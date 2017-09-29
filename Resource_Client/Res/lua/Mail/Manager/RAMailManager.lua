--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire("MessageDefine")
RARequire("MessageManager")
local Const_pb = RARequire("Const_pb")
local Mail_pb = RARequire("Mail_pb")
local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire("RANetUtil")
local  Utilitys = RARequire("Utilitys")
local RAMailUtility = RARequire("RAMailUtility")
local RAGameConfig = RARequire("RAGameConfig")
local RAStringUtil = RARequire("RAStringUtil")
local RARootManager = RARequire("RARootManager")
local RAMailConfig=RARequire("RAMailConfig")
local RAMailManager={}
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList


RAMailManager.netHandlers = {}   -- 存放监听协议


RAMailManager.mailDatas={}   	  --邮件简洁数据  --通过简洁数据可以知道邮件的状态
RAMailManager.deleteMailIdTab={}  --存储一份删除列表id
RAMailManager.isFirstReadTab={}   --存储一份是否第一次阅读邮件id
RAMailManager.optMailType = nil   --记录当前列表属于mailType ：nil或{}表示显示所有种类
RAMailManager.mainMailTitle = nil --主界面title

RAMailManager.systemMailCheckDatas={} --从服务器返回的数据 本地存一份 再次打开的时候不请求
RAMailManager.resCollectMailCheckDatas={}
RAMailManager.playerBattleMailCheckDatas={}
RAMailManager.monsterBattleMailCheckDatas={}
RAMailManager.chatRoomCheckDatas={}   --聊天信息存储
RAMailManager.chatRoomMemDatas={}   --聊天成员信息存储
RAMailManager.detectMailCheckDatas={}
RAMailManager.allianceMailCheckDatas={}

--私人信息 联盟邮件 战斗信息 系统消息 活动邮件 反击尤里 采集报告
RAMailManager.TipsTb={
	false,false,false,false,false,false,false
}

RAMailSimpleData = {}

--构造函数
function RAMailSimpleData:new(o)
    o = o or {}
    o.id = nil       
    o.type=nil
    o.title=nil
    o.subTitle=nil
    o.ctime=nil
    -- o.saved=nil
    o.status=nil
    o.hasReward=nil
    o.configId=nil
    o.lock = nil    -- 0未锁 1已锁
    o.icon = {}
    o.msg = nil
    o.selected = false		--是否选中
    o.canEdit = false		--是否编辑
    o.exit = false			--是否退出聊天室
    o.changeName = nil 		--聊天室名称 
    o.hasChangedName=nil    --是否改过聊天室名称
    o.createrId=nil 		--聊天室创建者
    o.mem =nil 			    --当前聊天室成员信息
    o.titleNoGroup=""		--不加群组标示
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAMailSimpleData:initByPbData(mailSimpleData)

	self.id = mailSimpleData.id       
    self.type=mailSimpleData.type
    self.ctime=mailSimpleData.ctime
    -- self.saved=mailSimpleData.saved
    self.status=mailSimpleData.status
    self.hasReward=mailSimpleData.hasReward

    if mailSimpleData:HasField('mailId') then
    	self.configId=mailSimpleData.mailId
    end 

    if mailSimpleData:HasField('lock') then
    	self.lock=mailSimpleData.lock
    end 


    local icons = mailSimpleData.icon
    if icons then
    	local num = #icons
	    for i=1,num do
	    	local iconId = icons[i]
	    	table.insert(self.icon,iconId)
	    end
    end 

    -- if mailSimpleData:HasField("msg") then
    -- 	self.msg = mailSimpleData.msg
    -- end

    -- if mailSimpleData:HasField("hasChangedName") then
    -- 	self.hasChangedName = mailSimpleData.hasChangedName
    -- end

	local RAMailConfig = RARequire("RAMailConfig")
    --if mailSimpleData:HasField('title') then

	--私人信件特殊处理
	if mailSimpleData.mailId~=RAMailConfig.Page.Prviate then
		if mailSimpleData:HasField('title') then
			self.title=mailSimpleData.title
		end 		
	else

		--私人信件有title的时候表示改过名字
		if mailSimpleData:HasField('title') then
			self.hasChangedName=1
		end 		

		--存储下聊天室成员信息
	
		RAMailManager:genChatMemData(self.id ,mailSimpleData.mem)


		local chatRoomMems = RAMailManager:getChatRoomMems(self.id)
    	local title,memNum = RAMailManager:getChatRoomName(chatRoomMems)
		local str=title
		local tStr=str
		if memNum>2 then
			--群组
			str = _RALang("@ChatGroup")..str
			str=  RAMailUtility:getLimitStr(str,20).."("..memNum..")"
			self.title = str
			self.titleNoGroup = RAMailUtility:getLimitStr(tStr,20).."("..memNum..")"
		else
			--私人
			self.title = title
			self.titleNoGroup = self.title
		end

		if self.hasChangedName then
			self.changeName = RAMailUtility:getLimitStr(mailSimpleData.title,20)
			local num=RAMailManager:getChatRoomMemsNum(self.id)
			self.title = self.changeName .."("..num..")"
			self.titleNoGroup = self.title
		end 

		
		
	end 
    	
    --end

    if mailSimpleData:HasField('subTitle') then
    	if mailSimpleData.mailId~=RAMailConfig.Page.Prviate then
    		self.subTitle=mailSimpleData.subTitle
    	else

    		if string.find(tostring(mailSimpleData.subTitle),":") then
    			--消息
    			self.subTitle = mailSimpleData.subTitle
    		else
    			--提示

    			--类型，操作者，被操作者
    			local tipsMsg = RAMailManager:getchatTipsMsg(mailSimpleData.subTitle)
    			self.subTitle = tipsMsg
    		end 
    	end 
    end 
end

function RAMailManager:Enter()
	self:addHandler()
end

function RAMailManager:Exit()
	self:removeHandler()
end

--添加协议监听
function RAMailManager:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHECK_MAIL_S, RAMailManager) 				--非报告类邮件返回监听
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHECK_MAIL_BY_TYPE_S, RAMailManager) 		--报告类邮件返回监听
    -- self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHAT_ADD_PLAYERS_S, RAMailManager) 			--添加聊天室成员返回监听
    -- self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHAT_DEL_PLAYERS_S, RAMailManager) 			--删除聊天室成员返回监听
end

--移除协议监听
function RAMailManager:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end 

--添加邮件
function RAMailManager:addMailDatas(id,mailInfo)
	if self.mailDatas[id]==nil then
		self.isFirstReadTab[id]=true
	local mailData=RAMailSimpleData:new()
        mailData:initByPbData(mailInfo)
		self.mailDatas[id]=mailData 
	end 
end

function RAMailManager:clearIsFirstReadTab()
	for k,v in pairs(self.isFirstReadTab) do
		v=nil
	end
	self.isFirstReadTab={}
end
--判断是否第一次阅读
function RAMailManager:isMailFirstRead(id)
	return self.isFirstReadTab[id]
end
function RAMailManager:clearMailDatas()
	for k,v in pairs(self.mailDatas) do
		v=nil
	end
	self.mailDatas={}
end

function RAMailManager:getTotalMailNum()
	return self.totleMailNum
end
function RAMailManager:reset()
	self:clearMailDatas()
	self:clearDeleteMailiIdTab()
	self:clearIsFirstReadTab()
	self:clearAllCheckMailDatas()
	self:resetMailTips()
	self.optMailType = nil
	self.mainMailTitle=nil
	self.selectPlayerId = nil
	self.setIsSelectAll = nil
	self:Exit()
end

--得到所有未读邮件的数目
function RAMailManager:getNewMailNum()
	local count = 0
	for k,v in pairs(self.mailDatas) do
		local  mailData =v
		if mailData.status==0 then
			count=count+1
		end 
	end
	return count
end

--得到某种分类下的未读邮件
function RAMailManager:getNewMailNumInType(mailTypeTab)
	local count =0 

	if mailTypeTab==nil or not next(mailTypeTab) then
		count =self:getNewMailNum()
		return count
	end 
	for i,v in pairs(mailTypeTab) do
		local mailType = v
		for k1,v1 in pairs(self.mailDatas) do
			local mailData = v1
			if mailData.type==mailType and mailData.status==0 then
				count=count+1
			end 
		end
	end
	return count
end
--得到非报告类未读邮件的数目
function RAMailManager:getNotReportMailNum()
	local count = 0
	for k,v in pairs(self.mailDatas) do
		local  mailData =v
		local  tmpMailType = mailData.type
		local  isReportMail = RAMailUtility:isReportMail(tmpMailType)
		if mailData.status==0 and (not isReportMail)then
			count=count+1
		end 
	end
	return count
end
--刷新主界面底部的邮件通知
function RAMailManager:refreshMainUIBottomMailNum()
	local newMailNum = self:getNewMailNum()
     local data={}
     data.menuType= RAGameConfig.MainUIMenuType.Mail
     data.num = newMailNum
     data.isDirChange=true
     MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,data)
end

--根据邮件类型获取数据
function RAMailManager:getMailDatasByType(mailType)
	if not mailType or not next(self.mailDatas) then return {} end
	local tmpMailDatas={}
	for k,v in pairs(self.mailDatas) do
		local tmpMailType = v.type
		local isReportMail = RAMailUtility:isReportMail(tmpMailType)

		--只返回非报告类邮件
		if  tmpMailType==mailType and (not isReportMail) then
			tmpMailDatas[v.id]=v
		end 
	end
	local tb = RAMailUtility:sortMailDatasByTime(tmpMailDatas)
	return tb
end
--根据邮件列表类型获取数据
function RAMailManager:getMailDatasByListType(mailType)

	local tmpMailDatas={}
	local RAMailConfig = RARequire("RAMailConfig")
	for k,v in pairs(self.mailDatas) do
		-- local tmpMailType = v.type
		local configId = v.configId
		local tmpMailType = self:getMailTypeByConfigId(configId)

		--只返回非报告类邮件
		if  tmpMailType~=RAMailConfig.Type.RESCOLLECT and tmpMailType==mailType  then
			tmpMailDatas[v.id]=v
		end 
	end


	local tb = RAMailUtility:sortMailDatasByTime(tmpMailDatas)
	return tb
end

function RAMailManager:getMailTime(id)
	if id==nil then return end
	local mailInfo = self:getMailById(id)
	return mailInfo.ctime
end

function RAMailManager:isReachLimitMailCount(mailType)
	local MailCount=0
	for k,v in pairs(self.mailDatas) do
			local configId = v.configId
			local tmpMailType = self:getMailTypeByConfigId(configId)

			if tmpMailType==mailType then
				MailCount=MailCount+1
			end
		end
	
	local RAMailConfig = RARequire('RAMailConfig')
	if MailCount==RAMailConfig.LimitMailNum then
		 return true
	end
	return false
end

function RAMailManager:isReachLimitFightMailCount()
	local RAMailConfig = RARequire('RAMailConfig')
	for k,v in pairs(RAMailConfig.FightDetailType) do
		local targetType = v
		local MailCount=0
		for key,value in pairs(self.mailDatas) do
				local configId = value.configId
				local tmpMailType = self:getFightMailTypeByConfigId(configId)
				if tmpMailType==targetType then
					MailCount=MailCount+1
				end
			end
		if MailCount>=RAMailConfig.LimitMailNum then
			 return true
		end
		return false
	end
	
end

--获得战斗邮件子类型

function RAMailManager:getFightMailTypeByConfigId(configId)
	local RAMailConfig = RARequire('RAMailConfig')
	if Utilitys.tableFind(RAMailConfig.FightConfigId.BE_HIT_FLY,configId) then
		return RAMailConfig.FightDetailType.BE_HIT_FLY
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.CAMP,configId) then
		return RAMailConfig.FightDetailType.CAMP
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.DETECT,configId) then
		return RAMailConfig.FightDetailType.DETECT
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.BE_DETECTED_MAIL,configId) then
		return RAMailConfig.FightDetailType.BE_DETECTED_MAIL
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.CURE,configId) then
		return RAMailConfig.FightDetailType.CURE
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.FIGHT,configId) then
		return RAMailConfig.FightDetailType.FIGHT
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.BE_NUCLEAR_BOMBED,configId) then
		return RAMailConfig.FightDetailType.BE_NUCLEAR_BOMBED
	elseif Utilitys.tableFind(RAMailConfig.FightConfigId.BE_STORM_BOMBED,configId) then
		return RAMailConfig.FightDetailType.BE_STORM_BOMBED
	end 
end
--返回列表数据 非报告类的
function RAMailManager:getMailListDatas()
	local tmpMailDatas={}
	for k,v in pairs(self.mailDatas) do
		local tmpMailType = v.type
		local isReportMail = RAMailUtility:isReportMail(tmpMailType)

		--只返回非报告类邮件
		if not isReportMail then
			tmpMailDatas[v.id]=v
		end 
	end
	local tb = RAMailUtility:sortMailDatasByTime(tmpMailDatas)
	return tb
end

--获取收藏的邮件
function RAMailManager:getFavoriteMailDatas()
	local tmpMailDatas={}
	for k,v in pairs(self.mailDatas) do
		local mailInfo = v
		local tmpMailType = mailInfo.type
		local isReportMail = RAMailUtility:isReportMail(tmpMailType)
		--只返回非报告类邮件
		if mailInfo.saved and (not isReportMail)  then
			tmpMailDatas[v.id]=v
		end 
	end
	local tb = RAMailUtility:sortMailDatasByTime(tmpMailDatas)
	return tb
end


--添加协议监听返回处理
function RAMailManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.MAIL_CHECK_MAIL_S then  
    	local msg = Mail_pb.HPCheckMailRes()
        msg:ParseFromString(buffer)

        local curtime = os.time()
        local costTime = curtime-self.lastTime

        CCLuaLog("the mail proto start time is  "..self.lastTime)
        CCLuaLog("the mail proto back time is  "..curtime)
        CCLuaLog("the mail proto cost time is  "..costTime)

        if msg:HasField("commonMail") then
        	self:updateMailMsg(msg.id,msg.commonMail.mailMessage)
    	end

        --发送消息 刷新界面
      	MessageManager.sendMessage(MessageDefine_Mail.MSG_Read_Mail,{mailDatas=msg})
    elseif pbCode==HP_pb.MAIL_CHECK_MAIL_BY_TYPE_S then
    	local msg = Mail_pb.HPCheckMailByTypeRes() 
    	msg:ParseFromString(buffer)
    	MessageManager.sendMessage(MessageDefine_Mail.MSG_Read_ReportMail,{mailDatas=msg})

    end

end


--自己刷新
-- //刷新添加或删除玩家
-- message RefreshMembers{
-- 	required string mailUuid		= 1;//邮件ID
-- 	repeated ChatRoomMember member	= 2;//添加或删除的玩家的信息
-- 	optional string	operatorName	= 3;//操作者名称
-- }

function RAMailManager:getChatRoomName(chatRoomMems)
	if chatRoomMems==nil then return "",0 end
	local name=""
	local count=0
	-- for k,v in pairs(chatRoomMems) do
	-- 	local mem = v
	-- 	local playerName = mem.name
	-- 	if count==0 then
	-- 		name = name ..playerName
	-- 	else
	-- 		name = name ..","..playerName
	-- 	end
	-- 	count = count + 1
	-- end

	for i=1,#chatRoomMems do
		local mem = chatRoomMems[i]
		local playerName = mem.name

		local isDelete=mem.isDelete 
		if not isDelete then
			if count==0 then
				name = name ..playerName
			else
				name = name ..","..playerName
			end
			count = count + 1
		end 
	end
	return name,count
end

function RAMailManager:refreshChatMsg(msg,isAdd)
	local uuid = msg.mailUuid
	local memberDatas=msg.member  --变化的聊天室成员
	self:updateRoomMemsData(uuid,memberDatas,isAdd)

	--发送消息:刷新：1添加删除界面cell、title  2 list界面标题和副标题
	MessageManager.sendMessage(MessageDefine_Mail.MSG_Update_ChatRoomMem)
	
end
function RAMailManager:updateChatGroupSubAndTitle(mailUuid,memberDatas,operatorName,keyStr,isMine)

	-- --替换聊天邮件列表的subtitle,title
    local count=#memberDatas
    local uuid = mailUuid
    local editPlayerName = operatorName
	local subtitle=""
	for i=1,count do
		local mems=memberDatas[i]
		local playerName = mems.name
		if i==count then
            subtitle=subtitle..playerName
		else
            subtitle=subtitle..playerName..","
		end
	end

	local tmpStr = subtitle

	if isMine then
		subtitle = _RALang(keyStr,subtitle)
	else
		subtitle = _RALang(keyStr,editPlayerName,subtitle)
	end 
	
    self:updateChatRoomSimplleData(uuid,subtitle)
end

--判断一封邮件是否选中
function RAMailManager:getSelectMailStatus(id)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		return mailData.selected 
	end 
	return false
end
function RAMailManager:updataSelectMailDatas(id,isSelect)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.selected = isSelect
	end 
end


--更改通用邮件的内容
function RAMailManager:updateMailMsg(id,msg)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.msg = msg
	end 
end

--判断一封邮件是否改名
function RAMailManager:getMailNameStatu(id)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		return mailData.changeName 
	end 
	return false
end
function RAMailManager:updateMailNameStatu(id,isChangeName)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.changeName = isChangeName
		mailData.hasChangedName=true
	end 
end

--聊天室创建者
function RAMailManager:getMailCreaterId(id)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		return mailData.createrId 
	end 
	return nil
end
function RAMailManager:updateMailCreaterId(id,createrId)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.createrId = createrId
	end 
end

--判断一封邮件是否可编辑
function RAMailManager:getEditMailStatus(id)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		return mailData.canEdit 
	end 
	return false
end
function RAMailManager:updataEditMailDatas(id,isCanEdit)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.canEdit = isCanEdit
	end 
end
--更新标记邮件信息
function RAMailManager:updataStarMailDatas(id,isStar)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.saved = isStar
	end 
	
end
function RAMailManager:getLockMailDatas(id)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		return mailData.lock 
	end 
end

function RAMailManager:updataLockMailDatas(id,isLock)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.lock = isLock
	end 
end
--更新已读邮件信息 isRead:1已读 0未读
function RAMailManager:updateReadMailDatas(id,isRead)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		mailData.status = isRead
	end
	
	--更新主UI
    self:refreshMainUIBottomMailNum()
end

--统一刷新某种类型邮件已读未读
function RAMailManager:updateReadMailDatasByType(isRead,targetType)
	for id,v in pairs(self.mailDatas) do
		local configId=v.configId
		local mailType = self:getMailTypeByConfigId(configId) 
		if mailType==targetType then
			if type(v)=="table" then
				v.status = isRead
			end	
		end 
	end
	--更新主UI
    self:refreshMainUIBottomMailNum()

    MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
    MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList)
end
--更新是否领取完奖励
function RAMailManager:updateRewardMailDatas(id,isGetReward)
	local mailData =self:getMailById(id)
	if type(mailData)=="table" then
		if mailData.hasReward then
			mailData.hasReward = isGetReward
		end 
	end 

end

--更新是否第一次阅读邮件
function RAMailManager:updateIsFirstMailDatas(id,isFirstRead)
	self.isFirstReadTab[id]=isFirstRead
end
function RAMailManager:getMailDatas()
	return self.mailDatas
end

function RAMailManager:addDeleteMailId(id)
	if self.deleteMailIdTab[id]==nil then
		 self.deleteMailIdTab[id]=id
	end 
end

function RAMailManager:clearDeleteMailiIdTab()
	for i,v in ipairs(self.deleteMailIdTab) do 
		v=nil
	end
	self.deleteMailIdTab={}

	--更新主UI
    self:refreshMainUIBottomMailNum()
end

function RAMailManager:removeDeleteMailiId(id)
	if self.deleteMailIdTab[id] then
		self.deleteMailIdTab[id]=nil
		self.readMailIdTab[id]=nil
	end 
end

function RAMailManager:getDeleteMailIdTab()
	return self.deleteMailIdTab
end


--根据id删除邮件
function RAMailManager:deleteMailById(id)
	if not id then return "" end 
	if self.mailDatas[id] then
		self.mailDatas[id]=nil
	end 
end

function RAMailManager:getMailTypeByMailId(id)
	if id==nil then return  end
	local mailData=self:getMailById(id)
	local mailType=mailData.type
	return mailType

end

--根据id获取邮件内容
function RAMailManager:getMailById(id)
	if not id then return "" end 
	if self.mailDatas[id] then
		return self.mailDatas[id]
	end 
	return ""
end

--记录当前列表type
function RAMailManager:setOptMailType(mailTYpe)
	self.optMailType=mailTYpe
end

--返回当前列表type
function RAMailManager:getOptMailType()
	return self.optMailType
end

--记录当前主界面标题
function RAMailManager:setMainMailTitle(mainMailTitle)
	self.mainMailTitle=mainMailTitle
end

--返回当前主界面标题
function RAMailManager:getMainMailTitle()
	return self.mainMailTitle
end
--根据某种类型邮件得到当前类型新邮件的数目
function RAMailManager:getNumByMailType(mailType)
	local count=0
	for k,v in pairs(self.mailDatas) do
		local mailInfo=v
		local mailStatus=mailInfo.status
		local configId = mailInfo.configId
		local tmpType = self:getMailTypeByConfigId(configId)

		if mailStatus==0 and tmpType==mailType then
			count = count+1
		end 
	end
	return count
end


--根据邮件配置ID来判断邮件类型 
function RAMailManager:getMailTypeByConfigId(configID)
	if configID==nil then return 0 end
	configID = tonumber(configID)

	local RAMailConfig = RARequire("RAMailConfig")
	if configID<RAMailConfig.IdLimit.PRIVATE[2] and configID>RAMailConfig.IdLimit.PRIVATE[1] then
		return RAMailConfig.Type.PRIVATE
	elseif configID<RAMailConfig.IdLimit.ALLIANCE[2] and configID>RAMailConfig.IdLimit.ALLIANCE[1] then
		return RAMailConfig.Type.ALLIANCE
	elseif configID<RAMailConfig.IdLimit.FIGHT[2] and configID>RAMailConfig.IdLimit.FIGHT[1] then
		return RAMailConfig.Type.FIGHT
	elseif configID<RAMailConfig.IdLimit.SYSTEM[2] and configID>RAMailConfig.IdLimit.SYSTEM[1] then
		return RAMailConfig.Type.SYSTEM
	elseif configID<RAMailConfig.IdLimit.MONSTERYOULI[2] and configID>RAMailConfig.IdLimit.MONSTERYOULI[1] then
		return RAMailConfig.Type.MONSTERYOULI
	elseif configID<RAMailConfig.IdLimit.RESCOLLECT[2] and configID>RAMailConfig.IdLimit.RESCOLLECT[1] then
		return RAMailConfig.Type.RESCOLLECT
	end 

	
end

--获取标记邮件数目
function RAMailManager:getStarMailNum()
	local count=0
	for k,v in pairs(self.mailDatas) do
		local mailInfo=v
		if mailInfo.saved then
			count = count + 1
		end 
	end
	return count
end

--获取锁住邮件数目
function RAMailManager:getLockMailNum()
	local count=0
	for k,v in pairs(self.mailDatas) do
		local mailInfo=v
		if mailInfo.lock==1 then
			count = count + 1
		end 
	end
	return count
end


--获取收藏信件中未读的邮件数目
function RAMailManager:getFavoriteNoReadMailNum()
	local count=0
	for k,v in pairs(self.mailDatas) do
		local mailInfo=v
		if mailInfo.saved and mailInfo.status==0 then
			count = count + 1
		end 
	end
	return count
end

--得到某种邮件的数目
function RAMailManager:getCountByMailType(mailType)
	local count=0
	for k,v in pairs(self.mailDatas) do
		local mailInfo=v
		local tmpType = mailInfo.type
		if tmpType==tmpType then
			count = count + 1
		end 
	end
	return count
end
    -- MailLimitNum=
    -- {
    --     STAR=50,     --收藏邮件
    --     SYSTEM=50    --系统邮件
    --     REPORT=50    --报告类邮件
    -- },
--判断收藏邮件是否已经达到上限
function RAMailManager:isReachStarMailLimit(add)
	local count=self:getStarMailNum()
	if add then
		if count+add>RAGameConfig.MailLimitNum.STAR then
			return true
		else
			return false
		end
	else
		if count>=RAGameConfig.MailLimitNum.STAR then
			return true
		else
			return false
		end 
	end

end

--判断收藏邮件是否已经达到上限
function RAMailManager:isReachLockMailLimit(add)
	local count=self:getLockMailNum()
	if add then
		if count+add>RAGameConfig.MailLimitNum.STAR then
			return true
		else
			return false
		end
	else
		if count>=RAGameConfig.MailLimitNum.STAR then
			return true
		else
			return false
		end 
	end

end

--判断报告类邮件是否已经达到上限
function RAMailManager:isReachReportMailLimit()

	local count = 0
	for k,v in pairs(self.mailDatas) do
		local  mailData =v
		local  tmpMailType = mailData.type
		local  isReportMail = RAMailUtility:isReportMail(tmpMailType)
		if isReportMail then
			count=count+1
		end 
	end
	if count>RAGameConfig.MailLimitNum.REPORT then
		return true
	end 
	return false
end


--聊天室信息推送替换对应id的subtitle和tit
function RAMailManager:updateChatRoomSimplleData(id,subtitle,title)
	local simpleMailData=self:getMailById(id)
	if type(simpleMailData)=="table" then
		simpleMailData.subTitle=subtitle
		if title then
			simpleMailData.title=title
		end 
	end 
	
end

--聊天室信息推送替换对应id的title
function RAMailManager:updateChatRoomSimplleDataTitle(id,title)
	local simpleMailData=self:getMailById(id)
	if type(simpleMailData)=="table" then	
		simpleMailData.title=title
	end 
	
end

function RAMailManager:updateChatRoomSimplleDataTitleNoGroup(id,title)
	local simpleMailData=self:getMailById(id)
	if type(simpleMailData)=="table" then	
		simpleMailData.titleNoGroup=title
	end 
end

--聊天室信息推送替换对应id的subtitle
function RAMailManager:updateChatRoomSimplleDataSubtitle(id,subtitle)
	local simpleMailData=self:getMailById(id)
	if type(simpleMailData)=="table" then	
		simpleMailData.subtitle=subtitle
	end 
	
end

--是否要开启某种邮件
function RAMailManager:isNoOpenMail(mailType)
	local isNoOpen=RAMailUtility:isNoOpenMail(mailType)
	return isNoOpen
end

function RAMailManager:setSelectPlayerId(playerId,isSelect)
	if self.selectPlayerIdTabs==nil then
		self.selectPlayerIdTabs={}
	end 
	self.selectPlayerIdTabs[playerId]=isSelect
end

function RAMailManager:getSelectTotalNum()
	if self.selectPlayerIdTabs then
		local count=0
		for k,v in pairs(self.selectPlayerIdTabs) do
			local isSelect = v
			if isSelect then 
				count = count + 1 
			end 
		end
		return count
	end 
	return 0
end
function RAMailManager:clearSelectPlayerId()
	if self.selectPlayerIdTabs then
		for k,v in pairs(self.selectPlayerIdTabs) do
			v=nil
		end
		self.selectPlayerIdTabs = nil
	end 

end
function RAMailManager:getSelectPlayerId(playerId)
	if self.selectPlayerIdTabs then
		return self.selectPlayerIdTabs[playerId]
	end 
end

----------------------------------------------------------------------------------proto
-- 发送删除邮件协议 邮件id列表
function RAMailManager:sendDeleteMailCmdById(idTab)

	local mailType=nil
    local cmd = Mail_pb.HPDelMailByIdReq()
    for k,v in pairs(idTab) do
    	local mailId = v
    	cmd.id:append(mailId)

    	if mailType==nil then
    		mailType=self:getMailTypeByMailId(mailId)
    	end  	
    end
    cmd.type=mailType
    if mailType then
    	RANetUtil:sendPacket(HP_pb.MAIL_DEL_MAIL_BY_ID_C,cmd,{retOpcode=-1})
    end
end

-- 发送删除邮件协议 通过类型
function RAMailManager:sendDeleteMailCmdByType(tmpType)

    local cmd = Mail_pb.HPDelMailByTypeReq()
    cmd.type =tmpType

    RANetUtil:sendPacket(HP_pb.MAIL_DEL_MAIL_BY_TYPE_C,cmd,{retOpcode=-1})
end

-- 发送收藏邮件协议 邮件id (锁住协议)
function RAMailManager:sendFavoriteMailCmd(idTab)

	local mailType=nil
    local cmd = Mail_pb.HPSaveMailReq()
    for k,v in pairs(idTab) do
    	local mailId = v
    	cmd.id:append(mailId)

    	if mailType==nil then
    		mailType=self:getMailTypeByMailId(mailId)
    	end  	
    end
    cmd.type=mailType
    if mailType then
    	RANetUtil:sendPacket(HP_pb.MAIL_SAVE_C,cmd,{retOpcode=-1})
    end
end

-- 发送取消收藏邮件协议 邮件id 
function RAMailManager:sendCancleFavoriteMailCmd(idTab)

	local mailType=nil
    local cmd = Mail_pb.HPCancelSaveMailReq()
    for k,v in pairs(idTab) do
    	local mailId = v
    	cmd.id:append(mailId)

    	if mailType==nil then
    		mailType=self:getMailTypeByMailId(mailId)
    	end  	
    end
    cmd.type=mailType
    if mailType then
    	RANetUtil:sendPacket(HP_pb.MAIL_CANCEL_SAVE_C,cmd,{retOpcode=-1})
    end
end

--发送创建聊天室消息  nameTab:接收人姓名表  msg：发送内容
function RAMailManager:sendCreateChatRoomCmd(nameTab,msg)

	local cmd= Mail_pb.HPCreateChatRoomReq()
	cmd.msg =msg
	for k,v in pairs(nameTab) do
		local name = v
		if name~="" then
			cmd.toName:append(name)
		end 
		
	end
	RANetUtil:sendPacket(HP_pb.MAIL_CREATE_CHATROOM_C,cmd,{retOpcode=-1})
end
--发送聊天室信息
function RAMailManager:sendChatRoomCmd(id,msg)
	
	--id就是聊天室的id
	local cmd = Mail_pb.HPSendChatRoomMsgReq()
	cmd.id =id
	cmd.msg=msg
	RANetUtil:sendPacket(HP_pb.MAIL_SEND_CHATROOM_MSG_C,cmd,{retOpcode=-1})
end

--发送阅读邮件请求 id 邮件id
function RAMailManager:sendReadCmd(id)
	local mailType=self:getMailTypeByMailId(id)
	local cmd = Mail_pb.HPCheckMailReq()
	cmd.id =id
	cmd.type=mailType
	self.lastTime = os.time()

	RANetUtil:sendPacket(HP_pb.MAIL_CHECK_MAIL_C,cmd)
end


--发送领取邮件奖励请求  id：邮件id
function RAMailManager:sendGetRewardCmd(id)
	local mailType=self:getMailTypeByMailId(id)
	local cmd = Mail_pb.HPGetMailRewardReq()
	cmd.id =id
	cmd.type=mailType
	RANetUtil:sendPacket(HP_pb.MAIL_REWARD_C,cmd,{retOpcode=-1})
end

--发送已经读取完了邮件  邮件ID，-1全部读取
function RAMailManager:sendReadFinishMailCmd(idTab)

	--取其中一个id来判断类型
	local mailType=nil
    local cmd = Mail_pb.HPMarkReadMailReq()
    for k,v in pairs(idTab) do
    	local mailId = v
    	cmd.id:append(mailId)

    	if mailType==nil then
    		mailType=self:getMailTypeByMailId(mailId)
    	end  	
    end
    cmd.type=mailType
    if mailType then
    	RANetUtil:sendPacket(HP_pb.MAIL_MARK_READ_C,cmd,{retOpcode=-1})
    end 
end

--发送类型请求数据 报告类邮件
function RAMailManager:sendReadReportMailCmd(mailType)
	local cmd = Mail_pb.HPCheckMailByTypeReq()
	cmd.type = mailType
	RANetUtil:sendPacket(HP_pb.MAIL_CHECK_MAIL_BY_TYPE_C,cmd)
end

--发送分享邮件的请求
function RAMailManager:sendShareMailCmd(id)
	-- body 
	local mailType=self:getMailTypeByMailId(id)
	local cmd = Mail_pb.HPMailShareReq()
	cmd.mailId = id
	cmd.type=mailType
	RANetUtil:sendPacket(HP_pb.MAIL_SHARE_C,cmd)
end


-- 发送查看其它玩家邮件
function RAMailManager:sendCheckOtherMailCmd(playerId,id)
	local mailType=self:getMailTypeByMailId(id)
	local cmd = Mail_pb.HPCheckOtherPlayerMailReq()
	cmd.playerId= playerId
	cmd.mailId = id
	cmd.type=mailType
	RANetUtil:sendPacket(HP_pb.MAIL_CHECK_OTHERPLAYER_MAIL_C,cmd)
end

--发送全体联盟邮件
function RAMailManager:sendAllianceMemsMailCmd(msg)
	local cmd = Mail_pb.HPCreateChatRoomReq()
	cmd.msg=msg
	cmd.toName:append("")
	RANetUtil:sendPacket(HP_pb.MAIL_SEND_GUILD_MAIL_C,cmd,{retOpcode=-1})
end

--请求历史交互好友信息
function RAMailManager:sendGetFriendsCmd()
	RANetUtil:sendPacket(HP_pb.MAIL_CHAT_HISTORY_PLAYERS_C)
end

--聊天室添加玩家协议
function RAMailManager:sendAddChatRoomMemsCmd(mailUuid,names)
	local cmd = Mail_pb.ChangeMembersReq()
	cmd.mailUuid=mailUuid
	for k,v in pairs(names) do
		local name = v
		if name~="" then
			cmd.playerName:append(name)
		end 
	end
	RANetUtil:sendPacket(HP_pb.MAIL_CHAT_ADD_PLAYERS_C,cmd)
end

--聊天室踢出玩家协议
function RAMailManager:sendDelChatRoomMemsCmd(mailUuid,names)
	local cmd = Mail_pb.ChangeMembersReq()
	cmd.mailUuid=mailUuid
	for k,v in pairs(names) do
		local name = v
		if name~="" then
			cmd.playerName:append(name)
		end 
	end
	RANetUtil:sendPacket(HP_pb.MAIL_CHAT_DEL_PLAYERS_C,cmd)
end
--修改聊天室名字
function RAMailManager:sendChangeChatRoomNameCmd(mailUuid,name)
	local cmd = Mail_pb.ChangeChatRoomName()
	cmd.mailUuid=mailUuid
	cmd.name = name
	RANetUtil:sendPacket(HP_pb.MAIL_CHANGE_CHATROOM_NAME_C,cmd)
end

--删除并退出聊天室
function RAMailManager:sendExitChatCmd(mailUuid)
	local cmd = Mail_pb.LeaveChatRoomReq()
	cmd.uuid=mailUuid
	RANetUtil:sendPacket(HP_pb.MAIL_LEAVE_CHATROOM_C,cmd)
end
-------------------------------------------------------------------------------------



--清除所有阅读数据
function RAMailManager:clearAllCheckMailDatas( )
	self:clearSystemMailCheckDatas() 			--清除系统邮件阅读数据
	self:clearResCollectMailCheckDatas()  		--清除资源采集邮件阅读数据
	self:clearPlayerBattleMailCheckDatas() 		--清除玩家战斗邮件阅读数据
	self:clearMonsterBattleMailCheckDatas()		--清除怪物战斗邮件阅读数据
	self:clearChatRoomMailCheckDatas()			--清除聊天室邮件阅读数据
	self:clearDetectMailCheckDatas()            --清除侦查邮件阅读数据
	self:clearAllianceMailCheckDatas()			--清除联盟邮件阅读数据
end
--服务器返回邮件数据存储
-------------------------------------------------------------------------------------

--系统邮件
function RAMailManager:addSystemMailCheckDatas(id,mailDatas)
	if self.systemMailCheckDatas[id]==nil then
		self.systemMailCheckDatas[id]=mailDatas
	end 
end

function RAMailManager:getSystemMailCheckDatas(id)
	if self.systemMailCheckDatas[id] then
		return self.systemMailCheckDatas[id]
	end
end
function RAMailManager:clearSystemMailCheckDatas()
	for i,v in pairs(self.systemMailCheckDatas) do
		v=nil
	end
	self.systemMailCheckDatas={}
end
-------------------------------------------------------------------------------------
--资源采集报告
function RAMailManager:addResCollectMailCheckDatas(id,mailDatas)
	if self.resCollectMailCheckDatas[id]==nil then
		self.resCollectMailCheckDatas[id]=mailDatas
	end 	
end
function RAMailManager:getResCollectMailCheckDatas(id)
	if self.resCollectMailCheckDatas[id] then
		return self.resCollectMailCheckDatas[id]
	end
end
function RAMailManager:clearResCollectMailCheckDatas()
	for i,v in pairs(self.resCollectMailCheckDatas) do
		v=nil
	end
	self.resCollectMailCheckDatas={}
end

--记录最新的一封采集邮件id
function RAMailManager:setResCollectNewId(id)
	self.ResCollectNewId=id
end

function RAMailManager:getResCollectNewId()
	return self.ResCollectNewId
end

-------------------------------------------------------------------------------------
--战斗报告
function RAMailManager:addPlayerBattleMailCheckDatas(id,mailDatas)
	if self.playerBattleMailCheckDatas[id]==nil then
		self.playerBattleMailCheckDatas[id]=mailDatas
	end 
end

function RAMailManager:getPlayerBattleMailCheckDatas(id)
	if self.playerBattleMailCheckDatas[id] then
		return self.playerBattleMailCheckDatas[id]
	end
end
function RAMailManager:clearPlayerBattleMailCheckDatas()
	for i,v in pairs(self.playerBattleMailCheckDatas) do
		v=nil
	end
	self.playerBattleMailCheckDatas={}
end
-------------------------------------------------------------------------------------
--打怪报告

function RAMailManager:addMonsterBattleMailCheckDatas(id,mailDatas)
	if self.monsterBattleMailCheckDatas[id]==nil then
		self.monsterBattleMailCheckDatas[id]=mailDatas
	end 
end

function RAMailManager:getMonsterBattleMailCheckDatas(id)
	if self.monsterBattleMailCheckDatas[id] then
		return self.monsterBattleMailCheckDatas[id]
	end
end
function RAMailManager:clearMonsterBattleMailCheckDatas()
	for i,v in pairs(self.monsterBattleMailCheckDatas) do
		v=nil
	end
	self.monsterBattleMailCheckDatas={}
end

--记录最新的一封打怪邮件id
function RAMailManager:setMonsterBattleNewId(id)
	self.MonsterBattleNewId=id
end

function RAMailManager:getMonsterBattleNewId()
	return self.MonsterBattleNewId
end

-------------------------------------------------------------------------------------
--聊天室信息  存储的是ChatRoomMail
function RAMailManager:addChatRoomMailCheckDatas(chatRoomId,mailDatas)
	if self.chatRoomCheckDatas[chatRoomId]==nil then
		self.chatRoomCheckDatas[chatRoomId]={}
		table.insert(self.chatRoomCheckDatas[chatRoomId],mailDatas)   --第一个元素为聊天室请求返回的数据，后面的元素为监听添加的
		-- local chatRoomMail = mailDatas.chatRoomMail
		-- self:genChatMemData(chatRoomId,chatRoomMail.mem)
	end

end

--邮件id:chatRoomId
function RAMailManager:genChatMemData(chatRoomId,memberDatas)
	-- chatRoomMemDatas
	if chatRoomId==nil  then return end
	if self.chatRoomMemDatas[chatRoomId]==nil then
		self.chatRoomMemDatas[chatRoomId] = {}
	end 

	local count=#memberDatas
	for i=1,count do
		local memberData = memberDatas[i]
		local t={}
		t.playerId = memberData.playerId
		t.name = memberData.name
		t.icon = memberData.icon
		t.isDelete = false
		-- self.chatRoomMemDatas[chatRoomId][memberData.playerId]=t
		table.insert(self.chatRoomMemDatas[chatRoomId],t)
	end

    
end
function RAMailManager:getChatRoomMems(chatRoomId)
	if self.chatRoomMemDatas[chatRoomId] then
		return self.chatRoomMemDatas[chatRoomId]
	end 
end

function RAMailManager:getChatRoomMemsNum(chatRoomId)
	local count=0
	if self.chatRoomMemDatas[chatRoomId] then
		local tb=self.chatRoomMemDatas[chatRoomId]
		for k,v in pairs(tb) do
			if not v.isDelete then
				count=count+1	
			end 	
		end
	end 
	return count
end
function RAMailManager:setChatRoomExit(chatRoomId,isExit)
	local mailData = self:getMailById(chatRoomId)
	if type(mailData)=="table" then
		mailData.exit = isExit
	end 
	
end
function RAMailManager:getChatRoomExit(chatRoomId)
	local mailData = self:getMailById(chatRoomId)
	if type(mailData)=="table" then
		return mailData.exit 
	end 
end


function RAMailManager:getchatTipsMsg(msg,msgType)
    -- msgType=tonumber(msgType)
	-- msg：以"_"分割，类型 第二个是操作者 后面是被操作者
	local msgTab=RAStringUtil:split(msg,"_") 
	local msgType = tonumber(msgTab[1])
	local operatorName = msgTab[2]
	local name=""

	local isMine = RAMailUtility:isMineByName(operatorName)
	local count = #msgTab
	local isOperatoredMine=nil
	for i=3,count do
		local playerName = msgTab[i]
		if not isOperatoredMine then
			local t = RAMailUtility:isMineByName(playerName)
			if t then
				isOperatoredMine=t
			end 
		end 
		if i==count then
			name=name..playerName
		else
			name=name..playerName..","
		end 

	end
	local resultMsg = ""
	local MailConst_pb = RARequire("MailConst_pb")
	if msgType==MailConst_pb.ADD_MEMBER then
		--添加玩家
		if isMine then
			resultMsg = _RALang("@AddChatGroupChatTips1",name)
		else
			resultMsg = _RALang("@AddChatGroupChatTips2",operatorName,name)
		end

		--被添加者是自己
		if isOperatoredMine then
			resultMsg = _RALang("@AddChatGroupChatTips3",operatorName)
		end

	elseif msgType==MailConst_pb.DEL_MEMBER then
		--删除玩家
		if isMine then
			resultMsg = _RALang("@DelChatGroupChatTips1",name)
		else
			resultMsg = _RALang("@DelChatGroupChatTips2",operatorName,name)
		end
	elseif msgType==MailConst_pb.MEMBER_LEAVE then
		--自己退出
		if isMine then
			resultMsg = _RALang("@LeaveChatGroupChatTips1")
		else
			resultMsg = _RALang("@LeaveChatGroupChatTips2",operatorName)
		end
	elseif msgType==MailConst_pb.BE_DEL_MEMBER then
		resultMsg =_RALang("@DelChatGroupChatTips3",operatorName)
	elseif msgType==MailConst_pb.CHANGE_CHATROOM then
		if isMine then
			resultMsg = _RALang("@ChangeChatNameTips1",name)
		else
			resultMsg = _RALang("@ChangeChatNameTips",operatorName,name)
		end 
		
	end
    return resultMsg
end

function RAMailManager:clearRoomMemsData(chatRoomId)
	if self.chatRoomMemDatas[chatRoomId] then
		for k,v in pairs(self.chatRoomMemDatas[chatRoomId]) do
			v=nil
		end
		self.chatRoomMemDatas[chatRoomId]=nil
	end 

end
--isAdd:添加或者刷新 
function RAMailManager:updateRoomMemsData(chatRoomId,memberDatas,isAdd)
	if chatRoomId==nil then return end
	if self.chatRoomMemDatas[chatRoomId]==nil then
	 	return 
	end
	if isAdd==nil then isAdd=true end

	local count=#memberDatas
	for i=1,count do
		local memberData = memberDatas[i]
		local playerId = memberData.playerId

		
		local targetName = memberData.name
		if not isAdd then 
			for k,v in ipairs(self.chatRoomMemDatas[chatRoomId]) do
				if targetName==v.name then
					v.isDelete=true
				end 
			end
		else
			-- --如果被踢出又被拉进来 只要更新状态就好
			-- local isExist=false
			-- for k,v in ipairs(self.chatRoomMemDatas[chatRoomId]) do
			-- 	if targetName==v.name then
			-- 		isExist=true
			-- 		v.isDelete=false
			-- 		break
			-- 	end 
			-- end
			-- if not isExist then
			-- 	local t={}
			-- 	t.playerId=memberData.playerId
			-- 	t.name = memberData.name
			-- 	t.icon = memberData.icon
			-- 	t.isDelete=false
			-- 	table.insert(self.chatRoomMemDatas[chatRoomId],t)
			-- end

			-- for k,v in ipairs(self.chatRoomMemDatas[chatRoomId]) do
			-- 	if targetName~=v.name and targetIsDeltete~=v.isDelete then
				
			-- 	end 
			-- end



			local isExist=false
			for k,v in ipairs(self.chatRoomMemDatas[chatRoomId]) do
				if v.name==memberData.name and v.isDelete==false then
					isExist=true
					break
				end 
			end

			if not isExist then
				local t={}
				t.playerId=memberData.playerId
				t.name = memberData.name
				t.icon = memberData.icon
				t.isDelete=false
				table.insert(self.chatRoomMemDatas[chatRoomId],t)
			end
		
		end 
		--刷新
		

		-- if isAdd then
		-- 	self.chatRoomMemDatas[chatRoomId][playerId]=t
		-- else
		-- 	--删除
		-- 	if self.chatRoomMemDatas[chatRoomId][playerId] then
		-- 		self.chatRoomMemDatas[chatRoomId][playerId]=nil
		-- 	end 
			
		-- end 
	end 
		
end
--playerMsg:charRoomId 和 msg  ==》playerId：msg
function RAMailManager:updateChatRoomMailCheckDatas(chatRoomId,playerId,chatMsg)
	local chatRoomDatas=self:getChatRoomMailCheckDatas(chatRoomId)
	local t={}
	t.playerId=playerId
	t.msg=chatMsg
	table.insert(chatRoomDatas,t)

end
function RAMailManager:clearChatRoomMailCheckDatas()
	for k1,v1 in pairs(self.chatRoomCheckDatas) do
		for k2,v2 in ipairs(v1) do
			v2=nil
		end
		v1=nil
	end
	self.chatRoomCheckDatas={}

	
	for k1,v1 in pairs(self.chatRoomMemDatas) do
		v1=nil
	end
	self.chatRoomMemDatas={}
end

function RAMailManager:getChatRoomMailCheckDatas(chatRoomId)
	if self.chatRoomCheckDatas[chatRoomId] then 
		return self.chatRoomCheckDatas[chatRoomId]
	end
	return {}
end

--通过id获取玩家name和icon
function RAMailManager:getPlayerNameAndIcon(chatRoomId,playerId)
	local mailDatas=self:getChatRoomMailCheckDatas(chatRoomId)
	local chatRoomDatas=mailDatas[1].chatRoomMail
	local chatRoomMem=chatRoomDatas.roomMember
	local count=#chatRoomMem
	local playerName=""
	local playerIcon=""
	for i=1,count do
		local memberData=chatRoomMem[i]
		if playerId==memberData.playerId then
			playerName=memberData.name
			playerIcon=memberData.icon
			break
		end 
	end
	return playerName,playerIcon
end


-------------------------------------------------------------------------------------
--侦查邮件

function RAMailManager:addDetectMailCheckDatas(id,mailDatas)
	if self.detectMailCheckDatas[id]==nil then
		self.detectMailCheckDatas[id]=mailDatas
	end 
end

function RAMailManager:getDetectMailCheckDatas(id)
	if self.detectMailCheckDatas[id] then
		return self.detectMailCheckDatas[id]
	end
end
function RAMailManager:clearDetectMailCheckDatas()
	for i,v in pairs(self.detectMailCheckDatas) do
		v=nil
	end
	self.detectMailCheckDatas={}
end
----------------------------------------------------------------------------------------
--联盟邮件
function RAMailManager:addAllianceMailCheckDatas(id,mailDatas)
	if self.allianceMailCheckDatas[id]==nil then
		self.allianceMailCheckDatas[id]=mailDatas
	end 
end

function RAMailManager:getAllianceMailCheckDatas(id)
	if self.allianceMailCheckDatas[id] then
		return self.allianceMailCheckDatas[id]
	end
end
function RAMailManager:clearAllianceMailCheckDatas()
	for i,v in pairs(self.allianceMailCheckDatas) do
		v=nil
	end
	self.allianceMailCheckDatas={}
end

--------------------------------------------------------------------------------
function RAMailManager:goToListPage(mailType,title)
	local pararms={}
	pararms.mailType = mailType
	pararms.title    = title
	RARootManager.OpenPage("RAMailListPageV6",pararms)
end


function RAMailManager:deleteMailInPage(id)
	local deleteMailId = id
	local mailInfo = self:getMailById(deleteMailId)
	local confirmData = {}
	if mailInfo.lock==1 then
		confirmData.labelText = _RALang("@DeleteLockMailTip")
		confirmData.lock = true
		RARootManager.OpenPage("RAMailDelConfirmPopUp", confirmData,false,true,true)
	else
		local mailId = deleteMailId
		self:addDeleteMailId(mailId)
		local deleteMailIdTab = self:getDeleteMailIdTab()
		self:sendDeleteMailCmdById(deleteMailIdTab)
		MessageManager.sendMessage(refreshMailOptListMsg,{isOffest=false})
	end
end

function RAMailManager:setMailTips(mailType,isShow)
	if mailType==nil then return end 

	local RAMailConfig = RARequire('RAMailConfig')
	if mailType==RAMailConfig.Type.PRIVATE then
		self.TipsTb[1]=isShow
	elseif mailType==RAMailConfig.Type.ALLIANCE then
		self.TipsTb[2]=isShow
	elseif mailType==RAMailConfig.Type.FIGHT then
		self.TipsTb[3]=isShow
	elseif mailType==RAMailConfig.Type.SYSTEM then
		self.TipsTb[4]=isShow
	elseif mailType==RAMailConfig.Type.ACTIVITY then
		self.TipsTb[5]=isShow
	elseif mailType==RAMailConfig.Type.MONSTERYOULI then
		self.TipsTb[6]=isShow
	elseif mailType==RAMailConfig.Type.RESCOLLECT then
		self.TipsTb[7]=isShow
	end 
end

function RAMailManager:getMailTips(mailType,isShow)
	if mailType==nil then return end 

	local RAMailConfig = RARequire('RAMailConfig')
	if mailType==RAMailConfig.Type.PRIVATE then
		return self.TipsTb[1]
	elseif mailType==RAMailConfig.Type.ALLIANCE then
		return self.TipsTb[2]
	elseif mailType==RAMailConfig.Type.FIGHT then
		return  self.TipsTb[3]
	elseif mailType==RAMailConfig.Type.SYSTEM then
		return  self.TipsTb[4]
	elseif mailType==RAMailConfig.Type.ACTIVITY then
		return  self.TipsTb[5]
	elseif mailType==RAMailConfig.Type.MONSTERYOULI then
		return  self.TipsTb[6]
	elseif mailType==RAMailConfig.Type.RESCOLLECT then
		return self.TipsTb[7]
	end 
end

function RAMailManager:resetMailTips()
	self.TipsTb={
	false,false,false,false,false,false,false
	}
end

return RAMailManager
--endregion
