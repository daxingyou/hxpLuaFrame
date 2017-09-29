
-- local mobdebug = require('Debug.mobdebug')
-- mobdebug.start('192.168.1.169')


-- avoid memory leak
collectgarbage("setpause", 100) 
collectgarbage("setstepmul", 5000)

-- local oldPath = package.path
-- package.path = oldPath .. ';.\\lua\\protobuf-lib\\?.lua;.\\lua\\protobuf\\?.lua;'

CCLuaLog("main.lua excute");
--RALogRelease(os.date())


require('BeforeUpate_Core.RAApi')

RARequire('GameStateMachine')

CC_PLATFORM = {
    CC_PLATFORM_UNKNOWN       	  = 0,
    CC_PLATFORM_IOS               = 1,
    CC_PLATFORM_ANDROID           = 2,
    CC_PLATFORM_WIN32             = 3
    -- CC_PLATFORM_MARMALADE         = 4,
    -- CC_PLATFORM_LINUX             = 5,
    -- CC_PLATFORM_BADA              = 6,
    -- CC_PLATFORM_BLACKBERRY        = 7,
    -- CC_PLATFORM_MAC               = 8,
    -- CC_PLATFORM_NACL              = 9,
    -- CC_PLATFORM_EMSCRIPTEN        = 10,
    -- CC_PLATFORM_TIZEN             = 11,
    -- CC_PLATFORM_WINRT             = 12,
    -- CC_PLATFORM_WP8               = 13
}

-- CC_PLATFORM_DICT = { [0]="UNKNOWN","IOS","ANDROID","WIN32","MARMALADE","LINUX","BADA","BLACKBERRY","MAC","NACL","EMSCRIPTEN","TIZEN","WINRT","WP8" }


--=================================
function GamePrecedure_reload()
    RALogRelease("GamePrecedure_reload")
	for k,v in pairs(package.loaded) do 
        package.loaded[k] = nil
    end
    for k,v in pairs(_G) do 
        if _G then
            _G[k] = nil 
        end
    end
end


function GamePrecedure_purgeCachedData()
    RALogRelease("GamePrecedure_purgeCachedData")
	-- GameStateMachine.purgeCachedData()
end

-- local firstPlay = true

--GamePrecedure_enterGame Android 每次切入后台在进入到游戏都会调用？？？？
function GamePrecedure_enterGame()
    RALogRelease("GamePrecedure_enterGame")
    --local RAGameConfig = RARequire("RAGameConfig")
    -- if firstPlay then
    --     firstPlay = false
    --     local BackgroundMusic = VaribleManager:getInstance():getSetting("LoadingMusic")
    --     SoundManager:getInstance():playMusic(BackgroundMusic, true)--RAGameConfig.BackgroundMusic
    -- end
end

function GamePrecedure_exitGame()
    RALogRelease("GamePrecedure_exitGame")

	--GamePrecedure_enterBackGround()
end

function GamePrecedure_enterBackGround()
    RALogRelease("GamePrecedure_enterBackGround")
    GameStateMachine.enterBackGround()
end

function GamePrecedure_enterForeground()
    RALogRelease("GamePrecedure_enterForeground")    
	GameStateMachine.enterForeground()
end

function GamePrecedure_fristUpdate()
    RALogRelease("GamePrecedure_fristUpdate: onFirstUpdate begin")
    GameStateMachine.Run()
end

function GamePrecedure_pushInitOver()
	RALogRelease("GamePrecedure_fristUpdate: pushInitOver begin")
end


local debugPostQueue = {}
local timeCount = 0
local sameCount = 1
local errorRepeatCount = 1
local lastDebugStr
local RASDKLoginConfig = RARequire("RASDKLoginConfig")
local PostReportError = function ( debugStr )

    local path = "/script/gameerror";
  
    -- local deviceId = RAPlatformUtils:getDeviceId()
    -- local serverId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.SERVER_ID, RASDKLoginConfig.DEF_SERVER_ID)
    -- local playerName = RAPlayerInfoManager.getPlayerName()
    -- local playerId = RAPlayerInfoManager.getPlayerId()

    -- local params = cjson.encode({deviceId = deviceId, serverId = serverId, playerId = playerId, playerName = playerName, errorInfo = debugStr})
    local params = cjson.encode({errorInfo = debugStr})

    -- dump(params)
    local md5Enc = com4loves.MD5:new()
    md5Enc:update(path, string.len(path))
    md5Enc:update(params, string.len(params))

    local md5Val = md5Enc:toString()
    md5Enc:delete()
    
    local ipAndPort = RASDKLoginConfig.errorLogUrl
    local pos = string.find(ipAndPort, ":")
    local ip = ipAndPort
    if pos then
        ip = string.sub(ipAndPort,1,pos - 1) --查找ip段，去除端口
    end
    local isIpv6 = GameCommon.isIPV6Net(ip)
    local url =string.format("http://%s%s", ipAndPort, path)
    local request = CCLuaHttpRequest:create()
    request:setUrl(url);
    request:setRequestData(params, string.len(params))
    request:setRequestType(CCHttpRequest.kHttpPost)
    request:setResponseScriptCallback(function ( response, isSuc, responseData, header, status, errorStr )
        status = status or "nil"
        RALogInfo("post gameErrorLog status = "..status)
        if isSuc == false then
            
            if errorRepeatCount <= RASDKLoginConfig.ErrorLogReSendCount then --重传3次之后停止该次发送
                errorRepeatCount = errorRepeatCount + 1
                table.insert(debugPostQueue,debugStr)
            else
                debugPostQueue = {}
            end            
        else
            errorRepeatCount = 1
        end       
    end)
    request:setTag("postErrorLog")
    if isIpv6 then
        request:setRequestIpType(CCHttpRequest.IP_V6)
    else
        request:setRequestIpType(CCHttpRequest.IP_V4)
    end
    CCHttpClient:getInstance():setTimeoutForConnect(10)
    CCHttpClient:getInstance():setTimeoutForRead(10)
    
    CCHttpClient:getInstance():send(request)
    request:release()   
end
-- 轮询报日志队列
local debugStrPostUpdate  = function ()
    
    if #debugPostQueue > 0 then
        timeCount = timeCount + GamePrecedure:getInstance():getFrameTime()
        if timeCount > RASDKLoginConfig.ErrorLogPostInv then  --RASDKLoginConfig.ErrorLogPostInv秒发送一次
            timeCount = 0
            local debugStr  = table.remove(debugPostQueue,1)
            if debugStr == lastDebugStr then  -- 相同报错次数
                sameCount = sameCount + 1
            else
                sameCount = 1
                lastDebugStr = debugStr
            end
            while debugStr == debugPostQueue[1] do
                table.remove(debugPostQueue,1)
            end
            if sameCount <= RASDKLoginConfig.ErrorLogRepeatNum then --相同错误日志达到多少条就不再发送
                PostReportError(debugStr)
            end
        end
    end
end

function GamePrecedure_update()	
    debugStrPostUpdate()
	GameStateMachine.Update()
end

function __G__TRACKBACK__(msg)
	
	local debugStr = "LUA ERROR: " .. tostring(msg) ..	 "\n" .. debug.traceback()
    --print error in log
	RALogError(debugStr)

    if RAGameUtils:isDebug() then
	    CCMessageBox(debugStr,"LUA ERROR")
    end
    if #debugPostQueue< 50 then
        table.insert(debugPostQueue,debugStr) --缓存队列 多少秒发送一次错误日志 防止帧循环中报错
    end
end

local repeatCount = 1
local isPostIng = false
-- game.log发送接口，发送game.log后多少条数据，RASDKLoginConfig.GameLogPostLins配置发送条数
function PostGameLog()
    if isPostIng then return end

    local logInfo = ""
    local gameLog = TableReaderManager:getInstance():getTableReader("game.log", 1)
    local logCount = gameLog:getLineCount()
    local beginCount = 0
    if logCount > RASDKLoginConfig.GameLogPostLins then
        beginCount = logCount - RASDKLoginConfig.GameLogPostLins - 1
    end
    for i = beginCount, logCount - 1 do
        logInfo = logInfo..gameLog:getData(i, 0)
    end    

    local path = "/script/gamelog";

    local deviceId = RAPlatformUtils:getDeviceId()
    local serverId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.SERVER_ID, RASDKLoginConfig.DEF_SERVER_ID)
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local playerName = RAPlayerInfoManager.getPlayerName()
    local playerId = RAPlayerInfoManager.getPlayerId()

    local params = cjson.encode({deviceId = deviceId, serverId = serverId, playerId = playerId, playerName = playerName, logInfo = logInfo})

    -- dump(params)
    local md5Enc = com4loves.MD5:new()
    md5Enc:update(path, string.len(path))
    md5Enc:update(params, string.len(params))

    local md5Val = md5Enc:toString()
    md5Enc:delete()
    
    local ipAndPort = RASDKLoginConfig.gameLogPostUrl
    local pos = string.find(ipAndPort, ":")
    local ip = ipAndPort
    if pos then
        ip = string.sub(ipAndPort,1,pos - 1) --查找ip段，去除端口
    end    
    local isIpv6 = GameCommon.isIPV6Net(ip)
    local url =string.format("http://%s%s", ipAndPort, path)
    isPostIng = true
    local request = CCLuaHttpRequest:create()
    request:setUrl(url);
    request:setRequestData(params, string.len(params))
    request:setRequestType(CCHttpRequest.kHttpPost)
    request:setResponseScriptCallback(function ( response, isSuc, responseData, header, status, errorStr )
        isPostIng = false
        status = status or "nil"
        RALogInfo("post gameLog status = "..status)
        if isSuc == false then
            if repeatCount <= 3 then --重传3次之后停止该次发送
                repeatCount = repeatCount + 1
                --PostGameLog()
            end
        else
            repeatCount = 1
        end
    end)
    request:setTag("postGameLog")
    if isIpv6 then
        request:setRequestIpType(CCHttpRequest.IP_V6)
    else
        request:setRequestIpType(CCHttpRequest.IP_V4)
    end
    CCHttpClient:getInstance():setTimeoutForConnect(10)
    CCHttpClient:getInstance():setTimeoutForRead(10)
    
    CCHttpClient:getInstance():send(request)
    request:release()
end


--__G__TRACKBACK__ = nil