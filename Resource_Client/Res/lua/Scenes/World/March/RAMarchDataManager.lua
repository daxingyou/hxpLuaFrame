-- RAMarchDataManager.lua
-- 处理行军数据并保存

local RAMarchDataManager = {
    -- 非自己的行军数据列表， key为marchId
    mMarchDataMap = {},

    -- 自己行军数据的列表，key为marchId
    mSelfMarchDataMap = {},

    -- 队长行军数据（当玩家正在参加一个集结行军的时候，）
    mTeamLeaderDataMap = {},
    mLastBufferOutputTime = 0,
}

local RAWorldVar = RARequire('RAWorldVar')
local RAMarchConfig = RARequire('RAMarchConfig')
local Utilitys = RARequire('Utilitys')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')
local List = RARequire('List')
local RAWorldUtil = RARequire('RAWorldUtil')

-- 敌人、公会、无关人员的行军id缓存列表，会在execute里进行遍历添加
RAMarchDataManager.mEnmyMarchsBuffer = List:New()
RAMarchDataManager.mGuildMarchsBuffer = List:New()
RAMarchDataManager.mNoneMarchsBuffer = List:New()


function RAMarchDataManager:reset()    
    self.mSelfMarchDataMap = {}
    self.mTeamLeaderDataMap = {}

    self.mMarchDataMap = {}    
    self:resetBufferData()
end

-- 切换城内城外的时候调用
function RAMarchDataManager:resetForChangeScene()    
    self.mMarchDataMap = {}    
    self:resetBufferData()
end


-- 跨服的时候，只刷移除
function RAMarchDataManager:resetForCrossServer()    
    self.mMarchDataMap = {}    
    self:resetBufferData()
end

function RAMarchDataManager:resetBufferData()
    self.mEnmyMarchsBuffer = List:New()
    self.mGuildMarchsBuffer = List:New()
    self.mNoneMarchsBuffer = List:New()

    self.mLastBufferOutputTime = 0
end

-- 添加一个行军数据
-- 缓冲添加行军数据，不要及时反应，而且应该有优先级别的判定，比如self > enemy > friend > none
function RAMarchDataManager:AddMarchData(msg, isSelfAdd)
    if msg == nil then return end
    local isSelfAdd = isSelfAdd or false
    local RAMarchDataHelper = RARequire('RAMarchDataHelper')
    local marchData = RAMarchDataHelper:CreateMarchData(msg)    
    if marchData == nil or marchData.marchId == '' then return end

    local marchId = marchData.marchId

    -- -- 如果curr time大于end time 直接return
    -- if marchData:GetLastTime() < 0 then
    --     return
    -- end

    -- 如果有老的，直接移除
    if self.mMarchDataMap[marchId] ~= nil then
        --
    end

    if marchData.relation == World_pb.SELF then
        self.mSelfMarchDataMap[marchData.marchId] = marchData        
        -- 刷新队列ui
        MessageManager.sendMessage(MessageDef_Queue.MSG_Common_ADD, {
            queueId = marchId, 
            queueType = Const_pb.MARCH_QUEUE, 
            marchType = marchData.marchType
            })
        -- 自己的直接刷新
        local RAMarchManager = RARequire('RAMarchManager')
        local timeDebug = CCTime:getCurrentTime()                            
        RAMarchManager:ShowMarchByData(marchData, true, true)
        local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
        print('run RAMarchManager.ShowMarchByData one time, spend time:'.. tostring(calcTimeSpend))

        -- 这块去播放音效，根据行军的士兵类型
        if isSelfAdd then
            self:CheckMarchDataAndPlayEffect(marchData, true)
        end
    elseif marchData.relation == World_pb.TEAM_LEADER then
        if isSelfAdd then
            --队长集结的行军，只存放数据 
            self.mTeamLeaderDataMap[marchData.marchId] = marchData
        end
    else
        -- 如果当前已经有这个行军的数据，就不再处理了（新的推送规则需要这么做）
        if self.mMarchDataMap[marchData.marchId] == nil then
            self.mMarchDataMap[marchData.marchId] = marchData
            -- 只有这两种行军需要添加到缓冲池中去做模型刷新的显示
            if self:LocalCheckMarchShowStatus(marchData.marchStatus) then            
                self:_AddMarchDataToBuffer(marchData)
            end
            local RAMarchManager = RARequire('RAMarchManager')
            RAMarchManager:ShowMarchByData(marchData, false, false)
        else
            return self.mMarchDataMap[marchData.marchId]
        end
    end

    return marchData
end


-- 更新一个行军数据
function RAMarchDataManager:UpdateMarchData(msg)
    local marchId = msg.marchId
    --是不是集结行军的update
    if msg.relation == World_pb.TEAM_LEADER then
        local leaderData = self.mTeamLeaderDataMap[marchId]
        if leaderData ~= nil then
            leaderData:UpdateByPb(msg)
            -- 队长的行军刷新，
            -- 队列刷新，需要找到自己参与的这个行军的id，然后去更新
            if self.mSelfMarchDataMap == nil then return leaderData end
            for k,selfData in pairs(self.mSelfMarchDataMap) do
                if selfData ~= nil then                    
                    if RAWorldUtil:IsJoiningMassMarch(selfData.marchType) then
                        if selfData.targetId == leaderData.marchId then
                            MessageManager.sendMessage(MessageDef_Queue.MSG_Common_UPDATE, {
                                queueId = selfData.marchId, 
                                queueType = Const_pb.MARCH_QUEUE, 
                                marchType = selfData.marchType
                                })                
                            break
                        end                        
                    end
                end
            end            
        end
        return leaderData
    end
    -- 如果有老的，直接更新
    local marchData = self:GetMarchDataById(marchId)    
    if marchData ~= nil then        
        local oldStatus = marchData.marchStatus  
        marchData:UpdateByPb(msg)
        if marchData.relation == World_pb.SELF then
            -- 刷新队列ui
            MessageManager.sendMessage(MessageDef_Queue.MSG_Common_UPDATE, {
                queueId = marchId, 
                queueType = Const_pb.MARCH_QUEUE, 
                marchType = marchData.marchType
                })
            -- 自己的直接刷新
            local RAMarchManager = RARequire('RAMarchManager')
            local timeDebug = CCTime:getCurrentTime()                    
            RAMarchManager:ShowMarchByData(marchData, false, true)
            local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
            print('run RAMarchManager.ShowMarchByData one time, spend time:'.. tostring(calcTimeSpend))

            self:CheckMarchDataAndPlayEffect(marchData)            
        else
            self:_AddMarchDataToBuffer(marchData)
            local RAMarchManager = RARequire('RAMarchManager')
            RAMarchManager:ShowMarchByData(marchData, false, false)
        end
    else
        -- print('RAMarchDataManager:UpdateMarchData error marchId:'..marchId)
        marchData = self:AddMarchData(msg)
    end
    return marchData
end



-- 移除一个行军
-- 及时删除
function RAMarchDataManager:RemoveMarchDataById(marchId, isBlockRemove)
    isBlockRemove = isBlockRemove or false
    local relation = nil
    if not isBlockRemove then
        if self.mSelfMarchDataMap[marchId] ~= nil then
            local marchData = self.mSelfMarchDataMap[marchId]
            local RARootManager = RARequire('RARootManager')
            -- -- 如果是资源采集的行军，尝试关闭相关页面：召回、自己资源采集页面
            -- if marchData.marchType == World_pb.COLLECT_RESOURCE then
            --     -- RARootManager.ClosePage('RAWorldMyCollectionPage')
            --     -- RARootManager.ClosePage('RAWorldMyCollectionPage')
            -- end
            relation = marchData.relation
            if self.mSelfMarchDataMap[marchId].relation == World_pb.SELF then
                MessageManager.sendMessage(MessageDef_Queue.MSG_Common_DELETE, {
                    queueId = marchId, 
                    queueType = Const_pb.MARCH_QUEUE, 
                    marchType = marchData.marchType
                    })
            end
        end
        self.mSelfMarchDataMap[marchId] = nil

        if relation == nil and self.mTeamLeaderDataMap[marchId] ~= nil then
            local marchData = self.mTeamLeaderDataMap[marchId]
            relation = marchData.relation
        end
        self.mTeamLeaderDataMap[marchId] = nil
    else
        if self.mMarchDataMap[marchId] ~= nil then
            relation = self.mMarchDataMap[marchId].relation
        end
        self.mMarchDataMap[marchId] = nil        
    end

    -- 移除行军显示
    -- MessageManager.sendMessage(MessageDef_World.MSG_MarchDelete, {marchId = marchId, relation = relation})
    local RAMarchManager = RARequire('RAMarchManager')
    -- relation为队长数据的时候，不移除显示
    if relation ~= World_pb.TEAM_LEADER then
        RAMarchManager:RemoveMarchDisplayById(marchId, relation)
    end
end


-- 根据行军关系类型，添加到对应的缓冲buffer里
function RAMarchDataManager:_AddMarchDataToBuffer(marchData)
    local isAdded = false
    local marchId = marchData.marchId
    if not marchId or marchId == '' then return end
    -- add to buffer
    if marchData.relation == World_pb.ENEMY then
        isAdded = true
        self.mEnmyMarchsBuffer:PushEnd({marchId = marchId})
    elseif marchData.relation == World_pb.GUILD_FRIEND then
        isAdded = true
        self.mGuildMarchsBuffer:PushEnd({marchId = marchId})
    elseif marchData.relation == World_pb.NONE then
        isAdded = true
        self.mNoneMarchsBuffer:PushEnd({marchId = marchId})
    end
    local RARootManager = RARequire('RARootManager')
    -- 需要去刷新数据了
    if isAdded and RARootManager.GetIsInWorld() then
        local RAMarchManager = RARequire('RAMarchManager')
        RAMarchManager:SetIsBufferEmpty(false)
    end
end


-- 从缓冲中取一个行军id，用来刷新
-- 优先级：enmy > guild > none
-- self类型的，会立即刷新
function RAMarchDataManager:PopMarchIdFromBuffer()
    if not self.mEnmyMarchsBuffer:IsEmpty() then
        local popEnd = self.mEnmyMarchsBuffer:PopEnd()
        if popEnd ~= nil and popEnd.marchId ~= nil then
            return popEnd.marchId
        end
    end

    if not self.mGuildMarchsBuffer:IsEmpty() then
        local popEnd = self.mGuildMarchsBuffer:PopEnd()
        if popEnd ~= nil and popEnd.marchId ~= nil then
            return popEnd.marchId
        end
    end

    if not self.mNoneMarchsBuffer:IsEmpty() then
        local popEnd = self.mNoneMarchsBuffer:PopEnd()
        if popEnd ~= nil and popEnd.marchId ~= nil then
            return popEnd.marchId
        end
    end
    return nil
end


-- 检查一个行军，然后播放音效
function RAMarchDataManager:CheckMarchDataAndPlayEffect(marchData, isOut)
    if marchData == nil then return end
    local videoEffectList = {}
    local marchType = marchData.marchType
    local marchStatus = marchData.marchStatus
    isOut = isOut or false

    -- 不是出发的时候，且不是reach 就不播放
    if not isOut and marchStatus ~= World_pb.MARCH_STATUS_MARCH_REACH then
        return
    end
    -- 兵种数据
    local armyTypeList = marchData:GetArmyTypes()
    -- 采集资源需要取资源类型
    local targetResType = -1
    if marchData.marchType == World_pb.COLLECT_RESOURCE then
        local RAWorldConfigManager = RARequire('RAWorldConfigManager')
        local res_conf, _ = RAWorldConfigManager:GetResConfig(marchData.targetId)
        targetResType = res_conf.resType
    end

    -- 超级矿采集的话，targetId为资源类型
    if marchData.marchType == World_pb.MANOR_COLLECT then
        targetResType = tonumber(marchData.targetId)
    end

    -- 侦查    
    if marchType == World_pb.SPY then          
        if marchStatus == World_pb.MARCH_STATUS_MARCH then
            table.insert(videoEffectList, 'reconnaissanceAircraftOut')
        end
        -- if marchStatus == World_pb.MARCH_STATUS_MARCH_REACH then
        --     table.insert(videoEffectList, 'reconnaissanceAircraftOut')
        -- end
    end
    -- 采集资源
    if marchType == World_pb.COLLECT_RESOURCE or
        marchData.marchType == World_pb.MANOR_COLLECT then 
        if targetResType ~= -1 and targetResType ~= nil then
            local videoName = ''
            if marchStatus == World_pb.MARCH_STATUS_MARCH then
                videoName = RAMarchConfig.MarchCollectResVideos[targetResType].out
            end
            if marchStatus == World_pb.MARCH_STATUS_MARCH_REACH then
                videoName = RAMarchConfig.MarchCollectResVideos[targetResType].arr
            end         
            if videoName ~= nil and videoName ~= '' then
                table.insert(videoEffectList, videoName)
            end
        end
    end

    -- 行军、集结、士兵援助
    if marchType == World_pb.ATTACK_MONSTER or 
        marchType == World_pb.ATTACK_PLAYER or 
        marchType == World_pb.ASSISTANCE or 
        marchType == World_pb.MASS or 
        marchType == World_pb.MASS_JOIN or
        marchType == World_pb.MONSTER_MASS or 
        marchType == World_pb.MONSTER_MASS_JOIN or
        marchType == World_pb.MANOR_MASS or 
        marchType == World_pb.MANOR_MASS_JOIN or
        marchType == World_pb.ARMY_QUARTERED or
        marchType == World_pb.MANOR_ASSISTANCE_MASS or 
        marchType == World_pb.MANOR_ASSISTANCE_MASS_JOIN or 
        marchType == World_pb.MANOR_ASSISTANCE or
        marchType == World_pb.PRESIDENT_SINGLE or 
        marchType == World_pb.PRESIDENT_MASS or
        marchType == World_pb.PRESIDENT_MASS_JOIN or 
        marchType == World_pb.PRESIDENT_ASSISTANCE_MASS or
        marchType == World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN or 
        marchType == World_pb.PRESIDENT_ASSISTANCE then

        if armyTypeList ~= nil and marchStatus == World_pb.MARCH_STATUS_MARCH then
            for index=1, #armyTypeList do
                local armyMaxType = armyTypeList[index]
                local ccbCfg = RAMarchConfig.MarchSoldiersCCB[armyMaxType]
                if ccbCfg ~= nil then
                    local videoName = ccbCfg.video
                    if videoName ~= nil and videoName ~= '' then
                        table.insert(videoEffectList, videoName)
                    end
                end
            end
        end
    end

    --播放音效
    local common = RARequire("common")
    for k,effectName in pairs(videoEffectList) do
        common:playEffect(effectName)
    end
end

-- 检查所有行军中是否有需要删除的
-- 当服务器区块同步的时候，调用。寻找出老行军数据中在新msg里不存在的，然后删除
function RAMarchDataManager:CheckMarchesAndRemoveDiffSet(sysncMsg)
    if self.mMarchDataMap ~= nil and sysncMsg ~= nil then
        local id2remove = {}        

        print('****************************CheckMarchesAndRemoveDiffSet old marches count:'.. tostring(Utilitys.table_count(self.mMarchDataMap)))
        print('****************************CheckMarchesAndRemoveDiffSet new marches count:'.. tostring(#sysncMsg.marchData))
        local removeCount = 0
        for marchId, marchData in pairs(self.mMarchDataMap) do
            local isRemove = true
            if marchData ~= nil then           
                for _,v in ipairs(sysncMsg.marchData) do
                    -- v = MarchData = {marchId, marchPB}
                    if v.marchPB ~= nil 
                        and v.marchPB.relation ~= World_pb.SELF
                        and v.marchPB.relation ~= World_pb.TEAM_LEADER then
                        if v.marchId == marchId then
                            isRemove = false
                            break
                        end
                    end
                end
            end
            if isRemove then
                removeCount = removeCount + 1
                id2remove[removeCount] = marchId
            end
        end
        print('***************************CheckMarchesAndRemoveDiffSet remvoe marches count:'.. removeCount)
        for i,v in ipairs(id2remove) do
            print('-----------------remove march id = '.. v)
            self:RemoveMarchDataById(v, true)
        end
    end
end


-- 检查所有行军中是否有需要删除的
function RAMarchDataManager:CheckAndCleanMarchsOut()
    if self.mMarchDataMap ~= nil then
        local id2remove = {}
        for marchId, marchData in pairs(self.mMarchDataMap) do
            if marchData ~= nil then                
                local timeDebug = CCTime:getCurrentTime()
                local result = self:CheckIsMarchOutOfView(marchId)
                if result then table.insert(id2remove, marchId) end                        
                local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
                print('run RAMarchDataManager:CheckIsMarchOutOfView one time, spend time:'.. tostring(calcTimeSpend))
            end
        end
        for i,v in ipairs(id2remove) do
            print('-----------------RAMarchDataManager:CheckAndCleanMarchsOut()------------------')
            print('-----------------remove march id = '.. v)
            self:RemoveMarchDataById(v, true)
        end
    end
end

-- 检查一个行军是否超出到视野外
function RAMarchDataManager:CheckIsMarchOutOfView(marchId)    
    local marchData = self:GetMarchDataById(marchId)
    if marchData == nil then
        return true
    end
    -- 自己的行军一定不会outside
    if marchData.relation == World_pb.SELF then
        return false
    end

    -- local ptS, ptE = controller:GetMarchMoveStartAndEndPos()
    -- if ptS == nil or ptE == nil then
    --     return true
    -- end

    -- local mapCenter = Utilitys.ccpCopy(RAWorldVar.ViewPos.Map)

    local ptS = marchData:GetStartCoord()
    local ptE = marchData:GetEndCoord()
    if ptS == nil or ptE == nil then
        return true
    end
    local mapCenter = Utilitys.ccpCopy(RAWorldVar.MapPos.Map)

    local dis = Utilitys.getPoint2SegmentDistance(mapCenter, ptS, ptE)    

    if RAMarchConfig.MarchDisplayRange < 0 then
        local world_map_const_conf = RARequire('world_map_const_conf') 
        local broadWidth = world_map_const_conf.broadCastWid.value
        local broadHeight = world_map_const_conf.broadCastLen.value
        RAMarchConfig.MarchDisplayRange = math.sqrt(broadWidth * broadWidth + broadHeight * broadHeight)
        RAMarchConfig.MarchDisplayRange = RAMarchConfig.MarchDisplayRange * world_map_const_conf.broadCastScaleForDel.value * 0.01
    end

    if dis < RAMarchConfig.MarchDisplayRange then
        return false
    end
    return true
end


-- 获取一个行军数据
function RAMarchDataManager:GetMarchDataById(marchId)
    local isSelf = nil
    local marchData = self.mSelfMarchDataMap[marchId]
    if marchData == nil then
        marchData = self.mMarchDataMap[marchId]
        isSelf = false
    else
        isSelf = true
    end
    return marchData, isSelf
end

--获取自己是否有了采集超级矿的行军；
-- 参数为true则检查是否正在采集过程中
function RAMarchDataManager:CheckSelfSuperMineCollectStatus(isCollecting)
	isCollecting = isCollecting or false
	local result = false
    local marchId = ''
	if self.mSelfMarchDataMap == nil then return false end
    for k,v in pairs(self.mSelfMarchDataMap) do
        if v.marchType == World_pb.MANOR_COLLECT then
            if isCollecting then
            	if v.marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
            		result = true
                    marchId = v.marchId
            		break
            	end
            else
            	result = true
                marchId = v.marchId
            	break
            end
        end
    end
    return result, marchId
end

-- 获取当前是否正在领地中驻守（即marchType == MANOR_ASSISTANCE）
-- 会检查是否正在驻扎状态中
function RAMarchDataManager:CheckSelfManorQuarteredStatus()    
    local result = false
    local marchId = ''
    if self.mSelfMarchDataMap == nil then return false end
    for k,v in pairs(self.mSelfMarchDataMap) do
        if v.marchType == World_pb.MANOR_ASSISTANCE and 
            v.marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
            result = true
            marchId = v.marchId
            break
        end
    end
    return result, marchId
end

-- 获取自己某个类型的行军
function RAMarchDataManager:GetSelfMarchDataMapByType(marchType)
    if self.mSelfMarchDataMap == nil then return {} end
    local marchMap = {}
    for marchId,v in pairs(self.mSelfMarchDataMap) do
        if v.marchType == marchType then
            marchMap[marchId] = v
        end
    end
    return marchMap
end

-- 根据自己的行军id，找到行军对应的集结数据
function RAMarchDataManager:GetTeamLeaderMarchData(joinMarchId)    
    local marchData = self:GetMarchDataById(joinMarchId)
    -- 本身就是集结发起人的话，直接返回自己
    if marchData ~= nil then 
        if RAWorldUtil:IsMassingMarch(marchData.marchType) then
            return marchData
        end
    end
    if marchData ~= nil then
        if RAWorldUtil:IsJoiningMassMarch(marchData.marchType) then
            return self.mTeamLeaderDataMap[marchData.targetId]
        end
    end
    return nil
end

-- 获取当前自己是不是集结队长，且队伍正在集结中
function RAMarchDataManager:CheckIsSelfTeamLeader()
    if self.mSelfMarchDataMap == nil then return false end
    for k,v in pairs(self.mSelfMarchDataMap) do
        if RAWorldUtil:IsMassingMarch(v.marchType) and v.marchStatus == World_pb.MARCH_STATUS_WAITING then
            return true
        end
    end
    return false
end

-- 获取当前是否参加或者发起了集结,且集结已经发车
function RAMarchDataManager:CheckIsSelfMassJoinAndMarching()
    if self.mSelfMarchDataMap == nil then return false end
    if self.mTeamLeaderDataMap == nil then return false end  
    for k,marchData in pairs(self.mSelfMarchDataMap) do
        if marchData ~= nil then
            if RAWorldUtil:IsMassingMarch(marchData.marchType) then                
                if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                    return true
                end
            end
            if RAWorldUtil:IsJoiningMassMarch(marchData.marchType) then
                local massData = self.mTeamLeaderDataMap[marchData.targetId]
                if massData ~= nil and massData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                    return true
                end
            end
        end
    end
    return false
end

-- 当前自己出征队伍数目
function RAMarchDataManager:GetSelfMarchCount()
    local count = Utilitys.table_count(self.mSelfMarchDataMap)
    return count
end


function RAMarchDataManager:GetSelfMarchDataMap()
    return self.mSelfMarchDataMap or {}
end

-- 是否有战斗类型行军
function RAMarchDataManager:HasMarchForBattle()
    local common = RARequire('common')
    for k, marchData in pairs(self.mSelfMarchDataMap or {}) do
        if not common:table_contains(RAMarchConfig.PeaceMarchType, marchData.marchType) then
            return true
        end
    end

    return false
end


-- 检查一个集结类型的行军是否是自己参加的
--（用于点击的时候hud显示加速和详情按钮）
function RAMarchDataManager:CheckIsJoinInOneMarch(marchData)
    if marchData == nil then return false end
    if RAWorldUtil:IsMassingMarch(marchData.marchType) then
        return false 
    end
    if marchData.relation == World_pb.SELF then return true end
    local massId = marchData.marchId
    if self.mSelfMarchDataMap == nil then return false end
    for k,v in pairs(self.mSelfMarchDataMap) do
        if RAWorldUtil:IsJoiningMassMarch(marchData.marchType) and massId == v.targetId then
            return true
        end
    end
    return false
end


-- 出征上限
function RAMarchDataManager:GetWorldMarchArmyLimit()
    local RABuildManager = RARequire('RABuildManager')
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local limit = RABuildManager:getAttackUnitLimit()

    -- 作用号逻辑
    -- TROOP_STRENGTH_PER    = 200;  //单支部队兵力上限加成 行军相关（200-299）
    -- TROOP_STRENGTH_NUM      = 201;  //单支部队兵力上限增加值
    -- 百分比作用号
    local effectValue = FACTOR_EFFECT_DIVIDE + RAPlayerEffect:getEffectResult(Const_pb.TROOP_STRENGTH_PER)
    limit = limit * effectValue / FACTOR_EFFECT_DIVIDE
    -- 固定值作用号
    local effectAdd = RAPlayerEffect:getEffectResult(Const_pb.TROOP_STRENGTH_NUM)
    limit = limit + effectAdd

    -- 取整
    limit = math.floor(limit)
    return limit or 0
end


-- 获取负重值,param table element:{armyId = count, id2=count2}
function RAMarchDataManager:GetArmyTotalLoadNum(armyMap)
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    if armyMap == nil then return 0 end
    local battle_soldier_conf = RARequire('battle_soldier_conf')
    local totalLoad = 0
    for k,v in pairs(armyMap) do
        local armyId = k or 0
        local count = v or 0
        local cfg = battle_soldier_conf[armyId]
        if cfg ~= nil then
            local load = cfg.load or 0
            totalLoad = totalLoad + load * count
        end
    end

    -- 作用号逻辑
    -- RES_TROOP_WEIGHT      = 352;  //部队负重加成
    local effectValue = FACTOR_EFFECT_DIVIDE + RAPlayerEffect:getEffectResult(Const_pb.RES_TROOP_WEIGHT)
    totalLoad = totalLoad * effectValue / FACTOR_EFFECT_DIVIDE

    -- 取整
    totalLoad = math.floor(totalLoad)

    return totalLoad or 0
end


function RAMarchDataManager:GetRealArmyLoadNeeded(targetLoad)
    local RAPlayerEffect = RARequire('RAPlayerEffect')

    -- 作用号逻辑
    -- RES_TROOP_WEIGHT      = 352;  //部队负重加成
    local effectValue = FACTOR_EFFECT_DIVIDE + RAPlayerEffect:getEffectResult(Const_pb.RES_TROOP_WEIGHT)
    local realLoadNum = targetLoad * FACTOR_EFFECT_DIVIDE / effectValue    
    -- 取整，需要的负重值可以略大于实际需要的值
    realLoadNum = math.ceil(realLoadNum)
    return realLoadNum
end

-- 采集资源的当前速度（按秒计算），返回的不是整数了，需要显示的时候再去取整
function RAMarchDataManager:GetResourceCollectSpeed(resType)
    speedType = speedType or 1
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local baseSpeed = RAWorldConfigManager:GetResBaseCollectSpeed(resType)
    -- 作用号
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    -- 光环类
    local effectValue1 = RAPlayerEffect:getEffectResult(Const_pb.RES_COLLECT)
    -- 有时效
    local effectValue2 = RAPlayerEffect:getEffectResult(Const_pb.RES_COLLECT_BUF)

    local speedAdd1 = baseSpeed * effectValue1 / FACTOR_EFFECT_DIVIDE
    local speedAdd2 = baseSpeed * effectValue2 / FACTOR_EFFECT_DIVIDE
    local totalSpeed = baseSpeed + speedAdd1 + speedAdd2
    local speedShowBase = baseSpeed + speedAdd1
    local timeSpeed = speedAdd2
    return totalSpeed, speedShowBase, timeSpeed
end


-- 采集资源的当前速度（按秒计算）
function RAMarchDataManager:GetResourceSpeedUpEffectTime()
    local RAPlayerEffect = RARequire('RAPlayerEffect')    
    -- 有时效
    local startTime, endTime = RAPlayerEffect:getEffectTime(Const_pb.RES_COLLECT_BUF)
    startTime = startTime or 0
    endTime = endTime or 0
    return startTime, endTime
end



-- 获取行军的体力消耗值（只有打怪有消耗）
function RAMarchDataManager:GetVitNeedByMarchType(marchType)    
    local num = 0
    if marchType == World_pb.ATTACK_MONSTER or
        marchType == World_pb.MONSTER_MASS or
        marchType == World_pb.MONSTER_MASS_JOIN then
        num = RARequire('world_march_const_conf').atkEnemyCostVitPoint.value
    end
    -- todo: 作用号逻辑
    return num or 0
end

-- 获取贡献与体力消耗的比率值（一点体力获得多少贡献）
function RAMarchDataManager:GetContributionPerVit()    
    if self.contributionPerVit == nil then
        local guild_const_conf = RARequire('guild_const_conf')
        local contributionRate = guild_const_conf.energyToAllianceContribution.value
        local RAStringUtil = RARequire('RAStringUtil')
        local tmp = RAStringUtil:split(contributionRate, "_")
        if #tmp >= 2 then
            self.contributionPerVit = tonumber(tmp[2])/tonumber(tmp[1])
        else
            self.contributionPerVit = 1     
        end
    end
    return self.contributionPerVit
end

-- 获取积分与体力消耗的比率值（一点体力获得多少积分）
function RAMarchDataManager:GetScorePerVit()    
    if self.scorePerVit == nil then
        local guild_const_conf = RARequire('guild_const_conf')
        local scoreRate = guild_const_conf.energyToAllianceScore.value
        local RAStringUtil = RARequire('RAStringUtil')
        local tmp = RAStringUtil:split(scoreRate, "_")
        if #tmp >= 2 then
            self.scorePerVit = tonumber(tmp[2])/tonumber(tmp[1])
        else
            self.scorePerVit = 1     
        end
    end
    return self.scorePerVit
end

-- 获取一个行军列表的当前速度（取最小值）
function RAMarchDataManager:GetMarchSpeedFromArmyList(armyIdList)
    if armyIdList ~= nil then
        local armySpeed = -1
        local battle_soldier_conf = RARequire('battle_soldier_conf')
        for armyId, count in pairs(armyIdList) do
            if count > 0 then
                local cfg = battle_soldier_conf[armyId]
                if cfg ~= nil then
                    if armySpeed == -1 then 
                        armySpeed = cfg.speed 
                    else
                        if armySpeed > cfg.speed then
                            armySpeed = cfg.speed
                        end
                    end
                end
            end
        end
        if armySpeed ~= -1 then
            return armySpeed
        else
            -- 有参数，但是没选中兵的时候，行军速度为0
            return 0
        end
    else
        return 0
    end
end



-- 获取侦查行军路线总时间
function RAMarchDataManager:GetMarchWayTotalTimeForDetect(startPos, endPos)
    local marchParts = self:GetMarchWayData(startPos, endPos, true)    
    -- 速度 坐标/秒，用时除以1000
    local baseSpeed = RARequire('world_march_const_conf').investigationMarchSpeed.value
    return self:GetMarchWayTotalTimeByMarchParts(marchParts, baseSpeed, World_pb.SPY)
end

-- 获取侦查行军路线总时间
function RAMarchDataManager:GetMarchWayTotalTimeForResAssistant(startPos, endPos)
    local marchParts = self:GetMarchWayData(startPos, endPos, true)    
    -- 速度 坐标/秒，用时除以1000
    local baseSpeed = RARequire('world_march_const_conf').resourceAssistMarchSpeed.value
    return self:GetMarchWayTotalTimeByMarchParts(marchParts, baseSpeed, World_pb.ASSISTANCE_RES)
end

-- 获取行军路线总时间，通过分段好的数据和速度（减少计算次数）
function RAMarchDataManager:GetMarchWayTotalTimeByMarchParts(marchParts, baseSpeed, marchType)
    if marchParts == nil then return 0 end  
    local totalTime = 0
    local slowDownScale = RARequire('world_march_const_conf').worldMarchCoreRangeTime.value
    for index, partData in pairs(marchParts) do
        local partBeginPos = partData.startPos
        local partEndPos = partData.endPos
        local isSlowDown = partData.isSlowDown
        local dis = Utilitys.getDistance(partBeginPos, partEndPos)
        local time = 0
        if isSlowDown then
            time = dis / baseSpeed * 1000 * slowDownScale
        else
            time = dis / baseSpeed * 1000
        end
        totalTime = totalTime + time
    end

    -- 作用号
    -- MARCH_SPD               = 203;  //行军速度增加-所有
    -- MARCH_SPD_MONSTER       = 204;  //行军速度增加-野怪

    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local effectValue = RAPlayerEffect:getEffectResult(Const_pb.MARCH_SPD)
    if marchType == World_pb.ATTACK_MONSTER then
        effectValue = effectValue + RAPlayerEffect:getEffectResult(Const_pb.MARCH_SPD_MONSTER)
    end
    totalTime = totalTime - totalTime * effectValue / FACTOR_EFFECT_DIVIDE

    -- 取整
    totalTime = math.floor(totalTime)

    return totalTime
end



-- 获取行军路线数据，
-- 传入的参数为需标示是否为格子
-- 返回一个数组，每个元素的数据结构是：
-- local onePartData2 = {}
-- onePartData2.startPos = Utilitys.ccpCopy(crossPt)
-- onePartData2.endPos = Utilitys.ccpCopy(endPos)
-- onePartData2.isSlowDown = true
function RAMarchDataManager:GetMarchWayData(startPos, endPos, isTile)
    local RAWorldUtil = RARequire('RAWorldUtil')

    local isStartPtBank = nil
    local isEndPtBank = nil

    local borders = nil 

    if isTile then
        isStartPtBank = RAWorldUtil:IsInBankArea(startPos)
        isEndPtBank = RAWorldUtil:IsInBankArea(endPos)
        borders = RAWorldUtil:GetMapBankBorders()
    else
        isStartPtBank = RAWorldUtil:IsInBankViewArea(startPos)
        isEndPtBank = RAWorldUtil:IsInBankViewArea(endPos)
        borders = RAWorldUtil:GetViewBankBorders()
    end

    local result = {}

    local crossLineMap = {}

    local relationMap = {}

    for i=1, #borders do
        local line = borders[i]
        -- local lineStatus, lineCrossPts = Utilitys.checkTwoSegmentsRelation(startPos, endPos, line.beginPos, line.endPos, true)    
        -- --正常相交的记录索引
        -- if lineStatus == 1 or lineStatus == 3 then
        --     table.insert(crossLineMap, i)
        -- end

        local timeDebug = CCTime:getCurrentTime()
        local lineStatus, lineCrossPt = Utilitys.getSegmentsIntersect(startPos, endPos, line.beginPos, line.endPos)    
        local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
        print('run Utilitys.getSegmentsIntersect one time, spend time:'.. tostring(calcTimeSpend))
        --正常相交的记录索引
        if lineStatus == 1 then
            table.insert(crossLineMap, i)
        end

        relationMap[i] = {
            crossPt = lineCrossPt,
            status = lineStatus
        }
    end
    -- 起点不在黑土地中
    if not isStartPtBank then
        --终点在黑土地中（包括线上）
        if isEndPtBank then
            -- 取一个交点，交点可能也是终点
            -- 当为两个交点的时候，一定交点为黑土地顶点，这时候两个交点相同
            if #crossLineMap >= 1 then
                local index = crossLineMap[1]
                local crossPt = relationMap[index].crossPt
                local status = relationMap[index].status
                -- 分两段
                local onePartData = {}
                onePartData.startPos = Utilitys.ccpCopy(startPos)
                onePartData.endPos = Utilitys.ccpCopy(crossPt)
                onePartData.isSlowDown = false
                table.insert(result, onePartData)

                if not Utilitys.checkIsPointSame(crossPt, endPos) then
                    local onePartData2 = {}
                    onePartData2.startPos = Utilitys.ccpCopy(crossPt)
                    onePartData2.endPos = Utilitys.ccpCopy(endPos)
                    onePartData2.isSlowDown = true
                    table.insert(result, onePartData2)
                end
            end
        else
        --终点不在黑土地上
            --如果正常交点有两个的时候，做分段
            --重合线不需要考虑，因为重合之后也一定会有2个正常交点
            if #crossLineMap == 2 then
                local index = crossLineMap[1]
                local crossPt = relationMap[index].crossPt
                local status = relationMap[index].status

                local index2 = crossLineMap[2]
                local crossPt2 = relationMap[index2].crossPt
                local status2 = relationMap[index2].status

                --路过一个顶点，此时不分段即可
                if Utilitys.checkIsPointSame(crossPt, crossPt2) then
                    local onePartData = {}
                    onePartData.startPos = Utilitys.ccpCopy(startPos)
                    onePartData.endPos = Utilitys.ccpCopy(endPos)
                    onePartData.isSlowDown = false
                    table.insert(result, onePartData)
                else
                    local crossOne = nil
                    local crossTwo = nil
                    if math.abs(startPos.x - crossPt.x) < math.abs(startPos.x - crossPt2.x) then
                        crossOne = crossPt
                        crossTwo = crossPt2
                    else
                        crossOne = crossPt2
                        crossTwo = crossPt
                    end

                    --  分三段
                    local onePartData = {}
                    onePartData.startPos = Utilitys.ccpCopy(startPos)
                    onePartData.endPos = Utilitys.ccpCopy(crossOne)
                    onePartData.isSlowDown = false
                    table.insert(result, onePartData)

                    local onePartData2 = {}
                    onePartData2.startPos = Utilitys.ccpCopy(crossOne)
                    onePartData2.endPos = Utilitys.ccpCopy(crossTwo)
                    onePartData2.isSlowDown = true
                    table.insert(result, onePartData2) 

                    local onePartData3 = {}
                    onePartData3.startPos = Utilitys.ccpCopy(crossTwo)
                    onePartData3.endPos = Utilitys.ccpCopy(endPos)
                    onePartData3.isSlowDown = false
                    table.insert(result, onePartData3)                        
                end
            end

            -- 如果没有正常交点，那么直接返回原路线
            if #crossLineMap == 0 then
                local onePartData = {}
                onePartData.startPos = Utilitys.ccpCopy(startPos)
                onePartData.endPos = Utilitys.ccpCopy(endPos)
                onePartData.isSlowDown = false
                table.insert(result, onePartData)
            end
        end
    else
        --终点在黑土地中（包括线上）
        if isEndPtBank then
             -- 分一段，全程减速
            local onePartData = {}
            onePartData.startPos = Utilitys.ccpCopy(startPos)
            onePartData.endPos = Utilitys.ccpCopy(endPos)
            onePartData.isSlowDown = true
            table.insert(result, onePartData) 
        else
            --终点不在黑土地
            --不论两个还是一个交点，都应该是同一个点
            if #crossLineMap >= 1 then
                local index = crossLineMap[1]
                local crossPt = relationMap[index].crossPt
                local status = relationMap[index].status
                -- 分两段
                local onePartData = {}
                onePartData.startPos = Utilitys.ccpCopy(startPos)
                onePartData.endPos = Utilitys.ccpCopy(crossPt)
                onePartData.isSlowDown = true
                table.insert(result, onePartData)

                if not Utilitys.checkIsPointSame(crossPt, endPos) then
                    local onePartData2 = {}
                    onePartData2.startPos = Utilitys.ccpCopy(crossPt)
                    onePartData2.endPos = Utilitys.ccpCopy(endPos)
                    onePartData2.isSlowDown = false
                    table.insert(result, onePartData2)
                end
            end
        end
    end    
    return result
end


-- 根据分段数据、开始和结束时间，计算当前走到了哪一段路程，同时计算走到的点
-- params:
-- marchParts = [onePart1, onePart2, ...]
    -- local onePart1 = {}
    -- onePart1.startPos = Utilitys.ccpCopy(crossPt)
    -- onePart1.endPos = Utilitys.ccpCopy(endPos)
    -- onePart1.isSlowDown = true
-- startTime、endTime为毫秒

-- return:
-- partIndex 分段索引（marchParts的索引）
-- currPos 当前点，线段marchParts[partIndex]上的一个点,
function RAMarchDataManager:GetMarchMoveCurrPos(marchParts, startTime, endTime)
    local partIndex = -1
    local currPos = RACcp(-1, -1)
    if marchParts == nil 
        or #marchParts < 1
        or endTime <= startTime then
        return partIndex, currPos 
    end

    local common = RARequire('common')
    local slowDownScale = RARequire('world_march_const_conf').worldMarchCoreRangeTime.value
    
    -- 1、计算每段距离（可以在分段时直接做完，少一次遍历）     
    -- 计算总距离百分比
    local totalDisPer = 0
    for i=1, #marchParts do        
        local partData = marchParts[i]
        local dis = Utilitys.getDistance(partData.startPos, partData.endPos)
        local speedScale = 1
        if partData.isSlowDown then
            speedScale = slowDownScale
        end
        partData.distancePer = dis * speedScale
        partData.distance = dis
        totalDisPer =  totalDisPer + dis * speedScale
    end

    -- 2、根据剩余的距离，计算走到了哪个分段，然后从那个分段开始构建数据  
    local curTime = common:getCurTime()
    local pastTime = os.difftime(curTime, startTime / 1000)
    local totalTime = (endTime - startTime) / 1000
    local pastTimePer = pastTime / totalTime
    -- 时间百分比防御
    if common:isNaN(pastTimePer) then
        pastTimePer = 0
    end
    if pastTimePer > 1 then
        pastTimePer = 1
    end
    local calcTimePer = 0
    for i=1, #marchParts do        
        local partData = marchParts[i]        
        calcTimePer = calcTimePer + partData.distancePer
        -- 走完当前分段所耗时间，占总消耗时间的百分比
        local calcCurrTimePer = calcTimePer / totalDisPer
        -- 因为是从起点开始遍历，那么如果经历过的时间百分比小于 calcCurrTimePer，或者已经是最后一段（后两个条件同一目的）
        if calcCurrTimePer > pastTimePer or calcCurrTimePer >= 1 or i == #marchParts then
            partIndex = i

            -- 计算走到了哪个点，因为partMovedDis为已经走的点，调用这个接口时要从终点往起点算
            -- 增加判断如果最后行军两个点一致的时候，直接返回起点，不再计算了
            local isLocalSame = Utilitys.checkIsPointSame(partData.endPos, partData.startPos)
            if isLocalSame or totalDisPer == 0 or partData.distance == 0 or totalTime == 0 or pastTimePer == 0 then
                currPos = Utilitys.ccpCopy(partData.startPos)
            else
                -- 计算这一分段中，走了多少距离
                -- (当前消耗时间百分比 - 上一分段累加的百分比) * 当前分段的真实距离
                local partMovedDis = (pastTimePer - (calcTimePer - partData.distancePer)/ totalDisPer) * partData.distance
                currPos = Utilitys.getGapPointOnSegment(partMovedDis, partData.endPos, partData.startPos)     
            end
            break       
        end
    end

    local common = RARequire('common')
    if common:isNaN(currPos.x) or common:isNaN(currPos.y) then
        RACcpPrint({x = currPos.x, y = currPos.y})
        print(debug.traceback())
    end 
    return partIndex, currPos 
end

-- 根据行军状态和类型来判断是否可以进行显示
-- 第二个参数可以不传
function RAMarchDataManager:LocalCheckMarchShowStatus(marchStatus, marchType)
    if marchStatus == World_pb.MARCH_STATUS_MARCH or         
        marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then 
        return true
    end
    if marchStatus == World_pb.MARCH_STATUS_WAITING then
        local RAWorldUtil = RARequire('RAWorldUtil')
        if RAWorldUtil:IsMassingMarch(marchType) then
            return true
        end
    end
    return false
end

function RAMarchDataManager:LocalCheckIsMarchNeedCreateModel(marchStatus)
    if marchStatus == World_pb.MARCH_STATUS_MARCH or         
        marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then 
        return true
    end
    return false
end


return RAMarchDataManager
