--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire("Const_pb")
local HP_pb = RARequire("HP_pb")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig  = RARequire("RAMailConfig")
RARequire("RAMailMainPageCellV6")

local  RAMailListPageV6= BaseFunctionPage:new(...)

local TAG = 1000
local CELLH=131  --每个邮件列表cell的高度
local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local selectedMailMsg =MessageDefine_Mail.MSG_Selected_Mail
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK
local refreshMailOptListMsg =MessageDefine_Mail.MSG_Refresh_MailOptList

local OnReceiveMessage = function(message)
    if message.messageID == refreshMailListMsg then                      --刷新列表
      	
      	local mailType=RAMailManager:getOptMailType()
      	local isOffest = message.isOffest 
 		RAMailListPageV6:updateInfo(mailType,isOffest)
      	
    elseif  message.messageID == selectedMailMsg then					--选中列表

    	RAMailListPageV6:refreshLockBtnLabel()
    	
    elseif message.messageID == OperationOkMsg then 				--删除邮件成功返回
    	local opcode = message.opcode
    	if opcode==HP_pb.MAIL_DEL_MAIL_BY_ID_C then 
    		local mailDatas=RAMailManager:getMailDatas()
    		local deleteMailIdTab = RAMailManager:getDeleteMailIdTab()
    		local count=0
    		for i,v in pairs(deleteMailIdTab) do
    			local deleteMailId = v
    			mailDatas[deleteMailId]=nil
    			RAMailManager.chatRoomMemDatas[deleteMailId]=nil
    			count=count+1

    		end
    		RAMailManager:clearDeleteMailiIdTab()
 			local mailType=RAMailManager:getOptMailType()
			RAMailListPageV6:updateInfo(mailType)
			local str = _RALang("@DeleteMailSuccess")
			RARootManager.ShowMsgBox(str)

			MessageManager.sendMessage(refreshMailOptListMsg)

    	end 

    end
end


function RAMailListPageV6:Enter(data)


	CCLuaLog("RAMailListPageV6:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailListPageV6.ccbi",self)
	self.ccbfile  = ccbfile

	self.title=data.title
	self.mailType=data.mailType
	self:registerMessageHandler()

	self.mailCellTab={}

	RAMailManager:Enter()
   	RAMailManager:setOptMailType(self.mailType)
   	

	self:init()
	self.canEdit = false  --默认不可编辑状态
   	UIExtend.setNodeVisible(self.ccbfile,"mEditNode",false)


   
   	local isShowDeletTips=RAMailManager:getMailTips(self.mailType)
   	local isShowLimiNumTips=nil
   	if self.mailType~=RAMailConfig.Type.FIGHT then
   		isShowLimiNumTips=RAMailManager:isReachLimitMailCount(self.mailType)
   	else
   		isShowLimiNumTips=RAMailManager:isReachLimitFightMailCount()
   	end 

   	
   	
   	if isShowDeletTips then
   		--服务器删除邮件提示
   		local RARootManager=RARequire("RARootManager")
		RARootManager.ShowMsgBox('@MailDeleteTips')
		RAMailManager:setMailTips(self.mailType,false)
	elseif isShowLimiNumTips then
		--邮件上限提示
		local RARootManager=RARequire("RARootManager")
		RARootManager.ShowMsgBox('@SystemMailLimitTips')
   	end 

    -- local RAMailConfig = RARequire("RAMailConfig")
    -- if self.mailType==RAMailConfig.Type.MONSTERYOULI then
   	-- 	RAMailManager:updateReadMailDatasByType(1,self.mailType)
   	-- end 
   	self:updateInfo(self.mailType,false)
 
end



function RAMailListPageV6:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

function RAMailListPageV6:init()

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	
	UIExtend.setNodeVisible(titleCCB,"mCmnTitleEditNode",true)

	-- --初始化
	self.mMailMainListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mMailMainListSV")
	UIExtend.setNodeVisible(self.ccbfile,"mMailMainListSV",true)
	self.listSVSize = self.mMailMainListSV:getViewSize()

	
	self:setTitle(self.title)
	RAMailManager:setMainMailTitle(self.title)
	-- self:setNoReadMailNum(self.title)
	
	--下方按钮

	UIExtend.setCCLabelString(self.ccbfile,"mSelectAllLabel",_RALang('@SelectAll'))
	UIExtend.setCCLabelString(self.ccbfile,"mDeleteLabel",_RALang('@DeleteMailBtn'))
	UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Lock'))
	UIExtend.setCCLabelString(self.ccbfile,"mReadLabel",_RALang('@ReadMailBtn'))

	
end

function RAMailListPageV6:setTitle(name)
	UIExtend.setCCLabelString(self.titleCCB,"mTitle",name)
end


function RAMailListPageV6:showTips(isVisible)
	UIExtend.setNodeVisible(self.ccbfile,"mNoMailTips",isVisible) 
end
--mailType 为一个类型表 一个标签包含多种类型邮件
--isStarMail 收藏文件
function RAMailListPageV6:updateInfo(mailType,isOffset)
	self.mMailMainListSV:removeAllCell()
	self:clearMailCellTabs()
	-- 
	if isOffset==nil then isOffset=true end
	--记录下当前列表的显示type
	RAMailManager:setOptMailType(mailType)

	local scrollview = self.mMailMainListSV

	local totleCount = 0
	local tb=RAMailManager:getMailDatasByListType(mailType)
	totleCount=totleCount+#tb
	if totleCount==0 then
		self:showTips(true)
		return
	else
		self:showTips(false)
	end
	
	for k,v in pairs(tb) do
		local mailInfo=v
		local cell = CCBFileCell:create()
		local panel = RAMailMainCellV6:new({
				id =mailInfo.id,
        })
        self.cellContentSize=cell:getContentSize()
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailListCellV6.ccbi")
		scrollview:addCellBack(cell)
		table.insert(self.mailCellTab,panel)	 
	end		

	local preOffset = scrollview:getContentOffset()

	if self.deleMailNum then
		local delH=CELLH*self.deleMailNum
		preOffset=CCPoint(preOffset.x,preOffset.y+delH)
		self.deleMailNum=nil
	end 
	scrollview:orderCCBFileCells(scrollview:getViewSize().width)
	if isOffset then
		scrollview:setContentOffset(preOffset)
	end 

end



function RAMailListPageV6:registerMessageHandler()
    MessageManager.registerMessageHandler(refreshMailListMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(selectedMailMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
end

function RAMailListPageV6:removeMessageHandler()
    MessageManager.removeMessageHandler(refreshMailListMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(selectedMailMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
end



--取消选择所有
function RAMailListPageV6:onCancelBtn()
	CCLuaLog("RAMailListPageV6:onCancelBtn")

	self.isAllSelect = false
	for i,v in ipairs(self.mailCellTab) do
		local mailCell = v
		local isSelected = mailCell:getIsSelected()
		if isSelected then
			mailCell:setIsSelected(false)
		end 	
	end

end
--删除所有选择邮件
function RAMailListPageV6:onDeleteBtn()
	CCLuaLog("RAMailListPageV6:onDeleteBtn")

	--如果没有勾选则直接返回
	local isHaveSelect = self:isHaveCellSelect()
	if not isHaveSelect then
		local str = _RALang("@MailSelectTips")
		RARootManager.ShowMsgBox(str)
		return 
	end

	local mailDatas = RAMailManager:getMailDatas()
	RAMailManager:clearDeleteMailiIdTab()


	--把所有选中的邮件id发给服务器
	local idTab={}
	local rewardTab={}
	local lockTab={}
	local deleMailNum=0
	for k,v in ipairs(self.mailCellTab) do
		local mailCell = v

		--先判断是否勾选
		local isSelected = mailCell:getIsSelected()
		local mailId = mailCell:getMailId()
		if isSelected then

			--是否锁住
			local isLock =mailCell:getLock()

			--是否含有奖励
			local isReward = mailCell:isHaveReward()


			if isReward then 
				--提示有邮件没有领取奖励
				table.insert(rewardTab,mailId)
			end
			if isLock==1 then
				--提示有收藏文件 请先取消收藏
				table.insert(lockTab,mailId)
			else
				RAMailManager:addDeleteMailId(mailId)
				deleMailNum=deleMailNum+1
			end 
		end 
	end
	
    local confirmData = {}
	if next(lockTab) then  --收藏提示
		confirmData.labelText = _RALang("@DeleteLockMailTip")
		confirmData.lock = true
		RARootManager.OpenPage("RAMailDelConfirmPopUp", confirmData,false,true,true)
	elseif next(rewardTab) then   --奖励提示
		confirmData.labelText = _RALang("@DeleteRewardMailTip")
		confirmData.resultFun = function (isOk)
			if isOk then
				local deleteMailIdTab = RAMailManager:getDeleteMailIdTab()
				RAMailManager:sendDeleteMailCmdById(deleteMailIdTab)
			end
		end
		RARootManager.OpenPage("RAMailDelConfirmPopUp", confirmData,false,true,true)
	else
		local deleteMailIdTab = RAMailManager:getDeleteMailIdTab()
		RAMailManager:sendDeleteMailCmdById(deleteMailIdTab)
		self.deleMailNum=deleMailNum
	end 

end

--选择所有
function RAMailListPageV6:onSelectAllBtn()
	CCLuaLog("RAMailListPageV6:mSelectAllBtn")

	if self.isAllSelect then
		self:onCancelBtn()
		UIExtend.setNodeVisible(self.ccbfile,"mYesPic",false)
		-- UIExtend.setCCLabelString(self.ccbfile,"mSelectAllLabel",_RALang('@SelectAll'))
	else
		self.isAllSelect = true
		for i,v in ipairs(self.mailCellTab) do
			local mailCell = v
			local isSelected = mailCell:getIsSelected()
			if not isSelected then
				mailCell:setIsSelected(true)
			end 	
		end
		UIExtend.setNodeVisible(self.ccbfile,"mYesPic",true)
		-- UIExtend.setCCLabelString(self.ccbfile,"mSelectAllLabel",_RALang('@CancleAll'))
	end 

end

function RAMailListPageV6:onReadBtn()


	-- 把选中的邮件标记为已读
	local idTab={}
	for i,v in ipairs(self.mailCellTab) do
		local mailCell = v
		local isSelected = mailCell:getIsSelected()
		local mailId = mailCell:getMailId()
		if isSelected then
			RAMailManager:updateReadMailDatas(mailId,1)
			RAMailManager:updateRewardMailDatas(mailId,false)
			table.insert(idTab,mailId)
		end
	end
	--如果没有勾选则直接返回
	if not next(idTab) then
		local str = _RALang("@MailSelectTips")
		RARootManager.ShowMsgBox(str)
		return 
	end 
	
	RAMailManager:sendReadFinishMailCmd(idTab)
	MessageManager.sendMessage(refreshMailListMsg)
	MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
end

function RAMailListPageV6:clearMailCellTabs()
	for k,v in pairs(self.mailCellTab) do
		v=nil
	end
	self.mailCellTab={}
end

function RAMailListPageV6:Exit()

	self.mMailMainListSV:removeAllCell()
	self.mMailMainListSV:setViewSize(self.listSVSize)
	self:clearMailCellTabs()
    self:removeMessageHandler()
    RAMailManager:Exit()
    self.mailCellTab=nil
    self.isAllSelect=nil
    self.isAllSelectLock = nil
    self.canEdit = nil
	UIExtend.unLoadCCBFile(RAMailListPageV6)
	
end

function RAMailListPageV6:onClose()

	local RAMailConfig = RARequire("RAMailConfig")
    if self.mailType==RAMailConfig.Type.MONSTERYOULI then
   		RAMailManager:updateReadMailDatasByType(1,self.mailType)
   	end 

	RARootManager.CloseCurrPage()
end

--刷新锁定按钮上的显示字
function RAMailListPageV6:refreshLockBtnLabel()

	local mEditNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mEditNode")
	if mEditNode:isVisible() then
		local isAllSelectLock = self:isAllLock()
		self.isAllSelectLock = isAllSelectLock
		if isAllSelectLock then
			UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Unlock'))
		else
			UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Lock'))
		end 
	end 
end 

--判断勾选的是否都锁住
function RAMailListPageV6:isAllLock()
	local isAllLock = true
	for i,v in ipairs(self.mailCellTab) do
		local cellSelected = v:getIsSelected()
		local isLock = v:getLock()
		
		if cellSelected and isLock==0 then
			isAllLock = false
			break
		end 
	end
	return isAllLock
end

--判断所有的cell是否都锁住
function RAMailListPageV6:isAllCellLock()
	local isAllLock = true
	for i,v in ipairs(self.mailCellTab) do
		local isLock = v:getLock()
		if isLock==0 then
			isAllLock = false
			break
		end 
	end
	return isAllLock
end

--判断所有的cell是否有勾选
function RAMailListPageV6:isHaveCellSelect()
	local isHaveSelect = false
	for i,v in ipairs(self.mailCellTab) do
		local isSelect = v:getIsSelected()
		if isSelect then
			isHaveSelect = true
			break
		end 
	end
	return isHaveSelect
end

function RAMailListPageV6:onLockBtn()

	--如果没有勾选则直接返回
	local isHaveSelect = self:isHaveCellSelect()
	if not isHaveSelect then
		local str = _RALang("@MailSelectTips")
		RARootManager.ShowMsgBox(str)
		return 
	end 

	--判断是解锁还是锁住
	local idTab={}
	if not self.isAllSelectLock then
		
		self.isAllSelectLock = true
		for i,v in ipairs(self.mailCellTab) do
			local mailCell = v
			local isSelected = mailCell:getIsSelected()
			local isLock=mailCell:getLock()
			local mailId = mailCell:getMailId()
			if isSelected and isLock==0 then
				RAMailManager:updataLockMailDatas(mailId,1)
				mailCell:setLock(1)
				table.insert(idTab,mailId)
			end
		end
		
		RAMailManager:sendFavoriteMailCmd(idTab)
		UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Unlock'))
	
	else
		self.isAllSelectLock = false
		for i,v in ipairs(self.mailCellTab) do
			local mailCell = v
			local isSelected = mailCell:getIsSelected()
			local isLock=mailCell:getLock()
			local mailId = mailCell:getMailId()
			if isSelected and isLock==1 then
				RAMailManager:updataLockMailDatas(mailId,0)
				mailCell:setLock(0)
				table.insert(idTab,mailId)
			end
		end
		RAMailManager:sendCancleFavoriteMailCmd(idTab)
		UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Lock'))
	end
	local  tmpMailType = RAMailManager:getOptMailType() 
	MessageManager.sendMessage(refreshMailListMsg,{mailType=tmpMailType})
end

function RAMailListPageV6:mCommonTitleCCB_onCmnTitleEditBtn()
	local mEditNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mEditNode")
	local btnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mEditSizeNode")
	local btnH = btnNode:getContentSize().height
	local mOffset = self.mMailMainListSV:getContentOffset()

	if mEditNode:isVisible() then
		UIExtend.setNodeVisible(self.ccbfile,"mEditNode",false)
		self:showCellSelectNode(false)
		-- UIExtend.setNodeVisible(self.ccbfile,"mYesPic",false)
		self.canEdit = false

		self:runCellAnimation("NormalAni")

		--add scrollview pos
		self.mMailMainListSV:setContentOffset(ccp(mOffset.x,mOffset.y+btnH))
		self.mMailMainListSV:setViewSize(self.listSVSize)

		--取消所有选中的
		self:onCancelBtn()

		UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Lock'))
		-- UIExtend.setCCLabelString(self.ccbfile,"mSelectAllLabel",_RALang('@SelectAll'))

	else
		UIExtend.setNodeVisible(self.ccbfile,"mEditNode",true)
		UIExtend.setNodeVisible(self.ccbfile,"mYesPic",false)
		self.canEdit =true
		self:runCellAnimation("EditAni")
		self:showCellSelectNode(true)
		--adjust Scrollview pos
		self.mMailMainListSV:setContentOffset(ccp(mOffset.x,mOffset.y-btnH))
		self.mMailMainListSV:setViewSize(CCSize(self.listSVSize.width,self.listSVSize.height-btnH))

		--如果是全部锁住 则切换到解锁状态
		local isAllLock = RAMailListPageV6:isAllCellLock()
		if isAllLock then
			self.isAllSelectLock = true
			UIExtend.setCCLabelString(self.ccbfile,"mLockLabel",_RALang('@Unlock'))
		else
			self.isAllSelectLock = false
		end 

	end 
	
end


function RAMailListPageV6:runCellAnimation(name)
	for i,v in ipairs(self.mailCellTab) do
		local mailCell = v
		mailCell:runAnimation(name)
	end
end
function RAMailListPageV6:showCellSelectNode(isShow)
	for i,v in ipairs(self.mailCellTab) do
		local mailCell = v
		mailCell:showSelectNode(isShow)
	end
end

function RAMailListPageV6:mCommonTitleCCB_onBack()
	UIExtend.setNodeVisible(self.ccbfile,"mEditNode",false)
	self:showCellSelectNode(false)
	self:onCancelBtn()

	self:onClose()
end


--endregion
