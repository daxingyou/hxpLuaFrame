--商城管理文件

local RANetUtil     = RARequire("RANetUtil")
local RAPackageData = RARequire("RAPackageData")
local Item_pb       = RARequire("Item_pb")
local RARootManager = RARequire("RARootManager")
local item_conf = RARequire("item_conf")

local RAStoreManager = 
{
	--所有
	mAllData        = {},
	--资源
	mResourcesData  = {},
    --加速
    mAccelerateData = {},
    --特殊
    mSpecialData    = {},
    --装备
    mConditionData  = {},
	--选中哪个tab
	mChoosenTab     = RAPackageData.STORE_CHOOSEN_TAB.allTab,
    --是否刷新过某一页的数据（即是否打开过某页）
    isRefreshVec    = {},
    --打折商品相关
    mDiscountedSellingData = {}
}

--重置数据
function RAStoreManager:reset()
	self.mAllData    = {}
	self.mResourcesData = {}
    self.mAccelerateData = {}
    self.mSpecialData = {}
    self.mConditionData = {}
    self.mChoosenTab     = RAPackageData.STORE_CHOOSEN_TAB.allTab
    self.isRefreshVec    = {}
    self.mDiscountedSellingData = {}
end



--排序：新品（newItem）
--热销 （hotItem）
--分类 （group）
-- id
function storeConfigAllSort(a, b)
    local r
    local aNewItem = tonumber(a.newItem)
    local bNewItem = tonumber(b.newItem)
    local aHotItem = tonumber(a.hotItem)
    local bHotItem = tonumber(b.hotItem)
    local aGroup = tonumber(a.group)
    local bGroup = tonumber(b.group)
    local aId = tonumber(a.id)
    local bId = tonumber(b.id)

    local aItem = item_conf[a.shopItemID]
    local bItem = item_conf[b.shopItemID]
    if aNewItem == bNewItem then
        if aHotItem == bHotItem then
            if aGroup == bGroup then
                r = aItem.order < bItem.order
            else
                r = aGroup < bGroup
            end
        else
            r = aHotItem < bHotItem
        end
    else
        r = aNewItem < bNewItem
    end

    return r
end

--排序：新品（newItem）
--热销 （hotItem）
-- id
function storeConfigOtherSort(a, b)
    local r
    local aNewItem = tonumber(a.newItem)
    local bNewItem = tonumber(b.newItem)
    local aHotItem = tonumber(a.hotItem)
    local bHotItem = tonumber(b.hotItem)
    local aId = tonumber(a.id)
    local bId = tonumber(b.id)

    local aItem = item_conf[a.shopItemID]
    local bItem = item_conf[b.shopItemID]
    if aNewItem == bNewItem then
        if aHotItem == bHotItem then
            r = aItem.order < bItem.order
        else
            r = aHotItem < bHotItem
        end
    else
        r = aNewItem < bNewItem
    end

    return r
end

--配置文件数据初始化
function RAStoreManager:updateConfigData()
    -- if 0 ~= #self.mAllData then
    --     return
    -- end
    self.mAllData = {}
    self.mResourcesData = {}
    self.mAccelerateData = {}
    self.mSpecialData = {}
    self.mConditionData = {}

    local RABuildManager = RARequire('RABuildManager')
    local pLV = RABuildManager:getMainCityLvl()
    local shop_conf     = RARequire("shop_conf")
    for k,v in pairs(shop_conf) do
        local newItem = v.newItem
        local hotItem = v.hotItem
        if newItem == nil then v.newItem = RAPackageData.ShopNotNew end
        if hotItem == nil then v.hotItem = RAPackageData.ShopNotHot end

        if pLV >= tonumber(v.buyLV) and v.group ~= nil then
            table.insert(self.mAllData, v)
        end
    end
    
    table.sort(self.mAllData, storeConfigAllSort)

    for k,v in pairs(self.mAllData) do
        if RAPackageData.PACKAGE_CHOOSEN_TAB.resourcesTab == v.group then
            table.insert(self.mResourcesData, v)
        elseif RAPackageData.PACKAGE_CHOOSEN_TAB.accelerateTab == v.group then
            table.insert(self.mAccelerateData, v)
        elseif RAPackageData.PACKAGE_CHOOSEN_TAB.specialTab == v.group then
            table.insert(self.mSpecialData, v)
        elseif RAPackageData.PACKAGE_CHOOSEN_TAB.conditionTab == v.group then
            table.insert(self.mConditionData, v)
        end
    end

    table.sort( self.mResourcesData,  storeConfigOtherSort )
    table.sort( self.mAccelerateData, storeConfigOtherSort )
    table.sort( self.mSpecialData,    storeConfigOtherSort )
    table.sort( self.mConditionData,      storeConfigOtherSort )
end

--通过对应的标签获取对应的数据
function RAStoreManager:getDataByTab(tabIndex)
    if tabIndex == RAPackageData.STORE_CHOOSEN_TAB.allTab then
        return self.mAllData
    elseif tabIndex == RAPackageData.STORE_CHOOSEN_TAB.resourcesTab then
        return self.mResourcesData
    elseif tabIndex == RAPackageData.STORE_CHOOSEN_TAB.accelerateTab then
        return self.mAccelerateData
    elseif tabIndex == RAPackageData.STORE_CHOOSEN_TAB.specialTab then
        return self.mSpecialData
    elseif tabIndex == RAPackageData.STORE_CHOOSEN_TAB.conditionTab then
        return self.mConditionData
    end
end

function RAStoreManager:getChoosenTab()
    return self.mChoosenTab
end

function RAStoreManager:setChoosenTab(index)
    self.mChoosenTab = index
end
--------------------------------------------------------------
-----------------------协议相关-------------------------------
--------------------------------------------------------------

-- 发送购买
function RAStoreManager:sendBuyItem(shopId, count)
    local cmd = Item_pb.HPItemBuyReq()
    cmd.shopId = shopId
    cmd.itemCount = count
    RANetUtil:sendPacket(HP_pb.ITEM_BUY_C, cmd, {retOpcode = -1})
end

--接收到打折商品消息处理
function RAStoreManager:onRecieveHotSalesInfo(msg)
    if msg == nil then
        return
    end

    self.mDiscountedSellingData.salesId = msg.salesId
    self.mDiscountedSellingData.endTime = msg.endTime
    self.mDiscountedSellingData.isAlreadyBuy = msg.isAlreadyBuy


    local k,pageHandler = RARootManager.checkPageLoaded("RAPackageMainPage")
    if pageHandler == nil then--判断面板没打开
        return
    end

    --判断面板打开了
    MessageManager.sendMessage(MessageDef_package.MSG_package_discount_selling_data, {})
end

--设置为已购买，当收到购买返回成功消息后
function RAStoreManager:setHotSalesInfoIsAlreadyBuy()
    self.mDiscountedSellingData.isAlreadyBuy = true
end

--发送打折商品购买
function RAStoreManager:sendDiscountedSelling(salesId)
    local cmd = Item_pb.HPBuyHotReq()
    cmd.salesId = salesId
    RANetUtil:sendPacket(HP_pb.BUY_HOT_C, cmd, {retOpcode = -1})
end

return RAStoreManager