--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local Commander_pb = RARequire("Commander_pb")
local HP_pb = RARequire("HP_pb")
local RANetUtil=RARequire("RANetUtil")
local RAPrisonDataManage={
	
	captureDatas={}
}




-- //指挥官信息
-- message CommanderInfo
-- {
-- 	required string uuid 		= 1;
-- 	required string enemyId 	= 2; //敌人id
-- 	required int32  state 		= 3; //状态，0正常，1被抓，2处决
-- 	required int64  endTime		= 4; //倒计时
	
-- 	optional int64  punishTime	= 5; //上次用刑时间，以下信息为俘虏信息
-- 	optional string name 		= 6;
-- 	optional int32  icon 		= 7;
-- 	optional int32  level 		= 8;
-- 	optional int32  posX 		= 9;
-- 	optional int32  posY 		= 10;
-- }




--俘虏信息

RACaptureData = {}

--构造函数
function RACaptureData:new(o)
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

function RACaptureData:initByPbData(data)
	self.uuid=data.uuid
    self.enemyId=data.enemyId
    self.state=data.state
    self.endTime=math.floor(data.endTime/1000)
    self.punishTime=math.floor(data.punishTime/1000)
    self.name=data.name
	self.icon=data.icon
	self.level=data.level
	self.posX=data.posX
	self.posY=data.posY
   
end

--加入俘虏数据  
function RAPrisonDataManage:addCaptureData(id,data)
	if self.captureDatas[id]==nil then
		local captureData=RACaptureData:new()
		captureData:initByPbData(data)
		self.captureDatas[id]=captureData
	end 
end

--删除俘虏数据
function RAPrisonDataManage:deleteCaptureData(id)
	if self.captureDatas[id]then
		self.captureDatas[id]=nil
	end 
end

--删除所有俘虏数据
function RAPrisonDataManage:deleteAllCaptureData()
	if self.captureDatas then
		for k,v in pairs(self.captureDatas) do
			v=nil
		end
		self.captureDatas={}
	end 
end

function RAPrisonDataManage:reset()
    self:deleteAllCaptureData()
end

--更新俘虏的状态
function RAPrisonDataManage:updateCaptureState(id,state)
	local captureData=self:getCaptureData(id)
	if captureData then
		captureData.state=state
	end 
end

--获取俘虏的状态
function RAPrisonDataManage:getCaptureState(id)
	local captureData=self:getCaptureData(id)
	if captureData then
		return captureData.state
	end 
end

function RAPrisonDataManage:updateCaptureEndTime(id,endTime)
	local captureData=self:getCaptureData(id)
	if captureData then
		endTime=math.floor(endTime/1000)
		captureData.endTime=endTime
	end 
end
function RAPrisonDataManage:getCaptureEndTime(id)
	local captureData=self:getCaptureData(id)
	if captureData then
		return captureData.endTime
	end
end


--更新俘虏的用刑时间
function RAPrisonDataManage:updateCapturePunishTime(id,punishTime)
	local captureData=self:getCaptureData(id)
	if captureData then
		punishTime=math.floor(punishTime/1000)
		captureData.punishTime=punishTime
	end 
end

function RAPrisonDataManage:getCapturePunishTime(id)
	local captureData=self:getCaptureData(id)
	if captureData then
		return captureData.punishTime
	end
end
--判断是否有俘虏
function RAPrisonDataManage:getIsHaveCapture()

	if next(self.captureDatas) then
		return true
	end 
	return false
end

--返回单个俘虏的信息
function RAPrisonDataManage:getCaptureData(id)
	if self.captureDatas[id] then
		return self.captureDatas[id]
	end
	return nil
end

--返回所有俘虏的信息
function RAPrisonDataManage:getAllCaptureData()
	if self.captureDatas then
		return self.captureDatas
	end 
	return nil
end


--------------------------------------------------协议处理

--立即释放
function RAPrisonDataManage:sendCaptureReleaseReq(playeId)
	local cmd = Commander_pb.HPCaptiveOptReq()
    cmd.playerId=playeId

    RANetUtil:sendPacket(HP_pb.CAPTIVE_RELEASE_C,cmd)
end

--用刑
function RAPrisonDataManage:sendCapturePunishReq(playeId)
	local cmd = Commander_pb.HPCaptiveOptReq()
    cmd.playerId=playeId

    RANetUtil:sendPacket(HP_pb.CAPTIVE_PUNISH_C,cmd)
end

--处决
function RAPrisonDataManage:sendCaptureExecuteReq(playeId)
	local cmd = Commander_pb.HPCaptiveOptReq()
    cmd.playerId=playeId

    RANetUtil:sendPacket(HP_pb.CAPTIVE_EXECUTE_C,cmd)
end

--查看俘虏信息
function RAPrisonDataManage:sendCheckCaptureReq( )
	RANetUtil:sendPacket(HP_pb.CAPTIVE_GET_C)
end
----------------------------------------------------------


return RAPrisonDataManage
--endregion
