--装备详情页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAEquipManager =RARequire("RAEquipManager")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAEquipUpgradePage = BaseFunctionPage:new(...)
local HP_pb = RARequire("HP_pb")
local Equipment_pb = RARequire("Equipment_pb")
local RANetUtil = RARequire("RANetUtil")
local RAResManager = RARequire("RAResManager")
local RALogicUtil = RARequire("RALogicUtil")
local item_conf = RARequire("item_conf")
local RAPackageData = RARequire("RAPackageData")

local TAB_TYPE = {
	UPGRADE = 1,	--强化
	ADV		= 2,	--进阶
}

local currentEquipUUID = ""
local currentInterval         = 0

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
        local qualityIcon = RALogicUtil:getItemBgByColor(quality)
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
        UIExtend.addSpriteToNodeParent(ccbfile, "mQualityNode", qualityIcon)
    end
end

---------------------------------------------------

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.ITEM_BUY_C then --购买成功
           RARootManager.ShowMsgBox('@buySuccessful')
           RAEquipUpgradePage:refreshItem(RAEquipUpgradePage.curPageType,false)

           local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
           local data = {
                equip = {part = serverEquipInfo.part,uuid = currentEquipUUID,isAdv = false}
            }
           MessageManager.sendMessage(MessageDef_Equip.MSG_Equip_Changed,data)
        elseif message.opcode == HP_pb.EQUIPMENT_LEVELUP_C then --装备强化成功
            local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
            serverEquipInfo.level = serverEquipInfo.level + 1

            if currentInterval == 0 then
                currentInterval = os.time()
                RAEquipUpgradePage:runAnimation("Continuous")
                local preCell = RAEquipUpgradePage.scrollView:getSelectedCell()
                if preCell then
                    local ccbiCell = preCell:getCCBFileNode()
                    if ccbiCell then
                        ccbiCell:runAnimation("Work")
                    end
                end
            end

            --点击强化及进阶按键
            local common = RARequire("common")
            common:playEffect("clickEquipPush")

            RARootManager.ShowMsgBox("@EquipLevelUPSuccess")
            RAEquipUpgradePage:setCurrentPage(RAEquipUpgradePage.curPageType)

            local data = {
                equip = {part = serverEquipInfo.part,uuid = currentEquipUUID,isAdv = false}
            }
            MessageManager.sendMessage(MessageDef_Equip.MSG_Equip_Changed,data)

            local RALordMainPage = RARequire("RALordMainPage")
            RALordMainPage:refreshEquip()
        end 
    end 
end

function RAEquipUpgradePage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAEquipUpgradePage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAEquipUpgradePage:initPageData(equip)
    self.equip = equip
    self.part = self.equip.part
    self.uuid = self.equip.uuid
    self.pageType = self.curPageType or 1
end

function RAEquipUpgradePage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAEquipUpgradePage.ccbi",self)
    self:initPageData(data.equip)
    self.pageType = data.pageType
    --top info
    self:initTitle()

    self:registerMessage()
    self:RegisterPacketHandler(HP_pb.EQUIPMENT_ENHANCE_S)
    --self:RegisterPacketHandler(HP_pb.EQUIPMENT_LEVELUP_S)

    self.mCellSVNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mCellNode")

    local size = CCSizeMake(0, 0)
    if self.mCellSVNode then
        size = self.mCellSVNode:getContentSize()
    end
    self.scrollView = CCSelectedScrollView:create(size)
    self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
    UIExtend.addNodeToParentNode(self.ccbfile, "mCellNode", self.scrollView)

    --初始化标签按钮
    self:initBtn()

    self:showAllEquip()

    --animation action
    self:runAnimation("Enter")
end

function RAEquipUpgradePage:runAnimation(actionName)
    for i = 1,4 do
        self.ccbfile:getCCBFileFromCCB("mRobotAniCCB"..i):runAnimation(actionName)
    end
end

function RAEquipUpgradePage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == "mRobotAniCCB4_Enter" then
        self:runAnimation("Idle")
    elseif lastAnimationName == "mRobotAniCCB4_Start" then
        self:runAnimation("Continuous")
    elseif lastAnimationName == "mRobotAniCCB4_Continuous" then
        self:runAnimation("Return")
    elseif lastAnimationName == "mRobotAniCCB4_Return" then
        currentInterval = 0
    end    
end

function RAEquipUpgradePage:initBtn()
	self.tabArr = {} --2个分页签
	self.tabArr[TAB_TYPE.UPGRADE] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mTabBtn1')
	self.tabArr[TAB_TYPE.ADV] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mTabBtn2')
end

function RAEquipUpgradePage:showAllEquip()
    self.scrollView:removeAllCell()
    local equips = RAEquipManager:getServerEquips()
    for k, equipInfo in ipairs(equips) do
        local equipIconCell = EquipIconCell:new({uuid = equipInfo.uuid})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAEquipUpgradeCell.ccbi")
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

    self:setCurrentPage(self.pageType)

end

--设置当前Page
function RAEquipUpgradePage:setCurrentPage(pageType)

	self.curPageType = pageType

    for k,v in ipairs(self.tabArr) do
        if pageType == k then 
			v:setEnabled(false)
		else
			v:setEnabled(true)
		end  
    end
    
    self:refreshPublicUI()    
    if pageType == TAB_TYPE.UPGRADE then    --强化
        self:refreshUpgradeUI()            
   	else                                    --进阶
   		self:refreshAdvUI()
	end 
end

function RAEquipUpgradePage:refreshPublicUI()
    
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    --装备名字
    UIExtend.setStringForLabel(self.ccbfile,{mItemName = _RALang(equipInfo.name)})
    UIExtend.setColorForLabel(self.ccbfile, {mItemName = RALogicUtil:getLabelNameColor(equipInfo.quality)})

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

    --按钮是强化还是进阶
    if self.curPageType == TAB_TYPE.UPGRADE then
        UIExtend.setControlButtonTitle(self.ccbfile, "mStrengthenBtn", _RALang("@StrengthenTxt"))
    else
        UIExtend.setControlButtonTitle(self.ccbfile, "mStrengthenBtn", _RALang("@AdvancedTxt"))
    end
end

--
function RAEquipUpgradePage:refreshItem(pageType,isMax)
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    --当前强化属性
    local currLevel = serverEquipInfo.level
    local material
    if pageType == TAB_TYPE.UPGRADE then
        material = RAEquipManager:getNeedMaterialByLevel(equipInfo.tpye,currLevel)
    else
        material = RAEquipManager:getEvoMaterialById(currentEquipUUID)
    end
    --强化所需要材料
    for i =1,4 do
        UIExtend.setNodesVisible(self.ccbfile,{['mNeedMatNode'..i] = false})
    end

    UIExtend.setNodesVisible(self.ccbfile,{['mStrengthenBtn'] = true})
    if isMax then  --最高级了，不需要显示下面的材料能进阶按钮了
        UIExtend.setNodesVisible(self.ccbfile,{['mStrengthenBtn'] = false})
        return
    end

    for i = 1,#material do
        UIExtend.setNodesVisible(self.ccbfile,{['mNeedMatNode'..i] = true})
        --
        local itemId = material[i].id
        local type = material[i].type
        local count = material[i].count
        local icon, name = RAResManager:getIconByTypeAndId(type, itemId)
        UIExtend.addSpriteToNodeParent(self.ccbfile, 'mNeedMatIconNode'..i, icon)

        local data = item_conf[itemId]
        RAPackageData.setNumTypeInItemIcon(self.ccbfile, "mResFaceValue"..i, "mResFaceValue"..i, data )--显示数字类型
       
        local itemConf = item_conf[itemId]
        local bgName  = RALogicUtil:getItemBgByColor(itemConf.item_color)
        UIExtend.addSpriteToNodeParent(self.ccbfile, 'mQualityNode'..i, bgName)
        local needResNumStr
        local selfItemCount = RACoreDataManager:getItemCountByItemId(itemId)
        if selfItemCount >= count then
            needResNumStr = RAStringUtil:fill(html_zh_cn["ItemEnough"],selfItemCount,count) 
        else
            needResNumStr = RAStringUtil:fill(html_zh_cn["ItemNotEnough"],selfItemCount,count) 
        end
        local abilityLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mNeedResNum"..i)
        abilityLabelHtml:setString(needResNumStr)
    end
end

--
function RAEquipUpgradePage:refreshUpgradeUI()
    UIExtend.setNodesVisible(self.ccbfile,{mStrengthenDataNode = true})
    UIExtend.setNodesVisible(self.ccbfile,{mEvolutionDataNode = false})

    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    --当前强化属性
    local currLevel = serverEquipInfo.level
    local isEquipMaxLevel = false
    local equipMaxLevel = RAEquipManager:getEquipLevelMax()
    if currLevel >= equipMaxLevel then
        UIExtend.setNodesVisible(self.ccbfile,{mStrRightNode = false})
        local strLeftNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mStrLeftNode")
        if strLeftNode then
            strLeftNode:setPositionX(90)
        end
        isEquipMaxLevel = true
    else
        UIExtend.setNodesVisible(self.ccbfile,{mStrRightNode = true})
        local strLeftNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mStrLeftNode")
        if strLeftNode then
            strLeftNode:setPositionX(-90)
        end
    end
--------------------------------当前等级强化的属性------------------------------------------------------------
    --装备等级
    if isEquipMaxLevel then    --满级
        UIExtend.setStringForLabel(self.ccbfile,{mStrCurrentLevel = currLevel.._RALang("@LevelAlreadyMax")})
        UIExtend.setColorForLabel(self.ccbfile, {mStrCurrentLevel = ccc3(225,225,0)})
    else
        UIExtend.setStringForLabel(self.ccbfile,{mStrCurrentLevel = currLevel})
        UIExtend.setColorForLabel(self.ccbfile, {mStrCurrentLevel = ccc3(222,207,178)})
    end
    --战斗力
    local currFightValue = equipInfo.initialBattlePoint + equipInfo.battlePointGrow * (currLevel -1)
    local currFightValueStr = Utilitys.formatNumber(currFightValue)
    UIExtend.setStringForLabel(self.ccbfile,{mStrCurrentFightValue = currFightValueStr})
    
    --属性名称
    UIExtend.setStringForLabel(self.ccbfile,{mStrAbilityLabel = _RALang(equipInfo.attributeName)})

    --numType = 1 有%号
    local currAttributeStr
    local currAttribute
    if equipInfo.numType == 1 then
        currAttribute = (equipInfo.initialAttribute + equipInfo.attributeGrow * (currLevel -1))/100
        currAttributeStr = currAttribute.."%"
    else
        currAttribute = equipInfo.initialAttribute + equipInfo.attributeGrow * (currLevel -1)
        currAttributeStr = currAttribute
    end

    UIExtend.setStringForLabel(self.ccbfile,{mStrCurrentAbilityNum = currAttributeStr})

---------------------------------下一等级强化的属性------------------------------------------------------------
    --装备等级
    local nextLevel = currLevel+1
    local levelDesStr = RAStringUtil:fill(html_zh_cn["EquipStrengthenLevel"],nextLevel,(nextLevel - currLevel)) 
    local levelLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mStrNextLevel")
    levelLabelHtml:setString(levelDesStr)

    --战斗力
    local nextFightValue= equipInfo.initialBattlePoint + equipInfo.battlePointGrow * (currLevel)
    local nextFightValueStr = Utilitys.formatNumber(nextFightValue)
    local diffFightValue = nextFightValue - currFightValue
    local diffFightValueStr = Utilitys.formatNumber(diffFightValue)
    local fightDesStr = RAStringUtil:fill(html_zh_cn["EquipStrengthenFightValue"],nextFightValueStr,diffFightValueStr)
    local fightLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mStrNextFightValue")
    fightLabelHtml:setString(fightDesStr)

    --numType = 1 有%号
    local nextAttributeStr
    local nextAttribute
    local diffAttributeStr
    if equipInfo.numType == 1 then
        nextAttribute = (equipInfo.initialAttribute + equipInfo.attributeGrow * currLevel)/100
        nextAttributeStr = nextAttribute.."%%"
        diffAttributeStr = nextAttribute - currAttribute
        diffAttributeStr = diffAttributeStr .."%%"
    else
        nextAttribute = equipInfo.initialAttribute + equipInfo.attributeGrow * currLevel
        nextAttributeStr = nextAttribute
        diffAttributeStr = nextAttribute - currAttribute
    end

    local abilityDesStr = RAStringUtil:fill(html_zh_cn["EquipStrengthenAbility"],nextAttributeStr,diffAttributeStr) 
    local abilityLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mStrNextAbilityNum")
    abilityLabelHtml:setString(abilityDesStr)

    --刷新最下面的道具
    self:refreshItem(self.curPageType,isEquipMaxLevel)
end

function RAEquipUpgradePage:refreshAdvUI()
    UIExtend.setNodesVisible(self.ccbfile,{mStrengthenDataNode = false})
    UIExtend.setNodesVisible(self.ccbfile,{mEvolutionDataNode = true})

    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    local currEquipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)

    --当前强化属性
    local currLevel = serverEquipInfo.level
    --当前强化属性
    local currAdvNumber = RAEquipManager:getAdvNumberById(serverEquipInfo.equipId)
    --进阶最大值
    local equipMaxQuality = RAEquipManager:getEquipMaxQualityMax()

---------------------------------当前等级进阶的属性------------------------------------------------------------
    --装备阶等级
    if currAdvNumber >= equipMaxQuality then    --满级
        UIExtend.setStringForLabel(self.ccbfile,{mEvoCurrentLevel = currAdvNumber.._RALang("@EnchantAlreadyMax")})
        UIExtend.setColorForLabel(self.ccbfile, {mEvoCurrentLevel = ccc3(225,225,0)})
    else
        UIExtend.setStringForLabel(self.ccbfile,{mEvoCurrentLevel = currAdvNumber})
        UIExtend.setColorForLabel(self.ccbfile, {mEvoCurrentLevel = ccc3(222,207,178)})
    end
    
    --战斗力
    local currFightValue = currEquipInfo.initialBattlePoint + currEquipInfo.battlePointGrow * (currLevel -1)
    local currFightValueStr = Utilitys.formatNumber(currFightValue)
    UIExtend.setStringForLabel(self.ccbfile,{mEvoCurrentFightValue = currFightValueStr})
    
    --属性名称
    UIExtend.setStringForLabel(self.ccbfile,{mEvoAbilityLabel = _RALang(currEquipInfo.attributeName)})

    --numType = 1 有%号
    local currAttributeStr
    local currAttribute
    if currEquipInfo.numType == 1 then
        currAttribute = (currEquipInfo.initialAttribute + currEquipInfo.attributeGrow * (currLevel -1))/100
        currAttributeStr = currAttribute.."%"
    else
        currAttribute = currEquipInfo.initialAttribute + currEquipInfo.attributeGrow * (currLevel -1)
        currAttributeStr = currAttribute
    end

    UIExtend.setStringForLabel(self.ccbfile,{mEvoCurrentAbilityNum = currAttributeStr})

---------------------------------下一等级强化的属性------------------------------------------------------------
    local nextEquipInfo = RAEquipManager:getConfEquipInfoById(tostring(currEquipInfo.targetID))
    if nextEquipInfo then
        --下一阶装备阶等级
        local nextAdvNumber = RAEquipManager:getAdvNumberById(nextEquipInfo.id)
        local levelDesStr = RAStringUtil:fill(html_zh_cn["EquipEvoLevel"],nextAdvNumber,(nextAdvNumber - currAdvNumber)) 
        local levelLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mEvoNextLevel")
        levelLabelHtml:setString(levelDesStr)

        --战斗力
        local nextFightValue= nextEquipInfo.initialBattlePoint + nextEquipInfo.battlePointGrow * (currLevel - 1)
        local nextFightValueStr = Utilitys.formatNumber(nextFightValue)
        local diffFightValue = nextFightValue - currFightValue
        local diffFightValueStr = Utilitys.formatNumber(diffFightValue)
        local fightDesStr = RAStringUtil:fill(html_zh_cn["EquipEvoFightValue"],nextFightValueStr,diffFightValueStr)
        local fightLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mEvoNextFightValue")
        fightLabelHtml:setString(fightDesStr)

        local nextAttributeStr
        local nextAttribute
        local diffAttributeStr
        if nextEquipInfo.numType == 1 then
            nextAttribute = (nextEquipInfo.initialAttribute + nextEquipInfo.attributeGrow * (currLevel - 1))/100
            nextAttributeStr = nextAttribute.."%%"
            diffAttributeStr = nextAttribute - currAttribute
            diffAttributeStr = diffAttributeStr .."%%"
        else
            nextAttribute = nextEquipInfo.initialAttribute + nextEquipInfo.attributeGrow * (currLevel -1)
            nextAttributeStr = nextAttribute
            diffAttributeStr = nextAttribute - currAttribute
        end

        local abilityDesStr = RAStringUtil:fill(html_zh_cn["EquipEvoAbility"],nextAttributeStr,diffAttributeStr) 
        local abilityLabelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mEvoNextAbilityNum")
        abilityLabelHtml:setString(abilityDesStr)
    end

    --进阶进度
    local enchantCurrValue = serverEquipInfo.point
    local enchantMaxValue = currEquipInfo.requestPoint

    local mBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
    local scale = enchantCurrValue/enchantMaxValue
    if scale > 1 then
        scale = 1
    end
    mBar:setScaleX(scale)

    local isEquipMaxQuality = false
    if currAdvNumber >= equipMaxQuality then    --满级
        UIExtend.setNodesVisible(self.ccbfile,{mEvoRightNode = false})
        local evoLeftNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mEvoLeftNode")
        if evoLeftNode then
            evoLeftNode:setPositionX(90)
        end
        mBar:setVisible(false)
        UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mMaxBar"):setVisible(true)
        UIExtend.setStringForLabel(self.ccbfile,{mBarNum = _RALang("@EnchantMaxTxt")})

        isEquipMaxQuality = true
    else    
        mBar:setVisible(true)
        UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mMaxBar"):setVisible(false)
        UIExtend.setStringForLabel(self.ccbfile,{mBarNum = enchantCurrValue.."/"..enchantMaxValue})
    end

    --刷新最下面的道具
    self:refreshItem(self.curPageType,isEquipMaxQuality)
end

function RAEquipUpgradePage:showStoreBuyItem(index)
    local equipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
    local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    --当前强化属性
    local currLevel = serverEquipInfo.level
    local material
    if self.curPageType == TAB_TYPE.UPGRADE then
        material = RAEquipManager:getNeedMaterialByLevel(equipInfo.tpye,currLevel)
    else
        material = RAEquipManager:getEvoMaterialById(currentEquipUUID)
    end
    
    local itemId = material[index].id
    local itemConf = item_conf[itemId]
    local itemData = Utilitys.deepCopy(itemConf)
	itemData.optionType = 1
    local itemStoreData = RAEquipManager:getStoreDataById(itemId)
    if itemStoreData then
	    itemData.shopId     = itemStoreData.id
	    itemData.price      = itemStoreData.price
	    RARootManager.showPackageInfoPopUp(itemData)
    else
        RARootManager.ShowMsgBox("@ItemNotBuy")
    end
end

function RAEquipUpgradePage:onCheckResBtn1()
    self:showStoreBuyItem(1)
end

function RAEquipUpgradePage:onCheckResBtn2()
    self:showStoreBuyItem(2)
end

function RAEquipUpgradePage:onCheckResBtn3()
    self:showStoreBuyItem(3)
end

function RAEquipUpgradePage:onCheckResBtn4()
    self:showStoreBuyItem(4)
end

--end

--on button
function RAEquipUpgradePage:onNextBtn()
    self.scrollView:moveCellByDirection(1)
end

function RAEquipUpgradePage:onPreviousBtn()
    self.scrollView:moveCellByDirection(-1)
end

function RAEquipUpgradePage:onTabBtn1()
    self:setCurrentPage(TAB_TYPE.UPGRADE)
end

function RAEquipUpgradePage:onTabBtn2()
    self:setCurrentPage(TAB_TYPE.ADV)
end

--强化 or 进阶
function RAEquipUpgradePage:onStrengthenBtn()
    if self.curPageType == TAB_TYPE.UPGRADE then
        local result,txt = RAEquipManager:getIsUPorEvoById(currentEquipUUID,1)
        if false == result and txt ~= "" then
            RARootManager.ShowMsgBox(_RALang(txt))
        else
            self:sendEquipLevelUpReq(currentEquipUUID)
        end
    else
        local result,txt = RAEquipManager:getIsUPorEvoById(currentEquipUUID,2)
        if false == result and txt ~= "" then
            RARootManager.ShowMsgBox(_RALang(txt))
        else
            self:sendEquipEnhanceReq(currentEquipUUID)
        end
    end
end

--强化
function RAEquipUpgradePage:sendEquipLevelUpReq(uuid)
    local cmd = Equipment_pb.HPEquipLevelUpReq()
    cmd.uuid = uuid
    RANetUtil:sendPacket(HP_pb.EQUIPMENT_LEVELUP_C, cmd)
end

--进阶
function RAEquipUpgradePage:sendEquipEnhanceReq(uuid)
    --点击强化及进阶按键
    local common = RARequire("common")
    common:playEffect("clickEquipPush")
            
    local cmd = Equipment_pb.HPEquipLevelUpReq()
    cmd.uuid = uuid
    RANetUtil:sendPacket(HP_pb.EQUIPMENT_ENHANCE_C, cmd)
end


function RAEquipUpgradePage:scrollViewSelectNewItem(cell)
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

        local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
        local data = {
            equip = {part = serverEquipInfo.part,uuid = currentEquipUUID,isAdv = true}
        }
        MessageManager.sendMessage(MessageDef_Equip.MSG_Equip_Changed,data)

        --刷新页面
        self:setCurrentPage(self.curPageType)
    end
end

function RAEquipUpgradePage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --todo播放放大动画
    end
end

function RAEquipUpgradePage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RAEquipUpgradePage:scrollViewPreItem(cell)
	print("RAEquipUpgradePage:scrollViewPreItem")
end

function RAEquipUpgradePage:scrollViewChangeItem(cell)
	print("RAEquipUpgradePage:scrollViewChangeItem")
end

function RAEquipUpgradePage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@EquipUpgradeTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAEquipUpgradePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAEquipUpgradePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    -- if pbCode == HP_pb.EQUIPMENT_LEVELUP_S then  --装备强化成功
    --     local msg = Equipment_pb.HPEquipLevelUpResp()
    --     msg:ParseFromString(buffer)
    --     if msg.result then
    --         local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)
    --         serverEquipInfo.level = serverEquipInfo.level + 1

    --         if currentInterval == 0 then
    --             currentInterval = os.time()
    --             self:runAnimation("Continuous")
    --             local preCell = self.scrollView:getSelectedCell()
    --             if preCell then
    --                 local ccbiCell = preCell:getCCBFileNode()
    --                 if ccbiCell then
    --                     ccbiCell:runAnimation("Work")
    --                 end
    --             end
    --         end

    --         --点击强化及进阶按键
    --         local common = RARequire("common")
    --         common:playEffect("clickEquipPush")

    --         RARootManager.ShowMsgBox("@EquipLevelUPSuccess")
    --         self:setCurrentPage(self.curPageType)

    --         local data = {
    --             equip = {part = serverEquipInfo.part,uuid = currentEquipUUID,isAdv = false}
    --         }
    --         MessageManager.sendMessage(MessageDef_Equip.MSG_Equip_Changed,data)

    --         local RALordMainPage = RARequire("RALordMainPage")
    --         RALordMainPage:refreshEquip()
    --     end
    if pbCode == HP_pb.EQUIPMENT_ENHANCE_S then --装备进阶成功
        local msg = Equipment_pb.HPEquipEnhanceResp()
        msg:ParseFromString(buffer)
        if msg.result then
            if msg.point == 0 then  --进阶成功
                RARootManager.ShowMsgBox("@EquipAdvSuccess")

                --进阶成功
                local common = RARequire("common")
                common:playEffect("qualityUpSuccess")

                --local confEquipInfo = RAEquipManager:getConfEquipInfoById(currentEquipUUID)
                local equip = RAEquipManager:getServerEquipInfoByPart(self.part)
                self:initPageData(equip)
                self:showAllEquip()

                if currentInterval == 0 then
                    currentInterval = os.time()
                    self:runAnimation("Continuous")
                    local preCell = self.scrollView:getSelectedCell()
                    if preCell then
                        local ccbiCell = preCell:getCCBFileNode()
                        if ccbiCell then
                            ccbiCell:runAnimation("Work")
                        end
                    end
                end

                local data = {
                    equip = {part = equip.part,uuid = equip.uuid,isAdv = true}
                }

                MessageManager.sendMessage(MessageDef_Equip.MSG_Equip_Changed,data)                
            else                    --增加进阶点
                local serverEquipInfo = RAEquipManager:getServerEquipInfoById(currentEquipUUID)

                if currentInterval == 0 then
                    currentInterval = os.time()
                    self:runAnimation("Continuous")
                    local preCell = self.scrollView:getSelectedCell()
                    if preCell then
                        local ccbiCell = preCell:getCCBFileNode()
                        if ccbiCell then
                            ccbiCell:runAnimation("Work")
                        end
                    end
                end

                --进阶暴击
                if (msg.point - serverEquipInfo.point) >= 5 then 
                    local common = RARequire("common")
                    common:playEffect("qualityUpCrit")
                end

                serverEquipInfo.point = msg.point
                RARootManager.ShowMsgBox("@AddEquipAdvPoint")
                self:setCurrentPage(self.curPageType)
            end
        end

        local RALordMainPage = RARequire("RALordMainPage")
        RALordMainPage:refreshEquip()
    end


end

function RAEquipUpgradePage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAEquipUpgradePage")
    self:removeMessageHandler()
    self:RemovePacketHandlers()
    self.scrollView:unregisterFunctionHandler()
    self.scrollView:removeAllCell()
    self.scrollView = nil
    if self.mCellSVNode then
        self.mCellSVNode:removeAllChildren()
    end
    UIExtend.unLoadCCBFile(self)
    currentInterval = 0
    self.ccbfile = nil
end

return RAEquipUpgradePage