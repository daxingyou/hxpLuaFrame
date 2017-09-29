-- RAAllianceSuperMineSelPage  qinho
-- 联盟超级矿选择资源类型的页面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire('RARootManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local super_mine_conf = RARequire('super_mine_conf')

local RAAllianceSuperMineSelPage = BaseFunctionPage:new(...)

--当前超级矿类型
RAAllianceSuperMineSelPage.mGuildMineType = 0
-- 当前选中的类型
RAAllianceSuperMineSelPage.mCurrSelectType = 0

local SuperMineIndex2Type = 
{
    [1] = Const_pb.GOLDORE,
    [2] = Const_pb.OIL,
    [3] = Const_pb.STEEL,
    [4] = Const_pb.TOMBARTHITE,
}

local OnReceiveMessage = nil


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog('MessageDef_World MSG_ArmyFreeCountUpdate')
    --     RAAllianceSuperMineSelPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog('MessageDef_World MSG_ArmyChangeSelectedCount')
    --     RAAllianceSuperMineSelPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.CHANGE_SUPER_MINE_TYPE_C then
            RARootManager.RemoveWaitingPage()
            RAAllianceSuperMineSelPage:RefreshCommonUI()
        end
    end

    if message.messageID == MessageDef_Packet.MSG_Operation_OK then        
        local opcode = message.opcode
        if opcode == HP_pb.CHANGE_SUPER_MINE_TYPE_C then
            RARootManager.RemoveWaitingPage()
            RAAllianceSuperMineSelPage:onClose()
        end
    end
end

function RAAllianceSuperMineSelPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAAllianceSuperMineSelPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAAllianceSuperMineSelPage:resetData()
    self.mGuildMineType = 0
    self.mCurrSelectType = 0
    self.mPointX = 0
    self.mPointY = 0
end


function RAAllianceSuperMineSelPage:Enter(data)
    CCLuaLog('RAAllianceSuperMineSelPage:Enter')    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile('ccbi/RAAllianceSuperMineSelPopUp.ccbi', self)    


    if data ~= nil then
        self.mGuildMineType = data.guildMineType or 0
        self.mPointX = data.posX or 0
        self.mPointY = data.posY or 0
    end

    self:registerMessageHandlers()
    -- self:RegisterPacketHandler(HP_pb.GET_GUILD_SUPER_MINE_MARCHS_S)

    self:RefreshCommonUI()
end

-- 只在enter的时候需要刷新
function RAAllianceSuperMineSelPage:RefreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    local btnMap = {}
    for index, resType in pairs(SuperMineIndex2Type) do
        local mineCfg = super_mine_conf[resType]
        if mineCfg ~= nil then
            local iconNodeName = 'mIconNode'..index
            local usingNodeName = 'mUsingNode'..index
            local btnName = 'mFrameBtn'..index
            UIExtend.setNodeVisible(ccbfile, usingNodeName, resType == self.mGuildMineType)
            UIExtend.setCCControlButtonEnable(ccbfile, btnName, resType ~= self.mGuildMineType)

            UIExtend.removeSpriteFromNodeParent(ccbfile, iconNodeName)
            UIExtend.addSpriteToNodeParent(ccbfile, iconNodeName, mineCfg.icon)
            btnMap[btnName] = false
        end
    end
    UIExtend.setControlButtonSelected(ccbfile, btnMap)
    UIExtend.setCCLabelString(ccbfile, 'mTitle', _RALang('@AllianceChangeSuperMineTitle'))
end

function RAAllianceSuperMineSelPage:_HandleSelect(index)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end  
    local resType = SuperMineIndex2Type[index]
    if resType == self.mGuildMineType then
        --选中的和当前的矿类型一致
        RARootManager.ShowMsgBox(_RALang('@SelectIsSameWithCurrMineType'))
        return
    end
    local btnMap = {}
    for i, typeValue in pairs(SuperMineIndex2Type) do
        local mineCfg = super_mine_conf[typeValue]
        if mineCfg ~= nil then
            local btnName = 'mFrameBtn'..i
            btnMap[btnName] = (index == i)
        end
    end    
    UIExtend.setControlButtonSelected(ccbfile, btnMap)
    self.mCurrSelectType = resType
end

function RAAllianceSuperMineSelPage:onFrameBtn1()
    print('RAAllianceSuperMineSelPage:onFrameBtn1')
    self:_HandleSelect(1)
end

function RAAllianceSuperMineSelPage:onFrameBtn2()
    print('RAAllianceSuperMineSelPage:onFrameBtn2')
    self:_HandleSelect(2)
end

function RAAllianceSuperMineSelPage:onFrameBtn3()
    print('RAAllianceSuperMineSelPage:onFrameBtn3')
    self:_HandleSelect(3)
end

function RAAllianceSuperMineSelPage:onFrameBtn4()
    print('RAAllianceSuperMineSelPage:onFrameBtn4')
    self:_HandleSelect(4)
end


function RAAllianceSuperMineSelPage:onReplaceBtn()
	print('RAAllianceSuperMineSelPage:onReplaceBtn')
	--发送协议
    if self.mGuildMineType == self.mCurrSelectType then
        --选中的和当前的矿类型一致
        RARootManager.ShowMsgBox(_RALang('@SelectIsSameWithCurrMineType'))
        self:RefreshCommonUI()
        return
    end
    if 0 == self.mCurrSelectType then
        --还没有选中矿
        RARootManager.ShowMsgBox(_RALang('@SelectMineTypeIsNull'))
        return
    end

    self:SendMineSelectReq()
end


-- 请求信息
function RAAllianceSuperMineSelPage:SendMineSelectReq()
    local RANetUtil = RARequire('RANetUtil')
    local cmd = World_pb.ChangeSuperMineTypeReq()    
    cmd.x = self.mPointX
    cmd.y = self.mPointY
    cmd.resType = self.mCurrSelectType
    local errorStr = 'RAAllianceSuperMinePage:SendMineSelectReq waiting page close Error'
    RARootManager.ShowWaitingPage(false, 10, errorStr)
    RANetUtil:sendPacket(HP_pb.CHANGE_SUPER_MINE_TYPE_C,cmd,{retOpcode=-1})
end

-- function RAAllianceSuperMineSelPage:onReceivePacket(handler)
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


function RAAllianceSuperMineSelPage:CommonRefresh(data)
    CCLuaLog('RAAllianceSuperMineSelPage:CommonRefresh')        
    self:RefreshCommonUI()
    -- self:SendMineSelectReq(self.mMarchId)
end


function RAAllianceSuperMineSelPage:onClose()
    CCLuaLog('RAAllianceSuperMineSelPage:onClose') 
    RARootManager.ClosePage('RAAllianceSuperMineSelPage')
end


function RAAllianceSuperMineSelPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAAllianceSuperMineSelPage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog('RAAllianceSuperMineSelPage:Exit')    
    -- self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end