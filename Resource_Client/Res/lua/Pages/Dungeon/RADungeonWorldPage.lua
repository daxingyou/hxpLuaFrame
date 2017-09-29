--[[
	desc: 	关卡世界地图页面
	author: royhu
	date: 	2016-12-27
]]--

RARequire('BasePage')

local pageVar =
{
	mPageName 	= 'RADungeonWorldPage',
	mRootNode 	= nil,
	mTouchLayer = nil,
	mMapNode 	= nil,

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
		chapterId = 1
	}
}
local RADungeonWorldPage = BaseFunctionPage:new(..., pageVar)

local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RADungeonHandler = RARequire('RADungeonHandler')
local RADungeonManager = RARequire('RADungeonManager')
local RANetUtil = RARequire('RANetUtil')
local common = RARequire('common')
local HP_pb = RARequire('HP_pb')
local Dungeon_pb = RARequire('Dungeon_pb')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAGuideManager = RARequire('RAGuideManager')

local msgTB =
{
	MessageDefine_PVE.MSG_Sync_AllChapterInfo,
	MessageDef_Guide.MSG_Guide                    --新手引导用的消息监听 by xinping
}

local ChapterStateIcon =
{
	[Dungeon_pb.CHAPTER_STATE_PASSED]		= 'NewPVE_Icon_Territory_2.png',
	[Dungeon_pb.CHAPTER_STATE_EXECUTING] 	= 'Map_World_Current.png',
	[Dungeon_pb.CHAPTER_STATE_LOCKED]		= 'Map_World_Lock.png'
}
local ChapterStateColor =
{
	[Dungeon_pb.CHAPTER_STATE_PASSED]		= {255, 255, 255},
	[Dungeon_pb.CHAPTER_STATE_EXECUTING] 	= {234, 255, 188},
	[Dungeon_pb.CHAPTER_STATE_LOCKED]		= {255, 255, 255}
}
local Btn2ChapterId =
{
	onSABtn 		= 1,
	onNABtn 		= 2,
	onAfricaBtn 	= 3,
	onEuropeBtn 	= 4,
	onAsiaBtn 		= 5,
	onAustraliaBtn 	= 6
}
local FontSizeMap =
{
	[Dungeon_pb.CHAPTER_STATE_PASSED]		= 40,
	[Dungeon_pb.CHAPTER_STATE_EXECUTING] 	= 52,
	[Dungeon_pb.CHAPTER_STATE_LOCKED]		= 40
}
local Pixel_Per_Second = 0.001
local Target_Map_Scale = 2.0

local function _genColor(colorTb)
	return colorTb and ccc3(unpack(colorTb))
end

function RADungeonWorldPage:Enter()
	self.canClick = false
	self:_registerPacketListener()
	self:_registerMessageHandlers()
	self:_initCover()
	self:_initRootNode()
	self:_initTitle()
	self:_initTouchLayer()
	
	self:_initChapterMap()
	self:_initChapterInfo()

	--进入战役页面播放战前准备音乐
	SoundManager:getInstance():playMusic('warLoadingMusic.mp3')
end

function RADungeonWorldPage:Exit()
	self.canClick = nil
	self:_removePacketListener()
	self:_unregisterMessageHandlers()

	self:_releaseNodes()
end

-------------------------------------
-- region: btn response

function RADungeonWorldPage:onMapAreaBtn(btnIndex)
	local chapterId = btnIndex
	local state = RADungeonManager:GetChapterState(chapterId)
	if state ~= Dungeon_pb.CHAPTER_STATE_LOCKED then
		local scaleAction = CCScaleTo:create(1.0, Target_Map_Scale)

		local pos = RACcpSub(self.mMapInfo.centerPos, self.mMapInfo.pos)
		pos = RACcpSub(self.mMapInfo.centerPos, RACcpMult(pos, Target_Map_Scale))
		local targetPos = ccp(pos.x, pos.y)
		local moveAction = CCMoveTo:create(1.0, targetPos)

		self.mMapNode:runAction(scaleAction)
		local shaderNode = UIExtend.getCCShaderNodeFromCCB(self.ccbfile, 'mShaderNode')
		self.ccbfile:runAnimation('OutAni')
		local this = self

		if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
			RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
	    end

		UIExtend.runActionWithCallback(self.mMapNode, moveAction, function()
			targetPos:delete()
			RARootManager.OpenPage('RADungeonMainPage', {chapterId = chapterId})
			this.mMapNode:setVisible(false)
			this.mMapNode:setScale(1.0)
			this.mMapNode:setPosition(this.mMapInfo.pos.x, this.mMapInfo.pos.y)
			performWithDelay(this.mMapNode, function()
				this.mMapNode:setVisible(true)
				this.ccbfile:runAnimation('Default Timeline')
				shaderNode:setValue4(0)
			end, 1.0)
		end)
	end
end

function RADungeonWorldPage:onBack()
	RARootManager.CloseCurrPage()
end

-- endregion: btn response
-------------------------------------

function RADungeonWorldPage:_initChapterInfo()
	if not RADungeonManager:IsReady() then
		RADungeonHandler:sendFetchAllChapterReq()
	else
		self:_setAllPartsState()
	end
end

function RADungeonWorldPage:_initRootNode()
	UIExtend.loadCCBFile('RAPVEWorldPage.ccbi', self)
	self.mRootNode = self.ccbfile
end

function RADungeonWorldPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local titleName = _RALang('@TheLevel')
    RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, nil, nil, false)
    UIExtend.setNodeVisible(titleCCB, 'mLightNode', false)
end

function RADungeonWorldPage:_initTouchLayer()
	local layer = UIExtend.getCCLayerFromCCB(self.ccbfile, 'mMapLayer')
    
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
	layer:setTouchMode(kCCTouchesOneByOne)
    layer:registerScriptTouchHandler(self._onSingleTouch)

    self.mTouchLayer = layer
end

function RADungeonWorldPage:_initCover()
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
    end
end

function RADungeonWorldPage:_initGuide()
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RAGuideManager.gotoNextStep()
    else
    	self.canClick = true
    end
end

function RADungeonWorldPage:_initChapterMap()
	local handler = {}
	local this = self
	for btnName, chapterId in pairs(Btn2ChapterId) do
		handler[btnName] = function()
			this:onMapAreaBtn(chapterId)
		end
	end
	self.mMapNode = UIExtend.loadCCBFile('RAPVEWorld.ccbi', handler)
	self.mMapNode:setScale(1.0)
	self.mTouchLayer:addChild(self.mMapNode)
	self.mMapNode:setVisible(false)

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

	local x, y = RACcpUnpack(self.mMapInfo.minPos)
	self.mMapNode:setPosition(x, y)
	self.mMapInfo.pos = RACcp(x, y)

	RAGameUtils:setChildMenu(self.mMapNode, CCRectMake(0, 0, winSize.width, winSize.height - titleSize.height))

	size:delete()
	winSize:delete()
	titleSize:delete()

	local strMap, sizeMap = {}, {}
	for _, chapterId in ipairs(RADungeonManager:GetChapterIdList()) do
		local cfg = RADungeonManager:GetChapterCfg(chapterId)
		strMap['mWorldLabel' .. chapterId] = _RALang(cfg.name)
		local sizeState = chapterId == 1 and Dungeon_pb.CHAPTER_STATE_EXECUTING or Dungeon_pb.CHAPTER_STATE_LOCKED
		sizeMap['mWorldLabel' .. chapterId] = FontSizeMap[sizeState]
	end
	UIExtend.setStringForLabel(self.mMapNode, strMap)
	UIExtend.setFontSizeForLabel(self.mMapNode, sizeMap)
end

function RADungeonWorldPage:_moveCamera(chapterId)
	local node = UIExtend.getCCNodeFromCCB(self.mMapNode, 'mWorldIcon' .. chapterId)
	local localPos = UIExtend.getNodeSpacePositionAR(node, self.mMapNode)

	local targetPos = RACcpSub(self.mMapInfo.centerPos, localPos)
	self:_validatePos(targetPos)
	localPos:delete()

	-- requirement: 只要平行位移动画
	self.mMapNode:setPosition(self.mMapInfo.pos.x, targetPos.y)
	self.mMapNode:setVisible(true)

	local Utilitys = RARequire('Utilitys')
	local distance = Utilitys.getDistance(self.mMapInfo.pos, targetPos)
	pos = ccp(targetPos.x, targetPos.y)
	
	local this = self
	performWithDelay(self.mMapNode, function()
	    local moveTo = CCMoveTo:create(distance * Pixel_Per_Second, pos)
	    UIExtend.runActionWithCallback(self.mMapNode, moveTo, function()
	    	this:_initGuide()
	    end)

		pos:delete()
		this.mMapInfo.pos = targetPos
	end, 0.2)
end

function RADungeonWorldPage:_setAllPartsState()
	self.mDungeonInfo.chapterId = RADungeonManager:GetProgressInfo().chapterId
	for _, chapterId in ipairs(RADungeonManager:GetChapterIdList()) do
		self:_setPartState(chapterId)
	end

	self:_moveCamera(self.mDungeonInfo.chapterId)
end

function RADungeonWorldPage:_setPartState(chapterId)
	local state = RADungeonManager:GetChapterState(chapterId)
	UIExtend.setFontSizeForLabel(self.mMapNode, {['mWorldLabel' .. chapterId] = FontSizeMap[state]})
	UIExtend.setColorForLabel(self.mMapNode, {['mWorldLabel' .. chapterId] = _genColor(ChapterStateColor[state])})
	UIExtend.setSpriteImage(self.mMapNode, {['mWorldIcon' .. chapterId] = ChapterStateIcon[state]})
end

function RADungeonWorldPage:_releaseNodes()
	RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
	if self.mTouchLayer then
		self.mTouchLayer:unregisterScriptTouchHandler()
		self.mTouchLayer = nil
	end
	UIExtend.releaseCCBFile(self.mMapNode)
	self.mMapNode = nil
	UIExtend.unLoadCCBFile(self)
end

function RADungeonWorldPage:_registerPacketListener()
	RADungeonHandler:registerPacketListener()
end

function RADungeonWorldPage:_removePacketListener()
	RADungeonHandler:removePacketListener()
end

function RADungeonWorldPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RADungeonWorldPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RADungeonWorldPage._onReceiveMessage(msg)
    local msgId = msg.messageID
    local self = RADungeonWorldPage

    if msgId == MessageDefine_PVE.MSG_Sync_AllChapterInfo then
    	self:_setAllPartsState()
        return
    end
      -- 新手 by xinping
    if msgId == MessageDef_Guide.MSG_Guide  then
    	local constGuideInfo = msg.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire('RAGuideConfig')
        --if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEWorldMapNode then
            if constGuideInfo.showGuidePage == 1 then
            	
                local mapAreaNode = UIExtend.getCCNodeFromCCB(RADungeonWorldPage.mMapNode, 'mWorldIcon1')
                local pos = ccp(0, 0)
                pos.x, pos.y = mapAreaNode:getPosition()
                local worldPos = mapAreaNode:getParent():convertToWorldSpace(pos)
                local size = mapAreaNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({['guideId'] = guideId, ['pos'] = worldPos, ['size'] = size})
                RADungeonWorldPage.canClick = true
            end 
       -- end  
    
    end
end

function RADungeonWorldPage._onSingleTouch(event, touch)
	if RAGuideManager.isInGuide() then return end
	
	local self = RADungeonWorldPage
    if event == 'began' then
       return self:_onSingleTouchBegan(touch)
    elseif event == 'moved' then
       return self:_onSingleTouchMoved(touch)
    elseif event == 'ended' then
       return self:_onSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

function RADungeonWorldPage:_onSingleTouchBegan(touch)
    self.mTouchRecord.touchPos = self.mTouchLayer:convertTouchToNodeSpace(touch)
    self.mTouchRecord.touchId = touch:getID()

    return true
end

function RADungeonWorldPage:_onSingleTouchMoved(touch)
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

function RADungeonWorldPage:_onSingleTouchEnded(touch)
	if self.mTouchRecord.touchId ~= touch:getID() then return end

    self.mTouchRecord.isMoving = false
end

function RADungeonWorldPage:_onTouchMove(offset)
	local newPos = RACcpAdd(self.mMapInfo.pos, offset)
	self:_validatePos(newPos)
	
	self.mMapNode:setPosition(newPos.x, newPos.y)
	self.mMapInfo.pos = newPos
end

function RADungeonWorldPage:_validatePos(pos)
	-- 边界检测
	pos.x = common:clamp(pos.x, self.mMapInfo.minPos.x, self.mMapInfo.maxPos.x)
	pos.y = common:clamp(pos.y, self.mMapInfo.minPos.y, self.mMapInfo.maxPos.y)
end

return RADungeonWorldPage