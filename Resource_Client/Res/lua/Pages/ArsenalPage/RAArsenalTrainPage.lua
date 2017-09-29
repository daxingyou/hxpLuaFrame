--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAArsenalTrainPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RAArsenalManager = RARequire("RAArsenalManager")
local build_conf = RARequire("build_conf")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAArsenalConfig = RARequire("RAArsenalConfig")
local HP_pb = RARequire("HP_pb")
local Utilitys = RARequire("Utilitys")
local Army_pb = RARequire("Army_pb")
local RANetUtil = RARequire("RANetUtil")
local RALogicUtil = RARequire("RALogicUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RAStringUtil = RARequire("RAStringUtil")
local const_conf = RARequire("const_conf")
local RAGameConfig = RARequire("RAGameConfig")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGuideManager = RARequire("RAGuideManager")
local RAGuideConfig = RARequire("RAGuideConfig")
local mArmyId = 0 
local mBuildingUUID = nil
local mArmyCount = 0
local mArmyMaxCount = 0
local mCostGold = 0 
local mBuildTypeId = 0
local mCurTrainType = 0
local mBuildId = 0
RARequire('MessageManager')


local DealGuideKeyArr = 
{
}

function RAArsenalTrainPage:sliderBegan( sliderNode )
    -- body
end
function RAArsenalTrainPage:sliderMoved( sliderNode )
    -- body
    self:refreshSliderValue()
end
function RAArsenalTrainPage:sliderEnded( sliderNode )
    -- body
    self:refreshSliderValue()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.ADD_SOLDIER_C then 
            if mCurTrainType == 1 then
                RARootManager.CloseAllPages()
            else
                --新手期特殊处理
                if RAGuideManager.isInGuide() then
                    RARootManager.CloseAllPages()
                    RARootManager.AddCoverPage()
                else
                    RARootManager.CloseCurrPage()
                end
            end
        end 
    end 
end

function RAArsenalTrainPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAArsenalTrainPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAArsenalTrainPage:Enter(data)
    mArmyId = data.armyId
    mBuildingUUID = data.buildData.id
    mBuildTypeId = data.buildData.confData.buildType
    mBuildId = data.buildData.confData.id
    -- self:RegisterPacketHandler(HP_pb.ADD_SOLDIER_S)
    self:registerMessage()
    assert(mArmyId>0 ,"false")
   
    local ccbfile = UIExtend.loadCCBFile("RAProductionInfoPage.ccbi",self)
    self:_initTitle()
    mArmyCount,mArmyMaxCount = RAArsenalManager:calcMaxTrainNum(mArmyId,mBuildTypeId)

    --新手期造兵特殊处理
    local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
    if keyWord and keyWord == RAGuideConfig.KeyWordArray.ChooseTrainSoldierFirst then
        --第一次造兵，数量是5，时间是5s
        local configCount = tonumber(const_conf.GuideFirstTrainSoldierCount.value)
        if configCount < mArmyCount then
            mArmyCount = configCount
        end
    end

    local barNode = ccbfile:getCCNodeFromCCB("mBarNode")
    --local controlSlider = CCControlSlider:create("mSliderBarBG", "mSliderBar", "mSliderBtn", "mBarNode", self.ccbfile)
    local controlSlider = UIExtend.getControlSlider("mBarNode", self.ccbfile,true)
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
    self.controlSlider:setMinimumValue(1)
	local maxNum = mArmyMaxCount
	self.controlSlider:setMaximumValue(maxNum)

    self.controlSlider:setValue(mArmyCount)
    self:CommonRefresh()

    RAGuideManager.gotoNextStep()
end

function RAArsenalTrainPage:getGuideNodeInfo()
    local upgradeNowBtn = self.ccbfile:getCCNodeFromCCB("mUpgradeNowBtn")
    local worldPos =  upgradeNowBtn:getParent():convertToWorldSpaceAR(ccp(upgradeNowBtn:getPositionX(),upgradeNowBtn:getPositionY()))
    local size = upgradeNowBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = size
    }
    return guideData
end

--desc:获得训练按钮
function RAArsenalTrainPage:getTrainBtnNodeInfo()
    local trainBtn = self.ccbfile:getCCNodeFromCCB("mTrainBtn")
    local worldPos =  trainBtn:getParent():convertToWorldSpaceAR(ccp(trainBtn:getPositionX(),trainBtn:getPositionY()))
    local size = trainBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = size
    }
    return guideData
end

--滑动完滑条
function RAArsenalTrainPage:refreshSliderValue()
	-- body
	local value = RAArsenalTrainPage.controlSlider:getValue()
	value = math.ceil(value)
	RAArsenalTrainPage.controlSlider:setValue(value)

	UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", value)
    mArmyCount = value
    self:_refreshBottomPanel()
end

function RAArsenalTrainPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()
	end
    local armyConf = battle_soldier_conf[mArmyId]
    local titleName = _RALang("@TrainSolider").._RALang(armyConf.name)
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAArsenalTrainPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAArsenalTrainPage:Exit()

    if nil ~= self.controlSlider then
        --todo
        self.controlSlider:removeFromParentAndCleanup(true)
        self.controlSlider = nil
    end
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAArsenalTrainPage")
    UIExtend.unLoadCCBFile(self)

    self:removeMessageHandler()
    -- self:RemovePacketHandlers()
    mArmyId = 0
    mArmyCount = 0 
    mCostGold = 0 
end

function RAArsenalTrainPage:CommonRefresh()
    self:_refreshDescription()
    self:_refreshBottomPanel()
end


function RAArsenalTrainPage:_refreshBottomPanel()
    local txtMap = {}
    local costMap = RAArsenalManager:calcResCostByArmyIdAndCount(mArmyId,mArmyCount)

    local buildConf = build_conf[mBuildId]
    --local trainSpeed = buildConf.trainSpeed or 0
    local oriTime, actualTime = RAArsenalManager:calcTimeCostByArmyIdAndCount(mArmyId,mArmyCount,mBuildTypeId)
    local canOneKeyTrain,totalCostDiamd = RAArsenalManager:isCanOneKeyUpgrade(actualTime,costMap)

    --新手期造兵特殊处理
    local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
    if keyWord and keyWord == RAGuideConfig.KeyWordArray.ChooseTrainSoldierFirst then
        --第一次造兵，数量是5，时间是5s
        local configTime = tonumber(const_conf.GuideFirstTrainSoldierTime.value)
        if configTime < actualTime then
            actualTime = configTime
        end
    end


    txtMap["mNeedGoldNum"] = RALogicUtil:num2k(costMap[tostring(Const_pb.GOLDORE)] or 0)
    txtMap["mNeedOilNum"] = RALogicUtil:num2k(costMap[tostring(Const_pb.OIL)] or 0 )
    txtMap["mNeedSteelNum"] = RALogicUtil:num2k(costMap[tostring(Const_pb.STEEL)] or 0)
    txtMap["mNeedRareEarthsNum"] = RALogicUtil:num2k(costMap[tostring(Const_pb.TOMBARTHITE)] or 0)

    txtMap["mWantTrainingNum"] = mArmyCount
    txtMap["mNeedDiamondsNum"] = totalCostDiamd
    mCostGold = totalCostDiamd
    txtMap["mActualTime"] = Utilitys.createTimeWithFormat(actualTime)
    txtMap["mOriginalTime"] =  Utilitys.createTimeWithFormat(oriTime)
    
    local armyConf = battle_soldier_conf[mArmyId]
    local res = RAStringUtil:parseWithComma(armyConf.res)
    local txtColorMap = {}
    txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.WHITE
    
    for k,v in ipairs(res) do
        local needValue = costMap[tostring(v.id)]
        local currValue = RAPlayerInfoManager.getResCountById(v.id)
        if v.id == Const_pb.GOLDORE then
            if needValue > currValue then
                txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.RED
            end
        end
        if v.id == Const_pb.OIL then
            if needValue > currValue then
                txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.RED
            end
        end
        if v.id == Const_pb.STEEL then
            if needValue > currValue then
                txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.RED
            end
        end
        if v.id == Const_pb.TOMBARTHITE then
            if needValue > currValue then
                txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.RED
            end
        end
    end
    
    UIExtend.setColorForLabel(self.ccbfile, txtColorMap)

    UIExtend.setStringForLabel(self.ccbfile,txtMap)
end

function RAArsenalTrainPage:_refreshDescription()
    local RACoreDataManager = RARequire("RACoreDataManager")
    local armyInfo = RACoreDataManager:getArmyInfoByArmyId(mArmyId)
    local curCount = 0 
    if armyInfo~=nil and armyInfo.freeCount > 0 then
        curCount = armyInfo.freeCount
    end
    local armyConf = battle_soldier_conf[mArmyId]
    local txtMap = {}
    txtMap["mCurrentNum"] = _RALang("@currentHave")..curCount
    txtMap["mAttackNum"] = tostring(armyConf.attack) --_RALang("@ArmyAttact")..armyConf.attack
    txtMap["mDefenseNum"] = tostring(armyConf.defence)--_RALang("@ArmyDefence")..armyConf.defence
    txtMap["mLifeNum"] = tostring(armyConf.hp)--_RALang("@ArmyLife")..armyConf.hp

    UIExtend.setStringForLabel(self.ccbfile,txtMap)
    
    UIExtend.addSpriteToNodeParent(self.ccbfile,"mBigIconNode", armyConf.show)
    
    
    local vecSub = RAStringUtil:split(armyConf.subdue,",")
    assert(#vecSub == 2, "#vecSub == 2")
    local desStr = RAStringUtil:getHTMLString("ArsenalTrainDes",
    armyConf.power,armyConf.load,armyConf.speed,armyConf.energyCost,_RALang(vecSub[1]),_RALang(vecSub[2])) 
    local labelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mDetailsLabel")
    labelHtml:setPreferredSize(219,150)
    UIExtend.setCCLabelHTMLString(self.ccbfile,"mDetailsLabel",desStr)

    local redBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mRedBar")
    local blueBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBlueBar")
    local greenBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mGreenBar")

    local soldierPropertyMaxValue = const_conf.soldierPropertyMax.value
    local soldierPropertyTable = RAStringUtil:split(soldierPropertyMaxValue,"_")
    
    Utilitys.barActionPlay(redBar,{value = armyConf.hp,baseValue = soldierPropertyTable[1],valueScale = 0.3})
    Utilitys.barActionPlay(blueBar,{value = armyConf.attack,baseValue = soldierPropertyTable[2],valueScale = 0.3})
    Utilitys.barActionPlay(greenBar,{value = armyConf.defence,baseValue = soldierPropertyTable[3],valueScale = 0.3})
end

function RAArsenalTrainPage:onSubBtn()
    local value = self.controlSlider:getValue()
    if value >= 2 then
	    value = tonumber(value-1)
	    RAArsenalTrainPage.controlSlider:setValue(value)
	    UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", self.controlSlider:getValue())
        mArmyCount = value
        self:_refreshBottomPanel()
    end
end

function RAArsenalTrainPage:onAddBtn()
    local value = self.controlSlider:getValue()
    if value < mArmyMaxCount then
        value = tonumber(value+1)
	    RAArsenalTrainPage.controlSlider:setValue(value)
	    UIExtend.setCCLabelString(self.ccbfile,"mWantTrainingNum", self.controlSlider:getValue())
        mArmyCount = value
        self:_refreshBottomPanel()
    else
        --tips is max
    end
	
end


function RAArsenalTrainPage:_getSelectedArmyElectricCost()
    local electricAdd = RAPlayerInfoManager.getArmyElectricConsume({mArmyId = mArmyCount})
    return electricAdd
end

function RAArsenalTrainPage:onTrainBtn()
    if mArmyCount <= 0 then
        RARootManager.ShowMsgBox("@TrainingCanNot0")
        return;
    end

    --- 训练兵时要增加电力警告判断
    local electricAdd = self:_getSelectedArmyElectricCost()
    local trainFunc = function()
        local cmd = Army_pb.HPAddSoldierReq()
        cmd.armyId = mArmyId
        cmd.soldierCount = mArmyCount
        cmd.buildingUUID = mBuildingUUID
        cmd.isImmediate = false

        --新手期造兵特殊处理
        local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
        if keyWord and keyWord == RAGuideConfig.KeyWordArray.CircleTrainSoldierBtnFirst then
            --第一次造兵，数量是5，时间是5s
            cmd.flag = RAGuideConfig.TrainSoldierMagicFlag--跟后端商量好的魔法字
        end


        RANetUtil:sendPacket(HP_pb.ADD_SOLDIER_C, cmd)
        mCurTrainType = 0   --普通训练模式
        --移除guidePage:add by xinghui
        if RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage({["update"] = true})
        end
        RARootManager.RemoveGuidePage()
    end
    RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, trainFunc)
end

function RAArsenalTrainPage:sendOneKey()
    if mArmyCount <= 0 then
        RARootManager.ShowMsgBox("@TrainingCanNot0")
        return;
    end
    local cmd = Army_pb.HPAddSoldierReq()
    cmd.armyId = mArmyId
    cmd.buildingUUID = mBuildingUUID
    cmd.soldierCount = mArmyCount
    cmd.isImmediate = true
    cmd.gold = mCostGold
    RANetUtil:sendPacket(HP_pb.ADD_SOLDIER_C, cmd)
    mCurTrainType = 1   --一键升级模式
end


function RAArsenalTrainPage:onUpgradeNowBtn()
    if RAGuideManager.isInGuide() then
        self:sendOneKey()
    else
        --- 训练兵时要增加电力警告判断
        local electricAdd = self:_getSelectedArmyElectricCost()
        local trainFunc = function()
            local confirmData = {}
            confirmData.yesNoBtn = true
            confirmData.labelText = _RALang("@isOneKeyCompleteTips")
            confirmData.resultFun = function (isOk)
                if isOk then
                    self:sendOneKey()
                    --RARootManager.CloseCurrPage()
                else
                    --RARootManager.CloseCurrPage()
                end 
            end
            RARootManager.OpenPage("RAConfirmPage", confirmData) 
        end
        RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, trainFunc)
    end
end


-- function RAArsenalTrainPage:onReceivePacket(handler)
--     local pbCode = handler:getOpcode()
--     local buffer = handler:getBuffer()
--     if pbCode == HP_pb.ADD_SOLDIER_S then
--         local msg = Army_pb.HPAddSoldierResp()
--         msg:ParseFromString(buffer)
--         if msg.result == true then
--             if mCurTrainType == 1 then
--                 RARootManager.CloseAllPages()
--             else
--                 RARootManager.CloseCurrPage()
--             end
            
--         end
--     end
-- end


return RAArsenalTrainPage
--endregion
