--[[
description: 
 单个导弹的技能

author: zhenhui
date: 2017/1/10
]]--

local RAFS_Skill_OneMissile = class('RAFS_Skill_OneMissile',RARequire("RAFS_Skill_Base"))
local ParabolaPartType = RARequire('RAFU_Cfg_OribitCalc_OneMissile').ParabolaPartType


local CalcMissileDisapperBeforeTime = 0.15

--技能飞行过程 SkillCast阶段开始
function RAFS_Skill_OneMissile:Enter(data)
    self.super.Enter(self, data)

    -- 技能飞行时间，根据这个时间反推速度
    self.moveEndTime = data.waitTime or 3.0
    self.mPartType = 0

    self.skillId = data.skillId
    local skillEffectCfg = RARequire('RAFU_Cfg_PlayerSkill')[self.skillId]
    assert(skillEffectCfg, 'skill id:'..self.skillId..' cfg is nil')

    -- create effect
    local mainClass = skillEffectCfg.main.EffectFrameClass
    local mainCfgName = skillEffectCfg.main.EffectFrameCfgName
    self.boneEffect = RARequire(mainClass).new(mainCfgName)
    self.boneEffect:setVisible(false)

    -- create shadow
    -- 把影子放在v3节点上，防止层级出错
    local sub1Class = skillEffectCfg.sub1.EffectFrameClass
    local sub1CfgName = skillEffectCfg.sub1.EffectFrameCfgName
    self.shadowEffect = RARequire(sub1Class).new(sub1CfgName)
    self.shadowEffect:setVisible(false)

    -- create calc
    local param = self:_prepareInputParam(data)    
    self.targetSpacePos = param.position.main.endPos
    self.isEffectShowed = false
    local startSpacePos = param.position.main.startPos    
    local boneEffectData = {
        targetSpacePos = startSpacePos,
        lifeTime = self.moveEndTime,
        -- 自己不做删除
        isExecute = false
    }
    self.boneEffect:Enter(boneEffectData)
    self.shadowEffect:Enter(
    {
        pararentNode = self.boneEffect.backNode,
        lifeTime = self.moveEndTime,
        -- 自己不做删除，由父对象删除
        isExecute = false
    })

    local oribitCalc = RARequire('RAFU_OribitCalc_CommonParabola').new(param)
    if oribitCalc.mIsNewSuccess then
        self.mOribitCalc = oribitCalc       
        local calcDatas = self.mOribitCalc:Begin()      
        local Utilitys = RARequire('Utilitys')
        self.mInitRootPos = Utilitys.ccpCopy(calcDatas.main.pos)
        self:_HandleCalcDatas(calcDatas, true)
    end
    self.boneEffect:setVisible(true)
    self.shadowEffect:setVisible(true)

    self.mEffectHanlder = {}
    local UIExtend = RARequire('UIExtend')
    local ccbfile = UIExtend.loadCCBFileWithOutPool('RABattle_Ani_MissileFire1.ccbi', self.mEffectHanlder)
    self.boneEffect.beforeNode:addChild(ccbfile)
end



function RAFS_Skill_OneMissile:_prepareInputParam(data)
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local curTilePos = RARequire("RAFightSkillSystem"):getSkillFirePos()
    local moveTilePos = data.targetPos

    local curSpacePos = RABattleSceneManager:tileToSpace(curTilePos)
    local spacepos = RABattleSceneManager:tileToSpace(moveTilePos)

    local param = {}
    -- 配置参数使用单个炮弹的配置
    param.cfg = {}
    param.cfg.dirCfg = RARequire('RAFU_Cfg_OribitCalc_OneMissile').ParabolaDirCfg
    param.cfg.partCfg = ParabolaPartType

    -- 影子计算并返回
    param.isCalcShadow = true

    param.position = {}
    param.position.main = {}
    param.position.main.startPos = curSpacePos
    param.position.main.endPos = spacepos    
    -- param.speed = 400
    local Utilitys = RARequire('Utilitys')
    param.pixelDistance = Utilitys.getDistance(curSpacePos, spacepos)
    -- 时间减个固定值，保证先飞到才爆炸，暂时不需要，通过配置有个0.1的时间了
    param.spendTime = (data.waitTime or 3.0) - 0
    param.speed = param.pixelDistance/param.spendTime
    return param
end

-- do nothing
function RAFS_Skill_OneMissile:EnterFly()
    
end


--SkillCast阶段结束

--受伤害的阶段SkillEffect  begin-----------------

--无论如何都会有受击效果或者伤害,父类来处理数据的处理
function RAFS_Skill_OneMissile:EnterEffect(effectActionData)
	self:_HitUnit(effectActionData)
    
    if not self.isEffectShowed then
        self.isEffectShowed = true
        -- 添加爆炸特效
        self:_AddEffect(self.targetSpacePos)
    end
    --移除
    self:Exit()
end


--受伤害的阶段SkillEffect  end-----------------

function RAFS_Skill_OneMissile:Execute(dt)
    if self.moveEndTime == nil then return end
    self.frameTime = self.frameTime + dt

	if self.localAlive and self.mOribitCalc then
        self:_HandleCalcDatas(self.mOribitCalc:Execute(dt))
    end
end


function RAFS_Skill_OneMissile:Exit()
    self.localAlive = false  
    self:_SelfRelease()
    self:release()
end

function RAFS_Skill_OneMissile:_HandleCalcDatas(calcDatas, isInitHandle)
    if calcDatas == nil or self.boneEffect == nil or self.shadowEffect == nil then 
        return 
    end    
    local partType = calcDatas.main.partType
    local direction = calcDatas.main.direction
    local timePart1 = calcDatas.main.timePart1
    local timePart2 = calcDatas.main.timePart2
    if self.mPartType == 0 and partType == ParabolaPartType.PartOne then                        
        local frameCount = self.boneEffect:getFrameCount(ACTION_TYPE.ACTION_IDLE, direction)
        local newFps = frameCount / timePart1
        self.boneEffect:changeAction(ACTION_TYPE.ACTION_IDLE, direction, {newFps = newFps})       

        local shadowFrameCount = self.shadowEffect:getFrameCount(ACTION_TYPE.ACTION_IDLE, direction)
        newFps = shadowFrameCount / timePart1
        self.shadowEffect:changeAction(ACTION_TYPE.ACTION_IDLE, direction, {newFps = newFps})
    end
    if self.mPartType == ParabolaPartType.PartOne and partType == ParabolaPartType.PartTwo then        
        local frameCount = self.boneEffect:getFrameCount(ACTION_TYPE.ACTION_RUN, direction)
        local newFps = frameCount / timePart2
        self.boneEffect:changeAction(ACTION_TYPE.ACTION_RUN, direction, {newFps = newFps})       

        local shadowFrameCount = self.shadowEffect:getFrameCount(ACTION_TYPE.ACTION_RUN, direction)
        newFps = shadowFrameCount / timePart2
        self.shadowEffect:changeAction(ACTION_TYPE.ACTION_RUN, direction, {newFps = newFps})     
    end
    self.mPartType = partType
    self.boneEffect:setVisible(calcDatas.main.isVisible)

    isInitHandle = isInitHandle or false
    -- 第一次设置的时候需要设置rootNode位置，之后execute设置sprite node的相对位置
    if isInitHandle then
        self.boneEffect:setNodePosition('rootNode', calcDatas.main.pos.x, calcDatas.main.pos.y)        
    end
    local spriteGapPos = RACcpSub(calcDatas.main.pos, self.mInitRootPos)
    self.boneEffect:setNodePosition('spriteNode', spriteGapPos.x, spriteGapPos.y)
    self.boneEffect:setNodePosition('beforeNode', spriteGapPos.x, spriteGapPos.y)    

    -- 设置影子
    local shadowGapPos = RACcpSub(calcDatas.sub1.pos, self.mInitRootPos)
    self.shadowEffect:setNodePosition('rootNode', shadowGapPos.x, shadowGapPos.y)

    self.shadowEffect:setNodeRotation('rootNode', calcDatas.sub1.rotation)
    self.boneEffect:setNodeRotation('spriteNode', calcDatas.main.rotation)

     -- 提前隐藏炮弹炮体
    local oneCalcLastTime = self.moveEndTime - self.frameTime
    -- RAFU_Effect_bone:setNodeVisible
    if oneCalcLastTime < CalcMissileDisapperBeforeTime then
        self.boneEffect:setNodeVisible('spriteNode', false)
        self.shadowEffect:setNodeVisible('rootNode', false)
        if not self.isEffectShowed then
            self.isEffectShowed = true
            -- 添加爆炸特效
            self:_AddEffect(self.targetSpacePos)
        end
    end
    
    
    if calcDatas.isEnd then
        self:_SelfRelease()
    end
end


function RAFS_Skill_OneMissile:_SelfRelease()
    self.frameTime = 0
    self.localAlive = false

    if self.mOribitCalc then
        self.mOribitCalc:release()
        self.mOribitCalc = nil
    end
    if self.mEffectHanlder then
        local UIExtend = RARequire('UIExtend')
        UIExtend.unLoadCCBFile(self.mEffectHanlder)
        self.mEffectHanlder = nil
    end

    self.mInitCalcData = nil

    if self.shadowEffect then
        self.shadowEffect:release()
        self.shadowEffect = nil
    end

    if self.boneEffect then
        self.boneEffect:setVisible(false)
        self.boneEffect:release()
        self.boneEffect = nil
    end
end


-- 添加爆炸特效
function RAFS_Skill_OneMissile:_AddEffect(pos)
    -- 添加震屏        
    MessageManager.sendMessage(MessageDef_RootManager.MSG_SceneShake)
    
    local skillEffectCfg = RARequire('RAFU_Cfg_PlayerSkill')[self.skillId]
    assert(skillEffectCfg, 'skill id:'..self.skillId..' cfg is nil')
    local effectClass = skillEffectCfg.skillEndCfg.EffectFrameClass
    local effectCfgName = skillEffectCfg.skillEndCfg.EffectFrameCfgName
    local effectInstance = RARequire(effectClass).new(effectCfgName)            
    RA_SAFE_ENTER(effectInstance, {targetSpacePos = pos})
end


return RAFS_Skill_OneMissile