--[[
description: 
buff系统，包含多个buff table

author: zhenhui
date: 2016/12/13
]]--

local RAFU_BuffSystem = class('RAFU_BuffSystem',RARequire("RAFU_Object"))


function RAFU_BuffSystem:ctor(unit)
	self.fightUnit = unit
	self.buffList = {}
end

--析构函数
function RAFU_BuffSystem:release()
	for k,v in pairs(self.buffList) do
		RA_SAFE_RELEASE(v)
	end
end

--buff 系统开始
function RAFU_BuffSystem:Enter()

end

function RAFU_BuffSystem:Execute(dt)
	for k,v in pairs(self.buffList) do
		RA_SAFE_EXECUTE(v,dt)
	end
end

function RAFU_BuffSystem:Exit()
    -- RALog("RAFU_BuffSystem:Exit")
    for k,v in pairs(self.buffList) do
		RA_SAFE_RELEASE(v)
	end
end

function RAFU_BuffSystem:AddBuff(data)

	local buffCfgName = data.buffCfgName
	local uuid = RARequire("uuid")

	local buffUuid = nil 
	if data.id == nil then 
    	buffUuid = uuid.new()
    else
    	buffUuid = data.id
    end 

	local RAFU_Cfg_Buff = RARequire("RAFU_Cfg_Buff")
	self.cfgData = RAFU_Cfg_Buff[buffCfgName]
	local owner = self
	local spriteNode = self.fightUnit.spriteNode
	local rootNode = self.fightUnit.rootNode
	local buffInstance = RARequire(self.cfgData.class).new(buffUuid,owner,spriteNode,rootNode,buffCfgName)
	buffInstance:Enter(data)
	self.buffList[buffUuid] = buffInstance
end

function RAFU_BuffSystem:RemoveBuff(uuid)
	if self.buffList[uuid] ~= nil then
		self.buffList[uuid] = nil
	end
end


return RAFU_BuffSystem