-- RAActionManager

local EnterFrameDefine = RARequire('EnterFrameDefine')
local RALogicUtil = RARequire('RALogicUtil')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RAActionConfig = RARequire('RAActionConfig')
local common = RARequire("common")


local RAActionManager = {}

-- 数字滚动动画
local RANumLabelChangeAction = nil
function RAActionManager:CreateNumLabelChangeAction(duration, beginNum, endNum, isNum2K, countAfterDot,prefix)
	local action = RANumLabelChangeAction:new()
	action:initWithDuration(duration, beginNum, endNum, isNum2K, countAfterDot,prefix)
	return action
end


-- ccb动画容器
local RACCBAnimationContainer = nil
function RAActionManager:CreateCCBAnimationContainer(target, ccbName, containerName, aniName, callBack, endAni)
	local container = RACCBAnimationContainer:new()
	container:initWithTarget(target, ccbName, containerName)
	container:initAnimationParams(aniName, callBack, endAni)	
	return container
end

-- 移动node动画
local RAMoveToAction = nil
function RAActionManager:CreateMoveToAction(target, duration, beginPos, endPos)
	local action = RAMoveToAction:new()
	action:initWithDuration(duration, beginPos, endPos)
	if target ~= nil then
		action:startWithTarget(target)
	end
	return action
end

-- 格子形式进度条
local RAGridProcessBarAction = nil
function RAActionManager:CreateGridProcessBarAction(target, variblePrefix, startIndex, endIndex, picName)
    local action = RAGridProcessBarAction:new()
    action:initWithDuration(variblePrefix, startIndex, endIndex, picName)
    if target then
        action:startWithTarget(target)
    end
    return action;
end

-- 进度条动画
local RAScale9SpriteChangeAction = nil
function RAActionManager:CreateScale9SpriteChangeAction(duration, beginScale, endScale)
	local action = RAScale9SpriteChangeAction:new()
	action:initWithDuration(duration, beginScale, endScale)
	return action
end

RAGridProcessBarAction = {
    new = function(self, o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    EnterFrame = function(self)
        if self.mTarget ~= nil then
			local frameTime = GamePrecedure:getInstance():getFrameTime()
			self.mTime = self.mTime + frameTime
			local isExit = false
            local canChange = false
			if self.mTime >= 0.1 then
				canChange = true
                self.mTime = 0
			end

            if canChange then
                local name = self.variblePrefix .. self.currentIndex
                UIExtend.setNodeVisible(self.mTarget, name, true)
                UIExtend.setSpriteIcoToNode(self.mTarget, name, self.picName)
                self.currentIndex = self.currentIndex + 1   
                if self.currentIndex > self.endIndex then
                    isExit = true
                end
            end

			
			if isExit then
				self:ClearAction()
			end
		else
			self:ClearAction()
		end
    end,

    ClearAction = function(self)
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_RAGridProcessBarAction, self)
		self:exit()
	end,

    -- private functions
	getActionName = function(self)
		return 'RAGridProcessBarAction'
	end,

	initWithDuration = function(self, variblePrefix, startIndex, endIndex, picName)
		self.variblePrefix = variblePrefix
		self.startIndex = startIndex
		self.endIndex = endIndex
		self.picName = picName
        self.currentIndex = startIndex
	end,

    startWithTarget = function(self, target)
		self.mTarget = target
		if self.mTarget ~= nil and (self.startIndex <= self.endIndex) then
            self.mTime = 0
			EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Action.EF_RAGridProcessBarAction, self)
		end
	end,

    exit = function(self)
		CCLuaLog('RAGridProcessBarAction exit')
		self.mTarget = nil
		self.variblePrefix = nil
		self.startIndex = 0
		self.endIndex = 0
		self.picName = nil
        self.currentIndex = 0
	end
}

RANumLabelChangeAction = {
	--public functions
	new = function(self, o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
	end,

	EnterFrame = function(self)
		if self.mTarget ~= nil then
			local frameTime = GamePrecedure:getInstance():getFrameTime()
			local currSpendTime = self.mTime + frameTime
			local isExit = false
			local num2show = nil
			local numStr = nil
			if currSpendTime >= self.mDuration then
				-- time over
				num2show = self.mEndNum
				isExit = true
			else
				num2show = self.mBeginNum + (self.mEndNum - self.mBeginNum) * (currSpendTime / self.mDuration)
			end

			if self.mIsNum2K then
				numStr = RALogicUtil:num2k(num2show, self.countAfterDot)
			else
				numStr = RALogicUtil:numCutAfterDot(num2show, self.countAfterDot)
			end

            if not self.mIsNum2K and self.countAfterDot == 0 then
                numStr = common:commaSeperate(numStr)
            end

            numStr=self.prefix..numStr
			self.mTarget:setString(numStr)
			
			if isExit then
				self:ClearAction()
			else
				self.mTime = currSpendTime
			end
		else
			self:ClearAction()
		end
	end,

	ClearAction = function(self)
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_NumLabelChangeAction, self)
		self:exit()
	end,

	-- private functions
	getActionName = function(self)
		return 'RALabelChangeAction'
	end,

	initWithDuration = function(self, duration, beginNum, endNum, isNum2K, countAfterDot,prefix)
		self.mDuration = duration
		self.mBeginNum = beginNum
		self.mEndNum = endNum
		self.mIsNum2K = isNum2K or false
		if countAfterDot == nil or countAfterDot < 0 then
			countAfterDot = 1
		end
		self.countAfterDot = countAfterDot
		if prefix == nil then
			prefix = ""
		end 
		self.prefix = prefix
	end,

	startWithTarget = function(self, target)
		self.mTarget = nil
		local classObj = tolua.cast(target:getClass(), "CCClass")
		local className
		if classObj ~= nil then
			className = classObj:getName()
		end
		if className ~= nil then
			-- ttf CCLabelTTF
			if className == "CCLabelTTF" then
				local ttf = tolua.cast(target, "CCLabelTTF")
				if ttf ~= nil then
					self.mTarget = ttf
				end
			end
		end

		if self.mTarget ~= nil then
			EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Action.EF_NumLabelChangeAction, self)
			self.mTime = 0
		end
	end,

	exit = function(self)
		CCLuaLog('RANumLabelChangeAction exit')
		self.mTarget = nil
		self.mDuration = 0
		self.mBeginNum = 0
		self.mEndNum = 0
		self.mIsNum2K = false
		self.mTime = 0
	end
}


RACCBAnimationContainer = {
	-- propertys
	mTarget = nil,						-- 动作目标node
	mTargetOriPos = {x = 0, y = 0},		-- 动作目标node原始位置
	mTargetParent = nil,

	mAniCCBName = "",					-- 动作ccb名字	
	mContainerName = "",				-- 动作ccb添加target的容器名

	mAniName = "",
	mAniCallBack = nil,
	mCallBackHandler = nil,
	mEndAni = "",
	--public functions
	new = function(self, o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
	end,
	initWithTarget = function(self, target, ccbName, containerName)
		if target == nil then
			return false
		end
		self.mTarget = target		
		self.mAniCCBName = ccbName
		self.mContainerName = containerName

		local ccbfile = UIExtend.loadCCBFileWithOutPool(self.mAniCCBName, self)
		if ccbfile == nil then return false end
		return true
	end,

	initAnimationParams = function(self, aniName, callBack, endAni)
		self.mAniName = aniName
		-- 最后一个时间轴的名字，默认和第一个一样
		self.mEndAni = endAni or self.mAniName
		self.mAniCallBack = callBack
	end,

	setAniCallBackHandler = function(self, handler)
		self.mCallBackHandler = handler
	end,

	beginAni = function(self)
		if self.mTarget == nil then return false end
		if self.ccbfile == nil then return false end
		local container = UIExtend.getCCNodeFromCCB(self.ccbfile, self.mContainerName)
		if container == nil then return false end

		-- 转移target
		local x, y = self.mTarget:getPosition()
		self.mTargetOriPos.x = x
		self.mTargetOriPos.y = y
		self.mTargetParent = self.mTarget:getParent()
		self.mTarget:retain()
		self.mTarget:removeFromParentAndCleanup(false)

		self.mTarget:setPosition(0, 0)
		container:addChild(self.mTarget)
		self.mTarget:release()

		self.ccbfile:setPosition(self.mTargetOriPos.x, self.mTargetOriPos.y)
		self.mTargetParent:addChild(self.ccbfile)

		self.ccbfile:runAnimation(self.mAniName)
		return true
	end,

	OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()           
        local isEnd = false
    	if lastAnimationName == self.mEndAni then
    		isEnd = true
    		self:revertTarget()
    	end
	    if self.mAniCallBack then	    	
	    	self.mAniCallBack(lastAnimationName, ccbfile, isEnd)
	    end
	    if self.mCallBackHandler and self.mCallBackHandler.onCCBContainerCallBack then
	    	self.mCallBackHandler:onCCBContainerCallBack(lastAnimationName, ccbfile, isEnd)
	    end
	    if isEnd then
	    	self:exit()
	    end
    end,
    --还原目标
    revertTarget = function(self)
    	CCLuaLog('RACCBAnimationContainer revertTarget')
    	local x, y = self.mTarget:getPosition()
		local pos = ccp(x, y)
		local currWorldPos = self.mTarget:getParent():convertToWorldSpaceAR(pos)
		local oriLocalPos = self.mTargetParent:convertToNodeSpaceAR(currWorldPos)

		-- target 复位
		self.mTarget:retain()
		self.mTarget:removeFromParentAndCleanup(false)
		self.mTarget:setPosition(oriLocalPos)
		self.mTargetParent:addChild(self.mTarget)
		self.mTarget:release()
    end,
	exit = function(self)
		CCLuaLog('RACCBAnimationContainer exit')
		self.mTarget = nil
		self.mTargetOriPos = {x = 0, y = 0}
		self.mAniCCBName = ""
		self.mContainerName = ""
		self.mAniName = ""
		self.mAniCallBack = nil
		self.mEndAni = ""

		UIExtend.unLoadCCBFile(self)
	end
}





-- 移动的动画
RAMoveToAction = {	
	--public functions
	new = function(self, o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		o.mTarget = nil
		-- 总持续时间
		o.mDuration = 0
		o.mBeginPos = nil
		o.mEndPos = nil
		-- 上次刷新时间
		o.mLastUpdateTime = 0
		-- 已经移动了的时间
		o.mMovedTime = 0

		o.mIsActing = false

		o.mHandler = nil
		return o
	end,

	-- called by EnterFrameMananger
	EnterFrame = function(self)
		if self.mTarget ~= nil then
			self.mIsActing = true
			local frameTime = GamePrecedure:getInstance():getFrameTime()
			local currMovedTime = self.mMovedTime + frameTime
			local isExit = false
			
			local xFrameEnd = 0
			local yFrameEnd = 0
			
			if currMovedTime >= self.mDuration then				
				isExit = true
				xFrameEnd = self.mEndPos.x
				yFrameEnd = self.mEndPos.y
			else
				-- 计算当前动画后的位置
				local currPosX, currPosY = self.mTarget:getPosition()
				local xGapDis = self.mEndPos.x - self.mBeginPos.x
				local yGapDis = self.mEndPos.y - self.mBeginPos.y
				local percent = frameTime / self.mDuration
				local xFrameDelta = xGapDis * percent 
				local yFrameDelta = yGapDis * percent
				xFrameEnd = currPosX + xFrameDelta
				yFrameEnd = currPosY + yFrameDelta
			end
			local common = RARequire('common')	
			if common:isNaN(xFrameEnd) or common:isNaN(yFrameEnd) then
                RACcpPrint({x = xFrameEnd, y = yFrameEnd})
                -- print(debug.traceback())
                xFrameEnd = currPosX
                yFrameEnd = currPosY
            end  
			self.mTarget:setPosition(xFrameEnd, yFrameEnd)
			
			if isExit then				
				self:ClearAction(RAActionConfig.MoveToCallBackType.NormalEnd)
			else
				self.mMovedTime = currMovedTime
			end
		else
			self:ReleaseAction()
		end
	end,

	RegisterHandler = function(self, handler)
		if type(handler) == 'table' then
			self.mHandler = nil
			self.mHandler = handler
		end
	end,

	-- 如果当前已经在播放的话调用这个方法，更新动作的参数同时直接重新计算动画
	UpdateActionParam = function(self, duration, endPos, beginPos)
		-- self:ClearAction(RAActionConfig.MoveToCallBackType.ParamsErrorEnd)
		-- self:initWithDuration(duration, beginPos, endPos)
		if self.mTarget == nil then
			print('RAMoveToAction UpdateActionParam mTarget error!! ')
			return false
		end
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_MoveToAction, self)
		self.mIsActing = false

		local currPosX, currPosY = self.mTarget:getPosition()		
		self.mBeginPos = RACcp(currPosX,currPosY)
		self.mMovedTime = 0
		self.mLastUpdateTime = 0		
		
		local endPosTmp, isEndPtOK = Utilitys.checkIsPoint(endPos)
		if not isEndPtOK then
			print('RAMoveToAction UpdateActionParam endPos error!! endPos:')
			print(endPos)
			return false
		end
		self.mEndPos = Utilitys.ccpCopy(endPos)
		self.mDuration = duration

		EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Action.EF_MoveToAction, self)		
		return true
	end,


	GetIsActing = function(self)
		local result = true
		if self.mTarget == nil or not self.mIsActing then
			result = false
		end
		return result
	end,

	-- 释放动作对象
	ReleaseAction = function(self)
		self.mIsActing = false
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_MoveToAction, self)		
		self:resetData(true)
	end,

	-- 停止动作，回调
	ClearAction = function(self, endType)		
		self.mIsActing = false
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_MoveToAction, self)
		if endType == nil then
			endType = RAActionConfig.MoveToCallBackType.InitiativeEnd
		end
		if self.mHandler ~= nil and self.mHandler.OnMoveToActionEnd ~= nil then
			self.mHandler:OnMoveToActionEnd(endType)
		end
	end,

	-- private functions
	resetData = function(self, isResetTarget)
		if isResetTarget == nil then
			isResetTarget = true
		end
		if isResetTarget then
			self.mTarget = nil
		end
		self.mDuration = 0
		self.mBeginPos = nil
		self.mEndPos = nil

		self.mLastUpdateTime = 0
		self.mMovedTime = 0
		self.mHandler = nil
	end,

	getActionName = function(self)
		return 'RAMoveToAction'
	end,

	initWithDuration = function(self, duration, beginPos, endPos)
		self:resetData()
		local beginPosTmp, isBeginPtOK = Utilitys.checkIsPoint(beginPos)
		if not isBeginPtOK then
			print('RAMoveToAction initWithDuration beginPos error!! beginPos:')
			print(beginPos)
			return false
		end

		local endPosTmp, isEndPtOK = Utilitys.checkIsPoint(endPos)
		if not isEndPtOK then
			print('RAMoveToAction initWithDuration endPos error!! endPos:')
			print(endPos)
			return false
		end

		self.mDuration = duration
		self.mBeginPos = Utilitys.ccpCopy(beginPosTmp)
		self.mEndPos = Utilitys.ccpCopy(endPosTmp)

		self.mIsActing = false
		return true
	end,

	startWithTarget = function(self, target)
		if target == nil then 
			print('RAMoveToAction startWithTarget target error!! target is nil!')
			return false 
		end
		if self.mTarget ~= nil or self.mIsActing then
			print('RAMoveToAction startWithTarget error!! target is acting!')
			return false 
		end
		self.mTarget = target
		if self.mTarget ~= nil then
			EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Action.EF_MoveToAction, self)
			self.mTarget:setPosition(self.mBeginPos.x, self.mBeginPos.y)
			self.mMovedTime = 0
			self.mLastUpdateTime = 0
		end		
		return true
	end
}

RAScale9SpriteChangeAction = {
    
	new = function(self, o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
	end,

    EnterFrame = function(self)
		if self.mTarget ~= nil then
			local frameTime = GamePrecedure:getInstance():getFrameTime()
			local currSpendTime = self.mTime + frameTime
			local isExit = false
			local scale = 0
			if currSpendTime >= self.mDuration then
				-- time over
				scale = self.endScale
				isExit = true
			else
				scale = self.mBeginScale + (self.endScale - self.mBeginScale) * (currSpendTime / self.mDuration)
			end


			self.mTarget:setScaleX(scale)
			
			if isExit then
				self:ClearAction()
			else
				self.mTime = currSpendTime
			end
		else
			self:ClearAction()
		end
	end,

	ClearAction = function(self)
		EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Action.EF_Scale9SpriteChangeAction, self)
		self:exit()
	end,

	-- private functions
	getActionName = function(self)
		return 'RAScale9SpriteChangeAction'
	end,

	initWithDuration = function(self, duration, beginScale, endScale)
		self.mDuration = duration
		self.mBeginScale = beginScale
		self.endScale = endScale
	end,

	startWithTarget = function(self, target)
		self.mTarget = target
		if self.mTarget ~= nil then
			EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Action.EF_Scale9SpriteChangeAction, self)
			self.mTime = 0
		end
	end,

	exit = function(self)
		CCLuaLog('RANumLabelChangeAction exit')
		self.mTarget = nil
		self.mDuration = 0
		self.beginScale = 0
		self.endScale = 0
		self.mTime = 0
	end
    
}


return RAActionManager