--region RAGameLoadingState.lua
--Date  2016/6/3
--Author zhenhui
--[[
    整合以前的两个登陆页面到一个GameLoadingState中来，step.3 之前加载的数据需要很小心，之后加载的数据尽量分帧加载
    登陆页面修改为五个步骤
    1. SDK初始化状态
        1.)加载setup.json 搜索路径
        2.)请求区服列表
        3.）判断是否需要内更新，来判断是否进入step.2内更新或者直接进入step.3 初始化状态
    2. RAUpdateManager 内更新状态
    3. RAInitPrecedure  初始化状态
    4. RALoginPrecedure 登陆请求状态
    5. 完成状态，数据清理等
]]--
local RAGameLoadingState = {
    --平台sdk 回调接口
    platformSDKListener = nil,
    isSwitchUser = false,
    isBeginNewGame = false,
    isSwitchLang = false,

    curState = 0
}

local RASDKLoginConfig = RARequire("RASDKLoginConfig")

RAGameLoadingStatus = {
    SDKInit = 1,    --SDK init
    HotUpdate = 2,  --hot update
    InitBasic = 3,  --init basic environment
    LoginServer = 4,--login server
    LoginFinish = 5,--login finish
    max = 6
}

local RASDKInitManager = RARequire("RASDKInitManager")
local mFirstUpdate = true
local mSDkInitTime = 4
local mCurSDKTime = 0
local mScaleSpeed = 1 / 5
local mLoadingBar = nil
local mLoadingLabel = nil

function RAGameLoadingState.loadCCBFile(filename,ownner)
    local ccbfile = CCBFile:create()
    ccbfile:retain()
    ccbfile:setCCBFileName(filename)
    ccbfile:setInPool(false)
    ccbfile:registerFunctionHandler(ownner)
    ccbfile:load()
    ownner.ccbfile = ccbfile
    return ccbfile
end

function RAGameLoadingState.unLoadCCBFile(ownner)
	if ownner and ownner.ccbfile then
		ownner.ccbfile:removeFromParentAndCleanup(true)
		ownner.ccbfile:release()
		ownner.ccbfile = nil
	end
end

function RAGameLoadingState.Enter()
    --init the loadingPage
    RALogRelease("RAGameLoadingState.Enter()")

    --loading 页面的背景音乐播放
    local BackgroundMusic = VaribleManager:getInstance():getSetting("LoadingMusic")
    SoundManager:getInstance():playMusic(BackgroundMusic, true)--RAGameConfig.BackgroundMusic

    --logTime
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = "RAGameLoadingState.Enter" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    RALogRelease(timeStr)
    
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesNameWithFile("Res/Resource/ImageSetFile/Loading.plist");

    --RARootManager:Init()
    GamePrecedure:getInstance():setIsInLoadingScene(true)
    mCurSDKTime = 0
    RAGameLoadingState.curState = 0
    local RAStringUtil = RARequire("RAStringUtil")
    RAStringUtil:setLanguage()


    --CCDirector:sharedDirector():setDisplayStats(true)
    

    -- local RAGameConfig = RARequire("RAGameConfig")
    -- if RAGameConfig.BattleDebug == 1 then 
    --     ccbfile = RAGameLoadingState.loadCCBFile("RALoadingPage.ccbi",RAGameLoadingState);
    -- else
        ccbfile = RAGameLoadingState.loadCCBFile("RALoadingPage.ccbi",RAGameLoadingState);
    -- end
    --RAGameLoadingState.ccbfile = ccbfile
    local mScene = CCScene:create()
    mScene:addChild(ccbfile);
    ccbfile:getCCNodeFromCCB("mLoadingBarNode"):setVisible(true)
    RAGameLoadingState.ccbfile:getCCLabelTTFFromCCB("mLoadingNum"):setVisible(false)
    mLoadingBar = ccbfile:getCCScale9SpriteFromCCB("mLoadingBar")
    mLoadingLabel = ccbfile:getCCLabelTTFFromCCB("mLoadingLabel")
    
    ccbfile:getCCNodeFromCCB("mLogin"):setVisible(false)
    ccbfile:getCCNodeFromCCB("mChooseBtnNode"):setVisible(false)
    
--	 local obj3d = CCEntity3D:create('3d/use.c3b')
--	 obj3d:setPosition(200,200)
--	 obj3d:setScale(30)
--	 obj3d:playAnimation("default",0,1)
--	 obj3d:setAlphaTestEnable(true)
--     obj3d:setUseLight(true)
--     obj3d:setDirectionLightDirection(1.0,-1,-1)
--     obj3d:setAmbientLight(0.3,0.3,0.5)
--     obj3d:setDirectionLightColor(1.0,0.8,0.8)
--     obj3d:setSpecularIntensity(5.0)
--	 ccbfile:addChild(obj3d)
	
    RAGameLoadingState.setLoadingPercent(0.01)
    RAGameLoadingState.changeState(RAGameLoadingStatus.SDKInit)
    local director = CCDirector:sharedDirector()
    if director:getRunningScene()   then
        director:replaceScene(mScene)
    else
        director:runWithScene(mScene)
    end
    --init the sdk  todo delete
    -- RAGameLoadingState:registerHandler()

    mFirstUpdate = true
end

--desc:在登录页面从后台进入前台
function RAGameLoadingState.enterForeground()
    RALogRelease("RAGameLoadingState.enterForeground()")
    RAGameLoadingState.startSDK()
end

--desc:在登录页面前台进入后台
function RAGameLoadingState.enterBackGround()
    RALogRelease("RAGameLoadingState.enterBackGround()")
    RASDKInitManager:setSDKCheck(false)
end


--需要满足IOS,ANDROID,WIN32三个平台
--正常登陆，切换账号，一分钟切后台重新走登陆流程，三个流程
function RAGameLoadingState.startSDK()
    --如果WIN32,Android平台，特殊处理，直接走登陆SDK
    local label = RASDKLoginConfig.loadingStatelabel[RAGameLoadingState.curState]
    RAGameLoadingState.setLoadingLabel(_RALang(label))

    local RASDKUtil = dynamic_require("RASDKUtil")
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 or CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
            
        -- if is swtich lang to direct getServerList 
        if RAGameLoadingState.isSwitchLang then
            RAGameLoadingState.isSwitchLang = false
            --如果登录成功，获取区服列表
            RASDKInitManager.getServerList(RASDKInitManager.httpListener)
            return 
        end
        
        if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
            RASDKInitManager.onInitSDK()--初始化sdk

            --这时候应该判断是否登陆成功，如果没有登陆成功,需要通知java,告诉lua初始化jni回调监听初始化好了  让继续回调一下onSDKInit
            if RASDKUtil.isSDKLogin() == false then
                RASDKUtil.sendMessageG2P("initLuaSuccess")
            end
        else
            RASDKInitManager.onInitSDK()--初始化sdk
            RASDKInitManager.loginSDK()--登陸sdk    
        end     
    else
        --先判断SDK是否初始化成功，如果初始化失败，则初始化，如果成功，判读是否LOGIN，
        --如果没有LOGIN，先LOGIN，如果已经LOGIN，直接取区服列表
        if RASDKUtil.isSDKInited() == false then
            RALogRelease("RAGameLoadingState. sdk not init, start init()")

            --logTime
            local currTime = os.time()
            local currTab = os.date("*t", currTime);
            local formatStr = "RAGameLoadingState.startSDK Start To init SDK" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
            local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
            RALogRelease(timeStr)

            RASDKInitManager.onInitSDK()--初始化sdk
        else
            if RASDKUtil.isSDKLogin() == false then
                RALogRelease("RAGameLoadingState. sdk init finish, start login")
                RASDKInitManager.loginSDK()--登陸sdk
            else
                RALogRelease("RAGameLoadingState. sdk init finish, login finish start get serverList")
                --如果登录成功，获取区服列表
                RASDKInitManager.getServerList(RASDKInitManager.httpListener)
            end

        end
    end
end

function RAGameLoadingState.Execute()
    mCurSDKTime = mCurSDKTime + GamePrecedure:getInstance():getFrameTime();
    if mFirstUpdate and mCurSDKTime > 1 then
        RALogRelease("RAGameLoadingState.first update()")
        if RAGameLoadingState.isSwitchUser == true then
            RAGameLoadingState.isSwitchUser = false
            RASDKInitManager.switchUserSDK()--切换账号
        elseif RAGameLoadingState.isBeginNewGame == true then 
            RAGameLoadingState.isBeginNewGame = false
            local RAGameConfig = RARequire("RAGameConfig")
            local url = RAGameConfig.BINDACCOUNT_TYPE.createGuest
            RASDKInitManager.bindAccount(url)--开始玩一个新账号    
        else
            --logTime
            local currTime = os.time()
            local currTab = os.date("*t", currTime);
            local formatStr = "RAGameLoadingState.Execute startSDK TheEntrance of SDK" .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
            local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
            RALogRelease(timeStr)
            -- -- todo delete
            -- RAGameLoadingState.startSDK()

            RASDKInitManager:EnterInitPrecedure()
        end
        mFirstUpdate = false
    end

    RASDKInitManager:Execute();
    
   RAGameLoadingState.setPercentByState()
end


function RAGameLoadingState.changeState(state)
    assert(state > 0 and state < RAGameLoadingStatus.max,"error")
    --if the cur state is larger than input state, return
    if RAGameLoadingState.curState >= state then return end
    RAGameLoadingState.curState = state
    local percent = RASDKLoginConfig.scaleBarPercent[RAGameLoadingState.curState].startPer
    RAGameLoadingState.setLoadingPercent(percent)
    local label = RASDKLoginConfig.loadingStatelabel[RAGameLoadingState.curState]
    RAGameLoadingState.setLoadingLabel(_RALang(label))
    
end

function RAGameLoadingState.setLoadingLabel(txt)
    if txt ~= nil and mLoadingLabel ~= nil then
        mLoadingLabel:setString(txt)
    end
end


function RAGameLoadingState.setPercentByState()
     local maxPercent = RASDKLoginConfig.scaleBarPercent[RAGameLoadingState.curState].endPer
     if maxPercent == nil then maxPercent = 1 end
     if mLoadingBar ~= nil then
        local curPercent = mLoadingBar:getScaleX()
         if curPercent < maxPercent then
            local dt = GamePrecedure:getInstance():getFrameTime()
            curPercent = curPercent + mScaleSpeed * dt
            RAGameLoadingState.setLoadingPercent(curPercent)
         end
     end
     

end

--value is 0-1
function RAGameLoadingState.setLoadingPercent(percent)
    percent = math.min(percent,1)
    if mLoadingBar ~= nil then
        mLoadingBar:setScaleX(percent)
    end
    
end

function RAGameLoadingState.Exit()
    RAGameLoadingState.unLoadCCBFile(RAGameLoadingState)
    RAGameLoadingState:removeHandler()
    RASDKInitManager:Exit()
    mFirstUpdate = true
    mSDkInitTime = 4
    mCurSDKTime = 0
    mLoadingBar = nil
    mLoadingLabel = nil
    --purge cached data
    --CCBFile:purgeCachedData();
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
    
end

function RAGameLoadingState:onDirectEnter()    
    GameStateMachine.ChangeState(RARequire("RAGameInitState"))
    RALogRelease("RALoginPage:onDirectEnter")
end

function RAGameLoadingState:registerHandler()
    
    self.platformSDKListener = platformSDKListener:new(RASDKInitManager)--注册SDK回调处理tabel
end

function RAGameLoadingState:removeHandler()
     if self.platformSDKListener then
        self.platformSDKListener:delete()
        self.platformSDKListener = nil
    end
end

return RAGameLoadingState
--endregion
