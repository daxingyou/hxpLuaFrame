RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RAFightDefine')
local UIExtend = RARequire('UIExtend')
local RAFightStartPage = BaseFunctionPage:new(...)

function RAFightStartPage:Enter()
	self.ccbfile = UIExtend.loadCCBFile("RABattleChapterPage.ccbi", RAFightStartPage)
	-- self:registerMessage()

	self.mBestInHistoryNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mBestInHistoryNum')
	self.mBestInHistoryNum:setString(_RALang("@TheLevelNum",8))

	self.mBestInWeeksNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mBestInWeeksNum')
	self.mBestInWeeksNum:setString(_RALang("@TheLevelNum",8))

	self.mHistoryRankNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHistoryRankNum')
	self.mHistoryRankNum:setString(_RALang("@NotInRank"))

	self.mWeeksRankNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mWeeksRankNum')
	self.mWeeksRankNum:setString(_RALang("@NotInRank"))

	self.mCurrentNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCurrentNum')
	self.mCurrentNum:setString(_RALang("@CurrentLevelDes",1))
	
	local titleName = _RALang("@TheLevel")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mCommonTitleCCB"),'mTitle',titleName) 
end

function RAFightStartPage:onChallengeBtn()
	local RARootManager = RARequire('RARootManager')	
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.SHOW_TROOP})
	MessageManager.sendMessageInstant(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
	RARootManager.ClosePage("RAFightStartPage")
end

function RAFightStartPage:registerMessage()
    -- MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end

function RAFightStartPage:removeMessageHandler()
    -- MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end

function RAFightStartPage:onBack()
	CCLuaLog('.... onBack')
end

function RAFightStartPage:Exit()
    self:removeMessageHandler()
    UIExtend.unLoadCCBFile(self) 
end


return RAFightStartPage