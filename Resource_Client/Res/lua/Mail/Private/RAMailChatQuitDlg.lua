RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil=RARequire("RAStringUtil")



local RAMailChatQuitDlg = BaseFunctionPage:new(...)

function RAMailChatQuitDlg:resetData()
    self.resultFun = nil 
end


function RAMailChatQuitDlg:Enter(data)
	self:resetData()
	self.resultFun = data.callBack
	local ccbfile = UIExtend.loadCCBFile("RAMailGroupChatExitPopUpV6.ccbi",RAMailChatQuitDlg)
	self.ccbfile = ccbfile
	UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@DeleteAndExit"))

end

function RAMailChatQuitDlg:onCancel()

    RARootManager.ClosePage("RAMailChatQuitDlg")
	if self.resultFun ~= nil then 
		self.resultFun(false)
	end
end

function RAMailChatQuitDlg:onConfirm()
	
	RARootManager.ClosePage("RAMailChatQuitDlg")
	if self.resultFun ~= nil then 
		self.resultFun(true)
	end
end

function RAMailChatQuitDlg:onClose()
	RARootManager.ClosePage("RAMailChatQuitDlg")
end	

function RAMailChatQuitDlg:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RAMailChatQuitDlg