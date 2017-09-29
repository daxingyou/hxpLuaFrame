RARequire('RABuildingType')

--塔台
local RATower = {}

--构造函数
function RATower:new(o)
    o = o or {}
    o.spineNode = nil   --建筑的spine节点
    o.order = 0         --编号
    o.building = nil    --关联的防御建筑
    o.curState = nil    --当前状态

    setmetatable(o,self)
    self.__index = self
    return o
end

--初始化spine文件
function RATower:init()
	self.spineNode = SpineContainer:create("Battery.json","Battery.atlas")
    self.curState = nil 
end

function RATower:setState(state)

    if self.curState == state then 
        return 
    end

	local RACityScene = RARequire('RACityScene')

    if state == TOWER_STATE_TYPE.IDLE_CLOSE then --关闭
    		self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_CLOSE,-1)   
    elseif state == TOWER_STATE_TYPE.IDLE_GREEN then --绿色
    	if RACityScene.isRain then 
    		self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_GREEN,-1)
    	else
    		self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_NIGHT_GREEN,-1)
    	end
    elseif state == TOWER_STATE_TYPE.IDLE_YELLOW then --黄色
        if RACityScene.isRain then 
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_YELLOW,-1)
        else
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_NIGHT_YELLOW,-1)
        end
    elseif state == TOWER_STATE_TYPE.IDLE_RED then  --红色
        if RACityScene.isRain then 
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_RED,-1)
        else
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.IDLE_NIGHT_RED,-1)
        end
    elseif state == TOWER_STATE_TYPE.BROKEN then --损毁
        if RACityScene.isRain then 
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.BROKEN,-1)
        else
            self.spineNode:runAnimation(0,TOWER_ANIMATION_TYPE.BROKEN_NIGHT,-1)
        end
    end

    self.curState = state 
end 

--是否可放置
function RATower:isFree()
	local RABuildManager = RARequire('RABuildManager')
	local isOpen = self:isOpen()

    if isOpen and self.building == nil then 
        return true
    else 
        return false
    end 
end

--是否开启
function RATower:isOpen()
    local RABuildManager = RARequire('RABuildManager')
    local curLimitNum = RABuildManager:getCurTowerLimitNum() 
    if self.order <= curLimitNum then
        return true
    else
        return false
    end
end

--设置位置
function RATower:setTile(tilePos)
	self.tilePos = tilePos
	local RATileUtil = RARequire('RATileUtil')
	local RACityScene = RARequire('RACityScene')
	local bulidPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,tilePos)
    self.spineNode:setPosition(bulidPos.x,bulidPos.y)
end

return RATower