--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAScienceManager = {}
local Technology_pb = RARequire('Technology_pb')
local HP_pb = RARequire('HP_pb')
local RANetUtil = RARequire("RANetUtil")
local tech_conf = RARequire('tech_conf')
local RAScienceUtility = RARequire("RAScienceUtility")
local RAPlayerEffect = RARequire("RAPlayerEffect")
local RAQueueManager = RARequire("RAQueueManager")
local RAStringUtil = RARequire("RAStringUtil")


RAScienceManager.scienceDatas = {}  -- 存放研究完成的科技id
RAScienceManager.netHandlers = {}   -- 存放监听协议
RAScienceManager.techUiType=nil     -- 存储记录下玩家最后一次点击的标签页
RAScienceManager.UIDinWeiTab={}     -- 是否定位的判断

--添加研究完成的科技
function RAScienceManager:addScienceDatas( id )
    if self.scienceDatas[tostring(id)]==nil then 
        self.scienceDatas[tostring(id)]=id 

        --存储下科技id
        -- local scienceInfo =RAScienceUtility:getScienceDataById(id)
        -- if scienceInfo.techEffectID then
        --     local effectTab = RAStringUtil:split(scienceInfo.techEffectID,"_")
        --     local effectType = tonumber(effectTab[1])
        --     local effectValue = tonumber(effectTab[2])
        --     RAPlayerEffect:addEffectTech(effectType,effectValue)
        -- end 
    end   
end

--刷新完成的科技
function RAScienceManager:updateScienceDatas(id)
   local updateData=nil
   local tmpKey =nil
   for k,v in pairs(self.scienceDatas) do   
       local tmpId = math.floor(v/100)
       local scienceId = math.floor(id/100)
       if tmpId==scienceId then
            -- updateData = RAScienceUtility:getScienceDataById(id)
            tmpKey = k
            break
       end
   end

   if tmpKey then
     self.scienceDatas[tmpKey]=nil
   end
   self:addScienceDatas(id)
end

--删除研究科技
function RAScienceManager:delete(id )
    if id==nil then return end 
	self.scienceDatas[tostring(id)]=nil
end

--清除一遍
function RAScienceManager:clearScienceDatas()
   for k,v in pairs(self.scienceDatas) do
       self.scienceDatas[k]=nil
   end
   self.scienceDatas={}
end

--获得已经研究过的科技
function RAScienceManager:getScienceDatas()
    return self.scienceDatas
end

--通过id获取具体的已经研究过的科技id
function RAScienceManager:getScienceDataById(id)
    return self.scienceDatas[tostring(id)]
end

--获取同一UI标签下完成最大的科技id
function RAScienceManager:getMaxScienceIdByUitype()
    local techUiType = self:getClickUiType()
    local tb=RAScienceUtility:getScienceDataByType(techUiType)
    local tmpId=0
    for k,v in pairs(self.scienceDatas) do
        local id =tonumber(v)
        local scienceInfo = tb[tostring(id)]
        if scienceInfo then
            if id>tmpId then
                tmpId = id
            end 
        end
    end


    --若一个都没完成返回0
    return tmpId
end

--判断是否是最顶部科技id RAScienceUtility:getMaxPosYInUitype(uiType)
function RAScienceManager:isTopScienceInUiType(id)
    local scienceInfo = RAScienceUtility:getScienceDataById(id)
    local posInfo = RAStringUtil:split(scienceInfo.uiPos,",")
    local posY = tonumber(posInfo[2])
    local techUiType = self:getClickUiType()
    local minPosY=RAScienceUtility:getMinPosYInUitype(techUiType)
    local isResult = minPosY==posY and true or false
    return isResult
end

--判断是否是底部科技id
function RAScienceManager:isBottomScienceInUiType(id)
    local scienceInfo = RAScienceUtility:getScienceDataById(id)
    local posInfo = RAStringUtil:split(scienceInfo.uiPos,",")
    local posY = tonumber(posInfo[2])
    local techUiType = self:getClickUiType()
    local maxPosY=RAScienceUtility:getMaxPosYInUitype(techUiType)
    local isResult = (maxPosY==posY or maxPosY-1==posY) and true or false
    return isResult
end

--通过id判断某个科技是否完成
function RAScienceManager:isResearchFinish(id)
    local isFinish = false
    local targetScienceId = tonumber(id)
    for k,v in pairs(self.scienceDatas) do
        local tmpScienceId = v
        if tmpScienceId==targetScienceId or (math.floor(tmpScienceId/100)==math.floor(targetScienceId/100) and tmpScienceId>targetScienceId) then 
            isFinish = true
            break
        end 
    end
    return isFinish

end

--通过id取得该科技的最高等级
function RAScienceManager:getMaxLevel(id)
    local targetScienceId = tonumber(id)
    for k,tmpScienceId in pairs(self.scienceDatas) do
        if tmpScienceId==targetScienceId or math.floor(tmpScienceId/100)==math.floor(targetScienceId/100) then 
            return tonumber(tech_conf[tmpScienceId].techLevel)
        end 
    end
    return 0

end

--判断科技是否解锁，根据前置建筑 前置科技
function RAScienceManager:isUnLock( scienceInfo )
    -- body
    local isUnLock = true

    --前置建筑
    if scienceInfo.frontBuild then
        local RABuildManager = RARequire('RABuildManager')
        local buildInfo = RABuildingUtility.getBuildInfoById(scienceInfo.frontBuild)
        local isBuildExist = RABuildManager:isBuildingExist(scienceInfo.frontBuild,buildInfo.buildType)

        if not isBuildExist  then
            isUnLock = false
        end 
    end

    if isUnLock and scienceInfo.frontTech then  --前置科技
        isUnLock = false
        local frontTechTab = RAStringUtil:split(scienceInfo.frontTech,",")
        local completeFrontTechIds = {}
        for i, frontTechId in ipairs(frontTechTab) do
            frontTechId = tonumber(frontTechId)
            local isScienceExist = RAScienceManager:isResearchFinish(frontTechId)
            if isScienceExist then
                isUnLock = true
                break
            end
        end 
    end  
    
    return isUnLock
end

--添加协议监听
function RAScienceManager:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.TECHNOLOGY_UPLEVEL_S, RAScienceManager) --研究科技返回
end

--移除协议监听
function RAScienceManager:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end 

function RAScienceManager:initDatas(tmpType)
    local scienceType = tmpType or 1
    local tb = RAScienceUtility:getScienceDataByTypeAndLevel(scienceType,1)
    if not tb or not next(tb) then return {} end
    if next(self.scienceDatas) then
        for i,v in pairs(self.scienceDatas) do
            RAScienceUtility:refreshScienceData(v,tb)
        end
    end 
    return tb
end

function RAScienceManager:getResearchSuccesNum(tmpType)

    local count = 0
    for k,v in pairs(self.scienceDatas) do
        local scienceInfo = RAScienceUtility:getScienceDataById(v)
        if scienceInfo.techUiType == tmpType then
            count = count +scienceInfo.techLevel
        end 
    end
    return count
end
function RAScienceManager:Enter(tmpType)

    local tb = self:initDatas(tmpType)
    self:addHandler()
    return tb
end

function RAScienceManager:Exit()
    self:removeHandler()
    self:clearDinWeiTab()
end

function RAScienceManager:reset()
   self:Exit()
   self:clearScienceDatas()
end

--添加协议监听返回处理
function RAScienceManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.TECHNOLOGY_UPLEVEL_S then  --研究科技返回
    	--local msg = Technology_pb.LevelUpTechnologyResp()
        --msg:ParseFromString(buffer)
      
    end

end


--返回研究队列的数目
function RAScienceManager:getCanResearchingNum()
   return 1
end

--记录玩家最后一次点击的标签页
function RAScienceManager:setClickUiType(tmpType)
    self.techUiType = tmpType
end

--返回玩家最后一次点击的标签页
function RAScienceManager:getClickUiType()
    return self.techUiType or 1
end


--判断是否要定位
function RAScienceManager:isGetDinWei(uiType)
    if not self.UIDinWeiTab[uiType] then
        return false
    end 
    return self.UIDinWeiTab[uiType]
end

function RAScienceManager:setDinWei(uiType,isDinWei)
   self.UIDinWeiTab[uiType]=isDinWei
end

function RAScienceManager:clearDinWeiTab()
    for i,v in ipairs(self.UIDinWeiTab) do
       v=nil
    end
    self.UIDinWeiTab={}
end

function RAScienceManager:initDinWeiTab(count)
    for i=1,count do
        self.UIDinWeiTab[i]=true
    end
end


--判断两个科技是否是同一个uiType
function RAScienceManager:isSameUiType(id1,id2)
    local scienceInfo1 = RAScienceUtility:getScienceDataById(id1)
    local scienceInfo2 = RAScienceUtility:getScienceDataById(id2)
    if scienceInfo1.uiType==scienceInfo2.uiType then
        return true
    end 
    return false
end

function RAScienceManager:isShowLineBy(id)
   local isShow=self:isResearchFinish(id)
   return isShow
end

--------------------------------------------------------------------------------------------
-- 发送研究协议 科技id
function RAScienceManager:sendReseachCmd(id)

    local cmd = Technology_pb.LevelUpTechnologyReq()
    cmd.techId = id
    cmd.useGold = 0
    RANetUtil:sendPacket(HP_pb.TECHNOLOGY_UPLEVEL_C, cmd)
end


-- 发送立即研究协议
function RAScienceManager:sendReseachNowCmd(id)
	
    local cmd = Technology_pb.LevelUpTechnologyReq()
    cmd.techId = id
    cmd.useGold = 1
    RANetUtil:sendPacket(HP_pb.TECHNOLOGY_UPLEVEL_C,cmd)
end

-- 发送队列加速协议 消耗钻石
function RAScienceManager:sendQueueSpeedUpByGold(id)
    RAQueueManager:sendQueueSpeedUpByGold(id)
end

-- 发送队列加速协议 消耗道具
function RAScienceManager:sendQueueSpeedUpByItems(id,itemUUid,count)

    RAQueueManager:sendQueueSpeedUpByItems(id,itemUUid,count)
end


--发送取消队列
function RAScienceManager:sendQueueCancel(id)
    RAQueueManager:sendQueueCancel(id)
end

return RAScienceManager
--endregion
