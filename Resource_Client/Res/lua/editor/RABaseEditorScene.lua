local UIExtend = RARequire('UIExtend')
RARequire('extern')
RARequire('BasePage')
local RABaseEditorScene = class('RABaseEditorScene',BaseFunctionPage:new())


function RABaseEditorScene:ctor(...)
end

function RABaseEditorScene:reset()
    self.mRootNode = nil --底图
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
end

function RABaseEditorScene:Enter(data)

    self:reset()

    self:initRootLayer()
    self:initCamera()
    self:initTouchLayer()
    self:initMultiTouchLayer()
    self:initMenu()
end

function RABaseEditorScene:multilayerTouchesBegin()
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

function RABaseEditorScene:initMenu()
    
end

--初始化触摸层
function RABaseEditorScene:initTouchLayer()
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

function RABaseEditorScene:removeTouches(touches)
    for i=1,#touches,3 do
        for j=1,#self.multiLayerInfo do
            if self.multiLayerInfo[j].id == touches[i+2] then
                table.remove(self.multiLayerInfo,j)
                break
            end
        end
    end
end

function RABaseEditorScene:isInDragState()
    return self.multiLayerTable.dragState
end

function RABaseEditorScene:isInScaleState()
    return self.multiLayerTable.scaleState
end

function RABaseEditorScene:Scrolling()
    if self.scrollTable.state then 
        self:deaccelerateScrolling()
    end 
end

function RABaseEditorScene:layerTouchesFinish(touches)
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

function RABaseEditorScene:scrollToucheBegin()
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

function RABaseEditorScene:singleBattleSceneTouch(pEvent, touch)

    if pEvent == "began" then
        CCLuaLog('began')
    elseif pEvent == "moved" then 
        CCLuaLog('moved')
    elseif pEvent == "ended" then
        CCLuaLog('ended')
    elseif pEvent == "cancelled" then
        CCLuaLog('cancelled')
    end
end

function RABaseEditorScene:setMultiTouchEnabled(enable,moveEnabled)
    self.mMultiTouchLayer:setTouchEnabled(enable)
    self.multiLayerInfo = {}

    if moveEnabled ~= nil then 
        self.multiLayerTable.isMoveEnabled = moveEnabled
    else
        self.multiLayerTable.isMoveEnabled = true
    end 
end


function RABaseEditorScene:initMultiTouchLayer()
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


function RABaseEditorScene:scrollCamera(touches)
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

function RABaseEditorScene:LayerTouches(pEvent, touches)

    if self.isCameraMoving == true  then 
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
            self:scrollCamera(touches)
        end
        
    elseif pEvent == "ended" then
        self:layerTouchesFinish(touches)
    elseif pEvent == "cancelled" then
        self:layerTouchesFinish(touches)
    end
end

--初始化镜头
function RABaseEditorScene:initCamera()
    self.mCamera = SceneCamera:create()
    self.mCamera:registerFunctionHandler(self)

    if self.rootSize == nil then 
        self.rootSize = CCDirector:sharedDirector():getOpenGLView():getVisibleSize()
    end 
        
    self.mCamera:setSize(self.rootSize) 
    

    self.mRootNode:setCamera(self.mCamera)     
end

--初始化地图
function RABaseEditorScene:initRootLayer()
    self.mRootNode = CCNode:create()
    self.ccbfile = self.mRootNode

    -- local battle_map_conf = RARequire('battle_map_conf')
    -- local mapData = battle_map_conf[13]
    -- self.mTileMapLayer = CCTMXTiledMap:create(mapData.tmx)

    -- if self.mTileMapLayer~=nil then
    --     self.mTileMapBlockLayer = self.mTileMapLayer:layerNamed('block')
    -- end
    
    -- local size = self.mTileMapLayer:getMapSize()
    -- self.mMapSizeWidth = size.width
    -- self.mMapSizeHeight = size.height
    
    -- local layersize = self.mTileMapLayer:getTileSize()
    -- self.mTileSizeWidth = layersize.width
    -- self.mTileSizeHeight = layersize.height

    -- local totalSize = (self.mMapSizeWidth+self.mMapSizeHeight)/2
    -- self.rootSize = CCSizeMake(totalSize*self.mTileSizeWidth,totalSize*self.mTileSizeHeight)

    -- self.mTileMapLayer:setPosition(ccp(0,0))

    -- local scaledWidth = mapData.original_width * 0.5
    -- local scaledHeight = mapData.original_height * 0.5

    -- self.bgCCBHandler = {}
    -- self.bgCCB =  UIExtend.loadCCBFile(mapData.bg_ccb,self.bgCCBHandler)
    -- self.bgCCB:setPosition(ccp(self.rootSize.width/2-scaledWidth/2,
    --     self.rootSize.height/2-scaledHeight/2))
    -- self.bgCCB:setScale(0.5)
    -- self.mRootNode:addChild(self.bgCCB) 

    -- self.mRootNode:addChild(self.mTileMapLayer)
end

function RABaseEditorScene:deaccelerateScrolling()
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

function RABaseEditorScene:Execute()
end

return RABaseEditorScene.new()