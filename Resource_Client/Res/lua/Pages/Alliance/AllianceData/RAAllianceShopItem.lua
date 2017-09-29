--联盟商店物品信息
RARequire('extern')

local RAAllianceShopItem = class('RAAllianceShopItem',{
		itemId = 0,
		count = nil, 
		price = 0,
		rare = 1,
		isRare = false,
		unlockLevel = 0,
    })

--根据PB初始化数据
function RAAllianceShopItem:initByPb(pb)
	self.itemId = pb.itemId
	self.count = pb.count
	self.price = pb.price
	self.rare = pb.rare
	if self.rare == 2 then
		self.isRare = true
	end
	self.unlockLevel = pb.unlockLevel
end


function RAAllianceShopItem:ctor(...)

end 

return RAAllianceShopItem
