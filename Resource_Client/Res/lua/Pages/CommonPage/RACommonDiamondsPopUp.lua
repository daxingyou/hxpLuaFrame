--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil=RARequire("RAStringUtil")
local RAConfirmManager = RARequire("RAConfirmManager")

local RACommonDiamondsPopUp = BaseFunctionPage:new(...)

function RACommonDiamondsPopUp:resetData()
    self.resultFun = nil 
    self.costDiamonds = nil
    self.isSelect = false
    self.ConfirmBtn = nil
end


function RACommonDiamondsPopUp:Enter(data)
	
	local ccbfile = UIExtend.loadCCBFile("RACommonDiamondsPopUp.ccbi",self)
	self.ccbfile = ccbfile
	self.type = data.type

	self.data=data

	self.isSelect = false

	local title = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mPopUpTitle")
	UIExtend.setCCLabelString(ccbfile,"mPopUpTitle",_RALang("@attention"))
	
	self.resultFun = data.resultFun
	self.costDiamonds = data.costDiamonds

	UIExtend.setNodeVisible(ccbfile,"mGou",self.isSelect)

	self:setContent()
end


function RACommonDiamondsPopUp:getlabelKey(type)

	local key1=""
	local key2=""
	if type==RAConfirmManager.TYPE.UPGRADNOW then
		key1 = "CommonDiamondsPopup1"
		key2 = "@DontAskMe1"
	elseif type==RAConfirmManager.TYPE.CURENOW then
		key1 = "CommonDiamondsPopup2"
		key2 = "@DontAskMe2"
	elseif type==RAConfirmManager.TYPE.TRAINNOW then
		key1 = "CommonDiamondsPopup3"
		key2 = "@DontAskMe3"
	elseif type==RAConfirmManager.TYPE.RECONSTRUCTNOW then
		key1 = "CommonDiamondsPopup4"
		key2 = "@DontAskMe4"
	elseif type==RAConfirmManager.TYPE.RESEARCHNOW then
		key1 = "CommonDiamondsPopup5"
		key2 = "@DontAskMe5"
	elseif type==RAConfirmManager.TYPE.BUYNOW then
		key1 = "CommonDiamondsPopup6"
		key2 = "@DontAskMe6"
	elseif type==RAConfirmManager.TYPE.REPAIRENOW then
		key1 = "CommonDiamondsPopup7"
		key2 = "@DontAskMe7"
	end 
	return key1,key2
end
function RACommonDiamondsPopUp:setContent()
	local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
	local Const_pb = RARequire("Const_pb")
	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
	local isEnoughDiamod = playerDiamond>=self.costDiamonds and true or false

	local imgSrc = "UI/CommonUI/Common_Icon_Diamonds.png"
	local fontColor = "#ffffff"
	if not isEnoughDiamod then
		fontColor = "#ff0000"
	end 

	local Utilitys = RARequire("Utilitys")
	local costDiamonds = Utilitys.formatNumber(self.costDiamonds)
	local keyStr1,keyStr2 = self:getlabelKey(self.type)
	local str
	if self.type==RAConfirmManager.TYPE.BUYNOW then
		str=RAStringUtil:getHTMLString(keyStr1,imgSrc,fontColor,costDiamonds,self.data.final,self.data.value)
	else
		str=RAStringUtil:getHTMLString(keyStr1,imgSrc,fontColor,costDiamonds)
	end 
	
	UIExtend.setCCLabelString(self.ccbfile,"mDonotAsk",_RALang(keyStr2))
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mConfirmDiamondsLabel",str,480,"center")

end

function RACommonDiamondsPopUp:onSelectBtn()
	if self.isSelect then
		self.isSelect = false
	else
		self.isSelect = true
	end
	
	UIExtend.setNodeVisible(self.ccbfile,"mGou",self.isSelect)

end
function RACommonDiamondsPopUp:onCancelBtn()
    RARootManager.ClosePage("RACommonDiamondsPopUp")
	if self.resultFun ~= nil then 
		self.resultFun(false)
	end
end

function RACommonDiamondsPopUp:onConfirmBtn()
	self.ConfirmBtn=true

	--只有在确认的时候再去保存开关值
	RAConfirmManager:setShowConfirmDlog(not self.isSelect,self.type)

	RARootManager.ClosePage("RACommonDiamondsPopUp")
	if self.resultFun ~= nil then 
		self.resultFun(true)
	end
end


function RACommonDiamondsPopUp:onClose()
	RARootManager.ClosePage("RACommonDiamondsPopUp")
end	

function RACommonDiamondsPopUp:Exit()
	if not self.ConfirmBtn then
		RAConfirmManager:cancleConfirm(self.type)
	end
	self:resetData()
	UIExtend.unLoadCCBFile(self)
end

return RACommonDiamondsPopUp

--endregion
