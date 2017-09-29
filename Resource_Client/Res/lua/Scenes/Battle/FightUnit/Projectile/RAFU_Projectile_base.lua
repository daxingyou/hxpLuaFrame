--[[
description: 
抛射类型是抛射体。基础类

author: zhenhui
date: 2016/12/9
]]--

local RAFU_Projectile_base = class('RAFU_Projectile_base',RARequire("RAFU_Object"))

--projectUUID 唯一UUID，pWeapon，所属控制器的武器句柄list，warheadList，当前这次射击产生的子弹list，effectList，射击产生的效果
function RAFU_Projectile_base:ctor(projectUUID,pWeapon,warheadList,effectList)
	self.warheadList = warheadList
	self.effectList = effectList
	self.pWeapon = pWeapon
	self.projectUUID = projectUUID
	self.frameTime = 0
	self.unitPos = pWeapon.ownerUnit:getPosition()
	self.curState = WEAPON_PROJECT_STATE.NONE
    self.localAlive = true
    self.hasCalcData = false
end

--析构函数
function RAFU_Projectile_base:release()
	for k,v in pairs(self.warheadList) do
		RA_SAFE_RELEASE(v)
	end

    if self.hasCalcData == false then
        self:_HitUnit(self.data)
    end

	--移除循环
	self:removeFromBattleScene()
	
	self.curState = WEAPON_PROJECT_STATE.DESTROY
end


--到达目标点，触发逻辑，注意：是flyTime到达之后，而不是lifeTime到达之后调用
--传入参数是受击的data.attackData = RAAttackActionData
function RAFU_Projectile_base:_HitUnit(data)
	if data == nil or data.attackData == nil then 
		RALogError("attackData is nil")
		return
	end
	local attackAction = data.attackData
    self.hasCalcData = true
    --分发战斗伤害计算，统一接口处理
    RARequire("RABattleSceneManager"):dispatchUnitDamage(attackAction.damage)
end

--[[
--控制器开始
    local fireData = {
        targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)
        attackData = data
    }
]]
function RAFU_Projectile_base:Enter(data)
    self.data = data
end

--无论如何都会有受击效果或者伤害,父类来处理数据的处理
function RAFU_Projectile_base:EnterEffect()
	self:_HitUnit(self.data)
end

function RAFU_Projectile_base:Execute(dt)
	RALogError("RAFU_Projectile_base:Execute  Please rewrite Execute")
end


function RAFU_Projectile_base:Exit()
	if self.localAlive then
		self:release()
  		self.localAlive = false
	end
    
end

--发消息给控制器，提示加入场景管理器        
function RAFU_Projectile_base:AddToBattleScene()
    local this = self
    local message = {}
    message.projectInstance = this
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_PROJECTILE, message)
end

--发消息给控制器，提示移除场景管理器 
function RAFU_Projectile_base:removeFromBattleScene()
    local message = {}
    message.uid = self.projectUUID
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_PROJECTILE, message)
end



return RAFU_Projectile_base