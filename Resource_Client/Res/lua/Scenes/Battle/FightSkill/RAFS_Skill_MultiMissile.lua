--[[
description: 
 多个导弹的技能

author: zhenhui
date: 2017/1/13
]]--

local RABattleSceneManager = RARequire("RABattleSceneManager")
local Utilitys = RARequire('Utilitys')

local RAFS_Skill_MultiMissile = class('RAFS_Skill_MultiMissile',RARequire("RAFS_Skill_Base"))

local ParabolaPartType = RARequire('RAFU_Cfg_OribitCalc_MultiMissile').ParabolaPartType

local CalcMissileDisapperBeforeTime = 0.1


--技能飞行过程 SkillCast阶段开始
function RAFS_Skill_MultiMissile:Enter(data)
    self.super.Enter(self, data)

    -- 技能飞行时间，根据这个时间反推速度
    self.moveEndTime = data.waitTime or 3.0    

    self.skillId = data.skillId
    local skillEffectCfg = RARequire('RAFU_Cfg_PlayerSkill')[self.skillId]
    assert(skillEffectCfg, 'skill id:'..self.skillId..' effect cfg is nil')

    local skillCfg = RARequire('battle_player_skill_conf')[self.skillId]
    assert(skillCfg, 'skill id:'..self.skillId..' cfg is nil')    
    self.calcNum = skillCfg.wave or 5
    local radian = skillCfg.range or 5

    -- [
    --     {
    --         boneEffect = {},
    --         shadowEffect = {},
    --         oribitCalc = {},
    --         initRootPos = {},
    --         targetSpacePos = {},
    --         effectHanlder = {},
    --         partType = 0,
    --         isBegan = false,            -- 轨迹是否开始计算
    --         isEffectShowed = false,     -- 特效是否已经添加
    --         frameBegan = 0,             -- 特效开始的时间
    --     }
    -- ]
    self.mCalcList = {}

    
    local posList = nil

    -- 多重技能释放的时候，随机发射时间的百分比
    local randomStartPer = skillEffectCfg.extraParams.MultiMissileFlyTimeRandomStartPer
    local randomEndPer = skillEffectCfg.extraParams.MultiMissileFlyTimeRandomEndPer
    -- 随机数最大值
    local randomMax = skillEffectCfg.extraParams.MultiMissileFlyTimeRandomMax

    local timeList = nil 
    local isPbInit = false
    if data.bombInfo ~= nil then        
        self.calcNum = #data.bombInfo
        isPbInit = true
    else    
        local posMap =  RABattleSceneManager:getRandomPos(data.targetPos, radian, self.calcNum)
        posList = Utilitys.table2Array(posMap)
        if skillEffectCfg.extraParams.IsRandom then
            local timeMap = self:_prepareRandomTimeMap(self.calcNum, randomMax)
            timeList = Utilitys.table2Array(timeMap)
        else
            local startPer = skillEffectCfg.extraParams.OneMissileStartTimePer
            local endPer = skillEffectCfg.extraParams.OneMissileEndTimePer
            local timeMap = self:_preparePercentTimeMap(self.calcNum, startPer, endPer)
            timeList = Utilitys.table2Array(timeMap)
        end
        if timeList == nil then 
            RALogError('RAFS_Skill_MultiMissile timeList can not been nil')
            return 
        end
    end

    local mainClass = skillEffectCfg.main.EffectFrameClass
    local mainCfgName = skillEffectCfg.main.EffectFrameCfgName

    local sub1Class = skillEffectCfg.sub1.EffectFrameClass
    local sub1CfgName = skillEffectCfg.sub1.EffectFrameCfgName

    for i=1, self.calcNum do        
        -- create effect                
        local oneCalc = {}
        self.mCalcList[i] = oneCalc
        oneCalc.partType = 0

        oneCalc.boneEffect = RARequire(mainClass).new(mainCfgName)
        oneCalc.boneEffect:setVisible(false)

        -- 把影子放在v3节点上，防止层级出错
        -- create shadow
        oneCalc.shadowEffect = RARequire(sub1Class).new(sub1CfgName)
        oneCalc.shadowEffect:setVisible(false)

        -- calc time
        if isPbInit then
            oneCalc.timeStart = data.bombInfo[i].startTime
            oneCalc.timeSpend = data.bombInfo[i].flyTime
            oneCalc.timeEnd = oneCalc.timeStart + oneCalc.timeSpend
        else
            oneCalc.timeStart = timeList[i].startPer * self.moveEndTime * randomStartPer
            oneCalc.timeEnd = timeList[i].endPer * self.moveEndTime * randomEndPer
            oneCalc.timeSpend = self.moveEndTime - oneCalc.timeStart - oneCalc.timeEnd
        end
        oneCalc.isBegan = false
        -- 特效是否已经添加
        oneCalc.isEffectShowed = false
        -- 特效开始的时间
        oneCalc.frameBegan = 0

        -- create calc
        local moveTilePos = nil
        if isPbInit then
            moveTilePos = data.bombInfo[i].bombPos
        else
            moveTilePos = posList[i]
        end
        local param = self:_prepareInputParam(moveTilePos, oneCalc.timeSpend)    
        local targetSpacePos = param.position.main.startPos
        local boneEffectData = {
            targetSpacePos = targetSpacePos,
            lifeTime = oneCalc.timeSpend,
            -- 自己不做删除
            isExecute = false
        }
        oneCalc.boneEffect:Enter(boneEffectData)
        oneCalc.shadowEffect:Enter(
        {
            pararentNode = oneCalc.boneEffect.backNode,
            lifeTime = oneCalc.timeSpend,
            -- 自己不做删除，由父对象删除
            isExecute = false
        })

        oneCalc.targetSpacePos = param.position.main.endPos
        oneCalc.oribitCalc = RARequire('RAFU_OribitCalc_CommonParabola').new(param)        

        oneCalc.effectHanlder = {}
        local UIExtend = RARequire('UIExtend')
        local ccbfile = UIExtend.loadCCBFileWithOutPool('RABattle_Ani_MissileFire2.ccbi', oneCalc.effectHanlder)
        oneCalc.boneEffect.beforeNode:addChild(ccbfile)
    end
end

function RAFS_Skill_MultiMissile:_prepareRandomTimeMap(calcNum, randomMax)
    local resultMap = {}    
    local index = 0
    if calcNum <= 0 then calcNum = 5 end
    if randomMax <= 0 then randomMax = 30 end
    while(index < calcNum) do
        local random1 = math.random(1, randomMax)
        local random2 = math.random(1, randomMax)
        local key = random1..'_'..random2
        if resultMap[key] == nil then
            resultMap[key] = {
                startPer = random1 / randomMax,
                endPer = random2 / randomMax
            }            
            index = index + 1
        end
    end    
    return resultMap
end

function RAFS_Skill_MultiMissile:_preparePercentTimeMap(calcNum, startPer, endPer)
    local resultMap = {}    
    local index = 0
    if calcNum <= 0 then calcNum = 5 end
    if startPer <= 0 or startPer > 20 then 
        startPer = 5
    end
    if endPer <= 0 or endPer > 20 then 
        endPer = 5
    end

    for i = 1, calcNum do
        resultMap[i] = {}
        resultMap[i].startPer = (i - 1) * startPer * 0.01
        resultMap[i].endPer = 1 - (calcNum - i) * endPer * 0.01
    end
     
    return resultMap
end

function RAFS_Skill_MultiMissile:_prepareInputParam(moveTilePos, waitTime)
    local curTilePos = RARequire("RAFightSkillSystem"):getSkillFirePos()    

    local curSpacePos = RABattleSceneManager:tileToSpace(curTilePos)
    local spacepos = RABattleSceneManager:tileToSpace(moveTilePos)

    local param = {}
    -- 配置参数使用单个炮弹的配置
    param.cfg = {}
    param.cfg.dirCfg = RARequire('RAFU_Cfg_OribitCalc_MultiMissile').ParabolaDirCfg
    param.cfg.partCfg = ParabolaPartType

    -- 影子计算并返回
    param.isCalcShadow = true

    param.position = {}
    param.position.main = {}
    param.position.main.startPos = curSpacePos
    param.position.main.endPos = spacepos    
    -- param.speed = 400
    param.pixelDistance = Utilitys.getDistance(curSpacePos, spacepos)
    -- 时间减个固定值，保证先飞到才爆炸，暂时不需要，通过配置有个0.1的时间了
    param.spendTime = (waitTime or 3.0) - 0
    param.speed = param.pixelDistance/param.spendTime
    return param
end

-- do nothing
function RAFS_Skill_MultiMissile:EnterFly()
    
end


--SkillCast阶段结束

--受伤害的阶段SkillEffect  begin-----------------

--无论如何都会有受击效果或者伤害,父类来处理数据的处理
function RAFS_Skill_MultiMissile:EnterEffect(effectActionData)
	self:_HitUnit(effectActionData)
    -- 从0开始
    if effectActionData.effectIndex >= self.calcNum - 1 then
        --移除
        self:Exit()
    end
end


--受伤害的阶段SkillEffect  end-----------------

function RAFS_Skill_MultiMissile:Execute(dt)
    if self.moveEndTime == nil then return end
    self.frameTime = self.frameTime + dt

    -- -- 计算时间，开始轨迹
    -- for k,oneCalc in pairs(self.mCalcList) do            
    --     if oneCalc.oribitCalc.mIsNewSuccess then            
    --         local calcDatas = oneCalc.oribitCalc:Begin()                  
    --         oneCalc.initRootPos = Utilitys.ccpCopy(calcDatas.main.pos)
    --         self:_HandleCalcDatas(k, calcDatas, true)
    --     end
    --     oneCalc.boneEffect:setVisible(true)
    --     oneCalc.shadowEffect:setVisible(true)
    -- end

	if self.localAlive then
        for k,oneCalc in pairs(self.mCalcList) do            
            if oneCalc.isBegan then
                self:_HandleCalcDatas(k, oneCalc.oribitCalc:Execute(dt), false)
            else
                if oneCalc.timeStart <= self.frameTime then
                    oneCalc.isBegan = true
                    oneCalc.frameBegan = self.frameTime
                    if oneCalc.oribitCalc.mIsNewSuccess then            
                        local calcDatas = oneCalc.oribitCalc:Begin()                  
                        oneCalc.initRootPos = Utilitys.ccpCopy(calcDatas.main.pos)
                        self:_HandleCalcDatas(k, calcDatas, true)
                    end
                    oneCalc.boneEffect:setVisible(true)
                    oneCalc.shadowEffect:setVisible(true)                                 
                end
            end
        end
    end
end


function RAFS_Skill_MultiMissile:Exit()
    self.localAlive = false  
    self.frameTime = 0
    if self.mCalcList ~= nil then
        for k,oneCalc in pairs(self.mCalcList) do            
            self:_SelfReleaseOneCalc(k)
        end
    end
    self.mCalcList = nil
    self:release()
end

function RAFS_Skill_MultiMissile:_HandleCalcDatas(k, calcDatas, isInitHandle)
    local oneCalc = self.mCalcList[k]
    if oneCalc == nil or calcDatas == nil then 
        return 
    end    
    local boneEffect = oneCalc.boneEffect
    local shadowEffect = oneCalc.shadowEffect    

    local partType = calcDatas.main.partType
    local direction = calcDatas.main.direction
    local timePart1 = calcDatas.main.timePart1
    local timePart2 = calcDatas.main.timePart2
    if oneCalc.partType == 0 and partType == ParabolaPartType.PartOne then                        
        local frameCount = boneEffect:getFrameCount(ACTION_TYPE.ACTION_IDLE, direction)
        local newFps = frameCount / timePart1
        boneEffect:changeAction(ACTION_TYPE.ACTION_IDLE, direction, {newFps = newFps})       

        local shadowFrameCount = shadowEffect:getFrameCount(ACTION_TYPE.ACTION_IDLE, direction)
        newFps = shadowFrameCount / timePart1
        shadowEffect:changeAction(ACTION_TYPE.ACTION_IDLE, direction, {newFps = newFps})
    end
    if oneCalc.partType == ParabolaPartType.PartOne and partType == ParabolaPartType.PartTwo then        
        local frameCount = boneEffect:getFrameCount(ACTION_TYPE.ACTION_RUN, direction)
        local newFps = frameCount / timePart2
        boneEffect:changeAction(ACTION_TYPE.ACTION_RUN, direction, {newFps = newFps})       

        local shadowFrameCount = shadowEffect:getFrameCount(ACTION_TYPE.ACTION_RUN, direction)
        newFps = shadowFrameCount / timePart2
        shadowEffect:changeAction(ACTION_TYPE.ACTION_RUN, direction, {newFps = newFps})     
    end
    oneCalc.partType = partType
    boneEffect:setVisible(calcDatas.main.isVisible)

    isInitHandle = isInitHandle or false
    -- 第一次设置的时候需要设置rootNode位置，之后execute设置sprite node的相对位置
    if isInitHandle then
        boneEffect:setNodePosition('rootNode', calcDatas.main.pos.x, calcDatas.main.pos.y)        
    end
    local spriteGapPos = RACcpSub(calcDatas.main.pos, oneCalc.initRootPos)
    boneEffect:setNodePosition('spriteNode', spriteGapPos.x, spriteGapPos.y)
    boneEffect:setNodePosition('beforeNode', spriteGapPos.x, spriteGapPos.y)    

    -- 设置影子
    local shadowGapPos = RACcpSub(calcDatas.sub1.pos, oneCalc.initRootPos)
    shadowEffect:setNodePosition('rootNode', shadowGapPos.x, shadowGapPos.y)

    shadowEffect:setNodeRotation('rootNode', calcDatas.sub1.rotation)
    boneEffect:setNodeRotation('spriteNode', calcDatas.main.rotation)

    -- 提前隐藏炮弹炮体
    local oneCalcLastTime = oneCalc.timeSpend - (self.frameTime - oneCalc.frameBegan)    
    if oneCalcLastTime < CalcMissileDisapperBeforeTime then
        boneEffect:setNodeVisible('spriteNode', false)
        shadowEffect:setNodeVisible('rootNode', false)
        if not oneCalc.isEffectShowed then
            oneCalc.isEffectShowed = true
            -- 添加爆炸特效
            self:_AddEffect(oneCalc.targetSpacePos)
        end
    end
    
    if calcDatas.isEnd then
        self:_SelfReleaseOneCalc(k)
    end
end


function RAFS_Skill_MultiMissile:_SelfReleaseOneCalc(k)    
    local oneCalc = self.mCalcList[k]
    if oneCalc == nil then return end

    if oneCalc.oribitCalc then
        oneCalc.oribitCalc:release()
        oneCalc.oribitCalc = nil
    end
    if oneCalc.effectHanlder then
        local UIExtend = RARequire('UIExtend')
        UIExtend.unLoadCCBFile(oneCalc.effectHanlder)
        oneCalc.effectHanlder = nil
    end

    oneCalc.initRootPos = nil

    if oneCalc.shadowEffect then
        oneCalc.shadowEffect:release()
        oneCalc.shadowEffect = nil
    end

    if oneCalc.boneEffect then
        oneCalc.boneEffect:setVisible(false)
        oneCalc.boneEffect:release()
        oneCalc.boneEffect = nil

        if not oneCalc.isEffectShowed then
            oneCalc.isEffectShowed = true
            -- 添加爆炸特效
            self:_AddEffect(oneCalc.targetSpacePos)
        end        
    end 
    self.mCalcList[k] = nil
end

-- 添加爆炸特效
function RAFS_Skill_MultiMissile:_AddEffect(pos)
    -- 添加震屏        
    MessageManager.sendMessage(MessageDef_RootManager.MSG_SceneShake)
    local skillEffectCfg = RARequire('RAFU_Cfg_PlayerSkill')[self.skillId]
    assert(skillEffectCfg, 'skill id:'..self.skillId..' cfg is nil')
    local effectClass = skillEffectCfg.skillEndCfg.EffectFrameClass
    local effectCfgName = skillEffectCfg.skillEndCfg.EffectFrameCfgName
    local effectInstance = RARequire(effectClass).new(effectCfgName)            
    RA_SAFE_ENTER(effectInstance, {targetSpacePos = pos})
end

return RAFS_Skill_MultiMissile