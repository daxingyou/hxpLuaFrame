-- RAElectricInfoPage.lua
-- 电力详情页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local RANetUtil = RARequire('RANetUtil')
local RAGameConfig = RARequire('RAGameConfig')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')    
local RABuildManager = RARequire('RABuildManager')
local RALogicUtil = RARequire('RALogicUtil')

local RAElectricInfoPage = BaseFunctionPage:new(...)
RAElectricInfoPage.mExplainLabel = nil


-- title
local RAElectricTitleCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        self.mTitle = ''
        return o
    end,

    GetCCBName = function(self)
        return 'RAPESystemPopUpCellTitle.ccbi'
    end,

    SetData = function(self, index, title)
        self.mIndex = index
        self.mTitle = title
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        UIExtend.setCCLabelString(ccbfile, 'mCellTitle', self.mTitle)
    end,

    onUnLoad = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode()        
    end
}

-- content cell
local RAElectricContentCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        self.mIsTitle = false
        self.mExtraColor = RAGameConfig.COLOR.WHITE
        self.mShowData = {
            str1 = '',
            str2 = '', 
            str3 = '',
            str4 = '',
        }
        return o
    end,

    GetCCBName = function(self)
        return 'RAPESystemPopUpCell.ccbi'
    end,

    SetData = function(self, index, isTitle, showData)
        self.mIndex = index
        self.mIsTitle = isTitle or false
        self.mShowData = showData
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        local color = RAGameConfig.COLOR.WHITE
        if self.mIsTitle then
            color = RAGameConfig.COLOR.YELLOW
        end
        local extraColor = self.mExtraColor
        if self.mShowData.extraColor then
            extraColor = self.mShowData.extraColor
        end
        UIExtend.setColorForLabel(ccbfile, {
            mDetailsTitle1 = color,
            mDetailsTitle2 = color,
            mDetailsTitle3 = color,
            mDetailsTitle4 = extraColor,
        })

        UIExtend.setStringForLabel(ccbfile,{
            mDetailsTitle1 = self.mShowData.str1,
            mDetailsTitle2 = self.mShowData.str2,
            mDetailsTitle3 = self.mShowData.str3,
            mDetailsTitle4 = self.mShowData.str4,  
        })
    end,

    onUnLoad = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode()        
    end
}


local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    -- if message.messageID == MessageDef_World.MSG_PresidentInfo_Update then        
    --     -- RAElectricInfoPage:CheckAndUpdatePage(PalaceTabBtnType.Attr)
    -- end

    -- if message.messageID == MessageDef_World.MSG_PresidentEvents_Update then        
    --     -- RAElectricInfoPage:CheckAndUpdatePage(PalaceTabBtnType.BattleRecord)
    -- end

    -- if message.messageID == MessageDef_World.MSG_PresidentHistory_Update then        
    --     -- RAElectricInfoPage:CheckAndUpdatePage(PalaceTabBtnType.PresidentRecord)
    -- end
end

function RAElectricInfoPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)
end

function RAElectricInfoPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)    
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)  
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)  
end

function RAElectricInfoPage:resetData()
    if self.scrollView ~= nil then
        self.scrollView:removeAllCell()
    end
    self.scrollView = nil
    
    if self.mExplainLabel ~= nil then
        self.mExplainLabel:stopAllActions()
        self.mExplainLabel:setPosition(self.mExplainLabelStarP)
    end
    self.mExplainLabel = nil
end

function RAElectricInfoPage:Enter()	
	local ccbfile = UIExtend.loadCCBFile("RAPESystemPopUp1.ccbi",self)
    
    --title
    UIExtend.setCCLabelString(ccbfile, 'mItemTitle' ,_RALang("@ElectricInfoTitle"))

    --scroll view
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

    self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(ccbfile,"mExplainLabel")
    self.mExplainLabelStarP = ccp(self.mExplainLabel:getPosition())
    UIExtend.setCCLabelString(ccbfile, 'mExplainLabel', _RALang('@ElectricRollingExplain'))
    UIExtend.createLabelAction(ccbfile, "mExplainLabel")

    -- 默认不可见吧
    UIExtend.setNodesVisible(ccbfile, {
            mAffectNode1 = false,
            mAffectNode2 = false,
            mAffectNode3 = false,
            mAffectNode4 = false,
            mAffectNode5 = false,
            mAffectNode6 = false,
        })

    self:RefreshCommonUIPart()

    -- self:registerMessageHandlers()
    -- self.mLastUpdateTime = 0
end


-- function RAElectricInfoPage:Execute()
--     local currTime = CCTime:getCurrentTime()
--     if currTime - self.mLastUpdateTime < 300 then
--         return
--     end
--     self.mLastUpdateTime = currTime
--     -- self:RefreshCommonUIPart()
-- end


function RAElectricInfoPage:Exit()
    self:resetData()
    -- self:unregisterMessageHandlers()    
    UIExtend.unLoadCCBFile(self)
end

function RAElectricInfoPage:onClose()
	RARootManager.ClosePage('RAElectricInfoPage')
end


function RAElectricInfoPage:RefreshCommonUIPart()
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end    

    local currElectric = RAPlayerInfoManager.getCurrElectricValue()
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    local status, decrease = RAPlayerInfoManager.getCurrElectricStatus()

    
    UIExtend.setStringForLabel(ccbfile, {
            mCurrentNum = currElectric,
            mTotalNum = '/'..currElectricMax,            
            mAffect1 = _RALang('@ElectricBuildQueueSpeedDown'),
            mAffect2 = _RALang('@ElectricCureQueueSpeedDown'),
            mAffect3 = _RALang('@ElectricDefenceQueueSpeedDown'),
            mAffect4 = _RALang('@ElectricScienceQueueSpeedDown'),
            mAffect5 = _RALang('@ElectricSoldierQueueSpeedDown'),
            mAffect6 = _RALang('@ElectricDefenceBuildDisable'),
            mAffectNum1 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum2 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum3 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum4 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum5 = _RALang('@ElectricAffectOnQueue', decrease),
        })
    UIExtend.setColorForLabel(ccbfile, {mAffect1 = RAGameConfig.COLOR.WHITE})

    local visibleTable = {}

    local color = RAGameConfig.COLOR.GREEN
    -- 电力充足
    if status ==  RAGameConfig.ElectricStatus.Enough then
        color = RAGameConfig.COLOR.GREEN
        visibleTable.mAffectNode1 = true
        visibleTable.mAffect1 = true
        visibleTable.mAffectNum1 = false
        UIExtend.setColorForLabel(ccbfile, { mAffect1 = color})
        UIExtend.setStringForLabel(ccbfile, { mAffect1 = _RALang('@ElectricNoEffect')})
    --电力紧张
    elseif status ==  RAGameConfig.ElectricStatus.Intense then
        color = RAGameConfig.COLOR.ORANGE
        visibleTable.mAffectNode1 = true
        visibleTable.mAffectNode2 = true
        visibleTable.mAffectNode3 = true
        visibleTable.mAffectNode4 = true
        visibleTable.mAffectNode5 = true
    -- 电力不足
    elseif status == RAGameConfig.ElectricStatus.NotEnough then
        color = RAGameConfig.COLOR.RED
        visibleTable.mAffectNode1 = true
        visibleTable.mAffectNode2 = true
        visibleTable.mAffectNode3 = true
        visibleTable.mAffectNode4 = true
        visibleTable.mAffectNode5 = true
        visibleTable.mAffectNode6 = true
    end

    UIExtend.setColorForLabel(ccbfile, {
            mCurrentNum = color,
            mAffectNum1 = color,
            mAffectNum2 = color,
            mAffectNum3 = color,
            mAffectNum4 = color,
            mAffectNum5 = color,            
            mAffect6 = color,
            mCurrentAffect = color,
        })
    UIExtend.setNodesVisible(ccbfile, visibleTable)

    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect1', 'mAffectNum1')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect2', 'mAffectNum2')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect3', 'mAffectNum3')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect4', 'mAffectNum4')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect5', 'mAffectNum5')


    -- bar
    self:_RefreshBar(ccbfile)

    -- scroll view
    self:_RefreshScrollView(ccbfile)
end

function RAElectricInfoPage:_RefreshBar(ccbfile)
    local const_conf = RARequire('const_conf')

    local barSizeNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarSizeNode")
    local barSizeHeight = barSizeNode:getContentSize().height
    local frontBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mFrontBar")
    local greenBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mGreenBar")
    local yellowBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mYellowBar")
    local redBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mRedBar")

    -- 当前主城等级对应的电量上限
    local electricCfgMax = RAPlayerInfoManager.getCurrElectricMaxCfgValue()
    -- 当前产电量上限
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    -- 当前用电量
    local currElectricUse = RAPlayerInfoManager.getCurrElectricValue()

    local checkPercent = function(percent)
        if percent < 0 then
            return 0
        end
        if percent > 1 then
            return 1
        end
        return percent
    end

    local electric_cap1 = const_conf.electric_cap1.value
    local electric_cap2 = const_conf.electric_cap2.value

    local greenScaleTo = 0
    local yellowScaleTo = 0
    local redScaleTo = 0
    if electricCfgMax == 0 then
        greenScaleTo = 0
    else
        greenScaleTo = (currElectricMax / electricCfgMax)
    end
    greenScaleTo = checkPercent(greenScaleTo)

    if currElectricMax == 0 then
        redScaleTo = 0
        yellowScaleTo = 0        
    else
        yellowScaleTo = (currElectricUse / currElectricMax / electric_cap1 * 100) * greenScaleTo
        redScaleTo = (currElectricUse / currElectricMax / electric_cap2 * 100) * greenScaleTo
    end
    redScaleTo = checkPercent(redScaleTo)
    yellowScaleTo = checkPercent(yellowScaleTo)
    frontBar:setScaleY((1 - greenScaleTo) * barSizeHeight)
    yellowBar:setScaleY(yellowScaleTo * barSizeHeight)
    redBar:setScaleY(redScaleTo * barSizeHeight) 
end

function RAElectricInfoPage:_RefreshScrollView(ccbfile)
    if self.scrollView == nil then return end
    local scrollView = self.scrollView
    scrollView:removeAllCell()
    self:_AddElectricCells(scrollView)
    self:_AddBuildingCells(scrollView)
    -- 不显示兵种了 jira 4810
    -- self:_AddArmyCells(scrollView)

    scrollView:orderCCBFileCells()
end

function RAElectricInfoPage:_AddElectricCells(scrollView)
    --添加电力供应
    -- title1
    local titleHandler = RAElectricTitleCell:New()
    titleHandler:SetData(1, _RALang('@ElectricSupplyTitle'))
    local titleCell = CCBFileCell:create()            
    titleCell:registerFunctionHandler(titleHandler)
    titleCell:setCCBFile(titleHandler:GetCCBName())
    scrollView:addCellBack(titleCell)
    -- title2
    local contentTitleShowData = {
        str1 = _RALang('@ElectricCellBuildTitle'),
        str2 = _RALang('@ElectricCellNumTitle'),
        str3 = _RALang('@ElectricCellBaseNumTitle'),
        str4 = _RALang('@ElectricCellExtralEffectTitle'),
        extraColor = RAGameConfig.COLOR.YELLOW
    }
    local contentTitleHandler = RAElectricContentCell:New()
    contentTitleHandler:SetData(1, true, contentTitleShowData)
    local contentTitleCell = CCBFileCell:create()            
    contentTitleCell:registerFunctionHandler(contentTitleHandler)
    contentTitleCell:setCCBFile(contentTitleHandler:GetCCBName())
    scrollView:addCellBack(contentTitleCell)
    -- content    
    local electricFactoryNum = RABuildManager:getBuildDataCountByType(Const_pb.POWER_PLANT)
    local electricFactoryName = _RALang('@Build_2025_name')
    local realElectricMax, baseElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    local baseElectricMaxStr = RALogicUtil:num2k(baseElectricMax)
    local extralElectricValue = realElectricMax - baseElectricMax
    local extraColor = RAGameConfig.COLOR.WHITE
    if extralElectricValue < 0 then 
        extralElectricValue = 0 
        extraColor = RAGameConfig.COLOR.WHITE
    end
    local extralElectricValueStr = RALogicUtil:num2k(extralElectricValue)
    if extralElectricValue > 0 then
        extralElectricValueStr = _RALang('@PlusWithParam', extralElectricValueStr)
        extraColor = RAGameConfig.COLOR.GREEN
    end
    local contentShowData = {
        str1 = electricFactoryName,
        str2 = tostring(electricFactoryNum),
        str3 = baseElectricMaxStr,
        str4 = extralElectricValueStr,
        extraColor = extraColor
    }
    local contentHandler = RAElectricContentCell:New()
    contentHandler:SetData(1, false, contentShowData)
    local contentCell = CCBFileCell:create()            
    contentCell:registerFunctionHandler(contentHandler)
    contentCell:setCCBFile(contentHandler:GetCCBName())
    scrollView:addCellBack(contentCell)
end
function RAElectricInfoPage:_AddBuildingCells(scrollView)
    --添加电力占用
    -- title1
    local titleHandler = RAElectricTitleCell:New()
    titleHandler:SetData(1, _RALang('@ElectricSpendOnTitle'))
    local titleCell = CCBFileCell:create()            
    titleCell:registerFunctionHandler(titleHandler)
    titleCell:setCCBFile(titleHandler:GetCCBName())
    scrollView:addCellBack(titleCell)
    -- title2
    local contentTitleShowData = {
        str1 = _RALang('@ElectricCellBuildTitle'),
        str2 = _RALang('@ElectricCellNumTitle'),
        str3 = _RALang('@ElectricCellBaseNumTitle'),
        str4 = _RALang('@ElectricCellExtralEffectTitle'),
        extraColor = RAGameConfig.COLOR.YELLOW
    }
    local contentTitleHandler = RAElectricContentCell:New()
    contentTitleHandler:SetData(1, true, contentTitleShowData)
    local contentTitleCell = CCBFileCell:create()            
    contentTitleCell:registerFunctionHandler(contentTitleHandler)
    contentTitleCell:setCCBFile(contentTitleHandler:GetCCBName())
    scrollView:addCellBack(contentTitleCell)
    -- contents
    local datas = RAPlayerInfoManager.getElectricInfoForAllBuildings()
    --按占用电量排序
    datas = Utilitys.table2Array(datas)
    Utilitys.tableSortByKeyReverse(datas, 'electricTotal')
    
    for buildType,oneData in pairs(datas) do
        if oneData.electricTotal > 0 then
            local extraColor = RAGameConfig.COLOR.WHITE
            local electriMaxStr = RALogicUtil:num2k(oneData.electricTotal)
            local electriReduceStr = RALogicUtil:num2k(oneData.reduceValue)
            if oneData.reduceValue > 0 then
                electriReduceStr = _RALang('@MinusWithParam', electriReduceStr)
                extraColor = RAGameConfig.COLOR.GREEN
            end
            local contentShowData = {
                str1 = oneData.buildName,
                str2 = tostring(oneData.count),
                str3 = electriMaxStr,
                str4 = electriReduceStr,
                extraColor = extraColor
            }
            local contentHandler = RAElectricContentCell:New()
            contentHandler:SetData(1, false, contentShowData)
            local contentCell = CCBFileCell:create()            
            contentCell:registerFunctionHandler(contentHandler)
            contentCell:setCCBFile(contentHandler:GetCCBName())
            scrollView:addCellBack(contentCell)
        end
    end
end
function RAElectricInfoPage:_AddArmyCells(scrollView)
    local datas = RAPlayerInfoManager.getElectricInfoForAllArmys()
    if Utilitys.table_count(datas) == 0 then return end
    --添加电力占用
    -- title2
    local contentTitleShowData = {
        str1 = _RALang('@ElectricCellArmyTitle'),
        str2 = _RALang('@ElectricCellNumTitle'),
        str3 = _RALang('@ElectricCellBaseNumTitle'),
        str4 = _RALang('@ElectricCellExtralEffectTitle'),
    }
    local contentTitleHandler = RAElectricContentCell:New()
    contentTitleHandler:SetData(1, true, contentTitleShowData)
    local contentTitleCell = CCBFileCell:create()            
    contentTitleCell:registerFunctionHandler(contentTitleHandler)
    contentTitleCell:setCCBFile(contentTitleHandler:GetCCBName())
    scrollView:addCellBack(contentTitleCell)

    --按占用电量排序
    datas = Utilitys.table2Array(datas)
    Utilitys.tableSortByKeyReverse(datas, 'electricTotal')
    -- contents
    for armyId,oneData in pairs(datas) do
        local electriMaxStr = RALogicUtil:num2k(oneData.electricTotal)
        local electriReduceStr = RALogicUtil:num2k(oneData.reduceValue)
        if oneData.reduceValue > 0 then
            electriReduceStr = _RALang('@MinusWithParam', electriReduceStr)
        end
        local countStr = RALogicUtil:num2k(oneData.count)
        local contentShowData = {
            str1 = oneData.armyName,
            str2 = countStr,
            str3 = electriMaxStr,
            str4 = electriReduceStr,
        }
        local contentHandler = RAElectricContentCell:New()
        contentHandler:SetData(1, false, contentShowData)
        local contentCell = CCBFileCell:create()            
        contentCell:registerFunctionHandler(contentHandler)
        contentCell:setCCBFile(contentHandler:GetCCBName())
        scrollView:addCellBack(contentCell)
    end
end
return RAElectricInfoPage