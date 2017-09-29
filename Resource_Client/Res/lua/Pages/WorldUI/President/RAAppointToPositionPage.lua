-- (选择玩家)任命于指定职位

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
local world_map_const_conf = RARequire("world_map_const_conf")

local SelectMode =
{
	None 		= 0,
	Alliance 	= 1,
	Search 		= 2
}

local pageInfo =
{
    mPageName       = 'RAAppointToPositionPage',
    mIsPresident    = false,
    mSelectMode     = SelectMode.None,
    mScrollView     = nil,
    mSVOffset       = nil,
    mViewWidth      = 640,
    mViewHeight     = 470,
    mSearchHeight   = 60,
    mEditbox        = nil,
    mSearchTxt      = '',
    mOfficeId 		= nil,
    mPlayerInfo     = {},
    mMemberInfo 	= {},
    mSearchInfo		= {}
}
local RAAppointToPositionPage = BaseFunctionPage:new(..., pageInfo)

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
        return 'RAPresidentApptCellTitle1.ccbi'
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
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_AppointTitleCell, {level = self.mLevel})
    end
}

-- endregion: RAMemberTitleCellHandler
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: RAPlayerCellHandler

local stepCityLevel1 = world_map_const_conf['stepCityLevel1'].value

local RAPlayerCellHandler =
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
        return 'RAPresidentApptCell1.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local isPresident = RAPresidentDataManager:IsPresident(self.mPlayerInfo.playerId)
        local isLevelEnough = self.mPlayerInfo.buildingLevel >= stepCityLevel1
        local isEnabled = not isPresident and isLevelEnough

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
            mJobName    = isAppointed and _RALang(cfg.officeName or '') or _RALang('@NoOfficial'),
            mPlayerName = self.mPlayerInfo.playerName,
            mFightValue = Utilitys.formatNumber(self.mPlayerInfo.power),
            mState 		= stateStr
        }
        if not isLevelEnough then
            txtMap['mConditionLabel'] = _RALang('@CastleLevelLessThan', stepCityLevel1)
        end
        UIExtend.setStringForLabel(ccbfile, txtMap)

        UIExtend.setNodeVisible(ccbfile, 'mInadequateConditionNode', not isLevelEnough)
    end,

    onCellBtn = function (self)
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_AppointPlayerCell, {playerInfo = self.mPlayerInfo})
    end
}

-- endregion: RAPlayerCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_AppointTitleCell,
    MessageDef_ScrollViewCell.MSG_AppointPlayerCell,
    MessageDef_World.MSG_OfficialInfo_Update
}


local opcodeTB =
{
    HP_pb.GUILDMANAGER_GETMEMBERINFO_S,
    HP_pb.PRESIDENT_SEARCH_S
}

local Mode2Tab =
{
	[SelectMode.Alliance] 	= 'mAllianceTabBtn',
	[SelectMode.Search]		= 'mSearchTabBtn'
}

local WelfareType = RAPresidentConfig.WelfareType
local SearchTipTxt = _RALang('@InputToSearchPlayer')

function RAAppointToPositionPage:Enter(data)
	if data.officeId == nil then
		CCLuaLog('office id is nil')
		return
	end

    self:_resetData()
    self.mOfficeId = data.officeId

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    self.mIsPresident = RAPlayerInfoManager.IsPresident()

    UIExtend.loadCCBFile('RAPresidentApptPage1.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')
    local viewSize = self.mScrollView:getViewSize()
    self.mViewWidth, self.mViewHeight = viewSize.width, viewSize.height
    viewSize:delete()

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

function RAAppointToPositionPage:Exit()
    self:_unregisterMessageHandlers()
    self:_unregisterPacketHandlers()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    self:_remoceEditbox()
    UIExtend.unLoadCCBFile(self)
    if self.mSelectMode == SelectMode.Search then
        self:_resetScrollViewSize()
    end
    self:_resetData()
end

function RAAppointToPositionPage:onSelectDetailsBtn()
    local playerId = self.mPlayerInfo.playerId
    if playerId and self.mOfficeId then
        local confirmTxt = ''

        local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
        local officeName = _RALang(officeCfg.officeName)
        local officialInfo = RAPresidentDataManager:GetOfficialInfo(self.mOfficeId) or {}

        local playerName = self.mPlayerInfo.playerName
        local playerOfficialInfo = RAPresidentDataManager:GetOfficialInfoByPlayerId(playerId) or {}
        local playerOfficialCfg = RAWorldConfigManager:GetOfficialPositionCfg(playerOfficialInfo.officeId or 0)

        local key = ''
        if playerOfficialCfg.id then
            -- 当前玩家已有官职
            local playerOfficialName = _RALang(playerOfficialCfg.officeName)
            if officialInfo.playerId and officialInfo.playerId ~= '' then
                -- 当前官职已有玩家
                key = '@ChangeAndReplaceJobConfirm'
                confirmTxt = _RALang(key, playerName, playerOfficialName, officialInfo.playerName, officeName)
            else
                -- 当前官职无玩家
                key = '@ChangeJobConfirm'
                confirmTxt = _RALang(key, playerName, playerOfficialName, officeName)
            end
        else
            -- 当前玩家无官职
            if officialInfo.playerId and officialInfo.playerId ~= '' then
                -- 当前官职已有玩家
                key = '@ReplaceJobConfirm'
                confirmTxt = _RALang(key, playerName, officialInfo.playerName, officeName)
            else
                -- 当前官职无玩家
                key = '@AppointJobConfirm'
                confirmTxt = _RALang(key, playerName, officeName)
            end
        end

        local officeId = self.mOfficeId
        local confirmData =
        {
            labelText = confirmTxt,
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
                    RAWorldProtoHandler:sendAppointOfficialReq(playerId, officeId)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
    end
end

function RAAppointToPositionPage:onAllianceTabBtn()
	self:_selectTab(SelectMode.Alliance)
end

function RAAppointToPositionPage:onSearchTabBtn()
	self:_selectTab(SelectMode.Search)
end

function RAAppointToPositionPage:onSendBtn()
    if self.mSearchTxt and self.mSearchTxt ~= '' then
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendSearchPlayerReq(self.mSearchTxt)
    end
end

function RAAppointToPositionPage:_refreshPage()
    self:_refreshBaseInfo()
    self:_initScrollView()
end

function RAAppointToPositionPage:_resetData()
    self.mScrollView = nil
    self.mIsPresident = false
    self.mSelectMode = SelectMode.None
    self.mMemberInfo = {memList = {}, cntList = {}, openList = {}}
    self.mPlayerInfo = {}
    self.mSearchInfo = {}
    self.mSearchTxt = ''
end

function RAAppointToPositionPage:_setSVOffset()
    self:_unsetSVOffset()
    if self.mScrollView then
        self.mSVOffset = self.mScrollView:getContentOffset()
    end
end

function RAAppointToPositionPage:_unsetSVOffset()
    if self.mSVOffset then
        self.mSVOffset:delete()
        self.mSVOffset = nil
    end
end

--初始化顶部
function RAAppointToPositionPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local titleName = _RALang('@Appointment')
    RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, 
        nil, RACommonTitleHelper.BgType.Blue)
end

function RAAppointToPositionPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAppointToPositionPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAppointToPositionPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_ScrollViewCell.MSG_AppointTitleCell then
        RAAppointToPositionPage:_toggleOpenGroup(msg.level)
        return
    end

    if msgId == MessageDef_ScrollViewCell.MSG_AppointPlayerCell then
        RAAppointToPositionPage:_selectPlayer(msg.playerInfo)
        return
    end

    if msgId == MessageDef_World.MSG_OfficialInfo_Update then
        RAAppointToPositionPage:_onAppointRsp()
        return
    end
end

function RAAppointToPositionPage:_onAppointRsp()
    local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
    local officeName = _RALang(officeCfg.officeName)
    RARootManager.ShowMsgBox('@AppointSuccess', self.mPlayerInfo.playerName, officeName)
    RARootManager.ClosePage(self.mPageName)
end

function RAAppointToPositionPage:_toggleOpenGroup(level)
    self.mMemberInfo.openList[level] = not self.mMemberInfo.openList[level]
    self:_unsetSVOffset()
    self:_initScrollView()
end

function RAAppointToPositionPage:_selectPlayer(playerInfo)
    if self.mPlayerInfo.playerId == playerInfo.playerId then
        self.mPlayerInfo = {}
    else
        self.mPlayerInfo = playerInfo
    end
    self:_refreshBaseInfo()
    self:_setSVOffset()
    self:_initScrollView()
end

function RAAppointToPositionPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAppointToPositionPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAAppointToPositionPage:_getOptionList()
	if self.mSelectMode == SelectMode.Alliance then
	   RAAllianceProtoManager:getGuildMemeberInfoReq(RAAllianceManager.selfAlliance.id)
	elseif self.mSelectMode == SelectMode.Search then

	end
end

function RAAppointToPositionPage:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then
        local memberInfo = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
        self:_classifyMemeberInfo(memberInfo)
        self:_initScrollView()
        return
    end

    if opcode == HP_pb.PRESIDENT_SEARCH_S then
        local President_pb = RARequire('President_pb')
        local msg = President_pb.PresidentSearchRes()
        msg:ParseFromString(buffer)
        self:_onSearchPlayerRsp(msg)
        return
    end
end

function RAAppointToPositionPage:_onSearchPlayerRsp(msg)
    self.mSearchInfo = {}
    for _, info in ipairs(msg.memeberInfo) do
        table.insert(self.mSearchInfo, {
            playerId        = info.playerId,
            playerName      = info.playerName,
            power           = info.power,
            icon            = info.icon,
            online          = info.online,
            offlineTime     = info.offlineTime or 0,
            officer         = info.officer,
            isSendGift      = info.isSendGift,
            buildingLevel   = info.buildingLevel
        })
    end
    self:_unsetSVOffset()
    self:_initScrollView()
    local found = #self.mSearchInfo > 0
    UIExtend.setNodeVisible(self.ccbfile, 'mNotFoundLabel', not found)
end

function RAAppointToPositionPage:_classifyMemeberInfo(memberInfo)
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
		table.sort(list, function (player1, player2)
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

	self.mMemberInfo =
	{
		memList 	= memList,
		cntList 	= cntList,
		openList 	= self.mMemberInfo.openList or {}
	}
end

function RAAppointToPositionPage:_refreshBaseInfo()
	local selectedPlayer = self.mPlayerInfo
    local hasSelected = selectedPlayer.playerId ~= nil

	local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
	local officeName = _RALang(officeCfg.officeName)

	local visibleMap =
	{
		mNoneNode 			= not hasSelected,
		mSelectDetailsNode 	= hasSelected,
        mNotFoundLabel      = false
	}

	if not hasSelected then
	    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mSelectMemApptLabel')
	    htmlLabel:setString(RAStringUtil:getHTMLString('SelectPlayerToAppointTip', officeName))

	    UIExtend.setCCControlButtonEnable(self.ccbfile, 'mApptBtn', false)
	else
		local isOnLine = self.mPlayerInfo.online
        local stateStr = ''
        if isOnLine then
            stateStr = _RALang('@InOnline')
        else
            local currTime = common:getCurMilliTime()
            local lostTime = (currTime - self.mPlayerInfo.offlineTime) / 1000  --毫秒转成秒
            stateStr = _RALang('@NoInOnline', Utilitys.second2AllianceDataString(lostTime))
        end
		
	    local txtMap =
	    {
	        mPlayerName       	= selectedPlayer.playerName,
	        mBeforeJobs 		= '',
	        mAfterJobs 			= officeName,
	        mMemState 			= stateStr
	    }

	    local btnTitleMap =
	    {
            mSelectDetailsBtn = _RALang('@Appointment')
	    }

	    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mBeforeAttributes')
	    local htmlStr = ''
        local isModifiable = true

	    local currOfficeId = self.mPlayerInfo.officer or 0
    	local cfg = RAWorldConfigManager:GetOfficialPositionCfg(currOfficeId) or {}
        if cfg.id then
            isModifiable = currOfficeId ~= self.mOfficeId
	    	txtMap.mBeforeJobs = _RALang(cfg.officeName)
            local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(currOfficeId)
            local htmlKey = cfg.welfareType == WelfareType.Buff and 'OfficialBuff' or 'OfficialDebuff'
		    htmlStr = RAStringUtil:getHTMLString(htmlKey, welfareStr)
            btnTitleMap.mSelectDetailsBtn = _RALang('@ChangeJob')
		else
			txtMap.mBeforeJobs = _RALang('@NoOfficial')
            local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(self.mOfficeId, nil, nil, 0)
			htmlStr = RAStringUtil:getHTMLString('NoOfficialBuff', welfareStr)
		end
		htmlLabel:setString(htmlStr)

		htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mAfterAttributes')
        local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(self.mOfficeId)
        local htmlKey = officeCfg.welfareType == WelfareType.Buff and 'OfficialBuff' or 'OfficialDebuff'
        htmlStr = RAStringUtil:getHTMLString(htmlKey, welfareStr)
        htmlLabel:setString(htmlStr)

	    UIExtend.setStringForLabel(self.ccbfile, txtMap)
	    UIExtend.setTitle4ControlButtons(self.ccbfile, btnTitleMap)
        UIExtend.setCCControlButtonEnable(self.ccbfile, 'mSelectDetailsBtn', isModifiable)

	    local playerIcon = RAPlayerInfoManager.getHeadIcon(selectedPlayer.icon)
	    UIExtend.addSpriteToNodeParent(self.ccbfile, 'mCellIconNode', playerIcon)
	end

	UIExtend.setNodesVisible(self.ccbfile, visibleMap)
end

function RAAppointToPositionPage:_selectTab(mode)
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

function RAAppointToPositionPage:_resetScrollViewSize()
    if self.mSelectMode == SelectMode.Alliance then
        self.mViewHeight = self.mViewHeight - self.mSearchHeight
    elseif self.mSelectMode == SelectMode.Search then
        self.mViewHeight = self.mViewHeight + self.mSearchHeight
    end
    local size = CCSizeMake(self.mViewWidth, self.mViewHeight)
    self.mScrollView:setViewSize(size)
    size:delete()
end

function RAAppointToPositionPage:_initScrollView()
    self.mScrollView:removeAllCell()

    local itemCell, cellHandler = nil, nil
    local playerId = self.mPlayerInfo.playerId

    if self.mSelectMode == SelectMode.Alliance then

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
		                mPlayerInfo = player,
		                mIsSelected = player.playerId == playerId
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
                mIsSelected   = player.playerId == playerId
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

function RAAppointToPositionPage:_initEditbox()
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

function RAAppointToPositionPage:_remoceEditbox()
    if self.mEditBox then
        self.mEditBox:removeFromParentAndCleanup(true)
        self.mEditBox = nil
    end
end

function RAAppointToPositionPage._editboxEventHandler(eventType, node)
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
        RAAppointToPositionPage.mSearchTxt = node:getText()
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

return RAAppointToPositionPage