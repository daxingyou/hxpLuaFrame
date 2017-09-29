local UIExtend         = RARequire("UIExtend")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire("RARootManager")
local RAVIPDataManager = RARequire("RAVIPDataManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAPackageData = RARequire("RAPackageData")
local RANetUtil = RARequire("RANetUtil")
local Utilitys = RARequire("Utilitys")
local RA_Common = RARequire("common")
local RALogicUtil = RARequire("RALogicUtil")

RARequire("MessageDefine")
RARequire("MessageManager")

local RAVIPUseToolsPage  = BaseFunctionPage:new(...)

local RAVIPUseToolsPageHandler = {}
RAVIPUseToolsPage.scrollView = nil
local timeCount=0
---------------------------scroll content cell---------------------------
local RAContentCellListener = {
contentIndex = 1,
contentInfo = nil
}
function RAContentCellListener:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function RAContentCellListener:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile = ccbfile
	if ccbfile then

		local itemData = self.contentInfo.conf

		local picName = "Resource/Image/Item/"..itemData.item_icon..".png"
	    local bgName  = RALogicUtil:getItemBgByColor(itemData.item_color)
	    UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", bgName, nil, nil, 20000)
	    UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", picName)

		local count = RACoreDataManager:getItemCountByItemId(itemData.id)
        UIExtend.setCCLabelString(ccbfile,"mCellTitleName", _RALang(itemData.item_name))
        UIExtend.setCCLabelString(ccbfile,"mCellItemExplain", _RALang(itemData.item_des))
        local colorMap = {}
		colorMap["mCellTitleName"] = COLOR_TABLE[itemData.item_color]
	    UIExtend.setColorForLabel(ccbfile, colorMap)
		UIExtend.setCCLabelString(ccbfile,"mCurrentHaveNum", _RALang("@itemCurrentCount")..(count or 0))
		UIExtend.setCCLabelString(ccbfile,"mDiamondsNum", itemData.sellPrice)
		if count == nil or count <= 0 then
			UIExtend.setNodeVisible(ccbfile, "mUseBtnNode", false)
			UIExtend.setNodeVisible(ccbfile, "mBuyBtnNode", true)
			UIExtend.updateControlButtonTitle(ccbfile, "mBuyBtnac" )
		else
			UIExtend.setNodeVisible(ccbfile, "mUseBtnNode", true)
			UIExtend.setNodeVisible(ccbfile, "mBuyBtnNode", false)
			UIExtend.updateControlButtonTitle(ccbfile, "mUseBtnac" )
		end
	end
end


function RAContentCellListener:showUseTools()
    RAVIPDataManager.Object.VIPToolsItemId=self.contentInfo.conf.id
	
	local itemData=self.contentInfo.conf
	local serverItem=RAVIPDataManager.getItemServerByItemId(itemData.id)
	if serverItem~=nil then
		itemData.uuid   = serverItem.uuid
		itemData.isNew  = serverItem.isNew
		itemData.count  = RACoreDataManager:getItemCountByItemId(itemData.id)
		itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse
		itemData.useUUID=false
		RARootManager.showPackageInfoPopUp(itemData)	
	else
		RAContentCellListener:onBuyBtn()
	end
end

--使用按钮
function RAContentCellListener:onUseBtn()
	CCLuaLog("RAContentCellListener:onUseBtn")

    local playerData=RAVIPDataManager.getPlayerData()
	if playerData==nil then
		return
	end

	local level=playerData.vipLevel
    if level >= RAVIPDataManager.getMaxVIPLevel() and RAVIPDataManager.getShowConfirm() == false then
        RAVIPDataManager.setShowConfirm(true)
        local confirmData = {}
        confirmData.labelText = _RALang("@VIPMaxLevelPrompt")
        confirmData.title = ""
        confirmData.yesNoBtn = true
        confirmData.resultFun = function (isOk)
            if isOk then
                self:showUseTools()
            end
        end
        RARootManager.OpenPage("RAConfirmPage", confirmData)
    else
        self:showUseTools()
    end
end


function RAContentCellListener:showBuyTools()
    RAVIPDataManager.Object.VIPToolsItemId=self.contentInfo.conf.id
	local conf=self.contentInfo.conf
	local itemConf = RAVIPDataManager.getShopConfByItemId(conf.id)--传入的是物品
	local itemData = self.contentInfo.conf
	itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy
	itemData.shopId     = itemConf.id
	itemData.price      = itemConf.price
	RAVIPDataManager.Object.SelBuyItemConf=itemData
	
	RARootManager.OpenPage("RAVIPBuyToolsPopup", nil, false, false ,true)
	--RARootManager.showPackageInfoPopUp(itemData)
end

--购买按钮
function RAContentCellListener:onBuyBtn()
    local playerData=RAVIPDataManager.getPlayerData()
	if playerData==nil then
		return
	end
	
	local level=playerData.vipLevel
    if level >= RAVIPDataManager.getMaxVIPLevel() and RAVIPDataManager.getShowConfirm() == false then
        RAVIPDataManager.setShowConfirm(true)
        local confirmData = {}
        confirmData.labelText = _RALang("@VIPMaxLevelPrompt")
        confirmData.title = ""
        confirmData.yesNoBtn = true
        confirmData.resultFun = function (isOk)
            if isOk then
                self:showBuyTools()
            end
        end
        RARootManager.OpenPage("RAConfirmPage", confirmData)
    else
        self:showBuyTools()
    end
end


---------------------------scroll content cell---------------------------

function RAVIPUseToolsPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAVIPBuyPage.ccbi", RAVIPUseToolsPage)
	self.ccbfile  = ccbfile
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mVIPBuyListSV")
	if self.scrollView ~= nil then
		self.scrollView:setBounceable(true)
	end

	self:registerMessage()
	self:init()
end

--这里需要处理刷新时间
function RAVIPUseToolsPage:Execute()
    timeCount=timeCount+1
    if timeCount%5==0 then
	    self:refereshEndTime()
    end
end

--初始化
function RAVIPUseToolsPage:init()
	self:initTitle()
	self:initVIPBar()
	self:refereshVIPActiveStatus()
	self:initRenderScrollView()
end

--初始化VIP信息
function RAVIPUseToolsPage:initVIPBar()
	
	local playerData=RAVIPDataManager.getPlayerData()
	if playerData==nil then
		return
	end
	
	local level=playerData.vipLevel
	local vipPoints=playerData.vipPoints

	local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(level)
    if currVIPConfig~=nil then
        if vipPoints==nil or tonumber(vipPoints)==0 then
            vipPoints=0
        end

        local percent=1.0
        if level >= RAVIPDataManager.getMaxVIPLevel() then
	        UIExtend.setCCLabelString(self.ccbfile, "mVIPExp",tostring(vipPoints))
        else
            local nextPoint=RAVIPDataManager.getVIPUpgradeNeedPointByLevel(level)
	        UIExtend.setCCLabelString(self.ccbfile, "mVIPExp",tostring(vipPoints).."/"..tostring(nextPoint))
            if tonumber(vipPoints)~=0 then
                if tonumber(vipPoints)<tonumber(nextPoint) then
                    percent=tonumber(vipPoints)/tonumber(nextPoint)
                end
            else
                percent=0
            end
        end

        local target = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mVIPPointBar")
        target:setScaleX(percent)

	    UIExtend.setCCLabelBMFontString(self.ccbfile, "mCurrentVip","VIP"..tostring(level))
    end

    self:refereshEndTime()
end

function RAVIPUseToolsPage:refereshVIPActiveStatus()
	local mainNode = self.ccbfile:getCCNodeFromCCB("mGrayNode")
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    if not isActive then
        local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
        graySprite:setTag(grayTag)
        graySprite:setPosition(mainNode:getPosition())
        graySprite:setAnchorPoint(mainNode:getAnchorPoint())
        mainNode:getParent():addChild(graySprite)
    end
 end   

 function RAVIPUseToolsPage:renderActiveStatus(isActive)
 	if isActive==nil then
 		self:refereshVIPActiveStatus()
 	end	

	if isActive~=RAVIPDataManager.Object.isActive then
		RAVIPDataManager.Object.isActive=isActive
		self:refereshVIPActiveStatus()
	end
 end

--刷新VIP倒计时面板
function RAVIPUseToolsPage:refereshEndTime()
	local player=RAVIPDataManager.getPlayerData()
	local endTime=tonumber(player.vipEndTime)/1000
	if endTime==nil or endTime<RA_Common:getCurTime() then
		endTime=0
	end
	local lastTime=0
	if endTime~=0 then
		lastTime= Utilitys.getCurDiffTime(endTime)
	end

	if endTime==nil or endTime<RA_Common:getCurTime() then
		isActive=false
	else
		isActive=true	
	end

	self:renderActiveStatus(isActive)

	local surplusTime=Utilitys.createTimeWithFormat(lastTime)
	local timeStr=tostring(surplusTime)
    if endTime==0 or lastTime<=0 then
    	timeStr=_RALang("@NoActived")
	end
    UIExtend.setCCLabelString(self.ccbfile, "mTimeLeftLabel",timeStr)
end

--初始化页面头
function RAVIPUseToolsPage:initTitle()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local backCallBack = function()
		RARootManager.CloseCurrPage()
	end
	
	local titleName = _RALang("@VIPToolsListTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAVIPUseToolsPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

--初始化VIP相关物品信息
function RAVIPUseToolsPage:initRenderScrollView()
	local scrollView = self.scrollView
	scrollView:removeAllCell()
	local cfgData = RAVIPDataManager.getVIPToolsData()
	
	for k,v in pairs(cfgData) do
		local cell = CCBFileCell:create()
		local ccbiStr = "RAVIPBuyCell.ccbi"
		cell:setCCBFile(ccbiStr)
		local panel = RAContentCellListener:new({contentInfo = v,contentIndex   = k})
		cell:registerFunctionHandler(panel)
		scrollView:addCell(cell)
	end
	scrollView:orderCCBFileCells()
end

--道具消耗后刷新页面
function RAVIPUseToolsPage:refreshRender()
	self:refreshVIPBar()
	self:initRenderScrollView()
	--不需要重新构建，但目前刷新面板方法没研究，后面再优化
	--self:refreshRenderScrollView()
end

--道具消耗后刷新VIP面板
function RAVIPUseToolsPage:refreshVIPBar()
	self:initVIPBar()
	self:refereshEndTime()
end

--道具消耗后刷新更新物品
function RAVIPUseToolsPage:refreshRenderScrollView()
	if self.scrollView~=nil then
		self.scrollView:orderCCBFileCells()
	end
end

function RAVIPUseToolsPage:addHandler()
	RAVIPUseToolsPageHandler[#RAVIPUseToolsPageHandler +1] = RANetUtil:addListener(HP_pb.PLAYER_INFO_SYNC_S, RAVIPUseToolsPage)
	RAVIPUseToolsPageHandler[#RAVIPUseToolsPageHandler +1] = RANetUtil:addListener(HP_pb.PLAYER_AWARD_S, RAVIPUseToolsPage)
end

function RAVIPUseToolsPage:removeHandler()
	for k, value in pairs(RAVIPUseToolsPageHandler) do
		if RAVIPUseToolsPageHandler[k] then
			RANetUtil:removeListener(RAVIPUseToolsPageHandler[k])
			RAVIPUseToolsPageHandler[k] = nil
		end
	end
	RAVIPUseToolsPageHandler = {}
end

local OnReceiveMessage = function(message)
	if message.messageID == MessageDef_package.MSG_package_consume_item then
		RAVIPUseToolsPage:refreshRender()
	elseif message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        RAVIPUseToolsPage:refreshRender()
	end
end

function RAVIPUseToolsPage:registerMessage()
	self:addHandler()
	MessageManager.registerMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
	MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RAVIPUseToolsPage:removeMessageHandler()
	self:removeHandler()
	MessageManager.removeMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
	MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

--接收服务器包，刷新面板
function RAVIPUseToolsPage:onReceivePacket(handler)
	RARootManager.RemoveWaitingPage()
	local pbCode = handler:getOpcode()
	local buffer = handler:getBuffer()
	if pbCode == HP_pb.PLAYER_AWARD_S then
		self:refreshRender()
	elseif	pbCode == HP_pb.PLAYER_INFO_SYNC_S then
		self:refreshRender()
	end
end

function RAVIPUseToolsPage:Exit()
	RACommonTitleHelper:RemoveCommonTitle("RAVIPUseToolsPage")
	if self.scrollView~=nil then
		self.scrollView:removeAllCell()
	end
	self:removeMessageHandler()
	self.ccbfile:stopAllActions()
	UIExtend.unLoadCCBFile(self)
	MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
end


