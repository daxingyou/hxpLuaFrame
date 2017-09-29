--region RATroopsInfoPage.lua
--Author : phan
--Date   : 2016/6/27
--此文件由[BabeLua]插件自动生成


--endregion

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RALogicUtil = RARequire("RALogicUtil")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAArmyDetailsCellNode = RARequire("RAArmyDetailsCellNode")
local Const_pb = RARequire("Const_pb")
local RAHospitalManager = RARequire("RAHospitalManager")
local RATroopsInfoManager = RARequire("RATroopsInfoManager")
local Utilitys = RARequire("Utilitys")

local scrollHeight = 120
local troopsTotal = 0

local RATroopsInfoPage = BaseFunctionPage:new(...)

local RAArmyDetailsCell = {}

local OnReceiveMessage = function(message)     
    if message.messageID == MessageDef_FireSoldier.MSG_RATroopsInfoUpdate then
        CCLuaLog("MessageDef_FireSoldier MSG_RATroopsInfoUpdate")
        local RARootManager = RARequire("RARootManager")
        RARootManager.ShowMsgBox("@TroopsFireSuccessTips")
        RATroopsInfoManager.restData()
        RATroopsInfoPage:refreshBasicData()
        --解雇成功后发送消息刷新集结点
        MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
    end
end

function RATroopsInfoPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_FireSoldier.MSG_RATroopsInfoUpdate, OnReceiveMessage)
end

function RATroopsInfoPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_FireSoldier.MSG_RATroopsInfoUpdate, OnReceiveMessage)
end

function RATroopsInfoPage:Enter()
    self:registerMessageHandlers()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAArmyDetailsPage.ccbi",self)
    self.ccbfile = ccbfile
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mArmyDetailsListSV")
    self:refreshBasicData()
end

function RATroopsInfoPage:refreshBasicData()    
    local gold = RAPlayerInfoManager.getPlayerBasicInfo().gold
    local goldore = RAPlayerInfoManager.getPlayerBasicInfo().goldore --金矿石
    local oil = RAPlayerInfoManager.getPlayerBasicInfo().oil    --油
    local steel = RAPlayerInfoManager.getPlayerBasicInfo().steel    --钢
    local tombarthite = RAPlayerInfoManager.getPlayerBasicInfo().tombarthite --稀土

    goldore = RALogicUtil:num2k(goldore, 1)
    oil = RALogicUtil:num2k(oil, 1)
    steel = RALogicUtil:num2k(steel, 1)
    tombarthite = RALogicUtil:num2k(tombarthite, 1)

    --top info
    self:initTitle()

    --部队总数
    local troopsTotal = RATroopsInfoManager.getTroopsTotal(true)
    local armyNumStr = _RALang("@TroopsTotal",tostring(troopsTotal))
    UIExtend.setStringForLabel(self.ccbfile,{mArmyTotalNum = armyNumStr})
    --行军总数
    local RAMarchDataManager = RARequire("RAMarchDataManager")
    local selfMarchCount = RAMarchDataManager:GetSelfMarchCount()
    local marchNumStr = _RALang("@MarchTotal",selfMarchCount) --.."/".."2")
    UIExtend.setStringForLabel(self.ccbfile,{mFoodConsumption = marchNumStr})
    --电力占用
    --local electric = RAPlayerInfoManager.getCurrElectricValue()
    
    -- local electric = 0
    -- local datas = RAPlayerInfoManager.getElectricInfoForAllArmys()
    -- if Utilitys.table_count(datas) ~= 0 then
    --     for k,v in pairs(datas) do
    --         electric = electric + v.electricTotal
    --     end   
    --     electric = math.ceil(electric) 
    -- end

    -- local foodConsumptionStr = _RALang("@PowerOccupy",electric)
    -- UIExtend.setStringForLabel(self.ccbfile,{mWoundedTotalNum = foodConsumptionStr})

    UIExtend.setNodeVisible(self.ccbfile,"mWoundedTotalNum",false)

    --伤病总数
    local curingCount, woundedCount = RAHospitalManager.getCuringAndWoundedCount()  ---------todo:woundedCount value
    local woundedTotalNumStr = _RALang("@WoundedTotal",woundedCount)
    UIExtend.setStringForLabel(self.ccbfile,{mMarchNum = woundedTotalNumStr})

    local RATroopsInfoConfig = RARequire("RATroopsInfoConfig")
    --兵种数据
    RATroopsInfoManager.getSoldersData()
    --防御数据
    RATroopsInfoManager.getDefenseData()

    self:pushCellToScrollView(RATroopsInfoConfig.buildIdData)
end

function RATroopsInfoPage:onBack()
    print("RATroopsInfoPageRATroopsInfoPageRATroopsInfoPageRATroopsInfoPageRATroopsInfoPage")
end

function RATroopsInfoPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local RARootManager = RARequire("RARootManager")
	local backCallBack = function()
		--RARootManager.CloseCurrPage()  
        RARootManager.ClosePage("RATroopsInfoPage")
	end
    local titleName = _RALang("@TroopsInfo")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RATroopsInfoPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RATroopsInfoPage:Exit()
    print("RATroopsInfoPage:Exit")
    self:unregisterMessageHandlers()
    RATroopsInfoManager.restData()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RATroopsInfoPage")
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end

function RAArmyDetailsCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

--根据node设置 content size
function RAArmyDetailsCell:onResizeCell(ccbRoot)
    local line = math.ceil(self.mSize/5)
    if line == 0 then return end
    local nodeScrollView = UIExtend.getCCScrollViewFromCCB(ccbRoot, "mIconListSV")
    local oldSize = nodeScrollView:getViewSize()
    local size = ccbRoot:getContentSize()
    size.height =  size.height + line*scrollHeight-scrollHeight --行数 x 一个container的高度 - 一行默认的高度
    if not self.mSelfCell then return end
    if 1 < line then
        self.mSelfCell:setContentSize(size.width,size.height)
    end
end

function RAArmyDetailsCell:onRefreshContent(ccbRoot)
	CCLuaLog("RAArmyDetailsCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local index = tonumber(self.mTag)
    local data = self.mData
    local lableTag = 10000
    
    ccbfile:removeChildByTag(lableTag,true)
    if nil ~= data.title then
       UIExtend.setStringForLabel(ccbfile,{mTitle = data.title})
    elseif nil ~= data.show then
        local scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mIconListSV")
        if scrollView then
            scrollView:removeAllCell()
        end
        local str = data.show
        local lable = UIExtend.createLabel(str)
        local size = ccbfile:getContentSize()
        lable:setTag(lableTag)
        lable:setPosition(ccp(size.width/2,size.height/2))
        ccbfile:addChild(lable)
        UIExtend.setStringForLabel(ccbfile,{mCellTitle = tostring(0)})
        UIExtend.setNodeVisible(ccbfile,"mCellNum",false)
        
    else
        local scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mIconListSV")
        local line = math.ceil(#data/5)
        if line == 0 then return end
        --if line > 1 then
            local rSize = ccbRoot:getContentSize()
            local cellBG = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mCellBG")
            cellBG:setContentSize(rSize.width,rSize.height)

            local oldSize = scrollView:getViewSize()
            oldSize.height = scrollHeight * line
            oldSize.width = rSize.width
            scrollView:setViewSize(oldSize)
            scrollView:setContentSize(oldSize.width,oldSize.height)
            ccbfile:setPositionY(oldSize.height-scrollHeight) --行数 x 一个scrollView的高度 - scrollView一行默认的高度
        --end

        scrollView:setTouchEnabled(false)
        scrollView:removeAllCell()
        local num = 0
        for k,v in pairs(data) do
            --num
            local armyInfo = RACoreDataManager:getArmyInfoByArmyId(tonumber(v.id))
            if armyInfo then
                num = num + armyInfo.freeCount
            end
            if v.name then --如果有名字，说明是防御类型
                num = _RALang(v.name)
            end
 
            local cell = CCBFileCell:create()
            local ccbiStr = "RAArmyDetailsCellNode.ccbi"
            local panel = RAArmyDetailsCellNode:new({
                    mData = data[k],
                    mTag   = k
            })

            cell:registerFunctionHandler(panel)
            
            cell:setCCBFile(ccbiStr)
            scrollView:addCell(cell)
        end

        scrollView:orderCCBFileCells()

        UIExtend.setStringForLabel(ccbfile,{mCellTitle = tostring(num)})

        UIExtend.setNodeVisible(ccbfile,"mCellNum",false)
    end
end

--function RAArmyDetailsCell:onUnLoad()
 --   UIExtend.unLoadCCBFile(self)
--end

--data:结构由1个itemTable组成
function RATroopsInfoPage:pushCellToScrollView(data)
    -- body
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        local ccbiStr = "RAArmyDetailsCell.ccbi"
        if nil ~= data[k].title then
            ccbiStr = "RAArmyDetailsCellTitle.ccbi"
        end
        local panel = RAArmyDetailsCell:new({
                mData = v,
                mTag   = k,
                mSize = (#v)
        })
        cell:registerFunctionHandler(panel)
        panel.mSelfCell = cell
        cell:setCCBFile(ccbiStr)
        scrollView:addCell(cell)
    end

    scrollView:orderCCBFileCells()
end

return RATroopsInfoPage