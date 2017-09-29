--留言板
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAAllianceEditLeaveMsgPage = BaseFunctionPage:new(...)
local RAStringUtil = RARequire('RAStringUtil')
local RAAllianceManager = RARequire('RAAllianceManager')

function RAAllianceEditLeaveMsgPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceChatPopUp.ccbi", RAAllianceEditLeaveMsgPage)
    self.data = data

    self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editbox:isKeyboardShow() == true then
        else
            RARootManager.ClosePage("RAAllianceEditLeaveMsgPage")
        end
    end

    local function inputEditboxEventHandler(eventType, node)
    --body
        -- CCLuaLog(eventType)
        if eventType == "began" then
        elseif eventType == "ended" then
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
            local text = self.editbox:getText()
            local length = RAStringUtil:getStringUTF8Len(text)
            self.mHaveBroadCastNum:setString(_RALang("@AllianceLeaveMsgRemain",200-length))
        elseif eventType == "return" then
            local text = self.editbox:getText()
            text = RAStringUtil:replaceToStarForChat(text)
            self.editbox:setText(text)
        end
    end

    self.mInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputNode')
    local editbox=UIExtend.createEditBox(self.ccbfile,"mInputBG",self.mInputNode,inputEditboxEventHandler,nil,200)
    self.editbox = editbox
    self.editbox:setFontColor(RAGameConfig.COLOR.BLACK)
    self.editbox:setText('')
    -- editbox:setIsAutoFitHeight(false)
    self.title = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mChatTitle')
    self.mHaveBroadCastNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHaveBroadCastNum')
    self.mCancelBtn = UIExtend.getCCNodeFromCCB(self.ccbfile,'mUseBtnNode')
    self.mBuyAndUseBtn = UIExtend.getCCNodeFromCCB(self.ccbfile,'mBuyAndUseBtnNode')

    self.title:setString(_RALang('@AllianceEditLeaveMsgTitle'))

    -- local length = RAStringUtil:getStringUTF8Len(data.text)
    self.mHaveBroadCastNum:setString(_RALang("@AllianceLeaveMsgRemain",200)) 

    self.mCancelBtn:setVisible(true)
    self.mBuyAndUseBtn:setVisible(true)
    self.mHaveBroadCastNum:setVisible(true)
end


function RAAllianceEditLeaveMsgPage:Exit()
	-- self:removeMessageHandler()
    -- self.editbox:setEnabled(true)
    self.editbox:removeFromParentAndCleanup(false)
    self.editbox = nil 
	UIExtend.unLoadCCBFile(RAAllianceEditLeaveMsgPage)
end

--关闭
function RAAllianceEditLeaveMsgPage:onClose()
    RARootManager.ClosePage("RAAllianceEditLeaveMsgPage")
end

--取消
function RAAllianceEditLeaveMsgPage:onCancelBtn()
    RARootManager.ClosePage("RAAllianceEditLeaveMsgPage")
end 

--编辑联盟公告
function RAAllianceEditLeaveMsgPage:onBuyAndUseBtn()
    local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
    -- RAAllianceManager.tempAnnouncement = self.editbox:getText()
    local text = self.editbox:getText()
    text = RAStringUtil:trim(text)

    if #text == 0 then 
        local str = _RALang("@CanotSendEmptyMessage")
        RARootManager.ShowMsgBox(str)
        return 
    end



    RAAllianceProtoManager:postMessageReq(self.editbox:getText(),self.data.allianceId)
    RARootManager.ClosePage("RAAllianceEditLeaveMsgPage")
end 

return RAAllianceEditLeaveMsgPage