RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RAFightDefine')
local RARootManager = RARequire('RARootManager')	
local UIExtend = RARequire('UIExtend')
local RAGuideManager=RARequire("RAGuideManager")
local RAFightResultPage = BaseFunctionPage:new(..., {mRewardNode = nil})
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Guide.MSG_Guide then  
        --新手相关
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        --if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEResultConfirmBtn then
             if constGuideInfo.showGuidePage == 1 then
                local confirmNode = UIExtend.getCCNodeFromCCB(RAFightResultPage.ccbfile, "mGuideConfirmNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = confirmNode:getPosition()
                local worldPos = confirmNode:getParent():convertToWorldSpace(pos)
                local size = confirmNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        --end 
    end
end

function RAFightResultPage:Enter(data)
	self.ccbfile = UIExtend.loadCCBFile("RABattleResultPage2.ccbi", RAFightResultPage)
	self:registerMessage()
	self:_renderRewards(data.rewardPB)

	if data.winResult == ATTACKER then 
		self.ccbfile:runAnimation("VictoryAni")
		RARequire("RAFightSoundSystem"):playVictoryMusic()
		
		--TODO...
		local delayFunc = function ()
			self.ccbfile:stopAllActions()
			RARequire("RAFightSoundSystem"):playFightWinStarMusic()
		end
		performWithDelay(self.ccbfile, delayFunc, 0.8)
	else 
		self.ccbfile:runAnimation("FailureAni")
		RARequire("RAFightSoundSystem"):playFailureMusic()
	end

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
    end
end

function RAFightResultPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()

    if lastAnimationName=="VictoryAni" or lastAnimationName=="KeepFailure" then
    	if self.keepAnimationDone then return end
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        	self.keepAnimationDone=true
            RAGuideManager.gotoNextStep()    
        end
    end 
end

function RAFightResultPage:registerMessage()
    -- MessageManager.registerMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)

     --这里只做了一个新手开关的监听 如果此界面还有其他消息监听 不要放到if语句里
    if RAGuideManager.partComplete.Guide_UIUPDATE then
         MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
         MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end 
end

function RAFightResultPage:removeMessageHandler()
    -- MessageManager.removeMessageHandler(MessageDef_BattleScene.MSG_CameraMoving_Start,OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
        MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end

end

function RAFightResultPage:onRePlay()
	MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.INIT_BATTLE,isReplay = true})
	RARootManager.ClosePage('RAFightResultPage')
end

function RAFightResultPage:onConfirm()

	if self.canClick==false then return end
	self.canClick=false
	-- MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.INIT_BATTLE})
	RARootManager.ClosePage('RAFightResultPage')

	local RAGameConfig = RARequire("RAGameConfig")
    if RAGameConfig.BattleDebug == 1 then 
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FightPlay_State_Change,{state=FIGHT_PLAY_STATE_TYPE.INIT_BATTLE})
    else

        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            RARootManager.RemoveGuidePage()
            RARootManager.AddCoverPage()
            -- return 
        end
        RARootManager.GotoLastScene() 
    end  
end

function RAFightResultPage:Exit()
	self.ccbfile:stopAllActions()

    self:removeMessageHandler()
    if self.mRewardNode then
    	self.mRewardNode:removeAllChildrenWithCleanup(true)
    	self.mRewardNode = nil
    end
    self.canClick=nil
    self.keepAnimationDone=nil
    UIExtend.unLoadCCBFile(self) 
end

function RAFightResultPage:_renderRewards(rewardPB)
	--当前版本不显示奖励，做假的
	if true then 
		return 
	end 
	local rewardArr = rewardPB.showItems
	if rewardArr and #rewardArr > 0 then
		self.mRewardNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mItemNode')
		self:_showRewards(rewardArr, #rewardArr)
	end
end

function RAFightResultPage:_showRewards(data,count)
	local time=0.4
	local offsetT=0.2
	if count==1 then
		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,1,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time)
	elseif count==2 then
		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,1,count)
		end, time)

		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,2,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time+offsetT)
	elseif count>=3 then
		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,1,count)
		end, time)

		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,2,count)
		end, time+offsetT)

		performWithDelay(self.mRewardNode, function ()
			self:creatRewardCell(data,3,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time+offsetT*2)
	end 
end

-------------------------------------------------------------------------------
local RARewardPopupNewPageCell = {}

function RARewardPopupNewPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RARewardPopupNewPageCell:load()
	local ccbi = UIExtend.loadCCBFile("RARewardPopUpCellNew.ccbi", self)
    return ccbi
end

function  RARewardPopupNewPageCell:getCCBFile()
	return self.ccbfile
end

function  RARewardPopupNewPageCell:updateInfo()
	local ccbfile = self:getCCBFile()
	local mainType = self.rewardMainType
    local rewardId = self.rewardId
    local rewardCount = self.rewardCount

    local RAResManager = RARequire('RAResManager')
    local icon, name = RAResManager:getIconByTypeAndId(tonumber(mainType), tonumber(rewardId))
    if icon then
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
    end
    if name then
        UIExtend.setCCLabelString(ccbfile, "mRewardName", _RALang(name))   
    end
    local label = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mRewardNum")
    -- UIExtend.setCCLabelString(ccbfile, "mRewardNum", rewardCount)

    local RAActionManager=RARequire("RAActionManager")
    local action = RAActionManager:CreateNumLabelChangeAction(1.5, 0, rewardCount, false, 0,"+")
    action:startWithTarget(label)

    ccbfile:runAnimation("RewardAni1")


end

---------------------------------------------------------

function RAFightResultPage:creatRewardCell(data,index,count)

	local mainType = nil
	local rewardId = nil
	local rewardCount = nil
	self.isSplite = true
	if self.isSplite then
		local rewardArr=data[index]
		mainType = rewardArr.itemType
    	rewardId = rewardArr.itemId
    	rewardCount = rewardArr.itemCount
	else
		 local rewardArray = Utilitys.Split(data[index], "_")
	     mainType = rewardArray[1]
	     rewardId = rewardArray[2]
	     rewardCount = rewardArray[3]
	end 

    local panel = RARewardPopupNewPageCell:new({
		rewardMainType = mainType,
		rewardId = rewardId, 
		rewardCount = rewardCount
	})
    local ccbi=panel:load()
    -- ccbi:setAnchorPoint(0.5,0.5)
    panel:updateInfo()

	self.mRewardNode:addChild(ccbi)
    local cellW = ccbi:getContentSize().width
    local cellH = ccbi:getContentSize().height

    self:setShowPos(ccbi,self.mRewardNode,cellW,cellH,index,count)
    -- table.insert(self.rewardCCBTb,panel)
end

function RAFightResultPage:setShowPos(node,parentNode,cellW,cellH,index,count)
	local maxShowNum = 3
	local rewardNum=count
	if rewardNum>maxShowNum then
		rewardNum = maxShowNum
	end 

	local w=parentNode:getContentSize().width
	local h=parentNode:getContentSize().height

	if rewardNum==1 then
		node:setPosition(ccp(w*0.5,h*0.5))
	elseif rewardNum==2 then
		node:setPosition(ccp(cellW*index,cellH*0.5))
	elseif rewardNum==3 then
		node:setPosition(ccp((index-1)*cellW+cellW*0.5,cellH*0.5))
	end 

end

return RAFightResultPage