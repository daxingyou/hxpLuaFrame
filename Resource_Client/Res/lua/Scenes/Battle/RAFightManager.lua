RARequire('extern')
RARequire('BattleField_pb')
RARequire('RAFightDefine')
local EnumManager = RARequire("EnumManager")
local RARootManager = RARequire("RARootManager")
local actionTypeCfg = EnumManager.ACTION_TYPE
local battle_map_conf = RARequire('battle_map_conf')
local RABattleUnitData = RARequire('RABattleUnitData')
RARequire("profiler")
local RAFightManager = class('RAFightManager',{
    battleUnitDatas = nil,
    initActions = nil,--初始化结构
    actions = nil,
    isEnd = false,
    frameTime = 0,
    curTimeIndex = 1,
    initCameraPos = nil,
    battleSkillPoint = 0,
    battlePeriod = 1,
    dungeonId = nil,
    isReplay = false
    })


--地图Tmxmap文件名
function RAFightManager:getTmxName()
    return battle_map_conf[self.battleParams.cfg.mapId].tmx
end

--地图配置数据
function RAFightManager:getMapConfData()
    return battle_map_conf[self.battleParams.cfg.mapId]
end

--兵种配置pb信息
function RAFightManager:getCfgPbById(id)
    return self.cfgsMap[id]
end

--设置兵种技能点
function RAFightManager:setSkillPoint(skillPoint)
	if self.battleSkillPoint ~= skillPoint then
	    self.battleSkillPoint = skillPoint
	    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_SkillPoint_Change)
	end
end

function RAFightManager:getSkillPoint()
    return self.battleSkillPoint
end

function RAFightManager:_syncSkillPointData(skillPointAction)
    assert(skillPointAction~= nil and skillPointAction.skillPoint~= nil,"false")
    self:setSkillPoint(skillPointAction.skillPoint)
end

function RAFightManager:getIsPVEBattle()
	return self.isPVEBattle
end

--战斗持续时间 
function RAFightManager:getBattlePeriod()
	return self.battlePeriod
end

--初始化战斗单元数据
function RAFightManager:initUnitData(unitType,unitArr)
    local subArr = self.battleTypeUnitArr[unitType]

    for i=1,#unitArr do
        local battleUnitData = RABattleUnitData.new()
        local cfg = self.cfgsMap[unitArr[i].itemId]
        battleUnitData:initByPb(unitArr[i],cfg)
        battleUnitData:setUnitType(unitType)
        self.battleUnitDatas[battleUnitData.id] = battleUnitData
        subArr[#subArr+1] = battleUnitData
    end
end

--初始化战场数据
function RAFightManager:initBattleParams(battleParams)
    self.battleParams = battleParams    --战场参数pb
    self.battleUnitDatas = {}           --全部的兵种数据
    self.battleTypeUnitArr = {}         --兵种类型索引
    self.battleTypeUnitArr[DEFENDER] = {} --防御方数据
    self.battleTypeUnitArr[ATTACKER] = {} --攻击方数据
    -- self.defenderUnitDatas = {}         
    -- self.attackerUnitDatas = {}       

    --初始化cfgsMap
    self.cfgsMap = {}
    local cfg
    for i=1,#battleParams.cfg.cfgs do
        cfg = battleParams.cfg.cfgs[i]
        self.cfgsMap[cfg.itemId] = cfg
    end

    self:initUnitData(DEFENDER,battleParams.defender.units)
    self:initUnitData(ATTACKER,battleParams.attacker.units)
end

--生成战斗单元 V3火箭车导弹之类的
function RAFightManager:addUnit(createActionData)
    local unitData = self:getBattleUnitDataById(createActionData.unitId)
    local childData = unitData:createChild(createActionData)
    self.battleUnitDatas[childData.id] = childData 
    return childData
end

--isPVEBattle 如果是PVE有战中技能，则填true，否则，如战报类型，填false
function RAFightManager:calBattle(mapSizeWidth,mapSizeHeight,tileMapBlockLayer,isPVEBattle)

    -- 设置地图
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local Utilitys = RARequire('Utilitys')
    
    self.battleParams.map.mapId = self.battleParams.cfg.mapId
    self.battleParams.map.width = mapSizeWidth
    self.battleParams.map.height = mapSizeHeight
    self.battleParams.map.tileWidth = RABattleSceneManager:getTileSizeWidth()
    self.battleParams.map.tileHeight = RABattleSceneManager:getTileSizeHeight()

    local mapData = self:getMapConfData()

    --攻击方部队初始位置
    local posArr = Utilitys.Split(mapData.atkPos, ",")
    self.battleParams.map.atkPos.x  = tonumber(posArr[1])
    self.battleParams.map.atkPos.y  = tonumber(posArr[2])

    --防守方部队初始位置
    posArr = Utilitys.Split(mapData.defPos, ",")
    self.battleParams.map.defPos.x  = tonumber(posArr[1])
    self.battleParams.map.defPos.y  = tonumber(posArr[2])

    --交火位置
    if mapData.warPos ~= nil then 
        posArr = Utilitys.Split(mapData.warPos, ",")
        self.battleParams.map.warPos.x  = tonumber(posArr[1])
        self.battleParams.map.warPos.y  = tonumber(posArr[2])
    end 

    for x=0,mapSizeWidth-1 do
        for y=0,mapSizeHeight-1 do
            self.battleParams.map.data:append((tileMapBlockLayer:tileGIDAt(y,x)-1)*-1)
        end
    end

    RABattleSceneManager:initMapInfo()
    BattleManager:getInstance():initMapInfo(self.battleParams.map.tileWidth,self.battleParams.map.tileHeight,mapSizeWidth,mapSizeHeight)
    local pb_data = self.battleParams:SerializeToString()

    --改用战中攻击的模式
    if isPVEBattle == nil then
        isPVEBattle = true
    end 
    self.isPVEBattle = isPVEBattle
    if self.isPVEBattle then
        --PVE 模式的战斗
        local battleResultStr = BattleManager:getInstance():startBattleApi(pb_data,#pb_data)
        RAFightManager:initPVEBattleResult(battleResultStr)
    else
        --PVP 模式的战斗
        local battleResultStr = BattleManager:getInstance():getBattleResult(pb_data,#pb_data)
        RAFightManager:initPVPBattleResult(battleResultStr) 
    end    
end

--获得士兵数据
function RAFightManager:getBattleUnitDataById(id)
    return self.battleUnitDatas[id] 
end

--初始化镜头设置,cameraIndex:battle_camera_conf的配置ID
function RAFightManager:initCameraPosById(cameraIndex)
    self.initCameraPos = {}
    self.fightCameraPos = {}
    local battle_camera_conf = RARequire('battle_camera_conf')
    local cameraText = battle_camera_conf[cameraIndex]

    if cameraText ~= nil then 
        self:setCameraInfo(cameraText.info,self.initCameraPos)  --开场前镜头移动
        self:setCameraInfo(cameraText.fightInfo,self.fightCameraPos) --战斗中镜头移动
    end 
end

function RAFightManager:initCamera()
    if self.missionData and self.missionData.cameraId then 
        self:initCameraPosById(self.missionData.cameraId)
    else 
        self:initCameraPosById(0)
    end 
end

--设置镜头数据
function RAFightManager:setCameraInfo(cameraText,arr)
    local Utilitys = RARequire('Utilitys')
    local singleInfos = Utilitys.Split(cameraText, ",")
    for i=1,#singleInfos do
        local singleInfo = singleInfos[i]
        local info = Utilitys.Split(singleInfo, "|")
        local data = {}
        data.type = tonumber(info[1])

        local pos = Utilitys.Split(info[2], "_")
        data.x = tonumber(pos[1])
        data.y = tonumber(pos[2])
        data.time = tonumber(info[3])

        if data.type == 1 then --移动摄像机，最后一个参数是缩放系数
            data.scale = tonumber(info[4])
        elseif data.type == 2 then --闪耀某个兵种
            data.itemId = tonumber(info[4])
        elseif data.type == 3 then  --部队集结的速度
            data.movePeriod = tonumber(info[4])
        end 
        arr[i] = data
    end
end

--处理行为数组
function RAFightManager:setActions(actionPbArr)
    local RAInitActionData = RARequire('RAInitActionData')
    local RAActionDataFactory = RARequire('RAActionDataFactory')
    local timeActions
    for i=1,#actionPbArr do
        local battleAction= actionPbArr[i]

        if battleAction.type == BattleField_pb.INIT then 
            local initAction = RAInitActionData.new(battleAction)
            initAction:initByPb(battleAction)
            self.initActions[#self.initActions+1] = initAction
        else
            if self.actions[battleAction.time] == nil then 
                self.actions[battleAction.time] = {}
                self.timeIndexs[#self.timeIndexs+1] = battleAction.time
            end
            timeActions = self.actions[battleAction.time] 
            timeActions[#timeActions+1] = RAActionDataFactory:create(battleAction)
        end 
    end
    table.sort(self.timeIndexs,function (v1,v2)
        return v1< v2
    end)
end

--PVE模式，添加战斗技能模块的战斗PB 处理
function RAFightManager:initPVEBattleResult(resultStr)
    local battleResultPb = BattleField_pb.BattleResult()
    battleResultPb:ParseFromString(resultStr)   
    -- CCLuaLog("battleResult:" .. battleResultPb.bulletin.result)
    local RAInitActionData = RARequire('RAInitActionData')
    local RAActionDataFactory = RARequire('RAActionDataFactory')
    local battle_camera_conf = RARequire('battle_camera_conf')
    if battleResultPb:HasField('bulletin') then
        self.battleCalTime = battleResultPb.bulletin.calcTime --战斗计算时间
        self.winResult = battleResultPb.bulletin.result       --胜负结果
        self.battleId = battleResultPb.bulletin.battleId      --
    end

    self:initCamera()

    self.initActions = {}
    self.actions = {} --按时间索引
    self.timeIndexs = {}

    self:setActions(battleResultPb.detail.actions)
end

--处理Tick之后的Result,之后的处理就没有InitAction,只有初始化的时候有InitAcion
function RAFightManager:_handlePVETick(battleResult)
    local battleResultPb = BattleField_pb.BattleResult()
    battleResultPb:ParseFromString(battleResult)   

    if battleResultPb.bulletin ~= nil then
        self.winResult = battleResultPb.bulletin.result
    end

    --如果数组为空，则不处理
    if #battleResultPb.detail.actions == 0 then
        return
    end

    self:setActions(battleResultPb.detail.actions)
end


--获取每一帧的逻辑处理
function RAFightManager:getPVETickBattleResult(dt)

    if self.battleId ~= nil then
        local tickParam = BattleField_pb.BattleTickParams()
        tickParam.battleId = self.battleId
        tickParam.period = dt

        --添加技能的释放处理
        RARequire("RAFightSkillSystem"):prepareSkillDataPB(tickParam.castSkills)

        local pb_data = tickParam:SerializeToString()

        --将battle id 和dt 发给C++，计算返回的值
        local battleResultStr = BattleManager:getInstance():tickBattleApi(pb_data,#pb_data)
        self:_handlePVETick(battleResultStr)
    end
end


function RAFightManager:initPVPBattleResult(resultStr)
    local battleResultPb = BattleField_pb.BattleResult()
    battleResultPb:ParseFromString(resultStr)   
    -- CCLuaLog("battleResult:" .. battleResultPb.bulletin.result)
    local RAInitActionData = RARequire('RAInitActionData')
    local RAActionDataFactory = RARequire('RAActionDataFactory')
    local battle_camera_conf = RARequire('battle_camera_conf')
    self.battleCalTime = battleResultPb.bulletin.calcTime
    self.winResult = battleResultPb.bulletin.result
    self.initActions = {}
    self.actions = {} --按时间索引
    local indexActions = {}  --按个体
    
    self:initCamera()
    
    self.timeIndexs = {}
    
    self:setActions(battleResultPb.detail.actions)

    local common = RARequire('common')
    local lastMoveAction = nil
    local removeIndex
    for k,indexMap in pairs(indexActions) do
        table.sort(indexMap, function ( left, right )
            return left.time < right.time
        end)
        lastMoveAction = nil
        for i,battleAction in ipairs(indexMap) do
            if battleAction.type == BattleField_pb.MOVE then
                if lastMoveAction and lastMoveAction.moveDir == battleAction.moveDir  then --遍历单个unitaction，去除相同方向的action
                    lastMoveAction.movePos = battleAction.movePos
                    lastMoveAction.movePeriod = battleAction.movePeriod + lastMoveAction.movePeriod
                    lastMoveAction.targetId = battleAction.targetId
                    lastMoveAction.mergerTime = lastMoveAction.mergerTime or 1
                    lastMoveAction.mergerTime = lastMoveAction.mergerTime + 1
                    if self.actions[battleAction.time] then
                        removeIndex = common:table_arrayIndex(self.actions[battleAction.time], battleAction)
                        if removeIndex ~= -1 then
                            table.remove(self.actions[battleAction.time],removeIndex)
                        else
                            RALogInfo("RAFightManager-- action is missing") 
                        end 
                    end                    

                else
                    if lastMoveAction then
                        lastMoveAction.actionTime = battleAction.time - lastMoveAction.time
                    end
                    lastMoveAction = battleAction
                end
            else
                if lastMoveAction then
                    lastMoveAction.actionTime = battleAction.time - lastMoveAction.time
                end
                lastMoveAction = nil
            end
        end
    end
end

function RAFightManager:getInitCameraPos()
    return self.initCameraPos
end

function RAFightManager:getFightCameraPos()
    return self.fightCameraPos
end

function RAFightManager:getAliveCount(armyType)
    
    local unitArr = self.battleTypeUnitArr[armyType]

    local count = 0
    for i,v in ipairs(unitArr) do
        if v:isAlive() then 
            count = count + 1
        end
    end
    return count
end

function RAFightManager:getCount(armyType)
    return #self.battleTypeUnitArr[armyType] 
end

function RAFightManager:init(missionId, pveDungeonId)
    local battle_mission_conf = RARequire('battle_mission_conf')
    self.missionData = battle_mission_conf[missionId]
    self.isInitExecuteData = false
    self.dungeonId = pveDungeonId or nil
    self.isPVEBattle = self.dungeonId ~= nil
    self.battleSkillPoint = self.missionData.skillPoint or 0
    self.battlePeriod = self.missionData.timeLimit or 180
end

function RAFightManager:resetAllBattleUnitData()
    for k,v in pairs(self.battleUnitDatas) do
        v:reset()
    end
end

function RAFightManager:initExecuteData()
    self.frameTime = 0
    self.curTimeIndex = 1

    self.isInitExecuteData = true
end

function RAFightManager:startEffect( ... )
    local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local effectCfg,effectInstance
    for i,effectName in ipairs(self.startEffectList) do
        effectCfg = RAFU_Cfg_Effect[effectName]
        if effectCfg then
            effectInstance = RARequire(effectCfg.class).new(effectName)
            effectInstance:Enter({targetSpacePos = RABattleSceneManager:tileToSpace(RACcp(28,24))})
        end
    end
end

function RAFightManager:Execute(dt)

    self.frameTime = self.frameTime + dt*1000

    if self.isInitExecuteData  then

        --计算每一帧的数据处理，注意，重播的情况下，不需要计算，直接使用timeIndex以及actionMap就OK
        if self.isReplay == false and self.isPVEBattle then
            RAFightManager:getPVETickBattleResult(dt * 1000)
        end

        --处理每一帧的战斗效果
        local time = self.timeIndexs[self.curTimeIndex]
        if time ~=nil then
            if self.frameTime > time then
                local actionsMap = self.actions[self.timeIndexs[self.curTimeIndex]]
                RAFightManager:TickActionMap(actionsMap)
                self.curTimeIndex = self.curTimeIndex + 1
            end
        end
    end
end

function RAFightManager:_FinishBattle(finishActionData)
    self:resetExecuteData()
    self.winResult = finishActionData.winTroop
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local delayFunc = function (  )
        RABattleSceneManager:changeAllUnitToEndBattle()
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.END_BATTLE}) 
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Quit)             
    end
    RABattleSceneManager:performWithDelay(delayFunc,1)

    --战斗顺利，通知服务器关卡打过去了
    if not self.isReplay and self.isPVEBattle and self.dungeonId ~= nil and self.winResult == BattleField_pb.WIN then
    	local RADungeonHandler = RARequire('RADungeonHandler')
    	RADungeonHandler:sendAttackDungeonReq(self.dungeonId)
    end
end


--Tick 动作Table
function RAFightManager:TickActionMap(actionsMap)
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local battleUnits = RABattleSceneManager.battleUnits
    for k,v in pairs(actionsMap) do
        local stateType = nil 
        if v.type == BattleField_pb.MOVE then
            stateType = STATE_TYPE.STATE_MOVE
        elseif v.type == BattleField_pb.STOP then
            stateType = STATE_TYPE.STATE_IDLE
        elseif v.type == BattleField_pb.ATTACK then
            stateType = STATE_TYPE.STATE_ATTACK
        elseif v.type == BattleField_pb.CREATE then
            stateType = STATE_TYPE.STATE_CREATE
        elseif v.type == BattleField_pb.FLY then
            stateType = STATE_TYPE.STATE_FLY
        elseif v.type == BattleField_pb.DISAPPEAR then
            stateType = STATE_TYPE.STATE_DISAPPEAR
        elseif v.type == BattleField_pb.FINISH then
            --战斗结束标志位
            return RAFightManager:_FinishBattle(v)
        elseif v.type == BattleField_pb.SKILL_CAST then
            --先同步技能点
            self:setSkillPoint(v.skillPoint)
            --如果是技能飞行，直接通过战斗技能系统处理，因为跟战斗单元无关
            local RAFightSkillSystem = RARequire("RAFightSkillSystem")
            RAFightSkillSystem:handleSkillCastAction(v)
        elseif v.type == BattleField_pb.SKILL_EFFECT then
            --如果是释放技能，直接通过战斗技能系统处理，因为跟战斗单元无关
            local RAFightSkillSystem = RARequire("RAFightSkillSystem")
            RAFightSkillSystem:handleSkillEffectAction(v)
        elseif v.type == BattleField_pb.SKILL_POINT_SYNC then
            self:_syncSkillPointData(v)
        elseif v.type == BattleField_pb.BUILDING_DISABLE then
           
        elseif v.type == BattleField_pb.BOMB_DAMAGE then --爆炸伤害
             RARequire("RABattleSceneManager"):dispatchUnitDamage(v.damage)
        elseif v.type ==  BattleField_pb.TERRORIST_ATTACH then 
             RARequire("RABattleSceneManager"):handleTerroristAttack(v.targetId)
             stateType = STATE_TYPE.STATE_TERRORIST_ATTACK
        elseif v.type == BattleField_pb.BUFF_ATTACH then
             RARequire("RABattleSceneManager"):addBuff(v)
        elseif v.type ==  BattleField_pb.BUFF_DMG then --buff伤害
            RARequire("RABattleSceneManager"):handleBuffDamage(v)
        elseif v.type ==  BattleField_pb.REVIVE     then   --复活
            stateType = STATE_TYPE.STATE_REVIVE 
        elseif v.type == BattleField_pb.FROZEN_ATTACH then 
            stateType = STATE_TYPE.STATE_FROZEN_ATTACH
        else
            RALog("TICKACTIONMAP")
        end
         
            local formatStr = "TICKACTIONMAP" .." type %d"
            local Str = string.format(formatStr, v.type)
            print(Str)
        local unit = battleUnits[v.unitId]
        if unit ~=nil then
            if stateType ~= nil then
                unit:changeState(stateType,v)
            else
               RALogInfo("RAFightManager-- stateType is nil, corresponding vtype is  "..v.type) 
            end    
        end
    end
end

function RAFightManager:setIsReplay(replay)
    self.isReplay = replay
end

function RAFightManager:getIsReplay()
	return self.isReplay
end

function RAFightManager:Exit()
    -- body
    self.battleUnitDatas = {}
    self:resetExecuteData()
end

function RAFightManager:resetExecuteData()
    self.frameTime = 0
    self.curTimeIndex = 1
    self.isInitExecuteData = false
    self.battleSkillPoint = 0
    self.isReplay = false
    RARequire("RAFightSkillSystem"):reset()
end

return RAFightManager