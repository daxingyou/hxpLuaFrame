--[[region RAFU_State_BaseCreate.lua
战斗单元的基础创建类
--用来处理战斗单元 创建另外一个战斗单元的逻辑
--如鲍里斯创建黑影战机，V3导弹车创建V3火箭
    更详细点的逻辑如下：
    CreateAction   
        没有attackAction 和damage
            1. 创建的准备时间
            2. 创建v3_head battleUnit battleUnitData      cfgdata
                initAction  (position, data)
            3. add to battleScene 
--Date 2016/12/16
--Author zhenhui
]]

FU_CREATE_ACTION_STATE = {
    NONE = 0,
    PREPARE = 1,
    CREATE = 2
}

local RAFU_State_BaseCreate = class('RAFU_State_BaseCreate',RARequire("RAFU_Object"))

function RAFU_State_BaseCreate:ctor(unit)
    self.fightUnit = unit;
    self.curState = FU_CREATE_ACTION_STATE.NONE

end

function RAFU_State_BaseCreate:release()
    self.fightUnit = nil;
    self:Exit()
    self.curState = FU_CREATE_ACTION_STATE.NONE

end

function RAFU_State_BaseCreate:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    --设置准备时间以及生命周期时间
    self.prepareTime = self.fightUnit.data.confData.glidePeriod or 0
    self.lifeTime = self.prepareTime + 0.2
    self:EnterPrepare()
end

--创建之前的准备阶段
function RAFU_State_BaseCreate:EnterPrepare()
    
    self.curState = FU_CREATE_ACTION_STATE.PREPARE
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = self.data.targetUnit
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)
    local direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)

    --设置移动方向
    self.fightUnit:setDir(direction)

    --自身的动作相关
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction)        
    end
end

--真正的创建战斗单元数据
function RAFU_State_BaseCreate:EnterCreate()
    self.curState = FU_CREATE_ACTION_STATE.CREATE
    
    --发送消息，将战斗单元创建并进入战斗单元的管理类中
    local message = {}
    message.createActionData = self.data
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT, message)

end


function RAFU_State_BaseCreate:Execute(dt)
    self.frameTime = self.frameTime + dt
    --切换到创建状态
    if self.frameTime > self.prepareTime then
        if self.curState == FU_CREATE_ACTION_STATE.PREPARE then
            self:EnterCreate()
        end
    end

    if self.frameTime > self.lifeTime and self.localAlive then
        self:Exit()
    end
end

function RAFU_State_BaseCreate:Exit()
    if self.localAlive == true then
        self.localAlive = false
    end

end

return RAFU_State_BaseCreate
--endregion
