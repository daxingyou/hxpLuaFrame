RARequire("extern")

local RAChatInfo = class("RAChatInfo",{
		type 		= 0,	--类型
		playerId 	= "",	--玩家ID
		name  		= "",	--玩家name
		chatMsg	  	= "",	--聊天内容
		allianceName= "",	--联盟名字
		vip  		= 0,	--vip等级
		msgTime  	= 0,	--时间
		icon  		= 0,	--头像
		guildTag  	= "",	--联盟简称
		hrefCfgName = nil,	--超链接
		hrefCfgPrams= "",	--超链接参数
		noticeType  = "",	--公告类型（1:系统公告  2：警告）
        office      = 0,    --官职id
        vipActive   = false, --VIP是否激活
        broadcastContent = "", --广播的字典名字(服务器传过来，为了和聊天区别html配置)
        chatBroadcastMsg = '' --广播的消息内容
	})

function RAChatInfo:initDataPB(chatInfo)
	self.type           = chatInfo.type    -- 类型
    self.playerId       = chatInfo.playerId    -- 玩家ID
    self.name           = chatInfo.name    -- 玩家name
    self.chatMsg        = chatInfo.chatMsg    -- 聊天内容
    self.allianceName   = chatInfo.allianceName    -- 联盟名字
    self.vip            = chatInfo.vip    -- vip等级
    self.msgTime        = chatInfo.msgTime    -- 时间
    self.icon           = chatInfo.icon
    self.guildTag       = chatInfo.guildTag

    if chatInfo:HasField('hrefCfgPrams') then
        self.hrefCfgPrams = chatInfo.hrefCfgPrams
    end
    if chatInfo:HasField('hrefCfgName') then 
        self.hrefCfgName = chatInfo.hrefCfgName
    end

    if chatInfo:HasField('noticeType') then  --如 警告,系統
        self.noticeType = chatInfo.noticeType
    end

    if chatInfo:HasField('office') then  --官职id
        self.office = chatInfo.office
    end

    if chatInfo:HasField('vipActive') then  --VIP是否激活
        self.vipActive = chatInfo.vipActive
    end

    if chatInfo:HasField('broadcastContent') then  --广播的字典名字
        self.broadcastContent = chatInfo.broadcastContent
    end
end

function RAChatInfo:ctor(...)

end

return RAChatInfo