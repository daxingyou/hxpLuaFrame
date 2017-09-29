local battle_player_skill_conf = {
[100001] ={
	skillId = 100001,
	name = '单导弹攻击',
	costPoint = 3,
	range = 3,
	damage = 1000000,
	effectElapse = 0,
	effectTimes = 1,
	flyPeriod = 0.05,
	wave = 1
},
[100002] ={
	skillId = 100002,
	name = '多导弹攻击',
	costPoint = 4,
	range = 4,
	damage = 50000,
	effectElapse = 0.1,
	effectTimes = 8,
	flyPeriod = 0.04,
	wave = 8
},
[100003] ={
	skillId = 100003,
	name = '队伍治疗',
	costPoint = 5,
	range = 3,
	damage = 2000000,
	effectElapse = 0.5,
	effectTimes = 10,
	flyPeriod = 0.05,
	wave = 1
}
}
return battle_player_skill_conf
