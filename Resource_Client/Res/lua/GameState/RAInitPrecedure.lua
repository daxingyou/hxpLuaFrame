local RAInitPrecedure = {}
package.loaded[...] = RAInitPrecedure

local common = RARequire("common")
-- local mFrameNum = 0
function RAInitPrecedure.Enter()
    --logTime
    local Utilitys = RARequire("Utilitys")
    Utilitys.LogCurTime("RAInitPrecedure.Enter Enter To RAInitPrecedure")

    -- mFrameNum = 0
    --init the global listner

    local RAGlobalListener = RARequire('RAGlobalListener')
    RAGlobalListener.init()
    GameStateMachine.setStateListener(dynamic_require('RAGlobalListener'))
     
    local RAGameConfig = RARequire("RAGameConfig")
    if RAGameConfig.BattleDebug == 1 then 
        RAInitPrecedure._initLuaPreloadTest()
        RAInitPrecedure._initResourcePreloadTest()
    else
        RAInitPrecedure._initLuaPreload()
        RAInitPrecedure._initResourcePreload()
    end
end

--战斗调试加载
function RAInitPrecedure._initLuaPreloadTest()
    RAInitPrecedure.initLuaTable = {
        function ()
            RARequire("BasePage")
        end,
        function()
            RARequire("RAStringUtil"):setLanguage()
        end,
        function()
            local mainState = RARequire("RAGameMainState")
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.changeState(RAGameLoadingStatus.LoginFinish)
            GameStateMachine.ChangeState(mainState)
        end,
    }
end    

--preload the lua
function RAInitPrecedure._initLuaPreload()
    --init the other config
    RAInitPrecedure.initLuaTable = {
        function ()
            --logTime
            local Utilitys = RARequire("Utilitys")
            Utilitys.LogCurTime("RAInitPrecedure._initLuaPreload Start To Preload Lua")

            RARequire("RANetUtil")
        end,
        function ()
            RARequire("RALoginManager")
        end,
        function ()
            RARequire("BasePage")
        end,
        function()
            RARequire("RAStringUtil"):setLanguage()
        end,
        function()
            --Ìí¼ÓpushÐÅÏ¢¼àÌý£¬²»»áÊÍ·Å
            local RAProtoPushLogic = RARequire("RAProtoPushLogic")
            RAProtoPushLogic:removePushProto();
            RAProtoPushLogic:registerPushProto();
        end,
        function()
            RARequire("RAPushRemindPageManager"):init()
        end,
        function()
            RARequire("RALoginPrecedure"):Enter()
        end,
        function()
            RARequire("RAGameLoadingState").changeState(RAGameLoadingStatus.LoginServer)
            RALogRelease("RAGameLoadingState  send login percent 100%")

            --logTime
            local Utilitys = RARequire("Utilitys")
            Utilitys.LogCurTime("RAInitPrecedure._initLuaPreload End To Preload Lua")
        end
    }
end

--preload the resource
function RAInitPrecedure._initResourcePreloadTest()
    RAInitPrecedure.initResourceTable = {
        function ()
            local RAGameConfig = RARequire("RAGameConfig")

            if RAGameConfig.BattleDebug == 1 then 
                RAImageSetManager:getInstance():init('Res/txt/Imageset_test.json')
            else
                RAImageSetManager:getInstance():init('Res/txt/Imageset.json')
            end 
        end,
    }
end

--preload the resource
function RAInitPrecedure._initResourcePreload()
    RAInitPrecedure.initResourceTable = {
        function ()
            -- TODO
            --logTime
            local Utilitys = RARequire("Utilitys")
            Utilitys.LogCurTime("RAInitPrecedure._initResourcePreload Start To Preload Resource")
            RAImageSetManager:getInstance():init('Res/txt/Imageset.json')
        end,
        function ()
            local RAWorldConfig = RARequire("RAWorldConfig")
            for relation, colorParam in pairs(RAWorldConfig.RelationFlagColor) do
                local colorKey = colorParam.key or 'DefaultColorKeyCCB'
                local r = colorParam.color.r or 255
                local g = colorParam.color.g or 255
                local b = colorParam.color.b or 255
                CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)    
            end  

            --logTime
            local Utilitys = RARequire("Utilitys")
            Utilitys.LogCurTime("RAInitPrecedure._initResourcePreload End To Preload Resource")          
        end,
    }
end

function RAInitPrecedure.Execute()
    local RALoginPrecedure = RARequire("RALoginPrecedure")
    RALoginPrecedure:Execute()
    -- mFrameNum = mFrameNum + 1

    if RAInitPrecedure.initResourceTable ~= nil and #RAInitPrecedure.initResourceTable > 0   then
        local func = table.remove(RAInitPrecedure.initResourceTable,1)
        --CCLuaLog("RAInitPrecedure.Execute() i = "..mFrameNum,true)
        return func()
    end

    if RAInitPrecedure.initLuaTable ~= nil and #RAInitPrecedure.initLuaTable > 0   then
        local func = table.remove(RAInitPrecedure.initLuaTable,1)
        --CCLuaLog("RAInitPrecedure.Execute() i = "..mFrameNum,true)
        return func()
    end
end

function RAInitPrecedure.Exit()
    local RALoginPrecedure = RARequire("RALoginPrecedure")
	RALoginPrecedure:Exit()
    --RAUnload("RARootManager")
end

