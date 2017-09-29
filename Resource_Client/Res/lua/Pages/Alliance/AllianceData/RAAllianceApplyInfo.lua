--收到申请信息
RARequire('extern')

local RAAllianceApplyInfo = class('RAAllianceApplyInfo',{
            playerId = "",			--玩家ID
		    playerName = "",			--玩家名称
		    power = 0,	--玩家战力
		    vip = 0,			--VIP
            language = "",   --语言
            icon = 0, --头像
            buildingLevel = 0, --建筑等级
            commonderLevel = 0, --指挥官等级
            guildTag = "", --工会旗帜
            guildName = "",
            vipStatus = false, --vip是否激活
            killEnemy = 0  --杀敌数

    })

--根据PB初始化数据
function RAAllianceApplyInfo:initByPb(applyInfoPb)
	self.playerId = applyInfoPb.playerId
	self.playerName  = applyInfoPb.playerName
	self.power  = applyInfoPb.power
	self.vip  = applyInfoPb.vip
	self.language  = applyInfoPb.language
    self.icon  = applyInfoPb.icon
    self.buildingLevel  = applyInfoPb.buildingLevel
    self.commonderLevel = applyInfoPb.commonderLevel
    self.guildTag = applyInfoPb.guildTag
    self.guildName = applyInfoPb.guildName
    self.vipStatus = applyInfoPb.vipStatus
    self.killEnemy = applyInfoPb.killEnemy
end

function RAAllianceApplyInfo:ctor(...)

end 


return RAAllianceApplyInfo