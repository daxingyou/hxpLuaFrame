local RAWorldMistManager = 
{
	mRootNode = nil,
	mMistNode = nil,
	mShaderNode = nil,

	mMistLayers = nil,
	mDataLayer = nil,

	mViewSize = nil,
	mScale = RACcp(1.0, 1.0),

	mMapPosDiff = RACcp(0, 0)
}

local UIExtend = RARequire('UIExtend')
local RATerritoryDataManager = RARequire('RATerritoryDataManager')
local Utilitys = RARequire('Utilitys')
local Const_pb = RARequire('Const_pb')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldConfig = RARequire('RAWorldConfig')
local MistCfg = RAWorldConfig.MistCfg

function RAWorldMistManager:Init(rootNode)
	self.mRootNode = rootNode
	self.ccbfile = nil
end

function RAWorldMistManager:Clear()
	self:_clearMist()
	UIExtend.unLoadCCBFile(self)
	self.mShaderNode = nil

	local RAWorldVar = RARequire('RAWorldVar')
	RAWorldVar.TerritoryId = 0
end

function RAWorldMistManager:AddMist(territoryId, openPosTb)
	self:_clearMist()

	local territoryData = RATerritoryDataManager:GetTerritoryById(territoryId)
	if territoryData == nil then
		CCLuaLog('no territoryData for id: ' .. territoryId)
		return
	end
	
	local strongholdInfo = territoryData.stronghold
	
	-- 所有据点开放：所有迷雾退散
	if #openPosTb == #strongholdInfo then
		territoryData.hasMist = false
		return
	end
	
	for _, pos in ipairs(openPosTb) do
		for _, info in ipairs(strongholdInfo) do
			if RACcpEqual(info.pos, pos) then
				info.isOpen = true
				break
			end
		end
	end

	local bastionPos = territoryData.buildingPos[Const_pb.GUILD_BASTION]

	local territory_mist_conf = RARequire('territory_mist_conf')
	local mistCfg = territory_mist_conf[territoryData.level]
	local tilePos = Utilitys.getCcpFromString(mistCfg.position, ',')
	local mistPos = RAWorldMath:Tile2Map(tilePos)

	self.mMapPosDiff = RACcpSub(mistPos, bastionPos)

	local map = CCTMXTiledMap:create(mistCfg.tmx)
	map:setAnchorPoint(0, 0)
	self.mMistNode = map

	self:_initSize()
	
	map:setScaleX(self.mScale.x)
	map:setScaleY(self.mScale.y)

	local viewPos = RAWorldMath:Map2View(bastionPos)
	viewPos = RACcpSub(viewPos, self:_Map2View(mistPos))

	if self.ccbfile == nil then
		UIExtend.loadCCBFile('RAWorldFogNode.ccbi', self)
	end

    if self.mShaderNode == nil then
		self.mShaderNode = tolua.cast(self.ccbfile:getVariable('mShaderNode'), 'CCShaderNode')
		self.mShaderNode:setAnchorPoint(0, 0)
		self.mShaderNode:setEnable(true)
        -- Important: always set user scale if you can, to reduce memory cost.
        self.mShaderNode:setUserScale(MistCfg.UserScale)

        local mistSize = self.mMistNode:getContentSize()
	    self.mShaderNode:setContentSize(mistSize.width * self.mScale.x, mistSize.height * self.mScale.y)
        mistSize:delete()
		self.mRootNode:addChild(self.ccbfile)
		-- self.mShaderNode:setStaticFrame(true)
		-- self.mShaderNode:setDrawOnceDirty()
	else
		-- 在_clearMist()中setStaticFrame(false), 为避免不生效，此处延时设置为true
		-- local shaderNode = self.mShaderNode
		-- performWithDelay(self.mShaderNode, function()
		-- 	shaderNode:setStaticFrame(true)
		-- 	shaderNode:setDrawOnceDirty()
		-- end, 0.1)
	end
    self.mShaderNode:addChild(map)
    self.ccbfile:setPosition(viewPos.x, viewPos.y)
	self:_initLayers(strongholdInfo)
end

function RAWorldMistManager:IsInMist(mapPos)
	-- 是否在领地中
	local RAWorldManager = RARequire('RAWorldManager')
    local territoryId = RAWorldManager:GetTerritoryId(mapPos) or 0
    if territoryId == 0 then return false end

    -- 是否在迷雾中
    local territoryData = RATerritoryDataManager:GetTerritoryById(territoryId)
    if not territoryData.hasMist then return false end

    local mistMapPos = RACcpAdd(mapPos, self.mMapPosDiff)
    local mistIndex = self:_getMistIndex(mistMapPos)
    return not (territoryData.stronghold[mistIndex] or {isOpen = true})['isOpen']
end

function RAWorldMistManager:_initSize()
    local mapSize = self.mMistNode:getMapSize()
    local tileSize = self.mMistNode:getTileSize()
    
    self.mScale.x = RAWorldConfig.halfTile.width * 2 / tileSize.width
    self.mScale.y = RAWorldConfig.halfTile.height * 2 / tileSize.height

    local viewWidth = (mapSize.width * 2 + 1) * RAWorldConfig.halfTile.width
    local viewHeight = (mapSize.height + 1) * RAWorldConfig.halfTile.height
    self.mViewSize = CCSizeMake(viewWidth, viewHeight)

    mapSize:delete()
    tileSize:delete()
end

function RAWorldMistManager:_Map2View(mapPos)
	return RACcp(mapPos.x * RAWorldConfig.halfTile.width, self.mViewSize.height - mapPos.y * RAWorldConfig.halfTile.height)
end

function RAWorldMistManager:_initLayers(strongholdInfo)
	if self.mMistNode == nil then return end

	self.mMistLayers = {}
	for k, v in pairs(MistCfg.MistId2Layer) do
		local layer = self.mMistNode:layerNamed(v)
		if layer then
			self.mMistLayers[k] = layer
			layer:setVisible(not (strongholdInfo[k] or {isOpen = true})['isOpen'])
		end
	end
	self.mDataLayer = self.mMistNode:layerNamed(MistCfg.DataLayer)
end

-- 获取领地id, 没有则返回0
function RAWorldMistManager:_getMistIndex(mapPos)
    if self.mDataLayer == nil then return 0 end

    local tilePos = RAWorldMath:Map2Tile(mapPos)
    local gid = self.mDataLayer:tileGIDAt(tilePos.x, tilePos.y)
    local idStr = self:_stringValueForGID(gid, 'stronghold')
    
    return (idStr ~= '') and tonumber(idStr) or 0
end

function RAWorldMistManager:_stringValueForGID(gid, key)
    if gid and gid ~= 0 then
        local propDict = self.mMistNode:propertiesForGID(gid)
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

function RAWorldMistManager:_clearMist()
	if self.mMistNode then
		self.mMistNode:removeFromParentAndCleanup(true)
		self.mMistNode = nil
	end
	self.mMistLayers = nil
	self.mDataLayer = nil
	-- if self.mShaderNode then
	-- 	self.mShaderNode:setStaticFrame(false)
	-- 	self.mShaderNode:setDrawOnceDirty()
	-- end
end

return RAWorldMistManager