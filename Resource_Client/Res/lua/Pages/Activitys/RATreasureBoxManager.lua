--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RANetUtil=RARequire("RANetUtil")
local RALogicUtil = RARequire("RALogicUtil")
local RAResManager = RARequire("RAResManager")
local UIExtend  =RARequire("UIExtend")
local HP_pb =RARequire("HP_pb")
local Activity_pb=RARequire("Activity_pb")
local EnterFrameDefine = RARequire("EnterFrameDefine")
local RA_Common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
RARequire("EnterFrameMananger")
RARequire("MessageDefine")
RARequire("MessageManager")

local mFrameTime = 0
----------------------------treasurebox data--------------------------------------------------------
RATreasureBoxData = {}

--构造函数
function RATreasureBoxData:new(o)
    o = o or {}
    o.nextRefreshTime = nil
    setmetatable(o,self)
    self.__index = self
    return o
end

function RATreasureBoxData:initByPbData(treasureBoxData)
	self.nextRefreshTime = math.floor(treasureBoxData.nextRefreshTime/1000)
end


----------------------------treasurebox data--------------------------------------------------------
local RATreasureBoxManager={
	flySpeed = 400,							-- 宝箱飞行的速度
	netHandlers = {},   						-- 存放监听协议
	curTreasurBox=nil

}

local TAG = 1000

function RATreasureBoxManager:Enter()
	self:addHandler()
	EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.TreasureBox.EF_TreasureBoxUpdate, self)
end

function RATreasureBoxManager:addTreasureBoxData(data)
	if not self.curTreasurBox then
		local treasureData=RATreasureBoxData:new()
    	treasureData:initByPbData(data) 
    	self.curTreasurBox = treasureData
	end 
end

function RATreasureBoxManager:updateTreasureBoxData(refreshTime)
	local nextRefreshTime = math.floor(refreshTime/1000)
	self.curTreasurBox.nextRefreshTime = nextRefreshTime
end

function RATreasureBoxManager:getCurTreasureBox()
	return self.curTreasurBox
end
function RATreasureBoxManager:Exit()
	self.curTreasurBox = nil
	self.isSend =nil
    self:removeHandler()
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.TreasureBox.EF_TreasureBoxUpdate, self)
    UIExtend.unLoadCCBFile(self)
end

function RATreasureBoxManager:reset()
   self:Exit()
end

function RATreasureBoxManager:EnterFrame()
	if self.curTreasurBox then
		mFrameTime = mFrameTime + RA_Common:getFrameTime()
		if mFrameTime<1 then return end 
		local RABuildManager = RARequire("RABuildManager")
		if RABuildManager.gift then return end 
		mFrameTime = 0
		local refreshTime = self.curTreasurBox.nextRefreshTime
		if refreshTime and refreshTime>0 then
			local currTime = RA_Common:getCurTime()
			
			if currTime>=refreshTime then
				CCLuaLog("create a treasurebox================================")
				RABuildManager.gift={}                   --用这个变量是为了防止场景还没有初始化
				MessageManager.sendMessage(MessageDef_TreasureBox.MSG_TreasureBox_Create)
				self:setIsSendCmd(false)
			end
		end 
		
	end 
	
end

function RATreasureBoxManager:createBoxCell(reward)
	local ccbfile = UIExtend.loadCCBFile("Ani_UI_WorldReward.ccbi",self)
	self.ccbfile = ccbfile
	UIExtend.handleCCBNode(ccbfile)
	local itemId = reward.itemId
	local itemType = reward.itemType
	local itemCount = reward.itemCount

	local isEquip=RALogicUtil:isItemById(itemId)  --道具
 	local isRes =RALogicUtil:isResourceById(itemId) --资源

 	local icon
 	local RAMailUtility=RARequire("RAMailUtility")
 	if isEquip then
 		icon =RAMailUtility:getItemIconByid(itemId)
 	elseif isRes then 
 		icon=RALogicUtil:getResourceIconById(itemId)
 	end

 	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
 	UIExtend.addNodeToAdaptParentNode(picNode,icon,1000)

 	UIExtend.setCCLabelString(ccbfile,"mItemCount","+"..itemCount)

 	ccbfile:runAnimation("InAni")

 	performWithDelay(ccbfile, function ()
 			
			ccbfile:runAnimation("OutAni")
			performWithDelay(ccbfile, function ()
				UIExtend.unLoadCCBFile(RATreasureBoxManager)
			end, 3.0)

	end, 2.0)
	return ccbfile

end

function RATreasureBoxManager:OnAnimationDone()
    local lastAnimationName = self.ccbfile:getCompletedAnimationName()
    CCLuaLog('OnAnimationDone' .. lastAnimationName)
    if lastAnimationName == 'OutAni' then 
    	local info = {}

    	info.itemType = self.reward.itemType
        info.itemId = self.reward.itemId
        info.itemCount = self.reward.itemCount

        local data = {}
        data[#data + 1] = info
        RARootManager.ShowCommonReward(data, true)
    end 
end

function RATreasureBoxManager:createRewardUIAndAction(reward)
	
	local RABuildManager = RARequire("RABuildManager")
	local buildDatas     = RABuildManager:getGiftData()		
		
	local tilePos 		 = buildDatas.tilePos

	local RACityScene    = RARequire("RACityScene")
	local RATileUtil     = RARequire("RATileUtil")

	local pos  = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,tilePos)
	local RACitySceneManager = RARequire('RACitySceneManager')
    pos = RACitySceneManager.convertTerrainPos2ScreenPos(pos)
    local treasurBoxPos = ccp(pos.x, pos.y)

    local RAMainUIBottomBanner = RARequire("RAMainUIBottomBannerNew")
    local packageNode = UIExtend.getCCNodeFromCCB(RAMainUIBottomBanner.ccbfile, "mPackageBtnNode")
    treasurBoxPos =packageNode:getParent():convertToNodeSpace(treasurBoxPos)

    self.reward = reward
    local ccb = self:createBoxCell(reward)
    packageNode:getParent():addChild(ccb)
    ccb:setPosition(treasurBoxPos)



  
 --  	local giftNode = CCNode:create()
  
 --  	local pic = CCSprite:create(icon)
 --  	giftNode:addChild(pic)
 --  	pic:setPosition(ccp(0,0))
 --  	pic:setAnchorPoint(0.5,0.5)

 --  	local label = CCLabelTTF:create("+"..itemCount, "Helvetica", 80)
	-- giftNode:addChild(label)
	-- label:setAnchorPoint(0.5,0.5)
	-- local RAGameConfig = RARequire("RAGameConfig")
	-- label:setColor(RAGameConfig.COLOR.GREEN)
	-- label:setPosition(ccp(pic:getPositionX(),pic:getPositionY()-80))

	-- giftNode:setPosition(ccp(treasurBoxPos.x,treasurBoxPos.y+pic:getContentSize().height/2))
	-- giftNode:setAnchorPoint(0.5,0.5)
	-- packageNode:getParent():addChild(giftNode)


	

	-- local packagePos 	= ccp(packageNode:getPosition())

	-- --光效飞到目标位
	-- -- local array = CCArray:create()
	-- local Utilitys = RARequire("Utilitys")
	-- local distance = Utilitys.getDistance(treasurBoxPos,packagePos)
	-- local flyTime = distance/self.flySpeed
 -- --  	local move =CCMoveTo:create(flyTime,ccp(packagePos.x-ccbfile:getContentSize().width/2,packagePos.y-ccbfile:getContentSize().height/2))
 -- --  	local funcAction = CCCallFunc:create(function ()
	-- -- 		ccbfile:removeFromParentAndCleanup(true)
	-- -- end)
	-- -- array:addObject(move)
	-- -- array:addObject(funcAction)
	-- -- local seq = CCSequence:create(array)
	-- -- ccbfile:runAction(seq)

	-- --奖励慢慢变小
	-- local scaleA=CCScaleTo:create(flyTime,0)
	-- local funcAction1 = CCCallFunc:create(function ()
	-- 		giftNode:removeFromParentAndCleanup(true)
	-- 		self:setIsSendCmd(false)
	-- end)
	-- local arrayS = CCArray:create()
	-- arrayS:addObject(scaleA)
	-- arrayS:addObject(funcAction1)
	-- local seqS = CCSequence:create(arrayS)
	-- giftNode:runAction(seqS)
	   
end

function RATreasureBoxManager:setIsSendCmd(isSend)
	self.isSend = isSend
end

function RATreasureBoxManager:getIsSendCmd()
	return self.isSend
end

--添加协议监听返回处理
function RATreasureBoxManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.TAKE_ONLINE_REWARD_S then  								--在线宝箱奖励返回
    	local msg = Activity_pb.TakeOnlineRewardResp()
        msg:ParseFromString(buffer)
        local RABuildManager = RARequire("RABuildManager")
        RABuildManager.gift=nil

        self:updateTreasureBoxData(0)
        MessageManager.sendMessage(MessageDef_TreasureBox.MSG_TreasureBox_Delete) 
        local rewards= msg.reward
        local count=#rewards
        for i=1,count do
        	self:createRewardUIAndAction(rewards[i])
        end
        
       
    end

end

--添加协议监听
function RATreasureBoxManager:addHandler()
	if #self.netHandlers==0 then
		self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.TAKE_ONLINE_REWARD_S, RATreasureBoxManager) --在线宝箱奖励返回
	end   
end

--移除协议监听
function RATreasureBoxManager:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end 


--发送领取奖励的请求
function RATreasureBoxManager:sendAchieveTreasurBoxCmd()
	local isSend = self:getIsSendCmd()
	if isSend then return end 
	 CCLuaLog('send proto==========================')
	self:setIsSendCmd(true)
	RANetUtil:sendPacket(HP_pb.TAKE_ONLINE_REWARD_C)
end

return RATreasureBoxManager

--endregion
