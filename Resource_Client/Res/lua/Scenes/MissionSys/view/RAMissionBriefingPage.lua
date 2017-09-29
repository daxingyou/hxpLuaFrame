-- RAMissionBriefingPage.lua
-- Author: xinghui
-- Using: 副本详情页面

RARequire("BasePage")
local UIExtend                          = RARequire("UIExtend")
local RAMissionVar                      = RARequire("RAMissionVar")
local RAMissionBriefingManager          = RARequire("RAMissionBriefingManager")
local RAMissionHelper                   = RARequire("RAMissionHelper")


local RAMissionBriefingPage             = BaseFunctionPage:new(...)

RAMissionBriefingPage.helper            = nil

RAMissionBriefingPage.listenerActon     = nil                   --动画结束监听action，当动画结束后，通知该action

--[[
    desc: 简报页面入口
]]
function RAMissionBriefingPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("xxx.ccbi", self)
    RAMissionVar:addCCBOwner("xxx.ccbi", self)

    self.helper = RAMissionHelper:new()

    RAMissionBriefingManager:gotoNextStep()
end

--[[
    desc: 注册需要监听的Action
]]
function RAMissionBriefingPage:registerActionListener(action)
    self.listenerActon = action
end

--[[
    desc: 动画播放结束回调
]]
function RAMissionBriefingPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
        self.listenerActon:onAnimationDone(lastAnimationName)
        self.listenerActon = nil
    end
end

--[[
    desc: 简报页面结束
]]
function RAMissionBriefingPage:Exit(data)
    self.helper:Exit()
    self.helper = nil
    self.listenerActon = nil
    UIExtend.unLoadCCBFile(self)
end

return RAMissionBriefingPage