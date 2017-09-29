--联盟推送协议

local RAEquipPushHandler = {}

function RAEquipPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire('HP_pb')
	local RAEquipManager = RARequire("RAEquipManager")
	local Equipment_pb = RARequire("Equipment_pb")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    if pbCode == HP_pb.PLAYER_EQUIPMENT_SYNC_S then --同步装备信息
		local msg = Equipment_pb.HPEquipmentInfoSync()
		msg:ParseFromString(buffer)
        RAEquipManager:initEquipData(msg.equipments)
    end
end

return RAEquipPushHandler

