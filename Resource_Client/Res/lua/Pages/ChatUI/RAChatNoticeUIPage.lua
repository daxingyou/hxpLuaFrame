--region RAChatNoticeUIPage.lua
--Author : phan
--Date   : 2016/7/8
--此文件由[BabeLua]插件自动生成

RARequire("BasePage")
local RAChatNoticeUIPage = BaseFunctionPage:new(...)

local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAChatData = RARequire("RAChatData")
local RAChatManager = RARequire("RAChatManager")
local common = RARequire("common")

local MsgString = nil

function RAChatNoticeUIPage:Enter()
    local ccbfile = UIExtend.loadCCBFile("RAChatBroadCastPopUp.ccbi",self)
    self.ccbfile = ccbfile
    self:initChatNoticeUI()
    self.lastSendTime = common:getCurTime()
end

function RAChatNoticeUIPage:initChatNoticeUI()
    self:refreshChatNoticeUI()
    self:initEditBox()
end

function RAChatNoticeUIPage:refreshChatNoticeUI()
    local item = RACoreDataManager:getItemInfoByItemId(RAChatData.HORNID) -- 800106 喇叭道具
    local count = RACoreDataManager:getItemCountByItemId(RAChatData.HORNID)

    local nodeVisible = {}
    if count > 0 then
        nodeVisible["mUseBtnNode"] = true
        nodeVisible["mBuyAndUseBtnNode"] = false
    else
        nodeVisible["mUseBtnNode"] = false
        nodeVisible["mBuyAndUseBtnNode"] = true
        UIExtend.setStringForLabel(self.ccbfile,{mNeedDiamondsNum = tostring(item.sellPrice)})
    end
    local haveHornCount = _RALang("@HaveBroadCastNum",tostring(count))
    UIExtend.setStringForLabel(self.ccbfile,{mHaveBroadCastNum = haveHornCount})
    UIExtend.setNodesVisible(self.ccbfile,nodeVisible)
end

local function editboxEventHandler(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == "began" then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == "ended" then
        -- triggered when an edit box loses focus after keyboard is hidden.
        RAChatManager.MsgString = node:getText()
    elseif eventType == "changed" then
        -- triggered when the edit box text was changed.
    elseif eventType == "return" then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RAChatNoticeUIPage:initEditBox()
    
    self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editBox:isKeyboardShow() == true then
        else
            RARootManager.ClosePage("RAChatNoticeUIPage")
        end
    end

    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mInputNode")
    local editBox = UIExtend.createEditBox(self.ccbfile,"mInputBG",inputNode,editboxEventHandler,nil,nil,nil,24)
    self.editBox = editBox
    self.editBox:setPlaceHolder(_RALang("@ClickInputNoticeContent"))
end

function RAChatNoticeUIPage:sendMsg()
    local curTime = common:getCurTime()  
    local mulTime = curTime - self.lastSendTime
    local errorText = ""
    if mulTime < 0.5 then
        errorText = "@chatInputTooOften"
    elseif RAChatManager.MsgString == nil or RAChatManager.MsgString == "" then
        errorText = "@chatInputNil"
    else
        local RAStringUtil = RARequire('RAStringUtil')
        RAChatManager.MsgString = RAStringUtil:replaceToStarForChat(RAChatManager.MsgString)
        RAChatManager:sendChatContent(RAChatManager.MsgString,true)
        RARootManager.CloseCurrPage()
        self.lastSendTime = curTime
    end

    if errorText ~= "" then
        local errorStr = _RALang(errorText)
        local data = {labelText = errorStr}
        RARootManager.showConfirmMsg(data)
    end
end

function RAChatNoticeUIPage:onBuyAndUseBtn()
    self:sendMsg()
end

function RAChatNoticeUIPage:onUseBtn()
    self:sendMsg()
end

function RAChatNoticeUIPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAChatNoticeUIPage:Exit()  
    self.editBox:removeFromParentAndCleanup(true)
    self.editBox = nil
    RAChatManager.MsgString = ""
    UIExtend.unLoadCCBFile(self)
end

return RAChatNoticeUIPage
--endregion
