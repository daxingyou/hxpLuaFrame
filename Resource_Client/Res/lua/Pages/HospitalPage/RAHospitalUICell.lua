--医院界面cell
--by sunyungao

local UIExtend       = RARequire("UIExtend")
local RAHospitalData = RARequire("RAHospitalData")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RAHospitalManager   = RARequire("RAHospitalManager")

local RAHospitalUICell = 
{
	uuid  = 0,
	mData = {},
	sliderValue = 0,
	woundedCountMax = 0,
	controlSlider = nil
}
function RAHospitalUICell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAHospitalUICell:Exit()
	-- body
	if nil ~= self.controlSlider then
		--todo
		self.controlSlider:removeFromParentAndCleanup(true)
	    self.controlSlider = nil
	end
end

function RAHospitalUICell:sliderBegan( sliderNode )
	-- body
end
function RAHospitalUICell:sliderMoved( sliderNode )
	-- body
	self:refreshSliderValue(sliderNode)
end
function RAHospitalUICell:sliderEnded( sliderNode )
	-- body
	self:refreshSliderValue(sliderNode)
end

function RAHospitalUICell:onUnLoad(ccbRoot)
	-- body
	local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile ~= nil then
        UIExtend.removeSpriteFromNodeParent(ccbfile, 'mListIconNode')
        local sliderNode = ccbfile:getCCNodeFromCCB('mBarNode')
        sliderNode:removeAllChildrenWithCleanup(true)
    end
    self.controlSlider = nil
end

--刷新数据
function RAHospitalUICell:onRefreshContent(ccbRoot)
	--todo
	CCLuaLog("RAHospitalUICell:onRefreshContent")

	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile  = ccbfile

    local data = self.mData
    if self.controlSlider == nil then
    	--todo
    	local controlSlider = UIExtend.getControlSlider("mBarNode", ccbfile)
		controlSlider:registerScriptSliderHandler(self)
		self.controlSlider = controlSlider
	end

	if self.controlSlider ~= nil then
		self.controlSlider:setMinimumValue(0)
		self.controlSlider:setMaximumValue(self.woundedCountMax)
		self.controlSlider:setValue(self.sliderValue)
	end

	RAHospitalManager:calculateConsume(self.uuid, self.sliderValue)
	----------------------------------------------------------------------------------
	local data = battle_soldier_conf[self.mData.armyId]
	--name
	UIExtend.setCCLabelString(ccbfile, "mSoldierName", _RALang(data.name))
	--icon
	UIExtend.addSpriteToNodeParent(ccbfile, "mListIconNode", data.icon)
	--当前伤兵数
	UIExtend.setCCLabelString(ccbfile,"mWoundedNum", self.sliderValue)
	--最大伤兵数
	UIExtend.setCCLabelString(ccbfile,"mMaxNum", self.woundedCountMax)
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--减按钮事件
function RAHospitalUICell:onSubBtn()
	-- body
	local value = self.controlSlider:getValue()
	value = tonumber(value-1)
	self.controlSlider:setValue(value)
	value = self.controlSlider:getValue()
	self:updateWoundedNumLabel(value)

	self:calculateConsume(self.uuid, self.sliderValue)
end

--加按钮事件
function RAHospitalUICell:onAddBtn()
	-- body
	local value = self.controlSlider:getValue()
	value = tonumber(value+1)
	self.controlSlider:setValue(value)
    value = self.controlSlider:getValue()
	self:updateWoundedNumLabel(value)

	self:calculateConsume()
end

--滑动完滑条
function RAHospitalUICell:refreshSliderValue(node)
	-- body
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	node:setValue(value)

	self:updateWoundedNumLabel(value)

	self:calculateConsume()
end

function RAHospitalUICell:isSelectAll()
	return self.sliderValue == self.woundedCountMax
end

--全部选择
function RAHospitalUICell:selectHandler(isAll,value)
	-- body
	if isAll then 
		self.sliderValue = self.woundedCountMax
	else
		self.sliderValue = 0
	end
	
	if value and value > 0 then
		if self.woundedCountMax <= value then
			self.sliderValue = self.woundedCountMax
		else
			self.sliderValue = value
		end
	end

	if nil == self.controlSlider then
		--todo
		CCLuaLog("slider has unloaded")
	else
		--todo
		self.controlSlider:setValue(self.sliderValue)
	end
	
	self:updateWoundedNumLabel(self.sliderValue)
	RAHospitalManager:calculateConsume(self.uuid, self.sliderValue)
end

function RAHospitalUICell:updateWoundedNumLabel(value)
	-- body
	self.sliderValue = value
	if nil ~= self.ccbfile then
		--todo
		UIExtend.setCCLabelString(self.ccbfile, "mWoundedNum", value)
	end
end

--计算消耗
function RAHospitalUICell:calculateConsume()
	-- body
	local value = self.controlSlider:getValue()
	RAHospitalManager:calculateConsume(self.uuid, tonumber(value))
	RAHospitalManager:sendRefreshConsumeMsg()
end

return RAHospitalUICell