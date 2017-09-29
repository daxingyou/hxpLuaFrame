--背包界面cell中

local Utilitys      = RARequire("Utilitys")
local UIExtend      = RARequire("UIExtend")
local RAStringUtil  = RARequire("RAStringUtil")
local RAPackageManager = RARequire("RAPackageManager")
local item_conf   = RARequire("item_conf")
local RARootManager = RARequire("RARootManager")
local RAPackageData = RARequire("RAPackageData")

local RAPackageCellPage = 
{
	mTag  = 0,
	mData = {}
}
function RAPackageCellPage:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

--刷新数据
function RAPackageCellPage:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile = ccbfile
	RAPackageCellPage:refreshContent(self.mData, ccbfile)
end

function RAPackageCellPage:refreshContent(dataTable, ccbfile)
	
	RAPackageData.addBgAndPicToItemGrid( ccbfile, "mItemIconNode", dataTable )--物品icon
    RAPackageData.setNumTypeInItemIcon( ccbfile, "mItemHaveNum", "mItemHaveNumNode", dataTable )--显示数字类型

	local newNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNewNode")--物品新得
	if dataTable.isNew then
		newNode:setVisible(true)
	else
		newNode:setVisible(false)
	end
	
	local numNode = UIExtend.getCCNodeFromCCB(ccbfile, "mItemNumNode")--物品数量
	if tonumber(dataTable.count) >= 1 then
		numNode:setVisible(true)
		UIExtend.setCCLabelString(ccbfile,"mItemNum", dataTable.count)
	else
		numNode:setVisible(false)	
	end
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--购买按钮
function RAPackageCellPage:onClick()
	self.mData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse
	self.mData.useUUID=true
	RARootManager.showPackageInfoPopUp(self.mData)
end

return RAPackageCellPage