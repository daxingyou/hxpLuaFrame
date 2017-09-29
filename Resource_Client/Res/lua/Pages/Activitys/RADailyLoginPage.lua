--TO:活动:每日登陆礼包界面
RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RADailyLoginPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.DAILYLOGIN_GET_REWARD_C then --领取奖励成功
            RADailyLoginPage.dailyLoginInfos[RADailyLoginPage.dailyLoginInfos.dayOfWeek].receiveStatus = 1
            RARootManager.ClosePage("RADailyLoginPage")
            --领取每日登陆奖励后，重新刷一下推送
            local RANotificationManager = RARequire("RANotificationManager")
            RANotificationManager.addAllDailyNotification()
        end 
    end 
end

function RADailyLoginPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RADailyLoginPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RADailyLoginPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RADailyLoginPage.ccbi",self)

    self:registerMessage()
	--top info
    self:initTitle()

    self:refreshUI()
end

function RADailyLoginPage:onReceiveBtn()
    local HP_pb = RARequire("HP_pb")
    local RANetUtil = RARequire("RANetUtil")
    RANetUtil:sendPacket(HP_pb.DAILYLOGIN_GET_REWARD_C,nil,{retOpcode=-1})
end

function RADailyLoginPage.onLongClick(data)
    local dailyLoginInfo = data.handler
    local itemId = dailyLoginInfo.itemId
    local itemType = dailyLoginInfo.itemType
    local itemCount = dailyLoginInfo.itemCount
    local index = dailyLoginInfo.index

    local item_conf = RARequire("item_conf")
    local itemConf = item_conf[itemId]
    --create node
    local ccb = RADailyLoginPage.ccbfile:getCCBFileFromCCB("mCCB"..index)
    local relativeNode = CCNode:create();
    local posX,posY = ccb:getPosition()

    local winSize = CCDirector:sharedDirector():getWinSize()

    relativeNode:setPosition(500,posY+winSize.height/2)
    RADailyLoginPage.ccbfile:addChild(relativeNode)

    --icon
    local RAResManager = RARequire("RAResManager")
    local icon, name = RAResManager:getIconByTypeAndId(itemType, itemId)
    --qualityFarme
    local RALogicUtil = RARequire("RALogicUtil")
    local qualityFarme = RALogicUtil:getItemBgByColor(itemConf.item_color)

    local paramMsg = {}
    paramMsg.title = _RALang(itemConf.item_name)
    paramMsg.htmlStr = _RALang(itemConf.item_des)
    paramMsg.icon = icon
    paramMsg.qualityFarme = qualityFarme
    paramMsg.titleNameColor = itemConf.item_color or 1
    paramMsg.num = "x"..itemCount
    paramMsg.relativeNode = relativeNode
    paramMsg.ccbiFileName = "RADailyLoginTips.ccbi"
    RARootManager.ShowTips(paramMsg)
end

function RADailyLoginPage.onShortClick(data)
    RARootManager.RemoveTips()  
end

function RADailyLoginPage:setNodesVisible(ccbfile,isVisible)
    UIExtend.setNodesVisible(ccbfile,{mYes = isVisible})
    UIExtend.setNodesVisible(ccbfile,{mNo = not isVisible})
end

function RADailyLoginPage:refreshUI()
    local item_conf = RARequire("item_conf")
    local RALogicUtil = RARequire("RALogicUtil")
    local RAResManager = RARequire("RAResManager")
    for k,dailyLoginInfo in ipairs(self.dailyLoginInfos) do
        local cellCcbifile = self.ccbfile:getCCBFileFromCCB("mCCB"..k)
		--星期几name
		UIExtend.setStringForLabel(cellCcbifile,{mWeek = _RALang("@WeekName"..k)})
        --
        local itemId = dailyLoginInfo.itemId
        local itemType = dailyLoginInfo.itemType
        local itemCount = dailyLoginInfo.itemCount

        --icon
        local icon, name = RAResManager:getIconByTypeAndId(itemType, itemId)
        UIExtend.addSpriteToNodeParent(cellCcbifile, "mIconNode",icon)

        --count
        UIExtend.setStringForLabel(cellCcbifile,{mItemNum = "x"..itemCount})

        local itemConf = item_conf[itemId]
        --quality
        local qualityFarme = RALogicUtil:getItemBgByColor(itemConf.item_color)
        UIExtend.addSpriteToNodeParent(cellCcbifile, "mQualityNode",qualityFarme)
        
        --默认都是为false
        UIExtend.setNodesVisible(cellCcbifile,{mYes = false})
        UIExtend.setNodesVisible(cellCcbifile,{mNo = false})
        
        self.mShaderNode = tolua.cast(cellCcbifile:getVariable("mShaderNode"),"CCShaderNode")
        if self.mShaderNode then
            self.mShaderNode:setEnable(false)
        end
        
        if self.dailyLoginInfos.dayOfWeek > k then
            if dailyLoginInfo.receiveStatus == 0 then   --之前的没有领取，显示x
                self:setNodesVisible(cellCcbifile,false)

                local grayNode = cellCcbifile:getCCNodeFromCCB("mGrayNode")
                local grayTag = 10000
                grayNode:getParent():removeChildByTag(grayTag,true)
                local graySprite = GraySpriteMgr:createGrayMask(grayNode,grayNode:getContentSize())
                graySprite:setTag(grayTag)
                graySprite:setPosition(grayNode:getPosition())
                graySprite:setAnchorPoint(grayNode:getAnchorPoint())
                grayNode:getParent():addChild(graySprite)
            else
                self:setNodesVisible(cellCcbifile,true)
            end
        elseif self.dailyLoginInfos.dayOfWeek == k then
            local ReceiveRewardText
            if dailyLoginInfo.receiveStatus ~= 0 then  --今日的已经领取了的话 显示x并且按钮设置为不可点
                self:setNodesVisible(cellCcbifile,true)
                UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mReceiveBtn'):setEnabled(false)
                ReceiveRewardText =  _RALang("@ReseivedAll")
                
                cellCcbifile:runAnimation("Default Timeline")
            else
                if self.mShaderNode then
                    self.mShaderNode:setEnable(true)
                end
                cellCcbifile:runAnimation("CanReceiveAni")
                UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mReceiveBtn'):setEnabled(true)
                ReceiveRewardText =  _RALang("@ReceiveReward")
            end 
            UIExtend.setControlButtonTitle(self.ccbfile, 'mReceiveBtn', ReceiveRewardText)
        end
		
        dailyLoginInfo.index = k
        --注册长按事件
        local tipsBtn = UIExtend.getCCControlButtonFromCCB(cellCcbifile,"mTouchBtn")
        tipsBtn:setVisible(false)
        local mIconNode = cellCcbifile:getCCNodeFromCCB("mIconNode")
        self.mLayer = UIExtend.createClickNLongClick(mIconNode,RADailyLoginPage.onShortClick,
        RADailyLoginPage.onLongClick,{handler = dailyLoginInfo,endedColse = true,delay = 0.0})
	end
end

function RADailyLoginPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    self.ccbfile:getCCBFileFromCCB("mCommonTitleCCB"):runAnimation("InAni")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@DailyLoginTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RADailyLoginPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RADailyLoginPage:isReceiveDailyLogin()
    -- body
    local result = true
    if self.dailyLoginInfos then
        local dayOfWeek = self.dailyLoginInfos.dayOfWeek
        local receiveStatus = self.dailyLoginInfos[dayOfWeek].receiveStatus
        if receiveStatus == 0 then
            result = false
        end
    else
        result = false    
    end 

    return result
end

function RADailyLoginPage:Exit()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RADailyLoginPage")

    self:removeMessageHandler()

    if self.mLayer then
        self.mLayer:removeFromParentAndCleanup(true)
        self.mLayer = nil
    end

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RADailyLoginPage