-- RAChangeParentAction.lua
-- Author: xinghui
-- Using: node切换parent Actin

local RAMissionVar          = RARequire("RAMissionVar")
local UIExtend              = RARequire("UIExtend")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RAChangeParentAction      = RAActionBase:new()

--[[
    desc: RAChangeParentAction的入口
]]
function RAChangeParentAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    
    local target = self:getTarget()


    if target then
        local desNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        if desNode then
            local ccbOwner = RAMissionVar:getCCBOwner(self.constActionInfo.param)
            if ccbOwner then
                ccbOwner.ccbfile:removeFromParentAndCleanup(false)
                desNode:addChild(ccbOwner.ccbfile)
            end
        end
    end

    self:End()
end

return RAChangeParentAction