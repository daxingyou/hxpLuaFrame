-- RAShowTransformAction.lua
-- Author: xinghui
-- Using: 显示过场Actin

local RARootManager                 = RARequire("RARootManager")
local UIExtend                      = RARequire("UIExtend")
local RAActionBase                  = RARequire("RAActionBase")

local RAShowTransformAction         = RAActionBase:new()

RAShowTransformAction.mCutSceneHandler = nil

local this = nil

--[[
    desc: RAShowTransformAction入口
]]
function RAShowTransformAction:Start(data)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_CutScene, self.OnReceiveMessage)
    this = self

    self.mCutSceneHandler = UIExtend.GetPageHandler('RAMainUICutScenePage')
    self.mCutSceneHandler:Enter()
    UIExtend.AddPageToNode(self.mCutSceneHandler, RARootManager.mSceneTransNode)
end

--[[
    desc: 接收消息
]]
function RAShowTransformAction.OnReceiveMessage(message)
    if message.messageID == MessageDef_RootManager.MSG_CutScene then
        local progress = message.progress
        if progress == 0 then
            --cut scene begain
        elseif progress == 1 then
            --cut scene end
            this:End()
        end
    end
end

--[[
    desc: RAShowTransformAction动作结束
]]
function RAShowTransformAction:End(data)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_CutScene, self.OnReceiveMessage)
    if self.mCutSceneHandler then
        self.mCutSceneHandler:Exit()
        UIExtend.unLoadCCBFile(self.mCutSceneHandler)
        self.mCutSceneHandler = nil
    end

    local message = {
        actionId = self.actionId
    }
    MessageManager.sendMessage(MessageDef_MissionBarrier.MSG_ActionEnd, message)
    this = nil
end

return RAShowTransformAction