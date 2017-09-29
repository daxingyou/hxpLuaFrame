-- RACommonTitleHelper

local UIExtend = RARequire('UIExtend')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAActionManager = RARequire('RAActionManager')
local RALogicUtil = RARequire('RALogicUtil')
local Utilitys = RARequire('Utilitys')

local RACommonTitleHelper = {}

local OnReceiveMessage = nil

RACommonTitleHelper.TitleCallBack = {
    Back = "onBackCallBack",
    Gold = "onGetGoldBtnCallBack",
    Oil = "onGetOilBtnCallBack",
    Steel = "onGetSteelBtnCallBack",
    RareEarths = "onGetRareEarthsBtnCallBack",
    Diamonds = "onDiamondsCCBCallBack",
    Help = 'onCommonHelpBtn',
    Label = 'onCommonLabelBtn'
}
RACommonTitleHelper.BgType = {
    None = 0,
    Yellow = 1,
    Blue = 2,
}
RACommonTitleHelper.mTitleMap = {}


---------------title handler---------------

local RACommonTitle = 
{
    parentPage = "",
    
    new = function(self, o)
        o = o or {}
        o.callBackMap = {
            onBackCallBack = nil,
            onGetGoldBtnCallBack = nil,
            onGetOilBtnCallBack = nil,
            onGetSteelBtnCallBack = nil,
            onGetRareEarthsBtnCallBack = nil,
            onDiamondsCCBCallBack = nil,
            onCommonHelpBtn = nil,
            onCommonLabelBtn = nil,
        }
        o.lastData = {
            mLastGold = 0, -- 钻石
            mLastGoldore = 0,   -- 金矿
            mLastOil = 0,   -- 石油
            mLastSteel = 0,   -- 钢铁
            mLastTombarthite = 0,   -- 稀土
        }
        o.actionMap = {
            mDiamondsNum = nil, 
            mGoldNum = nil,   -- 金矿
            mOilNum = nil,   -- 石油
            mSteelNum = nil,   -- 钢铁
            mRareEarthsNum = nil,   -- 稀土    
        }
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    -- public functions
    -- 自己创建ccb时会调用
    Load = function(self, backCallBack)
        local ccbi = UIExtend.loadCCBFile(self:getCCBName(), self)
        self.mIsCreate = true
        self:SetCallBack(RACommonTitleHelper.TitleCallBack.Back, backCallBack)
        return ccbi
    end,

    SetCallBack = function(self, name, callBack)
        self.callBackMap[name] = callBack
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    SetCCBFile = function(self, titleCCB)
        self.ccbfile = titleCCB
    end,

    SetTitleName = function(self, name)        
        local label = UIExtend.getCCLabelTTFFromCCB(self:GetCCBFile(), "mTitle")
        if label ~= nil then
            label:setString(name)
        end
    end,

    SetTitleBgType = function(self, bgType, isTitleBg)
        if isTitleBg ~= false then
            local blueVisible = false
            local yellowVisible = false
            if bgType == RACommonTitleHelper.BgType.Blue then
                blueVisible = true
            end
            if bgType == RACommonTitleHelper.BgType.Yellow then
                yellowVisible = true
            end
--            UIExtend.setNodesVisible(self:GetCCBFile(),
--                {
--                    mTitleColorBlueNode = blueVisible,
--                    mTitleColorYellowNode = yellowVisible
--                })
        end
    end,

    SetFunctionCallBackType = function(self, cbType)
        UIExtend.setNodesVisible(self:GetCCBFile(), {
            mDiamondsNode       = cbType == RACommonTitleHelper.TitleCallBack.Diamonds,
            mCommonHelpBtnNode  = cbType == RACommonTitleHelper.TitleCallBack.Help,
            mLabelBtnNode       = cbType == RACommonTitleHelper.TitleCallBack.Label
        })
    end,

    SetNewFunctionCallBackType = function(self, cbType)
        UIExtend.setNodesVisible(self:GetCCBFile(), {
            mDiamondsNode       = cbType == RACommonTitleHelper.TitleCallBack.Diamonds,
            mMainHelpBtnNode    = cbType == RACommonTitleHelper.TitleCallBack.Help,
            mMenuBtnNode        = cbType == RACommonTitleHelper.TitleCallBack.Label
        })
    end,

    SetFunctionLabelTxt = function(self, txt)
        if self:GetCCBFile():hasVariable('mCommonLabel') then
            UIExtend.setCCLabelString(self:GetCCBFile(), 'mCommonLabel', txt or '')
        end
    end,

    Exit = function(self)
        self:resetData()
        if self.mIsCreate then
            UIExtend.unLoadCCBFile(self)
        else
            if not Utilitys.isNil(self:GetCCBFile()) then
                self:GetCCBFile():unregisterFunctionHandler()
            end
        end
    end,


    -- private functions 

    getCCBName = function(self)
        return "RAzzTopTitleRes.ccbi"
    end,

    resetData = function(self)
        CCLuaLog("RACommonTitle resetData")
        self.lastData = {
            mLastGold = 0, -- 钻石
            mLastGoldore = 0,   -- 金矿
            mLastOil = 0,   -- 石油
            mLastSteel = 0,   -- 钢铁
            mLastTombarthite = 0,   -- 稀土
        }

        local clearAction = function(name)
            local action = self.actionMap[name]
            if action ~= nil and action.ClearAction ~= nil then
                action:ClearAction()
            end
            self.actionMap[name] = nil
        end

        clearAction('mDiamondsNum')
        clearAction('mGoldNum')
        clearAction('mOilNum')
        clearAction('mSteelNum')
        clearAction('mRareEarthsNum')

        self.callBackMap = {
            onBackCallBack = nil,
            onGetGoldBtnCallBack = nil,
            onGetOilBtnCallBack = nil,
            onGetSteelBtnCallBack = nil,
            onGetRareEarthsBtnCallBack = nil,
            onDiamondsCCBCallBack = nil,
        }
    end,

    refreshTitle = function(self, isAni)
        if isAni == nil then
            isAni = true            
        end

        --资源按大本等级显示
        local Const_pb = RARequire("Const_pb")                
        --钢材
        if self:GetCCBFile():hasVariable('mSteelNode') then 
            UIExtend.setNodeVisible(self:GetCCBFile(), 'mSteelNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.STEEL))
        end
        --合金
        if self:GetCCBFile():hasVariable('mRareEarthsNode') then 
            UIExtend.setNodeVisible(self:GetCCBFile(), 'mRareEarthsNode', RAPlayerInfoManager.getSelfIsOpenResByType(Const_pb.TOMBARTHITE))
        end

        self:checkLabelAndUpdate("mDiamondsNum", self.lastData.mLastGold, RAPlayerInfoManager.getPlayerBasicInfo().gold, false, 0, isAni)
        self.lastData.mLastGold = RAPlayerInfoManager.getPlayerBasicInfo().gold

        self:checkLabelAndUpdate("mGoldNum", self.lastData.mLastGoldore, RAPlayerInfoManager.getPlayerBasicInfo().goldore, true, 1, isAni)
        self.lastData.mLastGoldore = RAPlayerInfoManager.getPlayerBasicInfo().goldore

        self:checkLabelAndUpdate("mOilNum", self.lastData.mLastOil, RAPlayerInfoManager.getPlayerBasicInfo().oil, true, 1, isAni) 
        self.lastData.mLastOil = RAPlayerInfoManager.getPlayerBasicInfo().oil

        self:checkLabelAndUpdate("mSteelNum", self.lastData.mLastSteel, RAPlayerInfoManager.getPlayerBasicInfo().steel, true, 1, isAni)    
        self.lastData.mLastSteel = RAPlayerInfoManager.getPlayerBasicInfo().steel

        self:checkLabelAndUpdate("mRareEarthsNum", self.lastData.mLastTombarthite, RAPlayerInfoManager.getPlayerBasicInfo().tombarthite, true, 1, isAni)    
        self.lastData.mLastTombarthite = RAPlayerInfoManager.getPlayerBasicInfo().tombarthite
    end,

    checkLabelAndUpdate = function(self, name, oldValue, newValue, is2K, dotCount, isAni)
        local ccbfile = self:GetCCBFile()
        if ccbfile == nil then return end
        if ccbfile:hasVariable(name) == false then return end 
        local label = UIExtend.getCCLabelTTFFromCCB(ccbfile, name)
        if label ~= nil then
            if oldValue ~= newValue and isAni then
                local action = self.actionMap[name]
                if action ~= nil and action.ClearAction ~= nil then
                    action:ClearAction()
                end
                action = RAActionManager:CreateNumLabelChangeAction(0.5, oldValue, newValue, is2K, dotCount)
                action:startWithTarget(label)
            else
                if is2K then
                    label:setString(RALogicUtil:num2k(newValue, dotCount))
                else
                    label:setString(RALogicUtil:numCutAfterDot(newValue, dotCount))
                end
            end
        end
    end,

    -- click call back handlers 
    onBack = function(self)
        CCLuaLog("RACommonTitle onBack")
        if self.callBackMap.onBackCallBack ~= nil then
            self.callBackMap.onBackCallBack()
        else
            -- 默认返回上个页面
            local RARootManager = RARequire('RARootManager')
            RARootManager.CloseCurrPage()
        end
    end,
    onGetGoldBtn = function(self)
        CCLuaLog("RACommonTitle onGetGoldBtn")
        if self.callBackMap.onGetGoldBtnCallBack ~= nil then
            self.callBackMap.onGetGoldBtnCallBack()
        end
    end,
    onGetOilBtn = function(self)
        CCLuaLog("RACommonTitle onGetOilBtn")
        if self.callBackMap.onGetOilBtnCallBack ~= nil then
            self.callBackMap.onGetOilBtnCallBack()
        end
    end,
    onGetSteelBtn = function(self)
        CCLuaLog("RACommonTitle onGetSteelBtn")
        if self.callBackMap.onGetSteelBtnCallBack ~= nil then
            self.callBackMap.onGetSteelBtnCallBack()
        end
    end,
    onGetRareEarthsBtn = function(self)
        CCLuaLog("RACommonTitle onGetRareEarthsBtn")
        if self.callBackMap.onGetRareEarthsBtnCallBack ~= nil then
            self.callBackMap.onGetRareEarthsBtnCallBack()
        end
    end,
    onDiamondsCCB = function(self)
        CCLuaLog("RACommonTitle onDiamondsCCB")
        if self.callBackMap.onDiamondsCCBCallBack ~= nil then
            self.callBackMap.onDiamondsCCBCallBack()
        else
                -- 默认打开
            if self.parentPage == "RARechargeMainPage" then return end
            local msg = Recharge_pb.FetchRechargeInfo()
            local RANetUtil = RARequire("RANetUtil")
            RANetUtil:sendPacket(HP_pb.FETCH_RECHARGE_INFO, msg)
        end
    end,
    onCommonHelpBtn = function(self)
        if self.callBackMap.onCommonHelpBtn ~= nil then
            self.callBackMap.onCommonHelpBtn()
        end
    end,
    onCommonLabelBtn = function(self)
        if self.callBackMap.onCommonLabelBtn ~= nil then
            self.callBackMap.onCommonLabelBtn()
        end
    end
}


-- helper functions


-- init title ccbfile by code;  
-- useless!!!
function RACommonTitleHelper:AddCommonTitle(pageName, node, titleName, backCallBack, titleType)
    if Utilitys.table_count(self.mTitleMap) == 0 then
        self:registerMessageHandlers()
    end
    if self.mTitleMap[pageName] ~= nil then
        self.mTitleMap[pageName]:Exit()
        self.mTitleMap[pageName] = nil
    end
    local titleName = titleName or ""
    local titleType = titleType or RACommonTitleHelper.BgType.None
    if pageName ~= nil and node ~= nil then        
        local title = RACommonTitle:new({mIsCreate = true})
        title:Load(backCallBack)
        title.parentPage = pageName
        node:addChild(title:GetCCBFile())
        title:SetTitleName(titleName)
        title:SetTitleBgType(titleType)
        title:refreshTitle(false)

        self.mTitleMap[pageName] = title
        return title
    end
    return nil
end

-- title ccbfile has inited in ccb file
function RACommonTitleHelper:RegisterCommonTitle(pageName, titleCCBFile, titleName, backCallBack, titleType, isTitleBg)
    if Utilitys.table_count(self.mTitleMap) == 0 then
        self:registerMessageHandlers()
    end
    if self.mTitleMap[pageName] ~= nil then
        self.mTitleMap[pageName]:Exit()
        self.mTitleMap[pageName] = nil
    end
    local titleName = titleName or ""
    local titleType = titleType or RACommonTitleHelper.BgType.None
    if pageName ~= nil and titleCCBFile ~= nil then        
        local title = RACommonTitle:new()
        title.parentPage = pageName
        titleCCBFile:setParentCCBFileNode(nil)
        titleCCBFile:registerFunctionHandler(title)
        title:SetCCBFile(titleCCBFile)
        title:SetCallBack(RACommonTitleHelper.TitleCallBack.Back, backCallBack)
        title:SetTitleName(titleName)
        title:SetTitleBgType(titleType,isTitleBg)
        title:refreshTitle(false)

        self.mTitleMap[pageName] = title
        return title
    end
    return nil
end


function RACommonTitleHelper:RemoveCommonTitle(pageName)
    if self.mTitleMap[pageName] ~= nil then
        self.mTitleMap[pageName]:Exit()
        self.mTitleMap[pageName] = nil
    end
    if Utilitys.table_count(self.mTitleMap) == 0 then
        self:unregisterMessageHandlers()
    end
end


OnReceiveMessage = function(message)
    CCLuaLog("RACommonTitleHelper OnReceiveMessage id:"..message.messageID)

    -- open RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_UpdateBasicPlayerInfo then        
        for name,title in pairs(RACommonTitleHelper.mTitleMap) do
        	local needRemove = true
        	if title ~= nil then
        		local isNil = Utilitys.isNil(title:GetCCBFile())
        		if not isNil and title.refreshTitle ~= nil then
	                title:refreshTitle(true)
	                needRemove = false
	            end
	    		assert(not isNil, 'Assert: Plz Remove CommonTitle for page "' .. name .. '" when Exit')
            end

            if needRemove then
                RACommonTitleHelper:RemoveCommonTitle(name)
            end
        end
    end
end

function RACommonTitleHelper:registerMessageHandlers()
    CCLuaLog("RACommonTitleHelper registerMessageHandlers")
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RACommonTitleHelper:unregisterMessageHandlers()
     CCLuaLog("RACommonTitleHelper unregisterMessageHandlers")
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end



return RACommonTitleHelper
