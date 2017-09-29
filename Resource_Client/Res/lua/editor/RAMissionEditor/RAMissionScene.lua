local UIExtend = RARequire('UIExtend')

local RAMissionScene = BaseFunctionPage:new(...)
local RARootManager = RARequire('RARootManager')
local RAFightManager = RARequire('RAFightManager')
local RABattleSceneManager = RARequire("RABattleSceneManager")
local battle_map_conf = RARequire('battle_map_conf') 
function RAMissionScene:reset()
    self.mRootNode = nil --底图
    
    self.mTileMapLayer = nil --地图

    self.mMapSizeWidth = 0 --地图宽
    self.mMapSizeHeight = 0 --地图的长

    self.mTileSizeWidth = 0 --地块宽
    self.mTileSizeHeight = 0 --地块高

    self.mCamera = nil --摄像头
    self.isCameraMoving = false --摄像机是否在移动中

    self.multiLayerInfo = nil --多点触控
    
    self.multiLayerTable = {}
    self.multiLayerTable.isMoveEnabled = true
    self.multiLayerTable.dragState = false
    self.multiLayerTable.scaleState = false
    self.curScale = 1
    self.scrollTable = {}
    self.scrollTable.state = nil
    self.mFightPlay = nil  

    self.curMissionData = nil 
    self.curMapData = nil 
end


function RAMissionScene:Enter(data)

    self:reset()
    --初始化场景管理
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    RABattleSceneManager:init(self)

    self:initRootLayer()
    self:initBattleUnitLayer()
    self:initCamera()

    self:initTouchLayer()
    self:initMultiTouchLayer()

    self:initMenu()
end

function RAMissionScene:changeMission(curMissionData)
    self.curMissionData = curMissionData
    local battle_map_conf = RARequire('battle_map_conf') 
    self.curMapData = battle_map_conf[self.curMissionData.mapid]

    self:changeTileMapLayer(self.curMapData)

    local TestData = RARequire('TestData')
    local battleParams,missionId = TestData:getData(curMissionData.missionId) --测试数据
    RAFightManager:initBattleParams(battleParams)

    RAFightManager:init(missionId)

    RAFightManager:calBattle(self.mMapSizeWidth,self.mMapSizeHeight,self.mTileMapBlockLayer)

    RABattleSceneManager:cleanScene()
    RABattleSceneManager:initAllBattleUnits(RAFightManager.initActions)   
    RABattleSceneManager:attackersIdle()
    -- RAFightManager:initExecuteData() 
end

function RAMissionScene:multilayerTouchesBegin()
    if #self.multiLayerInfo == 2 then
        self.multiLayerTable.startDis = math.abs(self.multiLayerInfo[1].x - self.multiLayerInfo[2].x) + math.abs(self.multiLayerInfo[1].y - self.multiLayerInfo[2].y)
        self.multiLayerTable.startScale = self.mCamera:getScale()
        local offset =  self.mCamera:getOffSet()
        self.multiLayerTable.startCenter = ccp(
        (self.multiLayerInfo[1].x + self.multiLayerInfo[2].x)/2,
        (self.multiLayerInfo[1].y + self.multiLayerInfo[2].y)/2)  
        self.multiLayerTable.startTerrain = ccp(
        offset.x + self.multiLayerTable.startCenter.x * self.multiLayerTable.startScale,
        offset.y + self.multiLayerTable.startCenter.y * self.multiLayerTable.startScale)
        self.multiLayerTable.dragState = false
        self.multiLayerTable.scaleState = true
    elseif #self.multiLayerInfo == 1 then
        self.multiLayerTable.dragState = true
        self.multiLayerTable.scaleState = false
    else
        self.multiLayerTable.dragState = false
        self.multiLayerTable.scaleState = false
    end
    self:scrollToucheBegin()
end

function RAMissionScene:initBattleUnitLayer()
    --兵种层
    self.mBattleUnitLayer = CCLayer:create()
    self.mBattleUnitLayer:setPosition(0, 0)
    self.mBattleUnitLayer:setAnchorPoint(ccp(0, 0))  

    --兵种死亡损坏后的层级
    self.mBattleUnitDieLayer = CCLayer:create()
    self.mBattleUnitDieLayer:setPosition(0,0)
    self.mBattleUnitDieLayer:setAnchorPoint(ccp(0,0))

    self.mRootNode:addChild(self.mBattleUnitDieLayer)
    self.mRootNode:addChild(self.mBattleUnitLayer)
end


function RAMissionScene:initMenu()
    local mainMenu = CCMenu:create()
    local textLabel = CCLabelTTF:create('选择关卡', "Helvetica", 20)
    local menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    local missionEditorBtn = function ()
        CCLuaLog('this is a test')
        RARootManager.OpenPage("RAMissionInfoPage")
    end
    menuItemLabel:registerScriptTapHandler(missionEditorBtn)
    
    textLabel = CCLabelTTF:create('新建关卡', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    textLabel = CCLabelTTF:create('保存关卡', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    textLabel = CCLabelTTF:create('设置选项', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    mainMenu:alignItemsVerticallyWithPadding(10)
    mainMenu:setAnchorPoint(ccp(0,0))

    mainMenu:setPosition(ccp(40,CCDirector:sharedDirector():getOpenGLView():getVisibleSize().height-70))
    RARootManager.mGUINode:addChild(mainMenu)
end

--初始化触摸层
function RAMissionScene:initTouchLayer()
    self.mTouchLayer = CCLayer:create()
    self.mTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    self.mTouchLayer:setPosition(0, 0)
    self.mTouchLayer:setAnchorPoint(ccp(0, 0))
    self.mTouchLayer:setTouchEnabled(true)
    self.mTouchLayer:setKeypadEnabled(true)
    self.mTouchLayer:setTouchMode(kCCTouchesOneByOne)
    self.mRootNode:addChild(self.mTouchLayer)
    
    local singleBattleSceneTouch = function(pEvent, touch)
        self:singleBattleSceneTouch(pEvent, touch) 
    end

    self.mTouchLayer:registerScriptTouchHandler(singleBattleSceneTouch) 
end

function RAMissionScene:getTouchCityScenePos(point)
    local cameraOffSet = self.mCamera:getOffSet()
    local cameraScale = self.mCamera:getScale()
    local terrainPos = RACcp(cameraOffSet.x + point.x * cameraScale,cameraOffSet.y + point.y * cameraScale)
    return terrainPos
end

function RAMissionScene:removeTouches(touches)
    for i=1,#touches,3 do
        for j=1,#self.multiLayerInfo do
            if self.multiLayerInfo[j].id == touches[i+2] then
                table.remove(self.multiLayerInfo,j)
                break
            end
        end
    end
end

function RAMissionScene:convertScreenPos2TerrainPos(position)
    local cameraOffSet = self.mCamera:getOffSet()
    local cameraScale = self.mCamera:getScale()
    local terrainPos = RACcp(cameraOffSet.x + position.x * cameraScale,cameraOffSet.y + position.y * cameraScale)
    return terrainPos
end

function RAMissionScene:isInDragState()
    return self.multiLayerTable.dragState
end

function RAMissionScene:isInScaleState()
    return self.multiLayerTable.scaleState
end

function RAMissionScene:Scrolling()
    if self.scrollTable.state then 
        self:deaccelerateScrolling()
    end 
end

function RAMissionScene:layerTouchesFinish(touches)
    self.multiLayerTable.startDis = nil
    self.multiLayerTable.startScale = nil
    self.scrollTable.endTime = GamePrecedure:getInstance():getTotalTime()        
    
    if self.scrollTable.acceleSet then
        self.scrollTable.state = true
    end
    if self.scrollTable.touchTime ~= nil then
        if self.scrollTable.endTime - self.scrollTable.touchTime >= 0.08 then
            self.scrollTable.state = false
        end
    end
    
    self:removeTouches(touches)    
end

function RAMissionScene:scrollToucheBegin()
    if #self.multiLayerInfo ~= 1 then
        return
    end
    
    local winSize = CCDirector:sharedDirector():getWinSize()
    local mapSize = self.mCamera:getSize()
    local cameraScale = self.mCamera:getScale()
    self.scrollTable.maxOffset = CCSizeMake(mapSize.width-cameraScale * winSize.width,mapSize.height-cameraScale * winSize.height)
    self.scrollTable.beginTime = GamePrecedure:getInstance():getTotalTime()
    self.scrollTable.startPos = ccp(self.multiLayerInfo[1].x , self.multiLayerInfo[1].y)
    self.scrollTable.state = false
    self.scrollTable.acceleSet = false
end

function RAMissionScene:singleBattleSceneTouch(pEvent, touch)

    if pEvent == "began" then
        CCLuaLog('began')
        local point = touch:getLocation()
        local newSpacePos = self:getTouchCityScenePos(point)
        local RABattleSceneManager = RARequire("RABattleSceneManager")
        local tilePos = RABattleSceneManager:spaceToTile(newSpacePos)
        RALogInfo('tilePos:  ' .. tilePos.x .. '  ' .. tilePos.y)
        

        local RAGameConfig = RARequire("RAGameConfig")
        if RAGameConfig.BattleDebug == 1 then
            local spacePos = RABattleSceneManager:tileToSpace(tilePos)
            local node = CCSprite:create('Tile_Green_sNew2.png')
            node:setAnchorPoint(0.5,0.5)
            node:setPosition(spacePos.x,spacePos.y)
        end
    elseif pEvent == "moved" then 
        CCLuaLog('moved')
    elseif pEvent == "ended" then
        CCLuaLog('ended')
        --self:_testMove()
    elseif pEvent == "cancelled" then
        CCLuaLog('cancelled')
    end
end

function RAMissionScene:setMultiTouchEnabled(enable,moveEnabled)
    self.mMultiTouchLayer:setTouchEnabled(enable)
    self.multiLayerInfo = {}

    if moveEnabled ~= nil then 
        self.multiLayerTable.isMoveEnabled = moveEnabled
    else
        self.multiLayerTable.isMoveEnabled = true
    end 
end

function RAMissionScene:initMultiTouchLayer()
    self.mMultiTouchLayer = CCLayer:create()
    self.mMultiTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    self.mMultiTouchLayer:setPosition(0, 0)
    self.mMultiTouchLayer:setAnchorPoint(ccp(0, 0))
    -- self.mMultiTouchLayer:setTouchEnabled(true)
    self.mMultiTouchLayer:setKeypadEnabled(true)
    self.mMultiTouchLayer:setTouchMode(kCCTouchesAllAtOnce)
    self.mRootNode:addChild(self.mMultiTouchLayer)

    local LayerTouches = function (pEvent, touches)
        self:LayerTouches(pEvent, touches)
    end
    self.mMultiTouchLayer:registerScriptTouchHandler(LayerTouches,true, 1 ,false)
    self:setMultiTouchEnabled(true)
end

function RAMissionScene:scrollCamera(touches)
    for i=1,#touches,3 do
        for j=1,#self.multiLayerInfo do
            if self.multiLayerInfo[j].id == touches[i+2] then
                local cameraScale = self.mCamera:getScale()
                local offsetPos = ccp((self.multiLayerInfo[j].x - touches[i])*cameraScale, (self.multiLayerInfo[j].y - touches[i+1])*cameraScale)
                self.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
                self.multiLayerInfo[j].x = touches[i]
                self.multiLayerInfo[j].y = touches[i+1]
                
                local cameraOffSet = self.mCamera:getOffSet()

                if self.scrollTable.startPos ~= nil then 
                    self.scrollTable.distance = ccp(self.multiLayerInfo[j].x - self.scrollTable.startPos.x, self.multiLayerInfo[j].y - self.scrollTable.startPos.y)
                else
                    self.scrollTable.distance = ccp(self.multiLayerInfo[j].x , self.multiLayerInfo[j].y )
                end
                self.scrollTable.acceleSet = true
                self.scrollTable.touchTime = GamePrecedure:getInstance():getTotalTime()
                break
            end
        end
    end
end

function RAMissionScene:LayerTouches(pEvent, touches)

    if self.isCameraMoving == true  then 
        return 
    end 

    if self.isInFirstFight == true then 
        return 
    end 

    if pEvent == "began" then
        for i=1,#touches,3 do
            local touchInfo= {} 
            touchInfo.x = touches[i]
            touchInfo.y = touches[i+1]
            touchInfo.id = touches[i+2]         
            table.insert(self.multiLayerInfo,touchInfo)
            -- CCLuaLog("-------------insert touch-----------------------no."..i.."x:"..touchInfo.x.."y:"..touchInfo.y)
        end
        self:multilayerTouchesBegin()
        -- CCLuaLog("LayerTouches  pEvent, touch, begin")
    elseif pEvent == "moved" then
        if #touches == 6 and self.multiLayerTable.startDis then
            self.multiLayerTable.dragState = false
            self.multiLayerTable.scaleState = true
            local newDis = math.abs(touches[1] - touches[4]) + math.abs(touches[2] - touches[5])
            local scale = self.multiLayerTable.startScale * self.multiLayerTable.startDis/newDis
            local curScale = self.mCamera:getScale()
            --Èç¹ûscaleÎª1 »òÕßscale Îª×î´óscale£¬Ôòreturn£¬²»×öËõ·Å
            if scale > self.mCamera:getMinScale() and scale < self.mCamera:getMaxScale() then
                self.mCamera:setScale(scale,0)
                local originCenterX = (self.multiLayerTable.startTerrain.x - self.mCamera:getOffSet().x)/scale
                local originCenterY = (self.multiLayerTable.startTerrain.y - self.mCamera:getOffSet().y)/scale
                local offSetX = originCenterX - self.multiLayerTable.startCenter.x
                local offSetY = originCenterY - self.multiLayerTable.startCenter.y
                local offsetPos = ccp( offSetX, offSetY)
                self.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
            end
        elseif #touches == 3 and self.multiLayerTable.dragState and self.multiLayerTable.isMoveEnabled then
            self.multiLayerTable.dragState = true
            self.multiLayerTable.scaleState = false
            --[[
            if RABattleSceneManager.castingSkill then
                if RABattleSceneManager.showSkillRange then
                    if self.mSkillNode == nil then
                        local RAFU_Cfg_CastSkill = RARequire('RAFU_Cfg_CastSkill')
                        local img = (RAFU_Cfg_CastSkill[RABattleSceneManager.castingSkillId] or {}).rangeImage
                        if img then
                            local sprite = CCSprite:create(img)
                            sprite:setAnchorPoint(0.5, 0.5)
                            self.mBattleEffectLayer:addChild(sprite)
                            self.mSkillNode = sprite
                        end
                    end
                    local point = ccp(touches[1], touches[2])
                    local screenPoint = self.mRootNode:convertToWorldSpaceAR(point)
                    local newSpacePos = self:getTouchCityScenePos(point)
                    local winSize = CCDirector:sharedDirector():getWinSize()
                    if screenPoint.x > 0 and screenPoint.x < winSize.width and screenPoint.y > 0 and screenPoint.y < (winSize.height - 100) then
                        self:checkIsEdge(screenPoint, newSpacePos)
                        self.mSkillNode:setPosition(newSpacePos.x, newSpacePos.y)
                        RALogRelease('newSpacePos: ' .. newSpacePos.x .. '  y: ' .. newSpacePos.y)
                    end
                    point:delete()
                end

                if self.scrollTable.startPos then
                    local distance = ccp(touches[1] - self.scrollTable.startPos.x, touches[2] - self.scrollTable.startPos.y)
                    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Depart, {offset = distance})
                else
                    self.scrollTable.startPos = ccp(touches[1], touches[2])
                end

                return true
            end
            --]]
            self:scrollCamera(touches)
        end
        
    elseif pEvent == "ended" then
        self:layerTouchesFinish(touches)

        --[[
        if RABattleSceneManager.castingSkill and #touches == 3 then
            self.scrollTable.startPos = nil
            if not RABattleSceneManager.showSkillRange then
                MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Quit)
                return
            end
            local point = ccp(touches[1], touches[2])
            local newSpacePos = self:getTouchCityScenePos(point)
            local RABattleSceneManager = RARequire("RABattleSceneManager")
            local tilePos = RABattleSceneManager:spaceToTile(newSpacePos)
            RALogInfo('tilePos:  ' .. tilePos.x .. '  ' .. tilePos.y)
            RABattleSceneManager:castSkill(tilePos)

            -- TODO
            local this = self
            performWithDelay(self.mSkillNode, function()
                this:removeSkillRangeNode()
           end, 0.6)
            self.scrollTable.startPos = nil
        elseif self.mSkillNode then
            RA_SAFE_REMOVEFROMPARENT(self.mSkillNode)
            self.mSkillNode = nil
        end
        --]]
    elseif pEvent == "cancelled" then
        self:layerTouchesFinish(touches)
    end
end

--初始化镜头
function RAMissionScene:initCamera()
    self.mCamera = SceneCamera:create()
    self.mCamera:registerFunctionHandler(self)
    -- self.min_scale = self.mapConfData.min_scale
    -- self.max_scale = self.mapConfData.max_scale
    self.mCamera:setSize(self.rootSize) 
    -- self.mCamera:setMinScale(self.mapConfData.min_scale)
    -- self.mCamera:setMaxScale(self.mapConfData.max_scale)



    -- local minOffsetX = self.rootSize.width/2 - self.mapConfData.original_width/4
    -- local minOffsetY = self.rootSize.height/2 - self.mapConfData.original_height/4
    
    -- self.mCamera:setMinOffsetY(minOffsetY)
    -- self.mCamera:setMinOffsetX(minOffsetX)
    -- self.mCamera:setMaxOffsetY(-minOffsetY)
    -- self.mCamera:setMaxOffsetX(-minOffsetX)

    -- self.minOffsetX = minOffsetX
    -- self.minOffsetY = minOffsetY


    self.mRootNode:setCamera(self.mCamera) 
    -- self.mCamera:setScale(self.curScale,0.0)
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local pos = RABattleSceneManager:tileToSpace({x=46,y=63})
    self.mCamera:lookAt(ccp(pos.x,pos.y),0.0,false)     
end


--初始化地图
function RAMissionScene:initRootLayer()
    self.mRootNode = CCNode:create()
    self.ccbfile = self.mRootNode

    -- self.mTileMapLayer = CCTMXTiledMap:create('mission_bg_1.tmx')
    self:changeTileMapLayer(battle_map_conf[11])
end

function RAMissionScene:clean()
    self.mBattleUnitLayer:removeAllChildren()
    -- self.mBattleEffectLayer:removeAllChildren()
    -- self.mSurfaceLayer:removeAllChildren()
end

function RAMissionScene:addBattleUnit(battleUnit)
    self.mBattleUnitLayer:addChild(battleUnit.rootNode)
end

function RAMissionScene:changeTileMapLayer(mapData)
    if self.mTileMapLayer ~= nil then 
        self.mTileMapLayer:removeFromParentAndCleanup(true)
    end

    if self.bgCCBHandler ~= nil then 
        UIExtend.unLoadCCBFile(self.bgCCBHandler)
    end 

    if self.mCCBNode == nil then 
        self.mCCBNode = CCNode:create()
        self.mRootNode:addChild(self.mCCBNode)
    end 

    self.mTileMapLayer = CCTMXTiledMap:create(mapData.tmx)

    if self.mTileMapLayer~=nil then
        self.mTileMapBlockLayer = self.mTileMapLayer:layerNamed('block')
        -- self.mTileMapBlockLayer:setVisible(false)
        -- self.mTileMapLayer:setPosition(ccp(0,0))
        -- self.mRootNode:addChild(self.mTileMapLayer)
    end
    
    local size = self.mTileMapLayer:getMapSize()
    self.mMapSizeWidth = size.width
    self.mMapSizeHeight = size.height
    
    local layersize = self.mTileMapLayer:getTileSize()
    self.mTileSizeWidth = layersize.width
    self.mTileSizeHeight = layersize.height

    local totalSize = (self.mMapSizeWidth+self.mMapSizeHeight)/2
    self.rootSize = CCSizeMake(totalSize*self.mTileSizeWidth,totalSize*self.mTileSizeHeight)

    self.mTileMapLayer:setPosition(ccp(0,0))

    local scaledWidth = mapData.original_width * 0.5
    local scaledHeight = mapData.original_height * 0.5

    self.bgCCBHandler = {}
    self.bgCCB =  UIExtend.loadCCBFile(mapData.bg_ccb,self.bgCCBHandler)
    self.bgCCB:setPosition(ccp(self.rootSize.width/2-scaledWidth/2,
        self.rootSize.height/2-scaledHeight/2))
    self.bgCCB:setScale(0.5)
    self.mCCBNode:addChild(self.bgCCB) 

    self.mRootNode:addChild(self.mTileMapLayer)
end

function RAMissionScene:deaccelerateScrolling()
    local originDis = self.scrollTable.distance
    self.scrollTable.distance = ccpMult(originDis, SCROLL_DEACCEL_RATE)
    
    if math.abs(originDis.x) < SCROLL_DEACCEL_DIST and math.abs(originDis.y) < SCROLL_DEACCEL_DIST then
        self.scrollTable.state = false
        return
    end

    local offset = self.mCamera:getOffSet()
    local duringTime = self.scrollTable.endTime - self.scrollTable.beginTime
    
    local param = duringTime*4
    local offsetPos = ccp( 
    (self.scrollTable.distance.x -originDis.x )/param,
    (self.scrollTable.distance.y- originDis.y )/param
    )
    self.mCamera:setOffSet(offsetPos)
    offsetPos:delete()
end

function RAMissionScene:Execute()
    local dt = GamePrecedure:getInstance():getFrameTime()
    -- self:Scrolling()
    -- self.mFightPlay:Execute(dt)
end