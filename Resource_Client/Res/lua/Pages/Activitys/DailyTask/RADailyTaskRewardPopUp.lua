--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RADailyTaskActivityManager = RARequire("RADailyTaskActivityManager")
local RADailyTaskActivityUtility = RARequire("RADailyTaskActivityUtility")
local RA_Common = RARequire("common")

RARequire("MessageDefine")
RARequire("MessageManager")

local updateMsg = MessageDef_DailyTaskStatus.MSG_DailyTask_Changed



local RADailyTaskRewardPopUp = BaseFunctionPage:new(...)

-------------------------Cell Begin--------------------------------

local RADailyTaskRewardExplainCell = {

}
function RADailyTaskRewardExplainCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskRewardExplainCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskRewardExplainCell:onRefreshContent")
	if not ccbRoot then return end
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local isStage = self.isStage
    local configData = nil
    local keyStr = ""
    if isStage then
    	keyStr = "DailyTaskRewardExPlain"
    else
    	keyStr = "DailyTaskRewardActivityExPlain"
    end 
  
    local str = RAStringUtil:getHTMLString(keyStr)
    UIExtend.setCCLabelHTMLString(ccbfile,"mExplain",str)
   

	
end

local RADailyTaskRewardTitleCell = {

}
function RADailyTaskRewardTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskRewardTitleCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskRewardTitleCell:onRefreshContent")
	if not ccbRoot then return end
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile
   
    local title=""
    local data =self.data
    local preData=self.preData
    local rankIndex = data.rank
    if preData then
    	local preRankIndex = preData.rank+1	
    	title = _RALang("@ActivityRewardRank",preRankIndex.."~"..rankIndex)
    else
    	title = _RALang("@ActivityRewardRank",rankIndex)
    end
    UIExtend.setCCLabelString(ccbfile,"mCellTitle",title)

	
end

local RADailyTaskRewardCell = {

}
function RADailyTaskRewardCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RADailyTaskRewardCell:onRefreshContent(ccbRoot)

	CCLuaLog("RADailyTaskRewardCell:onRefreshContent")
	if not ccbRoot then return end
	self.ccbRoot = ccbRoot
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local rankData = self.data
    local rewardData= rankData.reward
	local icon = rewardData.item_icon
	local name = rewardData.item_name
	local num = rewardData.num
	UIExtend.setCCLabelString(ccbfile,"mItemName",_RALang(name))
	UIExtend.setCCLabelString(ccbfile,"mItemNum",num)
	UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
  
end


-------------------------Cell End----------------------------------

---------------------------------------------------------------------

-- id:活动id或者阶段id
function RADailyTaskRewardPopUp:Enter(data)


	CCLuaLog("RADailyActivityRewardPopUp:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAActivityRewardPopUp.ccbi",self)
	self.ccbfile  = ccbfile
	self.id  = data.id
	self.isStage = data.isStage
    self:init()
    self:updateInfo()
    
end

function RADailyTaskRewardPopUp:init()

	self.listSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV")
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@ActivityRewardTitle"))
	
end


function RADailyTaskRewardPopUp:updateInfo()
	self.listSV:removeAllCell()
	local scrollview = self.listSV

	--explain
	local explainCell = CCBFileCell:create()
	local explainPanel = RADailyTaskRewardExplainCell:new({
			id = self.id,
			isStage = self.isStage
    })
	explainCell:registerFunctionHandler(explainPanel)
	explainCell:setCCBFile("RAActivityRewardCell1.ccbi")
	self.listSV:addCellBack(explainCell)


	-- title and reward
	local rankDatas=nil
	if self.isStage then
		rankDatas = RADailyTaskActivityUtility:getRankRewardDataByStageId(self.id)
	else
		rankDatas = RADailyTaskActivityUtility:getRankRewardDataByActivityId(self.id)
	end 

	local count = #rankDatas
	for i=1,count do
		local rankData = rankDatas[i]
		local preRankData = nil
		if i>3 then
			preRankData = rankDatas[i-1]
		end 

		--title
		local titleCell = CCBFileCell:create()
		local titlePanel = RADailyTaskRewardTitleCell:new({
				data= rankData,
				preData = preRankData,
	    })
		titleCell:registerFunctionHandler(titlePanel)
		titleCell:setCCBFile("RAActivityRewardCell2.ccbi")
		self.listSV:addCellBack(titleCell)

		--reward
		local rewardCell = CCBFileCell:create()
		local rewardPanel = RADailyTaskRewardCell:new({
				data= rankData,
	    })
		rewardCell:registerFunctionHandler(rewardPanel)
		rewardCell:setCCBFile("RAActivityRewardCell3.ccbi")
		self.listSV:addCellBack(rewardCell)
	end
	scrollview:orderCCBFileCells(scrollview:getViewSize().width)
	
end


function RADailyTaskRewardPopUp:Exit()
	self.listSV:removeAllCell()
	UIExtend.unLoadCCBFile(RADailyTaskRewardPopUp)
	
end

function RADailyTaskRewardPopUp:onClose()
	RARootManager.CloseCurrPage()
end

function RADailyTaskRewardPopUp:mCommonTitleCCB_onBack()
	self:onClose()
end


--endregion
