-- RANoTouchLayer
-- 屏蔽点击层
-- 用于新手、刚登陆等等
-- 提供机制：
-- 1、点击回调
-- 2、如果提供参数，可以点击特定区域穿透

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local common = RARequire('common')

local RANoTouchLayer = BaseFunctionPage:new(...)


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RANoTouchLayer:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RANoTouchLayer:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end
end

function RANoTouchLayer:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    -- MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RANoTouchLayer:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    -- MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RANoTouchLayer:resetData()

end

function RANoTouchLayer:Enter(data)
    CCLuaLog("RANoTouchLayer:Enter")    
    UIExtend.loadCCBFile("Empty.ccbi", self)

    self.mTouchLayer = CCLayer:create()
    self.mTouchLayer:registerScriptTouchHandler(touchLayerEventHandler, false, NoTouchLayerPriority_All, true)--设置touchlayer的swallow
    self.mTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())--设置touchlayer大小
    self:getRootNode():addChild(self.mTouchLayer, 1)
    self.mTouchLayer:setAnchorPoint(0, 0)
    self.mTouchLayer:setPosition(0, 0)
    self.mTouchLayer:setTouchMode(kCCTouchesOneByOne)
    self.mTouchLayer:setTouchEnabled(true)
end


function RANoTouchLayer:Execute()
    
end


function RANoTouchLayer:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RANoTouchLayer:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RANoTouchLayer:Exit")    
    if self.mTouchLayer ~= nil then    
        RA_SAFE_REMOVEFROMPARENT(self.mTouchLayer)
    end
    self:unregisterMessageHandlers()    
    UIExtend.unLoadCCBFile(self)    
end