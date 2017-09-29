--联盟建筑的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceBaseCell = RARequire('RAAllianceBaseCell')
local RAAllianceBuildingCell = class('RAAllianceBuildingCell',RAAllianceBaseCell)
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local territory_building_conf =  RARequire('territory_building_conf')
local RAAllianceManager = RARequire('RAAllianceManager')
local super_mine_conf = RARequire('super_mine_conf')
local GuildManor_pb = RARequire('GuildManor_pb')

local MovableBuildStateTxt = 
{
    [GuildManor_pb.NONE_STATE] = {state = '@SuperWeaponPlatformNoBuild'},
    [GuildManor_pb.BUILDING_STATE] = {state = '@SuperWeaponPlatformBuilding'},
    [GuildManor_pb.FINISHED_STATE] = {state = '@SuperWeaponPlatformOverBuild'}
}

--刷新数据
function RAAllianceBuildingCell:onRefreshContent(ccbRoot)
	UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
	self.ccbfile = ccbRoot:getCCBFileNode() 

    --没有用的控件
	UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceName'):setVisible(false)

    --建筑名称
    self.mCellTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellTitle')
    -- self.mCellTitle:setString(_RALang(self.data.confData.name))

    --建筑坐标
    self.mPos = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mFightValue')
    self.mPos:setString(_RALang('@WorldCoordPos', self.data.pos.x, self.data.pos.y))        

    --建筑图片

    if self.data.buildingType == Const_pb.GUILD_MINE then
    	self.mCellTitle:setString(_RALang(super_mine_conf[RAAllianceManager.selfAlliance.manorResType].name))
    	UIExtend.addSpriteToNodeParent(self.ccbfile, "mFrameIconNode", super_mine_conf[RAAllianceManager.selfAlliance.manorResType].icon)
    else 
    	UIExtend.addSpriteToNodeParent(self.ccbfile, "mFrameIconNode", self.data.confData.icon)
    	self.mCellTitle:setString(_RALang(self.data.confData.name))	
    end 

    if self.data.buildingType == Const_pb.GUILD_CANNON then 
    	UIExtend.getCCNodeFromCCB(self.ccbfile,'mCoordinateNode'):setVisible(false)
   	else
   		UIExtend.getCCNodeFromCCB(self.ccbfile,'mCoordinateNode'):setVisible(true)
   	end 

    self.mIsCanLook = true
    -- 发射平台显示
    local platformInfo = RAAllianceManager:GetNuclearPlatformInfo()
    if self.data.buildingType == Const_pb.GUILD_MOVABLE_BUILDING then
        if platformInfo ~= nil then
            local showCfg = MovableBuildStateTxt[platformInfo.machineState]
            local allianceStr = ''
            local isShowPos = false
            if platformInfo.machineState == GuildManor_pb.NONE_STATE then
                allianceStr = _RALang(showCfg.state)
                self.mIsCanLook = false
            elseif platformInfo.machineState == GuildManor_pb.BUILDING_STATE then
                allianceStr = _RALang(showCfg.state) .. '\n'
                --添加倒计时

                isShowPos = true
            elseif platformInfo.machineState == GuildManor_pb.FINISHED_STATE then
                allianceStr = _RALang(showCfg.state)
                isShowPos = true
            end
            UIExtend.setNodeVisible(self.ccbfile, 'mCoordinateNode', isShowPos)
            if isShowPos then
                UIExtend.setCCLabelString(self.ccbfile, 'mFightValue', 
                    _RALang('@WorldCoordPos', platformInfo.posX, platformInfo.posY))
                self.data.pos.x = platformInfo.posX
                self.data.pos.y = platformInfo.posY
            end
            UIExtend.setCCLabelString(self.ccbfile, 'mAllianceName', allianceStr)
            UIExtend.setNodeVisible(self.ccbfile, 'mAllianceName', true)
        else
            UIExtend.setNodeVisible(self.ccbfile, 'mCoordinateNode', false)
            UIExtend.setNodeVisible(self.ccbfile, 'mAllianceName', false)
        end
    end    

    UIExtend.getCCNodeFromCCB(self.ccbfile,'mLaunchNuclearNode'):setVisible(false)
end

--跳转到地图
function RAAllianceBuildingCell:onCheckPosBtn()
    if self.mIsCanLook then
    	local RAWorldManager = RARequire('RAWorldManager')    
    	RAWorldManager:LocateAt(self.data.pos.x, self.data.pos.y)
    	RARootManager.CloseAllPages()
    end
end

--打开详情
function RAAllianceBuildingCell:onTranferBtn()
	-- body
    local Const_pb = RARequire('Const_pb')

	if self.data.buildingType == Const_pb.GUILD_BASTION then
		RARootManager.OpenPage('RAAllianceBaseWarPage')
	elseif self.data.buildingType == Const_pb.GUILD_SILO or self.data.buildingType == Const_pb.GUILD_WEATHER --超级武器和充能系统都跳去同一个页面
	or self.data.buildingType == Const_pb.GUILD_URANIUM or self.data.buildingType == Const_pb.GUILD_ELECTRIC then 
		-- RARootManager.OpenPage("RAAllianceSiloPage",nil,false,true,true)

        RAAllianceManager:showSolePage()
	elseif self.data.buildingType == Const_pb.GUILD_SHOP then 
		RARootManager.OpenPage("RAAllianceShopPage")
	elseif self.data.buildingType == Const_pb.GUILD_MINE then 
		local pageData =
                {
                    pointX = self.data.pos.x,
                    pointY = self.data.pos.y,
                    guildMineType = RAAllianceManager.selfAlliance.manorResType,
                }
                RARootManager.OpenPage('RAAllianceSuperMinePage', pageData, false, true, true)
	elseif self.data.buildingType == Const_pb.GUILD_HOSPITAL or self.data.buildingType == Const_pb.GUILD_CANNON then 
		local pageData =
                {
                    pointX = self.data.pos.x,
                    pointY = self.data.pos.y,
                    manorId = RAAllianceManager.selfAlliance.manorId,
                    buildId = self.data.confData.id,
                    buildType =self.data.buildingType
                }
        RARootManager.OpenPage('RAAlliancePassivePage', pageData, false, true, true)        
	elseif self.data.buildingType == Const_pb.GUILD_MOVABLE_BUILDING then
        print('open move page')
        RARootManager.OpenPage('RAAllianceSiloPlatformPage', nil, true, true, true)
    end
end

function RAAllianceBuildingCell:ctor(data)
	self.data = data
	self.ccbfileName = 'RAAllianceTerritoryCell.ccbi'
end

return RAAllianceBuildingCell