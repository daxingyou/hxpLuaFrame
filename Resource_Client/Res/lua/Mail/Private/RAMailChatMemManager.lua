--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


RAMailChatMemData = {}

--构造函数
function RAMailChatMemData:new(o)
    o = o or {}
    o.playerId= nil       
    o.name = nil
    o.icon = nil
    o.edit = false
    o.select =false
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAMailChatMemData:initByPbData(memData)
	self.playerId= memData.playerId       
    self.name = memData.name  
    self.icon = memData.icon  
end


local RAMailChatMemManager = {}
RAMailChatMemManager.memsTb={}

function RAMailChatMemManager:getMemData(playerId)
	if self.memsTb[playerId] then
		return self.memsTb[playerId]
	end 
end

function RAMailChatMemManager:clearMemsData()
	for k,v in pairs(self.memsTb) do
		v=nil
	end
	self.memsTb=nil
end

function RAMailChatMemManager:resetMemsStatu()
	for k,v in pairs(self.memsTb) do
		local mem = v
		mem.edit =false
		mem.select=false
	end
end
function RAMailChatMemManager:setMemsEditStatu(playerId,isEdit)
	 if not playerId then return end
	 local memData = self:getMemData(playerId)
	 memData.edit = isEdit
end

function RAMailChatMemManager:getMemsEditStatu(playerId)
	if not playerId then return end
	local memData = self:getMemData(playerId)
	return memData.edit 
end

function RAMailChatMemManager:setMemsSelectStatu(playerId,isSelect)
	 if not playerId then return end
	 local memData = self:getMemData(playerId)
	 memData.select = isSelect
end

function RAMailChatMemManager:getMemsSelectStatu(playerId)
	if not playerId then return end
	local memData = self:getMemData(playerId)
	return memData.select 
end
return RAMailChatMemManager
--endregion
