--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--学院研究子页面 未开始研究
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb = RARequire('Const_pb')
local build_conf = RARequire("build_conf")
local Utilitys = RARequire("Utilitys")
local RALogicUtil = RARequire("RALogicUtil")
local RAQueueManager= RARequire("RAQueueManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RABuildManager = RARequire("RABuildManager")
local RAScienceUtility = RARequire("RAScienceUtility")
local RAGameConfig = RARequire("RAGameConfig")
local RAScienceManager = RARequire("RAScienceManager")
local RA_Common = RARequire("common")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAGuideManager=RARequire("RAGuideManager")

local scienceQueueDeleteMsg = MessageDef_Queue.MSG_Science_DELETE

local RAScienceNoResearchPage = BaseFunctionPage:new(...)

local TAG = 1000
local mFrameTime = 0


local RAScienceNoResearchPageCell = {
}
function RAScienceNoResearchPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAScienceNoResearchPageCell:updateQueueCellTime()

	local remainTime = Utilitys.getCurDiffTime(self.queueEndTime)
	local tmpStr = self.queueCellName.._RALang("@Researching")..Utilitys.createTimeWithFormat(remainTime)
	UIExtend.setCCLabelString(self.ccbfile,"mQueueFullTime",tmpStr)

end

function RAScienceNoResearchPageCell:onRefreshContent(ccbRoot)
	CCLuaLog("RAScienceNoResearchPageCell:onRefreshContent")
	CCLuaLog("RABuildInfoPageCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile = ccbfile

	UIExtend.setCCLabelString(ccbfile,"mRequirementLabel","")
	UIExtend.setCCLabelString(ccbfile,"mQueueFull","")
	UIExtend.setCCLabelString(ccbfile,"mQueueFullTime","")
	UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",false)
    UIExtend.setNodeVisible(ccbfile,"mRequirementLabel",true)

    local picName = ""
	local tmpCellName = ""
	local tmpCellValue =""
	local isOk = false
	RAScienceNoResearchPage.resShort = false

    --前置建筑
	if self.frontBuild  then
		local buildInfo = RABuildingUtility.getBuildInfoById(self.frontBuild)
		--local buildInfo = RALogicUtil:getBuildInfoById(self.frontBuild)
		picName = buildInfo.buildArtImg
		-- picName = testPicN
		tmpCellName = buildInfo.buildName
		local level = buildInfo.level 
		tmpCellValue = _RALang("@LevelNum",level).._RALang(tmpCellName)
		local isBuildExist = RABuildManager:isBuildingExist(self.frontBuild,buildInfo.buildType)

		if isBuildExist  then
			isOk = true
		end 
		-- isOk = true
	elseif self.frontTech then  --前置科技
		local techInfo = RAScienceUtility:getScienceDataById(self.frontTech)
		picName = techInfo.techPic
		-- picName = testPicN
		tmpCellName = techInfo.techName
		local level = techInfo.techLevel
		tmpCellValue =_RALang("@LevelNum",level).._RALang(tmpCellName)
		local isFinishExist = RAScienceManager:isResearchFinish(self.frontTech)

		if isFinishExist  then
			isOk = true
		end 

	elseif self.queueInfo  then  --科技队列已满
		--这里需要替换接口
		local techInfo = RAScienceUtility:getScienceDataById(self.queueInfo.itemId)
		-- local buildInfo = RABuildingUtility.getBuildInfoById(201001)
		tmpCellValue = _RALang("@ResearchQueueFull")
		tmpCellName = techInfo.techName
        -- tmpCellName = "xx"
		self.queueCellName =_RALang(tmpCellName) 
		UIExtend.setCCLabelString(ccbfile,"mQueueFull",tmpCellValue)
		UIExtend.setNodeVisible(ccbfile,"mRequirementLabel",false)
		local endTime = self.queueInfo.endTime
		-- local endTime = os.time()+3600
		self.queueEndTime = endTime
		isOk = false

	else
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
		
		  tmpCellValue = _RALang("@UpgradFenGe",Utilitys.formatNumber(tmpSumValue),Utilitys.formatNumber(costNum))
		  if tmpSumValue >=tonumber(costNum) then
		  	isOk = true
		  end 

		elseif RALogicUtil:isResourceById(costId) then

			--资源 
			picName = RALogicUtil:getResourceIconById(costId)
			local curNum = RAPlayerInfoManager.getResCountById(tonumber(costId))
			
			tmpCellValue = _RALang("@UpgradFenGe",Utilitys.formatNumber(curNum),Utilitys.formatNumber(costNum))
			local resCost = tonumber(costNum)
			isOk = curNum>=resCost and true or false
			if not isOk then
				local costNum = resCost-curNum
				RAScienceNoResearchPage.resCostTab[costId]=costNum
				RAScienceNoResearchPage.resShort = true
			end 
		end 
	end 
	

	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mItemPicNode")
	UIExtend.addNodeToAdaptParentNode(picNode,picName,TAG)

	UIExtend.setCCLabelString(ccbfile,"mRequirementLabel",tmpCellValue)
	UIExtend.setNodeVisible(ccbfile,"mReachPic",isOk)
	-- UIExtend.setNodeVisible(ccbfile,"mNotReachedPic",not isOk)

	if not RAScienceNoResearchPage.resShort then
		table.insert(RAScienceNoResearchPage.resultList,isOk)
	end

	local color = isOk and RAGameConfig.COLOR.GREEN or RAGameConfig.COLOR.RED
	UIExtend.setLabelTTFColor(ccbfile,"mRequirementLabel",color)
	UIExtend.setLabelTTFColor(ccbfile,"mQueueFull",color)
	UIExtend.setLabelTTFColor(ccbfile,"mQueueFullTime",color)

	-- RAScienceNoResearchPage:setResearchBtn(isOk)

end

local OnReceiveMessage = function(message)
   if message.messageID == scienceQueueDeleteMsg then
   		RAScienceNoResearchPage:updateInfo()
   	elseif message.messageID == MessageDef_RootManager.MSG_ActionEnd then 
		if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
			RARootManager.AddCoverPage()
    		RAGuideManager.gotoNextStep()
		end
   	elseif message.messageID == MessageDef_Guide.MSG_Guide then 
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleNowResearchBtn then
            if constGuideInfo.showGuidePage == 1 then
                local reasearhBtn = UIExtend.getCCNodeFromCCB(RAScienceNoResearchPage.ccbfile, "mResearchNowBtn")
                local pos = ccp(0, 0)
                pos.x, pos.y = reasearhBtn:getPosition()
                local worldPos = reasearhBtn:getParent():convertToWorldSpace(pos)
                local size = reasearhBtn:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end 
        end 
   end 
end


function RAScienceNoResearchPage:Enter(data)


	CCLuaLog("RAScienceNoResearchPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RACollegePopUp.ccbi",self)
	self.ccbfile  = ccbfile
	self.data = data.scienceInfo
	self.buildId =data.buildId
	self.maxLevel = data.maxLevel
	self.resultList = {}
	self.resCostTab = {}
	self:registerMessageHandler()
	self:init()
end

function RAScienceNoResearchPage:registerMessageHandler()
    MessageManager.registerMessageHandler(scienceQueueDeleteMsg,OnReceiveMessage) 

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
        MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end
    
end

function RAScienceNoResearchPage:removeMessageHandler()
    MessageManager.removeMessageHandler(scienceQueueDeleteMsg,OnReceiveMessage)
    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
        MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end
end

-- function RAScienceNoResearchPage:calculateTime()
-- 	local researchTime = self.data.buildTime
-- 	local effectValue = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_SCIENCE)
-- 	researchTime = researchTime * (1 + 0.01 * effectValue)
-- 	return researchTime
-- end


function RAScienceNoResearchPage:init()

	-- 这个显示的是下一等级的信息
	-- --初始化
	self.mRequirementSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mMoreInfoCellSV")
	local titleName = _RALang(self.data.techName )
	UIExtend.setCCLabelString(self.ccbfile,"mMoreInfoTitle",titleName)
	-- UIExtend.setCCLabelString(self.ccbfile,"mOriginalTime",Utilitys.createTimeWithFormat(self.data.buildTime))

	--icon
	self.mPopUpIconNode =  UIExtend.getCCNodeFromCCB(self.ccbfile,"mCellSkillIconNode")

	local pic=UIExtend.addNodeToAdaptParentNode(self.mPopUpIconNode,self.data.techPic,TAG)
	
	local maxLevel=RAScienceUtility:getScienceMaxLevel(self.data.id)
	--process
	local curLevel = self.data.techLevel
	local levelStr = _RALang("@ScienceLevel",curLevel-1,maxLevel)
	UIExtend.setCCLabelString(self.ccbfile,"mCellLevel",levelStr)
	local RAGameConfig=RARequire("RAGameConfig")
	if curLevel==1 then
		UIExtend.setLabelTTFColor(self.ccbfile,"mCellLevel",RAGameConfig.COLOR.GRAY)
		UIExtend.setNodeVisible(self.ccbfile,"mRedBGNode",false)
		UIExtend.setCCSpriteGray(pic,true)
	else
		UIExtend.setLabelTTFColor(self.ccbfile,"mCellLevel",RAGameConfig.COLOR.GREEN)
		UIExtend.setNodeVisible(self.ccbfile,"mRedBGNode",true)
		UIExtend.setCCSpriteGray(pic)
	end 
	local des = _RALang(self.data.techDes)
	UIExtend.setCCLabelString(self.ccbfile,"mUpgradeExplain",des)
	local battlePoint =self.data.battlePoint
	UIExtend.setCCLabelString(self.ccbfile,"mBattlePoint",_RALang("@BattlePointX",battlePoint))
	


	--effect
	if self.data.techEffectID then
			UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevel",true)
			UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",true)
			UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevelBg",true)
			UIExtend.setNodeVisible(self.ccbfile,"mNextLevelBg",true)
			local effectTab = RAStringUtil:split(self.data.techEffectID,"_")
			local curEffectId =tonumber(effectTab[1])
			local cueEffectValue =tonumber(effectTab[2])

			--self.data.id 要比当前等级高一级
			-- local isReachMax = RAScienceUtility:isReachMaxLevel(self.data.id)
			-- if isReachMax then

			-- end 
			
			-- local isReachMax = RAScienceUtility:isReachMaxLevel(self.data.id)

			
			local pretEffectValue = RAScienceUtility:getEffectValueById(self.data.id-1)
			local cueEffectValue  = RAScienceUtility:getEffectValueById(self.data.id)
			local nextEffectValue  = RAScienceUtility:getEffectValueById(self.data.id+1)

			local keyStr = self.data.techTip 
			if pretEffectValue==0 then -- 最低级
				UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevel",true)
				UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevelBg",true)
				pretEffectValue=_RALang(keyStr,pretEffectValue)
			elseif nextEffectValue==0 then --最高级
				UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",false)
				UIExtend.setNodeVisible(self.ccbfile,"mNextLevelBg",false)
				pretEffectValue =_RALang(keyStr,cueEffectValue)
			else
				UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",true)
				UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevelBg",true)
				pretEffectValue=_RALang(keyStr,pretEffectValue) 
			end
			
			UIExtend.setCCLabelString(self.ccbfile,"mCurrentLevel",_RALang("@CurLevel")..pretEffectValue)
			UIExtend.setCCLabelString(self.ccbfile,"mNextLevel",_RALang("@NextLevel").._RALang(keyStr,cueEffectValue))

			local isReachMax = RAScienceUtility:isReachMaxLevel(self.data.id)
			if isReachMax then
				cueEffectValue = RAScienceUtility:getEffectValueById(self.data.id-1)
				nextEffectValue = RAScienceUtility:getEffectValueById(self.data.id)
				UIExtend.setCCLabelString(self.ccbfile,"mCurrentLevel",_RALang("@CurLevel").._RALang(keyStr,cueEffectValue))
			    UIExtend.setCCLabelString(self.ccbfile,"mNextLevel",_RALang("@NextLevel").._RALang(keyStr,nextEffectValue))
				
				UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevel",true)
				UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",true)
				UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevelBg",true)
				UIExtend.setNodeVisible(self.ccbfile,"mNextLevelBg",true)
			end


	else
	
		UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevel",false)
		UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",false)
		UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevelBg",false)
		UIExtend.setNodeVisible(self.ccbfile,"mNextLevelBg",false)
	end 

	
	self:updateInfo()
end
function RAScienceNoResearchPage:Execute()
    mFrameTime = mFrameTime + RA_Common:getFrameTime()
    if mFrameTime > 1 then
    	if self.mRequirementSV and self.queueTab then
			for i,v in ipairs(self.queueTab) do
				local cell = v
				cell:updateQueueCellTime()
			end
		end 
		mFrameTime=0
    end
	

end


function RAScienceNoResearchPage:isCanUpgrade()
	-- body

	--根据时间计算出消耗金币  
	local effectValue = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_SCIENCE)
	local researchTime = self.data.techTime /(1+effectValue/FACTOR_EFFECT_DIVIDE)
	local electric = RAPlayerInfoManager.getCurrElectricEffect()
	researchTime = math.ceil(researchTime*electric)
	-- local gold = RALogicUtil:time2Gold(researchTime)
	UIExtend.setCCLabelString(self.ccbfile,"mOriginalTime",Utilitys.createTimeWithFormat(self.data.techTime))
	UIExtend.setCCLabelString(self.ccbfile,"mActualTime",Utilitys.createTimeWithFormat(researchTime))
	-- UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",gold)

	local timeCostDimand = RALogicUtil:time2Gold(researchTime)
	-- UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",_RALang("@Diamond").." "..actualCost)

	--需求条件判断 不包括资源不足的情况
	local isCanUpgrade = true
	local totalCostDiamd = 0
	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
	for i,v in ipairs(self.resultList) do
		if v==false then
			isCanUpgrade = false
			break
		end 
	end

	
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mResearchBtn",isCanUpgrade)

	--当前置建筑 前置科技 科技队列其中之一不满足的情况下就设置不可点击
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mResearchNowBtn",isCanUpgrade)

	--资源不足时判断玩家钻石是否满足
	self.totalCostDiamd =0
	self.totalCostDiamd=self.totalCostDiamd+timeCostDimand
	if isCanUpgrade then
		
		local resCostDiamond = 0
		for k,v in pairs(self.resCostTab) do
			local resId = k
			local resCostNum = v
			resCostDiamond = resCostDiamond+RALogicUtil:res2Gold(resCostNum,resId)
		end

		self.totalCostDiamd = self.totalCostDiamd + resCostDiamond
	
		--只要资源不满足就把研究按钮设置不可点击
		if next(self.resCostTab) then
			UIExtend.setCCControlButtonEnable(self.ccbfile,"mResearchBtn",not isCanUpgrade)
		end 
		
    end
	
	UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",self.totalCostDiamd)

end

function RAScienceNoResearchPage:updateInfo()
	self.mRequirementSV:removeAllCell()
	local scrollview = self.mRequirementSV
  

   --判断研究队列是否已满
   local queueTabInfo = RAQueueManager:getQueueDatas(Const_pb.SCIENCE_QUEUE)
   self.queueTab = {}
   for i,v in pairs(queueTabInfo) do
   		local cell = CCBFileCell:create()
		cell:setCCBFile("RACollegePopUpCell.ccbi")
		local info = v
		local panel = RAScienceNoResearchPageCell:new({
				queueInfo = info,
        })
		cell:registerFunctionHandler(panel)
		scrollview:addCell(cell)
		table.insert(self.queueTab,panel)
   end
  --  if true then
  --  		local cell = CCBFileCell:create()
		-- cell:setCCBFile("RACollegePopUpCell.ccbi")
		-- local panel = RAScienceNoResearchPageCell:new({
		-- 		queueInfo = true,
  --       })
		-- cell:registerFunctionHandler(panel)
		-- scrollview:addCell(cell)
		-- table.insert(self.queueTab,panel)
  --  end 

  --前置建筑
   if self.data.frontBuild  then
	    local frontBuildTab = RAStringUtil:split(self.data.frontBuild,",")
	    for i,v in ipairs(frontBuildTab) do
	    	local frontBuild = v
	    	local cell = CCBFileCell:create()
			cell:setCCBFile("RACollegePopUpCell.ccbi")
			local panel = RAScienceNoResearchPageCell:new({
					frontBuild = frontBuild,
	        })
			cell:registerFunctionHandler(panel)
			scrollview:addCell(cell)
	    end	
   end 

   --前置科技
   if self.data.frontTech  then
	    local frontTechTab = RAStringUtil:split(self.data.frontTech,",")

	    local completeFrontTechIds = {}
	    for i, frontTechId in ipairs(frontTechTab) do
	    	frontTechId = tonumber(frontTechId)
	    	local isScienceExist = RAScienceManager:isResearchFinish(frontTechId)
	    	if isScienceExist then
	    		completeFrontTechIds[#completeFrontTechIds + 1] = frontTechId
	    	end
	    end	

	    if #completeFrontTechIds > 0 then
			for i,frontTech in ipairs(completeFrontTechIds) do
		    	local cell = CCBFileCell:create()
				cell:setCCBFile("RACollegePopUpCell.ccbi")
				local panel = RAScienceNoResearchPageCell:new({
						frontTech = frontTech,
		        })
				cell:registerFunctionHandler(panel)
				scrollview:addCell(cell)
		    end	
	    else
	    	for i,frontTech in ipairs(frontTechTab) do
		    	local cell = CCBFileCell:create()
				cell:setCCBFile("RACollegePopUpCell.ccbi")
				local panel = RAScienceNoResearchPageCell:new({
						frontTech = frontTech,
		        })
				cell:registerFunctionHandler(panel)
				scrollview:addCell(cell)
		    end	
	    end
   end 

   --消耗资源或者道具
   if self.data.techCost then
   	 local costTab = RAStringUtil:split(self.data.techCost,",") 
   	 for k,v in pairs(costTab) do
   	 
   		local cell = CCBFileCell:create()
		cell:setCCBFile("RACollegePopUpCell.ccbi")
		local info = v
		local panel = RAScienceNoResearchPageCell:new({
				costInfo = info,
        })
		cell:registerFunctionHandler(panel)
		scrollview:addCell(cell)
		
   	 end
   end 
   
   scrollview:orderCCBFileCells(scrollview:getViewSize().width)

    if scrollview:getContentSize().height < scrollview:getViewSize().height then
		scrollview:setTouchEnabled(false)
	else
		scrollview:setTouchEnabled(true)
    end 
	self:isCanUpgrade()

	--学院在升级时 不让研究
	self.curBuildIsUpgrade=RAQueueManager:isBuildingUpgrade(self.buildId)
	-- if curBuildIsUpgrade then
	--    UIExtend.setCCControlButtonEnable(self.ccbfile,"mResearchBtn",false)
	--    UIExtend.setCCControlButtonEnable(self.ccbfile,"mResearchNowBtn",false)
	-- end 

end

function RAScienceNoResearchPage:onResearchNowBtn( )

	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
       RARootManager.AddCoverPage()
       RARootManager.RemoveGuidePage()
       RAScienceManager:sendReseachNowCmd(self.data.id)
       RARootManager.CloseAllPages()
       return 
    end
	if self.curBuildIsUpgrade then
	  	local confirmData = {}	
		confirmData.labelText = _RALang("@BuildUpgradeResearchTip")
		RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
		return 
	end 
	-- local tipStr = ""
	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
	local isEnoughDiamod = playerDiamond>=self.totalCostDiamd and true or false

    local RAConfirmManager = RARequire("RAConfirmManager")
    local isShow = RAConfirmManager:getShowConfirmDlog(RAConfirmManager.TYPE.RESEARCHNOW)
    if isShow then
        local confirmData={}
        confirmData.type=RAConfirmManager.TYPE.RESEARCHNOW
        confirmData.costDiamonds = self.totalCostDiamd
        confirmData.resultFun = function (isOk)
            if isOk then
        		if isEnoughDiamod then
					RAScienceManager:sendReseachNowCmd(self.data.id)
					RARootManager.ClosePage("RAScienceNoResearchPage")
					--研究成功提示
					RAScienceUtility:showResearchSuccessTip(self.data.id)
				else
					RARootManager.OpenPage("RARechargeMainPage")
				end 
    		end 
        end
        RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)
    else
    	if isEnoughDiamod then
			RAScienceManager:sendReseachNowCmd(self.data.id)
			RARootManager.ClosePage("RAScienceNoResearchPage")
			--研究成功提示
			RAScienceUtility:showResearchSuccessTip(self.data.id)
		else
			RARootManager.OpenPage("RARechargeMainPage")
		end 
    end

end

function RAScienceNoResearchPage:onResearchBtn( )

	if self.curBuildIsUpgrade then
	  	local confirmData = {}
		
		confirmData.labelText = _RALang("@BuildUpgradeResearchTip")
	
		RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
	else
		CCLuaLog("RAScienceNoResearchPage:onResearchBtn")
		RARootManager.ClosePage("RAScienceNoResearchPage")
		RAScienceManager:sendReseachCmd(self.data.id)
	end
	
end

function RAScienceNoResearchPage:onCloseBtn()
	RARootManager.ClosePage("RAScienceNoResearchPage")
end

function RAScienceNoResearchPage:Exit()
	self.mRequirementSV:removeAllCell()
	self:removeMessageHandler()
	self.resultList = nil
	self.resCostTab = nil
	self.queueTab  = nil
	UIExtend.unLoadCCBFile(RAScienceNoResearchPage)
	--ScrollViewAnimation.clearTable()
end
--endregion
