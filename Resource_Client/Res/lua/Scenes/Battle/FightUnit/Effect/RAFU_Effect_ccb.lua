--[[
description: 特效模型实体
--单个CCB相关，如爆炸
author: zhenhui
date: 2016/11/22
]]--

local UIExtend = RARequire("UIExtend")
local RAFU_Effect_ccb = class('RAFU_Effect_ccb',RARequire("RAFU_Effect_base"))


function RAFU_Effect_ccb:ctor(effectCfgName)
  --为EFFECT 特效实例创建uid
  self.super.ctor(self,effectCfgName)

	self.effectCfgName = effectCfgName
    local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
	self.effectData = RAFU_Cfg_Effect[effectCfgName]
	self.ccbiName = self.effectData.ccbiName
end


function RAFU_Effect_ccb:Enter(data)
    --很关键：调用self.super.Enter(self,data),或者直接调用调用AddToBattleScene()  来发送消息加入场景中
    self.super.Enter(self,data)

    --RALog("RAFU_Effect_ccb:Enter")
    assert(data~= nil and data.targetSpacePos ~= nil, "false")
    local targetSpacePos = data.targetSpacePos
    local common = RARequire("common")
    if self.effectData.plist and self.effectData.pic and common:addSpriteFramesWithFile(self.effectData.plist,self.effectData.pic)==false then
      RALogError("RAFU_Effect_frameList:ctor -- file "..self.effectData.plist .."not found");   
    end
    local ccbifile = UIExtend.loadCCBFile(self.ccbiName,self)
    local RABattleScene = RARequire("RABattleScene")
    RABattleScene.mBattleEffectLayer:addChild(ccbifile)
    local curPos = ccp(targetSpacePos.x,targetSpacePos.y);
    ccbifile:setPosition(curPos)
    curPos:delete()
    self.ccbifile = ccbifile
    local scale = self.effectData.scale or 1.0
    self.ccbifile:setScale(scale)

    local timelineName = self.effectData.timeLine
    self.ccbifile:runAnimation(timelineName)

    
    self.data = data
    self.frameTime = 0
    self.lifeTime = data.lifeTime or 0.3
    self.autoExit = self.effectData.autoExit or data.autoExit
    self.localAlive = true
end

function RAFU_Effect_ccb:OnAnimationDone(ccbfile)
    --body
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if self.autoExit and lastAnimationName == self.effectData.timeLine then
        -- print("self:Exit()")
        self:Exit()
    end
end

function RAFU_Effect_ccb:Execute(dt)
  	self.frameTime = self.frameTime + dt
  	if not self.autoExit and self.frameTime > self.lifeTime and self.localAlive then
  		self:Exit()
  	end
end

function RAFU_Effect_ccb:Exit()
   -- RALog("RAFU_Effect_ccb:Exit")
   if self.localAlive then
      self.localAlive = false
      UIExtend.unLoadCCBFile(self)
      --很关键：必须要调用，用来从场景中移除
      self:removeFromBattleScene()
   end
   
end

return RAFU_Effect_ccb;