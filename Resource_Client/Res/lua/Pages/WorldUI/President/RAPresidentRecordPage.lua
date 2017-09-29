-- 王国界面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAPresidentConfig = RARequire('RAPresidentConfig')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RANetUtil = RARequire('RANetUtil')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local RecordType = RAPresidentConfig.RecordType

local pageInfo =
{
    mPageName       = 'RAPresidentRecordPage',
    mScrollView     = nil,
    mRecordType     = RecordType.Appointment,
    mRecordList     = {}
}
local RAPresidentRecordPage = BaseFunctionPage:new(..., pageInfo)

--------------------------------------------------------------------------------------
-- region: RARecordCellHandler

local RARecordCellHandler =
{
    mRecordType = RecordType.Appointment,

    mRecord = {},

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentRecordCell.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local txtMap =
        {
            mTime = Utilitys.timeConvertShowingTime(self.mRecord.time)
        }
        UIExtend.setStringForLabel(ccbfile, txtMap)

        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCellLabel')
        local htmlStr = ''
        if self.mRecordType == RecordType.Appointment then
            htmlStr = self:_getAppointmentRecordStr()
        elseif self.mRecordType == RecordType.Gift then
            htmlStr = self:_getGiftRecordStr()
        end
        htmlLabel:setString(htmlStr)
    end,

    _getAppointmentRecordStr = function(self)
        local info = self.mRecord.officialInfo

        local curPlayerName = info.curPlayerName or ''
        local curOfficialCfg = RAWorldConfigManager:GetOfficialPositionCfg(info.curOfficerId) or {}
        local curOfficialName = _RALang(curOfficialCfg.officeName)

        local oriPlayerName = info.oriPlayerName
        -- 原职位是否有玩家
        local isReplaced = not common:isEmptyStr(oriPlayerName)

        local oriOfficialCfg = RAWorldConfigManager:GetOfficialPositionCfg(info.oriOfficerId or 0) or {}
        -- 当前玩家是否已经有职位
        local isChanged = oriOfficialCfg.id ~= nil
        local oriOfficialName = isChanged and _RALang(oriOfficialCfg.officeName) or _RALang('@NoOfficial')

        if isReplaced then
            if isChanged then
                local President_pb = RARequire('President_pb')
                if info.curOfficerId == President_pb.OFFICER_00 then
                    local key = 'OfficialDismissRecord'
                    return RAStringUtil:getHTMLString(key, oriPlayerName, oriOfficialName)
                end
            end
            local key = 'OfficialReplaceRecord'
            return RAStringUtil:getHTMLString(key, curPlayerName, oriOfficialName, curOfficialName, oriPlayerName)
        else
            local key = 'OfficialAppointRecord'
            return RAStringUtil:getHTMLString(key, curPlayerName, oriOfficialName, curOfficialName)
        end
    end,

    _getGiftRecordStr = function(self)
        local key = 'PresidentGiftRecord'
        local info = self.mRecord.giftInfo
        local cfg = RAWorldConfigManager:GetPresidentGiftCfg(info.giftId) or {}
        local giftName = _RALang(cfg.giftName)
        return RAStringUtil:getHTMLString(key, giftName, info.playerName)
    end
}

-- endregion: RARecordCellHandler
--------------------------------------------------------------------------------------

local RecordType2Title =
{
    [RecordType.Appointment]    = '@ApptRecord',
    [RecordType.Gift]           = '@PresidentGiftRecord'
}

local opcodeTB =
{
    [RecordType.Appointment] = HP_pb.OFFICER_RECORD_SYNC_S,
    [RecordType.Gift]        = HP_pb.PRESIDENT_GIFT_RECORD_S
}

function RAPresidentRecordPage:Enter(data)
    self:_resetData()
    self.mRecordType = data.recordType

    UIExtend.loadCCBFile('RAPresidentRecordPopUp.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')

    self:_initTitle()

    self:_registerPacketHandlers()
    self:_getRecord()
    self:_initScrollView()
end

function RAPresidentRecordPage:Exit()
    self:_unregisterPacketHandlers()
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAPresidentRecordPage:_resetData()
    self.mScrollView = nil
    self.mRecordList = {}
end

--初始化顶部
function RAPresidentRecordPage:_initTitle()
    local titleKey = RecordType2Title[self.mRecordType] or ''
    UIExtend.setStringForLabel(self.ccbfile, {mTitle = _RALang(titleKey)})
end

function RAPresidentRecordPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAPresidentRecordPage:_initScrollView()
    self.mScrollView:removeAllCell()
    
    local itemCell, cellHandler = nil, nil

    for _, record in ipairs(self.mRecordList) do
        itemCell = CCBFileCell:create()
        cellHandler = RARecordCellHandler:new({
            mRecordType = self.mRecordType,
            mRecord     = record
        })
        itemCell:registerFunctionHandler(cellHandler)
        itemCell:setCCBFile(cellHandler:getCCBName())
            
        self.mScrollView:addCellBack(itemCell)
    end

    self.mScrollView:orderCCBFileCells()
end

function RAPresidentRecordPage:_registerPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB[self.mRecordType], self)
end

function RAPresidentRecordPage:_unregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAPresidentRecordPage:_getRecord()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    if self.mRecordType == RecordType.Appointment then
        RAWorldProtoHandler:sendGetAppointmentRecordReq()
    elseif self.mRecordType == RecordType.Gift then
        RAWorldProtoHandler:sendGetPresidentGiftRecordReq()
    end
end

function RAPresidentRecordPage:onReceivePacket(handler)
    local opcode, buffer = handler:getOpcode(), handler:getBuffer()
    local President_pb = RARequire('President_pb')

    if opcode == HP_pb.OFFICER_RECORD_SYNC_S then
        local msg = President_pb.OfficerRecordSync()
        msg:ParseFromString(buffer)
        self:_onReceiveAppointmentRecord(msg)
        return
    end

    if opcode == HP_pb.PRESIDENT_GIFT_RECORD_S then
        local msg = President_pb.PresidentGiftRecordRes()
        msg:ParseFromString(buffer)
        self:_onReceiveGiftRecord(msg)
        return
    end
end

function RAPresidentRecordPage:_onReceiveAppointmentRecord(msg)
    self.mRecordList = {}
    for _, record in ipairs(msg.records) do
        table.insert(self.mRecordList, {
            time = record.time,
            officialInfo =
            {
                oriOfficerId    = record.oriOfficerId,
                curOfficerId    = record.curOfficerId,
                curPlayerName   = record.playerNameSet,
                oriPlayerName   = record.playerNameUnset
            }
        })
    end
    self:_sortRecord()
    self:_initScrollView()
end

function RAPresidentRecordPage:_onReceiveGiftRecord(msg)
    self.mRecordList = {}
    for _, record in ipairs(msg.giftRecord) do
        table.insert(self.mRecordList, {
            time = record.sendTime,
            giftInfo =
            {
                giftId      = record.giftId,
                playerName  = record.playerName
            }
        })
    end
    self:_sortRecord()
    self:_initScrollView()
end

function RAPresidentRecordPage:_sortRecord()
    table.sort(self.mRecordList, function(record_1, record_2)
        return record_1.time > record_2.time
    end)
end

return RAPresidentRecordPage