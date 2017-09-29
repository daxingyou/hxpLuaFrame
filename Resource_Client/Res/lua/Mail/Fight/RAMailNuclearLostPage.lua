
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
local RAMailNuclearLostPage = BaseFunctionPage:new(...)

local soldierIconHeight = 150

local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailDatas = message.mailDatas
      local id=mailDatas.id
      --存储一份阅读数据
      RAMailManager:addAllianceMailCheckDatas(id,mailDatas)
      RAMailNuclearLostPage:updateInfo(mailDatas)
    end
end
-----------------------------------------------------------------
local RAMailNuclearLostTitleCell={}

function RAMailNuclearLostTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailNuclearLostTitleCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    UIExtend.setCCLabelString(ccbfile, "mTitle",_RALang("@NuclearTarget"))
    -- local time =Utilitys.createTimeWithFormat(self.datas.time)
    local timeStr = RAMailUtility:formatMailTime(self.datas.time)
    UIExtend.setCCLabelString(ccbfile, "mTime",timeStr)

    UIExtend.setCCLabelHTMLString(ccbfile, "mAtkName",_RALang("@PowerLost", self.datas.disBattlePoint))

    local targetHtmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mAtkPos") 
	local RAChatManager = RARequire("RAChatManager")
	targetHtmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
	targetHtmlLabel:setString(_RAHtmlFill("@location", self.datas.x, self.datas.y))
end

local RAMailNuclearLostDescCell={}

function RAMailNuclearLostDescCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailNuclearLostDescCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.setNodeVisible(ccbfile,"mBtnNode", false)
    UIExtend.setCCLabelHTMLString(ccbfile, "mCellTitle", _RAHtmlFill("SoliderLost",self.datas.woundNum))
end


local RAMailScoutArmyCell = {}

function RAMailScoutArmyCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailScoutArmyCell:load()
	local ccbi = UIExtend.loadCCBFile("RAMailScoutMainCell5V6.ccbi", self)
    return ccbi
end

function  RAMailScoutArmyCell:getCCBFile()
	return self.ccbfile
end

function  RAMailScoutArmyCell:updateInfo()
	local ccbfile = self:getCCBFile()

	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	local iconName=self.icon
	UIExtend.addNodeToAdaptParentNode(picNode,iconName,RAMailConfig.TAG)
    local numNode = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mTroopsNum")

	if self.def then    
        numNode:getParent():setVisible(false)
	else
		 numNode:getParent():setVisible(true)
		UIExtend.setCCLabelString(ccbfile,"mTroopsNum",self.num)
	end 
end


local RAMailNuclearLostPageCell={}

function RAMailNuclearLostPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailNuclearLostPageCell:setIconPos(ccbi,i,maxCount,row)
	local cellW = ccbi:getContentSize().width
    local cellH = ccbi:getContentSize().height


    self.contanerNode:addChild(ccbi)
    
	local posX=0
   	
   	local m=math.mod(i,maxCount)

   	if m==0 then

   		posX=(maxCount-1)*cellW
   	else
   		posX=(m-1)*cellW
   	end 
    

    ccbi:setPositionX(posX)
    local offset=5
    if row>1 then
    	offset=0
    end 
    ccbi:setPositionY(-(row-1)*cellH+offset)
	
	return m 
end

function RAMailNuclearLostPageCell:refreshPlayerData(data)
	
	local playerCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mPlayerCCB")
	self.playerCCB = playerCCB

	local name, icon, level = RAMailUtility:getWorldPosNameType(data.pointType,data.pointId)
   
   	print("data.pointId = ",data.pointId)
    UIExtend.setCCLabelHTMLString(playerCCB,"mPlayerName",_RALang(name))
   
 --    local time=RAMailUtility:formatMailTime(self.time)
 	if level then
		UIExtend.setCCLabelString(playerCCB,"mLevel",_RALang("@ResourceLevel",level))
	end

	local picNode = UIExtend.getCCNodeFromCCB(playerCCB,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)


end
function RAMailNuclearLostPageCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local contanerNode=UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode2")
    local contanerNode1=UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode1")
    contanerNode1:removeAllChildren()
	contanerNode:removeAllChildren()
	self.contanerNode=contanerNode

    local tipsNode = UIExtend.getCCNodeFromCCB(ccbfile,"mTipsCCBNode")
    local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBG")
    self.mBg = mBg

	local data=self.data
	local soldierDatas=data.deadSoldier
	local soldierKinds=#soldierDatas
	local maxCount= 4
	local row=1

	self:refreshPlayerData(data)

	for i=1,soldierKinds do
		local soldierData=soldierDatas[i]
		local armyId=soldierData.armyId
		local ArmyInfo=RAMailUtility:getBattleSoldierDataById(armyId)
		local num=soldierData.count
		local numberStr=""
		if  data.isAbout then
			 numberStr=_RALang("@SoldierAboutNum",num)
		else 
			numberStr=num

		end 
		local panel = RAMailScoutArmyCell:new({
				icon=ArmyInfo.icon,
				num=numberStr
		})
	    local ccbi=panel:load()
	    panel:updateInfo()

	    local m=self:setIconPos(ccbi,i,maxCount,row)
	    if m==0 then
        	row=row+1
        end 
    end
    if self.addH > 0 then
    	self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))
		self.playerCCB:setPositionY(self.playerCCB:getPositionY()+self.addH)
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
	end
end

function RAMailNuclearLostPageCell:onResizeCell(ccbRoot)
	 if self.addH > 0 then
	 	self.cell:setContentSize(self.cell:getContentSize().width,self.cell:getContentSize().height + self.addH )
	 end
end


function RAMailNuclearLostPageCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	if self.addH and self.addH > 0 then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
		self.playerCCB:setPositionY(self.playerCCB:getPositionY()-self.addH)
    	self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
	end
end

-----------------------------------------------------------

function RAMailNuclearLostPage:Enter(data)


	CCLuaLog("RAMailNuclearLostPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailSuperWeaponsHitPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailNuclearLostPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end

function RAMailNuclearLostPage:init()

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
	self.configId = configId

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

function RAMailNuclearLostPage:genResAid( mailDatas)
	local nuClearDatas = mailDatas.beNuclearBombedMail
	local tb={}
	tb.x = nuClearDatas.x
	tb.y = nuClearDatas.y
	tb.time = math.floor(nuClearDatas.time/1000)
	tb.fromGuild = nuClearDatas.fromGuild
	tb.disBattlePoint = nuClearDatas.disBattlePoint
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
			t.pointType = detal.pointType
			t.pointId = detal.pointId
			t.disBattlePoint = detal.disBattlePoint
			t.deadSoldier = {}
			for i,v in ipairs(detal.deadSoldier) do
				t.deadSoldier[i] = {armyId = v.armyId, count = v.count}
			end

			table.insert(tb.detal,t)
		end
	end 

    return tb


end
function RAMailNuclearLostPage:genSoilderAid(mailDatas)
	--stormBombMail
	local soilderAssistanceMail  = mailDatas.SoilderAssistanceMail
	local tb={}
	tb.x = soilderAssistanceMail.x
	tb.y = soilderAssistanceMail.y
	tb.time = math.floor(soilderAssistanceMail.atime /1000)
	tb.fromName  = soilderAssistanceMail.fromName
	tb.fromId   = soilderAssistanceMail.fromId 
	tb.targetName   = soilderAssistanceMail.targetName  

	local detals = soilderAssistanceMail.deadSoldier
	local count=#detals
	if count > 0 then
		tb.detal={}
		for i=1,count do
			local t={}
			local detal = detals[i]
			t.arrmyId = detal.arrmyId
			t.count = detal.count
			table.insert(tb.detal,t)
		end
	end 

	return tb

end
function RAMailNuclearLostPage:updateInfo(mailDatas)


	local datas =self:genResAid(mailDatas)
	self.ListSV:removeAllCell()
	local scrollview = self.ListSV
	if datas.detal then
		-- title
		local cell = CCBFileCell:create()
		local panel = RAMailNuclearLostTitleCell:new({
				datas = datas
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailSuperWeaponsHitCell3V6.ccbi")
		scrollview:addCellBack(cell)

		local cell = CCBFileCell:create()
		local panel = RAMailNuclearLostDescCell:new({
				datas = datas
        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailScoutMainCellTitleV6.ccbi")
		scrollview:addCellBack(cell)
		local addH = 0
		for k,v in ipairs(datas.detal) do
			local info = v
			if #info.deadSoldier > 0 then
				addH = soldierIconHeight * (math.ceil(#info.deadSoldier/4) - 1)
			end
			local cell = CCBFileCell:create()
			local panel = RAMailNuclearLostPageCell:new({
				data = info,
				addH = addH,
				cell = cell,
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailScoutMainCell9V6.ccbi")	
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



function RAMailNuclearLostPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailNuclearLostPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailNuclearLostPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self.ListSV:removeAllCell()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailNuclearLostPage)
	
end

function RAMailNuclearLostPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailNuclearLostPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailNuclearLostPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailNuclearLostPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end