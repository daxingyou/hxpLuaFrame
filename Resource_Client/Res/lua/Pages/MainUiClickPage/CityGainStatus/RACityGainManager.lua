local RACityGainManager ={}

local UIExtend = RARequire("UIExtend")

--获取基地增益状态显示数据
function RACityGainManager:getCityGainData()
    local bufftype_conf = RARequire("bufftype_conf")
    local buffData = {}
    for i = 1 ,#bufftype_conf do
        buffData[#buffData + 1] = bufftype_conf[i]
    end

    return buffData
end

--基地增益可使用道具的数据
function RACityGainManager:getCityGainUseItemData(data)
    local item_conf = RARequire("item_conf")
    local RABuildManager = RARequire("RABuildManager")
    local RACoreDataManager = RARequire("RACoreDataManager")
    local baseLevel  =RABuildManager:getMainCityLvl()
    local useItemData = {}
    for k,item in pairs(item_conf) do
        if data.itemFunction == item.functionBlock and baseLevel >= item.levelLimit then
            if item.isSellable ~= 1 then
                local count = RACoreDataManager:getItemCountByItemId(item.id)
                if count > 0 then
                    useItemData[#useItemData + 1] = item
                end
            else
                useItemData[#useItemData + 1] = item
            end
        end
    end

    return useItemData
end

function RACityGainManager:setNodeVisible(ccbfile,isVisible)
    UIExtend.setNodeVisible(ccbfile,"mNoBarNode",isVisible)
    UIExtend.setNodeVisible(ccbfile,"mHaveBarNode",not isVisible)
end

return RACityGainManager