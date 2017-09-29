RARequire('extern')
RARequire("MessageManager")

local RAPlayerBasicInfo =  class('RAPlayerBasicInfo',{
        playerId = "",
        name = "",--用户名
        gold = 0,--钻石
        coin = 0,--金币
        recharge = 0,
        vipLevel = 0,--vip等级
        vipEndTime = 0,--vip结束时间
        vipPoints = 0,--vip点数
        level = 0,--用户等级
        exp = 0,--经验值
        headIconId = "",--头像id
        electric = 0,--当前占用电力
        electricMax = 0,--当前电量上限
        electricStatus = nil, --电力状态,这个状态是自己计算的
        goldore = 0,--金矿
        oil = 0,--石油
        steel = 0,--钢铁
        battlePoint = 0,    -- 总战力

        power = 0,  --体力
        equip = {},--装备
        tombarthite = 0, --稀土

        allianceName = "",--联盟名称

        lastLoginTime=0,
        freeVipPoint=0,
    })

function RAPlayerBasicInfo:ctor(...)
end

local RAItemInfo =  class('RAItemInfo',{
        id = 0,
        itemId = 0,
        count = 0,
        status = 0
    })

function RAItemInfo:ctor(...)
end

local RAPlayerDetailInfo =  class('RAPlayerDetailInfo',{
        warWinCnt       = 0,
        warLoseCnt      = 0,
        atkWinCnt       = 0,
        atkLoseCnt      = 0,
        defWinCnt       = 0,
        defLoseCnt      = 0,
        spyCnt          = 0,
        armyKillCnt     = 0,
        armyLoseCnt     = 0,
        armyCureCnt     = 0,

        playerBattlePoint = 0,--将军战斗力
        armyBattlePoint = 0,--部队战斗力
        techBattlePoint = 0,--科技战斗力
        buildBattlePoint = 0,--建筑战斗力
        defenseBattlePoint = 0,--防御设施战斗力
        equipBattlePoint = 0,--装备战斗力

        maxMarchSoldierNum  = 0,--出征兵力上限
        maxCapNum           = 0--医院上限
    })

function RAPlayerDetailInfo:ctor(...)
end

local RAWorldInfo =  class('RAWorldInfo',{
        worldCoord      = RACcp(1, 1), -- 世界地图上的坐标
        kingdomId       = 1,           -- 王国id
        serverId        = 's1',        -- 服务器id
        isCityRecreated = false        -- 城点是否被重建
    })

function RAWorldInfo:ctor(...)
end


local RAPlayerInfo = {
    raPlayerBasicInfo = RAPlayerBasicInfo.new(),
    raTalentInfo ={},--天赋数据，天赋id(number)和level的数组
    raItemInfo = RAItemInfo.new(),
    raPlayerDetailInfo = RAPlayerDetailInfo.new(),
    raWorldInfo = RAWorldInfo.new(),
}

function RAPlayerInfo:reset()
    self.raPlayerBasicInfo = RAPlayerBasicInfo.new()
    self.raTalentInfo ={}--天赋数据，天赋id(number)和level的数组
    self.raItemInfo = RAItemInfo.new()
    self.raPlayerDetailInfo = RAPlayerDetailInfo.new()
    self.raWorldInfo = RAWorldInfo.new()
end


--设置电力  electric 当前电力  --总电量
function RAPlayerInfo:setElectric(electric,electricMax)
    
    --相同，不需要处理
    if self.raPlayerBasicInfo.electric == electric and electricMax == nil then 
        return 
    end 

    if self.raPlayerBasicInfo.electricMax == electricMax and electric == nil then 
        return 
    end

    if self.raPlayerBasicInfo.electricMax == electricMax and self.raPlayerBasicInfo.electric == electric then 
        return 
    end

    if electric then 
        self.raPlayerBasicInfo.electric = electric
    end 

    if electricMax then 
        self.raPlayerBasicInfo.electricMax = electricMax
    end

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local electricStatus = RAPlayerInfoManager.getCurrElectricStatus() --旧的电力状态 

    if self.raPlayerBasicInfo.electricStatus ~= electricStatus then 
        self.raPlayerBasicInfo.electricStatus = electricStatus
        MessageManager.sendMessage(MessageDef_BaseInfo.MSG_ElectricStatus_Change,{electricStatus = electricStatus})
    end 
end


return RAPlayerInfo