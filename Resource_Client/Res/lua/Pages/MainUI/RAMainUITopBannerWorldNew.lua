--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire("UIExtend")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RALogicUtil = RARequire('RALogicUtil')
local RAStringUtil = RARequire('RAStringUtil')
local RAActionManager = RARequire('RAActionManager')
local RAWorldManager = RARequire('RAWorldManager')
local RAGuideConfig = RARequire("RAGuideConfig")

local RAMainUITopBannerWorld = BaseFunctionPage:new(...)
local OnPacketRecieve = nil
local OnNodeEvent = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"


RAMainUITopBannerWorld.mChangeCount = 0
RAMainUITopBannerWorld.mIsShow = false
RAMainUITopBannerWorld.mLastIconId = -1

RAMainUITopBannerWorld.lastData = {
    mLastGold = 0, -- 钻石
    mLastVit = -1,   -- 体力
    mLastVitMax = -1,   -- 体力上限
    mLastGoldore = 0,   -- 金矿
    mLastOil = 0,   -- 石油
    mLastSteel = 0,   -- 钢铁
    mLastTombarthite = 0,   -- 稀土
    mLastBattlePoit = 0, -- 战力
    mExperience = -1,   --经验
    mExperienceMax = -1, --经验上限

}

RAMainUITopBannerWorld.actionMap = {
    mDiamondsNum = nil, 
    mGoldNum = nil,   -- 金矿
    mOilNum = nil,   -- 石油
    mSteelNum = nil,   -- 钢铁
    mRareEarthsNum = nil,   -- 稀土    
    mPower = nil,
}

RAMainUITopBannerWorld.ResNodePosDef = {
    [1] = {
        ["mGoldNode"] = ccp(-61, 0),
        ["mStrengthNode"] = ccp(61, 0)
    },
    [2] = {
        ["mGoldNode"] = ccp(-122, 0),
        ["mOilNode"] = ccp(0, 0),
        ["mStrengthNode"] = ccp(122, 00)
    },
    [3] = {
        ["mGoldNode"] = ccp(-183, 0),
        ["mOilNode"] = ccp(-61, 0),
        ["mSteelNode"] = ccp(61, 0),
        ["mStrengthNode"] = ccp(183, 00)
    },
    [4] = {
        ["mGoldNode"] = ccp(-244, 0),
        ["mOilNode"] = ccp(-122, 0),
        ["mSteelNode"] = ccp(0, 0),
        ["mRareEarthsNode"] = ccp(122, 0),
        ["mStrengthNode"] = ccp(244, 0)
    },
}

function RAMainUITopBannerWorld:resetData()
    self.mChangeCount = 0
    self.mLastIconId = -1
    self.mIsShow = false
    self.lastData = {
        mLastGold = 0, -- 钻石
        mLastVit = -1,   -- 体力
        mLastVitMax = -1,   -- 体力上限
        mLastGoldore = 0,   -- 金矿
        mLastOil = 0,   -- 石油
        mLastSteel = 0,   -- 钢铁
        mLastTombarthite = 0,   -- 稀土
        mLastBattlePoit = 0, -- 战力
        mExperience = -1,   --经验
        mExperienceMax = -1, --经验上限
    }
    self.actionMap = {
        mDiamondsNum = nil, 
        mGoldNum = nil,   -- 金矿
        mOilNum = nil,   -- 石油
        mSteelNum = nil,   -- 钢铁
        mRareEarthsNum = nil,   -- 稀土  
        mPower = nil,
    }
    self:unregisterMessageHandlers()
end

function RAMainUITopBannerWorld:Enter(data)
    self:resetData()
	CCLuaLog("RAMainUITopBannerWorld:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUITopBannerWorldNew.ccbi",RAMainUITopBannerWorld)
	
    if data ~= nil then
        for k,v in pairs(data) do
            print(k,v)
            CCLuaLog("RAMainUITopBannerWorld:Enter  k="..k.." v="..v)
        end
    end
    -- self:ChangeShowStatus(true, false, 2)

    self:refreshBasicData()
    self:registerMessageHandlers()

    --新手期内不显示
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowAllMainUI()) then
        self.ccbfile:setVisible(false)
    end
end

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

    -- open RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        RAMainUITopBannerWorld:refreshBasicData()
        --新手：xinghui，收到消息显示建筑按钮
    elseif message.messageID == MessageDef_Guide.MSG_Guide then
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local keyWord = constGuideInfo.keyWord
        if keyWord == RAGuideConfig.KeyWordArray.PlayMainUIAni then
            RAMainUITopBannerWorld.ccbfile:setVisible(true)
        end
    elseif message.messageID == MessageDef_Lord.MSG_RefreshHeadImg then
        CCLuaLog("MessageDef_MainUI MSG_UpdateBasicPlayerInfo")
        RAMainUITopBannerWorld:refreshHeadImg()
    elseif message.messageID == MessageDef_RedPoint.MSG_Refresh_Head_RedPoint then
        --刷新指挥官头像上的红点
        RAMainUITopBannerWorld:refreshRedPonit()     
    end
end

function RAMainUITopBannerWorld:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage
    --刷新头像
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint, OnReceiveMessage)
end

function RAMainUITopBannerWorld:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint, OnReceiveMessage)

end

function RAMainUITopBannerWorld:refreshBasicData()
    local info = RAPlayerInfoManager.getPlayerBasicInfo()
    
    local isActive,_ = RAPlayerInfoManager.isVIPActive()
    --VIP
    UIExtend.setCCLabelBMFontString(self:getRootNode(), "mVIPTex", "VIP "..RAPlayerInfoManager.getVipLevel())
    UIExtend.setCCLabelBMFontString(self:getRootNode(), "mVIPGrayTex", "VIP "..RAPlayerInfoManager.getVipLevel())
    UIExtend.setNodeVisible(self:getRootNode(), "mVIPTexNode", isActive)
    UIExtend.setNodeVisible(self:getRootNode(), "mVIPGrayTex", not isActive)

    UIExtend.setCCLabelString(self:getRootNode(), "mUserLevelNum", info.level)


    --资源按大本等级显示
    local activeResKindCount = 2
    local Const_pb = RARequire("Const_pb")   
    --钢材
    local isSteelActive = RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.STEEL)
    UIExtend.setNodeVisible(self:getRootNode(), 'mSteelNode', isSteelActive)
    if isSteelActive then
        activeResKindCount = activeResKindCount + 1
    end
    --合金
    local isTombarthiteActive = RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.TOMBARTHITE)
    UIExtend.setNodeVisible(self:getRootNode(), 'mRareEarthsNode', isTombarthiteActive)
    if isTombarthiteActive then
        activeResKindCount = activeResKindCount + 1
    end

    self:checkLabelAndUpdate("mPower", self.lastData.mLastBattlePoit, info.battlePoint, false, 0)
    self.lastData.mLastBattlePoit = info.battlePoint

    self:checkLabelAndUpdate("mDiamondsNum", self.lastData.mLastGold, info.gold, false, 0)
    self.lastData.mLastGold = info.gold

    self:checkLabelAndUpdate("mGoldNum", self.lastData.mLastGoldore, info.goldore, true, 1)
    self.lastData.mLastGoldore = info.goldore

    self:checkLabelAndUpdate("mOilNum", self.lastData.mLastOil, info.oil, true, 1) 
    self.lastData.mLastOil = info.oil

    self:checkLabelAndUpdate("mSteelNum", self.lastData.mLastSteel, info.steel, true, 1)    
    self.lastData.mLastSteel = info.steel

    self:checkLabelAndUpdate("mRareEarthsNum", self.lastData.mLastTombarthite, info.tombarthite, true, 1)    
    self.lastData.mLastTombarthite = info.tombarthite

    local vitMax = RAPlayerInfoManager.getPlayerVitMax()
    if self.lastData.mLastVit ~= info.power or self.lastData.mLastVitMax ~= vitMax then
        self:refreshVitBar(info.power, vitMax)
    end

    local experienceMax = RALogicUtil:getNextLevelExp()--获得下一等级经验
    local experienceNow = info.exp   --获得当前经验
    if self.lastData.mExperience ~= experienceNow or self.lastData.mExperienceMax ~= experienceMax then
        self:refreshExp(experienceNow, experienceMax)
    end

    self:refreshHeadImg()

    self:refreshResNodePos(activeResKindCount)

end

function RAMainUITopBannerWorld:checkLabelAndUpdate(name, oldValue, newValue, is2K, dotCount)
    if self:getRootNode() == nil then return end
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
                if dotCount <= 0 then
                    local common = RARequire("common")
                    numStr = common:commaSeperate(newValue)
                    label:setString(numStr)
                else
                    label:setString(RALogicUtil:numCutAfterDot(newValue, dotCount))
                end
            end
        end
    end
end

--[[
    desc: 根据资源数目
]]--
function RAMainUITopBannerWorld:refreshResNodePos(activeResKindCount)
    local posArr = self.ResNodePosDef[activeResKindCount]
    if posArr then
        for nodename, pos in pairs(posArr) do
            local node = UIExtend.getCCNodeFromCCB(self:getRootNode(), nodename)
            if node then
                node:setPosition(pos)
            end
        end
    end
end

-- 刷新体力
function RAMainUITopBannerWorld:refreshVitBar(targetVit, vitMax)    
    self.lastData.mLastVit = targetVit
    self.lastData.mLastVitMax = vitMax
    
    local vitDes = RAStringUtil:getLanguageString("@VitNum", targetVit, vitMax)    
    UIExtend.setCCLabelString(self:getRootNode(), "mStrengthNum", vitDes)
end

--[[
    desc: 刷新经验条
]]--
function RAMainUITopBannerWorld:refreshExp(expNow, expMax)
    self.lastData.mExperience = expNow
    self.lastData.mExperienceMax = expMax
    
    local scale = expNow * 1.0 / expMax
    if scale > 1 then
        scale = 1
    elseif scale < 0 then
        scale = 0
    end

    UIExtend.setCCScale9SpriteScale(self.ccbfile, "mExpBar", scale, true)
end

--[[
    desc: 刷新头像
]]--
function RAMainUITopBannerWorld:refreshHeadImg()

      -- 头像不同的时候刷�?
    if RAPlayerInfoManager.getPlayerBasicInfo().headIconId ~= self.mLastIconId then
        local iconStr = RAPlayerInfoManager.getHeadIcon()
        self.playerIcon=UIExtend.addSpriteToNodeParent(self:getRootNode(), "mHeadPortaitNode", iconStr)
    end 
    self:refreshCommanderState()
end

--[[
    desc: 刷新指挥官状态
]]--
function RAMainUITopBannerWorld:refreshCommanderState()
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

--[[
    desc: 刷新头像上的小红点
]]--
function RAMainUITopBannerWorld:refreshRedPonit()
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

function RAMainUITopBannerWorld:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    self:AniEnd(lastAnimationName)
end


function RAMainUITopBannerWorld:ChangeShowStatus(isShow, isAni, delay)
    if self.mChangeCount > 0 then
        CCLuaLog("RAMainUITopBannerWorld is moving. count:"..self.mChangeCount)
        return
    end
    if self.mIsShow == isShow then
        return
    end

    self.mChangeCount = 1
    self.mIsShow = isShow
    self:RunAni(self.mIsShow, isAni, delay)
end


function RAMainUITopBannerWorld:AniEnd(aniName)
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


function RAMainUITopBannerWorld:RunAni(isShow, isAni, delay)
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
    if delay <= 0 then 
        local cmd = self:getAnimationCmd(aniTar)
        cmd()
    else
        performWithDelay(self:getRootNode(), self:getAnimationCmd(aniTar), delay)   
    end
end

function RAMainUITopBannerWorld:getAnimationCmd(name)
    local ccbi = self:getRootNode()
    return function()
        if ccbi ~= nil then
            ccbi:runAnimation(name)
        else
            CCLuaLog("RAMainUITopBannerWorld:getAnimationCmd ccbi is nil")
        end
    end
end

function RAMainUITopBannerWorld:onExactSearchBtn()
    if RARootManager.GetIsInWorld() then
        RAWorldManager:SearchCoordinate()
    end
end

function RAMainUITopBannerWorld:onFavoritesBtn()
    if RARootManager.GetIsInWorld() then
        RARootManager.OpenPage('RAWorldFavoritesPage')
    end
end

function RAMainUITopBannerWorld:onVipBtn()
    CCLuaLog("RAMainUITopBannerCity:onVipBtn")
	RARootManager.OpenPage("RAVIPMainPage",nil,true, true, false)
end

--[[
    desc: 增加体力按钮
]]--
function RAMainUITopBannerWorld:onGetStrengthBtn()
    local RACommandManage=RARequire("RACommandManage")

    local state=RACommandManage:getCommanderState()
    if state and state>0 then return end  

    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack)
end

function RAMainUITopBannerWorld:onWorldMapBtn()
    if RARootManager.GetIsInWorld() then
        RAWorldManager:OpenMiniMap()
    end
end

--[[
    desc: 点击头像
]]--
function RAMainUITopBannerWorld:onUserBtn()
    RARootManager.OpenPage("RALordMainPage", nil ,true, true)
end

function RAMainUITopBannerWorld:onCapitalBtn()
    if RARootManager.GetIsInWorld() then
        RAWorldManager:LocateCapital()
    end
end

--打开支付面板
function RAMainUITopBannerWorld:onDiamondsBtn()
    local RANetUtil = RARequire("RANetUtil")
    local msg = Recharge_pb.FetchRechargeInfo()
    RANetUtil:sendPacket(HP_pb.FETCH_RECHARGE_INFO, msg)
end

function RAMainUITopBannerWorld:onGetStrengthBtn()
    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack)
end

function RAMainUITopBannerWorld:Exit()
    CCLuaLog("RAMainUITopBannerWorld:Exit")
    UIExtend.unLoadCCBFile(self)
    self:resetData()
end

--点击矿石资源按钮
function RAMainUITopBannerWorld:onGetGoldBtn()
    local data={}
    data.resourceType = 14
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击石油资源按钮
function RAMainUITopBannerWorld:onGetOilBtn()
    local data={}
    data.resourceType = 17
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击钢铁资源按钮
function RAMainUITopBannerWorld:onGetSteelBtn()
    local data={}
    data.resourceType = 16
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end
--点击合金资源按钮
function RAMainUITopBannerWorld:onGetRareEarthsBtn()
    local data={}
    data.resourceType = 15
    RARootManager.OpenPage("RAReposityPage",data,false, true)
end


--获取一些玩家属性的世界坐标
function RAMainUITopBannerWorld:getAttributePos()

    local tb={}
    tb["Default"]=RACcp(0,CCDirector:sharedDirector():getOpenGLView():getVisibleSize().height)

    local node=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mDiamondsNum")
    local pos=ccp(node:getPosition())
    local worldPos=node:getParent():convertToWorldSpace(pos)
    tb["Diamond"]=RACcp(worldPos.x,worldPos.y)


    node=UIExtend.getCCLabelBMFontFromCCB(self.ccbfile,"mVIPTex")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["VIP"]=RACcp(worldPos.x,worldPos.y)

    node=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mStrengthNum")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["VIT"]=RACcp(worldPos.x,worldPos.y)


    node=UIExtend.getCCNodeFromCCB(self.ccbfile,"mExpBarNode")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["EXP"]=RACcp(worldPos.x,worldPos.y)


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


