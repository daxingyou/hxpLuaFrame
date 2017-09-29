-- RAChangeLabelAction.lua
-- Author: xinghui
-- Using: 显示页Actin

local UIExtend              = RARequire("UIExtend")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RAStringUtil          = RARequire("RAStringUtil")
local RAChangeLabelAction   = RAActionBase:new()

--[[
    desc: changelabelAction入口
]]
function RAChangeLabelAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        local labelTTF = UIExtend.getCCLabelTTFFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        if labelTTF then
            UIExtend.setCCLabelString(target.ccbfile, self.constActionInfo.varibleName, _RALang(self.constActionInfo.param))
        else
            UIExtend.setCCLabelHTMLString(target.ccbfile, self.constActionInfo.varibleName, RAStringUtil:getHTMLString(self.constActionInfo.param))
        end
    end

    self:End()
end

return RAChangeLabelAction