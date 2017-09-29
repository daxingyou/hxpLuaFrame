
--联盟标题栏
local RAAllianceBaseListPage = RARequire("RAAllianceBaseListPage")
local RAAllianceMemberTitleCell = RARequire('RAAllianceMemberTitleCell')
local RAAllianceMemberContentCell = RARequire('RAAllianceMemberContentCell')
local RAAllianceLeaderContentCell = RARequire('RAAllianceLeaderContentCell')
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local RANetUtil = RARequire('RANetUtil')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')

local HP_pb = RARequire('HP_pb')
local RAAllianceMemberPage = class('RAAllianceMemberPage',RAAllianceBaseListPage)


function RAAllianceMemberPage:ctor(...)
    self.ccbfileName = "RAAllianceMembersPage.ccbi"
    self.scrollViewName = 'mCreeateListSV'
    self.titleCellClass = RAAllianceMemberTitleCell
    self.contentCellClass = RAAllianceMemberContentCell
    self.onlineInfos = {}
    -- self.titleCellDatas = 
end

function RAAllianceMemberPage:getContentCellClass(index)

    if index == 1 then 
        return RAAllianceLeaderContentCell
    else 
        return self.contentCellClass
    end 
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_AlliancePage.MSG_RefreshMemberPage then
       RAAllianceProtoManager:getGuildMemeberInfoReq(RAAllianceManager.selfAlliance.id)
    end 
end

function RAAllianceMemberPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_AlliancePage.MSG_RefreshMemberPage,OnReceiveMessage)
end

function RAAllianceMemberPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_AlliancePage.MSG_RefreshMemberPage,OnReceiveMessage)
end

function RAAllianceMemberPage:getContentCellData(titleIndex,index)
    local cellData = {}
    cellData[1] = self.contentDatasArr[titleIndex][2*index-1]
    if self.contentDatasArr[titleIndex][2*index] ~= nil then 
        cellData[2] = self.contentDatasArr[titleIndex][2*index]
    end 
    cellData.contentType = self.contentType
    return cellData
end

function RAAllianceMemberPage:onInfoCCB()
    RARootManager.OpenPage("RAAlliancePermissionsPage")
end

function RAAllianceMemberPage:getTitleCellData(index)
    local titleData = {}
    titleData.name = self.titleCellDatas[index]

    if self.contentType == 0 then 
        titleData.onlineInfo = self.onlineInfos[index].onlineNum .. '/' .. self.onlineInfos[index].totalNum
    else
        titleData.onlineInfo = '0/' .. self.onlineInfos[index].totalNum
    end 
    return titleData
end

function RAAllianceMemberPage:getContentCellNum(index)
    local num = #self.contentDatasArr[index]
    return math.ceil(num/2)
end

function RAAllianceMemberPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then --获得联盟成员
        local memberInfos,leaderNames = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
        self:refreshUI({memberInfos=memberInfos,leaderNames = leaderNames,contentType=self.contentType})
    end
end

--子类实现
function RAAllianceMemberPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETMEMBERINFO_S, self)
end

function RAAllianceMemberPage:refreshUI(data)
    -- self:init(data)
    self.titleCellDatas = data.leaderNames
    self:initContents(data)
    self:refreshCells()
end

function RAAllianceMemberPage:initContents(data)
    -- body
    self.contentDatasArr = {}

    for i=1,5 do
        self.contentDatasArr[i] = {}
    end

    for k,v in pairs(data.memberInfos) do
        local arr = self.contentDatasArr[6-v.authority]
        arr[#arr+1] = v 
    end

    for i=1,5 do
        local arr = self.contentDatasArr[i]
        table.sort( arr, function (v1,v2)
                if v1.offlineTime == 0 and v2.offlineTime ~= 0 then 
                    return true
                elseif v1.offlineTime ~= 0 and v2.offlineTime == 0 then
                    return false 
                elseif v1.power > v2.power then 
                    return true 
                end 
                return false 
            end)
        self.contentDatasArr[i] = arr
    end

    self.onlineInfos = {}
    for i=1,5 do
        local onlineInfo = {}
        onlineInfo.totalNum = #self.contentDatasArr[i]
        local onlineNum = 0
        for k,v in pairs(self.contentDatasArr[i]) do
            if v.offlineTime == 0 then 
                onlineNum = onlineNum+1
            end 
        end
        onlineInfo.onlineNum = onlineNum 
        self.onlineInfos[i] = onlineInfo
    end
end

function RAAllianceMemberPage:init(data)

    self:initTitleCellDatas(data.leaderNames)
    self.contentType = data.contentType
    self:initContents(data)
end

-- function RAAllianceMemberPage:onAllianceLetterBtn( ... )
--     sef:clickTitle()
--  end 

-- return RAAllianceInfo
return RAAllianceMemberPage.new()