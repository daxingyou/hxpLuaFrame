--region *.lua
--Date

local RAWorldMap =
{
    mapNode = nil,

    -- 参考node结点，用来算地图点击位置
    -- (直接用mapNode做参考，遇到大数会有浮点数误差)
    refNode = nil,

    groundLayer = nil,
    face1Layer = nil,
    face2Layer = nil,
    territoryLayer = nil,

    updateMapPos = nil,
    scale = 1.0,
    curMapPos = nil,
    allowServerReq = false,

    -- position 的最小最大值
    minPos = nil,
    maxPos = nil,

    -- map movement 
    destSpacePos = nil,
    curSpacePos = nil,
    frameTime = nil,
    curTime = nil,
    speed = nil,
    isAni = false
}


local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local abs = math.abs

function RAWorldMap:Load(tmxFile, mapPos)
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    local pos = ccp(tilePos.x, tilePos.y)
    self.mapNode = CCTMXTiledMap:create(RAWorldConfig.TmxFile, pos)
    pos:delete()
    if self.mapNode then
        self.mapNode:setAnchorPoint(0, 0)
        self:_initTileCfg()
        self:_addObjGroup()
        self.updateMapPos = mapPos

        self:_initPosRange()
    end
    if self.refNode == nil then
        local node = CCNode:create()
        node:setAnchorPoint(0, 0)
        node:setVisible(true)
        node:setContentSize(CCSizeMake(1, 1))
        self.mapNode:addChild(node)
        self.refNode = node
    end
    return self.mapNode, self.refNode
end

function RAWorldMap:Execute()
    if self.destSpacePos ~= nil and self.frameTime >0 then
        local dt = GamePrecedure:getInstance():getFrameTime()
        self.curTime = self.curTime + dt
        if self.curTime < self.frameTime then
            self.inAni = true
            local offset = RACcp(self.curTime * self.speed.x,self.curTime*self.speed.y)
--            local curSpaceX,curSpaceY = self.mapNode:getPosition()
--            local curSpace = RACcp(curSpaceX,curSpaceY)
            self:SetPosition(RACcpAdd(self.curSpacePos, offset))
        else
            self.curTime = 0 
            self.destSpacePos = nil
            self.frameTime = 0
            self.inAni = false
        end
    end
end

function RAWorldMap:Exit()
    if self.mapNode then
        self.mapNode:stopAllActions()
    end
    self.mapNode = nil
    self.refNode = nil
end

function RAWorldMap:GetRefNode()
    return self.refNode
end

function RAWorldMap:Relocate(forceUpdate)
    self:GotoTileAt(RAWorldVar.MapPos.Map, forceUpdate)
end

function RAWorldMap:GotoTileAt(mapPos, forceUpdate)
    RAWorldMath:ValidateMapPos(mapPos)
    local viewPos = RAWorldMath:Map2View(mapPos)
    local pos = RAWorldMath:GetCenterPosition(viewPos)
    self:SetPosition(pos, forceUpdate)
end

--desc:新手引导，指引资源采集和打怪需要
function RAWorldMap:GotoTileAtInGuide(mapPos, time)
    RAWorldMath:ValidateMapPos(mapPos)
    local viewPos = RAWorldMath:Map2View(mapPos)
    local pos = RAWorldMath:GetCenterPosition(viewPos)

    local xPos,yPos = self.mapNode:getPosition()
    local offset = RACcpSub(pos, {x = xPos, y=yPos})

    self:OffsetMapWithTime(offset, time)
end

function RAWorldMap:GotoViewAt(viewPos)
    self:SetPosition(RAWorldMath:GetCenterPosition(viewPos))
end

function RAWorldMap:OffsetMap(offset)
    if common:isNaN(offset.x) or common:isNaN(offset.y) then
        CCLuaLog(debug.traceback())
        return
    end
    self:SetPosition(RACcpAdd(RAWorldVar.ViewPos.Center, offset))
end

function RAWorldMap:OffsetMapWithTime(offset,time)
    if common:isNaN(offset.x) or common:isNaN(offset.y) then
        CCLuaLog(debug.traceback())
        return
    end
    if time == nil then time = 0.3 end
    self.speed = RACcp(offset.x/time,offset.y/time)
    self.destSpacePos = RACcpAdd(RAWorldVar.ViewPos.Center, offset)
    self.curSpacePos = RAWorldVar.ViewPos.Center
    self.frameTime = time
    self.curTime = 0
    --self.inAni = true
    --self:SetPosition(RACcpAdd(RAWorldVar.ViewPos.Center, offset))
end


function RAWorldMap:SetPosition(pos, forceUpdate)
    if self.mapNode == nil then return end

    self:_validateViewPos(pos)
    self.mapNode:setPosition(pos.x, pos.y)
    RAWorldVar.ViewPos.Center = pos

    local viewPos = RAWorldMath:GetViewPos(pos)
    local mapPos = RAWorldMath:View2Map(viewPos)

    if forceUpdate then
        self:_updateMap(mapPos, true)
        RAWorldVar:UpdateMap(mapPos)
        self:UpdateRefPos()
        MessageManager.sendMessageInstant(MessageDef_World.MSG_UpdateMapPosition)
    else
        if not self.curMapPos or not RACcpEqual(self.curMapPos, mapPos) then
            if self:_needUpdateMap(mapPos) then
                self:_updateMap(mapPos)
            end
            RAWorldVar:UpdateMap(mapPos)
            self:UpdateRefPos()
        end
        MessageManager.sendMessageInstant(MessageDef_World.MSG_UpdateMapPosition)
    end
    self.curMapPos = mapPos
end

function RAWorldMap:SetScale(scale)
    if scale == nil or scale <= 0 then return end

    self.scale = scale
    RAWorldMath:SetScale(scale)
    self:_initPosRange()

    if self.mapNode then
        local size = RAWorldConfig.MapUpdateSize
        -- TODO
        local scale = RAWorldConfig.MapScale_Def
        local w, h = math.ceil(size.x / scale), math.ceil(size.y / scale)
        self.mapNode:setUpdateSize(w, h)
    end
end

function RAWorldMap:EnlargeSizeForGuide()
    if self.mapNode then
        local size = RAWorldConfig.MapUpdateSize
        self.mapNode:setUpdateSize(math.ceil(size.x ) * 3, math.ceil(size.y ) * 3)
    end
    self:SetPosition(RAWorldVar.ViewPos.Center, true)
end

function RAWorldMap:_initPosRange()
    if RAWorldConfig.halfTile == nil then return end

    local w, h = RAWorldConfig.halfTile.width, RAWorldConfig.halfTile.height
    
    -- TODO
    self.maxPos =
    {
        x = -w * 2 / self.scale,
        y = (RAWorldConfig.Height.MainUIBottomBanner - h * 2) / self.scale
    }

    local topH = RAWorldConfig.Height.MainUITopBanner
    self.minPos =
    {
        x = RAWorldConfig.winCenter.x / self.scale * 2 - (RAWorldConfig.viewSize.width - w * 2 / self.scale),
        y = RAWorldConfig.winCenter.y / self.scale * 2 - (RAWorldConfig.viewSize.height - h * 4 / self.scale) + topH / self.scale
    }
end

function RAWorldMap:_validateViewPos(viewPos)
    if self.minPos and self.maxPos then
        viewPos.x = common:clamp(viewPos.x, self.minPos.x, self.maxPos.x)
        viewPos.y = common:clamp(viewPos.y, self.minPos.y, self.maxPos.y)
    end
end

function RAWorldMap:_needUpdateMap(mapPos)
    return RAWorldMath:IsOutOfView(mapPos, self.updateMapPos)
end

function RAWorldMap:_updateMap(mapPos, force)
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    self.mapNode:updateMap(tilePos.x, tilePos.y, force or false)
    
    self.updateMapPos = mapPos
    MessageManager.sendMessageInstant(MessageDef_World.MSG_UpdateMapArea, {mapPos = mapPos})
end

function RAWorldMap:UpdateRefPos()
    if self.refNode then
        local pos = RAWorldVar.ViewPos.Map
        if pos and pos.x and pos.y then
            self.refNode:setPosition(pos.x, pos.y)
        end
    end
end

function RAWorldMap:_initTileCfg()
    RAWorldConfig.mapSize = self.mapNode:getMapSize()
    RAWorldConfig.tileSize = self.mapNode:getTileSize()
    RAWorldConfig.halfTile = CCSizeMake(RAWorldConfig.tileSize.width * 0.5, RAWorldConfig.tileSize.height * 0.5)
    
    local viewWidth = RAWorldConfig.mapSize.width * RAWorldConfig.tileSize.width + RAWorldConfig.halfTile.width
    local viewHeight = (RAWorldConfig.mapSize.height + 1) * RAWorldConfig.halfTile.height
    RAWorldConfig.viewSize = CCSizeMake(viewWidth, viewHeight)

    local winSize = CCDirector:sharedDirector():getWinSize()
    RAWorldConfig.winCenter = RACcp(winSize.width * 0.5, winSize.height * 0.5)
    winSize:delete()

    self.groundLayer = self.mapNode:layerNamed(RAWorldConfig.GroundLayer)
    self.face1Layer = self.mapNode:layerNamed(RAWorldConfig.Face1Layer)
    self.face2Layer = self.mapNode:layerNamed(RAWorldConfig.Face2Layer)
    self.territoryLayer = self.mapNode:layerNamed(RAWorldConfig.TerritoryLayer)

    RAWorldConfig:ResetZorder()
end

function RAWorldMap:_addObjGroup()
    local objGroup = self.mapNode:objectGroupNamed(RAWorldConfig.ObjGroup)
    if objGroup == nil then return end

    local objs = objGroup:getObjects()
    local cnt = objs and objs:count() or 0
    if cnt < 1 then return end

    local objLayer = CCLayer:create()
    self.mapNode:addChild(objLayer, RAWorldConfig.Zorder_ObjGroup)

    local viewHeight = RAWorldConfig.viewSize.height
    local rect = CCRectMake(0, 0, 0, 0)
    for i = 0, cnt - 1 do
        local obj = objs:objectAtIndex(i)
        obj = tolua.cast(obj, 'CCDictionary')
        if obj then
            local gid = obj:valueForKey('gid')
            gid = tolua.cast(gid, 'CCString'):intValue()
            local propDict = self.mapNode:propertiesForGID(gid)
            if propDict then
                local img = propDict:valueForKey('source')
                img = tolua.cast(img, 'CCString'):stringValue()
                if img ~= '' then
                    local x = obj:valueForKey('x')
                    x = tolua.cast(x, 'CCString'):doubleValue()

                    local y = obj:valueForKey('y')
                    y = tolua.cast(y, 'CCString'):doubleValue()

                    local width = obj:valueForKey('width')
                    width = tolua.cast(width, 'CCString'):intValue()

                    local height = obj:valueForKey('height')
                    height = tolua.cast(height, 'CCString'):intValue()

                    rect:setRect(0, 0, width, height)
                    local sprite = CCSprite:create(img, rect)

                    sprite:setPosition(x, viewHeight - y)
                    sprite:setAnchorPoint(0, 0)
                    objLayer:addChild(sprite, y)

				    CCCamera:setBillboard(sprite)
                end
            end

        end
    end
    rect:delete()
end

-- 是否是阻挡点
function RAWorldMap:IsBlock(mapPos)
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    local layerTB =
    {
        self.groundLayer,
        self.face1Layer,
        self.face2Layer
    }

    for _, layer in ipairs(layerTB) do
        local gid = layer:tileGIDAt(tilePos.x, tilePos.y)
        if self:_stringValueForGID(gid, 'stop') == '1' then
            return true
        end
    end
    return false
end

-- @return name '@key'
function RAWorldMap:GetTileName(mapPos)
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    local layerTB =
    {
        self.face2Layer,
        self.face1Layer,
        self.groundLayer
    }

    for _, layer in ipairs(layerTB) do
        local gid = layer:tileGIDAt(tilePos.x, tilePos.y)
        local name = self:_stringValueForGID(gid, 'name')
        if name ~= '' then
            return name
        end
    end
    return ''
end

-- 是否显示装饰物（建筑不能压树）
-- @return 是否有装饰物
function RAWorldMap:SetDecorationVisible(mapPos, visible)
    if self.face2Layer == nil then return false end
    
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    return self.face2Layer:setTileVisibleAt(tilePos.x, tilePos.y, visible)
end

-- 获取领地id, 没有则返回0
function RAWorldMap:GetTerritoryId(mapPos)
    if self.territoryLayer == nil then return 0 end

    RAWorldMath:ValidateMapPos(mapPos)
    local tilePos = RAWorldMath:Map2Tile(mapPos)
    local gid = self.territoryLayer:tileGIDAt(tilePos.x, tilePos.y)
    local idStr = self:_stringValueForGID(gid, 'territoryId')
    
    return (idStr ~= '') and tonumber(idStr) or 0
end

function RAWorldMap:_stringValueForGID(gid, key)
    if gid and gid ~= 0 then
        local propDict = self.mapNode:propertiesForGID(gid)
        if propDict then
            local val = propDict:valueForKey(key)
            val = tolua.cast(val, 'CCString')
            if val then
                return val:stringValue()
            end
        end
    end
    return ''
end

return RAWorldMap

--endregion
