--联盟加入页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceJoinPage = BaseFunctionPage:new(...)
local RAAllianceManager = RARequire('RAAllianceManager')
local RANetUtil = RARequire("RANetUtil")
local GuildManager_pb = RARequire('GuildManager_pb')
local HP_pb = RARequire('HP_pb')
local RAAllianceInfo = RARequire('RAAllianceInfo')
local RAGameConfig = RARequire('RAGameConfig')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceUtility = RARequire('RAAllianceUtility')
RARequire("MessageManager")

local TAB_TYPE = {
   	JOIN = 1,
   	CREATE = 2,
   	INVITE = 3
}

function RAAllianceJoinPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceJoinPage.ccbi", RAAllianceJoinPage)

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)
    self.mSearchNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mSearchNode')
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.mWarTypeNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mWarTypeNode')
    self.mWarTypeNode:setVisible(false)

    self.mWarType = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mWarType')
    self.mTypeExplain = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeExplain')
    self.mTypeExplain:setString(_RALang('@AllianceTypeExplain1'))

    self.mTypeLabel1 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel1')
    self.mTypeLabel2 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel2')
    self.mTypeLabel3 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel3')

    self.mTypeLabel1:setString(_RALang('@AllianceTypeDeveloping'))
    self.mTypeLabel2:setString(_RALang('@AllianceTypeStrategic'))
    self.mTypeLabel3:setString(_RALang('@AllianceTypeFighting'))

    self.mWarTypePageNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mWarTypePageNode')


    self.searchType = GuildManager_pb.STRATEGIC --默认是平衡型
    self.curPageType = nil 
    self.netHandlers = {}
    self.inviteNum = 0
    self.recommendArr = nil 

    self:initTitle()
    self:initPage()
    self:addHandler()
    self:registerMessage()
    self:getRecommendGuildListReq()

    if RAAllianceManager.selfAlliance == nil and RAAllianceManager.joinedGuild == false then 
    	if RAAllianceManager.isShowJoinPage == false then 
    		RARootManager.OpenPage("RAAllianceJoinPopUpPage",nil,false, true, true)
    		RAAllianceManager.isShowJoinPage = true

    	end 
    end 

    --邀请的红点 --mInviteTipsNum
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mInviteTipsNode'):setVisible(false)
end

function RAAllianceJoinPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_CREATE_S, RAAllianceJoinPage) --创建联盟
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_RECOMMEND_S, RAAllianceJoinPage) --推荐联盟
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETPLAYERAPPLY_S, RAAllianceJoinPage) --推荐联盟
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_SEARCH_S, RAAllianceJoinPage) --搜索联盟
	self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETPLAYERINVITE_S, RAAllianceJoinPage) --邀请联盟
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_BEACCEPT_SYNC_S, RAAllianceJoinPage)  --申请加入联盟,同意后的回调
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	if message.opcode == HP_pb.GUILDMANAGER_APPLY_C then 
    		-- RARootManager.ClosePage("RAAllianceJoinPage")
    		-- RARootManager.CloseAllPages()

    		if RAAllianceManager.selfAlliance ~= nil then 
    			RARootManager.CloseAllPages()
    			RARootManager.OpenPage('RAAllianceMainPage')

                RARootManager.ShowMsgBox(_RALang('@AllianceJoinSuccess')) 
    		else
    			-- RARootManager.ShowMsgBox(_RALang('@AllianceApplicationSucess'))

    			if RAAllianceJoinPage.curPageType == TAB_TYPE.JOIN then 
    				RAAllianceJoinPage:getApplyGuildListReq()
    			end 
    		end
    	elseif message.opcode == HP_pb.GUILDMANAGER_CANCELAPPLY_C then 
    		-- RARootManager.ShowMsgBox(_RALang('@AllianceCancelApplySucess'))

    		if RAAllianceJoinPage.curPageType == TAB_TYPE.JOIN then 
    			RAAllianceJoinPage:getApplyGuildListReq()
    		end 
    	elseif message.opcode == HP_pb.GUILDMANAGER_REFUSEINVITE_C then
    		RARootManager.ShowMsgBox(_RALang('@AllianceRefuseinviteSucess'))
    		RAAllianceProtoManager:getPlayerGuildInviteInfoReq()

            RAAllianceJoinPage.inviteNum = RAAllianceJoinPage.inviteNum - 1
            RAAllianceJoinPage:refreshInviteNum()
    	elseif message.opcode == HP_pb.GUILDMANAGER_ACCEPTINVITE_C then
    		RARootManager.ShowMsgBox(_RALang('@AllianceBeInvitedSucess'))
    		RARootManager.CloseAllPages()
    		RARootManager.OpenPage('RAAllianceMainPage')
    	end 
    elseif message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAAllianceJoinPage' then 
            RAAllianceJoinPage:setEditBoxVisible(true)
        else
            RAAllianceJoinPage:setEditBoxVisible(false)
        end
    elseif message.messageID == MessageDef_Alliance.MSG_Alliance_Jion_Success then  
        RARootManager.CloseAllPages() 
        RARootManager.OpenPage("RAAllianceMainPage")   
    end 
end

function RAAllianceJoinPage:setEditBoxVisible(visible)
    if self.searchEdibox ~= nil then 
        self.searchEdibox:setVisible(visible)
    end 
end

function RAAllianceJoinPage:registerMessage()
	MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_Jion_Success,OnReceiveMessage)
end

function RAAllianceJoinPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_Jion_Success,OnReceiveMessage)
end

function RAAllianceJoinPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_CREATE_S then --创建联盟
        local msg = GuildManager_pb.CreateGuildResp()
        msg:ParseFromString(buffer)

        local info = RAAllianceInfo.new()
        info:initByPb(msg.info)
        RAAllianceManager.selfAlliance = info
        RAAllianceManager.authority = 5
        RARootManager.OpenPage('RAAllianceCreatePopUpPage',nil,false,true,true)
    elseif pbCode == HP_pb.GUILDMANAGER_RECOMMEND_S then --推荐联盟
    	local msg = GuildManager_pb.GetRecommendGuildListResp()
        msg:ParseFromString(buffer)

        local recommendArr = {}
        for i=1,#msg.info do
        	local info = RAAllianceInfo.new()
        	info:initByPb(msg.info[i])
        	recommendArr[i] = info
        end

        self.recommendArr = recommendArr
        RAAllianceManager.recommendArr = recommendArr
        self.inviteNum = msg.newInviteCnt
        self:getApplyGuildListReq()
        -- self:setCurrentPage(TAB_TYPE.JOIN)
    elseif pbCode == HP_pb.GUILDMANAGER_SEARCH_S then 
    	local searchArr = RAAllianceProtoManager:searchAllianceResp(buffer)
    	self:refreshSearch(searchArr)
    elseif pbCode == HP_pb.GUILDMANAGER_GETPLAYERAPPLY_S then
    	local applyArr = RAAllianceProtoManager:applyAllianceResp(buffer)
    	-- CCLuaLog('get apply')
    	self.applyArr = applyArr
    	self:setCurrentPage(TAB_TYPE.JOIN)
    elseif pbCode == HP_pb.GUILDMANAGER_GETPLAYERINVITE_S then 
    	local inviteArr = RAAllianceProtoManager:getPlayerGuildInviteInfo(buffer)
    	self.inviteArr = inviteArr
    	self:refreshInvitePanel()
    elseif pbCode == HP_pb.GUILD_BEACCEPT_SYNC_S then
        RARootManager.CloseAllPages() 
        RARootManager.OpenPage("RAAllianceMainPage")      
    end
end

function RAAllianceJoinPage:refreshSearch(searchArr)
	self.scrollViews[TAB_TYPE.JOIN]:removeAllCell()
	if searchArr == nil or #searchArr == 0 then --没推荐的列表
		self.mNoListLabel:setVisible(true)
		self.mNoListLabel:setString(_RALang('@HaveNoSearchList'))
	else
		local RAAllianceRecommondCell = RARequire('RAAllianceRecommondCell')
		self.mNoListLabel:setVisible(false)
		local scrollView = self.scrollViews[TAB_TYPE.JOIN]
		for i=1,#searchArr do

	        local cell = CCBFileCell:create()
	        local ccbiStr = "RAAllianceJoinCell.ccbi"
	        cell:setCCBFile(ccbiStr)
	        local panel = RAAllianceRecommondCell:new()
	        panel.cellType = 0
	        panel.info = searchArr[i]
	        cell:registerFunctionHandler(panel)
	        scrollView:addCell(cell)
	    end

	    scrollView:orderCCBFileCells()
	end 
end

function RAAllianceJoinPage:initPage()
	self.tabArr = {} --三个分页签
	self.tabArr[TAB_TYPE.JOIN] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mJoinTabBtn')
	self.tabArr[TAB_TYPE.CREATE] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mCreateTabBtn')
	self.tabArr[TAB_TYPE.INVITE] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mInviteTabBtn')

	self.scrollViews = {} --三个scrollViews
	self.scrollViews[TAB_TYPE.JOIN] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mJoinListSV")
	self.scrollViews[TAB_TYPE.CREATE] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mCreeateListSV")
    self.scrollViews[TAB_TYPE.CREATE]:setBounceable(false)
	self.scrollViews[TAB_TYPE.INVITE] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mInviteListSV")

	for k,v in pairs(self.scrollViews) do
		v:setVisible(false)
	end

	-- self:setCurrentPage(TAB_TYPE.JOIN)
end

function RAAllianceJoinPage:onInviteTabBtn()
	self:setCurrentPage(TAB_TYPE.INVITE)
end

function RAAllianceJoinPage:onCreateTabBtn()
	self:setCurrentPage(TAB_TYPE.CREATE)
end

function RAAllianceJoinPage:onJoinTabBtn()
	-- self:setCurrentPage(TAB_TYPE.JOIN)
	self:getApplyGuildListReq()
end

--设置当前Page
function RAAllianceJoinPage:setCurrentPage(pageType)
    self.curPageType = pageType
	for k,v in pairs(self.tabArr) do
		if pageType == k then 
			v:setEnabled(false)
			self.scrollViews[k]:setVisible(true)
		else
			v:setEnabled(true)
			self.scrollViews[k]:setVisible(false)
		end  
	end

    self.mWarTypePageNode:setVisible(false)

	if self.searchEdibox ~= nil then 
		self.searchEdibox:removeFromParentAndCleanup(true)
		self.searchEdibox = nil 
	end 

	if pageType == TAB_TYPE.JOIN then 
		self.mSearchNode:setVisible(true)
        self.mWarTypeNode:setVisible(true)
	else 
		self.mSearchNode:setVisible(false)
        self.mWarTypeNode:setVisible(false)
	end 

    --local scrollView = self.scrollViews[pageType]
    for k,v in pairs(self.scrollViews) do
        v:removeAllCell()
    end

    if pageType == TAB_TYPE.CREATE then 
    	self:initCreatePanel()
    elseif pageType == TAB_TYPE.JOIN then 
    	self:initJoinPanel()
   	elseif pageType == TAB_TYPE.INVITE then  
   		-- self:initInvitePanel()
   		RAAllianceProtoManager:getPlayerGuildInviteInfoReq()
	end 
end

function RAAllianceJoinPage:refreshInvitePanel()

	self.scrollViews[TAB_TYPE.INVITE]:removeAllCell()
	if self.inviteArr == nil or #self.inviteArr == 0 then --没推荐的列表
		self.mNoListLabel:setVisible(true)
		self.mNoListLabel:setString(_RALang('@HaveNoInviteList'))
	else
		local RAAllianceRecommondCell = RARequire('RAAllianceRecommondCell')
		self.mNoListLabel:setVisible(false)
		local scrollView = self.scrollViews[TAB_TYPE.INVITE]
		for i=1,#self.inviteArr do

	        local cell = CCBFileCell:create()
	        local ccbiStr = "RAAllianceJoinCell.ccbi"
	        cell:setCCBFile(ccbiStr)
	        local panel = RAAllianceRecommondCell:new()
	        panel.cellType = 1
	        panel.info = self.inviteArr[i]
	        cell:registerFunctionHandler(panel)
	        scrollView:addCell(cell)
	    end

	    scrollView:orderCCBFileCells()
	end 
end

function RAAllianceJoinPage:updateSearchTypePanel(searchType)
    -- local text = ''

    -- if self.searchType == GuildManager_pb.STRATEGIC then
    --     text = _RALang('@AllianceTypeStrategic') --平衡型
    -- elseif self.searchType == GuildManager_pb.DEVELOPING then 
    --     text = _RALang('@AllianceTypeDeveloping') -- 发展形
    -- elseif self.searchType == GuildManager_pb.FIGHTING then 
    --     text = _RALang('@AllianceTypeFighting')
    -- else 
    --     text = _RALang('@AllianceTypeAll')
    -- end 

    self.mWarType:setString(RAAllianceUtility:getAllianceTypeName(searchType))
end

function RAAllianceJoinPage:setSelectType(selectType)
    self.selectType = selectType

    for i=1,3 do
        if self.selectType == i then 
            UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, 'mTypeHighLight' .. i):setVisible(true)
            UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mTypeBtn' .. i):setEnabled(false)
        else
            UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, 'mTypeHighLight' .. i):setVisible(false)
            UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mTypeBtn' .. i):setEnabled(true)
        end 
    end

    self.mTypeExplain:setString(_RALang('@AllianceTypeExplain' .. selectType)) 
end

function RAAllianceJoinPage:onTypeBtn1()
    RAAllianceJoinPage:setSelectType(GuildManager_pb.DEVELOPING)
end

function RAAllianceJoinPage:onTypeBtn2()
    RAAllianceJoinPage:setSelectType(GuildManager_pb.STRATEGIC)
end

function RAAllianceJoinPage:onTypeBtn3()
    RAAllianceJoinPage:setSelectType(GuildManager_pb.FIGHTING)
end


--查看全部
function RAAllianceJoinPage:onCheckAllBtn()
    CCLuaLog('RAAllianceJoinPage:onCheckAllBtn')
    self.searchType = nil 
    -- self:updateSearchTypePanel(self.searchType)
    self:setTypePageNodeVisible(false)
    self:refreshList()
end

function RAAllianceJoinPage:onConfirmChooseBtn()
    CCLuaLog('RAAllianceJoinPage:onConfirmChooseBtn')
    self.searchType = self.selectType
    -- self:updateSearchTypePanel(self.searchType)
    self:setTypePageNodeVisible(false)
    self:refreshList(self.searchType)
end

function RAAllianceJoinPage:setTypePageNodeVisible(isVisible)
    self.mWarTypeNode:setVisible(not isVisible)
    self.mWarTypePageNode:setVisible(isVisible)
    self.scrollViews[TAB_TYPE.JOIN]:setVisible(not isVisible)
end

function RAAllianceJoinPage:onChangeType()
    self:setTypePageNodeVisible(true)

    self:setSelectType(self.searchType or 0)
end

function RAAllianceJoinPage:refreshList(orderType)
    self:updateSearchTypePanel(orderType)

    self.displayArr = {}
    self.orderArr = {}
    self.resetArr = {}
    for k,v in pairs(self.applyArr) do
        v.isApply = true
        self.displayArr[#self.displayArr+1] =v
    end

    for k,v in pairs(self.recommendArr) do
        local isApply = false 
        for k1,v1 in pairs(self.applyArr) do
            if v1.id == v.id then 
                isApply = true 
                break
            end 
        end

        if isApply == false then
            if v.guildType == orderType then 
                self.orderArr[#self.orderArr+1] = v
            else 
                self.resetArr[#self.resetArr+1] = v
            end  
            -- self.displayArr[#self.displayArr+1] = v
            v.isApply = false 
        end 
    end

    for k,v in pairs(self.orderArr) do
        self.displayArr[#self.displayArr+1] = v
    end

    for k,v in pairs(self.resetArr) do
        self.displayArr[#self.displayArr+1] = v
    end

    if self.displayArr == nil or #self.displayArr == 0 then --没推荐的列表
        self.mNoListLabel:setVisible(true)
        self.mNoListLabel:setString(_RALang('@HaveNoRecommondList'))
    else
        local RAAllianceRecommondCell = RARequire('RAAllianceRecommondCell')
        self.mNoListLabel:setVisible(false)
        local scrollView = self.scrollViews[self.curPageType]
        scrollView:removeAllCell()
        for i=1,#self.displayArr do

            local cell = CCBFileCell:create()
            local ccbiStr = "RAAllianceJoinCell.ccbi"
            cell:setCCBFile(ccbiStr)
            local panel = RAAllianceRecommondCell:new()
            panel.cellType = 0
            panel.info = self.displayArr[i]
            cell:registerFunctionHandler(panel)
            scrollView:addCell(cell)
        end

        scrollView:orderCCBFileCells()
    end 
end

function RAAllianceJoinPage:initJoinPanel()

	self.mSearchInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mSearchInputNode')
    local searchEdibox=UIExtend.createEditBox(self.ccbfile,"mInputBG",self.mSearchInputNode,nil,nil)
    self.searchEdibox = searchEdibox
    self.searchEdibox:setInputMode(kEditBoxInputModeSingleLine)
    self.searchEdibox:setMaxLength(15)
    self.searchEdibox:setFontColor(RAGameConfig.COLOR.WHITE)  

    self:refreshList(self.searchType)

    -- self:updateSearchTypePanel(self.searchType)

 --    self.displayArr = {}
 --    for k,v in pairs(self.applyArr) do
 --    	v.isApply = true
 --    	self.displayArr[#self.displayArr+1] =v
 --    end

 --    for k,v in pairs(self.recommendArr) do
 --    	local isApply = false 
 --    	for k1,v1 in pairs(self.applyArr) do
 --    		if v1.id == v.id then 
 --    			isApply = true 
 --    			break
 --    		end 
 --    	end

 --    	if isApply == false then 
 --    		self.displayArr[#self.displayArr+1] = v
 --    		v.isApply = false 
 --    	end 
 --    end

	-- if self.displayArr == nil or #self.displayArr == 0 then --没推荐的列表
	-- 	self.mNoListLabel:setVisible(true)
	-- 	self.mNoListLabel:setString(_RALang('@HaveNoRecommondList'))
	-- else
	-- 	local RAAllianceRecommondCell = RARequire('RAAllianceRecommondCell')
	-- 	self.mNoListLabel:setVisible(false)
	-- 	local scrollView = self.scrollViews[self.curPageType]
	-- 	for i=1,#self.displayArr do

	--         local cell = CCBFileCell:create()
	--         local ccbiStr = "RAAllianceJoinCell.ccbi"
	--         cell:setCCBFile(ccbiStr)
	--         local panel = RAAllianceRecommondCell:new()
	--         panel.cellType = 0
	--         panel.info = self.displayArr[i]
	--         cell:registerFunctionHandler(panel)
	--         scrollView:addCell(cell)
	--     end

	--     scrollView:orderCCBFileCells()
	-- end 

    --邀请的红点 --mInviteTipsNum
    -- if self.inviteNum > 0 then
    --     UIExtend.getCCNodeFromCCB(self.ccbfile,'mInviteTipsNode'):setVisible(true)
    --     UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mInviteTipsNum'):setString(self.inviteNum)
    -- end

    self:refreshInviteNum()
end

function RAAllianceJoinPage:refreshInviteNum()
    --邀请的红点 --mInviteTipsNum
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mInviteTipsNode'):setVisible(false)
    --邀请的红点 --mInviteTipsNum
    if self.inviteNum > 0 then
        UIExtend.getCCNodeFromCCB(self.ccbfile,'mInviteTipsNode'):setVisible(true)
        UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mInviteTipsNum'):setString(self.inviteNum)
    end
end

function RAAllianceJoinPage:onSearchBtn()
	-- CCLuaLog('搜索')
    if self.searchEdibox then
        self.mWarTypeNode:setVisible(true)
        self.mWarTypePageNode:setVisible(false)
        self.scrollViews[TAB_TYPE.JOIN]:setVisible(true)
        RAAllianceProtoManager:getSearchGuildListReq(self.searchEdibox:getText())
    end
end

function RAAllianceJoinPage:getRecommendGuildListReq()
	local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
	RAAllianceProtoManager:getRecommendGuildListReq(1)
end

function RAAllianceJoinPage:getApplyGuildListReq()
	local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
	RAAllianceProtoManager:getApplyAlliancesReg()
end

function RAAllianceJoinPage:initCreatePanel()
	self.mNoListLabel:setVisible(false)
	local scrollView = self.scrollViews[self.curPageType]
	local cell = CCBFileCell:create()
	local ccbiStr = "RAAllianceJoinCreateCell.ccbi"
	cell:setCCBFile(ccbiStr)

	local RAAllianceCreateCell = RARequire('RAAllianceCreateCell')
	local panel = RAAllianceCreateCell:new()
	cell:registerFunctionHandler(panel)


	scrollView:addCell(cell)
	scrollView:orderCCBFileCells()
end

--初始化顶部
function RAAllianceJoinPage:initTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@Alliance")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end


--移除
function RAAllianceJoinPage:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end

function RAAllianceJoinPage:Exit()
	-- self:removeMessageHandler()
	self:removeHandler()
	self:removeMessageHandler()

    for _, scrollView in pairs(self.scrollViews) do
        if scrollView then
            scrollView:removeAllCell()
        end
    end
    self.scrollViews = {}

	if self.searchEdibox ~= nil then 
		self.searchEdibox:removeFromParentAndCleanup(false)
		self.searchEdibox = nil 
	end 
	UIExtend.unLoadCCBFile(RAAllianceJoinPage)	
end

function RAAllianceJoinPage:mAllianceCommonCCB_onBack()
	RARootManager.ClosePage("RAAllianceJoinPage")
	-- RARootManager.ClosePage("RAMailMainPage")
end

return RAAllianceJoinPage