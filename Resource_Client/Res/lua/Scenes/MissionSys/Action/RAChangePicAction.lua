-- RAChangePicAction.lua
-- Author: xinghui
-- Using: 设置图片Actin

local UIExtend              = RARequire("UIExtend")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RAChangePicAction     = RAActionBase:new()

--[[
    desc: changepicAction的入口
]]
function RAChangePicAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        local spriteNode = UIExtend.getCCSpriteFromCCB(target.ccbfile, self.constActionInfo.varibleName)
        if spriteNode then
            spriteNode:setTexture(self.constActionInfo.param);
        else
            --UIExtend.addSpriteToNodeParent(target.ccbfile, self.constActionInfo.varibleName, self.constActionInfo.param)
            local parentNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
            local sprite = CCSprite:create(self.constActionInfo.param)
            if parentNode and sprite then
                parentNode:addChild(sprite)
            end
        end
    end

    self:End()
end

return RAChangePicAction