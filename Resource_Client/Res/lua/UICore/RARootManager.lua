--RARootManager
--manage raroot.ccbi for game
local RARootManager = {}
local Utilitys = RARequire("Utilitys")
local UIExtend = RARequire("UIExtend")
local List = RARequire("List")
local RAGameConfig = RARequire("RAGameConfig")
--scene type
SceneTypeList =
{
	NoneScene = 0,
	CityScene = 1,
	WorldScene = 2,
    BattleScene = 3,            --战斗场景
    MissionBarrierScene = 4,    --关卡场景
    MissionEditorScene = 5,     --关卡编辑场景
    ModelEditorScene = 6,       --模型编辑场景
}

local mSceneHandlerArr = {}
local mSceneHandlerName = {}
mSceneHandlerName[SceneTypeList.CityScene] = 'RACityScene'
mSceneHandlerName[SceneTypeList.WorldScene] = 'RAWorldScene'
mSceneHandlerName[SceneTypeList.BattleScene] = 'RABattleScene'
mSceneHandlerName[SceneTypeList.MissionEditorScene] = 'RAMissionScene'
mSceneHandlerName[SceneTypeList.MissionBarrierScene] = "RAMissionBarrierScene"
mSceneHandlerName[SceneTypeList.ModelEditorScene] = "RAModelScene"
--PopupPage stack queue
local mPopupPageCount = 0
local mPopupPageStack = {}


--k:page name     v:page handler
local mPopupPageMap = {}

--ui need update
local mUpdateMap = {}

--记录当前的Scene index
local mCurrScene = SceneTypeList.NoneScene

--记录上一个Scene index
local mLastScene = SceneTypeList.NoneScene

local mMainUIHandler = nil

local mCutSceneHandler = nil
local mCutSceneCommand = nil
local mIsCutingScene = false

local mWaitingHandler = nil
local mCommonTips = nil
local mGuidePageHandler = nil
local mCoverPageHandler = nil
local mBriefingPageHandler = nil                --简报页面
local mBarrierPageHandler = nil                 --关卡页面
local mBarrierGuideDialogPageHandler = nil      --关卡页面2

local mPurgeTimer = 0
local PurgeDelayFrame = 2

local Scene_Node_Shake_Ani_Name = 'ShakerAni'

local initSelf = function()
    RARequire('RARootManager_Msg')
end

--===============================================
--base: handle base part
function RARootManager.Init()    
    initSelf()

    -- 当前是否正在震屏
    RARootManager.mIsShaking = false

	RARootManager.resetPageLogic()
	RARootManager.initNode()
    RARootManager.registerMessageHandlers()
end

function RARootManager.Execute()
	if mUpdateMap ~= nil  then
        for name, handler in pairs(mUpdateMap) do
            handler:Execute()
        end
    end

    local sceneHandler = mSceneHandlerArr[mCurrScene]
    if sceneHandler ~= nil then 
        sceneHandler:Execute()
    end 

    if mPurgeTimer > 0 then
        mPurgeTimer = mPurgeTimer - 1
        if mPurgeTimer == 0 then
            RARootManager._purgeCachedTexture()
        end
    end
end

function RARootManager._clearSceneNode()

    for k,sceneHandler in pairs(mSceneHandlerArr) do
        sceneHandler:Exit()
    end

    mSceneHandlerArr = {}
end

function RARootManager.Exit()
    RARootManager.unregisterMessageHandlers()
    if mMainUIHandler ~= nil then
        mMainUIHandler:Exit()
    end
    RARootManager.RemoveGuidePage()
    RARootManager.RemoveCoverPage()
    RARootManager.RemoveBarrierGuideDialogPage()
    RARootManager._clearSceneNode()
    RARootManager._CloseAllPages()
    RARootManager.resetPageLogic(true)    
    RAUnload("RARootManager_Msg")
    --_G["RACityScene"] = nil
end


function RARootManager.resetPageLogic(isClear)
    if isClear then        
        mPopupPageStack = {}
        mPopupPageMap = {}
        mUpdateMap = {}
        mCurrScene = SceneTypeList.NoneScene
        mLastScene = SceneTypeList.NoneScene
        UIExtend.unLoadCCBFile(RARootManager)
    else
        mPopupPageStack = {}
        mPopupPageMap = {}
        mUpdateMap = {}
        mCurrScene = SceneTypeList.NoneScene
        mLastScene = SceneTypeList.NoneScene
    end
	
    mPopupPageCount = 0
    mMainUIHandler = nil

    mCutSceneHandler = nil
    mCutSceneCommand = nil
    mIsCutingScene = false


    mGuidePageHandler = nil
    mCoverPageHandler = nil
    mWaitingHandler = nil

    mBriefingPageHandler = nil
    mBarrierPageHandler = nil
    mBarrierGuideDialogPageHandler = nil

	RARootManager.mSceneNode = nil
	RARootManager.mGUINode = nil
	RARootManager.mPopNode = nil
	RARootManager.mMsgBoxNode = nil
	RARootManager.mWaitingNode = nil
	RARootManager.mSceneTransNode = nil
    RARootManager.mTopNode = nil
end

function RARootManager.initNode()    
    if RARootManager.mSceneNode ~= nil then
        return
    end
    local ccbfile = UIExtend.loadCCBFile("RARoot.ccbi",RARootManager)

    RARootManager.mSceneNode = tolua.cast(ccbfile:getVariable("mSceneNode"),"CCNode")
    RARootManager.mShaderNode = tolua.cast(ccbfile:getVariable("mShaderNode"),"CCShaderNode")
    RARootManager.mInnerPopupNode = CCNode:create()
    RARootManager.mShaderNode:addChild(RARootManager.mInnerPopupNode)
    --RARootManager.mShaderNode:setUserScale(0.5)
    RARootManager.mShaderNode:setEnable(false)
    
	RARootManager.mGUINode = tolua.cast(ccbfile:getVariable("mGUINode"),"CCNode")
	RARootManager.mPopNode = tolua.cast(ccbfile:getVariable("mPopNode"),"CCNode")
	RARootManager.mMsgBoxNode = tolua.cast(ccbfile:getVariable("mMsgBoxNode"),"CCNode")
	RARootManager.mWaitingNode = tolua.cast(ccbfile:getVariable("mWaitingNode"),"CCNode")
	RARootManager.mSceneTransNode = tolua.cast(ccbfile:getVariable("mSceneTransNode"),"CCNode")
    RARootManager.mTopNode = tolua.cast(ccbfile:getVariable("mTopNode"),"CCNode")
    local mScene = CCScene:create()
    mScene:addChild(ccbfile);
    local director = CCDirector:sharedDirector()
    if director:getRunningScene()   then
        director:replaceScene(mScene)
    else
        director:runWithScene(mScene)
    end 
    CCLuaLog("RARootManager.initNode finish");
end


--===============================================
--返回上一个场景
-- isPassTrans : default = false
--param: 默认为空
function RARootManager.GotoLastScene(isPassTrans,param)    
    RARootManager.ChangeScene(mLastScene,isPassTrans,param)
end

--[[
    --desc: 通过数组传递信息
]]
function RARootManager.ChangeSceneWithArr(args)
    RARootManager.ChangeScene(args.sceneType, args.isPassTrans, args.param)
end

--===============================================
--mSceneNode: handle scene change
-- isPassTrans : default = false
function RARootManager.ChangeScene(sceneType, isPassTrans, param)    
    -- default city scene
    RALogRelease("RARootManager.ChangeScene change to sceneType ".. sceneType .. ", isPassTrans is ".. tostring(isPassTrans))

    isPassTrans = isPassTrans or false
	if mCurrScene == SceneTypeList.NoneScene and sceneType==nil then
        sceneType = SceneTypeList.CityScene
    end
    if sceneType == mCurrScene then
        return
    end
    if mIsCutingScene then
        return
    end
    mLastScene = mCurrScene
    mCurrScene = sceneType
    mIsCutingScene = true

    if mLastScene ~= SceneTypeList.NoneScene then
        RARootManager._HideLastGUI(mLastScene)
    end

    mCutSceneCommand = nil 
    mCutSceneCommand = function ()


        local lastHandler = mSceneHandlerArr[mLastScene]
        if lastHandler ~= nil then 
            lastHandler:Exit()
            mSceneHandlerArr[mLastScene] = nil
        end

        RARootManager._purgeCachedData()

        local sceneHandler = mSceneHandlerArr[mCurrScene]
        if sceneHandler == nil then 
            sceneHandler = UIExtend.GetPageHandler(mSceneHandlerName[mCurrScene])
            sceneHandler:Enter(param)
            UIExtend.AddPageToNode(sceneHandler, RARootManager.mSceneNode)
            mSceneHandlerArr[mCurrScene] = sceneHandler
        end 

        if sceneType == SceneTypeList.BattleScene then 
            local RAGameConfig = RARequire("RAGameConfig")
            if RAGameConfig.BattleDebug == 1 then 
                
            else
                RARootManager._ShowCurrGUI()
            end
        elseif sceneType == SceneTypeList.MissionEditorScene or sceneType == SceneTypeList.ModelEditorScene then 
          
        else
            RARootManager._ShowCurrGUI()  
        end 
        -- if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS or CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        --     RARootManager._ShowCurrGUI()  
        -- else 
        --     local RAGameConfig = RARequire("RAGameConfig")
        --     if RAGameConfig.BattleDebug == 1 then 
        --     else
        --         RARootManager._ShowCurrGUI()  
        --     end
        -- end
        
    end

    if isPassTrans then
        --clear all pages
        RARootManager._CloseAllPages()
        if mCutSceneCommand ~= nil then
            mCutSceneCommand()
            mCutSceneCommand = nil
        end
        mIsCutingScene = false
    else
        RARootManager.ShowTransform(mCurrScene)

        --clear all pages

        if mCurrScene == SceneTypeList.BattleScene then 
            ----如果要进入的场景是战斗，战斗页面不清空stack，用于退出的时候GotoLastPage，返回上一级目录
            local clearStack = false
            RARootManager.CloseAllPages(clearStack)

            --如果当前要切入的场景是战斗场景，则播放战斗加载的loading视频
            RALogRelease("RARootManager.ChangeScene change begin play load battle movie")
            
            if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
                --播放视频
                local RASDKUtil = RARequire("RASDKUtil")
                RASDKUtil.sendMessageG2P("playMovie", {fileName = "loadBattle",needSkip = false,isLoop = true})
            else
                local loadFightMp4Path = CCFileUtils:sharedFileUtils():fullPathForFilename("loadBattle.mp4")
                libOS:getInstance():playMovie(loadFightMp4Path, "")
            end
            RALogRelease("RARootManager.ChangeScene change end play load battle movie")
        else
            --如果要退出的场景是BattleScene,则ReturntoLastPage,否则清空所有页面
            if mLastScene ~= SceneTypeList.BattleScene then
               RARootManager.CloseAllPages() 
            end
        end
        
        

    end
end

function RARootManager.GetCurrScene()	
	return mCurrScene
end

function RARootManager.GetIsInCity()
    return mCurrScene == SceneTypeList.CityScene
end

function RARootManager.GetIsInWorld()
    return mCurrScene == SceneTypeList.WorldScene
end

function RARootManager.GetIsInBarrierScene()
    return mCurrScene == SceneTypeList.MissionBarrierScene
end

--desc: 获得当前scene的handler
function RARootManager.GetCurrSceneHandler()
    if mCurrScene then
        return mSceneHandlerArr[mCurrScene]
    end
    return nil
end

function RARootManager.GetIsInBattle()
    return mCurrScene == SceneTypeList.BattleScene
end

--===============================================
--mGUINode: handle GUI part
function RARootManager.InitGUI()
    if mMainUIHandler ~= nil then
        return
    end
    mMainUIHandler = UIExtend.GetPageHandler("RAMainUIPage")
    mMainUIHandler:Enter()
    UIExtend.AddPageToNode(mMainUIHandler, RARootManager.mGUINode)
end

function RARootManager._HideLastGUI(lastType)
    if mMainUIHandler == nil then
        return
    end
    -- gui in city
    if RARootManager.GetIsInCity() then

    end

    -- gui in world
    if RARootManager.GetIsInWorld() then

    end 

    mMainUIHandler:HideLastGUI(lastType)
end

function RARootManager._ShowCurrGUI()
	if mMainUIHandler == nil then
        RARootManager.InitGUI()
    end
    -- gui in city
    if RARootManager.GetIsInCity() then

    end

    -- gui in world
    if RARootManager.GetIsInWorld() then

    end 

    mMainUIHandler:UpdateUIByScene(mCurrScene)
    mMainUIHandler:ShowCurrGUI(mCurrScene)
end


--===============================================
-- mPopNode: handle popup ui part
-- isUpdate: if page need call Execute, this param need to be true
-- needNotToucherLayer: if page need no touch layer, this param need to be true, default = true
-- isBlankClose: defalut = false
            --  if value = true, need one node named 'mContentSizeNode' in ccbi
            --  when touch outside of this node, it will call function 'CloseCurrPage()'
            --  can read code in file 'BasePage.lua', function is 'BaseFunctionPage:AddNoTouchLayer'            
-- swallowTouch: default = true
            -- to control no touch layer swallow touch event
function RARootManager.OpenPage(pageName, pageArg, isUpdate,needNotToucherLayer, isBlankClose,swallowTouch)
    local message = {}
    message.pageName = pageName
    message.pageArg = pageArg
    message.isUpdate = isUpdate
    message.needNotToucherLayer = needNotToucherLayer
    message.isBlankClose = isBlankClose or false
    message.swallowTouch = swallowTouch
    MessageManager.sendMessage(MessageDef_RootManager.MSG_OpenPage,message)

    if pageName ~= 'RAConfirmPage' then 
        MessageManager.sendMessage(MessageDef_Building.MSG_Cancel_Building_Select)
    end 
end

function RARootManager._setSceneAndMainGuiVisible(flag)	
    RARootManager.mSceneNode:setVisible(flag)
    RARootManager.mGUINode:setVisible(flag)
end

function RARootManager._OpenPageAni(pageName,pageHandler)   
    local rapageui_conf = RARequire("rapageui_conf")
    local RACommonTitleHelper = RARequire("RACommonTitleHelper")
    local pageInfo = rapageui_conf[pageName]
    if pageInfo~= nil then
        --page mode
        local pageSelfAni = false
        if pageInfo.effectType == 1 then
           pageSelfAni = true
        end
            --common title animation
        if RACommonTitleHelper.mTitleMap[pageName] ~= nil then
            if RACommonTitleHelper.mTitleMap[pageName].ccbfile:hasAnimation("InAni") then
                RACommonTitleHelper.mTitleMap[pageName].ccbfile:runAnimation("InAni")
            end
            pageSelfAni = true
        end
        
        if pageSelfAni  then
            --page animation if has
           if pageHandler.ccbfile:hasAnimation("InAni")  then
                pageHandler.ccbfile:runAnimation("InAni")
           end
           --if it's page, means it ocupied the whole screen. 
           --so set sceneNode and guiNode visible = false, to reduce the drawcall
           RARootManager._setSceneAndMainGuiVisible(false)  
        end

        --popup mode
        if pageInfo.effectType == 2 then
            local hasAda = pageHandler.ccbfile:hasVariable("mAdaptationNode")
            if hasAda then
                local adaptionNode = pageHandler.ccbfile:getCCNodeFromCCB("mAdaptationNode")
                if adaptionNode ~= nil then
                    adaptionNode:setScale(0)    
                    local scaleAction = CCScaleTo:create(0.2,1,1)
                    local backOutAct = CCEaseBackOut:create(scaleAction)

                    --新手期间要等动作做完才能框主所选区域 by xinping
                    local funcAction = CCCallFunc:create(function ()
                        RARequire("MessageDefine")
                        RARequire("MessageManager")                                   
                        MessageManager.sendMessage(MessageDef_RootManager.MSG_ActionEnd)
                    end)
                    local array = CCArray:create()
                    array:addObject(backOutAct)
                    array:addObject(funcAction)
                    local seq = CCSequence:create(array)
                    adaptionNode:runAction(seq)
                end
            end
            --set shaderNode enable
            if RAGameConfig.ShaderNodeEffect then
                --copy all data to mPopupNode1 node
                for k,v in pairs(mPopupPageStack) do
                    if type(v) == "table" then
                        if 1 ~= k then
                            local pageHandler = UIExtend.GetPageHandler(v.name)
                            UIExtend.SwitchPageToNode(pageHandler,RARootManager.mPopNode,RARootManager.mInnerPopupNode,k * -1)
                        end
                    end
                end
                --use shader node
                RARootManager.mShaderNode:setEnable(true)
                RARootManager.mShaderNode:setDrawOnceDirty();
            end
            

            local hasAdaColor = pageHandler.ccbfile:hasVariable("mAdaptationColor")
            if hasAdaColor then
                local adaptionLayer = pageHandler.ccbfile:getCCLayerColorFromCCB("mAdaptationColor")
                if adaptionLayer ~= nil then
                    if RAGameConfig.ShaderNodeEffect then
                        adaptionLayer:setVisible(false)
                    else
                        adaptionLayer:setOpacity(0)    
                        local fadeAction = CCFadeTo:create(0.1,200)
                        adaptionLayer:runAction(fadeAction)
                    end
                    
                end
            end
        end 
    end   
end


function RARootManager._OpenPage(pageName, pageArg, isUpdate,needNotToucherLayer, isBlankClose,swallowTouch)	
    -- if already in stack, unload it
    -- maybe can improve
    if mPopupPageMap ~= nil then
        local k,v = RARootManager.checkPageLoaded(pageName)
        if v ~= nil then
            RARootManager._ClosePage(pageName,true)
        end
    end
    --CCMessageBox(pageName,"hint")
	local pageHandler = UIExtend.GetPageHandler(pageName)
    if pageHandler == nil then
        CCLuaLog("RARootManager.OpenPage---lua handler for page="..pageName.." is not exist")
        return
    end

    pageHandler:Enter(pageArg)    
    mPopupPageMap[pageName] = pageHandler
    mPopupPageCount = mPopupPageCount + 1
    pageHandler.pageTag = mPopupPageCount
    if needNotToucherLayer == nil then
        needNotToucherLayer = true    
    end
    if swallowTouch == nil then swallowTouch = true end
    local stackAtom = {
    	name = pageName,
    	arg = pageArg,
    	update = isUpdate,
        -- default add no touch
    	touch = needNotToucherLayer,

        isBlankClose = isBlankClose,
        swallowTouch = swallowTouch,
	}
	--push front
    table.insert(mPopupPageStack,1,stackAtom)
--    mPopupPageStack:PushFront(stackAtom)
    
    local first = 1
    --add to node
    UIExtend.AddPageToNode(pageHandler, RARootManager.mPopNode, needNotToucherLayer, 
    isBlankClose,swallowTouch,first * -1)

    --open page ani related
    RARootManager._OpenPageAni(pageName,pageHandler)	

    if isUpdate and mUpdateMap ~= nil then
        if mUpdateMap[pageName] == nil and pageHandler.Execute then
        	mUpdateMap[pageName] = pageHandler
        end
    end

    local currTopPage = mPopupPageStack[1]
    if currTopPage ~= nil then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_TopPageMayChange,{topPageName = currTopPage.name}) 
    end
end

-- isPopSelf: defalut is true
-- isClearAll: handle is to clear all page stack, default is false
-- recover arg:isClear
function RARootManager.ClosePage(pageName, isPopSelf, isClear, pageArg)
    local message = {}
    message.pageName = pageName    
    if isPopSelf == nil then isPopSelf = true end
    message.isPopSelf = isPopSelf
    message.isClear = isClear or false
    message.pageArg = pageArg
    MessageManager.sendMessage(MessageDef_RootManager.MSG_ClosePage,message)    
end


function RARootManager._ClosePage(pageName, isPopSelf, isClear, pageArg)
	if pageName == nil then
		RARootManager.CloseCurrPage()
	end

	local k,pageHandler = RARootManager.checkPageLoaded(pageName)
    if pageHandler ~= nil then
    	mUpdateMap[pageName] = nil  
        
        -- 移除page的时候，尝试去移除点击屏蔽层
        if pageHandler.RemoveNoTouchLayer ~= nil then
            pageHandler:RemoveNoTouchLayer()
        end
        pageHandler:Exit(pageArg)
        UIExtend.unLoadCCBFile(pageHandler)
        mPopupPageMap[pageName] = nil

        local errorFlag = false

        --clear popup stack
        if isClear then
            mPopupPageStack = {}
        else
            if mPopupPageStack ~= nil and isPopSelf then
				--remove the page in the stack, no mater in front or end
				--to avoid first push, then close and etc conditions
                for k,v in pairs(mPopupPageStack) do 
                    if v.name == pageName then
                        table.remove(mPopupPageStack,k)
                        break
                    end
                end
            end
        end
        RARootManager._setSceneAndMainGuiVisible(true)

        if RAGameConfig.ShaderNodeEffect then
                --copy inner top node to the outside node
			--get the top item
            local currTopPage = mPopupPageStack[1]
            local first = 1
            if currTopPage ~= nil then
                local rapageui_conf = RARequire("rapageui_conf")
                local pageInfo = rapageui_conf[currTopPage.name]
                if pageInfo~= nil and pageInfo.effectType == 2 then
                    local pageHandler = UIExtend.GetPageHandler(currTopPage.name)
                    UIExtend.SwitchPageToNode(pageHandler,RARootManager.mInnerPopupNode,RARootManager.mPopNode,first * -1)
                    RARootManager.mShaderNode:setEnable(true)
                    RARootManager.mShaderNode:setDrawOnceDirty()
                else
                    RARootManager.mShaderNode:setEnable(false)
                end
            else
                mPopupPageStack = {}
                RARootManager.mShaderNode:setEnable(false)
            end
            if errorflag then
                RARootManager.mShaderNode:setEnable(false)
            end
        end
        --RARootManager._setSceneAndMainGuiVisible(true)
    else
        CCLuaLog("RARootManager.ClosePage----not find page handler for page:"..pageName)
    end


    local currTopPage = mPopupPageStack[1]
    if currTopPage ~= nil then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_TopPageMayChange,{topPageName = currTopPage.name}) 
    end
end

--clearStack默认是true,当某些特殊情况下，可能不需要clearStack
function RARootManager.CloseAllPages(clearStack)
    local message = {}
    if clearStack == nil then clearStack = true end
    message.isCloseAll = true
    message.clearStack = clearStack
    MessageManager.sendMessage(MessageDef_RootManager.MSG_ClosePage,message)
end

function RARootManager._CloseAllPages(clearStack)
	mUpdateMap = {}
    --clearStack默认为true,某些特殊情况下不需要清空
    if clearStack ~=nil and clearStack == false then
        RALog("do not clear")
    else        
        mPopupPageStack = {}    
    end
	
    RARootManager._setSceneAndMainGuiVisible(true)
	for k,pageHandler in pairs(mPopupPageMap) do
		if pageHandler ~= nil then
            -- 移除page的时候，尝试去移除点击屏蔽层
            if pageHandler.RemoveNoTouchLayer ~= nil then
                pageHandler:RemoveNoTouchLayer()
            end
			pageHandler:Exit()
			UIExtend.unLoadCCBFile(pageHandler)
		end
	end
    if RAGameConfig.ShaderNodeEffect then
        RARootManager.mShaderNode:setEnable(false)
    end
	mPopupPageMap = {}
end

-- isClear: handle is to clear page stack
-- remove arg: isClear
function RARootManager.CloseCurrPage()
    local message = {}
    message.isCloseCur = true
    -- message.isPopSelf = true
    -- message.isClear = false
    MessageManager.sendMessage(MessageDef_RootManager.MSG_ClosePage,message)
    -- RARootManager._CloseCurrPage(isClear)  
    --暂时先不触发，策划还要定触发的时机,这里在关闭很多页面的时候都会被触发，具有很强的不确定性，不满足策划需求，add by xinghui
    --MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
end


function RARootManager._CloseCurrPage(isPopSelf, isClear)
	local pageAtom = mPopupPageStack[1]
	if pageAtom == nil or pageAtom.name == nil then
		return
	end
	RARootManager._ClosePage(pageAtom.name, true, false)
end


function RARootManager.CheckIsPageOpening(pageName)
    local pageAtom = mPopupPageStack[1]
    if pageAtom == nil or pageAtom.name == nil then
        return false
    end
    if pageAtom.name == pageName then
        return true
    end
    return false
end

function RARootManager.CheckHasPageOpening()
    local pageAtom = mPopupPageStack[1]
    if pageAtom == nil or pageAtom.name == nil then
        return false
    end
    return true
end

--用于直接返回堆栈中的第一个页面，不关闭当前的页面
function RARootManager.ReturnToLastPage()
    MessageManager.sendMessage(MessageDef_RootManager.MSG_ReturntoLastPage,{})
end

function RARootManager._ReturntoLastPage()
    if #mPopupPageStack == 0  then
        return
    end
    local nextPageAtom = table.remove(mPopupPageStack,1)
    if nextPageAtom == nil or nextPageAtom.name == nil then
        mPopupPageStack = {}
        return
    end
    RARootManager.OpenPage(nextPageAtom.name, nextPageAtom.arg, nextPageAtom.update, nextPageAtom.touch, nextPageAtom.isBlankClose, nextPageAtom.swallowTouch)

end

function RARootManager.GotoLastPage()
    MessageManager.sendMessage(MessageDef_RootManager.MSG_GotoLastPage,{})
end

function RARootManager._GotoLastPage()
	local pageAtom = mPopupPageStack[1]
	if pageAtom == nil or pageAtom.name == nil  then
		return
	end
	local k,pageHandler = RARootManager.checkPageLoaded(pageAtom.name)
    if pageHandler ~= nil then
    	mUpdateMap[k] = nil        
        -- 移除page的时候，尝试去移除点击屏蔽层
        if pageHandler.RemoveNoTouchLayer ~= nil then
            pageHandler:RemoveNoTouchLayer()
        end
        pageHandler:Exit(pageArg)
        UIExtend.unLoadCCBFile(pageHandler)
        mPopupPageMap[k] = nil
        RARootManager._setSceneAndMainGuiVisible(true)
		--pop front
        table.remove(mPopupPageStack,1)
        --get last page in stack
        if #mPopupPageStack == 0  then
        	return
        end
		--pop front
        local nextPageAtom = table.remove(mPopupPageStack,1)
        if nextPageAtom == nil or nextPageAtom.name == nil then
        	mPopupPageStack = {}
			return
		end
        RARootManager.OpenPage(nextPageAtom.name, nextPageAtom.arg, nextPageAtom.update, nextPageAtom.touch, nextPageAtom.isBlankClose, nextPageAtom.swallowTouch)
    else
        CCLuaLog("RARootManager.ClosePage----not find page handler for page:"..pageAtom.name)
    end
end


function RARootManager.checkPageLoaded(pageName)
	local k,pageHandler = Utilitys.table_find(
        mPopupPageMap,
        function(k,v)
            return k == pageName 
        end)
	return k, pageHandler
end

--===============================================
--mMsgBoxNode: handle msg box ui part
function RARootManager.ShowMsgBox(msgTxt,...)
    local showMessageBoxPage = UIExtend.GetPageHandler("RAShowMessageBoxPage")
    showMessageBoxPage:setString_Lan(msgTxt,...)
    local isOpen = showMessageBoxPage:Enter()
    if not isOpen then return end
    UIExtend.AddPageToNode(showMessageBoxPage, RARootManager.mMsgBoxNode)
end

local isBroadcastToGUINode = false
function RARootManager.ShowBroadcast(tb)
    --新手期屏蔽
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() then
        return
    end

    local broadcastPage = UIExtend.GetPageHandler("RABroadcastPage")
    broadcastPage:setBroadcastData(tb)
    if not broadcastPage.ccbfile and #broadcastPage.broadcastList ~= 0 then
        broadcastPage:Enter()
        if RARootManager.mGUINode then
            isBroadcastToGUINode = true
            UIExtend.AddPageToNode(broadcastPage, RARootManager.mGUINode)
        end
    else
        if not isBroadcastToGUINode and RARootManager.mGUINode then
            isBroadcastToGUINode = true
            UIExtend.AddPageToNode(broadcastPage, RARootManager.mGUINode)
        end
        broadcastPage:refresh()
    end
end


--ÏÔÊ¾½±ÀøÍ¨ÓÃµ¯¿ò,data°üº¬icon£¬title£¬text
function RARootManager.ShowCommonReward(data, isSplite)
--    local rewardUI = dynamic_require("RARewardPopupNewPage")
--    rewardUI:Enter(data, isSplite)
--    UIExtend.AddPageToNode(rewardUI, RARootManager.mMsgBoxNode)
    RARootManager.AddCoverPage()
    RARootManager.OpenPage("RARewardPopupNewPage", {rewardArr = data, isSplite = isSplite}, false, true, true)

end

--===============================================
--Common Tips: Common Tips part  -- part.2 handle the tips msg
function RARootManager.ShowTips(data)
    if data.htmlStr == nil or data.relativeNode==nil then return; end
    RARootManager.RemoveTips()  
    --RARootManager.OpenPage("RACommonTips", data, false, true, true ,false )
	mCommonTips = UIExtend.GetPageHandler("RACommonTips",true,data)
    UIExtend.AddPageToNode(mCommonTips, RARootManager.mMsgBoxNode,true,true,false)
end

function RARootManager.RemoveTips()    
    if mCommonTips ~= nil then
        mCommonTips:Exit()        
        UIExtend.unLoadCCBFile(mCommonTips)
        mCommonTips = nil
    end
end

function RARootManager.hasTips()    
    return mCommonTips ~= nil
end

--===============================================
--mWaitingNode: handle waiting ui part
function RARootManager.ShowWaitingPage(isShow, closeTime, closePrint)
	if mWaitingHandler ~= nil then
        mWaitingHandler:Exit()
        UIExtend.unLoadCCBFile(mWaitingHandler)
        mWaitingHandler = nil
    end
    mWaitingHandler = UIExtend.GetPageHandler('RAMainUIWaitingPage')    
    mWaitingHandler:Enter({isShow = isShow, closeTime = closeTime, closePrint = closePrint})
    UIExtend.AddPageToNode(mWaitingHandler, RARootManager.mWaitingNode, nil , true)
end

function RARootManager.RemoveWaitingPage()
	CCLuaLog("RARootManager.RemoveWaitingPage")
    if mWaitingHandler ~= nil then
        mWaitingHandler:Exit()        
        UIExtend.unLoadCCBFile(mWaitingHandler)
        mWaitingHandler = nil
    end
end

--===============================================
--mSceneTransNode: handle scene transform ui part
function RARootManager.ShowTransform(transType)
    if mCutSceneHandler ~= nil then
        mCutSceneHandler:Exit()        
        UIExtend.unLoadCCBFile(mCutSceneHandler)
        mCutSceneHandler = nil
    end

	mCutSceneHandler = UIExtend.GetPageHandler('RAMainUICutScenePage')
    mCutSceneHandler:Enter(transType)
    UIExtend.AddPageToNode(mCutSceneHandler, RARootManager.mSceneTransNode)

    -- test waiting page
    RARootManager.ShowWaitingPage(false)
end

function RARootManager._CutSceneBegin()
    CCLuaLog("RARootManager._CutSceneBegin  ")
    if mCutSceneCommand ~= nil then
        mCutSceneCommand()
        mCutSceneCommand = nil
    end
    mPurgeTimer = PurgeDelayFrame

     --如果上一个场景是战斗，则返回上一级页面
    if mLastScene == SceneTypeList.BattleScene then
        RARootManager.ReturnToLastPage()
    end
end

function RARootManager._CutSceneEnd()
    CCLuaLog("RARootManager._CutSceneEnd")
    if mCutSceneHandler ~= nil then
        mCutSceneHandler:Exit()
        UIExtend.unLoadCCBFile(mCutSceneHandler)
        mCutSceneHandler = nil
    end  
    mIsCutingScene = false

    --如果是当前要切换过去的战斗场景，则stopMovie
    if mCurrScene == SceneTypeList.BattleScene then 
        RALogRelease("RARootManager.ChangeScene begin stop movie if load battle movie has not finish ")
         
         if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
            --播放视频
            local RASDKUtil = RARequire("RASDKUtil")
            RASDKUtil.sendMessageG2P("endPlayMovie")
        else
            libOS:getInstance():stopMovie()
        end
         RALogRelease("RARootManager.ChangeScene end stop movie if load battle movie has not finish ")
    end

    -- test waiting page
    RARootManager.RemoveWaitingPage()

end

function RARootManager._purgeCachedData()
    CCBFile:purgeCachedData()
    SkeletonManager:removeAllDataInfo()
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
    local common = RARequire('common')
    common:reset()
end

function RARootManager._purgeCachedTexture()
    -- 清除纹理缓存
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end


-----------------------------------------------------------
--mTopNode

--desc: 添加简报页面
function RARootManager.AddBriefingPage(data)
    if mBriefingPageHandler == nil then
        mBriefingPageHandler = UIExtend.GetPageHandler("RAMissionBriefingPage")
        mBriefingPageHandler:Enter(data)

        if data.update then
            mUpdateMap["RAMissionBriefingPage"] = mBriefingPageHandler
        end

        UIExtend.AddPageToNode(mBriefingPageHandler, RARootManager.mTopNode)
    end
end

--desc: 移除简报页面
function RARootManager.RemoveBriefingPage()
    if mBriefingPageHandler then
        mUpdateMap["RAMissionBriefingPage"] = nil
        mBriefingPageHandler:Exit()
        UIExtend.unLoadCCBFile(mBriefingPageHandler)
        mBriefingPageHandler = nil
    end
end

--desc: 添加关卡页面
function RARootManager.AddBarrierPage(data)
    if mBarrierPageHandler == nil then
        mBarrierPageHandler = UIExtend.GetPageHandler("RAMissionBarrierPage")
        mBarrierPageHandler:Enter(data)

        if data and data.update then
            mUpdateMap["RAMissionBarierPage"] = mBarrierPageHandler
        end

        UIExtend.AddPageToNode(mBarrierPageHandler, RARootManager.mTopNode)
    end
end

--desc: 移除管卡页面
function RARootManager.RemoveBarrierPage()
    if mBarrierPageHandler then
        mUpdateMap["RAMissionBarierPage"] = nil
        mBarrierPageHandler:Exit()
        UIExtend.unLoadCCBFile(mBarrierPageHandler)
        mBarrierPageHandler = nil
    end
end

--desc: 添加剧情对话页（为第二版剧情做的，替换BarrierPage，跟新手的对话相同）
function RARootManager.AddBarrierGuideDialogPage(data)
    if mBarrierGuideDialogPageHandler == nil then
        mBarrierGuideDialogPageHandler = UIExtend.GetPageHandler("RAMissionBarrierGuideDialogPage")
        mBarrierGuideDialogPageHandler:Enter(data)

        if data and data.update then
            mUpdateMap["RAMissionBarrierGuideDialogPage"] = mBarrierGuideDialogPageHandler
        end

        UIExtend.AddPageToNode(mBarrierGuideDialogPageHandler, RARootManager.mTopNode)
    end
end

--desc: 移除剧情对话页
function RARootManager.RemoveBarrierGuideDialogPage()
    if mBarrierGuideDialogPageHandler then
        mUpdateMap["RAMissionBarrierGuideDialogPage"] = nil
        mBarrierGuideDialogPageHandler:Exit()
        UIExtend.unLoadCCBFile(mBarrierGuideDialogPageHandler)
        mBarrierGuideDialogPageHandler = nil
    end
end 

function RARootManager.AddGuidPage(data)
    if mGuidePageHandler ~= nil then
        mGuidePageHandler:refreshPage(data)
    else
        mGuidePageHandler = UIExtend.GetPageHandler('RAGuidePage')    
        mGuidePageHandler:Enter(data)
        
        if data.update or (mGuidePageHandler.constGuideInfo and mGuidePageHandler.constGuideInfo.update) then
            mUpdateMap['RAGuidePage'] = mGuidePageHandler
        end
        UIExtend.AddPageToNode(mGuidePageHandler, RARootManager.mTopNode)
    end
end

--desc: 隐藏引导页
function RARootManager.HideGuidePage()
    if mGuidePageHandler then
        mGuidePageHandler:getRootNode():setVisible(false)
    end
end

--desc: 显示引导页
function RARootManager.ShowGuidePage()
    if mGuidePageHandler then
        mGuidePageHandler:getRootNode():setVisible(true)
    end
end

function RARootManager.RemoveGuidePage()
    CCLuaLog("RARootManager.RemoveGuidePage")
    if mGuidePageHandler ~= nil then
        mUpdateMap['RAGuidePage'] = nil
        mGuidePageHandler:Exit()        
        UIExtend.unLoadCCBFile(mGuidePageHandler)
        mGuidePageHandler = nil
    end
end

function RARootManager.AddCoverPage(data)
    if mCoverPageHandler ~= nil then
        mCoverPageHandler:Exit()
        UIExtend.unLoadCCBFile(mCoverPageHandler)
        mCoverPageHandler = nil
        mUpdateMap['RACoverPage'] = nil
    end
    mCoverPageHandler = UIExtend.GetPageHandler('RACoverPage')    
    mCoverPageHandler:Enter(data)
    if data and data.update then
        mUpdateMap['RACoverPage'] = mCoverPageHandler
    end
    UIExtend.AddPageToNode(mCoverPageHandler, RARootManager.mTopNode)
end

function RARootManager:isOpenCoverPage()
    if mUpdateMap['RACoverPage'] then
        return true
    end
    return false 
end
function RARootManager.RemoveCoverPage()
    if mCoverPageHandler ~= nil then
        mUpdateMap['RACoverPage'] = nil
        mCoverPageHandler:Exit()        
        UIExtend.unLoadCCBFile(mCoverPageHandler)
        mCoverPageHandler = nil
    end
end

function goAndroidBack()
    local currTopPage = mPopupPageStack[1]
    if currTopPage and currTopPage.name=="RAChooseBuildPage" then
        RARequire("MessageDefine")
        RARequire("MessageManager")
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true})
    end 
    RARootManager.CloseCurrPage()
end

--判断当前页面是否是目标界面
function RARootManager:isTargetPage(pageName,index)
    if index==nil then index=1 end 
    local currTopPage = mPopupPageStack[index]
    if currTopPage and currTopPage.name==pageName then
        return true
    end
    return false
end

--判断是否直接在主UI界面上面
function RARootManager:isInMainUITop(pageName,index)
    local currTopPage = mPopupPageStack[1]
    local bottomPage = mPopupPageStack[2]
    if currTopPage and currTopPage.name==pageName and bottomPage==nil then
        return true
    end
    return false
end
function RARootManager:showDiamondsConfrimDlg(confirmData)
    local RAConfirmManager = RARequire("RAConfirmManager")
    local isShow = RAConfirmManager:getShowConfirmDlog(confirmData.type)
    if isShow then
        RARootManager.OpenPage("RACommonDiamondsPopUp", confirmData,false,true,true)
    else
         if confirmData.resultFun then
            confirmData.resultFun(true)
        end 
    end
end

function RARootManager._ShakeSceneNode()
    if not RARootManager.mIsShaking then
        RARootManager.mIsShaking = true
        RARootManager.ccbfile:runAnimation(Scene_Node_Shake_Ani_Name)
    end
end 

function RARootManager:runShaderNodeInAni( )
    if RAGameConfig.ShaderNodeEffect then
        if RARootManager.ccbfile ~= nil then
            RARootManager.ccbfile:runAnimation("InAni")
        end 
    end
    
end


function RARootManager:runShaderNodeOutAni( )
    if RAGameConfig.ShaderNodeEffect then
        if RARootManager.ccbfile ~= nil then
            RARootManager.ccbfile:runAnimation("OutAni")
        end
    end
end

function RARootManager:OnAnimationDone(ccbfile)
    if RAGameConfig.ShaderNodeEffect == false then
        return
    end

    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == "OutAni" then
        RARootManager.mShaderNode:setEnable(false)
        RARootManager.mShaderNode:setValue1(1.0)
        --RARootManager.mShaderNode:setUserScale(0.5)
        RARootManager.ccbfile:runAnimation("Default Timeline")
    elseif lastAnimationName == Scene_Node_Shake_Ani_Name then
        RARootManager.mIsShaking = false
        RARootManager.ccbfile:runAnimation("Default Timeline")
    end
end


-------------------------------
return RARootManager