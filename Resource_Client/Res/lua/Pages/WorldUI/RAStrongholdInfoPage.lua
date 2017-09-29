--联盟领地据点页面
RARequire('BasePage')
local RAStrongholdInfoPage = BaseFunctionPage:new(...)

local RARootManager = RARequire('RARootManager')
local UIExtend = RARequire('UIExtend')
local common = RARequire('common')

-- 是否是联盟堡垒
RAStrongholdInfoPage.mIsBastion = false

function RAStrongholdInfoPage:Enter(pageInfo)
    UIExtend.loadCCBFile('RAAllianceTerritoryPopUp2.ccbi', self)

    self.mIsBastion = pageInfo.isBastion or false
    self.mBuildId = pageInfo.id or 0
    self.mTerritoryId = pageInfo.territoryId or 0
    self.mOwnerName = pageInfo.ownerName or ''

    self.mTerritoryType = pageInfo.territoryType or nil    
    self.mBuildStartTime = pageInfo.buildStartTime or 0

    self.mLastUpdateTime = 0
    self.mIsNeedUpdate = false
    self:_initContent(pageInfo)
end

function RAStrongholdInfoPage:Exit()
    UIExtend.unLoadCCBFile(self)
end

function RAStrongholdInfoPage:_initContent(data)
    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    if self.mTerritoryType == nil then
        local mCollectionName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, 'mCollectionName')
        mCollectionName:setString(_RALang(self.mIsBastion and '@BastionInfoTitle' or '@StrongholdInfoTitle'))

        local territoryData = RATerritoryDataManager:GetTerritoryById(self.mTerritoryId)

        local strongholdId = self.mIsBastion and territoryData.bastionId or data.id
        local RAWorldConfigManager = RARequire('RAWorldConfigManager')
        local strongholdCfg = RAWorldConfigManager:GetStrongholdCfg(strongholdId)
        UIExtend.addSpriteToNodeParent(self.ccbfile, 'mTerritoryIconNode', strongholdCfg.icon)

        local txtMap = 
        {
            mTerritoryBelongsLv     = _RALang('@TerritoryBelongsLv') .. (territoryData.level or 1),
            mAdscription            = '',
            mCompromisedTimes       = '',
            mcurrentPossession      = '',
            mExplain1               = _RALang('@StrongholdFunctionTitle'),
            mExplain2               = _RALang(self.mIsBastion and '@BastionFunctionDescription' or '@StrongholdFunctionDescription')
        }

        local isCompromised = (data.attackTimes or 0) == 0
        if isCompromised then
            local hasOccupier = not common:isEmptyStr(data.occupierName)

            local bastionPos = territoryData.buildingPos[Const_pb.GUILD_BASTION]
            txtMap.mAdscription         = _RALang('@BastionPos', bastionPos.x, bastionPos.y)
            txtMap.mCompromisedTimes    = _RALang('@Adscription') .. (data.ownerName or _RALang('@NoOwner'))
            txtMap.mcurrentPossession   = _RALang('@OccupiedGuildName') .. (hasOccupier and data.occupierName or _RALang('@OccupiedByNoOne'))
        else
            txtMap.mAdscription         = _RALang('@Adscription') .. _RALang(data.ownerName or strongholdCfg.armyName)
            txtMap.mCompromisedTimes    = _RALang('@CompromisedTimes') .. (data.attackTimes and (strongholdCfg.breakTimes - data.attackTimes) or 0)
        end

        UIExtend.setStringForLabel(self.ccbfile, txtMap)
    elseif self.mTerritoryType == Const_pb.GUILD_MOVABLE_BUILDING then
        -- 联盟移动建筑（发射平台）
        local territory_building_conf = RARequire('territory_building_conf')
        local buildCfgData = territory_building_conf[self.mBuildId]
        if buildCfgData ~= nil then
            UIExtend.addSpriteToNodeParent(self.ccbfile, 'mTerritoryIconNode', buildCfgData.icon)
            local txtMap = 
            {
                mCollectionName         = _RALang('@SuperWeaponPlatformInfoTitle'),
                mTerritoryBelongsLv     = _RALang('@SuperWeaponTypeWithName', _RALang(buildCfgData.name)),
                mAdscription            = _RALang('@BastionPos', data.coord.x, data.coord.y),
                mCompromisedTimes       = _RALang('@Adscription') .. (data.ownerName or _RALang('@NoOwner')),
                mcurrentPossession      = '',
                mExplain1               = _RALang('@StrongholdFunctionTitle'),
                mExplain2               = _RALang('@SuperWeaponPlatformFuncDes'),
            }
            
            UIExtend.setStringForLabel(self.ccbfile, txtMap)
            self.mIsNeedUpdate = self:_UpdateSuperWeaponPlatform()
        end            
    end
end

function RAStrongholdInfoPage:Execute()
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 and self.mIsNeedUpdate then
        self.mLastUpdateTime = 0
        self.mIsNeedUpdate = self:_UpdateSuperWeaponPlatform()
    end
end

function RAStrongholdInfoPage:_UpdateSuperWeaponPlatform()
    if self.mTerritoryType == Const_pb.GUILD_MOVABLE_BUILDING and self.mBuildStartTime > 0 then
        -- 状态
        local str = ''
        local isNeedUpdate = false
        local costTimeCfg = RARequire('guild_const_conf').platformBuilding.value
        local diffTime = self.mBuildStartTime / 1000 + costTimeCfg - common:getCurTime()
        if diffTime > 0 then
            --建筑未完成
            local Utilitys = RARequire('Utilitys')
            local timeStr = Utilitys.createTimeWithFormat(diffTime)
            str = _RALang('@TwoParamsGapWithColon', _RALang('@SuperWeaponPlatformBuilding'), Utilitys.createTimeWithFormat(diffTime))
            isNeedUpdate = true
        else
            --建筑完成
            str = _RALang('@SuperWeaponPlatformOverBuild')
        end
        UIExtend.setCCLabelString(self.ccbfile, 'mcurrentPossession', str)
        return isNeedUpdate
    end
    return false
end

function RAStrongholdInfoPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAStrongholdInfoPage:onConfirm()
	RARootManager.CloseCurrPage()
end

