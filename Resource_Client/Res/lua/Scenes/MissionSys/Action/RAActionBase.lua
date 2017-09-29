-- RAActionBase.lua
-- Author: xinghui
-- Using: Action的基类

local missionaction_conf    = RARequire("missionaction_conf")
local RAMissionVar          = RARequire("RAMissionVar")
local UIExtend              = RARequire("UIExtend")

local RAActionBase = {
    actionId = 0,
    constActionInfo = nil
}

--[[
    desc: action基类的构造
]]
function RAActionBase:new(o)
    self:resetData()
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[
    desc: Action开始的入口，可重写
]]
function RAActionBase:Start()
    
end

--[[
    desc: 重置数据
]]
function RAActionBase:resetData()
    self.actionId = 0
end

--[[
    desc: 获得action作用的target
]]
function RAActionBase:getTarget()
    if self.constActionInfo == nil then
        self.constActionInfo = missionaction_conf[self.actionId]
    end

    local target = RAMissionVar:getCCBOwner(self.constActionInfo.actionTarget)

    return target
end

--[[
    desc: Action结束，可重写
]]
function RAActionBase:End(data)
    local message = {
        actionId = self.actionId
    }
    
    MessageManager.sendMessage(MessageDef_MissionBarrier.MSG_ActionEnd, message)
end

return RAActionBase
