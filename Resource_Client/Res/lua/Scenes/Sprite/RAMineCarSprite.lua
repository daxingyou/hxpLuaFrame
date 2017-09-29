--region RAMineCarSprite.lua
--Date
--此文件由[BabeLua]插件自动生成

RARequire('extern')
local RASprite = RARequire("RASprite")
local RAMineCarSprite =class("RAMineCarSprite",RASprite)
local RACitySceneConfig = RARequire("RACitySceneConfig")
local UIExtend = RARequire("UIExtend")
local EnumManager = RARequire("EnumManager")
local transferCCBTag = 10000
local digMaxMineTime = 3
local RATransferCarHandler = {
        spriteNode = nil,    
}

function RATransferCarHandler:new(sprite)
    local new = {}
    self.__index = self
    setmetatable(new,self)
    new.spriteNode = sprite
    return new
end

function RATransferCarHandler:OnAnimationDone(ccbfile)
    if self.spriteNode ~= nil then
        --RAMineCarSprite.MoveToMinePos(self.spriteNode)
    end
end

function RAMineCarSprite.getOriAndDesPos(sprite)
    local oriPos = sprite.basePos
    local desPos = sprite.desPos

    if sprite.isInBase == false then
        oriPos = sprite.desPos
        desPos = sprite.basePos
    end
    return oriPos,desPos
end

function RAMineCarSprite:release()
    if self.sprite.transferHandler ~= nil then
        UIExtend.unLoadCCBFile(self.sprite.transferHandler)
    end

    if self.sprite ~= nil then
        self.sprite:release()
    end

end

function RAMineCarSprite:ctor(data)

    self.basePos = data.basePos
    self.desPos = data.desPos
    self.isInBase = data.isInBase
    local oriPos,desPos = self.getOriAndDesPos(self)

    self.sprite = self.super.new(data.id,
    data.frameId,
    data.parentNode,
    oriPos,
    data.layer,
    RAMineCarSprite.onClickCallBack)
    self.sprite.basePos = self.basePos
    self.sprite.desPos = self.desPos
    self.sprite.isInBase = self.isInBase
    self.sprite:MovePos(self.desPos,RAMineCarSprite.finishMoveCallback,true)

    self.sprite.ccbfile:removeChildByTag(transferCCBTag,true)

    --set the colorParam
    local RAWorldConfig = RARequire("RAWorldConfig")
    local World_pb = RARequire("World_pb")
    local colorParam = RAWorldConfig.RelationFlagColor[World_pb.SELF]
    local colorKey = colorParam.key or 'DefaultColorKeyCCB'
    local r = colorParam.color.r or 255
    local g = colorParam.color.g or 255
    local b = colorParam.color.b or 255
    CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    self.sprite.ccbfile:setUseColorMask(colorKey)


    self.sprite.transferHandler = RATransferCarHandler:new(self.sprite)
    local transferCCB = nil
    
    if transferCCB == nil then
        transferCCB = UIExtend.loadCCBFile("Ani_City_Transfer.ccbi",self.sprite.transferHandler)
        transferCCB:setTag(transferCCBTag)
        transferCCB:setVisible(false)
        self.sprite.ccbfile:addChild(transferCCB)
    end
    self.sprite.transferCCB = transferCCB
    self.sprite.buildId = data.buildId
    self.sprite.curDigTime = 0
    --记录时间
    self.sprite.time = os.time()
end

function RAMineCarSprite.onClickCallBack(sprite)
    --CCMessageBox("sprite id is "..sprite.id,"hint")
    local lostTime = os.time() - sprite.time
    if lostTime > 1.5 then
        local common = RARequire("common")
        common:playEffect("clickMineCar")
        sprite.time = os.time()
    end
end

function RAMineCarSprite.finishMoveCallback(sprite,status)
    --如果直接从基地过来到矿石场的结束回调
    if sprite.isInBase == true then
        if status == 3 then
            --如果是正常走到目标，则开始挖矿，挖矿完之后 直接传送回基地
            --RAMineCarSprite.transferToPos(sprite,sprite.basePos)
            return RAMineCarSprite.beginDigMine(sprite)
        else
            --如果被阻挡了，则直接传送到矿车位置，开始挖矿 
            return RAMineCarSprite.transferToPos(sprite,sprite.desPos,RAMineCarSprite.beginDigMine)
        end
    end
end

--从精炼厂走到矿石去采矿
function RAMineCarSprite.MoveToMinePos(sprite)
    local size = #RACitySceneConfig.CityArmyIndex.MinerRandomPos    
    local digGoldPosIndex = math.random(1,size)
    local digGoldPos = RACitySceneConfig.CityArmyIndex.MinerRandomPos[digGoldPosIndex]
    sprite.desPos = digGoldPos
    sprite:MovePos(sprite.desPos,RAMineCarSprite.finishMoveCallback,true)
    sprite.isInBase = true
    
end

function RAMineCarSprite.beginDigMine(sprite)
    sprite.curDigTime = sprite.curDigTime + 1
    local array = CCArray:create()
    local digMineAction = CCCallFunc:create( function()
        sprite:changeAction(EnumManager.ACTION_TYPE.ACTION_ATTACK, sprite.actionController.currentDirection)
    end )
    local delayTime = math.random(2,4)
    local delayAction = CCDelayTime:create(delayTime)
    --挖2-4秒之后，换到另外一个矿点去挖矿，如果达到3次，则传送回主基地
   
   
    local moveToAnotherPos = CCCallFunc:create( function()
       local size = #RACitySceneConfig.CityArmyIndex.MinerRandomPos
       RAMineCarSprite.MoveToMinePos(sprite)
    end )

    local transferAction = CCCallFunc:create( function()
        --传送完成之后，开始移动到采矿区域
        local RABuildManager = RARequire("RABuildManager")
        local buildData = RABuildManager:getBuildDataById(sprite.buildId)
        if buildData ~= nil then
            local basePos = buildData.tilePos
            sprite:changeAction(EnumManager.ACTION_TYPE.ACTION_IDLE, EnumManager.DIRECTION_ENUM.DIR_DOWN)
            RAMineCarSprite.transferToPos(sprite,basePos,RAMineCarSprite.MoveToMinePos)
        end
    end )
    array:addObject(digMineAction)
    array:addObject(delayAction)
    if sprite.curDigTime >=3 then
         array:addObject(transferAction)
         sprite.curDigTime = 0
    else
         array:addObject(moveToAnotherPos)
    end
   
    local action = CCSequence:create(array);
    array:removeAllObjects()
    array:release()
    sprite.ccbfile:stopAllActions()
    sprite.ccbfile:runAction(action)
end



function RAMineCarSprite.transferToPos(sprite,desPos,callback)
    --step.1渐渐消失，播放传送动画
    local array = CCArray:create()
    sprite.spriteNode:setOpacity(0)        
    local disapearAction = CCCallFunc:create( function()
        sprite.transferCCB:setVisible(true)
        sprite.transferCCB:runAnimation("Transfer")
    end )
    array:addObject(disapearAction)
    local delay = CCDelayTime:create(2)
    array:addObject(delay)
    --step.2 传送到目标点,设置位置，同时播放传送动画
    local apearAction = CCCallFunc:create( function()
        sprite.transferCCB:setVisible(true)
        sprite.transferCCB:runAnimation("Transfer")
        local tmpPos = ccp(desPos.x,desPos.y)
        sprite:setCurTilePos(sprite,tmpPos)
        sprite:checkPlayerStatus()
        sprite.mDestTilePos = RACcp(0,0)
        tmpPos:delete()
    end )
    array:addObject(apearAction)
    local fadeIn = CCFadeTo:create(2,255) 
    array:addObject(fadeIn)
    --step.3 延时2秒，开始走回另外一个位置
    local delay2 = CCDelayTime:create(3)
    array:addObject(delay2)
    local moveAction = CCCallFunc:create( function()
        callback(sprite)
    end )     
    array:addObject(moveAction)
    local action = CCSequence:create(array);
    array:removeAllObjects()
    array:release()
    sprite.spriteNode:stopAllActions()
    sprite.spriteNode:runAction(action)


end

return RAMineCarSprite
--endregion
