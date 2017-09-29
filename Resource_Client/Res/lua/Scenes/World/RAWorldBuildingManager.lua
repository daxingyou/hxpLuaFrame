--region *.lua
--Date

local RAWorldBuildingManager = 
{
    mRootNode = nil,
    mCapital = nil,
    mBorders = {},

    buildings = {},
    coordMaps = {},
    addList = {},
    addOrders = {},
    -- 不显示装饰层的坐标点({x_y = true})
    noDecoList = {},
    -- 延时添加的建筑({x_y = {pointInfo = {}}})
    delayList = {},
    -- 有超级武器警告的建筑({x_y = true})
    warningList = {},

    -- 新手专属资源、怪物
    guideBuildings = {}
}

local RAWorldBuilding = RARequire('RAWorldBuilding')
local RAStringUtil = RARequire('RAStringUtil')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldVar = RARequire('RAWorldVar')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAGuideManager = RARequire('RAGuideManager')
local RAWorldConfig = RARequire('RAWorldConfig')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')

local Add_Building_Per_Frame = 10

if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
    Add_Building_Per_Frame = 1
end

function RAWorldBuildingManager:Init(rootNode)
	self.mRootNode = rootNode

    self:AddCapital()
end

function RAWorldBuildingManager:ResetData()
    self:Clear()
    -- self.mRootNode = nil
end

function RAWorldBuildingManager:Execute()
    for _, building in pairs(self.buildings) do
        if building then
            building:Execute()
        end
    end

    local i = 1
    local added = {}
    for k, v in ipairs(self.addOrders) do
        local id = v.id
        local info = self.addList[id]
        if info then
            if self:_addBuilding(info) then
                i = i + 1
            end
            self.addList[id] = nil
        end
        table.insert(added, k)
        if i >= Add_Building_Per_Frame then break end
    end

    for _, index in ipairs(added) do
        table.remove(self.addOrders, index)
    end
end

function RAWorldBuildingManager:Clear()
    self.coordMaps = {}
    self.addList = {}
    self.addOrders = {}
    self.noDecoList = {}
    for id, buildingNode in pairs(self.buildings) do
        if buildingNode then
            buildingNode:Release()
        end
        self.buildings[id] = nil
    end
    self.buildings = {}
    self.delayList = {}
    self.guideBuildings = {}
    self.warningList = {}
    self.mCapital = nil
    self:RemoveBorder()
end

function RAWorldBuildingManager:IsBlock(mapPos)
    local id = RAWorldMath:GetMapPosId(mapPos.x, mapPos.y)

    local buildingId = self.coordMaps[id]
    if buildingId then
        if self.buildings[buildingId] then
            return true
        end
        self.buildings[buildingId] = nil
    end
    return false
end

function RAWorldBuildingManager:GetBuildingAt(mapPos)
    if mapPos == nil then return nil, nil end

    local id = RAWorldMath:GetMapPosId(mapPos.x, mapPos.y)
    local buildingId = self.coordMaps[id]
    if buildingId then
        local buildingNode = self.buildings[buildingId]
        return buildingId, buildingNode
    end
    return nil, nil
end

-- 查找特定等级的特定类型城点
-- @return {x=_x, y = _y}
function RAWorldBuildingManager:FindBuilding(_type, _level, _subType)
    local found = false
    local minDistance = -1
    local minBuilding = nil
    local curDistance = 0

    for id, building in pairs(self.buildings) do
        if building 
            and building:GetType() == _type 
        then
            if _type == World_pb.PLAYER then
                found = building:GetRelation() == World_pb.ENEMY
            elseif  _type == World_pb.RESOURCE then
                found = _subType == building.mBuildingInfo.resType
            elseif _type == World_pb.MONSTER and building:GetMonsterType() == RAWorldConfig.EnemyType.Normal then
                if _level == 0 then
                    found = true
                else
                    found = _level == building:GetLevel()
                end
            else
                if _level == 0 then
                    found = true
                else
                    found = _level == building:GetLevel()
                end
            end

            -- 剔除新手专属
            if found 
                and (_type == World_pb.RESOURCE or _type == World_pb.MONSTER)
                and building.ownerId ~= nil
            then
                found = false
            end

            -- 剔除正在采集的
            if found and _type == World_pb.RESOURCE and building.mBuildingInfo.playerId ~= "" then
                found = false
            end


            if found then
                curDistance = RACcpSub(building:GetCoord(), RAWorldVar.MapPos.Self)
                curDistance = curDistance.x*curDistance.x + curDistance.y*curDistance.y
                if minDistance == -1 then
                    minDistance = curDistance
                    minBuilding = building
                else
                    if curDistance < minDistance then
                        minDistance = curDistance
                        minBuilding = building
                    end
                end
            end
        end 
    end
    if minBuilding then
        return minBuilding:GetCoord()
    else
        return nil
    end
end

-- 获取新手建筑坐标
function RAWorldBuildingManager:FindGuideBuilding(_type)
    for k, v in pairs(self.guideBuildings) do
        if v == _type and self.buildings[k] then
            return RAWorldMath:GetMapPosFromId(k)
        end
    end
    return nil
end

-- @param instant: 是否立即添加, 否则扔到队列中分帧加载
function RAWorldBuildingManager:addBuilding(pointInfo, instant)
    -- 新手期不必添加建筑
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowWorld()) then return end

    local id = RAWorldMath:GetMapPosId(pointInfo.pos)
    local building = self.buildings[id]

    -- 若被标示为延时加载，更新点数据
    if self.delayList[id] then
        if self.delayList[id].removing then
            if building then
                building:AddRef()
            end
        end
        self.delayList[id] = {pointInfo = pointInfo, removing = false}
        return
    end

    if building then
        building:Update(pointInfo)
        return
    end

    while(not instant) do
        local isMigrateTarget = RACcpEqual(pointInfo.pos, RAWorldVar.MapPos.Migrate)

        -- 自己的基地优先加载
        if id == RAWorldVar.BuildingId.Self or isMigrateTarget then
            instant = true
            break
        end

        -- 要显示hud的优先加载
        if RACcpEqual(RAWorldVar.HudPos, pointInfo.pos) then
            instant = true
            break
        end

        -- 是否是新手建筑
        local _type = self:_getGuideBuildingType(pointInfo)
        if _type ~= nil then
            self.guideBuildings[id] = _type
            instant = true
            break
        end

        -- 是否优先级比较高
        if self:_isHighPriority(pointInfo) then
            instant = true
            break
        end

        break
    end

    if instant then
        local building = self:_addBuilding(pointInfo)
        if building and isMigrateTarget then
            building:setVisible(false)
        end
    else
        self.addList[id] = pointInfo
    end
end

function RAWorldBuildingManager:removeBuilding(mapPos)
    if mapPos == nil then return end
    
    local id = RAWorldMath:GetMapPosId(mapPos)
    if self.delayList[id] then
        self.delayList[id].removing = true
    end

    local building = self.buildings[id]
    if building and building:DecRef() < 1  then
        if self.noDecoList[id] then
            building:SetDecorationVisible(true)
            self.noDecoList[id] = nil
        end
        local gridCnt = building.mBuildingInfo.gridCnt
        building:Release()
        self.buildings[id] = nil
        self.delayList[id] = nil
        self.guideBuildings[id] = nil
        self:_removeCoordMap(id, mapPos, gridCnt)

        local RAWorldUIManager = RARequire('RAWorldUIManager')
        RAWorldUIManager:RemoveHud(mapPos)

        MessageManager.sendMessage(MessageDef_World.MSG_DelWorldPoint, {pos = mapPos, gridCnt = gridCnt})
    end
end

function RAWorldBuildingManager:markAddingBuildings()
    self.addOrders = {}

    local center = RAWorldVar.MapPos.Map
    local Utilitys = RARequire('Utilitys')

    for id, pointInfo in pairs(self.addList) do
        if pointInfo and not self:IsOutOfView(pointInfo.pos) then
            local distance = Utilitys.getSqrMagnitude(pointInfo.pos, center)
            table.insert(self.addOrders, {id = id, dis = distance})
        else
            self.addList[id] = nil
        end
    end

    table.sort(self.addOrders, function (a, b)
        return a.dis < b.dis
    end)

    MessageManager.sendMessage(MessageDef_World.MSG_RefreshWorldPoints)
end

-- 更新所有点(主要是与我的关系)
function RAWorldBuildingManager:updateAllBuildings()
    for k, building in pairs(self.buildings) do
        if building then
            building:UpdateRelationship()
        end
    end
end

function RAWorldBuildingManager:UpdateCapital()
    if self.mCapital then
        self.mCapital:Update({type = World_pb.KING_PALACE})
    end
end

function RAWorldBuildingManager:addBuildingRef(mapPos)
    local id, building = RAWorldBuildingManager:GetBuildingAt(mapPos)
    if building then
        building:AddRef()
    end
end

function RAWorldBuildingManager:decBuildingRef(mapPos)
    self:removeBuilding(mapPos)
end

function RAWorldBuildingManager:clearCache(mapPos)
    for id, building in pairs(self.buildings) do
        if building:GetType() ~= World_pb.KING_PALACE and building:GetRef() <= 1 then
            local pos = building.mBuildingInfo.coord
            if self:IsOutOfView(pos, mapPos) then
                self:removeBuilding(pos)
            end
        end
    end
end

function RAWorldBuildingManager:markDelayUpdate(mapPos)
    local id = RAWorldMath:GetMapPosId(mapPos.x, mapPos.y)
    if self.delayList[id] == nil then
        self.delayList[id] = {}
    end
    local building = self.buildings[id]
    if building then
        building:AddRef()
    end
end

function RAWorldBuildingManager:delayUpdate(mapPos)
    local id = RAWorldMath:GetMapPosId(mapPos.x, mapPos.y)
    local building = self.buildings[id]
    if building then
        building:DecRef()
    end
    local pointInfo = (self.delayList[id] or {})['pointInfo']
    if pointInfo then
        if building then
            building:Update(pointInfo)
            if building:GetRef() > 2 then
                return
            end
        else
            self:_addBuilding(pointInfo)
        end
    end
    self.delayList[id] = nil
end

-- 确定要添加，但还未收到同步点数据时主动添加我的基地
function RAWorldBuildingManager:addMyCity(mapPos)
    local RAPlayerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    local pointInfo =
    {
        pos = mapPos,
        type = World_pb.PLAYER,
        playerInfo =
        {
            id = RAPlayerInfo.playerId
        },
        k = RAWorldVar.KingdomId.Map
    }
    self:addBuilding(pointInfo, true)
end

function RAWorldBuildingManager:changeBuildingState(mapPos, action)
    local id = RAWorldMath:GetMapPosId(mapPos)
    local buildingNode = self.buildings[id]
    if buildingNode then
        buildingNode:runAction(action)
    end
end

function RAWorldBuildingManager:AddCapital()
    self.mCapital = self:_addBuilding({type = World_pb.KING_PALACE})
    if RAPlayerInfoManager.IsPresident() then
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:InitOfficialInfo()
    end
    return building
end

function RAWorldBuildingManager:_addBuilding(pointInfo)
    if pointInfo.type ~= World_pb.KING_PALACE then
        if pointInfo.k ~= RAWorldVar.KingdomId.Map then return nil end

        if self:IsOutOfView(pointInfo.pos) then return nil end
    end

    local building = RAWorldBuilding:new(pointInfo)
    if building ~= nil then
        building:addToParent(self.mRootNode)

        local info = building.mBuildingInfo or {}
        local id = info.buildingId
        self.buildings[id] = building  
        
        self:_insertCoordMap(id, info.coord, info.gridCnt)
        if building:SetDecorationVisible(false) then
            self.noDecoList[id] = true
        end

        MessageManager.sendMessage(MessageDef_World.MSG_AddWorldPoint, {pos = info.coord, gridCnt = info.gridCnt})
    end
    return building
end

function RAWorldBuildingManager:UpdateDecorationList()
    for id, _ in pairs(self.noDecoList) do
        local building = self.buildings[id]
        if building then
            building:SetDecorationVisible(false)
        end
    end
end

function RAWorldBuildingManager:_insertCoordMap(id, mapPos, gridCnt)
    self:_updateCoordMap(mapPos, gridCnt, id)
end

function RAWorldBuildingManager:_updateCoordMap(mapPos, gridCnt, val)
    self.coordMaps[RAWorldMath:GetMapPosId(mapPos)] = val

    if gridCnt > 1 then
        for _, pos in ipairs(RAWorldMath:GetCoveredMapPos(mapPos, gridCnt)) do
            self.coordMaps[RAWorldMath:GetMapPosId(pos)] = val
        end
    end
end

function RAWorldBuildingManager:_removeCoordMap(id, mapPos, gridCnt)
    self.noDecoList[id] = nil
    self:_updateCoordMap(mapPos, gridCnt, nil)
    self.guideBuildings[id] = nil
end

function RAWorldBuildingManager:_getGuideBuildingType(pointInfo)
    if RAGuideManager.isInGuide() then
        local _type = pointInfo.type
        if (_type == World_pb.RESOURCE or _type == World_pb.MONSTER)
            and pointInfo.ownerId == RAPlayerInfoManager.getPlayerId()
        then
            return _type
        end
    end
    return nil
end

function RAWorldBuildingManager:_isHighPriority(pointInfo)
    if pointInfo.type == World_pb.GUILD_TERRITORY then
        local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(pointInfo.territoryInfo.terriId)
        if cfg == nil or cfg.id == nil then return nil end
        if cfg.type == Const_pb.GUILD_BASTION then
            return true
        end
    end
    return false
end

function RAWorldBuildingManager:IsOutOfView(pos, mapPos)
    mapPos = mapPos or RAWorldVar.MapPos.Map
    local radius = RAWorldConfig.Building.Cache_Radius
    if math.abs(pos.x - mapPos.x) > radius.x or math.abs(pos.y - mapPos.y) > radius.y then
        return true
    end
    return false
end

-- 超级武器选中范围内警告
function RAWorldBuildingManager:AddWarnings(centerPos, weaponType)
    local warningList = {}

    local radius = RAWorldConfig.BombEffect_Radius
    if radius.x < 1 or radius.y < 1 then return end

    local k = radius.y / radius.x
    for i = -radius.x, radius.x, 1 do
        local maxY = radius.y - math.abs(k * i)
        for j = -maxY, maxY, 1 do
            local pos = RACcpAdd(centerPos, RACcp(i, j))
            if RAWorldMath:IsMapPos4Tile(pos)  then
                local id, building = self:GetBuildingAt(pos)
                if building then
                    if self.warningList[id] then
                        self.warningList[id] = nil
                        warningList[id] = true
                    elseif building:IsFearOfSuperWeapon(weaponType) then
                        building:AddWarning()
                        warningList[id] = true
                    end
                end
            end
        end
    end

    self:RemoveWarnings()
    self.warningList = warningList
end

function RAWorldBuildingManager:RemoveWarnings()
    for id, _ in pairs(self.warningList) do
        local building = self.buildings[id]
        if building then
            building:StopWarning()
        end
    end
    self.warningList = {}
end

-- 添加边界
function RAWorldBuildingManager:AddBorder(centerPos, radius)
    local Utilitys = RARequire('Utilitys')
    local UIExtend = RARequire('UIExtend')

    local posArr =
    {
        RAWorldMath:Map2View(RACcp(centerPos.x - radius, centerPos.y)),
        RAWorldMath:Map2View(RACcp(centerPos.x, centerPos.y - radius)),
        RAWorldMath:Map2View(RACcp(centerPos.x + radius, centerPos.y)),
        RAWorldMath:Map2View(RACcp(centerPos.x, centerPos.y + radius))
    }
    local len = #posArr
    for i = 1, len, 1 do
        local ccbi = UIExtend.loadCCBFile('Ani_Territory_Scope.ccbi', {})
        ccbi:setVisible(false)
        self.mRootNode:addChild(ccbi)
        local nextIndex = i % len + 1
        local startPos, endPos = posArr[i], posArr[nextIndex]      
        local lineSpr = UIExtend.getCCSpriteFromCCB(ccbi, 'mScopeLine')
        if lineSpr ~= nil then
            local degree = Utilitys.getDegree(startPos.x - endPos.x, startPos.y - endPos.y)
            -- 锚点在右侧
            lineSpr:setRotation(180 - degree)
            local height = lineSpr:getContentSize().height
            local width = Utilitys.getDistance(startPos, endPos)
            lineSpr:setPreferedSize(CCSize(width, height))
        end
        ccbi:setPosition(RACcpUnpack(startPos))
        ccbi:setVisible(true)
        table.insert(self.mBorders, ccbi)
    end
end

-- 移除边界
function RAWorldBuildingManager:RemoveBorder()
    local UIExtend = RARequire('UIExtend')
    
    for _, ccbi in ipairs(self.mBorders) do
        UIExtend.releaseCCBFile(ccbi)
    end
    self.mBorders = {}
end

return RAWorldBuildingManager

--endregion
