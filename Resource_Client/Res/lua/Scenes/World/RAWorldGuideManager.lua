-- 新手引导城外部分
local RAWorldGuideManager =
{
	mScene = nil,
	mRootNode = nil,
	mCityNode = nil,
    mCitySpineNode = nil,
    mEnegyCCB = nil,
    mSecondCityNode = nil,
    mSecondBattleNode = nil,
    mYuriLeaveNode = nil,
    mFirstBattle = nil,
	mArmyNode = nil,
	-- 行军目标icon
	mIconNode = nil,
	-- 箭头指示
	mArrowNode = nil,

	mCCBList = nil,
	mInGuide = false,
	mGuidId = 0,
    mGuideKeyWord = "",
	mLastUpdateTime = 0,

	mMarchData =
	{
		line = {},
		army = {},
		startPos = {},
		endPos = nil
	}
}

local UIExtend = RARequire('UIExtend')
local RAWorldVar = RARequire('RAWorldVar')
local RAWorldMath = RARequire('RAWorldMath')
local RAGuideManager = RARequire('RAGuideManager')
local World_pb = RARequire('World_pb')
local Utilitys = RARequire('Utilitys')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldConfig = RARequire('RAWorldConfig')
local GuideCfg= RARequire('RAWorldGuideConfig')
local RecordDot_pb = RARequire('RecordDot_pb')
local RecordManager = RARequire('RecordManager')
local RAGuideConfig = RARequire("RAGuideConfig")

local GuideIdCfg = GuideCfg.IdList
local GuideKeyWordCfg = GuideCfg.GuideKeyList--新手关键字配置
local MapPosCfg = GuideCfg.MapPos
local DurationCfg = GuideCfg.Duration
local MarchType = GuideCfg.MarchType

function RAWorldGuideManager:Init(scene, rootNode)
	self.mScene = scene
	if rootNode then
		rootNode:setVisible(false)
		self.mRootNode = rootNode
	end
end

function RAWorldGuideManager:Execute()
	if not self.mInGuide then return end

	local curTime = CCTime:getCurrentTime()
	if curTime - self.mLastUpdateTime > DurationCfg.UpdateMarch then
		for marchType, _ in pairs(self.mMarchData.line) do
			self:_updateMarch(marchType)
		end
		self.mLastUpdateTime = curTime
	end
end

function RAWorldGuideManager:Clear()
	self:_clearCCB()
	self.mInGuide = false
	self.mRootNode:removeAllChildren()
end

function RAWorldGuideManager:OnReceiveGuideInfo(guideInfo)
	local id = guideInfo.guideId
	CCLuaLog('Guide in world, id: ' .. id)
	self.mGuidId = id
    self.mGuideKeyWord = guideInfo.keyWord--获得keyword

	if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.GuideStart then
        RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_WORLD_MAINCITY)--打点
		self:_beginGuide()
		self:_addSelf()
        local RARootManager = RARequire("RARootManager")
        RARootManager.RemoveGuidePage()--播放动画前，移除guidepage
		return
	end

	if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.WorldPrepareOpenBaseCar then
        RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_PREPARE_EXPAND_CAR)--打点
		self:_preExpandCity()
		return
	end

	if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.WorldOpenBaseCar then
        RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_EXPAND_CAR)--打点
		self:_gatherArmy()
		return
	end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.FirstBattleStart then
        self:_beginGuide()
        self:_FirstBattlePrepare()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.FirstBattleIng then
        self:_FirstBattleIng()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.SecondBattleStart then
        self:_SecondBattlePrepare()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.ShowEnegy then
        self:_ShowEnegy()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.TonyaForward then
        self:_SecondBattleTonyaForward()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.SecondBattleIng then
        self:_SecondBattleIng()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.YuriLeave then
        self:_YuriLeave()
        return
    end

    if self.mGuideKeyWord == RAGuideConfig.KeyWordArray.FindGuideResourceLand then
        --寻找新手资源田
--        performWithDelay(RAWorldGuideManager.mRootNode, function()
--            local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
--            local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.RESOURCE)
--            if result then
--                local RAWorldManager = RARequire("RAWorldManager")
--                RAWorldManager:LocateAt(result.x, result.y)
--                RAGuideManager.gotoNextStep()
--            else
--                RAGuideManager.gotoNextStep2()
--            end
--        end, 1)
        local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
        local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.RESOURCE)
        if result then
            local RAWorldMap = RARequire("RAWorldMap")
            RAWorldMap:GotoTileAtInGuide(result, RAGuideConfig.gotoResAndMonsterTime)--移动到资源田
            performWithDelay(RAWorldGuideManager.mRootNode, function()
                RAGuideManager.gotoNextStep()
            end, RAGuideConfig.gotoResAndMonsterTime+0.2)
        else
            RAGuideManager.gotoNextStep2()
        end

        
    elseif self.mGuideKeyWord == RAGuideConfig.KeyWordArray.FindGuideMonster then
--        performWithDelay(RAWorldGuideManager.mRootNode, function()
--            local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
--            local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.MONSTER)
--            if result then
--                local RAWorldManager = RARequire("RAWorldManager")
--                RAWorldManager:LocateAt(result.x, result.y)
--                RAGuideManager.gotoNextStep()
--            else
--                RAGuideManager.gotoNextStep2()
--            end
--        end, 1)

        local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
        local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.MONSTER)
        if result then
            local RAWorldMap = RARequire("RAWorldMap")
            RAWorldMap:GotoTileAtInGuide(result, RAGuideConfig.gotoResAndMonsterTime)--移动到资源田
            performWithDelay(RAWorldGuideManager.mRootNode, function()
                RAGuideManager.gotoNextStep()
            end, RAGuideConfig.gotoResAndMonsterTime+0.2)
        else
            RAGuideManager.gotoNextStep2()
        end

    end
	
--	if id == GuideIdCfg.FirstBattle_Fire then
--		self:_beginGuide()
--		self:_firstBattleFire()
--		return
--	end

--	if id == GuideIdCfg.SecondBattle_March then
--		self:_beginGuide()
--		self:_secondBattleMarch()
--		return
--	end

--	if id == GuideIdCfg.SecondBattle_Fire then
--		self:_beginGuide()
--		self:_secondBattleFire()
--		return
--	end
end

function RAWorldGuideManager:OnClick()
	-- self:_gotoNextStep()
end

function RAWorldGuideManager:_beginGuide()
	self.mScene:HideLayer4Guide()
	self.mInGuide = true
	if self.mCCBList == nil then
		self.mCCBList = {}
	end
end

function RAWorldGuideManager:_endGuide()
	self.mInGuide = false
	self.mScene:RestoreAllLayers()
end

function RAWorldGuideManager:_clearCCB()
	if self.mCCBList then
		for _, ccb in ipairs(self.mCCBList) do
			if Utilitys.isNil(ccb) then
				UIExtend.releaseCCBFile(ccb)
			end
		end
		self.mCCBList = nil
	end

    if self.mCitySpineNode then
        self.mCitySpineNode:removeFromParentAndCleanup(true)
        self.mCitySpineNode = nil
    end

	self.mMarchData.line = {}
	self.mMarchData.army = {}
	self.mCityNode = nil
    self.mEnegyCCB = nil
    self.mSecondCityNode = nil
    self.mSecondBattleNode = nil
    self.mYuriLeaveNode = nil
	self.mArmyNode = nil
	self.mIconNode = nil
end

function RAWorldGuideManager:_gotoNextStep()
	local guideId = RAWorldGuideManager.mGuidId 
	if guideId == GuideIdCfg.PreLeaveWorld_1
		--or guideId == GuideIdCfg.PreLeaveWorld_2
	then
		local RARootManager = RARequire('RARootManager')
		RARootManager.ChangeScene(SceneTypeList.CityScene)
	else
		RAGuideManager:gotoNextStep()
	end
end

function RAWorldGuideManager:_beginFirstBattle()
	-- 我方
	self:_addSelf()

	-- 敌方
--	local this = self
--	performWithDelay(self.mRootNode, function ()
--		this:_addEnemy({ccbi = 'Ani_Guide_P1_EnemyRun.ccbi'})
--	end, DurationCfg.ShowEnemy)
end

--desc:添加基地车进场景，播放基地车行进动画
function RAWorldGuideManager:_addSelf()	
	local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
    local armyNode = UIExtend.loadCCBFile('Ani_Guide_Entrance.ccbi', {
        OnAnimationDone = function (_self, ccbfile)
        	local lastAnimationName = ccbfile:getCompletedAnimationName()
		    if lastAnimationName == 'Entrance' then
                RAGuideManager:gotoNextStep()
            end
    end
    })
    armyNode:setPosition(RACcpUnpack(selfViewPos))
    armyNode:runAnimation("Entrance")
    self.mRootNode:addChild(armyNode)
    self.mArmyNode = armyNode

    --播放基地车行驶音效
    local common = RARequire("common")
    common:playEffect("BaseTravel")

	table.insert(self.mCCBList, armyNode)
end

function RAWorldGuideManager:_addEnemy(enemyInfo)
	local enemyPos = MapPosCfg.Enemy
	local enemyViewPos = RAWorldMath:Map2View(enemyPos)
	local enemyNode = UIExtend.loadCCBFile(enemyInfo.ccbi, {})
	enemyNode:setPosition(RACcpUnpack(enemyViewPos))
	self.mRootNode:addChild(enemyNode)
	enemyNode:runAnimation('Default Timeline')
	table.insert(self.mCCBList, enemyNode)

	self.mMarchData.army[MarchType.Enemy] = enemyNode
	self.mMarchData.startPos[MarchType.Enemy] = enemyViewPos

	-- 移动镜头
	local targetPos = RAWorldMath:Map2View(MapPosCfg.Center4Enemy)
	targetPos = RAWorldMath:GetCenterPosition(targetPos)
	local pos = ccp(RACcpUnpack(targetPos))
	local moveAction = CCMoveTo:create(DurationCfg.MoveCamera, pos)
	pos:delete()

	local this = self
	local callback = CCCallFunc:create(function ()
		this:_startMarch(MarchType.Enemy, enemyNode, DurationCfg.EnemyMarch)
	end)
	self.mScene.MapNode:runAction(CCSequence:createWithTwoActions(moveAction, callback))
end

function RAWorldGuideManager:_addFriend(onMarchEnd)
	-- 移动镜头
	local targetPos = RAWorldMath:Map2View(MapPosCfg.Center4Friend)
	targetPos = RAWorldMath:GetCenterPosition(targetPos)
	local pos = ccp(RACcpUnpack(targetPos))
	local moveAction = CCMoveTo:create(DurationCfg.MoveCamera, pos)
	pos:delete()

	local this = self
	local callback = CCCallFunc:create(function ()
		this:_addFriendCar(onMarchEnd)
	end)
	self.mScene.MapNode:runAction(CCSequence:createWithTwoActions(moveAction, callback))
end

function RAWorldGuideManager:_addFriendCar(onMarchEnd)
	local friendPos = MapPosCfg.Friend
	local friendViewPos = RAWorldMath:Map2View(RACcp(friendPos.x, friendPos.y + 2))
    
    -- 基地车动画
    local spineName = RAWorldConfig.Spine.CityCar
    local car = RAWorldUtil:AddSpine(spineName, World_pb.GUILD_FRIEND)
    car:setPosition(RACcpUnpack(friendViewPos))
    self.mRootNode:addChild(car)

    local this = self
    car:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
        if eventName == 'Complete' then
            if animationName == BUILDING_ANIMATION_TYPE.ORIGIN then
            	this:_addFriendCity(onMarchEnd)
                car:unregisterLuaListener()
                car:removeFromParentAndCleanup(true)
            end
        end
    end)
    car:runAnimation(0, BUILDING_ANIMATION_TYPE.ORIGIN, 1)
end

--desc:添加能量ccb
function RAWorldGuideManager:_addEnegy(rootNode)
    local enegyCCB = UIExtend.loadCCBFile("Ani_Guide_Transfer.ccbi",{
        OnAnimationDone = function (_self, ccbfile)
            local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == "Start" then
				ccbfile:runAnimation("Keep")
                --播放时空转换循环音效
                local common = RARequire("common")
                common:playEffect("TransmissionLoop")
			end
        end
    })
    if enegyCCB then
        rootNode:addChild(enegyCCB)
        enegyCCB:runAnimation("Start")
        --播放时空转换音效
        local common = RARequire("common")
        common:playEffect("TransmissionStart")
        self.mEnegyCCB = enegyCCB
        table.insert(self.mCCBList, enegyCCB)
    end
end

--desc:添加谭雅的基地车
function RAWorldGuideManager:_addTonyaCar(rootNode)
    local spineName = RAWorldConfig.Spine.CityCar
    local car = RAWorldUtil:AddSpine(spineName, World_pb.GUILD_FRIEND)
    rootNode:addChild(car)

    local this = self
    car:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
        if eventName == 'Complete' then
            if animationName == BUILDING_ANIMATION_TYPE.ORIGIN then
            	this:_addTonyaCity(rootNode)
                car:unregisterLuaListener()
                car:removeFromParentAndCleanup(true)
            end
        end
    end)
    car:runAnimation(0, BUILDING_ANIMATION_TYPE.ORIGIN, 1)
    --播放音效
    local common = RARequire("common")
    common:playEffect("TransmissionBaseDeformation")
end

function RAWorldGuideManager:_addFriendCity(onMarchEnd)
	local friendPos = MapPosCfg.Friend
	local friendViewPos = RAWorldMath:Map2View(RACcp(friendPos.x, friendPos.y + 2))
    
    -- 基地伸展动画
	local RAWorldConfigManager = RARequire('RAWorldConfigManager')
	local spineName = RAWorldConfigManager:GetCitySpineByLevel(1)
	local cityNode = RAWorldUtil:AddSpine(spineName, World_pb.GUILD_FRIEND)
	cityNode:setPosition(RACcpUnpack(friendViewPos))
	cityNode:setVisible(false)
    self.mRootNode:addChild(cityNode)

    local this = self
    cityNode:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
        if eventName == 'Start' then
        	if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
                performWithDelay(cityNode, function ()
                    cityNode:setVisible(true)
                end, 0.01)
            end
        elseif eventName == 'Complete' then
            if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
            	cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.IDLE_MAP, 1)
            	this:_addFriendMarch(onMarchEnd)
                cityNode:unregisterLuaListener()
            end
        end
    end)

    cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP, 1)
end

--desc:添加谭雅基地
function RAWorldGuideManager:_addTonyaCity(rootNode)
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
	local spineName = RAWorldConfigManager:GetCitySpineByLevel(6)
	local cityNode = RAWorldUtil:AddSpine(spineName, World_pb.GUILD_FRIEND)
	cityNode:setVisible(false)
    rootNode:addChild(cityNode)

    local this = self
    cityNode:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
        if eventName == 'Start' then
        	if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
                performWithDelay(cityNode, function ()
                    cityNode:setVisible(true)
                end, 0.01)
            end
        elseif eventName == 'Complete' then
            if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
            	cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.IDLE_MAP, 1)
                cityNode:unregisterLuaListener()
                --tonya基地车变形成功，进入下一步
                RAGuideManager.gotoNextStep()
            end
        end
    end)

    cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP, 1)

end

function RAWorldGuideManager:_addFriendMarch(onMarchEnd)
	local friendPos = MapPosCfg.Friend
	local friendViewPos = RAWorldMath:Map2View(friendPos)

	local friendNode = UIExtend.loadCCBFile('Ani_Guide_P2_FriendRun.ccbi', {})
	friendNode:setPosition(RACcpUnpack(friendViewPos))
	self.mRootNode:addChild(friendNode)
	friendNode:runAnimation('Default Timeline')
	table.insert(self.mCCBList, friendNode)

	self.mMarchData.army[MarchType.Friend] = friendNode
	self.mMarchData.startPos[MarchType.Friend] = friendViewPos

	self:_startMarch(MarchType.Friend, friendNode, DurationCfg.FriendMarch)
	local enemyNode = self.mMarchData.army[MarchType.Enemy]
	local enemyViewPos = RAWorldMath:Map2View(MapPosCfg.Enemy)
	enemyNode:setPosition(RACcpUnpack(enemyViewPos))
	self:_startMarch(MarchType.Enemy, enemyNode, DurationCfg.FriendMarch, onMarchEnd)
end

function RAWorldGuideManager:_startMarch(marchType, armyNode, duration, onMarchEnd)
	local selfViewPos = RAWorldMath:Map2View(MapPosCfg.Self)
	local pos = ccp(RACcpUnpack(selfViewPos))
	local moveAction = CCMoveTo:create(duration, pos)
	pos:delete()

	local this = self
	local callback = CCCallFunc:create(function ()
		if this.mMarchData.line[marchType] then
			UIExtend.releaseCCBFile(this.mMarchData.line[marchType])
			this.mMarchData.line[marchType] = nil
		end
		if this.mMarchData.army[marchType] then
			UIExtend.releaseCCBFile(this.mMarchData.army[marchType])
			this.mMarchData.army[marchType] = nil
		end
		if this.mIconNode then
			UIExtend.releaseCCBFile(this.mIconNode)
			this.mIconNode = nil
		end
		if onMarchEnd then
			onMarchEnd()
		end
	end)
	armyNode:runAction(CCSequence:createWithTwoActions(moveAction, callback))

	-- 行军线
	self.mMarchData.endPos = selfViewPos
	self:_updateMarchLine(marchType)
    self.mLastUpdateTime = CCTime:getCurrentTime()

    if marchType == MarchType.Enemy and onMarchEnd == nil then
    	-- 开始播动画,行军动画暂停
	    local stopMarch = function ()
	    	armyNode:stopAllActions()
	    	this:_gotoNextStep()
	    end
	    performWithDelay(armyNode, stopMarch, DurationCfg.GotoNextStep)
	end
end

--desc:准备展开基地车
function RAWorldGuideManager:_preExpandCity()
    --添加汽车spine，需要先隐藏，防止穿帮
	local RAWorldConfigManager = RARequire('RAWorldConfigManager')
	local spineName = RAWorldConfigManager:GetCitySpineByLevel(1)--获得第一等级主基地的spine
	local cityNode = RAWorldUtil:AddSpine(spineName, World_pb.SELF)

	local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
	cityNode:setPosition(selfViewPos.x, selfViewPos.y - RAWorldConfig.tileSize.height - 6)

	self.mRootNode:addChild(cityNode)
	cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.ORIGIN, 1)
	self.mCitySpineNode = cityNode
    cityNode:setVisible(false)


    --添加指示箭头
    local this = self
    local arrowNode = UIExtend.loadCCBFile("Ani_Guide_Arrow_Car.ccbi",{
        onOpenBtn = function ()
            this.mRootNode:stopAllActions()
            RAGuideManager:gotoNextStep()
        end
    })
    local viewPos = RAWorldMath:Map2View(MapPosCfg.Self)
    local ClickArea = GuideCfg.ClickArea
    local arrowPos = RACcpAdd(viewPos, ClickArea.ArrowOffset)
    arrowNode:setPosition(RACcpUnpack(arrowPos))
    self.mRootNode:addChild(arrowNode)
    performWithDelay(self.mRootNode, function ()
        --todo:显示请点击基地车的文字
    end, DurationCfg.ShowClickCarDur)
    self.mArrowNode = arrowNode
    local RARootManager = RARequire('RARootManager')
    RARootManager.RemoveCoverPage()
end

--desc:展开基地车
function RAWorldGuideManager:_gatherArmy()
	if self.mArrowNode then
		UIExtend.releaseCCBFile(self.mArrowNode)
		self.mArrowNode = nil
	end

    -- local actionArray = CCArray:create()
    -- local targetPos = GuideCfg.ClickArea.ArrowOffset
    -- targetPos = RAWorldVar.ViewPos.Map
    -- targetPos.y = 0-targetPos.y

    local viewPos = RAWorldMath:Map2View(RAWorldVar.MapPos.Map)
    viewPos = RACcpAdd(viewPos, GuideCfg.ClickArea.ArrowOffset)
    local targetPos = RAWorldMath:GetCenterPosition(viewPos, GuideCfg.MapScale.ExpandCarScale)

    local moveAction = CCMoveTo:create(GuideCfg.MapScaleTime.ExpandCarScaleTime, ccp(RACcpUnpack(targetPos)))
    -- actionArray:addObject(moveAction)
	self.mScene.MapNode:runAction(moveAction)


    local scaleAction = CCScaleTo:create(GuideCfg.MapScaleTime.ExpandCarScaleTime, GuideCfg.MapScale.ExpandCarScale)
    -- actionArray:addObject(scaleAction)
    --local spawnAction = CCSpawn:create(actionArray)
	self.mScene.RootNode:runAction(scaleAction)

    self:_expandCity()
end

--desc:展开基地车的具体逻辑
function RAWorldGuideManager:_expandCity()
	local this = self
    self.mCitySpineNode:registerLuaListener(function(eventName, trackIndex, animationName, loopCount, reverse)
	    if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP then
			if eventName == "Complete" then
	 			this.mCitySpineNode:unregisterLuaListener()
                RAGuideManager.gotoNextStep()
	        end
	    end
	end)
    --播放变形音效
    local common = RARequire("common")
    common:playEffect("BaseDeformation")
    --播放spine的变形动画，显示spine节点，隐藏ccb原有小车节点，防止穿帮
	self.mCitySpineNode:runAnimation(0, BUILDING_ANIMATION_TYPE.CONSTRUCTION_MAP, 1)
    UIExtend.setNodeVisible(self.mArmyNode, "CarNode",false)
    self.mCitySpineNode:setVisible(true)
end

--desc:第一场战斗准备
function RAWorldGuideManager:_FirstBattlePrepare()
    --关闭warning
    local RARootManager = RARequire("RARootManager")
    RARootManager.isShowWarning = false
    MessageManager.sendMessage(MessageDef_MainUI.MSG_Update_Warning)--关闭warning

    --第一场战斗加载己方基地
    local this = self
    local mainCity = UIExtend.loadCCBFile("Ani_Guide_P1_Scene.ccbi", {
        OnAnimationDone = function (_self, ccbfile)
--			local lastAnimationName = ccbfile:getCompletedAnimationName()
--			if lastAnimationName == 'Fixed Lens' then
--				ccbfile:runAnimation("Cut Lens")
--            elseif lastAnimationName == "Cut Lens" then
--                ccbfile:runAnimation("Keep Lens")
--                --加载出击按钮
--                --模拟点击出击按钮逻辑
--                local btnNode = UIExtend.getCCNodeFromCCB(ccbfile, "mFocus")
--                this:_addAttackBtn(btnNode)
--			end
		end
    })

    local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
    mainCity:setPosition(RACcpUnpack(selfViewPos))
    self.mCityNode = mainCity
    self.mRootNode:addChild(mainCity)

    --播放锁定目标音效
    local common = RARequire("common")
    common:playEffect("BaseWasLocked")

    --mainCity:runAnimation("Keep Lens")
    --delay
    local array = CCArray:create()
    local delayAction = CCDelayTime:create(DurationCfg.FixedLensTime)
    array:addObject(delayAction)

    local enlargeMap = CCCallFunc:create(function()
	    local RAWorldMap = RARequire("RAWorldMap")
	    RAWorldMap:EnlargeSizeForGuide()
    end)
    array:addObject(enlargeMap)

    --show enemy
    local showEnemyPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.FirstBattleShowEnemy))
	local enemyAction = CCMoveBy:create(DurationCfg.FirstBattleShowEnemy, showEnemyPos)
    --local enemyEaseAction = CCEaseExponentialInOut:create(enemyAction)
    local enemyEaseAction = CCEaseInOut:create(enemyAction, 2)

	showEnemyPos:delete()
    array:addObject(enemyEaseAction)
    --播放怪物音效
    local playMonsterSound = CCCallFunc:create(function ()
        local common = RARequire("common")
        common:playEffect("FristWaveOfTroops")
    end)
    array:addObject(playMonsterSound)
    --delay 
    local delayActionKeep = CCDelayTime:create(DurationCfg.FirstBattleDelay)
    array:addObject(delayActionKeep)
    --back to city
    local backCityPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.FirstBattleBackCity))
	local backCityAction = CCMoveBy:create(DurationCfg.FirstBattleBackCity, backCityPos)
    local backCityEaseAction = CCEaseInOut:create(backCityAction, 1)
	backCityPos:delete()
    array:addObject(backCityEaseAction)
    --show attack btn
    local addAttackBtn = CCCallFunc:create( function()
        --local btnNode = UIExtend.getCCNodeFromCCB(mainCity, "mFocus")
        --this:_addAttackBtn(btnNode)
        RAGuideManager.gotoNextStep()
    end )
    array:addObject(addAttackBtn)
    local sequenceAction = CCSequence:create(array);
    array:removeAllObjects()
    array:release()

    self.mScene.MapNode:runAction(sequenceAction)
    --sequenceAction:release()
    table.insert(self.mCCBList, mainCity)
end

--desc:加载出击按钮
function RAWorldGuideManager:_addAttackBtn(rootNode)
    local this = self
    local attackCCB = nil
    attackCCB = UIExtend.loadCCBFile("RAGuideAttackAni.ccbi",{
        onAttackBtn = function ()
            this.mCityNode:setVisible(false)
            attackCCB:setVisible(false)
            attackCCB:removeFromParentAndCleanup(true)
            this:_FirstBattleIng()
        end
    })

    if rootNode then
        rootNode:addChild(attackCCB)
    end
end

--desc:第一场战斗进行
function RAWorldGuideManager:_FirstBattleIng()
    local this = self
    local firstBattleCCB = UIExtend.loadCCBFile("Ani_Guide_New_P1_Battle.ccbi",{
        OnAnimationDone = function (_self, ccbfile)
            local lastAnimationName = ccbfile:getCompletedAnimationName()
            if lastAnimationName == "Battle" then
                --local RARootManager = RARequire("RARootManager")
                --RARootManager.isShowWarning = false
                --MessageManager.sendMessage(MessageDef_MainUI.MSG_Update_Warning)--关闭warning
                RAGuideManager.gotoNextStep()
                --ccbfile:setVisible(false)
            end
        end
    })

    local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
    firstBattleCCB:setPosition(RACcpUnpack(selfViewPos))
    self.mRootNode:addChild(firstBattleCCB)
    firstBattleCCB:runAnimation("Battle")
    self.mFirstBattle = firstBattleCCB
    if self.mCityNode then
        self.mCityNode:setVisible(false)
    end

    --第一次拉近镜头，伴随着移动
    local targetPos = RAWorldMath:GetCenterPosition(selfViewPos, GuideCfg.MapScale.FirstBattleIngScale)
    local moveAction = CCMoveTo:create(GuideCfg.MapScaleTime.FirstBattleIngScaleTime, ccp(RACcpUnpack(targetPos)))
	self.mScene.MapNode:runAction(moveAction)
    local scaleAction = CCScaleTo:create(GuideCfg.MapScaleTime.FirstBattleIngScaleTime, GuideCfg.MapScale.FirstBattleIngScale)
    self.mScene.RootNode:runAction(scaleAction)

    --播放第一场战斗音效音效
    local common = RARequire("common")
    common:playEffect("FristBattles")
    
    table.insert(self.mCCBList, firstBattleCCB)
end

--desc:第二场战斗准备
function RAWorldGuideManager:_SecondBattlePrepare()
    local this = self
    local parentNode = nil


    local secondMainCity = UIExtend.loadCCBFile("Ani_Guide_P2_Scene.ccbi", {
        OnAnimationDone = function (_self, ccbfile)
			local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == 'Move To Enemy' then
                --RAGuideManager.gotoNextStep()
            elseif lastAnimationName == 'Move To Friend' then
				--this:_addTonyaCar(parentNode)
			end
		end
    })

    parentNode = UIExtend.getCCNodeFromCCB(secondMainCity, "mFriend")

    local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
    secondMainCity:setPosition(RACcpUnpack(selfViewPos))
    self.mRootNode:addChild(secondMainCity)
    secondMainCity:runAnimation("Move To Enemy")
    if self.mFirstBattle then
        self.mFirstBattle:removeFromParentAndCleanup(true)
        self.mFirstBattle = nil
    end
    
    --播放第二场战斗Yuri基地出现音效
    local common = RARequire("common")
    common:playEffect("SpaceTransAndBaseDefor")

    local array = CCArray:create()
    --show enemy
    local showEnemyPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleShowEnemy))
	local enemyAction = CCMoveBy:create(DurationCfg.SecondBattleShowEnemy, showEnemyPos)
    local enemyEaseAction = CCEaseInOut:create(enemyAction, 2)
	showEnemyPos:delete()
    array:addObject(enemyEaseAction)
    --delay 
    local delayActionKeep = CCDelayTime:create(DurationCfg.SecondBattleDelay)
    array:addObject(delayActionKeep)
    --back to city
    local backCityPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleBackCity))
	local backCityAction = CCMoveBy:create(DurationCfg.SecondBattleBackCity, backCityPos)
    local backCityEaseAction = CCEaseInOut:create(backCityAction, 2)
	backCityPos:delete()
    array:addObject(backCityEaseAction)
    --go to next step
    local gotoNext = CCCallFunc:create( function()
        secondMainCity:runAnimation("Move To Friend")--打开迷雾
        RAGuideManager.gotoNextStep()
    end )
    array:addObject(gotoNext)
    local sequenceAction = CCSequence:create(array);
    array:removeAllObjects()
    array:release()

    --第一次拉远镜头，伴随着位移
    local scaleAction = CCScaleTo:create(DurationCfg.SecondBattleShowEnemy, GuideCfg.MapScale.SecondBattlePrepareScale)
    self.mScene.RootNode:runAction(scaleAction)

    self.mScene.MapNode:runAction(sequenceAction)
    self.mSecondCityNode = secondMainCity
    table.insert(self.mCCBList, secondMainCity)
end

--desc:显示能量场
function RAWorldGuideManager:_ShowEnegy()
    local this = self
    local array = CCArray:create()
    --show enemy
    local showEnemyPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleToFriend))
	local enemyAction = CCMoveBy:create(DurationCfg.SecondBattleToFriend, showEnemyPos)
	showEnemyPos:delete()
    array:addObject(enemyAction)
    local parentNode = UIExtend.getCCNodeFromCCB(self.mSecondCityNode, "mTranferNode")
    --go to next step
    local callBack = CCCallFunc:create( function()
        this:_addEnegy(parentNode)
    end )
    array:addObject(callBack)

    local delay = CCDelayTime:create(0.5)
    array:addObject(delay)

    local callBack2 = CCCallFunc:create( function()
        RAGuideManager.gotoNextStep()
    end )
    array:addObject(callBack2)

    local sequenceAction = CCSequence:create(array);
    array:removeAllObjects()
    array:release()



    --第二次拉近镜头
    local scaleAction = CCScaleTo:create(DurationCfg.SecondBattleToFriend, GuideCfg.MapScale.SecondBattleFriendScale)
    self.mScene.RootNode:runAction(scaleAction)

    self.mScene.MapNode:runAction(sequenceAction)
end

--desc:第二步谭雅集合
function RAWorldGuideManager:_SecondBattleTonyaForward()
--    local this = self
--    local array = CCArray:create()
--    --show enemy
--    local showEnemyPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleToFriend))
--	local enemyAction = CCMoveBy:create(DurationCfg.SecondBattleToFriend, showEnemyPos)
--	showEnemyPos:delete()
--    array:addObject(enemyAction)
--    local parentNode = UIExtend.getCCNodeFromCCB(self.mSecondCityNode, "mFriend")
--    --go to next step
--    local addAttackBtn = CCCallFunc:create( function()
--        this:_addTonyaCar(parentNode)
--        --self.mCityNode:setVisible(false)
--    end )
--    array:addObject(addAttackBtn)
--    local sequenceAction = CCSequence:create(array);
--    array:removeAllObjects()
--    array:release()

--    self.mScene.MapNode:runAction(sequenceAction)

    local parentNode = UIExtend.getCCNodeFromCCB(self.mSecondCityNode, "mFriend")
    self:_addTonyaCar(parentNode)
    if self.mEnegyCCB then
        self.mEnegyCCB:removeFromParentAndCleanup(true)
        self.mEnegyCCB = nil
    end
end

--desc:第二次战斗过程
function RAWorldGuideManager:_SecondBattleIng()

    local secondBattleNode = UIExtend.loadCCBFile("Ani_Guide_New_P2_Battle.ccbi", {
        OnAnimationDone = function (_self, ccbfile)
			local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == 'Battle' then
				RAGuideManager.gotoNextStep()
			end
		end
    })
    local RAWorldConfigManager = RARequire("RAWorldConfigManager")
    local parentNode = UIExtend.getCCNodeFromCCB(secondBattleNode, "mFriend")
    local spineName = RAWorldConfigManager:GetCitySpineByLevel(6)
	local cityNode = RAWorldUtil:AddSpine(spineName, World_pb.GUILD_FRIEND)
	cityNode:setVisible(true)
    parentNode:addChild(cityNode)
    cityNode:runAnimation(0, BUILDING_ANIMATION_TYPE.IDLE_MAP, 1)
    

    local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
    secondBattleNode:setPosition(RACcpUnpack(selfViewPos))
    self.mRootNode:addChild(secondBattleNode)
    secondBattleNode:runAnimation("Battle")

    if self.mSecondCityNode then
        self.mSecondCityNode:setVisible(false)
    end

    local array = CCArray:create()
    --delay 
    local delayActionKeep = CCDelayTime:create(DurationCfg.SecondBattleFightPrepare)
    array:addObject(delayActionKeep)
    --back to self
    local backSelfPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleFightMove))
	local backSelfAction = CCMoveBy:create(DurationCfg.SecondBattleFightMove, backSelfPos)
	backSelfPos:delete()
    array:addObject(backSelfAction)
    --delay 2
    local delayActionKeep = CCDelayTime:create(DurationCfg.SecondBattleFightPrepare2)
    array:addObject(delayActionKeep)
    --move to battle field
    local moveBattleFieldPos = ccp(RACcpUnpack(GuideCfg.MoveCameraOffset.SecondBattleFightMove2))
	local moveBattleFieldAction = CCMoveBy:create(DurationCfg.SecondBattleFightMove2, moveBattleFieldPos)
	moveBattleFieldPos:delete()
    array:addObject(moveBattleFieldAction)
    local sequenceAction = CCSequence:create(array);
    array:removeAllObjects()
    array:release()

    self.mScene.MapNode:runAction(sequenceAction)

    --第二场战斗音效
    local common = RARequire("common")
    common:playEffect("SecondBattles")

    self.mSecondBattleNode = secondBattleNode
    table.insert(self.mCCBList, secondBattleNode)
end

--desc:尤里离开
function RAWorldGuideManager:_YuriLeave()
--	local yuriCastleCCB = UIExtend.loadCCBFile('Ani_Guide_YuriCastle.ccbi', {
--		OnAnimationDone = function (_self, ccbfile)
--			local lastAnimationName = ccbfile:getCompletedAnimationName()
--			if lastAnimationName == 'xxxxxxxxxxxxxxxxxxx' then
--				RAGuideManager.gotoNextStep()
--			end
--		end
--	})
--    local selfPos = MapPosCfg.Self
--	local selfViewPos = RAWorldMath:Map2View(selfPos)
--	yuriCastleCCB:setPosition(RACcpUnpack(selfViewPos))
--    yuriCastleCCB:runAnimation("xxxxxxxxxxxxxxxxxxx")--todo:Yuri飞走的动画
--	self.mRootNode:addChild(yuriCastleCCB)
--	table.insert(self.mCCBList, yuriCastleCCB)


    local yuriCastleCCB = UIExtend.loadCCBFile('Ani_Guide_P3_Scene.ccbi', {
		OnAnimationDone = function (_self, ccbfile)
			local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == 'Move To Enemy' then
				RAGuideManager.gotoNextStep()
			end
		end
	})
    local selfPos = MapPosCfg.Self
	local selfViewPos = RAWorldMath:Map2View(selfPos)
	yuriCastleCCB:setPosition(RACcpUnpack(selfViewPos))
    self.mRootNode:addChild(yuriCastleCCB)
    yuriCastleCCB:runAnimation("Move To Enemy")

    if self.mSecondBattleNode then
        self.mSecondBattleNode:setVisible(false)
    end



    local array = CCArray:create()
    --show enemy
    local showEnemyPos = ccp(RACcpUnpack(RACcpSub(GuideCfg.MoveCameraOffset.SecondBattleShowEnemy, GuideCfg.MoveCameraOffset.SecondBattleFightMove2)))
	local enemyAction = CCMoveBy:create(DurationCfg.YuriLeaveMove, showEnemyPos)
    local enemyEaseAction = CCEaseSineInOut:create(enemyAction)
	showEnemyPos:delete()
    array:addObject(enemyEaseAction)

    --delay 
    local delayActionKeep = CCDelayTime:create(DurationCfg.YuriLeave)
    array:addObject(delayActionKeep)

    local sequenceAction = CCSequence:create(array);
    array:removeAllObjects()
    array:release()


    --第二次拉远镜头
    local scaleAction = CCScaleTo:create(DurationCfg.YuriLeaveMove, GuideCfg.MapScale.SecondBattleYuriLeaveScale)
    self.mScene.RootNode:runAction(scaleAction)

    self.mScene.MapNode:runAction(sequenceAction)
    --播放yuri逃走的音效
    local common = RARequire("common")
    common:playEffect("yurileave")
    
    self.mYuriLeaveNode = yuriCastleCCB
    table.insert(self.mCCBList, yuriCastleCCB)

    --RAGuideManager.gotoNextStep()
end

function RAWorldGuideManager:_firstBattleFire()
	local this = self
	local fireCCB = UIExtend.loadCCBFile('Ani_Guide_P1_Battle.ccbi', {
		OnAnimationDone = function (_self, ccbfile)
			local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == 'Fighting' then
				this:_gotoNextStep()
			end
		end
	})
	fireCCB:setPosition(RACcpUnpack(RAWorldVar.ViewPos.Map))
	self.mRootNode:addChild(fireCCB)
	table.insert(self.mCCBList, fireCCB)
end

function RAWorldGuideManager:_secondBattleMarch()
	self:_addEnemy({ccbi = 'Ani_Guide_P2_EnemyRun.ccbi'})
end

function RAWorldGuideManager:_secondBattleFire()
	local this = self
	self:_addFriend(function ()
		this:_doSecondBattleFire()
	end)

	-- 移动镜头
	local targetPos = RAWorldMath:Map2View(MapPosCfg.Self)
	targetPos = RAWorldMath:GetCenterPosition(targetPos)
	local pos = ccp(RACcpUnpack(targetPos))
	local moveAction = CCMoveTo:create(DurationCfg.MoveCamera, pos)
	moveAction:retain()
	pos:delete()

	local this = self
	performWithDelay(self.mRootNode, function ()
		this.mScene.MapNode:runAction(moveAction)
		moveAction:release()
	end, DurationCfg.ShowSelf)
end

function RAWorldGuideManager:_doSecondBattleFire()
	self:_clearCCB()
	self.mCCBList = {}

	local this = self
	local fireCCB = UIExtend.loadCCBFile('Ani_Guide_P2_Battle.ccbi', {
		OnAnimationDone = function (_self, ccbfile)
			local lastAnimationName = ccbfile:getCompletedAnimationName()
			if lastAnimationName == 'Default Timeline' then
				this:_gotoNextStep()
			end
		end
	})
	fireCCB:setPosition(RACcpUnpack(self.mMarchData.endPos))
	self.mRootNode:addChild(fireCCB)
	table.insert(self.mCCBList, fireCCB)
end

function RAWorldGuideManager:_updateMarch(marchType)
	-- 更新军队位置
	self.mMarchData.startPos[marchType] = RACcp(self.mMarchData.army[marchType]:getPosition())

	-- 更新行军线
	self:_updateMarchLine(marchType)
end

function RAWorldGuideManager:_updateMarchLine(marchType)
	local RAMarchConfig = RARequire('RAMarchConfig')

	-- 添加目标icon
	if self.mIconNode == nil then
		local iconNode = UIExtend.loadCCBFile(RAMarchConfig.EndPosCCB, {})
		iconNode:setPosition(RACcpUnpack(self.mMarchData.endPos))
		self.mRootNode:addChild(iconNode)
		self.mIconNode = iconNode
		table.insert(self.mCCBList, iconNode)
	end

    local ccbName = RAMarchConfig.MarchRelation2CCB[marchType].ccb
    if ccbName ~= '' then
        local ccbi = UIExtend.loadCCBFile(ccbName, {})
        self.mRootNode:addChild(ccbi)
        ccbi:setVisible(false)
        local startPos, endPos = self.mMarchData.startPos[marchType], self.mMarchData.endPos       
        local lineSpr = UIExtend.getCCSpriteFromCCB(ccbi, 'mArmyLine')
        if lineSpr ~= nil then
        	local degree = Utilitys.getDegree(startPos.x - endPos.x, startPos.y - endPos.y)
            -- 锚点在右侧
            lineSpr:setRotation(180 - degree)
            local height = lineSpr:getContentSize().height
            local width = Utilitys.getDistance(startPos, endPos)
            lineSpr:setPreferedSize(CCSize(width, height))
        end
        ccbi:setPosition(RACcpUnpack(startPos))
        ccbi:setVisible(true)
        table.insert(self.mCCBList, ccbi)

        if self.mMarchData.line[marchType] then
        	UIExtend.releaseCCBFile(self.mMarchData.line[marchType])
        end
        self.mMarchData.line[marchType] = ccbi
    end
end

-- 添加尤里的基地
function RAWorldGuideManager:_addYuriCastle()
	local spineName = RAWorldConfig.Spine.YuriCastle
    local castle = SpineContainer:create(spineName .. '.json', spineName .. '.atlas')
    
    local viewPos = RAWorldMath:Map2View(MapPosCfg.Enemy)
    castle:setPosition(viewPos.x, viewPos.y)
    
    self.mRootNode:addChild(castle)
end

-- 添加资源田
function RAWorldGuideManager:_addResource()
	local resId = 300101

	local RAWorldConfigManager = RARequire('RAWorldConfigManager')
	local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(resId)
	local spineName = resShowCfg.buildArtJson
	local resSpine = RAWorldUtil:AddSpine(spineName, World_pb.NONE)
	local viewPos = RAWorldMath:Map2View(MapPosCfg.GoldResource)
	resSpine:setPosition(viewPos.x, viewPos.y)

	self.mRootNode:addChild(resSpine)
end

return RAWorldGuideManager