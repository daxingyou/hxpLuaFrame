--联盟商店信息
RARequire('extern')
local RAAllianceShopItem = RARequire('RAAllianceShopItem')

local RAAllianceShopInfo = class('RAAllianceShopInfo',{
		nextRefreshTime = 0,
		shopItems = nil, 
		historyScore = 0,
		contribution = 0
    })

--根据PB初始化数据
function RAAllianceShopInfo:initByPb(pb)
	self.nextRefreshTime = pb.nextRefreshTime
	self.historyScore = pb.historyScore
	self.contribution = pb.contribution
	self.shopItems = {}
	for i=1,#pb.shopItem do
		local itemInfo = RAAllianceShopItem.new()
		itemInfo:initByPb(pb.shopItem[i])
		self.shopItems[i] = itemInfo
	end
end


function RAAllianceShopInfo:ctor(...)

end 

return RAAllianceShopInfo
