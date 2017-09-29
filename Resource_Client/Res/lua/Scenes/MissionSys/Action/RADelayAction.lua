-- RADelayAction.lua
-- Author: xinghui
-- Using: 延迟Actin

local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RADelayAction         = RAActionBase:new()

--[[
    desc: delayAction的入口
]]
function RADelayAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()
    local delayTime = tonumber(self.constActionInfo.param)
    local this = self
    performWithDelay(target:getRootNode(), function()
        this:End()
    end, delayTime)
end


return RADelayAction