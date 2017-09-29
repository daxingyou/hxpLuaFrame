local RAWorldMigrateHelper =
{
	mRootNode = nil,
	mMainNode = nil,
    mBenchMarkNode = nil,
	mCityNode = nil,
	mAniNode = nil,
    mHudNode = nil,
    mCarNode = nil,
	mMigrateBtn = nil,

	mIsMigrating = false,
	mIsBlock = false,
	-- 当前迁城的中心点坐标
	mTargetPos = nil,
	mTileCoords = {},
	mTileNodes = {},
    mBtnList = {},
    mTouchNodes = {}
}

local TileKey =
{
    TOP     = 'TOP',
    LEFT    = 'LEFT',
    BOTTOM  = 'BOTTOM',
    RIGHT   = 'RIGHT'
}

local msgTB =
{
    MessageDef_World.MSG_AddWorldPoint,
    MessageDef_World.MSG_DelWorldPoint,
}

-- 确认类型
local ConfirmType =
{
    March       = 1,
    Territory   = 2,
    BankArea    = 3,
    Consume     = 4,

    Max         = 4
}

local ConfirmFunc =
{
    [ConfirmType.March]     = '_checkMarching',
    [ConfirmType.Territory] = '_checkTerritory',
    [ConfirmType.BankArea]  = '_checkBankArea',
    [ConfirmType.Consume]   = '_confirmConsume'
}

local RAWorldConfig = RARequire('RAWorldConfig')
local RAGameConfig = RARequire('RAGameConfig')
local RAWorldMath = RARequire('RAWorldMath')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local common = RARequire('common')
local RAWorldVar = RARequire('RAWorldVar')
local BtnType = RAWorldConfig.HudBtnType

function RAWorldMigrateHelper:Init(rootNode)
	self.mRootNode = rootNode
end

function RAWorldMigrateHelper:Clear()
	self:StopMigrate()
	self:_removeAniNode()
    self:_resetBuilding()
    self.mCityNode = nil
	self.mTargetPos = nil
    self.mTouchNodes = {}
end

-- 是否在迁城
function RAWorldMigrateHelper:IsMigrating()
	return self.mIsMigrating
end

function RAWorldMigrateHelper:IsOnTouch(touchPos, touch)
    local mapPos = RAWorldMath:View2Map(touchPos, true)
    if self:_isOnTileBg(mapPos) then return true end

    local RALogicUtil = RARequire('RALogicUtil')
    for _, touchNode in ipairs(self.mTouchNodes) do
        if RALogicUtil:isTouchInside(touchNode, touch) then
            return true
        end
    end

    return false
end

function RAWorldMigrateHelper:_addBenchMarkNode()
    local markNode = CCNode:create()
    
    local pos = RAWorldMath:Map2View(self.mTargetPos)
    markNode:setPosition(pos.x, pos.y)
    self.mRootNode:addChild(markNode)
    self.mBenchMarkNode = markNode
end

function RAWorldMigrateHelper:BeginMigrate(mapPos)
	local centerMapPos = {x = mapPos.x - 1, y = mapPos.y}
    self:_addTileBg(centerMapPos)
    self:_addBenchMarkNode()
    self:_addMainNode()
    self:_addCity()
    self:_addHud()

    -- if self.mMigrateBtn then
    --     self.mMigrateBtn:setEnabled(not self.mIsBlock)
    -- end

    self.mIsMigrating = true

    self:_registerMessageHandlers()
end

function RAWorldMigrateHelper:Migrating(offset,screenPoint,touchSpacePos)
    if self.mIsMigrating == false then return end
    --CCLuaLog("RAWorldMigrateHelper:Migrating(offset)"..offset.x..",  "..offset.y .. "screen point is "..screenPoint.x .. ", ".. screenPoint.y )
    local posX, posY = touchSpacePos.x,touchSpacePos.y
    
    -- judge whether need to update map
    local centerPos = RAWorldMath:GetViewPos(RAWorldVar.ViewPos.Center)
    print("touchSpacePos is ",touchSpacePos.x,touchSpacePos.y,"center pos is ",centerPos.x,centerPos.y)
    local winSize = CCDirector:sharedDirector():getWinSize()
    if screenPoint.x <100 or screenPoint.x >540 
    or screenPoint.y <200 or screenPoint.y >(winSize.height-200) then
        local newSpace = RACcp((centerPos.x + touchSpacePos.x  )/2,(centerPos.y + touchSpacePos.y )/2) 
        offset.x =  centerPos.x -newSpace.x
        offset.y = centerPos.y- newSpace.y 
        --print("newSpace is ",newSpace.x,newSpace.y,"center pos is ",centerPos.x,centerPos.y)
        local RAWorldMap = RARequire("RAWorldMap")
        RAWorldMap:OffsetMapWithTime(offset,0.2)
        local RAWorldScene = RARequire('RAWorldScene')
        RAWorldScene:ShowPosition()

    end

    local mapPos = RAWorldMath:View2Map(RACcp(posX, posY), true)

    if RAWorldMath:IsValidMapPos(RACcp(mapPos.x - 1, mapPos.y - 1), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x + 1, mapPos.y - 1), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y - 2), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y), true)
    then
        self.mBenchMarkNode:setPosition(posX, posY)
        local spacePos = RAWorldMath:Map2View(RACcp(mapPos.x, mapPos.y - 1))
        self.mMainNode:setPosition(spacePos.x, spacePos.y)
        self:_addTileBg(RACcp(mapPos.x, mapPos.y - 1))
    end
   
end

function RAWorldMigrateHelper:StopMigrate()
    self:_unregisterMessageHandlers()
	for _, node in pairs(self.mTileNodes) do
		if node then
			node:removeFromParentAndCleanup(true)
		end
	end
	self.mTileNodes = {}

    for _, btn in ipairs(self.mBtnList) do
        if btn then
            UIExtend.releaseCCBFile(btn)
        end
    end
    self.mBtnList = {}

    UIExtend.releaseCCBFile(self.mHudNode)
    self.mHudNode = nil

	if self.mMainNode then
		self.mMainNode:removeFromParentAndCleanup(true)
	end
	self.mMainNode = nil

    if self.mBenchMarkNode then
        self.mBenchMarkNode:removeFromParentAndCleanup(true)
    end
    self.mBenchMarkNode = nil

	self.mCityNode = nil
	self.mMigrateBtn = nil

	self.mIsMigrating = false
	self.mIsBlock = false
	self.mTileCoords = {}
end

function RAWorldMigrateHelper:OnMigrateRsp(isOK, migratePos, hasTip)
    self:StopMigrate()
    
    if migratePos then
        self.mTargetPos = migratePos
    end
    
    if isOK then
    	local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')

        -- make sure the old city is removed
        if not RACcpEqual(migratePos, RAWorldVar.MapPos.Self) then
            RAWorldBuildingManager:removeBuilding(RAWorldVar.MapPos.Self)
        end

        local id, building = RAWorldBuildingManager:GetBuildingAt(self.mTargetPos)
        if building == nil then
        	RAWorldBuildingManager:addMyCity(self.mTargetPos)
        	id, building = RAWorldBuildingManager:GetBuildingAt(self.mTargetPos)
        end

        building:setVisible(false)
        building:SetLevelSignVisible(false)

        self:_removeAniNode()
        
        -- 添加迁城动画
        local this = self
        local aniNode = UIExtend.loadCCBFile('Ani_Map_Transfer.ccbi', {
            OnAnimationDone = function (self, node)
                local lastAnimationName = node:getCompletedAnimationName()     
                if lastAnimationName == 'Ani_2' then
                    this:_removeAniNode()
                elseif lastAnimationName == 'Default Timeline' then
                    if node then
                        node:runAnimation('Ani_2')
                    end

                    -- 基地车动画
                    local id, building = RAWorldBuildingManager:GetBuildingAt(migratePos)
                    if building == nil then return end

                    local RAWorldUtil = RARequire('RAWorldUtil')
                    local World_pb = RARequire('World_pb')
                    local spineName = RAWorldConfig.Spine.CityCar
                    local car = RAWorldUtil:AddSpine(spineName, World_pb.SELF)
                    car:setPosition(building:getPosition())
                    this.mRootNode:addChild(car)
                    this.mCarNode = car

                    car:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
                        if eventName == 'Complete' then
                            if animationName == BUILDING_ANIMATION_TYPE.ORIGIN then
                                -- 基地伸展动画
                                local id, building = RAWorldBuildingManager:GetBuildingAt(migratePos)
                                if building then
                                    building:runAction(BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP, 1)
                                end
                                car:unregisterLuaListener()
                                car:removeFromParentAndCleanup(true)
                                this.mCarNode = nil
                            end
                        end
                    end)
                    car:runAnimation(0, BUILDING_ANIMATION_TYPE.ORIGIN, 1)
                end
            end
        })

        local viewPos = RAWorldMath:Map2View(self.mTargetPos)
        aniNode:setPosition(viewPos.x, viewPos.y)
        self.mRootNode:addChild(aniNode)
        self.mAniNode = aniNode

        common:playEffect('moveCity')

        RAWorldVar:UpdateSelfPos(self.mTargetPos)
    elseif not hasTip then
        RARootManager.ShowMsgBox('@MigrateFail')
    end

    RAWorldVar:SetMigrateTarget(nil)
end

function RAWorldMigrateHelper:_addTileBg(centerMapPos)
    local hasBlock = false
    self.mTileCoords = {}

    local topPos = {x = centerMapPos.x, y = centerMapPos.y - 1}
    hasBlock = self:_addSingleTile(TileKey.TOP, topPos) or hasBlock
    table.insert(self.mTileCoords, topPos)

    local leftPos = {x = centerMapPos.x - 1, y = centerMapPos.y}
    hasBlock = self:_addSingleTile(TileKey.LEFT, leftPos) or hasBlock
    table.insert(self.mTileCoords, leftPos)

    local bottomPos = {x = centerMapPos.x, y = centerMapPos.y + 1}
    hasBlock = self:_addSingleTile(TileKey.BOTTOM, bottomPos) or hasBlock
    table.insert(self.mTileCoords, bottomPos)

    local rightPos = {x = centerMapPos.x + 1, y = centerMapPos.y}
    hasBlock = self:_addSingleTile(TileKey.RIGHT, rightPos) or hasBlock
    table.insert(self.mTileCoords, rightPos)

    self.mTargetPos = centerMapPos

    -- if self.mMigrateBtn then
    --     self.mMigrateBtn:setEnabled(not hasBlock)
    -- end
    self.mIsBlock = hasBlock

    return hasBlock
end

function RAWorldMigrateHelper:_addSingleTile(key, mapPos)
    local RAWorldManager = RARequire('RAWorldManager')
    local isBlock = RAWorldManager:IsBlock(mapPos)

    local pic = isBlock and RAWorldConfig.MigrateTile.Block or RAWorldConfig.MigrateTile.Allow

    local sprite = self.mTileNodes[key]
    if sprite then
        sprite:setTexture(pic)
    else
        sprite = CCSprite:create(pic)
        self.mRootNode:addChild(sprite)
        self.mTileNodes[key] = sprite
    end
    sprite:setScale(RAWorldConfig.MigrateTile.Scale)

    local pos = RAWorldMath:Map2View(mapPos)
    sprite:setPosition(pos.x, pos.y)

    return isBlock
end

function RAWorldMigrateHelper:_isOnTileBg(mapPos)
    for _, pos in ipairs(self.mTileCoords) do
        if RACcpEqual(mapPos, pos) then return true end
    end
    return false
end

function RAWorldMigrateHelper:_addMainNode()
    local migrateNode = CCNode:create()
    
    local pos = RAWorldMath:Map2View(self.mTargetPos)
    migrateNode:setPosition(pos.x, pos.y)
    
    self.mRootNode:addChild(migrateNode)
    CCCamera:setBillboard(migrateNode)

    self.mMainNode = migrateNode
end

function RAWorldMigrateHelper:_addCity()
	local RABuildManager = RARequire('RABuildManager')
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local spineName = RAWorldConfigManager:GetCitySpineByLevel(RABuildManager:getMainCityLvl())

    local RAWorldUtil = RARequire('RAWorldUtil')
    local World_pb = RARequire('World_pb')
    local cityNode = RAWorldUtil:AddSpine(spineName, World_pb.SELF)
    cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.IDLE_MAP, -1)
    self.mMainNode:addChild(cityNode)
    cityNode:setPosition(0, -RAWorldConfig.tileSize.height)

    self.mCityNode = cityNode
end

function RAWorldMigrateHelper:_addHud()
   	local hudNode = UIExtend.loadCCBFile('RAHUDWorldNode.ccbi', {})
    
    UIExtend.setNodeVisible(hudNode, 'mHUDTitleNode', false)
    hudNode:setPosition(0, -RAWorldConfig.halfTile.height)
    
    self.mMainNode:addChild(hudNode)
    self.mHudNode = hudNode

    self:_addMigrateBtn(hudNode)
    self:_addCancelBtn(hudNode)

    hudNode:runAnimation('FunAni2')

    table.insert(self.mTouchNodes, (hudNode:getCCNodeFromCCB('mTouchNode')))
end

function RAWorldMigrateHelper:_addMigrateBtn(ccbfile)
	local this = self

    local migrateBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
        	common:playEffect('mapClickDetermine')
            this:_checkAndConfirm()
        end
    })
    migrateBtn:setAnchorPoint(0, 0)
    migrateBtn:setPosition(0, 0)
    UIExtend.setNodeVisible(migrateBtn, 'mHUDNameNode', true)
    self.mMigrateBtn = UIExtend.getCCControlButtonFromCCB(migrateBtn, 'mFunction')
    self.mMigrateBtn:setEnabled(true)
    table.insert(self.mBtnList, migrateBtn)

    local lang = RAWorldConfig.HudBtnLang[BtnType.Migrate]
    local sprite = RAWorldConfig.HudBtnImg[BtnType.Migrate]
    local btnStr = RAStringUtil:getLanguageString(lang)

    UIExtend.setCCLabelString(migrateBtn, 'mBtnName', btnStr)
    UIExtend.setSpriteIcoToNode(migrateBtn, 'mHUDIcon', sprite)

    UIExtend.addNodeToParentNode(ccbfile, 'mFunNode1', migrateBtn)
end

function RAWorldMigrateHelper:_addCancelBtn(ccbfile)
	local this = self
    local cancelBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
            this:StopMigrate()
        end
    })
    cancelBtn:setAnchorPoint(0, 0)
    cancelBtn:setPosition(0, 0)
    UIExtend.setNodeVisible(cancelBtn, 'mHUDNameNode', true)
    UIExtend.setCCControlButtonEnable(cancelBtn, 'mFunction', true)

    table.insert(self.mBtnList, cancelBtn)

    local lang = RAWorldConfig.HudBtnLang[BtnType.CancelMigrate]
    local sprite = RAWorldConfig.HudBtnImg[BtnType.CancelMigrate]
    local btnStr = RAStringUtil:getLanguageString(lang)

    UIExtend.setCCLabelString(cancelBtn, 'mBtnName', btnStr)
    UIExtend.setSpriteIcoToNode(cancelBtn, 'mHUDIcon', sprite)

    UIExtend.addNodeToParentNode(ccbfile, 'mFunNode2', cancelBtn)
end

--------------------------------------------------------------------------------------
-- region: 迁城确认

function RAWorldMigrateHelper:_checkAndConfirm()
    -- 是否有阻挡区
    if self.mIsBlock then
        RARootManager.ShowMsgBox('@UnableToMoveHere')
        return
    end

    -- 是否在跨服迁城
    if not self:_checkCrossingServer() then
        return
    end

    self:_confirmMigrate(ConfirmType.March)
end

-- 确认迁城
function RAWorldMigrateHelper:_confirmMigrate(confirmType)
    for _type = confirmType, ConfirmType.Max, 1 do
        local confirmFunc = self[ConfirmFunc[_type]]
        if confirmFunc and confirmFunc(self, _type + 1) then
            return
        end
    end
end

-- 是否在跨服迁城
function RAWorldMigrateHelper:_checkCrossingServer()
    -- 是否跨服
    if RAWorldVar:IsInSelfKingdom() then
        return true
    end

    -- 是否超过等级限制
    local world_map_const_conf = RARequire('world_map_const_conf')
    local lvLimit = world_map_const_conf.stepCityLevel1.value or 6
    local RABuildManager = RARequire('RABuildManager')
    if RABuildManager:getMainCityLvl() > lvLimit then
        RARootManager.ShowMsgBox('@LevelLimitToMigrate', lvLimit)
        return false
    end

    -- 是否在联盟中
    local RAAllianceManager = RARequire('RAAllianceManager')
    if RAAllianceManager:IsInGuild() then
        RARootManager.ShowMsgBox('@NeedToExitGuildToMigrate')
        return false
    end

    return true
end

-- 是否有部队在外执行任务
function RAWorldMigrateHelper:_checkMarching(nextConfirmType)
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    if RAMarchDataManager:GetSelfMarchCount() > 0 then
        local this = self
        local confirmData =
        {
            title = _RALang('@ConfirmMigrateTitle'),
            labelText = _RALang('@ConfirmMoveCity_Marching'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    self:_confirmMigrate(nextConfirmType)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
        return true
    end

    return false
end

-- 检查是否发起了一个集结或者集结队伍正在行军中
function RAWorldMigrateHelper:_checkMassing()
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local textKey = nil

    if RAMarchDataManager:CheckIsSelfTeamLeader() then
        textKey = '@IsStartingAMass'
    elseif RAMarchDataManager:CheckIsSelfMassJoinAndMarching() then
        textKey = '@IsJoinAMarchingMass'
    end

    if textKey then
        local this = self
        local confirmData =
        {
            labelText = _RALang(textKey),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    if not this:_checkBankArea() then
                        this:_confirmMigrate()
                    end
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
        return true
    end

    return false
end

-- 检查是否正迁往别人的领地
function RAWorldMigrateHelper:_checkTerritory(nextConfirmType)
    local RAWorldManager = RARequire('RAWorldManager')
    if RAWorldManager:IsInTerritoryOfEnemy(self.mTargetPos) then
        local this = self
        local confirmData =
        {
            title = _RALang('@ConfirmMigrateTitle'),
            labelText = _RALang('@ConfirmMoveCity_Territory'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    this:_confirmMigrate(nextConfirmType)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
        return true
    end

    return false
end

-- 检查是否迁到黑土地
function RAWorldMigrateHelper:_checkBankArea(nextConfirmType)
    local RAWorldUtil = RARequire('RAWorldUtil')
    if RAWorldUtil:IsInBankArea(self.mTargetPos) then
        local this = self
        local confirmData =
        {
            title = _RALang('@WarZone'),
            labelText = _RALang('@ConfirmMigrateToWarZone'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    this:_confirmMigrate(nextConfirmType)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
        return true
    end

    return false
end

-- 确认是否使用道具或钻石迁城
function RAWorldMigrateHelper:_confirmConsume(nextConfirmType)
    local needItemName, needItemCount = '', 1

    local item_conf =RARequire('item_conf')
    local itemCfg = nil
    
    -- 有定向迁城道具提示使用道具，否则提示使用钻石
    local hasItem = false
    local RACoreDataManager = RARequire('RACoreDataManager')
    local itemIds =
    {
        RAGameConfig.ItemId.GuideMigrate,
        RAGameConfig.ItemId.DirectionalMigrate
    }
    for _, itemId in ipairs(itemIds) do
        itemCfg = item_conf[itemId]
        if RACoreDataManager:getItemCountByItemId(itemId) > 0 then
            needItemName = _RALang(itemCfg.item_name)
            hasItem = true
            break
        end
    end
    
    if not hasItem then
        local RAResManager = RARequire('RAResManager')
        local Const_pb = RARequire('Const_pb')
        local _, name = RAResManager:getResourceIconByType(Const_pb.GOLD)
        needItemName, needItemCount = _RALang(name), itemCfg.sellPrice
    end

    local this = self
    local confirmData =
    {
        title = _RALang('@ConfirmMigrateTitle'),
        labelText = _RALang('@ConfirmMigrateMsg', needItemName, needItemCount),
        yesNoBtn = true,
        resultFun = function (isOK)
            if isOK then
                this:_sendReq()
            end
        end
    }
    RARootManager.showConfirmMsg(confirmData)
end
-- endregion: 迁城确认
--------------------------------------------------------------------------------------

function RAWorldMigrateHelper:_sendReq()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    local World_pb = RARequire('World_pb')
    RAWorldProtoHandler:sendMigrateReq(self.mTargetPos, World_pb.SELECT_MOVE)
    RAWorldVar:SetMigrateTarget(self.mTargetPos)
    self:StopMigrate()
end

function RAWorldMigrateHelper:_removeAniNode()
	if self.mAniNode then
        UIExtend.releaseCCBFile(self.mAniNode)
	end
	self.mAniNode = nil
end

function RAWorldMigrateHelper:_resetBuilding()
    -- revisible the building
    if self.mTargetPos ~= nil 
        and self.mCarNode == nil 
        and RACcpEqual(self.mTargetPos, RAWorldVar.MapPos.Self)
    then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        local id, building = RAWorldBuildingManager:GetBuildingAt(self.mTargetPos)
        if building ~= nil then
            building:setVisible(true)
            building:SetLevelSignVisible(true)
        end
    end
end

function RAWorldMigrateHelper:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAWorldMigrateHelper:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAWorldMigrateHelper._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_World.MSG_AddWorldPoint 
        or msgId == MessageDef_World.MSG_DelWorldPoint 
    then
        local this = RAWorldMigrateHelper
        for _, pos in ipairs(RAWorldMath:GetCoveredMapPos(msg.pos, msg.gridCnt)) do
            if this:_isOnTileBg(pos) then
                this:_addTileBg(this.mTargetPos)
                return
            end
        end
    end
end

return RAWorldMigrateHelper