--联盟留言的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceShopItemCell = {}
local RARootManager = RARequire("RARootManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local item_conf =  RARequire('item_conf')
local RAPackageData =  RARequire('RAPackageData')
local GuildManager_pb = RARequire('GuildManager_pb')


function RAAllianceShopItemCell:new(o)
    o = o or {}
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceShopItemCell:onStoreClick()
    RARootManager.OpenPage("RAAllianceBuyPage",self.info,false, true, true)
end

--刷新数据
function RAAllianceShopItemCell:onRefreshContent(ccbRoot)
	--todo
	-- CCLuaLog("RAAllianceHistoryCell:onRefreshContent")
    UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
    self.ccbfile = ccbRoot:getCCBFileNode() 

    local itemData = item_conf[self.info.itemId]
    local nameStr = "name"
    UIExtend.setCCLabelString(self.ccbfile, "mItemName", _RALang(itemData.item_name))

    -- UIExtend.setCCLabelString(self.ccbfile, "mItemName", self.info.itemId)

    RAPackageData.addBgAndPicToItemGrid(self.ccbfile, "mStoreItemIconNode", itemData )--icon
    RAPackageData.setNumTypeInItemIcon(self.ccbfile, "mItemHaveNum", "mItemHaveNode", itemData )--显示数字类型
    local hotNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mHotNode")

    if self.info.rare == GuildManager_pb.RARE then 
        hotNode:setVisible(true)
    else
        hotNode:setVisible(false)
    end

    UIExtend.setCCLabelString(self.ccbfile,"mHotTex", _RALang("@Rare"))
    
    -- RAPackageData.setNameLabelStringAndColor(self.ccbfile, "mStoreItemExplain", itemData)--物品名称
    -- UIExtend.setNodeVisible(self.ccbfile, "mStoreItemNum", false)--物品数量


    UIExtend.setCCLabelString(self.ccbfile,"mCurrencyNum", self.info.price)

    -- self.info.count = 0
    if self.cellType == 1 then 

        local mainNode = self.ccbfile:getCCNodeFromCCB("mGrayNode")
        local grayTag = 10000
        mainNode:getParent():removeChildByTag(grayTag,true)

        if self.info.rare == GuildManager_pb.PERMANENT then 
           UIExtend.setCCLabelString(self.ccbfile,"mStoreItemNum", '')
        else
            UIExtend.setCCLabelString(self.ccbfile,"mStoreItemNum", _RALang("@RestValue") .. ':' ..  self.info.count)
        end

        if self.info.count == 0 and self.info.rare ~= GuildManager_pb.PERMANENT then 
            UIExtend.getCCNodeFromCCB(self.ccbfile, "mSoldOutNode"):setVisible(true) --售空标签
            UIExtend.getCCControlButtonFromCCB(self.ccbfile, 'mStoreClick'):setEnabled(false)

            local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
            graySprite:setTag(grayTag)
            graySprite:setPosition(mainNode:getPosition())
            graySprite:setAnchorPoint(mainNode:getAnchorPoint())
            mainNode:getParent():addChild(graySprite)
            mainNode:setVisible(false)
        else
            UIExtend.getCCNodeFromCCB(self.ccbfile, "mSoldOutNode"):setVisible(false)
            UIExtend.getCCControlButtonFromCCB(self.ccbfile, 'mStoreClick'):setEnabled(true)
            mainNode:setVisible(true)
        end 
        -- UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(false)
       
    elseif self.cellType == 2 then 
        UIExtend.getCCNodeFromCCB(self.ccbfile, "mSoldOutNode"):setVisible(false)
        UIExtend.getCCControlButtonFromCCB(self.ccbfile, 'mStoreClick'):setEnabled(false)

        if self.info.unlockPoint == 0 then 
            -- UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(false)
        else 
            if self.info.unlockPoint < self.info.historyScore then --解锁标签
                -- UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(false)
            else
                -- UIExtend.getCCNodeFromCCB(self.ccbfile, "mUnLockedNode"):setVisible(true)
            end
        end 

        UIExtend.setCCLabelString(self.ccbfile,"mStoreItemNum", _RALang("@UnlockPoint") .. ':' ..  self.info.unlockPoint) 
    end 
end

return RAAllianceShopItemCell