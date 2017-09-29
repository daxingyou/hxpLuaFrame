--RANewAllianceWarCellHelper
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
local GuildWar_pb = RARequire("GuildWar_pb")
local Utilitys = RARequire("Utilitys")
local RAGameConfig = RARequire("RAGameConfig")
local common = RARequire("common")


local RANewAllianceWarCellHelper = {}


local RANewAllianceWarCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        o.mLastUpdateTime = 0
        return o
    end,
    GetCCBName = function(self)
        return 'RAAllianceWarCell.ccbi'
    end,

    SetData = function(self, index, oneCellData)
        self.mIndex = index
        self.mCellData = oneCellData
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        UIExtend.handleCCBNode(ccbfile)
        self.mLastUpdateTime = 0
        if self.mCellData ~= nil then
            if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                self:_handleRefreshForMass(ccbfile)
                self:_updateTimeForMass(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                self:_handleRefreshForAttack(ccbfile)
                self:_updateTimeForAttack(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                self:_handleRefreshForDefence(ccbfile)
                self:_updateTimeForDefence(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                self:_handleRefreshForQuartered(ccbfile)
                self:_updateTimeForQuartered(ccbfile)
            end                
        end
    end,

    -- 集结类型cell刷新
    _handleRefreshForMass = function(self, ccbfile)        
        local selfInfo = self.mCellData.selfInfo
        local selfIcon, selfName = selfInfo:GetShowDatas()
        --name
        UIExtend.setStringForLabel(ccbfile, {mPlayerName1 = selfName})
        --pos
        -- 默认自己，有行军就显示行军起点（往往也是自己）
        local RAWorldVar = RARequire('RAWorldVar')
        local coord = RAWorldVar.MapPos.Self
        if selfInfo ~= nil then
            coord = RACcp(selfInfo.x, selfInfo.y)
        end
        local posXAndY1 = _RALang('@WorldCoordPos', coord.x, coord.y)
        UIExtend.setStringForLabel(ccbfile, {mPos1 = posXAndY1})        
        --icon
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode1",selfIcon)
        UIExtend.addSpriteToNodeParent(ccbfile, "mArmyTagIcon1", "AllianceFlag_02.png")


        --def
        local singleData = self.mCellData.targetInfo
        local targetIcon, targetName = singleData:GetShowDatas()
        -- pos
        local posXAndY2 = _RALang('@WorldCoordPos', singleData.x, singleData.y)
        UIExtend.setStringForLabel(ccbfile, {mPos2 = posXAndY2})
        UIExtend.setStringForLabel(ccbfile, {mPlayerName2 = targetName})
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode2", targetIcon)  
        UIExtend.addSpriteToNodeParent(ccbfile, "mArmyTagIcon2", "Alliance_Icon_Def.png")
    end,

    -- 攻击类型cell刷新
    _handleRefreshForAttack = function(self, ccbfile)
        --和集结类型显示的一样，刷新time的时候不一样
        self:_handleRefreshForMass(ccbfile)
    end,

    -- 防守类型cell刷新
    _handleRefreshForDefence = function(self, ccbfile)
        --要把targetInfo放在左侧，selfInfo放右侧
        -- selfInfo放右侧（2结尾的node）
        -- def
        local selfInfo = self.mCellData.selfInfo
        local selfIcon, selfName = selfInfo:GetShowDatas()
        --name
        UIExtend.setStringForLabel(ccbfile, {mPlayerName2 = selfName})
        --pos
        -- 默认自己，有行军就显示行军起点（往往也是自己）
        local RAWorldVar = RARequire('RAWorldVar')
        local coord = RAWorldVar.MapPos.Self
        if selfInfo ~= nil then
            coord = RACcp(selfInfo.x, selfInfo.y)
        end
        local posXAndY1 = _RALang('@WorldCoordPos', coord.x, coord.y)
        UIExtend.setStringForLabel(ccbfile, {mPos2 = posXAndY1})        
        --icon
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode2",selfIcon)
        UIExtend.addSpriteToNodeParent(ccbfile, "mArmyTagIcon2", "AllianceFlag_02.png")

        -- targetInfo放在左侧（1结尾的node）
        -- atk
        local singleData = self.mCellData.targetInfo
        local targetIcon, targetName = singleData:GetShowDatas()
        -- pos
        local posXAndY2 = _RALang('@WorldCoordPos', singleData.x, singleData.y)
        UIExtend.setStringForLabel(ccbfile, {mPos1 = posXAndY2})
        UIExtend.setStringForLabel(ccbfile, {mPlayerName1 = targetName})
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode1", targetIcon)  
        UIExtend.addSpriteToNodeParent(ccbfile, "mArmyTagIcon1", "Alliance_Icon_Def.png")

        UIExtend.setControlButtonTitle(ccbfile, 'mStateBtn', '@EnemyInGatherTroops')        
    end,

    -- 驻守类型cell刷新
    _handleRefreshForQuartered = function(self, ccbfile)        
        local leaderShowData = self.mCellData.selfInfo.leaderMarch
        local marchData = leaderShowData.marchData
        --需要判断是否是单人还是集结
        local RAWorldUtil = RARequire('RAWorldUtil')
        if RAWorldUtil:IsMassRelatedMarch(marchData.marchType) then
            self:_handleRefreshForMass(ccbfile)
        else
            self:_handleRefreshForMass(ccbfile)
        end
    end,

    -- 集结类型cell刷新时间
    _updateTimeForMass = function(self, ccbfile)
        local leaderShowData = self.mCellData.selfInfo.leaderMarch
        local marchData = leaderShowData.marchData
        if marchData == nil then return end
        local statusStr = ""
        local lastTime = 0
        if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then   -- 集结等待状态
            statusStr = _RALang("@OurTroopsAssemblyIn")
            UIExtend.setControlButtonTitle(ccbfile, 'mStateBtn', '@OurInGatherTroops')
            local startTime = marchData.massReadyTime / 1000
            local endTime = marchData.startTime / 1000
            lastTime = os.difftime(endTime, common:getCurTime())
        elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then  --出征中
            statusStr = _RALang("@OurTroopsInRun")
            UIExtend.setControlButtonTitle(ccbfile, 'mStateBtn', '@OurInRunTroops')    
            local startTime = marchData.startTime / 1000
            local endTime = marchData.endTime / 1000
            lastTime = os.difftime(endTime, common:getCurTime())    
        end
        local timeStr = Utilitys.createTimeWithFormat(lastTime)
        statusStr = statusStr..timeStr
        UIExtend.setStringForLabel(ccbfile, {mWarStateLabel = statusStr})
        UIExtend.setColorForLabel(ccbfile, {mWarStateLabel = RAGameConfig.COLOR.WHITE})

        local isSelfLeader = RANewAllianceWarManager:CheckSelfIsLeader(self.mCellData.cellMarchId)
        local isSelfInTeam = RANewAllianceWarManager:CheckSelfIsInMassTeam(self.mCellData.cellMarchId)
        if isSelfInTeam or isSelfLeader then
            UIExtend.setControlButtonTitle(ccbfile, 'mStateBtn', '@SeeTroops')
        end
        UIExtend.setNodesVisible(ccbfile,{mStateBtn = true})
    end,

    -- 攻击类型cell刷新时间
    _updateTimeForAttack = function(self, ccbfile)
        local leaderShowData = self.mCellData.selfInfo.leaderMarch
        local marchData = leaderShowData.marchData
        if marchData == nil then return end
        local statusStr = ""
        local lastTime = 0
        if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then  --出征中
            statusStr = _RALang("@OurTroopsInRun")            
            local startTime = marchData.startTime / 1000
            local endTime = marchData.endTime / 1000
            lastTime = os.difftime(endTime, common:getCurTime())    
        end
        local timeStr = Utilitys.createTimeWithFormat(lastTime)
        statusStr = statusStr..timeStr
        UIExtend.setStringForLabel(ccbfile, {mWarStateLabel = statusStr})
        UIExtend.setColorForLabel(ccbfile, {mWarStateLabel = RAGameConfig.COLOR.GREEN})
        UIExtend.setNodesVisible(ccbfile,{mStateBtn = false})
    end,

    -- 防守类型cell刷新时间
    _updateTimeForDefence = function(self, ccbfile)
         --时间显示
        local singleData = self.mCellData.targetInfo
        local statusStr = ""
        local lastTime = os.difftime(singleData.endTime / 1000, common:getCurTime())  
        local isBtnVisible = true
        if singleData.marchStatus == World_pb.MARCH_STATUS_WAITING then   -- 集结等待状态
            statusStr = _RALang("@EnemyTroopsAssemblyIn")
        else -- MARCH_STATUS_MARCH                                  出征中
            statusStr = _RALang("@EnemyTroopsInRun")
        end
        local timeStr = Utilitys.createTimeWithFormat(lastTime)
        statusStr = statusStr..timeStr
        UIExtend.setStringForLabel(ccbfile, {mWarStateLabel = statusStr})
        UIExtend.setColorForLabel(ccbfile, {mWarStateLabel = RAGameConfig.COLOR.RED})
        UIExtend.setNodesVisible(ccbfile,{mStateBtn = isBtnVisible})

        local btnStr = '@EnemyInGatherTroops'
        if RANewAllianceWarManager:CheckSelfIsLeader(self.mCellData.cellMarchId) then
            btnStr = '@SeeTroops'
        end
        UIExtend.setControlButtonTitle(ccbfile, 'mStateBtn', btnStr)  
    end,

    -- 驻守类型cell刷新时间
    _updateTimeForQuartered = function(self, ccbfile)
        local leaderShowData = self.mCellData.selfInfo.leaderMarch
        local marchData = leaderShowData.marchData
        --需要判断是否是单人还是集结
        local RAWorldUtil = RARequire('RAWorldUtil')
        if RAWorldUtil:IsMassRelatedMarch(marchData.marchType) then
            self:_updateTimeForMass(ccbfile)
        else
            self:_updateTimeForAttack(ccbfile)
        end
    end,

    onExecute = function(self, ccbRoot)
        if not ccbRoot then return end
        local currTime = CCTime:getCurrentTime()
        if currTime - self.mLastUpdateTime < 300 then
            return
        end
        self.mLastUpdateTime = currTime
        local ccbfile = ccbRoot:getCCBFileNode()
        if self.mCellData ~= nil then
            if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                self:_updateTimeForMass(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                self:_updateTimeForAttack(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                self:_updateTimeForDefence(ccbfile)
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                self:_updateTimeForQuartered(ccbfile)
            end                
        end
    end,

    onJumpMyPosBtn = function(self)
        -- 默认自己，有行军就显示行军起点（往往也是自己）
        if self.mCellData == nil then return end
        if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS or 
            self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK or
            self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
            self:_WatchSelfInfo()
        else
            self:_WatchTargetInfo()
        end
    end,

    onJumpEnemyPosBtn = function(self)
        if self.mCellData == nil then return end
        if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS or 
            self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK or
            self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
            self:_WatchTargetInfo()
        else
            self:_WatchSelfInfo()
        end
    end,

    _WatchTargetInfo = function(self)
        local singleData = self.mCellData.targetInfo
        if singleData ~= nil then
            local RAWorldManager = RARequire("RAWorldManager")
            RARootManager.CloseAllPages()
            RAWorldManager:LocateAt(singleData.x, singleData.y)
        end
    end,
    _WatchSelfInfo = function(self)
        local RAWorldVar = RARequire('RAWorldVar')
        local coord = RACcp(self.mCellData.selfInfo.x, self.mCellData.selfInfo.y)
        local leaderShowData = self.mCellData.selfInfo.leaderMarch
        if leaderShowData.marchData ~= nil and self.mCellData.selfInfo.pointType == World_pb.PLAYER then
            coord = leaderShowData.marchData:GetStartCoord()
        end
        local RAWorldManager = RARequire("RAWorldManager")
        RARootManager.CloseAllPages()
        RAWorldManager:LocateAt(coord.x, coord.y)
    end,

    onStateBtn = function(self)
        if self.mCellData ~= nil then
            local leaderShowData = self.mCellData.selfInfo.leaderMarch
            --集结
            if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                local marchData = leaderShowData.marchData
                if marchData == nil then return end                
                if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING or
                    marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then

                    RARootManager.OpenPage("RANewAllianceWarDetailsPage",
                        {
                        index = self.mIndex,
                        cellMarchId = self.mCellData.cellMarchId,
                        warType = GuildWar_pb.GUILD_WAR_MASS
                        }, true)
                else
                    RARootManager.ShowMsgBox(_RALang("@IsrunTroopsStatus")..marchData.marchStatus)
                end
            --进攻
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                print('do nothing****************  atk')
            --防御
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then                
                local singleData = self.mCellData.targetInfo         
                local selfInfo = self.mCellData.selfInfo
                -- 据点、堡垒的时候需要特殊处理
                if selfInfo.pointType == World_pb.GUILD_GUARD or selfInfo.pointType == World_pb.GUILD_TERRITORY then
                    -- 堡垒和据点直接跳转
                    local RAWorldManager = RARequire("RAWorldManager")
                    RARootManager.CloseAllPages()
                    RAWorldManager:LocateAt(selfInfo.x, selfInfo.y, nil, true)

                elseif selfInfo.pointType == World_pb.KING_PALACE then
                    --王座
                    local RAWorldManager = RARequire("RAWorldManager")
                    RARootManager.CloseAllPages()
                    RAWorldManager:LocateAt(selfInfo.x, selfInfo.y, nil, true)
                else
                    --玩家
                    local Const_pb = RARequire("Const_pb")
                    RARootManager.OpenPage("RANewAllianceWarDetailsPage",{
                        index = self.mIndex,
                        cellMarchId = self.mCellData.cellMarchId,
                        warType = GuildWar_pb.GUILD_WAR_DEFENCE
                        }, true)
                end
            --驻守
            elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                print('do nothing****************  atk')
                local marchData = leaderShowData.marchData
                if marchData == nil then return end                
                if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING or
                    marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then

                    RARootManager.OpenPage("RANewAllianceWarDetailsPage",
                        {
                        index = self.mIndex,
                        cellMarchId = self.mCellData.cellMarchId,
                        warType = GuildWar_pb.GUILD_WAR_MASS
                        }, true)
                else
                    RARootManager.ShowMsgBox(_RALang("@IsrunTroopsStatus")..marchData.marchStatus)
                end
            end                
        end
    end,
}


function RANewAllianceWarCellHelper:CreateCell(index, oneCellData)
    local cell = RANewAllianceWarCell:New()
    cell:SetData(index, oneCellData)
    return cell
end

return RANewAllianceWarCellHelper