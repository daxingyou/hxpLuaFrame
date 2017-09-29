-- RAWaitForClickAction.lua
-- Author: xinghui
-- Using: 显示页Actin

local RAActionBase          = RARequire("RAActionBase")
local RAWaitForClickAction  = RAActionBase:new()

--[[
    desc: waitForClickAction的入口  主要用在动态加载了ccb之后，响应ccb中的一些按钮事件，也可以在ccb的handler里面写按钮响应逻辑，那么就不需要这个Action了。
]]
function RAWaitForClickAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()
    if target then
        local functionName = self.constActionInfo.param
        local this = self
        if target.functionName == nil then
            target.functionName = function ()
                local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
                RAMissionBarrierManager:gotoNextStep()
                this:End()
            end
        end
    end
end

return RAWaitForClickAction