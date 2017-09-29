--region RANetUtil.lua
--Date 20160526
--此文件由[BabeLua]插件自动生成

local RANetUtil = {}

-- 发送protobuf协议
function RANetUtil:sendPacket(opcode, protoMsg, extraParamTB)
    
    local pb_data = ''
    if protoMsg ~= nil then
        --todo
        pb_data = protoMsg:SerializeToString()
    end
    extraParamTB = extraParamTB or {}
    local waitingTime = extraParamTB['waitingTime'] or 10.0
    local sendTimes = extraParamTB['sendTimes'] or 1
    local retOpcode = extraParamTB['retOpcode'] or 0
    PacketManager:getInstance():sendPacket(opcode, pb_data, #pb_data, waitingTime, sendTimes, retOpcode)
end

-- 发送不期待ret opcode的协议
function RANetUtil:sendSinglePacket(opcode, protoMsg, extraParamTB)
    extraParamTB = extraParamTB or {}
    extraParamTB['retOpcode'] = 0
    self:sendPacket(opcode, protoMsg, extraParamTB)
end

-- 添加协议监听
-- @param opcodeTB 可以是table, 可以是单个协议id
-- @param listener 应实现 listener:onReceivePacket(handler) 方法
-- @return table of handler, 方便调用removeListener()方法来移除并释放handler
function RANetUtil:addListener(opcodeTB, listener)
    if type(opcodeTB) ~= 'table' then
        opcodeTB = { opcodeTB }
    end

    local handlerTB = {}
    for k, v in pairs(opcodeTB) do
        handlerTB[k] = PacketScriptHandler:new(v, listener)
    end

    return handlerTB
end

-- 移除监听
function RANetUtil:removeListener(handlerTB)
    for k, v in pairs(handlerTB) do
        if v then
            v:delete()
            handlerTB[k] = nil
        end
    end
end

return RANetUtil 
--endregion