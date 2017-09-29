--[[
	desc: 	关卡主页面
	author: royhu
	date: 	2016-12-27
]]--

RARequire('BasePage')

local pageVar =
{
	mPageName 	= 'RADungeonMainPage',
	mRootNode 	= nil,
	mTouchLayer = nil,
	mMapNode 	= nil,
	mTitleNode  = nil,

	mIsInAni 	= false,
	mIsLocating = false,
	mTargetPos 	= nil,

	-- 触摸事件数据
	mTouchRecord =
	{
		isMoving 	= false,
		touchId 	= nil,
		touchPos 	= nil,
		offset 		= nil
	},

	-- 地图数据
	mMapInfo =
	{
		pos 		= RACcp(0, 0),
		-- map 边界position, 避免超出边界
		minPos		= RACcp(-1024, -1024),
		maxPos		= RACcp(0, 0),
		centerPos 	= RACcp(0, 0)
	},

	-- 关卡数据
	mDungeonInfo =
	{
		chapterId = 1,
		dungeonId = 1001
	}
}
local RADungeonMainPage = BaseFunctionPage:new(..., pageVar)

local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RADungeonHandler = RARequire('RADungeonHandler')
local RADungeonManager = RARequire('RADungeonManager')
local common = RARequire('common')
local Dungeon_pb = RARequire('Dungeon_pb')
local RAGuideManager = RARequire('RAGuideManager')

local msgTB =
{
	MessageDefine_PVE.MSG_Sync_ChapterPartsInfo,
	MessageDef_Guide.MSG_Guide                    --新手引导用的消息监听 by xinping
}

local MapLightColor =
{
	[Dungeon_pb.CHAPTER_STATE_PASSED]		= {25,  193, 255},
	[Dungeon_pb.CHAPTER_STATE_EXECUTING] 	= {255, 98,  0}
}
local MapGradientColor =
{
	[Dungeon_pb.CHAPTER_STATE_LOCKED]		= {181, 181, 255}
}
local MapLineColor =
{
	[Dungeon_pb.CHAPTER_STATE_PASSED]		= {25,  193, 255},
	[Dungeon_pb.CHAPTER_STATE_EXECUTING] 	= {255, 165, 0},
	[Dungeon_pb.CHAPTER_STATE_LOCKED]		= {19,  113, 192}
}
local Part_Cnt_Per_Chapter = 6
local Init_Map_Scale = 0.6

local function _genColor(colorTb)
	return colorTb and ccc3(unpack(colorTb))
end

function RADungeonMainPage:Enter(data)
	self:_registerPacketListener()
	self:_registerMessageHandlers()
	self.canClick=false
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide()  then
        RARootManager.AddCoverPage()
    end

	self:_initRootNode()
	self:_initTitle()
	self:_initTouchLayer()
	
	self:_initChapterInfo(data.chapterId)
	self:_initChapterMap()

	self:_fadeIn()
end

function RADungeonMainPage:_initGuide()
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide()  then
		RAGuideManager.gotoNextStep()
    else
    	self.canClick=true
    end
end
function RADungeonMainPage:Exit()
	self:_unregisterMessageHandlers()
	self:_removePacketListener()
	self.executingPartId = nil
	self.canClick = nil

	self:_releaseNodes()
end

-------------------------------------
-- region: btn response

function RADungeonMainPage:onMapAreaBtn(btnIndex)
	if not self.canClick then return end
	local dungeonId = RADungeonManager:GetDungeonId(self.mDungeonInfo.chapterId, btnIndex)
	local state = RADungeonManager:GetDungeonState(dungeonId)
	if state ~= Dungeon_pb.CHAPTER_STATE_LOCKED then
		self.mDungeonInfo.dungeonId = dungeonId

		if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
			RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
        end

        RARootManager.OpenPage('RADungeonFightPage', {dungeonId = dungeonId}, false, true, false)
	end
end

function RADungeonMainPage:onBack()
	if not self.canClick then return end
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
		RARootManager.CloseAllPages()
        RARootManager.RemoveGuidePage()
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    end
	RARootManager.CloseCurrPage()
end

-- endregion: btn response
-------------------------------------

function RADungeonMainPage:_initChapterInfo(chapterId)
	self.mDungeonInfo.chapterId = chapterId
	self:_getChapterInfo()
end

function RADungeonMainPage:_initRootNode()
	UIExtend.loadCCBFile('RAPVEMainPage.ccbi', self)
	self.mRootNode = self.ccbfile
end

function RADungeonMainPage:_initTitle()
    self.mTitleNode = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, 'mTitle')
    if self.mTitleNode then
	    self.mTitleNode:setString('')
	end
end

function RADungeonMainPage:_initTouchLayer()
	local layer = UIExtend.getCCLayerFromCCB(self.ccbfile, 'mMapLayer')
    
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
	layer:setTouchMode(kCCTouchesOneByOne)
    layer:registerScriptTouchHandler(self._onSingleTouch)

    self.mTouchLayer = layer
end

function RADungeonMainPage:_initChapterMap()
	local handler = {}
	local this = self
	for i = 1, Part_Cnt_Per_Chapter do
		handler['onMapAreaBtn' .. i] = function()
			this:onMapAreaBtn(i)
		end
	end
	self.mMapNode = UIExtend.loadCCBFile('RAPVEMapSA.ccbi', handler)
	self.mMapNode:setVisible(false)
	self:_resetMapState()
	self.mTouchLayer:addChild(self.mMapNode)

	local size = self.mMapNode:getContentSize()
	local winSize = CCDirector:sharedDirector():getWinSize()
	local titleSize = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mTitleSizeNode'):getContentSize()

	self.mMapInfo.minPos =
	{
		x = winSize.width - size.width * 0.5,
		y = winSize.height - size.height * 0.5 - titleSize.height
	}
	self.mMapInfo.maxPos =
	{
		x = size.width * 0.5,
		y = size.height * 0.5
	}
	self.mMapInfo.centerPos =
	{
		x = winSize.width * 0.5,
		y = winSize.height * 0.5
	}

	local x, y = RACcpUnpack(self.mMapInfo.centerPos)
	self.mMapNode:setPosition(x, y)
	self.mMapInfo.pos = RACcp(x, y)

	RAGameUtils:setChildMenu(self.mMapNode, CCRectMake(0, 0, winSize.width, winSize.height - titleSize.height))

	size:delete()
	winSize:delete()
	titleSize:delete()
end

function RADungeonMainPage:_resetMapState()
	local visibleMap = {}
	for i = 1, Part_Cnt_Per_Chapter do
		visibleMap['mEnemyArea' .. i] = false
		visibleMap['mMineArea' .. i] = false
		visibleMap['mLockArea' .. i] = false
	end
	UIExtend.setNodesVisible(self.mMapNode, visibleMap)
end

function RADungeonMainPage:_fadeIn()
	self.mMapNode:setScale(Init_Map_Scale)	
	local pos = RACcpSub(self.mMapInfo.centerPos, self.mMapInfo.pos)
	pos = RACcpSub(self.mMapInfo.centerPos, RACcpMult(pos, Init_Map_Scale))
	self.mMapNode:setPosition(pos.x, pos.y)

	self.mMapNode:setVisible(true)


	local scaleAction = CCScaleTo:create(1.0, 1.0)

	local pos = self.mMapInfo.pos
	local targetPos = ccp(pos.x, pos.y)
	local moveAction = CCMoveTo:create(1.0, targetPos)

	self.mMapNode:runAction(scaleAction)
	self.ccbfile:runAnimation('InAni')
	self.mIsInAni = true
	local this = self
	UIExtend.runActionWithCallback(self.mMapNode, moveAction, function()
		targetPos:delete()
		if this.mIsLocating then
			this:_locateTargetArea()
		end
		this.mIsInAni = false
	end)
end

function RADungeonMainPage:_setAllPartsState()
	local dict = RADungeonManager:GetDungeonIdList(self.mDungeonInfo.chapterId)
	for partId, dungeonId in pairs(dict) do
		self:_setPartState(partId, dungeonId)
	end
end

function RADungeonMainPage:_setPartState(partId, dungeonId)
	local state = RADungeonManager:GetDungeonState(dungeonId)
	local isPass = state == Dungeon_pb.CHAPTER_STATE_PASSED
	local isLock = state == Dungeon_pb.CHAPTER_STATE_LOCKED
	local isExecuting = state == Dungeon_pb.CHAPTER_STATE_EXECUTING

	local visibleMap =
	{
		['mMapLight' .. partId] 	= not isLock,
		['mMapGradient' .. partId]	= isLock,
		['mMineArea' .. partId]		= isPass,
		['mEnemyArea' .. partId]	= not isLock and not isPass,
		['mLockArea' .. partId]		= isLock
	}
	UIExtend.setNodesVisible(self.mMapNode, visibleMap)
	local colorMap =
	{
		['mMapLight' .. partId] 	= _genColor(MapLightColor[state]),
		['mMapGradient' .. partId]	= _genColor(MapGradientColor[state]),
		['mMapLine' .. partId]		= _genColor(MapLightColor[state])
	}
	UIExtend.setColorForCCSprite(self.mMapNode, colorMap)

	local zorder = isExecuting and partId * 9999 or (isLock and partId or partId * 1000)
	UIExtend.setNodeZorder(self.mMapNode, 'mMapAreaNode' .. partId, zorder)

	if isExecuting 
		or RADungeonManager:IsExecuting(dungeonId) 
		or (isPass and RADungeonManager:IsLastDungeonOfChapter(dungeonId))
	then
		
		local sprite = UIExtend.getCCSpriteFromCCB(self.mMapNode, 'mMapLight' .. partId)
		self.executingPartId = partId
		if isExecuting then
			local outAni, inAni = CCFadeTo:create(1.0, 100), CCFadeTo:create(1.0, 255)
			UIExtend.runForever(sprite, outAni, inAni)
		end

		local localPos = UIExtend.getNodeSpacePositionAR(sprite, self.mMapNode)

		local targetPos = RACcpSub(self.mMapInfo.centerPos, localPos)
		self:_validatePos(targetPos)
		localPos:delete()

		self.mTargetPos = targetPos
		if self.mIsInAni then
			self.mIsLocating = true
		else
			self:_locateTargetArea()
		end
	end
end

function RADungeonMainPage:_locateTargetArea()
	local this = self
	performWithDelay(self.mMapNode, function()
		local pos = ccp(self.mTargetPos.x, self.mTargetPos.y)
	    local moveAction = CCMoveTo:create(0.6, pos)
		pos:delete()

		UIExtend.runActionWithCallback(self.mMapNode, moveAction, function()
			this.mMapInfo.pos = RACcp(self.mTargetPos.x, self.mTargetPos.y)
            this:_initGuide()
		end)
		this.mIsLocating = false
	end, 0.4)
end

function RADungeonMainPage:_releaseNodes()
	if self.mTouchLayer then
		self.mTouchLayer:unregisterScriptTouchHandler()
		self.mTouchLayer = nil
	end
	UIExtend.releaseCCBFile(self.mMapNode)
	self.mTitleNode = nil
	self.mMapNode = nil
	UIExtend.unLoadCCBFile(self)
end

function RADungeonMainPage:_registerPacketListener()
	RADungeonHandler:registerPacketListener()
end

function RADungeonMainPage:_removePacketListener()
	RADungeonHandler:removePacketListener()
end

function RADungeonMainPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RADungeonMainPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RADungeonMainPage._onReceiveMessage(msg)
    local msgId = msg.messageID
    local self = RADungeonMainPage

    if msgId == MessageDefine_PVE.MSG_Sync_ChapterPartsInfo then
    	self:_setAllPartsState()
        return
    end

    -- 新手 by xinping
    if msgId == MessageDef_Guide.MSG_Guide  then
    	local constGuideInfo = msg.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire('RAGuideConfig')
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEMapNode then
            if constGuideInfo.showGuidePage == 1 then
            	local executingPartId=RADungeonMainPage.executingPartId

                local mapAreaNode = UIExtend.getCCNodeFromCCB(RADungeonMainPage.mMapNode, 'mGuideMapAreaNode'..executingPartId)
                local pos = ccp(0, 0)
                pos.x, pos.y = mapAreaNode:getPosition()
                local worldPos = mapAreaNode:getParent():convertToWorldSpace(pos)
                local size = mapAreaNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({['guideId'] = guideId, ['pos'] = worldPos, ['size'] = size})
            end 
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEBackBtn then
        	 if constGuideInfo.showGuidePage == 1 then
         
                local backNode = UIExtend.getCCNodeFromCCB(RADungeonMainPage.ccbfile, 'mGuideBackNode')
                local pos = ccp(0, 0)
                pos.x, pos.y = backNode:getPosition()
                local worldPos = backNode:getParent():convertToWorldSpace(pos)
                local size = backNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({['guideId'] = guideId, ['pos'] = worldPos, ['size'] = size})
            end 
        end  

        performWithDelay(self.ccbfile, function()
            RADungeonMainPage.canClick = true
        end,1.0)
    end
end

function RADungeonMainPage:_getChapterInfo()
	if self.mTitleNode then
		local titleName = _RALang('@Chapter' .. self.mDungeonInfo.chapterId)
		self.mTitleNode:setString(titleName)
	end
	RADungeonHandler:sendFetchOneChapterReq(self.mDungeonInfo.chapterId)
end

function RADungeonMainPage._onSingleTouch(event, touch)
	if RAGuideManager.isInGuide() then return end
	
	local self = RADungeonMainPage
    if event == 'began' then
       return self:_onSingleTouchBegan(touch)
    elseif event == 'moved' then
       return self:_onSingleTouchMoved(touch)
    elseif event == 'ended' then
       return self:_onSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

function RADungeonMainPage:_onSingleTouchBegan(touch)
    self.mTouchRecord.touchPos = self.mTouchLayer:convertTouchToNodeSpace(touch)
    self.mTouchRecord.touchId = touch:getID()

    return true
end

function RADungeonMainPage:_onSingleTouchMoved(touch)
    if self.mTouchRecord.touchId ~= touch:getID() then return end

    local touchPos = self.mTouchLayer:convertTouchToNodeSpace(touch)

    if not self.mTouchRecord.isMoving then
    	-- iphone6s 敏感度太高，10以内当做点击
        local moveDis = ccpDistance(self.mTouchRecord.touchPos, touchPos)
        if moveDis > 10 then
            self.mTouchRecord.isMoving = true
        end
    end

    if self.mTouchRecord.isMoving then
	    self.mTouchRecord.offset = ccpSub(touchPos, self.mTouchRecord.touchPos)
	    self:_onTouchMove(self.mTouchRecord.offset)
	end

    self.mTouchRecord.touchPos = touchPos
end

function RADungeonMainPage:_onSingleTouchEnded(touch)
	if self.mTouchRecord.touchId ~= touch:getID() then return end

    self.mTouchRecord.isMoving = false
end

function RADungeonMainPage:_onTouchMove(offset)
	local newPos = RACcpAdd(self.mMapInfo.pos, offset)
	self:_validatePos(newPos)
	
	self.mMapNode:setPosition(newPos.x, newPos.y)
	self.mMapInfo.pos = newPos
end

function RADungeonMainPage:_validatePos(pos)
	-- 边界检测
	pos.x = common:clamp(pos.x, self.mMapInfo.minPos.x, self.mMapInfo.maxPos.x)
	pos.y = common:clamp(pos.y, self.mMapInfo.minPos.y, self.mMapInfo.maxPos.y)
end

return RADungeonMainPage