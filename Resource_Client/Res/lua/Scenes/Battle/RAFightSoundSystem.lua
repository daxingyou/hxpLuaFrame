--[[
description: 
战斗声音（音效）系统
主要包括三个部分
1. 士兵的voice 语言音效，比如士兵移动的时候有"yes sir","roger that" and so on.	
2. 士兵的action 动作音效，比如坦克移动过程中的声音等
3. 特效的音效


后期再考虑加入 距离和摄像机因素 影响声音的大小 假3D 的效果 

author: zhenhui
date: 2016/12/28
]]--

local RAFightSoundSystem = class('RAFightSoundSystem',{})

local FU_effect_sound_conf = RARequire("fight_unit_effect_sound_conf")

local FU_unit_sound_conf = RARequire("fight_unit_sound_conf")

local soundlist_conf = RARequire("soundlist_conf")

local common = RARequire("common")
local RABattleScene = RARequire('RABattleScene')



RAFightSoundSystem.voiceSounds = {}--key is unitItemId_state, value is {time1,time2,time3}
RAFightSoundSystem.actionSounds = {}--key is unitItemId_state, value is {time1,time2,time3}
RAFightSoundSystem.effectSounds = {}--key is unitItemId_state, value is {time1,time2,time3}
RAFightSoundSystem.willPlaySounds = {} -- 下一帧要播放的音乐

RAFightSoundSystem.voiceLifeTime = 5  --second
RAFightSoundSystem.sameVoiceMaxNum = 3

RAFightSoundSystem.actionLifeTime = 6  --second
RAFightSoundSystem.sameActionMaxNum = 4

RAFightSoundSystem.effectLifeTime = 1 --second
RAFightSoundSystem.sameEffectMaxNum = 3

--战斗音乐的ID
RAFightSoundSystem.fightMusicId = 2
RAFightSoundSystem.prepareMusicId = 3
RAFightSoundSystem.fightMusicFlag = false

RAFightSoundSystem.fightVictoryId = 201
RAFightSoundSystem.fightFailureId = 202

RAFightSoundSystem.fightWinStarId = 203

function RAFightSoundSystem:playFightMusic()
    local soundCfg = soundlist_conf[RAFightSoundSystem.fightMusicId]
    local mp3Name = soundCfg.Resource
    if mp3Name ~= nil then
        SoundManager:getInstance():playMusic(mp3Name,true);
    end
end

function RAFightSoundSystem:playPrepareMusic()
    local soundCfg = soundlist_conf[RAFightSoundSystem.prepareMusicId]
    local mp3Name = soundCfg.Resource
    if mp3Name ~= nil then
        SoundManager:getInstance():playMusic(mp3Name,true);
    end
end

function RAFightSoundSystem:stopFightMusic()

end

function RAFightSoundSystem:playVictoryMusic()
    local soundCfg = soundlist_conf[RAFightSoundSystem.fightVictoryId]
    local mp3Name = soundCfg.Resource
    if mp3Name ~= nil then
        SoundManager:getInstance():playEffect(mp3Name);
    end
end

--战斗胜利页面出来后几颗星的音效
function RAFightSoundSystem:playFightWinStarMusic()
    local soundCfg = soundlist_conf[RAFightSoundSystem.fightWinStarId]
    if not soundCfg then return end
    local mp3Name = soundCfg.Resource
    if mp3Name ~= nil then
        SoundManager:getInstance():playEffect(mp3Name);
    end
end

function RAFightSoundSystem:playFailureMusic()
    local soundCfg = soundlist_conf[RAFightSoundSystem.fightFailureId]
    local mp3Name = soundCfg.Resource
    if mp3Name ~= nil then
        SoundManager:getInstance():playEffect(mp3Name);
    end
end

--根据soundId 播放mp3
function RAFightSoundSystem:playSoundById(soundId)
    --同一帧，如果soundId一样，只播放一个声音文件
	if self.willPlaySounds[soundId] == nil then
        local soundCfg = soundlist_conf[soundId]
        if soundCfg ~= nil then
            self.willPlaySounds[soundId] = soundCfg.Resource
        else
            RALogError("not found the music id is "..soundId)
        end
        
    end
end

function RAFightSoundSystem:_randomSoundMusic(soundCfg)
    local Utilitys = RARequire("Utilitys")
    local soundList = Utilitys.Split(soundCfg,',')
    local count = common:table_count(soundList)
    if count == 1 then
        return tonumber(soundCfg)
    else
        local index = math.random(1,count)
        return tonumber(soundList[index])
    end
    
end

--[[
播放士兵的voice 语言音效
1. unitItemId 是战斗单元的itemId
2. state 是数据层的状态类型
STATE_TYPE = {
    STATE_IDLE = 1,
    STATE_MOVE = 2,
    STATE_ATTACK = 3,
    STATE_DEATH = 4,
    STATE_CREATE = 5,--战斗单元创建子单元
    STATE_FLY = 6,--子单元的飞行
    STATE_DISAPPEAR = 7,--子弹攻击完之后的消失状态
}]]
function RAFightSoundSystem:playUnitVoiceSound(unitItemId,state)
    --以unitItemId为key，也就是每个兵种为KEY
    local key = unitItemId
    --如果voiceSounds 当前的音效大于 最大的限制
    if self.voiceSounds[key] ~= nil and common:table_count(self.voiceSounds[key]) >self.sameVoiceMaxNum then
        return
    end

    if FU_unit_sound_conf[unitItemId] == nil then
        --RALog("RAFightSoundSystem:playUnitVoiceSound error in unitItemId".. unitItemId)
        return
    end
    
    local soundCfg = FU_unit_sound_conf[unitItemId]
    local stateCfg = "Voice"..state
    local soundId = soundCfg[stateCfg]
    if soundId ~= nil then
        soundId = self:_randomSoundMusic(soundId)
        self:playSoundById(soundId)
        if self.voiceSounds[key] == nil then self.voiceSounds[key] = {} end
        table.insert(self.voiceSounds[key],self.voiceLifeTime)
        return
    else
       --RALog("RAFightSoundSystem:playUnitVoiceSound not found in voice state ".. state) 
       return 
    end 
end

--播放士兵的action 动作音效
function RAFightSoundSystem:playUnitActionSound(unitItemId,state)

    local key = unitItemId.."_"..state
    --如果voiceSounds 当前的音效大于 最大的限制
    if self.actionSounds[key] ~= nil and common:table_count(self.actionSounds[key]) >self.actionLifeTime then
        return
    end

    if FU_unit_sound_conf[unitItemId] == nil then
        --RALog("RAFightSoundSystem:playUnitActionSound error in unitItemId".. unitItemId)
        return
    end
    
    local soundCfg = FU_unit_sound_conf[unitItemId]
    local stateCfg = "action"..state
    local soundId = soundCfg[stateCfg]
    if soundId ~= nil then
        soundId = self:_randomSoundMusic(soundId)
        self:playSoundById(soundId)
        if self.actionSounds[key] == nil then self.actionSounds[key] = {} end
        table.insert(self.actionSounds[key],self.actionLifeTime)
        return
    else
       --RALog("RAFightSoundSystem:playUnitActionSound not found in voice state ".. state) 
       return 
    end 

end

--根据effectCfgName 播放对应的音乐
function RAFightSoundSystem:playEffectSound(effectCfgName)
    if FU_effect_sound_conf[effectCfgName] ~= nil then
        return self:playSoundById(FU_effect_sound_conf[effectCfgName].SoundId)
    end
    --RALogError("RAFightSoundSystem:playEffectSound error in effectCfgName".. effectCfgName)
end


function RAFightSoundSystem:Exit()
    self.voiceSounds = {}
    self.actionSounds = {}
    self.effectSounds = {}
    self.willPlaySounds = {}
    SoundManager:getInstance():stopAllEffect()
    -- SimpleAudioEngine:sharedEngine():end()
    RALog("..........RAFightSoundSystem:Exit().........")
end

--帧循环，同一帧播放的相同音乐都默认跳过处理
function RAFightSoundSystem:Execute(dt)
    -- 大于1的时候，不再播放音效
    if RABattleScene:getSpeedScale() > 1 then
        return
    end
    --每一帧循环只播放同一种特定音效
	if self.willPlaySounds ~= nil then
        for k,mp3Name in pairs(self.willPlaySounds) do
            SoundManager:getInstance():playEffect(mp3Name);
        end
        self.willPlaySounds = {}
    end

    for key,lifeTimeTable in pairs(self.voiceSounds) do
        for k,lifeTime in pairs(lifeTimeTable) do
            lifeTime = lifeTime - dt
            if lifeTime <=0 then
                self.voiceSounds[key][k] = nil
            else
                self.voiceSounds[key][k] = lifeTime
            end
        end
        
    end

    for key,lifeTimeTable in pairs(self.actionSounds) do
        for k,lifeTime in pairs(lifeTimeTable) do
            lifeTime = lifeTime - dt
            if lifeTime <=0 then
                self.actionSounds[key][k] = nil
            else
                self.actionSounds[key][k] = lifeTime
            end
        end
        
    end

end

return RAFightSoundSystem