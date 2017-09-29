--联盟领地页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local RARootManager = RARequire('RARootManager')
RARequire('MessageManager')
local HP_pb = RARequire('HP_pb')
local territory_building_conf =  RARequire('territory_building_conf')
local super_mine_conf = RARequire('super_mine_conf')
RARequire('extern')
local RAAllianceManager = RARequire('RAAllianceManager')
local UIExtend = RARequire('UIExtend')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManorPage = class('RAAllianceManorPage',RAAllianceBasePage)
local RANetUtil = RARequire('RANetUtil')
local Const_pb = RARequire('Const_pb')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local curPage = nil 

function RAAllianceManorPage:ctor(...)
    self.ccbfileName = "RAAllianceTerritoryPage.ccbi"
    self.scrollViewName = 'mCreeateListSV'
end

function RAAllianceManorPage:init(data)
	curPage = self
	self.data = data

    -- local RAAllianceManager = RARequire('RAAllianceManager')
    -- self.superWeaponType = RAAllianceManager:getSelfSuperWeaponType()
	--领地图片
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mTerritoryIconNode", self.data.buildings[Const_pb.GUILD_BASTION].confData.icon)

    self.mTerritoryLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTeeritoryLevel')
    self.mTerritoryLevel:setString(self.data.level)


    self.mTerritoryDefAddition = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTerritoryDefAddition')

    local num = RAAllianceManager:getCannoNumById(RAAllianceManager.selfAlliance.manorId)
    self.mTerritoryDefAddition:setString(num)

    self.mSuperResTpye = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mSuperResTpye')

    self:updateManorResType()

    self.mNuclearSilo = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNuclearSilo')
    

    self.mCombustionSpeed = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCombustionSpeed')

    local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId)  
    local speed = RAAllianceUtility:getUraniumOutput(territoryData) 

    self.mUraniumMiningRate = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mUraniumMiningRate')
    if speed ~= 0 then 
        self.mUraniumMiningRate:setString(speed .. '/' .. _RALang('@PerDay'))
        RAAllianceProtoManager:reqNuclearInfo()
    else 
        self.mUraniumMiningRate:setString('---')
        self.mNuclearSilo:setString('---')
    end

    self.mTerritoryPos = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTerritoryPos')

    local bastionPos = self.data.buildings[Const_pb.GUILD_BASTION].pos
    self.mTerritoryPos:setString('X ' .. bastionPos.x .. '  ,  Y ' .. bastionPos.y)

   -- 初始化建筑
    self.buildDatas = {}
    for buildType,buildData in pairs(self.data.buildings) do

        if buildType ~= Const_pb.GUILD_SHOP and buildType ~= Const_pb.GUILD_URANIUM and buildType ~= Const_pb.GUILD_ELECTRIC then 
            self.buildDatas[#self.buildDatas+1] = buildData
        end 
    end
end

function RAAllianceManorPage:release()
    if self.mMessageSV then
        self.mMessageSV:removeAllCell()
        self.mMessageSV = nil
    end
end

--查看基地
function RAAllianceManorPage:onCheckPosBtn()
	-- body
	local RAWorldManager = RARequire('RAWorldManager')
    local bastionPos = self.data.buildings[Const_pb.GUILD_BASTION].pos
	RAWorldManager:LocateAt(bastionPos.x, bastionPos.y)
	RARootManager.CloseAllPages()
end

--更新
function RAAllianceManorPage:refreshNuclearInfo()
    local nuclearData = RAAllianceManager:GetNuclearInfo()

    if nuclearData == nil then 
        return 
    end 

    if nuclearData.launchTime == 0 then 
    	self.mNuclearSilo:setString(_RALang("@NuclearWaiting"))
    else 
    	self.mNuclearSilo:setString(_RALang("@NuclearLaunching"))
    end 
end

function RAAllianceManorPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    
end

--子类实现
function RAAllianceManorPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GET_NUCLEAR_INFO_S, self) 
end


--刷新scrollview
function RAAllianceManorPage:initScrollview()
	self.mMessageSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
	self.mMessageSV:removeAllCell()

	local RAAllianceBuildingCell = RARequire('RAAllianceBuildingCell')
    for i=#self.buildDatas,1,-1 do
        local cell = CCBFileCell:create()
        local panel = RAAllianceBuildingCell.new(self.buildDatas[i])
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(panel.ccbfileName)
        self.mMessageSV:addCell(cell)
    end

    -- 添加发射井
    if self.data.superWeaponType ~= nil then

    end

    self.mMessageSV:orderCCBFileCells()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Alliance.MSG_Alliance_ManorResType_Change then
    	curPage:updateManorResType()
        curPage:initScrollview() 
    end 

    if message.messageID == MessageDef_Alliance.MSG_NuclearInfo_Update then
        curPage:initScrollview()
    end
end

function RAAllianceManorPage:updateManorResType()
    if RAAllianceManager.selfAlliance.manorResType ~= nil then 
        self.mSuperResTpye:setString(_RALang(super_mine_conf[RAAllianceManager.selfAlliance.manorResType].name))
    else
        self.mSuperResTpye:setString('---')
    end
end

function RAAllianceManorPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_ManorResType_Change,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_NuclearInfo_Update,OnReceiveMessage)
end

function RAAllianceManorPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_ManorResType_Change,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_NuclearInfo_Update,OnReceiveMessage)
end

--初始化顶部
function RAAllianceManorPage:initTitle()
    -- body
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceManorPageTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

return RAAllianceManorPage.new()