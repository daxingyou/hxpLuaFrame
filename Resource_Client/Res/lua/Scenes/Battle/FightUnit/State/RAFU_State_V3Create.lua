--[[region RAFU_State_V3Create.lua
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
--Date 2016/12/26
--Author qinho
]]

local RAFU_State_BaseCreate = RARequire("RAFU_State_BaseCreate")
RARequire('BattleField_pb')

local RAFU_State_V3Create = class('RAFU_State_V3Create',RAFU_State_BaseCreate)


--创建之前的准备阶段
function RAFU_State_V3Create:EnterPrepare()
    --移动方向
    self.curState = FU_CREATE_ACTION_STATE.PREPARE
    local RABattleSceneManager = RARequire("RABattleSceneManager")

    -- v3导弹应该只有一个
    for index,oneData in pairs(self.data.data) do
        local targetId = oneData.targetUnit    
        local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)

        local direction = self.fightUnit:getDir()
        if oneData.targetPos ~= nil then
            local targetTilePos = RACcp(oneData.targetPos.x, oneData.targetPos.y)    
            local targetSpacePos = RABattleSceneManager:tileToSpace(targetTilePos)
            direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)
        end

        --设置移动方向
        self.fightUnit:setDir(direction)

        --自身的动作相关
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            local param = {isforce = true}
            if self.prepareTime > 0 then
                local frameCount = boneController:getFrameCount(ACTION_TYPE.ACTION_ATTACK, direction)
                newFps = frameCount / self.prepareTime
                param.newFps = newFps
            end
            boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction, param)        
        end
        self.fightUnit:SetSkillUsed(nil)    
    end 

    -- 发送消息，将战斗单元创建并进入战斗单元的管理类中
    local message = {}
    message.createActionData = self.data
    message.initVisible = false
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT, message)   
end

--真正的创建战斗单元数据
function RAFU_State_V3Create:EnterCreate()
    self.curState = FU_CREATE_ACTION_STATE.CREATE
    self.fightUnit:SetSkillUsed(BattleField_pb.V3_MISSILE)    
end


function RAFU_State_V3Create:Exit()
    if self.localAlive == true then
        self.localAlive = false        
    end
end


return RAFU_State_V3Create
--endregion
