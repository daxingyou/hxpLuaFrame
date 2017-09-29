--装备详情页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAEquipManager =RARequire("RAEquipManager")
local Utilitys = RARequire("Utilitys")
local RALogicUtil = RARequire("RALogicUtil")

local RAEquipInfoPage = BaseFunctionPage:new(...)

local currentEquipUUID = ""

---------------------------------cell--------------
local EquipIconCell = {}

function EquipIconCell:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function EquipIconCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local equipInfo = RAEquipManager:getConfEquipInfoById(self.uuid)
    if equipInfo then
        local icon = equipInfo.icon
        local quality = equipInfo.quality
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
        --local qualityIcon = RALogicUtil:getItemBgByColor(quality)
        --UIExtend.addSpriteToNodeParent(ccbfile, "mQualityNode", qualityIcon)
    end
end

---------------------------------------------------

local OnReceiveMessage = function(message)    
    CCLuaLog("RAEquipInfoPage OnReceiveMessage id:"..message.messageID)
    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_Equip.MSG_Equip_Changed then
        if message.equip then
            if message.equip.isAdv then
                RAEquipInfoPage:initPageData(message.equip)
                RAEquipInfoPage:showAllEquip()
            else
                RAEquipInfoPage:refreshPage()
            end
        end
    end
end

function RAEquipInfoPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Equip.MSG_Equip_Changed, OnReceiveMessage)
end

function RAEquipInfoPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Equip.MSG_Equip_Changed, OnReceiveMessage) 
end

function RAEquipInfoPage:initPageData(equip)
    self.equip = equip
    self.part = self.equip.part
    self.uuid = self.equip.uuid
end

function RAEquipInfoPage:Enter(equip)
	local ccbfile = UIExtend.loadCCBFile("RAEquipMainPage.ccbi",self)

    self:initPageData(equip)

    self:registerMessageHandlers()

    self.equipMainListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mEquipMainListSV")
    --top info
    self:initTitle()

    self.mCellSVNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mCellNode")

    local size = CCSizeMake(0, 0)
    if self.mCellSVNode then
        size = self.mCellSVNode:getContentSize()
    end
    self.scrollView = CCSelectedScrollView:create(size)
    self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
    UIExtend.addNodeToParentNode(self.ccbfile, "mCellNode", self.scrollView)

    self:showAllEquip()

end

function RAEquipInfoPage:showAllEquip()
    self.scrollView:removeAllCell()
    local equips = RAEquipManager:getServerEquips()
    for k, equipInfo in ipairs(equips) do
        local equipIconCell = EquipIconCell:new({uuid = equipInfo.uuid})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAEquipMainCell.ccbi")
        cell:registerFunctionHandler(equipIconCell)
        cell:setCellTag(equipInfo.part)
        self.scrollView:addCellBack(cell)
        if self.uuid == equipInfo.uuid then
            self.scrollView:setSelectedCell(cell)
            currentEquipUUID = equipInfo.uuid
            cell:setScale(1)
        end
    end
    self.scrollView:registerFunctionHandler(self)
    self.scrollView:orderCCBFileCells()
	self.scrollView:getSelectedCell():locateTo(CCBFileCell.LT_Mid);

    self:refreshPage()
end

function RAEquipInfoPage:refreshPage()
    self:refreshPageUI()
    self:addCell()
end

-------------------cell---------------------
--------------------------------------------------强化
local RAEquipMainStrCell = {}
function RAEquipMainStrCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAEquipMainStrCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    local currLevel = serverEquipInfo.level

    --是否可以升级图标
    local result,txt = RAEquipManager:getIsUPorEvoById(currentEquipUUID,1)
    UIExtend.setNodesVisible(ccbfile,{mCanStrengthenPic = result})

    --装备等级
    UIExtend.setStringForLabel(ccbfile,{mLevel = currLevel})
    --战斗力
    local fightValue= equipInfo.initialBattlePoint + equipInfo.battlePointGrow * (currLevel -1)
    UIExtend.setStringForLabel(ccbfile,{mFightNumValue = tostring(fightValue)})
    --属性
    UIExtend.setStringForLabel(ccbfile,{mAbilityLabel = _RALang(equipInfo.attributeName)})

    --numType = 1 有%号
    local fightValueStr
    if equipInfo.numType == 1 then
        local fightValue = (equipInfo.initialAttribute + equipInfo.attributeGrow * (currLevel -1))/100
        fightValueStr = "+"..fightValue.."%"
    else
        local fightValue = equipInfo.initialAttribute + equipInfo.attributeGrow * (currLevel -1)
        fightValueStr = "+"..fightValue
    end

    UIExtend.setStringForLabel(ccbfile,{mAbilityNum = fightValueStr})
end

--强化
function RAEquipMainStrCell:onStrengthenBtn()
    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local data = {
        equip = serverEquipInfo,
        pageType = 1
    }
    RARootManager.OpenPage("RAEquipUpgradePage",data)
end

--------------------------------------------------进阶
local RAEquipMainEvoCell = {}
function RAEquipMainEvoCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAEquipMainEvoCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    local enchantCurrValue = serverEquipInfo.point

    --是否可以升级图标
    local result,txt = RAEquipManager:getIsUPorEvoById(currentEquipUUID,2)
    UIExtend.setNodesVisible(ccbfile,{mCanStrengthenPic = result})
    --进阶进度
    local enchantMaxValue = equipInfo.requestPoint

    local mBar = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBar")
    local scale = enchantCurrValue/enchantMaxValue
    if scale > 1 then
        scale = 1
    end
    if mBar then
        mBar:setScaleX(scale)
    end

     --当前强化属性
    local currAdvNumber = RAEquipManager:getAdvNumberById(serverEquipInfo.equipId)
    --进阶最大值
    local equipMaxQuality = RAEquipManager:getEquipMaxQualityMax()

    if currAdvNumber >= equipMaxQuality then    --满级
        UIExtend.setStringForLabel(ccbfile,{mBarNum = _RALang("@EnchantMaxTxt")})
        mBar:setVisible(false)
        UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mMaxBar"):setVisible(true)
    else    
        UIExtend.setStringForLabel(ccbfile,{mBarNum = enchantCurrValue.."/"..enchantMaxValue})
        mBar:setVisible(true)
        UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mMaxBar"):setVisible(false)
    end
end

--进阶
function RAEquipMainEvoCell:onAdvancedBtn()
    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local data = {
        equip = serverEquipInfo,
        pageType = 2
    }
    RARootManager.OpenPage("RAEquipUpgradePage",data)
end

-------------------end cell

--------------------------------------------------嵌入
local RAEquipMainInleyCell = {}
function RAEquipMainInleyCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAEquipMainInleyCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
end
-------------------end cell

function RAEquipInfoPage:addCell()
    self.equipMainListSV:removeAllCell()
    local equipMainListSV = self.equipMainListSV
    local equipUpgradeType = RAEquipManager:getEquipUpgradeType() or {}
    for k,v in pairs(equipUpgradeType) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(v..".ccbi")
        local panel
        if v == "RAEquipMainStrCell" then
            panel = RAEquipMainStrCell:new({
    	        mTag = k
            })
        elseif v == "RAEquipMainEvoCell" then  
            panel = RAEquipMainEvoCell:new({
    	        mTag = k
            })
        elseif v == "RAEquipMainInleyCell" then
        	panel = RAEquipMainInleyCell:new({
    	        mTag = k
            })  	  
        end
        cell:registerFunctionHandler(panel)
        equipMainListSV:addCell(cell)
    end
    equipMainListSV:orderCCBFileCells()
end

function RAEquipInfoPage:onNextBtn()
    self.scrollView:moveCellByDirection(1)
end

function RAEquipInfoPage:onPreviousBtn()
    self.scrollView:moveCellByDirection(-1)
end

--刷新页面信息
function RAEquipInfoPage:refreshPageUI()
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)

    --装备名字
    UIExtend.setStringForLabel(self.ccbfile,{mEquipName = _RALang(equipInfo.name)})
    UIExtend.setColorForLabel(self.ccbfile, {mEquipName = RALogicUtil:getLabelNameColor(equipInfo.quality)})

    if equipInfo.part >= 8 then
        UIExtend.setNodesVisible(self.ccbfile,{mNextBtnNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mNextBtnNode = true})
    end

    if equipInfo.part <= 1 then
        UIExtend.setNodesVisible(self.ccbfile,{mPreviousBtnNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mPreviousBtnNode = true})
    end
end

function RAEquipInfoPage:scrollViewSelectNewItem(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --播放缩小动画
            --local scaleSmallAction = CCScaleTo:create(0.2, RAGameConfig.Portrait_Scale, RAGameConfig.Portrait_Scale)
            --preCell:runAction(scaleSmallAction)
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --播放放大动画
        local scaleLargeAction = CCScaleTo:create(0.2, 1, 1)
        cell:runAction(scaleLargeAction)
        local cellTag = cell:getCellTag()
        local equip = RAEquipManager:getServerEquipInfoByPart(cellTag)
        currentEquipUUID = equip.uuid
        --刷新页面
        self:refreshPageUI()
        self:addCell()
    end
end

function RAEquipInfoPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --todo播放放大动画
    end
end

function RAEquipInfoPage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RAEquipInfoPage:scrollViewPreItem(cell)
	print("RAEquipInfoPage:scrollViewPreItem")
end

function RAEquipInfoPage:scrollViewChangeItem(cell)
	print("RAEquipInfoPage:scrollViewChangeItem")
end

function RAEquipInfoPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local RARootManager = RARequire("RARootManager")
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@EquipInfoTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAEquipInfoPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAEquipInfoPage:Exit()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAEquipInfoPage")
    self:unregisterMessageHandlers()
    self.scrollView:unregisterFunctionHandler()
    self.scrollView:removeAllCell()
    self.scrollView = nil
    if self.mCellSVNode then
        self.mCellSVNode:removeAllChildren()
    end
    self.equipMainListSV:removeAllCell()
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAEquipInfoPage