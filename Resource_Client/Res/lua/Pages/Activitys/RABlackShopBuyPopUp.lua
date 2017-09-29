--region RABlackShopBuyPopUp.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire("BasePage")
local RABlackShopBuyPopUp = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local Const_pb = RARequire("Const_pb")
local RARootManager = RARequire("RARootManager")
local RAResManager = RARequire("RAResManager")
local RAPackageData = RARequire("RAPackageData")
local RABlackShopManager = RARequire("RABlackShopManager")
local item_conf = RARequire("item_conf")
local Utilitys = RARequire("Utilitys")

function RABlackShopBuyPopUp:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RABlackShopBuyPopUp.ccbi",self)
    self.data = data
    self:CommonRefresh(data)
end

function RABlackShopBuyPopUp:Exit()
    UIExtend.unLoadCCBFile(self)
end

function RABlackShopBuyPopUp:onBuyBtn()
    RABlackShopManager:sendBuyGoodCommand(self.data.id)
    RARootManager.CloseCurrPage()
end

function RABlackShopBuyPopUp:onClose()
    RARootManager.CloseCurrPage()
end

function RABlackShopBuyPopUp:CommonRefresh(data)
    local itemData = item_conf[data.itemId]
    RAPackageData.addBgAndPicToItemGrid(self.ccbfile, "mStoreItemIconNode", itemData )--icon
    RAPackageData.setNumTypeInItemIcon(self.ccbfile, "mItemHaveNum", "mItemHaveNode", itemData )--显示数字类型
    local resIcon, resName = RAResManager:getIconByTypeAndId(Const_pb.TOOL * 10000, data.itemId)
    local txtLabel = {}
    txtLabel["mTitle"] = _RALang("@TravelShopBuyPopupTitle")
    txtLabel["mItemName"] = _RALang(resName)
    txtLabel["mItemNum"] = _RALang("@ItemCurNumber",data.count)
    txtLabel["mNeedDiamondsLabel"] = data.price.itemCount
    UIExtend.setStringForLabel(self.ccbfile, txtLabel)

    local newResPic,_ = RAResManager:getIconByTypeAndId(data.price.itemType, data.price.itemId)
    UIExtend.addSpriteToNodeParent(self.ccbfile,"mDiamondsIco",newResPic)
end

return RABlackShopBuyPopUp
--endregion
