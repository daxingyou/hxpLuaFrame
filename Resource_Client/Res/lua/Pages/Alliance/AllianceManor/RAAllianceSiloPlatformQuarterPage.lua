-- RAAllianceSiloPlatformQuarterPage.lua  qinho
--TO:联盟超级武器发射平台驻军信息
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

local RAAllianceSiloPlatformQuarterPage = BaseFunctionPage:new(...)

local MovableBuildStateTxt = 
{
    [GuildManor_pb.NONE_STATE] = {state = '@SuperWeaponPlatformNoBuild'},
    [GuildManor_pb.BUILDING_STATE] = {state = '@SuperWeaponPlatformBuilding'},
    [GuildManor_pb.FINISHED_STATE] = {state = '@SuperWeaponPlatformOverBuild'}
}



local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)    
    -- 部队详情开启和关闭
    if message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change then
        local showData = message.showData
        RAAllianceSiloPlatformQuarterPage:ChangeCellInfoStatus(showData)    
    -- 切换显示某个空闲cell的按钮状态
    elseif message.messageID == MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change then
        RAAllianceSiloPlatformQuarterPage:ChangeCellAddStatus()

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

function RAAllianceSiloPlatformQuarterPage:registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, OnReceiveMessage)
    end
end


function RAAllianceSiloPlatformQuarterPage:unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, OnReceiveMessage)
    end
end

function RAAllianceSiloPlatformQuarterPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAllianceSiloPlatformQuarterPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAAllianceSiloPlatformQuarterPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()        
    -- 请求返回
    if opcode == HP_pb.GET_GUILD_BASTION_MARCH_GARRISON_LIST_S then
        return
    end
end


function RAAllianceSiloPlatformQuarterPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAAllianceBaseWarInfoPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mTroopsListSV")
    self:_SetVisible(false)    
    if data ~= nil then
        self.mManorId = data.territoryId
        self.mCoord = data.coord
    end
    -- self.mManorId = RAAllianceManager:getActiveManorId()    
    if self.mManorId == nil then
        print('RAAllianceSiloPlatformQuarterPage:Enter error!! self alliance there is no manor')
        RARootManager.ClosePage('RAAllianceSiloPlatformQuarterPage')
        return
    end

    -- title
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end
    local titleName = _RALang("@AllianceNuclearTitle")

    self.curType = RAAllianceManager:getSelfSuperWeaponType() 
    self.mBuildConfData = nil
    local territory_building_conf = RARequire('territory_building_conf')
    if self.curType == Const_pb.GUILD_SILO then
        self.mBuildConfData = territory_building_conf[Const_pb.NUCLEAR]
    elseif self.curType == Const_pb.GUILD_WEATHER then
        self.mBuildConfData = territory_building_conf[Const_pb.WEATHER]
    end
    titleName = _RALang(self.mBuildConfData.name)
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceSiloPlatformQuarterPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)

    self:registerMessageHandlers()
    self:_registerPacketHandlers()

    self.mTeamData = nil
    self.mOpenItemMap = {}
    self.mSpareCellMap = {}    
    
    self.mLastUpdateTime = 0
    
    local platformInfo = RAAllianceManager:GetNuclearPlatformInfo()
    if self.mManorId ~= nil and self.mCoord ~= nil then
        local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
        RAWorldProtoHandler:sendGetGarrisonReq(self.mManorId, self.mCoord.x, self.mCoord.y)
    end
end

function RAAllianceSiloPlatformQuarterPage:_SetVisible(value)
    value = value or false
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end
    local visibleMap =
    {
        mCoordLabel        = value,
        mBaseLevel         = value,
        mLeaderName        = value,
        mBaseState         = value,
        mDefenseTroopsNum  = false,
        mTroopsListSV  = value,
    }
    UIExtend.setNodesVisible(ccbfile, visibleMap)
end



function RAAllianceSiloPlatformQuarterPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceSiloPlatformQuarterPage")
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:_unregisterPacketHandlers()

    self.mManorId = nil
    self.mTeamData = nil
    self.mOpenItemMap = {}
    self.mSpareCellMap = {}
    self.curType = nil
    self.mBuildConfData = nil
    self.mCoord = nil

    if self.scrollView then
        self.scrollView:removeAllCell()
    end
    self.scrollView = nil

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mCoordLabel')
    if htmlLabel then
        htmlLabel:removeLuaClickListener()
    end

    UIExtend.unLoadCCBFile(self)
end
function RAAllianceSiloPlatformQuarterPage:Execute()    
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        self:RefreshCommonUIPart()
    end
    
end

function RAAllianceSiloPlatformQuarterPage:CommonRefresh(data)
    local pageName = data.pageName
    local msg = data.msg
    if pageName == 'RAAllianceSiloPlatformQuarterPage' and msg ~= nil then        
        if msg.guildId == RAAllianceManager:GetGuildId() then
            local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
            self.mTeamData = RANewAllianceWarDataHelper:CreateTeamData(msg.team)
            self.mManorId = msg.manorId
            self:_BuildItemCellInfoOpenData(true)
            self:RefreshCommonUIPart()
            self:refreshScrollView()        
            self:_SetVisible(true)
        end
    end
end


-- 点击空白位置，关闭cell上的弹出
function RAAllianceSiloPlatformQuarterPage:onClose()
    self:ChangeCellAddStatus()
end


function RAAllianceSiloPlatformQuarterPage:_BuildItemCellInfoOpenData(isReset)
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


function RAAllianceSiloPlatformQuarterPage:RefreshCommonUIPart()
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end    
    local platformInfo = RAAllianceManager:GetNuclearPlatformInfo()
    local buildCfg = self.mBuildConfData
    local selfInfo = self.mTeamData

    if platformInfo == nil or buildCfg == nil or selfInfo == nil or selfInfo.leaderMarch == nil then
        self:_SetVisible(false)
    else
        self:_SetVisible(true)
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordLabel')
        if htmlLabel then
            htmlLabel:removeLuaClickListener()
            local nameStr = platformInfo.posX .. ',' .. platformInfo.posY
            local RAStringUtil = RARequire('RAStringUtil')
            local htmlStr = RAStringUtil:getHTMLString('WorldPosHtmlShow', nameStr, platformInfo.posX, platformInfo.posY)
            htmlLabel:setString(htmlStr)
            htmlLabel:registerLuaClickListener(function(id, data)
                local RAGameConfig = RARequire('RAGameConfig')
                if id == RAGameConfig.HTMLID.WorldPosShow then
                    local pos = RAStringUtil:split(data or '', ',') or {}
                    local x, y = unpack(pos)
                    if x and y then                        
                        RARootManager.CloseAllPages()
                        local RAWorldManager = RARequire('RAWorldManager')
                        RAWorldManager:LocateAt(tonumber(x), tonumber(y))
                    end
                end
            end)
        end
        local txtMap =
        {
            mBaseLevel        = _RALang('@SuperWeaponTypeWithName', _RALang(buildCfg.name)),
            mLeaderName       = '',
            mBaseState        = '',
            mDefenseTroopsNum = ''
        }

        local guildTag = RAAllianceManager:GetGuildTag()
        txtMap.mLeaderName = _RALang('@LearderStr', Utilitys.getDisplayName(selfInfo.leaderMarch.playerName, guildTag))

        local stateKey = MovableBuildStateTxt[platformInfo.machineState].state 
        if stateKey then
            if platformInfo.machineState == GuildManor_pb.BUILDING_STATE then
                local stateTxt = '00:00:00'
                local diffTime = platformInfo.machineFinishTime / 1000 - common:getCurTime()
                if diffTime > 0 then
                    stateTxt = Utilitys.createTimeWithFormat(diffTime)
                end            
                local stateContentStr = _RALang('@TwoParamsGapWithColon', _RALang(stateKey), stateTxt)        
                txtMap.mBaseState = _RALang('@NuclearPlatformStatusWithParam', stateContentStr)
            else
                txtMap.mBaseState = _RALang('@NuclearPlatformStatusWithParam', _RALang(stateKey))
            end
        end

        UIExtend.setStringForLabel(ccbfile, txtMap)
        UIExtend.addSpriteToNodeParent(ccbfile, 'mBaseIconNode', buildCfg.icon)
    end
end



function RAAllianceSiloPlatformQuarterPage:ChangeCellInfoStatus(showData)
    local oldStatus = self.mOpenItemMap[showData.playerId]
    self.mOpenItemMap[showData.playerId] = not oldStatus
    self:refreshScrollView()
end

function RAAllianceSiloPlatformQuarterPage:ChangeCellAddStatus(cellIndex)
    if self.mSpareCellMap == nil then
        return
    end
    for i,v in ipairs(self.mSpareCellMap) do
        local index = v.mIndex
        v:UpdateSpareCellStatus(false)
    end
end

function RAAllianceSiloPlatformQuarterPage:refreshScrollView()
    local RAAllianceBaseWarInfoCellHelper = RARequire('RAAllianceBaseWarInfoCellHelper')
    local mannorId = self.mManorId 
    local mannorData = self.mMannorData
    local selfInfo = self.mTeamData
    local openItemMap = self.mOpenItemMap        
    local coord = self.mCoord
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView

    local addParams = {
        coord = coord,
        nuclearType = self.curType,
        buildConfData = self.mBuildConfData,
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
                cellIndex, selfInfo.leaderMarch, status, mannorId, addParams)
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
                    cellIndex, v, status, mannorId, addParams)
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

        scrollView:orderCCBFileCells()
    end
end


return RAAllianceSiloPlatformQuarterPage
