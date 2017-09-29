local RAWorldBuildSiloHelper =
{
	mRootNode = nil,
	mMainNode = nil,
    mBenchMarkNode = nil,
	mSiloNode = nil,
    mHudNode = nil,
	mBuildSiloBtn = nil,

	mIsBuildingSilo = false,
	mIsBlock = false,
	-- 当前建造的中心点坐标
	mTargetPos = nil,
	mTileCoords = {},
	mTileNodes = {},
    mBtnList = {},
    mTouchNodes = {},

    mWeaponType = nil,
    mBuildingCfg = {},
}

local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldMath = RARequire('RAWorldMath')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local BtnType = RAWorldConfig.HudBtnType

local WeaponType2Hud =
{
    [Const_pb.GUILD_SILO]       = BtnType.BuildNuclearSilo,
    [Const_pb.GUILD_WEATHER]    = BtnType.BuildWeatherSilo
}

function RAWorldBuildSiloHelper:Init(rootNode)
	self.mRootNode = rootNode
end

function RAWorldBuildSiloHelper:Clear()
	self:StopBuildSilo()
    self.mSiloNode = nil
	self.mTargetPos = nil
    self.mTouchNodes = {}
end

-- 是否在建造
function RAWorldBuildSiloHelper:IsBuildingSilo()
	return self.mIsBuildingSilo
end

function RAWorldBuildSiloHelper:IsOnTouch(touchPos, touch)
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

function RAWorldBuildSiloHelper:_addBenchMarkNode()
    local markNode = CCNode:create()
    
    local pos = RAWorldMath:Map2View(self.mTargetPos)
    markNode:setPosition(pos.x, pos.y)
    self.mRootNode:addChild(markNode)
    self.mBenchMarkNode = markNode
end

function RAWorldBuildSiloHelper:BeginBuildSilo(mapPos)
    self:Clear()
    if not self:_initBuildingCfg() then
        return
    end

	local centerMapPos = {x = mapPos.x, y = mapPos.y}
    if not RAWorldMath:IsMapPos4Tile(centerMapPos) then
        centerMapPos.x = centerMapPos.x + 1
        RAWorldMath:ValidateMapPos(centerMapPos)
    end
    self:_addTileBg(centerMapPos)
    self:_addBenchMarkNode()
    self:_addMainNode()
    self:_addSilo()
    self:_addHud()

    -- if self.mBuildSiloBtn then
    --     self.mBuildSiloBtn:setEnabled(not self.mIsBlock)
    -- end

    self.mIsBuildingSilo = true
end

function RAWorldBuildSiloHelper:BuildingSilo(offset,screenPoint,touchSpacePos)
    if self.mIsBuildingSilo == false then return end
    
    local posX, posY = touchSpacePos.x,touchSpacePos.y
    
    -- judge whether need to update map
    local RAWorldVar = RARequire('RAWorldVar')
    local centerPos = RAWorldMath:GetViewPos(RAWorldVar.ViewPos.Center)
    print('touchSpacePos is ',touchSpacePos.x,touchSpacePos.y,'center pos is ',centerPos.x,centerPos.y)
    local winSize = CCDirector:sharedDirector():getWinSize()
    if screenPoint.x < 100 or screenPoint.x > 540 
    or screenPoint.y < 200 or screenPoint.y > (winSize.height - 200) then
        local newSpace = RACcp((centerPos.x + touchSpacePos.x) * 0.5, (centerPos.y + touchSpacePos.y) * 0.5) 
        offset.x = centerPos.x - newSpace.x
        offset.y = centerPos.y - newSpace.y 

        local RAWorldMap = RARequire('RAWorldMap')
        RAWorldMap:OffsetMapWithTime(offset,0.2)
        local RAWorldScene = RARequire('RAWorldScene')
        RAWorldScene:ShowPosition()

    end

    local mapPos = RAWorldMath:View2Map(RACcp(posX, posY), true)

    local posTB = RAWorldMath:GetCoveredMapPos(mapPos, self.mBuildingCfg.gridCnt)
    for _, pos in ipairs(posTB) do
        if not RAWorldMath:IsValidMapPos(pos, true) then
            return
        end
    end

    self.mBenchMarkNode:setPosition(posX, posY)
    local spacePos = RAWorldMath:Map2View(mapPos)
    self.mMainNode:setPosition(spacePos.x, spacePos.y)
    self:_addTileBg(mapPos, posTB)
end

function RAWorldBuildSiloHelper:StopBuildSilo()
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

	self.mSiloNode = nil
	self.mBuildSiloBtn = nil

	self.mIsBuildingSilo = false
	self.mIsBlock = false
	self.mTileCoords = {}
end

function RAWorldBuildSiloHelper:_initBuildingCfg()
    local RAAllianceManager = RARequire('RAAllianceManager')
    local weaponType = RAAllianceManager:getSelfSuperWeaponType()
    local buildingId = RAWorldConfig.SuperWeaponBuildSiloId[weaponType]
    if buildingId then
        local RAWorldConfigManager = RARequire('RAWorldConfigManager')
        local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(buildingId)
        if cfg then
            self.mWeaponType = weaponType
            self.mBuildingCfg = cfg
            return true
        end
    end
    return false
end

function RAWorldBuildSiloHelper:_addTileBg(centerMapPos, tileCoords)
    local hasBlock = false

    if tileCoords == nil then
        self.mTileCoords = RAWorldMath:GetCoveredMapPos(centerMapPos, self.mBuildingCfg.gridCnt)
    else
        self.mTileCoords = tileCoords
    end

    for k, pos in ipairs(self.mTileCoords) do
        hasBlock = self:_addSingleTile(k, pos) or hasBlock
    end

    self.mTargetPos = centerMapPos

    -- if self.mBuildSiloBtn then
    --     self.mBuildSiloBtn:setEnabled(not hasBlock)
    -- end
    self.mIsBlock = hasBlock

    return hasBlock
end

function RAWorldBuildSiloHelper:_addSingleTile(key, mapPos)
    local RAWorldManager = RARequire('RAWorldManager')
    local isBlock = RAWorldManager:IsBlock(mapPos, {isBuildingSilo = true})

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

function RAWorldBuildSiloHelper:_isOnTileBg(mapPos)
    for _, pos in ipairs(self.mTileCoords) do
        if RACcpEqual(mapPos, pos) then return true end
    end
    return false
end

function RAWorldBuildSiloHelper:_addMainNode()
    local buildSiloNode = CCNode:create()
    
    local pos = RAWorldMath:Map2View(self.mTargetPos)
    buildSiloNode:setPosition(pos.x, pos.y)
    
    self.mRootNode:addChild(buildSiloNode)
    CCCamera:setBillboard(buildSiloNode)

    self.mMainNode = buildSiloNode
end

function RAWorldBuildSiloHelper:_addSilo()
    local spineName = self.mBuildingCfg.spine
    local RAWorldUtil = RARequire('RAWorldUtil')
    local World_pb = RARequire('World_pb')
    local siloNode = RAWorldUtil:AddSpine(spineName, World_pb.SELF)
    siloNode:runAnimation(0, BUILDING_ANIMATION_TYPE.IDLE_MAP, -1)
    self.mMainNode:addChild(siloNode)
    siloNode:setPosition(0, -RAWorldConfig.tileSize.height * self.mBuildingCfg.gridCnt * 0.5)

    self.mSiloNode = siloNode
end

function RAWorldBuildSiloHelper:_addHud()
   	local hudNode = UIExtend.loadCCBFile('RAHUDWorldNode.ccbi', {})
    
    UIExtend.setNodeVisible(hudNode, 'mHUDTitleNode', false)
    hudNode:setPosition(0, -RAWorldConfig.halfTile.height)
    
    self.mMainNode:addChild(hudNode)
    self.mHudNode = hudNode

    self:_addBuildSiloBtn(hudNode)
    self:_addCancelBtn(hudNode)

    hudNode:runAnimation('FunAni2')

    table.insert(self.mTouchNodes, (hudNode:getCCNodeFromCCB('mTouchNode')))
end

function RAWorldBuildSiloHelper:_addBuildSiloBtn(ccbfile)
	local this = self

    local btnType = WeaponType2Hud[self.mWeaponType]

    local buildSiloBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
            this:_checkAndConfirm()
        end
    })
    buildSiloBtn:setAnchorPoint(0, 0)
    buildSiloBtn:setPosition(0, 0)
    UIExtend.setNodeVisible(buildSiloBtn, 'mHUDNameNode', true)
    self.mBuildSiloBtn = UIExtend.getCCControlButtonFromCCB(buildSiloBtn, 'mFunction')
    self.mBuildSiloBtn:setEnabled(true)
    table.insert(self.mBtnList, buildSiloBtn)

    local lang = RAWorldConfig.HudBtnLang[btnType]
    local sprite = RAWorldConfig.HudBtnImg[btnType]
    local btnStr = RAStringUtil:getLanguageString(lang)

    UIExtend.setCCLabelString(buildSiloBtn, 'mBtnName', btnStr)
    UIExtend.setSpriteIcoToNode(buildSiloBtn, 'mHUDIcon', sprite)

    UIExtend.addNodeToParentNode(ccbfile, 'mFunNode1', buildSiloBtn)
end

function RAWorldBuildSiloHelper:_addCancelBtn(ccbfile)
	local this = self
    local cancelBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
            this:StopBuildSilo()
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


function RAWorldBuildSiloHelper:_checkAndConfirm()
    -- 是否有阻挡区
    if self.mIsBlock then
        local RARootManager = RARequire('RARootManager')
        RARootManager.ShowMsgBox('@UnableToBuildSiloHere')
        return
    end

    -- 联盟积分消耗确认
    local RAAllianceManager = RARequire('RAAllianceManager')
    local allianceScore = RAAllianceManager.allianScore or 0
    local guild_const_conf = RARequire('guild_const_conf')
    local cost = guild_const_conf.platformBuildingCost.value
    
    if allianceScore < cost then
        local RARootManager = RARequire('RARootManager')
        RARootManager.ShowMsgBox('@LackAllianceContributionToBuildSilo')
        return
    end

    local this = self
    local needItemName = _RALang('@AllianceScoreName')
    local confirmData =
    {
        title = _RALang('@ConfirmBuildSiloTitle'),
        labelText = _RALang('@ConfirmBuildSiloMsg', needItemName, cost),
        yesNoBtn = true,
        resultFun = function (isOK)
            if isOK then
                this:_sendReq()
            end
        end
    }
    local RARootManager = RARequire('RARootManager')
    RARootManager.showConfirmMsg(confirmData)
end

function RAWorldBuildSiloHelper:_sendReq()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    local World_pb = RARequire('World_pb')
    RAWorldProtoHandler:sendBuildSiloReq(self.mTargetPos)
    self:StopBuildSilo()
end

return RAWorldBuildSiloHelper