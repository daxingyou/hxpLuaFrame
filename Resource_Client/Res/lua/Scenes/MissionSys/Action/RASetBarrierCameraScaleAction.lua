-- RASetBarrierCameraScaleAction.lua
-- Author: xinghui
-- Using: 修改camera Actin

local Utilitys                          = RARequire("Utilitys")
local missionaction_conf                = RARequire("missionaction_conf")
local RAActionBase                      = RARequire("RAActionBase")

local RASetBarrierCameraScaleAction     = RAActionBase:new()

--[[
    desc: addlineAction入口
]]
function RASetBarrierCameraScaleAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    --参数格式  scale,time
    local paramArr = Utilitys.Split(self.constActionInfo.param, ",")
    if paramArr then
        local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
        RAMissionBarrierManager:setCameraScale(tonumber(paramArr[1]), tonumber(paramArr[2]))
    end

    self:End()
end


return RASetBarrierCameraScaleAction