-- RAGotoNextStepAction.lua
-- Author: xinghui
-- Using: 进行下一步的Actin

local RAActionBase      = RARequire("RAActionBase")

local RAGotoNextStepAction    = RAActionBase:new()

function RAGotoNextStepAction:Start(data)
    local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
    RAMissionBarrierManager:gotoNextStep()
    self:End()
end

return RAGotoNextStepAction