local RABattleUnit = {}

local UIExtend = RARequire('UIExtend')
local common = RARequire('common')
local RABattleConfig = RARequire('RABattleConfig')
local Duration = RABattleConfig.Fire_Duration

function RABattleUnit:new()
	local o = {}

    setmetatable(o, self)
    self.__index = self

	o.timer = 0

	o.increaseRate = 0

	o.progressSprite = nil

	o.timing = false

	o.rawSize = {}
    
    return o	
end

function RABattleUnit:Execute(delta)
	if not self.timing then return end
	self.timer = self.timer + delta
	self:_updateLife(common:math_round(self.timer * self.increaseRate))
end

function RABattleUnit:delete()
	self.timing = false
	UIExtend.unLoadCCBFile(self)
end

function RABattleUnit:Init(cfg)
	local life, loss = cfg.life or 0, cfg.loss
	if life == 0 then
		-- 无兵的情况
		life, loss = 1, 1
	end
	self.increaseRate = (loss / life * RABattleConfig.HP_Total) / Duration

	UIExtend.loadCCBFile(RABattleConfig.HP_CCBFile, self)
	self.ccbfile:setPosition(cfg.hpPos.x, cfg.hpPos.y)
	if cfg.stanceNode then
		cfg.stanceNode:addChild(self.ccbfile, RABattleConfig.HP_NodeTag)
	end

	UIExtend.setNodeVisible(self.ccbfile, 'mHP2', false)
	self.progressSprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, 'mHP')
	self.progressSprite:setVisible(true)
	self.rawSize = self.progressSprite:getContentSize()
	if RABattleConfig.HP_FullWidth == 0 then
		RABattleConfig.HP_FullWidth = self.rawSize.width
	else
		self.rawSize.width = RABattleConfig.HP_FullWidth
		self.progressSprite:setContentSize(self.rawSize.width, self.rawSize.height)
	end
end

function RABattleUnit:StartTimer()
	if self.ccbfile then
		self.timing = true
	end
end

function RABattleUnit:_updateLife(descNum)
	if descNum >= RABattleConfig.HP_LossToRed then
		self.progressSprite:setVisible(false)
		self.progressSprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, 'mHP2')
		self.progressSprite:setVisible(true)
	end
	local width = self.rawSize.width - descNum * RABattleConfig.HP_DescWidth
	width = common:clamp(width, 0, self.rawSize.width)
	if descNum >= RABattleConfig.HP_Total then
		self.progressSprite:setVisible(false)
	else
		self.progressSprite:setContentSize(width, self.rawSize.height)
	end
end

return RABattleUnit