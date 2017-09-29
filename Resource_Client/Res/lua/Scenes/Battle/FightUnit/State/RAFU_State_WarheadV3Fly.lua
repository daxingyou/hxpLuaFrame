--region RAFU_State_WarheadV3Fly.lua
-- v3炮弹的移动类
--Date 2016/12/16
--Author qinho
local RAFU_State_BaseFly = RARequire("RAFU_State_BaseFly")
local RAFU_State_WarheadV3Fly = class('RAFU_State_WarheadV3Fly',RAFU_State_BaseFly)

local ParabolaPartType = RARequire('RAFU_Cfg_OribitCalc_ParabolaV3').ParabolaPartType

-- enter 的时候
-- 1、设置v3炮弹位置和初始旋转，需要保证和v3车上的炮弹贴合
-- 2、创建轨迹计算
function RAFU_State_WarheadV3Fly:Enter(data)    
    self.super.Enter(self, data)
    
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    self.localAlive = true
    self.mOribitCalc = nil

    self.mEffectHanlder = nil

    self.mPartType = 0

    self.fightUnit:setRootNodeVisible(false)
    local param = self:_prepareInputParam(data)
    self.moveEndTime = param.spendTime - 0.2
    if self.moveEndTime > 0 then
        -- 抛物线轨迹
        local oribitCalc = RARequire('RAFU_OribitCalc_CommonParabola').new(param)
        -- local oribitCalc = RAFU_OribitCalc_Straight.new(param)
        if oribitCalc.mIsNewSuccess then
            self.mOribitCalc = oribitCalc       
            local calcDatas = self.mOribitCalc:Begin()      
            self:_HandleCalcDatas(calcDatas)
        end
        self.fightUnit:setRootNodeVisible(true)

        self.mEffectHanlder = {}
        local UIExtend = RARequire('UIExtend')
        local ccbfile = UIExtend.loadCCBFileWithOutPool('RABattle_Ani_V3Fire.ccbi', self.mEffectHanlder)
        self.fightUnit.beforeEffectNode:addChild(ccbfile)
    end    
    return
end


function RAFU_State_WarheadV3Fly:_prepareInputParam(data)
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = data.targetId
    local curTilePos = data.fromPos
    local moveTilePos = data.targetPos

    --计算space坐标
    local curSpacePos = RABattleSceneManager:tileToSpace(curTilePos)
    local spacepos = RABattleSceneManager:tileToSpace(moveTilePos)
    -- spacepos.y = curSpacePos.y
    --test
    -- if isAdd then
    --     spacepos = RACcpAdd(curSpacePos, RACcp(500, 0))
    --     isAdd = false
    -- else
    --     spacepos = RACcpAdd(curSpacePos, RACcp(-500, 0))
    --     isAdd = true
    -- end

    local param = {}

    -- 配置参数使用单个炮弹的配置
    param.cfg = {}
    param.cfg.dirCfg = RARequire('RAFU_Cfg_OribitCalc_ParabolaV3').ParabolaV3Cfg
    param.cfg.partCfg = ParabolaPartType

    -- 影子计算并返回
    param.isCalcShadow = false

    param.position = {}
    param.position.main = {}
    param.position.main.startPos = curSpacePos
    param.position.main.endPos = spacepos    
    param.speed = 200
    local Utilitys = RARequire('Utilitys')
    param.pixelDistance = Utilitys.getDistance(curSpacePos, spacepos)

    --使用服务器传过来的时间
    if data.isDebug then        
        param.spendTime = param.pixelDistance / param.speed
    else
        -- 暂时方法
        -- 减去一个固定值，保证fly state能够执行完毕
        param.spendTime = data.flyTime /1000.0 - 0.2
        print('...............................................')
        print('RAFU_State_WarheadV3Fly:Enter(dt)   fly time:'..data.flyTime)
        print('...............................................')
        param.speed = param.pixelDistance/param.spendTime
    end
    return param
end


-- 逐帧计算炮弹的位置和旋转，并设置
function RAFU_State_WarheadV3Fly:Execute(dt)
    if self.moveEndTime == nil then return end
    self.frameTime = self.frameTime + dt
    -- local costTime = self.moveEndTime or 1
    -- if self.frameTime > costTime and self.localAlive then
    --     self.frameTime = 0
    --     self.localAlive = false

    --     if self.mOribitCalc then
    --         self.mOribitCalc:release()
    --     end
    --     if self.mEffectHanlder then
    --         local UIExtend = RARequire('UIExtend')
    --         UIExtend.unLoadCCBFile(self.mEffectHanlder)
    --         self.mEffectHanlder = nil
    --     end

    --     -- self.fightUnit.rootNode:setVisible(false)
    --     print('...............................................')
    --     print('RAFU_State_WarheadV3Fly:Execute(dt)    fly End')
    --     print('...............................................')

    --     self:PlayFlyEndEffect()
    -- end
    if self.localAlive and self.mOribitCalc then
        self:_HandleCalcDatas(self.mOribitCalc:Execute(dt))
    end

end

function RAFU_State_WarheadV3Fly:Exit()
    -- RALog("RAFU_State_BaseMove:Exit")
    if self.mOribitCalc then
        self.mOribitCalc:release()
    end
    if self.mEffectHanlder then
        local UIExtend = RARequire('UIExtend')
        UIExtend.unLoadCCBFile(self.mEffectHanlder)
        self.mEffectHanlder = nil
    end
    self.frameTime = 0
end

function RAFU_State_WarheadV3Fly:_HandleCalcDatas(calcDatas)
    if calcDatas == nil then return end        
    local partType = calcDatas.main.partType
    local direction = calcDatas.main.direction
    local timePart1 = calcDatas.main.timePart1
    local timePart2 = calcDatas.main.timePart2
    if self.mPartType == 0 and partType == ParabolaPartType.PartOne then                
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            local frameCount = boneController:getFrameCount(ACTION_TYPE.ACTION_IDLE, direction)
            local newFps = frameCount / timePart1
            boneController:changeAction(ACTION_TYPE.ACTION_IDLE, direction, {newFps = newFps, isForce = true})
        end        
    end
    if self.mPartType == ParabolaPartType.PartOne and partType == ParabolaPartType.PartTwo then        
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            local frameCount = boneController:getFrameCount(ACTION_TYPE.ACTION_RUN, direction)
            local newFps = frameCount / timePart2
            boneController:changeAction(ACTION_TYPE.ACTION_RUN, direction, {newFps = newFps, isForce = true})
        end        
    end
    self.mPartType = partType
    self.fightUnit.rootNode:setPosition(calcDatas.main.pos.x, calcDatas.main.pos.y)
    self.fightUnit.spriteNode:setRotation(calcDatas.main.rotation)
    self.fightUnit.beforeEffectNode:setRotation(calcDatas.sub2.rotation)

    if not calcDatas.main.isVisible then
        self.fightUnit:setRootNodeVisible(false)
    end

    if calcDatas.isEnd then
        self.frameTime = 0
        self.localAlive = false

        if self.mOribitCalc then
            self.mOribitCalc:release()
        end
        if self.mEffectHanlder then
            local UIExtend = RARequire('UIExtend')
            UIExtend.unLoadCCBFile(self.mEffectHanlder)
            self.mEffectHanlder = nil
        end

        self.fightUnit:setRootNodeVisible(false)
        print('...............................................')
        print('RAFU_State_WarheadV3Fly:_HandleCalcDatas    fly End')
        print('...............................................')

        self:PlayFlyEndEffect()
    end
end

return RAFU_State_WarheadV3Fly
--endregion
