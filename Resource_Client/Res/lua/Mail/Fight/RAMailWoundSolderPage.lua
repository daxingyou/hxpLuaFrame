
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
local RAMailWoundSolderPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailDatas = message.mailDatas
      local id=mailDatas.id
      --存储一份阅读数据
      RAMailManager:addPlayerBattleMailCheckDatas(id,mailDatas)
      RAMailWoundSolderPage:updateInfo(mailDatas)

    end
end

-----------------------------------------------------------

function RAMailWoundSolderPage:Enter(data)


	CCLuaLog("RAMailWoundSolderPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailWoundedPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailWoundSolderPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailWoundSolderPage:init()


	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel","")

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)

	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId

	local configData = RAMailUtility:getNewMailData(configId)
	--title
	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	--banner 
	
	local mailBanner = configData.mailBanner
	local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	render:setTexture(mailBanner)

	self.mailInfo = mailInfo

	 --判断是否锁定
	self.lock = mailInfo.lock
	 
	
	--判断是否已读
	self.status = mailInfo.status

	--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailInfo = RAMailManager:getPlayerBattleMailCheckDatas(self.id)
		self:updateInfo(mailInfo)
	end 

	
end


function RAMailWoundSolderPage:updateInfo(mailDatas)

	local cureMail=mailDatas.cureMail

	--time
	local mailTime=RAMailManager:getMailTime(mailDatas.id)
	mailTime = math.floor(mailTime/1000)

	mailTime=RAMailUtility:formatMailTime(mailTime)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",mailTime)


	local free=cureMail.hospitalCap
	local hurt=cureMail.totalHurt
	local dead=cureMail.dead

	free=Utilitys.formatNumber(free)
	hurt=Utilitys.formatNumber(hurt)
	dead=Utilitys.formatNumber(dead)
	UIExtend.setCCLabelString(self.ccbfile,"mRepairStationsNum",free)
	UIExtend.setCCLabelString(self.ccbfile,"mCasualtiesTroopsNum",hurt)
	UIExtend.setCCLabelString(self.ccbfile,"mInsufficientSpaceNum",dead)


    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailDatas.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailDatas.id,false)
end
function RAMailWoundSolderPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailWoundSolderPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailWoundSolderPage:onIncreaseCapacityBtn()
	
	local Const_pb=RARequire("Const_pb")
	local RABuildManager = RARequire("RABuildManager")
	local toBuildInfo = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION) 
	if toBuildInfo  and next(toBuildInfo) then
			--从小到大排序
			local toBuild = nil 

			for k,v in pairs(toBuildInfo) do
				if toBuild == nil then 
					toBuild = v
				else
					if toBuild.confData.level > v.confData.level then 
						toBuild = v
					end 
				end 
			end

			-- local tmpTab = Utilitys.table_pairsByKeysAll(toBuildInfo,true)
			-- local toBuild = tmpTab[1]
			local tilePos = CCPoint(toBuild.tilePos.x,toBuild.tilePos.y)

			--摄像机移动到目标建筑并且选中该建筑
			RABuildManager:showBuildingById(toBuild.id)
			RARootManager.CloseAllPages()
	else
		 RARootManager.ShowMsgBox('@NoHospitalTips')
	end

end

function RAMailWoundSolderPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailWoundSolderPage)
	
end

function RAMailWoundSolderPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailWoundSolderPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailWoundSolderPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailWoundSolderPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

