-- RAAddTouchLayerAction.lua
-- Author: xinghui
-- Using: 增加点击层Actin

local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RAAddTouchLayerAction = RAActionBase:new()

--[[
    desc: addtouchlayerAction入口
]]
function RAAddTouchLayerAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        if self.constActionInfo.param == "true" then
            target:addTouchLayer()
        else
            target:removeTouchLayer()
        end
    end

    self:End()
end

return RAAddTouchLayerAction