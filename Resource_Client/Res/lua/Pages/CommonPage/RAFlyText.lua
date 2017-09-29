RARequire("BasePage")

local RAFlyText = BaseFunctionPage:new(...)



function RAFlyText:init(text)
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAFlyText.ccbi",RAFlyText)
	self.ccbfile = ccbfile
	UIExtend.setCCLabelString(ccbfile,"mFlyText",text);
end

-- function RAFlyText:sequence(actions)
-- 	if #actions < 1 then return end
-- 	if #actions < 2 then return actions[1] end

-- 	local prev = actions[1]
-- 	for i=2,#actions do
-- 		prev = CCSequence:createWithTwoActions(prev,actions[i])
-- 	end
-- 	return prev
-- end

function RAFlyText:show()
	-- local scaleTo = CCScaleTo:create(0.2,1,1)
	-- local scaleTo1 = CCScaleTo:create(0.4,1,0.1)
	-- local easeInAction = CCEaseExponentialIn:create(scaleTo)
	-- local easeInAction1 = CCEaseExponentialIn:create(scaleTo1)

	-- local actions = {}
	-- actions[#actions+1] = easeInAction
	-- actions[#actions+1] = CCDelayTime:create(2.0)
	-- actions[#actions+1] = easeInAction1

	-- local squenceActions = self:sequence(actions)

	-- self.ccbfile:runAction(squenceActions)
end	

function RAFlyText:Exit()
	
end