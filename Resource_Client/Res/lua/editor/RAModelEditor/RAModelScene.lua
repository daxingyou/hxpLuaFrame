local UIExtend = RARequire('UIExtend')
local RABaseEditorScene = RARequire('RABaseEditorScene')
local RARootManager = RARequire('RARootManager')
RARequire('extern')
RARequire('BasePage')
local RAModelScene = class('RABaseEditorScene',RABaseEditorScene)



function RAModelScene:initMenu()
    local mainMenu = CCMenu:create()
    local textLabel = CCLabelTTF:create('选择模型', "Helvetica", 20)
    local menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    local missionEditorBtn = function ()
        CCLuaLog('this is a test')
        -- RARootManager.OpenPage("RAMissionInfoPage")
    end
    menuItemLabel:registerScriptTapHandler(missionEditorBtn)
    
    textLabel = CCLabelTTF:create('新建模型', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    textLabel = CCLabelTTF:create('保存模型', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    textLabel = CCLabelTTF:create('设置选项', "Helvetica", 20)
    menuItemLabel = CCMenuItemLabel:create(textLabel)
    mainMenu:addChild(menuItemLabel)

    mainMenu:alignItemsVerticallyWithPadding(10)
    mainMenu:setAnchorPoint(ccp(0,0))

    mainMenu:setPosition(ccp(40,CCDirector:sharedDirector():getOpenGLView():getVisibleSize().height-70))
    RARootManager.mGUINode:addChild(mainMenu)
end

return RAModelScene.new()