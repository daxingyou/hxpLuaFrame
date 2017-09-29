local RABattleEntity = {}

function RABattleEntity:new(rootNode, marchId, result)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.fightInfo = 
	{
		attacker = {},	
		defenser = {},
		result = result,
		target = {},
		srcArmy = {},
		marchId = marchId,
		fightLayer = rootNode
	}

	o.SM = nil
    
    return o
end

function RABattleEntity:Fight(defenser_mapPos, attacker_armyInfo, attacker_mapPos)
	self:_init()

	self:Start({
		defenserPos = defenser_mapPos,
		attackerPos = attacker_mapPos,
		armyInfo = attacker_armyInfo or {},
		fightInfo = self.fightInfo
	})
end

function RABattleEntity:Execute()
	if self.SM then
		self.SM:Update()
	end
end

function RABattleEntity:Exit()
	MessageManager.sendMessage(MessageDef_World.MSG_MarchEndBattle, {marchId = self.fightInfo.marchId})
	if self.fightInfo.target.mapPos then
		local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
		RAWorldBuildingManager:delayUpdate(self.fightInfo.target.mapPos)
		RAWorldBuildingManager:decBuildingRef(self.fightInfo.target.mapPos)
	end
	if self.fightInfo.isSelfAttacker then
		local RARewardPushHandler = RARequire('RARewardPushHandler')
		RARewardPushHandler:showAllReward()
	end
	self:_checkIsCityRecreated()
	self:Clear()
end

function RABattleEntity:Clear()
	if self.SM then
		self.SM:Clear()
	end
	self.SM = nil
end

function RABattleEntity:Start(params)
	local RABattleStartState = RARequire('RABattleStartState')
	self.SM:ChangeState(RABattleStartState:new(self), params)
end

function RABattleEntity:Ready()
	local RABattleReadyState = RARequire('RABattleReadyState')
	self.SM:ChangeState(RABattleReadyState:new(self), self.fightInfo)
end

function RABattleEntity:Fire()
	local RABattleFireState = RARequire('RABattleFireState')
	self.SM:ChangeState(RABattleFireState:new(self), self.fightInfo)
end

function RABattleEntity:End()
	if self.SM == nil then return end
	
	local RABattleEndState = RARequire('RABattleEndState')
	self.SM:ChangeState(RABattleEndState:new(self), self.fightInfo)
end

function RABattleEntity:_init()
	local RABattleStateMachine = RARequire('RABattleStateMachine')
	self.SM = RABattleStateMachine:new()
end

function RABattleEntity:_checkIsCityRecreated()
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    if RAPlayerInfoManager.isCityRecreated() then
        local RARootManager = RARequire('RARootManager')
        RARootManager.OpenPage('RAConfirmPage', {
            labelText = _RALang('@NotifyCityRecreated'),
            resultFun = function ()
                if RARootManager.GetIsInWorld() then
                    local RAWorldVar = RARequire('RAWorldVar')
                    RAWorldVar:Init()
                    local RAWorldManager = RARequire('RAWorldManager')
                    RAWorldManager:LocateHome()
                end
            end
        })
        RAPlayerInfoManager.setCityRecreated(false)
    end
end

return RABattleEntity