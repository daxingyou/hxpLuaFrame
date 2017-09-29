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

local mFrameTime = 0
local TAG=1000
local TWO_CIRCLE_LENGTH =30
local pageConfig={
	normalTip="NewProduction_u_Tips_Nor.png",
	selectTip="NewProduction_u_Tips_Sel.png",
	arrow="NewProduction_Icon_Arrow_01.png"
}
local RAArsenalNewTwoPage = BaseFunctionPage:new(...)

--------------------------------------------------------------------
local RAArsenalRenderCell ={}
function RAArsenalRenderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAArsenalRenderCell:onRefreshContent(ccbRoot)

	CCLuaLog("RAArsenalRenderCell:onRefreshContent")
	if not ccbRoot then return end

	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    UIExtend.setSpriteImage(ccbfile, {mCellPic=self.banner})


   

    -- local pic = UIExtend.getCCSpriteFromCCB(ccbfile,"mCellPic")
    -- UIExtend.setCCSpriteGray(pic)
    -- if not self.isCurr or self.over or not self.isStart then
    -- 	UIExtend.setCCSpriteGray(pic,true)
    -- end 

end

function RAArsenalRenderCell:setPicGray(isGray)
	 local pic = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mCellPic")
	 UIExtend.setCCSpriteGray(pic,isGray)
end
--------------------------------------------------------------------------

function RAArsenalNewTwoPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAProductionPageNewTwo.ccbi",self)
	self.ccbfile = ccbfile


	self.mArsenalBuildTypeId = data.confData.buildType
	self.mArsenalBuildItemId = data.confData.id
    self.mBuildData = data
    self.mArmyDataTb = {}
    self.isFirstOpen = true
    self.isImmediate = false

    self:registerMessageHandlers()
    self:init()

    RAGuideManager.gotoNextStep()

end

function RAArsenalNewTwoPage:init()
	self:initTitle()
	self:genArmyDatas()
	self:updateInfo()
	self:createStageRenderSV()
	
	-- self:showSwithBtn()
	self.isFirstOpen = false
end


function RAArsenalNewTwoPage:updateInfo()

	--获取当前兵种
	local currArmyId = RACoreDataManager:getCurrArmyId(self.mArsenalBuildTypeId)
	if currArmyId==nil then
		currArmyId = self.mArmyDataTb[1]
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
	self.currArmyId=currArmyId

	self:refreshDescription()
	self:refreshCurrArmyUI()
	self:refreshTrainingNode()
end
function RAArsenalNewTwoPage:refreshDescription()

	local RACoreDataManager = RARequire("RACoreDataManager")
    local armyInfo = RACoreDataManager:getArmyInfoByArmyId(self.currArmyId)
    local curCount = 0 
    if armyInfo~=nil and armyInfo.freeCount > 0 then
        curCount = armyInfo.freeCount
    end
    local armyConf = battle_soldier_conf[self.currArmyId]
    local txtMap   = {}
    txtMap["mSoldierName"]=_RALang(armyConf.name)
    txtMap["mCurrentNum"] 	= curCount
    txtMap["mAttackNum"] 	= tostring(armyConf.attack) 
    txtMap["mDefenseNum"] 	= tostring(armyConf.defence)
    txtMap["mLifeNum"] 		= tostring(armyConf.hp)

    UIExtend.setStringForLabel(self.ccbfile,txtMap)
   
    
   
	   -- armyConf.power,armyConf.load,armyConf.speed,armyConf.energyCost,_RALang(vecSub[1]),_RALang(vecSub[2])) 
	--判断当前兵种是否解锁
	local isCurrArmyUnLock,openScienceId= self:isSoldierIsUnlock(self.currArmyId)
	local titleKey =""
	local contentKey = ""
	local vecSub = RAStringUtil:split(armyConf.subdue,",")  --克制 受制
	assert(#vecSub == 2, "#vecSub == 2")


	--战力：负重：速度：克制：受制：
	local desTb={
		{title=_RALang("@BattlePower"),num=armyConf.power},
		{title=_RALang("@BurdenTil"),num=armyConf.load},
		{title=_RALang("@Speed"),num=armyConf.speed},
		{title=_RALang("@Restrain"),num=_RALang(vecSub[1])},
		{title=_RALang("@Contrained"),num=_RALang(vecSub[2])},

	}
	local count=#desTb
	for i=1,#desTb do
		local des=desTb[i]
		local titleVar="mDetailsLabel"..i
		local numVar = "mDetailsNum"..i
		UIExtend.setCCLabelString(self.ccbfile,titleVar,des.title)
		UIExtend.setCCLabelString(self.ccbfile,numVar,des.num)
	end


    local redBar  	= UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mRedBar")
    local blueBar 	= UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBlueBar")
    local greenBar 	= UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mGreenBar")

    --hp,attack,defence   value = "72000_3500_300"  
    local soldierPropertyMaxValue = const_conf.soldierPropertyMax.value
    local soldierPropertyTable 	  = RAStringUtil:split(soldierPropertyMaxValue,"_")
    
    Utilitys.barActionPlay(redBar,{value = armyConf.attack,baseValue = soldierPropertyTable[2],valueScale =0})
    Utilitys.barActionPlay(blueBar,{value = armyConf.defence,baseValue = soldierPropertyTable[3],valueScale = 0})
    Utilitys.barActionPlay(greenBar,{value = armyConf.hp,baseValue = soldierPropertyTable[1],valueScale =0})


    --[[
		页面有三种状态：
			未训练状态==》解锁状态，未解锁状态
			训练状态
    ]]
    --判断当前兵种是否解锁
	-- local isCurrArmyUnLock,openScienceId= self:isSoldierIsUnlock(self.currArmyId)
	

end

function RAArsenalNewTwoPage:sliderMoved( sliderNode )
    -- body
    self:refreshSliderValue()
end
function RAArsenalNewTwoPage:sliderEnded( sliderNode )
    -- body
    self:refreshSliderValue()
end

function RAArsenalNewTwoPage:refreshCurrArmyUI()

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
    local controlSlider = UIExtend.getControlSliderNew("mBarNode", self.ccbfile,true)
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
    self.controlSlider:setMinimumValue(0)
	local maxNum = armyMaxCount
	self.controlSlider:setMaximumValue(maxNum)

    self.controlSlider:setValue(armyCount)

    --rescource and time
    self:refreshNeedResAndTime()

end

--滑动完滑条
function RAArsenalNewTwoPage:refreshSliderValue()
	-- body
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	self.controlSlider:setValue(value)

	UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", value)
    self.mArmyCount = value
    self:refreshNeedResAndTime()
end
function RAArsenalNewTwoPage:refreshNeedResAndTime()
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

    local costGoldNum = RALogicUtil:num2k(costMap[tostring(Const_pb.GOLDORE)] or 0)
    local costOilNum = RALogicUtil:num2k(costMap[tostring(Const_pb.OIL)] or 0)
    local costSteelNum = RALogicUtil:num2k(costMap[tostring(Const_pb.STEEL)] or 0)
    local costRareEarthsNum = RALogicUtil:num2k(costMap[tostring(Const_pb.TOMBARTHITE)] or 0)


    local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
    local goldNum=RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.GOLDORE) or 0)
    local oilNum=RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.OIL) or 0)
    local steelNum=RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.STEEL) or 0)
    local rareEarthsNum=RALogicUtil:num2k(RAPlayerInfoManager.getResCountById(Const_pb.TOMBARTHITE) or 0)

    UIExtend.setCCLabelHTMLStringDirect(self.ccbfile,"mNeedGoldNum",_RALang("@VitNum",costGoldNum,goldNum))
    UIExtend.setCCLabelHTMLStringDirect(self.ccbfile,"mNeedOilNum",_RALang("@VitNum",costOilNum,oilNum))
    UIExtend.setCCLabelHTMLStringDirect(self.ccbfile,"mNeedSteelNum",_RALang("@VitNum",costSteelNum,steelNum))
    UIExtend.setCCLabelHTMLStringDirect(self.ccbfile,"mNeedRareEarthsNum",_RALang("@VitNum",costRareEarthsNum,rareEarthsNum))


    local tmpCount = Utilitys.formatNumber(mArmyCount)
    txtMap["mWantTrainingNum"] = tmpCount
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


    txtMap["mNeedTime"] = Utilitys.createTimeWithFormat(actualTime)
    -- txtMap["mOriginalTime"] =  Utilitys.createTimeWithFormat(oriTime)
    
    -- local armyConf = battle_soldier_conf[mArmyId]
    -- local res = RAStringUtil:parseWithComma(armyConf.res)
    -- local txtColorMap = {}
    -- local RAGameConfig = RARequire("RAGameConfig")
    -- txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.WHITE
    -- txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.WHITE
    
    -- for k,v in ipairs(res) do
    --     local needValue = costMap[tostring(v.id)]
    --     local currValue = RAPlayerInfoManager.getResCountById(v.id)
    --     if v.id == Const_pb.GOLDORE then
    --         if needValue > currValue then
    --             txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.OIL then
    --         if needValue > currValue then
    --             txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.STEEL then
    --         if needValue > currValue then
    --             txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    --     if v.id == Const_pb.TOMBARTHITE then
    --         if needValue > currValue then
    --             txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.RED
    --         end
    --     end
    -- end
    
    -- UIExtend.setColorForLabel(self.ccbfile, txtColorMap)

    UIExtend.setStringForLabel(self.ccbfile,txtMap)

end

function RAArsenalNewTwoPage:genArmyDatas()
	local pageData = RAArsenalManager:getArmyIdsByBuildId(self.mArsenalBuildItemId)

	--如果有进阶兵种就放到professional字段里
	local index = 1
	for i,v in ipairs(pageData) do
		local armyId = tonumber(v)
		-- if index<=4 then
		-- 	table.insert(self.mArmyDataTb.normal,armyId)
		-- elseif index<=8 then
		-- 	table.insert(self.mArmyDataTb.professional,armyId)
		-- end 
		-- index = index + 1	

        table.insert(self.mArmyDataTb,armyId)
	end

end

--判断某个兵种是否解锁
function RAArsenalNewTwoPage:isSoldierIsUnlock(armyId)
    local armyConf = battle_soldier_conf[armyId]
    local openScienceId = armyConf.openScience

    --有些兵种不需要解锁
    if openScienceId==nil then
        return true
    end 
    local isUnLock = RAScienceManager:isResearchFinish(openScienceId)
    return isUnLock,openScienceId

end


function RAArsenalNewTwoPage:getMaxUnlockArmyId()
	--第一次一定是普通士兵状态
	local tb = self.mArmyDataTb
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

function RAArsenalNewTwoPage:initTitle()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@TrainSoldires"))
    titleCCB:runAnimation("InAni")
end

function RAArsenalNewTwoPage:createStageRenderSV()
    local svNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mBigIconBGNode")
    local size = CCSizeMake(0, 0)
    if svNode then
        size = svNode:getContentSize()
    end
	self.renderScrollView = CCSelectedScrollView:create(size)
    self.renderScrollView:setDirection(kCCScrollViewDirectionHorizontal)
    self.renderScrollView:registerFunctionHandler(self)
    UIExtend.addNodeToParentNode(self.ccbfile, "mBigIconBGNode", self.renderScrollView)

    self:refreshRenderUI()
end

function RAArsenalNewTwoPage:refreshRenderUI( ... )
	if self.renderScrollView then
        self.renderScrollView:removeAllCell()
    end

    self:clearCircleTab()
    if self.circleFG and tolua.cast(self.circleFG,"CCSprite") then
        self.circleFG:removeFromParentAndCleanup(true)
        self.circleFG = nil
    end

    --兵种id表
    local stageDatas = RAArsenalManager:getArmyIdsByBuildId(self.mArsenalBuildItemId)


    --获取圆点的起始位置
    local stageCount = #stageDatas
    local centerNode = UIExtend.getCCNodeFromCCB(self.ccbfile ,"mTipsNode")
    centerNode:removeAllChildren()
    local startPos = ccp(0, 0)
    if stageCount%2 == 0 then
        local oneSideNum = stageCount / 2
        startPos.x = startPos.x - (oneSideNum-0.5)*TWO_CIRCLE_LENGTH
    else
        local oneSideNum = (stageCount-1) / 2
        startPos.x = startPos.x - (oneSideNum * TWO_CIRCLE_LENGTH)
    end

    local scrollview = self.renderScrollView
    local index = 0
    local cellW = 0
    local currCell=nil
    local maxLeftOffset=100000
    local maxRightoffset=-100000
    for i,v in ipairs(stageDatas) do
    	local stageId =tonumber(v)

        local armyConf = battle_soldier_conf[stageId]
    	local show = armyConf.show

    	local cell = CCBFileCell:create()
    	local panel = RAArsenalRenderCell:new({
				banner = show,
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAProductionCellNewTwo.ccbi")
		scrollview:addCellBack(cell)
		cell:setCellTag(i)
		cellW = cell:getContentSize().width

		--圆点底图
		-- local RAGameConfig=RARequire("RAGameConfig")
	    local circleBG = CCSprite:create(pageConfig.normalTip)
        if circleBG and centerNode then
            centerNode:addChild(circleBG)
            local pos = ccpAdd(startPos, ccp((i - 1)*TWO_CIRCLE_LENGTH, 0))
            circleBG:setPosition(pos)

            --保存下左右的最大偏移量
            if pos.x<maxLeftOffset then
            	maxLeftOffset=pos.x
            end 

            if pos.x>maxRightoffset then
            	maxRightoffset=pos.x
            end 

            self.circles[i] = circleBG

            --选中圆点  
            if stageId==self.currArmyId then
            	 self.circleFG = CCSprite:create(pageConfig.selectTip)
            	 centerNode:addChild(self.circleFG)
            	 self.circleFG:setZOrder(TAG)
            	 self.circleFG:setPosition(pos)
            	 -- index = i
            	 currCell = cell
            	 -- self.currPanel = panel
        	end 
        end	
    end

    --左右箭头
    local leftArrow= CCSprite:create(pageConfig.arrow)
    centerNode:addChild(leftArrow)
    leftArrow:setPosition(ccp(maxLeftOffset-TWO_CIRCLE_LENGTH,0))

    local rightArrow= CCSprite:create(pageConfig.arrow)
    centerNode:addChild(rightArrow)
    rightArrow:setFlipX(true)
    rightArrow:setPosition(ccp(maxRightoffset+TWO_CIRCLE_LENGTH,0))

    scrollview:orderCCBFileCells()
    scrollview:setSelectedCell(currCell, CCBFileCell.LT_Mid, 0.0, 0.2)
   
end

function RAArsenalNewTwoPage:clearCircleTab()
	 if  self.circles then
    	for key, circle in pairs(self.circles) do
        	circle:removeFromParentAndCleanup(true)
    	end
    end 
    self.circles ={}
end

function RAArsenalNewTwoPage:getStageIdByIndex(index)
    
    return self.mArmyDataTb[index]
end

function RAArsenalNewTwoPage:scrollViewSelectNewItem(cell)
    if cell then
        self.renderScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        local tag = cell:getCellTag()
        local circleBG = self.circles[tag]
        local stageId= self:getStageIdByIndex(tag)
        if circleBG then
            local pos = ccp(0, 0)
            pos.x, pos.y = circleBG:getPosition()
            self.circleFG:setPosition(pos)

            --设置下当前stageId
           RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,stageId)

           self:updateInfo()

        end
    end
end

function RAArsenalNewTwoPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        self.renderScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RAArsenalNewTwoPage:scrollViewRollBack(cell)
    if cell then
        self.renderScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end
function RAArsenalNewTwoPage:_getSelectedArmyElectricCost()
	local id2Count = {}
	id2Count[self.currArmyId] = self.mArmyCount
    local electricAdd = RAPlayerInfoManager.getArmyElectricConsume(id2Count)
    return electricAdd
end

function RAArsenalNewTwoPage:sendOneKey()
    
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
function RAArsenalNewTwoPage:onUpgradeNowBtn()


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

function RAArsenalNewTwoPage:onTrainBtn()
    
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
---------------------------------training ---------------------------------------------
function RAArsenalNewTwoPage:refreshTrainingNode()
  --   local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(self.mArsenalBuildItemId)
  --   if hasQueue then
  --   	self.isTrainingStatus = true
  --       UIExtend.setNodeVisible(self.ccbfile,"mNoTrainNode",false)
  --       UIExtend.setNodeVisible(self.ccbfile,"mTrainingNode",true)
  --       local armyId = tonumber(QueueData.itemId)
  --       local armyConf = battle_soldier_conf[armyId]
  --       local armyInfo = RACoreDataManager:getArmyInfoByArmyId(armyId)
  --       assert(armyInfo~=nil,"armyInfo~=nil")
  --       local inTrainNum = armyInfo.inTrainCount
  --       local txtLabel = {}
  --       local tNum = Utilitys.formatNumber(inTrainNum)
  --       -- txtLabel["mTrainingNum"] = tNum

  --       --name 
  --       local name = armyConf.name
  --       UIExtend.setCCLabelString(self.ccbfile,"mTrainingSoldierName",_RALang(name))

  --       --icon
  --       UIExtend.addSpriteToNodeParent(self.ccbfile,"mTrainingIconNode", armyConf.icon)
        
  --       --remain MilliSecond
  --       local remainMilliSecond = 0
  --    	remainMilliSecond = Utilitys.getCurDiffMilliSecond(QueueData.endTime2)
  --       -- remainMilliSecond = remainMilliSecond / 1000
        
  --       local remainTime = math.ceil(remainMilliSecond)

		-- local tmpStr = Utilitys.createTimeWithFormat(remainTime)
  --       txtLabel["mTrainingTime"] = tmpStr
        
		-- local scaleX = RAQueueUtility.getTimeBarScale(QueueData)
  --       --scale
		-- local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mTrainingBar")
		-- pBar:setScaleX(scaleX)

		--  --num
  --       local haveTrainedNum = math.max(math.floor(inTrainNum*scaleX),0)
  --       local str = RAStringUtil:getHTMLString("TrainingNum",haveTrainedNum,tNum)
  --       UIExtend.setCCLabelHTMLString(self.ccbfile,"mTrainingNum",str)


  --       local timeCostDimand = RALogicUtil:time2Gold(remainTime)
  --       local RAGuideManager = RARequire('RAGuideManager')
  --       if RAGuideManager.isInGuide() then
  --           timeCostDimand = 0
  --       end        
  --       txtLabel["mTrainingNeedDiamondsNum"] = timeCostDimand
  --       UIExtend.setStringForLabel(self.ccbfile,txtLabel)

  --       --如果当前训练兵种id不是当前显示的兵种id按钮也不可点击
  --       local trainingId = tonumber(QueueData.itemId)
  --       if trainingId~=self.currArmyId then
  --       	self:setButtonsIsEnable(false)
  --       else
  --       	self:setButtonsIsEnable(true)
  --      	end 
        
  --   else
  --       UIExtend.setNodeVisible(self.ccbfile,"mTrainingNode",false)
  --       UIExtend.setNodeVisible(self.ccbfile,"mNoTrainNode",true)
        
  --   end
end

function RAArsenalNewTwoPage:Execute()
    mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
        self:refreshTrainingNode()
        mFrameTime = 0 
    end
end
-- --取消训练队列
-- function RAArsenalNewPage:onCancelTrainBtn()
-- 	local queue = RAQueueManager:getArsenaQueue()
-- 	if queue == nil then
--         return
--     end
--     local tb={}
-- 	for k,v in pairs(queue) do
-- 		if tonumber(v.itemId)==self.currArmyId then
-- 			tb=v
-- 			break
-- 		end
-- 	end

--     local confirmData = {}
-- 	confirmData.yesNoBtn = true
-- 	confirmData.labelText = _RALang("@BuildSoliderQueueCancelTip")
-- 	confirmData.resultFun = function (isOk)
-- 		if isOk then
-- 			RAQueueManager:sendQueueCancel(tb.id)
-- 		end 
-- 	end
-- 	RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
-- end

-- --钻石加速训练队列
-- function RAArsenalNewPage:onTrainDiamondsBtn()
-- 	local queue = RAQueueManager:getArsenaQueue()
--     local tb={}
-- 	for k,v in pairs(queue) do
-- 		if tonumber(v.itemId)==self.currArmyId then
-- 			tb=v
-- 			break
-- 		end
-- 	end
-- 	RARootManager.showFinishNowPopUp(tb)
-- end

-- --道具加速训练队列
-- function RAArsenalNewPage:onTrainItmeBtn()
-- 	CCLuaLog("RAArsenalPage:onAccelerationTraining")
--     local queue = RAQueueManager:getArsenaQueue()
-- 	if not next(queue) then return end 

-- 	local tb={}
-- 	for k,v in pairs(queue) do
-- 		if tonumber(v.itemId)==self.currArmyId then
-- 			tb=v
-- 			break
-- 		end
-- 	end
-- 	RARootManager.showCommonItemsSpeedUpPopUp(tb)
-- end

--------------------------Tab Click Function End-------------------------------------------


local OnReceiveMessage = function (message)
 CCLuaLog("RAArsenalPage OnReceiveMessage id:"..message.messageID)

    if message.messageID == MessageDef_Queue.MSG_Soilder_ADD or
    message.messageID == MessageDef_Queue.MSG_Soilder_UPDATE or 
    message.messageID == MessageDef_Queue.MSG_Soilder_CANCEL then
        local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(RAArsenalNewPage.mArsenalBuildItemId)
        if hasQueue then
        	--标志正在训练中
        	RAArsenalNewTwoPage.isTrainingStatus = true
            RAArsenalNewTwoPage.mEndTime = math.ceil(( QueueData.endTime2 - QueueData.startTime2) / 1000)
        end

        --新手期特殊处理，训练后直接关闭页面
        if RAGuideManager.isInGuide() then
    		RARootManager.CloseAllPages()
            RARootManager.AddCoverPage()
        else
            RAArsenalNewTwoPage:updateInfo()
        end

    elseif message.messageID == MessageDef_Queue.MSG_Soilder_DELETE then
    	RAArsenalNewTwoPage.isTrainingStatus = false
    	RAArsenalNewTwoPage.mEndTime=0
        RAArsenalNewTwoPage:updateInfo()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	local opcode = message.opcode
    	if opcode==HP_pb.ADD_SOLDIER_C then 
	    	local hasQueue,QueueData = RAArsenalManager:hasQueueByBuildId(RAArsenalNewTwoPage.mArsenalBuildItemId)
	    	if not hasQueue then
	    		RAArsenalNewTwoPage.isTrainingStatus = false
	    	end 

	    	--新手期特殊处理，训练后直接关闭页面
	    	if RAGuideManager.isInGuide() then
	    		RARootManager.CloseAllPages()
	    	else
	    		if not RAArsenalNewTwoPage.isImmediate then  --一键秒兵不需要关闭页面了
		    		RARootManager.CloseAllPages()
		    	else
		    		--刷新
		    		RAArsenalNewTwoPage:updateInfo()
		    	end	
	    	end
	    end
    end
end
function RAArsenalNewTwoPage:onSubBtn()
    local value = self.controlSlider:getValue()
    if value >= 2 then
	    value = tonumber(value-1)
	    self.controlSlider:setValue(value)
	    UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", self.controlSlider:getValue())
        self.mArmyCount = value
        self:refreshNeedResAndTime()
    end
end

function RAArsenalNewTwoPage:onAddBtn()
	local RAGuideManager = RARequire('RAGuideManager')
	if RAGuideManager.isInGuide() then
		return
	end
    local value = self.controlSlider:getValue()
    if value < self.mArmyMaxCount then
        value = tonumber(value+1)
	    self.controlSlider:setValue(value)
	    UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", self.controlSlider:getValue())
        self.mArmyCount = value
        self:refreshNeedResAndTime()
    else
        --tips is max
    end
	
end

---------------------------------training ---------------------------------------------
function RAArsenalNewTwoPage:registerMessageHandlers()
	MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK , OnReceiveMessage)
   
end

function RAArsenalNewTwoPage:removeMessageHandlers()
	MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
end

function RAArsenalNewTwoPage:resetVars()
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
function RAArsenalNewTwoPage:clearArmyDatas()
	for k,v in pairs(self.mArmyDataTb) do
		-- for k1,v1 in ipairs(v) do
		-- 	v1 = nil
		-- end
		v = nil
	end
	self.mArmyDataTb = nil
	RACoreDataManager:setCurrArmyId(self.mArsenalBuildTypeId,nil)
	-- RACoreDataManager:setCurrArmyKind(nil)
	-- RACoreDataManager:setCurrArmyIndex(nil)
end
function RAArsenalNewTwoPage:Exit()

	self:removeMessageHandlers()
    self.renderScrollView:removeAllCell()
    self.renderScrollView:unregisterFunctionHandler()
	-- local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	-- RACommonTitleHelper:RemoveCommonTitle("RAArsenalNewPage")

    if self.controlSlider then
        self.controlSlider:unregisterScriptSliderHandler()
        self.controlSlider = nil
    end

	self:clearArmyDatas()
    self:resetVars()


	UIExtend.unLoadCCBFile(RAArsenalNewTwoPage)
	
end

function RAArsenalNewTwoPage:mCommonTitleCCB_onBack()
    RARootManager.CloseAllPages()
end
--endregion
