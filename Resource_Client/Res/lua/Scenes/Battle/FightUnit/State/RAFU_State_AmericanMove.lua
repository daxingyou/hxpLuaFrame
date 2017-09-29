--region RAFU_State_BaseMove.lua
--美国大兵的移动类
--hulei
local EnumManager = RARequire("EnumManager")
local RAFU_Math = RARequire("RAFU_Math")
local RAFU_State_AmericanMove = class('RAFU_State_AmericanMove',RARequire("RAFU_State_BaseMove"))

function RAFU_State_AmericanMove:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    -- RALog("RAFU_State_AmericanMove:Enter")
    
    self.frameTime = 0.0
    self.localAlive = true
    self.data = data
    self.moveEndTime = 10
    self.standTime = 0
    self.beginMove = false
    if self.fightUnit.state == EnumManager.UNIT_STATE.SIT then
        self.fightUnit.state = EnumManager.UNIT_STATE.STAND
        self.standTime = 0.2
        --自身的动作相关
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            boneController:changeAction(ACTION_TYPE.ACTION_SIT_UP,self.fightUnit:getDir())        
        end     
    end    


end

function RAFU_State_AmericanMove:startMove(  )
    local data = self.data
    self.beginMove = true
    local targetId = data.targetId
    local curTilePos = data.curPos
    local moveTilePos = data.movePos
    --计算space坐标
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local curSpacePos = RABattleSceneManager:tileToSpace(curTilePos)
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

function RAFU_State_AmericanMove:Execute(dt)
    --RALog("RAFU_State_AmericanMove:Execute self.frameTime is "..self.frameTime.."  self.id is "..self.fightUnit.data)
    if self.localAlive == true then
        if self.moveEndTime == nil then return end
        self.frameTime = self.frameTime + dt
        local costTime = self.moveEndTime or 1

        if self.localAlive then
            if not self.beginMove and self.frameTime > self.standTime then
                self:startMove()
            end
            if self.beginMove then
                if self.frameTime > costTime then
                    self.frameTime = 0
                    self.localAlive = false
                    self.beginMove = false
                    self:SetIsExecute(false)
                else
                    local deltaPos = RACcpMult(self.moveSpeed,self.frameTime)
                    local newPos = RACcpAdd(deltaPos,self.startPos)
                    self.fightUnit.rootNode:setPosition(newPos.x,newPos.y)
                end
            end
        end
    end

    
end

function RAFU_State_AmericanMove:Exit()
    -- RALog("RAFU_State_AmericanMove:Exit")
    self.frameTime = 0
end

return RAFU_State_AmericanMove
--endregion
