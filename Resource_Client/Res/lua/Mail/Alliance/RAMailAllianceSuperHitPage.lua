
--联盟：核弹/闪电风暴命中
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")

local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local RAMailAllianceSuperHitPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailDatas = message.mailDatas
      local id=mailDatas.id
      --存储一份阅读数据
      RAMailManager:addAllianceMailCheckDatas(id,mailDatas)
      RAMailAllianceSuperHitPage:updateInfo(mailDatas)
    end
end
-----------------------------------------------------------------
local RAMailAllianceSuperHitPageCell={}

function RAMailAllianceSuperHitPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

-- enum WorldPointType
-- {
-- 	EMPTY 			= 0;	// 空白点
-- 	RESOURCE 		= 1;	// 资源点
-- 	MONSTER 		= 2;	// 怪物点
-- 	PLAYER 			= 3;	// 玩家城堡
-- 	OCCUPIED		= 4;	// 被玩家城堡或者其他大建筑占用的四周点
-- 	QUARTERED		= 5;	// 驻扎的部队的点
-- 	GUILD_GUARD		= 6;	// 据点类型
-- 	GUILD_TERRITORY = 7;	// 联盟建筑
-- 	KING_PALACE		= 8;	// 国王宫殿
-- }
function RAMailAllianceSuperHitPageCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    local data= self.data

    local playerName = data.playerName
    UIExtend.setCCLabelString(ccbfile,"mListTitle1",playerName)

    if self.isNuClear then
    	local pointType = data.pointType
    	local subType  =data.subType
    	local name = RAMailUtility:getWorldPosNameType(pointType,subType)
    	UIExtend.setCCLabelString(ccbfile,"mListTitle2",name)
    	local woundNum =Utilitys.formatNumber(data.woundNum)
    	UIExtend.setCCLabelString(ccbfile,"mListTitle3",woundNum)
    else

    	local baseStr = _RALang("@Upgrade")
    	local buildType = data.buildType
    	RARequire("RABuildingUtility")
    	local tb=RABuildingUtility.getBuildInfoByType(buildType,true)
    	local buildName = _RALang(tb[1].buildName)
    	UIExtend.setCCLabelString(ccbfile,"mListTitle2",buildName)
    	local breakTime =Utilitys.createTimeWithFormat(data.breakTime)
    	UIExtend.setCCLabelString(ccbfile,"mListTitle3",breakTime)
    end 
    
 	
end
-----------------------------------------------------------

function RAMailAllianceSuperHitPage:Enter(data)


	CCLuaLog("RAMailAllianceSuperHitPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailSuperWeaponsPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
    self.isNuClearBom = data.isNuClearBom
	self:registerMessageHandler()
    self:init()
    
end
function RAMailAllianceSuperHitPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

function RAMailAllianceSuperHitPage:resetLabel()
	local tb={}
	tb["mSysTimeLabel"]=""
	tb["mListTitle1"]=""
	tb["mListTitle2"]=""
	tb["mListTitle3"]=""
	UIExtend.setStringForLabel(self.ccbfile, tb)
	
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mConsequentLabel","")
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mTitle1","")
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mTitle2","")
	
end
function RAMailAllianceSuperHitPage:init()

	self:resetLabel()
	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId


	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	

	local configData = RAMailUtility:getNewMailData(configId)
	--title
	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	--banner 
	
	-- local mailBanner = configData.mailBanner
	-- local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	-- render:setTexture(mailBanner)

	self.ListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV")

	

	 --判断是否锁定
	self.lock = mailInfo.lock
	 
	
	--判断是否已读
	self.status = mailInfo.status

	--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailDatas = RAMailManager:getAllianceMailCheckDatas(self.id)
		self:updateInfo(mailDatas)
	end 

	
end

function RAMailAllianceSuperHitPage:genNuClearDatas( mailDatas)
	local nuClearDatas = mailDatas.nuclearBombMail
	local tb={}
	tb.x = nuClearDatas.x
	tb.y = nuClearDatas.y
	tb.time = math.floor(nuClearDatas.time/1000)
	tb.targetNum = nuClearDatas.targetNum
	if nuClearDatas:HasField('woundNum') then
		tb.woundNum = nuClearDatas.woundNum
	end

	local detals = nuClearDatas.detail
	local count=#detals
	if count > 0 then
		tb.detal={}
		for i=1,count do
			local t={}
			local detal = detals[i]
			t.playerName = detal.playerName
			if detal:HasField("guildTag") then
				local guildTag = detal.guildTag
				t.playerName = "("..guildTag..")"..t.playerName
			end 
			if detal:HasField("woundNum") then
				t.woundNum = detal.woundNum
			end
			
			if detal:HasField("pointType") then
				t.pointType = detal.pointType
			end
			if detal:HasField("subType") then
				t.subType = detal.subType
			end
			table.insert(tb.detal,t)
		end
	end 

    return tb


end
function RAMailAllianceSuperHitPage:genStormDatas(mailDatas)
	--stormBombMail
	local stormBombDatas = mailDatas.stormBombMail
	local tb={}
	tb.x = stormBombDatas.x
	tb.y = stormBombDatas.y
	tb.time = math.floor(stormBombDatas.time/1000)
	tb.targetNum = stormBombDatas.targetNum
	tb.breakTime = math.floor(stormBombDatas.breakTime/1000)

	local detals = stormBombDatas.detail
	local count=#detals
	if count > 0 then
		tb.detal={}
		for i=1,count do
			local t={}
			local detal = detals[i]
			t.playerName = detal.playerName
			if detal:HasField("guildTag") then
				local guildTag = detal.guildTag
				t.playerName = "("..guildTag..")"..t.playerName
			end 
			t.buildType = detal.buildType
			t.breakTime = math.floor(detal.breakTime/1000)
			table.insert(tb.detal,t)
		end
	end 

	return tb

end
function RAMailAllianceSuperHitPage:updateInfo(mailDatas)


	local datas = nil
	if self.isNuClearBom then
		datas =self:genNuClearDatas(mailDatas)
	else
		datas =self:genStormDatas(mailDatas)
	end 

	--target
	local x = datas.x
	local y = datas.y
	local targetHtmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mTitle1") 
	local RAChatManager = RARequire("RAChatManager")
	targetHtmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
	local htmlStr = ""
	if self.isNuClearBom then
		htmlStr = _RAHtmlLang("NuclearTarget",x,y)
	else
		htmlStr = _RAHtmlLang("StormTarget",x,y)
	end 
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mTitle1",htmlStr)


	--time
	local time = datas.time
	local timeStr = RAMailUtility:formatMailTime(time)
	UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel",timeStr)

	--middle
	if self.isNuClearBom then
		local woundNum =Utilitys.formatNumber(datas.woundNum)
		htmlStr = _RAHtmlLang("NuclearHurt",woundNum)
	else
		local breakTime =Utilitys.createTimeWithFormat(datas.breakTime)
		htmlStr = _RAHtmlLang("StormHurt",breakTime)
	end 

	UIExtend.setCCLabelHTMLString(self.ccbfile,"mConsequentLabel",htmlStr)

	--kill num
	htmlStr= _RAHtmlLang("HitTarget",datas.targetNum)
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mTitle2",htmlStr)

	--cell
	local tb={}
	tb["mListTitle1"]=_RALang("@PlayerAndAlliance")
	if self.isNuClearBom then
		tb["mListTitle2"]=_RALang("@Position")
		tb["mListTitle3"]=_RALang("@Kill")
	else
		tb["mListTitle2"]=_RALang("@BreakQueue")
		tb["mListTitle3"]=_RALang("@BreakTime")
	end 

	UIExtend.setStringForLabel(self.ccbfile,tb)

	self.ListSV:removeAllCell()
	local scrollview = self.ListSV
	if datas.detal then
		for k,v in ipairs(datas.detal) do
			local info = v
			local cell = CCBFileCell:create()
			local panel = RAMailAllianceSuperHitPageCell:new({
					data = info,
					isNuClear = self.isNuClearBom
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailSuperWeaponsCellV6.ccbi")
			scrollview:addCellBack(cell)

		end
		scrollview:orderCCBFileCells(scrollview:getContentSize().width)

	    if scrollview:getContentSize().height < scrollview:getViewSize().height then
			scrollview:setTouchEnabled(false)
		else
			scrollview:setTouchEnabled(true)
	    end 
	end 

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailDatas.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailDatas.id,false)
end



function RAMailAllianceSuperHitPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailAllianceSuperHitPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailAllianceSuperHitPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self.ListSV:removeAllCell()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailAllianceSuperHitPage)
	
end

function RAMailAllianceSuperHitPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailAllianceSuperHitPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailAllianceSuperHitPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailAllianceSuperHitPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end