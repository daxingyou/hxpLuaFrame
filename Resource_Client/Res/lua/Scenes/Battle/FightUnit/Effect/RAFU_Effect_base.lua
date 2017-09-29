--[[
description: 特效实体基类
纯虚函数
author: zhenhui
date: 2016/11/22
]]--

local RAFU_Effect_base = class('RAFU_Effect_base',RARequire("RAFU_Object"))


function RAFU_Effect_base:ctor(effectCfgName)  
    local uuid = RARequire("uuid")
    local uid = uuid.new()
    --为EFFECT 特效实例创建uid
    self.uid = uid
    self.effectCfgName = effectCfgName
    self.localAlive = false

end

function RAFU_Effect_base:release()
    self:Exit()
end


function RAFU_Effect_base:Enter(data)
    --RALog("RAFU_Effect_base:Enter")
    assert(data~= nil and data.targetSpacePos ~= nil, "false")
    self.localAlive = true
    self:AddToBattleScene()
end

--发消息给控制器，提示加入场景管理器        
function RAFU_Effect_base:AddToBattleScene()

    --1. 添加到场景
    local this = self
    local message = {}
    message.effectInstance = this
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_EFFECT, message)

    --2. 播放音乐特效
    RARequire("RAFightSoundSystem"):playEffectSound(self.effectCfgName)

end

--发消息给控制器，提示移除场景管理器 
function RAFU_Effect_base:removeFromBattleScene()
    local message = {}
    message.uid = self.uid
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_DELETE_EFFECT, message)
end

function RAFU_Effect_base:Execute(dt)
  	RALogInfo("plz rewrite")
end

function RAFU_Effect_base:Exit()
   -- RALog("RAFU_Effect_base:Exit")
   if self.localAlive then
      self.localAlive = false
      self:removeFromBattleScene()
   end
   
end

return RAFU_Effect_base;