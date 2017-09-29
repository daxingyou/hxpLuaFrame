--FileName :RATileUtil 
--Author: zhenhui 2016/5/26
local RATileUtil = {}
package.loaded[...] = RATileUtil
_G["RATileUtil"] = RATileUtil

local common = RARequire("common")

function RATileUtil:tile2Space(tmxLayer,tile)
    assert(tmxLayer~=nil,"tmxLayer~=nil")
    local tileSize = tmxLayer:getMapTileSize();
    local layerSize = tmxLayer:getLayerSize();
    local sy = tileSize.height * (layerSize.height - 1 - tile.y)  / 2.0;
    local sx = (tile.x + (tile.y % 2 /2.0)) * tileSize.width + tileSize.width/2
    return ccp(sx,sy)
end

--CCPoint xy = CCPointMake((pos.x * m_tMapTileSize.width) + ((int)pos.y % 2) * m_tMapTileSize.width / 2,
--		(m_tLayerSize.height - (pos.y + 1)) * m_tMapTileSize.height/2);

local function judgeUpOrDown(x,y,x1,y1)
    if x == 0 or y == 0 or x1 == 0 or y1 == 0 then
        return true
    end
    if y/x > y1/x1 then
        return true
    else
        return false
    end
end

local function judgeUpOrDownType2(x,y,x1,y1)

    x = x1 - x
    return judgeUpOrDown(x,y,x1,y1)
end


function RATileUtil:canFindThePath(startPos,endPos)
    local pos1 = ccp(startPos.x,startPos.y)
    local pos2 = ccp(endPos.x,endPos.y)
    AStarPathManager:getInstance():find(pos1, pos2)
    pos1:delete()
    pos2:delete()
    local pathLength = getPathLength()
    if pathLength > 0 then
        return true
    else
        return false
    end
end

function RATileUtil:space2Tile(tmxLayer,pos)
    assert(tmxLayer~=nil,"tmxLayer~=nil")
    local tileSize = tmxLayer:getMapTileSize();
    local layerSize = tmxLayer:getLayerSize();

     local halfWidth = tileSize.width/2.0
     local halfHeight = tileSize.height/2.0
     local txInt,txMod = math.modf(pos.x/halfWidth)
     local tyInt,tyMod = math.modf(pos.y/halfHeight)
     local finalX=0
     local finalY=0
     local tmpX = txMod * halfWidth
     local tmpY = tyMod * halfHeight
     if tyInt%2 == 0 then
        --even y
        if txInt%2 == 0 then
            if judgeUpOrDown(tmpX,tmpY,halfWidth,halfHeight) then
                finalX = math.floor(txInt / 2) - 1
                finalY = tileSize.height - tyInt - 1
            else
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt
            end
        else
            if judgeUpOrDownType2(tmpX,tmpY,halfWidth,halfHeight) then
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt - 1
            else
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt 
            end
        end
     else
         --odd y
        if txInt%2 == 0 then
            if judgeUpOrDownType2(tmpX,tmpY,halfWidth,halfHeight) then
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt - 1
            else
                finalX = math.floor(txInt / 2) -1
                finalY = tileSize.height - tyInt
            end
        else
            if judgeUpOrDown(tmpX,tmpY,halfWidth,halfHeight) then
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt - 1
            else
                finalX = math.floor(txInt / 2)
                finalY = tileSize.height - tyInt 
            end
        end
     end

     return RACcp(finalX,finalY)

--	local ty = layerSize.height - 1 - ((2 * pos.y)/ tileSize.height);
--    ty = common:math_round(ty)
--    --ty = math.floor(ty)
--	local tx = pos.x/tileSize.width - (ty % 2)/2.0;
--    return ccp(common:math_round(tx), ty);
end

function RATileUtil:tile2Point(tmxLayer,tile)
    assert(tmxLayer~=nil,"tmxLayer~=nil")
	return tmxLayer:positionAt(tile);
end

function RATileUtil:getCenterTile(tmxLayer)
    local RACitySceneManager = RARequire("RACitySceneManager")
	local scrSize = CCDirector:sharedDirector():getWinSize();
    local spacePos =  RACitySceneManager.convertScreenPos2TerrainPos(ccp(scrSize.width/2, scrSize.height/2))
	return self:space2Tile(tmxLayer,spacePos);
end

function RATileUtil:getFullScreenTilesRank(tmxLayer)
    local RACitySceneManager = RARequire("RACitySceneManager")
    local scrSize = CCDirector:sharedDirector():getWinSize();
    local spacePos =  RACitySceneManager.convertScreenPos2TerrainPos(ccp(0, 0))
    local rank = {}
    local lowTile = self:space2Tile(tmxLayer,spacePos)

    spacePos =  RACitySceneManager.convertScreenPos2TerrainPos(ccp(scrSize.width, scrSize.height))
    local highTile = self:space2Tile(tmxLayer,spacePos)
    rank.highTileX = highTile.x
    rank.lowTileX = lowTile.x 
    rank.lowTileY = highTile.y
    rank.highTileX = highTile.x
    rank.highTileY = lowTile.y
    return rank 
end


