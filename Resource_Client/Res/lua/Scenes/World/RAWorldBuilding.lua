--region *.lua
--Date
-- modify:
--      1.hgs@20160808 因层级遮挡问题，mMainNode不再添加到mRootNode

local RAWorldBuilding =
 {
    mRootNode       = nil,
    -- 主建筑
    mMainNode       = nil,
    -- 等级牌
    mLevelNode      = nil,
    -- 名字
    mNameNode       = nil,
    -- 保护罩
    mGuardNode      = nil,
    -- 资源占有标识
    mResFlagNode    = nil,
    mResFlagName    = nil,
    -- 联盟旗帜
    mGuildFlagNode  = nil,
    -- 雕像icon
    mStatueNode     = nil,
    -- 倒计时
    mCDEntity       = nil,
    -- 状态切换Action
    mStateAction    = nil,
    -- 着火
    mFireNode       = nil,
    -- 雷击
    mRayNode        = nil,
    -- 大总统名字
    mKingNameNode   = nil,
    -- 元帅战状态
    mKingTimerNode  = nil,
    -- 领地状态
    mTerriStateNode = nil,
    -- 防御建筑
    mFrontDefNode   = nil,
    mBackDefNode    = nil,

    mBuildingInfo   = {},

    mIsSpine        = false,
    mIsInProtect    = false,
    -- 是否在发射核弹
    mIsLaunching    = false,
    -- 是否受超级武器威胁
    mIsInDanger     = false,
    -- 是否有领地倒计时
    mHasTerrTimer   = false,
    -- 当前spine state
    mCurrState      = nil,

    mRef            = 1
}

local UIExtend = RARequire('UIExtend')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAGameConfig = RARequire('RAGameConfig')
local RAWorldMath = RARequire('RAWorldMath')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')
local const_conf = RARequire('const_conf')
local world_map_const_conf = RARequire('world_map_const_conf')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RABuildManager = RARequire('RABuildManager')
local BuildingCfg = RAWorldConfig.Building

local RAWorldBuildingInfo = RARequire('RAWorldBuildingInfo')

-- 资源标识对应关系
local ResFlag_Relation2Node =
{
    [World_pb.SELF]         = 'mMeIcon',
    [World_pb.GUILD_FRIEND] = 'mAllyIcon',
    [World_pb.ENEMY]        = 'mEnemyIcon'
}

local ZorderMap = RAWorldConfig.Building.Zorder

function RAWorldBuilding:new(pointInfo)
    local obj = {}

    setmetatable(obj, self)
    self.__index = self

    if not obj:_init(pointInfo) then
        obj = nil
    end

    return obj
end

function RAWorldBuilding:Execute()
    self:_updateCDEntity()
    self:_updatePresidentTimer()
    if self.mHasTerrTimer then
        self:_updateTerritoryStateNode()
    end
end

function RAWorldBuilding:_init(pointInfo)
    if not self:_initInfo(pointInfo) then return false end

    self.mRootNode = CCNode:create()
    if self.mRootNode == nil then return false end
    
    if tolua.type(self.mRootNode) ~= 'CCNode' then
    	assert(false, 'CCNode:create() return a ' .. tolua.type(self.mRootNode) .. ', Check basic.lua in "tools", or Report to RoyHu')
    	self.mRootNode = tolua.cast(self.mRootNode, 'CCNode')
    end
    self.mRootNode:setAnchorPoint(0.5, 0)

    self:_addMainNode()
    -- self:_addStateAction()
    self:_addGuardNode()
    self:_addNameNode()
    self:_addLevelNode()
    self:_addResFlagNode()
    self:_addGuildFlagNode()
    self:_addStatueNode()
    self:_addCDEntity()
    self:_addHurtEffect()

    if self.mBuildingInfo.type == World_pb.KING_PALACE then
        self:_addPresidentNameNode()
        self:_addPresidentTimer()
        self:_addPresidentGuardNode()
    elseif self.mBuildingInfo.type == World_pb.GUILD_TERRITORY then
        self:_addTerritoryStateNode()
    end

    local mapPos = RACcp(self.mBuildingInfo.coord.x, self.mBuildingInfo.coord.y)
    -- spine 以最下方为锚点，此处位置定在最下方的点
    mapPos.y = mapPos.y + (self.mBuildingInfo.gridCnt or 1)
    self:setPosition(RAWorldMath:Map2View(mapPos))

    CCCamera:setBillboard(self.mRootNode)

    return true
end

function RAWorldBuilding:_initInfo(pointInfo)
    local info = RAWorldBuildingInfo:new(pointInfo)
    if info then
        self.mBuildingInfo = info
        return true
    end

    return false
end

function RAWorldBuilding:Update(pointInfo)
    local info = RAWorldBuildingInfo:new(pointInfo)
    if info == nil then return end

    local guildIdChanged = false
    if info.guildId ~= self.mBuildingInfo.guildId then
        self.mBuildingInfo.guildId = info.guildId
        guildIdChanged = true
    end

    local isActiveChanged = info.isActive ~= self.mBuildingInfo.isActive
    if guildIdChanged
        or info.playerId ~= self.mBuildingInfo.playerId
        or isActiveChanged
    then
        self.mBuildingInfo.playerId = info.playerId
        self.mBuildingInfo.isActive = info.isActive
        self.mBuildingInfo.spine = info.spine
        self:UpdateRelationship()
    end

    if info.spine ~= self.mBuildingInfo.spine then
        self.mBuildingInfo.spine = info.spine
        self:_updateMainNode()
    end

    if info.state ~= self.mCurrState then
        if info.type == World_pb.PLAYER then
            -- 战败后破损状态保持（前端决定的）
            info.state = self.mCurrState
        else
            -- 发射井、天气控制室 展开状态：发射中要播放展开动画
            if info.state == BUILDING_ANIMATION_TYPE.READY_LAUNCH then
                info.state = BUILDING_ANIMATION_TYPE.START
            end
            self:runAction(info.state)
        end
    end

    if info.attackHurtEndTime ~= self.mBuildingInfo.attackHurtEndTime
        or info.weatherHurtEndTime ~= self.mBuildingInfo.weatherHurtEndTime
    then
        self.mBuildingInfo.attackHurtEndTime = info.attackHurtEndTime
        self.mBuildingInfo.weatherHurtEndTime = info.weatherHurtEndTime
        self:_updateHurtEffect()
    end

    if info.protectTime and info.protectTime ~= self.mBuildingInfo.protectTime then
        self.mBuildingInfo.protectTime = info.protectTime
        self:_updateGuard()
    end   

    if info.displayName ~= self.mBuildingInfo.displayName then
        self.mBuildingInfo.displayName = info.displayName
        self:_updateName()
    end

    if info.guildFlag ~= self.mBuildingInfo.guildFlag then
        self.mBuildingInfo.guildFlag = info.guildFlag
        self:_updateGuildFlag()
    end

    if info.cdTime ~= self.mBuildingInfo.cdTime then
        self.mBuildingInfo.cdTime = info.cdTime
        self:_updateCDEntity()
    end

    if info.level ~= self.mBuildingInfo.level then
        self.mBuildingInfo.level = info.level
        self:_updateLevel()
    end


    if self.mBuildingInfo.type == World_pb.KING_PALACE then
        local periodChanged = info.atPeace ~= self.mBuildingInfo.atPeace
        if periodChanged or info.presidentName ~= self.mBuildingInfo.presidentName then
            self.mBuildingInfo.atPeace = info.atPeace
            self.mBuildingInfo.presidentName = info.presidentName
            self:_updatePresidentNameNode(periodChanged)
        end

        if periodChanged 
            or info.presidentEndTime ~= self.mBuildingInfo.presidentEndTime
            or info.guildTag ~= self.mBuildingInfo.guildTag
        then
            self.mBuildingInfo.atPeace = info.atPeace
            self.mBuildingInfo.presidentEndTime = info.presidentEndTime
            self.mBuildingInfo.guildTag = info.guildTag
            self:_updatePresidentTimer(periodChanged)
            self:_updatePresidentGuardNode()
        end
    elseif self.mBuildingInfo.type == World_pb.GUILD_TERRITORY then
        if self.mBuildingInfo.territoryType == Const_pb.GUILD_BASTION then
            if guildIdChanged
                or isActiveChanged
                or self.mBuildingInfo.occupierId ~= info.occupierId
                or self.mBuildingInfo.occupierTag ~= info.occupierTag
                or self.mBuildingInfo.occupyTime ~= info.occupyTime
            then
                self.mBuildingInfo.occupierId = info.occupierId
                self.mBuildingInfo.occupierTag = info.occupierTag
                self.mBuildingInfo.occupyTime = info.occupyTime
                self:_updateTerritoryStateNode()
            end
        elseif self.mBuildingInfo.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
            if self.mBuildingInfo.buildStartTime ~= info.buildStartTime then
                self.mBuildingInfo.buildStartTime = info.buildStartTime
                self:_updateTerritoryStateNode()
            end
        end
    end

    self.mBuildingInfo = info
end

function RAWorldBuilding:UpdateRelationship()
    local relationship = self:GetRelation()
    if relationship ~= self.mBuildingInfo.relationship then
        self:_updateMainNode()
        self:_updateResFlag()
        self.mBuildingInfo.relationship = relationship
    end
end

function RAWorldBuilding:_addMainNode()
    local mainNode = nil
    
    local spineName = self.mBuildingInfo.spine
    if spineName then
        if RAGameConfig.test3d == nil or self.mBuildingInfo.type ~= World_pb.MONSTER then
            local relationship = self:GetRelation()
            mainNode = RAWorldUtil:AddSpine(spineName, relationship, self.mBuildingInfo.type)
            self.mIsSpine = true
        else
            local res = RAGameConfig.monsterRes or "3d/monster.c3b"
            local obj3d = CCEntity3D:create(res)
            obj3d:stopAllActions()
            obj3d:playAnimation("default",0,90,true)
            obj3d:setAlphaTestEnable(true)
            obj3d:setUseLight(true)
            obj3d:setAmbientLight(1,1,1)
            obj3d:setDirectionLightColor(1.0,1,1)
            obj3d:setDirectionLightDirection(1.0,-1.0,0)
            obj3d:setDiffuseIntensity(1)
            obj3d:setSpecularIntensity(1.0)
            obj3d:setScale(6)
            obj3d:setTag(10086)
            mainNode = obj3d
            obj3d:setRotation3D(Vec3(0,-30,0))
        end
    else
        local img = self.mBuildingInfo.img
        if img ~= nil then
            mainNode = CCSprite:create(img)
            mainNode:setAnchorPoint(0.5, 0)
        end
    end

    self.mMainNode = mainNode
    CCCamera:setBillboard(self.mMainNode)

    local state = self.mBuildingInfo.state or BUILDING_ANIMATION_TYPE.IDLE
    self:runAction(state)
end

function RAWorldBuilding:_addGuardNode()
    if self.mBuildingInfo.type ~= World_pb.PLAYER then return end

    local protectTime = self.mBuildingInfo.protectTime or 0
    protectTime = protectTime > 0 and (protectTime / 1000 - common:getCurTime()) or 0

    if protectTime > 0 then
        local guardNode = UIExtend.loadCCBFile('Ani_Map_Guard.ccbi', {})
        guardNode:setScale(BuildingCfg.Guard_Scale)
        self.mRootNode:addChild(guardNode, ZorderMap.GuardNode)

        self.mGuardNode = guardNode
        self.mIsInProtect = true

        self:_delayRemoveGuard(protectTime)
    end
end

function RAWorldBuilding:_addNameNode()
    local name = self.mBuildingInfo.displayName or ''
    if name ~= '' then
        local nameNode = UIExtend.loadCCBFile('RAHUDWorldName.ccbi', {})
        self.mNameNode = nameNode
        nameNode:setPosition(0, BuildingCfg.Name_OffsetY)
        UIExtend.setCCLabelString(nameNode, 'mName', name)
        UIExtend.setNodeVisible(nameNode, 'mAllianceIcon', false)
        UIExtend.setNodeVisible(nameNode, 'mStatueIcon', false)
        self.mRootNode:addChild(nameNode, ZorderMap.OtherNode)
    end
end

function RAWorldBuilding:_addLevelNode()
    local lvPos = self.mBuildingInfo.lvPos
    if lvPos then
        local lvNode = UIExtend.loadCCBFile('RAHUDWorldLevelNode.ccbi', {})
        self.mLevelNode = lvNode
        lvNode:setPosition(lvPos.x, lvPos.y)
        self.mRootNode:addChild(lvNode, ZorderMap.OtherNode)

        self:_updateLevel()
    end
end

-- 资源占领旗帜
function RAWorldBuilding:_addResFlagNode()
    if self.mBuildingInfo.type == World_pb.RESOURCE then
        local relationship = self:GetRelation()
        local flagName = ResFlag_Relation2Node[relationship]
        if flagName then
            local ccbfile = UIExtend.loadCCBFile('RAWorldCollectionFlag.ccbi', {})
            ccbfile:setPosition(0, RAWorldConfig.tileSize.height + 30) -- TODO
            local visibleMap = {}
            for k, v in pairs(ResFlag_Relation2Node) do
                visibleMap[v] = k == relationship
            end
            UIExtend.setNodesVisible(ccbfile, visibleMap)
            self.mRootNode:addChild(ccbfile, ZorderMap.OtherNode)
            self.mResFlagNode = ccbfile
            self.mResFlagName = flagName
        end
        return
    end
end

-- (城点、驻扎点、联盟领地建筑)联盟旗帜
function RAWorldBuilding:_addGuildFlagNode()
    if self.mBuildingInfo.type == World_pb.PLAYER 
        or self.mBuildingInfo.type == World_pb.RESOURCE
        or self.mBuildingInfo.type == World_pb.QUARTERED
        or self.mBuildingInfo.type == World_pb.GUILD_TERRITORY
        or self.mBuildingInfo.type == World_pb.KING_PALACE
    then
        local flagId = self.mBuildingInfo.guildFlag or 0
        local icon = RAAllianceUtility:getAllianceSmallFlag(flagId) or ''
        if icon == '' then return end

        if self.mNameNode == nil then
            self:_addNameNode()
        end

        self.mGuildFlagNode = UIExtend.getCCSpriteFromCCB(self.mNameNode, 'mAllianceIcon')
        self.mGuildFlagNode:setVisible(true)
        self.mGuildFlagNode:setTexture(icon)
    end
end

-- (雕像)雕像icon
function RAWorldBuilding:_addStatueNode()
    if self.mBuildingInfo.statueIcon and self.mStatueNode == nil then
        local icon = self.mBuildingInfo.statueIcon or ''
        if icon == '' then return end

        if self.mNameNode == nil then
            self:_addNameNode()
        end

        self.mStatueNode = UIExtend.getCCSpriteFromCCB(self.mNameNode, 'mStatueIcon')
        self.mStatueNode:setVisible(true)
        self.mStatueNode:setTexture(icon)
    end
end

-- (核弹发射井,天气控制室)倒计时
function RAWorldBuilding:_addCDEntity()
    if self.mBuildingInfo.type == World_pb.GUILD_TERRITORY then
        local cdTime = (self.mBuildingInfo.cdTime or 0) / 1000
        local currTime = common:getCurTime()
        if cdTime > currTime then
            local RABombEntityHelper = RARequire('RABombEntityHelper')
            local GuildManor_pb = RARequire('GuildManor_pb')
            local bombType = GuildManor_pb.NUCLRAR_WARHEAD
            if RAAllianceManager:getSelfSuperWeaponType() == Const_pb.GUILD_WEATHER then
                bombType = GuildManor_pb.WEATHER_STORM
            end
            self.mCDEntity = RABombEntityHelper:CreateCDEntity(bombType)
            local cdNode = self.mCDEntity:Load(1)
            self.mRootNode:addChild(cdNode, ZorderMap.CDNode)
            cdNode:setPosition(0, 200)
            self.mCDEntity:UpdateShowTime(cdTime - currTime)
            if self.mCurrState ~= BUILDING_ANIMATION_TYPE.READY_LAUNCH then
                self:runAction(BUILDING_ANIMATION_TYPE.START, 1)
            end
            RAWorldMath:CheckAndPlayVideo(self.mBuildingInfo.coord, 'bomb_ready')
            self.mIsLaunching = true
        end
    end
end

function RAWorldBuilding:_addStateAction()
    if self.mBuildingInfo.type ~= World_pb.PLAYER then return end

    local endTime = self.mBuildingInfo.hurtEndTime or 0
    endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0

    if endTime > 0 then
        self.mBuildingInfo.state = BUILDING_ANIMATION_TYPE.BROKEN_MAP
        self:runAction(self.mBuildingInfo.state)

        local this = self
        if self.mStateAction then
            self.mRootNode:stopAction(self.mStateAction)
        end
        self.mStateAction = performWithDelay(self.mRootNode, function ()
            this.mBuildingInfo.state = BUILDING_ANIMATION_TYPE.IDLE_MAP
            this:runAction(this.mBuildingInfo.state)
            this.mStateAction = nil
        end, endTime)
    end
end

function RAWorldBuilding:_addHurtEffect()
    local isTerritory = self:GetType() == World_pb.GUILD_TERRITORY
    local ccbfile, timeline = nil, nil

    local endTime = self.mBuildingInfo.attackHurtEndTime or 0
    if self.mFireNode == nil then
        endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0

        if endTime > 0 then
            ccbfile = isTerritory and 'Ani_Map_BuildFire_Alliance.ccbi' or 'Ani_Map_BuildFire_Public.ccbi'
            local fire = UIExtend.loadCCBFile(ccbfile, {})
            self.mFireNode = fire
            fire:setPosition(0, 0)
            self.mRootNode:addChild(fire, ZorderMap.OtherNode)
            fire:runAnimation(self.mBuildingInfo.spine)

            self:_delayRemoveFire(endTime)
        end
    end

    if self.mRayNode == nil then
        endTime = self.mBuildingInfo.weatherHurtEndTime or 0
        endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0
        
        if endTime > 0 then
            ccbfile = isTerritory and 'Ani_Map_BuildRay_Alliance.ccbi' or 'Ani_Map_BuildRay_Public.ccbi'
            local ray = UIExtend.loadCCBFile(ccbfile, {})
            self.mRayNode = ray
            ray:setPosition(0, 0)
            self.mMainNode:addChild(ray, ZorderMap.OtherNode)
            ray:runAnimation(self.mBuildingInfo.spine)

            self:_delayRemoveRay(endTime)
        end
    end
end

function RAWorldBuilding:_addPresidentNameNode()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.KING_PALACE then return end

    local name = info.presidentName or ''
    if name ~= '' then
        local nameNode = UIExtend.loadCCBFile('RAHUDPresidentName.ccbi', {})
        nameNode:setPosition(0, BuildingCfg.KingName_OffsetY)
        self.mRootNode:addChild(nameNode, ZorderMap.OtherNode)
        self.mKingNameNode = nameNode
        
        local nameStr = _RALang(info.atPeace and '@PresidentName_Hud' or '@TempPresidentName_Hud', name)
        UIExtend.setCCLabelString(nameNode, 'mName', nameStr)
        
        local icon = info:GetPresidentNameIcon()
        UIExtend.setSpriteImage(self.mKingNameNode, {mIconNode = icon})
    end
end

function RAWorldBuilding:_addPresidentTimer()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.KING_PALACE then return end

    local timerStr, progress = info:GetPresidentTimerStr()
    if timerStr ~= '' then
        local timerNode = UIExtend.loadCCBFile('RAHUDPresidentStateNode.ccbi', {})
        timerNode:setPosition(0, BuildingCfg.KingTimer_OffsetY)
        self.mRootNode:addChild(timerNode, ZorderMap.OtherNode)
        self.mKingTimerNode = timerNode

        UIExtend.setCCLabelString(timerNode, 'mTime', timerStr)
        UIExtend.setNodesVisible(timerNode, {
            mGreenBar   = info.atPeace,
            mRedBar     = not info.atPeace
        })
        
        local spriteName = info.atPeace and 'mGreenBar' or 'mRedBar'
        UIExtend.setCCScale9SpriteScale(timerNode, spriteName, 1 - progress, true)
        
        local icon = info:GetPresidentPeriodIcon()
        UIExtend.setSpriteImage(timerNode, {mHUDIcon = icon})
        
        timerNode:runAnimation('InAni')
    end
end

function RAWorldBuilding:_addPresidentGuardNode()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.KING_PALACE then return end

    if info.atPeace then
        local protectTime = self.mBuildingInfo.presidentEndTime or 0
        protectTime = protectTime > 0 and (protectTime / 1000 - common:getCurTime()) or 0

        if protectTime > 0 then
            local guardNode = UIExtend.loadCCBFile('Ani_Map_Guard.ccbi', {})
            guardNode:setScale(BuildingCfg.PresidentGuard_Scale)
            self.mRootNode:addChild(guardNode, ZorderMap.GuardNode)

            self.mGuardNode = guardNode
            self.mIsInProtect = true

            self:_delayRemoveGuard(protectTime)
        end
    end
end

function RAWorldBuilding:_addTerritoryStateNode()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.GUILD_TERRITORY then return end

    if info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
        self:_addBuildSiloTimer()
        return
    end

    if info.territoryType ~= Const_pb.GUILD_BASTION then return end

    if common:isEmptyStr(info.guildId) then return end

    local stateNode = UIExtend.loadCCBFile('RAHUDWorldStateNode.ccbi', {
        onRightIconBtn = function(self)
            -- TODO show rules
        end
    })
    self.mRootNode:addChild(stateNode, ZorderMap.OtherNode)
    stateNode:setPosition(0, info.gridCnt * RAWorldConfig.tileSize.height * 0.5)
    self.mTerriStateNode = stateNode
    
    local visibleMap =
    {
        mBarNode    = false,
        mOtherNode  = false
    }
    if info.occupierId and info.occupierId ~= '' then
        local timerStr, progress = info:GetBastionTimerStr()
        if timerStr ~= '' then
            visibleMap.mBarNode = true
            UIExtend.setCCLabelString(stateNode, 'mTime', timerStr)
            
            UIExtend.setCCScale9SpriteScale(stateNode, 'mRedBar', 1 - progress, true)
            
            -- local icon = info:GetPresidentPeriodIcon()
            -- UIExtend.setSpriteImage(stateNode, {mHUDIcon = icon})
            
            stateNode:runAnimation('InAni')
            self.mHasTerrTimer = true
        end
    else
        visibleMap.mOtherNode = true
        visibleMap.mAddPic = false
        local stateKey = info.isActive and '@TerritoryActive' or '@TerritoryUnactive'
        UIExtend.setCCLabelString(stateNode, 'mName', _RALang(stateKey))
    end
    UIExtend.setNodesVisible(stateNode, visibleMap)
end

function RAWorldBuilding:_addBuildSiloTimer()
    local info = self.mBuildingInfo
    local timerStr, progress = info:GetBuildSiloTimerStr()
    if timerStr ~= '' then
        local stateNode = UIExtend.loadCCBFile('RAHUDWorldStateNode.ccbi', {})
        self.mRootNode:addChild(stateNode, ZorderMap.OtherNode)
        stateNode:setPosition(0, info.gridCnt * RAWorldConfig.tileSize.height * 0.5)
        self.mTerriStateNode = stateNode
        
        UIExtend.setCCLabelString(stateNode, 'mTime', timerStr)
        UIExtend.setCCScale9SpriteScale(stateNode, 'mGreenBar', 1 - progress, true)
        
        -- local icon = info:GetPresidentPeriodIcon()
        -- UIExtend.setSpriteImage(stateNode, {mHUDIcon = icon})

        local visibleMap =
        {
            mBarNode    = true,
            mRedBar     = false,
            mOtherNode  = false
        }
        UIExtend.setNodesVisible(stateNode, visibleMap)
        
        stateNode:runAnimation('InAni')
        self.mHasTerrTimer = true
    end
end

function RAWorldBuilding:_delayRemoveGuard(delay)
    self.mGuardNode:stopAllActions()

    local this = self
    performWithDelay(this.mGuardNode, function ()
        UIExtend.releaseCCBFile(this.mGuardNode)
        this.mGuardNode = nil
        this.mIsInProtect = false
    end, delay)
end

function RAWorldBuilding:_delayRemoveFire(delay)
    self.mFireNode:stopAllActions()

    local this = self
    performWithDelay(this.mFireNode, function ()
        UIExtend.releaseCCBFile(this.mFireNode)
        this.mFireNode = nil
    end, delay)
end

function RAWorldBuilding:_delayRemoveRay(delay)
    self.mRayNode:stopAllActions()

    local this = self
    performWithDelay(this.mRayNode, function ()
        UIExtend.releaseCCBFile(this.mRayNode)
        this.mRayNode = nil
    end, delay)
end

function RAWorldBuilding:_updateGuard()
    local endTime = self.mBuildingInfo.protectTime or 0
    endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0

    if endTime > 0 then
        if self.mGuardNode then
            self:_delayRemoveGuard(endTime)
        else
            self:_addGuardNode()
        end
    elseif self.mGuardNode ~= nil then
        UIExtend.releaseCCBFile(self.mGuardNode)
        self.mGuardNode = nil
        self.mIsInProtect = false
    end
end

function RAWorldBuilding:_updateName()
    local nameTxt = self.mBuildingInfo.displayName or ''
    if self.mNameNode then
        if nameTxt ~= '' then
            UIExtend.setCCLabelString(self.mNameNode, 'mName', nameTxt)
        else
            UIExtend.releaseCCBFile(self.mNameNode)
            self.mNameNode = nil
        end
    elseif nameTxt ~= '' then
        self:_addNameNode()
    end
end

function RAWorldBuilding:_updateLevel()
    if self.mLevelNode then
        UIExtend.setCCLabelBMFontString(self.mLevelNode, 'mHUDLevel', self.mBuildingInfo.level or '')
    end
end

function RAWorldBuilding:_updateResFlag()
    if self.mBuildingInfo.type == World_pb.RESOURCE then
        local relationship = self:GetRelation()
        if relationship == World_pb.NONE then
            if self.mResFlagNode then
                UIExtend.releaseCCBFile(self.mResFlagNode)
                self.mResFlagNode = nil
                self.mResFlagName = nil
            end
        elseif self.mResFlagNode then
            UIExtend.setNodeVisible(self.mResFlagNode, self.mResFlagName, false)
            local flagName = ResFlag_Relation2Node[relationship]
            self.mResFlagName = flagName
            UIExtend.setNodeVisible(self.mResFlagNode, self.mResFlagName, true)
        else
            self:_addResFlagNode()
        end
    end
end

function RAWorldBuilding:_updateGuildFlag()
    if self.mBuildingInfo.type == World_pb.PLAYER
        or self.mBuildingInfo.type == World_pb.RESOURCE
        or self.mBuildingInfo.type == World_pb.QUARTERED
        or self.mBuildingInfo.type == World_pb.GUILD_TERRITORY
        or self.mBuildingInfo.type == World_pb.KING_PALACE
    then
        local flagId = self.mBuildingInfo.guildFlag or 0
        local icon = RAAllianceUtility:getAllianceSmallFlag(flagId) or ''
        if icon == '' then
            if self.mGuildFlagNode then
                self.mGuildFlagNode:setVisible(false)
                self.mGuildFlagNode = nil
            end
        elseif self.mGuildFlagNode then
            self.mGuildFlagNode:setTexture(icon)
        else
            self:_addGuildFlagNode()
        end
    end
end

function RAWorldBuilding:_updateMainNode()
    if self.mMainNode then
        if self.mIsSpine then
            self.mMainNode:stopAllAnimations()
            self.mCurrState = nil
        end
        self.mMainNode:stopAllActions()

        local parent = self.mMainNode:getParent()
        local x, y = self.mMainNode:getPosition()
        self.mMainNode:removeFromParentAndCleanup(true)
        self.mMainNode = nil
        
        self:_addMainNode()
        self.mMainNode:setPosition(x, y)
        parent:addChild(self.mMainNode, ZorderMap.MainNode)
    end
end

function RAWorldBuilding:_updateCDEntity()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.GUILD_TERRITORY then
        return
    end

    local cdTime = info.cdTime and (info.cdTime / 1000) or 0
    local currTime = common:getCurTime()
    if cdTime > currTime then
        if self.mCDEntity then
            self.mCDEntity:UpdateShowTime(cdTime - currTime)
        else
            self:_addCDEntity()
        end
        self.mIsLaunching = true
    elseif self.mCDEntity then
        if self.mIsLaunching and self.mCurrState == BUILDING_ANIMATION_TYPE.READY_LAUNCH then
            self:runAction(BUILDING_ANIMATION_TYPE.LAUNCH, 1)
            RAWorldMath:CheckAndPlayVideo(self.mBuildingInfo.coord, 'bomb_launch')
        else
            self:runAction(BUILDING_ANIMATION_TYPE.IDLE)
        end
        self:_releaseCDEntity()
    end
end

function RAWorldBuilding:_updateStateAction()
    if self.mBuildingInfo.type ~= World_pb.PLAYER then return end

    local endTime = self.mBuildingInfo.hurtEndTime or 0
    endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0

    if endTime > 0 then
        self:_addStateAction()
    elseif self.mStateAction then
        self.mRootNode:stopAction(self.mStateAction)
        self.mBuildingInfo.state = BUILDING_ANIMATION_TYPE.IDLE_MAP
        self:runAction(self.mBuildingInfo.state)
    end
end

function RAWorldBuilding:_updateHurtEffect()
    local toAdd = false

    local endTime = self.mBuildingInfo.attackHurtEndTime or 0
    endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0

    if endTime > 0 then
        if self.mFireNode then
            self:_delayRemoveFire(endTime)
        else
            toAdd = true
        end
    elseif self.mFireNode ~= nil then
        UIExtend.releaseCCBFile(self.mFireNode)
        self.mFireNode = nil
    end

    endTime = self.mBuildingInfo.weatherHurtEndTime or 0
    endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0
    if endTime > 0 then
        if self.mRayNode then
            self:_delayRemoveRay(endTime)
        else
            toAdd = true
        end
    elseif self.mRayNode ~= nil then
        UIExtend.releaseCCBFile(self.mRayNode)
        self.mRayNode = nil
    end

    if toAdd then
        local this = self
        performWithDelay(self.mMainNode, function()
            this:_addHurtEffect()
        end, RAWorldConfig.AddHurtEffectDelay)
    end
end

function RAWorldBuilding:_updatePresidentNameNode(isPeriodChanged)
    if self.mBuildingInfo.presidentName then
        if self.mKingNameNode then
            local key = self.mBuildingInfo.atPeace and '@PresidentName_Hud' or '@TempPresidentName_Hud'
            local nameStr = _RALang(key, self.mBuildingInfo.presidentName)
            UIExtend.setCCLabelString(self.mKingNameNode, 'mName', nameStr)
            if isPeriodChanged then
                local icon = self.mBuildingInfo:GetPresidentNameIcon()
                UIExtend.setSpriteImage(self.mKingNameNode, {mIconNode = icon})
            end
        else
            self:_addPresidentNameNode()
        end
    elseif self.mKingNameNode then
        UIExtend.releaseCCBFile(self.mKingNameNode)
        self.mKingNameNode = nil
    end
end

function RAWorldBuilding:_updatePresidentTimer(isPeriodChanged)
    local info = self.mBuildingInfo
    if info.type ~= World_pb.KING_PALACE then return end

    local timerStr, progress = info:GetPresidentTimerStr()
    if timerStr ~= '' then
        if self.mKingTimerNode then
            UIExtend.setCCLabelString(self.mKingTimerNode, 'mTime', timerStr)
            UIExtend.setNodesVisible(self.mKingTimerNode, {
                mGreenBar   = info.atPeace,
                mRedBar     = not info.atPeace
            })
            local spriteName = info.atPeace and 'mGreenBar' or 'mRedBar'
            UIExtend.setCCScale9SpriteScale(self.mKingTimerNode, spriteName, 1 - progress, true)
            if isPeriodChanged then
                local icon = info:GetPresidentPeriodIcon()
                UIExtend.setSpriteImage(self.mKingTimerNode, {mHUDIcon = icon})
            end
        else
            self:_addPresidentTimer()
        end
    elseif self.mKingTimerNode then
        UIExtend.releaseCCBFile(self.mKingTimerNode)
        self.mKingTimerNode = nil
    end
end

function RAWorldBuilding:_updatePresidentGuardNode()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.KING_PALACE then return end

    local endTime = 0
    if info.atPeace then
        endTime = self.mBuildingInfo.presidentEndTime or 0
        endTime = endTime > 0 and (endTime / 1000 - common:getCurTime()) or 0
    end

    if endTime > 0 then
        if self.mGuardNode then
            self:_delayRemoveGuard(endTime)
        else
            self:_addPresidentGuardNode()
        end
    elseif self.mGuardNode ~= nil then
        UIExtend.releaseCCBFile(self.mGuardNode)
        self.mGuardNode = nil
        self.mIsInProtect = false
    end
end

function RAWorldBuilding:_updateTerritoryStateNode()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.GUILD_TERRITORY then return end

    if info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
        self:_updateBuildSiloTimer()
        return
    end

    if info.territoryType ~= Const_pb.GUILD_BASTION then return end

    self.mHasTerrTimer = false

    if common:isEmptyStr(info.guildId) then
        if self.mTerriStateNode then
            UIExtend.releaseCCBFile(self.mTerriStateNode)
            self.mTerriStateNode = nil
        end
        return
    end

    if self.mTerriStateNode == nil then
        self:_addTerritoryStateNode()
        return
    end

    local visibleMap =
    {
        mBarNode    = false,
        mRedBar     = true,
        mOtherNode  = false
    }
    local stateNode = self.mTerriStateNode
    if info.occupierId and info.occupierId ~= '' then
        local timerStr, progress = info:GetBastionTimerStr()
        if timerStr ~= '' then
            visibleMap.mBarNode = true
            UIExtend.setCCLabelString(stateNode, 'mTime', timerStr)
            
            UIExtend.setCCScale9SpriteScale(stateNode, 'mRedBar', 1 - progress, true)
            
            -- local icon = info:GetPresidentPeriodIcon()
            -- UIExtend.setSpriteImage(stateNode, {mHUDIcon = icon})
            
            self.mHasTerrTimer = true
        end
    else
        visibleMap.mOtherNode = true
        visibleMap.mAddPic = false
        local stateKey = info.isActive and '@TerritoryActive' or '@TerritoryUnactive'
        UIExtend.setCCLabelString(stateNode, 'mName', _RALang(stateKey))
    end
    UIExtend.setNodesVisible(stateNode, visibleMap)
end

function RAWorldBuilding:_updateBuildSiloTimer()
    self.mHasTerrTimer = false

    local info = self.mBuildingInfo
    if common:isEmptyStr(info.guildId) then
        if self.mTerriStateNode then
            UIExtend.releaseCCBFile(self.mTerriStateNode)
            self.mTerriStateNode = nil
        end
        return
    end

    if self.mTerriStateNode == nil then
        self:_addTerritoryStateNode()
        return
    end

    local timerStr, progress = info:GetBuildSiloTimerStr()
    if timerStr ~= '' then
        local stateNode = self.mTerriStateNode
        UIExtend.setCCLabelString(stateNode, 'mTime', timerStr)
        
        UIExtend.setCCScale9SpriteScale(stateNode, 'mGreenBar', 1 - progress, true)
        
        -- local icon = info:GetPresidentPeriodIcon()
        -- UIExtend.setSpriteImage(stateNode, {mHUDIcon = icon})
        
        self.mHasTerrTimer = true
    elseif self.mTerriStateNode then
        UIExtend.releaseCCBFile(self.mTerriStateNode)
        self.mTerriStateNode = nil
    end
end

function RAWorldBuilding:AddFrontDefense(ccbiName, aniName, pos)
    if self.mFrontDefNode then
        UIExtend.releaseCCBFile(self.mFrontDefNode)
    end
    local frontNode = UIExtend.loadCCBFile(ccbiName, {})
    local parentNode = self.mIsSpine and self.mMainNode or self.mRootNode
    parentNode:addChild(frontNode, ZorderMap.FrontDefense)
    frontNode:runAnimation(aniName or self.mBuildingInfo.spine)
    self.mFrontDefNode = frontNode
    pos = pos or RACcp(0, 0)
    frontNode:setPosition(pos.x, pos.y)
end

function RAWorldBuilding:AddBackDefense(ccbiName, aniName, pos)
    if self.mBackDefNode then
        UIExtend.releaseCCBFile(self.mBackDefNode)
    end
    local backNode = UIExtend.loadCCBFile(ccbiName, {})
    local parentNode = self.mIsSpine and self.mMainNode or self.mRootNode
    parentNode:addChild(backNode, ZorderMap.BackDefense)
    backNode:runAnimation(aniName or self.mBuildingInfo.spine)
    self.mBackDefNode = backNode
    pos = pos or RACcp(0, 0)
    backNode:setPosition(pos.x, pos.y)
end

function RAWorldBuilding:RemoveDefense()
    UIExtend.releaseCCBFile(self.mFrontDefNode)
    UIExtend.releaseCCBFile(self.mBackDefNode)
    self.mFrontDefNode = nil
    self.mBackDefNode = nil
end

function RAWorldBuilding:_releaseCDEntity()
    if self.mCDEntity then
        self.mCDEntity:Unload()
        self.mCDEntity = nil
    end
    self.mIsLaunching = false
end

function RAWorldBuilding:AddRef()
    self.mRef = self.mRef + 1
end

function RAWorldBuilding:DecRef()
    self.mRef = self.mRef - 1
    return self.mRef
end

function RAWorldBuilding:GetRef()
    return self.mRef
end

function RAWorldBuilding:ResetRef()
    self.mRef = 1
end

function RAWorldBuilding:runAction(action, times)
	if action == nil then return end
    if self.mCurrState == action then return end
    if self.mMainNode == nil then return end

    times = times or -1
    
    if action == BUILDING_ANIMATION_TYPE.START then
        times = 1
    end

    if self.mBuildingInfo.spine and (RAGameConfig.test3d == nil or self.mBuildingInfo.type ~= World_pb.MONSTER) then
        if times == 1 then
            local this = self
            self.mMainNode:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
                if eventName == 'Start' then
                	if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
                        performWithDelay(this.mRootNode, function ()
                            this:setVisible(true)
                        end, 0.01)
                    end
                elseif eventName == 'Complete' then
                	if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
                        this:SetLevelSignVisible(true)
                        this:runAction(BUILDING_ANIMATION_TYPE.IDLE_MAP)
                    elseif animationName == BUILDING_ANIMATION_TYPE.START then
                    	this:runAction(BUILDING_ANIMATION_TYPE.READY_LAUNCH)
                    elseif animationName == BUILDING_ANIMATION_TYPE.LAUNCH then
                    	this:runAction(BUILDING_ANIMATION_TYPE.IDLE)
                    end
                    this.mMainNode:unregisterLuaListener()
                end
            end)
        end

        self.mMainNode:stopAllAnimations()
        self.mMainNode:runAnimation(0, action, times)
        self.mCurrState = action
    end
end

function RAWorldBuilding:addToParent(parentNode)
    if parentNode ~= nil and self.mRootNode ~= nil then
        if self.mMainNode then
            parentNode:addChild(self.mMainNode, ZorderMap.MainNode + self.mBuildingInfo.coord.y)
        end
        parentNode:addChild(self.mRootNode, ZorderMap.ContainerNode)
    end
end

function  RAWorldBuilding:removeFromParent()
    if self and not Utilitys.isNil(self.mMainNode) then
        self.mMainNode:removeFromParentAndCleanup(true)
    end
    if self and not Utilitys.isNil(self.mRootNode) then
        self.mRootNode:removeFromParentAndCleanup(true)
    end
end

function RAWorldBuilding:setPosition(position)
    if self.mRootNode then
        self.mRootNode:setPosition(position.x, position.y)
    end
    if self.mMainNode then
        self.mMainNode:setPosition(position.x, position.y)
    end
end

function RAWorldBuilding:getPosition()
    if self.mMainNode then
        return self.mMainNode:getPosition()
    end
    return 0, 0
end

function RAWorldBuilding:setVisible(visible)
    if self.mRootNode then
        self.mRootNode:setVisible(visible)
    end
    if self.mMainNode then
        self.mMainNode:setVisible(visible)
    end
end

-- 获取Hud按钮
function RAWorldBuilding:getBtnTypeTB()
    local info = self.mBuildingInfo
    return info and info:getBtnTypeTB() or {}
end

-- 获取显示hud时的音效
function RAWorldBuilding:GetHudEffect()
    local _type = self.mBuildingInfo.type
    if _type == World_pb.GUILD_TERRITORY then
        local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(self.mBuildingInfo.id)
        return cfg.hudSound or 'mapClick'
    end
    return 'mapClick'
end

-- 选中后闪烁
function RAWorldBuilding:Blink(color)
    if self.mIsInDanger then return end
    if not self.mIsSpine or not self.mMainNode then return end
    
    color = color or RAWorldConfig.BlinkColor.Shadow
    local tinto1 = CCTintTo:create(0.5, unpack(color))
    local tinto2 = CCTintTo:create(0.5, 255, 255, 255)
    local sequence = CCSequence:createWithTwoActions(tinto1, tinto2)
    local repeatForever = CCRepeatForever:create(sequence)
    self.mMainNode:runAction(repeatForever)
end

function RAWorldBuilding:StopBlink()
    if self.mIsInDanger then return end
    if not self.mIsSpine or not self.mMainNode then return end
    
    self.mMainNode:stopAllActions()
    self:SetColor(255, 255, 255)
end

function RAWorldBuilding:AddWarning()
    self:Blink(RAWorldConfig.BlinkColor.Warn)
    self.mIsInDanger = true
end

function RAWorldBuilding:StopWarning()
    self.mIsInDanger = false
    self:StopBlink()
end

function RAWorldBuilding:IsFearOfSuperWeapon(weaponType)
    if self.mIsInDanger then return false end
    return self.mBuildingInfo:IsFearOfSuperWeapon(weaponType)
end

function RAWorldBuilding:SetColor(r, g, b)
    if not self.mIsSpine or not self.mMainNode then return end

    local spineNode = tolua.cast(self.mMainNode, 'CCNodeRGBA')
    local color = ccc3(r, g, b)
    spineNode:setColor(color)
    color:delete()
    tolua.cast(self.mMainNode, 'SpineContainer')
end

-- 是否显示等级牌
function RAWorldBuilding:SetLevelSignVisible(visible)
    if self.mLevelNode then
        self.mLevelNode:setVisible(visible)
    end
end

-- 是否在保护状态
function RAWorldBuilding:IsInProtect()
    return self.mIsInProtect
end

-- 是否可以侦查
function RAWorldBuilding:IsAbleToSpy()
    -- 拥有科技：一级监测卫星
    local RAScienceManager=RARequire("RAScienceManager")
    return  RAScienceManager:isResearchFinish(530101)
end

-- 是否可采集
function RAWorldBuilding:IsAbleToCollect()
    local resType = self.mBuildingInfo.resType
    -- 钢铁与合金有等级限制
    if resType ~= Const_pb.STEEL and resType ~= Const_pb.TOMBARTHITE then return true end

    local cityLevel = RABuildManager:getMainCityLvl()
    local limitArr = RAStringUtil:split(world_map_const_conf.stepCityLevel2.value, '_') or {}
    local limit4Steel, limit4Tombarthite = tonumber(limitArr[1]) or 1, tonumber(limitArr[2]) or 1

    if resType == Const_pb.STEEL then
        return cityLevel >= limit4Steel, limit4Steel
    end

    return cityLevel >= limit4Tombarthite, limit4Tombarthite
end

-- 判断路点和自己的关系
function RAWorldBuilding:GetRelation()
    local info = self.mBuildingInfo
    return info and info:GetRelation() or World_pb.NONE
end

function RAWorldBuilding:GetType()
    return self.mBuildingInfo.type
end

function RAWorldBuilding:GetLevel()
    return self.mBuildingInfo.level or 1
end

function RAWorldBuilding:GetCoord()
    return self.mBuildingInfo.coord
end

function RAWorldBuilding:GetResDefenseOffset()
    local info = self.mBuildingInfo
    if info.type == World_pb.RESOURCE then
        return RAWorldConfigManager:GetResDefenseOffset(info.resType), info.resType
    end
end

-- @return {icon = '资源小角标', remain = '剩余资源量'}
function RAWorldBuilding:GetResInfoForHud()
    local info = self.mBuildingInfo
    if info and info.type == World_pb.RESOURCE then
        local RAResManager = RARequire('RAResManager')
        return {
            icon = RAResManager:getResourceIconByType(info.resType),
            remain = info.remainResNum
        }
    end

    return nil
end

-- 获取怪物的形态类型(生物/机械)
function RAWorldBuilding:GetMonsterShape()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.MONSTER then return nil end

    return RAWorldConfigManager:GetMonsterConfigAttr(info.id, 'MonsterShape') or 1
end


-- 获取怪物的类型
function RAWorldBuilding:GetMonsterType()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.MONSTER then return nil end

    return RAWorldConfigManager:GetMonsterConfigAttr(info.id, 'type') or 1
end

-- 怪物死亡音效
function RAWorldBuilding:GetMonsterExplodeEffect()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.MONSTER then return nil end

    return RAWorldConfigManager:GetMonsterConfigAttr(info.id, 'soundDeath')
end

-- 怪物攻击音效
function RAWorldBuilding:GetMonsterAttackEffect()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.MONSTER then return nil end

    return RAWorldConfigManager:GetMonsterConfigAttr(info.id, 'soundBattle')
end

-- 怪物点击音效
function RAWorldBuilding:GetMonsterClickEffect()
    local info = self.mBuildingInfo
    if info.type ~= World_pb.MONSTER then return nil end

    return RAWorldConfigManager:GetMonsterConfigAttr(info.id, 'soundClick')
end

function RAWorldBuilding:SetDecorationVisible(visible)
    local info = self.mBuildingInfo
    if visible == false
        and not common:table_contains(RAWorldConfig.CheckDecoTypeList, info.type) 
    then
        return false
    end

    local hasDeco = false
    
    local RAWorldMap = RARequire('RAWorldMap')
    local posTb = RAWorldMath:GetCoveredMapPos(info.coord, info.gridCnt)
    for _, pos in ipairs(posTb) do
        if RAWorldMap:SetDecorationVisible(pos, visible) then
            hasDeco = true
        end
    end

    return hasDeco
end

function RAWorldBuilding:Release()
    UIExtend.releaseCCBFile(self.mGuardNode)
    UIExtend.releaseCCBFile(self.mLevelNode)
    UIExtend.releaseCCBFile(self.mNameNode)
    UIExtend.releaseCCBFile(self.mResFlagNode)
    UIExtend.releaseCCBFile(self.mFireNode)
    UIExtend.releaseCCBFile(self.mRayNode)
    UIExtend.releaseCCBFile(self.mKingNameNode)
    UIExtend.releaseCCBFile(self.mKingTimerNode)
    UIExtend.releaseCCBFile(self.mTerriStateNode)
    self:RemoveDefense()
    self:_releaseCDEntity()
    self:removeFromParent()
end

return RAWorldBuilding

--endregion