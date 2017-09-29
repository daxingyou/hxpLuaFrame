-- RAAllianceSiloCellHelper.lua
-- 联盟核弹发射平台
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local RARootManager = RARequire('RARootManager')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RANetUtil = RARequire('RANetUtil')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local html_zh_cn = RARequire('html_zh_cn')
RARequire('MessageManager')
local HP_pb = RARequire('HP_pb')
local GuildManor_pb = RARequire('GuildManor_pb')
local World_pb = RARequire('World_pb')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire("common")
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local guild_const_conf = RARequire('guild_const_conf')
local RAQueueManager = RARequire('RAQueueManager')
local localObj = nil 

local RAAllianceSiloCellHelper = {}

local RAAllianceVoteCellHandler = {
    New = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    Register = function(self, ccbfile, index)
        self.ccbfile = ccbfile
        self.index = index
        if ccbfile ~= nil then
            ccbfile:registerFunctionHandler(self)
        end
    end,

    onKeyBtn = function(self)
        if self.voteData == nil then
            return
        end
        RAAllianceProtoManager:reqNulcearVote(self.voteData.index)
    end,

    updateVote = function(self, voteData)
        self.voteData = voteData
        self.mKeyBtn = UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mKeyBtn')

        self.mPilotLampGreen = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mPilotLampGreen')
        self.mPilotLampRed = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mPilotLampRed')
        self.mConfirmor = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mConfirmor')
        self.mNoManPic = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mNoManPic')
        if self.voteData ==nil or self.voteData.name == nil then --不需要投票
            self.mKeyBtn:setEnabled(false)
            self.mPilotLampGreen:setVisible(false)
            self.mPilotLampRed:setVisible(false)
            self.mConfirmor:setString('')
            self.mNoManPic:setVisible(true)
        else 
            if self.voteData.name == '' then  --还没投票
                self.mPilotLampGreen:setVisible(false)
                self.mPilotLampRed:setVisible(true)
                 self.mKeyBtn:setEnabled(true)
            else
                self.mPilotLampGreen:setVisible(true)
                self.mPilotLampRed:setVisible(false)
                self.mKeyBtn:setEnabled(false)
            end 
            self.mNoManPic:setVisible(false)
            self.mConfirmor:setString(self.voteData.name)
        end 
    end,

    Release = function(self)
        if self.ccbfile then
            self.ccbfile:unregisterFunctionHandler()
        end
    end
}

function RAAllianceSiloCellHelper:CreateVoteHandler(ccbfile, index)    
    local handler = RAAllianceVoteCellHandler:New()
    handler:Register(ccbfile, index)    
    return handler
end


return RAAllianceSiloCellHelper