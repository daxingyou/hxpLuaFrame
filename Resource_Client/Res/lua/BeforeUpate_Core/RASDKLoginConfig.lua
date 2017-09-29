--region RASDKLoginConfig.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASDKLoginConfig = {

DEVICE_UID = "RA_LocalDeviceId_Tag",
ACCOUNT_TOKEN = "account_token",
PLAYER_UID = "RA_PlayerId_Tag",
ACCOUNT_PUID = "RA_Puid_Tag",
PLAYER_LOGIN_TIMESTAMP = "RA_Player_Login_TimeStamp",
SERVERLIST_IP = "ra-ops.com4loves.com",
SERVER_ID = "server_id",
SERVER_IP = "server_ip",
SERVER_PORT = "server_port",
DEF_SERVER_PORT = 9595,
DEF_SERVER_IP = "10.0.1.131",	
DEF_SERVER_ID = 's1',
ACCOUNT_CHANNEL = "account_channel",
GameLogPostLins = 100, --game.log 一次上传条数
ErrorLogPostInv = 1, --报错日志发送频率
ErrorLogRepeatNum = 5, --相同报错日志重复发送最大次数    
ErrorLogReSendCount = 1, --错误日志传输失败重传次数
errorLogUrl = SetupFileConfig:getInstance():getSectionString("errorLogPostIp")..":"..SetupFileConfig:getInstance():getSectionString("errorLogPostPort"),
gameLogPostUrl = SetupFileConfig:getInstance():getSectionString("gameLogPostIp")..":"..SetupFileConfig:getInstance():getSectionString("gameLogPostPort"),

--     SDKInit = 1,    --SDK init
--    HotUpdate = 2,  --hot update
--    InitBasic = 3,  --init basic environment
--    LoginServer = 4,--login server
--    LoginFinish = 5,--login finish
 scaleBarPercent = {
    [1] = {
        startPer = 0,
        endPer = 0.2,
    },
    [2] = {
        startPer = 0.2,
        endPer = 0.5,
    },
    [3] = {
        startPer = 0.5,
        endPer = 0.95,
    },
    [4] = {
        startPer = 0.95,
        endPer = 1.0,
    },
    [5] = {
        startPer = 1.0,
        endPer = 1.0,
    }
 },
OpenLogoMovie = true,--是否播放logomp4
 loadingStatelabel = {
    [1] = "@LoadingStateSDKInit",   --正在连接...
    [2] = "@LoadingStateHotUpdate", --正在检查资源...
    [3] = "@LoadingStateInitBasic", --正在初始化环境
    [4] = "@LoadingStateLoginServer",--正在连接服务器
    [5] = "@LoadingStateLoginFinish"--连接服务器成功
 },

}
return RASDKLoginConfig
--endregion
