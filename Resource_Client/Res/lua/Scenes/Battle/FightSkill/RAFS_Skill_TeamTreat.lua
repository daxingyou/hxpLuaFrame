--[[
description: 
详细的战斗单位加血技能处理

author: xingui
date: 2017/1/11
]]--

local RAFS_Skill_TeamTreat  = class('RAFS_Skill_TeamTreat',RARequire("RAFS_Skill_Base"))
local ParabolaPartType      = RARequire('RAFU_Cfg_OribitCalc_TeamTreat').ParabolaPartType

--医疗包轨迹配置    
local EffectFlyConf = {
    CFG_FILE = "RAFU_Cfg_OribitCalc_TeamTreat",
    ORIBIT_CAL_FILE = "RAFU_OribitCalc_CommonParabola"
}
--[[
    desc: 治疗技能初始
    param: data RASkillCastActionData类型的数据
]]
function RAFS_Skill_TeamTreat:Enter(data)
    self.super.Enter(self,data)

    local battle_player_skill_conf = RARequire("battle_player_skill_conf")
    local skillConfInfo = battle_player_skill_conf[data.skillId]
    self.skillId = data.skillId
    self.skillConfInfo = skillConfInfo

    local RAFU_Cfg_PlayerSkill = RARequire("RAFU_Cfg_PlayerSkill")
    local rafuSkillConf = RAFU_Cfg_PlayerSkill[self.skillId]
    self.rafuSkillConf = rafuSkillConf
    
    --获得地面特效的位置
    self.targetSpacePos = RACcp(0, 0)
    if data.targetPos then
        local RABattleSceneManager = RARequire("RABattleSceneManager")
        self.targetSpacePos = RABattleSceneManager:tileToSpace(data.targetPos)
    end
    self.groudEffectTime = tonumber(skillConfInfo.effectElapse) * tonumber(skillConfInfo.effectTimes)
    self.frameTime = 0
    self.moveEndTime = skillConfInfo.waitPeriod or 2.0
    self.mPartType = 0
    self.isInGroudEffect = false
    self.treatTimes = 0

    --技能创建，进入飞行
    self:EnterFly(data)
end

--[[
    desc: 治疗技能帧调用
]]
function RAFS_Skill_TeamTreat:Execute(dt)
    if self.moveEndTime == nil then return end
    self.frameTime = self.frameTime + dt

	if self.localAlive and self.mOribitCalc then
        self:_HandleCalcDatas(self.mOribitCalc:Execute(dt))
    end


    if self.frameTime >= self.moveEndTime and not self.isInGroudEffect then
        self:_EnterGroundEffect()   --飞行晚后加入地面特效
    end
end

--[[
    desc: 重写父类函数，飞行的处理
]]
function RAFS_Skill_TeamTreat:EnterFly(data)
    
    -- create effect
    self.boneEffect = RARequire(self.rafuSkillConf.main.EffectFrameClass).new(self.rafuSkillConf.main.EffectFrameCfgName)
    self.boneEffect:setVisible(false)

    -- create shadow
    -- 把影子放在v3节点上，防止层级出错
    self.shadowEffect = RARequire(self.rafuSkillConf.sub1.EffectFrameClass).new(self.rafuSkillConf.sub1.EffectFrameCfgName)
    self.shadowEffect:setVisible(false)

     -- create calc
    local param = self:_prepareInputParam(data)--构造轨迹需要的数据   
    local boneEffectData = {
        targetSpacePos = param.position.main.startPos,
        lifeTime = self.moveEndTime,
        -- 自己不做删除
        isExecute = false
    }
    self.boneEffect:Enter(boneEffectData)

    self.shadowEffect:Enter(
    {
        --pararentNode = self.boneEffect.backNode,
        targetSpacePos = param.position.main.startPos,
        lifeTime = self.moveEndTime,
        -- 自己不做删除
        isExecute = false
    })
     
    local oribitCalc = RARequire(EffectFlyConf.ORIBIT_CAL_FILE).new(param)
    if oribitCalc.mIsNewSuccess then
        self.mOribitCalc = oribitCalc       
        local calcDatas = self.mOribitCalc:Begin()  
        
        local Utilitys = RARequire('Utilitys')
        self.mInitRootPos = Utilitys.ccpCopy(calcDatas.main.pos)
        self:_HandleCalcDatas(calcDatas, true)
    end
    self.boneEffect:setVisible(true)
    self.shadowEffect:setVisible(true)
end

--[[
    desc: 重写父类的函数，飞行结束后进入技能的实际效果，由RAFightSkillSystem:handleSkillEffectAction直接调用
]]
function RAFS_Skill_TeamTreat:EnterEffect(effectActionData)
    self:_HitUnit(effectActionData)

    --治疗次数达到上限之后，删除自己
    self.treatTimes = self.treatTimes + 1
    if self.treatTimes >= self.skillConfInfo.effectTimes then
        self:Exit()
    end
end

--[[
    desc: 显示地面治疗包特效
]]
function RAFS_Skill_TeamTreat:_EnterGroundEffect()
    self.isInGroudEffect = true

    self.effectInstance = RARequire(self.rafuSkillConf.skillEndCfg.EffectFrameClass).new(self.rafuSkillConf.skillEndCfg.EffectFrameCfgName)
    local RABattleScene = RARequire("RABattleScene")
    local data = {
        parentNode = RABattleScene.mSurfaceLayer,
        lifeTime = self.groudEffectTime,
        targetSpacePos = self.targetSpacePos
    }
    self.effectInstance:Enter(data)
end

--[[
    desc: 处理技能效果
]]
function RAFS_Skill_TeamTreat:_HitUnit(data)
    self.super._HitUnit(self, data)
    
    --todo:治疗包特有的效果
end

--[[
    desc: 退出
]]
function RAFS_Skill_TeamTreat:Exit()
    self.frameTime = 0
    self.treatTimes = 0
    self.isInGroudEffect = false

    self.super.Exit(self)
end



--[[
    desc: 根据输入数据获得计算数据
]]
function RAFS_Skill_TeamTreat:_prepareInputParam(data)
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local curTilePos = RARequire("RAFightSkillSystem"):getSkillFirePos()
    local moveTilePos = data.targetPos

    local curSpacePos = RABattleSceneManager:tileToSpace(curTilePos)
    local endPos = RABattleSceneManager:tileToSpace(moveTilePos)


    local param = {}
    -- 配置参数使用单个炮弹的配置
    param.cfg = {}
    param.cfg.dirCfg = RARequire(EffectFlyConf.CFG_FILE).ParabolaDirCfg
    param.cfg.partCfg = ParabolaPartType

    -- 影子计算并返回
    param.isCalcShadow = true


    param.position = {}
    param.position.main = {}
    param.position.main.startPos = curSpacePos
    param.position.main.endPos = endPos    
    --param.speed = 400
    local Utilitys = RARequire('Utilitys')
    param.pixelDistance = Utilitys.getDistance(curSpacePos, endPos)
    -- 时间减个固定值，保证先飞到才爆炸，暂时不需要，通过配置有个0.1的时间了
    param.spendTime = (data.waitTime or 3.0) - 0
    param.speed = param.pixelDistance/param.spendTime

    
    return param
end


--[[
    desc: 根据计算的轨迹数据，设置特效轨迹
]]
function RAFS_Skill_TeamTreat:_HandleCalcDatas(calcDatas, isInitHandle)
    if calcDatas == nil or self.boneEffect == nil then 
        return
    end        
    local partType = calcDatas.main.partType
    local direction = calcDatas.main.direction
    local timePart1 = calcDatas.main.timePart1
    local timePart2 = calcDatas.main.timePart2

    self.mPartType = partType

    self.boneEffect:setVisible(calcDatas.main.isVisible)
    self.shadowEffect:setVisible(calcDatas.main.isVisible)

    isInitHandle = isInitHandle or false
    -- 第一次设置的时候需要设置rootNode位置，之后execute设置sprite node的相对位置
    if isInitHandle then
        self.boneEffect:setNodePosition('frameSprite', calcDatas.main.pos.x, calcDatas.main.pos.y)        
    end
    local spriteGapPos = RACcpSub(calcDatas.main.pos, self.mInitRootPos)
    self.boneEffect:setNodePosition('frameSprite', calcDatas.main.pos.x, calcDatas.main.pos.y)
   
    -- 设置影子
    self.shadowEffect:setNodePosition('frameSprite', calcDatas.sub1.pos.x, calcDatas.sub1.pos.y)  


    if calcDatas.isEnd then

        if self.mOribitCalc then
            self.mOribitCalc:release()
            self.mOribitCalc = nil
        end
        
        if self.shadowEffect then
            self.shadowEffect:setVisible(false)
            self.shadowEffect:release()
            self.shadowEffect = nil
        end

        self.mInitCalcData = nil

        if self.boneEffect then
            self.boneEffect:setVisible(false)
            self.boneEffect:release()
            self.boneEffect = nil
        end
    end
end


return RAFS_Skill_TeamTreat