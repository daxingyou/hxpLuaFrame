--region *.lua
--Date

local RAWorldProtoHandler =
{
    handlers = {}
}

local HP_pb = RARequire('HP_pb')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')
local GuildManor_pb = RARequire('GuildManor_pb')
local President_pb = RARequire('President_pb')
local RANetUtil = RARequire('RANetUtil')
local RAWorldManager = RARequire('RAWorldManager')
local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')

local protoIds =
{
    -- world point
    HP_pb.WORLD_POINT_SYNC,

    -- battle    
    HP_pb.BATTLE_INFO_S,

    -- 联盟领地
    HP_pb.LAUNCH_NUCLEAR_BOMB_S,
    -- 迷雾
    HP_pb.WORLD_MANOR_MIST_PUSH,

    -- president
    HP_pb.OFFICER_INFO_SYNC_S,
    HP_pb.PRESIDENT_GIFT_INFO_S
}


function RAWorldProtoHandler:registerPacketListener()
    self.handlers = RANetUtil:addListener(protoIds, self)
end

function RAWorldProtoHandler:removePacketListener()
    RANetUtil:removeListener(self.handlers)
end

function RAWorldProtoHandler:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.WORLD_POINT_SYNC then
        local msg = World_pb.WorldPointSync()
        msg:ParseFromString(buffer)
        self:_onWorldPointSync(msg)
        return
    end

    if opcode == HP_pb.BATTLE_INFO_S then
        local msg = World_pb.HPBattleResultInfoSync()
        msg:ParseFromString(buffer)
        self:_onBattleRsp(msg)
        return
    end

    if opcode == HP_pb.LAUNCH_NUCLEAR_BOMB_S then
        local msg = GuildManor_pb.HPOperationResult()
        msg:ParseFromString(buffer)
        self:_onTerritoryOperationRsp(opcode, msg)
        return
    end

    if opcode == HP_pb.WORLD_MANOR_MIST_PUSH then
        local msg = GuildManor_pb.WorldManorMistPush()
        msg:ParseFromString(buffer)
        self:_onGetMistInfoRsp(msg)
        return
    end

    if opcode == HP_pb.OFFICER_INFO_SYNC_S then
        local msg = President_pb.OfficerInfoSync()
        msg:ParseFromString(buffer)
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:SyncOfficialInfo(msg)
        return
    end

    if opcode == HP_pb.PRESIDENT_GIFT_INFO_S then
        local msg = President_pb.PresidentGiftInfo()
        msg:ParseFromString(buffer)
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:SyncGiftInfo(msg)
        return
    end
end

--------------------------------------------------------------------------------------
-- region: world point

function RAWorldProtoHandler:sendEnterSignal(pos)
    self:tryGetMistInfo(pos)

    local msg = World_pb.PlayerEnterWorld()
    msg.x = pos.x
    msg.y = pos.y
    msg.serverId = RAWorldUtil.kingdomId.tostring(RAWorldVar.KingdomId.Self)
    RANetUtil:sendPacket(HP_pb.PLAYER_ENTER_WORLD, msg, {waitingTime = 0, retOpcode = -1})

    RAWorldVar:UpdateServerCenter(pos)
end

function RAWorldProtoHandler:sendMoveSignal(pos)
    self:tryGetMistInfo(pos)

    local msg = World_pb.PlayerWorldMove()
    msg.x = pos.x
    msg.y = pos.y
    msg.serverId = RAWorldUtil.kingdomId.tostring(RAWorldVar.KingdomId.Self)
    msg.speed = RAWorldVar.MoveSpeed or 0
    RANetUtil:sendPacket(HP_pb.PLAYER_WORLD_MOVE, msg, {waitingTime = 0, retOpcode = -1})

    CCLuaLog('---Sync Speed----------' .. msg.speed)

    RAWorldVar:UpdateServerCenter(pos)
    RAWorldVar:UpdateSyncSpeed(msg.speed)
    RAWorldBuildingManager:clearCache(pos)
end

function RAWorldProtoHandler:sendLeaveSignal()
    local msg = World_pb.PlayerLeaveWorld()
    msg.serverId = RAWorldUtil.kingdomId.tostring(RAWorldVar.KingdomId.Self)
    RANetUtil:sendPacket(HP_pb.PLAYER_LEAVE_WORLD, msg, {waitingTime = 0, retOpcode = -1})   
end

function RAWorldProtoHandler:sendFetchPointsReq(pos, k)
    local msg = World_pb.FetchInviewWorldPoint()
    msg.x = pos.x
    msg.y = pos.y
    msg.serverId = RAWorldUtil.kingdomId.tostring(k)
    msg.speed = RAWorldVar.MoveSpeed
    RANetUtil:sendPacket(HP_pb.FETCH_INVIEW_WORLD_POINT, msg, {waitingTime = 0, retOpcode = -1}) 

    RAWorldVar:UpdateServerCenter(pos) 
end


function RAWorldProtoHandler:_onWorldPointSync(msg)
    local k = RAWorldVar.KingdomId.Self
    if msg:HasField('serverId') then
        k = RAWorldUtil.kingdomId.tonumber(msg.serverId)
    end
    if k ~= RAWorldVar.KingdomId.Map then return end

    local isRemove = msg:HasField('isRemove') and msg.isRemove or false

    common:log('<<<<<<<<Point Sync----%d for %s', #msg.points, isRemove and 'remove' or 'add')
    if not isRemove then
        self:_addBuildings(msg.points)
    else
        self:_removeBuildings(msg.points)
    end
end

-- add or update
function RAWorldProtoHandler:_addBuildings(points)
    for _, pointPB in ipairs(points) do
        local _type = pointPB.pointType
        local _isValid = true
        local pointInfo = 
        {
            pos = RACcp(pointPB.pointX, pointPB.pointY),
            type = _type,
            k = RAWorldVar.KingdomId.Map,
            ownerId = pointPB.ownerId,
            ownerName = pointPB.ownerName
        }

        if pointInfo.ownerId == '' then
            pointInfo.ownerId = nil
            pointInfo.ownerName = ''
        end

        if _type == World_pb.MONSTER then
            pointInfo.monsterInfo = 
            {
                id = pointPB.monsterId,
                remainBlood = pointPB.remainBlood,
                maxBlood = pointPB.monsterMaxBlood
            }
            _isValid = pointPB.monsterId > 0
        elseif _type == World_pb.PLAYER then
            pointInfo.playerInfo =
            {
                id = pointPB.playerId,
                name = pointPB.playerName,
                icon = pointPB.playerIcon,
                level = pointPB.cityLevel or 1,
                guildId = pointPB.guildId,
                guildTag = pointPB.guildTag,
                guildFlag = pointPB.guildFlag or 0,
                tradeCenterLevel = pointPB.tradeCenterLevel or 0,
                embassyLevel = pointPB.embassyLevel or 0,
                protectTime = pointPB:HasField('protectedEndTime') and pointPB.protectedEndTime or 0,
                hasGarrison = pointPB:HasField('hasMarchStop') and pointPB.hasMarchStop or false
            }
            _isValid = pointPB.playerId ~= ''
        elseif _type == World_pb.RESOURCE then
            pointInfo.resourceInfo =
            {
                id = pointPB.resourceId,
                remainResNum = pointPB.remainResNum,
                guildId = pointPB.guildId,
                guildTag = pointPB.guildTag,
                guildFlag = pointPB.guildFlag or 0,
                marchId = pointPB.marchId,
                playerId = pointPB.playerId,
                playerName = pointPB.playerName,
                playerIconId = pointPB.playerIcon,
            }
            _isValid = pointPB.resourceId > 0
        elseif _type == World_pb.QUARTERED then
            pointInfo.campInfo =
            {
                guildId = pointPB.guildId,
                guildTag = pointPB.guildTag,
                guildFlag = pointPB.guildFlag or 0,
                marchId = pointPB.marchId,
                playerId = pointPB.playerId,
                playerName = pointPB.playerName,
                playerIconId = pointPB.playerIcon,
            }
        elseif _type == World_pb.GUILD_TERRITORY 
            or _type == World_pb.MOVEABLE_BUILDING
        then
            pointInfo.territoryInfo =
            {
                guildId = pointPB.guildId,
                guildTag = pointPB.guildTag,
                guildFlag = pointPB.guildFlag or 0,
                terriId = pointPB.terriId,
                terriLevel = pointPB.terriLevel,
                territoryId = pointPB.manorId,
                remainAttackedTimes = pointPB.guardRemainTimes,
                guildMineType = pointPB.guildMineType,
                occupierId = pointPB.attackGuildId,
                occupierTag = pointPB.attackGuildTag,
                occupierName = pointPB.attackGuildName,
                occupyTime = pointPB.attackStartTime,
                hasGarrison = pointPB.hasMarchStop,
                nuclearStatus = pointPB.nuclearStatus,
                nuclearTime = pointPB.nuclearTime,
                marchId = pointPB.marchId,
                isActive = pointPB.manorState == GuildManor_pb.BASTION_EFFECTED,
                buildStartTime = pointPB.buildStartTime
            }
            if _type == World_pb.MOVEABLE_BUILDING then
                pointInfo.type = World_pb.GUILD_TERRITORY
            end
        elseif _type == World_pb.GUILD_GUARD then
            pointInfo.guardInfo =
            {
                id = pointPB.guardId,
                territoryId = pointPB.manorId,
                remainAttackedTimes = pointPB.guardRemainTimes
            }
        end

        if pointPB:HasField('commonHurtEndTime') then
            pointInfo.commonHurtEndTime = pointPB.commonHurtEndTime
        end
        if pointPB:HasField('nuclearHurtEndTime') then
            pointInfo.nuclearHurtEndTime = pointPB.nuclearHurtEndTime
        end
        if pointPB:HasField('weatherHurtEndTime') then
            pointInfo.weatherHurtEndTime = pointPB.weatherHurtEndTime
        end
        
        if _isValid then
            RAWorldBuildingManager:addBuilding(pointInfo)
        else
            common:log('>>>>>>>invalid point (%d, %d)  index: %d, type: %d', pointPB.pointX, pointPB.pointY, _, _type)
        end
    end
    RAWorldBuildingManager:markAddingBuildings()
end

function RAWorldProtoHandler:_removeBuildings(points)
    for _, pnt in ipairs(points) do
        RAWorldBuildingManager:removeBuilding(RACcp(pnt.pointX, pnt.pointY))
    end
end

-- endregion: world point
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: favorite

function RAWorldProtoHandler:sendAddFavorite(coord, name, type, targetType)
    local msg = World_pb.WorldFavoriteAddReq()
    msg = self:_initFavoritePB(msg, coord, name, type, targetType)
    RANetUtil:sendPacket(HP_pb.WORLD_FAVORITE_ADD_C, msg, {retOpcode = -1})
end

function RAWorldProtoHandler:sendUpdateFavorite(coord, name, type, targetType, id)
    local msg = World_pb.WorldFavoriteUpdateReq()
    msg = self:_initFavoritePB(msg, coord, name, type, targetType, id)
    RANetUtil:sendPacket(HP_pb.WORLD_FAVORITE_UPDATE_C, msg, {retOpcode = -1})
end

function RAWorldProtoHandler:sendDeleteFavorite(idTB)
    local msg = World_pb.WorldFavoriteDelteReq()
    for _, id in ipairs(idTB) do
        msg.favoriteId:append(id)
    end
    RANetUtil:sendPacket(HP_pb.WORLD_FAVORITE_DELETE_C, msg, {retOpcode = -1})
end

function RAWorldProtoHandler:_initFavoritePB(msg, coord, name, type, targetType, id)
    msg.info.tag = type
    msg.info.type = targetType
    msg.info.name = name
    msg.info.serverId = coord.k
    msg.info.posX = coord.x
    msg.info.posY = coord.y
    if id ~= nil then
        msg.info.favoriteId = id
    end

    return msg
end

-- endregion: favorite
--------------------------------------------------------------------------------------

--
-- 迁城相关
--
function RAWorldProtoHandler:sendMigrateReq(coord, type)
    local msg = World_pb.WorldMoveCityReq()
    msg.type = type or World_pb.SELECT_MOVE
    if coord and coord.x and coord.y then
        msg.x = coord.x
        msg.y = coord.y
        
        local k = coord.k or RAWorldVar.KingdomId.Map
        msg.serverId = RAWorldUtil.kingdomId.tostring(k)
    end
    RANetUtil:sendPacket(HP_pb.WORLD_MOVE_CITY_C, msg)
end

--
-- 战斗相关
--
function RAWorldProtoHandler:_onBattleRsp(msg)
    local attackerInfo =
    {
        -- 兵种id列表
        armyIdList = {},
        -- 总兵量
        total = 0,
        -- 损失数量
        loss = 0
    }

    local armyIdList = {}
    for _, battleResult in ipairs(msg.myBattleResult) do
        table.insert(armyIdList, battleResult.armyId)
        attackerInfo.total = attackerInfo.total + battleResult.totalCount
        attackerInfo.loss = attackerInfo.loss + battleResult.dieCount
    end
    if #armyIdList > 0 then
        local RAArsenalManager = RARequire('RAArsenalManager')
        local categoryMap = RAArsenalManager:getCatagoryMapByArmyIdList(armyIdList)
        attackerInfo.armyIdList = common:table_keys(categoryMap)
    end

    local defenserInfo = {total = 0, loss = 0}
    for _, battleResult in ipairs(msg.oppBattleResult) do
        defenserInfo.total = defenserInfo.total + battleResult.totalCount
        defenserInfo.loss = defenserInfo.loss + battleResult.dieCount
    end

    local isAttackerWin = msg.isWin == Const_pb.SUCCESS
    local isDefenserDead = msg.isMonsterDead
    local marchId = msg.marchId

    local RABattleManager = RARequire('RABattleManager')
    RABattleManager:onBattleRsp(attackerInfo, defenserInfo, isAttackerWin, isDefenserDead, marchId)
end

--
-- 行军召回(城点上的行军)
--
function RAWorldProtoHandler:sendRecallPointMarchReq(coord)
    local msg = World_pb.WorldPointMarchCallBackReq()
    msg.x = coord.x
    msg.y = coord.y
    RANetUtil:sendPacket(HP_pb.WORLD_POINT_MARCH_CALLBACK_C, msg)
end

--------------------------------------------------------------------------------------
-- region: territory

-- 发射核弹
function RAWorldProtoHandler:sendLaunchBombReq(mapPos)
    local msg = GuildManor_pb.HPLaunchManorNuclear()
    msg.firePosX = mapPos.x
    msg.firePosY = mapPos.y
    RANetUtil:sendPacket(HP_pb.LAUNCH_NUCLEAR_BOMB_C, msg)
end

function RAWorldProtoHandler:_onTerritoryOperationRsp(opcode, msg)
	if opcode == HP_pb.LAUNCH_NUCLEAR_BOMB_S then
		local RAWorldUIManager = RARequire('RAWorldUIManager')
		RAWorldUIManager:OnTargetRsp(msg.result)
	end
end

function RAWorldProtoHandler:tryGetMistInfo(mapPos)
    local territoryId = RAWorldManager:GetTerritoryIdInView(mapPos) or 0
    if territoryId ~= RAWorldVar.TerritoryId then
        if territoryId > 0 then
            self:sendGetMistInfoReq(territoryId)
            RAWorldVar.TerritoryId = territoryId
        else
            local RAWorldMistManager = RARequire('RAWorldMistManager')
            RAWorldMistManager:Clear()
        end
    end
end

function RAWorldProtoHandler:sendGetMistInfoReq(territoryId)
    local msg = GuildManor_pb.HPGetGuildManorInfoReq()
    msg.manorId = territoryId
    RANetUtil:sendPacket(HP_pb.GET_GUILD_MANOR_INFO_C, msg, {retOpcode = HP_pb.WORLD_MANOR_MIST_PUSH})
end

function RAWorldProtoHandler:_onGetMistInfoRsp(msg)
    -- 不在当前视野范围内不处理
    if msg.manorId ~= RAWorldVar.TerritoryId then return end

    local openPosTb = {}
    for _, info in ipairs(msg.mistInfos) do
        if info.isOpen then
            table.insert(openPosTb, RACcp(info.x, info.y))
        end
    end
    local RAWorldMistManager = RARequire('RAWorldMistManager')
    RAWorldMistManager:AddMist(msg.manorId, openPosTb)

    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    RATerritoryDataManager:RecordOwnership(msg.manorId, msg.guildId)
end


-- 获取玩家联盟当前的领地列表数据
function RAWorldProtoHandler:sendGetBationsReq()
    RANetUtil:sendPacket(HP_pb.GET_GUILD_MANOR_BASTION_SHOW_LIST_C)
end

-- 获取单个领地的详细数据，驻军什么的
function RAWorldProtoHandler:sendGetGarrisonReq(territoryId, posX, posY)
    local msg = GuildManor_pb.GetManorBastionMarchGarrionsReq()
    msg.manorId = territoryId
    if posX ~= nil and posY ~= nil then
        msg.x = posX
        msg.y = posY
    end
    RANetUtil:sendPacket(HP_pb.GET_GUILD_BASTION_MARCH_GARRISON_LIST_C, msg)
end

-- 切换领地
function RAWorldProtoHandler:sendActivateBastionReq(territoryId, isCancel)
    local msg = GuildManor_pb.HPGuildManorSwitch()
    msg.manorId = territoryId
    -- 设置为生效
    msg.operation = 1
    if isCancel then
        -- 取消生效
        msg.operation = 2
    end
    RANetUtil:sendPacket(HP_pb.SWITCH_GUILD_MANOR_C, msg, {retOpcode = -1})
end

function RAWorldProtoHandler:sendGetGarrisonMarchReq(territoryId, marchId, status)
    local msg = GuildManor_pb.GetMarchGarrisonsReq()
    msg.manorId = territoryId
    msg.marchId = marchId
    msg.status = status
    RANetUtil:sendPacket(HP_pb.GET_MARCH_GARRISON_C, msg)
end

function RAWorldProtoHandler:sendBuildSiloReq(mapPos)
    local msg = GuildManor_pb.HPNuclearMachineCreate()
    msg.posX = mapPos.x
    msg.posY = mapPos.y
    RANetUtil:sendPacket(HP_pb.NUCLEAR_MACHINE_CREATE_C, msg, {retOpcode = -1})
end

-- endregion: territory
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: president

-- 获取指定服的元帅战信息
function RAWorldProtoHandler:sendFetchPresidentInfoReq(k)
    local msg = President_pb.FetchPresidentInfoReq()
    local serverId = k or RAWorldVar.KingdomId.Map
    msg.serverName = RAWorldUtil.kingdomId.tostring(serverId)
    RANetUtil:sendPacket(HP_pb.FETCH_PRESIDENT_INFO, msg, {retOpcode = HP_pb.PRESIDENT_INFO_SYNC})
end

-- 设置王国名字、图像
function RAWorldProtoHandler:sendSetCountryInfoReq(info)
    info = info or {}
    local isValid = false

    local msg = President_pb.CountryInfoSettingReq()
    if info.name then
        msg.countryName = info.name
        isValid = true
    end
    if info.icon then
        msg.countryIcon = info.icon
        isValid = true
    end

    if isValid then
        RANetUtil:sendPacket(HP_pb.COUNTRY_INFO_SETTING_C, msg, {retOpcode = -1})
    end
end

-- 获取官职信息
function RAWorldProtoHandler:sendGetOfficialsReq()
    RANetUtil:sendPacket(HP_pb.OFFICER_INFO_SYNC_C)
end

-- 任命官职
function RAWorldProtoHandler:sendAppointOfficialReq(playerId,  officeId)
    local msg = President_pb.OfficerSetReq()
    msg.playerId = playerId
    msg.officerId = officeId
    RANetUtil:sendPacket(HP_pb.OFFICER_SET_C, msg, {retOpcode = -1})
 end

 -- 撤职
 function RAWorldProtoHandler:sendDismissOfficialReq(playerId, officeId)
     local msg = President_pb.OfficerSetReq()
    msg.playerId = playerId
    msg.officerId = officeId
    RANetUtil:sendPacket(HP_pb.OFFICER_UNSET_C, msg, {retOpcode = -1})
 end

-- 获取官职任命记录
 function RAWorldProtoHandler:sendGetAppointmentRecordReq()
    RANetUtil:sendPacket(HP_pb.OFFICER_RECORD_SYNC_C)
 end

-- 获取国王战礼包数据
function RAWorldProtoHandler:sendGetPresidentGiftInfoReq()
    RANetUtil:sendPacket(HP_pb.PRESIDENT_GIFT_INFO_C)
end

-- 国王战授予礼包
function RAWorldProtoHandler:sendGrantPresidentGiftReq(giftId, playerIds)
    local msg = President_pb.PresidentSendGiftReq()
    msg.giftId = giftId
    for _, playerId in ipairs(playerIds or {}) do
        msg.playerIds:append(playerId)
    end
    RANetUtil:sendPacket(HP_pb.PRESIDENT_SEND_GIFT_C, msg, {retOpcode = -1})
end

-- 获取国王战礼包颁发记录
function RAWorldProtoHandler:sendGetPresidentGiftRecordReq()
    RANetUtil:sendPacket(HP_pb.PRESIDENT_GIFT_RECORD_C)
end

-- 搜索玩家
function RAWorldProtoHandler:sendSearchPlayerReq(name)
    local msg = President_pb.PresidentSearchReq()
    msg.name = name
    RANetUtil:sendPacket(HP_pb.PRESIDENT_SEARCH_C, msg)
end

-- endregion: president
--------------------------------------------------------------------------------------

return RAWorldProtoHandler

--endregion
