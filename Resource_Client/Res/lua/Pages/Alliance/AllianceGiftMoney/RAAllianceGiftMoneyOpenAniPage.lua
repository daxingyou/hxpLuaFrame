--抢红包成功后奖励弹框
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")

local RAAllianceGiftMoneyOpenAniPage = BaseFunctionPage:new(...)

function RAAllianceGiftMoneyOpenAniPage:Enter( data )
	-- body
	UIExtend.loadCCBFile("RAAllianceGiftMoneyOpenAni.ccbi",self)

	self.mDiamonds = data.diamonds

	self:refreshUI()

	self:playAni()
end

function RAAllianceGiftMoneyOpenAniPage:refreshUI()
	-- body
	UIExtend.setStringForLabel(self.ccbfile, {mDiamondsNum = self.mDiamonds})
end

function RAAllianceGiftMoneyOpenAniPage:playAni()
	-- body
	self.ccbfile:runAnimation("SuccessAni")
end

function RAAllianceGiftMoneyOpenAniPage:onReceiveBtn()
	-- body
	RARootManager.CloseCurrPage()
end

function RAAllianceGiftMoneyOpenAniPage:Exit()
	UIExtend.unLoadCCBFile(self)	
	self.ccbfile = nil
end

return RAAllianceGiftMoneyOpenAniPage