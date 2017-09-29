--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local Player_pb = RARequire("Player_pb")
local RANetUtil = RARequire("RANetUtil")
local RAShieldData = RARequire("RAShieldData")
local HP_pb = RARequire("HP_pb")
local RAShieldManager = {
    shieldList = {},
    reset = function (self)
        self.shieldList = {}
    end,
    OnReceivePacket = function (self,msg)
        self:reset()
        for i = 1, #msg.shieldPlayer,1 do
            local oneInfo = msg.shieldPlayer[i]
            local oneShieldData = RAShieldData:new()
            oneShieldData:initByPB(oneInfo)
            self.shieldList[oneInfo.playerId] = oneShieldData
        end
    end,
    --send shield cmd 
    sendOneShieldCmd = function(self,playerId)
        local msg = Player_pb.ShieldPlayerReq()
        msg.playerId = playerId
        RANetUtil:sendPacket(HP_pb.SHIELD_PLAYER_C, msg)
    end,
    --add one shield data in local mem, and send the packet
    addOneShieldData = function(self,oneInfo)
        local oneShieldData = RAShieldData:new()
        oneShieldData:initByPB(oneInfo)
        self.shieldList[oneInfo.playerId] = oneShieldData
    end,
    --remove one shield data in local mem, and send the packet
    removeOneShieldData = function(self,playerId)
        self.shieldList[playerId] = nil
        local msg = Player_pb.RemoveShieldPlayerReq()
        msg.playerId = playerId
        RANetUtil:sendPacket(HP_pb.REMOVE_SHIELD_C, msg)
    end,
    --send PresidengShield cmd 
    sendOnePresidengShieldCmd = function(self,playerId)
        local President_pb = RARequire("President_pb")
        local msg = President_pb.PresidentSilentPlayerReq()
        msg.playerId = playerId
        RANetUtil:sendPacket(HP_pb.PRESIDENT_MAKE_PLAYER_CILENT_C, msg)
    end,
}

return RAShieldManager
--endregion
