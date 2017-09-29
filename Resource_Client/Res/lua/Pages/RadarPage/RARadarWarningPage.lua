--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--雷达列表界面


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb =RARequire('Const_pb')
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAGameConfig=RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local RARadarManage=RARequire("RARadarManage")


local marchDeleteMsg = MessageDef_Radar.MSG_DELETE
local marchUpdateMsg = MessageDef_Radar.MSG_UPDATE
local marchAddMsg = MessageDef_Radar.MSG_ADD
local RARadarWarningPage = BaseFunctionPage:new(...)




--RARadarWarningPageCell
-----------------------------------------------------------------------
local RARadarWarningPageCell = {

}
function RARadarWarningPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RARadarWarningPageCell:onRefreshContent(ccbRoot)
	CCLuaLog("RABuildMoreInfoPageCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	local marchType=self.marchType
	local marchId=self.marchrId

	if RARadarManage:isNuclearExplosion(marchId) then 						--核弹爆炸
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",_RALang("@RadarShowNuclearExplosionTitle"))
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.ROSERED)
	elseif RARadarManage:isLightningStorm(marchId) then 					--雷暴
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",_RALang("@RadarShowLightningStormTitle"))
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.ROSERED)
	elseif RARadarManage:isMassWaitMarch(marchId)	then 					--士兵集结中

		--在按目标点继续细分子类型  
		local warningTitle=RARadarManage:getShowTitleByUuid(marchId,RARadarManage.Type.MASSWAIT)

		UIExtend.setCCLabelString(ccbfile,"mContentLabel",warningTitle)
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.RED)
	elseif RARadarManage:isMassMarch(marchId)	then 						--士兵集结后行军

		--在按目标点继续细分子类型 
		local warningTitle=RARadarManage:getShowTitleByUuid(marchId,RARadarManage.Type.MASSMARCH)
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",warningTitle)
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.RED)
	elseif RARadarManage:isAttackMarch(marchId) then 						--普通行军

		--在按目标点继续细分子类型 
		local warningTitle=RARadarManage:getShowTitleByUuid(marchId,RARadarManage.Type.ATTACK)
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",warningTitle)
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.RED)
	elseif RARadarManage:isRadarAssistanceSoldierData(marchId) then 		--士兵援助
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",_RALang("@RadarAssistanceSoldierTitle"))
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.GREEN)
	elseif RARadarManage:isRadarAssistanceResourceData(marchId) then 		--资源援助
		UIExtend.setCCLabelString(ccbfile,"mContentLabel",_RALang("@RadarAssistanceResourceTitle"))
		UIExtend.setLabelTTFColor(ccbfile,"mContentLabel",RAGameConfig.COLOR.LIGHTBULE)
	end 

end

function RARadarWarningPageCell:onCellClickBtn()
	--跳转到相应的界面 只要传入marchId
	local data={}
	data.marchId=self.marchrId
	data.desStr=RARadarWarningPage.buildData.buildDes
	RARootManager.OpenPage("RARadarInfomationPage", data,true,true)
end

local OnReceiveMessage = function(message)
   if message.messageID == marchDeleteMsg then  --删除 (行军到达 行军撤销)
   		RARadarWarningPage:updateInfo()
   elseif message.messageID == marchAddMsg then --新增 (行军开始)
  		RARadarWarningPage:updateInfo()
   elseif message.messageID == marchUpdateMsg then --更新 (行军加速)
   		RARadarWarningPage:updateInfo()
   end 
end

-----------------------------------------------------------------------
function RARadarWarningPage:Enter(data)


	CCLuaLog("RARadarWarningPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RARadarWarningPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.buildData=data.confData
	
	self:registerMessageHandler()
	self:init()

end

function RARadarWarningPage:init()

	--title
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarInformation"))
	UIExtend.setCCLabelString(self.ccbfile,"mExplainLabel",_RALang(self.buildData.buildDes))

	--判断文字是否需要滚动
	self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
	self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
	UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

	self.mWarningListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mWarningListSV")
	self:updateInfo()
	

end



function RARadarWarningPage:showTips(isVisible)
	UIExtend.setNodeVisible(self.ccbfile,"mNoWarningTips",isVisible)
end

function RARadarWarningPage:updateInfo()
   self.mWarningListSV:removeAllCell()
   local scrollview = self.mWarningListSV

   local radarDatas=RARadarManage:getRadarDatas()

   if next(radarDatas) then
   		self:showTips(false)
   		for k,v in pairs(radarDatas) do
   			local radarData=v
   			local uuid = radarData.marchData.marchUUID
   			if uuid==nil then
   				uuid = radarData.marchData.bombId
   			end
   			local cell = CCBFileCell:create()
			local panel = RARadarWarningPageCell:new({
					marchType=radarData.marchData.marchType,
					marchrId=uuid
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RARadarWarningPageCell.ccbi")
			
			scrollview:addCellFront(cell)
		end
		scrollview:orderCCBFileCells()
 
   else
   		self:showTips(true)
   end 

end


function RARadarWarningPage:registerMessageHandler()

    MessageManager.registerMessageHandler(marchDeleteMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(marchUpdateMsg,OnReceiveMessage) 
    MessageManager.registerMessageHandler(marchAddMsg,OnReceiveMessage)  
    
end

function RARadarWarningPage:removeMessageHandler()
    MessageManager.removeMessageHandler(marchDeleteMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(marchUpdateMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(marchAddMsg,OnReceiveMessage)
    
end
function RARadarWarningPage:Exit()

	self.mWarningListSV:removeAllCell()
	self:removeMessageHandler()
	self.mExplainLabel:stopAllActions()
	self.mExplainLabel:setPosition(self.mExplainLabelStarP)
	UIExtend.unLoadCCBFile(RARadarWarningPage)
	
end

function RARadarWarningPage:onBack()
	RARootManager.CloseCurrPage()
end





--endregion
