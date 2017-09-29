--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAReviveActionData = class('RAReviveActionData',RABattleActionData)

function RAReviveActionData:initByPb(pb)
	self.super.initByPb(self,pb)
    self.pos = pb.revive.pos
    self.count = pb.revive.count
    self.hp = pb.revive.hp
end

return RAReviveActionData