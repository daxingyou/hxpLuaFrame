
--资源采集邮件界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire("Const_pb")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire('RAMailConfig')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')

local readReportMailMsg=MessageDefine_Mail.MSG_Read_ReportMail
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK
-- local reportMailBack =MessageDefine_Mail.MSG_Back_ReportMail
local TAG=1000

local RAMailResourceCollectPage = BaseFunctionPage:new(...)

--RAMailResourceCollectPageCell
-------------------------------------------------------------------------
local RAMailResourceCollectPageCell = {

}
function RAMailResourceCollectPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end



function RAMailResourceCollectPageCell:onRefreshContent(ccbRoot)

	CCLuaLog("RAMailMainOptCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
	local resCollectInfo = self.info
    local selectStatue = RAMailResourceCollectPage:getSelectStatueByIndex(self.id)

    self.configId = resCollectInfo.mailId

    --时间
    local collectT = math.floor(self.colletTime/1000)
    local collectTStr=RAMailUtility:formatMailTime(collectT)
    UIExtend.setCCLabelString(ccbfile,"mMailTimeLabel",collectTStr)
    UIExtend.setNodeVisible(ccbfile, "mSelectNode", RAMailResourceCollectPage.canEdit)

    --采集信息
    local worldResInfo, resShowCfg = RAWorldConfigManager:GetResConfig(resCollectInfo.id)
    
    local isSuper=false
    if resCollectInfo.isSuper then
    	if resCollectInfo.isSuper==1 then
    		isSuper = true
    		worldResInfo=RAMailUtility:getSupperData(resCollectInfo.id)
    	end 
    end 
    --等级
    local htmlStr = ""
    if not isSuper then
    	htmlStr = _RALang("@NameWithLevelTwoParams", _RALang(resShowCfg.resName), worldResInfo.level)
    	-- RAStringUtil:fill(html_zh_cn["ResCollectTarget"],_RALang(resShowCfg.resName), worldResInfo.level, resCollectInfo.x, resCollectInfo.y)
   	else
   		htmlStr = _RALang(worldResInfo.name)
   		-- RAStringUtil:fill(html_zh_cn["ResCollectSuperTarget"], _RALang(worldResInfo.name), resCollectInfo.x, resCollectInfo.y )
    end 
    UIExtend.setCCLabelString(self.ccbfile,"mMailTitle", htmlStr)

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mPos")
    htmlLabel:setString(_RAHtmlFill("ResPos", resCollectInfo.x, resCollectInfo.y))
    
  	local RAChatManager = RARequire("RAChatManager")
  	htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
    -- UIExtend.setCCLabelString(self.ccbfile,"mPos",)
    --采集资源icon
    local descStr = ""
    if  self.configId == RAMailConfig.Page.ResCollectSucc or 
    	self.configId == RAMailConfig.Page.ResCollectSupSucc then
    	local resIcon = RALogicUtil:getResourceIconById(worldResInfo.resType)
    	UIExtend.addSpriteToNodeParent(self.ccbfile,"mIconNode", resIcon)
	    --采集数目
	    local resNum = resCollectInfo.num
	    resNum=Utilitys.formatNumber(resNum)
	    descStr = _RALang("@GetResNum",resNum)
     	
    else
    	UIExtend.removeSpriteFromNodeParent(self.ccbfile,"mIconNode")
    	if  self.configId == RAMailConfig.Page.ResCollectMiss then
    		descStr = _RALang("@ResCollectMiss")
    	elseif  self.configId == RAMailConfig.Page.ResCollectOccu then
    		descStr = _RALang("@ResCollectOccu")
    	elseif  self.configId == RAMailConfig.Page.ResCollectFight then
    		descStr = _RALang("@ResCollectFight")
    	elseif  self.configId == RAMailConfig.Page.ResCollectSupFail then
    		descStr = _RALang("@ResCollectSupFail")    	
    	end	    		
    end 

    UIExtend.setCCLabelString(ccbfile,"mMailContentLabel",descStr)
	UIExtend.setNodeVisible(ccbfile,"mSelectYesPic", selectStatue)   


  
end

function RAMailResourceCollectPageCell:onCellSelectBtn( )
	RAMailResourceCollectPage:onSelect(self.id)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic", RAMailResourceCollectPage:getSelectStatueByIndex(self.id))
end



-------------------------------------------------------------------------
local OnReceiveMessage = function(message)
    if message.messageID == readReportMailMsg then
     	local mailInfo = message.mailDatas
		local mailDatas = mailInfo.mails
		local count =#mailDatas
		for i=1,count do
			local mailInfo =mailDatas[i]
			local id=mailInfo.id
		     --记录下邮件状态
			RAMailManager:updateReadMailDatas(id,1)
		end
		--存储一份最新的阅读数据
		local newId = RAMailManager:getResCollectNewId()
		RAMailManager:clearResCollectMailCheckDatas()
		RAMailManager:addResCollectMailCheckDatas(newId,mailDatas)
        RAMailResourceCollectPage:updateInfo(mailDatas)
    elseif message.messageID == OperationOkMsg then 				--删除邮件成功返回
    	local opcode = message.opcode
    	if opcode==HP_pb.MAIL_DEL_MAIL_BY_ID_C then 
    		local newId = RAMailManager:getResCollectNewId()

			local mailDatas = RAMailManager:getResCollectMailCheckDatas(newId)
			local deleteMailIdTab = RAMailManager:getDeleteMailIdTab()
			for i,v in pairs(deleteMailIdTab) do
				for j,v1 in ipairs(mailDatas) do
					if v1.id == v then
						table.remove(mailDatas, j)
						break
					end
				end
			end
			RAMailManager:clearResCollectMailCheckDatas()
			RAMailManager:addResCollectMailCheckDatas(newId,mailDatas)
			RAMailResourceCollectPage:updateInfo(mailDatas) 		
    	end 

    end
end

function RAMailResourceCollectPage:Enter(data)


	CCLuaLog("RAMailSystemPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailResultReportPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	RAMailManager:Enter()
 	self:registerMessageHandler()
    self:init()

    local isShowDeletTips=RAMailManager:getMailTips(RAMailConfig.Type.RESCOLLECT)
   	local isShowLimiNumTips=RAMailManager:isReachLimitMailCount(RAMailConfig.Type.RESCOLLECT)

   	if isShowDeletTips then
   		--服务器删除邮件提示
   		local RARootManager=RARequire("RARootManager")
		RARootManager.ShowMsgBox('@MailDeleteTips')
		RAMailManager:setMailTips(RAMailConfig.Type.RESCOLLECT,false)
	elseif isShowLimiNumTips then
		--邮件上限提示
		local RARootManager=RARequire("RARootManager")
		RARootManager.ShowMsgBox('@SystemMailLimitTips')
   	end 

    
end
function RAMailResourceCollectPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailResourceCollectPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readReportMailMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
 
end

function RAMailResourceCollectPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readReportMailMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
end


function RAMailResourceCollectPage:init()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnTitleEditNode",true)
	self.canEdit = false  --默认不可编辑状态
	UIExtend.setNodeVisible(self.ccbfile,"mEditNode",false)
	UIExtend.setCCLabelString(self.ccbfile,"mDeleteLabel",_RALang('@DeleteMailBtn'))

	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@CollectReport"))
	-- UIExtend.setNodeVisible(titleCCB,"mHomeBackNode",true)
	self.mReportListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mReportListSV")
	self.selectTable = {}
	-- self:updateInfo({ctime = os.time()*1000,{collectMail = {id = 300101, num = 5000, x = 101, y = 1052, isSuper = false}}})
	local newId = RAMailManager:getResCollectNewId()
	if newId==nil then
		local label = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTipsLable")
		UIExtend.setCCLabelString(self.ccbfile,"mTipsLable",_RALang("@ResourceCollectMailTips"))
		return
	else
		UIExtend.setCCLabelString(self.ccbfile,"mTipsLable","")
		-- UIExtend.
	end 
	local mailInfo = RAMailManager:getMailById(newId)
	self.status = mailInfo.status
	self.newId=newId

	-- self.isFrstRead 表示是否第一次阅读
	self.isFrstRead = RAMailManager:isMailFirstRead(newId)
	if self.isFrstRead then
		RAMailManager:sendReadReportMailCmd(Const_pb.COLLECT_MAIL_TYPE)
	else
		local mailDatas = RAMailManager:getResCollectMailCheckDatas(newId)
		self:updateInfo(mailDatas)
	end 
end

function RAMailResourceCollectPage:updateInfo(mailInfo)
	self.mReportListSV:removeAllCell()
	local scrollview = self.mReportListSV

	local resCollectInfo = mailInfo
	self.mailInfo = mailInfo
	local count=#resCollectInfo
	if count == 0 then
		local label = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTipsLable")
		UIExtend.setCCLabelString(self.ccbfile,"mTipsLable",_RALang("@ResourceCollectMailTips"))
		UIExtend.setNodeVisible(self.ccbfile,"mEditNode",false)
	end
	for i=1,count do
		local collectInfo =resCollectInfo[i]
		local ctime=RAMailManager:getMailTime(collectInfo.id)

		local mailTime = ctime or os.time()*1000
		local mailCollet =collectInfo.collectMail

		local cell = CCBFileCell:create()
		local panel = RAMailResourceCollectPageCell:new({
				colletTime = mailTime,
				info = mailCollet,
				id = i,
				-- configId = self.configId
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailResultReportCellV6.ccbi") 
		scrollview:addCell(cell)
		self.selectTable[i] = false
	end
	scrollview:orderCCBFileCells()
	UIExtend.setNodeVisible(self.ccbfile,"mYesPic",false)	
	if self.status==0 then 
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 
   		--刷新列表
    	MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
    	RAMailManager:refreshMainUIBottomMailNum()   
    end 

    if self.isFrstRead then
  		RAMailManager:updateIsFirstMailDatas(self.newId,false)
  	end

 
end

function RAMailResourceCollectPage:mCommonTitleCCB_onCmnTitleEditBtn()
	self.canEdit = not self.canEdit
	UIExtend.setNodeVisible(self.ccbfile,"mEditNode",self.canEdit)
	self.mReportListSV:refreshAllCell()
end

function RAMailResourceCollectPage:onSelect( index )
	index = index or 1
	self.selectTable[index] = not self.selectTable[index]
	local isAllSelect = true
	for i,v in ipairs(self.selectTable) do
		if not v then
			isAllSelect = false
			break
		end
	end
	UIExtend.setNodeVisible(self.ccbfile,"mYesPic",isAllSelect)	
end

function RAMailResourceCollectPage:getSelectStatueByIndex(index )
	index = index or 1
	return self.selectTable[index]
end

function RAMailResourceCollectPage:onSelectAllBtn(  )
	local isAllSelect = true
	for i,v in ipairs(self.selectTable) do
		if not v then
			isAllSelect = false
			break
		end
	end
	isAllSelect = not isAllSelect
	for i = 1, #self.selectTable do
		self.selectTable[i] = isAllSelect
	end
	UIExtend.setNodeVisible(self.ccbfile, "mYesPic", isAllSelect)
	self.mReportListSV:refreshAllCell()
end

function RAMailResourceCollectPage:onDeleteBtn(  )

	RAMailManager:clearDeleteMailiIdTab()
	for i,v in ipairs(self.selectTable) do
		if v then
			RAMailManager:addDeleteMailId(self.mailInfo[i].id)
		end
	end
	local deleteMailIdTab = RAMailManager:getDeleteMailIdTab()
	RAMailManager:sendDeleteMailCmdById(deleteMailIdTab)
	
end

function RAMailResourceCollectPage:Exit()
	self.mReportListSV:removeAllCell()
	self:removeMessageHandler()
	RAMailManager:Exit()
	UIExtend.unLoadCCBFile(RAMailResourceCollectPage)
	
end

function RAMailResourceCollectPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailResourceCollectPage:mCommonTitleCCB_onBack()
	self:onClose()
	-- MessageManager.sendMessage(reportMailBack)
end