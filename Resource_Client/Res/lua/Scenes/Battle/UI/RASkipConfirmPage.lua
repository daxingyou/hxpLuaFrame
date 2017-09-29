RARequire("BasePage")
RARequire("MessageManager")
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil=RARequire("RAStringUtil")

local RASkipConfirmPage = BaseFunctionPage:new(...)


function RASkipConfirmPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RACommonPopUp1V2.ccbi",RASkipConfirmPage)
	self.ccbfile = ccbfile
	UIExtend.getCCNodeFromCCB(self.ccbfile,'mYesBtnNode'):setVisible(false)

	self.mPopUpTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mPopUpTitle')
	self.mPopUpTitle:setString(_RALang("@Confirm"))

	self.mPopUpLabel1 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mPopUpLabel1')
	self.mPopUpLabel1:setString(_RALang("@SkipBattleInfo"))
end


function RASkipConfirmPage:onConfirmBtn()
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.END_BATTLE})
	RARootManager.ClosePage("RASkipConfirmPage")
end


function RASkipConfirmPage:onCancelBtn()
	RARootManager.ClosePage("RASkipConfirmPage")
end	

function RASkipConfirmPage:Execute()
end	

function RASkipConfirmPage:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RASkipConfirmPage