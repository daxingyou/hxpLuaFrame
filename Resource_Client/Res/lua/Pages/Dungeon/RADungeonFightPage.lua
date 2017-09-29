local pageVar =
{
	mDungeonId 	= nil,
	mMissionId 	= nil,
	mHandlers 	= nil,
	mGuideFail 	= false -- 新手引导关卡，必败
}
local RADungeonFightPage = BaseFunctionPage:new(..., pageVar)

local HP_pb = RARequire('HP_pb')
local UIExtend = RARequire('UIExtend')
local RADungeonManager = RARequire('RADungeonManager')
local RADungeonHandler = RARequire('RADungeonHandler')
local RANetUtil = RARequire('RANetUtil')
local RAGuideManager=RARequire("RAGuideManager")
local RARootManager=RARequire("RARootManager")
-- RARequire("MessageDefine")
-- RARequire("MessageManager")

local protoIds =
{
    HP_pb.PVE_ATTACK_S
}

function RADungeonFightPage:Enter(data)
	UIExtend.loadCCBFile("RAPVEPopUp1.ccbi", self)

	local cfg = RADungeonManager:GetDungeonCfg(data.dungeonId)
	
	local strMap =
	{
		mTitle 			= _RALang(cfg.dungeonName),
		mCharpterLabel 	= _RALang(cfg.dungeonDes)
	}
	UIExtend.setStringForLabel(self.ccbfile, strMap)

	self.mDungeonId = data.dungeonId
	self.mMissionId = cfg.missionId
	self.mGuideFail = false
	self:_registerMessageHandlers()

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()   
    end
	self:_initGuide()
end
function RADungeonFightPage:_initGuide()
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        performWithDelay(self:getRootNode(), function ()
            RAGuideManager.gotoNextStep()
        end,0.5)
    end
end
function RADungeonFightPage._onReceiveMessage(msg)
    local msgId = msg.messageID
    local self = RADungeonFightPage

      -- 新手 by xinping
    if msgId == MessageDef_Guide.MSG_Guide  then
    	local constGuideInfo = msg.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")

        if guideId == RAGuideConfig.battleFailure then
        	self.mMissionId = RAGuideConfig.battleFailureMissionId
        	self.mGuideFail = true
        end

        --if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEStartFightNode then
            if constGuideInfo.showGuidePage == 1 then
            	
                local mapAreaNode = UIExtend.getCCNodeFromCCB(RADungeonFightPage.ccbfile, "mFightBtn")
                local pos = ccp(0, 0)
                pos.x, pos.y = mapAreaNode:getPosition()
                local worldPos = mapAreaNode:getParent():convertToWorldSpace(pos)
                local size = mapAreaNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end 
        --end  
    
    end
end

function RADungeonFightPage:_unregisterMessageHandlers()
    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,self._onReceiveMessage)
    end
end
function RADungeonFightPage:_registerMessageHandlers()
    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,self._onReceiveMessage)
    end
end
function RADungeonFightPage:onFightBtn()

    if self.canClick==false then return end
    self.canClick=false
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.RemoveGuidePage()
    end
    -- TODO: 改为先战斗发协议 2017.01.14
	if true or self.mGuideFail then    --第二场失败
		self:_onAttackRsp({})
	else    
		self:_registerPacketListener()
		RADungeonHandler:sendAttackDungeonReq(self.mDungeonId)  --关卡id
	end
end

function RADungeonFightPage:onClose()
	local RARootManager = RARequire('RARootManager')
	RARootManager.CloseCurrPage()
end

function RADungeonFightPage:Exit()
    self.canClick=nil
	self:_removePacketListener()
	self:_unregisterMessageHandlers()
    UIExtend.unLoadCCBFile(self) 
end

function RADungeonFightPage:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.PVE_ATTACK_S then
        local msg = Dungeon_pb.AttackDungeonResp()
        msg:ParseFromString(buffer)
        self:_onAttackRsp(msg)
        return
    end
end

function RADungeonFightPage:_registerPacketListener()
    self.mHandlers = RANetUtil:addListener(protoIds, self)
end

function RADungeonFightPage:_removePacketListener()
	if self.mHandlers then
	    RANetUtil:removeListener(self.mHandlers)
	    self.mHandlers = nil
	end
end

function RADungeonFightPage:_onAttackRsp(msg)
	if msg.reward then
		local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
		RAPlayerInfoManager.SyncAttrInfoFromReward(msg.reward)
	end
	
	local RARootManager = RARequire('RARootManager')
    RARootManager.CloseCurrPage()
    local params={}
    params.dungeonId = self.mDungeonId
    params.missionId = self.mMissionId
    params.reward = msg.reward

    RARootManager.OpenPage("RAMissionTroopPage",params,true,true,false)
	
	-- RARootManager.ChangeScene(SceneTypeList.BattleScene, nil, {missionId = self.mMissionId, reward = msg.reward})
end

return RADungeonFightPage