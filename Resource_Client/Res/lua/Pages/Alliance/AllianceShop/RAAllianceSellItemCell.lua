--联盟留言的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceSellItemCell = {}
local RARootManager = RARequire("RARootManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local item_conf =  RARequire('item_conf')
local RAPackageData =  RARequire('RAPackageData')
local RAAllianceManager = RARequire('RAAllianceManager')

function RAAllianceSellItemCell:new(o)
    o = o or {}
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSellItemCell:onStoreClick()
    RARootManager.OpenPage("RAAllianceBuyPage",self.info,false, true, true)
end

--刷新数据
function RAAllianceSellItemCell:onRefreshContent(ccbRoot)
	--todo
	-- CCLuaLog("RAAllianceHistoryCell:onRefreshContent")
    UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
    self.ccbfile = ccbRoot:getCCBFileNode() 

    local itemData = item_conf[self.info.itemId]
    local nameStr = "name"
    UIExtend.setCCLabelString(self.ccbfile, "mItemName", _RALang(itemData.item_name))

    RAPackageData.addBgAndPicToItemGrid(self.ccbfile, "mStoreItemIconNode", itemData )--icon
    RAPackageData.setNumTypeInItemIcon(self.ccbfile, "mItemHaveNum", "mItemHaveNode", itemData )--显示数字类型
    local hotNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mHotNode")
    -- hotNode:setVisible(self.info.isRare)

     if self.info.rare == GuildManager_pb.RARE then 
        hotNode:setVisible(true)
    else
        hotNode:setVisible(false)
    end
    
    UIExtend.setCCLabelString(self.ccbfile,"mHotTex", _RALang("@Rare"))
    
    UIExtend.setCCLabelString(self.ccbfile,"mCurrencyNum", self.info.price)

    local mainNode = self.ccbfile:getCCNodeFromCCB("mGrayNode")
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    mainNode:setVisible(true)
 
    if self.info.unlockLevel <= RAAllianceManager.selfAlliance.level then --解锁标签
        UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(false)
        mainNode:setVisible(true)
    else
        UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(true)
        UIExtend.setCCLabelString(self.ccbfile,"mUnlockCondition", _RALang("@UnlockPoint") .. ':' ..  self.info.unlockLevel) 
        local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
        graySprite:setTag(grayTag)
        graySprite:setPosition(mainNode:getPosition())
        graySprite:setAnchorPoint(mainNode:getAnchorPoint())
        mainNode:getParent():addChild(graySprite)
        mainNode:setVisible(false)
    end

end

return RAAllianceSellItemCell