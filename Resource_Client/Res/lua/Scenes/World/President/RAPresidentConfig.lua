-- 元帅战相关配置

local President_pb = RARequire('President_pb')

local officeType =
{
	-- 官员
	Official 	= 1,
	-- 流寇
	Rabble 		= 2,
}

local RAPresidentConfig =
{
	OfficeType = officeType,

	RecordType =
	{
		-- 任命
		Appointment = 1,
		-- 礼物
		Gift 		= 2
	},

	WelfareType =
	{
		-- 增益
		Buff = 1,
		-- 减益
		Debuff = 0
	},

	OfficeTypeName =
	{
	    [officeType.Official]   = _RALang('@Official'),
	    [officeType.Rabble]     = _RALang('@Rabble')
	},

	OfficeTypeTitleCCB =
	{
	    [officeType.Official]   = 'RAPresidentMainCellTitle.ccbi',
	    [officeType.Rabble]     = 'RAPresidentMainCellTitle2.ccbi'
	},

	OfficeTypeCellCCB =
	{
	    [officeType.Official]   = 'RAPresidentMainCell.ccbi',
	    [officeType.Rabble]     = 'RAPresidentMainCell2.ccbi'
	},

	GiftNumColor =
	{
		Enough 	= {255, 255, 255},
		Lack 	= {255, 0, 0}
	},

	NameIcon =
	{
		[President_pb.INIT] 	= 'President_u_Deco_01.png',
		[President_pb.PEACE] 	= 'President_u_Deco_01.png',
		[President_pb.WARFARE] 	= 'President_u_Deco_01.png' 
	},

	PeriodIcon =
	{
		[President_pb.INIT] 	= 'President_HUD_Icon_Pace.png',
		[President_pb.PEACE] 	= 'President_HUD_Icon_Pace.png',
		[President_pb.WARFARE] 	= 'President_HUD_Icon_Star.png' 
	},

	-- 修改总统府设置次数限制
	ModifySettingTimesMax = 1
}

return RAPresidentConfig