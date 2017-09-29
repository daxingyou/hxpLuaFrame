--region RAChatPushHandler.lua
--Date  2016/6/3
--Author sunyungao

local RAChatPushHandler = {}

--接收到主动推送消息
function RAChatPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Chat_pb = RARequire("Chat_pb")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PUSH_CHAT_S then
        local msg = Chat_pb.HPPushChat()
        msg:ParseFromString(buffer)
        if msg~=nil and msg.chatMsg~=nil then
            RAChatPushHandler:receiveChatMsg(msg.chatMsg, msg.isLogin)
            local RAChatManager = RARequire("RAChatManager")
            RAChatManager:refreshTheNewestMsg()--刷新主界面最新聊天信息的显示
        else
            CCLuaLog("RAChatPushHandler:onReceivePacket(): PUSH_CHAT_S-HPPushChat:msg is nil!")
        end
    elseif pbCode==HP_pb.ALLIANCE_MSG_CACHE_S then
        local msg = Chat_pb.HPPushChat()  
        msg:ParseFromString(buffer)
        if msg~=nil and msg.chatMsg~=nil then
            RAChatPushHandler:receiveChatMsg(msg.chatMsg, msg.isLogin)
        else
            CCLuaLog("RAChatPushHandler:onReceivePacket(): ALLIANCE_MSG_CACHE_S-HPPushChat:msg is nil!")
        end
    end
end

function RAChatPushHandler:receiveChatMsg(msg, isLogin)
    local Const_pb = RARequire('Const_pb')
    local RAChatManager = RARequire("RAChatManager")
    local RARootManager = RARequire("RARootManager")
    local RAChatData = RARequire("RAChatData")
    local RAChatInfo = RARequire("RAChatInfo")
    
    for i = #msg,1,-1 do
       if msg[i] then
            local chatInfo = RAChatInfo.new()
            chatInfo:initDataPB(msg[i])

            if chatInfo.hrefCfgName ~= "" and chatInfo.hrefCfgName ~= nil then 
                --保存不做任何处理的字段
                chatInfo.content = RAChatManager:getLangByName(chatInfo.name,chatInfo.hrefCfgName,chatInfo.hrefCfgPrams)
                --
                chatInfo.chatMsg = RAChatManager:getHrefCfgByName(chatInfo.hrefCfgName,chatInfo.hrefCfgPrams)
            
                if not isLogin and chatInfo.broadcastContent ~= nil and chatInfo.broadcastContent ~= "" then
                    chatInfo.chatBroadcastMsg = RAChatManager:getHrefCfgByName(chatInfo.broadcastContent,chatInfo.hrefCfgPrams)
                end
            else
                chatInfo.content = chatInfo.chatMsg
            end

            if chatInfo.type == Const_pb.CHAT_ALLIANCE                              --联盟聊天信息
            or chatInfo.type == RAChatData.CHAT_TYPE.allianceHrefBroadcast then     --联盟超链接信息
                RAChatManager:generateAllianceData(chatInfo)

                --记录最小msg的时间
                if RAChatManager.LastReqAllianceMsgTime == 0 or (chatInfo ~= nil and chatInfo.msgTime < RAChatManager.LastReqAllianceMsgTime) then
                    RAChatManager.LastReqAllianceMsgTime = chatInfo.msgTime
                end
            else
                --广播
                if not isLogin and (chatInfo.type == RAChatData.CHAT_TYPE.broadcast       --广播聊天
                or chatInfo.type == RAChatData.CHAT_TYPE.gmBroadcast    --系统公告
                or chatInfo.type == RAChatData.CHAT_TYPE.hrefBroadcast) then  --超链接
                    RARootManager.ShowBroadcast(chatInfo)
                end

                --根据 isLogin 判断 如果是 登陆推送过来的，那么把所有的类型都设置为0，即是全都显示在世界聊天，并且不需要广播
                if isLogin then
                    chatInfo.type = 0   
                end

                RAChatManager:generateWorldData(chatInfo)
            end
       end
    end
end

return RAChatPushHandler

