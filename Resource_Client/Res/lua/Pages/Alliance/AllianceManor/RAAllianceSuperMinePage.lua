-- RAAllianceSuperMinePage  qinho
-- 联盟超级矿页面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire('RARootManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local World_pb = RARequire('World_pb')

local RAAllianceSuperMinePage = BaseFunctionPage:new(...)


local OnReceiveMessage = nil

------ content cell
local RAAllianceSuperMineCell = 
{
    mCount = 0,
    mArmyId = -1,
    
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    resetData = function(self)        
        self.mArmyId = -1
        self.mCount = 0
    end,

    getCCBName = function(self)
        return 'RAAllianceSuperMineCell.ccbi'
    end,

    onUnLoad = function(self, cellRoot)
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then            
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mFrameIconNode')            
        end        
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog('RAAllianceSuperMineCell:onRefreshContent')
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then
        	local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            local iconStr = RAPlayerInfoManager.getHeadIcon(self.playerIcon)
            UIExtend.addSpriteToNodeParent(ccbfile, 'mFrameIconNode', iconStr)
            UIExtend.setStringForLabel(ccbfile,
                {
                    mCollectedNum = _RALang('@CollectedWithParam', self.collectNum),
                    mPlayerName = self.playerName
                })
        end
    end,


    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
    end
}


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog('MessageDef_World MSG_ArmyFreeCountUpdate')
    --     RAAllianceSuperMinePage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog('MessageDef_World MSG_ArmyChangeSelectedCount')
    --     RAAllianceSuperMinePage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.GET_GUILD_SUPER_MINE_MARCHS_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAAllianceSuperMinePage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAAllianceSuperMinePage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAAllianceSuperMinePage:resetData()

end


function RAAllianceSuperMinePage:Enter(data)
    CCLuaLog('RAAllianceSuperMinePage:Enter')    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile('ccbi/RAAllianceSuperMinePopUp.ccbi', self)    

    self.mList = UIExtend.getCCScrollViewFromCCB(ccbfile, 'mListSV')
    UIExtend.setNodeVisible(ccbfile, 'mListEmptyLabel', false)

    if data ~= nil then
        self.mGuildMineType = data.guildMineType or 0
        self.mPointX = data.pointX or 0
        self.mPointY = data.pointY or 0
    end

    self:registerMessageHandlers()
    self:RegisterPacketHandler(HP_pb.GET_GUILD_SUPER_MINE_MARCHS_S)

    self.mList:removeAllCell()
    self:RefreshCommonUI()

    self:SendMineDetailReq()
end

-- 只在enter的时候需要刷新
function RAAllianceSuperMinePage:RefreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    local super_mine_conf = RARequire('super_mine_conf')
    local mineCfg = super_mine_conf[self.mGuildMineType]
    local name = _RALang(mineCfg.name)    
    self.mName = name
    UIExtend.setCCLabelString(ccbfile, 'mMineName', name)

    local icon = mineCfg.icon
    self.mIcon = icon
    UIExtend.setSpriteImage(ccbfile, {mSuperMinePic = icon})

    UIExtend.setCCLabelString(ccbfile, 'mTitle', _RALang('@AllianceSuperMineTitle'))
    UIExtend.setCCLabelString(ccbfile, 'mExplainLabel', _RALang('@AllianceSuperMineExplain'))

    local btnStr = '@DoCollect'
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local isSelfIn = RAMarchDataManager:CheckSelfSuperMineCollectStatus(true)
    if isSelfIn then
        btnStr = '@CollectionInfo'
    end
    UIExtend.setControlButtonTitle(ccbfile, 'mCollectionBtn', btnStr)
end

function RAAllianceSuperMinePage:onCollectionBtn()
    print('RAAllianceSuperMinePage:onCollectionBtn')
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local isSelfIn, marchId = RAMarchDataManager:CheckSelfSuperMineCollectStatus(true)
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    if isSelfIn then
        --打开采集详情页面        
        local selfName = RAPlayerInfoManager.getPlayerName()
        local pageData = {
                    resId = 0, 
                    relation = World_pb.SELF,
                    remainResNum = -1,      --超级矿显示——无限
                    posX = self.mPointX,
                    posY = self.mPointY,
                    playerName = selfName,    -- get self name
                    marchId = marchId,
                    isManorCollect = true,
                    manorResType = self.mGuildMineType,  --新增资源类型
                }        
        RARootManager.OpenPage('RAWorldMyCollectionPage', pageData, true, true, true)
    else
    	local isSelfCollect = RAMarchDataManager:CheckSelfSuperMineCollectStatus()
    	if isSelfCollect then
    		--提示已经在采集中
        	RARootManager.ShowMsgBox(_RALang('@AllianceSuperMineCollectingTip'))
    	else
            --检查玩家自己是否可以采集了（资源类型和大本等级关系）
            local isCanCollect, cityLevel = RAPlayerInfoManager.getSelfIsOpenResByType(self.mGuildMineType)
            if isCanCollect then
                self:onClose()
        		--打开出征页面
        		RARootManager.OpenPage('RATroopChargePage',  {
    	            coord = RACcp(self.mPointX, self.mPointY), 
    	            name = self.mName,
    	            icon = self.mIcon,        
    	            marchType = World_pb.MANOR_COLLECT,
    	        })
            else
                local RAResManager = RARequire('RAResManager')
                local _, name = RAResManager:getResourceIconByType(self.mGuildMineType)
                RARootManager.ShowMsgBox('@NotAllowedToCollect', cityLevel, _RALang(name))
            end
    	end
    end
end


function RAAllianceSuperMinePage:onReplaceBtn()
	print('RAAllianceSuperMinePage:onReplaceBtn')
	--打开切换资源类型页面
    local RAAllianceManager = RARequire('RAAllianceManager')
    local isAble = RAAllianceManager:isAbleToChangeSuperMineRes()
    if isAble then
        self:onClose()
        RARootManager.OpenPage('RAAllianceSuperMineSelPage', {
            guildMineType = self.mGuildMineType,
            posX = self.mPointX,
            posY = self.mPointY,
            })
    else
        --权限不足
        local Status_pb = RARequire("Status_pb")
        RARootManager.showErrorCode(Status_pb.GUILD_LOW_AUTHORITY)
    end
end


-- 服务器回包之后，刷新兵种数据
function RAAllianceSuperMinePage:refreshScrollView(msg)
    local scrollView = self.mList
    if scrollView == nil then return end
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end   
    self.mList:removeAllCell()
    
    local playerDatas = {}
    local loadNum = 0
    local countNum = 0
    local isShowLabel = true
    for _,v in ipairs(msg.showData) do
        local oneData = {}
        oneData.marchId = v.marchId
        oneData.playerName = v.playerName
        oneData.playerIcon = v.playerIcon
        oneData.collectNum = v.collectNum
        table.insert(playerDatas, oneData)
        isShowLabel = false
    end

    -- Utilitys.tableSortByKey(playerDatas, 'armyId')
    UIExtend.setNodeVisible(ccbfile, 'mListEmptyLabel', isShowLabel)
    for i=1, #playerDatas do
        local oneData = playerDatas[i]
        local ccbDetailCell = CCBFileCell:create()
        local handlerDetail = RAAllianceSuperMineCell:new(
            {                
                playerName = oneData.playerName,
                playerIcon = oneData.playerIcon,   
                collectNum = oneData.collectNum
            })
        handlerDetail.selfCell = ccbDetailCell
        ccbDetailCell:registerFunctionHandler(handlerDetail)
        ccbDetailCell:setCCBFile(handlerDetail:getCCBName())
        scrollView:addCellBack(ccbDetailCell)
    end
    scrollView:orderCCBFileCells()    
end

-- 请求信息
function RAAllianceSuperMinePage:SendMineDetailReq()
    local RANetUtil = RARequire('RANetUtil')
    local cmd = World_pb.GetSuperMineMarchsReq()
    cmd.x = self.mPointX
    cmd.y = self.mPointY
    local errorStr = 'RAAllianceSuperMinePage:SendMineDetailReq waiting page close Error'
    RARootManager.ShowWaitingPage(false, 10, errorStr)
    RANetUtil:sendPacket(HP_pb.GET_GUILD_SUPER_MINE_MARCHS_C,cmd,{retOpcode=-1})
end

function RAAllianceSuperMinePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GET_GUILD_SUPER_MINE_MARCHS_S then
        local msg = World_pb.GetSuperMineMarchsResp()
        msg:ParseFromString(buffer)
        if msg then
            self:refreshScrollView(msg)            
        end
        RARootManager.RemoveWaitingPage()
    end
end


function RAAllianceSuperMinePage:CommonRefresh(data)
    CCLuaLog('RAAllianceSuperMinePage:CommonRefresh')        
    if self.mList == nil then return end
    -- 使用道具增加采集速度后刷新
    self.mList:removeAllCell()
    self:RefreshCommonUI()
    self:SendMineDetailReq()
end


function RAAllianceSuperMinePage:onClose()
    CCLuaLog('RAAllianceSuperMinePage:onClose') 
    RARootManager.ClosePage('RAAllianceSuperMinePage')
end


function RAAllianceSuperMinePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAAllianceSuperMinePage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog('RAAllianceSuperMinePage:Exit')    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self.mList:removeAllCell()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end