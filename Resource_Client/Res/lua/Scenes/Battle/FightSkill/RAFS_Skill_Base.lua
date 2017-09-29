--[[
description: 
主动技能效果类型，基础类，与弹道类很类似，但更精简

author: zhenhui
date: 2017/1/10
]]--

local RAFS_Skill_Base = class('RAFS_Skill_Base',RARequire("RAFU_Object"))

--uid 唯一UUID
function RAFS_Skill_Base:ctor(uid)
	self.uid = uid
	self.frameTime = 0
	self.curState = WEAPON_PROJECT_STATE.NONE
    self.localAlive = true
    self.hasCalcData = false
end

--析构函数
function RAFS_Skill_Base:release()

    if self.hasCalcData == false then
        self:_HitUnit(self.data)
    end

	--移除循环
	self:removeFromBattleScene()
	
	self.curState = WEAPON_PROJECT_STATE.DESTROY
end


--技能飞行过程 SkillCast阶段开始
function RAFS_Skill_Base:Enter(data)
    self.data = data
    self:AddToBattleScene()
end

--
function RAFS_Skill_Base:EnterFly()
    
end


--SkillCast阶段结束

--受伤害的阶段SkillEffect  begin-----------------

--无论如何都会有受击效果或者伤害,父类来处理数据的处理
function RAFS_Skill_Base:EnterEffect(effectActionData)
	self:_HitUnit(effectActionData)
end


--到达目标点，触发逻辑，注意：是flyTime到达之后，而不是lifeTime到达之后调用
--传入参数是受击的effectActionData
function RAFS_Skill_Base:_HitUnit(data)
    if data == nil or data.damage == nil then 
        RALogError("damage is nil")
        return
    end
    self:NotifyEnterGround()
    
    local damage = data.damage
    local damageLen = #damage
    self.hasCalcData = true
    --分发战斗伤害计算，统一接口处理
    RARequire("RABattleSceneManager"):dispatchUnitDamage(damage)
end

function RAFS_Skill_Base:NotifyEnterGround()
	local params = {tilePos = self.data.targetPos, skillId = self.data.skillId}
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_EnterGround, {params = params})
end

--受伤害的阶段SkillEffect  end-----------------


function RAFS_Skill_Base:Execute(dt)
	--RALogError("RAFS_Skill_Base:Execute  Please rewrite Execute")
end


function RAFS_Skill_Base:Exit()
	if self.localAlive then
		self:release()
  		self.localAlive = false
	end
    
end

--发消息给控制器，提示加入场景管理器        
function RAFS_Skill_Base:AddToBattleScene()
    local this = self
    local message = {}
    message.skillInstance = this
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_SKILL, message)
end

--发消息给控制器，提示移除场景管理器 
function RAFS_Skill_Base:removeFromBattleScene()
    local message = {}
    message.uid = self.uid
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_SKILL, message)
end



return RAFS_Skill_Base