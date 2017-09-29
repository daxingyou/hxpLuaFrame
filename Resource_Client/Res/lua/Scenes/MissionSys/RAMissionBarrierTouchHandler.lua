-- RAMissionBarrierTouchHandler.lua
-- Author: xinghui
-- Using: 触摸层响应handler

local RAMissionBarrierManager       = RARequire("RAMissionBarrierManager")

local RAMissionBarrierTouchHandler  = {}

--[[
    desc: RAMissionBarrierPage的touchLayer的点击响应函数
]]
function RAMissionBarrierTouchHandler.onBarrierPageHandler(event, touch)
    if event == 'began' then
       return RAMissionBarrierTouchHandler:_onPageSingleTouchBegan(touch)
    elseif event == 'moved' then
    elseif event == 'ended' then
       RAMissionBarrierTouchHandler:_onPageSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

--[[
    desc: 点击开始
]]
function RAMissionBarrierTouchHandler:_onPageSingleTouchBegan(touch)
    return true
end

--[[
    desc: 点击结束
]]
function RAMissionBarrierTouchHandler:_onPageSingleTouchEnded(touch)
    RAMissionBarrierManager:gotoNextStep()
end

------------------------------------------华丽的分割线-----------------------------------------
--subccb事件处理
RAMissionBarrierTouchHandler.SubCCBHandlers = {}

RAMissionBarrierTouchHandler.SubCCBHandlers.RAGuideLabelBlueNode = {
    registerActionListener = function(self, action)
        self.listenerActon = action
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
            self.listenerActon:onAnimationDone(lastAnimationName)
            self.listenerActon = nil
        end
    end
}

RAMissionBarrierTouchHandler.SubCCBHandlers.RAGuideLabelBlueNode2 = {
    registerActionListener = function(self, action)
        self.listenerActon = action
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
            self.listenerActon:onAnimationDone(lastAnimationName)
            self.listenerActon = nil
        end
    end
}

RAMissionBarrierTouchHandler.SubCCBHandlers.RAGuideLabelRedNode = {
    registerActionListener = function(self, action)
        self.listenerActon = action
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
            self.listenerActon:onAnimationDone(lastAnimationName)
            self.listenerActon = nil
        end
    end
}

RAMissionBarrierTouchHandler.SubCCBHandlers.RAGuideBustNode = {
    registerActionListener = function(self, action)
        self.listenerActon = action
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
            self.listenerActon:onAnimationDone(lastAnimationName)
            self.listenerActon = nil
        end
    end
}

RAMissionBarrierTouchHandler.SubCCBHandlers.RAWarningAni = {
    registerActionListener = function(self, action)
        self.listenerActon = action
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
            self.listenerActon:onAnimationDone(lastAnimationName)
            self.listenerActon = nil
        end
    end
}

------------------------------------------华丽的分割线-----------------------------------------

RAMissionBarrierTouchHandler.armyCCBHandler = {
    listenerActon = nil
}                        --士兵ccb的点击事件处理

--[[
    desc: RAMissionBarrierScene的armyNode的消息响应
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:registerActionListener(action)
    self.listenerActon = action
end

--[[
    desc: armynode的动画播放完成回调
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
        self.listenerActon:onAnimationDone(lastAnimationName)
        self.listenerActon = nil
    end
end

--[[
    desc: 点击潜艇炸弹响应函数
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:mSubmarineBombBtn1_onClick()
    RAMissionBarrierManager:gotoNextStep();
end

--[[
    desc: 点击潜艇炸弹响应函数
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:mSubmarineBombBtn2_onClick()
    RAMissionBarrierManager:gotoNextStep();
end

--[[
    desc: 点击潜艇炸弹响应函数
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:mSubmarineBombBtn3_onClick()
    RAMissionBarrierManager:gotoNextStep();
end

--[[
    desc: 点击潜艇炸弹响应函数
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:mSubmarineBombBtn4_onClick()
    RAMissionBarrierManager:gotoNextStep();
end

--[[
    desc: 点击集结按钮
]]
function RAMissionBarrierTouchHandler.armyCCBHandler:onClick()
    RAMissionBarrierManager:gotoNextStep();
end

return RAMissionBarrierTouchHandler