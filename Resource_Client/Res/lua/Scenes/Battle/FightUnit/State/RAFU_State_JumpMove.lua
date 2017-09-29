--region RAFU_State_JumpMove.lua
--战斗单元的Jump移动类
--Author hulei
local EnumManager = RARequire("EnumManager")
local RAFU_Math = RARequire("RAFU_Math")
local RAFU_State_BaseMove = RARequire("RAFU_State_BaseMove")
local RAFU_State_JumpMove = class('RAFU_State_JumpMove',RAFU_State_BaseMove)
local JUMPACTIONTAG = 10086


function RAFU_State_JumpMove:Enter(data)
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
    local direction = self:_calcMoveDirAndTime(data,curTilePos,moveTilePos,curDir)

    self.targetPos = moveTilePos;


    local array = CCArray:create()

    if direction ~= FU_DIRECTION_ENUM.DIR_NONE then      

        local changeDir = RAFU_Math:calcDirTurnTimes(curDir, direction)
        if (math.abs(moveTilePos.x - curTilePos.x) > 0 or math.abs(moveTilePos.y - curTilePos.y) > 0) 
            and (changeDir > 4 or (changeDir == 4 and math.random(100) < 50)) then -- 弧形转向
            --转角DelayAction
            if self.turnPeriod > 0 then 
                local cfgWidth
                if math.abs(moveTilePos.x - curTilePos.x) > 0 then
                    cfgWidth = RABattleSceneManager:getTileSizeWidth() * 2
                else
                    cfgWidth = RABattleSceneManager:getTileSizeHeight() * 2
                end
                local moveRatio = DirectionAngle_DIR16[direction]
                local curRatio = DirectionAngle_DIR16[curDir]
                if changeDir == 8 then
                    curRatio = curRatio + 45
                end
                local distance = RACcpDistance(curSpacePos, spacepos)
                local controlPointLen1 = cfgWidth/(math.cos(math.rad(curRatio - 90 -moveRatio)))
                local controlPointLen2 = math.sqrt(distance*distance + cfgWidth*cfgWidth)
                local controlRadio = math.atan(cfgWidth / distance)
                local flag = controlPointLen1/math.abs(controlPointLen1)
                local cfg = ccBezierConfig:new()
                cfg.endPosition = ccp(spacepos.x - curSpacePos.x,spacepos.y - curSpacePos.y)
                cfg.controlPoint_1 = ccp(math.abs(controlPointLen1) * math.cos(math.rad(curRatio)), math.abs(controlPointLen1) * math.sin(math.rad(curRatio)))
                cfg.controlPoint_2 = ccp(controlPointLen2*math.cos(math.rad(moveRatio + controlRadio*flag)), controlPointLen2*math.sin(math.rad(moveRatio + controlRadio*flag) ))
                local bezierBy = CCEaseSineInOut:create(CCBezierBy:create(self.turnPeriod + self.moveTime,cfg))
                array:addObject(bezierBy)
            end
        else
            --移动action
            local tmpPos = ccp(spacepos.x,spacepos.y)
            local moveAction = CCEaseSineInOut:create(CCMoveTo:create(self.moveTime, tmpPos))
            array:addObject(moveAction)
            tmpPos:delete()
        end
        --设置移动方向
        self.fightUnit:setDir(direction)
    
        
        array:addObject(CCCallFunc:create(function ( ... )
            self.fightUnit:changeState(STATE_TYPE.STATE_IDLE)
        end))
        local seq = CCSequence:create(array);
        self.fightUnit.rootNode:runAction(seq)

        if self.fightUnit.coreBone then
            self.fightUnit.coreBone:changeAction(ACTION_TYPE.ACTION_RUN,direction)
        end
    end
end

return RAFU_State_JumpMove
--endregion