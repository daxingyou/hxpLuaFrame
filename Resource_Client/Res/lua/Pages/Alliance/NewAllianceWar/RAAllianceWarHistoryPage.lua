--TO:联盟战争记录页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local HP_pb = RARequire("HP_pb")
local GuildWar_pb = RARequire("GuildWar_pb")

local RAAllianceWarHistoryPage = BaseFunctionPage:new(...)

function RAAllianceWarHistoryPage:Enter()
	-- body
	local ccbfile = UIExtend.loadCCBFile("RAAllianceWarHistoryPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mHistoryListSV")

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)

    --TOP
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self:initTopTitle()

    self:RegisterPacketHandler(HP_pb.GUILD_WAR_RECORD_S)
    --self:addCell({})

    RAAllianceProtoManager:warRecordReq()
end   

function RAAllianceWarHistoryPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_WAR_RECORD_S then --战争记录信息
        local msg = GuildWar_pb.HPGuildWarRecordResp()
        msg:ParseFromString(buffer)

        local RAAllianceWarPlayerInfo = RARequire("RAAllianceWarPlayerInfo")
        self.warRecordInfos = {}
        for i = 1 ,#msg.guildWarRecord do 
            local t = {}
            t.warType = msg.guildWarRecord[i].warType
            local attPlayerInfo = RAAllianceWarPlayerInfo.new()
	        attPlayerInfo:initByPb(msg.guildWarRecord[i].attPlayer)
            t.attPlayerInfo = attPlayerInfo

            local defPlayerInfo = RAAllianceWarPlayerInfo.new()
	        defPlayerInfo:initByPb(msg.guildWarRecord[i].defPlayer)
            t.defPlayerInfo = defPlayerInfo

            t.winTimes = msg.guildWarRecord[i].winTimes
            t.warTime = msg.guildWarRecord[i].warTime

            self.warRecordInfos[#self.warRecordInfos + 1] = t

        end
        self:addCell()
    end
end

--初始化顶部
function RAAllianceWarHistoryPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceHistoryTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

function RAAllianceWarHistoryPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceWarHistoryPage:clearWarRecordDatas()
    if self.warRecordInfos then
        for k,v in pairs(self.warRecordInfos) do
           v = nil
        end
        self.warRecordInfos = nil
    end
end

function RAAllianceWarHistoryPage:Exit()
    self:clearWarRecordDatas()
    self.scrollView:removeAllCell()
    self:RemovePacketHandlers()
    UIExtend.unLoadCCBFile(self)
end 


--cell begin
local RAAllianceWarHistoryCell = {}

function RAAllianceWarHistoryCell:new(o)
	-- body
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

function RAAllianceWarHistoryCell:onRefreshContent(ccbRoot)
	-- body
	if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile
    
    local index = self.mIndex
    local data = self.mData
    --icon
    --local headIcon = RAPlayerInfoManager.getHeadIcon(data.attPlayerInfo.icon)

    --warType 0为攻击类型，1为集结类型
    UIExtend.removeSpriteFromNodeParent(ccbfile, "mCellIconNode")
    if data.warType == 0 then
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode","Alliance_Icon_WarAtk.png")
    elseif data.warType == 1 then
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode","Alliance_Icon_WarGather.png") 
    elseif data.warType == 2 then
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode","Alliance_Icon_WarDef.png")        
    end

    --UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode",headIcon)

	if data.winTimes > 0 then
        local more = ""
        if data.winTimes > 1 then
            more = "X"..tostring(data.winTimes)
        end
		UIExtend.setStringForLabel(ccbfile,{mOffensiveState = _RALang("@VictoryStr")..more })
		UIExtend.setNodesVisible(ccbfile,{mOffensiveState = true})
		UIExtend.setNodesVisible(ccbfile,{mDefenderState = false})
	else
        local more = ""
        local winCount = data.winTimes*-1
        if winCount > 1 then
            more = "X"..tostring(winCount)
        end
		UIExtend.setStringForLabel(ccbfile,{mDefenderState = _RALang("@VictoryStr")..more})
		UIExtend.setNodesVisible(ccbfile,{mDefenderState = true})
		UIExtend.setNodesVisible(ccbfile,{mOffensiveState = false})
	end    
    local atkGuildTagStr = ""
    if data.attPlayerInfo.guildTag ~= "" then
        atkGuildTagStr = "("..data.attPlayerInfo.guildTag..")"
    end    
	UIExtend.setStringForLabel(ccbfile,{mOffensiveName = atkGuildTagStr..data.attPlayerInfo.playerName})

    local defGuildTagStr = ""
    if data.defPlayerInfo.guildTag ~= "" then
        defGuildTagStr = "("..data.defPlayerInfo.guildTag..")"
    end 
	UIExtend.setStringForLabel(ccbfile,{mDefenderName = defGuildTagStr..data.defPlayerInfo.playerName})

	self.endTime = data.warTime
	local curMilliTime = common:getCurMilliTime()
    local timeStamp = math.ceil((curMilliTime - self.endTime)/1000)
    --local timeStr = Utilitys.createTimeWithFormat(timeStamp)

    local timeStr = Utilitys.formatTime(self.endTime/1000)

    UIExtend.setStringForLabel(self.ccbfile, {mWarTime = timeStr})
end

---------------------

function RAAllianceWarHistoryPage:addCell()
	-- body
	self.scrollView:removeAllCell()
    if #self.warRecordInfos ~= 0 then
        local scrollView = self.scrollView
        for k,v in pairs(self.warRecordInfos) do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceWarHistoryCell.ccbi")
            
            local panel = RAAllianceWarHistoryCell:new({
                mIndex = k,
        	    mData = v
            })
            cell:registerFunctionHandler(panel)
            scrollView:addCell(cell)
        end
        self.scrollView:setVisible(true)
        self.mNoListLabel:setVisible(false) 
        scrollView:orderCCBFileCells()
     else
         self.scrollView:setVisible(false)
         self.mNoListLabel:setVisible(true) 
         self.mNoListLabel:setString(_RALang("@NoHistoryDataTxt"))
     end    
end

return RAAllianceWarHistoryPage