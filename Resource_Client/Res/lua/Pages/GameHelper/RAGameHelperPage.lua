--region RAGameHelperPage.lua


local RAGameHelperPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RAChooseBuildManager = RARequire("RAChooseBuildManager")
local RABuildManager = RARequire("RABuildManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local build_conf = RARequire("build_conf")
local build_ui_conf = RARequire("build_ui_conf")
local RAGuideManager = RARequire("RAGuideManager")
local RAGameHelperManager = RARequire('RAGameHelperManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAQueueManager = RARequire('RAQueueManager')
local Utilitys = RARequire('Utilitys')
local RAPlayerEffect = RARequire('RAPlayerEffect')
local RAMarchDataManager = RARequire('RAMarchDataManager')
	
local cellHeight2 = 60
local cellHeight3 = 132
local TimerBarTag = 999

local HelperType = {
        HelperBuild = 1,
        HelperWorld = 2,
        HelperArmy = 3
}


local lastGuideLabelIndex = 1

local RAGameHelperArmyCell = {
}

function RAGameHelperArmyCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAGameHelperArmyCell:load()
    local ccbi = UIExtend.loadCCBFile("RALittleHelperCell3.ccbi", self)
    return ccbi
end


function  RAGameHelperArmyCell:getCCBFile()
    return self.ccbfile
end

function  RAGameHelperArmyCell:updateInfo()
    local ccbfile = self:getCCBFile()
    for i,v in ipairs(self.data) do
        local bar = UIExtend.getCCSpriteFromCCB(ccbfile, "mBar"..i)
        local progressNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarNode"..i)
        local mainNode = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierNode"..i)
        bar:setVisible(v.queueData ~= nil)

        if v.queueData ~= nil then
            local diffTiem = Utilitys.getCurDiffTime(v.queueData.endTime)
            local countPercent = 1 - diffTiem/(v.queueData.endTime - v.queueData.startTime)            
            local progressTimerBar = progressNode:getChildByTag(TimerBarTag)
            if progressTimerBar == nil then
                progressTimerBar = CCProgressTimer:create(bar)
                progressNode:addChild(progressTimerBar)
            end
            progressTimerBar:setTag(TimerBarTag)
            progressTimerBar:setPercentage(countPercent * 100)
            progressNode:setVisible(true)
            bar:setVisible(false)
            progressNode:setScale(1)
        elseif #v.building == 0 then
            progressNode:setVisible(false)
            local grayTag = 10000 + i
            mainNode:getParent():removeChildByTag(grayTag,true)            
            local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
            graySprite:setTag(grayTag)
            graySprite:setPosition(mainNode:getPosition())
            graySprite:setAnchorPoint(mainNode:getAnchorPoint())
            mainNode:getParent():addChild(graySprite)            
        end

    end
end

function RAGameHelperArmyCell:onExecute(  )
    local ccbfile = self:getCCBFile()
    for i,v in ipairs(self.data) do
        local bar = UIExtend.getCCSpriteFromCCB(ccbfile, "mBar"..i)
        local progressNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarNode"..i)
        local mainNode = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierNode"..i)

        if v.queueData ~= nil then
            local diffTiem = Utilitys.getCurDiffTime(v.queueData.endTime)
            local countPercent = 1 - diffTiem/(v.queueData.endTime - v.queueData.startTime)            
            local progressTimerBar = progressNode:getChildByTag(TimerBarTag)
            progressTimerBar:setPercentage(countPercent * 100) 
        else
            progressNode:setVisible(false)
        end
    end
end

function RAGameHelperArmyCell:onJump( data )
    if data.queueDatas then
        RARootManager.CloseCurrPage()
        RAGameHelperManager:gotoHud(data.type, BUILDING_BTN_TYPE.SPEEDUP, true)
    elseif #data.building > 0 then
        RARootManager.CloseCurrPage()
        RAGameHelperManager:gotoHud(data.type, data.btnType, true)
    else
        RARootManager.CloseCurrPage()
        RAGameHelperManager:openChooseBuilding(data.type)
    end
end

function RAGameHelperArmyCell:onJumpBtn1( ... )
    RARootManager.CloseCurrPage()
    RAGameHelperManager:onSoilderClick(self.data[1])
end

function RAGameHelperArmyCell:onJumpBtn2( ... )
    RARootManager.CloseCurrPage()
    RAGameHelperManager:onSoilderClick(self.data[2])
end

function RAGameHelperArmyCell:onJumpBtn3( ... )
    RARootManager.CloseCurrPage()
    RAGameHelperManager:onSoilderClick(self.data[3])
end

function RAGameHelperArmyCell:onJumpBtn4( ... )
    RARootManager.CloseCurrPage()
    RAGameHelperManager:onSoilderClick(self.data[4])
end


local RAGameHelperBuildCell = {}

function RAGameHelperBuildCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAGameHelperBuildCell:load()
	local ccbi = UIExtend.loadCCBFile("RALittleHelperCell2.ccbi", self)
    return ccbi
end

function  RAGameHelperBuildCell:getCCBFile()
	return self.ccbfile
end

function  RAGameHelperBuildCell:updateInfo()
	local ccbfile = self:getCCBFile()

    if self.type == HelperType.HelperBuild then
        UIExtend.setCCLabelString(ccbfile, "mName", _RALang("@HelperBuild"..self.id))
        UIExtend.setControlButtonTitle(ccbfile, "mFunctionBtn1", _RALang("@Goto"))
        UIExtend.setControlButtonTitle(ccbfile, "mFunctionBtn3", _RALang("@Free"))
    	if #self.data.queueDatas > 0 then
            local queueData = self.data.queueDatas[1]
    		local isFree =  RAQueueManager:isBuildQueueInFreeTime( queueData )
    		UIExtend.setNodesVisible(ccbfile, {
    											mBarNode = true,
    											mStateLabel = false,
    											mExplainLabel = false,
    											mFunctionBtn1 = false,
    											mFunctionBtn3 = isFree,
    											mTime = not isFree
    											})

            local bar = UIExtend.getCCSpriteFromCCB(ccbfile, "mBar")

    		local diffTiem = Utilitys.getCurDiffTime(queueData.endTime)
            local timeScale = 1 - diffTiem/(queueData.endTime - queueData.startTime)
            bar:setScaleX(timeScale * 275)
            if not isFree then
                UIExtend.setCCLabelString(ccbfile,"mTime", Utilitys.createTimeWithFormat(diffTiem))
            end
    	else
            UIExtend.setNodesVisible(ccbfile, {
                                                mBarNode = false,
                                                mStateLabel = true,
                                                mExplainLabel = false,
                                                mFunctionBtn1 = true,
                                                mFunctionBtn3 = false,
                                                mTime = false
                                                })        
            UIExtend.setCCLabelString(ccbfile, "mStateLabel", _RALang("@FreeTime"))
    	end
    elseif self.type == HelperType.HelperWorld then
        UIExtend.setCCLabelString(ccbfile, "mName", _RALang("@HelperWorld"..self.id))
        UIExtend.setControlButtonTitle(ccbfile, "mFunctionBtn1", _RALang("@Dispatch"))
        local nowMarchCount = RAMarchDataManager:GetSelfMarchCount()
        local maxMarchCount = RAQueueManager:getQueueMaxCounts(Const_pb.MARCH_QUEUE)
        local explainStr = ""
        if nowMarchCount < maxMarchCount then
            explainStr = _RALang("@HelperWorldExplain"..self.id)
        else
            explainStr = _RALang("@WaitingMarchCount")
        end
        UIExtend.setCCLabelString(ccbfile, "mExplainLabel",explainStr)        


        UIExtend.setNodesVisible(ccbfile, {
                                            mBarNode = false,
                                            mStateLabel = false,
                                            mExplainLabel = true,
                                            mFunctionBtn1 = nowMarchCount < maxMarchCount,
                                            mFunctionBtn3 = false,
                                            mTime = false
                                            })

    else
        UIExtend.setCCLabelString(ccbfile, "mName", _RALang("@HelperArmy"))
        UIExtend.setControlButtonTitle(ccbfile, "mFunctionBtn1", _RALang("@HelperTrain"))
        UIExtend.setNodesVisible(ccbfile, {
                                            mBarNode = false,
                                            mStateLabel = false,
                                            mExplainLabel = false,
                                            mFunctionBtn1 = true,
                                            mFunctionBtn3 = false,
                                            mTime = false
                                            })        
    end
end


function RAGameHelperBuildCell:onExecute(  )
    local ccbfile = self:getCCBFile()
    if self.type == HelperType.HelperBuild then
        if #self.data.queueDatas > 0 then
            local queueData = self.data.queueDatas[1]
            local isFree =  RAQueueManager:isBuildQueueInFreeTime( queueData )
            UIExtend.setNodesVisible(ccbfile, {
                                                mFunctionBtn3 = isFree,
                                                mTime = not isFree
                                                })

            local bar = UIExtend.getCCSpriteFromCCB(ccbfile, "mBar")

            local diffTiem = Utilitys.getCurDiffTime(queueData.endTime)
            local timeScale = 1 - diffTiem/(queueData.endTime - queueData.startTime)
            bar:setScaleX(timeScale * 275)
            if not isFree then
                UIExtend.setCCLabelString(ccbfile,"mTime", Utilitys.createTimeWithFormat(diffTiem))
            end        
        else
            UIExtend.setNodesVisible(ccbfile, {
                                                mBarNode = false,
                                                mStateLabel = true,
                                                mFunctionBtn1 = true,
                                                mFunctionBtn3 = false,
                                                mTime = false
                                                })        
            UIExtend.setCCLabelString(ccbfile, "mStateLabel", _RALang("@FreeTime"))
        end
    elseif self.type == HelperType.HelperWorld then
        local nowMarchCount = RAMarchDataManager:GetSelfMarchCount()
        local maxMarchCount = RAQueueManager:getQueueMaxCounts(Const_pb.MARCH_QUEUE)
        local explainStr = ""
        if nowMarchCount < maxMarchCount then
            explainStr = _RALang("@HelperWorldExplain"..self.id)
        else
            explainStr = _RALang("@WaitingMarchCount")
        end
        UIExtend.setCCLabelString(ccbfile, "mExplainLabel",explainStr)        


        UIExtend.setNodesVisible(ccbfile, {
                                            mFunctionBtn1 = nowMarchCount < maxMarchCount,
                                            })

    end
end

function  RAGameHelperBuildCell:onFunctionBtn1()
    if self.type == HelperType.HelperBuild then
        RARootManager.CloseCurrPage()
        RAGameHelperManager:buildGuide(self.data)
    elseif self.type == HelperType.HelperWorld then
        local nowMarchCount = RAMarchDataManager:GetSelfMarchCount()
        local maxMarchCount = RAQueueManager:getQueueMaxCounts(Const_pb.MARCH_QUEUE)
        if nowMarchCount < maxMarchCount then
            local param = {}
            param.pages = {{pageName = 'RASearchPage', pageArg = {selectType = self.id},  isUpdate = true, needNotToucherLayer = true, isBlankClose = true}}
            RARootManager.ChangeScene(SceneTypeList.WorldScene, false, param)
        end
    elseif self.type == HelperType.HelperArmy then

        for i,data in ipairs(self.armyDatas) do
            if #data.building > 0 and data.queueData == nil then
                RARootManager.CloseCurrPage()
                RAGameHelperManager:gotoHud(data.type, data.btnType, true)
                return
            end
        end
        for i,data in ipairs(self.armyDatas) do
            if data.queueData then
                RARootManager.CloseCurrPage()
                RAGameHelperManager:gotoHud(data.type, BUILDING_BTN_TYPE.SPEEDUP, true)
                return
            end
        end         
    end

end

function RAGameHelperBuildCell:onClick(  )
    --self:onFunctionBtn1()
end

function  RAGameHelperBuildCell:onFunctionBtn3()
    if #self.data.queueDatas <= 0 then
        return
    end
    local btnType = BUILDING_BTN_TYPE.SPEEDUP
	if self.data.type == Const_pb.BUILDING_QUEUE or self.data.type == Const_pb.BUILDING_DEFENER  then
		local isFree = RAQueueManager:isBuildQueueInFreeTime( self.data.queueDatas[1] )
		if isFree then
			RAQueueManager:sendQueueFreeFinish(self.data.queueDatas[1].id)
            RARootManager.ClosePage("RAGameHelperPage")
			return
		end
    end

--    local queueData = self.data.queueDatas[1]
--    if queueData == nil then 
--        return
--    end
--    local isFree =  RAQueueManager:isBuildQueueInFreeTime( queueData )
--    RAQueueManager:sendQueueFreeFinish(queueData.id)
--    RARootManager.ClosePage("RAGameHelperPage")
end


local RAGameHelperCell = {}

function RAGameHelperCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAGameHelperCell:onRefreshContent(ccbRoot)
    ccbRoot:setIsScheduleUpdate(true)
    local ccbfile = ccbRoot:getCCBFileNode() 
    local bg = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBG")
    if bg then
    	bg:setContentSize(ccbRoot:getContentSize())
        bg:setPositionY(bg:getContentSize().height - 140)
        local bgHeight = bg:getContentSize().height - 20
        local cellNode = UIExtend.getCCNodeFromCCB(ccbfile,"mCellNode")
        cellNode:removeAllChildren()
        self.cells = {}
		for i,v in ipairs(self.data) do
			if not v.hide then
				local panel = RAGameHelperBuildCell:new({
						data=v,
						type = self.type,
                        id = i,
                        armyDatas = self.armyDatas
				})
			    local ccbi=panel:load()
		  	    panel:updateInfo()
                ccbi:setPositionY(bgHeight - cellHeight2*i)
                cellNode:addChild(ccbi)
                self.cells[i] = panel
			end
		end

        if self.armyDatas then
            local panel = RAGameHelperArmyCell:new({
                    data=self.armyDatas,
            })
            local ccbi=panel:load()
            panel:updateInfo()       
            cellNode:addChild(ccbi)
            self.armyCell = panel
        end

    end
end

function RAGameHelperCell:onExecute()
    self.updateCountTime = self.updateCountTime or 0
    self.updateCountTime = self.updateCountTime + GamePrecedure:getInstance():getFrameTime()
   
    if  self.updateCountTime > 1 then
        self.updateCountTime = 0
        for i,cell in ipairs(self.cells) do
            cell:onExecute()
        end
        if self.armyCell then
            self.armyCell:onExecute()
        end
    end
end

function RAGameHelperPage:_scaleCCB()
    local resSize = UIExtend.getDesignResolutionSize()
    local scale = resSize.height/1136
    --if self.ccbfile:getIsFirstCreate() then
        local mAniNode = self.ccbfile:getCCNodeFromCCB("mAniNode")
        mAniNode:setScale(scale)
    --end

end

function RAGameHelperPage:onClick(  )
    lastGuideLabelIndex = lastGuideLabelIndex + 1
    local const_conf = RARequire("const_conf")
    if lastGuideLabelIndex > const_conf.HelperTipsNum.value then
        lastGuideLabelIndex = 1
    end
    UIExtend.setCCLabelString(RAGameHelperPage.ccbfile, "mBubbleLabel", _RALang("@LittleHelper"..lastGuideLabelIndex), 18)    
end

function RAGameHelperPage:Enter(data)
    RAGameHelperPage:registerMessageHandlers()
    local ccbfile = UIExtend.loadCCBFile("RALittleHelperPopUp.ccbi",self)
    -- self:_scaleCCB()
    UIExtend.setCCLabelString(ccbfile, "mBubbleLabel", _RALang("@LittleHelper"..lastGuideLabelIndex),18)
    local targetHtmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mClickMe") 
    targetHtmlLabel:setString(_RAHtmlFill("@ClickMe"))
    local RAChatManager = RARequire("RAChatManager")
    targetHtmlLabel:registerLuaClickListener(function ( id, data )
        RAGameHelperPage:onClick()
    end)

    RAGameHelperManager:getQueueData()

    local scrollView = ccbfile:getCCScrollViewFromCCB("mListSV")
   	self.scrollView = scrollView
   	local count = #RAGameHelperManager.buildDatas
	if #RAGameHelperManager.buildDatas[4].queueDatas == 0 then
		local sure = RABuildManager:getBuildDataArray(Const_pb.HOSPITAL_STATION)
		if #sure > 0 and RACoreDataManager:getArmyWoundedSumCount() == 0 then
			RAGameHelperManager.buildDatas[4].hide = true
			count = count - 1
		end
	end

	scrollView:removeAllCell()
    local cell = CCBFileCell:create()
	cell:setCCBFile("RALittleHelperCell1.ccbi")
	local panel = RAGameHelperCell:new({
			data = RAGameHelperManager.buildDatas,
			type = HelperType.HelperBuild
		})
	cell:registerFunctionHandler(panel)
	cell:setContentSize(CCSize(cell:getContentSize().width, 20 + count*cellHeight2))
	scrollView:addCell(cell)	

    local cell = CCBFileCell:create()
	cell:setCCBFile("RALittleHelperCell1.ccbi")
	local panel = RAGameHelperCell:new({
			data = {{},{}},
			type = HelperType.HelperWorld
		})
	cell:registerFunctionHandler(panel)
	cell:setContentSize(CCSize(cell:getContentSize().width, 20 + 2*cellHeight2))
	scrollView:addCell(cell)	
    

    local cell = CCBFileCell:create()
	cell:setCCBFile("RALittleHelperCell1.ccbi")
	local panel = RAGameHelperCell:new({
            data = {{}},
			armyDatas = RAGameHelperManager.armyDatas,
			type = HelperType.HelperArmy
		})
	cell:registerFunctionHandler(panel)
	cell:setContentSize(CCSize(cell:getContentSize().width, 20 + cellHeight2 + cellHeight3))
	scrollView:addCell(cell)	

    scrollView:orderCCBFileCells()	

end


function RAGameHelperPage:Exit()
    RAGameHelperPage:unregisterMessageHandlers()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
    RAGameHelperManager:reset()
end




local OnReceiveMessage = function (message)
 CCLuaLog("RAGameHelperPage OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        if message.queueType ~= nil then
            RAGameHelperManager:deleteQueue(message.queueType, message.queueId)
        end
    end
end

function RAGameHelperPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
end

function RAGameHelperPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
end


--function related
function RAGameHelperPage:onClose(data)

    RARootManager.CloseCurrPage()
end

--endregion
