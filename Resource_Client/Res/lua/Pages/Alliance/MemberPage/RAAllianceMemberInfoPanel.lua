--成员信息的cell
local UIExtend = RARequire("UIExtend")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RARootManager = RARequire('RARootManager')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')

local RAAllianceMemberInfoPanel = {}

function RAAllianceMemberInfoPanel:new(o)
	o = o or {}
	o.data = nil 
	o.contentType = 0   -- 0 查看自己联盟 1查看别人联盟
    setmetatable(o,self)
    self.__index = self    
    return o
end	 

function RAAllianceMemberInfoPanel:onTranferBtn()
    -- if self.contentType == 0 then 
        RARootManager.OpenPage("RAAllianceMemberManagerPopUp",self.data,false, true, true)
    -- else
    --     RARootManager.OpenPage("RAAllianceMemberManagerPopUp",self.data,false, true, true)
    -- end 
end

--刷新数据
function RAAllianceMemberInfoPanel:init(ccbfile,data,contentType)
    -- self.ccbfile = ccbRoot:getCCBFileNode() 
    -- self.ccbfile = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemLevel')

    if ccbfile ~= nil then 
    	self.ccbfile = ccbfile
    	self.ccbfile:registerFunctionHandler(self)
    else 
    	self.ccbfile = UIExtend.loadCCBFile("RAAllianceMembersCell2.ccbi", RAAllianceMemberInfoPanel)
    end 

    self.data = data
    self.data.contentType = contentType
    self.contentType = contentType

    local libStr = {}
    libStr['mAllianceName'] = self.data.playerName
    libStr['mFightValue'] = Utilitys.formatNumber(self.data.power)
    
    local isOnlineStr = ""
    local offlineTime = self.data.offlineTime

    --头像
    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.data.icon)
    UIExtend.addSpriteToNodeParent(ccbfile, "mFrameIconNode", playerIcon)
    local mainNode = UIExtend.getCCNodeFromCCB(ccbfile,"mFrameIconNode"):getParent()
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    mainNode:setVisible(true)


    if self.contentType == 0 then 
        if self.data.offlineTime == 0 then
            isOnlineStr = _RALang("@InOnline")
        else
            local currTime = common:getCurMilliTime()
            local lostTime = (currTime - offlineTime) / 1000  --毫秒转成秒
            isOnlineStr = _RALang("@NoInOnline",Utilitys.second2AllianceDataString(lostTime))

            -- mainNode:setAnchorPoint(ccp(0,0))
            local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
            graySprite:setTag(grayTag)
            graySprite:setPosition(mainNode:getPosition())
            graySprite:setAnchorPoint(mainNode:getAnchorPoint())
            mainNode:getParent():addChild(graySprite)
            
            mainNode:setVisible(false)

        end
        UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,'mStateLabelSprite'):setVisible(true)
    else
        UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,'mStateLabelSprite'):setVisible(false)
    end 
        
    libStr['mStateLabel'] = isOnlineStr

    UIExtend.setStringForLabel(self.ccbfile,libStr)

    

    self.ccbfile:getCCNodeFromCCB('mTranferBtnNode'):setVisible(true)
    if self.contentType == 0 then 
        local RAAllianceManager = RARequire('RAAllianceManager')
        if RAAllianceManager.authority > self.data.authority then 
           UIExtend.setControlButtonTitle(self.ccbfile, 'mTranferBtn', '@ManagerBtn') 
    	   -- self.ccbfile:getCCNodeFromCCB('mTranferBtnNode'):setVisible(true)
    	else
            UIExtend.setControlButtonTitle(self.ccbfile, 'mTranferBtn', '@Detail')
           -- self.ccbfile:getCCNodeFromCCB('mTranferBtnNode'):setVisible(false)
        end 
    else
    	   UIExtend.setControlButtonTitle(self.ccbfile, 'mTranferBtn', '@Detail')
    end

    if self.data.playerId == RAPlayerInfoManager.getPlayerId() then 
        self.ccbfile:getCCNodeFromCCB('mTranferBtnNode'):setVisible(false)
    else 
        self.ccbfile:getCCNodeFromCCB('mTranferBtnNode'):setVisible(true)
    end 

end


return RAAllianceMemberInfoPanel