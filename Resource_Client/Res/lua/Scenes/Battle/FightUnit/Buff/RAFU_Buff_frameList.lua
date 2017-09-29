

local UIExtend = RARequire("UIExtend")
local RAFU_Buff_frameList = class('RAFU_Buff_frameList',RARequire("RAFU_Object"))

--[[
  buffSystem: 战斗单元的buff 系统句柄
  contentNode: 实际的想要做效果的内容节点
  rootNode: 内容节点的父节点
  buffCfgName : 配置名称
]]
function RAFU_Buff_frameList:ctor(uuid,buffSystem,contentNode,rootNode,buffCfgName)
    self.contentNode = contentNode
    self.uuid = uuid
    self.buffSystem = buffSystem
    self.parentNode = rootNode
    local RAFU_Cfg_Buff = RARequire("RAFU_Cfg_Buff")
	  self.cfgData = RAFU_Cfg_Buff[buffCfgName]
end

function RAFU_Buff_frameList:release()
  	self:Exit()
  	
end


function RAFU_Buff_frameList:Enter(data)
    --RALog("RAFU_Buff_shaderNodeCCB:Enter")
    
    assert(data~= nil and data.targetSpacePos ~= nil, "false")
    local targetSpacePos =  data.targetSpacePos
    
    local frames = self.cfgData.frameCount  
    local prefix = self.cfgData.prefix
    local frameArray = CCArray:create();  
    local firstFrame = nil
    --创建序列帧动作
    for i=1,frames do
        local index = i
        if self.cfgData.indexMode == 1 then
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
            RALogError("RAFU_Buff_frameList:Enter(data) -- file "..file .."not found");    
        end
    end
    if frameArray:count()==0 then 
        return nil
    end

    local fps = self.cfgData.frameFps or 8
    local pAnimation = CCAnimation:createWithSpriteFrames(frameArray, 1/fps);
    
    local animate = CCAnimate:create(pAnimation);     
    local pRepeatForever = CCRepeatForever:create(animate)
    self.action = pRepeatForever


    local frameSprite = CCSprite:createWithSpriteFrame(firstFrame)

    --挂接到effectLayer节点，同时设置位置
    self.contentNode:addChild(frameSprite,100)
    local curPos = ccp(targetSpacePos.x,targetSpacePos.y);
    frameSprite:setPosition(curPos)

    local scale = self.cfgData.scale or 1.0
    frameSprite:setScale(scale)

    curPos:delete()
    self.frameSprite = frameSprite
    frameSprite:runAction(self.action)

    self.data = data
    self.frameTime = 0
    self.lifeTime = data.lifeTime or 1000000
    self.localAlive = true
end

function RAFU_Buff_frameList:Execute(dt)
  	self.frameTime = self.frameTime + dt
  	if self.frameTime > self.lifeTime and self.localAlive then
  	   self:Exit()
  	end
end

function RAFU_Buff_frameList:Exit()
   -- RALog("RAFU_Buff_shaderNodeCCB:Exit")
   if self.localAlive then
      self.localAlive = false
      if self.frameSprite ~= nil then
        RA_SAFE_REMOVEFROMPARENT(self.frameSprite)
      end
      self.buffSystem:RemoveBuff(self.uuid)
   end
end

return RAFU_Buff_frameList