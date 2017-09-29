--FileName :RATileUtil 
--Author: zhenhui 2016/5/26

local RABuildManager = RARequire("RABuildManager")
local RACitySceneManager = {}
package.loaded[...] = RACitySceneManager
local common = RARequire("common")
local RATileUtil = RARequire("RATileUtil")
local RACitySceneConfig = RARequire("RACitySceneConfig")
local EnumManager = RARequire("EnumManager")
local RASprite = RARequire("RASprite")
local mBeginPos = nil
local mDebugMode = false
RACitySceneManager.sceneCamera = nil
RACitySceneManager.spriteDebug = false
RACitySceneManager.spriteScreenDebug = false
RACitySceneManager.backGroundFlag = false
isFirstCreateSprite = true

--矿车的队列
RACitySceneManager.TubSprite = {}

--随机巡逻的小兵
RACitySceneManager.rangerSprite = {}
RACitySceneManager.frameCount = 0
RACitySceneManager.guideCountTime = 0
RACitySceneManager.helperCountTime = 0
RACitySceneManager.isInTouch = 0

RACitySceneManager.armyGetherSprite = {}
RACitySceneManager.armyBeginIds = {}

--重置某些数据和精灵
function RACitySceneManager:reset()
    --清除随机巡逻的小兵
    for k,value in pairs(RACitySceneManager.rangerSprite) do 
        value:release()
    end

    --矿车的队列
    for k,value in pairs(RACitySceneManager.TubSprite) do 
        value:release()
    end

    --清除走到集结场的小兵
    for k,value in pairs(RACitySceneManager.armyGetherSprite) do 
        if value.line ~= nil then
            value.line:release()
            value.line = nil
        end
        
        value:release()
    end
    RACitySceneManager.isInTouch = 0
    RACitySceneManager.rangerSpriteIDs = {}
    RACitySceneManager.rangerSprite = {}
end

--function 1 -----------camera related------------------

--废弃的方法，后续可以不用这么处理
function RACitySceneManager:setControlToCamera(pNode)
    return
--    if RACitySceneManager.sceneCamera == nil then
--        return
--    end
--    if pNode == nil then
--		return
--	end
--	local classObj = tolua.cast(pNode:getClass(), "CCClass")
--	local className
--	if classObj ~= nil then
--		className = classObj:getName()
--	end
--	if className ~= nil then
--		-- node
--		if className == "CCControlButton" then
--			local node = tolua.cast(pNode, "CCControlButton")
--			if node ~= nil then
--				node:setCalcCamera(RACitySceneManager.sceneCamera)
--			end
--		end
--        local root = tolua.cast(pNode, className)
--		local children = root:getChildren()
--		if children ~= nil then
--			for i=1, children:count() do
--				local child = children:objectAtIndex(i - 1)
--				RACitySceneManager:setControlToCamera(child)
--			end
--		end
--	end
end

function RACitySceneManager:gobackToCity()
    return 
end

function RACitySceneManager:gotoWorld()
    local maxScale = RACitySceneConfig.cameraInfo.GotoWorldScale
    self:setCameraScale(maxScale,0.5)
end

function RACitySceneManager:setCameraScale(scale,time)
    if time == nil then time = 0.7 end
    local offset = RACityScene.mCamera:getCenter()
    if offset then
        self:cameraGotoSpacePos(offset, time, true, scale)
    end

    --return RACityScene.mCamera:setScale(scale,time)
end

--摄像机移动到TilePos
function RACitySceneManager:cameraGotoTilePos(pos,time,isSmooth,scale)
    local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,pos)
    self:cameraGotoSpacePos(spacePos,time,isSmooth,scale)
end

--摄像机移动到SpacePos
function RACitySceneManager:cameraGotoSpacePos(pos,time,isSmooth,scale)
    if time == nil then time = 0.7 end
    if scale == nil then scale = RACitySceneConfig.cameraInfo.normalScale end
    if isSmooth == nil then isSmooth = true end

    if time > 0 then 
        RACityScene.isCameraMoving = true
    end 
    RACityScene.mCamera:setScale(scale,time)
    RACityScene.mCamera:lookAt(pos,time,isSmooth)

end

function RACitySceneManager:setDebugModel(flag)
    mDebugMode = flag
    RACityScene.mTileMapGroundLayer:setVisible(flag)
end


--function 2 -----------pos coordinate related------------------

function RACitySceneManager.convertTerrainPos2ScreenPos(pos)
    local cameraOffSet = RACityScene.mCamera:getOffSet()
	local cameraScale = RACityScene.mCamera:getScale()
    local screenPos = RACcp((pos.x-cameraOffSet.x)/cameraScale,(pos.y-cameraOffSet.y)/cameraScale)
	return screenPos
end


function RACitySceneManager.convertScreenPos2TerrainPos(position)
    local cameraOffSet = RACityScene.mCamera:getOffSet()
	local cameraScale = RACityScene.mCamera:getScale()
	local terrainPos = RACcp(cameraOffSet.x + position.x * cameraScale,cameraOffSet.y + position.y * cameraScale)
	return terrainPos
end

function RACitySceneManager.getTouchCityScenePos(touch)
	local cameraOffSet = RACityScene.mCamera:getOffSet()
	local cameraScale = RACityScene.mCamera:getScale()
	local terrainPos = RACcp(cameraOffSet.x + touch:getLocation().x * cameraScale,cameraOffSet.y + touch:getLocation().y * cameraScale)
	return terrainPos
end

function RACitySceneManager.singleCitySceneTouch(pEvent, touch)

    local RACityScene = RARequire('RACityScene')
    if RACityScene.isCameraMoving == true then 
        return 
    end 

    --如果在缩放模式，不处理单击事件，直接returnn
     if RACityMultiLayerTouch.isInScaleState() then
        if RABuildManager.curBuilding~= nil and RABuildManager.curBuilding.timeNode~=nil then
            return  RABuildManager.curBuilding.timeNode:stopAllActions()
        end

     end

    if pEvent == "began" then
        RACitySceneManager.isInTouch = 1
		local point = touch:getLocation()
        local screenPoint = RACityScene.mRootNode:convertToWorldSpaceAR(point)
        local newSpacePos = RACitySceneManager.getTouchCityScenePos(touch)
        local tilePos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,newSpacePos)
        mBeginPos = screenPoint
		RABuildManager:TouchBeginHandler(touch,screenPoint,newSpacePos,tilePos)
        return true
    elseif pEvent == "moved" then
        local point = touch:getLocation()
        local screenPoint = RACityScene.mRootNode:convertToWorldSpaceAR(point)
        local newSpacePos = RACitySceneManager.getTouchCityScenePos(touch)
        local tilePos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,newSpacePos)
        
        local moveDis = ccpDistance(mBeginPos, screenPoint)
        if moveDis > 10 then
            RABuildManager:TouchMovedHandler(touch,screenPoint,newSpacePos,tilePos)
        end

    elseif pEvent == "ended" then
        RACitySceneManager.isInTouch = 2
        local point = touch:getLocation();
        local screenPoint = RACityScene.mRootNode:convertToWorldSpaceAR(point)
        local newSpacePos = RACitySceneManager.getTouchCityScenePos(touch)
        local tilePos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,newSpacePos)
        local moveDis = ccpDistance(mBeginPos, screenPoint)
        --如果是在滑动地表，而且不是在移动状态，直接返回，如果是在移动状态，则触发touchEnnd事件
        if moveDis >100 and RABuildManager.clickedBuilding == false  then
            RABuildManager.isInTouch = 2 
            return
        end

        RABuildManager:TouchEndHandler(touch,screenPoint,newSpacePos,tilePos)

    elseif pEvent == "cancelled" then
        RACitySceneManager.isInTouch = 2
		RABuildManager:TouchCancelHandler()
    end
end



--function 3 -----------block path related------------------

--在移动或者建造的时候，显示背景层Layer,标记建筑的格子位置信息
function RACitySceneManager:showBackGround(flag)  
    if RACitySceneManager.backGroundFlag == flag then return end
    RACitySceneManager.backGroundFlag = flag
    if flag == true then 

        RACityScene.mTileMapGroundLayer:setVisible(true)
        RACityScene.mTileMapGroundLayer:setOpacity(0)
        local fade = CCFadeTo:create(0.3,255)
        RACityScene.mTileMapGroundLayer:runAction(fade)
    else 
        local fade = CCFadeTo:create(0.3,0)
        local delay = CCDelayTime:create(0.3)
        local array = CCArray:create()
        array:addObject(fade)
        local funcAction = CCCallFunc:create(function ()
            RACityScene.mTileMapGroundLayer:setVisible(false)
        end)
        array:addObject(delay)
        array:addObject(funcAction)
        local seq = CCSequence:create(array);
        RACityScene.mTileMapGroundLayer:runAction(seq)
    end 
end


function g_WalkIsBlock(content)
    local RAStringUtil = RARequire("RAStringUtil")
    local inputTB = RAStringUtil:split(content, ',')
    local x, y = inputTB[1], inputTB[2]
    if x ~= nil and y ~=nil then
        local RACitySceneManager = RARequire("RACitySceneManager")
        return RACitySceneManager:isCanWalk(x,y)
    end
    return 0
end




--return 1 means can walk, else return 0
function RACitySceneManager:isCanWalk(x,y)
    local tilePos = RACcp( math.floor(x + .5), math.floor(y + .5))
    if tilePos.x<0 or tilePos.x>=self.m_layerSize.width or tilePos.y<0 or tilePos.y>=self.m_layerSize.height then
		CCLuaLog("RACitySceneManager::isCanWalk  not in data");
		return 0;
	end
    --建筑没有被遮挡，而且不是红色阻挡标记，则可以行走
    local RABuildManager = RARequire("RABuildManager")
    if RABuildManager:isCanWalk(tilePos) then
        if RACityScene.mTileBlockLayer:tileGIDAt(tilePos.x, tilePos.y) ~= RACitySceneConfig.tileInfo.tmxRedGID then 
            return 1
        end
    end
    return 0
end

--inputPos传入TilePos,返回该位置是否block,返回true 表示不能建造，false,表示可以建造
function RACitySceneManager:isBuildBlock(inputPos)
    local tilePos = RACcp( math.floor(inputPos.x + .5), math.floor(inputPos.y + .5))
    if tilePos.x<0 or tilePos.x>=self.m_layerSize.width or tilePos.y<0 or tilePos.y>=self.m_layerSize.height then
		CCLuaLog("RACitySceneManager::isBuildBlock  not in data");
		return true;
	end
    assert(RACityScene.mTileBlockLayer~=nil,"error in m_pBolck~=nil")
   
    
     --gid ~=3 means is block, ==3 is green ok for build in tilemap by zhenhui
    if RACityScene.mTileBlockLayer:tileGIDAt(tilePos.x, tilePos.y) == RACitySceneConfig.tileInfo.tmxGreenGID then 
        return false
    else
        return true
    end
end


function RACitySceneManager:setTileWhiteBg(inputPos)
    local tilePos = ccp( math.floor(inputPos.x + .5), math.floor(inputPos.y + .5))
    if tilePos.x<0 or tilePos.x>=self.m_layerSize.width or tilePos.y<0 or tilePos.y>=self.m_layerSize.height then
		-- CCLuaLog("RACitySceneManager::setTileWhiteBg  not in data");
        tilePos:delete()
		return false;
	end
    assert(RACityScene.mTileMapGroundLayer~=nil,"error in m_pBolck~=nil")
   
    RACityScene.mTileMapGroundLayer:setTileGID(RACitySceneConfig.tileInfo.tmxWhiteGID,tilePos)
    -- RACityScene.mTileBlockLayer:setTileGID(RACitySceneConfig.tileInfo.tmxGreenGID,tilePos)
    tilePos:delete()
end

function RACitySceneManager:setTileBlock(isBlock,inputPos)
        local tilePos = ccp( math.floor(inputPos.x + .5), math.floor(inputPos.y + .5))
    if tilePos.x<0 or tilePos.x>=self.m_layerSize.width or tilePos.y<0 or tilePos.y>=self.m_layerSize.height then
        -- CCLuaLog("RACitySceneManager::setTileWhiteBg  not in data");
        tilePos:delete()
        return false;
    end
    assert(RACityScene.mTileMapGroundLayer~=nil,"error in m_pBolck~=nil")
   
    if isBlock then 
        RACityScene.mTileBlockLayer:setTileGID(RACitySceneConfig.tileInfo.tmxRedGID,tilePos)
    else 
        RACityScene.mTileBlockLayer:setTileGID(RACitySceneConfig.tileInfo.tmxGreenGID,tilePos)
    end 

    tilePos:delete()
end


function RACitySceneManager:setTileEmptyBg(inputPos)
        local tilePos = ccp( math.floor(inputPos.x + .5), math.floor(inputPos.y + .5))
    if tilePos.x<0 or tilePos.x>=self.m_layerSize.width or tilePos.y<0 or tilePos.y>=self.m_layerSize.height then
		-- CCLuaLog("RACitySceneManager::setTileWhiteBg  not in data");
        tilePos:delete()
		return false;
	end
    assert(RACityScene.mTileMapGroundLayer~=nil,"error in m_pBolck~=nil")
   
    RACityScene.mTileMapGroundLayer:setTileGID(RACitySceneConfig.tileInfo.tmxEmptyGID,tilePos)
    -- RACityScene.mTileBlockLayer:setTileGID(RACitySceneConfig.tileInfo.tmxRedGID,tilePos)
    tilePos:delete()
end

function RACitySceneManager:judgeNextDirection(curPos,nextPos)
    local p = RACcp ( curPos.x - 1, curPos.y );
    --左移动¯
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_LEFT;
    end
    -- 右
    p = RACcp ( curPos.x + 1, curPos.y );
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_RIGHT;
    end
     -- 上
    p = RACcp ( curPos.x, curPos.y - 2 );  -- -2
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_UP;
    end

     -- 下
    p = RACcp ( curPos.x, curPos.y + 2 );-- + 2
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_DOWN;
    end
     -- 左上
    p = RACcp ( curPos.x - 1 +  ( (curPos.y) %2) , curPos.y - 1 );
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_UP_LEFT;
    end
 
    -- 左下
    p = RACcp ( curPos.x - 1 + ( (curPos.y ) % 2 ), curPos.y + 1 );
     if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT;
    end
 
    --右上
    p = RACcp ( curPos.x + ( (curPos.y )% 2 ), curPos.y - 1 );
    if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT;
    end
 
    --右下
    p = RACcp ( curPos.x +  ( (curPos.y )%2 ), curPos.y + 1 );
     if RACcpDistance(p,nextPos) < 0.1 then
        return EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT;
    end

    assert(false,"Sprite:judgeNextDirection -- error in found direction");
end


--function 4 -----------主城城市小兵移动相关------------------

--随机产生部队的初始位置和目的位置
function RACitySceneManager:randomTilePos()
    local x = math.random(RACitySceneConfig.CityArmyIndex.RandomRangerBeginPos.x,RACitySceneConfig.CityArmyIndex.RandomRangerEndPos.x)
    local y = math.random(RACitySceneConfig.CityArmyIndex.RandomRangerBeginPos.y,RACitySceneConfig.CityArmyIndex.RandomRangerEndPos.y)
    if self:isCanWalk(x,y) then
        return x,y
    end
    return RACitySceneConfig.CityArmyIndex.RandomFailPos
end


RACitySceneManager.rangerSpriteIDs = {}

RACitySceneManager.finishCallBack = function (sprite)
    table.insert(RACitySceneManager.rangerSpriteIDs,sprite.id)
end

function RACitySceneManager:Execute()
    self.frameCount = self.frameCount +1
    if #RACitySceneManager.rangerSpriteIDs > 0 and self.frameCount>30 then
        local curSpriteId = table.remove(self.rangerSpriteIDs,1)
        local curSprite = RACitySceneManager.rangerSprite[curSpriteId]
        if  curSprite~= nil then
            local x,y = RACitySceneManager:randomTilePos()
            local desPos = RACcp(x,y)
            self.frameCount = 0 
            return curSprite:MovePos(desPos,RACitySceneManager.finishCallBack,true )
        end
    end
    
    for k,value in pairs(RACitySceneManager.armyGetherSprite) do 
        if value.line ~= nil then
            value.line:Execute()
        end
        
    end

    self:checkGuide()

end

function RACitySceneManager:checkGuide(  )
    local RAGuideManager = RARequire("RAGuideManager")
    local RARootManager = RARequire('RARootManager')
    local isTaskCount = not RARootManager.hasTips()
                        and not RAGuideManager.isInGuide() 
                        and RACitySceneManager.isInTouch == 0 
                        and not RABuildManager:isHudShow()
                        and not RARootManager.CheckHasPageOpening() 
                        and RABuildManager.curAction == nil


    if RACitySceneManager.isInTouch == 2 then
        RACitySceneManager.isInTouch = 0;
    end

    RACitySceneManager:checkTaskGuide(isTaskCount)
    RACitySceneManager:checkHelperTips(isTaskCount)
end

function RACitySceneManager:checkTaskGuide( isTaskCount )
    local RAGuideConfig = RARequire('RAGuideConfig')
    local RAMainUIBottomBanner = RARequire('RAMainUIBottomBannerNew')
    local cityLevel = RABuildManager:getMainCityLvl()
    isTaskCount = isTaskCount and cityLevel < RAGuideConfig.taskGuideMaxLevel
    if RAMainUIBottomBanner.guideTaskCCB ~= nil then
        if not isTaskCount then
            MessageManager.sendMessage(MessageDef_MainUI.MSG_HideTaskGuild)
        else
            isTaskCount = false
        end
    end

    if isTaskCount then
        self.guideCountTime = self.guideCountTime + GamePrecedure:getInstance():getFrameTime()
    else
        self.guideCountTime = 0
    end
    if self.guideCountTime >= RAGuideConfig.taskGuideTime then
        self.guideCountTime = 0
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ShowTaskGuild)
    end
end

function RACitySceneManager:checkHelperTips( isTaskCount )
    local RASettingMainConfig = RARequire('RASettingMainConfig')
    local isShowHelper = CCUserDefault:sharedUserDefault():getStringForKey(RASettingMainConfig.option_showGameHelper)            
    if isShowHelper == "0" then return end
    local RAGuideConfig = RARequire('RAGuideConfig')
    local RAMainUIBottomBanner = RARequire('RAMainUIBottomBannerNew')
    local RAGuideManager = RARequire("RAGuideManager")
    if RAMainUIBottomBanner.showHelperTipes or RAGuideManager.isInGuide() then
        if not isTaskCount then
            MessageManager.sendMessage(MessageDef_MainUI.MSG_HideHelperTips)
        else
            isTaskCount = false
        end
    end

    if isTaskCount then
        self.helperCountTime = self.helperCountTime + GamePrecedure:getInstance():getFrameTime()
    else
        self.guideCountTime = 0
        self.helperCountTime = 0
    end
    if self.guideCountTime >= RAGuideConfig.taskGuideTime then
        self.guideCountTime = 0
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ShowTaskGuild)
    end
    if self.helperCountTime >= RAGuideConfig.helperGuideTime then
        self.helperCountTime = 0
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ShowHelperTips)
    end
end

--城市内，随机支持小兵在城内移动，todo clear the army
function RACitySceneManager:initRandomArmy()
    
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() and RAGuideManager.isInFirstPart()  then return end--在新手第一阶段才不需要世界数据
    local mainCityLv = RABuildManager:getMainCityLvl()
    if mainCityLv == 0 then return end
    local num = 0 
    if mainCityLv > 0 then
        num = 5 + math.floor(mainCityLv / 3 )
    end
    local frameId = 8
    for i =1,num,1 do
        local spriteUUid = RACitySceneConfig.CityArmyIndex.RandomArmy *1000 + i
        --创建精灵，寻路到部队集结位置
        local x,y = RACitySceneManager:randomTilePos()
        local oriPos = ccp(x,y)
        local sprite = RASprite.new(spriteUUid,frameId,RACityScene.mBuildSpineLayer,oriPos,
        RACityScene.mTileMapGroundLayer)
        oriPos:delete()
        
        local desx,desy = RACitySceneManager:randomTilePos()
        local desPos = RACcp(desx,desy)
        sprite:MovePos(desPos,RACitySceneManager.finishCallBack,true)

        RACitySceneManager.rangerSprite[spriteUUid] = sprite

    end
end


function RACitySceneManager:initHelicopter(armyId,tilePos)
    local armyBeginIds = RACitySceneManager.armyBeginIds
    local RAHelicopterArmy = RARequire("RAHelicopterArmy")
    for i = 1, 3 do
        RAHelicopterArmy:create(armyId,tilePos, i, armyBeginIds[4])
    end
    armyBeginIds[4] = armyBeginIds[4] + 3
end

--训练完士兵之后，初始化士兵，并走到对应集结点。
function RACitySceneManager:finishTrainSoldier(armyId)
    if RACityScene.mRootNode == nil then return end
     local battle_soldier_conf = RARequire("battle_soldier_conf")
     local buildDataTable = RABuildManager:getBuildDataByType(battle_soldier_conf[armyId].building)
     
     local buildNum = common:table_count(buildDataTable)

     local frameId = battle_soldier_conf[armyId].frameId
     local soldierType = battle_soldier_conf[armyId].type
     local armyBeginIds = RACitySceneManager.armyBeginIds
     armyBeginIds[soldierType] = armyBeginIds[soldierType] or soldierType*10000
     if armyBeginIds[soldierType] - soldierType*10000 + 3*buildNum >= 10000 then
        armyBeginIds[soldierType] = soldierType*10000
     end
     local beginId = armyBeginIds[soldierType]

     for k,buildData in pairs(buildDataTable) do
         local tilePos = RACcp(buildData.tilePos.x,buildData.tilePos.y)

         if battle_soldier_conf[armyId].type == 4 then
            RACitySceneManager:initHelicopter(armyId,tilePos)
         else
             local posTable  = {}
             local RATileUtil = RARequire("RATileUtil")
             local randomIndex = math.random(1,5)
             local endPos = RACitySceneConfig.CityArmyIndex.ArmyGetherRandomPos[randomIndex]
             --special handlement for v3
             if battle_soldier_conf[armyId].type == 3 then
                tilePos.y = tilePos.y + 2
             end
             local tilesMap = RABuildingUtility.getSortedBuildingAllTilePos(tilePos,buildData.confData.width,buildData.confData.length)

             for k,startPos in pairs(tilesMap) do
                 if #posTable == 3 then
                    break
                 end
                  if RATileUtil:canFindThePath(startPos,endPos) then
                      local ccpPoint = ccp(startPos.x,startPos.y)
                      table.insert(posTable,ccpPoint)
                  end
             end
             for j =1,#posTable do
                local param = {
                    id = armyBeginIds[soldierType] + j,
                    frameId = frameId,
                    tilePos = posTable[j],
                    finishArmyId = beginId + buildNum*3,
                    index = 1
                }
                local RANormalArmy = RARequire("RANormalArmy")
                RANormalArmy.new(param)
             end
             armyBeginIds[soldierType] = armyBeginIds[soldierType] + #posTable
         end
    end     
end

--训练完士兵之后，初始化士兵，并走到对应集结点。
function RACitySceneManager:finishCureSoldier()

     local battle_soldier_conf = RARequire("battle_soldier_conf")
     local Const_pb = RARequire('Const_pb')
     local armyId = 100021
     local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION)
     
     local buildNum = common:table_count(buildDataTable)

     local frameId = battle_soldier_conf[armyId].frameId
     local soldierType = battle_soldier_conf[armyId].type
     local armyBeginIds = RACitySceneManager.armyBeginIds
     armyBeginIds[soldierType] = armyBeginIds[soldierType] or soldierType*10000
     if armyBeginIds[soldierType] - soldierType*10000 + 3*buildNum >= 10000 then
        armyBeginIds[soldierType] = soldierType*10000
     end
     local beginId = armyBeginIds[soldierType]

     for k,buildData in pairs(buildDataTable) do


         local tilePos = RACcp(buildData.tilePos.x,buildData.tilePos.y)

         if battle_soldier_conf[armyId].type == 4 then
            RACitySceneManager:initHelicopter(armyId,tilePos)
         else
             local posTable  = {}
             local RATileUtil = RARequire("RATileUtil")
             local randomIndex = math.random(1,5)
             local endPos = RACitySceneConfig.CityArmyIndex.ArmyGetherRandomPos[randomIndex]
             --special handlement for v3
             if battle_soldier_conf[armyId].type == 3 then
                tilePos.y = tilePos.y + 2
             end
             local tilesMap = RABuildingUtility.getSortedBuildingAllTilePos(tilePos,buildData.confData.width,buildData.confData.length)

             for k,startPos in pairs(tilesMap) do
                 if #posTable == 3 then
                    break
                 end
                  if RATileUtil:canFindThePath(startPos,endPos) then
                      local ccpPoint = ccp(startPos.x,startPos.y)
                      table.insert(posTable,ccpPoint)
                  end
             end
             for j =1,#posTable do
                local param = {
                    id = armyBeginIds[soldierType] + j,
                    frameId = frameId,
                    tilePos = posTable[j],
                    finishArmyId = beginId + buildNum*3,
                    index = 1
                }
                local RANormalArmy = RARequire("RANormalArmy")
                RANormalArmy.new(param)
             end
             armyBeginIds[soldierType] = armyBeginIds[soldierType] + #posTable
         end
    end     
end


function RACitySceneManager:removeOneMineCarByBuildData(buildData)
   local buildId = buildData.id
   if self.TubSprite[buildId] ~= nil then
        self.TubSprite[buildId]:release()
        self.TubSprite[buildId] = nil
   end
end


function RACitySceneManager:addOneMineCarByBuildData(buildData)
    --登录的时候，RACityScene还没创建，就不要创建矿车了
    if RACityScene == nil then 
        return 
    end 

    local frameId = 5
    local RAMineCarSprite = RARequire("RAMineCarSprite")
    local tilePos = buildData.tilePos
    local digGoldPos = RACcp(0, 0)

    local size = #RACitySceneConfig.CityArmyIndex.MinerRandomPos
    digGoldPosIndex = math.random(1, size)
    digGoldPos = RACitySceneConfig.CityArmyIndex.MinerRandomPos[digGoldPosIndex]

    local isInBase = true
    -- 初始化矿车
    local param = {
        basePos = tilePos,
        desPos = digGoldPos,
        isInBase = isInBase,
        id = math.ceil(common:CalcCrc(buildData.id) /10000 + digGoldPosIndex),
        frameId = frameId,
        buildId = buildData.id,
        parentNode = RACityScene.mBuildSpineLayer,
        layer = RACityScene.mTileMapGroundLayer
    }
    local mineCar = RAMineCarSprite.new(param)
    self.TubSprite[param.buildId] = mineCar
end

--初始化矿车相关逻辑
function RACitySceneManager:initTubWithBuildData()
    local tubType = 2101
    local TubBuildDatas = RABuildManager:getBuildDataByType(tubType)
    if TubBuildDatas == nil then return end
    for k,buildData in pairs(TubBuildDatas) do
        self:addOneMineCarByBuildData(buildData)
    end
end