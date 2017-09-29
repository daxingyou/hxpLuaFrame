RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAVIPDataManager = RARequire("RAVIPDataManager")
local RANetUtil = RARequire("RANetUtil")

local RAVIPActiveReminderPopup = BaseFunctionPage:new(...)
local RAVIPActiveReminderPopupHandler = {}

function RAVIPActiveReminderPopup:Enter(data)
	self.ccbfile =  UIExtend.loadCCBFile("RAVIPTipsPopUp.ccbi", RAVIPActiveReminderPopup)
	
	
	--请求排行数据，初次请求排行领主战力排行
	self:LoadVIPData()
	self:initVIPLevelContent()
	self:registerHandler()
	self:AddNoTouchLayer(true)
end

--初始化等级滑动面板
function RAVIPActiveReminderPopup:initVIPLevelContent()
	self:initVIPDetailContent()
end

----初始化该等级详细选项
function RAVIPActiveReminderPopup:initVIPDetailContent()
	
end

--请求VIP数据，设置等待窗口
function RAVIPActiveReminderPopup:LoadVIPData()
	RAVIPDataManager.initConfig()
	local playerData=RAVIPDataManager.getPlayerData()
	local level=playerData.vipLevel
	local lastReminderTimeKey=RAVIPDataManager.Object.LastVIPReminderTimeKey
	local lastLoginTime=playerData.lastLoginTime/1000
	--record lastReminderTime
	CCUserDefault:sharedUserDefault():setIntegerForKey(lastReminderTimeKey, lastLoginTime);
    UIExtend.setCCLabelString(self.ccbfile, "mVIPNum","VIP"..tostring(level))
	
	local currVIPIndex=RAVIPDataManager.Object.currShowVIPLevel
	local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(currVIPIndex)
	if currVIPConfig then
		local vipAttrConfig=RAVIPDataManager.getVIPAttrConfig()
		if 	vipAttrConfig~=nil then
			local i=1
			for k,v in pairs(vipAttrConfig) do
				if v~=nil then
					UIExtend.setCCLabelString(self.ccbfile, "mKeyNum"..tostring(i), tostring(v.columnValue))
					UIExtend.setCCLabelString(self.ccbfile, "mValueNum"..tostring(i),RAVIPDataManager.getVIPConfigValueSymbol(currVIPConfig,v))
					i=i+1
				end
			end
		end
	end
end

function RAVIPActiveReminderPopup:onNotActivatedBtn()
	self:onCloseBtn()
end

function RAVIPActiveReminderPopup:onActivationBtn()
	RAVIPDataManager.Object.currShowVIPLevel=RAVIPDataManager.getPlayerData().vipLevel
	RARootManager.OpenPage("RAVIPUseToolsPage",nil,true)
	RAVIPActiveReminderPopup:onCloseBtn()
end

function RAVIPActiveReminderPopup:addHandler()
	RAVIPActiveReminderPopupHandler[#RAVIPActiveReminderPopupHandler +1] = RANetUtil:addListener(HP_pb.RANK_INFO_S, RAVIPActiveReminderPopup)
end

function RAVIPActiveReminderPopup:removeHandler()
	for k, value in pairs(RAVIPActiveReminderPopupHandler) do
		if RAVIPActiveReminderPopupHandler[k] then
			RANetUtil:removeListener(RAVIPActiveReminderPopupHandler[k])
			RAVIPActiveReminderPopupHandler[k] = nil
		end
	end
	RAVIPActiveReminderPopupHandler = {}
end

--注册客户端消息分发
function RAVIPActiveReminderPopup:registerHandler()
	RAVIPActiveReminderPopup:addHandler()
end

--移除客户端消息分发注册
function RAVIPActiveReminderPopup:unRegiterHandler()
	RAVIPActiveReminderPopup:removeHandler()
end

--接收服务器包，转到背包去吧
function RAVIPActiveReminderPopup:onReceivePacket(handler)
	RARootManager.RemoveWaitingPage()
	local pbCode = handler:getOpcode()
	local buffer = handler:getBuffer()
	--todo
end

--关闭按钮
function RAVIPActiveReminderPopup:onCloseBtn()
	MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
	RARootManager.ClosePage("RAVIPActiveReminderPopup")
end

--退出页面
function RAVIPActiveReminderPopup:Exit(data)
	self:onCloseBtn()
	self:unRegiterHandler()
	UIExtend.unLoadCCBFile(RAVIPActiveReminderPopup)
	self.ccbfile = nil
end