local EnterFrameDefine = RARequire("EnterFrameDefine")

--===================================================================

EnterFrameMananger = {}

local EnterFrameHandlerTabel = {}
local EnterFrameCallOneHandlerTable = {}

function EnterFrameMananger.performNextFrame(handler)
	EnterFrameCallOneHandlerTable[#EnterFrameCallOneHandlerTable + 1] = handler
end

function EnterFrameMananger.enterFrame()

	for k,v in pairs(EnterFrameCallOneHandlerTable) do
		v()
	end

	EnterFrameCallOneHandlerTable = {}

	for id,handlerMap in pairs(EnterFrameHandlerTabel) do
		if handlerMap ~= nil then
			-- for _,handler in pairs(handlerMap) do
			-- 	if handler ~= nil and handler.EnterFrame ~= nil then
			-- 		handler:EnterFrame()
			-- 	end
			-- end

			local count = handlerMap.StaticCount
			for i=1,count do
				if handlerMap[i] ~= nil and handlerMap[i].EnterFrame ~= nil then
					handlerMap[i]:EnterFrame()
				end			
			end
		end
	end
end

function EnterFrameMananger.registerEnterFrameHandler(enterframeId, handler)
	assert(handler,"\n--========EnterFrameMananger:this handler is nil========--")
	local handlerMap = EnterFrameHandlerTabel[enterframeId]
	if handlerMap ~= nil then
		handlerMap.StaticCount = handlerMap.StaticCount + 1
		handlerMap[handlerMap.StaticCount] = handler
		-- table.insert(EnterFrameHandlerTabel[enterframeId],handler)
	else
		handlerMap = {}
		EnterFrameHandlerTabel[enterframeId] = handlerMap
		handlerMap.StaticCount = 1
		handlerMap[handlerMap.StaticCount] = handler
		-- table.insert(handlerMap,handler)
	end		
end

function EnterFrameMananger.removeEnterFrameHandler(enterframeId, handler)
	local handlerMap = EnterFrameHandlerTabel[enterframeId]
	if handlerMap then
		local count = handlerMap.StaticCount
		local lastCount = 0
		for i=1,count do
			if handlerMap[i] ~= nil then
				lastCount = lastCount + 1
				if handler == handlerMap[i] then
					handlerMap[i] = nil
					lastCount = lastCount - 1
				end
			end			
		end

		if lastCount == 0 then
			-- 都不存在的话移除了
			EnterFrameHandlerTabel[enterframeId] = nil
			handlerMap = nil
		end

		-- for i,k in pairs(handlerMap) do
		-- 	if k == handler then
		-- 		handlerMap[i] = nil
		-- 	end
		-- end
	end
end
