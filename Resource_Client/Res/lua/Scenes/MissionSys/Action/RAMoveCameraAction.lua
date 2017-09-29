-- RAMoveCameraAction.lua
-- Author: xinghui
-- Using: 移动摄像机Actin

local UIExtend              = RARequire("UIExtend")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RAMoveCameraAction    = RAActionBase:new()

local this = nil
--[[
    desc: movecameraAction的入口
]]
function RAMoveCameraAction:Start()
    MessageManager.registerMessageHandler(MessageDef_MissionBarrier.MSG_CameraMoveEnd, self.OnReceiveMessage)
    this = self

    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()
    if target then
        local toNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        local toNodePos = ccp(0, 0)
        toNodePos.x, toNodePos.y = toNode:getPosition()
        local pos = toNode:getParent():convertToWorldSpace(toNodePos)
        local time = tonumber(self.constActionInfo.param)
        local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
        RAMissionBarrierManager:cameraGotoSpacePos(pos,time,true)
    end
end

--[[
    desc: 场景摄像机结束的消息
]]
function RAMoveCameraAction.OnReceiveMessage(message)
    if message.messageID == MessageDef_MissionBarrier.MSG_CameraMoveEnd then
        this:End()
    end
end

--[[
    desc: 移动动作结束
]]
function RAMoveCameraAction:End(data)
    MessageManager.removeMessageHandler(MessageDef_MissionBarrier.MSG_CameraMoveEnd, self.OnReceiveMessage)

    local message = {
        actionId = self.actionId
    }
    MessageManager.sendMessage(MessageDef_MissionBarrier.MSG_ActionEnd, message)
    this = nil
end

return RAMoveCameraAction