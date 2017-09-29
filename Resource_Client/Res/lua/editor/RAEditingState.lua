local RARootManager = RARequire('RARootManager')
local RAEditingState = {
}

--战斗调试加载
function RAEditingState._initLuaPreloadTest()
    local RAGlobalListener = RARequire('RAGlobalListener')
    RAGlobalListener.init()
    GameStateMachine.setStateListener(dynamic_require('RAGlobalListener'))
    RARequire("BasePage")
    RARequire("RAStringUtil"):setLanguage()
    RAImageSetManager:getInstance():init('Res/txt/Imageset_test.json')
end 

function RAEditingState.Execute()
    local delta = GamePrecedure:getInstance():getFrameTime()
    RARootManager.Execute()
end

function RAEditingState.Enter()
    RALogRelease("RAEditingState.Enter()")
    RAEditingState._initLuaPreloadTest()
    
    local mScene = CCScene:create()

    local mainMenu = CCMenu:create()


    local textLabel = CCLabelTTF:create('关卡编辑器', "Helvetica", 20)
    local menuItemLabel = CCMenuItemLabel:create(textLabel)

    local missionEditorBtn = function ()
        RARootManager.Init()
        RARootManager.ChangeScene(SceneTypeList.MissionEditorScene, true)
    end

    menuItemLabel:registerScriptTapHandler(missionEditorBtn)
    mainMenu:addChild(menuItemLabel)
	mScene:addChild(mainMenu)

    textLabel = CCLabelTTF:create('模型编辑器', "Helvetica", 20)

    local modelEditorBtn = function ()
        RARootManager.Init()
        RARootManager.ChangeScene(SceneTypeList.ModelEditorScene, true)
    end
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    menuItemLabel:registerScriptTapHandler(modelEditorBtn)
    mainMenu:addChild(menuItemLabel)

    -- textLabel = CCLabelTTF:create('关卡编辑器2', "Helvetica", 20)
    -- menuItemLabel = CCMenuItemLabel:create(textLabel)
    -- mainMenu:addChild(menuItemLabel)

    mainMenu:alignItemsVerticallyWithPadding(10)

    local director = CCDirector:sharedDirector()
    if director:getRunningScene()   then
        director:replaceScene(mScene)
    else
        director:runWithScene(mScene)
    end
end

return RAEditingState

