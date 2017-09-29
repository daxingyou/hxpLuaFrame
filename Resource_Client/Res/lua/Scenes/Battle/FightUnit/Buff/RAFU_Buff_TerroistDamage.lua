--[[
description: 
buff，shader node 的ccb模式
原理：
将原有的contentNode从原来的rootNode剥离出来，中间插入然后挂接到 ccb下面的mEffectNode 下，

用树状图表示如下：
原来的结构：
--rootNode
----contentNode(实际的想要做效果的内容节点)

转换为如下的结构:
--rootNode
----ani_ccb
--------mEffectNode(潜规则)
-----------contentNode

author: bls
date: 2017/2/15
]]--

local UIExtend = RARequire("UIExtend")
local RAFU_Buff_TerroistDamage = class('RAFU_Buff_TerroistDamage',RARequire("RAFU_Object"))

--[[
  buffSystem: 战斗单元的buff 系统句柄
  contentNode: 实际的想要做效果的内容节点
  rootNode: 内容节点的父节点
  buffCfgName : 配置名称
]]
function RAFU_Buff_TerroistDamage:ctor(uuid,buffSystem,contentNode,rootNode,buffCfgName)
    self.contentNode = contentNode
    self.uuid = uuid
    self.buffSystem = buffSystem
    self.parentNode = rootNode
    local RAFU_Cfg_Buff = RARequire("RAFU_Cfg_Buff")
	self.cfgData = RAFU_Cfg_Buff[buffCfgName]
	self.ccbiName = self.cfgData.ccbiName
    self.frameTime = 0
    self.shakeTime = 0
end

function RAFU_Buff_TerroistDamage:release()
  	self:Exit()
  	
end

function RAFU_Buff_TerroistDamage:_switchNode(childNode,toNode)
	assert(childNode ~= nil and toNode ~= nil,"false")
	childNode:retain()
    childNode:removeFromParentAndCleanup(false)
    toNode:addChild(childNode)
    childNode:release()
end

function RAFU_Buff_TerroistDamage:Enter(data)
    RALog("RAFU_Buff_shaderNodeCCB:Enter")

    local ccbifile = UIExtend.loadCCBFileWithOutPool(self.ccbiName,self)
    --add ccbifile
    self.parentNode:addChild(ccbifile)

    self.mEffectNode = ccbifile:getCCNodeFromCCB("mEffectNode")
    --remove from parent and add to mEffectNode
    self:_switchNode(self.contentNode,self.mEffectNode)

    local scale = self.cfgData.scale or 1.0
    ccbifile:setScale(scale)

    local timelineName = self.cfgData.timeLine
    ccbifile:runAnimation(timelineName)

    self.data = data
    self.frameTime = 0
    self.lifeTime = data.lifeTime or 0.3
    self.localAlive = true
end

function RAFU_Buff_TerroistDamage:Execute(dt)
  	self.frameTime = self.frameTime + dt
    self.shakeTime = self.shakeTime + dt
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local curSpacePos  =  RABattleSceneManager:getCenterPosByUnitId(self.buffSystem.fightUnit.id)
    local direction =  RARequire("EnumManager"):calcDir(curSpacePos,curSpacePos)
    if  self.shakeTime > 1 then  --播放坦克摇摆
        local radom = math.random(100)
        local actiontype =  ACTION_TYPE.ACTION_ROCK_LEFT
        if radom > 50 then
           actiontype = ACTION_TYPE.ACTION_ROCK_RIGHT
        end
        for boneName,boneController in pairs(self.buffSystem.fightUnit.boneManager) do
           if boneController.boneData.isTop == false then   
                boneController:changeAction(actiontype,direction)
           end
        self.shakeTime = 0
        end
    end
    if self.buffSystem.fightUnit.data.hp <= 0 then
         self.buffSystem.fightUnit:changeState(STATE_TYPE.STATE_DEATH)
         self:Exit()
    end
  	if self.lifeTime > 0 and self.frameTime > self.lifeTime and self.localAlive then
  		self:Exit()
  	end

end

function RAFU_Buff_TerroistDamage:Exit()
   -- RALog("RAFU_Buff_shaderNodeCCB:Exit")
   if self.localAlive then
      self.localAlive = false
      self:_switchNode(self.contentNode,self.parentNode)
      UIExtend.unLoadCCBFile(self)
      self.buffSystem:RemoveBuff(self.uuid)
   end
   
end

return RAFU_Buff_TerroistDamage;