--è”ç›Ÿçš„å·¥å…·ç±»
local GuildManager_pb = RARequire('GuildManager_pb')
local Const_pb = RARequire('Const_pb')
local RAAllianceUtility = {}

--判断联盟名字是否合法 0为合法 -1长度不符合 -2 格式非法 -3屏蔽字
function RAAllianceUtility:checkAllianceName(allianceName)
	local common = RARequire('common')

	local length =  GameMaths:calculateNumCharacters(allianceName)

    local guild_const_conf = RARequire('guild_const_conf')
    local confMinAndMaxLen = guild_const_conf.allianceNameMinMax.value
    local RAStringUtil = RARequire('RAStringUtil')
    local lenTb= RAStringUtil:split(confMinAndMaxLen,"_")
    local minLen = lenTb[1]
    local maxLen = lenTb[2]
   
	if length<tonumber(minLen) or length>tonumber(maxLen) then 
		return -1
	end 

	if not common:checkStringValidate(allianceName) then 
		return -2
	end 

	if not RAStringUtil:isStringOKForChat(allianceName) then 
		CCLuaLog('屏蔽字')
		return -3
	end 

	return 0
end

--判断联盟输入的文字是否合法 0为合法 -1长度不符合 -2 格式非法 -3屏蔽字
function RAAllianceUtility:checkAllianceString(str,strMinLen,strMaxLen)
	local RAStringUtil = RARequire('RAStringUtil')
	local common = RARequire('common')

    local guild_const_conf = RARequire('guild_const_conf')
    local confMinAndMaxLen = guild_const_conf.allianceNameMinMax.value
    local lenTb = RAStringUtil:split(confMinAndMaxLen,"_")
    local minLen = lenTb[1]
    local maxLen = lenTb[2]
	strMinLen = strMinLen or minLen
	strMaxLen = strMaxLen or maxLen

	local length = GameMaths:calculateNumCharacters(str)
	if length < strMinLen or length > strMaxLen then 
		return -1
	end 

	if not common:checkStringValidate(str) then 
		return -2
	end 

	if not RAStringUtil:isStringOKForChat(str) then 
		CCLuaLog('屏蔽字')
		return -3
	end 

	return 0
end

--获得联盟默认的名字
function RAAllianceUtility:getDefaultLName()
	
	local names = {}

	for i=5,1,-1 do
		local key = 'L' .. i .. 'Name' 
		names[#names + 1] = '@Default' .. key
	end

	return names
end

function RAAllianceUtility:getLIcon(authority)
	return 'Common_Icon_Diamonds.png'
end

function RAAllianceUtility:getLogIcon(logType)
	--local LogIcon = 'Common_Icon_Diamonds.png'
	-- if logType == GuildManager_pb.CREATE then 
	-- 	LogIcon = 'Alliance_Icon_H_Create.png'
	-- elseif logType == GuildManager_pb.JOIN then
	-- 	LogIcon = 'Alliance_Icon_H_Join.png'
	-- elseif logType == GuildManager_pb.KICK then
	-- 	LogIcon = 'Alliance_Icon_H_Fire.png'
	-- elseif logType == GuildManager_pb.QUIT then
	-- 	LogIcon = 'Alliance_Icon_H_Exit.png'
	-- end

	local LogIcon = 'Common_Icon_Diamonds.png'
	local guild_log_conf = RARequire("guild_log_conf")
	local guildLog = guild_log_conf[tonumber(logType)]
	if guildLog then
		LogIcon = guildLog.pic
	end

	return LogIcon
end

function RAAllianceUtility:getLogText(log)
	-- local RAStringUtil = RARequire('RAStringUtil')
	-- local text = ''
	-- if log.logType == GuildManager_pb.CREATE then 
	-- 	text = _RALang('@AllianceLogCreate',log.param)
	-- elseif log.logType == GuildManager_pb.JOIN then
	-- 	text = _RALang('@AllianceLogJoin',log.param)
	-- elseif log.logType == GuildManager_pb.KICK then
	-- 	text = _RALang('@AllianceLogKick',log.param)
	-- elseif log.logType == GuildManager_pb.QUIT then
	-- 	text = _RALang('@AllianceLogQuit',log.param)
	-- end

	local text = ''
	if log then
		local guild_log_conf = RARequire("guild_log_conf")
		local guildLog = guild_log_conf[tonumber(log.logType)]
		if guildLog then
			local content = guildLog.content
			text = _RALang(content, log.param)
		end
	end
	return text
end


--判断联盟缩写是否合法 0为合法 -1长度不符合 -2 格式非法 -3屏蔽字
function RAAllianceUtility:checkAllianceTag(allianceTag)
	local RAStringUtil = RARequire('RAStringUtil')
	local common = RARequire('common')

	local len = #allianceTag
	if len ~= 4 then 
		
		for i=1,len do
	    	local c = allianceTag:sub(i,i)
	    	--step.1 judge if it's alphanumerical and "_","-"," " character
	    	local ret1 = c:match("[%w]")
	    	if ret1 == nil then
	            
	            return -2
	    	end
    	end

		return -1 --长度不合法
	end 

    for i=1,len do
    	local c = allianceTag:sub(i,i)
    	--step.1 judge if it's alphanumerical and "_","-"," " character
    	local ret1 = c:match("[%w]")
    	if ret1 == nil then
            
            return -2
    	end
    end

	if not RAStringUtil:isStringOKForChat(allianceTag) then 
		-- CCLuaLog('屏蔽字')
		return -3
	end 

	return 0
end

--判断联盟宣言是否合法 0为合法 -1长度不符合 -3屏蔽字
function RAAllianceUtility:checkAllianceDeclaration(allianceDeclaration)
	local RAStringUtil = RARequire('RAStringUtil')
	local common = RARequire('common')

	local length = RAStringUtil:getStringUTF8Len(allianceDeclaration)
	if length<= 0 or length>200 then 
		return -1
	end

	if not RAStringUtil:isStringOKForChat(allianceDeclaration) then 
		-- CCLuaLog('屏蔽字')
		return -3
	end 
end

--根据旗帜ID获取旗帜icon
function RAAllianceUtility:getAllianceFlagIdByIcon(flagId)
	flagId = tonumber(flagId)
	local alliance_flag_conf = RARequire('alliance_flag_conf')
    local icon = ""
    if alliance_flag_conf[flagId] then
        icon = alliance_flag_conf[flagId].pic
    end
    return icon
end

--根据旗帜ID获取旗帜small icon
function RAAllianceUtility:getAllianceSmallFlag(flagId)
	flagId = tonumber(flagId)
	local alliance_flag_conf = RARequire('alliance_flag_conf') or {}
    local icon = ''
    if alliance_flag_conf[flagId] then
        icon = alliance_flag_conf[flagId].icon
    end
    return icon
end

--根据类型得到名字
function RAAllianceUtility:getAllianceTypeName(allianceType)
	local text = ''

	local GuildManager_pb = RARequire('GuildManager_pb')

    if allianceType == GuildManager_pb.STRATEGIC then
        text = _RALang('@AllianceTypeStrategic') --平衡型
    elseif allianceType == GuildManager_pb.DEVELOPING then 
        text = _RALang('@AllianceTypeDeveloping') -- 发展形
    elseif allianceType == GuildManager_pb.FIGHTING then 
        text = _RALang('@AllianceTypeFighting')
    else 
        text = _RALang('@AllianceTypeAll')
    end

    return text
end

--是否有权限编辑公告
function RAAllianceUtility:isCanEditAnnouncement(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
    if alliance_authority_conf[authority] then
        local vlaue = alliance_authority_conf[authority].edit_alliance_notice
        if vlaue == 1 then
            result = true
        end
    end
	return result
end

--是否可以重建雕像
function RAAllianceUtility:isCanRebuildStatue(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
    if alliance_authority_conf[authority] then
        local vlaue = alliance_authority_conf[authority].alliance_science_research
        if vlaue == 1 then
            result = true
        end
    end
	return result
end

--是否可以踢人
function RAAllianceUtility:isCanKickPeople(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
    local RAAllianceManager = RARequire("RAAllianceManager")
    local selfAuthority = RAAllianceManager.authority
    if alliance_authority_conf[selfAuthority] then
        local vlaue = alliance_authority_conf[selfAuthority].expel_alliance
        if vlaue == 1 then --有权限的情况下,判断这个人是否可以踢
        	--1.判断权限是不是比被踢得人高(相等的情况下也不能踢)
        	if tonumber(selfAuthority) > tonumber(authority) then
        		result = true
        	end
        end
    end
	return result
end

--是否可以调整玩家阶级
function RAAllianceUtility:isCanPlayerClass(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
    local RAAllianceManager = RARequire("RAAllianceManager")
	local authorityConf = alliance_authority_conf[RAAllianceManager.authority]
	if authorityConf then
		
    	local selfAuthority = RAAllianceManager.authority
		local vlaue = authorityConf.change_member_level
		if vlaue == 1 then 
    		if tonumber(selfAuthority) > tonumber(authority) then
        		result = true
        	end
        end
	end
	return result
end

--是否可以邀请迁城
function RAAllianceUtility:isCanInvatationCity(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
    local RAAllianceManager = RARequire("RAAllianceManager")
	local authorityConf = alliance_authority_conf[RAAllianceManager.authority]
	if authorityConf then
		
    	local selfAuthority = RAAllianceManager.authority
		local vlaue = authorityConf.invite_to_move
		if vlaue == 1 then 
    		if tonumber(selfAuthority) > tonumber(authority) then
        		result = true
        	end
        end
	end
	return result
end

--是否可以有屏蔽留言的权限
function RAAllianceUtility:isMessageMask(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')
    local result = false
	local authorityConf = alliance_authority_conf[authority]
	if authorityConf then
		local vlaue = authorityConf.message_leaving_authority
		if vlaue == 1 then 
    		result = true
        end
	end
	return result
end

--根据语言id获取玩家语言
function RAAllianceUtility:getLanguageIdByName(languageId)
    local alliance_language_conf = RARequire('alliance_language_conf')
    if languageId == "" or nil == languageId then
        languageId = "all"
    end
    -- languageId = string.lower(languageId)
    local languageConf = alliance_language_conf[languageId]
    if languageConf then
    	languageName = languageConf.language_name
    end	
	return languageName
end

--根据权限id获取申请权限
function RAAllianceUtility:getApplyIdById(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')

    local result = false
    local authorityConf = alliance_authority_conf[authority]
    if authorityConf then
    	local inviteToJoin = authorityConf.invite_to_join_alliance
    	if inviteToJoin == 1 then
    		result = true
    	end
    end	
	return result
end

-- 是否可以建造超级武器发射平台
function RAAllianceUtility:isAbleToBuildLanchSilo(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')

    local result = false
    local authorityConf = alliance_authority_conf[authority]
    if authorityConf then
    	local inviteToJoin = authorityConf.nuclear_launch
    	if inviteToJoin == 1 then
    		result = true
    	end
    end	
	return result
end

--是否可以发射核弹
function RAAllianceUtility:isAbleToLaunchBomb(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')

    local result = false
    local authorityConf = alliance_authority_conf[authority]
    if authorityConf then
    	local inviteToJoin = authorityConf.nuclear_launch
    	if inviteToJoin == 1 then
    		result = true
    	end
    end	
	return result
end

--是否可以发射核弹
function RAAllianceUtility:isAbleToSendOutRedPackage(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')

    local result = false
    local authorityConf = alliance_authority_conf[authority]
    if authorityConf then
    	local inviteToJoin = authorityConf.red_packet_open
    	if inviteToJoin == 1 then
    		result = true
    	end
    end	
	return result
end

function RAAllianceUtility:isCanOperationInProtectTime(organizerName)
	
	local RAAllianceManager = RARequire("RAAllianceManager")
	local RAPlayerInfoManager =  RARequire("RAPlayerInfoManager")
    local selfAuthority = RAAllianceManager.authority 
    if selfAuthority == 5 then --盟主
    	return true
    elseif organizerName == RAPlayerInfoManager.getPlayerName() then 
    	return true
    end 

    return false
end

--是否可以修改超级矿
function RAAllianceUtility:isAbleToChangeSuperMineRes(authority)
    local alliance_authority_conf = RARequire('alliance_authority_conf')

    local result = false
    local authorityConf = alliance_authority_conf[authority]
    if authorityConf then
    	local changeRes = authorityConf.alliance_resource_change
    	if changeRes == 1 then
    		result = true
    	end
    end	
	return result
end

function RAAllianceUtility:isActiveManor(manorId)
	local RAAllianceManager = RARequire('RAAllianceManager')
	
	if RAAllianceManager.selfAlliance == nil then 
		return false
	end 

	if RAAllianceManager.selfAlliance.manorId == nil then 
		return false
	end 

	if RAAllianceManager.selfAlliance.manorId == manorId then 
		return true
	end 

	return false
end


function RAAllianceUtility:getUraniumOutput(territoryData)

	if territoryData == nil then 
		return 0
	end 

	if territoryData.superWeaponType == nil then 
		return 0
	else
		if territoryData.superWeaponType == Const_pb.GUILD_SILO then 
			return territoryData.buildings[Const_pb.GUILD_URANIUM].confData.uraniumYield 
		elseif territoryData.superWeaponType == Const_pb.GUILD_WEATHER then 
			return territoryData.buildings[Const_pb.GUILD_ELECTRIC].confData.nuclearPowerYield
		end 
	end

	return 0 
end


return RAAllianceUtility