--联盟等级说明页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local alliance_level_conf = RARequire('alliance_level_conf')
local RAStringUtil = RARequire('RAStringUtil')

local RAAllianceLevelCell = {}
function RAAllianceLevelCell:new(o)
    o = o or {}
    o.cell = nil 
    -- o.info = nil 
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

--刷新数据
function RAAllianceLevelCell:onRefreshContent(ccbRoot)
    --todo
    -- UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
    self.ccbfile = ccbRoot:getCCBFileNode() 

    self.mCellTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellTitle')
    self.mCellTitle:setString(_RALang('@AllianceLevelTitle',self.info.level))

    -- local mShaderNode = tolua.cast(self.ccbfile:getVariable("mShaderNode"),"CCShaderNode")
    -- mShaderNode:setEnable(true)

    local des = ""

    des = des .. _RALang('@AllianceScoreInfo',self.info.alliance_score) .. '<br/>'
    des = des .. _RALang('@AllianceMemberNumInfo',self.info.member_limit) .. '<br/>'

    local line = 2
    if self.info.unlock_info ~= nil then 
        local desArr = RAStringUtil:split(self.info.unlock_info, ',')
        
        for i=1,#desArr do
            des = des .. _RALang(desArr[i]) .. '<br/>'
        end
        line = line + #desArr
    end 

    self.des = des
    self.mCellLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,'mCellLabel')
    self.mCellLabel:setString(des)

    local chtml = self.mCellLabel:getHTMLContentSize()

    local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + line*20)
    self.cell:setContentSize(size)
    self.ccbfile:setPositionY(line*20)
    local bubble = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBg")
    bubble:setContentSize(size)
    -- UIExtend.getCCLabelHTMLFromCCB(ccbfile,nodeName)
    -- local playerName = self.info.playerName
    
    -- if self.info.guildTag ~= nil then 
    --     playerName = '(' .. self.info.guildTag .. ')' .. playerName
    -- end 

    -- self.mPlayerName:setString(playerName)

    -- self.mCellLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellLabel')

    -- -- local contentSize = self.mCellLabel:getContentSize()
    -- UIExtend.setCCLabelString(self.ccbfile,'mCellLabel',self.info.message,18)

    -- self.ccbfile:setPositionY(self.mAddHeight)

    -- local bubble = UIExtend.getCCNodeFromCCB(self.ccbfile, "mMsgBG")
    -- local bubbleSize = CCSizeMake(self.mBgOriSize.width, self.mBgOriSize.height + self.mAddHeight)
    -- bubble:setContentSize(bubbleSize)


    -- self.mTranslationBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mTranslationBtn')
    -- -- local posX,posY = self.mTranslationBtn:getPosition()
    -- self.mTranslationBtn:setPositionY(self.mOriBtnPosY-self.mAddHeight)
    -- self.mTranslationBtn:setVisible(false)
    -- self.mCellLabel:setString(self.info.message)
end

--刷新cell content size
function RAAllianceLevelCell:onResizeCell(ccbfile)
    -- CCLuaLog("RAChatUIPageCell:onResizeCell")
    if self.cell == nil or ccbfile == nil then
        return
    end
    if self.mCellOriSize ~= nil then
        return
    end
    self.mCellOriSize = {}
    self.mCellOriSize.height = 119  
    self.mCellOriSize.width = self.cell:getContentSize().width 

    self.mCellTitle = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mCellTitle') 

    local des = ""

    des = des .. _RALang('@AllianceScoreInfo',self.info.alliance_score) .. '<br/>'
    des = des .. _RALang('@AllianceMemberNumInfo',self.info.member_limit) .. '<br/>'

    local line = 2
    if self.info.unlock_info ~= nil then 
        local desArr = RAStringUtil:split(self.info.unlock_info, ',')
        
        for i=1,#desArr do
            des = des .. _RALang(desArr[i]) .. '<br/>'
            line = line + 1
        end
    end 

    self.des = des
    self.mCellLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile,'mCellLabel')
    self.mCellLabel:setString(des)

    -- self.mCellTitle:setString(_RALang('@AllianceLevelTitle',self.info.level))

    -- UIExtend.setCCLabelString(ccbfile,'mCellLabel',self.info.message,18)
    local chtml = self.mCellLabel:getHTMLContentSize()

    self.mAddHeight = 0
    local cw, ch = chtml.width, chtml.height
    if ch > 75 then
        self.mAddHeight = ch-70
    end
    
    local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + line*20)
    self.cell:setContentSize(size)
    
    -- if self.mBgOriSize ~= nil then
    --     return
    -- end
    local bubble = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBg")
    bubble:setContentSize(size)
    -- self.mBgOriSize = {}
    -- self.mBgOriSize.height = 100--bubble:getContentSize().height 
    -- self.mBgOriSize.width = bubble:getContentSize().width  

    -- self.mTranslationBtn = UIExtend.getCCControlButtonFromCCB(ccbfile,'mTranslationBtn')
    -- local posX,posY = self.mTranslationBtn:getPosition() 
    -- self.mOriBtnPosY = posY
end



local RAAllianceLevelPage = class('RAAllianceLevelPage',RAAllianceBasePage)

function RAAllianceLevelPage:ctor(...)
    self.ccbfileName = "RAAllianceCommonPopUp.ccbi"
    self.scrollViewName = 'mListSV'
end

function RAAllianceLevelPage:refreshAllDes()
    self.mListSV:removeAllCell()

    for i=1,10 do
        local cell = CCBFileCell:create()
        local ccbiStr = "RAAllianceCommonPopUpCell.ccbi"
        local panel = RAAllianceLevelCell:new({})
        panel.info = alliance_level_conf[i]
        panel.cell=cell
        cell:registerFunctionHandler(panel)
        -- cell:setAnchorPoint(CCPointMake(0,1))
        cell:setCCBFile(ccbiStr)
        self.mListSV:addCell(cell)
    end
    self.mListSV:setTouchEnabled(true)
    self.mListSV:orderCCBFileCells()
end

--初始化顶部
function RAAllianceLevelPage:initTitle()
    -- -- body
    UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mTitle"):setString(_RALang('@AllianceLevelDest'))
end

function RAAllianceLevelPage:onClose()
    RARootManager.ClosePage("RAAllianceLevelPage")
end

function RAAllianceLevelPage:release()
    self.mListSV:removeAllCell()
end

--子类实现
function RAAllianceLevelPage:initScrollview()
    self.mListSV =  UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
    self:refreshAllDes()
end

return RAAllianceLevelPage.new()