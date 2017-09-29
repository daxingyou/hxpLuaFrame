--联盟留言的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceLeaveMsgCell = {}
local RARootManager = RARequire("RARootManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local Utilitys = RARequire('Utilitys')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAStringUtil = RARequire('RAStringUtil')

function RAAllianceLeaveMsgCell:new(o)
    o = o or {}
    o.info = nil 
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

--刷新数据
function RAAllianceLeaveMsgCell:onRefreshContent(ccbRoot)
	--todo
	-- CCLuaLog("RAAllianceHistoryCell:onRefreshContent")
    UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
    self.ccbfile = ccbRoot:getCCBFileNode() 

     --头像
    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.info.icon)
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mCellIconNode", playerIcon)
    
    self.mTimeLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMsgTime')
    self.mTimeLabel:setString(Utilitys.formatTime(self.info.time/1000))

    self.mPlayerName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mPlayerName')

    local playerName = self.info.playerName
    if self.info.guildTag ~= nil then 
        playerName = '(' .. self.info.guildTag .. ')' .. playerName
    end 

    self.mPlayerName:setString(playerName)

    self.mCellLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellLabel')

    -- local contentSize = self.mCellLabel:getContentSize()
    UIExtend.setCCLabelString(self.ccbfile,'mCellLabel',self.info.message,18)

    self.ccbfile:setPositionY(self.mAddHeight)

    local bubble = UIExtend.getCCNodeFromCCB(self.ccbfile, "mMsgBG")
    local bubbleSize = CCSizeMake(self.mBgOriSize.width, self.mBgOriSize.height + self.mAddHeight)
    bubble:setContentSize(bubbleSize)


    self.mTranslationBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mTranslationBtn')
    -- local posX,posY = self.mTranslationBtn:getPosition()
    self.mTranslationBtn:setPositionY(self.mOriBtnPosY-self.mAddHeight)
    self.mTranslationBtn:setVisible(false)
    -- self.mCellLabel:setString(self.info.message)
end

--刷新cell content size
function RAAllianceLeaveMsgCell:onResizeCell(ccbfile)
    CCLuaLog("RAChatUIPageCell:onResizeCell")
    if self.cell == nil or ccbfile == nil then
        return
    end
    if self.mCellOriSize ~= nil then
        return
    end
    self.mCellOriSize = {}
    self.mCellOriSize.height = 180  
    self.mCellOriSize.width = self.cell:getContentSize().width  

    UIExtend.setCCLabelString(ccbfile,'mCellLabel',self.info.message,18)
    local chtml = UIExtend.getCCLabelTTFFromCCB(ccbfile, "mCellLabel"):getContentSize()

    self.mAddHeight = 0
    local cw, ch = chtml.width, chtml.height
    if ch > 75 then
        self.mAddHeight = ch-70
    end
    
    local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + self.mAddHeight)
    self.cell:setContentSize(size)
    
    if self.mBgOriSize ~= nil then
        return
    end
    local bubble = UIExtend.getCCNodeFromCCB(ccbfile, "mMsgBG")
    self.mBgOriSize = {}
    self.mBgOriSize.height = 100--bubble:getContentSize().height 
    self.mBgOriSize.width = bubble:getContentSize().width  

    self.mTranslationBtn = UIExtend.getCCControlButtonFromCCB(ccbfile,'mTranslationBtn')
    local posX,posY = self.mTranslationBtn:getPosition() 
    self.mOriBtnPosY = posY
    -- local mclick = UIExtend.getCCMenuItemImageFromCCB(tmpCCB, "mClick")
    -- self.mBgOriSize.clickHeight = 60--mclick:getContentSize().height    --50
    -- self.mBgOriSize.clickWidth  = mclick:getContentSize().width     --480
end



--翻譯
function RAAllianceLeaveMsgCell:onTranslationBtn()
    local str = _RALang("@NoOpenTips")
    RARootManager.ShowMsgBox(str)
end

function RAAllianceLeaveMsgCell:onCheckPlayerBtn()
    -- body
    RARootManager.OpenPage("RAAllianceLeaveMsgMemberPage",self.info,false,true,true)
end

return RAAllianceLeaveMsgCell