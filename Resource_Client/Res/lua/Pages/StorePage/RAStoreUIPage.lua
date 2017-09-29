--商城界面

local UIExtend         = RARequire("UIExtend")
local RAStoreUICellItemPage = RARequire("RAStoreUICellItemPage")
local RAStoreManager   = RARequire("RAStoreManager")
local RARootManager = RARequire("RARootManager")
local RAPackageData      = RARequire("RAPackageData")
local shop_conf = RARequire("shop_conf")
local shopsale_conf = RARequire("shopsale_conf")
local item_conf = RARequire("item_conf")
local itemtips_conf = RARequire("itemtips_conf")
local Utilitys = RARequire("Utilitys")
local RABuildManager = RARequire('RABuildManager')


RARequire("MessageDefine")
RARequire("MessageManager")

local RAStoreUIPage  = BaseFunctionPage:new(...)
local p_ramdomIndex = 0

function RAStoreUIPage:Enter(data)

	CCLuaLog("RAStoreUIPage:Enter")
	--local ccbfile = UIExtend.loadCCBFile("RAPackageTabStore.ccbi", RAStoreUIPage)
	local ccbfile = UIExtend.loadCCBFile("RAPackageTabPkgNew.ccbi", RAStoreUIPage)
	self.ccbfile  = ccbfile
    self:registerMessage()
	self:init()
    self.MsgString = ""
end

function RAStoreUIPage:Exit()
    --for k,v in pairs(self.svVec) do
        --v:removeAllCell()

    --end
    self.scrollView:removeAllCell()

    RAStoreManager:setChoosenTab(RAPackageData.STORE_CHOOSEN_TAB.allTab)
    RAStoreManager.isRefreshVec = {}
    self:removeMessageHandler()
    self.ccbfile:stopAllActions()
    UIExtend.unLoadCCBFile(self)
end

--------------------------------------------------------------
-----------------------初始化---------------------------------
--------------------------------------------------------------

--初始化ui
function RAStoreUIPage:init()
    --self.svVec  = {}
    --self.btnVec = {}

    -- local svNameVec = {"mAllListSV", "mResourcesListSV", "mAccelerateListSV", "mSpecialListSV", "mEquipListSV"}
    -- for i=1,#svNameVec do
    --     self.svVec[i] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, svNameVec[i])
    -- end
    
    -- local btnNameVec = {"mAllBtn", "mAccelerateBtn", "mConditionBtn", "mResourcesBtn", "mSpecialBtn"}
    -- for i=1,#btnNameVec do
    -- 	self.btnVec[i] = UIExtend.getCCControlButtonFromCCB(self.ccbfile, btnNameVec[i])
    -- end

    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mStoreListSV")
    self.btnVec = {}
    local btnNameVec = {"mAllBtn", "mAccelerateBtn", "mConditionBtn", "mResourcesBtn", "mSpecialBtn"}
    for i=1,#btnNameVec do
        self.btnVec[i] = UIExtend.getCCControlButtonFromCCB(self.ccbfile, btnNameVec[i])
    end

    self.higtLight = {}
    local btnNameVec = {"mAllBtn", "mAccelerateBtn", "mConditionBtn", "mResourcesBtn", "mSpecialBtn"}
    for i=1,#btnNameVec do
    	self.btnVec[i] = UIExtend.getCCControlButtonFromCCB(self.ccbfile, btnNameVec[i])
    end

    
    local mbtnlis = {"mTabBtnLabel1","mTabBtnLabel2","mTabBtnLabel3","mTabBtnLabel4","mTabBtnLabel5"}
    for i,v in pairs(mbtnlis) do
        local tmp = UIExtend.getCCSpriteFromCCB(self.ccbfile, mbtnlis[i])
        self.higtLight[i] = tmp
    end 
    self:changeTabHandler(RAStoreManager:getChoosenTab())
    --self:updateDiscountedSelling()
    self:initPkgTips()
    --self:initSchedule()

    --刷新配置数据
    RAStoreManager:updateConfigData()
    self:refreshChoosenTabPro()
end

--更新化打折商品
function RAStoreUIPage:updateDiscountedSelling()
    local sellingData = RAStoreManager.mDiscountedSellingData
    if sellingData.salesId == nil then
        return
    end

    local dataTable = shopsale_conf[sellingData.salesId]
    local shopData  = shop_conf[dataTable.shopId]
    local itemData  = item_conf[shopData.shopItemID]
   
    RAPackageData.addBgAndPicToItemGrid( self.ccbfile, "mLimitItemIconNode", itemData ) --物品icon
    UIExtend.setCCLabelString(self.ccbfile,"mHotTex", _RALang("@shopnew"))--hot
    UIExtend.setNodeVisible(self.ccbfile, "mLimitItemNum", false)--物品数量 
    UIExtend.setCCLabelString(self.ccbfile,"mOriginalPrice", shopData.price)--原价 
    UIExtend.setCCLabelString(self.ccbfile,"mSalePrice", dataTable.salePrice)--现价 
    RAPackageData.setNumTypeInItemIcon( self.ccbfile, "mItemHaveNum", "mItemHaveNumNode", itemData )--显示数字类型
    UIExtend.setNodeVisible(self.ccbfile, "mBoughtPic", sellingData.isAlreadyBuy)
    self:updateDiscountedSellingEndTime()--倒计时
end

function RAStoreUIPage:initPkgTips()
    self:randomUpdatePkgTips()
    local scheduleUpdateFun = function()
        self:randomUpdatePkgTips()
    end
    self.ccbfile:stopAllActions()
    schedule(self.ccbfile,scheduleUpdateFun, 10)    
end

function RAStoreUIPage:initSchedule()
    local scheduleUpdateFun = function()
        if p_ramdomIndex >= 10 then
            self:randomUpdatePkgTips()
            p_ramdomIndex = 0
        end
        self:updateDiscountedSellingEndTime()
        p_ramdomIndex = p_ramdomIndex + 1
    end

    self.ccbfile:stopAllActions()
    schedule(self.ccbfile, scheduleUpdateFun, 1)
end

--------------------------------------------------------------
-----------------------刷新数据-------------------------------
--------------------------------------------------------------

--随机设置tips
function RAStoreUIPage:randomUpdatePkgTips()
    local randomLen = #itemtips_conf
    local ra = math.random(1, randomLen)
    local tipsStr = itemtips_conf[ra]
    UIExtend.setCCLabelString(self.ccbfile,"mPackageTipsLabel", _RALang(tipsStr.tips))
end

--打折商品倒计时
function RAStoreUIPage:updateDiscountedSellingEndTime()
    local sellingData = RAStoreManager.mDiscountedSellingData
    if sellingData.endTime~=nil then
        local endTime  = tonumber(sellingData.endTime)/1000
        local remainTime  = Utilitys.getCurDiffTime(endTime)
        local tmpStr      = Utilitys.createTimeWithFormat(remainTime)
        UIExtend.setCCLabelString(self.ccbfile,"mTimeLeftNum", tmpStr) --剩余时间 
    end
end

function RAStoreUIPage:updateVisible(isVisible)
    self.ccbfile:setVisible(isVisible)
end

--刷新选中属性
function RAStoreUIPage:refreshChoosenTabPro()
    self:refreshTabPro(RAStoreManager:getChoosenTab())
end

--刷新物品，（如果刷新过了就不用再刷）
function RAStoreUIPage:refreshTabPro( tabIndex )
    self:changeTabHandler(tabIndex)
    -- local x, y = self.svVec[tabIndex]:getPositionX(), self.svVec[tabIndex]:getPositionY()
    -- local isv = self.svVec[tabIndex]:isVisible()
    -- if RAStoreManager.isRefreshVec[tabIndex] ~= nil and RAStoreManager.isRefreshVec[tabIndex] then
    --     return
    -- end

    RAStoreManager.isRefreshVec[tabIndex] = true
    local data = RAStoreManager:getDataByTab(tabIndex)
    --RAStoreUIPage:pushCellToScrollView(self.svVec[tabIndex], data)
    RAStoreUIPage:pushCellToScrollView(self.scrollView, data)
end

--data:结构由1个itemTable组成
function RAStoreUIPage:pushCellToScrollView(scrollView, data)
    -- local mainLevel = RABuildManager:getMainCityLvl()
    -- for k,v in pairs(data) do

    --     if v.buyLV <= mainLevel then 
    --         local cell = CCBFileCell:create()
    --         local ccbiStr = "RAPackageStoreCell.ccbi"
    --         cell:setCCBFile(ccbiStr)
    --         local panel = RAStoreUICellItemPage:new({
    --                 mData = v,
    --                 mTag   = k
    --         })
    --         cell:registerFunctionHandler(panel)
    --         scrollView:addCell(cell)
    --     end 
    -- end

    -- scrollView:orderCCBFileCells()


    local isv = false
    if not next(data) then
        isv = true
    end
    
    UIExtend.setNodeVisible(self.ccbfile,"mEmptyLabel",isv)
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    local mainLevel = RABuildManager:getMainCityLvl()

    for k,v in pairs(data) do
        if v.buyLV <= mainLevel then 
            local cell = CCBFileCell:create()
            local ccbiStr = "RAPackageStoreCellNew.ccbi"
            cell:setCCBFile(ccbiStr)
            local panel = RAStoreUICellItemPage:new({
                    mData = v,
                    mTag  = k
            })
            cell:registerFunctionHandler(panel)
            scrollView:addCell(cell)
        end
    end

    scrollView:orderCCBFileCells()
    local RAPackageManager = RARequire("RAPackageManager")
    if RAPackageManager.mIsRememberPkgOffset and nil ~= self.scrollViewContentOffset then
        local x, y = self.scrollViewContentOffset.x, self.scrollViewContentOffset.y
        local nowSVContentHeight = scrollView:getContentSize().height
        local oldSVContentHeight = self.scrollViewContentSize.height
        local offsetPoint = self.scrollViewContentOffset
        offsetPoint.y = offsetPoint.y + oldSVContentHeight - nowSVContentHeight
        scrollView:setContentOffset(offsetPoint)
        RAPackageManager.mIsRememberPkgOffset = false
    end
end


--------------------------------------------------------------
-----------------------消息处理-------------------------------
--------------------------------------------------------------

local onReceiveMessage = function(message)
    if message.messageID == MessageDef_package.MSG_package_discount_selling_data then
        RAStoreUIPage:updateDiscountedSelling()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
        if opcode == HP_pb.BUY_HOT_C then 
            RAStoreManager:setHotSalesInfoIsAlreadyBuy()
            UIExtend.setNodeVisible(RAStoreUIPage.ccbfile, "mBoughtPic", true)
            RARootManager.ShowMsgBox('@buySuccessful')
        elseif opcode == HP_pb.ITEM_BUY_C then
            RARootManager.ShowMsgBox('@buySuccessful')
        end
    end
end
--注册监听消息
function RAStoreUIPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_discount_selling_data, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, onReceiveMessage)
end

function RAStoreUIPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_package.MSG_package_discount_selling_data, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, onReceiveMessage)
end


--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--点击随机更换内容
function RAStoreUIPage:onChangeBtn()
    self:randomUpdatePkgTips()
    p_ramdomIndex = 0
end

--购买打折商品按钮事件
function RAStoreUIPage:onSaleBuyBtn()
    local sellingData = RAStoreManager.mDiscountedSellingData
    if sellingData.isAlreadyBuy then
        return
    end

    --传入的是物品
    local sellingData = RAStoreManager.mDiscountedSellingData
    local dataTable = shopsale_conf[sellingData.salesId]
    local shopData  = shop_conf[dataTable.shopId]
    local itemConf  = item_conf[shopData.shopItemID]

    local itemData =Utilitys.deepCopy(itemConf)
    itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopHotBuy
    itemData.shopId     = shopData.id
    itemData.price      = shopData.price
    itemData.salesId    = sellingData.salesId
    itemData.salePrice  = dataTable.salePrice
    RARootManager.OpenPage("RAPackageInfoPopUp", itemData, false, true, true)
end

function RAStoreUIPage:onAllBtn()
    self:clickTabBtn(RAPackageData.STORE_CHOOSEN_TAB.allTab)
end

function RAStoreUIPage:onAccelerateBtn()
    self:clickTabBtn(RAPackageData.STORE_CHOOSEN_TAB.accelerateTab)
end

function RAStoreUIPage:onConditionBtn()
    self:clickTabBtn(RAPackageData.STORE_CHOOSEN_TAB.conditionTab)
end

function RAStoreUIPage:onSpecialBtn()
    self:clickTabBtn(RAPackageData.STORE_CHOOSEN_TAB.specialTab)
end

function RAStoreUIPage:onResourcesBtn()
    self:clickTabBtn(RAPackageData.STORE_CHOOSEN_TAB.resourcesTab)
end

function RAStoreUIPage:clickTabBtn(index)
    if RAStoreManager:getChoosenTab() == index then
        self:changeTabHandler(index)
        return
    end

    RAStoreManager:setChoosenTab(index)
    self:refreshChoosenTabPro(index)
end


--按钮，sv显示处理
function RAStoreUIPage:changeTabHandler(index)
    local hightLightVec = {}
    for i=1,#self.btnVec do
        hightLightVec[i] = false
        if i == index then
            hightLightVec[i] = true
        end
        --self.svVec[i]:setVisible(hightLightVec[i])
    end
    self:resetToggleButton(index)
    UIExtend.setControlButtonSelected(self.ccbfile,{
            mAllBtn = hightLightVec[1],
            mAccelerateBtn = hightLightVec[2],
            mConditionBtn = hightLightVec[3],
            mResourcesBtn = hightLightVec[4],
            mSpecialBtn = hightLightVec[5]
        })

    RAStoreManager:setChoosenTab(index)
end

function RAStoreUIPage:resetToggleButton(releaseIndex)
    for i,v in pairs(self.higtLight) do
        self.higtLight[i]:setVisible((releaseIndex) == i)
    end 
end