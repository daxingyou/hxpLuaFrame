--[[
	description: 

	author: royhu
	date: 2016/12/20
]]--

local RAFU_OribitCalc_Apocalypse = class('RAFU_OribitCalc_Apocalypse',{})
local Utilitys = RARequire('Utilitys')
local RAFU_Math = RARequire('RAFU_Math')
RARequire("RAFightDefine")

local ParabolaCfg = RARequire('RAFU_Cfg_OribitCalc_Apocalypse').ParabolaCfg

-- 	position = {
-- 		main = {
-- 			startPos = {x=x, y=y},
-- 			endPos = {x=x, y=y},
-- 		},
-- 		--shadow
-- 		sub1 = {
-- 			startPos = {x=x, y=y},
-- 			endPos = {x=x, y=y},
-- 		}
-- 	},
-- 	speed = speed,
--  pixelDistance = distance,
--  spendTime = time,
-- }

function RAFU_OribitCalc_Apocalypse:ctor(param)
	self.mIsNewSuccess = false
	self.mIsInitCalc = false
	if not self:_CheckParam(param) then
		return
	end
	self.mIsNewSuccess = true 
	self.mMainProperty = 
	{
		startPos = Utilitys.ccpCopy(param.position.main.startPos),
		endPos = Utilitys.ccpCopy(param.position.main.endPos),
		speedX = 0,
		speedV0 = {x = 0, y = 0},
		speedVt = {x = 0, y = 0},
		distance = {x = 0, y = 0, total = 0},
		accelerationPart1 = {x = 0, y = 0},
		accelerationPart2 = {x = 0, y = 0},
		highVertex = {x = 0, y = 0}
	}
	self.mSpeed = param.speed
	self.mPixelDistance = param.pixelDistance
	self.mSpendTime = param.spendTime
	
	self.mIsExecute = false

	self.mStartTime = 0
	self.mPastTime = 0

	self.mAngle = Utilitys.ccpAngle(self.mMainProperty.startPos, self.mMainProperty.endPos)
	self.mDirection = param.direction
	RALogInfo('direction-------->' .. self.mDirection)

	self.mMainProperty.distance.x = self.mMainProperty.endPos.x - self.mMainProperty.startPos.x
	self.mMainProperty.distance.y = self.mMainProperty.endPos.y - self.mMainProperty.startPos.y
	self.mMainProperty.distance.total = Utilitys.getDistance(self.mMainProperty.startPos, self.mMainProperty.endPos)

	self.mCalcDatas = 
	{
		main = 
		{
			pos = {x=0, y=0},
		}
	}
end

function RAFU_OribitCalc_Apocalypse:release()	
	self.mMainProperty = nil
	self.mSub1Property = nil
	self.mSpeed = 0
	self.mSpendTime = 0

	self.mIsInitCalc = false
	self.mIsExecute = false
	self.mIsNewSuccess = false

	self.mAngle = 0
	self.mDirection = 0	

	self.mStartTime = 0
	self.mPastTime = 0

	self.mCalcDatas = nil
end

function RAFU_OribitCalc_Apocalypse:_CheckParam(param)
	local result = false
	if param ~= nil and param.position ~= nil and param.spendTime > 0 then
		if param.position.main ~= nil and param.speed > 0 then
			local isMainSame = Utilitys.checkIsPointSame(param.position.main.startPos, param.position.main.endPos)
			if not isMainSame then
				result = true
			end
		end

		if result and param.position.sub1 ~= nil then
			local isSub1Same = Utilitys.checkIsPointSame(param.position.sub1.startPos, param.position.sub1.endPos)
			if isSub1Same then
				result = false
			end
		end
	end
	return result
end

function RAFU_OribitCalc_Apocalypse:Begin()
    self.mIsExecute = true   
    local common = RARequire('common')
    self.mPastTime = 0
    self:_CalcInit()
    self:_CalcImmediately()
    --print('RAFU_OribitCalc_Parabola:Begin   angle:'..self.mAngle..' direction:'..self.mDirection)
    return self:GetCalcDatas()
end


-- calcData = {
-- 	main = {
-- 		pos = {x=x, y=y},
-- 	}
-- }
function RAFU_OribitCalc_Apocalypse:GetCalcDatas()
	return self.mCalcDatas
end

function RAFU_OribitCalc_Apocalypse:Execute(dt)
	if not self.mIsExecute then return end
	self.mPastTime = self.mPastTime + dt

	self:_CalcImmediately()
	return self:GetCalcDatas()
end

function RAFU_OribitCalc_Apocalypse:_CalcInit()
	local cfg = ParabolaCfg[self.mDirection]
	local initV = cfg.Speed_Y_Init_V_Main
	local xPercent_1, xPercent_2 = cfg.Distance_X_Percent_1, cfg.Distance_X_Percent_2
	local part1Time = xPercent_1 * self.mSpendTime
	local part2Time = xPercent_2 * self.mSpendTime

	self.mMainProperty.speedX = self.mMainProperty.distance.x / self.mSpendTime
	self.mMainProperty.speedY = self.mMainProperty.distance.y / self.mSpendTime
	self.mMainProperty.speedV0.y = initV
	self.mMainProperty.accelerationPart1.y = part1Time > 0 and ((0 - initV) / part1Time) or 0
	if self.mDirection == FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT 
		or self.mDirection == FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT 
	then
		self.mMainProperty.accelerationPart1.y = -1
	end
	self.mMainProperty.highVertex.y = self.mMainProperty.speedV0.y * part1Time 
		+ 0.5 * self.mMainProperty.accelerationPart1.y * part1Time * part1Time
	self.mMainProperty.accelerationPart2.y = (self.mMainProperty.distance.y - self.mMainProperty.highVertex.y)
		* 2 / (part2Time * part2Time)

	self.mPart1Time = part1Time
	self.mPart2Time = part2Time
	self.mOribitCfg = cfg

	self.mIsInitCalc = true
end

-- calc and refresh data
function RAFU_OribitCalc_Apocalypse:_CalcImmediately()
	if self.mSpendTime <= 0 or not self.mIsInitCalc then
		return
	end

	local percent = RAFU_Math:CalcPastTimePercent(self.mPastTime, self.mSpendTime)

	local dx, dy = self.mPastTime * self.mMainProperty.speedX, 0
	if self.mDirection < FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT
		or self.mDirection > FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT
	then
		dy = self.mPastTime * self.mMainProperty.speedY
	else
		if percent <= self.mOribitCfg.Distance_X_Percent_1 then
			dy = self.mMainProperty.speedV0.y * self.mPastTime 
				+ 0.5 * self.mMainProperty.accelerationPart1.y * self.mPastTime * self.mPastTime
		elseif percent <= (self.mOribitCfg.Distance_X_Percent_1 + self.mOribitCfg.Distance_X_Percent_2) then
			local duration = self.mPastTime - self.mPart1Time
			dy = 0.5 * self.mMainProperty.accelerationPart2.y * duration * duration + self.mMainProperty.highVertex.y
		else
			dy = self.mMainProperty.distance.y
		end
	end

	self.mCalcDatas.main.pos =
	{
		x = self.mMainProperty.startPos.x + dx,
		y = self.mMainProperty.startPos.y + dy
	}
end

return RAFU_OribitCalc_Apocalypse
