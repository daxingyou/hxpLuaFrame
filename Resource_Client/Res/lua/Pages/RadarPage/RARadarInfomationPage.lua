--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


--雷达讯息界面


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb =RARequire('Const_pb')
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAGameConfig=RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local RARadarManage=RARequire("RARadarManage")
local RARadarUtils=RARequire("RARadarUtils")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local Utilitys=RARequire("Utilitys")
local RA_Common = RARequire("common")


local marchDeleteMsg = MessageDef_Radar.MSG_DELETE
local marchUpdateMsg = MessageDef_Radar.MSG_UPDATE

local RARadarInfomationPage = BaseFunctionPage:new(...)

local TAG=1000

--RARadarInfomationPageLeaderCell
-----------------------------------------------------------------------
local RARadarInfomationPageLeaderCell = {

}
function RARadarInfomationPageLeaderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RARadarInfomationPageLeaderCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbRoot=ccbRoot
	ccbRoot:setIsScheduleUpdate(true)
	self.ccbfile=ccbfile
	local data=self.data
	local isSuperWeapon = data.isSuperWeapon

	--玩家icon
	local iconName=""
	if  data.playerIcon then
		if not isSuperWeapon then
			iconName=RARadarUtils:getPlayerIcon(data.playerIcon)
		else
			iconName=RAAllianceUtility:getAllianceFlagIdByIcon(data.playerIcon)
		end 
		
	else
		iconName="Common_u_DefaultHead.png"
	end
	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,iconName,TAG)

	--玩家ID
	local keyStr = "@RadarPlayerID"
	if isSuperWeapon then
		keyStr = "@AllianceOwnName"
	end 
	UIExtend.setCCLabelString(ccbfile,"mPlayerIdTitle",_RALang(keyStr))
	local name=data.playerName or RAGameConfig.RadarDefaultStr.STR
	UIExtend.setCCLabelString(ccbfile,"mPlayerId",name)

	--出兵位置
	local playerPos=data.playerPos or RAGameConfig.RadarDefaultStr.STR
	local posKeyStr = "@RadarPlayerPos"
	if isSuperWeapon then
		posKeyStr = "@RadarSuperWeaponPos"
	end 
	UIExtend.setCCLabelString(ccbfile,"mPlayerPosTitle",_RALang(posKeyStr))
	UIExtend.setCCLabelString(ccbfile,"mPlayerPos",playerPos)



	--预计到达时间
	local curTime = RA_Common:getCurTime()
	local cutDownTime = data.playerArriveTime
	if data.massMarchStartTime then
		cutDownTime = data.massMarchStartTime
	end 
	if cutDownTime then
		self.playerArriveTime=cutDownTime 
		local remainTime =os.difftime(self.playerArriveTime,curTime)
		local tmpStr = Utilitys.createTimeWithFormat(remainTime)
		UIExtend.setCCLabelString(self.ccbfile,"mPlayerArriveTime",tmpStr)
	else
		
		UIExtend.setCCLabelString(self.ccbfile,"mPlayerArriveTime",RAGameConfig.RadarDefaultStr.STR)
	end 
	
	self.mFrameTime=0

	local timekeyStr = "@RadarPlayerArriveTime"
	if isSuperWeapon then
		timekeyStr = "@RadarSuperWeaponArriveTime"
	elseif data.massMarchStartTime then
		timekeyStr = "@RadarPlayerWillStartMarchTime"
	end 
	UIExtend.setCCLabelString(ccbfile,"mPlayerArriveTimeTitle",_RALang(timekeyStr))
	
end

function RARadarInfomationPageLeaderCell:onExecute()
	if self.playerArriveTime then
		self.mFrameTime = self.mFrameTime + RA_Common:getFrameTime()
		if self.mFrameTime>1 then
			local curTime = RA_Common:getCurTime()
			if curTime then
				local remainTime =os.difftime(self.playerArriveTime,curTime)
				if remainTime>0 then
					local tmpStr = Utilitys.createTimeWithFormat(remainTime)
					UIExtend.setCCLabelString(self.ccbfile,"mPlayerArriveTime",tmpStr)
				else
					self.ccbRoot:setIsScheduleUpdate(false)
					RARootManager.CloseCurrPage()
				end
			end
			self.mFrameTime = 0 
		end 
		
	end 
end


------------------------------------------------------------------------------------------------
local RARadarInfomationPageIconCell = {

}
function RARadarInfomationPageIconCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RARadarInfomationPageIconCell:load()
	local ccbi = UIExtend.loadCCBFile("RARadarPageIconCell.ccbi", self)
    return ccbi
end

function  RARadarInfomationPageIconCell:getCCBFile()
	return self.ccbfile
end

function  RARadarInfomationPageIconCell:updateInfo()
	local ccbfile = self:getCCBFile()

	--将领
	if self.isGeneral then
		local iconId =self.data.playerIcon
		local level = self.data.playerLevel
		local icon=RARadarUtils:getPlayerIcon(iconId)
		local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mAdditionalResPicNode")
		UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)
		UIExtend.setCCLabelString(ccbfile,"mCellNodeNum",_RALang("@LevelNum",level))
		return
	end

	-- --资源
	if self.isResouce then

		local iconId =self.data.itemId
		local count=self.data.itemCount
		local icon=RALogicUtil:getResourceIconById(iconId)
		local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mAdditionalResPicNode")
		UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)
		UIExtend.setCCLabelString(ccbfile,"mCellNodeNum",count)
		return 
	end 

	
	local data=self.data
	local armyId
	if type(data)=="number" then
		armyId=data	
	else
		armyId=data.armyId
	end 
	

	local icon=RARadarUtils:getBattleSoldierIconById(armyId)
	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mAdditionalResPicNode")
	UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)
	local isCount=self.isCount
	local isAbout=self.isAbout
	if not isCount then
		--显示？？？？
		UIExtend.setCCLabelString(ccbfile,"mCellNodeNum",RAGameConfig.RadarDefaultStr.STR)
	elseif isAbout then --显示大约数
		local armyCount=data.count
		armyCount=Utilitys.formatNumber(armyCount)
		UIExtend.setCCLabelString(ccbfile,"mCellNodeNum",_RALang("@SoldierAboutNum",armyCount))
	else  				--显示准确数
		local armyCount=data.count
		armyCount=Utilitys.formatNumber(armyCount)
		UIExtend.setCCLabelString(ccbfile,"mCellNodeNum",armyCount)
	end 


end

-----------------------------------------------------------------------------------------------
local RARadarInfomationPageGeneralCell={}

function RARadarInfomationPageGeneralCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RARadarInfomationPageGeneralCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbRoot=ccbRoot
	self.ccbfile=ccbfile

	UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@CommanderLevelConditions"))
	UIExtend.setNodeVisible(ccbfile,"mBg",true)
	local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
	contanerNode:removeAllChildren()

	local mBg=UIExtend.getCCNodeFromCCB(ccbfile,"mBg")
	self.mBg=mBg
	UIExtend.setNodeVisible(ccbfile,"mBg",true)
	local topNode=UIExtend.getCCNodeFromCCB(ccbfile,"mTopNode")
	self.topNode=topNode

	local generalData=self.data
	local unionData=self.unionData 

	local maxCount=4
	local row=1
	local count=#unionData+1
	for i=1,count do
		local playerData={}
		if i==1 then
			playerData=generalData
		else
			playerData=unionData[i-1]
		end 

		local panel = RARadarInfomationPageIconCell:new({
		 data=playerData,
		 isGeneral=true,
		})
	    local ccbi=panel:load()
	    panel:updateInfo()
	    contanerNode:addChild(ccbi)


        local cellW = ccbi:getContentSize().width
        local cellH = ccbi:getContentSize().height

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
        if m==0 then
        	row=row+1
        end 	
	end
	
	if self.addH and self.addH > 0  then
		topNode:setPositionY(topNode:getPositionY()+self.addH)
		mBg:setContentSize(CCSize(mBg:getContentSize().width,mBg:getContentSize().height+self.addH))
	end
	
end

function RARadarInfomationPageGeneralCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
		self.topNode:setPositionY(self.topNode:getPositionY() -self.addH)
		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
	end
end

function RARadarInfomationPageGeneralCell:onResizeCell(ccbRoot)

	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

----------------------------------------------------------------------------------------------
local RARadarInfomationPageEffectCell = {

}
function RARadarInfomationPageEffectCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RARadarInfomationPageEffectCell:load()
	local ccbi = UIExtend.loadCCBFile("RARadarPageCell4.ccbi", self)
    return ccbi
end

function  RARadarInfomationPageEffectCell:getCCBFile()
	return self.ccbfile
end

function  RARadarInfomationPageEffectCell:updateInfo()
	local ccbfile = self:getCCBFile()

	local data=self.data
	local effectId=data.effId
	local effectValue=data.effVal
	local key="@EffectNum"..effectId
	local effectData=RARadarUtils:getEffectDataById(effectId)
	local effectType=effectData.type  --1是百分数 0是数值
	local name=_RALang(key)
	UIExtend.setCCLabelString(ccbfile,"mName",name)
	if effectType==1 then
		UIExtend.setCCLabelString(ccbfile,"mNum",_RALang("@ScienceLevelEffectPercent",effectValue/100))
	elseif effectType==0 then
		UIExtend.setCCLabelString(ccbfile,"mNum",_RALang("@ScienceLevelEffectPoint",effectValue))	
	end 
	

end


------------------------------------------------------------------------------------------------
local RARadarInfomationPageCommanderLeaderCell = {

}
function RARadarInfomationPageCommanderLeaderCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

local effectCellAddH=0
function RARadarInfomationPageCommanderLeaderCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	local data=self.data
	local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
	contanerNode:removeAllChildren()
	local titleNode=UIExtend.getCCNodeFromCCB(ccbfile,"mTitleNode")
	local totalContainerH=contanerNode:getContentSize().height
	local mBg=UIExtend.getCCNodeFromCCB(ccbfile,"mBg")
	UIExtend.setNodeVisible(ccbfile,"mBg",true)
	UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@CommanderLeader"))

	local topNode=UIExtend.getCCNodeFromCCB(ccbfile,"mTopNode")
	self.topNode=topNode
	local isVisbleBg=nil
	if self.addH>0 then
		UIExtend.setNodeVisible(ccbfile,"mBg",false)
	
	end 
	--考虑做自适应
	local buffTab=self.data.buff
	local buffCount=#buffTab
	for i=1,buffCount do
		local effectData=buffTab[i]
		local isVisbleBg=self.addH>0 and true or false
		local panel = RARadarInfomationPageEffectCell:new({
			 data=effectData,
			 visbleBg=isVisbleBg
		})
        local ccbi=panel:load()
        panel:updateInfo()
        cellH= ccbi:getContentSize().height
        contanerNode:addChild(ccbi)
        local posY=totalContainerH-i*cellH
        ccbi:setPositionY(posY)
 		
	end
	
	if self.addH > 0  then
		topNode:setPositionY(topNode:getPositionY()+self.addH)
	end
	
		
end

function RARadarInfomationPageCommanderLeaderCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH > 0 then
		self.topNode:setPositionY(self.topNode:getPositionY() -self.addH)
	end
end

function RARadarInfomationPageCommanderLeaderCell:onResizeCell(ccbRoot)

	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end
------------------------------------------------------------------------------------------------
local RARadarInfomationPageSoldierCell = {

}
function RARadarInfomationPageSoldierCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RARadarInfomationPageSoldierCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	local data=self.data
	local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
	contanerNode:removeAllChildren()
	local titleNode=UIExtend.getCCNodeFromCCB(ccbfile,"mTitleNode")
	local totalContainerH=contanerNode:getContentSize().height
	local mBg=UIExtend.getCCNodeFromCCB(ccbfile,"mBg")
	self.mBg=mBg
	UIExtend.setNodeVisible(ccbfile,"mBg",true)
	local topNode=UIExtend.getCCNodeFromCCB(ccbfile,"mTopNode")
	self.topNode=topNode

	--超级武器
	if self.isSuper then
		local keyStr="@RadarSuperWeaponNuclearTips"
		if self.nuclearFlag==0 then
			keyStr="@RadarSuperWeaponLightingTips"
		end 
		UIExtend.setNodeVisible(ccbfile,"mContentTips",true)
		UIExtend.setCCLabelString(ccbfile,"mContentTips",_RALang(keyStr))
		return 
	end 
	if data.soldierNum then
		UIExtend.setNodeVisible(ccbfile,"mContentTips",false)
		local soldierNum=Utilitys.formatNumber(data.soldierNum)
		if data.isAbout then  --大约数
			UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@RadarPlayerAboutSoldierNum",soldierNum))
			if not data.soldierMem then
				UIExtend.setNodeVisible(ccbfile,"mContentTips",true)
				UIExtend.setCCLabelString(ccbfile,"mContentTips",_RALang("@TroopsComposition",RAGameConfig.RadarDefaultStr.STR))
			end 		
		else
			if not self.isResouce then
				UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@TroopsNum")..soldierNum)
			else
				UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@ResourceNum",soldierNum))
			end 
			

		end 

		local maxCount=4
		local row=1
		if data.soldierMem then
			UIExtend.setNodeVisible(ccbfile,"mContentTips",false)
			local soldier=data.soldierMem
			local soldierKinds=#soldier
			for i=1,soldierKinds do
				local soldierData=soldier[i]
				local panel = RARadarInfomationPageIconCell:new({
					 isAbout=data.isAbout,
					 isCount=data.soldierMemCount,
					 data=soldierData,
					 isResouce=self.isResouce
	    		})
		        local ccbi=panel:load()
		        panel:updateInfo()
		        local cellW = ccbi:getContentSize().width
		        local cellH = ccbi:getContentSize().height

		        contanerNode:addChild(ccbi)

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
		        if m==0 then
		        	row=row+1
		        end 

			end

			if self.addH and self.addH > 0  then
				topNode:setPositionY(topNode:getPositionY()+self.addH)
				mBg:setContentSize(CCSize(mBg:getContentSize().width,mBg:getContentSize().height+self.addH))
			end
		else
			UIExtend.setCCLabelString(ccbfile,"mContentTips",_RALang("@TroopsComposition",RAGameConfig.RadarDefaultStr.STR))
			UIExtend.setNodeVisible(ccbfile,"mContentTips",true)
		end 
			
		
		
		
	else
		UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@TroopsNum",RAGameConfig.RadarDefaultStr.STR))
		UIExtend.setCCLabelString(ccbfile,"mContentTips",_RALang("@TroopsComposition",RAGameConfig.RadarDefaultStr.STR))
		UIExtend.setNodeVisible(ccbfile,"mContentTips",true)
	end 

end


function RARadarInfomationPageSoldierCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
		self.topNode:setPositionY(self.topNode:getPositionY() -self.addH)
		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
	end
end

function RARadarInfomationPageSoldierCell:onResizeCell(ccbRoot)

	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

-----------------------------------------------------------------------
local RARadarInfomationPageMemberCell = {

}
function RARadarInfomationPageMemberCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RARadarInfomationPageMemberCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbRoot=ccbRoot
	self.ccbfile=ccbfile
	ccbRoot:setIsScheduleUpdate(true)
	local data=self.data
	UIExtend.setCCLabelString(ccbfile,"mTitle",_RALang("@UnionSoldiers"))
	
	--总数
	if self.index==1 then
		UIExtend.setNodeVisible(ccbfile,"mTotalCount",true)
		if self.showCount then
			UIExtend.setCCLabelString(ccbfile,"mTotalCount",_RALang("@UnionSoldiersTotalNum",self.showCount))
		else
			UIExtend.setCCLabelString(ccbfile,"mTotalCount",_RALang("@UnionSoldiersTotalNum",RAGameConfig.RadarDefaultStr.STR))
		end 
	else
		UIExtend.setNodeVisible(ccbfile,"mTotalCount",false)
	end 
	
	--玩家icon
	local iconName=RARadarUtils:getPlayerIcon(data.playerIcon)
	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,iconName,TAG)

	-- --玩家ID mPlayerIdTitle
	UIExtend.setCCLabelString(ccbfile,"mPlayerIdTitle",_RALang("@RadarPlayerID"))
	local name=data.playerName 
	UIExtend.setCCLabelString(ccbfile,"mPlayerId",name)

	--出兵位置
	local playerPos=data.playerPos 
	UIExtend.setCCLabelString(ccbfile,"mPlayerPosTitle",_RALang("@RadarPlayerPos"))
	UIExtend.setCCLabelString(ccbfile,"mPlayerPos",playerPos)

	--预计到达时间
	self.playerArriveTime=data.playerArriveTime
	local curTime = RA_Common:getCurTime()
	local remainTime =os.difftime(self.playerArriveTime,curTime)
	local tmpStr = Utilitys.createTimeWithFormat(remainTime)
	UIExtend.setCCLabelString(self.ccbfile,"mPlayerArriveTime",tmpStr)
	self.mFrameTime=0
	UIExtend.setCCLabelString(ccbfile,"mPlayerArriveTimeTitle",_RALang("@RadarPlayerArriveTime"))
	
end

function RARadarInfomationPageMemberCell:onExecute()
	if self.playerArriveTime then
		self.mFrameTime = self.mFrameTime + RA_Common:getFrameTime()
		if self.mFrameTime>1 then
			local curTime = RA_Common:getCurTime()
			if curTime then
				local remainTime =os.difftime(self.playerArriveTime,curTime)
				if remainTime>0 then
					local tmpStr = Utilitys.createTimeWithFormat(remainTime)
					UIExtend.setCCLabelString(self.ccbfile,"mPlayerArriveTime",tmpStr)
				else
					self.ccbRoot:setIsScheduleUpdate(false)
				end
				
			end
			self.mFrameTime = 0 
		end 
		
	end 
end

-----------------------------------------------------------------------

local OnReceiveMessage = function(message)
   if message.messageID == marchDeleteMsg then  --删除 (行军到达 行军撤销)
   		RARootManager.CloseCurrPage()
   elseif message.messageID == marchUpdateMsg then --更新 (行军加速)
   		RARadarInfomationPage:updateInfo()
   end 
end


function RARadarInfomationPage:Enter(data)


	CCLuaLog("RARadarInfomationPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RARadarInfomationPage.ccbi",self)
	self.ccbfile  = ccbfile

	--把描述和行军id传进来
	self.desStr=data.desStr
	self.marchId=data.marchId

	--self:registerMessageHandler()
	self:init()

end

function RARadarInfomationPage:setTitle()
	if RARadarManage:isNuclearExplosion(self.marchId) then 				    --核弹爆炸
		UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarSpyMarchTopTitle"))	
	elseif RARadarManage:isLightningStorm(self.marchId) then 					  --雷暴
		UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarSpyMarchTopTitle"))
	elseif RARadarManage:isAttackMarch(self.marchId) then 					--攻击类行军
		UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarSpyMarchTopTitle"))	
	elseif RARadarManage:isRadarAssistanceSoldierData(self.marchId) then --士兵援助
		UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarAssistanceSoldierTopTitle"))
	elseif RARadarManage:isRadarAssistanceResourceData(self.marchId) then --资源援助
		UIExtend.setCCLabelString(self.ccbfile,"mTitle",_RALang("@RadarAssistanceResourceTopTitle"))
	end 

end
function RARadarInfomationPage:init()

	--title  
	self:setTitle()
	UIExtend.setCCLabelString(self.ccbfile,"mExplainLabel",_RALang(self.desStr))

	--判断文字是否需要滚动
	self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
	self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
	UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

	self.mInfoListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mInfoListSV")
	self:registerMessageHandler()
	self:updateInfo()
end


function RARadarInfomationPage:updateAssistanceSoldierInfo(marchData)

 	local AssistanceSoldierData=RARadarManage:getshowAssistanceSoldierData(marchData)
 	--玩家基本信息
	local baseCell = CCBFileCell:create()
	local basePanel = RARadarInfomationPageLeaderCell:new({
			data=AssistanceSoldierData,
    })
	baseCell:registerFunctionHandler(basePanel)
	baseCell:setCCBFile("RARadarPageCell1.ccbi")
	self.mInfoListSV:addCellBack(baseCell)
	
	--玩家部队组成部分
	local tmptotalH=0
	if AssistanceSoldierData.soldierMem then
		local soldier=AssistanceSoldierData.soldierMem
		local soldierKinds=#soldier
		local row=math.ceil(soldierKinds/4)

		--100为每个iconCell的高度，60为总间隙包括上下中间
		tmptotalH=row*100+60
	end
	local soldierCell = CCBFileCell:create()
	local soldierPanel = RARadarInfomationPageSoldierCell:new({
			data=AssistanceSoldierData,
			totalH=tmptotalH
    })
    soldierPanel.selfCell=soldierCell
	soldierCell:registerFunctionHandler(soldierPanel)
	soldierCell:setCCBFile("RARadarPageCell2.ccbi")
	self.mInfoListSV:addCellBack(soldierCell)
	self.mInfoListSV:orderCCBFileCells()


end

function RARadarInfomationPage:updateAssistanceResourceInfo(marchData)
	
    local AssistanceResourceData=RARadarManage:getshowAssistanceResourceData(marchData)
    --玩家基本信息
	local baseCell = CCBFileCell:create()
	local basePanel = RARadarInfomationPageLeaderCell:new({
			data=AssistanceResourceData,
    })
	baseCell:registerFunctionHandler(basePanel)
	baseCell:setCCBFile("RARadarPageCell1.ccbi")
	self.mInfoListSV:addCellBack(baseCell)
	
	--玩家部队组成部分
	local tmptotalH=0
	if AssistanceResourceData.soldierMem then
		local soldier=AssistanceResourceData.soldierMem
		local soldierKinds=#soldier
		local row=math.ceil(soldierKinds/4)

		--100为每个iconCell的高度，60为总间隙包括上下中间
		tmptotalH=row*100+60
	end
	local soldierCell = CCBFileCell:create()
	local soldierPanel = RARadarInfomationPageSoldierCell:new({
			data=AssistanceResourceData,
			isResouce=true,
			totalH=tmptotalH
    })
    soldierPanel.selfCell=soldierCell
	soldierCell:registerFunctionHandler(soldierPanel)
	soldierCell:setCCBFile("RARadarPageCell2.ccbi")
	self.mInfoListSV:addCellBack(soldierCell)
	self.mInfoListSV:orderCCBFileCells()
end

function RARadarInfomationPage:updateSuperWeaponInfo(marchData)

	local superWeaponData = RARadarManage:getshowSuperWeaponData(marchData)
	--超级武器基本信息
	local baseCell = CCBFileCell:create()
	local basePanel = RARadarInfomationPageLeaderCell:new({
			data=superWeaponData,
    })
	baseCell:registerFunctionHandler(basePanel)
	baseCell:setCCBFile("RARadarPageCell1.ccbi")
	self.mInfoListSV:addCellBack(baseCell)
	
	local tipsCell = CCBFileCell:create()
	local nuclear = superWeaponData.nuclear  
	local tipsPanel = RARadarInfomationPageSoldierCell:new({
			nuclearFlag=nuclear,
			isSuper = true
			
    })
	tipsCell:registerFunctionHandler(tipsPanel)
	tipsCell:setCCBFile("RARadarPageCell2.ccbi")
	self.mInfoListSV:addCellBack(tipsCell)
	self.mInfoListSV:orderCCBFileCells()

end
function RARadarInfomationPage:updateInfo()
   
    self.mInfoListSV:removeAllCell()
    local scrollview = self.mInfoListSV
	local marchData=RARadarManage:getRadarDataByUuid(self.marchId)
	if not marchData then return end
	if RARadarManage:isSuperWeapon(self.marchId) then	    --超级武器
		self:updateSuperWeaponInfo(marchData)
		return 
	elseif not RARadarManage:isAttackMarch(self.marchId)then --援助类行军
		if RARadarManage:isRadarAssistanceSoldierData(self.marchId) then
			self:updateAssistanceSoldierInfo(marchData)
    		return
		end 

		if RARadarManage:isRadarAssistanceResourceData(self.marchId) then
			self:updateAssistanceResourceInfo(marchData)
    		return
		end
	end 


	local leaderData=RARadarManage:getshowLeaderData(marchData)
	---------------------------------------------------------------------主攻者

	--玩家基本信息
	local baseCell = CCBFileCell:create()
	local basePanel = RARadarInfomationPageLeaderCell:new({
			data=leaderData,
    })
	baseCell:registerFunctionHandler(basePanel)
	baseCell:setCCBFile("RARadarPageCell1.ccbi")
	scrollview:addCellBack(baseCell)
	
	--玩家部队组成部分
	local soldierCell = CCBFileCell:create()
	
	local tmptotalH=0
	if leaderData.soldierMem then
		local soldier=leaderData.soldierMem
		local soldierKinds=#soldier
		local row=math.ceil(soldierKinds/4)

		--100为每个iconCell的高度，60为总间隙包括上下中间
		tmptotalH=row*100+60
	end

	local soldierPanel = RARadarInfomationPageSoldierCell:new({
			data=leaderData,
			totalH=tmptotalH
    })
    soldierPanel.selfCell=soldierCell
	soldierCell:registerFunctionHandler(soldierPanel)
	soldierCell:setCCBFile("RARadarPageCell2.ccbi")

	scrollview:addCellBack(soldierCell)
    local soldierCellH=soldierCell:getContentSize().height

	--将领
	local unionSoldierData,totalCount,isTotalAbout=RARadarManage:getshowMemberData(marchData)

	if leaderData.playerLevel then

		local tmptotalH=0
		if unionSoldierData then
			local playerKinds=#unionSoldierData
			playerKinds=playerKinds+1
			local row=math.ceil(playerKinds/4)

			--100为每个iconCell的高度，60为总间隙包括上下中间
			tmptotalH=row*100+60
		end

		local commanderCell = CCBFileCell:create()
		local commanderPanel = RARadarInfomationPageGeneralCell:new({
			data=leaderData,
			unionData=unionSoldierData,
			totalH=tmptotalH
    	}) 
    	commanderPanel.selfCell=commanderCell
		commanderCell:registerFunctionHandler(commanderPanel)
		commanderCell:setCCBFile("RARadarPageCell2.ccbi")
		scrollview:addCellBack(commanderCell)



	end 

	-- --指挥官加成 显示作用号
	-- if leaderData.buff then
	-- 	local buffTab=leaderData.buff
	-- 	local buffCount=#buffTab

	-- 	if buffCount>0 then

	-- 		local panel = RARadarInfomationPageEffectCell:new({
				
	-- 		})
	--         local ccbi=panel:load()
	--         local childCellH= ccbi:getContentSize().height

	-- 		local titleNodeH=30
	-- 		local totalBuffCellH=buffCount*childCellH+titleNodeH

	-- 		local effectCell = CCBFileCell:create()
	-- 		local effectPanel = RARadarInfomationPageCommanderLeaderCell:new({
	-- 			data=leaderData,
	-- 			totalH=totalBuffCellH,
	--     	})
	-- 		effectPanel.selfCell = effectCell
	-- 		effectCell:registerFunctionHandler(effectPanel)
	-- 		effectCell:setCCBFile("RARadarPageCell2.ccbi")
	-- 		scrollview:addCellBack(effectCell)
	-- 		self.effectPanel=effectPanel
	-- 	end 
	-- end 
	
	
	---------------------------------------------------------------------联合部队

	-- local unionSoldierData,totalCount,isTotalAbout=RARadarManage:getshowMemberData(marchData)
	if next(unionSoldierData) then

		for i=1,#unionSoldierData do

			local showTotalCount=nil
			if i==1 then
				showTotalCount=totalCount
				if isTotalAbout then
					if totalCount then
						showTotalCount=_RALang("@SoldierAboutNum",totalCount)
					end 	
				end 
			end 
			local soldierData=unionSoldierData[i]
			local baseCell = CCBFileCell:create()
			local basePanel = RARadarInfomationPageMemberCell:new({
				data=soldierData,
				showCount=showTotalCount,
				index=i
	    	})
			baseCell:registerFunctionHandler(basePanel)
			baseCell:setCCBFile("RARadarPageCell3.ccbi")
			scrollview:addCellBack(baseCell)

			local tmptotalH=0
			if soldierData.soldierMem and #soldierData.soldierMem>0 then
				local soldier=soldierData.soldierMem
				local soldierKinds=#soldier
				local row=math.ceil(soldierKinds/4)

				--100为每个iconCell的高度，60为总间隙包括上下中间
				tmptotalH=row*100+60

				local soldierCell = CCBFileCell:create()
				local soldierPanel = RARadarInfomationPageSoldierCell:new({
						data=soldierData,
						totalH=tmptotalH
			    })
			    soldierPanel.selfCell=soldierCell
				soldierCell:registerFunctionHandler(soldierPanel)
				soldierCell:setCCBFile("RARadarPageCell2.ccbi")
				scrollview:addCellBack(soldierCell)

			end
			
		end
	end

	scrollview:orderCCBFileCells()

end


function RARadarInfomationPage:registerMessageHandler()

    MessageManager.registerMessageHandler(marchDeleteMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(marchUpdateMsg,OnReceiveMessage) 
  
end

function RARadarInfomationPage:removeMessageHandler()
    MessageManager.removeMessageHandler(marchDeleteMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(marchUpdateMsg,OnReceiveMessage)
    
end
function RARadarInfomationPage:Exit()

	self.mInfoListSV:removeAllCell()
	self.mExplainLabel:stopAllActions()
	self.mExplainLabel:setPosition(self.mExplainLabelStarP)
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RARadarInfomationPage)
	
end

function RARadarInfomationPage:onBack()
	RARootManager.CloseCurrPage()
end





--endregion
