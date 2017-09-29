--[[
	des: basic define for battle
	author:zhenhui
	date:2016/11/22
]]



RARequire('extern')

--direction enum
    -- DIRECTION_ENUM = {
    --     DIR_NONE =0,
    --     DIR_UP = 8,
    --     DIR_UP_LEFT = 7,
    --     DIR_LEFT = 6,
    --     DIR_DOWN_LEFT = 5,
    --     DIR_DOWN = 4,
    --     DIR_DOWN_RIGHT = 3,
    --     DIR_RIGHT = 2,
    --     DIR_UP_RIGHT = 1,
    --     DIR_MAX =9
    -- },
ATTACKER = 1
DEFENDER = 2

DIAGONAL_RATIO = 1.118 --基础移动时间，以客户端右上移动为基准单位U，向上移动为 1/U,向右移动为2/u

BLOOD_GREEN_TO_RED = 0.5 --血条从绿色到红色的分界线

DIRECTION_COUNT = 16
DIRECTION_ENUM = RARequire("EnumManager").DIRECTION_ENUM
FU_DIRECTION_ENUM = RARequire('EnumManager').FU_DIRECTION_ENUM

BATTLE_CAMERA_MIN_SCALE = 0.7
BATTLE_CAMERA_MAX_SCALE = 1.2

--美术表现层
ACTION_TYPE = RARequire("EnumManager").ACTION_TYPE

--数据层的状态类型
STATE_TYPE = {
    STATE_IDLE = 1,     --空闲状态
    STATE_MOVE = 2,     --移动
    STATE_ATTACK = 3,   --攻击
    STATE_DEATH = 4,    --死亡
    STATE_CREATE = 5,   --战斗单元创建子单元
    STATE_FLY = 6,      --子单元的飞行
    STATE_DISAPPEAR = 7,--子弹攻击完之后的消失状态
    STATE_TERRORIST_ATTACK = 17,--恐怖机器人攻击坦克行为
    STATE_REVIVE = 18,--复活
    STATE_FROZEN_ATTACH = 20 --冰冻
}

--场景播放
FIGHT_PLAY_STATE_TYPE = 
{
   NONE = 0,        --无状态
   INIT_BATTLE = 1, --初始化战场
   START_PAGE = 2,  --LOARDING
   SHOW_TROOP = 3,  --介绍敌我双方
   START_BATTLE = 4,--开始战斗
   END_BATTLE = 5,  --结束战斗
   SHOW_RESULT = 6, --展示结果
   TROOP_WALK = 7,  --部队行走
   SHOW_TOWER = 8,  --显示心灵塔 --第一场战斗使用
   SHOW_FIRST_ENDTALK = 9,   --新手第一场战斗结束对话
}

--抛射类型	飞行
PROJECTTILE_TYPE = {
	INVISIO = 1,--无形抛射体。瞬间击中子弹,如机枪类，不会miss也不存在飞行时间
	ARCING = 2,-- 弧线抛射体。
	ROT =3,--导弹类武器，特性是可以追踪
	VERTICAL = 4,-- 垂直抛射体，飞艇的炸弹
}

--武器抛射体状态
WEAPON_PROJECT_STATE ={
	NONE = 0, --空状态
	FLY_STATE = 1,--飞行状态
	EFFECT_STATE = 2, --特效状态
	DESTROY = 3 --损毁
}

--16方向笛卡尔坐标系的角度，以度为结尾
DirectionAngle_DIR16 = {
    [0] = 90,
    [1] = 112.5,
    [2] = 135,
    [3] = 157.5,
    [4] = 180,
    [5] = 202.5,
    [6] = 225,
    [7] = 247.5,
    [8] = 270,
    [9] = 292.5,
    [10] = 315,
    [11] = 337.5,
    [12] = 0,
    [13] = 22.5,
    [14] = 45,
    [15] = 67.5,
}

EFFECT_STATE_TYPE = {
  BEHIT = 'behit',--受击位置
  FIRE = 'fire' --开火位置
}
-- 16方向各个方向控制的角度范围
DIRECTION_16_ANGLE_DEFINE = 
{
  [0]   = {dir = FU_DIRECTION_ENUM.DIR_UP  ,              base = { 90   } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [1]   = {dir = FU_DIRECTION_ENUM.DIR_UP_UP_LEFT ,       base = { 112.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [2]   = {dir = FU_DIRECTION_ENUM.DIR_UP_LEFT ,          base = { 135  } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [3]   = {dir = FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT ,     base = { 157.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [4]   = {dir = FU_DIRECTION_ENUM.DIR_LEFT ,             base = { 180  } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [5]   = {dir = FU_DIRECTION_ENUM.DIR_DOWN_UP_LEFT ,     base = { 202.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [6]   = {dir = FU_DIRECTION_ENUM.DIR_DOWN_LEFT ,        base = { 225  } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, },     
  [7]   = {dir = FU_DIRECTION_ENUM.DIR_DOWN_DOWN_LEFT ,   base = { 247.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, },
  [8]   = {dir = FU_DIRECTION_ENUM.DIR_DOWN ,             base = { 270  } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [9]   = {dir = FU_DIRECTION_ENUM.DIR_DOWN_DOWN_RIGHT ,  base = { 292.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [10]  = {dir = FU_DIRECTION_ENUM.DIR_DOWN_RIGHT ,       base = { 315  } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [11]  = {dir = FU_DIRECTION_ENUM.DIR_DOWN_UP_RIGHT ,    base = { 337.5  } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [12]  = {dir = FU_DIRECTION_ENUM.DIR_RIGHT ,            base = { 0, 360 } , gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [13]  = {dir = FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT ,    base = { 22.5 } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [14]  = {dir = FU_DIRECTION_ENUM.DIR_UP_RIGHT ,         base = { 45   } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, }, 
  [15]  = {dir = FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT ,      base = { 67.5 } ,   gapAdd = 11.25, gapSub = 11.25, addEqual = false, subEqual = true, },   
}


--变色颜色定义相关
MaskColors =
{
  RED       = {key = 'RED',   color = {r = 255, g = 60,  b = 0}},
  BLUE      = {key = 'BLUE',  color = {r = 45,  g = 140, b = 248}},
  GREEN     = {key = 'GREEN', color = {r = 57,  g = 199, b = 13}},
  GREY      = {key = 'GREY',  color = {r = 148, g = 148, b = 148}},
  Purple    = {key = 'PURPLE', color = {r = 168, g = 94, b = 247}},
}


--战场玩家主动技能id
BattleSkillId = 
{
    ONE_MISSILE = 100001, -- 单导弹攻击
    MULTI_MISSILE = 100002, -- 多导弹攻击
    TEAM_TREAT = 100003 -- 队伍治疗
}

