--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAHelicopterArmy = {}
local RASprite = RARequire("RASprite")
local RATileUtil = RARequire("RATileUtil")
local RACitySceneConfig = RARequire("RACitySceneConfig")
local EnumManager = RARequire("EnumManager")
local RAGetherLine = RARequire("RAGetherLine")
function RAHelicopterArmy:create(armyId,tilePos,i, beginIndex)
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    local frameId = battle_soldier_conf[armyId].frameId
    local shadowId = 6
    local finishArmyId = beginIndex + 3
    local frame_conf = RARequire("frame_conf")
    local frameInfo = frame_conf[frameId]
    local speed = frameInfo.moveSpeed
    local RAMarchActionHelper = RARequire("RAMarchActionHelper")
    local Utilitys = RARequire("Utilitys")
    local sprite = RASprite.new(
    beginIndex + i, frameId, RACityScene.mBuildSpineLayer, tilePos,
    RACityScene.mTileMapGroundLayer)
    sprite.ccbfile:setZOrder(1000)

    local RAWorldConfig = RARequire("RAWorldConfig")
    local World_pb = RARequire("World_pb")
    local colorParam = RAWorldConfig.RelationFlagColor[World_pb.SELF]
    local colorKey = colorParam.key or 'DefaultColorKeyCCB'
    local r = colorParam.color.r or 255
    local g = colorParam.color.g or 255
    local b = colorParam.color.b or 255
    CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    sprite.ccbfile:setUseColorMask(colorKey)

    
    local randomIndex = math.random(1, 5)
    local randomPos = RACitySceneConfig.CityArmyIndex.ArmyGetherRandomPos[randomIndex]
    local sourcePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer, tilePos)
    local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer, randomPos)

    local angle = Utilitys.ccpAngle(sourcePos, spacePos)
    local mDirection = RAMarchActionHelper:GetMarchDirectionByAngle(angle)

    local moveTime = ccpDistance(sourcePos, spacePos) / speed

    sprite.finishArmyId = finishArmyId
    local finishTrainSoldierCallBack = function()
        local array = CCArray:create()
        local disapearAction = CCCallFunc:create( function()
            sprite.line:release()
            sprite.line = nil
            sprite:release()
            if sprite.id == sprite.finishArmyId then
                MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
            end
            local RACitySceneManager = RARequire("RACitySceneManager")
            RACitySceneManager.armyGetherSprite[sprite.id] = nil
        end )
        array:addObject(disapearAction)
        local action = CCSequence:create(array);
        array:removeAllObjects()
        array:release()
        sprite.spriteNode:stopAllActions()
        sprite.spriteNode:runAction(action)
    end

    -- 先从全透明到不透明，然后再移动到对应位置。
    sprite.spriteNode:setVisible(false)
    sprite:changeAction(EnumManager.ACTION_TYPE.ACTION_RUN, mDirection)
    local array = CCArray:create()
    -- 延迟i秒产生
    local delayTime = 2 *(i - 1)

    local tmpPoint = ccp(0, 50)
    local createFun = CCCallFunc:create( function()
        sprite.spriteNode:setVisible(true)
        -- line related
        local line = RAGetherLine:create(beginIndex + 100000 + i , RACityScene.mBuildSpineLayer, sprite,randomPos)
        sprite.line = line
    end )

    local delay = CCDelayTime:create(delayTime)
    --        local fadeOut = CCFadeTo:create(1, 255)
    --        array:addObject(fadeOut)
    array:addObject(delay)
    array:addObject(createFun)
    local moveAct = CCMoveBy:create(1, tmpPoint)
    array:addObject(moveAct)
    local ccMoveAction = CCMoveTo:create(moveTime, ccpAdd(spacePos, tmpPoint))
    tmpPoint:delete()
    array:addObject(ccMoveAction)
    array:addObject(CCCallFunc:create(finishTrainSoldierCallBack))
    local action = CCSequence:create(array);
    sprite.ccbfile:stopAllActions()
    sprite.ccbfile:runAction(action)

    
    local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager.armyGetherSprite[sprite.id] = sprite


--    -- 影子相关
--    local shadowSprite = RASprite.new(armyId + i + shadowId, shadowId,
--    RACityScene.mBuildSpineLayer, tilePos,
--    RACityScene.mTileMapGroundLayer)
--    shadowSprite.ccbfile:setZOrder(1000)
--    shadowSprite.spriteNode:setVisible(false)
--    shadowSprite:changeAction(EnumManager.ACTION_TYPE.ACTION_RUN, mDirection)
--    local shadowArray = CCArray:create()
--    -- 延迟i秒产生
--            delayTime = 2 * (i-1) 
--            delay = CCDelayTime:create(delayTime)
--            shadowArray:addObject(delay)
--            local createFun = CCCallFunc:create( function()
--                shadowSprite.spriteNode:setVisible(true)
--            end )
--            shadowArray:addObject(createFun)
--            shadowArray:addObject(CCDelayTime:create(1))
--            local shmoveAction = CCMoveTo:create(moveTime,spacePos)
--            shadowArray:addObject(shmoveAction)
--            local finishTrainshadowCallBack = function()
--                -- 先从不透明到半透明，然后再消失
--                local array = CCArray:create()
--                local disapearAction = CCCallFunc:create( function()
--                    shadowSprite:release()
--                end )
--                array:addObject(disapearAction)
--                local action = CCSequence:create(array);
--                array:removeAllObjects()
--                array:release()
--                shadowSprite.spriteNode:stopAllActions()
--                shadowSprite.spriteNode:runAction(action)
--            end

--            shadowArray:addObject(CCCallFunc:create(finishTrainshadowCallBack))
--            local shadowaction = CCSequence:create(shadowArray);
--            shadowSprite.ccbfile:stopAllActions()
--            shadowSprite.ccbfile:runAction(shadowaction)


end


return RAHelicopterArmy
--endregion
