--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire("UIExtend")
local RAStringUtil = RARequire("RAStringUtil")
local RAGameConfig = RARequire("RAGameConfig")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RABuildManager = RARequire('RABuildManager')
local RAMailManager  =RARequire('RAMailManager')
local RATaskManager = RARequire('RATaskManager')
local mission_conf = RARequire('mission_conf')
local Const_pb = RARequire('Const_pb')
local RAGuideManager = RARequire("RAGuideManager")
local guide_conf = RARequire("guide_conf")
local Mission_pb = RARequire("Mission_pb")
local RANetUtil = RARequire("RANetUtil")
local HP_pb = RARequire("HP_pb")
local item_conf = RARequire("item_conf")
local RAResManager = RARequire("RAResManager")
local RAPackageManager = RARequire("RAPackageManager")
local Utilitys = RARequire("Utilitys")
local RAGuideConfig = RARequire("RAGuideConfig")

local RAMainUIBottomBanner = BaseFunctionPage:new(...)

local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"

local BarScaleAniTimeSpend = 2.0

local onReceiveMessage = nil

local MainUIMenuType_Task = RAGameConfig.MainUIMenuType.Task
local MainUIMenuType_Item = RAGameConfig.MainUIMenuType.Item
local MainUIMenuType_Mail = RAGameConfig.MainUIMenuType.Mail
local MainUIMenuType_Menu = RAGameConfig.MainUIMenuType.Menu
local MainUIMenuType_Alliance = RAGameConfig.MainUIMenuType.Alliance
local MainUIMenuType_AllianceHelp = RAGameConfig.MainUIMenuType.AllianceHelp

local menu_type_to_name = {}
menu_type_to_name[MainUIMenuType_Task] = 
{
    node = "mTaskTipsNode",
    pic = "mTaskTipsPic",
    label = "mTaskTipsNum",
}
menu_type_to_name[MainUIMenuType_Item] = 
{
    node = "mPackageTipsNode",
    pic = "mPackageTipsPic",
    label = "mPackageTipsNum",
}
menu_type_to_name[MainUIMenuType_Mail] = 
{
    node = "mMailTipsNode",
    pic = "mMailTipsPic",
    label = "mMailTipsNum",
}
menu_type_to_name[MainUIMenuType_Alliance] = 
{
    node = "mAllianceTipsNode",
    pic = "mAllianceTipsPic",
    label = "mAllianceTipsNum",
}

menu_type_to_name[MainUIMenuType_Menu] = 
{
    node = "mMenuTipsNode",
    pic = "mMenuTipsPic",
    label = "mMenuTipsNum",
}

menu_type_to_name[MainUIMenuType_AllianceHelp] = 
{
    node = "mActivityTipsNode",
    pic = "mActivityTipsPic",
    label = "mActivityTipsNum",
}



RAMainUIBottomBanner.mUISceneType = SceneTypeList.NoneScene
RAMainUIBottomBanner.mChangeCount = 0
RAMainUIBottomBanner.mIsShow = false
RAMainUIBottomBanner.mMenuTipNum = {}
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_Task] = 0
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_Item] = 0
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_Mail] = 0
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_Menu] = 0
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_Alliance] = 0
RAMainUIBottomBanner.mMenuTipNum[MainUIMenuType_AllianceHelp] = 0
RAMainUIBottomBanner.netHandler = {}
RAMainUIBottomBanner.taskCCB = nil
RAMainUIBottomBanner.rewardTaskId = nil
RAMainUIBottomBanner.guideElecCCB = nil
RAMainUIBottomBanner.showHelperTipes = false
RAMainUIBottomBanner.guideElecCCBHandler = {
    OnAnimationDone = function (_, ccbfile)
	    local lastAnimationName = ccbfile:getCompletedAnimationName()	    
        if lastAnimationName == "UpAni" then
            RAGuideManager.gotoNextStep()
            UIExtend.releaseCCBFile(RAMainUIBottomBanner.guideElecCCB)
            RAMainUIBottomBanner.guideElecCCB = nil
        end
    end
}
RAMainUIBottomBanner.guideTaskCCB = nil
RAMainUIBottomBanner.guideTaskCCBHandler = {
}
-- 核弹显示
RAMainUIBottomBanner.mNuclearHandler = nil

RAMainUIBottomBanner.lastData = {
    mLastElectricMaxOwn = 0, -- 当前上限
    mLastElectric = 0, -- 当前使用了的电量
    mLastElectricMaxCfg = 0, -- 当前主城决定的上限
}


function RAMainUIBottomBanner:resetData()
    self.mUISceneType = SceneTypeList.NoneScene
    self.mChangeCount = 0
    self.mIsShow = false
    self.mMenuTipNum = {}
    self.mMenuTipNum[MainUIMenuType_Task] = 0
    self.mMenuTipNum[MainUIMenuType_Item] = 0
    self.mMenuTipNum[MainUIMenuType_Mail] = 0
    self.mMenuTipNum[MainUIMenuType_Menu] = 0
    self.mMenuTipNum[MainUIMenuType_Alliance] = 0
    self.mMenuTipNum[MainUIMenuType_AllianceHelp] = 0
    -- self:resetBarData()

    local resetHandlerFunc = function(handler)
        if handler ~= nil then
            handler:Exit()
        end        
    end
    resetHandlerFunc(self.mNuclearHandler)
    self.mNuclearHandler = nil
    self.mAddPowerAniCCB = nil
end

function RAMainUIBottomBanner:resetBarData()
    self.lastData = {
        mLastElectricMaxOwn = 0, -- 当前上限
        mLastElectric = 0, -- 当前使用了的电量
        mLastElectricMaxCfg = 0, -- 当前主城决定的上限
    }

    if self.mFrontBar and self.mBarSizeHeight then
        self.mFrontBar:setScaleY(1 * self.mBarSizeHeight)
    end

    if self.mYellowPowerBar then        
        self.mYellowPowerBar:setScaleY(0)
    end

    if self.mRedPowerBar then
        self.mRedPowerBar:setScaleY(0)
    end
end

function RAMainUIBottomBanner:Enter(data)
    self:resetData()
	CCLuaLog("RAMainUIBottomBanner:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUIBottomBanner.ccbi",RAMainUIBottomBanner)
    self.ccbfile = ccbfile
	
    if data ~= nil then
        for k,v in pairs(data) do
            print(k,v)
            CCLuaLog("RAMainUIBottomBanner:Enter  k="..k.." v="..v)
        end
    end
    -- self:ChangeShowStatus(true, true, 1)

    self.mBottomCityNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBottomCityNode")
    self.mBottomWorldNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBottomWorldNode")

    --基地增益状态显示页面Node,先隐藏
    self.mCityGainNode = UIExtend.getCCNodeFromCCB(ccbfile, "mCityGainNode")
    self.mActivityNode = UIExtend.getCCNodeFromCCB(ccbfile, "mActivityNode")


    --小助手按钮
    self.mLittleHelperNode = UIExtend.getCCNodeFromCCB(ccbfile, "mLittleHelperNode")
    UIExtend.setNodeVisible(ccbfile,"mLittleHelperTipsNode", false)

    self.mNuclearCDNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNuclearCDNode")
    self.mNuclearCityPosNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNuclearCityPosNode")
    self.mNuclearWorldPosNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNuclearWorldPosNode")

    if self.mCityGainNode and self.mActivityNode and self.mNuclearCDNode and self.mLittleHelperNode then
        if RAGuideManager.isInGuide() then
            self.mCityGainNode:setVisible(false)
            self.mActivityNode:setVisible(false)
            self.mLittleHelperNode:setVisible(false)
            self.mNuclearCDNode:setVisible(false)
        else
            self.mCityGainNode:setVisible(true)
            self.mActivityNode:setVisible(true)
            local RASettingMainConfig = RARequire('RASettingMainConfig')
            local isShowHelper = CCUserDefault:sharedUserDefault():getStringForKey(RASettingMainConfig.option_showGameHelper)            
            self.mLittleHelperNode:setVisible(isShowHelper ~= "0")
            self.mNuclearCDNode:setVisible(true)
        end

        self.mActivityNode:setVisible(false)
    end

    --查找领地的按钮 
    self.mSearchBtnNode = UIExtend.getCCNodeFromCCB(ccbfile, "mSearchBtnNode")


    -- 三个进度条
    self.mBarSizeNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarSizeNode")
    self.mBarSizeHeight = self.mBarSizeNode:getContentSize().height
    self.mFrontBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mFrontBar")
    self.mYellowPowerBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mYellowPowerBar")
    self.mRedPowerBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mRedPowerBar")
    self.taskCCB = UIExtend.getCCBFileFromCCB(ccbfile, "mTargetTipsNode")

    --联盟按钮
    self.mAllianceBtn = UIExtend.getCCSpriteFromCCB(ccbfile, 'mAllianceFlagSprite')
    self:updateAllianceFlag()
    
    -- 电力条动画ccb
    self.mAddPowerAniCCB = UIExtend.getCCBFileFromCCB(ccbfile, "mAddPowerAniCCB")
    
    --闪红的警报
    self.waringNode = UIExtend.getCCNodeFromCCB(ccbfile,'mWarningNode')
    self.waringCCBFile = UIExtend.getCCBFileFromCCB(ccbfile,'mWarningCCB')
    self.waringCCBFile:registerFunctionHandler(self)
    -- self.waringNode:setVisible(true)


    self:resetBarData()
    self:updateElectric(false)

    self:registerMessageHandlers()
    self:registerNetHandler()

    -- 刷一遍tips
    self:changeMenuTipsNum(MainUIMenuType_Task, self.mMenuTipNum[MainUIMenuType_Task], true)
    self:changeMenuTipsNum(MainUIMenuType_Item, self.mMenuTipNum[MainUIMenuType_Item], true)
    self:changeMenuTipsNum(MainUIMenuType_Mail, self.mMenuTipNum[MainUIMenuType_Mail], true)
    self:changeMenuTipsNum(MainUIMenuType_Menu, self.mMenuTipNum[MainUIMenuType_Menu], true)
    self:changeMenuTipsNum(MainUIMenuType_Alliance, self.mMenuTipNum[MainUIMenuType_Alliance], true)
    self:changeMenuTipsNum(MainUIMenuType_AllianceHelp, self.mMenuTipNum[MainUIMenuType_AllianceHelp], true)

    -- 隐藏目标
    self:refreshTask()
    --UIExtend.setNodeVisible(ccbfile, "mTargetTipsNode", false)

    --更新Mail数目
    RAMailManager:refreshMainUIBottomMailNum()
    --更新背包小红点
    RAPackageManager:updateMainUIMenuPkgRedPoint()

    local RAAllianceManager =  RARequire('RAAllianceManager')
    RAAllianceManager:refreshAllianceNoticeNum()
    --更新联盟小红点

    -- -- 测试tips
    -- MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,
    --     {
    --         menuType = RAGameConfig.MainUIMenuType.Task,
    --         num = 1,
    --         isDirChange = true
    --     })  

    self:initChatTabState()  

    UIExtend.setNodeVisible(ccbfile, 'mPointer', false)

    -- register nuclear helper
    self.mNuclearHandler = UIExtend.GetPageHandler('RAMainUINuclearHelper', true, 
        {
            nuclearCDNode = self.mNuclearCDNode,
        })


    --每次进到页面检查是否能够取代盟主
    self:isReplaceLeader()
end

function RAMainUIBottomBanner:isReplaceLeader()
    -- body
    local RAAllianceManager = RARequire("RAAllianceManager")
    if RAAllianceManager.selfAlliance and RAAllianceManager.selfAlliance.canImpeachLeader then
        local resultFun = function (isOK)
           if isOK then
                local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
                RAAllianceProtoManager:ReplaceLeader()
           end
        end
        local confirmData =
        {
            labelText = _RALang('@AllianceCanImpeachLeader'),
            resultFun = resultFun,
            yesNoBtn = true
        }
        local RARootManager = RARequire('RARootManager')
        RARootManager.showConfirmMsg(confirmData)
    end
end

function RAMainUIBottomBanner:setLittleHelperNodeShow( isShow )
    if RAMainUIBottomBanner.mLittleHelperNode then
        RAMainUIBottomBanner.mLittleHelperNode:setVisible(isShow == true)
    end
end

function RAMainUIBottomBanner:updateAllianceFlag()
    local RAAllianceUtility = RARequire('RAAllianceUtility')
    local RAAllianceManager = RARequire('RAAllianceManager')

    if RAAllianceManager.selfAlliance == nil then 
        self.mAllianceBtn:setTexture(RAAllianceUtility:getAllianceFlagIdByIcon(5))
    else
        self.mAllianceBtn:setTexture(RAAllianceUtility:getAllianceFlagIdByIcon(RAAllianceManager.selfAlliance.flag))
    end
end

--显示闪红的按钮
function RAMainUIBottomBanner:setWaringNodeVisible(isVisible)

    if RAGuideManager:isInGuide() then 
        self.waringNode:setVisible(false)
    else 
        self.waringNode:setVisible(isVisible)
    end 
end

function RAMainUIBottomBanner:onWarningBtn()

    if RAGuideManager.isInGuide() == true then 
        return 
    end 

    local RABuildManager = RARequire('RABuildManager')
    local datas =  RABuildManager:getBuildDataArray(Const_pb.RADAR)
    if #datas == 0 then 
        RARootManager.ShowMsgBox(_RALang("@DonotHaveRadar"))
    else 
        RARootManager.OpenPage("RARadarWarningPage", datas[1],true,true)
    end 
end


onReceiveMessage = function(msg)
    if msg.messageID == MessageDef_MainUI.MSG_UpdateWorldCoordinate then
        if RARootManager.GetIsInWorld() then
            RAMainUIBottomBanner:showWorldCoordinate(msg.x, msg.y, msg.k)
        end
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_HAS_UNLOCK_BUILD then
        local mainCityLvl = RABuildManager:getMainCityLvl()
        if RARootManager.GetIsInCity() and ((not RAGuideManager.isInGuide()) or (RAGuideManager.isInGuide() and mainCityLvl >= RAGuideConfig.ConsBtnTwinkleMaincityLvl)) then
            RAMainUIBottomBanner.ccbfile:getCCBFileFromCCB("mConstructionAniCCB"):setVisible(true)
            -- CCB里已经设置了默认播放只需要显示就好 
            -- RAMainUIBottomBanner.ccbfile:getCCBFileFromCCB("mConstructionAniCCB"):runAnimation("ConstructionAni")
        end
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_ShowTaskGuild then
        if RAMainUIBottomBanner.guideTaskCCB == nil then
            RAMainUIBottomBanner.guideTaskCCB = UIExtend.loadCCBFile("Ani_Guide_ArrowAni.ccbi", RAMainUIBottomBanner.guideTaskCCBHandler)
            UIExtend.addNodeToParentNode(RAMainUIBottomBanner.ccbfile, "mTipsFinger", RAMainUIBottomBanner.guideTaskCCB)
            RAMainUIBottomBanner.guideTaskCCB:setZOrder(10086)
            -- RAMainUIBottomBanner.guideTaskCCB:setPosition(50,50)
        end
        RAMainUIBottomBanner.guideTaskCCB:runAnimation("KeepAni")
        return
    end    
    if msg.messageID == MessageDef_MainUI.MSG_HideTaskGuild then
        if RAMainUIBottomBanner.guideTaskCCB ~= nil then
            RAMainUIBottomBanner.guideTaskCCB:stopAllActions()
            UIExtend.releaseCCBFile(RAMainUIBottomBanner.guideTaskCCB)
            RAMainUIBottomBanner.guideTaskCCB = nil
        end
        return
    end  
    if msg.messageID == MessageDef_MainUI.MSG_ShowHelperTips then
        local ccbfile = RAMainUIBottomBanner.ccbfile
        RAMainUIBottomBanner.showHelperTipes = true
        UIExtend.setNodeVisible(ccbfile, "mBubbleNode", true)
        local const_conf = RARequire("const_conf")
        local strIndex = math.random(const_conf.HelperTipsNum.value)
        UIExtend.setCCLabelString(ccbfile, "mBubbleLabel", _RALang("@LittleHelper"..strIndex), 12)
        local label = UIExtend.getCCLabelTTFFromCCB(ccbfile, "mBubbleLabel")
        local size = label:getContentSize()
        local bg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBubbleBG")
        bg:setContentSize(CCSize(size.width + 50, size.height + 20))
        return
    end    
    if msg.messageID == MessageDef_MainUI.MSG_HideHelperTips then
        RAMainUIBottomBanner.showHelperTipes = false
        UIExtend.setNodeVisible(RAMainUIBottomBanner.ccbfile, "mBubbleNode", false)
        return
    end      
    

    if msg.messageID == MessageDef_MainUI.MSG_HAS_NO_UNLOCK_BUILD then
        if RARootManager.GetIsInCity() then
            RAMainUIBottomBanner.ccbfile:getCCBFileFromCCB("mConstructionAniCCB"):setVisible(false)
            -- RAMainUIBottomBanner.ccbfile:getCCBFileFromCCB("mConstructionAniCCB"):runAnimation("ConstructionAni")
        end
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_UpdateWorldDirection then
        if RARootManager.GetIsInWorld() then
            RAMainUIBottomBanner:showWorldDirection(msg.distance, msg.degree, msg.hideArrow)
        end
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_ChangeChatNewestMsg then
        --todo
        RAMainUIBottomBanner.mainUIChatMsgs = {}

        local RAChatData = RARequire("RAChatData")
        local RAChatManager = RARequire("RAChatManager")
        for i=1,#msg do
            local data = msg[i]
            if data.type == RAChatData.CHAT_TYPE.broadcast or data.type == RAChatData.CHAT_TYPE.hrefBroadcast then
                --data.type = RAChatData.CHAT_TYPE.world
            end
            if data.hrefCfgName then
                data.content = RAChatManager:getLangByName(data.name,data.hrefCfgName,data.hrefCfgPrams)
            end

            if data.content ~= nil then
                local chatInfo = {}
                chatInfo.name = data.name
                chatInfo.content = data.content
                chatInfo.vip    = data.vip
                chatInfo.guildTag    = data.guildTag
                chatInfo.chatType = data.type
                chatInfo.choosenTab = RAChatManager.mChoosenTab
                chatInfo.index = #msg

                RAMainUIBottomBanner.mainUIChatMsgs[i] = chatInfo

                RAMainUIBottomBanner:changeChatTabState(RAChatManager.mChoosenTab)
            end
        end

        RAMainUIBottomBanner:refreshChatMsg()

        return
    end

    if MessageDef_MainUI.MSG_Chat_change_tab == msg.messageID then
        --todo
        --RAMainUIBottomBanner:updateChatTabAndContent(msg)
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_ChangeMenuTipsNum then
        RAMainUIBottomBanner:changeMenuTipsNum(msg.menuType, msg.num, msg.isDirChange)
        return
    end

    if msg.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        CCLuaLog("MessageDef_MainUI MSG_UpdateBasicPlayerInfo")
        RAMainUIBottomBanner:updateElectric()
        return
    end

    --刷新task
    if msg.messageID == MessageDef_Task.MSG_RefreshMainUITask then
        RAMainUIBottomBanner:refreshTask()
    end

    --刷新联盟标志 
     if msg.messageID == MessageDef_Alliance.MSG_Alliance_Flag_Change then
        RAMainUIBottomBanner:updateAllianceFlag()
    end

    --显示领奖UI
    if msg.messageID == MessageDef_Task.MSG_ShowTaskReward then
        RAMainUIBottomBanner.rewardTaskId = nil
    end

    --新手：xinghui，收到消息显示建筑按钮
    if msg.messageID == MessageDef_Guide.MSG_Guide then
        local constGuideInfo = msg.guideInfo
        local guideId = constGuideInfo.guideId
        local keyWord = constGuideInfo.keyWord

        if keyWord == RAGuideConfig.KeyWordArray.ShowContructionBtn then
            --跑建筑按钮的动画
            RAMainUIBottomBanner.ccbfile:setVisible(true)
            RAMainUIBottomBanner.ccbfile:runAnimation("ConstructionAni")
            RAMainUIBottomBanner.mIsShow = true
        elseif keyWord == RAGuideConfig.KeyWordArray.ShowWalkieTalkie then
            --显示步话机
            RAMainUIBottomBanner.ccbfile:runAnimation("QuestAni")
            RAMainUIBottomBanner.mIsShow = true
            if constGuideInfo.showGuidePage == 1 then
                RARootManager.AddGuidPage({["guideId"] = guideId})
            end
        elseif keyWord == RAGuideConfig.KeyWordArray.showWorldBtn then
            --显示世界按钮
            RAMainUIBottomBanner.ccbfile:runAnimation("WorldBtnAni")
            RAMainUIBottomBanner.ccbfile:getCCNodeFromCCB("mConstrctionBtnNode"):setVisible(false)
            RAMainUIBottomBanner.mIsShow = true
        elseif keyWord == RAGuideConfig.KeyWordArray.PlayMainUIAni then
            --显示所有的按钮
            RAMainUIBottomBanner.ccbfile:getCCNodeFromCCB("mConstrctionBtnNode"):setVisible(true)
            RAMainUIBottomBanner.ccbfile:runAnimation("OtherAni")
            RAMainUIBottomBanner.mIsShow = true
        elseif keyWord == RAGuideConfig.KeyWordArray.CircleTaskBanner then
            if RAMainUIBottomBanner.taskCCB then
                local x,y = RAMainUIBottomBanner.taskCCB:getPosition()
                local pos = ccp(x, y)
                local worldPos = RAMainUIBottomBanner.taskCCB:getParent():convertToWorldSpace(pos)
                local size = RAMainUIBottomBanner.taskCCB:getContentSize()
                worldPos.x = worldPos.x + size.width / 2
                worldPos.y = worldPos.y + size.height / 2
                size.width = size.width + 15
                size.height = size.height + 15
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                pos:delete()
            end
        elseif keyWord == RAGuideConfig.KeyWordArray.ShowElectricLow then
            --显示电量过低的动画
            if RAMainUIBottomBanner.guideElecCCB == nil then
                RAMainUIBottomBanner.guideElecCCB = UIExtend.loadCCBFile("Ani_Guide_BarAni.ccbi", RAMainUIBottomBanner.guideElecCCBHandler)
                UIExtend.addNodeToParentNode(RAMainUIBottomBanner.ccbfile, "mGuidePowerNode", RAMainUIBottomBanner.guideElecCCB)
            end
            
            local pos = ccp(0, 0)
            pos.x, pos.y = RAMainUIBottomBanner.mBarSizeNode:getPosition()
            local contenSize = RAMainUIBottomBanner.mBarSizeNode:getContentSize()
            local worldPos = RAMainUIBottomBanner.mBarSizeNode:getParent():convertToWorldSpace(pos)
            worldPos.y = worldPos.y + contenSize.height * 0.5
            contenSize.width = contenSize.width + 35
            contenSize.height = contenSize.height + 40

            RAMainUIBottomBanner.guideElecCCB:runAnimation("DownAni")
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = contenSize})
        elseif keyWord == RAGuideConfig.KeyWordArray.ShowElectricHigh then
            --显示电量过低的动画
            if RAMainUIBottomBanner.guideElecCCB == nil then
                RAMainUIBottomBanner.guideElecCCB = UIExtend.loadCCBFile("Ani_Guide_BarAni.ccbi", RAMainUIBottomBanner.guideElecCCBHandler)
                UIExtend.addNodeToParentNode(RAMainUIBottomBanner.ccbfile, "mGuidePowerNode", RAMainUIBottomBanner.guideElecCCB)
            end
            
            RAMainUIBottomBanner.guideElecCCB:runAnimation("UpAni")
            RARootManager.AddGuidPage({["guideId"] = guideId})
        elseif keyWord == RAGuideConfig.KeyWordArray.CircleTaskBtn then
            local taskNode = UIExtend.getCCControlButtonFromCCB(RAMainUIBottomBanner.ccbfile, "mTaskBtn")
            if taskNode then
                local x, y = taskNode:getPosition()
                local pos = ccp(x,y)
                local worldPos = taskNode:getParent():convertToWorldSpace(pos)
                local size = taskNode:getContentSize()
                size.width = size.width * 0.592 + 40
                size.height = size.height * 0.592 + 40
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                pos:delete()
            end
        end

    end
    if msg.messageID == MessageDef_Guide.MSG_GuideEnd then
        if RAMainUIBottomBanner.mCityGainNode then
            RAMainUIBottomBanner.mCityGainNode:setVisible(true)
            RAMainUIBottomBanner.mActivityNode:setVisible(false)
            RAMainUIBottomBanner.mLittleHelperNode:setVisible(true)
            RAMainUIBottomBanner.mNuclearCDNode:setVisible(true)
        end
    end 

    if msg.messageID == MessageDef_Packet.MSG_Operation_OK then
        local opcode = msg.opcode
        if opcode == HP_pb.GUILDMANAGER_IMPEACHMENTLEADER_C then --取代盟主成功
            RARootManager.ShowMsgBox(_RALang("@ReplaceLeaderSuccess"))
        elseif opcode == HP_pb.GUILDMANAGER_HELPALLQUEUES_C then
            RARootManager.ShowMsgBox(_RALang("@AllianceHelpAll"))     
            
            local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
            RAAllianceProtoManager:sendGetHelpInfoReq()
        end            
    end       
end

function RAMainUIBottomBanner:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateWorldCoordinate, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateWorldDirection, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ChangeMenuTipsNum, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ChangeChatNewestMsg, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_Chat_change_tab, onReceiveMessage)--切换聊天tab

    MessageManager.registerMessageHandler(MessageDef_Task.MSG_RefreshMainUITask, onReceiveMessage)--刷新task
    MessageManager.registerMessageHandler(MessageDef_Task.MSG_ShowTaskReward, onReceiveMessage)--刷新task

    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide, onReceiveMessage)--GuideMessage
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_GuideEnd, onReceiveMessage)--GuideEnd
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_HAS_UNLOCK_BUILD, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_HAS_NO_UNLOCK_BUILD, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_Flag_Change, onReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ShowTaskGuild, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_HideTaskGuild, onReceiveMessage)
    
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ShowHelperTips, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_HideHelperTips, onReceiveMessage)   

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,onReceiveMessage) 

end

function RAMainUIBottomBanner:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, onReceiveMessage)  
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateWorldCoordinate, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateWorldDirection, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ChangeMenuTipsNum, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ChangeChatNewestMsg, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_Chat_change_tab, onReceiveMessage)--切换聊天tab

    MessageManager.removeMessageHandler(MessageDef_Task.MSG_RefreshMainUITask, onReceiveMessage)--刷新task
    MessageManager.removeMessageHandler(MessageDef_Task.MSG_ShowTaskReward, onReceiveMessage)--刷新task

    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide, onReceiveMessage)--GuideMessage
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_HAS_UNLOCK_BUILD, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_HAS_NO_UNLOCK_BUILD, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_Flag_Change, onReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ShowTaskGuild, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_HideTaskGuild, onReceiveMessage)    

    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ShowHelperTips, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_HideHelperTips, onReceiveMessage)   

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,onReceiveMessage)  
end

--刷新任务显示
function RAMainUIBottomBanner:refreshTask()
    local taskInfo = RATaskManager.getRecommandTask()
    if taskInfo then
        self.taskCCB:setVisible(true)
        UIExtend.setCCControlButtonEnable(self.taskCCB, "mTargetTipsBtn", true)
        if taskInfo.taskState == RAGameConfig.TaskStatus.Complete and self.taskCCB then
            self.taskCCB:runAnimation("CanReceiveAni")
        else 
            self.taskCCB:runAnimation("UnFinishAni")
        end
        local constTaskInfo = mission_conf[taskInfo.taskId]
        if constTaskInfo then
            UIExtend.setCCLabelString(self.taskCCB, "mTargetContentTex", _RALang(constTaskInfo.name))
        else
            CCLuaLog("RAMainUIBottomBanner:refreshTask There is no constTaskInfo")
        end
    else
        self.taskCCB:setVisible(false)
    end

    --显示当前已完成任务数量
    local completeTaskNum = RATaskManager.getCompleteTaskNum()
    if completeTaskNum<=0 then
        UIExtend.setNodeVisible(self.ccbfile, "mTaskTipsNode", false)
    else
        UIExtend.setNodeVisible(self.ccbfile, "mTaskTipsNode", true)
        UIExtend.setCCLabelString(self.ccbfile, "mTaskTipsNum", completeTaskNum)
    end
end


function RAMainUIBottomBanner:getTaskNodePosAndSizeForGuide()
    local posSize = {}
    if self.taskCCB then
        local tmpPos = ccp(0, 0)
        tmpPos.x, tmpPos.y = self.taskCCB:getPosition()
        posSize.pos = self.taskCCB:getParent():convertToWorldSpace(tmpPos)
        tmpPos:delete()

        posSize.size = self.taskCCB:getContentSize()
    end

    return posSize
end

-- 电力发生改变的时候需要调用
-- 页面 CCB_InAni 完成的时候调用
function RAMainUIBottomBanner:updateElectric(isNoAni)
    local isNoAni = isNoAni or false
    -- 当前主城等级对应的电量上限
    local electricCfgMax = RAPlayerInfoManager.getCurrElectricMaxCfgValue()
    -- 当前产电量上限
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    -- 当前用电量
    local currElectricUse = RAPlayerInfoManager.getCurrElectricValue()

    local const_conf = RARequire('const_conf')
    local electric_cap1 = const_conf.electric_cap1.value
    local electric_cap2 = const_conf.electric_cap2.value

    local greenScaleTo = 0
    local yellowScaleTo = 0
    local redScaleTo = 0
    local checkPercent = function(percent)
        if percent < 0 then
            return 0
        end
        if percent > 1 then
            return 1
        end
        return percent
    end
    
    if electricCfgMax == 0 then
        greenScaleTo = 0
    else
        greenScaleTo = (currElectricMax / electricCfgMax)
    end
    greenScaleTo = checkPercent(greenScaleTo)

    if currElectricMax == 0 then
        redScaleTo = 0
        yellowScaleTo = 0        
    else
        yellowScaleTo = (currElectricUse / currElectricMax / electric_cap1 * 100) * greenScaleTo
        redScaleTo = (currElectricUse / currElectricMax / electric_cap2 * 100) * greenScaleTo
    end

    redScaleTo = checkPercent(redScaleTo)
    yellowScaleTo = checkPercent(yellowScaleTo)

    local scaleToActionFunc = function(target, scaleToY, time)
        if target ~= nil then
            target:stopAllActions()
            local currScaleY = target:getScaleY()
            if currScaleY ~= scaleToY then
                local action = CCScaleTo:create(time, target:getScaleX(), scaleToY)
                target:runAction(action)
            end
        end
    end

    local isGreenScale = false
    local isYellowScale = false
    local isRedScale = false
    if electricCfgMax ~= self.lastData.mLastElectricMaxCfg or 
        currElectricMax ~= self.lastData.mLastElectricMaxOwn then
        isGreenScale = true
    end
    if currElectricUse ~= self.lastData.mLastElectric or 
        electricCfgMax ~= self.lastData.mLastElectricMaxCfg or 
        currElectricMax ~= self.lastData.mLastElectricMaxOwn then
        isYellowScale = true
    end

    if currElectricUse ~= self.lastData.mLastElectric or 
        electricCfgMax ~= self.lastData.mLastElectricMaxCfg or 
        currElectricMax ~= self.lastData.mLastElectricMaxOwn then
        isRedScale = true
    end

    if isNoAni then
        self.mFrontBar:setScaleY((1 - greenScaleTo) * self.mBarSizeHeight)
        self.mYellowPowerBar:setScaleY(yellowScaleTo * self.mBarSizeHeight)
        self.mRedPowerBar:setScaleY(redScaleTo * self.mBarSizeHeight)   
    else
        if isGreenScale then
            scaleToActionFunc(self.mFrontBar, (1 - greenScaleTo) * self.mBarSizeHeight, BarScaleAniTimeSpend * greenScaleTo)        
        end
        if isYellowScale then
            scaleToActionFunc(self.mYellowPowerBar, yellowScaleTo * self.mBarSizeHeight, BarScaleAniTimeSpend * yellowScaleTo)
        end
        if isRedScale then
            scaleToActionFunc(self.mRedPowerBar, redScaleTo * self.mBarSizeHeight, BarScaleAniTimeSpend * redScaleTo)
        end
    end

    self.lastData.mLastElectricMaxCfg = electricCfgMax
    self.lastData.mLastElectricMaxOwn = currElectricMax
    self.lastData.mLastElectric = currElectricUse

    --播放电力条变化ccb
    if isGreenScale or isYellowScale or isRedScale then
        if self.mAddPowerAniCCB ~= nil then
            self.mAddPowerAniCCB:setVisible(true)
            self.mAddPowerAniCCB:runAnimation(CCB_InAni)
        end
    end
end


function RAMainUIBottomBanner:UpdateUIByScene(showType)
    --新手期不做这些操作
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowAllMainUI()) then
        return
    end

    if self.mUISceneType == showType then
        return
    end
    self.mUISceneType = showType


    if self.mUISceneType == SceneTypeList.CityScene then 
        self.mBottomCityNode:setVisible(true)
        self.mBottomWorldNode:setVisible(false)
        self.mSearchBtnNode:setVisible(false)
        local RASettingMainConfig = RARequire('RASettingMainConfig')
        local isShowHelper = CCUserDefault:sharedUserDefault():getStringForKey(RASettingMainConfig.option_showGameHelper)
        print("isShowHelper = ", isShowHelper ~= "0")
        self.mLittleHelperNode:setVisible(isShowHelper ~= "0")
        if self.mNuclearCDNode ~= nil and self.mNuclearCityPosNode ~= nil then
            self.mNuclearCDNode:setPosition(self.mNuclearCityPosNode:getPosition())
        end

    elseif self.mUISceneType == SceneTypeList.WorldScene then 
        self.mBottomCityNode:setVisible(false)
        self.mBottomWorldNode:setVisible(true)
        
        if self.mNuclearCDNode ~= nil and self.mNuclearWorldPosNode ~= nil then
            self.mNuclearCDNode:setPosition(self.mNuclearWorldPosNode:getPosition())
        end
        -- local RAAllianceManager = RARequire('RAAllianceManager')

        -- if RAAllianceManager.selfAlliance == nil then 
        --     self.mSearchBtnNode:setVisible(false)
        -- else
            self.mSearchBtnNode:setVisible(true)
            self.mLittleHelperNode:setVisible(false)
        -- end 
    end 
end

--查找页面
function RAMainUIBottomBanner:onFindBtn()    
    CCLuaLog('onFindBtn')
    if RARootManager.GetIsInWorld() then
        RARootManager.OpenPage('RASearchPage', nil, true, true, true)
    end
    -- local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    -- local arr = RATerritoryDataManager:GetAllTerritoryInfo()

    -- local len = #arr
    -- local index = math.random(1,len)

    -- --不选上次选中的
    -- while self.preIndex == index do
    --     index = math.random(1,len)
    -- end 

    -- self.preIndex = index

    -- local data = arr[index]
    -- local RAWorldManager = RARequire('RAWorldManager')
    -- local bastionPos = data.buildingPos[Const_pb.GUILD_BASTION]
    -- RAWorldManager:LocateAtPos(bastionPos.x, bastionPos.y)
end

function RAMainUIBottomBanner:onWorldBtn()
	CCLuaLog("RAMainUIBottomBanner:onWorldBtn")    
    if RARootManager.GetIsInCity() then
        --播放音效
        local common = RARequire("common")
        common:playEffect("into")
        RARootManager.ChangeScene(SceneTypeList.BattleScene)

        --新手期做特殊处理
        if RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
        end

        return
    end
end

--基地增益状态显示按钮回调
function RAMainUIBottomBanner:onCityGainBtn()
    RARootManager.OpenPage("RACityGainPage") 
end

--小助手
function RAMainUIBottomBanner:onLittleHelperBtn()
    RARootManager.OpenPage("RAGameHelperPage", nil, false, true, true)
end

--一键联盟帮助
function RAMainUIBottomBanner:onActivityBtn()
     --RARootManager.OpenPage("RADailyTaskMainPage") 
     local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
     RAAllianceProtoManager:sendHelpAllInfoReq()

     --RARootManager.ShowMsgBox(_RALang('@AllianceHelpAll'))
end

function RAMainUIBottomBanner:onCunstructionBtn()
    CCLuaLog("RAMainUIBottomBanner:onCunstructionBtn")
    RARootManager.OpenPage("RAChooseBuildPage")
    MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
    --移除guidePage:add by xinghui
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
    end
    RARootManager.RemoveGuidePage()
end

function RAMainUIBottomBanner:onAllianceBtn()
    CCLuaLog("RAMainUIBottomBanner:onAllianceBtn")

    -- local RAMainUIQueueShowHelper = RARequire('RAMainUIQueueShowHelper')
    -- RAMainUIQueueShowHelper:RefreshQueueAllCells()
    local RAAllianceManager = RARequire('RAAllianceManager')

    if RAAllianceManager.selfAlliance == nil then 
        RARootManager.OpenPage("RAAllianceJoinPage")
    else
        RARootManager.OpenPage("RAAllianceMainPage")
    end 
end

function RAMainUIBottomBanner:onPackageBtn()
    CCLuaLog("RAMainUIBottomBanner:onPackageBtn")
    RARootManager.OpenPage("RAPackageMainPage")
end

function RAMainUIBottomBanner:onMenuBtn()
    CCLuaLog("RAMainUIBottomBanner:onMenuBtn")
--    local RASettingManager = RARequire("RASettingManager")
--    RASettingManager:switchUser()

    RARootManager.OpenPage("RASettingMainPage")
    --RARootManager.OpenPage("RAWorldMapThreePage")
end

function RAMainUIBottomBanner:onMailBtn()
    CCLuaLog("RAMainUIBottomBanner:onPackageBtn")
    RARootManager.OpenPage("RAMailMainPageV6")
    --RARootManager.OpenPage("RAWorldMapThreePage",nil,true,false,false)
end
function RAMainUIBottomBanner:onHomeBackBtn()
    CCLuaLog("RAMainUIBottomBanner:onHomeBackBtn")
    if RARootManager.GetIsInWorld() then
        RARootManager.ChangeScene(SceneTypeList.CityScene)

        if RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage({["update"] = true})
            RARootManager.RemoveGuidePage()
        end
        return
    end
end

function RAMainUIBottomBanner:onSearchBtn()
    if RARootManager.GetIsInWorld() then
        local RAWorldManager = RARequire('RAWorldManager')
        RAWorldManager:SearchCoordinate()
    end
end

--接受网络数据
function RAMainUIBottomBanner:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.MISSION_BONUS_S then
        local msg = Mission_pb.MissionBonusRes()
        msg:ParseFromString(buffer)
        if msg.removeMissionId ~= 0 then
            RATaskManager.deleteTaskWithMissionId(msg.removeMissionId)
        end
        RATaskManager.addTaskFromServerData(msg)
        --if self.taskCCB then
            --self.taskCCB:runAnimation("ReceiveAni")
        --end
        self:refreshTask()
        MessageManager.sendMessage(MessageDef_Task.MSG_RefreshTaskUITask)
        MessageManager.sendMessage(MessageDef_Task.MSG_ShowTaskReward)
    end
end

--添加网络监听
function RAMainUIBottomBanner:registerNetHandler()
    self.netHandler[#RAMainUIBottomBanner.netHandler + 1] = RANetUtil:addListener(HP_pb.MISSION_BONUS_S, RAMainUIBottomBanner)
end

function RAMainUIBottomBanner:unRegisterNetHandler()
    --取消packet监听
    for k, value in pairs(self.netHandler) do
        if self.netHandler[k] ~= nil then
             RANetUtil:removeListener(self.netHandler[k])
             self.netHandler[k] = nil
        end
    end
    self.netHandler = {}
end

function RAMainUIBottomBanner:mTargetTipsNode_onTargetTipsBtn()
    local taskInfo = RATaskManager.getRecommandTask()
    if taskInfo then
        
        RARootManager.RemoveGuidePage()--移除guidepage
        RARootManager.RemoveCoverPage()
        if taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
            --领取奖励
            if self.taskCCB then
                --本应该在收到回包之后播放动画，但是如果依然有待领取的任务，那么待领取动画会挤掉获奖动画。
                self.taskCCB:runAnimation("ReceiveAni")
            end

            UIExtend.setCCControlButtonEnable(self.taskCCB, "mTargetTipsBtn", false)
            local msg = Mission_pb.MissionBonusReq()
            msg.missionId = taskInfo.missionId
            RANetUtil:sendPacket(HP_pb.MISSION_BONUS_C, msg)
            self.rewardTaskId = taskInfo.taskId--保存领奖的taskId
            
            --播放音效 by phan
            local common = RARequire("common")
            common:playEffect("click_main_botton_collectReward")

            if RAGuideManager.isInGuide() then
                RARootManager.AddCoverPage()
                RARootManager.RemoveGuidePage()
            end

            return
        end

        if RAGuideManager.isInGuide() and RAGuideConfig.guideTaskIds[taskInfo.taskId] == 1 then
            --新手特殊处理的任务id
            RARootManager.AddCoverPage({["update"] = true})
            RAGuideManager.gotoNextStep()
        else
            local constTaskInfo = mission_conf[taskInfo.taskId]
            if constTaskInfo then
                RATaskManager.gotoTaskTarget(constTaskInfo)
            else
                CCLuaLog("RAMainUIBottomBanner:refreshTask There is no constTaskInfo")
            end
        end
        
    else
        CCLuaLog("RAMainUIBottomBanner:refreshTask There is no taskInfo")
    end
end

function RAMainUIBottomBanner:onCheckBtn()
    if RARootManager.GetIsInWorld() then
        RARequire('RAWorldManager'):LocateHome()
    end
end

function RAMainUIBottomBanner:onTaskBtn()
    RARootManager.OpenPage("RATaskMainPage", nil,true,true,false)
end

-- isDirChange default = false
function RAMainUIBottomBanner:changeMenuTipsNum(menuType, num, isDirChange)
    local isDirChange = isDirChange or false
    if self.mMenuTipNum[menuType] == nil then
        return
    end

    if isDirChange then
        self.mMenuTipNum[menuType] = num
    else
        self.mMenuTipNum[menuType] = self.mMenuTipNum[menuType] + num
    end
    local lastNum = self.mMenuTipNum[menuType]
    local isShowTip = true
    if lastNum <= 0 then
        isShowTip = false
        lastNum = 0
        self.mMenuTipNum[menuType] = 0

        if menuType == MainUIMenuType_AllianceHelp or menuType == MainUIMenuType_Alliance then
            self.mActivityNode:setVisible(false)
        end
    else
        if menuType == MainUIMenuType_AllianceHelp or menuType == MainUIMenuType_Alliance then
            self.mActivityNode:setVisible(true)
        end
    end
    UIExtend.setNodeVisible(self:getRootNode(), menu_type_to_name[menuType].node, isShowTip)
    UIExtend.setCCLabelString(self:getRootNode(), menu_type_to_name[menuType].label, tostring(lastNum))
end

--聊天按钮
function RAMainUIBottomBanner:onChatPageBtn()
    -- body
    CCLuaLog("RAMainUIBottomBanner:onChatPageBtn")
    RARootManager.OpenPage("RAChatUIPage")
end


function RAMainUIBottomBanner:refreshChatMsg()
    -- body
    for i = 1,#self.mainUIChatMsgs do
        local data = self.mainUIChatMsgs[i]
        if data == nil then return end

        local maohaoStr = " : "
        local nameStr = ""
        local choosenType = data.chatType
        --类型
        local RAChatData = RARequire("RAChatData")
        if data.chatType == RAChatData.CHAT_TYPE.broadcast then
            nameStr = _RALang('@MainUISelfNotice')
            choosenType = RAChatData.CHAT_TYPE.world   
        elseif data.chatType == RAChatData.CHAT_TYPE.hrefBroadcast or data.name == "" then
            nameStr = _RALang('@MainUISysNotice')
            choosenType = RAChatData.CHAT_TYPE.world  
        end

        if data.vip and data.vip > 0 then
            nameStr = nameStr .. "VIP " .. data.vip
        end
        if data.guildTag and data.guildTag ~= "" then
            nameStr = nameStr .. " (" .. data.guildTag ..") "
        end
        if data.name ~= "" then
            nameStr = nameStr .. " "..data.name
        end

        if nameStr == "" then
            maohaoStr = ""
        end

        local content = nameStr..maohaoStr..data.content

        if choosenType ~= data.choosenTab then
            return
        end

        local mChatTex1 = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mChatTex")
        local mChatTex2 = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mChatTex2")

        if i == 1 then
            mChatTex1:setString("")
            mChatTex2:setString("")

            mChatTex2:setString(content)
            RAStringUtil:resetHTMLStringWidth(mChatTex2, 600)--465)
        else
            mChatTex1:setString(content)
            RAStringUtil:resetHTMLStringWidth(mChatTex1, 600)--465)    
        end
    end
end


function RAMainUIBottomBanner:initChatTabState()
    -- body
    local RAChatManager = RARequire("RAChatManager")
    self:changeChatTabState(RAChatManager.mChoosenTab)
end

--聊天界面打开时，切换频道时触发
function RAMainUIBottomBanner:updateChatTabAndContent(msg)
    --body
    --{content = content, name = name, chatType=chatType, mChoosenTab=self.mChoosenTab}
    -- self:changeChatTabState(msg.mChoosenTab)
    -- -- local maohaoStr = ":"
    -- -- if msg.name == "" then
    -- --     maohaoStr = ""
    -- -- end
    -- --local content = msg.name..maohaoStr..msg.content
    -- local content = msg.content
    -- if msg.hrefCfgName then
    --     content = msg.content
    -- end
    -- if msg.hrefCfgName then
    --     local RAChatManager = RARequire("RAChatManager")
    --     content = RAChatManager:getLangByName(msg.name,msg.hrefCfgName,msg.hrefCfgPrams)
    -- end

    -- --local chatType = msg.chatType
    -- --local choosenTab = msg.mChoosenTab

    -- if self.mainUIChatMsgs[1] == nil then
    --     self.mainUIChatMsgs[1] = {}
    -- end

    -- local chatInfo = {}
    -- chatInfo.name = msg.name
    -- chatInfo.content = content
    -- chatInfo.vip    = msg.vip
    -- chatInfo.guildTag    = msg.guildTag
    -- chatInfo.chatType = msg.chatType
    -- chatInfo.choosenTab = msg.mChoosenTab
    -- chatInfo.isChangeTab = true
    -- chatInfo.index = 1

    -- self.mainUIChatMsgs[1] = chatInfo
    -- self:refreshChatMsg()
end

function RAMainUIBottomBanner:changeChatTabState(choosenTab)
    -- body 现在ui还是sprite不是button  
    
    local btnNameVec = {"mChatChannel_1", "mChatChannel_2"}
     
    local index = 1 + choosenTab
    for i=1,#btnNameVec do
        --print(i)
        local isHightLighted = false
        if i == index then
            --todo
            isHightLighted = true
        end
        UIExtend.setNodeVisible(self.ccbfile,btnNameVec[i],isHightLighted)
    end
    
end


function RAMainUIBottomBanner:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	    
    self:AniEnd(lastAnimationName)
end


function RAMainUIBottomBanner:ChangeShowStatus(isShow, isAni, delay)
    if self.mChangeCount > 0 then
        CCLuaLog("RAMainUIBottomBanner is moving. count:"..self.mChangeCount)
        return
    end
    if self.mIsShow == isShow then
        return
    end

    self.mChangeCount = 1
    self.mIsShow = isShow
    self:RunAni(self.mIsShow, isAni, delay)
end


function RAMainUIBottomBanner:AniEnd(aniName)
    local isHandle = false
    if self.mIsShow and aniName == CCB_InAni then                
        isHandle = true        
        self:updateElectric()
        
    end
    --新手：xinghui 进入动画播放完毕，发送下一步新手信息
    if aniName == "ConstructionAni"  then
            RAGuideManager.gotoNextStep()
            isHandle = true
    elseif aniName == "PowerAni"  then
            self.ccbfile:runAnimation("ConstructionAni")
            self.mIsShow = true
    end

    if aniName == "OtherAni" or aniName == "WorldBtnAni" then
        RAGuideManager.gotoNextStep()
        isHandle = true
    end
       
    if not self.mIsShow and aniName == CCB_OutAni then              
        isHandle = true
        -- self:resetBarData()
    end

    if isHandle then
        self.mChangeCount = self.mChangeCount - 1
        CCLuaLog("CellAniEnd   cell cout:"..self.mChangeCount)    
    end
end


function RAMainUIBottomBanner:RunAni(isShow, isAni, delay)
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

    --新手之后才会把所有的bottom UI展现出来，所在在此之前，不播放动画
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowAllMainUI()) and aniName == CCB_InAni then
        return
    end
    --新手期间不播放OutAni动画，以KeepOut代替
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowAllMainUI()) and aniName == CCB_OutAni then
        self.ccbfile:runAnimation(CCB_KeepOut)
        return
    end

    if delay <= 0 then 
        local cmd = self:getAnimationCmd(aniTar)
        cmd()
    else
        performWithDelay(self:getRootNode(), self:getAnimationCmd(aniTar), delay)   
    end
end

function RAMainUIBottomBanner:getAnimationCmd(name)
    local ccbi = self:getRootNode()
    return function()
        if ccbi ~= nil then
            ccbi:runAnimation(name)
        else
            CCLuaLog("RAMainUIBottomBanner:getAnimationCmd ccbi is nil")
        end
    end
end

function RAMainUIBottomBanner:showWorldCoordinate(x, y, k)
    local str = 'X: ' .. x .. '  Y: ' .. y
    if k ~= nil then
        str = 'K: ' .. k .. '  ' .. str
    end
    UIExtend.setCCLabelString(self:getRootNode(), 'mWorldPos', str)
end

function RAMainUIBottomBanner:showWorldDirection(distance, degree, hideArrow)
    distance = distance or 0
    local str = distance > 0  and (distance .. '\n' .. RAStringUtil:getLanguageString('@KM')) or ''
    UIExtend.setCCLabelString(self:getRootNode(), 'mDistanceLabel', str)
    UIExtend.setNodeVisible(self:getRootNode(), 'mPointer', not hideArrow)
    if not hideArrow then
        UIExtend.setNodeRotation(self:getRootNode(), 'mPointer', 90 - degree)
    end
end

function RAMainUIBottomBanner:Exit()
    CCLuaLog("RAMainUIBottomBanner:Exit")
    if self.waringCCBFile then
        self.waringCCBFile = nil
    end

    if self.guideElecCCB then
        UIExtend.releaseCCBFile(self.guideElecCCB)
        self.guideElecCCB = nil
    end
    if self.guideTaskCCB then
        UIExtend.releaseCCBFile(self.guideTaskCCB)
        self.guideTaskCCB = nil
    end

    self.rewardTaskId = nil
    UIExtend.unLoadCCBFile(self)
    self:unregisterMessageHandlers()
    self:unRegisterNetHandler()
    self:resetData()
end