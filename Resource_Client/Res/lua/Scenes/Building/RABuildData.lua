RARequire('RABuildingUtility')
local build_conf = RARequire('build_conf')
RABuildData = {}

--构造函数
function RABuildData:new(buildCfgId)
    local o = {}

    if buildCfgId == nil then 
        o.confData = {} --配置文件对象
    else 
        o.confData = build_conf[buildCfgId]
    end 

    o.tilesMap = {} --该建筑占地tiles
    o.tilePos = nil --建筑的位置 即最下角
    o.topTile = nil --建筑最顶上的 
    o.clickPos = nil --点击的位置
    o.status = 0
    o.HP = 0    --防御建筑当前血量
    o.totalHP = 0   --防御建筑总血量
    o.normal = 1    --1表示满血0表示受损
    setmetatable(o,self)
    self.__index = self
    return o
end

--根据PB初始化数据
function RABuildData:initByPb(buildPB)
    -- self.confData = build_conf[buildPB.buildCfgId]
    self:initByCfgId(buildPB.buildCfgId)
    self.id = buildPB.id
    self.status = buildPB.status
    if buildPB:HasField("hp") then 
        self.HP = buildPB.hp
        
        -- local defenceBuildConf = RABuildingUtility:getDefenceBuildConfById(buildPB.buildCfgId)
        -- if defenceBuildConf then
        --     self.totalHP = defenceBuildConf.hp
        -- end

        if self.HP < self.totalHP then
            self.normal = 0
        end
    end

    self:setTilePos(buildPB)
end

-- --根据PB更新繁育建筑血量变化 以及状态
-- function RABuildData:updateHpByPb(defBuildHp)
--     local id = defBuildHp.id
--     local hp = defBuildHp.hp
--     local normal = defBuildHp.normal

--     local RABuildManager = RARequire("RABuildManager")
--     local buildData = RABuildManager:getBuildDataById(id)
--     buildData.HP = hp
--     buildData.normal = normal
-- end

function RABuildData:initByCfgId(buildCfgId)
    self.confData = build_conf[buildCfgId]

    local defenceBuildConf = RABuildingUtility:getDefenceBuildConfById(buildCfgId)
    if defenceBuildConf then
        self.totalHP = defenceBuildConf.hp
    end
end

function RABuildData:getLevel()
    return self.confData.level
end

--更新占地Map
function RABuildData:updateTilesMap()
    self.tilesMap = RABuildingUtility.getBuildingAllTilePos(self.tilePos,self.confData.width,self.confData.length)

    self.topTile = nil 
    for k,v in pairs(self.tilesMap) do
        if self.topTile == nil then 
            self.topTile = v
        elseif v.y < self.topTile.y then 
            self.topTile = v
        end  
    end
end

function RABuildData:setClickTile(tilePos)
    if tilePos == nil then 
        self.clickPos = nil 
    else  
        self.clickPos = self.tilesMap[tilePos.x .. "_" .. tilePos.y]
    end 
end

--设置tile位置
function RABuildData:setTilePos(tilePos)
    self.tilePos = {x = tilePos.x,y = tilePos.y}

    if tilePos.y%2 == 0 then 
        self.lowX = tilePos.x - tilePos.y/2 
        self.highX = tilePos.x + tilePos.y/2
    else 
        self.lowX = tilePos.x - (tilePos.y+1)/2 + 1
        self.highX = tilePos.x + (tilePos.y+1)/2 - 1
    end 

    self:updateTilesMap()
end

--当前点是不是在建筑里面
function RABuildData:isContain(tilePos)
    if self.tilesMap[tilePos.x .. "_" .. tilePos.y] ~= nil then 
        return true
    else
        return false
    end 
end

--两个建筑是不是有重叠
function RABuildData:isBuildingContain(buildData)
    for k,v in pairs(buildData.tilesMap) do
        if self.tilesMap[k] ~= nil then 
            return true
        end 
    end

    return false
end


