--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAStringUtil = RARequire("RAStringUtil")
local RARadarManage={}
RARadarManage.radarDatas={}   --存储雷达收到的行军报告数据


RARadarManage.Type={
    MASSWAIT=1,             --集结中
    MASSMARCH=2,            --集结完成行军
    ATTACK=3                --普通攻击行军
}


local RARadarData = {}

--构造函数
function RARadarData:new(o)
    o = o or {}
    o.marchData = nil       
    o.arrivalTime=nil
    o.isAttack=nil
    o.targetType=nil    --目标类型
    o.isExist=nil       --目标点是否有驻军

    setmetatable(o,self)
    self.__index = self
    return o
end

function RARadarData:initByPbData(marchReportData,isAttack,targetType,isExist)

    self.marchData=marchReportData
    local time = marchReportData.arrivalTime
    if time==nil then
        time = marchReportData.explosionTime
    end
    self.arrivalTime=math.floor(time/1000)
    self.isAttack=isAttack
    self.targetType=targetType
    self.isExist=isExist
end
--添加侦查行军数据
function RARadarManage:addRadarDatas(uuid,marchData,isAttack,targetType,isExist)
	if self.radarDatas[uuid]==nil then
        local radarData=RARadarData:new()
        radarData:initByPbData(marchData,isAttack,targetType,isExist)
        self.radarDatas[uuid]=radarData
	end 
end

function RARadarManage:updateRadarDatas(uuid,endTime)
	local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
        radarData.arrivalTime=math.floor(endTime/1000)
    end 
	
end
--删除行军数据
function RARadarManage:deleteRadarDatas(uuid)
	if self.radarDatas[uuid] then
		self.radarDatas[uuid]=nil
	end
end

--清空行军数据
function RARadarManage:clearRadarDatas()
	for k,v in pairs(self.radarDatas) do
		v=nil
	end
	self.radarDatas={}
end

--
function RARadarManage:getRadarDatas()
	return self.radarDatas
end

function RARadarManage:getRadarDataByUuid(uuid)
	if self.radarDatas[uuid] then
		return self.radarDatas[uuid]
	end 
	return nil
end

--判断行军的类型 攻击类和援助类
function RARadarManage:isAttackMarch(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
        return radarData.isAttack
    end 
	
end
--判断士兵援助类信息
function RARadarManage:isRadarAssistanceSoldierData(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
        local marchData=radarData.marchData
        local armyInfo=marchData.armyInfo
        if #armyInfo>0 then
            return true
        end 
        return false
    end 
	return false
end

--判断资源援助类信息
function RARadarManage:isRadarAssistanceResourceData(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
        local marchData=radarData.marchData
        local resources=marchData.resources
        if #resources>0 then
            return true
        end 
        return false
    end
    return false

end

--判断是否是集结后行军
function RARadarManage:isMassMarch(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData and radarData.isAttack then
         local marchData=radarData.marchData
         if marchData:HasField("massMarchStartTime") then
            local RA_Common = RARequire("common")
            local curTime = RA_Common:getCurTime() 
            if curTime*1000>marchData.massMarchStartTime then
                 return true
            end 
         end 
    end
    return false
end

--判断是否是集结中
function RARadarManage:isMassWaitMarch(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData and radarData.isAttack then
         local marchData=radarData.marchData
         if marchData:HasField("massMarchStartTime") then
            local RA_Common = RARequire("common")
            local curTime = RA_Common:getCurTime() 
            if curTime*1000<marchData.massMarchStartTime then
                 return true
            end 
         end 
    end
    return false
end

--判断是否是超级武器
function RARadarManage:isSuperWeapon(uuid)
     local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
         local marchData=radarData.marchData
         local nuclear = marchData.nuclear
         if nuclear then
            return true
         end 
    end
    return false
end 
--判断是否是核弹爆炸
function RARadarManage:isNuclearExplosion(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
         local marchData=radarData.marchData
         local nuclear = marchData.nuclear
         if nuclear==1 then
            return true
         end 
    end
    return false
end

--判断是否是雷暴爆炸
function RARadarManage:isLightningStorm(uuid)
    local radarData=self:getRadarDataByUuid(uuid)
    if radarData then
         local marchData=radarData.marchData
         local nuclear = marchData.nuclear
         if nuclear==0 then
            return true
         end 
    end
    return false
end


function RARadarManage:reset()
  self:clearRadarDatas()
end
------------------------------------------------------------------------

--获取主攻击者的信息
function RARadarManage:getshowLeaderData(RadarData)
   local  marchData=RadarData.marchData
   local info={}
   --科技0
   info.playerIcon=nil
   info.playerName=nil
   info.playerPos=nil
   info.playerLevel=nil
   info.playerArriveTime=nil
   info.soldierNum=nil
   info.soldierMem=nil
   info.massMarchStartTime = nil
   if marchData:HasField('leader') then
        local leaderData=marchData.leader

        --玩家姓名 科技1
        info.playerIcon=leaderData.icon
        info.playerName=leaderData.name

        --玩家坐标 科技2
        if marchData:HasField('originalX') and marchData:HasField('originalY') then
            info.playerPos=_RALang("@WorldCoordPos",marchData.originalX,marchData.originalY)

        end

        --到达时间 科技3
        if marchData:HasField('arrivalTime') then
            info.playerArriveTime=RadarData.arrivalTime
        end
        --集结是到达的时间
        if marchData:HasField('massMarchStartTime') then
            info.massMarchStartTime=math.floor(marchData.massMarchStartTime/1000)
        end 

        --部队数量 科技4

        local armyInfo=leaderData.armyInfo
        local armyInfoCount=#armyInfo
        local totalSoldier=0
        if armyInfoCount>0 then
            for i=1,armyInfoCount do
                local leaderArmy=armyInfo[i]
                totalSoldier=totalSoldier+leaderArmy.count
            end
        end 
        info.isAbout=false
        if marchData:HasField('leaderArmyTotalAbout') then
            info.soldierNum=marchData.leaderArmyTotalAbout
        	info.isAbout = true
        else
        	if totalSoldier>0 then
        		info.soldierNum=totalSoldier
        	end 
        end 
        
        if leaderData:HasField('about') then
            info.isAbout=leaderData.about
        end 

        --部队组成 只显示icon 科技5
        local armyIds=marchData.armyIds
        if #armyIds>0 then
            info.soldierMem=armyIds
            info.soldierMemCount=false
        else
            -- --部队组成 只显示icon和大约士兵数量 科技6
            if armyInfoCount>0 then
            	info.soldierMem=armyInfo
            	info.soldierMemCount=true
            end  
        end


        if leaderData:HasField('level') then
            info.playerLevel=leaderData.level
        end 
            
        -- --指挥官加成 科技10
        -- local buff=marchData.buff
        -- local buffCount=#buff
        -- if buffCount>0 then
        -- 	info.buff=buff
        -- else
        -- 	info.buff={}
        -- end 


   end 
   return info
end

--获取联合部队的信息
function RARadarManage:getshowMemberData(RadarData)
    local  marchData=RadarData.marchData
    local info={}
   --显示联合部队信息 科技7 8 9
   local totalSoldier=nil
   local isTotalAbout=nil
   if marchData:HasField("armyTotalAbout") then
        totalSoldier=marchData.armyTotalAbout
        isTotalAbout=true
   end 
  
    local memData=marchData.member
    local count=#memData
    if count>0 then
        local tmpTotal=0
        for i=1,count do
            local t={}
            local memberInfo=memData[i]
            t.playerIcon=memberInfo.icon
            t.playerLevel=memberInfo.level
            t.playerName=memberInfo.name
            t.playerPos=_RALang("@WorldCoordPos",marchData.originalX,marchData.originalY)
            t.playerArriveTime=RadarData.arrivalTime
            local memberArmy=memberInfo.armyInfo
            local memNum=#memberArmy
            local memTotalCount=0
            for j=1,memNum do
            	local memArmyInfo = memberArmy[j]
            	memTotalCount=memTotalCount+memArmyInfo.count

            end
            t.soldierNum=memTotalCount
            tmpTotal=tmpTotal+memTotalCount
            t.soldierMem=memberArmy
            t.isAbout=false
            if memberInfo:HasField('about') then
                t.isAbout=memberInfo.about
                isTotalAbout=memberInfo.about
            end 
            t.soldierMemCount=true
            t.buff={}
            table.insert(info,t)
        end

        if tmpTotal>0 then
            totalSoldier=tmpTotal
        end    
    end 

    return info,totalSoldier,isTotalAbout
end



function RARadarManage:getshowAssistanceSoldierData(RadarData)
    local marchData=RadarData.marchData
	local info={}
	info.playerIcon=marchData.icon
	info.playerName=marchData.name
	info.playerPos=_RALang("@WorldCoordPos",marchData.originalX,marchData.originalY)
	info.playerArriveTime=RadarData.arrivalTime
	info.isAbout=false
    info.soldierMemCount=true

    local armyDatas=marchData.armyInfo
    info.soldierMem=armyDatas
    local count=#armyDatas
    local soldierTotalCount=0
    if count>0 then
        for i=1,count do
            local armyData=armyDatas[i]
            soldierTotalCount=soldierTotalCount+armyData.count
        end

        info.soldierNum=soldierTotalCount
    end 

    return info
end


function RARadarManage:getshowAssistanceResourceData(RadarData)
    local marchData=RadarData.marchData
	local info={}
	info.playerIcon=marchData.icon
	info.playerName=marchData.name
	info.playerPos=_RALang("@WorldCoordPos",marchData.originalX,marchData.originalY)
	info.playerArriveTime=RadarData.arrivalTime
	info.isAbout=false
    info.soldierMemCount=true

    local resourceDatas=marchData.resources
    info.soldierMem=resourceDatas
    local count=#resourceDatas
    local resourceTotalCount=0
    if count>0 then
        for i=1,count do
            local resourceData=resourceDatas[i]
            resourceTotalCount=resourceTotalCount+resourceData.itemCount
        end

        info.soldierNum=resourceTotalCount
    end 

    return info
end

--超级武器
function RARadarManage:getshowSuperWeaponData(RadarData)

    local marchData=RadarData.marchData
    local info={}
    info.nuclear = marchData.nuclear  --1为核弹 0为雷暴
    info.isSuperWeapon = true
    info.playerIcon=nil
    info.playerName=nil
    info.playerPos=_RALang("@WorldCoordPos",marchData.centerX,marchData.centerY)
    info.playerArriveTime=nil
    if marchData:HasField("guildIcon") then
        info.playerIcon = marchData.guildIcon
    end
    if marchData:HasField("guildName") then
        info.playerName = marchData.guildName
    end 
    if marchData:HasField("explosionTime") then
        info.playerArriveTime = RadarData.explosionTime
    end 
    return info 
end

-- enum MarchTargetPointType
-- {
--     PLAYER_CITY_POINT        = 1;   // 玩家城点
--     RESOURCE_POINT           = 2;   // 资源点
--     QUARTERED_POINT          = 3;   // 驻扎点
--     GUILD_BASTION_POINT      = 4;   // 联盟堡垒
--     LAUNCH_PLATFORM_POINT    = 5;   // 发射平台
--     CAPITAL_POINT            = 6;   // 首都
-- }


function RARadarManage:getShowTitleByUuid(uuid,Type)
    local radarData=self:getRadarDataByUuid(uuid)
    local targetType=radarData.targetType

    local isExist =radarData.isExist 
    if targetType~=World_pb.PLAYER_CITY_POINT and not isExist then
        return _RALang("@RadarSpyMarchTitle1")
    end 
    local World_pb=RARequire("World_pb")
    local keyStr=""
    if Type==self.Type.MASSWAIT then
        keyStr="@RadarMassWaitMarchTitle"
    elseif Type==self.Type.RadarMassMarchTitle then
        keyStr="@RadarMassWaitMarchTitle"
    elseif Type==self.Type.ATTACK then 
        keyStr="@RadarSpyMarchTitle"
    end 

    local param=""
    if targetType==World_pb.PLAYER_CITY_POINT then
        param=_RALang("@PlayerBase")
    elseif targetType==World_pb.RESOURCE_POINT then
        param=_RALang("@PlayerResPoint")
    elseif targetType==World_pb.QUARTERED_POINT then
        param=_RALang("@PlayerCampPoint")
    elseif targetType==World_pb.GUILD_BASTION_POINT then
        param=_RALang("@PlayerAllianceBase")
    elseif targetType==World_pb.LAUNCH_PLATFORM_POINT then
        param=_RALang("@PlayerLanuchPlatform")
    elseif targetType==World_pb.CAPITAL_POINT then
        param=_RALang("@PlayerCapital")
    end 

    local title=_RALang(keyStr,param)
    return title
end

return RARadarManage

--endregion
