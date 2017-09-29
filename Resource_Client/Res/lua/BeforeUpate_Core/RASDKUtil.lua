--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASDKUtil = {}

function RASDKUtil.sendMessageG2P(msg, pTable)
	local ret=nil
	if pTable then
		ret = PlatformSDK:getInstance():sendMessageG2P(msg,cjson.encode(pTable))
	else
		ret = PlatformSDK:getInstance():sendMessageG2P(msg,'{}')
	end
	
	if ret and ret ~= "" then
	    return cjson.decode(ret)
	end
	return {}
end

function RASDKUtil.initSDK()
    PlatformSDK:getInstance():init()
end

function RASDKUtil.isSDKInited()
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        return true;
    end

    local inited = RASDKUtil.sendMessageG2P("isSDKInited").status
    if inited == nil then return false end
    if inited == true then return true end
    return false
end

function RASDKUtil.isSDKLogin()
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        return false;
    end
    local isLogin = RASDKUtil.sendMessageG2P("getLogined").logined
    --only return true when isLogin return true, else like nil or false return false
    if isLogin == nil then return false end
    if isLogin == true then return true end
    return false
end



return RASDKUtil
--endregion
