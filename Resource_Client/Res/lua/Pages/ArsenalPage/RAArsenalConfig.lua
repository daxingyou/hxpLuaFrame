--region RAArsenalConfig.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAArsenalConfig = {
--['@Build_2011_name'] = '兵营',
--['@Build_2012_name'] = '战车工厂',
--['@Build_2013_name'] = '远程火力工厂',
--['@Build_2014_name'] = '空指部',
    Build2011 = 2011,  
    Build2012 = 2012,
    Build2013 = 2013,
    Build2014 = 2014,
    ArmyCatogory = {--大类型的兵种
        infantry = 1,
        tank =2,
        missile =3,
        helicopter = 4
    },
    
    baseGatherNum = 3000,
     ArmyTroopTotalNum = {--大类型的兵种
        [1] = 16,
        [2] = 6,
        [3] = 6,
        [4] = 2,
    },
}


RAArsenalConfig.ArmyCategory2FrameId =
{
    [RAArsenalConfig.ArmyCatogory.infantry]     = 1,
    [RAArsenalConfig.ArmyCatogory.tank]         = 2,
    [RAArsenalConfig.ArmyCatogory.missile]      = 3,
    [RAArsenalConfig.ArmyCatogory.helicopter]   = 4
}
return RAArsenalConfig
--endregion
