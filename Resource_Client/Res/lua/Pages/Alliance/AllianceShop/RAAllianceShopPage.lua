--联盟商店页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local HP_pb = RARequire('HP_pb')
RARequire('extern')
RARequire('MessageManager')
local RAAllianceShopItemCell =  RARequire('RAAllianceShopItemCell')
local RAAllianceSellItemCell =  RARequire('RAAllianceSellItemCell')
local RANetUtil =  RARequire('RANetUtil')
local UIExtend = RARequire('UIExtend')
local RAAllianceProtoManager =  RARequire('RAAllianceProtoManager')
local RARootManager = RARequire('RARootManager')
local RAAllianceShopPage = class('RAAllianceShopPage',RAAllianceBasePage)
local Utilitys = RARequire('Utilitys')

local localObj = nil 

local PAGE_TYPE = {
	NONE = 0,
	SELL_LIST = 1,
	ALL_LIST = 2
}

function RAAllianceShopPage:ctor(...)
    self.ccbfileName = "RAAllianceShopPage.ccbi"
    self.scrollViewName = 'mSmallListSV'
    self.curPage = PAGE_TYPE.NONE 
end

function RAAllianceShopPage:init(data)

    localObj = self
	self.curPage = PAGE_TYPE.NONE
	self.mExplain = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mExplain')
    self.mExplain:setString(_RALang('@AllianceShopExplainDesc') .. '\n' .. _RALang('@AllianceShopExplainDesc2') .. '\n')

    --联盟贡献
    self.mContribution = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mContribution')
    self:setContribution(0)

    --联盟历史积分
    self.mHistoricalPoints = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHistoricalPoints')
    self:setHistoryPoint(0)

    --底部节点
    self.mBottomNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mBottomNode')
    
    self.mHistoryBtn = UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mHistoryBtn')

    self.mRecordLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, 'mRecordLabel')
end 

function RAAllianceShopPage:setCurPage(pageType)
	if self.curPage == pageType then 
		return
	end

	local titleName = ''
	self.curPage = pageType 

	if self.curPage == PAGE_TYPE.SELL_LIST then 
		self.mSmallListSV:setVisible(true)
		self.mBigListSV:setVisible(false)
		self.mBottomNode:setVisible(true)
        self.mHistoryBtn:setVisible(true)
        self.mRecordLabel:setVisible(true)
		RAAllianceProtoManager:reqShopInfo()
		titleName = _RALang("@AllianceShop")
	elseif self.curPage == PAGE_TYPE.ALL_LIST then 
		self.mSmallListSV:setVisible(false)
		self.mBigListSV:setVisible(true)
		self.mBottomNode:setVisible(false)
        self.mHistoryBtn:setVisible(false)
        self.mRecordLabel:setVisible(false)
        RAAllianceProtoManager:reqAllShopItems()
		titleName = _RALang("@AllianceItemList")
	end  

	UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

--子类实现
function RAAllianceShopPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_GET_SHOP_INFO_S, self) --获得商店信息 
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_GET_SHOP_ITEM_LIST_S, self) --获得商店信息
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_SHOP_BUY_S, self) --买完刷新一下
end

function RAAllianceShopPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
	
	if pbCode == HP_pb.GUILD_GET_SHOP_INFO_S or pbCode == HP_pb.GUILD_SHOP_BUY_S  then --获得联盟物品
        self.shopInfo = RAAllianceProtoManager:getShopInfo(buffer)
        self:refreshSellItems()

        if pbCode == HP_pb.GUILD_SHOP_BUY_S then
            RARootManager.ShowMsgBox("@buySuccessful")
        end
    elseif pbCode == HP_pb.GUILD_GET_SHOP_ITEM_LIST_S  then --获得联盟全部物品
        self.allShopInfo = RAAllianceProtoManager:getAllShopItem(buffer)
        self:refreshAllSellItems()
    end
end

function RAAllianceShopPage:refreshSellItems()
	self:setContribution(self.shopInfo.contribution)
    --联盟历史积分
    self:setHistoryPoint(self.shopInfo.historyScore)

    self:orderItems(self.shopInfo)
    self.mSmallListSV:removeAllCell()
    for i=1,#self.shopInfo.shopItems do
    	self.shopInfo.shopItems[i].historyScore = self.shopInfo.historyScore
        self.shopInfo.shopItems[i].contribution = self.shopInfo.contribution
        local cell = CCBFileCell:create()
        local ccbiStr = "RAAllianceShopCell.ccbi"
        cell:setCCBFile(ccbiStr)
        local panel = RAAllianceShopItemCell:new({
            	info = self.shopInfo.shopItems[i]
        })
        panel.cellType = 1
        cell:registerFunctionHandler(panel)
        self.mSmallListSV:addCell(cell)
    end

    self.mSmallListSV:orderCCBFileCells()
end

function RAAllianceShopPage:orderItems(itemInfo)
    local arr = itemInfo.shopItems
    local RAAllianceManager = RARequire('RAAllianceManager')
    local level = RAAllianceManager.selfAlliance.level
    table.sort( arr, function (v1,v2)
        if v1.unlockLevel <= level and v2.unlockLevel > level then 
            return true
        elseif  v1.unlockLevel > level and v2.unlockLevel <= level then 
            return false 
        elseif v1.isRare == true and v2.isRare == false then 
            return true
        elseif v1.isRare == false and v2.isRare == true then 
            return false      
        --elseif v1.price < v2.price then 
        --    return true
        --elseif v1.price > v2.price then 
        --    return false
        elseif v1.itemId > v2.itemId then 
            return false
        elseif v1.itemId < v2.itemId then 
            return true
        end 
        return false 
    end)
    itemInfo.shopItems = arr
end

function RAAllianceShopPage:refreshAllSellItems()
    self:setContribution(self.allShopInfo.contribution)
    --联盟历史积分
    self:setHistoryPoint(self.allShopInfo.historyScore)

    self.mBigListSV:removeAllCell()

    self:orderItems(self.allShopInfo)

    for i=1,#self.allShopInfo.shopItems do
        self.allShopInfo.shopItems[i].historyScore = self.allShopInfo.historyScore
        local cell = CCBFileCell:create()
        local ccbiStr = "RAAllianceShopCell2.ccbi"
        cell:setCCBFile(ccbiStr)
        local panel = RAAllianceSellItemCell:new({
                info = self.allShopInfo.shopItems[i]
        })
        panel.cellType = 2
        cell:registerFunctionHandler(panel)
        self.mBigListSV:addCell(cell)
    end

    self.mBigListSV:orderCCBFileCells()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        if message.opcode == HP_pb.GUILD_SHOP_BUY_C then 
            RAAllianceProtoManager:reqShopInfo()
        end 
    end 
end


function RAAllianceShopPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceShopPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceShopPage:release()
    self.mSmallListSV:removeAllCell()
    self.mBigListSV:removeAllCell()
end

--子类实现
function RAAllianceShopPage:initScrollview()
	--贩卖的商品
	self.mSmallListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
	--全部的商品
	self.mBigListSV =  UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mBigListSV')

    self:setCurPage(PAGE_TYPE.SELL_LIST)
end

function RAAllianceShopPage:mAllianceCommonCCB_onBack()

	if self.curPage == PAGE_TYPE.SELL_LIST then 
		RARootManager.ClosePage(self.__cname)
	elseif self.curPage == PAGE_TYPE.ALL_LIST then 
		self:setCurPage(PAGE_TYPE.SELL_LIST)
	end 
end

--初始化顶部
function RAAllianceShopPage:initTitle()
    -- body
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
end

function RAAllianceShopPage:onHistoryBtn()
	-- CCLuaLog('onHistoryBtn')
	RARootManager.OpenPage("RAAllianceBuyRecordPage")
end

--点击说明
function RAAllianceShopPage:onHelpBtn()
	-- CCLuaLog('question')
    RARootManager.OpenPage("RAAllianceContributePage")
end

function RAAllianceShopPage:setHistoryPoint(value)
	local valueText =  Utilitys.formatNumber(value)
	self.mHistoricalPoints:setString(valueText)
end

function RAAllianceShopPage:setContribution(value)
	self.mContribution:setString(_RALang('@ContributionValue') .. ':' .. value)
end

function RAAllianceShopPage:onListBtn()
	-- CCLuaLog('商品列表')
	self:setCurPage(PAGE_TYPE.ALL_LIST)
end

return RAAllianceShopPage.new()