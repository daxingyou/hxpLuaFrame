-- RADeleteCcbAction.lua
-- Author: xinghui
-- Using: 删除ccb Actin

local RAMissionVar                  = RARequire("RAMissionVar")
local UIExtend                      = RARequire("UIExtend")
local missionaction_conf            = RARequire("missionaction_conf")
local RAActionBase                  = RARequire("RAActionBase")

local RADeleteCcbAction    = RAActionBase:new()

--[[
    desc: addccbaction入口
]]
function RADeleteCcbAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    local target = self:getTarget()

    if target then
        UIExtend.unLoadCCBFile(target)
        RAMissionVar:deleteCCBOwner(self.constActionInfo.actionTarget)
    end

    self:End()
end

return RADeleteCcbAction