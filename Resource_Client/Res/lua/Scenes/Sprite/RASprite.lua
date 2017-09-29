--region RASprite.lua
--Date 2016/6/12
--Author zhenhui

local RASpriteData = RARequire("RASpriteData")
local RAActionController = RARequire("RAActionController")
local RAActionData = RARequire("RAActionData")
local RATileUtil = RARequire("RATileUtil")
local UIExtend = RARequire("UIExtend")
local EnumManager = RARequire("EnumManager")
local common = RARequire("common")
local RAStringUtil = RARequire("RAStringUtil")
local RACitySceneManager = RARequire("RACitySceneManager")
local RASpriteConfig = RARequire("RASpriteConfig")
local RASpriteActionMgr = RARequire("RASpriteActionMgr")
local frame_conf = RARequire("frame_conf")
RARequire('extern')


local RASprite = class('RASprite',{
    })

--id 是唯一uuid,用来标示tag, frameId 为frame_conf 的索引ID，parentNode
function RASprite:ctor(id,frameId,parentNode,curTilePos,tileLayer,clickCallback)
    
    self.id = id
    self.frameId = frameId --精灵ID
    self.frameInfo = frame_conf[frameId]
    local ccbfile = UIExtend.loadCCBFile("RASprite.ccbi",self)
    self.actionController = RASpriteActionMgr:new(self.ccbfile,frameId)
    self.parentNode = parentNode
    self.curTilePos = nil
    self.curSpacePos = nil
    self.tileLayer = tileLayer
   
    self.mDestTilePos = RACcp(0,0)

    self:setCurTilePos(self,curTilePos)
    self:setZOrder(curTilePos.y)
    --todo: need to set the tag for ccbfile

    if self.parentNode:getChildByTag(tonumber(self.id)) ~= nil then
        self.parentNode:removeChildByTag(tonumber(self.id),true)
    end
    self.ccbfile:setTag(tonumber(self.id))
    self.parentNode:addChild(self.ccbfile)
    self.spriteNode = self.ccbfile:getCCSpriteFromCCB("mSprite")
    self.actionController:changeAction(EnumManager.ACTION_TYPE.ACTION_IDLE, EnumManager.DIRECTION_ENUM.DIR_DOWN)
    self.clickCallback = clickCallback
    RACitySceneManager:setControlToCamera(self.ccbfile)
    self.spriteBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mSpriteBtn")
    --self.spriteBtn:setScale(100)
    local size = self.spriteNode:getContentSize()
    local width = size.width
    local height = size.height
    self.spriteBtn:setPreferredSize(CCSizeMake(width, height))

    local RACitySceneConfig = RARequire("RACitySceneConfig")
    RAGameUtils:setChildMenu(ccbfile,RACitySceneConfig.tileInfo.tmxTotalRect)

end

function RASprite:onSpriteBtn()
    if self.clickCallback ~= nil then
        self.clickCallback(self)
    end
end

function RASprite:release()
    if self.ccbfile ~= nil then
        self.ccbfile:stopAllActions()
        if self.parentNode ~= nil and self.ccbfile:getParent()~=nil then
            --self.ccbfile:removeFromParentAndCleanup(true)
            self.parentNode:removeChildByTag(self.id,true)
        end
        if self.spriteNode ~= nil then
            self.spriteNode:stopAllActions()
        end
    end
    if self.actionController ~= nil then
        self.actionController:release()
        self.actionController = nil
    end  
    UIExtend.unLoadCCBFile(self)
end

function RASprite:changeAction(actionType,actionDir)
    self.actionController:changeAction(actionType,actionDir)
end
function RASprite:setZOrder(order)
     local nodeZ = tolua.cast(self.ccbfile,"CCNode")
     if nodeZ ~= nil then
        nodeZ:setZOrder(order)
     end
end

function RASprite:setCurTilePos(unit,pos)
    unit.curTilePos = pos
    local spacePos = RATileUtil:tile2Space(unit.tileLayer,unit.curTilePos)
    unit:setCurSpacePos(unit,spacePos)
end

function RASprite:setCurSpacePos(unit,pos)
    unit.ccbfile:setPosition(pos);
    unit.curSpacePos = pos
end


function RASprite:getFrameInfo()
    assert(false,"error function")
end

function RASprite:checkPlayerStatus(nextPos)
    assert(self.ccbfile ~= nil)
    local posY = self.ccbfile:getPositionY()
    --local oriTiledPos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,ccp(self.ccbfile:getPosition()));
    self.ccbfile:setZOrder(-posY)

    if nextPos ~= nil then
        local flag = RACitySceneManager:isCanWalk(nextPos.x,nextPos.y)
        if flag == 0 then
            local finishCallback = self.finishCallback
            if finishCallback ~= nil then
                self.ccbfile:stopAllActions()
                finishCallback(self,RASpriteConfig.SpriteFinishStatus.BlockWhenMoving)
            else
                self.ccbfile:stopAllActions()
                self:MovePos(self.mDestTilePos,self,finishCallback,self.isWalk)
            end
        end
    end

end

function RASprite:MovePos(desTiledPos,finishCallback,isWalk)
    --common:log("dest tile pos(%.2f,%.2f)",desTiledPos.x,desTiledPos.y);
    if self.ccbfile == nil then
        return 
    end
    self.finishCallback = finishCallback
    self.isWalk = isWalk
    local oriSpacePos = ccp(self.ccbfile:getPosition())
    local tmpPos = ccp(self.ccbfile:getPosition())
    local oriTiledPos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,tmpPos);
    tmpPos:delete()
    if self.mDestTilePos.x == desTiledPos.x and self.mDestTilePos.y == desTiledPos.y then
        if finishCallback ~= nil then
            finishCallback(self,RASpriteConfig.SpriteFinishStatus.DestPosNotRight)
        end  
        return 
    end
    -- 寻路
    local path = nil
    local tempOriPos = ccp(oriTiledPos.x,oriTiledPos.y)
    local tempDesPos = ccp(desTiledPos.x,desTiledPos.y)
    AStarPathManager:getInstance():find(tempOriPos, tempDesPos)
    tempDesPos:delete()
    tempOriPos:delete()

    local pathLength = getPathLength()

    local frameInfo = self.frameInfo
    if (pathLength == 0) then
        -- common:log("you are right there or been blocked")
        if finishCallback ~= nil then
            finishCallback(self,RASpriteConfig.SpriteFinishStatus.NoPathToDestPos)
        end  
        return
    else
        --common:log("found the path")
    end
    --标记目标Tile pos为当前pos
    self.mDestTilePos  = ccp(desTiledPos.x,desTiledPos.y)
    local array = CCArray:create();
    local lastDirection = self.actionController.currentDirection
    self.ccbfile:stopActionByTag(EnumManager.ACTION_TAG.MOVE_TAG)
    for i = 0, pathLength-1, 1 do
        local lastPos = oriTiledPos
        local lastSpacePos = oriSpacePos
        if i > 0 then
            local x = getAstarPathX(i-1)
            local y = getAstarPathY(i-1)
            lastPos = ccp(x,y)
            lastSpacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,lastPos)
        end
        local oneX = getAstarPathX(i)
        local oneY = getAstarPathY(i)
        local onePos = ccp(oneX,oneY)
        local nextPos = RACcp(oneX,oneY)
        -- common:log("-------------- path %d onePos,x %d, y %d",i,onePos.x,onePos.y)
        local direction = RACitySceneManager:judgeNextDirection(lastPos, onePos)
        if i == (pathLength -1) then
            lastDirection = direction
        end
        local spacepos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,onePos)
        --calc distance between last pos and now pos
        local distance = ccpDistance(spacepos,lastSpacePos)
        --calc move time and speed
        local speed = frameInfo.moveSpeed
        if isWalk~=nil and isWalk == true then
            speed = speed * 0.25
        end
        local time = distance / speed
        --sprite move action
        local runAction = CCCallFunc:create( function()
            if isWalk ~= nil and isWalk == true then
                self:changeAction(EnumManager.ACTION_TYPE.ACTION_WALK, direction)
            else
                self:changeAction(EnumManager.ACTION_TYPE.ACTION_RUN, direction)
            end
            
            self:checkPlayerStatus(nextPos)
        end )
        
        array:addObject(runAction)
        array:addObject(CCMoveTo:create(time, spacepos));
        spacepos:delete()
        onePos:delete()
        --lastPos:delete()
    end
    local idleAction = CCCallFunc:create( function()
        self:changeAction(EnumManager.ACTION_TYPE.ACTION_IDLE, lastDirection)
        self:checkPlayerStatus()     
        if finishCallback ~= nil then
            finishCallback(self,RASpriteConfig.SpriteFinishStatus.FinishPath)
        end   
    end )
    array:addObject(idleAction)
    --开始播放动作
    local action = CCSequence:create(array);
    action:setTag(EnumManager.ACTION_TAG.MOVE_TAG);
    self.ccbfile:runAction(action)
    --common:log("start move,run action")
    array:removeAllObjects()
    array:release()
    oriSpacePos:delete()
end


return RASprite
--endregion
