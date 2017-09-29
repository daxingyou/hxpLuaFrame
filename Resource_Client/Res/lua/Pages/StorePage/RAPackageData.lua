local UIExtend = RARequire("UIExtend")
local RALogicUtil = RARequire("RALogicUtil")

local RAPackageData = 
{
	STORE_CHOOSEN_TAB = 
	{
	    allTab         = 1,
		accelerateTab  = 2,
	    conditionTab   = 3,
	    resourcesTab   = 4,
	    specialTab     = 5
	},
	PACKAGE_CHOOSEN_TAB = 
	{
	    allTab         = 0,
		accelerateTab  = 1,
	    conditionTab   = 2,
	    resourcesTab   = 3,
	    specialTab     = 4
	},
	ShopNotNew = 100000,--不是新款，用于排序
	ShopNotHot = 100000,--不是热款，用于排序
	PACKAGE_POP_UP_BTN_STYLE = 
	{
		shopBuy = 1,
		itemUse = 2,
		shopHotBuy = 3
	},
	PACKAGE_CAN_USE = --背包物品是否能使用
	{
		can = 1,
		cannot = 0
	},
	PACKAGE_CAN_ALL_USE = --背包物品是否能批量使用
	{
		can = 1,
		cannot = 0
	},
	ITEM_TYPE = 
	{
		accelerate = 1, --加速类道具
		buff = 2,
		state = 3,		--状态类道具
		box   = 4,		--开箱子类道具
		res   = 5,		--资源类道具
		others = 100    --杂项类道具
	},
	SPEED_UP_TYPE = 
	{
		common = 0,  --通用
		func   = 1,  --造功能、防御
		defent = 2,  --造防御
		science = 3,  --科技加速
		soldier = 4,  --造兵加速
		cure    = 5,  --治疗加速
		equip   = 6,  --造装备加速
		march   = 7,  --行军加速
		statue	= 8	  --雕像升级加速
	},
	--作用号id
	EFFECT_ID_TYPE = 
	{
		avoidWar = 440 --免战
	},
	
	--给道具添加背景品质底图，添加道具icon
	addBgAndPicToItemGrid = function( ccbfile, itemName, data )
	    local picName = "Resource/Image/Item/"..data.item_icon..".png"
	    local bgName  = RALogicUtil:getItemBgByColor(data.item_color)
	    UIExtend.addSpriteToNodeParent(ccbfile, itemName, bgName, nil, nil, 20000)
	    UIExtend.addSpriteToNodeParent(ccbfile, itemName, picName)
	end,

	removeBgAndPicToItemGrid = function( ccbfile, itemName )
	    UIExtend.removeSpriteFromNodeParent(ccbfile, itemName, 20000)
	    UIExtend.removeSpriteFromNodeParent(ccbfile, itemName)
	end,

	--给道具名称赋值，并修改颜色
	setNameLabelStringAndColor = function( ccbfile, itemName, data )
		UIExtend.setCCLabelString(ccbfile,itemName, _RALang(data.item_name))
		local colorMap = {}
		colorMap[itemName] = COLOR_TABLE[data.item_color]
	    UIExtend.setColorForLabel(ccbfile, colorMap)
	end,

	--item_type赋值。显示数字类型，0不显示，1显示数值，2显示百分比
	setNumTypeInItemIcon = function( ccbfile, itemName, itemNodeName, data )
		local num_type = data.num_type
	    if num_type == nil then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, false)
	    elseif num_type == 1 then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, true)
	        local numCount = RALogicUtil:num2k(data.num_icon)
	        UIExtend.setCCLabelBMFontString(ccbfile,itemName,numCount)
	     elseif num_type == 2 then
	        UIExtend.setNodeVisible(ccbfile, itemNodeName, true)
	        local numCount = data.num_icon.."%"
	        UIExtend.setCCLabelBMFontString(ccbfile,itemName,numCount)
	    end
	end
}

return RAPackageData