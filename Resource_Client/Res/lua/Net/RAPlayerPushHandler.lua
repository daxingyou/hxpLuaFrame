--region RAPlayerPushHandler.lua
--Date  2016/5/28
--Author zhenhui
--此文件由[BabeLua]插件自动生成

local RAPlayerPushHandler = {}

function RAPlayerPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Player_pb = RARequire("Player_pb")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_INFO_SYNC_S then
--        local msg = HPLogin.LoginStatusRequest();
--        msg:ParseFromString(buffer)
        --todo:登陆成功后进入mainstate
        local msg = Player_pb.HPPlayerInfoSync()
        msg:ParseFromString(buffer)
        if msg == nil or msg.playerInfo == nil then
            CCLuaLog("The HPPlayerInfoSync msg parsed Failed")
        else
            local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            RAPlayerInfoManager.setPlayerBasicInfo(msg.playerInfo)
        end
    elseif pbCode ==HP_pb.PLAYER_TALENT_SYNC_S then
        --天赋信息
        local Talent_pb = RARequire("Talent_pb")
        local msg = Talent_pb.HPTalentInfoSync()
        msg:ParseFromString(buffer)
        local RATalentManager = RARequire("RATalentManager")
        RATalentManager.setTalentInfo(msg)
    elseif pbCode == HP_pb.MISSION_LIST_SYNC_S then
        --任务推送
        local Mission_pb = RARequire("Mission_pb")
        local msg = Mission_pb.MissionListRes()
        msg:ParseFromString(buffer)
        local RATaskManager = RARequire("RATaskManager")
        RATaskManager.setTaskInfo(msg)
    elseif pbCode == HP_pb.MISSION_REFRESH_S then
        local Mission_pb = RARequire("Mission_pb")
        local msg = Mission_pb.MissionRefreshRes()
        msg:ParseFromString(buffer)
        local RATaskManager = RARequire("RATaskManager")
        RATaskManager.refreshTaskInfo(msg)
        MessageManager.sendMessage(MessageDef_Task.MSG_RefreshMainUITask)
    elseif pbCode == HP_pb.MISSION_UPDATE_SYNC_S then
        local Mission_pb = RARequire("Mission_pb")
        local msg = Mission_pb.MissionBonusRes()
        msg:ParseFromString(buffer)
        local RATaskManager = RARequire("RATaskManager")
        RATaskManager.addTaskFromServerData(msg)
    elseif pbCode == HP_pb.CUSTOM_DATA_SYNC then
        local msg = SysProtocol_pb.HPCustomDataSync()
        msg:ParseFromString(buffer)
        local RAGuideManager = RARequire("RAGuideManager")
        RAGuideManager.setGuideInfo(msg)
        local RASettingManager = RARequire("RASettingManager")
        RASettingManager:onRecieveSettingData(msg)
        local RAMissionFragmentManager = RARequire("RAMissionFragmentManager")
        RAMissionFragmentManager:setInfo(msg)
    elseif pbCode == HP_pb.PLAYER_EFFECT_INFO_SYNC_S then
        local msg = Player_pb.HPPlayerEffectSync()
		msg:ParseFromString(buffer)
        local size = #msg.effList
        for i = 1,size do 
            local oneEff = msg.effList[i]
            local RAPlayerEffect = RARequire("RAPlayerEffect")
            RAPlayerEffect:syncOneEffect(oneEff)
        end
    elseif pbCode == HP_pb.BUFF_INFO_S then
        local msg = Player_pb.PushBuffInfoRes()
		msg:ParseFromString(buffer)
        local size = #msg.buffInfo
        for i = 1,size do 
            local oneBuff = msg.buffInfo[i]
            local RABuffManager = RARequire("RABuffManager")
            RABuffManager:syncOneBuff(oneBuff)
        end
        return
    elseif pbCode == HP_pb.RECHARGE_INFO_SYNC then
        local Recharge_pb = RARequire("Recharge_pb")
        local msg = Recharge_pb.RechargeInfoSync()
        msg:ParseFromString(buffer)
        local RARealPayManager = RARequire("RARealPayManager")
        RARealPayManager.init()
        RARealPayManager.initServerProductionInfo(msg)
    elseif pbCode == HP_pb.RECHARGE_SUCCESS_SYNC then
        local Recharge_pb = RARequire("Recharge_pb")
        local msg = Recharge_pb.RechargeSuccessSync()
        msg:ParseFromString(buffer)
        local RARealPayManager = RARequire("RARealPayManager")
        RARealPayManager.onPayResult(msg)
    --SHIELD_PLAYER_INFO_SYNC_S
    elseif pbCode == HP_pb.SHIELD_PLAYER_INFO_SYNC_S then
        local msg = Player_pb.HPShieldPlayerInfoSync()
        msg:ParseFromString(buffer)
        local RAShieldManager = RARequire("RAShieldManager")
        RAShieldManager:OnReceivePacket(msg)
    elseif pbCode == HP_pb.SHIELD_PLAYER_S then
        local RARootManager = RARequire("RARootManager")
        RARootManager.ShowMsgBox("@ShieldPlayerSuccess")
        local msg = Player_pb.ShieldPlayerResp()
        msg:ParseFromString(buffer)
        if msg.shieldPlayer ~= nil then
            local RAShieldManager = RARequire("RAShieldManager")
            RAShieldManager:addOneShieldData(msg.shieldPlayer)
        end
        
    elseif pbCode == HP_pb.REMOVE_SHIELD_S then
        local RARootManager = RARequire("RARootManager")
        RARootManager.ShowMsgBox("@RemoveShieldPlayerOK")
        RARootManager.refreshPage("RASettingBlockPage")
    end
end

return RAPlayerPushHandler

--endregion
