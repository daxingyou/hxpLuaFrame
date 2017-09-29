local RABattleStartState = {}

local UIExtend = RARequire('UIExtend')
local RABattleConfig = RARequire('RABattleConfig')
local EnumManager = RARequire('EnumManager')

function RABattleStartState:new(owner)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.owner = owner
    
    return o
end

function RABattleStartState:Enter(params)
	if self:_init(params) then
		self.owner:Ready()
	else
		self.owner:Exit()
	end
end

function RABattleStartState:_init(params)
	local fightInfo = params.fightInfo or {}
	local targetPos = params.defenserPos or {}

	local RAMarchDataManager = RARequire('RAMarchDataManager')
	local marchData = RAMarchDataManager:GetMarchDataById(fightInfo.marchId)
	if marchData == nil then return false end
	
	targetPos.x, targetPos.y = marchData.terminalX, marchData.terminalY

	local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
	local buildingId, buildingNode = RAWorldBuildingManager:GetBuildingAt(targetPos)

	if buildingNode == nil then return false end

	-- 避免建筑点在战斗结束前被删除，并延时更新
	buildingNode:AddRef()
	RAWorldBuildingManager:markDelayUpdate(targetPos)


	-- 移除行军结束点的序列帧
	MessageManager.sendMessage(MessageDef_World.MSG_MarchBeginBattle, {marchId = fightInfo.marchId})
	
	local RAWorldMath = RARequire('RAWorldMath')
	local targetViewPos = RAWorldMath:Map2View(targetPos)
	fightInfo.target =
	{
		centerPos = RACcp(0, 0),
		mapPos = targetPos,
		viewPos = targetViewPos,
		gridCnt = buildingNode.mBuildingInfo.gridCnt
	}

	local fromPos = RACcp(marchData.origionX, marchData.origionY)
	local World_pb = RARequire('World_pb')
	fightInfo.isSelfAttacker = marchData.relation == World_pb.SELF

	if fightInfo.isSelfAttacker then
		local RAWorldHudManager = RARequire('RAWorldHudManager')
		RAWorldHudManager:RemoveHud()
	
		local RARewardPushHandler = RARequire('RARewardPushHandler')
		RARewardPushHandler:delayShowReward()
	end
	local dir = self:_getAttackerDir(fromPos, targetPos)
	fightInfo.attackerDir = dir

	fightInfo.battleType = marchData.marchType

	local ccbfile = UIExtend.loadCCBFile(RABattleConfig.Stance_CCBFile[dir], {})
	ccbfile:setPosition(targetViewPos.x, targetViewPos.y)
	-- ccbfile:setVisible(false)

	local RAWorldScene = RARequire('RAWorldScene')
	local parent = RAWorldScene.Layers['MARCH']
	parent:addChild(ccbfile)
	fightInfo.stanceNode = ccbfile
	CCCamera:setBillboard(ccbfile)

	fightInfo.srcArmy = {}
	fightInfo.lineupPos = {}

	local sumX, sumY = 0, 0
	local cnt = 0

	for k, v in pairs(params.armyInfo) do
		local worldPos = ccp(v.x, v.y)
		local localPos = ccbfile:convertToNodeSpaceAR(worldPos)
		fightInfo.srcArmy[k] = RACcp(localPos.x, localPos.y)
		worldPos:delete()
		localPos:delete()

		local node = UIExtend.getCCNodeFromCCB(ccbfile, 'mAttackNode' .. k)
		local x, y = node:getPosition()
		fightInfo.lineupPos[k] = RACcp(x, y)


    	sumX, sumY = sumX + x, sumY + y
    	cnt = cnt + 1
	end


	if cnt > 0 then
		fightInfo.lineupCenterPos = RACcp(sumX / cnt, sumY / cnt)
	end
	-- fightInfo.srcArmy = params.attackerPos
	
	return true
end

function RABattleStartState:_getAttackerDir(fromPos, toPos)
	local Utilitys = RARequire('Utilitys')
	local degree = Utilitys.ccpAngle(fromPos, toPos)

	local dirMap = 
	{
		EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
		EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
		EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
		EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT
	}
	local dir = math.floor(degree / 90) + 1
	return dirMap[dir]
end

function RABattleStartState:_getLineupEndPos(srcArmy)
	-- TODO: change according to dir and gridCnt
	local ccbiName = RABattleConfig.Stance_CCBFile
	local stanceNode = UIExtend.loadCCBFile(ccbiName, {})
	
	local endPos = {}
	for i = 1, 4 do
		if srcArmy[i] then
			local node = UIExtend.getCCNodeFromCCB(stanceNode, 'mAttackNode' .. i)
			local x, y = node:getPosition()
			endPos[i] = RACcp(x, y)
		end
	end

	return endPos
end

return RABattleStartState