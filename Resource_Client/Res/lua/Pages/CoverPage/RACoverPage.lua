RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAGuideConfig=RARequire("RAGuideConfig")
local RAGuideManager=RARequire("RAGuideManager")

local RACoverPage = BaseFunctionPage:new(...)

RACoverPage.touchLayer = nil
RACoverPage.totalTime = 0



--触摸层的点击事件
local touchLayerEventHandler = function(pEvent, pTouch)
    if pEvent == "began" then
        return true--吞噬点击事件
    elseif pEvent == "ended" then
    
        RACoverPage.touchClickCount=RACoverPage.touchClickCount+1
        
        CCLuaLog("RACoverPage.touchClickCount==="..RACoverPage.touchClickCount)
        --跳过所有新手  可以做成跳过某一步
        if RACoverPage.touchClickCount==RAGuideConfig.clickCoverPageCount then
            RAGuideManager.jumpAllGuide()
            RARootManager.RemoveCoverPage()
            RARequire("MessageDefine")
            RARequire("MessageManager")
            local guide_conf=RARequire("guide_conf")
            local constGuideInfo=guide_conf[RAGuideConfig.showAllMainUI]
            MessageManager.sendMessage(MessageDef_Guide.MSG_Guide, {guideInfo = constGuideInfo})
        end 
    end
end

function RACoverPage:Enter()
    UIExtend.loadCCBFile("RAGuidePage.ccbi", self)
    UIExtend.setNodeVisible(self.ccbfile, "mBGColor", false)
    self.touchClickCount=0
     --创建滑动layer
    if self.touchLayer == nil then
        self.touchLayer = CCLayer:create()
        self.touchLayer:registerScriptTouchHandler(touchLayerEventHandler, false, CoverLayerPriority, true)--设置touchlayer的swallow
        self.touchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())--设置touchlayer大小
        self:getRootNode():addChild(self.touchLayer, 1)
        self.touchLayer:setAnchorPoint(0, 0)
        self.touchLayer:setPosition(0, 0)
        self.touchLayer:setTouchMode(kCCTouchesOneByOne)
        self.touchLayer:setTouchEnabled(true)
    end
end

function RACoverPage:Execute()
    local dt = GamePrecedure:getInstance():getFrameTime()
    self.totalTime = self.totalTime + dt
    if self.totalTime >= 2 then
        self.totalTime = 0
        RARootManager.RemoveCoverPage()
    end
end


function RACoverPage:Exit()
    if self.touchLayer then
        self.touchLayer:removeFromParentAndCleanup(true)
        self.touchLayer = nil
    end
    self.totalTime = 0
    self.touchClickCount=0

    UIExtend.unLoadCCBFile(self)
end
