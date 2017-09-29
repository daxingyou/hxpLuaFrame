local EnumManager = RARequire("EnumManager")
--model action parameters---------------------

local LeaderAction = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_RUN] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = {
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_WALK] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },
}



local MinerCarAction = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_RUN] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },
}

LeaderFrames = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = 4,
    [EnumManager.ACTION_TYPE.ACTION_RUN] = 8,
    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = 6,
    [EnumManager.ACTION_TYPE.ACTION_DEATH] = 4,
}


LeaderFPS = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = 4,
    [EnumManager.ACTION_TYPE.ACTION_RUN] = 12,
    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = 12,
    [EnumManager.ACTION_TYPE.ACTION_DEATH] = 16,
}

local LeaderAction = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_RUN] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = {
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },

    [EnumManager.ACTION_TYPE.ACTION_WALK] = {
        EnumManager.DIRECTION_ENUM.DIR_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP,
        EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
        EnumManager.DIRECTION_ENUM.DIR_DOWN,
        EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
        EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    },
}

BF_ONE_DIR_OBJ = { 
    EnumManager.FU_DIRECTION_ENUM.DIR_UP,
}

--战斗单元 16方向
BF_SIXTEEN_DIR_OBJ = {  
   EnumManager.FU_DIRECTION_ENUM.DIR_UP,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_UP_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT,

   EnumManager.FU_DIRECTION_ENUM.DIR_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_UP_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_DOWN_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_LEFT,

   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_DOWN_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_UP_RIGHT,

   EnumManager.FU_DIRECTION_ENUM.DIR_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT,
}


--战斗单元 8方向
BF_EIGHT_DIR_OBJ = {  
   EnumManager.FU_DIRECTION_ENUM.DIR_UP,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_LEFT,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN,
   EnumManager.FU_DIRECTION_ENUM.DIR_DOWN_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_RIGHT,
   EnumManager.FU_DIRECTION_ENUM.DIR_UP_RIGHT,
}


BFUnitAction_Dir16 = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = BF_SIXTEEN_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_RUN] = BF_SIXTEEN_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = BF_SIXTEEN_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_DEATH] = BF_SIXTEEN_DIR_OBJ,
}

--8方向的序列帧
BFUnitAction_Dir8 = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = BF_EIGHT_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_RUN] = BF_EIGHT_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = BF_EIGHT_DIR_OBJ,
    [EnumManager.ACTION_TYPE.ACTION_DEATH] = BF_EIGHT_DIR_OBJ,
}


ActionParametersMap = {
    [0] = {Action = LeaderAction,
   Frames = LeaderFrames,
   FPS = LeaderFPS},
   [5] = {Action = MinerCarAction,
   Frames = LeaderFrames,
   FPS = LeaderFPS},
   [10] = {Action = BFUnitAction_Dir16}
}
----------------------------------------------------------------



ActionRepeat = {
    [EnumManager.ACTION_TYPE.ACTION_IDLE] = true,
    [EnumManager.ACTION_TYPE.ACTION_RUN] = true,
    [EnumManager.ACTION_TYPE.ACTION_ATTACK] = false,
    [EnumManager.ACTION_TYPE.ACTION_DEATH] = false,
    [EnumManager.ACTION_TYPE.ACTION_WALK] = true
}

DirectionFlip_DIR16 = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6,
    [7] = 7,
    [8] = 8,
    [9] = 7,
    [10] = 6,
    [11] = 5,
    [12] = 4,
    [13] = 3,
    [14] = 2,
    [15] = 1,
}


DirectionFlip = {
    [EnumManager.DIRECTION_ENUM.DIR_LEFT] = EnumManager.DIRECTION_ENUM.DIR_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_UP] = EnumManager.DIRECTION_ENUM.DIR_UP,
    [EnumManager.DIRECTION_ENUM.DIR_UP_LEFT] = EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT] = EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN] = EnumManager.DIRECTION_ENUM.DIR_DOWN,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
}

DirectionSpeed = {
    [EnumManager.DIRECTION_ENUM.DIR_LEFT] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_RIGHT] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_UP] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_UP_LEFT] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT] = 200,
    [EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT] = 200
}

MirrorDirection = {
    [EnumManager.DIRECTION_ENUM.DIR_LEFT] = EnumManager.DIRECTION_ENUM.DIR_RIGHT,
    [EnumManager.DIRECTION_ENUM.DIR_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_UP] = EnumManager.DIRECTION_ENUM.DIR_UP,
    [EnumManager.DIRECTION_ENUM.DIR_UP_LEFT] = EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT] = EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN] = EnumManager.DIRECTION_ENUM.DIR_DOWN,
    [EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT,
    [EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT] = EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,
}