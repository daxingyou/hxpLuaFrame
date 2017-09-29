-- RAShowAction.lua
-- Author: xinghui
-- Using: 显示Actin

local UIExtend              = RARequire("UIExtend")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RAShowAction          = RAActionBase:new()

--[[
    desc: ShowAction的入口
]]
function RAShowAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        local node = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        if node then
            if self.constActionInfo.param == "true" then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end

    self:End()
end

return RAShowAction