--账号绑定
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAGameConfig = RARequire("RAGameConfig")
local RASDKInitManager = RARequire("RASDKInitManager")
local RASettingAccountBindInfo = RARequire("RASettingAccountBindInfo")
local RASettingAccountBindUtil = RARequire("RASettingAccountBindUtil")

local RASettingAccountBindPage = BaseFunctionPage:new(...)

local isRefreshData = false

---------------------------------RASettingAccountBindCell------------------------

local RASettingAccountBindCell = {}

function RASettingAccountBindCell:new(o)
	-- body
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

function RASettingAccountBindCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellUnBindBtn'):setVisible(false)
    UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellBindBtn'):setVisible(false)

    if self.mType == 1 then  --绑定
    	local isBind = RASettingAccountBindUtil:getPlatformIsBindById(RASettingAccountBindPage.bindAccountInfo, self.mPlatformId)
    	if isBind then
    		--RALogRelease("RASettingAccountBindCell:onRefreshContent is isBind true to : "..self.mPlatformId)
    		UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellUnBindBtn'):setVisible(true)
    		UIExtend.setControlButtonTitle(ccbfile, 'mCellUnBindBtn', '@UnBind_'..self.mPlatformId)
    	else
    		--RALogRelease("RASettingAccountBindCell:onRefreshContent is isBind false to : "..self.mPlatformId)
    		UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellBindBtn'):setVisible(true)	
    		UIExtend.setControlButtonTitle(ccbfile, 'mCellBindBtn', '@Bind_'..self.mPlatformId)
    	end
    elseif self.mType == 2 then 	--切换绑定
    	UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellBindBtn'):setVisible(true)
    	UIExtend.setControlButtonTitle(ccbfile, 'mCellBindBtn', '@SwitchBind_'..self.mPlatformId)
    else
    	UIExtend.getCCControlButtonFromCCB(ccbfile,'mCellBindBtn'):setVisible(true)
    	UIExtend.setControlButtonTitle(ccbfile, 'mCellBindBtn', '@getBindList')	
    end
end

--绑定回调
function RASettingAccountBindCell:onCellBindBtn()
	-- body

    local delayFunc = function ()
        local platformId = tonumber(self.mPlatformId)

        if self.mType == 1 then  --绑定
            isRefreshData = false
            --根据平台id判断需要绑定的平台 发送给SDK
            local bindUrl,_ = RASettingAccountBindUtil:getPlatformUrlById(platformId)
            RASDKInitManager.bindAccount(bindUrl)
        elseif self.mType == 2 then     --切换绑定
            --切换账号，先不清理数据，切换成功后在清数据
            local _, switchUrl = RASettingAccountBindUtil:getPlatformUrlById(platformId)
            RASDKInitManager.bindAccount(switchUrl)
        else
            --获取账号是否绑定
            local url = RAGameConfig.BINDACCOUNT_TYPE.getBindlist
            RASDKInitManager.bindAccount(url)    
        end
    end
    performWithDelay(RASettingAccountBindPage.ccbfile, delayFunc, 0.05)
end

--解除绑定
function RASettingAccountBindCell:onCellUnBindBtn()
	-- body
    local delayFunc = function ()
        local platformId = tonumber(self.mPlatformId)

        isRefreshData = false
        --解除绑定
        local url = RAGameConfig.BINDACCOUNT_TYPE.unBind
        local key = 'platformType'
        local value = RAGameConfig.BINDACCOUNT_PLATFORM[platformId]
        RASDKInitManager.bindAccount(url, key, value)
    end
    performWithDelay(RASettingAccountBindPage.ccbfile, delayFunc, 0.05)
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

local OnReceiveMessage = function(msg)
    if msg.messageID == MessageDef_BINDACCOUNT.MSG_Bind_Data_Refresh then

    	RASettingAccountBindPage:refreshBindAccountData( msg.data )

    	if not isRefreshData then
    		isRefreshData = true
    		RASettingAccountBindPage:addBindPlatformCell(1)
    	end
    end
end
function RASettingAccountBindPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_BINDACCOUNT.MSG_Bind_Data_Refresh, OnReceiveMessage)
end

function RASettingAccountBindPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_BINDACCOUNT.MSG_Bind_Data_Refresh, OnReceiveMessage)
end

function RASettingAccountBindPage:Enter( data )
	-- body
	UIExtend.loadCCBFile("RASettingAccountBindPage.ccbi",self)

	--scrollView
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mPlatformListSV")

	self:registerMessageHandlers()
    self:initTitle()

    self.result = false
    self.resultData = nil
    self.resultCode = 0

    self.isMainShow = false

    --获取账号是否绑定
    local url = RAGameConfig.BINDACCOUNT_TYPE.getBindlist
    RASDKInitManager.bindAccount(url)

	self:refreshUI()
end

function RASettingAccountBindPage:isMainNode( isMain )
	-- body
	self.isMainShow = isMain
	UIExtend.setNodeVisible(self.ccbfile, 'mMainListNode', isMain)
	UIExtend.setNodeVisible(self.ccbfile, 'mSVListNode', not isMain)

	self.scrollView:setVisible(not isMain)
end

function RASettingAccountBindPage:refreshPlayerInfo()
	-- body
	local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local icon = RAPlayerInfoManager.getHeadIcon()
    local mIconNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(mIconNode,icon, 999)
    
    local playerName = RAPlayerInfoManager:getPlayerName()

    local servierId = RAPlayerInfoManager.getKingdomId()

    local RABuildManager = RARequire("RABuildManager")
    local mainCityLvl = RABuildManager:getMainCityLvl()

    local label = {}
    label['mName'] = playerName..' (s'..servierId..')'
    label['mBuildLevel'] = _RALang('@HeadquartersLowerLimit')..': '..mainCityLvl

    UIExtend.setStringForLabel(self.ccbfile, label)
end

function RASettingAccountBindPage:refreshUI()
	-- body
	self:refreshPlayerInfo()

	self:isMainNode(true)
end

--------------------------------------------------------------------
--获取玩家屈服列表
function RASettingAccountBindPage:refreshBindAccountData( resutJson )
	-- body
	-- resultData(json), result(bool) ,resultCode(int)
	RALogRelease("RASettingAccountBindPage:refreshBindAccountData is resutJson :"..resutJson)
	if resutJson ~= nil then
  		self.bindAccountInfo = RASettingAccountBindInfo.new()
  		self.bindAccountInfo:initByJson(resutJson)

  		local youaiId = self.bindAccountInfo.youaiId or ""

  		local userString = ""
  		for i,user in ipairs(self.bindAccountInfo.users or {}) do
  			if user.youaiId then
				userString = ","..userString..""..i.." youaiId :"..user.youaiId or ""
			end
			if user.thirdId then	
				userString = ","..userString..""..i.." thirdId :"..user.thirdId or ""
			end
			if user.thirdUserName then		
				userString = ","..userString..""..i.." thirdUserName :"..user.thirdUserName or ""
			end
			if user.thirdPlatform then		
				userString = ","..userString..""..i.." thirdPlatform :"..user.thirdPlatform or ""
			end
			if user.userType then		
				userString = ","..userString..""..i.." userType :"..user.userType or ""
			end
			if user.name then	
				userString = ","..userString..""..i.." name :"..user.name or ""
			end
  		end

        local result = self.bindAccountInfo.result
        local resultCode = self.bindAccountInfo.resultCode
        local hasBinds = self.bindAccountInfo.hasBinds

        local hasBindsStr = '0'
        if hasBinds then
        	hasBindsStr = '1'
        end

        local resultStr = '0'
        if result then
        	resultStr = '1'
        end

        local str = 'youaiId :'.. youaiId .. ',hasBinds :'.. hasBindsStr.." ,resultStr : "..resultStr .. " ,resultCode : "..resultCode..userString

    	local confirmData =
        {
            labelText = str,
            --yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    --RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(self.statueInfo.statueId, true)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)

	end
end
  
--添加可绑定平台的入口
function RASettingAccountBindPage:addBindPlatformCell(isBindType)
	-- body
	local scrollView = self.scrollView
	scrollView:removeAllCell()

	local type = 1 --默认为绑定类型页面
	if not isBindType then 
		type = 2  -- 为 切换类型页面
	end

	local bind_platform_conf = RARequire("bind_platform_conf")
	local bindPlatforId = bind_platform_conf['cn_appstore'].bind_platform_id
	local Utilitys = RARequire("Utilitys")
	local bindPlatforIds = Utilitys.Split(bindPlatforId, ",")
    for i = 1,#bindPlatforIds do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RASettingAccountBindCell.ccbi")
        local panel = RASettingAccountBindCell:new({
        	mType = type,
            mPlatformId = bindPlatforIds[i]
        })
        cell:registerFunctionHandler(panel)
        
        scrollView:addCell(cell)
    end

    scrollView:orderCCBFileCells()

	if scrollView:getContentSize().height < scrollView:getViewSize().height then
		scrollView:setTouchEnabled(false)
	else
		scrollView:setTouchEnabled(true)
	end
end

--绑定账号按钮
function RASettingAccountBindPage:onBindBtn()
	-- body

	self:isMainNode(false)

	--表示这个时候有没有数据了,如果没有则受到数据后还需要重新刷一遍
	if self.bindAccountInfo then
		isRefreshData = true
	end

    --添加需要绑定平台的cell params is true bind account
    self:addBindPlatformCell(true)
end

--切换账号
function RASettingAccountBindPage:onChangeBtn()
	-- body
	--todo 
	
	self:isMainNode(false)

    --添加需要绑定平台的cell params is false change account
    self:addBindPlatformCell(false)
end

--确认开始一个游客账号重新游戏
function RASettingAccountBindPage:ConfirmStartNewGame()
    -- body
    --step.1 disconnect server
    local RALoginManager = RARequire("RALoginManager")
    RALoginManager:disconnectServer()
    --step.2 clear user default
    local RASettingManager = RARequire("RASettingManager")
    RASettingManager:clearUserDefault()
    --step.3 call switch user sdk api
    local RAGameLoadingState = RARequire("RAGameLoadingState")
    --step.4 go to the loading state
    RAGameLoadingState.isBeginNewGame = true
    GameStateMachine.ChangeState(RAGameLoadingState)
end

--开始新游戏按钮
function RASettingAccountBindPage:onBeginNewGame()
	-- body
    local isBind = false
    if self.bindAccountInfo then
        isBind = self.bindAccountInfo.hasBinds or false  
    end

    if isBind then
        self:ConfirmStartNewGame()
    else
        local confirmData =
        {
            labelText = "@NoBindAccountWarning",
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    self:ConfirmStartNewGame()
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)  
    end    
end

function RASettingAccountBindPage:initTitle()
	-- body
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		if self.isMainShow == false then
			RASettingAccountBindPage:isMainNode( true )
		else
			RARootManager.GotoLastPage()	
		end
	end
    local titleName = _RALang("@SettingAccountBind")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingMessagePushPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingAccountBindPage:Exit()
	-- body
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingMessagePushPage")

	self:unregisterMessageHandlers()

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RASettingAccountBindPage