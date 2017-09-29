-------------------------------
--page:ÀÛ¼Æ³äÖµ½±ÀøÒ³Ãæ
-------------------------------
RARequire("BasePage")
RARequire('RABuildingUtility')
local UIExtend = RARequire("UIExtend")
local pay_add_conf = RARequire("pay_add_conf")
local RARealPayManager = RARequire("RARealPayManager")
local RAResManager = RARequire("RAResManager")
local RANetUtil = RARequire("RANetUtil")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local RAGameConfig = RARequire("RAGameConfig")
local RALogicUtil = RARequire('RALogicUtil')
local RABuildManager = RARequire('RABuildManager')


local RARechargeCumulativePopupPage = BaseFunctionPage:new(...)
RARechargeCumulativePopupPage.scrollView = nil

local cellWidth = 350
local cellHeight = 143
---------------------------------------------------------

local RACumulativeRewardTitleCellListener = {
}

function RACumulativeRewardTitleCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACumulativeRewardTitleCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, "mCellTitle", _RALang("@ChargeReward", self.level))
    end
end


local RACumulativePayCellListener = {
}

function RACumulativePayCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACumulativePayCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, "mBoxNodeTitle", _RALang(self.payInfo.name))
        local isEnough = RARealPayManager.addGold >= self.payInfo.addGold
        local hasRecv = false
        for i,v in ipairs(RARealPayManager.hasRecvArr) do
            if tonumber(v) == self.payInfo.level then
                hasRecv = true
                break
            end
        end
        UIExtend.setNodeVisible(ccbfile, "mConditionNode", not hasRecv and not isEnough) 
        UIExtend.setNodeVisible(ccbfile, "mCanReceiveNode", not hasRecv and isEnough) 
        UIExtend.setNodeVisible(ccbfile, "mReceivedNode", hasRecv) 
        UIExtend.setSpriteImage(ccbfile, {mBoxIcon = self.payInfo.show})
        UIExtend.setCCLabelString(ccbfile, "mReceivedLabel", _RALang("@HasRecv"))
        UIExtend.setControlButtonTitle(ccbfile, "mCanReceiveBtn", _RALang("@CanReceive"))
        UIExtend.setCCLabelHTMLString(ccbfile, "mConditionLabel", _RALang("@RechargeGold", self.payInfo.addGold))
    end
end

function RACumulativePayCellListener:onCanReceiveBtn(ccbRoot)
    if self.payInfo then
        if RARealPayManager.addGold >= self.payInfo.addGold then
            local msg = Recharge_pb.RecievePayAddAwardReq()
            msg.payAddLevel = self.payInfo.level
            RANetUtil:sendPacket(HP_pb.RECHARGE_REWARD_C, msg)
        end
    end
end


local RACumulativeRewardCellListener = {
    cellRewardItem = nil
}

function RACumulativeRewardCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACumulativeRewardCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        local startBtn = UIExtend.getCCControlButtonFromCCB(ccbfile, "mStartBtn")
        local mCellNum = UIExtend.getCCLabelTTFFromCCB(ccbfile, "mCellNum")
        if self.cellRewardItem then
            local icon, name, item_color = RAResManager:getIconByTypeAndId(self.cellRewardItem.type, self.cellRewardItem.id)
            local bgName  = RALogicUtil:getItemBgByColor(item_color)
            UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode" ,bgName, nil, nil, 9997)
            UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", icon, nil, nil, 9998)
    		UIExtend.setCCLabelString(ccbfile,"mCellName",_RALang(name))
            local rewardStr = RAStringUtil:getLanguageString("@RewardAccount", self.cellRewardItem.count)
            UIExtend.setCCLabelString(ccbfile, "mCellNum", rewardStr)
            mCellNum:setVisible(true)
            startBtn:setVisible(false)
        elseif self.special then
            self.actionType = 0
            local buildInfo = RABuildingUtility:getBuildInfoByLevel(Const_pb.EINSTEIN_LODGE, 1)
            local bgName  = RALogicUtil:getItemBgByColor(1)
            UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode" ,bgName, nil, nil, 9997)            
            UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", buildInfo.buildArtImg, nil, nil, 9998)
            if self.special == 1 then
                UIExtend.setCCLabelString(ccbfile,"mCellName",_RALang("@RechargeSpecial", self.special, _RALang(buildInfo.buildName)))
            else
                UIExtend.setCCLabelString(ccbfile,"mCellName",_RALang("@UpdateSpecial", self.special, _RALang(buildInfo.buildName)))
            end
            local buildInfo = RABuildManager:getBuildDataArray(Const_pb.EINSTEIN_LODGE)
            local payInfo = self.payInfo
            if buildInfo and buildInfo[1] then
                if buildInfo[1].status == Const_pb.DAMAGED then
                    mCellNum:setVisible(false)
                    startBtn:setVisible(false)
                elseif buildInfo[1].status == Const_pb.READY_TO_CREATE then
                    if payInfo.addGold < RARealPayManager.addGold then
                        mCellNum:setVisible(false)
                        startBtn:setVisible(true)
                        UIExtend.setControlButtonTitle(ccbfile, "mStartBtn", _RALang("@ClickActivation"))
                        self.actionType = 1
                    else
                        mCellNum:setVisible(false)
                        startBtn:setVisible(false)
                    end

                else
                    if buildInfo[1].confData.level == 2 then

                        mCellNum:setVisible(true)
                        startBtn:setVisible(false)
                        mCellNum:setString(_RALang(self.special == 1 and "@Started" or "@Upgraded" ))
                    else
                        if self.special == 1 then

                            mCellNum:setVisible(true)
                            startBtn:setVisible(false)
                            mCellNum:setString(_RALang(self.special == 1 and "@Started" or "@Upgraded" ))
                        else
                            if payInfo.addGold < RARealPayManager.addGold then
                                mCellNum:setVisible(false)
                                startBtn:setVisible(true)
                                UIExtend.setControlButtonTitle(ccbfile, "mStartBtn", _RALang("@Update"))
                                self.actionType = 2
                            else
                                mCellNum:setVisible(false)
                                startBtn:setVisible(false)
                            end
                        end
                    end

                end
            end
        end
    end
end


function RACumulativeRewardCellListener:onStartBtn(ccbRoot)
    local buildInfo = RABuildManager:getBuildDataArray(Const_pb.EINSTEIN_LODGE)
    if buildInfo then
        local buildData = buildInfo[1]
        if self.actionType == 1 then
            RABuildManager:sendCreateBuildCmd(buildData.confData.id,buildData.tilePos.x,buildData.tilePos.y)
            RARootManager.CloseAllPages()
        elseif self.actionType == 2 then
            local RAGameHelperManager = RARequire('RAGameHelperManager')
            RAGameHelperManager:gotoHud( Const_pb.EINSTEIN_LODGE, BUILDING_BTN_TYPE.UPGRADE, true)
            RARootManager.CloseAllPages()
        end
    end
end

----------------------------------------------------------

local OnReceiveMessage = function (message)
 CCLuaLog("RAGameHelperPage OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_Pay.MSG_PayInfoRefresh then
        RARechargeCumulativePopupPage:refreshData()
    end
end

function RARechargeCumulativePopupPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RARechargeCumulativePopupPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RARechargeCumulativePopupPage:Enter()
    self:registerMessageHandlers()
    UIExtend.loadCCBFile("RAStoreAccumulativePage.ccbi", self)
    self:refreshTitle()

    UIExtend.setCCLabelString(self.ccbfile, "mExplainLabel", _RALang("@RechargeDesc"))
    self.detailsSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mDetailsListSV")
    self.mCellSVNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mCellBoxNode")

    self.scrollView = self.mCellSVNode:getChildByTag(998)

    local size = CCSizeMake(0, 0)
    if self.mCellSVNode then
        size = self.mCellSVNode:getContentSize()
    end

    if self.scrollView == nil then
        self.scrollView = CCSelectedScrollView:create(size)
        self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
        UIExtend.addNodeToParentNode(self.ccbfile, "mCellBoxNode", self.scrollView)
    end
    local nowLevel = RARealPayManager.nowLevel
    if nowLevel > #pay_add_conf then--ÏÂÒ»µÈ¼¶²»ÄÜ´óÓÚ×î´óµÈ¼¶
        nowLevel = #pay_add_conf
    end

    self.scrollView:removeAllCell()
    local frontWidth = (size.width - cellWidth) / 2
    for i = 1,#pay_add_conf + 2 do
        local payInfo = pay_add_conf[i - 1]
        local payInfoCell = RACumulativePayCellListener:new({payInfo = payInfo})
        local cell = CCBFileCell:create()
        
        if payInfo == nil then
            cell:setContentSize(CCSizeMake(frontWidth,cellHeight))
        else    
            cell:setCCBFile("RAStoreAccumulativeBoxNode.ccbi")
        end
        cell:registerFunctionHandler(payInfoCell)
        cell:setCellTag(i - 1)
        self.scrollView:addCellBack(cell)     
    end
    self.scrollView:registerFunctionHandler(self)
    self.scrollView:orderCCBFileCells()
    self.scrollView:moveCellByDirection(nowLevel)

    self.nowLevel = nowLevel

    self:refreshUI()

end

function RARechargeCumulativePopupPage:refreshData(  )
    self.scrollView:refreshAllCell()
end

function RARechargeCumulativePopupPage:refreshTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")    
    if titleCCB then
        UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@PayAddReward"))
    end

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.ClosePage("RARechargeCumulativePopupPage") 
    end
    local diamondCallBack = function()
        RARootManager.ClosePage("RARechargeCumulativePopupPage") 
    end

    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RARechargeCumulativePopupPage', 
    titleCCB,  _RALang("@PayAddReward"), backCallBack, RACommonTitleHelper.BgType.Blue)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, diamondCallBack)    
end

function RARechargeCumulativePopupPage:refreshUI(  )

    local nowLevel = self.nowLevel
    local constAddInfo = pay_add_conf[nowLevel]
    self.constAddInfo = constAddInfo
    if constAddInfo then
        local rewardItems = RAStringUtil:parseWithComma(constAddInfo.awardItems)
        UIExtend.setCCLabelHTMLString(self.ccbfile, "mCumulativeRechargeNum", _RALang("@TotalRechargeGold",RARealPayManager.addGold, constAddInfo.addGold))
        self.detailsSV:removeAllCell()

        local cellTitleListener = RACumulativeRewardTitleCellListener:new({level = nowLevel})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAStoreAccumulativeCellTitle.ccbi")
        cell:registerFunctionHandler(cellTitleListener)
        self.detailsSV:addCellBack(cell)        

        for key, rewardItem in ipairs(rewardItems) do
            local cellListener = RACumulativeRewardCellListener:new({cellRewardItem = rewardItem})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAStoreAccumulativeCell.ccbi")
            cell:registerFunctionHandler(cellListener)
            self.detailsSV:addCellBack(cell)
        end
        if constAddInfo.level < 3 then
            local cellListener = RACumulativeRewardCellListener:new({special = constAddInfo.level, payInfo = constAddInfo})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAStoreAccumulativeCell.ccbi")
            cell:registerFunctionHandler(cellListener)
            self.detailsSV:addCellBack(cell)
        end
        self.detailsSV:orderCCBFileCells()
        local bar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
        local nowGold = RARealPayManager.addGold
        local needGold = constAddInfo.addGold
        local dValue = nowGold - needGold
        local percent = 0
        if dValue > 0 then
            percent = 50
            local nextPayInfo = pay_add_conf[nowLevel + 1]
            if nextPayInfo then
                percent = percent + dValue / (nextPayInfo.addGold - needGold) * 50
                if percent > 100 then
                    percent = 100
                end
            else
                percent = 100
            end
        else
            percent = 50 + dValue/needGold * 50
        end
        bar:setScaleX(percent/100)
        --     self.ccbfile:runAnimation("Activated")
        --     UIExtend.setControlButtonTitle(self.ccbfile, "mBuyBtn", _RALang("@PayLevelReward"))
        -- else
        --     self.ccbfile:runAnimation("Normal")
        --     UIExtend.setControlButtonTitle(self.ccbfile, "mBuyBtn", _RALang("@Confirm"))
        -- end
        
    end
end

function RARechargeCumulativePopupPage:scrollViewSelectNewItem(cell)
    if cell then
        local cellTag = cell:getCellTag()
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            if cellTag == 0 or cellTag == #pay_add_conf + 1 then
                self.scrollView:setSelectedCell(preCell, CCBFileCell.LT_Mid, 0.0, 0.2)        
                return 
            end
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        self.nowLevel = cellTag
        self:refreshUI()
    end
end

function RARechargeCumulativePopupPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --todo播放放大动画
    end
end

function RARechargeCumulativePopupPage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RARechargeCumulativePopupPage:scrollViewPreItem(cell)
    print("RARechargeCumulativePopupPage:scrollViewPreItem")
end

function RARechargeCumulativePopupPage:scrollViewChangeItem(cell)
    print("RARechargeCumulativePopupPage:scrollViewChangeItem")
end


function RARechargeCumulativePopupPage:onBackBtn()
    RARootManager.ClosePage("RARechargeCumulativePopupPage")
end

function RARechargeCumulativePopupPage:Exit(data)
    RARealPayManager.comFromPop = false
    self:unregisterMessageHandlers()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RARechargeCumulativePopupPage")        
    self.constAddInfo = nil
    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    UIExtend.unLoadCCBFile(self)
end

return RARechargeCumulativePopupPage