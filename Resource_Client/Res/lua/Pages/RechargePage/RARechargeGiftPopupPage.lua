-------------------------------
--page:礼包详细页面
-------------------------------
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAResManager = RARequire("RAResManager")
local Recharge_pb = RARequire("Recharge_pb")
local RANetUtil = RARequire("RANetUtil")
local RARealPayManager = RARequire("RARealPayManager")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")

local RARechargeGiftPopupPage = BaseFunctionPage:new(...)
RARechargeGiftPopupPage.scrollView = nil
RARechargeGiftPopupPage.itemInfo = nil
RARechargeGiftPopupPage.timeLabel = nil


----------------------------------------------------------------
local RARewardCellListener = {
    cellRewardItem = nil
}

function RARewardCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RARewardCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile and self.cellRewardItem then
        local icon, name = RAResManager:getIconByTypeAndId(self.cellRewardItem.itemType, self.cellRewardItem.itemId)
        UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", icon)
		UIExtend.setCCLabelString(ccbfile,"mCellName",_RALang(name))
        UIExtend.setCCLabelString(ccbfile, "mCellNum", self.cellRewardItem.itemCount)
    end
end

-----------------------------------------------------------------
function RARechargeGiftPopupPage:Enter(data)
    UIExtend.loadCCBFile("RAStoreDetailsPopUp.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mDetailsListSV")
    self.itemInfo = data.data
    self.timeLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mTime")
    self:refreshUI()
end

function RARechargeGiftPopupPage:refreshUI()
    if self.itemInfo then
        UIExtend.setCCLabelString(self.ccbfile, "mTitle", _RALang(self.itemInfo.name))

        local updateFun = function ()
            local remainTime = Utilitys.getCurDiffTime(self.itemInfo.endTime / 1000)

            if remainTime < 0 then --时间倒计时为0就隐藏进度条
                remainTime = 0
                self.ccbfile:stopAllActions()
                UIExtend.setCCControlButtonEnable(self.ccbfile, "mBuyBtn", false)
            else
                UIExtend.setCCControlButtonEnable(self.ccbfile, "mBuyBtn", true)
            end 

            local tmpStr = Utilitys.createTimeWithFormat(remainTime)
            if self.timeLabel then
                self.timeLabel:setString(tmpStr)
            end 
        end


        if self.itemInfo.endTime > 0 then
            UIExtend.setNodeVisible(self.ccbfile, "mTimeNode", true)
            schedule(self.ccbfile, updateFun, 1)
            updateFun()
        else
            UIExtend.setNodeVisible(self.ccbfile, "mTimeNode", false)
        end

        if self.itemInfo.percent > 0 then
            UIExtend.setNodeVisible(self.ccbfile, "mSaleNode", true)
            local percentStr = RAStringUtil:getLanguageString("@Percent", self.itemInfo.percent)
            UIExtend.setCCLabelString(self.ccbfile, "mPercentTitle", percentStr)
        else
            UIExtend.setNodeVisible(self.ccbfile, "mSaleNode", false)
        end

        UIExtend.setSpriteIcoToNode(self.ccbfile, "mDetailsIcon", self.itemInfo.show)

        if self.itemInfo.gold then
            UIExtend.setCCLabelString(self.ccbfile, "mCellNum", tostring(self.itemInfo.gold))
        end

        self.scrollView:removeAllCell()
        for i = 1, #self.itemInfo.awardItems do
            local rewardItem = self.itemInfo.awardItems[i]
            local cellListener = RARewardCellListener:new({cellRewardItem = rewardItem})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAStoreAccumulativeCell.ccbi")
            cell:registerFunctionHandler(cellListener)
            self.scrollView:addCellBack(cell)
        end
        self.scrollView:orderCCBFileCells()

        local platformProductInfo = RARealPayManager.getPlatfromProductionByProductId(self.itemInfo.saleId)
        if platformProductInfo then
            UIExtend.setCCLabelString(self.ccbfile, "mNowLabel", tostring(platformProductInfo.formatterPrice))
        else
            local price = RAStringUtil:getLanguageString("@PayPrice", self.itemInfo.payPrice)
            UIExtend.setCCLabelString(self.ccbfile, "mNowLabel", price)
        end

    end
end

function RARechargeGiftPopupPage:onClose()
    RARootManager.ClosePage("RARechargeGiftPopupPage")
end

function RARechargeGiftPopupPage:Exit(data)
    self.itemInfo = nil
    self.timeLabel = nil
    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    UIExtend.unLoadCCBFile(self)
    RARealPayManager.comFromPop = false
    MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
end

function RARechargeGiftPopupPage:onBuyBtn()
    local RARechargeMainPage = RARequire("RARechargeMainPage")
    local msg = Recharge_pb.RechargeRequest()
    msg.goodsId = self.itemInfo.goodsId
    RARealPayManager.goodsId = self.itemInfo.goodsId
    RARealPayManager.comFromPop = true
    RANetUtil:sendPacket(HP_pb.RECHARGE_C, msg)

    if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
        RARootManager.ShowWaitingPage(true)
    end
end

return RARechargeGiftPopupPage