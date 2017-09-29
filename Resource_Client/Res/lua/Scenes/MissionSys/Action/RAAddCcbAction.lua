-- RAAddCcbAction.lua
-- Author: xinghui
-- Using: 显示Actin

local UIExtend                      = RARequire("UIExtend")
local RAMissionVar                  = RARequire("RAMissionVar")
local RAActionBase                  = RARequire("RAActionBase")
local missionaction_conf            = RARequire("missionaction_conf")

local RAAddCcbAction    = RAActionBase:new()

--[[
    desc: addccbaction入口
]]
function RAAddCcbAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    local target = self:getTarget()

    local RAMissionBarrierTouchHandler  = RARequire("RAMissionBarrierTouchHandler")
    --添加ccb的 时候，要根据ccb的名字设置handler，防止不同的ccb使用相同的handler，这样会导致handler.ccbfile不准确
    local dotIndex = string.find(self.constActionInfo.param, ".ccbi")
    if not dotIndex then
        dotIndex = 1
    end
    local handlerName = string.sub(self.constActionInfo.param, 1, dotIndex-1)--构造handler的名字
    if RAMissionBarrierTouchHandler.SubCCBHandlers[handlerName] == nil then--如果handler不存在，那么构造
        RAMissionBarrierTouchHandler.SubCCBHandlers[handlerName] = {}
    end
    local subCcb = UIExtend.loadCCBFile(self.constActionInfo.param, RAMissionBarrierTouchHandler.SubCCBHandlers[handlerName])
    if subCcb then
        if target then
            UIExtend.addNodeToParentNode(target.ccbfile, self.constActionInfo.varibleName, subCcb)
        else
            --挂在top节点上
            local RARootManager = RARequire("RARootManager")
            RARootManager.mTopNode:addChild(subCcb,1000)
        end

        RAMissionVar:addCCBOwner(self.constActionInfo.param, RAMissionBarrierTouchHandler.SubCCBHandlers[handlerName])
    end

    self:End()
end



return RAAddCcbAction
