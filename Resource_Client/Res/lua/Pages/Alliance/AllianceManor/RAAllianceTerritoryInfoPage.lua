--联盟领地页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local RARootManager = RARequire('RARootManager')
RARequire('MessageManager')
local HP_pb = RARequire('HP_pb')
local RAStringUtil = RARequire('RAStringUtil')
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local territory_building_conf =  RARequire('territory_building_conf')
local RAAllianceTerritoryInfoPage = class('RAAllianceTerritoryInfoPage',RAAllianceBasePage)
local guild_const_conf = RARequire('guild_const_conf')
function RAAllianceTerritoryInfoPage:ctor(...)
    self.ccbfileName = "RAAllianceTerritoryPopUp.ccbi"
    -- self.scrollViewName = 'mCreeateListSV'
end

function RAAllianceTerritoryInfoPage:init(data)
    -- self:refreshUI()
    local RATerritoryDataManager =  RARequire('RATerritoryDataManager')
    self.territoryData = RATerritoryDataManager:GetTerritoryById(data.manorId)

    local Const_pb = RARequire('Const_pb')
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mTerritoryIconNode", territory_building_conf[Const_pb.GUILD_BASTION].icon)

    self.mTerritoryState = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTerritoryState')
    self.mTerritoryLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTerritoryLevel')
    self.mTerritoryPos = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTerritoryPos')

    if self.territoryData.guildId ~= nil then 
    	self.mTerritoryState:setString(_RALang('@HaveOwner') .. '(' .. self.territoryData.guildName .. ')')
    else
    	self.mTerritoryState:setString(_RALang('@NoHaveOwner'))
    end

    self.mTerritoryLevel:setString(self.territoryData.level)
    local bastionPos = self.territoryData.buildingPos[Const_pb.GUILD_BASTION]
    self.mTerritoryPos:setString('X: ' .. bastionPos.x .. '  ,  Y: ' .. bastionPos.y) 
end

function RAAllianceTerritoryInfoPage:onClose()
    --关闭
    RARootManager.ClosePage("RAAllianceTerritoryInfoPage")
end

function RAAllianceTerritoryInfoPage:onConfirm()
	RARootManager.ClosePage('RAAllianceTerritoryInfoPage')
end


--初始化顶部
function RAAllianceTerritoryInfoPage:initTitle()
	local mCollectionName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCollectionName')
	mCollectionName:setString(_RALang('@AllianceTerritoryInfoTitle'))
end

return RAAllianceTerritoryInfoPage.new()