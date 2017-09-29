
RAQueueData = {}

--构造函数
function RAQueueData:new(o)
    o = o or {}
    o.id = nil              --队列id
    o.queueType = nil       --队列类型
    o.itemId = nil          --建筑的创建和升级就放建筑id;科技升级就放科技的id
    o.startTime = nil       --开始时间
    o.endTime = nil         --结束时间
    o.info = nil            --额外数据 --造兵队列为兵营类型
    o.status = nil          --防御建筑的两种状态，升级或者修理
    o.helpTimes = 0         --0代表没申请过帮助  
    o.totalQueueTime = 0    --队列初始总时长
    o.totalReduceTime = 0   --队列加速
    o.totalQueueTime2 = 0   --队列初始总时长,毫秒
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAQueueData:initByPb(queuePB)
    self.id = queuePB.id
    self.queueType = queuePB.queueType
    self.itemId = queuePB.itemId
    self.startTime = math.floor(queuePB.startTime/1000) --服务器是毫秒
    self.endTime = math.floor(queuePB.endTime /1000)
    self.startTime2 = queuePB.startTime --服务器是毫秒
    self.endTime2 = queuePB.endTime
    self.totalQueueTime = math.floor(queuePB.totalQueueTime/1000)
    self.totalReduceTime = math.floor(queuePB.totalReduceTime/1000)
    self.totalQueueTime2 = queuePB.totalQueueTime           --毫秒
    if queuePB:HasField('info') then 
        self.info = queuePB.info
    end 

    if queuePB:HasField('status') then 
        self.status = queuePB.status
    end

    if queuePB:HasField('helpTimes') then 
        self.helpTimes = queuePB.helpTimes
    end

    CCLuaLog('联盟帮助')
end