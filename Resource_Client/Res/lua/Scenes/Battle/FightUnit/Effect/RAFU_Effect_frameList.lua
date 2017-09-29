--[[
description: 特效序列帧模式
author: zhenhui
date: 2016/12/7
]]--

local UIExtend = RARequire("UIExtend")
local RAFU_Effect_frameList = class('RAFU_Effect_frameList',RARequire("RAFU_Effect_base"))


function RAFU_Effect_frameList:ctor(effectCfgName)
  --为EFFECT 特效实例创建uid
  self.super.ctor(self,effectCfgName)

	self.effectCfgName = effectCfgName
    local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
	self.effectData = RAFU_Cfg_Effect[effectCfgName]
  local common = RARequire("common")
	if common:addSpriteFramesWithFile(self.effectData.plist,self.effectData.pic)==false then
      RALogError("RAFU_Effect_frameList:ctor -- file "..self.effectData.plist .."not found");   
  end
  self.frameSprite = nil
  self.backNode = nil
  self.frameTime = 0
  self.localAlive = false
  self.lifeTime = 0
end



function RAFU_Effect_frameList:Enter(data)
    --很关键：调用self.super.Enter(self,data),或者直接调用调用AddToBattleScene()  来发送消息加入场景中
    self.super.Enter(self,data)

    assert(data~= nil and data.targetSpacePos ~= nil, "false")
    local targetSpacePos =  data.targetSpacePos
    
    local frames = self.effectData.frameCount  
    local prefix = self.effectData.prefix
    local frameArray = CCArray:create();  
    local firstFrame = nil
    --创建序列帧动作
    for i=1,frames do
        local index = i
        if self.effectData.indexMode == 1 then
            index = string.format("%02d",i);
        end
        
        local file = prefix..index..".png"
        --CCMessageBox(file,"hint")
        local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(file);
        if pSpriteFrame ~= nil then
            frameArray:addObject(pSpriteFrame);
            if firstFrame==nil then 
                firstFrame = pSpriteFrame
            end
        else
            RALogError("RAFU_Effect_frameList:Enter(data) -- file "..file .."not found");    
        end
    end
    if frameArray:count()==0 then 
        return nil
    end

    self.isSelfExecute = true
    if data.isExecute ~= nil then
        self.isSelfExecute = data.isExecute
    end

    local fps = self.effectData.frameFps or 8
    local pAnimation = CCAnimation:createWithSpriteFrames(frameArray, 1/fps);
    if self.effectData.repeated then
        local animate = CCAnimate:create(pAnimation);     
        local pRepeatForever = CCRepeatForever:create(animate)
        self.action = pRepeatForever
    else
        local animate = CCAnimate:create(pAnimation);      
        self.action = animate   
    end

    local frameSprite = CCSprite:createWithSpriteFrame(firstFrame)

    --挂接到effectLayer节点，同时设置位置
    local RABattleScene = RARequire("RABattleScene")
    if data.parentNode then
        data.parentNode:addChild(frameSprite)
    else
        RABattleScene.mBattleEffectLayer:addChild(frameSprite)
    end
    local curPos = ccp(targetSpacePos.x,targetSpacePos.y);
    frameSprite:setPosition(curPos)

    local scale = self.effectData.scale or 1.0
    frameSprite:setScale(scale)

    curPos:delete()
    self.frameSprite = frameSprite
    frameSprite:runAction(self.action)
    self.data = data
    self.frameTime = 0
    self.lifeTime = data.lifeTime or self.effectData.lastTime

    -- backNode
    self.backNode = CCNode:create()
    self.frameSprite:addChild(self.backNode, -1)
    
     -- if self.effectData.repeated == false then
     --     local animateTime = 1/self.effectData.frameFps*self.effectData.frameCount
     --     if self.lifeTime > animateTime then 
     --         self.lifeTime = animateTime + 0.1
     --     end 
     -- end

    self.localAlive = true
end

function RAFU_Effect_frameList:Execute(dt)
    if self.localAlive then
      self.frameTime = self.frameTime + dt
      if self.frameTime > self.lifeTime and self.localAlive and self.isSelfExecute then
        self:Exit()
      end
    end
  	
end

--控制rootNode显影
function RAFU_Effect_frameList:setVisible(flag)
    if self.frameSprite ~= nil then
        self.frameSprite:setVisible(flag)
    end
end

--[[
    desc: 设置node位置
]]
function RAFU_Effect_frameList:setNodePosition(nodeName, x, y)
    local node = self[nodeName]
    if node ~= nil then
        node:setPosition(x, y)
    end
end

function RAFU_Effect_frameList:Exit()
   -- RALog("RAFU_Effect_frameList:Exit")
   if self.localAlive then
      self.localAlive = false
      RA_SAFE_REMOVEALLCHILDREN(self.backNode)

      if self.frameSprite ~= nil then
        RA_SAFE_REMOVEFROMPARENT(self.frameSprite)
     end
     --很关键：必须要调用，用来从场景中移除
     self:removeFromBattleScene()

      self.backNode = nil

   end
   
end

return RAFU_Effect_frameList;