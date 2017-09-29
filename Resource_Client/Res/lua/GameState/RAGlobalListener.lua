
local RAGlobalListener = {}
package.loaded[...] = RAGlobalListener

RARequire('MessageManager')
RARequire('EnterFrameMananger')
--RARequire('RAPacketManager')

local RAScenesMananger = RARequire('RAScenesMananger')

function g_MenuClicked(strparam)
    --global menuclick
    -- CCLuaLog("g_MenuClicked"..strparam)
    -- local RABuildManager = RARequire('RABuildManager')
    -- RABuildManager:cacelBuildingSelect() 
    -- MessageManager.sendMessage(MessageDef_Building.MSG_Cancel_Building_Select)
end

--controlSlider move global effect by chenpanhua
function g_ControlSlider_Move_PlayEffect()
    --global player controlSlider effect
    --CCLuaLog("g_ControlSlider_Move_PlayEffect")
    --local common = RARequire("common")
    --common:playEffect("slide")
end

function RAGlobalListener.OnReceiveMessage(message)
    CCLuaLog("RAGlobalListenere id:"..message.messageID)
    if message.messageID == MessageDef_Building.MSG_MainFactory_Levelup then
        --1. 判断升级之后的解锁状态
        local RAChooseBuildManager = RARequire("RAChooseBuildManager")
        local hasUnlock = RAChooseBuildManager:judgeUnlockBuild() 
        if hasUnlock then
            MessageManager.sendMessage(MessageDef_MainUI.MSG_HAS_UNLOCK_BUILD)
        end
    end
end

function RAGlobalListener.init()
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup, RAGlobalListener.OnReceiveMessage)
    RAScenesMananger.Init()
end

function RAGlobalListener:reset()
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup, RAGlobalListener.OnReceiveMessage)
    RAScenesMananger.Exit()
end


function RAGlobalListener.beforeUpdate()
--	if g_isLoadTallTables then
--		TableReader.loadAllTables()
--	end
	MessageManager.update()
	EnterFrameMananger.enterFrame()
    --RAPacketManager.Execute()
    -- RAScenesMananger.Execute()
end

function RAGlobalListener.afterUpdate()
	
end

function RAGlobalListener.beforeEnterBackGround()
	
end

function RAGlobalListener.afterEnterBackGround()

end

function RAGlobalListener.beforeEnterForeground()

end

function RAGlobalListener.afterEnterForeground()

end

function RAGlobalListener.beforePurgeCachedData()

end

function RAGlobalListener.afterPurgeCachedData()

end