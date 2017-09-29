--region RAFU_State_TankMove.lua
--战斗单元的TANK移动类
--Date 2016/11/25
--Author zhenhui
local RAFU_State_BaseMove = RARequire("RAFU_State_BaseMove")
local RAFU_State_TankMove = class('RAFU_State_TankMove',RAFU_State_BaseMove)


function RAFU_State_TankMove:Enter(data)
    -- 状态本身需要execute
    
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    self.frameTime = 0.0
    self.localAlive = true
    local targetId = data.targetId
    local curTilePos = data.curPos
    local moveTilePos = data.movePos
    --计算space坐标
    local curSpacePos = self.fightUnit:getPosition()
    local spacepos = RABattleSceneManager:tileToSpace(moveTilePos)
    --计算移动角度及时间
    local curDir = self.fightUnit:getDir()

    local lastDir = curDir

    local direction = self:_calcMoveDirAndTime(data,curTilePos,moveTilePos,curDir)

    self.targetPos = moveTilePos;

    --设置移动方向
    self.fightUnit:setDir(direction)
    self.startPos = curSpacePos
    self.moveSpeed = RACcp(0,0)

    --如果有移动格子，做移动action,否则，不处理，等待时间完成
    if direction ~= FU_DIRECTION_ENUM.DIR_NONE then
        local array = CCArray:create()
        --转角DelayAction
        if self.turnPeriod > 0 then 
            local delay = CCDelayTime:create(self.turnPeriod)
            array:addObject(delay)
        end
        --移动action
        local tmpPos = ccp(spacepos.x,spacepos.y)
        local moveAction = nil 
        if lastDir ~= direction then
            self:SetIsExecute(false)
            moveAction = CCEaseSineInOut:create(CCMoveTo:create(self.moveTime, tmpPos))
            array:addObject(moveAction)
            tmpPos:delete()
            local seq = CCSequence:create(array);
            self.fightUnit.rootNode:runAction(seq)
        else
            self:SetIsExecute(true)
            self.moveSpeed = RACcp((spacepos.x- curSpacePos.x)/self.moveTime,(spacepos.y- curSpacePos.y)/self.moveTime)
        end
        
        

        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            if boneController.boneData.isTop == false then
                boneController:changeAction(ACTION_TYPE.ACTION_RUN,direction)
            end
        end
    end

    --处理TANK炮管对准逻辑

    if targetId ~=nil then 
        local targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)

        direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)

        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            if boneController.boneData.isTop then
                boneController:changeAction(ACTION_TYPE.ACTION_RUN,direction)
            end
        end
    end 
end

return RAFU_State_TankMove
--endregion
