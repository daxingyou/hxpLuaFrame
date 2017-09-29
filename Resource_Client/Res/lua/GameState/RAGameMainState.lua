
local RASDKLoginListener = {}
local RAGameMainState = {}
package.loaded[...] = RAGameMainState

local RARootManager = RARequire("RARootManager")
local HP_pb = RARequire('HP_pb')
local SysProtocol_pb = RARequire('SysProtocol_pb')
local RANetUtil = RARequire('RANetUtil')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RANetManager = RARequire("RANetManager")
local RAGameConfig = RARequire("RAGameConfig")

local heartBeatTime = 0
local HeartBeatDuration = 20
local backGroundTimeFlag = "enterBackGroundTime"

RAGameMainState.SDKListener = nil
 
local packetManagetHandler = {
    onConnectionSuccess = function ()
        --断线重连成功之后，请求登陆消息
        RANetManager:setReconect(false)
        RAGameMainState.resetDataOnly()

        RANetManager.isReconectSuccess = true

        local RALoginManager = RARequire("RALoginManager")
        RALoginManager.sendLoginCmd()
    end,
    onDisConnection = function()
        --local errorStr = _RALang('@ServerDisConnectInReconnect')
        --RARootManager.showConfirmMsg(errorStr)
        RANetManager:setReconect(true)
    end,
    onConnectionError = function()
        --local errorStr = _RALang('@ServerDisConnectInReconnect')
        --RARootManager.showConfirmMsg(errorStr)
        RANetManager:setReconect(true)
    end
}


RAGameMainState.libOSListenerClass = {
    onPlayMovieEndMessage = function()
        RALogRelease("begin onPlayMovieEndMessage  RAGameMainState.libOSListener ")
        local RecordManager = RARequire("RecordManager")
        local RecordDot_pb = RARequire("RecordDot_pb")
        RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_MOVIE_END)--打点
        RAGameMainState.EnterCommonScene()
        RALogRelease("end onPlayMovieEndMessage  RAGameMainState.libOSListener ")
    end
}
RAGameMainState.libOSListener = nil


function RAGameMainState.Enter()
	CCLuaLog("Lua: RAGameMainState:Enter")
    --step.1 init the node first and scene
    GamePrecedure:getInstance():setIsInLoadingScene(false)
    RARootManager.Init()

    local RAGameConfig = RARequire("RAGameConfig")
    if RAGameConfig.BattleDebug == 1 then 
        RAGameMainState.EnterCommonScene()
    else
        local RAGuideManager = RARequire("RAGuideManager")
        local RAGuideConfig = RARequire("RAGuideConfig")
        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS and RAGuideManager.currentGuildId <=0 and RAGuideConfig.playGuideStartMovie then
            --播放视频
            RAGameMainState.libOSListener = libOSScriptListener:new(RAGameMainState.libOSListenerClass)
            RAGameMainState.libOSListener:setRegister()
            local logoMp4Path = CCFileUtils:sharedFileUtils():fullPathForFilename("GuideStart.mp4")
            local skipPath = CCFileUtils:sharedFileUtils():fullPathForFilename("Skip.pmg")
            libOS:getInstance():setIsInPlayMovie(true);
            libOS:getInstance():playMovie(logoMp4Path, skipPath)
            local RecordManager = RARequire("RecordManager")
            local RecordDot_pb = RARequire("RecordDot_pb")
            RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_MOVIE_START)--打点
        elseif CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID and RAGuideManager.currentGuildId <=0 and RAGuideConfig.playGuideStartMovie then
            --播放视频
            local RASDKUtil = RARequire("RASDKUtil")
            RASDKUtil.sendMessageG2P("playMovie", {fileName = "GuideStart",needSkip = true})
            local RecordManager = RARequire("RecordManager")
            local RecordDot_pb = RARequire("RecordDot_pb")
            RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_MOVIE_START)--打点
        else
            RAGameMainState.EnterCommonScene()
        end
    end

    --添加每日通知
    local RANotificationManager = RARequire("RANotificationManager")
    RANotificationManager.addAllDailyNotification()

    local RAConfirmManager=RARequire("RAConfirmManager")
    RAConfirmManager:setComfirmData()

    RAGameMainState.packetManagerListener = ScriptPacketManagerListener:new(packetManagetHandler)
    RAGameMainState.SDKListener = platformSDKListener:new(RASDKLoginListener)
end

function RAGameMainState.EnterCommonScene()

    local RAGameConfig = RARequire("RAGameConfig")
    if RAGameConfig.BattleDebug == 1 then 
        RARootManager.ChangeScene(SceneTypeList.BattleScene, true)
    else
        local RAGuideManager = RARequire("RAGuideManager")
        local RAMissionFragmentManager = RARequire("RAMissionFragmentManager")
        if RAGameConfig.SwitchBarrierGuide and RAGameConfig.SwitchBarrierGuide == 1 and RAMissionFragmentManager:isInGuide() and RAGuideManager.isInGuide() and RAGuideManager.currentGuildId <=0 then
            RAMissionFragmentManager:start()--新手关卡引导开启，会先判断是否要进入关卡，在关卡内部去判断引导哪一关
        elseif RAGuideManager.isInGuide() and RAGuideManager.guideInWorld() then--判断是否需要直接去城外
            RARootManager.ChangeScene(SceneTypeList.WorldScene, true)
        else
            RARootManager.ChangeScene(SceneTypeList.CityScene, true)
        end
    end

    --只要进入了场景，则删除掉libOSListener
    if RAGameMainState.libOSListener then
        RALogRelease("Delete RAGameMainState.libOSListener ")
        RAGameMainState.libOSListener:delete()
        RAGameMainState.libOSListener = nil
    end

end

function RAGameMainState.Execute()
    local delta = GamePrecedure:getInstance():getFrameTime()
	RARootManager.Execute()
    RAGameMainState._HeartBeat(delta)
    RAPlayerInfoManager.UpdateServerTime(delta)
    RANetManager:Execute(delta)
end

function RAGameMainState.Exit()
	CCLuaLog("RAGameMainState:Exit end")
    RARootManager.Exit()

    if RAGameMainState.packetManagerListener then
        RAGameMainState.packetManagerListener:delete()
        RAGameMainState.packetManagerListener = nil
    end

    if RAGameMainState.libOSListener then
        RAGameMainState.libOSListener:delete()
        RAGameMainState.libOSListener = nil
    end

    --数据删除
    RAGameMainState.reset()
    if RAGameMainState.SDKListener then
        RAGameMainState.SDKListener:delete()
        RAGameMainState.SDKListener = nil
    end


end

function RAGameMainState.enterBackGround()
    local backGroundTime = os.time()
    CCUserDefault:sharedUserDefault():setIntegerForKey(backGroundTimeFlag, backGroundTime);
end

function RAGameMainState.enterForeground()
    local curTime = os.time()
    
    local lastOsTimeStamp = CCUserDefault:sharedUserDefault():getIntegerForKey(backGroundTimeFlag, curTime)
    --如果切前台的时间超过切后台的时间60s，则切换到登陆页面，重新走登陆流程，否则，则只是发送心跳包，同步时间    
    -- 新增判断，非Debug状态才会重连……防止调试过程中重新连接
    if curTime - lastOsTimeStamp > 60 and COCOS2D_DEBUG ~= 1 then
        local RALoginManager = RARequire("RALoginManager")
        RALoginManager:goLoginAgain()
    else
        local msg = SysProtocol_pb.HPHeartBeat()
        msg.timeStamp = 1
        RANetUtil:sendPacket(HP_pb.HEART_BEAT, msg, {waitingTime = 0, retOpcode = HP_pb.HEART_BEAT})
        heartBeatTime = 0
        MessageManager.sendMessage(MessageDef_MainState.EnterForeground)
    end
end


function RAGameMainState._HeartBeat(delta)
    if heartBeatTime > HeartBeatDuration then
        local msg = SysProtocol_pb.HPHeartBeat()
        msg.timeStamp = 1
        RANetUtil:sendPacket(HP_pb.HEART_BEAT, msg, {waitingTime = 0, retOpcode = HP_pb.HEART_BEAT})
        heartBeatTime = 0
    else
        heartBeatTime = heartBeatTime + delta
    end
end

--切换账号，或者是离开GameMainState的时候，需要重置缓存的UI和内存数据
function RAGameMainState.reset()
    local common = RARequire("common")
    common:log("RAGameMainState.reset()")
    common:reset()
    RARequire("RANetManager"):reset()
    RARequire("RACoreDataManager"):reset()
    RARequire("RAScienceManager"):reset()
    RARequire("RAMailManager"):reset()
    RARequire("RAChatManager"):reset()
    RARequire("RAHospitalManager"):reset()
    RARequire("RAPackageManager"):reset()
    RARequire("RAStoreManager"):reset()
    RARequire("RAQueueManager"):reset()
    RARequire("RABuildManager"):reset()
    RARequire("RAWorldManager"):reset()
    RARequire("RAPlayerInfoManager"):reset()
    RARequire("RATalentManager"):reset()
    RARequire("RATaskManager"):reset()
    RARequire("RAGlobalListener"):reset()
    RARequire("RABuffManager"):reset()
    RARequire("RAGuideManager"):reset()
    RARequire("RAPlayerEffect"):reset()
    RARequire("RAStringUtil"):reset()
    RARequire("RARadarManage"):reset()
    RARequire("RACommandManage"):reset()
    RARequire("RAPrisonDataManage"):reset()
    RARequire("RAAllianceManager"):reset()
    RARequire("RATreasureBoxManager"):reset()
    RARequire("RAPushRemindPageManager"):reset()
    RARequire("RAConfirmManager"):reset()
    RARequire("RADailyTaskActivityManager"):reset()
    RARequire("RANewAllianceWarManager"):reset()
    RARequire("RABroadcastPage"):reset()
    RARequire("RAEquipManager"):reset()
    RARequire('RATerritoryDataManager'):reset()
    RARequire('RALordUpgradeManager'):reset()
    RARequire('RADungeonManager'):reset()
    RARequire('RAMissionFragmentManager'):reset()
end

--当触发断线重连的时候，只做重置同步数据的操作，不重置UI及其他多余的操作
function RAGameMainState.resetDataOnly()
    RALogRelease("RAGameMainState.resetDataOnly()")
    RARequire("RANetManager"):reset()
    RARequire("RACoreDataManager"):reset()
    --断线重连之后会触发重连刷新
    MessageManager.sendMessage(MessageDef_MainState.ReConnectRefresh)
end

-------------------------------------------
--SDK相关
function RASDKLoginListener:onSDKLogOutSuccess(listener)

    --step.1 disconnect server
    local RALoginManager = RARequire("RALoginManager")
    RALoginManager:disconnectServer()
    --step.2 clear user default
    local RASettingManager = RARequire("RASettingManager")
    RASettingManager:clearUserDefault()
    --step.3 call switch user sdk api
    local RAGameLoadingState = RARequire("RAGameLoadingState")
    --step.4 go to the loading state
    return GameStateMachine.ChangeState(RAGameLoadingState)

end

function RASDKLoginListener:onSDKLogOutFailed(listener)
end

--Android 视频播放完毕后监听
function RASDKLoginListener:onPlayMovieEnd(listener)
    local fileName = listener:getResultStr()
    RALogRelease("RASDKLoginListener:onPlayMovieEnd is fileName :"..fileName)
    if fileName ~= nil and fileName~= '' then
        if fileName == "GuideStart" then
            local RecordManager = RARequire("RecordManager")
            local RecordDot_pb = RARequire("RecordDot_pb")
            RecordManager.recordNoviceGuide(RecordDot_pb.NOVICE_MOVIE_END)--打点
            RAGameMainState.EnterCommonScene()
        elseif fileName == "loadBattle" then --战斗视频回调
                 
        end
    end
end


--recieve the win32 key hook to mimic some GM command or message related
local isDebugVisible = false
local isSetOffset = true
local isHudVisible = false
local isShowBigCell = false
function g_RAKeyHookClick(msg)
    if msg == "G" then
        RARootManager.OpenPage("RAGMPage")
    elseif msg == "T" then
        CCTextureCache:sharedTextureCache():dumpCachedTextureInfo() 
    elseif msg == 'Q' then
        local RALoginManager = RARequire("RALoginManager")
        RALoginManager:goLoginAgain()
    elseif msg == 'Y' then
        --跳过新手
        local RAGuideManager = RARequire("RAGuideManager")
        RAGuideManager.jumpAllGuide()
        RARootManager.RemoveCoverPage()
        RARootManager.RemoveGuidePage()
        RARequire("MessageDefine")
        RARequire("MessageManager")
        local RAGuideConfig=RARequire("RAGuideConfig")
        local guide_conf=RARequire("guide_conf")
        local constGuideInfo=guide_conf[RAGuideConfig.showAllMainUI]
        MessageManager.sendMessage(MessageDef_Guide.MSG_Guide, {guideInfo = constGuideInfo})
    else
        if RARootManager.GetIsInBattle() then 
            if msg == "R" then
                RAUnload('TestData')
                RARequire('RABattleScene'):doFightTest()
            elseif msg == "F" then
                RARootManager.OpenPage("RAFightGMPage")
            elseif msg == "V" then 
                RARequire('RABattleScene'):showBlockLayer()
            elseif msg == "A" then 
                RARequire('RABattleScene'):addScale()
            elseif msg == "S" then 
                RARequire('RABattleScene'):subScale()
            elseif msg == "1" then 
                local scale = CCDirector:sharedDirector():getDeltaTimeScale()
                scale = scale * 0.5
                CCDirector:sharedDirector():setDeltaTimeScale(scale)
            elseif msg == "2" then 
                local scale = CCDirector:sharedDirector():getDeltaTimeScale()
                scale = scale * 2
                CCDirector:sharedDirector():setDeltaTimeScale(scale)
            elseif msg == "3" then 
                RARequire('RABattleSceneManager'):setTouchAttackDebug()
            elseif msg == "D" then 
                isDebugVisible = not isDebugVisible
                RARequire('RABattleSceneManager'):setAllUnitsDebugNodeVisible(isDebugVisible)
            elseif msg == "O" then 
                isSetOffset = not isSetOffset
                RARequire('RABattleScene'):isSetOffset(isSetOffset)
            elseif msg == "H" then 
                isHudVisible = not isHudVisible
                RARequire('RABattleSceneManager'):setAllUnitsHudNodeVisible(isHudVisible)
            elseif msg == "C" then
                isShowBigCell = not isShowBigCell
                RARequire('RABattleScene').mDebugLayer:setVisible(isShowBigCell)
            end
        end
    end
end


function RASDKLoginListener:onVideoEvent(listener)

    RARequire("MessageDefine")
    RARequire("MessageManager")
    local eventType = cjson.decode(listener:getResultStr()).status
    eventType=tonumber(eventType)

    local data={}
    data.eventType=eventType
    CCLuaLog("videoPlayer eventCallBack=================="..eventType)
    if eventType==PLAYING then
        MessageManager.sendMessage(MessageDef_Video.Playing,data)
    elseif eventType==PAUSED then
        MessageManager.sendMessage(MessageDef_Video.Paused,data)
    elseif eventType==STOPPED then
        MessageManager.sendMessage(MessageDef_Video.Stopped,data)
    elseif eventType==COMPLETED then
        MessageManager.sendMessage(MessageDef_Video.Completed,data)
    end 
end


----------------------------------------------------------------------
----------------------------begin 绑定账号相关 begin------------------
----------------------------------------------------------------------

--绑定统一回调
function RASDKLoginListener:onResultBindAccount(listener)
    local resutJsonStr = listener:getResultStr()
    RALogRelease("RASDKLoginListener:refreshBindAccountData is data :"..resutJsonStr)

    if resutJsonStr ~= nil and resutJsonStr~= '' then
        local jsonDataObj = cjson.decode(resutJsonStr)  
        local url = jsonDataObj.url or ""
        if url == RAGameConfig.BINDACCOUNT_TYPE.createGuest then
            RALogRelease("RASDKLoginListener:onResultBindAccount is createGuest type") 
            local RASDKInitManager = RARequire("RASDKInitManager")
            RASDKInitManager.getServerList(RASDKInitManager.httpListener)
        elseif url == RAGameConfig.BINDACCOUNT_TYPE.unBind  --绑定账号，解除绑定，切换绑定账号 都需要重新拉去一遍绑定列表
            or url == RAGameConfig.BINDACCOUNT_TYPE.bindFb 
            or url == RAGameConfig.BINDACCOUNT_TYPE.bindGooglePlay
            or url == RAGameConfig.BINDACCOUNT_TYPE.switchFb 
            or url == RAGameConfig.BINDACCOUNT_TYPE.switchGooglePlay  then
            local isSuccess = jsonDataObj.resulData or ""
            RALogRelease("RASDKLoginListener:onResultBindAccount url is "..url.." type value :"..isSuccess)
            
            local url = RAGameConfig.BINDACCOUNT_TYPE.getBindlist
            local RASDKInitManager = RARequire("RASDKInitManager")
            RASDKInitManager.bindAccount(url)
        else
            RALogRelease("RASDKLoginListener:onResultBindAccount is orther type") 
            MessageManager.sendMessage(MessageDef_BINDACCOUNT.MSG_Bind_Data_Refresh,{data = resutJsonStr})
        end
    else
        RALogRelease("RASDKLoginListener:onResultBindAccount resutJsonStr is null")    
    end
end

----------------------------------------------------------------------
----------------------------end 绑定账号相关 end----------------------
----------------------------------------------------------------------


