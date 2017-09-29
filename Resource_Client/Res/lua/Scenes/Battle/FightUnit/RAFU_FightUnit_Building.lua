local RAFU_FightUnit_Building = class('RAFU_FightUnit_Building',RARequire("RAFU_FightUnit_Basic"))

function RAFU_FightUnit_Building:behit(damage)

    local isBreakenBefore = self:isBreaken() 
    self.super.behit(self,damage)
    local isBreakenNow = self:isBreaken()

    --从正常到毁坏
    if isBreakenBefore == false and isBreakenNow == true then 
        self:showDestory()
    end 
end

function RAFU_FightUnit_Building:showDestory()
    if self.curState == ACTION_TYPE.ACTION_IDLE then 
        local direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP
        for boneName,boneController in pairs(self.boneManager) do
            boneController:changeAction(ACTION_TYPE.ACTION_BEHIT_IDLE,direction,nil,false,true)        
        end
    end

    if self.cfgData.DestoryBuff ~= nil then 
        for buffKey,pos in pairs(self.cfgData.DestoryBuff) do
            local data = {
                buffCfgName = buffKey,
                targetSpacePos = pos
            }
            self.buffSystem:AddBuff(data)
        end
    end 
end

-- 获取实体的中心点
function RAFU_FightUnit_Building:getHitPosition()
    --返回实体中心点的偏移
    local coreBone_offsetY = self:_getCoreBonePosOffset()

    local pos = RA_GET_POSITION(self.rootNode)
    pos.y = pos.y - self.centerOffset + coreBone_offsetY

    -- pos.y = pos.y + math.random(-self.maxWidth/4,self.maxWidth/4)
    pos.x =  pos.x + math.random(-self.maxHeight/4,self.maxHeight/4)

    return pos
end

--设置初始方向
function RAFU_FightUnit_Building:setInitDirection(dir)
    self:setDir(dir)
    local direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP

    local param = {
        callback = nil,--回调
        needSwitch = false,--是否强制转向
        isforce = true,--是否强制改变动作
        newFps = nil,--新的播放fps
        startFrame = nil--新的开始帧
    }


    for k,boneController in pairs(self.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_IDLE, direction,param)
    end
end

function RAFU_FightUnit_Building:behitBuff()
    --buff test by zhenhui
    -- local data = {
    --     lifeTime = 0.5,
    --     buffCfgName = "BUFF_BorisTarget"
    -- }
    -- self.buffSystem:AddBuff(data)
end

-- function RAFU_FightUnit_Building:_initHUDNode()
--     self.super._initHUDNode(self)
--     -- self.
--     local RAFU_BloodBar = RARequire('RAFU_BloodBar')
--     if self.data.confData.id  == 2002  then
--         self.bloodBar = RAFU_BloodBar:new()
--         self.bloodBar:init()
--         self.bloodBar.ccbfile:setPosition(-60,10)
--         self.hudNode:addChild(self.bloodBar.ccbfile)
--     end
-- end

--更新count
function RAFU_FightUnit_Building:updateCount(count)
    if self.bloodBar ~= nil then 
        if self.data.curHp == self.data.totalHp then 
            self:setBloodBarVisible(false)
        else
            self:setBloodBarVisible(true)
        end 
        self.bloodBar:setBarValue(self.data.curHp,self.data.totalHp,self:isBreaken())
    end 
end


function RAFU_FightUnit_Building:isBreaken()
    if self.data.curHp < self.data.totalHp * BLOOD_GREEN_TO_RED then 
        return true
    else
        return false
    end 
end


return RAFU_FightUnit_Building