--背包界面
local UIExtend           = RARequire("UIExtend")
local RAPackageCellPage  = RARequire("RAPackageCellPage")
local RAPackageManager   = RARequire("RAPackageManager")
local RAPackageData      = RARequire("RAPackageData")
local itemtips_conf      = RARequire("itemtips_conf") 
local RARootManager      = RARequire("RARootManager")

RARequire("MessageDefine")
RARequire("MessageManager")

local RAPackageUIPage  = BaseFunctionPage:new(...)

function RAPackageUIPage:Enter(data)
	RAPackageUIPage:init()
    RAPackageUIPage:registerMessage()
end


--退出页面处理操作
function RAPackageUIPage:Exit()
    RAPackageManager:setChoosenTab(RAPackageData.PACKAGE_CHOOSEN_TAB.allTab)
    self:removeMessageHandler()
    self.scrollView:removeAllCell()
    self.ccbfile:stopAllActions()
end

--------------------------------------------------------------
-----------------------初始化---------------------------------
--------------------------------------------------------------

--初始化ui
function RAPackageUIPage:init()
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mPackageListSV")
    self.btnVec = {}
    self.higtLight = {}
    local btnNameVec = {"mAllBtn", "mAccelerateBtn", "mConditionBtn", "mResourcesBtn", "mSpecialBtn"}
    for i=1,#btnNameVec do
    	self.btnVec[i] = UIExtend.getCCControlButtonFromCCB(self.ccbfile, btnNameVec[i])
    end

    
    local mbtnlis = {"mTabBtnLabel1","mTabBtnLabel2","mTabBtnLabel3","mTabBtnLabel4","mTabBtnLabel5"}
    for i,v in pairs(mbtnlis) do
        local tmp = UIExtend.getCCSpriteFromCCB(self.ccbfile, mbtnlis[i])
        self.higtLight[i] = tmp
    end 

    RAPackageUIPage:refreshChoosenTabPro(RAPackageManager:getChoosenTab())
    self:initPkgTips()
end

function RAPackageUIPage:initPkgTips()
    self:randomUpdatePkgTips()
    local scheduleUpdateFun = function()
        self:randomUpdatePkgTips()
    end
    self.ccbfile:stopAllActions()
    schedule(self.ccbfile,scheduleUpdateFun, 10)    
end

--------------------------------------------------------------
-----------------------刷新数据-------------------------------
--------------------------------------------------------------

--随机设置tips
function RAPackageUIPage:randomUpdatePkgTips()
    local randomLen = #itemtips_conf
    local ra = math.random(1, randomLen)
    local tipsStr = itemtips_conf[ra]
    UIExtend.setCCLabelString(self.ccbfile,"mPackageTipsLabel", _RALang(tipsStr.tips))
end

--刷新选中属性
function RAPackageUIPage:refreshChoosenTabPro(index)
    RAPackageUIPage:changeTabHandler(index)
    local data = RAPackageManager:getChoosenData()
    RAPackageUIPage:pushCellToScrollView(data)
end

--data:结构由1个itemTable组成
function RAPackageUIPage:pushCellToScrollView(data)
    local isv = false
    if not next(data) then
        isv = true
    end
    
    UIExtend.setNodeVisible(self.ccbfile,"mEmptyLabel",isv)
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        local ccbiStr = "RAPackageItemCellNew.ccbi"
        cell:setCCBFile(ccbiStr)
        local panel = RAPackageCellPage:new({
                mData = v,
                mTag  = k
        })
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end

    scrollView:orderCCBFileCells()
    if RAPackageManager.mIsRememberPkgOffset and nil ~= self.scrollViewContentOffset then
        local x, y = self.scrollViewContentOffset.x, self.scrollViewContentOffset.y
        local nowSVContentHeight = scrollView:getContentSize().height
        local oldSVContentHeight = self.scrollViewContentSize.height
        local offsetPoint = self.scrollViewContentOffset
        offsetPoint.y = offsetPoint.y + oldSVContentHeight - nowSVContentHeight
        scrollView:setContentOffset(offsetPoint)
        RAPackageManager.mIsRememberPkgOffset = false
    end
end


--------------------------------------------------------------
-----------------------消息处理-------------------------------
--------------------------------------------------------------
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_package.MSG_package_push_item then
    elseif message.messageID == MessageDef_package.MSG_package_consume_item then
    elseif message.messageID == MessageDef_package.MSG_package_refresh_data then
        RAPackageUIPage:refreshChoosenTabPro(RAPackageManager:getChoosenTab())
    elseif message.messageID == MessageDef_package.MSG_package_remember_sv_offset then
        RAPackageUIPage.scrollViewContentOffset = RAPackageUIPage.scrollView:getContentOffset()
        RAPackageUIPage.scrollViewContentSize = RAPackageUIPage.scrollView:getContentSize()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
        if opcode == HP_pb.ITEM_USE_C then 
            RARootManager.ShowMsgBox('@useSuccessful')
        end
    end
end

--注册监听消息
function RAPackageUIPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_refresh_data, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_remember_sv_offset, OnReceiveMessage)
end

function RAPackageUIPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_package.MSG_package_refresh_data, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_package.MSG_package_remember_sv_offset, OnReceiveMessage)
end


--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--点击随机更换提示内容
function RAPackageUIPage:onChangeBtn()
    self:initPkgTips()
end
--
function RAPackageUIPage:onAllBtn()
    RAPackageUIPage:clickTabBtn(RAPackageData.PACKAGE_CHOOSEN_TAB.allTab)
end

function RAPackageUIPage:onAccelerateBtn()
    RAPackageUIPage:clickTabBtn(RAPackageData.PACKAGE_CHOOSEN_TAB.accelerateTab)
end

function RAPackageUIPage:onConditionBtn()
    RAPackageUIPage:clickTabBtn(RAPackageData.PACKAGE_CHOOSEN_TAB.conditionTab)
end

function RAPackageUIPage:onSpecialBtn()
    RAPackageUIPage:clickTabBtn(RAPackageData.PACKAGE_CHOOSEN_TAB.specialTab)
end

function RAPackageUIPage:onResourcesBtn()
    RAPackageUIPage:clickTabBtn(RAPackageData.PACKAGE_CHOOSEN_TAB.resourcesTab)
end

function RAPackageUIPage:clickTabBtn(index)
    if RAPackageManager:getChoosenTab() == index then
        self:changeTabHandler(index)
        return
    end

    RAPackageManager:setChoosenTab(index)
    RAPackageUIPage:refreshChoosenTabPro(index)
end

--按钮，sv显示处理
function RAPackageUIPage:changeTabHandler(index)
    local hightLightVec = {}
	for i=1,#self.btnVec do
		hightLightVec[i] = false
    	if i == (1+index) then
    		hightLightVec[i] = true
    	end
	end

    self:resetToggleButton(index)
    UIExtend.setControlButtonSelected(self.ccbfile,{
            mAllBtn = hightLightVec[1],
            mAccelerateBtn = hightLightVec[2],
            mConditionBtn = hightLightVec[3],
            mResourcesBtn = hightLightVec[4],
            mSpecialBtn = hightLightVec[5]
        })
end

function RAPackageUIPage:resetToggleButton(releaseIndex)
    for i,v in pairs(self.higtLight) do
        self.higtLight[i]:setVisible((releaseIndex+1) == i)
    end 
end