--[[
description:
bone类型的effect，配置取自bone cfg
author: qinho
date: 2017/01/11
]]--

local UIExtend = RARequire("UIExtend")
local EnumManager = RARequire("EnumManager")
local RAFU_Effect_bone = class('RAFU_Effect_bone',RARequire("RAFU_Effect_base"))


function RAFU_Effect_bone:ctor(effectCfgName)
    --为EFFECT 特效实例创建uid
    self.super.ctor(self,effectCfgName)   
    self.effectCfgName = effectCfgName
    local RAFU_Cfg_Effect= RARequire("RAFU_Cfg_Effect")
    local boneData = RAFU_Cfg_Effect[effectCfgName]
    if boneData.CanSwitch == nil then boneData.CanSwitch = false end
    self.boneData = boneData    
    self.CanSwitch = boneData.CanSwitch
    self.frameConfigName = boneData.BoneFrameCfgName
    self.frameConfig = RARequire("RAFU_Cfg_Bone")[boneData.BoneFrameCfgName]
    assert(self.frameConfig ~= nil ,"self.frameConfig ~= nil")
    self.AllActionData = RARequire('RAFU_FrameData'):new(self.frameConfigName)

    self.frameTime = 0
    self.localAlive = false

    self.rootNode = nil
    self.beforeNode = nil
    self.spriteNode = nil
    self.backNode = nil
    self.sprite = nil
    self:_initBoneEffectNode()
end


--初始化sprite
function RAFU_Effect_bone:_initBoneEffectNode()
    -- node
    self.rootNode = CCNode:create()
    self.rootNode:retain()

    -- beforeNode
    self.beforeNode = CCNode:create()
    self.rootNode:addChild(self.beforeNode, 1)

    -- spriteNode
    self.spriteNode = CCNode:create()
    self.rootNode:addChild(self.spriteNode, 0)
    
    -- backNode
    self.backNode = CCNode:create()
    self.rootNode:addChild(self.backNode, -1)
    

    -- sprite
    self.sprite = CCSprite:create("empty.png")
    local zorder = self.boneData.Zorder    
    local scale = self.boneData.scale or 1.0
    self.sprite:setAnchorPoint(0.5,0.5)
    self.sprite:setScale(scale)
    self.sprite:setOpacity(255)
    local x = 0
    local y = 0

    if self.boneData.imageOffsetY ~= nil then 
        y = y + self.boneData.imageOffsetY
    end

    if self.boneData.imageOffsetX ~= nil then 
        x = x + self.boneData.imageOffsetX
    end
    self.sprite:setPosition(ccp(x,y))   
    -- 初始值一定不能为已经存在的状态和方向
    self.currentAction = -1
    self.currentDirection = -1
    self.spriteNode:addChild(self.sprite,zorder)
    -- 默认不切换动作
    -- self:changeAction(self.currentAction, self.currentDirection) 
end

--colorParam is defined in RAFightDefine
function RAFU_Effect_bone:changeMaskColor(colorParam)
    local colorKey = colorParam.key 
    local r = colorParam.color.r or 255
    local g = colorParam.color.g or 255
    local b = colorParam.color.b or 255
    CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    if self.sprite ~= nil then
        self.sprite:setMaskColor(CCTextureCache:sharedTextureCache():getColorByName(colorKey))
    end
end



--发消息给控制器，提示加入场景管理器        
function RAFU_Effect_bone:AddToBattleScene()

    --1. 添加到场景
    local this = self
    local message = {}
    message.effectInstance = this
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_EFFECT, message)

    --2. 播放音乐特效
    -- RARequire("RAFightSoundSystem"):playEffectSound(self.effectCfgName)
end



--控制rootNode显影
function RAFU_Effect_bone:setVisible(flag)
    if self.rootNode ~= nil then
        self.rootNode:setVisible(flag)
    end
end


function RAFU_Effect_bone:setNodePosition(nodeName, x, y)
    local node = self[nodeName]
    if node ~= nil then
        node:setPosition(x, y)
    end
end

function RAFU_Effect_bone:setNodeVisible(nodeName, value)
    local node = self[nodeName]
    if node ~= nil then
        node:setVisible(value)
    end
end


function RAFU_Effect_bone:setNodeRotation(nodeName, rotation)
    local node = self[nodeName]
    if node ~= nil then
        node:setRotation(rotation)
    end
end



--[[改变方向和动作
--actionType and direction
param默认值
local param = {
    callback = nil,--回调
    needSwitch = true,--是否强制转向  
    isforce = false,--是否强制改变动作
    newFps = nil,--新的播放fps
    startFrame = nil--新的开始帧
}
]]
function RAFU_Effect_bone:changeAction(actionType, direction, paramData)
    if self.AllActionData == nil then assert(false,"false") end
    local param = paramData
    if param == nil then 
        param = {
            callback = nil,--回调
            needSwitch = true,--是否强制转向
            isforce = false,--是否强制改变动作
            newFps = nil,--新的播放fps
            startFrame = nil--新的开始帧
        }
    end
    if param.isforce == nil then param.isforce = false end
    if param.needSwitch == nil then param.needSwitch = true end

    if not param.isforce and self.currentAction == actionType and self.currentDirection == direction then
        return
    end

    if direction == EnumManager.FU_DIRECTION_ENUM.DIR_NONE then
        return
    end
    

    if self.frameConfig.actionDefine[actionType] == nil then
        RALog("RAFU_Effect_bone:changeAction -- do not has the actionType "..actionType)
        return
    end


    self:updateAction(actionType, direction, param)
end

function RAFU_Effect_bone:getOffsetY( )
    self.boneData.offsetY = self.boneData.offsetY or 0
    return self.boneData.offsetY
end


function RAFU_Effect_bone:getFrameCount(actionType, direction)
    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction)
    local frameCount = 0
    if oneAction and oneAction.frameArray:count() then frameCount = oneAction.frameArray:count() end
    return frameCount
end


function RAFU_Effect_bone:getFrameTime(actionType, direction)
    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction)
    local frameTime = 0
    if oneAction and oneAction.frameTime then frameTime = oneAction.frameTime end
    return frameTime
end

--更新方向和动作的具体的实现
function RAFU_Effect_bone:updateAction(actionType, direction, param)
    if self.AllActionData == nil or self.sprite == nil then
        return 
    end
    local actionId = actionType .. "_" .. direction
    if param == nil then param = {} end
    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction,param.newFps,param.startFrame)
    local frameInfo = self.AllActionData:getFrameInfo()
    if oneAction then
        self.sprite:stopAllActions();
        self.sprite:removeAllChildren()
        
        -- 调整锚点
        local size = self.sprite:getContentSize();
        self.sprite:setAnchorPoint(ccp(0.5, 0.5));
        
        -- flip
        if frameInfo.needDirFlip then
            self.sprite:setFlipX(DirectionFlip_DIR16[direction] ~= direction)
        end
        
        local switchDirAction = nil
        if self.CanSwitch and param.needSwitch then
            switchDirAction = self:switchDirection(self.currentDirection,direction, param.isCircle)
        else
            -- 如果不转向，则直接设置第一帧
            self.sprite:setDisplayFrame(oneAction.firstFrame)
        end      
        

        local actionHander = oneAction.action
        if actionHander ~= nil then
            if param.callback ~= nil then
                local array = CCArray:create()
                if switchDirAction ~= nil then array:addObject(switchDirAction) end
                array:addObject(actionHander)
                local funcAction = CCCallFunc:create(param.callback)
                array:addObject(funcAction)
                local seq = CCSequence:create(array);
                self.sprite:runAction(seq);
            else
                if switchDirAction ~= nil then
                    local array = CCArray:create()
                    array:addObject(switchDirAction)
                    array:addObject(actionHander)
                    local seq = CCSequence:create(array);
                    self.sprite:runAction(seq);
                else
                    self.sprite:runAction(actionHander);
                end 
            end
        end
    end

    self.currentDirection = direction
    self.currentAction = actionType
end


-- data = {
--     targetSpacePos = {x, y},
--     lifeTime = xxx
-- }
function RAFU_Effect_bone:Enter(data)    
    if data == nil then return end
    self.data = data
    self.isSelfExecute = true
    if data.isExecute ~= nil then
        self.isSelfExecute = data.isExecute
    end
    self.localAlive = true
    self:AddToBattleScene()

    self.targetSpacePos = data.targetSpacePos

    if data.pararentNode ~= nil then 
        -- 有传父节点进来，就直接加到父节点上
        data.pararentNode:addChild(self.rootNode)
    else
        --挂接到effectLayer节点，同时设置位置
        local RABattleScene = RARequire("RABattleScene")
        RABattleScene.mBattleEffectLayer:addChild(self.rootNode)
    end
    -- 有位置就设置
    if self.targetSpacePos ~= nil then
        self.rootNode:setPosition(self.targetSpacePos.x, self.targetSpacePos.y)    
    end

    self.frameTime = 0
    self.lifeTime = data.lifeTime or 0
    self.localAlive = true
end

function RAFU_Effect_bone:Execute(dt)
    if self.localAlive and self.isSelfExecute then
        self.frameTime = self.frameTime + dt
        if self.frameTime > self.lifeTime and self.localAlive then
            self:Exit()
        end
    end    
end

function RAFU_Effect_bone:Exit()
    -- RALog("RAFU_Effect_bone:Exit")
    if self.localAlive then
        self.localAlive = false
        self.frameTime = 0
        if self.sprite ~= nil then
            RA_SAFE_REMOVEFROMPARENT(self.sprite)
        end

        RA_SAFE_REMOVEALLCHILDREN(self.beforeNode)
        RA_SAFE_REMOVEALLCHILDREN(self.spriteNode)
        RA_SAFE_REMOVEALLCHILDREN(self.backNode)

        if self.rootNode ~= nil then
            RA_SAFE_REMOVEFROMPARENT(self.rootNode)
            if self.rootNode ~= nil then
                self.rootNode:release()
            end
        end

        if self.AllActionData ~= nil then
            self.AllActionData:release()
        end

        self.sprite = nil
        self.beforeNode = nil
        self.spriteNode = nil
        self.backNode = nil
        self.rootNode = nil
        self.AllActionData = nil

        --很关键：必须要调用，用来从场景中移除
        self:removeFromBattleScene()
    end
end

return RAFU_Effect_bone;