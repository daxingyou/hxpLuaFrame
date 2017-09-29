--RAPresidentPalaceCellHelper
--联盟战争页面cell处理
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
local RABuildManager = RARequire("RABuildManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local World_pb=RARequire("World_pb")
local Utilitys = RARequire("Utilitys")
local common = RARequire("common")

local RAPresidentPalaceCellHelper = {}


-- 战争事件记录的cell
local RAPresidentEventHistoryCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentPalaceLabelCell.ccbi'
    end,

    SetData = function(self, index, eventData)
        self.mIndex = index
        self.mEventData = eventData
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        if self.mEventData ~= nil then
            local timeStr = Utilitys.timeConvertShowingTime(self.mEventData.eventTime)
            local cellLabelStr = ''
            local President_pb = RARequire('President_pb')
            if self.mEventData.eventType == President_pb.OCCUPY_PALACE then
                cellLabelStr = _RALang('@RecordOccpuyPalace', self.mEventData.guildName)
            elseif self.mEventData.eventType == President_pb.ATTACK_FAILED then
                cellLabelStr = _RALang('@RecordAttackFailed', self.mEventData.guildName, self.mEventData.enemyGuildName)
            elseif self.mEventData.eventType == President_pb.ATTACK_WIN then
                cellLabelStr = _RALang('@RecordAttackWin', self.mEventData.guildName, self.mEventData.enemyGuildName)
            elseif self.mEventData.eventType == President_pb.PRESIDENT_ELECTED then
                cellLabelStr = _RALang('@RecordPresidentElected', self.mEventData.guildName)
            end

            UIExtend.setStringForLabel(ccbfile, 
                {
                mTime = timeStr,
                mCellLabel = cellLabelStr,
                })
        end
    end,
}


-- 国王记录cell
local RAPresidentHistoryCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentPalaceCell.ccbi'
    end,

    SetData = function(self, index, presidentData)
        self.mIndex = index
        self.mPresidentData = presidentData
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        if self.mPresidentData ~= nil then
            UIExtend.handleCCBNode(ccbfile)
            local turnStr = _RALang('@PresidentTurnWithParam', self.mPresidentData.turnCount)
            local guildNameStr = _RALang('@GuildTagWithName', self.mPresidentData.guildTag, self.mPresidentData.guildName)
            UIExtend.setStringForLabel(ccbfile,
                {
                    mPresidentsTitle = turnStr,
                    mPresidentsName = self.mPresidentData.playerName,
                    mAllianceName = guildNameStr
                })

            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mCellIconNode')
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mAllianceSmallIcon')
            local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            local iconStr = RAPlayerInfoManager.getHeadIcon(self.mPresidentData.playerIcon)
            UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode', iconStr)

            local RAAllianceUtility = RARequire('RAAllianceUtility')
            local guildIconStr =RAAllianceUtility:getAllianceFlagIdByIcon(self.mPresidentData.guildFlag)
            UIExtend.addSpriteToNodeParent(ccbfile, 'mAllianceSmallIcon', guildIconStr)
        end
    end,
}


function RAPresidentPalaceCellHelper:CreatePresidentHistoryCell(index, presidentData)
    local cell = RAPresidentHistoryCell:New()
    cell:SetData(index, presidentData)
    return cell
end

function RAPresidentPalaceCellHelper:CreateEventHistoryCell(index, eventData)
    local cell = RAPresidentEventHistoryCell:New()
    cell:SetData(index, eventData)
    return cell
end

return RAPresidentPalaceCellHelper