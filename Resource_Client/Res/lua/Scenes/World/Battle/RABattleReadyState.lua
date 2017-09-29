local RABattleReadyState = {}

local RABattleConfig = RARequire('RABattleConfig')
local RAWorldMath = RARequire('RAWorldMath')
local World_pb = RARequire('World_pb')

function RABattleReadyState:new(owner)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.owner = owner
    
    return o
end

function RABattleReadyState:Enter(fightInfo)
	self:_initAttacker(fightInfo)
	self:_initDefenser(fightInfo)

	self.owner:Fire()
	-- self:_lineup(fightInfo)
end

function RABattleReadyState:_initAttacker(fightInfo)
	local targetPos = fightInfo.target.mapPos
	-- local pos = RAWorldMath:Map2View(RACcp(targetPos.x - 2, targetPos.y - 2))
	local stancePos = RAWorldMath:Map2View(RACcp(targetPos.x - 2, targetPos.y - 2))
	
	local RAWorldScene = RARequire('RAWorldScene')
	local parent = RAWorldScene.Layers['MARCH']
	
	local attackerInfo = fightInfo.result.attacker or {}
	local ccbKey = fightInfo.result.isAttackerWin and 'Win' or 'Fail'
	local aniName = fightInfo.result.isAttackerWin and 'Win' or 'Fail'
    local RAMarchDataManager = RARequire("RAMarchDataManager")
    local marchData = RAMarchDataManager:GetMarchDataById(fightInfo.marchId)
	-- TODO
	local this = self
	local cfg = {
		life = attackerInfo.total or 60,
		loss = attackerInfo.loss or 20,
		stancePos = stancePos,
		stanceNode = fightInfo.stanceNode, -- parent,
		fightLayer = parent,
		targetPos = fightInfo.target.centerPos,
		armyPos = fightInfo.srcArmy,
		centerPos = fightInfo.lineupCenterPos,
		lineupPos = fightInfo.lineupPos,
		armyIdList = attackerInfo.armyIdList or {1, 2, 3, 4},
        ccbName = RABattleConfig.Attack_CCB[fightInfo.target.gridCnt][ccbKey],
		aniName = aniName,
        marchData = marchData,
		callback = function ()
			this.owner:End()
		end
	}

	local RABattleUnit_Attacker = RARequire('RABattleUnit_Attacker')
	local attacker = RABattleUnit_Attacker:new(cfg)

	fightInfo.attacker = attacker

	performWithDelay(parent, function ()
		this:_showResult(fightInfo)
	end, RABattleConfig.ShowResult_TimeSpan)
end

function RABattleReadyState:_initDefenser(fightInfo)
	local RAWorldScene = RARequire('RAWorldScene')
	local parent = RAWorldScene.Layers['MARCH']

	local targetPos = fightInfo.target.mapPos
	local pos = RAWorldMath:Map2View(RACcp(targetPos.x, targetPos.y - 3))
	
	local battleType = fightInfo.battleType
	local defenserInfo = fightInfo.result.defenser or {}
	local hasTower = self:_hasTower(fightInfo, defenserInfo.total)
	local gridCnt = fightInfo.target.gridCnt
	
	-- TODO
	local cfg = 
	{
		life = defenserInfo.total,
		loss = defenserInfo.loss,
		hasTower = self:_hasTower(fightInfo, defenserInfo.total),
		ccbName = RABattleConfig.Defense_CCB[gridCnt],
		baseMapPos = targetPos,
		baseViewPos = fightInfo.target.viewPos,
		stanceNode = fightInfo.stanceNode,
		stancePos = fightInfo.target.centerPos,
		battleType = battleType,
		gridCnt = gridCnt,
		fightLayer = parent
	}

	local RABattleUnit_Defenser = RARequire('RABattleUnit_Defenser')
	local defenser = RABattleUnit_Defenser:new(cfg)
	fightInfo.defenser = defenser
end

function RABattleReadyState:_hasTower(fightInfo, totalArmy)
	return (fightInfo.battleType ~= World_pb.ATTACK_MONSTER 
		and fightInfo.battleType ~= World_pb.MONSTER_MASS
		and totalArmy > 0)
	-- return ((fightInfo.battleType == World_pb.ATTACK_PLAYER
	-- 		or fightInfo.battleType == World_pb.MASS
	-- 		or fightInfo.battleType == World_pb.MASS_JOIN
	-- 	 	) and fightInfo.target.gridCnt > 1 and totalArmy > 0)
end

function RABattleReadyState:_lineup(fightInfo)
	local endPos = fightInfo.lineupPos
	local owner = self.owner
	fightInfo.attacker:Lineup(endPos, function (hasNoArmy)
		if hasNoArmy then
			owner:End()
		else
			owner:Fire()
		end
	end)
end

function RABattleReadyState:_showResult(fightInfo)
	local targetMapPos = fightInfo.target.mapPos
	local targetViewPos = fightInfo.target.viewPos
	local parentNode = fightInfo.fightLayer
	local battleType = fightInfo.battleType
	local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
	local common = RARequire('common')

	local explodeCCB = RABattleConfig.Explode_CCBFile[battleType]
	local showExplode = false
	if explodeCCB then
		showExplode = true
		local soundEffect = nil
		if battleType == World_pb.ATTACK_MONSTER or battleType == World_pb.MONSTER_MASS then
			local _, building = RAWorldBuildingManager:GetBuildingAt(targetMapPos)
			if not building then return end

			if fightInfo.result.isDefenserDead then
				soundEffect = building:GetMonsterExplodeEffect()
				local RAWorldConfig = RARequire('RAWorldConfig')
				if building:GetMonsterShape() == RAWorldConfig.MonsterShape.Biological then
					RAWorldBuildingManager:changeBuildingState(targetMapPos, BUILDING_ANIMATION_TYPE.DIE)
					showExplode = false
				end
			end
			RAWorldBuildingManager:changeBuildingState(targetMapPos, BUILDING_ANIMATION_TYPE.IDLE)
		else
			if fightInfo.result.isAttackerWin then
				RAWorldBuildingManager:changeBuildingState(targetMapPos, BUILDING_ANIMATION_TYPE.BROKEN_MAP)
			end
			soundEffect = RABattleConfig.SoundEffect_Result.Explode
		end

		if showExplode then
			local UIExtend = RARequire('UIExtend')
			local this = self
			local explodeNode = UIExtend.loadCCBFile(explodeCCB, {
				OnAnimationDone = function (_self, ccbfile)
					local lastAnimationName = ccbfile:getCompletedAnimationName()
					if lastAnimationName == 'Default Timeline' then
						ccbfile:removeFromParentAndCleanup(true)
						if this.owner then
							this.owner:End()
						end
					end
				end
			})
			explodeNode:setPosition(targetViewPos.x, targetViewPos.y)
			parentNode:addChild(explodeNode)
		end
		
		common:playEffect(soundEffect)
	end

	if not showExplode then
		self.owner:End()
		--[[
		local this = self
		performWithDelay(
			parentNode, 
			function ()
				this.owner:End()
			end, 
			RABattleConfig.EndBattle_TimeSpan
		)
		--]]
	end

	-- common:playEffect(RABattleConfig.SoundEffect_Result.Cheer)
end

return RABattleReadyState