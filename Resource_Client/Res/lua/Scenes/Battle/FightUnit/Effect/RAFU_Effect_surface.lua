--[[
description: 弹坑效果
]]--

local UIExtend = RARequire("UIExtend")
local RAFU_Effect_surface = class('RAFU_Effect_surface',RARequire("RAFU_Effect_base"))


function RAFU_Effect_surface:ctor(effectCfgName)
    --为EFFECT 特效实例创建uid
    self.super.ctor(self,effectCfgName)

	self.effectCfgName = effectCfgName
    local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
	self.effectData = RAFU_Cfg_Effect[effectCfgName]
    local common = RARequire("common")
    if common:addSpriteFramesWithFile(self.effectData.plist,self.effectData.pic)==false then
        RALogError("RAFU_Effect_surface:ctor -- file "..self.effectData.plist .."not found");   
    end
    self.probability = self.effectData.probability or 100
    self.percent = self.effectData.percent or {100}
end


function RAFU_Effect_surface:Enter(data)
    RALog("RAFU_Effect_surface:Enter")

    --很关键：调用self.super.Enter(self,data),或者直接调用调用AddToBattleScene()  来发送消息加入场景中
    self.super.Enter(self,data)


    assert(data~= nil and data.targetSpacePos ~= nil, "false")
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local tile = RACcp(0,0)
    if data.tile then
        tile = data.tile
    elseif data.targetSpacePos then
        local targetSpacePos =  data.targetSpacePos
        tile = RABattleSceneManager:spaceToTile(targetSpacePos)        
    end

    if RABattleSceneManager:isSurfaceEffectExist(tile) == false then
        if math.random(100) <= self.effectData.probability then
            local radom = math.random(100)
            local index = 1
            for i,v in ipairs(self.percent) do
                if radom <= v then
                    index = i
                    break
                end
            end
            local file = self.effectData.frameName..index..".png"
            local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(file);

            if pSpriteFrame ~= nil then
                local frameSprite = CCSprite:createWithSpriteFrame(pSpriteFrame)
                --挂接到effectLayer节点，同时设置位置
                local RABattleScene = RARequire("RABattleScene")

                RABattleScene.mSurfaceLayer:addChild(frameSprite)
                local curPos 
                if data.targetSpacePos then
                    curPos = ccp(data.targetSpacePos.x, data.targetSpacePos.y);
                else
                    local pos = RABattleSceneManager:tileToSpace( tile )
                    curPos = ccp(pos.x, pos.y)
                end
                frameSprite:setPosition(curPos)
                RABattleSceneManager:addSurfaceEffect(tile, index)
            else
                RALogError("RAFU_Effect_surface:Enter(data) -- file "..file .."not found");    
            end
        end
    end
end

function RAFU_Effect_surface:Execute(dt)

end

function RAFU_Effect_surface:Exit()
    --很关键：必须要调用，用来从场景中移除
    self:removeFromBattleScene()
end

return RAFU_Effect_surface;