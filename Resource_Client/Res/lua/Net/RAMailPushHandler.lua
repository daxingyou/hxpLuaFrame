
local RAMailPushHandler = {}

function RAMailPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Mail_pb = RARequire("Mail_pb")
    local Const_pb = RARequire("Const_pb")
    local RAMailManager = RARequire("RAMailManager")
    local RAMailConfig = RARequire("RAMailConfig")
    local RAStringUtil = RARequire("RAStringUtil")
    local RAMailUtility = RARequire("RAMailUtility")

    RARequire("MessageDefine")
    RARequire("MessageManager")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.MAIL_LIST_SYNC_S then  --登录推送
		local msg = Mail_pb.HPMailListSync()
	    msg:ParseFromString(buffer)

        local mailDatasTab = msg.mail
        local count = #mailDatasTab
        for i=1,count do
        	local mailInfo = mailDatasTab[i]
            local mailId = mailInfo.id
            -- local mailType = mailInfo.type
            local mailIsSave = mailInfo.saved
            local mailTitle = mailInfo.title
            local mailSubTitle = mailInfo.subTitle
            local mialStatus=mailInfo.status
            local mialReward=mailInfo.hasReward
            local configID = mailInfo.mailId
            local mailType = RAMailManager:getMailTypeByConfigId(configID)

            -- if configID==2011011 then
            --     local a=0
            -- end 

            --同步的时候聊天消息要特殊处理？自己拼串

            --存储一份总数据
            local isNoOpen=RAMailManager:isNoOpenMail(configID)
            if not isNoOpen then
                 RAMailManager:addMailDatas(mailId,mailInfo)
                 if mailType==RAMailConfig.Type.RESCOLLECT then
                    RAMailManager:setResCollectNewId(mailId)
                end 
            end 
        end


    elseif pbCode == HP_pb.MAIL_NEW_MAIL_S  then --新邮件推送  包括创建新的聊天室也走这个
    	CCLuaLog("a new mail========")
        local msg = Mail_pb.HPNewMailRes()
        msg:ParseFromString(buffer)
        local mailDatasTab = msg.mail
        local count = #mailDatasTab
         for i=1,count do
            local mailInfo = mailDatasTab[i]
            local mailId = mailInfo.id
            local mailType = mailInfo.type
            local configID = mailInfo.mailId
            local mailType = RAMailManager:getMailTypeByConfigId(configID)

            local isNoOpen=RAMailManager:isNoOpenMail(configID)
            if not isNoOpen then
                RAMailManager:addMailDatas(mailId,mailInfo) 
                --发个消息刷新
                MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
                MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList,{isOffest=false})

                if mailType==RAMailConfig.Type.RESCOLLECT then
                    RAMailManager:setResCollectNewId(mailId)
                end 
            end 
 
        end
        --更新主UI
        RAMailManager:refreshMainUIBottomMailNum()

    elseif pbCode ==HP_pb.MAIL_PUSH_CHATROOM_MSG_S then --聊天室信息推送 类似于报告 有新消息就算新邮件 有一条新信息就算一封
    	CCLuaLog("chat msg========")

        local chatRoomData = Mail_pb.HPPushChatRoomMsgRes()
        chatRoomData:ParseFromString(buffer)

        local chatRoomId=chatRoomData.id
        local playerName=""
        if chatRoomData:HasField("playerName") then
            playerName = chatRoomData.playerName
        end
        local chatRoomMsg=chatRoomData.msg
        
        local RAStringUtil=RARequire("RAStringUtil")

        local playerId=nil
        local playerMsg=nil
        local isTips=false
        local subtitle=""
        local changeName = RAMailManager:getMailNameStatu(chatRoomId)
        if string.find(tostring(chatRoomMsg),":") then
            --消息
            local msgTab=RAStringUtil:split(chatRoomMsg,":")
            playerId=msgTab[1]
            playerMsg=msgTab[2]
            subtitle=playerName..":"..playerMsg
            if changeName then
                playerName = changeName
            end
            RAMailManager:updateChatRoomSimplleDataTitle(chatRoomId,playerName)
            -- RAMailManager:updateChatRoomSimplleData(chatRoomId,subtitle)
        else
            --提示
            isTips = true
            --根据类型拼成消息
            local tipsMsg = RAMailManager:getchatTipsMsg(chatRoomMsg)
            playerMsg = tipsMsg
            subtitle  = tipsMsg

        end 
        --替换聊天邮件列表的subtitle
        RAMailManager:updateChatRoomSimplleData(chatRoomId,subtitle)

        --如果有新消息 把聊天室标记为未读
        RAMailManager:updateReadMailDatas(chatRoomId,0)
        
        --刷新聊天室的聊天信息
        RAMailManager:updateChatRoomMailCheckDatas(chatRoomId,playerId,playerMsg)

        --发个消息刷新
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Update_ChatMail,{roomId = chatRoomId,id=playerId,msg=playerMsg,tips=isTips})

        --更新主UI
        RAMailManager:refreshMainUIBottomMailNum()

    elseif pbCode ==HP_pb.MAIL_PUHS_DEL_S then  --服务器推送删除邮件器推送删除邮件
        --服务器邮件达到上限是主动删除后推送
        local msg = Mail_pb.PushDelMail() 
        msg:ParseFromString(buffer)

        local uuids = msg.uuid
        local count = #uuids
        local mailDatas=RAMailManager:getMailDatas()
        local configIdTb={}
        for i=1,count do
            local uuid = uuids[i]
            configIdTb[uuid]=mailDatas[uuid].configId
            mailDatas[uuid]=nil
        end
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailOptList)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList)

        --更新主UI
        RAMailManager:refreshMainUIBottomMailNum()

        --映射下该类型的删除邮件提示
        for k,v in pairs(configIdTb) do
            local configId=v
            local mailType=RAMailManager:getMailTypeByConfigId(configId)
            RAMailManager:setMailTips(mailType,true)
        end
       
    elseif pbCode ==HP_pb.MAIL_BE_DEL_S then    --自己收到自己 “被踢出”

        local chatRoomData = Mail_pb.BeDelFromChatRoomRes()
        chatRoomData:ParseFromString(buffer)

        local chatRoomId = chatRoomData.uuid
        local operatorName = chatRoomData.operatorName


        --更新状态
        RAMailManager:setChatRoomExit(chatRoomId,true)

        --刷新Subtitle
        local RAStringUtil = RARequire("RAStringUtil")
        local subtitle=_RALang("@DelChatGroupChatTips3",operatorName)

        RAMailManager:updateChatRoomSimplleData(chatRoomId,subtitle)

        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Update_ChatMail,{roomId=chatRoomId,tips=true,msg=subtitle})
        MessageManager.sendMessage(MessageDefine_Mail.MSG_BeExit_ChatRoom)

    elseif pbCode==HP_pb.MAIL_UPDATE_CHATROOM_S then    --加入成员 踢出成员 修改名字

    --     // 聊天室数据更新
    -- message UpdateChatRoom{
    --     required string uuid        = 1;//邮件唯一ID
    --     optional string createrId   = 2;//创建者ID
    --     optional string name        = 3;//聊天室名称  
    --     optional int32 operatorType = 4;//成员列表操作类型
    --     repeated ChatRoomMember member  = 5;//成员列表: 当某成员被踢出后再次拉进：表示当前的成员  其他情况为变化的成员
    -- }

        local UpdateChatRoom= Mail_pb.UpdateChatRoom()
        UpdateChatRoom:ParseFromString(buffer) 

        --
        local mailUuid=UpdateChatRoom.uuid

       
        if UpdateChatRoom:HasField("createrId") then
            local createrId = UpdateChatRoom.createrId
            RAMailManager:updateMailCreaterId(mailUuid,createrId)
        end 


        if UpdateChatRoom:HasField("operatorType") then
            local operatorType=UpdateChatRoom.operatorType
            local MailConst_pb = RARequire("MailConst_pb")
            if operatorType==MailConst_pb.ADD_MEMBER then                             
            
                --如果被踢出后再次拉进聊天室
                local isExit = RAMailManager:getChatRoomExit(mailUuid)
                if isExit then
                    RAMailManager:setChatRoomExit(mailUuid,false)

                    --清除后重新生成一份数据
                    RAMailManager:clearRoomMemsData(mailUuid)
                    RAMailManager:genChatMemData(mailUuid,UpdateChatRoom.member)
                else
                    -- RAMailManager:refreshChatMsg(UpdateChatRoom,true) 
                    RAMailManager:updateRoomMemsData(mailUuid,UpdateChatRoom.member,true)   
                end

            elseif operatorType==MailConst_pb.DEL_MEMBER then   
                --踢人  
                -- RAMailManager:refreshChatMsg(UpdateChatRoom,false)  

                RAMailManager:updateRoomMemsData(mailUuid,UpdateChatRoom.member,false)

            end 

            --刷新成员界面
            MessageManager.sendMessage(MessageDefine_Mail.MSG_Update_ChatRoomMem)
        end

        
        local name=""
        local chatRoomMems = RAMailManager:getChatRoomMems(mailUuid)
        local title,memNum = RAMailManager:getChatRoomName(chatRoomMems)
        local isChangeName=false
        local titleNoGroup=""
        if UpdateChatRoom:HasField("name") then
            --手动修改过名字
            isChangeName=true
            name = UpdateChatRoom.name
            RAMailManager:updateMailNameStatu(mailUuid,name) 

            if memNum>2 then
                name=RAMailUtility:getLimitStr(name,20).."("..memNum..")"
            end  

            titleNoGroup=name

        else
            --聊天室默认名称 自己拼写
            name = title 
            if memNum>2 then
                titleNoGroup=title.."("..memNum..")"

                name = _RALang("@ChatGroup")..title
                name=  RAMailUtility:getLimitStr(name,20).."("..memNum..")"
            else
                titleNoGroup=title
            end 
            RAMailManager:updateChatRoomSimplleDataTitleNoGroup(mailUuid,titleNoGroup)
        end

        RAMailManager:updateChatRoomSimplleDataTitle(mailUuid,name)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Refresh_MailList)
        MessageManager.sendMessage(MessageDefine_Mail.MSG_Update_ChatRoomName,{chatRoomName=titleNoGroup,roomId=mailUuid})
    
    end
end

return RAMailPushHandler