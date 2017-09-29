local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RA_Common = RARequire("common")

--这个管理类干啥的？
--用来管理各种乱七八糟登录条件下弹出的页面，是否是一定是登陆后？这个不一定
--比如登录弹出好多个页面的时候，让这些页面有序的，有管理逻辑的进行一个个弹
--目前还比较简单，如果有必要可以追加管理配置文件，让策划同学自行管理和配置

local RAPushRemindPageManager = {
    Pages           = {},
    isInit          = false,
    containsPage    = false
}
package.loaded[...] = RAPushRemindPageManager


--如存在配置文件，可以加载配置
function RAPushRemindPageManager.init()
	RAPushRemindPageManager.registerHandler()
end

function RAPushRemindPageManager.calcVIPReminderStatus()

    local RAVIPDataManager = RARequire("RAVIPDataManager")
	local player=RAVIPDataManager.getPlayerData()
	if player==nil then
		return
	end
	
	local level=player.vipLevel
	local endTime=tonumber(player.vipEndTime)/1000
	local currTime=RA_Common:getCurTime()

	local lastReminderTimeKey=RAVIPDataManager.Object.LastVIPReminderTimeKey
	local lastReminderTime=CCUserDefault:sharedUserDefault():getIntegerForKey(lastReminderTimeKey,0)

    --暂未使用
	--local lastActiveTimeKey=RAVIPDataManager.Object.lastVIPActiveTimeKey
	--local lastActiveTimeKey=CCUserDefault:sharedUserDefault():getIntegerForKey(lastActiveTimeKey,0)
    
    --当前VIP未激活，且失效后从未提醒时，给予一次VIP失效提醒
	if endTime<currTime and lastReminderTime<endTime then
		RAPushRemindPageManager.pushPage("RAVIPActiveReminderPopup")
	end
end

--push一个要弹出的页面队列
--尽可能的不要传条件，如果是压入了 就要是能弹得，
function RAPushRemindPageManager.pushPage(pageName,condition)
	local pageContent={}
	pageContent.pageName=pageName
	if condition~=nil then
		pageContent.condition=condition
	end
	if pageName~=nil then
		table.insert(RAPushRemindPageManager.Pages,pageContent)
        RAPushRemindPageManager.containsPage = true
	end
end

--pop页面队列
function RAPushRemindPageManager.popPage()
    --新手期不做任何弹出
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() then
        return
    else
        RARootManager.RemoveGuidePage()
    end

	--只给一次弹出机会，无论是否符合，都不再考虑
    local pageContent=table.remove(RAPushRemindPageManager.Pages,1)

    --弹出一个页面后设置状态
    if table.maxn(RAPushRemindPageManager.Pages)<=0 then
        RAPushRemindPageManager.containsPage = false
    end

	if pageContent~=nil then
		local canShowPage=true
		if pageContent.condition~=nil then
			--这里用于根据不同的页面编写页面特殊的传参需求
		end
		if canShowPage then
            if pageContent.condition and pageContent.condition.blankClose and pageContent.condition.blankClose == 0 then
			    RARootManager.OpenPage(pageContent.pageName, pageContent.condition, false, true, false)
            else
			    RARootManager.OpenPage(pageContent.pageName, pageContent.condition, false, true, true)
            end
		else
			RAPushRemindPageManager.nextPage()	
		end
	else
		RAPushRemindPageManager.nextPage()
	end
end

function RAPushRemindPageManager.nextPage()
	--以防当前传参出现漏洞，object后面还有其他等待弹出的页面
	if table.maxn(RAPushRemindPageManager.Pages)>0 then
		RAPushRemindPageManager.popPage()
    else
        RAPushRemindPageManager.containsPage = false
	end
end

function RAPushRemindPageManager.dealWithGiftPopupPage()
    local RARealPayManager = RARequire("RARealPayManager")
    local giftItem = RARealPayManager.getGiftItemByLogTimes()
    if giftItem then
        RAPushRemindPageManager.pushPage("RARechargeGiftPage", {data = giftItem, blankClose = 0})
    end
end

function RAPushRemindPageManager.dealWithUpgradePopupPage()
    local RALordUpgradeManager = RARequire("RALordUpgradeManager")
    local flag = RALordUpgradeManager:hasUnclaimedReward()
    if flag then
        local RAGuideManager = RARequire("RAGuideManager")--在新手期间不弹升级页面
        if RAGuideManager.isInGuide() then
            return
        end
        RAPushRemindPageManager.pushPage("RALordUpgradePage", {blankClose = 1})
    end
end

function RAPushRemindPageManager.dailyLoginPagePopupPage()
    local RADailyLoginPage = RARequire("RADailyLoginPage")
    local result = RADailyLoginPage:isReceiveDailyLogin()
    if not result then
        RAPushRemindPageManager.pushPage("RADailyLoginPage",{condition = 1,blankClose = 0})
    end
end

function RAPushRemindPageManager.initPopup()
	if not RAPushRemindPageManager.isInit then
    	--RAPushRemindPageManager.calcVIPReminderStatus()  --to 给腾讯的版本屏蔽
    	--RAPushRemindPageManager.dealWithGiftPopupPage()  --to 给腾讯的版本屏蔽
        RAPushRemindPageManager.dealWithUpgradePopupPage()
        --每日登陆礼包界面
        --RAPushRemindPageManager.dailyLoginPagePopupPage()  --to 给腾讯的版本屏蔽
    	RAPushRemindPageManager.isInit=true
	end
end

local onReceiveMessage = function(message)
    --if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
    if message.messageID == MessageDef_LOGIN.MSG_LoginSuccess then
         RAPushRemindPageManager.initPopup()
    elseif message.messageID == Message_AutoPopPage.MSG_AlreadyPopPage then
        if RAPushRemindPageManager.containsPage then
            --当主基地等级小于一定等级时，需要pop的页面都不处理，因为可能要触发新手
            local RAGameConfig = RARequire("RAGameConfig")
            if RAGameConfig.SwitchGuide == 1 then
                local RABuildManager = RARequire("RABuildManager")
                local RAGuideConfig = RARequire("RAGuideConfig")
                local mainCityLvl = RABuildManager:getMainCityLvl()
                local RAGuideManager = RARequire("RAGuideManager")
                if RAGuideManager.isInGuide() or mainCityLvl < RAGuideConfig.mainCityLevelPopup then
                    return
                end
            end
            RAPushRemindPageManager.nextPage()
        end
    end
end

--切换账号的时候需要清理一些数据
function RAPushRemindPageManager:reset()
    RAPushRemindPageManager.isInit = false
end

function RAPushRemindPageManager.registerHandler()
    MessageManager.registerMessageHandler(MessageDef_LOGIN.MSG_LoginSuccess, onReceiveMessage)
    MessageManager.registerMessageHandler(Message_AutoPopPage.MSG_AlreadyPopPage, onReceiveMessage)

end

function RAPushRemindPageManager.unRegisterHandler()
    MessageManager.removeMessageHandler(MessageDef_LOGIN.MSG_LoginSuccess, onReceiveMessage)
    MessageManager.removeMessageHandler(Message_AutoPopPage.MSG_AlreadyPopPage, onReceiveMessage)

end