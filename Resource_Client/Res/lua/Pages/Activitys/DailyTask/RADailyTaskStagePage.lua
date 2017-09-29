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
local RAGameConfig = RARequire("RAGameConfig")
local RANetUtil = RARequire("RANetUtil")
local updateMsg = MessageDef_DailyTaskStatus.MSG_DailyTask_Changed

local TAG=1000
local TWO_CIRCLE_LENGTH =30

local RADailyTaskStagePage = BaseFunctionPage:new(...)
local mFrameTime = 0

-- local OnReceiveMessage = function(message)
--     if message.messageID == updateMsg then			--阶段变更
--       RADailyTaskMainPage:updateInfo()
--     end
-- end

-------------------------Cell Begin--------------------------------

local RADailyTaskStageRenderCell ={}
function RADailyTaskStageRenderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RADailyTaskStageRenderCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageRenderCell:onRefreshContent")
	if not ccbRoot then return end

	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data=self.data
    local banner =data.banner
    UIExtend.setSpriteImage(ccbfile, {mCellPic=banner})

   

    local pic = UIExtend.getCCSpriteFromCCB(ccbfile,"mCellPic")
    UIExtend.setCCSpriteGray(pic)
    if not self.isCurr or self.over or not self.isStart then
    	UIExtend.setCCSpriteGray(pic,true)
    end 
    -- pic:removeAllChildren()
    -- local ttf =UIExtend.createLabel(self.index)
    -- ttf:setFontSize(100)
    -- pic:addChild(ttf)
    -- ttf:setPosition(200,100)
end

function RADailyTaskStageRenderCell:setPicGray(isGray)
	 local pic = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mCellPic")
	 UIExtend.setCCSpriteGray(pic,isGray)
end
local RADailyTaskStageScoreCell = {

}
function RADailyTaskStageScoreCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RADailyTaskStageScoreCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageScoreCell:onRefreshContent")
	if not ccbRoot then return end

	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data = self.data
    local stageId = data.stageId

    --当前积分
    local currScore = math.max(0,data.score)
    self.currScore = currScore
    local str = RAStringUtil:getHTMLString("DailyTaskScoreCurr", currScore)
    UIExtend.setCCLabelHTMLString(ccbfile,"mCurrentIntegral",str)

    --进度
    local cityLevel = self.cityLevel
    local tb=RADailyTaskActivityUtility:getStageScoreData(stageId,cityLevel)
    local scores=tb.score
    local rewards=tb.reward
    for i=1,#scores do
    	local score = scores[i]
    	UIExtend.setCCLabelString(ccbfile,"mBarPoint"..i,score)
    end

    for i=1,#rewards do
    	local rewardDatas = rewards[i]
    	-- local item_conf = RARequire("item_conf")
    	-- local rewardDatas = item_conf[reward]
    	-- local name = rewardDatas.item_name
    	-- local icon = rewardDatas.item_icon..".png"

    	local name = rewardDatas.item_name
    	local icon = rewardDatas.item_icon
    	local num = rewardDatas.num
    	UIExtend.setCCLabelString(ccbfile,"mItemName"..i,_RALang(name))
    	UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode"..i, icon)
    	UIExtend.setCCLabelString(ccbfile,"mItemNum"..i,num)
    end

    local maxScore = scores[#scores]*1.2
    table.insert(scores,maxScore)

    self:refreshBars(scores)
    -- local scaleX = math.min(currScore/maxScore,1)
    -- local bar = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBar")
    -- bar:setScaleX(scaleX)
end


function RADailyTaskStageScoreCell:setBarScales(tabs)
	local bar1 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar1")
	local bar2 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar2")
	local bar3 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar3")
	local bar4 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar4")

	bar1:setScaleX(tabs[1])
	bar2:setScaleX(tabs[2])
	bar3:setScaleX(tabs[3])
	bar4:setScaleX(tabs[4])
end
function RADailyTaskStageScoreCell:refreshBars(scoresTb)
	
	self:setBarScales({0,0,0,0})
	local score1 = scoresTb[1]
	local score2 = scoresTb[2]
	local score3 = scoresTb[3]
	local score4 = scoresTb[4]

	local process = 0
	local totalProcess=0
	if self.currScore<=score1 then

		process = self.currScore
		totalProcess = score1
		local x1 =  math.min(process/totalProcess,1)
		self:setBarScales({x1,0,0,0})
	elseif self.currScore<=score2 then

		process = self.currScore-score1
		totalProcess = score2-score1
		local x2 =  math.min(process/totalProcess,1)
		self:setBarScales({1,x2,0,0})
	elseif self.currScore<=score3 then

		process = self.currScore-score2
		totalProcess = score3-score2
		local x3 =  math.min(process/totalProcess,1)
		self:setBarScales({1,1,x3,0})
	elseif self.currScore<=score4 then

		process = self.currScore-score3
		totalProcess = score4-score3
		local x4 =  math.min(process/totalProcess,1)
		self:setBarScales({1,1,1,x4})
	else
		self:setBarScales({1,1,1,1})
	end 
end
local RADailyTaskStageTitleCell = {

}
function RADailyTaskStageTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskStageTitleCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageTitleCell:onRefreshContent")
	if not ccbRoot then return end
	ccbRoot:setIsScheduleUpdate(true)
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)


	UIExtend.setNodeVisible(ccbfile,"mIntegralTitleNode",self.isScore)
	UIExtend.setNodeVisible(ccbfile,"mIntegralRankTitleNode",not self.isScore)
	
  
end

local RADailyTaskStageContentCell = {

}
function RADailyTaskStageContentCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskStageContentCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageContentCell:onRefreshContent")
	if not ccbRoot then return end
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data = self.data

    local title = data.contentName
    local details = data.contentTips
    local points = data.score
    UIExtend.setCCLabelString(ccbfile,"mCellTitle",_RALang(title))
    UIExtend.setCCLabelString(ccbfile,"mCellDetails",_RALang(details))
    UIExtend.setCCLabelString(ccbfile,"mPoints",points.._RALang("@Minute"))


end

local RADailyTaskStageRankCell = {

}
function RADailyTaskStageRankCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskStageRankCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageRankCell:onRefreshContent")
	if not ccbRoot then return end

	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data =self.data

    --rank
    local selfRank = math.max(0,data.selfRank)
    local str = RAStringUtil:getHTMLString("DailyTaskRankCurr", selfRank)
    UIExtend.setCCLabelHTMLString(ccbfile,"mMyRankLabel",str)

end

function RADailyTaskStageRankCell:onRankRewardBtn( )
	-- body 跳到查看奖励页面
	local curStageId  = RADailyTaskActivityManager:getCurrStageId()
	local data = {}
	data.id =curStageId
	data.isStage = true
	RARootManager.OpenPage("RADailyTaskRewardPopUp", data,false,true,true)
	
end

local RADailyTaskStageDetailRankCell = {

}
function RADailyTaskStageDetailRankCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskStageDetailRankCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskStageDetailRankCell:onRefreshContent")
	if not ccbRoot then return end
	
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

-- message PlayerRankPB
-- {
-- 	required int32 rank         = 1;  // 排名
-- 	required string playerId    = 2;  // 玩家id
-- 	required string playerName  = 3;  // 玩家名字
-- 	required int32 playerIcon   = 4;  // 玩家头像
-- 	optional string guildTag    = 5;  // 联盟缩写
-- }

	
	local data = self.data
	local rank =data.rank
	local playerName = data.playerName
	local guildTag =nil

	if data.guildTag~="" then
		guildTag = data.guildTag
		playerName="("..guildTag..")"..playerName
	end 
	-- if data:HasField('guildTag') then
	-- 	guildTag = data.guildTag
	-- 	playerName="("..guildTag..")"..playerName
	-- end 


	--rank
	self:showRankIcon(rank)

	--icon
	local iconId = data.playerIcon
	local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
	local icon=RAPlayerInfoManager.getHeadIcon(iconId)
	UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)

	--name
	UIExtend.setCCLabelString(ccbfile,"mPlayerName",playerName)


end

function RADailyTaskStageDetailRankCell:showRankIcon(rank)
	UIExtend.setNodeVisible(self.ccbfile,"mRank1",false)
	UIExtend.setNodeVisible(self.ccbfile,"mRank2",false)
	UIExtend.setNodeVisible(self.ccbfile,"mRank3",false)
	UIExtend.setNodeVisible(self.ccbfile,"mRank",false)
	if rank==1 then
		UIExtend.setNodeVisible(self.ccbfile,"mRank1",true)
	elseif rank==2 then
		UIExtend.setNodeVisible(self.ccbfile,"mRank2",true)
	elseif rank==3 then
		UIExtend.setNodeVisible(self.ccbfile,"mRank3",true)

	else
		UIExtend.setNodeVisible(self.ccbfile,"mRank",true)
		UIExtend.setCCLabelString(self.ccbfile,"mRank",rank)
	end

end
-------------------------Cell End----------------------------------

---------------------------------------------------------------------

--添加协议监听返回处理
function RADailyTaskStagePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.ROUND_TASK_STAGE_RANK_S then  
    	local msg = Activity_pb.RoundTaskStageScoreRankPB()
        msg:ParseFromString(buffer)

        local rankScroeDatas=msg

        RADailyTaskStagePage:updateInfo(rankScroeDatas)
    end

end

function RADailyTaskStagePage:Enter(data)


	CCLuaLog("RADailyTaskStagePage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAActivityDetailsPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.curStageId = data.curStageId
	self.activityId = data.activityId
	self.endT       =data.endT
	self.firstRound =data.firstRound
	self.isStart = data.isStart
	RADailyTaskActivityManager:setCurrStageId(self.curStageId)

	self.netHandlers={}
	self:addHandler()
	self:registerMessageHandler()
    self:init()

    --先发送请求，等数据返回再刷新
    if self.isStart then
    	RADailyTaskActivityManager:sendGetActivityStageReq()
    else
    	self:updateInfo()
    end 
	
    
end

--添加协议监听
function RADailyTaskStagePage:addHandler()
	 --积分和排名数据 返回监听
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.ROUND_TASK_STAGE_RANK_S, RADailyTaskStagePage)

end

--移除协议监听
function RADailyTaskStagePage:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end 

function RADailyTaskStagePage:init()

	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mDiamondsNode",false)
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@ActiveMails"))

	self.activitySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mActivitySV")
	self:seEnableBtn(true)

end



function RADailyTaskStagePage:setStageNameAndTime(stageId,isOver)

	if isOver then
		UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageHasOver"))
		return 
	end 


	local stageData = RADailyTaskActivityUtility:getStageDataById(stageId)
	local stageName = _RALang(stageData.eventName)
	UIExtend.setCCLabelString(self.ccbfile,"mStageName",stageName)


	if not self.isStart then
		UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageNoStart"))
		return 
	end 

	local tData=RADailyTaskActivityManager:getActivityStageDatas(self.activityId,stageId)
	self.iscutDown = true

	local statu= RADailyTaskActivityUtility:getStatgeStatue(self.activityId,self.curStageId,stageId)
	if statu==RADailyTaskActivityUtility.STAGESTATU.OVER then				--阶段已经结束
		self.iscutDown=false
		UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageHasOver"))
		return 
	elseif statu==RADailyTaskActivityUtility.STAGESTATU.NOSTART then 		--阶段尚未开始	
		self.iscutDown=false
		UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageNoStart"))
		return 
	end 


	local remainT = Utilitys.getCurDiffTime(self.endT)
	local str = Utilitys.createTimeWithFormat(remainT)
	UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageRemainTime",str))
end

function RADailyTaskStagePage:Execute( )

	if self.endT and self.iscutDown and self.isStart then
		mFrameTime = mFrameTime + RA_Common:getFrameTime()
		if mFrameTime>1 then
			local remainT = Utilitys.getCurDiffTime(self.endT)
			if remainT>=0 then
				local str = Utilitys.createTimeWithFormat(remainT)
    			UIExtend.setCCLabelString(self.ccbfile,"mTime",_RALang("@ActivityStageRemainTime",str))
    			if remainT==0 then
    				if self.currPanel then
    					self.currPanel.isOver = true
    					self.currPanel:setPicGray(true)
    					self:setStageNameAndTime(self.curStageId,true)
    				end 
    			end 
    		else
    			 self.endT=nil
			end 
    		mFrameTime = 0	
		end 
		
	end 

end

function RADailyTaskStagePage:createStageRenderSV()
    local svNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mStageRenderedNode")
    local size = CCSizeMake(0, 0)
    if svNode then
        size = svNode:getContentSize()
    end
	self.renderScrollView = CCSelectedScrollView:create(size)
    self.renderScrollView:setDirection(kCCScrollViewDirectionHorizontal)
    self.renderScrollView:registerFunctionHandler(self)
    UIExtend.addNodeToParentNode(self.ccbfile, "mStageRenderedNode", self.renderScrollView)

    self:refreshRenderUI()
end

function RADailyTaskStagePage:clearCircleTab()
	 if  self.circles then
    	for key, circle in pairs(self.circles) do
        	circle:removeFromParentAndCleanup(true)
    	end
    end 
    self.circles ={}
end

function RADailyTaskStagePage:getStageIdByIndex(index)
	local stageDatas=nil
	if self.firstRound==1 then
    	stageDatas=RADailyTaskActivityUtility:getFirstStageIdsInActivity(self.activityId)
    else
    	stageDatas=RADailyTaskActivityUtility:getStageIdsInActivity(self.activityId)
    end
	return stageDatas[index]
end
function RADailyTaskStagePage:refreshRenderUI()
	if self.renderScrollView then
        self.renderScrollView:removeAllCell()
    end

    self:clearCircleTab()
    if self.circleFG and tolua.cast(self.circleFG,"CCSprite") then
        self.circleFG:removeFromParentAndCleanup(true)
        self.circleFG = nil
    end
    local stageDatas=nil
    if self.firstRound==1 then
    	 stageDatas=RADailyTaskActivityUtility:getFirstStageIdsInActivity(self.activityId)
    else
    	stageDatas=RADailyTaskActivityUtility:getStageIdsInActivity(self.activityId)
    end
    --获取圆点的起始位置
    local stageCount = #stageDatas
    local centerNode = UIExtend.getCCNodeFromCCB(self.ccbfile ,"mTipsNode")
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
    for i,v in ipairs(stageDatas) do
    	local stageId =v
    	local stageData = RADailyTaskActivityUtility:getStageDataById(stageId)
  		
  		local isCurrCell=false
    	if self.curStageId and stageId==self.curStageId then
    		isCurrCell=true
    	end 
    	local cell = CCBFileCell:create()
    	local panel = RADailyTaskStageRenderCell:new({
				data = stageData,
				isCurr=isCurrCell,
				index = i,
				isStart=self.isStart
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAActivityDetailsTopNode.ccbi")
		scrollview:addCellBack(cell)
		cell:setCellTag(i)
		cellW = cell:getContentSize().width

		--圆点底图
	    local circleBG = CCSprite:create(RAGameConfig.CirlclePic.CIRCLE_BG)
        if circleBG and centerNode then
            centerNode:addChild(circleBG)
            local pos = ccpAdd(startPos, ccp((i - 1)*TWO_CIRCLE_LENGTH, 0))
            circleBG:setPosition(pos)
            self.circles[i] = circleBG

            --选中圆点
            if stageId==self.curStageId then
            	 self.circleFG = CCSprite:create(RAGameConfig.CirlclePic.CIRCLE_FG)
            	 centerNode:addChild(self.circleFG)
            	 self.circleFG:setZOrder(TAG)
            	 self.circleFG:setPosition(pos)
            	 index = i
            	 currCell = cell
            	 self.currPanel = panel
        	end 

        end	
    end
    scrollview:orderCCBFileCells()
    scrollview:setSelectedCell(currCell, CCBFileCell.LT_Mid, 0.0, 0.2)
   

end


function RADailyTaskStagePage:getScoreAndRankByStageId(stageId)
	
	local tData=RADailyTaskActivityManager:getActivityStageDatas(self.activityId,stageId)
	-- local count = #self.rankScoreDatas
	-- for i=1,count do
	-- 	local rankScoreData = self.rankScoreDatas[i]
	-- 	local tmpStageId = rankScoreData.stageId
	-- 	if tmpStageId ==stageId then
	-- 		tData = rankScoreData
	-- 		break
	-- 	end 
	-- end
	if not tData then
		tData=RADailyTaskActivityUtility:getConfigScoreRankDatas(stageId)
	end
	return tData
end
function RADailyTaskStagePage:updateScroeAndRank(stageId,isScore)

	if isScore==nil then
		isScore = true
	end 
	self.activitySV:removeAllCell()
	local scrollview = self.activitySV

	--默认选中score
	if isScore then
		self:updateScoreData(stageId)
	else
		self:updateRankData(stageId)
	end 
	scrollview:orderCCBFileCells()
	
end

function RADailyTaskStagePage:seEnableBtn(isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mIntegralBtn",not isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mIntegralRankBtn",isEnable)
end
function RADailyTaskStagePage:updateRankData(stageId)
	local scoreRankData = self:getScoreAndRankByStageId(stageId)
	--myRank
	local myRankCell = CCBFileCell:create()
	local myRankPanel = RADailyTaskStageRankCell:new({
			data = scoreRankData,
    })
	myRankCell:registerFunctionHandler(myRankPanel)
	myRankCell:setCCBFile("RAActivityDetailsCell4.ccbi")
	self.activitySV:addCellBack(myRankCell)


	
	local playerRanks = scoreRankData.playerRank
	local count = #playerRanks
	if count>0 then
		--title
		local titleCell = CCBFileCell:create()
		local titlePanel = RADailyTaskStageTitleCell:new({
			isScore = false
				
	    })
		titleCell:registerFunctionHandler(titlePanel)
		titleCell:setCCBFile("RAActivityDetailsCell2.ccbi")
		self.activitySV:addCellBack(titleCell)

		--player rank
		for i=1,count do
			local playRank = playerRanks[i]
			local playerRankCell = CCBFileCell:create()
			local playerRankPanel = RADailyTaskStageDetailRankCell:new({
					data = playRank,
		    })
			playerRankCell:registerFunctionHandler(playerRankPanel)
			playerRankCell:setCCBFile("RAActivityDetailsCell5.ccbi")
			self.activitySV:addCellBack(playerRankCell)
		end

	end 
	
	


end

function RADailyTaskStagePage:updateScoreData(stageId)
	
	local scoreRankData = self:getScoreAndRankByStageId(stageId)
	--score

	local scoreCell = CCBFileCell:create()
	local scorePanel = RADailyTaskStageScoreCell:new({
			data = scoreRankData,
			cityLevel = self.cityLevel
    })
	scoreCell:registerFunctionHandler(scorePanel)
	scoreCell:setCCBFile("RAActivityDetailsCell1.ccbi")
	self.activitySV:addCellBack(scoreCell)


	--title

	local titleCell = CCBFileCell:create()
	local titlePanel = RADailyTaskStageTitleCell:new({
		isScore = true
			
    })
	titleCell:registerFunctionHandler(titlePanel)
	titleCell:setCCBFile("RAActivityDetailsCell2.ccbi")
	self.activitySV:addCellBack(titleCell)

	--content

	local contentDatas=RADailyTaskActivityUtility:getStageContentDatas(stageId)
	local count = #contentDatas
	for i=1,count do
		local contentData = contentDatas[i]
		local contentCell = CCBFileCell:create()
		local contentPanel = RADailyTaskStageContentCell:new({
				data = contentData,
	    })
		contentCell:registerFunctionHandler(contentPanel)
		contentCell:setCCBFile("RAActivityDetailsCell3.ccbi")
		self.activitySV:addCellBack(contentCell)
	end

end
function RADailyTaskStagePage:updateInfo(rankScoreDatas)

	if self.isStart then
		self.cityLevel = rankScoreDatas.playerLevel
		if rankScoreDatas:HasField("scoreRankList") then
			local scoreRankList = rankScoreDatas.scoreRankList
			local rankScoreDatas = scoreRankList.scoreRank
			local count = #rankScoreDatas
			for i=1,count do
				local rankScoreData = rankScoreDatas[i]
				RADailyTaskActivityManager:addActivityStageDatas(self.activityId,rankScoreData)
			end

		end
		
	else
		local RABuildManager=RARequire("RABuildManager")
		self.cityLevel=RABuildManager:getMainCityLvl()
	end 
	
	--top bannner
	self:setStageNameAndTime(self.curStageId)
	self:createStageRenderSV()

	--scroe and rank
	-- self.rankScoreDatas = rankScoreDatas.scoreRank

	local currStageId = RADailyTaskActivityManager:getCurrStageId()
	self:updateScroeAndRank(currStageId)

end

function RADailyTaskStagePage:scrollViewSelectNewItem(cell)
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
            RADailyTaskActivityManager:setCurrStageId(stageId)

            local isOver = false
            if stageId==self.curStageId and self.currPanel and self.currPanel.isOver then
            	isOver = true
       --      	self.currPanel.isOver = true
    			self.currPanel:setPicGray(true)
            end 
            self:setStageNameAndTime(stageId,isOver)

            self:seEnableBtn(true)
            --滑动时默认显示积分页签
			self:updateScroeAndRank(stageId)
			self.isScore = true
        end
    end
end

function RADailyTaskStagePage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        self.renderScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RADailyTaskStagePage:scrollViewRollBack(cell)
    if cell then
        self.renderScrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end


function RADailyTaskStagePage:registerMessageHandler()
	 -- if self.renderScrollView then
  --       self.renderScrollView:registerFunctionHandler(RADailyTaskStagePage)
  --   end
end

function RADailyTaskStagePage:removeMessageHandler()
    -- if self.renderScrollView then
    --     self.renderScrollView:unregisterFunctionHandler()
    -- end
end


--点击积分页签
function RADailyTaskStagePage:onIntegralBtn( )

	self.isShowScore=true
	self:seEnableBtn(self.isShowScore)
	local currStageId = RADailyTaskActivityManager:getCurrStageId()
	self:updateScroeAndRank(currStageId,self.isShowScore)

end

--点击排行页签
function RADailyTaskStagePage:onIntegralRankBtn()
	self.isShowScore=false
	self:seEnableBtn(self.isShowScore)
	local currStageId = RADailyTaskActivityManager:getCurrStageId()
	self:updateScroeAndRank(currStageId,self.isShowScore)
end

function RADailyTaskStagePage:Exit()
	self.activitySV:removeAllCell()
	self.renderScrollView:removeAllCell()
	self.renderScrollView:unregisterFunctionHandler()
	self:removeMessageHandler()
	self:removeHandler()
	self:clearCircleTab()
	RADailyTaskActivityManager:clearSingleaActivityStatus(self.activityId)

	self.circles=nil
	self.currPanel = nil
	UIExtend.unLoadCCBFile(RADailyTaskStagePage)
	
end

function RADailyTaskStagePage:onClose()
	RARootManager.CloseCurrPage()
end

function RADailyTaskStagePage:mCommonTitleCCB_onBack()
	self:onClose()
end

--endregion
