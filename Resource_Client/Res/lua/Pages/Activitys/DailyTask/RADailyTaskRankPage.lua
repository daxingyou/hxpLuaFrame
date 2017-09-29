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



local RADailyTaskRankPage = BaseFunctionPage:new(...)



-------------------------Cell Begin--------------------------------

local RADailyTaskRankPageCell = {

}
function RADailyTaskRankPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskRankPageCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskRankPageCell:onRefreshContent")
	if not ccbRoot then return end
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data = self.data

    local playerName = data.playerName
	local guildTag =nil
	if data.guildTag and data.guildTag~="" then
		guildTag = data.guildTag
		playerName="("..guildTag..")"..playerName
	end 

	UIExtend.setCCLabelString(ccbfile,"mPlayerName",playerName)

	local rank = data.rank
	UIExtend.setCCLabelString(ccbfile,"mRankLabel",rank)	

	local score = data.score
	score=Utilitys.formatNumber(score)
	UIExtend.setCCLabelString(ccbfile,"mIntegralLabel",score)	

end


-------------------------Cell End----------------------------------

---------------------------------------------------------------------

function RADailyTaskRankPage:Enter(data)


	CCLuaLog("RADailyTaskRankPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAActivityRankPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.activityId = data.activityId
    self:init()
    self:updateInfo()
    
end

function RADailyTaskRankPage:init()

	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mDiamondsNode",false)
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@ActiveMails"))

	self.activitySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mActivitySV")
	
end

function RADailyTaskRankPage:updateTopRank()
	
	local playerRanks =self.activityData.playerRank

	--top rank
	UIExtend.setNodeVisible(self.ccbfile,"mFirstName1",true)
	UIExtend.setNodeVisible(self.ccbfile,"mSecondName1",true)
	UIExtend.setNodeVisible(self.ccbfile,"mThirdName1",true)
	UIExtend.setNodeVisible(self.ccbfile,"mFirstName2",true)
	UIExtend.setNodeVisible(self.ccbfile,"mSecondName2",true)
	UIExtend.setNodeVisible(self.ccbfile,"mThirdName2",true)
	-- UIExtend.setCCLabelString(self.ccbfile,"mFirstName1",_RALang("@PlayerNickName"))
	-- UIExtend.setCCLabelString(self.ccbfile,"mSecondName1",_RALang("@PlayerNickName"))
	-- UIExtend.setCCLabelString(self.ccbfile,"mThirdName1",_RALang("@PlayerNickName"))

-- message PlayerRankPB
-- {
-- 	required int32 rank         = 1;  // 排名
-- 	optional int32 score        = 2;  // 积分
-- 	required string playerId    = 3;  // 玩家id
-- 	required string playerName  = 4;  // 玩家名字
-- 	required int32 playerIcon   = 5;  // 玩家头像
-- 	optional string guildTag    = 6;  // 联盟缩写
-- }

	for i=1,3 do
		local playerRank=playerRanks[i]
		if playerRank then
			local playerName=playerRank.playerName
			local guildTag = nil
			if playerRank.guildTag and playerRank.guildTag~="" then
				guildTag = playerRank.guildTag
				playerName="("..guildTag..")"..playerName
			end 

			local score = playerRank.score
			
			local playerIconId = playerRank.playerIcon
			local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
			local icon=RAPlayerInfoManager.getHeadIcon(playerIconId)
			
	    	local rankStr=""
	    	local iconStr=""
	    	if i==1 then
	    		rankStr ="mFirstName1"
	    		scoreStr="mFirstName2"
	    		iconStr="mFirstIconNode"
	    	elseif i==2 then
	    		rankStr="mSecondName1"
	    		scoreStr="mSecondName2"
	    		iconStr="mPersonalSecondIconNode"
	    	elseif i==3 then
	    		rankStr="mThirdName1"
	    		scoreStr="mThirdName2"
	    		iconStr="mPersonalThirdIconNode"
	    	end
	    	UIExtend.setCCLabelString(self.ccbfile,scoreStr,_RALang("@Integral").." "..score)
	    	UIExtend.setCCLabelString(self.ccbfile,rankStr,playerName)
	    	UIExtend.addSpriteToNodeParent(self.ccbfile, iconStr, icon)
	    else
	    	if i==1 then
	    		UIExtend.setNodeVisible(self.ccbfile,"mFirstName2",false)
	    		UIExtend.setNodeVisible(self.ccbfile,"mFirstName1",false)
	    	elseif i==2 then
	    		UIExtend.setNodeVisible(self.ccbfile,"mSecondName2",false)
	    		UIExtend.setNodeVisible(self.ccbfile,"mSecondName1",false)
	    	elseif i==3 then
	    		UIExtend.setNodeVisible(self.ccbfile,"mThirdName2",false)
	    		UIExtend.setNodeVisible(self.ccbfile,"mThirdName1",false)	
	    	end 

		end
		
	end



end
function RADailyTaskRankPage:updateInfo()
	self.activitySV:removeAllCell()
	local scrollview = self.activitySV


	--activtiy name
	local configData =  RADailyTaskActivityUtility:getActivityConfigData(self.activityId)
	local name = configData.eventName
	UIExtend.setCCLabelString(self.ccbfile,"mActivityName",_RALang(name))

	local activityData=RADailyTaskActivityManager:getActivityDatasById(self.activityId)
	self.activityData = activityData
	local myRoundRank = activityData.roundRank
	
	if myRoundRank and myRoundRank~="" then		
	    local str = RAStringUtil:getHTMLString("DailyTaskMyRank", myRoundRank)
	    UIExtend.setCCLabelHTMLString(self.ccbfile,"mMyRankLabel",str)
	else
		local str = RAStringUtil:getHTMLString("NoJoinActivityTips")
		UIExtend.setCCLabelHTMLString(self.ccbfile,"mMyRankLabel",str)
		
	end
	local rankDatas=activityData.playerRank
	if #rankDatas==0 then 
		local isShow=false
		UIExtend.setNodeVisible(self.ccbfile,"mFirstName1",isShow)
		UIExtend.setNodeVisible(self.ccbfile,"mSecondName1",isShow)
		UIExtend.setNodeVisible(self.ccbfile,"mThirdName1",isShow)
		UIExtend.setNodeVisible(self.ccbfile,"mFirstName2",isShow)
		UIExtend.setNodeVisible(self.ccbfile,"mSecondName2",isShow)
		UIExtend.setNodeVisible(self.ccbfile,"mThirdName2",isShow)
		return 
	end
	self:updateTopRank()

	local count = #rankDatas
	for i=4,count do
		local rankData = rankDatas[i]

		local rankCell = CCBFileCell:create()
		local rankPanel = RADailyTaskRankPageCell:new({
				data = rankData
	    })
		rankCell:registerFunctionHandler(rankPanel)
		rankCell:setCCBFile("RAActivityRankCell.ccbi")
		self.activitySV:addCellBack(rankCell)

	end


	scrollview:orderCCBFileCells(scrollview:getViewSize().width)
	
    
    
end

function RADailyTaskRankPage:onRankRewardBtn()

	local data = {}
	data.id =self.activityId
	RARootManager.OpenPage("RADailyTaskRewardPopUp", data,false,true,true)
end

function RADailyTaskRankPage:Exit()
	-- self.activitySV:removeAllCell()
	UIExtend.unLoadCCBFile(RADailyTaskRankPage)
	
end

function RADailyTaskRankPage:onClose()
	RARootManager.CloseCurrPage()
end

function RADailyTaskRankPage:mCommonTitleCCB_onBack()
	self:onClose()
end


--endregion
