RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RAFightDefine')
local UIExtend = RARequire('UIExtend')
local battle_ui_test_conf = RARequire('battle_ui_test_conf')
local RAFightManager = RARequire('RAFightManager')

local pageVar =
{
	-- 开始拖动技能
	mStartCasting 		= false,
	-- 开始选择释放目标点
	mIsDeploying 		= false,
	mCastSkillIndex 	= nil,
	mSkillSprite 		= nil,
	mEnableCastSkill 	= true,

	-- 显示技能点
	mSkillPointLabels 	= nil,
	-- 显示技能cd
	mBattleCDLabel 		= nil,
	-- 顶部按钮CCB
	mTopBtnCCB 			= nil,
	-- 顶部按钮是否是展开状态
	mIsTopBtnOpen		= false,
	mBloodBarTxtLabel 	= nil,

	mSkillCost 			= {},
	mSelectedSkillBtn 	= nil
}
local RAFightUI = BaseFunctionPage:new(..., pageVar)

local Max_Depart_OffsetY = 0 --80
local Max_Scale_Reduce = 0.9
local BtnIndex2SkillId =
{
	[3] = BattleSkillId.ONE_MISSILE,
	[2] = BattleSkillId.MULTI_MISSILE,
	[1] = BattleSkillId.TEAM_TREAT
}

function RAFightUI:Enter()
	self.mRootNode = UIExtend.loadCCBFileWithOutPool("RABattlePage.ccbi", self)
	self:initUI()
	self:registerMessage()
end

function RAFightUI:setVisible(isVisible)
	self.mRootNode:setVisible(isVisible)
end

function RAFightUI:initUI()
    self.mTopBtnCCB = UIExtend.getCCBFileFromCCB(self.mRootNode, 'mCellNodeCCB')

	UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'LeftVip'):setString(_RALang(battle_ui_test_conf.leftVip))
	UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'RightVip'):setString(_RALang(battle_ui_test_conf.rightVip))
	self.leftInfo = {}
	self.leftInfo.vipLevelTTF = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLeftVIPLevel')
	self.leftInfo.playerNameTTF = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLeftName')
	self.leftInfo.bloodBar = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mLeftBlueBar')
	self.leftInfo.numInfo = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLeftNum')
	-- self.leftInfo.bloodBar:setScaleX(0.5)
	self.rightInfo = {}
	self.rightInfo.vipLevelTTF = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mRightVIPLevel')
	self.rightInfo.playerNameTTF = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mRightName')
	self.rightInfo.bloodBar = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mRightRedBar')
	self.rightInfo.numInfo = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mRightNum')
	-- self.rightInfo.bloodBar:setScaleX(0.7)

	self.leftInfo.vipLevelTTF:setString(battle_ui_test_conf.leftVIPLevel)
	self.rightInfo.vipLevelTTF:setString(battle_ui_test_conf.rightVIPLevel)
	self.leftInfo.playerNameTTF:setString(battle_ui_test_conf.leftName)
	self.rightInfo.playerNameTTF:setString(battle_ui_test_conf.rightName)

	UIExtend.getCCNodeFromCCB(self.ccbfile,'mLeftBarBlueNode'):setVisible(true)
	UIExtend.getCCNodeFromCCB(self.ccbfile,'mLeftBarRedNode'):setVisible(false)

	UIExtend.getCCNodeFromCCB(self.ccbfile,'mRightBarBlueNode'):setVisible(false)
	UIExtend.getCCNodeFromCCB(self.ccbfile,'mRightBarRedNode'):setVisible(true)

	self.scaleImageArr = {}
	for i=1,4 do
		self.scaleImageArr[i] = UIExtend.getCCSpriteFromCCB(self.mTopBtnCCB,'mSpeedUpIcon' .. i)
	end


	local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
	local iconStr = RAPlayerInfoManager.getHeadIcon(11)
    self.leftPlayerIcon=UIExtend.addSpriteToNodeParent(self.mRootNode, "mLeftHeadNode", iconStr)

    local iconStr = RAPlayerInfoManager.getHeadIcon(12)
    self.rightPlayerIcon=UIExtend.addSpriteToNodeParent(self.mRootNode, "mRightHeadNode", iconStr)

    self.mSkillPointLabels = 
    {
    	(UIExtend.getCCLabelBMFontFromCCB(self.mRootNode, 'mSkillPoint1')),
    	(UIExtend.getCCLabelBMFontFromCCB(self.mRootNode, 'mSkillPoint2'))
    }
    if self.mBattleCDLabel == nil then
    	self.mBattleCDLabel = UIExtend.getCCLabelTTFFromCCB(self.mRootNode, 'mTime')
    end

    self.mBloodBarTxtLabel = UIExtend.getCCLabelTTFFromCCB(self.mTopBtnCCB, 'mHpBarTxt')
    self:_showBloodBarTxt()

    self:_initSkillCost()
end

function RAFightUI:init()
	self:setScaleImage(1)
	self.curScaleIndex = 1
	self:updateBar()
	self:_updateSkillPoint()
	self:_enableCastSkill(false)
	self:_updateSkipBtn()
	self:_showTopButtons(true)
	self:_addCD()
end

function RAFightUI:_showBloodBarTxt()
	local RABattleSceneManager = RARequire('RABattleSceneManager')
	local isVisible = RABattleSceneManager:getIsBloodBarVisible()
	local txtKey = isVisible and '@HideBloodBar' or '@ShowBloodBar'
	self.mBloodBarTxtLabel:setString(_RALang(txtKey))
end

function RAFightUI:_initSkillCost()
	local battle_player_skill_conf = RARequire('battle_player_skill_conf')
	self.mSkillCost = {}
	for k, skillId in pairs(BtnIndex2SkillId) do
		local cfg = battle_player_skill_conf[skillId] or {}
		local cost = cfg.costPoint or 1
		self.mSkillCost[skillId] = cost

		UIExtend.setCCLabelBMFontString(self.mRootNode, 'mSkillNum' .. k, cost)
	end
end

function RAFightUI:_showTopButtons(isOpen)
	if self.mIsTopBtnOpen == isOpen then return end
	self.mTopBtnCCB:runAnimation(isOpen and 'InAni' or 'OutAni')
	self.mIsTopBtnOpen = isOpen
end

-- currentSpeedScale = 1
function RAFightUI:updateBar()
	local attackerAliveCount = RAFightManager:getAliveCount(ATTACKER)
	local attackerCount = RAFightManager:getCount(ATTACKER)
	local defenderAliveCount = RAFightManager:getAliveCount(DEFENDER)
	local defenderCount = RAFightManager:getCount(DEFENDER)


	self:setBarValue(ATTACKER,attackerAliveCount,attackerCount)
	self:setBarValue(DEFENDER,defenderAliveCount,defenderCount)
end

function RAFightUI:setBarValue(armyType,value,totalValue)
	if armyType == ATTACKER then 
		self.leftInfo.numInfo:setString(value .. '/' .. totalValue)
		self.leftInfo.bloodBar:setScaleX(value/totalValue)
	else
		self.rightInfo.numInfo:setString(value .. '/' .. totalValue)
		self.rightInfo.bloodBar:setScaleX(value/totalValue)
	end
end

function RAFightUI:_updateSkipBtn()
    local enableToSkip = RAFightManager:getIsReplay() or not RAFightManager:getIsPVEBattle()
    UIExtend.setMenuItemEnable(self.mTopBtnCCB, 'mSkipBtn', enableToSkip)
end

local OnReceiveMessage = function(message)
	local self = RAFightUI
    if message.messageID == MessageDef_BattleScene.MSG_Update_Fight_BloodBar then
    	self:updateBar()
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_Depart then
    	self:_updateSkillSprite(message.offset)
    elseif message.messageID == MessageDef_BattleScene.MSG_CastSkill_Quit 
    	or message.messageID == MessageDef_BattleScene.MSG_CastSkill_TakeEffect
    then
    	self:_restoreSkillSprite()
    elseif message.messageID == MessageDef_BattleScene.MSG_FightPlay_State_Change then
    	local enable = (not RAFightManager:getIsReplay()) and message.state == FIGHT_PLAY_STATE_TYPE.START_BATTLE
    	self:_enableCastSkill(enable)
    elseif message.messageID == MessageDef_BattleScene.MSG_SkillPoint_Change then
    	self:_updateSkillPoint()
    end
end 

function RAFightUI:_updateSkillSprite(offset)
	local offsetY = math.max(offset.y, 0)
	if offsetY > Max_Depart_OffsetY then
		if not self.mIsDeploying then
			-- 超出skill sprite显示范围
			MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Deploy)
			-- self.mSkillSprite:setVisible(false)
			self.mIsDeploying = true
		end
	else
		if self.mSkillSprite then
			self.mSkillSprite:setPosition(offset.x, offsetY)
			local scale = 1 - (offsetY / Max_Depart_OffsetY) * Max_Scale_Reduce
			self.mSkillSprite:setScale(scale)
			self.mSkillSprite:setVisible(true)
		end
		if self.mIsDeploying then
			-- 正在往skill button内回拖
			MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_CancelDeploy)
			self.mIsDeploying = false
		end
	end
end

function RAFightUI:_restoreSkillSprite()
	if self.mSkillSprite then
		self.mSkillSprite:setPosition(0, 0)
		self.mSkillSprite:setScale(1)
		self.mSkillSprite:setVisible(true)
		self.mSkillSprite = nil
	end
	if self.mSelectedSkillBtn then
		self.mSelectedSkillBtn:setSelected(false)
		self.mSelectedSkillBtn:setHighlighted(false)
		UIExtend.setNodeVisible(self.mRootNode, 'mSkillLightSpr' .. self.mCastSkillIndex, false)
		self.mSelectedSkillBtn = nil
	end		
	self.mCastSkillIndex = nil
end

function RAFightUI:_enableCastSkill(enable, forceUpdate)
	if self.mEnableCastSkill == enable and not forceUpdate then return end
	if enable then
		if not RAFightManager:getIsPVEBattle() then return end
		
		local RAGuideManager = RARequire('RAGuideManager')
		if RAGuideManager.isInGuide() then return end
	end

	self.mEnableCastSkill = enable
	local totalPoint = enable and RAFightManager:getSkillPoint() or 0
	local RAFU_Cfg_CastSkill = RARequire('RAFU_Cfg_CastSkill')
	for k, skillId in pairs(BtnIndex2SkillId) do
		local cfg = RAFU_Cfg_CastSkill[skillId]
		local isCurrSkillEnabled = enable and self.mSkillCost[skillId] <= totalPoint
		UIExtend.setCCControlButtonEnable(self.mRootNode, 'mSkillBtn' .. k, isCurrSkillEnabled)
		local img = isCurrSkillEnabled and cfg.normalIcon or cfg.grayIcon
		UIExtend.addSpriteToNodeParent(self.mRootNode, 'mSkillIconNode' .. k, img)
	end
end

function RAFightUI:_updateSkillPoint()
	if self.mSkillPointLabels then
		for _, label in ipairs(self.mSkillPointLabels) do
			label:setString(_RALang('@SkillPoint') .. ': ' .. RAFightManager:getSkillPoint())
		end
		if self.mEnableCastSkill then
			self:_enableCastSkill(true, true)
		end
	end
end

function RAFightUI:_addCD()
	if not self.mBattleCDLabel then return end

	local battlePeriod = RAFightManager:getBattlePeriod()
	self.mBattleCDLabel:stopAllActions()
	
	local _format = function(second)
		return string.format('%02d:%02d', (second / 60) % 60, second % 60)
	end

	local cdLabel = self.mBattleCDLabel
	local _render = function()
		cdLabel:setString(_format(battlePeriod))
		if battlePeriod < 1 then
			cdLabel:stopAllActions()
		else
			battlePeriod = battlePeriod - 1
		end
	end
	_render()
	schedule(self.mBattleCDLabel, _render, 1.0)
end

function RAFightUI:onSkillBtn1(sender)
	self:_onSkillBtn(sender, 1)
end

function RAFightUI:onSkillBtn2(sender)
	self:_onSkillBtn(sender, 2)
end

function RAFightUI:onSkillBtn3(sender)
	self:_onSkillBtn(sender, 3)
end

function RAFightUI:_onSkillBtn(sender, index)
	local event = sender:getControlBtnEvent()
	if event == CCControlEventTouchDragOutside then
		-- self.mSkillSprite = UIExtend.getCCSpriteFromCCB(self.ccbfile, 'mSkillImage' .. index)
		-- local skillId = BtnIndex2SkillId[index]
		-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Start, {skillId = skillId})
		-- self.mStartCasting = true
		-- self.mCastSkillIndex = index
		return
	elseif event == CCControlEventTouchUpOutside then --and self.mStartCasting then
		-- self.mStartCasting = false
		-- self.mCastSkillIndex = nil 
	elseif event == CCControlEventTouchUpInside then --and self.mStartCasting then
		-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Quit)
		-- self.mStartCasting = false
		-- self.mCastSkillIndex = nil 

		if self.mCastSkillIndex and self.mCastSkillIndex == index then
			MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Quit)
			if self.mSelectedSkillBtn then
				self.mSelectedSkillBtn:setSelected(false)
				self.mSelectedSkillBtn:setHighlighted(false)
				UIExtend.setNodeVisible(self.mRootNode, 'mSkillLightSpr' .. self.mCastSkillIndex, false)
				self.mSelectedSkillBtn = nil
			end
			self.mCastSkillIndex = nil
		else
			if self.mCastSkillIndex then
				if self.mSelectedSkillBtn then
					self.mSelectedSkillBtn:setSelected(false)
					self.mSelectedSkillBtn:setHighlighted(false)
					UIExtend.setNodeVisible(self.mRootNode, 'mSkillLightSpr' .. self.mCastSkillIndex, false)
					self.mSelectedSkillBtn = nil
				end
			end
			local skillId = BtnIndex2SkillId[index]
			MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_CastSkill_Start, {skillId = skillId})
			self.mCastSkillIndex = index
			self.mSelectedSkillBtn = self.mRootNode:getCCControlButtonFromCCB('mSkillBtn' .. index)
			self.mSelectedSkillBtn:setSelected(true)
			self.mSelectedSkillBtn:setHighlighted(true)
			UIExtend.setNodeVisible(self.mRootNode, 'mSkillLightSpr' .. self.mCastSkillIndex, true)
		end
	end
end

function RAFightUI:mCellNodeCCB_onSpeedUpBtn()
	self.curScaleIndex = self.curScaleIndex%4 + 1
	self:setScaleImage(self.curScaleIndex)
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_Change_Speed_Scale,{scale=self.curScaleIndex})
end

function RAFightUI:mCellNodeCCB_onHPBtn()
	local RABattleSceneManager = RARequire('RABattleSceneManager')
	RABattleSceneManager:toggleAllUnitsBloodBarVisible()
	self:_showBloodBarTxt()
end

function RAFightUI:setScaleImage(scale)
	for i=1,4 do
		self.scaleImageArr[i]:setVisible(i == scale)
	end
end


function RAFightUI:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_Update_Fight_BloodBar,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Depart, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Quit, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CastSkill_TakeEffect, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_SkillPoint_Change, OnReceiveMessage)
end

function RAFightUI:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_Update_Fight_BloodBar,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Depart, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_Quit, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CastSkill_TakeEffect, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_FightPlay_State_Change, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_SkillPoint_Change, OnReceiveMessage)
end

function RAFightUI:onPlayBtn()
	-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.SHOW_TROOP})
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.START_BATTLE})

	-- local RARootManager = RARequire('RARootManager')
	-- RARootManager.OpenPage("RAFightResultPage", nil, false, true, false, true)
end

-- function RAFightUI:resetSpeed(speed)
-- 	self.orginSpeed = speed
-- 	self:setSpeedScale(1)
-- end

-- function RAFightUI:setSpeedScale(scale)
-- 	self.currentSpeedScale = scale
	-- scale = scale * 2
 --    CCDirector:sharedDirector():setDeltaTimeScale(scale)
-- end

function RAFightUI:mCellNodeCCB_onSkipBtn()
	local RARootManager = RARequire('RARootManager')
	RARootManager.OpenPage("RASkipConfirmPage", nil, false, true, true)
	-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.END_BATTLE})
end

function RAFightUI:onReplayBtn()
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.INIT_BATTLE})
end

function RAFightUI:mCellNodeCCB_onOpenBtn()
	self:_showTopButtons(true)
end

function RAFightUI:mCellNodeCCB_onCloseBtn()
	self:_showTopButtons(false)
end

function RAFightUI:Exit()
	self.mSkillPointLabel = nil
	self.mBattleCDLabel = nil
	self.mEnableCastSkill = true
	-- self:resetSpeed(self.orginSpeed)
    self:removeMessageHandler()
    -- self.ccbfile:removeAllChildren()
    self:_restoreSkillSprite()
    UIExtend.unLoadCCBFile(self) 
end


return RAFightUI