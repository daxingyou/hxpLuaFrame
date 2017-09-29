
--资源采集邮件界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire("Const_pb")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAResManager = RARequire("RAResManager")
local html_zh_cn = RARequire('html_zh_cn')
local RAMailConfig = RARequire('RAMailConfig')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local TAG=1000

local RAMailMonsterYouLiPage = BaseFunctionPage:new(...)

--
--RAMailMonsterYouLiPageCellNode
-------------------------------------------------------------------------
local RAMailMonsterYouLiPageCellNode = {

}
function RAMailMonsterYouLiPageCellNode:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailMonsterYouLiPageCellNode:load()
	local ccbi = UIExtend.loadCCBFile("RAMailMonsterReportCellNodeV6.ccbi", self)
    return ccbi
end

function  RAMailMonsterYouLiPageCellNode:getCCBFile()
	return self.ccbfile
end

function RAMailMonsterYouLiPageCellNode:updateInfo()
	local ccbfile = self:getCCBFile()

	UIExtend.setCCLabelString(ccbfile,"mCellNum",self.count)

	--根据id判断是道具还是资源
 	local icon, name, item_color =RAResManager:getIconByTypeAndId(self.type, self.id)

 	UIExtend.setCCLabelString(ccbfile,"mCellLabel", _RALang(name))
	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	local bgName  = RALogicUtil:getItemBgByColor(item_color)
	UIExtend.addNodeToAdaptParentNode(picNode,bgName, 20000)
	UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)

end
-------------------------------------------------------------------------
--RAMailMonsterYouLiPageCell
-------------------------------------------------------------------------
local RAMailMonsterYouLiPageCell = {

}
function RAMailMonsterYouLiPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end



function RAMailMonsterYouLiPageCell:onRefreshContent(ccbRoot)

	CCLuaLog("RAMailMonsterYouLiPageCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local monsterBattleInfo = self.info
    print("self.configId = ",self.configId)
    local resultStr = ""
    local rewardStr = ""
    local monstData = RAMailUtility:getMonsterDataById(monsterBattleInfo.monsterId)
    local name  = _RALang("@MonsterLevelName",monstData.level , _RALang(monstData.name) )  

    if self.configId == RAMailConfig.Page.FightYouLiMonstSucc then
    	resultStr = _RALang("@MonsterFightSucc")
    	rewardStr = _RALang("@MonsterFightReward")
    elseif self.configId == RAMailConfig.Page.FightYouLiMonstFail then
    	resultStr = _RALang("@MonsterFightFail")
    elseif self.configId == RAMailConfig.Page.FightYouLiMonstLast then
    	resultStr = _RALang("@MonsterFightFirstBlood")
    	rewardStr = _RALang("@MonsterFightLastReward")
	elseif self.configId == RAMailConfig.Page.FightYouLiMonstMiss then
		resultStr = _RALang("@MonsterFightFail")
		name = _RALang("@MonsterFightMiss")
    end

    UIExtend.setCCLabelString(ccbfile,"mCellTitle",resultStr)
    --时间
    local fightT = math.floor(self.fightTime/1000)
    local fightTStr=RAMailUtility:formatMailTime(fightT)
    UIExtend.setCCLabelString(ccbfile,"mTime",fightTStr)
    local world_march_const = RARequire("world_march_const_conf")
    local atkEnemyCost = world_march_const.atkEnemyCostVitPoint.value
    local contributionRate = RAMarchDataManager:GetContributionPerVit()
    local scoreRate = RAMarchDataManager:GetScorePerVit()

    UIExtend.setCCLabelString(ccbfile,"mCellLabel",name)

    if self.configId == RAMailConfig.Page.FightYouLiMonstMiss then
    	UIExtend.setCCLabelString(ccbfile,"mUseUp1","")
    	UIExtend.setCCLabelString(ccbfile,"mUseUp2","")
    	UIExtend.setCCLabelString(ccbfile,"mUseUp3","")
    else
	    UIExtend.setCCLabelString(ccbfile,"mUseUp1",_RALang("@atkEnemyCost", atkEnemyCost))

	    UIExtend.setCCLabelString(ccbfile,"mUseUp2",_RALang("@energyToContribution", atkEnemyCost * contributionRate))

	    UIExtend.setCCLabelString(ccbfile,"mUseUp3",_RALang("@energyToScore", atkEnemyCost * scoreRate))
	end
    
    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mPosLabel")
    htmlLabel:setString(_RAHtmlFill("@location",monsterBattleInfo.x,monsterBattleInfo.y))
	local RAChatManager = RARequire("RAChatManager")
	htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)

	local btn = UIExtend.getCCControlButtonFromCCB(ccbfile,"mDataStatisticsBtn")
	btn:setVisible(self.configId ~= RAMailConfig.Page.FightYouLiMonstMiss)

    --战斗结果
    local result = monsterBattleInfo.result -- 1成功 2失败
    if result ~= 2 then
    	UIExtend.setCCLabelString(ccbfile,"mCellDetailsTitle",rewardStr)
    	local additionalNode = UIExtend.getCCNodeFromCCB(ccbfile,"mAdditionalNode")
    	additionalNode:removeAllChildren()
		local rewards = monsterBattleInfo.rewards
		local cellH = 0
		for i=1,#rewards do
			local reward = rewards[i]
			local itemId = reward.itemId
			local itemType = reward.itemType
			local itemCount = reward.itemCount

			local rewardCCB = RAMailMonsterYouLiPageCellNode:new({
				count = itemCount,
				id = itemId,
				type=itemType,
			})
			local ccbi = rewardCCB:load()
			rewardCCB:updateInfo()
			additionalNode:addChild(ccbi)
			cellH = ccbi:getContentSize().height
			ccbi:setPositionY(cellH - i*cellH) 
		end

		local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBG")
		local contentSize = mBg:getContentSize()
		mBg:setContentSize(CCSize(contentSize.width,192 + cellH* #rewards - cellH))
		btn:setPositionY(- cellH* #rewards + cellH)
    end 

end


function RAMailMonsterYouLiPageCell:onDataStatisticsBtn()
	print("onDataStatisticsBtn")
	RARootManager.OpenPage("RAMailMonsterYouLiDataPage", self.info, false , true, true)
end
-------------------------------------------------------------------------
local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailData = message.mailDatas
      local id=mailData.id

      --存储一份阅读数据
      RAMailManager:addMonsterBattleMailCheckDatas(id,mailData)
      RAMailMonsterYouLiPage:updateInfo(mailData)
    end
end

function RAMailMonsterYouLiPage:Enter(data)


	CCLuaLog("RAMailSystemPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailMonsterReportPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	self.id = data.id
	print("self.id = ",self.id)
 	self:registerMessageHandler()
    self:init()
    
end
function RAMailMonsterYouLiPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailMonsterYouLiPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
 
end

function RAMailMonsterYouLiPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailMonsterYouLiPage:init()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	titleCCB:runAnimation("InAni")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@YouLiFightReprot"))
	-- UIExtend.setNodeVisible(titleCCB,"mHomeBackNode",true)
	self.mReportListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mReportListSV")

	local mailInfo = RAMailManager:getMailById(self.id) 
	self.mailInfo = mailInfo

	self.status = mailInfo.status

	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailData = RAMailManager:getMonsterBattleMailCheckDatas(self.id)
		self:updateInfo(mailData)
	end 
end

function RAMailMonsterYouLiPage:updateInfo(mailInfo)

	self.mReportListSV:removeAllCell()
	local scrollview = self.mReportListSV

	local mailTime=RAMailManager:getMailTime(mailInfo.id)
	local monsterData =mailInfo.monsterMail

    if monsterData==nil then 
    	self:refreshStatu(mailInfo)
    	assert(monsterData~= nil ,"mailInfo.monsterMail ~= nil")
    	return 
    end

	local cell = CCBFileCell:create()

	local result=monsterData.result
	if result~=2 then
		cell:setCCBFile("RAMailMonsterReportCell1V6.ccbi")
	else
		cell:setCCBFile("RAMailMonsterReportCell2V6.ccbi")
	end 
	
	local panel = RAMailMonsterYouLiPageCell:new({
			fightTime = mailTime,
			configId = self.mailInfo.configId,
			info = monsterData,
    })
	cell:registerFunctionHandler(panel)
	scrollview:addCell(cell)
	scrollview:orderCCBFileCells()

 	if scrollview:getContentSize().height < scrollview:getViewSize().height then
		scrollview:setTouchEnabled(false)
	else
		scrollview:setTouchEnabled(true)
    end 

   self:refreshStatu(mailInfo)
	
end

function RAMailMonsterYouLiPage:refreshStatu(mailInfo)
  if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailInfo.id,false)
end
function RAMailMonsterYouLiPage:Exit()
	self:removeMessageHandler()
	self.isFrstRead = nil 
	self.mailInfo = nil
	UIExtend.unLoadCCBFile(RAMailMonsterYouLiPage)
	
end

function RAMailMonsterYouLiPage:onClose()
	RARootManager.CloseCurrPage()
end


function RAMailMonsterYouLiPage:mCommonTitleCCB_onBack()
	CCLuaLog("RAMailResourceCollectPage:mCommonTitleCCB_onBack")
	self:onClose()
	-- MessageManager.sendMessage(reportMailBack)
end