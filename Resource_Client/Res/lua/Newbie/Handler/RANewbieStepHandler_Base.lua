--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieStepHandler_Base.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

local RANewbieStepHandler_Base = class('RANewbieStepHandler_Base',{})

function RANewbieStepHandler_Base:ctor(stepData)
	self.mTargetNode = nil
	
	self.mTargetCallBack = nil
	self.mTargetPos = nil
	self.mTargetSize = nil

	self.mTargetPreCallBack = nil

	-- kv格式，key为messageId，value为回调
	self.mMessageTable = nil

	self.mIsMessageOK = false
	self.mIsParamOK = false

	self:Enter()
end

function RANewbieStepHandler_Base:Enter()
	self:selfInit()
end

-- 子类实现的方法，用于初始化数据
function RANewbieStepHandler_Base:selfInit()
	
end

function RANewbieStepHandler_Base:Exit()
	self.mTargetNode = nil
	
	self.mTargetCallBack = nil
	self.mTargetPos = nil
	self.mTargetSize = nil
	
	self.mTargetPreCallBack = nil
	
	self.mMessageTable = nil

	self.mIsMessageOK = false
	self.mIsParamOK = false

	self:unRegisterMessageHandler()
	self:selfExit()
end

-- 子类实现的方法，用于退出清理
function RANewbieStepHandler_Base:selfExit()
	
end

function RANewbieStepHandler_Base:registerMessageHandler(callBack)
	if not self.mIsMessageOK or not self.mMessageTable then return end
	for k,v in pairs(self.mMessageTable) do
		MessageManager.registerMessageHandler(k, v)
	end
end

function RANewbieStepHandler_Base:unRegisterMessageHandler()
	if self.mMessageTable then
		for k,v in pairs(self.mMessageTable) do
			MessageManager.removeMessageHandler(k, v)
		end		
	end
	self.mMessageTable = nil
end

-- 子类型需要重写，
-- 用于监听消息
function RANewbieStepHandler_Base:prepareMessageNecessary()
end

-- 供子类调用，准备需要注册的message完毕后调用
function RANewbieStepHandler_Base:prepareMessageEnd()
	self:registerMessageHandler()
end

-- 子类型需要重写，用于各自准备参数，
-- 例如发送消息告诉GuidePage进行更新。
function RANewbieStepHandler_Base:prepareParamNecessary()
end

-- 供子类调用，准备好需要的参数后调用，	
-- 会通知GuidePage进行更新	
function RANewbieStepHandler_Base:prepareParamEnd()
	if self.mTargetPreCallBack ~= nil then
		self.mTargetPreCallBack()
	end
	self.mIsParamOK = true
end

-- 执行回调之前会调用的方法，各个子类需要各自实现，
-- 返回bool值，如果true则执行回调；false不执行
function RANewbieStepHandler_Base:beforeCallBackHandle()
	return false
end

-- 回调执行完毕后调用的方法，
-- 需要子类根据自身情况自行实现逻辑
function RANewbieStepHandler_Base:afterCallBackHandle()

end

-- 会调用beforeCallBackHandle进行检查，
-- 然后执行call back，
-- 最后执行afterCallBackHandle
function RANewbieStepHandler_Base:excuteStepLogic()
	if not self.mIsParamOK then return false end
	if self:beforeCallBackHandle() then
		if self.mTargetCallBack ~= nil then
			self.mMessageTable()
		end
		self:afterCallBackHandle()
		return true
	end
	return false
end

return RANewbieStepHandler_Base