-- RAAllianceBaseWarPage.lua  qinho
--联盟堡垒页面
RARequire('BasePage')
local RAAllianceBaseWarPage = BaseFunctionPage:new(...)

local RARootManager = RARequire('RARootManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
local RANetUtil = RARequire('RANetUtil')
local RAWorldUtil = RARequire('RAWorldUtil')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local HP_pb = RARequire('HP_pb')
local Const_pb = RARequire('Const_pb')
local GuildManor_pb = RARequire('GuildManor_pb')


-- cell ---

local BastionStatus2BtnKey =
{
    [GuildManor_pb.BASTION_SHOW_OCCUPIED]    = {'',   '@WarTroopsDetails',   ''},
    [GuildManor_pb.BASTION_SHOW_LOSING]      = {'@WarTroopsDetails', '@MassReoccupy', '@Reoccupy'},
    [GuildManor_pb.BASTION_SHOW_EFFECTED]    = {'',    '@WarTroopsDetails',    ''},
    [GuildManor_pb.BASTION_SHOW_UNEFFECTED]  = {'@BecomeEffective',    '@WarTroopsDetails',    ''},
    [GuildManor_pb.BASTION_SHOW_SWITCH]      = {'@CancelEffective',    '@WarTroopsDetails',    ''}
}


local CheckMassTB =
{
    ['@MassReoccupy']  = true,
}

local BastionStatus2TimerKey =
{
    [GuildManor_pb.BASTION_SHOW_OCCUPIED]   = '@OcuppyTimer',
    [GuildManor_pb.BASTION_SHOW_LOSING]     = '@AttackedTimer',
    [GuildManor_pb.BASTION_SHOW_SWITCH]     = '@SwitchingTimer'
}


local RAAllianceBaseWarCell = {
    New = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    SetData = function(self, info)
        self.bastionInfo = info or nil
    end,

    GetCCBName = function(self)
        return 'RAAllianceBaseWarCell.ccbi'
    end,

    onUnLoad = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        if ccbfile ~= nil then
            local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordLabel')
            if htmlLabel then
                htmlLabel:removeLuaClickListener()
            end
        end
    end,

    onRefreshContent = function(self, cellRoot)
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile == nil then return end

        local info = self.bastionInfo

        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordLabel')
        if htmlLabel then
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
                        RAWorldManager:LocateAt(tonumber(x), tonumber(y))
                    end
                end
            end)
        end
        local txtMap =
        {
            mLevel        = _RALang('@LevelStr', info.level),
            mPlayerName   = '',
            mState        = ''
        }


        local visibleMap =
        {
            mFunctionBtnNode1       = true,
            mFunctionBtnNode2       = true,
            mFunctionBtnNode3       = true,
            mIconStateNode          = info.isAttacked,
        }

        local btnTitleMap =
        {
            mFunctionBtn1       = '',
            mFunctionBtn2       = '',
            mFunctionBtn3       = '',
        }

        local enableMap =
        {
            mFunctionBtn1 = true,
            mFunctionBtn2 = true,
            mFunctionBtn3 = true,
        }

        local keys = BastionStatus2BtnKey[info.status]
        for k, v in pairs(keys) do
            if v == nil or v == '' then
                visibleMap['mFunctionBtnNode' .. k] = false
                enableMap['mFunctionBtn' .. k] = false
            else
                btnTitleMap['mFunctionBtn' .. k] = _RALang(v)
                if CheckMassTB[v] and not RAWorldUtil:IsAbleToMass() then
                    enableMap['mFunctionBtn' .. k] = false
                end
            end
        end

        local stateKey = BastionStatus2TimerKey[info.status] 
        if stateKey then
            local stateTxt = '00:00:00'
            local diffTime = info.downTime / 1000 - common:getCurTime()
            if diffTime > 0 then
                cellRoot:setIsScheduleUpdate(true)
                stateTxt = Utilitys.createTimeWithFormat(diffTime)
            end
            self.timerKey = stateKey
            txtMap.mState = _RALang(self.timerKey, stateTxt)
        elseif info.status == GuildManor_pb.BASTION_SHOW_EFFECTED then
            txtMap.mState = _RALang('@ComeIntoEffect')
        elseif info.status == GuildManor_pb.BASTION_SHOW_UNEFFECTED then
            txtMap.mState = _RALang('@OccupiedButNoEffect')
        end

        if info.status == GuildManor_pb.BASTION_SHOW_LOSING then
            txtMap.mPlayerName = _RALang('@OccupierStr', info.name)
            txtMap.mIconState = _RALang('@IsOccupied')
            visibleMap.mIconStateNode = true
        else
            local guildTag = RAAllianceManager:GetGuildTag()
            if info.name == '' then
                txtMap.mPlayerName = _RALang('@LearderStr', _RALang('@NoLeaderToShow'))
            else
                txtMap.mPlayerName = _RALang('@LearderStr', Utilitys.getDisplayName(info.name, guildTag))
            end
            txtMap.mIconState = info.isAttacked and _RALang('@IsAttacked') or ''
        end

        UIExtend.setStringForLabel(ccbfile, txtMap)
        UIExtend.setNodesVisible(ccbfile, visibleMap)
        UIExtend.setTitle4ControlButtons(ccbfile, btnTitleMap)
        UIExtend.setEnabled4ControlButtons(ccbfile, enableMap)
        UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', info.icon)
    end,

    onExecute = function(self, cellRoot)
        if cellRoot and self.timerKey then
            local diffTime = self.bastionInfo.downTime / 1000 - common:getCurTime()
            if diffTime > 0 then
                cellRoot:setIsScheduleUpdate(true)
                local stateTxt = Utilitys.createTimeWithFormat(diffTime)
                UIExtend.setCCLabelString(cellRoot:getCCBFileNode(), 'mState', _RALang(self.timerKey, stateTxt))
            else
                cellRoot:setIsScheduleUpdate(false)
                -- MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_BastionListCell, {stateChanged = true})
            end
        end
    end,

    onFunctionBtn1 = function (self)
        local status = self.bastionInfo.status

        -- 已生效的时候
        if status == GuildManor_pb.BASTION_SHOW_EFFECTED then
            -- do nothing

        -- 未生效的时候
        elseif status == GuildManor_pb.BASTION_SHOW_UNEFFECTED then
            -- swtich to effective
            self:_SwitchEffectivity(false)

        --占领中
        elseif status == GuildManor_pb.BASTION_SHOW_OCCUPIED then
            -- do nothing            

        --丢失中
        elseif status == GuildManor_pb.BASTION_SHOW_LOSING then
            -- 守军信息
            self:_ShowArmyDetail()
        --切换中
        elseif status == GuildManor_pb.BASTION_SHOW_SWITCH then
            -- 取消生效            
            self:_SwitchEffectivity(true)
        end
    end,

    onFunctionBtn2 = function (self, node, fromLink)
        local status = self.bastionInfo.status

        -- 已生效的时候
        if status == GuildManor_pb.BASTION_SHOW_EFFECTED then
            -- 守军信息
            self:_ShowArmyDetail()

        -- 未生效的时候
        elseif status == GuildManor_pb.BASTION_SHOW_UNEFFECTED then
            -- 守军信息
            self:_ShowArmyDetail()

        --占领中
        elseif status == GuildManor_pb.BASTION_SHOW_OCCUPIED then
            -- 守军信息
            self:_ShowArmyDetail()

        --丢失中
        elseif status == GuildManor_pb.BASTION_SHOW_LOSING then
            -- 集结收复
            self:_MassReoccupy()
        --切换中
        elseif status == GuildManor_pb.BASTION_SHOW_SWITCH then
            -- 守军信息
            self:_ShowArmyDetail()
        end
    end,

    onFunctionBtn3 = function (self)
        local status = self.bastionInfo.status

        -- 已生效的时候
        if status == GuildManor_pb.BASTION_SHOW_EFFECTED then
            -- do nothing

        -- 未生效的时候
        elseif status == GuildManor_pb.BASTION_SHOW_UNEFFECTED then
            -- do nothing

        --占领中
        elseif status == GuildManor_pb.BASTION_SHOW_OCCUPIED then
            -- do nothing

        --丢失中
        elseif status == GuildManor_pb.BASTION_SHOW_LOSING then
            -- 收复
            self:_Reoccupy()
        --切换中
        elseif status == GuildManor_pb.BASTION_SHOW_SWITCH then
            -- do nothing
        end

        -- MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_BastionListCell, {id = self.bastionInfo.id})
    end,

    -- 守军信息
    _ShowArmyDetail = function(self)
        RARootManager.OpenPage('RAAllianceBaseWarInfoPage', {
            id = self.bastionInfo.id,
            mannorData = self.bastionInfo
            }, true)
    end,

    -- 设为生效或者取消生效
    _SwitchEffectivity = function(self, isCancel)
        isCancel = isCancel or false
        local reqFunc = function()
            RAWorldProtoHandler:sendActivateBastionReq(self.bastionInfo.id, isCancel)
        end
        if not isCancel and RAAllianceManager:GetIsHasPlatform() then
            -- 有发射平台的时候，要提示确认
            local confirmData =
            {
                title = _RALang('@SwitchManorWarningSiloTitle'),
                labelText = _RALang('@SwitchManorWarningSiloMsg'),
                yesNoBtn = true,
                resultFun = function (isOK)
                    if isOK then
                        reqFunc()
                    end
                end
            }
            RARootManager.showConfirmMsg(confirmData)
        else
            reqFunc()
        end
    end,

    -- 收复
    _Reoccupy = function (self)
        local this = self
        local confirmFunc = function ()
            RAWorldUtil:ChargeTroops(this.bastionInfo, World_pb.MANOR_SINGLE)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)
    end,

    -- 集结收复
    _MassReoccupy = function (self)
        local this = self
        local confirmFunc = function ()
            RAWorldUtil:GatherTroops(this.bastionInfo, World_pb.MANOR_MASS)
        end
        RAWorldUtil:ActAfterConfirm(confirmFunc)
    end,
}


---------------


RAAllianceBaseWarPage.mPageName     = 'RAAllianceBaseWarPage'
RAAllianceBaseWarPage.mScrollView   = nil
RAAllianceBaseWarPage.mBastionList  = nil
RAAllianceBaseWarPage.mTerrBuildId  = nil

local msgTB =
{
    MessageDef_ScrollViewCell.MSG_BastionListCell,
    MessageDef_Packet.MSG_Operation_OK
}

local opcodeTB =
{
    HP_pb.GET_GUILD_MANOR_BASTION_SHOW_LIST_S,
}

function RAAllianceBaseWarPage:Enter(pageInfo)
    self:_resetData()
    pageInfo = pageInfo or {}
    self.mTerrBuildId = pageInfo.terrBuildingId
    if self.mTerrBuildId == nil then
        local RAWorldConfig = RARequire('RAWorldConfig')
        self.mTerrBuildId = RAWorldConfig.TerritoryBuildingId[Const_pb.GUILD_BASTION]
    end
    UIExtend.loadCCBFile('RAAllianceBaseWarPage.ccbi', self)
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mTroopsListSV')
    self:_initTitle()

    self:_registerMessageHandlers()
    self:_registerPacketHandlers()
    self:_getBastionInfo()
end

function RAAllianceBaseWarPage:Exit()
    self:_unregisterMessageHandlers()
    self:_unregisterPacketHandlers()
    
    self:_resetData()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    UIExtend.unLoadCCBFile(self)
end

function RAAllianceBaseWarPage:_resetData()
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    self.mScrollView = nil
    self.mTerrBuildId = nil
end

--初始化顶部
function RAAllianceBaseWarPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local this = self
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end
    RACommonTitleHelper:RegisterCommonTitle(self.mPageName, 
        titleCCB, _RALang('@AllianceBastionTitle'), backCallBack, RACommonTitleHelper.BgType.Blue)
    UIExtend.setCCLabelString(self.ccbfile, 'mBaseNum', '')
end

function RAAllianceBaseWarPage:_refreshContent()
    local cnt = common:table_count(self.mBastionList or {})
    local subTitle = _RALang('@BastionCntTitle', cnt)
    UIExtend.setCCLabelString(self.ccbfile, 'mBaseNum', subTitle)

    self:_initScrollview()
end

function RAAllianceBaseWarPage:_initScrollview()
    self.mScrollView:removeAllCell()

    local arr = {}
    if self.mBastionList ~= nil then
        --排序
        arr = Utilitys.table2Array(self.mBastionList)
        Utilitys.tableSortByKey(arr, 'status')
    end

    for k, bastionInfo in pairs(arr) do
        local itemCell, cellHandler = nil, nil  
        itemCell = CCBFileCell:create()
        cellHandler = RAAllianceBaseWarCell:New()
        cellHandler:SetData(bastionInfo)
        itemCell:registerFunctionHandler(cellHandler)
        itemCell:setCCBFile(cellHandler:GetCCBName())
        
        self.mScrollView:addCellBack(itemCell)
    end
    self.mScrollView:orderCCBFileCells()
end


function RAAllianceBaseWarPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAllianceBaseWarPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAAllianceBaseWarPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_ScrollViewCell.MSG_BastionListCell then
        if msg.stateChanged then
            RAAllianceBaseWarPage:_getBastionInfo()
        else
            RAAllianceBaseWarPage:_selectBastion(msg.id)
        end
        return 
    end

    if msgId == MessageDef_Packet.MSG_Operation_OK then
        if msg.opcode == HP_pb.SWITCH_GUILD_MANOR_C then
            RAAllianceBaseWarPage:_getBastionInfo()
        end
        return
    end
end

function RAAllianceBaseWarPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAllianceBaseWarPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

-- 获取所有领地数据
function RAAllianceBaseWarPage:_getBastionInfo()
   RAWorldProtoHandler:sendGetBationsReq()
end

function RAAllianceBaseWarPage:CommonRefresh(data)
    self:_getBastionInfo()
end

function RAAllianceBaseWarPage:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()

    if opcode == HP_pb.GET_GUILD_MANOR_BASTION_SHOW_LIST_S then
        local msg = GuildManor_pb.GetManorBastionShowPBListResp()
        msg:ParseFromString(buffer)
        self:_onReceiveBastionInfo(msg)
        return
    end
end

function RAAllianceBaseWarPage:_onReceiveBastionInfo(msg)
    self.mBastionList = {}

    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(self.mTerrBuildId)

    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    for _, v in ipairs(msg.manorBastions) do
        local territoryId = v.manorId
        local territoryData = RATerritoryDataManager:GetTerritoryById(territoryId)
        if territoryData ~= nil then
            local bastionInfo =
            {
                id          = territoryId,
                level       = territoryData.level,
                icon        = cfg.icon,
                name        = v.leaderName,
                bastionName = _RALang(cfg.name),
                coord       = territoryData.buildingPos[Const_pb.GUILD_BASTION],
                isAttacked  = false
            }
            if v:HasField('status') then
                bastionInfo.status = v.status
            end
            if v:HasField('downTime') then
                bastionInfo.downTime = v.downTime
            end
            if v:HasField('isAttacked') then
                bastionInfo.isAttacked = v.isAttacked
            end

            if bastionInfo.status ~= nil then
                self.mBastionList[territoryId] = bastionInfo
            end
        else
            CCLuaLog('>>>>>>invalid territory id: ' .. territoryId)
        end
    end

    self:_refreshContent()
end
