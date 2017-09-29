--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--建筑资讯界面
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local build_conf = RARequire("build_conf")
local Const_pb =RARequire('Const_pb')
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAQueueManager = RARequire("RAQueueManager")
local RABuildInformationUtil = RARequire("RABuildInformationUtil")
local RABuildEffect = RARequire("RABuildEffect")

RARequire("RABuildingUtility")

local buildQueueDeleteMsg = MessageDef_Queue.MSG_Building_DELETE

local RABuildInformationNewPage = BaseFunctionPage:new(...)

--endregion

local TAG = 1000
local maxCol =7
local focusCell = nil
local mLabelPosition = {}


local TAB_TYPE = {
	BUILDING_INFO = 1,
	BUILDING_DETAILS = 2
}

local OnReceiveMessage = function(message)
   if message.messageID == buildQueueDeleteMsg then
   		RABuildInformationNewPage.curBuildIsUpgrade=false
   		if RABuildInformationNewPage.curPageType == TAB_TYPE.BUILDING_DETAILS then
   			RABuildInformationNewPage:addCell()
   		end
   end 
end

function RABuildInformationNewPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RABuildingMoreInfoPageNew.ccbi",self)
	self.buildData = data
	self.buildId = data.id
	self.curBuildData = data.confData
	self.allLevelsData = RABuildingUtility.getBuildInfoByType(self.curBuildData.buildType,true) 
	
	self:registerMessageHandler()
	
	self:initBtn()

	self:refreshUI()

	self:setCurrentPage(TAB_TYPE.BUILDING_INFO)
end

function RABuildInformationNewPage:initBtn()
	--初始化
	self.tabArr = {} --三个分页签
	self.tabArr[TAB_TYPE.BUILDING_INFO] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mUpgradeConditionBtn')
	self.tabArr[TAB_TYPE.BUILDING_DETAILS] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mUpgradeEffectBtn')

	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

	self.levelLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mCellTitleLabel")
	--self.levelLabel:setString(_RALang("@Level"))
	self.levelLabelNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mDetailsTitleNode")
end

function RABuildInformationNewPage:refreshUI()
	--名称
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang(self.curBuildData.buildName))
	--等级
	UIExtend.setCCLabelString(self.ccbfile,"mLevel",self.curBuildData.level)

	--UIExtend.setSpriteImage(self.ccbfile, {mSuperMinePic = self.curBuildData.buildArtImg})
	UIExtend.getCCSpriteFromCCB(self.ccbfile,"mSuperMinePic"):setVisible(false)

	self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
    self.mExplainLabel:setString(_RALang(self.curBuildData.buildDes))
    self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
    UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

    --判断是否正在升级
	self.curBuildIsUpgrade=RAQueueManager:isBuildingUpgrade(self.buildId)

	if self.curBuildData.buildType == Const_pb.CONSTRUCTION_FACTORY or self.curBuildData.limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then 
        local RAWorldConfig =  RARequire('RAWorldConfig')
        local World_pb =  RARequire('World_pb')
        local flagCfg = RAWorldConfig.RelationFlagColor[World_pb.SELF]
        CCTextureCache:sharedTextureCache():addColorMaskKey(flagCfg.key, RAColorUnpack(flagCfg.color))
        self.spineNode = SpineContainer:create(self.curBuildData.buildArtJson .. ".json",self.curBuildData.buildArtJson ..".atlas",flagCfg.key)
        -- self.spineNode = SpineContainer:create(self.curBuildData.buildArtJson .. ".json",self.curBuildData.buildArtJson ..".atlas",'INSIDE_COLOR')
    else
        self.spineNode = SpineContainer:create(self.curBuildData.buildArtJson .. ".json",self.curBuildData.buildArtJson ..".atlas")
    end 

    self.mSpineBuildNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mSpineBuildNode")
    self.mSpineBuildNode:addChild(self.spineNode)
    self.spineNode:setScale(0.7)
    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE,-1)

    --是否显示改建按钮
    if self.curBuildData.rebuildGroup then
    	UIExtend.setNodeVisible(self.ccbfile, "mConfirmBtnNode" ,false)
    	UIExtend.setNodeVisible(self.ccbfile, "mRebuildingBtnNode" ,true)
    else
    	UIExtend.setNodeVisible(self.ccbfile, "mRebuildingBtnNode" ,false)
    	UIExtend.setNodeVisible(self.ccbfile, "mConfirmBtnNode" ,true)	
    end
end

function RABuildInformationNewPage:onBuildingInfoBtn()
    self:setCurrentPage(TAB_TYPE.BUILDING_INFO)
end

function RABuildInformationNewPage:onUpgradeEffectBtn()
    self:setCurrentPage(TAB_TYPE.BUILDING_DETAILS)
end

function RABuildInformationNewPage:setCurrentPage(pageType)
    -- body
    self.curPageType = pageType

    for k,v in pairs(self.tabArr) do
        if pageType == k then 
            v:setEnabled(false)
        else
            v:setEnabled(true)
        end  
    end

    if pageType == TAB_TYPE.BUILDING_INFO then 
        self:initBuildingInfoPanel()
    elseif pageType == TAB_TYPE.BUILDING_DETAILS then 
        self:initBuildDetailsPanel()
    end 
end

function RABuildInformationNewPage:initBuildingInfoPanel()
	-- body
	UIExtend.setNodeVisible(self.ccbfile,"mInformationLabelNode",true)
	UIExtend.setNodeVisible(self.ccbfile,"mDetailsLabelNode",false)
	UIExtend.setNodeVisible(self.ccbfile,"mSpecialTitleNode",false)

	self:addCell()
end

function RABuildInformationNewPage:initBuildDetailsPanel()
	-- body
	if self.curBuildData.buildType== Const_pb.RADAR then
		UIExtend.setNodeVisible(self.ccbfile,"mInformationLabelNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mDetailsLabelNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mSpecialTitleNode",true)

		UIExtend.setCCLabelString(self.ccbfile,"mSpecialTitleLabel2",_RALang("@ElectricConsume"))
		UIExtend.setCCLabelString(self.ccbfile,"mSpecialTitleLabel3",_RALang("@ImproveEffect"))
		
	else
		UIExtend.setNodeVisible(self.ccbfile,"mInformationLabelNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mSpecialTitleNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mDetailsLabelNode",true)
	end
	
	self:addCell()
end

function RABuildInformationNewPage:getTotalValue(buildType, key)
	-- body
	if key == nil or buildType == nil then return 0 end
	local RABuildManager = RARequire("RABuildManager")
	local buildTable = RABuildManager:getBuildDataArray(buildType)
    local totalValue = 0
    
    for i = 1 ,#buildTable do
        local buildConfData = buildTable[i].confData
        if key == 'totalTrainSpeed' then --训练速度
        	totalValue = totalValue + buildConfData.trainSpeed
        elseif key == 'TotaleWoundedLimit' then  --伤病上限
        	totalValue = totalValue + buildConfData.woundedLimit
        elseif key == 'TotaleWoundedLimit' then  --伤病上限
        	totalValue = totalValue + buildConfData.woundedLimit
        	
        elseif key == 'totalResOutPut' then  --资源总产量/小时
        	totalValue = totalValue + buildConfData.resPerHour
        	
        elseif key == 'totalResUpperLimit' then  --资源总上限
        	totalValue = totalValue + buildConfData.resLimit			
        end
    end

    return totalValue
end

---------------------------------------RABuildInformationNewPageCell-----------------------------------
local RABuildInformationNewPageCell = {}
function RABuildInformationNewPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildInformationNewPageCell:createLabel(str,node,levelLabel,tag)
    return RABuildInformationUtil:createLabel(node,str,levelLabel,tag)
end

function RABuildInformationNewPageCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
	self.ccbfile = ccbfile

	if self.index == 1 then                           --建筑信息页签
		local mTag = self.mTag
		local keyTab = self.mKeyTab
		local titleTab = self.mTitleTab
		local buildInfo = RABuildInformationNewPage.curBuildData

		local key = keyTab[mTag]
		local title = titleTab[mTag]
		local currValue = buildInfo[key]
		
		if key == "effectID" then
            local sub = RAStringUtil:split(currValue, "_")
            if sub and sub[2] then
            	currValue = tonumber(sub[2])
            	--加快建造类型buff由秒修改成小时
            	if tonumber(sub[1]) == 417 then
            		currValue = Utilitys.createTimeWithFormat(currValue)
            		--currValue = math.floor(currValue/3600)
            	end
            end
		end

		if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
			if key == "buildingAttack" or key == "buildingDefence" or key== "defenceTotalHP" or key== "defenceCurrHP" then  --
        	   currValue = RABuildInformationUtil:getDefenceAttrByKey(RABuildInformationNewPage.buildData, key)
        	end
        end

        --总有一些建筑要总值
        local totalVlaue = RABuildInformationNewPage:getTotalValue(buildInfo.buildType, key)
        if totalVlaue > 0 or currValue == nil then
        	currValue = totalVlaue
        end

        local currValueStr = currValue

		if key == 'totalTrainSpeed' or key == 'trainSpeed' or key == 'marketTax' then --士兵训练总速度，训练速度，市场税率
			currValueStr = currValueStr .. '%'
		else
			if buildInfo.buildType ~= Const_pb.EINSTEIN_LODGE then    --不是 爱因斯坦时光机器 才进去
				currValueStr = Utilitys.formatNumber(currValue)	
			end
		end
		local labels = {}
		labels["mAttribute"] = title
		labels["mBasicData"] = currValueStr

		local commanderAddition = ""
		--消耗电力的时候不显示第三列
		local addNum = RABuildEffect:getAddValueByEffect(currValue,buildInfo.buildType,key)

		if key == 'totalTrainSpeed' then   --兵营里面的训练总数
			addNum = RABuildEffect:getAddValueByEffect(currValue,buildInfo.buildType,'trainSpeed')
		end
		
		if key == 'TotaleWoundedLimit' then
			addNum = RABuildEffect:getAddValueByEffect(currValue,buildInfo.buildType,'woundedLimit')
		end

		if key == 'totalResOutPut' then
			addNum = RABuildEffect:getAddValueByEffect(currValue,buildInfo.buildType,'resPerHour')
		end

		if key == 'totalResUpperLimit' then
			addNum = RABuildEffect:getAddValueByEffect(currValue,buildInfo.buildType,'resLimit')
		end

		if addNum == 0 then
			addNum = ""
		elseif addNum > 0 then
			
			--消耗的，负值
			if key == 'marketTax' or key == 'electricConsume' then
				addNum = _RALang("@MinusWithParam",addNum)
			else
				addNum = _RALang("@EffectAddValue",addNum)	
			end
			
		end 
		--if key ~= "electricConsume" then
			commanderAddition = addNum
		--end
		if (key == 'marketTax' or key == 'totalTrainSpeed') and commanderAddition ~= '' then  --市场税率
			commanderAddition = commanderAddition .. '%'
		end
		
		if key == 'trainSpeed' then
			commanderAddition = ''
		end
		labels["mCommanderAddition"] = commanderAddition

		UIExtend.setStringForLabel(ccbfile,labels)
	elseif self.index == 2 then                           --建筑详情页签
		local buildInfo = self.mBuildInfo
		local cellLabelNode = UIExtend.getCCNodeFromCCB(ccbfile,"mCellLabelNode")
		local levelLabel = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mCellLabel")

        for i=1,maxCol do
			local label = cellLabelNode:getChildByTag(i+TAG)
			if label then
				-- cellLabelNode:removeChildByTag(i+TAG,true)
				label:setVisible(false)
			end 
		end

        --cellLabelNode:removeAllChildren()
        local txtTab = {}
--        local label = self:createLabel(buildInfo.level,cellLabelNode,levelLabel,100)
--	    table.insert(txtTab,label)

		--UIExtend.setCCLabelString(ccbfile,"mCellLabel",buildInfo.level)
		--levelLabel:setPositionX(levelLabel:getPositionX() + 1)
		
		local label=nil
		for i,key in ipairs(RABuildInformationNewPage.keyTab) do
			local valueStr = buildInfo[key]
			if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
				if key == "buildingAttack" or key == "buildingDefence" or key== "defenceTotalHP" then  --
	            	valueStr = RABuildInformationUtil:getDefenceAttrByKey(buildInfo, key)
	        	end
        	end
        	if key == 'trainSpeed' or key == 'marketTax' then  --士兵训练速度，市场税率
        		valueStr = valueStr.."%"
        	end

        	if key == 'timeMachineBuff' then
        		local effectIDs = RAStringUtil:split(buildInfo.effectID, "_")
        		local effectTime = tonumber(effectIDs[2])
        		valueStr = Utilitys.createTimeWithFormat(effectTime)
        	end

			label = self:createLabel(valueStr,cellLabelNode,levelLabel,i+TAG)
			table.insert(txtTab,label)
		end
		local sectionTotalSize = #txtTab
        local positionTabel = RABuildInformationUtil:calcSectionPos(520,sectionTotalSize)

		for k,label in pairs(txtTab) do
			local position = positionTabel[k]
            label:setPosition(position.x,position.y)
            label:setVisible(true)
		end
		
		if RABuildInformationNewPage.curBuildData.level == buildInfo.level then
				UIExtend.setNodeVisible(ccbfile,"mCellBG1",false)
				UIExtend.setNodeVisible(ccbfile,"mCellBG2",true)
		else
				UIExtend.setNodeVisible(ccbfile,"mCellBG1",true)
				UIExtend.setNodeVisible(ccbfile,"mCellBG2",false)
		end 

		--正在升级的特效
		if RABuildInformationNewPage.curBuildIsUpgrade then
			if RABuildInformationNewPage.curBuildData.level +1 == buildInfo.level then
				UIExtend.setNodeVisible(ccbfile,"mCellBG3",true)
				UIExtend.setNodeVisible(ccbfile,"mNextLevelArrow",true)
				
			else
				UIExtend.setNodeVisible(ccbfile,"mCellBG3",false)
				UIExtend.setNodeVisible(ccbfile,"mNextLevelArrow",false)
			end 
		else
			UIExtend.setNodeVisible(ccbfile,"mCellBG3",false)
			UIExtend.setNodeVisible(ccbfile,"mNextLevelArrow",false)
		end 
	elseif self.index == 3 then                           --雷达 特殊的
		local buildInfo = self.mBuildInfo
		local Label1 = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mSpecialLabel1")
		local Label3 = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mSpecialLabel3")
		UIExtend.setCCLabelString(ccbfile,"mSpecialLabel1",buildInfo.level)
		local key = RABuildInformationNewPage.keyTab[2]
		local keyStr = buildInfo[key]
		UIExtend.setCCLabelString(ccbfile,"mSpecialLabel2",keyStr)

		if buildInfo.level <= 10 then
			local keyStr = '@Build_20220'..buildInfo.level.."_Tips"
			if buildInfo.level >= 10 then
				keyStr = '@Build_2022'..buildInfo.level.."_Tips"
			end
			UIExtend.setCCLabelString(ccbfile,"mSpecialLabel3",_RALang(keyStr))
		else
			UIExtend.setCCLabelString(ccbfile,"mSpecialLabel3","")
		end 	
	end
end
----------------------------------------------------------------------------------------------------

----------------add  cell
function RABuildInformationNewPage:buildingInfoCell(scrollView)

	local col,keyTab,titleTab = RABuildInformationUtil:initBuildInfoAttr(self.buildData)

	-- dump(self.curBuildData)
	for i=1,col do
       	local cell = CCBFileCell:create()
		local panel = RABuildInformationNewPageCell:new({
				index = 1,
				mTag = i,
				mKeyTab = keyTab,
				mTitleTab = titleTab
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RABuildingMoreInfoCell1.ccbi")
		scrollView:addCellBack(cell)
    end
    scrollView:orderCCBFileCells(scrollView:getViewSize().width)
end

function RABuildInformationNewPage:buildingDetailsCell(scrollView)

  	self:initTabTitle()
  	
  	local curCellPosY=nil
    local count = #self.allLevelsData
    focusCell = nil
    for i,info in ipairs(self.allLevelsData) do
    	local cell = nil
    	if self.curBuildData.buildType== Const_pb.RADAR then
	   		cell = CCBFileCell:create()
			local radarPanel = RABuildInformationNewPageCell:new({
					mBuildInfo = info,
					index = 3
	        })
			cell:registerFunctionHandler(radarPanel)
			cell:setCCBFile("RABuildingMoreInfoCell3.ccbi")
			scrollView:addCellBack(cell)
	    else
	    	cell = CCBFileCell:create()
			local panel = RABuildInformationNewPageCell:new({
					mBuildInfo = info,
					index = 2
	        })

            if self.curBuildData.level == info.level then
                focusCell = cell
            end

			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RABuildingMoreInfoCell2.ccbi")
			scrollView:addCellBack(cell)
	    end
    
--		--记录当前的等级cell的位置
--		if self.curBuildData.level == info.level  then
--			local cellH = cell:getContentSize().height
--			curCellPosY=cellH*(count-i-3)
--		end
    end

    scrollView:orderCCBFileCells(scrollView:getViewSize().width)
    if focusCell ~= nil then
        focusCell:locateTo(CCBFileCell.LT_Mid)
    end
    
--    if curCellPosY then
--   		scrollView:setContentOffset(ccp(0,-curCellPosY))
--    end 
end

function RABuildInformationNewPage:addCell()
	-- body
	self.scrollView:removeAllCell()

    local scrollView = self.scrollView

--    for i = 1,4 do
--  		UIExtend.setNodeVisible(self.ccbfile,"mLineNode"..i,false)
--  	end

    if self.curPageType == TAB_TYPE.BUILDING_INFO then
    	self:buildingInfoCell(scrollView)
    elseif self.curPageType == TAB_TYPE.BUILDING_DETAILS then
    	self:buildingDetailsCell(scrollView)
    end
  	--
	

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		--设置边缘特效使用
    	--scrollView:setEdgeEffect(0);
		scrollView:setTouchEnabled(true)
	end
end

function RABuildInformationNewPage:createLabel(str,tag)
    return RABuildInformationUtil:createLabel(self.levelLabelNode,str,self.levelLabel,tag)
end


function RABuildInformationNewPage:initTabTitle()
	-- body
	local col = 0
	local txtTab={}
	local keyTab={}
	local titleTab={}
	local buildInfo = self.curBuildData
	local offDis = 10
	local label=nil

    --self.levelLabelNode:removeAllChildren();
    --等级
    label = self:createLabel(_RALang("@Level"),col+TAG)
	table.insert(txtTab,label)
	table.insert(titleTab,_RALang("@Level"))
	table.insert(keyTab,"level")

	if buildInfo.electricGenerate then
		--产电量
		col = col+1
		label = self:createLabel(_RALang("@ElectricGenerate"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@ElectricGenerate"))
		table.insert(keyTab,"electricGenerate")
	end 
	if buildInfo.electricConsume then
		--占用电量

		col = col+1
		label = self:createLabel(_RALang("@ElectricConsume"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@ElectricConsume"))
		table.insert(keyTab,"electricConsume")
	end 
	-- if buildInfo.resPerMin then
	-- 	--产资源每min
	-- 	col = col+1
	-- 	label = self:createLabel(_RALang("@ResPerMin"),col+TAG)
	-- 	table.insert(txtTab,label)
	-- 	table.insert(titleTab,_RALang("@ResPerMin"))
	-- 	table.insert(keyTab,"resPerMin")
	-- end 
	if buildInfo.resPerHour then
		--产资源每min
		col = col+1
		label = self:createLabel(_RALang("@ResPerHour"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@ResPerHour"))
		table.insert(keyTab,"resPerHour")
	end 
	if buildInfo.resLimit then
		--产资源上限
		col = col+1
		label = self:createLabel(_RALang("@ResLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@ResLimit"))
		table.insert(keyTab,"resLimit")
	end 
	-- if buildInfo.resProtect then
	-- 	--资源保护
	-- 	col = col+1
	-- 	label = self:createLabel(_RALang("@ResProtect"),col+TAG)
	-- 	table.insert(txtTab,label)
	-- 	table.insert(titleTab,_RALang("@ResProtect"))
	-- 	table.insert(keyTab,"resProtect")
	-- end

	if buildInfo.resProtectA then
     	--资源保护:黄金
     	col = col+1
     	label = self:createLabel(_RALang("@ResProtectA"),col+TAG)
     	table.insert(txtTab,label)
     	table.insert(titleTab,_RALang("@ResProtectA"))
     	table.insert(keyTab,"resProtectA")
     end 

     if buildInfo.resProtectB then
     	--资源保护:石油
     	col = col+1
     	label = self:createLabel(_RALang("@ResProtectB"),col+TAG)
     	table.insert(txtTab,label)
     	table.insert(titleTab,_RALang("@ResProtectB"))
     	table.insert(keyTab,"resProtectB")
     end 

     if buildInfo.resProtectC then
     	--资源保护:钢材
     	col = col+1
     	label = self:createLabel(_RALang("@ResProtectC"),col+TAG)
     	table.insert(txtTab,label)
     	table.insert(titleTab,_RALang("@ResProtectC"))
     	table.insert(keyTab,"resProtectC")
     end 

     if buildInfo.resProtectD then
     	--资源保护:稀土
     	col = col+1
     	label = self:createLabel(_RALang("@ResProtectD"),col+TAG)
     	table.insert(txtTab,label)
     	table.insert(titleTab,_RALang("@ResProtectD"))
     	table.insert(keyTab,"resProtectD")
     end 

	if buildInfo.resProtectPlus then
		--资源额外保护
		col = col+1
		label = self:createLabel(_RALang("@ResProtectPlus"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@ResProtectPlus"))
		table.insert(keyTab,"resProtectPlus")
	end 
	if buildInfo.trainQuantity then
		--训练数量
		col = col+1
		label = self:createLabel(_RALang("@TrainQuantity"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@TrainQuantity"))
		table.insert(keyTab,"trainQuantity")
	end
	if buildInfo.trainSpeed then
		--训练速度
		col = col+1
		label = self:createLabel(_RALang("@TrainSpeed"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@TrainSpeed"))
		table.insert(keyTab,"trainSpeed")
	end
	if buildInfo.assistTime then
		--援助减少时间
		col = col+1
		label = self:createLabel(_RALang("@AssistTime"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@AssistTime"))
		table.insert(keyTab,"assistTime")
	end 
	if buildInfo.assistLimit then
		--可受援助次数
		col = col+1
		label = self:createLabel(_RALang("@AssistLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@AssistLimit"))
		table.insert(keyTab,"assistLimit")
	end 
	if buildInfo.assistUnitLimit then
		--援助单位上限
		col = col+1
		label = self:createLabel(_RALang("@AssistUnitLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@AssistUnitLimit"))
		table.insert(keyTab,"assistUnitLimit")
	end
	if buildInfo.marketBurden then
		--市场负重
		col = col+1
		label = self:createLabel(_RALang("@MarketBurden"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@MarketBurden"))
		table.insert(keyTab,"marketBurden")
	end 
	if buildInfo.marketTax then
		--市场税率
		col = col+1
		label = self:createLabel(_RALang("@MarketTax"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@MarketTax"))
		table.insert(keyTab,"marketTax")
	end
	if buildInfo.buildupLimit then
		--集结上限
		col = col+1
		label = self:createLabel(_RALang("@BuildupLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@BuildupLimit"))
		table.insert(keyTab,"buildupLimit")
	end 
	if buildInfo.attackUnitLimit then
		--行军单位数量
		col = col+1
		label = self:createLabel(_RALang("@AttackUnitLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@AttackUnitLimit"))
		table.insert(keyTab,"attackUnitLimit")
	end
	if buildInfo.woundedLimit then
		--伤兵上限
		col = col+1
		label = self:createLabel(_RALang("@WoundedLimit"),col+TAG)
		table.insert(txtTab,label)
		table.insert(titleTab,_RALang("@WoundedLimit"))
		table.insert(keyTab,"woundedLimit")
	end 

	--如果为防御建筑，得从 battle_soldier_conf 表里面读取攻击 防御 最大生命 以及当当前生命
    if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
        local battleSoldierConf = RABuildingUtility:getDefenceBuildConfById(buildInfo.id)
        if battleSoldierConf then
            --攻击
            if battleSoldierConf.attack then
                col = col+1
				label = self:createLabel(_RALang("@BuildingAttack"),col+TAG)
				table.insert(txtTab,label)
				table.insert(titleTab,_RALang("@BuildingAttack"))
				table.insert(keyTab,"buildingAttack")
            end

            --防御
            if battleSoldierConf.defence then
                col = col+1
                label = self:createLabel(_RALang("@BuildingDefence"),col+TAG)
				table.insert(txtTab,label)
				table.insert(titleTab,_RALang("@BuildingDefence"))
				table.insert(keyTab,"buildingDefence")
            end

            --最大生命
            if battleSoldierConf.hp then
                col = col+1
                label = self:createLabel(_RALang("@DefenceTotalHP"),col+TAG)
				table.insert(txtTab,label)
				table.insert(titleTab,_RALang("@DefenceTotalHP"))
				table.insert(keyTab,"defenceTotalHP")
            end
        end
    end

    if buildInfo.buildType == Const_pb.EINSTEIN_LODGE then    --爱因斯坦时光机器
    	if buildInfo.effectID then
            --buff
            local sub = RAStringUtil:split(buildInfo.effectID, "_")
            if #sub == 2 then
	            col = col+1
	            label = self:createLabel(_RALang("@TimeMachineBuff"),col+TAG)
				table.insert(txtTab,label)
				table.insert(titleTab,_RALang("@TimeMachineBuff"))
				table.insert(keyTab,"timeMachineBuff")
			end	
        end
    end    

	self.txtTab = txtTab
	self.keyTab = keyTab

    
    local totalSectSize = #txtTab

    local positionTable = RABuildInformationUtil:calcSectionPos(520,totalSectSize)

    for k,label in pairs(txtTab) do
        local curPos = positionTable[k]
        label:setPosition(curPos.x,curPos.y)
    end
end

function RABuildInformationNewPage:registerMessageHandler()
    MessageManager.registerMessageHandler(buildQueueDeleteMsg,OnReceiveMessage)  
end

function RABuildInformationNewPage:removeMessageHandler()
    MessageManager.removeMessageHandler(buildQueueDeleteMsg,OnReceiveMessage)
end

function RABuildInformationNewPage:onClose()
	RARootManager.CloseCurrPage()
end

--建筑改造按钮
function RABuildInformationNewPage:onAlterationBtn()
	-- body
	if self.buildData.normal == 1 then
		RARootManager.OpenPage("RABuildingAlterationPopUp",{buildData = self.buildData},false, true, true)
	else
		RARootManager.ShowMsgBox(_RALang("@FullBloodCanTansform"))
	end	
end

function RABuildInformationNewPage:onConfirmBtn()
	-- body
	RARootManager.CloseCurrPage()
end

function RABuildInformationNewPage:clearTable()
	if self.txtTab then
		for i,v in pairs(self.txtTab) do
			v = nil
		end
		self.txtTab = nil
	end	

	if self.keyTab then
		for i,v in pairs(self.keyTab) do
			v = nil
		end
		self.keyTab = nil
	end
end

function RABuildInformationNewPage:Exit()
	self:clearTable()

	self.spineNode:removeFromParentAndCleanup(true)

    self.levelLabelNode:removeAllChildren()

	self.scrollView:removeAllCell()

    self.mExplainLabel:stopAllActions()
    self.mExplainLabel:setPosition(self.mExplainLabelStarP)

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RABuildInformationNewPage