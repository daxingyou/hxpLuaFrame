--region RAPlayerEffect.lua
--Date 2016/6/22
--Author zhenhui
--此文件由[BabeLua]插件自动生成

--改为服务器推送作用号的模式，不需要每个模块自己添加

FACTOR_EFFECT_DIVIDE = 10000
FACTOR_EFFECT_MULTIPLE = 0.0001

local RAPlayerEffect = {
    EffectTable = {}
}

function RAPlayerEffect:reset()
    self.EffectTable = {}
end


function RAPlayerEffect:syncOneEffect(oneEffect)    
    RAPlayerEffect.EffectTable[oneEffect.effId] = oneEffect

    -- 可以多次攻打怪物的作用号
    if oneEffect.effId == Const_pb.MULT_ATK_MONSTER then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAWorldMonsterNewPage'})
    end

    -- 资源加速道具的作用号
    if oneEffect.effId == Const_pb.RES_COLLECT_BUF or oneEffect.effId == Const_pb.RES_COLLECT then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAWorldMyCollectionPage'})
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAWorldCollectionBackPage'})
    end
end

--get the effect value right now.
function RAPlayerEffect:getEffectResult(effId)
    local oneEffect = RAPlayerEffect.EffectTable[effId] 
    if oneEffect~= nil then
         return oneEffect.effVal
    end
    return 0
end

--get the effect start time and end time if has, if do not has, return nil,nil
--ms
function RAPlayerEffect:getEffectTime(effId)
    local RABuffManager = RARequire("RABuffManager")

    if RABuffManager.buffList[effId] ~= nil then
        return  RABuffManager.buffList[effId].startTime,RABuffManager.buffList[effId].endTime
    end
    return nil,nil
end




--根据VIP初始化作用号
function RAPlayerEffect:addEffectVIP(effectType,effectValue)
    return;
--    assert(effectType > 0 and effectValue ~=nil,"effectType > 0 and effectValue ~=nil")
--    if self.EffectVIP[effectType] ~= nil then
--        self.EffectVIP[effectType] = self.EffectVIP[effectType] + effectValue
--    else
--        self.EffectVIP[effectType] = effectValue
--    end
end

--根据天赋初始化作用号
function RAPlayerEffect:addEffectTalent(effectType,effectValue)
    return
--    assert(effectType > 0 and effectValue ~=nil,"effectType > 0 and effectValue ~=nil")
--    if self.EffectTalent[effectType] ~= nil then
--        self.EffectTalent[effectType] = self.EffectTalent[effectType] + effectValue
--    else
--        self.EffectTalent[effectType] = effectValue
--    end
end

--根据科技初始化作用号
function RAPlayerEffect:addEffectTech(effectType,effectValue)
    return
--    assert(effectType > 0 and effectValue ~=nil,"effectType > 0 and effectValue ~=nil")
--    if self.EffectTech[effectType] ~= nil then
--        self.EffectTech[effectType] = self.EffectTech[effectType] + effectValue
--    else
--        self.EffectTech[effectType] = effectValue
--    end
end

--根据英雄初始化作用号
function RAPlayerEffect:addEffectHero(effectType,effectValue)
    return
--    assert(effectType > 0 and effectValue ~=nil,"effectType > 0 and effectValue ~=nil")
--    if self.EffectHero[effectType] ~= nil then
--        self.EffectHero[effectType] = self.EffectHero[effectType] + effectValue
--    else
--        self.EffectHero[effectType] = effectValue
--    end
end


return RAPlayerEffect 
--endregion
