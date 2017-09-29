-- RASetCapacityAction.lua
-- Author: xinghui
-- Using: 设置透明度

local UIExtend                      = RARequire("UIExtend")
local RAActionBase                  = RARequire("RAActionBase")
local missionaction_conf            = RARequire("missionaction_conf")

local RASetCapacityAction           = RAActionBase:new()

--[[
    desc: RASetCapacityAction的入口
]]
function RASetCapacityAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        local layerColor = UIExtend.getCCLayerColorFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        if layerColor then
            layerColor:setOpacity(tonumber(self.constActionInfo.param))
        end
    end

    self:End()
end


return RASetCapacityAction