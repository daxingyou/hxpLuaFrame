local RATerritoryPushHandler = {}

local HP_pb = RARequire('HP_pb')
local GuildManor_pb = RARequire('GuildManor_pb')
local RATerritoryDataManager = RARequire('RATerritoryDataManager')

function RATerritoryPushHandler:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    -- 领地同步
    if pbCode == HP_pb.GUILD_MANOR_SYNC then
		local msg = GuildManor_pb.HPGuildManorSync()
		msg:ParseFromString(buffer)

		self:_onSyncTerritory(msg)
        return
    end

    -- 核弹信息同步
	if pbCode == HP_pb.NUCLEAR_BOMB_SYNC then
		local msg = GuildManor_pb.HPNuclearBombSync()
		msg:ParseFromString(buffer)

		self:_onSyncBomb(msg)
        return
    end

    -- 核弹取消
	if pbCode == HP_pb.DISARM_NUCLEAR_BOMB_SYNC then
		local msg = GuildManor_pb.HPNuclearBombRemove()
		msg:ParseFromString(buffer)

		self:_onDisarmBomb(msg)
        return
    end
end

function RATerritoryPushHandler:_onSyncTerritory(msg)
	for _, territoryInfo in ipairs(msg.manorInfo) do
		RATerritoryDataManager:SyncTerritory(territoryInfo)
	end
	if #msg.manorInfo > 0 then
		MessageManager.sendMessage(MessageDef_World.MSG_Territory_Update)
	end
end



function RATerritoryPushHandler:_onSyncBomb(msg)
	for _, bombInfo in ipairs(msg.nuclearBomb) do
		RATerritoryDataManager:SyncBomb(bombInfo)
	end
end

function RATerritoryPushHandler:_onDisarmBomb(msg)
	RATerritoryDataManager:DisarmBomb(msg.bombId)
end

-- msg = NuclearInfo
function RATerritoryPushHandler:_onSyncNuclearInfo(msg)
	RATerritoryDataManager:SyncNuclearInfo(msg)
end

-- msg = GuildManorNuclearDelSync
function RATerritoryPushHandler:_onDelNuclearInfo(msg)
	RATerritoryDataManager:DelNuclearInfo(msg.type)
end


return RATerritoryPushHandler