
-- 战斗邮件：你已强制撤离(跟联盟统一模板)，
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")

local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local RAMailEvacuationPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id
      mailInfo =RAMailManager:getMailById(id)

      RAMailEvacuationPage:updateInfo(mailInfo)
   
    end
end
-----------------------------------------------------------

function RAMailEvacuationPage:Enter(data)


	CCLuaLog("RAMailEvacuationPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailAllianceCmnPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailEvacuationPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailEvacuationPage:init()

	
	UIExtend.setCCLabelString(self.ccbfile,"mApplicationExplain","")
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel","")
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mAllianceHTMLLabel","",615,"center")

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	UIExtend.setCCLabelString(titleCCB,"mTitle","")

	-- self.SenderItemSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mSenderItemSV")
	local mailInfo =RAMailManager:getMailById(self.id)
	self.mailInfo = mailInfo


	 --判断是否锁定
	self.lock = mailInfo.lock
	 
	
	--判断是否已读
	self.status = mailInfo.status

	

	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		self:updateInfo(mailInfo)
	end 
end

function RAMailEvacuationPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailEvacuationPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailEvacuationPage:updateInfo(mailInfo)

	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId

	local configData = RAMailUtility:getNewMailData(configId)

	--头像
	local iconId=mailInfo.icon
	if iconId then
		local icon = RAMailUtility:getPlayerIcon(iconId)
		local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mAllianceIconNode")
 		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end 


	--time
	local mailTime = math.floor(mailInfo.ctime/1000)
	mailTime=RAMailUtility:formatMailTime(mailTime)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",mailTime)

	 --title and subTitle
 	local configId = mailInfo.configId
    self.configId=configId
 	local configData = RAMailUtility:getNewMailData(configId)

	if configData then

		--title
		local paramsTitle = mailInfo.title 
		local titlekeyStr = configData.mainTitle
		local titleStr = nil
		if paramsTitle then
			local params=RAStringUtil:split(paramsTitle, "_")
			titleStr = _RALangFill(titlekeyStr,params[1],params[2],params[3],params[4],params[5]) 
		else
			titleStr = _RALang(titlekeyStr)
		end

		--subTitle
		local paramsSubTitle = mailInfo.subTitle 
		local subTitlekeyStr = configData.subTitile
		local subTitleStr = nil
		if paramsSubTitle then
			local params=RAStringUtil:split(paramsSubTitle, "_")
			subTitleStr = _RALangFill(subTitlekeyStr,params[1],params[2],params[3],params[4],params[5]) 
		else
			subTitleStr = _RALang(subTitlekeyStr)
		end
		
		UIExtend.setCCLabelString(self.titleCCB,"mTitle",titleStr)
		UIExtend.setCCLabelString(self.ccbfile,"mApplicationExplain",subTitleStr)

		--content 参数以subTitle为主
		local paramsContent = mailInfo.msg
		local contentkeyStr = configData.content
		local htmlHrefStr=nil
		if paramsContent then
			local params=RAStringUtil:split(paramsContent, "_")
			htmlHrefStr = _RAHtmlFill(contentkeyStr,params[1],params[2],params[3],params[4],params[5],params[6],params[7],params[8],params[9],params[10]) 
		else
			htmlHrefStr = _RAHtmlLang(configData.content)
		end
		UIExtend.setCCLabelHTMLString(self.ccbfile,"mAllianceHTMLLabel",htmlHrefStr,615,"center")


		--定义超链接
		local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mAllianceHTMLLabel")
		self.mHtmlLabel = htmlLabel

		--注册CCB
		self:registerHtmlCCB(mailInfo)

		if configData.isLink and configData.isLink == 1 then
			local RAChatManager = RARequire("RAChatManager")
			htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
		end 
	end

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailInfo.id,false)
end
function RAMailEvacuationPage:registerHtmlCCB(mailInfo)
	local paramsContent = mailInfo.msg
	if not paramsContent then
		return 
	end 
	local params=RAStringUtil:split(paramsContent, "_")
	if self.configId==2012011  then
		--强制撤离（被击飞）
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
	
	end

end
function RAMailEvacuationPage:refreshRAMailCommonCell1V6(htmlCCBFile,iconId,name,battle)
	if not htmlCCBFile then return end 
	if iconId then
		htmlCCBFile:setVisible(true)
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		local icon = RAMailUtility:getPlayerIcon(iconId)
		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	else
		htmlCCBFile:setVisible(false)
		return 
	end 
	if name then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellTitle",name)
	end 

	if battle then
		battle = Utilitys.formatNumber(battle)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",_RALang("@MailCellSingleBattle",battle))
	end 
	
end
function RAMailEvacuationPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailEvacuationPage)
	
end

function RAMailEvacuationPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailEvacuationPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailEvacuationPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailEvacuationPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

