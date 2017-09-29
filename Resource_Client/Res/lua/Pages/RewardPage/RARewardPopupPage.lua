RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local item_conf = RARequire("item_conf")
local Const_pb = RARequire("Const_pb")
local RALogicUtil = RARequire("RALogicUtil")
local RAResManager = RARequire("RAResManager")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAGuideManager = RARequire("RAGuideManager")

local RARewardPopupPage = BaseFunctionPage:new(...)
RARewardPopupPage.rewardSV = nil
RARewardPopupPage.isSplite = false


---------------------------------------------------------
local RACommonRewardCellListener = {
    rewardMainType = nil,
    rewardId = nil,
    rewardCount = 0
}
function RACommonRewardCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACommonRewardCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local mainType = self.rewardMainType
    local rewardId = self.rewardId
    local rewardCount = self.rewardCount

    --添加品质框
    if mainType and (tonumber(mainType)*0.0001) == Const_pb.TOOL then
        local constItemInfo = item_conf[tonumber(rewardId)]
        if constItemInfo then
            local qualityIcon = RALogicUtil:getItemBgByColor(constItemInfo.item_color)
            UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", qualityIcon,nil, nil, 20000)
        end
    else
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", "Common_u_Quality_04.png",nil, nil, 20000)
    end
    --添加icon
    local icon, name = RAResManager:getIconByTypeAndId(tonumber(mainType), tonumber(rewardId))
    if icon then
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
    end
    if name then
        UIExtend.setCCLabelString(ccbfile, "mCellName", _RALang(name))   
    end
    UIExtend.setCCLabelString(ccbfile, "mRewardCount", rewardCount)   

end

---------------------------------------------------------



function RARewardPopupPage:Enter(data)
    UIExtend.loadCCBFile("RACommonPopUp2.ccbi", self)
    if self.ccbfile then
        self.rewardSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")
    end
    local timeCCbfiel = UIExtend.getCCBFileFromCCB(self.ccbfile,"mRewardStart")

    self.isSplite = data.isSplite
    local rewardArr = data.rewardArr    
    self.notClickClose = false
    self.mBeginPos = nil    
    self:createClickNLongClick()

    self.isSplite = data.isSplite

    if rewardArr then
        timeCCbfiel:registerFunctionHandler({OnAnimationDone = function ( self, ccbfile )
            local lastAnimationName = ccbfile:getCompletedAnimationName()       
            if lastAnimationName == "Default Timeline" then
                RARewardPopupPage:_refreshUI(rewardArr)
            end            
        end})
        local count = #rewardArr
        if count > 4 then count = 4 end
        self.ccbfile:runAnimation("InAni"..count )
        timeCCbfiel:runAnimation("Default Timeline")
    end

end

function RARewardPopupPage:createClickNLongClick( )
    local contentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mContentSizeNode")
    local layer = contentSizeNode:getParent():getChildByTag(51001);
    if not layer then
        layer = CCLayer:create();
        layer:setTag(51001);
        contentSizeNode:getParent():addChild(layer);
        layer:setContentSize(CCSize(contentSizeNode:getContentSize().width,contentSizeNode:getContentSize().height));
        layer:setPosition(contentSizeNode:getPosition())
        layer:setAnchorPoint(contentSizeNode:getAnchorPoint())
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

function RARewardPopupPage:onTouchBegin( eventName,pTouch )
    local contentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mContentSizeNode")
    local inside = UIExtend.isTouchInside(contentSizeNode,pTouch)
    if inside then
        local point = pTouch:getLocation()
        RARewardPopupPage.mBeginPos = point        
        performWithDelay(contentSizeNode,function ( ... )
            RARewardPopupPage.notClickClose = true
        end,0.5)
        return 1
    end
    return 0
end
function RARewardPopupPage:onTouchMove( eventName,pTouch )
        local point = pTouch:getLocation()
        local moveDis = ccpDistance(RARewardPopupPage.mBeginPos, point)
        if moveDis > 20 then  --手抖的话不做处理
            local contentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mContentSizeNode")
            contentSizeNode:stopAllActions()
            RARewardPopupPage.notClickClose = true
        end
end
function RARewardPopupPage:onTouchCancel( eventName,pTouch )
    local contentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mContentSizeNode")
    contentSizeNode:stopAllActions()    
    RARewardPopupPage.notClickClose = false
    RARewardPopupPage.mBeginPos = nil
end
function RARewardPopupPage:onTouchEnd( eventName,pTouch )
    local contentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mContentSizeNode")
    contentSizeNode:stopAllActions()    
    if not RARewardPopupPage.notClickClose then
        RARootManager.ClosePage("RARewardPopupPage")
    else
        RARewardPopupPage.notClickClose = false
        RARewardPopupPage.mBeginPos = nil        
    end
end

--desc:如果传进来的数据是已经分割好的数组，那么直接从数组中取出数据
--如果传进来的数据是以下划线（_）链接的奖励字符串，那么需要进行分割
--传进来的数组必须从1开始
function RARewardPopupPage:_refreshUI(data)
    if data and self.rewardSV then
        self.rewardSV:removeAllCell() 
        if self.isSplite then
            for _, rewardArr in ipairs(data) do
                local mainType = rewardArr.itemType
                local rewardId = rewardArr.itemId
                local rewardCount = rewardArr.itemCount

                local cell = CCBFileCell:create()
                cell:setCCBFile("RACommonPopUp2Cell.ccbi")     
                local listener = RACommonRewardCellListener:new({rewardMainType = mainType, rewardId = rewardId, rewardCount = rewardCount})
                cell:registerFunctionHandler(listener)
                self.rewardSV:addCell(cell)
            end
        else
            for _, rewardString in ipairs(data) do
                local rewardArray = Utilitys.Split(rewardString, "_")
                local mainType = rewardArray[1]
                local rewardId = rewardArray[2]
                local rewardCount = rewardArray[3]

                local cell = CCBFileCell:create()
                cell:setCCBFile("RACommonPopUp2Cell.ccbi")     
                local listener = RACommonRewardCellListener:new({rewardMainType = mainType, rewardId = rewardId, rewardCount = rewardCount})
                cell:registerFunctionHandler(listener)
                self.rewardSV:addCell(cell)
            end
        end       
        
        self.rewardSV:orderCCBFileCells()
        self.rewardSV:setTouchEnabled(#data > 4)
    end
end

function RARewardPopupPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if string.find(lastAnimationName,"InAni") ~=nil then 
        RARootManager.RemoveCoverPage()
    end
end

function RARewardPopupPage:Exit()
    self.notClickClose = false
    self.mBeginPos = nil    
    --新手期，奖励动画播放完成后，进入下一步
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
        RAGuideManager.gotoNextStep()
    end

    if self.rewardSV then
        self.rewardSV:removeAllCell()
        self.rewardSV = nil
    end

    UIExtend.unLoadCCBFile(self)

    self:showLevelUpGrade()
    
end

function RARewardPopupPage:showLevelUpGrade( )

    local RALordUpgradeManager=RARequire("RALordUpgradeManager")
    local nextAvailableReward=RALordUpgradeManager.playerRewardLevel
    if nextAvailableReward==nil then return end
    --只在领主升级的时候判断发送
    RARequire("MessageDefine")
    RARequire("MessageManager")
    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    local playLevel =  RAPlayerInfoManager.getPlayerLevel()
    -- --judge if player is level up, send msg
    if playLevel>nextAvailableReward then
        MessageManager.sendMessage(MessageDef_Lord.MSG_LevelUpgrade)
    end 
    RALordUpgradeManager.playerRewardLevel=nil
end