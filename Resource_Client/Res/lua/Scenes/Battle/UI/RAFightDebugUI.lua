RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RAFightDefine')
local UIExtend = RARequire('UIExtend')
local RAFightDebugUI = BaseFunctionPage:new(...)

function RAFightDebugUI:Enter()
	self.mRootNode = UIExtend.loadCCBFileWithOutPool("BattleTestPage.ccbi", self)

	self:registerMessage()
end

function RAFightDebugUI:registerMessage()
    -- MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end

function RAFightDebugUI:removeMessageHandler()
    -- MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end


function RAFightDebugUI:init()

end

function RAFightDebugUI:onPlayBtn()
	-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.SHOW_TROOP})
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.START_BATTLE})

	-- local RARootManager = RARequire('RARootManager')
	-- RARootManager.OpenPage("RAFightResultPage", nil, false, true, false, true)
end

function RAFightDebugUI:onSkipBtn()
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.END_BATTLE})
end

function RAFightDebugUI:onReplayBtn()
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.INIT_BATTLE})
end

function RAFightDebugUI:Exit()
    self:removeMessageHandler()
    self.ccbfile:removeAllChildren()
    UIExtend.unLoadCCBFile(self) 
end


return RAFightDebugUI