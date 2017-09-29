--[[
description: 
战斗主角技能系统，不是战斗单元的技能系统

主要包括两部分
1. 数据部分
2. 效果部分存放在RABattleSceneManager.skillList 里面


// 战场技能id
enum BattleSkillId
{
    ONE_MISSILE = 100001; // 单导弹攻击
    MULTI_MISSILE = 100002; // 多导弹攻击
    TEAM_TREAT = 100003; // 队伍治疗
}

author: zhenhui
date: 2017/1/11
]]--

local RAFightSkillSystem = class('RAFightSkillSystem',{})

--技能数据map
RAFightSkillSystem.skillDataMap = {}
RAFightSkillSystem.skillUidIndex = 1

RAFightSkillSystem.skillFirePos = RACcp(65,101)

------------数据层  开始----------------------

--设置每张地图不同的开火位置，跟随地图表配置
function RAFightSkillSystem:setSkillFirePos(firePos)
    assert(firePos ~= nil ,"false")
    self.skillFirePos = RACcp(firePos.x,firePos.y)
end

function RAFightSkillSystem:getSkillDataNum()
    return #self.skillDataMap
end


function RAFightSkillSystem:getSkillFirePos()
    return self.skillFirePos
end


--[[传入技能ID，技能的目标位置，skillId参考第6行的enum或者RAFightDefine BattleSkillId,targetPos为tilePos
// 施放技能
message CastSkill
{
    required int32 skillId = 1;
    optional int32 castTime = 2;
    optional UnitPos firePos = 3;
    optional UnitPos targetPos = 4;
    optional int32 skillUid = 5;
}
]]
function RAFightSkillSystem:addOneSkillData(skillId,targetPos)
    if RARequire("RAFightManager").isReplay == true then
        assert(false,"only not replay mode can add skill data")
        return 
    end
    assert(skillId ~= nil and targetPos ~= nil,"false")
    local oneSkill = {}
    oneSkill.skillId = skillId
    oneSkill.targetPos = targetPos
    oneSkill.skillUid = self.skillUidIndex
    oneSkill.firePos = self.skillFirePos
    --每次主动释放技能的时候都把uid默认加1，注意replay和结束之后需要清空 
    self.skillUidIndex = self.skillUidIndex + 1
    
    table.insert(self.skillDataMap,oneSkill)
end

--将所有的技能数据推送给计算模块，在RAFightManager每一个tick判断有没有skillDataMap
function RAFightSkillSystem:prepareSkillDataPB(castSkills)
    if #self.skillDataMap > 0 then
        --构建pb数据
        for k,oneData in pairs(self.skillDataMap) do
            if oneData ~= nil then
                local oneSkillPb = castSkills:add()
                oneSkillPb.skillId = oneData.skillId
                oneSkillPb.targetPos.x = oneData.targetPos.x
                oneSkillPb.targetPos.y = oneData.targetPos.y
                oneSkillPb.firePos.x = oneData.firePos.x
                oneSkillPb.firePos.y = oneData.firePos.y
                oneSkillPb.skillUid = oneData.skillUid
            end
        end
        --清空skillDataMap
        self.skillDataMap = {}
    end
end

function RAFightSkillSystem:reset()
    RAFightSkillSystem.skillUidIndex = 1
    RAFightSkillSystem.skillDataMap = {}
    RAFightSkillSystem.skillFirePos = RACcp(65,101)
end


------------数据层  结束----------------------

------------表现层  开始----------------------

--castActionData 为RASkillCastActionData
--处理技能释放的逻辑，也就是技能飞行状态逻辑
function RAFightSkillSystem:handleSkillCastAction(castActionData)
    RALogInfo("RAFightSkillSystem:handleSkillCastAction come in cast action data")
    local skillInstance = nil
    
    local uid = castActionData.skillUid
    if castActionData.skillId == BattleSkillId.ONE_MISSILE then
        --need rewrite
        skillInstance = RARequire("RAFS_Skill_OneMissile").new(uid)
    elseif castActionData.skillId == BattleSkillId.MULTI_MISSILE then
        --need rewrite
        skillInstance = RARequire("RAFS_Skill_MultiMissile").new(uid)
    elseif castActionData.skillId == BattleSkillId.TEAM_TREAT then
        --need rewrite
        skillInstance = RARequire("RAFS_Skill_TeamTreat").new(uid)
    end

    assert(skillInstance ~= nil ,"false")
    if skillInstance ~= nil then
        --开始生命周期
        skillInstance:Enter(castActionData)
    end

end



--effectActionData 为RASkillEffectActionData
--处理技能到达之后效果的逻辑，也就是技能效果状态逻辑
function RAFightSkillSystem:handleSkillEffectAction(effectActionData)
    assert(effectActionData ~= nil ,"false")
    local uid = effectActionData.skillUid
    --技能表现的实体存放在RABattleSceneManager里面
    local skillInstance = RARequire("RABattleSceneManager").skillList[uid]
    assert(skillInstance ~= nil ,"false")
    --将伤害数据传入effect模块 
    skillInstance:EnterEffect(effectActionData)

end

------------表现层  结束----------------------

return RAFightSkillSystem