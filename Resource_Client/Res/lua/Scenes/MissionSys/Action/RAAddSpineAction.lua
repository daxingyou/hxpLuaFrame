-- RAAddSpineAction.lua
-- Author: xinghui
-- Using: 显示Actin

local RAWorldConfig         = RARequire("RAWorldConfig")
local missionaction_conf    = RARequire("missionaction_conf")
local RAMissionVar          = RARequire("RAMissionVar")
local UIExtend              = RARequire("UIExtend")
local RAActionBase          = RARequire("RAActionBase")

local RAAddSpineAction       = RAActionBase:new()

--[[
    desc: addspineAction入口
]]
function RAAddSpineAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    local target = self:getTarget()

    if target then
        if self.constActionInfo.param == "false" then
            target:removeFromParentAndCleanup(true)
            RAMissionVar:deleteCCBOwner(self.constActionInfo.actionTarget)
        else
            local spineName = self.constActionInfo.param
            CCTextureCache:sharedTextureCache():addColorMaskKey('BLUE', RAColorUnpack({r = 45,  g = 140, b = 248}))
            local spineNode = SpineContainer:create(spineName .. '.json', spineName .. '.atlas', 'BLUE')
            if spineNode then
                local parentNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
                if parentNode then
                    spineNode:setPositionY(0 - 128 - 6)
                    parentNode:addChild(spineNode)
                end

                if self.constActionInfo.name and self.constActionInfo.name ~= "" then
                    RAMissionVar:addCCBOwner(self.constActionInfo.name, spineNode)
                else
                    RAMissionVar:addCCBOwner(spineName, spineNode)
                end
            end
        end
    end

    self:End()
end


return RAAddSpineAction