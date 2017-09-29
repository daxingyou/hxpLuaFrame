--TO:联盟战争 集结加入页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAPresidentMarchDataHelper = RARequire("RAPresidentMarchDataHelper")
local RAPresidentDataManager = RARequire('RAPresidentDataManager')
local RAGameConfig = RARequire("RAGameConfig")
local Const_pb = RARequire("Const_pb")
local HP_pb = RARequire('HP_pb')
local World_pb = RARequire("World_pb")

local RAPresidentQuarterPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_World.MSG_PresidentQuarterPage_Refresh then
        RAPresidentQuarterPage:CommonRefresh(false)
    -- 部队详情开启和关闭
    elseif message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change then
        local showData = message.showData
        RAPresidentQuarterPage:ChangeCellInfoStatus(showData)
    -- 临时国王切换
    elseif message.messageID == MessageDef_World.MSG_TmpPresident_Change then
        RARootManager.ClosePage('RAPresidentQuarterPage')
    -- 切换显示某个空闲cell的按钮状态
    elseif message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change then
        RAPresidentQuarterPage:ChangeCellAddStatus()

    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        local opcode = message.opcode          
        if opcode == HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_C then
            RARootManager.RemoveWaitingPage()            
        end
        if opcode == HP_pb.WORLD_MASS_DISSOLVE_C then
            RARootManager.RemoveWaitingPage()            
        end
    end
end

function RAPresidentQuarterPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_Refresh, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_TmpPresident_Change, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change, OnReceiveMessage)
    
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAPresidentQuarterPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_Refresh, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_TmpPresident_Change, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change, OnReceiveMessage)    

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAPresidentQuarterPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAPresidentGatherPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mTroopsListSV")

    -- --TOP
    -- self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    -- self.mDiamondsNode:setVisible(false)
    -- self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    -- local titleName = _RALang("@AllianceWarWarGatherTitle")
    -- UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)


    -- title
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end
    local titleName = _RALang("@PresidentQuarterPageTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAPresidentQuarterPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)

    self.mTeamData = RAPresidentMarchDataHelper:GetCurrTeamData()
    self.mOpenItemMap = {}
    self.mSpareCellMap = {}
    self:CommonRefresh(true)
    --刷新页面
    

    self:registerMessageHandlers()
    -- self:RegisterPacketHandler(HP_pb.WORLD_MASS_DISSOLVE_S)
    -- self:RegisterPacketHandler(HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_S)

    self.mLastUpdateTime = 0
end



function RAPresidentQuarterPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()    
    -- -- 解散集结
    -- if opcode == HP_pb.WORLD_MASS_DISSOLVE_S then
    --     local msg = World_pb.WorldMassDissolveResp()
    --     msg:ParseFromString(buffer)
    --     local result = msg.result
    --     if result then
    --          RARootManager.ClosePage('RAPresidentQuarterPage')
    --     end
    --     RARootManager.RemoveWaitingPage()
    --     return
    -- end
    -- -- 购买一个新队列的返回
    -- if opcode == HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_S then
    --     local msg = World_pb.WorldMassMarchBuyExtraItemsResp()
    --     msg:ParseFromString(buffer)
    --     local result = msg.result
        
    --     return
    -- end
end

function RAPresidentQuarterPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAPresidentQuarterPage")
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end
function RAPresidentQuarterPage:Execute()
    local currTime = CCTime:getCurrentTime()
    if currTime - self.mLastUpdateTime < 300 then
        return
    end
    self.mLastUpdateTime = currTime
    self:RefreshCommonUIPart()
end

function RAPresidentQuarterPage:CommonRefresh(isReset)
    isReset = isReset or false
    self.mTeamData = RAPresidentMarchDataHelper:GetCurrTeamData()
    if self.mTeamData == nil then return end
    self:_BuildItemCellInfoOpenData(isReset)
    self:RefreshCommonUIPart()
    self:refreshScrollView()
end


function RAPresidentQuarterPage:_BuildItemCellInfoOpenData(isReset)
    if self.mTeamData == nil then return end
    if isReset then
        self.mOpenItemMap = {}    
    end
    local leaderShowData = self.mTeamData.leaderMarch
    if self.mOpenItemMap[leaderShowData.playerId] == nil then 
        self.mOpenItemMap[leaderShowData.playerId] = false    
    end
    local joinMarches = self.mTeamData.joinMarchs    
    for k,v in pairs(joinMarches) do
        if self.mOpenItemMap[v.playerId] == nil then
            self.mOpenItemMap[v.playerId] = false
        end
    end
end


function RAPresidentQuarterPage:RefreshCommonUIPart()
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    -- Common part
    local isPeace, periodEndTime, periodTotalTime = RAPresidentDataManager:GetPresidentStatus()
    local statusStrKey = '@PresidentPeaceStatusWithParam'
    if not isPeace then
        statusStrKey = '@PresidentWarStatusWithParam'
    end
    local lastTime = periodEndTime - common:getCurMilliTime()
    if lastTime < 0 then lastTime = 0 end
    local timeStr = Utilitys.createTimeWithFormat(lastTime / 1000) 
    timeStr = _RALang(statusStrKey, timeStr)
    UIExtend.setStringForLabel(ccbfile, {        
        mBarTime = timeStr,
        })

    local percent = lastTime / periodTotalTime
    UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mBar', 'mBarSizeNode', 1 - percent)

    --刷新数目
    local selfInfo = RAPresidentMarchDataHelper:GetCurrTeamData()
    local currCount = selfInfo:GetJoinedArmyCount()
    local limitCount = selfInfo.leaderArmyLimit
    local keyStr = '@QuarterArmyCountWith2Param'
    UIExtend.setStringForLabel(ccbfile, {mDefenseTroopsNum = _RALang(keyStr,currCount ,limitCount)})
end



function RAPresidentQuarterPage:ChangeCellInfoStatus(showData)
    local oldStatus = self.mOpenItemMap[showData.playerId]
    self.mOpenItemMap[showData.playerId] = not oldStatus
    self:refreshScrollView()
end

function RAPresidentQuarterPage:ChangeCellAddStatus(cellIndex)
    if self.mSpareCellMap == nil then
        return
    end
    for i,v in ipairs(self.mSpareCellMap) do
        local index = v.mIndex
        v:UpdateSpareCellStatus(false)
    end
end


-- 点击空白位置，关闭cell上的弹出
function RAPresidentQuarterPage:onClose()
    self:ChangeCellAddStatus()
end


function RAPresidentQuarterPage:refreshScrollView()
    local RAPresidentQuarterCellHelper = RARequire('RAPresidentQuarterCellHelper')
    local isSelfGuild = RAPresidentMarchDataHelper:CheckIsSelfGuild()
    local selfInfo = RAPresidentMarchDataHelper:GetCurrTeamData()
    local openItemMap = self.mOpenItemMap        
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView

    local checkAndCreateCellInfo = function(showData)
        local status = openItemMap[showData.playerId] or false
        local cell = nil
        local cellHandler = nil
        if status then
            cellHandler = RAPresidentQuarterCellHelper:CreateArmyInfoCell(
                index, showData)
            cell = CCBFileCell:create()            
            cell:registerFunctionHandler(cellHandler)
            cell:setIsScheduleUpdate(true)
            cell:setCCBFile(cellHandler:GetCCBName())
            scrollView:addCellBack(cell)
        end
        return status, cell
    end
    if isSelfGuild and selfInfo ~= nil then
        --先创建队长
        local cellIndex = 1    
        local itemCount = 0
        if selfInfo.leaderMarch.playerId ~= '' and selfInfo.leaderMarch.marchData ~= nil then
            local status = openItemMap[selfInfo.leaderMarch.playerId] or false
            local leaderCellHandler = RAPresidentQuarterCellHelper:CreateJoinedCell(
                cellIndex, selfInfo.leaderMarch, status)
            local leaderCell = CCBFileCell:create()            
            leaderCell:registerFunctionHandler(leaderCellHandler)
            leaderCell:setIsScheduleUpdate(true)
            leaderCell:setCCBFile(leaderCellHandler:GetCCBName())
            scrollView:addCellBack(leaderCell)            
            itemCount = itemCount + 1
            local leaderCellInfoStatus, leaderCellInfoCell = checkAndCreateCellInfo(selfInfo.leaderMarch)
            if leaderCellInfoStatus then cellIndex = cellIndex + 1 end
        end

        --创建队员
        local joinMarches = selfInfo.joinMarchs
        local sortedMarchIdList = selfInfo:GetSortedJoinedMarhIdList()
        for i=1, #sortedMarchIdList do                
            local oneIdData = sortedMarchIdList[i]
            local v = joinMarches[oneIdData.marchId]
            if v ~= nil then
                cellIndex = cellIndex + 1
                local status = openItemMap[v.playerId] or false
                local itemCellHandler = RAPresidentQuarterCellHelper:CreateJoinedCell(
                    cellIndex, v, status)
                local itemCell = CCBFileCell:create()            
                itemCell:registerFunctionHandler(itemCellHandler)
                itemCell:setIsScheduleUpdate(true)
                itemCell:setCCBFile(itemCellHandler:GetCCBName())
                scrollView:addCellBack(itemCell)

                itemCount = itemCount + 1

                local itemCellInfoStatus, itemCellInfoCell = checkAndCreateCellInfo(v)
                if itemCellInfoStatus then cellIndex = cellIndex + 1 end
            end
        end

        self.mSpareCellMap = {}
        --创建剩余的空闲位置
        local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
        local baseMassNum = RANewAllianceWarManager:GetPlayerBaseMassItemCount()
        local spareNum = baseMassNum - itemCount + selfInfo.buyItemTimes
        if spareNum > 0 then                
            for i=1,spareNum do
                cellIndex = cellIndex + 1
                local spareCellHandler = RAPresidentQuarterCellHelper:CreateSpareCell(
                    cellIndex, false, selfInfo.buyItemTimes)
                local spareCell = CCBFileCell:create()            
                spareCell:registerFunctionHandler(spareCellHandler)
                spareCell:setCCBFile(spareCellHandler:GetCCBName())
                scrollView:addCellBack(spareCell)
                table.insert(self.mSpareCellMap, spareCellHandler)
            end
        end

        --创建购买位置            
        local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(selfInfo.buyItemTimes)
        if isCanBuy then
            local lockCellHandler = RAPresidentQuarterCellHelper:CreateSpareCell(
                        cellIndex, true, selfInfo.buyItemTimes)
            local lockCell = CCBFileCell:create()            
            lockCell:registerFunctionHandler(lockCellHandler)
            lockCell:setCCBFile(lockCellHandler:GetCCBName())
            scrollView:addCellBack(lockCell)
        end

        scrollView:orderCCBFileCells()
    end
end


return RAPresidentQuarterPage
