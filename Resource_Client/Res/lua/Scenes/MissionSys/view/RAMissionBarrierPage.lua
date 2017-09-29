-- RAMissionBarierPage.lua
-- Author: xinghui
-- Using: 关卡中配套显示的页面

RARequire("BasePage")
local UIExtend                      = RARequire("UIExtend")
local RAMissionBarrierTouchHandler  = RARequire("RAMissionBarrierTouchHandler")
local RAMissionVar                  = RARequire("RAMissionVar")

local RAMissionBarierPage           = BaseFunctionPage:new(...)

RAMissionBarierPage.touchLayer      = nil
RAMissionBarierPage.listenerActon   = nil                             --页面需要监听的action


--[[
    desc: 页面的入口函数
]]
function RAMissionBarierPage:Enter(data)
    UIExtend.loadCCBFile("RAMissionMap_Ani_Dialog.ccbi", self)
    RAMissionVar:addCCBOwner("RAMissionMap_Ani_Dialog.ccbi", self)

end


--[[
    desc: 注册需要监听的Action
]]
function RAMissionBarierPage:registerActionListener(action)
    self.listenerActon = action
end

--[[
    desc: 动画播放结束回调
]]
function RAMissionBarierPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if self.listenerActon and lastAnimationName == self.listenerActon.constActionInfo.param then
        self.listenerActon:onAnimationDone(lastAnimationName)
        self.listenerActon = nil
    end
end


--[[
    desc: 添加点击层
]]
function RAMissionBarierPage:addTouchLayer()
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
function RAMissionBarierPage:removeTouchLayer()
    if self.touchLayer then
        self.touchLayer:removeFromParentAndCleanup(true)
        self.touchLayer = nil
    end
end

--[[
    desc: 移除页面
]]
function RAMissionBarierPage:Exit(data)
    self.listenerActon = nil
    self:removeTouchLayer()
    UIExtend.unLoadCCBFile(self)
    RAMissionVar:deleteCCBOwner("RAMissionMap_Ani_Dialog.ccbi")
end


return RAMissionBarierPage