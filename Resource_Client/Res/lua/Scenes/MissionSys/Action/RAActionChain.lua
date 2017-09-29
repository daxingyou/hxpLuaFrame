-- RAActionChain.lua
-- Author: xinghui
-- Using: Action的链

local Utilitys = RARequire("Utilitys")
local RAMissionActionManager = RARequire("RAMissionActionManager")

local RAActionChain = {
    actionChainList = {},           --保存这个chain中所有的action
    chainId = nil,                  --当前chain的Id
    currActionIndex = 0             --当前运行的action的索引
}

--[[
    desc: 返回一个chain实例
    @return: 返回chain实例
]]
function RAActionChain:new()
    local o = {}
    self:_resetData()
    setmetatable(o, self)
    self.__index = self

    return o
end

--[[
    desc: 根据数据构造chain
    @param: data 构造chain所用的数据
]]
function RAActionChain:Enter(data)
    self:_resetData()

    local subAction = {}
    if data then
        if type(data) == "table" then
            subAction = Utilitys.Split(data.action, "|")
            self.chainId = data.id
        else
            subAction = Utilitys.Split(data, "|")
        end

        for i, actionStr in ipairs(subAction) do
            local action = RAMissionActionManager:getActionByType(actionStr)
            self.actionChainList[i] = action
            if i > 1 then
               local preAction = self.actionChainList[i - 1]
               preAction.nextAction = action
            end
        end
    end
end

--[[
    desc: 开始这个chain
]]
function RAActionChain:startChain()
    self:goChain()
end

--[[
    desc: 从chain中选择合适的action运行
]]
function RAActionChain:goChain()
    if self.currActionIndex < 1 then
        self.currActionIndex = 1
        local action = self.actionChainList[self.currActionIndex]
        if action then
            action:Enter()
        end
    else
        local action = self.actionChainList[self.currActionIndex]
        if action.nextAction then
            action.nextAction:Enter()
            self.currActionIndex = self.currActionIndex + 1
        else
            --没有连接的action，说明这个chain已经走完
            MessageManager.sendMessage(MessageDef_MissionBarrier.MSG_ChainEnd, {chainId = self.chainId})
        end
    end
end

--[[
    desc: 重置所有数据
]]
function RAActionChain:_resetData()
    self.actionChainList = {}
    self.currActionIndex = 0
    self.chainId = nil
end

return RAActionChain