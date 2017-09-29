--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAWorldMath = 
{
    K = nil, -- 地图像素高度/宽度 (0.5)
    scale = 1.0,
    -- 不刷新地图的范围
    safeRange = nil
}

local modf = math.modf
local abs = math.abs
local tonumber = tonumber
local random = math.random
local type = type

local WorldCfg = RARequire('RAWorldConfig')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire('common')

-- TileMap坐标系 -> 直角坐标系
function RAWorldMath:Tile2Map(tilePos)
    local mapPos = RACcp(1, tilePos.y + 1)

    if tilePos.y % 2 == 1 then
        mapPos.x = (tilePos.x + 1) * 2
    else 
        mapPos.x = tilePos.x * 2 + 1
    end

    return mapPos
end

-- 直角坐标系 -> TileMap坐标系
function RAWorldMath:Map2Tile(mapPos)
    local tilePos = RACcp(0, mapPos.y - 1)

    if mapPos.y % 2 == 0 then
        tilePos.x = mapPos.x * 0.5 - 1
    else
        tilePos.x = (mapPos.x - 1) * 0.5
    end

    return tilePos
end

-- 直角坐标系 -> OpenGL坐标系
function RAWorldMath:Map2View(mapPos)
    return RACcp(mapPos.x * WorldCfg.halfTile.width, WorldCfg.viewSize.height - mapPos.y * WorldCfg.halfTile.height)
end

-- OpenGL坐标系 -> 直角坐标系
function RAWorldMath:View2Map(viewPos, onlyTileCenter)
    local x, y = viewPos.x / WorldCfg.halfTile.width, (WorldCfg.viewSize.height - viewPos.y) / WorldCfg.halfTile.height
    local floorX, modX = modf(x, 1)
    local floorY, modY = modf(y, 1)
    modX = viewPos.x - floorX * WorldCfg.halfTile.width
    modY = WorldCfg.viewSize.height - viewPos.y - floorY * WorldCfg.halfTile.height

    local mapPos = RACcp(floorX, floorY)
    local isTilePos = self:IsMapPos4Tile(mapPos)
    if self.K == nil then
        self.K = WorldCfg.halfTile.height / WorldCfg.halfTile.width
    end

    -- 不在 直角坐标点 或 线 上
    if modX > 0 and modY > 0 then
        if isTilePos then
            -- 右下部分
            if modY  / (WorldCfg.halfTile.width - modX) > self.K then
                mapPos = RACcp(floorX + 1, floorY + 1)
            end
        -- 地块交界点
        else
            -- 左下部分
            if modY / modX > self.K then
                mapPos.y = floorY + 1
            -- 右上部分
            else
                mapPos.x = floorX + 1
            end
        end
    -- 在坐标点上
    elseif modX == 0 and modY == 0 then
        if onlyTileCenter then
            -- 地块交界点,默认算右边地块(除非已到最右)
            if isTilePos == false then
                if self:IsRightEdge(mapPos) == false then
                    mapPos.x = floorX + 1
                else
                    mapPos.x = floorX - 1
                end
            end
        end
    -- 在线上,且不在地块内
    elseif isTilePos == false then
        if modX > 0 then
           mapPos.x = floorX + 1 
        else
           mapPos.y = floorY + 1
        end
    end

    return mapPos
end

function RAWorldMath:SetScale(scale)
    if scale == nil or scale <= 0 then return end

    if WorldCfg.winCenter and (self.safeRange == nil or self.scale ~= scale) then
        local _scale = WorldCfg.MapScale_Def
        local updateSize = RACcpMult(WorldCfg.MapUpdateSize, 0.5 / _scale)
        updateSize = self:Tile2Map(updateSize)

        local range = RACcp(WorldCfg.winCenter.x / WorldCfg.tileSize.width, WorldCfg.winCenter.y / WorldCfg.tileSize.height)
        range = RACcpAdd(range, WorldCfg.MapReserveSize)
        self.safeRange = RACcpSub(updateSize, RACcpMult(range, 1 / scale))
    end 
    self.scale = scale
end

-- 是否是直角坐标系上的有效地块坐标
function RAWorldMath:IsMapPos4Tile(mapPos)
    return (mapPos.x + mapPos.y) % 2 == 0
end

-- 直角坐标 是否到有效地块的右边缘
function RAWorldMath:IsRightEdge(mapPos)
    if mapPos.y % 2 == 0 then
        return mapPos.x >= (WorldCfg.mapSize.width) * 2
    else
        return mapPos.x >= (WorldCfg.mapSize.width * 2 - 1)
    end
end

-- 获取viewPos在屏幕中心点时map的position
function RAWorldMath:GetCenterPosition(viewPos, scale)
    scale = scale or self.scale
    scale = scale > 0 and scale or 1

    return RACcpSub(RACcpMult(WorldCfg.winCenter, 1 / scale), viewPos)
end

-- 由map的position获取viewPos
function RAWorldMath:GetViewPos(centerPoint, scale)
    scale = scale or self.scale
    scale = scale > 0 and scale or 1

    return RACcpSub(RACcpMult(WorldCfg.winCenter, 1 / scale), centerPoint)
end

-- 是否要刷新地图
function RAWorldMath:IsOutOfView(newMapPos, oldMapPos)
    local offset = RACcpSub(newMapPos, oldMapPos)
    local safeRange = self.safeRange or {x = 2 / self.scale, y = 2 / self.scale}
    return abs(offset.x) >= safeRange.x or abs(offset.y) >= safeRange.y
    -- local offset = RACcpSub(self:Map2Tile(newMapPos), self:Map2Tile(oldMapPos))
    -- return (abs(offset.x) >= (2 / self.scale)) or (abs(offset.y) >= (2 / self.scale))
end

-- 是否超出地图有效直角坐标范围
function RAWorldMath:IsValidMapPos(mapPos, isEdge)
    local gapX, gapY = 0, 0

    -- if not isEdge then
        --TODO: make sure mapPos is the center of win
        -- gapX, gapY = 4 / self.scale, 9 / self.scale
    -- end

    if mapPos.x < 1 + gapX or mapPos.y < 1 + gapY or mapPos.y > WorldCfg.mapSize.height - gapY
    then
        return false
    end

    if mapPos.y % 2 == 0 then
        return mapPos.x <= (WorldCfg.mapSize.width) * 2 - gapX
    else
        return mapPos.x <= (WorldCfg.mapSize.width * 2 - 1) - gapX
    end
end

function RAWorldMath:ValidateMapPos(mapPos)
    if WorldCfg.mapSize == nil then
        RALogWarn('RAWorldConfig.mapSize should have been assigned', true)
        return 
    end

    local maxX, maxY = WorldCfg.mapSize.width * 2, WorldCfg.mapSize.height
    if mapPos.y % 2 == 1 then
        maxX = maxX - 1
    end

    mapPos.x = common:clamp(mapPos.x, 1, maxX)
    mapPos.y = common:clamp(mapPos.y, 1, maxY)
end

function RAWorldMath:GetMapPosId(posX, posY)
    if type(posX) == 'table' or type(posX) == 'userdata' then
        return posX.x .. '_' .. posX.y
    end
    return posX .. '_' .. posY
end

function RAWorldMath:GetMapPosFromId(id)
    local tb = RAStringUtil:split(id, '_')
    return RACcp(tonumber(tb[1]), tonumber(tb[2]))
end

function RAWorldMath:IsMyCityOutOfView(mapPos_1, mapPos_2)
    local radiusX, radiusY = 3 / self.scale, 9 / self.scale --TODO:
    
    local offsetX = abs(mapPos_1.x - mapPos_2.x)
    if offsetX > radiusX then return true end

    local offsetY = mapPos_1.y - mapPos_2.y
    if offsetY < 0 then
        return abs(offsetY) > (6 / self.scale)
    end
    return offsetY > radiusY
end

function RAWorldMath:GetRandomPos(pos, radius)
    local x = pos.x + random(-1 * radius, radius)
    local y = pos.y + random(-1 * radius, radius)
    return RACcp(x, y)
end

-- 是否在菱形区域内
-- @param cornerPos : 四个角的mapPos, {left= {}, right = {}, top = {}, bottom = {}}
-- @param size      : {x = , y = }, x是左角到中心点的横向距离，y是上角到中心的纵向距离
function RAWorldMath:IsInDiamondArea(mapPos, cornerPos, size, isMapPos)
    if size.x < 1 or size.y < 1 then return false end

    local x, y = mapPos.x, mapPos.y

    if x < cornerPos.left.x or x > cornerPos.right.x then return false end
    local midY = cornerPos.top.y - size.y
    if isMapPos then
        midY = cornerPos.top.y + size.y
    end
    local yGap = math.abs(midY - mapPos.y)
    if yGap > size.y then return false end

    local offsetX = x - cornerPos.left.x
    local K = size.y / size.x
    if offsetX < size.x then
        return y >= (cornerPos.left.y - offsetX * K) and y <= (cornerPos.left.y + offsetX * K)
    elseif offsetX > size.x then
        offsetX = size.x * 2 - offsetX
        return y >= (cornerPos.left.y - offsetX * K) and y <= (cornerPos.left.y + offsetX * K)
    end
    return true
end


-- 判断城外一个点是否在音效范围内，然后播放音效
function RAWorldMath:CheckAndPlayVideo(targetTile, effect)
    if targetTile == nil then return false end

    local RARootManager = RARequire('RARootManager')
    -- 不在城外的话就不播放
    if not RARootManager.GetIsInWorld() then
        return false
    end

    local RAWorldVar = RARequire('RAWorldVar')
    local viewTile = RAWorldVar.MapPos.Map
    if viewTile == nil then return false end

    local RAWorldConfig = RARequire('RAWorldConfig')
    local radius = RAWorldConfig.VideoEffect_Radius
    if math.abs(viewTile.x - targetTile.x) > radius.x and math.abs(viewTile.y - targetTile.y) > radius.y then
        return false
    end

    if effect ~= nil then
        local common = RARequire("common")
        common:playEffect(effect)
    end
    
    return true
end

-- 获取以centerMapPos为中心，占格grintCnt 范围内覆盖的所有点坐标
function RAWorldMath:GetCoveredMapPos(centerMapPos, gridCnt)
    local posTB = {}

    local posX, posY = centerMapPos.x, centerMapPos.y
    if gridCnt % 2 == 1 then
        table.insert(posTB, RACcp(posX,     posY))
    end

    if gridCnt == 2 then
        -- left
        table.insert(posTB, RACcp(posX - 1, posY))
        -- top
        table.insert(posTB, RACcp(posX,     posY - 1))
        -- right
        table.insert(posTB, RACcp(posX + 1, posY))
        -- down
        table.insert(posTB, RACcp(posX,     posY + 1))
    elseif gridCnt == 3 then
        table.insert(posTB, RACcp(posX - 2, posY))
        table.insert(posTB, RACcp(posX + 2, posY))
        table.insert(posTB, RACcp(posX,     posY - 2))
        table.insert(posTB, RACcp(posX,     posY + 2))
        table.insert(posTB, RACcp(posX - 1, posY - 1))
        table.insert(posTB, RACcp(posX - 1, posY + 1))
        table.insert(posTB, RACcp(posX + 1, posY - 1))
        table.insert(posTB, RACcp(posX + 1, posY + 1))
    elseif gridCnt == 4 then
        -- top 2, bottom 2, left 2, right 2
        local offsetTb = {{y = -2}, {y = 2}, {x = -2}, {x = 2}}
        for _, offset in ipairs(offsetTb) do
            local corner2Pos = self:GetCoveredMapPos(RACcpAdd(centerMapPos, offset), 2)
            for _, pos in ipairs(corner2Pos) do
                table.insert(posTB, pos)
            end
        end
    elseif gridCnt == 7 then
        -- top 3, bottom 3, left 3, right 3
        local offsetTb = {{y = -4}, {y = 4}, {x = -4}, {x = 4}}
        for _, offset in ipairs(offsetTb) do
            local corner3Pos = self:GetCoveredMapPos(RACcpAdd(centerMapPos, offset), 3)
            for _, pos in ipairs(corner3Pos) do
                table.insert(posTB, pos)
            end
        end

        -- center strip
        for i = -3, 3, 1 do
            if i ~= 0 then
                table.insert(posTB, RACcpAdd(centerMapPos, RACcp(i, i)))
                table.insert(posTB, RACcpAdd(centerMapPos, RACcp(i, -i)))
            end
        end
    end

    return posTB
end

function RAWorldMath:IsInRange(centerPos, range, mapPos, viewPos)
    if viewPos ~= nil then
        if self.K == nil then
            self.K = WorldCfg.halfTile.height / WorldCfg.halfTile.width
        end
        local offset = RACcpSub(viewPos, self:Map2View(centerPos))
        return math.abs(offset.x) * self.K + math.abs(offset.y) <= range * WorldCfg.tileSize.height * 0.5
    end

    local offset = RACcpSub(mapPos, centerPos)
    return math.abs(offset.x) + math.abs(offset.y) <= range
end

return RAWorldMath

--endregion
