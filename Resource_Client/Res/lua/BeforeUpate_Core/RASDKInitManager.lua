--region RASDKInitManager.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASDKInitManager = {
    ip = "",
    port = "",
    platformProductionInfo = {}
}

local RASDKLoginConfig = dynamic_require("RASDKLoginConfig")
local RAUpdateManager = dynamic_require("RAUpdateManager")
local RASDKUtil = dynamic_require("RASDKUtil")
local isInUpdate = false
local isInLogin = false
local serverListGetError = false
local mFrameTime = 0

local ClientSDKState = {
    SDKInit =1,     --SDK初始化
    SDKLoading = 2  --SDK登陆
}
local startCheckSDK = false--是否开始进行SDK状态检测
local checkSDKState = ClientSDKState.SDKInit --当前需要检测的sdk状态
local currSDKState = nil--当前sdk的状态，用来进行sdk校验
local checkSDKTotalTime = 20--检测时间间隔，单位是s，10s检测一次
local checkSDKDurTime = 0--检测经过时间，等于checkSDKTotalTime的时候进行一次检测
---------------------------SDK related begin-------------------------
function RASDKInitManager.onInitSDK()
    --初始化sdk
    RALogRelease("RASDKInitManager.onInitSDK")
    
    --设置sdk检测状态
    startCheckSDK = true
    checkSDKState = ClientSDKState.SDKInit
    checkSDKDurTime = 0


    RASDKUtil.initSDK()
end

function RASDKInitManager.loginSDK()
    --logTime
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = "RASDKInitManager.loginSDK Start To Login SDK" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    RALogRelease(timeStr)

    --登陸sdk
    RALogRelease("RASDKInitManager.loginSDK")
    if RASDKUtil.isSDKLogin() == false then
        --设置sdk检测状态
        startCheckSDK = true
        checkSDKState = ClientSDKState.SDKLoading
        checkSDKDurTime = 0

        RASDKUtil.sendMessageG2P("SDKLogin")
    end
    
end

function RASDKInitManager.switchUserSDK()
    --切换账号
    --RALogRelease("RASDKInitManager.switchUserSDK")
    --Android 平台,根据sdk那边反馈,切换账号先不用 SDKSwitchUsers 直接用调用logout login
    --if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
    --    RASDKInitManager.logout()
        --RASDKInitManager.loginSDK()
    --else
        local RAGameLoadingState= RARequire("RAGameLoadingState")
        --RAGameLoadingState.isSwitchUser = false
        RASDKUtil.sendMessageG2P("SDKSwitchUsers");
    --end
end

function RASDKInitManager.logout()
    --登陸sdk
    RALogRelease("RASDKInitManager.logout")
--     if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
--        RASDKUtil.initSDK()
--    end
    RASDKUtil.sendMessageG2P("SDKLogout")
end

function RASDKInitManager.getDeviceModel()
    --获得设备型号
    RALogRelease("RASDKInitManager.getDeviceModel")
    if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
        local ret = RASDKUtil.sendMessageG2P("getDeviceModel")
        return ret.deviceModel
    else
        return "win32"
    end
    
end


--SDKListener SDK逻辑处理完后的回调
function RASDKInitManager:onSDKInit(listener)
    --logTime
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = "RASDKInitManager:onSDKInit End To init SDK" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    RALogRelease(timeStr)

    startCheckSDK = false--接受到回调，暂时关闭sdk检测

    --SDK初始化成功
    local initStatus = cjson.decode(listener:getResultStr()).status
    if initStatus == false then
        local RAGameLoadingState = RARequire("RAGameLoadingState")
        RAGameLoadingState.setLoadingLabel(_RALang("@SDKInitFail"))
        RALogRelease("RASDKInitManager:onSDKInit Fail!!!")
        --CCMessageBox(_RALang("@SDKInitFail"),_RALang("@hint"))
        return 
    end

    currSDKState = ClientSDKState.SDKInit--设置当前sdk完成的状态

    RALogRelease("RASDKInitManager:onSDKInit")
    self.loginSDK()--登陸sdk
    
end

function RASDKInitManager:onSDKLogin(listener)
    RALogRelease("RASDKInitManager:onSDKLogin")
    local loginState = false
    if listener:getResultStr() ~= nil and listener:getResultStr() ~= "" then
        local resutJson = cjson.decode(listener:getResultStr())
        if resutJson then
            loginState = resutJson.status
        else
            RALogRelease("RASDKInitManager:onSDKLogin The Result String can not decoded!")
        end
    else
        RALogRelease("RASDKInitManager:onSDKLogin There is not ResultStrint")
    end

    startCheckSDK = false--接受到正确的回调，暂时关闭sdk检测

    if loginState == true then
        RALogRelease("SDK Login Success!")
        currSDKState = ClientSDKState.SDKLoading--设置当前sdk完成的状态

        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
            local directLogin = SetupFileConfig:getInstance():getSectionString("directLogin")
            if directLogin == nil then
                directLogin = "false"
            end
            --if directLogin, send get server list directly, else show inputbox
            if directLogin == "false" then
                RASDKUtil.sendMessageG2P('showInputbox')
            else
                RASDKInitManager.getServerList(RASDKInitManager.httpListener)
            end
            
        else
            --logTime
            local currTime = os.time()
            local currTab = os.date("*t", currTime);
            local formatStr = "RASDKInitManager:onSDKLogin End To Login SDK" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
            local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
            RALogRelease(timeStr)

            RASDKInitManager.getServerList(RASDKInitManager.httpListener)
        end
    else
        local RAGameLoadingState = RARequire("RAGameLoadingState")
        RAGameLoadingState.setLoadingLabel(_RALang("@SDKLoginFail"))
        --CCMessageBox(_RALang("@SDKLoginFail"),_RALang("@hint"))
        --RASDKInitManager.loginSDK()--登陸sdk
        return 
    end
end

--设置是否check sdk
function RASDKInitManager:setSDKCheck(open)
    startCheckSDK = open
    if not open then
        checkSDKDurTime = 0
    end
end

function RASDKInitManager:onProductInfo(listener)
    RALogRelease("RASDKInitManager:onProductInfo")
    local productionInfoStr = cjson.decode(listener:getResultStr()).productInfos

    local productionArr = RAUpdateManager.Split(productionInfoStr, "|")
    for _, productionItemStr in ipairs(productionArr) do
        if productionItemStr then
            local productionItemArr = RAUpdateManager.Split(productionItemStr, ",")
            local productionId = productionItemArr[1]
            local currencyCode = productionItemArr[2]
            local formatterPrice = productionItemArr[3]
            local price = tonumber(productionItemArr[4])
            local description = productionItemArr[5]
            local item = {["productionId"] = productionId, ["formatterPrice"] = formatterPrice, ["currencyCode"] = currencyCode, ["price"] = price, ["description"] = description}
            self.platformProductionInfo[productionId] = item
        end
    end
end


function RASDKInitManager:onSDKLogOutSuccess(listener)
    --Android 平台logout成功后，如果是切换账号过来的，需要重新调用出登录
    -- if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
    --     local RAGameLoadingState= RARequire("RAGameLoadingState")
    --     if RAGameLoadingState.isSwitchUser == true then
    --         RAGameLoadingState.isSwitchUser = false
    --         RASDKInitManager.loginSDK()
    --     end
    -- end

    --Android 平台需要判断登出的时候 是否在播放视频 如果在播放 需要关闭
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        RASDKUtil.sendMessageG2P("endPlayMovie")
    end
end

function RASDKInitManager:onSDKLogOutFailed(listener)
    RALogRelease("RASDKInitManager.onSDKLogOutFailed()")
end

function RASDKInitManager:onSDKSwitchUsersSuccess(listener)
    --SDK切换账号成功
    RALogRelease("RASDKInitManager:onSDKSwitchUsersSuccess")
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        RASDKInitManager:onInputboxOK(listener)
    end
end

function RASDKInitManager:onSDKSwitchUsersFailed(listener)
    --SDK切换账号失败
    RALogRelease("RASDKInitManager:onSDKSwitchUsersFailed")
    self.loginSDK()
    --CCMessageBox(_RALang("@SDKSwitchUserFail"),_RALang("@hint"))
end

---------------------------http request related begin-------------------------

function RASDKInitManager.httpListener(response, isSuc, responseData, header, status, errorStr)
    --logTime
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = "RASDKInitManager.httpListener End To getServerList" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    RALogRelease(timeStr)

    if errorStr=="" then
        if isSuc==false then
            --没有正常获取到
            --CCMessageBox(_RALang("@GetServerListError"),_RALang("@hint"))
            RALogRelease("RASDKInitManager.httpListener Get Server List Error With no Error String")
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.setLoadingLabel(_RALang("@GetServerListError"))
            serverListGetError = true
            return
        end
        serverListGetError = false

        RALogRelease("RASDKInitManager.httpListener the serverlist http response is "..responseData)

        if responseData == nil or responseData=="" then
            RALogRelease("RASDKInitManager.httpListener Get Server List Error : The responseData is nil or empty")
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.setLoadingLabel(_RALang("@GetServerListError"))
            serverListGetError = true
            return
        end

        local jsonBody = cjson.decode(responseData);
        if jsonBody.code ~= nil and  jsonBody.code >0 then
            RALogRelease("RASDKInitManager.httpListener Get Server List Error : The jsonBody.code > 0")
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.setLoadingLabel(_RALang("@GetServerListError"))
            --CCMessageBox(_RALang("@GetServerListError"),_RALang("@hint"))
            serverListGetError = true
            return
        end
        local serverId = jsonBody.serverId or "s1"
        local port = jsonBody.port or DEF_SERVER_PORT
        local ip = jsonBody.ip or DEF_SERVER_IP
        local updateUrl = jsonBody.update_url or ""
        local pageUrl = jsonBody.page_url or "www.com4loves.com"
        if jsonBody.log_url then
            RASDKLoginConfig.errorLogUrl = jsonBody.log_url
            RASDKLoginConfig.gameLogPostUrl = jsonBody.log_url
        end   
        local client_ver = jsonBody.client_ver or ""
        local puid = jsonBody.puid or ""
        local playerId = jsonBody.playerId or ""


	    CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.PLAYER_UID, playerId);
	    CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.ACCOUNT_PUID, puid);
        RALogRelease("port is "..tostring(port))
	    CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.SERVER_ID, serverId);
	    CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.SERVER_IP, ip);
	    CCUserDefault:sharedUserDefault():setIntegerForKey(RASDKLoginConfig.SERVER_PORT, port);

	    CCUserDefault:sharedUserDefault():flush();

        --获得gameserver基本信息成功
        RASDKInitManager.ip = ip
        RASDKInitManager.port = port

        --针对IOS平台，判断是否覆盖安装，来判断是否清除内更新资源
        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS or
         CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
            RASDKInitManager:judgeOverideInstall()
        end

        --win32平台下用于测试内更新逻辑
        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
            client_ver = SetupFileConfig:getInstance():getSectionString("testResClientVersion")
            updateUrl = SetupFileConfig:getInstance():getSectionString("testUpdateUrl")
        end
        
        --根据服务器资源版本号，判断是否需要做资源更新，如果不需要直接进入下一个状态
        if RAUpdateManager:judgeVersionUpdate(client_ver) then
            RASDKInitManager:dealWithVersionUpdate(pageUrl)
        elseif RAUpdateManager:judgeResUpdate(client_ver) then
            --todo:弹出内更新框
            local param = {
                updateUrl = updateUrl,
                serverResVersion = client_ver
            }
            isInUpdate = true
            local RAGameLoadingState= RARequire("RAGameLoadingState")
            RAGameLoadingState.changeState(RAGameLoadingStatus.HotUpdate)
            RAUpdateManager:Enter(param)           
        else
            RASDKInitManager:EnterInitPrecedure()
        end
        
    else
        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
            local directConnectIp = SetupFileConfig:getInstance():getSectionString("directConnectIp")
            local directConnectPort = SetupFileConfig:getInstance():getSectionString("directConnectPort")
            if directConnectIp ~= nil and directConnectPort ~= nil then
                RASDKInitManager.ip = directConnectIp
                RASDKInitManager.port = tonumber(directConnectPort)
                RASDKInitManager:EnterInitPrecedure()
                return
            else
                CCMessageBox(_RALang("@GetServerListError"), _RALang("@hint"))
                serverListGetError = true
            end
        else
            RALogRelease("RASDKInitManager.httpListener Get Server List Error : "..errorStr)
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.setLoadingLabel(_RALang("@GetServerListError"))
            --CCMessageBox(_RALang("@GetServerListError"), _RALang("@hint"))
            serverListGetError = true
        end
    end
end

--des: 针对IOS 平台，android 平台的覆盖安装逻辑直接在解压缩之前处理
--判断UserDefault.xml版本号v1 与包内的setup.json 里面的Version版本号v2比较，判断是否是覆盖安装，
--如果是覆盖安装，则需要删除内更新目录下的文件夹
function RASDKInitManager:judgeOverideInstall()
    local setupVersion = SetupFileConfig:getInstance():getSectionString("Version")
    local v2 = RAUpdateManager:instanceVersion(setupVersion)
    local v1 = RAUpdateManager:instanceVersion(RAUpdateManager:getCurResVersion())
    RALogRelease("RASDKInitManager:judgeOverideInstall() v1 is "..setupVersion..", v2 is "..RAUpdateManager:getCurResVersion())
    if v1.bigVersion < v2.bigVersion then
        RASDKInitManager:clearInnerUpdateFolder()
    elseif v1.bigVersion == v2.bigVersion then
        if v1.smallVersion < v2.smallVersion then
            RASDKInitManager:clearInnerUpdateFolder()
        end
    else
        assert(false,"v1.big version > v2.big version, plz check the setup.json if has change the version num")
    end
end


--des: 删除内更新目录下的文件夹，同时重置 UserDefault.xml里面的版本号为setup.json里面的Version字段v2的版本号
function RASDKInitManager:clearInnerUpdateFolder()
    --delete all addtional path folder
    local additionalPath =  RAUpdateManager:getAdditionalSearchPath()
    game_rmdir(additionalPath)
    RALogRelease("RASDKInitManager:clearInnerUpdateFolder game_rmdir")
    --set cur res version to v2
    local setupVersion = SetupFileConfig:getInstance():getSectionString("Version") 
    RAUpdateManager:setCurResVersion(setupVersion)
end

--des:处理大版本更逻辑
--param:版本url
function RASDKInitManager:dealWithVersionUpdate(url)
    CCMessageBox(_RALang("@GetDealWithVersionUpdate"), _RALang("@hint"))
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS then
        libOS:getInstance():openURLHttps(url)
    else
        local msg = {}
        msg.url = url
        RASDKUtil.sendMessageG2P("openURL", msg)
    end
end

function RASDKInitManager:Execute()
    if isInUpdate then
        RAUpdateManager:Execute()
    end

    --这里在RASDKInitManager.doneUpdate后，会isInLogin为true
    -- 然后被状态机调用
    if isInLogin then
        local RAInitPrecedure = RARequire("RAInitPrecedure")
        RAInitPrecedure.Execute()
    end

    if startCheckSDK then
        self:checkSDK(GamePrecedure:getInstance():getFrameTime())
    end

    --区服列表获取失败后的处理，每5秒重新发送一次http请求
    if serverListGetError then
        local dt = GamePrecedure:getInstance():getFrameTime()
        mFrameTime = mFrameTime + dt
        if mFrameTime > 5 then
            RASDKInitManager.getServerList(RASDKInitManager.httpListener)
            mFrameTime = 0
        end
    end
end

--desc:判断当前sdk状态是否已经完成
function RASDKInitManager:checkSDK(dt)
    checkSDKDurTime = checkSDKDurTime + dt
    if checkSDKDurTime >= checkSDKTotalTime then
        checkSDKDurTime = 0

        if checkSDKState ~= currSDKState then
            RALogRelease("RASDKInitManager:checkSDK(dt) checkSDKState "..tostring(checkSDKState).." currSDKState "..tostring(currSDKState))
            local RAGameLoadingState= RARequire("RAGameLoadingState")
            RAGameLoadingState.startSDK()--如果需要check的状态并不是当前状态，那么重新走一遍startSDK
            --post game log to server
            PostGameLog()

        end

--        if checkSDKState == ClientSDKState.SDKInit then
--            --判断当前状态是不是sdk初始化完成的状态，如果没有，再次调用sdkinit
--            if currSDKState ~= ClientSDKState.SDKInit then
--                --调用sdkinit
--                RALogRelease("RASDKInitManager:checkSDK(dt) ClientSDKState.SDKInit")
--                self.onInitSDK()
--            end
--        elseif checkSDKState == ClientSDKState.SDKLoading then
--            --判断当前状态是不是已经登录了，如果没有，再次调用sdklogin
--            if currSDKState ~= ClientSDKState.SDKLoading then
--              --调用sdklogin
--                RALogRelease("RASDKInitManager:checkSDK(dt) ClientSDKState.SDKLoading")
--              self.loginSDK()
--            end
--        end
    end
end

function RASDKInitManager:Exit()
    startCheckSDK = false
    checkSDKDurTime = 0

    if isInUpdate then
        RAUpdateManager:Exit()
    end
    local RAInitPrecedure = RARequire("RAInitPrecedure")
    RAInitPrecedure.Exit()
    isInLogin = false
end


function RASDKInitManager.getServerList(pSelector)
    --logTime
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = "RASDKInitManager.getServerList Start To getServerList" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    RALogRelease(timeStr)


    local path = "/script/serverlist";

    local oldDeviceId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.DEVICE_UID, "");
    local oldToken = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.ACCOUNT_TOKEN, "");

    local deviceId = RAPlatformUtils:getDeviceId()
    local platformId = RAPlatformUtils:getPlatform()

    local channel = RAPlatformUtils:getChannel()--ACCOUNT_CHANNEL
    if channel == nil or channel == "" then
        -- channel = "hawk"
        -- CCUserDefault:sharedUserDefault():setStringForKey(ACCOUNT_CHANNEL, channel)
    end
    local country = RAPlatformUtils:getCountry()
    local pkgVersion = RAUpdateManager:getCurPkgVersion()
    local resVersion = RAUpdateManager:getCurResVersion()
    local sdkVersion = RAPlatformUtils:getSdkVersion()
    local token = RAPlatformUtils:getToken()

    RALogRelease("RASDKInitManager.getServerList the token is "..token)

    GamePrecedure:getInstance():setUin(token)


    local tokenEncode = RAPlatformUtils:UrlEncode(token)--对param进行url编码
    RALogRelease("RASDKInitManager.getServerList The tokenEncode encode is "..tokenEncode)

    local params = string.format("platform=%s&channel=%s&country=%s&resVer=%s&pkgVer=%s&sdkVer=%s&deviceId=%s&token=%s",
        platformId, channel, country, resVersion, pkgVersion, sdkVersion, deviceId, token)

    local playerId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.PLAYER_UID, "")
    if playerId ~= "" then
        if oldDeviceId == deviceId and oldToken == token then
            local tmpParam = string.format("playerId=%s&%s", playerId, params)
            params = tmpParam
        end
    end
    RALogRelease("RASDKInitManager.getServerList params before encode is "..params)

    local md5Enc = com4loves.MD5:new()
    md5Enc:update(path, string.len(path))
    md5Enc:update(params, string.len(params))

    local md5Val = md5Enc:toString()
    md5Enc:delete()
    
    local ip = "" 

    --get the ip based on platform to avoid change on setup.json as less as possible
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        ip = SetupFileConfig:getInstance():getSectionString("ListServerIpWin32")
        RALogRelease("RASDKInitManager.getServerList -- win32 -- ip is "..ip)
    elseif CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        ip = SetupFileConfig:getInstance():getSectionString("ListServerIpAndroid")
        RALogRelease("RASDKInitManager.getServerList -- android -- ip is "..ip)
    elseif CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS then
        ip = SetupFileConfig:getInstance():getSectionString("ListServerIpIOS")
        RALogRelease("RASDKInitManager.getServerList -- ios -- ip is "..ip)
    else
        ip = SetupFileConfig:getInstance():getSectionString("ListServerIpIOS")    
        RALogRelease("RASDKInitManager.getServerList -- none platform -- ip is "..ip)
    end

    
    if ip == "" or ip == nil then
        RALogRelease("RASDKInitManager.getServerList error ip is nil ")
        local RAGameLoadingState = RARequire("RAGameLoadingState")
        RAGameLoadingState.setLoadingLabel(_RALang("@GetServerListError"))
        --CCMessageBox(_RALang("@GetServerListError"), _RALang("@hint"))
        serverListGetError = true
        return
    end
    local isIpv6 = GameCommon.isIPV6Net(ip)

    
    local paramsUrlEncode = string.format("platform=%s&channel=%s&country=%s&resVer=%s&pkgVer=%s&sdkVer=%s&deviceId=%s&token=%s",
        platformId, channel, country, resVersion, pkgVersion, sdkVersion, deviceId, tokenEncode)

    local playerId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.PLAYER_UID, "")
    if playerId ~= "" then
        if oldDeviceId == deviceId and oldToken == token then
            local tmpParam = string.format("playerId=%s&%s", playerId, paramsUrlEncode)
            paramsUrlEncode = tmpParam
        end
    end

    local url =string.format("http://%s%s?%s&crc=%s", ip, path, paramsUrlEncode, md5Val)
    RALogRelease("encoded url is :")
    RALogRelease(url, true)

    local request = CCLuaHttpRequest:create()
    request:setUrl(url);
    request:setRequestType(CCHttpRequest.kHttpPost)
    request:setResponseScriptCallback(pSelector)
    request:setTag("get_server_list")
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

function RASDKInitManager:doneUpdate()
    --done update, clean the data and restart the game.
    SetupFileConfig:getInstance():reload()
    ResourcePathConfig:getInstance():reload()
    RASearchPathManager:getInstance():reload()
--    for key, v in pairs(package.loaded) do
--        package.loaded[key] = nil
--    end
    --purge cached entry
    CCFileUtils:sharedFileUtils():purgeCachedEntries()

    if false then
        --subpass.1 reload the whole lua stack
        local RAGameLoadingState = RARequire("RAGameLoadingState")
        RAGameLoadingState.Exit()
        GamePrecedure:getInstance():resetScriptEngine()
    else
        --subpass.2 direct enter the precedure
        RASDKInitManager:EnterInitPrecedure()
    end
end


function RASDKInitManager:EnterInitPrecedure()
    RALogRelease("RASDKInitManager:EnterInitPrecedure")
    local RAGameLoadingState = RARequire("RAGameLoadingState")
    RAGameLoadingState.changeState(RAGameLoadingStatus.InitBasic)
    local RAInitPrecedure = RARequire("RAInitPrecedure")
    isInLogin = true
    RAInitPrecedure.Enter()
    
end

function RASDKInitManager:onInputboxOK(listener)

    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        local input = listener:getResultStr()
        if input ~= nil and input~= '' then
            local jsonObj = cjson.decode(input)
            if jsonObj ~= nil then
                local RAStringUtil = RARequire('RAStringUtil')
                local content = jsonObj.content or ''
                local inputTB = RAStringUtil:split(content, ',')
                local deviceId, channel = inputTB[1], inputTB[2]
                if deviceId ~= nil and deviceId ~= '' then
                    CCUserDefault:purgeSharedUserDefault()
                    os.remove(CCUserDefault:getXMLFilePath())
                    local loginCfg = RARequire('RASDKLoginConfig')
                    CCUserDefault:sharedUserDefault():setStringForKey(loginCfg.DEVICE_UID, deviceId)
                    if channel ~= nil then
                        CCUserDefault:sharedUserDefault():setStringForKey(loginCfg.ACCOUNT_CHANNEL, channel)
                    end
                    CCUserDefault:sharedUserDefault():flush()
                    local RASDKInitManager = RARequire('RASDKInitManager')
                    RASDKInitManager.getServerList(RASDKInitManager.httpListener)
                end
            end
        end
    end
    
    --listener:delete()
end


function RASDKInitManager:onInputboxCancel(listener)
     --listener:delete()
end

function RASDKInitManager:onMessageboxEnter(listener)
    local input = listener:getResultStr()
    if input ~= nil and input~= '' then
        local jsonObj = cjson.decode(input)
        if jsonObj ~= nil then
            local tag = jsonObj.tag or ''
            if tonumber(tag) == 100 then
                local RALoginManager = RARequire("RALoginManager")
                RALoginManager:connectServer()
            end
        end
    end
end


function RASDKInitManager:decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function RASDKInitManager:encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end


----------------------------------------------------------------------
----------------------------绑定账号相关------------------------------
----------------------------------------------------------------------

--url : request url
--key : request params key
--platformType : request params platformType
function RASDKInitManager.bindAccount(url, key, platformType)
    --开始玩一个新账号
    RALogRelease("RASDKInitManager.createGuest")

    local msg = {}
    msg.url = url or ""
    msg.key = key or ""
    msg.value = platformType or ""

    RASDKUtil.sendMessageG2P("bindAccount", msg)
end

--回调
function RASDKInitManager:onResultBindAccount(listener)
    local data = listener:getResultStr()
    RALogRelease("RASDKInitManager:onResultBindAccounts is data :"..data)

    if data ~= nil and data~= '' then
        local resutJson = cjson.decode(data)
        if resutJson then
            local RASettingAccountBindPage = RARequire("RASettingAccountBindPage")
            RASettingAccountBindPage:refreshBindAccountData(resutJson)
        else
            RALogRelease("RASDKInitManager:onResultBindAccounts The Result String can not decoded!")
        end
    else
        RALogRelease("RASDKInitManager:onResultBindAccounts There is not ResultStrint")    
    end
end

return RASDKInitManager

--endregion
    
