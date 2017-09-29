
RARequire('extern')
RARequire('RAFightDefine')
RARequire("MessageDefine")
RARequire("MessageManager")
local RABattleSceneManager = RARequire('RABattleSceneManager')
local RAFightManager = RARequire('RAFightManager')
local RARootManager = RARequire('RARootManager')
local EnterFrameMananger = RARequire('EnterFrameMananger')
local orignScale = CCDirector:sharedDirector():getDeltaTimeScale()

local RAFightPlay = class('RAFightPlay',{
    curState = FIGHT_PLAY_STATE_TYPE.NONE,--当前状态
    handlers = nil,
    curCameraIndex = 0
  }
)

--开始页面
local RAFightPlay_State_StartPage = class('RAFightPlay_State_StartPage',RARequire("RAFU_Object"))
function RAFightPlay_State_StartPage:Enter()
	if self.instantFight then
		MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.SHOW_TROOP})
		MessageManager.sendMessageInstant(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
		return
	end

    local RARootManager = RARequire('RARootManager')
    RARootManager.OpenPage("RAFightStartPage", nil, false, true, false, true)
end

function RAFightPlay_State_StartPage:Exit()   
end

function RAFightPlay_State_StartPage:ctor(instantFight)
	self.instantFight = instantFight
end

--初始化战场
local RAFightPlay_State_InitBattle = class('RAFightPlay_State_InitBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_InitBattle:Enter(data)

    if data and data.isReplay == true then 
        RABattleSceneManager:resetScene(RAFightManager.initActions)
        --当状态为重播是设为标志位
        RAFightManager:setIsReplay(data.isReplay)
    else
        --当状态为重播是设为标志位
        RAFightManager:setIsReplay(false)
        RABattleSceneManager:cleanScene()
        RABattleSceneManager:initAllBattleUnits(RAFightManager.initActions)   
    end

    RAFightManager:resetAllBattleUnitData()
    RAFightPlay:changeSpeedScale(1)
    local RAGameConfig = RARequire("RAGameConfig")
    
    local RAFightUI = nil
    if RAGameConfig.BattleDebug == 0 then
        RAFightUI = RARequire('RAFightUI')
    else
        RAFightUI = RARequire('RAFightUI')
        -- RAFightUI = RARequire('RAFightDebugUI') 
    end
    RAFightUI:init()
     --音乐相关
    RARequire("RAFightSoundSystem"):playPrepareMusic()
    -- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_Update_Fight_BloodBar, {})
    if data and data.isReplay == true then 
        RAFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.SHOW_TROOP)
    else
        RAFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.START_PAGE)    
    end
end

function RAFightPlay_State_InitBattle:Exit()   
end

--开始战斗
local RAFightPlay_State_StartBattle = class('RAFightPlay_State_StartBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_StartBattle:Enter()
    -- RARootManager.ShowMsgBox(_RALang("@startBattle") ..'  time: ' .. RAFightManager.battleCalTime)
    RABattleSceneManager:attackersIdle()
    RAFightManager:initExecuteData() 
    RARequire("RAFightSoundSystem"):playFightMusic()
    RAFightPlay:showFight()
end

function RAFightPlay_State_StartBattle:Exit() 
    RAFightPlay:stopMoveFightCamera()  
end

--开始页面
local RAFightPlay_State_EndBattle = class('RAFightPlay_State_EndBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_EndBattle:Enter()
    local RAFightUI = RARequire('RAFightUI')
    -- RARootManager.ShowMsgBox(_RALang("@endBattle"))
    RAFightManager:resetExecuteData()

    if RAFightManager.winResult == ATTACKER then 
        local defenderCount = RAFightManager:getCount(DEFENDER)
        RAFightUI:setBarValue(DEFENDER,0,defenderCount)
    else
        local attackCount = RAFightManager:getCount(ATTACKER)
        RAFightUI:setBarValue(ATTACKER,0,attackCount)
    end 

    local RARootManager = RARequire('RARootManager')
    RARootManager.OpenPage("RAFightResultPage", {rewardPB = self.rewardPB,winResult = RAFightManager.winResult}, false, true, false) 
end

function RAFightPlay_State_EndBattle:Exit()   
end

function RAFightPlay_State_EndBattle:ctor(rewardPB)
	self.rewardPB = rewardPB
end

--开始页面
local RAFightPlay_State_ShowTroop = class('RAFightPlay_State_ShowTroop',RARequire("RAFU_Object"))
function RAFightPlay_State_ShowTroop:Enter()
    RAFightPlay:showTroop()
end

function RAFightPlay_State_ShowTroop:Exit()   
    RAFightPlay:stopMoveFightCamera()
end

--开始页面
local RAFightPlay_State_TroopWalk = class('RAFightPlay_State_TroopWalk',RARequire("RAFU_Object"))
function RAFightPlay_State_TroopWalk:Enter()
    -- RAFightPlay:showTroop()
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    RABattleSceneManager:attackersWalk()
end

function RAFightPlay_State_TroopWalk:Exit()   
end


function RAFightPlay:loadFightUnits()
    return  RABattleSceneManager:initBattleUnitsByStep(RAFightManager.initActions) 
end

--战斗播放
function RAFightPlay:init(instantFight, rewardPB)
    self:registerMessage()
    self.curState = nil

    self:_initStateManager(instantFight, rewardPB)

    -- self.handlers = {}
    -- self.handlers[FIGHT_PLAY_STATE_TYPE.INIT_BATTLE] = self.initBattle
    -- self.handlers[FIGHT_PLAY_STATE_TYPE.SHOW_TROOP] = self.showTroop
    -- self.handlers[FIGHT_PLAY_STATE_TYPE.START_BATTLE] = self.startBattle
    -- self.handlers[FIGHT_PLAY_STATE_TYPE.END_BATTLE] = self.endBattle
end

function RAFightPlay:changeSpeedScale(scale)
    self.currentScale  = scale
    CCDirector:sharedDirector():setDeltaTimeScale(self.currentScale*orignScale)
end

function RAFightPlay:getSpeedScale()
	return self.currentScale
end

--初始化状态机
function RAFightPlay:_initStateManager(instantFight, rewardPB)
    self.stateManager = {}
    -- self.stateManager[FIGHT_PLAY_STATE_TYPE.START_PAGE] = RAFightPlay_State_StartPage.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.START_PAGE] = RAFightPlay_State_StartPage.new(instantFight)
    self.stateManager[FIGHT_PLAY_STATE_TYPE.INIT_BATTLE] = RAFightPlay_State_InitBattle.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.START_BATTLE] = RAFightPlay_State_StartBattle.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.END_BATTLE] = RAFightPlay_State_EndBattle.new(rewardPB)
    self.stateManager[FIGHT_PLAY_STATE_TYPE.SHOW_TROOP] = RAFightPlay_State_ShowTroop.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.TROOP_WALK] = RAFightPlay_State_TroopWalk.new()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_BattleScene.MSG_FightPlay_State_Change then
        RAFightPlay:updateState(message.state,nil,message)
    elseif message.messageID == MessageDef_BattleScene.MSG_Change_Speed_Scale then
        RAFightPlay:changeSpeedScale(message.scale) 
    end
end 

function RAFightPlay:Exit()
    CCDirector:sharedDirector():setDeltaTimeScale(orignScale)
	if self.curState and self.stateManager then
		self.stateManager[self.curState]:Exit()
	end
    self:removeMessageHandler()
    self.OnReceiveMessage = nil
end

function RAFightPlay:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_Change_Speed_Scale,OnReceiveMessage)
end

function RAFightPlay:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_Change_Speed_Scale,OnReceiveMessage)
    MessageManager.removeAllMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished)
end

function RAFightPlay:startBattle()
    RARootManager.ShowMsgBox(_RALang("@startBattle"))
    RAFightManager:initExecuteData() 
end

function RAFightPlay:endBattle()
    RARootManager.ShowMsgBox(_RALang("@endBattle"))
    RAFightManager:resetExecuteData() 
    local RARootManager = RARequire('RARootManager')
    RARootManager.OpenPage("RABattleResultPage", nil, false, true, true)
end

function RAFightPlay:showTroop()
    self.curCameraIndex = 1
    self.initCameraPos = RAFightManager:getInitCameraPos()

    local OnReceiveMessage = function (message)
        self:moveCamera()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)
    self:moveCamera()
end

function RAFightPlay:showFight()
    self.curCameraIndex = 1
    self.initCameraPos = RAFightManager:getFightCameraPos()

    local OnReceiveMessage = function (message)
        self:moveFightCamera()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)
    self:moveFightCamera()
end

function RAFightPlay:moveFightCamera()
    local nextPos = self:getNextCamera()
    if nextPos == nil then 
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)      
        -- self:updateState(FIGHT_PLAY_STATE_TYPE.START_BATTLE)
    else
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
    end 
end

function RAFightPlay:stopMoveFightCamera()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)
    self.initCameraPos = {} 
end

function RAFightPlay:moveCamera()
    local nextPos = self:getNextCamera()
    if nextPos == nil then 
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)      
        -- self:updateState(FIGHT_PLAY_STATE_TYPE.START_BATTLE)
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_FightPlay_State_Change, {state = FIGHT_PLAY_STATE_TYPE.START_BATTLE})
    else
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
    end 
end

function RAFightPlay:Execute(dt)
    
    -- if self.curState >= FIGHT_PLAY_STATE_TYPE.START_BATTLE then 
        RABattleSceneManager:Execute(dt)
    -- end 

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

function RAFightPlay:updateState(state,isforce,data)

    if isforce ~= true and self.curState == state then 
        return 
    end

    if self.stateManager[state] == nil then
         RALogError("RAFightPlay:changeState  state is nor right: "..state)
        return
    end
    if self.curState then        
        self.stateManager[self.curState]:Exit()
    end
    self.curState = state
    if self.curState then
        self.stateManager[self.curState]:Enter(data)
    end 
end

return RAFightPlay