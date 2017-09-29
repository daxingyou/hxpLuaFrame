--[[
description: 斜抛类移动轨迹计算
  例如，坦克的发射体

author: qinho
date: 2016/12/7
]]--

local RAFU_OribitCalc_Parabola = class('RAFU_OribitCalc_Parabola',{})
local Utilitys = RARequire('Utilitys')
local RAFU_Math = RARequire('RAFU_Math')
RARequire("RAFightDefine")

local ParabolaCfg = RARequire('RAFU_Cfg_OribitCalc_Parabola').ParabolaCfg


local ParabolaPartType = 
{
	PartOne = 1,
	PartTwo = 2,
	PartThree = 3,
}

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

function RAFU_OribitCalc_Parabola:ctor(param)
	self.mIsNewSuccess = false
	self.mIsInitCalc = false
	if not self:_CheckParam(param) then
		return
	end
	self.mIsNewSuccess = true 
	self.mMainProperty = {
		startPos = Utilitys.ccpCopy(param.position.main.startPos),
		endPos = Utilitys.ccpCopy(param.position.main.endPos),
		speedV0 = {x = 0, y = 0},
		speedVt = {x = 0, y = 0},
		distance = {x = 0, y = 0, total = 0},
		accelerationPart1 = {x = 0, y = 0},
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
	self.mSub1Property = { 
		startPos = Utilitys.ccpCopy(param.position.sub1.startPos),
		endPos = Utilitys.ccpCopy(param.position.sub1.endPos),
		speedV0 = {x = 0, y = 0},
		speedVt = {x = 0, y = 0},
		distance = {x = 0, y = 0, total = 0},
		accelerationPart1 = {x = 0, y = 0},
	}
	self.mSpeed = param.speed
	self.mPixelDistance = param.pixelDistance
	self.mSpendTime = param.spendTime
	
	self.mIsExecute = false

	self.mStartTime = 0
	self.mPastTime = 0

	-- calc angle base on shadow line
	self.mAngle = Utilitys.ccpAngle(self.mSub1Property.startPos, self.mSub1Property.endPos)
	self.mDirection = RAFU_Math:Get16DirectionByAngle(self.mAngle)

	self.mMainProperty.distance.x = self.mMainProperty.endPos.x - self.mMainProperty.startPos.x
	self.mMainProperty.distance.y = self.mMainProperty.endPos.y - self.mMainProperty.startPos.y
	self.mMainProperty.distance.total = Utilitys.getDistance(self.mMainProperty.startPos, self.mMainProperty.endPos)

	self.mSub1Property.distance.x = self.mSub1Property.endPos.x - self.mSub1Property.startPos.x
	self.mSub1Property.distance.y = self.mSub1Property.endPos.y - self.mSub1Property.startPos.y
	self.mSub1Property.distance.total = Utilitys.getDistance(self.mSub1Property.startPos, self.mSub1Property.endPos)

	self.mCalcDatas = {
		main = {
			pos = {x=0, y=0},
		},
		sub1 = {
			pos = {x=0, y=0},
		}
	}
end

function RAFU_OribitCalc_Parabola:release()	
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

function RAFU_OribitCalc_Parabola:_CheckParam(param)
	local result = false
	if param ~= nil and param.position ~= nil and param.spendTime > 0 then
		if param.position.main ~= nil and param.position.sub1 ~= nil and param.speed > 0 then
			local isMainSame = Utilitys.checkIsPointSame(param.position.main.startPos, param.position.main.endPos)
			local isSub1Same = Utilitys.checkIsPointSame(param.position.sub1.startPos, param.position.sub1.endPos)
			if not isMainSame and not isSub1Same then
				result = true
			end
		end
	end
	return result
end

function RAFU_OribitCalc_Parabola:Begin()
    self.mIsExecute = true   
    local common = RARequire('common')
    self.mStartTime = common:getCurTime()
    self.mPastTime = 0
    self:_CalcInit()
    self:_CalcImmediately()
    print('RAFU_OribitCalc_Parabola:Begin   angle:'..self.mAngle..' direction:'..self.mDirection)
    return self:GetCalcDatas()
end


-- calcData = {
-- 	main = {
-- 		pos = {x=x, y=y},
-- 	},
-- 	sub1 = {
-- 		pos = {x=x, y=y},
-- 	},
-- }
function RAFU_OribitCalc_Parabola:GetCalcDatas()
	return self.mCalcDatas
end


function RAFU_OribitCalc_Parabola:Execute(dt)
	if not self.mIsExecute then return end
	self.mPastTime = self.mPastTime + dt

	self:_CalcImmediately()
	return self:GetCalcDatas()
end

function RAFU_OribitCalc_Parabola:_CalcInit()
	
	if not self.mIsInitCalc then
		-- 垂直向上
		-- 垂直向上时，初始状态子弹快于影子，所以子弹做匀减速、影子做匀加速		
		-- 会预设置炮弹的初始速度和最终速度
		-- 然后计算出总飞行时间、炮弹加速度，然后计算影子的结束速度、加速度
		if self.mDirection == FU_DIRECTION_ENUM.DIR_UP then		
			-- calc main
			local initVSelf = ParabolaCfg[self.mDirection].Speed_Y_Init_V_Main
			self.mMainProperty.speedV0.y = initVSelf
			self.mMainProperty.speedVt.y = 2 * self.mMainProperty.distance.y / self.mSpendTime - initVSelf			
			-- main accelerationPart1 speed
			self.mMainProperty.accelerationPart1.y = (self.mMainProperty.speedVt.y - self.mMainProperty.speedV0.y) / self.mSpendTime

			-- calc sub1
			local initVSub1 = ParabolaCfg[self.mDirection].Speed_Y_Init_V_Sub1
			self.mSub1Property.speedV0.y = initVSub1
			self.mSub1Property.speedVt.y = 2 * self.mSub1Property.distance.y / self.mSpendTime - initVSub1			
			-- sub1 accelerationPart1 speed
			self.mSub1Property.accelerationPart1.y = (self.mSub1Property.speedVt.y - self.mSub1Property.speedV0.y) / self.mSpendTime

			self.mIsInitCalc = true
			return
		end

		-- 垂直向下
		-- 垂直向下时，初始状态影子快于子弹，所以子弹做匀加速、影子做匀减速
		-- 为保证和垂直向上的效果一致，需要预设置影子的初始速度和最终速度，这样同距离下飞行的时间会更相似
		-- 然后计算出总飞行时间、影子加速度，然后计算炮弹的结束速度、加速度
		if self.mDirection == FU_DIRECTION_ENUM.DIR_DOWN then

			-- calc main
			local initVSelf = ParabolaCfg[self.mDirection].Speed_Y_Init_V_Main
			self.mMainProperty.speedV0.y = initVSelf
			self.mMainProperty.speedVt.y = 2 * self.mMainProperty.distance.y / self.mSpendTime - initVSelf			
			-- main accelerationPart1 speed
			self.mMainProperty.accelerationPart1.y = (self.mMainProperty.speedVt.y - self.mMainProperty.speedV0.y) / self.mSpendTime

			-- calc sub1
			local initVSub1 = ParabolaCfg[self.mDirection].Speed_Y_Init_V_Sub1
			self.mSub1Property.speedV0.y = initVSub1
			self.mSub1Property.speedVt.y = 2 * self.mSub1Property.distance.y / self.mSpendTime - initVSub1			
			-- sub1 accelerationPart1 speed
			self.mSub1Property.accelerationPart1.y = (self.mSub1Property.speedVt.y - self.mSub1Property.speedV0.y) / self.mSpendTime

			self.mIsInitCalc = true
			return
		end

		-- if self.mDirection == FU_DIRECTION_ENUM.DIR_RIGHT or 
		-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT or
		-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_RIGHT or
		-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT then
		if 1 > 0 then
			-- calc main

			self.mMainProperty.partType = ParabolaPartType.PartOne			
			
			local initVSelf = ParabolaCfg[self.mDirection].Speed_Y_Init_V_Main
			local disXper = ParabolaCfg[self.mDirection].Distance_X_Percent
			-- local tmp1 = RACcp(1,1)
			-- local tmp2 = RACcp(2,2)
			-- local angle, radian = Utilitys.ccpAngle(tmp1, tmp2)
			-- self.mMainProperty.axesRotated.angle = angle
			-- self.mMainProperty.axesRotated.radian = radian
			-- self.mMainProperty.axesRotated.startPos = RAFU_Math:CalcPosAxesRotated(tmp1, radian)
			-- self.mMainProperty.axesRotated.endPos = RAFU_Math:CalcPosAxesRotated(tmp2, radian)

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

			-- sub1 no need to calc
		end
	end
end

-- calc and refresh data
function RAFU_OribitCalc_Parabola:_CalcImmediately()
	if self.mSpendTime <= 0 and not self.mIsInitCalc then
		return
	end

	local percent = RAFU_Math:CalcPastTimePercent(self.mPastTime, self.mSpendTime)

	-- 垂直向上和向下的逻辑相似
	-- 根据距离和时间算出的速度值为终点速度vt，另已知距离s、时间t
	-- 垂直向上时，初始状态子弹快于影子，所以子弹做匀减速、影子做匀加速		
	-- 垂直向下时，初始状态影子快于子弹，所以子弹做匀加速、影子做匀减速	
	-- 计算时，先根据炮弹的初始和结束速度，计算出总飞行时间、加速度，然后计算影子的结束速度、加速度
	-- 水平方向做匀速移动
	if self.mDirection == FU_DIRECTION_ENUM.DIR_UP or 
		self.mDirection == FU_DIRECTION_ENUM.DIR_DOWN then		
		self.mCalcDatas.main.pos.x = self.mMainProperty.startPos.x + self.mMainProperty.distance.x * percent
		local mainMoveY = RAFU_Math:CalcDistanceByV0_A_T(self.mMainProperty.speedV0.y, self.mMainProperty.accelerationPart1.y, self.mPastTime)
		self.mCalcDatas.main.pos.y = self.mMainProperty.startPos.y + mainMoveY

		self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x + self.mSub1Property.distance.x * percent
		local sub1MoveY = RAFU_Math:CalcDistanceByV0_A_T(self.mSub1Property.speedV0.y, self.mSub1Property.accelerationPart1.y, self.mPastTime)		
		self.mCalcDatas.sub1.pos.y = self.mSub1Property.startPos.y + sub1MoveY
		return
	end

	-- if self.mDirection == FU_DIRECTION_ENUM.DIR_RIGHT or 
	-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT or
	-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_RIGHT or
	-- 	self.mDirection == FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT then
	if 1 > 0 then
		local axesPosXMain = self.mMainProperty.axesRotated.endPos.x * percent
		local disXper = ParabolaCfg[self.mDirection].Distance_X_Percent
		local axesPosYMain = 0
		if disXper > percent then
			axesPosYMain = self.mMainProperty.axesRotated.speedV0.y * self.mPastTime + 
				0.5 * self.mMainProperty.axesRotated.accelerationPart1.y * self.mPastTime * self.mPastTime
		else
			if self.mMainProperty.partType == ParabolaPartType.PartOne then
				self.mMainProperty.partType = ParabolaPartType.PartTwo
				axesPosYMain = self.mMainProperty.axesRotated.highVertex.y
				axesPosXMain = self.mMainProperty.axesRotated.highVertex.x
			elseif self.mMainProperty.partType == ParabolaPartType.PartTwo then
				local moveGap = 0.5 * self.mSpendTime *  self.mSpendTime * (percent - disXper) * (percent - disXper) * self.mMainProperty.axesRotated.accelerationPart2.y
				axesPosYMain = self.mMainProperty.axesRotated.highVertex.y - moveGap
			end
		end

		-- axesPosXMain = 0
		-- axesPosYMain = 0

		local axesRotatedPos = RAFU_Math:CalcPosAxesRotatedReverse(RACcp(axesPosXMain, axesPosYMain), self.mMainProperty.axesRotated.radian)
		local axesPos = RACcpAdd(self.mMainProperty.axesRotated.posGap, axesRotatedPos)
		self.mCalcDatas.main.pos = axesPos

		self.mCalcDatas.sub1.pos.x = axesPos.x
		if self.mSub1Property.distance.x > 0 and axesPos.x < self.mSub1Property.startPos.x then
			self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x		
		end
		if self.mSub1Property.distance.x < 0 and axesPos.x > self.mSub1Property.startPos.x then
			self.mCalcDatas.sub1.pos.x = self.mSub1Property.startPos.x		
		end

		local x1 = self.mSub1Property.startPos.x
		local y1 = self.mSub1Property.startPos.y
		local x2 = self.mSub1Property.endPos.x
		local y2 = self.mSub1Property.endPos.y
		self.mCalcDatas.sub1.pos.y = (self.mCalcDatas.sub1.pos.x - x1)*(y2 - y1) / (x2 - x1) + y1
		return
	end
	self.mCalcDatas = nil
end


return RAFU_OribitCalc_Parabola
