--region RAChooseBuildPage.lua
--Date  2016/6/1
--author:zhenhui


local RAChooseBuildPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RAChooseBuildManager = RARequire("RAChooseBuildManager")
local RABuildManager = RARequire("RABuildManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local build_conf = RARequire("build_conf")
local build_ui_conf = RARequire("build_ui_conf")
local RAGuideManager = RARequire("RAGuideManager")
local build_limit_conf = RARequire("build_limit_conf")
local PAGE_TYPE = {
    ALL = 0;
    FUN = 1,
    RES = 2,
    DEF = 3,
    OTHER = 4
}
local missionGuideData = nil
local blueColor = ccc3(127,214,255)
local blackColor = ccc3(11,25,39)
local BarScaleAniTimeSpend = 2.0


--key is buildTypeId, value is contentsize and pos
local mGuideTypeBuild = {
    
}


RAChooseBuildPage.lastData = {
    mLastElectricMaxOwn = 0, -- 当前上限
    mLastElectric = 0, -- 当前使用了的电量
    mLastElectricMaxCfg = 0, -- 当前主城决定的上限
}

--local mAllScrollview = nil
local mOtherScrollview = nil
local mCurPage = nil


local RABuildOtherCell = {}

function RABuildOtherCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildOtherCell:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.setNodesVisible(ccbfile,{mWhateverNode = true})
    local mNormalSprite = ccbfile:getCCSpriteFromCCB("mNormalSprite")
    local callback = function ()
    end
    UIExtend.createClickNLongClick(mNormalSprite,callback,
    callback,{handler = self})
end


local RABuildFuncCellTitle = {
}

function RABuildFuncCellTitle:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildFuncCellTitle:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.setCCLabelString(ccbfile,"mCellTitle",self.displayTxt)
    
end

local RABuildFuncCell = {
	
}



function RABuildFuncCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RABuildFuncCell:onRefreshContent(ccbRoot)
	CCLuaLog("RABuildFuncCell:onRefreshContent")
	if not ccbRoot then return end


    --calc worldPos and contentSize data for guide 
	local ccbfile = ccbRoot:getCCBFileNode() 
    ccbfile:getCCBFileFromCCB("mUnlockAniCCB"):setVisible(false)
    local worldPos =  self.container:convertToWorldSpaceAR(ccp(ccbRoot:getPositionX(),ccbRoot:getPositionY()))
    local resSize = UIExtend.getDesignResolutionSize()
    local scale = resSize.height/1136
    local ccbSize = ccbfile:getContentSize()
    ccbSize.height = ccbSize.height * scale
    ccbSize.width = ccbSize.width * scale
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = ccbSize,
        ["cell"] = self
    }
    UIExtend.setNodesVisible(ccbfile,{mWhateverNode = false})
    local buildTypeId = self.cellData.id
    mGuideTypeBuild[buildTypeId] = guideData

    local buildId = self.cellData.id * 100 + 1
    local name = build_conf[buildId].buildName
    self.name = name
    self.ccbfile = ccbfile
	UIExtend.setCCLabelString(ccbfile,"mCellBuildingName",_RALang(name))
    local mSelectSprite = ccbfile:getCCSpriteFromCCB("mSelectSprite")
    if RAChooseBuildManager.mCurChooseBuildId == self.cellData.id then
        mSelectSprite:setVisible(true)
    else
        mSelectSprite:setVisible(false)
    end

    local limitType = build_conf[buildId].limitType
    local mainCityLvl = RABuildManager:getMainCityLvl();
    if mainCityLvl == 0 then mainCityLvl = 1 end ;
    local limitNum = build_limit_conf[limitType]['cyLv'..mainCityLvl]
    local buildTypeCount = RABuildManager:getBuildDataCountByType(self.cellData.id)
    self.limitNum = limitNum
    self.buildTypeCount = buildTypeCount
    --if limitNum ==0, means it's been blocked, and need to display it's reason
    local status = self.cellData.status
    --资源建筑和防御建筑特殊处理
    --status == 2表示上锁，如果不为2，那么判断资源建筑是否到达上线，进行特殊处理
    if status ~= 2 then
        if self.cellData.uiType == 2 then
            if RAChooseBuildManager.mResourceBuildCurNum == RAChooseBuildManager.mResourceBuildTotalNum then
                status = 1
            end
        end
    end
    
    if self.cellData.uiType == 3 and limitNum>0 then
        if RAChooseBuildManager.mDefendBuildCurNum == RAChooseBuildManager.mDefendBuildTotalNum then
            status = 1
        end
    end
    self.cellData.status = status
    if status == 2 then
        UIExtend.setNodesVisible(ccbfile,{
            mRequirementNode = true
        })
        local uiInfo = build_ui_conf[buildTypeId]
--        if uiInfo ~= nil and uiInfo.frontBuild~=nil then
--            local limitStr = _RALang("@BuildDetailRequirement",_RALang(build_conf[uiInfo.frontBuild].buildName),build_conf[uiInfo.frontBuild].level)
--            ccbfile:getCCLabelTTFFromCCB("mLimitCondition"):setString(limitStr)
--        end
    
    else
        UIExtend.setNodesVisible(ccbfile,{
            mRequirementNode = false
        })
    end

    local mNormalSprite = ccbfile:getCCSpriteFromCCB("mNormalSprite")
    local mBuildingNum  = ccbfile:getCCLabelTTFFromCCB("mBuildingNum")
    if self.cellData.uiType == 1 then
        mBuildingNum:setString(buildTypeCount.."/"..limitNum)
    else
        mBuildingNum:setString(buildTypeCount)
    end
    

    local mIconSprite = ccbfile:getCCSpriteFromCCB("mIconSprite")
    mIconSprite:setTexture(build_ui_conf[buildTypeId].pic)
    
    local containsPoint = function ( worldPos )
        local scrollView = self.scrollView
        return UIExtend.scrollViewContainPoint(scrollView, worldPos)
    end    
    UIExtend.createClickNLongClick(mNormalSprite,RABuildFuncCell.onShortClick,
    RABuildFuncCell.onLongClick,{handler = self,endedColse = true,delay = 0.2, containsPoint = containsPoint})

    local mainNode = ccbfile:getCCNodeFromCCB("mIconSprite")
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    if status > 0  then
        local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
        graySprite:setTag(grayTag)
        graySprite:setPosition(mainNode:getPosition())
        graySprite:setAnchorPoint(mainNode:getAnchorPoint())
        mainNode:getParent():addChild(graySprite)
    end
end

function RABuildFuncCell.onLongClick(data)
    local handler = data.handler
    local status = handler.cellData.status
    --if status == 0  then
        handler.ccbfile:getCCBFileFromCCB("mTouchAniCCB"):setVisible(true)
        handler.ccbfile:getCCBFileFromCCB("mTouchAniCCB"):runAnimation("LoadAni")
    --end
    
    --长按音效
    common:playEffect("buildingWait")

    -- MessageManager.sendMessage(MessageDef_ChooseBuild.MSG_ChooseBuild_ShowDetail,{buildTypeId = handler.cellData.id})
    local buildTypeId = handler.cellData.id
    local strLabel = handler.limitNum
    local buildTypeCount = handler.buildTypeCount

    local showTipsHander = function ()
        local paramMsg = {}
        paramMsg.title = _RALang(handler.name)
        paramMsg.num = handler.buildTypeCount.."/"..handler.limitNum
        paramMsg.htmlStr = RAChooseBuildManager:generateTipHtmlStrByTypeId(buildTypeId,status)
        paramMsg.relativeNode = handler.ccbfile
        RARootManager.ShowTips(paramMsg)
        RAChooseBuildManager.isLongClick = true
    end

    local callfunc = CCCallFunc:create(showTipsHander)
    local delay = CCDelayTime:create(1)
    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
    handler.ccbfile:runAction(sequence)

    --RAChooseBuildManager:removeNewUnlockInfo(handler.cellData)
end

function RABuildFuncCell.onShortClick(data)

    local handler = data.handler
    handler.ccbfile:getCCBFileFromCCB("mTouchAniCCB"):setVisible(false)

    handler.ccbfile:stopAllActions()
    if data.hasMove == true then
        RAChooseBuildManager.isLongClick  = false
        return RARootManager.RemoveTips()  
    end

    --如果是长按的TouchEnd回调，则关闭Tips
    if data.isLongClick  == true then
        RAChooseBuildManager.isLongClick  = false
        return RARootManager.RemoveTips()  
    end

    --RAChooseBuildManager:removeNewUnlockInfo(handler.cellData)

    local status = handler.cellData.status
    if status > 0  then
        return
    end

    --播放音效
    common:playEffect("vbuilding")

    if RAChooseBuildPage.isDefense then 
        RAChooseBuildManager:buildNew(handler.cellData.id,RAChooseBuildPage.isDefense,RAChooseBuildPage.targetPos)
    else 
        RAChooseBuildManager:buildNew(handler.cellData.id)
        --点击建造建筑，移除CoverPage和guidePage：add by xinghui
        RARootManager.RemoveCoverPage()
        RARootManager.RemoveGuidePage()
    end

end

function RAChooseBuildPage:_scaleCCB()
    local resSize = UIExtend.getDesignResolutionSize()
    local scale = resSize.height/1136
    --if self.ccbfile:getIsFirstCreate() then
        local mAniNode = self.ccbfile:getCCNodeFromCCB("mAniNode")
        mAniNode:setScale(scale)
    --end

end

function RAChooseBuildPage:getGuideNodeInfo(constGuideInfo)
    
    local buildTypeId = constGuideInfo.buildType
    local buildUI = build_ui_conf[buildTypeId]
    if buildUI ~= nil then
        local uiType = buildUI.uiType
        self:ChangePage(uiType, buildTypeId)
    else
        self:ChangePage(PAGE_TYPE.FUN, buildTypeId)
    end

    -- mAllScrollview:refreshAllCell()
    mOtherScrollview:refreshAllCell()
    assert(buildTypeId ~= nil, "error")
    local guideData = mGuideTypeBuild[buildTypeId]
    return guideData
   
end

function RAChooseBuildPage:resetBarData()
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

function RAChooseBuildPage:Enter(data)
    RAChooseBuildPage:registerMessageHandlers()
    local ccbfile = UIExtend.loadCCBFile("RAConstructionPage.ccbi",self)
    self:_scaleCCB()
    --clear data
    --self:_closeSelectBuildInfo()
    RAChooseBuildManager.mCurChooseBuildId = 0
    RAChooseBuildManager.showBuildId = 0
    self.isDefense = false
    self.targetPos = false



    --mAllScrollview = ccbfile:getCCScrollViewFromCCB("mAllListSV")
    mOtherScrollview = ccbfile:getCCScrollViewFromCCB("mOthersListSV")
    --assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    assert(mOtherScrollview~=nil,"mOtherScrollview~=nil")


    -- 三个进度条
    self.mBarSizeNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarSizeNode")
    self.mBarSizeHeight = self.mBarSizeNode:getContentSize().height
    self.mFrontBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mFrontBar")
    self.mYellowPowerBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mYellowPowerBar")
    self.mRedPowerBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mRedPowerBar")
    self:resetBarData()
    self:updateElectric(true)

    self:AllCCBRunAnimation("InAni")

    self.ccbfile:getCCMenuItemCCBFileFromCCB("mFunBtn"):setEnabled(true)
    self.ccbfile:getCCMenuItemCCBFileFromCCB("mDefBtn"):setEnabled(true)
    self.ccbfile:getCCMenuItemCCBFileFromCCB("mResBtn"):setEnabled(true)   
    self.ccbfile:getCCMenuItemCCBFileFromCCB("mAllBtn"):setEnabled(true) 
    self.ccbfile:getCCMenuItemCCBFileFromCCB("mOtherBtn"):setEnabled(true) 

    --self.ccbfile:getCCMenuItemCCBFileFromCCB("mFunBtn"):getCCBFile():runAnimation("looptouchend")
    if data ~= nil then
        if data.isDefense then 
            if data.pos then
                self.isDefense = true
                self.targetPos = data.pos
            end
            self.ccbfile:getCCMenuItemCCBFileFromCCB("mFunBtn"):setEnabled(false)
            self.ccbfile:getCCMenuItemCCBFileFromCCB("mDefBtn"):setEnabled(true)
            self.ccbfile:getCCMenuItemCCBFileFromCCB("mResBtn"):setEnabled(false)   
            self.ccbfile:getCCMenuItemCCBFileFromCCB("mAllBtn"):setEnabled(false)
            self.ccbfile:getCCMenuItemCCBFileFromCCB("mOtherBtn"):setEnabled(false)  
            self:ChangePage(PAGE_TYPE.DEF)
        else 
            missionGuideData = data.GuideData
            if missionGuideData ~= nil then
                local buildUI = build_ui_conf[missionGuideData.buildType]
                if buildUI ~= nil then
                    local uiType = buildUI.uiType
                    self:ChangePage(uiType, missionGuideData.buildType)
                else
                    self:ChangePage(PAGE_TYPE.FUN, missionGuideData.buildType)
                end
            end
        end 
    else
        self:ChangePage(PAGE_TYPE.FUN)
    end
    
    self.inAnimation = true
end




-- 电力发生改变的时候需要调用
-- 页面 CCB_InAni 完成的时候调用
function RAChooseBuildPage:updateElectric(isNoAni)
    local const_conf = RARequire('const_conf')
    local isNoAni = isNoAni or false
    -- 当前主城等级对应的电量上限
    local electricCfgMax = RAPlayerInfoManager.getCurrElectricMaxCfgValue()
    -- 当前产电量上限
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    -- 当前用电量
    local currElectricUse = RAPlayerInfoManager.getCurrElectricValue()

    local electric_cap1 = const_conf.electric_cap1.value
    local electric_cap2 = const_conf.electric_cap2.value
    local checkPercent = function(percent)
        if percent < 0 then
            return 0
        end
        if percent > 1 then
            return 1
        end
        return percent
    end

    local greenScaleTo = 0
    local yellowScaleTo = 0
    local redScaleTo = 0

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
        local frontBar = self.mFrontBar
        local yellowBar = self.mYellowPowerBar
        local redBar = self.mRedPowerBar
        if isGreenScale then
            scaleToActionFunc(frontBar, (1 - greenScaleTo) * self.mBarSizeHeight, BarScaleAniTimeSpend * greenScaleTo)        
        end
        if isYellowScale then
            scaleToActionFunc(yellowBar, yellowScaleTo * self.mBarSizeHeight, BarScaleAniTimeSpend * yellowScaleTo)
        end
        if isRedScale then
            scaleToActionFunc(redBar, redScaleTo * self.mBarSizeHeight, BarScaleAniTimeSpend * redScaleTo)
        end
    end
    

    self.lastData.mLastElectricMaxCfg = electricCfgMax
    self.lastData.mLastElectricMaxOwn = currElectricMax
    self.lastData.mLastElectric = currElectricUse
end

function RAChooseBuildPage:Exit()
    RAChooseBuildPage:unregisterMessageHandlers()
    mOtherScrollview:removeAllCell()
    --mAllScrollview:removeAllCell()
    mGuideTypeBuild = {}
    missionGuideData = nil
    -- self:resetBarData()
    UIExtend.unLoadCCBFile(self)
    mCurPage = nil

end


function RAChooseBuildPage:ChangePage(pageIndex, showBuildId)

    if self.isDefense == true then 
        if pageIndex ~= PAGE_TYPE.DEF then 
            self:_setNodeVisible()
            return 
        end 
    end 

    if pageIndex == mCurPage then
        self:_setNodeVisible()
        return
    end
    mCurPage = pageIndex
    --Òþ²Øinfoccb,Çå¿ÕchooseBuildId
    --self:_closeSelectBuildInfo()
    RAChooseBuildManager.mCurChooseBuildId = 0
    RAChooseBuildManager.showBuildId = showBuildId or 0
    --RARootManager.refreshPage("RAChooseBuildPage")
    self:CommonRefresh()
end

--function RAChooseBuildPage:mConstructionInfoCCB_onCunstructionBtn()
--    if RAChooseBuildManager.mCurChooseBuildId > 0 then
--        RAChooseBuildManager:buildNew(RAChooseBuildManager.mCurChooseBuildId)
--    end
--end


local OnReceiveMessage = function (message)
 CCLuaLog("RAChooseBuildPage OnReceiveMessage id:"..message.messageID)

    if message.messageID == MessageDef_ChooseBuild.MSG_ChooseBuild_ShowDetail then
        if message.buildTypeId ~= nil then
            RAChooseBuildPage:_refreshSelectBuildInfo(message.buildTypeId)
        end
    end

    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        CCLuaLog("MessageDef_MainUI MSG_UpdateBasicPlayerInfo")
        RAChooseBuildPage:updateElectric()
    end
end

function RAChooseBuildPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_ChooseBuild.MSG_ChooseBuild_ShowDetail, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_ChooseBuild.MSG_ChooseBuild_refreshSelect, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RAChooseBuildPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_ChooseBuild.MSG_ChooseBuild_ShowDetail, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_ChooseBuild.MSG_ChooseBuild_refreshSelect, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RAChooseBuildPage:_closeSelectBuildInfo()
--    local detailCcbfile = self.ccbfile:getCCBFileFromCCB("mConstructionInfoCCB")
--    detailCcbfile:setVisible(false)
--    UIExtend.setNodeVisible(self.ccbfile,"mBigClose",true)
end

function RAChooseBuildPage:_showSelectBuildInfo()
--    local detailCcbfile = self.ccbfile:getCCBFileFromCCB("mConstructionInfoCCB")
--    detailCcbfile:setVisible(true)
--    UIExtend.setNodeVisible(self.ccbfile,"mBigClose",false)
end

local getDesTxtByBuildTypeId = function (buildTypeId)
    local finalStr = ""
    local conf =  build_ui_conf[buildTypeId]
    if conf.string1 ~= nil and conf.v1 ~= nil then
        finalStr = finalStr.._RALang(conf.string1)..conf.v1.."\n"
    end
    if conf.string2 ~= nil and conf.v2 ~= nil then
        finalStr = finalStr.._RALang(conf.string2)..conf.v2.."\n"
    end
    if conf.string3 ~= nil and conf.v3 ~= nil then
        finalStr = finalStr.._RALang(conf.string3)..conf.v3
    end
    return finalStr
end

function RAChooseBuildPage:_refreshSelectBuildInfo(buildTypeId)
    --self:_showSelectBuildInfo();
    

    if mCurPage == PAGE_TYPE.ALL then
        --mAllScrollview:refreshAllCell()
    else
        mOtherScrollview:refreshAllCell()
    end
end

local function setCCBFileButtonSelected(ccbfile,map)
    for k,v in pairs (map) do 
        if v == true then
            ccbfile:getCCMenuItemCCBFileFromCCB(k):getCCBFile():runAnimation("looptouchend")
        else
            ccbfile:getCCMenuItemCCBFileFromCCB(k):getCCBFile():runAnimation("normal")
        end
    end
    if RAChooseBuildManager.unlockTabList ~= nil then
        for k,v in pairs(RAChooseBuildManager.unlockTabList ) do 
            if v ~= nil then
                if k == 1 then 
                    ccbfile:getCCMenuItemCCBFileFromCCB("mFunBtn"):getCCBFile():runAnimation("NewTipsAni")
                elseif k == 2 then
                    ccbfile:getCCMenuItemCCBFileFromCCB("mResBtn"):getCCBFile():runAnimation("NewTipsAni")
                elseif k == 3 then
                    ccbfile:getCCMenuItemCCBFileFromCCB("mDefBtn"):getCCBFile():runAnimation("NewTipsAni")
                end
            end
        end
    end

end



function RAChooseBuildPage:_setNodeVisible()
    self.ccbfile:getCCBFileFromCCB("mTopAniCCB"):runAnimation("InAni")
    if mCurPage == PAGE_TYPE.ALL then
        UIExtend.setNodesVisible(self.ccbfile,{
            mAllListSV = true,
            mOthersListSV = false
        })
        setCCBFileButtonSelected(self.ccbfile,{
            mAllBtn = true,
            mFunBtn = false,
            mResBtn = false,
            mDefBtn = false,
        })
        UIExtend.setNodesVisible(self.ccbfile,{
            mTitlePicNode1 = true,
            mTitlePicNode2 = false,
            mTitlePicNode3 = false,
            mTitlePicNode4 = false,
            mTitlePicNode5 = false,
        })
        
        --mConstructionTitle
        UIExtend.setStringForLabel(self.ccbfile,{mConstructionTitle = _RALang("@ChooseBuildTitleAll")})

    else
        UIExtend.setNodesVisible(self.ccbfile,{
            mAllListSV = false,
            mOthersListSV = true
        })
        if RAGuideManager.isInGuide() then
            mOtherScrollview:setTouchEnabled(false)
        end
    end

    if mCurPage == PAGE_TYPE.FUN then
    setCCBFileButtonSelected(self.ccbfile,{
            mAllBtn = false,
            mFunBtn = true,
            mResBtn = false,
            mDefBtn = false,
            mOtherBtn = false,
        })
        UIExtend.setNodesVisible(self.ccbfile,{
            mTitlePicNode1 = false,
            mTitlePicNode2 = true,
            mTitlePicNode3 = false,
            mTitlePicNode4 = false,
            mTitlePicNode5 = false,
            mComingSoon = false,
        })
        UIExtend.setStringForLabel(self.ccbfile,{mConstructionTitle = _RALang("@ChooseBuildTitleFun")})

    elseif mCurPage == PAGE_TYPE.RES then
    setCCBFileButtonSelected(self.ccbfile,{
            mAllBtn = false,
            mFunBtn = false,
            mResBtn = true,
            mDefBtn = false,
            mOtherBtn = false,
        })
        UIExtend.setNodesVisible(self.ccbfile,{
            mTitlePicNode1 = false,
            mTitlePicNode2 = false,
            mTitlePicNode3 = true,
            mTitlePicNode4 = false,
            mTitlePicNode5 = false,
            mComingSoon = false,
        })
        UIExtend.setStringForLabel(self.ccbfile,{mConstructionTitle = _RALang("@ChooseBuildTitleRes")})

    elseif mCurPage == PAGE_TYPE.DEF then
    setCCBFileButtonSelected(self.ccbfile,{
            mAllBtn = false,
            mFunBtn = false,
            mResBtn = false,
            mDefBtn = true,
            mOtherBtn = false,al
        })
        UIExtend.setNodesVisible(self.ccbfile,{
            mTitlePicNode1 = false,
            mTitlePicNode2 = false,
            mTitlePicNode3 = false,
            mTitlePicNode4 = true,
            mTitlePicNode5 = false,
            mComingSoon = false,
        })
        UIExtend.setStringForLabel(self.ccbfile,{mConstructionTitle = _RALang("@ChooseBuildTitleDef")})
    elseif mCurPage == PAGE_TYPE.OTHER then
    setCCBFileButtonSelected(self.ccbfile,{
            mAllBtn = false,
            mFunBtn = false,
            mResBtn = false,
            mDefBtn = false,
            mOtherBtn = true,
        })
        UIExtend.setNodesVisible(self.ccbfile,{
            mTitlePicNode1 = false,
            mTitlePicNode2 = false,
            mTitlePicNode3 = false,
            mTitlePicNode4 = false,
            mTitlePicNode5 = true,
            mComingSoon = true,
        })
        UIExtend.setStringForLabel(self.ccbfile,{mConstructionTitle = _RALang("@ChooseBuildTitleOther")})
        UIExtend.setStringForLabel(self.ccbfile,{mComingSoon = _RALang("@ComingSoon")})
    end
end

function RAChooseBuildPage:_refreshAllScrollview()
--    local pageData = RAChooseBuildManager.mAllBuild
--    mAllScrollview:removeAllCell()

--    for k,v in pairs(pageData) do 
--        local cell = CCBFileCell:create()
--		cell:setCCBFile("RAConstructionCell.ccbi")
--		local panel = RABuildFuncCell:new({
--				cellData = v,
--                container = mAllScrollview:getContainer()
--        })
--		cell:registerFunctionHandler(panel)
--		mAllScrollview:addCell(cell)
--    end
--    mAllScrollview:orderCCBFileCells()
end

function RAChooseBuildPage:_refreshRealOtherScrollview()
    mOtherScrollview:removeAllCell()

     for i=1,10,1 do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RAConstructionCell.ccbi")
		local panel = RABuildOtherCell:new()
		cell:registerFunctionHandler(panel)
		mOtherScrollview:addCell(cell)
    end
    mOtherScrollview:orderCCBFileCells()
    mOtherScrollview:setTouchEnabled(false)
end


function RAChooseBuildPage:_refreshOtherScrollview()
    local pageData = nil
    mOtherScrollview:removeAllCell()
    mOtherScrollview:setTouchEnabled(true)
    if mCurPage == PAGE_TYPE.FUN then
        pageData = RAChooseBuildManager.mFunctionBuild
        
    elseif mCurPage == PAGE_TYPE.RES then
        pageData = RAChooseBuildManager.mResourceBuild
        local cell = CCBFileCell:create()
		cell:setCCBFile("RAConstructionCellTitle.ccbi")
        local handler = RABuildFuncCellTitle:new({
            displayTxt = _RALang("@ChooseBuildTitleRes")..
            RAChooseBuildManager.mResourceBuildCurNum.."/"..RAChooseBuildManager.mResourceBuildTotalNum
        })
        cell:registerFunctionHandler(handler)
		mOtherScrollview:addCell(cell)
    elseif mCurPage == PAGE_TYPE.DEF then
        pageData = RAChooseBuildManager.mDefendBuild
        local cell = CCBFileCell:create()
		cell:setCCBFile("RAConstructionCellTitle.ccbi")
        local handler = RABuildFuncCellTitle:new({
            displayTxt = _RALang("@ChooseBuildTitleDef")..
            RAChooseBuildManager.mDefendBuildCurNum.."/"..RAChooseBuildManager.mDefendBuildTotalNum
        })
        cell:registerFunctionHandler(handler)
		mOtherScrollview:addCell(cell)
    end
    

    local showIndex = 1
    local cellCount = 0
    local cellHeight = 0
    local needNewUnlockList = {}
    for k,v in pairs(pageData) do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RAConstructionCell.ccbi")
		local panel = RABuildFuncCell:new({
				cellData = v,
                scrollView = mOtherScrollview,
                container = mOtherScrollview:getContainer()
        })
		cell:registerFunctionHandler(panel)
		mOtherScrollview:addCell(cell)
        cellHeight = cell:getContentSize().height
        if RAChooseBuildManager.unlockList[v.id] ~= nil then
            table.insert(needNewUnlockList,cell)
            RAChooseBuildManager:removeNewUnlockInfo(v)
        end
        cellCount = cellCount + 1
        if v.id == RAChooseBuildManager.showBuildId then
            showIndex = cellCount
        end
    end
    -- mOtherScrollview 移动到显示出指定cell
    showIndex = math.ceil(showIndex/2)
    mOtherScrollview:orderCCBFileCells()
    local scrollViewShowCellNum = math.ceil(mOtherScrollview:getViewSize().height / cellHeight)
    if showIndex > scrollViewShowCellNum then
        local preOffest = mOtherScrollview:getContentOffset()
        mOtherScrollview:setContentOffset(ccp(preOffest.x, preOffest.y + (showIndex - scrollViewShowCellNum)* cellHeight))
    end

    for k,v in pairs(needNewUnlockList) do 
        if not RAGuideManager.isInGuide() then
            if v and v:getCCBFileNode() then
                v:getCCBFileNode():getCCBFileFromCCB("mUnlockAniCCB"):setVisible(true)
                v:getCCBFileNode():getCCBFileFromCCB("mUnlockAniCCB"):runAnimation("UnlockAni")
            end    
        end
    end

    if RAGuideManager.isInGuide() then
       mOtherScrollview:setTouchEnabled(false) 
    end
end

function RAChooseBuildPage:_setOtherData()
    local strMap = {}

    strMap["mAllNum"] = RAChooseBuildManager.mAllBuildCurNum.."/"..RAChooseBuildManager.mAllBuildTotalNum
    UIExtend.setStringForLabel(self.ccbfile:getCCMenuItemCCBFileFromCCB("mAllBtn"):getCCBFile(),strMap)
    strMap = {}
    strMap["mFunctionNum"] = RAChooseBuildManager.mFunctionBuildCurNum.."/"..RAChooseBuildManager.mFunctionBuildTotalNum
    UIExtend.setStringForLabel(self.ccbfile:getCCMenuItemCCBFileFromCCB("mFunBtn"):getCCBFile(),strMap)
    strMap = {}
    strMap["mResNum"] =RAChooseBuildManager.mResourceBuildCurNum.."/".. RAChooseBuildManager.mResourceBuildTotalNum
    UIExtend.setStringForLabel(self.ccbfile:getCCMenuItemCCBFileFromCCB("mResBtn"):getCCBFile(),strMap)
    strMap = {}
    strMap["mDefenseNum"] =RAChooseBuildManager.mDefendBuildCurNum.."/" ..RAChooseBuildManager.mDefendBuildTotalNum
    UIExtend.setStringForLabel(self.ccbfile:getCCMenuItemCCBFileFromCCB("mDefBtn"):getCCBFile(),strMap)


end

function RAChooseBuildPage:CommonRefresh()
    RAChooseBuildManager:generateData()
    --node related
    self:_setNodeVisible()
    --num related
    --self:_setOtherData()
    if mCurPage == PAGE_TYPE.OTHER then
        self:_refreshRealOtherScrollview()
    else
        self:_refreshOtherScrollview()
    end
end


--function related
function RAChooseBuildPage:onClose(data)

    if not self.inAnimation then
        --新手期屏蔽：xinghui
        if RAGuideManager.isInGuide() then
            return
        end
        RARootManager.ShowWaitingPage(true)
        self:AllCCBRunAnimation("OutAni")
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true})
        RARootManager.RemoveGuidePage()--移除引导页：解决任务引导中，快速点击，本页隐藏而留下guidepage的bug
        RARootManager.RemoveCoverPage()
    end
end

function RAChooseBuildPage:onAllBtn(data)
    self:ChangePage(PAGE_TYPE.ALL)
end

function RAChooseBuildPage:onFunBtn(data)
    self:ChangePage(PAGE_TYPE.FUN)
end

function RAChooseBuildPage:onResBtn(data)
    self:ChangePage(PAGE_TYPE.RES)
end

function RAChooseBuildPage:onDefBtn(data)
    self:ChangePage(PAGE_TYPE.DEF)
end

function RAChooseBuildPage:onOtherBtn(data)
    self:ChangePage(PAGE_TYPE.OTHER)
end


function RAChooseBuildPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == "OutAni" then
        RARootManager:CloseCurrPage();
        
    end

    if lastAnimationName == "InAni" then
        self:updateElectric()

        self.inAnimation = false
        if RAGuideManager.isInGuide() then
           mOtherScrollview:setTouchEnabled(false) 
        end
        --任务引导回调
        if missionGuideData ~= nil then
            local guideData = self:getGuideNodeInfo(missionGuideData)
            MessageManager.sendMessage(MessageDef_Guide.MSG_TaskGuide, guideData)
            print("guideData.cell.cellData.status = ",guideData.cell.cellData.status)
            if guideData.cell.cellData.status > 0 then
                RAChooseBuildPage:ShowTips(guideData.cell)
            end
        end
        
        --新手：xinghui
        RAGuideManager.gotoNextStep()
    end     
end

function RAChooseBuildPage:ShowTips( Celldata )
    local strLabel = Celldata.limitNum
    local buildTypeCount = Celldata.buildTypeCount

    local paramMsg = {}
    paramMsg.title = _RALang(Celldata.name)
    paramMsg.num = Celldata.buildTypeCount.."/"..Celldata.limitNum
    paramMsg.htmlStr = RAChooseBuildManager:generateTipHtmlStrByTypeId(Celldata.cellData.id,Celldata.cellData.status)
    paramMsg.relativeNode = Celldata.ccbfile
    RARootManager.ShowTips(paramMsg)
end


--packet related

function RAChooseBuildPage:onReceivePacket(handler)
	local opcode = handler:getRecOpcode()
	if opcode == OP_pb.OPCODE_S_WearEquip_RET then
		local msg = UserEquip_pb.OP_S_WearEquip_RET()
		local msgbuff = handler:getRecPacketBuffer()
		msg:ParseFromString(msgbuff)
        RARootManager.refreshPage("RAChooseBuildPage")
   end
end

--endregion
