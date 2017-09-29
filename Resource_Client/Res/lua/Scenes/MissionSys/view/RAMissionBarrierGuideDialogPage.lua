-- RAMissionBarrierGuideDialogPage.lua
-- Author: xinghui
-- Using: 关卡中第二种对话显示的页面

RARequire("BasePage")

local UIExtend                                  = RARequire("UIExtend")
local RAMissionBarrierTouchHandler              = RARequire("RAMissionBarrierTouchHandler")
local RAMissionVar                              = RARequire("RAMissionVar")

local RAMissionBarrierGuideDialogPage            = BaseFunctionPage:new(...)

RAMissionBarrierGuideDialogPage.touchLayer       = nil
RAMissionBarrierGuideDialogPage.listenerActon    = nil  

--[[
    desc: 页面的入口函数
]]
function RAMissionBarrierGuideDialogPage:Enter(data)
    UIExtend.loadCCBFile("RAGuidePage.ccbi", self)
    RAMissionVar:addCCBOwner("RAGuidePage.ccbi", self)
end

--[[
    desc: 注册需要监听的Action
]]
function RAMissionBarrierGuideDialogPage:registerActionListener(action)
    self.listenerActon = action
end

--[[
    desc: 动画播放结束回调
]]
function RAMissionBarrierGuideDialogPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
        self.listenerActon:onAnimationDone(lastAnimationName)
        self.listenerActon = nil
    end
end

--[[
    desc: 添加点击层
]]
function RAMissionBarrierGuideDialogPage:addTouchLayer()
    if self.touchLayer == nil then
        self.touchLayer = CCLayer:create()
        self.touchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())--设置touchlayer大小
        self:getRootNode():addChild(self.touchLayer, 1)
        self.touchLayer:setAnchorPoint(0, 0)
        self.touchLayer:setPosition(0, 0)
        self.touchLayer:setTouchMode(kCCTouchesOneByOne)
        self.touchLayer:setTouchEnabled(true)
        self.touchLayer:registerScriptTouchHandler(RAMissionBarrierTouchHandler.onBarrierPageHandler, false, GuideLayerPriority, true)--设置touchlayer的swallow
    end
end

--[[
    desc: 移除点击层
]]
function RAMissionBarrierGuideDialogPage:removeTouchLayer()
    if self.touchLayer then
        self.touchLayer:removeFromParentAndCleanup(true)
        self.touchLayer = nil
    end
end

--[[
    desc: 移除页面
]]
function RAMissionBarrierGuideDialogPage:Exit(data)
    self.listenerActon = nil
    self:removeTouchLayer()
    UIExtend.unLoadCCBFile(self)
    RAMissionVar:deleteCCBOwner("RAGuidePage.ccbi")
end



return RAMissionBarrierGuideDialogPage