--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAMailConfig={}


--邮件类型
RAMailConfig.Type={
	PRIVATE 		= 1,	--私人信息
	ALLIANCE 		= 2,	--联盟邮件
	FIGHT 			= 3,	--战斗信息
	SYSTEM			= 4,	--系统消息
	ACTIVITY		= 5,	--活动邮件
	MONSTERYOULI	= 6,	--反击尤里
	RESCOLLECT		= 7,	--采集报告

}

--邮件配置ID 开区间（2010000,2011000）
RAMailConfig.IdLimit={
	PRIVATE			= {2010000,2011000},
	ALLIANCE		= {2011000,2012000},
	FIGHT			= {2012000,2013000},
	SYSTEM			= {2013000,2014000},
	--ACTIVITY	= {2011000,2012000},
	MONSTERYOULI	= {2014000,2015000},
	RESCOLLECT		= {2015000,2016000},
}


--战斗邮件细分
RAMailConfig.FightDetailType={
	BE_HIT_FLY			=1,			--被击飞
	CAMP				=2,			--扎营
	DETECT 				=3,			--侦查
	BE_DETECTED_MAIL	=4,			--被侦查
	CURE				=5,			--治疗
	FIGHT 				=6,			--战斗
	BE_NUCLEAR_BOMBED 	=7,			--被核弹轰炸
	BE_STORM_BOMBED 	=8,			--被闪电风暴轰炸

}

--战斗邮件细分
RAMailConfig.FightConfigId={
	BE_HIT_FLY			={2012011},													--被击飞
	CAMP				={2012141,2012142},											--扎营
	DETECT 				={2012021,2012031,2012041,2012051,2012061,2012071},			--侦查
	BE_DETECTED_MAIL	={2012022,2012032,2012042,2012052,2012072},					--被侦查
	CURE				={2012151},													--治疗
	FIGHT 				={
							2012081,2012082,2012083,2012084,
							2012091,2012092,2012093,2012094,
							2012101,2012102,2012103,2012104,
							2012111,2012112,
							2012121,2012122,2012123,2012124,2012125,
							2012131,2012132,2012133,2012134,
						  },														--战斗
	BE_NUCLEAR_BOMBED 	={2012161},													--被核弹轰炸
	BE_STORM_BOMBED 	={2012171},													--被闪电风暴轰炸

}


RAMailConfig.TAG = 1000
RAMailConfig.ChatRoomMemLimit = 50		--聊天室成员数目上限
RAMailConfig.LimitMailNum=50
--Pages
RAMailConfig.Page={
	--Alliance
	ResAid={2011021,2011024},
	SoldierAid={2011031,2011034},
	DestroyYouLiBase=2011071,
	NubormExplode=2011131,
	LighningStorm = 2011141,

	--Private
	Prviate 				=2010001,
	--Fight
	Evacuation 				=2012011,
	InvestigateBase 		=2012021,
	InvestigateResPos 		=2012031,
	InvestigateStationed 	=2012041,
	InvestigateCore			=2012051,
	InvestigateYouLiBase	=2012061,
	InvestigateCastle		=2012071,
	InvestigatePlatform		=2012181,

	BeInvestigateBase 		=2012022,
	BeInvestigateResPos 	=2012032,
	BeInvestigateStationed 	=2012042,
	BeInvestigateCore		=2012052,
	BeInvestigateCastle		=2012072,


	FightBaseSuccess 		={2012081,2012084},
	FightBaseFail 		    ={2012085,2012088},
	FightResPosSuccess 		={2012091,2012094},
	FightResPosFail 		={2012095,2012096},

	FightStationedSuccess   ={2012101,2012104},
	FightStationedFail 		=2012105,


	FightYouLiBaseSuccess	={2012111,2012112}, 
	FightYouLiBaseFail	    =2012113,

	FightCastleSuccess		={2012121,2012125}, 
	FightCastleSuccess1		=2012127,
	FightCastleFail	    	=2012126,

	FightCoreSuccess		={2012131,2012134}, 
	FightCoreFail	    	=2012135,

	FightPlatformSuccess1	={2012191,2012192}, 
	FightPlatformSuccess2	={2012194,2012195}, 
	FightPlatformFail	    =2012193,


	WoundSolder				=2012151,
	LighningStormHurt		=2012171,

	FightYouLiMonstSucc 	=2014011,
	FightYouLiMonstLast 	=2014012,
	FightYouLiMonstFail 	=2014013,
	FightYouLiMonstMiss 	=2014014,

	ResCollectSucc 			=2015011,
	ResCollectMiss 			=2015012,
	ResCollectOccu 			=2015013,
	ResCollectFight			=2015014,
	ResCollectSupSucc		=2015021,
	ResCollectSupFail		=2015022,

	ResAidSucc				=2011021,
	ResRecvSucc				=2011022,
	ResAidFail				=2011023,
	ResRecvFail				=2011024,
	SoldierAidSucc			=2011031,
	SoldierRecvSucc			=2011032,
	SoldierAidFail			=2011033,
	SoldierRecvFail			=2011034,
}	


--html里嵌入CCB的配置
--<ccb id="RAMailCommonCell1V6" src="ccbi/RAMailCommonCell1.ccbi"></ccb>
--1 4 5
--如果出现一个html中有多个相同的CCB 参照下例:RAMailCommonCell1V6_1,RAMailCommonCell1V6_2
--<ccb id="RAMailCommonCell1V6_1" src="ccbi/RAMailCommonCell1.ccbi"></ccb><ccb id="RAMailCommonCell1V6_2" src="ccbi/RAMailCommonCell1.ccbi"></ccb>
RAMailConfig.CCB=
{
	RAMailCmmCell1={id="RAMailCommonCell1V6",src="ccbi/RAMailCommonCell1V6.ccbi"},
	RAMailCmmCell2={id="RAMailCommonCell2V6",src="ccbi/RAMailCommonCell2V6.ccbi"},
	RAMailCmmCell3={id="RAMailCommonCell3V6",src="ccbi/RAMailCommonCell3V6.ccbi"},
	RAMailCmmCell4={id="RAMailCommonCell4V6",src="ccbi/RAMailCommonCell4V6.ccbi"},
	RAMailCmmCell5={id="RAMailCommonCell5V6",src="ccbi/RAMailCommonCell5V6.ccbi"},
	RAMailCmmCell6={id="RAMailCommonCell6V6",src="ccbi/RAMailCommonCell6V6.ccbi"},
	RAMailCmmCell7={id="RAMailCommonCell7V6",src="ccbi/RAMailCommonCell7V6.ccbi"},
}

RAMailConfig.HtmlCCBCell={
	--核武器攻击投票，闪电风暴攻击投票  											RAMailCmmCell1
	--核武器攻击确认，闪电风暴攻击确认  核武器攻击取消								RAMailCmmCell1
	--闪电风暴攻击取消																RAMailCmmCell1
	--联盟堡垒攻占成功 联盟堡垒失守 成功夺回联盟堡垒 未能守住联盟堡垒				RAMailCmmCell2
	--基地迁城邀请 	 强制撤离														RAMailCmmCell1
	--遭到侦查，侦查失败，已阻止敌人侦查，敌人侦查失败								RAMailCmmCell1
	--资源点侦查失败 驻扎点侦查失败	尤里基地侦查失败 首都侦查失败 堡垒侦查失败		RAMailCmmCell4										
	--国王战结束 大总统礼包  官员撤职   											RAMailCmmCell1
	--被征税 征税																	RAMailCmmCell5
	--官员首次任命                                                      			RAMailCmmCell1,RAMailCmmCell6
	--官员再次任命                                                          		RAMailCmmCell1,RAMailCmmCell7

}
RAMailConfig.StationIcon="Favorites_Icon_Building_08.png"				--驻扎点默认图
RAMailConfig.CoreIcon ="Favorites_Icon_Building_06.png"					--首都默认图

RAMailConfig.FightResultID={
	AttackSuccess 	= {2012081,2012091,2012101,2012111,2012121,2012127,2012131,2012191},
	DefendFail  	= {2012082,2012092,2012102,2012122,2012123,2012132,2012195},

	AttackFail 		= {2012083,2012093,2012103,2012112,2012124,2012133,2012192},
	DefendSuccess 	= {2012084,2012094,2012104,2012125,2012134,2012194},
	
}

RAMailConfig.FightResult={
	AttackSuccess 	= 1,
	DefendFail  	= 2,
	AttackFail 		= 3,
	DefendSuccess 	= 4,
	
}

--产生时间提示间隔 180秒
RAMailConfig.createTime=180 

return RAMailConfig

--endregion
