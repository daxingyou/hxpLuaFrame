local UIExtend = RARequire('UIExtend')

--血条
local RAFU_BloodBar =
{
	mFullLength = nil,
	mRedBar 	= nil,
	mGreenBar 	= nil,
	mBarHolder 	= nil,
	mHolderPos 	= nil,
}

function RAFU_BloodBar:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAFU_BloodBar:init(bloodId)
    local ccbRes = "Ani_Fight_Blood_L.ccbi"
    if bloodId then
        local RAFU_Cfg_Blood = RARequire("RAFU_Cfg_Blood")
        local cfg = RAFU_Cfg_Blood[bloodId]
        if cfg and cfg.C_B_Res and cfg.C_B_Res ~= "" then
            ccbRes = cfg.C_B_Res
        end
    end

    UIExtend.loadCCBFile(ccbRes,self)
    self.mRedBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mHP2")
    self.mGreenBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mHP")

    if not self.mBarHolder then
        self.mBarHolder = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mHPPosNode')
    	local posX, posY = self.mBarHolder:getPosition()
    	self.mHolderPos = RACcp(posX, posY)
    end

    if self.mFullLength == nil then
    	local size = self.mRedBar:getContentSize()
    	self.mFullLength = size.width
    	size:delete()
    end
end

function RAFU_BloodBar:setVisible(isVisible)
    self.ccbfile:setVisible(isVisible)
end


function RAFU_BloodBar:setBarValue(value,totalValue,isBreak,isMove)
    if isMove == nil then 
        isMove = true
    end 

	totalValue = totalValue > 0 and totalValue or 1
    value = (value > totalValue) and totalValue or value

	local posX = self.mHolderPos.x + self.mFullLength * (1 - value / totalValue)
	local pos = ccp(posX, self.mHolderPos.y)

	self.mBarHolder:stopAllActions()

    if isMove then 
	   self.mBarHolder:runAction(CCMoveTo:create(0.4, pos))
    else
       self.mBarHolder:setPosition(pos)
    end 
	pos:delete()

	self.mRedBar:setVisible(isBreak)
	self.mGreenBar:setVisible(not isBreak)
end

function RAFU_BloodBar:_reset()
    self.mFullLength        = nil
	self.mRedBar 	        = nil
	self.mGreenBar 	        = nil
	self.mBarHolder 	    = nil
	self.mHolderPos 	    = nil
end

function RAFU_BloodBar:release()
    --释放资源的时候把进度条重置成原来状态，否则当下一次冲缓冲池loadccbi的时候，初始状态不对，会造成显示问题
    if self.mBarHolder ~= nil then
        self.mBarHolder:setPositionX(self.mHolderPos.x)
    end

    self:_reset()
    UIExtend.unLoadCCBFile(self)
end

return RAFU_BloodBar