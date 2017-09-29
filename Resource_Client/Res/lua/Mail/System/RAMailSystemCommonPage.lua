	--系统消息：
	--[[
		(跟联盟统一模板)
		{
			系统更新，系统通知，补偿奖励，人民币消费，迁城，活动奖励(积分目标，阶段排名，总排名),
			指挥官被拷打，指挥官被解救，指挥官被解救，指挥官基地回到基地，指挥官处决倒数，国王战，
			总统礼包，官员任命，征税
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

local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK

local RAMailSystemCommonPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id

      local systemInfo = mailInfo.commonMail

      local rewards = systemInfo.rewards
      local count = #rewards
      for i=1,count do
      	local reward = rewards[i]
      	local itemId = reward.itemId
      	local itemType = reward.itemType
      	local itemCount = reward.itemCount

      	local a=0
      end
      --存储一份阅读数据
      RAMailManager:addSystemMailCheckDatas(id,mailInfo)
      RAMailSystemCommonPage:updateInfo(mailInfo)
     elseif message.messageID == OperationOkMsg then 
    	local opcode = message.opcode
    	if opcode==HP_pb.MAIL_REWARD_C then 
    		RAMailSystemCommonPage:refreshUIAndTips()
    	end
    end
end

--RAMailSystemPageCell
-----------------------------------------------------------
local RAMailSystemCommonPageCell = {

}
function RAMailSystemCommonPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailSystemCommonPageCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)
    local rewardInfo = self.info
    local itemid = rewardInfo.itemId
 	local itemCount = rewardInfo.itemCount
 	local itemType = rewardInfo.itemType

 	--根据id判断是道具还是资源
 	local isEquip=RALogicUtil:isItemById(itemid)  --道具
 	local isRes =RALogicUtil:isResourceById(itemid) --资源

 	local icon
 	local name=""
 	if isEquip then
 		icon =RAMailUtility:getItemIconByid(itemid)
 		local itemInfo =RAMailUtility:getItemInfo(itemid)
 		local RAPackageData = RARequire("RAPackageData")
 		RAPackageData.setNumTypeInItemIcon(ccbfile,"mItemHaveNum","mItemParentNode",itemInfo)
 		UIExtend.setNodeVisible(ccbfile,"mItemHaveNum",true)

 		name =_RALang(itemInfo.item_name)

 	elseif isRes then 
 		icon=RALogicUtil:getResourceIconById(itemid)
 		UIExtend.setNodeVisible(ccbfile,"mItemHaveNum",false)
 		name = RALogicUtil:getResourceNameById(itemid)
 	else
 		local RAResManager = RARequire("RAResManager")
 		icon,name=RAResManager:getIconByTypeAndId(itemType,itemid)
 		UIExtend.setNodeVisible(ccbfile,"mItemHaveNum",false)
 		name = _RALang(name)
 	end

 	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mAdditionalResPicNode")
 	UIExtend.addSpriteToNodeParent(ccbfile,"mAdditionalResPicNode",icon)

 	UIExtend.setCCLabelString(ccbfile,"mCellLabel",name)
 	--num
 	UIExtend.setCCLabelString(ccbfile,"mCellNum","x"..itemCount)

	UIExtend.setNodeVisible(ccbfile,"mReseivedAllNode",not self.hasReward)
 	
end
function RAMailSystemCommonPageCell:showRecievedTips(isShow)
	if self.ccbfile then
		UIExtend.setNodeVisible(self.ccbfile,"mReseivedAllNode",isShow)
	end 
end
-----------------------------------------------------------

function RAMailSystemCommonPage:Enter(data)


	CCLuaLog("RAMailSystemCommonPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailSystemPageV6.ccbi",self)
	self.ccbfile  = ccbfile

	self.ccbfile:setVisible(false)

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailSystemCommonPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailSystemCommonPage:init()

	
	UIExtend.setCCLabelString(self.ccbfile,"mApplicationExplain","")
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel","")
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mMailLabel","",615,"center")

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	UIExtend.setCCLabelString(titleCCB,"mTitle","")

	self.SenderItemSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mSenderItemSV")
	self.SenderItemSV:removeAllCell()
	local mailInfo =RAMailManager:getMailById(self.id)
	self.mailInfo = mailInfo


	 --判断是否锁定
	self.lock = mailInfo.lock

	self.hasReward=mailInfo.hasReward

	
	
	--判断是否已读
	self.status = mailInfo.status

	--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailInfo = RAMailManager:getSystemMailCheckDatas(self.id)
		self:updateInfo(mailInfo)
	end 

	
end

function RAMailSystemCommonPage:updateInfo(mailDatas)

	--mailDatas 是从服务器返回的数据

	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId

	local configData = RAMailUtility:getNewMailData(configId)

	--寄件者头像
	local icon=configData.mailHead
	if icon then
		local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mHeadPicNode")
 		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end

	--time
	local mailTime = math.floor(mailInfo.ctime/1000)
	mailTime=RAMailUtility:formatMailTime(mailTime)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",mailTime)

	 --title and subTitle
 	self.configId = configId

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
			subTitleStr = _RALangFill(subTitlekeyStr,params[1],params[2],params[3],params[4],params[5],params[6],params[7],params[8],params[9],params[10]) 
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
			params = self:refreshParamsData(params,true)
			htmlHrefStr = _RAHtmlFill(contentkeyStr,params[1],params[2],params[3],params[4],params[5],params[6],params[7],params[8],params[9],params[10]) 
		else
			htmlHrefStr = _RAHtmlLang(configData.content)
		end
		UIExtend.setCCLabelHTMLString(self.ccbfile,"mMailLabel",htmlHrefStr,615,"center")

		--定义超链接
		local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mMailLabel")
		self.mHtmlLabel = htmlLabel
		

		--注册CCB
		self:registerHtmlCCB(mailInfo)

		if configData.isLink and configData.isLink == 1 then
			local RAChatManager = RARequire("RAChatManager")
			htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
		end 
	end

	--reward
	self:showRewords(mailDatas)

	self.ccbfile:setVisible(true)

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailInfo.id,false)
end


function RAMailSystemCommonPage:refreshParamsData(params,isCont)
	if self.configId==2011121 then
		--富资源点变更
		local super_mine_conf = RARequire("super_mine_conf")
		local info = super_mine_conf[tonumber(params[1])]
		params[1]= _RALang(info.name)
	
	elseif self.configId==2013041 then  
		--超值礼包购买成功
		params[1] = _RALang(params[1])
	elseif self.configId==2013061 then
		--活动积分目标奖励
		local event_conf = RARequire("event_conf")
		local info = event_conf[tonumber(params[1])]
		params[1] = _RALang(info.eventName)
	elseif self.configId==2013062 then
		--活动阶段排名奖励
		local event_conf = RARequire("event_conf")
		local info = event_conf[tonumber(params[1])]
		params[1] = _RALang(info.eventName)
	elseif self.configId==2013063 then
		--活动总排名奖励
		local event_conf = RARequire("event_conf")
		-- local info = event_conf[tonumber(params[1])]
		-- params[1] = _RALang(info.eventName)
	elseif self.configId==2013141 then
		--来自大总统表扬
		params[1] = _RALang(params[1])
	elseif self.configId==2013151 then
		--官员任命
		if not isCont then
			params[2] = RAMailUtility:getOfficailsName(params[2])
		end 
	elseif self.configId==2013152 then
		--官员任命更改
		if not isCont then
			params[2] = RAMailUtility:getOfficailsName(params[2])
			params[3] = RAMailUtility:getOfficailsName(params[3])
		end 
		
	elseif self.configId==2013153 then
		--官员撤职 无人接替 
		if isCont then
			params[1] = RAMailUtility:getOfficailsName(params[1])
		end 
	elseif self.configId==2013154 then
		--官员撤职 有人接替 
		if isCont then
			params[1] = RAMailUtility:getOfficailsName(params[1])
		end
		
	elseif self.configId==2013132 then
		--国王战结束
		local effect,_ = self:getOfficailsEffect(304101)
		local count=#effect
		local index=5
		for i=1,count do
			local data = effect[i]
			local effectInfo = RAStringUtil:split(data,"_")
			local effectValue = effectInfo[2]
			params[index]=effectValue
			index = index + 1
		end
	end
	return params
end

function RAMailSystemCommonPage:getOfficailsEffect(configId)
	local official_position_conf = RARequire("official_position_conf")
	local info = official_position_conf[tonumber(configId)]
	local effectStr=info.welfare
	local effect = RAStringUtil:split(effectStr,",")
	return effect,info
end
function RAMailSystemCommonPage:showRewords(mailDatas)
	local systemMailInfo =mailDatas.commonMail
	local scrollview = self.SenderItemSV
	self.SenderItemSV:removeAllCell()
	local rewardsInfo = systemMailInfo.rewards
	local count =#rewardsInfo


	if count>0 then
		self:hideReword(false)
		self.rewardCellTab={}
		for i=1,count do
			local rewardInfo =rewardsInfo[i]
			local cell = CCBFileCell:create()
			
			local panel = RAMailSystemCommonPageCell:new({
					info = rewardInfo,
					hasReward=self.hasReward
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailSystemCellV6.ccbi")
			scrollview:addCell(cell)
			table.insert(self.rewardCellTab,panel)

		end

		scrollview:orderCCBFileCells(scrollview:getContentSize().width)

	    if scrollview:getContentSize().height < scrollview:getViewSize().height then
			scrollview:setTouchEnabled(false)
		else
			scrollview:setTouchEnabled(true)
	    end 

	else
		self:hideReword(true)
	end 

	UIExtend.setNodeVisible(self.ccbfile,"mReseiveAllNode",self.hasReward)
end

function RAMailSystemCommonPage:hideReword(isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mReseiveAllNode",not isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mSenderItemNode",not isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mContentOfMailBG",not isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mContentOfMailBG2",isShow)
end
function RAMailSystemCommonPage:registerHtmlCCB(mailInfo)
	local paramsContent = mailInfo.msg
	if not paramsContent then
		return 
	end 
	local params=RAStringUtil:split(paramsContent, "_")
	if  self.configId==2013132 then
		-- 国王战结束
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[2],params[3],params[4])
	elseif self.configId==2013151 then
		-- 首次官员任命
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[2],params[3],params[4])

		local officalId =params[5]
		if officalId then
			local id = RAMailConfig.CCB.RAMailCmmCell6.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local effects,info = self:getOfficailsEffect(officalId)

			self:refreshRAMailCommonCell6V6(htmlCCBFile,info,effects)
		end 
	elseif self.configId==2013154  then
		-- 官员撤职 有人接替
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[2],params[3],params[4])
	elseif self.configId==2013152 then
		-- 官员再次任命
		local id = RAMailConfig.CCB.RAMailCmmCell1.id
		local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
		self:refreshRAMailCommonCell1V6(htmlCCBFile,params[2],params[3],params[4])


		local officalId =params[5]
		if officalId then
			local id = RAMailConfig.CCB.RAMailCmmCell7.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local effects,info = self:getOfficailsEffect(officalId)
			local tmpCCBFile = UIExtend.getCCBFileFromCCB(htmlCCBFile,"mCCB1")
			self:refreshRAMailCommonCell6V6(tmpCCBFile,info,effects)
		end 

		officalId =params[6]
		if officalId then
			local id = RAMailConfig.CCB.RAMailCmmCell7.id
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local effects,info = self:getOfficailsEffect(officalId)
			local tmpCCBFile = UIExtend.getCCBFileFromCCB(htmlCCBFile,"mCCB2")
			self:refreshRAMailCommonCell6V6(tmpCCBFile,info,effects)
		end 


	elseif self.configId==2013161 or self.configId==2013162 then 
		--  征税 被征税
		local isAdd = true
		local index=2
		if self.configId==2013162 then
			isAdd =false
			index = 1
		end 
		local baseId = RAMailConfig.CCB.RAMailCmmCell5.id
		local ids={baseId.."_1",baseId.."_2",baseId.."_3",baseId.."_4"}
		
		local RAGameConfig = RARequire("RAGameConfig")
		for i=1,#ids do
			local id = ids[i]
			local htmlCCBFile = self.mHtmlLabel:getCCBElement(id)
			local iconId = params[index]
			local changeNum = params[index+1] 
			local color = nil
			if iconId and changeNum then
				changeNum=Utilitys.formatNumber(changeNum)
				if isAdd then
					changeNum = "+"..changeNum
					color = RAGameConfig.COLOR.GREEN
				else
					changeNum = "-"..changeNum
					color = RAGameConfig.COLOR.RED
				end 
			end 
			
			self:refreshRAMailCommonCell5V6(htmlCCBFile,iconId,changeNum,color)
			index = index+2
		end
	end

end
function RAMailSystemCommonPage:refreshRAMailCommonCell6V6(htmlCCBFile,info,effects)
	if not htmlCCBFile then return end 
	local officeName = _RALang(info.officeName)
	local officeIcon = info.officeIcon
	UIExtend.setCCLabelString(htmlCCBFile,"mJobName",officeName)
	if officeIcon then
		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
 		UIExtend.addNodeToAdaptParentNode(picNode,officeIcon,RAMailConfig.TAG)
	end

	local keyStr="MailCell4V63"
	for i=1,3 do
		local effect = effects[i]
		if effect then
			local t=RAStringUtil:split(effect,"_")
			local effectid_conf = RARequire("effectid_conf")
			local effectInfo = effectid_conf[tonumber(t[1])]
			local effectType=effectInfo.type  --1是百分数 0是数值
			local value = t[2]
			
			if effectInfo.nameString then
				local name= _RALang(effectInfo.nameString)
				local htmlStr=""
				if effectType==1 then
					htmlStr = _RAHtmlLang(keyStr,name..":"..value.."%%")
				elseif effectType==0 then
					htmlStr = _RAHtmlLang(keyStr,name..":"..value)
				end 
				UIExtend.setCCLabelHTMLStringDirect(htmlCCBFile,"mAttritubes"..i,htmlStr)
				UIExtend.setNodeVisible(htmlCCBFile,"mAttritubes"..i,true)

			else
				--隐藏
				UIExtend.setNodeVisible(htmlCCBFile,"mAttritubes"..i,false)
			end 
			
			
		else
			--隐藏
			UIExtend.setNodeVisible(htmlCCBFile,"mAttritubes"..i,false)
		end 
	end
end


function RAMailSystemCommonPage:refreshRAMailCommonCell1V6(htmlCCBFile,iconId,name,battle)
	if not htmlCCBFile then return end 
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

function RAMailSystemCommonPage:refreshRAMailCommonCell5V6(htmlCCBFile,iconId,changeNum,fontColor)
	if not htmlCCBFile then return end 
	-- to do  征税的cell
	if iconId then
		htmlCCBFile:setVisible(true)
		local icon=RALogicUtil:getResourceIconById(iconId)
 		local name = RALogicUtil:getResourceNameById(iconId)
 		local picNode = UIExtend.getCCNodeFromCCB(htmlCCBFile,"mIconNode")
		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellLabel",name)
		UIExtend.setCCLabelString(htmlCCBFile,"mCellNum",changeNum)
		UIExtend.setLabelTTFColor(htmlCCBFile,"mCellNum",fontColor)
	else
		htmlCCBFile:setVisible(false)
	end 


end

function RAMailSystemCommonPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
end

function RAMailSystemCommonPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
end


function RAMailSystemCommonPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end

	if self.rewardCellTab then
		for i,v in ipairs(self.rewardCellTab) do
			v=nil
		end
		self.rewardCellTab=nil
	end 
	

	self.SenderItemSV:removeAllCell()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailSystemCommonPage)
	
end

function RAMailSystemCommonPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailSystemCommonPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailSystemCommonPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailSystemCommonPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

function RAMailSystemCommonPage:refreshCellStatus(isShow)
	if self.rewardCellTab then
		for i,v in ipairs(self.rewardCellTab) do
			local cellPanel=v
			cellPanel:showRecievedTips(isShow)
		end
	end 

end
function RAMailSystemCommonPage:refreshUIAndTips()
	--刷新主邮件列表
	MessageManager.sendMessage(refreshMailListMsg)

	UIExtend.setNodeVisible(self.ccbfile,"mReseiveAllNode",false)

	--刷新cell
	self:refreshCellStatus(not self.hasReward)
end


function RAMailSystemCommonPage:onReceiveBtn()
	if self.hasReward then
		RAMailManager:sendGetRewardCmd(self.id)
		self.hasReward=false
	end 
	

	RAMailManager:updateRewardMailDatas(self.id,false)
end