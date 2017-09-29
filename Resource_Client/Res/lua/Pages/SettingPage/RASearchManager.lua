--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RANetUtil = RARequire("RANetUtil")
local Player_pb = RARequire("Player_pb")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RARootManager = RARequire("RARootManager")
local Page_Index = {
    Player = 1,
    Alliance = 2
}
local RASearchManager = {
    
    playerSearchData = {},
    allianceSearchData = {},

    reset = function (self)
        self.playerSearchData = {}
        self.allianceSearchData = {}
    end,

    --search player 
    searchPlayer = function(self, playerName)
        if playerName == nil or playerName == "" then return end
        local RAStringUtil =  RARequire('RAStringUtil')
        playerName = RAStringUtil:trim(playerName)

        if #playerName == 0 then 
            return 
        end 
        local cmd = Player_pb.GetPlayerBasicInfoReq()
        cmd.name = playerName
        RANetUtil:sendPacket(HP_pb.PLAYER_GETGLOBALPLAYERINFOBYNAME_C, cmd)
    end,

    --onRecievePlayerPacket 
    onRecievePlayerPacket = function(self, buffer)
         local msg = Player_pb.GetPlayerBasicInfoResp()
        msg:ParseFromString(buffer)
        self.playerSearchData = msg.info
        RARootManager.refreshPage("RASettingSearchPage")
    end,

    --search alliance
    searchAlliance = function(self, allianceName)
        RAAllianceProtoManager:getSearchGuildListReq(allianceName)
    end,

    --onRecieveAlliancePacket 
    onRecieveAlliancePacket = function(self, buffer)
        local searchArr = RAAllianceProtoManager:searchAllianceResp(buffer)
        self.allianceSearchData = searchArr
        RARootManager.refreshPage("RASettingSearchPage")
    end,

}

return RASearchManager
--endregion
