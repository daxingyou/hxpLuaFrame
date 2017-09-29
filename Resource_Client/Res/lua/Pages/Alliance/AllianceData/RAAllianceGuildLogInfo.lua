--联盟日志
RARequire('extern')

local RAAllianceGuildLogInfo = class('RAAllianceGuildLogInfo',{
            logType = "",			--日志类型
		    param = "",			    --日志参数
		    time = 0,	            --日志时间
    })

--根据PB初始化数据
function RAAllianceGuildLogInfo:initByPb(guildLogInfo)
	self.logType = guildLogInfo.logType
	self.param  = guildLogInfo.param
	self.time  = guildLogInfo.time
end

function RAAllianceGuildLogInfo:ctor(...)

end 


return RAAllianceGuildLogInfo