--FileName :RACityScene 
--Author: zhenhui 2016/5/24

RARequire("RACityMultiLayerTouch")
local RABuildManager = RARequire('RABuildManager')

local RACityScene = BaseFunctionPage:new(...)
local RACitySceneManager = RARequire("RACitySceneManager")
local RACitySceneConfig = RARequire("RACitySceneConfig")
local RAGuideManager = RARequire('RAGuideManager')
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
_G["RACityScene"] = RACityScene
local HP_pb = RARequire("HP_pb")


RACityScene.mRootNode =nil

RACityScene.mTileMapLayer =nil
RACityScene.mTileMapGroundLayer =nil
RACityScene.mTileBlockLayer =nil
RACityScene.mBuildSpineLayer =nil
RACityScene.mTroopLayer = nil
RACityScene.mBuildUILayer =nil
RACityScene.mBuildNameLayer =nil
RACityScene.mTouchLayer =nil
RACityScene.mMultiTouchLayer =nil
RACityScene.mTroopGatherCell = {}
RACityScene.mCamera =nil

RACityScene.mGatherPos = {}
RACityScene.isRain = false 

--背景音乐2播放标示
local cityMusicLoopTag = false

function RACityScene:resetData()
    
    RACityScene.mRootNode =nil
    RACityScene.mTileMapLayer =nil
    RACityScene.mTileMapGroundLayer =nil
    RACityScene.mTileBlockLayer = nil 
    RACityScene.mBuildLayer = nil 
    RACityScene.mBuildSpineLayer =nil
    RACityScene.mTroopLayer = nil
    RACityScene.mBuildUILayer =nil
    RACityScene.mBuildNameLayer =nil
    RACityScene.mTouchLayer =nil
    RACityScene.mMultiTouchLayer =nil
    RACityScene.mCamera =nil   
    RACityScene.mGatherPos = {}

end

local RARain = {}
--构造函数
function RARain:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RARain:init()
    UIExtend.loadCCBFile("Ani_City_Rain.ccbi",self)
end

function RACityScene:onMovingFinish()
    -- CCLuaLog('this is a test')
    self.isCameraMoving = false

    MessageManager.sendMessage(MessageDef_Building.MSG_Moving_Finished)
end

function RACityScene:_initRootNodeNLayer()
    --step.1 create the root node
	RACityScene.mRootNode = UIExtend.loadCCBFileWithOutPool("RACityScene.ccbi",self);
    
    --init the camera
    RACityScene.mCamera = SceneCamera:create()
    RACityScene.mCamera:registerFunctionHandler(self)
    self.isCameraMoving = false
    local rect = RACitySceneConfig.tileInfo.tmxTotalRect
    RACityScene.mCamera:setSize(rect.size)
    local minOffsetX = -160  
    RACityScene.mCamera:setMinOffsetY(-360)
    RACityScene.mCamera:setMinOffsetX(minOffsetX)
    RACityScene.mCamera:setMaxOffsetY(360)
    RACityScene.mCamera:setMaxOffsetX(-minOffsetX)
    RACityScene.mCamera:setMinScale(RACitySceneConfig.cameraInfo.minScale)
    local maxScale = RACityScene.mCamera:getMaxScale()
    RACityScene.mCamera:setMaxScale(RACitySceneConfig.cameraInfo.maxScaleRate * maxScale )
    RACitySceneManager.sceneCamera = RACityScene.mCamera
    RACityScene.mRootNode:setCamera(RACityScene.mCamera)

    --step.2 create the tmx layer
    RACityScene.mTileMapLayer = CCTMXTiledMap:create(RACitySceneConfig.tileInfo.tmxFile)
    if RACityScene.mTileMapLayer~=nil then
        self.mTileMapGroundLayer = self.mTileMapLayer:layerNamed(RACitySceneConfig.tileInfo.tmxTileLayerName);
        self.mTileBlockLayer = self.mTileMapLayer:layerNamed(RACitySceneConfig.tileInfo.tmxTileBlockLayerName);
        AStarPathManager:getInstance():setBlock(self.mTileBlockLayer)
        assert(self.mTileBlockLayer~=nil ,"self.mTileBlockLayer~=nil" )
        assert(self.mTileMapGroundLayer~=nil ,"self.mTileMapGroundLayer~=nil" )
        --RACitySceneManager:setDebugModel(false)
        RACitySceneManager.m_tileSize = self.mTileMapGroundLayer:getMapTileSize();
        RACitySceneManager.m_layerSize = self.mTileMapGroundLayer:getLayerSize()
        self.mTileMapGroundLayer:setVisible(false)
        RACitySceneManager.backGroundFlag = false
        self.mTileBlockLayer:setVisible(false)
        RACityScene.mTileMapLayer:setPosition(ccp(0,0))
        RACityScene.mRootNode:addChild(RACityScene.mTileMapLayer)
    end

    RACityScene.mBuildLayer = CCLayer:create()
    RACityScene.mBuildLayer:setPosition(0, 0)
    RACityScene.mBuildLayer:setAnchorPoint(ccp(0, 0))    
    RACityScene.mRootNode:addChild(RACityScene.mBuildLayer)

    --step.3 create the build layer
    RACityScene.mBuildSpineLayer = CCLayer:create()
    RACityScene.mBuildSpineLayer:setPosition(0, 0)
    RACityScene.mBuildSpineLayer:setAnchorPoint(ccp(0, 0))    
    RACityScene.mRootNode:addChild(RACityScene.mBuildSpineLayer)

     --step.4 create the troop layer
    RACityScene.mTroopLayer = CCLayer:create()
    RACityScene.mTroopLayer:setPosition(0, 0)
    RACityScene.mTroopLayer:setAnchorPoint(ccp(0, 0))    
    RACityScene.mRootNode:addChild(RACityScene.mTroopLayer)

    --step.4 create the single touch layer and multi touch layer
    RACityScene.mTouchLayer = CCLayer:create()
    RACityScene.mTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    RACityScene.mTouchLayer:setPosition(0, 0)
    RACityScene.mTouchLayer:setAnchorPoint(ccp(0, 0))
    RACityScene.mTouchLayer:setTouchEnabled(true)
    RACityScene.mTouchLayer:setKeypadEnabled(true)
    RACityScene.mTouchLayer:setTouchMode(kCCTouchesOneByOne)
    RACityScene.mRootNode:addChild(RACityScene.mTouchLayer)
    RACityScene.mTouchLayer:registerScriptTouchHandler(RACitySceneManager.singleCitySceneTouch)	

    RACityScene.mMultiTouchLayer = CCLayer:create()
    RACityScene.mMultiTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    RACityScene.mMultiTouchLayer:setPosition(0, 0)
    RACityScene.mMultiTouchLayer:setAnchorPoint(ccp(0, 0))
    RACityScene.mMultiTouchLayer:setTouchEnabled(false)
    RACityScene.mMultiTouchLayer:setKeypadEnabled(true)
    RACityScene.mMultiTouchLayer:setTouchMode(kCCTouchesAllAtOnce)
    RACityScene.mRootNode:addChild(RACityScene.mMultiTouchLayer)
    RACityScene.mMultiTouchLayer:registerScriptTouchHandler(RACityMultiLayerTouch.LayerTouches,true, 1 ,false)
    RACityMultiLayerTouch.setEnabled(true)
    --RACityScene.mCamera:setScale(1.0)

    --step.5 create the UI and Name layer
    RACityScene.mBuildUILayer = CCLayer:create()
    RACityScene.mBuildUILayer:setPosition(0, 0)
    RACityScene.mBuildUILayer:setAnchorPoint(ccp(0, 0))    
    RACityScene.mRootNode:addChild(RACityScene.mBuildUILayer)

    RACityScene.mBuildNameLayer = CCLayer:create()
    RACityScene.mBuildNameLayer:setPosition(0, 0)
    RACityScene.mBuildNameLayer:setAnchorPoint(ccp(0, 0))   
    --RACityScene.mBuildNameLayer:setZOrder(); 
    RACityScene.mRootNode:addChild(RACityScene.mBuildNameLayer)

    -- --新手期间不下雨
    -- if RAGuideManager:isInGuide() then 
    --     RACityScene.isRain = false 
    -- end 

    -- if RACityScene.isRain == true then 
    --     RACityScene.mRootNode:runAnimation('KeepNight')
    --     RACityScene.mRain = RARain:new()
    --     RACityScene.mRain:init()
    --     local RARootManager = RARequire('RARootManager')
    --     RARootManager.mGUINode:addChild(RACityScene.mRain.ccbfile,-1000)
    -- else 
        RACityScene.isRain = false
        RACityScene.mRootNode:runAnimation('NormalAni')
    -- end 
--	local obj3d = CCEntity3D:create('3d/use.c3b')
--	obj3d:setPosition(500,500)
--	obj3d:playAnimation("default",0,3)
--	obj3d:setScale(30)
--	obj3d:setAlphaTestEnable(true)
--	RACityScene.mBuildSpineLayer:addChild(obj3d)
end


function RACityScene:releaseGatherGround()
    for i=1,#self.mTroopGatherCell do
        UIExtend.releaseCCBFile(self.mTroopGatherCell[i])
        self.mTroopGatherCell[i] = nil
    end
    self.mTroopGatherCell = {}
end

function RACityScene:refreshGatherGround()
    local RAGuideManager = RARequire("RAGuideManager")
    local RAGuideConfig = RARequire("RAGuideConfig")
    local RACityScene_TrainInGuide = RARequire("RACityScene_TrainInGuide")
    RACityScene_TrainInGuide:UpdateAnimationStatus()
    if RAGuideManager.getCurrentStage() == RAGuideConfig.GuideStageEnum.StageFirst then
        return
    end

    local RAArsenalManager = RARequire("RAArsenalManager")
    local RAArsenalConfig = RARequire("RAArsenalConfig")
    local returnMap = RAArsenalManager:arrangeArmyTroop()

    self:releaseGatherGround()

    for index,data in pairs(returnMap) do 
        local handler = {
            lastTime = os.time(),
            onRandom = function(self,len)
                local n = 0
                math.randomseed(os.time())
                for i = 1, len do
                    n = math.random(len)
                end
                return n
            end,

            onInfantryBtn = function(self)
                local time = os.time() - self.lastTime
                if time > 1 then
                    local randomId = self:onRandom(4)
                    --CCLuaLog("选中了。。。"..randomId)
                    common:playEffect("clickSoldiers",randomId)
                    self.lastTime = os.time()
                end

                local RARootManager = RARequire("RARootManager")
                RARootManager.OpenPage("RATroopsInfoPage")
            end,
            onTankBtn = function(self)
                local time = os.time() - self.lastTime
                if time > 1 then
                    local randomId = self:onRandom(4)
                    --CCLuaLog("选中了。。。"..randomId)
                    common:playEffect("clickTank",randomId)
                    self.lastTime = os.time()
                end

                local RARootManager = RARequire("RARootManager")
                RARootManager.OpenPage("RATroopsInfoPage")
            end,
            onMissileCarBtn = function(self)
                local time = os.time() - self.lastTime
                if time > 1 then
                    local randomId = self:onRandom(2)
                    --CCLuaLog("选中了。。。"..randomId)
                    common:playEffect("clickAircraft",randomId)
                    self.lastTime = os.time()
                end

                local RARootManager = RARequire("RARootManager")
                RARootManager.OpenPage("RATroopsInfoPage")
            end,
            onAirCraftBtn = function(self)
                local time = os.time() - self.lastTime
                if time > 1 then
                    local randomId = self:onRandom(2)
                    --CCLuaLog("选中了。。。"..randomId)
                    common:playEffect("clickRocketCar",randomId)
                    self.lastTime = os.time()
                end

                local RARootManager = RARequire("RARootManager")
                RARootManager.OpenPage("RATroopsInfoPage")
            end
        }
        local ccbfile = UIExtend.loadCCBFile("RACityGatherCell.ccbi",handler)
        --RACityScene.mTroopGatherCell:insert(ccbfile)
        table.insert(RACityScene.mTroopGatherCell,ccbfile)
        RAGameUtils:setChildMenu(ccbfile,RACitySceneConfig.tileInfo.tmxTotalRect)
        
        --ÏÈÉèÖÃÏÔÓ°×´Ì¬£¬ÔÙÏÔÊ¾ÊýÁ¿
        --RACitySceneManager:setControlToCamera(ccbfile)
        if data.armyType == 1 then
            UIExtend.setNodesVisible(ccbfile,{
                mInfantryNode = true,
                mTankNode = false,
                mMissileCarNode = false,
                mAirCraftNode = false,
            })
            for i=1,RAArsenalConfig.ArmyTroopTotalNum[data.armyType] do 
                local flag = data.displayNum >= i 
                UIExtend.setNodeVisible(ccbfile,"mInfantryPic"..i,flag)
            end

        elseif data.armyType == 2 then
            UIExtend.setNodesVisible(ccbfile,{
                mInfantryNode = false,
                mTankNode = true,
                mMissileCarNode = false,
                mAirCraftNode = false,
            })
            for i=1,RAArsenalConfig.ArmyTroopTotalNum[data.armyType] do 
                local flag = data.displayNum >= i 
                UIExtend.setNodeVisible(ccbfile,"mTankPic"..i,flag)
            end
        elseif data.armyType == 3 then
            UIExtend.setNodesVisible(ccbfile,{
                mInfantryNode = false,
                mTankNode = false,
                mMissileCarNode = true,
                mAirCraftNode = false,
            })
            for i=1,RAArsenalConfig.ArmyTroopTotalNum[data.armyType] do 
                local flag = data.displayNum >= i 
                UIExtend.setNodeVisible(ccbfile,"mMissileCarPic"..i,flag)
            end
        elseif data.armyType == 4 then
            UIExtend.setNodesVisible(ccbfile,{
                mInfantryNode = false,
                mTankNode = false,
                mMissileCarNode = false,
                mAirCraftNode = true,
            })
            for i=1,RAArsenalConfig.ArmyTroopTotalNum[data.armyType] do 
                local flag = data.displayNum >= i 
                UIExtend.setNodeVisible(ccbfile,"mAirCraftPic"..i,flag)
            end
        end
        ccbfile:setPosition(RACityScene.mGatherPos[index].x,RACityScene.mGatherPos[index].y)
        RACityScene.mTroopLayer:addChild(ccbfile)
    end
end

function RACityScene:_initGatherGround()
    local topGatherNode = self.ccbfile:getCCNodeFromCCB("mAssemblyTopNode")
    local leftGatherNode = self.ccbfile:getCCNodeFromCCB("mAssemblyLeftNode")
    local rightGatherNode = self.ccbfile:getCCNodeFromCCB("mAssemblyRightNode")
    local downGatherNode = self.ccbfile:getCCNodeFromCCB("mAssemblyDownNode")

    local row = RACitySceneConfig.GatherGround.row  --4
    local column = RACitySceneConfig.GatherGround.column --6

    local topPos = RACcp(topGatherNode:getPositionX(),topGatherNode:getPositionY())
    local leftPos = RACcp(leftGatherNode:getPositionX(),leftGatherNode:getPositionY())
    local rightPos = RACcp(rightGatherNode:getPositionX(),rightGatherNode:getPositionY())
    local downPos = RACcp(downGatherNode:getPositionX(),downGatherNode:getPositionY())

    local colXOffsetUnit = (topPos.x - leftPos.x) / column
    local colYOffsetUnit = (topPos.y - leftPos.y) / column
    
    local rowXOffsetUnit = (downPos.x - leftPos.x) / row
    local rowYOffsetUnit = (downPos.y - leftPos.y) / row
    RACityScene.mTroopLayer:removeAllChildren()
    for i =0,3 do   --×Ü¹²ËÄÐÐ£¬ÁùÁÐ£¬24¸ö¼¯½áµã
        for k = 1,6 do 
            local index = i * 6 + k 
            local rowBasePos = RACcp(
                leftPos.x + i * rowXOffsetUnit,
                leftPos.y + i * rowYOffsetUnit
            )
            local finalPos = RACcp(
                rowBasePos.x + (k-1)*colXOffsetUnit,
                rowBasePos.y + (k-1)*colYOffsetUnit
            )
            common:log("_initGatherGround index "..index.."finalPos.x"..finalPos.x..",finalPos.y"..finalPos.y)
            RACityScene.mGatherPos[index] = finalPos
        end
    end

end


function RACityScene:Enter()
	CCLuaLog("RACityScene:Enter")
    self:resetData()
    if RACityScene.mRootNode ~= nil then
        assert(false,"RACityScene.mRootNode ~=nil");
        CCLuaLog("RACityScene:Enter  RACityScene.mRootNode ~=nil")
        return
    end
    self:_initRootNodeNLayer();
    self:_initGatherGround()
    self:RegisterPacketHandler(HP_pb.COLLECT_SOLDIER_S)
    self:registerMessageHandlers()
    RABuildManager:Enter()

    --刷新头像上面的红点
    MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint)

     --Default Camera position handle,Ä¬ÈÏÏÈÖ±½Óµ½Ö÷³Ç×ø±ê£¬·ñÔòÔÚÖÐÐÄµã
    local buildData = nil 
    if RABuildManager.showBuildingId == nil then 
        buildData = RABuildManager:getMainCityData()
        local pos = RACitySceneConfig.tileInfo.tmxCenterTile 
        if buildData ~= nil then 
            pos = buildData.tilePos
        end
        --enter the city, camera movement
        local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,pos)
        RACityScene.mCamera:setScale(RACitySceneConfig.cameraInfo.GotoWorldScale, 0.0)
        RACityScene.mCamera:lookAt(spacePos,0.0,false)

        local callback = function ()
            RACityScene.mCamera:setScale(RACitySceneConfig.cameraInfo.normalScale, 0.8)
            RACityScene.mCamera:lookAt(spacePos,0.8,true)
        end
        performWithDelay(RACityScene.mRootNode,callback,0.1)
        
        --RACitySceneManager:cameraGotoTilePos(pos,0,false)
    else
        RACityScene.mCamera:setScale(RACitySceneConfig.cameraInfo.GotoWorldScale, 0.0)
        local pos = RACitySceneConfig.tileInfo.tmxCenterTile 
        local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,pos)
        RACityScene.mCamera:lookAt(spacePos,0.0,false)

        local callback = function ()
            RABuildManager:moveToBuildingById(RABuildManager.showBuildingId,true)
            RABuildManager.showBuildingId = nil 
        end
        performWithDelay(RACityScene.mRootNode,callback,0.1)
        
    end 
    
    --新手开始的地方
    local guideCallback = function ()
        --新手：xinghui 检查新手，这里是新手的起点
        local RAGuideManager = RARequire('RAGuideManager')
        local RAGuideConfig = RARequire('RAGuideConfig')
        local nextKeyWord = RAGuideManager.getKeyWordById()--如果要显示的步骤是要求不走gotoNext的，那么不处理
        if RAGuideConfig.enterNotGotoNext[nextKeyWord] == 1 then
            if nextKeyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then
                --如果是圈住freeBtn，因为freeBtn有可能不存在，需要特殊处理
                local constGuideInfo = RAGuideManager.getConstGuideInfoById()
                if constGuideInfo and constGuideInfo.buildType then
                    local RAQueueManager = RARequire("RAQueueManager")
                    local isUpgrade = RAQueueManager:isBuildingTypeUpgrade(constGuideInfo.buildType)
                    if not isUpgrade then--如果这里依然有建造队列，那么建造那里会发送MSG_Guide_Hud_BtnInfo消息去接上新手
                        RAGuideManager.gotoNextStep2()
                    end
                end
            end
        else

            RAGuideManager.gotoNextStep()
        end
    end
    performWithDelay(RACityScene.mTileMapLayer,guideCallback,1)
    --如果在新手期，先把屏幕cover住
    local RAGuideManager = RARequire('RAGuideManager')
    if RAGuideManager.isInGuide() then
        local RARootManager = RARequire('RARootManager')
        RARootManager.AddCoverPage()
    end


    RACitySceneManager:initRandomArmy()
    
    RACitySceneManager:initTubWithBuildData()
    local RACityScene_BlackShop = RARequire("RACityScene_BlackShop")
    RACityScene_BlackShop:Enter(self.mBuildSpineLayer)
    local RACityScene_TrainInGuide = RARequire("RACityScene_TrainInGuide")
    RACityScene_TrainInGuide:Enter(self.mTroopLayer)

    RACityScene:refreshGatherGround()
    --城市背景音乐 by cph
    SoundManager:getInstance():stopAllEffect()
    local cityMusicSingleton = VaribleManager:getInstance():getSetting("cityMusic_1")
    SoundManager:getInstance():playMusic(cityMusicSingleton,false)

    cityMusicLoopTag = true

    self:checkIsCityRecreated()

    -- RAGameUtils:setChildMenu( self.ccbfile.,RACitySceneConfig.tileInfo.tmxTotalRect)
--    RAGameUtils:setChildMenu( self.mBuildSpineLayer,RACitySceneConfig.tileInfo.tmxTotalRect)
--    RAGameUtils:setChildMenu( self.mTroopLayer,RACitySceneConfig.tileInfo.tmxTotalRect)

    local RAChatManager = RARequire("RAChatManager")
    RAChatManager:refreshTheNewestMsg()--刷新主界面最新聊天信息的显示
end


function RACityScene:Execute()
	RACityMultiLayerTouch.Scrolling()
    RACitySceneManager:Execute()
    
    if cityMusicLoopTag then
        local isBgMusicPlaying = SoundManager:getInstance():isBackgroundMusicPlaying()
        

        if not isBgMusicPlaying then
            --local isRunningForeground = RAPlatformUtils:getRunningForeground()
            local cityMusicLoop = VaribleManager:getInstance():getSetting("cityMusic_2")
            SoundManager:getInstance():playMusic(cityMusicLoop,true)
            cityMusicLoopTag = false
        end
    end

    if self.isRain then 
        local spineColorSprite = self.mRain.ccbfile:getCCSpriteFromCCB('mSpineColor')
        local spineColor = spineColorSprite:getColor()
        local RABuildManager = RARequire('RABuildManager')
        RABuildManager:setAllBuildingsColor(spineColor)
    end 
end	

function RACityScene:Exit()
    if self.mCamera then
        self.mCamera:unregisterFunctionHandler()
    end
    local RACityScene_BlackShop = RARequire("RACityScene_BlackShop")
    RACityScene_BlackShop:Exit()
    local RACityScene_TrainInGuide = RARequire("RACityScene_TrainInGuide")
    RACityScene_TrainInGuide:Exit()
    RACityScene:releaseGatherGround()
    RACitySceneManager:reset()
	self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:resetData()

--    if self.mBuildSpineLayer then
--        self.mBuildSpineLayer:removeAllChildren()
--    end

--    if self.mBuildUILayer then
--        self.mBuildUILayer:removeAllChildren()
--    end

    RABuildManager:Exit()
    cityMusicLoopTag = false
    self.ccbfile:removeAllChildren()
    UIExtend.unLoadCCBFile(self) 

    if self.isRain then 
        UIExtend.unLoadCCBFile(self.mRain) 
        self.mRain = nil 
    end 

    self.isRain = not self.isRain
end



function RACityScene:onReceivePacket(handler)
	local opcode = handler:getOpcode()
    local Army_pb = RARequire("Army_pb")
	if opcode == HP_pb.COLLECT_SOLDIER_S then
		local msg = Army_pb.HPCollectSoldierResp()
		local msgbuff = handler:getBuffer()
		msg:ParseFromString(msgbuff)
        --collect finish, let's rock
        if msg.result == true then
            local RAGuideManager = RARequire("RAGuideManager")
            local RARootManager = RARequire('RARootManager')
            local RAGuideConfig = RARequire("RAGuideConfig")

            --只有新手第一阶段做动画的特殊处理
            if RAGuideManager.getCurrentStage() == RAGuideConfig.GuideStageEnum.StageFirst then
                -- 第一步，触发造兵动画相关逻辑
                local RACityScene_TrainInGuide = RARequire("RACityScene_TrainInGuide")
                RACityScene_TrainInGuide:UpdateAnimationStatus()

                -- 第二步，只有新手普通造兵收兵时才会镜头移动，新手任务造兵不移动镜头
                local RAGuideConfig =  RARequire('RAGuideConfig')
                if RAGuideManager.currentGuildId <= RAGuideConfig.normalCollectPlane then
                    local delayTime = RAGuideConfig.CityCameraTime.TankMoveTime
                    
                    if msg.armyId == RAGuideConfig.FOOT_SOLDIER_L1 then
                        delayTime = RAGuideConfig.CityCameraTime.SoldierMoveTime
                    end
                    local position = RAGuideConfig.CityTrain.TankMovePos
                    if msg.armyId == RAGuideConfig.FOOT_SOLDIER_L1 then
                        position = RAGuideConfig.CityTrain.SoldierMovePos
                    end
                    RARootManager.AddCoverPage()

                    --空中单元不移动镜头
                    if RAGuideManager.currentGuildId<=RAGuideConfig.normalCollectTank then
                        RACitySceneManager:cameraGotoTilePos(position,delayTime)
                    end 

                    --todo 空中单元目前先不播放新手收兵动画，直接进入下一步
                    if RAGuideManager.currentGuildId<=RAGuideConfig.normalCollectTank then
                        performWithDelay(RACityScene.mRootNode,function ( ... )
                            RARootManager.RemoveCoverPage()
                            RAGuideManager.gotoNextStep()--收集士兵，调用一次gotoNext
                        end,delayTime + 0.5)
                    else
                        RARootManager.RemoveCoverPage()
                        RAGuideManager.gotoNextStep()--收集士兵，调用一次gotoNext
                    end    
                elseif RAGuideManager.currentGuildId == RAGuideConfig.missionCollectArmy then
                    --任务中再造10个兵
                    RAGuideManager.gotoNextStep()--收集士兵，调用一次gotoNext
                end
                    
            end

            if not RAGuideManager:isInGuide() then
                RACitySceneManager:finishTrainSoldier(msg.armyId)
            end

            -- --只有新手第一阶段做动画的特殊处理
            -- if RAGuideManager.getCurrentStage() ~= RAGuideConfig.GuideStageEnum.StageFirst then
            --     RACitySceneManager:finishTrainSoldier(msg.armyId)
            -- end
            
            --return 
        end
   end
end



local OnReceiveMessage = function (message)
 CCLuaLog("RACityScene OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_CITY.MSG_NOTICE_GATHER then
        RACityScene:refreshGatherGround()
    elseif message.messageID == MessageDef_World.MSG_CityRecreated then
        RACityScene:checkIsCityRecreated()
    end
end

function RACityScene:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_CITY.MSG_NOTICE_GATHER, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_CityRecreated, OnReceiveMessage)
end

function RACityScene:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_CITY.MSG_NOTICE_GATHER, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_CityRecreated, OnReceiveMessage)
end

-- 检查城外的城点是否被重建
function RACityScene:checkIsCityRecreated()
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    if RAPlayerInfoManager.isCityRecreated() and not RAGuideManager:isInGuide() then
        local RARootManager = RARequire('RARootManager')
        RARootManager.OpenPage('RAConfirmPage', {labelText = _RALang('@NotifyCityRecreated')},false, true, true)
        RAPlayerInfoManager.setCityRecreated(false)
    end
end