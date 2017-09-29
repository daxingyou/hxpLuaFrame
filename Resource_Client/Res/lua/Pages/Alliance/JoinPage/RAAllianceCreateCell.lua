--创建联盟的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceCreateCell = {}

local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local guild_const_conf = RARequire('guild_const_conf')
local Const_pb = RARequire('Const_pb')
local RABuildManager = RARequire('RABuildManager')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAGameConfig = RARequire('RAGameConfig')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local i18nconfig_conf = RARequire('i18nconfig_conf')
local currentCell = nil 
RARequire("MessageManager")

function RAAllianceCreateCell:new(o)
    o = o or {}
    o.nameEdibox = nil 
    -- o.allianceName = ""
    o.isNameOK = false
    o.isTagOK = false
    setmetatable(o,self)
    self.__index = self    
    currentCell = o
    return o
end


--刷新数据
function RAAllianceCreateCell:onRefreshContent(ccbRoot)
	--todo
	CCLuaLog("RAAllianceCreateCell:onRefreshContent")
    UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile = ccbfile

    self:initEditName()
    self:initEditTag()
    -- self:initEditDeclaration()
    self:initCreateBtn()
    self:registerMessage()
end

function RAAllianceCreateCell:initCreateBtn()
    if RABuildManager:getMainCityLvl() <= guild_const_conf['createGuildCostGoldLevel'].value then 
        self.ccbfile:getCCNodeFromCCB('mCreateAllianceBtnNode'):setVisible(false)
        self.ccbfile:getCCNodeFromCCB('mSpendBtnNode'):setVisible(true)

        self.ccbfile:getCCLabelTTFFromCCB('mNeedDiamondsNum'):setString(guild_const_conf['createGuildCostGold'].value)
    else 
        self.ccbfile:getCCNodeFromCCB('mCreateAllianceBtnNode'):setVisible(true)
        self.ccbfile:getCCNodeFromCCB('mSpendBtnNode'):setVisible(false)
    end 
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	if message.opcode == HP_pb.GUILDMANAGER_CHECKNAME_C then 
    		if currentCell.isNameOK == true then 
    			currentCell.mNameAvailable:setVisible(true)
    			currentCell.mNameUnAvailable:setVisible(false)
                currentCell.mNameExplainLabel:setString(_RALang('@AllianceNameExplain'))
    		end 
        elseif message.opcode == HP_pb.GUILDMANAGER_CHECKTAG_C then 
            if currentCell.isTagOK == true then 
                currentCell.mTagAvailable:setVisible(true)
                currentCell.mTagUnAvailable:setVisible(false)
                currentCell.mExplainLabel:setString('')
            end 
    	end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
    	if message.opcode == HP_pb.GUILDMANAGER_CHECKNAME_C then 
    		if currentCell.isNameOK == true then 
    			currentCell.mNameAvailable:setVisible(false)
    			currentCell.mNameUnAvailable:setVisible(true)
    			currentCell.isNameOK = false 
                local errorStr = RAStringUtil:getErrorString(message.errCode)
                currentCell.mNameExplainLabel:setString(errorStr)
                -- currentCell.mNameExplainLabel:setString(_RALang('@AllianceNameIsExist'))
    		end
        elseif message.opcode == HP_pb.GUILDMANAGER_CHECKTAG_C then 
            if currentCell.isTagOK == true then 
                currentCell.mTagAvailable:setVisible(false)
                currentCell.mTagUnAvailable:setVisible(true)
                currentCell.isTagOK = false
                local errorStr = RAStringUtil:getErrorString(message.errCode) 
                currentCell.mExplainLabel:setString(errorStr)
            end
    	end
    elseif message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAAllianceJoinPage' then 
            currentCell:setEditBoxVisible(true)
        else
            currentCell:setEditBoxVisible(false)
        end   
    end 
end

function RAAllianceCreateCell:setEditBoxVisible(visible)
    if self.tagEdibox ~= nil then 
        self.tagEdibox:setVisible(visible)
    end 
end

function RAAllianceCreateCell:registerMessage()
	MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,OnReceiveMessage)
end

function RAAllianceCreateCell:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

-- function RAAllianceCreateCell:initEditDeclaration()
--     local function inputEditboxEventHandler(eventType, node)
--     --body
--         -- CCLuaLog(eventType)
--         if eventType == "began" then
--         elseif eventType == "ended" then
--         elseif eventType == "changed" then
--             -- triggered when the edit box text was changed.
--             self:updateDeclaration()
--         elseif eventType == "return" then
--         end
--     end


--     self.mInputDeclarationNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputDeclarationNode')
    
--     -- local picScale9Sprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,'mInputDeclarationBG')
--     -- local size = picScale9Sprite:getContentSize()
--     -- local resize = CCSizeMake(size.width-10, size.height)

--     -- local declarationEdibox=UIExtend.createEditBox(self.ccbfile,"mInputDeclarationBG",self.mInputDeclarationNode,inputEditboxEventHandler,nil,200,nil,nil,nil,nil,nil,resize)
--     local declarationEdibox=UIExtend.createEditBox(self.ccbfile,"mInputDeclarationBG",self.mInputDeclarationNode,inputEditboxEventHandler,nil,200,nil,nil,nil,nil,nil)
--     self.declarationEdibox = declarationEdibox
--     self.declarationEdibox:setFontColor(RAGameConfig.COLOR.WHITE)
--     self.declarationEdibox:setText(_RALang('@AllianceDefaultDeclaration'))
--     self.isDeclarationOK = true 
-- end

-- function RAAllianceCreateCell:updateDeclaration()
--     local text = self.declarationEdibox:getText()
--     -- local length = RAStringUtil:getStringUTF8Len(text)

--     local result = RAAllianceUtility:checkAllianceDeclaration(text)
--     if result == 0 then 
--         self.isDeclarationOK = true 
--     elseif result == -3 then 
--         self.isDeclarationOK = false  
--     end 
-- end


function RAAllianceCreateCell:initEditName()
	 --联盟名字数字
    self.remainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mRemainingLabel')
    self.remainLabel:setString(_RALang("@AllianceNameRemain",16))
    self.mNameExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNameExplainLabel')

    self.mNameAvailable = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mNameAvailable')
    self.mNameUnAvailable = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mNameUnAvailable')
    self.mNameAvailable:setVisible(false)
    self.mNameUnAvailable:setVisible(false)

    local function inputEditboxEventHandler(eventType, node)
    --body
	    CCLuaLog(eventType)
	    if eventType == "began" then
	        -- triggered when an edit box gains focus after keyboard is shown
	    elseif eventType == "ended" then
	        -- triggered when an edit box loses focus after keyboard is hidden.
	    elseif eventType == "changed" then
	        -- triggered when the edit box text was changed.
			self:updateName()
            self:updateDefaultTag()
            if self.isNameOK == true then 
                RAAllianceProtoManager:checkGuildNameReq(self.nameEdibox:getText())
            end 
	    elseif eventType == "return" then
	    	-- if self.isNameOK == true then 
	    	-- 	RAAllianceProtoManager:checkGuildNameReq(self.nameEdibox:getText())
	    	-- end 
	    end
	end


    self.mInputNameNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputNameNode')
    local nameEdibox=UIExtend.createEditBox(self.ccbfile,"mInputNameBG",self.mInputNameNode,inputEditboxEventHandler,nil,16)
    self.nameEdibox = nameEdibox
    self.nameEdibox:setInputMode(kEditBoxInputModeSingleLine)
    self.nameEdibox:setIsShowTTF(true)
    self.nameEdibox:setFontColor(RAGameConfig.COLOR.WHITE)
end

function RAAllianceCreateCell:updateDefaultTag()
    local text = self.tagEdibox:getText() 
    if text == '' or text == nil then 
        local name = self.nameEdibox:getText() 
        if #name >= 4 then
            local defaultTag = string.sub(name,1,4)
            local result = RAAllianceUtility:checkAllianceTag(defaultTag)
            if result ~= -2 then 
                self.tagEdibox:setText(defaultTag)
                self:updateTag()

                if self.isTagOK == true then 
                    RAAllianceProtoManager:checkGuildTagReq(self.tagEdibox:getText())
                end 
            end 
        end  
    end 
end

function RAAllianceCreateCell:onUnLoad()
	self.nameEdibox:removeFromParentAndCleanup(false)
	self.tagEdibox:removeFromParentAndCleanup(false)
    -- self.declarationEdibox:removeFromParentAndCleanup(false)
	self:removeMessageHandler()
end

function RAAllianceCreateCell:initEditTag()
	--联盟缩写
    self.remainTagLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mRemainingLabel2')
    self.remainTagLabel:setString(_RALang("@AllianceNameRemain",4))
    self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTagExplainLabel')

    self.mTagAvailable = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mTagAvailable')
    self.mTagUnAvailable = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mTagUnAvailable')
    self.mTagAvailable:setVisible(false)
    self.mTagUnAvailable:setVisible(false)

    local function inputEditboxEventHandler(eventType, node)
    --body
	    CCLuaLog(eventType)
	    if eventType == "began" then
	        -- triggered when an edit box gains focus after keyboard is shown
	    elseif eventType == "ended" then
	        -- triggered when an edit box loses focus after keyboard is hidden.
	    elseif eventType == "changed" then
	        self:updateTag()
            if self.isTagOK == true then 
                RAAllianceProtoManager:checkGuildTagReq(self.tagEdibox:getText())
            end
	    elseif eventType == "return" then
            -- if self.isTagOK == true then 
            --     RAAllianceProtoManager:checkGuildTagReq(self.tagEdibox:getText())
            -- end 
	    end
	end


    self.mInputTagNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputTagNode')
    local tagEdibox=UIExtend.createEditBox(self.ccbfile,"mInputTagBG",self.mInputTagNode,inputEditboxEventHandler,nil,4)
    self.tagEdibox = tagEdibox
    self.tagEdibox:setInputMode(kEditBoxInputModeSingleLine)
    -- self.tagEdibox:setIsShowTTF(true)
    self.tagEdibox:setFontColor(RAGameConfig.COLOR.WHITE)    
end

function RAAllianceCreateCell:updateTag()
    local text = self.tagEdibox:getText()
    text = RAStringUtil:trim(text)
    local length = RAStringUtil:getStringUTF8Len(text)
    -- self.tagEdibox:setText(text)
    -- self.tagName = text
    self.remainTagLabel:setString(_RALang("@AllianceNameRemain",4-length))

    local result = RAAllianceUtility:checkAllianceTag(text)
    if result == 0 then 
        -- self.mNameAvailable:setVisible(true)
        -- self.mNameUnAvailable:setVisible(false)
        self.isTagOK = true
        self.mExplainLabel:setString(_RALang('@AllianceTagExplain'))
    else 
        self.mTagAvailable:setVisible(false)
        self.mTagUnAvailable:setVisible(true)
        self.isTagOK = false 

        if result == -1 then 
            self.mExplainLabel:setString(_RALang('@AllianceTagLenError'))
        elseif result == -2 then 
            self.mExplainLabel:setString(_RALang('@AllianceTagContentError'))
        elseif result == -3 then 
            self.mExplainLabel:setString(_RALang('@AllianceTagBlockError'))
        end 
    end 
end

function RAAllianceCreateCell:updateName()
	local text = self.nameEdibox:getText()
    text = RAStringUtil:trim(text)
    -- local length = RAStringUtil:getStringUTF8Len(text)
    -- local common = RARequire('common')
    local length =  GameMaths:calculateNumCharacters(text)
    -- self.nameEdibox:setText(text)

    local remainNum = 16-length
    if remainNum<0 then 
        remainNum = 0
    end 

    self.remainLabel:setString(_RALang("@AllianceNameRemain",remainNum))

    local result = RAAllianceUtility:checkAllianceName(text)
    if result == 0 then 
    	-- self.mNameAvailable:setVisible(true)
    	-- self.mNameUnAvailable:setVisible(false)
    	self.isNameOK = true
    else 
    	self.mNameAvailable:setVisible(false)
    	self.mNameUnAvailable:setVisible(true)
    	self.isNameOK = false 

        if result == -1 then 
            self.mNameExplainLabel:setString(_RALang('@AllianceNameLenError'))
        elseif result == -2 then 
            self.mNameExplainLabel:setString(_RALang('@AllianceNameContentError'))
        elseif result == -3 then 
            self.mNameExplainLabel:setString(_RALang('@AllianceNameBlockError'))
        end 
    end 
end

function RAAllianceCreateCell:onCreateAllianceBtn()
	local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')

    if self.isNameOK == false or self.isTagOK == false or self.isDeclarationOK == false then
        RARootManager.ShowMsgBox(_RALang('@AllianceCreateHasError'))
        return 
    end 
    local RAStringUtil = RARequire("RAStringUtil")
    local lang_type =  RAStringUtil:getCurrentLang()
    local curLanguageInfo = i18nconfig_conf[lang_type]
    if curLanguageInfo ~= nil then
            RAAllianceProtoManager:createAllianceReq(self.nameEdibox:getText(),self.tagEdibox:getText(),curLanguageInfo.id,_RALang('@AllianceDefaultDeclaration'))
    end
	
    -- RAAllianceProtoManager:createAllianceReq(self.nameEdibox:getText(),self.tagEdibox:getText(),'EN','这个是联盟宣言')
end 

function RAAllianceCreateCell:onOpenRecruitBtn()

    if RABuildManager:getMainCityLvl() <= guild_const_conf['createGuildCostGoldLevel'].value then 
        local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
        local needGold = tonumber(guild_const_conf['createGuildCostGold'].value)
        if needGold > playerDiamond then 
            RARootManager.ShowMsgBox(_RALang('@AllianceCreateNotHaveEnoughMoney'))
            return 
        end
    end  

    self:onCreateAllianceBtn()
end

return RAAllianceCreateCell