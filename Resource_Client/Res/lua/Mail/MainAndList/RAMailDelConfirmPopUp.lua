RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil=RARequire("RAStringUtil")


local RAMailDelConfirmPopUp = BaseFunctionPage:new(...)

function RAMailDelConfirmPopUp:resetData()
    self.resultFun = nil 
end


function RAMailDelConfirmPopUp:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("RAMailDelConfirmPopUp.ccbi",RAMailDelConfirmPopUp)
	self.ccbfile = ccbfile
	UIExtend.setCCLabelString(ccbfile,"mPopUpLabel1",data.labelText or tostring(data));
	self.resultFun = data.resultFun
	self.title = data.title

	if data.lock then
		UIExtend.setControlButtonTitle(ccbfile,"mDelConfirmBtn",_RALang("@Confirm"))
	else
		UIExtend.setControlButtonTitle(ccbfile,"mDelConfirmBtn",_RALang("@ReceiveRewardAndDelete"))
	end 
	

	-- _RALang("@Confirm")
	self:AddNoTouchLayer(true)
	self:showTitle()

end

function RAMailDelConfirmPopUp:onCancelGoBackBtn()

    RARootManager.ClosePage("RAMailDelConfirmPopUp")
	if self.resultFun ~= nil then 
		self.resultFun(false)
	end
end

function RAMailDelConfirmPopUp:onDelConfirmBtn()
	
	RARootManager.ClosePage("RAMailDelConfirmPopUp")
	if self.resultFun ~= nil then 
		self.resultFun(true)
	end
end

function RAMailDelConfirmPopUp:showTitle()
	if self.title then
		UIExtend.setNodeVisible(self.ccbfile,"mPopUpTitle",true)
		UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle",self.title);
	else
		UIExtend.setNodeVisible(self.ccbfile,"mPopUpTitle",false)
	end 
end


function RAMailDelConfirmPopUp:onClose()
	RARootManager.ClosePage("RAMailDelConfirmPopUp")
end	


function RAMailDelConfirmPopUp:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RAMailDelConfirmPopUp