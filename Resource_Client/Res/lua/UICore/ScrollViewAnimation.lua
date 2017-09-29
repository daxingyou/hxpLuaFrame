local ScrollViewAnimation = {}

local PanelTable = {}
local beginTime = 0
local animationName = "GetIn"
local num = 0
local animationAble = false

function ScrollViewAnimation.runAnimationContent()
	num = num + 1
	if num > #PanelTable then	
		return false
	end
	if PanelTable[num] then
		local ccb = PanelTable[num]:getCCBFileNode()
		if ccb then
			ccb:runAnimation(animationName,true)
		end
		beginTime = GamePrecedure:getInstance():getTotalTime()		
	end		
	return true
end

function ScrollViewAnimation.addToTable(cell)
	PanelTable[#PanelTable + 1] = cell
end

function ScrollViewAnimation.init(ownerPage,getIn)
	ScrollViewAnimation.mOwnerPage = ownerPage	
    if getIn == nil then
        animationName = "GetIn"
    else
        animationName = getIn
    end
	
end

function ScrollViewAnimation.runGetInParam(default,getIn)
	for k,v in pairs(PanelTable) do
		if v:getCCBFileNode() then
			v:getCCBFileNode():runAnimation(default,true)
		end
	end	
	ScrollViewAnimation.startAnimation(getIn)	
end

function ScrollViewAnimation.runGetIn()
	for k,v in pairs(PanelTable) do
		if v:getCCBFileNode() then
			v:getCCBFileNode():runAnimation("Untitled Timeline",true)
		end
	end	
	ScrollViewAnimation.startAnimation("GetIn")	
end

function ScrollViewAnimation.reSetBeginTime()
	beginTime,num,animationAble = 0,0,false
end

function ScrollViewAnimation.startAnimation(name)
	beginTime = GamePrecedure:getInstance():getTotalTime()
	animationName = name	
	animationAble = true
end

function ScrollViewAnimation.update()
	local ownerPage = ScrollViewAnimation.mOwnerPage
	if ownerPage and not ownerPage.delay_unLock then
		if animationAble then
			local currentTime = GamePrecedure:getInstance():getTotalTime()
			if currentTime - beginTime >= 0.03 then
				if not ScrollViewAnimation.runAnimationContent() then
					ScrollViewAnimation.reSetBeginTime()				
				end
			end			
		end
	end
end

function ScrollViewAnimation.clearTable()
	ScrollViewAnimation.reSetBeginTime()
	for k,v in pairs(PanelTable) do
		PanelTable[k] = nil
	end
end	

return ScrollViewAnimation