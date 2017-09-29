RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')

local RAMailChatEditNameDlg = BaseFunctionPage:new(...)

function RAMailChatEditNameDlg:resetData()
    self.resultFun = nil 
end

function nameEditboxEventHandler(eventType, node)
	if eventType == "ended" then	
		local txt = node:getText()
		RAMailChatEditNameDlg:checkIllegalMsg(node,txt)
	end
end

function RAMailChatEditNameDlg:checkIllegalMsg(edibox,cont)
	local RAStringUtil=RARequire("RAStringUtil")
	cont = RAStringUtil:replaceToStarForChat(cont)
	edibox:setText(cont)
end

function RAMailChatEditNameDlg:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("RAMailGroupChatEditPopUpV6.ccbi",RAMailChatEditNameDlg)
	self.ccbfile = ccbfile
	self.resultFun = data.callBack
	self.name = data.name
	self:init()
end

function RAMailChatEditNameDlg:init()
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@EditChatRoomName"))

	--输入框
	self.mInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mInputNode")
	--self.mReceiverAddInputBoxNode:removeAllChildren()
	local RAGameConfig = RARequire("RAGameConfig")
	self.nameEdibox=UIExtend.createEditBox(self.ccbfile,"mInputPic",self.mInputNode,nameEditboxEventHandler)
	self.nameEdibox:setFontColor(RAGameConfig.COLOR.BLACK)
	self.nameEdibox:setInputMode(kEditBoxInputModeSingleLine)

	self.nameEdibox:setText(self.name)
end


function RAMailChatEditNameDlg:onConfirm()
	
	RARootManager.ClosePage("RAMailChatEditNameDlg")
	if self.resultFun ~= nil then 
		local name  =self.nameEdibox:getText()
		self.resultFun(name)
	end
end

function RAMailChatEditNameDlg:onClose()
	RARootManager.ClosePage("RAMailChatEditNameDlg")
end	

function RAMailChatEditNameDlg:Exit()
	self.nameEdibox:removeFromParentAndCleanup(true)
    self.nameEdibox = nil

	UIExtend.unLoadCCBFile(self)
end

return RAMailChatEditNameDlg