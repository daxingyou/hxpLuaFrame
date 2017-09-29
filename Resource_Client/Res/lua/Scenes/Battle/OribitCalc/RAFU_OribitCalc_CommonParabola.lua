--[[
description: 单个炮弹的轨迹运算
  
author: qinho
date: 2017-01-11
]]--

local RAFU_OribitCalc_CommonParabola = class('RAFU_OribitCalc_CommonParabola',{})
local Utilitys = RARequire('Utilitys')
local RAFU_Math = RARequire('RAFU_Math')
RARequire("RAFightDefine")

-- 默认值，如果参数里有的话，会使用参数内的配置
local ParabolaDirCfg = RARequire('RAFU_Cfg_OribitCalc_OneMissile').ParabolaDirCfg
local ParabolaPartType = RARequire('RAFU_Cfg_OribitCalc_OneMissile').ParabolaPartType
local isCalcShadow = true

-- param = {
-- 	main = {
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
-- 	pixelDistance = distance,
-- 	spendTime = time,
-- 	cfg = {
-- 		dirCfg = ParabolaDirCfg,
-- 		partCfg = ParabolaPartType
-- 	},
-- 	isCalcShadow = true
-- }

function RAFU_OribitCalc_CommonParabola:ctor(param)
	self.mIsNewSuccess = false
	self.mIsInitCalc = false
	if not self:_CheckParam(param) then
		return
	end
	if param.cfg ~= nil then
		if param.cfg.dirCfg ~= nil then
			ParabolaDirCfg = param.cfg.dirCfg
		end
		if param.cfg.partCfg ~= nil then
			ParabolaPartType = param.cfg.partCfg
		end
	end
	if param.isCalcShadow ~= nil then
		isCalcShadow = param.isCalcShadow
	end
	self.mIsNewSuccess = true 
	self.mMainProperty = {
		startPos = Utilitys.ccpCopy(param.position.main.startPos),
		endPos = Utilitys.ccpCopy(param.position.main.endPos),
		speedV0 = {x = 0, y = 0},
		speedVt = {x = 0, y = 0},
		distance = {x = 0, y = 0, total = 0},
		accelerationPart1 = {x = 0, y = 0},
		accelerationPart2 = {x = 0, y = 0},
		highVertex = {x = 0, y = 0},
		-- 转换坐标系后的数据
		axesRotated = 
		{
			agnle = 0,
			radian = 0,
			posGap = {x = 0, y = 0},
			startPos = {x = 0, y = 0},
			endPos = {x = 0, y = 0},
			speedV0 = {x = 0, y = 0},
			accelerationPart1 = {x = 0, y = 0},
			accelerationPart2 = {x = 0, y = 0},
			highVertex = {x = 0, y = 0},
		},
		partType = ParabolaPartType.PartOne
	}

	self.mSpeed = param.speed
	self.mPixelDistance = param.pixelDistance
	self.mSpendTime = param.spendTime

	self.mIsExecute = false
	self.mStartTime = 0
	self.mPastTime = 0

	-- calc angle 
	self.mAngle = Utilitys.ccpAngle(self.mMainProperty.startPos, self.mMainProperty.endPos)	
	self.mDirection = RAFU_Math:Get16DirectionByAngle(self.mAngle)

	self.mMainProperty.distance.x = self.mMainProperty.endPos.x - self.mMainProperty.startPos.x
	self.mMainProperty.distance.y = self.mMainProperty.endPos.y - self.mMainProperty.startPos.y
	self.mMainProperty.distance.total = Utilitys.getDistance(self.mMainProperty.startPos, self.mMainProperty.endPos)

	if isCalcShadow then
		-- 影子的起始点和炮弹的起始点一致
		self.mSub1Property = { 
			startPos = Utilitys.ccpCopy(param.position.main.startPos),
			endPos = Utilitys.ccpCopy(param.position.main.endPos),
			distance = {x = 0, y = 0, total = 0},
			-- 暂时下面的没用到
			speedV0 = {x = 0, y = 0},
			speedVt = {x = 0, y = 0},
			accelerationPart1 = {x = 0, y = 0},
		}
		self.mSub1Property.distance.x = self.mSub1Property.endPos.x - self.mSub1Property.startPos.x
		self.mSub1Property.distance.y = self.mSub1Property.endPos.y - self.mSub1Property.startPos.y
		self.mSub1Property.distance.total = Utilitys.getDistance(self.mSub1Property.startPos, self.mSub1Property.endPos)
		-- self.mShadowAngle = Utilitys.ccpAngle(self.mSub1Property.endPos, self.mSub1Property.startPos)
	else
		self.mSub1Property = nil
	end

	self.mCalcDatas = {
		-- 主体
		main = {
			pos = {x=0, y=0},
			rotation = 0,
			partType = ParabolaPartType.PartOne,
			direction = 0,
			timePart1 = 0,
			timePart2 = 0,
			-- 用于提前固定的时间值消失，否则炮弹尾部到达位置会很奇怪
			isVisible = true
		},
		-- 影子
		sub1 = {
			pos = {x = 0, y = 0},
			rotation = 0,
		},
		-- 拖尾
		sub2 = {
			rotation = 0
		},		
		isEnd = false
	}
end

function RAFU_OribitCalc_CommonParabola:release()	
	self.mMainProperty = nil
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

function RAFU_OribitCalc_CommonParabola:_CheckParam(param)
	local result = false
	if param ~= nil and param.position ~= nil and param.spendTime > 0 then
		if param.position.main ~= nil and param.speed > 0 then
			local isMainSame = Utilitys.checkIsPointSame(param.position.main.startPos, param.position.main.endPos)
			if not isMainSame then
				result = true
			end
		end
	end
	return result
end

function RAFU_OribitCalc_CommonParabola:Begin()
    self.mIsExecute = true   
    local common = RARequire('common')
    self.mStartTime = common:getCurTime()
    self.mPastTime = 0
    self:_CalcInit()
    self:_CalcImmediately()
    print('RAFU_OribitCalc_CommonParabola:Begin   angle:'..self.mAngle..' direction:'..self.mDirection)
    return self:GetCalcDatas()
end


-- self.mCalcDatas = {
-- 		-- 主体
-- 		main = {
-- 			pos = {x=0, y=0},
-- 			rotation = 0,
-- 			partType = ParabolaPartType.PartOne,
-- 			direction = 0,
-- 			timePart1 = 0,
-- 			timePart2 = 0,
-- 			-- 用于提前固定的时间值消失，否则炮弹尾部到达位置会很奇怪
-- 			isVisible = true
-- 		},
-- 		-- 影子
-- 		sub1 = {
-- 			pos = {x = 0, y = 0},
-- 			rotation = 0,
-- 		},
-- 		-- 拖尾
-- 		sub2 = {
-- 			rotation = 0
-- 		},		
-- 		isEnd = false
-- 	}
function RAFU_OribitCalc_CommonParabola:GetCalcDatas()
	return self.mCalcDatas
end


function RAFU_OribitCalc_CommonParabola:Execute(dt)
	if not self.mIsExecute then return end
	self.mPastTime = self.mPastTime + dt

	self:_CalcImmediately()
	return self:GetCalcDatas()
end

function RAFU_OribitCalc_CommonParabola:_CalcInit()
	
	if not self.mIsInitCalc then
		-- 垂直方向
		if self.mDirection == FU_DIRECTION_ENUM.DIR_UP then		
			-- calc part one
			local initVSelf = ParabolaDirCfg[self.mDirection].Speed_Y_Init_V_Main
			local disYPer = ParabolaDirCfg[self.mDirection].Distance_Y_Percent
			local param1 = math.sqrt((disYPer + 1) / disYPer)
			local timePart2 = self.mSpendTime /(param1 + 1)
			local timePart1 = self.mSpendTime - timePart2

			self.mMainProperty.highVertex.x = self.mMainProperty.endPos.x
			self.mMainProperty.highVertex.y = self.mMainProperty.endPos.y + math.abs(disYPer * self.mMainProperty.distance.y)

			self.mMainProperty.speedV0.y = initVSelf
			local accelerationParam = 2 * (disYPer + 1) * math.abs(self.mMainProperty.distance.y) - 2 * initVSelf * timePart1
			self.mMainProperty.accelerationPart1.y = accelerationParam / timePart1 / timePart1
			self.mMainProperty.partType = ParabolaPartType.PartOne

			self.mCalcDatas.main.isVisible = true
			self.mCalcDatas.main.timePart2 = timePart2
			self.mCalcDatas.main.timePart1 = timePart1
			self.mCalcDatas.sub2.rotation = -90
			self.mIsInitCalc = true
			return
		end

		-- 垂直向下
		if self.mDirection == FU_DIRECTION_ENUM.DIR_DOWN then		
			-- calc part one
			local initVSelf = ParabolaDirCfg[self.mDirection].Speed_Y_Init_V_Main
			local disYPer = ParabolaDirCfg[self.mDirection].Distance_Y_Percent			
			local param1 = math.sqrt(disYPer / (disYPer + 1))
			local timePart2 = self.mSpendTime /(param1 + 1)
			local timePart1 = self.mSpendTime - timePart2

			self.mMainProperty.highVertex.x = self.mMainProperty.endPos.x
			self.mMainProperty.highVertex.y = self.mMainProperty.startPos.y + math.abs(disYPer * self.mMainProperty.distance.y)

			self.mMainProperty.speedV0.y = initVSelf
			-- self.mMainProperty.accelerationPart1.y = -math.abs(initVSelf / timePart1)
			local accelerationParam = 2 * math.abs(disYPer * self.mMainProperty.distance.y) - 2 * initVSelf * timePart1
			self.mMainProperty.accelerationPart1.y = accelerationParam / timePart1 / timePart1
			self.mMainProperty.partType = ParabolaPartType.PartOne


			-- part two部分需要在切换的时候实时计算，防止跳位置的情况
			-- self.mMainProperty.accelerationPart2.y = -math.abs(2*(disYPer + 1) * self.mMainProperty.distance.y / ( timePart2 * timePart2))

			self.mCalcDatas.main.isVisible = true
			self.mCalcDatas.main.timePart2 = timePart2
			self.mCalcDatas.main.timePart1 = timePart1
			self.mCalcDatas.sub2.rotation = 90
			self.mIsInitCalc = true
			return
		end

		-- 所有其他方向走一样的逻辑
		if 1 > 0 then
			-- calc main

			self.mMainProperty.partType = ParabolaPartType.PartOne			
			
			local initVSelf = ParabolaDirCfg[self.mDirection].Speed_Y_Init_V_Main
			local disXper = ParabolaDirCfg[self.mDirection].Distance_X_Percent			

			-- 新坐标系 先平移，后旋转
			local startPos = self.mMainProperty.startPos
			local endPos = self.mMainProperty.endPos
			-- endPos = RACcpAdd(startPos, RACcp(1,1))
			self.mMainProperty.axesRotated.posGap = Utilitys.ccpCopy(startPos)
			local angle, radian = Utilitys.ccpAngle(startPos, endPos)
			self.mMainProperty.axesRotated.angle = angle
			self.mMainProperty.axesRotated.radian = radian
			self.mMainProperty.axesRotated.reverseRadian = math.rad(360 - angle)
			self.mMainProperty.axesRotated.startPos = RACcp(0, 0)
			local endMovedPos = RACcpSub(endPos, self.mMainProperty.axesRotated.posGap)
			self.mMainProperty.axesRotated.endPos = RAFU_Math:CalcPosAxesRotated(endMovedPos, radian)

			local timePart1 = self.mSpendTime * disXper
			local timePart2 = self.mSpendTime * (1 - disXper)
			-- y part 1
			self.mMainProperty.axesRotated.speedV0.y = initVSelf
			self.mMainProperty.axesRotated.accelerationPart1.y = -math.abs(initVSelf / timePart1)

			-- high vertex
			self.mMainProperty.axesRotated.highVertex.x = self.mMainProperty.axesRotated.endPos.x * disXper
			self.mMainProperty.axesRotated.highVertex.y = self.mMainProperty.axesRotated.speedV0.y * timePart1 + 
				0.5 * self.mMainProperty.axesRotated.accelerationPart1.y * timePart1 * timePart1

			-- y part 2
			local accelerationPart2 = 2 * self.mMainProperty.axesRotated.highVertex.y / timePart2 / timePart2
			self.mMainProperty.axesRotated.accelerationPart2.y = math.abs(accelerationPart2)

			-- x 
			self.mMainProperty.speedV0.x = self.mMainProperty.distance.total / self.mSpendTime
			self.mMainProperty.accelerationPart1.x = 0

			self.mCalcDatas.main.isVisible = true
			self.mCalcDatas.main.timePart1 = timePart1
			self.mCalcDatas.main.timePart2 = timePart2
			-- print('.....................................')
			-- print('part1 time:'..timePart1..'   part2 time:'..timePart2)
		end
	end
end

-- calc and refresh data
function RAFU_OribitCalc_CommonParabola:_CalcImmediately()
	if self.mSpendTime <= 0 and not self.mIsInitCalc then
		return
	end

	local percent = RAFU_Math:CalcPastTimePercent(self.mPastTime, self.mSpendTime)
	self.mCalcDatas.isEnd = percent >= 1

	local aheadTime = ParabolaDirCfg[self.mDirection].AheadTimeToRemoveBody
	self.mCalcDatas.main.isVisible = self.mSpendTime - self.mPastTime > aheadTime
	
	if self.mDirection == FU_DIRECTION_ENUM.DIR_UP then		
		local posY = self.mMainProperty.startPos.y
		if self.mMainProperty.partType == ParabolaPartType.PartOne then
			local mainMoveY = RAFU_Math:CalcDistanceByV0_A_T(self.mMainProperty.speedV0.y, self.mMainProperty.accelerationPart1.y, self.mPastTime)		
			posY = posY + mainMoveY
			if self.mPastTime >= self.mCalcDatas.main.timePart1 then							
				self.mMainProperty.partType = ParabolaPartType.PartTwo

				-- 重新设置最高点位置为当前位置
				self.mMainProperty.highVertex.y = posY
				local yDistance = posY - self.mMainProperty.endPos.y
				local timePart2 = self.mCalcDatas.main.timePart2
				-- 重新计算第2段相关加速度
				self.mMainProperty.accelerationPart2.y = -math.abs(2* yDistance / ( timePart2 * timePart2))
			end
			self.mCalcDatas.sub2.rotation = -90
		else
			local part2PastTime = self.mPastTime - self.mCalcDatas.main.timePart1			
			if part2PastTime >= self.mCalcDatas.main.timePart2 then
				part2PastTime = self.mCalcDatas.main.timePart2
				posY = self.mMainProperty.endPos.y
			else
				local mainMoveY = RAFU_Math:CalcDistanceByV0_A_T(0, self.mMainProperty.accelerationPart2.y, part2PastTime)		
				posY = self.mMainProperty.highVertex.y + mainMoveY 
			end
			self.mCalcDatas.sub2.rotation = 90
		end

		self.mCalcDatas.main.pos.x = self.mMainProperty.startPos.x + self.mMainProperty.distance.x * percent
		self.mCalcDatas.main.pos.y = posY
		self.mCalcDatas.main.partType = self.mMainProperty.partType
		self.mCalcDatas.main.direction =self.mDirection
		self.mCalcDatas.main.rotation = 0

		-- 计算影子位置，垂直方向上，影子匀速运动
		if isCalcShadow and self.mSub1Property ~= nil then
			self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x + self.mSub1Property.distance.x * percent
			self.mCalcDatas.sub1.pos.y = self.mSub1Property.startPos.y + self.mSub1Property.distance.y * percent
			self.mCalcDatas.sub1.rotation = 0
		end

		return
	end

	if self.mDirection == FU_DIRECTION_ENUM.DIR_DOWN then		
		local posY = self.mMainProperty.startPos.y
		if self.mMainProperty.partType == ParabolaPartType.PartOne then
			local mainMoveY = RAFU_Math:CalcDistanceByV0_A_T(self.mMainProperty.speedV0.y, self.mMainProperty.accelerationPart1.y, self.mPastTime)		
			posY = posY + mainMoveY
			if self.mPastTime >= self.mCalcDatas.main.timePart1 then							
				self.mMainProperty.partType = ParabolaPartType.PartTwo

				-- 重新设置最高点位置为当前位置
				self.mMainProperty.highVertex.y = posY
				local yDistance = posY - self.mMainProperty.endPos.y
				local timePart2 = self.mCalcDatas.main.timePart2
				-- 重新计算第2段相关加速度
				self.mMainProperty.accelerationPart2.y = -math.abs(2* yDistance / ( timePart2 * timePart2))
			end
			self.mCalcDatas.sub2.rotation = -90
		else
			local part2PastTime = self.mPastTime - self.mCalcDatas.main.timePart1			
			if part2PastTime >= self.mCalcDatas.main.timePart2 then
				part2PastTime = self.mCalcDatas.main.timePart2
				posY = self.mMainProperty.endPos.y
			else
				local mainMoveY = RAFU_Math:CalcDistanceByV0_A_T(0, self.mMainProperty.accelerationPart2.y, part2PastTime)		
				posY = self.mMainProperty.highVertex.y + mainMoveY 
			end
			self.mCalcDatas.sub2.rotation = 90
		end

		self.mCalcDatas.main.pos.x = self.mMainProperty.startPos.x + self.mMainProperty.distance.x * percent
		self.mCalcDatas.main.pos.y = posY
		self.mCalcDatas.main.partType = self.mMainProperty.partType
		self.mCalcDatas.main.direction =self.mDirection
		self.mCalcDatas.main.rotation = 0		

				-- 计算影子位置，垂直方向上，影子匀速运动
		if isCalcShadow and self.mSub1Property ~= nil then
			self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x + self.mSub1Property.distance.x * percent
			self.mCalcDatas.sub1.pos.y = self.mSub1Property.startPos.y + self.mSub1Property.distance.y * percent
			self.mCalcDatas.sub1.rotation = 0
		end

		return
	end

	-- 所有其他方向走一样的逻辑
	if 1 > 0 then
		local printStr = function(part, speed, time, yMove)
			-- print('..........................................')
			-- print('curr part is:'..part..'   curr speedY:'..speed..'  curr time:'..time..' move Y:'..yMove)
		end

		local axesPosXMain = self.mMainProperty.axesRotated.endPos.x * percent
		local disXper = ParabolaDirCfg[self.mDirection].Distance_X_Percent
		local axesPosYMain = 0
		local currSpeedY = 0
		local isLeftPart = false
		if self.mDirection < FU_DIRECTION_ENUM.DIR_DOWN then isLeftPart = true end
		if self.mMainProperty.partType == ParabolaPartType.PartOne then
			axesPosYMain = self.mMainProperty.axesRotated.speedV0.y * self.mPastTime + 
				0.5 * self.mMainProperty.axesRotated.accelerationPart1.y * self.mPastTime * self.mPastTime
			currSpeedY = self.mMainProperty.axesRotated.speedV0.y + self.mMainProperty.axesRotated.accelerationPart1.y * self.mPastTime
			local positive = math.abs(currSpeedY)
			currSpeedY = isLeftPart and -positive or positive	
			if disXper <= percent then
				self.mMainProperty.partType = ParabolaPartType.PartTwo
				self.mMainProperty.axesRotated.highVertex.y = axesPosYMain
				self.mMainProperty.axesRotated.highVertex.x = axesPosXMain				
				currSpeedY = 0
				-- 重新计算加速度2
				local timePart2 = self.mCalcDatas.main.timePart2
				local accelerationPart2 = 2 * self.mMainProperty.axesRotated.highVertex.y / timePart2 / timePart2
				self.mMainProperty.axesRotated.accelerationPart2.y = math.abs(accelerationPart2)
			end
			printStr(self.mMainProperty.partType, currSpeedY, self.mPastTime, axesPosYMain)
		else
			local part2PastTime = self.mSpendTime * (percent - disXper)
			local moveGap = 0.5 * part2PastTime * part2PastTime * self.mMainProperty.axesRotated.accelerationPart2.y
			axesPosYMain = self.mMainProperty.axesRotated.highVertex.y - moveGap
			currSpeedY = part2PastTime * self.mMainProperty.axesRotated.accelerationPart2.y
			local positive = math.abs(currSpeedY)
			currSpeedY = isLeftPart and positive or -positive
			if percent >= 1 then
				axesPosYMain = 0
			end
			printStr(self.mMainProperty.partType, currSpeedY, self.mPastTime, axesPosYMain)
		end

		-- 终点
		-- if percent >= 1 then
		if 1<0 then
			self.mCalcDatas.main.pos.x = self.mMainProperty.endPos.x
			self.mCalcDatas.main.pos.y = self.mMainProperty.endPos.y
		else
			local axesRotatedPos = RAFU_Math:CalcPosAxesRotatedReverse(RACcp(axesPosXMain, axesPosYMain), self.mMainProperty.axesRotated.radian)
			local axesPos = RACcpAdd(self.mMainProperty.axesRotated.posGap, axesRotatedPos)
			self.mCalcDatas.main.pos = axesPos
		end

		-- rotation
		local currSpeedX = self.mMainProperty.speedV0.x		
		local rotation = RAFU_Math:CalcAngleBySpeedXY(currSpeedX, currSpeedY)
		rotation = rotation + self.mMainProperty.axesRotated.angle
		self.mCalcDatas.main.rotation = -rotation

		-- part type
		self.mCalcDatas.main.partType = self.mMainProperty.partType
		self.mCalcDatas.main.direction =self.mDirection
		self.mCalcDatas.sub2.rotation = self.mCalcDatas.main.rotation

		-- 计算影子位置，垂直方向上，影子匀速运动
		if isCalcShadow and self.mSub1Property ~= nil then
			self.mCalcDatas.sub1.pos.x = self.mCalcDatas.main.pos.x
			if self.mSub1Property.distance.x > 0 and self.mCalcDatas.sub1.pos.x < self.mSub1Property.startPos.x then
				self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x		
			end
			if self.mSub1Property.distance.x < 0 and self.mCalcDatas.sub1.pos.x > self.mSub1Property.startPos.x then
				self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x		
			end

			local x1 = self.mSub1Property.startPos.x
			local y1 = self.mSub1Property.startPos.y
			local x2 = self.mSub1Property.endPos.x
			local y2 = self.mSub1Property.endPos.y
			self.mCalcDatas.sub1.pos.y = (self.mCalcDatas.sub1.pos.x - x1)*(y2 - y1) / (x2 - x1) + y1

			self.mCalcDatas.sub1.rotation = -self.mAngle
		end
		return
	end
	self.mCalcDatas = nil
end


return RAFU_OribitCalc_CommonParabola
