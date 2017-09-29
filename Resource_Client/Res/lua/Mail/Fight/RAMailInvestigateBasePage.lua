
-- 战斗邮件：侦查基地
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire("RANetUtil")
RARequire("RAMailInvestCell")
local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail


local CELLH = 160			--单个士兵的IconCell高度	
local maxCount = 4 			--士兵摆列一行最大的数目
local extraH = 65			--敌人援军Cell上方玩家Cell的高度
local EffectCELLH = 45		--指挥官属性值Cell的高度
local DefWeaponCELLH = 50	--防御武器个数Cell的高度
local TipCELLH = 50			--提示cell的高度

local RACELLTYPE={
	res 		= 1,			--可掠夺资源
	army 		= 2,			--敌方部队
	aidArmy 	= 3,			--敌方援军
	defweapon 	= 4,			--防御武器
	effect 		= 5,			--属性加成
}

local RACELLKEY={
	res 		= 1001,
	army 		= 1002,
	aidArmy 	= 1003,
	defweapon 	= 1004,
	effect 		= 1005,
}

local RACELLTIP={
	tip1 = _RAHtmlLang("ScoutTips1"),
	tip2 = _RAHtmlLang("ScoutTips2"),
	tipVar = "ScoutTips",
} 


local RAMailInvestigateBasePage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailInfo = message.mailDatas
      local id=mailInfo.id

      --存储一份阅读数据
      RAMailManager:addPlayerBattleMailCheckDatas(id,mailInfo)
      RAMailInvestigateBasePage:updateInfo(mailInfo)
   elseif message.messageID == MessageDef_ScrollViewCell.MSG_MailScoutListCell then
   		local isAdd = message.isAdd
   		local panelCell  = message.cell
   		local cellType = panelCell.cellType

   		--refresh index
   		local cellOffsetIndex  = panelCell.cellOffest
   		local index = panelCell.cellIndex
   		RAMailInvestigateBasePage:refreshCellIndex(index,isAdd,cellOffsetIndex)
     	if isAdd then
     		-- add cell
     		local datas = panelCell.data
     		RAMailInvestigateBasePage:addSoldierCell(datas,panelCell.cellIndex,cellType)
     		
     	else
     		RAMailInvestigateBasePage:deleteSoldierCell(cellType)
     	end 
   
    end
end

function RAMailInvestigateBasePage:Enter(data)


	CCLuaLog("RAMailInvestigateBasePage:Enter")

	local ccbfile = UIExtend.loadCCBFile("RAMailScoutMainPageV6.ccbi",self)
	self.ccbfile  = ccbfile
	self.netHandlers={}
    self.isShare = data.isShare
    self.cfgId=data.cfgId
    self.mailPlayerId = data.mailPlayerId
    self.id = data.id
    self:addHandler()
	self:registerMessageHandler()
    self:init()
    
end
function RAMailInvestigateBasePage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailInvestigateBasePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.MAIL_CHECK_OTHERPLAYER_MAIL_S then  
    	local msg = Mail_pb.HPCheckMailRes()
        msg:ParseFromString(buffer)
        local mailInfo = msg
        RAMailInvestigateBasePage:updateInfo(mailInfo)
    end
end

--添加协议监听
function RAMailInvestigateBasePage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.MAIL_CHECK_OTHERPLAYER_MAIL_S, RAMailInvestigateBasePage) 	--查看其他玩家邮件返回监听
end

--移除协议监听
function RAMailInvestigateBasePage:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
    self.netHandlers = {}
end 

function RAMailInvestigateBasePage:init()

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	-- UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	UIExtend.setNodeVisible(titleCCB,"mCmnShareNode",true)
	

	self.mReportListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mReportListSV")
	

	--banner 
	if self.isShare then
		self.configId = self.cfgId
	else
		local mailInfo =RAMailManager:getMailById(self.id)
		self.mailInfo = mailInfo
		local configId = mailInfo.configId
		self.configId = configId
		 --判断是否锁定
		self.lock = mailInfo.lock
		--判断是否已读
		self.status = mailInfo.status
	end
	
 	local configData = RAMailUtility:getNewMailData(self.configId)


	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	

	--如果是超链接分享
	if self.isShare and self.mailPlayerId then
		-- UIExtend.setCCControlButtonEnable(self.ccbfile,"mShareAlliance",false)
		UIExtend.setNodeVisible(titleCCB,"mCmnShareNode",false)
		RAMailManager:sendCheckOtherMailCmd(self.mailPlayerId,self.id)
	else
		--self.isFrstRead 表示是否第一次阅读 
		self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
		if self.isFrstRead then
			RAMailManager:sendReadCmd(self.id)
		else
			local mailInfo = RAMailManager:getPlayerBattleMailCheckDatas(self.id)
			self:updateInfo(mailInfo)
		end 
	end 


	

	
end


function RAMailInvestigateBasePage:refreshState( )
    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(self.mailDatas.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(self.mailDatas.id,false)
end
function RAMailInvestigateBasePage:updateInfo(mailDatas)

	self.mailDatas=mailDatas

	-- --time
	local mailTime = RAMailManager:getMailTime(self.id)
	mailTime = math.floor(mailTime/1000)
	self.mailTime = mailTime
	self.mReportListSV:removeAllCell()
	local scrollview = self.mReportListSV
	local detectMail = mailDatas.detectMail

	self.radarLV = detectMail.level 

	local cellIndex = 1
	self:clearCellTab()

	local showTb = RAMailUtility:showDetectMailContent(self.configId,detectMail)

	--是否有归属 
	local isAttribution=false
	--是否有守军
	local isDefenceArmy=false

	if detectMail:HasField("player") then
		isAttribution=true
	end 
	if detectMail:HasField("defenceArmy") then
		isDefenceArmy=true
	end 
	-- 玩家信息
	if showTb[1]==1 then
		self.playerInfo = detectMail.player
		local playerCell = CCBFileCell:create()
		local playerPanel = RAMailPlayerInvestCell:new({
				data = self.playerInfo,
				attribution=isAttribution,
				defenceArmy=isDefenceArmy,
				configId= self.configId,
				time = mailTime,
				cellIndex = 1
	        })
		playerCell:registerFunctionHandler(playerPanel)
		playerCell:setCCBFile("RAMailScoutMainCell1V6.ccbi")
		scrollview:addCellBack(playerCell)
		table.insert(self.cellTab,playerPanel)
	else
		cellIndex = 0
	end 
	

	--可掠夺资源
	if showTb[2]==1 then
		local resDatas = detectMail.canPlunderItem
		cellIndex = cellIndex +1
		self:refreshTitleCell(scrollview,RACELLTYPE.res,cellIndex,resDatas)
	end 
	
	-- 1级是只显示资源数
	-- if self.radarLV==1 then
	-- 	scrollview:orderCCBFileCells(scrollview:getContentSize().width)
	-- 	self:refreshState()
	-- 	return 
	-- end 
	-- --敌方部队
    local defendDatas=RAMailUtility:getScoutMailShowDefenceDatas(detectMail)
	if showTb[3]==1 then
    	cellIndex = cellIndex +1
		self:refreshTitleCell(scrollview,RACELLTYPE.army,cellIndex,defendDatas)
	end 
    
	--援军部队
	if showTb[4]==1 then
		local helpArmyDatas,allSoldiers=RAMailUtility:getScoutMailShowHelpDatas(detectMail)
		cellIndex = cellIndex +1
		self:refreshTitleCell(scrollview,RACELLTYPE.aidArmy,cellIndex,helpArmyDatas,allSoldiers)
	end 


	--防御武器
	if showTb[5]==1 then 
		cellIndex = cellIndex +1
		self:refreshTitleCell(scrollview,RACELLTYPE.defweapon,cellIndex,defendDatas)
	end
	

	-- --属性加成
	-- if showTb[6]==1 then
	-- 	cellIndex = cellIndex +1
	-- 	self:refreshTitleCell(scrollview,RACELLTYPE.effect,cellIndex,defendDatas)
	-- end

	scrollview:orderCCBFileCells(scrollview:getContentSize().width)

	self:refreshState()

end

--type: 1 res 2 army 3 aidArmy 4 defweapon 5 effect
function RAMailInvestigateBasePage:refreshTitleCell(scrollview,type,index,info,allSoldiers)
	local titleCell = CCBFileCell:create()
	local titlePanel = RAMailInvestTitleCell:new({
			cellType = type,
			data = info,
			cellIndex = index,
			radarLV = self.radarLV,
			helpSoldiers=allSoldiers
        })
	titleCell:registerFunctionHandler(titlePanel)
	titleCell:setCCBFile("RAMailScoutMainCellTitleV6.ccbi")
	scrollview:addCellBack(titleCell)
	table.insert(self.cellTab,titlePanel)
end

function RAMailInvestigateBasePage:refershResCell(resDatas,index,cellKey)
	 
	local resCell = CCBFileCell:create()
	local resPanel = RAMailInvestResCell:new({
			data= resDatas
        })
	resPanel.selfCell=resCell
	resCell:registerFunctionHandler(resPanel)
	resCell:setCCBFile("RAMailScoutMainCellResV6.ccbi")
	self.mReportListSV:addCell(resCell,index)
	
	self.soldierCellTab[cellKey]=resPanel
    self.mReportListSV:orderCCBFileCells()
end

function RAMailInvestigateBasePage:refreshArmyCell(defendDatas,index,cellKey)
	if self.radarLV<5 then

		local tipsCell = CCBFileCell:create()
		local tipsPanel = RAMailInvestTipsNodeCell:new({
				htmlStr= _RAHtmlLang(RACELLTIP.tipVar,5)
	        })
		tipsPanel.selfCell=tipsCell
		tipsCell:registerFunctionHandler(tipsPanel)
		tipsCell:setCCBFile("RAMailScoutMainCell7V6.ccbi")
		self.mReportListSV:addCell(tipsCell,index)
		self.mReportListSV:orderCCBFileCells()

		self.soldierCellTab[cellKey]=tipsPanel

	else

		local tmptotalH=0
		if defendDatas.defenceSoldierMem then
			local soldier=defendDatas.defenceSoldierMem
			local soldierKinds=#soldier
			local row=math.ceil(soldierKinds/maxCount)

			--CELLH为每个iconCell的高度
			tmptotalH=row*CELLH

			--加上提示Cell的高度
			if self.radarLV<9 then
				tmptotalH =  tmptotalH + TipCELLH
			end 
		end


		local armySolderCell = CCBFileCell:create()
		local armySolderPanel = RAMailInvestSolder1Cell:new({
				data = defendDatas,
				totalH=tmptotalH,
				radarLV = self.radarLV,
				htmlStr= _RAHtmlLang(RACELLTIP.tipVar,9)
	        })
		armySolderPanel.selfCell=armySolderCell
		armySolderCell:registerFunctionHandler(armySolderPanel)
		armySolderCell:setCCBFile("RAMailScoutMainCell3V6.ccbi")
		self.mReportListSV:addCell(armySolderCell,index)
		self.soldierCellTab[cellKey] = armySolderPanel

		self.mReportListSV:orderCCBFileCells()

	end 
end

function RAMailInvestigateBasePage:refreshAidArmyCell(helpArmyDatas,index,cellKey)
	if self.radarLV<=6 then

		local tipsCell = CCBFileCell:create()
		local tipsPanel = RAMailInvestTipsNodeCell:new({
				htmlStr= _RAHtmlLang(RACELLTIP.tipVar,7)
	        })
		tipsPanel.selfCell=tipsCell
		tipsCell:registerFunctionHandler(tipsPanel)
		tipsCell:setCCBFile("RAMailScoutMainCell7V6.ccbi")
		self.mReportListSV:addCell(tipsCell,index)
		self.mReportListSV:orderCCBFileCells()
		self.tipsCellTab[cellKey]=tipsPanel
	elseif self.radarLV==7 then

		local t={}
		local datas=helpArmyDatas.armyDatas
		local count=#datas
		if count>0 then
			-- local tmptotalH=count*105+TipCELLH
			for i=1,count do
				local helpArmyData = datas[i]

				local armyPlayerCell = CCBFileCell:create()
				local armyPlayerPanel = RAMailInvestHelpArmyPlayerCell:new({
						time = self.mailTime,
						configId = self.configId,
						data = helpArmyData
			        })
				armyPlayerPanel.selfCell=armyPlayerCell
				armyPlayerCell:registerFunctionHandler(armyPlayerPanel)
				armyPlayerCell:setCCBFile("RAMailScoutMainCell2V6.ccbi")

				self.mReportListSV:addCell(armyPlayerCell,index)
                index = index +1
				table.insert(t,armyPlayerPanel)
			end
			self.soldierCellTab[cellKey] = t		

		end 

		local tipsCell = CCBFileCell:create()
		local tipsPanel = RAMailInvestTipsNodeCell:new({
				htmlStr= _RAHtmlLang(RACELLTIP.tipVar,8)
	        })
		tipsPanel.selfCell=tipsCell
		tipsCell:registerFunctionHandler(tipsPanel)
		tipsCell:setCCBFile("RAMailScoutMainCell7V6.ccbi")
		self.mReportListSV:addCell(tipsCell,index)
		self.tipsCellTab[cellKey]=tipsPanel

		self.mReportListSV:orderCCBFileCells()

	else

		--多个援军用过一个二维表存储
		local t={}
		local datas=helpArmyDatas.armyDatas
		local count=#datas
		if count>0 then
			for i=1,count do
				local helpArmyData = datas[i]
				local tmptotalH=0
				if helpArmyData.helpSoldierMem then
					local soldier=helpArmyData.helpSoldierMem
					local soldierKinds=#soldier
					local row=math.ceil(soldierKinds/maxCount)

					--CELLH为每个iconCell的高度，extraH为上方cell的高度
					tmptotalH=row*CELLH+extraH+40

					-- --加上提示Cell的高度
					if self.radarLV<10 then
						tmptotalH =  tmptotalH + TipCELLH
					end 
				end

				local armySolderCell = CCBFileCell:create()
				local armySolderPanel = RAMailInvestSolder2Cell:new({
						data = helpArmyData,
						totalH=tmptotalH,
						radarLV=self.radarLV,
						htmlStr= _RAHtmlLang(RACELLTIP.tipVar,10)
			        })
				armySolderPanel.selfCell=armySolderCell
				armySolderCell:registerFunctionHandler(armySolderPanel)
				armySolderCell:setCCBFile("RAMailScoutMainCell9V6.ccbi")
				self.mReportListSV:addCell(armySolderCell,index)
                index = index +1
				table.insert(t,armySolderPanel)
			end
			self.soldierCellTab[cellKey] = t


			self.mReportListSV:orderCCBFileCells()

		end 
		
	end 
end

function RAMailInvestigateBasePage:refreshDefWeaponCell(defweaponDatas,index,cellKey)
	
	if self.radarLV<=5 then

		local tipsCell = CCBFileCell:create()
		local tipsPanel = RAMailInvestTipsNodeCell:new({
				htmlStr= _RAHtmlLang(RACELLTIP.tipVar,6)
	        })
		tipsPanel.selfCell=tipsCell
		tipsCell:registerFunctionHandler(tipsPanel)
		tipsCell:setCCBFile("RAMailScoutMainCell7V6.ccbi")
		self.mReportListSV:addCell(tipsCell,index)
		self.mReportListSV:orderCCBFileCells()
		self.soldierCellTab[cellKey]=tipsPanel
	else

		--直接拿三个buildInfo
		local defBuildType = {Const_pb.PRISM_TOWER,Const_pb.PATRIOT_MISSILE,Const_pb.PILLBOX}
		local Const_pb =RARequire("Const_pb")


		local tb={}
		RARequire("RABuildingUtility")

		for i=1,#defBuildType do
			local t=RABuildingUtility.getBuildInfoByType(defBuildType[i],true)
			local tp={}
			tp.buildType = v
			tp.buildArtImg = t[1].buildArtImg
			table.insert(tb,tp)
		end

		local tmptotalH=0
		local iconNum = #tb
		local row=math.ceil(iconNum/3)
		tmptotalH=row*CELLH

		local _,maxNum = RABuildingUtility.getBuildInfoByType(Const_pb.PRISM_TOWER,true)
		tmptotalH = tmptotalH +maxNum*DefWeaponCELLH 


		local defenceBuildCell = CCBFileCell:create()
		local defendBuildPanel =RAMailInvestDefWeaponCell:new({
				data=tb,
				totalH=tmptotalH,
				defenceMem=defweaponDatas.defenceMem,
				maxCount = maxNum		
	    })
	    defendBuildPanel.selfCell=defenceBuildCell
		defenceBuildCell:registerFunctionHandler(defendBuildPanel)
		defenceBuildCell:setCCBFile("RAMailScoutMainCell3V6.ccbi")
		self.mReportListSV:addCell(defenceBuildCell,index)

		self.soldierCellTab[cellKey]=defendBuildPanel

		self.mReportListSV:orderCCBFileCells()
	end 
end
function RAMailInvestigateBasePage:refreshEffectCell(effectDatas,index,cellKey)
	local buffTab=effectDatas.buff
	local count=#buffTab
	local num1,num2 = math.modf(count/2)
	if num2>0 then
		num1 = num1 +1
	end 
	local tmptotalH = num1*EffectCELLH

	--自己构建一张表
	local tb={}
	local tmpIndex =1
	for i=1,count,2 do
		local t={}
		local buff1=buffTab[i]
		local buff2=buffTab[i+1]
		if buff1 then
			t[1]=buff1
		end 
		if buff2 then
			t[2]=buff2
		end 

		tb[tmpIndex] = t
		tmpIndex = tmpIndex +1
	end


	local effectCell = CCBFileCell:create()
	local effectPanel =RAMailInvestEffectCell:new({
				data=tb,
				totalH=tmptotalH,		
	})
    effectPanel.selfCell=effectCell
	effectCell:registerFunctionHandler(effectPanel)
	effectCell:setCCBFile("RAMailScoutMainCell7V6.ccbi")
	self.mReportListSV:addCell(effectCell,index)

	self.soldierCellTab[cellKey]=effectPanel
	self.mReportListSV:orderCCBFileCells()

end

function RAMailInvestigateBasePage:clearCellTab()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			v=nil
		end
	end 
	self.cellTab={}

	--添加的cell 临时存放表
	if self.soldierCellTab then
		for i,v in pairs(self.soldierCellTab) do
				
			v=nil
		end
	end
	self.soldierCellTab={}

	if self.defWeaponCellTab then
		for i,v in pairs(self.defWeaponCellTab) do
				
			v=nil
		end
	end
	self.defWeaponCellTab={}

	if self.tipsCellTab then
		for i,v in pairs(self.tipsCellTab) do	
			v=nil
		end
	end
	self.tipsCellTab={}
end
function RAMailInvestigateBasePage:refreshCellIndex(clickIndex,isOpen,offset)
	offset = offset or 1
	for i,v in ipairs(self.cellTab) do
		local cell=v
		local tmpIndex=cell.cellIndex
		if isOpen then
			if tmpIndex>clickIndex then 
				cell:refreshIndex(tmpIndex+offset)
			end 
		else

			if tmpIndex>clickIndex then
				cell:refreshIndex(tmpIndex-offset) 
			end 
		end

	end
end
function RAMailInvestigateBasePage:addSoldierCell(datas,index,cellType)
 	if cellType==RACELLTYPE.res then
 		self:refershResCell(datas,index,RACELLKEY.res)
	elseif cellType==RACELLTYPE.army then
		self:refreshArmyCell(datas,index,RACELLKEY.army)
	elseif cellType==RACELLTYPE.aidArmy then
		self:refreshAidArmyCell(datas,index,RACELLKEY.aidArmy)
	elseif cellType==RACELLTYPE.defweapon then
		self:refreshDefWeaponCell(datas,index,RACELLKEY.defweapon)
	elseif cellType==RACELLTYPE.effect then
		self:refreshEffectCell(datas,index,RACELLKEY.effect)
	end 
end

function RAMailInvestigateBasePage:getCellKeyByType(cellType)
	local cellKey =""
	if cellType==RACELLTYPE.res then
 		cellKey=RACELLKEY.res
	elseif cellType==RACELLTYPE.army then
		cellKey=RACELLKEY.army
	elseif cellType==RACELLTYPE.aidArmy then
		cellKey=RACELLKEY.aidArmy
	elseif cellType==RACELLTYPE.defweapon then
		cellKey=RACELLKEY.defweapon
	elseif cellType==RACELLTYPE.effect then
		cellKey=RACELLKEY.effect
	end 
	return cellKey
end

function RAMailInvestigateBasePage:deleteSoldierCell(cellType)
	
	local cellKey = self:getCellKeyByType(cellType)
	local soldierCell=self.soldierCellTab[cellKey]

	if cellType==RACELLTYPE.aidArmy then
		if type(soldierCell)=="table" then
			for i,v in ipairs(soldierCell) do
                self.mReportListSV:removeCell(v.selfCell)
				v=nil
			end

			soldierCell = nil
		end 

		local tipsCell=self.tipsCellTab[cellKey]
		if tipsCell then
			self.mReportListSV:removeCell(tipsCell.selfCell)
			self.tipsCellTab[cellType]=nil
		end 
	end 

	if soldierCell then
        self.mReportListSV:removeCell(soldierCell.selfCell)
		self.soldierCellTab[cellType]=nil
	end 

	--防御武器有两个cell
	if cellType == RACELLTYPE.defweapon then
		local defweaponCell=self.defWeaponCellTab[cellKey]
		if defweaponCell then
			self.mReportListSV:removeCell(defweaponCell.selfCell)
			self.defWeaponCellTab[cellType]=nil
		end
	end 
	
end

function RAMailInvestigateBasePage:registerMessageHandler()
	MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
    -- MessageManager.registerMessageHandler(OperationOkMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end

function RAMailInvestigateBasePage:removeMessageHandler()
	MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
    -- MessageManager.removeMessageHandler(OperationOkMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end


function RAMailInvestigateBasePage:Exit()
	self:clearCellTab()
	self.mReportListSV:removeAllCell()
	self:removeHandler()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailInvestigateBasePage)
	
end

function RAMailInvestigateBasePage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailInvestigateBasePage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailInvestigateBasePage:mCommonTitleCCB_onCmnShareBtn()
	 local RAAllianceManager = RARequire("RAAllianceManager")
	 if RAAllianceManager.selfAlliance == nil then
	 	RARootManager.ShowMsgBox('@NoAllianceLabel')
	 	return 
	 end 
	 RAMailManager:sendShareMailCmd(self.id)
	 local str = _RALang("@ShareMailSuccess")
	 RARootManager.ShowMsgBox(str)

	 self:onClose()
end

