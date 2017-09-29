

local GuildManor_pb = RARequire('GuildManor_pb')

local RATerritoryDataManager = 
{
	mTerritoryMap = {},

	-- 核弹数据
	mBombMap = {},

	mInit = false,

	-- {territoryId = guildId}
	mOwnerMap = {},

	-- 核弹井数据
	mNuclearInfo = nil
}

function RATerritoryDataManager:reset()
	self.mTerritoryMap = {}

	-- 核弹数据
	self.mBombMap = {}

	self.mInit = false

	-- {territoryId = guildId}
	self.mOwnerMap = {}

	-- 核弹井数据
	self.mNuclearInfo = nil	
end

function RATerritoryDataManager:SyncTerritory(territoryPB)
	self:_init()

	local id = territoryPB.manorId
	local territoryInfo = self.mTerritoryMap[id]

	if territoryInfo == nil then
		CCLuaLog('>>>>>>No Such Territory Id: ' .. id .. ' <<<<<<<<')
		return
	end
	
	territoryInfo.guildId = territoryPB.guildId
	territoryInfo.guildName = territoryPB.guildName
	territoryInfo.guildTag = territoryPB.guildTag
	territoryInfo.guildFlag = territoryPB.guildFlag
	self.mTerritoryMap[id] = territoryInfo
end

--[[
	// 已发射出来的核弹信息
	message NuclearBomb
	{
		required string bombId = 1;
		required int32 guildId = 2;
		required string guildName = 3;
		required int64 launchTime = 4;	
		required int32 firePosX = 5;
		required int32 firePosY = 6;
		required int64 explodeTime = 7;	
		required int64 disappearTime = 8;
	}
--]]
function RATerritoryDataManager:SyncBomb(bombPb)
	if bombPb == nil then return end
	
	if bombPb.nuclearType == GuildManor_pb.NO_NULCRAR then
		return
	end
	local bombData = self.mBombMap[bombPb.bombId]
	local isInitBomb = false
	if bombData == nil then
		bombData = {}		
		isInitBomb = true
	end	
	bombData.bombId = bombPb.bombId
	bombData.guildId = bombPb.guildId
	bombData.guildName = bombPb.guildName
	bombData.launchTime = bombPb.launchTime
	bombData.firePosX = bombPb.firePosX
	bombData.firePosY = bombPb.firePosY
	bombData.explodeTime = bombPb.explodeTime
	bombData.disappearTime = bombPb.disappearTime
	bombData.nuclearType = bombPb.nuclearType
	self.mBombMap[bombPb.bombId] = bombData

	if isInitBomb then
		local RAWorldMath = RARequire('RAWorldMath')
		RAWorldMath:CheckAndPlayVideo(RACcp(bombData.firePosX, bombData.firePosY), 'bomb_target')
	end

	local RARootManager = RARequire('RARootManager')
	if RARootManager.GetIsInWorld() then
		local RATerritoryManager = RARequire('RATerritoryManager')
		RATerritoryManager:ShowBombAreaByData(bombData)
	end
	local common = RARequire('common')
	local currTime = common:getCurTime()
	print('RATerritoryDataManager:SyncBomb add bomb id:'..bombData.bombId)
	print('RATerritoryDataManager:SyncBomb bomb last time:'..tostring(bombData.explodeTime / 1000 - currTime))

	-- 尝试刷新核弹显示
	-- 暂时没有区分是登陆还是新增核弹，讲道理应该只有新增的时候去刷新
	MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUINuclearPart)
end

function RATerritoryDataManager:AddBombByClientForShow(force)
	local RAWorldVar = RARequire('RAWorldVar')
	local clientBombId = 'what_the_bomb_fk'
	local bombData = self.mBombMap[clientBombId]

	local common = RARequire('common')
	local currTime = common:getCurMilliTime()
	-- 超时的了话，就换个新的炸弹
	if bombData ~= nil and bombData.disappearTime < currTime then
		force = true
	end
	if bombData == nil or force then
		bombData = {}
		local launchTimeNeed = 60
		local explodeTimeNeed = math.random(120, 240)
		local disappearTimeNeed = math.random(100, 150)
		bombData.bombId = clientBombId
		bombData.guildId = 'some_one_ex'
		bombData.guildName = 'some_one_ex'
		bombData.launchTime = currTime + launchTimeNeed * 1000
		bombData.firePosX = RAWorldVar.MapPos.Core.x - math.random(5, 10)
		bombData.firePosY = RAWorldVar.MapPos.Core.y - math.random(5, 10)
		bombData.explodeTime = currTime + launchTimeNeed * 1000 + explodeTimeNeed * 1000
		bombData.disappearTime = currTime + launchTimeNeed * 1000 + explodeTimeNeed * 1000 + disappearTimeNeed * 1000
		self.mBombMap[clientBombId] = bombData

		print('add one bomb by client id:'..clientBombId)
		print('explodeTimeNeed:'..explodeTimeNeed..'   disappearTimeNeed:'..disappearTimeNeed)

		local RARootManager = RARequire('RARootManager')
		if RARootManager.GetIsInWorld() then
			local RATerritoryManager = RARequire('RATerritoryManager')
			RATerritoryManager:ShowBombAreaByData(bombData)
		end
	end
end

function RATerritoryDataManager:DisarmBomb(bombId)
	-- body	
	local RATerritoryManager = RARequire('RATerritoryManager')
	RATerritoryManager:RemoveBombAreaByBombId(bombId)
	self.mBombMap[bombId] = nil
	print('RATerritoryDataManager:DisarmBomb remove bomb id:'..bombId)
	-- 尝试刷新核弹显示
	-- 暂时没有区分是登陆还是新增核弹，讲道理应该只有新增的时候去刷新
	MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUINuclearPart)
end

-- 根据领地id获取核弹数据
function RATerritoryDataManager:GetBombDataById(bombId)	
	return self.mBombMap[bombId]
end


function RATerritoryDataManager:GetAllBombsData()
	return self.mBombMap or {}
end


function RATerritoryDataManager:GetAllTerritoryInfo()
	self:_init()
	return self.mTerritoryMap
end

-- 根据领地id获取领地数据
function RATerritoryDataManager:GetTerritoryById(id)
	self:_init()
	return self.mTerritoryMap[id]
end

-- 根据联盟id获取领地数据
function RATerritoryDataManager:GetTerritoryByGuildId(guildId)
	if guildId == nil or guildId == '' then return nil end

	for _, info in pairs(self.mTerritoryMap) do
		if info and info.guildId == guildId then
			return info
		end
	end  

	return nil
end

function RATerritoryDataManager:_init()
	if self.mInit then return end

	local territory_conf = RARequire('guild_territory_conf')
	local Utilitys = RARequire('Utilitys')
	local Const_pb = RARequire('Const_pb')
	
	for _, conf in pairs(territory_conf) do
		local id = conf.id

		local strongholdCfg = {}
		local strongholdIds = Utilitys.Split(conf.strongHoldId, '_')
		local strongholdPos = Utilitys.Split(conf.strongHoldPosition, '_')
		for _i, _id in ipairs(strongholdIds) do
			table.insert(strongholdCfg, {
				id 		= _id,
				pos  	= Utilitys.getCcpFromString(strongholdPos[_i], ','),
				isOpen 	= false
			})
		end
		local bastionPos = Utilitys.getCcpFromString(conf.bastionPosition, ',')
		-- table.insert(strongholdCfg, {
		-- 	id 		= conf.bastionId,
		-- 	posStr 	= bastionPos,
		-- 	isOpen 	= false
		-- })

		self.mTerritoryMap[id] =
		{
			manorId 	= id,
			level 		= conf.level,
			buildingPos =
			{
				[Const_pb.GUILD_BASTION] 	= bastionPos
				-- [Const_pb.GUILD_SILO] 		= Utilitys.getCcpFromString(conf.fireingWell, ','),
				-- [Const_pb.GUILD_HOSPITAL] 	= Utilitys.getCcpFromString(conf.hospital, ','),
				-- [Const_pb.GUILD_WEATHER] 	= Utilitys.getCcpFromString(conf.weather, ','),
				-- [Const_pb.GUILD_SHOP] 		= Utilitys.getCcpFromString(conf.shop, ','),
				-- [Const_pb.GUILD_URANIUM] 	= Utilitys.getCcpFromString(conf.uranium, ','),
				-- [Const_pb.GUILD_MINE] 		= Utilitys.getCcpFromString(conf.supermine, ','),
				-- [Const_pb.GUILD_MIRACLE] 	= Utilitys.getCcpFromString(conf.miracle, ',')
			},
			bastionId 	= conf.bastionId,
			stronghold 	= strongholdCfg,
			hasMist 	= true,
			cannonCount = #(Utilitys.Split(conf.cannon or '', '_') or {})
		}
	end
	
	self.mInit = true
end

function RATerritoryDataManager:RecordOwnership(territoryId, guildId)
	self.mOwnerMap[territoryId] = guildId
end

function RATerritoryDataManager:GetGuildId(territoryId)
	return self.mOwnerMap[territoryId]
end

return RATerritoryDataManager