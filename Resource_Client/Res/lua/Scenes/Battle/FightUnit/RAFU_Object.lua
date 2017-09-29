--[[
description: 战斗单元 纯虚类定义
每个子类必须重写对应的方法
author: zhenhui
date: 2016/12/9
]]--


local RAFU_Object = class('RAFU_Object',{})


function RAFU_Object:ctor(...)
	RALog("Please rewrite")
end

function RAFU_Object:release()
	RALog("Please rewrite")
end

function RAFU_Object:Enter()
    RALog("Please rewrite")
end

function RAFU_Object:Execute(dt)
  	RALog("Please rewrite")
end

function RAFU_Object:Exit()
    RALog("Please rewrite")
end

function RAFU_Object:SetIsExecute(value)
	self.mIsExecute = value
end

-- 默认为false，需要execute的单元或者类，自行注册
function RAFU_Object:GetIsExecute()
	return self.mIsExecute or false
end

return RAFU_Object;