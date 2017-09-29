RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RANetUtil = RARequire("RANetUtil")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Rank_pb = RARequire("Rank_pb")
local Const_pb = RARequire("Const_pb")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARankManager = RARequire("RARankManager")


local RARankPage = BaseFunctionPage:new(...)
RARankPage.scrollView = nil
RARankPage.contentCellNode = nil
RARankPage.isInitData=false
local RARankPageHandler = {}


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
        --UIExtend.setCCControlButtonEnable(self.ccbfile, "mRewardBtn", true)
        local rankItem = self.rankInfo
        if rankItem then
			
        	local name=rankItem.playerName
        	if RARankManager.currTabIndex==RARankManager.rankTabTypeIndex.Alliance then
        		name=rankItem.allianceName
			end
        		
			if rankItem.guildTag~=nil and rankItem.guildTag~="" then
				name="("..tostring(rankItem.guildTag)..")"..name
			end	
			UIExtend.setCCLabelString(ccbfile, "mCellName", tostring(name))

			local rankValueStr = tostring(rankItem.rankInfoValue)
			if rankItem.rankType == Rank_pb.ALLIANCE_NUCLEAR_STORM_BREAK then
				rankValueStr = Utilitys.fromatTimeGap(rankItem.rankInfoValue)
			end
            UIExtend.setCCLabelString(ccbfile, "mCellRankNum", rankValueStr)
			UIExtend.setCCLabelString(ccbfile, "mSettingCellLabel", _RALang("@RankTypeName"..tostring(rankItem.rankType)))
			--CCLuaLog("RAContentCellListener:onRefreshContent() Rank:"..tostring(rankItem.rank)..",playerName:"..rankItem.playerName..",allianceName:"..tostring(rankItem.allianceName)..",rankInfoValue:"..rankItem.rankInfoValue..",icon:"..tostring(rankItem.icon)..",allianceIcon:"..rankItem.allianceIcon..",rankType:"..tostring(rankItem.rankType))
		end
    end
end

function RAContentCellListener:onAllianceLetterBtn()
    self:showRankContentDetailPage(self.rankInfo.rankType)
end

--���չ����ϸ���а�����
function RAContentCellListener:showRankContentDetailPage(typeIndex)
	RARankManager.CurrShowContentRankType=typeIndex
	RARootManager.OpenPage("RARankContentListPage")
end

function RARankPage:Enter(data)
    self.ccbfile =  UIExtend.loadCCBFile("RARankMainPage.ccbi", RARankPage)
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSettingListSV")
    self:refreshUI()
    self:registerHandler()
	self:initPanel()
	--�����������ݣ�����������������ս������
	--self:LoadRankData(RankTypeIndex.PlayerBattleRank)
end

--��ʼ���������������ݲ��ֲ�ֿ�������һЩ
function RARankPage:initPanel()
	RARankManager.currTabIndex=RARankManager.rankTabTypeIndex.Player
	self:onPersonalRankBtn()
	--��ʼ������������չ��
end

function RARankPage:refreshUI()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	if titleCCB~=nil then
		local backCallBack = function()
			--RARootManager.ClosePage("RARankPage")
            RARootManager.GotoLastPage()
			-- RARootManager.CloseCurrPage()
		end
		local titleName = _RALang("@RankTitle")
		local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RARankPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
	end
end

--��������
function RARankPage:onPersonalRankBtn()
	--UIExtend.setMenuItemSelected(self.ccbfile,{mPersonalRankBtn=true,mAllianceRankBtn = false})
	UIExtend.setMenuItemEnable(self.ccbfile,"mPersonalRankBtn",false)
	UIExtend.setMenuItemEnable(self.ccbfile,"mAllianceRankBtn",true)

	UIExtend.setNodeVisible(self.ccbfile,"mPersonalLightNode",true)
	UIExtend.setNodeVisible(self.ccbfile,"mAllianceLightNode",false)
	RARankManager.currTabIndex=RARankManager.rankTabTypeIndex.Player
	self:switchTab()
	
end

----��������
function RARankPage:onAllianceRankBtn()
	--UIExtend.setMenuItemSelected(self.ccbfile,{mPersonalRankBtn=false,mAllianceRankBtn = true})
	UIExtend.setMenuItemEnable(self.ccbfile,"mPersonalRankBtn",true)
	UIExtend.setMenuItemEnable(self.ccbfile,"mAllianceRankBtn",false)
	UIExtend.setNodeVisible(self.ccbfile,"mPersonalLightNode",false)
	UIExtend.setNodeVisible(self.ccbfile,"mAllianceLightNode",true)
	RARankManager.currTabIndex=RARankManager.rankTabTypeIndex.Alliance
	self:switchTab()
end

function RARankPage:switchTab()
	if self.isInitData==true then
		self:renderRankContent()
	else	
		self:LoadRankTopData()
	end
end

--���а����������Ⱦ
function RARankPage:renderRankContent()
	--�������ʼ��content list�����а�����
	local obj=RARankManager.getRankTopListByIndex(RARankManager.currTabIndex)
	local i=0
	if obj~=nil then
		self.scrollView:removeAllCell()
		for k, value in pairs(obj) do
			local rankItem=obj[k]
			if rankItem~=nil then
			i=1
            local listener = RAContentCellListener:new({rankInfo = rankItem, contentIndex= k})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RARankMainCell.ccbi")
            cell:registerFunctionHandler(listener)
            self.scrollView:addCell(cell)
			--CCLuaLog("RARankPage:renderRankContent() k:"..tostring(k)..",Rank:"..tostring(rankItem.rank)..",playerName:"..rankItem.playerName..",allianceName:"..tostring(rankItem.allianceName)..",rankInfoValue:"..rankItem.rankInfoValue..",icon:"..tostring(rankItem.icon)..",allianceIcon:"..rankItem.allianceIcon..",rankType:"..tostring(rankItem.rankType))
			end
		end
		self.scrollView:orderCCBFileCells()
	else
		--CCLuaLog("RARankPage:renderRankContent self.currTabIndex:"..tostring(RARankManager.currTabIndex).." is nil!")
	end
	if i==0 then
		UIExtend.setCCLabelString(self.ccbfile,"mNoRankLabel",_RALang("@NoRankLabel"))
	else
		UIExtend.setCCLabelString(self.ccbfile,"mNoRankLabel","")
	end	
end

function RARankPage:addHandler()
	RARankPageHandler[#RARankPageHandler +1] = RANetUtil:addListener(HP_pb.RANK_OPEN_PANEL_S, RARankPage)
end

function RARankPage:removeHandler()
    for k, value in pairs(RARankPageHandler) do
        if RARankPageHandler[k] then
            RANetUtil:removeListener(RARankPageHandler[k])
            RARankPageHandler[k] = nil
        end
    end
    RARankPageHandler = {}
end


--ע��ͻ�����Ϣ�ַ�
function RARankPage:registerHandler()
	RARankPage:addHandler()
end

--�Ƴ��ͻ�����Ϣ�ַ�ע��
function RARankPage:unRegiterHandler()
	RARankPage:removeHandler()
end

--��ȡ���а��ʼ���������
function RARankPage:LoadRankTopData()
    RANetUtil:sendPacket(HP_pb.RANK_OPEN_PANEL_C)
	--RARootManager.ShowWaitingPage(true)
end

--���շ���������ˢ���������
function RARankPage:onReceivePacket(handler)
    RARootManager.RemoveWaitingPage()
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
	if	pbCode == HP_pb.RANK_OPEN_PANEL_S then
		local msg = Rank_pb.HPPushTopRank()
        msg:ParseFromString(buffer)
        RARankManager.initRankTopContentData(msg)
		self.isInitData=true
		self:renderRankContent()
	end
end

--�رհ�ť
function RARankPage:onCloseBtn()
    RARootManager.GotoLastPage()
end

--�˳�ҳ��
function RARankPage:Exit(data)
	RACommonTitleHelper:RemoveCommonTitle("RARankPage")
    self.contentCellNode = nil--��ʾ���е�node
    self:unRegiterHandler()
    UIExtend.unLoadCCBFile(RARankPage)
    self.ccbfile = nil
	self.isInitData=false
	RARankManager.currTabIndex=nil
	if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
	RARankManager:resetData()
end