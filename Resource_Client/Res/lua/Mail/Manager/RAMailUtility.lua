

local RAMailUtility = {}

local Const_pb = RARequire("Const_pb")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RA_Common = RARequire("common")
RARequire("RABuildingUtility")

function RAMailUtility:sortMailDatasByTime(mailDatas)
	local tmpMailDatasTab={}
	local keyTab ={}
	for k,v in pairs(mailDatas) do
		local mailInfo= v
		local mailId = mailInfo.id
		table.insert(keyTab,mailId)
	end
	table.sort(keyTab,function (v1,v2)
		return mailDatas[v1].ctime> mailDatas[v2].ctime
	end)

	for i,v in ipairs(keyTab) do
		local mailInfo = mailDatas[v]
        table.insert(tmpMailDatasTab,mailDatas[v])
	end
    
	return tmpMailDatasTab

end

--Utilitys.formatTimeWithYear(mailTime)
--格式化邮件显示时间  t为一个时间戳 秒级别
function RAMailUtility:formatMailTime(t,isDirect)
	--先判断是否同一天
	local curDate = os.date("*t",RA_Common:getCurTime())
	local curDateStr = string.format("%d-%02d-%02d",curDate.year,curDate.month,curDate.day)
	
	local tmpDate = os.date("*t",t)
	local tmpDayStr = string.format("%d-%02d-%02d",tmpDate.year,tmpDate.month,tmpDate.day)
	if isDirect then 
		local tmpDayStr = string.format("%02d-%02d-%02d %02d:%02d",tmpDate.year,tmpDate.month,tmpDate.day,tmpDate.hour,tmpDate.min)
		return tmpDayStr
	end

	local diffTime = math.abs(Utilitys.getCurDiffTime(t))
	if curDateStr~=tmpDayStr then
		formatT=Utilitys.formatTimeWithYear(t)
	elseif diffTime>=60*60 then
		local hour = 60*60
		formatT=_RALang("@MailTimeHourFormat",math.floor(diffTime/hour))
	else
		formatT=_RALang("@MailTimeMinFormat",math.max(1,math.ceil(diffTime/60)))
	end 
	return formatT
end

function RAMailUtility:getMailFromDatas(id)
	local MailGuide = RARequire("guider_conf")
	if not id or not MailGuide[tonumber(id)] then
		return  MailGuide[0]
	end 
	return MailGuide[tonumber(id)]
end

function RAMailUtility:getItemInfo(itemid)
	local item_conf = RARequire("item_conf")
	local itemInfo = item_conf[tonumber(itemid)]
	return itemInfo
end

function RAMailUtility:getItemIconByid(itemId)
	local RALogicUtil = RARequire("RALogicUtil")
 	return RALogicUtil:getItemIconById(itemId)
end

--获取世界资源点的icon
function RAMailUtility:getWorldResIconById(id)
	local worldResInfo = self:getWorldResDataById(id)
	local icon = worldResInfo.resTargetIcon or "College_u_Icon_BG.png"
	return icon
end

function RAMailUtility:getWorldResDataById(id)
	local world_resource_conf = RARequire("world_resource_conf")
	return world_resource_conf[tonumber(id)]
end

--获取士兵信息
function RAMailUtility:getBattleSoldierDataById(id)
	local battle_soldier_conf = RARequire("battle_soldier_conf")
	return battle_soldier_conf[tonumber(id)]
end

--获取士兵的icon
function RAMailUtility:getBattleSoldierIconById(id)
	local battleSoldierInfo = self:getBattleSoldierDataById(id)
	if not battleSoldierInfo then return "College_u_Icon_BG.png" end 
	local icon = battleSoldierInfo.icon or "College_u_Icon_BG.png"
	return icon
end

--获得怪物信息
function RAMailUtility:getMonsterDataById(id)
	local world_enemy_conf = RARequire("world_enemy_conf")
	return world_enemy_conf[tonumber(id)]
end

--获取怪物的icon
function RAMailUtility:getMonsterIconById(id)
	local world_enemy_conf = RARequire("world_enemy_conf")
	if id==nil then return world_enemy_conf[302000].show end 
	local monsterInfo = self:getMonsterDataById(id)
	if monsterInfo==nil then
		monsterInfo = world_enemy_conf[302000]
	end
	local icon = monsterInfo.show 
	return icon
end

--获取玩家的icon
function RAMailUtility:getPlayerIcon(id)

	local icon=RAPlayerInfoManager.getHeadIcon(id)
	return icon
end


-- --屏蔽掉客户端没有开启的邮件类型
function RAMailUtility:isNoOpenMail(configId)
	local noFinishMailId={
				

				-- 2011151,2011161,2011152,2011162,2011153,2011163,2011041,2011042,2011051,2011052,
				-- 2012022,2012023,2012024,2012025,2012026,2012027,2012028,
				-- 2012033,2012034,2012043,2012044,2012052,2012053,2012062,2012073,2013132,2013151,2013152,2013153,2013161,2013162
		}
	local isNoFinish=Utilitys.tableFind(noFinishMailId,configId)
	return isNoFinish
end

--判断是否是报告类邮件
function RAMailUtility:isReportMail(mailType)
	if  mailType==Const_pb.KILL_MONSTER or mailType==Const_pb.COLLECT then
		return true
	end
	return false 
end


--判断是否是系统邮件
function RAMailUtility:isSystemMail(mailType)
	if  mailType==Const_pb.SYSMAIL_UPDATE or mailType==Const_pb.SYSMAIL_NOTICE 
	    or mailType==Const_pb.SYSMAIL_QA  or  mailType==Const_pb.CURE
	 then
		return true
	end
	return false
end



--判断是否是战斗邮件
function RAMailUtility:isFightMail(mailType)
	if  mailType==Const_pb.CAMP or mailType==Const_pb.DETECT
	    or mailType==Const_pb.BE_DETECTED  or  mailType==Const_pb.FIGHT
	 then
		return true
	end
	return false
end

--判断是否是联盟邮件
function RAMailUtility:isAllianceMail(mailType)
	if  mailType==Const_pb.MOVE_CITY or mailType==Const_pb.ALLIANCE
	    or mailType==Const_pb.ALLIANCE_KICK  or  mailType==Const_pb.ALLIANCE_AGREE_APPLY 
	    or mailType==Const_pb.ALLIANCE_REFUSE_INVITE  or  mailType==Const_pb.ALLIANCE_CHANGE_POS 
	    or mailType==Const_pb.ALLIANCE_DISSOLVE or  mailType==Const_pb.ALLIANCE_REFUSE_APPLY 
	 then
		return true
	end
	return false
end

--判断是否是聊天邮件
function RAMailUtility:isChatMail(mailType)
	if  mailType==Const_pb.CHAT then
		return true
	end 
	return false
end

--判断是自己还是其他玩家
function RAMailUtility:isMine(playerId)
	local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	if playerInfo.raPlayerBasicInfo.playerId==playerId then
		return true
	end
	return false
end

function RAMailUtility:isMineByName(name)
	local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	if playerInfo.raPlayerBasicInfo.name==name then
		return true
	end
	return false
end

function RAMailUtility:getMinePlayId()
	local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	return playerInfo.raPlayerBasicInfo.playerId
end


--获取据点的信息
function RAMailUtility:getGuardData(id)
	local territory_guard_conf = RARequire("territory_guard_conf")
	local guard = territory_guard_conf[tonumber(id)]
	if not guard then
		guard=territory_guard_conf[1]
	end
	return guard
end

-- //系统通知类型
-- enum SystemNoticeType
-- {
-- 	COLLECT_NOTICE			= 1;	//采集
-- 	CAMP_NOTICE				= 2;	//扎营
-- 	DETECT_NOTICE			= 3;	//侦查
-- 	KILL_MONSTER_NOTICE		= 4;	//打怪
-- 	ATTACK_PLAYER_NOTICE	= 5;	//打玩家
-- 	ASSISTANCE_NOTICE		= 6; 	// 援助
-- 	ASSISTANCE_RES_NOTICE	= 7; 	// 资源援助
-- 	SPY_NOTICE				= 8; 	// 侦察
-- 	MASS_NOTICE				= 9; 	// 集结
-- 	MASS_JOIN_NOTICE		= 10; 	// 加入集结

-- };

-- //系统通知原因类型
-- enum SystemNoticeSubType
-- {
-- 	NO_TARGET		= 0;	//目标点不存在
-- 	TARGET_CHANGED	= 1;	//目标点发生变化

-- }

--获取邮件通知的类型
function RAMailUtility:getMailNoticeTitle(id)
	local mail_type_conf=RARequire("mail_type_conf")
	local failData=mail_type_conf[tonumber(id)]
	if not failData then
		failData=mail_type_conf[1]
	end 
	return failData.type_title
end

--获取邮件通知内容
function RAMailUtility:getMailNoticeReason(id)
	local mail_fail_reason_conf=RARequire("mail_fail_reason_conf")
	local failData=mail_fail_reason_conf[tonumber(id)]
	if not failData then
		failData=mail_fail_reason_conf[1]
	end 
	return failData.reason
end

function RAMailUtility:getReasonData(id)
	local mail_fail_reason_conf=RARequire("mail_fail_reason_conf")
	local failData=mail_fail_reason_conf[tonumber(id)]
	if not failData then
		failData=mail_fail_reason_conf[1]
	end 
	return failData
end
function RAMailUtility:getShowSystemTxt(noticeType,noticeSubType)
	local file=""
	if noticeType==Const_pb.COLLECT_NOTICE then

	elseif noticeType==Const_pb.COLLECT_NOTICE then

	elseif noticeType==Const_pb.CAMP_NOTICE then

	elseif noticeType==Const_pb.DETECT_NOTICE then

	elseif noticeType==Const_pb.KILL_MONSTER_NOTICE then

	elseif noticeType==Const_pb.ATTACK_PLAYER_NOTICE then

	elseif noticeType==Const_pb.ASSISTANCE_NOTICE then

	elseif noticeType==Const_pb.ASSISTANCE_RES_NOTICE then

	elseif noticeType==Const_pb.SPY_NOTICE then

	elseif noticeType==Const_pb.MASS_NOTICE then

	elseif noticeType==Const_pb.MASS_JOIN_NOTICE then

	end 

	local data=RARequire(file)
	local txt=_RALang(data[tonumber(noticeSubType)])
	return txt
end


--聊天内容是否显示时间
function RAMailUtility:isShowChatTime(firstTime,secondTime)
	local RAChatManager=RARequire("RAChatManager")
	local  baseTime=RAChatManager.chatTimeDiff
	local isShow=Utilitys.timeDiffBetweenTwo(firstTime,secondTime,baseTime)
	return isShow
end

--获取当前雷达建筑的等级
function RAMailUtility:getRadarLevel()
	local RABuildManager=RARequire("RABuildManager")
	local arr=RABuildManager:getBuildDataArray(Const_pb.RADAR)

	if next(arr) then
		local buildData=arr[1]
		return buildData:getLevel()
	end 
	return 0
end


--侦查邮件的数据处理

-- //防御建筑
-- message DefenceBuilding{
-- 	required sint32 id 	= 1;//建筑ID
-- 	required sint32 num	= 2;//建筑数目
-- }

-- //侦查邮件
-- message DetectMail{
-- 	required int32 result				= 1;	//结果，0：成功，1：失败
-- 	required MailPlayerInfo player		= 2;	//被侦查者玩家信息
-- 	repeated RewardItem canPlunderItem	= 3;	//可掠夺资源
-- 	optional int32 defenceArmyAboutNum	= 4;	//防守部队兵大致总数
-- 	optional int32 helpArmyAboutNum		= 5;	//援军士兵大致总数
-- 	repeated int32 defenceArmyIds		= 6;	//防守部队兵种组成
-- 	optional MailArmyInfo myArmy		= 7;	//部队
-- 	optional int32 defenceNum		    = 8;	//防御武器数目
-- 	repeated DefenceBuilding defenceBuildings	= 9;	//防御建筑组成
-- 	repeated MailArmyInfo helpArmy		= 10;	//援军
-- 	repeated EffectPB buff              = 11;	//玩家所获得的作用号数值总和（作用号 100~149 150~199）
-- }

-- //部队数据
-- message MailArmyInfo{
-- 	optional string playerName		= 1;	//玩家名称
-- 	optional sint32 level			= 2;	//等级
-- 	repeated ArmySoldierPB soldier	= 3;	//军队数据
-- 	optional int32 totalNum			= 4;	//部队总数
-- 	optional bool isAboutValue		= 5;	//精确值还是大概值
-- }

-- // 兵种信息 MarchArmy
-- message ArmySoldierPB
-- {
-- 	required int32 armyId	= 1;	// 兵种id
-- 	required int32 count	= 2;	// 兵的数量
-- }
function RAMailUtility:getScoutMailShowDefenceDatas(mailDatas)
	
	local info={}
	info.defenceArmyAboutNum=nil
	info.helpArmyAboutNum=nil
	-- info.defenceArmyIds=nil
	info.myArmy=nil
	info.defenceAboutNum=nil
	info.helpArmy=nil
	info.buff=nil
	info.isSoldierShowCount=true
	info.isAbout=true
	info.defenceSoldierMem=nil
	info.helpSoldierMem=nil
	info.defenceNum=nil   --防御武器数量
	info.defenceMem=nil   --防御武器组成
	--雷达2级
	if mailDatas:HasField('defenceArmyAboutNum') then
		info.defenceArmyAboutNum=mailDatas.defenceArmyAboutNum
	end 

	
	--雷达3级
	-- local defenceArmyIds=mailDatas.defenceArmyIds
	-- if #defenceArmyIds>0 then
	-- 	-- info.defenceArmyIds=defenceArmyIds
	-- 	info.defenceSoldierMem=defenceArmyIds
	-- 	info.isSoldierShowCount=false
	-- end 


	--防守部队数据
	if mailDatas:HasField('defenceArmy') then

		info.myArmy=mailDatas.defenceArmy
		local myArmyData=mailDatas.defenceArmy
		
		--雷达4级
		local soldierDatas=myArmyData.soldier
		local totalNum=0
		local count=#soldierDatas
		for i=1,count do
			local soldierData=soldierDatas[i]
			local num=soldierData.defencedCount
			
			totalNum=totalNum+num
		end

		if totalNum>0 then
			info.defenceSoldierMem=soldierDatas
			info.defenceArmyAboutNum=totalNum
		end 
		

		if myArmyData:HasField('isAboutValue') then
			info.isAbout=myArmyData.isAboutValue
		end 

		-- local buffDatas=mailDatas.buff
		-- if #buffDatas>0 then
		-- 	info.buff=buffDatas
		-- end 

	end 

	--防御武器
	if mailDatas:HasField('defenceNum') then
		info.defenceNum=mailDatas.defenceNum
	end

	local defenceBuildings=mailDatas.defenceBuildings
	if #defenceBuildings>0 then
		info.defenceMem=defenceBuildings
		local defenceTotalNum=0
		for i=1,#defenceBuildings do
			local defenceBuilding=defenceBuildings[i]
			local num=defenceBuilding.num
			defenceTotalNum=defenceTotalNum+num
		end
		info.defenceNum=defenceTotalNum
	end 

	return info


end


function RAMailUtility:getScoutMailShowHelpDatas(mailDatas)
	local info={}
	info.isAbout=nil
	info.armyDatas={}
	--援军数据
	local helpArmys=mailDatas.helpArmy
	local allSoldierTotalNum=0

	if mailDatas:HasField('helpArmyAboutNum') then
		allSoldierTotalNum=mailDatas.helpArmyAboutNum
		info.isAbout=true
	end

	if #helpArmys>0 then
		-- info.helpArmy=mailDatas.helpArmy
		for i=1,#helpArmys do
			local helpArmyData=helpArmys[i]

			local t={}
			t.buff=nil
			t.isAbout=true
			t.helpSoldierMem=nil
			t.soldierTotalNum=nil
		
			if helpArmyData:HasField('playerName') then 
				t.playerName=helpArmyData.playerName
			end 
			if helpArmyData:HasField('level') then 
				t.playerLevel=helpArmyData.level
			end

			if helpArmyData:HasField('icon') then 
				t.playerIcon=helpArmyData.icon
			end

			local soldierDatas=helpArmyData.soldier
			
			local count=#soldierDatas
			if count>0 then
				t.helpSoldierMem=soldierDatas
			end 
			local soldierTotalNum=0
			for j=1,count do
				local soldierData=soldierDatas[j]
				local num=soldierData.defencedCount
				soldierTotalNum=soldierTotalNum+num
				-- allSoldierTotalNum=allSoldierTotalNum+num
			end

			if helpArmyData:HasField('totalNum') then
				t.soldierTotalNum=helpArmyData.totalNum
			elseif soldierTotalNum>0 then
				t.soldierTotalNum=soldierTotalNum			
			end

			if not mailDatas:HasField('helpArmyAboutNum') then
				allSoldierTotalNum=allSoldierTotalNum+t.soldierTotalNum
			end 

			if helpArmyData:HasField('isAboutValue') then
				t.isAbout=helpArmyData.isAboutValue
				info.isAbout=helpArmyData.isAboutValue
		
			end

			table.insert(info.armyDatas,t)

		end

	end 	

	return info,allSoldierTotalNum
end


function RAMailUtility:getEffectDataById(id)
	local effectid_conf=RARequire("effectid_conf")
    local effectidConfigData=effectid_conf[tonumber(id)]
    if not effectidConfigData then
       effectidConfigData=effectid_conf[100]
    end 
    return effectidConfigData
end


-- 获得自己联盟的id
function RAMailUtility:getOwnAllianceId()
	local RAAllianceManager = RARequire('RAAllianceManager')
	local selfAlliance=RAAllianceManager.selfAlliance
	if selfAlliance then
		return selfAlliance.id
	end 
end

function RAMailUtility:getBuildData(id)
	return RABuildingUtility.getBuildInfoById(id)
end

--限制显示的长度  
function RAMailUtility:getLimitStr(str,limitNum)
	if not str then return "" end
	local len = GameMaths:calculateNumCharacters(str)
	if len>limitNum then
		local tmpStr =  GameMaths:getStringSubNumCharacters(str,0,limitNum)
		return tmpStr.."..."
	end
	return  str 
end

--聊天信件中判断是否要显示时间
function RAMailUtility:isCreatChatTime(lastMsgTime)
	if not lastMsgTime then return false end
	local RAChatManager=RARequire("RAChatManager")
	local nowTime=RA_Common:getCurTime()
	local RAMailConfig = RARequire("RAMailConfig")
	if not Utilitys.timeDiffBetweenTwo(nowTime,lastMsgTime,RAMailConfig.createTime) then
        return false
    end
   	return true
end


function RAMailUtility:getSupperData(id)
	local super_mine_conf = RARequire("super_mine_conf")
	return super_mine_conf[tonumber(id)]
end

function RAMailUtility:getNewMailData(configID)
	local mailsys_conf = RARequire("mailsys_conf")
	if not configID or not mailsys_conf[configID] then
		return mailsys_conf[2011011]
	end 
	return mailsys_conf[configID]
end


--     enum WorldPointType
-- {
-- 	EMPTY 			= 0;	// 空白点
-- 	RESOURCE 		= 1;	// 资源点
-- 	MONSTER 		= 2;	// 怪物点
-- 	PLAYER 			= 3;	// 玩家城堡
-- 	OCCUPIED		= 4;	// 被玩家城堡或者其他大建筑占用的四周点
-- 	QUARTERED		= 5;	// 驻扎的部队的点
-- 	GUILD_GUARD		= 6;	// 据点类型
-- 	GUILD_TERRITORY = 7;	// 联盟建筑
-- 	KING_PALACE		= 8;	// 国王宫殿
-- }

function RAMailUtility:getWorldPosNameType(pointType,subType)
	local name = ""
	local icon, level
	local World_pb = RARequire("World_pb")
	if pointType==World_pb.PLAYER then
		local RAWorldConfigManager = RARequire('RAWorldConfigManager')
		name = _RALang("@WorldArea007")
		icon = RAWorldConfigManager:GetCityIconByLevel(subType)
		level = tonumber(subType)
	elseif pointType==World_pb.QUARTERED then
		name = _RALang("@ArmyQuarteredTiltle")
		icon = "Favorites_Icon_Building_08.png"
	elseif pointType==World_pb.GUILD_GUARD then
		name = _RALang("@AllianceCastle")
	elseif pointType == World_pb.GUILD_TERRITORY then
		local RAAllianceManager = RARequire('RAAllianceManager')
		local manorInfo = RAAllianceManager:getManorDataById(id)
		name = manorInfo.confData.name
		icon = manorInfo.confData.icon
		level = manorInfo.confData.level
	elseif pointType==World_pb.RESOURCE then
		if subType then
			local RALogicUtil = RARequire("RALogicUtil")
			local resInfo = self:getWorldResDataById(subType)
			name = RALogicUtil:getResourceNameById(resInfo.resType)
			icon = resInfo.resTargetIcon
			level = resInfo.level
		end 
	end 
	return name, icon, level
end



--返回某特定id的兵种数量
function RAMailUtility:getSolderCount(solderInfo,soldierId)
	local count = #solderInfo
	soldierId = tonumber(soldierId)
	for i=1,count do
		local soldier = solderInfo[i]
		local id  = soldier.soldierId
		if soldierId==id then 
			local num = soldier.survivedCount+soldier.woundedCount+soldier.deadCount
			return num
		end
	end
	return 0
end

--返回某特定id的effect值
function RAMailUtility:getEffectValue(effectInfo,effectId)
	local count = #effectInfo
	effectId = tonumber(effectId)
	for i=1,count do
		local effect = effectInfo[i]
		local id  = effect.effId
		if effectId==id then 
			local num = effect.effVal
			return num
		end
	end
	return 0
end

function RAMailUtility:getFightResultDes(configId)

	local str = ""
	local result = ""
	local RAMailConfig = RARequire("RAMailConfig")
	if Utilitys.tableFind(RAMailConfig.FightResultID.AttackSuccess,configId) then
		str = _RALang("@FightSuccessInforTitle")
		result = RAMailConfig.FightResult.AttackSuccess
	elseif Utilitys.tableFind(RAMailConfig.FightResultID.DefendFail,configId) then
		str =  _RALang("@GuardFailInforTitle")
		result = RAMailConfig.FightResult.DefendFail
	elseif Utilitys.tableFind(RAMailConfig.FightResultID.AttackFail,configId) then
		str = _RALang("@FightFailInforTitle")
		result = RAMailConfig.FightResult.AttackFail
	elseif Utilitys.tableFind(RAMailConfig.FightResultID.DefendSuccess,configId) then
		str =  _RALang("@GuardSuccessInforTitle")
		result = RAMailConfig.FightResult.DefendSuccess
	end 
	return str,result
end



function RAMailUtility:getTargetPlayerName(playerData)
	if not playerData then return "" end
	local playerName = playerData.name
	if playerData:HasField("guildTag") then
		local guildTag = playerData.guildTag
		playerName = "("..guildTag..")"..playerName
	end 
	return playerName
end

--获得某种防御武器类型同等级的数目
function RAMailUtility:getWeaponNum(weaponDatas,level)
	local t={0,0,0}
	if weaponDatas==nil then return t end
	local Const_pb = RARequire("Const_pb")
	local defBuildType = {Const_pb.PRISM_TOWER,Const_pb.PATRIOT_MISSILE,Const_pb.PILLBOX}
	

	
	for i=1,#weaponDatas do
		local weaponData =weaponDatas[i] 
		local buildId = weaponData.id
		local buildData = RABuildingUtility.getBuildInfoById(buildId) 
		local buildType = buildData.buildType
		local buildLevel = buildData.level

		for j=1,#defBuildType do
			local defType = defBuildType[j]
			if buildType==defType and buildLevel==level then
				t[j]=weaponData.num
                break
            end 
		end

	end
	
	return t
end

--t{玩家信息,可掠夺资源，敌方部队，敌方援军，防御数量，属性加成}
function RAMailUtility:showDetectMailContent(configId,detectMail)
	local t={0,0,0,0,0,0}
	local RAMailConfig = RARequire("RAMailConfig")
	if configId==RAMailConfig.Page.InvestigateBase  then
		--侦查基地
		t = {1,1,1,1,1,0}
	elseif configId==RAMailConfig.Page.InvestigateResPos  then
		--侦查资源点
		 t={1,0,1,0,0,0}
	elseif configId==RAMailConfig.Page.InvestigateStationed  then
		--侦查驻扎点
		 t={1,0,1,0,0,0}
	elseif configId==RAMailConfig.Page.InvestigateCore  then
		--侦查首都
		 t={1,0,1,1,0,0}
	elseif configId==RAMailConfig.Page.InvestigateYouLiBase  then
		--侦查尤里基地
		 t={1,1,1,0,0,0}
	elseif configId==RAMailConfig.Page.InvestigateCastle then
		--侦查有归属/无归属联盟堡垒 
		t={1,0,1,1,0,0}
	elseif configId==RAMailConfig.Page.InvestigatePlatform then	
		t={1,0,1,1,0,0}
	end
	return t
end

--是否是侦查邮件
function RAMailUtility:isInvestMailPage(configId)
	if configId==nil or configId=="" or not tonumber(configId) then return end
	configId = tonumber(configId)

	local RAMailConfig = RARequire("RAMailConfig")
	if configId==RAMailConfig.Page.InvestigateBase or 
	   configId==RAMailConfig.Page.InvestigateResPos or 
	   configId==RAMailConfig.Page.InvestigateStationed or 
	   configId==RAMailConfig.Page.InvestigateYouLiBase or
	   configId==RAMailConfig.Page.InvestigateCastle or
	   configId==RAMailConfig.Page.InvestigateCore 
	then
		return true
	end 

	return false
end

function RAMailUtility:getOfficailsName(configId)
	if configId==nil then return "" end 
	local official_position_conf = RARequire("official_position_conf")
	local info = official_position_conf[tonumber(configId)]
	local officeName = _RALang(info.officeName)
	return officeName
end
-- t.playerId = memberData.playerId
-- 		t.name = memberData.name
function RAMailUtility:sortChatRoomMemData(info)
	local selfInfo={}
	local tb={}
	for k,v in ipairs(info) do
		if not v.isDelete then
			local playerName = v.name
			local isMine =RAMailUtility:isMineByName(playerName)
			if isMine then
				selfInfo = v
			end
			table.insert(tb,v)	
		end 
	end
	return tb,selfInfo
end

function RAMailUtility:getDefenseWeaponNum(armyInfo)
	local count=#armyInfo
	local result=0
	local battle_soldier_conf=RARequire("battle_soldier_conf")
	local Const_pb=RARequire("Const_pb")
	for i=1,count do
		local army=armyInfo[i]
		local soldiers=army.soldier
		local num=#soldiers
		for j=1,num do
			local soldier=soldiers[j]
			local id=tonumber(soldier.soldierId)
			local configData=battle_soldier_conf[id]
			if 	configData.type==Const_pb.PILLBOX_WEAPON or
				configData.type==Const_pb.PRISM_TOWER_WEAPON or 
				configData.type==Const_pb.PATRIOT_MISSILE_WEAPON
			then
				result=result+1
			end	
		end
	end
	return result
end

--保留n为小数,暂时不考虑四舍五入
--n为小数点后n位
function RAMailUtility:getDotNumBy(str,n)
	str=tostring(str)
	if not string.find(str,".") then
		return ""
	end 

	local dotIndex=string.find(str,".")

	local result=string.sub(str,1,dotIndex+n+1)

	return result
end
return RAMailUtility