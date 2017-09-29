--TO:联盟战争页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
local RANewAllianceWarCellHelper = RARequire('RANewAllianceWarCellHelper')
local RABuildManager = RARequire("RABuildManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local Utilitys = RARequire('Utilitys')

local RANewAllianceWarPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh then
        local showType = message.showType
        RANewAllianceWarPage:setCurrentPage(showType)
    end
end

function RANewAllianceWarPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, OnReceiveMessage)
end

function RANewAllianceWarPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, OnReceiveMessage)    
end

function RANewAllianceWarPage:Enter()	
	local ccbfile = UIExtend.loadCCBFile("RAAllianceWarPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mInviteListSV")

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)

    -- title
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")    
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle', _RALang("@AllianceWarTitle"))

    --红点
    UIExtend.setNodesVisible(self.ccbfile,{
        mWarGatherTipsNode = false,
        mWarAttackTipsNode = false,
        mWarDefendTipsNode = false,
        mWarStationedTipsNode = false,
        })
    
    UIExtend.setNodesVisible(self.ccbfile,{
        mTabBtnNode = true,
        mWarHistoryBtnNode = true
        })

    --初始化标签页三个按钮
    self.tabArr = {} --三个分页签
    self.tabArr[GuildWar_pb.GUILD_WAR_MASS] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mGatherTabBtn')
    self.tabArr[GuildWar_pb.GUILD_WAR_ATTACK] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mAttackTabBtn')
    self.tabArr[GuildWar_pb.GUILD_WAR_DEFENCE] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mDefendTabBtn')
    self.tabArr[GuildWar_pb.GUILD_WAR_QUARTERED] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mStationedTabBtn')
    
    self:onGatherTabBtn()

    self:registerMessageHandlers()
end


function RANewAllianceWarPage:Exit()
    self:unregisterMessageHandlers()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end


function RANewAllianceWarPage:onGatherTabBtn()
	self:setCurrentPage(GuildWar_pb.GUILD_WAR_MASS)
end

function RANewAllianceWarPage:onAttackTabBtn()
	self:setCurrentPage(GuildWar_pb.GUILD_WAR_ATTACK)
end

function RANewAllianceWarPage:onDefendTabBtn()
	self:setCurrentPage(GuildWar_pb.GUILD_WAR_DEFENCE)
end

function RANewAllianceWarPage:onStationedTabBtn()
    self:setCurrentPage(GuildWar_pb.GUILD_WAR_QUARTERED)
end


--进入战争记录页面
function RANewAllianceWarPage:onWarHistoryBtn()
    RARootManager.OpenPage('RAAllianceWarHistoryPage')
end


function RANewAllianceWarPage:mAllianceCommonCCB_onBack()
    RARootManager.ClosePage('RANewAllianceWarPage')
end


--设置当前Page
function RANewAllianceWarPage:setCurrentPage(pageType)
    RANewAllianceWarManager:ClearRedListByType(pageType)
	self.curPageType = pageType

	for k,v in pairs(self.tabArr) do
        v:setEnabled(pageType ~= k)		
    end 
    --刷新红点    
    local massCount = RANewAllianceWarManager:GetRedPointNum(GuildWar_pb.GUILD_WAR_MASS)
    local atkCount = RANewAllianceWarManager:GetRedPointNum(GuildWar_pb.GUILD_WAR_ATTACK)
    local defCount = RANewAllianceWarManager:GetRedPointNum(GuildWar_pb.GUILD_WAR_DEFENCE)
    local quarteredCount = RANewAllianceWarManager:GetRedPointNum(GuildWar_pb.GUILD_WAR_QUARTERED)

    if massCount <= 0 then
        UIExtend.setNodesVisible(self.ccbfile,{mWarGatherTipsNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mWarGatherTipsNode = true})
        UIExtend.setStringForLabel(self.ccbfile,{mWarGatherTipsNum = massCount})
    end

    if atkCount <= 0 then
        UIExtend.setNodesVisible(self.ccbfile,{mWarAttackTipsNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mWarAttackTipsNode = true})
        UIExtend.setStringForLabel(self.ccbfile,{mWarAttackTipsNum = atkCount})
    end

    if defCount <= 0 then
        UIExtend.setNodesVisible(self.ccbfile,{mWarDefendTipsNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mWarDefendTipsNode = true})
        UIExtend.setStringForLabel(self.ccbfile,{mWarDefendTipsNum = defCount})
    end

    if quarteredCount <= 0 then
        UIExtend.setNodesVisible(self.ccbfile,{mWarStationedTipsNode = false})
    else
        UIExtend.setNodesVisible(self.ccbfile,{mWarStationedTipsNode = true})
        UIExtend.setStringForLabel(self.ccbfile,{mWarStationedTipsNum = quarteredCount})
    end

    self:RefreshScrollView(pageType)
end

-- 刷新显示
function RANewAllianceWarPage:RefreshScrollView(showType)
    local datas, redDatas = RANewAllianceWarManager:GetCellDataByType(showType)
    local count = Utilitys.table_count(datas)
    if count > 0 then
        local index = 1
        local scrollView = self.scrollView
        scrollView:removeAllCell()
        for k,v in pairs(datas) do
            local oneCellHandler = RANewAllianceWarCellHelper:CreateCell(index, v)            
            local cell = CCBFileCell:create()
            cell:setCCBFile(oneCellHandler:GetCCBName())
            cell:registerFunctionHandler(oneCellHandler)
            cell:setIsScheduleUpdate(true)
            scrollView:addCell(cell)
            index = index + 1
        end
        self.mNoListLabel:setVisible(false) 
        self.scrollView:setVisible(true)
        scrollView:orderCCBFileCells()
    else
        self.scrollView:setVisible(false)
        UIExtend.setNodesVisible(self.ccbfile,{mTabBtnNode = true})
        UIExtend.setNodesVisible(self.ccbfile,{mWarHistoryBtnNode = true})
        self.mNoListLabel:setVisible(true) 
        if self.curPageType == GuildWar_pb.GUILD_WAR_MASS then
            self.mNoListLabel:setString(_RALang("@NoGatherWarTxt"))
        elseif self.curPageType == GuildWar_pb.GUILD_WAR_DEFENCE then
            self.mNoListLabel:setString(_RALang("@NoDefendWarTxt"))       
        elseif self.curPageType == GuildWar_pb.GUILD_WAR_ATTACK then
             self.mNoListLabel:setString(_RALang("@NoAttackWarTxt"))   
        elseif self.curPageType == GuildWar_pb.GUILD_WAR_QUARTERED then
             self.mNoListLabel:setString(_RALang("@NoStationedWarTxt"))   
        end
    end
end


return RANewAllianceWarPage