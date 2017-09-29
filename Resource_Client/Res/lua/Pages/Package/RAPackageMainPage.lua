--[[背包主界面
包含：背包，商店两个页签
]]

RARequire("BasePage")
RARequire("MessageDefine")
RARequire("MessageManager")
RARequire("RAStoreUIPage")

local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RALogicUtil = RARequire("RALogicUtil")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAPackageManager = RARequire("RAPackageManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local build_conf = RARequire("build_conf")
local RAGameConfig = RARequire("RAGameConfig")
local RAPackageMainPage = BaseFunctionPage:new(...)



function RAPackageMainPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAPackagePageNew.ccbi", RAPackageMainPage)
    self:initTitleConsume()

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner")

    self:refreshUI()
    RAPackageManager:sendItemNewClearMsg()

end

function RAPackageMainPage:Exit()
    if RAPackageManager.mHasOpenedPkgTab then
        --清理数据new=false
        RACoreDataManager:clearAllItemIsNewFalse()
        --清理小红点
        RAPackageManager:updateMainUIMenuPkgRedPoint(0)
    end

    RACommonTitleHelper:RemoveCommonTitle("RAPackageMainPage")
    
    if self.packageUIPage ~= nil then
        self.packageUIPage:Exit()
        self.packageUICCB:unregisterFunctionHandler()
        self.packageUICCB  = nil
        self.packageUIPage = nil
    end
    
    if self.storeUIPage ~= nil then
        self.storeUIPage:Exit()
        self.storeUIPage = nil
    end 

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner_back")
    
    RAPackageManager:setIsPackageTab(true)
    RAPackageManager.mHasOpenedPkgTab = true

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end


--初始化顶部资源条
function RAPackageMainPage:initTitleConsume()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local backCallBack = function()
        RARootManager.ClosePage("RAPackageMainPage")
    end

    local titleName = _RALang("@Item")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAPackageMainPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
    titleHandler:SetNewFunctionCallBackType(RACommonTitleHelper.TitleCallBack.Diamonds)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, self.onDiamondsCCB)
end

--判断上次打开的是哪个面板，就先初始化哪个
function RAPackageMainPage:refreshUI()
    local isPackageShow = RAPackageManager:getIsPackageTab()
    if isPackageShow then
        self:createPackageUIPage()
    else
        self:createStoreUIPage()
    end
    
    self:updateStoreUIVisible(not isPackageShow)
    self:updatePackageUIVisible(isPackageShow)
    self:changeTabHandler(RAPackageManager:getIsPackageTab())
end

function RAPackageMainPage:createPackageUIPage()
    if self.packageUIPage ~= nil then
        return
    end

    self.packageUICCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mPackageTabCCB")
    self.packageUIPage = UIExtend.GetPageHandler("RAPackageUIPage")
    self.packageUIPage.ccbfile = self.packageUICCB
    self.packageUIPage:Enter()
    self.packageUICCB:registerFunctionHandler(self.packageUIPage)
end

function RAPackageMainPage:createStoreUIPage()
 
    if nil ~= self.storeUIPage then
        return
    end
  
    local mBottomNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mBottomNode")
    self.storeUIPage  = UIExtend.GetPageHandler("RAStoreUIPage", true)
    UIExtend.AddPageToNode(self.storeUIPage, mBottomNode)
end

function RAPackageMainPage:updatePackageUIVisible(isVisible)
    if nil ~= self.packageUICCB then
        self.packageUICCB:setVisible(isVisible)
    end

    if isVisible then
        RAPackageManager.mHasOpenedPkgTab = isVisible
    end
end

function RAPackageMainPage:updateStoreUIVisible(isVisible)
    if nil ~= self.storeUIPage then
        self.storeUIPage:updateVisible(isVisible)
    end
end

--------------------------------------------------------------
-----------------------点击事件-------------------------------
--------------------------------------------------------------

--背包点击事件处理
function RAPackageMainPage:onGoPkgBtn()
    self:createPackageUIPage()
    self:updateStoreUIVisible(false)
    self:updatePackageUIVisible(true)

    RAPackageManager:setIsPackageTab(true)
    self:changeTabHandler(RAPackageManager:getIsPackageTab())
end

--商店点击事件处理
function RAPackageMainPage:onGoStoreBtn()
    self:createStoreUIPage()
    self:updatePackageUIVisible(false)
    self:updateStoreUIVisible(true)

    RAPackageManager:setIsPackageTab(false)
    self:changeTabHandler(RAPackageManager:getIsPackageTab())
end

function RAPackageMainPage:changeTabHandler(pkgTab)
    local storeTab = not pkgTab
    UIExtend.setControlButtonSelected(self.ccbfile,{
            mGoPkgBtn = pkgTab,
            mGoStoreBtn = storeTab
        })
end

--打开支付面板
function RAPackageMainPage:onDiamondsCCB()
    local RARealPayManager = RARequire('RARealPayManager')
    RARealPayManager:getRechargeInfo()
end