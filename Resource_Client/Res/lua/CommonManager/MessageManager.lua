local List = RARequire("List")
RARequire("MessageDefine")
--require("MessageManager.Message")
MessageHandler = {}
function MessageHandler:new(o)
	o = o or {}
	setmetatable(o,self)
    self.__index = self
    return o	
end

function MessageHandler:OnMessageReceive(message) end
--===================================================================

MessageManager = {}

local MessageHandlerTable = {}
local MessageList = {}



function MessageManager.table_simpleEqual(t1,t2)
    if #t1 ~= #t2 then return false end
    for k,v in pairs(t1) do
        if v ~= t2[k] then
            return false
        end
    end
    return true
end

function MessageManager.update()
	while #MessageList > 0  do
		--local message = MessageList:PopFront()
        local message = table.remove(MessageList,1)
		if message then 
			local messageID = message.messageID
			local HanderTable = MessageHandlerTable[messageID]
			if HanderTable then
				for _,v in pairs(HanderTable) do				
					v(message)
				end
			end
		end			
	end
end

function MessageManager.registerMessageHandler(messageID,messageHandler)
	assert(messageHandler,"\n--========this handler is nil========--")
	if MessageHandlerTable[messageID] then
		table.insert(MessageHandlerTable[messageID],messageHandler)
	else
		local HandlerTable = {}
		table.insert(HandlerTable,messageHandler)		
		MessageHandlerTable[messageID] = HandlerTable
	end		
end

function MessageManager.removeMessageHandler(messageID,messageHandler)
	local handlerMap = MessageHandlerTable[messageID]
	if handlerMap then
		for i,k in pairs(handlerMap) do
			if k == messageHandler then
				handlerMap[i] = nil
			end
		end
	end
end

function MessageManager.removeAllMessageHandler(messageID)
	if messageID then
		MessageHandlerTable[messageID] = nil
	end
end

function MessageManager.sendMessage(id,message)
    if message == nil then
        message = {}
    end
    message.messageID = id
    for k,v in pairs(MessageList) do 
        if v.messageID == id then
            if MessageManager.table_simpleEqual(v,message) then
                CCLuaLog("same id detected in same frame, discard, message id is "..id)
                return
            end
        end
    end
    table.insert(MessageList,message)
end

-- Message 立即处理，不必等到下一帧
function MessageManager.sendMessageInstant(id, message)
	local HanderTable = MessageHandlerTable[id]
	if HanderTable then
	    if message == nil then
	        message = {}
	    end
	    message.messageID = id

		for _,v in pairs(HanderTable) do	
			v(message)
		end
	end
end