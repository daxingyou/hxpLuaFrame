--联盟商店页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local HP_pb = RARequire('HP_pb')
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local RAPackageData = RARequire('RAPackageData')
local RARootManager = RARequire('RARootManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAAllianceBuyPage = class('RAAllianceBuyPage',RAAllianceBasePage)
local Utilitys = RARequire('Utilitys')
local item_conf = RARequire('item_conf')
local localPage = nil 
local RAStringUtil  = RARequire('RAStringUtil')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local GuildManager_pb = RARequire('GuildManager_pb')

function RAAllianceBuyPage:ctor(...)
    self.ccbfileName = "RAAllianceShopInfoPopUp.ccbi"
end

function RAAllianceBuyPage:sliderBegan( sliderNode )
end

function RAAllianceBuyPage:sliderMoved( sliderNode )
    self:refreshSliderValue()
end

function RAAllianceBuyPage:sliderEnded( sliderNode )
    self:refreshSliderValue()
end

function RAAllianceBuyPage:init(data)
	self.info = data
    localPage = self
    local itemData = item_conf[self.info.itemId]
    RAPackageData.setNameLabelStringAndColor(self.ccbfile, "mItemName", itemData)--物品名称
    RAPackageData.addBgAndPicToItemGrid( self.ccbfile, "mIconNode", itemData )--icon
    UIExtend.setCCLabelString(self.ccbfile,"mItemExplain", _RALang(itemData.item_des))--物品描述
    self.itemData = itemData
    --当前拥有
    local itemCount = RACoreDataManager:getItemCountByItemId(self.info.itemId)
    UIExtend.setCCLabelString(self.ccbfile,"mItemCurrentNum", _RALang("@itemCurrentCount")..itemCount)

    UIExtend.setCCLabelString(self.ccbfile, "mItemTitle", _RALang("@itemBuy"))

    UIExtend.setCCLabelString(self.ccbfile,"mItemNum", self.info.price)

    self:initSliderBar()
end 

function RAAllianceBuyPage:initSliderBar()
    UIExtend.setNodeVisible(self.ccbfile,"mSliderNode",true)
    UIExtend.setNodeVisible(self.ccbfile,"mSliderNumNode",true)
    local controlSlider = UIExtend.getControlSlider("mBarNode", self.ccbfile, true)
    controlSlider:registerScriptSliderHandler(self)
    self.controlSlider = controlSlider
    UIExtend.setNodeVisible(self.ccbfile,"mBottomNode",true)

    self:createEditBox()
    self:initControlSliderProp()
end

function RAAllianceBuyPage:initControlSliderProp()
    self.controlSlider:setMinimumValue(1)
    local maxNum

    maxNum = self:getShopCanBuyMaxCount()
    -- if maxNum == 1 then
    --     self.controlSlider:setMinimumValue(1)
    -- end

    self.controlSlider:setMaximumValue(maxNum)
    self.controlSlider:setValue(1)
    self.editBox:setText(1)
    self:refreshCostDiamondNum()
end

--减按钮事件
function RAAllianceBuyPage:onSubBtn()
    local value = self.controlSlider:getValue()
    value = tonumber(value-1)
    if value <= 0 then 
        value = 1
    end 
    self.controlSlider:setValue(value)
    self.editBox:setText(self.controlSlider:getValue())
    self:refreshCostDiamondNum()
end

--加按钮事件
function RAAllianceBuyPage:onAddBtn()
    local value = self.controlSlider:getValue()
    value = tonumber(value+1)
    self.controlSlider:setValue(value)
    self.editBox:setText(self.controlSlider:getValue())
    self:refreshCostDiamondNum()
end

function RAAllianceBuyPage:getShopCanBuyMaxCount()
    -- body
    local maxCount = 99
    local currDiamond = self.info.contribution
    local itemPrice   = self.info.price
    local canBuyCount = math.floor(currDiamond/itemPrice)


    local returnCount
    if self.info.rare == GuildManager_pb.PERMANENT then 
       returnCount = canBuyCount
    else
        returnCount = self.info.count
    end

    if canBuyCount < returnCount then
        returnCount = canBuyCount
    end

    if returnCount == 0 then
        returnCount = 1
    end

    return returnCount
end

local onBuyConfirmCallBack = function (isConfirm)
    if not isConfirm then
        return
    end
    local value = localPage:getSliderValue()
    RAAllianceProtoManager:buyItem(localPage.info.itemId,value)
    RARootManager.CloseCurrPage()
end

function RAAllianceBuyPage:refreshCostDiamondNum()

    local num = 0
    local value = 1
    if nil ~= self.controlSlider then
        value = self.controlSlider:getValue()
    end
    local price = self.info.price
    num = tonumber(value) * tonumber(price)
    UIExtend.setCCLabelString(self.ccbfile,"mBuyDiamondsNum", num)
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
        localPage:updateSliderNum()
    end
end

function RAAllianceBuyPage:getSliderValue()
    local value = 1
    if nil ~= self.controlSlider then
        value = self.controlSlider:getValue()
    end
    return value
end

--点击最底部操作按钮
function RAAllianceBuyPage:onBuyBtn()
    
    local value = self:getSliderValue()
    if value == 0 then
        return
    end
    local name  = _RALang(self.itemData.item_name)
    local final = string.gsub(name, "%%", "%%%%")
    local tipStr = RAStringUtil:getLanguageString("@buyConfirmDes", final, value)
    local confirmData = {labelText = tipStr, title=_RALang("@buyConfirm"), yesNoBtn=true, resultFun=onBuyConfirmCallBack}
    RARootManager.showConfirmMsg(confirmData)
end

function RAAllianceBuyPage:updateSliderNum()
    local value = self.editBox:getText()
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

function RAAllianceBuyPage:createEditBox()

    self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editBox:isKeyboardShow() == true then
        else
            RARootManager.ClosePage("RAAllianceBuyPage")
        end
    end

    
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mSliderNumNode")
    local inputMode=kEditBoxInputModeNumeric
    self.editBox = UIExtend.createEditBox(self.ccbfile,"mSliderNumBG",inputNode,editboxEventHandler,nil,nil,inputMode,24,nil,ccc3(255,255,255))
    self.editBox:setIsShowTTF(true)
end

--滑动完滑条
function RAAllianceBuyPage:refreshSliderValue()
    local value = self.controlSlider:getValue()
    value = math.ceil(value)
    self.controlSlider:setValue(value)

    self.editBox:setText(value)
    self:refreshCostDiamondNum()
end

function RAAllianceBuyPage:onClose()
    CCLuaLog("RAAllianceBuyPage:onClose")
    RARootManager.ClosePage("RAAllianceBuyPage")
end

--初始化顶部
function RAAllianceBuyPage:initTitle()
end

function RAAllianceBuyPage:release()
    if self.editBox then
        self.editBox:removeFromParentAndCleanup(true)
        self.editBox = nil
    end
    if self.controlSlider then
        self.controlSlider:unregisterScriptSliderHandler()
        self.controlSlider = nil
    end
end


return RAAllianceBuyPage.new()