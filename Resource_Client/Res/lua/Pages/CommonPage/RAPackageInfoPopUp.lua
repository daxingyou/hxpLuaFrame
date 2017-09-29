--[[道具使用二级面板]]

RARequire("BasePage")
RARequire('MessageManager')
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStoreManager = RARequire("RAStoreManager")
local RAPackageManager = RARequire("RAPackageManager")
local RAPackageData = RARequire("RAPackageData")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAGameType = RARequire('RAGameType') 
local RAStringUtil = RARequire("RAStringUtil")


local RAPackageInfoPopUp = BaseFunctionPage:new(...)

function RAPackageInfoPopUp:resetData()
end

local OnReceiveMessage = function(message)
	if message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAPackageInfoPopUp' then 
            RAPackageInfoPopUp:setEditBoxVisible(true)
        else
            RAPackageInfoPopUp:setEditBoxVisible(false)
        end 
    end 
end


function RAPackageInfoPopUp:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("RAPackageInfoPopUp.ccbi", RAPackageInfoPopUp)
	self.ccbfile  = ccbfile
	self.data     = data

	self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editBox == nil or self.editBox:isKeyboardShow() == false then
            RARootManager.ClosePage("RAPackageInfoPopUp")
        end 
    end

    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,OnReceiveMessage)
	RAPackageInfoPopUp:initUI()
end


function RAPackageInfoPopUp:sliderBegan( sliderNode )
end

function RAPackageInfoPopUp:sliderMoved( sliderNode )
	self:refreshSliderValue()
end

function RAPackageInfoPopUp:sliderEnded( sliderNode )
	self:refreshSliderValue()
end


function RAPackageInfoPopUp:initUI()
    RAPackageInfoPopUp:refreshUIData()
    self:initCurrentItemCount()

    --滑动条和数字处理
    if RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse  == self.data.optionType then
    	if RAPackageData.PACKAGE_CAN_USE.cannot == self.data.use then
    		self:setSliderAndNumVisible(false)
    	elseif RAPackageData.PACKAGE_CAN_ALL_USE.cannot == self.data.useAll then
    		self:setSliderAndNumVisible(false)
    	elseif self.data.count == 1 then
    		self:setSliderAndNumVisible(false)
    	else
    		self:initSliderBar()
    	end
    elseif RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy  == self.data.optionType then
    	self:initSliderBar()
    elseif RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy  == self.data.optionType then
    	self:setSliderAndNumVisible(false)
    end	

    --底部按钮处理
    if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse then
    	if RAPackageData.PACKAGE_CAN_USE.cannot == self.data.use then
    		UIExtend.setNodeVisible(self.ccbfile,"mUseBtnNode",false)
    		UIExtend.setNodeVisible(self.ccbfile,"mConfirmBtnNode",true)
    	else
    		UIExtend.setNodeVisible(self.ccbfile,"mUseBtnNode",true)
    		UIExtend.setNodeVisible(self.ccbfile,"mConfirmBtnNode",false)
    	end
		UIExtend.setNodeVisible(self.ccbfile,"mBuyBtnNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mNeedDiamondsNumNode",false)
		UIExtend.setCCLabelString(self.ccbfile, "mItemTitle", _RALang("@itemUse"))
	elseif self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy or self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy then 
		UIExtend.setNodeVisible(self.ccbfile,"mUseBtnNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mConfirmBtnNode",false)--不能使用的确认按钮
		UIExtend.setNodeVisible(self.ccbfile,"mBuyBtnNode",true)
		UIExtend.setNodeVisible(self.ccbfile,"mNeedDiamondsNumNode",true)
		self:setItemPrice()
		UIExtend.setCCLabelString(self.ccbfile, "mItemTitle", _RALang("@itemBuy"))
		self:refreshCostDiamondNum()
	end
end

function RAPackageInfoPopUp:getNowPrice()
	local price = 0
	if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy then
		price = self.data.price
	elseif self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy then
		price = self.data.salePrice
	end
	return price
end

function RAPackageInfoPopUp:setItemPrice()
	local price = self:getNowPrice()
	UIExtend.setCCLabelString(self.ccbfile,"mItemNum", price)
end

function RAPackageInfoPopUp:setSliderAndNumVisible( isV )
	UIExtend.setNodeVisible(self.ccbfile,"mSliderNode",isV)
    UIExtend.setNodeVisible(self.ccbfile,"mSliderNumNode",isV)
end

function RAPackageInfoPopUp:initSliderBar()
	UIExtend.setNodeVisible(self.ccbfile,"mSliderNode",true)
    UIExtend.setNodeVisible(self.ccbfile,"mSliderNumNode",true)
	local controlSlider = UIExtend.getControlSlider("mBarNode", self.ccbfile, true)
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
  	UIExtend.setNodeVisible(self.ccbfile,"mBottomNode",true)

    self:createEditBox()
    self:initControlSliderProp()
end

--当前拥有
function RAPackageInfoPopUp:initCurrentItemCount()
	local itemCount = 0
	local add = '+'
	if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse then
		itemCount = self.data.count
		add = '-'
	elseif self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy or self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy then
		itemCount = RACoreDataManager:getItemCountByItemId(self.data.id)
	end
	UIExtend.setCCLabelString(self.ccbfile,"mAddLabel", add)
	UIExtend.setCCLabelString(self.ccbfile,"mItemCurrentNum", _RALang("@itemCurrentCount")..itemCount)
end

function RAPackageInfoPopUp:refreshUIData()
	local data = self.data
	RAPackageData.setNameLabelStringAndColor(self.ccbfile, "mItemName", data)--物品名称
	RAPackageData.addBgAndPicToItemGrid( self.ccbfile, "mIconNode", data )--icon
	UIExtend.setCCLabelString(self.ccbfile,"mItemExplain", _RALang(data.item_des))--物品描述
end

function RAPackageInfoPopUp:initControlSliderProp()
	self.controlSlider:setMinimumValue(1)
	local maxNum
    if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse then
		maxNum = self.data.count
	elseif self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy then 
		--商店购买的,应该有算法计算最大值。1.当前钻石能购买的最大数；2.最大值为99；3.99减去背包对应数量
		maxNum = self:getShopCanBuyMaxCount()
		if maxNum == 1 then
			self.controlSlider:setMinimumValue(0)
		end
	end

	self.controlSlider:setMaximumValue(maxNum)
	self.controlSlider:setValue(1)
	self.editBox:setText(1)
	self:refreshCostDiamondNum()
end

--获取当前商店能买的最大值
--商店购买的,应该有算法计算最大值。
--1.当前钻石能购买的最大数；2.最大值为99；3.99减去背包对应数量
function RAPackageInfoPopUp:getShopCanBuyMaxCount()
	-- body
	local maxCount = 99
	local currDiamond = RAPlayerInfoManager.getPlayerBasicInfo().gold
	local itemPrice   = self.data.price
	local canBuyCount = math.floor(currDiamond/itemPrice)

	local returnCount = maxCount
	if canBuyCount < maxCount then
		returnCount = canBuyCount
	end

	if returnCount == 0 then
		returnCount = 1
	end

	return returnCount
end

--滑动完滑条
function RAPackageInfoPopUp:refreshSliderValue()
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	self.controlSlider:setValue(value)

	self.editBox:setText(value)
	self:refreshCostDiamondNum()
end

--减按钮事件
function RAPackageInfoPopUp:onSubBtn()
	local value = self.controlSlider:getValue()
	value = tonumber(value-1)
	self.controlSlider:setValue(value)
	self.editBox:setText(self.controlSlider:getValue())
	self:refreshCostDiamondNum()
end

--加按钮事件
function RAPackageInfoPopUp:onAddBtn()
	local value = self.controlSlider:getValue()
	value = tonumber(value+1)
	self.controlSlider:setValue(value)
	self.editBox:setText(self.controlSlider:getValue())
	self:refreshCostDiamondNum()
end

--输入文字按钮
function RAPackageInfoPopUp:onInputNumBtn()
	
end

local function editboxEventHandler(eventType, node)
    if eventType == "began" then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == "changed" then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == "ended" then
        -- triggered when the edit box text was changed.
    elseif eventType == "return" then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
        RAPackageInfoPopUp:updateSliderNum()
    end
end

function RAPackageInfoPopUp:updateSliderNum()
	local value = self.editBox:getText()
	if value == '' then 
		value = 0
	end 
	value = math.ceil(value)
	if value < self.controlSlider:getMinimumValue() then
		value = self.controlSlider:getMinimumValue()
	elseif value>self.controlSlider:getMaximumValue() then
		value=self.controlSlider:getMaximumValue()
	end
	self.editBox:setText(value)
	self.controlSlider:setValue(value)
	self:refreshCostDiamondNum()
end

function RAPackageInfoPopUp:createEditBox()
	--self.editBox = UIExtend.createEditBox(self.editBox, self.ccbfile, "mSliderNum", "mSliderNumBG", "mSliderNumNode", editboxEventHandler)
	local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mSliderNumNode")
	local inputMode=kEditBoxInputModeNumeric
	self.editBox = UIExtend.createEditBox(self.ccbfile,"mSliderNumBG",inputNode,editboxEventHandler,nil,nil,inputMode,16,nil,ccc3(255,255,255))
	self.editBox:setMaxLength(5)
end

function RAPackageInfoPopUp:refreshCostDiamondNum()
	if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse then
		return
	end

	local num = 0
	local value = 1
	if nil ~= self.controlSlider then
		value = self.controlSlider:getValue()
	end
	local price = self:getNowPrice()
	num = tonumber(value) * tonumber(price)
	self.totalCost = num
	UIExtend.setCCLabelString(self.ccbfile,"mBuyDiamondsNum", num)
end

function RAPackageInfoPopUp:getSliderValue()
	local value = 1
	if nil ~= self.controlSlider then
		value = self.controlSlider:getValue()
	end
	return value
end

local function onUseConfirmCallBack(isConfirm)
    if not isConfirm then
    	return
    end
    RAPackageInfoPopUp:sendUseItemHandler()
end

--发送使用道具消息
function RAPackageInfoPopUp:sendUseItemHandler()
	RAPackageManager:dealwithPkgSVOffset()
	local value = self:getSliderValue()
	--默认使用itemid进行消耗道具
	local useItem=true
	local id=nil
	--若明确指明使用uuid则使用uuid进行消耗使用道具
	--默认配置是可以提供并得到itemid的
	if self.data.useUUID~=nil and self.data.useUUID then
		useItem=false
		id=self.data.uuid
	else
		id=self.data.id
	end	

	--道具id获取失败报错
	if id~=nil then
		if useItem then
			RAPackageManager:sendUseItemByItemId(id, value)
		else
			RAPackageManager:sendUseItemByUUID(id, value)
		end	
	else	
		RARootManager.ShowMsgBox('@PackageConsumeIdError')
	end

	RARootManager.CloseCurrPage()
end

--使用状态类道具特殊处理
function RAPackageInfoPopUp:useStatusItemHandler(data,callFunc)
	local buff_conf = RARequire("buff_conf")
	local RABuffManager = RARequire('RABuffManager')
	local buffId = data.buffId
	local effectId, effectValue = buff_conf[buffId].effect, buff_conf[buffId].value
	local playerEffectValue = RABuffManager:getBuffValue(effectId)

	--如果我正在出征，不能使用免战道具
	local RAMarchDataManager = RARequire("RAMarchDataManager")
	if effectId == RAPackageData.EFFECT_ID_TYPE.avoidWar and RAMarchDataManager:HasMarchForBattle() then
		local confirmData = {labelText = _RALang("@AvoidWarUnUse"), title=_RALang("@useConfirm"), yesNoBtn=false}
    	RARootManager.showConfirmMsg(confirmData)
		return
	end

    local onConfirmCallBack
    if callFunc then
        onConfirmCallBack = callFunc
    else
        onConfirmCallBack = onUseConfirmCallBack
    end

	if playerEffectValue == effectValue or playerEffectValue == 0 then -- 同一种作用号,直接使用，（叠加效果）
        if callFunc then
		    callFunc(true)
        else
            self:sendUseItemHandler()
        end
	elseif playerEffectValue > effectValue then --已有高等级效果后再使用低等级效果道具，提示无法使用
		local confirmData = 
		{
			labelText = _RALang("@unUse"),
			title =_RALang("@useConfirm"),
			yesNoBtn = true,
			resultFun = onConfirmCallBack
		}
    	RARootManager.showConfirmMsg(confirmData)
	else
		--todo 不同种作用号，提示是否要使用（替换原有作用号）
		--@buffMutex       使用该道具会覆盖您当前的状态，是否确定使用？
		local confirmData = {labelText = _RALang("@buffMutex"), title=_RALang("@useConfirm"), yesNoBtn=true, resultFun=onConfirmCallBack}
    	RARootManager.showConfirmMsg(confirmData)
	end
end

--点击最底部操作按钮
function RAPackageInfoPopUp:onUseBtn()
	
	if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse then
        if self.data.item_type == RAPackageManager.ItemType.Horn then --为喇叭
            local RAChatUIPage = RARequire('RAChatUIPage')
            RAChatUIPage.isUseHorn = true
            RARootManager.ClosePage("RAPackageInfoPopUp")
			RARootManager.OpenPage("RAChatUIPage")
            return
        end
		if self.data.item_type == RAPackageManager.ItemType.WorldType then -- 随机迁城
			local RAWorldManager = RARequire('RAWorldManager')
			RAWorldManager:RandomMigrate()
			return
		end
		if self.data.item_type == RAPackageManager.ItemType.StateType then--状态类道具
			self:useStatusItemHandler(self.data)
		    return
		end
		if self.data.item_type == RAPackageManager.ItemType.ResourceType then--资源类道具
			self:sendUseItemHandler()
		    return
		end
		if self.data.item_type == RAPackageManager.ItemType.ChangeNameType then --改名卡
			RARootManager.ClosePage("RAPackageInfoPopUp",true)
			RARootManager.OpenPage("RALordChangeNamePage",nil,false,false)
			return
		end
		if self.data.item_type == RAPackageManager.ItemType.ChangeStyleType then --改形象卡
			RARootManager.ClosePage("RAPackageInfoPopUp")
			RARootManager.OpenPage("RALordHeadChangePage", nil,false,true)
			return
		end
		if self.data.item_type == RAPackageManager.ItemType.ResetLordSkillType then --重置天赋
			RARootManager.ClosePage("RAPackageInfoPopUp")
			--RARootManager.OpenPage("RATalentMainPage", nil,false,true,false)
			RARootManager.OpenPage("RATalentSysMainPage", nil,false,true,false)
			return
		end

		local value = self:getSliderValue()
		local item = _RALang(self.data.item_name)
		local final = string.gsub(item, "%%", "%%%%")
		local tipStr = RAStringUtil:getLanguageString("@useConfirmDes",final , value)
		local confirmData = {labelText = tipStr, title=_RALang("@useConfirm"), yesNoBtn=true, resultFun=onUseConfirmCallBack}
    	RARootManager.showConfirmMsg(confirmData)
	end
end

local onBuyConfirmCallBack = function (isConfirm)
    if not isConfirm then
    	return
    end
    local value = RAPackageInfoPopUp:getSliderValue()

    RAPackageManager.mHasOpenedPkgTab = false
	RAStoreManager:sendBuyItem(RAPackageInfoPopUp.data.shopId, value)
	RARootManager.CloseCurrPage()
end

function onHotBuyConfirmCallBack(isConfirm)
    if not isConfirm then
    	return
    end

    RAPackageManager.mHasOpenedPkgTab = false
    RAStoreManager:sendDiscountedSelling(RAPackageInfoPopUp.data.salesId)
    RARootManager.CloseCurrPage()
end

function RAPackageInfoPopUp:onBuyBtn()
	
	if self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy then
		local value = self:getSliderValue()
		if value == 0 then
			return
		end
		local name  = _RALang(self.data.item_name)
		local final = string.gsub(name, "%%", "%%%%")
		-- local tipStr = RAStringUtil:getLanguageString("@buyConfirmDes", final, value)
		-- local confirmData = {labelText = tipStr, title=_RALang("@buyConfirm"), yesNoBtn=true, resultFun=onBuyConfirmCallBack}
  --   	RARootManager.showConfirmMsg(confirmData)

	    local RAConfirmManager = RARequire("RAConfirmManager")
	    local confirmData = {}
	    confirmData.final = final
	    confirmData.value = value
	    confirmData.type=RAConfirmManager.TYPE.BUYNOW
	    confirmData.costDiamonds = self.totalCost
	    confirmData.resultFun =onBuyConfirmCallBack
	    RARootManager:showDiamondsConfrimDlg(confirmData)

	elseif self.data.optionType == RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy then --打折物品购买
		local Utilitys = RARequire("Utilitys")
		local name  = _RALang(self.data.item_name)
		local final = string.gsub(name, "%%", "%%%%")
		local value = tostring(1)
		-- local tipStr = RAStringUtil:getLanguageString("@buyConfirmDes", final, value)
		-- local confirmData = {labelText = tipStr, title=_RALang("@buyConfirm"), yesNoBtn=true, resultFun=onHotBuyConfirmCallBack}
  --   	RARootManager.showConfirmMsg(confirmData)

     	local RAConfirmManager = RARequire("RAConfirmManager")
        local confirmData = {}
	    confirmData.final = final
	    confirmData.value = value
	    confirmData.type=RAConfirmManager.TYPE.BUYNOW
	    confirmData.costDiamonds = self.totalCost
	    confirmData.resultFun =onHotBuyConfirmCallBack
	    RARootManager:showDiamondsConfrimDlg(confirmData)

	end
end

--不能使用的确认按钮
function RAPackageInfoPopUp:onConfirmBtns()
	RARootManager.ClosePage("RAPackageInfoPopUp")
end

function RAPackageInfoPopUp:onClose()
    CCLuaLog("RAPackageInfoPopUp:onClose")
    RARootManager.ClosePage("RAPackageInfoPopUp")
end

function RAPackageInfoPopUp:setEditBoxVisible(visible)
    if self.editBox ~= nil then 
        self.editBox:setVisible(visible)
    end 
end

function RAPackageInfoPopUp:Exit()
	if nil ~= self.controlSlider then
		self.controlSlider:removeFromParentAndCleanup(true)
	    self.controlSlider = nil
	end
	if nil ~= self.editBox then
		self.editBox:removeFromParentAndCleanup(true)
		self.editBox = nil
	end
	MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
    UIExtend.unLoadCCBFile(RAPackageInfoPopUp)
end

return RAPackageInfoPopUp