RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARankManager = RARequire("RARankManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RANetUtil = RARequire("RANetUtil")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local RAAllianceManager=RARequire("RAAllianceManager")

local RARankContentListPage = BaseFunctionPage:new(...)
RARankContentListPage.scrollView = nil
RARankContentListPage.noSelfRankScrollView = nil
RARankContentListPage.contentCellNode = nil
local RARankDetailPageHandler = {}
---------------------------scroll content cell---------------------------
local RAContentCellListener = {
contentIndex = 1,
rankInfo = nil
}
function RAContentCellListener:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function RAContentCellListener:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile = ccbfile
	if ccbfile then
		UIExtend.handleCCBNode(ccbfile)
		local rankItem = self.rankInfo
		if rankItem then
			UIExtend.setCCLabelString(ccbfile, "mCellRankNum", tostring(rankItem.rank))
			local rankValueStr = tostring(rankItem.rankInfoValue)
			if rankItem.rankType == Rank_pb.ALLIANCE_NUCLEAR_STORM_BREAK then
				rankValueStr = Utilitys.fromatTimeGap(rankItem.rankInfoValue)
			end
			UIExtend.setCCLabelString(ccbfile, "mCellFightValue", rankValueStr)
			
			local isPlayerGroup=RARankManager.rankGroupIsPlayer()
			local allianceName=rankItem.allianceName
			if rankItem.guildTag~="" and rankItem.guildTag~=nil then
				allianceName="("..tostring(rankItem.guildTag)..")"..allianceName
			end	
			if isPlayerGroup then
				UIExtend.setCCLabelString(ccbfile, "mCellName1", tostring(rankItem.playerName))
				UIExtend.setCCLabelString(ccbfile, "mCellName2",allianceName)
			else

				UIExtend.setCCLabelString(ccbfile, "mCellName1",allianceName)
				UIExtend.setCCLabelString(ccbfile, "mCellName2", tostring(rankItem.playerName))
			end
				
			UIExtend.setNodeVisible(ccbfile, "mCellPersonalNode",isPlayerGroup)
			UIExtend.setNodeVisible(ccbfile, "mCellAllianceNode",not isPlayerGroup)
			
			if rankItem.icon~=nil then
				local iconStr = RAPlayerInfoManager.getHeadIcon(rankItem.icon)
				--UIExtend.addSpriteToNodeParent(self:getRootNode(), "mHeadPortaitNode", iconStr)
				UIExtend.addSpriteToNodeParent(ccbfile, "mCellPersonalIconNode",tostring(iconStr))
			end
			
			if rankItem.allianceIcon~=nil then
				local iconStr = RAAllianceUtility:getAllianceFlagIdByIcon(rankItem.allianceIcon)
				UIExtend.addSpriteToNodeParent(ccbfile, "mCellAllianceIconNode",tostring(iconStr))
			end
		end
	end
end
---------------------------scroll content cell---------------------------


function RARankContentListPage:Enter(data)
	
	self.ccbfile =  UIExtend.loadCCBFileWithOutPool("RARankDetailsPage.ccbi", RARankContentListPage)
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSettingListSV")
	self.noSelfRankScrollView=UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mNoMeListSV")
	self:initTopRankPanel()
	self:refreshUI()
	self:registerHandler()
	self:LoadRankContentPanel()
end

function RARankContentListPage:initTopRankPanel()
	
	if RankTopPanel==nil then
		RARankManager.RankTopPanel={}
		--top1
		local top1Item={}
		top1Item.playerName="mFirstName1"
		top1Item.allianceName="mFirstName2"
		top1Item.rankInfoValue="mFirstFightValue"
		top1Item.playerNode="mPersonalFirstNode"
		top1Item.allianceNode="mAllianceFirstNode"
		top1Item.icon="mPersonalFirstIconNode"
		top1Item.allianceIcon="mAllianceFirstIconNode"
		table.insert(RARankManager.RankTopPanel,top1Item)
		
		--top2
		local top2Item={}
		top2Item.playerName="mSecondName1"
		top2Item.allianceName="mSecondName2"
		top2Item.rankInfoValue="mSecondFightValue"
		top2Item.playerNode="mPersonalSecondNode"
		top2Item.allianceNode="mAllianceSecondNode"
		top2Item.icon="mPersonalSecondIconNode"
		top2Item.allianceIcon="mAllianceSecondIconNode"
		table.insert(RARankManager.RankTopPanel,top2Item)
		
		--top3
		local top3Item={}
		top3Item.playerName="mThirdName1"
		top3Item.allianceName="mThirdName2"
		top3Item.rankInfoValue="mThirdFightValue"
		top3Item.playerNode="mPersonalThirdNode"
		top3Item.allianceNode="mAllianceThirdNode"
		top3Item.icon="mPersonalThirdIconNode"
		top3Item.allianceIcon="mAllianceThirdIconNode"
		table.insert(RARankManager.RankTopPanel,top3Item)
		
	end
end
--temp
function RARankContentListPage:refreshUI()
	-- body
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	if titleCCB~=nil then
		local backCallBack = function()
			RARootManager.ClosePage("RARankContentListPage")
		end
		local titleName = _RALang( _RALang("@RankTypeName"..tostring(RARankManager.CurrShowContentRankType)))
		local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RARankContentListPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
	end
end



function RARankContentListPage:renderPanel()
	self:initSelfRankPanel()
	self:initContentRankList()
end

function RARankContentListPage:LoadRankContentPanel()
	local currIndex=RARankManager.CurrShowContentRankType
	local obj=RARankManager.getRankListByIndex(currIndex)
	if obj~=nil then
		self:renderPanel()
	else
		self:LoadRankContentData(currIndex)
	end
end

--0、初始化自身的排行榜数据
function RARankContentListPage:initSelfRankPanel()
	--初始化自身的排行榜数据
	
	local rankDataItem=RARankManager.getMyRank(RARankManager.CurrShowContentRankType)

	local allianceName=rankDataItem.allianceName
	if rankDataItem.guildTag~=nil and rankDataItem.guildTag~="" then
		allianceName="("..tostring(rankDataItem.guildTag)..")"..allianceName
	end	

	local iconStr = RAPlayerInfoManager.getHeadIcon()
	UIExtend.addSpriteToNodeParent(self.ccbfile,"mMyPersonalIconNode",tostring(iconStr))
	
	if RARankManager.rankGroupIsPlayer() then
		UIExtend.setNodeVisible(self.ccbfile,"mMyDetailsNode",true)
		UIExtend.setCCLabelString(self.ccbfile,"mMyName1", tostring(rankDataItem.playerName))
		UIExtend.setCCLabelString(self.ccbfile,"mMyName2", tostring(allianceName))
	else

		if RAAllianceManager.selfAlliance==nil then
			UIExtend.setNodeVisible(self.ccbfile,"mMyDetailsNode",false)
		else
			if rankDataItem.allianceIcon~=nil then
				iconStr = RAAllianceUtility:getAllianceFlagIdByIcon(rankDataItem.allianceIcon)
				UIExtend.addSpriteToNodeParent(self.ccbfile,"mMyAllianceIconNode",tostring(iconStr))
			end

			UIExtend.setCCLabelString(self.ccbfile,"mMyName2", tostring(rankDataItem.guildLeaderName))
			UIExtend.setCCLabelString(self.ccbfile,"mMyName1", tostring(rankDataItem.allianceName))
		end	
	
	end
	local rankValueStr = tostring(rankDataItem.rankInfoValue)
	if rankDataItem.rankType == Rank_pb.ALLIANCE_NUCLEAR_STORM_BREAK then
		rankValueStr = Utilitys.fromatTimeGap(rankDataItem.rankInfoValue)
	end
	UIExtend.setCCLabelString(self.ccbfile,"mMyFightValue", rankValueStr)
	local rankStr=rankDataItem.rank
	local const_conf = RARequire('const_conf')
	local maxRank = const_conf['clearRankData'].value
	if rankDataItem.rank==0 or rankDataItem.rank > maxRank then
		--rankStr=_RALang("@NoRank")
		rankStr = maxRank..'+'
	end	
	UIExtend.setCCLabelString(self.ccbfile,"mRankNum", tostring(rankStr))
	UIExtend.setNodeVisible(self.ccbfile,"mMyPersonalNode",RARankManager.rankGroupIsPlayer())
	UIExtend.setNodeVisible(self.ccbfile,"mMyAllianceNode",not RARankManager.rankGroupIsPlayer())
				
end

--1、初始化top 3排行数据
function RARankContentListPage:initTopRankInfo(rank,rankDataItem)
	--在这里初始化top3的排行榜数据
	--在这里初始化content list的排行榜数据

	local rankPanelItem=RARankManager.RankTopPanel[rank]
	
	if rankDataItem==nil then
		rankDataItem={}
		rankDataItem.rank="-"
		rankDataItem.playerName="-"
		rankDataItem.allianceName="-"
		rankDataItem.rankInfoValue="-"
		rankDataItem.icon=""
		rankDataItem.allianceIcon=""
	end
	
	if rankPanelItem~=nil then
		local allianceName=rankDataItem.allianceName
		if rankDataItem.guildTag~="" and rankDataItem.guildTag~=nil  then
			allianceName="("..tostring(rankDataItem.guildTag)..")"..allianceName
		end	
		if RARankManager.rankGroupIsPlayer() then
			UIExtend.setCCLabelString(self.ccbfile,rankPanelItem.playerName, tostring(rankDataItem.playerName))
			UIExtend.setCCLabelString(self.ccbfile,rankPanelItem.allianceName, tostring(allianceName))
		else
			UIExtend.setCCLabelString(self.ccbfile,rankPanelItem.playerName, tostring(allianceName))
			UIExtend.setCCLabelString(self.ccbfile,rankPanelItem.allianceName, tostring(rankDataItem.playerName))
		end	

		local rankValueStr = tostring(rankDataItem.rankInfoValue)
		if rankDataItem.rankType == Rank_pb.ALLIANCE_NUCLEAR_STORM_BREAK then
			rankValueStr = Utilitys.fromatTimeGap(rankDataItem.rankInfoValue)
		end
		UIExtend.setCCLabelString(self.ccbfile,rankPanelItem.rankInfoValue, rankValueStr)
		
		UIExtend.setNodeVisible(self.ccbfile,rankPanelItem.playerNode,RARankManager.rankGroupIsPlayer())
		UIExtend.setNodeVisible(self.ccbfile,rankPanelItem.allianceNode,not RARankManager.rankGroupIsPlayer())
		
		if rankDataItem.icon~=nil then
			local iconStr = RAPlayerInfoManager.getHeadIcon(rankDataItem.icon)
			UIExtend.addSpriteToNodeParent(self.ccbfile,rankPanelItem.icon,tostring(iconStr))
		end
		
		if rankDataItem.allianceIcon~=nil then
			iconStr = RAAllianceUtility:getAllianceFlagIdByIcon(rankDataItem.allianceIcon)
			UIExtend.addSpriteToNodeParent(self.ccbfile,rankPanelItem.allianceIcon,tostring(iconStr))
		end
	end
end

--2、初始化content scroll list
function RARankContentListPage:initContentRankList()
	--在这里初始化content list的排行榜数据
	local obj=RARankManager.getRankListByIndex(RARankManager.CurrShowContentRankType)
	local renderTopRank={}
	local sv=self.scrollView

	if RAAllianceManager.selfAlliance==nil then
		sv=self.noSelfRankScrollView
	end	
	if obj~=nil then
		sv:removeAllCell()
		for k, value in pairs(obj) do
			local rankItem=obj[k]
			if rankItem~=nil then
				if k<=3 then
					table.insert(renderTopRank,k,k)
					self:initTopRankInfo(k,rankItem)
				else	
					local listener = RAContentCellListener:new({rankInfo = rankItem, contentIndex= k})
					local cell = CCBFileCell:create()
					cell:setCCBFile("RARankDetailsCell.ccbi")
					cell:registerFunctionHandler(listener)
					sv:addCell(cell)
				end				
			end
		end
		sv:orderCCBFileCells()
	else
	end
	
	for i=1,3,1 do
		rank=renderTopRank[i]
		if rank==nil then
			self:initTopRankInfo(i,nil)
		end	
	end
end

function RARankContentListPage:addHandler()
	RARankDetailPageHandler[#RARankDetailPageHandler +1] = RANetUtil:addListener(HP_pb.RANK_INFO_S, RARankContentListPage)
end

function RARankContentListPage:removeHandler()
	for k, value in pairs(RARankDetailPageHandler) do
		if RARankDetailPageHandler[k] then
			RANetUtil:removeListener(RARankDetailPageHandler[k])
			RARankDetailPageHandler[k] = nil
		end
	end
	RARankDetailPageHandler = {}
end

--注册客户端消息分发
function RARankContentListPage:registerHandler()
	RARankContentListPage:addHandler()
end

--移除客户端消息分发注册
function RARankContentListPage:unRegiterHandler()
	RARankContentListPage:removeHandler()
end

--请求排行数据，设置等待窗口
function RARankContentListPage:LoadRankContentData(reqType)
	local msg = Rank_pb.HPSendRank()
	msg.rankType=tonumber(reqType)
	RANetUtil:sendPacket(HP_pb.RANK_INFO_C, msg)
	--RARootManager.ShowWaitingPage(true)
end

--接收服务器包，刷新排行面板
function RARankContentListPage:onReceivePacket(handler)
	RARootManager.RemoveWaitingPage()
	local pbCode = handler:getOpcode()
	local buffer = handler:getBuffer()
	if pbCode == HP_pb.RANK_INFO_S then
		local msg = Rank_pb.HPPushRank()
		msg:ParseFromString(buffer)
		RARankManager.initRankContentData(msg)
		self:renderPanel()
	end
end

--关闭按钮
function RARankContentListPage:onCloseBtn()
	RARootManager.ClosePage("RARankContentListPage")
end

--退出页面
function RARankContentListPage:Exit(data)
	RACommonTitleHelper:RemoveCommonTitle("RARankContentListPage")
	self:unRegiterHandler()
	self.contentCellNode = nil--显示排行的node
	if self.scrollView then
		self.scrollView:removeAllCell()
		self.scrollView = nil
	end
	if self.noSelfRankScrollView then
		self.noSelfRankScrollView:removeAllCell()
		self.noSelfRankScrollView = nil
	end
	UIExtend.unLoadCCBFile(RARankContentListPage)
	self.ccbfile = nil
end