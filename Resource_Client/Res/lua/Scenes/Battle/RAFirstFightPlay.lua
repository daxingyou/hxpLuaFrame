
RARequire('extern')
RARequire('RAFightDefine')
RARequire("MessageDefine")
RARequire("MessageManager")
local RABattleSceneManager = RARequire('RABattleSceneManager')
local RAFightManager = RARequire('RAFightManager')
local RARootManager = RARequire('RARootManager')
local EnterFrameMananger = RARequire('EnterFrameMananger')
local battle_first_battle_conf = RARequire('battle_first_battle_conf')

local RAFirstFightPlay = class('RAFirstFightPlay',{
    curState = FIGHT_PLAY_STATE_TYPE.NONE,--当前状态
    handlers = nil,
    curCameraIndex = 0
  }
)

--初始化战场
local RAFightPlay_State_InitBattle = class('RAFightPlay_State_InitBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_InitBattle:Enter(data)
     --音乐相关
    RABattleSceneManager:cleanScene()
    RABattleSceneManager:initAllBattleUnits(RAFightManager.initActions)   
    RAFightManager:resetAllBattleUnitData()

    for k,v in pairs(RABattleSceneManager.battleUnits) do
        if v.data.unitType == DEFENDER then 
            v:changeMaskColor(MaskColors.Purple)
        end     
    end

    RARequire("RAFightSoundSystem"):playPrepareMusic()
    RAFirstFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.SHOW_TROOP)
end

function RAFightPlay_State_InitBattle:Exit()   
end

--开始战斗
local RAFightPlay_State_StartBattle = class('RAFightPlay_State_StartBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_StartBattle:Enter()
    RAFightManager:initExecuteData()
    RARequire("RAFightSoundSystem"):playFightMusic()
    RAFirstFightPlay:showFight() 
end

function RAFightPlay_State_StartBattle:Exit()   
end


local RAFightPlay_State_EndBattle = class('RAFightPlay_State_EndBattle',RARequire("RAFU_Object"))
function RAFightPlay_State_EndBattle:Enter()
    RAFightManager:resetExecuteData()
    --衔接剧情新手对话：add by xinghui
    local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
    RAMissionBarrierManager:gotoNextStep()

    --RAFirstFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.SHOW_TOWER)
end

function RAFightPlay_State_EndBattle:Exit()   
end

function RAFightPlay_State_EndBattle:ctor()
end

--展示军队
local RAFightPlay_State_ShowTroop = class('RAFightPlay_State_ShowTroop',RARequire("RAFU_Object"))
function RAFightPlay_State_ShowTroop:Enter()
    RAFirstFightPlay:showTroop()
end

function RAFightPlay_State_ShowTroop:Exit()   
end

--心灵塔动画 
local RAFightPlay_State_ShowTower = class('RAFightPlay_State_ShowTower',RARequire("RAFU_Object"))
function RAFightPlay_State_ShowTower:Enter()
    self:moveToTower()
end

--镜头移动到心灵塔
function RAFightPlay_State_ShowTower:moveToTower()

    local OnReceiveMessage = function (message)
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)  
        self:openTower()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)

    local nextPos = battle_first_battle_conf.moveToTowerInfo
    MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
end

--打开心灵探测
function RAFightPlay_State_ShowTower:openTower()
    local unit =  RABattleSceneManager:getUnitByConfId(battle_first_battle_conf.towerId)
    if unit == nil then 
        --灭有配置心灵塔
        self:showCircle() 
    end 
    self.unit = unit
    local direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP

    local attackFun = function()
        for boneName,boneController in pairs(unit.boneManager) do
            boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction,nil,false,true)        
        end
        self:showCircle()           
    end

    local param = {
        callback =  attackFun
    }
        
    for boneName,boneController in pairs(unit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_RUN,direction,param,false,true)        
    end
end

--显示效果圈
function RAFightPlay_State_ShowTower:showCircle()
    local UIExtend = RARequire('UIExtend')
    local callback = function ()
       self.ccbHandler = {}
       self.circleCCb = UIExtend.loadCCBFile("RABattle_Effect_Behit_7.ccbi",self.ccbHandler)
       local pos = self.unit:getPosition()
       self.circleCCb:setPosition(pos.x,pos.y)
       RABattleSceneManager.battleScene.mBattleUnitDieLayer:addChild(self.circleCCb)

       local callbacktwo = function ()
           self.ccbHandler2 = {}
           self.circleCCb2 = UIExtend.loadCCBFile("RABattle_Effect_Behit_7.ccbi",self.ccbHandler2)
           local pos = self.unit:getPosition()
           self.circleCCb2:setPosition(pos.x,pos.y)
           RABattleSceneManager.battleScene.mBattleUnitDieLayer:addChild(self.circleCCb2)

           local callbackthree = function ()
               self:changeTroopColor()
           end
           RABattleSceneManager:performWithDelay(callbackthree,battle_first_battle_conf.showSecondCircle)
       end
       RABattleSceneManager:performWithDelay(callbacktwo,battle_first_battle_conf.showFirstCircle)
    end
    RABattleSceneManager:performWithDelay(callback,battle_first_battle_conf.attckTime)
end

function RAFightPlay_State_ShowTower:changeTroopColor()

    local OnReceiveMessage = function (message)
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage) 

        for k,v in pairs(RABattleSceneManager.battleUnits) do
            if v.isAlive then 
                v:changeMaskColor(MaskColors.Purple)
            end     
        end 
        -- RARootManager.ShowMsgBox(_RALang("@changeColor"))
        RAFirstFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.SHOW_FIRST_ENDTALK)
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)

    local nextPos = battle_first_battle_conf.moveToArmy
    MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
end

function RAFightPlay_State_ShowTower:Exit()
     local UIExtend = RARequire('UIExtend')
     UIExtend.unLoadCCBFile(self.ccbHandler)
     UIExtend.unLoadCCBFile(self.ccbHandler2)    
end

--展示军队
local RAFightPlay_State_FirstEndTalk = class('RAFightPlay_State_FirstEndTalk',RARequire("RAFU_Object"))
function RAFightPlay_State_FirstEndTalk:Enter()
    --衔接剧情新手对话：add by xinghui
    local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")
    RAMissionBarrierManager:gotoNextStep()
    --RARootManager.ShowMsgBox(_RALang("显示新手对话"))
end

function RAFightPlay_State_FirstEndTalk:Exit()   
end

--战斗播放
function RAFirstFightPlay:init(instantFight, rewardPB)
    self:registerMessage()
    self.curState = nil

    self:_initStateManager(instantFight, rewardPB)
end

function RAFirstFightPlay:getSpeedScale()
	return 1
end

--初始化状态机
function RAFirstFightPlay:_initStateManager(instantFight, rewardPB)
    self.stateManager = {}
    
    self.stateManager[FIGHT_PLAY_STATE_TYPE.INIT_BATTLE] = RAFightPlay_State_InitBattle.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.START_BATTLE] = RAFightPlay_State_StartBattle.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.END_BATTLE] = RAFightPlay_State_EndBattle.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.SHOW_TROOP] = RAFightPlay_State_ShowTroop.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.SHOW_TOWER] = RAFightPlay_State_ShowTower.new()
    self.stateManager[FIGHT_PLAY_STATE_TYPE.SHOW_FIRST_ENDTALK] = RAFightPlay_State_FirstEndTalk.new()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_BattleScene.MSG_FightPlay_State_Change then
        RAFirstFightPlay:updateState(message.state,nil,message)
    end
end 

function RAFirstFightPlay:Exit()
	if self.curState and self.stateManager then
		self.stateManager[self.curState]:Exit()
	end
    self:removeMessageHandler()
    self.OnReceiveMessage = nil
end

function RAFirstFightPlay:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
end

function RAFirstFightPlay:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change,OnReceiveMessage)
    MessageManager.removeAllMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished)
end


function RAFirstFightPlay:showTroop()
    self.curCameraIndex = 1
    self.initCameraPos = RAFightManager:getInitCameraPos()

    local OnReceiveMessage = function (message)
        self:moveCamera()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)

    self:moveCamera()
end

function RAFirstFightPlay:moveCamera()
    local nextPos = self:getNextCamera()
    if nextPos == nil then 
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)      
        self:updateState(FIGHT_PLAY_STATE_TYPE.START_BATTLE)
    else
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
    end 
end

function RAFirstFightPlay:showFight()
    self.curCameraIndex = 1
    self.initCameraPos = RAFightManager:getFightCameraPos()

    local OnReceiveMessage = function (message)
        self:moveFightCamera()
    end
    self.OnReceiveMessage = OnReceiveMessage
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,OnReceiveMessage)
    self:moveFightCamera()
end

function RAFirstFightPlay:moveFightCamera()
    local nextPos = self:getNextCamera()
    if nextPos == nil then 
        MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Finished,self.OnReceiveMessage)      
        -- self:updateState(FIGHT_PLAY_STATE_TYPE.START_BATTLE)
    else
        MessageManager.sendMessage(MessageDef_BattleScene.MSG_CameraMoving_Start,{data = nextPos})
    end 
end

function RAFirstFightPlay:Execute(dt)
    
    -- if self.curState >= FIGHT_PLAY_STATE_TYPE.START_BATTLE then 
        RABattleSceneManager:Execute(dt)
    -- end 

    if self.curState == FIGHT_PLAY_STATE_TYPE.START_BATTLE then 
        RAFightManager:Execute(dt)
    end
end

function RAFirstFightPlay:getNextCamera()
    if self.curCameraIndex > #self.initCameraPos then 
        return nil
    end 

    local pos = self.initCameraPos[self.curCameraIndex]
    self.curCameraIndex = self.curCameraIndex + 1
    return pos
end

function RAFirstFightPlay:getCurrentState()
    return self.curState
end

function RAFirstFightPlay:updateState(state,isforce,data)

    if isforce ~= true and self.curState == state then 
        return 
    end

    if self.stateManager[state] == nil then
         RALogError("RAFirstFightPlay:changeState  state is nor right: "..state)
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
return RAFirstFightPlay