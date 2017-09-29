local RAWorldTargetHelper =
{
	mRootNode = nil,
	mMainNode = nil,
	mAniNode = nil,
    mHudNode = nil,
	mTargetBtn = nil,
    mWeaponType = nil,

	mIsTargeting = false,
	mIsBlock = false,
	-- 当前瞄准的中心点坐标
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

local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldMath = RARequire('RAWorldMath')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAWorldVar = RARequire('RAWorldVar')
local BtnType = RAWorldConfig.HudBtnType
local RAAllianceManager = nil

function RAWorldTargetHelper:Init(rootNode)
	self.mRootNode = rootNode
end

function RAWorldTargetHelper:Clear()
	self:StopTarget()
    self.mWeaponType = nil
	self.mTargetPos = nil
    self.mTouchNodes = {}
end

-- 是否在瞄准
function RAWorldTargetHelper:IsTargeting()
	return self.mIsTargeting
end

function RAWorldTargetHelper:IsOnTouch(touchPos, touch)
    if self.mTargetPos == nil then return false end

    local RALogicUtil = RARequire('RALogicUtil')
    for _, touchNode in ipairs(self.mTouchNodes) do
        if RALogicUtil:isTouchInside(touchNode, touch) then
            return true
        end
    end

    return false
end

function RAWorldTargetHelper:BeginTarget(mapPos)
    if RAAllianceManager == nil then
        RAAllianceManager = RARequire('RAAllianceManager')
    end
    local weaponType = RAAllianceManager:getSelfSuperWeaponType()
    if weaponType == nil then return end

    self.mWeaponType = weaponType
    self.mTargetPos = mapPos
    self:_addMainNode()
    self:_addTargetNode()
    self:_addHud()
    self:_addBorder()

    -- if self.mTargetBtn then
    --     self.mTargetBtn:setEnabled(not self.mIsBlock)
    -- end

    self.mIsTargeting = true
end

function RAWorldTargetHelper:Targeting(offset)
    if self.mIsTargeting == false then return end

    local posX, posY = self.mMainNode:getPosition()
    posX, posY = posX + offset.x, posY + offset.y

    local tileWidth, tileHeight = RAWorldConfig.tileSize.width, RAWorldConfig.tileSize.height

    
    local RAWorldMap = RARequire('RAWorldMap')
    local scale = RAWorldMap.scale
    
    -- judge whether need to update map
    local centerPos = RAWorldMath:GetViewPos(RAWorldVar.ViewPos.Center)
    local viewX, viewY = posX - centerPos.x, posY - centerPos.y
    local mapOffset = {x = 0, y = 0}
    local winSize = CCDirector:sharedDirector():getWinSize()
    local halfWinWidth, halfWinHeight = winSize.width / scale * 0.5, winSize.height / scale * 0.5

    -- left
    if viewX < 0 and offset.x < 0 and (viewX - tileWidth) <= -halfWinWidth then
        local dx = (tileWidth - viewX - halfWinWidth) + tileWidth * 0.25
        mapOffset.x = -offset.x + dx
        posX = posX - dx
    -- right
    elseif viewX > 0 and offset.x > 0 and (viewX + tileWidth) >= halfWinWidth then
        local dx = (halfWinWidth - (viewX + tileWidth)) - tileWidth * 0.25
        mapOffset.x = -offset.x + dx
        posX = posX - dx
    end

    -- 屏幕主UI菜单区高度 (加上hud按钮高度)
    local bGap, tGap = RAWorldConfig.Height.MainUIBottomBanner + 140 / scale, 0
    -- bottom
    if viewY < 0 and offset.y < 0 and (viewY - tileHeight * 2) <= -(halfWinHeight - bGap) then
        local dy = (tileHeight * 2 - viewY - (halfWinHeight - bGap)) + tileHeight * 0.25
        mapOffset.y = -offset.y + dy
        posY = posY - dy
    -- top
    elseif viewY > 0 and offset.y > 0 and (viewY + tileHeight * 2) >= (halfWinHeight - tGap) then
        local dy = (halfWinHeight - tGap - (viewY + tileHeight * 2)) - tileHeight * 0.25
        mapOffset.y = -offset.y + dy
        posY = posY - dy
    end

    
    if mapOffset.x ~= 0 or mapOffset.y ~= 0 then
        RAWorldMap:OffsetMap(mapOffset)
        local RAWorldScene = RARequire('RAWorldScene')
        RAWorldScene:ShowPosition()
    end

    local viewPos = RACcp(posX, posY)
    local mapPos = RAWorldMath:View2Map(viewPos)

    if RAAllianceManager == nil then
        RAAllianceManager = RARequire('RAAllianceManager')
    end
    if RAAllianceManager:IsInSiloRange(mapPos, viewPos)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x - 3, mapPos.y), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x + 3, mapPos.y), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y - 3), true)
        and RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y + 3), true)
    then
        self.mMainNode:setPosition(posX, posY)
        if not RACcpEqual(self.mTargetPos, mapPos) then
            self.mTargetPos = mapPos
            local msg = {pos = self.mTargetPos, weaponType = self.mWeaponType}
            MessageManager.sendMessage(MessageDef_World.MSG_SuperWeapon_Aiming, msg)
        end
    end
end

function RAWorldTargetHelper:StopTarget()
    self:_removeBorder()

    for _, btn in ipairs(self.mBtnList) do
        if btn then
            UIExtend.releaseCCBFile(btn)
        end
    end
    self.mBtnList = {}

    UIExtend.releaseCCBFile(self.mTargetNode)
    self.mTargetNode = nil

    UIExtend.releaseCCBFile(self.mHudNode)
    self.mHudNode = nil

	if self.mMainNode then
		self.mMainNode:removeFromParentAndCleanup(true)
	end
	self.mMainNode = nil

	self.mTargetBtn = nil

	self.mIsTargeting = false
	self.mIsBlock = false
	self.mTileCoords = {}

    if self.mTargetPos then
        MessageManager.sendMessage(MessageDef_World.MSG_SuperWeapon_AimEnd)
        self.mTargetPos = nil
    end
end

function RAWorldTargetHelper:OnTargetRsp(isOK)
	RARootManager.RemoveWaitingPage()
	self:StopTarget()
end

function RAWorldTargetHelper:_isOnTileBg(mapPos)
    for _, pos in ipairs(self.mTileCoords) do
        if RACcpEqual(mapPos, pos) then return true end
    end
    return false
end

function RAWorldTargetHelper:_addMainNode()
    local migrateNode = CCNode:create()
    
    local pos = RAWorldMath:Map2View(self.mTargetPos)
    migrateNode:setPosition(pos.x, pos.y)
    
    self.mRootNode:addChild(migrateNode)

    self.mMainNode = migrateNode
end

function RAWorldTargetHelper:_addTargetNode()
    local ccb = RAWorldConfig.WeaponAimCCB[self.mWeaponType]
    local targetNode = UIExtend.loadCCBFile(ccb, {})

    self.mMainNode:addChild(targetNode)
    targetNode:runAnimation('Selecting')
    self.mTargetNode = targetNode

    table.insert(self.mTouchNodes, (targetNode:getCCNodeFromCCB('mTouchNode')))

    local msg = {pos = self.mTargetPos, weaponType = self.mWeaponType}
    MessageManager.sendMessage(MessageDef_World.MSG_SuperWeapon_Aiming, msg)
end

function RAWorldTargetHelper:_addHud()
    local hudNode = UIExtend.loadCCBFile('RAHUDWorldNode.ccbi', {})
    
    UIExtend.setNodeVisible(hudNode, 'mHUDTitleNode', false)
    hudNode:setPosition(0, -RAWorldConfig.halfTile.height * 4)
    
    self.mMainNode:addChild(hudNode)
    self.mHudNode = hudNode

    self:_addTargetBtn(hudNode)
    self:_addCancelBtn(hudNode)

    CCCamera:setBillboard(hudNode)
    hudNode:runAnimation('FunAni2')

    table.insert(self.mTouchNodes, (hudNode:getCCNodeFromCCB('mTouchNode')))
end

function RAWorldTargetHelper:_addTargetBtn(ccbfile)
	local this = self
    local sendReq = function (isOK)
        if not isOK then return end

        this.mTargetNode:runAnimation('Selected')
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendLaunchBombReq(this.mTargetPos)
        RARootManager.ShowWaitingPage(true)
        --this:StopTarget()
    end

    local migrateBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
            sendReq(true)
        end
    })
    migrateBtn:setAnchorPoint(0, 0)
    migrateBtn:setPosition(0, 0)
    UIExtend.setNodeVisible(migrateBtn, 'mHUDNameNode', true)
    self.mTargetBtn = UIExtend.getCCControlButtonFromCCB(migrateBtn, 'mFunction')
    self.mTargetBtn:setEnabled(true)
    table.insert(self.mBtnList, migrateBtn)

    local btnType = RAWorldConfig.WeaponLaunchHud[self.mWeaponType]
    if btnType == nil then return end

    local lang = RAWorldConfig.HudBtnLang[btnType]
    local sprite = RAWorldConfig.HudBtnImg[btnType]
    local btnStr = RAStringUtil:getLanguageString(lang)

    UIExtend.setCCLabelString(migrateBtn, 'mBtnName', btnStr)
    UIExtend.setSpriteIcoToNode(migrateBtn, 'mHUDIcon', sprite)

    UIExtend.addNodeToParentNode(ccbfile, 'mFunNode1', migrateBtn)
end

function RAWorldTargetHelper:_addCancelBtn(ccbfile)
	local this = self
    local cancelBtn = UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', {
        onFunciton = function (self, args)
            this:StopTarget()
        end
    })
    cancelBtn:setAnchorPoint(0, 0)
    cancelBtn:setPosition(0, 0)
    UIExtend.setNodeVisible(cancelBtn, 'mHUDNameNode', true)
    UIExtend.setCCControlButtonEnable(cancelBtn, 'mFunction', true)
    table.insert(self.mBtnList, cancelBtn)

    local lang = RAWorldConfig.HudBtnLang[BtnType.CancelLaunch]
    local sprite = RAWorldConfig.HudBtnImg[BtnType.CancelLaunch]
    local btnStr = RAStringUtil:getLanguageString(lang)

    UIExtend.setCCLabelString(cancelBtn, 'mBtnName', btnStr)
    UIExtend.setSpriteIcoToNode(cancelBtn, 'mHUDIcon', sprite)

    UIExtend.addNodeToParentNode(ccbfile, 'mFunNode2', cancelBtn)
end

function RAWorldTargetHelper:_addBorder()
    local siloPos = RAAllianceManager:GetSiloPosition()
    local radius = RAAllianceManager:GetSiloLaunchRadius()
    local bombRadius = RAWorldConfig.BombEffect_Radius.x

    local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
    RAWorldBuildingManager:AddBorder(siloPos, radius + bombRadius)
    -- RAWorldBuildingManager:AddBorder(siloPos, radius)
end

function RAWorldTargetHelper:_removeBorder()
    local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
    RAWorldBuildingManager:RemoveBorder()
end

return RAWorldTargetHelper