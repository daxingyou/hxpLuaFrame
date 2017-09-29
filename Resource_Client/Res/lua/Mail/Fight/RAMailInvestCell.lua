

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")
local RAGameConfig = RARequire("RAGameConfig")

local MAXCOUNT = 4
local addCellMsg = MessageDef_ScrollViewCell.MSG_MailScoutListCell

RAMailPlayerInvestCell = {}
function RAMailPlayerInvestCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

-- //侦查邮件
-- message DetectMail{
-- 	required int32 result				= 1;	//结果，参考DetectResult
-- 	optional MailPlayerInfo player		= 2;	//被侦查者玩家信息
-- 	repeated RewardItem canPlunderItem	= 3;	//可掠夺资源
-- 	optional int32 defenceArmyAboutNum	= 4;	//防守部队兵大致总数
-- 	optional int32 helpArmyAboutNum		= 5;	//援军士兵大致总数
-- 	repeated int32 defenceArmyIds		= 6;	//防守部队兵种组成
-- 	optional MailArmyInfo myArmy		= 7;	//部队
-- 	optional int32 defenceNum		    = 8;	//防御武器数目
-- 	repeated DefenceBuilding defenceBuildings	= 9;	//防御建筑组成
-- 	repeated MailArmyInfo helpArmy		= 10;	//援军
-- 	repeated EffectPB buff              = 11;	//玩家所获得的作用号数值总和（作用号 100~149 150~199）
-- 	optional GuardInfo guard			= 12;	//被侦查据点信息
-- }

-- //玩家数据
-- message MailPlayerInfo{
-- 	optional string playerId		= 1;	//玩家ID
-- 	optional string name			= 2;	//玩家名称
-- 	optional string guildTag		= 3;	//联盟简称
-- 	optional sint32 icon			= 4;	//玩家头像
-- 	optional sint32 x				= 5;	//坐标X
-- 	optional sint32 y				= 6;	//坐标Y
-- 	optional int32 commanderState	= 7;	//指挥官状态
-- 	optional int32 disBattlePoint	= 8;	//损失的战力
-- 	optional string guildName		= 9;	//联盟全称
-- }

function RAMailPlayerInvestCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local data = self.data
    local configId = self.configId

    local icon=""
    local targetName = ""
    if configId==RAMailConfig.Page.InvestigateYouLiBase then
    	--侦查尤里基地 显示尤里基地头像
    	local Id =data.icon
    	local RAWorldConfigManager = RARequire("RAWorldConfigManager")
		local info = RAWorldConfigManager:GetStrongholdCfg(Id)
		icon = info.icon
		targetName = _RALang(info.armyName)
    elseif configId==RAMailConfig.Page.InvestigateCore then
        -- 首都  显示默认首都的图和名字

        --无归属/有守军/无守军
        if not self.attribution then
            icon = RAMailConfig.CoreIcon
            targetName = _RALang("@Capital")
        elseif self.defenceArmy then
            local Id =data.icon
            icon = RAMailUtility:getPlayerIcon(Id)
            targetName=RAMailUtility:getTargetPlayerName(data)
        else
            icon = RAMailConfig.CoreIcon
            targetName = _RALang("@Capital")
            if data:HasField("guildTag") then
                targetName = "("..data.guildTag..")"..targetName
            end
        end 

    elseif configId==RAMailConfig.Page.InvestigateCastle then
        --联盟堡垒无归属/有守军/无守军
        if not self.attribution then
            local Id = data.icon
            local territory_guard_conf = RARequire("territory_guard_conf")
            local guardInfo = territory_guard_conf[Id]
            if not guardInfo then
                guardInfo=territory_guard_conf[1]
            end
            icon = guardInfo.icon
            targetName = _RALang(guardInfo.armyName)
        elseif self.defenceArmy then
            local Id =data.icon
            icon = RAMailUtility:getPlayerIcon(Id)
            targetName=RAMailUtility:getTargetPlayerName(data)
        else
            local Id = data.icon
            local territory_guard_conf = RARequire("territory_guard_conf")
            local guardInfo = territory_guard_conf[Id]
            if not guardInfo then
                guardInfo=territory_guard_conf[1]
            end
            icon = guardInfo.icon
            targetName = _RALang(guardInfo.armyName)
            if data:HasField("guildTag") then
                targetName = "("..data.guildTag..")"..targetName
            end 
        end 

    elseif configId==RAMailConfig.Page.InvestigatePlatform then
        --发射平台无归属/有守军/无守军
        if not self.attribution then
            local Id = data.icon
            local territory_guard_conf = RARequire("territory_guard_conf")
            local guardInfo = territory_guard_conf[Id]
            if not guardInfo then
                guardInfo=territory_guard_conf[1]
            end
            icon = guardInfo.icon
            targetName = _RALang(guardInfo.armyName)
        elseif self.defenceArmy then
            local Id =data.icon
            icon = RAMailUtility:getPlayerIcon(Id)
            targetName=RAMailUtility:getTargetPlayerName(data)
        else
            local Id = data.icon
            local territory_guard_conf = RARequire("territory_guard_conf")
            local guardInfo = territory_guard_conf[Id]
            if not guardInfo then
                guardInfo=territory_guard_conf[1]
            end
            icon = guardInfo.icon
            targetName = _RALang(guardInfo.armyName)
            if data:HasField("guildTag") then
                targetName = "("..data.guildTag..")"..targetName
            end 
        end 
    else
    	--侦查基地/资源点/驻扎点显示玩家头像
    	local Id =data.icon
    	icon = RAMailUtility:getPlayerIcon(Id)
    	targetName=RAMailUtility:getTargetPlayerName(data)
    end

    UIExtend.setCCLabelHTMLString(ccbfile,"mPlayerName",targetName)
    local time=RAMailUtility:formatMailTime(self.time)
	UIExtend.setCCLabelString(ccbfile,"mTime",time)

	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)
    

    local x = data.x
    local y = data.y

    --首都的坐标固定
    if configId==RAMailConfig.Page.InvestigateCore then
        local RAWorldVar = RARequire("RAWorldVar")
        local targetPos = RAWorldVar.MapPos.Core
        x  = targetPos.x
        y  = targetPos.y
    end 


    local targetPosHtmlStr = _RAHtmlLang("TargetPos",x,y)
	UIExtend.setCCLabelHTMLString(ccbfile,"mAtkPos",targetPosHtmlStr)
    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mAtkPos")
	self.htmlLabel = htmlLabel
	local RAChatManager = RARequire("RAChatManager")
	htmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)

end

function RAMailPlayerInvestCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.htmlLabel then
		self.htmlLabel:removeLuaClickListener()
		self.htmlLabel = nil
	end  	
end

-------------------------------------------------------------------------------
RAMailInvestTitleCell = {}
function RAMailInvestTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestTitleCell:hideArrow(str)
	UIExtend.setNodeVisible(self.ccbfile,"mArrowPic",false)
    UIExtend.setNodeVisible(self.ccbfile,"mClick",false)
    UIExtend.setCCLabelHTMLString(self.ccbfile,"mCellTitle",str)
end
function RAMailInvestTitleCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local radarLV=self.radarLV
    local data = self.data
    local title = ""
    --type: 1 res 2 army 3 aidArmy 4 defweapon 5 effect
    local cellType = self.cellType
    if cellType==1 then
    	title = _RALang("@ScoutPlunder") 
    	self.cellOffest = 1
    elseif cellType==5 then
    	title = _RALang("@ValueScalingBtn")

    	if not data.buff or #data.buff==0 then
    		self:hideArrow(title)
    		return 
    	end 
    	self.cellOffest = 1
    elseif cellType==2 then
    	if radarLV<2 then
    		title = _RAHtmlLang("ScoutTips1")
    		self:hideArrow(title)

    		return 
    		
    	else
    		local defenceArmyAboutNum=data.defenceArmyAboutNum
    		if not defenceArmyAboutNum or defenceArmyAboutNum==0 then
    			title = _RALang("@DefendSoldier",0)
    			self:hideArrow(title)
    			return 
    		end 
    		self.cellOffest =1   --添加cell的个数
    		
			if data.isAbout then
				title = _RALang("@DefendSoldierAbout",defenceArmyAboutNum)
			else
				title = _RALang("@DefendSoldier",defenceArmyAboutNum)
			end 
    	end 
    	
    elseif cellType==3 then
    	if radarLV<4 then
    		title = _RAHtmlLang("ScoutTips2")
    		self:hideArrow(title)
    		return 
   
    	else
            local totalNum=0
            if self.helpSoldiers then
                totalNum=self.helpSoldiers 
            end

    		local count = #data.armyDatas
    		--无援军详细信息
    		if count==0 then
    			if data.isAbout then
    			    title=_RALang("@RescueSoldierAbout",totalNum)
    		    else
    			    title=_RALang("@RescueSoldier",totalNum)
    		    end 

                if totalNum==0 then
                    self:hideArrow(title)
                    return 
                end
    			
    		end 
    		self.cellOffest =count   --添加cell的个数
    		if radarLV==7 then
    			self.cellOffest = count+1
    		end

    		local tmpCount=0
    		for i=1,count do
    			local helpArmy = data.armyDatas[i]
    			tmpCount = tmpCount+helpArmy.soldierTotalNum
    		end
            if tmpCount>0 then
                 totalNum=tmpCount
            end 
           
    		if data.isAbout then
    			title=_RALang("@RescueSoldierAbout",totalNum)
    		else
    			title=_RALang("@RescueSoldier",totalNum)
    		end 
    	end
    	
    elseif cellType==4 then
        if radarLV<3 then
            title= _RAHtmlLang("ScoutTips3")
            self:hideArrow(title)
            return
        end 


    	if data.defenceNum and data.defenceNum==0 then
    		title = _RALang("@DefenceWeaponNum",0)
    		self:hideArrow(title)
    		return 
    	end 
    	self.cellOffest = 1
    	local num = data.defenceNum
    	if radarLV>=3 and radarLV<6 then
    		title = _RALang("@DefenceWeaponNum",num)
    	elseif radarLV>=6 then
    		title = _RALang("@DefenceWeaponNum",num)
    		self.cellOffest = 2
    	end 


    end 
    UIExtend.setCCLabelHTMLString(ccbfile,"mCellTitle",title)

    self.mArrowPic = UIExtend.getCCSpriteFromCCB(ccbfile,"mArrowPic")

    if self.isOpen then
        self.mArrowPic:setRotation(90)
    else
        self.mArrowPic:setRotation(0)
    end 
end

function RAMailInvestTitleCell:onClick()
	--发消息创建不同的cell
	if not self.isOpen then
		self.isOpen= true
		self.mArrowPic:setRotation(90)
	else
		self.isOpen= false
		self.mArrowPic:setRotation(0)
	end 

	-- RAMailScoutPage:refreshCellIndex(self.index,self.isOpen)

	--true时添加一个cell
	if self.isOpen then
		local params={}
		params.isAdd = true
		params.cell = self
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, params)
	else

		--删除这个cell
		local params={}
        params.isAdd = false
        params.cell = self
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, params)
		
	end 

end

function RAMailInvestTitleCell:refreshIndex(index)
	self.cellIndex=index
end

function RAMailInvestTitleCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	UIExtend.setNodeVisible(ccbfile,"mArrowPic",true)
    UIExtend.setNodeVisible(ccbfile,"mClick",true)
end
-------------------------------------------------------------------------------

RAMailInvestResCell = {}
function RAMailInvestResCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestResCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local resDatas = self.data
    local count = #resDatas

    local Const_pb=RARequire("Const_pb")
    local resIdTb={Const_pb.GOLDORE,Const_pb.OIL,Const_pb.STEEL,Const_pb.TOMBARTHITE}
    for i=1,4 do
    	local resData = resDatas[i]
        local resCCB  = UIExtend.getCCBFileFromCCB(ccbfile,"mResCCB"..i)
        local resPicNode = UIExtend.getCCNodeFromCCB(resCCB,"mIconNode")
        if resData then
            local resId = resData.itemId
            local resCount  = resData.itemCount
            resCount = Utilitys.formatNumber(resCount)
            
            if resData.itemCount>0 then
                resCount = "+"..resCount
            end 
            local resIcon = RALogicUtil:getResourceIconById(resId)
            local resName = RALogicUtil:getResourceNameById(resId)
            UIExtend.addNodeToAdaptParentNode(resPicNode,resIcon,RAMailConfig.TAG)

            UIExtend.setCCLabelString(resCCB,"mCellLabel",resName)
            UIExtend.setCCLabelString(resCCB,"mCellNum",resCount)
            UIExtend.setLabelTTFColor(resCCB,"mCellNum",RAGameConfig.COLOR.GREEN)
        else
            local resId=resIdTb[i]
            local resIcon = RALogicUtil:getResourceIconById(resId)
            local resName = RALogicUtil:getResourceNameById(resId)
            UIExtend.addNodeToAdaptParentNode(resPicNode,resIcon,RAMailConfig.TAG)
            UIExtend.setCCLabelString(resCCB,"mCellLabel",resName)
    
            UIExtend.setCCLabelString(resCCB,"mCellNum",_RALang("@TheTargetIsNotTheResource"))
        end 
    end

end

-------------------------------------------------------------------------------

RAMailInvestTipsCell = {}

function RAMailInvestTipsCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestTipsCell:load()
    local ccbi = UIExtend.loadCCBFile("RAMailScoutCellTipsV6.ccbi", self)
    return ccbi
end

function  RAMailInvestTipsCell:getCCBFile()
    return self.ccbfile
end

function  RAMailInvestTipsCell:updateInfo()
    local ccbfile = self:getCCBFile()

    local htmlStr = self.str
    UIExtend.setCCLabelHTMLString(ccbfile,"mCellTipsLabel",htmlStr)
end
-----------------------------------------------------------------
RAMailInvestTipsNodeCell={}
function RAMailInvestTipsNodeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestTipsNodeCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local  mContainer = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
    mContainer:removeAllChildren()
    self.mContainer = mContainer

    local panel = RAMailInvestTipsCell:new({
                str = self.htmlStr,
    })
    local ccbi=panel:load()
    panel:updateInfo()
    self.mContainer:addChild(ccbi)
end 

-------------------------------------------------------------------------------
RAMailInvestArmyPlayerCell = {}
function RAMailInvestArmyPlayerCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestArmyPlayerCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local data = self.data
    local myArmy = data.myArmy
    -- local playerData  =self.playerData
    local configId = self.configId

    local icon=""
    local targetName = ""
    if configId==RAMailConfig.Page.InvestigateYouLiBase then
    	--侦查尤里基地 显示尤里基地头像
    	local Id =myArmy.icon
    	local RAWorldConfigManager = RARequire("RAWorldConfigManager")
		local info = RAWorldConfigManager:GetStrongholdCfg(Id)
		icon = info.icon
		targetName = _RALang(info.armyName)
    else
    	--侦查基地/堡垒/资源点/驻扎点/首都 显示玩家头像
    	local Id =myArmy.icon
    	icon = RAMailUtility:getPlayerIcon(Id)
    	targetName = myArmy.playerName
    end
  
    local level = myArmy.level
    local num = data.defenceArmyAboutNum
    num=Utilitys.formatNumber(num)
    local htmlStr = _RAHtmlLang("ScoutArmyPlayer",targetName,num,level)
    UIExtend.setCCLabelHTMLString(ccbfile,"mPlayerName",htmlStr)
   
    local time=RAMailUtility:formatMailTime(self.time)
	UIExtend.setCCLabelString(ccbfile,"mLevel",time)

	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

end 
-------------------------------------------------------------------------------

RAMailInvestHelpArmyPlayerCell = {}
function RAMailInvestHelpArmyPlayerCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestHelpArmyPlayerCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local data = self.data
    local configId = self.configId

    local icon=""
    local targetName = ""
    if configId==RAMailConfig.Page.InvestigateYouLiBase then
        --侦查尤里基地 显示尤里基地头像
        local Id =data.playerIcon
        local RAWorldConfigManager = RARequire("RAWorldConfigManager")
        local info = RAWorldConfigManager:GetStrongholdCfg(Id)
        icon = info.icon
        targetName = _RALang(info.armyName)
    else
        --侦查基地/堡垒/资源点/驻扎点/首都 显示玩家头像
        local Id =data.playerIcon
        icon = RAMailUtility:getPlayerIcon(Id)
        targetName = data.playerName
    end
  
    local level = data.playerLevel
    local num = data.soldierTotalNum
    num=Utilitys.formatNumber(num)
    local htmlStr = _RAHtmlLang("ScoutArmyPlayer",targetName,num,level)
    UIExtend.setCCLabelHTMLString(ccbfile,"mPlayerName",htmlStr)
   
    local time=RAMailUtility:formatMailTime(self.time)
    UIExtend.setCCLabelString(ccbfile,"mLevel",time)

    local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

end 

-------------------------------------------------------------------------------
RAMailScoutArmyCell = {}

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
-------------------------------------------------------------------------------

--自己的士兵cell
RAMailInvestSolder1Cell = {}
function RAMailInvestSolder1Cell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailInvestSolder1Cell:setIconPos(ccbi,i,maxCount,row)
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

function RAMailInvestSolder1Cell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode1")
    local contanerNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode2")
    local tipsNode = UIExtend.getCCNodeFromCCB(ccbfile,"mTipsCCBNode")
    tipsNode:removeAllChildren()
    contanerNode1:removeAllChildren()
	-- local topNode = UIExtend.getCCNodeFromCCB(ccbfile,"mTopNode")
	-- self.topNode=topNode
	contanerNode:removeAllChildren()
	self.contanerNode = contanerNode

    local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBG")
    self.mBg = mBg


    local data = self.data
    local defenceSoldierMem = data.defenceSoldierMem

    if data.isSoldierShowCount then
		local soldierDatas=data.defenceSoldierMem
		local count=#soldierDatas
		local totalNum=0
		local maxCount=MAXCOUNT
		local row=1

		for i=1,count do
			local soldierData=soldierDatas[i]
			local armyId=soldierData.soldierId
			local ArmyInfo=RAMailUtility:getBattleSoldierDataById(armyId)
			local num=soldierData.defencedCount


			local numberStr=""
			
			if data.isAbout then
				numberStr=_RALang("@SoldierAboutNum",num)
			else
				numberStr=num
			end 
			totalNum=totalNum+num
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

	else

		local defenceArmyIds=data.defenceSoldierMem
		local count=#defenceArmyIds 

		local maxCount=MAXCOUNT
		local row=1
		for i=1,count do
			local ArmyId=defenceArmyIds[i]
			local ArmyInfo=RAMailUtility:getBattleSoldierDataById(ArmyId)
			local number=_RALang("@UnkownNum")
	
			local panel = RAMailScoutArmyCell:new({
					icon=ArmyInfo.icon,
					num=number
			})
		    local ccbi=panel:load()
		    panel:updateInfo()

		    local m=self:setIconPos(ccbi,i,maxCount,row)
		    if m==0 then
	        	row=row+1
	        end 
		end
	end


    if self.radarLV and self.radarLV <9 then
        local panel = RAMailInvestTipsCell:new({
                str = self.htmlStr,
        })
        local ccbi=panel:load()
        panel:updateInfo()
        tipsNode:addChild(ccbi)
    end 

	--调整背景
	if self.addH and self.addH > 0  then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
	end

end

function RAMailInvestSolder1Cell:onResizeCell(ccbRoot)
	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

function RAMailInvestSolder1Cell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
	end
end


-------------------------------------------------------------------------------
--援军的士兵cell
RAMailInvestSolder2Cell = {}
function RAMailInvestSolder2Cell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailInvestSolder2Cell:setIconPos(ccbi,i,maxCount,row)
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

function RAMailInvestSolder2Cell:refreshPlayerData(data)
	
	local playerCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mPlayerCCB")
	self.playerCCB = playerCCB

	local playerName=data.playerName
	self.playerName=playerName
	local level=data.playerLevel
	local iconId=data.playerIcon
	local icon=RAMailUtility:getPlayerIcon(iconId)

	local totalNum=data.soldierTotalNum
	totalNum=Utilitys.formatNumber(totalNum)
	local htmlStr=""
	if data.isAbout then
		htmlStr = _RAHtmlLang("ScoutArmyPlayer",playerName,totalNum,level)
	else
		htmlStr = _RAHtmlLang("ScoutArmyAccuratePlayer",playerName,totalNum,level)

	end 

   
    UIExtend.setCCLabelHTMLString(playerCCB,"mPlayerName",htmlStr)
   
    local time=RAMailUtility:formatMailTime(self.time)
	UIExtend.setCCLabelString(playerCCB,"mLevel",time)

	local picNode = UIExtend.getCCNodeFromCCB(playerCCB,"mIconNode")
    UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)


end
function RAMailInvestSolder2Cell:onRefreshContent(ccbRoot)
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

	self:refreshPlayerData(data)


    if data.helpSoldierMem then
        local soldierDatas=data.helpSoldierMem
        local soldierKinds=#soldierDatas
        local maxCount=MAXCOUNT
        local row=1

        for i=1,soldierKinds do
            local soldierData=soldierDatas[i]
            local armyId=soldierData.soldierId
            local ArmyInfo=RAMailUtility:getBattleSoldierDataById(armyId)
            local num=soldierData.defencedCount
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
    end 
    

    if self.radarLV and self.radarLV <10 then
        local panel = RAMailInvestTipsCell:new({
                str = self.htmlStr,
        })
        local ccbi=panel:load()
        panel:updateInfo()
        tipsNode:addChild(ccbi)
    end 

    --调整
    if self.addH and self.addH>0 then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))
    	self.playerCCB:setPositionY(self.playerCCB:getPositionY()+self.addH)
    	self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
    end 

end

function RAMailInvestSolder2Cell:onResizeCell(ccbRoot)
	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height
	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

function RAMailInvestSolder2Cell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
		self.playerCCB:setPositionY(self.playerCCB:getPositionY()-self.addH)
    	self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
	end
end

-------------------------------------------------------------------------------
--防御武器cell
RAMailInvestDefWeaponCell = {}
function RAMailInvestDefWeaponCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailInvestDefWeaponCell:setIconPos(ccbi,i,maxCount,row)
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

function RAMailInvestDefWeaponCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode2")
    local contanerNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mSoldierFrameNode1")
    local tipsNode =UIExtend.getCCNodeFromCCB(ccbfile,"mTipsCCBNode")
    self.tipsNode = tipsNode
    tipsNode:removeAllChildren()
    contanerNode1:removeAllChildren()

	contanerNode:removeAllChildren()
	self.contanerNode = contanerNode

    local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBG")
    self.mBg = mBg 
	local data = self.data
	local count=#data
	local maxCount=MAXCOUNT-1
	local row=1
	for i=1,count do
		local buildData=data[i]
		local iconName=buildData.buildArtImg

		local panel = RAMailScoutArmyCell:new({
				icon=iconName,
				def = true
		})
	    local ccbi=panel:load()
	    panel:updateInfo()

	    local m=self:setIconPos(ccbi,i,maxCount,row)
	    if m==0 then
        	row=row+1
        end 
    end

    --自己构建一张表
    local defenceMem = self.defenceMem
    local tbs={}
    for i=1,self.maxCount do
        -- local RAMailUtility = RARequire("RAMailUtility")
        local t=RAMailUtility:getWeaponNum(defenceMem,i)
        table.insert(tbs,t)
    end
    for i=1,self.maxCount do
        local panel = RAMailInvestWeaponNumCell:new({
                level = i,
                nums = tbs[i]
        })
        local ccbi=panel:load()
        panel:updateInfo()

        tipsNode:addChild(ccbi)
        local cellH = ccbi:getContentSize().height
        local posY = -(i-1)*cellH
        ccbi:setPositionY(posY)
    end


	--调整背景
	if self.addH and self.addH > 0  then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))			
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
        self.tipsNode:setPositionY(self.tipsNode:getPositionY()+self.addH+20)
	end
end

function RAMailInvestDefWeaponCell:onResizeCell(ccbRoot)
	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

function RAMailInvestDefWeaponCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
        self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
        self.tipsNode:setPositionY(self.tipsNode:getPositionY()-self.addH-20)
	end
end

----------------------------------------------------------------------------------------
RAMailInvestWeaponNumCell = {}

function RAMailInvestWeaponNumCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvestWeaponNumCell:load()
	local ccbi = UIExtend.loadCCBFile("RAMailScoutMainCell6V6.ccbi", self)
    return ccbi
end

function  RAMailInvestWeaponNumCell:getCCBFile()
	return self.ccbfile
end

function  RAMailInvestWeaponNumCell:updateInfo()
	local ccbfile = self:getCCBFile()

	-- weaponData
	local data = self.weaponData
	local level = self.level
	UIExtend.setCCLabelString(ccbfile,"mLevel",_RALang("@ResourceLevel",level))

	local nums = self.nums

	local t={}
	t["mNum1"]=nums[1]
	t["mNum2"]=nums[2]
	t["mNum3"]=nums[3]
	UIExtend.setStringForLabel(ccbfile, t)

end
----------------------------------------------------------------------------------------
-- RAMailInvestDefLevelCell = {}
-- function RAMailInvestDefLevelCell:new(o)
--     o = o or {}
--     setmetatable(o,self)
--     self.__index = self    
--     return o
-- end
-- function RAMailInvestDefLevelCell:onRefreshContent(ccbRoot)
-- 	if not ccbRoot then return end
-- 	local ccbfile = ccbRoot:getCCBFileNode()
--     self.ccbfile = ccbfile

--     local data = self.data

--     local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
--     contanerNode:removeAllChildren()
-- 	self.contanerNode = contanerNode

-- 	local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBg")
-- 	self.mBg = mBg

-- 	--自己构建一张表

-- 	local tbs={}
-- 	for i=1,self.maxCount do
-- 		local t=RAMailUtility:getWeaponNum(data,i)
-- 		table.insert(tbs,t)
-- 	end
-- 	for i=1,self.maxCount do
-- 		local panel = RAMailInvestWeaponNumCell:new({
-- 				level = i,
-- 				nums = tbs[i]
-- 		})
-- 	    local ccbi=panel:load()
-- 	    panel:updateInfo()

-- 	    self.contanerNode:addChild(ccbi)
-- 	    local cellH = ccbi:getContentSize().height
-- 	    local posY = -(i-1)*cellH
-- 	    ccbi:setPositionY(posY)
-- 	end

-- 		--调整背景
-- 	if self.addH and self.addH > 0  then			
-- 		self.mBg:setPositionY(self.mBg:getPositionY()+self.addH)
-- 		self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
-- 		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))
-- 	end


-- end

-- function RAMailInvestDefLevelCell:onResizeCell(ccbRoot)
-- 	 if self.totalH then
-- 	 	local height = ccbRoot:getContentSize().height

-- 	 	height = math.max(height, self.totalH)
-- 	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
-- 	 	self.addH = height - ccbRoot:getContentSize().height
-- 	 end

-- end

-- function RAMailInvestDefLevelCell:onUnLoad(ccbRoot)
-- 	if not ccbRoot then return end
-- 	local ccbfile = ccbRoot:getCCBFileNode()
-- 	if self.addH and self.addH > 0 then
-- 		self.mBg:setPositionY(self.mBg:getPositionY()-self.addH)
-- 		self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
-- 		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
-- 	end
-- end

-----------------------------------------------------------------------------------------------------------
RAMailInvesteffectNumCell = {}

function RAMailInvesteffectNumCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAMailInvesteffectNumCell:load()
	local ccbi = UIExtend.loadCCBFile("RAMailScoutMainCell8V6.ccbi", self)
    return ccbi
end

function  RAMailInvesteffectNumCell:getCCBFile()
	return self.ccbfile
end

function RAMailInvesteffectNumCell:getEffectNameAndValue(effectData)
	local effectId= effectData.effId
	local effectValue=effectData.effVal
	local key="@EffectNum"..effectId
	local effectData=RAMailUtility:getEffectDataById(effectId)
	local effectType=effectData.type  --1是百分数 0是数值
	local name=_RALang(key)
	local value=""
	if effectType==1 then
		value=_RALang("@VIPAttrValueAdditionPercent",effectValue/100)
	elseif effectType==0 then
		value=_RALang("@VIPAttrValueAdditionNoSymble",effectValue)
	end

	return name..":"..value 


end

function  RAMailInvesteffectNumCell:updateInfo()
	local ccbfile = self:getCCBFile()

	-- weaponData

	local data =self.data
	local myEffect = data[1]
	local oppEffect = data[2]

	local str1 = self:getEffectNameAndValue(myEffect)
	UIExtend.setCCLabelString(ccbfile,"mAdditionLabel1",str1)

	if not oppEffect then
		UIExtend.setNodeVisible(ccbfile,"mAdditionLabel2",false)
		return
	else
		UIExtend.setNodeVisible(ccbfile,"mAdditionLabel2",true)
	end 
	local str2 = self:getEffectNameAndValue(oppEffect)
	UIExtend.setCCLabelString(ccbfile,"mAdditionLabel2",str2)

end

-----------------------------------------------------------------------------------------------------------
RAMailInvestEffectCell = {}
function RAMailInvestEffectCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAMailInvestEffectCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile

    local data = self.data

    local contanerNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContainer")
    contanerNode:removeAllChildren()
	self.contanerNode = contanerNode

	local mBg = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBg")
	self.mBg = mBg

	--自己构建一张表
	local data = self.data
	local count = #data

	for i=1,count do
		local effect = data[i]
		local panel = RAMailInvesteffectNumCell:new({
				data = effect,
		})
	    local ccbi=panel:load()
	    panel:updateInfo()

	    self.contanerNode:addChild(ccbi)
	    local cellH = ccbi:getContentSize().height
	    local posY = -(i-1)*cellH
	    ccbi:setPositionY(posY)
	end

		--调整背景
	if self.addH and self.addH > 0  then			
		self.mBg:setPositionY(self.mBg:getPositionY()+self.addH)
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()+self.addH)
		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height+self.addH))
	end


end

function RAMailInvestEffectCell:onResizeCell(ccbRoot)
	 if self.totalH then
	 	local height = ccbRoot:getContentSize().height

	 	height = math.max(height, self.totalH)
	 	self.selfCell:setContentSize(CCSize(ccbRoot:getContentSize().width, height))
	 	self.addH = height - ccbRoot:getContentSize().height
	 end

end

function RAMailInvestEffectCell:onUnLoad(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	if self.addH and self.addH > 0 then
		self.mBg:setPositionY(self.mBg:getPositionY()-self.addH)
		self.contanerNode:setPositionY(self.contanerNode:getPositionY()-self.addH)
		self.mBg:setContentSize(CCSize(self.mBg:getContentSize().width,self.mBg:getContentSize().height-self.addH))
	end
end
