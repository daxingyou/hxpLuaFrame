-- RAAllianceBaseWarInfoPage.lua  qinho
--TO:联盟堡垒部队详情页面
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
local RANetUtil = RARequire('RANetUtil')
local RAAllianceManager = RARequire('RAAllianceManager')

local RAAllianceBaseWarInfoPage = BaseFunctionPage:new(...)

local BastionStatus2TimerKey =
{
    [GuildManor_pb.BASTION_SHOW_OCCUPIED]   = '@OcuppyTimer',
    [GuildManor_pb.BASTION_SHOW_LOSING]     = '@AttackedTimer',
    [GuildManor_pb.BASTION_SHOW_SWITCH]     = '@SwitchingTimer'
}


local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)    
    -- 部队详情开启和关闭
    if message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change then
        local showData = message.showData
        RAAllianceBaseWarInfoPage:ChangeCellInfoStatus(showData)    
    -- 切换显示某个空闲cell的按钮状态
    elseif message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change then
        RAAllianceBaseWarInfoPage:ChangeCellAddStatus()

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

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_BastionListCell,
    MessageDef_Packet.MSG_Operation_OK,
    MessageDef_Packet.MSG_Operation_Fail,
    MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change,
    MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change
}


local opcodeTB =
{
    HP_pb.GET_GUILD_BASTION_MARCH_GARRISON_LIST_S,
}

function RAAllianceBaseWarInfoPage:registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, OnReceiveMessage)
    end
end


function RAAllianceBaseWarInfoPage:unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, OnReceiveMessage)
    end
end

function RAAllianceBaseWarInfoPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAllianceBaseWarInfoPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAAllianceBaseWarInfoPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()        
    -- 请求返回
    if opcode == HP_pb.GET_GUILD_BASTION_MARCH_GARRISON_LIST_S then
        return
    end
end


function RAAllianceBaseWarInfoPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAAllianceBaseWarInfoPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mTroopsListSV")
    self:_SetVisible(false)
    if data ~= nil then
        self.mMannorId = data.id
        -- self.mMannorData = data.mannorData or nil
        self.mMannorData = nil
    end
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
    local titleName = _RALang("@AllianceBastionTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceBaseWarInfoPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)

    self:registerMessageHandlers()
    self:_registerPacketHandlers()

    self.mTeamData = nil
    self.mOpenItemMap = {}
    self.mSpareCellMap = {}    
    
    self.mLastUpdateTime = 0
    
    if self.mMannorId ~= nil then
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendGetGarrisonReq(self.mMannorId)
    end
end

function RAAllianceBaseWarInfoPage:_SetVisible(value)
    value = value or false
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    local visibleMap =
    {
        mCoordLabel        = value,
        mBaseLevel         = value,
        mLeaderName        = value,
        mBaseState         = value,
        mDefenseTroopsNum  = value,
        mTroopsListSV  = value,
    }
    UIExtend.setNodesVisible(ccbfile, visibleMap)
end



function RAAllianceBaseWarInfoPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceBaseWarInfoPage")
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:_unregisterPacketHandlers()

    self.mMannorId = nil
    self.mTeamData = nil
    self.mOpenItemMap = {}
    self.mSpareCellMap = {}

    if self.scrollView then
        self.scrollView:removeAllCell()
    end
    self.scrollView = nil

    UIExtend.removeHtmlLabelListener(self.ccbfile, 'mCoordLabel')

    UIExtend.unLoadCCBFile(self)
end
function RAAllianceBaseWarInfoPage:Execute()
    if self.mMannorData ~= nil then
        self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
        if self.mLastUpdateTime > 1 then
            self.mLastUpdateTime = 0
            self:RefreshCommonUIPart()
        end
    end
end

function RAAllianceBaseWarInfoPage:CommonRefresh(data)
    local pageName = data.pageName
    local msg = data.msg
    if pageName == 'RAAllianceBaseWarInfoPage' and data.isRequest then
        if self.mMannorId ~= nil then
            local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
            RAWorldProtoHandler:sendGetGarrisonReq(self.mMannorId)
        end
        return
    end
    if pageName == 'RAAllianceBaseWarInfoPage' and msg ~= nil then        
        local bastionShowMsg = msg.bastion
        if msg.guildId == RAAllianceManager:GetGuildId() and 
            bastionShowMsg ~= nil and 
            bastionShowMsg.manorId == self.mMannorId then

            local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
            local RAWorldConfigManager = RARequire('RAWorldConfigManager')
            local RATerritoryDataManager = RARequire('RATerritoryDataManager')
            local RAWorldConfig = RARequire('RAWorldConfig')
            local territoryData = RATerritoryDataManager:GetTerritoryById(self.mMannorId)
            local buildId = RAWorldConfig.TerritoryBuildingId[Const_pb.GUILD_BASTION]
            local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(buildId)
            if territoryData ~= nil then
                local bastionInfo =
                {
                    id          = self.mMannorId,
                    level       = territoryData.level,
                    icon        = cfg.icon,
                    name        = bastionShowMsg.leaderName,
                    bastionName = _RALang(cfg.name),
                    coord       = territoryData.buildingPos[Const_pb.GUILD_BASTION],
                    isAttacked  = false
                }
                if bastionShowMsg:HasField('status') then
                    bastionInfo.status = bastionShowMsg.status
                end
                if bastionShowMsg:HasField('downTime') then
                    bastionInfo.downTime = bastionShowMsg.downTime
                end
                if bastionShowMsg:HasField('isAttacked') then
                    bastionInfo.isAttacked = bastionShowMsg.isAttacked
                end
                self.mMannorData = bastionInfo
            end
            self.mTeamData = RANewAllianceWarDataHelper:CreateTeamData(msg.team)
            self.mMannorId = msg.manorId
            self:_BuildItemCellInfoOpenData(true)
            self:RefreshCommonUIPart()
            self:refreshScrollView()        
            self:_SetVisible(true)
        end
    end
end

-- 点击空白位置，关闭cell上的弹出
function RAAllianceBaseWarInfoPage:onClose()
    self:ChangeCellAddStatus()
end

function RAAllianceBaseWarInfoPage:_BuildItemCellInfoOpenData(isReset)
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


function RAAllianceBaseWarInfoPage:RefreshCommonUIPart()
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    if self.mMannorData == nil then return end
    local info = self.mMannorData

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordLabel')
    if htmlLabel then
        htmlLabel:removeLuaClickListener()
        local nameStr = info.coord.x .. ',' .. info.coord.y
        local RAStringUtil = RARequire('RAStringUtil')
        local htmlStr = RAStringUtil:getHTMLString('WorldPosHtmlShow', nameStr, info.coord.x, info.coord.y)
        htmlLabel:setString(htmlStr)
        htmlLabel:registerLuaClickListener(function(id, data)
            local RAGameConfig = RARequire('RAGameConfig')
            if id == RAGameConfig.HTMLID.WorldPosShow then
                local pos = RAStringUtil:split(data or '', ',') or {}
                local x, y = unpack(pos)
                if x and y then
                    RARootManager.CloseAllPages()
                    local RAWorldManager = RARequire('RAWorldManager')
                    RAWorldManager:LocateAt(x, y)
                end
            end
        end)
    end
    local txtMap =
    {
        mBaseLevel        = _RALang('@LevelStr', info.level),
        mLeaderName       = '',
        mBaseState        = ''
    }

    local stateKey = BastionStatus2TimerKey[info.status] 
    if stateKey then
        local stateTxt = '00:00:00'
        local diffTime = info.downTime / 1000 - common:getCurTime()
        if diffTime > 0 then
            stateTxt = Utilitys.createTimeWithFormat(diffTime)
        end
        self.timerKey = stateKey
        txtMap.mBaseState = _RALang(self.timerKey, stateTxt)
    elseif info.status == GuildManor_pb.BASTION_SHOW_EFFECTED then
        txtMap.mBaseState = _RALang('@ComeIntoEffect')
    elseif info.status == GuildManor_pb.BASTION_SHOW_UNEFFECTED then
        txtMap.mBaseState = _RALang('@OccupiedButNoEffect')
    end

    if info.status == GuildManor_pb.BASTION_SHOW_LOSING then
        txtMap.mLeaderName = _RALang('@OccupierStr', info.name)
    else
        local guildTag = RAAllianceManager:GetGuildTag()
        if info.name == '' then
            txtMap.mLeaderName = _RALang('@LearderStr', _RALang('@NoLeaderToShow'))
        else
            txtMap.mLeaderName = _RALang('@LearderStr', Utilitys.getDisplayName(info.name, guildTag))
        end
    end

    UIExtend.setStringForLabel(ccbfile, txtMap)
    UIExtend.addSpriteToNodeParent(ccbfile, 'mBaseIconNode', info.icon)


    --刷新数目
    local selfInfo = self.mTeamData
    local currCount = selfInfo:GetJoinedArmyCount()
    local limitCount = selfInfo.leaderArmyLimit
    local keyStr = '@QuarterArmyCountWith2Param'
    UIExtend.setStringForLabel(ccbfile, {mDefenseTroopsNum = _RALang(keyStr,currCount ,limitCount)})
end



function RAAllianceBaseWarInfoPage:ChangeCellInfoStatus(showData)
    local oldStatus = self.mOpenItemMap[showData.playerId]
    self.mOpenItemMap[showData.playerId] = not oldStatus
    self:refreshScrollView()
end

function RAAllianceBaseWarInfoPage:ChangeCellAddStatus(cellIndex)
    if self.mSpareCellMap == nil then
        return
    end
    for i,v in ipairs(self.mSpareCellMap) do
        local index = v.mIndex
        v:UpdateSpareCellStatus(false)
    end
end

function RAAllianceBaseWarInfoPage:refreshScrollView()
    local RAAllianceBaseWarInfoCellHelper = RARequire('RAAllianceBaseWarInfoCellHelper')
    local mannorId = self.mMannorId 
    local mannorData = self.mMannorData
    local selfInfo = self.mTeamData
    local openItemMap = self.mOpenItemMap        
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView

    local addParams = 
    {
        leaderId = '',
        leaderMarchId = ''
    }

    local checkAndCreateCellInfo = function(showData)
        local status = openItemMap[showData.playerId] or false
        local cell = nil
        local cellHandler = nil
        if status then
            cellHandler = RAAllianceBaseWarInfoCellHelper:CreateArmyInfoCell(
                index, showData, mannorId)
            cell = CCBFileCell:create()            
            cell:registerFunctionHandler(cellHandler)
            cell:setIsScheduleUpdate(true)
            cell:setCCBFile(cellHandler:GetCCBName())
            scrollView:addCellBack(cell)
        end
        return status, cell
    end
    if selfInfo ~= nil then
        --先创建队长
        local cellIndex = 1    
        local itemCount = 0
        if selfInfo.leaderMarch.playerId ~= '' and selfInfo.leaderMarch.marchData ~= nil then
            local status = openItemMap[selfInfo.leaderMarch.playerId] or false
            local leaderCellHandler = RAAllianceBaseWarInfoCellHelper:CreateJoinedCell(
                cellIndex, selfInfo.leaderMarch, status, mannorId)
            local leaderCell = CCBFileCell:create()            
            leaderCell:registerFunctionHandler(leaderCellHandler)
            leaderCell:setIsScheduleUpdate(true)
            leaderCell:setCCBFile(leaderCellHandler:GetCCBName())
            scrollView:addCellBack(leaderCell)            
            itemCount = itemCount + 1
            local leaderCellInfoStatus, leaderCellInfoCell = checkAndCreateCellInfo(selfInfo.leaderMarch)
            if leaderCellInfoStatus then cellIndex = cellIndex + 1 end

            -- 用于购买
            addParams.leaderId = selfInfo.leaderMarch.playerId
            addParams.leaderMarchId = selfInfo.leaderMarch.marchData.marchId
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
                local itemCellHandler = RAAllianceBaseWarInfoCellHelper:CreateJoinedCell(
                    cellIndex, v, status, mannorId)
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
        if mannorData.status ~= GuildManor_pb.BASTION_SHOW_LOSING then
            --创建剩余的空闲位置
            local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
            local baseMassNum = RANewAllianceWarManager:GetPlayerBaseMassItemCount()
            local spareNum = baseMassNum - itemCount + selfInfo.buyItemTimes
            if spareNum > 0 then                
                for i=1,spareNum do
                    cellIndex = cellIndex + 1
                    local spareCellHandler = RAAllianceBaseWarInfoCellHelper:CreateSpareCell(
                        cellIndex, false, selfInfo.buyItemTimes, mannorId, addParams)
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
                local lockCellHandler = RAAllianceBaseWarInfoCellHelper:CreateSpareCell(
                            cellIndex, true, selfInfo.buyItemTimes, mannorId, addParams)
                local lockCell = CCBFileCell:create()            
                lockCell:registerFunctionHandler(lockCellHandler)
                lockCell:setCCBFile(lockCellHandler:GetCCBName())
                scrollView:addCellBack(lockCell)
            end
        end

        scrollView:orderCCBFileCells()
    end
end


return RAAllianceBaseWarInfoPage
