--联盟购买日志信息
RARequire('extern')

local RAAllianceBuyRecord = class('RAAllianceBuyRecord',{
		name = "",
		itemId = 0, 
		count = 0,
		cost = 0,
		time = 0,
    })

--根据PB初始化数据
function RAAllianceBuyRecord:initByPb(pb)
	self.name = pb.name
	self.itemId = pb.itemId
	self.count = pb.count
	self.cost = pb.cost
	self.time = pb.time
end


function RAAllianceBuyRecord:ctor(...)

end 

return RAAllianceBuyRecord
