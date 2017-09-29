-- RAMissionActionManager.lua
-- Author: xinghui
-- Using: 自定义动作管理类

local Utilitys                      = RARequire("Utilitys")
local RAMissionConfig               = RARequire("RAMissionConfig")

local missionaction_conf            = RARequire("missionaction_conf")

--所有action
local RADelayAction                 = RARequire("RADelayAction")
local RAShowAction                  = RARequire("RAShowAction")
local RARunAniAction                = RARequire("RARunAniAction")
local RAChangePicAction             = RARequire("RAChangePicAction")
local RAMoveCameraAction            = RARequire("RAMoveCameraAction")
local RAWaitForClickAction          = RARequire("RAWaitForClickAction")
local RAAddCcbAction                = RARequire("RAAddCcbAction")
local RAChangeLabelAction           = RARequire("RAChangeLabelAction")
local RAShowPageAction              = RARequire("RAShowPageAction")
local RAAddTouchLayerAction         = RARequire("RAAddTouchLayerAction")
local RAGotoNextStepAction          = RARequire("RAGotoNextStepAction")
local RAAddLineAction               = RARequire("RAAddLineAction")
local RAAddSpineAction              = RARequire("RAAddSpineAction")
local RARunSpineAniAction           = RARequire("RARunSpineAniAction")
local RASetCapacityAction           = RARequire("RASetCapacityAction")
local RAChangeParentAction          = RARequire("RAChangeParentAction")
local RAExecuteScriptFunctionAction = RARequire("RAExecuteScriptFunctionAction")
local RAShowTransformAction         = RARequire("RAShowTransformAction")
local RADeleteCcbAction             = RARequire("RADeleteCcbAction")
local RAGotoFightAction             = RARequire("RAGotoFightAction")
local RASendMessageAction           = RARequire("RASendMessageAction")
local RAGuidePageCircleAction       = RARequire("RAGuidePageCircleAction")
local RASetBarrierCameraScaleAction = RARequire("RASetBarrierCameraScaleAction")
local RAPlayMusicAction             = RARequire("RAPlayMusicAction")



local RAMissionActionManager = {
    actionList = {}                 --保存所有正在进行的action
}

--[[
    desc: 解析动作字符串，获得相应的actin并启动
    @param: actionStr 动作字符串 A,B,C,D
]]
function RAMissionActionManager:startAction(actionStr)
    local actionIds = Utilitys.Split(actionStr, ",")
    for i, actionId in ipairs(actionIds) do
        local action = self:getActionByActionId(tonumber(actionId))
        if action then
            self.actionList[tonumber(actionId)] = action
            action:Start()
        end
    end
end

--[[
    desc: 通过动作id返回动作实例
    @return: 返回动作实例
]]
function RAMissionActionManager:getActionByActionId(actionId)
    local action = nil

    local constActionInfo = missionaction_conf[actionId]
    if constActionInfo then
        if constActionInfo.actionType == RAMissionConfig.ActionType.shownode then
            action = RAShowAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.runani then
            action = RARunAniAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.gotonextstep then
            action = RAGotoNextStepAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.changepic then
            action = RAChangePicAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.movecamera then
            action = RAMoveCameraAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.waitforclick then
            action = RAWaitForClickAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.addccb then
            action = RAAddCcbAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.deleteccb then
            action = RADeleteCcbAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.changelabel then
            action = RAChangeLabelAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.showpage then
            action = RAShowPageAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.delaytime then
            action = RADelayAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.addtouchlayer then
            action = RAAddTouchLayerAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.addwalkline then
            action = RAAddLineAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.runspineani then
            action = RARunSpineAniAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.addspine then
            action = RAAddSpineAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.setcapacity then
            action = RASetCapacityAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.changeparent then
            action = RAChangeParentAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.executescriptfunction then
            action = RAExecuteScriptFunctionAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.showtransform then
            action = RAShowTransformAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.gotofight then
            action = RAGotoFightAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.sendmessage then
            action = RASendMessageAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.circletarget then
            action = RAGuidePageCircleAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.setcamerascale then
            action = RASetBarrierCameraScaleAction:new({actionId = actionId})
        elseif constActionInfo.actionType == RAMissionConfig.ActionType.playmusic then
            action = RAPlayMusicAction:new({actionId = actionId})
        end
    end

    return action
end

--[[
    desc: 一个Action结束,构造它的下一步action
]]
function RAMissionActionManager:actionEnd(actionId)
    if actionId then
        --把进行完的action进行销毁
        if self.actionList[actionId] then
            self.actionList[actionId] = nil
        end
        --检查顺序action
        local constActionInfo = missionaction_conf[actionId]
        if constActionInfo then
            if constActionInfo.nextActionId then
                self:startAction(constActionInfo.nextActionId)
            end
        end
    end
end

return RAMissionActionManager