-------------------------------
--page:ÀÛ¼Æ³äÖµ½±ÀøÒ³Ãæ
-------------------------------
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire('RAStringUtil')

local RATest3DPage = BaseFunctionPage:new(...)

local winSize = CCDirector:sharedDirector():getWinSize()

local rotationX = 0
local rotationY = 0
local rotationZ = 0
local addDir
local showStats = false
--str 模板 @3d,10,lr,ca,cl,
--@3d;1;res=3d/hero.c3b;scale=1
--@3d;1;res=3d/monster.c3b;scale=1
-- 10 模型个数, lr 转换灯光方向模式，如无表示转换3d模型的角度
-- ca 有表示关闭alpha测试， cl表示关闭灯光
function RATest3DPage:Enter(data)
    showStats = CCDirector:sharedDirector():isDisplayStats()
    if not showStats then
        CCDirector:sharedDirector():setDisplayStats(true)
    end
    data = data or {}
    self.setTable = {}
    local num = 1
    if data.str then
        local paramList = RAStringUtil:split(data.str, ";") 
        if tonumber(paramList[2]) then
            num = tonumber(paramList[2])
        end
        for i = 3, #paramList do
            local param = RAStringUtil:split(paramList[i], "=") 
            self.setTable[param[1]] = {} --
            if #param > 1 then
                self.setTable[param[1]].param = RAStringUtil:split(param[2], ",") 
            end
        end
    end
    UIExtend.loadCCBFile("RAGuidePage.ccbi", self)
    UIExtend.setNodeVisible(self.ccbfile, "mBGColor", true)
    local ccbfile = self.ccbfile
    -- local node = CCNode:create()
    -- node:setTag(10086)
    -- ccbfile:addChild(node)
    local objContainer = CCNode:create()
    objContainer:setTag(10086)
    ccbfile:addChild(objContainer)
    self.objContainer = objContainer

    

    local posTable = {
                    {30, winSize.height - 100, "rotationY -"},
                    {winSize.width - 130, winSize.height - 100, "rotationY +"},
                    {winSize.width - 130, winSize.height - 160, "rotationX -"},
                    {winSize.width - 130, 160, "rotationX +"},
                    {winSize.width - 130, 100, "rotationZ -"},
                    {30, 100, "rotationZ +"},
                    {winSize.width - 130, winSize.height/2, "关闭"},
                    {30, winSize.height/2 + 40, "增加单元"},
                    {30, winSize.height/2 - 40, "减少单元"},
}

    for i = 1,9 do
        local LTBtn = CCLayerColor:create(ccc4(65, 129, 195,100))
        LTBtn:setAnchorPoint(ccp(0,0))
        -- LTBtn:setZOrder(1)
        LTBtn:setContentSize(CCSizeMake(120,40))
        local label = CCLabelTTF:create(posTable[i][3], "Helvetica", 20)
        label:setAnchorPoint(ccp(0.5,0.5))
        label:setPosition(ccp(60,20))
        LTBtn:addChild(label)
        -- LTBtn:setColor(ccc3(255, 0, 0))
        LTBtn:setPosition(posTable[i][1],posTable[i][2])
        objContainer:addChild(LTBtn)
        LTBtn:setTouchEnabled(true)
        local index = i
        LTBtn:setTag(i)
        LTBtn:registerScriptTouchHandler(function(eventName,pTouch)
            if eventName == "began" then
                local inside =  UIExtend.isTouchInside(LTBtn,pTouch) 
                if inside then
                    if index < 7 then
                        addDir = index
                    end
                    return true
                end
            elseif eventName == "ended" then
                addDir = nil
                return self:onClick(index)
            end
        end
        ,false,0,false);
    end

    -- rotationX = 0
    -- rotationY = 0
    -- rotationZ = 0
    -- rotationX = -88
    -- rotationY = 0
    -- rotationZ = 363

    self.obj3dArrs = {}
    for i = 1, num do
        RATest3DPage:createObj3D( )
    end
    -- self.objContainer:setVisible(false)
end

function RATest3DPage:delectObj3D(  )
    local obj3d = table.remove(self.obj3dArrs)
    if obj3d then
        obj3d:removeFromParentAndCleanup(true)
    end
end

function RATest3DPage:createObj3D( )
    local index = #self.obj3dArrs + 1
    local width = (winSize.width - 100)/2
    local res =  index == 1 and "3d/hero.c3b" or "3d/hero.c3b"
    if self.setTable.res then
        res = self.setTable.res.param[1]
    end
    local obj3d = CCEntity3D:create(res)
    obj3d:stopAllActions()
    obj3d:playAnimation("default",0,250,true)
    if not self.setTable.ca then
        obj3d:setAlphaTestEnable(true) --使用透明度通道
    end
    if not self.setTable.cl then
        obj3d:setUseLight(true) --开启灯光
    end    
    if self.setTable.sal then
        obj3d:setAmbientLight(tonumber(self.setTable.sal.param[1]),tonumber(self.setTable.sal.param[3]),tonumber(self.setTable.sal.param[3]))
    else
        obj3d:setAmbientLight(1,1,1)  --环境光颜色
    end

    if self.setTable.sdlc then
        obj3d:setDirectionLightColor(tonumber(self.setTable.sdlc.param[1]),tonumber(self.setTable.sdlc.param[3]),tonumber(self.setTable.sdlc.param[3]))
    else
        obj3d:setDirectionLightColor(1.0,1.0,1.0)   --设置方向光颜色
    end        
    
    obj3d:setDirectionLightDirection(0,-1,1)    --设置方向光方向

    if self.setTable.sdi then
        obj3d:setDiffuseIntensity(tonumber(self.setTable.sdi.param[1]))
    else
        obj3d:setDiffuseIntensity(1)    --设置漫反射光强度
    end       
    
    if self.setTable.ssi then
        obj3d:setSpecularIntensity(tonumber(self.setTable.ssi.param[1]))
    else
        obj3d:setSpecularIntensity(1.0)    --设置镜面反射光强度
    end    

    if self.setTable.anyValue then
        local param = self.setTable.anyValue.param
        if param[2] == "true" then
            obj3d[param[1]](obj3d,true)
        elseif param[2] == "false" then
            obj3d[param[1]](obj3d,false)
        else
            if tonumber(param[2]) == 1 then
                obj3d[param[1]](obj3d,tonumber(param[3]))
            elseif tonumber(param[2]) == 2 then
                obj3d[param[1]](obj3d,tonumber(param[3]),tonumber(param[4]))
            elseif tonumber(param[2]) == 3 then
                obj3d[param[1]](obj3d,tonumber(param[3]),tonumber(param[4]),tonumber(param[5]))
            end          
        end
    end

    if self.setTable.scale then
        obj3d:setScale(tonumber(self.setTable.scale.param[1]))
    else
        obj3d:setScale(1)
    end
    
    -- obj3d:setPosition(50 + width/2 + (index - 1)%5*width, winSize.height - 300 + width/2 - math.ceil(index/5) * width )
    obj3d:setPosition(ccp(winSize.width/2+ (index == 1 and 0 or -0), winSize.height/2 ))

    -- obj3d:setPosition(math.random(50, winSize.width - 50), math.random(100, winSize.height - 100))
    if self.setTable.lr then
        obj3d:setRotation3D(Vec3(20,-20,0))
    else
        obj3d:setRotation3D(Vec3(rotationX,rotationY,rotationZ))
    end

    obj3d:setAnchorPoint(ccp(0.5,0.5))

    self.objContainer:addChild(obj3d)   
    self.obj3dArrs[index] = obj3d    
end

function RATest3DPage:Execute()
    local dt = GamePrecedure:getInstance():getFrameTime()
    self.totalTime = self.totalTime or 0
    self.totalTime = self.totalTime + dt
    if self.totalTime >= 0.06 then
        self.totalTime = 0
        if addDir then
            RATest3DPage:addRot( addDir )
        end
    end
end


function RATest3DPage:onClick( index )
    if index == 7 then
        RARootManager.ClosePage("RATest3DPage")
        return
    end
    if index == 8 then
        RATest3DPage:createObj3D( )
        return
    end   
    if index == 9 then
        RATest3DPage:delectObj3D( )
        return
    end      
    RATest3DPage:addRot( index )
end
function RATest3DPage:addRot( index )
    if index == 3 then
        rotationX = rotationX - 3
    elseif index == 4 then
        rotationX = rotationX + 3
    elseif index == 2 then
        rotationY = rotationY + 3
    elseif index == 1 then
        rotationY = rotationY - 3                
    elseif index == 5 then
        rotationZ = rotationZ - 3
    elseif index == 6 then
        rotationZ = rotationZ + 3
    end
    print("rotationX = ",rotationX)
    print("rotationY = ",rotationY)
    print("rotationZ = ",rotationZ)
    for i,obj3d in ipairs(self.obj3dArrs) do
        if self.setTable.lr then
            obj3d:setDirectionLightDirection(math.sin(math.rad(rotationX)),math.sin(math.rad(rotationY)),math.sin(math.rad(rotationZ)))
        else
            obj3d:setRotation3D(Vec3(rotationX,rotationY,rotationZ))  
        end
    end

end

function RATest3DPage:onBackBtn()
    RARootManager.ClosePage("RATest3DPage")
end

function RATest3DPage:Exit(data)
    self.ccbfile:removeChildByTag(10086, true)
    CCDirector:sharedDirector():setDisplayStats(showStats)
    showStats = false
    UIExtend.unLoadCCBFile(self)
end

return RATest3DPage