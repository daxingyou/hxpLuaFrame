--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--系统邮件界面
RARequire("MessageDefine")
RARequire("MessageManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility=RARequire("RAMailUtility")
local RAGameConfig = RARequire("RAGameConfig")
local RAAllianceProtoManager=RARequire("RAAllianceProtoManager")
local RANetUtil=RARequire("RANetUtil")
local GuildManager_pb=RARequire("GuildManager_pb")
local RAMailConfig= RARequire("RAMailConfig")
local RA_Common=RARequire("common")
local HP_pb=RARequire("HP_pb")

local TAG=1000
local mFrameTime=0

local RAMailWritePageSelectDialog = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
	if message.messageID == MessageDef_ScrollViewCell.MSG_MailScoutListCell then
   		local isAdd = message.isAdd
   		local panelCell  = message.cell
   		
   		--refresh index
   		local cellOffsetIndex  = panelCell.cellOffest
   		local index = panelCell.cellIndex
   		RAMailWritePageSelectDialog:refreshCellIndex(index,isAdd,cellOffsetIndex)
     	if isAdd then
     		-- add cell
     		local datas = panelCell.memsData
     		RAMailWritePageSelectDialog:addAllianceMemsCell(datas,panelCell.cellIndex,panelCell.authority)
     		
     	else
     		RAMailWritePageSelectDialog:delAllianceMemsCell(panelCell.authority)
     	end 
   
    end
end

-----------------------------------------------------------------
local RASelectDialogCell = {

}
function RASelectDialogCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RASelectDialogCell:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAMailMainCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile


	local data=self.data
	local playerName=data.playerName
	self.playerName=playerName
	local icon=data.icon

	UIExtend.setCCLabelString(ccbfile,"mPlayerName",playerName)



	local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mCellIconNode")
	local iconName=RAMailUtility:getPlayerIcon(icon)
 	UIExtend.addNodeToAdaptParentNode(picNode,iconName,TAG)

	UIExtend.setNodeVisible(self.ccbfile,"mSelectBG",false)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",false)


	local isSelect = RAMailManager:getSelectPlayerId(self.data.playerId)
	self:setSelect(isSelect)

end

function RASelectDialogCell:onCellSelectBtn()
	local isSelect = self:getSelect()
	local isShow = nil
	if not isSelect then

		--上限提示  这里要区分是写邮件添加还是私人信件添加
		--私人信件首先要得到聊天室成员数目
		local totalNum = RAMailManager:getSelectTotalNum()
		local limitNum = RAMailConfig.ChatRoomMemLimit-1-RAMailWritePageSelectDialog.memNum
		if totalNum==limitNum then
			local str = _RALang("@ChatRoomLimitTips")
			RARootManager.ShowMsgBox(str)
			return 
		end 
		isShow=true
		RAMailManager:setSelectPlayerId(self.data.playerId,true)
		
	else
		isShow=false
		RAMailManager:setSelectPlayerId(self.data.playerId,false)
	end 
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectBG",isShow)

end

function RASelectDialogCell:getSelect()

	local isSelect = RAMailManager:getSelectPlayerId(self.data.playerId)
	return isSelect
end

function RASelectDialogCell:setSelect(isSelect)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",isSelect)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectBG",isSelect)
	RAMailManager:setSelectPlayerId(self.data.playerId,isSelect)
end
function RASelectDialogCell:getPlayerName()
	return self.data.playerName
end
--------------------------------------------------------------------------
local RASelectDialogTitleCell = {

}
function RASelectDialogTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RASelectDialogTitleCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local authority = self.authority
    UIExtend.setCCLabelString(ccbfile,"mCellTitle",_RALang("@AllianceMemAuthority",authority))

    -- UIExtend.setNodeVisible(ccbfile,"mArrowPic",false)
   	self.mArrowPic=UIExtend.getCCSpriteFromCCB(ccbfile,"mArrowPic")

   	if self.isOpen then
   		self.mArrowPic:setRotation(0)
   	else
   		self.mArrowPic:setRotation(270)
   	end 
end

function RASelectDialogTitleCell:onClick()
	if not self.isOpen then
		self.isOpen= true
		self.mArrowPic:setRotation(0)
	else
		self.isOpen= false
		self.mArrowPic:setRotation(270)
	end 

	--true时添加一个cell
	if self.isOpen then
		local params={}
		params.isAdd = true
		params.cell = self
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, params)
	else

		--删除这个cell
		local params={}
        params.isAdd = false
        params.cell = self
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, params)
		
	end 
end

function RASelectDialogTitleCell:refreshIndex(index)
	self.cellIndex=index
end

function RASelectDialogTitleCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.setNodeVisible(ccbfile,"mArrowPic",true)
end
--------------------------------------------------------------------------
function RAMailWritePageSelectDialog:Enter(data)


	CCLuaLog("RAMailWritePageSelectDialog:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailChatSelAddPopUpV6.ccbi",self)
	self.ccbfile  = ccbfile
	self.callBack=data.callBack
	self.netHandlers={}

	if data.memNum then
    	--获取聊天室成员个数
    	self.memNum = data.memNum
    	self.isChatPage =true
    	self.chatRoomMems = data.chatRoomMems
    else
    	self.memNum = 0
    	self.isChatPage =false
    end 

    self:init()

end

function RAMailWritePageSelectDialog:init()
	
	self.friendListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mFriendListSV")
	self.allianceListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mAllianceListSV")

	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@SelectSendPlayer"))

	self:registerMessageHandler()
	self:addHandler()
	self:clearCellTab()
    self:sendGetAllianceReq()
    self:setButtonEnabel(false)
    self:sendGetFriendsReq()
    self.allianceListSV:setVisible(true)
    self.friendListSV:setVisible(false)
end
function RAMailWritePageSelectDialog:refreshCellIndex(index,isAdd,offset)
	offset = offset or 1
	for i,v in ipairs(self.cellTitleTab) do
		local cell=v
		local tmpIndex=cell.cellIndex
		if isAdd then
			if tmpIndex>index then 
				cell:refreshIndex(tmpIndex+offset)
			end 
		else

			if tmpIndex>index then
				cell:refreshIndex(tmpIndex-offset) 
			end 
		end

	end
end

function RAMailWritePageSelectDialog:registerMessageHandler()
    MessageManager.registerMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end

function RAMailWritePageSelectDialog:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end
function RAMailWritePageSelectDialog:setButtonEnabel(isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mFriendsBtn",not isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mAllianceBtn",isEnable)
end

function RAMailWritePageSelectDialog:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then  
    	--联盟信息
        local info,_=RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)

        local isMine=RAMailWritePageSelectDialog:isOnlyMyOwn(info)
        if not isMine then
        	
        	local datas=RAMailWritePageSelectDialog:getAllianceData(info)
        	RAMailWritePageSelectDialog:updateAllianceInfo(datas)
        end   
        
    elseif pbCode == HP_pb.MAIL_CHAT_HISTORY_PLAYERS_S then  
    	--历史玩家信息
    	local msg = Mail_pb.HistoryPlayersRes()
    	msg:ParseFromString(buffer)

    	local memebers = msg.member
    	local count = #memebers
    	RAMailWritePageSelectDialog:updateFriendsInfo(memebers)
    end

end
function RAMailWritePageSelectDialog:isOnlyMyOwn(info)

	if #info>1 then 
		return false
	else
		return true
	end
end

--获取除了自己的联盟其他成员信息
function RAMailWritePageSelectDialog:getAllianceData(info)


	--0 sort by the name
	local nameTb={}
	for k,v in pairs(info) do
        local allianceMemeberInfo = v
		local playerName = allianceMemeberInfo.playerName
		local playerId=allianceMemeberInfo.playerId
		local isMine=RAMailUtility:isMine(playerId)
		local isExsit = self:isExsitMem(playerId)
		
		if not isMine and not isExsit then
			table.insert(nameTb,playerName)
		end 
	end
	table.sort(nameTb)
	local tb={}
	for i=1,#nameTb do
		local targetName = nameTb[i]
		for k,v in pairs(info) do
			local playerName = v.playerName
			if playerName==targetName then
				table.insert(tb,v)
			end 
		end
	end

	--1 get all level
	local authorityTb={}

	for i=1,#tb do
		local allianceMemeberInfo=tb[i]
		local authority = allianceMemeberInfo.authority
		local playerId=allianceMemeberInfo.playerId
		authorityTb[tostring(authority)]=0
	end

	--2 sort the key 
	local keyTab={}
	for k,v in pairs(authorityTb) do
		local key=tonumber(k)
		table.insert(keyTab,key)
	end

	table.sort(keyTab,function (v1,v2)
		return v1>v2
	end)

	--3 in the chatMemPage remove the exsit mem

	--4 get the same authority info
	local resultTb={}
	for i=1,#keyTab do
		local authority = keyTab[i]
		t={}
		t.authority=authority
		t.mems={}
		for j=1,#tb do
			local allianceMemeberInfo=tb[j]
			local targetAuthority = allianceMemeberInfo.authority
			if authority==targetAuthority then
				table.insert(t.mems,allianceMemeberInfo)
			end 
		end
		table.insert(resultTb,t)
	end
	return resultTb

end
function RAMailWritePageSelectDialog:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETMEMBERINFO_S, RAMailWritePageSelectDialog) 		
	self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHAT_HISTORY_PLAYERS_S, RAMailWritePageSelectDialog) 		
end

function RAMailWritePageSelectDialog:isExsitMem(targetPlayerId)
	-- body chatRoomMems
	if not self.isChatPage then return false end
	if self.chatRoomMems then
		for k,v in pairs(self.chatRoomMems) do
			local playerId = v.playerId
			if targetPlayerId==playerId then
				return true
			end
		end
		return false
	end
end
function RAMailWritePageSelectDialog:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end


function RAMailWritePageSelectDialog:sendGetAllianceReq()
	local allianceId=RAMailUtility:getOwnAllianceId()
	RAAllianceProtoManager:getGuildMemeberInfoReq(allianceId)
end

function RAMailWritePageSelectDialog:sendGetFriendsReq()
	RAMailManager:sendGetFriendsCmd()
end



function RAMailWritePageSelectDialog:genFriendsData(datas)
	local tb={}
	local count = #datas
	for i=1,count do
		local data = datas[i]
		local t={}
		t.playerId = data.playerId
		t.playerName = data.name
		t.icon = data.icon
		table.insert(tb,t)
	end
	return tb
end
function RAMailWritePageSelectDialog:updateFriendsInfo(friendsdatas)
	
	if friendsdatas==nil then return end
	self.friendListSV:removeAllCell() 
	local scrollview=self.friendListSV
	local tb=self:genFriendsData(friendsdatas)

	for i,v in ipairs(tb) do
		local friendData=v

		local playerId = friendData.playerId
		local isExsit = self:isExsitMem(playerId)
		--已经在聊天室的要剔除
		if not isExsit then
			local cell = CCBFileCell:create()
			local panel = RASelectDialogCell:new({
					data = friendData,
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailChatSelAddCellV6.ccbi")
			scrollview:addCellBack(cell)
			table.insert(self.cellTab,panel)
		end 

	end
	scrollview:orderCCBFileCells(scrollview:getViewSize().width)

end 
function RAMailWritePageSelectDialog:clearCellTab()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			v=nil
		end
	end 
	self.cellTab={}

	
	if self.cellTitleTab then
		for i,v in ipairs(self.cellTitleTab) do
			v=nil
		end
	end 
	self.cellTitleTab={}
	--添加的cell 临时存放表
	if self.memsCellTab then
		for i,v in pairs(self.memsCellTab) do			
			v=nil
		end
	end
	self.memsCellTab={}

end

function RAMailWritePageSelectDialog:addAllianceMemsCell(mems,index,key)
	--mems
	self.memsCellTab[key]={}
	for j,mem in ipairs(mems) do
		local memsData=mem
		local cell = CCBFileCell:create()
		local panel = RASelectDialogCell:new({
				data = memsData,
        })
        panel.selfCell=cell
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailChatSelAddCellV6.ccbi")
		self.allianceListSV:addCell(cell,index)
		table.insert(self.memsCellTab[key],panel)
		index = index +1
	end

	self.allianceListSV:orderCCBFileCells()
end

function RAMailWritePageSelectDialog:delAllianceMemsCell(key)
	--mems
	if self.memsCellTab[key] then
		for i,v in ipairs(self.memsCellTab[key]) do
			 self.allianceListSV:removeCell(v.selfCell)
		end
		self.memsCellTab[key]=nil
	end 
end

function RAMailWritePageSelectDialog:updateAllianceInfo(alliancedatas)

	self.allianceListSV:removeAllCell()
	local scrollview=self.allianceListSV


	local index=1
	self:clearCellTab()
	for i=1,#alliancedatas do
		local alliancedata=alliancedatas[i]
		local targetAuthority = alliancedata.authority
		local mems=alliancedata.mems
		local memsNum=#mems
		--title
		local titleCell = CCBFileCell:create()
		local titlePanel = RASelectDialogTitleCell:new({
				authority = targetAuthority,
				memsData=mems,
				cellIndex=index,
				cellOffest=memsNum
        })
		titleCell:registerFunctionHandler(titlePanel)
		titleCell:setCCBFile("RAMailChatSelAddCellTitleV6.ccbi")
		scrollview:addCellBack(titleCell)
		table.insert(self.cellTitleTab,titlePanel)

		index=index+1

		--mems
		-- local mems=alliancedata.mems
		-- for j,mem in ipairs(mems) do
		-- 	local memsData=mem
		-- 	local cell = CCBFileCell:create()
		-- 	local panel = RASelectDialogCell:new({
		-- 			data = memsData,
	 --        })
		-- 	cell:registerFunctionHandler(panel)
		-- 	cell:setCCBFile("RAMailChatSelAddCellV6.ccbi")
		-- 	scrollview:addCellBack(cell)
		-- 	table.insert(self.cellTab,panel)
		-- end

	end
	scrollview:orderCCBFileCells(scrollview:getViewSize().width)

end


function RAMailWritePageSelectDialog:resetCellStatus()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
		   local cell=v
		   cell:setSelect(false)
		end
	end
end
function RAMailWritePageSelectDialog:onAllianceBtn(sender)
	-- self:resetCellStatus()

	local event=sender:getControlBtnEvent()
	if event==CCControlEventTouchUpInside then
		self.friendListSV:setVisible(false)
		self.allianceListSV:setVisible(true)
		self:setButtonEnabel(false)
	end 
end


function RAMailWritePageSelectDialog:onFriendsBtn(sender)
	-- self:resetCellStatus()
	local event=sender:getControlBtnEvent()
	if event==CCControlEventTouchUpInside then
		self.friendListSV:setVisible(true)
		self.allianceListSV:setVisible(false)
		self:setButtonEnabel(true)
	end
end

function RAMailWritePageSelectDialog:onConfirm()
	local nameStr=""
	local namesTb={}
	local tb={}
	if self.memsCellTab then
		for i,v in pairs(self.memsCellTab) do
		   for k,cell in pairs(v) do
		   		local isSelect=cell:getSelect()
			    if isSelect then
			   		local playerName=cell:getPlayerName()
			   		local isExist=Utilitys.tableFind(tb,playerName)
			   		if not isExist then
			   			if not self.isChatPage then
				   			nameStr=nameStr..playerName..";"
				   		else
				   			table.insert(namesTb,playerName)
				   		end 
	                    table.insert(tb,playerName)
			   		end		   		
			   end 
		   end
		   
		end
	end

	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
		   local cell=v
		   local isSelect=cell:getSelect()
		   if isSelect then
		   		local playerName=cell:getPlayerName()
		   		local isExist=Utilitys.tableFind(tb,playerName)
		   		if not isExist then
		   			if not self.isChatPage then
			   			nameStr=nameStr..playerName..";"
			   		else
			   			table.insert(namesTb,playerName)
			   		end 
                    table.insert(tb,playerName)
		   		end		   		
		   end 
		end
	end

	if self.callBack then
		if not self.isChatPage then
			self.callBack(nameStr)
		else
			self.callBack(namesTb)
		end 
	end 
	self.onConfirmBtn= true
	self:onClose()
end

function RAMailWritePageSelectDialog:Exit()

  --如果不是点击确认按钮退出 清除选中
	if not self.onConfirmBtn then
		self:resetCellStatus()
	end 

	if self.isChatPage then
		RAMailManager:clearSelectPlayerId()
	end
	self.allianceListSV:removeAllCell()
	self:clearCellTab()
	self:removeHandler()
	self:removeMessageHandler()
	self.cellTab=nil
	self.onConfirmBtn=nil
	self.memNum = nil
    self.isChatPage =nil

	UIExtend.unLoadCCBFile(RAMailWritePageSelectDialog)
	
end

function RAMailWritePageSelectDialog:onClose()

	RARootManager.CloseCurrPage()
end




--endregion
