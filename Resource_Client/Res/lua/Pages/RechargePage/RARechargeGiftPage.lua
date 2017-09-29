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
local RAGameConfig = RARequire("RAGameConfig")

local RARechargeGiftPage = BaseFunctionPage:new(...)
RARechargeGiftPage.scrollView = nil
RARechargeGiftPage.itemInfo = nil
RARechargeGiftPage.timeLabel = nil

----------------------------------------------------------------
--消息处理
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Pay.MSG_PaySuccess then
        RARootManager.ClosePage("RARechargeGiftPage")
    end
end

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
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
		UIExtend.setCCLabelString(ccbfile,"mCellTitle",_RALang(name))
        UIExtend.setCCLabelString(ccbfile, "mCellNum", self.cellRewardItem.itemCount)
    end
end

-----------------------------------------------------------------
function RARechargeGiftPage:Enter(data)
    self.itemInfo = data.data
    local detailIndex = 1
    if self.itemInfo.showDetail ~= nil then
        detailIndex = string.sub(self.itemInfo.showDetail, string.len("libao")+1, string.len(self.itemInfo.showDetail))
    end
    local ccbName = "RAStoreGiftPackItemPage"..detailIndex..".ccbi"
    UIExtend.loadCCBFile(ccbName,self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")
    self.timeLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mTime")
    self:refreshUI()
    self:_addHandler()
end

function RARechargeGiftPage:refreshUI()
    if self.itemInfo then
        if self.itemInfo.name then
            UIExtend.setCCLabelString(self.ccbfile, "mTitle", _RALang(self.itemInfo.name))
        end

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
            UIExtend.setCCLabelBMFontString(self.ccbfile, "mDiamondsPercent", percentStr)
        else
            UIExtend.setNodeVisible(self.ccbfile, "mSaleNode", false)
        end

        UIExtend.setSpriteIcoToNode(self.ccbfile, "mDetailsIcon", self.itemInfo.show)

        if self.itemInfo.gold then
            UIExtend.setCCLabelBMFontString(self.ccbfile, "mDiamondsNum", tostring(self.itemInfo.gold))
        end

        self.scrollView:removeAllCell()
        for i = 1, #self.itemInfo.awardItems do
            local rewardItem = self.itemInfo.awardItems[i]
            local cellListener = RARewardCellListener:new({cellRewardItem = rewardItem})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAStoreGiftPackItemCell.ccbi")
            cell:registerFunctionHandler(cellListener)
            self.scrollView:addCellBack(cell)
        end
        self.scrollView:orderCCBFileCells()

        local platformProductInfo = RARealPayManager.getPlatfromProductionByProductId(self.itemInfo.saleId)
        if platformProductInfo then
            UIExtend.setControlButtonTitle(self.ccbfile, "mBuyBtn", tostring(platformProductInfo.formatterPrice))
        else
            local realPrice = tonumber(self.itemInfo.payPrice) / 100
            local price = RAStringUtil:getLanguageString("@PayPrice", realPrice)
            UIExtend.setControlButtonTitle(self.ccbfile, "mBuyBtn", price)
        end

    end
end


--desc:添加各种监听
function RARechargeGiftPage:_addHandler()
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PaySuccess, OnReceiveMessage)
end

--desc:移除各种监听
function RARechargeGiftPage:_removeHandler()
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PaySuccess, OnReceiveMessage)
end


function RARechargeGiftPage:onClose()
    RARootManager.ClosePage("RARechargeGiftPage")
end

function RARechargeGiftPage:Exit(data)
    self.itemInfo = nil
    self.timeLabel:stopAllActions()
    self.timeLabel = nil
    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    self:_removeHandler()
    UIExtend.unLoadCCBFile(self)
    RARealPayManager.comFromPop = false
    MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
end

function RARechargeGiftPage:onBuyBtn()
    local RARootManager = RARequire('RARootManager')
    
    if RAGameConfig.SwitchPay and RAGameConfig.SwitchPay == 1 then
        local RARechargeMainPage = RARequire("RARechargeMainPage")
        local msg = Recharge_pb.RechargeRequest()
        msg.goodsId = self.itemInfo.goodsId
        RARealPayManager.goodsId = self.itemInfo.goodsId
        RARealPayManager.comFromPop = true
        RANetUtil:sendPacket(HP_pb.RECHARGE_C, msg)

        if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
            RARootManager.ShowWaitingPage(true)
        end
    else
        self:onClose()
    end
end

return RARechargeGiftPage