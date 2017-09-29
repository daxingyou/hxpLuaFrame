
--士兵援助 资源援助
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAResManager = RARequire('RAResManager')

local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local RAMailGatherPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailDatas = message.mailDatas
      local id=mailDatas.id
      --存储一份阅读数据
      RAMailManager:addAllianceMailCheckDatas(id,mailDatas)
      RAMailGatherPage:updateInfo(mailDatas)
    end
end
-----------------------------------------------------------------
local RAMailGatherTitleCell={}

function RAMailGatherTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailGatherTitleCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.setCCLabelHTMLString(ccbfile, "mCellTitle",self.titleStr)
end

local RAMailGatherPageCell={}

function RAMailGatherPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailGatherPageCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    local data= self.data

    UIExtend.setNodeVisible(ccbfile, "mHeadFrameNode", true)
    -- UIExtend.setNodeVisible(ccbfile, "mResFrameNode", not self.isRes)

    if self.isRes then
    	 local icon, name, item_color =RAResManager:getIconByTypeAndId(data.type, data.itemId)
    	UIExtend.setCCLabelString(ccbfile,"mCellLabel", _RALang(name))
    	UIExtend.setCCLabelString(ccbfile,"mCellNum",data.count)
		-- local bgName  = RALogicUtil:getItemBgByColor(item_color)
		-- UIExtend.addSpriteToNodeParent(ccbfile, "mHeadIconNode" ,bgName)    	
    	UIExtend.addSpriteToNodeParent(ccbfile,"mHeadIconNode",icon)    	 
    else
    	local battle_soldier_conf = RARequire("battle_soldier_conf")
    	local curInfo = battle_soldier_conf[data.armyId]    	
    	UIExtend.setCCLabelString(ccbfile,"mCellLabel", _RALang(curInfo.name))
    	UIExtend.setCCLabelString(ccbfile,"mCellNum",data.count)
    	UIExtend.addSpriteToNodeParent(ccbfile,"mHeadIconNode",curInfo.icon)
    end 
    
 	
end
-----------------------------------------------------------

function RAMailGatherPage:Enter(data)


	CCLuaLog("RAMailGatherPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailGatherPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailGatherPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

function RAMailGatherPage:init()

	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId


	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	

	local configData = RAMailUtility:getNewMailData(configId)
	--title
	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	--banner 
	
	-- local mailBanner = configData.mailBanner
	-- local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	-- render:setTexture(mailBanner)
	self.configId = configId
	self.configData = configData

	self.ListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV")

	

	 --判断是否锁定
	self.lock = mailInfo.lock
	 
	
	--判断是否已读
	self.status = mailInfo.status

	--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailDatas = RAMailManager:getAllianceMailCheckDatas(self.id)
		self:updateInfo(mailDatas)
	end 

	
end

function RAMailGatherPage:genResAid( mailDatas)

	local resAssistanceMail  = mailDatas.resAssistanceMail
	local tb={}
	tb.x = resAssistanceMail.x
	tb.y = resAssistanceMail.y
	tb.time = math.floor(resAssistanceMail.atime /1000)
	tb.playerIcon = resAssistanceMail.playerIcon
	tb.name = resAssistanceMail.name
	tb.tradeTaxRate = resAssistanceMail.tradeTaxRate
	tb.name = resAssistanceMail.name
	

	local detals = resAssistanceMail.resource
	local count=#detals
	if count > 0 then
		tb.detal={}
		for i=1,count do
			local t={}
			local detal = detals[i]
			t.itemId = detal.itemId
			t.type = detal.type
			t.count = detal.num
			table.insert(tb.detal,t)
		end
	end 

	return tb


end
function RAMailGatherPage:genSoldierDatas(mailDatas)
	
	local soilderAssistanceMail  = mailDatas.assistanceMail
	local tb={}
	tb.x = soilderAssistanceMail.x
	tb.y = soilderAssistanceMail.y
	tb.time = math.floor(soilderAssistanceMail.atime /1000)
	tb.playerIcon = soilderAssistanceMail.playerIcon
	tb.name = soilderAssistanceMail.name

	local detals = soilderAssistanceMail.soldier
	local count=#detals
	if count > 0 then
		tb.detal={}
		for i=1,count do
			local t={}
			local detal = detals[i]
			t.armyId = detal.armyId
			t.count = detal.count
			table.insert(tb.detal,t)
		end
	end 

	return tb

end
function RAMailGatherPage:updateInfo(mailDatas)


	local datas = nil
	local isRes = false
	if self.configId >= RAMailConfig.Page.SoldierAidSucc then
		datas =self:genSoldierDatas(mailDatas)
	else
		datas =self:genResAid(mailDatas)
		isRes = true
	end 
	local x = datas.x
	local y = datas.y
	local targetHtmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mPosLabel") 
	local RAChatManager = RARequire("RAChatManager")
	targetHtmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
	targetHtmlLabel:setString(_RAHtmlLang("@location",x,y))

	--time
	local time = datas.time
	local timeStr = RAMailUtility:formatMailTime(time)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",timeStr)

	UIExtend.setCCLabelString(self.ccbfile,"mApplicationExplain",_RALangFill(self.configData.subTitile, datas.name))

	local icon = RAPlayerInfoManager.getHeadIcon(datas.playerIcon)
	UIExtend.addSpriteToNodeParent(self.ccbfile, "mAllianceIconNode", icon)
	

	local count = 0
	if datas.detal then
		for i,v in ipairs(datas.detal) do
			count = count + v.count
		end
	end
	local mailsys_conf = RARequire('mailsys_conf')
	local descStr = mailsys_conf[self.configId].content
	local titleStr = ""
	if self.configId == RAMailConfig.Page.ResAidSucc then
		descStr = _RAHtmlFill(descStr,datas.name, datas.tradeTaxRate)
		titleStr = _RALang("@AssistanceResTiltle")
	elseif self.configId == RAMailConfig.Page.ResRecvSucc then
		descStr = _RAHtmlFill(descStr,datas.name)
		titleStr = _RALang("@AssistanceResTiltle")
		if datas.detal then
			for i,v in ipairs(datas.detal) do
				v.count = math.floor(v.count * (100 - datas.tradeTaxRate)/100)
			end
		end
	elseif self.configId == RAMailConfig.Page.ResAidFail then	
		descStr = _RAHtmlFill(descStr,datas.name)
		datas.detal = nil
	elseif self.configId == RAMailConfig.Page.ResRecvFail then
		descStr = _RAHtmlFill(descStr,datas.name)
		datas.detal = nil
		titleStr = _RAHtmlFill("SoldierAidNum",count)
	elseif self.configId == RAMailConfig.Page.SoldierAidSucc then
		descStr = _RAHtmlFill(descStr,datas.name)
		titleStr = _RAHtmlFill("SoldierAidNum",count)
	elseif self.configId == RAMailConfig.Page.SoldierRecvSucc then
		descStr = _RAHtmlFill(descStr,datas.name)
	elseif self.configId == RAMailConfig.Page.SoldierAidFail then
		descStr = _RAHtmlFill(descStr,datas.name)
		datas.detal = nil
	elseif self.configId == RAMailConfig.Page.SoldierRecvFail then					
		descStr = _RAHtmlFill(descStr,datas.name)
		datas.detal = nil
	end

	UIExtend.setCCLabelHTMLString(self.ccbfile,"mAllianceHTMLLabel",descStr)


	self.ListSV:removeAllCell()
	local scrollview = self.ListSV
	if datas.detal then
		-- title
		local cell = CCBFileCell:create()
		local panel = RAMailGatherTitleCell:new({
				titleStr = titleStr
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailGatherCellTitleV6.ccbi")
		scrollview:addCellBack(cell)

		for k,v in ipairs(datas.detal) do
			local info = v
			local cell = CCBFileCell:create()
			local panel = RAMailGatherPageCell:new({
				data = info,
				isRes = isRes
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailGatherResCellV6.ccbi")
			scrollview:addCellBack(cell)

		end
		scrollview:orderCCBFileCells(scrollview:getContentSize().width)

	    if scrollview:getContentSize().height < scrollview:getViewSize().height then
			scrollview:setTouchEnabled(false)
		else
			scrollview:setTouchEnabled(true)
	    end 
	end 

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailDatas.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailDatas.id,false)
end



function RAMailGatherPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailGatherPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailGatherPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self.id = nil
	self.configId = nil
	self.configData = nil
	self.ListSV:removeAllCell()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailGatherPage)
	
end

function RAMailGatherPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailGatherPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailGatherPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailGatherPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end