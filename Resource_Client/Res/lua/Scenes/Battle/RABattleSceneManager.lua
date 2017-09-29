RARequire('extern')
RARequire('RAFightDefine')
RARequire("MessageDefine")
RARequire("MessageManager")
local common = RARequire("common")
--显示对象
local RABattleSceneManager = class('RABattleSceneManager',{
    battleScene = nil,
    battleUnits = nil,
    projectileList = {},
    effectList = {},
    skillList = {},
    debugTime = 0,
    callTime = 0,
    castingSkill = false,
    castingSkillId = nil,
    mIsBloodBarVisible = true ,
   --bls
    mLoadedUnitIndex = 1 
  }
)

function RABattleSceneManager:init(battleScene)
    self.battleScene = battleScene

    self:registerMessage()
    self.touchDebug = false
    self.tilesMap = {}
    self.surfaceTile = {}
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_DIE_NOTI then
        RABattleSceneManager:removeBattleUnitFromBattle(message.unitId)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH then
        RABattleSceneManager:changeUnitToDieState(message.unitId,message.attackerType)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_BEHIT then
        RABattleSceneManager:changeUnitToBehitState(message.unitId,message.unitDamage)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_TARGET then
        RABattleSceneManager:changeUnitToTargetWarning(message.unitId,message.param)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT then
        local initVisible = true
        if message.initVisible ~= nil then initVisible = message.initVisible end
        RABattleSceneManager:createUnit(message.createActionData, initVisible)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_EFFECT then
        RABattleSceneManager:addEffect(message.effectInstance)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_EFFECT then
        RABattleSceneManager:removeEffect(message.uid)
     elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_PROJECTILE then
        RABattleSceneManager:addProjectile(message.projectInstance)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_PROJECTILE then
        RABattleSceneManager:removeProjectile(message.uid)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_SKILL then
        RABattleSceneManager:addSkill(message.skillInstance)
    elseif message.messageID == MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_SKILL then
        RABattleSceneManager:removeSkill(message.uid)
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_Start then
    	RABattleSceneManager.castingSkill = true	
    	RABattleSceneManager.castingSkillId = message.skillId
    	RABattleSceneManager.battleScene.multiLayerTable.dragState = true
    	RABattleSceneManager.showSkillRange = true
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_Quit then
    	RABattleSceneManager.castingSkill = false
    	RABattleSceneManager.castingSkillId = nil
    	RABattleSceneManager.showSkillRange = false
    	RABattleSceneManager.battleScene.scrollTable.startPos = nil
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_Deploy then
    	RABattleSceneManager.showSkillRange = true
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_CancelDeploy then
    	RABattleSceneManager.battleScene:removeSkillRangeNode()
    	RABattleSceneManager.showSkillRange = false
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_EnterGround then
    	RABattleSceneManager.battleScene:removeSkillRangeNode(message.params)
    end

end 

function RABattleSceneManager:Exit()
    self:cleanScene()
    self:removeMessageHandler()
    RARequire("RAFightSoundSystem"):Exit()
end

function RABattleSceneManager:createUnit(createActionData, initVisible)
    assert(createActionData ~=nil)
    local RAFightManager = RARequire('RAFightManager')
    local RAFightUnitFactory = RARequire('RAFightUnitFactory')

    for i=1,#createActionData.data do
        local createData = createActionData.data[i]
        local newUnit = RAFightManager:addUnit(createData)
        local battleUnit = RAFightUnitFactory:createUnit(newUnit)
        battleUnit:setRootNodeVisible(initVisible)
        battleUnit:setTilePos(createData.pos)
        self.battleScene:addBattleUnit(battleUnit)
        self.battleUnits[battleUnit.id] = battleUnit
    end
end

function RABattleSceneManager:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DIE_NOTI,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_BEHIT,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_TARGET,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_EFFECT,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_EFFECT,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_PROJECTILE,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_PROJECTILE,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_SKILL,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_SKILL,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Start, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Quit, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Deploy, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_CancelDeploy, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_EnterGround, OnReceiveMessage)
end



function RABattleSceneManager:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DIE_NOTI,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_BEHIT,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_TARGET,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_EFFECT,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_EFFECT,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_PROJECTILE,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_PROJECTILE,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_SKILL,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_SKILL,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Start, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Quit, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Deploy, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_CancelDeploy, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_EnterGround, OnReceiveMessage)
end

function RABattleSceneManager:initAllBattleUnits(initActions)
    local RAFightManager = RARequire('RAFightManager')
    local RAFightUnitFactory = RARequire('RAFightUnitFactory')
    local EnumManager = RARequire('EnumManager')

    local offsetY = 0

    if RAFightManager.missionData and RAFightManager.missionData.offsetY then 
        offsetY = RAFightManager.missionData.offsetY
    end  

    self.battleUnits = {}
    self.tilesMap = {}
    self.surfaceTile = {}
    self.attackUnits = {}
    for index,action in pairs(initActions) do
        local unitData = RAFightManager:getBattleUnitDataById(action.unitId)
        local battleUnit = RAFightUnitFactory:createUnit(unitData)

        if unitData.unitType == DEFENDER then --防守方
            battleUnit:setTilePos(action.pos)
            battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_LEFT)
        else
            local pos = {}
            pos.x = action.pos.x
            pos.y = action.pos.y + offsetY
            battleUnit:setTilePos(pos)

            battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT)
            self.attackUnits[#self.attackUnits+1] = battleUnit
        end

        self.battleScene:addBattleUnit(battleUnit)
        battleUnit:initBloodBar()
        self.battleUnits[unitData.id] = battleUnit
    end
end

function RABattleSceneManager:initBattleUnitsByStep(initActions)
 local RAFightManager = RARequire('RAFightManager')
    local RAFightUnitFactory = RARequire('RAFightUnitFactory')
    local EnumManager = RARequire('EnumManager')
    local offsetY = 0
    if RAFightManager.missionData and RAFightManager.missionData.offsetY then 
        offsetY = RAFightManager.missionData.offsetY
    end  
  
    if self.mLoadedUnitIndex > #initActions then 
       return 1000
    end
    action = initActions[self.mLoadedUnitIndex]

    local unitData = RAFightManager:getBattleUnitDataById(action.unitId)
    local battleUnit = RAFightUnitFactory:createUnit(unitData)

    if unitData.unitType == DEFENDER then --防守方
        battleUnit:setTilePos(action.pos)
        battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_LEFT)
    else
        local pos = {}
        pos.x = action.pos.x
        pos.y = action.pos.y + offsetY
        battleUnit:setTilePos(pos)

        battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT)
        self.attackUnits[#self.attackUnits+1] = battleUnit
     end
     self.battleScene:addBattleUnit(battleUnit)
     battleUnit:initBloodBar()
     self.battleUnits[unitData.id] = battleUnit
     self.mLoadedUnitIndex = self.mLoadedUnitIndex+1
     return 500
end

function RABattleSceneManager:removeAllBattleUnits()
    if self.projectileList ~= nil then  
          for k,unit in pairs(self.projectileList) do
              unit:release()
          end
    end

    if self.effectList ~= nil then  
          for k,unit in pairs(self.effectList) do
              unit:release()
          end
    end

    if self.skillList ~= nil then  
          for k,unit in pairs(self.skillList) do
              unit:release()
          end
    end


    if self.battleUnits ~= nil then  
          for k,unit in pairs(self.battleUnits) do
              unit:release()
          end
    end
    
    self.battleUnits = {}
    self.projectileList = {}
    self.effectList = {}
    self.skillList = {}
    self.childUnits = {}
end

function RABattleSceneManager:cleanScene()
    self:removeAllBattleUnits();
    self.battleScene:clean()
    self.mLoadedUnitIndex = 1

    self.battleUnits = {}
    self.tilesMap = {}
    self.surfaceTile = {}
    self.attackUnits = {}
end

function RABattleSceneManager:resetScene(initActions)
    -- self.battleScene:clean()
    if self.childUnits ~= nil then  
          for k,unit in pairs(self.childUnits) do
              unit:release()
          end
    end

    if self.projectileList ~= nil then  
          for k,unit in pairs(self.projectileList) do
              unit:release()
          end
    end

    if self.effectList ~= nil then  
          for k,unit in pairs(self.effectList) do
              unit:release()
          end
    end

    if self.skillList ~= nil then  
          for k,unit in pairs(self.skillList) do
              unit:release()
          end
    end

    self.projectileList = {}
    self.effectList = {}
    self.skillList = {}
    self.childUnits = {}


    self.battleScene.mBattleEffectLayer:removeAllChildren()
    self.battleScene.mSurfaceLayer:removeAllChildren()
    local RAFightManager = RARequire('RAFightManager')
    local RAFightUnitFactory = RARequire('RAFightUnitFactory')
    local EnumManager = RARequire('EnumManager')

    local offsetY = 0

    if RAFightManager.missionData and RAFightManager.missionData.offsetY then 
        offsetY = RAFightManager.missionData.offsetY
    end 

    -- self.battleUnits = {}
    self.tilesMap = {}
    self.surfaceTile = {}
    self.attackUnits = {}

    for k,v in pairs(self.battleUnits) do
        v:Die()
    end

    for _,action in pairs(initActions) do
        local unitData = RAFightManager:getBattleUnitDataById(action.unitId)
        -- local battleUnit = RAFightUnitFactory:createUnit(unitData)
        local battleUnit = self.battleUnits[action.unitId]
      
        battleUnit:Alive()
        if unitData.unitType == DEFENDER then --防守方
            battleUnit:setTilePos(action.pos)
            battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_LEFT)
        else
            local pos = {}
            pos.x = action.pos.x
            pos.y = action.pos.y + offsetY
            battleUnit:setTilePos(pos)
            battleUnit:initBloodBar()
            battleUnit:setInitDirection(EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT)
            self.attackUnits[#self.attackUnits+1] = battleUnit
        end 
    end
end

function RABattleSceneManager:getRandomPos(centerPos,radian,num)
    math.randomseed(os.time())
    local minX = centerPos.x - radian
    local maxX = centerPos.x + radian
    local minY = centerPos.y - radian
    local maxY = centerPos.y + radian
    local index = 0
    local posMap = {}
    while(index<num) do
        local x = math.random(minX,maxX)
        local y = math.random(minY,maxY)
        if posMap[x .. '_' .. y] == nil then 
            posMap[x .. '_' .. y] = {x=x,y=y}
            index = index + 1
        end 
    end

    return posMap
end

--攻击方行走
function RABattleSceneManager:attackersWalk(movePeriod)
    local RAMoveActionData = RARequire('RAMoveActionData')
    local EnumManager = RARequire('EnumManager')
    local RAFightManager = RARequire('RAFightManager')

    local offsetY = 0

    if RAFightManager.missionData and RAFightManager.missionData.offsetY then 
        offsetY = RAFightManager.missionData.offsetY
    end 
    
    for i=1,#self.attackUnits do
        local attackUnit = self.attackUnits[i]

        local action  = RAMoveActionData.new()
        local pos = {}
        pos.x = attackUnit.tilePos.x
        pos.y = attackUnit.tilePos.y 

        local targetPos = {x = pos.x,y=pos.y-offsetY}
        action:init(attackUnit.id,pos,targetPos,movePeriod,EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT)
        attackUnit:changeState(STATE_TYPE.STATE_MOVE,action)
    end
end

function RABattleSceneManager:attackersIdle()
    for i=1,#self.attackUnits do
        local attackUnit = self.attackUnits[i]
        attackUnit:changeState(STATE_TYPE.STATE_IDLE)
    end
end

function RABattleSceneManager:removeBattleUnitFromBattle(unitId)
    assert(unitId~=nil,"unitId~=nil")
    local unit = self.battleUnits[unitId]
    if unit ~= nil then 
        unit:Die()
    end
    -- self.battleUnits[unitId] = nil 
end

-- 根据id获取uni
function RABattleSceneManager:getBattleUnit(unitId)
    return self.battleUnits[unitId]
end

-- function RABattleSceneManager:changeAllUnitToEndBattle( ... )
--     -- body
-- end

--控制unitId单元为死亡状态
function RABattleSceneManager:changeUnitToDieState(unitId,attackerType)
    assert(unitId~=nil,"unitId~=nil")
    local unit = self.battleUnits[unitId]
    if unit ~= nil then
        unit.data.hp = 0
        --add attackerType to unit.data
        unit.data.attackerType = attackerType
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_Update_Fight_BloodBar, {})
        if unit ~= nil then 
            return unit:changeState(STATE_TYPE.STATE_DEATH)
        end
    end  
end

function RABattleSceneManager:getUnitByConfId(confId)
    for k,v in pairs(self.battleUnits) do
        if v.data.itemId == confId then 
            return v;
        end 
    end
end

--控制unitId单元为受击状态
function RABattleSceneManager:changeUnitToBehitState(unitId,unitDamage)
    assert(unitId~=nil,"unitId~=nil")
    assert(unitDamage~=nil,"unitDamage~=nil")

    local unit = self.battleUnits[unitId]
    if unit ~= nil then 
        unit:behit(unitDamage)
    end
end

--让unitId单元设置为闪红状态,目前供鲍里斯使用
function RABattleSceneManager:changeUnitToTargetWarning(unitId,param)
    assert(unitId~=nil,"unitId~=nil")

    local unit = self.battleUnits[unitId]
    if unit ~= nil then 
        unit:targetWarningBuff(param)
    end
end

--战场结束之后的单元重置，将所有剩余单元设为idle --防守方全死
function RABattleSceneManager:changeAllUnitToEndBattle()
    local BattleField_pb = RARequire('BattleField_pb')
    for k,v in pairs(self.battleUnits) do 
        if v ~= nil then
            if v.data.confData.type == BattleField_pb.UNIT_BUILDING or v.data.confData.type == BattleField_pb.UNIT_DEFENCE then 
                if v.data.confData.id ~= 4006 then
                    if v.data.confData.id < 2010 and v.data.confData.id > 2015 then  
                        v:changeState(STATE_TYPE.STATE_DEATH)
                    end 
                end 
            else
                v:changeState(STATE_TYPE.STATE_IDLE)
            end
        end
    end
end

function RABattleSceneManager:addSurfaceEffect( tilePos, index)
    self.surfaceTile[tilePos.x.."_"..tilePos.y] = index or 1
end

function RABattleSceneManager:isSurfaceEffectExist( tilePos )
    return self.surfaceTile[tilePos.x.."_"..tilePos.y] ~= nil
end

function RABattleSceneManager:removeTilePos( tilePos, width, height, data )
    local key 
    for i=1, width do
        for j=1,height do
            key = (tilePos.x + i - 1).."_"..(tilePos.y + 1 - j)
            self.tilesMap[key] = self.tilesMap[key] or {}
            for i,v in ipairs(self.tilesMap[key]) do
                if v.id == data.id then
                    table.remove(self.tilesMap[key],i)
                    break
                end
            end
        end
    end
end

function RABattleSceneManager:setTilePos( tilePos, width, height, data )
    -- local a = CCTime:getCurrentTime()
    local key 
    for i=1, width do
        for j=1,height do
            key = (tilePos.x + i - 1).."_"..(tilePos.y + 1 - j)
            self.tilesMap[key] = self.tilesMap[key] or {}
            table.insert(self.tilesMap[key], data)
        end
    end
    -- local b = CCTime:getCurrentTime()
    -- print(b-a)
end

function RABattleSceneManager:isCrashInTile( tile, ownId, FilterTypes )
    if self.tilesMap[tile.x.."_"..tile.y] then
        for i,v in ipairs(self.tilesMap[tile.x.."_"..tile.y]) do
            if v.id ~= ownId then
                if FilterTypes then
                    if common:table_arrayIndex(FilterTypes, v.confData.type) == -1 then
                        return true, v
                    end
                else
                    return true, v
                end
            end
        end
    end
    return false
end


function RABattleSceneManager:Execute(dt)
    if self.battleUnits ~= nil then
        for k,unit in pairs(self.battleUnits) do 
            RA_SAFE_EXECUTE(unit,dt)
        end
    end

    if self.projectileList ~= nil then
        for k,unit in pairs(self.projectileList) do 
            RA_SAFE_EXECUTE(unit,dt)
        end
    end

    if self.effectList ~= nil then
        for k,unit in pairs(self.effectList) do 
            RA_SAFE_EXECUTE(unit,dt)
        end
    end

    if self.skillList ~= nil then
        for k,unit in pairs(self.skillList) do 
            RA_SAFE_EXECUTE(unit,dt)
        end
    end


    RARequire("RAFightSoundSystem"):Execute(dt)

    -- self.battleScene.mBattleEffectLayer:removeAllChildren()
    -- local RAStringUtil = RARequire('RAStringUtil')
    -- for k,v in pairs(self.tilesMap) do
    --     if #v > 0 then
    --         local pos = RAStringUtil:split(k,"_")
    --         local spacePos = RABattleSceneManager:tileToSpace({x = tonumber(pos[1]), y = tonumber(pos[2])})
    --         local node = CCSprite:create('Tile_Green_sNew2.png')
    --         node:setAnchorPoint(0.5,0.5)
    --         node:setPosition(spacePos.x,spacePos.y)
    --         self.battleScene.mBattleEffectLayer:addChild(node)        
    --     end
    -- end

end

function RABattleSceneManager:castSkill(tilePos)
	local RAFightManager = RARequire('RAFightManager')
	if RAFightManager.isReplay then
		MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Quit)
		return
	end

	if self.castingSkillId then
		RARequire("RAFightSkillSystem"):addOneSkillData(self.castingSkillId, tilePos)
		self.castingSkill = false
		self.castingSkillId = nil
		MessageManager.sendMessage(MessageDef_BattleScene.MSG_CastSkill_TakeEffect)
	end
end

function RABattleSceneManager:setTouchAttackDebug()
    self.touchDebug = not self.touchDebug
end

function RABattleSceneManager:setAllUnitsDebugNodeVisible(isVisible)
    if self.battleUnits ~= nil then
        for k,unit in pairs(self.battleUnits) do 
             unit:setDebugModeVisible(isVisible)
        end
    end
end

function RABattleSceneManager:setAllUnitsHudNodeVisible(isVisible)
    if self.battleUnits ~= nil then
        for k,unit in pairs(self.battleUnits) do 
             unit:setHudVisible(isVisible)
        end
    end
end

function RABattleSceneManager:setAllUnitsBloodBarVisible(isVisible)
	if self.mIsBloodBarVisible == isVisible then return end

    if self.battleUnits ~= nil then
        for k,unit in pairs(self.battleUnits) do 
             unit:forceBloodBarVisible(isVisible)
        end
    end

    self.mIsBloodBarVisible = isVisible
end

function RABattleSceneManager:toggleAllUnitsBloodBarVisible()
	self:setAllUnitsBloodBarVisible(not self.mIsBloodBarVisible)
end

function RABattleSceneManager:getIsBloodBarVisible()
	return self.mIsBloodBarVisible
end

--获得占地位置
function RABattleSceneManager:getUnitsAllTilePos(pos,width,height)
    local posArr = {}
    local orignX = pos.x
    local orignY = pos.y

    for i = 1, width do
        for j = 1, height do

        end
    end

    return posArr
end



function RABattleSceneManager:tileToSpace(tilePos)
    local x = self.battleScene.mTileSizeWidth/2*(self.battleScene.mMapSizeWidth + tilePos.x - tilePos.y)
    local y = self.battleScene.mTileSizeHeight/2*(self.battleScene.mMapSizeHeight*2 - tilePos.x - tilePos.y - 1)
    return RACcp(x,y)
end

function RABattleSceneManager:spaceToTile(spacePos)
    --local a = CCTime:getCurrentTime()
    local tileIndex = BattleManager:getInstance():spaceToTile(spacePos.x,spacePos.y)

    local tx = math.floor(tileIndex/self.battleScene.mMapSizeHeight)
    local ty =  tileIndex%self.battleScene.mMapSizeHeight

    --local b = CCTime:getCurrentTime()
    --self.debugTime = b - a + self.debugTime
    --self.callTime = self.callTime + 1
    return {x = tx,y=ty}
end

function RABattleSceneManager:initMapInfo()
    self.halfWidth = self.battleScene.mTileSizeWidth*0.5
    self.halfHeight = self.battleScene.mTileSizeHeight*0.5
end

function RABattleSceneManager:getRootSize()
    return self.battleScene.rootSize
end

function RABattleSceneManager:getTileSizeWidth()
    return self.battleScene.mTileSizeWidth
end

function RABattleSceneManager:getTileSizeHeight()
    return self.battleScene.mTileSizeHeight
end

function RABattleSceneManager:performWithDelay(callback,time)
    performWithDelay(self.battleScene.mRootNode,callback,time)
end

function RABattleSceneManager:getSpacePosByUnitId( id)
    local pos = RACcp(0,0)
    local unit = self.battleUnits[id]
    if unit ~= nil then
        pos = unit:getPosition()
    end
    return pos
end

function RABattleSceneManager:getCenterPosByUnitId(id)
    local pos = RACcp(0,0)
    local unit = self.battleUnits[id]
    if unit ~= nil then
        pos = unit:getCenterPosition()
    end
    return pos 
end

function RABattleSceneManager:getHitPosByUnitId(id)
    local pos = RACcp(0,0)
    local unit = self.battleUnits[id]
    if unit ~= nil then
        pos = unit:getHitPosition()
    end
    return pos 
end

function RABattleSceneManager:getUnitCfgByUnitId(id)
	local unit = self.battleUnits[id]
	if unit ~= nil then
		return unit.data.confData
	end
	return nil
end


-----------projectile system related begin--------------
--添加弹道
function RABattleSceneManager:addProjectile(projectile)
    local projectUUID = projectile.projectUUID
    assert(self.projectileList[projectUUID] == nil, "false")
    self.projectileList[projectUUID] = projectile
end

--删除弹道
function RABattleSceneManager:removeProjectile(uid)
    assert(uid ~= nil ,"false")
    if self.projectileList ~= nil and self.projectileList[uid]~=nil then
        self.projectileList[uid] = nil
    end
end

-----------projectile system related end--------------


-----------effect system related begin--------------
--添加特效
function RABattleSceneManager:addEffect(effectInstance)
    local uid = effectInstance.uid

    if self.effectList[uid] == nil then 
        self.effectList[uid] = effectInstance
    end
    -- assert(self.effectList[uid] == nil, "false")
    -- self.effectList[uid] = effectInstance
end

--删除特效
function RABattleSceneManager:removeEffect(uid)
    assert(uid ~= nil ,"false")
    if self.effectList ~= nil and self.effectList[uid]~=nil then
        self.effectList[uid] = nil
    end
end

-----------effect system related end--------------


-----------sklill system related begin--------------
--添加技能
function RABattleSceneManager:addSkill(skillInstance)
    local uid = skillInstance.uid
    RALogInfo("RABattleSceneManager:addSkill come in skillInstance data")
    assert(self.skillList[uid] == nil, "false")
    self.skillList[uid] = skillInstance
    RALogInfo("RABattleSceneManager:addSkill end in skillInstance data")
end

--删除主动技能
function RABattleSceneManager:removeSkill(uid)
    assert(uid ~= nil ,"false")
    if self.skillList ~= nil and self.skillList[uid]~=nil then
        self.skillList[uid] = nil
    end
end

-----------sklill system related end--------------


-----------damage system related begin--------------

--伤害计算逻辑相关，分发
function RABattleSceneManager:dispatchUnitDamage(damage)
    assert(damage ~= nil ,"false")
    local damageLen = #damage
    for i =1, damageLen do 
        local unitDamage = damage[i]
        if unitDamage.count<= 0 then             
            --死亡逻辑            
            local unitId = unitDamage.unitId
            local attackerId = unitDamage.attackerId
            
            local message = {}
            message.unitId = unitId
            message.attackerType = self:getAttackerTypeById(attackerId)

            MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH, message)
        else
            --受攻击逻辑
            local unitId = unitDamage.unitId
            local message = {}
            message.unitId = unitId
            message.unitDamage = unitDamage
            MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_BEHIT, message)
        end
    end
end

                                   
function RABattleSceneManager:handleTerroristAttack(targetid)
    RALog('handleTerroristAttack')
    local unit = self.battleUnits[targetid]
    if unit ~= nil then
        unit:BeTerroristHit()
    end
end

function RABattleSceneManager:addBuff(buff)
    RALog('addBuff')
    local targetid = buff.unitId
    local unit = self.battleUnits[targetid]
    if unit ~= nil then
        unit:addTerroristBuff(buff)
    end
end

function RABattleSceneManager:handleBuffDamage(buff)
    RALog('handleBuffDamage')
    local targetid = buff.unitId
    local unit = self.battleUnits[targetid]
    if unit ~= nil then
    --这里掉血是负值
        buff.damage.damage = -buff.damage.damage
        unit.data:updateByUnitDamage(buff.damage)
        unit:updateCount()
    end
end 

-----------damage system related end--------------

function RABattleSceneManager:getAttackerTypeById(attackerId)
    --assert(attackerId ~= nil ,"false")
    local RAFightManager = RARequire('RAFightManager')
    local unitData = RAFightManager:getBattleUnitDataById(attackerId)

    local attackerType = 1
    if unitData then
        attackerType = unitData.confData.damageSort
    end

    return attackerType
end

return RABattleSceneManager