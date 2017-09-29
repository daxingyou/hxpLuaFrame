--region RAStatePushHandler.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAStatePushHandler = {}

function RAStatePushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Player_pb = RARequire("Player_pb")
    local Const_pb = RARequire("Const_pb")
    local RACoreDataManager = RARequire('RACoreDataManager')

    
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.STATE_INFO_SYNC_S then
        local msg = Player_pb.StateInfoSync();
        msg:ParseFromString(buffer)		
        if msg ~= nil then
            local size = #msg.stateInfos
            local Const_pb=RARequire("Const_pb")
            local nextAvailableReward=nil
            for i = 1,size do 
                local oneState = msg.stateInfos[i]

                --领奖的等级
                if  Const_pb.REWARD_LEVEL==oneState.key then
                    if oneState.value and oneState.value~=1 then
                        nextAvailableReward = oneState.value
                    end   
                end 

                if oneState.type == Const_pb.BUFF_STATE then
                    local RABuffManager = RARequire("RABuffManager")
                    RABuffManager:syncOneBuff(oneState)
                    --刷新基地增益状态显示页面
                    MessageManager.sendMessage(MessageDef_CityGainStatus.MSG_CityGain_Changed,data)
                elseif oneState.type == Const_pb.PLAYER_STATE then
                    RACoreDataManager:syncStateInfo(oneState)
                else
                    assert(false,"RACoreDataManager:syncStateInfo type error ")
                end
            end

            local RALordUpgradeManager=RARequire("RALordUpgradeManager")
            RALordUpgradeManager.playerRewardLevel=nextAvailableReward

        end
    end
end

return RAStatePushHandler
--endregion
