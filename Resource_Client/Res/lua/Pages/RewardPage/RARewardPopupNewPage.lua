RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local item_conf = RARequire("item_conf")
local Const_pb = RARequire("Const_pb")
local RALogicUtil = RARequire("RALogicUtil")
local RAResManager = RARequire("RAResManager")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAGuideManager = RARequire("RAGuideManager")
local common = RARequire("common")
RARequire("MessageDefine")
RARequire("MessageManager")
local RARewardPopupNewPage = BaseFunctionPage:new(...)

local DisappearMsg=MessageDef_Reward.Disappear
RARewardPopupNewPage.isSplite = false

	local time=0.4
	local offsetT=0.13

local CityMainUIPage="RACityScene"
local WorldMainUIPage="RAWorldScene"
local PageConfig={
	BetweenTime=0.13,		--每个奖励消失的间隔
	StartShowTime=0.2,		--第一个奖励出现的时间
	ShowOffsetTime=0.08		--每个奖励出现的间隔
}
local  POSTYPE={
	DEFAULT="Default",
	DIAMOND="Diamond",				--钻石
	VIP="VIP",						--VIP
	VIT="VIT",						--体力
	EXP="EXP",						--经验
	GOLDORE="GOLDORE",				--矿石
	OIL="OIL",						--石油
	STEEL="STEEL",					--钢材
	TOMBARTHITE="TOMBARTHITE",		--稀土
	ITME="item"						-- 道具
}
local maxShowNum=3

local OnReceiveMessage = function(message)
    if message.messageID == DisappearMsg then                      
      	
      	if RARewardPopupNewPage.startAction then return end 
      	RARewardPopupNewPage.startAction=true
      	--开始做奖励的动作
      	RARewardPopupNewPage:startRewardAction()
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



function RARewardPopupNewPage:Enter(data)
	self.canClick=false				-- 避免奖励cell还没产生出来就快速点击 等完全显示才开始可以点击
    local ccbfile=UIExtend.loadCCBFile("RARewardPopUpNew.ccbi", self)
    self.isSplite = data.isSplite
    self.rewardCCBTb={}
    local rewardArr = data.rewardArr 
    self:registerMessageHandler()


    self.rewContainer=UIExtend.getCCNodeFromCCB(ccbfile,"mRewContainer")
    self.rewContainer:removeAllChildren()

    common:playEffect('rewardAcquisition')

    self.layerColor = UIExtend.getCCLayerColorFromCCB(ccbfile, "mAdaptationColor")
    self.layerColor:setOpacity(180)

    self:getTargetPos()
    self:refreshUI(rewardArr)

    RARootManager:runShaderNodeInAni( )

end


function RARewardPopupNewPage:getTargetPos()


	local isInWorld = RARootManager:GetIsInWorld()
	self.isInWorld=isInWorld
	if isInWorld then
		--世界
		local RAMainUITopBannerWorld=RARequire("RAMainUITopBannerWorldNew")
		self.targetPosTb=RAMainUITopBannerWorld:getAttributePos()
	else
		--城内
		local RAMainUITopBannerCity=RARequire("RAMainUITopBannerCityNew")
		self.targetPosTb=RAMainUITopBannerCity:getAttributePos()

	end

    local RAMainUIBottomBanner = RARequire("RAMainUIBottomBannerNew")
    local packageNode = UIExtend.getCCNodeFromCCB(RAMainUIBottomBanner.ccbfile, "mPackageBtnNode")
    packagePos =packageNode:getParent():convertToWorldSpace(ccp(packageNode:getPosition()))

    self.targetPosTb[POSTYPE.ITME]=RACcp(packagePos.x,packagePos.y)

end

function RARewardPopupNewPage:registerMessageHandler()
    MessageManager.registerMessageHandler(DisappearMsg,OnReceiveMessage)
end

function RARewardPopupNewPage:removeMessageHandler()
    MessageManager.removeMessageHandler(DisappearMsg,OnReceiveMessage)
end


function RARewardPopupNewPage:setShowPos(node,parentNode,cellW,cellH,index,count)

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

function RARewardPopupNewPage:creatRewardCell(data,index,count)

	local mainType = nil
	local rewardId = nil
	local rewardCount = nil
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

	self.rewContainer:addChild(ccbi)
    local cellW = ccbi:getContentSize().width
    local cellH = ccbi:getContentSize().height

    self:setShowPos(ccbi,self.rewContainer,cellW,cellH,index,count)
    table.insert(self.rewardCCBTb,panel)
end


function RARewardPopupNewPage:showRewards(data,count,isSplite)

	local time=PageConfig.StartShowTime
	local offsetT=PageConfig.ShowOffsetTime
	if count==1 then
		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,1,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time)
	elseif count==2 then
		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,1,count)
		end, time)

		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,2,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time+offsetT)
	elseif count==3 then
		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,1,count)
		end, time)

		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,2,count)
		end, time+offsetT)

		performWithDelay(self.rewContainer, function ()
			self:creatRewardCell(data,3,count)
			self.canClick=true
			RARootManager.RemoveCoverPage()
		end, time+offsetT*2)
	end 
end
function RARewardPopupNewPage:refreshUI(data)
	if data then	
	   	local count=#data
		if count>maxShowNum then 
			count= maxShowNum
		end 
		self:showRewards(data,count)     
    end
end


function RARewardPopupNewPage:startRewardAction( )
	if self.rewardCCBTb then
		local RALogicUtil=RARequire("RALogicUtil")
		local Const_pb=RARequire("Const_pb")
		for i,v in ipairs(self.rewardCCBTb) do
			local id = tonumber(v.rewardId)
			local targetPos=nil
			local index=i
			if id==Const_pb.GOLDORE then
				targetPos=self.targetPosTb[POSTYPE.GOLDORE]
			elseif id==Const_pb.OIL then
				targetPos=self.targetPosTb[POSTYPE.OIL]
			elseif id==Const_pb.STEEL then
				targetPos=self.targetPosTb[POSTYPE.STEEL]
			elseif id==Const_pb.TOMBARTHITE then
				targetPos=self.targetPosTb[POSTYPE.TOMBARTHITE]
			elseif id==Const_pb.EXP then
				targetPos=self.targetPosTb[POSTYPE.EXP]
			elseif id==Const_pb.VIP then
				targetPos=self.targetPosTb[POSTYPE.VIP]
			elseif id==Const_pb.GOLD then
				targetPos=self.targetPosTb[POSTYPE.DIAMOND]
			elseif id == Const_pb.VIT then
				targetPos=self.targetPosTb[POSTYPE.VIT]
			elseif RALogicUtil:isItemById(id) then
				targetPos=self.targetPosTb[POSTYPE.ITME]
			else
				targetPos=self.targetPosTb[POSTYPE.DEFAULT]
			end 

			
			-- --RACcp(55,931) RACcp(168,931) RACcp(275,931) RACcp(408,931) RACcp(573,931)
			-- local endPosTb={RACcp(55,931),RACcp(275,931),RACcp(168,931),RACcp(408,931),RACcp(573,931)}
			-- targetPos=endPosTb[i]

			--如果在二级或三级界面就设置为默认点
			--判断是否在主UI界面上面
	    	local isInMainUITop=RARootManager:isInMainUITop("RARewardPopupNewPage")
	  		
	  		local isRandom=false
			if not isInMainUITop then
				targetPos=self.targetPosTb[POSTYPE.DEFAULT]
				isRandom=true
			end 

			local node=v:getCCBFile()
			local mainType = v.rewardMainType
    		local rewardId = v.rewardId
    		local icon,_= RAResManager:getIconByTypeAndId(tonumber(mainType), tonumber(rewardId))

			self:startSingleAction(node,targetPos,i*PageConfig.BetweenTime,index,isRandom,icon)
			
		end
	end

end

function RARewardPopupNewPage:startSingleAction(node,targetPos,delayTime,index,isRandom,icon)
	
	local array = CCArray:create()
	local delay=CCDelayTime:create(delayTime)
	-- local scale = CCScaleTo:create(PageConfig.ScaleTime,PageConfig.Scale)
	-- local fadeCCB = CCFadeTo:create(1.0,50)

	if index==1 then
		local fade = CCFadeTo:create(1.0,0)
		self.layerColor:runAction(fade)
		self.ccbfile:runAnimation("CloseAni")
		RARootManager:runShaderNodeOutAni( )
	end
	

	
	-- array:addObject(fadeCCB)
    -- array:addObject(scale)

    local funcAction = CCCallFunc:create(function ()
		node:runAnimation("RewardAni4")
	end)
	array:addObject(funcAction)

	--都转换成世界坐标
	local startPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()))
	startPos=RACcp(startPos.x,startPos.y)

	callback=function ()
		node:runAnimation("RewardAni5")

		common:playEffect('rewardAcquisitionCompleted')
		
		CCLuaLog("targetPos=========X:"..targetPos.x.." Y:"..targetPos.y)
		local iconSprite=CCSprite:create(icon)
		CCDirector:sharedDirector():getRunningScene():addChild(iconSprite)
		iconSprite:setScale(0.1)
		iconSprite:setPosition(ccp(targetPos.x,targetPos.y))

		local scale=CCScaleTo:create(1.0,0.8)
		local fadeTo=CCFadeTo:create(1.0,0)
		local iconArray = CCArray:create() 
		iconArray:addObject(scale)
		iconArray:addObject(fadeTo)

		local spawn = CCSpawn:create(iconArray)

		local disfuncAction = CCCallFunc:create(function ()
			iconSprite:removeFromParentAndCleanup(true)
		end)
		local arrayD = CCArray:create()
		arrayD:addObject(spawn)
		arrayD:addObject(disfuncAction)

		local seqD=CCSequence:create(arrayD)
		iconSprite:runAction(seqD)

		-- node:removeFromParentAndCleanup(true)
		local totalNum = #self.rewardCCBTb
		if totalNum > maxShowNum then
			totalNum = maxShowNum
		end
		if index == totalNum then
			performWithDelay(self.rewContainer, function ()
				RARootManager.CloseCurrPage()
			end, 0.5)
		end 
	end
	local bezier=UIExtend.createBezierAction(startPos,targetPos,callback,index,isRandom)

	array:addObject(bezier)

	local spawn = CCSpawn:create(array)
	-- node:runAction(spawn)

	local array1 = CCArray:create()
	array1:addObject(delay)
	local disfuncAction = CCCallFunc:create(function ()
		node:runAnimation("RewardAni3")
	end)
	array1:addObject(disfuncAction)
	local delay1=CCDelayTime:create(0.35) 
	array1:addObject(delay1)
	array1:addObject(spawn)

	local seq=CCSequence:create(array1)

	node:runAction(seq)
end

function RARewardPopupNewPage:clearCCBTb()
	if self.rewardCCBTb then
		for i,v in ipairs(self.rewardCCBTb) do
			if v then
				v.ccbfile:removeFromParentAndCleanup(true)
			end 
			v=nil	
		end
		self.rewardCCBTb=nil
	end 
end
function RARewardPopupNewPage:Exit()

	self.startAction=nil
	self.isInWorld=nil
	self.canClick=nil
	self.rewContainer:stopAllActions()
	self:removeMessageHandler()

	--新手期，奖励动画播放完成后，进入下一步
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
        RAGuideManager.gotoNextStep()
    end

	self:clearCCBTb()
    UIExtend.unLoadCCBFile(self)
  
end
