--这个类负责处理联盟的全部协议发送
RARequire('extern')

-- local Const_pb = RARequire('Const_pb')
local GuildManager_pb = RARequire('GuildManager_pb')
local HP_pb = RARequire('HP_pb')
local GuildManor_pb = RARequire('GuildManor_pb')
local RANetUtil = RARequire("RANetUtil")
local RAAllianceInfo = RARequire("RAAllianceInfo")

local RAAllianceProtoManager = class('RAAllianceProtoManager',{
    })

--联盟申请
function RAAllianceProtoManager:applyReq(id)
	local cmd = GuildManager_pb.ApplyGuildReq()
    cmd.guildId = id
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_APPLY_C,cmd,{retOpcode=-1})
end

--创建联盟
function RAAllianceProtoManager:createAllianceReq(name,tag,language,announcement)
	local cmd = GuildManager_pb.CreateGuildReq()
    cmd.name = name
    cmd.tag = tag
    cmd.language = language
    cmd.announcement = announcement
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CREATE_C,cmd,{retOpcode=-1})
end

--请求联盟信息
function RAAllianceProtoManager:getAllianceReq(guildId)
    
    local cmd = GuildManager_pb.GetGuildMemeberInfoReq()
    cmd.guildId = tostring(guildId) or ''

    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETINFO_C,cmd,{retOpcode=-1})
end

--请求联盟日志
function RAAllianceProtoManager:getAllianceLogReg()
    RANetUtil:sendPacket(HP_pb.GUILD_GETLOG_C,nil,{retOpcode=-1})
end

--修改联盟类型
function RAAllianceProtoManager:changeAllianceType(guildType)

    local cmd = GuildManager_pb.ChangeGuildTypeReq()
    cmd.guildType = guildType

    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGETYPE_C,cmd,{retOpcode=-1})
end

--请求申请过的联盟日志
function RAAllianceProtoManager:getApplyAlliancesReg()
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETPLAYERAPPLY_C,nil,{retOpcode=-1})
end

--获得联盟日志
function RAAllianceProtoManager:getAllianceLogResp(buffer)
    local RAAllianceGuildLogInfo = RARequire("RAAllianceGuildLogInfo")
    local msg = GuildManager_pb.GetGuildLog()
    msg:ParseFromString(buffer)
    local logInfos = {}
    for i=1,#msg.info do
        local info = RAAllianceGuildLogInfo.new()
        info:initByPb(msg.info[i])
        logInfos[#logInfos + 1] = info
    end
    return logInfos
end

--获得商店数据
function RAAllianceProtoManager:getShopInfo(buffer)
    local RAAllianceShopInfo = RARequire("RAAllianceShopInfo")
    local msg = GuildManager_pb.HPGetGuildShopInfoResp()
    msg:ParseFromString(buffer)
    local shopInfo = RAAllianceShopInfo.new()
    shopInfo:initByPb(msg)
    return shopInfo
end

--获得商店全部数据
function RAAllianceProtoManager:getAllShopItem(buffer)
    local RAAllianceShopInfo = RARequire("RAAllianceShopInfo")
    local msg = GuildManager_pb.HPGetGuildShopItemListResp()
    msg:ParseFromString(buffer)
    local shopInfo = RAAllianceShopInfo.new()
    shopInfo:initByPb(msg)
    return shopInfo
end

--购买联盟商店道具
function RAAllianceProtoManager:buyItem(itemID,count)
    local cmd = GuildManager_pb.HPGuildShopBuyReq()
    cmd.itemId = itemID
    cmd.count = count
    RANetUtil:sendPacket(HP_pb.GUILD_SHOP_BUY_C,cmd,{retOpcode=-1})
end

--获得购买记录
function RAAllianceProtoManager:reqBuyRecord()
    RANetUtil:sendPacket(HP_pb.GUILD_GET_SHOP_LOG_C,cmd,{retOpcode=-1})
end

--发起投票
function RAAllianceProtoManager:reqNuclearVote()
    RANetUtil:sendPacket(HP_pb.NUCLEAR_VOTE_C,cmd,{retOpcode=-1})
end

--获取联盟商店信息
function RAAllianceProtoManager:reqShopInfo()
    RANetUtil:sendPacket(HP_pb.GUILD_GET_SHOP_INFO_C,cmd,{retOpcode=-1})
end

--获取全部商店物品信息
function RAAllianceProtoManager:reqAllShopItems()
    RANetUtil:sendPacket(HP_pb.GUILD_GET_SHOP_ITEM_LIST_C,cmd,{retOpcode=-1})
end

--获取全部购买日志
function RAAllianceProtoManager:reqAllBuyRecords()
    RANetUtil:sendPacket(HP_pb.GUILD_GET_SHOP_LOG_C,cmd,{retOpcode=-1})
end

--获取全部购买日志
function RAAllianceProtoManager:getAllBuyRecords(buffer)
    local RAAllianceBuyRecord = RARequire("RAAllianceBuyRecord")
    local msg = GuildManager_pb.HPGetGuildShopLogResp()
    msg:ParseFromString(buffer)

    local buyRecords = {}
    for i=1,#msg.shopLog do
        local shopLog = RAAllianceBuyRecord.new()
        shopLog:initByPb(msg.shopLog[i])
        buyRecords[i] = shopLog
    end

    return buyRecords
end


--请求核弹发射井的数据
function RAAllianceProtoManager:reqNuclearInfo()
    RANetUtil:sendPacket(HP_pb.GET_NUCLEAR_INFO_C,cmd,{retOpcode=-1})
end

--请求核弹发射井的数据
function RAAllianceProtoManager:reqCancelNuclear()
    RANetUtil:sendPacket(HP_pb.NUCLEAR_CANCEL_C,cmd,{retOpcode=-1})
end

--请求发起投票
function RAAllianceProtoManager:reqBeginNuclearVote(launchType)
    if launchType ~= GuildManor_pb.FROM_MANOR and 
        launchType ~= GuildManor_pb.FROM_MACHINE then
        launchType = GuildManor_pb.FROM_MANOR
    end
    local cmd = GuildManor_pb.HPBegainVote()
    cmd.launchType = launchType
    RANetUtil:sendPacket(HP_pb.NUCLEAR_BEGIN_VOTE_C,cmd,{retOpcode=-1})
end

--获取核弹发射井的数据
function RAAllianceProtoManager:getNuclearInfo(buffer)
    local RAAllianceNuclearInfo = RARequire("RAAllianceNuclearInfo")
    local msg = GuildManor_pb.NuclearInfo()
    msg:ParseFromString(buffer)

    local allianceNuclearInfo = RAAllianceNuclearInfo.new()
    allianceNuclearInfo:initByPb(msg)
    return allianceNuclearInfo
end

--检测联盟名字
function RAAllianceProtoManager:checkGuildNameReq(guildName)
	local cmd = GuildManager_pb.CheckGuildNameReq()
    cmd.guildName = guildName
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHECKNAME_C,cmd,{retOpcode=-1})
end

--检测联盟简称合法
function RAAllianceProtoManager:checkGuildTagReq(guildTag)
	local cmd = GuildManager_pb.CheckGuildTagReq()
    cmd.guildTag = guildTag
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHECKTAG_C,cmd,{retOpcode=-1})
end

--开始投票
function RAAllianceProtoManager:reqNulcearVote(index)
    local cmd = GuildManor_pb.HPNuclearVote()
    cmd.index = index
    RANetUtil:sendPacket(HP_pb.NUCLEAR_VOTE_C,cmd,{retOpcode=-1})
end

--展开发射井
function RAAllianceProtoManager:reqOpenNulcear()
    RANetUtil:sendPacket(HP_pb.NUCLEAR_OPEN_UP_C,cmd,{retOpcode=-1})
end

--获得推荐联盟信息
function RAAllianceProtoManager:getRecommendGuildListReq(pageNum)
	local cmd = GuildManager_pb.GetRecommendGuildListReq()
    cmd.pageNum = pageNum
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_RECOMMEND_C,cmd,{retOpcode=-1})
end

--搜索联盟
function RAAllianceProtoManager:getSearchGuildListReq(name)
    local RAStringUtil =  RARequire('RAStringUtil')
    name = RAStringUtil:trim(name)

    local length = GameMaths:calculateNumCharacters(name)
    if length < 4 then 
        return 
    end 

	local cmd = GuildManager_pb.GetSearchGuildListReq()
    cmd.name = name
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_SEARCH_C,cmd,{retOpcode=-1})
end

--取消申请联盟
function RAAllianceProtoManager:cancelApplyReq(guildId)
	local cmd = GuildManager_pb.CancelApplyReq()
    cmd.guildId = guildId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CANCELAPPLY_C,cmd,{retOpcode=-1})
end

--接受联盟邀请
function RAAllianceProtoManager:acceptInviteReq(guildId)
	local cmd = GuildManager_pb.AcceptInviteReq()
    cmd.guildId = guildId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_ACCEPTINVITE_C,cmd,{retOpcode=-1})
end

--拒绝联盟邀请
function RAAllianceProtoManager:refuseInviteReq(guildId)
    local cmd = GuildManager_pb.RefuseInviteReq()
    cmd.guildId = guildId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_REFUSEINVITE_C,cmd,{retOpcode=-1})
end

--发布/修改 联盟宣言
function RAAllianceProtoManager:postAnnouncement(announcement)
	local cmd = GuildManager_pb.PostAnnouncementReq()
    cmd.announcement = announcement
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C,cmd,{retOpcode=-1})
end

--发布/修改 联盟公告
function RAAllianceProtoManager:postNoticeReq(notice)
    local cmd = GuildManager_pb.PostNoticeReq()
    cmd.notice = notice
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTNOTICE_C,cmd,{retOpcode=-1})
end

--修改联盟名称
function RAAllianceProtoManager:changeGuildName(guildName)
	local cmd = GuildManager_pb.ChangeGuildNameReq()
    cmd.guildName = guildName
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGENAME_C,cmd,{retOpcode=-1})
end

--修改联盟简称
function RAAllianceProtoManager:changeGuildTag(guildTag)
	local cmd = GuildManager_pb.ChangeGuildTagReq()
    cmd.guildTag = guildTag
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGETAG_C,cmd,{retOpcode=-1})
end

--修改联盟公开招募 isOpen:是否开启 buildingLevel:大本等级 power:限制战力 commonderLevel:指挥官等级 语言 默认all
function RAAllianceProtoManager:changeGuildApplyPermiton(isOpen,buildingLevel,power,commonderLevel,language)
	local cmd = GuildManager_pb.ChangeGuildApplyPermitonReq()
    cmd.isOpen = isOpen
    if isOpen then
	    cmd.buildingLevel = buildingLevel
	    cmd.power = power
	    cmd.commonderLevel = commonderLevel
	    cmd.lang = language
	end   	 
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGEAPPLYPERMITON_C,cmd,{retOpcode=-1})
end

--修改联盟旗帜
function RAAllianceProtoManager:changeGuildFlag(guildFlag)
	local cmd = GuildManager_pb.ChangeGuildFlagReq()
    cmd.guildFlag = guildFlag
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGEFLAG_C,cmd,{retOpcode=-1})
end

--改变联盟语言
function RAAllianceProtoManager:changeGuildLang(guildLang)
	local cmd = GuildManager_pb.ChangeGuildLangReq()
    cmd.guildLang = guildLang
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGELANG_C,cmd,{retOpcode=-1})
end

--改变联盟成员权限
function RAAllianceProtoManager:changeGuildLevel(playerId)
	local cmd = GuildManager_pb.ChangeGuildLevelReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C,cmd,{retOpcode=-1})
end

--改变联盟阶级名称
function RAAllianceProtoManager:changeLevelName(L1Name,L2Name,L3Name,L4Name,L5Name)
	local cmd = GuildManager_pb.ChangeLevelNameReq()
	if L1Name ~= "" then
		cmd.L1Name = L1Name
	end
	if L2Name ~= "" then
		cmd.L2Name = L2Name
	end
	if L3Name ~= "" then
		cmd.L3Name = L3Name
	end
	if L4Name ~= "" then
		cmd.L4Name = L4Name
	end
	if L5Name ~= "" then
		cmd.L5Name = L5Name
	end
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHANGELEVELNAME_C,cmd,{retOpcode=-1})
end

--踢出联盟成员
function RAAllianceProtoManager:kickMember(playerId)
	local cmd = GuildManager_pb.KickMemberReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C,cmd,{retOpcode=-1})
end

--弹劾联盟盟主
function RAAllianceProtoManager:dimiseLeader(playerId)
	local cmd = GuildManager_pb.DimiseLeaderReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_DEMISELEADER_C,cmd,{retOpcode=-1})
end

--设置联盟外交官
function RAAllianceProtoManager:grantColeader(playerId)
	local cmd = GuildManager_pb.GrantColeaderReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C,cmd,{retOpcode=-1})
end

--解散联盟
--GUILDMANAGER_DISSMISEGUILD_C = 9054;
--GUILDMANAGER_DISSMISEGUILD_S = 9055;
function RAAllianceProtoManager:dissolutionAlliance()
	-- body
	RANetUtil:sendPacket(HP_pb.GUILDMANAGER_DISSMISEGUILD_C,nil,{retOpcode=-1})	
end	

function RAAllianceProtoManager:searchAllianceResp(buffer)
    local msg = GuildManager_pb.GetSearchGuildListResp()
    msg:ParseFromString(buffer)

    local searchArr = {}
    for i=1,#msg.info do
        local info = RAAllianceInfo.new()
        info:initByPb(msg.info[i])
        searchArr[i] = info
    end

    return searchArr
end

function RAAllianceProtoManager:applyAllianceResp(buffer)
    local msg = GuildManager_pb.GetPlayerGuildApplyResp()
    msg:ParseFromString(buffer)

    local applyArr = {}
    for i=1,#msg.info do
        local info = RAAllianceInfo.new()
        info:initByPb(msg.info[i])
        applyArr[i] = info
    end

    return applyArr
end

function RAAllianceProtoManager:getPlayerGuildInviteInfoReq()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETPLAYERINVITE_C,nil,{retOpcode=-1}) 
end 

function RAAllianceProtoManager:getPlayerGuildInviteInfo(buffer)
    local msg = GuildManager_pb.GetPlayerGuildInviteInfo()
    msg:ParseFromString(buffer)

    local inviteArr = {}
    for i=1,#msg.info do
        local info = RAAllianceInfo.new()
        info:initByPb(msg.info[i])
        inviteArr[i] = info
    end

    return inviteArr
end

-- 请求联盟成员信息
function RAAllianceProtoManager:getGuildMemeberInfoReq(guildId)
    local cmd = GuildManager_pb.GetGuildMemeberInfoReq()
    cmd.guildId = tostring(guildId) or ''
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETMEMBERINFO_C,cmd,{retOpcode=-1})
end

--设置联盟成员信息
function RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
    local msg = GuildManager_pb.GetGuildMemeberInfoResp()
    msg:ParseFromString(buffer)

    local RAAllianceMemeberInfo = RARequire("RAAllianceMemeberInfo")
    local transferInfo = {}
    for i=1,#msg.info do
        local info = RAAllianceMemeberInfo.new()
        info:initByPb(msg.info[i])
        transferInfo[#transferInfo+1] = info
    end

    local leaderNames = {}

    for i=5,1,-1 do
        local fieldName = 'l' .. i .. 'Name'
        if msg:HasField(fieldName) then 
            leaderNames[#leaderNames+1] = msg[fieldName]
        else 
            leaderNames[#leaderNames+1] = '@Default' .. 'L' .. i .. 'Name'
        end 
    end

    return transferInfo,leaderNames
end

--获取屏蔽玩家列表
function RAAllianceProtoManager:getForbidPlayerList()
	-- body
	RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETFORBIDLIST_C,nil,{retOpcode=-1})	
end	

--取消玩家屏蔽
function RAAllianceProtoManager:cancelForbinPlayer(playerId)
	-- body
	local cmd = GuildManager_pb.CancelForbinPlayerReq()
    cmd.playerId = tostring(playerId) or ''
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CANCELFORBIDMESSAGE_C,cmd,{retOpcode=-1})
end

--退出联盟
function RAAllianceProtoManager:quitAlliance(playerId)
	-- body
	local cmd = GuildManager_pb.KickMemberReq()
    cmd.playerId = tostring(playerId) or ''
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_QUIT_C,cmd,{retOpcode=-1})
end

--获得其他联盟
function RAAllianceProtoManager:getOtherGuildReq(pageNum)
	-- body
	local cmd = GuildManager_pb.GetOtherGuildReq()
    cmd.pageNum = tonumber(pageNum) or 1
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETOTHERGUILD_C,cmd,{retOpcode=-1})
end

--设置申请联盟信息
function RAAllianceProtoManager:setAllianceApplyInfo(buffer)
    local RAAllianceApplyInfo = RARequire("RAAllianceApplyInfo")
    local msg = GuildManager_pb.GetForbidPlayerListResp()
    msg:ParseFromString(buffer)
    local applyInfo = {}
    for i=1,#msg.info do
        local info = RAAllianceApplyInfo.new()
        info:initByPb(msg.info[i])
        applyInfo[#applyInfo + 1] = info
    end
    return applyInfo
end

--获得联盟留言
function RAAllianceProtoManager:getGuildMessageReq(guildId)
    -- body
    local cmd = GuildManager_pb.GetGuildMessageReq()
    cmd.guildId = guildId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETMESSAGE_C,cmd,{retOpcode=-1})
end

--发布联盟留言
function RAAllianceProtoManager:postMessageReq(message,guildId)
    -- body
    local cmd = GuildManager_pb.PostMessageReq()
    cmd.message = message
    cmd.guildId = guildId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_POSTMESSAGE_C,cmd,{retOpcode=-1})
end

--获得联盟留言返回
function RAAllianceProtoManager:getGuildMessageResp(buffer)
    local RAAllianceBBSMessageInfo = RARequire("RAAllianceBBSMessageInfo")
    local msg = GuildManager_pb.GetGuildBBSMessageResp()
    msg:ParseFromString(buffer)
    local messagesArr = {}
    for i=1,#msg.message do
        local message = RAAllianceBBSMessageInfo.new()
        message:initByPb(msg.message[i])
        messagesArr[#messagesArr + 1] = message
    end
    return messagesArr,msg.isForbiden
end

--屏蔽玩家留言
function RAAllianceProtoManager:forbidPlayerPostMessageReq(playerId)
    -- body
    local cmd = GuildManager_pb.ForbidPlayerPostMessageReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_FORBIDPLAYERMESSAGE_C,cmd,{retOpcode=-1})
end


--查看联盟帮助
function RAAllianceProtoManager:sendGetHelpInfoReq()
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CHECKQUEUES_C)
end

--生产核弹
function RAAllianceProtoManager:sendCreateWeaponReq()
    RANetUtil:sendPacket(HP_pb.NUCLEAR_CREATE_C,nil,{retOpcode=-1})
end

--联盟帮助请求
function RAAllianceProtoManager:sendHelpInfoReq(queueId)
    -- body
    local cmd = GuildManager_pb.HelpGuildQueueReq()
    cmd.queueId = queueId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_HELPQUEUE_C,cmd,{retOpcode=-1})
end

--联盟帮助所有请求
function RAAllianceProtoManager:sendHelpAllInfoReq()
     RANetUtil:sendPacket(HP_pb.GUILDMANAGER_HELPALLQUEUES_C)
end

--申请联盟帮助
function RAAllianceProtoManager:sendApplyHelpInfoReq(queueId)
    local cmd = GuildManager_pb.ApplyGuildHelpReq()
    cmd.queueId=queueId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_APPLYHELP_C,cmd)
end

--联盟战争请求 to 集结
function RAAllianceProtoManager:sendWarGatherReq()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILDWAR_GETMASSINFO_C,nil,{retOpcode=-1})
end

--联盟战争请求 to 防守
function RAAllianceProtoManager:sendWarAttackReq()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILDWAR_GETDEFINSEINFO_C,nil,{retOpcode=-1})
end

--联盟战争请求 to 攻击
function RAAllianceProtoManager:sendDefendReq()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILDWAR_GETATTACKINFO_C,nil,{retOpcode=-1})
end

--联盟权限提升发送协议
function RAAllianceProtoManager:changeGuildLevelReq(authority,playerId)
    local cmd = GuildManager_pb.ChangeGuildLevelReq()
    cmd.playerId = playerId
    cmd.level = authority
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CAHNGELEVEL_C,cmd)
end

--联盟战争记录
function RAAllianceProtoManager:warRecordReq()
    RANetUtil:sendPacket(HP_pb.GUILD_WAR_RECORD_C,nil,{retOpcode=-1})
end

--获得推荐邀请玩家
function RAAllianceProtoManager:sendGetRecommendInvitePlayerReq(page)
	page = page or 1
    local cmd = GuildManager_pb.GetRecommendInvitePlayerReq()
    cmd.page = page
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETRECOMMANDINVITE_C, cmd)
end

--请求传送要求数据
function RAAllianceProtoManager:sendGetPlayerBasicInfoReq(name)
    if name == nil then return end
    local Player_pb = RARequire("Player_pb")
    local cmd = Player_pb.GetPlayerBasicInfoReq()  
    cmd.name = name
    RANetUtil:sendPacket(HP_pb.PLAYER_GETLOCALPLAYERINFOBYNAME_C, cmd)
end

--请求联盟申请信息
function RAAllianceProtoManager:sendGetGuildPlayerApplyReq()
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETAPPLY_C,nil,{retOpcode=-1})
end

--邀请加入联盟
function RAAllianceProtoManager:sendInviteGuildReq(playerId)
    if playerId == nil then return end
    local cmd = GuildManager_pb.InviteGuildReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_INVITE_C, cmd)
end

--撤回邀请
function RAAllianceProtoManager:sendCancelInviteReq(playerId)
    if playerId == nil then return end
    local cmd = GuildManager_pb.CancelInviteReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_CANCELINVITE_C, cmd)
end

--拒绝
function RAAllianceProtoManager:sendRefuseApplyReq(playerId)
    if playerId == nil then return end
    local cmd = GuildManager_pb.RefuseApplyReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_REFUSEAPPLY_C, cmd)
end

--批准
function RAAllianceProtoManager:sendAcceptApplyReq(playerId)
    if playerId == nil then return end
    local cmd = GuildManager_pb.AcceptApplyReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_ACCEPTAPPLY_C, cmd)
end

--获得送出去的邀请
function RAAllianceProtoManager:sendGetGuildPlayerInviteReq()
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_GETINVITE_C,nil,{retOpcode=-1})
end

--踢出联盟
function RAAllianceProtoManager:sendKickMemberReq(playerId)
    if playerId == nil then return end
    local cmd = GuildManager_pb.KickMemberReq()
    cmd.playerId = playerId
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_KICK_C, cmd)
end

--发起公开招募广播
function RAAllianceProtoManager:sendOpenAllinceRecruitReq()
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_SENDRECRUITNOTICE_C,nil,{retOpcode=-1})
end

--获取联盟贡献排行
function RAAllianceProtoManager:sendetContributionRankReq(rankType)
    local cmd = GuildManager_pb.GuildGetContributionRank()
    cmd.rankType = rankType or 1
    RANetUtil:sendPacket(HP_pb.GUILD_GET_CONTRIBUTION_RANK_C, cmd)
end

--获取联盟雕像信息
function RAAllianceProtoManager:sendGetStatueInfoResp()
    RANetUtil:sendPacket(HP_pb.GUILD_GET_STATUE_INFO_C,nil,{retOpcode=-1})
end

--联盟雕像升级
function RAAllianceProtoManager:sendGuildStatueUpgradeReq(statueId)
    if statueId == nil or statueId == "" then return end
    local cmd = GuildManager_pb.GuildStatueUpgrade()
    cmd.statueId = statueId
    RANetUtil:sendPacket(HP_pb.GUILD_STATUE_UPGRADE_C, cmd)
end

--联盟雕像建造
function RAAllianceProtoManager:sendGuildStatueBuildReq(statueId)
    if statueId == nil or statueId == "" then return end
    local cmd = GuildManager_pb.GuildStatueBuildReq()
    cmd.statueId = statueId
    RANetUtil:sendPacket(HP_pb.GUILD_STATUE_BUILD_C, cmd)
end

--联盟雕像建造
function RAAllianceProtoManager:sendGuildStatueReBuildReq(statueId)
    if statueId == nil or statueId == "" then return end
    local cmd = GuildManager_pb.GuildStatueRefreshReq()
    cmd.statueId = statueId
    RANetUtil:sendPacket(HP_pb.GUILD_STATUE_REFRESH_C, cmd)
end

--联盟雕像刷新结果保存
function RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(statueId, isSave)
    if statueId == nil or statueId == "" then return end
    isSave = isSave or false
    local cmd = GuildManager_pb.GuildStatueSaveRefreshReq()
    cmd.statueId = statueId
    cmd.save = isSave
    RANetUtil:sendPacket(HP_pb.GUILD_STATUE_SAVE_REFRESH_C, cmd)
end

--请求红包信息
function RAAllianceProtoManager:sendGetRedPacketListReq()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILD_RP_GET_INFO_LIST_C,nil,{retOpcode=-1})
end

--发红包
function RAAllianceProtoManager:sendRedPacketReq(packetGold)
    -- body
    if packetGold == nil or packetGold == "" then return end
    local cmd = GuildManager_pb.SendRedPacketReq()
    cmd.packetGold = packetGold
    RANetUtil:sendPacket(HP_pb.GUILD_RP_SEND_C, cmd)
end

--开启红包
function RAAllianceProtoManager:sendOpenPacketReq(packetId)
    -- body
    if packetId == nil or packetId == "" then return end
    local cmd = GuildManager_pb.OpenPacketReq()
    cmd.packetId = packetId
    RANetUtil:sendPacket(HP_pb.GUILD_RP_OPEN_C, cmd)
end

--拼手气红包
function RAAllianceProtoManager:sendPacketLuckyTryReq(packetId)
    -- body
    if packetId == nil or packetId == "" then return end
    local cmd = GuildManager_pb.PacketLuckyTryReq()
    cmd.packetId = packetId
    RANetUtil:sendPacket(HP_pb.GUILD_RP_LUCKY_TRY_C, cmd)
end

--请求历史红包信息
function RAAllianceProtoManager:sendGetPacketDetailInfoRep(packetId)
    -- body
    if packetId == nil or packetId == "" then return end
    local cmd = GuildManager_pb.GetPacketDetailInfoReq()
    cmd.packetId = packetId
    RANetUtil:sendPacket(HP_pb.GUILD_RP_GET_DETAIL_INFO_C,cmd)
end

--
function RAAllianceProtoManager:sendPacketShareReq(packetId)
    -- body
    if packetId == nil or packetId == "" then return end
    local cmd = GuildManager_pb.PacketShareReq()
    cmd.packetId = packetId
    RANetUtil:sendPacket(HP_pb.GUILD_PR_SHARE_C,cmd)
end

--邀请迁城
function RAAllianceProtoManager:sendPacketInviteMove(inviteId)
    -- body
    if inviteId == nil or inviteId == "" then return end
    local cmd = GuildManager_pb.InviteMoveCityReq()
    cmd.inviteeId = inviteId
    RANetUtil:sendPacket(HP_pb.GUILD_INVITE_TO_MOVE_CITY_C,cmd)
end

--取代联盟盟主
function RAAllianceProtoManager:ReplaceLeader()
    -- body
    RANetUtil:sendPacket(HP_pb.GUILDMANAGER_IMPEACHMENTLEADER_C,nil,{retOpcode=-1})
end

return RAAllianceProtoManager