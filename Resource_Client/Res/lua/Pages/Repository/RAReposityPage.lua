--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--仓库资源界面
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb =RARequire('Const_pb')
local HP_pb=RARequire("HP_pb")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAGameConfig=RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local Utilitys=RARequire("Utilitys")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAPackageData = RARequire("RAPackageData")
local RABuildManager = RARequire("RABuildManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")

RARequire("MessageDefine")
RARequire("MessageManager")
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK

local TAG = 1000

local resourceTypeTab={
	Gold_functionBlock=14,
	Oil_functionBlock=17,
	Steel_functionBlock=16,
	RareEarths_functionBlock=15,
}

local RAReposityPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID ==OperationOkMsg then   --使用道具后刷新数据
        local opcode = message.opcode
        if opcode == HP_pb.ITEM_USE_C then
        	 RARootManager.ShowMsgBox('@useSuccessful')           
            RAReposityPage:updateInfo(RAReposityPage.resourceType)
        elseif opcode == HP_pb.ITEM_BUY_C then
        	RARootManager.ShowMsgBox('@buySuccessful')
        	RAReposityPage:updateInfo(RAReposityPage.resourceType)
        end
    end
end

-----------------------------------------------------------------
local RAReposityPageCell={}
function RAReposityPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAReposityPageCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile =ccbfile
	UIExtend.handleCCBNode(ccbfile)

	local data = self.data

	--icon
	local itemId = data.id
	local icon = RALogicUtil:getItemIconById(itemId)
	local picNode=UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)


	--quality
	local bgName  = RALogicUtil:getItemBgByColor(data.item_color)
    UIExtend.addSpriteToNodeParent(ccbfile, 'mQualityNode', bgName)
	--title
	local name = data.item_name
	UIExtend.setCCLabelString(ccbfile,"mCellTitle",_RALang(name))

	--explain
	local explain = data.item_des
	UIExtend.setCCLabelString(ccbfile,"mExplain",_RALang(explain))

	UIExtend.setControlButtonTitle(ccbfile, "mBuyBtnac", _RALang("@Purchase"), true)

	--count
	local count = RACoreDataManager:getItemCountByItemId(itemId)
	if data.isSellable==1 then   		--没有的话可以购买
 		if count>=1 then
 			self:setNodeVisible(true)	
		else
			self:setNodeVisible(false)
 			local price = data.sellPrice
 			UIExtend.setCCLabelString(ccbfile,"mDiamondsNum",price)
 		end 
 	else
 		self:setNodeVisible(true)
 	end 

	self.data.count = count
	count = Utilitys.formatNumber(count)
	UIExtend.setCCLabelString(ccbfile,"mHaveNum",_RALang("@HaveNumNow",count))


 

end
function RAReposityPageCell:setNodeVisible(isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mUseBtn",isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mBuyBtnNode",not isVisible)
end


--使用
function RAReposityPageCell:onUseBtn()

	local itemData=self.data
    itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse
	itemData.useUUID=true
	local itemServerData=RACoreDataManager:getItemInfoByItemId(itemData.id)
	itemData.uuid = itemServerData.server[1].uuid
	RARootManager.showPackageInfoPopUp(itemData)
end

--购买并使用
function RAReposityPageCell:onBuyBtn()


	local itemData=self.data
	local RAVIPDataManager = RARequire("RAVIPDataManager")
	local shopData  = RAVIPDataManager.getShopConfByItemId(self.data.id)			--传入的是物品
	itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy
	itemData.shopId     = shopData.id
	itemData.price      = shopData.price
	RARootManager.showPackageInfoPopUp(itemData)

	
 --    local RAVIPDataManager = RARequire("RAVIPDataManager")
 --    local RAPackageData = RARequire("RAPackageData")
	-- local shopData = RAVIPDataManager.getShopConfByItemId(self.data.id)
	-- local itemData = self.data
	-- itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy
	-- itemData.shopId     = itemConf.id
	-- itemData.price      = itemConf.price
	-- RAVIPDataManager.Object.SelBuyItemConf=itemData
	
	-- RARootManager.OpenPage("RAVIPBuyToolsPopup", nil, false, false ,true)

end


function RAReposityPage:Enter(data)


	CCLuaLog("RAReposityPageCell:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAResourcePage.ccbi",self)
	self.ccbfile  = ccbfile
	if data and data.resourceType then
		self.resourceType = data.resourceType
	else
		self.resourceType =resourceTypeTab.Gold_functionBlock
	end 

	self:registerMessageHandler()
	self:init()
	self:updateInfo(self.resourceType)

end

function RAReposityPage:registerMessageHandler()
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)   
end

function RAReposityPage:removeMessageHandler()
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
end


function RAReposityPage:setSelectedBtn(tabsIndex)

	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab2Btn1",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab2Btn2",false)

	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn1",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn2",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn3",false)

	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn1",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn2",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn3",false)
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn4",false)


	if tabsIndex==4 then
		if self.resourceType==resourceTypeTab.Gold_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn1",true)
		elseif self.resourceType==resourceTypeTab.Oil_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn2",true)
		elseif self.resourceType==resourceTypeTab.Steel_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn3",true)
		elseif self.resourceType==resourceTypeTab.RareEarths_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab4Btn4",true)
		end 

	elseif tabsIndex ==3 then
		if self.resourceType==resourceTypeTab.Gold_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn1",true)
		elseif self.resourceType==resourceTypeTab.Oil_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn2",true)
		elseif self.resourceType==resourceTypeTab.Steel_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab3Btn3",true)
		end

	elseif tabsIndex ==2 then
		if self.resourceType==resourceTypeTab.Gold_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab2Btn1",true)
		elseif self.resourceType==resourceTypeTab.Oil_functionBlock then
			UIExtend.setCCControlButtonSelected(self.ccbfile,"mTab2Btn2",true)
		end
	end 

end


function RAReposityPage:refreshCurrType(resourceType)
	self.resourceType = resourceType
end
function RAReposityPage:checkShowTabs()
	local world_map_const_conf = RARequire("world_map_const_conf")
	local stepCityLevel2=world_map_const_conf["stepCityLevel2"]
	local arr=RAStringUtil:split(stepCityLevel2.value,"_") 

	--获取大本的等级
	local level =RABuildManager:getMainCityLvl()

	if level>=tonumber(arr[2]) then
		self.tabCount = 4
		self:setShowTabs(self.tabCount)
		self:setSelectedBtn(self.tabCount)
		return 
	end

	if level>=tonumber(arr[1]) then
		self.tabCount = 3
		self:setShowTabs(self.tabCount)
		self:setSelectedBtn(self.tabCount)
		return 
	end 
	self.tabCount = 2
	self:setShowTabs(self.tabCount)
	self:setSelectedBtn(self.tabCount)
end

function RAReposityPage:setShowTabs(count)
	
	UIExtend.setNodeVisible(self.ccbfile,"mTab2Node",false)
	UIExtend.setNodeVisible(self.ccbfile,"mTab3Node",false)
	UIExtend.setNodeVisible(self.ccbfile,"mTab4Node",false)
	if count==2 then
		UIExtend.setNodeVisible(self.ccbfile,"mTab2Node",true)
	elseif count==3 then
		UIExtend.setNodeVisible(self.ccbfile,"mTab3Node",true)
	elseif count==4 then
		UIExtend.setNodeVisible(self.ccbfile,"mTab4Node",true)
	end 
end

function RAReposityPage:initTitle()


	--tab title
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab2Btn1",_RALang("@ResName1007"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab2Btn2",_RALang("@ResName1008"),true)

	UIExtend.setControlButtonTitle(self.ccbfile,"mTab3Btn1",_RALang("@ResName1007"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab3Btn2",_RALang("@ResName1008"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab3Btn3",_RALang("@ResName1009"),true)

	UIExtend.setControlButtonTitle(self.ccbfile,"mTab4Btn1",_RALang("@ResName1007"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab4Btn2",_RALang("@ResName1008"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab4Btn3",_RALang("@ResName1009"),true)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTab4Btn4",_RALang("@ResName1010"),true)

end
function RAReposityPage:init()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")

	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
	-- local diamondCallBack = function()
	--     local RARealPayManager = RARequire('RARealPayManager')
	--     RARealPayManager:getRechargeInfo()
	-- end

    local titleName = _RALang("@Resources")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAReposityPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
	titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds)

	self.mListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mResListView")
	self:initTitle()
	self:checkShowTabs()

end

function RAReposityPage:getRepositoryUseItemDataByType(functionBlock)
    local item_conf = RARequire("item_conf")
    local baseLevel  =RABuildManager:getMainCityLvl()
   
    for k,item in pairs(item_conf) do
        if functionBlock == item.functionBlock and baseLevel >= item.levelLimit then
            if item.isSellable ~= 1 then
                local count = RACoreDataManager:getItemCountByItemId(item.id)
                if count > 0 then
                    self.resItemDatas[#self.resItemDatas + 1] = item
                end
            else
                self.resItemDatas[#self.resItemDatas + 1] = item
            end
        end
    end

    --按order从小到大排
    table.sort(self.resItemDatas,function (v1,v2)
		return v1.order< v2.order
	end)
  
end


function RAReposityPage:updateInfo(resourceType)
  	self.mListSV:removeAllCell()
  	self:clearItemDatas()
  	self:getRepositoryUseItemDataByType(resourceType)

  	-- --diamonds
  	-- local num=RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
  	-- UIExtend.setCCLabelString(self.titleCCB,"mDiamondsNum",num)
    

	local scrollview = self.mListSV

	for k,v in ipairs(self.resItemDatas) do
		local itemData=v
		local cell = CCBFileCell:create()
	    local panel = RAReposityPageCell:new({
				data = itemData,
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAResourceCell.ccbi")
		scrollview:addCellBack(cell)
	end

	scrollview:orderCCBFileCells(scrollview:getViewSize().width)

end

function RAReposityPage:onTab2Btn1()

	if self.resourceType ==resourceTypeTab.Gold_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Gold_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Gold_functionBlock)
end
function RAReposityPage:onTab2Btn2()
	if self.resourceType ==resourceTypeTab.Oil_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Oil_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Oil_functionBlock)
end
function RAReposityPage:onTab3Btn1()
	if self.resourceType ==resourceTypeTab.Gold_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Gold_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Gold_functionBlock)
end
function RAReposityPage:onTab3Btn2()
	if self.resourceType ==resourceTypeTab.Oil_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Oil_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Oil_functionBlock)
end
function RAReposityPage:onTab3Btn3()
	if self.resourceType ==resourceTypeTab.Steel_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Steel_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Steel_functionBlock)
end

function RAReposityPage:onTab4Btn1()
	if self.resourceType ==resourceTypeTab.Gold_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Gold_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Gold_functionBlock)
end
function RAReposityPage:onTab4Btn2()
	if self.resourceType ==resourceTypeTab.Oil_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Oil_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Oil_functionBlock)
end
function RAReposityPage:onTab4Btn3()
	if self.resourceType ==resourceTypeTab.Steel_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.Steel_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.Steel_functionBlock)
end
function RAReposityPage:onTab4Btn4()
	if self.resourceType ==resourceTypeTab.RareEarths_functionBlock then
		self:setSelectedBtn(self.tabCount)
		return 
	end
	self:refreshCurrType(resourceTypeTab.RareEarths_functionBlock)
	self:setSelectedBtn(self.tabCount)
	self:updateInfo(resourceTypeTab.RareEarths_functionBlock)
end


function RAReposityPage:clearItemDatas()

	if self.resItemDatas then
		for k,v in ipairs(self.resItemDatas) do
			v=nil
		end
	end 
    self.resItemDatas = {}
end
function RAReposityPage:Exit()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAReposityPage")
	self:removeMessageHandler()
	self.mListSV:removeAllCell()
	self:clearItemDatas()
	self.resItemDatas=nil
end


--endregion
