RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil=RARequire("RAStringUtil")

--提示框，包含一个文本和确认取消按钮
 -- local confirmPageTest = dynamic_require("RAConfirmPage")

 --    local data = {}
 --    data.labelText = "this is a test"
 --    data.resultFun = function(resultInfo)
 --        if resultInfo == true then 
 --            CCLuaLog("click confirm")
 --        else
 --            CCLuaLog("click cancel")
 --        end
 --    end

 --    confirmPageTest:Enter(data)
 --    ccbfile:addChild(confirmPageTest.ccbfile)


local RAConfirmPage = BaseFunctionPage:new(...)

function RAConfirmPage:resetData()
    self.resultFun = nil 
end


function RAConfirmPage:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("ccbi/RACommonPopUp1.ccbi",RAConfirmPage)
	self.ccbfile = ccbfile
	UIExtend.setCCLabelString(ccbfile,"mPopUpLabel1",data.labelText or tostring(data));
	self.resultFun = data.resultFun
	self.title = data.title
	self.yesNoBtn = data.yesNoBtn
	self.buttonLabel={yes=_RALang("@Confirm"),no=_RALang("@Cancel")}
	if data.buttonLabel then
		data.buttonLabel=data.buttonLabel
	end 
	
	self:AddNoTouchLayer(true)
	self:showTitle()
	self:showBtn()

end

function RAConfirmPage:onCancelBtn()

    RARootManager.ClosePage("RAConfirmPage")
	if self.resultFun ~= nil then 
		self.resultFun(false)
	end
end

function RAConfirmPage:onConfirmBtn()
	
	RARootManager.ClosePage("RAConfirmPage")
	if self.resultFun ~= nil then 
		self.resultFun(true)
	end
end

function RAConfirmPage:showTitle()
	if self.title then
		UIExtend.setNodeVisible(self.ccbfile,"mPopUpTitle",true)
		UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle",self.title);
	else
		UIExtend.setNodeVisible(self.ccbfile,"mPopUpTitle",false)
	end 
end
function RAConfirmPage:showBtn()
	if self.yesNoBtn then
		UIExtend.setNodeVisible(self.ccbfile,"mYesNoBtnNode",true)
		UIExtend.setNodeVisible(self.ccbfile,"mYesBtnNode",false)

		if self.buttonLabel then
			local yesBtnlabel=self.buttonLabel.yes
			local noBtnLabel =self.buttonLabel.no
			UIExtend.setControlButtonTitle(self.ccbfile, "mConfirmBtn",yesBtnlabel,true)
			UIExtend.setControlButtonTitle(self.ccbfile, "mCancelBtn",noBtnLabel,true)
		end 
		

	else
		UIExtend.setNodeVisible(self.ccbfile,"mYesNoBtnNode",false)
		UIExtend.setNodeVisible(self.ccbfile,"mYesBtnNode",true)
	end 
end

function RAConfirmPage:onClose()
	RARootManager.ClosePage("RAConfirmPage")
end	

function RAConfirmPage:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RAConfirmPage