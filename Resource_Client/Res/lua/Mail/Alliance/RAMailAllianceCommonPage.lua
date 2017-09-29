
	--联盟邮件:
	--[[
	
	 { 
	   集结解散，集结失败,激活堡垒已变更，超级矿种类变更，核武器攻击投票，闪电风暴攻击投票，核武器攻击确认，闪电风暴攻击确认，核武器攻击取消，闪电风暴攻击取消
	   联盟堡垒攻占成功,联盟堡垒失守,成功夺回联盟堡垒，未能守住联盟堡垒，已同意加入联盟，入盟申请被拒绝，
	   逐出联盟，联盟阶级变更,基地迁移邀请，红包未开启，红包无人开启,红包被开启，你是幸运儿
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
local RAMailAllianceCommonPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id
      mailInfo =RAMailManager:getMailById(id)

      RAMailAllianceCommonPage:updateInfo(mailInfo)
   
    end
end
-----------------------------------------------------------

function RAMailAllianceCommonPage:Enter(data)


	CCLuaLog("RAMailAllianceCommonPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailAllianceCmnPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
    self:registerMessageHandler()
    self:init()
    
end
function RAMailAllianceCommonPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailAllianceCommonPage:init()

	
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

function RAMailAllianceCommonPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailAllianceCommonPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailAllianceCommonPage:updateInfo(mailInfo)


	--寄件者头像
	local iconId = mailInfo.icon[1]
	local RAAllianceUtility = RARequire('RAAllianceUtility')
	local icon=RAAllianceUtility:getAllianceFlagIdByIcon(iconId)
	if icon then
		local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mAllianceIconNode")
 		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end


	--time
	local mailTime = math.floor(mailInfo.ctime/1000)
	mailTime=RAMailUtility:formatMailTime(mailTime)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",mailTime)

	 --title and subTitle
 	local configId = mailInfo.configId
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
			params = self:refreshParamsData(params)
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
		if  paramsContent then
			local params=RAStringUtil:split(paramsContent, "_")
			params = self:refreshParamsContData(params)
			htmlHrefStr = _RAHtmlFill(contentkeyStr,params[1],params[2],params[3],params[4],params[5],params[6],params[7],params[8],params[9],params[10]) 
		else
			htmlHrefStr = _RAHtmlLang(contentkeyStr)
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
function RAMailAllianceCommonPage:refreshParamsData(params)
	if self.configId==2011111 then
		--联盟等级变更
		--0未改(等级) 1已改
		local t1=RAStringUtil:split(params[1], ":")
		if t1[1]=="0" then
			local key= 'L' .. t1[2] .. 'Name' 
			params[1]= _RALang('@Default' .. key)
		else
			params[1]= t1[2]
		end 

	elseif self.configId==2011121 then
		--富资源点变更
		local super_mine_conf = RARequire("super_mine_conf")
		local info = super_mine_conf[tonumber(params[1])]
		params[1]= _RALang(info.name)
	elseif  self.configId==2011044 or  self.configId==2011045 then
		--联盟堡垒占领中 被占领中
		local guild_const_conf = RARequire("guild_const_conf")
		local time = guild_const_conf["guildManorOccupyTime"].value/3600

		time=RAMailUtility:getDotNumBy(time,3)
		params[2]=time
	end
	return params
end 

function RAMailAllianceCommonPage:refreshParamsContData(params)
	if self.configId==2011111 then
		--联盟等级变更
		--0未改(等级) 1已改
		local t1=RAStringUtil:split(params[1], ":")
		if t1[1]=="0" then
			local key= 'L' .. t1[2] .. 'Name' 
			params[1]= _RALang('@Default' .. key)
		else
			params[1]= t1[2]
		end 

		local t2=RAStringUtil:split(params[2], ":")
		if t2[1]=="0" then
			local key= 'L' .. t2[2] .. 'Name' 
			params[2]= _RALang('@Default' .. key)
		else
			params[2]= t2[2]
		end 

	elseif self.configId==2011121 then
		--富资源点变更
		local super_mine_conf = RARequire("super_mine_conf")
		local info = super_mine_conf[tonumber(params[1])]
		params[1]= _RALang(info.name)

		info = super_mine_conf[tonumber(params[2])]
		params[2]= _RALang(info.name)
	elseif (self.configId>=2011041 and self.configId<=2011045) or self.configId==2011051 or self.configId==2011052  or self.configId==2011061 then 
		--联盟堡垒攻占成功 联盟堡垒失守 成功夺回联盟堡垒 未能守住联盟堡垒 联盟堡垒变更
		local territoryId=params[1]
		local territory_guard_conf = RARequire("territory_guard_conf")
		local info = territory_guard_conf[tonumber(territoryId)]
		local icon=info.icon
		params[1] =icon

	end
	return params
end 


function RAMailAllianceCommonPage:registerHtmlCCB(mailInfo)
	local paramsContent = mailInfo.msg
	if not paramsContent then
		return 
	end 
	local params=RAStringUtil:split(paramsContent, "_")
	if self.configId==2011151 or self.configId==2011161 then
		--核武器攻击投票，闪电风暴攻击投票
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
	elseif  self.configId==2011152 or self.configId==2011162 then
		--核武器攻击确认，闪电风暴攻击确认  ， 3个一样的CCB
		local baseId = RAMailConfig.CCB.RAMailCmmCell1.id
		local ids={baseId.."_1",baseId.."_2",baseId.."_3"}
		local index=1
		for i=1,#ids do
			local id = ids[i]
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			self:refreshRAMailCommonCell1V6(htmlCCBFile,params[index],params[index+1],params[index+2])
			index = index+3
		end
	
	elseif self.configId==2011163 or self.configId==2011153 then
		--闪电风暴攻击取消 --核武器攻击取消
		local baseId = RAMailConfig.CCB.RAMailCmmCell1.id
		-- local ids={baseId.."_1",baseId.."_2",baseId.."_3",baseId.."_4"}
		-- local index=1
		-- for i=1,#ids do
		-- 	local id = ids[i]
		-- 	local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		-- 	self:refreshRAMailCommonCell1V6(htmlCCBFile,params[index],params[index+1],params[index+2])
		-- 	index = index+4
		-- end
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(baseId)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[1],params[2],params[3])
	elseif (self.configId>=2011041 and self.configId<=2011045) or self.configId==2011051 or self.configId==2011052  then 
		--联盟堡垒攻占成功 联盟堡垒失守 成功夺回联盟堡垒 未能守住联盟堡垒
		local id = RAMailConfig.CCB.RAMailCmmCell2.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell2V6(htmlCCBFile,params[4],params[5],params[6],params[7])
	elseif self.configId==2011181 then
		--基地迁城邀请  
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[3],params[4],params[5])
	end

end

function RAMailAllianceCommonPage:refreshRAMailCommonCell1V6(htmlCCBFile,iconId,name,level)
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

	if level then
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",_RALang("@MailCellLevel",level))
	end 
	
end

function RAMailAllianceCommonPage:refreshRAMailCommonCell2V6(htmlCCBFile,iconId,allianceName,battle,ownName)
	if not htmlCCBFile then return end 
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

function RAMailAllianceCommonPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailAllianceCommonPage)
	
end

function RAMailAllianceCommonPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailAllianceCommonPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailAllianceCommonPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailAllianceCommonPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

