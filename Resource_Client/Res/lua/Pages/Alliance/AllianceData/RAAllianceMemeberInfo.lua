--联盟成员信息
RARequire('extern')

local RAAllianceMemeberInfo = class('RAAllianceMemeberInfo',{
            playerId = "",			--玩家ID
		    playerName = "",			--玩家名称
		    authority = 0,	--玩家权限
		    power = 0,			--玩家战力
            icon = 0,   --icon
            online = false, --是否在线
            offlineTime = 0, --最后一次下线时间,在线为0
            x = 0,--坐标
            y = 0,--
            buildingLevel = 0,--大本等级
            officer = 0, -- 官职
            isSendGift = false -- 是否被大总统发过礼包
    })

--根据PB初始化数据
function RAAllianceMemeberInfo:initByPb(memeberInfoPb)
	self.playerId = memeberInfoPb.playerId
	self.playerName  = memeberInfoPb.playerName
	self.authority  = memeberInfoPb.authority
	self.power  = memeberInfoPb.power
    self.icon  = memeberInfoPb.icon
    self.online  = memeberInfoPb.online
    self.offlineTime = memeberInfoPb.offlineTime
    self.x = memeberInfoPb.x
    self.y = memeberInfoPb.y
    self.buildingLevel = memeberInfoPb.buildingLevel
    self.officer = memeberInfoPb.officer or 0
    self.isSendGift = memeberInfoPb.isSendGift or false
end

function RAAllianceMemeberInfo:ctor(...)

end 

return RAAllianceMemeberInfo