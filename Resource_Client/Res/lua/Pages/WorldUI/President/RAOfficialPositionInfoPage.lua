-- 官职信息界面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire('RARootManager')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')

local pageInfo =
{
    mIsPresident    = false,
    mOfficeId       = 0,
    mEndTime        = 0,
    mPlayerInfo     = {}
}
local RAOfficialPositionInfoPage = BaseFunctionPage:new(..., pageInfo)

local msgTB =
{
    MessageDef_World.MSG_OfficialInfo_Update
}

function RAOfficialPositionInfoPage:Enter(data)
    self:_resetData()
    self.mOfficeId = data.officeId

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    self.mIsPresident = RAPlayerInfoManager.IsPresident()

    UIExtend.loadCCBFile('RAPresidentMainPopUp.ccbi', self)
    
    self:_refreshPage()
end

function RAOfficialPositionInfoPage:Exit()
	if self.ccbfile then
		self.ccbfile:stopAllActions()
	end
    UIExtend.unLoadCCBFile(self)
    self:_unregisterMessageHandlers()
    self:_resetData()
end

function RAOfficialPositionInfoPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAOfficialPositionInfoPage:onAppointmentBtn()
    self:onClose()
	RARootManager.OpenPage('RAAppointToPositionPage', {officeId = self.mOfficeId})
end

function RAOfficialPositionInfoPage:onChangeJobBtn()
    self:onClose()
    RARootManager.OpenPage('RAAppointToPositionPage', {officeId = self.mOfficeId})
end

function RAOfficialPositionInfoPage:onUndoBtn()
    local playerId = self.mPlayerInfo.playerId
    if common:isEmptyStr(playerId) then return end

    local this = self
    local confirmData =
    {
        labelText = _RALang('@ConfirmDismissOfficial', self.mPlayerInfo.playerName),
        yesNoBtn = true,
        resultFun = function (isOK)
            if isOK then
                local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
                RAWorldProtoHandler:sendDismissOfficialReq(playerId, this.mOfficeId)
                this:_registerMessageHandlers()
            end
        end
    }
    RARootManager.showConfirmMsg(confirmData)
end

function RAOfficialPositionInfoPage:onUndoInCDBtn()
    self:onUndoBtn()
end

function RAOfficialPositionInfoPage:_resetData()
    self.mIsPresident = false
    self.mOfficeId = 0
    self.mEndTime = 0
    self.mPlayerInfo = {}
end

function RAOfficialPositionInfoPage:_refreshPage()
    local RAPresidentDataManager = RARequire('RAPresidentDataManager')
    local officialInfo = RAPresidentDataManager:GetOfficialInfo(self.mOfficeId) or {}
    self.mPlayerInfo = officialInfo

    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local officeCfg = RAWorldConfigManager:GetOfficialPositionCfg(self.mOfficeId)

   	local isAppointed = officialInfo.playerId and officialInfo.playerId ~= ''

    local txtMap =
    {
    	mTitle 		= _RALang(officeCfg.officeName),
        mPlayerName = isAppointed and officialInfo.playerName or '',
        mCD 		= ''
    }
    UIExtend.setStringForLabel(self.ccbfile, txtMap)

    local icon = nil
    if isAppointed then
    	local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    	icon = RAPlayerInfoManager.getHeadIcon(officialInfo.playerIcon)
    else
    	icon = officeCfg.officeIcon
	end 
	if icon then
	    UIExtend.addSpriteToNodeParent(self.ccbfile, 'mIconNode', icon)
	end

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mDetailsHTMLLabel')
    local RAStringUtil = RARequire('RAStringUtil')
    local welfareStr = RAWorldConfigManager:GetOfficialWelfareStr(self.mOfficeId)
    local RAPresidentConfig = RARequire('RAPresidentConfig')
    local htmlKey = officeCfg.welfareType == RAPresidentConfig.WelfareType.Buff and 'OfficialBuff' or 'OfficialDebuff'
    htmlLabel:setString(RAStringUtil:getHTMLString(htmlKey, welfareStr))

	local isAbleToChange = not (officialInfo.endTime and officialInfo.endTime > common:getCurMilliTime())

    local visibleMap =
    {
    	mAppointmentBtn = isAbleToChange and not isAppointed,
    	mChangBtnNode 	= isAbleToChange and isAppointed,
    	mCDNode 		= not isAbleToChange,
        mUndoInCDBtn    = not isAbleToChange and isAppointed
	}
	UIExtend.setNodesVisible(self.ccbfile, visibleMap)

    local enableMap =
    {
        mAppointmentBtn = self.mIsPresident,
        mChangeJobBtn   = self.mIsPresident,
        mUndoBtn        = self.mIsPresident,
        mUndoInCDBtn    = self.mIsPresident
    }
    UIExtend.setEnabled4ControlButtons(self.ccbfile, enableMap)

    if not isAbleToChange then
    	self.mEndTime = officialInfo.endTime
    	self:_updateCD()

    	local this = self
    	schedule(self.ccbfile, function()
    		this:_updateCD()
    	end, 0.5)
    end
end

--倒计时
function RAOfficialPositionInfoPage:_updateCD()
    if self.ccbfile then
        local curMilliTime = common:getCurMilliTime()
        local timeStamp = math.ceil((self.mEndTime - curMilliTime) / 1000)
        if timeStamp > 0 then
	        local timeStr = Utilitys.createTimeWithFormat(timeStamp)
	        UIExtend.setCCLabelString(self.ccbfile, 'mCD', timeStr)
        else
            self:_refreshPage()
	    end
    end    
end

function RAOfficialPositionInfoPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAOfficialPositionInfoPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAOfficialPositionInfoPage._onReceiveMessage(msg)
    local msgId = msg.messageID
    if msgId == MessageDef_World.MSG_OfficialInfo_Update then
        RAOfficialPositionInfoPage:_onDismissRsp()
        return
    end
end

function RAOfficialPositionInfoPage:_onDismissRsp()
    RARootManager.ShowMsgBox('@DismissOfficialSuccess', self.mPlayerInfo.playerName)
    self:_unregisterMessageHandlers()
    self:onClose()
end