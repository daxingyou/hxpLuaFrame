--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAWorldUtil =
{
    corePos = nil,
    bankArea = nil,
    cornerPos = nil
}

local tonumber = tonumber
local substr = string.sub

local RAWorldVar = RARequire('RAWorldVar')
local RAWorldMath = RARequire('RAWorldMath')
local World_pb = RARequire('World_pb')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAMarchConfig = RARequire('RAMarchConfig')
local common = RARequire('common')

RAWorldUtil.kingdomId = {
    ['tostring'] = function (id)
        return 's' .. id
    end,
    ['tonumber'] = function (k)
        return tonumber(substr(k or 's1', 2))
    end,
    ['isSelf'] = function (k)
        k = k or RAWorldVar.KingdomId.Map
        return k == RAWorldVar.KingdomId.Self
    end
}

function RAWorldUtil:IsMyCity(playerId)
    
end

-- 是否在黑土地真实范围内
-- 格子数据，与后端同步
function RAWorldUtil:IsInBankArea(mapPos)
    if mapPos == nil then return false end

    local cornerPos = RAWorldVar.MapPos.BankCorner
    local bankSize = RAWorldVar.MapPos.BankSize

    return RAWorldMath:IsInDiamondArea(mapPos, cornerPos, bankSize, true)
end

-- 获取黑土地线段数据，map data
function RAWorldUtil:GetMapBankBorders()
    local Utilitys = RARequire('Utilitys')
    local cornerPos = RAWorldVar.MapPos.BankCorner
    local left = Utilitys.ccpCopy(cornerPos.left)
    local right = Utilitys.ccpCopy(cornerPos.right)
    local top = Utilitys.ccpCopy(cornerPos.top)
    local bottom = Utilitys.ccpCopy(cornerPos.bottom)
    local l_t = {beginPos = left, endPos = top}
    local t_r = {beginPos = top, endPos = right}
    local r_b = {beginPos = right, endPos = bottom}
    local b_l = {beginPos = bottom, endPos = left}
    local result = {l_t, t_r, r_b, b_l}
    return result, l_t, t_r, r_b, b_l
end

-- 是否在黑土地显示范围内
-- View数据，前端展示使用
function RAWorldUtil:IsInBankViewArea(viewPos)
    if viewPos == nil then return false end
    
    local cornerPos = RAWorldVar.ViewPos.BankCorner
    local bankSize = RAWorldVar.ViewPos.BankSize

    return RAWorldMath:IsInDiamondArea(viewPos, cornerPos, bankSize)
end

-- 获取黑土地线段数据，view data
function RAWorldUtil:GetViewBankBorders()
    local Utilitys = RARequire('Utilitys')
    local cornerPos = RAWorldVar.ViewPos.BankCorner
    local left = Utilitys.ccpCopy(cornerPos.left)
    local right = Utilitys.ccpCopy(cornerPos.right)
    local top = Utilitys.ccpCopy(cornerPos.top)
    local bottom = Utilitys.ccpCopy(cornerPos.bottom)
    local l_t = {beginPos = left, endPos = top}
    local t_r = {beginPos = top, endPos = right}
    local r_b = {beginPos = right, endPos = bottom}
    local b_l = {beginPos = bottom, endPos = left}
    local result = {l_t, t_r, r_b, b_l}
    return result, l_t, t_r, r_b, b_l
end

-- 是否在首都
function RAWorldUtil:IsInCapital(mapPos)
    if mapPos == nil then return false end

    local cornerPos = RAWorldVar.MapPos.CapitalCorner
    local CapitalCnt = RARequire('RAWorldConfig').Capital.GridCnt
    local size = RACcp(CapitalCnt, CapitalCnt)

    return RAWorldMath:IsInDiamondArea(mapPos, cornerPos, size, true)
end

-- @return: WorldPointType_id
function RAWorldUtil:GetFavoriteType(buildingInfo)
    local idStr = buildingInfo.id or ''
    if buildingInfo.type == World_pb.PLAYER then
        idStr = buildingInfo.iconId or ''
    end
    return buildingInfo.type .. '#' .. idStr
end

function RAWorldUtil:GetFavoriteIcon(favoType)
    local typeTB = RAStringUtil:split(favoType, '#', 2) or {}
    local pointType, id = typeTB[1], typeTB[2]
    pointType = tonumber(pointType)

    local icon = ''
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    if pointType == World_pb.PLAYER then
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        id = tonumber(id)
        icon = RAPlayerInfoManager.getHeadIcon(id)
    elseif pointType == World_pb.RESOURCE then
        id = tonumber(id)
        local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(id)
        icon = resShowCfg.resTargetIcon
    elseif pointType == World_pb.MONSTER then
        id = tonumber(id)
        local monsCfg = RAWorldConfigManager:GetMonsterConfig(id)
        icon = monsCfg.icon
    elseif pointType == World_pb.GUILD_GUARD then
        id = tonumber(id)
        local strongholdCfg = RAWorldConfigManager:GetStrongholdCfg(id)
        icon = strongholdCfg.icon
    elseif pointType == World_pb.GUILD_TERRITORY then
        id = tonumber(id)
        local terrCfg = RAWorldConfigManager:GetTerritoryBuildingCfg(id)
        icon = terrCfg.icon
    elseif pointType == World_pb.EMPTY 
        or pointType == World_pb.QUARTERED 
    then
        local mapPos = RAWorldMath:GetMapPosFromId(id)
        local RAWorldManager = RARequire('RAWorldManager')
        local name = nil
        name, icon = RAWorldManager:GetTileDetail(mapPos)
    elseif pointType == World_pb.KING_PALACE then
        local RAWorldConfig = RARequire('RAWorldConfig')
        icon = RAWorldConfig.Capital.Icon
    end

    return icon
end

function RAWorldUtil:AddSpine(spineName, relationship, buildingType)
    local spineNode = nil
    
    local RAWorldConfig = RARequire('RAWorldConfig')
    local flagCfg = relationship and RAWorldConfig.RelationFlagColor[relationship]
    if relationship == World_pb.NONE and buildingType ~= nil then
        flagCfg = RAWorldConfig.MaskColor4None[buildingType]
    end
    
    if flagCfg then
        CCTextureCache:sharedTextureCache():addColorMaskKey(flagCfg.key, RAColorUnpack(flagCfg.color))
        spineNode = SpineContainer:create(spineName .. '.json', spineName .. '.atlas', flagCfg.key)
    else
        spineNode = SpineContainer:create(spineName .. '.json', spineName .. '.atlas')
    end

    return spineNode
end

-- 在保护状态下确认是否行动
function RAWorldUtil:ActAfterConfirm(confirmFunc)
    if confirmFunc == nil then return end

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    if RAPlayerInfoManager.IsSelfInProtect() then
        local confirmData =
        {
            title = _RALang('@CancelProtectingTitle'),
            labelText = _RALang('@CancelProtectingMsg'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then confirmFunc() end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
    else
        confirmFunc()
    end
end

-- 获取领地的关系
function RAWorldUtil:GetTerritoryRelationship(guildId, stateInfo)
    local relationship = World_pb.NONE
    if guildId and guildId ~= '' then
        relationship = World_pb.ENEMY
        if RAWorldVar:IsInSelfKingdom() then
            local RAAllianceManager = RARequire('RAAllianceManager')
            if RAAllianceManager:IsGuildFriend(guildId) then
                relationship = World_pb.SELF
                if stateInfo and stateInfo.isActive == false then
                    relationship = World_pb.GUILD_FRIEND
                end
            end
        end
    end
    return relationship
end

-- 能否集结
function RAWorldUtil:IsAbleToMass()
    -- 在联盟中
    local RAAllianceManager = RARequire('RAAllianceManager')
    if not RAAllianceManager:IsInGuild() then return false end
    
    -- 拥有建筑: 卫星通讯所
    local RABuildManager = RARequire('RABuildManager')
    local Const_pb = RARequire('Const_pb')
    if RABuildManager:getBuildDataCountByType(Const_pb.SATELLITE_COMMUNICATIONS) < 1 then return false end

    return true
end

-- 派兵出征
function RAWorldUtil:ChargeTroops(targetInfo, marchType)
    local pageData =
    {
        coord       = targetInfo.coord, 
        name        = targetInfo.name,
        icon        = targetInfo.icon,
        marchType   = marchType
    }
    -- 采集资源的时候，需要添加额外字段
    if marchType == World_pb.COLLECT_RESOURCE then
        pageData.remainResNum = targetInfo.remainResNum
    end
    RARootManager.OpenPage('RATroopChargePage', pageData)
end

-- 集结部队
function RAWorldUtil:GatherTroops(targetInfo, marchType)
    local pageData =
    {
        coord       = targetInfo.coord, 
        name        = targetInfo.name,
        icon        = targetInfo.icon,
        marchType   = marchType
    }
    RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
end

-- 是否是有集结的行军
function RAWorldUtil:IsMassRelatedMarch(marchType)
    return (self:IsMassingMarch(marchType) or self:IsJoiningMassMarch(marchType))
end

-- 是否是集结前往中的行军
function RAWorldUtil:IsMassingMarch(marchType)
    return common:table_contains(RAMarchConfig.MassMarchType, marchType)
end

-- 是否是参与集结的行军
function RAWorldUtil:IsJoiningMassMarch(marchType)
    return common:table_contains(RAMarchConfig.JoinMassMarchType, marchType)
end

return RAWorldUtil

--endregion
