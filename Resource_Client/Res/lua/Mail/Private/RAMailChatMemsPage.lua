--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")

local RAMailChatMemManager = RARequire("RAMailChatMemManager")
local refreshMems = MessageDefine_Mail.MSG_Update_ChatRoomMem
local refreshChatRoomName = MessageDefine_Mail.MSG_Update_ChatRoomName
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK
local BeExitChatRoom=MessageDefine_Mail.MSG_BeExit_ChatRoom

local RAMailChatMemsPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == refreshMems then
 		RAMailChatMemsPage.editStatu=false
      	RAMailChatMemsPage:updateInfo()
     elseif message.messageID == OperationOkMsg then 
    	local opcode = message.opcode
    	if opcode==HP_pb.MAIL_CHANGE_CHATROOM_NAME_C then --自己修改名字后返回
    		--修改聊天室名称成功
    		-- RAMailChatMemsPage:setChatRoomName()
    	elseif  opcode==HP_pb.MAIL_LEAVE_CHATROOM_C then   --退出聊天室

            local mailDatas=RAMailManager:getMailDatas()
            mailDatas[RAMailChatMemsPage.id]=nil
            -- RAMailManager.chatRoomMemDatas[RAMailChatMemsPage.id]=nil
            RAMailManager:clearRoomMemsData(RAMailChatMemsPage.id)
            MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList,{isOffest=false})
            MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
    		RARootManager.ClosePage("RAMailChatMemsPage")
    	end
    elseif message.messageID==refreshChatRoomName then 	  --其他人收到刷新名字消息
    	local id = RAMailChatMemsPage.id
    	if id==message.roomId then
    		local name = message.chatRoomName
	    	RAMailChatMemsPage.chatRoomName=name
	    	RAMailChatMemsPage:setChatRoomName()
    	end
    elseif message.messageID==BeExitChatRoom then 	  --被其他成员踢出
    	RARootManager.ClosePage("RAMailChatMemsPage")
    end
end

-------------------------------------------------------------------------------------
local RAMailChatMemsCell = {

}
function RAMailChatMemsCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailChatMemsCell:onRefreshContent(ccbRoot)

	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    self:setVisible(true)
    if self.add or self.del then
    	return 
    end 
    local data=self.data
    local playerId = data.playerId
    local icon = data.icon
    local name = data.name

    local iconName=RAMailUtility:getPlayerIcon(icon)
    local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode")
 	UIExtend.addNodeToAdaptParentNode(picNode,iconName,RAMailConfig.TAG)

 	UIExtend.setCCLabelString(ccbfile,"mPlayerName",name)

 	local isEdit = RAMailChatMemManager:getMemsEditStatu(playerId)
 	UIExtend.setNodeVisible(ccbfile,"mSelectBtnNode",isEdit)

 	local isSelect = RAMailChatMemManager:getMemsSelectStatu(playerId)
 	self.select = isSelect
 	UIExtend.setNodeVisible(self.ccbfile,"mSelPic",isSelect)

 	--如果是自己就不能编辑
 	if self.mine then
 		UIExtend.setNodeVisible(ccbfile,"mSelectBtnNode",false)
 	end 
 	
end 

function RAMailChatMemsCell:setVisible(isShow)
	local ccbfile = self.ccbfile
	if not ccbfile then return end 
	if self.add then
		UIExtend.setNodeVisible(ccbfile,"mPlayerFrameNode",not isShow)
		UIExtend.setNodeVisible(ccbfile,"mAddBtnNode",isShow)
		UIExtend.setNodeVisible(ccbfile,"mSubBtnNode",not isShow)
	elseif self.del then
		UIExtend.setNodeVisible(ccbfile,"mPlayerFrameNode",not isShow)
		UIExtend.setNodeVisible(ccbfile,"mAddBtnNode",not isShow)
		UIExtend.setNodeVisible(ccbfile,"mSubBtnNode",isShow)
	else
		UIExtend.setNodeVisible(ccbfile,"mPlayerFrameNode",isShow)
		UIExtend.setNodeVisible(ccbfile,"mAddBtnNode",not isShow)
		UIExtend.setNodeVisible(ccbfile,"mSubBtnNode",not isShow)
	end 
end

function RAMailChatMemsCell:hideAll()
	local ccbfile = self.ccbfile
	UIExtend.setNodeVisible(ccbfile,"mPlayerFrameNode",false)
	UIExtend.setNodeVisible(ccbfile,"mAddBtnNode",false)
	UIExtend.setNodeVisible(ccbfile,"mSubBtnNode",false)
end

function RAMailChatMemsCell:onAddBtn()
	-- body  弹出选择框
	local data={}
	data.memNum = self.memNum
	data.chatRoomMems = RAMailChatMemsPage.chatRoomMems
	data.callBack=function (names)
		local mailUuid=RAMailChatMemsPage.id
		RAMailManager:sendAddChatRoomMemsCmd(mailUuid,names)
	end

	RARootManager.OpenPage("RAMailWritePageSelectDialog",data,true,true,true)
end

function RAMailChatMemsCell:onSubBtn()
	RAMailChatMemsPage.editStatu=true
	RAMailChatMemsPage:refreshEditCellStaue(false)
	RAMailChatMemsPage:refreshMemsCellStatus(true)
end

function RAMailChatMemsCell:onSelectBtn()
	if not self.select then
		self.select = true
	else
		self.select = false
	end
	local playerId = self.data.playerId
	RAMailChatMemManager:setMemsSelectStatu(playerId,self.select)
	UIExtend.setNodeVisible(self.ccbfile,"mSelPic",self.select)
end

function RAMailChatMemsCell:setEditStatu(isShow)
	local playerId = self.data.playerId
	RAMailChatMemManager:setMemsEditStatu(playerId,isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectBtnNode",isShow)
end	
function RAMailChatMemsCell:setSelectStatu(isSelect)
	self.select = isSelect
	local playerId = self.data.playerId
	RAMailChatMemManager:setMemsSelectStatu(playerId,self.select)
	UIExtend.setNodeVisible(self.ccbfile,"mSelPic",self.select)
end
function RAMailChatMemsCell:getSelectStatu()
	local playerId = self.data.playerId
	local isSelect = RAMailChatMemManager:getMemsSelectStatu(playerId)
	return isSelect

end

function RAMailChatMemsCell:getPlayerName()
	local playerName=self.data.name
	return playerName
end

-------------------------------------------------------------------------------------
local RAMailChatMemsTitleCell={}
function RAMailChatMemsTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailChatMemsTitleCell:onRefreshContent(ccbRoot)

	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local titleStr = self.title
    self:setTitle(titleStr)
   
end 

function RAMailChatMemsTitleCell:setTitle(titleStr)
	 UIExtend.setCCLabelString(self.ccbfile,"mCellName",titleStr)
end

--更改聊天室名字
function RAMailChatMemsTitleCell:onChangeNameBtn()
	
	--如果处于选择人状态就不让发送退出
	if  RAMailChatMemsPage.editStatu then 
		local str = _RALang("@DelSelectMemTips1")
		RARootManager.ShowMsgBox(str)
		return 
	end

	local data={}
	data.name = self.msg
	data.callBack=function (name)
		-- RAMailChatMemsPage.chatRoomName=name
		local mailUuid = RAMailChatMemsPage.id
		RAMailManager:sendChangeChatRoomNameCmd(mailUuid,name)
	end
	RARootManager.OpenPage("RAMailChatEditNameDlg",data,true,true,true)
end
-------------------------------------------------------------------------------------
local RAMailChatMemsBtnCell={}
function RAMailChatMemsBtnCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailChatMemsBtnCell:onRefreshContent(ccbRoot)

	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    if self.deleteSelect then
    	self:showBtns(true)
    	if not RAMailChatMemsPage.showDel or not RAMailChatMemsPage.isCreater then
    		self:hideAll()
    	end 
    elseif self.deleteQuit then
    	self:showBtns(false)
    end


end 

function RAMailChatMemsBtnCell:showBtns(isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mDeleteBtnNode",isShow)
    UIExtend.setNodeVisible(self.ccbfile,"mQuitBtnNode",not isShow)
end

function RAMailChatMemsBtnCell:hideAll()
	UIExtend.setNodeVisible(self.ccbfile,"mDeleteBtnNode",false)
    UIExtend.setNodeVisible(self.ccbfile,"mQuitBtnNode",false)
end
function RAMailChatMemsBtnCell:showAll()
	UIExtend.setNodeVisible(self.ccbfile,"mDeleteBtnNode",true)
    UIExtend.setNodeVisible(self.ccbfile,"mQuitBtnNode",true)
end

function RAMailChatMemsBtnCell:onDeleteAndExitBtn()

	--如果处于选择人状态就不让发送退出
	if  RAMailChatMemsPage.editStatu then 
		local str = _RALang("@DelSelectMemTips")
		RARootManager.ShowMsgBox(str)
		return 
	end
	--发送自己退出协议
	local data={}
	data.callBack=function (ok)
		if ok then
			local mailUuid=RAMailChatMemsPage.id
			RAMailManager:sendExitChatCmd(mailUuid)
		end 
	end
	RARootManager.OpenPage("RAMailChatQuitDlg",data,true,true,true)

end

function RAMailChatMemsBtnCell:onDeletePlayerBtn()
	--发送删除所选玩家协议

	--拿到勾选的cell
	local tb=RAMailChatMemsPage.cellTab
	local mailUuid=RAMailChatMemsPage.id
	local names={}
	for i,v in ipairs(tb) do
		local isSelect = v:getSelectStatu()
		if isSelect then
			local playerName=v:getPlayerName()
			table.insert(names,playerName)
		end 	
	end

	--如果为空表表示没有选中要删除的对象
	if not next(names) then
		local str=_RALang("@DeleteChatRoomMemsTips")
		RARootManager.ShowMsgBox(str)
		return 
	end 
	RAMailManager:sendDelChatRoomMemsCmd(mailUuid,names)
end
-------------------------------------------------------------------------------------
function RAMailChatMemsPage:Enter(data)


	CCLuaLog("RAMailChatMemsPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailGroupChatListPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id   			--邮件id
    self.createrId = data.createrId 	--聊天室创建者Id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailChatMemsPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end


function RAMailChatMemsPage:init()

	self.mMailMainListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mMailMainListSV")
	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	self:showCancleDelSelectBtn(false)
	self:updateInfo()
	self:initTitle()
end

function RAMailChatMemsPage:isShowDelEdit(count)
	if count<3 then
		return false
	end
	return true
end

function RAMailChatMemsPage:isShowTitle(count)
	if count<3 then
		return false
	end
	return true
end



function RAMailChatMemsPage:refreshEditCellStaue(isShow)
	if self.addCell then
		if isShow then
			self.addCell:setVisible(true)
		else
			self.addCell:hideAll()
		end 
		
	end 
	if self.delCell then
		if isShow then
			self.delCell:setVisible(true)
		else
			self.delCell:hideAll()
		end 
	end

	if self.delBtnCell then
		if isShow then
			self.delBtnCell:hideAll()
			self:showCancleDelSelectBtn(false)	
		else
			self.delBtnCell:showBtns(true)
			self:showCancleDelSelectBtn(true)
		end 
	end 

	if self.quitBtnCell then
		if isShow then
			self.quitBtnCell:showBtns(false)
		end 
	end 
end

function RAMailChatMemsPage:refreshMemsCellStatus(isShow)
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			local memCell = v
			memCell:setEditStatu(isShow)
		end
	end 
end

function RAMailChatMemsPage:resertMemsCellStatus()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			local memCell = v
			memCell:setEditStatu(false)
			memCell:setSelectStatu(false)
		end
	end 
end

function RAMailChatMemsPage:clearCellTab()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			v=nil
		end
		self.cellTab={}
	end 
	self.cellTab={}
end

function RAMailChatMemsPage:showCancleDelSelectBtn(isShow)
	UIExtend.setNodeVisible(self.titleCCB,"mCmnCloseNode",isShow)
end

function RAMailChatMemsPage:refreshMemCells(scrollView,tb,selfInfo)
	--select mine mem

	if next(selfInfo) then
		local selfmemData=RAMailChatMemData:new()
	    selfmemData:initByPbData(selfInfo)
	    local selfPlayerId = selfmemData.playerId
	    RAMailChatMemManager.memsTb[selfPlayerId]=selfmemData

	    local cell = CCBFileCell:create()
		local panel = RAMailChatMemsCell:new({
				data = selfmemData,
				mine= true
	    })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailGroupChatListCell1V6.ccbi")
		scrollView:addCellBack(cell)
	end 

	for i=1,#tb do
		local player=tb[i]
		local memData=RAMailChatMemData:new()
        memData:initByPbData(player)
		local playerId = memData.playerId
		RAMailChatMemManager.memsTb[playerId]=memData
		local isMine=RAMailUtility:isMine(playerId)
		if not isMine then
			local cell = CCBFileCell:create()
			local panel = RAMailChatMemsCell:new({
					data = memData
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailGroupChatListCell1V6.ccbi")
			scrollView:addCellBack(cell)
			table.insert(self.cellTab,panel)
		end

	end

end

function RAMailChatMemsPage:refreshEditCells(scrollView,isCreater,showDel,num)
	--refresh addCell
	local addCell = CCBFileCell:create()
	local addPanel = RAMailChatMemsCell:new({
				add = true,
				memNum = num
    })
	addCell:registerFunctionHandler(addPanel)
	addCell:setCCBFile("RAMailGroupChatListCell1V6.ccbi")
	scrollView:addCellBack(addCell)
	self.addCell=addPanel

	--refres delCell
	if isCreater and showDel then
		local delCell = CCBFileCell:create()
		local delPanel = RAMailChatMemsCell:new({
					del = true
	    })
		delCell:registerFunctionHandler(delPanel)
		delCell:setCCBFile("RAMailGroupChatListCell1V6.ccbi")
		scrollView:addCellBack(delCell)
		self.delCell=delPanel

		--Del btn
		local delBtnCell = CCBFileCell:create()
		local delBtnPanel = RAMailChatMemsBtnCell:new({
			      deleteSelect = true
	    })
		delBtnCell:registerFunctionHandler(delBtnPanel)
		delBtnCell:setCCBFile("RAMailGroupChatListCell2V6.ccbi")
		scrollView:addCellBack(delBtnCell)
		self.delBtnCell = delBtnPanel
	end
end

function RAMailChatMemsPage:refreshTitleCell(scrollView,showTitle)
	--refresh title
	if showTitle then

		local changeName = RAMailManager:getMailNameStatu(self.id)
		local chatRoomName=""
		local dlgMsg=""
		if not changeName then
			chatRoomName = RAMailManager:getChatRoomName(self.chatRoomMems)
			chatRoomName = RAMailUtility:getLimitStr(chatRoomName,20)
			dlgMsg=chatRoomName
			if self.chatMemNum>2 then
				chatRoomName = chatRoomName.."("..self.chatMemNum..")"
			end 
			
		else
			changeName = RAMailUtility:getLimitStr(changeName,20)
			dlgMsg=changeName
			if self.chatMemNum>2 then
				chatRoomName = changeName.."("..self.chatMemNum..")"
			end

		end 
		chatRoomName=chatRoomName..">"
		local titleCell = CCBFileCell:create()
		local titlePanel = RAMailChatMemsTitleCell:new({
					title = chatRoomName,
					msg=dlgMsg
	    })
		titleCell:registerFunctionHandler(titlePanel)
		titleCell:setCCBFile("RAMailGroupChatListCellTitleV6.ccbi")
		scrollView:addCellBack(titleCell)
		self.titleCell = titlePanel
	end 
end

function RAMailChatMemsPage:refreshQuitBtn(scrollView)
	local quitBtnCell = CCBFileCell:create()
	local quitBtnPanel = RAMailChatMemsBtnCell:new({
		 deleteQuit = true
    })
	quitBtnCell:registerFunctionHandler(quitBtnPanel)
	quitBtnCell:setCCBFile("RAMailGroupChatListCell2V6.ccbi")
	self.quitBtnCell = quitBtnPanel
	scrollView:addCellBack(quitBtnCell)
end

function RAMailChatMemsPage:initTitle( )
	--refresh title
	local changeName = RAMailManager:getMailNameStatu(self.id)
	if not changeName then
		local chatRoomName = RAMailManager:getChatRoomName(self.chatRoomMems)
		chatRoomName = RAMailUtility:getLimitStr(chatRoomName,20)
        self.chatRoomName = chatRoomName
		if self.chatMemNum>2 then
			self.chatRoomName = chatRoomName.."("..self.chatMemNum..")"
		end 
		
	else
		changeName = RAMailUtility:getLimitStr(changeName,20)
        self.chatRoomName = changeName
		if self.chatMemNum>2 then
			self.chatRoomName = changeName.."("..self.chatMemNum..")"
		end 
	end 
	UIExtend.setCCLabelString(self.titleCCB,"mTitle",self.chatRoomName)
end

function RAMailChatMemsPage:updateInfo()
	--聊天室当前成员信息 包含自己
	local chatRoomMems = RAMailManager:getChatRoomMems(self.id)
	if chatRoomMems==nil then return end
	
	local tb,selfInfo=RAMailUtility:sortChatRoomMemData(chatRoomMems)
	self.chatRoomMems = tb
	RAMailChatMemManager:resetMemsStatu()

	local count=RAMailManager:getChatRoomMemsNum(self.id)
	local num = count
	self.chatMemNum = count
	local showTitle=self:isShowTitle(num)
	local showDel=self:isShowDelEdit(num)
	self.showDel = showDel

	local createId=RAMailManager:getMailCreaterId(self.id)
	local isCreater=nil
	if createId then
		isCreater=RAMailUtility:isMine(createId)
	else
		--没有加人踢人时
		isCreater=RAMailUtility:isMine(self.createrId)
	end
	
	self.isCreater = isCreater
	
	

	self:clearCellTab()
	self.addCell=nil
	self.delCell=nil
	self.delBtnCell=nil
	self.quitBtnCell=nil
	self.mMailMainListSV:removeAllCell()
	local scrollView = self.mMailMainListSV

	--refresh memCells
	self:refreshMemCells(scrollView,tb,selfInfo)

	--refresh eidtCell
	self:refreshEditCells(scrollView,isCreater,showDel,self.chatMemNum)

	--refresh titleCell
	self:refreshTitleCell(scrollView,showTitle)

	--refresh delAndQuitBtnCell
	self:refreshQuitBtn(scrollView)

    scrollView:orderCCBFileCells(scrollView:getContentSize().width)

    self:refreshEditCellStaue(true)


end


function RAMailChatMemsPage:registerMessageHandler()
	MessageManager.registerMessageHandler(refreshMems,OnReceiveMessage)
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(refreshChatRoomName,OnReceiveMessage)
    MessageManager.registerMessageHandler(BeExitChatRoom,OnReceiveMessage)
    
end

function RAMailChatMemsPage:removeMessageHandler()
	MessageManager.removeMessageHandler(refreshMems,OnReceiveMessage)
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(refreshChatRoomName,OnReceiveMessage)
    MessageManager.removeMessageHandler(BeExitChatRoom,OnReceiveMessage)
end


function RAMailChatMemsPage:Exit()

	self.mMailMainListSV:removeAllCell()
	self:clearCellTab()
	RAMailChatMemManager:resetMemsStatu()
	self.cellTab=nil
	self.chatMemNum=nil
	self.chatRoomName=nil
	self.editStatu = nil
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailChatMemsPage)
	
end

--取消删除选中
function RAMailChatMemsPage:mCommonTitleCCB_onCmnClose()
	--显示编辑cell（add/del） 隐藏按钮cell
	self:refreshEditCellStaue(true)

	--刷新cell的状态 恢复不可编辑状态 恢复未选中
	self:resertMemsCellStatus()

	RAMailChatMemManager:resetMemsStatu()

	self.editStatu =false

end

function RAMailChatMemsPage:setChatRoomName()

	--名字cell
	local chatRoomName = RAMailUtility:getLimitStr(self.chatRoomName,30)
	if self.titleCell then
		self.titleCell:setTitle(chatRoomName..">")
	end 
	

	UIExtend.setCCLabelString(self.titleCCB,"mTitle",chatRoomName)

end

function RAMailChatMemsPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailChatMemsPage:mCommonTitleCCB_onBack()
	self:onClose()
end



