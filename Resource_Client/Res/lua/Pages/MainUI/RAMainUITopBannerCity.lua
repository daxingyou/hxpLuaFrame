--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local RARootManager = RARequire('RARootManager')
local UIExtend = RARequire('UIExtend')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RALogicUtil = RARequire('RALogicUtil')
local RAActionManager = RARequire('RAActionManager')
local Recharge_pb = RARequire("Recharge_pb")
local RANetUtil = RARequire("RANetUtil")
local RA_Common = RARequire("common")
local RAGuideManager = RARequire("RAGuideManager")
local RAGuideConfig = RARequire("RAGuideConfig")

local RAMainUITopBannerCity = BaseFunctionPage:new(...)
local OnPacketRecieve = nil
local OnNodeEvent = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"

local OnReceiveMessage = nil


RAMainUITopBannerCity.mChangeCount = 0
RAMainUITopBannerCity.mIsShow = false
RAMainUITopBannerCity.mLastIconId = -1
RAMainUITopBannerCity.lastData = {
    mLastGold = 0, -- 钻石
    mLastBattlePoit = 0, -- 战力
    mLastGoldore = 0,   -- 金矿
    mLastOil = 0,   -- 石油
    mLastSteel = 0,   -- 钢铁
    mLastTombarthite = 0,   -- 稀�?
}

RAMainUITopBannerCity.actionMap = {
    mDiamondsNum = nil, 
    mPower = nil,
    mGoldNum = nil,   -- 金矿
    mOilNum = nil,   -- 石油
    mSteelNum = nil,   -- 钢铁
    mRareEarthsNum = nil,   -- 稀�?   
}



function RAMainUITopBannerCity:resetData()    
    self.mChangeCount = 0
    self.mIsShow = false
    self.mLastIconId = -1
    
    self.lastData = {
        mLastGold = 0, -- 钻石
        mLastBattlePoit = 0, -- 战力
        mLastGoldore = 0,   -- 金矿
        mLastOil = 0,   -- 石油
        mLastSteel = 0,   -- 钢铁
        mLastTombarthite = 0,   -- 稀�?
    }

    self.actionMap = {
        mDiamondsNum = nil, 
        mPower = nil,
        mGoldNum = nil,   -- 金矿
        mOilNum = nil,   -- 石油
        mSteelNum = nil,   -- 钢铁
        mRareEarthsNum = nil,   -- 稀�?   
    }

    self:unregisterMessageHandlers()
end


function RAMainUITopBannerCity:Enter(data)
    self:resetData()
	CCLuaLog("RAMainUITopBannerCity:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUITopBannerCity.ccbi",RAMainUITopBannerCity)
	
    if data ~= nil then
        for k,v in pairs(data) do
            print(k,v)
            CCLuaLog("RAMainUITopBannerCity:Enter  k="..k.." v="..v)
        end
    end
    -- self:ChangeShowStatus(true, true, 1)

    self:refreshBasicData()
    self:registerMessageHandlers()
end


function RAMainUITopBannerCity:onUserBtn()
    RARootManager.OpenPage("RALordMainPage", nil ,true, true)
end


OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        CCLuaLog("MessageDef_MainUI MSG_UpdateBasicPlayerInfo")
        local temp = RAPlayerInfoManager.getPlayerBasicInfo().playerId        
        CCLuaLog("MessageDef_MainUI :"..temp)
        RAMainUITopBannerCity:refreshBasicData()
    end

    if message.messageID == MessageDef_Lord.MSG_RefreshHeadImg then
        CCLuaLog("MessageDef_MainUI MSG_UpdateBasicPlayerInfo")
        RAMainUITopBannerCity:refreshHeadImg()
    end

    --新手：xinghui，收到消息显示建筑按钮
    if message.messageID == MessageDef_Guide.MSG_Guide then
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local keyWord = constGuideInfo.keyWord
        if keyWord == RAGuideConfig.KeyWordArray.PlayMainUIAni then
            RAMainUITopBannerCity.ccbfile:setVisible(true)
            RAMainUITopBannerCity.ccbfile:runAnimation(CCB_InAni)
        elseif keyWord == RAGuideConfig.KeyWordArray.VIPLevelUp then
            RARootManager.AddCoverPage()
            --显示UI
            if RAGuideManager:isInGuide() then
                MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true})
            end

            local vipActive = RAPlayerInfoManager.isVIPActive()
            local vipLevel = RAPlayerInfoManager.getVipLevel()
            if vipActive then
                --如果已经是vip，那么不再发送协议
                RAGuideManager.gotoNextStep()
                return
            else
                --如果不是vip，但已经在免费升级状态，那么直接gotoNextStep()
                local constGuideInfo = RAGuideManager.getConstGuideInfoById()
                if constGuideInfo.buildType and constGuideInfo.keyWord and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then
                    local RAQueueManager = RARequire("RAQueueManager")
                    local isInFree = RAQueueManager:isBuildingInFreeTime(constGuideInfo.buildType)
                    if isInFree then
                        --模拟发送hud动画完成消息
                        MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo)
                    else
                        --如果没有建造队列的话，直接跳过圈住免费按钮这一步
                        local isUpgrade = RAQueueManager:isBuildingTypeUpgrade(constGuideInfo.buildType)
                        if not isUpgrade then
                            RAGuideManager.gotoNextStep2()
                        end
                    end
                end
            end

            --发送vip协议
            local Newly_pb = RARequire("Newly_pb")
            local msg = Newly_pb.HPGenNewlyData()
            msg.type = Newly_pb.VIP
            RANetUtil:sendPacket(HP_pb.GEN_NEWLY_DATA_C, msg, {retOpcode = -1})
        elseif keyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then
            local mainUI = RARequire("RAMainUIPage")
            local queueCCB = mainUI.mQueueShowHelper.mCellList[1]:GetCCBFile()
            if queueCCB then
                local freeBtn = UIExtend.getCCControlButtonFromCCB(queueCCB, "mFreeBtn")
                if freeBtn then
                    local pos = freeBtn:getParent():convertToWorldSpace(ccp(freeBtn:getPositionX(), freeBtn:getPositionY()))
                    local size = freeBtn:getContentSize()
                    size.width = size.width + 18
                    size.height = size.height + 18
                    --RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = pos, ["size"]=size})
                    RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId})--不圈住免费按钮
                    RARootManager.RemoveCoverPage()
                else
                    RARootManager.RemoveGuidePage()
                    RARootManager.RemoveCoverPage()
                end
            else
                --如果此时检测不到免费按钮，说明已经升级完成
                RARootManager.AddCoverPage()
                RAGuideManager.gotoNextStep()
            end
        elseif keyWord == RAGuideConfig.KeyWordArray.CircleMarchAcc then
            --圈住出征加速的队列按钮
            local mainUI = RARequire("RAMainUIPage")
            local queueCCB = mainUI.mQueueShowHelper.mCellList[1]:GetCCBFile()
            if queueCCB then
                local freeBtn = UIExtend.getCCControlButtonFromCCB(queueCCB, "mBlueBtn")
                if freeBtn then
                    local pos = freeBtn:getParent():convertToWorldSpace(ccp(freeBtn:getPositionX(), freeBtn:getPositionY()))
                    local size = freeBtn:getContentSize()
                    size.width = size.width + 18
                    size.height = size.height + 18
                    RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = pos, ["size"]=size})
                    RARootManager.RemoveCoverPage()
                else
                    RARootManager.RemoveGuidePage()
                    RARootManager.RemoveCoverPage()
                end
            else
                --如果此时检测不到免费按钮，说明已经升级完成
                RARootManager.AddCoverPage()
                RAGuideManager.gotoNextStep()
            end
        end
    elseif message.messageID == MessageDef_RedPoint.MSG_Refresh_Head_RedPoint then
        --刷新指挥官头像上的红点
        RAMainUITopBannerCity:refreshRedPonit()     
    end
end

function RAMainUITopBannerCity:registerMessageHandlers()
    --基础数据
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    --刷新头像
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage

    --红点消息
    MessageManager.registerMessageHandler(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint, OnReceiveMessage)
end

function RAMainUITopBannerCity:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)    
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage

    --红点消息
    MessageManager.removeMessageHandler(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint, OnReceiveMessage)

end


function RAMainUITopBannerCity:refreshBasicData()    
    --UIExtend.setCCLabelString(self:getRootNode(), "mVIPTex", "VIP "..RAPlayerInfoManager.getVipLevel())
    UIExtend.setCCLabelBMFontString(self:getRootNode(), "mVIPTex", "VIP "..RAPlayerInfoManager.getVipLevel())
    
    -- local endTime=RAPlayerInfoManager.getPlayerBasicInfo().vipEndTime

    -- local currTime=RA_Common:getCurTime() * 1000


    -- local isActive=false
    -- if endTime>currTime then
    --     isActive=true
    -- end

    local isActive,endTime = RAPlayerInfoManager.isVIPActive()

    if isActive then
        --vip结束时间 - 1小时的时间 = 多久需要推送的时间
        local diffTime = endTime - 3600
        if diffTime > 0 then
            local RANotificationManager = RARequire("RANotificationManager")
            RANotificationManager.deleteCommonNotification(51)
            RANotificationManager.addNotification(51, diffTime, 51)
        end

        --设置vip时间结束后的推送
        if endTime > 0 then
            local RANotificationManager = RARequire("RANotificationManager")
            RANotificationManager.deleteCommonNotification(52)
            RANotificationManager.addNotification(52, endTime, 52)
        end
    end

    local vipGrayPic=self:getRootNode():getCCSpriteFromCCB("mVIPGrayPic")
    local vipPic=self:getRootNode():getCCSpriteFromCCB("mVIPPic")

    if vipGrayPic~=nil then
        vipGrayPic:setVisible(not isActive)
    end    

     if vipPic~=nil then
        vipPic:setVisible(isActive)
    end    

    if isActive then
        local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
        if keyWord == RAGuideConfig.KeyWordArray.VIPLevelUp then
            --播放vip升级动画
            local this = self
            local vipUpgradeNode = UIExtend.getCCBFileFromCCB(self.ccbfile, "mVIPUpgradeAniCCB")
            if vipUpgradeNode then
                vipUpgradeNode:setVisible(true)
                vipUpgradeNode:runAnimation("Upgrade")
            end

            performWithDelay(self:getRootNode(), function ()
                UIExtend.setNodeVisible(this.ccbfile, "mVIPUpgradeAniCCB", false)
            end, 2.5)
        end
    end

    --资源按大本等级显示
    local Const_pb = RARequire("Const_pb")   
    --钢材
    UIExtend.setNodeVisible(self:getRootNode(), 'mSteelNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.STEEL))
    --合金
    UIExtend.setNodeVisible(self:getRootNode(), 'mRareEarthsNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.TOMBARTHITE))
    

    -- UIExtend.setCCLabelString(self:getRootNode(), "mDiamondsNum", tostring(RAPlayerInfoManager.getPlayerBasicInfo().gold))
    -- UIExtend.setCCLabelString(self:getRootNode(), "mPower", tostring(RAPlayerInfoManager.getPlayerBasicInfo().battlePoint))

    -- UIExtend.setCCLabelString(self:getRootNode(), "mGoldNum", RALogicUtil:num2k(RAPlayerInfoManager.getPlayerBasicInfo().goldore)) 
    -- UIExtend.setCCLabelString(self:getRootNode(), "mOilNum", RALogicUtil:num2k(RAPlayerInfoManager.getPlayerBasicInfo().oil))
    -- UIExtend.setCCLabelString(self:getRootNode(), "mSteelNum", RALogicUtil:num2k(RAPlayerInfoManager.getPlayerBasicInfo().steel))
    -- UIExtend.setCCLabelString(self:getRootNode(), "mRareEarthsNum", RALogicUtil:num2k(RAPlayerInfoManager.getPlayerBasicInfo().tombarthite))

    self:checkLabelAndUpdate("mDiamondsNum", self.lastData.mLastGold, RAPlayerInfoManager.getPlayerBasicInfo().gold, false, 0)
    self.lastData.mLastGold = RAPlayerInfoManager.getPlayerBasicInfo().gold

    --战力提升的时候播放音效 不等于0的时候为不是第一次进
    if self.lastData.mLastBattlePoit ~= 0 and self.lastData.mLastBattlePoit < RAPlayerInfoManager.getPlayerBasicInfo().battlePoint then
        local common = RARequire("common")
        common:playEffect("prompt3")
    end
    self:checkLabelAndUpdate("mPower", self.lastData.mLastBattlePoit, RAPlayerInfoManager.getPlayerBasicInfo().battlePoint, false, 0)
    self.lastData.mLastBattlePoit = RAPlayerInfoManager.getPlayerBasicInfo().battlePoint

    self:checkLabelAndUpdate("mGoldNum", self.lastData.mLastGoldore, RAPlayerInfoManager.getPlayerBasicInfo().goldore, true, 1)
    self.lastData.mLastGoldore = RAPlayerInfoManager.getPlayerBasicInfo().goldore

    self:checkLabelAndUpdate("mOilNum", self.lastData.mLastOil, RAPlayerInfoManager.getPlayerBasicInfo().oil, true, 1) 
    self.lastData.mLastOil = RAPlayerInfoManager.getPlayerBasicInfo().oil

    self:checkLabelAndUpdate("mSteelNum", self.lastData.mLastSteel, RAPlayerInfoManager.getPlayerBasicInfo().steel, true, 1)    
    self.lastData.mLastSteel = RAPlayerInfoManager.getPlayerBasicInfo().steel

    self:checkLabelAndUpdate("mRareEarthsNum", self.lastData.mLastTombarthite, RAPlayerInfoManager.getPlayerBasicInfo().tombarthite, true, 1)    
    self.lastData.mLastTombarthite = RAPlayerInfoManager.getPlayerBasicInfo().tombarthite

    self:refreshHeadImg()
end

function RAMainUITopBannerCity:checkLabelAndUpdate(name, oldValue, newValue, is2K, dotCount)
    local label = UIExtend.getCCLabelTTFFromCCB(self:getRootNode(), name)

    if label ~= nil then
        if oldValue ~= newValue then
            local action = self.actionMap[name]
            if action ~= nil and action.ClearAction ~= nil then
                action:ClearAction()
                self.actionMap[name] = nil
            end
            action = RAActionManager:CreateNumLabelChangeAction(0.5, oldValue, newValue, is2K, dotCount)
            action:startWithTarget(label)
            self.actionMap[name] = action
        else
            if is2K then
                label:setString(RALogicUtil:num2k(newValue, dotCount))
            else
                label:setString(RALogicUtil:numCutAfterDot(newValue, dotCount))
            end
        end
    end
end


function RAMainUITopBannerCity:refreshHeadImg()

      -- 头像不同的时候刷�?
    if RAPlayerInfoManager.getPlayerBasicInfo().headIconId ~= self.mLastIconId then
        local iconStr = RAPlayerInfoManager.getHeadIcon()
        self.playerIcon=UIExtend.addSpriteToNodeParent(self:getRootNode(), "mHeadPortaitNode", iconStr)
    end 
    self:refreshCommanderState()
   
end

--刷新下指挥官的状态
function RAMainUITopBannerCity:refreshCommanderState()
    local RACommandManage=RARequire("RACommandManage")
    local state=RACommandManage:getCommanderState()

    if self.playerIcon then

        --0：正常 1:被抓 2:释放行军返回途中 3:处决  4:死亡
        if state==0 then
            UIExtend.setNodeVisible(self.ccbfile,"mCageNode",false)
            UIExtend.setCCSpriteGray(self.playerIcon,false)
        elseif state==1 or state==2 or state==3 then
            --显示监狱图片
            UIExtend.setCCSpriteGray(self.playerIcon,false)
            UIExtend.setNodeVisible(self.ccbfile,"mExecutePic",false)
            UIExtend.setNodeVisible(self.ccbfile,"mCageNode",true)
        elseif state==4 then
            --直接置灰
            UIExtend.setNodeVisible(self.ccbfile,"mCageNode",true)
            UIExtend.setNodeVisible(self.ccbfile,"mExecutePic",true)
            UIExtend.setCCSpriteGray(self.playerIcon,true)
        end 
    end 
end

function RAMainUITopBannerCity:refreshRedPonit()
    -- body
    local RAEquipManager = RARequire("RAEquipManager")
    local redpointNode = false
    --装备红点
    local equipRedPointCount = RAEquipManager:getEquipsRedPointCount()
    --天赋红点
    local RATalentManager = RARequire("RATalentManager")
    local talentRedPointCount = RATalentManager.getTalentRedPointCount()

    local totalCount = equipRedPointCount + talentRedPointCount
    if totalCount > 0 then
        redpointNode = true
        UIExtend.setStringForLabel(self.ccbfile, {mUserHeadTipsNum = totalCount})
    end
    UIExtend.setNodeVisible(self.ccbfile,'mUserHeadTipsNode',redpointNode)
end

function RAMainUITopBannerCity:onVipBtn()
    CCLuaLog("RAMainUITopBannerCity:onVipBtn")
    --RARootManager.ShowMsgBox("@NoOpen")
	--RARootManager.OpenPage("RARankPage")
	RARootManager.OpenPage("RAVIPMainPage",nil,true, true, false)
end

--打开支付面板
function RAMainUITopBannerCity:onDiamondsBtn()
    local msg = Recharge_pb.FetchRechargeInfo()
    RANetUtil:sendPacket(HP_pb.FETCH_RECHARGE_INFO, msg)
end

function RAMainUITopBannerCity:onTestBtn1()
	CCLuaLog("RAMainUITopBannerCity:onTestBtn1")
    RARootManager.OpenPage("RACDKeyPage")
end

function RAMainUITopBannerCity:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    self:AniEnd(lastAnimationName)
end


function RAMainUITopBannerCity:ChangeShowStatus(isShow, isAni, delay)
    if self.mChangeCount > 0 then
        CCLuaLog("RAMainUITopBannerCity is moving. count:"..self.mChangeCount)
        return
    end
    if self.mIsShow == isShow then
        return
    end

    self.mChangeCount = 1
    self.mIsShow = isShow
    self:RunAni(self.mIsShow, isAni, delay)
end


function RAMainUITopBannerCity:AniEnd(aniName)
    local isHandle = false
    if self.mIsShow and aniName == CCB_InAni then                
        isHandle = true
    end
    
    if not self.mIsShow and aniName == CCB_OutAni then                
        isHandle = true
    end

    if isHandle then
        self.mChangeCount = self.mChangeCount - 1
        CCLuaLog("CellAniEnd   cell cout:"..self.mChangeCount)    
    end
end


function RAMainUITopBannerCity:RunAni(isShow, isAni, delay)
    local aniName = nil
    local noAniName = nil
    if delay == nil then
        delay = 0
    end
    if isAni == nil then
        isAni = true
    end
    if isShow then
        aniName = CCB_InAni        
        noAniName = CCB_KeepIn
    else
        aniName = CCB_OutAni        
        noAniName = CCB_KeepOut
    end
    local aniTar = aniName
    if not isAni then
        aniTar = noAniName
    end

    --51步才会把所有的bottom UI展现出来，所在在此之前，不播放动画
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowAllMainUI()) then
        return
    end

    if delay <= 0 then 
        local cmd = self:getAnimationCmd(aniTar)
        cmd()
    else
        performWithDelay(self:getRootNode(), self:getAnimationCmd(aniTar), delay)   
    end
end

function RAMainUITopBannerCity:getAnimationCmd(name)
    local ccbi = self:getRootNode()
    return function()
        if ccbi ~= nil then
            ccbi:runAnimation(name)
        else
            CCLuaLog("RAMainUITopBannerCity:getAnimationCmd ccbi is nil")
        end
    end
end

function RAMainUITopBannerCity:Exit()
    CCLuaLog("RAMainUITopBannerCity:Exit")
    UIExtend.unLoadCCBFile(self)
    self:resetData()
end


--点击矿石资源按钮
function RAMainUITopBannerCity:onGetGoldBtn()

    -- self:getAttributePos()

    local data={}
    data.resourceType = 14
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击石油资源按钮
function RAMainUITopBannerCity:onGetOilBtn()
    local data={}
    data.resourceType = 17
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击钢铁资源按钮
function RAMainUITopBannerCity:onGetSteelBtn()
    local data={}
    data.resourceType = 16
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击合金资源按钮
function RAMainUITopBannerCity:onGetRareEarthsBtn()
    local data={}
    data.resourceType = 15
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end

--获取一些玩家属性的世界坐标
function RAMainUITopBannerCity:getAttributePos( ... )

    local tb={}
    tb["Default"]=RACcp(50,CCDirector:sharedDirector():getOpenGLView():getVisibleSize().height-50)

    local node=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mDiamondsNum")
    local pos=ccp(node:getPosition())
    local worldPos=node:getParent():convertToWorldSpace(pos)
    tb["Diamond"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCLabelBMFontFromCCB(self.ccbfile,"mVIPTex")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["VIP"]=RACcp(worldPos.x,worldPos.y)

    -- node=UIExtend.getCCLabelBMFontFromCCB(self.ccbfile,"mVIPTex")
    -- worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    -- tb["VIT"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCNodeFromCCB(self.ccbfile,"mGoldNode")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["GOLDORE"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCNodeFromCCB(self.ccbfile,"mOilNode")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["OIL"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCNodeFromCCB(self.ccbfile,"mSteelNode")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["STEEL"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCNodeFromCCB(self.ccbfile,"mRareEarthsNode")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["TOMBARTHITE"]=RACcp(worldPos.x,worldPos.y)

    return tb
end
