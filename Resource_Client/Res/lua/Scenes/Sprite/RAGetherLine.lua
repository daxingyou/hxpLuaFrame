--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local Utilitys = RARequire("Utilitys")
local EnterFrameDefine = RARequire("EnterFrameDefine")
local RATileUtil = RARequire("RATileUtil")
local RACitySceneConfig = RARequire("RACitySceneConfig")
local RAGetherLine = {
}



function RAGetherLine:create(id, parentNode,followSprite,destPos)
    local new = {}

    self.__index = self
    setmetatable(new,self)
    new.startPos = ccp(followSprite.ccbfile:getPosition())
    new.parentNode = parentNode
    new.id = id
    if new.parentNode:getChildByTag(tonumber(new.id)) ~= nil then
        new.parentNode:removeChildByTag(new.id,true)
    end
    new.followSprite = followSprite
    local line = CCLayerColor:create(ccc4(0,255,0,200))
    line:setContentSize(CCSizeMake(2,2))
    if destPos == nil then destPos = RACitySceneConfig.CityArmyIndex.ArmyGetherPos end
    local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,destPos)
    line:setPosition(spacePos)
    line:setAnchorPoint(0,0)
    line:setTag(id)
    new.endPos = spacePos

    parentNode:addChild(line)

    line:setZOrder(2000)
    new.line = line

    new.lifeTime = 0.0
    new:updateScaleAndRotate()
    
    --if RAGuideManager.isInGuide() then
    new.timeCount = 0
    new.liftTime = 2
    --end



    return new
end

function RAGetherLine:createWithSpacePos(id, parentNode, followSprite, destPos, lifeTime)
    local new = {}

    self.__index = self
    setmetatable(new,self)

    local startPos = ccp(0, 0)
    startPos.x, startPos.y = followSprite.ccbfile:getPosition()
    local parentNode = followSprite.ccbfile:getParent()
    if parentNode then
        startPos = parentNode:convertToWorldSpace(startPos)
    end

    new.startPos = startPos
    new.parentNode = parentNode
    new.id = id
    new.followSprite = followSprite

    if new.parentNode:getChildByTag(tonumber(new.id)) ~= nil then
        new.parentNode:removeChildByTag(new.id,true)
    end
    local line = CCLayerColor:create(ccc4(0,255,0,200))
    line:setContentSize(CCSizeMake(2,2))
    line:setPosition(destPos)
    line:setAnchorPoint(0,0)
    line:setTag(id)
    line:setZOrder(2000)
    parentNode:addChild(line)

    new.endPos = destPos
    new.line = line
    new.lifeTime = 0.0
    new:updateScaleAndRotate()
    
    new.timeCount = 0
    new.liftTime = lifeTime or 2

    return new
end

function RAGetherLine:updateScaleAndRotate()

    if self.followSprite == nil or 
        self.line == nil or
        self.followSprite.ccbfile == nil then return end
    local RAGuideManager = RARequire('RAGuideManager')
    --local RAGuideConfig = RARequire("RAGuideConfig")
    if self.timeCount then
        if self.timeCount >= self.liftTime then
            return
        else
            self.timeCount = self.timeCount + GamePrecedure:getInstance():getFrameTime();
            if self.timeCount >= self.liftTime then
                self.line:setVisible(false)
            end
        end
    end        
    local curSpritePos = ccp(self.followSprite.ccbfile:getPositionX(),self.followSprite.ccbfile:getPositionY())
    self.startPos = curSpritePos
    local dis = Utilitys.getDistance(self.startPos,self.endPos)

    local scale = dis / 2
    if scale < 1 then scale = 1 end
    self.line:setScaleX(scale)

    local degree = Utilitys.getDegree(self.startPos.x-self.endPos.x, self.startPos.y-self.endPos.y)
    
    self.line:setRotation(-degree)
    --curSpritePos:delete()
end


function RAGetherLine:Execute()
    if self ~= nil then
        self:updateScaleAndRotate()
    end
    
end

function RAGetherLine:release()
    if self.parentNode ~= nil then
        --self.parentNode:removeChildByTag(self.id,true)
        self.line:removeFromParentAndCleanup(true)
    end
    if self.startPos ~= nil then
        self.startPos:delete()
    end
    self.timeCount = nil
    
end

return RAGetherLine
--endregion
