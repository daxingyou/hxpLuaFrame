local RABattleFireState = {}

local RABattleConfig = RARequire('RABattleConfig')

function RABattleFireState:new(owner)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.fightInfo = {}
    o.timer = 0

    o.owner = owner
    
    return o
end

function RABattleFireState:Enter(fightInfo)
	self.timer = 0

	-- fightInfo.attacker:StartTimer()
	-- fightInfo.defenser:StartTimer()

	-- fightInfo.attacker:Fire(fightInfo)
	fightInfo.defenser:Fire(fightInfo)

	self.fightInfo = fightInfo
end

-- function RABattleFireState:Execute()
	-- local delta = GamePrecedure:getInstance():getFrameTime()
	-- self.timer = self.timer + delta
	-- if self.timer >= RABattleConfig.Fire_Duration then
	-- 	self.owner:End()
	-- 	return
	-- end
	
	-- self.fightInfo.attacker:Execute(delta)
	-- self.fightInfo.defenser:Execute(delta)
-- end

function RABattleFireState:Exit()
	--self.fightInfo.attacker:Destroy()
	--self.fightInfo.defenser:Destroy()
	--self.fightInfo.stanceNode:removeFromParentAndCleanup(true)
end

return RABattleFireState