RARequire('extern')

local RAVector = class('RAVector',{
	x = 0,
	y = 0
})

function RAVector:init(vec)
	self.x = vec.x
	self.y = vec.y
end

--归零
function RAVector:Zero()
	self.x = 0
	self.y = 0
end

--是否是零向量
function RAVector:isZero()
	if self.x == 0 and self.y == 0 then 
		return true
	else
		return false
	end 
end

--长度
function RAVector:Length()
	return math.sqrt(self.x*self.x + self.y*self.y)
end

--长度的平方
function RAVector:LengthSq()
	return self.x*self.x + self.y*self.y
end

--点乘
function RAVector:Dot(vec)
	return self.x*vec.x + self.y*vec.y
end

--如果是顺时针方向，返回true,逆时针返回false
function RAVector:Sign(vec)
	if(self.y*vec.x>self.x*vec.y)
		return false
	else
		return true
	end
end

--垂直向量
function RAVector:Perp()
	local perp = RAVector.new()
	perp.x = -self.y
	perp.y = self.x
	return perp
end

return RAVector