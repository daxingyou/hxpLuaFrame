--编辑联盟公告
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAAllianceEditAnnouncePage = BaseFunctionPage:new(...)
local RAStringUtil = RARequire('RAStringUtil')
local RAAllianceManager = RARequire('RAAllianceManager')

-- pageType 0 查看  1 编辑
function RAAllianceEditAnnouncePage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceChatPopUp.ccbi", RAAllianceEditAnnouncePage)

    self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editbox:isKeyboardShow() == true then
        else
            RARootManager.ClosePage("RAAllianceEditAnnouncePage")
        end
    end

    local function inputEditboxEventHandler(eventType, node)
    --body
        -- CCLuaLog(eventType)kKeyboardReturnTypeSend
        if eventType == "began" then
        elseif eventType == "ended" then
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
            local text = self.editbox:getText()
            local length = RAStringUtil:getStringUTF8Len(text)
            self.mHaveBroadCastNum:setString(_RALang("@AllianceNameRemain",200-length))
        elseif eventType == "return" then
        end
    end

    self.mInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputNode')
    local editbox=UIExtend.createEditBox(self.ccbfile,"mInputBG",self.mInputNode,inputEditboxEventHandler,nil,200)
    self.editbox = editbox
    -- self.editbox:setReturnType(kKeyboardReturnTypeSend)
    self.editbox:setFontColor(RAGameConfig.COLOR.BLACK)
    self.editbox:setText(data.text)
    self.editbox:setInputMode(kEditBoxInputModeAny)
    -- editbox:setIsAutoFitHeight(false)
    self.title = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mChatTitle')
    self.mHaveBroadCastNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHaveBroadCastNum')
    self.mCancelBtn = UIExtend.getCCNodeFromCCB(self.ccbfile,'mUseBtnNode')
    self.mBuyAndUseBtn = UIExtend.getCCNodeFromCCB(self.ccbfile,'mBuyAndUseBtnNode')

    UIExtend.setControlButtonTitle(self.ccbfile,'mBuyAndUseBtn',_RALang('@Save'))

    if data.pageType == 0 then 
        self.title:setString(_RALang('@AllianceAnnounceTitle'))
        self.editbox:setEnabled(false)
        self.mHaveBroadCastNum:setVisible(false)
        self.mCancelBtn:setVisible(false)
        self.mBuyAndUseBtn:setVisible(false)
    else
        self.title:setString(_RALang('@EditAllianceAnnounceTitle'))
        self.editbox:setEnabled(true)
        self.mHaveBroadCastNum:setVisible(true)
        self.mCancelBtn:setVisible(true)
        self.mBuyAndUseBtn:setVisible(true)
    end

    local length = RAStringUtil:getStringUTF8Len(data.text)
    self.mHaveBroadCastNum:setString(_RALang("@AllianceNameRemain",200-length)) 
end


function RAAllianceEditAnnouncePage:Exit()
	-- self:removeMessageHandler()
    UIExtend.setControlButtonTitle(self.ccbfile,'mBuyAndUseBtn','@Confirm')
    self.editbox:setEnabled(true)
    self.editbox:removeFromParentAndCleanup(false)
    self.editbox = nil 
	UIExtend.unLoadCCBFile(RAAllianceEditAnnouncePage)
end

--关闭
function RAAllianceEditAnnouncePage:onClose()
    RARootManager.ClosePage("RAAllianceEditAnnouncePage")
end

--取消
function RAAllianceEditAnnouncePage:onCancelBtn()
    RARootManager.ClosePage("RAAllianceEditAnnouncePage")
end 

--编辑联盟公告
function RAAllianceEditAnnouncePage:onBuyAndUseBtn()
    local RAAllianceProtoManager = RARequire('RAAllianceProtoManager') 

    RAAllianceManager.tempAnnouncement = self.editbox:getText()
    RAAllianceProtoManager:postNoticeReq(RAAllianceManager.tempAnnouncement)
    RARootManager.ClosePage("RAAllianceEditAnnouncePage")
end 

return RAAllianceEditAnnouncePage