--region *.lua
--Date

local RAWorldManager = 
{
    targetPos = nil,
    twoLevelMapStaus={true,false,false} --联盟成员 领地 资源带
}

local PointType =
{
    Capital     = 1,
    Self        = 2,
    GuildLeader = 3,
    GuildMember = 4,
    GuildCastle = 5,
    CurPositon  = 6,
    ResZone     = 7
}

local RAStringUtil = RARequire('RAStringUtil')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldVar = RARequire('RAWorldVar')
local RAWorldUtil = RARequire('RAWorldUtil')
local Utilitys = RARequire('Utilitys')
local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
local RAWorldUIManager = RARequire('RAWorldUIManager')
local RAWorldMistManager = RARequire('RAWorldMistManager')
local RARootManager = RARequire('RARootManager')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAGuideManager = RARequire('RAGuideManager')

function RAWorldManager:SearchCoordinate()
    local coord =
    {
        k = RAWorldVar.KingdomId.Map,
        x = RAWorldVar.MapPos.Map.x, 
        y = RAWorldVar.MapPos.Map.y
    }
    RARootManager.OpenPage('RAWorldSearchPage', coord, false, true, false)
end

function RAWorldManager:LocateHome()
    local selfPos = RAWorldVar.MapPos.Self
    self:LocateAt(selfPos.x, selfPos.y, RAWorldVar.KingdomId.Self)
end

-- 跳转到总统府（默认当前服）
function RAWorldManager:LocateCapital(k)
    local targetPos = RAWorldVar.MapPos.Core
    self:LocateAtPos(targetPos.x, targetPos.y, k)
end

-- 跳转到（自己服）总统府
function RAWorldManager:LocateAtSelfCapital()
    local targetPos = RAWorldVar.MapPos.Core
    self:LocateAt(targetPos.x, targetPos.y)
end

-- 跳转到任意服(默认本服)
function RAWorldManager:LocateAt(x, y, k, showHud, noClear)
    k = k or RAWorldVar.KingdomId.Self
    self:LocateAtPos(x, y, k, showHud, noClear)
end

-- 跳转到指定坐标并应用HudBtn
function RAWorldManager:LocateAtWithHudApply(x, y, k, hudBtn)
    k = k or RAWorldVar.KingdomId.Self
    self:LocateAtPos(x, y, k, false, nil, hudBtn)
end

-- 跳转到任意服(默认当前服)
function RAWorldManager:LocateAtPos(x, y, k, showHud, noClear, hudBtn)
    -- eg: 迁城过程中不清理
    if not noClear then
        RAWorldUIManager:Clear()
    end

    local mapPos = RACcp(x, y)
    k = k or RAWorldVar.KingdomId.Map
    local isInWorld = RARootManager:GetIsInWorld()

    if isInWorld then
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        
        local isToSelfServer = RAWorldUtil.kingdomId.isSelf(k)

        -- 跨服：清理
        if k ~= RAWorldVar.KingdomId.Map then
            self:reset4CrossingServer()
            
            --离开自己的服
            if RAWorldVar:IsInSelfKingdom() then
                RAWorldProtoHandler:sendLeaveSignal()
            -- 离开别人的服并进入自己的服
            else
                if isToSelfServer then
                    RAWorldProtoHandler:sendEnterSignal(mapPos)
                    self:reset4BackSelfServer()
                end
                local RAPresidentDataManager = RARequire('RAPresidentDataManager')
                RAPresidentDataManager:ClearCrossServerInfo(RAWorldVar.KingdomId.Map)
            end
            MessageManager.sendMessage(MessageDef_World.MSG_Territory_Update)
            RAWorldVar:UpdateMapKingdomId(k)
            RAWorldBuildingManager:AddCapital()
        end
        
        if not isToSelfServer then
            RAWorldProtoHandler:sendFetchPointsReq(mapPos, k)
            RAWorldProtoHandler:sendFetchPresidentInfoReq(k)
        end
    end

    RAWorldVar:UpdateMapKingdomId(k)
    RAWorldVar.HudPos = nil

    if not isInWorld then
        local RAScenesMananger = RARequire('RAScenesMananger')
        RAScenesMananger.AddWorldLocateCmdByXY(mapPos.x, mapPos.y, hudBtn)

        RARootManager.ChangeScene(SceneTypeList.WorldScene)
    else
        local isInView = not RAWorldBuildingManager:IsOutOfView(mapPos)

        local RAWorldScene = RARequire('RAWorldScene')
        RAWorldScene:GotoTileAtPoint(mapPos)
        
        if showHud and isInView then
            RAWorldUIManager:ShowHud(mapPos, true)
            return
        end

        if hudBtn then
            local RAWorldHudManager = RARequire('RAWorldHudManager')
            RAWorldHudManager:TriggerHudBtn(mapPos, hudBtn)
            return
        end
    end

    if showHud then
        RAWorldVar.HudPos = mapPos
    end
end

-- 指定坐标建造发射平台
function RAWorldManager:BuildSiloAt(x, y)
    local RAAllianceManager = RARequire('RAAllianceManager')
    local weaponType = RAAllianceManager:getSelfSuperWeaponType()
    local btnType = RAWorldConfig.WeaponBuildSiloHud[weaponType]
    if x == nil or y == nil then
        if RARootManager:GetIsInWorld() and RAWorldVar:IsInSelfKingdom() then
            x, y = RACcpUnpack(RAWorldVar.MapPos.Map)
        else
            x, y = RACcpUnpack(RAWorldVar.MapPos.Self)
        end
    end
    self:LocateAtWithHudApply(x, y, nil, btnType)
end

-- 指定坐标发射超级武器
function RAWorldManager:LaunchBombAt(x, y)
    local RAAllianceManager = RARequire('RAAllianceManager')
    local weaponType = RAAllianceManager:getSelfSuperWeaponType()
    local btnType = RAWorldConfig.WeaponLaunchHud[weaponType]
    self:LocateAtWithHudApply(x, y, nil, btnType)
end

function RAWorldManager:LocateAtBuilding(_type, _level, _subType)
    if RARootManager.GetIsInWorld() then
        RARootManager.OpenPage("RASearchPage", {selectType = _type, level = _level, subType = _subType}, true, true, true)
    else
        local param = {}
        param.pages = {{pageName = 'RASearchPage', pageArg = {selectType = _type, level = _level, subType = _subType},  isUpdate = true, needNotToucherLayer = true, isBlankClose = true}}
        RARootManager.ChangeScene(SceneTypeList.WorldScene, false, param)
    end
end

-- 打开小地图
function RAWorldManager:OpenMiniMap()
    -- RARootManager.OpenPage('RAWorldMiniMap')
    RARootManager.OpenPage('RAWorldNewMinMap', nil,true,true)
end

function RAWorldManager:FadeIn()
    local RAWorldScene = RARequire('RAWorldScene')
    local RAWorldMap = RARequire('RAWorldMap')

    RAWorldScene:SetTouchEnabled(false)
    RAWorldScene:SetScale(RAWorldConfig.MapScale_Fade)
    local scaleAction = CCScaleTo:create(1.0, RAWorldConfig.MapScale_Def)

    local viewPos = RAWorldMath:Map2View(RAWorldVar.MapPos.Map)
    local targetPos = RAWorldMath:GetCenterPosition(viewPos, RAWorldConfig.MapScale_Def)

    local moveAction = CCMoveTo:create(1.0, ccp(targetPos.x, targetPos.y))

    local this = self
    local callback = CCCallFunc:create(function ()
        RAWorldScene:SetScale(RAWorldConfig.MapScale_Def)
        RAWorldScene:SetTouchEnabled(true)
        RAWorldVar.AllowServerReq = true
        

        local targetInfo, targetPos = RAWorldVar.TargetInfo, nil
        if targetInfo ~= nil then
            targetPos = RAWorldBuildingManager:FindBuilding(targetInfo.taskType, targetInfo.targetLevel or 1, targetInfo.targetType)
            RAWorldVar.TargetInfo = nil
            MessageManager.sendMessage(MessageDef_Guide.MSG_TaskGuideWorld, {found = targetPos ~= nil})
        end
        if targetPos ~= nil then
            this:LocateAtPos(targetPos.x, targetPos.y)
        else
            RAWorldMap:Relocate()
        end
    end)

    RAWorldScene.MapNode:runAction(CCEaseExponentialOut:create(moveAction))
    RAWorldScene.RootNode:runAction(CCSequence:createWithTwoActions(CCEaseExponentialOut:create(scaleAction), callback))

    performWithDelay(RAWorldScene.RootNode, function ()
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendEnterSignal(RAWorldVar.MapPos.Map)
    end, 0.2)
end

function RAWorldManager:FadeOut()
    local RAWorldScene = RARequire('RAWorldScene')

    if not RAGuideManager.isInGuide() then
        RAWorldScene:SetScale(RAWorldConfig.MapScale_Def)
    end

    if RAWorldScene:GetScale() == RAWorldConfig.MapScale_Fade then return end

    if RAWorldScene.MapNode then
	    local scaleAction = CCScaleTo:create(1.0, RAWorldConfig.MapScale_Fade)

	    local viewPos = RAWorldMath:Map2View(RAWorldVar.MapPos.Map)
	    local targetPos = RAWorldMath:GetCenterPosition(viewPos, RAWorldConfig.MapScale_Fade)

	    local moveAction = CCMoveTo:create(1.0, ccp(targetPos.x, targetPos.y))

	    local callback = CCCallFunc:create(function ()
	        if RARootManager.GetIsInWorld() then
	            RAWorldScene:SetScale(RAWorldConfig.MapScale_Fade)
	            RAWorldManager:LocateHome()
	        end
	    end)

	    RAWorldScene.MapNode:runAction(CCEaseSineIn:create(moveAction))
	    RAWorldScene.RootNode:runAction(CCSequence:createWithTwoActions(CCEaseSineIn:create(scaleAction), callback))
	end

    local RAWorldMap = RARequire('RAWorldMap')
    RAWorldVar.AllowServerReq = false
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    RAWorldProtoHandler:sendLeaveSignal()
end

function RAWorldManager:RandomMigrate()
    local World_pb = RARequire('World_pb')
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    RAWorldProtoHandler:sendMigrateReq(nil, World_pb.RANDOM_MOVE)
end

function RAWorldManager:onMigrateRsp(isOK, migratePos, hasTip)
    RARootManager.CloseAllPages()
    if RARootManager.GetIsInWorld() then
        if isOK and RAWorldVar.MapPos.Migrate == nil then
            self:LocateAt(migratePos.x, migratePos.y, nil, nil, true)
        end
        RAWorldUIManager:OnMigrateRsp(isOK, migratePos, hasTip)
    else
        if isOK then
            -- RAWorldVar:UpdateSelfPos(migratePos)
            RARootManager.ChangeScene(SceneTypeList.WorldScene)
        end
    end
end

-- @return name, icon
function RAWorldManager:GetTileDetail(mapPos)
    if RARootManager.GetIsInWorld() then
        local RAWorldMap = RARequire('RAWorldMap')
        local name = RAWorldMap:GetTileName(mapPos)
        local icon = nil
        if name then
            icon = RAWorldConfig.EmptyTileIcon[name]
            name = _RALang(name)
        end
        return name, icon
    end
    return nil, nil
end

function RAWorldManager:GetTerritoryId(mapPos)
    if RARootManager.GetIsInWorld() then
        local RAWorldMap = RARequire('RAWorldMap')
        return RAWorldMap:GetTerritoryId(mapPos)
    end
    return 0
end

-- 是否有领地在视野范围内
function RAWorldManager:GetTerritoryIdInView(mapPos)
    local id = self:GetTerritoryId(mapPos)
    if id > 0 then return id end

    local radius = RAWorldConfig.CheckMist_Radius
    for i = -1, 1, 1 do
        for j = -1, 1, 1 do
            if i ~= 0 or j ~= 0 then
                local pos = RACcpAdd(mapPos, RACcpMultCcp(radius, RACcp(i, j)))
                id = self:GetTerritoryId(pos)
                if id > 0 then return id end
            end
        end
    end

    return 0
end

-- 是否在别人的领地内
function RAWorldManager:IsInTerritoryOfEnemy(mapPos)
    local territoryId = RAWorldManager:GetTerritoryId(mapPos) or 0
    if territoryId < 1 then
        return false
    end
    
    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    local guildId = RATerritoryDataManager:GetGuildId(territoryId)

    local World_pb = RARequire('World_pb')
    return RAWorldUtil:GetTerritoryRelationship(guildId) == World_pb.ENEMY
end

function RAWorldManager:updateDirection()
    local RAWorldScene = RARequire('RAWorldScene')
    local viewPos = RAWorldMath:GetViewPos(RAWorldVar.ViewPos.Center)
    local offsetX = RAWorldVar.ViewPos.Self.x - viewPos.x
    local offsetY = RAWorldVar.ViewPos.Self.y - viewPos.y

    local distance = Utilitys.getDistance(RAWorldVar.MapPos.Map, RAWorldVar.MapPos.Self)
    local degree = Utilitys.getDegree(offsetX, offsetY)
    local hideArrow = not RAWorldMath:IsMyCityOutOfView(RAWorldVar.MapPos.Map, RAWorldVar.MapPos.Self)
    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateWorldDirection, {distance = math.floor(distance), degree = degree, hideArrow = hideArrow})
end

function RAWorldManager:IsBlock(mapPos, targetInfo)
    if RAWorldBuildingManager:IsBlock(mapPos) then return true end

    -- 边界限制
    if not RAWorldMath:IsValidMapPos(RACcp(mapPos.x - 4, mapPos.y), true)
        or not RAWorldMath:IsValidMapPos(RACcp(mapPos.x + 4, mapPos.y), true)
        or not RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y - 4), true)
        or not RAWorldMath:IsValidMapPos(RACcp(mapPos.x, mapPos.y + 4), true)
    then
        return true
    end

    if targetInfo and targetInfo.isBuildingSilo then
        -- 建筑超级武器发射平台： 1.不能在黑土地内 2.不能在别人的领地内
        if RAWorldUtil:IsInBankArea(mapPos) then
            return true
        end

        if self:IsInTerritoryOfEnemy(mapPos) then
            return true
        end
    end

    -- 是否是阻挡点
    local RAWorldMap = RARequire('RAWorldMap')
    if RAWorldMap:IsBlock(mapPos) then
        return true
    end

    -- 是否在迷雾内
    return RAWorldMistManager:IsInMist(mapPos)
end

function RAWorldManager:Clear()
    -- RAWorldVar:resetVersion()
end

-- 重连服务器之后清理
function RAWorldManager:reset()
    --所有行军数据和显示移除
    local RAMarchManager = RARequire('RAMarchManager')
    RAMarchManager:Clear()
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    RAMarchDataManager:reset()

    --TODO:
    --所有核弹数据和显示移除 
    

    RAWorldVar:Clear()
    local RABattleManager = RARequire('RABattleManager')
    RABattleManager:Clear()
    local RAUserFavoriteManager = RARequire('RAUserFavoriteManager')
    RAUserFavoriteManager:ResetData()
    RAWorldMistManager:Clear()

    self:resetTwoLevelMapStatus()
end

-- 跨服清理
function RAWorldManager:reset4CrossingServer()
    --行军广播移除；所有行军显示移除
    local RAMarchManager = RARequire('RAMarchManager')
    RAMarchManager:ClearMarches()
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    RAMarchDataManager:resetForCrossServer()  

    --TODO:
    --核弹显示移除 

    RAWorldVar:Clear()
    RAWorldBuildingManager:ResetData()
    RAWorldUIManager:Clear()
    local RABattleManager = RARequire('RABattleManager')
    RABattleManager:Clear()
    -- local RAUserFavoriteManager = RARequire('RAUserFavoriteManager')
    -- RAUserFavoriteManager:ResetData()
    RAWorldMistManager:Clear()
end

-- 从其它服返回自己的服
function RAWorldManager:reset4BackSelfServer()
    --行军重新显示
    local RAMarchManager = RARequire('RAMarchManager')
    RAMarchManager:ShowSelfMarches()

    --TODO:
    --核弹重新显示
end

--twoLevelMapStaus={true,false,false} --联盟成员 领地 资源带
function RAWorldManager:setTwoLevelMapStatu(posType,isShow)
    if posType==nil then return end

    if posType==PointType.GuildMember or posType==PointType.GuildLeader then
        self.twoLevelMapStaus[1]=isShow
    elseif posType==PointType.GuildCastle then
        self.twoLevelMapStaus[2]=isShow
    elseif posType==PointType.ResZone then
        self.twoLevelMapStaus[3]=isShow
    end
end

function RAWorldManager:getTwoLevelMapStatu(posType)
    if posType==nil then return end

    if posType==PointType.GuildMember or posType==PointType.GuildLeader then
        return self.twoLevelMapStaus[1]
    elseif posType==PointType.GuildCastle then
        return self.twoLevelMapStaus[2]
    elseif posType==PointType.ResZone then
        return  self.twoLevelMapStaus[3]
    end
end

function RAWorldManager:resetTwoLevelMapStatus()
    self.twoLevelMapStaus={true,false,false}
end

return RAWorldManager
--endregion
