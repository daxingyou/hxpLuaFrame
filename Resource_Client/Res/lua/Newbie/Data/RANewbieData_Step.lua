--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieData_Step.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

local RANewbieData_Step = class('RANewbieData_Step',{})

local RANewbieConfig = RARequire('RANewbieConfig')
local newbie_step_conf = RARequire('newbie_step_conf')

function RANewbieData_Step:ctor(stepId)
	self.mStepId = 0
	self.mStepConfig = nil
	self.mIsInit = false
	self:_initSelf(stepId)
end


function RANewbieData_Step:_initSelf(stepId)
	local conf = newbie_step_conf[stepId]
	if conf == nil then return end
	self.mStepId = stepId
	self.mStepConfig = conf
	self.mIsInit = true
end

function RANewbieData_Step:GetIsInit()
	return self.mIsInit
end

function RANewbieData_Step:GetIntConfig(attrName)
	if self.mIsInit then
		return self.mStepConfig[attrName]
	end
	return 0
end

function RANewbieData_Step:GetBoolConfig(attrName)
	if self.mIsInit then
		if self.mStepConfig[attrName] == 0 then
			return false
		else
			return true
		end
	end
	return false
end

function RANewbieData_Step:GetStringConfig(attrName)
	if self.mIsInit then
		return self.mStepConfig[attrName]
	end
	return ''
end

function RANewbieData_Step:SetStepIndex(index)
	self.mIndex = index
end

function RANewbieData_Step:GetStepIndex()
	return self.mIndex
end

return RANewbieData_Step