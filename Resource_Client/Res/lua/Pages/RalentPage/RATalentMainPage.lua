RARequire("BasePage")
local RATalentManager = RARequire("RATalentManager")
local RAGameConfig = RARequire("RAGameConfig")
local player_talent_conf = RARequire("player_talent_conf")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire("Const_pb")
local Talent_pb = RARequire("Talent_pb")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local item_conf = RARequire("item_conf")
local shop_conf = RARequire("shop_conf")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAStringUtil = RARequire("RAStringUtil")

local RATalentMainPage = BaseFunctionPage:new(...)

RATalentMainPage.currTalentType = nil--当前显示的天赋类型
RATalentMainPage.oldTalentType = nil--切换前显示的天赋类型
RATalentMainPage.cellSizeHeight = 0 --cell的高度，用来计算scrollview的contentsize
RATalentMainPage.fightBtn = nil --战斗天赋按钮
RATalentMainPage.developBtn = nil --发展天赋按钮
RATalentMainPage.fightBtnPos = {x = 0, y = 0} --战斗天赋起始位置
RATalentMainPage.developBtnPos = {x = 0, y = 0} --发展天赋起始位置
RATalentMainPage.talentLines = {}--保存连接的背景黑线，key是talentid（number），value是有它发出所有的线的数组
RATalentMainPage.talentRedLines = {}--保存连接的红线
RATalentMainPage.circlePlates = {} --保存所有的连接点圆形
RATalentMainPage.allCells = {}--保存所有cell
RATalentMainPage.netHandler = {}--网络监听接口
RATalentMainPage.upgradeTalentId = nil--升级的天赋id

local spaceX = 200 --水平方向一条线距离
local spaceY = 150--垂直一条线距离

local basePos = nil--基础实际位置，scrollview的上面中间位置为基础坐标
local baseRelativePos = nil--第一个天赋的逻辑位置，其他天赋的逻辑位置都是根据这个来的

RATalentMainPage.svContentOffset = nil --scrollview偏移
RATalentMainPage.scrollView = nil --scrollView
RATalentMainPage.hasResetTalentTools = false
--消息处理
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Lord.MSG_TalentUpgrade then
    --天赋升级 是否会解锁其余天赋
        RATalentMainPage.upgradeTalentId = message.talentId
        RATalentMainPage:refreshPage()
    end
end

---------------------------------------------
local RASkillCellListener = {
    skillId = 0,
    skillType = nil,
}
function RASkillCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RASkillCellListener:onRefreshContent(ccbRoot)
    local constSkillInfo = player_talent_conf[self.skillId]--通过skillId获得skill信息
    if constSkillInfo == nil then
        return
    end

    local ccbfile = ccbRoot:getCCBFileNode()
    if not RATalentManager.isTalentLock(self.skillId) then
        UIExtend.setNodeVisible(ccbfile,"mRedBGNode",true)
        UIExtend.setNodeVisible(ccbfile,"mGrayBGNode",false)
        local pic = UIExtend.addSpriteToNodeParent(ccbfile, "mCellSkillIconNode", constSkillInfo.icon, 0, ccc3(255,255,255))
        if pic then
            UIExtend.setCCSpriteGray(pic,false)
        end
    else
        UIExtend.setNodeVisible(ccbfile,"mRedBGNode",false)
        UIExtend.setNodeVisible(ccbfile,"mGrayBGNode",true)
        local pic = UIExtend.addSpriteToNodeParent(ccbfile, "mCellSkillIconNode", constSkillInfo.icon, 0, ccc3(166,166,166))
        if pic then
            UIExtend.setCCSpriteGray(pic,true)
        end
    end

    local skillServerInfo = RATalentManager.getTalentInfo()[self.skillId]--通过skillId获得server数据
    local currentLevel = 0
    if skillServerInfo ~= nil then
        currentLevel = skillServerInfo.level
    end
    local levelStr =  currentLevel .. "/" .. constSkillInfo.maxLevel
    UIExtend.setCCLabelString(ccbfile, "mCellLevel", levelStr)
    if currentLevel == constSkillInfo.maxLevel then
        UIExtend.setLabelTTFColor(ccbfile, "mCellLevel", ccc3(255, 255, 0))
    else
        UIExtend.setLabelTTFColor(ccbfile, "mCellLevel", ccc3(255, 255, 255))
    end

    UIExtend.setCCLabelString(ccbfile, "mCellName", _RALang(constSkillInfo.name))
    if currentLevel > 0 then
        UIExtend.setLabelTTFColor(ccbfile, "mCellName", ccc3(255, 255, 0))
    else
        UIExtend.setLabelTTFColor(ccbfile, "mCellName", ccc3(255, 255, 255))
    end

    if self.skillId == RATalentMainPage.upgradeTalentId then
        local mUpgradeSkillAniCCB = UIExtend.getCCBFileFromCCB(ccbfile, "mUpgradeSkillAniCCB")
        if mUpgradeSkillAniCCB then
            mUpgradeSkillAniCCB:runAnimation("UpgradeAni")
        end
        RATalentMainPage.upgradeTalentId = nil
    end

end

function RASkillCellListener:onSkillBG()
    RATalentMainPage.svContentOffset = RATalentMainPage.scrollView:getContentOffset()
    local data = {}
    data.talentId = tonumber(self.skillId)
    RARootManager.OpenPage("RATalentUpgradePage", data, false, true, true)
end

----------------------------------------------

function RATalentMainPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.TALENT_CLEAR_S then
        local msg = Talent_pb.HPTalentClearResp()
        msg:ParseFromString(buffer)
        if msg.result == true then
            RATalentManager.reset()
            self:refreshPage()
        end
    end
end

--页面入口
function RATalentMainPage:Enter(data)
    RATalentMainPage.oldTalentType = nil
    RATalentMainPage.svContentOffset = nil
    self.ccbfile = UIExtend.loadCCBFile("RALordSkillPage.ccbi", RATalentMainPage)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSkillSV")

    --初始化两个type按钮
    RATalentMainPage.fightBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mFightSkillBtn")
    RATalentMainPage.fightBtnPos.x, RATalentMainPage.fightBtnPos.y = RATalentMainPage.fightBtn:getPosition()
    RATalentMainPage.developBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mDevelopSkillBtn")
    RATalentMainPage.developBtnPos.x, RATalentMainPage.developBtnPos.y = RATalentMainPage.developBtn:getPosition()

    basePos = ccp(0, 0)
    baseRelativePos = ccp(0, 0)

    self.hasResetTalentTools = false

    --初始化基础位置数据
    local mSVNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mSVNode")
    if mSVNode then
        basePos.x = mSVNode:getContentSize().width / 2
        basePos.y = mSVNode:getContentSize().height - 185
    end

    RATalentMainPage.currTalentType = RAGameConfig.TalentTypes.TALENT_FIGHT --当前显示的技能类型
    RATalentMainPage.oldTalentType = nil
    if RATalentMainPage.fightBtn then--设置当前技能按钮高亮
        RATalentMainPage.fightBtn:setHighlighted(true)
    end
    if self.developBtn then
        self.developBtn:setHighlighted(false)
    end

    RATalentMainPage:runBtnAction()--tab按钮效果
    RATalentMainPage:refreshPage()
    self:addHandler()--添加各种handler
end

--添加各种监听
function RATalentMainPage:addHandler()
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_TalentUpgrade, OnReceiveMessage)
    RATalentMainPage.netHandler[#RATalentMainPage.netHandler +1] = RANetUtil:addListener(HP_pb.TALENT_CLEAR_S, RATalentMainPage)
end

--移除各种监听
function RATalentMainPage:removeHandler()
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_TalentUpgrade, OnReceiveMessage)

    --取消packet监听
    for k, value in pairs(RATalentMainPage.netHandler) do
        if RATalentMainPage.netHandler[k] ~= nil then
             RANetUtil:removeListener(RATalentMainPage.netHandler[k])
             RATalentMainPage.netHandler[k] = nil
        end
    end
    RATalentMainPage.netHandler = {}
end

--刷新页面展示的总入口
function RATalentMainPage:refreshPage()
    RATalentMainPage:refreshTop()
    RATalentMainPage:setResetBtn()
    RATalentMainPage:refreshSkillTree()--刷新天赋树
end

--刷新顶部信息
function RATalentMainPage:refreshTop()
    --获得总天赋点
    local totleNum = RATalentManager.getFreeGeneralNum()
    local totalStr = RAStringUtil:getLanguageString("@TotalTalent", totleNum)
    UIExtend.setCCLabelString(self.ccbfile, "mSkillPoint", totalStr)

    --获得已经使用的天赋点
    local num = RATalentManager.getUseGeneralNumByType(RATalentMainPage.currTalentType)
    local putInStr = RAStringUtil:getLanguageString("@TalentPutIn", num)
    UIExtend.setCCLabelString(self.ccbfile, "mUsedPoints", putInStr)
    
    --设置天赋类型icon和描述
    local typeIcon = ""--天赋类型icon
    local typeDesStr = ""
    if RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_FIGHT then
        typeIcon = RAGameConfig.TalentIcons.TALENT_FIGHT_ICON
        typeDesStr = RAGameConfig.TalentIntroduce.TALENT_FIGHT_INTRO
    elseif RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_DEVELOP then
        typeIcon = RAGameConfig.TalentIcons.TALENT_DEVELOP_ICON
        typeDesStr = RAGameConfig.TalentIntroduce.TALENT_DEVELOP_INTRO
    end

    UIExtend.setCCLabelString(self.ccbfile, "mUpgradeExplain", _RALang(typeDesStr))
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mUpgradeIconNode", typeIcon)
end

--设置重置按钮
function RATalentMainPage:setResetBtn()
    --获得洗点道具数量
    
    local toolNum, itemIcon, itemPrice = self:getResetToolNum()

    local pic = ""--显示的图标
    local num = 0--显示的数量
    if toolNum >= RAGameConfig.TalentResetConsume.CONSUME_COUNT then
        pic = itemIcon .. ".png"
        num = 1
        self.hasResetTalentTools = true
    else
        pic = RAGameConfig.Diamond_Icon--金币的icon
        num = itemPrice--需要花费的金币数量
    end

    UIExtend.setSpriteIcoToNode(self.ccbfile, "mResetIcon", pic)
    UIExtend.setCCLabelString(self.ccbfile, "mResetNum", num)


    --获得已使用的技能点
    local total = RATalentManager.getUseGeneralNum()
    if total > 0 then
    --按钮可用
        UIExtend.setCCControlButtonEnable(self.ccbfile, "mRevertPointBtn", true)
    else
    --按钮不可用
        UIExtend.setCCControlButtonEnable(self.ccbfile, "mRevertPointBtn", false)
    end
end

--获得重置道具数量
function RATalentMainPage:getResetToolNum()
    local toolId = Const_pb.SHOP_TALENT_CLEAR
    local shopConstInfo = shop_conf[toolId]
    local itemId = shopConstInfo.shopItemID
    local constToolInfo = item_conf[itemId]
    local toolNum = RACoreDataManager:getItemCountByItemId(itemId)
    return toolNum,  constToolInfo.item_icon, shopConstInfo.price
end


function RATalentMainPage:isLineExist(talentId, lineCoordinate)
    if RATalentMainPage.talentLines[talentId] ~= nil and RATalentMainPage.talentLines[talentId] ~= {} then
        local key = lineCoordinate.x .. "_"..lineCoordinate.y
        if RATalentMainPage.talentLines[talentId][key] ~= nil then
            return true
        else
            return false
        end
    else
        return false
    end
end

function RATalentMainPage:saveLine(talentId, lineCoordinate, lineCcbi)
    if RATalentMainPage.talentLines[talentId] == nil then
        RATalentMainPage.talentLines[talentId] = {}
    end
    local key = lineCoordinate.x .."_"..lineCoordinate.y
    if RATalentMainPage.talentLines[talentId][key] == nil then
        RATalentMainPage.talentLines[talentId][key] = lineCcbi
    end
end

function RATalentMainPage:saveRedLine(talentId, lineCoordinate, redLineCcbi)
    if RATalentMainPage.talentRedLines[talentId] == nil then
        RATalentMainPage.talentRedLines[talentId] = {}
    end
    local key = lineCoordinate.x .."_"..lineCoordinate.y
    if RATalentMainPage.talentRedLines[talentId][key] == nil then
        RATalentMainPage.talentRedLines[talentId][key] = redLineCcbi
    end
end

function RATalentMainPage:refreshSkillTree()
    self.scrollView:removeAllCell()--情况所有cell
    RATalentMainPage.talentLines = {}--清空所有背景线
    RATalentMainPage.talentRedLines = {}--清空所有红色线
    RATalentMainPage.circlePlates = {}--清空所有圆形链接
    RATalentMainPage.allCells = {}--清空所有cell记录
    local count = 0
    local contentSizeWidth = 0--scrollview的宽度
    local contentSizeHeight = 0--scrollview的高度
    local offsetY = 0--适配Y，所有cell中最小的y坐标

    --遍历所有天赋
    for key, value in Utilitys.table_pairsByKeys(player_talent_conf) do
        if value.type == RATalentMainPage.currTalentType then
            
            --获得cell的坐标位置
            local site = Utilitys.Split(value.site, "_")
            local cellSitePos = {}
            cellSitePos[1] = tonumber(site[1])
            cellSitePos[2] = tonumber(site[2])

            local isLock = RATalentManager.isTalentLock(tonumber(value.id))--判断天赋是否解锁

            count = count +1--数量加1

            if count == 1 then--把第一个cell的坐标当做基准相对坐标
                baseRelativePos.x = cellSitePos[1]
                baseRelativePos.y = cellSitePos[2]
            end

            --计算原始实际位置
            local tmpPoint = ccp((cellSitePos[1] - baseRelativePos.x)*spaceX, (cellSitePos[2] - baseRelativePos.y)*spaceY)
            local realPos = ccpAdd(basePos , tmpPoint)
            RATalentMainPage:addSkillCell(value.id, realPos)--添加cell进scrollview
            tmpPoint:delete()

            --保存contentsize
            if realPos.x > contentSizeWidth then
                contentSizeWidth = realPos.x
            end
            if (basePos.y - realPos.y) > contentSizeHeight then
                contentSizeHeight = basePos.y - realPos.y
            end

            --获得适配y坐标
            if offsetY>realPos.y then
                offsetY = realPos.y
            end

            if value.connect ~= nil and value.connect ~= "" then
                --具有连接天赋
                --必然有一条竖线
                local currentLineCoordinate = {x=cellSitePos[1], y=cellSitePos[2]}
                if not RATalentMainPage:isLineExist(value.id, currentLineCoordinate) then--首先查看这条竖线是否已存在
                    local verticalLine = CCSprite:create("CollegePage/College_u_Cable_BG.png")
                    local lineSize = verticalLine:getContentSize()
                    self.scrollView:addChild(verticalLine)
                    local posY = realPos.y + self.cellSizeHeight / 2-spaceY/2
                    verticalLine:setPosition(realPos.x, posY)
                    verticalLine:setScaleX(spaceY)
                    verticalLine:setRotation(90)
                    verticalLine:setAnchorPoint(0.5, 0.5)

                    --红线
                    if not isLock then
                        local verticalRedLine = CCSprite:create("College_u_Cable.png")
                        verticalRedLine:setPosition(realPos.x, posY)
                        verticalRedLine:setScaleX(spaceY)
                        self.scrollView:addChild(verticalRedLine)
                        verticalRedLine:setAnchorPoint(0.5, 0.5)
                        verticalRedLine:setZOrder(1)
                        verticalRedLine:setRotation(90)
                        RATalentMainPage:saveRedLine(value.id, currentLineCoordinate, verticalRedLine)--保存红线
                    end

                    --竖线两端的圆盘
                    local circlePlate1 = CCSprite:create("College_u_Connection.png")
                    if circlePlate1 then
                        circlePlate1:setPosition(realPos.x, posY + spaceY / 2)
                        RATalentMainPage.circlePlates[#RATalentMainPage.circlePlates +1] = circlePlate1--保存圆盘
                        self.scrollView:addChild(circlePlate1)
                        circlePlate1:setAnchorPoint(0.5, 0.5)
                        circlePlate1:setZOrder(5)
                    end
                    local circlePlate2 = CCSprite:create("College_u_Connection.png")
                    if circlePlate2 then
                        circlePlate2:setPosition(realPos.x, posY - spaceY / 2)
                        RATalentMainPage.circlePlates[#RATalentMainPage.circlePlates +1] = circlePlate2--保存圆盘
                        self.scrollView:addChild(circlePlate2)
                        circlePlate2:setAnchorPoint(0.5, 0.5)
                        circlePlate2:setZOrder(5)
                    end

                    RATalentMainPage:saveLine(value.id, currentLineCoordinate, verticalLine)--保存黑线
                end

                local connectTalentIds = Utilitys.Split(value.connect, "_")
                for i=1, #connectTalentIds do
                    currentLineCoordinate.y = cellSitePos[2] - 1
                    local connectTalentId = tonumber(connectTalentIds[i])
                    local connectSite = Utilitys.Split(player_talent_conf[connectTalentId].site, "_")
                    local connectSitePos = {}
                    connectSitePos[1] = tonumber(connectSite[1])
                    connectSitePos[2] = tonumber(connectSite[2])
                    local isLock = RATalentManager.isTalentLock(tonumber(connectTalentId))--判断天赋是否解锁

                    if connectSitePos[1] ~= cellSitePos[1] then--横线
                        --x不相等
                        local dur = 1--判断横线方向，向左还是向右
                        if connectSitePos[1] < cellSitePos[1] then
                            dur = -1
                        end
                        for j = cellSitePos[1]+dur, connectSitePos[1], dur do
                            currentLineCoordinate.x = j
                            if not RATalentMainPage:isLineExist(value.id, currentLineCoordinate) then
                                local horizonlLine = CCSprite:create("CollegePage/College_u_Cable_BG.png")
                                local size = horizonlLine:getContentSize()
                                self.scrollView:addChild(horizonlLine)
                                local tmpPoint = ccp((j-cellSitePos[1])*spaceX - dur*spaceX / 2, -spaceY+self.cellSizeHeight / 2)
                                local pos = ccpAdd(realPos ,tmpPoint)
                                tmpPoint:delete()
                                horizonlLine:setPosition(pos)
                                horizonlLine:setScaleX(spaceX)
                                horizonlLine:setAnchorPoint(0.5, 0.5)
                                RATalentMainPage:saveLine(value.id, currentLineCoordinate, horizonlLine)

                                --红线
                                if not isLock then
                                    local horizonRedLine = CCSprite:create("College_u_Cable.png")
                                    horizonRedLine:setPosition(pos)
                                    horizonRedLine:setScaleX(spaceX)
                                    self.scrollView:addChild(horizonRedLine)
                                    horizonRedLine:setAnchorPoint(0.5, 0.5)
                                    horizonRedLine:setZOrder(1)
                                    RATalentMainPage:saveRedLine(value.id, currentLineCoordinate, horizonRedLine)
                                end

                            end
                        end
                    end


                    if connectSitePos[2] ~= cellSitePos[2] - 1 then--竖线
                        for m=cellSitePos[2] - 2, connectSitePos[2], -1 do
                            currentLineCoordinate.y = m
                            if not RATalentMainPage:isLineExist(value.id, currentLineCoordinate) then
                                local verticalLine = CCSprite:create("CollegePage/College_u_Cable_BG.png")
                                local size = verticalLine:getContentSize()
                                self.scrollView:addChild(verticalLine)
                                local posOffset = ccp(spaceX*(currentLineCoordinate.x - cellSitePos[1]), self.cellSizeHeight / 2+(currentLineCoordinate.y-cellSitePos[2])*spaceY + spaceY/2   )
                                local pos = ccpAdd(realPos, posOffset)
                                posOffset:delete()
                                verticalLine:setPosition(pos)
                                verticalLine:setScaleX(spaceY)
                                verticalLine:setRotation(90)
                                verticalLine:setAnchorPoint(0.5, 0.5)


                                --红线
                                if not isLock then
                                    local verticalRedLine = CCSprite:create("College_u_Cable.png")
                                    verticalRedLine:setPosition(pos)
                                    verticalRedLine:setScaleX(spaceY)
                                    self.scrollView:addChild(verticalRedLine)
                                    verticalRedLine:setAnchorPoint(0.5, 0.5)
                                    verticalRedLine:setZOrder(1)
                                    verticalRedLine:setRotation(90)
                                    RATalentMainPage:saveRedLine(value.id, currentLineCoordinate, verticalRedLine)
                                end

                                --竖线两端的圆盘
                                local circlePlate1 = CCSprite:create("College_u_Connection.png")
                                if circlePlate1 then
                                    circlePlate1:setPosition(pos.x, pos.y + spaceY / 2)
                                    RATalentMainPage.circlePlates[#RATalentMainPage.circlePlates +1] = circlePlate1
                                    self.scrollView:addChild(circlePlate1)
                                    circlePlate1:setAnchorPoint(0.5, 0.5)
                                    circlePlate1:setZOrder(5)
                                end
                                local circlePlate2 = CCSprite:create("College_u_Connection.png")
                                if circlePlate2 then
                                    circlePlate2:setPosition(pos.x, pos.y - spaceY / 2)
                                    RATalentMainPage.circlePlates[#RATalentMainPage.circlePlates +1] = circlePlate2
                                    self.scrollView:addChild(circlePlate2)
                                    circlePlate2:setAnchorPoint(0.5, 0.5)
                                    circlePlate2:setZOrder(5)
                                end

                                RATalentMainPage:saveLine(value.id, currentLineCoordinate, verticalLine)
                            end
                        end
                    end
                end
            end
        end
    end

    --适配Y位置
    for talentId, cell in pairs(self.allCells) do
        local posY = cell:getPositionY()
        posY = posY - offsetY
        cell:setPositionY(posY)

        local lines = self.talentLines[talentId]
        if lines ~= nil then
            for _, line in pairs(lines) do
                local lineY = line:getPositionY()
                lineY = lineY- offsetY
                line:setPositionY(lineY)
            end
        end

        --红线
        local redLines = self.talentRedLines[talentId]
        if redLines ~= nil then
            for _, line in pairs(redLines) do
                local lineY = line:getPositionY()
                lineY = lineY- offsetY
                line:setPositionY(lineY)
            end
        end
    end

    for i=1, #RATalentMainPage.circlePlates do
        if RATalentMainPage.circlePlates[i] ~= nil then
            local circleY = RATalentMainPage.circlePlates[i]:getPositionY()
            circleY = circleY - offsetY
            RATalentMainPage.circlePlates[i]:setPositionY(circleY)
        end
    end

    local viewHeight = self.scrollView:getViewSize().height
    local contentSizeHeight = contentSizeHeight + self.cellSizeHeight
    if RATalentMainPage.svContentOffset ~= nil then
        self.scrollView:setContentOffset(RATalentMainPage.svContentOffset)
        RATalentMainPage.svContentOffset = nil
    else
        local tmpPoint = ccp(0,viewHeight - contentSizeHeight)
        self.scrollView:setContentOffset(tmpPoint)
        tmpPoint:delete()
    end
    self.scrollView:setContentSize(CCSize(contentSizeWidth, contentSizeHeight))
end


--添加cell进scrollview
function RATalentMainPage:addSkillCell(id, realPos)
    local cell = CCBFileCell:create()
	cell:setCCBFile("RALordSkillCell.ccbi")

    local listener = RASkillCellListener:new({skillId = id, skillType = RATalentMainPage.currTalentType})
    cell:registerFunctionHandler(listener)
    self.scrollView:addCell(cell)
    self.allCells[id] = cell
    local contentSizeY = cell:getContentSize().height
    --设置cellsize
    if RATalentMainPage.cellSizeHeight < contentSizeY then
        RATalentMainPage.cellSizeHeight = contentSizeY
    end
    cell:setPosition(realPos)
    cell:setZOrder(10)--设置cell的zorder为10，本页面最上层
end

function RATalentMainPage:runBtnAction()
--RATalentMainPage.fightBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mFightSkillBtn")
--    RATalentMainPage.developBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mDevelopSkillBtn")
    if RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_FIGHT then
        if RATalentMainPage.oldTalentType == RAGameConfig.TalentTypes.TALENT_DEVELOP then
            if RATalentMainPage.fightBtn ~= nil then
                local tmpPoint = ccp(0, 4)
                local moveUp = CCMoveBy:create(0.1, tmpPoint)
                tmpPoint:delete()
                RATalentMainPage.fightBtn:runAction(moveUp)
            end
            if RATalentMainPage.developBtn ~= nil then
                local tmpPoint = ccp(0, -4)
                local moveDown = CCMoveBy:create(0.1, tmpPoint)
                RATalentMainPage.developBtn:runAction(moveDown)
                tmpPoint:delete()
            end
        elseif RATalentMainPage.oldTalentType == RAGameConfig.TalentTypes.TALENT_FIGHT then
           
        else
            if RATalentMainPage.fightBtn ~= nil then
                local tmpPoint = ccp(0, 4)
                local moveUp = CCMoveBy:create(0.1, tmpPoint)
                tmpPoint:delete()
                RATalentMainPage.fightBtn:runAction(moveUp)
            end
        end
        
    elseif RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_DEVELOP then
         if RATalentMainPage.oldTalentType == RAGameConfig.TalentTypes.TALENT_FIGHT then
            if RATalentMainPage.developBtn ~= nil then
                local tmpPoint = ccp(0, 4)
                local moveUp = CCMoveBy:create(0.1, tmpPoint)
                tmpPoint:delete()
                RATalentMainPage.developBtn:runAction(moveUp)
            end
            if RATalentMainPage.fightBtn ~= nil then
                local tmpPoint = ccp(0, -4)
                local moveDown = CCMoveBy:create(0.1,tmpPoint)
                tmpPoint:delete()
                RATalentMainPage.fightBtn:runAction(moveDown)
            end
        elseif RATalentMainPage.oldTalentType == RAGameConfig.TalentTypes.TALENT_DEVELOP then
           
        else
            if RATalentMainPage.developBtn ~= nil then
                local tmpPoint = ccp(0, 4)
                local moveUp = CCMoveBy:create(0.1, tmpPoint)
                tmpPoint:delete()
                RATalentMainPage.developBtn:runAction(moveUp)
            end
        end
    end
end

function RATalentMainPage:onBackBtn()
    RARootManager.ClosePage("RATalentMainPage")
end

function RATalentMainPage:Exit()

    --刷新装备页面天赋按钮上的红点
    local RALordMainPage = RARequire("RALordMainPage")
    RALordMainPage:refreshTalentRedPoint()

    basePos:delete()
    basePos = nil
    baseRelativePos:delete()
    baseRelativePos = nil
    self:removeHandler()
    RATalentMainPage.talentLines = {}
    RATalentMainPage.talentRedLines = {}
    RATalentMainPage.allCells = {}
    RATalentMainPage.circlePlates = {}
    RATalentMainPage.fightBtn:setPosition(self.fightBtnPos.x, self.fightBtnPos.y)
    RATalentMainPage.developBtn:setPosition(self.developBtnPos.x, self.developBtnPos.y)
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(RATalentMainPage)
    self.ccbfile = null
end

function RATalentMainPage:onFightSkillBtn()
    if RATalentMainPage.fightBtn then
        RATalentMainPage.fightBtn:setHighlighted(true)
    end
    if RATalentMainPage.developBtn then
        RATalentMainPage.developBtn:setHighlighted(false)
    end
    if RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_FIGHT  then
        return
    end
    RATalentMainPage.oldTalentType = RATalentMainPage.currTalentType
    RATalentMainPage.currTalentType = RAGameConfig.TalentTypes.TALENT_FIGHT 
    RATalentMainPage:runBtnAction()
    RATalentMainPage:refreshPage()
end

function RATalentMainPage:onRevertPoint()
    self.svContentOffset = self.scrollView:getContentOffset()
    local confirmData = {}
    confirmData.labelText = _RALang("@TalentRevertLabel")
    confirmData.title = ""
    confirmData.yesNoBtn = true
    confirmData.resultFun = function (isOk)
        if isOk then
            local msg = Talent_pb.HPTalentClearReq()
            if RATalentMainPage:getResetToolNum() > 0 then
                self.hasResetTalentTools = true
            else
                self.hasResetTalentTools = false
            end
            msg.useGold = not self.hasResetTalentTools
            msg.itemId = Const_pb.ITEM_TALENT_CLEAR
            RANetUtil:sendPacket(HP_pb.TALENT_CLEAR_C, msg)
        end
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData)
end

function RATalentMainPage:sendTalentClearReq()
    local msg = Talent_pb.HPTalentClearReq()
    msg.useGold = true
    msg.itemId = Const_pb.ITEM_TALENT_CLEAR
    RANetUtil:sendPacket(HP_pb.TALENT_CLEAR_C, msg)
end

function RATalentMainPage:onDevelopSkillBtn()
    if RATalentMainPage.fightBtn then
        RATalentMainPage.fightBtn:setHighlighted(false)
    end
    if RATalentMainPage.developBtn then
        RATalentMainPage.developBtn:setHighlighted(true)
    end

    if RATalentMainPage.currTalentType == RAGameConfig.TalentTypes.TALENT_DEVELOP  then
        return
    end
    RATalentMainPage.oldTalentType = RATalentMainPage.currTalentType
    RATalentMainPage.currTalentType = RAGameConfig.TalentTypes.TALENT_DEVELOP 
    RATalentMainPage:runBtnAction()
    RATalentMainPage:refreshPage()

    
end