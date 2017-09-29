local RAActionDataFactory = {}

--action 数据类
function RAActionDataFactory:init()
	local BattleField_pb = RARequire('BattleField_pb')
	local RAMoveActionData = RARequire('RAMoveActionData')
	local RAAttackActionData = RARequire('RAAttackActionData')
	local RAStopActionData = RARequire('RAStopActionData')
	local RADeadActionData = RARequire('RADeadActionData')
	local RABuffAttachActionData = RARequire('RABuffAttachActionData')
	local RABuffDmgActionData = RARequire('RABuffDmgActionData')
	local RACreateActionData = RARequire('RACreateActionData')
	local RADisappearActionData = RARequire('RADisappearActionData')
	local RAFlyActionData = RARequire('RAFlyActionData')
	local RAFinishActionData = RARequire('RAFinishActionData')
	local RASkillCastActionData = RARequire('RASkillCastActionData')
	local RASkillEffectActionData = RARequire('RASkillEffectActionData')
	local RASkillPointSyncActionData = RARequire('RASkillPointSyncActionData')
	local RABuildingDisableActionData = RARequire('RABuildingDisableActionData')
	local RATerroristActionData =  RARequire('RATerroristActionData')
    local RAReviveActionData = RARequire('RAReviveActionData')
	local RABombDamageActionData = RARequire('RABombDamageActionData')
    local RAFrozenActionData    = RARequire('RAFrozenActionData')

	self.createMap = {}
	self.createMap[BattleField_pb.MOVE] = RAMoveActionData.new
	self.createMap[BattleField_pb.DEAD] = RADeadActionData.new
	self.createMap[BattleField_pb.STOP] = RAStopActionData.new
	self.createMap[BattleField_pb.ATTACK] = RAAttackActionData.new
	self.createMap[BattleField_pb.BUFF_ATTACH] = RABuffAttachActionData.new
	self.createMap[BattleField_pb.BUFF_DMG] = RABuffDmgActionData.new
	self.createMap[BattleField_pb.CREATE] = RACreateActionData.new
	self.createMap[BattleField_pb.DISAPPEAR] = RADisappearActionData.new
	self.createMap[BattleField_pb.FLY] = RAFlyActionData.new
	self.createMap[BattleField_pb.FINISH] = RAFinishActionData.new
	self.createMap[BattleField_pb.SKILL_CAST] = RASkillCastActionData.new
	self.createMap[BattleField_pb.SKILL_EFFECT] = RASkillEffectActionData.new
	self.createMap[BattleField_pb.SKILL_POINT_SYNC] = RASkillPointSyncActionData.new
	self.createMap[BattleField_pb.BUILDING_DISABLE] = RABuildingDisableActionData.new
	self.createMap[BattleField_pb.TERRORIST_ATTACH] = RATerroristActionData.new
	self.createMap[BattleField_pb.BOMB_DAMAGE] = RABombDamageActionData.new
    self.createMap[BattleField_pb.REVIVE] = RAReviveActionData.new
    self.createMap[BattleField_pb.FROZEN_ATTACH] = RAFrozenActionData.new
end

function RAActionDataFactory:create(actionPb)
	local handler = self.createMap[actionPb.type]
	if handler == nil then 
		RALogError("ActionType ".. actionPb.type .. " not found")
		return 
	end  
	return handler(actionPb)
end

RAActionDataFactory:init()
return RAActionDataFactory