--[[region RAFU_State_BorisCreate.lua
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

local RAFU_State_BaseCreate = RARequire("RAFU_State_BaseCreate")

local RAFU_State_BorisCreate = class('RAFU_State_BorisCreate',RAFU_State_BaseCreate)



function RAFU_State_BorisCreate:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    self.borisFlyTime = 5
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    --设置准备时间以及生命周期时间
    self.prepareTime = self.fightUnit.data.confData.glidePeriod  + self.borisFlyTime
    self.lifeTime = self.prepareTime + 0.2
    self:EnterPrepare()
end


--创建之前的准备阶段
function RAFU_State_BorisCreate:EnterPrepare()
    --移动方向
    --RALogInfo("RAFU_State_BorisCreate:EnterPrepare() -- self.data.targetUnit: "..self.data.targetUnit)
    self.curState = FU_CREATE_ACTION_STATE.PREPARE
    local RABattleSceneManager = RARequire("RABattleSceneManager")

    local borisCreateDataCount = #self.data.data
    --boris创建的只可能为1个
    assert(borisCreateDataCount ==1 ,"false")
    local oneData = self.data.data[1]
    
    local targetId = oneData.targetUnit
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:tileToSpace(oneData.targetPos)
    local direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)

    --设置移动方向
    self.fightUnit:setDir(direction)

    --自身的动作相关
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction)        
    end

    --让target id变成闪红
    if targetId ~= nil then
        local message = {}
        message.unitId = targetId
        message.param = {
            lifeTime = self.prepareTime
        }
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_TARGET, message)
    end
    

    --创建一个cclayer联线
    local line = CCLayerColor:create(ccc4(255,0,0,200))
    line:setContentSize(CCSizeMake(2,2))
    line:setPosition(targetSpacePos.x,targetSpacePos.y)
    line:setAnchorPoint(0,0)

    self.startPos = curSpacePos
    self.endPos = targetSpacePos
    local Utilitys = RARequire("Utilitys")
    local dis = Utilitys.getDistance(self.startPos,self.endPos)
    self.line = line
    local scale = dis / 2
    if scale < 1 then scale = 1 end
    self.line:setScaleX(scale)
    local degree = Utilitys.getDegree(self.startPos.x-self.endPos.x, self.startPos.y-self.endPos.y)
    self.line:setRotation(-degree)

    local tag = self.fightUnit.id
    self.line:setTag(tag)

    local RABattleScene = RARequire("RABattleScene")
    RABattleScene.mBattleEffectLayer:addChild(self.line)

     --发送消息，将战斗单元创建并进入战斗单元的管理类中
    local message = {}
    message.createActionData = self.data
    message.initVisible = false
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT, message)

end

--真正的创建战斗单元数据
function RAFU_State_BorisCreate:EnterCreate()
    self.curState = FU_CREATE_ACTION_STATE.CREATE
    
    local direction = self.fightUnit:getDir()
    --自身的动作相关
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_IDLE,direction)        
    end

    if self.line then
        RA_SAFE_REMOVEFROMPARENT(self.line)
        self.line = nil
    end

   


end


function RAFU_State_BorisCreate:Exit()
    if self.localAlive == true then
        self.localAlive = false
        if self.line then
            RA_SAFE_REMOVEFROMPARENT(self.line)
            self.line = nil
        end
    end

end


return RAFU_State_BorisCreate
--endregion
