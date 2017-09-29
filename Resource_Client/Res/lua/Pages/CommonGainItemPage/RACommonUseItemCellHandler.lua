--通用道具使用界面cell

local UIExtend      = RARequire("UIExtend")
local RAPackageData = RARequire("RAPackageData")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local RACoreDataManager = RARequire("RACoreDataManager")
local RACommonGainItemData = RARequire('RACommonGainItemData')
local RAGuideManager = RARequire("RAGuideManager")

local RACommonUseItemCellHandler = 
{
	mTag  = 0,
	mData = {}
}
function RACommonUseItemCellHandler:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


--刷新数据
function RACommonUseItemCellHandler:onRefreshContent(ccbRoot)
	CCLuaLog("RACommonUseItemCellHandler:onRefreshContent")

	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile  = ccbfile
	local itemData = self.mData.conf
	local count = RACoreDataManager:getItemCountByItemId(itemData.id)

	--name
	RAPackageData.setNameLabelStringAndColor(ccbfile, "mCellTitle", itemData)
	--icon
	RAPackageData.addBgAndPicToItemGrid( ccbfile, "mIconNode", itemData )
	--显示数字类型
    RAPackageData.setNumTypeInItemIcon( ccbfile, "mHaveNum", "mItemHaveNode", itemData )	
	--物品描述
	UIExtend.setCCLabelString(ccbfile, "mCellExplain", _RALang(itemData.item_des))
	--物品数量
	UIExtend.setCCLabelString(ccbfile,"mItemNum", _RALang("@itemCurrentCount")..(count or 0))
	--按钮上的花费
	UIExtend.setCCLabelString(ccbfile,"mDiamondsNum", itemData.sellPrice)
	if count == nil or count <= 0 then
		UIExtend.setNodeVisible(ccbfile, "mBuyBtnNode", true)
		UIExtend.setNodeVisible(ccbfile, "mUseBtn", false)  
		UIExtend.updateControlButtonTitle(ccbfile, "mBuyBtnac" )
	else
		UIExtend.setNodeVisible(ccbfile, "mBuyBtnNode", false)
		UIExtend.setNodeVisible(ccbfile, "mUseBtn", true)
		UIExtend.updateControlButtonTitle(ccbfile, "mUseBtn" )
	end
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--使用按钮
function RACommonUseItemCellHandler:onUseBtn()
	-- body

	local itemId = self.mData.conf.id
	local itemType = self.mCellType
	local marchId = self.mMarchId

	if nil == self.mData.server then
		return
	end
	--local uuid = self.mData.server[1].uuid
	local function onUseConfirmCallBack(isConfirm)
	    if not isConfirm then
	    	return
	    end
		
	    -- 出征上限
	    if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.expeditionMax then
	    	-- TODO: 公用道具使用接口
	    	self:useStatusItemHandler(false)
        elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack then
            --添加体力相关
            self:useCommonItemHandler(false)
	    -- 行军加速
	    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
	    	local RAWorldPushHandler = RARequire('RAWorldPushHandler')    
        	RAWorldPushHandler:sendMarchSpeedUpReq(marchId, itemId)
        	-- RARootManager.CloseCurrPage()
	    -- 行军召回
    	elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchCallBack then
    		local RAWorldPushHandler = RARequire('RAWorldPushHandler')    
        	RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
        	-- RARootManager.CloseCurrPage()
        	MessageManager.sendMessage(MessageDef_World.MSG_CloseMarchUseItemPageForCallBack)  
    	elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.resCollectSpeedUp then
            -- 采集资源加速
            self:useStatusItemHandler(false)
    	elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.useExp then
            -- 使用经验药
            self:useCommonItemHandler(false)            
    	end
	end

    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RARootManager.RemoveGuidePage()
        onUseConfirmCallBack(true)
    else
        local name = _RALang(self.mData.conf.item_name)
	    local final = string.gsub(name, "%%", "%%%%")
	    local tipStr = RAStringUtil:getLanguageString("@useConfirmDes", final, 1)
	    local confirmData = {labelText = tipStr, title=_RALang("@useConfirm"), yesNoBtn=true, resultFun=onUseConfirmCallBack}
        RARootManager.showConfirmMsg(confirmData)
    end
	
end



--购买按钮
function RACommonUseItemCellHandler:onBuyBtn()
	
	local itemId = self.mData.conf.id
	local itemType = self.mCellType
	local marchId = self.mMarchId
	--点击确认按键则扣除钻石并提示玩家：“购买并使用成功”；道具生效后返回上一页。
	local onBuyConfirmCallBack = function (isConfirm)
	    if not isConfirm then
	    	return
	    end
	    
		-- 出征上限
	    if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.expeditionMax then
	    	-- TODO: 公用道具使用接口
	    	self:useStatusItemHandler(true)
        elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack then
            --添加体力相关
            self:useCommonItemHandler(true)
	    -- 行军加速
	    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
	    	local RAWorldPushHandler = RARequire('RAWorldPushHandler')    
	    	RAWorldPushHandler:sendMarchSpeedUpReq(marchId, itemId)
	    	-- RARootManager.CloseCurrPage()
	    -- 行军召回
		elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchCallBack then
			local RAWorldPushHandler = RARequire('RAWorldPushHandler')    
	    	RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
	    	-- RARootManager.CloseCurrPage()
	    	MessageManager.sendMessage(MessageDef_World.MSG_CloseMarchUseItemPageForCallBack)  
    	elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.resCollectSpeedUp then
            -- 采集资源加速
            self:useStatusItemHandler(true)
    	elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.useExp then
            -- 经验药
            self:useCommonItemHandler(true)            
		end
	end
	
	local tipStr = _RALang("@buyUse")--您当前没有该道具，是否购买并使用？
	local confirmData = {labelText = tipStr, title=_RALang("@attention"), yesNoBtn=true, resultFun=onBuyConfirmCallBack}
    RARootManager.showConfirmMsg(confirmData)
end

function RACommonUseItemCellHandler:useCommonItemHandler(isBuyAndUse)
    if isBuyAndUse then
		self:sendBuyAndUseCallBack()
	else
		self:sendUseCallBack()
	end
	--RARootManager.CloseCurrPage()
end

--使用状态类道具特殊处理
function RACommonUseItemCellHandler:useStatusItemHandler(isBuyAndUse)
	local buff_conf = RARequire("buff_conf")
	local RABuffManager = RARequire('RABuffManager')
	local buffId = self.mData.conf.buffId
	local effectId, effectValue = buff_conf[buffId].effect, buff_conf[buffId].value
	local playerEffectValue = RABuffManager:getBuffValue(effectId)

	local this = self
	local confirmUseItem = function (isOK)
		if isOK then		
			if isBuyAndUse then
				this:sendBuyAndUseCallBack()
			else
				this:sendUseCallBack()
			end
		end
	    RARootManager.CloseCurrPage()
	end

	if playerEffectValue == effectValue or playerEffectValue == 0 then -- 同一种作用号,直接使用，（叠加效果）
		confirmUseItem(true)
	elseif playerEffectValue > effectValue then --已有高等级效果后再使用低等级效果道具，提示无法使用
		local this = self
		local confirmData = 
		{
			labelText = _RALang("@unUse"),
			title =_RALang("@useConfirm"),
			yesNoBtn = true,
			resultFun = confirmUseItem
		}
    	RARootManager.showConfirmMsg(confirmData)
	else
		--todo 不同种作用号，提示是否要使用（替换原有作用号）
		--@buffMutex       使用该道具会覆盖您当前的状态，是否确定使用？
		local this = self
		local confirmData = 
		{
			labelText = _RALang("@buffMutex"), 
			title = _RALang("@useConfirm"), 
			yesNoBtn = true, 
			resultFun = confirmUseItem
		}
    	RARootManager.showConfirmMsg(confirmData)
	end
end

function RACommonUseItemCellHandler:sendBuyAndUseCallBack()
	local RAPackageManager = RARequire("RAPackageManager")
	local itemId = self.mData.conf.id
	RAPackageManager:sendBuyAndUse(itemId, 1)
end

function RACommonUseItemCellHandler:sendUseCallBack()
	local RAPackageManager = RARequire("RAPackageManager")
	--local uuid = self.mData.server[1].uuid
	--RAPackageManager:sendUseItemByUUID(uuid, 1)
	--更改為使用itemId消耗道具，以防物品因堆疊后uuid出现问题，尤其是self.mData.server[1].uuid
	local itemId = self.mData.conf.id
	RAPackageManager:sendUseItemByItemId(itemId, 1)
end

return RACommonUseItemCellHandler