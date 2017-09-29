--建筑修理弹出页面(目前只有防御建筑能修理)
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb = RARequire("Const_pb")
local RAArsenalManager = RARequire("RAArsenalManager")
local RAQueueManager = RARequire("RAQueueManager")
local RABuildManager = RARequire("RABuildManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGameConfig = RARequire("RAGameConfig")
local RACitySceneManager = RARequire("RACitySceneManager")
local RABuildInformationUtil = RARequire("RABuildInformationUtil")

local RABuildingRepairPage = BaseFunctionPage:new(...)

local TAG = 1000

local OnReceiveMessage = function(message)
	--资源有变化的时候需要刷新 or 充值钻石有变化的时候
    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo or message.messageID == MessageDef_MainUI.MSG_PayInfoRefresh then        
        RABuildingRepairPage:addCell()
    end
end

function RABuildingRepairPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RABuildingRepairPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RABuildingRepairPage:Enter(data)
	-- body
	UIExtend.loadCCBFile("RABuildingRepairPage.ccbi",self)

	self:registerMessageHandlers()

	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

	self.dataConfData 	  = data.confData  		--配置数据
	self.uuid	  	      = data.id

	self.defenceBuildConf = RABuildingUtility:getDefenceBuildConfById(self.dataConfData.id)

	self.resultList = {}
	self.resCostTab = {}
	self.frontBuildCond = true
	self.resShort = false

	self:refreshUI()

end

--修复时间 = （1 - 当前生命值/当前等级生命上限） * 配置时间
function RABuildingRepairPage:getRepairTime()
	-- body
	local buildData = RABuildManager:getBuildDataById(self.uuid)
	local defenceBuildConf = RABuildingUtility:getDefenceBuildConfById(self.dataConfData.id)
	local repairTime = (1 - buildData.HP / buildData.totalHP) * defenceBuildConf.recoverTime

	return repairTime
end

--修复资源 = (1 - 当前生命值 / 当前等级生命上限) * 配置资源
function RABuildingRepairPage:getRepairRes(resCount)
	-- body
	local buildData = RABuildManager:getBuildDataById(self.uuid)
	local repairRes = (1 - buildData.HP / buildData.totalHP) * resCount

	return repairRes
end

function RABuildingRepairPage:refreshUI()
	-- body
	--名称
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang(self.dataConfData.buildName))
	--当前等级
	UIExtend.setCCLabelString(self.ccbfile,"mCurrentLevel",self.dataConfData.level)

	--时间
	--UIExtend.setCCLabelString(self.ccbfile,"mNeedTime",Utilitys.createTimeWithFormat(self:getRepairTime()))

	--UIExtend.setSpriteImage(self.ccbfile, {mSuperMinePic = self.dataConfData.buildArtImg})
	UIExtend.getCCSpriteFromCCB(self.ccbfile,"mSuperMinePic"):setVisible(false)

	self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
    self.mExplainLabel:setString(_RALang(self.dataConfData.buildDes))
    self.mExplainLabelStarP = ccp(self.mExplainLabel:getPosition())
    UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

    self:addCell()

    self:calTotalCostDiamond()

    if self.dataConfData.buildType == Const_pb.CONSTRUCTION_FACTORY or self.dataConfData.limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then 
        local RAWorldConfig =  RARequire('RAWorldConfig')
        local World_pb =  RARequire('World_pb')
        local flagCfg = RAWorldConfig.RelationFlagColor[World_pb.SELF]
        CCTextureCache:sharedTextureCache():addColorMaskKey(flagCfg.key, RAColorUnpack(flagCfg.color))
        self.spineNode = SpineContainer:create(self.dataConfData.buildArtJson .. ".json",self.dataConfData.buildArtJson ..".atlas",flagCfg.key)
        -- self.spineNode = SpineContainer:create(self.dataConfData.buildArtJson .. ".json",self.dataConfData.buildArtJson ..".atlas",'INSIDE_COLOR')
    else
        self.spineNode = SpineContainer:create(self.dataConfData.buildArtJson .. ".json",self.dataConfData.buildArtJson ..".atlas")
    end 

    self.mSpineBuildNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mSpineBuildNode")
    self.mSpineBuildNode:addChild(self.spineNode)
    self.spineNode:setScale(0.7)
    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE,-1)
end

function RABuildingRepairPage:calculateTime()

	-- （（建筑原始时间/（1+作用号400））- 爱因斯坦小屋（417）减少时间）*（1+电力影响）
	local researchTime = self:getRepairTime()
	local effectValue=nil
	if self.dataConfData.limitType ~= Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
	effectValue = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_BUILD)
	else
		effectValue = RALogicUtil:getEffectResult(Const_pb.CITYDEF_SPD_BUILD)
	end

	local effectValue1 = RALogicUtil:getEffectResult(Const_pb.CITY_BUILD_REDUCE_TIME)
	
	researchTime = researchTime /(1+effectValue/FACTOR_EFFECT_DIVIDE)-effectValue1

	return researchTime
end

function RABuildingRepairPage:calTotalCostDiamond()
	-- body

	local actualTime = self:calculateTime()
	
	local electric = RAPlayerInfoManager.getCurrElectricEffect()
	actualTime = math.ceil(actualTime*electric)
	if actualTime <= 0 then
		actualTime = 0
	end
	UIExtend.setCCLabelString(self.ccbfile,"mNeedTime",Utilitys.createTimeWithFormat(actualTime))
	local timeCostDimand = RALogicUtil:time2Gold(actualTime)
	-- UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",_RALang("@Diamond").." "..actualCost)

	--需求条件判断 不包括资源不足的情况
	-- local isCanUpgrade = true
	-- local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
	-- for i,v in ipairs(self.resultList) do
	-- 	if v.isOk==false then
	-- 		isCanUpgrade = false
	-- 		break
	-- 	end 
	-- end

	--UIExtend.setCCControlButtonEnable(self.ccbfile,"mRepairNowBtn",isCanUpgrade)
	--UIExtend.setCCControlButtonEnable(self.ccbfile,"mRepairBtn",isCanUpgrade)

	--资源不足时判断玩家钻石是否满足
	self.totalCostDiamd = 0
	self.totalCostDiamd = self.totalCostDiamd+timeCostDimand
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

function RABuildingRepairPage:addCell()
    self.scrollView:removeAllCell()

    local scrollView = self.scrollView

    self:repairConditionCell(scrollView)
  	--
	scrollView:orderCCBFileCells()

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		scrollView:setTouchEnabled(true)
	end 
end

---------------------------RABuildingRepairCell---------------------------

local RABuildingRepairCell = {}
function RABuildingRepairCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildingRepairCell:updateTime()
	-- body
	local endTime = self.queueInfo.endTime2
    local remainMilliSecond = Utilitys.getCurDiffMilliSecond(endTime)
    local remainTime = math.ceil(remainMilliSecond)
    local formatTimeStr = Utilitys.createTimeWithFormat(remainTime)
    local tmpCellName = _RALang("@IsUpgradeing",self.queueCellName,formatTimeStr)
	UIExtend.setCCLabelString(self.ccbfile,"mQueueFull",tmpCellName)
end

function RABuildingRepairCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
	self.ccbfile = ccbfile

	UIExtend.setCCLabelString(ccbfile,"mRequirementLabel","")
	UIExtend.setCCLabelString(ccbfile,"mQueueFull","")

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

		local queueFullStr =  _RALang()

		local scheduleFunc = function ()
            self:updateTime(self)
        end

        isFrontBuild = false

        self.frontBuild = buildingData.confData.id
        self.isFrontBuildExist = false
        schedule(self.ccbfile,scheduleFunc,0.05)

        picName = buildingData.confData.buildArtImg
        local endTime = self.queueInfo.endTime
		-- local endTime = os.time()+3600
		self.queueEndTime = endTime
		isOk = false
		UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",true)
	else
		isRes = true
		local costInfo = RAStringUtil:split(self.costInfo,"_")
	    local costType = costInfo[1] 
	    local costId = costInfo[2] 
	    local costNum = costInfo[3] 
	    costNum = math.ceil(RABuildingRepairPage:getRepairRes(costNum)) 

		if RALogicUtil:isItemById(costId) then 
			--道具
		    local itemInfo = RACoreDataManager:getItemInfoByItemId(costId)
		    local tmpSumValue = RACoreDataManager:getItemCountByItemId(costId)
		    tmpCellName = itemInfo.conf.item_name
		    picName = itemInfo.conf.item_icon
		
		    tmpCellValue = _RALang("@UpgradFenGe" ,Utilitys.formatNumber(tmpSumValue) ,Utilitys.formatNumber(costNum))
		    if tmpSumValue >=tonumber(costNum) then
		  		isOk = true
		  	end 
		  	UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",false)
		elseif RALogicUtil:isResourceById(costId) then
			--资源 
			picName = RALogicUtil:getResourceIconById(costId)
			local curNum = RAPlayerInfoManager.getResCountById(tonumber(costId))
			-- curNum = curNum or 100

			tmpCellValue = _RALang("@UpgradFenGe" ,Utilitys.formatNumber(curNum) ,Utilitys.formatNumber(costNum))
			local resCost = tonumber(costNum)
			isOk = curNum>=resCost and true or false

			if not isOk then
				--local costNum = resCost-curNum
				RABuildingRepairPage.resCostTab[costId] = costNum
				RABuildingRepairPage.resShort = false
			end 
			UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)

		elseif costId == DIAMONDS_TYPE then  --钻石
			local RAResManager = RARequire("RAResManager")
			picName, name = RAResManager:getIconByTypeAndId(costType,costId)
			local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
			tmpCellValue = _RALang("@UpgradFenGe" ,Utilitys.formatNumber(playerDiamond) ,Utilitys.formatNumber(costNum))

			local diamondCost = tonumber(costNum)
			isOk = playerDiamond>=diamondCost and true or false

			if not isOk then
				RABuildingRepairPage.resShort = false
			end 

			--local costNum = playerDiamond - diamondCost-playerDiamond
			RABuildingRepairPage.resCostTab[costId] = costNum
			UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)
		end 
	end 
	
	self.isAnimation = isOk

	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mItemPicNode")
	--picNode:removeAllChildren()
	UIExtend.addNodeToAdaptParentNode(picNode,picName,TAG)
	
	UIExtend.setCCLabelString(ccbfile,"mRequirementLabel",tmpCellValue)
	UIExtend.setNodeVisible(ccbfile,"mReachPic",isOk)
	-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)

	if not RABuildingRepairPage.resShort then
		local t = {}
		t.isOk = isOk
		t.isRes = isRes
		t.isFrontBuild = isFrontBuild
		RABuildingRepairPage.resultList[#RABuildingRepairPage.resultList + 1] = t
	end
	local color = isOk and RAGameConfig.COLOR.GREEN or RAGameConfig.COLOR.RED
	UIExtend.setLabelTTFColor(ccbfile,"mRequirementLabel",color)
	UIExtend.setLabelTTFColor(ccbfile,"mQueueFull",color)
end

function RABuildingRepairCell:onJumpBtn( )
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
			RABuildingRepairPage:onClose()
		else
			RABuildingRepairPage:onClose()
		end 
	elseif self.costInfo then
		local costInfo = RAStringUtil:split(self.costInfo,"_")
	    local costType = costInfo[1] 
	    local costId = costInfo[2] 
	    local costNum = costInfo[3] 
	    if costId == DIAMONDS_TYPE then --钻石不足，打开支付页面
	    	RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
	    elseif RABuildingRepairPage.resCostTab[costId] then
	    	--RABuildingRepairPage:onClose()
		    local data={}
		    data.resourceType = RALogicUtil:resTypeToShopType(tonumber(costId))
		    RARootManager.OpenPage("RAReposityPage",data,false, true)	    		
	    end
	end 
end

--一键升级
function RABuildingRepairPage:onRepairNowBtn()

	local RARealPayManager = RARequire('RARealPayManager')

	local isCanUpgrade = true
    for k,v in ipairs(self.resultList) do
		--立即升级需要前置建筑限制，不受资源限制
		if v.isFrontBuild == false then
			isCanUpgrade = false
			break
		end  
	end
	if isCanUpgrade then
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
			local isShow = RAConfirmManager:getShowConfirmDlog(RAConfirmManager.TYPE.REPAIRENOW)
			if isShow then
				local confirmData={}
				confirmData.type=RAConfirmManager.TYPE.REPAIRENOW
				confirmData.costDiamonds = self.totalCostDiamd
				confirmData.resultFun = function (isOk)
					if isOk then
						if isEnoughDiamod then
							RABuildManager:sendRepairBuildCmd(self.uuid,true)
							RARootManager.ClosePage("RABuildingRepairPage")
						else
							-- RARootManager.OpenPage("RAPackageMainPage")
							RARealPayManager:getRechargeInfo()
						end 
					end
				end
				RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)
			else
				if isEnoughDiamod then
					RABuildManager:sendRepairBuildCmd(self.uuid,true)
					RARootManager.ClosePage("RABuildingRepairPage")
				else
					-- RARootManager.OpenPage("RAPackageMainPage")
					RARealPayManager:getRechargeInfo()
				end 
			end

		end)
	else
		--TODO play animation	
		for i,v in ipairs(self.cellCCBTab) do
			if not v.isAnimation then
				v.ccbfile:runAnimation("ShakeAni")
			end
		end	
	end	
end

--时间升级
function RABuildingRepairPage:onRepairBtn()
	local isCanUpgrade = true

    for k,v in ipairs(self.resultList) do
		if v.isOk == false then
			isCanUpgrade = false
			break
		end 
	end

	if isCanUpgrade then
		self:_doAfterCheckGuard(function ()
			RABuildManager:sendRepairBuildCmd(self.uuid, false)
			self:onClose()
		end)
	else
		--TODO play animation	
		for i,v in ipairs(self.cellCCBTab) do
			if not v.isAnimation then
				v.ccbfile:runAnimation("ShakeAni")
			end
		end
	end
end

function RABuildingRepairPage:_doAfterCheckGuard(confirmFunc)

    if confirmFunc == nil then return end

    local world_map_const_conf = RARequire('world_map_const_conf')
    if self.dataConfData.buildType == Const_pb.CONSTRUCTION_FACTORY
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

---------------------------RABuildingRepairCell end-----------------------

function RABuildingRepairPage:repairConditionCell(scrollView)
	-- body
	local queueTabInfo = nil
    if self.dataConfData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_DEFENER)
    else
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_QUEUE)
    end

    self.cellCCBTab = {}
    for k,v in pairs(queueTabInfo) do
	   local cell = CCBFileCell:create()
	   cell:setCCBFile("RABuildingUpgradeCell1.ccbi")
	   local panel = RABuildingRepairCell:new({
	       queueInfo = v
	   })
	   cell:registerFunctionHandler(panel)
	   self.cellCCBTab[#self.cellCCBTab + 1] = panel
	   scrollView:addCell(cell)
    end

	--消耗资源或者道具
    if self.defenceBuildConf.recoverRes then
   		local costTab = RAStringUtil:split(self.defenceBuildConf.recoverRes,",") 
	   	for k,info in pairs(costTab) do
	   		local cell = CCBFileCell:create()
	   		cell:setCCBFile("RABuildingUpgradeCell1.ccbi")
			local panel = RABuildingRepairCell:new({
					costInfo = info,
	        })
			cell:registerFunctionHandler(panel)
			self.cellCCBTab[#self.cellCCBTab + 1] = panel
			scrollView:addCell(cell)
	    end
    end
end

function RABuildingRepairPage:onClose()
	-- body
	RARootManager.CloseCurrPage()
end

function RABuildingRepairPage:clearDatas()
	for i,v in ipairs(self.resultList) do
		v=nil
	end
	self.resultList = nil

	for i,v in ipairs(self.resCostTab) do
		v=nil
	end
	self.resCostTab = nil
end

function RABuildingRepairPage:Exit()

	self:unregisterMessageHandlers()

	self.spineNode:removeFromParentAndCleanup(true)
	self:clearDatas()
	-- body
	self.scrollView:removeAllCell()
    self.scrollView = nil

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RABuildingRepairPage