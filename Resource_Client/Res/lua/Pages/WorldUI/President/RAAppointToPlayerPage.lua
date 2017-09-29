-- (选择职位)任命给指定玩家

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire('RARootManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAPresidentConfig = RARequire('RAPresidentConfig')
local RAStringUtil = RARequire('RAStringUtil')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')

local pageInfo =
{
    mPageName       = 'RAAppointToPlayerPage',
    mScrollView     = nil,
    mSVOffset       = nil,
    mViewWidth      = 640,
    mOfficeId       = nil,
    mPlayerId       = '',
    mPlayerIcon     = 0,
    mPlayerName     = '',
    mPlayerInfo 	= {},
    mEndTime        = 0,
    mCDAction       = nil
}
local RAAppointToPlayerPage = BaseFunctionPage:new(..., pageInfo)

--------------------------------------------------------------------------------------
-- region: RAPostTitleCellHandler

local RAPostTitleCellHandler =
{
    mType = 1,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return RAPresidentConfig.OfficeTypeTitleCCB[self.mType]
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()
        local OfficeTypeName = RAPresidentConfig.OfficeTypeName
        UIExtend.setStringForLabel(ccbfile, {mCellTitle = OfficeTypeName[self.mType] or ''})
    end,
}

-- endregion: RAPostTitleCellHandler
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: RAPostCellHandler

local RAPostCellHandler =
{
    mId = 0,

    mType = 1,

    mIsSelected = false,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return RAPresidentConfig.OfficeTypeCellCCB[self.mType]
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local cfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mId)
        local officialInfo = RAPresidentDataManager:GetOfficialInfo(self.mId) or {}

        local isAppointed = (officialInfo.playerId or '') ~= ''
        local txtMap =
        {
            mJobName    = _RALang(cfg.officeName or ''),
            mPlayerName = isAppointed and officialInfo.playerName or _RALang('@NotAppointed')
        }
        UIExtend.setStringForLabel(ccbfile, txtMap)

        UIExtend.setNodeVisible(ccbfile, 'mAddNode', not isAppointed)
        local icon = nil
        if isAppointed then
            icon = RAPlayerInfoManager.getHeadIcon(officialInfo.playerIcon)
        else
            icon = cfg.officeIcon
        end            
        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', icon)
        UIExtend.setMenuItemSelected(ccbfile, {mCellBtn = self.mIsSelected})
    end,

    onCellBtn = function(self)
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_AppointOfficialCell, {officeId = self.mId})
    end
}

-- endregion: RAPostCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_AppointOfficialCell,
    MessageDef_World.MSG_OfficialInfo_Update
}

local opcodeTB =
{
    HP_pb.PRESIDENT_GIFT_RECORD_S
}

local WelfareType = RAPresidentConfig.WelfareType
function RAAppointToPlayerPage:Enter(data)
    self:_resetData()

    self.mPlayerId = data.playerId
    self.mPlayerIcon = data.icon
    self.mPlayerName = data.name
    self.mPlayerInfo = RAPresidentDataManager:GetOfficialInfoByPlayerId(data.playerId) or {}

    UIExtend.loadCCBFile('RAPresidentApptPage2.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')
    local viewSize = self.mScrollView:getViewSize()
    self.mViewWidth = viewSize.width 
    viewSize:delete()

    self:_initTitle()

    self:_refreshBaseInfo()
    self:_initScrollView()
    self:_registerMessageHandlers()
end

function RAAppointToPlayerPage:Exit()
    self:_unregisterMessageHandlers()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAAppointToPlayerPage:onSelectDetailsBtn()
    local playerId = self.mPlayerId
    if playerId and self.mOfficeId then
        local confirmTxt = ''

        local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
        local officeName = _RALang(officeCfg.officeName)
        local officialInfo = RAPresidentDataManager:GetOfficialInfo(self.mOfficeId) or {}

        local playerName = self.mPlayerName
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
function RAAppointToPlayerPage:_resetData()
    self.mScrollView     = nil
    self.mOfficeId       = nil
    self.mPlayerId       = ''
    self.mPlayerIcon     = 0
    self.mPlayerName     = ''
    self.mPlayerInfo     = {}
    self.mEndTime        = 0
    self.mCDAction       = nil
end

function RAAppointToPlayerPage:_setSVOffset()
    self:_unsetSVOffset()
    if self.mScrollView then
        self.mSVOffset = self.mScrollView:getContentOffset()
    end
end

function RAAppointToPlayerPage:_unsetSVOffset()
    if self.mSVOffset then
        self.mSVOffset:delete()
        self.mSVOffset = nil
    end
end

--初始化顶部
function RAAppointToPlayerPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local titleName = _RALang('@Appointment')
    RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, 
        nil, RACommonTitleHelper.BgType.Blue)
end

function RAAppointToPlayerPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAppointToPlayerPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAppointToPlayerPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_ScrollViewCell.MSG_AppointOfficialCell then
        RAAppointToPlayerPage:_selectOfficial(msg.officeId)
        return
    end


    if msgId == MessageDef_World.MSG_OfficialInfo_Update then
        RAAppointToPlayerPage:_onGetOfficialInfo()
        return
    end
end

function RAAppointToPlayerPage:_onGetOfficialInfo()
    local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
    local officeName = _RALang(officeCfg.officeName)
    RARootManager.ShowMsgBox('@AppointSuccess', self.mPlayerName, officeName)
    RARootManager.ClosePage(self.mPageName)
end

function RAAppointToPlayerPage:_selectOfficial(officeId)
    if self.mOfficeId == officeId then
        self.mOfficeId = nil
    else
        self.mOfficeId = officeId
    end
    self:_setSVOffset()
    self:_refreshPage()
end

function RAAppointToPlayerPage:_refreshPage()
    self:_refreshBaseInfo()
    self:_initScrollView()
end

function RAAppointToPlayerPage:_refreshBaseInfo()
	local selectedOffice = self.mOfficeId

	local visibleMap =
	{
		mNoneNode 			= selectedOffice == nil,
		mSelectDetailsNode 	= selectedOffice ~= nil,
        mSelectDetailsBtn   = true,
        mCDNode             = false
	}

    local currOfficeId = self.mPlayerInfo.officeId or 0
    local cfg = RAWorldConfigManager:GetOfficialPositionCfg(currOfficeId) or {}

    local isAppointed = cfg.id ~= nil

    local txtMap =
    {
        mPlayerName = self.mPlayerName,
        mMemState   = '',
        mBeforeJobs = isAppointed and _RALang(cfg.officeName) or _RALang('@NoOfficial')
    }

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mBeforeAttributes')
    local htmlStr = ''

    if isAppointed then
        local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(currOfficeId)
        local htmlKey = cfg.welfareType == WelfareType.Buff and 'OfficialBuff' or 'OfficialDebuff'
        htmlStr = RAStringUtil:getHTMLString(htmlKey, welfareStr)
    else
        local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(self.mOfficeId, nil, nil, 0)
        htmlStr = RAStringUtil:getHTMLString('NoOfficialBuff', welfareStr)
    end
    htmlLabel:setString(htmlStr)
    
    self:_removeCD()
    if selectedOffice == nil then
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mSelectMemApptLabel')
        htmlLabel:setString(RAStringUtil:getHTMLString('SelectOfficialToAppointTip', self.mPlayerName))

        UIExtend.setCCControlButtonEnable(self.ccbfile, 'mApptBtn', false)
    else
        local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)
        local officeName = _RALang(officeCfg.officeName)
        
        txtMap.mAfterJobs = officeName

        local btnTitleMap =
        {
            mSelectDetailsBtn = isAppointed and _RALang('@ChangeJob') or _RALang('@Appointment')
        }
        UIExtend.setTitle4ControlButtons(self.ccbfile, btnTitleMap)

        htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mAfterAttributes')
        local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(self.mOfficeId)
        local htmlKey = officeCfg.welfareType == WelfareType.Buff and 'OfficialBuff' or 'OfficialDebuff'
        htmlStr = RAStringUtil:getHTMLString(htmlKey, welfareStr)
        htmlLabel:setString(htmlStr)

        local isModifiable = currOfficeId ~= self.mOfficeId

        if isModifiable then
            local offcialInfo = RAPresidentDataManager:GetOfficialInfo(self.mOfficeId) or {}
            self.mEndTime = offcialInfo.endTime or 0
            if self.mEndTime > common:getCurMilliTime() then
                isModifiable = false
                self:_updateCD()
                visibleMap.mCDNode = true
                visibleMap.mSelectDetailsBtn = false

                local this = self
                self.mCDAction = schedule(self.ccbfile, function()
                    this:_updateCD()
                end, 0.5)
            end
        end
        UIExtend.setCCControlButtonEnable(self.ccbfile, 'mSelectDetailsBtn', isModifiable)
    end

    UIExtend.setStringForLabel(self.ccbfile, txtMap)
    UIExtend.setNodesVisible(self.ccbfile, visibleMap)

    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.mPlayerIcon)
    UIExtend.addSpriteToNodeParent(self.ccbfile, 'mCellIconNode', playerIcon)
end

function RAAppointToPlayerPage:_initScrollView()
    self.mScrollView:removeAllCell()
    
    local itemCell, cellHandler = nil, nil

    local officeCfg = RAWorldConfigManager:GetOfficialPositionList()
    for officeType, idList in pairs(officeCfg) do
        itemCell = CCBFileCell:create()
        cellHandler = RAPostTitleCellHandler:new({mType = officeType})
        itemCell:registerFunctionHandler(cellHandler)
        itemCell:setCCBFile(cellHandler:getCCBName())
                
        self.mScrollView:addCellBack(itemCell)

        for _, id in ipairs(idList) do
            itemCell = CCBFileCell:create()
            cellHandler = RAPostCellHandler:new({
                mId         = id,
                mType       = officeType,
                mIsSelected = id == self.mOfficeId
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

--倒计时
function RAAppointToPlayerPage:_updateCD()
    if self.ccbfile then
        local curMilliTime = common:getCurMilliTime()
        local timeStamp = math.ceil((self.mEndTime - curMilliTime) / 1000)
        if timeStamp > 0 then
            local timeStr = Utilitys.createTimeWithFormat(timeStamp)
            UIExtend.setCCLabelString(self.ccbfile, 'mCD', timeStr)
        else
            self:_refreshBaseInfo()
        end
    end    
end

function RAAppointToPlayerPage:_removeCD()
    if self.mCDAction then
        self.ccbfile:stopAction(self.mCDAction)
        self.mCDAction = nil
        self.mEndTime = 0
    end
end

return RAAppointToPlayerPage