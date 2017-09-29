
--联盟玩家战争信息
RARequire('extern')

local RAAllianceGiftMoneyInfo = class('RAAllianceGiftMoneyInfo',{
			id = nil,				-- 红包id
            sponsorId = 0,			--发起人id
            sponsorName = "", 		--发起者姓名
		    state = 1,				--红包状态 1;//可抢阶段 2;//拼手气阶段 3;//已结束
		    createTime = 0, 		--发出时间
            totalGold = 0,			-- 红包金额
            isOpen = 0,				-- 是否开启成功
            sponsorGold = 0, 		-- 发起者收益
            stageEndTime = 0,		--阶段剩余时间
            hasOpen = false,        --是否开启过
            hasLuckyTry = false     --是否拼过手气
})

--根据PB初始化数据
function RAAllianceGiftMoneyInfo:initByPb(redPacketInfoPb)
	self.id = redPacketInfoPb.id
	self.sponsorId  = redPacketInfoPb.sponsorId
	self.sponsorName  = redPacketInfoPb.sponsorName
	self.state  = redPacketInfoPb.state
	self.createTime  = redPacketInfoPb.createTime
    self.totalGold  = redPacketInfoPb.totalGold
    self.isOpen  = redPacketInfoPb.isOpen
    self.sponsorGold = redPacketInfoPb.sponsorGold
    self.stageEndTime = redPacketInfoPb.stageEndTime
    self.hasOpen = redPacketInfoPb.hasOpen
    self.hasLuckyTry = redPacketInfoPb.hasLuckyTry
end

function RAAllianceGiftMoneyInfo:ctor(...)

end 


return RAAllianceGiftMoneyInfo
