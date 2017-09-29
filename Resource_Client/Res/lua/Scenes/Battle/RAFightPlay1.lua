RARequire('extern')
RARequire('RAFightDefine')
RARequire("MessageDefine")
RARequire("MessageManager")
local RABattleSceneManager = RARequire('RABattleSceneManager')
local RAFightManager = RARequire('RAFightManager')
local RARootManager = RARequire('RARootManager')
local EnterFrameMananger = RARequire('EnterFrameMananger')
local RAFightPlay = class('RAFightPlay',{
    curState = FIGHT_PLAY_STATE_TYPE.NONE,--当前状态
    handlers = nil,
    curCameraIndex = 0, 
  }
)
--战斗播放
function RAFightPlay:init()
    self:registerMessage()
    self.curState = FIGHT_PLAY_STATE_TYPE.NONE
    self.handlers = {}
    self.handlers[FIGHT_PLAY_STATE_TYPE.INIT_BATTLE] = self.initBattle
    self.handlers[FIGHT_PLAY_STATE_TYPE.SHOW_TROOP] = self.showTroop
    self.handlers[FIGHT_PLAY_STATE_TYPE.START_BATTLE] = self.startBattle
    self.handlers[FIGHT_PLAY_STATE_TYPE.END_BATTLE] = self.endBattle
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_BattleScene.MSG_FightPlay_State_Change then
        RAFightPlay:updateState(message.state)
    end
end 

function RAFightPlay:exit()
    self:removeMessageHandler()
end

function RAFightPlay:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
end

function RAFightPlay:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
end

function RAFightPlay:startBattle()
    RARootManager.ShowMsgBox(_RALang("@startBattle"))
    RAFightManager:initExecuteData() 
end

function RAFightPlay:endBattle()
    RARootManager.ShowMsgBox(_RALang("@endBattle"))
    RAFightManager:resetExecuteData() 
end

function RAFightPlay:initBattle()
    RABattleSceneManager:cleanScene()
    RABattleSceneManager:initAllBattleUnits(RAFightManager.initActions)
end

function RAFightPlay:showTroop()
    self.curCameraIndex = 1
    self.initCameraPos = RAFightManager:getInitCameraPos()

    local OnReceiveMessage = function (message)
        self:moveCamera()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)
    -- RARootManager.ShowMsgBox(_RA)
    RARootManager.ShowMsgBox(_RALang("@showTroop"))
    self:moveCamera()
end

function RAFightPlay:moveCamera()
    local nextPos = self:getNextCamera()
    if nextPos == nil then 
        -- RAFightManager.isEnd = false
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)      
        self:updateState(FIGHT_PLAY_STATE_TYPE.START_BATTLE)
    else
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
    end 
end

function RAFightPlay:Execute(dt)
    RABattleSceneManager:Execute(dt)
    if self.curState == FIGHT_PLAY_STATE_TYPE.START_BATTLE then 
        RAFightManager:Execute(dt)
    end
end

function RAFightPlay:getNextCamera()
    if self.curCameraIndex > #self.initCameraPos then 
        return nil
    end 

    local pos = self.initCameraPos[self.curCameraIndex]
    self.curCameraIndex = self.curCameraIndex + 1
    return pos
end

function RAFightPlay:getCurrentState()
    return self.curState
end

function RAFightPlay:updateState(state,isforce)
    
    if isforce ~= true and self.curState == state then 
        return 
    end 

    local handler = self.handlers[state]
    if handler == nil then 
        return
    end 

    self.curState = state
    handler(self)
end





return RAFightPlay