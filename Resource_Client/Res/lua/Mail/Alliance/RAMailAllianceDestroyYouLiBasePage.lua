
--联盟：摧毁尤里基地
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
local RAMailAllianceDestroyYouLiBasePage = BaseFunctionPage:new(...)


local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id
      mailInfo =RAMailManager:getMailById(id)

      RAMailAllianceDestroyYouLiBasePage:updateInfo(mailInfo)
   
    end
end

-----------------------------------------------------------

function RAMailAllianceDestroyYouLiBasePage:Enter(data)


	CCLuaLog("RAMailAllianceDestroyYouLiBasePage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailCommonPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailAllianceDestroyYouLiBasePage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailAllianceDestroyYouLiBasePage:init()

	
	-- UIExtend.setCCLabelString(self.ccbfile,"mApplicationExplain","")
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel","")
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mAllianceHTMLLabel","",615,"center")

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	UIExtend.setCCLabelString(titleCCB,"mTitle","")

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

function RAMailAllianceDestroyYouLiBasePage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailAllianceDestroyYouLiBasePage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailAllianceDestroyYouLiBasePage:updateInfo(mailInfo)


	
	--time
	local mailTime = math.floor(mailInfo.ctime/1000)
	mailTime=RAMailUtility:formatMailTime(mailTime)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",mailTime)

	 --title and subTitle
 	local configId = mailInfo.configId
 	self.configId = configId
 	local configData = RAMailUtility:getNewMailData(configId)

 	local mailBanner = configData.mailBanner
	local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	if render and mailBanner then
		render:setTexture(mailBanner)
	end

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


		UIExtend.setCCLabelString(self.titleCCB,"mTitle",titleStr)


		--content
		local paramsContent = mailInfo.msg
		local contentkeyStr = configData.content
		local htmlHrefStr=nil
		if paramsContent then
			local params=RAStringUtil:split(paramsContent, "_")
			htmlHrefStr = _RAHtmlFill(contentkeyStr,params[1],params[2],params[3],params[4],params[5]) 
		else
			htmlHrefStr = _RAHtmlLang(configData.content)
		end
		UIExtend.setCCLabelHTMLString(self.ccbfile,"mAllianceHTMLLabel",htmlHrefStr,615,"center")


		--定义超链接
		local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mAllianceHTMLLabel")
		self.mHtmlLabel = htmlLabel
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



function RAMailAllianceDestroyYouLiBasePage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailAllianceDestroyYouLiBasePage)
	
end

function RAMailAllianceDestroyYouLiBasePage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailAllianceDestroyYouLiBasePage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailAllianceDestroyYouLiBasePage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailAllianceDestroyYouLiBasePage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end