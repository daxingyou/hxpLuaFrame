--商城界面cell中的item
--by sunyungao
local RALogicUtil   = RARequire("RALogicUtil")
local Utilitys      = RARequire("Utilitys")
local UIExtend      = RARequire("UIExtend")
local RAStringUtil  = RARequire("RAStringUtil")
local RAStoreManager = RARequire("RAStoreManager")
local item_conf   = RARequire("item_conf")
local RAPackageData = RARequire("RAPackageData")
local RARootManager = RARequire("RARootManager")

local RAStoreUICellItemPage = 
{
	mTag  = 0,
	mData = {}
}
function RAStoreUICellItemPage:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


--刷新数据
function RAStoreUICellItemPage:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile  = ccbfile
	RAStoreUICellItemPage:refreshContent(self.mData, ccbfile)
end

setNumTypeInItemIcon = function( ccbfile, itemName, itemNodeName, data )
		local num_type = data.num_type
	    if num_type == nil then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, false)
	    elseif num_type == 1 then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, true)
	        local numCount = RALogicUtil:num2k(data.num_icon)
	        UIExtend.setCCLabelString(ccbfile,itemName,numCount)
	     elseif num_type == 2 then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, true)
	        local numCount = data.num_icon.."%"
	        UIExtend.setCCLabelString(ccbfile,itemName,numCount)
	    end
	end

function RAStoreUICellItemPage:refreshContent(dataTable, ccbfile)
	local itemData = item_conf[dataTable.shopItemID]
	local nameStr = "name"
	UIExtend.setCCLabelString(ccbfile, "mStoreItemTitle", itemData.item_name)
	RAPackageData.addBgAndPicToItemGrid( ccbfile, "mStoreItemIconNode", itemData )--icon
    setNumTypeInItemIcon( ccbfile, "mItemHaveNum", "mItemHaveNode", itemData )--显示数字类型
	local hotNode = UIExtend.getCCNodeFromCCB(ccbfile, "mHotNode")
	hotNode:setVisible(true)
	if dataTable.hotItem ~= RAPackageData.ShopNotHot then
		UIExtend.setCCLabelString(ccbfile,"mHotTex", _RALang("@shophot"))
	elseif dataTable.newItem ~= RAPackageData.ShopNotNew then
		UIExtend.setCCLabelString(ccbfile,"mHotTex", _RALang("@shopnew"))
	else
		hotNode:setVisible(false)
	end
	
	
	RAPackageData.setNameLabelStringAndColor(ccbfile, "mStoreItemExplain", itemData)--物品名称
	UIExtend.setNodeVisible(ccbfile, "mStoreItemNum", false)--物品数量
	UIExtend.setCCLabelString(ccbfile,"mDiamondsNum", dataTable.price)
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--购买按钮
function RAStoreUICellItemPage:onStoreClick()
	--传入的是物品
	local itemConf = item_conf[self.mData.shopItemID]
    local itemData =Utilitys.deepCopy(itemConf)
	itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy
	itemData.shopId     = self.mData.id
	itemData.price      = self.mData.price
	RARootManager.showPackageInfoPopUp(itemData)
end

return RAStoreUICellItemPage