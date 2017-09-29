--region RAArmyPushHandler.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAArmyPushHandler = {}

function RAArmyPushHandler:onReceivePacket(handler)
    local Army_pb = RARequire("Army_pb")
    local HP_pb = RARequire("HP_pb")
    local RACoreDataManager = RARequire('RACoreDataManager')
    
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_ARMY_S then
        
        local msg = Army_pb.HPArmyInfoSync();
        msg:ParseFromString(buffer)		
        if msg ~= nil then
            RACoreDataManager:onRecieveArmyInfo(msg)
        end
    -- elseif pbCode == HP_pb.FIRE_SOLDIER_S then
    --     local msg = Army_pb.HPFireSoldierResp()
    --     msg:ParseFromString(buffer)     
    --     if msg.result then
    --         --解雇成功 刷新
    --         MessageManager.sendMessage(MessageDef_FireSoldier.MSG_RATroopsInfoUpdate)
    --         MessageManager.sendMessage(MessageDef_FireSoldier.MSG_RAArmyDetailsPopUpUpdate)
    --     end
    end
end

return RAArmyPushHandler
--endregion
