--TO:联盟雕像页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local GuildManager_pb = RARequire("GuildManager_pb")
local HP_pb = RARequire("HP_pb")
local RAAllianceRankingManager = RARequire("RAAllianceRankingManager")
local html_zh_cn = RARequire("html_zh_cn")
local RAStringUtil = RARequire("RAStringUtil")

local RAAllianceContributePage = BaseFunctionPage:new(...)

local TAB_TYPE = {
    DAY   = 1,
    WEEK  = 2,
    TOTAL = 3,
}

local dailyContributionPoitMax = 5000

function RAAllianceContributePage:Enter()

	self:RegisterPacketHandler(HP_pb.GUILD_GET_CONTRIBUTION_RANK_S)

	UIExtend.loadCCBFile("RAAllianceConRankPage.ccbi",self)

    --top info
    self:initTitle()

    self:initBtn()

    self:setCurrentPage(TAB_TYPE.DAY)
end

--刷新页面
function RAAllianceContributePage:refreshUI()
	-- body
    UIExtend.setStringForLabel(self.ccbfile, {mContribution = _RALang("@AllianceContribution",self.contributionRankInfo.contribution)})
    --
    local contributeExplain = RAStringUtil:fill(html_zh_cn["AllianceContributeExplain"],dailyContributionPoitMax,(self.contributionRankInfo.dailyContribution .."/".. dailyContributionPoitMax))
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mConRankExplain"):setString(contributeExplain)

    --add cell
	self:addCell()
end

function RAAllianceContributePage:initBtn()
    -- body
    self.tabArr = {} --三个分页签
    self.tabArr[TAB_TYPE.DAY] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mDailyContributionBtn')
    self.tabArr[TAB_TYPE.WEEK] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mWeeklyContributionBtn')
    self.tabArr[TAB_TYPE.TOTAL] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mMonthlyContributionBtn')

    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mInviteListSV")

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)
end

function RAAllianceContributePage:onDailyContributionBtn()
    self:setCurrentPage(TAB_TYPE.DAY)
end

function RAAllianceContributePage:onWeeklyContributionBtn()
    self:setCurrentPage(TAB_TYPE.WEEK)
end

function RAAllianceContributePage:onMonthlyContributionBtn()
    self:setCurrentPage(TAB_TYPE.TOTAL)
end

function RAAllianceContributePage:setCurrentPage(pageType)
    -- body
    self.curPageType = pageType

    for k,v in pairs(self.tabArr) do
        if pageType == k then 
            v:setEnabled(false)
        else
            v:setEnabled(true)
        end  
    end

    if pageType == TAB_TYPE.DAY then 
        self:initDayRankingPanel()
    elseif pageType == TAB_TYPE.WEEK then 
        self:initWeekDayRankingPanel()
    elseif pageType == TAB_TYPE.TOTAL then  
        self:initTotalRankingPanel()
    end 
end

--每天的贡献排行
function RAAllianceContributePage:initDayRankingPanel()
    -- body
    RAAllianceProtoManager:sendetContributionRankReq(self.curPageType)
end

--每周的贡献排行
function RAAllianceContributePage:initWeekDayRankingPanel()
    -- body
    RAAllianceProtoManager:sendetContributionRankReq(self.curPageType)
end

--总的贡献排行
function RAAllianceContributePage:initTotalRankingPanel()
    -- body
    RAAllianceProtoManager:sendetContributionRankReq(self.curPageType)
end

function RAAllianceContributePage:onReceivePacket(handler)
	local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_GET_CONTRIBUTION_RANK_S then
        local msg = GuildManager_pb.GuildGetContributionRankResp()
        msg:ParseFromString(buffer)
        self.contributionRankInfo = RAAllianceRankingManager:setContributeData(msg)

        self:refreshUI()
    end
end

-------- add cell begin --------------
local RAAllianceContributeCell = {}

function RAAllianceContributeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAAllianceContributeCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    if self.mRanking <=3 then
        UIExtend.setNodeVisible(self.ccbfile, "mRankNode"..self.mRanking, true)
    else
        UIExtend.setNodeVisible(self.ccbfile, "mRankNode4", true)     
    end

    UIExtend.setStringForLabel(self.ccbfile, {mRank = self.mRanking})

    local rankData = self.mRankData
    UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mCellName"):setString(rankData.playerName)

    UIExtend.setStringForLabel(self.ccbfile, {mContributionNum = rankData.contribution})
end

function RAAllianceContributePage:orderRankInfos(itemInfo)
    table.sort( itemInfo, function (v1,v2)
        if v1.contribution > v2.contribution then 
            return true
        elseif v1.contribution < v2.contribution then 
            return false 
        elseif v1.contributeRefreshTime < v2.contributeRefreshTime then
            return true
        end    
        return false 
    end)

end

--刷新排行榜数据
function RAAllianceContributePage:addCell()
    -- body
    local rankInfo = self.contributionRankInfo.rankInfo

    --排序
    self:orderRankInfos(rankInfo)

    self.scrollView:removeAllCell()
    if #rankInfo > 0 then
        local scrollView = self.scrollView
        for k,v in pairs(rankInfo) do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceConRankCell.ccbi")
            local panel = RAAllianceContributeCell:new({
                mRanking = k,
                mRankData = v
            })
            cell:registerFunctionHandler(panel)

            scrollView:addCell(cell)
        end
        self.scrollView:setVisible(true)
        self.mNoListLabel:setVisible(false)
        scrollView:orderCCBFileCells()
    else
        self.mNoListLabel:setVisible(true)
        self.mNoListLabel:setString(_RALang("@NoContributeData"))
        self.scrollView:removeAllCell()
        self.scrollView:setVisible(false)
    end
end

function RAAllianceContributePage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@RAAllianceContributeTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceContributePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAAllianceContributePage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceContributePage:Exit()
	self:RemovePacketHandlers()

    self.contributionRankInfo = {}

    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end

	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceContributePage")

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceContributePage