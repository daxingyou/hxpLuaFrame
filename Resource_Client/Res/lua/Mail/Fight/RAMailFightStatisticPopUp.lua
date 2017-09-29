
-- 战斗邮件：战斗成功
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")

RARequire("RAMailFightCell")
local RAMailFightStatisticPopUp = BaseFunctionPage:new(...)

-----------------------------------------------------------

function RAMailFightStatisticPopUp:Enter(data)


	CCLuaLog("RAMailFightStatisticPopUp:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailDataPopUp2V6.ccbi",self)
	self.ccbfile  = ccbfile

    self.data = data.info
    self.targetIcon = data.targetIcon
    self.ownIcon = data.ownIcon
    self.configId = data.configId
    self.targetName =data.targetName

    self:init()
    
end

function RAMailFightStatisticPopUp:init()

	--title
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@BattleDataStatisticsBtn"))
	
	self.ListSV1 = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV1")
	self.ListSV2 = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV2")
	
	self:setBtnEnable(false)
	self:showArmyUI(true)

	self:refreshArmyContrastData()
	self:refreshFightDetailData()
end

function RAMailFightStatisticPopUp:showArmyUI(isShow)
	self.ListSV1:setVisible(isShow)
	self.ListSV2:setVisible(not isShow)
end



--部队对比
function RAMailFightStatisticPopUp:refreshArmyContrastData()
	-- body

	self.ListSV1:removeAllCell()
	local scrollview = self.ListSV1
	--title
	local titleCell = CCBFileCell:create()
	local titlePanel = RAMailFightPopupTitleCell:new({
				ownIcon = self.ownIcon,
				targetIcon = self.targetIcon,
				titleStr = _RALang("@SoldersContrast")
	       })
	titleCell:registerFunctionHandler(titlePanel)
	titleCell:setCCBFile("RAMailDataCellTitleV6.ccbi")
	scrollview:addCellBack(titleCell)

	--solders
	local data=self.data
	local myArmy = data.myArmy
	local oppArmy = data.oppArmy


	
	--我方自己军队和对方自己军队
	local totalSolders = self:genTotalSolderData(myArmy,oppArmy)

	for i,v in pairs(totalSolders) do
		local totalSolderData = v
		local soldierId  = tonumber(i)
		local SolderCell = CCBFileCell:create()
		local SolderPanel = RAMailFightPopupSolderCell:new({
				data = totalSolderData,
				id = soldierId,
				configId = self.configId
	       })
		SolderCell:registerFunctionHandler(SolderPanel)
		SolderCell:setCCBFile("RAMailDataCellV6.ccbi")
		scrollview:addCellBack(SolderCell)
	end


	--efffect
	local effectTitleCell = CCBFileCell:create()
	local effectTitlePanel = RAMailFightPopupTitleCell:new({
				effect = true,
				titleStr = _RALang("@SoldersEffectContrast")
	       })
	effectTitleCell:registerFunctionHandler(effectTitlePanel)
	effectTitleCell:setCCBFile("RAMailDataCellTitleV6.ccbi")
	scrollview:addCellBack(effectTitleCell)

	--effect value
	local myEffect = data.myEffect
	local oppEffect = data.oppEffect

	local effectDatas = self:genEffectDatas(myEffect,oppEffect)

	for k,v in pairs(effectDatas) do
		local efffectData = v
		local effectId = k
		local effectCell = CCBFileCell:create()
		local effectPanel = RAMailFightPopupEffectCell:new({
				id = effectId,
				data =efffectData
			})
		effectCell:registerFunctionHandler(effectPanel)
		effectCell:setCCBFile("RAMailDataCellLabelV6.ccbi")
		scrollview:addCellBack(effectCell)


	end

	scrollview:orderCCBFileCells(scrollview:getContentSize().width)

end
function RAMailFightStatisticPopUp:genEffectDatas(myEffect,oppEffect)
	local tb={}
	--拿到所有的effectId
	for i=1,#myEffect do
		local effectId = myEffect[i].effId
		local t={}
		t.myValue = 0
		t.oppValue=0
		tb[tostring(effectId)]=t
	end

	for k,v in pairs(tb) do
		local effectId = tonumber(k)
		local num = RAMailUtility:getEffectValue(myEffect,effectId)
		tb[tostring(effectId)].myValue = num

		num = RAMailUtility:getEffectValue(oppEffect,effectId)
		tb[tostring(effectId)].oppValue = num
	end

	return tb

end

function RAMailFightStatisticPopUp:getAllSolderIds(myArmys,oppArmys)
	local t={}

	for i=1,#myArmys do
		local myArmy = myArmys[i]
		local soldiers= myArmy.soldier
		for j=1,#soldiers do
			local soldier = soldiers[j]
			local id =soldier.soldierId
			--把Id最为key值保存
			t[tostring(id)]=1
		end
	end

	for i=1,#oppArmys do
		local oppArmy = oppArmys[i]
		local soldiers= oppArmy.soldier
		for j=1,#soldiers do
			local soldier = soldiers[j]
			local id =soldier.soldierId
			--把Id最为key值保存
			t[tostring(id)]=1
		end
	end
	return t
end

function RAMailFightStatisticPopUp:genTotalSolderData(myArmys,oppArmys)


	--自己的部队
	-- local myOwnArmy = myArmys[1]
	-- local oppOwnArmy= oppArmys[1]
	-- local myOwnsoldiers= myOwnArmy.soldier
	-- local oppOwnsoldiers= oppOwnArmy.soldier

	--构建一种总兵力表  首先得拿到所有的兵种Id
	local solderAllIds = self:getAllSolderIds(myArmys,oppArmys)
	local totalSolder={}
	for i,v in pairs(solderAllIds) do
		local soldierId = i
		local t={} 
		t.myTotal = 0
		t.oppTotal=0
		totalSolder[soldierId]=t
	end
		
	

	--援军的部队
	for id,v in pairs(solderAllIds) do
		local targetId = id
		-- 自己部队 包含援军
		for i=1,#myArmys do
			local Army = myArmys[i]
			local Soldiers=Army.soldier
			local num=RAMailUtility:getSolderCount(Soldiers,targetId)
			--统计同种兵种的数量
			totalSolder[targetId].myTotal=totalSolder[targetId].myTotal+num
		end	
		-- 对方部队 包含援军
		for i=1,#oppArmys do
			local Army = oppArmys[i]
			local Soldiers=Army.soldier
			local num=RAMailUtility:getSolderCount(Soldiers,targetId)
			--统计同种兵种的数量
			totalSolder[targetId].oppTotal=totalSolder[targetId].oppTotal+num
		end	

	end
	return totalSolder
end

--战斗详情
--判断是否是我方
function RAMailFightStatisticPopUp:isAttackConfigId()
	local isAttack = false
	if self.configId==2012081 or self.configId==2012083 or
		self.configId==2012091 or self.configId==2012093 or
		self.configId==2012101 or self.configId==2012103 or 
		self.configId==2012111 or self.configId==2012112 or
		self.configId==2012121 or self.configId==2012124 or
		self.configId==2012131 or self.configId==2012133 or
		self.configId==2012127
	 then
	 	isAttack=true
	end 
	return isAttack
end

function RAMailFightStatisticPopUp:refreshFightDetailData()
	self.ListSV2:removeAllCell()
	local scrollview = self.ListSV2

	--先得出我方数据和对方数据
	local data = self.data
	local isAttack = self:isAttackConfigId()

	local ownDatas={}
	local oppDatas={}
	if isAttack then
		ownDatas.player = data.myPlayerInfo
		ownDatas.fight = data.myFight
		ownDatas.statu =_RALang("@AttackName")
		ownDatas.icon = self.ownIcon
		ownDatas.killSolder = data.oppFight.deadSoldier
		ownDatas.armys = data.myArmy

		oppDatas.player = data.oppPlayerInfo
		oppDatas.fight = data.oppFight
		oppDatas.statu =_RALang("@Defend")
		oppDatas.icon = self.targetIcon
		oppDatas.killSolder = data.myFight.deadSoldier
		oppDatas.armys = data.oppArmy
		if data:HasField("cannonKillCnt") then
			oppDatas.cannonKillCnt = data.cannonKillCnt
		end 
		oppDatas.defBuildEff = data.defBuildEff
		
	else
		ownDatas.player = data.oppPlayerInfo
		ownDatas.fight = data.oppFight
		ownDatas.statu =_RALang("@AttackName")
		ownDatas.icon = self.targetIcon
		ownDatas.killSolder = data.myFight.deadSoldier
		ownDatas.armys = data.oppArmy

		oppDatas.player = data.myPlayerInfo
		oppDatas.fight = data.myFight
		oppDatas.statu =_RALang("@Defend")
		oppDatas.icon = self.ownIcon
		oppDatas.killSolder = data.oppFight.deadSoldier
		oppDatas.armys = data.myArmy

		if data:HasField("cannonKillCnt") then
			oppDatas.cannonKillCnt = data.cannonKillCnt
		end 
		oppDatas.defBuildEff = data.defBuildEff
	end 


	-------------------------------------------------我方和对方数据
	self:refeshPlayerAndSolderDatas(ownDatas,true)
	self:refeshPlayerAndSolderDatas(oppDatas,false,self.targetName)

	scrollview:orderCCBFileCells(scrollview:getContentSize().width)
end


function RAMailFightStatisticPopUp:refeshPlayerAndSolderDatas(showDatas,isAttack,name)
	local scrollview = self.ListSV2
	local PlayerCell = CCBFileCell:create()
	local PlayerPanel = RAMailFightPopupPlayerCell:new({
			data = showDatas,
			attack=isAttack,
			targetName=name
    })
	PlayerCell:registerFunctionHandler(PlayerPanel)
	PlayerCell:setCCBFile("RAMailDataCell2V6.ccbi")
	scrollview:addCellBack(PlayerCell)

	--defBuildEff
	local defBuildEffs = showDatas.defBuildEff
	if defBuildEffs then
		local num=#defBuildEffs
		if num>0 then
			for i=1,num do
				local defInfo  = defBuildEffs[i]
				local cell = CCBFileCell:create()
				local panel = RAMailFightPopupDefendDetailCell:new({
						data = defInfo,
						defWeapon = true
		        })
				cell:registerFunctionHandler(panel)
				cell:setCCBFile("RAMailDataCell3V6.ccbi")
				scrollview:addCellBack(cell)
			end
		end 
	end 

	
	--defCannon
	if showDatas.cannonKillCnt then
		-- local defCannonInfo = showDatas.defCannon
		local cell = CCBFileCell:create()
		local panel = RAMailFightPopupDefendDetailCell:new({
					data = showDatas.cannonKillCnt,
					cannon = true
	        })
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAMailDataCell3V6.ccbi")
		scrollview:addCellBack(cell)
	end 
	--armys
	local Armys=showDatas.armys
	local ArmysCount=#Armys
	for i=1,ArmysCount do
		local Army=Armys[i]

		local soldiers=Army.soldier
		for j=1,#soldiers do
			local soldier=soldiers[j]
			-- 
			local cell = CCBFileCell:create()
			local panel = RAMailFightPopupSolderDetailCell:new({
					data = soldier,
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAMailDataCell3V6.ccbi")
			scrollview:addCellBack(cell)
		end
	end
end

function RAMailFightStatisticPopUp:Exit()
	self.ListSV1:removeAllCell()
	self.ListSV2:removeAllCell()
	UIExtend.unLoadCCBFile(RAMailFightStatisticPopUp)
	
end

function RAMailFightStatisticPopUp:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailFightStatisticPopUp:setBtnEnable(isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mArmyContrastBtn",isEnable)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mFightDetailsBtn",not isEnable)
end
function RAMailFightStatisticPopUp:onArmyContrastBtn()
	self:setBtnEnable(false)
	self:showArmyUI(true)
end

function RAMailFightStatisticPopUp:onFightDetailsBtn()
	self:setBtnEnable(true)
	self:showArmyUI(false)
end






