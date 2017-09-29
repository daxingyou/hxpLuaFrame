-- RATerritoryManager
-- 处理炸弹相关逻辑

local RATerritoryManager = {
    mRootNode = nil, 
    mUILayer = nil, 

    mBombEntityMap = {}
}

local RAWorldMath = RARequire('RAWorldMath')
local RATerritoryDataManager = RARequire('RATerritoryDataManager')




local OnReceiveMessage = function(message)    
    CCLuaLog("RATerritoryManager OnReceiveMessage id:"..message.messageID)
    -- if message.messageID == MessageDef_World.MSG_MarchDelete then
    --     CCLuaLog("MessageDef_World MSG_MarchDelete")
    --     local marchId = message.marchId
    --     RATerritoryManager:RemoveMarchDisplayById(marchId)
    -- end
    -- if message.messageID == MessageDef_World.MSG_MarchBeginBattle then
    --     CCLuaLog("MessageDef_World MSG_MarchBeginBattle")
    --     local marchId = message.marchId
    --     RATerritoryManager:_RecordMarchBeginBattle(marchId)
    -- end

    -- if message.messageID == MessageDef_World.MSG_MarchEndBattle then
    --     CCLuaLog("MessageDef_World MSG_MarchEndBattle")
    --     local marchId = message.marchId
    --     RATerritoryManager:_RecordMarchEndBattle(marchId)
    -- end
end

function RATerritoryManager:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchDelete, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchBeginBattle, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchEndBattle, OnReceiveMessage)
end

function RATerritoryManager:unregisterMessageHandlers()    
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchDelete, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchBeginBattle, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchEndBattle, OnReceiveMessage)
end


-- 城外初始化的时候调用
function RATerritoryManager:Init(rootNode, uiLayer)
    self.mRootNode = rootNode
    self.mUILayer = uiLayer
    self.mBombEntityMap = {}
    self:registerMessageHandlers()

    self:ShowAllBombs()

    -- 创建一个客户端的核弹
    -- RATerritoryDataManager:AddBombByClientForShow()
end


-- 在城外的时候会调用
function RATerritoryManager:Execute()
    if self.mBombEntityMap ~= nil then
        for id, entity in pairs(self.mBombEntityMap) do
            if entity ~= nil then
                entity:Execute()
            end
        end
    end
end

-- 退出城外的时候调用，需要清除显示对象缓存
function RATerritoryManager:Clear() 
    self:unregisterMessageHandlers()
    
    for id, entity in pairs(self.mBombEntityMap) do
        if entity ~= nil then
            entity:Release()
        end
    end
    self.mBombEntityMap = {}

    -- 去除指针
    self.mRootNode = nil
    self.mUILayer = nil
end


function RATerritoryManager:ShowAllBombs()
    local allBombs = RATerritoryDataManager:GetAllBombsData()
    for id,bombData in pairs(allBombs) do
        self:ShowBombAreaByData(bombData)
    end
end


-- 根据一个核弹数据，显示一块被轰炸区域
function RATerritoryManager:ShowBombAreaByData(bombData)
    if bombData == nil then return end
    if self.mRootNode == nil then return end

    local bombId = bombData.bombId
    local entity = self.mBombEntityMap[bombId]
    if entity ~= nil then
        --如果已经存在，直接return不做处理
        -- 目前版本不存在需要刷新已经创建了的核弹显示规则的需求
        return
    end
    if entity == nil then
        local RABombEntityHelper = RARequire('RABombEntityHelper')
        entity = {}
        entity = RABombEntityHelper:CreateBombEntity(bombId)
        if entity ~= nil then            
            entity:UpdateByBombData(bombId)
            self.mBombEntityMap[bombId] = entity 
        end
    else
        print('TODO: if need update……')
    end
end


function RATerritoryManager:RemoveBombAreaByBombId(bombId, isClearData)
    local isClearData = isClearData or false
    local entity = self.mBombEntityMap[bombId]
    if entity ~= nil then
        entity:Release()        
    end
    self.mBombEntityMap[bombId] = nil

    if isClearData then
        print('TODO: RemoveBombAreaByBombId:clear data')
    end

    -- -- 强制客户端自己的核弹去重新创建
    -- if bombId == 'what_the_bomb_fk' then
    --     -- 尝试添加个客户端的核弹
    --     RATerritoryDataManager:AddBombByClientForShow(true)
    -- end    
end

function RATerritoryManager:GetUILayer()
    return self.mUILayer or nil
end
function RATerritoryManager:GetGroundLayer()
    return self.mRootNode or nil
end

return RATerritoryManager