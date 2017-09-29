--region RALoginManager.lua
--Date
--此文件由[BabeLua]插件自动生成
local RALoginManager = {isInLogin = false}

local Login_pb = RARequire("Login_pb")

function RALoginManager:reconnectServer()
    PacketManager:getInstance():reconnect();
end

function RALoginManager:disconnectServer()
    PacketManager:getInstance():disconnect();
end


function RALoginManager:goLoginAgain()
    RALoginManager:disconnectServer()
    local RAGameLoadingState = RARequire("RAGameLoadingState")

    -- 重连发送消息
    MessageManager.sendMessage(MessageDef_MainState.ReloginRefresh)
    
    return GameStateMachine.ChangeState(RAGameLoadingState)
end

function RALoginManager:switchUser()
     --step.1 disconnect server
    local RALoginManager = RARequire("RALoginManager")
    RALoginManager:disconnectServer()
    --step.2 clear user default
    local RASettingManager = RARequire("RASettingManager")
    RASettingManager:clearUserDefault()
    --step.3 call switch user sdk api
    local RAGameLoadingState = RARequire("RAGameLoadingState")
    RAGameLoadingState.isSwitchUser = true
    --step.4 go to the loading state
    return GameStateMachine.ChangeState(RAGameLoadingState)
end

function RALoginManager:connectServer()
    --logTime
    local Utilitys = RARequire("Utilitys")
    Utilitys.LogCurTime("RALoginManager:connectServer Connect To Server")

    --如果已经链接上服务器了，不需要重新再连接
    if PacketManager:getInstance():isConnected() then return false end    
    local RASDKInitManager = RARequire("RASDKInitManager")
    PacketManager:getInstance():connect(RASDKInitManager.ip, RASDKInitManager.port);
    return true
end


function RALoginManager.sendLoginCmd()
    --logTime
    local Utilitys = RARequire("Utilitys")
    Utilitys.LogCurTime("RALoginManager.sendLoginCmd Start To Send LoginCmd")


    --发送登陆协议
    local RASDKInitManager = RARequire('RASDKInitManager')
    local RASDKLoginConfig = RARequire("RASDKLoginConfig")
    local cmd = Login_pb.HPLogin()

    local playerId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.PLAYER_UID, "")
    if playerId~=nil and playerId ~= "" then
        cmd.playerId = playerId
    end
    local puid = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.ACCOUNT_PUID, "")
    if puid ~= nil and puid ~= "" then
        cmd.puid = puid
    end
    
    local token = RAPlatformUtils:getToken()
    if token ~= nil and token ~= "" then
        cmd.token = RAPlatformUtils:getToken()
    end
    cmd.platform = RAPlatformUtils:getPlatform()
    cmd.channel = RAPlatformUtils:getChannel()
    cmd.country = RAPlatformUtils:getCountry()
    cmd.deviceId = RAPlatformUtils:getDeviceId()
    local RAStringUtil = RARequire("RAStringUtil")
    cmd.lang = RAStringUtil:getCurrentLang()
    cmd.phoneInfo = RASDKInitManager.getDeviceModel()
    cmd.version = RAPlatformUtils:getVersion()

    local pushDeviceId = RAPlatformUtils:getPushDeviceToken(1)   --默认获取的是 信鸽的 token
    local pfStr = SetupFileConfig:getInstance():getSectionString("pushChannel")
    if pfStr == 'getui' then
        pushDeviceId = RAPlatformUtils:getPushDeviceToken(2)     --个推 的 token
    end
    if pushDeviceId and pushDeviceId ~= "" then
        --local pfStr = SetupFileConfig:getInstance():getSectionString("pushChannel")
        local pushTable = {pf=pfStr,pushDeviceId=pushDeviceId,phoneType=cmd.platform}
        local pushData = cjson.encode(pushTable)
        cmd.pushInfo = pushData
    end

    local RANetUtil = RARequire("RANetUtil")
    RANetUtil:sendPacket(HP_pb.LOGIN_C, cmd)
end

function RALoginManager:onReceivePacket(handler)
    local RASDKLoginConfig = RARequire("RASDKLoginConfig")
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.LOGIN_S then
        --logTime
        local Utilitys = RARequire("Utilitys")
        Utilitys.LogCurTime("RALoginManager:onReceivePacket Receive LoginCmd")

        local msg = Login_pb.HPLoginRet()
        msg:ParseFromString(buffer)
        local errCode = msg.errCode
        if errCode == 0 then
            CCLuaLog("Receive Packet of pbCode ".. pbCode.." Success")
            local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
            
            if msg:HasField("puid") then
                local puid = msg.puid
                CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.ACCOUNT_PUID, puid)
            end
            if msg:HasField("playerId") then
                local playerId = msg.playerId
                CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.PLAYER_UID, playerId)
                RAPlayerInfoManager.setPlayerId(playerId)
            end
            if msg:HasField("timeStamp") then
                local timeStamp = msg.timeStamp
                RAPlayerInfoManager.SetServerTime(timeStamp)
                CCUserDefault:sharedUserDefault():setIntegerForKey(RASDKLoginConfig.PLAYER_LOGIN_TIMESTAMP, timeStamp);
            end
            if msg:HasField('serverOpenTime') then
                RAPlayerInfoManager.setServerOpenTime(msg.serverOpenTime)
            end
        else
            local Status_pb = RARequire("Status_pb")
            if errCode == Status_pb.DEVICE_NOT_ACTIVE then
                --if not active, jump to RAVerifyPage
                local RAVerifyPage = RARequire("RAVerifyPage")
                RAVerifyPage:Enter()
            else
                local RAStringUtil = RARequire("RAStringUtil")
                local errorMsg = RAStringUtil:getErrorString(errCode)
                CCMessageBox(errorMsg,_RALang("@hint"))
            end

--            local RARootManager = RARequire("RARootManager")
--            RARootManager.showErrorCode(errCode)
        end
    end
end

return RALoginManager
--endregion
