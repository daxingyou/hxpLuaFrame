--RARootManager message part
--manage raroot.ccbi for game
RARequire("MessageManager")

local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")

local OnReceiveMessage = nil

function RARootManager.registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_OpenPage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_CommonRefreshPage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ClosePage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_CutScene, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_GotoLastPage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ReturntoLastPage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_SceneShake, OnReceiveMessage)    
end

function RARootManager.unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_OpenPage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_CommonRefreshPage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ClosePage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_CutScene, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_GotoLastPage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ReturntoLastPage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_SceneShake, OnReceiveMessage)
end

function RARootManager.refreshPage(pageName,pageArg)
    local message = {}
    message.pageName = pageName
    message.pageArg = pageArg or nil
    MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage,message)
end

function RARootManager.showErrorCode(errorCode,windowType)
    if windowType == nil then windowType = 1 end
    local RAStringUtil = RARequire("RAStringUtil")
    if windowType == 1 then
        local errorStr = RAStringUtil:getErrorString(errorCode)
        RARootManager.ShowMsgBox(errorStr)
    else
        local errorStr = RAStringUtil:getErrorString(errorCode)
        RARootManager.OpenPage("RAConfirmPage", {labelText = errorStr})
    end
    
end

function RARootManager.showPackageInfoPopUp(data)
    -- body
    RARootManager.OpenPage("RAPackageInfoPopUp", data, false, true, true)
end

function RARootManager.showConfirmMsg(data)

    RARootManager.OpenPage("RAConfirmPage", data,true,true,true)
end

function RARootManager.showFinishNowPopUp(data)
    -- body
    RARootManager.OpenPage("RAFinishNowPopUp", data,true,true,true)
end

--道具使用界面
--type:是哪种类型道具
function RARootManager.showCommonGainItemPage(type, marchId)    
    local RACommonGainItemData = RARequire('RACommonGainItemData')
    local data = {itemType=type}
    data.marchId = marchId
    if type == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate or 
        type == RACommonGainItemData.GAIN_ITEM_TYPE.marchCallBack then

        MessageManager.sendMessage(MessageDef_World.MSG_OpenMarchUseItemPage, {marchId = marchId})
        RARootManager.OpenPage("RAMarchItemUsePage", data, true, true, true)
    else
        RARootManager.OpenPage("RACommonGainItemUIPage", data, false)
    end    
end

function RARootManager.showCommonItemsSpeedUpPopUp(data)
    -- body
    local RACoreDataManager = RARequire("RACoreDataManager")
    local itemsInfo = RACoreDataManager:getAccelerateDataByType(data.queueType)
	if not itemsInfo or not next(itemsInfo) then 
        --道具不足提示使用钻石加速
        --local RAQueueUtility = RARequire('RAQueueUtility')
        --RAQueueUtility.showSpeedupByGoldWindow(data)
        RARootManager.showFinishNowPopUp(data)
	else
        RARootManager.OpenPage("RACommonItemsSpeedUpPopUp", data,true,true,true)
	end
end

OnReceiveMessage = function(message)    
    CCLuaLog("RARootManager_Msg OnReceiveMessage id:"..message.messageID)

    -- refresh page
    if message.messageID == MessageDef_RootManager.MSG_CommonRefreshPage then
        CCLuaLog("RARootManager_Msg OnReceiveCommonRefresh page name:"..message.pageName)
        local k,pageHandler = RARootManager.checkPageLoaded(message.pageName)
        if pageHandler ~= nil and pageHandler.CommonRefresh ~= nil then
            pageHandler:CommonRefresh(message)
        end
    -- -- open page
    elseif message.messageID == MessageDef_RootManager.MSG_OpenPage then
        RARootManager._OpenPage(message.pageName, 
            message.pageArg, 
            message.isUpdate, 
            message.needNotToucherLayer, 
            message.isBlankClose,
            message.swallowTouch)
    -- -- close page
    elseif message.messageID == MessageDef_RootManager.MSG_ClosePage then
        if message.isCloseAll then
            return RARootManager._CloseAllPages(message.clearStack)
        end

        if message.isCloseCur then            
            return RARootManager._CloseCurrPage()
        end

        if message.pageName ~= nil then
            return RARootManager._ClosePage(message.pageName, message.isPopSelf, message.isClear,message.pageArg)
        end

    -- cut scene
    elseif message.messageID == MessageDef_RootManager.MSG_CutScene then
        local progress = message.progress
        CCLuaLog("get progress:"..progress)
        if progress == 0 then
            RARootManager._CutSceneBegin()
        elseif progress == 1 then
            RARootManager._CutSceneEnd()
        end
    elseif message.messageID == MessageDef_RootManager.MSG_GotoLastPage then
        RARootManager._GotoLastPage()
    elseif message.messageID == MessageDef_RootManager.MSG_ReturntoLastPage then
        RARootManager._ReturntoLastPage()
    elseif message.messageID == MessageDef_RootManager.MSG_SceneShake then
        RARootManager._ShakeSceneNode()
    end
end


