-- RAMainUIPage
RARequire("BasePage")
RARequire("extern")
local RARootManager = RARequire("RARootManager")
local RABuildManager = RARequire("RABuildManager")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RAGuideManager = RARequire("RAGuideManager")
local const_conf = RARequire("const_conf")
local RARealPayManager = RARequire("RARealPayManager")
local RAGuideConfig = RARequire("RAGuideConfig")


local RAMainUIPage = BaseFunctionPage:new(...)
local OnReceiveMessage = nil
local OnNodeEvent = nil

local RAWarning = {}
--构造函数
function RAWarning:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAWarning:init()
    UIExtend.loadCCBFile("RAWarningAni.ccbi",self)
end

function RAWarning:Exit()
    UIExtend.unLoadCCBFile(self)
end

local RASuperEffect = {}

function RASuperEffect:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RASuperEffect:init(bombType)

    if bombType == GuildManor_pb.WEATHER_STORM then 
        UIExtend.loadCCBFile("Ani_Territory_DarkScreen.ccbi",self)
    else 
        UIExtend.loadCCBFile("Ani_Territory_BrightScreen.ccbi",self)
    end 
end

function RASuperEffect:OnAnimationDone()
    -- body
    self:Exit()
end

function RASuperEffect:Exit()
    UIExtend.unLoadCCBFile(self)
end

local RAMainUIStatus = 
{
    GUIShow_Only = 0,
    AddNodeShow_WithGUI = 1,
    AddNodeShow_WithoutGUI = 2,
    BackNodeShow_Only = 3
}

RAMainUIPage.mTopCityHandler = nil
RAMainUIPage.mTopWorldHandler = nil
RAMainUIPage.mBottomHandler = nil
RAMainUIPage.mActivityHandler = nil
-- RAMainUIPage.mQueueHandler = nil

-- new queue helper
RAMainUIPage.mQueueShowHelper = nil

-- 核弹显示
RAMainUIPage.mNuclearHandler = nil

RAMainUIPage.mUISceneType = SceneTypeList.NoneScene
RAMainUIPage.mGiftCcbfile = nil
RAMainUIPage.mGiftNode = nil
RAMainUIPage.mIsBuilding = false
RAMainUIPage.isShowWarning = false
RAMainUIPage.mWarning = nil 
local CoordinateInputListener = { handler = nil }

function CoordinateInputListener:onInputboxOK(listener)
    local input = listener:getResultStr()
    if input ~= nil and input~= '' then
        local jsonObj = cjson.decode(input) or {}
        local num = tonumber(jsonObj.content)
        -- CCLuaLog(jsonObj.content);
        CCCamera:setPerspectiveCameraParam(num);
    end
    listener:delete()
end

function CoordinateInputListener:onInputboxCancel(listener)
    listener:delete()
end

function RAMainUIPage:resetData()
    self:unregisterMessageHandlers()

    --清除礼包节点
    if self.mGiftCcbfile then
        self.mGiftCcbfile:removeFromParentAndCleanup(true)
        self.mGiftCcbfile = nil
    end

    local resetHandlerFunc = function(handler)
        if handler ~= nil then
            handler:Exit()
        end        
    end

    resetHandlerFunc(self.mTopCityHandler)
    resetHandlerFunc(self.mTopWorldHandler)
    resetHandlerFunc(self.mBottomHandler)

    resetHandlerFunc(self.mActivityHandler)
    -- resetHandlerFunc(self.mQueueHandler)
    resetHandlerFunc(self.mNuclearHandler)
    resetHandlerFunc(self.mQueueShowHelper)

    

    self.mTopCityHandler = nil
    self.mTopWorldHandler = nil
    self.mBottomHandler = nil

    self.mActivityHandler = nil
    -- self.mQueueHandler = nil
    self.mNuclearHandler = nil
    self.mQueueShowHelper = nil

    self.mUISceneType = SceneTypeList.NoneScene
    self.mIsBuilding = false
    self.isShowWarning = false    
end



OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_HandleChooseBuildPage then
        CCLuaLog("MessageDef_MainUI MSG_HandleChooseBuildPage")
        if message.isShow == false then
            RAMainUIPage:HideLastGUI(RAMainUIPage.mUISceneType,true)
        end
        if message.isShow == true then
            RAMainUIPage:ShowCurrGUI(RAMainUIPage.mUISceneType,true)
        end
    end

    -- change build status
    if message.messageID == MessageDef_MainUI.MSG_ChangeBuildStatus then        
        RAMainUIPage:ChangeBuildStatus(message.isShow)
    end

    if message.messageID == MessageDef_MainUI.MSG_Update_Warning then        
        local RARootManager = RARequire('RARootManager')
        local RAMainUIBottomBanner = RARequire('RAMainUIBottomBannerNew')
        if RARootManager.isShowWarning then
            if RAMainUIPage.mWarning == nil then 
                RAMainUIPage.mWarning = RAWarning:new()
                RAMainUIPage.mWarning:init()
                -- RARootManager.mGUINode:addChild(RAMainUIPage.mWarning.ccbfile,-1000)

                -- local director = CCDirector:sharedDirector()
                -- director:getRunningScene():addChild(RAMainUIPage.mWarning.ccbfile)
                RARootManager.mTopNode:addChild(RAMainUIPage.mWarning.ccbfile,1000)

                
                RAMainUIBottomBanner:setWaringNodeVisible(true)
            end
            -- RARootManager.mGUINode:addChild(RAMainUIPage.mWarning.ccbfile,-1000)
        else
            if RAMainUIPage.mWarning ~= nil then 
                RAMainUIPage.mWarning:Exit()
                RAMainUIBottomBanner:setWaringNodeVisible(false)
                RAMainUIPage.mWarning = nil 
            end 
        end  
    end

    if message.messageID == MessageDef_World.MSG_NuclearBomb_Explode then 
        if RARootManager.GetIsInWorld() and RAGuideManager.isInGuide() == false then 
            RAMainUIPage.mSuperEffect = RASuperEffect:new()
            RAMainUIPage.mSuperEffect:init(message.bombType)
            RARootManager.mGUINode:addChild(RAMainUIPage.mSuperEffect.ccbfile,1000)
        end 
    end 

    -- Deal with guide
    if message.messageID == MessageDef_Guide.MSG_Guide then
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.GuideStartDescription then
             --第一步隐藏四个方向的UI
            if RAMainUIPage.mBottomHandler and RAMainUIPage.mBottomHandler.ccbfile then
                RAMainUIPage.mBottomHandler.ccbfile:setVisible(false)
            end
            if RAMainUIPage.mTopCityHandler and RAMainUIPage.mTopCityHandler.ccbfile then
                RAMainUIPage.mTopCityHandler.ccbfile:setVisible(false)
            end
            if RAMainUIPage.mTopWorldHandler and RAMainUIPage.mTopWorldHandler.ccbfile then
                RAMainUIPage.mTopWorldHandler.ccbfile:setVisible(false)
            end
            if RAMainUIPage.mQueueNode then
                RAMainUIPage.mQueueNode:setVisible(false)
                RAMainUIPage.mNuclearCDNode:setVisible(false)
            end
            if RAMainUIPage.mGiftNode then
                RAMainUIPage.mGiftNode:setVisible(false)
            end
            RARootManager.AddGuidPage({["guideId"] = guideId})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.GuideStart then
            --第一步隐藏四个方向的UI
--            if RAMainUIPage.mBottomHandler and RAMainUIPage.mBottomHandler.ccbfile then
--                RAMainUIPage.mBottomHandler.ccbfile:setVisible(false)
--            end
--            if RAMainUIPage.mTopCityHandler and RAMainUIPage.mTopCityHandler.ccbfile then
--                RAMainUIPage.mTopCityHandler.ccbfile:setVisible(false)
--            end
--            if RAMainUIPage.mTopWorldHandler and RAMainUIPage.mTopWorldHandler.ccbfile then
--                RAMainUIPage.mTopWorldHandler.ccbfile:setVisible(false)
--            end
--            if RAMainUIPage.mQueueNode then
--                RAMainUIPage.mQueueNode:setVisible(false)
--                RAMainUIPage.mNuclearCDNode:setVisible(false)
--            end
--            if RAMainUIPage.mGiftNode then
--                RAMainUIPage.mGiftNode:setVisible(false)
--            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleContructionBtn then
            if constGuideInfo.showGuidePage == 1 then
                local constructionNode = UIExtend.getCCNodeFromCCB(RAMainUIPage.mBottomHandler.ccbfile, "mGuildConstructionNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = constructionNode:getPosition()
                local worldPos = constructionNode:getParent():convertToWorldSpace(pos)
                local size = constructionNode:getContentSize()
                -- size.width = size.width * 0.592
                -- size.height = size.height * 0.592

                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CirclePVEBtn then
            if constGuideInfo.showGuidePage == 1 then
                local pveNode = UIExtend.getCCNodeFromCCB(RAMainUIPage.mBottomHandler.ccbfile, "mGuildPveNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = pveNode:getPosition()
                local worldPos = pveNode:getParent():convertToWorldSpace(pos)
                local size = pveNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleHeadIconBtn then
            if constGuideInfo.showGuidePage == 1 then
                local headNode = UIExtend.getCCNodeFromCCB(RAMainUIPage.mTopCityHandler.ccbfile, "mGuideHeadNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = headNode:getPosition()
                local worldPos = headNode:getParent():convertToWorldSpace(pos)
                local size = headNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleBuildTypeAndMoveCamera then
            if constGuideInfo.showGuidePage == 1 then
                local RAChooseBuildPageHandler = RARequire("RAChooseBuildPage")
                local info = RAChooseBuildPageHandler:getGuideNodeInfo(constGuideInfo)-- 获得建筑类型按钮
                info["pos"].x = info["pos"].x + info["size"].width / 2
                info["pos"].y = info["pos"].y + info["size"].height / 2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
            end
        elseif constGuideInfo and (constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.ChooseTrainSoldierFirst or constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.ChooseTrainSoldier) then
            if constGuideInfo.showGuidePage == 1 then
                --光圈在造兵page圈住大兵
                local RAArsenalNewPage = RARequire("RAArsenalNewPage")
                local info = RAArsenalNewPage:getGuideNodeInfo(constGuideInfo)
                info["pos"].x = info["pos"].x + info["size"].width / 2
                info["pos"].y = info["pos"].y + info["size"].height / 2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CreateTrainImm then
            if constGuideInfo.showGuidePage == 1 then
                --光圈在训练page圈住立即训练
                local RAArsenalTrainPage = RARequire("RAArsenalNewPage")
                local info = RAArsenalTrainPage:getGuideNodeInfo()
                info.pos.x = info.pos.x - 5
                info.pos.y = info.pos.y + 5
                info.size.width =  info.size.width - 3
                info.size.height = info.size.height - 3
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.RatarBuildCompleted then
            local RACitySceneManager = RARequire("RACitySceneManager")
            RARootManager.AddCoverPage()
            local time = tonumber(const_conf["GuideToRadarTime"].value)
            local scale = tonumber(const_conf["GuideToRadarScale"].value)
            RACitySceneManager:setCameraScale(scale,1.5)            
            performWithDelay(RAMainUIPage:getRootNode(), function ()
                --雷达建造完了，需要展现一些警报效果
                RARootManager.isShowWarning = true
                MessageManager.sendMessage(MessageDef_MainUI.MSG_Update_Warning)

                --变红，播放音效
                local common = RARequire("common")
                common:playEffect("AlarmSound")


                --time时间后，进入下一步
                performWithDelay(RAMainUIPage:getRootNode(), function ()
                    --RARootManager.isShowWarning = false
                    --MessageManager.sendMessage(MessageDef_MainUI.MSG_Update_Warning)--关闭warning
                    RAGuideManager.gotoNextStep()
                 end, 1)
            end, 2)     
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleWorldBtn then
            --圈住世界按钮
            if constGuideInfo.showGuidePage == 1 then
                local worldBtn = UIExtend.getCCNodeFromCCB(RAMainUIPage.mBottomHandler.ccbfile, "mGuildWorldBtnNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = worldBtn:getPosition()
                local worldPos = worldBtn:getParent():convertToWorldSpace(pos)
                local size = worldBtn:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.StartStory then
            --剧情开始
            if constGuideInfo.showGuidePage == 1 then
                local barrierId=constGuideInfo.barrierId
                local framentId=constGuideInfo.framentId
                local RAMissionBarrierManager=RARequire("RAMissionBarrierManager")
                local RAMissionVar=RARequire("RAMissionVar")
                RAMissionVar:setFragmentId(framentId)
                RAMissionBarrierManager:gotoBarrier(barrierId)   
                RAMainUIPage.mTopCityHandler.ccbfile:setVisible(false)
                --MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.EndStory then
             if constGuideInfo.showGuidePage == 1 then
               RARootManager.AddCoverPage()
               RAGuideManager.gotoNextStep()
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.RemoveCoverPage then
             if constGuideInfo.showGuidePage == 1 then
               RARootManager.RemoveCoverPage()
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.PlayMainUIAni then
            --UI全部显示
            if RAMainUIPage.mQueueNode then
                RAMainUIPage.mQueueNode:setVisible(true)
                RAMainUIPage.mNuclearCDNode:setVisible(true)
            end
            if RAMainUIPage.mGiftNode then
                if RAGuideManager.isInGuide() then
                    RAMainUIPage.mGiftNode:setVisible(false)
                else  
                    --因挡住广播，所以先隐藏
                    --RAMainUIPage.mGiftNode:setVisible(true)
                end 
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleUpgradeBtn then
            --圈住升级按钮
            local RABuildPromoteNewPage = RARequire("RABuildPromoteNewPage")
            local info = RABuildPromoteNewPage:getGuideNodeInfo()
            info.pos.x = info.pos.x -2
            info.pos.y = info.pos.y + 2
            info.size.width =  info.size.width + 5
            info.size.height = info.size.height + 5
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.ActiveVip then
            --激活vip
            local RANetUtil = RARequire("RANetUtil")
            RANetUtil:sendPacket(HP_pb.GUIDE_ACTIVATE_VIP,nil, {retOpcode = -1})
            return
        elseif constGuideInfo and (constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleResourceLand or constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleMonster) then
            local landSize = constGuideInfo.buildSize
            local landOffset = constGuideInfo.buildOffSet
            local size = CCSizeMake(0, 0)
            if landSize then
                local sizeArr = Utilitys.Split(landSize, "_")
                size.width = tonumber(sizeArr[1])
                size.height = tonumber(sizeArr[2])
            end

            local offsetX = 0
            local offsetY = 0
            if landOffset then
                local offsetArr = Utilitys.Split(landOffset, "_")
                offsetX = tonumber(offsetArr[1])
                offsetY = tonumber(offsetArr[2])
            end

            local screenVisibleSize = CCDirector:sharedDirector():getOpenGLView():getVisibleSize()
            local screenCenterPos = ccp(screenVisibleSize.width / 2, screenVisibleSize.height / 2)
            screenCenterPos.x = screenCenterPos.x + offsetX
            screenCenterPos.y = screenCenterPos.y + offsetY

            RARootManager.RemoveCoverPage()
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = screenCenterPos, ["size"]=size})
        elseif constGuideInfo and (constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleMarchBtn or constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleMarchBtnWithNoDelay) then
            local RATroopChargePage = RARequire("RATroopChargePage")
            local info = RATroopChargePage:getGuideNodeInfo()
            info.pos.x = info.pos.x - 5
            info.pos.y = info.pos.y + 5
            info.size.width =  info.size.width + 10
            info.size.height = info.size.height + 10
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleWeightNum then
            local RATroopChargePage = RARequire("RATroopChargePage")
            local info = RATroopChargePage:getWeightLoadNodeInfo()
            info.pos.x = info.pos.x - info.size.width/2
            info.size.width =  info.size.width + 20
            info.size.height = info.size.height + 25
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleHomeBtn then
            --圈住世界按钮
            if constGuideInfo.showGuidePage == 1 then
                local worldBtn = UIExtend.getCCNodeFromCCB(RAMainUIPage.mBottomHandler.ccbfile, "mGuildHomeBackNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = worldBtn:getPosition()
                local worldPos = worldBtn:getParent():convertToWorldSpace(pos)
                local size = worldBtn:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleUseBtn then
            if constGuideInfo.showGuidePage == 1 then
                local RACommonItemsSpeedUpPopUp = RARequire("RACommonItemsSpeedUpPopUp")
                local info = RACommonItemsSpeedUpPopUp:getGuideNodeInfo()
                info.pos.x = info.pos.x - 5
                info.pos.y = info.pos.y + 5
                info.size.width =  info.size.width + 10
                info.size.height = info.size.height + 10
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.GotoCity then
            local isInCity = RARootManager.GetIsInCity()
            if not isInCity then
                RARootManager.ChangeScene(SceneTypeList.CityScene)
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleTrainSoldierBtnFirst then
            --圈住训练按钮
            if constGuideInfo.showGuidePage == 1 then
                --光圈在训练page圈住训练
                local RAArsenalTrainPage = RARequire("RAArsenalNewPage")
                local info = RAArsenalTrainPage:getTrainBtnNodeInfo()
                info.pos.x = info.pos.x - 5
                info.pos.y = info.pos.y + 5
                info.size.width =  info.size.width-3
                info.size.height = info.size.height-3
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})

                RAMainUIPage.mTopCityHandler.ccbfile:setVisible(false)
            end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.TravelShopShow then
            --旅行商人处理飞机飞行动画
            local RACityScene_BlackShop = RARequire("RACityScene_BlackShop")
            RARootManager.AddCoverPage()
            RACityScene_BlackShop:HandleGuideSpecialReq()
            -- RARootManager.AddGuidPage({["guideId"] = guideId})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleAttackBtn then
            --圈住攻击按钮
            local RAWorldMonsterNewPage = RARequire("RAWorldMonsterNewPage")
            local info = RAWorldMonsterNewPage:getAttackBtnInfo()
            info.size.width =  info.size.width + 10
            info.size.height = info.size.height + 10
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleAccToolUseBtn then
            local RAMarchItemUsePage = RARequire("RAMarchItemUsePage")
            local info = RAMarchItemUsePage:getUseBtnInfo()
            RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = info["pos"], ["size"]=info["size"]})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.AddCoverPage then
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.FightMonsterSuc then
            --打小怪胜利
            local RAMarchItemUsePage = RARequire("RAMarchItemUsePage")
            if RAMarchItemUsePage then
                if RAMarchItemUsePage.ccbfile and RAMarchItemUsePage.closeFunc then
                    RAMarchItemUsePage.closeFunc()
                end
            end
            RARootManager.AddGuidPage({["guideId"] = guideId})
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleBuildInCenter then
            if constGuideInfo.notDealMessageOfMoveBuild and constGuideInfo.notDealMessageOfMoveBuild==1 then
                --新手期有些步骤不需要处理hud完成消息
                return
            end

            if constGuideInfo.specialGuideType == 1 then
                local confSize = constGuideInfo.buildSize
                local size = CCSizeMake(0, 0)
                if confSize then
                    local sizeArr = Utilitys.Split(confSize, "_")
                    size.width = tonumber(sizeArr[1])
                    size.height = tonumber(sizeArr[2])
                end
                local confBuildOffset = constGuideInfo.buildOffSet
                local offsetX = 0
                local offsetY = 0
                if confBuildOffset then
                    local offsetArr = Utilitys.Split(confBuildOffset, "_")
                    offsetX = tonumber(offsetArr[1])
                    offsetY = tonumber(offsetArr[2])
                end
                local screenVisibleSize = CCDirector:sharedDirector():getOpenGLView():getVisibleSize()
                local screenCenterPos = ccp(screenVisibleSize.width / 2, screenVisibleSize.height / 2)
                screenCenterPos.x = screenCenterPos.x + offsetX
                screenCenterPos.y = screenCenterPos.y + offsetY

                RARootManager.RemoveCoverPage()
                RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = screenCenterPos, ["size"]=size})
            end
        end
    end

end

function RAMainUIPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_HandleChooseBuildPage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ChangeBuildStatus, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_Update_Warning, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_NuclearBomb_Explode, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage
end

function RAMainUIPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_HandleChooseBuildPage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ChangeBuildStatus, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_Update_Warning, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_NuclearBomb_Explode, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide, OnReceiveMessage)--GuideMessage
end


function RAMainUIPage:Enter(data)
    --如果在新手期，先把屏幕cover住
    if RAGuideManager.isInGuide() then
        if not RARootManager.GetIsInBarrierScene() then
            RARootManager.AddCoverPage()
        end
    end

    self:resetData()
	CCLuaLog("RAMainUIPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUI.ccbi",RAMainUIPage)
	
    if data ~= nil then
        for k,v in pairs(data) do
            print(k,v)
            CCLuaLog("RAMainUIPage:Enter  k="..k.." v="..v)
        end
    end
    self:registerMessageHandlers()

    self.mGUINode = UIExtend.getCCNodeFromCCB(ccbfile, "mGUINode")
    self.mMainUIBackNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUIBackNode")
    self.mMainUIAddNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUIAddNode")

    self.mMainUIBottomBannerNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUIBottomBannerNode")
    self.mMainUITopCityNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUITopCityNode")
    self.mMainUITopWorldNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUITopWorldNode")
    self.mBuyQueueNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBuyQueueNode")
    self.mQueueNode = UIExtend.getCCNodeFromCCB(ccbfile, "mQueueNode")

    -- 新的queue node
    self.mNewQueueNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNewQueueNode")

    self.mNuclearCDNode = UIExtend.getCCNodeFromCCB(ccbfile, "mNuclearCDNode")
    self.mGiftNode = UIExtend.getCCNodeFromCCB(ccbfile, "mMainUIActivityNode")

    self:initUI()

    -- UIExtend.setNodeVisible(RAMainUIPage:getRootNode(), "mTestMenuNode", true)

    if not RAGuideManager.isInGuide() then
	    self:loadPushPopup()
    end

    local RARootManager = RARequire('RARootManager')
    local RAMainUIBottomBanner = RARequire('RAMainUIBottomBannerNew')
    if RARootManager.isShowWarning then
        if self.mWarning == nil then 
            self.mWarning = RAWarning:new()
            self.mWarning:init()
            local RARootManager = RARequire('RARootManager')
            RARootManager.mTopNode:addChild(self.mWarning.ccbfile,1000)
            RAMainUIBottomBanner:setWaringNodeVisible(true)
            -- local director = CCDirector:sharedDirector()
            -- director:getRunningScene():addChild(RAMainUIPage.mWarning.ccbfile)
        end 
    elseif  self.mWarning ~= nil then 
        self.mWarning:Exit()
        self.mWarning = nil 
        RAMainUIBottomBanner:setWaringNodeVisible(false)
    end
    
    --因挡住广播，所以先隐藏
    --self:_refreshGiftNode()--刷新礼包节点  
end

--desc:刷新礼包节点
function RAMainUIPage:_refreshGiftNode()
    local ccbfileName = RARealPayManager.getGiftItemMainUICCBByLogTimes()
    if self.mGiftCcbfile == nil and ccbfileName and ccbfileName ~= "" then
        self.mGiftCcbfile = UIExtend.loadCCBFile(ccbfileName,{
            onCheckBtn = function ()
                --礼包按钮点击
                local giftItem = RARealPayManager.getGiftItemByLogTimes()
                if giftItem then
                    RARootManager.OpenPage("RARechargeGiftPage", {data = giftItem})
                end
            end
        })
    end

    if self.mGiftCcbfile and self.mGiftNode then
        self.mGiftNode:addChild(self.mGiftCcbfile)
    end
end

--用于登录时弹出各种提醒、支付等主动push的页面
--RAPushRemindPageManager，这个类可以放各种提醒，只要push进去
function RAMainUIPage:loadPushPopup()
    --先放这，在这不合适，还有比较复杂的push条件，新手、建造引导、任务引导、是否首次登录等等一系列条件
    --每日首次登录后VIP失效，提醒面板弹出
    --todo 判断 1、新手完成
    --todo 判断 2、城内
    --todo 判断 3、无引导和其他弹出框
    --todo 判断 4、其他不适合弹出的条件
    local RAPushRemindPageManager = RARequire('RAPushRemindPageManager')
    RAPushRemindPageManager.popPage()
end

function RAMainUIPage:initUI()
    self.mGUINode:setVisible(false)
    self.mMainUIBackNode:setVisible(false)
    self.mMainUIAddNode:setVisible(false)

    self.mMainUIBottomBannerNode:setVisible(false)
    self.mMainUITopCityNode:setVisible(false)
    self.mMainUITopWorldNode:setVisible(false)
    self.mBuyQueueNode:setVisible(false)
    self.mQueueNode:setVisible(false)
    self.mGiftNode:setVisible(false)

    local initNodesFunc = function(name, node)
        local handler = UIExtend.GetPageHandler(name, true)
        UIExtend.AddPageToNode(handler, node)
        return handler
    end

    -- add bottom part
    self.mBottomHandler = initNodesFunc('RAMainUIBottomBannerNew', self.mMainUIBottomBannerNode)

    -- add top part
    self.mTopCityHandler = initNodesFunc('RAMainUITopBannerCityNew', self.mMainUITopCityNode)
    self.mTopWorldHandler = initNodesFunc('RAMainUITopBannerWorldNew', self.mMainUITopWorldNode)

    -- -- register queue helper
    -- self.mQueueHandler = UIExtend.GetPageHandler('RAMainUIQueueHelper', true, 
    --     {
    --         buyNode = self.mBuyQueueNode,
    --         queueNode = self.mQueueNode
    --     })

    -- -- register nuclear helper
    -- self.mNuclearHandler = UIExtend.GetPageHandler('RAMainUINuclearHelper', true, 
    --     {
    --         nuclearCDNode = self.mNuclearCDNode,
    --     })

    self.mQueueShowHelper = UIExtend.GetPageHandler('RAMainUIQueueShowHelper', true,
        {
            queueNode = self.mNewQueueNode,
        })
end


function RAMainUIPage:ChangeBuildStatus(isShow)
    if isShow == nil or self.mIsBuilding == isShow then
        return    
    end

    self.mIsBuilding = isShow
    --新手期内不显示返回按钮
    if  not RAGuideManager.isInGuide() then
        self.mMainUIBackNode:setVisible(self.mIsBuilding)
    end
end

function RAMainUIPage:HideLastGUI(lastType,isChooseBuild)
    if lastType == SceneTypeList.NoneScene then
        return
    end
    if isChooseBuild == nil then
        isChooseBuild = false
    end
    --self.mActivityHandler:ChangeCellShowStatus(false)
    -- self.mQueueHandler:ChangeCellShowStatus(false)
    self.mBottomHandler:ChangeShowStatus(false, true)

    self.mQueueShowHelper:ChangeAllCellShowStatus(false)
    -- 隐藏城内UI的动画
    if lastType == SceneTypeList.CityScene then
        self.mTopCityHandler:ChangeShowStatus(false, true)
        --如果是选择建筑页面，不去拉升摄像机
        if isChooseBuild == false then
            local RACitySceneManager = RARequire("RACitySceneManager")
            RACitySceneManager:gotoWorld()
        end
    end

    -- 隐藏城外UI的动画
    if lastType == SceneTypeList.WorldScene then
        self.mTopWorldHandler:ChangeShowStatus(false, true)

        local RAWorldManager = RARequire('RAWorldManager')
        RAWorldManager:FadeOut()
    end
end

function RAMainUIPage:ShowCurrGUI(currType,isChooseBuild)
    if currType == SceneTypeList.NoneScene then
        return
    end
    if isChooseBuild == nil then isChooseBuild = false end
    --self.mActivityHandler:ChangeCellShowStatus(true)
    -- self.mQueueHandler:ChangeCellShowStatus(true)

    if currType ~= SceneTypeList.BattleScene then
        self.mBottomHandler:ChangeShowStatus(true, true)
        self.mQueueShowHelper:ChangeAllCellShowStatus(true, true)
    end
    -- 显示城内UI的动画
    if currType == SceneTypeList.CityScene then
        self.mTopCityHandler:ChangeShowStatus(true, true)

        
        --如果是选择建筑页面，不去拉升摄像机
        if isChooseBuild == false then
            local RACitySceneManager = RARequire("RACitySceneManager")
            RACitySceneManager:gobackToCity()
        end
        
    end

    -- 显示城外UI的动画
    if currType == SceneTypeList.WorldScene then
        self.mTopWorldHandler:ChangeShowStatus(true, true)
        
        local RAWorldManager = RARequire('RAWorldManager')
        RAWorldManager:FadeIn()
    end

    RARootManager.RemoveWaitingPage()
end


-- 仅用于控制节点显隐，不处理动画
function RAMainUIPage:UpdateUIByScene(showType)
    if self.mUISceneType == showType then
        return
    end

    self.mUISceneType = showType
    -- none scene
    if self.mUISceneType == SceneTypeList.NoneScene then
        self.mGUINode:setVisible(false)
        self.mMainUIBackNode:setVisible(false)
        self.mMainUIAddNode:setVisible(false)

        self.mMainUIBottomBannerNode:setVisible(false)        
        self.mBuyQueueNode:setVisible(false)
        self.mQueueNode:setVisible(false)
        self.mGiftNode:setVisible(false)
        self.mNuclearCDNode:setVisible(false)

        self.mMainUITopCityNode:setVisible(false)
        self.mMainUITopWorldNode:setVisible(false)
    end

    -- city scene
    if self.mUISceneType == SceneTypeList.CityScene then
        self.mGUINode:setVisible(true)
        self.mMainUIBackNode:setVisible(false)
        self.mMainUIAddNode:setVisible(true)

        self.mMainUIBottomBannerNode:setVisible(true)        
        self.mBuyQueueNode:setVisible(true)
        if not RAGuideManager.isInGuide() or (RAGuideManager.isInGuide() and RAGuideManager.canShowAllMainUI()) then
            self.mQueueNode:setVisible(true)--新手期间，队列按钮不显示

            --因挡住广播，所以先隐藏
            --self.mGiftNode:setVisible(true)
            self.mNuclearCDNode:setVisible(true)
        end

        if RAGuideManager.isInGuide() then 
            self.mGiftNode:setVisible(false)
        end 

        -- 这块用时间轴来控制
        self.mMainUITopCityNode:setVisible(true)
        self.mMainUITopWorldNode:setVisible(true)
    end

    -- world scene
    if self.mUISceneType == SceneTypeList.WorldScene then
        self.mGUINode:setVisible(true)
        self.mMainUIBackNode:setVisible(false)
        self.mMainUIAddNode:setVisible(true)

        self.mMainUIBottomBannerNode:setVisible(true)        
        self.mBuyQueueNode:setVisible(true)
        if not RAGuideManager.isInGuide() or (RAGuideManager.isInGuide() and RAGuideManager.canShowAllMainUI()) then--新手期间，队列按钮不显示
            self.mQueueNode:setVisible(true)
            --因挡住广播，所以先隐藏
            --self.mGiftNode:setVisible(true)
            self.mNuclearCDNode:setVisible(true)
        end

        if RAGuideManager.isInGuide() then 
            self.mGiftNode:setVisible(false)
        end 

        -- 这块用时间轴来控制
        self.mMainUITopCityNode:setVisible(true)
        self.mMainUITopWorldNode:setVisible(true)
    end

    if self.mUISceneType == SceneTypeList.BattleScene then
        self.mGUINode:setVisible(true)
        self.mMainUIBackNode:setVisible(false)
        self.mMainUIAddNode:setVisible(false)

        self.mMainUIBottomBannerNode:setVisible(false)        
        self.mBuyQueueNode:setVisible(true)
        self.mGiftNode:setVisible(false)

        -- 这块用时间轴来控制
        self.mMainUITopCityNode:setVisible(false)
        self.mMainUITopWorldNode:setVisible(false)
    end

    -- 测试版本，隐藏队列
    self.mBuyQueueNode:setVisible(false)
    -- self.mQueueNode:setVisible(false)

    self.mBottomHandler:UpdateUIByScene(self.mUISceneType)
end

function RAMainUIPage:onMainUIBackBtn()
    -- body
    CCLuaLog("RAMainUIPage:onMainUIBackBtn")
    MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus,{isShow = false})
    RARootManager.OpenPage("RAChooseBuildPage")
end

function RAMainUIPage:onTestBtn1()
	CCLuaLog("RAMainUIPage:onTestBtn1")
    self.mQueueShowHelper:RefreshQueueAllCells()
end

function RAMainUIPage:onTestBtn2()
    -- RARootManager.ShowMsgBox("@BuildDetailRequirement","zhangsan",20)
    -- RACityScene.mCamera:lookAt(ccp(1000,1000),0.0,false)
    -- CCLuaLog("RAMainUIPage:onTestBtn2")
   -- RARootManager.OpenPage("RABuildInfoPage", null,false,true)
   -- RARootManager.OpenPage("RATroopChargePage", {marchType = 2})
   self.mQueueShowHelper.mIsOpening = not self.mQueueShowHelper.mIsOpening
end

function RAMainUIPage:onTestBtn3()
    CCLuaLog("RAMainUIPage:onTestBtn3")
    -- local curScale = RACityScene.mCamera:getScale()
    -- curScale = curScale * 0.9
    -- if curScale<1.0 then
    --    curScale = 1.0 
    -- end
    -- RACityScene.mCamera:setScale(curScale,0)
    local id = self.mQueueShowHelper.mCellCount
    print('want toooooooooooooooooooooooooooo removeeeeeeeeeeee last id = '..id)
    self.mQueueShowHelper:ChangeOneCellShowStatus(id, 3)
end

function RAMainUIPage:onTestBtn4()
    local id = math.floor(math.random(1, self.mQueueShowHelper.mCellCount))
    print('want toooooooooooooooooooooooooooo removeeeeeeeeeeee id = '..id)
    self.mQueueShowHelper:ChangeOneCellShowStatus(id, 3)
end

function RAMainUIPage:onTestBtn5()
    local id = math.floor(math.random(1, self.mQueueShowHelper.mCellCount))
    print('want toooooooooooooooooooooooooooo addddddddddddddddd id = '..id)
    self.mQueueShowHelper:ChangeOneCellShowStatus(id, 1)
    -- CCLuaLog("RAMainUIPage:onTestBtn5")
    -- RARootManager.OpenPage("RAScienceTreePage", null,true,true)
    -- local RABuildManager = RARequire('RABuildManager')
    -- RABuildManager:showBuildingByBuildType(Const_pb.POWER_PLANT,1,true)

    -- local data = {}
    --         data.labelText = "是否测试同屏问题"
    --         data.resultFun = function(resultInfo)
    --             if resultInfo == true then 
    --                 CCLuaLog("click confirm")
    --                 -- self.curBuilding = self:createTempBuilding("test")
    --                 -- RACityScene.mBuildSpineLayer:addChild(self.curBuilding.spineNode)
    --                 -- self:setMoveBuildPos(tilePos)
    --                 RABuildManager:debugMode()
    --                 local RACitySceneManager = RARequire("RACitySceneManager")
    --                 RACitySceneManager.spriteScreenDebug = not RACitySceneManager.spriteScreenDebug
    --             else
    --                 CCLuaLog("click cancel")
    --             end
    --         end

            -- confirmPageTest:Enter(data)
            -- RACityScene.mBuildSpineLayer:addChild(confirmPageTest.ccbfile)

    -- RARootManager.OpenPage("RAConfirmPage",data, false, true, true)
    -- RARootManager.OpenPage("RAMainUIQueuePage")
end

function RAMainUIPage:onTestBtn6()
    CCLuaLog("RAMainUIPage:onTestBtn6")
    -- RARootManager.OpenPage("RAChooseBuildPage")
    local RALogicUtil = RARequire('RALogicUtil')
    -- CCLuaLog(RALogicUtil:num2k(1000))
    -- CCLuaLog(RALogicUtil:num2k(999))
    -- CCLuaLog(RALogicUtil:num2k(1001))
    -- CCLuaLog(RALogicUtil:num2k(11221121))
    -- CCLuaLog(RALogicUtil:num2k(999999999))
    -- CCLuaLog(RALogicUtil:num2k(100000000))
    -- CCLuaLog(RALogicUtil:num2k(1000000000))

    CCLuaLog(RALogicUtil:num2percent(0.213))    
    CCLuaLog(RALogicUtil:num2percent(0.112312))    
    CCLuaLog(RALogicUtil:num2percent(0.112362))  
    CCLuaLog(RALogicUtil:num2percent(0.112395))  
    CCLuaLog(RALogicUtil:num2percent(0.1123952))  
    CCLuaLog(RALogicUtil:num2percent(10003.11351))
    CCLuaLog(RALogicUtil:num2percent(0.009))
    CCLuaLog(RALogicUtil:num2percent(0.009, 2, true))
    CCLuaLog(RALogicUtil:num2percent(0.01))

    CCLuaLog(RALogicUtil:numCutAfterDot(0.213))    
    CCLuaLog(RALogicUtil:numCutAfterDot(0.1))    
    CCLuaLog(RALogicUtil:numCutAfterDot(0.135))    
    CCLuaLog(RALogicUtil:numCutAfterDot(0.1345))    
    CCLuaLog(RALogicUtil:numCutAfterDot(0.1398))    
    CCLuaLog(RALogicUtil:numCutAfterDot(10003.1))

    -- local RAStringUtil = RARequire('RAStringUtil')
    -- CCLuaLog(RAStringUtil:getHTMLString('test1', 'n', 1))
    -- CCLuaLog(RAStringUtil:getHTMLString('test2'))

    -- RARootManager.OpenPage("RACDKeyPage",nil, false, true, true)
end

function RAMainUIPage:onTestBtn7()
    -- CCLuaLog("RAMainUIPage:onTestBtn7")
    -- -- self.mQueueHandler.mIsBuyCellShow = not self.mQueueHandler.mIsBuyCellShow
    -- local RAGameConfig = RARequire("RAGameConfig")
    --  -- 测试tips
    -- MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,
    --     {
    --         menuType = RAGameConfig.MainUIMenuType.Menu,
    --         num = -5,
    --         isDirChange = true
    --     })
    
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local oilNum = RAPlayerInfoManager.getPlayerBasicInfo().oil
    RAPlayerInfoManager.getPlayerBasicInfo().oil = oilNum + 2000
    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo,{})
end

function RAMainUIPage:onTestBtn8()
    CCLuaLog("RAMainUIPage:onTestBtn8")
    -- self.mActivityHandler:ChangeCellShowStatus(not self.mActivityHandler.mIsCellIn)
    self.mQueueShowHelper:ChangeAllCellShowStatus(not self.mQueueShowHelper.mIsAllCellIn)

    -- local RAGameConfig = RARequire("RAGameConfig")
    --  -- 测试tips
    -- MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,
    --     {
    --         menuType = RAGameConfig.MainUIMenuType.Menu,
    --         num = 2,
    --         isDirChange = false
    --     })

    -- 队列UI
    --RARootManager.OpenPage("RAMainUIQueuePage", nil, false, true, true)

    -- platformSDKListener:new(CoordinateInputListener)
    -- RARequire('RASDKUtil').sendMessageG2P('showInputbox', {multiline = false})
end


function RAMainUIPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAMainUIPage:Excute()
	--ScrollViewAnimation.update()
end	


function RAMainUIPage:Exit()
    CCLuaLog("RAMainUIPage:Exit")
    self:resetData()
    UIExtend.unLoadCCBFile(self)
end