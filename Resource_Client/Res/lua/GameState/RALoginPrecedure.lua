--region RALoginPrecedure.lua
--Date
--此文件由[BabeLua]插件自动生成
local RALoginPrecedure = {}
RARequire("MessageDefine")
RARequire("MessageManager")
--平台sdk 回调接口
RALoginPrecedure.platformSDKListener = nil
local mLoginConnectFail = false
local mFrameTime = 0 
local mLoginFailTime = 0
RALoginPrecedure.packetManagetHandler = {
    onConnectionSuccess = function ()

        --logTime
        local Utilitys = RARequire("Utilitys")
        Utilitys.LogCurTime("RALoginPrecedure.packetManagetHandler Connnect To Server Success")

        mLoginConnectFail = false
        local RALoginManager = RARequire("RALoginManager")
        RALoginManager.sendLoginCmd()
    end,
    onConnection = function()
    end,
    onDisConnection = function()
        local errorStr = _RALang("@ServerDisConnectSession")
        mLoginFailTime = mLoginFailTime +1
        if mLoginFailTime % 5 == 4 then
            CCMessageBox(errorStr,_RALang("@hint"))
        end
        mLoginConnectFail = true
--        local RASDKUtil = RARequire("RASDKUtil")
--        RASDKUtil.sendMessageG2P("showMessagebox", {
--                tag = 100,
--                msg = errorStr,
--                title = _RALang("@hint")
--        })

    end,
    onConnectionError = function()
        --logTime
        local Utilitys = RARequire("Utilitys")
        Utilitys.LogCurTime("RALoginPrecedure.packetManagetHandler Connnect To Server Failed")

        local errorStr = _RALang("@ServerCannotConnect")
        --local RARootManager = RARequire("RARootManager")
        --RARootManager.showConfirmMsg(errorStr)
        mLoginFailTime = mLoginFailTime +1
        if mLoginFailTime % 5 == 4 then
            CCMessageBox(errorStr,_RALang("@hint"))
        end
        mLoginConnectFail = true
--        local RASDKUtil = RARequire("RASDKUtil")
--        RASDKUtil.sendMessageG2P("showMessagebox", {
--                tag = 100,
--                msg = errorStr,
--                title = _RALang("@hint")
--        })

    end
}


RALoginPrecedure.Win32InputListener =
{
    onInputboxOK = function (_self, listener)
        local input = listener:getResultStr()
        if input ~= nil and input~= '' then
            local jsonObj = cjson.decode(input)
            if jsonObj ~= nil then
                local RAStringUtil = RARequire('RAStringUtil')
                local content = jsonObj.content or ''
                local inputTB = RAStringUtil:split(content, ';')
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
        listener:delete()
    end,
    onInputboxCancel = function (listener)
        listener:delete()
    end
}


local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_LOGIN.MSG_LoginSuccess then
            local mainState = RARequire("RAGameMainState")
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.changeState(RAGameLoadingStatus.LoginFinish)

            -- 真正进入游戏主界面
            return GameStateMachine.ChangeState(mainState)
    end
end

function RALoginPrecedure:Enter()
    --logTime
    local Utilitys = RARequire("Utilitys")
    Utilitys.LogCurTime("RALoginPrecedure:Enter Enter To RALoginPrecedure")

    self:addHandler();
    mLoginFailTime = 0
    --链接服务器，如果成功则在回调中直接发送登陆请求  todo delete  不向服务器请求
    -- local RALoginManager = RARequire("RALoginManager")
    -- RALoginManager:connectServer()

    --不向服务器请求 直接进入游戏
    self:enterGameDirect()
end

function RALoginPrecedure:Execute()
    if mLoginConnectFail == true then
        local dt = GamePrecedure:getInstance():getFrameTime()
        mFrameTime = mFrameTime + dt 
        if mFrameTime > 5 * mLoginFailTime then
            local RALoginManager = RARequire("RALoginManager")
            RALoginManager:connectServer()
            mFrameTime = 0 
        end
    end
end

function RALoginPrecedure:Exit()
    self:removeHandler();
    mLoginConnectFail = false
    mFrameTime = 0 
end

--function RALoginPrecedure:onLogin()
--    --链接服务器，如果成功则在回调中直接发送登陆请求
--    RALoginManager:connectServer()
--end

--function RALoginPrecedure:onChoose()
--    platformSDKListener:new(self.Win32InputListener)
--    Utilitys.sendMessageG2P('showInputbox')
--end

--function RALoginPrecedure:onDirectEnter()    
--    GameStateMachine.ChangeState(RARequire("RAGameMainState"))
--    CCLuaLog("RALoginPrecedure:onDirectEnter")
--end

function RALoginPrecedure:addHandler()
    RALoginPrecedure.platformSDKListener = platformSDKListener:new(self)--注册SDK回调处理tabel
    RALoginPrecedure.packetManagerListener = ScriptPacketManagerListener:new(RALoginPrecedure.packetManagetHandler);--添加网络回调
    MessageManager.registerMessageHandler(MessageDef_LOGIN.MSG_LoginSuccess, OnReceiveMessage)
end

function RALoginPrecedure:enterGameDirect()
    local mainState = RARequire("RAGameMainState")
    local RAGameLoadingState = RARequire("RAGameLoadingState")
    RAGameLoadingState.changeState(RAGameLoadingStatus.LoginFinish)

    -- 真正进入游戏主界面
    return GameStateMachine.ChangeState(mainState)
end

function RALoginPrecedure:removeHandler()
    
    if RALoginPrecedure.packetManagerListener then
        RALoginPrecedure.packetManagerListener:delete()
        RALoginPrecedure.packetManagerListener = nil
    end
     --注销sdk回调处理
    if RALoginPrecedure.platformSDKListener then
        RALoginPrecedure.platformSDKListener:delete()
        RALoginPrecedure.platformSDKListener = nil
    end

    MessageManager.removeMessageHandler(MessageDef_LOGIN.MSG_LoginSuccess, OnReceiveMessage)
end


function RALoginPrecedure:onSDKSwitchUsersSuccess(listener)
    --SDK切换账号成功
    CCLuaLog("RALoginPrecedure:onSDKSwitchUsersSuccess")
end


return RALoginPrecedure
--endregion
