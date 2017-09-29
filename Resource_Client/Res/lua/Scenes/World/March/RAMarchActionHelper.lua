--RAMarchActionHelper
local RAMarchConfig = RARequire('RAMarchConfig')
local EnumManager = RARequire('EnumManager')

local RAMarchActionHelper = {}




-- 根据行军两点角度，获取方向类型
function RAMarchActionHelper:GetMarchDirectionByAngle(angle)
	local borderCfg = RAMarchConfig.AngleBorderCfg
	for dir,cfg in pairs(borderCfg) do
		local isInCfg = self:compareAngleWithCfg(angle, cfg.base, cfg.gapAdd, cfg.gapSub, cfg.isEqual)
		if isInCfg then
			return cfg.dir
		end
	end
	-- 错误
	print('RAMarchActionHelper:GetMarchDirectionByAngle handle error!! angle='..angle)
	return EnumManager.DIRECTION_ENUM.DIR_NONE
end



-- 检查一个点是否在配置对应的范围内
function RAMarchActionHelper:compareAngleWithCfg(angle, base, gapAdd, gapSub, isEqual)
	local addBorder = base + gapAdd
	local subBorder = base - gapSub	
	if angle < addBorder and angle > subBorder then
		return true
	end 
	if isEqual then
		if angle == addBorder or angle == subBorder then
			return true
		end
	end
	return false
end



-- 根据行军两点角度，获取16方向的值（按美术要求，0为向上:90度，4为向左:180，类推到15）
-- angle为笛卡尔坐标系，0为x轴方向，90为y轴方向
function RAMarchActionHelper:Get16DirectionByAngle(angle)
	local borderCfg = RAMarchConfig.ArmyMarchAniCfg
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
	print('RAMarchActionHelper:GetMarchDirectionByAngle handle error!! angle='..angle)
	return -1
end

function RAMarchActionHelper:_CompareAngleWith16DirCfg(angle, base, gapAdd, gapSub, addEqual, subEqual)
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

return RAMarchActionHelper