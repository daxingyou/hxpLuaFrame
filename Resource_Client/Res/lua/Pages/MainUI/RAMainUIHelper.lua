local Const_pb=RARequire('Const_pb')
local World_pb = RARequire('World_pb')

local RAMainUIHelper = {   
    -- 显示队列的数目
    QueueShowTypeCount = 6,
    -- 队列图标
    QueueIconMap = {},
    QueueSoilderIconMap = {},
    QueueNameMap = {},
    QueueUseNameMap = {},
    QueueUsingDesKeyMap = {},
    --队列加速
    SpeedKey = "@QueueSpeedUp",
    --队列空闲
    QueueSpareKey = "@QueueSpareKey",

    QueueSpareIcon = "MainUI_Queue_Btn_Spare.png",

    QueueMarchingIcon = "MainUI_Queue_Btn_Marching.png",

    SpareQueueTypeAddValue = 1000,
}

-- data init
RAMainUIHelper.QueueIconMap[Const_pb.BUILDING_QUEUE] = 'NewMainUI_u_Queue_Icon_02.png'
RAMainUIHelper.QueueIconMap[Const_pb.BUILDING_DEFENER] = 'NewMainUI_u_Queue_Icon_09.png'
RAMainUIHelper.QueueIconMap[Const_pb.SCIENCE_QUEUE] = 'NewMainUI_u_Queue_Icon_03.png'
RAMainUIHelper.QueueIconMap[Const_pb.SOILDER_QUEUE] = 'MainUI_Queue_Btn_Army.png'
RAMainUIHelper.QueueIconMap[Const_pb.CURE_QUEUE] = 'NewMainUI_u_Queue_Icon_04.png'
RAMainUIHelper.QueueIconMap[Const_pb.EQUIP_QUEUE] = 'empty.png'
RAMainUIHelper.QueueIconMap[Const_pb.MARCH_QUEUE] = 'NewMainUI_u_Queue_Icon_01.png'

RAMainUIHelper.QueueSoilderIconMap[Const_pb.BARRACKS] = 'NewMainUI_u_Queue_Icon_05.png'
RAMainUIHelper.QueueSoilderIconMap[Const_pb.WAR_FACTORY] = 'NewMainUI_u_Queue_Icon_07.png'
RAMainUIHelper.QueueSoilderIconMap[Const_pb.REMOTE_FIRE_FACTORY] = 'NewMainUI_u_Queue_Icon_08.png'
RAMainUIHelper.QueueSoilderIconMap[Const_pb.AIR_FORCE_COMMAND] = 'NewMainUI_u_Queue_Icon_06.png'




RAMainUIHelper.QueueNameMap[Const_pb.BUILDING_QUEUE] = '@BuildQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.BUILDING_DEFENER] = '@BuildDefQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.SCIENCE_QUEUE] = '@ScienceQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.SOILDER_QUEUE] = '@SoilderQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.CURE_QUEUE] = '@CureQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.EQUIP_QUEUE] = '@EquipQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.MARCH_QUEUE] = '@MarchQueueName'
RAMainUIHelper.QueueNameMap[Const_pb.GUILD_SCIENCE_QUEUE] = '@StatueQueueName'

RAMainUIHelper.QueueUseNameMap[Const_pb.BUILDING_QUEUE] = '@BuildQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.BUILDING_DEFENER] = '@BuildDefQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.SCIENCE_QUEUE] = '@ScienceQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.SOILDER_QUEUE] = '@SoilderQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.CURE_QUEUE] = '@CureQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.EQUIP_QUEUE] = '@EquipQueueUseName'
RAMainUIHelper.QueueUseNameMap[Const_pb.MARCH_QUEUE] = '@MarchQueueUseName'


-- 队列使用中的时候，显示的队列信息描述标题
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_QUEUE] = {}
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_COMMON] = '@QueueBuildingLevelUp'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_REBUILD] = '@QueueBuildingRebuild'

RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_DEFENER] = {}
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_COMMON] = '@QueueBuildingLevelUp'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REBUILD] = '@QueueBuildingRebuild'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REPAIR] = '@QueueBuildingRepair'

RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.SCIENCE_QUEUE] = '@QueueTechDevelop'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.SOILDER_QUEUE] = '@QueueTrain'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.CURE_QUEUE] = '@MedicalCare'
RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.EQUIP_QUEUE] = '@EquipQueueName'
-- RAMainUIHelper.QueueUsingDesKeyMap[Const_pb.MARCH_QUEUE] = '@MarchQueueName'


-- 行军状态对应的文本展示
RAMainUIHelper.MarchStatusShowCfg = {
    [World_pb.MARCH_STATUS_MARCH]               = { lbKey = '@MarchingNew'  , btnKey = '@QueueSpeedUp'  },
    [World_pb.MARCH_STATUS_MARCH_COLLECT]       = { lbKey = '@Collecting'   , btnKey = '@ViewDetails'   },
    [World_pb.MARCH_STATUS_MARCH_QUARTERED]     = { lbKey = '@Stationed'    , btnKey = '@ViewDetails'   },
    [World_pb.MARCH_STATUS_MARCH_ASSIST]        = { lbKey = '@SoldierAiding', btnKey = '@Recall'        },
    [World_pb.MARCH_STATUS_RETURN_BACK]         = { lbKey = '@RetruningNew' , btnKey = '@QueueSpeedUp'  },
    [World_pb.MARCH_STATUS_WAITING]             = { lbKey = '@Assemblying'  , btnKey = '@ViewDetails'   },
}


function RAMainUIHelper:getQueueCellCfg(queueType, queueData)
    local queueItemId = nil
    local queueInfo = nil
    local queueStatus = nil
    if queueData then
        queueItemId = queueData.itemId
        queueInfo = queueData.info
        queueStatus = queueData.status
    end
	local RAStringUtil = RARequire('RAStringUtil')
    local RABuildManager = RARequire('RABuildManager')
    local icon = ''
    local name = ''
    local btnName = ''
    if queueType == Const_pb.BUILDING_QUEUE then        
        -- local buildData = RABuildManager:getBuildDataByType(tonumber(queueInfo))
        local buildData = RABuildManager:getBuildDataById(queueItemId)
        if buildData ~= nil then
            icon = buildData.confData.buildArtImg
            name = buildData.confData.buildName
    	else
    		name = _RALang(RAMainUIHelper.QueueSpareKey, _RALang(RAMainUIHelper.QueueNameMap[queueType]))
    		btnName = _RALang(RAMainUIHelper.QueueUseNameMap[queueType])
            icon = RAMainUIHelper.QueueSpareIcon
    	end
    elseif queueType == Const_pb.BUILDING_DEFENER then
        -- 防御建筑
        local buildData = RABuildManager:getBuildDataById(queueItemId)
        if buildData ~= nil then
            icon = buildData.confData.buildArtImg
            name = buildData.confData.buildName
        else
            name = _RALang(RAMainUIHelper.QueueSpareKey, _RALang(RAMainUIHelper.QueueNameMap[queueType]))
            btnName = _RALang(RAMainUIHelper.QueueUseNameMap[queueType])
            icon = RAMainUIHelper.QueueSpareIcon
        end
    elseif queueType == Const_pb.SCIENCE_QUEUE then     
        -- 科技队列是固定的一个
        local RAScienceUtility = RARequire('RAScienceUtility')
        local scieneData = RAScienceUtility:getScienceDataById(queueItemId)
        if scieneData ~= nil then
            icon = scieneData.techPic
            name = scieneData.techName
        else
        	icon = RAMainUIHelper.QueueSpareIcon
        	name = _RALang(RAMainUIHelper.QueueSpareKey, _RALang(RAMainUIHelper.QueueNameMap[queueType]))
        	btnName = _RALang(RAMainUIHelper.QueueUseNameMap[queueType])
        end
        
    elseif queueType == Const_pb.SOILDER_QUEUE then
        -- 训练队列上限根据兵营类建筑个数决定
        local RAArsenalManager = RARequire('RAArsenalManager')        
        local cfg = RAArsenalManager:getArmyCfgById(queueItemId)
        if cfg ~= nil then
            icon = cfg.icon
            name = cfg.name
        else
            icon = RAMainUIHelper.QueueSpareIcon
        	name = _RALang(RAMainUIHelper.QueueSpareKey, _RALang(RAMainUIHelper.QueueNameMap[queueType]))
        	btnName = _RALang(RAMainUIHelper.QueueUseNameMap[queueType])
        end
    elseif queueType == Const_pb.CURE_QUEUE then    
        -- 治疗队列是固定的一个        
        local RAQueueManager = RARequire('RAQueueManager')
        local count = RAQueueManager:getQueueCounts(Const_pb.CURE_QUEUE)
        -- 队列数目为0，证明需要治疗
        if count == 0 then            
            name = _RALang(RAMainUIHelper.QueueSpareKey, _RALang(RAMainUIHelper.QueueNameMap[queueType]))
            btnName = _RALang(RAMainUIHelper.QueueUseNameMap[queueType])
            icon = RAMainUIHelper.QueueSpareIcon
        else

        end
    elseif queueType == Const_pb.EQUIP_QUEUE then
        -- 装备未实现
        -- ret = 0
    elseif queueType == Const_pb.MARCH_QUEUE then   
        -- 行军
        icon = RAMainUIHelper.QueueMarchingIcon 
    end
    return icon, name, btnName
end


return RAMainUIHelper
