--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceRecommondCell = {}
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RAAllianceManager = RARequire('RAAllianceManager')

function RAAllianceRecommondCell:new(o)
    o = o or {}
    o.info = nil 
    o.cellType = 0  --0 是推荐 1 是邀请 2 是设置里面搜索
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceRecommondCell:onJoinBtn()
    RARootManager.OpenPage('RAAllianceDetailPage',self.info)
end

function RAAllianceRecommondCell:onInviteBtn()
    RARootManager.OpenPage('RAAllianceDetailPage',self.info)
end

function RAAllianceRecommondCell:onClick()
    RARootManager.OpenPage('RAAllianceDetailPage',self.info)
end

function RAAllianceRecommondCell:onNoBtn()
    RAAllianceProtoManager:refuseInviteReq(self.info.id)
end

function RAAllianceRecommondCell:onYesBtn()
    RAAllianceProtoManager:acceptInviteReq(self.info.id)
end

--刷新数据
function RAAllianceRecommondCell:onRefreshContent(ccbRoot)
	--todo
	CCLuaLog("RAAllianceRecommondCell:onRefreshContent")

    self.ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(self.ccbfile)

    self.mAllianceName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceName')
    self.mLeaderName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLeaderName')
    self.mMemNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemNum')
    self.mFightValue = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mFightValue')
    self.mLanguageLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLanguageLabel')
    self.mWarType = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,'mWarType')
    self.mWarType:setString(RAAllianceUtility:getAllianceTypeName(self.info.guildType))

    self.mJoinBtnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mJoinBtnNode')
    self.mApplicationBtnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mApplicationBtnNode')
    self.mInviteBtnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInviteBtnNode')

    self.mAllianceName:setString('[' .. self.info.tag .. ']' .. self.info.name)
    self.mLeaderName:setString( _RALang('@AllianceLeader') .. ':' ..  self.info.leaderName)
    self.mMemNum:setString(self.info.memberNum .. '/' .. self.info.memberMaxNum)
    self.mFightValue:setString(self.info.power)

    self.mLanguageLabel:setString(RAAllianceUtility:getLanguageIdByName(self.info.language))
    UIExtend.setControlButtonTitle(self.ccbfile, "mInviteBtn","@Apply")
    if self.cellType == 0 then 

        if self.info.isApply == true then 
            self.mJoinBtnNode:setVisible(false)
            self.mApplicationBtnNode:setVisible(true)
            UIExtend.setControlButtonTitle(self.ccbfile, "mInviteBtn","@CancelApply")
        else
            local isCan = self.info.openRecurit
            --判断大本等级
            local RABuildManager = RARequire("RABuildManager")
            local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
            if RABuildManager:getMainCityLvl() < self.info.needBuildingLevel then 
                isCan = false
            elseif RAPlayerInfoManager.getPlayerLevel() < self.info.needCommonderLevel then 
                isCan = false
            elseif RAPlayerInfoManager.getPlayerFightPower() < self.info.needPower then 
                isCan = false
            elseif self.info.needLanguage ~= 'all' then 
                local lang_type =  CCApplication:sharedApplication():getCurrentLanguage()
                local i18nconfig_conf = RARequire("i18nconfig_conf")
                local curLanguageInfo = i18nconfig_conf[lang_type]
                if curLanguageInfo ~= self.info.needLanguage then 
                    isCan = false 
                end 
            end 
            if isCan == false then 
                self.mJoinBtnNode:setVisible(false)
                self.mApplicationBtnNode:setVisible(true)
            else
                self.mJoinBtnNode:setVisible(true)
                self.mApplicationBtnNode:setVisible(false)    
            end
        end
    	self.mInviteBtnNode:setVisible(false)
	elseif self.cellType == 1 then
		self.mJoinBtnNode:setVisible(false)
    	self.mApplicationBtnNode:setVisible(false)
        self.mWarType:setString("")
    	self.mInviteBtnNode:setVisible(true)
    elseif self.cellType == 2 then
        self.mJoinBtnNode:setVisible(false)
    	self.mApplicationBtnNode:setVisible(false)
    	self.mInviteBtnNode:setVisible(false)
	end

    if RAAllianceManager.selfAlliance ~= nil then 
        self.mJoinBtnNode:setVisible(false)
        self.mApplicationBtnNode:setVisible(false)
        self.mInviteBtnNode:setVisible(false)
    end    
   
     --旗帜
    local flagIcon = RAAllianceUtility:getAllianceFlagIdByIcon(self.info.flag)
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mCellIconNode", flagIcon)
end

return RAAllianceRecommondCell