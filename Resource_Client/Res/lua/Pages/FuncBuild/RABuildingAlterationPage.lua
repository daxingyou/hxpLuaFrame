--改造建筑弹出页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb = RARequire("Const_pb")
local RAQueueManager = RARequire("RAQueueManager")
local RABuildManager = RARequire("RABuildManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGameConfig = RARequire("RAGameConfig")
local RACitySceneManager = RARequire("RACitySceneManager")
local RABuildInformationUtil = RARequire("RABuildInformationUtil")
local RAScienceManager = RARequire("RAScienceManager")
local RAScienceUtility = RARequire("RAScienceUtility")

local RABuildingAlterationPage = BaseFunctionPage:new(...)

local currAnimainStatus = true
local rebuildAnimainStatus = true
local TAG = 1000

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	--刷新
    	RABuildingAlterationPage:alterationSuccessRefresh()

    	--建筑改造完成需要关闭页面
    	local HP_pb = RARequire("HP_pb")
    	if message.opcode == HP_pb.BUILDING_REBUILD_C then 
    		RARootManager.CloseAllPages()
   		end
    	--
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 

    elseif message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo or message.messageID == MessageDef_MainUI.MSG_PayInfoRefresh then        	
   		--刷新资源
   		RABuildingAlterationPage:initReBuildIf()
    end 
end

function RABuildingAlterationPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RABuildingAlterationPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
end

function RABuildingAlterationPage:alterationSuccessRefresh()
	-- body
	if self.currBuildData.buildType == Const_pb.ORE_REFINING_PLANT then --矿石精鍊厂 改建成了其他的 需要remove 矿车
		local RACitySceneManager = RARequire("RACitySceneManager")
    	RACitySceneManager:removeOneMineCarByBuildData(self.buildData)
	end
end

function RABuildingAlterationPage:Enter(data)
	-- body
	UIExtend.loadCCBFile("RABuildingAlterationPage.ccbi",self)
	self.buildData = data.currBuildData
	self.buildId = self.buildData.id
	self.currBuildData = self.buildData.confData
	local reBuildInfo = data.reBuildData

	self.reBuildData = RABuildManager:getBuildInfoByBuildType(reBuildInfo.buildType,self.currBuildData.level)
	self.resultList = {}
	self.resCostTab = {}
	self.resShort = false

	self:registerMessage()

	self:refreshUI()

	self:initReBuildIf()
end

function RABuildingAlterationPage:refreshUI()
	--body
	UIExtend.setCCLabelString(self.ccbfile,"mTitle", _RALang("@BuildingAlterationTitle",_RALang(self.currBuildData.buildName)))
	--curr build ui
	self:refreshOldBuildCCB()
	--rebuild ui
	self:refreshNewBuildCCB()

	--curr build attr
	local currBuildName = _RALang("@NameWithLevelTwoParams2",_RALang(self.currBuildData.buildName), self.currBuildData.level)

	local currRefrain = _RALang("@OutPut",_RALang(self.currBuildData.rebuildResourceType))
	local soldierConf = RABuildingUtility:getDefenceBuildConfById(self.currBuildData.id)
    if soldierConf then
    	currRefrain = _RALang("@Refrain",_RALang(soldierConf.subdue))
	end
	local oldDesStr = RAStringUtil:getHTMLString("BuildDetails",currBuildName , self.currBuildData.electricConsume,currRefrain)
	UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mOldBuildDetails"):setString(oldDesStr)

	--rebuild attr

	local newBuildName = _RALang("@NameWithLevelTwoParams2",_RALang(self.reBuildData.buildName), self.reBuildData.level)
	local newRefrain = _RALang("@OutPut",_RALang(self.reBuildData.rebuildResourceType))
		
	local soldierConf = RABuildingUtility:getDefenceBuildConfById(self.reBuildData.id)
    if soldierConf then
    	newRefrain = _RALang("@Refrain",_RALang(soldierConf.subdue))
	end

	local newDesStr = RAStringUtil:getHTMLString("BuildDetails", newBuildName, self.reBuildData.electricConsume, newRefrain)
	UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mNewBuildDetails"):setString(newDesStr)

	--init scrollView 
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

	--时间
	--UIExtend.setCCLabelString(self.ccbfile,"mNeedTime",Utilitys.createTimeWithFormat(self.reBuildData.rebuildTime))

	--self:calTotalCostDiamond()
end

function RABuildingAlterationPage:refreshOldBuildCCB()
	-- body
	local oldBuildCCB = self.ccbfile:getCCBFileFromCCB("mOldBuildCCB")
	if oldBuildCCB then
		--set build icon
		if currAnimainStatus then
			oldBuildCCB:runAnimation("SwitchSprAni")
			UIExtend.removeSpriteFromNodeParent(oldBuildCCB, 'mIconNode1')
			UIExtend.addSpriteToNodeParent(oldBuildCCB, "mIconNode1",self.currBuildData.buildArtImg)
		else
			oldBuildCCB:runAnimation("SwitchLabelAni")
			if self.reBuildData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
				local soldierConf = RABuildingUtility:getDefenceBuildConfById(self.currBuildData.id)
            	local desStr = RAStringUtil:getHTMLString("BuildingAlterationDefenseDetails", soldierConf.attack, soldierConf.defence, soldierConf.hp)
				UIExtend.getCCLabelHTMLFromCCB(oldBuildCCB,"mDetailsLabel"):setString(desStr)
			else  --资源采集建筑
				local resLimit = self.currBuildData.resLimit --资源容量上限
				local resPerHour = self.currBuildData.resPerHour --产量/小时

				local desStr = RAStringUtil:getHTMLString("BuildingAlterationResDetails", resPerHour, resLimit)
				UIExtend.getCCLabelHTMLFromCCB(oldBuildCCB,"mDetailsLabel"):setString(desStr)
			end
		end
	end
end

function RABuildingAlterationPage:refreshNewBuildCCB()
	-- body
	local newBuildCCB = self.ccbfile:getCCBFileFromCCB("mNewBuildCCB")
	if newBuildCCB then
		--set build icon
		if rebuildAnimainStatus then
			newBuildCCB:runAnimation("SwitchSprAni")
			UIExtend.removeSpriteFromNodeParent(newBuildCCB, 'mIconNode1')
			UIExtend.addSpriteToNodeParent(newBuildCCB, "mIconNode1",self.reBuildData.buildArtImg)
		else
			newBuildCCB:runAnimation("SwitchLabelAni")
			if self.reBuildData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
				local soldierConf = RABuildingUtility:getDefenceBuildConfById(self.reBuildData.id)
            	local desStr = RAStringUtil:getHTMLString("BuildingAlterationDefenseDetails", soldierConf.attack, soldierConf.defence, soldierConf.hp)
				UIExtend.getCCLabelHTMLFromCCB(newBuildCCB,"mDetailsLabel"):setString(desStr)
			else  --资源采集建筑
				local resLimit = self.reBuildData.resLimit --资源容量上限
				local resPerHour = self.reBuildData.resPerHour --产量/小时

				local desStr = RAStringUtil:getHTMLString("BuildingAlterationResDetails", resPerHour, resLimit)
				UIExtend.getCCLabelHTMLFromCCB(newBuildCCB,"mDetailsLabel"):setString(desStr)
			end
		end
	end
end

function RABuildingAlterationPage:mOldBuildCCB_onDetailsBtn()

	currAnimainStatus = not currAnimainStatus

	self:refreshOldBuildCCB()

end

function RABuildingAlterationPage:mNewBuildCCB_onDetailsBtn()

	rebuildAnimainStatus = not rebuildAnimainStatus

	self:refreshNewBuildCCB()
end

function RABuildingAlterationPage:initReBuildIf()
	-- body
	self.resultList = {}

	self.scrollView:removeAllCell()

    local scrollView = self.scrollView

    self:reBuildNeedResCell(scrollView)
  	--
	scrollView:orderCCBFileCells()

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		scrollView:setTouchEnabled(true)
	end 

	self:calTotalCostDiamond()
end

function RABuildingAlterationPage:calculateTime()
    -- body
    -- （（建筑原始时间/（1+作用号400））- 爱因斯坦小屋（417）减少时间）*（1+电力影响）
    local researchTime = self.reBuildData.rebuildTime
    local effectValue = nil
    if self.reBuildData.limitType ~= Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
    	effectValue = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_BUILD)
    else
        effectValue = RALogicUtil:getEffectResult(Const_pb.CITYDEF_SPD_BUILD)
    end

    local effectValue1 = RALogicUtil:getEffectResult(Const_pb.CITY_BUILD_REDUCE_TIME)
    
    researchTime = researchTime /(1+effectValue/FACTOR_EFFECT_DIVIDE)-effectValue1

    return researchTime
end

function RABuildingAlterationPage:calTotalCostDiamond()
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

	--UIExtend.setCCControlButtonEnable(self.ccbfile,"onAlterationNowBtn",isCanUpgrade)
	--UIExtend.setCCControlButtonEnable(self.ccbfile,"mAlterationBtn",isCanUpgrade)

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
	-- 	UIExtend.setCCControlButtonEnable(self.ccbfile,"mAlterationBtn",false)
	-- end 
		
    --end
	
	UIExtend.setCCLabelString(self.ccbfile,"mNeedDiamondsNum",self.totalCostDiamd)
	
end

--改造
function RABuildingAlterationPage:onAlterationBtn()
	-- body
	local isCanUpgrade = true
    for k,v in ipairs(self.resultList) do
		if v.isOk == false then
			isCanUpgrade = false
			break
		end 
	end

	if isCanUpgrade then
		self:_doAfterCheckGuard(function ()
			RABuildManager:sendReBuildCmd(self.buildId,self.reBuildData.id, false)
			--self:onClose()
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

function RABuildingAlterationPage:_doAfterCheckGuard(confirmFunc)

    if confirmFunc == nil then return end

    local world_map_const_conf = RARequire('world_map_const_conf')
    if self.reBuildData.buildType == Const_pb.CONSTRUCTION_FACTORY
    	and self.reBuildData.level == world_map_const_conf.stepCityLevel1.value
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

--一键改造
function RABuildingAlterationPage:onAlterationNowBtn()
	-- body
	local RAGuideManager = RARequire('RAGuideManager')
	if RAGuideManager.isInGuide() then
		return
	end
	local isCanUpgrade = true
    for k,v in ipairs(self.resultList) do
		if v.isFrontBuild == false then --
			isCanUpgrade = false
			break
		end 
	end

	local RARealPayManager = RARequire('RARealPayManager')
    
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
        	local isShow = RAConfirmManager:getShowConfirmDlog(RAConfirmManager.TYPE.RECONSTRUCTNOW)
			if isShow then
				local confirmData={}
	            confirmData.type=RAConfirmManager.TYPE.RECONSTRUCTNOW
	            confirmData.costDiamonds = self.totalCostDiamd
	            confirmData.resultFun = function (isOk)
	                if isOk then
	            		if isEnoughDiamod then
							RABuildManager:sendReBuildCmd(self.buildId, self.reBuildData.id, true)
							--RARootManager.ClosePage("RABuildingAlterationPage")
						else
							-- RARootManager.OpenPage("RAPackageMainPage")
							RARealPayManager:getRechargeInfo()
						end 
	        		end 
	            end
	            RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)

			else
				if isEnoughDiamod then
					RABuildManager:sendReBuildCmd(self.buildId, self.reBuildData.id, true)
					--RARootManager.ClosePage("RABuildingAlterationPage")
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

---------------------------
------------------------------------RAReBuildingCell-----------------------------------------------------
--------改造条件cell
local RAReBuildingCell = {}

function RAReBuildingCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAReBuildingCell:updateTime()
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

	UIExtend.setCCLabelString(self.ccbfile,"mQueueFull",tmpCellName)
end

function RAReBuildingCell:onJumpBtn( )
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
			RARootManager.CloseAllPages()
		else
			RARootManager.CloseAllPages()
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
				RABuildingAlterationPage:scienceComplete()
			end
			RARootManager.OpenPage("RAScienceTreePage",data,true,true)	
		else
			RABuildingAlterationPage:onClose()
			local RAGuideManager = RARequire("RAGuideManager")
			RAGuideManager:guideToConsturctionBtn()	
		end		
	elseif self.costInfo then
		local costInfo = RAStringUtil:split(self.costInfo,"_")
	    local costType = costInfo[1] 
	    local costId = costInfo[2] 
	    local costNum = costInfo[3] 
	    if costId == DIAMONDS_TYPE then --钻石不足，打开支付页面
	    	RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
	    elseif RABuildingAlterationPage.resCostTab[costId] then
	    	--RARootManager.CloseAllPages()
		    local data={}
		    data.resourceType = RALogicUtil:resTypeToShopType(tonumber(costId))
		    RARootManager.OpenPage("RAReposityPage",data,false, true)	    		
	    end
	end 
end

function RAReBuildingCell:onRefreshContent(ccbRoot)
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

		self.queueStatus = self.queueInfo.status

		isFrontBuild = false

		local scheduleFunc = function ()
            self:updateTime(self)
        end

        self.frontBuild = buildingData.confData.id
        self.isFrontBuildExist = false
        self.isFrontScienceExist = false

        schedule(self.ccbfile,scheduleFunc,0.05)

        picName = buildingData.confData.buildArtImg
        local endTime = self.queueInfo.endTime
		-- local endTime = os.time()+3600
		self.queueEndTime = endTime
		isOk = false
		UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",true)
	elseif self.frontScienceId then
		local frontScienceConf = RAScienceUtility:getScienceDataById(self.frontScienceId)
		picName = frontScienceConf.techPic
		tmpCellName = _RALang("@FrontScienceName",_RALang(frontScienceConf.techName))
		local level = frontScienceConf.techLevel
		tmpCellValue = tmpCellName	--_RALang("@LevelNum",level)..tmpCellName

		local isScienceExist = RAScienceManager:isResearchFinish(self.frontScienceId)
		self.isFrontScienceExist = isScienceExist

		if isScienceExist then
			isOk = true
		else
			isFrontBuild = isScienceExist
		end	
		UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)	
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
				RABuildingAlterationPage.resCostTab[costId] = costNum
				RABuildingAlterationPage.resShort = false
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
				RABuildingAlterationPage.resShort = false
			end 

			--local costNum = playerDiamond - diamondCost-playerDiamond
			RABuildingAlterationPage.resCostTab[costId] = costNum
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

	if not RABuildingAlterationPage.resShort then
		local t = {}
		t.isOk = isOk
		t.isRes = isRes
		t.isFrontBuild = isFrontBuild
		RABuildingAlterationPage.resultList[#RABuildingAlterationPage.resultList + 1] = t
	end
	local color = isOk and RAGameConfig.COLOR.GREEN or RAGameConfig.COLOR.RED
	UIExtend.setLabelTTFColor(ccbfile,"mRequirementLabel",color)
	UIExtend.setLabelTTFColor(ccbfile,"mQueueFull",color)
end

--科技升级完成刷新回调
function RABuildingAlterationPage:scienceComplete()
	-- body
	self:initReBuildIf()
end

function RABuildingAlterationPage:reBuildNeedResCell(scrollView)
	local queueTabInfo = nil
    if self.reBuildData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_DEFENER)
    else
   		queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_QUEUE)
    end

    self.cellCCBTab = {}
    for k,v in pairs(queueTabInfo) do
	   local cell = CCBFileCell:create()
	   cell:setCCBFile("RABuildingUpgradeCell1.ccbi")
	   local panel = RAReBuildingCell:new({
	       queueInfo = v
	   })
	   cell:registerFunctionHandler(panel)
	   self.cellCCBTab[#self.cellCCBTab + 1] = panel
	   scrollView:addCell(cell)
    end

    --科技前置 至多一个
  	if self.reBuildData.frontScience then
  	   local frontSciences = RAStringUtil:split(self.reBuildData.frontScience, ",")
	   for k,frontScienceId in ipairs(frontSciences) do
	   		if frontScienceId and tonumber(frontScienceId) then
		   		local cell = CCBFileCell:create()
		   		cell:setCCBFile("RABuildingUpgradeCell1.ccbi")
				local panel = RAReBuildingCell:new({
					frontScienceId = tonumber(frontScienceId)
		        })
				cell:registerFunctionHandler(panel)
				self.cellCCBTab[#self.cellCCBTab + 1] = panel
				scrollView:addCell(cell)
			end
	   end
  	end 

	--消耗资源或者道具
    if self.reBuildData.rebuildRes then
   		local costTab = RAStringUtil:split(self.reBuildData.rebuildRes,",") 
	   	for k,info in pairs(costTab) do
	   		local cell = CCBFileCell:create()
	   		cell:setCCBFile("RABuildingUpgradeCell1.ccbi")
			local panel = RAReBuildingCell:new({
					costInfo = info
	        })
			cell:registerFunctionHandler(panel)
			self.cellCCBTab[#self.cellCCBTab + 1] = panel
			scrollView:addCell(cell)
	    end
    end
end

function RABuildingAlterationPage:onClose()
	-- body
	RARootManager.CloseCurrPage()
end

function RABuildingAlterationPage:clearDatas()
	for i,v in ipairs(self.resultList) do
		v=nil
	end
	self.resultList = nil

	for i,v in ipairs(self.resCostTab) do
		v=nil
	end
	self.resCostTab = nil
end

function RABuildingAlterationPage:Exit()

	self:removeMessageHandler()

	self:clearDatas()

	currAnimainStatus = true

    self.scrollView:removeAllCell()
    self.scrollView = nil

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RABuildingAlterationPage