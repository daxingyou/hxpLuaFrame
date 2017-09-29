--TO:联盟战争页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAPresidentDataManager = RARequire("RAPresidentDataManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local President_pb = RARequire('President_pb')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local RANetUtil = RARequire('RANetUtil')

local PalaceTabBtnType = 
{
    Attr = 1,
    BattleRecord = 2,
    PresidentRecord = 3
}

local RAPresidentPalacePage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    -- 刷新国王属性页签
    if message.messageID == MessageDef_World.MSG_PresidentInfo_Update then        
        RAPresidentPalacePage:CheckAndUpdatePage(PalaceTabBtnType.Attr)
    end

    if message.messageID == MessageDef_World.MSG_PresidentEvents_Update then        
        RAPresidentPalacePage:CheckAndUpdatePage(PalaceTabBtnType.BattleRecord)
    end

    if message.messageID == MessageDef_World.MSG_PresidentHistory_Update then        
        RAPresidentPalacePage:CheckAndUpdatePage(PalaceTabBtnType.PresidentRecord)
    end
end

function RAPresidentPalacePage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)
end

function RAPresidentPalacePage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)    
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)  
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)  
end

function RAPresidentPalacePage:Enter()	
	local ccbfile = UIExtend.loadCCBFile("RAPresidentPalacePage.ccbi",self)
    -- title
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end
    local titleName = _RALang("@PresidentPalacePageTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAPresidentPalacePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)

    --两个scroll view
    self.mEeventsSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mRecordListSV")
    self.mHistorySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSuccessiveListSV")

    

    --初始化标签页三个按钮
    self.tabArr = {} --三个分页签
    self.tabArr[PalaceTabBtnType.Attr] = 
    {
        btn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mAttributionDetailsBtn'),
        node = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mAttributionDetailsNode'),        
    }
    self.tabArr[PalaceTabBtnType.BattleRecord] = 
    {
        btn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mRecordBtn'),
        node = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mRecordNode'),        
    }
    self.tabArr[PalaceTabBtnType.PresidentRecord] = 
    {
        btn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mSuccessivePresidentsBtn'),
        node = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mSuccessivePresidentsNode'),        
    }

    -- 刷新国王加成显示（不会发生改变）
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local RAStringUtil = RARequire('RAStringUtil')
    local addStr, strTable = RAWorldConfigManager:GetOfficialWelfareStr(President_pb.OFFICER_01)
    for i,v in ipairs(strTable) do        
        local htmlStr = RAStringUtil:getHTMLString('OfficialBuff', v)
        local htmlNodeName = 'mPresidentAdditional'..i
        UIExtend.setCCLabelHTMLString(ccbfile, htmlNodeName, htmlStr)
    end

    -- 刷新两个scrollView没内容的时候的提示
    UIExtend.setStringForLabel(ccbfile, {
        mRecordExplain = _RALang('@NoBattleEventTips'),
        mSuccessiveExplain = _RALang('@NoPresidentsHistoryTips'),
        })

    self:RefreshCommonUIPart()
    self:onAttributionDetailsBtn()

    self:registerMessageHandlers()
    -- self:RegisterPacketHandler(HP_pb.WORLD_MASS_DISSOLVE_S)
    -- self:RegisterPacketHandler(HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_S)
    self.mLastUpdateTime = 0
end


function RAPresidentPalacePage:Execute()
    local currTime = CCTime:getCurrentTime()
    if currTime - self.mLastUpdateTime < 300 then
        return
    end
    self.mLastUpdateTime = currTime
    self:RefreshCommonUIPart()
end


function RAPresidentPalacePage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAPresidentPalacePage")
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    -- self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end


function RAPresidentPalacePage:onAttributionDetailsBtn()
	self:setCurrentPage(PalaceTabBtnType.Attr)
end

function RAPresidentPalacePage:onRecordBtn()
	self:setCurrentPage(PalaceTabBtnType.BattleRecord)
end

function RAPresidentPalacePage:onSuccessivePresidentsBtn()
	self:setCurrentPage(PalaceTabBtnType.PresidentRecord)
end

function RAPresidentPalacePage:onAttributionBtn()
    RARootManager.OpenPage('RAPresidentMainPage')
end

function RAPresidentPalacePage:onReceivePacket(handler)
    -- local opcode = handler:getOpcode()
    -- local buffer = handler:getBuffer()    
    -- -- 国王战事件
    -- if opcode == HP_pb.WORLD_MASS_DISSOLVE_S then
    --     local msg = World_pb.WorldMassDissolveResp()
    --     msg:ParseFromString(buffer)
    --     local result = msg.result
    --     if result then
    --          RARootManager.ClosePage('RANewAllianceWarDetailsPage')
    --     end
    --     RARootManager.RemoveWaitingPage()
    --     return
    -- end
end

function RAPresidentPalacePage:CheckAndUpdatePage(showType)
    self:RefreshCommonUIPart()
    self:RefreshUIByType(showType)
    -- if self.curPageType == showType then
    --     self:setCurrentPage(showType)
    -- end
end


--设置当前Page
function RAPresidentPalacePage:setCurrentPage(pageType)
    self:sendPorotolRequestByType(pageType)
	self.curPageType = pageType
    self:RefreshUIByType(pageType)

    for k,v in pairs(self.tabArr) do
        if v.btn ~= nil then
            v.btn:setEnabled(pageType ~= k)     
        end
        if v.node ~= nil then
            v.node:setVisible(pageType == k)
        end
    end     
end


function RAPresidentPalacePage:RefreshCommonUIPart()
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    -- Common part
    local isPeace, periodEndTime, periodTotalTime = RAPresidentDataManager:GetPresidentStatus()
    local statusStrKey = '@PresidentPeaceStatus'
    if not isPeace then
        statusStrKey = '@PresidentWarStatus'
    end
    local lastTime = periodEndTime - common:getCurMilliTime()
    if lastTime < 0 then lastTime = 0 end
    local timeStr = Utilitys.createTimeWithFormat(lastTime / 1000) 

    UIExtend.setStringForLabel(ccbfile, {
        mBarStateLabel = _RALang(statusStrKey),
        mBarTime = timeStr,
        })

    local percent = lastTime / periodTotalTime
    UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mBar', 'mBarSizeNode', 1 - percent)
end


function RAPresidentPalacePage:RefreshUIByType(showType)
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end

    local RAPresidentPalaceCellHelper = RARequire('RAPresidentPalaceCellHelper')
    -- 归属详情
    if showType == PalaceTabBtnType.Attr then
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        local presidentInfo = RAPresidentDataManager:GetPresidentInfo()
        UIExtend.removeSpriteFromNodeParent(ccbfile, 'mCellIconNode')
        UIExtend.removeSpriteFromNodeParent(ccbfile, 'mAllianceSmallIconNode')
        local playerName = _RALang('@NoPresidentDes')
        local durationTimeStr = _RALang('@NoPresidentDes')
        local guildName = _RALang('@NoPresidentDes')
        -- 刷新国王显示
        if presidentInfo.playerId ~= nil then
            playerName = presidentInfo.playerName
            local presidentBeginTime = presidentInfo.tenureTime
            local lastTime = common:getCurMilliTime() - presidentBeginTime
            durationTimeStr = Utilitys.createTimeWithFormat(lastTime / 1000) 
            guildName = _RALang('@GuildTagWithName', presidentInfo.guildTag, presidentInfo.guildName)

            local iconStr = RAPlayerInfoManager.getHeadIcon(presidentInfo.playerIcon)
            UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', iconStr)

            local RAAllianceUtility = RARequire('RAAllianceUtility')
            local guildIconStr = RAAllianceUtility:getAllianceFlagIdByIcon(presidentInfo.guildFlag)
            UIExtend.addSpriteToNodeParent(ccbfile, 'mAllianceSmallIconNode', guildIconStr)
        end
        local isSelfPresident = RAPlayerInfoManager.IsPresident()
        UIExtend.setNodeVisible(ccbfile, 'mAttributionBtn', true)
        UIExtend.setControlButtonTitle(ccbfile, 'mAttributionBtn', '@OfficialPosition')
        
        UIExtend.setStringForLabel(ccbfile, {
            mPresidentName = playerName,
            mReElectionTime = durationTimeStr,
            mAllianceName = guildName,
        })
        return
    end

    -- 记录
    if showType == PalaceTabBtnType.BattleRecord then
        local scrollView = self.mEeventsSV
        if scrollView then
            local datas = RAPresidentDataManager:GetEventsHistory()            
            scrollView:removeAllCell()
            local count = Utilitys.table_count(datas)
            local index = 1
            for i=1, #datas do
                local v = datas[i]
                local oneCellHandler = RAPresidentPalaceCellHelper:CreateEventHistoryCell(index, v)            
                local cell = CCBFileCell:create()
                cell:setCCBFile(oneCellHandler:GetCCBName())
                cell:registerFunctionHandler(oneCellHandler)                
                scrollView:addCell(cell)
                index = index + 1
            end
            local isTipsVisual = (count <= 0)
            UIExtend.setNodesVisible(ccbfile, {mRecordExplain = isTipsVisual})
            scrollView:orderCCBFileCells()
        end
        return
    end

    -- 历代国王
    if showType == PalaceTabBtnType.PresidentRecord then
        local scrollView = self.mHistorySV
        if scrollView then
            local datas = RAPresidentDataManager:GetPresidentsHistory()
            scrollView:removeAllCell()
            local count = Utilitys.table_count(datas)
            local index = 1
            for i=1,#datas do
                local v = datas[i]
                local oneCellHandler = RAPresidentPalaceCellHelper:CreatePresidentHistoryCell(index, v)            
                local cell = CCBFileCell:create()
                cell:setCCBFile(oneCellHandler:GetCCBName())
                cell:registerFunctionHandler(oneCellHandler)                
                scrollView:addCell(cell)
                index = index + 1
            end
            local isTipsVisual = (count <= 0)
            UIExtend.setNodesVisible(ccbfile, {mSuccessiveExplain = isTipsVisual})
            scrollView:orderCCBFileCells()
        end
        return
    end
end



-- 请求国王战数据
function RAPresidentPalacePage:sendPorotolRequestByType(showType)
    local SysProtocol_pb = RARequire('SysProtocol_pb')
    if showType == PalaceTabBtnType.BattleRecord then
        local msg = SysProtocol_pb.EmptyProtocol()
        RANetUtil:sendPacket(HP_pb.FETCH_PRESIDENT_EVENT_C, msg)
    end
    if showType == PalaceTabBtnType.PresidentRecord then
        local msg = SysProtocol_pb.EmptyProtocol()
        RANetUtil:sendPacket(HP_pb.FETCH_PRESIDENT_HISTORY_C, msg)
    end
end


return RAPresidentPalacePage