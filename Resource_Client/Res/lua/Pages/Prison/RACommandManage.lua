--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local HP_pb = RARequire("HP_pb")
local RANetUtil=RARequire("RANetUtil")
local RARootManager=RARequire("RARootManager")
local RACommandManage={
	commonder=nil
}
--指挥官
RACommanderData={}
-- --构造函数
function RACommanderData:new(o)
    o = o or {}

    o.uuid=nil
    o.enemyId=nil
    o.state=nil
    o.endTime=nil

    o.punishTime=nil
    o.name=nil
	o.icon=nil
	o.level=nil
	o.posX=nil
	o.posY=nil

    setmetatable(o,self)
    self.__index = self
    return o
end

function RACommanderData:initByPbData(data)
    self.uuid=data.uuid
    self.enemyId=data.enemyId
    self.state=data.state
    self.endTime=math.floor(data.endTime/1000)

    if data:HasField('punishTime') then
    	self.punishTime=math.floor(data.punishTime/1000)
    end

    if data:HasField('name') then
    	self.name=data.name
    end

   	if data:HasField('icon') then
    	self.icon=data.icon
    end


   	if data:HasField('level') then
    	self.level=data.level
    end
    if data:HasField('posX') then
    	self.posX=data.posX
    end
    if data:HasField('posY') then
    	self.posY=data.posY
    end


   
end

function RACommandManage:addCommanderData(data)
	if self.commonder==nil then
		local commonderData=RACommanderData:new()
    	commonderData:initByPbData(data) 
   		self.commonder=commonderData
	end 

end

function RACommandManage:updateCommanderData(data)
    local commander=self:getCommanderData()

    local endTime=math.floor(data.endTime/1000)
    local punishTime=math.floor(data.punishTime/1000)

    if commander.state~=data.state then
 
        commander.state=data.state
    end 

    if commander.endTime~=endTime then

        commander.endTime=endTime
    end 

    if commander.enemyId~=data.enemyId then
        commander.enemyId=data.enemyId
    end

    if commander.punishTime~=punishTime then
        commander.punishTime=punishTime
    end 

    if commander.name~=data.name then
        commander.name=data.name
    end
    if commander.icon~=data.icon then
        commander.icon=data.icon
    end
    if commander.level~=data.level then
        commander.level=data.level
    end
    if commander.posX~=data.posX then
        commander.posX=data.posX
    end
    if commander.posY~=data.posY then
        commander.posY=data.posY
    end
end

function RACommandManage:getCommanderData()
	if self.commonder then
		return self.commonder
	end 
end

function RACommandManage:clearCommanderData()
    if self.commonder then
        self.commonder=nil
    end
end

--同步指挥官的状态
function RACommandManage:updateCommanderState(state)
	
	local commonder=self:getCommanderData()
	if commonder then
		commonder.state=state
	end 
end
--同步指挥官的状态结束时间
function RACommandManage:updateCommanderTime(endTime)
	local commonder=self:getCommanderData()
	if commonder then
		commonder.endTime=math.floor(endTime/1000)
	end 
end
--返回指挥官的状态
function RACommandManage:getCommanderState()
	local commonder=self:getCommanderData()
	if commonder then
		return commonder.state
	end 
end
--返回指挥官的状态结束时间
function RACommandManage:getCommanderEndTime()
	local commonder=self:getCommanderData()
	if commonder then
		return commonder.endTime
	end 
end

function RACommandManage:reset()
    self:clearCommanderData()
end

--------------------------------------------------------------协议相关

--立即复活
function RACommandManage:sendCommanderResurrecReq()
	RANetUtil:sendPacket(HP_pb.CAPTIVE_REBORN_C)
end
--发邮件请求释放
function RACommandManage:sendReleaseMail(name)
	RARootManager.OpenPage("RAMailWritePage",{sendName=name})
end

function RACommandManage:sendOpenPlayerBoardReq()
    RANetUtil:sendPacket(HP_pb.OPEN_PLAYER_BOARD_C)
    
end
return RACommandManage
--endregion
