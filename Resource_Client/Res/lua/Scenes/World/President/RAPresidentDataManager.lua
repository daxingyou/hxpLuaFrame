-- 元帅、国王战信息

local President_pb = RARequire('President_pb')
local RAWorldUtil = RARequire('RAWorldUtil')

local RAPresidentDataManager =
{
	-- 阶段信息
	mPeriodInfo =
	{
		-- 阶段类型：初始和平、和平、战争
		periodType = President_pb.Init,
		-- 期数
		turnCount = 1,

		-- 元帅战开始时间
		periodStartTime = 0,
		-- 临时大总统上任时间
		attackStartTime = 0,
		-- 和平时期开始时间
		peaceStartTime = 0
	},

	-- 王国信息
	mCountryInfo =
	{
		name = nil,
		icon = nil,
		modifyTimes = 0
	},

	-- 大总统信息
	mPresidentInfo =
	{
		playerId = nil,
		playerName = nil,
		playerIcon = nil,

		guildId = nil,
		guildName = nil,
		guildTag = nil,
		guildFlag = nil,

		-- (连续)任期开始时间
		tenureTime = 0
	},

	-- 临时大总统信息
	mTmpPresidentInfo =
	{
		playerId = nil,
		playerName = nil,
		playerIcon = nil,

		guildId = nil,
		guildName = nil,
		guildTag = nil,
		guildFlag = nil
	},

	-- 官职信息
	mOfficialInfo = {},

	-- 礼包信息
	mGiftInfo = {},

	-- 历代国王信息
	mPresidentsHistory = {},

	-- 国王战事件信息
	mEventsHistory = {},

	-- 是否已经初始化官职信息
	mOfficialInited = false,

	-- 其它服的总统信息(当前查看服)
	mCrossServerInfo =
	{
		-- 王国id
		k = 0,

		presidentInfo =
		{
			guildTag 	= nil,
			guildFlag 	= nil
		}
	}
}

function RAPresidentDataManager:Sync(pbMsg)
	local serverId = RAWorldUtil.kingdomId.tonumber(pbMsg.serverName)
	if not RAWorldUtil.kingdomId.isSelf(serverId) then
		self:_setCrossServerInfo(serverId, pbMsg)
		return
	end

	self.mPeriodInfo =
	{
		periodType 		= pbMsg.periodType,
		turnCount 		= pbMsg.turnCount,
		periodStartTime = pbMsg.periodStartTime,
		attackStartTime = pbMsg.attackStartTime,
		peaceStartTime 	= pbMsg.peaceStartTime
	}

	if pbMsg:HasField('countryName') then
		self.mCountryInfo =
		{
			name 		= pbMsg.countryName,
			icon 		= pbMsg.countryIcon,
			modifyTimes = pbMsg.countryModify or 0
		}
	else
		local president_const_conf = RARequire('president_const_conf')
		self.mCountryInfo =
		{
			name 		= _RALang(president_const_conf.defaultName.value),
			icon 		= president_const_conf.defaultFlag.value,
			modifyTimes = 0
		}
	end

	self.mPresidentInfo = {}
	if pbMsg:HasField('presidentId') then
		self.mPresidentInfo =
		{
			playerId 	= pbMsg.presidentId,
			playerName 	= pbMsg.presidentName,
			playerIcon 	= pbMsg.presidentIcon,

			guildId 	= pbMsg.presidentGuildId,
			guildName 	= pbMsg.presidentGuildName,
			guildTag 	= pbMsg.presidentGuildTag,
			guildFlag 	= pbMsg.presidentGuildFlagId,

			tenureTime 	= pbMsg.tenureTime or 0
		}
	end

	local lastTmpPresidentId = self.mTmpPresidentInfo.playerId
	self.mTmpPresidentInfo = {}
	if pbMsg:HasField('attackerId') then
		if lastTmpPresidentId ~= pbMsg.attackerId then
			--临时国王切换
			MessageManager.sendMessage(MessageDef_World.MSG_TmpPresident_Change)			
		end
		self.mTmpPresidentInfo =
		{
			playerId 	= pbMsg.attackerId,
			playerName 	= pbMsg.attackerName,
			playerIcon 	= pbMsg.attackerIcon,

			guildId 	= pbMsg.attackerGuildId,
			guildName 	= pbMsg.attackerGuildName,
			guildTag 	= pbMsg.attackerGuildTag,
			guildFlag 	= pbMsg.attackerGuildFlag
		}
	end

	MessageManager.sendMessage(MessageDef_World.MSG_PresidentInfo_Update)
end

function RAPresidentDataManager:SyncOfficialInfo(msg)
	for _, info in ipairs(msg.officers) do
		self.mOfficialInfo[info.officerId] =
		{
			officeId 	= info.officerId,
			playerId 	= info.playerId,
			playerName 	= info.playerName or '',
			playerIcon 	= info.playerIcon,
			endTime 	= info.endTime
		}
	end
	MessageManager.sendMessage(MessageDef_World.MSG_OfficialInfo_Update)
end

function RAPresidentDataManager:SyncGiftInfo(msg)
	self.mGiftInfo = {}
	for _, info in ipairs(msg.giftInfo) do
		self.mGiftInfo[info.giftId] =
		{
			giftId 		= info.giftId,
			remainCnt 	= info.residueNumber,
			totalCnt 	= info.totalNumber
		}
	end
	MessageManager.sendMessage(MessageDef_World.MSG_PresidentGift_Update)
end

-- msg = President_pb.PresidentHistorySync
function RAPresidentDataManager:SyncPresidentsHistory(msg)
	self.mPresidentsHistory = {}
	for _,v in ipairs(msg.history) do
		local oneHistory = {
			turnCount = v.turnCount,
			playerId = v.playerId,
			playerName = v.playerName,
			playerIcon = v.playerIcon,
			guildId = v.guildId,
			guildName = v.guildName,
			guildTag = v.guildTag,
			guildFlag = v.guildFlag,
		}
		table.insert(self.mPresidentsHistory, oneHistory)
	end	
    -- 最新的国王在上面
	local Utilitys = RARequire('Utilitys')
	Utilitys.tableSortByKeyReverse(self.mPresidentsHistory, 'turnCount')
	MessageManager.sendMessage(MessageDef_World.MSG_PresidentHistory_Update)
end

-- msg = President_pb.PresidentEventSync
function RAPresidentDataManager:SyncEventsHistory(msg)
	self.mEventsHistory = {}
	for _,v in ipairs(msg.event) do
		local oneEvent = {
			eventType = v.eventType,
			eventTime = v.eventTime,
			
			guildName = v.guildName,
			playerName = v.playerName,

			enemyGuildName = v.enemyGuildName,
			enemyPlayerName = v.enemyPlayerName,
		}
		table.insert(self.mEventsHistory, oneEvent)
	end
	-- 最新的记录在最上面
	local Utilitys = RARequire('Utilitys')
	Utilitys.tableSortByKeyReverse(self.mEventsHistory, 'eventTime')

	MessageManager.sendMessage(MessageDef_World.MSG_PresidentEvents_Update)
end
function RAPresidentDataManager:Clear()
	-- body
end

function RAPresidentDataManager:GetPeriodInfo()
	return self.mPeriodInfo
end

function RAPresidentDataManager:GetPresidentInfo()
	return self.mPresidentInfo
end

function RAPresidentDataManager:GetTmpPresidentInfo()
	return self.mTmpPresidentInfo
end

function RAPresidentDataManager:GetCountryInfo()
	return self.mCountryInfo
end

function RAPresidentDataManager:GetPresidentsHistory()
	return self.mPresidentsHistory
end

function RAPresidentDataManager:GetEventsHistory()
	return self.mEventsHistory
end

function RAPresidentDataManager:GetCurrentPeriod()
	return self.mPeriodInfo.periodType or President_pb.INIT
end

function RAPresidentDataManager:IsIniting()
	return self.mPeriodInfo.periodType == President_pb.INIT
end

function RAPresidentDataManager:IsAtPeace()
	return (self.mPeriodInfo.periodType == President_pb.PEACE or self:IsIniting())
end

function RAPresidentDataManager:IsAtWar()
	return self.mPeriodInfo.periodType == President_pb.WARFARE
end

function RAPresidentDataManager:IsPresident(playerId)
	return playerId and self.mPresidentInfo and (playerId == self.mPresidentInfo.playerId)
end

function RAPresidentDataManager:IsTmpPresident(playerId)
	return playerId and self.mTmpPresidentInfo and (playerId == self.mTmpPresidentInfo.playerId)
end

function RAPresidentDataManager:GetPresidentStatus()
	local isPeace = self:IsAtPeace()
	local periodEndTime = 0
	local periodTotalTime = 0
	local president_const_conf = RARequire('president_const_conf')
	local periodInfo = self:GetPeriodInfo()
	if isPeace then
		if self:IsIniting() then
			periodTotalTime = president_const_conf.initPeaceTime.value * 1000
			periodEndTime = (RAPlayerInfoManager.getServerOpenTime() or 0) + periodTotalTime			
		else
			periodTotalTime = president_const_conf.commonPeaceTime.value * 1000
			periodEndTime = (periodInfo.peaceStartTime or 0) + periodTotalTime			
		end
	else
		if self.mTmpPresidentInfo ~= nil 
			and self.mTmpPresidentInfo.playerId ~= nil
			and self.mTmpPresidentInfo.playerId ~= '' then
			periodTotalTime = president_const_conf.warfareTime.value * 1000
        	periodEndTime = (periodInfo.attackStartTime or 0) + periodTotalTime
		else
			periodTotalTime = president_const_conf.occupationTime.value * 1000
        	periodEndTime = (periodInfo.periodStartTime or 0) + periodTotalTime
		end
	end
	return isPeace, periodEndTime, periodTotalTime
end

-- 是否在总统府有驻军
function RAPresidentDataManager:HasGarrison()
	local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
	return (RAPresidentMarchDataHelper:CheckSelfIsQuartering()
		or RAPresidentMarchDataHelper:CheckSelfIsLeader())
end

function RAPresidentDataManager:GetOfficialInfo(officialId)
	return self.mOfficialInfo[officialId]
end

function RAPresidentDataManager:GetOfficialInfoByPlayerId(playerId)
	for _, info in pairs(self.mOfficialInfo) do
		if info and info.playerId == playerId then
			return info
		end
	end
	return nil
end

function RAPresidentDataManager:GetGiftInfo(giftId)
	return self.mGiftInfo[giftId]
end

function RAPresidentDataManager:DecreaseGiftCount(giftId, num)
	local info = self:GetGiftInfo(giftId)
	if info then
		info.remainCnt = info.remainCnt - num
		MessageManager.sendMessage(MessageDef_World.MSG_PresidentGift_Update)
	end
end

function RAPresidentDataManager:InitOfficialInfo()
	if not self.mOfficialInited then
	    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
	    RAWorldProtoHandler:sendGetOfficialsReq()
	end
end

function RAPresidentDataManager:_setCrossServerInfo(k, pbMsg)
	self.mCrossServerInfo =
	{
		k 				= k,
		presidentInfo 	= {}
	}
	if pbMsg:HasField('presidentId') then
		self.mCrossServerInfo.presidentInfo =
		{
			guildTag 	= pbMsg.presidentGuildTag,
			guildFlag 	= pbMsg.presidentGuildFlagId
		}
	end
	MessageManager.sendMessage(MessageDef_World.MSG_CrossServerPresidentInfo_Update)
end

function RAPresidentDataManager:GetCrossServerInfo(k)
	return k == self.mCrossServerInfo.k and self.mCrossServerInfo or {}
end

function RAPresidentDataManager:ClearCrossServerInfo(k)
	if k == self.mCrossServerInfo then
		self.mCrossServerInfo = {}
	end
end

return RAPresidentDataManager