--联盟申请页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local Utilitys = RARequire("Utilitys")
local HP_pb = RARequire("HP_pb")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local GuildManager_pb = RARequire("GuildManager_pb")
local RAAllianceApplyInfo = RARequire("RAAllianceApplyInfo")

local RAAllianceApplicationPage = BaseFunctionPage:new(...)

local TAB_TYPE = {
		TRANSFER = 1,
		APPLICANT = 2,
		SENDAPPLICATION = 3
}

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_INVITE_C then --邀请成功
            RARootManager.ShowMsgBox("@InvitationSuccess")
            --TODO 需要刷新修改成功后的玩家数据
        elseif message.opcode == HP_pb.GUILDMANAGER_REFUSEINVITE_C then --撤回邀请成功
            RARootManager.ShowMsgBox("@WithdrawSuccess")
        elseif message.opcode == HP_pb.GUILDMANAGER_CANCELINVITE_C then --撤回邀请成功
            RARootManager.ShowMsgBox("@CancelInviteSuccess")
        elseif message.opcode == HP_pb.GUILDMANAGER_ACCEPTAPPLY_C then --同意申请
            RARootManager.ShowMsgBox("@AgreeApplicationSuccess")
        elseif message.opcode == HP_pb.GUILDMANAGER_SENDRECRUITNOTICE_C then  --发起联盟公开招募成功
            RARootManager.ShowMsgBox("@OpenAllinceRecruitSuccess")
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_INVITE_C then 
            --RARootManager.ShowMsgBox("@TransferFail"..message.messageID)
        end
    elseif message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAAllianceApplicationPage' then 
            RAAllianceApplicationPage:setEditBoxVisible(true)
        else
            RAAllianceApplicationPage:setEditBoxVisible(false)
        end 
    end 
end

function RAAllianceApplicationPage:setEditBoxVisible(visible)
    if self.searchEdibox ~= nil then 
        self.searchEdibox:setVisible(visible)
    end 
end

function RAAllianceApplicationPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RAAllianceApplicationPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

--右上角公开招募
function RAAllianceApplicationPage:mAllianceCommonCCB_onCommonLabelBtn()
    local confirmData = {}
    confirmData.labelText = _RALang("@IsOpenAllinceRecruitText",self.publicRecruitCost)
    confirmData.title = _RALang("@IsOpenAllinceRecruitTitle")
    confirmData.yesNoBtn = true
	confirmData.resultFun = function (isOk)
		if isOk then
            RAAllianceProtoManager:sendOpenAllinceRecruitReq()
        end
	end
	RARootManager.OpenPage("RAConfirmPage", confirmData)
end

function RAAllianceApplicationPage:Enter()
	-- body
	local ccbfile = UIExtend.loadCCBFile("RAAllianceApplicationPage.ccbi",self)

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)

    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')

    --self.mDiamondsNode:setVisible(false)

    self:RegisterPacketHandler(HP_pb.PLAYER_GETLOCALPLAYERINFOBYNAME_S)
    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETAPPLY_S)
    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETINVITE_S)
    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETRECOMMANDINVITE_S)

    self:registerMessage()

    self:initTopTitle()
    self:initPage()

    self:setCurrentPage(TAB_TYPE.TRANSFER)
end

function RAAllianceApplicationPage:initPage()
	self.tabArr = {} --三个分页签
	self.tabArr[TAB_TYPE.TRANSFER] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mTransferTabBtn')
	self.tabArr[TAB_TYPE.APPLICANT] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mApplicantTabBtn')
	self.tabArr[TAB_TYPE.SENDAPPLICATION] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mSendApplicationTabBtn')

	self.scrollViews = {} --2个scrollViews
	self.scrollViews[TAB_TYPE.APPLICANT] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mApplicationListSV")
	self.scrollViews[TAB_TYPE.SENDAPPLICATION] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mApplicationListSV2")

	for k,v in pairs(self.scrollViews) do
		v:setVisible(false)
	end

    --申请红点
    --联盟管理中联盟申请红点
    local RAAllianceManager = RARequire("RAAllianceManager")
    if RAAllianceManager.applyNum <=0 then 
        UIExtend.getCCNodeFromCCB(self.ccbfile,'mApplicantTipsNode'):setVisible(false) 
    else
        UIExtend.getCCNodeFromCCB(self.ccbfile,'mApplicantTipsNode'):setVisible(true)
        UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mApplicantTipsNum'):setString(RAAllianceManager.applyNum) 
    end   
end

function RAAllianceApplicationPage:onTransferTabBtn()
    RARootManager.ShowWaitingPage(true)
	self:setCurrentPage(TAB_TYPE.TRANSFER)
end

function RAAllianceApplicationPage:onApplicantTabBtn()
    RARootManager.ShowWaitingPage(true)
	self:setCurrentPage(TAB_TYPE.APPLICANT)
end

function RAAllianceApplicationPage:onSendApplicationTabBtn()
    RARootManager.ShowWaitingPage(true)
	self:setCurrentPage(TAB_TYPE.SENDAPPLICATION)
end

function RAAllianceApplicationPage:setCurrentPage(pageType)
	-- body
	self.curPageType = pageType

	for k,v in pairs(self.tabArr) do
		if pageType == k then 
			v:setEnabled(false)
            if pageType == TAB_TYPE.TRANSFER then
                for k,v in pairs(self.scrollViews) do
		            v:setVisible(false)
	            end
            else
                self.scrollViews[k]:setVisible(true)
            end
		else
			v:setEnabled(true)
            if k ~= 1 then
                self.scrollViews[k]:setVisible(false)
            end
		end  
	end

	if self.searchEdibox ~= nil then 
		self.searchEdibox:removeFromParentAndCleanup(true)
		self.searchEdibox = nil 
	end 

    if pageType ~= TAB_TYPE.TRANSFER then
        self.scrollViews[pageType]:removeAllCell()
        local scrollView = self.scrollViews[pageType]
    end
    if pageType == TAB_TYPE.TRANSFER then 
    	self:initTransferPanel()
    elseif pageType == TAB_TYPE.APPLICANT then 
    	self:initApplicantPanel()
   	elseif pageType == TAB_TYPE.SENDAPPLICATION then  
   		self:initApplicationPanel()
	end 
end

--点击搜索
function RAAllianceApplicationPage:onSearchBtn()
    local name = self.searchEdibox:getText()
    if name == "" then
        RARootManager.ShowMsgBox(_RALang("@Empty"))
        return
    end
    --self.mSearchExplain:setVisible(false)
    self.mNoListLabel:setVisible(false)
    RAAllianceProtoManager:sendGetPlayerBasicInfoReq(name)
end

--
function RAAllianceApplicationPage:initTransferPanel()

    UIExtend.setNodesVisible(self.ccbfile,{mSearchNode = true})

    self.mSearchInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mSearchInputNode')
    self.mSearchInputNode:setVisible(true)
    local searchEdibox=UIExtend.createEditBox(self.ccbfile,"mInputBG",self.mSearchInputNode,nil,ccp(5,-5))
    self.searchEdibox = searchEdibox
    local RAGameConfig = RARequire("RAGameConfig")
    self.searchEdibox:setFontColor(RAGameConfig.COLOR.BLACK)
    self.searchEdibox:setInputMode(kEditBoxInputModeSingleLine)
    self.searchEdibox:setMaxLength(15)

    --self.mSearchExplain = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mSearchExplain')
    --self.mSearchExplain:setVisible(true)
    --self.mSearchExplain:setString(_RALang("@TransferTxt"))

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(true)
    self.mNoListLabel:setString(_RALang("@NoResult"))

    --默认请求
    RAAllianceProtoManager:sendGetRecommendInvitePlayerReq(1)
end

function RAAllianceApplicationPage:initApplicantPanel()
    UIExtend.setNodesVisible(self.ccbfile,{mSearchNode = false})
    self.mNoListLabel:setVisible(false)
    RAAllianceProtoManager:sendGetGuildPlayerApplyReq()
end

function RAAllianceApplicationPage:initApplicationPanel()
    UIExtend.setNodesVisible(self.ccbfile,{mSearchNode = false})
    self.mNoListLabel:setVisible(false)
    RAAllianceProtoManager:sendGetGuildPlayerInviteReq()
end

--初始化顶部
function RAAllianceApplicationPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    UIExtend.setNodeVisible(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mLabelBtnNode',true)
    local titleName = _RALang("@AllianceApplicationTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)

    local guild_const_conf = RARequire('guild_const_conf')
    self.publicRecruitCost = guild_const_conf.publicRecruitCost.value
    local commonLabelName = _RALang("@OpenAllinceRecruitTitle",self.publicRecruitCost)
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mCommonLabel', commonLabelName)
end

function RAAllianceApplicationPage:Exit()
    self:RemovePacketHandlers()
    self:removeMessageHandler()

    for _, scrollView in pairs(self.scrollViews) do
        if scrollView then
            scrollView:removeAllCell()
        end
    end
    self.scrollViews = {}

    if self.searchEdibox ~= nil then 
        self.searchEdibox:removeFromParentAndCleanup(true)
        self.searchEdibox = nil 
    end 

	UIExtend.unLoadCCBFile(self)	
end

function RAAllianceApplicationPage:mAllianceCommonCCB_onBack()
	RARootManager.ClosePage("RAAllianceApplicationPage")
end

-- add cell begin
local RAAllianceApplicationCell = {}

function RAAllianceApplicationCell:new(o)
	-- body
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

function RAAllianceApplicationCell:refreshCells(cell,pageType)
    if cell then
        RAAllianceApplicationPage.scrollViews[pageType]:removeCell(cell)	
        RAAllianceApplicationPage.scrollViews[pageType]:orderCCBFileCells()
    end

    local index = self.mIndex
    if RAAllianceApplicationPage.curPageType == TAB_TYPE.TRANSFER then
        RAAllianceApplicationPage.playerSearchData[index] = nil
        if #RAAllianceApplicationPage.playerSearchData == 0 then
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setVisible(true) 
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setString(_RALang("@NoResult"))
        end
    elseif RAAllianceApplicationPage.curPageType == TAB_TYPE.APPLICANT then
        RAAllianceApplicationPage.playerApplyData[index] = nil
        if #RAAllianceApplicationPage.playerApplyData == 0 then
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setVisible(true) 
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setString(_RALang("@NoToApply"))
        end
    elseif RAAllianceApplicationPage.curPageType == TAB_TYPE.SENDAPPLICATION then
        RAAllianceApplicationPage.playerInviteData[index] = nil
        if #RAAllianceApplicationPage.playerInviteData == 0 then
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setVisible(true) 
            RAAllianceApplicationPage.scrollViews[pageType]:setVisible(false)
            RAAllianceApplicationPage.mNoListLabel:setString(_RALang("@NoSendResult"))
        end
    end
end

--点击邀请
function RAAllianceApplicationCell:onInviteJoinBtn()
    -- body
    RAAllianceProtoManager:sendInviteGuildReq(self.mData.playerId)

    local delayFunc = function ()
        self:refreshCells(self.mCell,TAB_TYPE.APPLICANT)
    end
    performWithDelay(RAAllianceApplicationPage.ccbfile, delayFunc, 0.05)
end

--点击撤回邀请
function RAAllianceApplicationCell:onCancelApplicationBtn()
    -- body
    RAAllianceProtoManager:sendCancelInviteReq(self.mData.playerId)

    local delayFunc = function ()
        self:refreshCells(self.mCell,TAB_TYPE.SENDAPPLICATION)
    end
    performWithDelay(RAAllianceApplicationPage.ccbfile, delayFunc, 0.05)
end

--拒绝
function RAAllianceApplicationCell:onNoBtn()
    -- body
    RAAllianceProtoManager:sendRefuseApplyReq(self.mData.playerId)

    local delayFunc = function ()
        self:refreshCells(self.mCell,TAB_TYPE.SENDAPPLICATION)
    end
    performWithDelay(RAAllianceApplicationPage.ccbfile, delayFunc, 0.05)
end

--批准
function RAAllianceApplicationCell:onYesBtn()
    -- body
    RAAllianceProtoManager:sendAcceptApplyReq(self.mData.playerId)

    local delayFunc = function ()
        self:refreshCells(self.mCell,TAB_TYPE.SENDAPPLICATION)
    end
    performWithDelay(RAAllianceApplicationPage.ccbfile, delayFunc, 0.05)
end

function RAAllianceApplicationCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile
    
    local playerInfo = self.mData

    --set name
    UIExtend.setStringForLabel(ccbfile, {mAllianceLeaderName = playerInfo.playerName})

    --set fight
    UIExtend.setStringForLabel(ccbfile, {mAllianceFightValue = playerInfo.power})

    --set vip level
    UIExtend.setStringForLabel(ccbfile, {mMemNum = tostring(playerInfo.vip)})

    --set vip level
    local languageName = RAAllianceUtility:getLanguageIdByName(playerInfo.language or "")
    UIExtend.setStringForLabel(ccbfile, {mLanguage = languageName})
     
    --set icon 
    local headIcon = RAPlayerInfoManager.getHeadIcon(playerInfo.icon)
    UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode",headIcon)

    --set button setvisible
    local curPageType = RAAllianceApplicationPage.curPageType
    if curPageType == TAB_TYPE.TRANSFER then
        UIExtend.setNodesVisible(ccbfile,{mTransferBtnNode = true})
        if playerInfo.guildName ~= "" then
            UIExtend.setNodesVisible(ccbfile,{mTransferBtnNode = false})
        end
        UIExtend.setNodesVisible(ccbfile,{mApplicationBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mCancelBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mSendApplicationBtnNode = false})
    elseif curPageType == TAB_TYPE.APPLICANT then
        UIExtend.setNodesVisible(ccbfile,{mTransferBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mApplicationBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mCancelBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mSendApplicationBtnNode = true})
    elseif curPageType == TAB_TYPE.SENDAPPLICATION then
        UIExtend.setNodesVisible(ccbfile,{mTransferBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mApplicationBtnNode = false})
        UIExtend.setNodesVisible(ccbfile,{mCancelBtnNode = true})
        UIExtend.setNodesVisible(ccbfile,{mSendApplicationBtnNode = false})
    end
end

function RAAllianceApplicationPage:addCell(data,pageType)
	-- body
    if #data ~= 0 then
        for k,v in pairs(self.scrollViews) do
            if k == pageType then
                v:setVisible(true)
            else
                v:setVisible(false)
            end
        end

        self.scrollViews[pageType]:removeAllCell()
        local scrollView = self.scrollViews[pageType]
        for k,v in pairs(data) do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceApplicationCell.ccbi")
            local panel = RAAllianceApplicationCell:new({
                mIndex = k,
                mCell = cell,
        	    mData = v
            })
            cell:registerFunctionHandler(panel)
            
            scrollView:addCell(cell)
        end
        self.mNoListLabel:setVisible(false) 
        scrollView:orderCCBFileCells()
    else
         for k,v in pairs(self.scrollViews) do
            v:setVisible(false)
         end
         self.mNoListLabel:setVisible(true) 
         if self.curPageType == TAB_TYPE.APPLICANT then
            self.mNoListLabel:setString(_RALang("@NoToApply"))
         elseif self.curPageType == TAB_TYPE.TRANSFER then
            self.mNoListLabel:setString(_RALang("@NoResult"))
         elseif self.curPageType == TAB_TYPE.SENDAPPLICATION then
            self.mNoListLabel:setString(_RALang("@NoSendResult"))
         end
    end
end


function RAAllianceApplicationPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_GETLOCALPLAYERINFOBYNAME_S then           --获得本服玩家
        local Player_pb = RARequire("Player_pb")
        local msg = Player_pb.GetPlayerBasicInfoResp()
        msg:ParseFromString(buffer)
        self.playerSearchData = {}
        for i = 1, #msg.info do
            local info = RAAllianceApplyInfo.new()
            info:initByPb(msg.info[i])
            self.playerSearchData[#self.playerSearchData + 1] = info
        end

        self.curPageType = TAB_TYPE.TRANSFER
        self:addCell(self.playerSearchData,TAB_TYPE.APPLICANT)
    elseif pbCode == HP_pb.GUILDMANAGER_GETAPPLY_S then                 --获得联盟申请信息
        local msg = GuildManager_pb.GetGuildPlayerApplyResp()
        msg:ParseFromString(buffer)
        self.playerApplyData = {}
        for i = 1, #msg.info do
            local info = RAAllianceApplyInfo.new()
            info:initByPb(msg.info[i])
            self.playerApplyData[#self.playerApplyData + 1] = info
        end
        self.curPageType = TAB_TYPE.APPLICANT
        self:addCell(self.playerApplyData,TAB_TYPE.SENDAPPLICATION)
    elseif pbCode == HP_pb.GUILDMANAGER_GETINVITE_S then                --获得联盟邀请信息
        local msg = GuildManager_pb.GetGuildPlayerInviteResp()
        msg:ParseFromString(buffer)
        self.playerInviteData = {}
        for i = 1, #msg.info do
            local info = RAAllianceApplyInfo.new()
            info:initByPb(msg.info[i])
            self.playerInviteData[#self.playerInviteData + 1] = info
        end
        self.curPageType = TAB_TYPE.SENDAPPLICATION
        self:addCell(self.playerInviteData,TAB_TYPE.SENDAPPLICATION)
    elseif pbCode == HP_pb.GUILDMANAGER_GETRECOMMANDINVITE_S then       -- 获得推荐邀请玩家
        local msg = GuildManager_pb.GetRecommendInvitePlayerResp()
        msg:ParseFromString(buffer)
        self.playerSearchData = {}
        for i = 1, #msg.info do
            local info = RAAllianceApplyInfo.new()
            info:initByPb(msg.info[i])
            self.playerSearchData[#self.playerSearchData + 1] = info
        end
        self.curPageType = TAB_TYPE.TRANSFER
        self:addCell(self.playerSearchData,TAB_TYPE.APPLICANT)
    end
    RARootManager.RemoveWaitingPage()
end

return RAAllianceApplicationPage