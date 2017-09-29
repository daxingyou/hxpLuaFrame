---------------------------------
--轮询滑动控件
---------------------------------
RAWidgeReel = {}

local Utilitys = RARequire("Utilitys")

function RAWidgeReel:create(parentNode,nodes)
    local new = {}
    self.__index = self
    setmetatable(new,self)
    ---------------------------------
    --创建初始位置、缩放比例、zorder
    ---------------------------------
    new.size = #nodes
    if new.size==0 then return new end
    new.ceilWidth = nodes[1]:getContentSize().width
    new.ceilHeight = nodes[1]:getContentSize().height
    new.ceilAnchor = nodes[1]:getAnchorPoint()
    new.ceilAngle = 360 / new.size
    new.parentNode = parentNode
    --new.radio = new.ceilWidth==0 and parentNode:getContentSize().width/2 or new.ceilWidth
    new.radio = parentNode:getContentSize().width/2 - new.ceilWidth/2
    new.parentWidth = parentNode:getContentSize().width/2
    new.childTable = {}

    for i=1,new.size do
        local index = i-1
        local oneAngle = new.ceilAngle*index
        local x,y,scale,zorder,color = new:getXYScaleZorderColor(new.radio,oneAngle)
        nodes[i]:setPositionX(x)
        nodes[i]:setPositionY(y)
        nodes[i]:setScale(scale)
        nodes[i]:setZOrder(zorder)
        --NodeHelper:setNodeColor(nodes[i],color)
        colors = Utilitys.Split(color,",")
        --nodes[i]:setAllChildColor(tostring(colors[1]),tostring(colors[2]), tostring(colors[3]));


        parentNode:addChild(nodes[i])

        local child = {angle = oneAngle,node = nodes[i]}
        table.insert(new.childTable,child)
    end
    new.currentIndex = 1
    ---------------------------------
    --创建触摸层
    ---------------------------------
    local layer = parentNode:getChildByTag(51001);
	if not layer then
		layer = CCLayer:create();
		layer:setTag(51001);
		parentNode:getParent():addChild(layer);
		layer:setContentSize(CCSize(parentNode:getContentSize().width,parentNode:getContentSize().height));
		layer:setPosition(parentNode:getPosition())
        layer:setAnchorPoint(parentNode:getAnchorPoint())
		layer:registerScriptTouchHandler(function(eventName,pTouch)
            if eventName == "began" then
                return new:onTouchBegin(parentNode,eventName,pTouch)
            elseif eventName == "moved" then
                return new:onTouchMove(parentNode,eventName,pTouch)
            elseif eventName == "ended" then
                return new:onTouchEnd(parentNode,eventName,pTouch)
            elseif eventName == "cancelled" then
                return new:onTouchCancel(parentNode,eventName,pTouch)
            end
        end
        ,false,0,false);
		layer:setTouchEnabled(true);
		layer:setVisible(true);
	end
    new.layer = layer
    return new
end

function RAWidgeReel:registerEventHandler(func,container)
    self.handler = func
    self.container = container
end

function RAWidgeReel:getXYScaleZorderColor(radio,angle)
    local scale = ( math.cos( math.rad(angle)) + 1) / 2 * 0.7 + 0.3  --放缩从0.3~1
    local x = math.sin( math.rad(angle)) * radio + self.parentWidth - self.ceilWidth * scale * (0.5-self.ceilAnchor.x)
    local y = (1-scale)*self.ceilHeight*(0.5-self.ceilAnchor.y)
    local z = scale*1000 + 2048
    local color = ""..255*scale..","..255*scale..","..255*scale
    return x,y,scale,z,color
end

function RAWidgeReel:onTouchBegin(parentNode,eventName,pTouch)
    local point = pTouch:getLocation();
    self.mCanTouch = false
    local layer = parentNode:getParent():getChildByTag(51001);
    if layer~=nil then
        point = layer:getParent():convertToNodeSpace(point)
        local m_obPosition = ccp(layer:getPositionX(),layer:getPositionY())
        local m_obAnchorPoint = layer:getAnchorPoint()
        local m_obContentSize = layer:getContentSize()
        local rect = CCRectMake( m_obPosition.x - m_obContentSize.width * m_obAnchorPoint.x,
                      m_obPosition.y - m_obContentSize.height * m_obAnchorPoint.y,
                      m_obContentSize.width, m_obContentSize.height);
        if rect:containsPoint(point) then
            self.mCanTouch = true
        end
    end
    
    if self.mCanTouch==false then return end
    for i=1,#self.childTable do
        self.childTable[i].node:stopAllActions()
    end

    self.mBegainX = point.x;
    if self.handler~=nil then 
        self.handler(eventName,self.container)
    end
    return true
end

function RAWidgeReel:onTouchMove(parentNode,eventName,pTouch)
    if self.mCanTouch and self.mBegainX~=nil then
        local point = pTouch:getLocation();
    
        local layer = parentNode:getParent():getChildByTag(51001);
        if layer~=nil then
            point = layer:getParent():convertToNodeSpace(point)
        end
    
        local moveDisX =  point.x - self.mBegainX
        local moveAngle = moveDisX / self.radio * 90 / 2
        for i=1,#self.childTable do
            local oneAngle = self.childTable[i].angle + moveAngle
            local x,y,scale,zorder,color = self:getXYScaleZorderColor(self.radio,oneAngle)
            self.childTable[i].node:setPositionX(x)
            self.childTable[i].node:setPositionY(y)
            self.childTable[i].node:setScale(scale)
            self.childTable[i].node:setZOrder(zorder)

            colors = Utilitys.Split(color,",")
            --self.childTable[i].node:setAllChildColor(tostring(colors[1]),tostring(colors[2]), tostring(colors[3]));
            --NodeHelper:setNodeColor(self.childTable[i].node,color)
        end

        if self.handler~=nil and math.abs(moveDisX)>20 then 
            self.handler(eventName,self.container)
        end
    end
end

function RAWidgeReel:onTouchEnd(parentNode,eventName,pTouch)
    if self.mCanTouch then
        local point = pTouch:getLocation();
    
        local layer = parentNode:getParent():getChildByTag(51001);
        if layer~=nil then
            point = layer:getParent():convertToNodeSpace(point)
        end
    
        local moveDisX =  point.x - self.mBegainX
        local moveAngle = moveDisX / self.radio * 90 / 2
        moveAngle = math.floor(moveAngle / self.ceilAngle + 0.5) * self.ceilAngle

        for i=1,#self.childTable do
            self.childTable[i].angle = self.childTable[i].angle + moveAngle
            local x,y,scale,zorder,color = self:getXYScaleZorderColor(self.radio,self.childTable[i].angle)
            local array = CCArray:create()
            local moveTo = CCMoveTo:create(0.2,ccp(x,y))
            local scaleTo = CCScaleTo:create(0.2,scale)
            array:addObject(moveTo)
            array:addObject(scaleTo)
            local actionTo = CCSpawn:create(array)
            --NodeHelper:setNodeColor(self.childTable[i].node,color)
            colors = Utilitys.Split(color,",")
            --self.childTable[i].node:setAllChildColor(tostring(colors[1]),tostring(colors[2]), tostring(colors[3]));

            self.childTable[i].node:setZOrder(zorder)
            self.childTable[i].node:runAction(actionTo)
            if scale==1 then
                self.currentIndex = i
            end
        end
        if self.handler~=nil then 
            self.handler(eventName,self.container)
        end
    end
end

function RAWidgeReel:onTouchCancel(parentNode,eventName,pTouch)
    if self.mCanTouch then
        local point = pTouch:getLocation();
    
        local layer = parentNode:getParent():getChildByTag(51001);
        if layer~=nil then
            point = layer:getParent():convertToNodeSpace(point)
        end
    
        local moveDisX =  point.x - self.mBegainX
        local moveAngle = moveDisX / self.radio * 90 / 2
        moveAngle = math.floor(moveAngle / self.ceilAngle + 0.5) * self.ceilAngle

        for i=1,#self.childTable do
            self.childTable[i].angle = self.childTable[i].angle + moveAngle
            local x,y,scale,zorder,color = self:getXYScaleZorderColor(self.radio,self.childTable[i].angle)
            local array = CCArray:create()
            local moveTo = CCMoveTo:create(0.2,ccp(x,y))
            local scaleTo = CCScaleTo:create(0.2,scale)
            array:addObject(moveTo)
            array:addObject(scaleTo)
            local actionTo = CCSpawn:create(array)
            --NodeHelper:setNodeColor(self.childTable[i].node,color)
            colors = Utilitys.Split(color,",")
            --self.childTable[i].node:setAllChildColor(tostring(colors[1]),tostring(colors[2]), tostring(colors[3]));

            self.childTable[i].node:setZOrder(zorder)
            self.childTable[i].node:runAction(actionTo)
            if x==(self.parentWidth - self.ceilWidth * scale * (0.5-self.ceilAnchor.x)) then
                self.currentIndex = i
            end
        end
        if self.handler~=nil then 
            self.handler(eventName,self.container)
        end
    end
end
--dir  -1:left , 1:right
function RAWidgeReel:nextWidge(dir)
    local moveAngle =dir*360/self.size
    moveAngle = math.floor(moveAngle / self.ceilAngle + 0.5) * self.ceilAngle

    for i=1,#self.childTable do
        self.childTable[i].node:stopAllActions()
        self.childTable[i].angle = self.childTable[i].angle + moveAngle
        local x,y,scale,zorder,color = self:getXYScaleZorderColor(self.radio,self.childTable[i].angle)
        local array = CCArray:create()
        local moveTo = CCMoveTo:create(0.2,ccp(x,y))
        local scaleTo = CCScaleTo:create(0.2,scale)
        array:addObject(moveTo)
        array:addObject(scaleTo)
        local actionTo = CCSpawn:create(array)

        colors = Utilitys.Split(color,",")
        --self.childTable[i].node:setAllChildColor(tostring(colors[1]),tostring(colors[2]), tostring(colors[3]));

        self.childTable[i].node:setZOrder(zorder)
        self.childTable[i].node:runAction(actionTo)
    end
    self.currentIndex = self.currentIndex - dir
    if self.currentIndex<=0 then 
        self.currentIndex = self.size
    end
    if self.currentIndex > self.size then
        self.currentIndex = 1
    end
end
function RAWidgeReel:destroy(parentNode)
    local children = self.childTable
    if not children then return end
    for i=1,#children do
        local child = children[i];
        local node =  tolua.cast(child.node,"CCNode")
        if node then
            node:removeFromParentAndCleanup(true)
        end
    end 
    self.childTable = {}
    if self.layer then
        self.layer:removeFromParentAndCleanup(true)
        self.layer = nil
    end
end
return RAWidgeReel