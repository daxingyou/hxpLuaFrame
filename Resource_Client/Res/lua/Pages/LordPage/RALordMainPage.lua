local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RALogicUtil = RARequire("RALogicUtil")
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RAGameConfig = RARequire("RAGameConfig")
local RANetUtil = RARequire("RANetUtil")
local RAStringUtil = RARequire("RAStringUtil")
local RARootManager = RARequire("RARootManager")
local shop_conf = RARequire("shop_conf")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAPackageData = RARequire("RAPackageData")
local RAPackageManager = RARequire("RAPackageManager")
local RA_Common = RARequire("common")
local Utilitys=RARequire("Utilitys")
local RACommandManage=RARequire("RACommandManage")
local RAWorldManager=RARequire("RAWorldManager")
local RAEquipManager = RARequire("RAEquipManager")
local RAGuideManager=RARequire('RAGuideManager')
local mFrameTime=0
local RALordMainPage = BaseFunctionPage:new(...)

local RALordHandler = {}

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Lord.MSG_RefreshName then
        RALordMainPage:refreshName()
    elseif message.messageID == MessageDef_Lord.MSG_RefreshPortrait then
        RALordMainPage:refreshPortrait()
    elseif message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        RALordMainPage:refreshExpAndPower()
    elseif message.messageID==MessageDef_Commonder.MSG_State_Changed then 
        RALordMainPage:refreshCommanderState()
    elseif message.messageID==MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
        if opcode==HP_pb.CAPTIVE_REBORN_C then 
            RALordMainPage:refreshCommanderState()
        end
    elseif message.messageID == MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint then 
        --天赋红点
        RALordMainPage:refreshTalentRedPoint()
    -- elseif message.messageID == MessageDef_Lord.MSG_RefreshHeadImg then
        -- RALordMainPage:refreshHeadImg()  
    elseif  message.messageID == MessageDef_Guide.MSG_Guide then 
         --新手相关
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleTalentBtn then
                if constGuideInfo.showGuidePage == 1 then
                    local skillNode = UIExtend.getCCNodeFromCCB(RALordMainPage.ccbfile, "mGuideSkillNode")
                    local pos = ccp(0, 0)
                    pos.x, pos.y = skillNode:getPosition()
                    local worldPos = skillNode:getParent():convertToWorldSpace(pos)
                    local size = skillNode:getContentSize()
                    size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                    size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                    RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                end
        elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleRALordMainPageBackBtn then
                if constGuideInfo.showGuidePage == 1 then
                    local titleCCB=UIExtend.getCCBFileFromCCB(RALordMainPage.ccbfile, "mCommonTitleCCB")
                    local backNode = UIExtend.getCCNodeFromCCB(titleCCB, "mBackBtn")
                    local pos = ccp(0, 0)
                    pos.x, pos.y = backNode:getPosition()
                    local worldPos = backNode:getParent():convertToWorldSpace(pos)
                    local size = backNode:getContentSize()
                    size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                    size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                    RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                end
        end 
    end
end

--RALordMainPage.euipCCB = {}
function RALordMainPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RALordPageV2.ccbi", RALordMainPage)

    UIExtend.setNodeVisible(self.ccbfile, 'mUserBustPic', false)
--    for i = 1, RAGameConfig.MAX_EQUIPNUM do
--        local name = "mEquipCell"..i
--        RALordMainPage.euipCCB[i] = UIExtend.getCCBFileFromCCB(self.ccbfile, name)
--    end
    self:addHandler()
    self:refreshUI()
    self:refreshTitle()

     --刷新装备
    self:refreshEquip()

    RACommandManage:sendOpenPlayerBoardReq()
    --刷新下指挥官的状态
    self:refreshCommanderState()

    --天赋红点
    self:refreshTalentRedPoint()

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    end
end

function RALordMainPage:addHandler()
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshName, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshPortrait, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Commonder.MSG_State_Changed, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
         MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end 

    --天赋红点消息
    MessageManager.registerMessageHandler(MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint, OnReceiveMessage)



    RALordHandler[#RALordHandler + 1] = RANetUtil:addListener(HP_pb.PLAYER_DETAIL_S, RALordMainPage)

end

function RALordMainPage:removeHander()
    for k, value in pairs(RALordHandler) do
        if RALordHandler[k] then
            RANetUtil:removeListener(RALordHandler[k])
            RALordHandler[k] = nil
        end
    end
    RALordHandler = {}

    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshName, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshPortrait, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Commonder.MSG_State_Changed, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)   

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end  

    --天赋红点消息
    MessageManager.removeMessageHandler(MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint, OnReceiveMessage)
end

function RALordMainPage:onReceivePacket(handler)
    RARootManager.RemoveWaitingPage()
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_DETAIL_S then
        local msg = Player_pb.PlayerDetailRes()
        msg:ParseFromString(buffer)
        if msg ~= nil then
            RAPlayerInfoManager.setPlayerDetailInfo(msg)
            RARootManager.OpenPage("RALordBasicPage", nil,false,true, true)
        else
            CCLuaLog("The packet PlayerDetailRes parse Failed")
        end
    end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------装备-----------------------------------------------------------------------

function RALordMainPage:refreshEquip()
    local equips = RAPlayerInfoManager.getPlayerEquipInfo()
    --for i = 1,RAGameConfig.MAX_EQUIPNUM do
    for k,equip in pairs(equips) do
        local equipInfo = RAEquipManager:getConfEquipInfoById(equip.uuid)
        --装备icon AllianceFlag_01.png
        UIExtend.addSpriteToNodeParent(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part), "mIconNode",equipInfo.icon)
        --装备等级
        UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part),'mEquipLevel',"LV."..equip.level)
        --设置部位
        equip.part = equipInfo.part
        --装备品质
        local qualityFarme = RALogicUtil:getItemBgByColor(equipInfo.quality)
        UIExtend.addSpriteToNodeParent(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part), "mQualityNode",qualityFarme)
        --是否能升级标志
        local result,txt = RAEquipManager:getIsUPorEvoById(equip.uuid,0)
        UIExtend.setNodesVisible(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part),{mCanUpgradePic = result})
        --part作为key存一个table
        --RAEquipManager.equipsPart[equip.part] = equip
    end
end

function RALordMainPage:mEquipCell1_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(1)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell2_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(2)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell3_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(3)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell4_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(4)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell5_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(5)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell6_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(6)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell7_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(7)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end

function RALordMainPage:mEquipCell8_onEquipBtn()
    local equip = RAEquipManager:getServerEquipInfoByPart(8)
    RARootManager.OpenPage("RAEquipInfoPage",equip)
end


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function RALordMainPage:setEquipBtnsEnable(isEnable)
    for i=1,8 do
        local equipCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mEquipCell"..i)
       UIExtend.setMenuItemEnable(equipCCB,"mEquipBtn",isEnable)
    end
end

--天赋红点
function RALordMainPage:refreshTalentRedPoint()
    -- body
    local redpointNode = false
    local RATalentManager = RARequire("RATalentManager")
    local count = RATalentManager.getTalentRedPointCount()
    if count > 0 then
        redpointNode = true
        UIExtend.setStringForLabel(self.ccbfile, {mTalentTipsNum = count})
    end
    UIExtend.setNodeVisible(self.ccbfile,'mTalentTipsNode',redpointNode)
end

--指挥官的状态刷新
function RALordMainPage:refreshCommanderState()
    print("refreshCommanderState()")
    local state=RACommandManage:getCommanderState()

    --0：正常 1:被抓 2:释放返回中 3:处决 4:死亡
    UIExtend.setNodeVisible(self.ccbfile,"mCageNode",false)
    UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",false)
    self:setEquipBtnsEnable(true)

    --半身像
    local bustPic=UIExtend.getCCSpriteFromCCB(self.ccbfile,"mUserBustPic")
    UIExtend.setCCSpriteGray(bustPic,false)

    UIExtend.setNodeVisible(self.ccbfile,"mExecuteNode",false)

    if state==1 or state==2 or state==3 then
        self:showCommanderNoNormalStateUI(true)
        self:setEquipBtnsEnable(false)

        --信息显示
        local info=RACommandManage:getCommanderData()
        local name=info.name
        self.enemyName=name
        local level=info.level
        local posX=info.posX
        self.enemyPosX=posX
        local posY=info.posY
        self.enemyPosY=posY
        if name and level and posX and posY then
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonName",name)
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonLevel",_RALang("@ResCollectTargetLevel",level))
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonPos",_RALang("@WorldCoordPos",posX,posY))
        end



        if state==1 or state==3 then
            UIExtend.setNodeVisible(self.ccbfile,"mCmdCapturedNode",true)
            local endTime=RACommandManage:getCommanderEndTime()
            local remainTime = Utilitys.getCurDiffTime(endTime)

            local keyStr="CommanderExcuteTips"
            if state==1 then
                keyStr="CommanderCapturedTips"
            end 
            if remainTime>0 then
                local timeStr = Utilitys.createTimeWithFormat(remainTime)
                local msg=RAStringUtil:getHTMLString(keyStr,timeStr)
                UIExtend.setCCLabelHTMLString(self.ccbfile,"mReleaseCDLabel",msg,300) 
            end 
        elseif state==2 then
             local msg=RAStringUtil:getHTMLString("CommanderReleasingTips",timeStr)
            UIExtend.setCCLabelHTMLString(self.ccbfile,"mReleaseCDLabel",msg,300)
            UIExtend.setNodeVisible(self.ccbfile,"mCmdCapturedNode",false)
        end 
  
    elseif state==4 then
        self:showCommanderNoNormalStateUI(false)
        UIExtend.setCCSpriteGray(bustPic,true)
        self:setEquipBtnsEnable(false)
        UIExtend.setNodeVisible(self.ccbfile,"mExecuteNode",true)
        --信息显示
        local const_conf=RARequire("const_conf")
        local costNum=const_conf.rebornGold.value
        UIExtend.setCCLabelString(self.ccbfile,"ResurrctionNum",costNum)
    end 
end

--指挥官复活
function RALordMainPage:onResurrectionBtn()

    local confirmData = {}
    local const_conf=RARequire("const_conf")
    local costNum=const_conf.rebornGold.value
    confirmData.labelText = _RALang("@CommanderDemutationTips",costNum)
    self.yesNoBtn=true
    confirmData.resultFun =function (isOk)
        if isOk then
             RACommandManage:sendCommanderResurrecReq()
        end 
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)

end

--发邮件请求释放
function RALordMainPage:onReleaseRequestBtn()
    local name=""
    if self.enemyName then
        name =self.enemyName
    end 
    RACommandManage:sendReleaseMail(name)
end

--刷新时间显示
function RALordMainPage:Execute()
    local state=RACommandManage:getCommanderState()
    if state and state==1 or state==3 then
        local keyStr="CommanderExcuteTips"
        if state==1 then
            keyStr="CommanderCapturedTips"
        end 
        mFrameTime = mFrameTime + RA_Common:getFrameTime()
        if mFrameTime > 1 then
           
            local endTime=RACommandManage:getCommanderEndTime()
            local remainTime = Utilitys.getCurDiffTime(endTime)
            if remainTime>=0 then
                local timeStr = Utilitys.createTimeWithFormat(remainTime)
                local msg=RAStringUtil:getHTMLString(keyStr,timeStr)
                UIExtend.setCCLabelHTMLString(self.ccbfile,"mReleaseCDLabel",msg,300) 
            end 

            mFrameTime = 0 
        end
    end 
end

function RALordMainPage:onCheckPosBtn()
    -- body
    if self.enemyPosX and self.enemyPosY then
        RARootManager.CloseAllPages()
        RAWorldManager:LocateAt(self.enemyPosX,self.enemyPosY)
    end   
end
function RALordMainPage:showCommanderNoNormalStateUI(isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mCageNode",true)
    UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",true)
    UIExtend.setNodeVisible(self.ccbfile,"mReleaseCDNode",isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mCommanderKilledNode",not isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mCmdCapturedNode",isVisible)
    UIExtend.setNodeVisible(self.ccbfile,"mResurrectionCmdNode",not isVisible)

end


function RALordMainPage:refreshUI()
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    local portrait = RAPlayerInfoManager.getPlayerBust()
    -- UIExtend.setCCLabelString(self.ccbfile, "mPlayerName", playerInfo.name)--角色名
    local lvStr = "Lv."..playerInfo.level
    UIExtend.setCCLabelString(self.ccbfile, "mGeneralLevel", lvStr)--等级
    UIExtend.setCCLabelString(self.ccbfile, "mPlayerName", playerInfo.name)--名字
    if not RAGameConfig.hero3D then
        UIExtend.setSpriteIcoToNode(self.ccbfile, "mUserBustPic", portrait)--半身像
        UIExtend.setNodeVisible(self.ccbfile, 'mUserBustPic', true)
    else
        local node = UIExtend.getCCNodeFromCCB(self.ccbfile, "mUserBustPic")
        node:setVisible(false)
        node:getParent():removeChildByTag(10086,true)
        local res = RAGameConfig.heroRes or "3d/hero.c3b"
        local obj3d = CCEntity3D:create(res)
        obj3d:stopAllActions()
        obj3d:playAnimation("default",0,48,true)
        obj3d:setAlphaTestEnable(true)
        obj3d:setUseLight(true)
        obj3d:setAmbientLight(1,1,1)  --环境光颜色
        obj3d:setDirectionLightColor(1.0,1.0,1.0)   --设置方向光颜色
        obj3d:setDirectionLightDirection(1,-1,0)    --设置方向光方向
        obj3d:setDiffuseIntensity(1)
        obj3d:setSpecularIntensity(0.5)
        obj3d:setScale(1.7)
        obj3d:setTag(10086)
        self.obj3d = obj3d
        obj3d:setPosition(140,130)
        obj3d:setRotation3D(Vec3(0,15,0))
        node:getParent():addChild(obj3d) 
        self.obj3d = obj3d
        self:createTouchLayout(node:getParent())
    end
    



    local expStr = playerInfo.exp.."/"..RALogicUtil:getNextLevelExp()
    UIExtend.setCCLabelString(self.ccbfile, "mExpBarNum", expStr)--经验条文字
    local expPercent = playerInfo.exp * 1.0 / RALogicUtil:getNextLevelExp()--经验条
    if expPercent >1.0 then
        expPercent = 1.0
    end
    local expBarSp = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mExpBar")
    local expBarSpNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mExpBarNode")
    local expBar = expBarSpNode:getChildByTag(10086)
    if expBar == nil then
        expBar = CCProgressTimer:create(expBarSp)
        expBarSpNode:addChild(expBar)
    end
    expBar:setTag(10086)
    expBar:setPercentage(expPercent * 100)
    expBarSp:setVisible(false)  

    -- UIExtend.setCCScale9SpriteScale(self.ccbfile, "mExpBar", expPercent, true)

    local powerStr = playerInfo.power.."/"..RALogicUtil:getCurrMaxPower()
    UIExtend.setCCLabelString(self.ccbfile, "mStaminaBarNum", powerStr)--体力条文字
    local powerPercent = playerInfo.power * 1.0 / RALogicUtil:getCurrMaxPower()--体力条
    if powerPercent > 1.0 then
        powerPercent = 1.0
    end
    local staminaBarSp = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mStaminaBar")
    local staminaBarSpNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mStaminaBarNode")
    local staminaBar = staminaBarSpNode:getChildByTag(10086)
    if staminaBar == nil then
        staminaBar = CCProgressTimer:create(staminaBarSp)
        staminaBarSpNode:addChild(staminaBar)
    end
    staminaBar:setTag(10086)
    staminaBar:setPercentage(powerPercent * 100)
    staminaBarSp:setVisible(false)     

end


function RALordMainPage:createTouchLayout( parent )
    local layer = parent:getChildByTag(51001);
    if not layer then
        layer = CCLayer:create();
        layer:setTag(51001);
        parent:addChild(layer);
        layer:setContentSize(CCSize(parent:getContentSize().width,parent:getContentSize().height));
        layer:setPosition(parent:getPosition())
        layer:setAnchorPoint(parent:getAnchorPoint())
    end
    layer:setTouchEnabled(true);
    layer:setVisible(true);
    layer:registerScriptTouchHandler(function(eventName,pTouch)
        if eventName == "began" then
            return self:onTouchBegin(eventName,pTouch)
        elseif eventName == "moved" then
            return self:onTouchMove(eventName,pTouch)
        elseif eventName == "ended" then
            return self:onTouchEnd(eventName,pTouch)
        elseif eventName == "cancelled" then
            return self:onTouchCancel(eventName,pTouch)
        end
    end
    ,false,0,false);
end

function RALordMainPage:onTouchBegin( eventName,pTouch )
    local contentSizeNode = self.obj3d:getParent()
    local inside = UIExtend.isTouchInside(contentSizeNode,pTouch)
    if inside then
        local point = pTouch:getLocation()
        RALordMainPage.mBeginPos = point        
        return 1
    end
    return 0
end
function RALordMainPage:onTouchMove( eventName,pTouch )
        local point = pTouch:getLocation()
        local disX = point.x - RALordMainPage.mBeginPos.x

        self.obj3d:setRotation3D(Vec3(0,self.obj3d:getRotation3D().y + disX,0))
end
function RALordMainPage:onTouchCancel( eventName,pTouch )
    RALordMainPage.mBeginPos = nil
end
function RALordMainPage:onTouchEnd( eventName,pTouch )
    RALordMainPage.mBeginPos = nil        
end

function RALordMainPage:refreshTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()    
    if titleCCB then
          
        UIExtend.setCCLabelString(titleCCB, "mTitle", playerInfo.name)
        -- UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
    end


    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage()
            RAGuideManager.gotoNextStep()
        end
        RARootManager.ClosePage("RALordMainPage") 
    end
    local diamondCallBack = function()
        local RARealPayManager = RARequire('RARealPayManager')
        RARealPayManager:getRechargeInfo()
    end

    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RALordMainPage', 
    titleCCB, playerInfo.name, backCallBack, RACommonTitleHelper.BgType.Blue)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, diamondCallBack)    
end

function RALordMainPage:onAddExpBtn()

    local state=RACommandManage:getCommanderState()
    if state and state>0 then return end  

    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.useExp)    

    -- local state=RACommandManage:getCommanderState()
    -- if state and state>0 then return end     
    -- local itemId = 0
    -- local itemCount = 0

    -- local shopItemInfo1 = shop_conf[Const_pb.SHOP_ADD_EXP1]
    -- local itemId1 = shopItemInfo1.shopItemID
    -- local itemCount1 = RACoreDataManager:getItemCountByItemId(itemId1)

    -- local shopItemInfo2 = shop_conf[Const_pb.SHOP_ADD_EXP2]
    -- local itemId2 = shopItemInfo2.shopItemID
    -- local itemCount2 = RACoreDataManager:getItemCountByItemId(itemId2)

    -- local shopItemInfo3 = shop_conf[Const_pb.SHOP_ADD_EXP3]
    -- local itemId3 = shopItemInfo3.shopItemID
    -- local itemCount3 = RACoreDataManager:getItemCountByItemId(itemId3)

    -- if itemCount1>0 then
    --     itemId = itemId1
    --     itemCount = itemCount1
    -- elseif itemCount2 > 0 then
    --     itemId = itemId2
    --     itemCount = itemCount2
    -- elseif itemCount3 > 0 then
    --     itemId = itemId3
    --     itemCount = itemCount3
    -- end

    -- if (itemCount1 + itemCount2 + itemCount3) > 0 then
    --     --具有增加经验的道具
    --     local data = RAPackageManager:getItemInfoByItemId(itemId)
    --     data.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse
	   --  RARootManager.showPackageInfoPopUp(data)
    -- else
    --     --没有增加经验的道具
    --     RARootManager.OpenPage("RAPackageMainPage")
    -- end
end

function RALordMainPage:onAddStaminaBtn()

    local state=RACommandManage:getCommanderState()
    if state and state>0 then return end  

    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack)
--    local itemId = 0
--    local itemCount = 0

--    local shopItemInfo1 = shop_conf[Const_pb.SHOP_ADD_POWER1]
--    local itemId1 = shopItemInfo1.shopItemID
--    local itemCount1 = RACoreDataManager:getItemCountByItemId(itemId1)

--    local shopItemInfo2 = shop_conf[Const_pb.SHOP_ADD_POWER2]
--    local itemId2 = shopItemInfo2.shopItemID
--    local itemCount2 = RACoreDataManager:getItemCountByItemId(itemId2)

--    local shopItemInfo3 = shop_conf[Const_pb.SHOP_ADD_POWER3]
--    local itemId3 = shopItemInfo3.shopItemID
--    local itemCount3 = RACoreDataManager:getItemCountByItemId(itemId3)

--    if itemCount1>0 then
--        itemId = itemId1
--        itemCount = itemCount1
--    elseif itemCount2 > 0 then
--        itemId = itemId2
--        itemCount = itemCount2
--    elseif itemCount3 > 0 then
--        itemId = itemId3
--        itemCount = itemCount3
--    end

--    if (itemCount1 + itemCount2 + itemCount3) > 0 then
--        --具有增加体力的道具
--        local data = RAPackageManager:getItemInfoByItemId(itemId)
--        data.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.itemUse
--      RARootManager.showPackageInfoPopUp(data)
--    else
--        --没有增加体力的道具
--        RARootManager.OpenPage("RAPackageMainPage")
--    end
end

function RALordMainPage:onDetailsBtn()
    local msg = Player_pb.PlayerDetailReq()
    RANetUtil:sendPacket(HP_pb.PLAYER_DETAIL_C, msg)
    RARootManager.ShowWaitingPage(true)
end

function RALordMainPage:onLiftingEffectBtn()
    RARootManager.OpenPage("RALordLiftingEffectPage")
end

function RALordMainPage:onBackBtn()
    RARootManager.ClosePage("RALordMainPage")
end

function RALordMainPage:onChangeNameBtn()
    RARootManager.OpenPage("RALordChangeNamePage", nil,false,false)
end

function RALordMainPage:onChangePortaitBtn()
    RARootManager.OpenPage("RALordHeadChangePage", nil,false,true)
end

function RALordMainPage:onTalentBtn()

    local state=RACommandManage:getCommanderState()

    if state==0 then
        RARootManager.OpenPage("RATalentSysMainPage", nil,false,true,false)
        return 
    end

    local confirmData = {}
    local keyStr=""
    if state==1 or state==2 or state==3 then
        keyStr="@CommanderCapturedTalentTips"
    elseif state==4 then
        keyStr="@CommanderExcutedTalentTips" 
    end
    confirmData.labelText = _RALang(keyStr)
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
end

function RALordMainPage:refreshPortrait()
    print("refreshPortrait()")
    print("self.ccbfile",self.ccbfile)
    local portrait = RAPlayerInfoManager.getPlayerBust()
    if not RAGameConfig.hero3D then
        UIExtend.setSpriteIcoToNode(self.ccbfile, "mUserBustPic", portrait)--半身像
    end
end

function RALordMainPage:refreshName()
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    if self.ccbfile then
        UIExtend.setCCLabelString(self.ccbfile, "mPlayerName", playerInfo.name)

        local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
        if titleCCB then
            UIExtend.setCCLabelString(titleCCB, "mTitle", playerInfo.name)
        end
    end
end

-- function RALordMainPage:refreshHeadImg()
--     local icon = RAPlayerInfoManager.getPlayerBust()
--     if self.ccbfile then
--         UIExtend.setSpriteIcoToNode(self.ccbfile, "mUserBustPic", icon)
--     end
-- end

function RALordMainPage:refreshExpAndPower()
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    local lvStr = "Lv."..playerInfo.level
    UIExtend.setCCLabelString(self.ccbfile, "mGeneralLevel", lvStr)--等级

    local expStr = playerInfo.exp.."/"..RALogicUtil:getNextLevelExp()
    UIExtend.setCCLabelString(self.ccbfile, "mExpBarNum", expStr)--经验条文字
    local expPercent = playerInfo.exp * 1.0 / RALogicUtil:getNextLevelExp()--经验条
    if expPercent >1.0 then
        expPercent = 1.0
    end
    local expBarSpNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mExpBarNode")
    local expBar = expBarSpNode:getChildByTag(10086)
    expBar:setPercentage(expPercent * 100)    

    local powerStr = playerInfo.power.."/"..RALogicUtil:getCurrMaxPower()
    UIExtend.setCCLabelString(self.ccbfile, "mStaminaBarNum", powerStr)--体力条文字
    local powerPercent = playerInfo.power * 1.0 / RALogicUtil:getCurrMaxPower()--体力条
    if powerPercent > 1.0 then
        powerPercent = 1.0
    end
    local staminaBarSpNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mStaminaBarNode")
    local staminaBar = staminaBarSpNode:getChildByTag(10086)
    staminaBar:setPercentage(powerPercent * 100)
end

function RALordMainPage:Exit()
    --刷新指挥官头像上的红点
    MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint)

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RALordMainPage")    
    self:removeHander()
    UIExtend.unLoadCCBFile(RALordMainPage)
    self.ccbfile = nil
end