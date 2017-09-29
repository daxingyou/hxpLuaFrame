--联盟管理
RARequire('extern')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire('RARootManager')
local Const_pb = RARequire('Const_pb')
local HP_pb = RARequire('HP_pb')
local RAStringUtil = RARequire('RAStringUtil')

local RAAllianceManager = class('RAAllianceManager',{
	selfAlliance = nil,--自己联盟
	authority = nil, --权限
	recommendArr = nil, --推荐联盟
	isShowJoinPage = false,
	joinedGuild = false,
	tempAnnouncement = '',--临时公告
	applyNum = 0,  --申请的个数
	helpNum = 0,	--帮助的个数
	manorDatas = {},	--领地数据
	nuclearInfo = nil,--核弹发射井
	allianScore = 0,--联盟积分
})


function RAAllianceManager:reset()
    self.selfAlliance = nil 
    self.authority = nil
    self.recommendArr = nil 
    self.isShowJoinPage = false
    self.joinedGuild = false
    self.tempAnnouncement = ''
end

--自动加入
function RAAllianceManager:autoJoin()
	CCLuaLog('RAAllianceManager:autoJoin()')
	if self.recommendArr == nil or #self.recommendArr == 0 then 
		RARootManager.ShowMsgBox(_RALang('@HaveNoRecommondAllianceList'))
	else
		for i=1,#self.recommendArr do
			local info = self.recommendArr[i]
			if info.openRecurit then 
				local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
				RAAllianceProtoManager:applyReq(info.id)
				break
			end 
		end
	end 
end

function RAAllianceManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
end

function RAAllianceManager:removeHandler()

	if self.netHandler ~= nil then 
		local RANetUtil = RARequire('RANetUtil')
		RANetUtil:removeListener(self.netHandler)
	end 
end

function RAAllianceManager:showSolePage()
	-- local RANetUtil = RARequire('RANetUtil')
	-- self.netHandler =  RANetUtil:addListener(HP_pb.GET_NUCLEAR_INFO_S, self) 
	-- RAAllianceProtoManager:reqNuclearInfo()

    local RARootManager = RARequire('RARootManager')
    RARootManager.OpenPage("RAAllianceSiloPage",nil,true,true,true)
end

function RAAllianceManager:refreshAllianceNoticeNum()
	local RAGameConfig =  RARequire('RAGameConfig')
	RARequire('MessageManager')
	
	local num = 0
	if self.selfAlliance ~= nil then 
		
		--联盟帮助
		num = num + self.helpNum

		--加联盟战争
    	local RANewAllianceWarManager =  RARequire('RANewAllianceWarManager')
    	local warNum = RANewAllianceWarManager:GetRedPointNum()

    	num = num + warNum

    	--联盟申请
    	local RAAllianceUtility =  RARequire('RAAllianceUtility')
		if RAAllianceUtility:getApplyIdById(self.authority) then 
			num = num + self.applyNum
		end     	
	end 

    local data={}
    data.menuType= RAGameConfig.MainUIMenuType.Alliance
    data.num = num
    data.isDirChange=true
    MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,data)

    local data={}
    data.menuType= RAGameConfig.MainUIMenuType.AllianceHelp
    data.num = self.helpNum
    data.isDirChange=true
    MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,data)
end

-- 是否在联盟中
function RAAllianceManager:IsInGuild()
	return self.selfAlliance ~= nil and self.selfAlliance.id ~= nil
end

-- 是否是盟友
function RAAllianceManager:IsGuildFriend(guildId)
	return self.selfAlliance ~= nil and guildId ~= nil and self.selfAlliance.id == guildId
end

-- 是否是盟主
function RAAllianceManager:IsGuildLeader()
	return self.selfAlliance ~= nil and self.authority == Const_pb.L5
end

-- 是否是生效的领地
function RAAllianceManager:IsActiveTerritory(territoryId)
	local activeId = self:getActiveManorId()
	return (activeId and activeId == territoryId)
end

-- 获取联盟缩写
function RAAllianceManager:GetGuildTag()
	return self.selfAlliance and self.selfAlliance.tag or ''
end

-- 获取联盟Id
function RAAllianceManager:GetGuildId()
	return self.selfAlliance and self.selfAlliance.id or ''
end

-- 是否可以修改超级矿类型
function RAAllianceManager:isAbleToChangeSuperMineRes()
	-- 必须在联盟中
	if not self:IsInGuild() then return false end
	local RAAllianceUtility = RARequire('RAAllianceUtility')
	return RAAllianceUtility:isAbleToChangeSuperMineRes(self.authority)
end

-- 是否可以建造超级武器发射平台
function RAAllianceManager:IsAbleToBuildLanchSilo()
	-- 必须在联盟中
	if not self:IsInGuild() then return false end

	-- 必须有建造权限
	local RAAllianceUtility = RARequire('RAAllianceUtility')
	if not RAAllianceUtility:isAbleToBuildLanchSilo(self.authority) then return false end

	-- 只能建造一个
	local platformInfo = self:GetNuclearPlatformInfo()
	if platformInfo ~= nil and platformInfo.machineState ~= GuildManor_pb.NONE_STATE then
		return false
	end

	return true
end

-- 能否发射超级武器
function RAAllianceManager:IsAbleToLaunchSuperWeapon(mapPos)
	-- 必须在联盟中
	if not self:IsInGuild() then return false end

	-- 必须有发射权限
	local RAAllianceUtility = RARequire('RAAllianceUtility')
	if not RAAllianceUtility:isAbleToLaunchBomb(self.authority) then return false end

	-- -- 联盟有领地并有核弹
	-- local RATerritoryDataManager = RARequire('RATerritoryDataManager')
	-- local territoryData = RATerritoryDataManager:GetTerritoryByGuildId(self.selfAlliance.id)

	-- --没有领地
	-- if territoryData == nil then 
	-- 	return false 
	-- end 

	-- --判断是否已经在发射状态了
	-- local nuclearData = RATerritoryDataManager:GetNuclearDataById(territoryData.manorId)
	-- if nuclearData == nil or nuclearData.launchTime > 0 then
	-- 	return false 
	-- end

	if self.selfAlliance.nuclearReady and self:IsInSiloRange(mapPos) then 
		return true 
	end 

	--是否有剩余核弹
	return false
end

-- 是否在超级武器发射范围内
function RAAllianceManager:IsInSiloRange(mapPos, viewPos)
	if self.mNuclearInfo == nil then
		return false
	end

	local centerPos = self:GetSiloPosition()
	if centerPos == nil then
		return false
	end

	local range = self:GetSiloLaunchRadius()
	if range == nil then
		return false
	end

	local RAWorldMath = RARequire('RAWorldMath')
	return RAWorldMath:IsInRange(centerPos, range, mapPos, viewPos)
end

-- 获取发射平台或发射井的位置
function RAAllianceManager:GetSiloPosition()
	local centerPos = nil

	local launchInfo = self.mNuclearInfo.launchInfo or {}
	if launchInfo.launchType == GuildManor_pb.FROM_MACHINE then
		local platData = self:GetNuclearPlatformInfo()
		if platData ~= nil then
			centerPos = RACcp(platData.posX, platData.posY)
		end
	elseif launchInfo.launchType == GuildManor_pb.FROM_MANOR then
		local selfManorData = self:getManorDataById(self.selfAlliance.manorId)
		local weaponType = self:getSelfSuperWeaponType()
		centerPos = selfManorData.buildings[weaponType].pos
	end

	return centerPos
end

-- 获取发射平台或发射井的发射范围
function RAAllianceManager:GetSiloLaunchRadius()
	local weaponType = self:getSelfSuperWeaponType()
	local guild_const_conf = RARequire('guild_const_conf')
	if weaponType == Const_pb.GUILD_SILO then
		return guild_const_conf.nuclearLaunchRadius.value
	elseif weaponType == Const_pb.GUILD_WEATHER then
		return guild_const_conf.thunderLaunchRadius.value
	end
		
	return nil
end

--如果聊天页面中标签选择的是联盟的话,清空主页聊天显示内容，并把选中的联盟标签标示设置为世界的聊天
function RAAllianceManager:ClearChatContent()
    local RAChatManager = RARequire("RAChatManager")
    if RAChatManager.mChoosenTab == Const_pb.CHAT_ALLIANCE then
        RAChatManager.mChoosenTab = 0
        --local RAMainUIBottomBanner = RARequire("RAMainUIBottomBannerNew")
        --RAMainUIBottomBanner:refreshChatMsg("", Const_pb.CHAT_ALLIANCE, 1)
    	RAChatManager:updateMainUIBottomTabAndContent()
    end

    --刷新主页面帮助红点
    local RAGameConfig = RARequire("RAGameConfig")
    local data={}
    data.menuType= RAGameConfig.MainUIMenuType.AllianceHelp
    data.num = 0
    data.isDirChange=true
    MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,data)
end

function RAAllianceManager:initAllianceBuildData(buildingType,posString,buildingDatas)
	-- body
	if posString == nil then 
		return 
	end 

	local territory_building_conf = RARequire('territory_building_conf')
	local buildData = {}
	if buildingType == Const_pb.GUILD_CANNON then --巨炮
		local cannos = RAStringUtil:split(posString, '_')
		posString = cannos[1]
		buildData.cannonNum = #cannos
	-- 	buildData.pos = Utilitys.getCcpFromString(posString, ',') 
	-- 	local infos = RAStringUtil:split(posString, ',')
	-- 	buildData.confData = territory_building_conf[tonumber(infos[3])] 
	-- else 
	-- 	buildData.pos = Utilitys.getCcpFromString(posString, ',') 
	-- 	local infos = RAStringUtil:split(posString, ',')
	-- 	buildData.confData = territory_building_conf[tonumber(infos[3])] 
	end 

	buildData.pos = Utilitys.getCcpFromString(posString, ',') 
	local infos = RAStringUtil:split(posString, ',')
	buildData.confData = territory_building_conf[tonumber(infos[3])] 
	
	buildData.buildingType = buildingType
	buildingDatas[buildingType] = buildData
end


-- nil 没有超级武器 Const_pb.GUILD_SILO 核弹 Const_pb.GUILD_WEATHER 天气控制
function RAAllianceManager:getSelfSuperWeaponType()
	if self.selfAlliance == nil then 
		return nil 
	end
	local selfManorData = self:getManorDataById(self.selfAlliance.manorId)

	if selfManorData == nil then 
		return nil 
	end

	return selfManorData.superWeaponType 
end

-- function RAAllianceManager:isSelf
-- 	ManorId( ... )
-- 	-- body
-- end

function RAAllianceManager:getActiveManorId()
	if self.selfAlliance and self.selfAlliance.manorId then 
		return self.selfAlliance.manorId
	end 

	return nil
end

function RAAllianceManager:getSelfSuperWeaponData()
	local superWeaponType = self:getSelfSuperWeaponType()
	if superWeaponType == nil then 
		return nil 
	end 

	local selfManorData = self:getManorDataById(self.selfAlliance.manorId)
	return selfManorData.buildings[superWeaponType]
end

-----------------------------------------------------------------
-----------------------------------------------------------------
--同步自己当前的发射井数据
function RAAllianceManager:SyncNuclearInfo(msg)	
	local RAAllianceNuclearInfo = RARequire('RAAllianceNuclearInfo')
    local allianceNuclearInfo = RAAllianceNuclearInfo.new()
    allianceNuclearInfo:initByPb(msg)
    self.mNuclearInfo = allianceNuclearInfo
end

function RAAllianceManager:GetNuclearInfo()
	return self.mNuclearInfo
end

-- 删除核弹发射井或者发射平台
function RAAllianceManager:DelNuclearInfo(delType)
	if delType == GuildManor_pb.FROM_MANOR then
		-- 核弹井失效了
		self.mNuclearInfo = nil
	end

	if delType == GuildManor_pb.FROM_MACHINE then
		if self.mNuclearInfo ~= nil then
			-- 发射平台被打飞了
		end
	end
end


function RAAllianceManager:GetNuclearPlatformInfo()
	if self.mNuclearInfo then
		return self.mNuclearInfo.machineInfo
	end
	return nil
end

-- 获取当前是否有发射平台
function RAAllianceManager:GetIsHasPlatform()
	local platformInfo = self:GetNuclearPlatformInfo()
	if platformInfo ~= nil and platformInfo.machineState ~= GuildManor_pb.NONE_STATE then
		return true
	end
	return false
end

-----------------------------------------------------------------
-----------------------------------------------------------------



function RAAllianceManager:getCannoNumById(id)
	local data = self:getManorDataById(id)
	local cannonData = data.buildings[Const_pb.GUILD_CANNON]

	if cannonData == nil then 
		return 0
	end 

	return cannonData.cannonNum
end

--获得联盟领地数据
function RAAllianceManager:getManorDataById(id)
	
	if id == nil then 
		return nil 
	end 
	
	if self.manorDatas[id] == nil then 
		local territory_conf = RARequire('guild_territory_conf')
		local territory_building_conf = RARequire('territory_building_conf')		
		if territory_conf[id] == nil then 
			return nil 
		end 

		local data = {}
		data.manorId = id 
		data.level = territory_conf[id].level
		data.buildings = {}
		local conf = territory_conf[id]

		self:initAllianceBuildData(Const_pb.GUILD_BASTION,conf.bastionPosition,data.buildings) --联盟大本营
		self:initAllianceBuildData(Const_pb.GUILD_SILO,conf.fireingWell,data.buildings) --联盟核弹发射井
		self:initAllianceBuildData(Const_pb.GUILD_LAB,conf.lab,data.buildings) --联盟实验室
		self:initAllianceBuildData(Const_pb.GUILD_HOSPITAL,conf.hospital,data.buildings) --联盟医院
		self:initAllianceBuildData(Const_pb.GUILD_WEATHER,conf.weather,data.buildings) --联盟天气控制室
		self:initAllianceBuildData(Const_pb.GUILD_SHOP,conf.shop,data.buildings) --联盟商店
		self:initAllianceBuildData(Const_pb.GUILD_URANIUM,conf.uranium,data.buildings)--联盟铀矿
		self:initAllianceBuildData(Const_pb.GUILD_MINE,conf.superMine,data.buildings)--联盟超级矿
		self:initAllianceBuildData(Const_pb.GUILD_MIRACLE,conf.miracle,data.buildings)-- 联盟奇迹
		self:initAllianceBuildData(Const_pb.GUILD_ELECTRIC,conf.nuclearPower,data.buildings)-- 联盟发动站
		self:initAllianceBuildData(Const_pb.GUILD_CANNON,conf.cannon,data.buildings)-- 联盟巨炮
		
		-- 添加发射平台数据
		local movebleBuildData = nil
		if conf.fireingWell ~= nil then 
			data.superWeaponType = Const_pb.GUILD_SILO						
			movebleBuildData = territory_building_conf[Const_pb.NUCLEAR]
		elseif conf.weather ~= nil then 
			data.superWeaponType = Const_pb.GUILD_WEATHER
			movebleBuildData = territory_building_conf[Const_pb.WEATHER]
		else 
			data.superWeaponType = nil 
		end 
		if movebleBuildData ~= nil then
			local oneData = {}
			oneData.confData = movebleBuildData
			oneData.buildingType = Const_pb.GUILD_MOVABLE_BUILDING
			oneData.pos = RACcp(0, 0)
			local platData = self:GetNuclearPlatformInfo()
			if platData ~= nil then
				oneData.pos.x = platData.posX
				oneData.pos.y = platData.posY
			end
			data.buildings[oneData.buildingType] = oneData
		end

		self.manorDatas[id] = data
	end

	return self.manorDatas[id] 
end

return RAAllianceManager