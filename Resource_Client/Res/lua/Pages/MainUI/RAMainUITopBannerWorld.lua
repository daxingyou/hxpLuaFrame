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
RAMainUITopBannerWorld.lastData = {
    mLastGold = 0, -- 钻石
    mLastVit = -1,   -- 体力
    mLastVitMax = -1,   -- 体力上限
    mLastGoldore = 0,   -- 金矿
    mLastOil = 0,   -- 石油
    mLastSteel = 0,   -- 钢铁
    mLastTombarthite = 0,   -- 稀土

}

RAMainUITopBannerWorld.actionMap = {
    mDiamondsNum = nil, 
    mGoldNum = nil,   -- 金矿
    mOilNum = nil,   -- 石油
    mSteelNum = nil,   -- 钢铁
    mRareEarthsNum = nil,   -- 稀土    
}

function RAMainUITopBannerWorld:resetData()
    self.mChangeCount = 0
    self.mIsShow = false
    self.lastData = {
        mLastGold = 0, -- 钻石
        mLastVit = -1,   -- 体力
        mLastVitMax = -1,   -- 体力上限
        mLastGoldore = 0,   -- 金矿
        mLastOil = 0,   -- 石油
        mLastSteel = 0,   -- 钢铁
        mLastTombarthite = 0,   -- 稀土
    }
    self.actionMap = {
        mDiamondsNum = nil, 
        mGoldNum = nil,   -- 金矿
        mOilNum = nil,   -- 石油
        mSteelNum = nil,   -- 钢铁
        mRareEarthsNum = nil,   -- 稀土    
    }
    self:unregisterMessageHandlers()
end

function RAMainUITopBannerWorld:Enter(data)
    self:resetData()
	CCLuaLog("RAMainUITopBannerWorld:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUITopBannerWorld.ccbi",RAMainUITopBannerWorld)
	
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
    end
end

function RAMainUITopBannerWorld:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage
end

function RAMainUITopBannerWorld:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage

end

function RAMainUITopBannerWorld:refreshBasicData()
    local info = RAPlayerInfoManager.getPlayerBasicInfo()
    -- UIExtend.setCCLabelString(self:getRootNode(), "mDiamondsNum", RALogicUtil:num2k(info.gold))    
    
    -- UIExtend.setCCLabelString(self:getRootNode(), "mGoldNum", RALogicUtil:num2k(info.goldore)) 
    -- UIExtend.setCCLabelString(self:getRootNode(), "mOilNum", RALogicUtil:num2k(info.oil))
    -- UIExtend.setCCLabelString(self:getRootNode(), "mSteelNum", RALogicUtil:num2k(info.steel))
    -- UIExtend.setCCLabelString(self:getRootNode(), "mRareEarthsNum", RALogicUtil:num2k(info.tombarthite))

    --资源按大本等级显示
    local Const_pb = RARequire("Const_pb")   
    --钢材
    UIExtend.setNodeVisible(self:getRootNode(), 'mSteelNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.STEEL))
    --合金
    UIExtend.setNodeVisible(self:getRootNode(), 'mRareEarthsNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.TOMBARTHITE))

    self:checkLabelAndUpdate("mDiamondsNum", self.lastData.mLastGold, RAPlayerInfoManager.getPlayerBasicInfo().gold, false, 0)
    self.lastData.mLastGold = RAPlayerInfoManager.getPlayerBasicInfo().gold

    self:checkLabelAndUpdate("mGoldNum", self.lastData.mLastGoldore, RAPlayerInfoManager.getPlayerBasicInfo().goldore, true, 1)
    self.lastData.mLastGoldore = RAPlayerInfoManager.getPlayerBasicInfo().goldore

    self:checkLabelAndUpdate("mOilNum", self.lastData.mLastOil, RAPlayerInfoManager.getPlayerBasicInfo().oil, true, 1) 
    self.lastData.mLastOil = RAPlayerInfoManager.getPlayerBasicInfo().oil

    self:checkLabelAndUpdate("mSteelNum", self.lastData.mLastSteel, RAPlayerInfoManager.getPlayerBasicInfo().steel, true, 1)    
    self.lastData.mLastSteel = RAPlayerInfoManager.getPlayerBasicInfo().steel

    self:checkLabelAndUpdate("mRareEarthsNum", self.lastData.mLastTombarthite, RAPlayerInfoManager.getPlayerBasicInfo().tombarthite, true, 1)    
    self.lastData.mLastTombarthite = RAPlayerInfoManager.getPlayerBasicInfo().tombarthite

    local vitMax = RAPlayerInfoManager.getPlayerVitMax()
    if self.lastData.mLastVit ~= info.power or self.lastData.mLastVitMax ~= vitMax then
        self:refreshVitBar(info.power, vitMax)
    end
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
                label:setString(RALogicUtil:numCutAfterDot(newValue, dotCount))
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

    local barNode = UIExtend.getCCNodeFromCCB(self:getRootNode(), "mStrengthBar")
    local percent = targetVit/vitMax    
    if percent > 1 then percent = 1 end    
    barNode:setScaleX(percent)
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

function RAMainUITopBannerWorld:onWorldMapBtn()
    if RARootManager.GetIsInWorld() then
        RAWorldManager:OpenMiniMap()
    end
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


    node=UIExtend.getCCLabelBMFontFromCCB(self.ccbfile,"mStrengthNum")
    worldPos=node:getParent():convertToWorldSpace(ccp(node:getPosition()) )
    tb["VIT"]=RACcp(worldPos.x,worldPos.y)

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


