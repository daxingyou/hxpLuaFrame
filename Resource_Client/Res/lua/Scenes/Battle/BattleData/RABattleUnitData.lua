
--pb数据存储
RARequire('extern')
local battle_unit_conf = RARequire('battle_unit_conf')
local BattleField_pb = RARequire('BattleField_pb')
local RABattleUnitData = class('RABattleUnitData',{
		id = 0,
		itemId = 0,
		type = 0,
		movePeriod = 0,--基础移动时间，以客户端右上移动为基准单位U，向上移动为 1/U,向右移动为2/u
		attackCd = 0,
		unitHp = 0,
		attackRange = 0,  
		count = 0,  --以上都是PB数据
		turnPeriod = 0,--转向45度的基础时间，如tank0.1，如从左转到右为180度，则为0.4秒，其他士兵默认为0，
		size = nil,--战斗单元的占位大小
		aircraft = false,--是否为飞行器
		deadPeriod = 0,--死亡时间消耗
		bulletSpeed = 50, --每秒多少像素

		hp = 0, --当前血量
		confData = nil,--配置文件对象
		pos = nil, --地图坐标
		unitType = 0,--2 防守方,1 攻击方
	})

--根据PB初始化数据
function RABattleUnitData:initByPb(pb,cfg)
	
	self.id = pb.id
	self.count = pb.count
	self.maxCount = pb.maxCount

	self.type = cfg.type
	self.itemId = cfg.itemId
	self.posPrior = cfg.posPrior

	if cfg:HasField("size") then 
		self.size = {width=cfg.size.width,height=cfg.size.height}
	else
		self.size = {width=1,height=1}
	end 

	if cfg:HasField("canMove") then 
		self.canMove = cfg.canMove
	else
		self.canMove = false
	end

	if cfg:HasField("canAttack") then 
		self.canAttack = cfg.canAttack
	else
		self.canAttack = false
	end

	if pb:HasField("initPos") then 
		self.initPos = {x=pb.initPos.x,y=pb.initPos.y}
	else
		self.initPos = nil 
	end 

	if cfg:HasField("attackOnce") then 
		self.attackOnce = cfg.attackOnce
	else
		self.attackOnce = false
	end

	if pb:HasField("entranceWait") then 
		self.entranceWait = cfg.entranceWait
	else
		self.entranceWait = 0
	end

	self.movePeriod = cfg.movePeriod
	self.attackPeriod = cfg.attackPeriod
	self.turnPeriod = cfg.turnPeriod
	self.deadPeriod = cfg.deadPeriod
	self.bulletSpeed = cfg.bulletSpeed or 50

	self.unitHp = cfg.unitHp
	self.unitAttack = cfg.unitAttack
	self.unitDefence = cfg.unitDefence
	
	self.attackRange = cfg.attackRange
	self.attackCd = cfg.attackCd
	self.damageMode = cfg.damageMode
	self.damageRange = cfg.damageRange

	self.percentDamage = cfg.percentDamage
	self.damageAtte = cfg.damageAtte
	self.damageBuffType = cfg.damageBuffType
	self.damageBuffTime = cfg.damageBuffTime


	self.skills = {}
	for i=1,#cfg.skills do
		local skillInfo = {}
		skillInfo.skillId = cfg.skills[i].skillId
		skillInfo.skillCd = cfg.skills[i].skillCd
		skillInfo.createUnitId = cfg.skills[i].createUnitId
		skillInfo.createUnitCount = cfg.skills[i].createUnitCount
        skillInfo.skillDps = cfg.skills[i].skillDps
		skillInfo.enemyIds = {}

		for j=1,#cfg.skills[i].enemyIds do
			skillInfo.enemyIds[j] = cfg.skills[i].enemyIds[j]
		end

		self.skills[i] = skillInfo
	end

	self.attackIds = {}
	for i=1,#cfg.attackIds do
		self.attackIds[i] = cfg.attackIds[i]
	end

	self.enemyIds = {}
	for i=1,#cfg.enemyIds do
		self.enemyIds[i] = cfg.enemyIds[i]
	end

	self.dmgAddition = {}
	for i=1,#cfg.dmgAddition do
		local dmgAddition = {}
		dmgAddition.itemId = cfg.dmgAddition[i].itemId
		dmgAddition.rate = cfg.dmgAddition[i].rate
		self.dmgAddition[i] = dmgAddition
	end

	self.pb = pb


	self.hp = self.count
	self.confData = battle_unit_conf[self.itemId]
	assert(self.confData,"confData is nil========--" .. self.itemId)
	self.unitType = ATTACKER

	self.totalHp = self.maxCount*self.unitHp
	self.curHp = self.count*self.unitHp
	-- self.bulletSpeed = 50 --目前是测试数据
end

function RABattleUnitData:createChild(createData)
	local unitPB = BattleField_pb.BattleUnit()
	unitPB.id = createData.childUnitId
	unitPB.count = 1
	unitPB.itemId = createData.childItemId
	-- unitPB.self.unitType

	local childData = self.new()
	local RAFightManager = RARequire('RAFightManager')
	local cfg = RAFightManager:getCfgPbById(unitPB.itemId)
	childData:initByPb(unitPB,cfg)
	childData.unitType = self.unitType
	return childData
end

function RABattleUnitData:setPos(pos)
	self.pos = {x = pos.x, y = pos.y}
end

function RABattleUnitData:updateTileMap()
	local tileMap = {}
	for i=1,self.width do
		for j=1,self.height do
			tileMap[i .. '_' .. j] = {x=self.pos.x + (i-1),y=self.pos.y + (j-1)}
		end
	end
	self.tileMap = tileMap
end

function RABattleUnitData:setUnitType(unitType)
	self.unitType = unitType
end

function RABattleUnitData:reset()
	self.hp = self.count
	self.curHp = self.count*self.unitHp
end

function RABattleUnitData:isAlive()
	return self.hp > 0
end

--通过unitDamage 更新 hp
function RABattleUnitData:updateByUnitDamage(unitDamage)
	assert(unitDamage.unitId == self.id,"unitDamage.uuid == self.id")
	if unitDamage.unitId == self.id then
		if self.hp > unitDamage.count then
			self.hp = unitDamage.count
		end
		self.curHp  = self.curHp + unitDamage.damage

		local fullHP = self.count*self.unitHp
		if self.curHp < 0 then 
			self.curHp = 0
		elseif self.curHp > fullHP then 
			self.curHp = fullHP
		end 
	end
end

function RABattleUnitData:ctor(...)

end 

return RABattleUnitData
