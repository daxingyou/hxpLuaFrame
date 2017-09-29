
-- 战斗邮件：战斗成功
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire("RANetUtil")
RARequire("RAMailFightCell")
local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail

local RAMailPlayerFightSuccessPage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id

      --存储一份阅读数据
      RAMailManager:addPlayerBattleMailCheckDatas(id,mailInfo)
      RAMailPlayerFightSuccessPage:updateInfo(mailInfo)
   
    end
end

function RAMailPlayerFightSuccessPage:Enter(data)


	CCLuaLog("RAMailPlayerFightSuccessPage:Enter")

	--todo replace
	local ccbfile = UIExtend.loadCCBFile("RAMailBattleReportPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	self.netHandlers={}
    self.id = data.id
    self.isShare = data.isShare
    self.cfgId=data.cfgId
    self.mailPlayerId = data.mailPlayerId
    self:addHandler()
	self:registerMessageHandler()
    self:init()
    
end
function RAMailPlayerFightSuccessPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

function RAMailPlayerFightSuccessPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.MAIL_CHECK_OTHERPLAYER_MAIL_S then  
    	local msg = Mail_pb.HPCheckMailRes()
        msg:ParseFromString(buffer)
        local mailInfo = msg
        RAMailPlayerFightSuccessPage:updateInfo(mailInfo)
    end

end

--添加协议监听
function RAMailPlayerFightSuccessPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHECK_OTHERPLAYER_MAIL_S, RAMailPlayerFightSuccessPage) 	--查看其他玩家邮件返回监听
end

--移除协议监听
function RAMailPlayerFightSuccessPage:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
    self.netHandlers = {}
end 

function RAMailPlayerFightSuccessPage:init()

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")

	-- UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	UIExtend.setNodeVisible(titleCCB,"mCmnShareNode",true)
	

	self.mReportListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mReportListSV")
	local mailInfo =RAMailManager:getMailById(self.id)
	self.mailInfo = mailInfo

	--banner 

	if self.isShare then
		self.configId = self.cfgId
	else
		local mailInfo =RAMailManager:getMailById(self.id)
		self.mailInfo = mailInfo
		local configId = mailInfo.configId
		self.configId = configId
		 --判断是否锁定
		self.lock = mailInfo.lock
		--判断是否已读
		self.status = mailInfo.status
	end


 	local configData = RAMailUtility:getNewMailData(self.configId)
	local mailBanner = configData.mailBanner
	local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	render:setTexture(mailBanner)

	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)



	--如果是超链接分享
	if self.isShare and self.mailPlayerId then
		-- UIExtend.setCCControlButtonEnable(self.ccbfile,"mShareAlliance",false)
		UIExtend.setNodeVisible(titleCCB,"mCmnShareNode",false)
		RAMailManager:sendCheckOtherMailCmd(self.mailPlayerId,self.id)
	else
		--self.isFrstRead 表示是否第一次阅读 
		self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
		if self.isFrstRead then
			RAMailManager:sendReadCmd(self.id)
		else
			local mailInfo = RAMailManager:getPlayerBattleMailCheckDatas(self.id)
			self:updateInfo(mailInfo)
		end 
	end 

end



function RAMailPlayerFightSuccessPage:updateInfo(mailInfo)


	
	-- --time
	local mailTime=RAMailManager:getMailTime(mailInfo.id)
	mailTime = math.floor(mailTime/1000)
	
	self.mReportListSV:removeAllCell()
	local scrollview = self.mReportListSV

	-- result  res
	local fightInfo = mailInfo.fightMail  
	local resultCell = CCBFileCell:create()
	local resultPanel = RAMailPlayerFightCell:new({
			data = fightInfo,
			configId= self.configId,
			time = mailTime
        })
	resultCell:registerFunctionHandler(resultPanel)
	resultCell:setCCBFile("RAMailBattleReportCellV6.ccbi")
	scrollview:addCell(resultCell)



	scrollview:orderCCBFileCells(scrollview:getContentSize().width)

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailInfo.id,false)
end
function RAMailPlayerFightSuccessPage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailPlayerFightSuccessPage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailPlayerFightSuccessPage:Exit()

	self.mReportListSV:removeAllCell()
	self:removeHandler()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailPlayerFightSuccessPage)
	
end

function RAMailPlayerFightSuccessPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailPlayerFightSuccessPage:mCommonTitleCCB_onBack()
	self:onClose()
end


function RAMailPlayerFightSuccessPage:mCommonTitleCCB_onCmnShareBtn()
	 local RAAllianceManager = RARequire("RAAllianceManager")
	 if RAAllianceManager.selfAlliance == nil then
	 	RARootManager.ShowMsgBox('@NoAllianceLabel')
	 	return 
	 end 
	 RAMailManager:sendShareMailCmd(self.id)
	 local str = _RALang("@ShareMailSuccess")
	 RARootManager.ShowMsgBox(str)

	 self:onClose()
end

