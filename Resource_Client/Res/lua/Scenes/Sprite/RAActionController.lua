--region RAActionController.lua
--Date 2016/6/12
--Author zhenhui
--此文件由[BabeLua]插件自动生成
local RAActionController = {}
local EnumManager = RARequire("EnumManager")
function RAActionController:new(container,aniData)
    local o =  {}
    self.__index = self
    setmetatable(o, self)
    o.container = container 
    o.AllActionData = aniData
    o.sprite = container:getCCSpriteFromCCB("mSprite")
    o.working = true
    o.currentAction = EnumManager.ACTION_TYPE.ACTION_IDLE
    o.currentDirection = EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT
    o:updateAction(o.currentAction, o.currentDirection)
    return o
end

function RAActionController:release()
    if self.AllActionData ~= nil then
        self.AllActionData:release()
    end
end



function RAActionController:changeAction(actionType, direction, callback,isforce)
    if self.AllActionData == nil or self.container == nil then return end

    if not isforce and self.currentAction == actionType and self.currentDirection == direction then
        return
    end

    self:updateAction(actionType, direction, callback)
end

function RAActionController:updateAction(actionType, direction, callback)
    if self.AllActionData == nil or self.container == nil or self.working==false then return end

    local actionId = actionType .. "_" .. direction

    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction)
    local frameInfo = self.AllActionData:getFrameInfo()
    if oneAction then
        self.sprite:stopAllActions();
        self.sprite:removeAllChildren()
                
        -- first sprite
        self.sprite:setDisplayFrame(oneAction.firstFrame)
        -- 调整锚点
        local size = self.sprite:getContentSize();
        local dx = frameInfo.dx / size.width
        local dy = frameInfo.dy / size.height
        self.sprite:setAnchorPoint(ccp(dx, dy));
        -- effect
        --
        -- flip
        self.sprite:setFlipX(DirectionFlip[direction] ~= direction)
                
        --
        local actionHander = oneAction.action
        if actionHander ~= nil then
            if callback ~= nil then
                local array = CCArray:create()
                array:addObject(actionHander)
                local funcAction = CCCallFunc:create(callback)
                array:addObject(funcAction)
                local seq = CCSequence:create(array);
                self.sprite:runAction(seq);
            else
                self.sprite:runAction(actionHander);
            end

        end
    end

    if self.onActionChange~=nil then 
        self.onActionChange(self.container,actionType,direction)
    end

    self.currentDirection = direction
    self.currentAction = actionType

end


return RAActionController
--endregion
