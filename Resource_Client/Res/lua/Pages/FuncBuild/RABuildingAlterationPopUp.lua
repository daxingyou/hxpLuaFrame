--改造建筑弹出页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RABuildManager = RARequire("RABuildManager")
local Const_pb = RARequire("Const_pb")

local RABuildingAlterationPopUp = BaseFunctionPage:new(...)

local controlButtonSelected = 1

function RABuildingAlterationPopUp:Enter(data)
	
	self.buildData = data.buildData
	self.curBuildData = self.buildData.confData
	
	if self.curBuildData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 (防御建筑除了自己之外只有2个)
		UIExtend.loadCCBFile("RABuildingAlterationPopUp2.ccbi",self)
		for i=1,2 do
			UIExtend.setNodeVisible(self.ccbfile,"mFrameNode"..i,false)
		end
	else
		UIExtend.loadCCBFile("RABuildingAlterationPopUp.ccbi",self)	
		for i=1,4 do
		 	UIExtend.setNodeVisible(self.ccbfile,"mFrameNode"..i,false)
		 end
	end

	self:refreshUI()
end

function RABuildingAlterationPopUp:refreshUI()
	 UIExtend.setCCLabelString(self.ccbfile,"mTitle", _RALang("@ReBuildTitle"))
	 --default set node visible false
	 
	 UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn"..controlButtonSelected,false)
	 controlButtonSelected = 1
	 UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn1",true)

	 self.buildDataTable = {}
	 --
	 local rebuildGroupTable = Utilitys.Split(self.curBuildData.rebuildGroup, "_")
	 local index = 0
	 for i=1,#rebuildGroupTable do
	 	local buildType = tonumber(rebuildGroupTable[i])
	 	if buildType ~= self.curBuildData.buildType then
	 		index = index + 1
	 		local buildData = RABuildingUtility:getBuildInfoByLevel(buildType,1)
	 		local hasFrondBuild = RABuildManager:isBuildCanCreateByFrontBuild(buildData.frontBuild)

	 		UIExtend.setCCLabelString(self.ccbfile,"mIconName"..index, _RALang(buildData.buildName))

	 		local soldierConf = RABuildingUtility:getDefenceBuildConfById(buildData.id)
            if soldierConf then --防御建筑
            	UIExtend.setCCLabelString(self.ccbfile,"mFunLabel"..index,_RALang("@Refrain",_RALang(soldierConf.subdue)))
        	else	--资源建筑
        		UIExtend.setCCLabelString(self.ccbfile,"mFunLabel"..index,_RALang("@OutPut",_RALang(buildData.rebuildResourceType)))
        	end

        	--UIExtend.removeSpriteFromNodeParent(self.ccbfile, 'mIconNode')
        	UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode"..index, buildData.buildArtImg)

	 		local mainNode = self.ccbfile:getCCNodeFromCCB("mFrameNode"..index)
	 		if hasFrondBuild then
	            UIExtend.setNodeVisible(self.ccbfile,"mLockNode"..index,false)
	            UIExtend.setCCControlButtonEnable(self.ccbfile,"mFrameBtn"..index,true)
	            mainNode:setVisible(true)
	        else
	        	UIExtend.setNodeVisible(self.ccbfile,"mLockNode"..index,true)	
	        	UIExtend.setCCControlButtonEnable(self.ccbfile,"mFrameBtn"..index,false)
		        local grayTag = 10000+index
		        mainNode:getParent():removeChildByTag(grayTag,true)

	        	local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
	            graySprite:setTag(grayTag)
	            graySprite:setPosition(mainNode:getPosition())
	            graySprite:setAnchorPoint(mainNode:getAnchorPoint())
	            mainNode:getParent():addChild(graySprite)
	            mainNode:setVisible(true)
	 		end

            self.buildDataTable[index] = buildData
	 	end	
	 end
end

function RABuildingAlterationPopUp:onFrameBtn1()
	-- body
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn"..controlButtonSelected,false)
	controlButtonSelected = 1
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn1",true)

	local buildData = self.buildDataTable[controlButtonSelected]

	RARootManager.OpenPage("RABuildingAlterationPage",{currBuildData = self.buildData,reBuildData = buildData},false, true, true)
end

function RABuildingAlterationPopUp:onFrameBtn2()
	-- body
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn"..controlButtonSelected,false)
	controlButtonSelected = 2
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn2",true)

	local buildData = self.buildDataTable[controlButtonSelected]

	RARootManager.OpenPage("RABuildingAlterationPage",{currBuildData = self.buildData,reBuildData = buildData},false, true, true)
end

function RABuildingAlterationPopUp:onFrameBtn3()
	-- body
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn"..controlButtonSelected,false)
	controlButtonSelected = 3
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn3",true)

	local buildData = self.buildDataTable[controlButtonSelected]

	RARootManager.OpenPage("RABuildingAlterationPage",{currBuildData = self.buildData,reBuildData = buildData},false, true, true)
end

function RABuildingAlterationPopUp:onFrameBtn4()
	-- body
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn"..controlButtonSelected,false)
	controlButtonSelected = 4
	UIExtend.setCCControlButtonSelected(self.ccbfile,"mFrameBtn4",true)

	local buildData = self.buildDataTable[controlButtonSelected]

	RARootManager.OpenPage("RABuildingAlterationPage",{currBuildData = self.buildData,reBuildData = buildData},false, true, true)
end

function RABuildingAlterationPopUp:onClose()
	-- body
	RARootManager.CloseCurrPage()
end

function RABuildingAlterationPopUp:Exit()
	-- body
	self.buildData = nil
	self.curBuildData = nil

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RABuildingAlterationPopUp