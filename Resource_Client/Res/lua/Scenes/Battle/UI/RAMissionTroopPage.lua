RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RAFightDefine')

local battle_mission_conf = RARequire('battle_mission_conf')
local battle_unit_conf = RARequire('battle_unit_conf')
local battle_map_conf = RARequire('battle_map_conf')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAGuideManager=RARequire("RAGuideManager")
local RAResManager = RARequire('RAResManager')
RARequire("BasePage")
local RAMissionTroopPage = BaseFunctionPage:new(...)
local Utilitys = RARequire('Utilitys')


local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Guide.MSG_Guide then  
        --新手相关
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        --if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEMarchNode then
             if constGuideInfo.showGuidePage == 1 then
                -- mGuideMarchNode
                local confirmNode = UIExtend.getCCNodeFromCCB(RAMissionTroopPage.ccbfile, "mMarchBtn")
                local pos = ccp(0, 0)
                pos.x, pos.y = confirmNode:getPosition()
                local worldPos = confirmNode:getParent():convertToWorldSpace(pos)
                local size = confirmNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                RAMissionTroopPage.canClick = true
            end
        --end 
    end
end

local RefreshScrollViewType = 
{
    SliderBarMove = 0,
    SliderBarEnd = 1,
    Max = 2,
    Minimum = 3
}

local RAMissionTroopContentCell = {}

function RAMissionTroopContentCell:new(o)
	o = o or {}
	--当前兵种的最大数目
    o.mArmyMaxCount = 0
    --当前兵种选中的项目
    o.mArmySelectCount = 0
    o.mArmyLimitLastNum = 0

    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMissionTroopContentCell:setData(data)
	self.data = data
	self.confData = battle_unit_conf[self.data.id]
	self.mArmyMaxCount = self.data.maxCount
	if self.confData.icon == nil then 
		self.confData.icon = 'Soldier_Small_100000.png'
	end  
end

function RAMissionTroopContentCell:onUnLoad(cellRoot)
	local ccbfile = cellRoot:getCCBFileNode()
    if ccbfile ~= nil then            
        UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
        local sliderNode = ccbfile:getCCNodeFromCCB('mBarNode')
        sliderNode:removeAllChildrenWithCleanup(true)

        if self.editBox then
            self.editBox:removeFromParentAndCleanup(true)
            self.editBox = nil
        end
    end        
    self.mSlider = nil
end

function RAMissionTroopContentCell:sliderBegan(sliderNode)
	 print("RATroopChargeContentCell:sliderBegan")
end

function RAMissionTroopContentCell:sliderMoved(sliderNode)
	if self.mSlider ~= nil then
        self.mArmySelectCount = math.ceil(self.mSlider:getValue())
        self:refreshCellContent(self.mArmyLimitLastNum*self.confData.population)
        RAMissionTroopPage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarMove, self.confData.id, self.mArmySelectCount)
    end
end

function RAMissionTroopContentCell:sliderEnded(sliderNode)
	if self.mSlider ~= nil then
        self.mArmySelectCount = math.ceil(self.mSlider:getValue())
        RAMissionTroopPage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarEnd, self.confData.id, self.mArmySelectCount)
    end
end

function RAMissionTroopContentCell:onAddBtn()
    -- body
    if self.mSlider == nil then return end
    local value = math.ceil(self.mSlider:getValue())
    if 0 < self.mArmyLimitLastNum and value < self.mArmyMaxCount then
        value = tonumber(value+1)
        self.mSlider:setValue(value)
        self:sliderEnded()
    end
end

function RAMissionTroopContentCell:onSubBtn()
    -- body
    if self.mSlider == nil then return end
    local value = math.ceil(self.mSlider:getValue())
    if value >= 1 then
        value = tonumber(value-1)
        self.mSlider:setValue(value)
        self:sliderEnded()
    end
end

function RAMissionTroopContentCell:onRefreshContent(cellRoot)
	local ccbfile = cellRoot:getCCBFileNode()
    if ccbfile ~= nil then
    	UIExtend.setCCLabelString(ccbfile, 'mCellName', _RALang(self.confData.name))
    	UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', self.confData.icon) 

    	UIExtend.setCCLabelString(ccbfile, 'mLevelLabel', '')
    	UIExtend.setCCLabelString(ccbfile, 'mSlashLabel', '/')

    	UIExtend.setCCLabelString(ccbfile,"mCellExplain",_RALang('@battleUnitCountExplain',self.confData.population))
    	self.mWantTrainingNum = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mWantTrainingNum') 

    	 local editboxEventHandler = function(eventType, node)
                --body
            CCLuaLog(eventType)
            if eventType == "began" then
               -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
               -- triggered when an edit box loses focus after keyboard is hidden.
               local valueStr = self.editBox:getText()
               local value = tonumber(valueStr) or 0
               if value > self.mArmyMaxCount then
                   value = self.mArmyMaxCount
               end
               local maxNum = self.mArmySelectCount + self.mArmyLimitLastNum
               if maxNum < value then
                   value = self.mArmySelectCount + self.mArmyLimitLastNum
               end
               -- self.mArmySelectCount = value
               -- self.mSlider:setValue(self.mArmySelectCount)
               self.mArmySelectCount = math.ceil(value)
               if self.mSlider ~= nil then
                   self.mSlider:setValue(self.mArmySelectCount)
               end
               if self.editBox then
                   self.editBox:setText(tostring(self.mArmySelectCount))
               end
               RAMissionTroopPage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarEnd, self.confData.id, self.mArmySelectCount)
               -- RAMissionTroopPage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarEnd, self.mArmyId, self.mArmySelectCount)
            elseif eventType == "changed" then
               -- triggered when the edit box text was changed.
            elseif eventType == "return" then
               -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end

    	local inputNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputNode")
        local editBox = UIExtend.createEditBox(ccbfile,"mInputBG",inputNode,editboxEventHandler,nil,nil,kEditBoxInputModeNumeric,22,nil,ccc3(255,255,255),2)
        self.editBox = editBox
            --不适用原生控件
        self.editBox:setIsShowTTF(true)
        self.editBox:setText(tostring(self.mArmySelectCount))

    	local slider = UIExtend.getControlSliderSpriteNew('mBarNode', ccbfile, true)
    	slider:registerScriptSliderHandler(self)
        self.mSlider = slider
        self.mSlider:setMinimumValue(0)
        self.mSlider:setMaximumValue(self.mArmyMaxCount)
        self.mSlider:setLimitMoveValue(1)
        self.mSlider:setMaximumAllowedValue(self.mArmyLimitLastNum + self.mArmySelectCount)
        self.mSlider:setValue(self.mArmySelectCount)

    	self:updateTroopNum()   
    end 
end

function RAMissionTroopContentCell:refreshCellContent(armyLimitLastNum)
	if self.selfCell ~= nil then   
        local ccbfile = self.selfCell:getCCBFileNode()       
        if ccbfile ~= nil then
        	self:updateTroopNum()   
            --UIExtend.setCCLabelString(ccbfile, 'mWoundedNum', tostring(self.mArmySelectCount))
            if self.editBox then
               self.editBox:setText(tostring(self.mArmySelectCount))
            end                
        end
        local num = math.floor(armyLimitLastNum/self.confData.population)
        if num ~= self.mArmyLimitLastNum then
            self.mArmyLimitLastNum = num
            if self.mSlider ~= nil then
                local maxNum = self.mArmySelectCount + self.mArmyLimitLastNum
                self.mSlider:setMaximumAllowedValue(maxNum)
            end
        end
    end
end

function RAMissionTroopContentCell:updateTroopNum()
	-- self.mWantTrainingNum:setString(self.mArmySelectCount .. '/' .. self.mArmyMaxCount)
	self.mWantTrainingNum:setString(self.mArmyMaxCount)
end

function RAMissionTroopPage:Enter(data)

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
    end
    self:registerMessage()
	if data == nil or data.missionId == nil then 
		data = {}
		data.missionId = 51
	end 
	--data.missionId = 51
	self.dungeonId = data.dungeonId
	self.missionData = battle_mission_conf[data.missionId]
	self.populationLimit = self.missionData.populationLimit
	if self.populationLimit == nil then 
		self.populationLimit = 0
	end 
	self.mapData = battle_map_conf[self.missionData.mapid]
	self.mArmySelectMap = {}
	self:initUnitInfo()

	self.ccbfile = UIExtend.loadCCBFile("RABattleChargePageNew.ccbi", RAMissionTroopPage)
	self.mTroopChargeSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")
	
	self.mBattleSceneNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mBattleSceneNode')

	self.mStaminaNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mStaminaNum')
	self.mStaminaNum:setString(_RALang('@Exhaustion') .. 5)

	self.mArmyNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mArmyNum')
	self.mArmyNum:setString('')

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")

	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@MarchQueueUseName"))
	UIExtend.setCCLabelString(self.ccbfile,"mCharpterExplain",_RALang(self.missionData.battleDescribe))
	UIExtend.setCCLabelString(self.ccbfile,"mArmySlashLabel",'/')
	UIExtend.setCCLabelString(self.ccbfile,"mMaxArmyNum",self.populationLimit)

	UIExtend.addSpriteToNodeParent(self.ccbfile, "mBattleSceneNode",self.mapData.small_pic,nil, nil, 20000)
	-- self:updateTroopNum()
	-- self:refreshScrollView()

    --self.showItems = data.reward.showItems
    --刷新奖励
    self:_refreshRewards()
    
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        self:refreshScrollView(RefreshScrollViewType.Max)
    else
    	self:refreshScrollView()
    end
    self:updateTroopNum()

    --add by xinping
    self:_initGuide()
end

--刷新奖励
function RAMissionTroopPage:_refreshRewards()
    -- body
    --先使用ccbi中的规定配置奖励
    if true then return end

    for i=1,3 do
        local mCellCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,'mCellCCB'..i)
        mCellCCB:setVisible(false)
    end
    
    if #self.showItems < 1 then return end
    for i=1,#self.showItems do
        local showItem = self.showItems[i]
        local mCellCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,'mCellCCB'..i)
        mCellCCB:setVisible(true)

        local icon, name = RAResManager:getIconByTypeAndId(tonumber(showItem.itemType), tonumber(showItem.itemId))
        if icon then
            UIExtend.addSpriteToNodeParent(mCellCCB, "mIconNode", icon)
        end
        if name then
            UIExtend.setCCLabelString(mCellCCB, "mCellName", _RALang(name))   
        end

        local count = showItem.itemCount
        if count > 0 then
            UIExtend.setCCLabelString(mCellCCB, "mCellNum", '+'..tostring(count))   
        end
    end
end

function RAMissionTroopPage:initUnitInfo()
	
	local troopsText = self.missionData.unitControl

	local unitTexts = Utilitys.Split(troopsText, ",")
	self.unitMap = {}
	self.totalCount = 0
	self.curCount = 0
	for k,unitText in pairs(unitTexts) do
		local unitInfo = Utilitys.Split(unitText,'_')
		local unit = {}
		unit.id = tonumber(unitInfo[1])
		unit.maxCount = tonumber(unitInfo[2])
		self.totalCount = self.totalCount + unit.maxCount
		unit.count = tonumber(unitInfo[3])
		self.unitMap[unit.id] = unit
		self.mArmySelectMap[unit.id] = 0 
	end
	
end

-- function RAMissionTroopPage:OnAnimationDone(ccbfile)
--     local lastAnimationName = ccbfile:getCompletedAnimationName()

--     if lastAnimationName=="InAni"  then
--         if self.keepAnimationDone then return end
--         if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
--             self.keepAnimationDone=true
--             self:_initGuide()    
--         end
--     end 
-- end

function RAMissionTroopPage:_initGuide()
    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide()  then
        RAGuideManager.gotoNextStep()
    else
        self.canClick=true
    end
end

function RAMissionTroopPage:updateTroopNum()
	local selectCount = self:refreshArmySelectedCount(true)
	-- self.mArmyNum:setString(selectCount .. '/' .. self.populationLimit)
	self.mArmyNum:setString(selectCount)
end


function RAMissionTroopPage:onAddArmyBtn()
	-- body
end

function RAMissionTroopPage:registerMessage()

    if RAGuideManager.partComplete.Guide_UIUPDATE then
         MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
         -- MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end 
end

function RAMissionTroopPage:removeMessageHandler()
    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
        -- MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end

end

function RAMissionTroopPage:mCommonTitleCCB_onBack()
	RARootManager.ClosePage('RAMissionTroopPage')
end

function RAMissionTroopPage:refreshSelectEffectUI(armyId)
	local selectCount = self:refreshArmySelectedCount(true)
	selectCount = battle_unit_conf[armyId].population + selectCount

	if selectCount > self.populationLimit then 		
			self.ccbfile:runAnimation('ShakeAni')
	end
end

function RAMissionTroopPage:RefreshUIWhenSelectedChange(actionType, armyId, selectCount)
    if actionType == RefreshScrollViewType.SliderBarMove then        
        self.mArmySelectMap[armyId] = selectCount
        self:updateTroopNum()
        -- self:refreshScrollViewCell()
        -- self:refreshSelectEffectUI()
    end

    if actionType == RefreshScrollViewType.SliderBarEnd then
        self.mArmySelectMap[armyId] = selectCount
        --self:refreshSelectEffectUI()
        self:updateTroopNum()
        self:refreshScrollViewCell()
        self:refreshSelectEffectUI(armyId)
    end

    -- if actionType == RefreshScrollViewType.Max then
    --     local armyMap, maxLevel, totalFree = RACoreDataManager:getFreeArmyLevelMap()
    --     self:refreshScrollView(armyMap, maxLevel, true, true)  
        
    --     self:updateTroopNum()
    -- end

    -- 直接刷新所有UI

    --[[
    if actionType == RefreshScrollViewType.Minimum then
        local armyMap, maxLevel, totalFree = RACoreDataManager:getFreeArmyLevelMap()
        self:refreshScrollView(armyMap, maxLevel, false, true) 
        self:refreshSelectEffectUI()
        self.mMarchFreeCount = totalFree
    end

    -- 自动配置的时候刷新
    if actionType == RefreshScrollViewType.Max then
        local armyMap, maxLevel, totalFree = RACoreDataManager:getFreeArmyLevelMap()
        self:refreshScrollView(armyMap, maxLevel, true, true)  
        self:refreshSelectEffectUI()
        self.mMarchFreeCount = totalFree
    end
    --]]
end

function RAMissionTroopPage:refreshScrollView(selectType)
    if self.mTroopChargeSV == nil then return end

    self.mTroopChargeSV:removeAllCell()
    self.mArmyCellMap = {}
    for k,v in pairs(self.unitMap) do

    	local handlerDetail = RAMissionTroopContentCell:new()
    	handlerDetail:setData(v)

    	local ccbDetailCell = CCBFileCell:create()
    	ccbDetailCell:registerFunctionHandler(handlerDetail)
    	ccbDetailCell:setCCBFile('RABattleChargeCellNew.ccbi')
        self.mTroopChargeSV:addCellBack(ccbDetailCell)
        handlerDetail.selfCell = ccbDetailCell
        self.mArmyCellMap[v.id] = handlerDetail

        if selectType == RefreshScrollViewType.Max then 
        	handlerDetail.mArmySelectCount = v.maxCount
        	self.mArmySelectMap[v.id] = v.maxCount
        end
    end

    self.mTroopChargeSV:orderCCBFileCells()
    self:refreshScrollViewCell()
end

function RAMissionTroopPage:refreshScrollViewCell()
    -- 出征上限刷新
    local selectCount = self:refreshArmySelectedCount(true)
    local canSelectCount = self.populationLimit - selectCount
    if self.mArmyCellMap ~= nil then
        for armyId, cellHandler in pairs(self.mArmyCellMap) do
            if cellHandler ~= nil then
                cellHandler:refreshCellContent(canSelectCount)
            end
        end
    end
end

-- 选择兵力改变的时候需要刷新
function RAMissionTroopPage:refreshArmySelectedCount(isCheck)
    local countTotal = 0    
    
    for armyId, count in pairs(self.mArmySelectMap) do
        if isCheck then
            countTotal = countTotal + count*battle_unit_conf[armyId].population
        else
            countTotal = countTotal + count*battle_unit_conf[armyId].population
        end
    end

    return countTotal
end

function RAMissionTroopPage:onMarchBtn()

    if RAGuideManager.isInGuide() then
        if self.canClick == false then return end
            self.canClick = false
        if RAGuideManager.partComplete.Guide_UIUPDATE  then
            RARootManager.RemoveGuidePage()
        end
    end
	
	local countTotal = self:refreshArmySelectedCount()
	if countTotal == 0 then 
		RARootManager.ShowMsgBox(_RALang("@selectTroop"))
		self.canClick = true
		return 
	end

	local troops = {}
	--local troopText = ''
	for armyId, count in pairs(self.mArmySelectMap) do  
		local text = ''

		local fullCount = math.floor(count/self.unitMap[armyId].count)
		local singleCount = count%self.unitMap[armyId].count

		if fullCount > 0 then 
			text = armyId .. '_' .. self.unitMap[armyId].count .. '_' .. fullCount
			troops[#troops+1] = text
		end

		if singleCount > 0 then 
			text = armyId .. '_' .. singleCount .. '_' .. 1 .. '_' .. self.unitMap[armyId].count
			troops[#troops+1] = text
		end  
        --local data = {}
        --data.id = armyId
        --data.count = count
        --data.maxCount = self.unitMap[data.id].count
        --troops[armyId] = data
    end

    local troopText = table.concat( troops, ",")
    RARootManager.ClosePage('RAMissionTroopPage')
    local params =
    {
    	dungeonId = self.dungeonId,
		missionId = self.missionData.id,
		troopText = troopText
	}
	RARootManager.ChangeScene(SceneTypeList.BattleScene, nil, params)

	--RARootManager.ChangeScene(SceneTypeList.BattleScene, nil, {missionId = self.mMissionId, reward = msg.reward})
end

function RAMissionTroopPage:Exit()
    self:removeMessageHandler()
    self.mTroopChargeSV:removeAllCell()
    self.canClick = nil
    UIExtend.unLoadCCBFile(self) 
end


return RAMissionTroopPage