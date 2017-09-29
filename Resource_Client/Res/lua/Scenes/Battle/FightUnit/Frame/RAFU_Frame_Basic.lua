--[[
description: 地面部队基础的Frame模型
author: zhenhui
date: 2016/11/22
]]--

local RAFU_Frame_Basic = class('RAFU_Frame_Basic',{
		EnumManager = RARequire("EnumManager"),
        turnPeriod = 0
	})

--构造函数
function RAFU_Frame_Basic:ctor(owner,boneData)
    local RAFU_FrameData = RARequire("RAFU_FrameData")
	self.owner = owner
	self.boneData = boneData
	if boneData.CanSwitch == nil then boneData.CanSwitch = false end
	self.CanSwitch = boneData.CanSwitch
	self.frameConfigName = boneData.BoneFrameCfgName
    self.frameConfig = RARequire("RAFU_Cfg_Bone")[boneData.BoneFrameCfgName]
    assert(self.frameConfig ~= nil ,"self.frameConfig ~= nil")
	self.AllActionData = RAFU_FrameData:new(self.frameConfigName)
	self:_initSprite()
end

--初始化sprite
function RAFU_Frame_Basic:_initSprite()
	self.sprite = CCSprite:create("empty.png")
    local zorder = self.boneData.Zorder
	self.owner.spriteNode:addChild(self.sprite,zorder)
	self:initSpriteInfo()
end


--colorParam is defined in RAFightDefine
function RAFU_Frame_Basic:changeMaskColor(colorParam)
    local colorKey = colorParam.key 
    local r = colorParam.color.r or 255
    local g = colorParam.color.g or 255
    local b = colorParam.color.b or 255
    CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    if self.sprite ~= nil then
        self.sprite:setMaskColor(CCTextureCache:sharedTextureCache():getColorByName(colorKey))
    end
end

function RAFU_Frame_Basic:initSpriteInfo()
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
    self.currentAction = ACTION_TYPE.ACTION_IDLE
    self.currentDirection = FU_DIRECTION_ENUM.DIR_UP
    self:changeAction(self.currentAction, self.currentDirection) 
end

--析构函数
function RAFU_Frame_Basic:release()
    if self.AllActionData ~= nil then
        self.AllActionData:release()
    end
    RA_SAFE_REMOVEFROMPARENT(self.sprite)
end

--转换方向，根据方向做转动
function RAFU_Frame_Basic:switchDirection(lastDirection, direction, isCircle)
    local frameArray = CCArray:create();
    local frameTable
    if self.boneData.frameNum and self.boneData.frameNum == 8 then  
        frameTable = self.EnumManager:getFUSwitchDirTableFor8(lastDirection,direction,isCircle)
    elseif self.boneData.frameNum and self.boneData.frameNum == 16 then
        frameTable = self.EnumManager:getFUSwitchDirTable(lastDirection,direction,isCircle) 
    else
       frameTable = self.EnumManager:getFUSwitchDirTableFor32(lastDirection,direction,isCircle)
    end
    local frameInfo = self.AllActionData.frameInfo
    local actionType = ACTION_TYPE.ACTION_ROTATE
    for i = 1,#frameTable do 
        local index = frameTable[i]

        local file = frameInfo.name.."_"..actionType .."_"..index.."_1"..".png"

        local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(file);
        if pSpriteFrame ~= nil then
            frameArray:addObject(pSpriteFrame);
        else
            RALog("RAFU_Frame_Turn:switchDirection "..file .."not found");    
        end
    end

    if frameArray:count()==0 then 
        return nil
    end

    -- local fps = 16
    local pAnimation = CCAnimation:createWithSpriteFrames(frameArray, self.turnPeriod/2);
    local animate = CCAnimate:create(pAnimation);      

    return animate
end

--控制Sprite显影
function RAFU_Frame_Basic:setVisible(flag)
    if self.sprite ~= nil then
        self.sprite:setVisible(flag)
    end
end

--被销毁的处理
function RAFU_Frame_Basic:beenDestroy(time,callback)
    if self.sprite ~= nil then
        if callback ~= nil then
            local array = CCArray:create()
            local fadeOut = CCFadeTo:create(time,0)         
            array:addObject(fadeOut)
            local callbackAct = CCCallFunc:create(callback)
            array:addObject(callbackAct)
            local seq = CCSequence:create(array);
            self.sprite:runAction(seq)
        else
            local fadeOut = CCFadeTo:create(time,0) 
            self.sprite:runAction(fadeOut)
        end
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
function RAFU_Frame_Basic:changeAction(actionType, direction, paramData)
    if self.AllActionData == nil or self.owner == nil then assert(false,"false") end
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

    if direction == self.EnumManager.FU_DIRECTION_ENUM.DIR_NONE then
        return
    end
    

    if self.frameConfig.actionDefine[actionType] == nil then
        RALog("RAFU_Frame_Basic:changeAction -- do not has the actionType "..actionType)
        return
    end


    self:updateAction(actionType, direction, param)
end

function RAFU_Frame_Basic:getOffsetY( )
    self.boneData.offsetY = self.boneData.offsetY or 0
    return self.boneData.offsetY
end


function RAFU_Frame_Basic:getFrameCount(actionType, direction)
    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction)
    local frameCount = 0
    if oneAction and oneAction.frameArray:count() then frameCount = oneAction.frameArray:count() end
    return frameCount
end


function RAFU_Frame_Basic:getFrameTime(actionType, direction)
    local oneAction = self.AllActionData:getActionByTypeAndDir(actionType,direction)
    local frameTime = 0
    if oneAction and oneAction.frameTime then frameTime = oneAction.frameTime end
    return frameTime
end

--更新方向和动作的具体的实现
function RAFU_Frame_Basic:updateAction(actionType, direction, param)
    if self.AllActionData == nil or self.owner == nil or self.working==false then return end
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

    if self.onActionChange~=nil then 
        self.onActionChange(self.owner,actionType,direction)
    end

    self.currentDirection = direction
    self.currentAction = actionType

end


return RAFU_Frame_Basic