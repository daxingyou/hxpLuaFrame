
GameStateMachine = {}
GameStateMachine.curState= nil
GameStateMachine.stateListener= nil
function GameStateMachine.Run()
    --RAGameInitState
    --RAGameUpdateState
    local RASDKLoginConfig = RARequire("RASDKLoginConfig")
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS and RASDKLoginConfig.OpenLogoMovie then
        GameStateMachine.ChangeState(RARequire('RAGameLogoFrameState'))
    else
        local editMode = SetupFileConfig:getInstance():getSectionString("editMode")
        if editMode == 'true' then 
            GameStateMachine.ChangeState(RARequire('RAEditingState'))
        else
            GameStateMachine.ChangeState(RARequire('RAGameLoadingState'))
        end 
        -- GameStateMachine.ChangeState(RARequire('RAEditingState'))
    end

    --初始化uuid的seed，整个application 一次初始化种子
    local uuid = RARequire("uuid")
    uuid.seed()
end

function GameStateMachine.Update()
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.beforeUpdate()
    end
	
    local curState = GameStateMachine.curState
    if curState and curState.Execute then
        curState.Execute()
    end
	
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.afterUpdate()
    end
end

function GameStateMachine.ChangeState(state,data)
    RALogRelease("GameStateMachine.ChangeState")
    if GameStateMachine.curState then
        if GameStateMachine.curState == state then 
            return
        else
            RALogRelease("GameStateMachine.curState.Exit")
            GameStateMachine.curState.Exit()
        end
    end
    GameStateMachine.curState = state
    if GameStateMachine.curState then
		if data then
			GameStateMachine.curState.Enter(data)
		else
            RALogRelease("GameStateMachine.curState.Enter")
			GameStateMachine.curState.Enter()
		end			
    end
end

function GameStateMachine.getState()
    return GameStateMachine.curState
end

function GameStateMachine.setStateListener(listener)
    GameStateMachine.stateListener = listener
end

function GameStateMachine.getStateListener()
    return GameStateMachine.stateListener
end

function GameStateMachine.enterBackGround()
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.beforeEnterBackGround()
    end
	
    if GameStateMachine.curState and GameStateMachine.curState.enterBackGround then
        GameStateMachine.curState.enterBackGround()
    end
	
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.afterEnterBackGround()
    end
end

function GameStateMachine.enterForeground()
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.beforeEnterForeground()
    end
	
    if GameStateMachine.curState then
        if GameStateMachine.curState.enterForeground ~= nil then
            GameStateMachine.curState.enterForeground()
        end
    end
	
	if GameStateMachine.stateListener then
        GameStateMachine.stateListener.afterEnterForeground()
    end
end

function GameStateMachine.purgeCachedData()    
	-- if GameStateMachine.stateListener then
 --        GameStateMachine.stateListener.beforePurgeCachedData()
 --    end
	
 --    if GameStateMachine.curState then
 --        GameStateMachine.curState.purgeCachedData()
 --    end
	
	-- if GameStateMachine.stateListener then
 --        GameStateMachine.stateListener.afterPurgeCachedData()
 --    end
end