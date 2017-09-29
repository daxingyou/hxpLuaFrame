--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


--私人信件 暂时只支持单人聊天

local RALogicUtil = RARequire("RALogicUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")

local refreshMailListMsg=MessageDefine_Mail.MSG_Refresh_MailList
local updateChatMsg=MessageDefine_Mail.MSG_Update_ChatMail
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local refreshChatRoomName = MessageDefine_Mail.MSG_Update_ChatRoomName
local OperationOkMsg = MessageDef_Packet.MSG_Operation_OK
-- local outChatRoom = MessageDef_Packet.MSG_Update_ChatRoomKickOut
local RAMailPrivateChatPage = BaseFunctionPage:new(...)

local CHATMSGWIDTH=415
local TAG=1000
local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id


	  local chatRoomMail = mailInfo.chatRoomMail

      --存储一份阅读数据
      RAMailManager:addChatRoomMailCheckDatas(id,mailInfo)
      RAMailPrivateChatPage:updateInfo(mailInfo)
   	elseif  message.messageID == updateChatMsg then
   		local roomId = message.roomId
   		--同一个聊天室才产生一条信息
   		if RAMailPrivateChatPage.id==roomId then

   			if message.tips then
   				local tipsStr=message.msg
   				RAMailPrivateChatPage:addTipsContent(tipsStr)
   				return 
   			end 
   			local playerId=message.id
	   		local chatMsg=message.msg
	   		RAMailPrivateChatPage:addChatContent(chatMsg,playerId)
   		end 
   	elseif  message.messageID == refreshChatRoomName then
   		local id = RAMailPrivateChatPage.id
    	if id==message.roomId then
    		local name = message.chatRoomName
    		RAMailPrivateChatPage:setTitle(name)
    	end
    elseif message.messageID == OperationOkMsg then 
    	local opcode = message.opcode
    	if opcode==HP_pb.MAIL_LEAVE_CHATROOM_C then --退出聊天室
    		RARootManager.ClosePage("RAMailPrivateChatPage")
    	end

    	
    -- elseif message.messageID == outChatRoom then 	--被踢出聊天室
    	
    end
end

-----------------------------------------------------------
local RAMailPrivateChatPageCell = {

}
function RAMailPrivateChatPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailPrivateChatPageCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
   
   	if not self.isMine then
   		UIExtend.setNodeVisible(ccbfile,"mOtherName",false)
   	end 
	--要考虑自适应高度

	local playerId=""
	local msg=""
	if self.isAdd then
		playerId=self.id
		msg=self.chatData

	else
		local chatData=self.chatData
		playerId=chatData.playerId 
		msg=chatData.msg
	end
	self.playerId=playerId

	local _,playerIcon=RAMailManager:getPlayerNameAndIcon(RAMailPrivateChatPage.id,playerId)

    playerIcon=RAMailUtility:getPlayerIcon(playerIcon)
    local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mHeadPortaitPicNode")
 	UIExtend.addNodeToAdaptParentNode(picNode,playerIcon,TAG)


 	UIExtend.setNodeVisible(ccbfile, "mVipNode", false)
	-- local tmpNode=UIExtend.getCCNodeFromCCB(ccbfile,"mGetWidthNode")
	local bubbleBg=UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBubblePic")
	self.bubbleBg=bubbleBg
	local orginSize=bubbleBg:getContentSize()
	-- UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",msg, tmpNode:getContentSize().width)
	--UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",msg,CHATMSGWIDTH)

	local mOthersSendLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOthersSendLabel")

    if self.mAddHeight and self.mAddHeight > 0 then     --表示多行 一行 height 26
        orginSize.width = CHATMSGWIDTH + 40

        --contentWidth = CHATMSGWIDTH
        UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",msg,CHATMSGWIDTH)

        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow1"):setVisible(true)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow2"):setVisible(false)
    else
        
        UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",msg)

        local chtml = mOthersSendLabel:getHTMLContentSize()
        local cw = chtml.width

        orginSize.width = cw + 50

        local mCopyBtnNode = UIExtend.getCCNodeFromCCB(ccbfile,"mCopyBtnNode")
        --local pos = ccp(0, 0)
        --pos.x, pos.y = mCopyBtnNode:getPosition()
        --320 - 100
        mCopyBtnNode:setPositionX(220)

        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow1"):setVisible(false)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow2"):setVisible(true)

    end

	--if self.mAddHeight and self.mAddHeight>0 then
		bubbleBg:setContentSize(CCSize(orginSize.width,orginSize.height+self.mAddHeight))
		ccbfile:setPositionY(ccbfile:getPositionY()+self.mAddHeight)
	--end 
end 

--刷新cell content size
function RAMailPrivateChatPageCell:onResizeCell(ccbfile)
	
	if not ccbfile then return end
	--local tmpNode=UIExtend.getCCNodeFromCCB(ccbfile,"mGetWidthNode")

	if self.isAdd then
		UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel", self.chatData, CHATMSGWIDTH) --tmpNode:getContentSize().width)
	else
		UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel", self.chatData.msg, CHATMSGWIDTH) -- tmpNode:getContentSize().width)
	end 
	
	local chtml = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOthersSendLabel"):getHTMLContentSize()
	local cw, ch = chtml.width, chtml.height
	self.mAddHeight=0
	if ch > 30 then
		 self.mAddHeight = ch-26
	end

	if self.mAddHeight>0 then
		local height = ccbfile:getContentSize().height+self.mAddHeight
		self.selfCell:setContentSize(CCSize(ccbfile:getContentSize().width, height))
	end 
	

end

function RAMailPrivateChatPageCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.mAddHeight and self.mAddHeight > 0 then
		ccbfile:setPositionY(ccbfile:getPositionY()-self.mAddHeight)
		self.bubbleBg:setContentSize(CCSize(self.bubbleBg:getContentSize().width,self.bubbleBg:getContentSize().height-self.mAddHeight))
	end
end


function RAMailPrivateChatPageCell:onCheck()	
	if not self.isMine then
		RARootManager.OpenPage('RAGeneralInfoPage', {playerId = self.playerId})
	end 
end


-----------------------------------------------------------
local RAMailChatTimeCell = {

}
function RAMailChatTimeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailChatTimeCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
   	local time=self.time
   	if not self.tips then
   		time=RAMailUtility:formatMailTime(time,true)
   	end 
   	
   	UIExtend.setCCLabelString(ccbfile,"mTime",time)
   	local timeTTF = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mTime")
    local lableWidth = timeTTF:getContentSize().width + 10
    local mTimeBG = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mTimeBG")
    mTimeBG:setContentSize(lableWidth,timeTTF:getContentSize().height)
end 

-----------------------------------------------------------
function RAMailPrivateChatPage:Enter(data)


	CCLuaLog("RAMailPrivateChatPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailChatPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	ccbfile:runAnimation("InAni")
    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end

function RAMailPrivateChatPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end


function RAMailPrivateChatPage:init()

	local mailInfo =RAMailManager:getMailById(self.id)

	--邮件标题  --对方玩家名称
	local title =mailInfo.titleNoGroup  
	if mailInfo.hasChangedName then
		-- RAMailManager:updateMailNameStatu(self.id,mailInfo.changeName)
		title=mailInfo.title
	end 
	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB = titleCCB
	UIExtend.setNodeVisible(titleCCB,"mAddMemNode",true)
	titleCCB:runAnimation("InAni")

	self.mSendBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mSendBtn")
	self.mSendBtn:setEnabled(false)

	--标题
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	self.chatListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mMailChatListSV")
	self.playerId=RAMailUtility:getMinePlayId()
	self:initEdibox()
	 
	
	--判断是否已读
	self.status = mailInfo.status

	--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailInfo = RAMailManager:getChatRoomMailCheckDatas(self.id)
		self:updateInfo(mailInfo)
	end 

end

function RAMailPrivateChatPage:initEdibox()
	self:initTouchLayer()
	local function sendEditboxEventHandler(eventType, node)

		if eventType == "began" then
        -- RAChatManager.MsgString = RAChatUIPage.editBox:getText()
        -- RAChatUIPage:setInputBoxLabelString()
        	self:resetEditAreaContentSize()
    	elseif eventType == "changed" then
        	-- CCLuaLog('CHAT changed')
        	local cont=self.sendEdibox:getText()
        
	        if #cont == 0 then 
	            self.mSendBtn:setEnabled(false)
	        else
	            self.mSendBtn:setEnabled(true)
	        end 
	        -- -- RAChatUIPage:setInputBoxLabelString()
	        self:resetEditAreaContentSize()

	    elseif eventType == "ended" then
	        -- CCLuaLog('CHAT ended')
	        -- RAChatManager.MsgString = RAChatUIPage.editBox:getText()
	        -- RAChatUIPage:setInputBoxLabelString()
	        -- RAChatUIPage:resetEditAreaContentSize()
	        local cont=self.sendEdibox:getText()
			local RAStringUtil = RARequire("RAStringUtil")
   			cont = RAStringUtil:replaceToStarForChat(cont)
			self.sendEdibox:setText(cont)
			self:resetEditAreaContentSize()
	    elseif eventType == "return" then
	    end
    end
	-- local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mInputBoxNode")
	-- inputNode:removeAllChildren()

	local sprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mInputBoxSprite")
    sprite:setContentSize(520,39)
    local size = sprite:getContentSize()
    sprite:removeFromParentAndCleanup(true)

	-- self.sendEdibox=UIExtend.createEditBox(self.ccbfile,"mInputBoxSprite",inputNode,sendEditboxEventHandler,ccp(5,0),nil,nil,nil,nil,nil,nil,nil,nil,nil,kEditBoxCloseKeybroadChat)
	if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS or CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        self.sendEdibox = CCNewEditBox:create(size, sprite,nil,nil,true,kEditBoxCloseKeybroadChat)
        self.sendEdibox:setIsAutoFitHeight(true)
    else
    	self.sendEdibox = CCEditBox:create(size, sprite)
    end
    local x, y = sprite:getPositionX(), sprite:getPositionY()
    local offsetW, offsetH = sprite:getContentSize().width/2, sprite:getContentSize().height/2
    self.sendEdibox:setPosition(CCPointMake(6, y-offsetH+12))
    self.sendEdibox:setAnchorPoint(CCPointMake(0, 0))
    self.ccbfile:addChild(self.sendEdibox)


	self.sendEdibox:setIsAutoFitHeight(true)
	local RAGameConfig = RARequire("RAGameConfig")
    self.sendEdibox:setIsDimensions(true)
    self.sendEdibox:setFontName(RAGameConfig.DefaultFontName)
    self.sendEdibox:setFontSize(27)
    self.sendEdibox:setAlignment(0)
    self.sendEdibox:setFontColor(RAGameConfig.COLOR.BLACK)
    self.sendEdibox:setInputMode(kEditBoxInputModeAny)
    self.sendEdibox:setMaxLength(200)
    self.sendEdibox:registerScriptEditBoxHandler(sendEditboxEventHandler)
    self.sendEdibox:setText('')
    self:resetEditAreaContentSize()
end

function RAMailPrivateChatPage:addTipsContent(tipsStr)
	local timeCell = CCBFileCell:create()
	local timePanel = RAMailChatTimeCell:new({
				time=tipsStr,
				tips=true
    })
	timeCell:registerFunctionHandler(timePanel)
	timeCell:setCCBFile("RAChatTimeCell.ccbi")
	self.chatListSV:addCellBack(timeCell)
	self.chatListSV:orderCCBFileCells()
	
	timeCell:locateTo(CCBFileCell.LT_Bottom, timeCell:getContentSize().height)
	--刷新聊天室的聊天信息 （本地存储）
    RAMailManager:updateChatRoomMailCheckDatas(chatRoomId,nil,tipsStr)

	 --判断是否退出聊天室:群主退出还是可以发消息

  	self:setSendBtnStatus()

	--如果在页面内也刷新下
  	RAMailManager:updateReadMailDatas(self.id,1)

  	MessageManager.sendMessage(refreshMailListMsg)
    MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList) 


end

function RAMailPrivateChatPage:setTitle(title)
	UIExtend.setCCLabelString(self.titleCCB,"mTitle",title)
end
--添加聊天内容
function RAMailPrivateChatPage:addChatContent(data,playerId)


	--第一条发送消息记录下时间
	local RA_Common=RARequire("common")
	--考虑是否要添加时间cell
	
	if not self.lastMsgTime then
		self.lastMsgTime=RA_Common:getCurTime()
		local ctime=self.lastMsgTime
		local timeCell = CCBFileCell:create()
		local timePanel = RAMailChatTimeCell:new({
				time=ctime
        })
		timeCell:registerFunctionHandler(timePanel)
		timeCell:setCCBFile("RAChatTimeCell.ccbi")
		self.chatListSV:addCellBack(timeCell)
	end 
	local isCreateTime=false
	if self.lastMsgTime then
		isCreateTime=RAMailUtility:isCreatChatTime(self.lastMsgTime)
		self.lastMsgTime=RA_Common:getCurTime()
	end 
	
	if isCreateTime then
		local ctime=self.lastMsgTime
		local timeCell = CCBFileCell:create()
		local timePanel = RAMailChatTimeCell:new({
				time=ctime
        })
		timeCell:registerFunctionHandler(timePanel)
		timeCell:setCCBFile("RAChatTimeCell.ccbi")
		self.chatListSV:addCellBack(timeCell)
	end 

	local mine=RAMailUtility:isMine(playerId)

	local ccbfileStr=""
	if mine then
		ccbfileStr="RAChatMyCell.ccbi"
	else
		ccbfileStr="RAChatOthersCell.ccbi"
	end 
	local cell = CCBFileCell:create()
	local panel = RAMailPrivateChatPageCell:new({
			chatData = data,
			id=playerId,
			isMine=mine,
			isAdd=true
	})
	panel.selfCell=cell
	cell:registerFunctionHandler(panel)
	cell:setCCBFile(ccbfileStr)
	self.chatListSV:addCellBack(cell)


    self.chatListSV:orderCCBFileCells()
    cell:locateTo(CCBFileCell.LT_Bottom, cell:getContentSize().height)

    if self.chatListSV:getContentSize().height < self.chatListSV:getViewSize().height then
		self.chatListSV:setTouchEnabled(false)
  	else
   		self.chatListSV:setTouchEnabled(true)
  	end

  	--如果在页面内也刷新下
  	RAMailManager:updateReadMailDatas(self.id,1) 
	MessageManager.sendMessage(refreshMailListMsg)
	MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)

end
function RAMailPrivateChatPage:updateInfo(mailDatas)

	
	
	--刷新聊天内容
	--自己在右 对方在左
	
	self.chatListSV:removeAllCell()
	local scrollView=self.chatListSV

	local totalH=0

	--第一次阅读从服务器直接返回 ChatRoomMail,之后都是从本地数据里取
	self.mailDatas=mailDatas
	if self.isFrstRead then
        
        self.createrId = self.mailDatas.chatRoomMail.createrId
		--聊天室创建的时间

		local ctime=RAMailManager:getMailTime(mailDatas.id)
		ctime = math.floor(ctime/1000)
		local timeCell = CCBFileCell:create()
		local timePanel = RAMailChatTimeCell:new({
				time=ctime
        })
		timeCell:registerFunctionHandler(timePanel)
		timeCell:setCCBFile("RAChatTimeCell.ccbi")
		scrollView:addCellBack(timeCell)
		local timeCellH=timeCell:getContentSize().height
		totalH=totalH+timeCellH

		local chatRoomDatas=mailDatas.chatRoomMail
		local chatRoomMsg=chatRoomDatas.msg
		local count=#chatRoomMsg
		for j=1,count do
			local chatRoomData=chatRoomMsg[j]

			--判断是消息还是提示
			if chatRoomData:HasField("playerId") then
				--判断是自己还是对方
				local playerId=chatRoomData.playerId
				local mine=RAMailUtility:isMine(playerId)

				local ccbfileStr=""
				if mine then
					ccbfileStr="RAChatMyCell.ccbi"
				else
					ccbfileStr="RAChatOthersCell.ccbi"
				end 
				local cell = CCBFileCell:create()
				local panel = RAMailPrivateChatPageCell:new({
						chatData = chatRoomData,
						isMine=mine
		        })
		        panel.selfCell=cell
				cell:registerFunctionHandler(panel)
				cell:setCCBFile(ccbfileStr)

				local cellH=cell:getContentSize().height
				totalH=totalH+cellH
				scrollView:addCellBack(cell)
			else
				local tipsMsg = RAMailManager:getchatTipsMsg(chatRoomData.msg)
				local tipsCell = CCBFileCell:create()
				local tipsPanel = RAMailChatTimeCell:new({
							time=tipsMsg,
							tips=true
			    })
				tipsCell:registerFunctionHandler(tipsPanel)
				tipsCell:setCCBFile("RAChatTimeCell.ccbi")
				scrollView:addCellBack(tipsCell)
			end 
			
		end

	else
		for i,v in ipairs(mailDatas) do
		
			local mailData=v
			--默认聊天室有的
			if i==1 then
				local chatRoomDatas=mailData.chatRoomMail
				self.createrId = chatRoomDatas.createrId
				local chatRoomMsg=chatRoomDatas.msg
				local count=#chatRoomMsg
				for j=1,count do
					local chatRoomData=chatRoomMsg[j]
					if chatRoomData:HasField("playerId") then
						--判断是自己还是对方
						local playerId=chatRoomData.playerId
						local mine=RAMailUtility:isMine(playerId)

						local ccbfileStr=""
						if mine then
							ccbfileStr="RAChatMyCell.ccbi"
						else
							ccbfileStr="RAChatOthersCell.ccbi"
						end 
						local cell = CCBFileCell:create()
						local panel = RAMailPrivateChatPageCell:new({
								chatData = chatRoomData,
								isMine=mine
				        })
				        panel.selfCell=cell
						cell:registerFunctionHandler(panel)
						cell:setCCBFile(ccbfileStr)

						local cellH=cell:getContentSize().height
						totalH=totalH+cellH
						scrollView:addCellBack(cell)
					else
						local tipsMsg = RAMailManager:getchatTipsMsg(chatRoomData.msg)
						local tipsCell = CCBFileCell:create()
						local tipsPanel = RAMailChatTimeCell:new({
									time=tipsMsg,
									tips=true
					    })
						tipsCell:registerFunctionHandler(tipsPanel)
						tipsCell:setCCBFile("RAChatTimeCell.ccbi")
						scrollView:addCellBack(tipsCell)
					end
					
				end

				--聊天室创建的时间
				local ctime=RAMailManager:getMailTime(mailData.id)
				ctime = math.floor(ctime/1000)
				
				local timeCell = CCBFileCell:create()
				local timePanel = RAMailChatTimeCell:new({
						time=ctime
		        })
				timeCell:registerFunctionHandler(timePanel)
				timeCell:setCCBFile("RAChatTimeCell.ccbi")
				scrollView:addCellFront(timeCell)
				local timeCellH=timeCell:getContentSize().height
				totalH=totalH+timeCellH

			else


				local playerId=mailData.playerId
				if playerId then
					--消息
					local mine=RAMailUtility:isMine(playerId)
					local ccbfileStr=""
					if mine then
						ccbfileStr="RAChatMyCell.ccbi"
					else
						ccbfileStr="RAChatOthersCell.ccbi"
					end 
					local cell = CCBFileCell:create()
					local panel = RAMailPrivateChatPageCell:new({
								chatData = mailData,
								isMine=mine
				    })
				    panel.selfCell=cell
					cell:registerFunctionHandler(panel)
					cell:setCCBFile(ccbfileStr)

					local cellH=cell:getContentSize().height
					totalH=totalH+cellH
					scrollView:addCellBack(cell)
				else
					--提示
					local tipsStr=mailData.msg
					local tipsCell = CCBFileCell:create()
					local tipsPanel = RAMailChatTimeCell:new({
								time=tipsStr,
								tips=true
				    })
					tipsCell:registerFunctionHandler(tipsPanel)
					tipsCell:setCCBFile("RAChatTimeCell.ccbi")
					scrollView:addCellBack(tipsCell)
				end
				
			end 
		end

	end 


	scrollView:orderCCBFileCells(scrollView:getViewSize().width)
	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
  	else
   		scrollView:setTouchEnabled(true)
  	end
	if totalH>scrollView:getViewSize().height then
		scrollView:setContentOffset(ccp(0,0))
	end 
	
    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(self.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
    end 
  	
  	if self.isFrstRead then
  		RAMailManager:updateIsFirstMailDatas(self.mailDatas.id,false)
  	end



  	--判断是否退出聊天室:群主退出还是可以发消息
  	local createId=RAMailManager:getMailCreaterId(self.id)
	local isCreater=nil
	if createId then
		isCreater=RAMailUtility:isMine(createId)
	else
		--没有加人踢人时
		isCreater=RAMailUtility:isMine(self.createrId)
	end
  	local memNum= RAMailManager:getChatRoomMemsNum(self.id)
  	local isExit = RAMailManager:getChatRoomExit(self.id)
	if (memNum==1 and not isCreater) or isExit then
		RAMailManager:setChatRoomExit(self.id,true)
	else
		RAMailManager:setChatRoomExit(self.id,false)
	end
  	self:setSendBtnStatus()
       
end



function RAMailPrivateChatPage:setSendBtnStatus()


	--如果已经退出聊天室就无法发送
  	local isExit = RAMailManager:getChatRoomExit(self.id)
  	if isExit then
  		self.sendEdibox:setEnabled(false)
  		UIExtend.setNodeVisible(self.titleCCB,"mAddMemNode",false)
  	else
  		self.sendEdibox:setEnabled(true)
  		UIExtend.setNodeVisible(self.titleCCB,"mAddMemNode",true)
  	end 
end
function RAMailPrivateChatPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(updateChatMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(refreshChatRoomName,OnReceiveMessage)
    MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
    
end
function RAMailPrivateChatPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(updateChatMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(refreshChatRoomName,OnReceiveMessage)
    MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
end

function RAMailPrivateChatPage:initTouchLayer()
   

    local callback = function(pEvent, pTouch)
        CCLuaLog("event name:"..pEvent)
        if pEvent == "began" then
 
            return 1
        end
        if pEvent == "ended" then
            local RALogicUtil = RARequire('RALogicUtil')
            local isInside = RALogicUtil:isTouchInside(self.mSendBtn, pTouch)
            
            if not isInside then 
                -- CCLuaLog('关闭键盘')
                self.sendEdibox:closeKeyboard()
            end 
        end
    end

    layer = CCLayer:create()
    layer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    layer:setPosition(0, 0)
    layer:setAnchorPoint(ccp(0, 0))
    layer:setTouchEnabled(true)
    layer:setTouchMode(kCCTouchesOneByOne)
    self:getRootNode():addChild(layer)
    layer:registerScriptTouchHandler(callback,false, 1 ,false)
 
    self.mLayer = layer
end

function RAMailPrivateChatPage:Exit()
	self.chatListSV:removeAllCell()
	self:removeMessageHandler()
	self.lastMsgTime=nil
	self.mLayer:removeFromParentAndCleanup(true)
	if self.sendEdibox then
		self.sendEdibox:removeFromParentAndCleanup(true)
		self.sendEdibox = nil
	end
	UIExtend.unLoadCCBFile(RAMailPrivateChatPage)
end

function RAMailPrivateChatPage:onClose()
	RAMailManager:sendReadFinishMailCmd({self.id})

	RARootManager.CloseCurrPage()
end

function RAMailPrivateChatPage:resetEditAreaContentSize()
	local perfersize = self.sendEdibox:getLabelContentSize()
    --底图
    local mBottomBG = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBottomBG")

    local newHeight = perfersize.height + 20 

    if newHeight <= 70 then 
    	--newHeight = 70
    end 
    mBottomBG:setContentSize(640, newHeight)
    --发送按钮
    local boxSize = self.mSendBtn:boundingBox().size
    local mSendBtnSizeHeight = boxSize.height
    local mSendBtnPosY = self.mSendBtn:getPositionY()
    local mSendBtnFinalPosY = perfersize.height - mSendBtnSizeHeight - 3
    self.mSendBtn:setPositionY(mSendBtnFinalPosY)
    --mSendBtn:setPositionX(mSendBtn:getPositionX() + 10)
    -- self.mSendBtn:setPositionX(259)
end 


function RAMailPrivateChatPage:onSendBtn()
	local msg=self.sendEdibox:getText()
	-- if msg == "" then
	-- 	local confirmData = {}
	-- 	confirmData.labelText = _RALang("@chatInputNil")
	-- 	RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
	--     return 
 --    end 
	--聊天室的id
	local id=self.id

	RAMailManager:sendChatRoomCmd(id,msg)
	self.sendEdibox:setText("")
	self.mSendBtn:setEnabled(false)
    self:resetEditAreaContentSize()
end

function RAMailPrivateChatPage:mCommonTitleCCB_onBack()
	RAMailManager:sendReadFinishMailCmd({self.id})
	self:onClose()
end

function RAMailPrivateChatPage:mCommonTitleCCB_onAddMemBtn()
	local data={}
	data.id = self.id
	data.createrId = self.createrId
	
	RARootManager.OpenPage("RAMailChatMemsPage",data)
end

--endregion
