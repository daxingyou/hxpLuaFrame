--region NewFile_1.lua
--Author : phan
--Date   : 2016/6/23
--此文件由[BabeLua]插件自动生成



--endregion

RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RAStringUtil = RARequire("RAStringUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RAChatManager = RARequire("RAChatManager")
local RAChatData = RARequire("RAChatData")

local RABroadcastPage = BaseFunctionPage:new(...)

--广播列表
RABroadcastPage.broadcastList = {}
local dIndex = 1
local isNowBroadcast = false

function RABroadcastPage:Enter()
    if not self.ccbfile then
        local ccbfile = UIExtend.loadCCBFile("ccbi/RACarouselPage.ccbi",self)
        self.ccbfile = ccbfile
    end
    self:refresh()
end

function RABroadcastPage:startActions(tableL)
    local carouselLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mCarouselLabel")
    self.carouselLabel = carouselLabel
    local updateFun = function()
        dIndex = dIndex + 1
        isNowBroadcast = false
        self:startActions(tableL)  
    end
    if not tableL[dIndex] then 
        carouselLabel:stopAllActions()
        if self.Exit then
            self:Exit()
        end
        --if self.Unload then
            --self:Unload()
        --end
        return
    end

    if not isNowBroadcast then
        local winSize = CCDirector:sharedDirector():getWinSize()
        self.ccbfile:setPosition(ccp(winSize.width/2,winSize.height-160))

        
        --系统消息
        local noticeName = RAChatManager:getMessageNameById(tableL[dIndex].noticeType,tableL[dIndex].name)
        
        local msgContent = tableL[dIndex].chatMsg
        if tableL[dIndex].chatBroadcastMsg ~= nil and tableL[dIndex].chatBroadcastMsg ~= "" then
            msgContent = tableL[dIndex].chatBroadcastMsg
        end

        local levelDesStr = RAStringUtil:fill(html_zh_cn["PlayerBroadcast"],noticeName, msgContent)
        if tableL[dIndex].type == RAChatData.CHAT_TYPE.gmBroadcast then
           levelDesStr = RAStringUtil:fill(html_zh_cn["GMBroadcast"],noticeName, msgContent)
        elseif tableL[dIndex].type == RAChatData.CHAT_TYPE.hrefBroadcast then
           levelDesStr = RAStringUtil:fill(html_zh_cn["NoticeBroadcast"],noticeName, msgContent)
        end

        carouselLabel:setString(levelDesStr)

        carouselLabel:removeLuaClickListener()
        carouselLabel:registerLuaClickListener(RAChatManager.createHtmlClick)

        local clippingNode = UIExtend.getCCClippingNodeFromCCB(self.ccbfile,"mClippingNode")
        clippingNode:setInverted(false)
        carouselLabel:setPositionX(130)
        local width = carouselLabel:getHTMLContentSize().width+290

        width = (128-clippingNode:getContentSize().width)-width/2
        local fdt = math.ceil( width / -60) + 5

        local leftAction = CCMoveBy:create(fdt,ccp(width,0))
        local array = CCArray:create()
        array:addObject(leftAction)
        local funcAction = CCCallFunc:create(updateFun)
        array:addObject(funcAction)
        local sequence = CCSequence:create(array);
        carouselLabel:stopAllActions()
        local action = CCRepeatForever:create(sequence)
        carouselLabel:runAction(action)
        isNowBroadcast = true
    end
end

function RABroadcastPage:refresh()
    if #self.broadcastList ~= 0 then
	    self:startActions(self.broadcastList)
    end
end

function RABroadcastPage:setBroadcastData(tb)
    table.insert(self.broadcastList,tb)
end

function RABroadcastPage:Excute()

end

function RABroadcastPage:Unload()
    CCLuaLog("RABroadcastPage:Exit")
    if self.carouselLabel then
        self.carouselLabel:removeLuaClickListener()
        self.mCarouselLabel = nil
    end
    UIExtend.unLoadCCBFile(self)
end	

function RABroadcastPage:OnAnimationDone(ccbfile)
    
end

function RABroadcastPage:Exit()
	self.broadcastList = {}
    dIndex = 1
    isNowBroadcast = false

    if self.carouselLabel then
        self.carouselLabel:removeLuaClickListener()
        self.mCarouselLabel = nil
    end
    UIExtend.unLoadCCBFile(self)
end

function RABroadcastPage:reset()
    self.broadcastList = {}
    dIndex = 1
    isNowBroadcast = false

    UIExtend.unLoadCCBFile(self)
end

return RABroadcastPage
