-- 场景管理器
-- 用于实现场景间互相切换时一些特殊需求
-- 用于支持：不在当前场景，但是可能需要一些数据存储或者监听消息

--===================================================================
local RAScenesMananger = {}

local mScenesCmdMap = nil

-- init
function RAScenesMananger.Init()
	RAScenesMananger.resetCmdData()
	RAScenesMananger.registerMessageHandlers()	
end

-- function RAScenesMananger.Execute()
-- end

function RAScenesMananger.Exit()
	RAScenesMananger.unregisterMessageHandlers()
	RAScenesMananger.resetCmdData()
end

-- add cmd
function RAScenesMananger.AddSceneCmd(sceneType, cmdType, cmdData)
	if mScenesCmdMap == nil then
		RAScenesMananger.resetCmdData()
	end
	if sceneType == nil or cmdType == nil or cmdData == nil then return end
	local sceneMap = mScenesCmdMap[sceneType]
	if sceneMap == nil then
		sceneMap = {}
		mScenesCmdMap[sceneType] = sceneMap
	end
	sceneMap[cmdType] = cmdData
end

-- get cmd 
function RAScenesMananger.GetSceneCmd(sceneType, cmdType)
	if mScenesCmdMap == nil or sceneType == nil or cmdType == nil then return nil end
	if mScenesCmdMap[sceneType] ~= nil then
		return mScenesCmdMap[sceneType][cmdType]
	end
	return nil
end

-- remove cmd 
function RAScenesMananger.RemoveSceneCmd(sceneType, cmdType)
	if mScenesCmdMap == nil then return end
	-- cmd type == nil, clear by sceneType
	if cmdType == nil then
		mScenesCmdMap[sceneType] = nil
		return
	end

	if mScenesCmdMap[sceneType] ~= nil then
		mScenesCmdMap[sceneType][cmdType] = nil
	end
end


function RAScenesMananger.resetCmdData()
	mScenesCmdMap = nil

	mScenesCmdMap = {}
end

local OnReceiveMessage = function(message)    
    CCLuaLog("RAScenesMananger OnReceiveMessage id:"..message.messageID)
    
    if message.messageID == MessageDef_ScenesMananger.MSG_AddCmdData then
        CCLuaLog("MessageDef_ScenesMananger MSG_AddCmdData")
        local sceneType = message.sceneType
        local cmdType = message.cmdType
        local cmdData = message.cmdData
        RAScenesMananger.AddSceneCmd(sceneType, cmdType, cmdData)
    elseif message.messageID == MessageDef_Lord.MSG_LevelUpgrade then
        local RALordUpgradeManager = RARequire("RALordUpgradeManager")
        local flag = RALordUpgradeManager:hasUnclaimedReward()
        if flag then
            local RARootManager = RARequire("RARootManager")
            local RAGuideManager = RARequire("RAGuideManager")--在新手期间不弹升级页面
            if RAGuideManager.isInGuide() then
                return
            end
            RARootManager.OpenPage("RALordUpgradePage",nil,true,true,true)
        end
    elseif message.messageID == MessageDef_MainState.SwitchUser then
        local RALoginManager = RARequire("RALoginManager")
        RALoginManager:switchUser()
    end
end

function RAScenesMananger.registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_LevelUpgrade, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_ScenesMananger.MSG_AddCmdData, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainState.SwitchUser, OnReceiveMessage)
end

function RAScenesMananger.unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_LevelUpgrade, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_ScenesMananger.MSG_AddCmdData, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainState.SwitchUser, OnReceiveMessage)
end


function RAScenesMananger.AddWorldLocateCmdByXY(x, y, hudBtn)
	local RARootManager = RARequire('RARootManager')
	local RAScenesConfig = RARequire('RAScenesConfig')
    local cmdData = {x = x, y = y, hudBtn = hudBtn}
    RAScenesMananger.AddSceneCmd(SceneTypeList.WorldScene, RAScenesConfig.CMD_WorldScene.Locate_Tile, cmdData)
end

function RAScenesMananger.AddWorldLocateCmdByMarchId(marchId, isChangeScene)
	local RARootManager = RARequire('RARootManager')
	local RAScenesConfig = RARequire('RAScenesConfig')
    local cmdData = {marchId = marchId}
    RAScenesMananger.AddSceneCmd(SceneTypeList.WorldScene, RAScenesConfig.CMD_WorldScene.Locate_Tile, cmdData)
    if isChangeScene then
    	RARootManager.ChangeScene(SceneTypeList.WorldScene)
    end
end

--desc:任务引导相关操作
function RAScenesMananger.addWorldLocateCmdByTaskType(taskType, targetLevel, targetType)
    local RARootManager = RARequire('RARootManager')
	local RAScenesConfig = RARequire('RAScenesConfig')
    local cmdData = {taskType = taskType, targetLevel = targetLevel, targetType = targetType}
    RAScenesMananger.AddSceneCmd(SceneTypeList.WorldScene, RAScenesConfig.CMD_WorldScene.Locate_Tile, cmdData)
end


function RAScenesMananger.GetWorldLocateCmdData()
	local RAScenesConfig = RARequire('RAScenesConfig')
	local rt = RAScenesMananger.GetSceneCmd(SceneTypeList.WorldScene, RAScenesConfig.CMD_WorldScene.Locate_Tile)
	return rt
end

function RAScenesMananger.RemoveWorldSceneCmd()
	local RARootManager = RARequire('RARootManager')
    RAScenesMananger.RemoveSceneCmd(SceneTypeList.WorldScene)
end

-------------------------------------------------------
return RAScenesMananger
