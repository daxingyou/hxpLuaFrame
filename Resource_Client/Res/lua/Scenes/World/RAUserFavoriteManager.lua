--region *.lua
--Date

local RAUserFavoriteManager =
{
	favList = {},
	orderList = {},
	isOrdered = {false, false, false},
	countList = {},
	coordList = {}
}

local World_pb = RARequire('World_pb')
local RAWorldMath = RARequire('RAWorldMath')
local FavType = RARequire('RAWorldConfig').FavoriteType

function RAUserFavoriteManager:ResetData()
	self.favList = {}
	self.orderList = {}
	self.isOrdered = {false, false, false}
	self.countList = {}
	self.coordList = {}
end

function RAUserFavoriteManager:addFavorite(msg)
	local favType = msg.tag
	if favType == nil then return end

	local favId = msg.favoriteId
	self:deleteFavorite(favId, favType)

	local favTb = self.favList[favType] or {}
	if favTb[favId] == nil then
		local orderTB = self.orderList[favType] or {}
		table.insert(orderTB, {id = favId, updateTime = msg.updateTime})
		self.orderList[favType] = orderTB
		self.countList[favType] = (self.countList[favType] or 0) + 1
	end

	favTb[favId] =
	{
		id = favId,
		type = favType,
		targetType = msg.type,
		name = msg.name,
		coord = {x = msg.posX, y = msg.posY, k = msg.serverId}
	}
	self.favList[favType] = favTb

	local coordId = RAWorldMath:GetMapPosId(msg.posX, msg.posY)
	self.coordList[coordId] = true
end

function RAUserFavoriteManager:isFavorite(mapPos)
	local coordId = RAWorldMath:GetMapPosId(mapPos)
	return self.coordList[coordId] == true
end

function RAUserFavoriteManager:getFavoriteList(favType)
	if self.isOrdered[favType] == false then
		self:_sortFavList(favType)
		self.isOrdered[favType] = true
	end

	local tb = {}
	for _, v in ipairs(self.orderList[favType]) do
		table.insert(tb, self.favList[favType][v.id])
	end
	return tb
end

function RAUserFavoriteManager:getFavoriteCount(favType)
	return self.countList[favType] or 0
end

function RAUserFavoriteManager:deleteFavorite(id, favType)
	for k, _type in pairs(FavType) do
		if _type ~= favType then
			local list = self.favList[_type] or {}
			local favInfo = list[id]
			if favInfo then
				local coordId = RAWorldMath:GetMapPosId(favInfo.coord)
				self.coordList[coordId] = nil
				self:_deleteFromOrderList(_type, id)
				self.favList[_type][id] = nil
				self.countList[_type] = self.countList[_type] - 1
				return
			end
		end
	end
end

function RAUserFavoriteManager:_deleteFromOrderList(favType, id)
	for k, info in ipairs(self.orderList[favType] or {}) do
		if info and info.id == id then
			table.remove(self.orderList[favType], k)
			return
		end
	end
end

function RAUserFavoriteManager:_sortFavList(favType)
	local orderTB = self.orderList[favType] or {}
	if #orderTB > 1 then
		table.sort(orderTB, function (val_1, val_2)
			return val_1.updateTime < val_2.updateTime
		end)
	end
	self.orderList[favType] = orderTB
end

return RAUserFavoriteManager

--endregion
