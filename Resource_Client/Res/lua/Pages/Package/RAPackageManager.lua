--物品UI管理文件
--by sunyungao

local RANetUtil   = RARequire("RANetUtil")
local RAPackageData = RARequire("RAPackageData")
local item_conf   = RARequire("item_conf")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local RAPackageManager = 
{
	--所有
	mAllData        = {},
	--资源
	mResourcesData  = {},
    --加速
    mAccelerateData = {},
    --特殊
    mSpecialData    = {},
    --状态
    mConditionData  = {},
	--选中哪个tab
	mChoosenTab     = RAPackageData.PACKAGE_CHOOSEN_TAB.allTab,
    --是否在背包页签
    mIsPackageTab   = true,
    --是否打开过背包页签(购买了之后是否打开过)
    mHasOpenedPkgTab = true,
    --是否记住sv滑动到的位置
    mIsRememberPkgOffset = false,
    ItemType=
    {
        StateType           = 3,
        ResourceType        = 5,
        WorldType           = 100,
        ChangeNameType      = 103,
        ChangeStyleType     = 104,
        ResetLordSkillType  = 105,
        Horn                = 106
    }
}



function packageConfigSort(a, b)
    local r
    local aOrder = tonumber(a.order)
    local bOrder = tonumber(b.order)

    r = aOrder < bOrder

    return r
end

--重置数据
function RAPackageManager:reset()
	self.mAllData    = {}
	self.mResourcesData = {}
    self.mAccelerateData = {}
    self.mSpecialData = {}
    self.mConditionData = {}
    self.mChoosenTab     = RAPackageData.PACKAGE_CHOOSEN_TAB.allTab
    self.mIsPackageTab   = true
end

--接收服务器发送到物品，并刷新
function RAPackageManager:updateServerDataByTempItem(itemInfo, isConsume)
    local tmpItemInfo = RAPackageManager:updateConfigDataByTempItem(itemInfo, isConsume)
    --判断面板没打开
    local k,pageHandler = RARootManager.checkPageLoaded("RAPackageMainPage")
    if pageHandler ~= nil then
        --如果面板是打开的
        --判断收到的物品是否在打开了的tab中，是的话发消息刷新
        if self.mChoosenTab ==  RAPackageData.PACKAGE_CHOOSEN_TAB.allTab or self.mChoosenTab == tmpItemInfo.tab then
            MessageManager.sendMessage(MessageDef_package.MSG_package_refresh_data, {})
        end
    end
end

function RAPackageManager:dealwithPkgSVOffset()
    self.mIsRememberPkgOffset = true
    MessageManager.sendMessage(MessageDef_package.MSG_package_remember_sv_offset, {})
end

function RAPackageManager:updateMainUIMenuPkgRedPoint()
    local count = 0
    for _,v in pairs(self.mAllData) do
        if v.isNew then
            count = count + 1
        end
    end
    self:refreshMainUIMenuPkgRedPoint(count)
end

--更新小红点
function RAPackageManager:refreshMainUIMenuPkgRedPoint(count)
    local data = {}
    local RAGameConfig = RARequire("RAGameConfig")
    data.menuType = RAGameConfig.MainUIMenuType.Item
    data.num = count
    data.isDirChange = true
    MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum, data)
end

--增删改的数据操作
function RAPackageManager:updateConfigDataByTempItem(itemInfo, isConsume)
    local isNeedSort = false
    local serverItemInfo = RAPackageManager:createItemByServerItem( itemInfo )--服务器发送来的数据
    --客户端无配置的道具给予丢弃处理，客户端有了再显示和处理，
    --1、热更新延迟导致
    --2、客户端和服务器配置不同步
    if serverItemInfo~=nil then
        if isConsume then
            RAPackageManager:consumeItemToData(serverItemInfo)
        else
            local isChange = RAPackageManager:changeItemToData(serverItemInfo)
            if not isChange then
                RAPackageManager:insertItemToData(serverItemInfo)
                isNeedSort = true
            end
        end
     else
        CCLuaLog("!!!!![Waring!!!!!]RAPackageManager:updateConfigData-itemId:"..tostring(serverItemInfo.itemId).." id is not exist in item_conf!")   
     end
    RAPackageManager:sortAllData( isNeedSort )
    return serverItemInfo
end

function RAPackageManager:sortAllData( isNeedSort )
    if isNeedSort then
        table.sort( self.mAllData,        packageConfigSort )
        table.sort( self.mResourcesData,  packageConfigSort )
        table.sort( self.mAccelerateData, packageConfigSort )
        table.sort( self.mSpecialData,    packageConfigSort )
        table.sort( self.mConditionData,  packageConfigSort )
    end
end

--创建含有配置文件属性的item
function RAPackageManager:createItemByServerItem( serverItem )
    local itemConf  = item_conf[serverItem.itemId]
    local item = nil
    if itemConf~=nil then
        item=Utilitys.deepCopy(itemConf)
        item.uuid   = serverItem.uuid
        item.count  = serverItem.count
        item.isNew  = serverItem.isNew
    else
        CCLuaLog("!!!!Waring RAPackageManager:createItemByServerItem()-itemId:"..tostring(serverItem.itemId).."id is not exist in item_conf!")      
    end
    return item
end

--插入
function RAPackageManager:insertItemToData(item)
    table.insert(self.mAllData, item)
    if RAPackageData.PACKAGE_CHOOSEN_TAB.resourcesTab == item.tab then
        table.insert(self.mResourcesData, item)
    elseif RAPackageData.PACKAGE_CHOOSEN_TAB.accelerateTab == item.tab then
        table.insert(self.mAccelerateData, item)
    elseif RAPackageData.PACKAGE_CHOOSEN_TAB.specialTab == item.tab then
        table.insert(self.mSpecialData, item)
    elseif RAPackageData.PACKAGE_CHOOSEN_TAB.conditionTab == item.tab then
        table.insert(self.mConditionData, item)
    end
end

--删除
function RAPackageManager:consumeItemToData(item)
    local data = RAPackageManager:getDataByTabIndex(item.tab)
    for k,v in pairs(data) do
        if v.uuid == item.uuid then
            table.remove(data, k)
            break
        end
    end

    local allData = RAPackageManager.mAllData
    for k,v in pairs(allData) do
        if v.uuid == item.uuid then
            table.remove(allData, k)
            break
        end
    end
end

--修改
function RAPackageManager:changeItemToData(item)
    local isChange = false
    local data = RAPackageManager:getDataByTabIndex(item.tab)
    for k,v in pairs(data) do
        if v.uuid == item.uuid then
            v.count = item.count
            v.isNew = item.isNew
            isChange = true
            break
        end
    end

    if not isChange then
        return isChange
    end

    local allData = RAPackageManager.mAllData
    for k,v in pairs(allData) do
        if v.uuid == item.uuid then
            v.count = item.count
            v.isNew = item.isNew
            break
        end
    end
    return isChange
end

--根据itemID获得处理过的iteminfo
function RAPackageManager:getItemInfoByItemId(itemId)
    local allData = RAPackageManager.mAllData
    for k,v in pairs(allData) do
        if v.id == itemId then
            return v
        end
    end
    return nil
end

function RAPackageManager:getDataByTabIndex(tabIndex)                                                                                   
    local data = {}
    if tabIndex == RAPackageData.PACKAGE_CHOOSEN_TAB.allTab then
        data = RAPackageManager.mAllData
    elseif tabIndex == RAPackageData.PACKAGE_CHOOSEN_TAB.resourcesTab then
        data = RAPackageManager.mResourcesData
    elseif tabIndex == RAPackageData.PACKAGE_CHOOSEN_TAB.accelerateTab then
        data = RAPackageManager.mAccelerateData
    elseif tabIndex == RAPackageData.PACKAGE_CHOOSEN_TAB.specialTab then
        data = RAPackageManager.mSpecialData
    elseif tabIndex == RAPackageData.PACKAGE_CHOOSEN_TAB.conditionTab then
        data = RAPackageManager.mConditionData
    end
    return data 
end

function RAPackageManager:getChoosenData()
    local data = self:getDataByTabIndex(self.mChoosenTab)
    return data
end

function RAPackageManager:getChoosenTab()
    return self.mChoosenTab
end

function RAPackageManager:setChoosenTab(index)
    self.mChoosenTab = index
end

function RAPackageManager:setIsPackageTab( bl )
    self.mIsPackageTab = bl
end

function RAPackageManager:getIsPackageTab()
    return self.mIsPackageTab
end

--------------------------------------------------------------
-----------------------协议相关-------------------------------
--------------------------------------------------------------

-- 发送购买
--id:道具配置表id
function RAPackageManager:sendUseItemByUUID(id, count)
    local cmd = Item_pb.HPItemUseReq()
    cmd.uuid  = id
    cmd.itemCount = count
    RANetUtil:sendPacket(HP_pb.ITEM_USE_C, cmd, {retOpcode = -1})
end

function RAPackageManager:sendUseItemByItemId(id, count)
    local cmd = Item_pb.HPItemUseByItemIdReq()
    cmd.itemId  = id
    cmd.itemCount = count
    RANetUtil:sendPacket(HP_pb.ITEM_USE_BY_ITEMID_C, cmd)
end

--购买并使用道具
function RAPackageManager:sendBuyAndUse(id, count)
    local cmd = Item_pb.HPItemBuyAndUseReq()
    cmd.itemId  = id
    cmd.itemCount = count
    RANetUtil:sendPacket(HP_pb.BUY_AND_USE_C, cmd, {retOpcode = -1})
end

--发送打开过界面消息（刷新品展示标签）
function RAPackageManager:sendItemNewClearMsg()
    RANetUtil:sendPacket(HP_pb.ITEM_OPEN_BAG_C, nil, {retOpcode = -1})
end

function RAPackageManager:clearAllItemIsNewFalse()
    local data = {self.mAllData, self.mResourcesData, self.mAccelerateData, self.mAlmSpecialDatalData, self.mConditionData}
    for _,v1 in pairs(data) do
        for _,v2 in pairs(v1) do
            v2.isNew = false
        end
    end
end

return RAPackageManager