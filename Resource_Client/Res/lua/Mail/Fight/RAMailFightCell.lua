
-- 战斗邮件：战斗成功
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local RAGameConfig = RARequire("RAGameConfig")


RAMailPlayerFightCell = {}
function RAMailPlayerFightCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

local questionStr="???"
-- //战斗邮件
-- message FightMail{
-- 	optional int32 result					= 1;	//战斗结果，1：成功，2：失败
-- 	optional MailPlayerInfo myPlayerInfo	= 2;	//我方玩家信息
-- 	optional MailPlayerInfo oppPlayerInfo	= 3;	//对方玩家信息
-- 	repeated RewardItem items				= 4;	//成功奖励或失败损失
-- 	required FighteInfo myFight				= 5;	//我方战斗数据
-- 	required FighteInfo oppFight			= 6;	//对方战斗数据
-- 	repeated MailArmyInfo myArmy			= 7;	//我方军队数据
-- 	repeated MailArmyInfo oppArmy			= 8;	//对方军队数据
-- 	required int32 x						= 9;	//战争地点X
-- 	required int32 y						= 10;	//战争地点Y
-- 	repeated EffectPB myEffect              = 11;	//我方科技加成（100-199）
-- 	repeated EffectPB oppEffect             = 12;	//对方科技加成（100-199）
-- 	optional GuardInfo guardInfo			= 13;	//据点信息
-- 	optional CannonInfo defCannon			= 14; 	//防守方巨炮信息
-- 	repeated DefBuildEffect	defBuildEff		= 15;	//防御武器伤害
-- }
 
 function RAMailPlayerFightCell:resetLableAndBtnShow(ccbfile)
 	UIExtend.setNodeVisible(ccbfile,"mLeftDefBuildAtkTitle",true)
	UIExtend.setNodeVisible(ccbfile,"mLeftDefBuildAtk",true)
	UIExtend.setNodeVisible(ccbfile,"mRightDefBuildAtkTitle",true)
	UIExtend.setNodeVisible(ccbfile,"mRightDefBuildAtk",true)
	UIExtend.setCCControlButtonEnable(ccbfile,"mDataStatisticsBtn",true)
	UIExtend.setCCLabelString(ccbfile,"mBattleResult",_RALang("@BattleResult"))
 end
function RAMailPlayerFightCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data

    --result 
    local isSuccess=nil
    local str,result = RAMailUtility:getFightResultDes(self.configId)
    if result==RAMailConfig.FightResult.AttackSuccess 
    	or result==RAMailConfig.FightResult.DefendSuccess then
    	isSuccess = true
    	UIExtend.setCCLabelString(ccbfile,"mWinTitle",str)
    else
    	isSuccess = false
    	UIExtend.setCCLabelString(ccbfile,"mLoseTitle",str)
    end 
    UIExtend.setNodeVisible(ccbfile,"mWinTitle",isSuccess)
	UIExtend.setNodeVisible(ccbfile,"mLoseTitle",not isSuccess)

	if result==RAMailConfig.FightResult.AttackSuccess or result==RAMailConfig.FightResult.AttackFail
		then
		UIExtend.setCCLabelString(ccbfile,"mAttackTitle",_RALang("@AttackName"))
		UIExtend.setCCLabelString(ccbfile,"mDefendTitle",_RALang("@Defend"))
	else
		UIExtend.setCCLabelString(ccbfile,"mAttackTitle",_RALang("@Defend"))
		UIExtend.setCCLabelString(ccbfile,"mDefendTitle",_RALang("@AttackName"))
	end
	--time
	local time = self.time
	time=RAMailUtility:formatMailTime(time)
	UIExtend.setCCLabelString(ccbfile,"mTime",time)


	--targetName
	local oppPlayerInfo = data.oppPlayerInfo
	local targetName=""
	if self.configId==2012111 or self.configId==2012112 then
		--攻击尤里基地
		local iconId = oppPlayerInfo.icon
		local RAWorldConfigManager = RARequire("RAWorldConfigManager")
		local info = RAWorldConfigManager:GetStrongholdCfg(iconId)
		targetName = _RALang(info.armyName)
	elseif self.configId==2012127  then
		--攻击中立的联盟堡垒
		local territory_building_conf = RARequire("territory_building_conf")
		local info = territory_building_conf[100]
		targetName = _RALang(info.name)
	-- elseif self.configId==2012191 or self.configId==2012192 or self.configId==2012194 or self.configId==2012195 then
	-- 	--攻击发射平台
	-- 	local iconId = oppPlayerInfo.icon
	-- 	local territory_building_conf = RARequire("territory_building_conf")
	-- 	local info = territory_building_conf[tonumber(iconId)]
	-- 	targetName = _RALang(info.name)
	else
		targetName = RAMailUtility:getTargetPlayerName(oppPlayerInfo)
	end
	
	-- local targetName = RAMailUtility:getTargetPlayerName(oppPlayerInfo)

	local targetKey = ""
	if result==RAMailConfig.FightResult.AttackSuccess 
		or result==RAMailConfig.FightResult.AttackFail then
			targetKey = "AttackTarget"
	else
			targetKey = "DefendTarget"
	end 
	local targetHtmlStr = _RAHtmlLang(targetKey,targetName)
	UIExtend.setCCLabelHTMLString(ccbfile,"mAtkName",targetHtmlStr)

	--targetPos
	local x = data.x
	local y = data.y
	local targetPosHtmlStr = _RAHtmlLang("TargetPos",x,y)
	UIExtend.setCCLabelHTMLString(ccbfile,"mAtkPos",targetPosHtmlStr)

	local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mAtkPos")
	self.htmlLabel = htmlLabel
	local RAChatManager = RARequire("RAChatManager")
	htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)

	--rob resource
	local resources = data.items
	self:refreshResData(result,resources)

	--防御武器总个数
	self.defWeaponNum=0

	--参与战斗的防御武器个数
	self.defWeaponFightNum=0
	if result==RAMailConfig.FightResult.AttackSuccess then
		self.defWeaponNum=RAMailUtility:getDefenseWeaponNum(data.oppArmy)
		self.defWeaponFightNum=#data.defBuildEff
	end 
	
	
	--battle result
	self:refrehBattleDatas(data.myPlayerInfo,data.myFight,false,result)
	self:refrehBattleDatas(data.oppPlayerInfo,data.oppFight,true,result)
	

	--kill count
	local leftKillNum = data.oppFight.deadSoldier
	local rightKillNum = data.myFight.deadSoldier
	leftKillNum = Utilitys.formatNumber(leftKillNum)
	rightKillNum = Utilitys.formatNumber(rightKillNum)


	--如果攻击胜利后，防守方死伤小于10% 所有部队显示为？？？，战斗详情按钮不可点击
	self:resetLableAndBtnShow(ccbfile)
	if result==RAMailConfig.FightResult.AttackSuccess or result==RAMailConfig.FightResult.AttackFail then
		if not self.isFightYouLiBase and  data.oppFight.totalSoldier-self.defWeaponNum>0 and (data.oppFight.deadSoldier+data.oppFight.hurtSoldier-self.defWeaponFightNum)/(data.oppFight.totalSoldier-self.defWeaponNum)<0.1 then
			rightKillNum=questionStr
			UIExtend.setCCControlButtonEnable(ccbfile,"mDataStatisticsBtn",false)
			UIExtend.setCCLabelString(ccbfile,"mBattleResult",_RALang("@BattleResult").."  ".._RALang("@BattleMailLostLessTips"))
		end

		--隐藏防御
		UIExtend.setNodeVisible(ccbfile,"mLeftDefBuildAtkTitle",false)
		UIExtend.setNodeVisible(ccbfile,"mLeftDefBuildAtk",false)
	else
		--隐藏防御
		UIExtend.setNodeVisible(ccbfile,"mRightDefBuildAtkTitle",false)
		UIExtend.setNodeVisible(ccbfile,"mRightDefBuildAtk",false)
	end 

	UIExtend.setCCLabelString(ccbfile,"mLeftKilledNum",leftKillNum)
	UIExtend.setCCLabelString(ccbfile,"mRightKilledNum",rightKillNum)


end
function RAMailPlayerFightCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.htmlLabel then
		self.htmlLabel:removeLuaClickListener()
		self.htmlLabel = nil
	end  	
end

function RAMailPlayerFightCell:refreshResData(result,resInfo)
	local isShowRes = nil
	local showTips = nil
	local isAdd = true
	local color = nil
	if result==RAMailConfig.FightResult.AttackSuccess then
		isShowRes = true
		isAdd = true
		color = RAGameConfig.COLOR.GREEN
	elseif result==RAMailConfig.FightResult.DefendFail  then
		isShowRes = true
		isAdd = false
		color = RAGameConfig.COLOR.RED
	elseif result==RAMailConfig.FightResult.AttackFail  then
		isShowRes = false
		showTips=_RALang("@AttackFailTips")

		--攻击有归属联盟堡垒失败 2012125
		if self.configId == 2012125 then
			showTips=_RALang("@AttackFailTips1")
		end 

	elseif result==RAMailConfig.FightResult.DefendSuccess  then
		isShowRes = false
		showTips=_RALang("@DefendSuccessTips")

		

	end

	UIExtend.setNodeVisible(self.ccbfile,"mResNode",isShowRes)
	UIExtend.setNodeVisible(self.ccbfile,"mNoResLabel",not isShowRes)
	if showTips then
		UIExtend.setCCLabelString(self.ccbfile,"mNoResLabel",showTips)
		UIExtend.setNodeVisible(self.ccbfile,"mNoResLabel",true)
	else
		UIExtend.setNodeVisible(self.ccbfile,"mNoResLabel",false)
	end

	if not isShowRes then return end

	--refesh single res
	local count = #resInfo
	--尤里基地 联盟堡垒没有可掠夺资源
	if count==0 then
		local Const_pb = RARequire('Const_pb')
		resInfo={
			{itemId =Const_pb.GOLDORE,itemCount=0},
			{itemId =Const_pb.OIL,itemCount=0},
			{itemId =Const_pb.STEEL,itemCount=0},
			{itemId =Const_pb.TOMBARTHITE,itemCount=0},
		}
		count = 4
	end 
	count=math.min(count,4)
	for i=1,count do
		local res = resInfo[i]
		local resId = res.itemId
		local resCount = res.itemCount
		resCount = Utilitys.formatNumber(resCount)
		if resCount~=0 then
			if isAdd then
				resCount = "+"..resCount
			else
				resCount = "-"..resCount
			end 
		end 
		
		local resIcon = RALogicUtil:getResourceIconById(resId)
		local resName = RALogicUtil:getResourceNameById(resId)

		local resPicNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode"..i)
    	UIExtend.addNodeToAdaptParentNode(resPicNode,resIcon,RAMailConfig.TAG)

    	UIExtend.setCCLabelString(self.ccbfile,"mCellLabel"..i,resName)
    	UIExtend.setCCLabelString(self.ccbfile,"mCellNum"..i,resCount)
    	UIExtend.setLabelTTFColor(self.ccbfile,"mCellNum"..i,color)
	end
end


function RAMailPlayerFightCell:isOpenResource(resId)

	local Const_pb=RARequire("Const_pb")
	if resId==Const_pb.GOLDORE or resId==Const_pb.OIL then
		return true
	end 
	local  world_map_const_conf = RARequire("world_map_const_conf")
	local RABuildManager=RARequire("RABuildManager")
    local cityLevel = RABuildManager:getMainCityLvl()
    local stepCityLevel2=world_map_const_conf["stepCityLevel2"]
    local arr=RAStringUtil:split(stepCityLevel2.value,"_") 
    local steelLimitLevel = tonumber(arr[1])
	local rareEarthsLevel = tonumber(arr[2])

    if cityLevel>=steelLimitLevel then
		return true
	end 

	if cityLevel>=rareEarthsLevel then
		return true
	end  

	return false

end
	-- 


-- 攻击 尤里基地 -==-》尤里

-- 联盟堡垒==》中立：联盟堡垒/玩家：玩家头像
-- 首都 =》有玩家：玩家
function RAMailPlayerFightCell:getTargetIconAndName(playerInfo)
	
	local icon=""
	local name = ""
	local iconId = playerInfo.icon
	self.isFightYouLiBase=false
	if self.configId==2012111 or self.configId==2012112 then
		--攻击尤里基地
		local RAWorldConfigManager = RARequire("RAWorldConfigManager")
		local info = RAWorldConfigManager:GetStrongholdCfg(iconId)
		icon = info.icon
		name = _RALang(info.armyName)
		self.isFightYouLiBase=true
		self.targetName = name
	elseif self.configId==2012127  then
		--攻击中立的联盟堡垒
		local territory_building_conf = RARequire("territory_building_conf")
		local info = territory_building_conf[100]
		icon=info.icon
		name = _RALang(info.name)
	-- elseif self.configId==2012191 or self.configId==2012192 or self.configId==2012194 or self.configId==2012195 then
	-- 	--攻击发射平台
	-- 	local territory_building_conf = RARequire("territory_building_conf")
	-- 	local info = territory_building_conf[tonumber(iconId)]
	-- 	name = _RALang(info.name)
	-- 	icon=info.icon
		self.targetName = name
	else
		icon = RAMailUtility:getPlayerIcon(iconId)
		name= RAMailUtility:getTargetPlayerName(playerInfo)
	end
	
	return icon,name
end

--攻击尤里基地还未考虑  TODO
function RAMailPlayerFightCell:refrehBattleDatas(playerInfo,fightInfo,isRight,result)
	

	local baseStr = "Left"
	if isRight then
		baseStr = "Right"
	end 

	--player datas
	local iconId = playerInfo.icon


	local icon=nil
	local playerName=""
	if isRight then
		icon,playerName= self:getTargetIconAndName(playerInfo)
		self.targetIcon = icon
	else
		local iconId = playerInfo.icon
		icon = RAMailUtility:getPlayerIcon(iconId)
		playerName= RAMailUtility:getTargetPlayerName(playerInfo)
		self.ownIcon = icon
	end 

	
	local picNodeName = "m"..baseStr.."IconNode"
	if icon then
		local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,picNodeName)
    	UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
	end 


    local nameStr = "m"..baseStr.."PlayerName"
    UIExtend.setCCLabelString(self.ccbfile,nameStr,playerName)

    local disBattlePoint = playerInfo.disBattlePoint
    disBattlePoint= "-"..Utilitys.formatNumber(disBattlePoint)
   

	--commonder statu
	local commanderState=playerInfo.commanderState
	local prisonStr="m"..baseStr.."CapturedNode"
	local commanderStateTips="m"..baseStr.."CapturedLabel"
	local isShowPrison = false
	local showTitle=""
	if commanderState then
		if commanderState==1 then
			--被自己俘虏
			isShowPrison = true
			showTitle=_RALang("@BeTakenPrisoner")
		elseif commanderState==2 then
			--被其他人俘虏
			isShowPrison = true
			showTitle=_RALang("@BeOtherTakenPrisoner")
		end 
	end 
	UIExtend.setCCLabelString(self.ccbfile,commanderStateTips,showTitle)
	UIExtend.setNodeVisible(self.ccbfile,prisonStr,isShowPrison)


	-- refresh battle data
	local str1 = "m"..baseStr.."TotalNum"
	local str2 = "m"..baseStr.."DeadNum"
	local str3 = "m"..baseStr.."HurtNum"
	local str4 = "m"..baseStr.."SurvivalNum"
	local str5 = "m"..baseStr.."DefBuildAtk"


	local totalSoldier 		= fightInfo.totalSoldier
	local deadSoldier 		= fightInfo.deadSoldier
	local hurtSoldier 		= fightInfo.hurtSoldier
	local survivalSoldier 	= fightInfo.survivalSoldier
	local defBuildWound 	= fightInfo.defBuildWound

	totalSoldier 			= Utilitys.formatNumber(totalSoldier)
	deadSoldier 			= Utilitys.formatNumber(deadSoldier)
	hurtSoldier 			= Utilitys.formatNumber(hurtSoldier)
	survivalSoldier 		= Utilitys.formatNumber(survivalSoldier)
	defBuildWound 			= Utilitys.formatNumber(defBuildWound)

	-- --如果防守方死伤小于10% 所有部队显示为？？？，战斗详情按钮不可点击
	if  result==RAMailConfig.FightResult.AttackSuccess or result==RAMailConfig.FightResult.AttackFail then
		if isRight and  not self.isFightYouLiBase and fightInfo.totalSoldier-self.defWeaponNum>0 and (fightInfo.deadSoldier+fightInfo.hurtSoldier-self.defWeaponFightNum)/(fightInfo.totalSoldier-self.defWeaponNum)<0.1 then
			totalSoldier=questionStr
			deadSoldier=questionStr
			hurtSoldier=questionStr
			survivalSoldier=questionStr
			defBuildWound=questionStr
			disBattlePoint=questionStr
		end 
	end  


	UIExtend.setCCLabelString(self.ccbfile,str1,totalSoldier)
	UIExtend.setCCLabelString(self.ccbfile,str2,deadSoldier)
	UIExtend.setCCLabelString(self.ccbfile,str3,hurtSoldier)
	UIExtend.setCCLabelString(self.ccbfile,str4,survivalSoldier)
	UIExtend.setCCLabelString(self.ccbfile,str5,defBuildWound)

	local disBattlePointStr=_RAHtmlLang("GeneralFightValue", disBattlePoint)

	UIExtend.setCCLabelHTMLString(self.ccbfile,"m"..baseStr.."FightValue",disBattlePointStr,200)

end

function RAMailPlayerFightCell:onDataStatisticsBtn()
	local params={}
	params.info=self.data
	params.targetIcon = self.targetIcon
	params.ownIcon =self.ownIcon
	params.configId = self.configId
	params.targetName = self.targetName 
	RARootManager.OpenPage("RAMailFightStatisticPopUp",params,true,true,true)
end

--popup 界面
------------------------------------------------------------------------------------------
RAMailFightPopupTitleCell = {}
function RAMailFightPopupTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupTitleCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    if self.effect then
    	UIExtend.setNodeVisible(ccbfile,"mLeftNode",false)
    	UIExtend.setNodeVisible(ccbfile,"mRightNode",false)

    	local titleStr = self.titleStr
    	UIExtend.setCCLabelString(ccbfile,"mPlayerName",titleStr)

    	return 
    end 
	local ownIcon = self.ownIcon
	local targetIcon = self.targetIcon
	local titleStr = self.titleStr

	local picNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode1,ownIcon,RAMailConfig.TAG)

    local picNode2 = UIExtend.getCCNodeFromCCB(ccbfile,"mRightCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode2,targetIcon,RAMailConfig.TAG)

    UIExtend.setCCLabelString(ccbfile,"mPlayerName",titleStr)
    
end

function RAMailFightPopupTitleCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.setNodeVisible(ccbfile,"mLeftNode",true)
    UIExtend.setNodeVisible(ccbfile,"mRightNode",true)
end

------------------------------------------------------------------------------------------
RAMailFightPopupSolderCell = {}
function RAMailFightPopupSolderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupSolderCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data

    local solderId = self.id
    local myTotal = data.myTotal
    local oppTotal = data.oppTotal

    local solderConfig = RAMailUtility:getBattleSoldierDataById(solderId)
    local level = solderConfig.level
    local icon = solderConfig.icon  
    if self.configId==RAMailConfig.Page.FightYouLiBaseSuccess[1] or 
    	self.configId==RAMailConfig.Page.FightYouLiBaseSuccess[2] then
    	icon = solderConfig.yuriIcon
    end 

    UIExtend.setCCLabelString(ccbfile,"mLeftNum",myTotal)
    UIExtend.setCCLabelString(ccbfile,"mRightNum",oppTotal)

    UIExtend.setCCLabelString(ccbfile,"mLeftLevel",_RALang("@ResCollectTargetLevel",level))
    UIExtend.setCCLabelString(ccbfile,"mRightLevel",_RALang("@ResCollectTargetLevel",level))

    local picNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    local picNode2 = UIExtend.getCCNodeFromCCB(ccbfile,"mRightCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode1,icon,RAMailConfig.TAG)
    UIExtend.addNodeToAdaptParentNode(picNode2,icon,RAMailConfig.TAG)

end

------------------------------------------------------------------------------------------
RAMailFightPopupPlayerCell = {}
function RAMailFightPopupPlayerCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupPlayerCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

	UIExtend.setNodeVisible(ccbfile,"mRedNode",self.attack) 
	UIExtend.setNodeVisible(ccbfile,"mBlueNode",not self.attack) 

    local data = self.data
    local playData= data.player
    local fightData = data.fight
    local statu = data.statu
    local killSolder = data.killSolder

    --icon name  statu
    local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    local icon = data.icon
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

    local name = ""
    --考虑到尤里基地和中立的联盟堡垒
    if self.targetName then
    	name = self.targetName
    else
    	name = RAMailUtility:getTargetPlayerName(playData)
    end 
    UIExtend.setCCLabelString(ccbfile,"mPlayerName",name)

    UIExtend.setCCLabelString(ccbfile,"mState",statu)

    --refresh fight data
    self:refeshFightDatas(playData,fightData,killSolder)

end

function RAMailFightPopupPlayerCell:refeshFightDatas(playData,fightData,killSolder)
	
	local lossFight 		= playData.disBattlePoint
	local totalSoldier 		= fightData.totalSoldier
	local deadSoldier 		= fightData.deadSoldier
	local hurtSoldier 		= fightData.hurtSoldier
	local survivalSoldier 	= fightData.survivalSoldier
	-- local defBuildWound 	= fightData.defBuildWound

	lossFight 				= Utilitys.formatNumber(lossFight)
	totalSoldier 			= Utilitys.formatNumber(totalSoldier)
	deadSoldier 			= Utilitys.formatNumber(deadSoldier)
	hurtSoldier 			= Utilitys.formatNumber(hurtSoldier)
	survivalSoldier 		= Utilitys.formatNumber(survivalSoldier)
	killSolder 				= Utilitys.formatNumber(killSolder)

	UIExtend.setCCLabelString(self.ccbfile,"mTotalSoldierNum",totalSoldier)
	UIExtend.setCCLabelString(self.ccbfile,"mLossFightValue",lossFight)
	UIExtend.setCCLabelString(self.ccbfile,"mSurvivalNum",survivalSoldier)
	UIExtend.setCCLabelString(self.ccbfile,"mKilledNum",killSolder)
	UIExtend.setCCLabelString(self.ccbfile,"mHurtNum",hurtSoldier)
	UIExtend.setCCLabelString(self.ccbfile,"mDeadNum",deadSoldier)

end

------------------------------------------------------------------------------------------
RAMailFightPopupSolderDetailCell = {}
function RAMailFightPopupSolderDetailCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailFightPopupSolderDetailCell:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAMailFightPopupSolderDetailCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local data=self.data

	local soldierId=data.soldierId
	local icon=RAMailUtility:getBattleSoldierIconById(soldierId)
	local picNode=UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

	local survivedCount=data.survivedCount
	local deadCount=data.deadCount
	local killCount=data.killCount
	local woundedCount=data.woundedCount

	survivedCount=Utilitys.formatNumber(survivedCount)
	deadCount=Utilitys.formatNumber(deadCount)
	killCount=Utilitys.formatNumber(killCount)
	woundedCount=Utilitys.formatNumber(woundedCount)

	UIExtend.setCCLabelString(ccbfile,"mSurvivalNum",survivedCount)
	UIExtend.setCCLabelString(ccbfile,"mDeadNum",deadCount)
	UIExtend.setCCLabelString(ccbfile,"mKilledNum",killCount)
	UIExtend.setCCLabelString(ccbfile,"mHurtNum",woundedCount)


end
------------------------------------------------------------------------------------------
RAMailFightPopupDefendDetailCell = {}
function RAMailFightPopupDefendDetailCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupDefendDetailCell:resert( )
	local ccbfile = self.ccbfile
	if self.cannon then
		for i=2,4 do
    		UIExtend.setNodeVisible(ccbfile,"mTitle"..i,true)
    	end
    	UIExtend.setNodeVisible(ccbfile,"mDeadNum",true)
    	UIExtend.setNodeVisible(ccbfile,"mKilledNum",true)
    	UIExtend.setNodeVisible(ccbfile,"mHurtNum",true)
    	UIExtend.setCCLabelString(ccbfile,"mTitle1",_RALang("@SurSoldier"))
    elseif self.defWeapon then
    	UIExtend.setNodeVisible(ccbfile,"mTitle4",true)
    	UIExtend.setNodeVisible(ccbfile,"mDeadNum",true)
    	UIExtend.setCCLabelString(ccbfile,"mTitle3",_RALang('@HurtSoldier'))
	end 
	-- body
end
function RAMailFightPopupDefendDetailCell:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAMailFightPopupDefendDetailCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local data=self.data

    if self.cannon then
    	local RAWorldConfigManager = RARequire("RAWorldConfigManager")
    	local RAWorldConfig  =RARequire("RAWorldConfig")
    	local Const_pb = RARequire("Const_pb")
    	local id = RAWorldConfig.TerritoryBuildingId[Const_pb.GUILD_CANNON]
    	local info = RAWorldConfigManager:GetTerritoryBuildingCfg(id)

    	local icon = info.icon
    	--巨炮的配置表 todo..
    	-- local icon=RAMailUtility:getBattleSoldierIconById(iconId)
    	local picNode=UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    	UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

    	for i=2,4 do
    		UIExtend.setNodeVisible(ccbfile,"mTitle"..i,false)
    	end
    	UIExtend.setNodeVisible(ccbfile,"mDeadNum",false)
    	UIExtend.setNodeVisible(ccbfile,"mKilledNum",false)
    	UIExtend.setNodeVisible(ccbfile,"mHurtNum",false)

    	UIExtend.setCCLabelString(ccbfile,"mTitle1",_RALang("@KillSoldier"))

    	local killCount = data
    	killCount=Utilitys.formatNumber(killCount)
    	UIExtend.setCCLabelString(ccbfile,"mSurvivalNum",killCount)
    	
    elseif self.defWeapon then
    	UIExtend.setNodeVisible(ccbfile,"mTitle4",false)
    	UIExtend.setNodeVisible(ccbfile,"mDeadNum",false)
    	UIExtend.setCCLabelString(ccbfile,"mTitle3",_RALang('@Damage'))

    	local buildingId = data.buildingId
    	local RABuildingUtility = RARequire("RABuildingUtility")
    	local buildInfo = RABuildingUtility.getBuildInfoById(buildingId) 
    	local icon=buildInfo.buildArtImg
    	local picNode=UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    	UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

    	local survivedCount=data.survivedCount
		local deadCount=data.deadCount
		local killCount=data.killCount
		survivedCount=Utilitys.formatNumber(survivedCount)
		deadCount=Utilitys.formatNumber(deadCount)
		killCount=Utilitys.formatNumber(killCount)

		UIExtend.setCCLabelString(ccbfile,"mSurvivalNum",survivedCount)
		UIExtend.setCCLabelString(ccbfile,"mDeadNum",deadCount)
		UIExtend.setCCLabelString(ccbfile,"mKilledNum",killCount)


    end 
end

function RAMailFightPopupDefendDetailCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self:resert() 	
end

------------------------------------------------------------------------------------------
RAMailFightPopupEffectCell = {}
function RAMailFightPopupEffectCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailFightPopupEffectCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local data=self.data
    local myValue = data.myValue
	local oppValue = data.oppValue

	local effectId= self.id
	local effectValue=data.effVal
	local key="@EffectNum"..effectId
	local effectData=RAMailUtility:getEffectDataById(effectId)
	local effectType=effectData.type  --1是百分数 0是数值
	local name=_RALang(key)
	local value=""
	if effectType==1 then
		myValue=_RALang("@VIPAttrValueAdditionPercent",myValue/100)
		oppValue=_RALang("@VIPAttrValueAdditionPercent",oppValue/100)
	elseif effectType==0 then
		myValue=_RALang("@VIPAttrValueAdditionNoSymble",myValue)
		oppValue=_RALang("@VIPAttrValueAdditionNoSymble",oppValue)
	end 

	UIExtend.setCCLabelString(ccbfile,"mCellTitle",name)
	UIExtend.setCCLabelString(ccbfile,"mLeftNum",myValue)
	UIExtend.setCCLabelString(ccbfile,"mRightNum",oppValue)
	-- UIExtend.setLabelTTFColor(ccbfile,"mRightNum",RAGameConfig.COLOR.GREEN)
end
