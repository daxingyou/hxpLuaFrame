--[[
description: 战斗单元数学基础类

author: zhenhui
date: 2016/11/22
]]--
RARequire("RAFightDefine")
local RAFU_Math = {}

--计算转向需要的次数，以22.5度移动为基础
function RAFU_Math:calcDirTurnTimes(fromDir,toDir)
	-- body
	local dirDelta = math.abs(toDir - fromDir);
	if dirDelta > DIRECTION_COUNT / 2 then
		dirDelta = DIRECTION_COUNT - dirDelta;
	end
	return dirDelta;
end

--计算以半径和角度为输入的，xy坐标
function RAFU_Math:calcOffsetByAngle(angle,radius)
	local posx = radius * math.cos(math.rad(angle))
	local posy = radius * math.sin(math.rad(angle))
	return RACcp(posx,posy)
end


--计算从当前位置到下一个位置移动的方向  8方向
function RAFU_Math:calcMoveDir(from,to)
	local dir = FU_DIRECTION_ENUM.NONE

	if from.x < to.x then
		if from.y < to.y then
			dir = FU_DIRECTION_ENUM.DIR_DOWN
		elseif from.y == to.y then
			dir = FU_DIRECTION_ENUM.DIR_DOWN_RIGHT
		else
			dir = FU_DIRECTION_ENUM.DIR_RIGHT
		end
	elseif from.x == to.x then
		if from.y < to.y then
			dir = FU_DIRECTION_ENUM.DIR_DOWN_LEFT
		elseif from.y == to.y then
			dir = FU_DIRECTION_ENUM.DIR_NONE
		else
			dir = FU_DIRECTION_ENUM.DIR_UP_RIGHT
		end
	else
		if from.y < to.y then
			dir = FU_DIRECTION_ENUM.DIR_LEFT
		elseif from.y == to.y then
			dir = FU_DIRECTION_ENUM.DIR_UP_LEFT
		else
			dir = FU_DIRECTION_ENUM.DIR_UP
		end
	end

	return dir 
end



-- 根据行军两点角度，获取16方向的值（按美术要求，0为向上:90度，4为向左:180，类推到15）
-- angle为笛卡尔坐标系，0为x轴方向，90为y轴方向
function RAFU_Math:Get16DirectionByAngle(angle)
	local borderCfg = DIRECTION_16_ANGLE_DEFINE
	for dir,cfg in pairs(borderCfg) do
		local baseTb = cfg.base
		for _,baseAngle in pairs(baseTb) do
			local isInCfg = self:_CompareAngleWith16DirCfg(angle, baseAngle, cfg.gapAdd, cfg.gapSub, cfg.addEqual, cfg.subEqual)
			if isInCfg then
				return cfg.dir
			end
		end
	end
	-- 错误
	print('RAFU_Math:Get16DirectionByAngle handle error!! angle='..angle)
	return -1
end

function RAFU_Math:_CompareAngleWith16DirCfg(angle, base, gapAdd, gapSub, addEqual, subEqual)
	local addBorder = base + gapAdd
	local subBorder = base - gapSub	
	if angle < addBorder and angle > subBorder then
		return true
	end 
	if addEqual and angle == addBorder then
		return true
	end
	if subEqual and angle == subBorder then
		return true
	end
	return false
end

--获得两点之间和 （1,0)向量的夹角
function RAFU_Math:getDegreeBetween(orginPoint,targetPoint)
	local vecX = targetPoint.x - orginPoint.x
    local vecY = targetPoint.y - orginPoint.y
    local orX = 1
    local orY = 0
    local cos = (orX*vecX + orY*vecY)/(math.sqrt(orX*orX+orY*orY)*math.sqrt(vecX*vecX + vecY*vecY))
    local deg = math.acos(cos)

    if vecY < 0 then 
    	deg = -deg
    end  

    return deg
end

-- 计算经过时间的百分比
function RAFU_Math:CalcPastTimePercent(pastTime, totalTime)
	if pastTime <= 0 or totalTime <= 0 then return 0 end
	local percent = pastTime / totalTime
	if percent >= 1 then 
		percent = 1		
	end 
	return percent
end



-- 根据初始速度、加速度、时间，计算走过的距离
function RAFU_Math:CalcDistanceByV0_A_T(v0, a, t)		
	local s = 0
	s = v0 * t + 0.5 * a * t * t
	return s
end


-- 根据坐标、旋转弧度（逆时针方向0-360），计算转换后的坐标系
function RAFU_Math:CalcPosAxesRotated(pos, radian)		
	local rotatedPos = RACcp(0, 0)
	local sinR = math.sin(radian)
	local cosR = math.cos(radian)
	local format = function(number)
		local result = string.format('%.4f', number)
		return tonumber(result)
	end
	--sinR = format(sinR)
	--cosR = format(cosR)
	rotatedPos.x = pos.x * cosR + pos.y * sinR
	rotatedPos.y = pos.y * cosR - pos.x * sinR
	rotatedPos.x = format(rotatedPos.x)
	rotatedPos.y = format(rotatedPos.y)
	return rotatedPos
end

-- 根据坐标、旋转弧度（顺时针方向0-360），计算转换后的坐标系
function RAFU_Math:CalcPosAxesRotatedReverse(pos, radian)		
	local rotatedPos = RACcp(0, 0)
	local sinR = math.sin(radian)
	local cosR = math.cos(radian)
	local format = function(number)
		local result = string.format('%.4f', number)
		return tonumber(result)
	end
	--sinR = format(sinR)
	--cosR = format(cosR)
	rotatedPos.x = pos.x * cosR - pos.y * sinR
	rotatedPos.y = pos.y * cosR + pos.x * sinR
	rotatedPos.x = format(rotatedPos.x)
	rotatedPos.y = format(rotatedPos.y)
	return rotatedPos
end


-- 根据x和y轴速度，计算当前切线与x轴的角度
function RAFU_Math:CalcAngleBySpeedXY(speedX, speedY)
	local Utilitys = RARequire('Utilitys')
	local angle = Utilitys.getDegree(speedX, speedY)
	return angle
end


return RAFU_Math