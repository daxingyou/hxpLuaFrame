-- 总统府设置信息界面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire('common')

local pageInfo =
{
    mScrollView     = nil,
    mCountryInfo    = {},
    mCountryName    = '',
    mCountryIcon    = nil,
    mViewWidth      = 640,
    mEditbox        = nil,
    mIsNameOK       = true,
    mChangeRecord   = 0,
    mChangeTimes    = -1,
    mIsSendingReq   = false
}
local RAPresidentSettingPage = BaseFunctionPage:new(..., pageInfo)

--------------------------------------------------------------------------------------
-- region: RAFlagCellHandler

local RAFlagCellHandler =
{
    mFlagId = 0,

    mFlagIcon = '',

    mIsSelected = false,

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentSettingPopUpCell.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', self.mFlagIcon)
        UIExtend.setNodeVisible(ccbfile, 'mHighLightNode', self.mIsSelected)
    end,

    onCellBtn = function (self)
        MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_PresidentFlagCell, {id = self.mFlagId})
    end
}

-- endregion: RAFlagCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_PresidentFlagCell,
    MessageDef_World.MSG_PresidentInfo_Update,
    MessageDef_Packet.MSG_Operation_Fail
}

local ChangeType =
{
    Name = 1,
    Flag = 2
}

function RAPresidentSettingPage:Enter(data)
    self:_resetData()

    UIExtend.loadCCBFile('RAPresidentSettingPopUp.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mFlagListSV')
    local viewSize = self.mScrollView:getViewSize()
    self.mViewWidth = viewSize.width 
    viewSize:delete()

    self:_initTitle()

    self:_initEditbox()
    self:_refreshPage()
    self:_registerMessageHandlers()
end

function RAPresidentSettingPage:Exit()
    self:_unregisterMessageHandlers()
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    self:_removeEditbox()
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAPresidentSettingPage:_resetData()
    self.mScrollView = nil
    self.mIsNameOK = true
    self.mChangeRecord = 0
    self.mChangeTimes = -1
    self.mIsSendingReq = false
end

--初始化顶部
function RAPresidentSettingPage:_initTitle()
    UIExtend.setStringForLabel(self.ccbfile, {mTitle = _RALang('@PresidentSetting')})
end

function RAPresidentSettingPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentSettingPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentSettingPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_ScrollViewCell.MSG_PresidentFlagCell then
        RAPresidentSettingPage:_changeControyIcon(msg.id)
        return
    end

    if msgId == MessageDef_World.MSG_PresidentInfo_Update then
        RAPresidentSettingPage:_refreshPage()
        RAPresidentSettingPage:_onModifyRsp()
        return
    end

    if msgId == MessageDef_Packet.MSG_Operation_Fail then
        RAPresidentSettingPage:_onModifyRsp(true)
        return
    end
end

function RAPresidentSettingPage:onModify()
    if not self.mIsNameOK then
        RARootManager.ShowMsgBox('@PalaceNameNotValid')
        return
    end
    
    if self.mChangeRecord > 0 then
        local modifyInfo = 
        {
            name = self.mCountryName,
            icon = self.mCountryIcon
        }

        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendSetCountryInfoReq(modifyInfo)
        self.mIsSendingReq = true
    end
end

function RAPresidentSettingPage:_onModifyRsp(hasError)
    if self.mIsSendingReq then
        if not hasError then
            RARootManager.ShowMsgBox('@PresidentSettingModifySuccess')
        end
        self.mIsSendingReq = false
    end
end

function RAPresidentSettingPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAPresidentSettingPage:_refreshPage()
    self:_refreshBaseInfo()
    self:_initScrollView()
end

function RAPresidentSettingPage:_refreshBaseInfo()
    local countryInfo = RAPresidentDataManager:GetCountryInfo()
    self.mCountryIcon = countryInfo.icon or 0
    self.mCountryName = countryInfo.name or ''
    self.mCountryInfo = countryInfo

    self:_refreshName()
    self:_refreshFlag()

    self:_setModifiable()
end

function RAPresidentSettingPage:_refreshName()
    self.mEditBox:setText(self.mCountryName)
    UIExtend.setNodesVisible(self.ccbfile, {
        mAvailablePic   = self.mIsNameOK,
        mUnavailablePic = not self.mIsNameOK,
    })
end

function RAPresidentSettingPage:_refreshFlag()
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local icon = RAWorldConfigManager:GetPresidengFlag(self.mCountryIcon)
    UIExtend.setSpriteImage(self.ccbfile, {mFlag = icon})
end

function RAPresidentSettingPage:_setModifiable()
    local RAPresidentConfig = RARequire('RAPresidentConfig')
    local maxTimes = RAPresidentConfig.ModifySettingTimesMax or 1

    local remainCnt = maxTimes - self.mCountryInfo.modifyTimes
    remainCnt = remainCnt > 0 and remainCnt or 0
    if self.mChangeTimes ~= self.mCountryInfo.modifyTimes then
        self.mChangeTimes = self.mCountryInfo.modifyTimes

        local str = _RALang('@PresidentSettingExplain', remainCnt)
        UIExtend.setCCLabelString(self.ccbfile, 'mModifyTipLabel', str)

        local colorKey = remainCnt > 0 and 'Enough' or 'Lack'
        local color = ccc3(unpack(RAPresidentConfig.GiftNumColor[colorKey]))
        UIExtend.setLabelTTFColor(self.ccbfile, 'mModifyTipLabel', color)
        color:delete()
    end
    local isEnabled = remainCnt > 0 and self.mChangeRecord > 0 and self.mIsNameOK
    UIExtend.setCCControlButtonEnable(self.ccbfile, 'mModify', isEnabled)
end

function RAPresidentSettingPage:_initScrollView()
    self.mScrollView:removeAllCell()
    
    local itemCell, cellHandler = nil, nil

    local conf = RARequire('president_flag_conf')
    local flagIdList = common:table_keys(conf)
    table.sort(flagIdList)
    for _, id in pairs(flagIdList) do
        itemCell = CCBFileCell:create()
        cellHandler = RAFlagCellHandler:new({
            mFlagId     = id,
            mFlagIcon   = conf[id].icon,
            mIsSelected = id == self.mCountryIcon
        })
        itemCell:registerFunctionHandler(cellHandler)
        itemCell:setCCBFile(cellHandler:getCCBName())
                
        self.mScrollView:addCellBack(itemCell)
    end

    self.mScrollView:orderCCBFileCells(self.mViewWidth)
end

function RAPresidentSettingPage:_changeCountryName(newName)
    if newName and newName ~= self.mCountryName then
        newName = RAStringUtil:trim(newName)
        local length = RAStringUtil:getStringUTF8Len(newName)

        local result = self:_validateName(newName)
        if result == 0 then
            self.mIsNameOK = true
        else 
            self.mIsNameOK = false
        end 

        self.mCountryName = newName
        self:_refreshName()

        local bit = RARequire('bit')
        if self.mIsNameOK and newName ~= self.mCountryInfo.name then
            self.mChangeRecord = bit:bor(self.mChangeRecord, ChangeType.Name)
        elseif bit:band(self.mChangeRecord, ChangeType.Name) == 1 then
            self.mChangeRecord = bit:bxor(self.mChangeRecord, ChangeType.Name)
        end
        self:_setModifiable()
    end
end

function RAPresidentSettingPage:_changeControyIcon(newFlag)
    self.mCountryIcon = newFlag
    self:_refreshFlag()
    self:_initScrollView()

    local bit = RARequire('bit')
    if newFlag ~= self.mCountryInfo.icon then
        self.mChangeRecord = bit:bor(self.mChangeRecord, ChangeType.Flag)
    else
        self.mChangeRecord = bit:bxor(self.mChangeRecord, ChangeType.Flag)
    end
    self:_setModifiable()
end

--判断联盟名字是否合法 0为合法 -1长度不符合 -2 格式非法 -3屏蔽字
function RAPresidentSettingPage:_validateName(name)
    local length =  GameMaths:calculateNumCharacters(name)

    local guild_const_conf = RARequire('guild_const_conf')
    local confMinAndMaxLen = guild_const_conf.allianceNameMinMax.value
    local lenTb= RAStringUtil:split(confMinAndMaxLen, '_')
    local minLen, maxLen = lenTb[1], lenTb[2]
   
    if length < tonumber(minLen) or length > tonumber(maxLen) then 
        return -1
    end 

    if not common:checkStringValidate(name) then 
        return -2
    end 

    if not RAStringUtil:isStringOKForChat(name) then 
        CCLuaLog('屏蔽字')
        return -3
    end 

    return 0
end

function RAPresidentSettingPage:_initEditbox()
    if self.mEditBox == nil then
        local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mInputCountryNode')
        local color = ccc3(255, 255, 255)
        self.mEditBox = UIExtend.createEditBox(self.ccbfile, 'mInputCountryBG', inputNode, 
            self._editboxEventHandler, nil, nil, nil, 24, nil, color)
        color:delete()
        self.mEditBox:setInputMode(kEditBoxInputModeSingleLine)
        self.mEditBox:setMaxLength(15)
    end
end

function RAPresidentSettingPage:_removeEditbox()
    if self.mEditBox then
        self.mEditBox:removeFromParentAndCleanup(true)
        self.mEditBox = nil
    end
end

function RAPresidentSettingPage._editboxEventHandler(eventType, node)
    if eventType == 'began' then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        RAPresidentSettingPage:_changeCountryName(node:getText())
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

return RAPresidentSettingPage