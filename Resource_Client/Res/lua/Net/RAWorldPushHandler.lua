--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAWorldPushHandler = {}

local HP_pb = RARequire('HP_pb')
local World_pb = RARequire('World_pb')
local RANetUtil = RARequire('RANetUtil')

function RAWorldPushHandler:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    if pbCode == HP_pb.WORLD_PLAYER_WORLD_INFO_PUSH then
		local msg = World_pb.WorldInfoPush()
		msg:ParseFromString(buffer)
        self:_onSyncWorldPos(msg) 
        return
    end

    if pbCode == HP_pb.WORLD_FAVORITE_SYNC_S then
        local msg = World_pb.HPWorldFavoriteSync()
        msg:ParseFromString(buffer)
        self:_onSyncFavorites(msg)
        return
    end

    if pbCode == HP_pb.WORLD_MOVE_CITY_S then
        local msg = World_pb.WorldMoveCityResp()
        msg:ParseFromString(buffer)
        self:_onMigrateRsp(msg)
        return
    end

    -------------------------------------------------
    -- march pb push in world (other players)
    -- if pbCode == HP_pb.WORLD_MARCH_BLOCK_ADD then
    --     local msg = World_pb.PushMarchAddInfo()
    --     msg:ParseFromString(buffer)        
    --     self:_onMarchBlockAdd(msg)
    --     return
    -- end
    
    -- if pbCode == HP_pb.WORLD_MARCH_BLOCK_UPDATE then
    --     local msg = World_pb.WorldMarchPB()
    --     msg:ParseFromString(buffer)
    --     self:_onMarchBlockUpdate(msg)
    --     return
    -- end

    -- if pbCode == HP_pb.WORLD_MARCH_BLOCK_DELETE then
    --     local msg = World_pb.WorldMarchDeletePush()
    --     msg:ParseFromString(buffer)
    --     self:_onMarchBlockDelete(msg)
    --     return
    -- end
    -- end

    -- new 
    if pbCode == HP_pb.WORLD_MARCH_EVENT_SYNC then
        local msg = World_pb.MarchEventSync()
        msg:ParseFromString(buffer)       
        local RAMarchDataManager = RARequire('RAMarchDataManager') 
        -- 整块视野同步，需要找出老数据中无效的行军并删除
        if msg.eventType == World_pb.MARCH_SYNC then
            RAMarchDataManager:CheckMarchesAndRemoveDiffSet(msg)
            for _,v in ipairs(msg.marchData) do
                -- v = MarchData = {marchId, marchPB}
                if v.marchPB ~= nil and v.marchPB.relation ~= World_pb.SELF then
                    RAMarchDataManager:AddMarchData(v.marchPB)
                end
            end
        -- 视野内行军的增加
        elseif msg.eventType == World_pb.MARCH_ADD then
            for _,v in ipairs(msg.marchData) do
                -- v = MarchData = {marchId, marchPB}
                if v.marchPB ~= nil and v.marchPB.relation ~= World_pb.SELF then
                    --判断如果有这个数据在的话，就直接更新
                    RAMarchDataManager:AddMarchData(v.marchPB)
                end
            end
        -- 视野内行军的更新            
        elseif msg.eventType == World_pb.MARCH_UPDATE then
            for _,v in ipairs(msg.marchData) do
                -- v = MarchData = {marchId, marchPB}
                if v.marchPB ~= nil then
                    self:_onMarchBlockUpdate(v.marchPB)
                end
            end
        -- 视野内行军的删除
        elseif msg.eventType == World_pb.MARCH_DELETE then
            for _,v in ipairs(msg.marchData) do
                -- v = MarchData = {marchId, marchPB}
                RAMarchDataManager:RemoveMarchDataById(v.marchId, true)
            end
        end
        return
    end

    -----------------------------------------------------------------------------------------------------
    -- march pb push for self

    -- 登陆时自己和参与的行军数据推送
    if pbCode == HP_pb.WORLD_MARCHS_PUSH then
        local msg = World_pb.WorldMarchLoginPush()
        msg:ParseFromString(buffer)
        self:_onMarchInitPush(msg)
        return
    end

    -- add　推送
    if pbCode == HP_pb.WORLD_MARCH_ADD_PUSH then
        local msg = World_pb.WorldMarchPB()
        msg:ParseFromString(buffer)
        self:_onMarchAddPush(msg)
        return
    end

    -- update
    if pbCode == HP_pb.WORLD_MARCH_UPDATE_PUSH then
        local msg = World_pb.WorldMarchPB()
        msg:ParseFromString(buffer)
        self:_onMarchUpdatePush(msg)
        return
    end

    -- delete
    if pbCode == HP_pb.WORLD_MARCH_DELETE_PUSH then
        local msg = World_pb.WorldMarchDeletePush()
        msg:ParseFromString(buffer)
        self:_onMarchDeletePush(msg)
        --行军部队回来后刷新城内的集合地
        MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
        return
    end
    -- end
    --------------------------------------------------------------------------------------------------------
    --三级地图数据推送相关
    if pbCode == HP_pb.OPEN_KING_DISTRIBUTE_MAP_S then
        local RAWorldMapThreeManager = RARequire("RAWorldMapThreeManager")
        local msg = World_pb.WorldKingDistributeMapRes()
        msg:ParseFromString(buffer)
        RAWorldMapThreeManager:onRecieveKingdomData(msg.worldKingDistributeMap)
        return
    end

    --三级地图数据推送相关
    if pbCode == HP_pb.WORLD_PLAYER_WORLD_BEATING_PUSH then
        
        local msg = World_pb.WorldBeatingWarning()
        msg:ParseFromString(buffer)
        local RARootManager = RARequire('RARootManager')
        RARootManager.isShowWarning = msg.isWarning
        -- RARootManager.isShowWarning = true
        MessageManager.sendMessage(MessageDef_MainUI.MSG_Update_Warning)
        return
    end
    -- end
    --------------------------------------------------------------------------------------------------------
    ----------发起行军、行军加速、召回、遣返等等，暂时逻辑上没有用到返回消息-------------
    --[[
    if pbCode == HP_pb.WORLD_MARCH_SPEEDUP_S then
        local msg = World_pb.WorldMarchSpeedUpResp()
        msg:ParseFromString(buffer)
        self:_onMarchSpeedUpResp(msg)
        return
    end

    -- 服务器计算，召回行军
    if pbCode == HP_pb.WORLD_SERVER_CALLBACK_S then
        local msg = World_pb.WorldMarchClientCallBackResp()
        msg:ParseFromString(buffer)
        self:_onServerCalcCallBackMarchRsp(msg)
        return
    end

    -- 遣返行军
    if pbCode == HP_pb.WORLD_MASS_REPATRIATE_S then
        local msg = World_pb.WorldMassRepatriateResp()
        msg:ParseFromString(buffer)
        self:_onMassRepatriateResp(msg)
        return
    end
    --]]
    -- end
    ----------------------------------------------------------

    ----------------------------------------------------------
    -- region: president
    if pbCode == HP_pb.PRESIDENT_INFO_SYNC then
        local President_pb = RARequire('President_pb')
        local msg = President_pb.PresidentInfoSync()
        msg:ParseFromString(buffer)
        
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:Sync(msg.info)
        
        return
    end

    -- 国王战驻军信息，全量
    -- 领地驻军请求返回数据
    -- 发射井驻军请求返回数据
    if pbCode == HP_pb.PUSH_ALL_QUARTERED_MARCHS then
        local GuildWar_pb = RARequire('GuildWar_pb')
        local msg = GuildWar_pb.PushAllQuarteredMarch()
        msg:ParseFromString(buffer)
        
        if msg.pushType == GuildWar_pb.PUSH_QUARTERED_PRESIDENT then
            local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
            RAPresidentMarchDataHelper:InitTeamData(msg)        
        end

        if msg.pushType == GuildWar_pb.PUSH_QUARTERED_MANOR then
            -- 领地数据推送成功
            MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAAllianceBaseWarInfoPage', msg = msg})            
        end
        if msg.pushType == GuildWar_pb.PUSH_QUARTERED_BUILDING then
            -- 发射井驻军数据推送成功
            MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAAllianceSiloPlatformQuarterPage', msg = msg})
        end
        return
    end

    -- 国王战驻军信息，删除
    if pbCode == HP_pb.PUSH_DEL_QUARTERED_MARCHS then
        local GuildWar_pb = RARequire('GuildWar_pb')
        local msg = GuildWar_pb.PushQuarteredMarchDelItem()
        msg:ParseFromString(buffer)
        
        local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
        RAPresidentMarchDataHelper:DeleteTeamItemData(msg)      
        return
    end

    -- 国王战驻军信息，更新
    if pbCode == HP_pb.PUSH_UPDATE_QUARTERED_MARCHS then
        local GuildWar_pb = RARequire('GuildWar_pb')
        local msg = GuildWar_pb.PushQuarteredMarchUpdateItem()
        msg:ParseFromString(buffer)
        
        local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
        RAPresidentMarchDataHelper:UpdateTeamItemData(msg)       
        return
    end

    -- 国王战购买集结队列
    if pbCode == HP_pb.PUSH_UPDATE_QUARTERED_MARCHS_BUY_ITEM then
        local GuildWar_pb = RARequire('GuildWar_pb')
        local msg = GuildWar_pb.PushQuarteredMarchBuyItems()
        msg:ParseFromString(buffer)
        
        local RAPresidentMarchDataHelper = RARequire('RAPresidentMarchDataHelper')
        RAPresidentMarchDataHelper:UpdateBuyTimes(msg)
        return
    end

    -- 历代国王信息
	if pbCode == HP_pb.PRESIDENT_HISTORY_SYNC then
        local President_pb = RARequire('President_pb')
        local msg = President_pb.PresidentHistorySync()
        msg:ParseFromString(buffer)
        
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:SyncPresidentsHistory(msg)       
        return
    end

    -- 国王战事件同步
	if pbCode == HP_pb.PRESIDENT_EVENT_SYNC then
        local President_pb = RARequire('President_pb')
        local msg = President_pb.PresidentEventSync()
        msg:ParseFromString(buffer)
        
        local RAPresidentDataManager = RARequire('RAPresidentDataManager')
        RAPresidentDataManager:SyncEventsHistory(msg)       
        return
    end

    -- 联盟堡垒页面需要请求新数据的推送
    if pbCode == HP_pb.PUSH_MANOR_INFO_CHANGED then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAAllianceBaseWarPage'})
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAAllianceBaseWarInfoPage', isRequest = true})            
    end

    -- endregion: president
    ----------------------------------------------------------
end

function RAWorldPushHandler:_onSyncWorldPos(msg)
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    RAPlayerInfoManager.setWorldPos(msg.targetX, msg.targetY)
    local RASDKLoginConfig = RARequire('RASDKLoginConfig')
    local serverId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.SERVER_ID, RASDKLoginConfig.DEF_SERVER_ID)
    RAPlayerInfoManager.setKingdomId(serverId)

    local RAWorldVar = RARequire('RAWorldVar')
    RAWorldVar:Init()

    if msg:HasField('isRecreate') and msg.isRecreate then
        RAPlayerInfoManager.setCityRecreated(true)
        MessageManager.sendMessage(MessageDef_World.MSG_CityRecreated)
    end
end

function RAWorldPushHandler:_onSyncFavorites(msg)
    local RAUserFavoriteManager = RARequire('RAUserFavoriteManager')
    for _, favPB in ipairs(msg.favorites) do
        RAUserFavoriteManager:addFavorite(favPB)
    end
    MessageManager.sendMessage(MessageDef_World.MSG_UpdateFavorite)
end

function RAWorldPushHandler:_onMigrateRsp(msg)
    local RAWorldManager = RARequire('RAWorldManager')
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

    local pos = nil
    if msg:HasField('x') and msg:HasField('y') then
        RAPlayerInfoManager.setWorldPos(msg.x, msg.y)
        pos = RACcp(msg.x, msg.y)
    end

    if msg:HasField('serverInfo') then
        local RAWorldVar = RARequire('RAWorldVar')
        local oldK = RAWorldVar.KingdomId.Self
        local k = RAPlayerInfoManager.setKingdomId(msg.serverInfo.serverId)
        if oldK ~= k then
            local ip, port = msg.serverInfo.serverIp, msg.serverInfo.serverPort

            local RANetManager = RARequire('RANetManager')
            RANetManager:reconnect(ip, port)

            local RASDKLoginConfig = RARequire('RASDKLoginConfig')
            CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.SERVER_ID, msg.serverInfo.serverId)
            CCUserDefault:sharedUserDefault():setStringForKey(RASDKLoginConfig.SERVER_IP, ip)
            CCUserDefault:sharedUserDefault():setIntegerForKey(RASDKLoginConfig.SERVER_PORT, port)
            CCUserDefault:sharedUserDefault():flush()
            
            RAWorldVar:UpdateSelfKingdomId(k)

            local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
            RAWorldProtoHandler:sendEnterSignal(RAWorldVar.MapPos.Map)
        end
    end

    RAWorldManager:onMigrateRsp(msg.result, pos)
end

local isClientDelMarhc = false

-- 后端虚拟格子的Add MSG:PushMarchAddInfo
function RAWorldPushHandler:_onMarchBlockAdd(msg)
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    -- 如果是换块数据推送，判断是否需要干掉一些

    if msg.operation == World_pb.AMOUNT_ADD then
        local timeDebug = CCTime:getCurrentTime()
        print('need to clean march data,time:'.. tostring(timeDebug)..'   need to remove march count:'..tostring(#msg.removeMarchs))
        if isClientDelMarhc then
            RAMarchDataManager:CheckAndCleanMarchsOut()        
        else
            for _, removeId in ipairs(msg.removeMarchs) do    
                local marchData = RAMarchDataManager:GetMarchDataById(removeId)
                print('RAWorldPushHandler:_onMarchBlockAdd  want to remove march id = '.. removeId)
                if marchData ~= nil and marchData.relation == World_pb.SELF then
                    print("RAWorldPushHandler:_onMarchBlockAdd  want to remove one march that relation is self")
                else
                    RAMarchDataManager:RemoveMarchDataById(removeId, true)
                end
            end
        end
        local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
        print('run RAMarchDataManager:RemoveMarchDataById, spend time:'.. tostring(calcTimeSpend))
    end
    local timeDebug1 = CCTime:getCurrentTime()
    print('need to add march data,time:'.. tostring(timeDebug1)..'   need to add march  count:'..tostring(#msg.marchs))    
    for _,v in ipairs(msg.marchs) do
        -- v = march pb
        if v.relation ~= World_pb.SELF then
            --判断如果有这个数据在的话，就直接更新
            RAMarchDataManager:AddMarchData(v)
        end
    end
    local calcTimeSpend1 = CCTime:getCurrentTime() - timeDebug1
    print('run RAWorldPushHandler:_onMarchBlockAdd one time, spend time:'.. tostring(calcTimeSpend1))    
end


-- 后端虚拟格子的update  MSG:WorldMarchPB
function RAWorldPushHandler:_onMarchBlockUpdate(msg)
    local RAMarchDataManager = RARequire('RAMarchDataManager') 
    -- msg = march pb
    if msg.relation ~= World_pb.SELF then
        RAMarchDataManager:UpdateMarchData(msg)       
    end
end



-- 后端虚拟格子的del MSG:WorldMarchDeletePush
function RAWorldPushHandler:_onMarchBlockDelete(msg)
    local RAMarchDataManager = RARequire('RAMarchDataManager')    
    print(' RAWorldPushHandler:_onMarchBlockDelete  need to remove march id:'..tostring(msg.marchId))    
    local timeDebug = CCTime:getCurrentTime()
    RAMarchDataManager:RemoveMarchDataById(msg.marchId, true)
    local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
    print('run RAWorldPushHandler:_onMarchBlockDelete, spend time:'.. tostring(calcTimeSpend))
end


-- 登陆广播
function RAWorldPushHandler:_onMarchInitPush(msg)
    local RAMarchDataManager = RARequire('RAMarchDataManager')    
    for _,v in ipairs(msg.marchs) do        
        RAMarchDataManager:AddMarchData(v, true)
    end
end

function RAWorldPushHandler:_onMarchAddPush(msg)
    local RAMarchManager = RARequire('RAMarchManager')
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local marchData = RAMarchDataManager:AddMarchData(msg, true)   
end

function RAWorldPushHandler:_onMarchUpdatePush(msg)
    local RAMarchManager = RARequire('RAMarchManager')
    local RAMarchDataManager = RARequire('RAMarchDataManager')    
    local marchData = RAMarchDataManager:UpdateMarchData(msg)
end

function RAWorldPushHandler:_onMarchDeletePush(msg)
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    -- local relation = msg.relation
    RAMarchDataManager:RemoveMarchDataById(msg.marchId, false)
end




-------------------------发起行军、行军加速、召回、遣返等等------------------------
-- send march pb
function RAWorldPushHandler:sendWorldMarchReq(marchType, targetCoord, armyList, params)
    local RAMarchConfig = RARequire('RAMarchConfig')
    local RAWorldMath = RARequire('RAWorldMath')
    local Utilitys = RARequire('Utilitys')

    local hpTb = RAMarchConfig.MarchType2HpCode[marchType]
    if hpTb ~= nil then
        local c2s = hpTb.c2s
        if type(c2s) == 'number' then
            local coord, isOK = Utilitys.checkIsPoint(targetCoord)
            if isOK then
                -- local pos = RAWorldMath:Map2View(coord)
                local msg = World_pb.WorldMarchReq()
                msg.posX = coord.x
                msg.posY = coord.y

                --如果x或y为0 则对方城点不存在 add by phan
                if coord.x <= 0 or coord.x <= 0 then
                    local RARootManager = RARequire('RARootManager')
                    RARootManager.ShowMsgBox(_RALang('@CoordPointNotExistent'))
                    return
                end
                    
                if armyList ~= nil then
                    for armyId, count in pairs(armyList) do
                        if count > 0 then
                            local armyInfo = msg.armyInfo:add()
                            armyInfo.armyId = armyId
                            armyInfo.count = count
                        end
                    end
                end
                if marchType == World_pb.ATTACK_MONSTER or
                    marchType == World_pb.MONSTER_MASS then                    
                    msg.attackModel = 0
                    if params ~= nil then
                        msg.attackModel = params.times or 0
                    end
                end

                local RAWorldUtil = RARequire('RAWorldUtil')
                if RAWorldUtil:IsMassingMarch(marchType) then                    
                    msg.massTime = 0
                    if params ~= nil then
                        msg.massTime = params.gatherTime or 0
                    end
                end
                if RAWorldUtil:IsJoiningMassMarch(marchType) then                    
                    msg.marchId = ''
                    if params ~= nil then
                        msg.marchId = params.massTargetMarchId or 0
                    end
                end

                if  marchType == World_pb.ASSISTANCE_RES then
                    if params~=nil then
                        local assistant= params.assistant
                        for itemId,v in pairs(assistant) do
                            local rewardItem = msg.assistant:add()
                            rewardItem.itemId = itemId
                            rewardItem.itemType = v.itemType
                            rewardItem.itemCount = v.itemCount
                        end
                    end                    
                end 

                -- 在一些特殊情况，比如联盟堡垒相关行军上，后端会用到这个字段
                msg.type = marchType

                RANetUtil:sendPacket(c2s, msg, {retOpcode = -1})            
            else
                error('RAWorldPushHandler:sendWorldMarchReq  targetCoord error')        
            end
        else
            error('RAWorldPushHandler:sendWorldMarchReq  marchType = '..marchType..' error!')    
        end
    else
        error('RAWorldPushHandler:sendWorldMarchReq  marchType = '..marchType..' error!')
    end
end


-- 行军加速
function RAWorldPushHandler:sendMarchSpeedUpReq(marchId, itemId)
    local msg = World_pb.WorldMarchSpeedUpReq()
    msg.marchId = marchId
    msg.itemId = itemId
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local marchData = RAMarchDataManager:GetMarchDataById(removeId)    
    if marchData ~= nil then
        msg.status = marchData.marchStatus
    end
    RANetUtil:sendPacket(HP_pb.WORLD_MARCH_SPEEDUP_C, msg)
end

-- 行军加速返回
function RAWorldPushHandler:_onMarchSpeedUpResp(msg)
    --msg.result
    local result = msg.result
    print("RAWorldPushHandler:_onMarchSpeedUpResp  result="..tostring(result))
    -- local RARootManager = RARequire('RARootManager')
    -- if success then
    --     RARootManager:CloseAllPages()
    -- end
    -- RARootManager.RemoveWaitingPage()
end

-- 服务器计算召回
function RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
    local msg = World_pb.WorldMarchServerCallBackReq()
    msg.marchId = marchId
    RANetUtil:sendPacket(HP_pb.WORLD_SERVER_CALLBACK_C, msg)
end

-- 行军召回返回
function RAWorldPushHandler:_onServerCalcCallBackMarchRsp(msg)
    --msg.result
    local result = msg.result
    print("RAWorldPushHandler:_onServerCalcCallBackMarchRsp  result="..tostring(result))
    -- local RARootManager = RARequire('RARootManager')
    -- if success then
    --     RARootManager:CloseAllPages()
    -- end
    -- RARootManager.RemoveWaitingPage()
end


-- 队长遣返一个行军
function RAWorldPushHandler:sendMassRepatriateReq(marchId)
    local msg = World_pb.WorldMassRepatriateReq()
    msg.marchId = marchId
    RANetUtil:sendPacket(HP_pb.WORLD_MASS_REPATRIATE_C, msg)
end

-- 队长遣返结果
function RAWorldPushHandler:_onMassRepatriateResp(msg)
    --msg.result
    --WorldMassRepatriateResp
    local result = msg.result
    print("RAWorldPushHandler:_onMassRepatriateResp  result="..tostring(result))
    -- local RARootManager = RARequire('RARootManager')
    -- if success then
    --     RARootManager:CloseAllPages()
    -- end
    -- RARootManager.RemoveWaitingPage()
end


-- 队长解散一个集结
function RAWorldPushHandler:sendMassDissolveReq(marchId)
    local msg = World_pb.WorldMassDissolveReq()
    msg.marchId = marchId
    RANetUtil:sendPacket(HP_pb.WORLD_MASS_DISSOLVE_C, msg)
end


---------------------------------------------------------------------------

return RAWorldPushHandler

--endregion