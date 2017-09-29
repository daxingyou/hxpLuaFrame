-- RAAlliancePassivePage
-- 联盟医院、巨炮页面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire('RARootManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldVar = RARequire('RAWorldVar')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local territory_building_conf = RARequire('territory_building_conf')

local RAAlliancePassivePage = BaseFunctionPage:new(...)



--默认是医院
-- Const_pb.GUILD_CANNON
RAAlliancePassivePage.mBuildType = Const_pb.GUILD_HOSPITAL
RAAlliancePassivePage.mBuildId = 0



local OnReceiveMessage = function(message)     

    -- if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
    --     local opcode = message.opcode
    --     if opcode == HP_pb.CHANGE_SUPER_MINE_TYPE_C then
    --         RARootManager.RemoveWaitingPage()
    --         RAAlliancePassivePage:RefreshCommonUI()
    --     end
    -- end

    -- if message.messageID == MessageDef_Packet.MSG_Operation_OK then        
    --     local opcode = message.opcode
    --     if opcode == HP_pb.CHANGE_SUPER_MINE_TYPE_C then
    --         RARootManager.RemoveWaitingPage()
    --         RAAlliancePassivePage:onClose()
    --     end
    -- end
end

function RAAlliancePassivePage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAAlliancePassivePage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAAlliancePassivePage:resetData()    
    self.mBuildType = Const_pb.GUILD_HOSPITAL
    self.mManorId = 0
    self.mBuildId = 0
    self.mPointX = 0
    self.mPointY = 0
    self.mExplainLabel = nil
end


function RAAlliancePassivePage:Enter(data)
    CCLuaLog('RAAlliancePassivePage:Enter')    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile('ccbi/RAAlliancePassivePopUp.ccbi', self)    


    if data ~= nil then
        self.mBuildType = data.buildType or Const_pb.GUILD_HOSPITAL
        self.mBuildId = data.buildId or 0
        self.mPointX = data.pointX or 0
        self.mPointY = data.pointY or 0
        self.mManorId = data.manorId or 0
    end

    self:registerMessageHandlers()
    -- self:RegisterPacketHandler(HP_pb.GET_GUILD_SUPER_MINE_MARCHS_S)
    self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(ccbfile,"mExplainLabel")
    self.mExplainLabelStarP = ccp(self.mExplainLabel:getPosition())
    self:RefreshCommonUI()
end

-- 只在enter的时候需要刷新
function RAAlliancePassivePage:RefreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    local btnMap = {}
    local buildCfg = territory_building_conf[self.mBuildId]
    if buildCfg == nil then return end
    local iconStr = buildCfg.icon
    local buildName = buildCfg.name    

    UIExtend.setCCLabelString(ccbfile, 'mTitle', _RALang(buildName))
    UIExtend.setSpriteImage(ccbfile, {mPassivePic = iconStr})

    UIExtend.setNodesVisible(ccbfile, {
        mHospitalLabelNode = false,
        mBombardLabelNode = false,
        })

    local RAAllianceUtility = RARequire('RAAllianceUtility')
    local isActive = RAAllianceUtility:isActiveManor(self.mManorId)    
    local color = ccc3(169, 169, 169)
    local valueStrKey = '@CannonOrHospitalNotUsing'
    if isActive then
        color = ccc3(81, 215, 67)
        valueStrKey = '@CannonOrHospitalUsing'
    end
    UIExtend.setColorForLabel(ccbfile,
    {
        mPassiveLabel1 = color,
        mPassiveLabel2 = color,
        mPassiveLabel3 = color,
        mPassiveLabel4 = color,
        mPassiveLabel5 = color,
        mPassiveLabel6 = color,
    })
    local territory_building_conf = RARequire('territory_building_conf')
    --医院
    if self.mBuildType == Const_pb.GUILD_HOSPITAL then
        UIExtend.setCCLabelString(ccbfile, 'mExplainLabel', _RALang('@RAAllianceHospitalExplain'))
        --两个作用号显示：419 420
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel1', _RALang('@RAAllianceHospitalEffectName1'))
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel3', _RALang('@RAAllianceHospitalEffectName2'))
        --作用显示：
        local value1 = buildCfg.hospitalRate1 * 100 / 10000
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel2', _RALang(valueStrKey, value1)) 
        local value2 = buildCfg.hospitalRate2 * 100 / 10000
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel4', _RALang(valueStrKey, value2)) 


        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel1')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildHospitalDes1'))

        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel2')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildHospitalDes2'))

        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel3')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildHospitalDes3'))

        UIExtend.setNodeVisible(ccbfile, 'mHospitalLabelNode', true)
        UIExtend.setNodeVisible(ccbfile, 'mBombardLabelNode', false)
    end

    --巨炮
    if self.mBuildType == Const_pb.GUILD_CANNON then
        UIExtend.setCCLabelString(ccbfile, 'mExplainLabel', _RALang('@RAAllianceCannonExplain'))
        --个数显示
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel5', _RALang('@RAAllianceCannonNumDes'))
        --按照领地取当前巨炮个数
        local RATerritoryDataManager = RARequire('RATerritoryDataManager')
        local cannonNum = 0
        local manorData =  RATerritoryDataManager:GetTerritoryById(self.mManorId)
        if manorData ~= nil then
            cannonNum = manorData.cannonCount
        end
        UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel6', tostring(cannonNum))

        --作用显示  jira 5010
        --UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel3', _RALang('@RAAllianceCannonEffectName1'))

        -- local value = 1
        local guild_const_conf = RARequire('guild_const_conf')
        local value = buildCfg.cannonRate

        --jira 5010
        --local totalValue = value * cannonNum * 100 / 10000
        --UIExtend.setCCLabelString(ccbfile, 'mPassiveLabel4', _RALang(valueStrKey, totalValue))

        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel1')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildCannorDes1'))

        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel2')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildCannorDes2'))

        local htmlLabel1 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mDetailsLabel3')
        htmlLabel1:setString(RAStringUtil:getHTMLString('@GuildCannorDes3'))
        
        UIExtend.setNodeVisible(ccbfile, 'mBombardLabelNode', true)
        UIExtend.setNodeVisible(ccbfile, 'mHospitalLabelNode', false)
    end
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mPassiveLabel5', 'mPassiveLabel6', 3)

    --jira 5010
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mPassiveLabel1', 'mPassiveLabel2', 3)

    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mPassiveLabel3', 'mPassiveLabel4', 3)

    UIExtend.createLabelAction(ccbfile, "mExplainLabel")
end

-- -- 请求信息
-- function RAAlliancePassivePage:SendMineSelectReq()
--     local RANetUtil = RARequire('RANetUtil')
--     local cmd = World_pb.ChangeSuperMineTypeReq()    
--     cmd.x = self.mPointX
--     cmd.y = self.mPointY
--     cmd.resType = self.mCurrSelectType
--     local errorStr = 'RAAllianceSuperMinePage:SendMineSelectReq waiting page close Error'
--     RARootManager.ShowWaitingPage(false, 10, errorStr)
--     RANetUtil:sendPacket(HP_pb.CHANGE_SUPER_MINE_TYPE_C,cmd,{retOpcode=-1})
-- end

-- function RAAlliancePassivePage:onReceivePacket(handler)
--     local pbCode = handler:getOpcode()
--     local buffer = handler:getBuffer()
--     if pbCode == HP_pb.CHANGE_SUPER_MINE_TYPE_S then
--         local msg = World_pb.WorldCheckArmyDetailResp()
--         msg:ParseFromString(buffer)
--         if msg then
--             self:refreshScrollView(msg)            
--         end
--         RARootManager.RemoveWaitingPage()
--     end
-- end


function RAAlliancePassivePage:CommonRefresh(data)
    CCLuaLog('RAAlliancePassivePage:CommonRefresh')        
    self:RefreshCommonUI()
    -- self:SendMineSelectReq(self.mMarchId)
end


function RAAlliancePassivePage:onClose()
    CCLuaLog('RAAlliancePassivePage:onClose') 
    RARootManager.ClosePage('RAAlliancePassivePage')
end


function RAAlliancePassivePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAAlliancePassivePage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog('RAAlliancePassivePage:Exit')    
    -- self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    if self.mExplainLabel ~= nil then
        self.mExplainLabel:stopAllActions()
        self.mExplainLabel:setPosition(self.mExplainLabelStarP)
    end
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end