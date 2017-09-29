--region RABlackShopPage.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire("BasePage")
local RABlackShopPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local Const_pb = RARequire("Const_pb")
local RARootManager = RARequire("RARootManager")
local RAResManager = RARequire("RAResManager")
local RAPackageData = RARequire("RAPackageData")
local RABlackShopManager = RARequire("RABlackShopManager")
local item_conf = RARequire("item_conf")
local Utilitys = RARequire("Utilitys")
local ScrollViewAnimation = RARequire('ScrollViewAnimation')
local mFrameTime = 0
local mListSV = nil
local RABlackShopCell = {
	
}
function RABlackShopCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABlackShopCell:onRefreshContent(ccbRoot)
	CCLuaLog("RABlackShopCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data
    
    local itemData = item_conf[data.itemId]
    assert(itemData ~= nil ,"itemData ~= nil")
    RAPackageData.addBgAndPicToItemGrid(ccbfile, "mStoreItemIconNode", itemData )--icon
    RAPackageData.setNumTypeInItemIcon(ccbfile, "mItemHaveNum", "mItemHaveNode", itemData )--显示数字类型

    local resIcon, resName = RAResManager:getIconByTypeAndId(Const_pb.TOOL * 10000, data.itemId)

    local oldResPic,_ = RAResManager:getIconByTypeAndId(data.oldPrice.itemType, data.oldPrice.itemId)
    local newResPic,_ = RAResManager:getIconByTypeAndId(data.price.itemType, data.price.itemId)

    UIExtend.addSpriteToNodeParent(ccbfile,"mCurrentDiamondsIco",oldResPic)
    UIExtend.addSpriteToNodeParent(ccbfile,"mDiamondsIco",newResPic)

    local txtLabel = {}
    txtLabel["mItemName"] =  GameMaths:stringAutoReturnForLua(_RALang(resName),8,0)
    txtLabel["mItemNum"] = _RALang("@ItemCurNumber",data.count)
    txtLabel["mDiscountAgo"] = data.oldPrice.itemCount
    txtLabel["mDiamondsNum"] = data.price.itemCount
    
    UIExtend.setStringForLabel(ccbfile, txtLabel)

    if data.bought then
        UIExtend.setNodesVisible(ccbfile,{
            mHasBuyNode = true,
            mNotBuyNode = false
        })
    else
        UIExtend.setNodesVisible(ccbfile,{
            mHasBuyNode = false,
            mNotBuyNode = true
        })
    end
    local mShaderNode = tolua.cast(ccbfile:getVariable("mShaderNode"),"CCShaderNode")
    mShaderNode:setEnable(true)
    if data.best then
        --ccbfile:runAnimation("SpecialAni")
        UIExtend.setNodeVisible(ccbfile, 'mHotNode', true)
    else
        --ccbfile:runAnimation("Default Timeline")
        UIExtend.setNodeVisible(ccbfile, 'mHotNode', false)
    end
    ccbfile:runAnimation("Default Timeline")
end

function RABlackShopCell:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
    local mShaderNode = tolua.cast(ccbfile:getVariable("mShaderNode"),"CCShaderNode")
    mShaderNode:setEnable(true)
    if lastAnimationName == "RefreshAni" then
        if self.data.best then
            --ccbfile:runAnimation("SpecialAni")
        else
            --ccbfile:runAnimation("Default Timeline")
        end
    end
end

function RABlackShopCell:onStoreClick()
    RARootManager.OpenPage("RABlackShopBuyPopUp",self.data,false,true,true)
end

function RABlackShopPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RABlackShopPage.ccbi",self)
    mFrameTime = 0
    mListSV = ccbfile:getCCScrollViewFromCCB("mListSV")
    self:_initTitle()
    self:CommonRefresh()
    ScrollViewAnimation.init(self,"RefreshAni")
    local RACityScene_BlackShop = RARequire("RACityScene_BlackShop")
    RACityScene_BlackShop:setHasOpenPage(true)
    RACityScene_BlackShop:setBlackShopAni()

end

function RABlackShopPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()
	end
    local titleName = _RALang("@TravelShopTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RABlackShopPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RABlackShopPage:Execute()
    mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
        self:_refreshBottomBanner()
        mFrameTime = 0 
    end
    ScrollViewAnimation.update()
end

function RABlackShopPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RABlackShopPage")
    mListSV:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end


function RABlackShopPage:_refreshTopBanner()
    local txtLabel = {}
    local index = math.random(1,6)
    local randomLang = _RALang("@TravelShopExplain"..index);
    txtLabel["mBlackShopExplain"] = randomLang
    UIExtend.setStringForLabel(self.ccbfile, txtLabel)
end

function RABlackShopPage:_refreshBottomBanner()
    -- remain MilliSecond
    local remainMilliSecond = 0

    remainMilliSecond = Utilitys.getCurDiffMilliSecond(RABlackShopManager.nextRefreshTime)
    -- remainMilliSecond = remainMilliSecond / 1000
        
    local remainTime = math.ceil(remainMilliSecond)
    if remainTime < 0 then remainTime = 0  end 
    local tmpStr = Utilitys.createTimeWithFormat(remainTime)
    local txtLabel = {}
    tmpStr = _RALang("@TravelShopBottomExplain",tmpStr)
    txtLabel["mRefreshTimeLabel"] = tmpStr
    txtLabel["mDiamondsNum"] = RABlackShopManager.refreshNeedGold
    UIExtend.setStringForLabel(self.ccbfile, txtLabel)
       
end

function RABlackShopPage:_refreshScrollView(data)
    local pageData = RABlackShopManager.goodsInfos
    assert(pageData~=nil)
    ScrollViewAnimation.clearTable()
    mListSV:removeAllCell()
    for k,v in pairs(pageData) do 
        if v.itemId ~= nil then
            local cell = CCBFileCell:create()
		    cell:setCCBFile("RABlackShopCell.ccbi")
		    local panel = RABlackShopCell:new({
				    data = v
            })
		    cell:registerFunctionHandler(panel)
		    mListSV:addCell(cell)
            ScrollViewAnimation.addToTable(cell)
        end
    end
    mListSV:orderCCBFileCells()
    if data~= nil and data.isLocalRefresh then
        ScrollViewAnimation.runGetInParam("Default Timeline","RefreshAni")
    end
    
end


--加速
function RABlackShopPage:onRefreshNowBtn()
    RABlackShopManager:sendRefreshGoodCommand()
end

function RABlackShopPage:CommonRefresh(data)
    self:_refreshBottomBanner()
    self:_refreshTopBanner()
    self:_refreshScrollView(data)
end

return RABlackShopPage
--endregion
