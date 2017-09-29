-- RARunSpineAniAction.lua
-- Author: xinghui
-- Using: 播放spine动画Actin

local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")

local RARunSpineAniAction = RAActionBase:new()

--[[
    desc: RARunSpineAniAction入口
]]
function RARunSpineAniAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        local this = self
        target:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
            if eventName == 'Complete' then
                if animationName == this.constActionInfo.param then
                    target:unregisterLuaListener()
                    this:End()
                    this = nil
                end
            end
        end)

        --判断是否需要倒序播放spine动画
        if self.constActionInfo.varibleName and self.constActionInfo.varibleName == "false" then
            target:runAnimation(0, self.constActionInfo.param, 1, false)
        else
            target:runAnimation(0, self.constActionInfo.param, 1, true)
        end
    end
end

return RARunSpineAniAction