--region RAFU_State_BaseMove.lua
--战斗单元的基础移动类
--Date 2016/11/19
--Author zhenhui
local EnumManager = RARequire("EnumManager")
local RAFU_Math = RARequire("RAFU_Math")
local RAFU_State_BaseMove = class('RAFU_State_BaseMove',RARequire("RAFU_Object"))

function RAFU_State_BaseMove:ctor(unit)
    -- RALog("RAFU_State_BaseMove:ctor")
    self.fightUnit = unit;
    self.frameTime = 0.0
    self.switchDirTime = 0.3
    self.timeFactor = 1.0
    self.debugMode = false
end

function RAFU_State_BaseMove:release()
    -- RALog("RAFU_State_BaseMove:release")
    self.fightUnit = nil;
end

--计算移动的方向以及移动，转向，总共的时间
function RAFU_State_BaseMove:_calcMoveDirAndTime(data,from,to,curDir)    
    -- RALogInfo('...............................................')
    -- RALogInfo('RAFU_State_BaseMove:Enter() ')
    -- RALogInfo('unit id:'.. self.fightUnit.id.. ' itemId = '..self.fightUnit.data.confData.id)
    -- RALogInfo('...............................................')
    local unitData = self.fightUnit.data

    local movePeriod = unitData.movePeriod
    local turnPeriod = unitData.turnPeriod

    local moveDir = RAFU_Math:calcMoveDir(from,to)
    --基础移动时间，以客户端右上移动为基准单位U，向上移动为 1/U,向右移动为2/u
    if moveDir == FU_DIRECTION_ENUM.DIR_UP or moveDir == FU_DIRECTION_ENUM.DIR_DOWN then
        local disRatio = 1.0 / DIAGONAL_RATIO;
        movePeriod = movePeriod* disRatio;
    elseif moveDir == FU_DIRECTION_ENUM.DIR_LEFT or moveDir == FU_DIRECTION_ENUM.DIR_RIGHT then
        local disRatio = 2.0 / DIAGONAL_RATIO;
        movePeriod = movePeriod* disRatio;
    end
    
    --转向移动时间
    self.turnPeriod = 0
    if curDir ~= moveDir then
        local turnTimes = RAFU_Math:calcDirTurnTimes(curDir,moveDir)
        if turnPeriod > 0 then
            self.turnPeriod = turnPeriod * turnTimes/2.0
        end
    end
    local mergeTime = data.mergerTime or 1
    self.moveTime = movePeriod * mergeTime
    --如果服务器传过来turnPeriod和movePerid，则以服务器为主
    if data.turnPeriod ~= nil then
        if self.turnPeriod - data.turnPeriod > 0.1 then
            -- assert(false,"false")
        end
        self.turnPeriod = data.turnPeriod

    end
    if data.movePeriod ~= nil then
        if self.moveTime - data.movePeriod > 0.1 then
            assert(false,"false")
        end
        self.moveTime = data.movePeriod
    end

    if data.actionTime ~= nil then
        self.moveTime = data.actionTime/1000 - self.turnPeriod
    end

    local totalTime = self.turnPeriod + self.moveTime

    self.moveEndTime = totalTime
    return moveDir
end

function RAFU_State_BaseMove:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    -- RALog("RAFU_State_BaseMove:Enter")
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

    self.startPos = curSpacePos
    self.targetPos = moveTilePos;

    --设置移动方向
    self.fightUnit:setDir(direction)

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
        -- local tmpPos = ccp(spacepos.x,spacepos.y)
        -- local moveAction = CCMoveTo:create(self.moveTime, tmpPos)
        -- array:addObject(moveAction)
        -- tmpPos:delete()
        -- local seq = CCSequence:create(array);
        -- self.fightUnit.rootNode:runAction(seq)

        self.moveSpeed = RACcp((spacepos.x- curSpacePos.x)/self.moveTime,(spacepos.y- curSpacePos.y)/self.moveTime)

        for boneName,boneController in pairs(self.fightUnit.boneManager) do

            local maxFrame = boneController:getFrameCount(ACTION_TYPE.ACTION_RUN,direction)
            local _startFrame = math.random(0,maxFrame-1)
            local param = {
                callback = nil,--回调
                needSwitch = true,--是否强制转向  
                isforce = false,--是否强制改变动作
                newFps = nil,--新的播放fps
                startFrame = _startFrame--新的开始帧
            }
            boneController:changeAction(ACTION_TYPE.ACTION_RUN,direction,param)
        end
    end
end

function RAFU_State_BaseMove:Execute(dt)
    --RALog("RAFU_State_BaseMove:Execute self.frameTime is "..self.frameTime.."  self.id is "..self.fightUnit.data)
    if self.moveEndTime == nil then return end
    self.frameTime = self.frameTime + dt
    local costTime = self.moveEndTime or 1

    if self.localAlive then
        if self.frameTime > costTime then
            self.frameTime = 0
            self.localAlive = false
            self:SetIsExecute(false)
        else
            local deltaPos = RACcpMult(self.moveSpeed,self.frameTime)
            local newPos = RACcpAdd(deltaPos,self.startPos)
            self.fightUnit.rootNode:setPosition(newPos.x,newPos.y)
        end
    end
end

function RAFU_State_BaseMove:Exit()
    -- RALog("RAFU_State_BaseMove:Exit")
    self.frameTime = 0
end

return RAFU_State_BaseMove
--endregion
