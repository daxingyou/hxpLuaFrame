
-- 战斗邮件：战斗失败(跟联盟统一模板)，

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
local RAMailPlayerFightFailPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id
      mailInfo =RAMailManager:getMailById(id)

      RAMailPlayerFightFailPage:updateInfo(mailInfo)
   
    end
end
-----------------------------------------------------------

function RAMailPlayerFightFailPage:Enter(data)


	CCLuaLog("RAMailPlayerFightFailPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailAllianceCmnPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailPlayerFightFailPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailPlayerFightFailPage:init()

	
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

function RAMailPlayerFightFailPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailPlayerFightFailPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailPlayerFightFailPage:updateInfo(mailInfo)


	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId
	local configData = RAMailUtility:getNewMailData(configId)

	--头像
	local iconId=mailInfo.icon[1]
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
 	self.configId = configId
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

		--content
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

function RAMailPlayerFightFailPage:registerHtmlCCB(mailInfo)
	local paramsContent = mailInfo.msg
    if not paramsContent then
       return 
    end
	local params=RAStringUtil:split(paramsContent, "_")
	if self.configId>=2012085 and self.configId<=2012088 then
		--攻击基地失败
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
	elseif  self.configId==2012095 or self.configId==2012096 then
		--攻击资源点失败
		local resId = params[1]
        --资源点：资源图片等级名字
		if resId then
			local id = RAMailConfig.CCB.RAMailCmmCell4.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local RAWorldConfigManager = RARequire("RAWorldConfigManager")
			local resConf,resShow=RAWorldConfigManager:GetResConfig(tonumber(resId))
			local icon = resConf.resTargetIcon
			local name = _RALang(resShow.resName)
			local level = resConf.level

			local keyStr ="MailCell4V61" 
			local htmlStr = _RAHtmlLang(keyStr,name,level)

			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 
	elseif self.configId==2012105 then
		--攻击驻扎点失败
		local name = params[1]

        --驻扎点: 驻扎图片 名字（玩家）
		if name then
			local id = RAMailConfig.CCB.RAMailCmmCell4.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local icon = RAMailConfig.StationIcon
			local keyStr ="MailCell4V62" 
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 

	elseif self.configId==2012113 then 
		--攻击尤里基地失败
		local id = RAMailConfig.CCB.RAMailCmmCell4.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		local Id = params[1]
		if Id then
			local RAWorldConfigManager = RARequire("RAWorldConfigManager")
			local info = RAWorldConfigManager:GetStrongholdCfg(tonumber(Id))
			local icon = info.icon
			local name = _RALang(info.armyName)
			local keyStr = "MailCell4V63"
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end
	elseif self.configId==2012126 then
		--攻击联盟堡垒失败

	elseif self.configId==2012135 then
		--攻击首都失败
	elseif self.configId==2012193 then
		--攻击发射平台失败
		
	end

end

function RAMailPlayerFightFailPage:refreshRAMailCommonCell1V6(htmlCCBFile,iconId,name,battle)

	if iconId then
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		local icon = RAMailUtility:getPlayerIcon(iconId)
		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end 
	if name then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellTitle",name)
	end 

	if battle then
		local num = Utilitys.formatNumber(battle)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",_RALang("@MailCellSingleBattle",num))
	end 
	
end

function RAMailPlayerFightFailPage:refreshRAMailCommonCell4V6(htmlCCBFile,iconName,htmlStr)
	if not htmlCCBFile then return end 
	if iconName then
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		UIExtend.addNodeToAdaptParentNode(picNode,iconName,RAMailConfig.TAG)
	end 
	
	if htmlStr then 
		UIExtend.setCCLabelHTMLString(htmlCCBFile,"mLabel",htmlStr,174,"center")
	end 
	
end


function RAMailPlayerFightFailPage:refreshRAMailCommonCell2V6(htmlCCBFile,iconId,allianceName,battle,ownName)

	if iconId then	
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		local RAAllianceUtility = RARequire("RAAllianceUtility")
		local icon =RAAllianceUtility:getAllianceFlagIdByIcon(iconId)
		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end

	if allianceName then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellTitle",allianceName)
	end
	if battle then
		local num = Utilitys.formatNumber(battle)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",_RALang("@MailCellBattle",num))
	end 
	
	if ownName then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel2",ownName)
	end

end


function RAMailPlayerFightFailPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailPlayerFightFailPage)
	
end

function RAMailPlayerFightFailPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailPlayerFightFailPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailPlayerFightFailPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailPlayerFightFailPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end



