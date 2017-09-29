--region *.lua
--Date

local RAWorldHudManager = {
    mRootNode = nil,

    hudNode = nil,
    blinkNode = nil,
    buildingNode = nil,

    marchId = nil,
    movingMarchHud = false,
    hudMapPos = {},
    hudPos = nil    -- 行军hud当前位置
}

local UIExtend = RARequire('UIExtend')
local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
local RARootManager = RARequire('RARootManager')
local RAMarchManager = RARequire('RAMarchManager')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local RAWorldMistManager = RARequire('RAWorldMistManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAGameConfig = RARequire('RAGameConfig')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local HudBtnType = RAWorldConfig.HudBtnType

function RAWorldHudManager:Init(rootNode)
    self.mRootNode = rootNode
end

function RAWorldHudManager:Execute()
    if (not self.movingMarchHud ) and (self.hudNode == nil) then return end

    self:_updateMarchHud()

    -- 暂时不需要: 更新资源量
    -- if self.buildingNode then
    --     local info = self.buildingNode.buildingInfo
    --     if info.type == World_pb.RESOURCE then
    --         self.hudNode:UpdateResource(info.remainResNum)
    --     end
    -- end
end

function RAWorldHudManager:ShowHud(mapPos)
    local hasHud = false
    if self.hudNode then
        self:RemoveHud()
        hasHud = true
    end

    self.buildingNode = nil

    -- 迷雾中不可点击
    if RAWorldMistManager:IsInMist(mapPos) then return end

    local buildingId, buildingNode = RAWorldBuildingManager:GetBuildingAt(mapPos)

    if hasHud and buildingNode == nil then return end

    local gridCnt = buildingNode and buildingNode.mBuildingInfo.gridCnt or 1
    local resInfo = nil

    local centerPos = mapPos
    local btnTypeTB = {}
    local clickEffect = nil
    if buildingNode then
        -- 野怪不弹hud，直接弹页面
        local info = buildingNode.mBuildingInfo
        if info.type == World_pb.MONSTER then
            
            if info.ownerId ~= nil and not RARequire('RAPlayerInfoManager').isSelf(info.ownerId) then
                return
            end

            local pageData =
            {
                monsId = info.id, 
                remainBlood = info.remainBlood,
                posX = info.coord.x,
                posY = info.coord.y,
                name = info.name,
                icon = info.icon,
                maxBlood = info.maxBlood
            }
            common:playEffect(buildingNode:GetMonsterClickEffect())
            RARootManager.OpenPage('RAWorldMonsterNewPage', pageData, false, true, true)
            --RARootManager.RemoveGuidePage()--移除guidepage

            return
        end

        if gridCnt > 1 then
            centerPos = RAWorldMath:GetMapPosFromId(buildingId)
        end
        btnTypeTB = buildingNode:getBtnTypeTB()
        self.buildingNode = buildingNode
        
        resInfo = buildingNode:GetResInfoForHud()
        clickEffect = buildingNode:GetHudEffect()
    else
        -- 空地
        local RAWorldManager = RARequire('RAWorldManager')
        local World_pb = RARequire('World_pb')
        local name, icon = RAWorldManager:GetTileDetail(centerPos)
        self.buildingNode = {
            mBuildingInfo = {
                coord = {x= centerPos.x, y = centerPos.y, k = RAWorldVar.KingdomId.Map},
                name = name,
                icon = icon,
                type = World_pb.EMPTY,
                id = RAWorldMath:GetMapPosId(centerPos)
            }
        }
        btnTypeTB = self:_getHudBtnTB_Empty(centerPos)
    end

	common:playEffect(clickEffect or 'mapClick')

    if RAWorldVar:IsInSelfKingdom() then
        if RAAllianceManager:IsAbleToLaunchSuperWeapon(mapPos) then
            local weaponType = RAAllianceManager:getSelfSuperWeaponType()
            if weaponType == Const_pb.GUILD_SILO then
                table.insert(btnTypeTB, HudBtnType.LaunchBomb)
            elseif weaponType == Const_pb.GUILD_WEATHER then
                table.insert(btnTypeTB, HudBtnType.LaunchWeather)
            end
        end
    end

    if #btnTypeTB < 1 then return end

    if buildingNode then
        buildingNode:Blink()
    end

    local tileSize = RAWorldConfig.tileSize
    local nodeSize = CCSizeMake(tileSize.width * gridCnt, tileSize.height * gridCnt)

    local ccbiName = RAWorldConfig.ChooseCcbi[gridCnt]
    local blinkNode = UIExtend.loadCCBFile(ccbiName, {})
    local blinkPos = RAWorldMath:Map2View(centerPos)
    blinkNode:setPosition(blinkPos.x, blinkPos.y + 12 * gridCnt)
    self.mRootNode:addChild(blinkNode)
    self.blinkNode = blinkNode

    CCCamera:setBillboard(blinkNode)

    local hudPanel = RARequire('RAWorldHud')
    hudPanel:Init(btnTypeTB, {x = centerPos.x, y = centerPos.y}, self, nodeSize, resInfo)
    hudPanel:addToParent(self.mRootNode)
    local hudPos = RAWorldMath:Map2View(RACcpAdd(centerPos, {y = gridCnt}))
    hudPanel:setPosition(hudPos.x, hudPos.y)
    self.hudNode = hudPanel

    hudPanel:SetBillboard()

    self.hudMapPos = centerPos
end

function RAWorldHudManager:RemoveHud(mapPos)
    if mapPos and not RACcpEqual(mapPos, self.hudMapPos) then return end

    if self.hudNode then
        self.hudNode:Release()
        self.hudNode = nil
    end

    if self.blinkNode then
        UIExtend.releaseCCBFile(self.blinkNode)
        self.blinkNode = nil
    end

    if self.buildingNode then
        if self.buildingNode.StopBlink then
            self.buildingNode:StopBlink()
        end
        self.buildingNode = nil
    end

    self.movingMarchHud = false
    self.marchId = nil
    self.hudMapPos = nil
end

-- 添加行军Hud
function RAWorldHudManager:AddMarchHud(marchId, parent)
    if marchId == nil or parent == nil then return end

    self:RemoveHud()

    local marchData = RAMarchDataManager:GetMarchDataById(marchId)
    if marchData == nil then return end

    local hudPos = RAMarchManager:GetMarchMoveEntityViewPos(marchId)
    if hudPos.x < 0 and hudPos.y < 0 then
        return
    end
    
    local RAWorldScene = RARequire('RAWorldScene')
    RAWorldScene:GotoViewAt(hudPos)

    local btnTypeTB = {}

    if marchData.relation == World_pb.SELF then
        local marchType = marchData.marchType
        -- 侦查、资源援助 没有'部队'
        if marchType ~= World_pb.SPY
            and marchType ~= World_pb.ASSISTANCE_RES
        then
            table.insert(btnTypeTB, HudBtnType.MarchArmyDetail)
        end

        table.insert(btnTypeTB, HudBtnType.MarchSpeedUp)

        -- 出征(集结除外)才有'撤军'
        if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH
            and not RAWorldUtil:IsMassingMarch(marchType)
        then
            table.insert(btnTypeTB, HudBtnType.MarchRecall)
        end
    elseif marchData.relation == World_pb.GUILD_FRIEND then
        if RAWorldUtil:IsMassingMarch(marchData.marchType) then
            local isJoin = RAMarchDataManager:CheckIsJoinInOneMarch(marchData)
            if isJoin then
                table.insert(btnTypeTB, HudBtnType.MarchArmyDetail)
                table.insert(btnTypeTB, HudBtnType.MarchSpeedUp)
            end
        end 
    end

    local hudPanel = RARequire('RAWorldHud')
    hudPanel:InitMarchHud(btnTypeTB, marchId, self)
    hudPanel:addToParent(parent)
    hudPanel:setPosition(0, 0)
    --新手期出征打怪发送加速按钮的信息：add by xinghui
    --而且只有玩家具有加速道具，才会走这里
    local RAGuideManager = RARequire("RAGuideManager")
    local RAGuideConfig = RARequire("RAGuideConfig")
    local keyWord = RAGuideManager.getKeyWordById()
    if keyWord == RAGuideConfig.KeyWordArray.CircleMarchAcc then
        local canSendMarch = false

        local RACoreDataManager = RARequire("RACoreDataManager")
        local accLowCount = RACoreDataManager:getItemCountByItemId(Const_pb.ITEM_WORLD_MARCH_SPEEDUPL)
        local accHighCount = RACoreDataManager:getItemCountByItemId(Const_pb.ITEM_WORLD_MARCH_SPEEDUPH)
        if (accLowCount + accHighCount > 0) then
            canSendMarch = true
            performWithDelay(self.mRootNode, function()
                --hudPanel:_sendGuideMarchMsg()
                RAGuideManager.gotoNextStep()--这里本来是圈住出征hud的加速按钮的，因为hud正常情况下处于屏幕中间，但是当小怪处于地图边缘的时候，hud会进行移动，就圈不准确了
            end, 1)
        end

        if not canSendMarch then
            RAGuideManager.gotoNextStep2()--如果不存在圈住加速hud的条件，那么为了衔接，处理一下
        end
    end
    

    self.movingMarchHud = true
    self.marchId = marchId
    self.hudNode = hudPanel
    self.hudPos = RACcp(hudPos.x, hudPos.y)

    self:_updateMarchHud()
end

function RAWorldHudManager:AddMarchHudWithoutNode(marchId)
    local RAMarchManager = RARequire('RAMarchManager')
    local hudPos = RAMarchManager:GetMarchMoveEntityViewPos(marchId)
    if hudPos.x < 0 and hudPos.y < 0 then
        return
    end

    local y = hudPos.y - RAWorldConfig.winCenter.y * RAWorldConfig.Height.MarchUseItemPage
    y = y - RAWorldConfig.Height.MainUITopBanner
    local RAWorldScene = RARequire('RAWorldScene')
    RAWorldScene:GotoViewAt(RACcp(hudPos.x, y))

    self.movingMarchHud = true
    self.marchId = marchId
    self.hudPos = hudPos
end

function RAWorldHudManager:ShowMarchHudNode()
    if self.movingMarchHud and self.hudNode == nil then
        local marchId = self.marchId
        self:RemoveHud()
        if marchId then
            local RAMarchManager = RARequire('RAMarchManager')
            RAMarchManager:ShowMarchHud(marchId)
        end
    end
end

function RAWorldHudManager:RemoveMarchHud(marchId)
    if self.marchId and self.marchId == marchId then
        self:RemoveHud()
    end
    --出征行军结束，需要处理
    local RAGuideManager = RARequire("RAGuideManager")
    local RAGuideConfig = RARequire("RAGuideConfig")
    if RAGuideManager.isInGuide() then
        local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
        --如果当前步骤正在圈住加速hud
        if keyWord == RAGuideConfig.KeyWordArray.CircleMarchAcc or keyWord == RAGuideConfig.KeyWordArray.CircleAccToolUseBtn then
            RAGuideManager.gotoNextStep2()
        end
    end
end

function RAWorldHudManager:onHudFunction(btnType)
    local info = self.buildingNode and self.buildingNode.mBuildingInfo or {}
    local HudBtnType = RAWorldConfig.HudBtnType
    
    local World_pb = RARequire('World_pb')
    -- 收藏
    if btnType == HudBtnType.AddFavorite then
        local targetType = RAWorldUtil:GetFavoriteType(info)
        RARootManager.OpenPage('RAAddFavoritePage', {coord = info.coord, name = info.name, icon = info.icon, targetType = targetType}, false, true, false)
    -- 迁城
    elseif btnType == HudBtnType.Migrate then
    	common:playEffect('mapClickDetermine')
        local RAWorldUIManager = RARequire('RAWorldUIManager')
        RAWorldUIManager:doMigrate(self.hudMapPos)
    -- 建造超级武器发射平台
    elseif btnType == HudBtnType.BuildNuclearSilo 
        or btnType == HudBtnType.BuildWeatherSilo
    then
        local RAWorldUIManager = RARequire('RAWorldUIManager')
        RAWorldUIManager:doBuildSilo(self.hudMapPos)
    -- 进入基地
    elseif btnType == HudBtnType.EnterCity then
        RARootManager.ChangeScene(SceneTypeList.CityScene)
    -- 基地增益
    elseif btnType == HudBtnType.CityGain then
         RARootManager.OpenPage('RACityGainPage')
    -- 攻击
    elseif btnType == HudBtnType.Attack then
    	common:playEffect('mapClickDetermine')
        local this = self
        -- 攻打城点
        if info.type == World_pb.PLAYER then
            if self.buildingNode:IsInProtect() then
                RARootManager.ShowMsgBox('@TargetIsInProtect')
            else
                local confirmFunc = function ()
                    this:_chargeTroop(info, World_pb.ATTACK_PLAYER)
                end
                RAWorldUtil:ActAfterConfirm(confirmFunc)
            end
        -- 采集资源
        elseif info.type == World_pb.RESOURCE then
            self:_collectResource()
        -- 打怪
        elseif info.type == World_pb.MONSTER then
            local pageData = {
                    monsId = info.id, 
                    remainBlood = info.remainBlood,
                    posX = info.coord.x,
                    posY = info.coord.y,
                    name = info.name,
                    icon = info.icon,
                    maxBlood = info.maxBlood
                }
            RARootManager.OpenPage('RAWorldMonsterNewPage', pageData, false, true, true)
        -- 驻扎
        elseif info.type == World_pb.QUARTERED then
            local confirmFunc = function ()
                this:_chargeTroop(info, World_pb.ARMY_QUARTERED)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        -- 攻打联盟据点和堡垒
        elseif info.type == World_pb.GUILD_GUARD or info.type == World_pb.GUILD_TERRITORY then
            local confirmFunc = function ()
                this:_chargeTroop(info, World_pb.MANOR_SINGLE)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        -- 攻打元帅府
        elseif info.type == World_pb.KING_PALACE then
            if not RAAllianceManager:IsInGuild() then
                RARootManager.ShowMsgBox('@PlzJoinAllianceToRunForPresident')
                return
            end

            local confirmFunc = function ()
                this:_chargeTroop(info, World_pb.PRESIDENT_SINGLE)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        end
    -- 说明
    elseif btnType == HudBtnType.Explain then
        --资源详情
        if info.type == World_pb.RESOURCE then
            --需要根据relation去判断打开哪个UI
            local relation = self.buildingNode:GetRelation()
            local resId = info.id
            local remainResNum = info.remainResNum
            local resX = info.coord.x
            local resY = info.coord.y
            local playerName = info.playerName
            local pageData = {
                    resId = resId, 
                    relation = relation,
                    remainResNum = remainResNum,
                    posX = resX,
                    posY = resY,
                    playerName = playerName
                }
            if relation == World_pb.SELF then
                local marchId = info.marchId
                pageData.marchId = marchId
                RARootManager.OpenPage('RAWorldMyCollectionPage', pageData, true, true, true)
            else
                RARootManager.OpenPage('RAWorldCollectionPage', pageData, false, true, true)
            end
        -- 打怪
        elseif info.type == World_pb.MONSTER then
            
        -- 驻扎
        elseif info.type == World_pb.QUARTERED then
            
        end
    elseif btnType == HudBtnType.GeneralDetail then
        local relation = self.buildingNode:GetRelation()
        if relation == World_pb.SELF then
            RARootManager.OpenPage('RALordMainPage')
        else
            RARootManager.OpenPage('RAGeneralInfoPage', {playerId = info.playerId})
        end
    -- 侦查
    elseif btnType == HudBtnType.Spy then
        if not self.buildingNode:IsAbleToSpy() then
            RARootManager.ShowMsgBox('@NeedRadarToSpy')
            return
        end

        if info.type == World_pb.KING_PALACE then
            if not RAAllianceManager:IsInGuild() then
                RARootManager.ShowMsgBox('@PlzJoinAllianceToRunForPresident')
                return
            end
        end

        local confirmFunc = function()
            local resX = info.coord.x
            local resY = info.coord.y
            local playerName = info.playerName
            local icon = info.playerIcon

            if info.type == World_pb.PLAYER 
                or info.type == World_pb.GUILD_GUARD
                or info.type == World_pb.GUILD_TERRITORY
                or info.type == World_pb.KING_PALACE
            then
               icon = info.icon 
               playerName = info.name
            end

            local pageData = 
            {
                posX = resX,
                posY = resY,
                playerName = playerName,
                icon = icon
            }            
            RARootManager.OpenPage('RAWorldDetectPage', pageData, false, true, true)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)
    elseif btnType == HudBtnType.Occupy then
    	common:playEffect('mapClickDetermine')
        -- 驻扎
        if info.type == World_pb.EMPTY then
            self:_chargeTroop(info, World_pb.ARMY_QUARTERED)
        end
    -- 行军部队
    elseif btnType == HudBtnType.ArmyDetail then
        RARootManager.OpenPage('RAWorldArmyDetailsPage', {marchId = info.marchId}, false, true, true)
    -- 部队详情
    elseif btnType == HudBtnType.MarchArmyDetail then
        RARootManager.OpenPage('RAWorldArmyDetailsPage', {marchId = self.marchId}, false, true, true)
    -- 行军加速
    elseif btnType == HudBtnType.MarchSpeedUp then        
        local RACommonGainItemData = RARequire('RACommonGainItemData')
        RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate, self.marchId)
    -- 行军召回
    elseif btnType == HudBtnType.MarchRecall then
        local RACommonGainItemData = RARequire('RACommonGainItemData')
        RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.marchCallBack, self.marchId)
    -- 召回
    elseif btnType == HudBtnType.Recall then
        local marchId = info.marchId        
        -- 驻扎召回
        if info.type == World_pb.QUARTERED then
            local RAWorldPushHandler = RARequire('RAWorldPushHandler')
            RAWorldPushHandler:sendServerCalcCallBackReq(marchId)

        -- 采集召回
        elseif info.type == World_pb.RESOURCE then
            
            local relation = self.buildingNode:GetRelation()
            
            if relation == World_pb.SELF then
                local pageData = {
                        resId = info.id, 
                        relation = relation,
                        remainResNum = info.remainResNum,
                        posX = info.coord.x,
                        posY = info.coord.y,
                        playerName = info.playerName
                    }
                pageData.marchId = marchId
                RARootManager.OpenPage('RAWorldCollectionBackPage', pageData, false, true, true)
            end
        elseif info.type == World_pb.GUILD_TERRITORY then
            -- 堡垒召回
            if info.territoryType == Const_pb.GUILD_BASTION
            	or info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING
            then
                local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')                
                RAWorldProtoHandler:sendRecallPointMarchReq(info.coord)
            -- 超级矿召回
            elseif info.territoryType == Const_pb.GUILD_MINE then
                local RAMarchDataManager = RARequire('RAMarchDataManager')
                local isSelfIn, selfMarchId = RAMarchDataManager:CheckSelfSuperMineCollectStatus(true)
                if isSelfIn then
                    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
                    local selfName = RAPlayerInfoManager.getPlayerName()
                    local pageData = {
                            resId = 0, 
                            relation = World_pb.GUILD_FRIEND,
                            remainResNum = -1,
                            posX = info.coord.x,
                            posY = info.coord.y,
                            playerName = selfName,
                            isManorCollect = true,
                            guildMineType = info.mineType,  --新增资源类型
                        }
                    pageData.marchId = selfMarchId
                    RARootManager.OpenPage('RAWorldCollectionBackPage', pageData, false, true, true)
                else
                    --无法召回
                    local Status_pb = RARequire("Status_pb")
                    RARootManager.showErrorCode(Status_pb.WORLD_POINT_WITHOUT_ARMY)
                end
            end
        elseif info.type == World_pb.PLAYER then
            -- 士兵援助召回
            local confirmData =
            {
                labelText = _RALang('@ConfirmSendbackTroops'),
                yesNoBtn = true,
                resultFun = function (isOK)
                    if isOK then
                        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
                        RAWorldProtoHandler:sendRecallPointMarchReq(info.coord)
                    end
                end
            }
            RARootManager.showConfirmMsg(confirmData)
        end
    -- 总统府召回
    elseif btnType == HudBtnType.Recall_President then
        local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
        local isCallBack, marchId = RAPresidentMarchDataHelper:CheckSelfIsLeader()
        if not isCallBack then
            isCallBack, marchId = RAPresidentMarchDataHelper:CheckSelfIsQuartering()
        end
        if isCallBack and marchId ~= '' then
            local confirmData =
            {
                labelText = _RALang('@ConfirmSendbackTroops'),
                yesNoBtn = true,
                resultFun = function (isOK)
                    if isOK then
                        local RAWorldPushHandler = RARequire('RAWorldPushHandler')
                        --召回
                        RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
                    end
                end
            }
            RARootManager.showConfirmMsg(confirmData)
        end
    -- 士兵援助
    elseif btnType == HudBtnType.SoldierAid then
        local pageData = {
                posX = info.coord.x,
                posY = info.coord.y,
                name = info.name,
                icon = info.icon,
                playerId = info.playerId
            }
        RARootManager.OpenPage('RAAllianceSoldierAidPage', pageData, false, true, true)
    -- 资源援助
    elseif btnType == HudBtnType.ResourceAid then
        local targetPos={x=info.coord.x,y=info.coord.y}
        local targetLevel=info.level

        local pageData={endPos=targetPos,level=targetLevel}
        RARootManager.OpenPage('RAWorldResourceAidPage', pageData, false, true, true)
    -- 宣战
    elseif btnType == HudBtnType.DeclareWar then
        -- 联盟据点和堡垒的集结，行军类型不一样
        local gatherMarchType = World_pb.MASS
        if info.type == World_pb.GUILD_GUARD or info.type == World_pb.GUILD_TERRITORY then
            gatherMarchType = World_pb.MANOR_MASS
        elseif info.type == World_pb.KING_PALACE then
            if not RAAllianceManager:IsInGuild() then
                RARootManager.ShowMsgBox('@PlzJoinAllianceToRunForPresident')
                return
            end
            
            gatherMarchType = World_pb.PRESIDENT_MASS
        end
           
        if info.type == World_pb.PLAYER and self.buildingNode:IsInProtect() then
            RARootManager.ShowMsgBox('@TargetIsInProtect')
        else
            local this = self
            local confirmFunc = function ()
                local pageData = 
                {
                    posX = info.coord.x,
                    posY = info.coord.y,
                    name = info.name,
                    icon = info.icon,
                    marchType = gatherMarchType
                }
                RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        end
    elseif btnType == HudBtnType.TerritoryList then
        RARootManager.OpenPage('RAAllianceBaseWarPage', {terrBuildingId = info.id})
    -- 查看详情
    elseif btnType == HudBtnType.ViewDetail then
        if info.type == World_pb.GUILD_TERRITORY then
            if info.territoryType == Const_pb.GUILD_BASTION then
                local ownerName = nil
                if info.guildId and info.guildId ~= '' then
                    ownerName = info.guildTag
                end

                local pageData =
                {
                    territoryId     = info.territoryId,
                    attackTimes     = info.attackTimes,
                    isBastion       = true,
                    ownerName       = ownerName,
                    occupierName    = common:isEmptyStr(info.occupierId) and ownerName or info.occupierName
                }
                RARootManager.OpenPage('RAStrongholdInfoPage', pageData, false, true, true)

            -- 查看超级武器发射平台
            elseif info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
                local ownerName = nil
                if info.guildId and info.guildId ~= '' then
                    ownerName = info.guildTag
                end
                local pageData =
                {
                    id              = info.id,
                    coord           = info.coord,
                    territoryId     = info.territoryId,
                    territoryType   = info.territoryType,
                    buildStartTime  = info.buildStartTime,
                    ownerName       = ownerName,
                    isBastion       = false
                }
                RARootManager.OpenPage('RAStrongholdInfoPage', pageData, true, true, true)
            -- 查看联盟超级矿
            elseif info.territoryType == Const_pb.GUILD_MINE then
            	local pageData =
                {
                    pointX = info.coord.x,
                    pointY = info.coord.y,
                    guildMineType = info.mineType,
                }
                RARootManager.OpenPage('RAAllianceSuperMinePage', pageData, false, true, true)
            -- 查看联盟医院
            elseif info.territoryType == Const_pb.GUILD_HOSPITAL then
                local pageData =
                {
                    pointX = info.coord.x,
                    pointY = info.coord.y,
                    manorId = info.territoryId,
                    buildId = info.id,
                    buildType = info.territoryType
                }
                RARootManager.OpenPage('RAAlliancePassivePage', pageData, false, true, true)
            -- 查看联盟巨炮
            elseif info.territoryType == Const_pb.GUILD_CANNON then
                local pageData =
                {
                    pointX = info.coord.x,
                    pointY = info.coord.y,
                    manorId = info.territoryId,
                    buildId = info.id,
                    buildType = info.territoryType
                }
                RARootManager.OpenPage('RAAlliancePassivePage', pageData, false, true, true)            
            end
        end
    elseif btnType == HudBtnType.ViewOwnership then
        -- 总统府详情
        if info.type == World_pb.KING_PALACE then
            RARootManager.OpenPage('RAPresidentPalacePage', {}, true)
        elseif info.territoryType == Const_pb.GUILD_SILO
            or info.territoryType == Const_pb.GUILD_WEATHER
            or info.territoryType == Const_pb.GUILD_URANIUM
            or info.territoryType == Const_pb.GUILD_ELECTRIC
        then
            RAAllianceManager:showSolePage()
        -- 查看发射平台
        elseif info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
            RARootManager.OpenPage('RAAllianceSiloPlatformPage', nil, true, true, true)            
        -- 查看联盟商店
        elseif info.territoryType == Const_pb.GUILD_SHOP then
            RARootManager.OpenPage('RAAllianceShopPage')
        -- 查看联盟雕像
        elseif info.territoryType == Const_pb.GUILD_STATUE then
            local RAWorldConfigManager = RARequire('RAWorldConfigManager')
            local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(info.id)
            if cfg.jumpInterface then
                RARootManager.OpenPage('RAAllianceStatueInfoPage',{isWorld = true,statueIndex = cfg.jumpInterface},false,true,true)
            end
        end
    -- 发射核弹,雷电风暴
    elseif btnType == HudBtnType.LaunchBomb
        or btnType == HudBtnType.LaunchWeather
    then
        local RAWorldUIManager = RARequire('RAWorldUIManager')
        RAWorldUIManager:doTarget(self.hudMapPos)
    -- 查看据点详情
    elseif btnType == HudBtnType.StrongholdDetail then
        local pageData =
        {
            id              = info.id,
            territoryId     = info.territoryId,
            attackTimes     = info.attackTimes,
            isBastion       = false
        }
        RARootManager.OpenPage('RAStrongholdInfoPage', pageData, false, true, true)

    -- 单人收复（其实是攻打）
    elseif btnType == HudBtnType.Reoccupy then
    	-- self:_chargeTroop(targetInfo, World_pb.MANOR_ASSISTANCE)
        local this = self
        local confirmFunc = function ()
            this:_chargeTroop(info, World_pb.MANOR_SINGLE)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)

    -- 集结收复、集结，均属于集结攻击类型的请求
    --（仅对于前端来说，因为后端会在收到请求后根据当前堡垒状态来判断marchType）
    elseif btnType == HudBtnType.MassReoccupy then
    	local confirmFunc = function ()
            local pageData = 
            {
                posX = info.coord.x,
                posY = info.coord.y,
                name = info.name,
                icon = info.icon,
                marchType = World_pb.MANOR_MASS
            }
            RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)
    -- 单人驻守
    -- 单人增援（这两个都是援助）
    elseif btnType == HudBtnType.Garrison
        or btnType == HudBtnType.Garrison_President
        or btnType == HudBtnType.Reinforce 
    then
        local marchType = World_pb.MANOR_ASSISTANCE
        if info.type == World_pb.KING_PALACE then
            marchType = World_pb.PRESIDENT_ASSISTANCE
        end
        local this = self
        local confirmFunc = function()
            this:_chargeTroop(info, marchType)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)
    -- 集结增援、集结驻守，都属于集结援助类型的请求
    --（仅对于前端来说，因为后端会在收到请求后根据当前堡垒状态来判断marchType）
    elseif btnType == HudBtnType.MassReinforce 
    	or btnType == HudBtnType.MassGarrison 
        or btnType == HudBtnType.MassGarrison_President
    then
        local marchType = World_pb.MANOR_ASSISTANCE_MASS
        if info.type == World_pb.KING_PALACE then
            marchType = World_pb.PRESIDENT_ASSISTANCE_MASS
        end

    	local confirmFunc = function ()
            local pageData = 
            {
                posX = info.coord.x,
                posY = info.coord.y,
                name = info.name,
                icon = info.icon,
                marchType = marchType
            }
            RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)

    -- 采集资源
    elseif btnType == HudBtnType.Collect then
        if info.type == World_pb.RESOURCE then
            common:playEffect('mapClickDetermine')
            self:_collectResource()
        else
            -- 采集超级矿
        	local isSelfCollect = RAMarchDataManager:CheckSelfSuperMineCollectStatus()
        	if isSelfCollect then
        		--提示已经在采集中
            	RARootManager.ShowMsgBox(_RALang('@AllianceSuperMineCollectingTip'))
        	else
    			local guildMineType = info.mineType
                local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
                local isCanCollect, cityLevel = RAPlayerInfoManager.getSelfIsOpenResByType(guildMineType)
                if isCanCollect then
                    self:_chargeTroop(info, World_pb.MANOR_COLLECT)
                else
                    local RAResManager = RARequire('RAResManager')
                    local _, name = RAResManager:getResourceIconByType(guildMineType)
                    RARootManager.ShowMsgBox('@NotAllowedToCollect', cityLevel, _RALang(name))
                end
    		end
        end
    -- 总统详情
    elseif btnType == HudBtnType.ViewDetail_President then
        RARootManager.OpenPage('RAPresidentPalacePage', {}, true)
    -- 任命
    elseif btnType == HudBtnType.Appoint then
        local world_map_const_conf = RARequire('world_map_const_conf')
        local stepCityLevel1 = world_map_const_conf['stepCityLevel1'].value
        if info.level >= stepCityLevel1 then
            local pageInfo = {playerId = info.playerId, name = info.name, icon = info.iconId}
            RARootManager.OpenPage('RAAppointToPlayerPage', pageInfo)
        else
            RARootManager.ShowMsgBox('@LowCastleLevelToAppoint', info.name, stepCityLevel1)
        end
    -- 总统府守军信息
    elseif btnType == HudBtnType.ViewGarrison_President then
        -- 判断自己是不是当前临时国王的公会
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        local RAAllianceManager = RARequire('RAAllianceManager')
        local tmpPresidentGuildId = RAPresidentDataManager:GetTmpPresidentInfo().guildId
        if RAAllianceManager:IsGuildFriend(tmpPresidentGuildId) then
            -- 驻军信息
            RARootManager.OpenPage('RAPresidentQuarterPage', {}, true)
        else
            RARootManager.ShowMsgBox('@PresidentChanged')
        end
    -- 堡垒守军信息
    elseif btnType == HudBtnType.ViewGarrison_Territory then
        -- 查看发射平台
        if info.territoryType == Const_pb.GUILD_MOVABLE_BUILDING then
            RARootManager.OpenPage('RAAllianceSiloPlatformQuarterPage',
            {
                territoryId = info.territoryId,
                coord = RACcp(info.coord.x, info.coord.y)
            }, true)
        end
        -- 查看堡垒守军
        if info.territoryType == Const_pb.GUILD_BASTION then
            RARootManager.OpenPage('RAAllianceBaseWarInfoPage', nil, true)
        end
    end

    self:RemoveHud()
end

function RAWorldHudManager:TriggerHudBtn(hudPos, btnType)
    self.hudMapPos = hudPos
    self:onHudFunction(btnType)
end

function RAWorldHudManager:_collectResource()
    local info = self.buildingNode.mBuildingInfo
    local enable, limitLevel = self.buildingNode:IsAbleToCollect()
    if enable then
        local this = self
        local confirmFunc = function ()
            this:_chargeTroop(info, World_pb.COLLECT_RESOURCE)
        end
        if self.buildingNode:GetRelation() == World_pb.ENEMY then
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        else
            confirmFunc()
        end
    else
        local RAResManager = RARequire('RAResManager')
        local _, name = RAResManager:getResourceIconByType(info.resType)
        RARootManager.ShowMsgBox('@NotAllowedToCollect', limitLevel, _RALang(name))
    end
end

function RAWorldHudManager:_chargeTroop(targetInfo, marchType)
    RAWorldUtil:ChargeTroops(targetInfo, marchType)
end

function RAWorldHudManager:_getHudBtnTB_Empty(mapPos)
    local tbs = {HudBtnType.Migrate}
    
    if RAWorldVar:IsInSelfKingdom() then
        -- 阻挡点不能占领
        local RAWorldManager = RARequire('RAWorldManager')
        if not RAWorldManager:IsBlock(mapPos) and not RAWorldUtil:IsInBankArea(mapPos) then
            table.insert(tbs, HudBtnType.Occupy)
        end

        -- 建造超级武器发射平台
        if RAAllianceManager:IsAbleToBuildLanchSilo() then
            local weaponType = RAAllianceManager:getSelfSuperWeaponType()
            if weaponType == Const_pb.GUILD_SILO then
                table.insert(tbs, HudBtnType.BuildNuclearSilo)
            elseif weaponType == Const_pb.GUILD_WEATHER then
                table.insert(tbs, HudBtnType.BuildWeatherSilo)
            end
        end
    else
        -- tbs = {HudBtnType.Migrate, HudBtnType.Settle, HudBtnType.InviteToMigrate, HudBtnType.Occupy}
    end

    return tbs
end

function RAWorldHudManager:_updateMarchHud()
    if self.movingMarchHud and self.marchId then
        -- 更新行军时间
        local marchData = RAMarchDataManager:GetMarchDataById(self.marchId)
        
        if marchData == nil then
            self.movingMarchHud = false
            self.hudPos = nil
            return
        end

        if self.hudNode then
            self.hudNode:UpdateTime(marchData:GetLastTime())
        end

        local hudPos = RAMarchManager:GetMarchMoveEntityViewPos(self.marchId)

        if not self.hudPos then
            self.hudPos = RACcp(hudPos.x, hudPos.y)
            return
        end

        local mapOffset = RACcpSub(self.hudPos, hudPos)
        if mapOffset.x ~= 0 or mapOffset.y ~= 0 then
            local RAWorldScene = RARequire('RAWorldScene')
            RAWorldScene:OffsetMap(mapOffset)
        end

        self.hudPos = RACcp(hudPos.x, hudPos.y)
    end
end

return RAWorldHudManager

--endregion
