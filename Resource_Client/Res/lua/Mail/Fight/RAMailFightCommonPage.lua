	--战斗邮件：
	--[[
		{
			遭到侦查，阻止敌人侦查，敌人侦查失败,
			基地侦查失败,资源点侦查失败，尤里基地侦查失败，驻扎点侦查失败，伤兵死亡
		}

	]]


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
local RAMailFightCommonPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id
      mailInfo =RAMailManager:getMailById(id)

      RAMailFightCommonPage:updateInfo(mailInfo)
   
    end
end
-----------------------------------------------------------

function RAMailFightCommonPage:Enter(data)


	CCLuaLog("RAMailFightCommonPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailCommonPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailFightCommonPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailFightCommonPage:init()

	
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


	--banner 
	local configId = mailInfo.configId
 	local configData = RAMailUtility:getNewMailData(configId)
	local mailBanner = configData.mailBanner
	local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	render:setTexture(mailBanner)


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
function RAMailFightCommonPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailFightCommonPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailFightCommonPage:updateInfo(mailInfo)



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

function RAMailFightCommonPage:registerHtmlCCB(mailInfo)
	local paramsContent = mailInfo.msg
	if not paramsContent then
		return 
	end 
	local params=RAStringUtil:split(paramsContent, "_")
	if self.configId==2012022 then
		--基地被侦查
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
 
	elseif self.configId==2012032 then
		--资源点被侦查
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])

		local resId = params[6]

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

	elseif self.configId==2012042 then
		--驻扎点被侦查
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])

		local name = params[6]

        --驻扎点: 驻扎图片 名字（玩家）
		if name then
			local id = RAMailConfig.CCB.RAMailCmmCell4.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local icon = RAMailConfig.StationIcon
			local keyStr ="MailCell4V62" 
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 


	elseif self.configId==2012052 then
		--首都被侦查
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])

	elseif self.configId==2012072 then
		--联盟堡垒被侦查
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])

		local territoryId= params[6]
        --堡垒:堡垒图片 名字
		if territoryId then
			local id = RAMailConfig.CCB.RAMailCmmCell4.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local territory_guard_conf = RARequire("territory_guard_conf")
			local info = territory_guard_conf[tonumber(territoryId)]
			local icon=info.icon
			local name = _RALang(info.armyName)
			local keyStr = "MailCell4V63"
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 

	elseif self.configId>=2012023 and  self.configId<=2012028 then
		 
		--基地侦查失败，已阻止敌人侦查，敌人侦查失败
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
	elseif  self.configId==2012033 or self.configId==2012034  then
		--资源点侦查失败
		local id = RAMailConfig.CCB.RAMailCmmCell4.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)

		local resId = params[1]
		if resId then
			local RAWorldConfigManager = RARequire("RAWorldConfigManager")
			local resConf,resShow=RAWorldConfigManager:GetResConfig(tonumber(resId))
			local icon = resConf.resTargetIcon
			local name = _RALang(resShow.resName)
			local level = resConf.level

			local keyStr ="MailCell4V61" 
			local htmlStr = _RAHtmlLang(keyStr,name,level)

			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 
		
	elseif self.configId==2012043 or self.configId==2012044 then
		--驻扎点侦查失败
		local id = RAMailConfig.CCB.RAMailCmmCell4.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)

		local name = params[1]
		if name then
			local icon = RAMailConfig.StationIcon
			local keyStr ="MailCell4V62" 
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 

	elseif self.configId==2012052 or self.configId==2012053  then 
		--首都侦查失败 
		local id = RAMailConfig.CCB.RAMailCmmCell4.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		local icon=RAMailConfig.CoreIcon
		local name = _RALang("@Capital")
		local keyStr = "MailCell4V63"
		local htmlStr = _RAHtmlLang(keyStr,name)
		self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)


	elseif self.configId==2012062 then
		--尤里基地侦查失败
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
		

	elseif self.configId==2012073 then
		--堡垒侦查失败
		local territoryId= params[1]
		if territoryId then
			local id = RAMailConfig.CCB.RAMailCmmCell4.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local territory_guard_conf = RARequire("territory_guard_conf")
			local info = territory_guard_conf[tonumber(territoryId)]
			local icon=info.icon
			local name = _RALang(info.armyName)
			local keyStr = "MailCell4V63"
			local htmlStr = _RAHtmlLang(keyStr,name)
			self:refreshRAMailCommonCell4V6(htmlCCBFile,icon,htmlStr)
		end 

		
	end

end

function RAMailFightCommonPage:refreshRAMailCommonCell4V6(htmlCCBFile,iconName,htmlStr)
	if not htmlCCBFile then return end 
	if iconName then
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		UIExtend.addNodeToAdaptParentNode(picNode,iconName,RAMailConfig.TAG)
	end 
	
	if htmlStr then 
		UIExtend.setCCLabelHTMLString(htmlCCBFile,"mLabel",htmlStr,174,"center")
	end 
	
end



function RAMailFightCommonPage:refreshRAMailCommonCell1V6(htmlCCBFile,iconId,playerName,battle)
	if not htmlCCBFile then return end 
	if iconId then	
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		local icon = RAMailUtility:getPlayerIcon(iconId)
		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end

	if playerName then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellTitle",playerName)
	end

	if battle then
		local num = Utilitys.formatNumber(battle)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",_RALang("@MailCellSingleBattle",num))
	end 

end


function RAMailFightCommonPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailFightCommonPage)
	
end

function RAMailFightCommonPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailFightCommonPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailFightCommonPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailFightCommonPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

