RARequire('BasePage')
local RAWorldMiniMap = BaseFunctionPage:new(...)

local UIExtend = RARequire('UIExtend')
local HP_pb = RARequire('HP_pb')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')
local RANetUtil = RARequire('RANetUtil')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldVar = RARequire('RAWorldVar')
local RARootManager = RARequire('RARootManager')
local RAWorldConfig = RARequire('RAWorldConfig')
local common = RARequire('common')
local RAWorldMath = RARequire('RAWorldMath')

local protoIds =
{
    HP_pb.OPEN_SECONDARY_MAP_S
}
local PointType =
{
	Capital 	= 1,
	Self 		= 2,
	GuildLeader	= 3,
	GuildMember = 4,
	GuildCastle = 5
}
local GuildPositon2PointType =
{
	[Const_pb.LEADER] 		= PointType.GuildLeader,
	[Const_pb.MEMBER] 		= PointType.GuildMember
}
local LabelAniType =
{
	Start 	= 1,
	Points 	= 2,
	Res 	= 3,
}

-- 顶部，底部 按钮区高度
local Height_Top_Banner = 52
local Height_Bottom_Banner = 114

RAWorldMiniMap.mLayer = nil
RAWorldMiniMap.mMap = nil
RAWorldMiniMap.mPointContainer = nil
RAWorldMiniMap.mCapital = nil
RAWorldMiniMap.mSelf = nil
RAWorldMiniMap.mSVLabel = nil
RAWorldMiniMap.mAniLabel = nil
RAWorldMiniMap.mPoints = {}
RAWorldMiniMap.mRes = nil
RAWorldMiniMap.mInfo =
{
	mapWidth 	= 1024,
	mapHeight 	= 1024,
	-- map 边界position, 避免超出边界
	minPos		= RACcp(-1024, -1024),
	maxPos		= RACcp(0, Height_Bottom_Banner),
	-- 小地图与一级地图的比例
	mapRatio	= RACcp(1, 1),
	position 	= RACcp(0, 0),

	-- 是否显示城点
	showPoint	= false,
	-- 是否显示资源带
	showRes		= false
}
RAWorldMiniMap.mRecord =
{
	isClicking 	= false,
	isMoving 	= false,
	touchPos 	= nil,
	beginPos 	= nil,
	touchId		= 0
}

--------------------------------------------------------------------------------------
-- region: RAMapPoint

local Point2Node =
{
	[PointType.Capital] 	= 'mIconCastle',
	[PointType.Self]		= 'mIconMe',
	[PointType.GuildLeader] = 'mIconLeader',
	[PointType.GuildMember] = 'mIconMem',
	[PointType.GuildCastle] = 'mIconAlliance'
}

local RAMapPoint = {}

function RAMapPoint:new(pointType, mapPos, relationship)
    local o = {}

    setmetatable(o, self)
    self.__index = self

    o.pointType = pointType

    o:_init(mapPos, relationship)

    return o
end

function RAMapPoint:addToParent(parentNode)
    if parentNode and self.ccbfile then
        parentNode:addChild(self.ccbfile)
    end
end

function RAMapPoint:setVisible(visible)
	if self.ccbfile then
		if visible then
			self.ccbfile:runAnimation('InAni')
		else
			self.ccbfile:runAnimation('OutAni')
		end
		self.ccbfile:setVisible(visible)
	end
end

function RAMapPoint:Release()
    UIExtend.unLoadCCBFile(self)
end

function RAMapPoint:_init(mapPos, relationship)
    local nodeName = Point2Node[self.pointType]
    if nodeName == nil then return end

    UIExtend.loadCCBFile('RAWorldTwoLevelMapIcon.ccbi', self)

	local viewPos =  RAWorldMiniMap:Map2View(mapPos)
	self.ccbfile:setPosition(viewPos.x, viewPos.y)
    
    if self.pointType == PointType.GuildCastle then
    	relationship = relationship or World_pb.NONE
    	local icon = RAWorldConfig.TerritoryRelationIcon[relationship]
    	if icon then
    		UIExtend.setSpriteIcoToNode(self.ccbfile, nodeName, icon)
    	end
    end

    local visibleMap = {}
    for _, name in pairs(Point2Node) do
    	visibleMap[name] = name == nodeName
    end
	UIExtend.setNodesVisible(self.ccbfile, visibleMap)
	
    self:setVisible(true)
end

-- endregion: RAWorldHudBtn
--------------------------------------------------------------------------------------

function RAWorldMiniMap:Enter()
	self:_registerPacketListener()

	self:_sendOpenMapReq()
	
	UIExtend.loadCCBFile('RAWorldTwoLevelMapsPage.ccbi', self)

	self:_initPage()
	self:_initLayer()
	self:_initMap()

	self:_addCapital()
end

function RAWorldMiniMap:Exit()
	self:_removePacketListener()
	
	self:_hidePoints()
	self:_hideRes()

	if self.mCapital then
		self.mCapital:Release()
		self.mCapital = nil
	end

	if self.mSelf then
		self.mSelf:Release()
		self.mSelf = nil
	end

	if self.mLayer then
		self.mLayer:unregisterScriptTouchHandler()
		self.mLayer = nil
	end

	for _, pointNode in ipairs(self.mPoints) do
		if pointNode then
			pointNode:Release()
		end
	end
	self.mPoints = {}

	UIExtend.releaseCCBFile(self.mMap)
	self.mMap = nil
	self.mPointContainer = nil
	
	UIExtend.unLoadCCBFile(self)
	
	self.mLayer = nil
end

function RAWorldMiniMap:_registerPacketListener()
    self.handlers = RANetUtil:addListener(protoIds, self)
end

function RAWorldMiniMap:_removePacketListener()
    RANetUtil:removeListener(self.handlers)
end

function RAWorldMiniMap:_sendOpenMapReq()
	local msg = World_pb.WorldSecondaryMapReq()
	msg.serverName = RAWorldUtil.kingdomId.tostring(RAWorldVar.KingdomId.Map)
	RANetUtil:sendPacket(HP_pb.OPEN_SECONDARY_MAP_C, msg)
end

function RAWorldMiniMap:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.OPEN_SECONDARY_MAP_S then
        local msg = World_pb.WorldSecondaryMapInfo()
        msg:ParseFromString(buffer)
        self:_onMiniMapInfoRsp(msg)
        return
    end
end

function RAWorldMiniMap:_initPage()
	self:_hidePoints()
	self:_hideRes()
	self:_playLabelAni(LabelAniType.Start)
end

function RAWorldMiniMap:_initLayer()
	local layer = UIExtend.getCCLayerFromCCB(self.ccbfile, 'mWorldMapLayer')
    
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
	layer:setTouchMode(kCCTouchesOneByOne)
    layer:registerScriptTouchHandler(self._onSingleTouch)

    self.mLayer = layer
end

function RAWorldMiniMap:_initMap()
	self.mMap = UIExtend.loadCCBFile('RAWorldTwoLevelMapCell.ccbi', {})
	self.mLayer:addChild(self.mMap)

	local size = self.mMap:getContentSize()
	self.mInfo.mapWidth, self.mInfo.mapHeight = size.width, size.height
	self.mInfo.mapRatio =
	{
		x = RAWorldConfig.viewSize.width / size.width,
		y = RAWorldConfig.viewSize.height / size.height
	}

	local winSize = CCDirector:sharedDirector():getWinSize()
	self.mInfo.minPos =
	{
		x = winSize.width - size.width,
		y = winSize.height - Height_Top_Banner - size.height
	}

	size:delete()

	local pos = self:Map2View(RAWorldVar.MapPos.Map)
	pos =
	{
		x = winSize.width * 0.5 - pos.x,
		y = winSize.height * 0.5 - Height_Top_Banner - pos.y
	}
	winSize:delete()

	self:_validatePos(pos)
	self.mInfo.position = pos
	self.mMap:setPosition(RACcpUnpack(pos))
	
	self.mPointContainer = UIExtend.getCCNodeFromCCB(self.mMap, 'mPointNode') or self.mMap
	UIExtend.setNodeVisible(self.mMap, 'mResLevelAniCCB', false)
end

function RAWorldMiniMap._onSingleTouch(event, touch)
    if event == 'began' then
       return RAWorldMiniMap:_onSingleTouchBegan(touch)
    elseif event == 'moved' then
       return RAWorldMiniMap:_onSingleTouchMoved(touch)
    elseif event == 'ended' then
       return RAWorldMiniMap:_onSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

function RAWorldMiniMap:_onSingleTouchBegan(touch)
    self.mRecord.isClicking = true
    self.mRecord.isMoving = false

    self.mRecord.touchPos = self.mLayer:convertTouchToNodeSpace(touch)
    self.mRecord.beginPos = self.mLayer:convertTouchToNodeSpace(touch)

    self.mRecord.touchId = touch:getID()
    return true
end

function RAWorldMiniMap:_onSingleTouchMoved(touch)
    if not self.mRecord.isClicking then return end
    if self.mRecord.touchId ~= touch:getID() then return end

    local touchPos = self.mLayer:convertTouchToNodeSpace(touch)

    if not self.mRecord.isMoving then
    	-- iphone6s 敏感度太高，10以内当做点击
        local moveDis = ccpDistance(self.mRecord.touchPos, touchPos)
        if moveDis <= 10 then
            self.mRecord.isMoving = false
        else
            self.mRecord.isMoving = true
        end
    end

    self.mRecord.offset = ccpSub(touchPos, self.mRecord.touchPos)
    self:_onTouchMove(self.mRecord.offset)

    self.mRecord.touchPos = touchPos
end

function RAWorldMiniMap:_onSingleTouchEnded(touch)
	if self.mRecord.isMoving then return end
	if self.mRecord.touchId ~= touch:getID() then return end

    self.mRecord.isMoving = false

    local touchPos = self.mLayer:convertTouchToNodeSpace(touch)
    local moveDis = ccpDistance(self.mRecord.beginPos, touchPos)
    if moveDis > 10 then
        return
    end

    local pos = self.mPointContainer:convertTouchToNodeSpace(touch)
    self:_onTouchAt(pos)

    self.mRecord.isClicking = false
end

function RAWorldMiniMap:_onTouchMove(offset)
	local newPos = RACcpAdd(self.mInfo.position, offset)
	self:_validatePos(newPos)
	
	self.mMap:setPosition(newPos.x, newPos.y)
	self.mInfo.position = newPos
end

function RAWorldMiniMap:_validatePos(pos)
	-- 边界检测
	pos.x = common:clamp(pos.x, self.mInfo.minPos.x, self.mInfo.maxPos.x)
	pos.y = common:clamp(pos.y, self.mInfo.minPos.y, self.mInfo.maxPos.y)
end

function RAWorldMiniMap:_onTouchAt(pos)
	local targetScale = RAWorldConfig.MapScale_Fade
	local scaleAction = CCScaleTo:create(1.0, targetScale)

	local relativePos = RACcpSub(pos, RACcpSub(RAWorldConfig.winCenter, self.mInfo.position))
	local targetPos = RACcpAdd(RACcpSub(RAWorldConfig.winCenter, RACcpMult(pos, targetScale)), relativePos)
	-- self:_validatePos(targetPos)
	local moveAction = CCMoveTo:create(1.0, ccp(targetPos.x, targetPos.y))

	local mapPos = RAWorldMath:View2Map(RACcpMultCcp(pos, self.mInfo.mapRatio))
	local RAWorldManager = RARequire('RAWorldManager')
	local callback = CCCallFunc:create(function ()
		RAWorldManager:LocateAtPos(mapPos.x, mapPos.y)
		RARootManager.CloseAllPages()
		self.mMap:setScale(1.0)
	end)

	self.mMap:runAction(CCEaseExponentialOut:create(moveAction))
	self.mMap:runAction(CCSequence:createWithTwoActions(CCEaseExponentialOut:create(scaleAction), callback))
end

function RAWorldMiniMap:_showPoints()
	self.mInfo.showPoint = true
	UIExtend.setNodeVisible(self.ccbfile, 'mPeopleSelectNode', true)
	UIExtend.setNodeVisible(self.ccbfile, 'mPeopeUnSelectNode', false)

	UIExtend.setNodeVisible(self.ccbfile, 'mTopNode', true)
	if self.mMap then
		UIExtend.setNodeVisible(self.mMap, 'mMemAniCCB', true)
		UIExtend.runCCBAni(self.mMap, 'mMemAniCCB', 'InAni')
	end

	-- show TopBanner
	for _, pointNode in ipairs(self.mPoints) do
		if pointNode then
			pointNode:setVisible(true)
		end
	end
end

function RAWorldMiniMap:_hidePoints()
	self.mInfo.showPoint = false
	UIExtend.setNodeVisible(self.ccbfile, 'mPeopleSelectNode', false)
	UIExtend.setNodeVisible(self.ccbfile, 'mPeopeUnSelectNode', true)
	
	UIExtend.setNodeVisible(self.ccbfile, 'mTopNode', false)
	for _, pointNode in ipairs(self.mPoints) do
		if pointNode then
			pointNode:setVisible(false)
		end
	end

	if self.mMap then
		UIExtend.runCCBAni(self.mMap, 'mMemAniCCB', 'OutAni')
	end
end

function RAWorldMiniMap:_showRes()
	self.mInfo.showRes = true
	UIExtend.setNodeVisible(self.ccbfile, 'mResSelectNode', true)
	UIExtend.setNodeVisible(self.ccbfile, 'mResUnSelectNode', false)
	
	if self.mMap == nil then return end

	local pos = ccp(self.mInfo.minPos.x, self.mInfo.minPos.y)
	self.mMap:runAction(CCMoveTo:create(0.5, pos))
	pos:delete()

	local resCCB = UIExtend.getCCBFileFromCCB(self.mMap, 'mResLevelAniCCB')
	resCCB:setVisible(true)
	resCCB:runAnimation('InAni')

	local resNames = RAWorldConfig.ResourceZoneName
	local maxK, sec = table.maxn(resNames), 0.3
	for k, v in pairs(resNames) do
		local aniCCB = UIExtend.getCCBFileFromCCB(resCCB, 'mLabelAniCCB' .. (maxK - k + 1))
		aniCCB:setVisible(false)
		UIExtend.setCCLabelString(aniCCB, 'mLabelAni1', _RALang(v))
		local this = self
		performWithDelay(aniCCB, function ()
			if this.mInfo.showRes == false then return end
			aniCCB:setVisible(true)
			aniCCB:runAnimation('InAni')
		end, (k - 1) * sec)
	end
end

function RAWorldMiniMap:_hideRes()
	self.mInfo.showRes = false
	UIExtend.setNodeVisible(self.ccbfile, 'mResSelectNode', false)
	UIExtend.setNodeVisible(self.ccbfile, 'mResUnSelectNode', true)
	
	if self.mMap == nil then return end

	local resCCB = UIExtend.getCCBFileFromCCB(self.mMap, 'mResLevelAniCCB')
	for k, v in pairs(RAWorldConfig.ResourceZoneName) do
		local aniCCB = UIExtend.getCCBFileFromCCB(resCCB, 'mLabelAniCCB' .. k)
		aniCCB:stopAllActions()
		aniCCB:runAnimation('OutAni')
	end
end

function RAWorldMiniMap:_playLabelAni()
	local aniCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mStateLabel')
	aniCCB:stopAllActions()
	
	self.mAniLabel = UIExtend.getCCLabelTTFFromCCB(aniCCB, 'DataLabel1')
	self.mSVLabel = UIExtend.getCCLabelTTFFromCCB(aniCCB, 'DataLabel2')
	self.mAniLabel:setString('')
	self.mSVLabel:setString('')

	
end

function RAWorldMiniMap:onPeopleSelectBtn()
	self:_showPoints()
end

function RAWorldMiniMap:onPeopleUnSelectBtn()
	self:_hidePoints()
end

function RAWorldMiniMap:onResSelectBtn()
	self:_showRes()
end

function RAWorldMiniMap:onResUnSelectBtn()
	self:_hideRes()
end

function RAWorldMiniMap:onThreeMapBtn()
	local RAWorldMapThreeManager = RARequire("RAWorldMapThreeManager")
	RAWorldMapThreeManager:sendOpenKingmapPacket()
 --    RARootManager.ClosePage("RAWorldMiniMap",false)
	-- RARootManager.OpenPage("RAWorldMapThreePage",nil,true,false,false)
end

function RAWorldMiniMap:onBackBtn()
	RARootManager.CloseAllPages()
end

--[[
	// 二级地图信息
	message WorldSecondaryMapInfo
	{
		// 领地概要信息
		repeated WorldSecondaryManorInfo manorInfo = 1; 
		// 自己所在联盟信息
		repeated WorldSecondaryAllianceInfo allianceInfo = 2;  	 
		// 国王名称
		optional string kingName = 3;  		 
		// 国旗ID
		optional string bannerId = 4;	 	 
		// 受保护时间
		optional int64 protectTime = 5; 
	}
]]--
function RAWorldMiniMap:_onMiniMapInfoRsp(msg)
	self:_showPoints()
	self:_addSelf()
	for _, member in ipairs(msg.allianceInfo) do
		self:_parseMemberInfo(member)
	end
	for _, castle in ipairs(msg.manorInfo) do
		self:_pareseGuildCastle(castle)
	end
end

--[[
	required int32 pointX 		= 1;  // 玩家坐标
	required int32 pointY	    = 2;
	required GuildPositon guildPositon = 3;  // 职位
]]--
function RAWorldMiniMap:_parseMemberInfo(msg)
	local mapPos = RACcp(msg.pointX, msg.pointY)
	-- 自己的基地已经添加
	if RACcpEqual(mapPos, RAWorldVar.MapPos.Self) then
		return
	end

	local pointType = GuildPositon2PointType[msg.guildPositon]
	local pointNode = RAMapPoint:new(pointType, mapPos)
	pointNode:addToParent(self.mPointContainer)

	table.insert(self.mPoints, pointNode)
end

--[[
	// 二级地图的领地概况
	message WorldSecondaryManorInfo
	{
		required int32 manorId = 1;
		optional string guildId = 2;
	}
]]--
function RAWorldMiniMap:_pareseGuildCastle(msg)
	local RATerritoryDataManager = RARequire('RATerritoryDataManager')

	local territoryData = RATerritoryDataManager:GetTerritoryById(msg.manorId)
	if territoryData == nil then return end
	
	local mapPos = territoryData.buildingPos[Const_pb.GUILD_BASTION]
	local relationship = RAWorldUtil:GetTerritoryRelationship(msg.guildId)

	local world_map_const_conf = RARequire('world_map_const_conf')
	local levelLimit = (world_map_const_conf.territoryDisplayLowLimit or {value = 1})['value']

	if relationship == World_pb.SELF or territoryData.level >= levelLimit then
		local pointNode = RAMapPoint:new(PointType.GuildCastle, mapPos, relationship)
		pointNode:addToParent(self.mPointContainer)

		table.insert(self.mPoints, pointNode)
	end
end

function RAWorldMiniMap:_addCapital()
	local capital = RAMapPoint:new(PointType.Capital, RAWorldVar.MapPos.Core)
	capital:addToParent(self.mPointContainer)
	self.mCapital = capital
end

function RAWorldMiniMap:_addSelf()
	if RAWorldVar:IsInSelfKingdom() then
		local selfNode = RAMapPoint:new(PointType.Self, RAWorldVar.MapPos.Self)
		selfNode:addToParent(self.mPointContainer)
		
		self.mSelf = selfNode
	end
end

function RAWorldMiniMap:Map2View(mapPos)
	local viewPos = RAWorldMath:Map2View(mapPos)
	local ratio = self.mInfo.mapRatio
	return RACcp(viewPos.x / ratio.x, viewPos.y / ratio.y)
end

return RAWorldMiniMap