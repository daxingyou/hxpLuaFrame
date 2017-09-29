
-- 战斗邮件：战斗成功
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAGameConfig = RARequire("RAGameConfig")

RARequire("RAMailFightCell")
local RAMailMonsterYouLiDataPage = BaseFunctionPage:new(...)

-----------------------------------------------------------

local RAMailFightPopupTitleCell = {}
function RAMailFightPopupTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupTitleCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    if self.effect then
    	UIExtend.setNodeVisible(ccbfile,"mLeftNode",false)
    	UIExtend.setNodeVisible(ccbfile,"mRightNode",false)

    	local titleStr = self.titleStr
    	UIExtend.setCCLabelString(ccbfile,"mPlayerName",titleStr)

    	return 
    end 
	local ownIcon = self.ownIcon
	local targetIcon = self.targetIcon
	local titleStr = self.titleStr

	local picNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode1,ownIcon,RAMailConfig.TAG)

    local picNode2 = UIExtend.getCCNodeFromCCB(ccbfile,"mRightCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode2,targetIcon,RAMailConfig.TAG)

    UIExtend.setCCLabelString(ccbfile,"mPlayerName",titleStr)
    
end

function RAMailFightPopupTitleCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.setNodeVisible(ccbfile,"mLeftNode",true)
    UIExtend.setNodeVisible(ccbfile,"mRightNode",true)
end

------------------------------------------------------------------------------------------
local RAMailFightPopupSolderCell = {}
function RAMailFightPopupSolderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailFightPopupSolderCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)
    print("self.id" , self.id)
    local solderConfig = RAMailUtility:getBattleSoldierDataById(self.id)
    local level = solderConfig.level
    local icon = solderConfig.icon  
    -- if self.configId==RAMailConfig.Page.FightYouLiBaseSuccess[1] or 
    -- 	self.configId==RAMailConfig.Page.FightYouLiBaseSuccess[2] then
    -- 	icon = solderConfig.yuriIcon
    -- end 

    UIExtend.setCCLabelString(ccbfile,"mLeftNum",self.data.myNum)
    UIExtend.setCCLabelString(ccbfile,"mRightNum",self.data.monstNum)

    UIExtend.setCCLabelString(ccbfile,"mLeftLevel",_RALang("@ResCollectTargetLevel",level))
    UIExtend.setCCLabelString(ccbfile,"mRightLevel",_RALang("@ResCollectTargetLevel",level))

    local picNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mLeftCellIconNode")
    local picNode2 = UIExtend.getCCNodeFromCCB(ccbfile,"mRightCellIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode1,icon,RAMailConfig.TAG)
    UIExtend.addNodeToAdaptParentNode(picNode2,icon,RAMailConfig.TAG)

end

------------------------------------------------------------------------------------------
local RAMailFightPopupEffectCell = {}
function RAMailFightPopupEffectCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAMailFightPopupEffectCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data
    -- dump(data)
	local effectId= self.data.effId
	local myValue=data.myEffVal
	local oppValue = data.monstEffVal
	local key="@EffectNum"..effectId
	local effectData=RAMailUtility:getEffectDataById(effectId)
	local effectType=effectData.type  --1是百分数 0是数值
	local name=_RALang(key)
	local value=""
	if effectType==1 then
		myValue=_RALang("@VIPAttrValueAdditionPercent",myValue/100)
		oppValue=_RALang("@VIPAttrValueAdditionPercent",oppValue/100)
	elseif effectType==0 then
		myValue=_RALang("@VIPAttrValueAdditionNoSymble",myValue)
		oppValue=_RALang("@VIPAttrValueAdditionNoSymble",oppValue)
	end 

	UIExtend.setCCLabelString(ccbfile,"mCellTitle",name)
	UIExtend.setCCLabelString(ccbfile,"mLeftNum",myValue)
	UIExtend.setCCLabelString(ccbfile,"mRightNum",oppValue)
	UIExtend.setLabelTTFColor(ccbfile,"mRightNum",RAGameConfig.COLOR.GREEN)
end



function RAMailMonsterYouLiDataPage:Enter(data)


	CCLuaLog("RAMailMonsterYouLiDataPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailDataPopUp1V6.ccbi",self)
	self.ccbfile  = ccbfile
	self.mailData = data
	local monstData = RAMailUtility:getMonsterDataById(data.monsterId)
	self.targetIcon = monstData.icon
	self.ownIcon = RAPlayerInfoManager.getHeadIcon()

    self.monstData = monstData
    


    self:init()
    
end

function RAMailMonsterYouLiDataPage:init()

	--title
	UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@BattleDataStatisticsBtn"))
	
	self.ListSV1 = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV")

	self:refreshArmyContrastData()
end



--部队对比
function RAMailMonsterYouLiDataPage:refreshArmyContrastData()
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

	local totalSolderData = {}
	local hasSame = false

	local army_conf = RARequire("battle_army_conf")
	local monstArrmy = RAStringUtil:parseWithComma(army_conf[self.monstData.armyId].soldier,{"soldierId", "num"})
	-- dump(self.mailData.soldier)
	for i,v in ipairs(self.mailData.soldier) do
		totalSolderData[i] = {soldierId = v.soldierId, myNum = v.defencedCount, monstNum = 0}
		
		for j,v1 in ipairs(monstArrmy) do
			if v.soldierId == v1.soldierId then
				totalSolderData[i].monstNum = v1.num
				table.remove(monstArrmy,j)
				break
			end
		end
	end
	for i,v in ipairs(monstArrmy) do
		table.insert(totalSolderData, {soldierId = v.soldierId, myNum = 0, monstNum = v.num})
	end	


	for i,v in ipairs(totalSolderData) do
		local SolderCell = CCBFileCell:create()
		local SolderPanel = RAMailFightPopupSolderCell:new({
				data = v,
				id = v.soldierId,
	       })
		SolderCell:registerFunctionHandler(SolderPanel)
		SolderCell:setCCBFile("RAMailDataCellV6.ccbi")
		scrollview:addCellBack(SolderCell)
	end

	local totalEff = {}
	local monstBuffs = RAStringUtil:parseWithComma(army_conf[self.monstData.armyId].buff,{"effId", "effVal"})

	for i,v in ipairs(self.mailData.effect) do
		totalEff[i] = {effId = v.effId, myEffVal = v.effVal, monstEffVal = 0}
		
		for j,v1 in ipairs(monstBuffs) do
			if v.effId == v1.effId then
				totalEff[i].monstEffVal = v1.effVal
				table.remove(monstBuffs,j)
				break
			end
		end
	end
	for i,v in ipairs(monstBuffs) do
		table.insert(totalEff, {effId = v.effId, myEffVal = 0, monstEffVal = v.effVal})

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

	for k,v in ipairs(totalEff) do
		local effectCell = CCBFileCell:create()
		local effectPanel = RAMailFightPopupEffectCell:new({
				data = v
			})
		effectCell:registerFunctionHandler(effectPanel)
		effectCell:setCCBFile("RAMailDataCellLabelV6.ccbi")
		scrollview:addCellBack(effectCell)


	end

	scrollview:orderCCBFileCells(scrollview:getContentSize().width)

end
function RAMailMonsterYouLiDataPage:genEffectDatas(myEffect,oppEffect)
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

function RAMailMonsterYouLiDataPage:getAllSolderIds(myArmys,oppArmys)
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

function RAMailMonsterYouLiDataPage:genTotalSolderData(myArmys,oppArmys)


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


function RAMailMonsterYouLiDataPage:Exit()
	self.ListSV1:removeAllCell()
	UIExtend.unLoadCCBFile(RAMailMonsterYouLiDataPage)
	
end

function RAMailMonsterYouLiDataPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailMonsterYouLiDataPage:onArmyContrastBtn()
	self:setBtnEnable(false)
	self:showArmyUI(true)
end

function RAMailMonsterYouLiDataPage:onFightDetailsBtn()
	self:setBtnEnable(true)
	self:showArmyUI(false)
end






