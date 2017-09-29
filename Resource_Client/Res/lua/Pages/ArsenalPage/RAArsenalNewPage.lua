--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RAArsenalManager = RARequire("RAArsenalManager")
local build_conf = RARequire("build_conf")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RAArsenalConfig = RARequire("RAArsenalConfig")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAQueueManager = RARequire("RAQueueManager")
local RAScienceManager = RARequire("RAScienceManager")
local RALogicUtil = RARequire("RALogicUtil")
local Utilitys = RARequire("Utilitys")
local RAPackageData = RARequire("RAPackageData")
local const_conf = RARequire("const_conf")
local RAStringUtil = RARequire("RAStringUtil")
local RAActionManager = RARequire("RAActionManager")
local Army_pb = RARequire("Army_pb")
local RANetUtil = RARequire("RANetUtil")
local RAGuideManager = RARequire("RAGuideManager")
local RAGuideConfig = RARequire("RAGuideConfig")
local RAQueueUtility = RARequire('RAQueueUtility')
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGuideConfig=RARequire("RAGuideConfig")

local mFrameTime = 0
local RAArsenalNewPage = BaseFunctionPage:new(...)

local ActionConfig={
	DownNor="DownNor",
	-- UpPro="UpPro",
	DownPro="DownPro",
	-- UpNor="UpNor",
	KeepNor="KeepNor",
	InAni="InAni"
}

-- local ActionConfig={
-- 	Down="Down",
-- 	UpAni="UpAni",
-- }


local RAArsenalCellListener = {
}

function RAArsenalCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RAArsenalCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
		local armyConf = battle_soldier_conf[self.armyId]
		local icon = armyConf.show
		local nameIcon = armyConf.nameIcon
		local desIcon = armyConf.desIcon
		local mSoldierPic = UIExtend.getCCSpriteFromCCB(ccbfile,"mSoldierPic")
		local mTitle1 = UIExtend.getCCSpriteFromCCB(ccbfile,"mTitle1")
		local mTitle2 = UIExtend.getCCSpriteFromCCB(ccbfile,"mTitle2")
		mSoldierPic:setTexture(icon)
		mTitle1:setTexture(nameIcon)
		mTitle2:setTexture(desIcon)

		--判断是否开启
		local openScienceId = armyConf.openScience
		local flag = true
	    if openScienceId ~= nil then
	        flag = RAScienceManager:isResearchFinish(openScienceId)
	    end

	    UIExtend.setCCSpriteGray(mSoldierPic,not flag)
	    UIExtend.setCCSpriteGray(mTitle1,not flag)

	    local armyInfo = RACoreDataManager:getArmyInfoByArmyId(self.armyId)
	    local curCount = 0 
	    if armyInfo~=nil and armyInfo.freeCount > 0 then
	        curCount = armyInfo.freeCount
	    end
	    UIExtend.setCCLabelBMFontString(ccbfile,"mHaveNum", tostring(curCount))

    end
end


function RAArsenalNewPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RATestProUIPage.ccbi",self)
	self.ccbfile = ccbfile

	self.mArsenalBuildTypeId = data.confData.buildType
	self.mArsenalBuildItemId = data.confData.id
    self.mBuildData = data
    self.mArmyDataTb = {normal={},professional={}}
    self.isFirstOpen = true
    self.isImmediate = false

    self:registerMessageHandlers()
    self:init()

    RAGuideManager.gotoNextStep()

end

function RAArsenalNewPage:createPointsAndBar(  )
	local node = UIExtend.getCCNodeFromCCB(self.ccbfile,"mTipsNode")
	node:removeAllChildren()
	local len = #self.mArmyDataTb.normal
	local beginX = -(len -1)/2 * 40
	local pointBg
	for i = 1, len do
		pointBg = CCSprite:create("TestProUI_u_Tips_Nor.png")
		pointBg:setPosition(ccp(beginX + i*40 - 40, 0))
		node:addChild(pointBg)
	end
	local leftArow = CCSprite:create("TestProUI_u_Arrow.png") 
	leftArow:setScaleX(-1)
	leftArow:setPositionX(beginX - 50)
	node:addChild(leftArow)

	local rightArow = CCSprite:create("TestProUI_u_Arrow.png") 
	rightArow:setPositionX(50 - beginX)	
	node:addChild(rightArow)

	self.curPoint = CCSprite:create("TestProUI_u_Tips_Sel.png")
	node:addChild(self.curPoint)

	self.barSize = {width = 0, height = 0}
    local atkBarNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mAtkBarNode")
    local atkBar = atkBarNode:getChildByTag(10086)
    if atkBar == nil then
    	local atkBarSp = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mAtkBar")
    	self.barSize.width = atkBarSp:getContentSize().width
    	self.barSize.height = atkBarSp:getContentSize().height
        atkBar = CCProgressTimer:create(atkBarSp)
        atkBarNode:addChild(atkBar)
        atkBar:setReverseProgress(true)
        atkBar:setTag(10086)
        atkBarSp:setVisible(false) 
    end
    atkBar:setPercentage(0)
    self.atkBar = atkBar

    local defBarNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mDefBarNode")
    local defBar = defBarNode:getChildByTag(10087)
    if defBar == nil then
    	local defBarSp = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mDefBar")
        defBar = CCProgressTimer:create(defBarSp)
        defBarNode:addChild(defBar)
        defBar:setReverseProgress(true)
        defBar:setTag(10087)
        defBarSp:setVisible(false) 
    end
    defBar:setPercentage(0)
    self.defBar = defBar    
    
    local hpBarNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mHPBarNode")
    local hpBar = hpBarNode:getChildByTag(10088)
    if hpBar == nil then
    	local hpBarSp = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mHPBar")
        hpBar = CCProgressTimer:create(hpBarSp)
        hpBarNode:addChild(hpBar)
        hpBar:setReverseProgress(true)
        hpBar:setTag(10088)
        hpBarSp:setVisible(false) 
    end
    hpBar:setPercentage(0)
    self.hpBar = hpBar       

end

function RAArsenalNewPage:createScrollView()
    self.mCellSVNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mSoldierListNode")

    self.scrollView = self.mCellSVNode:getChildByTag(998)
    local size = CCSizeMake(0, 0)
    if self.mCellSVNode then
        size = self.mCellSVNode:getContentSize()
    end

    if self.scrollView == nil then
        self.scrollView = CCSelectedScrollView:create(size)
        self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
        self.scrollView:setTag(998)
        UIExtend.addNodeToParentNode(self.ccbfile, "mSoldierListNode", self.scrollView)
    end

    self.scrollView:removeAllCell()
    local listener, cell
    for i,armyId in ipairs(self.mArmyDataTb.normal) do
    	listener = RAArsenalCellListener:new({armyId = armyId})
		cell = CCBFileCell:create()
      	cell:setCCBFile("RATestProUICell.ccbi")
        cell:registerFunctionHandler(listener)
        cell:setCellTag(i)
        self.scrollView:addCellBack(cell)       	
    end
    self.scrollView:registerFunctionHandler(self)
    self.scrollView:orderCCBFileCells()
    -- self.scrollView:moveCellByDirection(nowLevel)    
end


function RAArsenalNewPage:scrollViewSelectNewItem(cell)
    if cell then
        local cellTag = cell:getCellTag()
        local preCell = self.scrollView:getSelectedCell()
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 20, 0.2)
        -- self.currArmyId = self.mArmyDataTb.normal[cellTag]
        self:updateInfo(cellTag)
    end
end

function RAArsenalNewPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 20, 0.2)
        --todo播放放大动画
    end
end

function RAArsenalNewPage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 20, 0.2)
    end
end

function RAArsenalNewPage:scrollViewPreItem(cell)
    print("RAArsenalNewPage:scrollViewPreItem")
end

function RAArsenalNewPage:scrollViewChangeItem(cell)
    print("RAArsenalNewPage:scrollViewChangeItem")
end



function RAArsenalNewPage:refreshTitle()
    local txtMap   = {}
    txtMap["mResNum1"]	= RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.GOLDORE))
    txtMap["mResNum2"]	= RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.OIL))
    txtMap["mResNum3"]	= RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.STEEL))
    txtMap["mResNum4"]	= RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.TOMBARTHITE))
    dump(txtMap)
	UIExtend.setStringForLabel(self.ccbfile, txtMap)
end

function RAArsenalNewPage:init()
	self:refreshTitle()
	self:genArmyDatas()
	self:createPointsAndBar() --代表各页面的小点和三项属性的CCProgressTimer
	self:createScrollView() --
	-- self:resetAction()
	self:getLastArmyIndex() --移动SelectScrollView到上次查看的页面
	self:updateInfo() --刷新当前页面的信息 滑动SelectScrollView后会调用
	-- self:showSwithBtn()
	self.isFirstOpen = false
end


function RAArsenalNewPage:showSwithBtn()
	self.isShow=RAArsenalManager:isHaveSpecailArmy(self.mArsenalBuildTypeId)
	-- UIExtend.setNodeVisible(self.ccbfile,"mNoBtnNode",not self.isShow)
	local mCutoverBtnCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCutoverBtnCCB")
	-- UIExtend.setCCControlButtonEnable(mCutoverBtnCCB,"mSwitchingArmsBtn",self.isShow)

	UIExtend.setCCControlButtonEnable(mCutoverBtnCCB,"mSwitchingArmsBtn",false)
	UIExtend.setNodeVisible(self.ccbfile,"mNoBtnNode",true)
end
function RAArsenalNewPage:genArmyDatas()
	local pageData = RAArsenalManager:getArmyIdsByBuildId(self.mArsenalBuildItemId)

	--如果有进阶兵种就放到professional字段里
	local index = 1
	for i,v in ipairs(pageData) do
		local armyId = tonumber(v)
		if index<=4 then
			table.insert(self.mArmyDataTb.normal,armyId)
		elseif index<=8 then
			table.insert(self.mArmyDataTb.professional,armyId)
		end 
		index = index + 1	
	end
end
function RAArsenalNewPage:refreshDescription()

    local armyConf = battle_soldier_conf[self.currArmyId]


    local txtMap   = {}
    txtMap["mAtkNum1"] 	= tostring(armyConf.attack) 
    txtMap["mAtkNum2"] 	= tostring(armyConf.attack) 
    txtMap["mDefNum1"] 	= tostring(armyConf.defence)
    txtMap["mDefNum2"] 	= tostring(armyConf.defence)
    txtMap["mHPNum1"] 	= tostring(armyConf.hp)
    txtMap["mHPNum2"] 	= tostring(armyConf.hp)

    UIExtend.setStringForLabel(self.ccbfile,txtMap)

    --hp,attack,defence   value = "72000_3500_300"  
    local soldierPropertyMaxValue = const_conf.soldierPropertyMax.value
    local soldierPropertyTable 	  = RAStringUtil:split(soldierPropertyMaxValue,"_")
    
    self.atkBar:runAction(CCEaseSineInOut:create( CCProgressFromTo:create(0.5,self.atkBar:getPercentage(), armyConf.attack/soldierPropertyTable[2] *100 )))
    self.defBar:runAction(CCEaseSineInOut:create(CCProgressFromTo:create(0.5,self.defBar:getPercentage(), armyConf.defence/soldierPropertyTable[3] *100 )))
    self.hpBar:runAction(CCEaseSineInOut:create(CCProgressFromTo:create(0.5,self.hpBar:getPercentage(), armyConf.hp/soldierPropertyTable[1] *100 )))

end

--判断某个兵种是否解锁
function RAArsenalNewPage:isSoldierIsUnlock(armyId)
	local armyConf = battle_soldier_conf[armyId]
	local openScienceId = armyConf.openScience

	--有些兵种不需要解锁
	if openScienceId==nil then
		return true
	end 
	local isUnLock = RAScienceManager:isResearchFinish(openScienceId)
	return isUnLock,openScienceId

end

function RAArsenalNewPage:onGotoScience()
	local RABuildManager = RARequire("RABuildManager")
	local t=RABuildManager:getBuildDataArray(Const_pb.FIGHTING_LABORATORY)
	--如果没有作战实验室给出提示
	if not next(t) then
		local str = _RALang("@NoFightingLaboratory")
		RARootManager.ShowMsgBox(str)
		return 
	end 
	-- 获取作战实验室的建筑信息 并定位到相应科技


	local tb={}
	tb.scienceId = self.openScienceId
	tb.scienceFunc=function ()
		self:updateInfo()
	end
	RARootManager.OpenPage("RAScienceTreePage",tb,true,true)
end

function RAArsenalNewPage:setHideHight()
	for i=1,4 do
		local ccbName = "mSoldierCCB"..i
		local armyCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,ccbName)
		UIExtend.setNodeVisible(armyCCB,"mHighLightNode",false)
		UIExtend.setNodeVisible(armyCCB,"mProHighLightNode",false)
	end
end

function RAArsenalNewPage:refreshBtnState()
	if self.isTrainingStatus then return end --在造兵时候则返回

	local isUnlock = RAArsenalNewPage:isSoldierIsUnlock(self.currArmyId)
	local mBgPic = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mSoldierBG")
	UIExtend.setCCSpriteGray(mBgPic, not isUnlock)

	local grayNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mTrainBtnMaskNode")

    local grayTag = 10000
    grayNode:getParent():removeChildByTag(grayTag,true)
 	
    UIExtend.setNodeVisible(self.ccbfile,"mLockedNode", not isUnlock)
    UIExtend.setNodeVisible(self.ccbfile,"mDiamondsNode", isUnlock)
    UIExtend.setNodeVisible(self.ccbfile,"mTimeNode", isUnlock)
    UIExtend.setNodeVisible(self.ccbfile,"mSliderNode", isUnlock)

 	if not isUnlock then
 		grayNode:setVisible(false)
	    local graySprite = GraySpriteMgr:createGrayMask(grayNode,grayNode:getContentSize())
	    graySprite:setTag(grayTag)
	    grayNode:getParent():addChild(graySprite)
	else
		grayNode:setVisible(true)
	end

	if isUnlock then
		self:setButtonsIsEnable(true)
	else
		self:setButtonsIsEnable(false)
	end 
	-- local mCutoverBtnCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCutoverBtnCCB")
	-- UIExtend.setCCControlButtonEnable(mCutoverBtnCCB,"mSwitchingArmsBtn",false)
end
function RAArsenalNewPage:refreshArmyShow(cellIndex)

	if self.curPoint then
		self.curPoint:setPositionX(40*cellIndex - 40 -  (#self.mArmyDataTb.normal - 1)/2 * 40  )
	end

end


function RAArsenalNewPage:refreshSingleArmyShow(armyId,index,count)
						
	local armyConf = battle_soldier_conf[armyId]
	local ccbName = "mSoldierCCB"..index
	local armyCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,ccbName)
	local icon = armyConf.icon
	local pic = ""
	local pic2= ""
	if count<=4 then
	 	pic  = UIExtend.addSpriteToNodeParent(armyCCB, 'mNormalIconNode1', icon)
	 	pic2  = UIExtend.addSpriteToNodeParent(armyCCB, 'mNormal2IconNode', icon)
	elseif count <=8 then
		pic  = UIExtend.addSpriteToNodeParent(armyCCB, 'mProfessionalIconNode', icon)
	end

	--判断是否开启
	local openScienceId = armyConf.openScience
	local flag = true
    if openScienceId ~= nil then
        flag = RAScienceManager:isResearchFinish(openScienceId)
    end

    if count<=4 then
    	if self.currArmyKind==1 then
    		UIExtend.setNodeVisible(armyCCB,"mLockedNode",not flag)
    		UIExtend.setNodeVisible(armyCCB,"mProLockedNode",false)
    	elseif self.currArmyKind==2 then
    		UIExtend.setNodeVisible(armyCCB,"mProLockedNode",not flag)
    		UIExtend.setNodeVisible(armyCCB,"mLockedNode",false)
    	end 
    	
    	
    end 

    if not flag then
    	UIExtend.setCCSpriteGray(pic,true)
    	if tolua.cast(pic2,"CCSprite") then
    		UIExtend.setCCSpriteGray(pic2,true)
    	end 
    	
    else
    	UIExtend.setCCSpriteGray(pic,false)
    	if tolua.cast(pic2,"CCSprite") then
    		UIExtend.setCCSpriteGray(pic2,false)
    	end 
    end 

   	--当前选中
    if self.currArmyId==armyId  then
    	--记录当前要解锁的科技
    	if openScienceId then
    		self.openScienceId = openScienceId
    	end 
    	RACoreDataManager:setCurrArmyIndex(index)
    	if self.currArmyKind==1 then
	       	UIExtend.setNodeVisible(armyCCB,"mProHighLightNode",false)
	    	UIExtend.setNodeVisible(armyCCB,"mHighLightNode",true)
	    elseif self.currArmyKind==2 then
	    	UIExtend.setNodeVisible(armyCCB,"mProHighLightNode",true)
	    	UIExtend.setNodeVisible(armyCCB,"mHighLightNode",false)
	    end 

    end

    --按钮是否可点击
	-- self:setBtnIsEnable(armyCCB,flag)
	-- UIExtend.setMenuItemEnable(armyCCB,"mProfessionalBtn",false)
end


function RAArsenalNewPage:getMaxUnlockArmyId()
	--第一次一定是普通士兵状态
	local tb = self.mArmyDataTb.normal
	local maxUnlockArmyId = 0
	for k,v in ipairs(tb) do
		local armyId = v
		local isUnlock = self:isSoldierIsUnlock(armyId)
		if isUnlock then
			if armyId>maxUnlockArmyId then
				maxUnlockArmyId=armyId
			end 
		end 
	end

	return maxUnlockArmyId

end

function RAArsenalNewPage:setBtnIsEnable(ccb,isEnable)
	--这里会有切换效果
	if self.currArmyKind == 1 then
    	UIExtend.setMenuItemEnable(ccb,"mNormalBtn",isEnable)
    	UIExtend.setMenuItemEnable(ccb,"mProfessionalBtn",false)
	elseif self.currArmyKind == 2 then
		UIExtend.setMenuItemEnable(ccb,"mNormalBtn",false)
    	UIExtend.setMenuItemEnable(ccb,"mProfessionalBtn",isEnable)
	end
	-- UIExtend.setMenuItemEnable(ccb,"mNormalBtn",isEnable)
	-- UIExtend.setMenuItemEnable(ccb,"mProfessionalBtn",false)
end
function RAArsenalNewPage:sliderBegan( sliderNode )
    -- bodyp
end
function RAArsenalNewPage:sliderMoved( sliderNode )
    -- body
    self:refreshSliderValue()
end
function RAArsenalNewPage:sliderEnded( sliderNode )
    -- body
    self:refreshSliderValue()
end

--滑动完滑条
function RAArsenalNewPage:refreshSliderValue()
	-- body
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	self.controlSlider:setValue(value)

	UIExtend.setCCLabelBMFontString(self.ccbfile,"mBarNum", value)
    self.mArmyCount = value
    self:refreshNeedResAndTime()
end

function RAArsenalNewPage:refreshCurrArmyUI(armyindex)

    --bar

    --之前根据每个兵营的配置读取造兵上限，现在全都根据 作战指挥部 里面的配置读取
    --local armyCount,armyMaxCount = RAArsenalManager:calcMaxTrainNum(self.currArmyId,self.mArsenalBuildTypeId)
    local armyCount,armyMaxCount = RAArsenalManager:calcMaxTrainNum(self.currArmyId,Const_pb.FIGHTING_COMMAND)

    --新手期造兵特殊处理

    local nextKeyWord = RAGuideManager.getKeyWordById()
    if nextKeyWord and nextKeyWord == RAGuideConfig.KeyWordArray.CircleTrainSoldierBtnFirst then
        --第一次造兵，数量是5，时间是5s
        local configCount = tonumber(const_conf.GuideFirstTrainSoldierCount.value)
        if configCount < armyCount then
            armyCount = configCount
        end
    end

    self.mArmyCount = armyCount
    self.mArmyMaxCount = armyMaxCount


   
    local controlSlider = UIExtend.getControlSlider("mSliderBarNode", self.ccbfile,true, 4, "TestProUI_u_Slider_BG.png", "TestProUI_u_Slider_Menu.png")
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
    self.controlSlider:setMinimumValue(0)
	local maxNum = armyMaxCount
	self.controlSlider:setMaximumValue(maxNum)

    self.controlSlider:setValue(armyCount)

    --rescource and time
    self:refreshNeedResAndTime()


    local ccbroot  = self.scrollView:getSelectedCell()
    if ccbroot ~= nil then
    	local ccbinfo =  ccbroot:getCCBFileNode()
    	if ccbinfo then
			local armyInfo = RACoreDataManager:getArmyInfoByArmyId(self.currArmyId)
			local curCount = 0 
			if armyInfo~=nil and armyInfo.freeCount > 0 then
	    		curCount = armyInfo.freeCount
	    		UIExtend.setCCLabelBMFontString(ccbinfo,"mHaveNum", tostring(curCount))
			end
		end
	end
end


function RAArsenalNewPage:refreshNeedResAndTime()
	local mArmyId = self.currArmyId
	local mArmyCount = self.mArmyCount
	local txtMap = {}
    local costMap = RAArsenalManager:calcResCostByArmyIdAndCount(mArmyId,mArmyCount)
    local buildConf = build_conf[self.mArsenalBuildItemId]

    local oriTime, actualTime = RAArsenalManager:calcTimeCostByArmyIdAndCount(mArmyId,mArmyCount,self.mArsenalBuildTypeId)
    local canOneKeyTrain,totalCostDiamd = RAArsenalManager:isCanOneKeyUpgrade(actualTime,costMap)
    local RAGuideManager = RARequire('RAGuideManager')
    if RAGuideManager.isInGuide() then
        totalCostDiamd = 0
    end     

    txtMap["mNeedResNum1"] = RALogicUtil:num2k(costMap[tostring(Const_pb.GOLDORE)] or 0)
    txtMap["mNeedResNum2"] = RALogicUtil:num2k(costMap[tostring(Const_pb.OIL)] or 0 )
    txtMap["mNeedResNum3"] = RALogicUtil:num2k(costMap[tostring(Const_pb.STEEL)] or 0)
    txtMap["mNeedResNum4"] = RALogicUtil:num2k(costMap[tostring(Const_pb.TOMBARTHITE)] or 0)

    local tmpCount = Utilitys.formatNumber(mArmyCount)
    txtMap["mBarNum"] = tmpCount
    txtMap["mNeedDiamondsNum"] = totalCostDiamd
    self.mCostGold = totalCostDiamd


    --新手期造兵特殊处理
    local nextKeyWord = RAGuideManager.getKeyWordById()
    if nextKeyWord and nextKeyWord == RAGuideConfig.KeyWordArray.CircleTrainSoldierBtnFirst then
        --第一次造兵，数量是5，时间是5s
        local configTime = tonumber(const_conf.GuideFirstTrainSoldierTime.value)
        if configTime < actualTime then
            actualTime = configTime
        end
    end


    txtMap["mTimeNum"] = Utilitys.createTimeWithFormat(actualTime)
    -- txtMap["mOriginalTime"] =  Utilitys.createTimeWithFormat(oriTime)
    
    local armyConf = battle_soldier_conf[mArmyId]
    local res = RAStringUtil:parseWithComma(armyConf.res)
    -- local txtColorMap = {}
    -- local RAGameConfig = RARequire("RAGameConfig")
    -- txtColorMap['mNeedResNum1'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedResNum2'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedResNum3'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedResNum4'] = RAGameConfig.COLOR.WHITE
    
    -- for k,v in ipairs(res) do
    --     local needValue = costMap[tostring(v.id)]
    --     local currValue = RAPlayerInfoManager.getResCountById(v.id)
    --     if v.id == Const_pb.GOLDORE then
    --         if needValue > currValue then
    --             txtColorMap['mNeedResNum1'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.OIL then
    --         if needValue > currValue then
    --             txtColorMap['mNeedResNum2'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.STEEL then
    --         if needValue > currValue then
    --             txtColorMap['mNeedResNum3'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.TOMBARTHITE then
    --         if needValue > currValue then
    --             txtColorMap['mNeedResNum4'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    -- end
    
    -- UIExtend.setColorForLabel(self.ccbfile, txtColorMap)

    UIExtend.setStringForLabel(self.ccbfile,txtMap)

end

function RAArsenalNewPage:getArmyIndex( armyId )
	for i,v in ipairs(self.mArmyDataTb.normal) do
		if v == armyId then
			return i
		end
	end
	return 1
end

function RAArsenalNewPage:getLastArmyIndex(  )
	local currArmyId = RACoreDataManager:getCurrArmyId(self.mArsenalBuildTypeId)
	if currArmyId==nil then
		currArmyId = self.mArmyDataTb.normal[1]
		if self.isFirstOpen then
			  local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(self.mArsenalBuildItemId)
    		  if not hasQueue then
    		  	 currArmyId = self:getMaxUnlockArmyId()
    		  else
    		  	 currArmyId = tonumber(QueueData.itemId)
    		  end
			
		end 
		RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,currArmyId)
	end

	local currArmyKind = RACoreDataManager:getCurrArmyKind()
	if currArmyKind==nil then
		currArmyKind = 1
		RACoreDataManager:setCurrArmyKind(currArmyKind)
	end 
	local index = self:getArmyIndex(currArmyId)
	self.scrollView:moveCellByDirection(index-1)
end

--index 代表刷单个cell
function RAArsenalNewPage:updateInfo(index)

	if index and self.mArmyDataTb.normal[index] then
		self.currArmyId = self.mArmyDataTb.normal[index]
	else
		index =	self:getArmyIndex(self.currArmyId)
		self.currArmyId = self.mArmyDataTb.normal[index]
	end
	self.currArmyKind = 1
	

	--刷新代表当前页面的点位置
	self:refreshArmyShow(index)

	-- local currIndex = RACoreDataManager:getCurrArmyIndex()
	-- if index and currIndex~=index then return end
      
	-- 当前拥有
	self:refreshDescription()



	--当前兵种信息
	self:refreshCurrArmyUI(index)

	-- 刷新正在造兵时的页面
	self:refreshTrainingNode()

	-- 刷新非造兵时的页面
	self:refreshBtnState()
end

function RAArsenalNewPage:onSubBtn()
    local value = self.controlSlider:getValue()
    if value >= 2 then
	    value = tonumber(value-1)
	    self.controlSlider:setValue(value)
        self.mArmyCount = value
        self:refreshNeedResAndTime()
    end
end

function RAArsenalNewPage:onAddBtn()
	local RAGuideManager = RARequire('RAGuideManager')
	if RAGuideManager.isInGuide() then
		return
	end
    local value = self.controlSlider:getValue()
    if value < self.mArmyMaxCount then
        value = tonumber(value+1)
	    self.controlSlider:setValue(value)
	    UIExtend.setCCLabelBMFontString(self.ccbfile,"mBarNum", self.controlSlider:getValue())
        self.mArmyCount = value
        self:refreshNeedResAndTime()
    else
        --tips is max
    end
	
end



function RAArsenalNewPage:_getSelectedArmyElectricCost()
	local id2Count = {}
	id2Count[self.currArmyId] = self.mArmyCount
    local electricAdd = RAPlayerInfoManager.getArmyElectricConsume(id2Count)
    return electricAdd
end

function RAArsenalNewPage:onTraningBtn()
    
 --    local RAQueueManager = RARequire('RAQueueManager')
	-- local isUpgrade = RAQueueManager:isBuildingTypeUpgrade(self.mBuildData.confData.buildType)
	-- if isUpgrade == true then 
	-- 	RARootManager.showErrorCode(39)
	-- 	return
	-- end	 
    if self.mArmyCount <= 0 then
        RARootManager.ShowMsgBox(_RALang("@TrainingCanNot0"))
        return
    end
    --- 训练兵时要增加电力警告判断
    local electricAdd = self:_getSelectedArmyElectricCost()
    local electricConfirmFunc = function()
	    local mBuildingUUID = self.mBuildData.id
	    local cmd = Army_pb.HPAddSoldierReq()
	    cmd.armyId = self.currArmyId
	    cmd.soldierCount = self.mArmyCount
	    cmd.buildingUUID = mBuildingUUID
	    cmd.isImmediate = false

	    self.isImmediate = false

		--新手期造兵特殊处理
	    local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
	    if keyWord and keyWord == RAGuideConfig.KeyWordArray.CircleTrainSoldierBtnFirst then
	        --第一次造兵，数量是5，时间是3s
	        local Newly_pb = RARequire('Newly_pb')
	        if self.mArsenalBuildTypeId == Const_pb.BARRACKS then
	        	cmd.flag = Newly_pb.COMMON_INFANTRY--跟后端商量好的魔法字
	        elseif self.mArsenalBuildTypeId == Const_pb.WAR_FACTORY then
	        	cmd.flag = Newly_pb.COMMON_TANK--跟后端商量好的魔法字
 			elseif self.mArsenalBuildTypeId == Const_pb.AIR_FORCE_COMMAND then
	        	cmd.flag = Newly_pb.COMMON_PLANE--跟后端商量好的魔法字
	        end
	    end
	    RANetUtil:sendPacket(HP_pb.ADD_SOLDIER_C, cmd)

	    self.isTraining = true

	    --移除guidePage:add by xinghui
	    if RAGuideManager.isInGuide() then
	        RARootManager.AddCoverPage({["update"] = true})
	    end
	    RARootManager.RemoveGuidePage()
	end
	RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, electricConfirmFunc)
end


function RAArsenalNewPage:sendOneKey()
    
    local mBuildingUUID = self.mBuildData.id
    local cmd = Army_pb.HPAddSoldierReq()
    cmd.armyId = self.currArmyId
    cmd.buildingUUID = mBuildingUUID
    cmd.soldierCount = self.mArmyCount
    cmd.isImmediate = true
    cmd.gold = self.mCostGold

    self.isImmediate = true

	--新手期造兵特殊处理
    local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
    if RAGuideManager.isInGuide() then
    	--第一次立即造兵不消耗钻石
        local Newly_pb = RARequire('Newly_pb')
        if self.mArsenalBuildTypeId == Const_pb.BARRACKS then
        	cmd.flag = Newly_pb.IMMEDIATE_INFANTRY--跟后端商量好的魔法字
        end
    end

    RANetUtil:sendPacket(HP_pb.ADD_SOLDIER_C, cmd)
    
end

function RAArsenalNewPage:onTraningNowBtn()

	-- local RAQueueManager = RARequire('RAQueueManager')
	-- local isUpgrade = RAQueueManager:isBuildingTypeUpgrade(self.mBuildData.confData.buildType)
	-- if isUpgrade == true then 
	-- 	RARootManager.showErrorCode(39)
	-- 	return
	-- end 


    if RAGuideManager.isInGuide() then
        self:sendOneKey()
        --移除guidePage:add by xinghui
        if RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage({["update"] = true})
        end
        RARootManager.RemoveGuidePage()
    else
    	if self.mArmyCount <= 0 then
        	RARootManager.ShowMsgBox(_RALang("@TrainingCanNot0"))
        	return
    	end
    	local electricAdd = self:_getSelectedArmyElectricCost()
        local electricConfirmFunc = function()
	        local RAConfirmManager = RARequire("RAConfirmManager")
	        local isShow = RAConfirmManager:getShowConfirmDlog(RAConfirmManager.TYPE.TRAINNOW)
	        if isShow then
	            local confirmData={}
	            confirmData.type=RAConfirmManager.TYPE.TRAINNOW
	            confirmData.costDiamonds = self.mCostGold
	            confirmData.resultFun = function (isOk)
	                if isOk then
	            		self:sendOneKey()
	        		end 
	            end
	            RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)
	        else
	        	self:sendOneKey()
	        end
	    end
	    RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, electricConfirmFunc)
    end
end

--获得点击按钮的兵种id
function RAArsenalNewPage:getClickArmyId(index)
	local armyId=nil
	if self.currArmyKind==1 then
		armyId = self.mArmyDataTb.normal[index]
	elseif  self.currArmyKind==2 then
		armyId = self.mArmyDataTb.professional[index]
	end 
	return armyId
end
--------------------------Btn Click Function Start-------------------------------------------
function RAArsenalNewPage:mSoldierCCB1_onNormalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==1 then return end 
	local armyId = self:getClickArmyId(1)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB1_onProfessionalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==1 then return end 
	local armyId = self:getClickArmyId(1)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB2_onNormalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==2 then return end 
	local armyId = self:getClickArmyId(2)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB2_onProfessionalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==2 then return end 
	local armyId = self:getClickArmyId(2)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB3_onNormalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==3 then return end 
	local armyId = self:getClickArmyId(3)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB3_onProfessionalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==3 then return end 
	local armyId = self:getClickArmyId(3)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB4_onNormalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==4 then return end 
	local armyId = self:getClickArmyId(4)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
function RAArsenalNewPage:mSoldierCCB4_onProfessionalCheckBtn()
	local currIndex = RACoreDataManager:getCurrArmyIndex()
	if currIndex==4 then return end 
	local armyId = self:getClickArmyId(4)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:updateInfo()
end
--------------------------Btn Click Function End-------------------------------------------

--------------------------Tab Click Function Start-----------------------------------------
-- RACoreDataManager:setCurrArmyKind(kind)

function RAArsenalNewPage:mCutoverBtnCCB_onSwitchingArmsBtn()
	local currArmyKind = RACoreDataManager:getCurrArmyKind()
	--1普通 2进阶
	if currArmyKind==1 then
		self.currArmyKind=2
		RACoreDataManager:setCurrArmyKind(2)
	elseif currArmyKind==2 then
		self.currArmyKind=1
		RACoreDataManager:setCurrArmyKind(1)
	end 

	local currIndex = RACoreDataManager:getCurrArmyIndex()

	local armyId = RAArsenalNewPage:getClickArmyId(currIndex)
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,armyId)
	self:ShuffleDeck()
end

function RAArsenalNewPage:setButtonsIsEnable(isEnable)
	-- body

	--切换按钮
	-- local mCutoverBtnCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCutoverBtnCCB")
	-- UIExtend.setCCControlButtonEnable(mCutoverBtnCCB,"mSwitchingArmsBtn",false)

	--+ - 按钮

	UIExtend.setCCControlButtonEnable(self.ccbfile,"mTraningBtn",isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mTraningNowBtn",isEnable)
end

--desc:获得训练按钮的信息
function RAArsenalNewPage:getTrainBtnNodeInfo()
	-- body
	if not self.ccbfile then return end
	local trainBtn = self.ccbfile:getCCNodeFromCCB("mGuideSpeedUpNode")
    local worldPos =  trainBtn:getParent():convertToWorldSpaceAR(ccp(trainBtn:getPositionX(),trainBtn:getPositionY()))
    --适配一下，目前获得的数据不是很准确
    worldPos.y = worldPos.y - 8
    worldPos.x = worldPos.x + 6
    local size = trainBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = CCSizeMake(size.width+RAGuideConfig.GuideTips.ConfigOffset*2, size.height+RAGuideConfig.GuideTips.ConfigOffset*2)
    }
    return guideData
end

--desc:获得立即训练按钮信息
function RAArsenalNewPage:getGuideNodeInfo()
    local upgradeNowBtn = self.ccbfile:getCCNodeFromCCB("mGuideSpeedUpNowNode")
    local worldPos =  upgradeNowBtn:getParent():convertToWorldSpaceAR(ccp(upgradeNowBtn:getPositionX(),upgradeNowBtn:getPositionY()))
    --适配一下，目前获得的数据不是很准确
    worldPos.y = worldPos.y - 8
    worldPos.x = worldPos.x + 6
    local size = upgradeNowBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = CCSizeMake(size.width+RAGuideConfig.GuideTips.ConfigOffset*2, size.height+RAGuideConfig.GuideTips.ConfigOffset*2)
    }
    return guideData
end


--动作之前已经切换的页签
function RAArsenalNewPage:playDownAction(ccbfile)

	-- 1 普通士兵 2 进阶士兵
	if self.currArmyKind==2 then
		ccbfile:runAnimation(ActionConfig.DownNor)
	elseif self.currArmyKind==1 then
		ccbfile:runAnimation(ActionConfig.DownPro)
	end

end

function RAArsenalNewPage:playUpAction(ccbfile)
		-- 1 普通士兵 2 进阶士兵
	if self.currArmyKind==2 then
		ccbfile:runAnimation(ActionConfig.UpPro)
	elseif self.currArmyKind==1 then
		ccbfile:runAnimation(ActionConfig.UpNor)
	end
end


--点击tab的洗牌动作
function RAArsenalNewPage:ShuffleDeck()

	--动作期间设置所有按钮不可点击
	-- self:setButtonsIsEnable(false)
	local t=0.1
	for i=1,4 do
		local ccbName = "mSoldierCCB"..i
		local armyCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,ccbName)
		local delay = t*i
		local tp=i
		performWithDelay(armyCCB, function ()
			self:playDownAction(armyCCB)
			self:updateInfo(tp)
		end, delay)

	end

	-- self:setButtonsIsEnable(true)

end
--------------------------Tab Click Function End-------------------------------------------


local OnReceiveMessage = function (message)
 CCLuaLog("RAArsenalPage OnReceiveMessage id:"..message.messageID)

    if message.messageID == MessageDef_Queue.MSG_Soilder_ADD or
    message.messageID == MessageDef_Queue.MSG_Soilder_UPDATE or 
    message.messageID == MessageDef_Queue.MSG_Soilder_CANCEL then
        local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(RAArsenalNewPage.mArsenalBuildItemId)
        if hasQueue then
        	--标志正在训练中
        	RAArsenalNewPage.isTrainingStatus = true
            RAArsenalNewPage.mEndTime = math.ceil(( QueueData.endTime2 - QueueData.startTime2) / 1000)
        end

        --新手期特殊处理，训练后直接关闭页面
        if RAGuideManager.isInGuide() then
    		RARootManager.CloseAllPages()
            RARootManager.AddCoverPage()
        else
            RAArsenalNewPage:updateInfo()
        end

    elseif message.messageID == MessageDef_Queue.MSG_Soilder_DELETE then
    	RAArsenalNewPage.isTrainingStatus = false
    	RAArsenalNewPage.mEndTime=0
        RAArsenalNewPage:updateInfo()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	local opcode = message.opcode
    	if opcode==HP_pb.ADD_SOLDIER_C then 
	    	local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(RAArsenalNewPage.mArsenalBuildItemId)
	    	if not hasQueue then
	    		RAArsenalNewPage.isTrainingStatus = false
	    	end 

	    	--新手期特殊处理，训练后直接关闭页面
	    	if RAGuideManager.isInGuide() then
	    		RARootManager.CloseAllPages()
	    	else
	    		if not RAArsenalNewPage.isImmediate then  --一键秒兵不需要关闭页面了
		    		RARootManager.CloseAllPages()
		    	else
		    		--刷新
		    		RAArsenalNewPage:updateInfo(RAArsenalNewPage:getArmyIndex(RAArsenalNewPage.currArmyId) )
		    	end	
	    	end
	    end
	elseif message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then

    end
end



---------------------------------training ---------------------------------------------
function RAArsenalNewPage:refreshTrainingNode()
    local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(self.mArsenalBuildItemId)
    
    UIExtend.setNodeVisible(self.ccbfile,"mIldeNode",not hasQueue)
    UIExtend.setNodeVisible(self.ccbfile,"mSpeedUpTimeNode",not hasQueue)
    UIExtend.setNodeVisible(self.ccbfile,"mTrainingNode",hasQueue)


    if hasQueue then
    	self.isTrainingStatus = true
        local armyId = tonumber(QueueData.itemId)
        local armyConf = battle_soldier_conf[armyId]
        local armyInfo = RACoreDataManager:getArmyInfoByArmyId(armyId)
        assert(armyInfo~=nil,"armyInfo~=nil")
        local inTrainNum = armyInfo.inTrainCount
        local txtLabel = {}
        local tNum = Utilitys.formatNumber(inTrainNum)
        -- txtLabel["mTrainingNum"] = tNum

        --name 
        local name = armyConf.name
        UIExtend.setCCLabelBMFontString(self.ccbfile,"mSoldierName",_RALang(name))

        --icon
        UIExtend.addSpriteToNodeParent(self.ccbfile,"mIconNode", armyConf.icon)
        
        --remain MilliSecond
        local remainMilliSecond = 0
     	remainMilliSecond = Utilitys.getCurDiffMilliSecond(QueueData.endTime2)
        -- remainMilliSecond = remainMilliSecond / 1000
        
        local remainTime = math.ceil(remainMilliSecond)

		local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        txtLabel["mTrainingTime"] = tmpStr
        
		local scaleX = RAQueueUtility.getTimeBarScale(QueueData)
        --scale
		local pBar = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mTrainingBar")
		pBar:setScaleX(scaleX)

		 --num
        local haveTrainedNum = math.max(math.floor(inTrainNum*scaleX),0)
        UIExtend.setCCLabelBMFontString(self.ccbfile,"mTrainingNum",haveTrainedNum.."/"..tNum)


        local timeCostDimand = RALogicUtil:time2Gold(remainTime)
        local RAGuideManager = RARequire('RAGuideManager')
        if RAGuideManager.isInGuide() then
            timeCostDimand = 0
        end        
        txtLabel["mSpeedUpNeedDiamondsNum"] = timeCostDimand
        UIExtend.setStringForLabel(self.ccbfile,txtLabel)

        --如果当前训练兵种id不是当前显示的兵种id按钮也不可点击
        local trainingId = tonumber(QueueData.itemId)
        if trainingId~=self.currArmyId then
        	-- self:setButtonsIsEnable(false)
        else
        	-- self:setButtonsIsEnable(true)
       	end 
    end
end

function RAArsenalNewPage:Execute()
    mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
        self:refreshTrainingNode()
        mFrameTime = 0 
    end
end

--取消训练队列
function RAArsenalNewPage:onTrainingCancelBtn()
	local queue = RAQueueManager:getArsenaQueue()
	if queue == nil then
        return
    end
    local tb={}
	for k,v in pairs(queue) do
		if tonumber(v.itemId)==self.currArmyId then
			tb=v
			break
		end
	end

    local confirmData = {}
	confirmData.yesNoBtn = true
	confirmData.labelText = _RALang("@BuildSoliderQueueCancelTip")
	confirmData.resultFun = function (isOk)
		if isOk then
			RAQueueManager:sendQueueCancel(tb.id)
		end 
	end
	RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
end

--钻石加速训练队列
function RAArsenalNewPage:onSpeedUpNowBtn()
	local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(self.mArsenalBuildItemId)
	if hasQueue then
		RARootManager.showFinishNowPopUp(QueueData)
	end
end

--道具加速训练队列
function RAArsenalNewPage:onSpeedUpBtn()
	CCLuaLog("RAArsenalPage:onAccelerationTraining")

	local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(self.mArsenalBuildItemId)
	if hasQueue then
		RARootManager.showCommonItemsSpeedUpPopUp(QueueData)
	end
end




---------------------------------training ---------------------------------------------
function RAArsenalNewPage:registerMessageHandlers()
	MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK , OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo , OnReceiveMessage)
    
   
end

function RAArsenalNewPage:removeMessageHandlers()
	MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo , OnReceiveMessage)
end

function RAArsenalNewPage:resetVars()
	self.mArsenalBuildTypeId = nil
	self.mArsenalBuildItemId = nil
	self.mBuildData			 = nil
	self.currArmyId          = nil
	self.currArmyKind        = nil
	self.mArmyCount 		 = nil
    self.mArmyMaxCount 		 = nil
    self.mEndTime			 = nil
    self.controlSlider 		 = nil
    self.mCostGold			 = nil
    self.isTrainingStatus    = nil
    self.isFirstOpen		 = nil
end
function RAArsenalNewPage:clearArmyDatas()
	for k,v in pairs(self.mArmyDataTb) do
		for k1,v1 in ipairs(v) do
			v1 = nil
		end
		v = nil
	end
	self.mArmyDataTb = nil
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,nil)
	RACoreDataManager:setCurrArmyKind(nil)
	RACoreDataManager:setCurrArmyIndex(nil)
end


function RAArsenalNewPage:onClose( ... )
	RARootManager.ClosePage("RAArsenalNewPage")
end

function RAArsenalNewPage:Exit()

	self:removeMessageHandlers()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAArsenalNewPage")

    if self.controlSlider then
        self.controlSlider:unregisterScriptSliderHandler()
        self.controlSlider = nil
    end
    if self.scrollView then
    	self.scrollView:removeAllCell()
    end
	self:clearArmyDatas()
    self:resetVars()


	UIExtend.unLoadCCBFile(RAArsenalNewPage)
	
end

return RAArsenalNewPage
--endregion
