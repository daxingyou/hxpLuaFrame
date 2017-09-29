-- RARunAniAction.lua
-- Author: xinghui
-- Using: 播放动画Actin

local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RARunAniAction        = RAActionBase:new()

--[[
    desc: runaniaction的入口
]]
function RARunAniAction:Start(data)
    self. constActionInfo = missionaction_conf[self.actionId]

    local target = self:getTarget()

    if target then
        if target.registerActionListener then
            target:registerActionListener(self)                     --将action注册回ccbfile播放完动画的监听
        end
        target.ccbfile:runAnimation(self.constActionInfo.param)
    end
end

--[[
    desc: animation播放完成后的回调
]]
function RARunAniAction:onAnimationDone(aniName)
    if aniName == self.constActionInfo.param then
        self:End()
    end
end

return RARunAniAction