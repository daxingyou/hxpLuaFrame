-- RAMissionHelper.lua
-- Author: xinghui
-- Using: 副本helper

local RAMissionActionManager = RARequire("RAMissionActionManager")

local RAMissionHelper = {}

local msgCodes = 
{
    MessageDef_MissionBarrier.MSG_ActionEnd,
}

RAMissionHelper._instance = nil
--[[
    desc: 返回RAMissionHelper的实例
]]
function RAMissionHelper:new()
    if self._instance == nil then
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:_registerHandler()
        self._instance = o
    end
    return self._instance
end

--[[
    desc: 入口
]]
function RAMissionHelper:Enter(data)
    self:_registerHandler()
end

--[[
    desc: 注册消息回调
]]
function RAMissionHelper:_registerHandler()
    for _, msgCode in pairs(msgCodes) do
        MessageManager.registerMessageHandler(msgCode, self._onReceiveMessage)
    end
end

--[[
    desc: 消息回调函数
]]
function RAMissionHelper._onReceiveMessage(msg)
    local msgId = msg.messageID
    if msgId == MessageDef_MissionBarrier.MSG_ActionEnd then
        RAMissionHelper:_actionEndHandler(msg)
    end
end

--[[
    desc: 动作结束消息的回调
]]
function RAMissionHelper:_actionEndHandler(msg)
    local actionId = msg.actionId
    RAMissionActionManager:actionEnd(actionId)
end

--[[
    desc: 取消消息回调
]]
function RAMissionHelper:_unRegisterHandler()
    for _, msgCode in pairs(msgCodes) do
        MessageManager.removeMessageHandler(msgCode, self._onReceiveMessage)
    end
end

--[[
    desc: 结束
]]
function RAMissionHelper:Exit(data)
    self:_unRegisterHandler()
end

return RAMissionHelper