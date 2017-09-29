
--系统邮件界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
RARequire("MessageDefine")
RARequire("MessageManager")
local topMayPageMsg = MessageDef_RootManager.MSG_TopPageMayChange

local RAMailWritePage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == topMayPageMsg then
    	if message.topPageName == 'RAMailWritePage' then 
            RAMailWritePage:setEditBoxVisible(true)
            local txt = RAMailWritePage.nameEdibox:getText()
			if txt == "" then
				RAMailWritePage.contEdibox:setText("")
				RAMailWritePage.contEdibox:setEnabled(false)
			else
				RAMailWritePage.contEdibox:setEnabled(true)
			end 
        else
            RAMailWritePage:setEditBoxVisible(false)
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then                 --删除邮件成功返回
        local opcode = message.opcode
        if opcode==HP_pb.MAIL_CREATE_CHATROOM_C then
		    local str = _RALang("@SendmailSuccess")
			RARootManager.ShowMsgBox(str)
			RARootManager.ClosePage("RAMailWritePage")
        elseif opcode==HP_pb.MAIL_SEND_GUILD_MAIL_C then
		    local str = _RALang("@SendmailSuccess")
			RARootManager.ShowMsgBox(str)
			RARootManager.ClosePage("RAMailWritePage")
        end              
    end
end

--默认不传data，传的话sendName：多个名字的时候要带分号"name1;name2"
function RAMailWritePage:Enter(data)
	CCLuaLog("RAMailWritePage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailWritePageV6.ccbi",self)
	self.ccbfile  = ccbfile
	if data then
		self.nameStr=data.sendName
		self.isSendAllianceMems = data.isSendAllianceMems
	end
	self:registerMessageHandler()
    self:init()
end

function RAMailWritePage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

-- function nameEditboxEventHandler(eventType, node)
-- 	if eventType == "changed" then
-- 		--local txt = node:getText()
-- 		--RAMailWritePage:checkIllegalMsg(node ,txt)
-- 	elseif eventType == "ended" then	
-- 		local txt = node:getText()
-- 		if txt=="" then
-- 			RAMailWritePage.contEdibox:setEnabled(false)
-- 		else
-- 			RAMailWritePage.contEdibox:setEnabled(true)
-- 		end 
-- 		RAMailWritePage:checkIllegalMsg(node ,txt)
-- 	end
-- end

function msgEditboxEventHandler(eventType, node)
	if eventType == "ended" then
    	local txt = RAMailWritePage.contEdibox:getText()
        RAMailWritePage:checkIllegalMsg(node,txt)
    elseif eventType == "changed" then
    	local valueText = RAMailWritePage.contEdibox:getText()
     --    RAMailWritePage:checkIllegalMsg(RAMailWritePage.contEdibox,valueText)
        if string.find(valueText,'\n') ~= nil then 
            valueText = valueText:gsub("\n", "")
            node:setText(valueText) 
            node:closeKeyboard()
        end 
    elseif eventType == "return" then
        local txt=RAMailWritePage.contEdibox:getText()
        RAMailWritePage:checkIllegalMsg(RAMailWritePage.contEdibox,txt)
    end
end

function RAMailWritePage:init()
	-- local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@WriteMail"))
	-- UIExtend.setNodeVisible(titleCCB,"mHomeBackNode",true)

	
	UIExtend.setCCLabelString(self.ccbfile,"mTargetPlatfomLabel","")

	
	--创建收件人昵称输入框
	self.mReceiverAddInputBoxNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mAddInputBoxNode")
	--self.mReceiverAddInputBoxNode:removeAllChildren()
	self.nameEdibox=UIExtend.createEditBox(self.ccbfile,"mInputBoxPic",self.mReceiverAddInputBoxNode,nil)--nameEditboxEventHandler)
	self.nameEdibox:setFontColor(RAGameConfig.COLOR.WHITE)
	self.nameEdibox:setInputMode(kEditBoxInputModeSingleLine)

	if self.nameStr then
		self.nameEdibox:setText(self.nameStr)
	end 
	self.nameEdibox:setEnabled(false)

	--创建发送内容输入框
	self.mMsgInputBoxNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mContentInputBoxNode")
	--self.mMsgInputBoxNode:removeAllChildren()
	self.contEdibox=UIExtend.createEditBox(self.ccbfile,"mContentOfMailBG",self.mMsgInputBoxNode,msgEditboxEventHandler)
	self.contEdibox:setFontColor(RAGameConfig.COLOR.BLACK)

	local ttf=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTargetPlatfomLabel")
	ttf:setZOrder(100)
	ttf:setFontSize(20)
	ttf:setFontName(RAGameConfig.DefaultFontName)

	--打开界面的时候设置是否可输入内容
	self.contEdibox:setEnabled(false)

	if not self.isSendAllianceMems then
		UIExtend.setNodeVisible(self.ccbfile,"mAddAddressBtn",true)
	else
		UIExtend.setNodeVisible(self.ccbfile,"mAddAddressBtn",false)
	end

	
end

function RAMailWritePage:registerMessageHandler()
    MessageManager.registerMessageHandler(topMayPageMsg,OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
 
end

function RAMailWritePage:removeMessageHandler()
    MessageManager.removeMessageHandler(topMayPageMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAMailWritePage:setEditBoxVisible(isVisible)
	self.nameEdibox:setVisible(isVisible)
	self.contEdibox:setVisible(isVisible)
end

function RAMailWritePage:checkIllegalMsg(edibox,cont)
	cont = RAStringUtil:replaceToStarForChat(cont)
	edibox:setText(cont)
end

function RAMailWritePage:Exit()
	self.nameStr=nil
	self.isSendAllianceMems = nil
	if self.nameEdibox then
		self.nameEdibox:removeFromParentAndCleanup(true)
		self.nameEdibox = nil
	end
	if self.contEdibox then
		self.contEdibox:removeFromParentAndCleanup(true)
		self.contEdibox = nil
	end
	self:removeMessageHandler()
	RAMailManager:clearSelectPlayerId()
	UIExtend.unLoadCCBFile(RAMailWritePage)
	
end

function RAMailWritePage:onClose()
	RARootManager.CloseCurrPage()
end


function RAMailWritePage:mCommonTitleCCB_onBack()
	CCLuaLog("RAMailWritePage:onBack")
	self:onClose()
end

function RAMailWritePage:onSendMailBtn()
	-- body
	--发送邮件
	local nameStr = self.nameEdibox:getText()
	local nameTab=RAStringUtil:split(nameStr,";")

	local contentMsg = self.contEdibox:getText()
	local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	if contentMsg=="" then --or nameStr==playerInfo.name then 
		local confirmData = {}
		confirmData.labelText = _RALang("@chatInputNil")
		RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
		return
	elseif nameStr=="" then
		local confirmData = {}
		confirmData.labelText = _RALang("@MailReceiverNullTips")
		RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
		return 
	elseif nameStr==playerInfo.raPlayerBasicInfo.name then
		local confirmData = {}
		confirmData.labelText = _RALang("@ReceiverIsMyMineTips")
		RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
		return 
	end

	if not self.isSendAllianceMems then
		RAMailManager:sendCreateChatRoomCmd(nameTab,contentMsg)
	else
		RAMailManager:sendAllianceMemsMailCmd(contentMsg)
    end
	
 --    local str = _RALang("@SendmailSuccess")
	-- RARootManager.ShowMsgBox(str)
	-- self:onClose()
end

function RAMailWritePage:onMailUIBtn()
	RARootManager.CloseAllPages()
end
function RAMailWritePage:onAddAddressBtn()

	local data={}
	data.callBack=function (names)
		self.nameEdibox:setText(names)
	end
	RARootManager.OpenPage("RAMailWritePageSelectDialog",data,true,true,true)
end


