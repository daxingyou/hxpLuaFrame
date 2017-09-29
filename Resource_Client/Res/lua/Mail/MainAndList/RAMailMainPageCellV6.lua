--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UIExtend = RARequire("UIExtend")
local RAStringUtil = RARequire("RAStringUtil")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local RAMailManager=RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RALogicUtil=RARequire("RALogicUtil")
local  RAMailConfig = RARequire("RAMailConfig")
RARequire("MessageManager")
RARequire("MessageDefine")
RARequire('MailConst_pb')

local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local selectedMailMsg =MessageDefine_Mail.MSG_Selected_Mail
local deleteMailMsg =MessageDefine_Mail.MSG_Delete_Mail
local clickOptMailMsg =MessageDefine_Mail.MSG_Click_OptMail
local refreshMailOptListMsg =MessageDefine_Mail.MSG_Refresh_MailOptList


--MailCell
--------------------------------------------------------------
RAMailMainCellV6 = {

}
function RAMailMainCellV6:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailMainCellV6:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAMailMainCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    local mailInfo = RAMailManager:getMailById(self.id)
    self.mailInfo = mailInfo


    --是否编辑
    self.canEdit = mailInfo.canEdit
    UIExtend.setNodeVisible(self.ccbfile,"mSelectNode",self.canEdit)
    if self.canEdit then
    	self:runAnimation("EditAni")
    else
    	self:runAnimation("NormalAni")
    end


    --是否选中
    self.isSelected = mailInfo.selected
    UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",self.isSelected)
    self.isYesPic=self.isSelected
    
    --lock 1:锁定 0:未锁定
    self.lock = mailInfo.lock
    if mailInfo.lock==1 then
    	UIExtend.setNodeVisible(ccbfile,"mLockPic",true)
    else
    	UIExtend.setNodeVisible(ccbfile,"mLockPic",false)
    end 


	--time	
	local mailTime = math.floor(mailInfo.ctime/1000)
	UIExtend.setCCLabelString(ccbfile,"mMailTimeLabel",RAMailUtility:formatMailTime(mailTime))
	 
	--is have reward
	self.hasReward = mailInfo.hasReward
	UIExtend.setNodeVisible(self.ccbfile,"mGiftNode",self.hasReward)
	

	--is have read  1:已读 0:未读
	self.statu = mailInfo.status
	local isRead = false
	if self.statu==1  then
		isRead = true
	end
	UIExtend.setNodeVisible(ccbfile,"mReadNode",isRead)
	UIExtend.setNodeVisible(ccbfile,"mUnreadNode",not isRead)
	UIExtend.setNodeVisible(ccbfile,"mNewNode",not isRead)

	--title and subTitle
	self.configId = mailInfo.configId
	self:showMailDeltal()

	--icon
	self:showIcon()


end
function RAMailMainCellV6:showSelectNode(isShow)
    self.canEdit = isShow
	RAMailManager:updataEditMailDatas(self.id,isShow)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectNode",isShow)
end
function RAMailMainCellV6:showIcon()

	local iconNode= UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode")
	local bigIconNode= UIExtend.getCCNodeFromCCB(self.ccbfile,"mBigIconNode")
	iconNode:removeAllChildrenWithCleanup(true)
	bigIconNode:removeAllChildrenWithCleanup(true)
	local configData = RAMailUtility:getNewMailData(self.configId)
	--先从配置表里读，否则从服务器传来的IconId
	local picNode =nil
	local mailType = RAMailManager:getMailTypeByConfigId(self.configId)
	if mailType~=RAMailConfig.Type.PRIVATE then 
		picNode = bigIconNode
	else
		picNode = iconNode
	end 
	if configData.mailIcon then	
		UIExtend.addNodeToAdaptParentNode(picNode,configData.mailIcon,RAMailConfig.TAG)
	else
		--（玩家头像或联盟旗帜,怪物ID）
		local icons = self.mailInfo.icon
		
		local iconId = icons[1]
		local iconName=nil
		if mailType==RAMailConfig.Type.PRIVATE then
		    --暂时只用一个，以后有多人聊天用前4个
			iconName = RAMailUtility:getPlayerIcon(iconId)
		elseif mailType==RAMailConfig.Type.ALLIANCE then
			local RAAllianceUtility = RARequire('RAAllianceUtility')
			iconName=RAAllianceUtility:getAllianceFlagIdByIcon(iconId)
		elseif mailType==RAMailConfig.Type.MONSTERYOULI then
			iconName=RAMailUtility:getMonsterIconById(iconId)
		end 
		UIExtend.addNodeToAdaptParentNode(picNode,iconName,RAMailConfig.TAG)
	end 
	
end
function RAMailMainCellV6:showMailDeltal()
	

	local configData = RAMailUtility:getNewMailData(self.configId)
	if configData then
		
		--title
		local paramsTitle = self.mailInfo.title 
		local titlekeyStr = configData.mainTitle
		local titleStr = nil
		if paramsTitle  then
			local params=RAStringUtil:split(paramsTitle, "_")
			titleStr = _RALangFill(titlekeyStr,params[1],params[2],params[3],params[4],params[5]) 
		else
			titleStr = _RALang(titlekeyStr)
		end

		--subTitle
		local paramsSubTitle = self.mailInfo.subTitle 
		local subTitlekeyStr = configData.subTitile
		local subTitleStr = nil
		if paramsSubTitle  then
			local params=RAStringUtil:split(paramsSubTitle, "_")

			if self.configId==2011111 then
				--联盟等级变更
				--0未改(等级) 1已改
				local t1=RAStringUtil:split(params[1], ":")
				if t1[1]=="0" then
					local key= 'L' .. t1[2] .. 'Name' 
					params[1]= _RALang('@Default' .. key)
				else
					params[1]= t1[2]
				end 


			elseif self.configId==2011121 then
				--富资源点变更
				local super_mine_conf = RARequire("super_mine_conf")
				local info = super_mine_conf[tonumber(params[1])]
				params[1]= _RALang(info.name)
			
			elseif self.configId==2013041 then  
				--超值礼包购买成功
				params[1] = _RALang(params[1])
			elseif self.configId==2013061 then
				--活动积分目标奖励
				local event_conf = RARequire("event_conf")
				local info = event_conf[tonumber(params[1])]
				params[1] = _RALang(info.eventName)
			elseif self.configId==2013062 then
				--活动阶段排名奖励
				local event_conf = RARequire("event_conf")
				local info = event_conf[tonumber(params[1])]
				params[1] = _RALang(info.eventName)
			elseif self.configId==2013063 then
				--活动总排名奖励
				local event_conf = RARequire("event_conf")
				local info = event_conf[tonumber(params[1])]
				params[1] = _RALang(info.eventName)
			elseif self.configId==2013141 then
				--来自大总统表扬
				params[1] = _RALang(params[1])
			elseif self.configId==2013151 then
				--官员任命
		
				params[2] = RAMailUtility:getOfficailsName(params[2])
			elseif self.configId==2013152 then
				--官员任命更改
				params[2] = RAMailUtility:getOfficailsName(params[2])
				params[3] = RAMailUtility:getOfficailsName(params[3])
			elseif  self.configId==2011044 or  self.configId==2011045 then
				--联盟堡垒占领中 被占领中
				local guild_const_conf = RARequire("guild_const_conf")
				local time = guild_const_conf["guildManorOccupyTime"].value/3600
				params[2]=time

			end 

			subTitleStr = _RALangFill(subTitlekeyStr,params[1],params[2],params[3],params[4],params[5]) 
		else
			subTitleStr = _RALang(subTitlekeyStr)
		end
		

		if self.configId ==RAMailConfig.Page.Prviate then
			titleStr = self.mailInfo.title 
			subTitleStr = self.mailInfo.subTitle 
		end
		local titelLimitLen = 30 
		local subTitleLimitLen = 40
		if self.hasReward then
			subTitleLimitLen=30
		end 
		UIExtend.setCCLabelString(self.ccbfile,"mMailTitle",RAMailUtility:getLimitStr(titleStr,titelLimitLen))
		UIExtend.setCCLabelString(self.ccbfile,"mMailContentLabel",RAMailUtility:getLimitStr(subTitleStr,subTitleLimitLen))
	end
end



--点击cell回调 进入阅读界面
function RAMailMainCellV6:onCellCheckBtn()
	
	--私人信件：
	--[[
		私聊，群聊
	]]

	--联盟邮件:
	--[[
	 资源援助，部队援助
	 { 
	   集结解散，集结失败,激活堡垒已变更，超级矿种类变更，核武器攻击投票，闪电风暴攻击投票，核武器攻击确认，闪电风暴攻击确认，核武器攻击取消，闪电风暴攻击取消
	   联盟堡垒攻占成功,联盟堡垒失守,成功夺回联盟堡垒，未能守住联盟堡垒，已同意加入联盟，入盟申请被拒绝，
	   逐出联盟，联盟阶级变更,基地迁移邀请，红包未开启，红包无人开启,红包被开启，你是幸运儿
	 }
	 摧毁尤里基地,
	 核弹命中，闪电风暴命中
	]]


	--战斗邮件：
	--[[
		你已强制撤离(跟联盟统一模板)，
		侦查基地成功，
		{
			遭到侦查，阻止敌人侦查，敌人侦查失败,
			基地侦查失败,资源点侦查失败，尤里基地侦查失败，驻扎点侦查失败
		}
		联盟堡垒侦查成功，
		遭受核武器攻击，
		遭受闪电风暴攻击，
		战斗成功（跟攻击基地一套模板），
		战斗失败(跟联盟统一模板)，
		伤兵死亡

	]]

	--系统消息：
	--[[
		(跟联盟统一模板)
		{
			系统更新，系统通知，补偿奖励，人民币消费，迁城，活动奖励(积分目标，阶段排名，总排名),
			指挥官被拷打，指挥官被解救，指挥官被解救，指挥官基地回到基地，指挥官处决倒数，国王战，
			总统礼包，官员任命，征税
		}
	]]

	--尤里战斗：
	--[[
		战斗报告
	]]

	--如果处于可编辑状态就不进入二级界面
	if self.canEdit  then 
		local str = _RALang("@MailEditTips")
		RARootManager.ShowMsgBox(str)
		return 
	end 

	local mailType = RAMailManager:getMailTypeByConfigId(self.configId)
	if mailType==0 then return end

	if mailType==RAMailConfig.Type.PRIVATE then 							
		-- 私人信件
		RARootManager.OpenPage("RAMailPrivateChatPage",{id=self.id})
	elseif mailType==RAMailConfig.Type.ALLIANCE then

		if self.configId>=RAMailConfig.Page.ResAid[1] and self.configId<=RAMailConfig.Page.ResAid[2] then
			--资源援助
			RARootManager.OpenPage("RAMailGatherPage",{id=self.id})
		elseif self.configId>=RAMailConfig.Page.SoldierAid[1] and self.configId<=RAMailConfig.Page.SoldierAid[2] then
			--士兵援助
			RARootManager.OpenPage("RAMailGatherPage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.DestroyYouLiBase then
			--摧毁尤里基地
			RARootManager.OpenPage("RAMailAllianceDestroyYouLiBasePage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.NubormExplode then
			-- 核弹爆炸
			RARootManager.OpenPage("RAMailAllianceSuperHitPage",{id=self.id,isNuClearBom=true})
		elseif self.configId==RAMailConfig.Page.LighningStorm then
			-- 闪电风暴
			RARootManager.OpenPage("RAMailAllianceSuperHitPage",{id=self.id,isNuClearBom=false})
		else
			RARootManager.OpenPage("RAMailAllianceCommonPage",{id=self.id})
		end 
	elseif mailType==RAMailConfig.Type.FIGHT then

		if self.configId==RAMailConfig.Page.Evacuation then
			--强制撤离
			RARootManager.OpenPage("RAMailEvacuationPage",{id=self.id})

		elseif self.configId==RAMailConfig.Page.LighningStormHurt then
			--遭受闪电风暴攻击
			RARootManager.OpenPage("RAMailLightingStormPage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.InvestigateBase then
			--侦查基地成功，
			RARootManager.OpenPage("RAMailInvestigateBasePage",{id=self.id})
		elseif  self.configId==RAMailConfig.Page.InvestigateResPos 
				or self.configId==RAMailConfig.Page.InvestigateStationed
				or self.configId==RAMailConfig.Page.InvestigateYouLiBase
		 then
		 	-- 侦查资源点/驻扎点/尤里基地成功
		 	RARootManager.OpenPage("RAMailInvestigateBasePage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.InvestigateCastle
			   or self.configId==RAMailConfig.Page.InvestigateCore
			then
			-- 侦查堡垒/王座成功
			RARootManager.OpenPage("RAMailInvestigateBasePage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.InvestigatePlatform then
			-- 侦查发射平台成功
			RARootManager.OpenPage("RAMailInvestigateBasePage",{id=self.id})
		elseif (self.configId>=RAMailConfig.Page.FightBaseSuccess[1] and self.configId<=RAMailConfig.Page.FightBaseSuccess[2])
			   or (self.configId>=RAMailConfig.Page.FightResPosSuccess[1] and self.configId<=RAMailConfig.Page.FightResPosSuccess[2])
			   or (self.configId>=RAMailConfig.Page.FightStationedSuccess[1] and self.configId<=RAMailConfig.Page.FightStationedSuccess[2])
			   or (self.configId>=RAMailConfig.Page.FightYouLiBaseSuccess[1] and self.configId<=RAMailConfig.Page.FightYouLiBaseSuccess[2])
			   or (self.configId>=RAMailConfig.Page.FightCastleSuccess[1] and self.configId<=RAMailConfig.Page.FightCastleSuccess[2])
			   or  self.configId==RAMailConfig.Page.FightCastleSuccess1
			   or (self.configId>=RAMailConfig.Page.FightCoreSuccess[1] and self.configId<=RAMailConfig.Page.FightCoreSuccess[2])
			   or (self.configId>=RAMailConfig.Page.FightPlatformSuccess1[1] and self.configId<=RAMailConfig.Page.FightPlatformSuccess1[2])
			   or (self.configId>=RAMailConfig.Page.FightPlatformSuccess2[1] and self.configId<=RAMailConfig.Page.FightPlatformSuccess2[2])
			   or self.configId==RAMailConfig.Page.InvestigatePlatform
			   
			then
			-- 攻击成功
			RARootManager.OpenPage("RAMailPlayerFightSuccessPage",{id=self.id})
		elseif (self.configId>=RAMailConfig.Page.FightBaseFail[1] and self.configId<=RAMailConfig.Page.FightBaseFail[2])
			   or (self.configId>=RAMailConfig.Page.FightResPosFail[1] and self.configId<=RAMailConfig.Page.FightResPosFail[2])
			   or self.configId==RAMailConfig.Page.FightStationedFail
			   or self.configId==RAMailConfig.Page.FightYouLiBaseFail
			   or self.configId==RAMailConfig.Page.FightCastleFail 
			   or self.configId==RAMailConfig.Page.FightCoreFail
			   or self.configId==RAMailConfig.Page.FightPlatformFail 
			then
			--攻击失败
			RARootManager.OpenPage("RAMailPlayerFightFailPage",{id=self.id})
		elseif self.configId==RAMailConfig.Page.WoundSolder then
			--伤兵治疗
			RARootManager.OpenPage("RAMailWoundSolderPage",{id=self.id})
		elseif self.configId==MailConst_pb.NBOMB_HURT then
			--核弹损失
			RARootManager.OpenPage("RAMailNuclearLostPage",{id=self.id})			
		else
			--侦查失败 / 被侦查
			RARootManager.OpenPage("RAMailFightCommonPage",{id=self.id})
		end 

	elseif mailType==RAMailConfig.Type.SYSTEM then
		-- 系统通知
		RARootManager.OpenPage("RAMailSystemCommonPage",{id=self.id})
	elseif mailType==RAMailConfig.Type.MONSTERYOULI then
		-- 尤里战报
		RARootManager.OpenPage("RAMailMonsterYouLiPage",{id=self.id})
	end 

end

function RAMailMainCellV6:runAnimation(name)
	if self.ccbfile then
		self.ccbfile:runAnimation(name)
	end 
end
function RAMailMainCellV6:setLock(isLock)
	self.lock = isLock
	local isShow = false
	if isLock==1 then
		isShow = true
	end 
	RAMailManager:updataLockMailDatas(self.id,isLock)
    UIExtend.setNodeVisible(self.ccbfile,"mLockPic",isShow)
end
--邮件是否锁住
function RAMailMainCellV6:getLock()
	local mailInfo = RAMailManager:getMailById(self.id)
	self.lock = mailInfo.lock
	return self.lock
end

--判断邮件里是否有奖励
function RAMailMainCellV6:isHaveReward()
	local mailInfo = RAMailManager:getMailById(self.id)
	self.hasReward = mailInfo.hasReward
	return self.hasReward
end

--返回邮件的状态 已读1 未读0 0也表示新邮件
function RAMailMainCellV6:getMailStatu()
	local mailInfo = RAMailManager:getMailById(self.id)
	self.statu= mailInfo.status
	return self.statu
end

--设置邮件的状态
function RAMailMainCellV6:setMailStatu(statu)
	self.statu=statu
end
--返回邮件ID
function RAMailMainCellV6:getMailId()
	return self.id
end

function RAMailMainCellV6:onCellSelectBtn()
	if not self.isYesPic then
		self.isYesPic = true
		self.isSelected = true
	else
		self.isYesPic=false
		self.isSelected = false
	end
	RAMailManager:updataSelectMailDatas(self.id,self.isSelected)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",self.isYesPic)
	MessageManager.sendMessage(selectedMailMsg) 
end

function RAMailMainCellV6:getIsSelected()
	local mailInfo = RAMailManager:getMailById(self.id)
	self.isSelected =mailInfo.selected
	return self.isSelected
end

function RAMailMainCellV6:setIsSelected(isVisible)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectYesPic",isVisible)
	self.isSelected = isVisible
	self.isYesPic = isVisible
	RAMailManager:updataSelectMailDatas(self.id,self.isSelected)
end





