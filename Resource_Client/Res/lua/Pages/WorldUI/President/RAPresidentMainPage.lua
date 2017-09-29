-- 王国界面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire('RARootManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAPresidentConfig = RARequire('RAPresidentConfig')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

local pageInfo =
{
    mPageName       = 'RAPresidentMainPage',
    mIsPresident    = false,
    mIsShowMgr      = false,
    mScrollView     = nil,
    mViewWidth      = 640,
    mTitle          = nil
}
local RAPresidentMainPage = BaseFunctionPage:new(..., pageInfo)

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

    mIsPresident = false,

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
        if not isAppointed and self.mIsPresident then
            txtMap.mPlayerName = _RALang('@ToBeAppointed')
        end
        UIExtend.setStringForLabel(ccbfile, txtMap)

        UIExtend.setNodeVisible(ccbfile, 'mAddNode', self.mIsPresident and not isAppointed)

        local icon = nil
        if isAppointed then
            icon = RAPlayerInfoManager.getHeadIcon(officialInfo.playerIcon)
        else
            icon = cfg.officeIcon
        end            
        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', icon)
        UIExtend.setMenuItemSelected(ccbfile, {mCellBtn = false})
    end,

    onCellBtn = function(self)
        RARootManager.OpenPage('RAOfficialPositionInfoPage', {officeId = self.mId}, false, true, true)
    end
}

-- endregion: RAPostCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_World.MSG_OfficialInfo_Update,
    MessageDef_World.MSG_PresidentInfo_Update
}

function RAPresidentMainPage:Enter(data)
    self:_resetData()
    self:_getOfficialInfo()
    self.mIsPresident = RAPlayerInfoManager.IsPresident()

    UIExtend.loadCCBFile('RAPresidentMainPage.ccbi', self)
    self.ccbfile:runAnimation(self.mIsPresident and 'KeepCloseAni' or 'NoMgrAni')
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')
    local viewSize = self.mScrollView:getViewSize()
    self.mViewWidth = viewSize.width 
    viewSize:delete()

    self:_initTitle()

    self:_refreshBaseInfo()
    self:_initScrollView()
    self:_registerMessageHandlers()
end

function RAPresidentMainPage:Exit()
    self:_unregisterMessageHandlers()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    self.mTitle = nil
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAPresidentMainPage:_resetData()
    self.mScrollView = nil
    self.mIsPresident = false
    self.mIsShowMgr = false
end

--初始化顶部
function RAPresidentMainPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local countryInfo = RAPresidentDataManager:GetCountryInfo()
    local RAWorldVar = RARequire('RAWorldVar')
    local serverName = RAPlayerInfoManager.getKingdomName(RAWorldVar.KingdomId.Map)
    local titleName = _RALang('@PalaceName_Title', countryInfo.name or '', serverName)

    self.mTitle = RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, 
        nil, RACommonTitleHelper.BgType.Blue)
end

function RAPresidentMainPage:_refreshTitle()
    local countryInfo = RAPresidentDataManager:GetCountryInfo()
    local RAWorldVar = RARequire('RAWorldVar')
    local serverName = RAPlayerInfoManager.getKingdomName(RAWorldVar.KingdomId.Map)
    local titleName = _RALang('@PalaceName_Title', countryInfo.name or '', serverName)
    self.mTitle:SetTitleName(titleName)
end

function RAPresidentMainPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentMainPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentMainPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_World.MSG_PresidentInfo_Update then
        RAPresidentMainPage:_refreshSetting()
        return
    end

    if msgId == MessageDef_World.MSG_OfficialInfo_Update then
        RAPresidentMainPage:_refreshOfficial()   
        return
    end
end

function RAPresidentMainPage:onSettingBtn()
    if self.mIsPresident then
        RARootManager.OpenPage('RAPresidentSettingPage', nil, false, true, true)
    else
        RARootManager.ShowMsgBox('@OnlyPresidentCanModify')
    end
end

function RAPresidentMainPage:onApptRecordBtn()
    local pageData = {recordType = RAPresidentConfig.RecordType.Appointment}
    RARootManager.OpenPage('RAPresidentRecordPage', pageData, false, true, true)
end

function RAPresidentMainPage:onManagerBtn()
    self.mIsShowMgr = not self.mIsShowMgr
    self.ccbfile:runAnimation(self.mIsShowMgr and 'MgrOpenAni' or 'MgrCloseAni')
end

function RAPresidentMainPage:onTaxationBtn()
    RARootManager.OpenPage('RAPresidentTaxationPage')
end

function RAPresidentMainPage:onGiftPackAwardedBtn()
    RARootManager.OpenPage('RAPresidentGiftPage')
end

function RAPresidentMainPage:onTaxationRecordBtn()
    RARootManager.OpenPage('RAPresidentTaxationRecordPage')
end

function RAPresidentMainPage:onGiftPackRecordBtn()
    local pageData = {recordType = RAPresidentConfig.RecordType.Gift}
    RARootManager.OpenPage('RAPresidentRecordPage', pageData, false, true, true)
end

function RAPresidentMainPage:_refreshSetting()
    if self.mTitle then
        self:_refreshTitle()
    end
    self:_refreshBaseInfo()
end

function RAPresidentMainPage:_refreshOfficial()
    if self.mScrollView then
        self.mScrollView:refreshAllCell() 
    end
end

function RAPresidentMainPage:_refreshBaseInfo()
    local presidentInfo = RAPresidentDataManager:GetPresidentInfo()

    local txtMap =
    {
        mAllianceName       = presidentInfo.guildName or '',
        mPresidentName      = presidentInfo.playerName or ''
    }
    UIExtend.setStringForLabel(self.ccbfile, txtMap)

    local countryInfo = RAPresidentDataManager:GetCountryInfo()
    local flagIcon = RAWorldConfigManager:GetPresidengFlag(countryInfo.icon)
    UIExtend.setMenuItemTexture(self.ccbfile, 'mSettingBtn', flagIcon, 158, 168)

    local iconNodeName = self.mIsPresident and 'mMgrIconNode' or 'mNoMgrIconNode'
    local presidentIcon = RAPlayerInfoManager.getPlayerBust(presidentInfo.playerIcon)
    UIExtend.addSpriteToNodeParent(self.ccbfile, iconNodeName, presidentIcon)
end

function RAPresidentMainPage:_initScrollView()
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
                mId             = id,
                mType           = officeType,
                mIsPresident    = self.mIsPresident
            })
            itemCell:registerFunctionHandler(cellHandler)
            itemCell:setCCBFile(cellHandler:getCCBName())
                
            self.mScrollView:addCellBack(itemCell)
    	end
    end

    self.mScrollView:orderCCBFileCells(self.mViewWidth)
end

function RAPresidentMainPage:_getOfficialInfo()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    RAWorldProtoHandler:sendGetOfficialsReq()
end

return RAPresidentMainPage