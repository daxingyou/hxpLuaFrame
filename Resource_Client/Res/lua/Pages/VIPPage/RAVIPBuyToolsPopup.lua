RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAVIPDataManager = RARequire("RAVIPDataManager")
local RANetUtil = RARequire("RANetUtil")

local RAVIPBuyToolsPopup = BaseFunctionPage:new(...)
local RAVIPBuyToolsPopupHandler = {}
local SelBuyItemConf=nil


function RAVIPBuyToolsPopup:Enter(data)
	self.ccbfile =  UIExtend.loadCCBFile("RAVIPBuyPopUp.ccbi", RAVIPBuyToolsPopup)
	self:LoadData()
	self:registerHandler()
	self:initPage()
	self:AddNoTouchLayer(true)
end

function RAVIPBuyToolsPopup:initPage()
	UIExtend.setCCLabelString(self.ccbfile,"mItemTitle", _RALang("@VIPBuyTitle"))
	if  SelBuyItemConf~=nil then
		local picName = "Resource/Image/Item/"..SelBuyItemConf.item_icon..".png"
	    local bgName  = RALogicUtil:getItemBgByColor(SelBuyItemConf.item_color)
	    UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode", bgName, nil, nil, 20000)
	    UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode", picName)

        UIExtend.setCCLabelString(self.ccbfile,"mItemName", _RALang(SelBuyItemConf.item_name))
        UIExtend.setCCLabelString(self.ccbfile,"mItemExplain", _RALang(SelBuyItemConf.item_des))
        local colorMap = {}
		colorMap["mItemName"] = COLOR_TABLE[SelBuyItemConf.item_color]
	    UIExtend.setColorForLabel(self.ccbfile, colorMap)
		UIExtend.setCCLabelString(self.ccbfile,"mBuyDiamondsNum", SelBuyItemConf.sellPrice)
	end
end

--请求VIP数据，设置等待窗口
function RAVIPBuyToolsPopup:LoadData()
	SelBuyItemConf=RAVIPDataManager.Object.SelBuyItemConf
	if SelBuyItemConf==nil then
		CCLuaLog("RAVIPBuyToolsPopup:LoadData()-RAVIPDataManager.Object.SelBuyItemConf is nil!")
	end
end

function RAVIPBuyToolsPopup:onBuyBtn()
	--钻石检测
	local itemId=SelBuyItemConf.id

	local buyPrice=SelBuyItemConf.sellPrice
	local player=RAVIPDataManager.getPlayerData()
	if itemId~=nil then
		local RAPackageManager = RARequire("RAPackageManager")
		RAPackageManager:sendBuyAndUse(itemId, 1)
	end
end

function RAVIPBuyToolsPopup:addHandler()
	RAVIPBuyToolsPopupHandler[#RAVIPBuyToolsPopupHandler +1] = RANetUtil:addListener(HP_pb.ITEM_USE_S, RAVIPBuyToolsPopup)
	RAVIPBuyToolsPopupHandler[#RAVIPBuyToolsPopupHandler +1] = RANetUtil:addListener(HP_pb.ITEM_BUY_S, RAVIPBuyToolsPopup)
	RAVIPBuyToolsPopupHandler[#RAVIPBuyToolsPopupHandler +1] = RANetUtil:addListener(HP_pb.PLAYER_AWARD_S, RAVIPBuyToolsPopup)
end

function RAVIPBuyToolsPopup:removeHandler()
	for k, value in pairs(RAVIPBuyToolsPopupHandler) do
		if RAVIPBuyToolsPopupHandler[k] then
			RANetUtil:removeListener(RAVIPBuyToolsPopupHandler[k])
			RAVIPBuyToolsPopupHandler[k] = nil
		end
	end
	RAVIPBuyToolsPopupHandler = {}
end

--注册客户端消息分发
function RAVIPBuyToolsPopup:registerHandler()
	RAVIPBuyToolsPopup:addHandler()
end

--移除客户端消息分发注册
function RAVIPBuyToolsPopup:unRegiterHandler()
	RAVIPBuyToolsPopup:removeHandler()
end

--接收服务器包
function RAVIPBuyToolsPopup:onReceivePacket(handler)
	RARootManager.RemoveWaitingPage()
	local pbCode = handler:getOpcode()
	local buffer = handler:getBuffer()
	if pbCode == HP_pb.PLAYER_AWARD_S then
		CCLuaLog("RAVIPBuyToolsPopup:onReceivePacket:PLAYER_AWARD_S")
	elseif	pbCode == HP_pb.ITEM_USE_S then
		CCLuaLog("RAVIPBuyToolsPopup:onReceivePacket:ITEM_USE_S")
	elseif	pbCode == HP_pb.ITEM_BUY_S then
		CCLuaLog("RAVIPBuyToolsPopup:onReceivePacket:ITEM_BUY_S")
	end
    self:onClose()
end

--关闭按钮
function RAVIPBuyToolsPopup:onClose()
	RARootManager.ClosePage("RAVIPBuyToolsPopup")
	MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
end

--退出页面
function RAVIPBuyToolsPopup:Exit(data)
	self:unRegiterHandler()
	UIExtend.unLoadCCBFile(RAVIPBuyToolsPopup)
	self.ccbfile = nil
end