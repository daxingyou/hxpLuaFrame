local RABattleUnit = RARequire('RABattleUnit')

local RABattleUnit_Attacker = RABattleUnit:new()

local UIExtend = RARequire('UIExtend')
local RABattleConfig = RARequire('RABattleConfig')
local EnumManager = RARequire('EnumManager')
local RAWorldMath = RARequire('RAWorldMath')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local ArmyCategory = RARequire('RAArsenalConfig').ArmyCatogory

function RABattleUnit_Attacker:new(cfg)
	local o = {}

    setmetatable(o, self)
    self.__index = self

	o.cfg = {}
	o.army = {}
	o.pos = {}
	o.missleNode = nil
	o.stanceNode = nil
	o.attackNode = nil

	o.actions = {}
	o.bullets = {}

    o:_init(cfg)

    return o
end

function RABattleUnit_Attacker:Destroy()
	if self.mAttackNode then
		UIExtend.releaseCCBFile(self.mAttackNode)
		self.mAttackNode = nil
	end

	if self.missleNode then
		self.missleNode:removeFromParentAndCleanup(true)
	end

	for armyId, armyInfo in pairs(self.army) do
		if armyInfo then
			local actionSpr = armyInfo.actionSpr
			if actionSpr then
				-- local sprite = actionSpr:GetSprite()
				-- if sprite then
				-- 	sprite:removeFromParentAndCleanup(true)
				-- end
				actionSpr:Release()
			end
		end
	end
	self.army = {}
	self.actions = {}

	for _, bullet in pairs(self.bullets) do
		bullet:removeFromParentAndCleanup(true)
	end
	self.bullets = {}

	if self.stanceNode then
		self.stanceNode:removeFromParentAndCleanup(true)
	end
	
	self:delete()
end

function RABattleUnit_Attacker:_init(cfg)
	self.cfg = cfg

	-- local ccbfile = UIExtend.loadCCBFile(RABattleConfig.Stance_CCBFile, {})
	-- if cfg.parent then
	-- 	cfg.parent:addChild(ccbfile)
	-- end
	-- ccbfile:setPosition(cfg.stancePos.x, cfg.stancePos.y)
	-- self.stanceNode = ccbfile

	self.pos = self.cfg.stancePos

	local RAArsenalConfig = RARequire('RAArsenalConfig')
	
	local flagCfg = nil 
    if cfg.marchData~= nil then
        local RAWorldConfig = RARequire("RAWorldConfig")
        flagCfg = RAWorldConfig.RelationFlagColor[cfg.marchData.relation]   
    end
    
	local attackNode = UIExtend.loadCCBFile(cfg.ccbName, {
		OnAnimationDone = function (self, ccbfile)
			local aniName = ccbfile:getCompletedAnimationName()
			if aniName == cfg.aniName then
				cfg.callback()
			end
		end
	},flagCfg)
	-- attackNode:setPosition()
	cfg.stanceNode:addChild(attackNode)
	self.mAttackNode = attackNode

	local visibleMap = {}
	for armyType, nodeName in pairs(RABattleConfig.Attacker_AniNode) do
		local hasSoldier = common:table_contains(cfg.armyIdList, armyType)
		visibleMap[nodeName] = hasSoldier
		if hasSoldier then
			common:playEffect(RABattleConfig.SoundEffect_Attack[armyType])
		end
	end
	UIExtend.setNodesVisible(attackNode, visibleMap)
	attackNode:runAnimation(cfg.aniName)

	-- cfg.hpPos = RACcp(cfg.centerPos.x - 100, cfg.centerPos.y + 10)
	-- self:Init(cfg)
end

function RABattleUnit_Attacker:Fire(fightInfo)
	for armyId, armyInfo in pairs(self.army) do
		-- local dir = EnumManager:getDirectionBetweenPoint(armyInfo.pos, fightInfo.target.centerPos)

		local DirEnum = EnumManager.DIRECTION_ENUM
		local dirFlip = 
		{
			[DirEnum.DIR_UP_LEFT] = DirEnum.DIR_DOWN_RIGHT,
			[DirEnum.DIR_UP_RIGHT] = DirEnum.DIR_DOWN_LEFT,
			[DirEnum.DIR_DOWN_RIGHT] = DirEnum.DIR_UP_LEFT,
			[DirEnum.DIR_DOWN_LEFT] = DirEnum.DIR_UP_RIGHT
		}

		armyInfo.actionSpr:RunAction(EnumManager.ACTION_TYPE.ACTION_ATTACK, dirFlip[fightInfo.attackerDir])
		
		local attackCfg  = RABattleConfig.Attack_ArmyMap[armyId]
		if attackCfg then
			if armyId == ArmyCategory.missile then
				self:_fireWithMissle(armyInfo, attackCfg, fightInfo)
			else
				self:_fireWithBullet(armyInfo, attackCfg, fightInfo)
			end
		end
	end
end

function RABattleUnit_Attacker:Harm(dropPos)
	local ccbfile = UIExtend.loadCCBFile(RABattleConfig.LightTower_Harm, {
		OnAnimationDone = function (self, node)
			node:removeFromParentAndCleanup(true)
		end
	})
	local pos = RAWorldMath:GetRandomPos(dropPos, 14)
	ccbfile:setPosition(pos.x, pos.y)
	self.cfg.stanceNode:addChild(ccbfile)
end

function RABattleUnit_Attacker:Lineup(endPosTB, callback)
	local duration = RABattleConfig.LineUp_Duration

	local lastId = table.maxn(self.army)
	local hasArmy = false
	for armyId, armyInfo in pairs(self.army) do
		local endPos = endPosTB[armyId]
		if endPos then
			local degree = Utilitys.getDegree(endPos.x - armyInfo.pos.x, endPos.y - armyInfo.pos.y)
			-- armyInfo.actionSpr:GetSprite():setRotation(180 - degree)
			
			local pos = ccp(endPos.x , endPos.y)
			local action = CCMoveTo:create(duration, pos)
			pos:delete()
			if armyId == lastId then
				local actArr = CCArray:create()
				actArr:addObject(action)
				actArr:addObject(CCCallFunc:create(callback))
				action = CCSequence:create(actArr)
			end
			local dir = EnumManager:getDirectionBetweenPoint(armyInfo.pos, endPos)
			armyInfo.actionSpr:RunAction(EnumManager.ACTION_TYPE.ACTION_RUN, dir)
			armyInfo.actionSpr:GetSprite():runAction(action)

			armyInfo.pos = endPos

			hasArmy = true
		end
	end

	if not hasArmy and callback then
		callback(true)
	end
end

function RABattleUnit_Attacker:_fireWithMissle(armyInfo, attackCfg, fightInfo)
	if self.missleNode == nil then
		local cfg = attackCfg[fightInfo.attackerDir]
		if cfg == nil then return end
		local effectId = RABattleConfig.SoundEffect_Attack[armyInfo.id]
		local node = UIExtend.loadCCBFile(cfg.ccbi, {
			OnAnimationDone = function (self, node)
				fightInfo.defenser:Harm(armyInfo.id)
				-- common:playEffect(effectId)
			end
		})
		node:setScaleX(cfg.flipX)
		node:setPosition(armyInfo.lineupPos.x - 10, armyInfo.lineupPos.y + 10)
		armyInfo.actionSpr:GetSprite():removeFromParentAndCleanup(true)
		fightInfo.stanceNode:addChild(node)
		self.missleNode = node

		common:playEffect(effectId)
	end
end

function RABattleUnit_Attacker:_fireWithBullet(armyInfo, attackCfg, fightInfo)
	local effectId = RABattleConfig.SoundEffect_Attack[armyInfo.id]
	if attackCfg == '' and self.actions[armyInfo.id] == nil then
		local action = schedule(armyInfo.actionSpr:GetSprite(), function ()
				fightInfo.defenser:Harm(armyInfo.id)
				-- common:playEffect(effectId)
			end, 0.5)
		self.actions[armyInfo.id] = action
		common:playEffect(effectId)
		return
	end

	local bullet = self.bullets[armyInfo.id]
	if bullet then bullet:removeFromParentAndCleanup(true) end

	bullet = UIExtend.loadCCBFile(attackCfg, {
		OnAnimationDone = function (self, node)
			fightInfo.defenser:Harm(armyInfo.id)
			-- common:playEffect(effectId)
			-- node:removeFromParentAndCleanup(true)
		end
	})

	local posX, posY = armyInfo.lineupPos.x, armyInfo.lineupPos.y
	local offset = RABattleConfig.Bullet_Offset[armyInfo.id]
	if offset then
		posX = posX + (offset.x or 0)
		posY = posY + (offset.y or 0)
	end

	bullet:setPosition(posX, posY)

	fightInfo.stanceNode:addChild(bullet, -1)
	common:playEffect(effectId)
	
	local targetPos = fightInfo.defenser.cfg.stancePos
	local distance = Utilitys.getDistance(RACcp(posX, posY), targetPos)
	local scaleX = distance / 128
	bullet:setScaleX(scaleX)
	local degree = Utilitys.getDegree(targetPos.x - posX, targetPos.y - posY)
	bullet:setRotation(180 - degree)

	self.bullets[armyInfo.id] = bullet
end

return RABattleUnit_Attacker