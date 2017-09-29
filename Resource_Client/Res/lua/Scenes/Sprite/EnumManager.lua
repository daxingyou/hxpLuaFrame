--region EnumManager.lua
--Author : zhenhui
--Date   : 2015/5/21
--endregion

--[[
¶¯×÷£º
1. ´ý»ú    ÓÐ    4F
2. ±¼ÅÜÒÆ¶¯
3. ÆÕÍ¨¹¥»÷    ÓÐ    8F    1¸ö·½Ïò
4. ËÀÍö    ÓÐ    4F 1¸ö·½Ïò

·½Ïò£º
1. ÓÒÉÏ
2. ÓÒ
3. ÓÒÏÂ
4. ÏÂ
5. ×óÏÂ
6. ×ó
7. ×óÉÏ
8. ÉÏ
]]--

local EnumManager = {
    DIRECTION_ENUM = {
        DIR_NONE =0,
        DIR_UP = 8,
        DIR_UP_LEFT = 7,
        DIR_LEFT = 6,
        DIR_DOWN_LEFT = 5,
        DIR_DOWN = 4,
        DIR_DOWN_RIGHT = 3,
        DIR_RIGHT = 2,
        DIR_UP_RIGHT = 1,
        DIR_MAX =9
    },

    FU_DIRECTION_ENUM = {
        DIR_NONE =-1,
        DIR_UP = 0,
        DIR_UP_UP_LEFT = 1,
        DIR_UP_LEFT = 2,
        DIR_UP_DOWN_LEFT = 3,
        DIR_LEFT = 4,
        DIR_DOWN_UP_LEFT = 5,
        DIR_DOWN_LEFT = 6,
        DIR_DOWN_DOWN_LEFT = 7,
        DIR_DOWN = 8,
        DIR_DOWN_DOWN_RIGHT = 9,
        DIR_DOWN_RIGHT = 10,
        DIR_DOWN_UP_RIGHT = 11,
        DIR_RIGHT = 12,
        DIR_UP_DOWN_RIGHT = 13,
        DIR_UP_RIGHT = 14,
        DIR_UP_UP_RIGHT = 15
    },

    DIRECTION_TO_FUDIRECTION = {
        [8] = 0,
        [7] = 2,
        [6] = 4,
        [5] = 6,
        [4] = 8,
        [3] = 10,
        [2] = 12,
        [1] = 14, 
        [0] = -1,  
    },

    DIRECTION_SIXTEEN_ENUM = {
        [1] = {dir = 14},
        [2] = {dir = 12},
        [3] = {dir = 10},
        [4] = {dir = 8},
        [5] = {dir = 6},
        [6] = {dir = 4},
        [7] = {dir = 2},
        [8] = {dir = 0},
    },

    ACTION_TYPE = {
        ACTION_NONE= 0,
        ACTION_IDLE = 1,
        ACTION_RUN = 2,
        ACTION_ATTACK = 3,
        ACTION_DEATH = 4,
        ACTION_WALK = 5,
        ACTION_BEHIT_ATTACK = 6,
        ACTION_BEHIT_IDLE = 7,
        ACTION_ROTATE = 8,
        ACTION_SPECIAL_IDLE = 9,
        ACTION_VICTORY_IDLE = 10,
        ACTION_ROCK_LEFT = 11, --摇摆动作左边
        ACTION_ROCK_RIGHT = 12, --摇摆动作右边
        ACTION_SIT_IDLE = 21,
        ACTION_SIT_ATTACK = 22,
        ACTION_SIT_DOWN = 23,
        ACTION_SIT_UP = 24,
        ACTION_SKILL_ATTACK = 25, --技能攻击动作
        ACTION_MAX = 27,
    },

     ACTION_TYPE_STR = {
        [1] = "Idle",
        [2] = "Run",
        [3] = "Att",
        [4] = "Die",
        [5] = "Walk",
        [6] = "Behit",
        [7] = "Behit_Idle",
        [8] = "Rotate"
    },

    ACTION_TAG = {
        MOVE_TAG = 1000,
    },

    SCENE_TAG = {
        BG_CCB_TAG = 9000000,
        MAP_TAG = 9010000,
    },

    UNIT_STATE = {
        STAND = 0,
        SIT = 1
    }
}

function EnumManager:convert8DirTo16Dir(dir)
    if self.DIRECTION_SIXTEEN_ENUM[dir] == nil then
        return self.DIRECTION_SIXTEEN_ENUM[4].dir
    end
    return self.DIRECTION_SIXTEEN_ENUM[dir].dir
end


function EnumManager:calcDir(startPos,endPos)
    local Utilitys = RARequire("Utilitys")
    local angle = Utilitys.ccpAngle(startPos, endPos)
    local RAMarchActionHelper = RARequire("RAMarchActionHelper")
    local Direction = RAMarchActionHelper:GetMarchDirectionByAngle(angle)
    return Direction 
end

function EnumManager:cal16Dir(startPos,endPos)
    local Utilitys = RARequire("Utilitys")
    local angle = Utilitys.ccpAngle(startPos, endPos)
    local RAMarchActionHelper = RARequire("RAMarchActionHelper")
    local Direction = RAMarchActionHelper:Get16DirectionByAngle(angle)
    return Direction 
end

--计算方向
function EnumManager:calcBattleDir(startPos,endPos)
    local Direction = self:calcDir(startPos,endPos)
    return self.DIRECTION_TO_FUDIRECTION[Direction] 
end

function EnumManager:calcBattle16Dir(startPos,endPos)
    local Direction = self:cal16Dir(startPos,endPos)
    return Direction
end


function EnumManager:getSwitchDirTable(startDir,endDir)
   local startDir16 = self.DIRECTION_SIXTEEN_ENUM[startDir].dir
   local endDir16 = self.DIRECTION_SIXTEEN_ENUM[endDir].dir
   
   local frames= {}
   local offset = endDir16 - startDir16
   if offset == 0 then return frames end
   if offset > 0  then
        if offset <= 8 then
            finalDir = startDir16 + offset
            for i = startDir16,finalDir do
                table.insert(frames,i)
            end
        else
            offset = 16 - offset
            finalDir = startDir16 + offset
            for i = startDir16,finalDir,-1 do
                table.insert(frames,i)
            end 
        end
   else
        if offset< -8 then
            offset = offset + 16
            finalDir = startDir16 + offset
            for i = startDir16,finalDir do
                if i >=16 then i = i - 16 end
                table.insert(frames,i)
            end
        else
            finalDir = startDir16 + offset
            for i = startDir16,finalDir,-1 do
                table.insert(frames,i)
            end 
        end
   end
   return frames
end


function EnumManager:getFUSwitchDirTableFor8(startDir,endDir, isCircle)
   if startDir%2 == 1 then
        startDir = startDir - 1
   end
   if endDir%2 == 1 then
        endDir = endDir - 1
   end   
   local startDir16 = startDir
   local endDir16 = endDir
   local startIndex = startDir16
   local frames= {}
   local offset = endDir16 - startDir16
   if offset == 0 then return frames end
   if offset > 0  then
        if offset <= 8 or isCircle then
            startIndex = startIndex + 2
            for i = startIndex,endDir16, 2 do
                table.insert(frames,i)
            end
        else
            offset = 16 - offset
            finalDir = startDir16 - offset
            startIndex = startIndex - 2
            for i = startIndex,finalDir,-2 do
                if i>=0 then 
                    table.insert(frames,i)
                else
                    table.insert(frames,i+16)
                end 
            end 
        end
   else
        if offset< -8 or isCircle then
            offset = offset + 16
            finalDir = startDir16 + offset
            startIndex = startIndex + 2
            for i = startIndex,finalDir, 2 do
                if i >=16 then i = i - 16 end
                table.insert(frames,i)
            end
        else
            -- finalDir = startDir16 + offset
            startIndex = startIndex - 2
            for i = startIndex,endDir16,-2 do
                table.insert(frames,i)
            end 
        end
   end
   return frames
end

function EnumManager:getFUSwitchDirTable(startDir,endDir, isCircle)
   local startDir16 = startDir
   local endDir16 = endDir
   local startIndex = startDir16
   local frames= {}
   local offset = endDir16 - startDir16
   if offset == 0 then return frames end
   if offset > 0  then
        if offset <= 8 or isCircle then
            startIndex = startIndex + 1
            for i = startIndex,endDir16 do
                table.insert(frames,i)
            end
        else
            offset = 16 - offset
            finalDir = startDir16 - offset
            startIndex = startIndex - 1
            for i = startIndex,finalDir,-1 do
                if i>=0 then 
                    table.insert(frames,i)
                else
                    table.insert(frames,i+16)
                end 
            end 
        end
   else
        if offset< -8 or isCircle then
            offset = offset + 16
            finalDir = startDir16 + offset
            startIndex = startIndex + 1
            for i = startIndex,finalDir do
                if i >=16 then i = i - 16 end
                table.insert(frames,i)
            end
        else
            -- finalDir = startDir16 + offset
            startIndex = startIndex - 1
            for i = startIndex,endDir16,-1 do
                table.insert(frames,i)
            end 
        end
   end
   return frames
end


function EnumManager:getFUSwitchDirTableFor32(startDir,endDir, isCircle)
   local startDir32 = startDir * 2
   local endDir32 = endDir * 2
   local startIndex = startDir32
   local frames= {}
   local offset = endDir32 - startDir32
   if offset == 0 then return frames end
   if offset > 0  then
        if offset <= 16 or isCircle then
            startIndex = startIndex + 1
            for i = startIndex,endDir32 do
                table.insert(frames,i)
            end
        else
            offset = 32 - offset
            finalDir = startDir32 - offset
            startIndex = startIndex - 1
            for i = startIndex,finalDir,-1 do
                if i>=0 then 
                    table.insert(frames,i)
                else
                    table.insert(frames,i+32)
                end 
            end 
        end
   else
        if offset< -16 or isCircle then
            offset = offset + 32
            finalDir = startDir32 + offset
            startIndex = startIndex + 1
            for i = startIndex,finalDir do
                if i >=32 then i = i - 32 end
                table.insert(frames,i)
            end
        else
            -- finalDir = startDir32 + offset
            startIndex = startIndex - 1
            for i = startIndex,endDir32,-1 do
                table.insert(frames,i)
            end 
        end
   end
   return frames
end


----------------------------------
--¸ù¾ÝÁ½¸ö×ø±ê·µ»Ø·½Ïò£¬30¶Èµ½60¶ÈÖ®¼ä×ª»»ÎªÐ±45¶È·½Ïò
----------------------------------
function EnumManager:getDirectionBetweenPoint(pos1,pos2,currentDirection)
    local offsetX = pos2.x - pos1.x
    local offsetY = pos2.y - pos1.y

    local direction = self.DIRECTION_ENUM.DIR_RIGHT
    if offsetX==0 then 
        if offsetY>0 then 
            direction = self.DIRECTION_ENUM.DIR_UP
        elseif offsetY<0 then
            direction = self.DIRECTION_ENUM.DIR_DOWN
        elseif offsetY==0 then
            direction = currentDirection
        end
    else
        local tan = math.abs(offsetY/offsetX)
        if offsetX>0 then 
            if tan<=0.57 then 
                direction = self.DIRECTION_ENUM.DIR_RIGHT
            elseif tan>=1.73 then 
                if offsetY>0 then 
                    direction = self.DIRECTION_ENUM.DIR_UP
                else
                    direction = self.DIRECTION_ENUM.DIR_DOWN
                end
            else
                if offsetY>0 then 
                    direction = self.DIRECTION_ENUM.DIR_UP_RIGHT
                else
                    direction = self.DIRECTION_ENUM.DIR_DOWN_RIGHT
                end
            end
        else
            if tan<=0.57 then 
                direction = self.DIRECTION_ENUM.DIR_LEFT
            elseif tan>=1.73 then 
                if offsetY>0 then 
                    direction = self.DIRECTION_ENUM.DIR_UP
                else
                    direction = self.DIRECTION_ENUM.DIR_DOWN
                end
            else
                if offsetY>0 then 
                    direction = self.DIRECTION_ENUM.DIR_UP_LEFT
                else
                    direction = self.DIRECTION_ENUM.DIR_DOWN_LEFT
                end
            end
        end
    end

    return direction
end


return EnumManager;
