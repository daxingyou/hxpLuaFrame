--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
local RANetUtil=RARequire("RANetUtil")
local HP_pb=RARequire("HP_pb")
local Player_pb=RARequire("Player_pb")
local world_map_const_conf=RARequire("world_map_const_conf")
local RABuildManager=RARequire("RABuildManager")
local RAMarchDataManager=RARequire("RAMarchDataManager")
local RAGameConfig=RARequire("RAGameConfig")
local RAWorldMath=RARequire("RAWorldMath")
local RAMarchConfig = RARequire('RAMarchConfig')
local world_march_const_conf = RARequire("world_march_const_conf")

local TAG=1000

local RAWorldResourceAidPage = BaseFunctionPage:new(...)





-----------------------------------------------------------


local OnReceiveMessage = function(message)     
    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode          
        for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
            local c2s = v.c2s
            if opcode == c2s then
                RARootManager.RemoveWaitingPage()
                break    
            end
        end
    end
end

function RAWorldResourceAidPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldResourceAidPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldResourceAidPage:Enter(data)
	CCLuaLog("RAWorldResourceAidPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAAllianceResAidPopUp.ccbi",self)
	self.ccbfile  = ccbfile

	self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.GoldEditBox:isKeyboardShow() == true or self.OilEditBox:isKeyboardShow() == true or self.SteelEditBox:isKeyboardShow() == true 
        or self.RareEarthsEditBox:isKeyboardShow() == true then
        else
        	RARootManager.ClosePage("RAWorldResourceAidPage")
        end
    end

	self:registerMessageHandlers()
    for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
        local s2c = v.s2c
        self:RegisterPacketHandler(s2c)
    end

	local startPos=RAPlayerInfoManager.getWorldPos()
   	self.startPos=startPos
   	self.endPos=data.endPos		
   	self.targetLevel=data.level
   	self.inputNumsTab={}

   	--资源开启条件
   	local stepCityLevel2=world_map_const_conf["stepCityLevel2"]
	local arr=RAStringUtil:split(stepCityLevel2.value,"_") 
	self.steelLimitLevel = tonumber(arr[1])
	self.rareEarthsLevel = tonumber(arr[2])
	self.cityLevel = RABuildManager:getMainCityLvl()

	--资源换算成负重比例
	self.GOLDORERatio = world_march_const_conf["res1007Weight"].value
	self.OILRatio = world_march_const_conf["res1008Weight"].value
	self.STEELRatio = world_march_const_conf["res1009Weight"].value
	self.TOMBARTHITERatio = world_march_const_conf["res1010Weight"].value
	self:init()
end


function RAWorldResourceAidPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()    
    for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
        local s2c = v.s2c
        if opcode == s2c then
            local msg = World_pb.WorldMarchResp()
            msg:ParseFromString(buffer)
             local success = msg.success
            local RARootManager = RARequire('RARootManager')
            if success then
                RARootManager:CloseAllPages()
            end
            RARootManager.RemoveWaitingPage()
        end
    end

end

function RAWorldResourceAidPage:hideAllLockNode()
	UIExtend.setNodeVisible(self.ccbfile,"mSteelLockedNode",false)
	UIExtend.setNodeVisible(self.ccbfile,"mRareEarthsLockedNode",false)
end

function RAWorldResourceAidPage:sliderMoved(slider)
	self:refreshResourceValue(slider)
end
function RAWorldResourceAidPage:sliderEnded(slider)
	self:refreshSliderValue(slider)
	
	--刷新负重
	local curTotalAidCount=self:getCurTotalAidCount()
	self:setBurdenTxt(curTotalAidCount)

	--刷新时间
	self:refreshAssitanceBtnAndTxt()
end

function RAWorldResourceAidPage:refreshSliderValue(slider)

	local sliderTag=slider:getTag()
	local value=slider:getValue()
	value = math.floor(value)
	self:refreshInputNumTab(value,sliderTag)
	
	local num=0
	local numStr=""
	local editBox=nil

	if sliderTag==Const_pb.GOLDORE then
		num=self.inputNumsTab[1]
		if self.goldNum <= 0 then
			num = 0
		end
		numStr=Utilitys.formatNumber(num)
		editBox=self.GoldEditBox

	elseif sliderTag==Const_pb.OIL then

		num=self.inputNumsTab[2]
		if self.oilNum <= 0 then
			num = 0
		end
		numStr=Utilitys.formatNumber(num)
		editBox=self.OilEditBox

	elseif sliderTag==Const_pb.STEEL then

		num=self.inputNumsTab[3]

		if self.steelNum <= 0 then
			num = 0
		end
		numStr=Utilitys.formatNumber(num)
		editBox=self.SteelEditBox
	elseif sliderTag==Const_pb.TOMBARTHITE then
		num=self.inputNumsTab[4]

		if self.rareEarthsNum <= 0 then
			num = 0
		end
		numStr=Utilitys.formatNumber(num)
		editBox=self.RareEarthsEditBox
	end 


	slider:setValue(num)
	editBox:setText(numStr)
	self:refrestWillReceiveResource(num,sliderTag)
end


function RAWorldResourceAidPage:refreshResourceValue(slider)
	local sliderTag=slider:getTag()
	local value=slider:getValue()
	value = math.floor(value)
	-- value=math.min(0,value)

	self:refreshInputNumTab(value,sliderTag)
	local numStr=Utilitys.formatNumber(value)
	if sliderTag==Const_pb.GOLDORE then
		
		self.GoldEditBox:setText(numStr)
	elseif sliderTag==Const_pb.OIL then
		-- numStr=Utilitys.formatNumber(self.inputNumsTab[2])
		self.OilEditBox:setText(numStr)
	elseif sliderTag==Const_pb.STEEL then
		-- numStr=Utilitys.formatNumber(self.inputNumsTab[3])
		self.SteelEditBox:setText(numStr)
	elseif sliderTag==Const_pb.TOMBARTHITE then
		-- numStr=Utilitys.formatNumber(self.inputNumsTab[4])
		self.RareEarthsEditBox:setText(numStr)
	end 
end


function RAWorldResourceAidPage:setSliderMinAndMax()
	self.GoldControlSlider:setMinimumValue(0)
	self.OilControlSlider:setMinimumValue(0)
	self.SteelControlSlider:setMinimumValue(0)
	self.RareEarthsControlSlider:setMinimumValue(0)

	local goldNumMax = self.goldNum
	if goldNumMax <= 0 then
		goldNumMax = 1
	end
	self.GoldControlSlider:setMaximumValue(goldNumMax)

	local oilNumMax = self.oilNum
	if oilNumMax <= 0 then
		oilNumMax = 1
	end
	self.OilControlSlider:setMaximumValue(oilNumMax)

	local steelNumMax = self.steelNum
	if steelNumMax <= 0 then
		steelNumMax = 1
	end
	self.SteelControlSlider:setMaximumValue(steelNumMax)

	local rareEarthsNumMax = self.rareEarthsNum
	if rareEarthsNumMax <= 0 then
		rareEarthsNumMax = 1
	end
	self.RareEarthsControlSlider:setMaximumValue(rareEarthsNumMax)
end

function RAWorldResourceAidPage:initCanAidResource()
	--可援助资源
	local goldNum=RAPlayerInfoManager.getResCountById(Const_pb.GOLDORE)
	local oilNum=RAPlayerInfoManager.getResCountById(Const_pb.OIL)
	local steelNum=RAPlayerInfoManager.getResCountById(Const_pb.STEEL)
	local rareEarthsNum=RAPlayerInfoManager.getResCountById(Const_pb.TOMBARTHITE)

	self.goldNum=goldNum
	self.oilNum=oilNum
	self.steelNum=steelNum
	self.rareEarthsNum=rareEarthsNum
	UIExtend.setCCLabelString(self.ccbfile,"mCanAidGoldNum",RALogicUtil:num2k(goldNum))
	UIExtend.setCCLabelString(self.ccbfile,"mCanAidOilNum",RALogicUtil:num2k(oilNum))
	UIExtend.setCCLabelString(self.ccbfile,"mCanAidSteelNum",RALogicUtil:num2k(steelNum))
	UIExtend.setCCLabelString(self.ccbfile,"mCanAidRareEarthsNum",RALogicUtil:num2k(rareEarthsNum))

	--判断自己是否开启
	UIExtend.setNodeVisible(self.ccbfile,"mCanAidSteelNode",false)
	UIExtend.setNodeVisible(self.ccbfile,"mCanAidRareEarthsNode",false)
	if self.cityLevel>=self.steelLimitLevel then
		UIExtend.setNodeVisible(self.ccbfile,"mCanAidSteelNode",true)
	end 

	if self.cityLevel>=self.rareEarthsLevel then
		UIExtend.setNodeVisible(self.ccbfile,"mCanAidRareEarthsNode",true)
	end  

end

function RAWorldResourceAidPage:initSliderUI()
	--滑块
	self:hideAllLockNode()
	local ccbfile=self.ccbfile
	local GoldControlSlider = UIExtend.getControlSlider("mSelectGoldBarNode", ccbfile,true)
	GoldControlSlider:setTag(Const_pb.GOLDORE)
	self.GoldControlSlider=GoldControlSlider
	GoldControlSlider:registerScriptSliderHandler(self)


	local OilControlSlider = UIExtend.getControlSlider("mSelectOilBarNode", ccbfile,true)
	OilControlSlider:setTag(Const_pb.OIL)
	self.OilControlSlider=OilControlSlider
	OilControlSlider:registerScriptSliderHandler(self)

	local SteelControlSlider = UIExtend.getControlSlider("mSelectSteelBarNode", ccbfile,true)
	SteelControlSlider:setTag(Const_pb.STEEL)
	self.SteelControlSlider=SteelControlSlider
	SteelControlSlider:registerScriptSliderHandler(self)
	SteelControlSlider:setPositionX(SteelControlSlider:getPositionX())
	UIExtend.setNodeVisible(self.ccbfile,"mSteelLockedNode",true)

	local RareEarthsControlSlider = UIExtend.getControlSlider("mSelectRareEarthsBarNode", ccbfile,true)
	RareEarthsControlSlider:setTag(Const_pb.TOMBARTHITE)
	self.RareEarthsControlSlider=RareEarthsControlSlider
	RareEarthsControlSlider:registerScriptSliderHandler(self)
	RareEarthsControlSlider:setPositionX(RareEarthsControlSlider:getPositionX())
	UIExtend.setNodeVisible(self.ccbfile,"mRareEarthsLockedNode",true)

	self:setSliderMinAndMax()


	--判断对方以及我方是否开启资源 钢铁和稀土
	if self.cityLevel<self.steelLimitLevel or self.targetLevel<self.steelLimitLevel then
		SteelControlSlider:setEnabled(false)
		self.SteelEditBox:setEnabled(false)
		UIExtend.setNodeVisible(self.ccbfile,"mSteelLockedNode",true)
		if self.cityLevel<self.steelLimitLevel then
			UIExtend.setCCLabelString(self.ccbfile,"mSteelTips",_RALang("@TheOwnIsNotTheResource"))
		else
			UIExtend.setCCLabelString(self.ccbfile,"mSteelTips",_RALang("@TheTargetIsNotTheResource"))
		end
	else
		SteelControlSlider:setEnabled(true)
		self.SteelEditBox:setEnabled(true)
		UIExtend.setNodeVisible(self.ccbfile,"mSteelLockedNode",false)
	end 

	if self.cityLevel<self.rareEarthsLevel or self.targetLevel<self.rareEarthsLevel then
		RareEarthsControlSlider:setEnabled(false)
		self.RareEarthsEditBox:setEnabled(false)
		UIExtend.setNodeVisible(self.ccbfile,"mRareEarthsLockedNode",true)
		if self.cityLevel<self.rareEarthsLevel then
			UIExtend.setCCLabelString(self.ccbfile,"mRareEarthsTips",_RALang("@TheOwnIsNotTheResource"))
		else
			UIExtend.setCCLabelString(self.ccbfile,"mRareEarthsTips",_RALang("@TheTargetIsNotTheResource"))
		end
	else
		RareEarthsControlSlider:setEnabled(true)
		self.RareEarthsEditBox:setEnabled(true)
		UIExtend.setNodeVisible(self.ccbfile,"mRareEarthsLockedNode",false)
	end 

end


function RAWorldResourceAidPage:refreshInputNumTab(num,resourceType)
	num=tonumber(num)
	local RetainCount=self:getInputRetain(resourceType)
	if RetainCount<0 then return end 
	if resourceType==Const_pb.GOLDORE then
		if self.goldNum <= 0 then
			num = 0
		elseif num > self.goldNum then
			num	= self.goldNum	
		end
		if num*self.GOLDORERatio >=RetainCount then
			self.inputNumsTab[1] = math.floor(RetainCount/self.GOLDORERatio)
		else
			self.inputNumsTab[1] = num
		end 
	elseif resourceType==Const_pb.OIL then
		if self.oilNum <= 0 then
			num = 0
		elseif num > self.oilNum then
			num	= self.oilNum
		end

		local mOILRatio = num*self.OILRatio
		if mOILRatio >= RetainCount then
			self.inputNumsTab[2] = math.floor(RetainCount/self.OILRatio)
		else
			self.inputNumsTab[2] = num
		end 

	elseif resourceType==Const_pb.STEEL then
		if self.steelNum <= 0 then
			num = 0
		elseif num > self.steelNum then
			num	= self.steelNum		
		end
		if num*self.STEELRatio >=RetainCount then
			self.inputNumsTab[3] = math.floor(RetainCount/self.STEELRatio)
		else
			self.inputNumsTab[3] = num
		end 
	elseif resourceType==Const_pb.TOMBARTHITE then
		if self.rareEarthsNum <= 0 then
			num = 0
		elseif num > self.rareEarthsNum then
			num	= self.rareEarthsNum		
		end
		if num*self.TOMBARTHITERatio >=RetainCount then
			self.inputNumsTab[4] = math.floor(RetainCount/self.TOMBARTHITERatio)
		else
			self.inputNumsTab[4] = num
		end 
	end 
end

--计算输入时能输入的最大量 返回负重
function RAWorldResourceAidPage:getInputRetain(resourceType)
	local totalNum=self.marketBurden
	local tmp=0

	if resourceType==Const_pb.GOLDORE then
		tmp=self.inputNumsTab[2]*self.OILRatio+self.inputNumsTab[3]*self.STEELRatio+self.inputNumsTab[4]*self.TOMBARTHITERatio
	elseif resourceType==Const_pb.OIL then
		tmp=self.inputNumsTab[1]*self.GOLDORERatio+self.inputNumsTab[3]*self.STEELRatio+self.inputNumsTab[4]*self.TOMBARTHITERatio

	elseif resourceType==Const_pb.STEEL then
		tmp=self.inputNumsTab[1]*self.GOLDORERatio+self.inputNumsTab[2]*self.OILRatio+self.inputNumsTab[4]*self.TOMBARTHITERatio
	elseif resourceType==Const_pb.TOMBARTHITE then
		tmp=self.inputNumsTab[1]*self.GOLDORERatio+self.inputNumsTab[2]*self.OILRatio+self.inputNumsTab[3]*self.STEELRatio
	end 
	return math.max(0,totalNum-tmp)
end


function RAWorldResourceAidPage:initEditBoxUI()
	local function inputEditboxEventHandler(eventType, node)

   		if eventType == "ended" then
   		 	local num=node:getText()
	    	local tag=node:getTag()
	    	if not tonumber(num) or tonumber(num)<0 then 
	    		node:setText(0)
	    		self:refreshInputNumTab(0,tag)
	    		self:refrestWillReceiveResource(0,tag)


	    		--更新商队负重
	    		local curCount=self:getCurTotalAidCount()
	    		self:setBurdenTxt(curCount)
	    		--刷新运输时间
	    		self:refreshAssitanceBtnAndTxt()
	    	else
	    		self:refreshInputNumTab(num,tag)

	    		--计算当前可运输的剩余资源 返回的是负重
	    		local retainInput=self:getInputRetain(tag)
	    		num=tonumber(num)

	    		if tag==Const_pb.GOLDORE then
	    			if num>=retainInput/self.GOLDORERatio then
	    				num = math.floor(retainInput/self.GOLDORERatio)
	    			end 
	    			if self.goldNum <= 0 then
	    				num = 0
	    			elseif num > self.goldNum then
	    				num	= self.goldNum	
	    			end
	    		elseif tag==Const_pb.OIL then
	    			if num>=retainInput/self.OILRatio then
	    				num = math.floor(retainInput/self.OILRatio)
	    			end 
	    			if self.oilNum <= 0 then
	    				num = 0
	    			elseif num > self.oilNum then
	    				num	= self.oilNum
	    			end
	    		elseif tag==Const_pb.STEEL then
	    			if num>=retainInput/self.STEELRatio then
	    				num =math.floor(retainInput/self.STEELRatio)
	    			end 
	    			if self.steelNum <= 0 then
	    				num = 0
	    			elseif num > self.steelNum then
	    				num	= self.steelNum		
	    			end
	    		elseif tag==Const_pb.TOMBARTHITE then
	    			if num>=retainInput/self.TOMBARTHITERatio then
	    				num = math.floor(retainInput/self.TOMBARTHITERatio)
	    			end 
	    			if self.rareEarthsNum <= 0 then
	    				num = 0
	    			elseif num > self.rareEarthsNum then
	    				num	= self.rareEarthsNum		
	    			end
	    		end 
	    		
	    		local numStr=Utilitys.formatNumber(num)
	    		node:setText(numStr)
	    		self:refrestWillReceiveResource(num,tag)
	    		--更新商队负重
	    		local curCount=self:getCurTotalAidCount()
	    		self:setBurdenTxt(curCount)

	    		--刷新运输时间
	    		self:refreshAssitanceBtnAndTxt()
	    	end 
        end
    end

    local ttf=UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mSelectGoldNum")
	local fontName=ttf:getFontName()
	local fontSize=ttf:getFontSize()
    -- UIExtend.createEditBox(ccbfile,nodeName,parentNode,editCall,lableStartPos,length,mode,fontSize,fontName,fontColor,lableAlignment)

    local startLabelPos=ccp(0,0)
	local GoldEditBoxPNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mSelectGoldInputNode")
	local size=GoldEditBoxPNode:getContentSize()
	-- GoldEditBoxPNode:removeAllChildren()
	self.GoldEditBox=UIExtend.createEditBox(self.ccbfile,"mSelectGoldBG",GoldEditBoxPNode,
		inputEditboxEventHandler,startLabelPos,nil,kEditBoxInputModeSingleLine,fontSize,fontName,RAGameConfig.COLOR.WHITE,2)
	self.GoldEditBox:setTag(Const_pb.GOLDORE)
	self.GoldEditBox:setText(0)
	self.inputNumsTab[1]=0

	local OilEditBoxPNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mSelectOilInputNode")

	self.OilEditBox=UIExtend.createEditBox(self.ccbfile,"mSelectOilBG",OilEditBoxPNode,
		inputEditboxEventHandler,startLabelPos,nil,kEditBoxInputModeSingleLine,fontSize,fontName,RAGameConfig.COLOR.WHITE,2)
	self.OilEditBox:setTag(Const_pb.OIL)
	self.OilEditBox:setText(0)
	self.inputNumsTab[2]=0

	local SteelEditBoxPNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mSelectSteelInputNode")
	self.SteelEditBox=UIExtend.createEditBox(self.ccbfile,"mSelectSteelBG",SteelEditBoxPNode,
		inputEditboxEventHandler,startLabelPos,nil,kEditBoxInputModeSingleLine,fontSize,fontName,RAGameConfig.COLOR.WHITE,2)
	self.SteelEditBox:setTag(Const_pb.STEEL)
	self.SteelEditBox:setText(0)
	self.inputNumsTab[3]=0

	local RareEarthsEditBoxPNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mSelectRareEarthsInputNode")
	self.RareEarthsEditBox=UIExtend.createEditBox(self.ccbfile,"mSelectRareEarthsBG",RareEarthsEditBoxPNode,
		inputEditboxEventHandler,startLabelPos,nil,kEditBoxInputModeSingleLine,fontSize,fontName,RAGameConfig.COLOR.WHITE,2)
	self.RareEarthsEditBox:setTag(Const_pb.TOMBARTHITE)
	self.RareEarthsEditBox:setText(0)
	self.inputNumsTab[4]=0


	UIExtend.setNodeVisible(self.ccbfile,"mSelectGoldNum",false)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectOilNum",false)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectSteelNum",false)
	UIExtend.setNodeVisible(self.ccbfile,"mSelectRareEarthsNum",false)
end

function RAWorldResourceAidPage:setResourceCount(num,rescourceType)
	local numStr=RALogicUtil:num2k(tonumber(num))
	if resourceType==Const_pb.GOLDORE then
		UIExtend.setCCLabelString(self.ccbfile,"mSelectGoldNum",numStr)
	elseif resourceType==Const_pb.OIL then
		UIExtend.setCCLabelString(self.ccbfile,"mSelectOilNum",numStr)
	elseif resourceType==Const_pb.STEEL then
		UIExtend.setCCLabelString(self.ccbfile,"mSelectSteelNum",numStr)
	elseif resourceType==Const_pb.TOMBARTHITE then

		UIExtend.setCCLabelString(self.ccbfile,"mSelectRareEarthsNum",numStr)
	end 
end

--计算当前即将运输的资源总数
function RAWorldResourceAidPage:getCurTotalAidCount()
	local num1=self.inputNumsTab[1]*self.GOLDORERatio
	local num2=self.inputNumsTab[2]*self.OILRatio
	local num3=self.inputNumsTab[3]*self.STEELRatio
	local num4=self.inputNumsTab[4]*self.TOMBARTHITERatio
	return num1+num2+num3+num4
end

--计算剩余可以运输资源的总数
function RAWorldResourceAidPage:getRetainAidCount()
	local canAidCount=self.marketBurden
	local curAidCount=self:getCurTotalAidCount()
	local retainCount=canAidCount-curAidCount
	return retainCount

end

function RAWorldResourceAidPage:setBurdenTxt(curCount)
	curCount=math.min(curCount,self.marketBurden)
	UIExtend.setCCLabelString(self.ccbfile,"mLoadNum",_RALang("@Burden",curCount,self.marketBurden))
end

function RAWorldResourceAidPage:initTaxAndBurden()
	--拿到市场的等级

	local arr=RABuildManager:getBuildDataArray(Const_pb.TRADE_CENTRE)
	local tradeCenterLevel=0
	if next(arr) then
		local buildData=arr[1]
		tradeCenterLevel=buildData:getLevel()
	end 

	local buildData=RABuildingUtility:getBuildInfoByLevel(Const_pb.TRADE_CENTRE,tradeCenterLevel)

	--加上作用号的影响
	local RABuildEffect=RARequire("RABuildEffect")
	local marketBurden= RABuildEffect:getValueByEffect(buildData.marketBurden,Const_pb.TRADE_CENTRE,"marketBurden")
	local marketTax=buildData.marketTax
	self.marketTax=marketTax/100

	self.marketBurden=tonumber(marketBurden)

	-- local curTotal=self:getCurTotalAidCount()
	UIExtend.setCCLabelString(self.ccbfile,"mTariffNum",_RALang("@Tax",marketTax))
	self:setBurdenTxt(0)
end

function RAWorldResourceAidPage:refrestWillReceiveResource(num,resourceType)
	num=tonumber(num)
	num=num*(1-self.marketTax)
	local numStr=RALogicUtil:num2k(tonumber(num))
	
	if resourceType==Const_pb.GOLDORE then
		self.GoldControlSlider:setValue(tonumber(num))
		UIExtend.setCCLabelString(self.ccbfile,"mAidGoldNum",numStr)
	elseif resourceType==Const_pb.OIL then
		self.OilControlSlider:setValue(tonumber(num))
		UIExtend.setCCLabelString(self.ccbfile,"mAidOilNum",numStr)
	elseif resourceType==Const_pb.STEEL then
		self.SteelControlSlider:setValue(tonumber(num))
		UIExtend.setCCLabelString(self.ccbfile,"mAidSteelNum",numStr)
	elseif resourceType==Const_pb.TOMBARTHITE then
		self.RareEarthsControlSlider:setValue(tonumber(num))
		UIExtend.setCCLabelString(self.ccbfile,"mAidRareEarthsNum",numStr)
	end 
end
function RAWorldResourceAidPage:initWillReceiveResource()
	UIExtend.setCCLabelString(self.ccbfile,"mAidGoldNum",0)
	UIExtend.setCCLabelString(self.ccbfile,"mAidOilNum",0)
	UIExtend.setCCLabelString(self.ccbfile,"mAidSteelNum",0)
	UIExtend.setCCLabelString(self.ccbfile,"mAidRareEarthsNum",0)
end


function RAWorldResourceAidPage:refreshTransportTime()
	--local startPos=RAWorldMath:View2Map(self.startPos)
	--local endPos=RAWorldMath:View2Map(self.endPos)
	local secs=RAMarchDataManager:GetMarchWayTotalTimeForResAssistant(self.startPos,self.endPos)
	UIExtend.setCCLabelString(self.ccbfile,"mTransportTimeLabel",_RALang("@TransportTime",Utilitys.createTimeWithFormat(secs)))
end

function RAWorldResourceAidPage:refreshAssitanceBtnAndTxt()
	local curAidCount=self:getCurTotalAidCount()
	local isOk=false
	if curAidCount>0 then
		isOk=true
		self:refreshTransportTime()
	else	
		UIExtend.setCCLabelString(self.ccbfile,"mTransportTimeLabel",_RALang("@TransportTime","00:00:00"))
	end 
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mAssistanceBtn",isOk)
end
function RAWorldResourceAidPage:initAssitanceBtnAndTxt()
	
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mAssistanceBtn",false)
	UIExtend.setCCLabelString(self.ccbfile,"mTransportTimeLabel",_RALang("@TransportTime","00:00:00"))
end
function RAWorldResourceAidPage:init()	
	UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle",_RALang("@AssistanceResTiltle"))

	self:initCanAidResource()
	self:initEditBoxUI()
	self:initSliderUI()
	self:initTaxAndBurden()
	self:initWillReceiveResource()
	self:initAssitanceBtnAndTxt()
end



function RAWorldResourceAidPage:Exit()
	if self.GoldControlSlider then
        self.GoldControlSlider:unregisterScriptSliderHandler()
        self.GoldControlSlider = nil
    end
    if self.OilControlSlider then
    	self.OilControlSlider:unregisterScriptSliderHandler()
    	self.OilControlSlider = nil
    end
    if self.SteelControlSlider then
    	self.SteelControlSlider:unregisterScriptSliderHandler()
    	self.SteelControlSlider = nil
    end
    if self.RareEarthsControlSlider then
    	self.RareEarthsControlSlider:unregisterScriptSliderHandler()
    	self.RareEarthsControlSlider = nil
    end
    if self.GoldEditBox then
    	self.GoldEditBox:removeFromParentAndCleanup(true)
    	self.GoldEditBox = nil
    end
    if self.OilEditBox then
    	self.OilEditBox:removeFromParentAndCleanup(true)
    	self.OilEditBox = nil
    end
    if self.SteelEditBox then
    	self.SteelEditBox:removeFromParentAndCleanup(true)
    	self.SteelEditBox = nil
    end
    if self.RareEarthsEditBox then
    	self.RareEarthsEditBox:removeFromParentAndCleanup(true)
    	self.RareEarthsEditBox = nil
    end
	self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
	self.targetLevel=nil
	self.startPos=nil
	self.endPos=nil
	UIExtend.unLoadCCBFile(RAWorldResourceAidPage)
end

function RAWorldResourceAidPage:onClose()
	RARootManager.CloseAllPages()
end

function RAWorldResourceAidPage:onAssistanceBtn()
 	local RAWorldPushHandler = RARequire('RAWorldPushHandler')
    local World_pb = RARequire('World_pb')

    local playerAttr=Const_pb.PLAYER_ATTR*10000

	local goldoreNum=self.inputNumsTab[1]
	local oilNum=self.inputNumsTab[2]
	local steelNum=self.inputNumsTab[3]
	local tomabarthiteNum=self.inputNumsTab[4]


    local params={}
    local t={}
    t[Const_pb.GOLDORE]={itemCount=goldoreNum,itemType=playerAttr}
    t[Const_pb.OIL]={itemCount=oilNum,itemType=playerAttr}
    t[Const_pb.STEEL]={itemCount=steelNum,itemType=playerAttr}
    t[Const_pb.TOMBARTHITE]={itemCount=tomabarthiteNum,itemType=playerAttr}

    params.assistant=t

    RAWorldPushHandler:sendWorldMarchReq(World_pb.ASSISTANCE_RES, self.endPos, {},params)

    self:onClose()
end

--endregion
