-- RAGotoFightAction.lua
-- Author: xinghui
-- Using: 进入战斗Actin

local RARootManager         = RARequire("RARootManager")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RAGotoFightAction     = RAActionBase:new()

--[[
    desc: RAGotoFightAction的入口
]]
function RAGotoFightAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    RARootManager.ChangeScene(SceneTypeList.BattleScene, nil, {missionId = tonumber(self.constActionInfo.param)})

    self:End()
end

return RAGotoFightAction