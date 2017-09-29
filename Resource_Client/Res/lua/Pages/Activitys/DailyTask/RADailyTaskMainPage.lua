--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RADailyTaskActivityManager = RARequire("RADailyTaskActivityManager")
local RADailyTaskActivityUtility = RARequire("RADailyTaskActivityUtility")
local RA_Common = RARequire("common")

RARequire("MessageDefine")
RARequire("MessageManager")

local updateMsg = MessageDef_DailyTaskStatus.MSG_DailyTask_Changed

local mFrameTime = 0

local RADailyTaskMainPage = BaseFunctionPage:new(...)


local OnReceiveMessage = function(message)
    if message.messageID == updateMsg then			--阶段变更
      RADailyTaskMainPage:updateInfo()
    end
end

-------------------------Cell Begin--------------------------------

local RADailyTaskMainCell = {

}
function RADailyTaskMainCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskMainCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskMainCell:onRefreshContent")
	if not ccbRoot then return end
	ccbRoot:setIsScheduleUpdate(true)
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile
    self.endT = nil

    local bottomBgNode = UIExtend.getCCNodeFromCCB(ccbfile,"mBottomBGNode")
    local leftNode  = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftBGNode")
    local rightNode  = UIExtend.getCCNodeFromCCB(ccbfile,"mRightBGNode")
    bottomBgNode:removeAllChildren()
    leftNode:removeAllChildren()
    rightNode:removeAllChildren()

    local data  = self.data
    local activityId = data.activityId
    self.activityId = activityId

    local activityConfigData = RADailyTaskActivityUtility:getActivityConfigData(activityId)
   
   	--活动名称
    local activityName = _RALang(activityConfigData.eventName)
    UIExtend.setCCLabelString(ccbfile,"mActivityName",activityName)

    local curStageId  = data.stageId
    local firstRound = data.firstRound

    --firstRound: 1 首次活动 0 非首次活动
    local stageDatas=nil
    if firstRound==1 then
		stageDatas=RADailyTaskActivityUtility:getFirstStageIdsInActivity(activityId)
    else
    	stageDatas=RADailyTaskActivityUtility:getStageIdsInActivity(activityId)
    end 
  

 	local leftTab={}
 	local rightTab={}
    self.curStageId = curStageId
    for i,v in ipairs(stageDatas) do
    	local stageId = v
    	local statu= RADailyTaskActivityUtility:getStatgeStatue(self.activityId,self.curStageId,stageId)
		if statu==RADailyTaskActivityUtility.STAGESTATU.OVER then				--阶段已经结束
			
			table.insert(leftTab,stageId) 
		elseif statu==RADailyTaskActivityUtility.STAGESTATU.NOSTART then 		--阶段尚未开始	
			table.insert(rightTab,stageId)
		end 
    end

    self.leftNum = #leftTab
    self.rightNum = #rightTab
    self.splitW = nil
    --leftBanner
    for i,v in ipairs(leftTab) do
    	local stageId = v
    	local stageData = RADailyTaskActivityUtility:getStageDataById(stageId)
    	local pic = stageData.bannerPreview
    	local stageSprite = CCSprite:create(pic)
    	self.splitW = stageSprite:getContentSize().width
    	leftNode:addChild(stageSprite)
    	stageSprite:setAnchorPoint(0,0)
    	local posX = stageSprite:getContentSize().width*(i-1)
    	stageSprite:setPositionX(posX)
    	UIExtend.setCCSpriteGray(stageSprite,true)
    end

    --rightBanner
    for i,v in ipairs(rightTab) do
    	local stageId = v
    	local stageData = RADailyTaskActivityUtility:getStageDataById(stageId)
    	local pic = stageData.bannerPreview
    	local stageSprite = CCSprite:create(pic)
    	self.splitW = stageSprite:getContentSize().width
    	rightNode:addChild(stageSprite)
    	stageSprite:setAnchorPoint(1,0)
    	local posX = -stageSprite:getContentSize().width*(i-1)
    	stageSprite:setPositionX(posX)
    	UIExtend.setCCSpriteGray(stageSprite,true) 
    end


	UIExtend.setNodeVisible(ccbfile,"mActivityRankBtnNode",false)
    local currTime = RA_Common:getCurTime()
	if data.beginTime and currTime <data.beginTime then
		
		if curStageId==stageDatas[#stageDatas] then
			UIExtend.setNodeVisible(ccbfile,"mActivityRankBtnNode",true)
			if firstRound==1 then
				keyStr="@ActivityStageWillOverTime"
			else
				keyStr="@ActivityStageNextStartTime"
			end 
			self:setActivityCurrStageUI(bottomBgNode,data.beginTime,keyStr,true)
		else
			self:setActivityCurrStageUI(bottomBgNode,data.beginTime,"@ActivityStageWillStartTime")
		end 
	elseif data.startTime and currTime<data.startTime then
		local keyStr = "@ActivityStagePrepareTime"
		local tmpTime = data.startTime
		self:setActivityCurrStageUI(bottomBgNode,tmpTime,keyStr)
	elseif data.endTime and currTime<data.endTime then
		local keyStr = "@ActivityStageRemainTime"
		local tmpTime = data.endTime
		self:setActivityCurrStageUI(bottomBgNode,tmpTime,keyStr)
	end

end

function RADailyTaskMainCell:setActivityCurrStageUI(node,time,strKey,isEnd)
	local currStageData = RADailyTaskActivityUtility:getStageDataById(self.curStageId) 
	assert(currStageData~= nil ,"currStageData~=nil is curStageId: " .. self.curStageId)
	local currPic = currStageData.banner
	local curStageSprite = CCSprite:create(currPic)
	node:addChild(curStageSprite)
	curStageSprite:setAnchorPoint(0.5,0)


	local totalW = self.ccbRoot:getContentSize().width
	local remainW = totalW-(self.leftNum+self.rightNum)*self.splitW



	if self.leftNum*self.splitW<=totalW*0.5 then
		local w1 =totalW*0.5-self.leftNum*self.splitW
		local w2 = w1-remainW*0.5
		curStageSprite:setPositionX(-w2)
	else
		local w1 =totalW*0.5-remainW
		local w2 = w1-self.splitW*0.5
		curStageSprite:setPositionX(w2)
	end
	
	self.keyStr = strKey

	local currStageName = currStageData.eventName
	local currStageStr = _RALang(currStageName)
	if isEnd then
		currStageStr= _RALang("@ActivityOver")
	end 
	UIExtend.setCCLabelString(self.ccbfile,"mStageName",currStageStr)

	local endT = time
	self.endT = endT
	local remainT = math.max(0,Utilitys.getCurDiffTime(endT))
	local str = Utilitys.createTimeWithFormat(remainT)
	UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang(strKey,str))
	

	-- return curStageSprite

end
function RADailyTaskMainCell:onExecute()
	if self.endT then
		mFrameTime = mFrameTime + RA_Common:getFrameTime()
		if mFrameTime>1 then

			local remainT = Utilitys.getCurDiffTime(self.endT)
            remainT = math.max(0,remainT)
			if remainT>=0 then
				local str = Utilitys.createTimeWithFormat(remainT)
    			UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang(self.keyStr,str))
    			if remainT==0 then

    				--当休息时间结束时也要刷新下倒计时
    				if self.endT== self.data.startTime then
    					self.keyStr="@ActivityStageRemainTime"
    					self.endT = self.data.endTime
    					-- RADailyTaskMainPage:updateInfo()
    				end 
    				
    				--self.endT = nil
    			end
			end 
    		mFrameTime = 0 
    	
		end 
		
	end 
end

function RADailyTaskMainCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	local btnNode =UIExtend.getCCNodeFromCCB(ccbfile,"mActivityRankBtnNode")
	btnNode:setPositionX(0)
	ccbRoot:setIsScheduleUpdate(false)

	local bottomBgNode = UIExtend.getCCNodeFromCCB(ccbfile,"mBottomBGNode")
    local leftNode  = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftBGNode")
    local rightNode  = UIExtend.getCCNodeFromCCB(ccbfile,"mRightBGNode")
    bottomBgNode:removeAllChildren()
    leftNode:removeAllChildren()
    rightNode:removeAllChildren()
end

--跳转到排名界面
function RADailyTaskMainCell:onActivityRankBtn()
	-- body
	self.clickRankBtn=true
	local pageArg={}
	pageArg.activityId = self.activityId
	RARootManager.OpenPage("RADailyTaskRankPage", pageArg)
end

function RADailyTaskMainCell:onTouchBtn()

	if self.clickRankBtn then
		self.clickRankBtn=false
		return 
	end 
	local currT = RA_Common:getCurTime()
    local remainT = Utilitys.getCurDiffTime(self.endT)
    local isStart=true
	if self.data.beginTime or currT<self.data.startTime or remainT<=0 then 
		-- return 
		isStart = false
	end
	local pageArg={}
	pageArg.curStageId=self.curStageId
	pageArg.activityId = self.data.activityId
	pageArg.endT=self.endT
	pageArg.firstRound=self.data.firstRound
	pageArg.isStart=isStart
	RARootManager.OpenPage("RADailyTaskStagePage", pageArg,true)
end
-------------------------Cell End----------------------------------

---------------------------------------------------------------------

function RADailyTaskMainPage:Enter(data)


	CCLuaLog("RADailyTaskMainPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAActivityMainPage.ccbi",self)
	self.ccbfile  = ccbfile
	self:registerMessageHandler()
    self:init()
    self:updateInfo()
    
end

function RADailyTaskMainPage:init()

	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mDiamondsNode",false)
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@ActiveMails"))

	self.activitySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mActivitySV")
	
end

function RADailyTaskMainPage:updateInfo()
	self.activitySV:removeAllCell()
	local scrollview = self.activitySV
	local activitDatas = RADailyTaskActivityManager:getActivityDatas()

	--如果没有开启活动 则直接返回
	if not next(activitDatas) then
		return
	end 
	for k,v in pairs(activitDatas) do
		local activitData = v

		local cell = CCBFileCell:create()
	
		local panel = RADailyTaskMainCell:new({
				data = activitData,
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAActivityMainCell.ccbi")
		scrollview:addCell(cell)

	end
	scrollview:orderCCBFileCells(scrollview:getViewSize().width)
	
    
    
end
function RADailyTaskMainPage:registerMessageHandler()
    MessageManager.registerMessageHandler(updateMsg,OnReceiveMessage)
end

function RADailyTaskMainPage:removeMessageHandler()
    MessageManager.removeMessageHandler(updateMsg,OnReceiveMessage)  
end



function RADailyTaskMainPage:Exit()
	self.activitySV:removeAllCell()
	self:removeMessageHandler()
	self.keyStr = nil
	UIExtend.unLoadCCBFile(RADailyTaskMainPage)
	
end

function RADailyTaskMainPage:onClose()
	RARootManager.CloseCurrPage()
end

function RADailyTaskMainPage:mCommonTitleCCB_onBack()
	self:onClose()
end


--endregion
