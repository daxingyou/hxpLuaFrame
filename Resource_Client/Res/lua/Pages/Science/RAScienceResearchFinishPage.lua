--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


--学院研究子页面 科技研究完成界面

local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb = RARequire('Const_pb')
local build_conf = RARequire("build_conf")
local Utilitys = RARequire("Utilitys")
local RALogicUtil = RARequire("RALogicUtil")
-- local RAQueueManager= RARequire("RAQueueManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RABuildManager = RARequire("RABuildManager")
local RAScienceUtility = RARequire("RAScienceUtility")
local RA_Common = RARequire("common")


local RAScienceResearchFinishPage = BaseFunctionPage:new(...)
local tech_conf = RARequire("tech_conf")


local TAG = 1000

function RAScienceResearchFinishPage:Enter(data)


	CCLuaLog("RAScienceResearchFinishPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RACollegePopUp2.ccbi",self)
	self.ccbfile  = ccbfile
	self.data = data.scienceInfo
	self.maxLevel = data.maxLevel
	
	self:init()

end



function RAScienceResearchFinishPage:init()

	-- --初始化

	local titleName = _RALang(self.data.techName )
	UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle",titleName)

	--icon
	local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mCellSkillIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,self.data.techPic,TAG)

	--process
	local curLevel = self.data.techLevel
	local maxLevel=RAScienceUtility:getScienceMaxLevel(self.data.id)
	local levelStr = _RALang("@ScienceLevel",curLevel,maxLevel)
	UIExtend.setCCLabelString(self.ccbfile,"mCellLevel",levelStr)
	local RAGameConfig=RARequire("RAGameConfig")
	UIExtend.setLabelTTFColor(self.ccbfile,"mCellLevel",RAGameConfig.COLOR.GREEN)
	
	local des = _RALang(self.data.techDes)
	UIExtend.setCCLabelString(self.ccbfile,"mSkillExplain",des)
	--根据作用号获取当前等级和下一等级的效果
	UIExtend.setNodeVisible(self.ccbfile,"mEffectNode1",false)	
	
	

	if  self.data.techEffectID then
		UIExtend.setNodeVisible(self.ccbfile,"mEffectNode2",true)
		local keyStr = self.data.techTip 
		local cueEffectValue  = RAScienceUtility:getEffectValueById(self.data.id)
		UIExtend.setCCLabelString(self.ccbfile,"mEffect2",_RALang("@ScienceEffect").._RALang(keyStr,cueEffectValue))
	else
		UIExtend.setNodeVisible(self.ccbfile,"mEffectNode2",false)
	end 

	
	
	
end


function RAScienceResearchFinishPage:onClose( )
	RARootManager.CloseCurrPage()
end

function RAScienceResearchFinishPage:onConfirm( )
	RARootManager.CloseCurrPage()
end

function RAScienceResearchFinishPage:Exit()
	
	UIExtend.unLoadCCBFile(RAScienceResearchPage)
	--ScrollViewAnimation.clearTable()
end
--endregion
