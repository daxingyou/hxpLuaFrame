--region RAFU_State_ParatrooperFly.lua
--伞兵飞行状态
--Date 2016/12/29
--Author qinho
local RAFU_State_ParatrooperFly = class('RAFU_State_ParatrooperFly',RARequire("RAFU_State_BaseFly"))
local RAFU_Math = RARequire('RAFU_Math')

function RAFU_State_ParatrooperFly:Enter(data)
    RALogInfo("***********************************************")
    RALogInfo("RAFU_State_ParatrooperFly:Enter")
    RALogInfo("***********************************************")
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    local targetId = data.targetId
    local curTilePos = data.fromPos
    local moveTilePos = data.targetPos
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    self.targetSpacePos = RABattleSceneManager:tileToSpace(moveTilePos)

    self.spendTime = data.flyTime/1000.0    
    self.lifeTime = self.spendTime
    self.frameTime = 0

    -- 做个随机的生成时间效果
    self.prepareTime = math.random(1, 20) / 40.0

    
    self.statePart1 = 0
    self.statePart2 = 0
    self.statePart3 = 0
    self.fightUnit:setTilePos(moveTilePos)
    local coreBoneName = self.fightUnit.cfgData.Bones.CoreBone
    local coreBoneManager = self.fightUnit.boneManager[coreBoneName]
    if coreBoneManager ~= nil then
        local boneCfg = self.fightUnit.cfgData.Bones[coreBoneName]
        self.imageOffsetY = boneCfg.imageOffsetY

        -- 开伞时间，方向只有1个
        self.partTime1 = coreBoneManager:getFrameTime(ACTION_TYPE.ACTION_RUN, 0)
        -- 收伞时间，方向只有1个
        self.partTime3 = coreBoneManager:getFrameTime(ACTION_TYPE.ACTION_ATTACK, 0)
        self.boneManager = coreBoneManager
    end
end


function RAFU_State_ParatrooperFly:Execute(dt)
    self.frameTime = self.frameTime + dt
    if self.boneManager == nil then return end

    if self.frameTime >= self.prepareTime then
        if self.statePart1 == 0 then
            -- 开伞
            self.boneManager:changeAction(ACTION_TYPE.ACTION_RUN, 0)
            self.statePart1 = 1
        else
            if self.frameTime - self.prepareTime >= self.partTime1 then    
                if self.frameTime < self.spendTime - self.partTime3 then
                    if self.statePart2 == 0 then
                        -- 空中
                        self.statePart2 = 1
                        self.boneManager:changeAction(ACTION_TYPE.ACTION_IDLE, 0)
                    end
                else
                    if self.statePart3 == 0 then
                        -- 收伞
                        self.statePart3 = 1
                        self.boneManager:changeAction(ACTION_TYPE.ACTION_ATTACK, 0)
                    end
                end
            end
        end
    end

    
    local percent = RAFU_Math:CalcPastTimePercent(self.frameTime, self.spendTime)
    local posY = self.imageOffsetY * (1 - percent)
    if self.boneManager then
        self.boneManager.sprite:setPositionY(posY)
    end
end

function RAFU_State_ParatrooperFly:Exit()
    
end

return RAFU_State_ParatrooperFly
--endregion
