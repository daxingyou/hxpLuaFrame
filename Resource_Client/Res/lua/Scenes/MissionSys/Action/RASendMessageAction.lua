-- RASendMessageAction.lua
-- Author: xinghui
-- Using: 发送消息Actin

local missionaction_conf    = RARequire("missionaction_conf")
local Utilitys              = RARequire("Utilitys")
local RAActionBase          = RARequire("RAActionBase")
local RASendMessageAction   = RAActionBase:new()

--[[
    desc: RASendMessageAction的入口
]]
function RASendMessageAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local messageId = tonumber(self.constActionInfo.varibleName)
    local args = {}
    local paramStr = self.constActionInfo.param
    if paramStr then
        local tmpArr = Utilitys.Split(paramStr, ",")
        local keyValueArr = {}
        for _, keyValue in pairs(tmpArr) do
            keyValueArr = Utilitys.Split(keyValue, "_")
            if keyValueArr[2] then
                local valueInt = tonumber(keyValueArr[2])
                if keyValueArr[1] then
                    args[keyValueArr[1]] = valueInt and valueInt or keyValueArr[2]
                end
            end
        end
        
    end

    MessageManager.sendMessage(messageId, args)


    self:End()
end


return RASendMessageAction