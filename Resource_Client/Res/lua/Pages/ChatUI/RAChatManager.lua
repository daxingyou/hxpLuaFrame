--聊天管理文件
--test by sunyungao


local Chat_pb              = RARequire("Chat_pb")
local RANetUtil            = RARequire("RANetUtil")
local RAChatData = RARequire("RAChatData")
local RARootManager = RARequire("RARootManager")

local RAChatManager = {
	--世界频道
	mWorldChannelData    = {},
	--联盟频道
	mAllianceChannelData = {},
	--选中哪个tab
	mChoosenTab      = RAChatData.CHATCHOOSENTAB.worldTab,
    --复制内容
    mCopyContent     = "",
    --是否刷新过某一页的数据（即是否打开过某页）
    isRefreshWorld    = false,
    isRefreshAlliance = false,
    --联盟聊天是否开启
    isAllianceChatOpen = true,
    --世界频道最多保存的数据条目
    worldChatMaxCount = 1000,
     --世界频道打开时刷新条数
    worldChatFirstCount = 20,
    --世界频道上拉刷新条数
    chatPullTopRefreshCount = 20,
    --2min
    chatTimeDiff = 120000,
    --聊天输入的内容
    MsgString = "",

    --记录最早一条联盟历史消息的数据时间，用于给服务器，查询历史联盟20条信息
    LastReqAllianceMsgTime=0,

    --系统头像
    systemIcon = "HeadPortait_Sys.png"
}

--重置数据
function RAChatManager:resetData()
	-- body
	self.mWorldChannelData    = {}
	self.mAllianceChannelData = {}
    --
    --self.mChoosenTab = RAChatData.CHATCHOOSENTAB.worldTab
end

function RAChatManager:reset()
    -- body
    self:resetData()
end

--创建世界频道数据
function RAChatManager:generateWorldData( data )
	-- body
    table.insert(self.mWorldChannelData, data)
    --当超过容量的时候移除
    if #self.mWorldChannelData > self.worldChatMaxCount then
        -- 每次移除都要移除掉对应的cell
        table.remove(self.mWorldChannelData, 1)
        if self.isRefreshWorld then
            --插入最新，删除最旧
            MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_remove_World_top_Data, data)
        end
    else 
        if self.isRefreshWorld then
            --插入一条
            MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_Generate_World_Data, data)
        end
    end
end

--创建联盟频道数据
function RAChatManager:generateAllianceData( data )
    -- body
    table.insert(self.mAllianceChannelData, data)
    --当超过容量的时候移除
    if #self.mAllianceChannelData > self.worldChatMaxCount then
        --每次移除都要移除掉对应的cell
        table.remove(self.mAllianceChannelData, 1)
        if self.isRefreshAlliance then
            MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_remove_Alliance_top_Data, data)
        end
    else 
        if self.isRefreshAlliance then
            MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_Generate_Alliance_Data, data)
        end
    end
end

--切换聊天频道的时候调用
function RAChatManager:updateMainUIBottomTabAndContent()
    -- body
    -- local items = {}
    -- if self.mChoosenTab == RAChatData.CHATCHOOSENTAB.worldTab then
    --     data = self.mWorldChannelData
    -- elseif RAChatData.CHATCHOOSENTAB.allianceTab == self.mChoosenTab then
    --     local RAAllianceManager = RARequire("RAAllianceManager")
    --     if nil == RAAllianceManager.selfAlliance then
    --         self.mAllianceChannelData = {}
    --     end
    --     data = self.mAllianceChannelData
    -- end

    -- local obj=nil
    -- local count = #data
    -- if count > 0 then
    --     obj={}
    --     obj.content  = data[count].chatMsg
    --     obj.name     = data[count].name
    --     obj.chatType = data[count].type
    --     obj.hrefCfgName = data[count].hrefCfgName
    --     obj.hrefCfgPrams = data[count].hrefCfgPrams
    --     obj.mChoosenTab=self.mChoosenTab
    -- end


    -- if obj~=nil then
    --     --如果是喇叭的话，在主界面底部是跟世界一个频道的
    --     if obj.chatType == RAChatData.CHAT_TYPE.broadcast then
    --         obj.chatType = RAChatData.CHAT_TYPE.world
    --     end
    --     if obj.hrefCfgName then
    --         obj.content = self:getLangByName(obj.name,obj.hrefCfgName,obj.hrefCfgPrams)
    --     end
    --     MessageManager.sendMessage(MessageDef_MainUI.MSG_Chat_change_tab, obj)
    -- end
    self:refreshTheNewestMsg()
end

--向上滑动的时候，获取和接收联盟历史的消息
function RAChatManager:receiveAllianceMsgToTop(data)

    --记录最小msg的时间
    if RAChatManager.LastReqAllianceMsgTime==0 or (data ~=nil and data.msgTime < RAChatManager.LastReqAllianceMsgTime) then
        RAChatManager.LastReqAllianceMsgTime=data.msgTime
    end

    --历史信息从前排插入
    self.mAllianceChannelData[#self.mAllianceChannelData + 1] = data
    --当超过容量的时候移除
    if #self.mAllianceChannelData > self.worldChatMaxCount then
        --每次移除都要移除掉对应的cell
        table.remove(self.mAllianceChannelData, 1)
        if self.isRefreshAlliance then
            MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_remove_Alliance_top_Data, data)
        end
    end
end

--刷新主界面最新一句聊天内容
function RAChatManager:refreshTheNewestMsg()
    --local data = {}
    local index = 0
    local items = {}
    if RAChatData.CHATCHOOSENTAB.worldTab == self.mChoosenTab and 0 ~= #self.mWorldChannelData then
        index = #self.mWorldChannelData
        items[#items + 1] = self.mWorldChannelData[index]
        items[#items + 1] = self.mWorldChannelData[index - 1]
    elseif RAChatData.CHATCHOOSENTAB.allianceTab == self.mChoosenTab and 0 ~= #self.mAllianceChannelData then
        local RAAllianceManager = RARequire("RAAllianceManager")
        if nil == RAAllianceManager.selfAlliance then
            self.mAllianceChannelData = {}
        end
        index = #self.mAllianceChannelData
        items[#items + 1] = self.mAllianceChannelData[index]
        items[#items + 1] = self.mAllianceChannelData[index - 1]
    end

    if #items ~= 0 then
        --如果是喇叭的话，在主界面底部是跟世界一个频道的
        -- if data.chatType == RAChatData.CHAT_TYPE.broadcast or data.chatType == RAChatData.CHAT_TYPE.hrefBroadcast then
        --     data.chatType = RAChatData.CHAT_TYPE.world
        -- end
        -- if data.hrefCfgName then
        --     data.content = self:getLangByName(data.name,data.hrefCfgName,data.hrefCfgPrams)
        -- end
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeChatNewestMsg, items)
    end
end

--------------------------------------------------------------
-----------------------协议相关-------------------------------
--------------------------------------------------------------

-- 发送聊天内容 content:聊天内容：content , isUseHorn ：是否使用喇叭
function RAChatManager:sendChatContent(content,isUseHorn)
    local cmd = Chat_pb.HPSendChat()
    cmd.chatMsg = content
    cmd.chatType = self.mChoosenTab
    if isUseHorn then
       cmd.chatType = 2 
    end
    RANetUtil:sendPacket(HP_pb.SEND_CHAT_C, cmd)
end

--获取联盟聊天信息
function RAChatManager:getChatMsgCacheForAlliance(lastMsgTime)
    local cmd = Chat_pb.HPChatMsgCacheReq()
    cmd.msgMinTime = lastMsgTime
    RANetUtil:sendPacket(HP_pb.ALLIANCE_MSG_CACHE_C, cmd)
end 

--------------------------------------------------------------
-----------------------UI数据操作-----------------------------
--------------------------------------------------------------

--设置选择tab为世界的
function RAChatManager:changeChoosenTabToWorld()
    self.mChoosenTab = RAChatData.CHATCHOOSENTAB.worldTab
end

--设置选择tab为联盟的
function RAChatManager:changeChoosenTabToAlliance()
    self.mChoosenTab = RAChatData.CHATCHOOSENTAB.allianceTab
end

function RAChatManager:isChoosenTabWorld()
    return RAChatData.CHATCHOOSENTAB.worldTab == self.mChoosenTab
end

function RAChatManager:isChoosenTabAlliance()
    return RAChatData.CHATCHOOSENTAB.allianceTab == self.mChoosenTab
end

function RAChatManager:setIsRefreshWorld( isr )
    self.isRefreshWorld = isr
end

function RAChatManager:setIsRefreshAlliance( isr )
    self.isRefreshAlliance = isr
end

--------------------------------------------------------------
-----------------------UI操作---------------------------------
--------------------------------------------------------------

--点击某个复制按钮，其他复制按钮隐藏
function RAChatManager:clickOneCopyBtn(  )
    --MessageManager.sendMessage(MessageDef_Chat.MSG_Chat_CopyBtn_CellTag_Data, {tag = cellTag})
end

--向服务器发送打点数据
function RAChatManager:sendNoticeToServer()
    local SysProtocol_pb = RARequire("SysProtocol_pb")
    local msg = SysProtocol_pb.HPClickNoticePB()
    msg.clickType = SysProtocol_pb.CHAT_CLICK
    RANetUtil:sendPacket(HP_pb.CLICK_NOTICE_C, msg)
end

function RAChatManager:getLang(langName)
    -- body
    local str = langName
    if langName then
        if string.find(langName,'@') then
            str = _RALang(langName)
        end
    end

    return str
end

--读超链接配置
function RAChatManager:getHrefCfgByName(cfgName,chatMsg)
    if chatMsg == nil or chatMsg == "" then 
        return "" 
    end
    local jsonData = cjson.decode(chatMsg)
    local RAStringUtil = RARequire("RAStringUtil")

    local prams ={}
    for i=1,5 do
        prams[i] = self:getLang(jsonData[i])
    end

    local htmlHrefStr = _RAHtmlFill(cfgName,prams[1],prams[2],prams[3],prams[4],prams[5]) 
    return htmlHrefStr
end

function RAChatManager:getLangByName(name,langName,chatMsg)
    if chatMsg == nil or chatMsg == "" then
        return ""
    end
    local jsonData = cjson.decode(chatMsg)
    local str

    local prams ={}
    for i=1,5 do
        prams[i] = self:getLang(jsonData[i])
    end

    if name == "" then
        str = _RALang("@"..langName,prams[1],prams[2],prams[3],prams[4],prams[5])
    else
        str = _RALang("@"..langName,name,prams[1],prams[2],prams[3],prams[4],prams[5])
    end
    return str
end

--根据const id获取名字
function RAChatManager:getMessageNameById(id,name)
    local str = _RALang("@SystemMessage")
    local notice_conf = RARequire("notice_conf")

    if notice_conf[id] then
        str = _RALang(notice_conf[id].noticeName)   
    else
        if name then
            str = name
        end
    end
    return str
end

--富文本超链接点击事件
function RAChatManager.createHtmlClick(id,data)
    local delayFunc = function ()
		local RAStringUtil = RARequire("RAStringUtil")
        local RAGameConfig = RARequire("RAGameConfig")
        if data == nil or data == "" then return end
        
        data = RAStringUtil:split(data, ',')
        if id == RAGameConfig.HTMLID.AllianceRecruit then   --联盟招募
            local guildId = data[1]
            RARootManager.OpenPage('RAAllianceDetailPage', {isNeedRequest = true, id = guildId, type = 1})
        elseif id == RAGameConfig.HTMLID.AllianceBomb then  --导弹坐标跳转
            local mPosXorY = {}
            mPosXorY.x = data[1]
            mPosXorY.y = data[2]
            local RAWorldManager = RARequire("RAWorldManager")
            RARootManager.CloseAllPages()
            RAWorldManager:LocateAt(tonumber(mPosXorY.x), tonumber(mPosXorY.y))
        elseif id == RAGameConfig.HTMLID.MailShare then  --邮件分享
            --
            local mailShareId = data[1]
            local playerId = data[2]
            local configId = tonumber(data[3])
            local RAMailUtility = RARequire("RAMailUtility")
            local isInvestMail = RAMailUtility:isInvestMailPage(configId)
            if isInvestMail==nil then return end

            if isInvestMail then
                RARootManager.OpenPage('RAMailInvestigateBasePage', {id = mailShareId,isShare = true,mailPlayerId=playerId,cfgId=configId})
            else
                RARootManager.OpenPage('RAMailPlayerFightSuccessPage', {id = mailShareId,isShare = true,mailPlayerId=playerId,cfgId=configId})
            end
            
        elseif id == RAGameConfig.HTMLID.ShowBombPage then    --超级框
            local RAAllianceManager=RARequire("RAAllianceManager")
            RAAllianceManager:showSolePage()
        elseif id == RAGameConfig.HTMLID.AllianceRedPacketLuckyTry then --联盟拼手气红包 
        
            --注册消息
            RARootManager.ShowWaitingPage(false)

            local addHandler = function()
                -- body
                local HP_pb = RARequire("HP_pb")
                RAChatManager.netHandlers = {}
                RAChatManager.netHandlers[#RAChatManager.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_RP_LUCKY_TRY_S, RAChatManager)   --查看其他玩家邮件返回监听
            end

            addHandler()

            local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")  
            RAAllianceProtoManager:sendPacketLuckyTryReq(data[1])

        elseif id == RAGameConfig.HTMLID.AllianceRedPacketOpen then     --开启联盟红包
            --注册消息
            RARootManager.ShowWaitingPage(false)

            local addHandler = function()
                -- body
                local HP_pb = RARequire("HP_pb")
                RAChatManager.netHandlers = {}
                RAChatManager.netHandlers[#RAChatManager.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_RP_OPEN_S, RAChatManager)   --查看其他玩家邮件返回监听
            end

            addHandler()

            local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")  
            RAAllianceProtoManager:sendOpenPacketReq(data[1])
        elseif id == RAGameConfig.HTMLID.CorePos then                   --跳到王座位置
            RARootManager.CloseAllPages()
            local RAWorldManager = RARequire("RAWorldManager")
            RAWorldManager:LocateAtSelfCapital()
        elseif id == RAGameConfig.HTMLID.LaunchPlatform then            --跳到发射平台界面
            RARootManager.OpenPage('RAAllianceSiloPlatformPage', nil, true, true, true)
        end
	end
    local RAMainUIBottomBanner = RARequire("RAMainUIBottomBannerNew")
	performWithDelay(RAMainUIBottomBanner.mBottomCityNode, delayFunc, 0.05)
end

--移除协议监听
function RAChatManager:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
    self.netHandlers = {}
end 

function RAChatManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_RP_OPEN_S then     --开启红包
        local msg = GuildManager_pb.OpenPacketResp()
        msg:ParseFromString(buffer)   
        if msg.success then
            RARootManager.OpenPage("RAAllianceGiftMoneyOpenAniPage",{diamonds = msg.getGold})
        else
            RARootManager.ShowMsgBox(_RALang("@OpenFail"))    
        end
    elseif pbCode == HP_pb.GUILD_RP_LUCKY_TRY_S then
        local msg = GuildManager_pb.PacketLuckyTryResp()
        msg:ParseFromString(buffer)   

        RARootManager.OpenPage("RAAllianceGiftMoneyOpenAniPage",{diamonds = msg.luckyGold})    
    end
    --删除消息
    self:removeHandler()
    RARootManager.RemoveWaitingPage()
end

return RAChatManager