--建筑升级界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local build_conf = RARequire("build_conf")
local build_limit_conf = RARequire("build_limit_conf")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RABuildManager= RARequire("RABuildManager")
local RAQueueManager= RARequire("RAQueueManager")
local Const_pb = RARequire('Const_pb')
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RACitySceneManager = RARequire("RACitySceneManager")
local const_conf = RARequire("const_conf")
local RA_Common = RARequire("common")
local RAGameConfig = RARequire("RAGameConfig")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAGuideManager=RARequire("RAGuideManager")
RARequire("RABuildingUtility")
local html_zh_cn = RARequire("html_zh_cn")
local RABuildInformationUtil = RARequire("RABuildInformationUtil")
local RAScienceManager = RARequire("RAScienceManager")
local RAScienceUtility = RARequire("RAScienceUtility")
local RARealPayManager = RARequire("RARealPayManager")

local RABuildPromoteNewPage = BaseFunctionPage:new(...)

local TAG = 1000

local DIAMONDS_TYPE = "1001"			--钻石
local RECHARGE_DIAMONDS_TYPE = "1011"	--充值的钻石

local TAB_TYPE = {
	UPGRADECONDITION = 1,
	UPGRADEEFFECT = 2
}

------ani begin----------
local RABuildingUpgradeAni = {}

function RABuildingUpgradeAni:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RABuildingUpgradeAni:init(ccbfileName)
    UIExtend.loadCCBFileWithOutPool(ccbfileName,self)

    self.ccbfile:runAnimation("Default Timeline")
end

function RABuildingUpgradeAni:release()
    UIExtend.unLoadCCBFile(self)
end
------ani end----------

--------升级效果cell
----通用
local RABuildingUpgradeEffectCommonCell = {}
function RABuildingUpgradeEffectCommonCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildingUpgradeEffectCommonCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()

	local arrow = UIExtend.getCCSpriteFromCCB(ccbfile,"mArrow")
	arrow:setVisible(true)


	local buildingUpgradeAni = RABuildingUpgradeAni:new()
	buildingUpgradeAni:init("RABuildingUpgradePromptNew.ccbi")

	local mUgradeGlowNode = UIExtend.getCCNodeFromCCB(ccbfile,'mUgradeGlowNode')
	mUgradeGlowNode:addChild(buildingUpgradeAni.ccbfile)
	RABuildPromoteNewPage.buildingUpgradeAnis[#RABuildPromoteNewPage.buildingUpgradeAnis + 1] = buildingUpgradeAni

	local buildData = RABuildPromoteNewPage.buildData
	local buildInfo = RABuildPromoteNewPage.buildData.confData
	local buildNextInfo = RABuildingUtility.getBuildInfoById(buildInfo.id+1) or {}	
	local key, title, currValue, nextValue = self.key,self.title,self.currValue,self.nextValue

	UIExtend.setCCLabelString(ccbfile,"mUpgradeTitle2",title)
	if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
        if key == "buildingAttack" or key == "buildingDefence" 
    	   or key == "defenceTotalHP"  then  --升级效果里面不显示当前血条
        	currValue = RABuildInformationUtil:getDefenceAttrByKey(buildData, key)
    	end
	end	

	local currValueStr = Utilitys.formatNumber(currValue)

	if key == "effectID" and buildInfo.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦小屋 
		local sub = RAStringUtil:split(currValue, "_")
        if #sub == 2 then
            currValue = tonumber(sub[2])
        end			
		currValueStr = Utilitys.createTimeWithFormat(currValue)
	end

	if key == 'trainSpeed' or key == 'marketTax' then
		currValueStr = currValueStr ..'%'
	end

	UIExtend.setCCLabelString(ccbfile,"mGarrisonNum1",currValueStr)


	--下一级的信息
	local color = RAGameConfig.COLOR.GREEN
	if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
        if key == "buildingAttack" or key == "buildingDefence" 
           or key == "defenceTotalHP"  then  --升级效果里面不显示当前血条
        	nextValue = RABuildInformationUtil:getDefenceAttrByKey(buildNextInfo, key)
    	end
	end	
	if key == "effectID" and buildInfo.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦小屋 
		local sub = RAStringUtil:split(nextValue, "_")
        if #sub == 2 then
            nextValue = tonumber(sub[2])
        end
	end	
	if nextValue then
		local diffValue = nextValue - currValue

		if key == "electricConsume" then --电力颜色需要变化
			color = RAGameConfig.COLOR.RED
		end
		local nextValueStr = Utilitys.formatNumber(nextValue)

		if key == "effectID" and buildInfo.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦小屋 
			diffValue = tonumber(diffValue)
			--diffValue = math.floor(diffValue/3600)
			diffValue = Utilitys.createTimeWithFormat(diffValue)
			nextValue = tonumber(nextValue)
			--nextValueStr = math.floor(nextValue/3600)
			nextValueStr = Utilitys.createTimeWithFormat(nextValue)
		end

		if key == 'trainSpeed' or key == 'marketTax' then
			nextValueStr = nextValueStr ..'%'
			diffValue = diffValue ..'%'
		end
		UIExtend.setLabelTTFColor(ccbfile,"mGarrisonNum2",color)
		if  key == 'marketTax' then
			UIExtend.setCCLabelString(ccbfile,"mGarrisonNum2", "-"..diffValue.."")
		else
			local diffValueStr = Utilitys.formatNumber(diffValue)	
			UIExtend.setCCLabelString(ccbfile,"mGarrisonNum2","+"..diffValueStr.."")
		end
	else
		UIExtend.setCCLabelString(ccbfile,"mGarrisonNum2", _RALang("@LevelAlreadyMax"))
	end

end	

--雷达
local RABuildingUpgradeEffectRadarCell = {}
function RABuildingUpgradeEffectRadarCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildingUpgradeEffectRadarCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.setCCLabelString(ccbfile,"mUpgradeTitle2","")

	UIExtend.setCCLabelString(ccbfile,"mGarrisonNum2","")

	local arrow = UIExtend.getCCSpriteFromCCB(ccbfile,"mArrow")
	arrow:setVisible(false)

	--10级以上没有解锁效果
	if RABuildPromoteNewPage.data.level <= 10 then
		local str = string.format("%02d",RABuildPromoteNewPage.data.level+1)
		local keyStr = '@Build_2022'..str.."_Tips"
		if RABuildPromoteNewPage.data.level >= 10 then
			keyStr = '@Build_202210_Tips'
		end
		UIExtend.setCCLabelString(ccbfile,"mGarrisonNum1",_RALang(keyStr))
	else
		UIExtend.setCCLabelString(ccbfile,"mGarrisonNum1",_RALang("@MAXLevelNoEffect"))
	end

end


--大本node
local RABuildingUpgradeEffectBaseCampCell = {}
function RABuildingUpgradeEffectBaseCampCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self 
    return o
end


function RABuildingUpgradeEffectBaseCampCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	local arrow = UIExtend.getCCSpriteFromCCB(ccbfile,"mArrow")
	arrow:setVisible(true)	

	local buildingUpgradeAni = RABuildingUpgradeAni:new()
	buildingUpgradeAni:init("RABuildingUpgradePromptNew.ccbi")
	local mUgradeGlowNode = UIExtend.getCCNodeFromCCB(ccbfile,'mUgradeGlowNode')
	mUgradeGlowNode:addChild(buildingUpgradeAni.ccbfile)
	RABuildPromoteNewPage.buildingUpgradeAnis[#RABuildPromoteNewPage.buildingUpgradeAnis + 1] = buildingUpgradeAni

	UIExtend.setCCLabelString(ccbfile,"mUpgradeTitle2",_RALang("@UnlockArchitecture"))
	UIExtend.setCCLabelString(ccbfile,"mGarrisonNum1","")
	UIExtend.setCCLabelString(ccbfile,"mGarrisonNum2",self.name)
	UIExtend.setLabelTTFColor(ccbfile,"mGarrisonNum2",RAGameConfig.COLOR.GREEN)
end	


local OnReceiveMessage = function(message)
	--资源有变化的时候需要刷新 or 充值钻石有变化的时候
    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo or message.messageID == MessageDef_MainUI.MSG_PayInfoRefresh then        
        if RABuildPromoteNewPage.curPageType == TAB_TYPE.UPGRADECONDITION then
        	RABuildPromoteNewPage:setCurrentPage(TAB_TYPE.UPGRADECONDITION)
    	end
    end
end

function RABuildPromoteNewPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RABuildPromoteNewPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

--data 为 RABuildData 类型
function RABuildPromoteNewPage:Enter(data)
	UIExtend.loadCCBFile("RABuildingUpgradePageNew.ccbi",self)

	self.buildData = data       		--RABuildData
	self.data 	  = data.confData  		--配置数据
	self.uuid	  = data.id
    self.nextBuildInfo = RABuildingUtility.getBuildInfoById(self.data.id+1)
	self.resultList = {}
	self.resCostTab = {}
	--self.frontBuildCond = true
	self.resShort = false

	self:registerMessageHandlers()

	self.buildingUpgradeAnis = {}

	self:refreshUI()

    performWithDelay(self:getRootNode(), function ()
    local RAGuideManager = RARequire("RAGuideManager")
		RAGuideManager.gotoNextStep()
	end, 0.3)

end

function RABuildPromoteNewPage:onUpgradeConditionBtn()
    self:setCurrentPage(TAB_TYPE.UPGRADECONDITION)
end

function RABuildPromoteNewPage:onUpgradeEffectBtn()
    self:setCurrentPage(TAB_TYPE.UPGRADEEFFECT)
end



function RABuildPromoteNewPage:refreshUI()

	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang(self.data.buildName))
	UIExtend.setNodeVisible(titleCCB,"mMainHelpBtnNode",false)
	UIExtend.setControlButtonTitle(self.ccbfile,"mTrainBtn","@Update")
	-- UIExtend.setNodeVisible(titleCCB,"mMenuBtnNode",false)

	self.effectScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mNextEffectContent")
	self.limitScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mUpGradeTitle2")	
	
	self:addCell()
	--名称
	-- UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang(self.data.buildName))
	--当前等级
	UIExtend.setCCLabelString(self.ccbfile,"mGradeNum1",_RALang("@ResCollectTargetLevel", self.data.level))
	--下一等级
	UIExtend.setCCLabelString(self.ccbfile,"mGradeNum2",_RALang("@ResCollectTargetLevel",self.data.level+1))
	
	local buildingUpgradeAni = RABuildingUpgradeAni:new()
	buildingUpgradeAni:init("RABuildingUpgradePromptNew2.ccbi")
	local mLevelGlowNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mLevelGlowNode')
	mLevelGlowNode:addChild(buildingUpgradeAni.ccbfile)
	self.buildingUpgradeAnis[#self.buildingUpgradeAnis + 1] = buildingUpgradeAni

	--时间
	--UIExtend.setCCLabelString(self.ccbfile,"mNeedTime",Utilitys.createTimeWithFormat(self.nextBuildInfo.buildTime))

	--UIExtend.setSpriteImage(self.ccbfile, {mSuperMinePic = self.data.buildArtImg})
	-- UIExtend.getCCSpriteFromCCB(self.ccbfile,"mSuperMinePic"):setVisible(false)

	-- self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
 --    self.mExplainLabel:setString(_RALang(self.data.buildDes))
 --    self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
 --    UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

    --self:calTotalCostDiamond()

    -- if self.buildData.confData.buildType == Const_pb.CONSTRUCTION_FACTORY or self.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then 
    --     local RAWorldConfig =  RARequire('RAWorldConfig')
    --     local World_pb =  RARequire('World_pb')
    --     local flagCfg = RAWorldConfig.RelationFlagColor[World_pb.SELF]
    --     CCTextureCache:sharedTextureCache():addColorMaskKey(flagCfg.key, RAColorUnpack(flagCfg.color))
    --     self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas",flagCfg.key)
    --     -- self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas",'INSIDE_COLOR')
    -- else
    --     self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas")
    -- end 
    
    -- UIExtend.addNodeToAdaptParentNode

    local mSpineBuildNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mBuilderIcon")
    UIExtend.addNodeToAdaptParentNode(mSpineBuildNode, self.buildData.confData.buildLevelUpImg,10086)
    mSpineBuildNode:setScale(1.3)
    -- self.mSpineBuildNode:addChild(self.spineNode)

	-- local picNodeW = self.mSpineBuildNode:getContentSize().width
	-- local picNodeH = self.mSpineBuildNode:getContentSize().height
	-- local picW = self.spineNode:getContentSize().width
	-- local picH = self.spineNode:getContentSize().height
	-- dump({picNodeW,picNodeH,picW,picNodeW})
	-- local picNodeMin = math.min(picNodeW,picNodeH)
	-- local picMax = math.max(picW,picH)
	-- if picW>picNodeMin or picH>picNodeMin then
	-- 	self.spineNode:setScale(picNodeMin/picMax)
	-- end    
	-- self.spineNode:setPosition(ccp(250,0))
 --    -- self.spineNode:setScale(0.7)
 --    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE,-1)
end

function RABuildPromoteNewPage:calculateTime()

	-- （（建筑原始时间/（1+作用号400））- 爱因斯坦小屋（417）减少时间）*（1+电力影响）
	local researchTime = self.nextBuildInfo.buildTime
	local effectValue=nil
	if self.data.limitType ~= Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
		effectValue = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_BUILD)
	else
		effectValue = RALogicUtil:getEffectResult(Const_pb.CITYDEF_SPD_BUILD)
	end

	local effectValue1 = RALogicUtil:getEffectResult(Const_pb.CITY_BUILD_REDUCE_TIME)
	
	researchTime = researchTime /(1+effectValue/FACTOR_EFFECT_DIVIDE)-effectValue1

	return researchTime
end

function RABuildPromoteNewPage:calTotalCostDiamond()
	-- body

	local actualTime = math.ceil(self:calculateTime())
	
	local electric = RAPlayerInfoManager.getCurrElectricEffect()
	actualTime = math.ceil(actualTime*electric)
	if actualTime <= 0 then
		actualTime = 0
	end

	self.actualTime = actualTime
	UIExtend.setCCLabelString(self.ccbfile,"mNeedTime",Utilitys.createTimeWithFormat(actualTime))
	local timeCostDimand = RALogicUtil:time2Gold(actualTime)
	-- UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",_RALang("@Diamond").." "..actualCost)

	--需求条件判断 不包括资源不足的情况
	local isCanUpgrade = true
	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
	for i,v in ipairs(self.resultList) do
		if v.isOk==false then
			isCanUpgrade = false
			break
		end 
	end

	--添加新手对主基地立即建造按钮的影响
    local immBtnEnable = self:isImmUpgradeBtnEnabelWithGuide()

	UIExtend.setCCControlButtonEnable(self.ccbfile,"mUpgradeNowBtn", immBtnEnable)
	--UIExtend.setCCControlButtonEnable(self.ccbfile,"mUpgradeBtn",isCanUpgrade)

	--资源不足时判断玩家钻石是否满足
	self.totalCostDiamd = 0
	self.totalCostDiamd = self.totalCostDiamd + timeCostDimand
	--if isCanUpgrade then

	local resCostDiamond = 0
	for resId, costNum in pairs(self.resCostTab) do
		local gold = 0
		if resId == DIAMONDS_TYPE then  --钻石
    		gold = gold + costNum
    	else
    		local curNum = RAPlayerInfoManager.getResCountById(tonumber(resId))
	    	local diffNum = costNum - curNum
	    	gold = gold + RALogicUtil:res2Gold(diffNum,resId)
    	end
		
		resCostDiamond = resCostDiamond + gold
	end

	self.totalCostDiamd = self.totalCostDiamd + resCostDiamond

	--只要资源不满足就把研究按钮设置不可点击
	-- local num = #self.resCostTab
	-- if num>0 then
	-- 	--UIExtend.setCCControlButtonEnable(self.ccbfile,"mUpgradeBtn",false)
	-- end 
		
    --end
	
	UIExtend.setCCLabelString(self.ccbfile,"mNeedDiamondsNum",self.totalCostDiamd)
end

function RABuildPromoteNewPage:onUpgradeNowBtn()
	local RAGuideManager = RARequire('RAGuideManager')
	if RAGuideManager.isInGuide() then
		return
	end
	local isCanUpgrade = true
    for k,v in ipairs(self.resultList) do
		--立即升级需要前置建筑限制，不受资源限制
		if v.isFrontBuild == false then
			isCanUpgrade = false
			break
		end  
	end

	--local RARealPayManager = RARequire('RARealPayManager')
    
	if isCanUpgrade  then
		self:_doAfterCheckGuard(function ()
			local tipStr = ""
			local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
			--弹出二次确认框后，再次计算钻石数量
			self:calTotalCostDiamond()
			local isEnoughDiamod = playerDiamond>=self.totalCostDiamd and true or false
			if isEnoughDiamod then
				tipStr = _RALang("@UpgradNowTip")
			else
				tipStr = _RALang("@UpgradBuildNowDiamondShortTip")
			end 

			local RAConfirmManager = RARequire("RAConfirmManager")
			local isShow = RAConfirmManager:getShowConfirmDlog(RAConfirmManager.TYPE.UPGRADNOW)
			if isShow then
				local confirmData={}
				confirmData.type=RAConfirmManager.TYPE.UPGRADNOW
				confirmData.costDiamonds = self.totalCostDiamd
				confirmData.resultFun = function (isOk)
					if isOk then
						if isEnoughDiamod then
							RABuildManager:sendUpgradeBuildCmd(self.uuid,true)
							RARootManager.ClosePage("RABuildPromoteNewPage")
						else
							-- RARootManager.OpenPage("RAPackageMainPage")
							RARealPayManager:getRechargeInfo()
						end 
					end
				end
				RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)
			else
				if isEnoughDiamod then
					RABuildManager:sendUpgradeBuildCmd(self.uuid,true)
					RARootManager.ClosePage("RABuildPromoteNewPage")
				else
					-- RARootManager.OpenPage("RAPackageMainPage")
					RARealPayManager:getRechargeInfo()
				end 
			end
		end)
	else
		--TODO play animation	
		for i,v in ipairs(self.cellCCBTab) do
			if not v.isAnimation and v.ccbfile then
				v.ccbfile:runAnimation("ShakeAni")
			end
		end	
	end
end

function RABuildPromoteNewPage:onTrainBtn()
	local isCanUpgrade = true

    for k,v in ipairs(self.resultList) do
		if v.isOk == false then
			isCanUpgrade = false
			break
		end 
	end

	if isCanUpgrade then

		self:_doAfterCheckGuard(function ()
			if self.actualTime ~= 0 then 
				RABuildManager:sendUpgradeBuildCmd(self.uuid, false)
			else
				RABuildManager:sendUpgradeBuildCmd(self.uuid, true)
			end 
			self:onClose()
		end)
	else
		--TODO play animation	
		for i,v in ipairs(self.cellCCBTab) do
			if not v.isAnimation and v.ccbfile then
				v.ccbfile:runAnimation("ShakeAni")
			end
		end
	end
    --如果是新手期点击升级，需要添加coverpage，防止点击
    local RAGuideManager = RARequire("RAGuideManager")
    local RAGuideConfig = RARequire("RAGuideConfig")
    if RAGuideManager.isInGuide() or RAGuideManager.getCurrentGuideId() == RAGuideConfig.partNameWithEndId.Guide_First then
        RARootManager.AddCoverPage()
        RARootManager.RemoveGuidePage()
    end
end

function RABuildPromoteNewPage:_doAfterCheckGuard(confirmFunc)

    if confirmFunc == nil then return end
    -- 增加电力消耗判断
    local nextLevelConsume = self.nextBuildInfo.electricConsume or 0
    local currLevelConsume = self.data.electricConsume or 0
    local electricAdd =  nextLevelConsume - currLevelConsume
    local upgradeFunc = function()
    	local world_map_const_conf = RARequire('world_map_const_conf')
	    if self.data.buildType == Const_pb.CONSTRUCTION_FACTORY
	    	and self.nextBuildInfo.level == world_map_const_conf.stepCityLevel1.value
	    	and RAPlayerInfoManager.isNewerInProtect()  -- 仍然在保护盾
	    then
	        local confirmData =
	        {
	            labelText = _RALang('@ConfrimPromotingWithLosingGuard',world_map_const_conf.stepCityLevel1.value),
	            yesNoBtn = true,
	            resultFun = function (isOK)
	                if isOK then confirmFunc() end
	            end
	        }
	        RARootManager.showConfirmMsg(confirmData)
	    else
	        confirmFunc()
	    end	
    end
    RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, upgradeFunc)
end

------------------------------------RABuildingUpgradeCell-----------------------------------------------------
local RABuildingUpgradeCell = {}
function RABuildingUpgradeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildingUpgradeCell:updateTime()
	-- body
	local endTime = self.queueInfo.endTime2
    local remainMilliSecond = Utilitys.getCurDiffMilliSecond(endTime)
    local remainTime = math.ceil(remainMilliSecond)
    if remainTime <= 0 then return end
    local formatTimeStr = Utilitys.createTimeWithFormat(remainTime)

    local tmpCellName
	if self.queueStatus == Const_pb.QUEUE_STATUS_REPAIR then -- 防御建筑维修中
		tmpCellName = _RALang("@IsRePairdeing",self.queueCellName,formatTimeStr)
	elseif self.queueStatus == Const_pb.QUEUE_STATUS_REBUILD then -- 建筑改建中
		tmpCellName = _RALang("@IsReBuilding",self.queueCellName,formatTimeStr)
	else
		tmpCellName = _RALang("@IsUpgradeing",self.queueCellName,formatTimeStr)	
    end

	UIExtend.setCCLabelString(self.ccbfile,"mLevelUpNum",formatTimeStr)
end

function RABuildingUpgradeCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
	self.ccbfile = ccbfile

	UIExtend.setCCLabelString(ccbfile,"mLevelUpNum","")
	-- UIExtend.setCCLabelString(ccbfile,"mQueueFull","")

	local picName = ""
	local tmpCellName = ""
	local tmpCellValue =""
	local isOk = false
	local isRes = false
	local isFrontBuild = true
    --前置建筑
    --道具/资源消耗  10000_1006_100 
    if self.queueInfo  then  --建造队列已满
		local buildingData = RABuildManager:getBuildDataById(self.queueInfo.itemId)

		self.queueCellName = _RALang(buildingData.confData.buildName)

		self.queueStatus = self.queueInfo.status

		local queueFullStr =  _RALang()

		local scheduleFunc = function ()
            self:updateTime(self)
        end

        isFrontBuild = false

        self.frontBuild = buildingData.confData.id
        self.isFrontBuildExist = false
        self.isFrontScienceExist = false
        schedule(self.ccbfile,scheduleFunc,0.05)

        picName = buildingData.confData.buildArtImg
        tmpCellName = _RALang("@UpdateSpecial", buildingData.confData.level,_RALang(buildingData.confData.buildName))
        local endTime = self.queueInfo.endTime
		-- local endTime = os.time()+3600
		self.queueEndTime = endTime
		isOk = false
		-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",true)

    elseif self.frontBuild  then
		local buildInfo = RABuildingUtility.getBuildInfoById(self.frontBuild)
		tmpCellName = _RALang(buildInfo.buildName)
		local level = buildInfo.level
		local isBuildExist = RABuildManager:isBuildingExist(self.frontBuild,buildInfo.buildType)
		self.isFrontBuildExist = isBuildExist
		local nowLevel = RABuildManager:getBuildMaxLevel(buildInfo.buildType)
		tmpCellValue = _RALang("@LevelToLevel",nowLevel,level)
		if isBuildExist  then
			isOk = true
			--RABuildPromoteNewPage.frontBuildCond=true
		else
			isFrontBuild = isBuildExist
			--RABuildPromoteNewPage.frontBuildCond=false
		end 
		-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)
	elseif self.frontRechargeDiamond then
		local frontRechargeDiamond = self.frontRechargeDiamond
		local RAResManager = RARequire("RAResManager")
		picName, name = RAResManager:getIconByTypeAndId(10000,DIAMONDS_TYPE) --使用钻石的icon
		local rechargeDiamond = RARealPayManager.addGold

		tmpCellValue = _RALang("@TotalRechargeGold",Utilitys.formatNumber(rechargeDiamond), Utilitys.formatNumber(frontRechargeDiamond))


		local diamondCost = tonumber(frontRechargeDiamond)
		isOk = rechargeDiamond>=diamondCost and true or false

		self.isFrontRechargeDiamond = isOk
		isFrontBuild = isOk

		-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)	
	elseif self.frontScienceId then
		local frontScienceConf = RAScienceUtility:getScienceDataById(self.frontScienceId)
		picName = frontScienceConf.techPic
		name = frontScienceConf.techName
		tmpCellName = _RALang("@FrontScienceName",_RALang(frontScienceConf.techName))
		local level = frontScienceConf.techLevel
		local isScienceExist = RAScienceManager:isResearchFinish(self.frontScienceId)
		self.isFrontScienceExist = isScienceExist

		local nowLevel = RAScienceManager:getMaxLevel(self.frontScienceId)
		tmpCellValue = _RALang("@LevelToLevel",nowLevel,level)
		if isScienceExist then
			isOk = true
		else
			isFrontBuild = isScienceExist
		end	
		-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)
	else
		isRes = true
		local costInfo = RAStringUtil:split(self.costInfo,"_")
	    local costType = costInfo[1] 
	    local costId = costInfo[2] 
	    local costNum = costInfo[3] 

		if RALogicUtil:isItemById(costId) then 
		 --道具
		  local itemInfo = RACoreDataManager:getItemInfoByItemId(costId)
		  local tmpSumValue = RACoreDataManager:getItemCountByItemId(costId)
		  tmpCellName = itemInfo.conf.item_name
		  picName = itemInfo.conf.item_icon
		
		  tmpCellValue = _RALang("@UpgradFenGe",Utilitys.formatNumber(tmpSumValue), Utilitys.formatNumber(costNum))
		  if tmpSumValue >=tonumber(costNum) then
		  	isOk = true
		  end 
		  -- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",false)
		elseif RALogicUtil:isResourceById(costId) then
			--资源 
			picName = RALogicUtil:getResourceIconById(costId)
			tmpCellName = RALogicUtil:getResourceNameById(costId)
			local curNum = RAPlayerInfoManager.getResCountById(tonumber(costId))
			-- curNum = curNum or 100

			tmpCellValue = _RALang("@UpgradFenGe",Utilitys.formatNumber(curNum), Utilitys.formatNumber(costNum))
			local resCost = tonumber(costNum)
			isOk = curNum>=resCost and true or false

			if not isOk then
				--local costNum = resCost - curNum
				RABuildPromoteNewPage.resCostTab[costId] = costNum
				RABuildPromoteNewPage.resShort = false
			end 
			-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)

		elseif costId == DIAMONDS_TYPE then  --钻石
			local RAResManager = RARequire("RAResManager")
			picName, tmpCellName = RAResManager:getIconByTypeAndId(costType,costId)
			local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)

			tmpCellValue = _RALang("@UpgradFenGe",Utilitys.formatNumber(playerDiamond), Utilitys.formatNumber(costNum))

			
			local diamondCost = tonumber(costNum)
			isOk = playerDiamond>=diamondCost and true or false

			if not isOk then
				RABuildPromoteNewPage.resShort = false
			end 

			--local costNum = playerDiamond - diamondCost-playerDiamond
			RABuildPromoteNewPage.resCostTab[costId] = costNum
			-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)
		end 
	end 
	
	self.isAnimation = isOk

	-- local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mItemPicNode")
	-- --picNode:removeAllChildren()
	-- UIExtend.addNodeToAdaptParentNode(picNode,picName,TAG)
	UIExtend.setCCLabelString(ccbfile,"mLevelUpTower",tmpCellName)
	UIExtend.setCCLabelString(ccbfile,"mLevelUpNum",tmpCellValue)
	UIExtend.setNodeVisible(ccbfile,"mUnDone",not isOk)
	UIExtend.setNodeVisible(ccbfile,"mCompleted",isOk)
	-- local btn = UIExtend.getCCControlButtonFromCCB(ccbfile,"mButton1")
	-- btn:setVisible(not isOk)
	UIExtend.setControlButtonTitle(ccbfile,"mButton1",_RALang("@Go"))
	-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)

	if not RABuildPromoteNewPage.resShort then
		local t = {}
		t.isOk = isOk
		t.isRes = isRes
		t.isFrontBuild = isFrontBuild
		RABuildPromoteNewPage.resultList[#RABuildPromoteNewPage.resultList + 1] = t
	end
	local color = isOk and ccc3(158,167,174) or ccc3(255,212,100)
	UIExtend.setLabelTTFColor(ccbfile,"mLevelUpNum",color)
	UIExtend.setLabelTTFColor(ccbfile,"mLevelUpTower",color)
	-- UIExtend.setLabelTTFColor(ccbfile,"mQueueFull",color)
end

function RABuildingUpgradeCell:onUnLoad( ... )
	self.ccbfile = nil
end

function RABuildingUpgradeCell:onJumpBtn( )
	if self.frontBuild and not self.isFrontBuildExist then
		--得到前置建筑的类型
		local frontBuildInfo = RABuildingUtility.getBuildInfoById(self.frontBuild)
		local buildType = frontBuildInfo.buildType

		--得到建筑队列中信息
		local toBuildInfo = RABuildManager:getBuildDataByType(buildType)
		if toBuildInfo  and next(toBuildInfo) then
			--按等级从高到低排序下 取等级最高的那个

			local maxLevelBuilding = nil 
			for k,v in pairs(toBuildInfo) do
				if maxLevelBuilding == nil then 
					maxLevelBuilding = v
				else
					if maxLevelBuilding.confData.level < v.confData.level then 
						maxLevelBuilding = v
					end 
				end  
			end

			local RAQueueManager = RARequire('RAQueueManager')
			local isUpgrade,upgradeBuilding =  RAQueueManager:isBuildingTypeUpgrade(buildType)
			if isUpgrade then 
				maxLevelBuilding = upgradeBuilding
			end 

			local tilePos = CCPoint(maxLevelBuilding.tilePos.x,maxLevelBuilding.tilePos.y)

			--摄像机移动到目标建筑并且选中该建筑
			RABuildManager:setBuildingSelect(maxLevelBuilding.id)
			RACitySceneManager:cameraGotoTilePos(tilePos)
			RABuildPromoteNewPage:onClose()
		else
			RABuildPromoteNewPage:onClose()
			local RAGuideManager = RARequire("RAGuideManager")
			RAGuideManager:guideToConsturctionBtn()	
		end 
	elseif self.frontScienceId and not self.isFrontScienceExist then --跳转到科技
		local toBuild = RABuildManager:getBuildDataByType(Const_pb.FIGHTING_LABORATORY)
		--如果没有作战实验室给出提示
		if toBuild  and next(toBuild) then
			local data = {}
			data.scienceId = self.frontScienceId
			data.scienceFunc = function ()
				RABuildPromoteNewPage:scienceComplete()
			end
			RARootManager.OpenPage("RAScienceTreePage",data,true,true)	
		
		else
			RABuildPromoteNewPage:onClose()
			local RAGuideManager = RARequire("RAGuideManager")
			RAGuideManager:guideToConsturctionBtn()	
		end	
		
	elseif self.costInfo then
		local costInfo = RAStringUtil:split(self.costInfo,"_")
	    local costType = costInfo[1] 
	    local costId = costInfo[2] 
	    local costNum = costInfo[3] 
	    if costId == DIAMONDS_TYPE then --所需钻石
	    	local needCostNum = tonumber(RABuildPromoteNewPage.resCostTab[costId])

	    	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)

	    	if playerDiamond < needCostNum then  --钻石不足，打开支付页面
	    		RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
	    	end
	    elseif RABuildPromoteNewPage.resCostTab[costId] then
	    	--RABuildPromoteNewPage:onClose()
		    local data={}
		    data.resourceType = RALogicUtil:resTypeToShopType(tonumber(costId))
		    RARootManager.OpenPage("RAReposityPage",data,false, true)	    		
	    end
	elseif self.frontRechargeDiamond and not self.isFrontRechargeDiamond then
		local needCostNum = tonumber(self.frontRechargeDiamond)

    	local rechargeDiamond = RARealPayManager.addGold

    	if rechargeDiamond < needCostNum then  --钻石不足，打开支付页面
    		RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
    	end     
	end 
end

----------------------------------------end cell-----------------------------------------------------

--科技升级完成刷新回调
function RABuildPromoteNewPage:scienceComplete()
	-- body
	if self.curPageType == TAB_TYPE.UPGRADECONDITION then
		self:setCurrentPage(TAB_TYPE.UPGRADECONDITION)
	end
end


--------升级条件cell
function RABuildPromoteNewPage:upgradeConditionCell(scrollView)
	local queueTabInfo = nil
    if self.data.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_DEFENER)
    else
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_QUEUE)
    end

    self.cellCCBTab = {}
    for k,v in pairs(queueTabInfo) do
	   local cell = CCBFileCell:create()
	   cell:setCCBFile("RABuildingUpgradeCell1New.ccbi")
	   local panel = RABuildingUpgradeCell:new({
	       queueInfo = v
	   })
	   cell:registerFunctionHandler(panel)
	   self.cellCCBTab[#self.cellCCBTab + 1] = panel
	   scrollView:addCell(cell)
    end

    --前置建筑 至多一个
  	if self.nextBuildInfo.frontBuild then
  	   local frontBuilds = RAStringUtil:split(self.nextBuildInfo.frontBuild,",")
	   for k,frontbuildId in ipairs(frontBuilds) do
	   		if frontbuildId and tonumber(frontbuildId) then
		   		local cell = CCBFileCell:create()
		   		cell:setCCBFile("RABuildingUpgradeCell1New.ccbi")
				local panel = RABuildingUpgradeCell:new({
					frontBuild = tonumber(frontbuildId)
		        })
				cell:registerFunctionHandler(panel)
				self.cellCCBTab[#self.cellCCBTab + 1] = panel
				scrollView:addCell(cell)
			end
	   end   
  	end 

  	--特殊的 累计充值钻石 前置
  	if self.nextBuildInfo.frontRechargeDiamond then
	   	local cell = CCBFileCell:create()
   		cell:setCCBFile("RABuildingUpgradeCell1New.ccbi")
		local panel = RABuildingUpgradeCell:new({
			frontRechargeDiamond = tonumber(self.nextBuildInfo.frontRechargeDiamond)
        })
		cell:registerFunctionHandler(panel)
		self.cellCCBTab[#self.cellCCBTab + 1] = panel
		scrollView:addCell(cell)
  	end

  	--科技前置 至多一个
  	if self.nextBuildInfo.frontScience then
  	   local frontSciences = RAStringUtil:split(self.nextBuildInfo.frontScience, ",")
	   for k,frontScienceId in ipairs(frontSciences) do
	   		if frontScienceId and tonumber(frontScienceId) then
		   		local cell = CCBFileCell:create()
		   		cell:setCCBFile("RABuildingUpgradeCell1New.ccbi")
				local panel = RABuildingUpgradeCell:new({
					frontScienceId = tonumber(frontScienceId)
		        })
				cell:registerFunctionHandler(panel)
				self.cellCCBTab[#self.cellCCBTab + 1] = panel
				scrollView:addCell(cell)
			end
	   end
  	end 

	--消耗资源或者道具
    if self.nextBuildInfo.buildCost then
   		local costTab = RAStringUtil:split(self.nextBuildInfo.buildCost,",") 
	   	for k,info in pairs(costTab) do
	   		local cell = CCBFileCell:create()
	   		cell:setCCBFile("RABuildingUpgradeCell1New.ccbi")
			local panel = RABuildingUpgradeCell:new({
					costInfo = info,
	        })
			cell:registerFunctionHandler(panel)
			self.cellCCBTab[#self.cellCCBTab + 1] = panel
			scrollView:addCell(cell)
	    end
    end
end



--获得大本未解锁的数据	
function RABuildPromoteNewPage:initLockBuildsData()
	local curlevel =self.data.level
	local nextLevel = curlevel + 1
	local limitIdTab = {}
    local curLimitId = self.data.limitType
	for k,info in pairs(build_limit_conf) do
		if curLimitId ~= info.id then
			--资源型建筑特殊处理
			if info.id == 200 then
				local limitResBuildInfo = RABuildingUtility.getResBuildInfoByLimitType(info.id)
				for i,resBuildInfo in ipairs(limitResBuildInfo) do
					local frontbuildId = resBuildInfo.frontBuild
					local frontBuildInfo = RABuildingUtility.getBuildInfoById(tonumber(frontbuildId))
					if frontBuildInfo.level == nextLevel then
						local tb={}
						tb.id = resBuildInfo.id
						tb.curNum = 0
						tb.isRes = true
						limitIdTab[#limitIdTab + 1] = tb
					end
				end
			else
				local key1 = "cyLv"..curlevel
				local key2= "cyLv"..nextLevel
	            local value1  =info[key1]
	            local value2  =info[key2]
	            if value2 then
	            	local add = value2 - value1
					if add>0 then
						local tb={}
						tb.id = info.id
						tb.curNum = value1
						tb.add = add
						limitIdTab[#limitIdTab + 1] = tb
					end 
	            end 
			end 
		end 
	end
	return limitIdTab
end

function RABuildPromoteNewPage:upgradeEffectCell(scrollView)

	local buildInfo = self.buildData.confData

	local buildNextInfo = RABuildingUtility.getBuildInfoById(buildInfo.id+1) or {}	

	if self.data.buildType == Const_pb.CONSTRUCTION_FACTORY then   --建筑工厂
		self.limitIdTab = RABuildPromoteNewPage:initLockBuildsData()
		local cell,panel,limitBuildInfo
		for i,info in ipairs(self.limitIdTab) do
			if not info.isRes then
				limitBuildInfo = RABuildingUtility.getBuildInfoByLimitType(info.id)
			else
				limitBuildInfo = RABuildingUtility.getBuildInfoById(info.id)
			end		
			cell = CCBFileCell:create()
			panel = RABuildingUpgradeEffectBaseCampCell:new({
				isFactory = true,
				name = _RALang(limitBuildInfo.buildName)
	        })
			cell:registerFunctionHandler(panel)		
			panel.mSelfCell = cell
			cell:setCCBFile("RABuildingUpgradeCell2New.ccbi")
			scrollView:addCell(cell)
		end

		cell = CCBFileCell:create()
   		cell:setCCBFile("RABuildingUpgradeCell2New.ccbi")
		panel = RABuildingUpgradeEffectCommonCell:new({
				key = "electricConsume",
				title = _RALang("@ElectricConsume"),
				currValue = buildInfo.electricConsume,
				nextValue = buildNextInfo.electricConsume
        })
		cell:registerFunctionHandler(panel)
		scrollView:addCell(cell)

	elseif self.data.buildType == Const_pb.RADAR then 			   --雷达

		local cell = CCBFileCell:create()
   		cell:setCCBFile("RABuildingUpgradeCell2New.ccbi")
		local panel = RABuildingUpgradeEffectRadarCell:new({
			index = 1
        })
		cell:registerFunctionHandler(panel)
		scrollView:addCell(cell)

		cell = CCBFileCell:create()
   		cell:setCCBFile("RABuildingUpgradeCell2New.ccbi")
		panel = RABuildingUpgradeEffectCommonCell:new({
				key = "electricConsume",
				title = _RALang("@ElectricConsume"),
				currValue = buildInfo.electricConsume,
				nextValue = buildNextInfo.electricConsume
        })
		cell:registerFunctionHandler(panel)
		scrollView:addCell(cell)
	else 														   --通用
		local col,keyTab,titleTab = RABuildInformationUtil:initBuildInfoAttr(self.buildData)  
		local cell,panel
		-- dump(titleTab)
		for i = 1, col do
			if keyTab[i] ~= "defenceCurrHP" and keyTab[i] ~= "totalTrainSpeed" 
			and keyTab[i] ~= "TotaleWoundedLimit" and keyTab[i] ~= "totalResUpperLimit"
			and keyTab[i] ~= "totalResOutPut" then --不显示当前血量
				cell = CCBFileCell:create()
		   		cell:setCCBFile("RABuildingUpgradeCell2New.ccbi")
				panel = RABuildingUpgradeEffectCommonCell:new({
						key = keyTab[i],
						title = titleTab[i],
						currValue = buildInfo[keyTab[i]],
						nextValue = buildNextInfo[keyTab[i]]
		        })
				cell:registerFunctionHandler(panel)
				scrollView:addCell(cell)
			end
		end

	end 
end

function RABuildPromoteNewPage:addCell()
    self.effectScrollView:removeAllCell()

    local scrollView = self.effectScrollView

    self:upgradeEffectCell(scrollView)
  	--
	scrollView:orderCCBFileCells(scrollView:getContentSize().width)

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		scrollView:setTouchEnabled(true)
	end 

    self.limitScrollView:removeAllCell()

    local scrollView = self.limitScrollView

    self:upgradeConditionCell(scrollView)
    
	scrollView:orderCCBFileCells()

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		scrollView:setTouchEnabled(true)
	end 	

	self:calTotalCostDiamond()
end

function RABuildPromoteNewPage:onClose()
	RARootManager.CloseCurrPage()
end

function RABuildPromoteNewPage:clearDatas()
	for i,v in ipairs(self.resultList) do
		v=nil
	end
	self.resultList = nil

	for i,v in ipairs(self.resCostTab) do
		v=nil
	end
	self.resCostTab = nil
end

function RABuildPromoteNewPage:Exit()

	
	for i,v in ipairs(self.buildingUpgradeAnis) do
		v:release()
	end
	self.buildingUpgradeAnis = nil
	
	self:unregisterMessageHandlers()

	-- self.spineNode:removeFromParentAndCleanup(true)
	self:clearDatas()
	self.limitScrollView:removeAllCell()
	self.effectScrollView:removeAllCell()


    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    -- self.ccbfile = nil

    -- if RAGuideManager.isInGuide() then
    -- 	RARootManager.RemoveCoverPage()
    -- end 
end

function RABuildPromoteNewPage:getGuideNodeInfo()
    local upgradeNowBtn = self.ccbfile:getCCNodeFromCCB("mTrainBtn")
    local worldPos =  upgradeNowBtn:getParent():convertToWorldSpaceAR(ccp(upgradeNowBtn:getPositionX(),upgradeNowBtn:getPositionY()))
    local size = upgradeNowBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = CCSizeMake(size.width + 20, size.height + 20) 
    }
    return guideData
end

function RABuildPromoteNewPage:mCommonTitleCCB_onBack()
	self:onClose()
end

--desc:新手会影响建主基地造页面的立即升级按钮的展现，在这里统一做判断
function RABuildPromoteNewPage:isImmUpgradeBtnEnabelWithGuide()
    if self.data.buildType == Const_pb.CONSTRUCTION_FACTORY then
        local RABuildManager = RARequire("RABuildManager")
        local RAGuideManager = RARequire("RAGuideManager")
        local const_conf = RARequire("const_conf")
        local RAGameConfig = RARequire("RAGameConfig")
        local mainCityLv = RABuildManager:getMainCityLvl()
        local allowCityLv = const_conf.GuideUpgradeImmMainCityLevel.value
        if RAGameConfig.SwitchGuide == 1 and mainCityLv<allowCityLv and (not RAGuideManager.isInGuide()) then
            return false
        end
        return true
    else
        return true
    end
end

return RABuildPromoteNewPage