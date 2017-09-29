-- (RAW选择玩家)任命于指定职位

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire('RARootManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAPresidentConfig = RARequire('RAPresidentConfig')
local RAStringUtil = RARequire('RAStringUtil')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local Utilitys = RARequire('Utilitys')
local RANetUtil = RARequire('RANetUtil')
local common = RARequire('common')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')

local SelectMode =
{
	None 		= 0,
	Alliance 	= 1,
	Search 		= 2
}

local pageInfo =
{
    mPageName       = 'RAPresidentGrantGiftPage',
    mIsSelectable   = false,
    mRemainCnt      = 0,
    mSelectMode     = SelectMode.None,
    mScrollView     = nil,
    mTopScrollView  = nil,
    mSVOffset       = nil,
    mViewWidth      = 640,
    mViewHeight     = 470,
    mSearchHeight   = 60,
    mEditbox        = nil,
    mSearchTxt      = '',
    mGiftId 		= nil,
    mPlayerInfo     = {},
    mMemberInfo 	= {},
    mSearchInfo		= {},
    mSelectList     = {},
    mSelectIdList   = {},
    mPlayerNameStr  = '',
    mGiftName       = ''
}
local RAPresidentGrantGiftPage = BaseFunctionPage:new(..., pageInfo)

--------------------------------------------------------------------------------------
-- region: RAMemberTitleCellHandler

local RAMemberTitleCellHandler =
{
    mLevel = 1,

    mCntInfo = {},

    mIsOpen = false,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentConferSelCellTitle.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()
	    
	    local txtMap =
	    {
	        mCellTitle 		= _RALang('@MemberLevelTitle', self.mLevel),
	        mCellTitleNum 	= (self.mCntInfo.online or 0) .. '/' .. (self.mCntInfo.total or 0)
	    }
        UIExtend.setStringForLabel(ccbfile, txtMap)

        UIExtend.setNodeRotation(ccbfile, 'mArrow', self.mIsOpen and 90 or 0)
    end,

    onTitleBtn = function(self)
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_GrantGiftTitleCell, {level = self.mLevel})
    end
}

-- endregion: RAMemberTitleCellHandler
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: RAPlayerCellHandler

local RAPlayerCellHandler =
{
    mPlayerInfo = {},

    mIsSelected = false,

    mIsSelectable = false,

    mRemainCnt = 0,

    mGrayNode = nil,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentConferSelCell2.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local isEnabled = self.mPlayerInfo.isSendGift
        UIExtend.setMenuItemEnable(ccbfile, 'mCellBtn', isEnabled)
        UIExtend.setMenuItemSelected(ccbfile, {mCellBtn = self.mIsSelected})
        UIExtend.setNodeVisible(ccbfile, 'mSelBG', self.mIsSelected)

        local isAppointed = self.mPlayerInfo.officer and self.mPlayerInfo.officer ~= 0
        local cfg = isAppointed and RAWorldConfigManager:GetOfficialPositionCfg(self.mPlayerInfo.officer) or {}

        local playerIcon = RAPlayerInfoManager.getHeadIcon(self.mPlayerInfo.icon)
        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', playerIcon)

        local frameNode = UIExtend.getCCNodeFromCCB(ccbfile, 'mCellIconNode'):getParent()
        local stateStr = ''
	    if self.mPlayerInfo.offlineTime == 0 then	
            stateStr = _RALang('@InOnline')

            if self.mGrayNode then
            	self.mGrayNode:removeFromParentAndCleanup(true)
            	self.mGrayNode = nil
            end
            frameNode:setVisible(true)
        else
            local currTime = common:getCurMilliTime()
            local lostTime = (currTime - self.mPlayerInfo.offlineTime) / 1000  --毫秒转成秒
            stateStr = _RALang('@NoInOnline', Utilitys.second2AllianceDataString(lostTime))

            if self.mGrayNode == nil then
	            -- local graySprite = GraySpriteMgr:createGrayMask(frameNode, frameNode:getContentSize())
	            -- graySprite:setPosition(frameNode:getPosition())
	            -- graySprite:setAnchorPoint(frameNode:getAnchorPoint())
	            -- frameNode:getParent():addChild(graySprite)
	            -- frameNode:setVisible(false)

	            -- self.mGrayNode = graySprite
	        end
        end

        local txtMap =
        {
            mPlayerName         = self.mPlayerInfo.playerName,
            mFightValue         = Utilitys.formatNumber(self.mPlayerInfo.power),
            mState              = stateStr,
            mConditionLabel     = ''
        }
        UIExtend.setStringForLabel(ccbfile, txtMap)

        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mJobName')
        local htmlKey = not self.mPlayerInfo.isSendGift and 'PresidentGiftReceived' or 'PresidentGiftNotReceived'
        local officialName = isAppointed and _RALang(cfg.officeName) or _RALang('@NoOfficial')
        htmlLabel:setString(RAStringUtil:getHTMLString(htmlKey, officialName))
    end,

    onCellBtn = function (self)
        if self.mIsSelected or self.mIsSelectable then
            MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_GrantGiftPlayerCell, {playerInfo = self.mPlayerInfo})
        elseif not self.mIsSelectable then
            RARootManager.ShowMsgBox('@NoMoreGiftToSend', self.mRemainCnt)
        end
    end
}

-- endregion: RAPlayerCellHandler
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: RASelectedPlayerCellHandler

local RASelectedPlayerCellHandler =
{
    mPlayerInfo = {},

    mIsSelected = false,

    mGrayNode = nil,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentConferSelCell1.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local playerIcon = RAPlayerInfoManager.getHeadIcon(self.mPlayerInfo.icon)
        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', playerIcon)
    end,

    onCellBtn = function (self)
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_GrantGiftSelectCell, {playerInfo = self.mPlayerInfo})
    end
}

-- endregion: RASelectedPlayerCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_GrantGiftTitleCell,
    MessageDef_ScrollViewCell.MSG_GrantGiftPlayerCell,
    MessageDef_ScrollViewCell.MSG_GrantGiftSelectCell,
    MessageDef_Packet.MSG_Operation_OK
}


local opcodeTB =
{
    HP_pb.GUILDMANAGER_GETMEMBERINFO_S,
    HP_pb.PRESIDENT_SEARCH_S
    --HP_pb.PRESIDENT_SEND_GIFT_S
}

local Mode2Tab =
{
	[SelectMode.Alliance] 	= 'mAllianceTabBtn',
	[SelectMode.Search]		= 'mSearchTabBtn'
}

local SearchTipTxt = _RALang('@InputToSearchPlayer')

function RAPresidentGrantGiftPage:Enter(data)
	if data.giftId == nil then
		CCLuaLog('gift id is nil')
		return
	end

    self:_resetData()
    self.mGiftId = data.giftId

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

    UIExtend.loadCCBFile('RAPresidentConferSelPage.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')
    local viewSize = self.mScrollView:getViewSize()
    self.mViewWidth, self.mViewHeight = viewSize.width, viewSize.height
    viewSize:delete()

    self.mTopScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mSelectListSV')

    local sizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mSearchSizeNode')
    local size = sizeNode:getContentSize()
    self.mSearchHeight = size.height 
    size:delete()

    self:_initTitle()

    self:_registerMessageHandlers()
    self:_registerPacketHandlers()
    self:_refreshBaseInfo()
    self:_selectTab(SelectMode.Alliance)
end

function RAPresidentGrantGiftPage:Exit()
    self:_unregisterMessageHandlers()
    self:_unregisterPacketHandlers()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    if self.mTopScrollView then
        self.mTopScrollView:removeAllCell()
    end
    self:_remoceEditbox()
    UIExtend.unLoadCCBFile(self)
    if self.mSelectMode == SelectMode.Search then
        self:_resetScrollViewSize()
    end
    self:_resetData()
end

function RAPresidentGrantGiftPage:onConferBtn()
    local playerIds, nameTb = {}, {}
    for playerId, info in pairs(self.mSelectList) do
        if info then 
            table.insert(playerIds, playerId)
            table.insert(nameTb, info.playerName)
        end
    end
    if #playerIds > 0 then
        self.mPlayerNameStr = table.concat(nameTb, ',')
        local confirmTxt = _RALang('@SendPresidentGiftConfirm', self.mPlayerNameStr, self.mGiftName)
        confirmTxt = GameMaths:stringAutoReturnForLua(confirmTxt, 20, 0)

        local giftId = self.mGiftId
        local confirmData =
        {
            labelText = confirmTxt,
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
                    RAWorldProtoHandler:sendGrantPresidentGiftReq(giftId, playerIds)
                    RARootManager.ShowWaitingPage(true)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
    end
end

function RAPresidentGrantGiftPage:onAllianceTabBtn()
	self:_selectTab(SelectMode.Alliance)
end

function RAPresidentGrantGiftPage:onSearchTabBtn()
	self:_selectTab(SelectMode.Search)
end

function RAPresidentGrantGiftPage:onSendBtn()
    if self.mSearchTxt and self.mSearchTxt ~= '' then
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendSearchPlayerReq(self.mSearchTxt)
    end
end

function RAPresidentGrantGiftPage:_refreshPage()
    self:_refreshBaseInfo()
    self:_getOptionList()
    self:_initScrollView()
end

function RAPresidentGrantGiftPage:_resetData()
    self.mScrollView = nil
    self.mTopScrollView = nil
    self.mIsSelectable = false
    self.mRemainCnt = 0
    self.mSelectMode = SelectMode.None
    self.mMemberInfo = {memList = {}, cntList = {}, openList = {}}
    self.mSearchInfo = {}
    self.mSearchTxt = ''
    self.mSelectList = {}
    self.mSelectIdList = {}
    self.mPlayerNameStr = ''
    self.mGiftName = ''
end

function RAPresidentGrantGiftPage:_setSVOffset()
    self:_unsetSVOffset()
    if self.mScrollView then
        self.mSVOffset = self.mScrollView:getContentOffset()
    end
end

function RAPresidentGrantGiftPage:_unsetSVOffset()
    if self.mSVOffset then
        self.mSVOffset:delete()
        self.mSVOffset = nil
    end
end

--初始化顶部
function RAPresidentGrantGiftPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local titleName = _RALang('@Confer')
    RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, 
        nil, RACommonTitleHelper.BgType.Blue)
end

function RAPresidentGrantGiftPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentGrantGiftPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentGrantGiftPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_ScrollViewCell.MSG_GrantGiftTitleCell then
        RAPresidentGrantGiftPage:_toggleOpenGroup(msg.level)
        return
    end

    if msgId == MessageDef_ScrollViewCell.MSG_GrantGiftPlayerCell then
        RAPresidentGrantGiftPage:_selectPlayer(msg.playerInfo)
        return
    end

    if msgId == MessageDef_ScrollViewCell.MSG_GrantGiftSelectCell then
        RAPresidentGrantGiftPage:_selectPlayer(msg.playerInfo)
        return
    end

    if msgId == MessageDef_Packet.MSG_Operation_OK then
        RAPresidentGrantGiftPage:_onSendGiftRsp()
    end
end

function RAPresidentGrantGiftPage:_toggleOpenGroup(level)
    self.mMemberInfo.openList[level] = not self.mMemberInfo.openList[level]
    self:_unsetSVOffset()
    self:_initScrollView()
end

function RAPresidentGrantGiftPage:_selectPlayer(playerInfo)
    local playerId = playerInfo.playerId
    if self.mSelectList[playerId] then
        self.mSelectList[playerId] = nil
        self.mSelectIdList = common:table_removeFromArray(self.mSelectIdList, playerId)
    else
        self.mSelectList[playerId] = playerInfo
        table.insert(self.mSelectIdList, playerId)
    end
    self:_refreshBaseInfo()
    self:_setSVOffset()
    self:_initScrollView()
end

function RAPresidentGrantGiftPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAPresidentGrantGiftPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAPresidentGrantGiftPage:_getOptionList()
	if self.mSelectMode == SelectMode.Alliance then
	   RAAllianceProtoManager:getGuildMemeberInfoReq(RAAllianceManager.selfAlliance.id)
	elseif self.mSelectMode == SelectMode.Search then
        self:onSendBtn()
	end
end

function RAPresidentGrantGiftPage:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then
        local memberInfo = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
        self:_classifyMemeberInfo(memberInfo)
        self:_initScrollView()
        return
    end

    local President_pb = RARequire('President_pb')
    if opcode == HP_pb.PRESIDENT_SEARCH_S then
        local msg = President_pb.PresidentSearchRes()
        msg:ParseFromString(buffer)
        self:_onSearchPlayerRsp(msg)
        return
    end

    -- if opcode == HP_pb.PRESIDENT_SEND_GIFT_S then
    --     local msg = President_pb.PresidentSendGiftRes()
    --     msg:ParseFromString(buffer)
    --     self:_onSendGiftRsp(msg)
    --     return
    -- end
end

function RAPresidentGrantGiftPage:_onSearchPlayerRsp(msg)
    self.mSearchInfo = {}
    for _, info in ipairs(msg.memeberInfo) do
        table.insert(self.mSearchInfo, {
            playerId    = info.playerId,
            playerName  = info.playerName,
            power       = info.power,
            icon        = info.icon,
            online      = info.online,
            offlineTime = info.offlineTime or 0,
            officer     = info.officer,
            -- 是否可以发送王战礼包
            isSendGift  = info.isSendGift
        })
    end
    self:_sortPlayer(self.mSearchInfo)
    self:_unsetSVOffset()
    self:_initScrollView()
    local found = #self.mSearchInfo > 0
    UIExtend.setNodeVisible(self.ccbfile, 'mNotFoundLabel', not found)
end

function RAPresidentGrantGiftPage:_onSendGiftRsp(msg)
    RARootManager.RemoveWaitingPage()
    --if msg.sendResult then
        local num = common:table_count(self.mSelectList)
        RAPresidentDataManager:DecreaseGiftCount(self.mGiftId, num)
        self.mSelectList = {}
        self.mSelectIdList = {}
        RARootManager.ShowMsgBox('@SendPresidentGiftSuccess', self.mPlayerNameStr, self.mGiftName)
        self:_refreshPage()
    --end
    self.mPlayerNameStr = ''
end

function RAPresidentGrantGiftPage:_classifyMemeberInfo(memberInfo)
	local memList, cntList = {}, {}

	-- 按等阶分类,统计在线人数
	for k, player in pairs(memberInfo or {}) do 
		local lv = player.authority
		if memList[lv] then
			table.insert(memList[lv], player)
		else
			memList[lv] = {player}
		end

		local cntInfo = cntList[lv] or {total = 0, online = 0}
		cntInfo.total = cntInfo.total + 1
		if player.offlineTime == 0 then
			cntInfo.online = cntInfo.online + 1
		end
		cntList[lv] = cntInfo
	end

	-- 排序
	for _, list in pairs(memList) do
        self:_sortPlayer(list)
	end

	self.mMemberInfo =
	{
		memList 	= memList,
		cntList 	= cntList,
		openList 	= self.mMemberInfo.openList or {}
	}
end

function RAPresidentGrantGiftPage:_sortPlayer(playerList)
    table.sort(playerList, function (player1, player2)
        if player1.isSendGift == true and player2.isSendGift == false then
            return true
        elseif player1.isSendGift == false and player2.isSendGift == true then
            return false
        end
        
        local isPresident_1 = RAPresidentDataManager:IsPresident(player1.playerId)
        local isPresident_2 = RAPresidentDataManager:IsPresident(player2.playerId)
        if isPresident_1 == true and isPresident_2 == false then
            return true
        elseif isPresident_1 == false and isPresident_2 == true then
            return false
        end

        if player1.offlineTime == 0 and player2.offlineTime ~= 0 then 
            return true
        elseif player1.offlineTime ~= 0 and player2.offlineTime == 0 then
            return false 
        elseif player1.power > player2.power then 
            return true 
        end 
        return false
    end)
end

function RAPresidentGrantGiftPage:_refreshBaseInfo()
    local giftCfg = RAWorldConfigManager:GetPresidentGiftCfg(self.mGiftId)
    local giftInfo = RAPresidentDataManager:GetGiftInfo(self.mGiftId) or {}
    local selectCnt, remainCnt = common:table_count(self.mSelectList), giftInfo.remainCnt or 0
    local hasSelected = selectCnt > 0
    self.mIsSelectable = selectCnt < remainCnt
    self.mRemainCnt = remainCnt
    self.mGiftName = _RALang(giftCfg.giftName)

    local txtMap =
    {
        mConferTitle       	= _RALang(giftCfg.giftName),
        mSelectedNum 		= _RALang('@PresidentSelectNum', selectCnt, remainCnt)
    }

    local visibleMap =
    {
        mConferExplain      = not hasSelected,
        mSelectListSV       = hasSelected,
        mNotFoundLabel      = false
    }

    if not hasSelected then
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mConferExplain')
        htmlLabel:setString(RAStringUtil:getHTMLString('SelectPlayerToGrantGift'))

        UIExtend.setCCControlButtonEnable(self.ccbfile, 'mConferBtn', false)
    else
        self.mTopScrollView:removeAllCell()

        local itemCell, cellHandler = nil, nil
        for _, playerId in ipairs(self.mSelectIdList) do
            local playerInfo = self.mSelectList[playerId]
            if playerInfo then
                itemCell = CCBFileCell:create()
                local cellInfo =
                {
                    mPlayerInfo = playerInfo
                }
                cellHandler = RASelectedPlayerCellHandler:new(cellInfo)
                itemCell:registerFunctionHandler(cellHandler)
                itemCell:setCCBFile(cellHandler:getCCBName())
                self.mTopScrollView:addCellBack(itemCell)
            end
        end
        self.mTopScrollView:orderCCBFileCells()

        UIExtend.setCCControlButtonEnable(self.ccbfile, 'mConferBtn', true)
    end

    UIExtend.setStringForLabel(self.ccbfile, txtMap)
    local colorKey = remainCnt > 0 and 'Enough' or 'Lack'
    local color = ccc3(unpack(RAPresidentConfig.GiftNumColor[colorKey]))
    UIExtend.setLabelTTFColor(self.ccbfile, 'mSelectedNum', color)
    color:delete()
	UIExtend.setNodesVisible(self.ccbfile, visibleMap)
end

function RAPresidentGrantGiftPage:_selectTab(mode)
	for tabMode, btnName in pairs(Mode2Tab) do
		UIExtend.setCCControlButtonEnable(self.ccbfile, btnName, tabMode ~= mode)
	end

	if self.mSelectMode ~= mode then
        self:_resetScrollViewSize()

        UIExtend.setNodeVisible(self.ccbfile, 'mSearchNode', mode == SelectMode.Search)

        if mode == SelectMode.Search then
            self:_initEditbox()
        end
        
        self.mSelectMode = mode

		self:_getOptionList()
        self:_unsetSVOffset()
		self:_initScrollView()
	end
end

function RAPresidentGrantGiftPage:_resetScrollViewSize()
    if self.mSelectMode == SelectMode.Alliance then
        self.mViewHeight = self.mViewHeight - self.mSearchHeight
    elseif self.mSelectMode == SelectMode.Search then
        self.mViewHeight = self.mViewHeight + self.mSearchHeight
    end
    local size = CCSizeMake(self.mViewWidth, self.mViewHeight)
    self.mScrollView:setViewSize(size)
    size:delete()
end

function RAPresidentGrantGiftPage:_initScrollView()
    self.mScrollView:removeAllCell()

    local itemCell, cellHandler = nil, nil

    if self.mSelectMode == SelectMode.Alliance then
        local playerId = self.mPlayerInfo.playerId

    	local Const_pb = RARequire('Const_pb')
    	for i = Const_pb.L5, Const_pb.L1, -1 do
	        itemCell = CCBFileCell:create()
	        local cellInfo =
	        {
	        	mLevel 		= i,
	        	mCntInfo 	= self.mMemberInfo.cntList[i] or {},
	        	mIsOpen 	= (self.mMemberInfo.openList or {})[i]
	    	}
	        cellHandler = RAMemberTitleCellHandler:new(cellInfo)
	        itemCell:registerFunctionHandler(cellHandler)
	        itemCell:setCCBFile(cellHandler:getCCBName())
	        self.mScrollView:addCellBack(itemCell)

	        if cellInfo.mIsOpen then
	        	for _, player in ipairs(self.mMemberInfo.memList[i] or {}) do
		            itemCell = CCBFileCell:create()
		            cellHandler = RAPlayerCellHandler:new({
		                mPlayerInfo   = player,
		                mIsSelected   = self.mSelectList[player.playerId] ~= nil,
                        mIsSelectable = self.mIsSelectable,
                        mRemainCnt    = self.mRemainCnt
		            })
		            itemCell:registerFunctionHandler(cellHandler)
		            itemCell:setCCBFile(cellHandler:getCCBName())
		                
		            self.mScrollView:addCellBack(itemCell)
	        	end
	        end
    	end
	elseif self.mSelectMode == SelectMode.Search then
        for _, player in ipairs(self.mSearchInfo or {}) do
            itemCell = CCBFileCell:create()
            cellHandler = RAPlayerCellHandler:new({
                mPlayerInfo   = player,
                mIsSelected   = self.mSelectList[player.playerId] ~= nil,
                mIsSelectable = self.mIsSelectable,
                mRemainCnt    = self.mRemainCnt
            })
            itemCell:registerFunctionHandler(cellHandler)
            itemCell:setCCBFile(cellHandler:getCCBName())
                
            self.mScrollView:addCellBack(itemCell)
        end
	end

    self.mScrollView:orderCCBFileCells(self.mViewWidth)
    if self.mSVOffset then
        self.mScrollView:setContentOffset(self.mSVOffset)
    end
end

function RAPresidentGrantGiftPage:_initEditbox()
    if self.mEditBox == nil then
        local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mInputBoxNode')
        local color = ccc3(255, 255, 255)
        self.mEditBox = UIExtend.createEditBox(self.ccbfile, 'mInputBoxSprite', inputNode, 
            self._editboxEventHandler, nil, nil, nil, 24, nil, color)
        color:delete()
        self.mEditBox:setInputMode(kEditBoxInputModeSingleLine)
        self.mEditBox:setMaxLength(15)
        self.mEditBox:setText(SearchTipTxt)
    end
end

function RAPresidentGrantGiftPage:_remoceEditbox()
    if self.mEditBox then
        self.mEditBox:removeFromParentAndCleanup(true)
        self.mEditBox = nil
    end
end

function RAPresidentGrantGiftPage._editboxEventHandler(eventType, node)
    if eventType == 'began' then
        if node:getText() == SearchTipTxt then
            node:setText('')
        end
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        if node:getText() == '' then
            node:setText(SearchTipTxt)
        end
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        RAPresidentGrantGiftPage.mSearchTxt = node:getText()
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

return RAPresidentGrantGiftPage