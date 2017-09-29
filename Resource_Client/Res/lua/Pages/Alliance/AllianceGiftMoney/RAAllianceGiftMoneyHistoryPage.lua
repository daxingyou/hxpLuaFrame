--联盟历史红包页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local HP_pb = RARequire("HP_pb")
local html_zh_cn = RARequire("html_zh_cn")
local RAStringUtil = RARequire("RAStringUtil")
local Utilitys = RARequire("Utilitys")
local common = RARequire("common")
local GuildManager_pb = RARequire('GuildManager_pb')
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")

local RAAllianceGiftMoneyHistoryPage = BaseFunctionPage:new(...)

local intervalTime = 60 -- m

local YES_OR_NO = {
    YES = 1,
    NO = 2,
}

function RAAllianceGiftMoneyHistoryPage:shareUpdateTime()
    -- body
    
end

local OnReceiveMessage = function(msg)
    if msg.messageID == MessageDef_Alliance.MSG_Alliance_RedPackage_Change then
        --RARootManager.ClosePage("RAAllianceGiftMoneyHistoryPage")
    elseif msg.messageID == MessageDef_Packet.MSG_Operation_OK then
        RAAllianceGiftMoneyHistoryPage.myRedPackageInfo.lastTime = common:getCurTime() 
        RAAllianceGiftMoneyHistoryPage.myRedPackageInfo.mIsExecute = true
    end
end
function RAAllianceGiftMoneyHistoryPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_RedPackage_Change, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceGiftMoneyHistoryPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_RedPackage_Change, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

--share
function RAAllianceGiftMoneyHistoryPage:onShareAgainBtn()
    -- body
    RAAllianceProtoManager:sendPacketShareReq(self.myRedPackageInfo.id)
end

function RAAllianceGiftMoneyHistoryPage:setExecuteData()
    -- body
    UIExtend.setControlButtonTitle(self.ccbfile, 'mShareAgainBtn', '@ShareAgain')
    UIExtend.setCCControlButtonEnable(self.ccbfile, 'mShareAgainBtn', true)

    if not self.myRedPackageInfo.lastTime then
        self.myRedPackageInfo.lastTime = intervalTime
    end

    if not self.myRedPackageInfo.mIsExecute then
        self.myRedPackageInfo.mIsExecute = false
    end
end

function RAAllianceGiftMoneyHistoryPage:setShareAgainNode()
    -- body
    --最下面分享按钮   只有自己看自己 并且 没有开启过的 才会有分享按钮
    local selfPlayerId = RAPlayerInfoManager.getPlayerId()
    if selfPlayerId == self.myRedPackageInfo.sponsorId and self.myRedPackageInfo.state == GuildManager_pb.OPEN_TRY then
        --
        UIExtend.setNodeVisible(self.ccbfile,"mNoBtnLabel",false)
        mShareAgainBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mShareAgainBtn"):setVisible(true)

        self.node = self.nodes[YES_OR_NO.YES]
        self.node:setVisible(true)

        self.scrollView = self.scrollViews[YES_OR_NO.YES]
        self.scrollView:setVisible(true)
    else
        UIExtend.setNodeVisible(self.ccbfile,"mNoBtnLabel",false)
        mShareAgainBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mShareAgainBtn"):setVisible(false)    

        self.node = self.nodes[YES_OR_NO.NO]
        self.node:setVisible(true)

        self.scrollView = self.scrollViews[YES_OR_NO.NO]
        self.scrollView:setVisible(true)
    end
end

function RAAllianceGiftMoneyHistoryPage:Enter(data)
	-- body
	UIExtend.loadCCBFile("RAAllianceGiftMoneyHistoryPage.ccbi",self)

	self.myRedPackageInfo = data.mRedPackageInfo

    if self.myRedPackageInfo.state == GuildManager_pb.OPEN_TRY then
        self:setExecuteData()
    end

	self.historyInfo = {}

    self:registerMessageHandlers()

	self:RegisterPacketHandler(HP_pb.GUILD_RP_GET_DETAIL_INFO_S)
    
    self:initScrollView()

    self:setShareAgainNode()

	--发送协议获取历史红包信息
	RAAllianceProtoManager:sendGetPacketDetailInfoRep(self.myRedPackageInfo.id)

	self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)

	self:initTopTitle()

	self:refreshPage()

end

function RAAllianceGiftMoneyHistoryPage:initScrollView()
    -- body
    self.scrollViews = {}
    self.scrollViews[YES_OR_NO.YES] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")
    self.scrollViews[YES_OR_NO.NO] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mNoBtnListSV")

    for i,v in ipairs(self.scrollViews) do
        v:setVisible(false)
    end

    self.nodes = {}
    self.nodes[YES_OR_NO.YES] = UIExtend.getCCNodeFromCCB(self.ccbfile,"mHaveBtnListNode")
    self.nodes[YES_OR_NO.NO] = UIExtend.getCCNodeFromCCB(self.ccbfile,"mNoBtnListNode")

    for i,v in ipairs(self.nodes) do
        v:setVisible(false)
    end
end

function RAAllianceGiftMoneyHistoryPage:updateTime()
    local curTime = common:getCurMilliTime()
    local diffTime = math.ceil((self.myRedPackageInfo.stageEndTime - curTime) / 1000)

    if diffTime > 0 then
        local formatTimeStr = Utilitys.createTimeWithFormat(diffTime)
        UIExtend.setStringForLabel(self.ccbfile,{mTipsLabel = _RALang("@ActivityStageRemainTime",formatTimeStr)})
    else
        RARootManager.CloseCurrPage()
    end
end

function RAAllianceGiftMoneyHistoryPage:refreshPage()
	-- body
	--set DiamondsNum
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    local surplusGoldStr = _RALang("@SurplusGold",playerInfo.raPlayerBasicInfo.gold)
    UIExtend.setStringForLabel(self.ccbfile, {mOverageDiamondsNum = surplusGoldStr})

    --
    UIExtend.setStringForLabel(self.ccbfile, {mHaveNum = self.myRedPackageInfo.totalGold})

    --
    local giftMoneyHistoryName = RAStringUtil:fill(html_zh_cn["AllianceGiftMoneyHistoryName"],self.myRedPackageInfo.sponsorName)
    if self.myRedPackageInfo.sponsorGold ~= 0 then
    	giftMoneyHistoryName = RAStringUtil:fill(html_zh_cn["AllianceGiftMoneyHistoryNameAndGold"],self.myRedPackageInfo.sponsorName,self.myRedPackageInfo.sponsorGold)
    end
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mName"):setString(giftMoneyHistoryName)

    if self.myRedPackageInfo.state == GuildManager_pb.OPEN_TRY or not self.myRedPackageInfo.hasLuckyTry then --开启记录
        UIExtend.setStringForLabel(self.ccbfile, {mContentTitle = _RALang("@ContentTitle")})
    else
        UIExtend.setStringForLabel(self.ccbfile, {mContentTitle = _RALang("@LuckyRecord")})    
    end

    local mContentNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mContentNode")
    local mTipsNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mTipsNode")
    if self.myRedPackageInfo.state == GuildManager_pb.FINISH then -- 已经结束了
    	local pos = ccp(0, 0)
    	pos.x, pos.y = mTipsNode:getPosition()
    	mContentNode:setPosition(pos.x,pos.y)
    else
        local scheduleFunc = function ()
            self:updateTime()
        end
        mContentNode:setPositionY(-280)
        schedule(self.ccbfile,scheduleFunc,0.5)   
    end	
end

--初始化顶部
function RAAllianceGiftMoneyHistoryPage:initTopTitle()
    -- body
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
    titleCCB:runAnimation("InAni")
    local mDiamondsNode = UIExtend.getCCNodeFromCCB(titleCCB,'mDiamondsNode')
    mDiamondsNode:setVisible(false)

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()  
    end
    local titleName = _RALang("@RAAllianceGiftMoneyHistoryTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceGiftMoneyHistoryPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAAllianceGiftMoneyHistoryPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_RP_GET_DETAIL_INFO_S then           --获得历史红包数据
        local msg = GuildManager_pb.GetPacketDetailInfoResp()
        msg:ParseFromString(buffer)
        
        for i = 1,#msg.partnerInfo do
        	local info = {}
        	info.playerId = msg.partnerInfo[i].playerId
        	info.playerName = msg.partnerInfo[i].playerName
        	info.isOpen = msg.partnerInfo[i].isOpen
        	info.operateTime = msg.partnerInfo[i].operateTime
        	info.luckyGold = msg.partnerInfo[i].luckyGold or 0

        	self.historyInfo[info.playerId] = info
        end

        self:addCell()
    end
end

---------------------------------RAAllianceGiftMoneyHistoryCell------------------------

local RAAllianceGiftMoneyHistoryCell = {}

function RAAllianceGiftMoneyHistoryCell:new(o)
	-- body
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

function RAAllianceGiftMoneyHistoryCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local playerInfo = self.mData
    local curTime = common:getCurMilliTime()
    local diffTime = math.ceil(playerInfo.operateTime)
    local formatTimeStr = Utilitys.timeConvertShowingTime(diffTime)
    UIExtend.setStringForLabel(ccbfile,{mTime = formatTimeStr})

	UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mName"):setString(playerInfo.playerName)
	--
    if RAAllianceGiftMoneyHistoryPage.myRedPackageInfo.state == GuildManager_pb.OPEN_TRY 
        or RAAllianceGiftMoneyHistoryPage.myRedPackageInfo.isOpen then -- 可抢阶段的
        UIExtend.setNodeVisible(ccbfile,"mGetNode",false)
        UIExtend.setNodeVisible(ccbfile,"mState",true)
        if playerInfo.isOpen then
            UIExtend.setStringForLabel(ccbfile, {mState = _RALang("@OpenSuccess")})
        else
            UIExtend.setStringForLabel(ccbfile, {mState = _RALang("@OpenFail")})
        end
    else
        UIExtend.setNodeVisible(ccbfile,"mState",false)
        UIExtend.setNodeVisible(ccbfile,"mGetNode",true)
        UIExtend.setStringForLabel(ccbfile, {mGetNum = playerInfo.luckyGold})
    end
end

---------------------------------------------------------------------------------------

function RAAllianceGiftMoneyHistoryPage:addCell()
	-- body
    local isNull = true
    for i,v in pairs(self.historyInfo) do
        if v then
            isNull = false
        end
    end
    if not isNull then
        self.scrollView:removeAllCell()
        local scrollView = self.scrollView
        for k,v in pairs(self.historyInfo) do
        --for i = 1,10 do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceGiftMoneyHistoryCell.ccbi")
            local panel = RAAllianceGiftMoneyHistoryCell:new({
                mData = v
            })
            cell:registerFunctionHandler(panel)
            
            scrollView:addCell(cell)
        end
        self.mNoListLabel:setVisible(false) 
        scrollView:orderCCBFileCells()
    else
        self.mNoListLabel:setVisible(true) 
        self.mNoListLabel:setString(_RALang("@NoHistoryRedPackage"))
    end
end

function RAAllianceGiftMoneyHistoryPage:Exit()
	self:RemovePacketHandlers()
    self:unregisterMessageHandlers()

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceGiftMoneyHistoryPage")

    self.ccbfile:stopAllActions()

    intervalTime = 60 -- m
    mFrameTime = 0

    self.historyInfo = nil
    self.myRedPackageInfo = nil

    for _, scrollVie in ipairs(self.scrollViews) do
        scrollVie:removeAllCell()
    end
    self.scrollViews = {}

	UIExtend.unLoadCCBFile(self)	
end

function RAAllianceGiftMoneyHistoryPage:Execute()
    if self.ccbfile ~= nil then
        if not self.myRedPackageInfo.mIsExecute then return end 

        UIExtend.setControlButtonTitle(self.ccbfile, "mShareAgainBtn", _RALang('@ShareAgainCD', intervalTime))
        UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mShareAgainBtn"):setEnabled(false)

        local pastTime = os.difftime(common:getCurTime(), self.myRedPackageInfo.lastTime)
        if pastTime >= intervalTime then        
            UIExtend.setControlButtonTitle(self.ccbfile, 'mShareAgainBtn', '@ShareAgain')
            UIExtend.setCCControlButtonEnable(self.ccbfile, 'mShareAgainBtn', true)
            self.myRedPackageInfo.mIsExecute = false
        else
            local lastTime = math.floor(intervalTime - pastTime)
            UIExtend.setControlButtonTitle(self.ccbfile, 'mShareAgainBtn', _RALang('@ShareAgainCD', lastTime))
            UIExtend.setCCControlButtonEnable(self.ccbfile, 'mShareAgainBtn', false)
        end
    end
end 

return RAAllianceGiftMoneyHistoryPage