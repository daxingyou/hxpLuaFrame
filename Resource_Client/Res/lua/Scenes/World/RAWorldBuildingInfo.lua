--region *.lua

local RAWorldBuildingInfo =
{
    buildingId          = nil,
    type                = nil,
    coord               = {},
    relationship        = nil,
    id                  = nil,

    img                 = nil,
    spine               = nil,
    icon                = nil,
    iconId              = nil,

    gridCnt             = 1,
    name                = '',
    displayName         = '',
    level               = nil,
    state               = nil,

    playerId            = nil,
    playerName          = nil,
    playerIcon          = nil,

    lvPos               = nil,

    attackHurtEndTime   = nil,
    weatherHurtEndTime  = nil,

    guildId             = nil,
    guildTag            = nil,
    guildFlag           = nil,

    -- special resource & monster
    ownerId             = nil,
    ownerName           = nil,

    -- for player
    tradeCenterLevel    = nil,
    embassyLevel        = nil,
    protectTime         = nil,
    isMyCity            = false,

    -- for resource
    resType             = nil,
    remainResNum        = nil,

    -- for monster
    maxBlood            = nil,
    remainBlood         = nil,

    -- for camp
    marchId             = nil,

    -- for territory
    territoryType       = nil,
    territoryLevel      = nil,
    territoryId         = nil,
    isActive            = nil,
    -- bastion
    attackTimes         = nil,
    occupierId          = nil,
    occupierTag         = nil,
    occupierName        = nil,
    occupyTime          = nil,
    hasGarrison         = nil,
    -- super mine
    mineType            = nil,
    -- super weapon
    status              = nil,
    -- statue
    statueIcon          = nil,
    -- build silo
    buildStartTime      = nil,

    -- for president
    atPeace             = true,
    duration            = nil,
    presidentName       = nil,
    presidentEndTime    = nil
}

local RAWorldVar = RARequire('RAWorldVar')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldMath = RARequire('RAWorldMath')
local HudType = RAWorldConfig.HudBtnType
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')
local world_map_const_conf = RARequire('world_map_const_conf')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RABuildManager = RARequire('RABuildManager')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')


function RAWorldBuildingInfo:new(pointInfo)
    local obj = {}

    setmetatable(obj, self)
    self.__index = self

    if not obj:_init(pointInfo) then
        obj = nil
    end

    return obj
end

function RAWorldBuildingInfo:_init(pointInfo)
    if not self:_parsePointInfo(pointInfo) then
        return false
    end

    self.buildingId = RAWorldMath:GetMapPosId(pointInfo.pos)
    self.type = pointInfo.type
    self.coord = 
    {
        x = pointInfo.pos.x,
        y = pointInfo.pos.y, 
        k = RAWorldVar.KingdomId.Map
    }
    self.relationship = self:GetRelation()
    
    return true
end

function RAWorldBuildingInfo:_parsePointInfo(pointInfo)
    local _type = pointInfo.type
    
    -- 玩家
    if _type == World_pb.PLAYER then
        return self:_initPlayer(pointInfo)
    -- 资源
    elseif _type == World_pb.RESOURCE then
        return self:_initResource(pointInfo)
    -- 怪物
    elseif _type == World_pb.MONSTER then
        return self:_initMonster(pointInfo)
    -- 驻扎点
    elseif _type == World_pb.QUARTERED then
        return self:_initCamp(pointInfo)
    -- 联盟领地建筑
    elseif _type == World_pb.GUILD_TERRITORY then
        return self:_initTerritoryBuilding(pointInfo)
    -- 领地据点
    elseif _type == World_pb.GUILD_GUARD then
        return self:_initStronghold(pointInfo)
    -- 首都
    elseif _type == World_pb.KING_PALACE then
        return self:_initCapital(pointInfo)
    else
        return nil
    end
end

function RAWorldBuildingInfo:_initCapital(pointInfo)
    pointInfo.pos       = RAWorldVar.MapPos.Core
    
    self.img            = RAWorldConfig.Capital.Image
    self.name           = RAStringUtil:getLanguageString('@Capital')
    self.gridCnt        = RAWorldConfig.Capital.GridCnt
    self.icon           = RAWorldConfig.Capital.Icon

    if RAWorldVar:IsInSelfKingdom() then
        local periodInfo = RAPresidentDataManager:GetPeriodInfo()
        local presidentInfo = RAPresidentDataManager:GetPresidentInfo()
        local president_const_conf =RARequire('president_const_conf')

        local duration = 1
        if RAPresidentDataManager:IsAtPeace() then
            self.atPeace = true
            self.presidentName = presidentInfo.playerName
            if RAPresidentDataManager:IsIniting() then
                duration = president_const_conf.initPeaceTime.value * 1000
                self.presidentEndTime = (RAPlayerInfoManager.getServerOpenTime() or 0) + duration
            else
                duration = president_const_conf.commonPeaceTime.value * 1000
                self.presidentEndTime = (periodInfo.peaceStartTime or 0) + duration
            end
        else
            self.atPeace = false
            local tmpPresidentInfo = RAPresidentDataManager:GetTmpPresidentInfo()
            if tmpPresidentInfo.playerId then
                self.presidentName = tmpPresidentInfo.playerName
                duration = president_const_conf.occupationTime.value * 1000
                self.presidentEndTime = (periodInfo.attackStartTime or 0) + duration
                self.guildTag = tmpPresidentInfo.guildTag
            else
                self.presidentName = nil
                self.presidentEndTime = nil
                self.guildTag = nil
            end
        end

        self.guildFlag = presidentInfo.guildFlag
        self.name = Utilitys.getDisplayName(self.name, presidentInfo.guildTag)
        self.duration = duration
    else
        local crossServerInfo = RAPresidentDataManager:GetCrossServerInfo(RAWorldVar.KingdomId.Map) or {}
        if crossServerInfo.k then
            local presidentInfo = crossServerInfo.presidentInfo or {}
            self.guildFlag = presidentInfo.guildFlag
            self.name = Utilitys.getDisplayName(self.name, presidentInfo.guildTag)
        end
    end

    self.displayName    = self.name

    return true
end

function RAWorldBuildingInfo:_initPlayer(pointInfo)
    local playerId = pointInfo.playerInfo.id
    local isMyCity = RAPlayerInfoManager.isSelf(playerId)
    
    local playerIcon = RAPlayerInfoManager.getHeadIcon(pointInfo.playerInfo.icon)

    self.id = playerId
    self.playerId = playerId
    self.level = pointInfo.playerInfo.level or 1
    self.name = isMyCity and RAStringUtil:getLanguageString('@MyCity') or pointInfo.playerInfo.name
    self.state = BUILDING_ANIMATION_TYPE.IDLE_MAP
    self.iconId = pointInfo.playerInfo.icon
    self.icon = playerIcon
    self.protectTime = pointInfo.playerInfo.protectTime
    self.guildId = pointInfo.playerInfo.guildId
    self.guildTag = pointInfo.playerInfo.guildTag
    self.guildFlag = pointInfo.playerInfo.guildFlag
    self.tradeCenterLevel = pointInfo.playerInfo.tradeCenterLevel
    self.embassyLevel = pointInfo.playerInfo.embassyLevel
    self.gridCnt = 2
    self.spine = RAWorldConfigManager:GetCitySpineByLevel(self.level)
    self.lvPos = RAWorldConfigManager:GetCityLvOffsetByLevel(self.level)
    self.displayName = Utilitys.getDisplayName(self.name, self.guildTag)
    self.isMyCity = isMyCity
    self.hasGarrison = pointInfo.playerInfo.hasGarrison

    self:_initHurtTime(pointInfo)

    return true
end

function RAWorldBuildingInfo:_initResource(pointInfo)
    local resId = pointInfo.resourceInfo.id
    local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(resId)

    if resCfg.id == nil then
        common:log('>>>>>>>invalid res point (%d, %d) id: %d', pointInfo.pos.x, pointInfo.pos.y, resId)
        return false
    end

    self.id = resId
    self.resType = resCfg.resType
    self.img = resShowCfg.buildArtImg
    self.spine = resShowCfg.buildArtJson
    self.level = resCfg.level or 1
    self.name = RAStringUtil:getLanguageString(resShowCfg.resName) .. ' Lv: ' .. (resCfg.level or 1)
    self.icon = resShowCfg.resTargetIcon
    self.lvPos = RAWorldMath:GetMapPosFromId(resShowCfg.levelXy)
    self.marchId = pointInfo.resourceInfo.marchId
    self.playerId = pointInfo.resourceInfo.playerId
    self.playerName = pointInfo.resourceInfo.playerName
    self.playerIcon = RAPlayerInfoManager.getHeadIcon(pointInfo.resourceInfo.playerIconId)
    self.guildId = pointInfo.resourceInfo.guildId
    self.guildTag = pointInfo.resourceInfo.guildTag
    self.guildFlag = pointInfo.resourceInfo.guildFlag
    self.remainResNum = pointInfo.resourceInfo.remainResNum
    self.ownerId = pointInfo.ownerId
    self.ownerName = pointInfo.ownerName
    self.gridCnt = 1
    self.state = self:_getResourceState()

    if self.ownerId then
        self.displayName = _RALang('@SpecificPoint', self.ownerName)
    elseif not common:isEmptyStr(self.playerName) then
        self.displayName = Utilitys.getDisplayName(self.playerName, self.guildTag)
    end

    self:_initHurtTime(pointInfo)

    return true
end

function RAWorldBuildingInfo:_initMonster(pointInfo)
    local monsId = pointInfo.monsterInfo.id
    local monsCfg = RAWorldConfigManager:GetMonsterConfig(monsId)
    
    local gridTb = Utilitys.Split(monsCfg.areaSize, '_')
    local gridCnt = tonumber(gridTb[1] or 1)
    
    self.id = monsId
    self.spine = monsCfg.buildArtJson
    self.level = monsCfg.level or 1
    self.name = RAStringUtil:getLanguageString(monsCfg.name) .. ' Lv: ' .. monsCfg.level
    self.icon = monsCfg.icon
    self.gridCnt = gridCnt
    self.maxBlood = pointInfo.monsterInfo.maxBlood
    self.remainBlood = pointInfo.monsterInfo.remainBlood
    self.ownerId = pointInfo.ownerId
    self.ownerName = pointInfo.ownerName
    self.displayName = self.name
    
    if self.ownerId then
        self.displayName = _RALang('@SpecificPoint', self.ownerName)
    end

    return true
end

function RAWorldBuildingInfo:_initCamp(pointInfo)
    local RAWorldManager = RARequire('RAWorldManager')
    local name, icon = RAWorldManager:GetTileDetail(pointInfo.pos)
    local isMyCamp = RAPlayerInfoManager.isSelf(pointInfo.campInfo.playerId)
    
    self.id = RAWorldMath:GetMapPosId(pointInfo.pos)
    self.spine = RAWorldConfig.Spine.Camp
    self.playerId = pointInfo.campInfo.playerId
    self.playerIcon = RAPlayerInfoManager.getHeadIcon(pointInfo.campInfo.playerIconId)
    self.playerName = pointInfo.campInfo.playerName
    self.name = name
    self.icon = icon
    self.marchId = pointInfo.campInfo.marchId
    self.guildId = pointInfo.campInfo.guildId
    self.guildTag = pointInfo.campInfo.guildTag
    self.guildFlag = pointInfo.campInfo.guildFlag
    self.gridCnt = 1
    self.displayName = isMyCamp and _RALang('@MyCamp') or _RALang('@CampName', pointInfo.campInfo.playerName)
    
    self:_initHurtTime(pointInfo)

    return true
end

function RAWorldBuildingInfo:_initTerritoryBuilding(pointInfo)
    local serverInfo = pointInfo.territoryInfo
    local _typeId = serverInfo.terriId
    local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(_typeId)
    
    if cfg == nil or cfg.id == nil then 
        return false 
    end

    local _type = cfg.type

    self.id              = _typeId
    self.territoryType   = _type
    self.territoryLevel  = serverInfo.terriLevel or 1
    self.territoryId     = serverInfo.territoryId
    self.isActive        = serverInfo.isActive
    self.spine           = cfg.spine
    self.guildId         = serverInfo.guildId
    self.guildFlag       = serverInfo.guildFlag
    self.guildTag        = serverInfo.guildTag
    self.name            = Utilitys.getDisplayName(_RALang(cfg.name, serverInfo.terriLevel or 1), serverInfo.guildTag)
    self.icon            = cfg.icon
    self.attackTimes     = serverInfo.remainAttackedTimes
    self.gridCnt         = cfg.gridCnt

    if _type == Const_pb.GUILD_BASTION then
        self.occupierId     = serverInfo.occupierId
        self.occupierTag    = serverInfo.occupierTag
        self.occupierName   = serverInfo.occupierName
        self.occupyTime     = serverInfo.occupyTime
        self.hasGarrison    = serverInfo.hasGarrison

        self:_initHurtTime(pointInfo)
    elseif _type == Const_pb.GUILD_SILO
        or _type == Const_pb.GUILD_WEATHER
        or _type == Const_pb.GUILD_MOVABLE_BUILDING
    then
        self.status = serverInfo.nuclearStatus
        if self.status == World_pb.CAN_LAUNCH then
            self.state = BUILDING_ANIMATION_TYPE.READY_LAUNCH
        elseif self.status == World_pb.LAUNCHING then
            self.state = nil
        elseif self.status == World_pb.CANCEL then
            self.state = BUILDING_ANIMATION_TYPE.IDLE
        end
        self.cdTime = serverInfo.nuclearTime or 0
        
        if _type == Const_pb.GUILD_MOVABLE_BUILDING then
            self.buildStartTime = serverInfo.buildStartTime
            self.hasGarrison    = serverInfo.hasGarrison
        end
    elseif _type == Const_pb.GUILD_MINE then
        local mineType = serverInfo.guildMineType
        local mineCfg = RAWorldConfigManager:GetSuperMineCfg(mineType)
        if mineCfg.id then
            self.mineType   = mineType
            self.name       = Utilitys.getDisplayName(_RALang(mineCfg.name), serverInfo.guildTag)
            self.spine      = mineCfg.spine
            self.icon       = mineCfg.icon
        else
            common:log('>>>>>>>invalid super mine point (%d, %d) id: %s', pointInfo.pos.x, pointInfo.pos.y, tostring(mineType))
            return false
        end
    elseif _type == Const_pb.GUILD_STATUE then
        self.statueIcon = cfg.statuePicture
    end

    self.displayName = self.name

    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    RATerritoryDataManager:RecordOwnership(self.territoryId, self.guildId)

    return true
end

function RAWorldBuildingInfo:_initStronghold(pointInfo)
    local id = pointInfo.guardInfo.id
    
    local cfg = RAWorldConfigManager:GetStrongholdCfg(id)
    if cfg.id == nil then
        common:log('>>>>>>>invalid super stronghold point (%d, %d) id: %s', pointInfo.pos.x, pointInfo.pos.y, tostring(id))
        return false
    end

    local gridTb = Utilitys.Split(cfg.size, '_')
    local gridCnt = tonumber(gridTb[1] or 1)

    self.id              = id
    self.territoryId     = pointInfo.guardInfo.territoryId
    self.spine           = cfg.model
    self.icon            = cfg.icon
    self.name            = _RALang(cfg.armyName)
    self.attackTimes     = pointInfo.guardInfo.remainAttackedTimes
    self.gridCnt         = gridCnt
    self.displayName     = self.name

    return true
end

function RAWorldBuildingInfo:_getResourceState()
    local playerId = self.playerId or ''
    local state = playerId == '' and BUILDING_ANIMATION_TYPE.IDLE_MAP or BUILDING_ANIMATION_TYPE.WORKING_MAP

    if self.resType == Const_pb.GOLDORE then
        state = playerId == '' and BUILDING_ANIMATION_TYPE.IDLE or BUILDING_ANIMATION_TYPE.WORKING
    end

    return state
end

function RAWorldBuildingInfo:_initHurtTime(pointInfo)
    self.attackHurtEndTime = math.max(pointInfo.commonHurtEndTime or 0, pointInfo.nuclearHurtEndTime or 0)
    self.weatherHurtEndTime = pointInfo.weatherHurtEndTime or 0
end

-- 获取Hud按钮
function RAWorldBuildingInfo:getBtnTypeTB()
    -- 基地
    if self.type == World_pb.PLAYER then
        return self:_getBtnTypeTB_Player()
    end

    local relationship = self:GetRelation()
    local isMyKingdom = RAWorldVar:IsInSelfKingdom()
    local tbs = {}

    -- 资源
    if self.type == World_pb.RESOURCE then
        if relationship == World_pb.SELF then
            tbs = {HudType.Explain, HudType.Recall}
        elseif relationship == World_pb.GUILD_FRIEND then
            tbs = {HudType.GeneralDetail, HudType.Explain}
        elseif relationship == World_pb.ENEMY then
            if isMyKingdom then
                tbs = {HudType.GeneralDetail, HudType.Explain, HudType.Spy, HudType.Attack}
            else
                tbs = {HudType.GeneralDetail, HudType.Explain}
            end
        elseif relationship == World_pb.NONE then
            tbs = {HudType.Explain}
            if isMyKingdom then
                if self.ownerId ~= nil and not RAPlayerInfoManager.isSelf(self.ownerId) then
                    return {}
                else
                    table.insert(tbs, HudType.Collect)
                end
            end
        end
        return tbs
    end

    -- 驻扎
    if self.type == World_pb.QUARTERED then
        -- 自己的
        if relationship == World_pb.SELF then
            tbs = {HudType.ArmyDetail, HudType.Recall}
        elseif relationship == World_pb.GUILD_FRIEND then
            tbs = {HudType.GeneralDetail}
        -- 别人的
        else
            if isMyKingdom then
                tbs = {HudType.GeneralDetail, HudType.Spy, HudType.Attack}
            else
                tbs = {HudType.GeneralDetail}
            end
        end
        return tbs
    end

    -- 联盟领地建筑
    if self.type == World_pb.GUILD_TERRITORY then
        return self:_getBtnTypeTB_Territory()
    end

    -- 领地据点
    if self.type == World_pb.GUILD_GUARD then
        if isMyKingdom then
            tbs = {HudType.StrongholdDetail}

            if RAAllianceManager:IsInGuild() then
                table.insert(tbs, HudType.Attack)
                table.insert(tbs, HudType.Spy)
                -- 集结宣战
                if self:_isAbleToMass() then
                    table.insert(tbs, HudType.DeclareWar)
                end
            end
        else
            -- tbs = {HudType.StrongholdDetail}
        end
    end

    -- 元帅府
    if self.type == World_pb.KING_PALACE then
        return self:_getBtnTypeTB_President()
    end

    return tbs
end

function RAWorldBuildingInfo:_getBtnTypeTB_Player()
    local tbs = {}

    local relationship = self:GetRelation()
    -- 自己的
    if relationship == World_pb.SELF then
        tbs = {HudType.GeneralDetail, HudType.CityGain, HudType.EnterCity}
    -- 盟友的
    elseif relationship == World_pb.GUILD_FRIEND then
        tbs = {HudType.GeneralDetail}
        -- 士兵援助
        if self:_isAbleToSoldierAid() then
            table.insert(tbs, HudType.SoldierAid)
        end
        -- 资源援助
        if self:_isAbleToResourceAid() then
            table.insert(tbs, HudType.ResourceAid)
        end
    -- 别人的
    else
        local isMyKingdom = RAWorldVar:IsInSelfKingdom()
        -- 同服
        if isMyKingdom then
            tbs = {HudType.GeneralDetail, HudType.Attack, HudType.Spy}
            -- 宣战
            if self:_isAbleToMass() then
                table.insert(tbs, HudType.DeclareWar)
            end
        else
            tbs = {HudType.GeneralDetail}
        end
    end

    if self.hasGarrison then
        table.insert(tbs, HudType.Recall)
    end

    if RAPlayerInfoManager.IsPresident() and not self.isMyCity then
        table.insert(tbs, HudType.Appoint)
    end

    return tbs
end

function RAWorldBuildingInfo:_getBtnTypeTB_Territory()
    local tbs = {}

    local territoryType = self.territoryType
    local isMyKingdom = RAWorldVar:IsInSelfKingdom()
    local isActive = isMyKingdom and RAAllianceManager:IsActiveTerritory(self.territoryId)

    -- 联盟堡垒
    if territoryType == Const_pb.GUILD_BASTION then
        if not isMyKingdom then return tbs end

        local isAbleToAttack = true
        -- 领地是否有归属
        local isTerritoryOccupied = self.guildId ~= nil and self.guildId ~= ''
        -- 堡垒是否在占领者
        local hasOccupier = self.occupierId ~= nil and self.occupierId ~= ''

        if isTerritoryOccupied then
            -- 是自己盟的领地
            if RAAllianceManager:IsGuildFriend(self.guildId) then
                isAbleToAttack = false

                table.insert(tbs, HudType.TerritoryList)
                if hasOccupier and self.occupierId ~= self.guildId then
                    -- 被其它联盟攻占, 但尚未易主
                    table.insert(tbs, HudType.Reoccupy)
                    if self:_isAbleToMass() then
                        table.insert(tbs, HudType.MassReoccupy)
                    end
                    -- table.insert(tbs, HudType.Spy)
                else
                    -- 自己联盟占领
                    table.insert(tbs, HudType.Garrison)
                    if self:_isAbleToMass() then
                        table.insert(tbs, HudType.MassGarrison)
                    end

                    -- 有兵驻守
                    if self.hasGarrison then
                        table.insert(tbs, HudType.Recall)
                    end

                end
                -- table.insert(tbs, HudType.ViewGarrison_Territory)
            elseif RAAllianceManager:IsInGuild() then
                -- 其它盟占领
                if hasOccupier and RAAllianceManager:IsGuildFriend(self.occupierId) then
                    table.insert(tbs, HudType.TerritoryList)
                    -- 自己联盟占领，但尚未易主
                    table.insert(tbs, HudType.Reinforce)
                    if self:_isAbleToMass() then
                        table.insert(tbs, HudType.MassReinforce)
                    end

                    -- 有兵驻守
                    if self.hasGarrison then
                        table.insert(tbs, HudType.Recall)
                    end

                    -- table.insert(tbs, HudType.ViewGarrison_Territory)
                else
                    table.insert(tbs, HudType.ViewDetail)
                    table.insert(tbs, HudType.Attack)
                    -- 集结宣战
                    if self:_isAbleToMass() then
                        table.insert(tbs, HudType.DeclareWar)
                    end
                    table.insert(tbs, HudType.Spy)
                end
            else
                table.insert(tbs, HudType.ViewDetail)
            end
        -- npc占领，或者无人占领
        elseif RAAllianceManager:IsInGuild() then
            table.insert(tbs, HudType.ViewDetail)
            table.insert(tbs, HudType.Attack)
            -- 集结宣战
            if self:_isAbleToMass() then
                table.insert(tbs, HudType.DeclareWar)
            end
            table.insert(tbs, HudType.Spy)
        end

        return tbs
    end

    -- 联盟核弹发射井/联盟天气控制室
    if territoryType == Const_pb.GUILD_SILO
        or territoryType == Const_pb.GUILD_WEATHER
        or territoryType == Const_pb.GUILD_GUILD_URANIUM
        or territoryType == Const_pb.GUILD_ELECTRIC
        or territoryType == Const_pb.GUILD_SHOP
        or territoryType == Const_pb.GUILD_STATUE
    then
        if not isActive then return tbs end
        
        if RAAllianceManager:IsGuildFriend(self.guildId) then
            tbs = {HudType.ViewOwnership}
        end
        return tbs
    end

    -- 联盟超级矿
    if territoryType == Const_pb.GUILD_MINE then
        if not isActive then return tbs end
        
        if RAAllianceManager:IsGuildFriend(self.guildId) then
            table.insert(tbs, HudType.ViewDetail)

            local RAMarchDataManager = RARequire('RAMarchDataManager')
            -- 是否正在采集
            if RAMarchDataManager:CheckSelfSuperMineCollectStatus(true) then
                table.insert(tbs, HudType.Recall)
            else
                table.insert(tbs, HudType.Collect)
            end
        end

        return tbs
    end

    -- 联盟医院、联盟巨炮
    if territoryType == Const_pb.GUILD_HOSPITAL
        or territoryType == Const_pb.GUILD_CANNON
        or territoryType == Const_pb.GUILD_SHOP
    then
        if isActive and RAAllianceManager:IsGuildFriend(self.guildId) then
            tbs = {HudType.ViewDetail}
        end
    end

    -- 超级武器发射平台
    if territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
        if not isMyKingdom then return tbs end

        -- 自己联盟占领
        if RAAllianceManager:IsGuildFriend(self.guildId) then
            if self:IsBuildingFinished() then
                table.insert(tbs, HudType.ViewOwnership)
            end
            table.insert(tbs, HudType.Garrison)
            if self:_isAbleToMass() then
                table.insert(tbs, HudType.MassGarrison)
            end

            table.insert(tbs, HudType.ViewGarrison_Territory)
            -- 有兵驻守
            if self.hasGarrison then
                table.insert(tbs, HudType.Recall)
            end
        else
            table.insert(tbs, HudType.ViewDetail)
            table.insert(tbs, HudType.Attack)
            -- 集结宣战
            if self:_isAbleToMass() then
                table.insert(tbs, HudType.DeclareWar)
            end
            table.insert(tbs, HudType.Spy)
        end
    end

    return tbs
end

function RAWorldBuildingInfo:_getBtnTypeTB_President()
    local tbs = {}

    local isMyKingdom = RAWorldVar:IsInSelfKingdom()
    if not isMyKingdom then
        return tbs
    end
    
    tbs = {HudType.ViewDetail_President}

    -- 和平时期
    if RAPresidentDataManager:IsAtPeace() then
         return tbs
    end

    local tmpPresidentInfo = RAPresidentDataManager:GetTmpPresidentInfo() or {}
    -- 是自己盟占领
    if RAAllianceManager:IsGuildFriend(tmpPresidentInfo.guildId) then
        table.insert(tbs, HudType.Garrison_President)
        if self:_isAbleToMass() then
            table.insert(tbs, HudType.MassGarrison_President)
        end
        table.insert(tbs,  HudType.ViewGarrison_President)

        -- 有兵驻守
        if RAPresidentDataManager:HasGarrison() then
            table.insert(tbs, HudType.Recall_President)
        end
    else
        table.insert(tbs, HudType.Attack)
        -- 集结宣战
        if self:_isAbleToMass() then
            table.insert(tbs, HudType.DeclareWar)
        end
        table.insert(tbs, HudType.Spy)
    end

    return tbs
end

-- 获取显示hud时的音效
function RAWorldBuildingInfo:GetHudEffect()
    local _type = self.type
    if _type == World_pb.GUILD_TERRITORY then
        local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(self.id)
        return cfg.hudSound or 'mapClick'
    end
    return 'mapClick'
end

-- 能否可以资源(前提：是盟友)
function RAWorldBuildingInfo:_isAbleToResourceAid()
    -- 双方拥有建筑: 贸易中心
    return (RABuildManager:getBuildDataCountByType(Const_pb.TRADE_CENTRE) > 0
        and (self.tradeCenterLevel or 0) > 0)
end

-- 能否可以资源/士兵援助(前提：是盟友)
function RAWorldBuildingInfo:_isAbleToSoldierAid()
    -- 双方拥有建筑: 大使馆
   return (RABuildManager:getBuildDataCountByType(Const_pb.EMBASSY) > 0
        and (self.embassyLevel or 0) > 0)
end

-- 能否集结
function RAWorldBuildingInfo:_isAbleToMass()
    if not RAWorldUtil:IsAbleToMass() then return false end

    if self.type == World_pb.PLAYER then
        -- 目标有盟 或者 大本等级>=6
        if self.guildId and self.guildId ~= '' then return true end

        return self.level >= world_map_const_conf.stepCityLevel1.value
    else
        return true
    end
end

-- 判断路点和自己的关系
function RAWorldBuildingInfo:GetRelation()
    -- 基地
    if self.type == World_pb.PLAYER then
        if RAPlayerInfoManager.isSelf(self.id) then
            return World_pb.SELF
        elseif RAAllianceManager:IsGuildFriend(self.guildId) then
            return World_pb.GUILD_FRIEND
        else
            return World_pb.ENEMY
        end
    end

    -- 资源
    if self.type == World_pb.RESOURCE then
        -- 判断是不是无人占领
        if self.playerId == nil or self.playerId == '' then
            return World_pb.NONE
        end

        -- 判断自己
        local isSelf = RAPlayerInfoManager.isSelf(self.playerId)
        if isSelf then
            return World_pb.SELF
        end

        -- 判断联盟
        if RAAllianceManager:IsGuildFriend(self.guildId) then
            return World_pb.GUILD_FRIEND
        end

        -- 最后就是敌人了
        return World_pb.ENEMY
    end

    -- 怪物
    if self.type == World_pb.MONSTER then
        return World_pb.ENEMY
    end

    -- 驻扎
    if self.type == World_pb.QUARTERED then
        if RAPlayerInfoManager.isSelf(self.playerId) then
            return World_pb.SELF
        elseif RAAllianceManager:IsGuildFriend(self.guildId) then
            return World_pb.GUILD_FRIEND
        else
            return World_pb.ENEMY
        end
    end

    -- 领地建筑
    if self.type == World_pb.GUILD_TERRITORY then
        return RAWorldUtil:GetTerritoryRelationship(self.guildId, {isActive = self.isActive})
    end

    -- 据点
    if self.type == World_pb.GUILD_GUARD then
        return World_pb.ENEMY
    end

    return World_pb.NONE
end

function RAWorldBuildingInfo:IsFearOfSuperWeapon(weaponType)
    if weaponType == Const_pb.GUILD_WEATHER then
        return self.type == World_pb.PLAYER
    elseif weaponType == Const_pb.GUILD_SILO then
        if self.type == World_pb.PLAYER
            or self.type == World_pb.RESOURCE
            or self.type == World_pb.QUARTERED
            or (self.type == World_pb.GUILD_TERRITORY and self.territoryType == Const_pb.GUILD_BASTION)
        then
            return true
        end
    end

    return false
end

function RAWorldBuildingInfo:GetPresidentTimerStr()
    if self.presidentEndTime == nil then return '' end

    local passTime = self.presidentEndTime - common:getCurMilliTime()
    if passTime <= 0 then return '' end

    local duration = math.ceil(passTime / 1000)
    local timerStr = Utilitys.createTimeWithFormat(duration)
    local progress = tonumber(string.format('%.2f', passTime / self.duration))
    progress = common:clamp(progress, 0, 1.0)
    if self.atPeace then
        return _RALang('@PresidentPeaceTimer', timerStr), progress
    else
        return _RALang('@PresidentWarfareTimer', self.guildTag, timerStr), progress
    end
end

function RAWorldBuildingInfo:GetPresidentNameIcon()
    local period = RAPresidentDataManager:GetCurrentPeriod()
    local RAPresidentConfig = RARequire('RAPresidentConfig')
    return RAPresidentConfig.NameIcon[period] or 'President_u_Deco_01.png'
end

function RAWorldBuildingInfo:GetPresidentPeriodIcon()
    local period = RAPresidentDataManager:GetCurrentPeriod()
    local RAPresidentConfig = RARequire('RAPresidentConfig')
    return RAPresidentConfig.PeriodIcon[period] or 'President_HUD_Icon_Pace.png'
end

function RAWorldBuildingInfo:GetBastionTimerStr()
    if self.occupyTime == nil then return '' end

    if self.duration == nil then
        local guild_const_conf = RARequire('guild_const_conf')
        self.duration = guild_const_conf.guildManorOccupyTime.value * 1000
    end
    local passTime = self.occupyTime + self.duration - common:getCurMilliTime()
    if passTime <= 0 then return '' end

    local duration = math.ceil(passTime / 1000)
    local timerStr = Utilitys.createTimeWithFormat(duration)
    local progress = tonumber(string.format('%.2f', passTime / self.duration))
    progress = common:clamp(progress, 0, 1.0)
    local key = RAAllianceManager:IsGuildFriend(self.guildId) and '@TerritoryLosingTimer' or '@TerritoryOccupyTimer'
    return _RALang(key, self.occupierTag, timerStr), progress
end

function RAWorldBuildingInfo:GetBuildSiloTimerStr()
    if self.buildStartTime == nil then return '' end

    if self.duration == nil then
        local guild_const_conf = RARequire('guild_const_conf')
        self.duration = guild_const_conf.platformBuilding.value * 1000
    end
    local passTime = self.buildStartTime + self.duration - common:getCurMilliTime()
    if passTime <= 0 then return '' end

    local duration = math.ceil(passTime / 1000)
    local timerStr = Utilitys.createTimeWithFormat(duration)
    local progress = tonumber(string.format('%.2f', passTime / self.duration))
    progress = common:clamp(progress, 0, 1.0)
    return _RALang('@BuildSiloTimer', timerStr), progress
end

function RAWorldBuildingInfo:IsBuildingFinished()
    local startTime = self.buildStartTime or 0
    if startTime <= 0 then return true end
    if self.duration == nil then
        local guild_const_conf = RARequire('guild_const_conf')
        self.duration = guild_const_conf.platformBuilding.value * 1000
    end
    return (self.buildStartTime + self.duration) <= common:getCurMilliTime()
end

return RAWorldBuildingInfo

--endregion