-- RAAddLineAction.lua
-- Author: xinghui
-- Using: 显示Actin

local RAMissionVar          = RARequire("RAMissionVar")
local RARootManager         = RARequire("RARootManager")
local RAGetherLine          = RARequire("RAGetherLine")
local UIExtend              = RARequire("UIExtend")
local Utilitys              = RARequire("Utilitys")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RAAddLineAction       = RAActionBase:new()

--[[
    desc: addlineAction入口
]]
function RAAddLineAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()
    if target then
        local sceneHandler = RARootManager.GetCurrSceneHandler()            --获得当前scene的handler
        local parentNode = sceneHandler:getTopLayer()                       --获得当前scene的toplayer
        parentNode = parentNode or target.ccbfile

        local lifeTime = tonumber(self.constActionInfo.param)
        local varibleName = self.constActionInfo.varibleName
        local varibleArr = Utilitys.Split(varibleName, ",")

        local destPos = ccp(0, 0)
        if varibleArr then
            local destNode = UIExtend.getCCNodeFromCCB(target.ccbfile, varibleArr[1])
            destPos.x, destPos.y = destNode:getPosition()
            destPos = destNode:getParent():convertToWorldSpace(destPos);
        end
        for i=2, #varibleArr do
            local varible = varibleArr[i]
            local ccbNode = UIExtend.getCCNodeFromCCB(target.ccbfile, varible)
            if ccbNode then
                local lineOwner = RAGetherLine:createWithSpacePos(self.actionId + i, parentNode, {ccbfile = ccbNode}, destPos, lifeTime)
                RAMissionVar:addLineOwner(self.actionId + i, lineOwner)     --保存所有的lineOwner
            end
        end

        local this = self
        performWithDelay(parentNode, function()                     
            RAMissionVar:deleteAllLineOwner()
            this:End()
        end, lifeTime+1)                                                    --删除所有的lineOwner
    end
end


return RAAddLineAction