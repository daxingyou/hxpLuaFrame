-- RAWorldMyCollectionPage
-- 自己占领的资源详情页面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire('RARootManager')
local battle_soldier_conf = RARequire('battle_soldier_conf')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')

local RAWorldMyCollectionPage = BaseFunctionPage:new(...)


RAWorldMyCollectionPage.mResId = 0
RAWorldMyCollectionPage.mRemainResNum = 0
RAWorldMyCollectionPage.mMarchId = ''
RAWorldMyCollectionPage.mPlayerName = ''

RAWorldMyCollectionPage.mPos = nil
RAWorldMyCollectionPage.mName = ''
RAWorldMyCollectionPage.mIcon = ''

RAWorldMyCollectionPage.mStartTime = -1
RAWorldMyCollectionPage.mEndTime = -1

-- 当前自己可以采集的数目，min(剩余量, 负重量)
RAWorldMyCollectionPage.mMaxCollectNum = 0
RAWorldMyCollectionPage.mCurrSpeed = 0
RAWorldMyCollectionPage.mShowBaseSpeed = 0
RAWorldMyCollectionPage.mShowAddSpeed = 0
RAWorldMyCollectionPage.mLoadBaseNum = 1
RAWorldMyCollectionPage.mCanLoadNum = 0

local OnReceiveMessage = nil

-- @OccupantWithParam=占领者:{0}
-- @TotalAmountWithParam=总量:{0}
-- @CollectSpeedWithParam=采集速度:{0}/小时
-- @CollectedWithParam=已采集:{0}/{1}

-- @CollectingArmyNumWithParam=采集部队数量:{0}
-- @TotalArmyLoadWithParam=总负重:{0}

-- @CollectLastTime=采集剩余时间:{0}

------ content cell
local RAWorldMyCollectionPopUpCell = 
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
        return 'RAWorldMyCollectionPopUpCell.ccbi'
    end,

    onUnLoad = function(self, cellRoot)
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then            
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')            
        end        
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog('RAWorldMyCollectionPopUpCell:onRefreshContent')
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil and self.mArmyId > 0 then
           -- UIExtend.handleCCBNode(ccbfile)
            local armyConf = battle_soldier_conf[tonumber(self.mArmyId)]
            if armyConf then
                -- local iconPath = 'Resource/Image/SoldierHeadIcon/'
                -- local picName = iconPath..armyConf.icon
                UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', armyConf.icon)
                UIExtend.setStringForLabel(ccbfile,
                    {
                        mArmyNum = tostring(self.mCount),
                        mArmyName = _RALang(armyConf.name)
                    })
            else
                UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
            end
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
    --     RAWorldMyCollectionPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog('MessageDef_World MSG_ArmyChangeSelectedCount')
    --     RAWorldMyCollectionPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_CHECK_ARMY_DETAIL_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAWorldMyCollectionPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldMyCollectionPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldMyCollectionPage:resetData()
    self.mResId = 0
    self.mRemainResNum = 0
    self.mMarchId = ''
    self.mPlayerName = ''
    self.mPos = nil
    self.mName = ''
    self.mIcon = ''

    self.mStartTime = -1
    self.mEndTime = -1
    self.mLastTime = -1

    self.mMaxCollectNum = 0
    self.mCurrSpeed = 0
    self.mShowBaseSpeed = 0
    self.mShowAddSpeed = 0
    self.mLoadBaseNum = 1

    self.mCanLoadNum = 0
end

function RAWorldMyCollectionPage:Enter(data)
    CCLuaLog('RAWorldMyCollectionPage:Enter')    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile('ccbi/RAWorldMyCollectionPopUp.ccbi',RAWorldMyCollectionPage)    

    self.mTroopsListSV = UIExtend.getCCScrollViewFromCCB(ccbfile, 'mTroopsListSV')
    
    UIExtend.setNodeVisible(ccbfile, 'mAddSpeedBtn', true)
    UIExtend.setNodeVisible(ccbfile, 'mAdditionSpeedNum', false)

    if data ~= nil then
        self.mResId = data.resId or 0
        self.mRelation = data.relation or World_pb.NONE
        self.mRemainResNum = data.remainResNum or 0
        self.mPos = RACcp(data.posX, data.posY)
        self.mMarchId = data.marchId or ''
        self.mPlayerName = data.playerName
        self.mIsManorCollect = data.isManorCollect or false
        self.mGuildMineType = data.manorResType or -1
    end
    self:RegisterPacketHandler(HP_pb.WORLD_CHECK_ARMY_DETAIL_S)
    self:registerMessageHandlers()

    self.mTroopsListSV:removeAllCell()
    self:refreshCommonUI()

    self:sendWorldCheckArmyDetail(self.mMarchId)
end

function RAWorldMyCollectionPage:Execute()
    if self.mStartTime ~= -1 and self.mEndTime ~= -1 then
        local lastTime = os.difftime(self.mEndTime, common:getCurTime())
        if self.mLastTime > lastTime then
            self:refreshTimeShow(lastTime)
        end
    end
end

-- 刷新倒计时和已采集
function RAWorldMyCollectionPage:refreshTimeShow(lastTime)
    if lastTime <= 0 then
        self.mLastTime = 0
        -- 没时间的时候，直接关闭UI
        RARootManager.ClosePage('RAWorldMyCollectionPage')
        return
    end
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end  
    -- res collected
    -- past Time * speed
    local curTime = common:getCurTime()
    local pastTime = os.difftime(curTime, self.mStartTime)
    local collectedNum = math.floor(self.mCurrSpeed * pastTime)
    UIExtend.setCCLabelString(ccbfile, 'mCollectedNum', _RALang('@CollectedWithParam', collectedNum))

    -- res remained, normal mine
     if not self.mIsManorCollect then
        local lastResNum = self.mRemainResNum - collectedNum
        UIExtend.setCCLabelString(ccbfile, 'mTotalAmount', _RALang('@TotalAmountWithParam', lastResNum)) 
     end

    --buff last time
    local buffST, buffET = RAMarchDataManager:GetResourceSpeedUpEffectTime()
    local buffLastS = math.floor(buffET / 1000) - curTime
    local tmpStr = ''
    local isAddSpeedShow = false
    if buffLastS > 0 then
        tmpStr = Utilitys.createTimeWithFormat(buffLastS)
        tmpStr = _RALang('@CollectLastTime', tmpStr)
        isAddSpeedShow = true    
    end
    UIExtend.setCCLabelString(ccbfile, 'mCollectionAdditionTime', tmpStr)  
    UIExtend.setNodeVisible(ccbfile, 'mAdditionSpeedNum', isAddSpeedShow)
    self.mLastTime = lastTime
end

-- 只在enter的时候需要刷新
function RAWorldMyCollectionPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    local resName = ''
    local resLv = -1
    local resIcon = ''
    local resType = 0
    local resRemainStr = 0
    if not self.mIsManorCollect then
        local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(self.mResId)
        resName = resShowCfg.resName
        resLv = resCfg.level
        resType = resCfg.resType        
        resIcon = resShowCfg.resTargetIcon
        resRemainStr = tostring(self.mRemainResNum)
    else
        local super_mine_conf = RARequire('super_mine_conf')
        local mineCfg = super_mine_conf[self.mGuildMineType]
        resName = mineCfg.name
        resIcon = mineCfg.icon
        resType = self.mGuildMineType
        resRemainStr = _RALang('@SuperMineRemainResDes')
    end
    --名字刷新
    local name = _RALang(resName)
    if resLv > 0 then
        name = name .. '  '.. _RALang('@ResCollectTargetLevel', resLv)
    end
    self.mName = name
    self.mIcon = resIcon
    UIExtend.setCCLabelString(ccbfile, 'mCollectionName', name)    
    UIExtend.setCCLabelString(ccbfile, 'mCollectionPosLabel', _RALang('@WorldCoordPos', self.mPos.x, self.mPos.y))

    -- 占领者
    UIExtend.setCCLabelString(ccbfile, 'mPlayerName', _RALang('@OccupantWithParam', self.mPlayerName))

    --icon
    UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', resIcon)

    -- res num    mTotalAmount        
    UIExtend.setCCLabelString(ccbfile, 'mTotalAmount', _RALang('@TotalAmountWithParam', resRemainStr)) 

    -- speed         
    local totalSpeed, speedShowBase, timeSpeed = RAMarchDataManager:GetResourceCollectSpeed(resType)
    --速度单位是秒
    self.mCurrSpeed = totalSpeed or 0    
    self.mShowBaseSpeed = speedShowBase or 0
    self.mShowAddSpeed = timeSpeed or 0

    self.mLoadBaseNum = RAWorldConfigManager:GetResBaseLoadNum(resType)
    UIExtend.setCCLabelString(ccbfile, 'mCollectionSpeedNum', _RALang('@CollectSpeedWithParam', speedShowBase * 60))
    UIExtend.setCCLabelString(ccbfile, 'mAdditionSpeedNum', _RALang('@CollectAddSpeedWithParam', timeSpeed * 60))

    -- res collected
    -- init is 0
    UIExtend.setCCLabelString(ccbfile, 'mCollectedNum', _RALang('@CollectedWithParam', 0))

    --buff last time    
    local lastTime = 0
    UIExtend.setCCLabelString(ccbfile, 'mCollectionAdditionTime', '')


    -- army num
    local armyNum = 0
    UIExtend.setCCLabelString(ccbfile, 'mTroopsNum', _RALang('@CollectingArmyNumWithParam', armyNum))    

    -- army load
    local armyLoad = 0
    UIExtend.setCCLabelString(ccbfile, 'mTotalWeight', _RALang('@TotalArmyLoadWithParam', armyLoad))    
end

function RAWorldMyCollectionPage:refreshTimeData(loadNum)
    local remainResNum = self.mRemainResNum or 0
    self.mCanLoadNum = loadNum / self.mLoadBaseNum    
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    -- time init
    -- 设置队列时间            
    local marchData = RAMarchDataManager:GetMarchDataById(self.mMarchId)
    if marchData ~= nil then
        self.mStartTime = marchData:GetResCalcStartTime() / 1000
        self.mEndTime = marchData.resEndTime / 1000
        local lastTime = os.difftime(self.mEndTime, common:getCurTime())
        self:refreshTimeShow(lastTime)
    else
        self.mStartTime = -1
        self.mEndTime = -1
        self.mLastTime = -1
    end
end

-- 服务器回包之后，刷新兵种数据
function RAWorldMyCollectionPage:refreshScrollView(msg)
    local scrollView = self.mTroopsListSV
    if scrollView == nil then return end
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end   
    self.mTroopsListSV:removeAllCell()
    
    local soldierDatas = {}
    local loadNum = 0
    local countNum = 0
    for _,v in ipairs(msg.army) do
        local oneData = {}
        oneData.armyId = v.armyId
        oneData.count = v.count
        table.insert(soldierDatas, oneData)

        local cfg = battle_soldier_conf[oneData.armyId]
        if cfg ~= nil then
            local load = cfg.load or 0
            loadNum = loadNum + load * oneData.count
        end
        countNum = countNum + oneData.count
    end
    UIExtend.setCCLabelString(ccbfile, 'mTroopsNum', _RALang('@CollectingArmyNumWithParam', countNum))    
    UIExtend.setCCLabelString(ccbfile, 'mTotalWeight', _RALang('@TotalArmyLoadWithParam', loadNum))

    self:refreshTimeData(loadNum)

    Utilitys.tableSortByKey(soldierDatas, 'armyId')

    for i=1, #soldierDatas do
        local oneSoldier = soldierDatas[i]
        local ccbDetailCell = CCBFileCell:create()
        local handlerDetail = RAWorldMyCollectionPopUpCell:new(
            {                
                mArmyId = oneSoldier.armyId,
                mCount = oneSoldier.count,   
            })
        handlerDetail.selfCell = ccbDetailCell
        ccbDetailCell:registerFunctionHandler(handlerDetail)
        ccbDetailCell:setCCBFile(handlerDetail:getCCBName())
        scrollView:addCellBack(ccbDetailCell)
    end
    scrollView:orderCCBFileCells()    
end

-- 请求军队信息
function RAWorldMyCollectionPage:sendWorldCheckArmyDetail(marchId)
    local RANetUtil = RARequire('RANetUtil')
    local cmd = World_pb.WorldCheckArmyDetailReq()
    -- marchId = ''
    cmd.marchId = tostring(marchId) or ''
    RARootManager.ShowWaitingPage(false)
    RANetUtil:sendPacket(HP_pb.WORLD_CHECK_ARMY_DETAIL_C,cmd,{retOpcode=-1})
end

function RAWorldMyCollectionPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.WORLD_CHECK_ARMY_DETAIL_S then
        local msg = World_pb.WorldCheckArmyDetailResp()
        msg:ParseFromString(buffer)
        if msg then
            self:refreshScrollView(msg)            
        end
        RARootManager.RemoveWaitingPage()
    end
end


function RAWorldMyCollectionPage:CommonRefresh(data)
    CCLuaLog('RAWorldMyCollectionPage:CommonRefresh')        
    if self.mTroopsListSV == nil then return end
    -- 使用道具增加采集速度后刷新
    self.mTroopsListSV:removeAllCell()
    self:refreshCommonUI()
    self:sendWorldCheckArmyDetail(self.mMarchId)
end


function RAWorldMyCollectionPage:onClose()
    CCLuaLog('RAWorldMyCollectionPage:onClose') 
    RARootManager.ClosePage('RAWorldMyCollectionPage')
end


function RAWorldMyCollectionPage:onAddSpeedBtn()
    CCLuaLog('RAWorldMyCollectionPage:onAddSpeedBtn') 
    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.resCollectSpeedUp)
end

function RAWorldMyCollectionPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAWorldMyCollectionPage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog('RAWorldMyCollectionPage:Exit')    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self.mTroopsListSV:removeAllCell()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end