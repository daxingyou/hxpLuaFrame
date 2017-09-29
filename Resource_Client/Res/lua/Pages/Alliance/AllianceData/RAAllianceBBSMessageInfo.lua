--联盟留言板
RARequire('extern')

local RAAllianceBBSMessageInfo = class('RAAllianceBBSMessageInfo',{
            icon = 0,			--头像
		    guildTag = nil,	    --联盟简称
		    playerName = '',	--名字
		    playerId = '',		--人员ID
		    time = 0,			--时间
		    message = '',		--联盟信息
		    power = 0			--战力
    })

--根据PB初始化数据
function RAAllianceBBSMessageInfo:initByPb(pb)
	self.icon = pb.icon
	self.playerName  = pb.playerName
	self.playerId  = pb.playerId
	self.time  = pb.time
	self.message  = pb.message
	self.power  = pb.power

	if pb:HasField("guildTag") then 
		self.guildTag = pb.guildTag
	else
		self.guildTag = nil 
	end 
end

function RAAllianceBBSMessageInfo:ctor(...)

end 


return RAAllianceBBSMessageInfo