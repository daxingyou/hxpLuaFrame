--region *.lua
--Date

local RAWorldVar = 
{
	MapVersion = 1,

	-- 格子坐标
	MapPos =
	{
		Self = {},			-- 自己主城
		Map = {},			-- 屏幕中心格子
		Migrate = nil,		-- 迁城目标

		ServerCenter = {},	-- 服务器同步城点时的中心点

		Core = nil,			-- 首都中心点
		BankCorner = nil,	-- 黑土地四角坐标		
		BankSize = nil,		-- 黑土地宽高

		CapitalCorner = nil	-- 首都四角坐标
	},

	-- tile map layer上的位置
	--MapPos.BankCorner =
	-- {
	-- 	left = {x = self.MapPos.Core.x - self.BankSize.x, y = self.MapPos.Core.y},
	-- 	right = {x = self.MapPos.Core.x + self.BankSize.x, y = self.MapPos.Core.y},
	-- 	top = {x = self.MapPos.Core.x, y = self.MapPos.Core.y - self.BankSize.y},
	-- 	bottom = {x = self.MapPos.Core.x, y = self.MapPos.Core.y + self.BankSize.y}
	-- }
	ViewPos =
	{
		Self = {},	
		Map = {},
		Center = {},

		Core = nil,
		BankCorner = nil,
		BankSize = nil,		-- 黑土地宽高
	},

	KingdomId =
	{
		Self = 1,
		Map = 1
	},

	BuildingId = 
	{
		Self = nil
	},

	AllowServerReq = false,

	-- 进入城外获取城点数据后跳转目标信息
	TargetInfo = nil,
	-- 对应坐标城点显示后显示Hud
	HudPos = nil,

	-- 当前视野内联盟领地id
	TerritoryId = 0,

	-- 往服务器发move协议，同步点数据时，服务器按此速度调整同步数据量
	MoveSpeed = 0,
	-- 实际同步速度
	SyncMoveSpeed = 0,

	-- 是否是移动结束
	IsMovingStop = false
}

local RAWorldMath = RARequire('RAWorldMath')

function RAWorldVar:Init()
	local playerInfo = RARequire('RAPlayerInfoManager').getWorldInfo()
    self.MapPos.Self = playerInfo.worldCoord
    self.KingdomId.Self = playerInfo.kingdomId
    self.BuildingId.Self = RAWorldMath:GetMapPosId(self.MapPos.Self)

    -- 给个初值，避免为nil
    self.MapPos.Map = self.MapPos.Self

    self:_initBankVar4MapPos()
end

function RAWorldVar:InitMap()
	self:Init()

	local RAGuideManager = RARequire('RAGuideManager')
    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowWorld()) then
    	local RAWorldGuideConfig = RARequire('RAWorldGuideConfig')
    	self.MapPos.Map = RAWorldGuideConfig.MapPos.MapSelf
    else
	    self.MapPos.Map = self.MapPos.Self
    end

    self.KingdomId.Map = self.KingdomId.Self
end

function RAWorldVar:Clear()
	self:ResetVersion()
	self.TargetInfo = nil
	self.HudPos = nil
	self.MoveSpeed = 0
	self.IsMovingStop = false
end

function RAWorldVar:AddVersion()
	self.MapVersion = self.MapVersion + 1
	return self.MapVersion
end

function RAWorldVar:ResetVersion()
	self.MapVersion = 1
end

function RAWorldVar:UpdateSelfPos(mapPos)
	if mapPos == nil then return end

	self.MapPos.Self = mapPos
	-- 已经加载过tmx map
	if self.ViewPos.Core then
		self:UpdateSelfViewPos()
	end
	self.BuildingId.Self = RAWorldMath:GetMapPosId(self.MapPos.Self)
end

function RAWorldVar:UpdateMap(mapPos)
	if mapPos == nil then return end
	
	self.MapPos.Map = mapPos
	self.ViewPos.Map = RAWorldMath:Map2View(mapPos)
	self.BuildingId.Self = RAWorldMath:GetMapPosId(self.MapPos.Self)
end

function RAWorldVar:UpdateServerCenter(mapPos)
	if mapPos ~= nil then
		self.MapPos.ServerCenter = mapPos
	end
end

function RAWorldVar:UpdateSelfKingdomId(kingdomId)
	self.KingdomId.Self = kingdomId
end

function RAWorldVar:UpdateMapKingdomId(kingdomId)
	self.KingdomId.Map = kingdomId
end

-- 当前是否在自己的王国内
function RAWorldVar:IsInSelfKingdom()
	return self.KingdomId.Map == self.KingdomId.Self
end

function RAWorldVar:UpdateSelfViewPos()
	self.ViewPos.Self = RAWorldMath:Map2View(self.MapPos.Self)
end

function RAWorldVar:UpdateMoveSpeed(speed)
	self.MoveSpeed = speed or 0
end

function RAWorldVar:UpdateSyncSpeed(speed)
	self.SyncMoveSpeed = speed
end

function RAWorldVar:MarkStopMoving(isStop)
	if isStop and self.SyncMoveSpeed <= 0 then
		isStop = false
	end
	self.IsMovingStop = isStop
end

function RAWorldVar:SetMigrateTarget(mapPos)
	self.MapPos.Migrate = mapPos
end

function RAWorldVar:_initBankVar4MapPos()
	local world_map_const_conf = RARequire('world_map_const_conf')
	
	if self.MapPos.Core == nil then
        local posStr = world_map_const_conf.worldCentreXy.value
        self.MapPos.Core = RAWorldMath:GetMapPosFromId(posStr)
    end
    
    if self.MapPos.BankSize == nil then
    	local areaStr = world_map_const_conf.worldCoreXy.value
    	self.MapPos.BankSize = RAWorldMath:GetMapPosFromId(areaStr)
    end

    if self.MapPos.BankCorner == nil then
    	self.MapPos.BankCorner =
    	{
    		left = {x = self.MapPos.Core.x - self.MapPos.BankSize.x, y = self.MapPos.Core.y},
    		right = {x = self.MapPos.Core.x + self.MapPos.BankSize.x, y = self.MapPos.Core.y},
    		top = {x = self.MapPos.Core.x, y = self.MapPos.Core.y - self.MapPos.BankSize.y},
    		bottom = {x = self.MapPos.Core.x, y = self.MapPos.Core.y + self.MapPos.BankSize.y}
    	}

    	local CapitalCnt = RARequire('RAWorldConfig').Capital.GridCnt
    	self.MapPos.CapitalCorner =
    	{
    		left = {x = self.MapPos.Core.x - CapitalCnt, y = self.MapPos.Core.y},
    		right = {x = self.MapPos.Core.x + CapitalCnt, y = self.MapPos.Core.y},
    		top = {x = self.MapPos.Core.x, y = self.MapPos.Core.y - CapitalCnt},
    		bottom = {x = self.MapPos.Core.x, y = self.MapPos.Core.y + CapitalCnt}
    	}
    end
end

function RAWorldVar:InitBankVar()
	if self.ViewPos.Core then
        self.ViewPos.Core = RAWorldMath:Map2View(self.MapPos.Core)
    end

    if self.ViewPos.BankCorner == nil then
    	self.ViewPos.BankCorner =
    	{
    		left = RAWorldMath:Map2View(self.MapPos.BankCorner.left),
    		right = RAWorldMath:Map2View(self.MapPos.BankCorner.right),
    		top = RAWorldMath:Map2View(self.MapPos.BankCorner.top),
    		bottom = RAWorldMath:Map2View(self.MapPos.BankCorner.bottom)
    	}
    end

    if self.ViewPos.BankSize == nil then
    	self.ViewPos.BankSize = {} 	
    	self.ViewPos.BankSize.x = math.abs(self.ViewPos.BankCorner.left.x - self.ViewPos.BankCorner.right.x) / 2
    	self.ViewPos.BankSize.y = math.abs(self.ViewPos.BankCorner.top.y - self.ViewPos.BankCorner.bottom.y) / 2
    end

end

return RAWorldVar

--endregion
