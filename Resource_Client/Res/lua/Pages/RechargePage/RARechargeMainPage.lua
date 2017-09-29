-------------------------------
--page:支付主页面
-------------------------------

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARealPayManager = RARequire("RARealPayManager")
local RAStringUtil = RARequire("RAStringUtil")
local pay_add_conf = RARequire("pay_add_conf")
local Utilitys = RARequire("Utilitys")
local RAResManager = RARequire("RAResManager")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGameConfig = RARequire("RAGameConfig")


local RARechargeMainPage = BaseFunctionPage:new(...)
local this = RARechargeMainPage

local TWO_CIRCLE_LENGTH = 30
RARechargeMainPage.giftScrollView = nil--礼包scrollview
RARechargeMainPage.goodsScrollView = nil--普通充值scrollview
RARechargeMainPage.netHandler = {}
RARechargeMainPage.circles = {}--礼包标示圆圈
RARechargeMainPage.rewardBoxCCB = nil--累计登陆箱子ccb
RARechargeMainPage.circleFG = nil
RARechargeMainPage.isShowing = false

--------------------------------------------------------------------
--desc:礼包cell监听
local RAGiftItemCellListener = {
    itemInfo = nil,
    timeLabel = nil,
    titleLabel = nil
}
function RAGiftItemCellListener:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self
    return o
end

function RAGiftItemCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    self.timeLabel = UIExtend.getCCLabelTTFFromCCB(ccbfile, "mTime")
    self.titleLabel = UIExtend.getCCLabelTTFFromCCB(ccbfile, "mTitle")
    if ccbfile and self.itemInfo then
        if self.titleLabel and self.itemInfo.name then
            self.titleLabel:setString(_RALang(self.itemInfo.name))
        end
        
        if self.itemInfo.show then
            UIExtend.setSpriteIcoToNode(ccbfile, "mTopIcon", self.itemInfo.show)
        end

        local updateFun = function ()
            local remainTime = Utilitys.getCurDiffTime(self.itemInfo.endTime / 1000)

            if remainTime < 0 then --时间倒计时为0就隐藏进度条
                remainTime = 0
                ccbfile:stopAllActions()
            end 

            local tmpStr = Utilitys.createTimeWithFormat(remainTime)
            if self.timeLabel then
                self.timeLabel:setString(tmpStr)
            end 
        end


        if self.itemInfo.endTime > 0 then
            UIExtend.setNodeVisible(ccbfile, "mTime", true)
            schedule(ccbfile, updateFun, 1)
            updateFun()
            --设置title位置
            if self.titleLabel then
                local pos = ccp(-30, 0)
                self.titleLabel:setPosition(pos)
                pos:delete()
            end
        else
            UIExtend.setNodeVisible(ccbfile, "mTime", false)
            --设置title位置
            if self.titleLabel then
                local pos = ccp(0, 0)
                self.titleLabel:setPosition(pos)
                pos:delete()
            end
        end

        if self.itemInfo.percent > 0 then
            UIExtend.setNodeVisible(ccbfile, "mSaleNode", true)
            local percentStr = RAStringUtil:getLanguageString("@Percent", self.itemInfo.percent)
            UIExtend.setCCLabelBMFontString(ccbfile, "mDiamondsPercent", percentStr)
        else
            UIExtend.setNodeVisible(ccbfile, "mSaleNode", false)
        end

        if self.itemInfo.gold > 0 then
            UIExtend.setCCLabelBMFontString(ccbfile, "mDiamondsNum", tostring(self.itemInfo.gold))
        end

        local platformProductInfo = RARealPayManager.getPlatfromProductionByProductId(self.itemInfo.saleId)
        if platformProductInfo then
            UIExtend.setControlButtonTitle(ccbfile, "mBuyBtn", platformProductInfo.formatterPrice)
        else
            local realPrice = tonumber(self.itemInfo.payPrice) / 100
            local price = RAStringUtil:getLanguageString("@PayPrice", realPrice)
            UIExtend.setControlButtonTitle(ccbfile, "mBuyBtn", price)
        end

        if self.itemInfo.awardItems then
            for i=1,3 do
                local item = self.itemInfo.awardItems[i]
                local icon, name = RAResManager:getIconByTypeAndId(item.itemType, item.itemId)
                UIExtend.addSpriteToNodeParent(ccbfile, "mCarouselIconNode"..i, icon)
                local countStr = _RALang("@Count", item.itemCount)
                UIExtend.setCCLabelString(ccbfile, "mCarouselCount"..i, countStr)
            end
        end

        UIExtend.setCCLabelString(ccbfile, "mMore", _RALang("@More"))
    end
end

--desc:发送打点数据
function RAGiftItemCellListener:sendNoticeToServer()
    local msg = SysProtocol_pb.HPClickNoticePB()
    msg.clickType = SysProtocol_pb.GIFT_CLICK
    if self.itemInfo then
        msg.eventId = tonumber(self.itemInfo.goodsId)
    end

    RANetUtil:sendPacket(HP_pb.CLICK_NOTICE_C, msg)
end

function RAGiftItemCellListener:onMoreBtn()
    self:sendNoticeToServer()    
    RARootManager.OpenPage("RARechargeGiftPage", {data = self.itemInfo} ,false)
end

function RAGiftItemCellListener:onBuyBtn()
    if RAGameConfig.SwitchPay and RAGameConfig.SwitchPay == 1 then
        local msg = Recharge_pb.RechargeRequest()
        msg.goodsId = self.itemInfo.goodsId
        RARealPayManager.goodsId = self.itemInfo.goodsId
        RARealPayManager.comFromPop = false
        RANetUtil:sendPacket(HP_pb.RECHARGE_C, msg)

        if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
            RARootManager.ShowWaitingPage(true)
        end
    end
    
end
--------------------------------------------------------------------
--desc：普通充值cell监听
local RAGoodItemCellListener = {
    itemInfo = nil
}

function RAGoodItemCellListener:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self
    return o
end

function RAGoodItemCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()

    if ccbfile and self.itemInfo then
        if self.itemInfo.hot and self.itemInfo.hot > 0 then
            UIExtend.setNodeVisible(ccbfile, "mHotNode", true)
        else
            UIExtend.setNodeVisible(ccbfile, "mHotNode", false)
        end

        if self.itemInfo.show then
            UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", self.itemInfo.show)
        end

        if self.itemInfo.gold > 0 then
            UIExtend.setCCLabelString(ccbfile, "mCellNum", tostring(self.itemInfo.gold))
        end

        if self.itemInfo.payLimit and self.itemInfo.payLimit > 0 then
            if self.itemInfo.payLimit == 1 then
                UIExtend.setNodeVisible(ccbfile, "mRestrictionLabel", true)
                UIExtend.setNodeVisible(ccbfile, "mRestrictionDailyLabel", false)
                UIExtend.setCCLabelString(ccbfile, "mRestrictionLabel", _RALang("@LimitBuyEver"))
            elseif self.itemInfo.payLimit == 2 then
                UIExtend.setNodeVisible(ccbfile, "mRestrictionLabel", false)
                UIExtend.setNodeVisible(ccbfile, "mRestrictionDailyLabel", true)
                UIExtend.setCCLabelString(ccbfile, "mRestrictionDailyLabel", _RALang("@LimitBuyDaily"))
            end
        else
            UIExtend.setNodeVisible(ccbfile, "mRestrictionLabel", false)
            UIExtend.setNodeVisible(ccbfile, "mRestrictionDailyLabel", false)
        end

        local addDiamond = 0
        if self.itemInfo.awardItems then
            for i=1, #self.itemInfo.awardItems do
                local item = self.itemInfo.awardItems[i]
                if (item.itemType / 10000) == Const_pb.PLAYER_ATTR and item.itemId == Const_pb.GOLD then
                    addDiamond = addDiamond + item.itemCount
                end
            end
        end
        if addDiamond > 0 then
            UIExtend.setNodeVisible(ccbfile, "mAdditionalLabel", true)
            local addStr = RAStringUtil:getLanguageString("@PayAdd", addDiamond)
            UIExtend.setCCLabelString(ccbfile, "mAdditionalLabel", addStr)
        else
            UIExtend.setNodeVisible(ccbfile, "mAdditionalLabel", false)
        end

        local platformProductInfo = RARealPayManager.getPlatfromProductionByProductId(self.itemInfo.saleId)
        if platformProductInfo then
            UIExtend.setControlButtonTitle(ccbfile, "mBuyBtn", platformProductInfo.formatterPrice)
        else
            local realPrice = tonumber(self.itemInfo.payPrice) / 100
            local price = RAStringUtil:getLanguageString("@PayPrice", realPrice)
            UIExtend.setControlButtonTitle(ccbfile, "mBuyBtn", price)
        end
    end
end

function RAGoodItemCellListener:onBuyBtn()
    if RAGameConfig.SwitchPay and RAGameConfig.SwitchPay == 1 then
        local msg = Recharge_pb.RechargeRequest()
        msg.goodsId = self.itemInfo.goodsId
        RARealPayManager.goodsId = self.itemInfo.goodsId
        RARealPayManager.comFromPop = false
        RANetUtil:sendPacket(HP_pb.RECHARGE_C, msg)

        if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
            RARootManager.ShowWaitingPage(true)
        end
    end
end

--------------------------------------------------------------------
--消息处理
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Pay.MSG_PayInfoRefresh then
        if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
            RARootManager.RemoveWaitingPage()
        end
        this:_refreshLevelGiftUI()
        this:_refreshGiftUI()
        this:_refreshCommonUI()
        return
    end

    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        this:_refreshGold()
        return
    end
end


function RARechargeMainPage:Enter(data)
    UIExtend.loadCCBFile("RAStoreMainPage.ccbi", self)   
    self.isShowing = true
    local svNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mCarouselNode")
    local size = CCSizeMake(0, 0)
    if svNode then
        size = svNode:getContentSize()
    end
    self.giftScrollView = CCSelectedScrollView:create(size)
    self.giftScrollView:setDirection(kCCScrollViewDirectionHorizontal)
    UIExtend.addNodeToParentNode(self.ccbfile, "mCarouselNode", self.giftScrollView)


    self.goodsScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mStoreListSV")

    self:_refreshLevelGiftUI()
    self:_refreshGiftUI()
    self:_refreshCommonUI()
    self:_addHandler()
end

function RARechargeMainPage:_refreshGold()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
    if titleCCB then
        UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@Pay"))
        UIExtend.setCCLabelString(titleCCB, "mDiamondsNum", RAPlayerInfoManager.getPlayerBasicInfo().gold)
    end

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.ClosePage("RARechargeMainPage")
	end
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RARechargeMainPage', 
    titleCCB, _RALang("@Pay"), backCallBack, RACommonTitleHelper.BgType.Blue)
end

--desc:刷新等级礼包显示
function RARechargeMainPage:_refreshLevelGiftUI()
    self:_refreshGold()

    local isMaxLevel = false
    local nextLevel = RARealPayManager.nowLevel
    local addGold = RARealPayManager.addGold    
    if nextLevel > #pay_add_conf then--下一等级礼包不能超过最大等级
        nextLevel = #pay_add_conf
        isMaxLevel = true
    end

    local maxGoldNextLevel = pay_add_conf[nextLevel].addGold
    local currLevelGold = RARealPayManager.addGold


    local goldBarStr = RAStringUtil:getLanguageString("@PayLevelGoldPercent", currLevelGold, maxGoldNextLevel)
    UIExtend.setCCLabelString(self.ccbfile, "mBarNum", goldBarStr)

    local percent = currLevelGold / maxGoldNextLevel
    if percent > 1 then
        percent = 1
    end
    local bar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
    local barGreen = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBarGreen")
    if percent < 1 then
        bar:setScaleX(percent)
        bar:setVisible(true)
        barGreen:setVisible(false)
    else
        barGreen:setScaleX(percent)
        barGreen:setVisible(true)
        bar:setVisible(false)
    end

    if self.rewardBoxCCB == nil then
        self.rewardBoxCCB = UIExtend.loadCCBFile("RAStoreMainGiftBox.ccbi", {})
        UIExtend.addNodeToParentNode(self.ccbfile, "mGiftNode", self.rewardBoxCCB)
    end

    UIExtend.setSpriteImage(self.rewardBoxCCB, {mBoxPic = pay_add_conf[nextLevel].show})
    UIExtend.setCCLabelString(self.rewardBoxCCB, "mLevel", _RALang("@ResCollectTargetLevel",pay_add_conf[nextLevel].level))

    if isMaxLevel then
        UIExtend.setMenuItemEnable(self.ccbfile,"mReceiveItem",false)
        self.rewardBoxCCB:runAnimation("CloseAni")
        self.ccbfile:runAnimation("Normal")        
    else
        if currLevelGold >= maxGoldNextLevel then
            --可以领取奖励
            --todo:播放宝箱动画
            self.rewardBoxCCB:runAnimation("OpenAni")
            self.ccbfile:runAnimation("Activated")
        else    
            --还不可领取奖励
            self.rewardBoxCCB:runAnimation("CloseAni")
            self.ccbfile:runAnimation("Normal")
        end
    end
    

end

--desc:接收数据
function RARechargeMainPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
end

--desc:添加各种监听
function RARechargeMainPage:_addHandler()
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    if self.giftScrollView then
        self.giftScrollView:registerFunctionHandler(self)
    end

end

--desc:移除各种监听
function RARechargeMainPage:_removeHandler()
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)

--取消packet监听
    for k, value in pairs(self.netHandler) do
        if self.netHandler[k] ~= nil then
             RANetUtil:removeListener(self.netHandler[k])
             self.netHandler[k] = nil
        end
    end
    self.netHandler = {}

    if self.giftScrollView then
        self.giftScrollView:unregisterFunctionHandler()
    end

end

--desc:刷新礼包显示
function RARechargeMainPage:_refreshGiftUI()
    if self.giftScrollView then
        self.giftScrollView:removeAllCell()
    end
    for key, circle in pairs(self.circles) do
        circle:removeFromParentAndCleanup(true)
    end
    self.circles = {}
    if self.circleFG then
        self.circleFG:removeFromParentAndCleanup(true)
        self.circleFG = nil
    end

    local giftItemInfos = RARealPayManager.getGiftItems()
    local selectCell = nil
    if giftItemInfos then
        local giftItemCount = (#giftItemInfos)
        local centerNode = UIExtend.getCCNodeFromCCB(self.ccbfile ,"mPageNumNode")
        --获得圆圈的其实位置
        local startPos = ccp(0, 0)
        if giftItemCount%2 == 0 then
            local oneSideNum = giftItemCount / 2
            startPos.x = startPos.x - (oneSideNum-0.5)*TWO_CIRCLE_LENGTH
        else
            local oneSideNum = (giftItemCount-1) / 2
            startPos.x = startPos.x - (oneSideNum * TWO_CIRCLE_LENGTH)
        end

        for key, giftItemInfo in ipairs(giftItemInfos) do
            local cellListener = RAGiftItemCellListener:new({itemInfo = giftItemInfo})
            local cell = CCBFileCell:create()
            --选择 ccbi
            local detailIndex = 1
            if giftItemInfo.showDetail ~= nil then
                detailIndex = string.sub(giftItemInfo.showDetail, string.len("libao")+1, string.len(giftItemInfo.showDetail))
            end
            local ccbName = "RAStoreCarouselNode"..detailIndex..".ccbi"
            cell:setCCBFile(ccbName)
            cell:registerFunctionHandler(cellListener)
            cell:setCellTag(key)
            if key == 1 then
                selectCell = cell--设置初始化要选择的cell
            end
            self.giftScrollView:addCellBack(cell)

            local circleBG = CCSprite:create(RAGameConfig.CirlclePic.CIRCLE_BG)
            if circleBG and centerNode then
                centerNode:addChild(circleBG)
                local pos = ccpAdd(startPos, ccp((key - 1)*TWO_CIRCLE_LENGTH, 0))
                circleBG:setPosition(pos)
                self.circles[key] = circleBG
            end
        end

        if self.circleFG == nil then
            self.circleFG = CCSprite:create(RAGameConfig.CirlclePic.CIRCLE_FG)
            if centerNode and self.circleFG then
                centerNode:addChild(self.circleFG)
            end
        end
        self.circleFG:setPosition(startPos)

        if selectCell then
            self.giftScrollView:setSelectedCell(selectCell)--设置select的cell
        end
        self.giftScrollView:orderCCBFileCells()

    end
end

--desc:刷新普通重置显示
function RARechargeMainPage:_refreshCommonUI()
    if self.goodsScrollView then
        self.goodsScrollView:removeAllCell()
    end

    local goodsItemInfos = RARealPayManager.getGoodsItems()
    if goodsItemInfos then
        for key, goodItemInfo in ipairs(goodsItemInfos) do
            local cellListener = RAGoodItemCellListener:new({itemInfo = goodItemInfo})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAStoreMainCell.ccbi")
            cell:registerFunctionHandler(cellListener)
            self.goodsScrollView:addCellBack(cell)
        end
        self.goodsScrollView:orderCCBFileCells()
    end
end

--desc:点击累计充值奖励
function RARechargeMainPage:onLevelReward()
    RARootManager.OpenPage("RARechargeCumulativePopupPage")
end

--desc:点击累计充值按钮
function RARechargeMainPage:onReceive()
    RARootManager.OpenPage("RARechargeCumulativePopupPage")
end

--function RARechargeMainPage:mAllianceCommonCCB_onBack()
--    RARootManager.ClosePage("RARechargeMainPage")
--end

function RARechargeMainPage:scrollViewSelectNewItem(cell)
    if cell then
        self.giftScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        local tag = cell:getCellTag()
        local circleBG = self.circles[tag]
        if circleBG then
            local pos = ccp(0, 0)
            pos.x, pos.y = circleBG:getPosition()
            self.circleFG:setPosition(pos)
        end
    end
end

function RARechargeMainPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        self.giftScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RARechargeMainPage:scrollViewRollBack(cell)
    if cell then
        self.giftScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RARechargeMainPage:scrollViewPreItem(preCell)

end

function RARechargeMainPage:scrollViewChangeItem(cell)

end

function RARechargeMainPage:Exit(data)  
    self:_removeHandler()
    self.isShowing = false
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RARechargeMainPage")

    if self.rewardBoxCCB then
        self.rewardBoxCCB:removeFromParentAndCleanup(true)
        self.rewardBoxCCB = nil
    end
    for key, circle in pairs(self.circles) do
        circle:removeFromParentAndCleanup(true)
    end
    self.circles = {}
    
    if self.circleFG then
        self.circleFG:removeFromParentAndCleanup(true)
        self.circleFG = nil
    end

    if self.giftScrollView then
        self.giftScrollView:removeAllCell()
        self.giftScrollView:removeFromParentAndCleanup(true)
        self.giftScrollView = nil
    end
    if self.goodsScrollView then
        self.goodsScrollView:removeAllCell()
        self.goodsScrollView = nil
    end
    UIExtend.unLoadCCBFile(self)
end


return RARechargeMainPage