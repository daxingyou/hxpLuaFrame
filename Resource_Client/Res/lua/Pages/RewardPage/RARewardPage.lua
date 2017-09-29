RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")


local RARewardPage = BaseFunctionPage:new(...)

function RARewardPage:Enter(data)
    UIExtend.loadCCBFile("RACommonPopUp2.ccbi", self)
    -- 如果初始化没有pos参数，那么会放到屏幕中间
    if data.pos == nil then
        local visibleSize = CCDirector:sharedDirector():getVisibleSize()
        self.ccbfile:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
    else
        self.ccbfile:setPosition(data.pos)
    end
    RARewardPage:refreshUI(data.icon,data.title, data.text)
    self.ccbfile:runAnimation("InAni")
end

function RARewardPage:refreshUI(icon, title, text)
    if icon then
        UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode", icon)
    end
    title = title or '@Reward'
    UIExtend.setCCLabelString(self.ccbfile, "mPopUpTitle", _RALang(title))

    local htmlLabel = self.ccbfile:getCCLabelHTMLFromCCB("mGetResHTMLLabel")
    htmlLabel:setPreferredSize(400,400)
    htmlLabel:setString(text)
end

function RARewardPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == "InAni" then 
        self.ccbfile:removeFromParentAndCleanup(true)
        UIExtend.unLoadCCBFile(self.ccbfile)
        self.ccbfile = nil        
        --新手期，奖励动画播放完成后，进入下一步
        local RAGuideManager = RARequire("RAGuideManager")
        if RAGuideManager.isInGuide() then
            RAGuideManager.gotoNextStep()
        end
    end
end


function RARewardPage:Exit(data)
    UIExtend.unLoadCCBFile(self)
end