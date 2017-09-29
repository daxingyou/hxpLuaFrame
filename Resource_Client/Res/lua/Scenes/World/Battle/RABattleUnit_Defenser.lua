 local RABattleUnit = RARequire('RABattleUnit')

local RABattleUnit_Defenser = RABattleUnit:new()

local UIExtend = RARequire('UIExtend')
local RABattleConfig = RARequire('RABattleConfig')
local RAWorldMath = RARequire('RAWorldMath')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local World_pb = RARequire('World_pb')
local ArmyCatogory = RARequire('RAArsenalConfig').ArmyCatogory

local BulletRadius =
{
	-- left
	{135, 225},
	-- right
	{-45, 45},
	-- top
	{45, 135},
	-- bottom
	{-135, -45}
}

function RABattleUnit_Defenser:new(cfg)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.cfg = {}
	o.tower = {}
	-- o.buildings = {}
	o.building = nil

    o:_init(cfg)

    return o
end

function RABattleUnit_Defenser:_init(cfg)
	cfg.hpPos = RACcp(cfg.stancePos.x - 20, cfg.stancePos.y + 150)
	-- self:Init(cfg)
	self.cfg = cfg

	local hasDefenseTower = cfg.hasTower
	if hasDefenseTower then
		-- self:_addDefenseTower(cfg)
		self:_addDefenseBuilding(cfg)
	end
end

-- 添加光陵塔
function RABattleUnit_Defenser:_addDefenseTower(cfg)
	local towerSpine = RABattleConfig.LightTower_Spine
	local MapPosOffset = {
		-- left
		{x = -1},
		-- right
		{x = 1},
		-- top
		{y = 1},
		-- bottom
		{y = -1}
	}
	local ViewPosOffset = {
		{x = 10, y = -20},
		{x = 0, y = -30},
		{y = 20},
		{y = -20}
	}

	-- common:playEffect(RABattleConfig.SoundEffect_Defense.Show)
	for i = 1, 4 do
		local tower = SpineContainer:create(towerSpine .. '.json', towerSpine .. '.atlas')
		-- local pos = RAWorldMath:Map2View(RACcpAdd(cfg.baseMapPos, MapPosOffset[i]))
		local pos = RACcp(128 * (MapPosOffset[i].x or 0), 64 * (MapPosOffset[i].y or 0))
		pos = RACcpAdd(pos, ViewPosOffset[i])
		tower:setPosition(pos.x, pos.y)
		tower:setScale(0.6)
		cfg.stanceNode:addChild(tower)
		self.tower[i] = {pos = pos, towerNode = tower}
		tower:runAnimation(0, BUILDING_ANIMATION_TYPE.ATTACK, 1)
	end
	common:playEffect(RABattleConfig.SoundEffect_Defense.Ready)
end

-- 添加防御建筑(沙袋)
function RABattleUnit_Defenser:_addDefenseBuilding(cfg)
	if cfg.ccbName == nil then return end
	self:_clearBuildings()

	local RAWorldConfig = RARequire('RAWorldConfig')
	local ZorderMap = RAWorldConfig.Building.Zorder
	local RAWorldScene = RARequire('RAWorldScene')
	local parentNode = RAWorldScene.Layers['BUILDING']

	local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
	local _, building = RAWorldBuildingManager:GetBuildingAt(cfg.baseMapPos)
	if building == nil then return end
	self.building = building
	
	-- local posOffset = nil
	if cfg.battleType == World_pb.COLLECT_RESOURCE then
		local offset, resType = building:GetResDefenseOffset()
		-- posOffset = offset
		-- posOffset = RACcp(0, 0)

		local Const_pb = RARequire('Const_pb')
		if resType == Const_pb.GOLDORE then
			-- local defNode = UIExtend.loadCCBFile(RABattleConfig.Defense_CCB_Gold, {})
			-- local pos = RACcpAdd(cfg.baseViewPos, posOffset)
			-- defNode:setPosition(RACcpUnpack(pos))
			-- parentNode:addChild(defNode, ZorderMap.FrontDefense)
			-- defNode:runAnimation(RABattleConfig.Defense_CCB_Ani_Gold)
			-- table.insert(self.buildings, defNode)
			building:AddBackDefense(RABattleConfig.Defense_CCB_Gold)
			return
		end
	else
		-- posOffset = RABattleConfig.Defense_CCB_Offset[cfg.battleType][cfg.gridCnt]
		-- posOffset = RACcp(0, 0)
	end

	-- local pos = RACcpAdd(cfg.baseViewPos, posOffset)
	local aniName = RABattleConfig.Defense_CCB_Ani[building:GetType()]
	local posOffset = RABattleConfig.Defense_CCB_Offset[building:GetType()]

	-- local backNode = UIExtend.loadCCBFile(cfg.ccbName.Back, {})
	-- backNode:setPosition(RACcpUnpack(pos))
	-- parentNode:addChild(backNode, ZorderMap.BackDefense)
	-- table.insert(self.buildings, backNode)
	-- backNode:runAnimation(aniName)
	building:AddBackDefense(cfg.ccbName.Back, aniName, posOffset)

	-- local frontNode = UIExtend.loadCCBFile(cfg.ccbName.Front, {})
	-- frontNode:setPosition(RACcpUnpack(pos))
	-- parentNode:addChild(frontNode, ZorderMap.FrontDefense)
	-- table.insert(self.buildings, frontNode) 
	building:AddFrontDefense(cfg.ccbName.Front, aniName, posOffset)
end

function RABattleUnit_Defenser:Destroy()
	for i, towerInfo in pairs(self.tower) do
		if towerInfo.towerNode then
			towerInfo.towerNode:removeFromParentAndCleanup(true)
		end
		if towerInfo.attackNode then
			towerInfo.attackNode:removeFromParentAndCleanup(true)
		end
	end
	if self.monster then
		self.monster:runAction(BUILDING_ANIMATION_TYPE.IDLE)
		self.monster = nil
	end

	self:_clearBuildings()

	self:delete()
end

function RABattleUnit_Defenser:Fire(fightInfo)
	-- if fightInfo.battleType == World_pb.ATTACK_PLAYER
	-- 	or fightInfo.battleType == World_pb.MASS
	-- 	or fightInfo.battleType == World_pb.MASS_JOIN
	-- then
	-- 	-- self:_fireFromPlayer(fightInfo)
	-- end

	if fightInfo.battleType == World_pb.ATTACK_MONSTER or fightInfo.battleType == World_pb.MONSTER_MASS then
		self:_fireFromMonster(fightInfo)
	end
end

function RABattleUnit_Defenser:_fireFromPlayer(fightInfo)
	local ccbiName = RABattleConfig.LightTower_Attack
	local targetPos = fightInfo.attacker.cfg.centerPos
	local lastDegree = 0

	for i, towerInfo in pairs(self.tower) do
		if towerInfo.attackNode == nil then
			local node = UIExtend.loadCCBFile(ccbiName, {
				OnAnimationDone = function (self, node)
					fightInfo.attacker:Harm(towerInfo.dropPos)
				end
			})
			local posX, posY = towerInfo.pos.x, towerInfo.pos.y + 60
			node:setPosition(posX, posY)

			-- 子弹落点一定范围内随机
			-- local dropPos = RAWorldMath:GetRandomPos(targetPos, 16)

			-- local distance = Utilitys.getDistance(RACcp(posX, posY), dropPos)
			local distance = math.random(128, 256)
			local scaleX = distance / 128
			node:setScaleX(scaleX)
			-- local degree = Utilitys.getDegree(dropPos.x - posX, dropPos.y - posY)
			local degree = math.random(unpack(BulletRadius[i]))
			node:setRotation(180 - degree)
			towerInfo.dropPos = RACcp(towerInfo.pos.x + distance * math.cos(math.rad(degree)), towerInfo.pos.y + math.sin(math.rad(degree)))
			fightInfo.stanceNode:addChild(node)
			towerInfo.attackNode = node
			node:stopAllActions()

			performWithDelay(node, function()
				-- 攻击与伤害 同时播放
				node:runAnimation('Default Timeline')
				fightInfo.attacker:Harm(towerInfo.dropPos)
			end, i * 0.2)
		end
	end

	if self.cfg.hasTower then
		local effectId = RABattleConfig.SoundEffect_Defense.Fire
		common:playEffect(effectId)
	end
end

function RABattleUnit_Defenser:_fireFromMonster()
	-- TODO
	local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
	local buildingId, buildingNode = RAWorldBuildingManager:GetBuildingAt(self.cfg.baseMapPos)
	if buildingNode then
		buildingNode:runAction(BUILDING_ANIMATION_TYPE.ATTACK)
		common:playEffect(buildingNode:GetMonsterAttackEffect())
		self.monster = buildingNode
	end
end

function RABattleUnit_Defenser:_clearBuildings()
	-- for _, building in ipairs(self.buildings) do
	-- 	if building then
	-- 		UIExtend.releaseCCBFile(building)
	-- 	end
	-- end
	-- self.buildings = {}
	if self.building then
		self.building:RemoveDefense()
		self.building = nil
	end
end

function RABattleUnit_Defenser:Harm(armyId)
	local ccbiName = RABattleConfig.Harm_ArmyMap[armyId]
	local harmNode = UIExtend.loadCCBFile(ccbiName, {
		OnAnimationDone = function (self, node)
			node:removeFromParentAndCleanup(true)
		end
	})
	local pos = RAWorldMath:GetRandomPos(self.cfg.stancePos, 30)
	harmNode:setPosition(pos.x, pos.y)
	self.cfg.stanceNode:addChild(harmNode)
end

return RABattleUnit_Defenser