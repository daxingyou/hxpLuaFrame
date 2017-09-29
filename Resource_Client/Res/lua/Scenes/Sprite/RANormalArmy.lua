--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire("extern")
local RASprite = RARequire("RASprite")

local RANormalArmy = class("RANormalArmy",RASprite)
local RACitySceneConfig = RARequire("RACitySceneConfig")
local EnterFrameDefine = RARequire("EnterFrameDefine")
local RAGetherLine = RARequire("RAGetherLine")
function RANormalArmy.finishTrainSoldierCallBack(sprite)
    --先从不透明到半透明，然后再消失
    local array = CCArray:create()
    local disapearAction = CCCallFunc:create( function()
        sprite.line:release()
        sprite.line = nil
        sprite:release()

        --判断是最后一个小兵走到集合地点，触发逻辑
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

function RANormalArmy:ctor(param)
    
    local sprite = self.super.new(param.id,param.frameId,RACityScene.mBuildSpineLayer,param.tilePos,
         RACityScene.mTileMapGroundLayer)
    sprite.finishArmyId = param.finishArmyId
    
    --set the colorParam
    local RAWorldConfig = RARequire("RAWorldConfig")
    local World_pb = RARequire("World_pb")
    local colorParam = RAWorldConfig.RelationFlagColor[World_pb.SELF]
    local colorKey = colorParam.key or 'DefaultColorKeyCCB'
    local r = colorParam.color.r or 255
    local g = colorParam.color.g or 255
    local b = colorParam.color.b or 255
    CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    sprite.ccbfile:setUseColorMask(colorKey)

    sprite:checkPlayerStatus()
    --先从全透明到不透明，然后再移动到对应位置。
    sprite.spriteNode:setOpacity(0)
    local array = CCArray:create()
    --延迟i秒产生
    local delayTime  = 0.5 * param.index
    local delay = CCDelayTime:create(delayTime)
        array:addObject(delay)
    local fadeOut = CCFadeTo:create(1,255)         
        array:addObject(fadeOut)
    
    local randomIndex = math.random(1,5)
    local randomPos = RACitySceneConfig.CityArmyIndex.ArmyGetherRandomPos[randomIndex]
    local moveAction = CCCallFunc:create( function()
        sprite:MovePos(randomPos,RANormalArmy.finishTrainSoldierCallBack)
        local line = RAGetherLine:create(param.id + 100000,RACityScene.mBuildSpineLayer,sprite,randomPos)
        sprite.line = line
    end )
    array:addObject(moveAction)
    local action = CCSequence:create(array);
    sprite.spriteNode:stopAllActions()
    sprite.spriteNode:runAction(action)
    sprite.destPos = randomPos

    
    local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager.armyGetherSprite[sprite.id] = sprite
end


function RANormalArmy:release()
    
end


return RANormalArmy
--endregion
