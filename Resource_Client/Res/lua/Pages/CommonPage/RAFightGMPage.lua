--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAFightGMPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local mAllScrollview = nil
local common = RARequire("common")
local RAGameConfig = RARequire('RAGameConfig')

local RASoilderNode = {}
--构造函数
function RASoilderNode:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

local createEditBox = function (size)
    local editbox = CCEditBox:create(size, CCScale9Sprite:create(RAGameConfig.ButtonBg.GARY))

    editbox:setIsDimensions(true)
    editbox:setFontName(RAGameConfig.DefaultFontName)
    editbox:setFontSize(20)
    editbox:setAlignment(0)
    editbox:setLableStarPosition(ccp(5,5))
    -- anchorPoint = anchorPoint or ccp(0,1)
    editbox:setAnchorPoint(ccp(0,0))
    editbox:setFontColor(RAGameConfig.COLOR.WHITE)
    editbox:setInputMode(kEditBoxInputModeNumeric)
    editbox:setMaxLength(10)
    return editbox
end

local getValue = function(editbox)
    local value = editbox:getText()
    
    value = tonumber(value)
    
    if value == nil then 
        value = 0
    end  

    return value
end
-- function RASoilderNode:createEditBox(size)
--     local editbox = CCEditBox:create(size, CCScale9Sprite:create(RAGameConfig.ButtonBg.GARY))

--     editbox:setIsDimensions(true)
--     editbox:setFontName(RAGameConfig.DefaultFontName)
--     editbox:setFontSize(20)
--     editbox:setAlignment(0)
--     editbox:setLableStarPosition(ccp(5,5))
--     -- anchorPoint = anchorPoint or ccp(0,1)
--     editbox:setAnchorPoint(ccp(0,0))
--     editbox:setFontColor(RAGameConfig.COLOR.WHITE)
--     editbox:setInputMode(kEditBoxInputModeNumeric)
--     editbox:setMaxLength(10)
--     return editbox
-- end

function RASoilderNode:init(index)
    self.index = index
    self.rootNode = CCNode:create()

    self.editboxArr = {}
    local size = CCSize(100,40)

    for i=1,3 do
        self.editboxArr[i] = createEditBox(size)
        self.editboxArr[i]:setPosition(ccp(20+120*(i-1),0))
        self.rootNode:addChild(self.editboxArr[i])
    end
end

function RASoilderNode:getValue(editbox)
    local value = editbox:getText()
    
    value = tonumber(value)
    
    if value == nil then 
        value = 0
    end  

    return value
end

function RASoilderNode:getData()
    local data = {}

    data.itemId = self:getValue(self.editboxArr[1])
    data.count = self:getValue(self.editboxArr[2])
    data.totalCount = self:getValue(self.editboxArr[3])
    return data
end

function RASoilderNode:setData(data)
    self.editboxArr[1]:setText(data.itemId)
    self.editboxArr[2]:setText(data.count)
    self.editboxArr[3]:setText(data.totalCount)
end

function RASoilderNode:setPosition(pos)
    self.rootNode:setPosition(pos)
end

local RATroopNode = {}
--构造函数
function RATroopNode:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RATroopNode:init(index)
    self.index = index
    self.rootNode = CCNode:create()
    self.nodes = {}
    for i=1,6 do
        local node = RASoilderNode:new()
        node:init(i)
        node:setPosition(ccp(0,250-(i-1)*50))
        self.rootNode:addChild(node.rootNode)
        self.nodes[#self.nodes+1] = node
    end
end

function RATroopNode:setPosition(pos)
    self.rootNode:setPosition(pos)
end

function RATroopNode:setValue(troop)
    for i,v in ipairs(troop) do
        if i < 7 then 
            self.nodes[i]:setData(v)
        end 
    end
end

function RATroopNode:getValue()
    local arr = {}
    for i,v in ipairs(self.nodes) do
        local value = v:getData()
        if value.itemId ~= 0 then 
            arr[#arr+1] = value
        end 
    end

    return arr
end


function RAFightGMPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RAFightGMPage.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    mAllScrollview:setVisible(false)
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:CommonRefresh()
    self:initData()
end

function RAFightGMPage:initData()
    local TestData = RARequire('TestData')
    -- if TestData.attackers then 
    --     self.attackTroop:setValue(TestData.attackers)
    -- end 

    -- if TestData.defenders then 
    --     self.defenerTroop:setValue(TestData.defenders)
    -- end 

    self.missionEditBox:setText(tostring(TestData.missionId))
    self.scaleTTF:setString('当前缩放比例:'.. RARequire('RABattleScene').curScale)
end


function RAFightGMPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()
	end
    local titleName = "Fight GM Page"
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAFightGMPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAFightGMPage:createTTF(pos,text)
    local ttf = CCLabelTTF:create("", "Helvetica", 20)
    ttf:setString(text)
    ttf:setColor(COLOR_TABLE[COLOR_TYPE.WHITE])
    ttf:setAnchorPoint(ccp(0,0))
    ttf:setPosition(pos)
    self.container:addChild(ttf)
    return ttf
end

function RAFightGMPage:initDes()
    self.desArr = {}
    self.scaleTTF = self:createTTF(ccp(340,790),"当前缩放比例:")
    self.desArr[#self.desArr+1] = self.scaleTTF
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"重置测试数据:ctrl+R")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"打开战斗GM页面:ctrl+F")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"显示遮挡层:ctrl+V")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"放大地图:ctrl+A")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"缩小地图:ctrl+S")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"作战单位遮挡:ctrl+D")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"摄像机限制:ctrl+O")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"游戏减速*0.5:ctrl+1")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"游戏加速*2:ctrl+2")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"打开点击鼠标进行攻击:ctrl+3")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"显示坦克信息:ctrl+H")
    self.desArr[#self.desArr+1] = self:createTTF(ccp(40,790),"显示大格地图信息:ctrl+C")

    for i=1,#self.desArr do
        self.desArr[i]:setPosition(ccp(20+120*(4-1),790-i*30))  
    end
end

function RAFightGMPage:onCommit()
    -- local attackValues = self.attackTroop:getValue()
    -- local defenerValues = self.defenerTroop:getValue()
    RAUnload('TestData')
    local TestData = RARequire('TestData')
    TestData.missionId = getValue(self.missionEditBox)
    if TestData.missionId == 0 then 
        TestData.missionId = 1
    end 
    -- TestData:setGMWindowData(attackValues,defenerValues)
    RARequire('RABattleScene'):doFightTest()
    RARootManager.ClosePage('RAFightGMPage')
end

function RAFightGMPage:initMissionPanel()
    self:createTTF(ccp(40,790),"关卡ID")

    local size = CCSize(100,40)
    self.missionEditBox = createEditBox(size)
    self.missionEditBox:setPosition(ccp(40,750))
    self.container:addChild(self.missionEditBox)
end

function RAFightGMPage:CommonRefresh()

    self.container = CCNode:create()
    self.ccbfile:addChild(self.container)

    self:initDes()
    self:initMissionPanel()
    self.controlBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mCommitBtn')
end

function RAFightGMPage:Execute()
   
end

function RAFightGMPage:Exit()
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAFightGMPage")
    self.container:removeFromParentAndCleanup(true)
    UIExtend.unLoadCCBFile(self)
end

return RAFightGMPage