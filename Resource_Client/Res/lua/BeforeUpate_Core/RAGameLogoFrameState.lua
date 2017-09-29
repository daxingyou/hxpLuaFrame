local RAGameLogoFrameState = {}

RAGameLogoFrameState.libOSListenerClass = {
    onPlayMovieEndMessage = function(args)
        GameStateMachine.ChangeState(RARequire('RAGameLoadingState'))
    end
}
RAGameLogoFrameState.libOSListener = nil

function RAGameLogoFrameState.Enter(data)
    RAGameLogoFrameState.libOSListener = libOSScriptListener:new(RAGameLogoFrameState.libOSListenerClass)
    RAGameLogoFrameState.libOSListener:setRegister()
    local logoMp4Path = CCFileUtils:sharedFileUtils():fullPathForFilename("gamelogo.mp4")
    local skipPath = CCFileUtils:sharedFileUtils():fullPathForFilename("Skip.pmg")
    libOS:getInstance():setIsInPlayMovie(true);
    libOS:getInstance():playMovie(logoMp4Path, "")
end

function RAGameLogoFrameState.Exit(data)
    RAGameLogoFrameState.libOSListener:delete()
    RAGameLogoFrameState.libOSListener = nil
end

return RAGameLogoFrameState