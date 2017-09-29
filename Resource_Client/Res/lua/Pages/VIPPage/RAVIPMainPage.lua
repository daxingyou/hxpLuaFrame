RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RANetUtil = RARequire("RANetUtil")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAVIPDataManager = RARequire("RAVIPDataManager")
local RA_Common = RARequire("common")

local RAVIPMainPage = BaseFunctionPage:new(...)
local RAVIPMainPageHandler = {}
RAVIPMainPage.scrollView = nil

local timeCount=0
---------------------------scroll content cell---------------------------
local RAContentCellListener = {
contentIndex = 1,
contentInfo = nil
}
function RAContentCellListener:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function RAContentCellListener:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile = ccbfile
	if ccbfile then
		UIExtend.handleCCBNode(ccbfile)
		local currVIPConfig = self.contentInfo
		if currVIPConfig then
			local vipAttrConfig=RAVIPDataManager.getVIPAttrConfig()
			if 	vipAttrConfig~=nil then
				local increaseValue=""
				if currVIPConfig.increaseKey~=nil then
					local increaseKey=currVIPConfig.increaseKey
					for k,v in pairs(increaseKey) do
						if v~=nil then
							if increaseValue~="" then
								increaseValue=increaseValue.."\n"
							end	
							increaseValue=increaseValue.." "..tostring(v.columnValue)..RAVIPDataManager.getVIPConfigValueSymbol(currVIPConfig,v)
						end
					end
				end
				UIExtend.setCCLabelString(ccbfile, "mCellDetailsLabel",increaseValue)
			end
			UIExtend.setCCLabelBMFontString(ccbfile, "mVIPLevelLabel", "VIP"..tostring(currVIPConfig.level))
		end
	end

	local isGray=false
	local player=RAVIPDataManager.getPlayerData()
	if player~=nil and tonumber(player.vipLevel)<tonumber(self.contentIndex) then
		isGray=true
	end
	self:setContentGray(isGray)

end

function RAContentCellListener:setContentGray(isGray)
	local mainNode = self.ccbfile:getCCNodeFromCCB("mGrayNode")
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    if isGray then
        local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
        graySprite:setTag(grayTag)
        graySprite:setPosition(mainNode:getPosition())
        graySprite:setAnchorPoint(mainNode:getAnchorPoint())
        mainNode:getParent():addChild(graySprite)
    end
end

function RAContentCellListener:onClickVIPCellBtn()
	RAVIPMainPage:showVIPDiff(self.contentIndex)
end
---------------------------scroll content cell---------------------------

--MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo,{})
function RAVIPMainPage:Enter(data)
	UIExtend.loadCCBFile("RAVIPPage.ccbi", RAVIPMainPage)
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mVIPListSV")
	
	self:addHandler()
	self:refreshUI()
	
	--请求排行数据，初次请求排行领主战力排行
	self:LoadVIPData()
	self:renderVIPContent()
	self:renderActiveStatus()
end

--这里需要处理刷新时间
function RAVIPMainPage:Execute()
    timeCount=timeCount+1
    if timeCount%5==0 then
	    self:refereshEndTime()
    end
end

function RAVIPMainPage:refreshUI()
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    if titleCCB then
         UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
    end

	if titleCCB~=nil then
        local RACommonTitleHelper = RARequire('RACommonTitleHelper')

		local backCallBack = function()
			RARootManager.ClosePage("RAVIPMainPage")

		end
		
		local titleName = _RALang("@VIPTitle")
		local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAVIPMainPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
	end
end

--计算VIP当前剩余时间，刷新页面VIP倒计时以及VIP激活状态
function RAVIPMainPage:refereshVIPActiveStatus(isActive)

	if isActive==nil then
		self:renderActiveStatus()
		return
	end	

	if isActive~=RAVIPDataManager.Object.isActive then
		RAVIPDataManager.Object.isActive=isActive
		self:renderActiveStatus()
	end
end

--刷新VIP激活相关面板
function RAVIPMainPage:renderActiveStatus()
	--CCLuaLog("RAVIPMainPage:refereshEndTime() VIPServerData.isActive:"..tostring(RAVIPDataManager.Object.isActive))
	
	--todo
	--1、vip激活等级面板
	--2、开启、关闭按钮状态调整
	--3、其他信息面板刷新

	local mainNode = self.ccbfile:getCCNodeFromCCB("mGrayNode")
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    if not RAVIPDataManager.Object.isActive then
        local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
        graySprite:setTag(grayTag)
        graySprite:setPosition(mainNode:getPosition())
        graySprite:setAnchorPoint(mainNode:getAnchorPoint())
        mainNode:getParent():addChild(graySprite)
    end
end

--刷新VIP倒计时面板
function RAVIPMainPage:refereshEndTime(refreshGray)
	local player=RAVIPDataManager.getPlayerData()
	local endTime=tonumber(player.vipEndTime)/1000
	if endTime==nil or endTime<RA_Common:getCurTime() then
		endTime=0
	end
	local lastTime=0
	if endTime~=0 then
		lastTime= Utilitys.getCurDiffTime(endTime)
	end
    local surplusTime=Utilitys.createTimeWithFormat(lastTime)
    local timeStr=_RALang("@VIPSurplusTime")..":"..tostring(surplusTime)
    if endTime==0 or lastTime<=0 then
    	timeStr=_RALang("@NoActived")
	end
    UIExtend.setCCLabelString(self.ccbfile, "mTimeLeftLabel",timeStr)

	if endTime==nil or endTime<RA_Common:getCurTime() then
		isActive=false
	else
		isActive=true	
	end

	if refreshGray~=nil and refreshGray then
		self:renderActiveStatus()
	else
		self:refereshVIPActiveStatus(isActive)
	end

end


--请求VIP数据，设置等待窗口
function RAVIPMainPage:LoadVIPData()
	RAVIPDataManager.initConfig()
	self:refreshSelfVIPPanel()
end

function RAVIPMainPage:refreshSelfVIPPanel()
	local playerData=RAVIPDataManager.getPlayerData()
	if playerData==nil then
		return
	end
	
	local level=playerData.vipLevel
	local vipPoints=playerData.vipPoints
	local freeVipPoint=playerData.freeVipPoint

	UIExtend.setCCLabelBMFontString(self.ccbfile, "mCurrentVip","VIP"..tostring(level))

	local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(level)
    if currVIPConfig~=nil then 
        if vipPoints==nil or tonumber(vipPoints)==0 then
            vipPoints=0
        end

        local percent=1.0
        if level >= RAVIPDataManager.getMaxVIPLevel() then
	        UIExtend.setCCLabelString(self.ccbfile, "mVIPExp",tostring(vipPoints))
        else
            local nextPoint=RAVIPDataManager.getVIPUpgradeNeedPointByLevel(level)
	        UIExtend.setCCLabelString(self.ccbfile, "mVIPExp",tostring(vipPoints).."/"..tostring(nextPoint))
            if tonumber(vipPoints)~=0 then
                if tonumber(vipPoints)<tonumber(nextPoint) then
                    percent=tonumber(vipPoints)/tonumber(nextPoint)
                end
            else
                percent=0
            end
        end
        
        local target = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mVIPPointBar")
        target:setScaleX(percent)
	    UIExtend.setCCLabelString(self.ccbfile, "mVIPPoint",tostring(_RALang("@VIPPoints",freeVipPoint)))
	end
	
    self:refereshEndTime(true)

	if currVIPConfig~=nil then
		local vipAttrConfig=RAVIPDataManager.getVIPAttrConfig()
		if 	vipAttrConfig~=nil then
			local i=1
			for k,v in pairs(vipAttrConfig) do
				if v~=nil then
					UIExtend.setCCLabelString(self.ccbfile, "mKeyNum"..tostring(i), tostring(v.columnValue))
					UIExtend.setCCLabelString(self.ccbfile, "mValueNum"..tostring(i),RAVIPDataManager.getVIPConfigValueSymbol(currVIPConfig,v))
					i=i+1
				end
			end
		end
	end

	self:showVIPDiff(level)
end

function RAVIPMainPage:showVIPDiff(diffLevel)
	local player=RAVIPDataManager.getPlayerData()
	if player==nil then
		return
	end
	
	local currLevel=player.vipLevel
	local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(currLevel)
	local diffVIPConfig=nil
	if currLevel<diffLevel then
		diffVIPConfig=RAVIPDataManager.getVIPConfigByLevel(diffLevel)
	end	
	
	local vipAttrConfig=RAVIPDataManager.getVIPAttrConfig()
		if 	vipAttrConfig~=nil then
			local i=1
			for k,v in pairs(vipAttrConfig) do
				if v~=nil then
					local diffValue=0
					if diffVIPConfig~=nil then
						diffValue=diffVIPConfig[v.columnName]-currVIPConfig[v.columnName]
					end	
					if diffValue>0 then
						UIExtend.setCCLabelString(self.ccbfile, "mNextValueNum"..tostring(i),RAVIPDataManager.getVIPConfigValueSymbol(diffVIPConfig,v))
					else
						UIExtend.setCCLabelString(self.ccbfile, "mNextValueNum"..tostring(i),"")		
					end
					i=i+1
				end
			end
		end
end


function RAVIPMainPage:renderVIPContent()
	self.scrollView:removeAllCell()
	local currVIPLevel=RAVIPDataManager.getPlayerData().vipLevel
	local needFocus = false--是否需要定位cell
    local focusCell = nil--需要定位在中间的cell
    local needOffsetToBelow = false--是否需要定位到最底端
    local canShowCellCount = 1--scrollview可以同时显示的完整的cell数量

	for i=1,RAVIPDataManager.getMaxVIPLevel() do
		local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(i)
		if currVIPConfig~=nil then
			local listener = RAContentCellListener:new({contentInfo = currVIPConfig, contentIndex= i})
			local cell = CCBFileCell:create()
			cell:setCCBFile("RAVIPCell.ccbi")
			cell:registerFunctionHandler(listener)
			self.scrollView:addCell(cell)

            if i == 1 then
                local cellHeight = cell:getContentSize().height
                local viewHeight = self.scrollView:getViewSize().height
                canShowCellCount = math.floor(viewHeight / cellHeight)
            end

            --偏移逻辑处理
            if currVIPConfig.level == currVIPLevel and currVIPLevel > canShowCellCount and currVIPLevel < (RAVIPDataManager.getMaxVIPLevel() - canShowCellCount + 1) then
                needFocus = true
                focusCell = cell
            elseif currVIPConfig.level == currVIPLevel and currVIPLevel >= (RAVIPDataManager.getMaxVIPLevel() - canShowCellCount + 1) then
                needOffsetToBelow = true
            end
		end
	end

	self.scrollView:orderCCBFileCells()
    if needFocus == true then
        if focusCell then
            focusCell:locateTo(CCBFileCell.LT_Mid)
        end
    elseif needOffsetToBelow == true then
        local offset = self.scrollView:getViewSize().height - self.scrollView:getContentSize().height
        self.scrollView:setContentOffset(ccp(0, 0))
    end
end

function RAVIPMainPage:refreshPanel()
	self:refreshSelfVIPPanel()
	self:renderVIPContent()
end


--打开道具使用页面
function RAVIPMainPage:onVIPBuyBtn()
	RAVIPDataManager.Object.currShowVIPLevel=RAVIPDataManager.getPlayerData().vipLevel
	RARootManager.OpenPage("RAVIPUseToolsPage",nil,true)
end


local OnReceiveMessage = function(message)
	if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then
        RAVIPMainPage:refreshPanel()
    end
end


function RAVIPMainPage:addHandler()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RAVIPMainPage:removeHander()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RAVIPMainPage:mCommonTitleCCB_onBack()
    RARootManager.ClosePage("RAVIPMainPage")
end

--退出页面
function RAVIPMainPage:Exit(data)
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAVIPMainPage")

	if self.scrollView then
		self.scrollView:removeAllCell()
		self.scrollView = nil
	end
	self:removeHander()
	UIExtend.unLoadCCBFile(RAVIPMainPage)
	self.ccbfile = nil
end