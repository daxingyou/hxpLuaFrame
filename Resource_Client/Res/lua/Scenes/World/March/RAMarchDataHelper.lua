-- RAMarchDataHelper
local World_pb = RARequire('World_pb')


local RAMarchDataHelper = {}

local RAMarchData = {    
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self
        self:ResetData()
        return o
    end,

    ResetData = function(self)
        self.marchId = ''
        self.playerId = ''
        self.playerName = ''
        self.origionX = -1
        self.origionY = -1

        self.terminalX = -1
        self.terminalY = -1

        -- 毫秒
        self.startTime = 0
        self.endTime = 0

        self.marchJourneyTime = 0

        self.marchType = -1
        self.marchStatus = -1

        self.armyTypes = {}

        self.relation = -1
        self.targetId = ''
        self.guildTag = ''

        self.itemUseX = 0
        self.itemUseY = 0
        self.itemUseTime = 0
        self.speedTimes = 0

        self.callBackX = 0
        self.callBackY = 0
        self.callBackTime = 0

        self.resStartTime = 0
        self.resEndTime = 0

        self.resSpeedUpdateCount = 0
        self.resSpeedUpdateTime = 0

        self.massReadyTime = 0

        ------------------------------- client ----------------------
        -- default value -1
        -- battle begin 1
        -- battle end 0
        self.mBattleStatus = -1

        -- when call back, set value = true
        self.mLastUpdateStatus = -1
    end,

    InitByPb = function(self, msg)        
        self.marchId = msg.marchId
        self.playerId = msg.playerId
        self.playerName = msg.playerName
        self.origionX = msg.origionX
        self.origionY = msg.origionY

        self.terminalX = msg.terminalX
        self.terminalY = msg.terminalY

        self.startTime = msg.startTime
        self.endTime = msg.endTime

        self.marchJourneyTime = msg.marchJourneyTime

        self.marchType = msg.marchType
        self.marchStatus = msg.marchStatus

        self.armyTypes = {}
        for _, itemType in ipairs(msg.armyTypes) do
            table.insert(self.armyTypes, itemType)
        end

        self.relation = msg.relation
        self.targetId = msg.targetId
        self.guildTag = msg.guildTag or ''

        self.itemUseX = msg.itemUseX or 0
        self.itemUseY = msg.itemUseY or 0
        self.itemUseTime = msg.itemUseTime or 0
        self.speedTimes = msg.speedTimes or 0        

        self.callBackX = msg.callBackX or 0
        self.callBackY = msg.callBackY or 0
        self.callBackTime = msg.callBackTime or 0

        self.resStartTime = msg.resStartTime or 0
        self.resEndTime = msg.resEndTime or 0

        self.resSpeedUpdateCount = msg.resSpeedUpdateCount or 0
        self.resSpeedUpdateTime = msg.resSpeedUpdateTime or 0

        self.massReadyTime = msg.massReadyTime or 0
    end,

    -- 更新数据，暂时和初始化数据一样
    UpdateByPb = function(self, msg)
        self:InitByPb(msg)
    end,

    GetLastTime = function(self)
        local common = RARequire('common')
        local curTime = common:getCurTime()
        local remainTime =os.difftime(self.endTime / 1000,curTime)
        return remainTime
    end,

    GetPastTime = function(self)
        local common = RARequire('common')
        local curTime = common:getCurTime()
        local pastTime =os.difftime(curTime, self.startTime / 1000)
        return pastTime
    end,

    --计算显示距离时的起点时间
    GetCalcDisStartTime = function(self)
        if self.itemUseTime >= self.startTime then
            return self.itemUseTime
        end
        return self.startTime
    end,

    -- 计算显示距离时的起始点
    -- 会额外返回一个计算的类型；0为初始值；1为道具加速；2为召回点
    GetCalcDisStartPos = function(self)
        if self.callBackTime > 0 then
            --召回的行军，起始点优先级：道具加速点 > 召回点 > 起点
            if self.itemUseTime >= self.startTime then            
                return RACcp(self.itemUseX, self.itemUseY), 1
            else
                return RACcp(self.callBackX, self.callBackY), 2
            end
        else
            if self.itemUseTime >= self.startTime then            
                return RACcp(self.itemUseX, self.itemUseY), 1
            end
        end
        return RACcp(self.origionX, self.origionY), 0
    end,

    GetStartCoord = function(self)
        local coord = {x = self.origionX, y = self.origionY}
        return coord
    end,

    GetEndCoord = function(self)
        local coord = {x = self.terminalX, y = self.terminalY}
        return coord
    end,

    GetArmyTypes = function(self)
       local list = {}
       local isHasTank = false
       for k,v in pairs(self.armyTypes) do
            table.insert(list, v)            
       end
       table.sort(list)

       -- tank、soldier、v3、plane : 2、1、3、4    
       if #list >= 2 then
            local Const_pb = RARequire('Const_pb')
            if list[1] == Const_pb.FOOT_SOLDIER and list[2] == Const_pb.TANK_SOLDIER then
                list[1] = Const_pb.TANK_SOLDIER
                list[2] = Const_pb.FOOT_SOLDIER
            end
       end
       return list
    end,

    GetBattleStatus = function(self)
        return self.mBattleStatus
    end,

    SetBattleStatus =function(self, value)
        if value then
            -- 正在战斗
            self.mBattleStatus = 1
        else
            -- 战斗结束
            self.mBattleStatus = 0
        end
    end,

    SetLastUpdateStatus = function(self, value)
        self.mLastUpdateStatus = value
    end,
    GetLastUpdateStatus = function(self)
        return self.mLastUpdateStatus
    end,

    -- 获取资源采集计算的开始时间
    GetResCalcStartTime = function(self)
        if self.resSpeedUpdateTime > 0 then
            return self.resSpeedUpdateTime
        end
        return self.resStartTime
    end,

    Release = function(self)
        self:ResetData()
    end
}



-- 根据proto创建一个 march data
function RAMarchDataHelper:CreateMarchData(msg)
    local data = RAMarchData:New()
    data:InitByPb(msg)
    return data
end

return RAMarchDataHelper