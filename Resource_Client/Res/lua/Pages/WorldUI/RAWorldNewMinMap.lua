RARequire('BasePage')
local RAWorldNewMinMap = BaseFunctionPage:new(...)

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
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local Utilitys=RARequire("Utilitys")
local RAWorldManager = RARequire('RAWorldManager')
local mFrameTime=0
local startPointLayerPos=0

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
	GuildCastle = 5,
	CurPositon	= 6,
	ResZone		= 7
}

local PointTypes={
	Alliance={PointType.GuildLeader,PointType.GuildMember},
	GuildCastle={PointType.GuildCastle}
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
local Height_Top_Banner = 68
local Height_Bottom_Banner = 84

RAWorldNewMinMap.mLayer = nil
RAWorldNewMinMap.mMap = nil
RAWorldNewMinMap.mPointContainer = nil
RAWorldNewMinMap.mCapital = nil
RAWorldNewMinMap.mSelf = nil
RAWorldNewMinMap.mSVLabel = nil
RAWorldNewMinMap.mAniLabel = nil
RAWorldNewMinMap.mPoints = {}
RAWorldNewMinMap.mRes = nil
RAWorldNewMinMap.mInfo =
{
	mapWidth 	= 1024,
	mapHeight 	= 1024,
	-- map 边界position, 避免超出边界
	minPos		= RACcp(-1024, -1024),
	maxPos		= RACcp(0, 0),
	pointLayerMinPos= RACcp(0, 0),

	-- CamaraMaxPos = RACcp(0, -1024),
	-- 小地图与一级地图的比例
	mapRatio	= RACcp(1, 1),
	position 	= RACcp(0, 0),
	pointLayerPos=RACcp(0, 0),

	-- 是否显示城点
	showPoint	= false,
	-- 是否显示资源带
	showRes		= false
}
RAWorldNewMinMap.mRecord =
{
	isClicking 	= false,
	isMoving 	= false,
	touchPos 	= nil,
	beginPos 	= nil,
	touchId		= 0,
}
RAWorldNewMinMap.adustTab={}

--------------------------------------------------------------------------------------
-- region: RAMapPoint

local Point2Node =
{
	[PointType.Capital] 	= 'mIconCastle',
	[PointType.Self]		= 'mIconMe',
	[PointType.GuildLeader] = 'mIconLeader',
	[PointType.GuildMember] = 'mIconMem',
	[PointType.GuildCastle] = 'mIconAlliance',
	[PointType.CurPositon] = 'mIconCurrent'
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

    UIExtend.loadCCBFile('RAWorldMapTwoIconV2.ccbi', self)

	local viewPos =  RAWorldNewMinMap:Map2View(mapPos)

	--首都点固定的
	if self.pointType==PointType.Capital then
		viewPos=RAWorldNewMinMap.limitPoint[5]
	end 
	-- viewPos.y=math.max(self.limitPoint[2].y,viewPos.y)
	local adjustPos,_= RAWorldNewMinMap:_adjustPos(viewPos,false,mapPos)

	local key=""..math.floor(adjustPos.x).."_"..math.floor(adjustPos.y)
	RAWorldNewMinMap.adustTab[key]=mapPos
	self.ccbfile:setPosition(adjustPos.x, adjustPos.y)
	-- self.ccbfile:setPosition(300, 300)
    
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

function RAWorldNewMinMap:Enter()
	self:_registerPacketListener()

	self:_sendOpenMapReq()
	
	UIExtend.loadCCBFile('RAWorldMapTwoPageV2.ccbi', self)

	self:_initPage()
	self:_initLayer()
	self:_initMap()

	self:_addCapital()

	self:_resetBtn()
end


function RAWorldNewMinMap:_resetBtn()

	local showTb=RAWorldManager.twoLevelMapStaus
	local showAlliance=showTb[1]
	local showTerritory=showTb[2]
	local showRes=showTb[3]

	self.showAlliance=showAlliance
	self.showTerritory=showTerritory
	self.showRes=showRes


	UIExtend.setNodeVisible(self.ccbfile,"mAllianceSelNode",showAlliance)
	UIExtend.setNodeVisible(self.ccbfile,"mAllianceNorNode",not showAlliance)
	UIExtend.setNodeVisible(self.ccbfile,"mTerritorySelNode",showTerritory)
	UIExtend.setNodeVisible(self.ccbfile,"mTerritoryNorNode",not showTerritory)
	UIExtend.setNodeVisible(self.ccbfile,"mResSelNode",showRes)
	UIExtend.setNodeVisible(self.ccbfile,"mResNorNode",not showRes)
end
function RAWorldNewMinMap:Exit()
	self:_removePacketListener()
	
	self:_hidePoints()
	UIExtend.setNodeVisible(self.mMap,"mResAniCCB",false)

	if self.mCapital then
		self.mCapital:Release()
		self.mCapital = nil
	end

	if self.mSelf then
		self.mSelf:Release()
		self.mSelf = nil
	end

	if self.mCurrent then
		self.mCurrent:Release()
		self.mCurrent = nil
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

	for k,v in pairs(self.adustTab) do
		v=nil
	end
	self.adustTab={}
	self.mPoints = {}

	-- self:_resetBtn()

	local titleLabel=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mPresidentCDTitle")
    local timeLabel=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTime")
	timeLabel:setPositionX(timeLabel:getPositionX()-titleLabel:getContentSize().width*0.5)

	UIExtend.releaseCCBFile(self.mMap)
	self.mMap = nil
	self.mPointContainer = nil
	
	UIExtend.unLoadCCBFile(self)
	
	self.mLayer = nil
end

function RAWorldNewMinMap:_registerPacketListener()
    self.handlers = RANetUtil:addListener(protoIds, self)
end

function RAWorldNewMinMap:_removePacketListener()
    RANetUtil:removeListener(self.handlers)
end

function RAWorldNewMinMap:_sendOpenMapReq()
	local msg = World_pb.WorldSecondaryMapReq()
	msg.serverName = RAWorldUtil.kingdomId.tostring(RAWorldVar.KingdomId.Map)
	RANetUtil:sendPacket(HP_pb.OPEN_SECONDARY_MAP_C, msg)
end

function RAWorldNewMinMap:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.OPEN_SECONDARY_MAP_S then
        local msg = World_pb.WorldSecondaryMapInfo()
        msg:ParseFromString(buffer)
        self:_onMiniMapInfoRsp(msg)
        return
    end
end

function RAWorldNewMinMap:_initPage()
	self:_hidePoints()
	self:_playLabelInAni(LabelAniType.Start)

	--服务器序号 服务器时间
	self:_refreshServierIdAndTime()
	--国王战时间（和平和战争）
	self:_refreshKingWarTime()
	local titleLabel=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mPresidentCDTitle")
    local timeLabel=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTime")
	timeLabel:setPositionX(timeLabel:getPositionX()+titleLabel:getContentSize().width*0.5)

end


function RAWorldNewMinMap:_refreshServierIdAndTime()
	local servierId = RAPlayerInfoManager.getKingdomId()
	local servierTime= common:getCurTime()
	servierTime=Utilitys.formatTime(servierTime,true)

	UIExtend.setCCLabelString(self.ccbfile,"mServerLabel",_RALang("@ServerIdAndTime",servierId,servierTime))
end

function RAWorldNewMinMap:_refreshKingWarTime()
	local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    -- Common part
    local RAPresidentDataManager = RARequire("RAPresidentDataManager")
    local isPeace, periodEndTime, periodTotalTime = RAPresidentDataManager:GetPresidentStatus()
    local statusStrKey = '@PresidentPeaceStatus'
    if not isPeace then
        statusStrKey = '@PresidentWarStatus'
    end
    local lastTime = periodEndTime - common:getCurMilliTime()
    if lastTime < 0 then lastTime = 0 end
    local timeStr = Utilitys.createTimeWithFormat(lastTime / 1000) 

    UIExtend.setCCLabelString(self.ccbfile,"mPresidentCDTitle",_RALang(statusStrKey))
	UIExtend.setCCLabelString(self.ccbfile,"mTime",timeStr)

end

--刷新时间显示
function RAWorldNewMinMap:Execute()

	mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
	   self:_refreshServierIdAndTime()
	   self:_refreshKingWarTime()
       mFrameTime = 0 
    end
end
function RAWorldNewMinMap:_initLayer()
	local layer = UIExtend.getCCLayerFromCCB(self.ccbfile, 'mWorldMapLayer')
    
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
	layer:setTouchMode(kCCTouchesOneByOne)
    layer:registerScriptTouchHandler(self._onSingleTouch)

    self.mLayer = layer
end

function RAWorldNewMinMap:_getActualPos(pos)

	pos.x=math.floor(pos.x)
	pos.y=math.floor(pos.y)

	local RAStringUtil = RARequire("RAStringUtil")
	local minDistance=nil
	local targetMapPos=nil
	for key,mapPos in pairs(self.adustTab) do
		local keyTb=RAStringUtil:split(key, "_")
		--在一定区域内如果有多个点，选择最近的点
		if math.abs(pos.x-tonumber(keyTb[1]))<80 and math.abs(pos.y-tonumber(keyTb[2]))<80 then
			local distance=RACcpDistance(pos,{x=tonumber(keyTb[1]),y=tonumber(keyTb[2])})
			if not minDistance or distance<minDistance then
				minDistance=distance
				targetMapPos=mapPos
			end			
		end 
	end
	return targetMapPos
end
function RAWorldNewMinMap:_isSamePoint(point1,point2)
	if math.abs(point1.x-point2.x)<=10 and math.abs(point1.y-point2.y)<=10 then
		return true
	end 
	return false
end
--调整点的位置使它在梯形区域内部
--targetPos:调整过的点
--isInside: 是否在区域范围
function RAWorldNewMinMap:_adjustPos(pos,isCheck)
	local targetPos={x=0,y=0}
	local isInside=false
	
	local point1=self.limitPoint[1]
	local point2=self.limitPoint[2]
	local point3=self.limitPoint[3]
	local point4=self.limitPoint[4]


	local isOut=nil
	if pos.x>point1.x then
		pos.x=point1.x
		isOut=true
	elseif pos.x<point4.x then
		pos.x=point4.x
		isOut=true
	end 

	local offset=0
	if isCheck then
		offset=10
	end 
	if pos.y-point2.y> offset then
		-- pos.y=point2.y
		if isCheck then
			isOut=true
		end 
	end 
	if isCheck and isOut then
		return nil,false
	end 
	
 	--如果是同一点直接返回
    if self:_isSamePoint(pos,point1) or self:_isSamePoint(pos,point2)
		or self:_isSamePoint(pos,point3) or self:_isSamePoint(pos,point4)
	then
		isInside=true
		return pos,isInside
	end 

	if pos.y-point1.y<offset then
		--区域下部
		targetPos.x = pos.x
		targetPos.y = 0
	elseif pos.y-point2.y>offset and pos.x<point2.x and  pos.x>point3.x then
		--区域正上部
		targetPos.x = pos.x
		targetPos.y = point2.y-(self.mInfo.mapHeight-pos.y)
	elseif pos.y-point2.y>=offset and pos.x>point2.x then
		--区域上部 偏右
		targetPos.x = point2.x-math.min(pos.x-point2.x,point2.x-point3.x)
		targetPos.y = point2.y-(self.mInfo.mapHeight-pos.y)
	elseif pos.y-point2.y>=offset and pos.x<point3.x  then
		--区域上部 偏左
		targetPos.x = point3.x+math.min(pos.x,point2.x-point3.x)
		targetPos.y = point3.y-(self.mInfo.mapHeight-pos.y)
	elseif pos.x==point1.x then
		--右边界
		targetPos.x=pos.x-(point1.x-point2.x)*(pos.y-point1.y)/(point2.y-point1.y)
		targetPos.y = pos.y

	elseif pos.x==point4.x then
		--左边界
		targetPos.x=pos.x+(point3.x-point4.x)*(pos.y-point4.y)/(point3.y-point4.y)
		targetPos.y = pos.y
	elseif pos.x~=point1.x and (pos.y-point1.y)/(pos.x-point1.x)-(point2.y-point1.y)/(point2.x-point1.x)<0.1 then
		--区域右边 
		targetPos.x=point2.x+(point1.x-point2.x)-(point1.x-point2.x)*(pos.y-point1.y)/(point2.y-point1.y)-(self.mInfo.mapWidth-pos.x)
		targetPos.y = pos.y
	elseif pos.x~=point4.x and (pos.y-point4.y)/(pos.x-point4.x)-(point4.y-point3.y)/(point4.x-point3.x) >0.1  then
		--区域左边
		targetPos.x=point4.x+(point3.x-point4.x)*(pos.y-point1.y)/(point3.y-point4.y)+pos.x
		targetPos.y = pos.y
	else
		--在区域内部
		isInside=true
		targetPos=pos

	end 
	return targetPos,isInside

end
function RAWorldNewMinMap:_initMap( ... )
	self.mMap = UIExtend.loadCCBFile('RAWorldMapTwoBGV2.ccbi', {})
	self.mLayer:addChild(self.mMap)

	local mLimitPoint1=UIExtend.getCCNodeFromCCB(self.mMap,"mLimitPoint1")
	local mLimitPoint2=UIExtend.getCCNodeFromCCB(self.mMap,"mLimitPoint2")
	local mLimitPoint3=UIExtend.getCCNodeFromCCB(self.mMap,"mLimitPoint3")
	local mLimitPoint4=UIExtend.getCCNodeFromCCB(self.mMap,"mLimitPoint4")
	local mLimitPoint5=UIExtend.getCCNodeFromCCB(self.mMap,"mLimitPoint5")
	self.limitPoint={
		RACcp(mLimitPoint1:getPositionX(), mLimitPoint1:getPositionY()),
		RACcp(mLimitPoint2:getPositionX(), mLimitPoint2:getPositionY()),
		RACcp(mLimitPoint3:getPositionX(), mLimitPoint3:getPositionY()),
		RACcp(mLimitPoint4:getPositionX(), mLimitPoint4:getPositionY()),
		RACcp(mLimitPoint5:getPositionX(), mLimitPoint5:getPositionY()),
	}

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
		y = winSize.height - size.height
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

	local resCCB = UIExtend.getCCBFileFromCCB(self.mMap, 'mResAniCCB')
	UIExtend.handleCCBNode(resCCB)
	UIExtend.setNodeVisible(self.mMap,"mResAniCCB",false)
end
function RAWorldNewMinMap._onSingleTouch(event, touch)
    if event == 'began' then
       return RAWorldNewMinMap:_onSingleTouchBegan(touch)
    elseif event == 'moved' then
       return RAWorldNewMinMap:_onSingleTouchMoved(touch)
    elseif event == 'ended' then
       return RAWorldNewMinMap:_onSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

function RAWorldNewMinMap:_onSingleTouchBegan(touch)
    self.mRecord.isClicking = true
    self.mRecord.isMoving = false

    self.mRecord.touchPos = self.mLayer:convertTouchToNodeSpace(touch)
    self.mRecord.beginPos = self.mLayer:convertTouchToNodeSpace(touch)

    self.mRecord.touchId = touch:getID()
    return true
end

function RAWorldNewMinMap:_onSingleTouchMoved(touch)
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

function RAWorldNewMinMap:_onSingleTouchEnded(touch)
	if self.mRecord.isMoving then return end
	if self.mRecord.touchId ~= touch:getID() then return end

    self.mRecord.isMoving = false

    local touchPos = self.mLayer:convertTouchToNodeSpace(touch)
    local moveDis = ccpDistance(self.mRecord.beginPos, touchPos)
    if moveDis > 10 then
        return
    end

    local pos = self.mPointContainer:convertTouchToNodeSpace(touch)

    local _,isInside=RAWorldNewMinMap:_adjustPos(pos,true)
    if isInside then
    	self:_onTouchAt(pos)
    end 
    self.mRecord.isClicking = false
end

function RAWorldNewMinMap:_onTouchMove(offset)
	local newPos = RACcpAdd(self.mInfo.position, offset)
	self:_validatePos(newPos)
	self.mMap:setPosition(newPos.x, newPos.y)
	self.mInfo.position = newPos

end

function RAWorldNewMinMap:_validatePos(pos)
	-- 边界检测
	pos.x = common:clamp(pos.x, self.mInfo.minPos.x, self.mInfo.maxPos.x)
	pos.y = common:clamp(pos.y, self.mInfo.minPos.y, self.mInfo.maxPos.y)
end

function RAWorldNewMinMap:_onTouchAt(pos)
	local targetScale = RAWorldConfig.MapScale_Fade
	local scaleAction = CCScaleTo:create(1.0, targetScale)

	local relativePos = RACcpSub(pos, RACcpSub(RAWorldConfig.winCenter, self.mInfo.position))
	local targetPos = RACcpAdd(RACcpSub(RAWorldConfig.winCenter, RACcpMult(pos, targetScale)), relativePos)
	-- self:_validatePos(targetPos)
	local moveAction = CCMoveTo:create(1.0, ccp(targetPos.x, targetPos.y))

	local actualPos=self:_getActualPos({x=pos.x,y=pos.y})
	local mapPos=nil
	if actualPos then
		--已经调整过的点（返回地图上的坐标）
		mapPos= actualPos
	else
		mapPos = RAWorldMath:View2Map(RACcpMultCcp(pos, self.mInfo.mapRatio))
	end 

	local callback = CCCallFunc:create(function ()
		RAWorldManager:LocateAtPos(mapPos.x, mapPos.y,nil,true)
		RARootManager.CloseAllPages()
		self.mMap:setScale(1.0)

	end)

	self.mMap:runAction(CCEaseExponentialOut:create(moveAction))
	self.mMap:runAction(CCSequence:createWithTwoActions(CCEaseExponentialOut:create(scaleAction), callback))
end

function RAWorldNewMinMap:_resertCamera()
	local RAWorldScene=RARequire("RAWorldScene")
	CCCamera:setPerspectiveCameraParam(RAWorldConfig.Camera_PerspectiveParam)
	CCCamera:setPerspectiveCameraMatrix()
	CCCamera:setPerspectiveRootNode(RAWorldScene.RootNode)
end

function RAWorldNewMinMap:_showPoints(pTypes)
	self.mInfo.showPoint = true
	for _, pointNode in ipairs(self.mPoints) do
		if pointNode then
			if pTypes then
				if Utilitys.tableFind(pTypes,pointNode.pointType) then
					pointNode:setVisible(true)
				end 
			else
				pointNode:setVisible(true)
			end 
			
		end
	end
end

function RAWorldNewMinMap:_hidePoints(pTypes)
	self.mInfo.showPoint = false
	for _, pointNode in ipairs(self.mPoints) do
		if pointNode then
			if pTypes then
				if Utilitys.tableFind(pTypes,pointNode.pointType) then
					pointNode:setVisible(false)
				end 
			else
				pointNode:setVisible(false)
			end 
		end
	end
end

function RAWorldNewMinMap:_showRes()
	self.mInfo.showRes = true
	if self.mMap == nil then return end
	local resCCB = UIExtend.getCCBFileFromCCB(self.mMap, 'mResAniCCB')
	resCCB:setVisible(true)
	resCCB:runAnimation('InAni')

end

function RAWorldNewMinMap:_hideRes()
	self.mInfo.showRes = false
	if self.mMap == nil then return end
	local resCCB = UIExtend.getCCBFileFromCCB(self.mMap, 'mResAniCCB')
	resCCB:runAnimation('OutAni')
end

function RAWorldNewMinMap:_playLabelInAni()
	local aniCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mIconExplainCCB')
	aniCCB:runAnimation("InAni")
end

function RAWorldNewMinMap:_playLabelOutAni()
	local aniCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mIconExplainCCB')
	aniCCB:runAnimation("OutAni")
end

function RAWorldNewMinMap:mIconExplainCCB_onCloseBtn()
	self:_playLabelOutAni()
end

function RAWorldNewMinMap:mIconExplainCCB_onOpenBtn()
	self:_playLabelInAni()
end

--[[
	自己 当前位置 首都 一直显示
	点击联盟成员：控制成员和盟主的显示
	点击领土范围：控制领地的显示
	点击资源分布：播放资源带动画
]]--

function RAWorldNewMinMap:onAllianceBtn()
	-- body
	if not self.showAlliance then
		self.showAlliance=true
		self:_showPoints(PointTypes.Alliance)
	else
		self.showAlliance=false
		self:_hidePoints(PointTypes.Alliance)
	end 
	RAWorldManager:setTwoLevelMapStatu(PointType.GuildMember,self.showAlliance)
	UIExtend.setNodeVisible(self.ccbfile,"mAllianceSelNode",self.showAlliance)
	UIExtend.setNodeVisible(self.ccbfile,"mAllianceNorNode",not self.showAlliance)
end

function RAWorldNewMinMap:onTerritoryBtn()
	-- body
	if not self.showTerritory then
		self.showTerritory=true
		self:_showPoints(PointTypes.GuildCastle)
	else
		self.showTerritory=false
		self:_hidePoints(PointTypes.GuildCastle)
	end 
	RAWorldManager:setTwoLevelMapStatu(PointType.GuildCastle,self.showTerritory)
	UIExtend.setNodeVisible(self.ccbfile,"mTerritorySelNode",self.showTerritory)
	UIExtend.setNodeVisible(self.ccbfile,"mTerritoryNorNode",not self.showTerritory)
end

function RAWorldNewMinMap:onResBtn()
	-- body
	if not self.showRes then
		self.showRes=true
		self:_showRes()
	else
		self.showRes=false
		self:_hideRes()
	end 
	RAWorldManager:setTwoLevelMapStatu(PointType.ResZone,self.showRes)
	UIExtend.setNodeVisible(self.ccbfile,"mResSelNode",self.showRes)
	UIExtend.setNodeVisible(self.ccbfile,"mResNorNode",not self.showRes)
end

function RAWorldNewMinMap:onMapThreeBtn()
	local RAWorldMapThreeManager = RARequire("RAWorldMapThreeManager")
	RAWorldMapThreeManager:sendOpenKingmapPacket()
end

function RAWorldNewMinMap:onBack()
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
function RAWorldNewMinMap:_onMiniMapInfoRsp(msg)
	self:_showPoints()
	self:_addSelf()
	self:_addCurrent()

	-- --联盟成员 盟主
	for _, member in ipairs(msg.allianceInfo) do
		self:_parseMemberInfo(member)
	end

	-- 联盟领地
	for _, castle in ipairs(msg.manorInfo) do
		self:_pareseGuildCastle(castle)
	end

	
	local isShowMems=RAWorldManager:getTwoLevelMapStatu(PointType.GuildMember)
	local isShowTerr=RAWorldManager:getTwoLevelMapStatu(PointType.GuildCastle)
	local isShwoResZone=RAWorldManager:getTwoLevelMapStatu(PointType.ResZone)
	

	if not isShowMems then
		self:_hidePoints(PointTypes.Alliance)
	end 

	if not isShowTerr then
		self:_hidePoints(PointTypes.GuildCastle)
	end 

	if isShwoResZone then
		self:_showRes()
	else
		self:_hideRes()
	end 
	
end

--[[
	required int32 pointX 		= 1;  // 玩家坐标
	required int32 pointY	    = 2;
	required GuildPositon guildPositon = 3;  // 职位
]]--

--// 联盟职位
--enum GuildPositon
--{
--	LEADER = 1;	  // 盟主
--	COLEADER = 2; //外交官
--	MEMBER = 3;	  // 普通
--}

function RAWorldNewMinMap:_parseMemberInfo(msg)
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
function RAWorldNewMinMap:_pareseGuildCastle(msg)
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

function RAWorldNewMinMap:_addCapital()
	local capital = RAMapPoint:new(PointType.Capital, RAWorldVar.MapPos.Core)
	capital:addToParent(self.mPointContainer)
	self.mCapital = capital
end

function RAWorldNewMinMap:_addSelf()
	if RAWorldVar:IsInSelfKingdom() then
		local selfNode = RAMapPoint:new(PointType.Self, RAWorldVar.MapPos.Self)
		selfNode:addToParent(self.mPointContainer)
		
		self.mSelf = selfNode
	end
end
function RAWorldNewMinMap:_addCurrent()

	local currentNode = RAMapPoint:new(PointType.CurPositon, RAWorldVar.MapPos.Map)
	currentNode:addToParent(self.mPointContainer)
		
	self.mCurrent = currentNode
end

function RAWorldNewMinMap:Map2View(mapPos)
	local viewPos = RAWorldMath:Map2View(mapPos)
	local ratio = self.mInfo.mapRatio
	return RACcp(viewPos.x / ratio.x, viewPos.y / ratio.y)
end

return RAWorldNewMinMap