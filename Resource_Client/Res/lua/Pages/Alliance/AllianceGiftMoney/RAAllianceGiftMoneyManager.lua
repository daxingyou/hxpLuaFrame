local RAAllianceGiftMoneyManager = {}
local RAAllianceGiftMoneyInfo = RARequire("RAAllianceGiftMoneyInfo")

local RP_TYPE = {
        GET = GuildManager_pb.OPEN_TRY,
        LUCKY = GuildManager_pb.LUCKY_TRY,
        HISTORY = GuildManager_pb.FINISH
}

function RAAllianceGiftMoneyManager:initData(msg)
	-- body
	self:init()
	for i = 1, #msg.redPacketInfo do
        local info = RAAllianceGiftMoneyInfo.new()
        info:initByPb(msg.redPacketInfo[i])

        self.redPacketDatas[info.id] = info
    end
    --今日已发送红包数量
    self.dailySendCount = msg.dailySendCount

    self:updateDataByType()
end

function RAAllianceGiftMoneyManager:getDailySendCount()
	-- body
	return self.dailySendCount or 0
end

function RAAllianceGiftMoneyManager:setDailySendCount()
	-- body
	self.dailySendCount = self.dailySendCount + 1
end

--update data
function RAAllianceGiftMoneyManager:update(msg)
	-- body
	local info = RAAllianceGiftMoneyInfo.new()
    info:initByPb(msg)

    self.redPacketDatas[info.id] = info

    self:updateDataByType()
end

--
function RAAllianceGiftMoneyManager:updateDataByType()
	-- body
	for k,v in pairs(RP_TYPE) do
		self:initType(v)
	end

	for i,info in pairs(self.redPacketDatas) do
		self.redPacketTypeDatas[info.state][info.id] = info
	end
end

--get data by type
function RAAllianceGiftMoneyManager:getDataByType(type)
	-- body
	local infos = {}
	for _type,_info in pairs(self.redPacketTypeDatas) do
		if _type == type then
			infos = _info
		end
	end

	return infos
end

--排序
function RAAllianceGiftMoneyManager:orderDatas(data,state)
	local t = {}
	for k,v in pairs(data) do
		t[#t + 1] = v
	end
	table.sort( t, function (v1,v2)
			if state ~= 3 then
		        if v1.hasOpen == true and v2.hasOpen == false then 
		            return false 
		        elseif v1.hasOpen == false and v2.hasOpen == true then 
		            return true	
	        	elseif v1.hasLuckyTry == true and v2.hasLuckyTry == false then 
		            return false 
		        elseif v1.hasLuckyTry == false and v2.hasLuckyTry == true then 
		            return true	
		        elseif v1.createTime > v2.createTime then
		             return true   
		        end
		        return false
		    else
		    	if v1.createTime > v2.createTime then
		             return true  
		        end
		        return false
		    end    
	        
    end)

    return t
end

function RAAllianceGiftMoneyManager:initType(type)
	self.redPacketTypeDatas[type] = {}
end

function RAAllianceGiftMoneyManager:init()
	self.redPacketDatas = {}
	self.redPacketTypeDatas = {}
	for k,v in pairs(RP_TYPE) do
		self:initType(v)
	end
end

RAAllianceGiftMoneyManager:init()

return RAAllianceGiftMoneyManager