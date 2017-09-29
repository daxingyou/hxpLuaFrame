-- RAShowPageAction.lua
-- Author: xinghui
-- Using: 显示页Actin

local RARootManager         = RARequire("RARootManager")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RAShowPageAction      = RAActionBase:new()

--[[
    desc: 显示页action的入口
]]
function RAShowPageAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    
    if self.constActionInfo.varibleName == "RAMissionBarrierPage" then
        if self.constActionInfo.param == "true" then
            RARootManager.AddBarrierPage()
        else
            RARootManager.RemoveBarrierPage()
        end
    elseif self.constActionInfo.varibleName == "RAMissionBarrierGuideDialogPage" then
        if self.constActionInfo.param == "true" then
            RARootManager.AddBarrierGuideDialogPage()
        else
            RARootManager.RemoveBarrierGuideDialogPage()
        end
    end

    self:End()
end



return RAShowPageAction