RARequire('BattleField_pb')

local battle_unit_conf = RARequire('battle_unit_conf')
local battle_skill_conf = RARequire('battle_skill_conf')
local TestData = {}

ATTACKER = 1
DEFENDER = 2

TestData.missionId = 88
--1,10,7,1,3,0.1,4,3,0.5,4
--movePeriod 移动相邻一格的时间  turnPeriod 转动45度的时间
function TestData:addSoldierData(armyType,itemId,singleCount,count,pos,airInfo,entranceWait,maxCount)
	local data = {}
    data.confData = battle_unit_conf[itemId]
    data.totalCount = count or 1
    data.count = singleCount or 4
    data.pos = pos
    data.airInfo = airInfo
    data.entranceWait = entranceWait or 0
    data.maxCount = maxCount 

    if armyType == nil then 
        armyType = ATTACKER
    end 

	local arr = self.soldiersArr[armyType]
	arr[#arr+1] = data 
    return data
end

function TestData:addSoldierDataByObj(obj)
    local objPararm = obj or {}
    self:addSoldierData(objPararm.armyType,objPararm.itemId,objPararm.singleCount,objPararm.count,objPararm.pos,objPararm.airInfo,objPararm.entranceWait,objPararm.maxCount)
end

function TestData:addBattleSkillsCfg(battleSkills)
    local battle_player_skill_conf = RARequire("battle_player_skill_conf")
    for k,skillConf in pairs(battle_player_skill_conf) do
        --[[
        // 战场主动技能
        message BattleSkill
        {
            required int32 skillId = 1; // 技能id
            required int32 costPoint = 2; // 消耗点
            optional int32 range = 3; // 生效范围
            optional float damage = 4; // 伤害|治疗, 数值或百分比
            optional float flyPeriod = 5; // 效果飞行速度
            optional float effectElapse = 6; // 生效间隔
            optional int32 effectTimes = 7; // 多次生效
        }]]
        local oneSkill = battleSkills:add()
        oneSkill.skillId = skillConf.skillId
        oneSkill.costPoint = skillConf.costPoint
        oneSkill.range = skillConf.range
        oneSkill.damage = skillConf.damage
        oneSkill.flyPeriod = skillConf.flyPeriod
        oneSkill.effectElapse = skillConf.effectElapse
        oneSkill.effectTimes = skillConf.effectTimes
        

    end
end

function TestData:setBattleUnitCfg(cfg,confData)
    cfg.type = confData.type
    cfg.itemId = confData.id
    cfg.posPrior = confData.posPrior 
    cfg.size.width = confData.unitSize_Width
    cfg.size.height = confData.unitSize_Height

    if confData.canMove == 0 then 
        cfg.canMove = false
    else
        cfg.canMove = true
    end

    if confData.canAttack == 0 then 
        cfg.canAttack = false
    else
        cfg.canAttack = true
    end 

    if confData.attackOnce == 0 then 
        cfg.attackOnce = false
    else
        cfg.attackOnce = true
    end

    if confData.flyPeriod ~= nil then 
        cfg.flyPeriod = confData.flyPeriod
    end 


    if confData.airDropRadius ~= nil and confData.airDropRadius >= 0 then 
        cfg.airDropRadius = confData.airDropRadius
    end 

    cfg.movePeriod = confData.movePeriod
    cfg.attackPeriod = confData.attackPeriod
    cfg.turnPeriod = confData.turnPeriod
    cfg.deadPeriod = confData.deadPeriod
    cfg.bulletSpeed = confData.bulletSpeed
    cfg.idleWait = confData.idleWait

    if confData.specialAI ~= nil then 
        cfg.specialAI = confData.specialAI
    end

    if confData.placeholder ~= nil and confData.placeholder > 0 then 
        cfg.placeholder = true
    else
        cfg.placeholder = false
    end

    if confData.freeFly ~= nil and confData.freeFly > 0 then 
        cfg.freeFly = true
    else
        cfg.freeFly = false
    end

    if confData.moveStep ~= nil and confData.moveStep > 0 then 
        cfg.moveStep = confData.moveStep
    end


    if confData.skillPoint ~= nil and confData.skillPoint > 0 then 
        cfg.skillPoint = confData.skillPoint
    end

    if confData.glidePeriod ~= nil then 
        cfg.glidePeriod = confData.glidePeriod
    end

    if confData.disBuildingAtk ~= nil and confData.disBuildingAtk > 0 then 
    	cfg.disBuildingAtk = true
    end 

    cfg.unitHp = confData.unitHp
    cfg.unitAttack = confData.unitAttack
    cfg.unitDefence = confData.unitDefence
    cfg.unitFight = confData.unitDefence
    cfg.attackRange = confData.attackRange
    cfg.attackCd = confData.attackCd
    cfg.damageCalcMode = confData.damageCalcMode
    cfg.damageRange = confData.damageRange
    cfg.percentDamage = confData.percentDamage
    cfg.damageAtte = confData.damageAtte
    cfg.damageBuffType = confData.damageBuffType
    cfg.damageBuffTime = confData.damageBuffTime

    if confData.bombDamage ~= nil then
        cfg.bombDamage = confData.bombDamage
    end
    if confData.bombRange ~= nil then
        cfg.bombRange = confData.bombRange
    end
    

    if confData.attackMinRange ~= nil then 
        cfg.attackMinRange = confData.attackMinRange
    end

    local Utilitys = RARequire('Utilitys')
    if confData.attackIds ~= nil or confData.attackIds ~= '0' then 
        local attackIds = Utilitys.Split(confData.attackIds, ",")
        for i=1,#attackIds do
            cfg.attackIds:append(tonumber(attackIds[i]))
        end
    end 

    if confData.enemyIds ~= nil or confData.enemyIds ~= '0' then 

        local enemyIds = Utilitys.Split(confData.enemyIds, ",")
        for i=1,#enemyIds do
            cfg.enemyIds:append(tonumber(enemyIds[i]))
        end
    end

    if confData.skillId ~= nil or confData.skillId ~= '0' then 

        local skills = Utilitys.Split(confData.skillId, ",")
        for i=1,#skills do
            local skillConf = battle_skill_conf[tonumber(skills[i])]

            local unitSkill = cfg.skills:add()
            unitSkill.skillId = skillConf.id
            unitSkill.skillCd = skillConf.skillCd
           
            if skillConf.createUnitId ~=nil then
                 unitSkill.createUnitId = skillConf.createUnitId
            end
            if skillConf.createUnitCount ~= nil then 
                unitSkill.createUnitCount = skillConf.createUnitCount
            end 
            if  skillConf.dps ~= nil then 
                unitSkill.skillDps =  skillConf.dps
            end 

            local enemyIds = Utilitys.Split(skillConf.enemyIds, ",")
            
            for i=1,#enemyIds do
                unitSkill.enemyIds:append(tonumber(enemyIds[i]))
            end
        end
    
    end

    if confData.damage_addition ~= nil or confData.damage_addition ~= '0' then 
        local damageAdditions = Utilitys.Split(confData.damage_addition, ",")
        for i=1,#damageAdditions do
            local damageInfo = Utilitys.Split(damageAdditions[i], "_")
            local dmgAddition = cfg.dmgAddition:add()
            dmgAddition.itemId = tonumber(damageInfo[1])
            dmgAddition.rate = tonumber(damageInfo[2])/1000
        end
    end 

    -- for i=1,3 do
    --     local dmgAddition = cfg.dmgAddition:add()
    --     dmgAddition.itemId = i
    --     dmgAddition.rate = i
    -- end
end

function TestData:setBattleUnit(unit,id,data)
    unit.count = data.count
    unit.id = id
    unit.itemId = data.confData.id

    if data.maxCount ~= nil then 
        unit.maxCount = data.maxCount
    else
        unit.maxCount = unit.count
    end 

    --unit.maxCount = 2*unit.count

    local entranceWait = 0

    if self.missionData.waitTime ~= nil then 
        entranceWait = self.missionData.waitTime
    end

    if data.airInfo then 
        entranceWait = data.airInfo.entranceWait + entranceWait
        unit.moveTargetPos.x = data.airInfo.targetPos.x
        unit.moveTargetPos.y = data.airInfo.targetPos.y
    else
        if data.entranceWait ~= nil then 
            entranceWait = entranceWait + data.entranceWait
        end 
    end 

    if entranceWait>0 then

        if unit.itemId ~= 3001 then  
            unit.entranceWait = entranceWait
        end 
    end 

    if data.pos ~= nil then 
        unit.initPos.x = data.pos.x
        unit.initPos.y = data.pos.y
    end 
      
end

function TestData:copyData(armyType,pbArr)
	local index = 0
	for i,v in ipairs(self.soldiersArr[armyType]) do
    	for i=1,v.totalCount do
    		local unit = pbArr.units:add()
    
    		index = index + 1
            local id = nil 

    		if armyType == ATTACKER then 
				id = index
			else
				id = index+ 1000
    		end

            self:setBattleUnit(unit,id,v) 
    	end
    end
end


--初始化带位置的军队
function TestData:initTroopsHasPos(troopsText,arr)
    if troopsText == nil then 
        return 
    end 
    local Utilitys = RARequire('Utilitys')
    local troops =  Utilitys.Split(troopsText, ",")
    for k,v in pairs(troops) do
        local unitInfo = Utilitys.Split(v, "_")
        local unit = {}
        assert(unitInfo[1]~=nil,"error" .. troopsText)
        assert(unitInfo[2]~=nil,"error".. troopsText)
        assert(unitInfo[3]~=nil,"error".. troopsText)
        assert(unitInfo[4]~=nil,"error".. troopsText)
        unit.itemId = tonumber(unitInfo[1])
        unit.pos = {}
        unit.pos.x = tonumber(unitInfo[2])
        unit.pos.y = tonumber(unitInfo[3])
        unit.count = tonumber(unitInfo[4])

        if unitInfo[5] ~= nil then 
            unit.maxCount = tonumber(unitInfo[5])
        end

        arr[#arr+1] = unit
        self.allBattleUids[unit.itemId] = unit.itemId
    end
end

--初始化空中单位
function TestData:initAirforce(troopsText,arr)
    if troopsText == nil then 
        return 
    end 
    local Utilitys = RARequire('Utilitys')
    local troops =  Utilitys.Split(troopsText, ",")
    for k,v in pairs(troops) do
        local unitInfo = Utilitys.Split(v, "|")
        local unit = {}
        assert(unitInfo[1]~=nil,"error" .. troopsText)
        assert(unitInfo[2]~=nil,"error".. troopsText)
        assert(unitInfo[3]~=nil,"error".. troopsText)
        assert(unitInfo[4]~=nil,"error".. troopsText)
        unit.itemId = tonumber(unitInfo[1])
        unit.pos = {}

        local initPos = Utilitys.Split(unitInfo[2], "_")
        unit.pos.x = tonumber(initPos[1])
        unit.pos.y = tonumber(initPos[2])
        unit.airInfo = {}
        local targetPos = Utilitys.Split(unitInfo[3], "_")
        unit.airInfo.targetPos = {}
        unit.airInfo.targetPos.x = tonumber(targetPos[1])
        unit.airInfo.targetPos.y = tonumber(targetPos[2])

        unit.airInfo.entranceWait = tonumber(unitInfo[4])

        unit.count = tonumber(unitInfo[5])

        if  unitInfo[6] ~= nil then 
            unit.maxCount = tonumber(unitInfo[6])
        end 

        self.allBattleUids[unit.itemId] = unit.itemId 
        arr[#arr+1] = unit
    end
end

function TestData:initTroops(troopsText,arr)
    if troopsText == nil then 
        return 
    end 

    local battle_troop_conf = RARequire('battle_troop_conf')

    local Utilitys = RARequire('Utilitys')
    local troopsIndexs =  Utilitys.Split(troopsText, ",")
    for _,index in pairs(troopsIndexs) do

        local troopsInfo = battle_troop_conf[tonumber(index)]
        local troops = Utilitys.Split(troopsInfo.troops,',')
        local waitTime = troopsInfo.waitTime
        for _,v in pairs(troops) do
            local unitInfo = Utilitys.Split(v, "_")
            local unit = {}
            assert(unitInfo[1]~=nil,"error" .. troopsText)
            assert(unitInfo[2]~=nil,"error" .. troopsText)
            assert(unitInfo[3]~=nil,"error" .. troopsText)
            unit.itemId = tonumber(unitInfo[1])
            unit.count = tonumber(unitInfo[2])
            unit.totalcount = tonumber(unitInfo[3])--显示对象

            if unitInfo[4] ~= nil then 
                unit.maxCount = tonumber(unitInfo[4])
            end 
            unit.entranceWait = waitTime
            arr[#arr+1] = unit
            self.allBattleUids[unit.itemId] = unit.itemId
        end
        
    end
end

function TestData:initPlayerArmy(troopsText,arr)
	local Utilitys = RARequire('Utilitys')
	local troops = Utilitys.Split(troopsText,',')
    for _,v in pairs(troops) do
        local unitInfo = Utilitys.Split(v, "_")
        local unit = {}
        assert(unitInfo[1]~=nil,"error" .. troopsText)
        assert(unitInfo[2]~=nil,"error" .. troopsText)
        assert(unitInfo[3]~=nil,"error" .. troopsText)
        unit.itemId = tonumber(unitInfo[1])
        unit.count = tonumber(unitInfo[2])
        unit.totalcount = tonumber(unitInfo[3])--显示对象

        if unitInfo[4] ~= nil then 
            unit.maxCount = tonumber(unitInfo[4])
        end 
        --unit.entranceWait = waitTime
        arr[#arr+1] = unit
        self.allBattleUids[unit.itemId] = unit.itemId
    end
end

function TestData:initAllUnitChild()
    local x = 1
    local Utilitys = RARequire('Utilitys')
    local troops =  Utilitys.Split(troopsText, ",")
    local childMap = {}

    local battle_unit_conf = RARequire('battle_unit_conf')
    for k,v in pairs(self.allBattleUids) do
        local unit_conf = battle_unit_conf[k]
        if unit_conf.child ~= nil then 
            local childStr = tostring(unit_conf.child)
            local unitIns = Utilitys.Split(childStr, ",")
            for i,unitId in ipairs(unitIns) do
                local id = tonumber(unitId)
                childMap[id] = id
            end
        end 
    end

    for k,v in pairs(childMap) do
        self.allBattleUids[v] = v
    end
end

--解析关卡数据配置
function TestData:initMissionData(missionId)
    RAUnload('battle_mission_conf')
    local battle_mission_conf = RARequire('battle_mission_conf')
    local missionData = battle_mission_conf[missionId]
    self.missionData = missionData
    self.initAttackersArr = {}  --攻击方的数据
    self.initDefendersArr = {}  --防守方的数据
    self.allBattleUids = {}     --全部涉及的兵种
    self.targetItems = {}

    local Utilitys = RARequire('Utilitys')    
    local targetItems =  Utilitys.Split(tostring(missionData.targetItems), ",")
    for i=1,#targetItems do
        self.targetItems[#self.targetItems+1] = tonumber(targetItems[i])
    end
    -- self.
    -- self.
    if self.troopText == nil then 
    	self:initTroopsHasPos(missionData.attackerHasPos,self.initAttackersArr)
    	-- self:initAirforce(missionData.initAirforce,self.initAttackersArr)
    	self:initTroops(missionData.attacker,self.initAttackersArr)
    else
    	self:initPlayerArmy(self.troopText,self.initAttackersArr)
    	self.troopText = nil 
    end 

    --self:initTroopsHasPos(missionData.attackerHasPos,self.initAttackersArr)
    self:initTroopsHasPos(missionData.defenderHasPos,self.initDefendersArr)

    self:initAirforce(missionData.initAirforce,self.initAttackersArr)

    --self:initTroops(missionData.attacker,self.initAttackersArr)
    self:initTroops(missionData.defender,self.initDefendersArr)

    self:initAllUnitChild()
end

--初始化战场配置
function TestData:initBattleCfg(battleCfg)
    local battle_unit_conf = RARequire('battle_unit_conf')
    battleCfg.version = 1
    battleCfg.mapId = self.missionData.mapid  -- 地图ID
    battleCfg.randSeed = 4 --随机种子
    battleCfg.skillPoint = self.missionData.skillPoint 
    battleCfg.battlePeriod = self.missionData.timeLimit 

    for i=1,#self.targetItems do
        battleCfg.targetItems:append(self.targetItems[i])
    end

    for k,v in pairs(self.allBattleUids) do
        local cfg = battleCfg.cfgs:add()
        self:setBattleUnitCfg(cfg,battle_unit_conf[v])
    end


    -- self:initMissionData(self.missionId)
    -- battleCfg.randSeed = 4 --随机种子
end

function TestData:getData(missionId,troopText)
	if missionId then
		self.missionId = missionId
	end

	if troopText then 
		self.troopText = troopText
	end 
	
	local battleParams = BattleField_pb.BattleParams()
	self.soldiersArr = {}
	self.soldiersArr[ATTACKER] = {}
	self.soldiersArr[DEFENDER] = {} 

    self:initMissionData(self.missionId)
    --初始化战场配置
    self:initBattleCfg(battleParams.cfg)

    for i,v in ipairs(self.initAttackersArr) do
        -- v.armyType = ATTACKER
        self:addSoldierDataByObj({armyType = ATTACKER,itemId = v.itemId,count = v.totalcount,singleCount = v.count,pos=v.pos,airInfo = v.airInfo,entranceWait = v.entranceWait,maxCount = v.maxCount})
    end

    for i,v in ipairs(self.initDefendersArr) do
        self:addSoldierDataByObj({armyType = DEFENDER,itemId = v.itemId,count = v.totalcount,singleCount = v.count,pos=v.pos,airInfo = v.airInfo,entranceWait = v.entranceWait,maxCount = v.maxCount})
    end

    self:copyData(ATTACKER,battleParams.attacker)
    self:copyData(DEFENDER,battleParams.defender)

    self.attackers =self.soldiersArr[ATTACKER] 
    self.defenders =self.soldiersArr[DEFENDER] 


    --添加BattleSkill技能配置
    self:addBattleSkillsCfg(battleParams.battleSkills)


    return battleParams,self.missionId
end

function TestData:setGMWindowData(attackers,defenders)
	self.attackers = attackers
	self.defenders = defenders
end

function TestData:getGMData()
	local battleParams = BattleField_pb.BattleParams()
	self.soldiersArr = {}
	self.soldiersArr[ATTACKER] = {}
	self.soldiersArr[DEFENDER] = {} 

	local battleCfg = battleParams.cfg
    battleCfg.version = 1
    battleCfg.mapId = 3  -- 地图ID

    for i,v in ipairs(self.attackers) do

        local type = nil 
        if v.itemId == 4 then 
            type = BattleField_pb.UNIT_FOOT
        else 
            type = BattleField_pb.UNIT_TANK
        end 

        self:addSoldierDataByObj({armyType = ATTACKER,itemId = v.itemId,count = v.totalCount,singleCount= v.count,type = type})    	
    end

    for i,v in ipairs(self.defenders) do
        local type = nil 
        if v.itemId == 4 then 
            type = BattleField_pb.UNIT_FOOT
        else 
            type = BattleField_pb.UNIT_TANK
        end

    	self:addSoldierDataByObj({armyType = DEFENDER,itemId = v.itemId,count = v.totalCount,singleCount= v.count,type = type})
    end

    self:copyData(ATTACKER,battleParams.attacker)
    self:copyData(DEFENDER,battleParams.defender)

    return battleParams
end

return TestData