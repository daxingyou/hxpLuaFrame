--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceBaseCell = RARequire('RAAllianceBaseCell')
local RAAllianceLeaderContentCell = class('RAAllianceLeaderContentCell',RAAllianceBaseCell)
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

function RAAllianceLeaderContentCell:onTranferBtn()
    RARootManager.OpenPage("RAAllianceMemberManagerPopUp",self.data,false, true, true)
end

--刷新数据
function RAAllianceLeaderContentCell:onRefreshContent(ccbRoot)
	self.ccbfile = ccbRoot:getCCBFileNode() 
	
	local libStr = {}
    libStr['mAllianceName'] = self.data.playerName
    libStr['mFightValue'] = Utilitys.formatNumber(self.data.power)
    
    local isOnlineStr = ""
    local offlineTime = self.data.offlineTime

    --头像
    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.data.icon)

    UIExtend.addSpriteToNodeParent(self.ccbfile, "mFrameIconNode", playerIcon)

    local mainNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mFrameIconNode"):getParent()
    local grayTag = 10000
    mainNode:getParent():removeChildByTag(grayTag,true)
    mainNode:setVisible(true)
    
    if self.contentType == 0 then 
        if self.data.offlineTime == 0 then
            isOnlineStr = _RALang("@InOnline")
        else
            local currTime = common:getCurMilliTime()
            local lostTime = (currTime - offlineTime) / 1000  --毫秒转成秒
            isOnlineStr = _RALang("@NoInOnline",Utilitys.second2DateMinuteString(lostTime))

            local graySprite = GraySpriteMgr:createGrayMask(mainNode,mainNode:getContentSize())
            graySprite:setTag(grayTag)
            graySprite:setPosition(mainNode:getPosition())
            graySprite:setAnchorPoint(mainNode:getAnchorPoint())
            mainNode:getParent():addChild(graySprite)
            
            mainNode:setVisible(false)
        end
    end 
        
    libStr['mStateLabel'] = isOnlineStr

    UIExtend.setStringForLabel(self.ccbfile,libStr)


    if self.contentType == 0 then 
        UIExtend.setControlButtonTitle(self.ccbfile, 'mTranferBtn', '@Detail')
        local RAAllianceManager = RARequire('RAAllianceManager')
        if RAAllianceManager.authority > self.data.authority then 
    	   -- self.ccbfile:getCCControlButtonFromCCB('mTranferBtn'):setVisible(true)
    	else
           -- self.ccbfile:getCCControlButtonFromCCB('mTranferBtn'):setVisible(false)
        end 
    else
        UIExtend.setControlButtonTitle(self.ccbfile, 'mTranferBtn', '@Detail')
    	-- self.ccbfile:getCCNodeFromCCB('mTranferBtn'):setVisible(false)
    end

    if self.data.playerId == RAPlayerInfoManager.getPlayerId() then 
        self.ccbfile:getCCNodeFromCCB('mTranferBtn'):setVisible(false)
    else 
        self.ccbfile:getCCNodeFromCCB('mTranferBtn'):setVisible(true)
    end  
end

function RAAllianceLeaderContentCell:ctor(data,index)
	self.data = data[1]
    self.data.contentType = data.contentType
	self.index = index
	self.contentType = data.contentType
	self.ccbfileName = 'RAAllianceMembersCell3.ccbi'
end

return RAAllianceLeaderContentCell