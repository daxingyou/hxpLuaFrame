-- RAExecuteScriptFunctionAction.lua
-- Author: xinghui
-- Using: 运行特定模块函数Actin

local Utilitys              = RARequire("Utilitys")
local missionaction_conf    = RARequire("missionaction_conf")
local RAActionBase          = RARequire("RAActionBase")
local RAExecuteScriptFunctionAction     = RAActionBase:new()


--[[
    desc: RAExecuteScriptFunctionAction的入口
]]
function RAExecuteScriptFunctionAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]

    local owner = RARequire(self.constActionInfo.actionTarget)
    if owner then
        --self.constActionInfo.param的格式是  key1_value1,key2_value2,key3_value31|value32
        local args = {}
        local paramStr = self.constActionInfo.param
        if paramStr then
            local tmpArr = Utilitys.Split(paramStr, ",")
            local keyValueArr = {}
            for _, keyValue in pairs(tmpArr) do
                keyValueArr = Utilitys.Split(keyValue, "=")
                if keyValueArr[2] then
                    

                    local valueNum = tonumber(keyValueArr[2])

                    if not valueNum then
                        local valueArr = Utilitys.Split(keyValueArr[2], "|")
                        if #valueArr == 2 then
                            args[keyValueArr[1]] = {x =tonumber(valueArr[1]), y = tonumber(valueArr[2])}
                        elseif #valueArr == 4 then
                            args[keyValueArr[1]] = CCRectMake(tonumber(valueArr[1]), tonumber(valueArr[2]), tonumber(valueArr[3]), tonumber(valueArr[4]))
                        else
                            args[keyValueArr[1]] = keyValueArr[2]
                        end
                    else
                        args[keyValueArr[1]] = valueNum
                    end
                    
                end
            end
        
        end


        --处理函数名
        local functionNames = Utilitys.Split(self.constActionInfo.varibleName, ",")
        if #functionNames > 1 then
            owner[functionNames[1]](functionNames[2],args)
        else
            owner[self.constActionInfo.varibleName](args)
        end


    end

    self:End()
end


return RAExecuteScriptFunctionAction

