RARequire('RAFightDefine')
local UIExtend = RARequire('UIExtend')
RARequire("MessageDefine")
RARequire("MessageManager")
local RAFightManager = RARequire('RAFightManager')
local RABattleSceneManager = RARequire('RABattleSceneManager')
local RAFightUnitFactory = RARequire('RAFightUnitFactory')
local EnumManager = RARequire('EnumManager')
-- local RAFightPlay = RARequire('RAFightPlay')
local RABattleScene = BaseFunctionPage:new(...)
local RAFightUI = RARequire('RAFightUI')

local SCROLL_DEACCEL_RATE  = 0.85
local SCROLL_DEACCEL_DIST  = 1.0

function RABattleScene:reset()
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

    self.mSkillNode = nil
    self.mSkillNodeDict = {}

    self.loadedOver = true
    self.loadStep = 1
   
end

function RABattleScene:Execute()
    if self.loadedOver ~= true then 
        self:doLoadScene()
        return 
    end
    local dt = GamePrecedure:getInstance():getFrameTime()
    self:Scrolling()
    self.mFightPlay:Execute(dt)
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_BattleScene.MSG_CameraMoving_Start then
        RABattleScene:moveCamera(message.data)
    end
end 

function RABattleScene:moveCamera(cameraData)
    local pos = RABattleSceneManager:tileToSpace(cameraData)
    self.isCameraMoving = true

    if cameraData.scale then
    	if self.max_scale and cameraData.scale > self.max_scale then 
    		cameraData.scale = self.max_scale
    	end  

    	if self.min_scale and cameraData.scale < self.min_scale then 
    		cameraData.scale = self.min_scale
    	end 

        self.mCamera:setScale(cameraData.scale, cameraData.time)
    end 
    if cameraData.time == 0 then 
        self.mCamera:lookAt(ccp(pos.x,pos.y),cameraData.time,true)
        -- self.mCamera:setScale(cameraData.scale, cameraData.time)
        self:onMovingFinish()
    else 
        self.mCamera:lookAt(ccp(pos.x,pos.y),cameraData.time,false)
        -- self.mCamera:setScale(cameraData.scale, cameraData.time)
    end 

    if cameraData.type == 2 then 
        if cameraData.itemId ~= nil then
            local unit =  RABattleSceneManager:getUnitByConfId(cameraData.itemId)
            if unit then
                unit:whiteFlashBuff({})
            end
        end
        
    elseif cameraData.type == 3 then 
        if cameraData.movePeriod ~= nil then
            RABattleSceneManager:attackersWalk(cameraData.movePeriod)
        end
        
    end 
end

function RABattleScene:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end

function RABattleScene:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)
end

function RABattleScene:Enter(data)
    
   self.startTime =  CCTime:getCurrentTime()
    local common = RARequire('common')
    common:addSpriteFramesWithFile('Army_Effect_1.plist','Army_Effect_1.png')
	self.data = data or {}
	
    -- MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus, {isShow = false})
    -- MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
    self:reset()
    self:registerMessage()

    --初始化场景管理
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    RABattleSceneManager:init(self)
    
    local TestData = RARequire('TestData')
    local RAGameConfig = RARequire('RAGameConfig')
    if RAGameConfig.BattleDebug == 1 then
       data = data or {}  
    end
    local battleParams,missionId = TestData:getData(data.missionId,data.troopText) --测试数据
	RAFightManager:initBattleParams(battleParams)
    --初始化场景
    RAFightManager:init(missionId, self.data.dungeonId)

    self.mapConfData = RAFightManager:getMapConfData()
    
    self:initRootLayer()


   -- self:initDebugLayer()
   self:initSurfaceLayer()
   self:initBattleUnitLayer()
   self:initBattleEffectLayer()
   self:initCamera()
   self:initTouchLayer()
   self:initMultiTouchLayer()

   local RARootManager = RARequire('RARootManager')
   local RAGameConfig = RARequire('RAGameConfig')
   local RAGuideManager = RARequire('RAGuideManager')
   -- if RAGameConfig.BattleDebug == 0 then

   --     if RAGameConfig.
   --     self.mFightPlay = RARequire('RAFightPlay')
   --     self.mFightPlay:init(true, data.reward)
   --     self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
   -- else --调试模式
   --     self.mFightPlay = RARequire('RAFightPlay')
   --     self.mFightPlay:init(true, data.reward)
   --     self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
   --     -- self.mfightUI = UIExtend.GetPageHandler("RAFightDebugUI")    
   -- end
   --desc：判断是否进入第一场战斗，第一场战斗特殊处理了，在剧情的时候进入。
   self.isInFirstFight = RAGuideManager.isInGuide() and (RAGuideManager.getCurrentGuideId() == 0)
   if self.isInFirstFight == true then --在新手，且在第一次剧情中才走
       self.mFightPlay = RARequire('RAFirstFightPlay')
       self.mFightPlay:init(true, data.reward)
       self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
       self.mfightUI:Enter()
       self.mfightUI:setVisible(false)
   else 
       self.mFightPlay = RARequire('RAFightPlay')
       self.mFightPlay:init(true,data.reward)
       self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
       self.mfightUI:Enter()
       self.mfightUI:setVisible(true)
   end 

   UIExtend.AddPageToNode(self.mfightUI, RARootManager.mGUINode)
   local b =  CCTime:getCurrentTime()
   -- print(b-self.startTime)
   -- print("calBattle")
   RAFightManager:calBattle(self.mMapSizeWidth,self.mMapSizeHeight,self.mTileMapBlockLayer)
   -- local c =  CCTime:getCurrentTime()
   -- print (c-b)
   self.mFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.INIT_BATTLE)

   -- local e =  CCTime:getCurrentTime()
   -- print(e-c)
   -- print(e-self.startTime)
--   CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
end

function RABattleScene:doLoadScene()
    if self.loadStep == 1 then
        self.loadStep = 2
        self:initSurfaceLayer()
        self:initBattleUnitLayer()
    elseif self.loadStep == 2 then 
        self:initSurfaceLayer()
        self:initBattleUnitLayer()
        self:initBattleEffectLayer()
        self.loadStep = 10
    elseif self.loadStep == 10 then

        self:initCamera()
        self:initTouchLayer()
        self:initMultiTouchLayer()
        self.loadStep = 20
    elseif self.loadStep == 20 then
        local RARootManager = RARequire('RARootManager')
        local RAGameConfig = RARequire('RAGameConfig')
        local RAGuideManager = RARequire('RAGuideManager')

        self.isInFirstFight = RAGuideManager.isInGuide() and (RAGuideManager.getCurrentGuideId() == 0)
        if self.isInFirstFight == true then --在新手，且在第一次剧情中才走
            self.mFightPlay = RARequire('RAFirstFightPlay')
            self.mFightPlay:init(true, self.data.reward)
            self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
            self.mfightUI:Enter()
            self.mfightUI:setVisible(false)
        else 
            self.mFightPlay = RARequire('RAFightPlay')
            self.mFightPlay:init(true, self.data.reward)
            self.mfightUI = UIExtend.GetPageHandler("RAFightUI")
            self.mfightUI:Enter()
            self.mfightUI:setVisible(true)
        end 

        UIExtend.AddPageToNode(self.mfightUI, RARootManager.mGUINode)
         self.loadStep = 21   
     elseif   self.loadStep == 21 then
        RAFightManager:calBattle(self.mMapSizeWidth,self.mMapSizeHeight,self.mTileMapBlockLayer)
        self.loadStep = 500
        
--        RABattleSceneManager:cleanScene()
    elseif self.loadStep == 500 then
--        self.loadStep = self.mFightPlay:loadFightUnits()
         self.loadStep =1000
    elseif self.loadStep == 1000 then
        self.loadedOver = true
       
        self.mFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.INIT_BATTLE)
        local tiemend = CCTime:getCurrentTime()
        print(tiemend - self.startTime)
        print("fuckkkkk")
    end
end 

function RABattleScene:doFightTest()
    local TestData = RARequire('TestData')
    local battleParams = TestData:getData() --测试数据
    RAFightManager:initBattleParams(battleParams)
    RAFightManager:calBattle(self.mMapSizeWidth,self.mMapSizeHeight,self.mTileMapBlockLayer)
    self.mFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.INIT_BATTLE,true)
end

function RABattleScene:doGMFightTest()
    local TestData = RARequire('TestData')
    local battleParams = TestData:getGMData() --测试数据
    RAFightManager:initBattleParams(battleParams)
    RAFightManager:calBattle(self.mMapSizeWidth,self.mMapSizeHeight,self.mTileMapBlockLayer)
    self.mFightPlay:updateState(FIGHT_PLAY_STATE_TYPE.INIT_BATTLE,true)
end

function RABattleScene:addBattleUnit(battleUnit)
    self.mBattleUnitLayer:addChild(battleUnit.rootNode)
end

function RABattleScene:onMovingFinish()
    self.isCameraMoving = false
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CameraMoving_Finished)
end

-- 获取当前战斗播放加速倍数
function RABattleScene:getSpeedScale()
	if self.mFightPlay then
		return self.mFightPlay:getSpeedScale()
	end
	return 1
end

--初始化地图
function RABattleScene:initRootLayer()

    self.mRootNode = CCNode:create()
    self.ccbfile = self.mRootNode

    local mapName = RAFightManager:getTmxName()
    self.mTileMapLayer = CCTMXTiledMap:create(mapName)
    
    local size = self.mTileMapLayer:getMapSize()
    self.mMapSizeWidth = size.width
    self.mMapSizeHeight = size.height
    
    local layersize = self.mTileMapLayer:getTileSize()
    self.mTileSizeWidth = layersize.width
    self.mTileSizeHeight = layersize.height

    local totalSize = (self.mMapSizeWidth+self.mMapSizeHeight)/2
    self.rootSize = CCSizeMake(totalSize*self.mTileSizeWidth,totalSize*self.mTileSizeHeight)
    
    local mapData = RAFightManager:getMapConfData()

    local ccbName = mapData.bg_ccb
    local scaledWidth = mapData.original_width * 0.5
    local scaledHeight = mapData.original_height * 0.5

    self.bgCCBHandler = {}
    self.bgCCB =  UIExtend.loadCCBFile(ccbName,self.bgCCBHandler)
    self.bgCCB:setPosition(ccp(self.rootSize.width/2-scaledWidth/2,
        self.rootSize.height/2-scaledHeight/2))
    self.bgCCB:setScale(0.5)
    self.mRootNode:addChild(self.bgCCB)
    
    --设置技能战船位置
    local Utilitys = RARequire("Utilitys")
    local shipPos = Utilitys.getCcpFromString(mapData.ship_pos,'_')
    RARequire("RAFightSkillSystem"):setSkillFirePos(shipPos)

    --self.mRootNode:addChild(self.bgCCB)

    -- self.bgNode = CCSprite:create(mapData.bg_pic)
    -- self.bgNode:setPosition(ccp(self.rootSize.width/2,self.rootSize.height/2))
    

    if self.mTileMapLayer~=nil then
        self.mTileMapBlockLayer = self.mTileMapLayer:layerNamed('block')
        self.mTileMapBlockLayer:setVisible(false)
        self.mTileMapLayer:setPosition(ccp(0,0))
        self.mRootNode:addChild(self.mTileMapLayer)
    end	
end

function RABattleScene:clean()
    self.mBattleUnitLayer:removeAllChildren()
    self.mBattleEffectLayer:removeAllChildren()
    self.mSurfaceLayer:removeAllChildren()
end

function RABattleScene:initDebugLayer()
    self.mDebugLayer = CCLayer:create()
    self.mDebugLayer:setPosition(0, 0)
    self.mDebugLayer:setAnchorPoint(ccp(0, 0))    
    self.mRootNode:addChild(self.mDebugLayer)
    self.mDebugLayer:setVisible(false)
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    -- local spacePos = RABattleSceneManager:tileToSpace(tilePos)
    for i=0,self.mMapSizeWidth-1 do
        for j=0,self.mMapSizeHeight -1 do
            if i%4 == 0 or i%4==1 then 
                if j%4 == 0 or j %4 == 1 then 
                    local node = CCSprite:create('Tile_Green_sNew2.png')
                    node:setAnchorPoint(0.5,0.5)
                    local spacePos = RABattleSceneManager:tileToSpace({x=i,y=j})
                    node:setPosition(spacePos.x,spacePos.y)
                    self.mDebugLayer:addChild(node)
                else
                    local node = CCSprite:create('Tile_Red_sNew2.png')
                    node:setAnchorPoint(0.5,0.5)
                    local spacePos = RABattleSceneManager:tileToSpace({x=i,y=j})
                    node:setPosition(spacePos.x,spacePos.y)
                    self.mDebugLayer:addChild(node)
                end
            else
                if j%4 == 0 or j %4 == 1 then 
                    local node = CCSprite:create('Tile_Red_sNew2.png')
                    node:setAnchorPoint(0.5,0.5)
                    local spacePos = RABattleSceneManager:tileToSpace({x=i,y=j})
                    node:setPosition(spacePos.x,spacePos.y)
                    self.mDebugLayer:addChild(node)
                else
                    local node = CCSprite:create('Tile_Green_sNew2.png')
                    node:setAnchorPoint(0.5,0.5)
                    local spacePos = RABattleSceneManager:tileToSpace({x=i,y=j})
                    node:setPosition(spacePos.x,spacePos.y)
                    self.mDebugLayer:addChild(node)
                end
            end
        end
    end
end

function RABattleScene:initSurfaceLayer()
    self.mSurfaceLayer = CCLayer:create()
    self.mSurfaceLayer:setPosition(0, 0)
    self.mSurfaceLayer:setAnchorPoint(ccp(0, 0))    
    self.mRootNode:addChild(self.mSurfaceLayer)
end


function RABattleScene:initBattleUnitLayer()
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

function RABattleScene:initBattleEffectLayer()
    self.mBattleEffectLayer = CCLayer:create()
    self.mBattleEffectLayer:setPosition(0, 0)
    self.mBattleEffectLayer:setAnchorPoint(ccp(0, 0))    
    self.mRootNode:addChild(self.mBattleEffectLayer)
end

--初始化镜头
function RABattleScene:initCamera()
    self.mCamera = SceneCamera:create()
    self.mCamera:registerFunctionHandler(self)
    self.min_scale = self.mapConfData.min_scale
    self.max_scale = self.mapConfData.max_scale
    self.mCamera:setSize(self.rootSize) 
    self.mCamera:setMinScale(self.mapConfData.min_scale)
    self.mCamera:setMaxScale(self.mapConfData.max_scale)



    local minOffsetX = self.rootSize.width/2 - self.mapConfData.original_width/4
    local minOffsetY = self.rootSize.height/2 - self.mapConfData.original_height/4
    
    self.mCamera:setMinOffsetY(minOffsetY)
    self.mCamera:setMinOffsetX(minOffsetX)
    self.mCamera:setMaxOffsetY(-minOffsetY)
    self.mCamera:setMaxOffsetX(-minOffsetX)

    self.minOffsetX = minOffsetX
    self.minOffsetY = minOffsetY


    self.mRootNode:setCamera(self.mCamera) 
    self.mCamera:setScale(self.curScale,0.0)
    local pos = RABattleSceneManager:tileToSpace({x=46,y=63})
    self.mCamera:lookAt(ccp(pos.x,pos.y),0.0,false)     
end

function RABattleScene:isSetOffset(isSet)
    if isSet then 
        self.mCamera:setMinOffsetY(self.minOffsetY)
        self.mCamera:setMinOffsetX(self.minOffsetX)
        self.mCamera:setMaxOffsetY(-self.minOffsetY)
        self.mCamera:setMaxOffsetX(-self.minOffsetX)
    else
        self.mCamera:setMinOffsetY(0)
        self.mCamera:setMinOffsetX(0)
        self.mCamera:setMaxOffsetY(0)
        self.mCamera:setMaxOffsetX(0)
    end 
end

--初始化触摸层
function RABattleScene:initTouchLayer()
    self.mTouchLayer = CCLayer:create()
    self.mTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    self.mTouchLayer:setPosition(0, 0)
    self.mTouchLayer:setAnchorPoint(ccp(0, 0))
    self.mTouchLayer:setTouchEnabled(true)
    self.mTouchLayer:setKeypadEnabled(true)
    self.mTouchLayer:setTouchMode(kCCTouchesOneByOne)
    self.mRootNode:addChild(self.mTouchLayer)
    self.isCameraMoving = false
    local singleBattleSceneTouch = function(pEvent, touch)
        self:singleBattleSceneTouch(pEvent, touch) 
    end

    self.mTouchLayer:registerScriptTouchHandler(singleBattleSceneTouch) 
end

function RABattleScene:initMultiTouchLayer()
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

--GM命令使用
function RABattleScene:showBlockLayer()
    self.mTileMapBlockLayer:setVisible(not self.mTileMapBlockLayer:isVisible())
end

function RABattleScene:subScale()
    self.curScale = self.curScale - 0.1
    self.mCamera:setScale(self.curScale,0.0)
    RALogInfo("RABattleScene:subScale self.curScale :"..self.curScale)
    self.mCamera:lookAt(ccp(self.rootSize.width/2,self.rootSize.height/2),0.0,false)     
end

function RABattleScene:addScale()
    self.curScale = self.curScale + 0.1
    self.mCamera:setScale(self.curScale,0.0)
    RALogInfo("RABattleScene:addScale self.curScale :"..self.curScale)
    self.mCamera:lookAt(ccp(self.rootSize.width/2,self.rootSize.height/2),0.0,false)     
end

function RABattleScene:getTouchCityScenePos(point)
    local cameraOffSet = self.mCamera:getOffSet()
    local cameraScale = self.mCamera:getScale()
    local terrainPos = RACcp(cameraOffSet.x + point.x * cameraScale,cameraOffSet.y + point.y * cameraScale)
    return terrainPos
end

function RABattleScene:setMultiTouchEnabled(enable,moveEnabled)
    self.mMultiTouchLayer:setTouchEnabled(enable)
    self.multiLayerInfo = {}

    if moveEnabled ~= nil then 
        self.multiLayerTable.isMoveEnabled = moveEnabled
    else
        self.multiLayerTable.isMoveEnabled = true
    end 
end

function RABattleScene:scrollToucheBegin()
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

function RABattleScene:multilayerTouchesBegin()
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

function RABattleScene:scrollCamera(touches)
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

function RABattleScene:LayerTouches(pEvent, touches)

    if self.mFightPlay:getCurrentState() == FIGHT_PLAY_STATE_TYPE.START_BATTLE then 
        self.isCameraMoving = false
        if self.mFightPlay.stopMoveFightCamera then 
            self.mFightPlay:stopMoveFightCamera()
        end
    end 

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

function RABattleScene:removeSkillRangeNode(params)
	RA_SAFE_REMOVEFROMPARENT(self.mSkillNode)
	self.mSkillNode = nil

	params = params or {}
	if params.tilePos == nil or params.skillId == nil then return end

	local key = string.format('%d_%d_%d', params.tilePos.x, params.tilePos.y, params.skillId)
	local node = self.mSkillNodeDict[key]
	RA_SAFE_REMOVEFROMPARENT(node)
	self.mSkillNodeDict[key] = nil
end

function RABattleScene:removeTouches(touches)
    for i=1,#touches,3 do
        for j=1,#self.multiLayerInfo do
            if self.multiLayerInfo[j].id == touches[i+2] then
                table.remove(self.multiLayerInfo,j)
                break
            end
        end
    end
end

function RABattleScene:layerTouchesFinish(touches)
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

function RABattleScene:checkIsEdge(screenPoint,newSpacePos)
    
	local winSize = CCDirector:sharedDirector():getWinSize()
    if screenPoint.x <100 or screenPoint.x >540 
    or screenPoint.y <100 or screenPoint.y >(winSize.height-200) then

        local centerSpacePos =  self:convertScreenPos2TerrainPos(RACcp(winSize.width/2, winSize.height/2))
        local newSpace = ccp((centerSpacePos.x + newSpacePos.x  )/2,(centerSpacePos.y + newSpacePos.y )/2) 

        self.mCamera:lookAt(newSpace,0.5,false)
        newSpace:delete()
    end
end

function RABattleScene:convertScreenPos2TerrainPos(position)
    local cameraOffSet = self.mCamera:getOffSet()
	local cameraScale = self.mCamera:getScale()
	local terrainPos = RACcp(cameraOffSet.x + position.x * cameraScale,cameraOffSet.y + position.y * cameraScale)
	return terrainPos
end

function RABattleScene:Exit()
    if self.mCamera then
        self.mCamera:unregisterFunctionHandler()
        self.mCamera = nil 
    end

    for k, node in pairs(self.mSkillNodeDict) do
    	RA_SAFE_REMOVEFROMPARENT(node)
    end
    self.mSkillNodeDict = {}
    
    UIExtend.unLoadCCBFile(self.bgCCBHandler)

    self:removeMessageHandler()
    RAFightManager:Exit()
    RABattleSceneManager:Exit()
    self.ccbfile:removeAllChildren()
    self.mfightUI:Exit()
    self.mFightPlay:Exit()
    -- UIExtend.AddPageToNode(self.mfightUI, RARootManager.mGUINode)
    -- UIExtend.unLoadCCBFile(self) 

end

function RABattleScene:singleBattleSceneTouch(pEvent, touch)

    if self.isCameraMoving == true then 
        return 
    end 

    if pEvent == "began" then
        CCLuaLog('began')
        local point = touch:getLocation()
        local newSpacePos = self:getTouchCityScenePos(point)
        local RABattleSceneManager = RARequire("RABattleSceneManager")
        local tilePos = RABattleSceneManager:spaceToTile(newSpacePos)
        RALogInfo('tilePos:  ' .. tilePos.x .. '  ' .. tilePos.y)
        
        if RABattleSceneManager.castingSkill then
        	self:_addSkillCastingEffect(point, newSpacePos, tilePos)
        end

        if RABattleSceneManager.touchDebug then
            for k,v in pairs(RABattleSceneManager.battleUnits) do
                local fireData = {
                    targetSpacePos = newSpacePos
                }
                if v.weapon then
                    v.weapon:StartFire(fireData)
                end
                -- local moveData = {
                --     fromPos = v.tilePos,
                --     targetPos = tilePos,
                --     isDebug = true
                -- }
                -- v:changeState(STATE_TYPE.STATE_FLY, moveData)
            end
        end
        
        


        local RAGameConfig = RARequire("RAGameConfig")
        if RAGameConfig.BattleDebug == 1 then
            local spacePos = RABattleSceneManager:tileToSpace(tilePos)
            local node = CCSprite:create('Tile_Green_sNew2.png')
            node:setAnchorPoint(0.5,0.5)
            node:setPosition(spacePos.x,spacePos.y)
            -- self.mBattleEffectLayer:addChild(node)
        end

        -- CCLuaLog('spacePos:  ' .. spacePos.x .. '  ' .. spacePos.y)
        -- local ccpos = self.mTileMapBlockLayer:positionAt(ccp(tilePos.x,tilePos.y))
        -- CCLuaLog('ccpos:  ' .. ccpos.x .. '  ' .. ccpos.y)
        --self:_testMove()
    elseif pEvent == "moved" then 
        CCLuaLog('moved')
    elseif pEvent == "ended" then
        CCLuaLog('ended')
        --self:_testMove()
    elseif pEvent == "cancelled" then
        CCLuaLog('cancelled')
    end
end

function RABattleScene:Scrolling()
    if self.scrollTable.state then 
        self:deaccelerateScrolling()
    end 
end

function RABattleScene:deaccelerateScrolling()
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

function RABattleScene:isInDragState()
    return self.multiLayerTable.dragState
end

function RABattleScene:isInScaleState()
    return self.multiLayerTable.scaleState
end

function RABattleScene:_addSkillCastingEffect(point, newSpacePos, tilePos)
	local RAFU_Cfg_CastSkill = RARequire('RAFU_Cfg_CastSkill')
	local skillId = RABattleSceneManager.castingSkillId
	local img = (RAFU_Cfg_CastSkill[skillId] or {}).rangeImage
	if img == nil then return end

	local sprite = CCSprite:create(img)
	sprite:setAnchorPoint(0.5, 0.5)
	self.mBattleEffectLayer:addChild(sprite)
	local skillNode = sprite

	local screenPoint = self.mRootNode:convertToWorldSpaceAR(point)
	local winSize = CCDirector:sharedDirector():getWinSize()
	if screenPoint.x > 0 and screenPoint.x < winSize.width and screenPoint.y > 0 and screenPoint.y < (winSize.height - 100) then
		self:checkIsEdge(screenPoint, newSpacePos)
		skillNode:setPosition(newSpacePos.x, newSpacePos.y)
		RALogRelease('newSpacePos: ' .. newSpacePos.x .. '  y: ' .. newSpacePos.y)
	end
	point:delete()

	RABattleSceneManager:castSkill(tilePos)

	local key = string.format('%d_%d_%d', tilePos.x, tilePos.y, skillId)
	self.mSkillNodeDict[key] = skillNode
	-- TODO
	-- local this = self
	-- performWithDelay(skillNode, function()
	-- 	RA_SAFE_REMOVEFROMPARENT(skillNode)
	-- end, 0.6)
end