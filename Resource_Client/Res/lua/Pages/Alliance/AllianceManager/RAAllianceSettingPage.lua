--to:联盟设置页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire("RAAllianceManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RANetUtil = RARequire("RANetUtil")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local guild_const_conf = RARequire("guild_const_conf")
local GuildManager_pb = RARequire("GuildManager_pb")
local RAStringUtil = RARequire('RAStringUtil')

local RAAllianceSettingPage = BaseFunctionPage:new(...)

--
local RAAllianceSettingEditDecCell = {}     --修改联盟宣言
local RAAllianceSettingRecruitCell = {}     --修改联盟公开招募  --"RAAllianceSettingRecruitCell2",
local RAAllianceSettingModifyNameCell = {}  --修改联盟名称
local RAAllianceSettingModifyShortCell = {} --修改联盟简称
local RAAllianceSettingLangCell = {}        --修改联盟语音
local RAAllianceSettingTitleCell = {}       --修改联盟阶级与称谓
local RAAllianceSettingTypeCell = {}        --修改联盟类型
--

function RAAllianceSettingEditDecCell.getCcbiFileName()
    return "RAAllianceSettingEditDecCell.ccbi"
end
function RAAllianceSettingEditDecCell.getCellName()
    return "RAAllianceSettingEditDecTxt"
end

function RAAllianceSettingRecruitCell.getCcbiFileName()
    return "RAAllianceSettingRecruitCell1.ccbi"
end
function RAAllianceSettingRecruitCell.getCellName()
    return "RAAllianceSettingRecruitTxt"
end

function RAAllianceSettingModifyNameCell.getCcbiFileName()
    return "RAAllianceSettingModifyCell.ccbi"
end
function RAAllianceSettingModifyNameCell.getCellName()
    return "RAAllianceSettingModifyNameTxt"
end

function RAAllianceSettingModifyShortCell.getCcbiFileName()
    return "RAAllianceSettingModifyCell.ccbi"
end
function RAAllianceSettingModifyShortCell.getCellName()
    return "RAAllianceSettingModifyShortTxt"
end

function RAAllianceSettingLangCell.getCcbiFileName()
    return "RAAllianceSettingLangCell.ccbi"
end
function RAAllianceSettingLangCell.getCellName()
    return "RAAllianceSettingLangTxt"
end

function RAAllianceSettingTitleCell.getCcbiFileName()
    return "RAAllianceSettingTitleCell.ccbi"
end
function RAAllianceSettingTitleCell.getCellName()
    return "RAAllianceSettingTitleTxt"
end
function RAAllianceSettingTypeCell.getCcbiFileName()
    return "RAAllianceSettingTypeCell.ccbi"
end
function RAAllianceSettingTypeCell.getCellName()
    return "AllianceChangeTypeTitle"
end

local subCell = {}

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

function RAAllianceSettingPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RAAllianceSettingPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mCreeateListSV")

    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.allianceInfo = RAAllianceManager.selfAlliance
    
    self:initTopTitle()

    self.isKeyboardShow = false
    self:registerMessage()

    self:initCellList()

    self:addCell()
    self:initTouchLayer()
end

function RAAllianceSettingPage:initTouchLayer()
   
    local callback = function(pEvent, pTouch)
        CCLuaLog("event name:"..pEvent)
        if pEvent == "began" then
            return self.isKeyboardShow
        end
        if pEvent == "ended" then
            if self.editBox ~= nil then 
                self.editBox:closeKeyboard()
                self.editBox = nil 
            end 
            
            -- if not isInside then 
            --     -- CCLuaLog('关闭键盘')
            --     self.editBox:closeKeyboard()
            -- end 
        end
    end

    layer = CCLayer:create()
    layer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    layer:setPosition(0, 0)
    layer:setAnchorPoint(ccp(0, 0))
    layer:setTouchEnabled(true)
    layer:setTouchMode(kCCTouchesOneByOne)
    self:getRootNode():addChild(layer)
    layer:registerScriptTouchHandler(callback,false, -2147483645 ,true)
 
    self.mLayer = layer
end

function RAAllianceSettingPage:initCellList()
    
    self.authority = RAAllianceManager.authority or 1

    local alliance_authority_conf = RARequire("alliance_authority_conf")
    local alliance_authority = alliance_authority_conf[self.authority]

	local cellSize = 0

    if alliance_authority.edit_alliance_announcement == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingEditDecCell
    end    
    if alliance_authority.edit_public_recruit == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingRecruitCell

        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingTypeCell
    end
    if alliance_authority.edit_alliance_name == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingModifyNameCell
    end
    if alliance_authority.edit_alliance_shortname == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingModifyShortCell
    end
    if alliance_authority.edit_alliance_language == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingLangCell
    end
    if alliance_authority.edit_member_level_name == 1 then
        cellSize = cellSize + 1
        subCell[cellSize] = RAAllianceSettingTitleCell
    end
end

--初始化顶部
function RAAllianceSettingPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceSettingTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

function RAAllianceSettingPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end


------------------------------------------------------------------------------------------------
-----联盟设置cell中的cell to 修改联盟宣言
------------------------------------------------------------------------------------------------
local editBoxTag = false

function RAAllianceSettingEditDecCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingEditDecCell:onEditBtn()
    -- body
    if editBoxTag then
        editBoxTag = false
        UIExtend.setControlButtonTitle(RAAllianceSettingEditDecCell.ccbfile, "mEditBtn","@Edit")
        RAAllianceProtoManager:postAnnouncement(RAAllianceSettingEditDecCell.DecString)
    else
        self.editBox:clickShowInput()
    end    
end

function RAAllianceSettingEditDecCell.editboxEventHandler(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
         local valueText = node:getText()
         if RAAllianceSettingEditDecCell.DecString ~= valueText then
             editBoxTag = true
             UIExtend.setControlButtonTitle(RAAllianceSettingEditDecCell.ccbfile, "mEditBtn","@Save")
         end
    elseif eventType == 'ended' then
        local valueText = node:getText()
        if RAAllianceSettingEditDecCell.DecString ~= valueText then
            RAAllianceSettingEditDecCell.DecString = RAStringUtil:replaceToStarForChat(valueText) 
            RAAllianceSettingEditDecCell.editBox:setText(RAAllianceSettingEditDecCell.DecString)
        end 
    end
end

function RAAllianceSettingEditDecCell:onRefreshContent(ccbRoot)
	-- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingEditDecCell.ccbfile = ccbfile
    local inputNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputNode")
    local editBox = UIExtend.createEditBox(ccbfile,"mInputBG",inputNode,RAAllianceSettingEditDecCell.editboxEventHandler,nil,nil,nil,24,nil,RAGameConfig.COLOR.WHITE)
    RAAllianceSettingEditDecCell.editBox = editBox
    RAAllianceSettingEditDecCell.DecString = RAAllianceSettingPage.allianceInfo.announcement
    RAAllianceSettingEditDecCell.editBox:setText(RAAllianceSettingEditDecCell.DecString)
    UIExtend.setControlButtonTitle(ccbfile, "mEditBtn","@Edit")
end

function RAAllianceSettingEditDecCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)	
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
    RAAllianceSettingEditDecCell.editBox:removeFromParentAndCleanup(true)
    RAAllianceSettingEditDecCell.editBox = nil
    RAAllianceSettingEditDecCell.DecString = ""
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改公开招募 RAAllianceSettingRecruitCell 是默认关闭的
------------------------------------------------------------------------------------------------
local isOpenRecruit = false

function RAAllianceSettingRecruitCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingRecruitCell.editboxEventHandler1(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
        local valueText = node:getText()
        if RAAllianceSettingRecruitCell.needBuildingLevel ~= valueText then
            RAAllianceSettingRecruitCell.needBuildingLevel = valueText 
            if RAAllianceSettingRecruitCell.needBuildingLevel == "" then
                RAAllianceSettingRecruitCell.needBuildingLevel = 0
            end
            if tonumber(RAAllianceSettingRecruitCell.needBuildingLevel) > 30 then
                RAAllianceSettingRecruitCell.needBuildingLevel = 30
            end
            --
        else
            --todo 名字没有改变则提示告诉 待确认
        end  
    elseif eventType == 'ended' then
       node:setText(tonumber(RAAllianceSettingRecruitCell.needBuildingLevel))       
    end
end

function RAAllianceSettingRecruitCell.editboxEventHandler2(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
        local valueText = node:getText()
        if RAAllianceSettingRecruitCell.needPower ~= valueText then
            RAAllianceSettingRecruitCell.needPower = RAStringUtil:replaceToStarForChat(valueText) 
            if RAAllianceSettingRecruitCell.needPower == "" then
                RAAllianceSettingRecruitCell.needPower = 0
            end
            --
        else
            --todo 名字没有改变则提示告诉 待确认
        end  
    elseif eventType == 'ended' then
        if tonumber(RAAllianceSettingRecruitCell.needPower) > 2100000000 then
            RAAllianceSettingRecruitCell.needPower = 2100000000
        end
        node:setText(tonumber(RAAllianceSettingRecruitCell.needPower))  
    end
end
function RAAllianceSettingRecruitCell.editboxEventHandler3(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
        local valueText = node:getText()
        if RAAllianceSettingRecruitCell.needCommonderLevel ~= valueText then
            RAAllianceSettingRecruitCell.needCommonderLevel = valueText
            if RAAllianceSettingRecruitCell.needCommonderLevel == "" then
                RAAllianceSettingRecruitCell.needCommonderLevel = 0
            end
            if tonumber(RAAllianceSettingRecruitCell.needCommonderLevel) > 50 then
                RAAllianceSettingRecruitCell.needCommonderLevel = 50
            end
            --
        else
            --todo 名字没有改变则提示告诉 待确认
        end
    elseif eventType == 'ended' then
       node:setText(tonumber(RAAllianceSettingRecruitCell.needCommonderLevel))      
    end
end

function RAAllianceSettingRecruitCell:onSelectLangBtn()
    RARootManager.OpenPage("RAAllianceSettingLangPopUp",{needLanguage = RAAllianceSettingRecruitCell.needLanguage},false,true,true)
end

function RAAllianceSettingRecruitCell:onTypeChange()
    -- CCLuaLog('onTypeChange')
    RARootManager.OpenPage("RAAllianceChangeTypePage",{settingCell = self},false,true,true)
end

function RAAllianceSettingRecruitCell:refreshAllianceType()
    RAAllianceSettingRecruitCell.allianceType = RAAllianceManager.selfAlliance.guildType

    RAAllianceSettingRecruitCell.mWarType = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mWarType')
    RAAllianceSettingRecruitCell.mWarType:setString(RAAllianceUtility:getAllianceTypeName(RAAllianceSettingRecruitCell.allianceType))
end 

function RAAllianceSettingRecruitCell:onRefreshContent(ccbRoot)
    -- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    if RAAllianceSettingRecruitCell.isOpen then

        RAAllianceSettingRecruitCell.ccbfile = ccbfile
        
        --RAAllianceSettingRecruitCell.allianceType = RAAllianceManager.selfAlliance.guildType

        --RAAllianceSettingRecruitCell.mWarType = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mWarType')
        --RAAllianceSettingRecruitCell.mWarType:setString(RAAllianceUtility:getAllianceTypeName(RAAllianceSettingRecruitCell.allianceType))

        --隐藏语言修改
        local languageNode = UIExtend.getCCNodeFromCCB(ccbfile,"mLanguageNode")
        languageNode:setVisible(false)

        --初始化5个editbox
        local inputNode1 = UIExtend.getCCNodeFromCCB(ccbfile,"mInputHeadquartersNode")
        local inputNode2 = UIExtend.getCCNodeFromCCB(ccbfile,"mInputFightValueNode")
        local inputNode3 = UIExtend.getCCNodeFromCCB(ccbfile,"mInputCommanderNode")

        local editBox1 = UIExtend.createEditBox(ccbfile,"mInputHeadquartersBG",inputNode1,RAAllianceSettingRecruitCell.editboxEventHandler1,nil,3,kEditBoxInputModeNumeric,24,nil,RAGameConfig.COLOR.WHITE,1)
        RAAllianceSettingRecruitCell.editBox1 = editBox1
        RAAllianceSettingRecruitCell.editBox1:setIsShowTTF(true)
        RAAllianceSettingRecruitCell.needBuildingLevel = RAAllianceSettingPage.allianceInfo.needBuildingLevel
        RAAllianceSettingRecruitCell.editBox1:setText(RAAllianceSettingRecruitCell.needBuildingLevel)

        local editBox2 = UIExtend.createEditBox(ccbfile,"mInputFightValueBG",inputNode2,RAAllianceSettingRecruitCell.editboxEventHandler2,nil,10,kEditBoxInputModeNumeric,24,nil,RAGameConfig.COLOR.WHITE,1)
        RAAllianceSettingRecruitCell.editBox2 = editBox2
        RAAllianceSettingRecruitCell.editBox2:setIsShowTTF(true)
        RAAllianceSettingRecruitCell.needPower = RAAllianceSettingPage.allianceInfo.needPower
        RAAllianceSettingRecruitCell.editBox2:setText(RAAllianceSettingRecruitCell.needPower)

        local editBox3 = UIExtend.createEditBox(ccbfile,"mInputCmdrBG",inputNode3,RAAllianceSettingRecruitCell.editboxEventHandler3,nil,3,kEditBoxInputModeNumeric,24,nil,RAGameConfig.COLOR.WHITE,1)
        RAAllianceSettingRecruitCell.editBox3 = editBox3
        RAAllianceSettingRecruitCell.editBox3:setIsShowTTF(true)
        RAAllianceSettingRecruitCell.needCommonderLevel = RAAllianceSettingPage.allianceInfo.needCommonderLevel
        RAAllianceSettingRecruitCell.editBox3:setText(RAAllianceSettingRecruitCell.needCommonderLevel)

        RAAllianceSettingRecruitCell.needLanguage = RAAllianceSettingPage.allianceInfo.needLanguage
        local needLanguageString = RAAllianceUtility:getLanguageIdByName(RAAllianceSettingRecruitCell.needLanguage)
        UIExtend.setStringForLabel(ccbfile,{mLanguage = needLanguageString})
    end
end

--保存公开招募条件
function RAAllianceSettingRecruitCell:onSaveBtn()
    --发送关闭协议
    local buildingLevel = tonumber(RAAllianceSettingRecruitCell.needBuildingLevel or 0)
    local power = tonumber(RAAllianceSettingRecruitCell.needPower or 0)
    local commonderLevel = tonumber(RAAllianceSettingRecruitCell.needCommonderLevel or 0)
    local needLanguage = "all"--RAAllianceSettingRecruitCell.needLanguage or "all"

    RAAllianceProtoManager:changeGuildApplyPermiton(RAAllianceSettingRecruitCell.isOpen,buildingLevel,power,commonderLevel,needLanguage)
end

function RAAllianceSettingRecruitCell:refreshCells(ccbiFile)
    self:restData()
    local index = self.mIndex
    local cell = CCBFileCell:create()
    cell:setCCBFile(ccbiFile)--"RAAllianceSettingRecruitCell2.ccbi")
    local panel = subCell[index]:new({
        mCell = cell
    })
    cell:setZOrder(99)
    cell:registerFunctionHandler(panel)
    subCell[index] = panel
    RAAllianceSettingPage.scrollView:addCell(cell,index)  
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
end

--打开公开招募
function RAAllianceSettingRecruitCell:onOpenRecruitBtn()
    RAAllianceSettingRecruitCell.isOpen = true
    isOpenRecruit = false

    --打开
    self:onSaveBtn()

    --这里需要延迟0.05秒调用,否则快速点击CCControl 时 在CCControl:sendActionsForControlEvents 出现崩溃
    local delayFunc = function ()
		self:refreshCells("RAAllianceSettingRecruitCell2.ccbi")
	end
	performWithDelay(RAAllianceSettingPage.ccbfile, delayFunc, 0.05)
end

--关闭公开招募
function RAAllianceSettingRecruitCell:onCloseRecruitBtn()
    RAAllianceSettingRecruitCell.isOpen = false
    isOpenRecruit = true

    --发送关闭协议
    RAAllianceProtoManager:changeGuildApplyPermiton(RAAllianceSettingRecruitCell.isOpen)

    --这里需要延迟0.05秒调用,否则快速点击CCControl 时 在CCControl:sendActionsForControlEvents 出现崩溃
    local delayFunc = function ()
		self:refreshCells("RAAllianceSettingRecruitCell1.ccbi")
	end
	performWithDelay(RAAllianceSettingPage.ccbfile, delayFunc, 0.05)
end

function RAAllianceSettingRecruitCell:restData()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)
    if isOpenRecruit then
        RAAllianceSettingRecruitCell.editBox1:removeFromParentAndCleanup(true)
        RAAllianceSettingRecruitCell.editBox1 = nil
        RAAllianceSettingRecruitCell.needBuildingLevel = nil

        RAAllianceSettingRecruitCell.editBox2:removeFromParentAndCleanup(true)
        RAAllianceSettingRecruitCell.editBox2 = nil
        RAAllianceSettingRecruitCell.needPower = nil

        RAAllianceSettingRecruitCell.editBox3:removeFromParentAndCleanup(true)
        RAAllianceSettingRecruitCell.editBox3 = nil
        RAAllianceSettingRecruitCell.needCommonderLevel = nil

        RAAllianceSettingRecruitCell.needLanguage = nil  
    end
end

function RAAllianceSettingRecruitCell:Exit(isOrder)
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)
    RAAllianceSettingPage.scrollView:orderCCBFileCells()

    isOpenRecruit = RAAllianceSettingRecruitCell.isOpen
    self:restData()
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改联盟名称
------------------------------------------------------------------------------------------------

function RAAllianceSettingModifyNameCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingModifyNameCell:onOpenRecruitBtn()
    -- body
    

    local result = RAAllianceUtility:checkAllianceName(RAAllianceSettingModifyNameCell.DecString)
    local isNameOK = false
    if result == 0 then 
        isNameOK = true
    else 
        isNameOK = false 

        if result == -1 then 
            result = _RALang('@AllianceNameLenError')
        elseif result == -2 then 
            result = _RALang('@AllianceNameContentError')
        elseif result == -3 then 
            result = _RALang('@AllianceNameBlockError')
        end 
    end 

    if isNameOK then
        RAAllianceProtoManager:changeGuildName(RAAllianceSettingModifyNameCell.DecString)  
    else
        RARootManager.ShowMsgBox(result)    
    end
end

function RAAllianceSettingModifyNameCell.editboxEventHandler(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
        local valueText = node:getText()
        if RAAllianceSettingModifyNameCell.DecString ~= valueText then
            RAAllianceSettingModifyNameCell.DecString = RAStringUtil:replaceToStarForChat(valueText) 
            --RAAllianceSettingModifyNameCell.editBox:setText(RAAllianceSettingModifyNameCell.DecString)
        else
            --todo 名字没有改变则提示告诉 待确认
        end
    end        
end

function RAAllianceSettingModifyNameCell:onRefreshContent(ccbRoot)
	-- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingModifyNameCell.ccbfile = ccbfile
    local inputNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputNode")
    local editBox = UIExtend.createEditBox(ccbfile,"mInputBG",inputNode,RAAllianceSettingModifyNameCell.editboxEventHandler,nil,nil,nil,24,nil,RAGameConfig.COLOR.WHITE)
    editBox:setInputMode(kEditBoxInputModeSingleLine)
    editBox:setMaxLength(16)
    RAAllianceSettingModifyNameCell.editBox = editBox
    RAAllianceSettingModifyNameCell.DecString = RAAllianceSettingPage.allianceInfo.name
    RAAllianceSettingModifyNameCell.editBox:setText(RAAllianceSettingModifyNameCell.DecString)

    UIExtend.setControlButtonTitle(ccbfile, "mOpenRecruitBtn", _RALang("@ModifyName"))
    UIExtend.setCCLabelString(ccbfile,'mInputName',_RALang("@InputNewAllianceName"))

    local changeGuildNameGold = guild_const_conf.changeGuildNameGold.value
    UIExtend.setCCLabelString(ccbfile,'mNeedDiamondsNum',changeGuildNameGold)

    UIExtend.setCCLabelString(ccbfile,'mModifyExplain',_RALang("@ModifyNameTxt"))
end

function RAAllianceSettingModifyNameCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)	
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
    self.editBox:removeFromParentAndCleanup(true)
    self.editBox = nil
    self.DecString = ""
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改联盟简称
------------------------------------------------------------------------------------------------
function RAAllianceSettingModifyShortCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingModifyShortCell:onOpenRecruitBtn()
    -- body
    RAAllianceProtoManager:changeGuildTag(RAAllianceSettingModifyShortCell.DecString)  
end

function RAAllianceSettingModifyShortCell.editboxEventHandler(eventType, node)
    if eventType == "changed" then
        -- triggered when the edit box text was changed.
        local valueText = node:getText()
        if RAAllianceSettingModifyShortCell.DecString ~= valueText then
            RAAllianceSettingModifyShortCell.DecString = RAStringUtil:replaceToStarForChat(valueText) 
            --RAAllianceSettingModifyShortCell.editBox:setText(RAAllianceSettingModifyShortCell.DecString)
        else
            --todo 名字没有改变则提示告诉 待确认
        end    
    end
end

function RAAllianceSettingModifyShortCell:onRefreshContent(ccbRoot)
	-- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingModifyShortCell.ccbfile = ccbfile
    local inputNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputNode")
    local editBox = UIExtend.createEditBox(ccbfile,"mInputBG",inputNode,RAAllianceSettingModifyShortCell.editboxEventHandler,nil,nil,nil,24,nil,RAGameConfig.COLOR.WHITE)
    editBox:setInputMode(kEditBoxInputModeSingleLine)
    editBox:setMaxLength(4)
    RAAllianceSettingModifyShortCell.editBox = editBox
    RAAllianceSettingModifyShortCell.DecString = RAAllianceSettingPage.allianceInfo.tag
    RAAllianceSettingModifyShortCell.editBox:setText(RAAllianceSettingModifyShortCell.DecString)

    UIExtend.setControlButtonTitle(ccbfile, "mOpenRecruitBtn", _RALang("@ModifyShort"))
    UIExtend.setCCLabelString(ccbfile,'mInputName',_RALang("@InputNewAllianceShort"))

    local changeGuildTagGold = guild_const_conf.changeGuildTagGold.value
    UIExtend.setCCLabelString(ccbfile,'mNeedDiamondsNum',changeGuildTagGold)

    UIExtend.setCCLabelString(ccbfile,'mModifyExplain',_RALang("@ModifyTagTxt"))
end

function RAAllianceSettingModifyShortCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)	
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
    self.editBox:removeFromParentAndCleanup(true)
    self.editBox = nil
    self.DecString = ""
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改联盟语言
------------------------------------------------------------------------------------------------
function RAAllianceSettingLangCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingLangCell:onRefreshContent(ccbRoot)
    -- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingLangCell.ccbfile = ccbfile
    
    --init scorllView
    RAAllianceSettingLangCell.scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mLanguageListSV")

    local alliance_language_conf = RARequire("alliance_language_conf")
    local list ={}
    for k,v in pairs(alliance_language_conf) do
        local languageInfo = {}
        languageInfo.languageId = v.id
        languageInfo.order = v.order
        list[#list + 1] = languageInfo
    end
    table.sort(list,function(e1,e2) 
        return e1.order < e2.order
    end)
    RAAllianceSettingLangCell:addCell(list)
end

---
local RAAllianceSettingLangCell2 = {}
local currSelectCcb = nil
local currLanguage = ""

function RAAllianceSettingLangCell2:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingLangCell2:onSelectLangBtn()
    -- body
    local mLanguageId = self.mLanguageId
    local ccbfile = self.mCell:getCCBFileNode() 
    if currSelectCcb then
        UIExtend.getCCSpriteFromCCB(currSelectCcb,"mSelectPic"):setVisible(false) 
    end    
    currSelectCcb = ccbfile
    currLanguage = mLanguageId
    UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(true)
    
    --发送协议
    RAAllianceProtoManager:changeGuildLang(currLanguage)
end

function RAAllianceSettingLangCell2:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local mLanguageId = self.mLanguageId
    local data = self.mData
    
    if currLanguage == "" then
        currLanguage = RAAllianceSettingPage.allianceInfo.language
    end
    if currLanguage == mLanguageId then
        currSelectCcb = ccbfile
        UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(true)
    else
        UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(false)    
    end 
    local languageName = RAAllianceUtility:getLanguageIdByName(data.languageId)
    UIExtend.setCCLabelString(ccbfile,'mLanguage',languageName)
end

function RAAllianceSettingLangCell:addCell(data)
    RAAllianceSettingLangCell.scrollView:removeAllCell()
    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAAllianceSettingLangCell2.ccbi")
        local panel = RAAllianceSettingLangCell2:new({
                mLanguageId = v.languageId,
                mData  = v,
                mCell = cell
        })
        cell:setZOrder(999)
        cell:registerFunctionHandler(panel)
        RAAllianceSettingLangCell.scrollView:addCell(cell)
    end
    RAAllianceSettingLangCell.scrollView:orderCCBFileCells()
end

function RAAllianceSettingLangCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)	
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
    currSelectCcb = nil
    currLanguage = ""
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改联盟阶级与称谓
------------------------------------------------------------------------------------------------

function RAAllianceSettingTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingTitleCell:stringResult(result)
    local isSave = true
    local errorTxt = ""
    if result ~= 0 then
        isSave = false
    end
    if result == -1 then 
        errorTxt = _RALang('@AllianceTitleLenError')
    elseif result == -2 then 
        errorTxt = _RALang('@AllianceTitleContentError')
    elseif result == -3 then 
        errorTxt = _RALang('@AllianceTitleBlockError')
    end
    return isSave,errorTxt
end

--确认修改
function RAAllianceSettingTitleCell:onSaveBtn()
    -- body
    local L1Name = RAAllianceSettingTitleCell.editBox1:getText() or ""
    local L2Name = RAAllianceSettingTitleCell.editBox2:getText() or ""
    local L3Name = RAAllianceSettingTitleCell.editBox3:getText() or ""
    local L4Name = RAAllianceSettingTitleCell.editBox4:getText() or ""
    local L5Name = RAAllianceSettingTitleCell.editBox5:getText() or ""

    local isSave = true
    local errorTxt = ""
    local isNoModificAction = false
    
    local allianceMemberLevelNameLenMax = tonumber(guild_const_conf.allianceMemberLevelNameLenMax.value)

    if L1Name ~= "" and isSave then
        isNoModificAction = true
        local result1 = RAAllianceUtility:checkAllianceString(L1Name,1,allianceMemberLevelNameLenMax)
        isSave,errorTxt = self:stringResult(result1)
    end
    if L2Name ~= "" and isSave then
        isNoModificAction = true
        local result2 = RAAllianceUtility:checkAllianceString(L2Name,1,allianceMemberLevelNameLenMax)
        isSave,errorTxt = self:stringResult(result2)
    end
    if L3Name ~= "" and isSave then
        isNoModificAction = true
        local result3 = RAAllianceUtility:checkAllianceString(L3Name,1,allianceMemberLevelNameLenMax)
        isSave,errorTxt = self:stringResult(result3)
    end
    if L4Name ~= "" and isSave then
        isNoModificAction = true
        local result4 = RAAllianceUtility:checkAllianceString(L4Name,1,allianceMemberLevelNameLenMax)
        isSave,errorTxt = self:stringResult(result4)
    end
    if L5Name ~= "" and isSave then
        isNoModificAction = true
        local result5 = RAAllianceUtility:checkAllianceString(L5Name,1,allianceMemberLevelNameLenMax)
        isSave,errorTxt = self:stringResult(result5)
    end

    if not isNoModificAction then --没有修改
        RARootManager.ShowMsgBox(_RALang("@NoModificAction"))
        return
    end

    if isSave then
        RAAllianceProtoManager:changeLevelName(L1Name,L2Name,L3Name,L4Name,L5Name)
    else
        RARootManager.ShowMsgBox(errorTxt)
    end
end

local function editboxEventHandler(eventType, node)
    --body
    -- CCLuaLog(eventType)
    if eventType == 'began' then
        RAAllianceSettingPage.isKeyboardShow = true
        RAAllianceSettingPage.editBox = node
    elseif eventType == 'ended' or eventType == 'return' then
        local valueText = node:getText()
        valueText = RAStringUtil:replaceToStarForChat(valueText) 
        node:setText(valueText) 
        RAAllianceSettingPage.isKeyboardShow = false
        RAAllianceSettingPage.editBox = nil 
    elseif eventType == 'changed' then
        local valueText = node:getText()
        if string.find(valueText,'\n') ~= nil then 
            valueText = valueText:gsub("\n", "")
            node:setText(valueText) 
            node:closeKeyboard()
            RAAllianceSettingPage.isKeyboardShow = false
            RAAllianceSettingPage.editBox = nil 
        end 
        -- triggered when the edit box text was changed.
    end
end

function RAAllianceSettingTitleCell:onRefreshContent(ccbRoot)
    -- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingTitleCell.ccbfile = ccbfile

    local names = RAAllianceUtility:getDefaultLName()

    for i=1,5 do
        local editBoxObj = {}
        editBoxObj.ccbfile = ccbfile
        editBoxObj.nodeName = "mInputTitleBG" .. i
        editBoxObj.parentNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputTitleNode" .. i)
        editBoxObj.editCall = editboxEventHandler
        editBoxObj.fontSize = 24
        editBoxObj.fontColor = RAGameConfig.COLOR.WHITE
        editBoxObj.lableAlignment = 1
        editBoxObj.closeKeyboardType = kEditBoxCloseKeybroadChat
        RAAllianceSettingTitleCell['editBox' .. i] = UIExtend.createEditBoxEx(editBoxObj)
        RAAllianceSettingTitleCell['L' .. i .. 'Name'] = RAAllianceSettingPage.allianceInfo['L' .. i .. 'Name']
        if RAAllianceSettingTitleCell['L' .. i .. 'Name'] == '' then 
            RAAllianceSettingTitleCell['L' .. i .. 'Name'] = _RALang(names[6-i])
        end 

        RAAllianceSettingTitleCell['editBox' .. i]:setPlaceHolder(RAAllianceSettingTitleCell['L' .. i .. 'Name'])
    end
end

function RAAllianceSettingTitleCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell)	
    RAAllianceSettingPage.scrollView:orderCCBFileCells()

    for i=1,5 do
        self['editBox' .. i]:removeFromParentAndCleanup(true)
        self['editBox' .. i] = nil 
        self['Name' .. i] = ""
    end
end

------------------------------------------------------------------------------------------------
----------------联盟设置cell中的cell to 修改联盟类型
------------------------------------------------------------------------------------------------


function RAAllianceSettingTypeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingTypeCell:onRefreshContent(ccbRoot)
    -- body
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    RAAllianceSettingTypeCell.ccbfile = ccbfile

    RAAllianceSettingTypeCell.allianceType = RAAllianceManager.selfAlliance.guildType

    --local mTitle = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTitle')
    --mTitle:setString(_RALang('@AllianceChangeTypeTitle'))

    local mTypeLabel1 = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTypeLabel1')
    local mTypeLabel2 = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTypeLabel2')
    local mTypeLabel3 = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTypeLabel3')

    mTypeLabel1:setString(_RALang('@AllianceTypeDeveloping'))
    mTypeLabel2:setString(_RALang('@AllianceTypeStrategic'))
    mTypeLabel3:setString(_RALang('@AllianceTypeFighting'))

    RAAllianceSettingTypeCell.mTypeExplain = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTypeExplain')
    --local mTypeInfoExplain = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mTypeExplain2')
    --mTypeInfoExplain:setString(_RALang('@AllianceTypeChangeExplain'))

    RAAllianceSettingTypeCell.selectType = RAAllianceManager.selfAlliance.guildType
    RAAllianceSettingTypeCell.mTypeExplain:setString(_RALang('@AllianceTypeExplain' .. RAAllianceSettingTypeCell.selectType))

    for i=1,3 do
        local selBG = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mTypeHighLight"..i)
        if RAAllianceSettingTypeCell.selectType == i then
            selBG:setVisible(true)
        else
            selBG:setVisible(false)
        end
    end
end

function RAAllianceSettingTypeCell:setSelectType(selectType)
    self.selectType = selectType

    for i=1,3 do
        local selBG = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mTypeHighLight"..i)
        if self.selectType == i then
            selBG:setVisible(true)
        else
            selBG:setVisible(false)
        end
    end

    self.mTypeExplain:setString(_RALang('@AllianceTypeExplain' .. selectType)) 
end

function RAAllianceSettingTypeCell:onTypeBtn1()
    self:setSelectType(GuildManager_pb.DEVELOPING)
end

function RAAllianceSettingTypeCell:onTypeBtn2()
    self:setSelectType(GuildManager_pb.STRATEGIC)
end

function RAAllianceSettingTypeCell:onTypeBtn3()
    self:setSelectType(GuildManager_pb.FIGHTING)
end

--保存
function RAAllianceSettingTypeCell:onConfirmBtn()
    if self.selectType == RAAllianceManager.selfAlliance.guildType then 
        RARootManager.ShowMsgBox("@NoChange")
    else
        RAAllianceSettingTypeCell.selectType = self.selectType
        RAAllianceProtoManager:changeAllianceType(self.selectType)
    end  
end

function RAAllianceSettingTypeCell:Exit()
    RAAllianceSettingPage.scrollView:removeCell(self.mCell) 
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
end

------------------------------------------------------------------------------------------------
-----联盟设置cell
------------------------------------------------------------------------------------------------

local RAAllianceSettingCell = {}
local isAnimationOpen = false
local lastClickRecord = {
    index = 0,  --上次点的是第几个
    ccb = nil --上次点击的ccbi
}

function RAAllianceSettingCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingCell:onRefreshContent(ccbRoot)
	-- body
    local index = self.mTag
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local cellName = subCell[index]:getCellName()

    UIExtend.setCCLabelString(ccbfile,'mSettingCellLabel',_RALang("@"..cellName))
end

local isTouchEnabled = true

function RAAllianceSettingCell:refreshCells(index)
    local cell = CCBFileCell:create()
    local cellStr = subCell[index]:getCcbiFileName()
    local cellName = subCell[index]:getCellName()
    if cellName == "RAAllianceSettingRecruitTxt" then   --修改 公开招募需特殊处理
        if RAAllianceSettingPage.allianceInfo.openRecurit then
            RAAllianceSettingRecruitCell.isOpen = true
            cellStr = "RAAllianceSettingRecruitCell2.ccbi"
        else
            RAAllianceSettingRecruitCell.isOpen = false
        end
    end
	cell:setCCBFile(cellStr)
	local panel = subCell[index]:new({
        mIndex = index,
        mCell = cell
    })
    cell:setZOrder(99)
    cell:registerFunctionHandler(panel)
    subCell[index] = panel

    if cellName == "RAAllianceSettingLangTxt" then
        if not isTouchEnabled then
            isTouchEnabled = true
            RAAllianceSettingPage.scrollView:setTouchEnabled(false)
        end
    else
        if isTouchEnabled then
            isTouchEnabled = false
            RAAllianceSettingPage.scrollView:setTouchEnabled(true)    
        end
    end

	RAAllianceSettingPage.scrollView:addCell(cell,index)
    RAAllianceSettingPage.scrollView:orderCCBFileCells()
end 

--function RAAllianceSettingCell:onUnLoad()
--    UIExtend.unLoadCCBFile(self)
--end

function RAAllianceSettingCell:onAllianceLetterBtn()
	-- body
    local index = self.mTag
	if lastClickRecord.ccb then
		if isAnimationOpen then
            isAnimationOpen = false
			lastClickRecord.ccb:runAnimation("CloseAni")
            if lastClickRecord.index ~= 0 then
	            subCell[lastClickRecord.index]:Exit()
                lastClickRecord.index = 0
            end
		end	
	end	
    
	if not self.mCell then return end
    local ccb = self.mCell:getCCBFileNode()
    if ccb == lastClickRecord.ccb then
        lastClickRecord.ccb = nil
        return
    end
    lastClickRecord.index = index
	lastClickRecord.ccb = ccb
	if not isAnimationOpen then
		isAnimationOpen = true
		ccb:runAnimation("OpenAni")
	else
		isAnimationOpen = false
		ccb:runAnimation("CloseAni")
	end

    --这里需要延迟0.05秒调用,否则快速点击CCControl 时 在CCControl:sendActionsForControlEvents 出现崩溃
    local delayFunc = function ()
        self:refreshCells(index)
    end
    performWithDelay(RAAllianceSettingPage.ccbfile, delayFunc, 0.05)
end

function RAAllianceSettingPage:addCell()
    self.scrollView:removeAllCell()
    for i=1,#subCell do
    	local cell = CCBFileCell:create()
	    cell:setCCBFile("RAAllianceSettingCell.ccbi")
	    local panel = RAAllianceSettingCell:new({
                mTag   = i,
                mCell = cell
        })
        cell:setZOrder(999)
        cell:registerFunctionHandler(panel)
	    self.scrollView:addCell(cell)
    end
    --self.scrollView:setTouchEnabled(false)
    self.scrollView:orderCCBFileCells()
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C then --联盟宣言
            editBoxTag = false
            UIExtend.setControlButtonTitle(RAAllianceSettingEditDecCell.ccbfile, "mEditBtn","@Edit")
            RAAllianceSettingPage.allianceInfo.announcement = RAAllianceSettingEditDecCell.DecString
            --MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGEAPPLYPERMITON_C then  --公开招募
            RAAllianceSettingPage.allianceInfo.openRecurit = RAAllianceSettingRecruitCell.isOpen
            if RAAllianceSettingPage.allianceInfo.openRecurit then
                RAAllianceSettingPage.allianceInfo.needBuildingLevel = RAAllianceSettingRecruitCell.needBuildingLevel
                RAAllianceSettingPage.allianceInfo.needCommonderLevel = RAAllianceSettingRecruitCell.needCommonderLevel
                RAAllianceSettingPage.allianceInfo.needPower = RAAllianceSettingRecruitCell.needPower
                RAAllianceSettingPage.allianceInfo.needLanguage = RAAllianceSettingRecruitCell.needLanguage
            end
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGENAME_C then   --联盟名称
            RAAllianceSettingPage.allianceInfo.name = RAAllianceSettingModifyNameCell.DecString
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGETAG_C then    --联盟简称
            RAAllianceSettingPage.allianceInfo.tag = RAAllianceSettingModifyShortCell.DecString
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGELANG_C then    --联盟语言
            RAAllianceSettingPage.allianceInfo.language = currLanguage
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGELEVELNAME_C then    --联盟阶级称谓

            local L1Name = RAAllianceSettingTitleCell.editBox1:getText() or ""
            local L2Name = RAAllianceSettingTitleCell.editBox2:getText() or ""
            local L3Name = RAAllianceSettingTitleCell.editBox3:getText() or ""
            local L4Name = RAAllianceSettingTitleCell.editBox4:getText() or ""
            local L5Name = RAAllianceSettingTitleCell.editBox5:getText() or ""

            if L1Name ~= "" then
                RAAllianceSettingPage.allianceInfo.L1Name = L1Name
            end
            if L2Name ~= "" then
                RAAllianceSettingPage.allianceInfo.L2Name = L2Name
            end
            if L3Name ~= "" then
                RAAllianceSettingPage.allianceInfo.L3Name = L3Name
            end
            if L4Name ~= "" then
                RAAllianceSettingPage.allianceInfo.L4Name = L4Name
            end
            if L5Name ~= "" then
                RAAllianceSettingPage.allianceInfo.L5Name = L5Name
            end
        elseif message.opcode == HP_pb.GUILDMANAGER_CHANGETYPE_C then   --联盟类型修改成功
            RAAllianceManager.selfAlliance.guildType = RAAllianceSettingTypeCell.selectType
            RARootManager.ShowMsgBox("@ChangeAllianceTypeSuccess")
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        end 

        if message.opcode ~= HP_pb.GUILDMANAGER_CHANGETYPE_C then
            RARootManager.ShowMsgBox("@UpdateSuccess")
        end
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_POSTANNOUNCEMENT_C then 
            RARootManager.ShowMsgBox("@UpdateFail")
        end 
    elseif message.messageID == MessageDef_Alliance.MSG_Alliance_SettingLangue then    
        RAAllianceSettingRecruitCell.needLanguage = RAAllianceSettingPage.currNeedLanguage or "all"
        local languageString = RAAllianceUtility:getLanguageIdByName(RAAllianceSettingRecruitCell.needLanguage)
        UIExtend.setStringForLabel(RAAllianceSettingRecruitCell.ccbfile,{mLanguage = languageString})
    elseif message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAAllianceSettingPage' then 
            RAAllianceSettingPage:setEditBoxVisible(true)
        else
            RAAllianceSettingPage:setEditBoxVisible(false)
        end 
    end 
end

function RAAllianceSettingPage:setEditBoxVisible(visible)
    if RAAllianceSettingRecruitCell ~= nil then 
        if RAAllianceSettingRecruitCell.editBox1 ~= nil then 
            RAAllianceSettingRecruitCell.editBox1:setVisible(visible)
        end 

        if RAAllianceSettingRecruitCell.editBox2 ~= nil then 
            RAAllianceSettingRecruitCell.editBox2:setVisible(visible)
        end 

        if RAAllianceSettingRecruitCell.editBox3 ~= nil then 
            RAAllianceSettingRecruitCell.editBox3:setVisible(visible)
        end 
    end 
end

function RAAllianceSettingPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_SettingLangue,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,OnReceiveMessage)
end

function RAAllianceSettingPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_SettingLangue,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RAAllianceSettingPage:Exit()
    local cell = subCell[lastClickRecord.index]
    if cell then
        cell:Exit()
    end
    self.editBox = nil 
    self.isKeyboardShow = false
    lastClickRecord.ccb = nil
    lastClickRecord.index = 0
    isAnimationOpen = false
    self.mLayer:removeFromParentAndCleanup(true)
    self:removeMessageHandler()
	self.scrollView:removeAllCell()
	UIExtend.unLoadCCBFile(self)
end

return RAAllianceSettingPage