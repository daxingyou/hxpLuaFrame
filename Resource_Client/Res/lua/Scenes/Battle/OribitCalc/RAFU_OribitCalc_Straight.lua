--[[
description: 直线类匀速移动轨迹计算
 

author: qinho
date: 2016/12/7
]]--


local RAFU_OribitCalc_Straight = class('RAFU_OribitCalc_Straight',{})
local Utilitys = RARequire('Utilitys')
local RAFU_Math = RARequire('RAFU_Math')
RARequire("RAFightDefine")

-- param = {
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
-- 	speed = speed
-- }

function RAFU_OribitCalc_Straight:ctor(param)
	self.mIsNewSuccess = false
	self.mIsInitCalc = false
	if not self:_CheckParam(param) then
		return
	end
	self.mIsNewSuccess = true 
	self.mMainProperty = {
		startPos = Utilitys.ccpCopy(param.position.main.startPos),
		endPos = Utilitys.ccpCopy(param.position.main.endPos),
		distance = {x = 0, y = 0, total = 0},
		speed = param.speed
	}
	self.mSub1Property = {
		startPos = Utilitys.ccpCopy(param.position.sub1.startPos),
		endPos = Utilitys.ccpCopy(param.position.sub1.endPos),
		distance = {x = 0, y = 0, total = 0},
		speed = 0
	}
	self.mSpeed = param.speed
	self.mSpendTime = 0
	
	self.mIsExecute = false

	self.mStartTime = 0
	self.mPastTime = 0

	-- calc angle base on shadow line
	self.mAngle = Utilitys.ccpAngle(self.mSub1Property.startPos, self.mSub1Property.endPos)
	self.mDirection = RAFU_Math:Get16DirectionByAngle(self.mAngle)

	-- self.mMainProperty.distance.x = math.abs(self.mMainProperty.startPos.x - self.mMainProperty.endPos.x)
	-- self.mMainProperty.distance.y = math.abs(self.mMainProperty.startPos.y - self.mMainProperty.endPos.y)
	self.mMainProperty.distance.total = Utilitys.getDistance(self.mMainProperty.startPos, self.mMainProperty.endPos)

	-- self.mSub1Property.distance.x = math.abs(self.mSub1Property.startPos.x - self.mSub1Property.endPos.x)
	-- self.mSub1Property.distance.y = math.abs(self.mSub1Property.startPos.y - self.mSub1Property.endPos.y)
	self.mSub1Property.distance.total = Utilitys.getDistance(self.mSub1Property.startPos, self.mSub1Property.endPos)

	self.mCalcDatas = {
		main = {
			pos = {x=0, y=0},
		},
		sub1 = {
			pos = {x=0, y=0},
		}
	}
	return true
end

function RAFU_OribitCalc_Straight:release()
	self.mMainProperty = nil
	self.mSub1Property = nil
	
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

function RAFU_OribitCalc_Straight:_CheckParam(param)
	local result = false
	if param ~= nil and param.position ~= nil then
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


function RAFU_OribitCalc_Straight:Begin()
    self.mIsExecute = true   
    local common = RARequire('common')
    self.mStartTime = common:getCurTime()
    self.mPastTime = 0
    self:_CalcInit()
    self:_CalcImmediately()
    return self:GetCalcDatas(), self.mSpendTime
end


-- calcData = {
-- 	main = {
-- 		pos = {x=x, y=y},
-- 	},
-- 	sub1 = {
-- 		pos = {x=x, y=y},
-- 	},
-- }
function RAFU_OribitCalc_Straight:GetCalcDatas()
	return self.mCalcDatas
end


function RAFU_OribitCalc_Straight:Execute(dt)
	if not self.mIsExecute then return end
	self.mPastTime = self.mPastTime + dt

	self:_CalcImmediately()
	return self:GetCalcDatas()
end

function RAFU_OribitCalc_Straight:_CalcInit()
	if not self.mIsInitCalc then
		self.mSpendTime = self.mMainProperty.distance.total / self.mMainProperty.speed
		self.mSub1Property.speed = self.mSub1Property.distance.total / self.mSpendTime
		self.mIsInitCalc = true
	end
end


-- calc and refresh data
function RAFU_OribitCalc_Straight:_CalcImmediately()
	if self.mSpendTime <= 0 or not self.mIsInitCalc then
		return
	end

	local percent = self.mPastTime / self.mSpendTime
	local isEnd = false
	if percent >= 1 then 
		percent = 1
		isEnd = true
		self.mPastTime = self.mSpendTime
	end 
	self.mCalcDatas.main.pos.x = (self.mMainProperty.endPos.x - self.mMainProperty.startPos.x) * percent + self.mMainProperty.startPos.x
	self.mCalcDatas.main.pos.y = (self.mMainProperty.endPos.y - self.mMainProperty.startPos.y) * percent + self.mMainProperty.startPos.y

	self.mCalcDatas.sub1.pos.x = (self.mSub1Property.endPos.x - self.mSub1Property.startPos.x) * percent + self.mSub1Property.startPos.x
	self.mCalcDatas.sub1.pos.y = (self.mSub1Property.endPos.y - self.mSub1Property.startPos.y) * percent + self.mSub1Property.startPos.y
end


return RAFU_OribitCalc_Straight