local RABattleStateMachine = {}

function RABattleStateMachine:new()
    local o = {}

    setmetatable(o, self)
    self.__index = self

    o.curState = nil
    o.stateListener = nil

    return o
end

function RABattleStateMachine:Update()
	if self.stateListener then
        self.stateListener:beforeUpdate()
    end
	
    if self.curState and self.curState.Execute then
        self.curState:Execute()
    end
	
	if self.stateListener then
        self.stateListener:afterUpdate()
    end
end

function RABattleStateMachine:ChangeState(state, data)
    if self.curState then
        if self.curState == state then 
            return
        elseif self.curState.Exit then
            self.curState:Exit()
        end
    end
    
    self.curState = state
    
    if self.curState then
		if data then
			self.curState:Enter(data)
		else
			self.curState:Enter()
		end			
    end
end

function RABattleStateMachine:Clear()
    self:ChangeState(nil)
end

function RABattleStateMachine.getState()
    return self.curState
end

function RABattleStateMachine.setStateListener(listener)
    self.stateListener = listener
end

function RABattleStateMachine.getStateListener()
    return self.stateListener
end

return RABattleStateMachine