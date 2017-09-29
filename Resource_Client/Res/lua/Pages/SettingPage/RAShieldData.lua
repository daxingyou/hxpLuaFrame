--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
RARequire('extern')
--// 被屏蔽的玩家信息
--message ShieldPlayerInfo
--{
--	required string playerId 	= 1;
--	required string name 		= 2;
--	required int32  icon 		= 3;	//头像id
--	required int32  battlePoint	= 4;	//战斗力
--	required string guildName   = 5;    //联盟名称
--}
local RAShieldData = class('RAShieldData',{
    playerId = "",
    name = "",
    icon = 1,
    battlePoint = 0,
    guildName = ""
})

function RAShieldData:initByPB(data)
    self.playerId = data.playerId
    self.name = data.name
    self.icon = data.icon
    self.battlePoint = data.battlePoint
    self.guildName = data.guildName
end

function RAShieldData:ctor(...)
    
end 

return RAShieldData
--endregion
