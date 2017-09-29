--TO:联盟战争 集结加入页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local Const_pb = RARequire("Const_pb")
local HP_pb = RARequire('HP_pb')
local const_conf = RARequire("const_conf")
local world_march_const_conf = RARequire("world_march_const_conf")
local Utilitys = RARequire("Utilitys")
local common = RARequire("common")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local World_pb = RARequire("World_pb")
local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
local RANewAllianceWarDetailsCellHelper = RARequire('RANewAllianceWarDetailsCellHelper')
local RAGameConfig = RARequire("RAGameConfig")

local RANewAllianceWarDetailsPage = BaseFunctionPage:new(...)


local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh then
        local cellMarchId = message.cellMarchId
        if RANewAllianceWarDetailsPage.cellMarchId == cellMarchId then
            RANewAllianceWarDetailsPage:CommonRefresh(false)
        end
    elseif message.messageID == MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_CellInfo_Change then
        local cellMarchId = message.cellMarchId
        local showData = message.showData
        RANewAllianceWarDetailsPage:ChangeCellInfoStatus(cellMarchId, showData)

    elseif message.messageID == MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Close then
        local cellMarchId = message.cellMarchId
        if RANewAllianceWarDetailsPage.cellMarchId == cellMarchId then
            RARootManager.ClosePage('RANewAllianceWarDetailsPage')
        end       

    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        local opcode = message.opcode          
        if opcode == HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_C then
            RARootManager.RemoveWaitingPage()            
        end
        if opcode == HP_pb.WORLD_MASS_DISSOLVE_C then
            RARootManager.RemoveWaitingPage()            
        end
    end
end

function RANewAllianceWarDetailsPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Close, OnReceiveMessage)    
    MessageManager.registerMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_CellInfo_Change, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RANewAllianceWarDetailsPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Close, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_CellInfo_Change, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RANewAllianceWarDetailsPage:Enter(data)
    self.index = data.index
    self.cellMarchId = data.cellMarchId

	local ccbfile = UIExtend.loadCCBFile("RAAllianceWarGatherPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mInviteListSV")

    --TOP
    -- self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    -- -- self.mDiamondsNode:setVisible(false)
    -- self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    -- local titleName = _RALang("@AllianceWarWarGatherTitle")
    -- UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)

    -- title
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end
    local titleName = _RALang("@AllianceWarWarGatherTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RANewAllianceWarDetailsPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
    

    -- 用于记录哪个cell点开了部队详情
    -- 存放show data的player id
    self.mOpenItemMap = {}

    --刷新页面
    self:CommonRefresh(true)

    self:registerMessageHandlers()
    self:RegisterPacketHandler(HP_pb.WORLD_MASS_DISSOLVE_S)
    self:RegisterPacketHandler(HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_S)

    self.mLastUpdateTime = 0
end


--点击左边放大镜
function RANewAllianceWarDetailsPage:onJumpMyPosBtn()
    -- 默认自己，有行军就显示行军起点（往往也是自己）
    local RAWorldVar = RARequire('RAWorldVar')
    local coord = RAWorldVar.MapPos.Self
    local selfInfo = self.mCellData.selfInfo
    if selfInfo ~= nil then
        coord = RACcp(selfInfo.x, selfInfo.y)
    end
    local RAWorldManager = RARequire("RAWorldManager")
    RARootManager.CloseAllPages()
    RAWorldManager:LocateAt(coord.x, coord.y)
end

--点击左边放大镜
function RANewAllianceWarDetailsPage:onJumpEnemyPosBtn()
    local singleData = self.mCellData.targetInfo
    if singleData ~= nil then
        local RAWorldManager = RARequire("RAWorldManager")
        RARootManager.CloseAllPages()
        RAWorldManager:LocateAt(singleData.x, singleData.y)
    end
end


--队长解散一个集结
function RANewAllianceWarDetailsPage:onStateBtn()
    local RAWorldPushHandler = RARequire("RAWorldPushHandler")
    RAWorldPushHandler:sendMassDissolveReq(self.mCellData.cellMarchId)
end

function RANewAllianceWarDetailsPage:mAllianceCommonCCB_onBack()
    RARootManager.ClosePage('RANewAllianceWarDetailsPage')
end


function RANewAllianceWarDetailsPage:mAllianceCommonCCB_onDiamondesCCB()
    local Recharge_pb = RARequire('Recharge_pb')
    local RANetUtil = RARequire("RANetUtil")
    local msg = Recharge_pb.FetchRechargeInfo()
    RANetUtil:sendPacket(HP_pb.FETCH_RECHARGE_INFO, msg)
end


function RANewAllianceWarDetailsPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()    
    -- 解散集结
    if opcode == HP_pb.WORLD_MASS_DISSOLVE_S then
        local msg = World_pb.WorldMassDissolveResp()
        msg:ParseFromString(buffer)
        local result = msg.result
        if result then
             RARootManager.ClosePage('RANewAllianceWarDetailsPage')
        end
        RARootManager.RemoveWaitingPage()
        return
    end
    -- 购买一个新队列的返回
    if opcode == HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_S then
        local msg = World_pb.WorldMassMarchBuyExtraItemsResp()
        msg:ParseFromString(buffer)
        local result = msg.result
        
        return
    end
end

function RANewAllianceWarDetailsPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RANewAllianceWarDetailsPage")
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end
function RANewAllianceWarDetailsPage:Execute()
    local currTime = CCTime:getCurrentTime()
    if currTime - self.mLastUpdateTime < 300 then
        return
    end
    self.mLastUpdateTime = currTime
    self:updateTime()
end


function RANewAllianceWarDetailsPage:_BuildItemCellInfoOpenData(isReset)
    if self.mCellData == nil then return end
    if isReset then
        self.mOpenItemMap = {}    
    end
    local leaderShowData = self.mCellData.selfInfo.leaderMarch
    if self.mOpenItemMap[leaderShowData.playerId] == nil then 
        self.mOpenItemMap[leaderShowData.playerId] = false    
    end
    local joinMarches = self.mCellData.selfInfo.joinMarchs    
    for k,v in pairs(joinMarches) do
        if self.mOpenItemMap[v.playerId] == nil then
            self.mOpenItemMap[v.playerId] = false
        end
    end
end

function RANewAllianceWarDetailsPage:CommonRefresh(isReset)
    isReset = isReset or false
    self.mCellData = RANewAllianceWarManager:GetOneCellDataById(self.cellMarchId)
    if self.mCellData == nil then return end
    self:_BuildItemCellInfoOpenData(isReset)
    self:refreshCommonUI()
    self:updateTime()    
    self:refreshScrollView()
end

function RANewAllianceWarDetailsPage:refreshCommonUI()
    local ccbfile = self.ccbfile
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

    local currArmyCount = selfInfo:GetJoinedArmyCount()
    local limitCount = selfInfo.leaderArmyLimit
    local keyStr = '@AggregationUpperHint'
    if self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
        keyStr = '@AssistanceUpperHint'
    end
    UIExtend.setStringForLabel(ccbfile, {mGatherTroopsNum = _RALang(keyStr,currArmyCount ,limitCount)})
end

function RANewAllianceWarDetailsPage:updateTime()
    local ccbfile = self.ccbfile
	if self.mCellData ~= nil then
        if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS or
            self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
            --集结标签，驻扎标签使用同样的逻辑
            local leaderShowData = self.mCellData.selfInfo.leaderMarch
            local marchData = leaderShowData.marchData
            if marchData == nil then return end
            local statusStr = ""
            local lastTime = 0
            local isBtnVisible = true
            if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then   -- 集结等待状态
                statusStr = _RALang("@OurTroopsAssemblyIn")
                local startTime = marchData.massReadyTime / 1000
                local endTime = marchData.startTime / 1000
                lastTime = os.difftime(endTime, common:getCurTime())
            elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then  --出征中
                statusStr = _RALang("@OurTroopsInRun")
                local startTime = marchData.startTime / 1000
                local endTime = marchData.endTime / 1000
                lastTime = os.difftime(endTime, common:getCurTime())    
                isBtnVisible = false
            end
            local timeStr = Utilitys.createTimeWithFormat(lastTime)
            statusStr = statusStr..timeStr
            UIExtend.setStringForLabel(ccbfile, {mWarStateLabel = statusStr})
            UIExtend.setColorForLabel(ccbfile, {mWarStateLabel = RAGameConfig.COLOR.WHITE})

            if isBtnVisible then
                isBtnVisible = leaderShowData.playerId == RAPlayerInfoManager.getPlayerId()
            end
            UIExtend.setNodesVisible(ccbfile,{mStateBtn = isBtnVisible})

        elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
            --攻击标签
            --不会点进来
        elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
            --防守标签
            --时间显示
            local singleData = self.mCellData.targetInfo
            local statusStr = ""
            local lastTime = os.difftime(singleData.endTime / 1000, common:getCurTime())  
            local isBtnVisible = false
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
        -- elseif self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
        --     --驻扎标签

        end                
    end
end

function RANewAllianceWarDetailsPage:ChangeCellInfoStatus(cellMarchId, showData)
    if self.cellMarchId == cellMarchId then
        local oldStatus = self.mOpenItemMap[showData.playerId]
        self.mOpenItemMap[showData.playerId] = not oldStatus
        self:refreshScrollView()
    end
end


-- RANewAllianceWarDetailsCellHelper:CreateJoinedCell(index, cellMarchId, itemShowData)
-- RANewAllianceWarDetailsCellHelper:CreateSpareCell(index, cellMarchId, isLock)

function RANewAllianceWarDetailsPage:refreshScrollView()
    if self.mCellData ~= nil then
        local openItemMap = self.mOpenItemMap        
        self.scrollView:removeAllCell()
        local scrollView = self.scrollView

        local checkAndCreateCellInfo = function(cellMarchId, showData)
            local status = openItemMap[showData.playerId] or false
            local cell = nil
            local cellHandler = nil
            if status then
                cellHandler = RANewAllianceWarDetailsCellHelper:CreateArmyInfoCell(
                    index, cellMarchId, showData)
                cell = CCBFileCell:create()            
                cell:registerFunctionHandler(cellHandler)
                cell:setIsScheduleUpdate(true)
                cell:setCCBFile(cellHandler:GetCCBName())
                scrollView:addCellBack(cell)
            end
            return status, cell
        end

        -- 集结驻扎和集结出兵都一样的
        if self.mCellData.showType == GuildWar_pb.GUILD_WAR_MASS
            or self.mCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
            --先创建队长
            local cellIndex = 1    
            local itemCount = 0
            local status = openItemMap[self.mCellData.selfInfo.leaderMarch.playerId] or false
            local leaderCellHandler = RANewAllianceWarDetailsCellHelper:CreateJoinedCell(
                cellIndex,  self.mCellData.cellMarchId, self.mCellData.selfInfo.leaderMarch, status)
            local leaderCell = CCBFileCell:create()            
            leaderCell:registerFunctionHandler(leaderCellHandler)
            leaderCell:setIsScheduleUpdate(true)
            leaderCell:setCCBFile(leaderCellHandler:GetCCBName())
            scrollView:addCellBack(leaderCell)
            itemCount = itemCount + 1
            local leaderCellInfoStatus, leaderCellInfoCell = checkAndCreateCellInfo(
                self.mCellData.cellMarchId, self.mCellData.selfInfo.leaderMarch)
            if leaderCellInfoStatus then cellIndex = cellIndex + 1 end

            --创建队员
            local joinMarches = self.mCellData.selfInfo.joinMarchs
            local sortedMarchIdList = self.mCellData.selfInfo:GetSortedJoinedMarhIdList()
            for i=1, #sortedMarchIdList do                
                local oneIdData = sortedMarchIdList[i]
                local v = joinMarches[oneIdData.marchId]
                if v ~= nil then
                    cellIndex = cellIndex + 1
                    local status = openItemMap[v.playerId] or false
                    local itemCellHandler = RANewAllianceWarDetailsCellHelper:CreateJoinedCell(
                        cellIndex, self.mCellData.cellMarchId, v, status)
                    local itemCell = CCBFileCell:create()            
                    itemCell:registerFunctionHandler(itemCellHandler)
                    itemCell:setIsScheduleUpdate(true)
                    itemCell:setCCBFile(itemCellHandler:GetCCBName())
                    scrollView:addCellBack(itemCell)

                    itemCount = itemCount + 1

                    local itemCellInfoStatus, itemCellInfoCell = checkAndCreateCellInfo(
                        self.mCellData.cellMarchId, v)
                    if itemCellInfoStatus then cellIndex = cellIndex + 1 end
                end
            end

            -- 集结发车后，不显示空闲和购买位置了
            local leaderMarch = self.mCellData.selfInfo.leaderMarch
            if leaderMarch ~= nil and leaderMarch.marchData ~= nil then
                if leaderMarch.marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                    --创建剩余的空闲位置
                    local baseMassNum = RANewAllianceWarManager:GetPlayerBaseMassItemCount()
                    local spareNum = baseMassNum - itemCount + self.mCellData.selfInfo.buyItemTimes
                    if spareNum > 0 then                
                        for i=1,spareNum do
                            cellIndex = cellIndex + 1
                            local spareCellHandler = RANewAllianceWarDetailsCellHelper:CreateSpareCell(
                                cellIndex, self.mCellData.cellMarchId, false)
                            local spareCell = CCBFileCell:create()            
                            spareCell:registerFunctionHandler(spareCellHandler)
                            spareCell:setCCBFile(spareCellHandler:GetCCBName())
                            scrollView:addCellBack(spareCell)
                        end
                    end

                    --创建购买位置            
                    local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(self.mCellData.selfInfo.buyItemTimes)
                    if isCanBuy then
                        local lockCellHandler = RANewAllianceWarDetailsCellHelper:CreateSpareCell(
                                    cellIndex, self.mCellData.cellMarchId, true)
                        local lockCell = CCBFileCell:create()            
                        lockCell:registerFunctionHandler(lockCellHandler)
                        lockCell:setCCBFile(lockCellHandler:GetCCBName())
                        scrollView:addCellBack(lockCell)
                    end
                end
            end

            scrollView:orderCCBFileCells()
        end

        if self.mCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
            --创建援助人
            local joinMarches = self.mCellData.selfInfo.joinMarchs
            local sortedMarchIdList = self.mCellData.selfInfo:GetSortedJoinedMarhIdList()
            local cellIndex = 0 
            for i=1, #sortedMarchIdList do                
                local oneIdData = sortedMarchIdList[i]
                local v = joinMarches[oneIdData.marchId]
                if v ~= nil then
                    cellIndex = cellIndex + 1
                    local itemCellHandler = RANewAllianceWarDetailsCellHelper:CreateJoinedCell(
                        cellIndex, self.mCellData.cellMarchId, v)
                    local itemCell = CCBFileCell:create()            
                    itemCell:registerFunctionHandler(itemCellHandler)
                    itemCell:setIsScheduleUpdate(true)
                    itemCell:setCCBFile(itemCellHandler:GetCCBName())
                    scrollView:addCellBack(itemCell)

                    local itemCellInfoStatus, itemCellInfoCell = checkAndCreateCellInfo(
                        self.mCellData.cellMarchId, v)
                    if itemCellInfoStatus then cellIndex = cellIndex + 1 end
                end
            end

            --创建空闲点击位置
            cellIndex = cellIndex + 1
            local spareCellHandler = RANewAllianceWarDetailsCellHelper:CreateSpareCell(
                cellIndex, self.mCellData.cellMarchId, false)
            local spareCell = CCBFileCell:create()            
            spareCell:registerFunctionHandler(spareCellHandler)
            spareCell:setCCBFile(spareCellHandler:GetCCBName())
            scrollView:addCellBack(spareCell)

            scrollView:orderCCBFileCells()
        end
    end
end


return RANewAllianceWarDetailsPage
