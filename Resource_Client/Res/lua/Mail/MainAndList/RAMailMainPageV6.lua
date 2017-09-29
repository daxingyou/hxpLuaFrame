--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire("Const_pb")
local HP_pb = RARequire("HP_pb")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig =  RARequire("RAMailConfig")


local TAG = 1000

local RAMailMainPageV6 = BaseFunctionPage:new(...)



local refreshMailOptListMsg =MessageDefine_Mail.MSG_Refresh_MailOptList


local OnReceiveMessage = function(message)

    if message.messageID == refreshMailOptListMsg then 
    	RAMailMainPageV6:refreshNewNum()
    end
end



function RAMailMainPageV6:Enter(data)


	CCLuaLog("RAMailMainPageV6:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailMainPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	self:registerMessageHandler()
	self:init()

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner")
    
end

function RAMailMainPageV6:init()

	--标题
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@Mail"))
	UIExtend.setNodeVisible(titleCCB,"mWirteNode",true)

	UIExtend.setCCLabelString(self.ccbfile,"mMsgLabel5","???????")

	--刷新分栏信息
	self:updateInfo()	
end

-- --邮件类型
-- RAMailConfig.Type={
-- 	PRIVATE 		= 1,	--私人信息
-- 	ALLIANCE 		= 2,	--联盟邮件
-- 	FIGHT 			= 3,	--战斗信息
-- 	SYSTEM			= 4,	--系统消息
-- 	ACTIVITY		= 5,	--活动邮件
-- 	MONSTERYOULI	= 6,	--反击尤里
-- 	RESCOLLECT		= 7,	--采集报告

-- }

function RAMailMainPageV6:updateInfo()
	
	-- local baseName = "mIconNode"
	-- for i=1,7 do
	-- 	local nameStr = baseName..i
	-- 	local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,nameStr)
	-- 	local icon = RAMailConfig.Icon[i]
	-- 	UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)
	-- end


	--refresh the new num
	self:refreshNewNum()

end


function RAMailMainPageV6:refreshNewNum()
	local mailTypes={
		RAMailConfig.Type.FIGHT,
		RAMailConfig.Type.PRIVATE,
		RAMailConfig.Type.ALLIANCE,
		RAMailConfig.Type.SYSTEM,
		RAMailConfig.Type.ACTIVITY,
		RAMailConfig.Type.MONSTERYOULI,
		RAMailConfig.Type.RESCOLLECT,
	}

	for i=1,#mailTypes do
		local mailType = mailTypes[i]
		local newNum =  RAMailManager:getNumByMailType(mailType)
	    if newNum==0 then
	    	UIExtend.setNodeVisible(self.ccbfile,"mMsgTipsNode"..i,false)
	    elseif newNum<=99 then 
	    	UIExtend.setNodeVisible(self.ccbfile,"mMsgTipsNode"..i,true)
	    	UIExtend.setCCLabelString(self.ccbfile,"mTipsLabel"..i,_RALang("@MailNewLabel",newNum))	
	    else
	    	UIExtend.setNodeVisible(self.ccbfile,"mMsgTipsNode"..i,true)
	    	UIExtend.setCCLabelString(self.ccbfile,"mTipsLabel"..i,_RALang("@MailNewMaxLabel"))	
	    end

	end

end

function RAMailMainPageV6:mCommonTitleCCB_onCmnTitleEditBtn()
	RARootManager.OpenPage("RAMailWritePage")
end
function RAMailMainPageV6:registerMessageHandler()
  
    MessageManager.registerMessageHandler(refreshMailOptListMsg,OnReceiveMessage)
end

function RAMailMainPageV6:removeMessageHandler()
    MessageManager.removeMessageHandler(refreshMailOptListMsg,OnReceiveMessage)
end


function RAMailMainPageV6:Exit()

    self:removeMessageHandler()
    RAMailManager:Exit()
	UIExtend.unLoadCCBFile(RAMailMainPageV6)
	
    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner_back")
end

function RAMailMainPageV6:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailMainPageV6:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailMainPageV6:mCommonTitleCCB_onWriteBtn()
	RARootManager.OpenPage("RAMailWritePage")
end

--战斗邮件
function RAMailMainPageV6:onMsgBtn1()
	local mailType = RAMailConfig.Type.FIGHT
	local title = _RALang("@FightInformation")
	RAMailManager:goToListPage(mailType,title)
end

--私人邮件
function RAMailMainPageV6:onMsgBtn2()
	local mailType = RAMailConfig.Type.PRIVATE
	local title = _RALang("@PrivateMails")
	RAMailManager:goToListPage(mailType,title)
end

--联盟邮件
function RAMailMainPageV6:onMsgBtn3()
	local mailType = RAMailConfig.Type.ALLIANCE
	local title = _RALang("@AllianceInfomation")
	RAMailManager:goToListPage(mailType,title)
end

--系统邮件
function RAMailMainPageV6:onMsgBtn4()
	local mailType = RAMailConfig.Type.SYSTEM
	local title = _RALang("@SystemMessage")
	RAMailManager:goToListPage(mailType,title)
end
--活动邮件
function RAMailMainPageV6:onMsgBtn5()

	local str = _RALang("@NoOpenTips")
	RARootManager.ShowMsgBox(str)
	-- local mailType = RAMailConfig.Type.ACTIVITY
	-- RAMailUtility:goToListPage(mailType)
end
--反击尤里报告
function RAMailMainPageV6:onMsgBtn6()
	local mailType = RAMailConfig.Type.MONSTERYOULI
	local title = _RALang("@MonsterYouliFight")
	RAMailManager:goToListPage(mailType,title)
end
--采集报告
function RAMailMainPageV6:onMsgBtn7()
	-- body
	--_RALang("@CollectReport")
	RARootManager.OpenPage("RAMailResourceCollectPage")
end
