--[[
description: base fight unit
author: zhenhui
date: 2016/11/22
	战斗单元
		1.bones骨骼	可能包含多个骨骼，同时每个骨骼可能有不同的序列帧管理器，灵活配置
			multiple boneframeController	多个骨骼的序列帧管理器
		2.state 状态机实现，拆分开每个action，可以灵活组装
			aka action
		3.Weapon 武器
			武器分为发射器和单个的子弹，与粒子的发射器和粒子有些类似。
				一个发射控制器包含一种类型子弹以及一种类型的击中特效，状态的切换也由发射器或者弹道控制器维护
		4.SoundManager 声音控制器	待完善
	战斗单元跟其他模块交互的大概的示意图：
	战斗单元---------------------->武器
		|						    |
		|					   	    |
		|					  	(发射控制器)
		|					 		|
		|					      	|
		|							|
		v 							v
	   特效<-----------------------子弹
	
]]

local RAFU_BloodBar     = RARequire('RAFU_BloodBar')
local Utilitys          = RARequire("Utilitys")


local BACKEFFECT_NODE_ZORDER = 1
local SPRITE_NODE_ZORDER = 2
local BEFOREEFFCT_NODE_ZORDER = 3
local HUD_NODE_ZORDER = 4

local RAFU_FightUnit_Basic = class('RAFU_FightUnit_Basic',RARequire("RAFU_Object"))

--构造函数
function RAFU_FightUnit_Basic:ctor(unitData)
    -- RALog("RAFU_FightUnit_Basic:ctor")
    --创建基础的node节点
    self.rootNode = CCNode:create()
    self.attackTime = 0
    self.id = unitData.id
    self.isAlive = true
    self.data = unitData
    self.type = self.data.confData.type
    self.tilePos = nil
    self.isBloodBarVisible = true
    --根据uniData的itemId类型，拿到unit cfgData,目前临时撰写
	local RAFU_Cfg_Unit = RARequire("RAFU_Cfg_Unit")
	local cfgData = RAFU_Cfg_Unit[self.data.confData.imageId]
    self.cfgData = cfgData

    -- 个性化属性
    self:_initSpecificProperty()

    --初始化debug层
    self:_initDebugNode()

    --初始化显示节点
    self:_initSpriteNode()

    --武器相关
    self:_initWeapon(cfgData)
    --BUFF系统相关
    self:_initBuffSystem()
    --初始化骨骼相关
    self:_initBones(cfgData);

    --声音相关


    self:_initHUDNode()
    --名字相关
    self:_initName()

    --hp
    self:_initCount()
    --主状态相关
    self.curState = ACTION_TYPE.ACTION_IDLE
    self.curDir = FU_DIRECTION_ENUM.DIR_DOWN

    --初始化状态相关
    self:_initStateManager(cfgData)

    self.crashCount = 0
    --unit 的状态，比如美国大兵 0为站里，1为坐下
    local EnumManager = RARequire("EnumManager")
    self.state =  EnumManager.UNIT_STATE.STAND 

    --unit颜色设置
    local RAGameConfig = RARequire("RAGameConfig")
    if RAGameConfig.IsBattleUnitSetMaskColor and RAGameConfig.IsBattleUnitSetMaskColor == 1 then
        self:_setMaskColor()
    end
end

function RAFU_FightUnit_Basic:_initSpriteNode()
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local width = RABattleSceneManager:getTileSizeWidth()
    local height = RABattleSceneManager:getTileSizeHeight()

    --中心位置为占地格的中心点位置，如1x1为单一格正中心，2x2为两格的交叉点
    self.centerOffset = (self.data.size.width + self.data.size.height-2)*height/4
    self.maxWidth = (self.data.size.width + self.data.size.height-2)*width/2
    self.maxHeight = 2*self.centerOffset

    --计算出最下角的点的位置
    self.bottomOffset = (self.data.size.width + self.data.size.height-2)*height/2

    --挂载精灵的节点
    self.spriteNode = CCNode:create()
    self.spriteNode:setPosition(0,-1 * self.bottomOffset)
    self.spriteNode:setZOrder(SPRITE_NODE_ZORDER)
    
    --挂载层级低于精灵的特效节点
    self.backEffectNode = CCNode:create()
    self.backEffectNode:setPosition(0,-1 * self.bottomOffset)
    self.backEffectNode:setZOrder(BACKEFFECT_NODE_ZORDER)

    --挂载层级高于精灵的特效节点
    self.beforeEffectNode = CCNode:create()
    self.beforeEffectNode:setPosition(0,-1 * self.bottomOffset)
    self.beforeEffectNode:setZOrder(BEFOREEFFCT_NODE_ZORDER)

    self.offsetY = self.data.confData.offsetY or 0
    self.rootNode:addChild(self.spriteNode)
    self.rootNode:addChild(self.backEffectNode)
    self.rootNode:addChild(self.beforeEffectNode)
end

function RAFU_FightUnit_Basic:_initDebugNode()
    self.debugNode = CCNode:create()
    self.rootNode:addChild(self.debugNode,1000)
    
    self.debugBg = CCSprite:create('Tile_Green_sNew2.png')
    self.debugBg:setAnchorPoint(0.5,0.5)
    self.debugBg:setPosition(0,0)

    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local width = RABattleSceneManager:getTileSizeWidth()
    local height = RABattleSceneManager:getTileSizeHeight()

    local x,y
    for i=1,self.data.size.width do
        for j=1,self.data.size.height do
            if i == 1 and j == 1 then 

            else
                local node = CCSprite:create('Tile_Red_sNew2.png')
                node:setAnchorPoint(0.5,0.5)
                x = (i - j)*width/2
                y = -(i + j-2)*height/2
                node:setPosition(x,y)
                self.debugNode:addChild(node,1000)
            end 
        end
    end

    self.debugNode:addChild(self.debugBg,1000)
    self.debugNode:setVisible(false)
end

function RAFU_FightUnit_Basic:setDebugModeVisible(isVisible)
    self.debugNode:setVisible(isVisible)
end

function RAFU_FightUnit_Basic:setBloodBarVisible(isVisible)
	if self.bloodBar then
		if isVisible then
			local RABattleSceneManager = RARequire('RABattleSceneManager')
			if RABattleSceneManager:getIsBloodBarVisible() then
				self.bloodBar:setVisible(isVisible)
			end
		else
			self.bloodBar:setVisible(false)
		end
	end
	self.isBloodBarVisible = isVisible
end

function RAFU_FightUnit_Basic:forceBloodBarVisible(isVisible)
	if self.bloodBar then
		if not isVisible or self.isBloodBarVisible then
			self.bloodBar:setVisible(isVisible)
		end
	end
end

function RAFU_FightUnit_Basic:release( )
	for k,v in pairs(self.stateManager) do
		RA_SAFE_RELEASE(v)
	end

    self.isAlive = false

	-- body
	for k,v in pairs(self.boneManager) do
		RA_SAFE_RELEASE(v)
	end

    if self.tilePos then
        local RABattleSceneManager = RARequire('RABattleSceneManager')
        RABattleSceneManager:removeTilePos(self.tilePos, self.data.size.width, self.data.size.height, {id = self.id, confData = self.data.confData})   
        self.tilePos = nil
    end      


	RA_SAFE_RELEASE(self.weapon)

    RA_SAFE_RELEASE(self.bloodBar)  --卸载血条:add by xinghui

    RA_SAFE_RELEASE(self.buffSystem)

	--clear node related
	RA_SAFE_REMOVEFROMPARENT(self.nameTTF)
	RA_SAFE_REMOVEFROMPARENT(self.countTTF)

    RA_SAFE_REMOVEFROMPARENT(self.spriteNode)
    RA_SAFE_REMOVEFROMPARENT(self.beforeEffectNode)
    RA_SAFE_REMOVEFROMPARENT(self.backEffectNode)

	RA_SAFE_REMOVEFROMPARENT(self.rootNode)

    self.zorderFrameCount = nil
    self.crashCount = nil
    local EnumManager = RARequire("EnumManager")
    self.state =  EnumManager.UNIT_STATE.STAND     
end

--------------Private function--------------------

function RAFU_FightUnit_Basic:_initHUDNode()
    self.hudNode = CCNode:create()
    self.rootNode:addChild(self.hudNode)
    self.hudNode:setZOrder(HUD_NODE_ZORDER)
    
    local RAFU_BloodBar = RARequire('RAFU_BloodBar')
    --if self.data.confData.id  == 2002  then --只有主基地有血条
    if self.cfgData.BloodCfg then
        --配置了血条才会有血条
        self.bloodBar = RAFU_BloodBar:new()
        self.bloodBar:init(self.cfgData.BloodCfg.BloodBar)
        self:setBloodBarVisible(false)
        local bloodPos = {0, 0}
        if self.cfgData.BloodCfg.BloodPos then
            bloodPos = Utilitys.Split(self.cfgData.BloodCfg.BloodPos, "_")
        end
        self.bloodBar.ccbfile:setPosition(tonumber(bloodPos[1]),tonumber(bloodPos[2]))
        self.hudNode:addChild(self.bloodBar.ccbfile)
    end
    --end

    if self.data.confData.id == 1001 then --只有美国大兵有等级
        local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName('Fight_Ani_Buff_Effect_601.png')
        self.levelFlag = CCSprite:createWithSpriteFrame(pSpriteFrame)
        self.hudNode:addChild(self.levelFlag)
        self.levelFlag:setVisible(false)
    end 

    self.debugHudNode = CCNode:create()
    self.rootNode:addChild(self.debugHudNode)
    self.debugHudNode:setVisible(false)
    self.debugHudNode:setZOrder(HUD_NODE_ZORDER)
end

function RAFU_FightUnit_Basic:setHudVisible(isVisible)
    self.hudNode:setVisible(isVisible)
    self.debugHudNode:setVisible(isVisible)
end

function RAFU_FightUnit_Basic:setRootNodeVisible(isVisible)
    self.rootNode:setVisible(isVisible)
end

--初始化名字
function RAFU_FightUnit_Basic:_initName()
	local ttf = CCLabelTTF:create(" ","Helvetica", 22)
    self.nameTTF = ttf
    local RAGameConfig = RARequire("RAGameConfig")
    if self.data.unitType == DEFENDER then
        ttf:setColor(RAGameConfig.COLOR.RED);
    else
        ttf:setColor(RAGameConfig.COLOR.YELLOW);
    end
    ttf:setPosition(ccp(0,50))
    self.nameTTF:setString(self.data.id)
    self.debugHudNode:addChild(self.nameTTF)
end

--[[
    desc: 兵种、建筑等变色
]]
function RAFU_FightUnit_Basic:_setMaskColor()
    if self.data.unitType == DEFENDER then
        --防守方变色
        self:changeMaskColor(MaskColors.RED)
    elseif self.data.unitType == ATTACKER then
        --攻击方变色
        self:changeMaskColor(MaskColors.BLUE)
    else
        self:changeMaskColor(MaskColors.BLUE)
    end
end

function RAFU_FightUnit_Basic:_initCount()
	local ttf = CCLabelTTF:create(" ","Helvetica", 22)
    self.countTTF = ttf
    local RAGameConfig = RARequire("RAGameConfig")
    ttf:setColor(RAGameConfig.COLOR.BLACK);
    ttf:setPosition(ccp(0,-40))
    self.countTTF:setString(self.data.count)
    self.debugHudNode:addChild(self.countTTF)
end

function RAFU_FightUnit_Basic:behit(damage)
    self:_damageBuff(damage)--添加特效

    self.data:updateByUnitDamage(damage)
    -- 更新单元的count，目前省略掉被攻击状态
    self:updateCount()
    --self:behitBuff()
end


function  RAFU_FightUnit_Basic:BeTerroristHit()
    RALog("RAFU_FightUnit_Basic:BeTerroristHit")
    
end


--更新count
function RAFU_FightUnit_Basic:updateCount(count)
    if count == nil then count = self.data.hp end
    self.countTTF:setString(count)

    --添加战斗单位血条逻辑：add by xinghui
    if self.bloodBar ~= nil then 
        if self.data.curHp >= self.data.totalHp then 
            self:setBloodBarVisible(false)
        else
            self:setBloodBarVisible(true)
        end 
        self.bloodBar:setBarValue(self.data.curHp,self.data.totalHp,self:isBreaken())
    end 
end

function RAFU_FightUnit_Basic:initBloodBar()
    if self.bloodBar ~= nil then 
        if self.data.curHp >= self.data.totalHp then 
            self:setBloodBarVisible(false)
        else
            self:setBloodBarVisible(true)
        end 
        self.bloodBar:setBarValue(self.data.curHp,self.data.totalHp,self:isBreaken(),false)
    end 
end

--[[
    desc: 添加血量改变buff显示
]]
function RAFU_FightUnit_Basic:_damageBuff(damage)
    if damage.damage > 0 and self.data.curHp < self.data.totalHp then
        --加血
        --添加治疗buff效果
        local data = {
        	targetSpacePos = RACcp(0, 0),
            lifeTime = 1.0,
            buffCfgName = "Fight_Ani_Buff_Effect_7"
        }
        self.buffSystem:AddBuff(data)
    elseif damage.damage < 0 then
        --掉血
    end
end
 
function RAFU_FightUnit_Basic:addTerroristBuff(param)
    
    local data = {
      	targetSpacePos = RACcp(0, 0),
        lifeTime = -1,
--        buffCfgName = "BUFF_BorisTarget"  ,
         buffCfgName = "BUFF_TerroristDamage"  ,
        }
    self:setBloodBarVisible(true)
    self.buffSystem:AddBuff(data)

end

--是否毁坏 普通单位没有毁坏状态，根据血量来判断
function RAFU_FightUnit_Basic:isBreaken()
    if self.data.curHp <= self.data.totalHp * BLOOD_GREEN_TO_RED then 
        return true
    else
        return false
    end
end

function RAFU_FightUnit_Basic:targetWarningBuff(param)
    
    local _lifeTime = param.lifeTime or 0.5
    local data = {
        lifeTime = _lifeTime,
        buffCfgName = "BUFF_BorisTarget"
    }
    self.buffSystem:AddBuff(data)
end

function RAFU_FightUnit_Basic:whiteFlashBuff(param)
    
    local _lifeTime = param.lifeTime or 2
    local data = {
        lifeTime = _lifeTime,
        buffCfgName = "BUFF_WhiteFlash"
    }
    self.buffSystem:AddBuff(data)
end


--获取主骨骼位置的偏移
function RAFU_FightUnit_Basic:_getCoreBonePosOffset()
    if self.coreBoneOffset == nil then
        self.coreBoneOffset = 0
        if self.coreBone then
            self.coreBoneOffset = self.coreBone:getOffsetY()
        end
        return self.coreBoneOffset
    else
        return self.coreBoneOffset
    end
    
end

--初始化骨骼
function RAFU_FightUnit_Basic:_initBones(data)
	self.boneManager = {}
	local boneCfg = data.Bones
	local owner = self

    --主骨骼
    self.coreBone = nil
    if boneCfg == nil then 
        return
    end
	for boneName,oneBoneCfg in pairs(boneCfg) do
        if oneBoneCfg.BoneFrameClass ~= nil then
            local boneFrameClass = oneBoneCfg.BoneFrameClass
		    local oneBoneInstance = RARequire(boneFrameClass).new(owner,oneBoneCfg)

            if oneBoneCfg.turnPeriod ~= nil then 
                oneBoneInstance.turnPeriod = oneBoneCfg.turnPeriod
            else
                oneBoneInstance.turnPeriod = self.data.turnPeriod
            end 
		    self.boneManager[boneName] = oneBoneInstance
            --设置默认的主骨骼
            if self.coreBone == nil then self.coreBone = oneBoneInstance end
        end
		
	end

    --设置主骨骼，用来标记实体位置等
    if boneCfg.CoreBone ~= nil then
        self.coreBone = self.boneManager[boneCfg.CoreBone]
    end


end


--初始化状态机
function RAFU_FightUnit_Basic:_initStateManager(data)
    self.stateManager = {}

    local stateCfg = data.State
    local Utilitys = RARequire('Utilitys')
    assert(stateCfg~= nil and Utilitys.table_count(stateCfg) >0)
    for action,actionClass in pairs(data.State) do
    	local stateInstance = RARequire(actionClass).new(self)
    	self.stateManager[action] = stateInstance
    end
end

--初始化BUFF系统
function RAFU_FightUnit_Basic:_initBuffSystem()
    self.buffSystem = RARequire("RAFU_BuffSystem").new(self)
end

--初始化武器
function RAFU_FightUnit_Basic:_initWeapon(data)
	local weaponCfgName = data.Weapon
    if weaponCfgName == nil or weaponCfgName == 'None' then return end
	local RAFU_Cfg_Weapon = RARequire("RAFU_Cfg_Weapon")
    local cfgData = RAFU_Cfg_Weapon[weaponCfgName]
	local weaponClass = cfgData.weaponClass
    local weaponInstance = RARequire(weaponClass).new(self,weaponCfgName)
	self.weapon = weaponInstance
end

-- 用于子类添加个性化属性
function RAFU_FightUnit_Basic:_initSpecificProperty()
    
end

------------Public function------------------------
--[[实现战斗单元的变色需求
提供兵种变色接口changeMaskColor()
需要美术1.抠图 2.改名为.color.png  .mask.png 3. 运行texture.py 脚本 生成 r g 通道的图
example: self.fightUnit:changeMaskColor(MaskColors.BLUE)
colorParam is defined in RAFightDefine
]]
function RAFU_FightUnit_Basic:changeMaskColor(colorParam)
    for k,boneController in pairs(self.boneManager) do
        boneController:changeMaskColor(colorParam)
    end
end

--获取根节点的父节点
function RAFU_FightUnit_Basic:getParent()
	if self.rootNode~= nil then
		return self.rootNode:getParent()
	end
	return nil
end

--设置单元的TilePos
function RAFU_FightUnit_Basic:setTilePos(tilePos)
	local RABattleSceneManager = RARequire('RABattleSceneManager')
	local pos = RABattleSceneManager:tileToSpace(tilePos)
 	self.rootNode:setPosition(pos.x,pos.y)
    self.tilePos = tilePos
    if self.data.confData.type ~= BattleField_pb.UNIT_PLANE then
        RABattleSceneManager:setTilePos(self.tilePos, self.data.size.width, self.data.size.height, {id = self.id, confData = self.data.confData})
    end
end

--拿到当前根节点的位置
function RAFU_FightUnit_Basic:getPosition()
	return RA_GET_POSITION(self.rootNode)
end

--获取实体的中心点
function RAFU_FightUnit_Basic:getCenterPosition()
    --返回实体中心点的偏移
    local coreBone_offsetY = self:_getCoreBonePosOffset()

    local pos = RA_GET_POSITION(self.rootNode)
    pos.y = pos.y - self.centerOffset + coreBone_offsetY
    return pos
end

--获得受击点位置，默认是实体中心点
function RAFU_FightUnit_Basic:getHitPosition()
    return self:getCenterPosition()
end

function RAFU_FightUnit_Basic:getDir()
	return self.curDir
end

function RAFU_FightUnit_Basic:setDir(dir)
    if dir ~= FU_DIRECTION_ENUM.DIR_NONE then 
        self.curDir = dir
    end
end

--设置初始方向
function RAFU_FightUnit_Basic:setInitDirection(dir)
	self:setDir(dir)
    local param = {
        callback = nil,--回调
        needSwitch = false,--是否强制转向
        isforce = true,--是否强制改变动作
        newFps = nil,--新的播放fps
        startFrame = nil--新的开始帧
    }
	for k,boneController in pairs(self.boneManager) do
		boneController:changeAction(ACTION_TYPE.ACTION_IDLE, dir,param)
	end
end

--更新ZOrder
function RAFU_FightUnit_Basic:updateZorder()
    if self.zorderFrameCount == nil then
        self.zorderFrameCount = 0
    end
    self.zorderFrameCount = self.zorderFrameCount + 1
    --每五帧更新一次Zorder
    if self.isAlive and self.zorderFrameCount>5 then
        self.zorderFrameCount = 0
        local centerPosition = self:getCenterPosition()
        local baseZOrder = 0
        if self.data.confData.type == BattleField_pb.UNIT_PLANE or 
            self.data.confData.type == BattleField_pb.UNIT_AIR_FOOT or 
            self.data.confData.type>=100 or
            --空中伞兵层级要高
            self.data.confData.id == 1013 then  
            baseZOrder = 20000
        end
        self.rootNode:setZOrder(baseZOrder - 1 * centerPosition.y )
    end
end

function RAFU_FightUnit_Basic:setTileMap( )
    if self.isAlive then
        self.crashCount = self.crashCount or 0
        self.crashCount = self.crashCount + 1        
        if self.crashCount > 5 then
            local RABattleSceneManager = RARequire('RABattleSceneManager')
            local tilePos = RABattleSceneManager:spaceToTile(self:getPosition())
            if RACcpEqual(tilePos, self.tilePos) == false then
                if self.tilePos then
                    RABattleSceneManager:removeTilePos(self.tilePos, self.data.size.width, self.data.size.height, {id = self.id, confData = self.data.confData})   
                end             
                self.tilePos = tilePos
                RABattleSceneManager:setTilePos(self.tilePos, self.data.size.width, self.data.size.height, {id = self.id, confData = self.data.confData})
            end
        end
    end
end

--切换状态,同时传入数据
function RAFU_FightUnit_Basic:changeState(state,data)
    -- RALogRelease("RAFU_FightUnit_Basic:changeState from curState "..self.curState.."to state "..state)
    if self.stateManager[state] == nil then
        RALogError("RAFU_FightUnit_Basic:changeState  state is nor right: "..state)
        return
    end
    if self.curState and self.stateManager[self.curState] then        
        self.stateManager[self.curState]:Exit()
    end
    self.curState = state
    if self.curState and self.isAlive then

        self.stateManager[self.curState]:Enter(data)
        --播放该unitid + state对应的声音系统
        local unitItemId = self.data.confData.id


        if self.data.unitType == ATTACKER then
            RARequire("RAFightSoundSystem"):playUnitVoiceSound(unitItemId,self.curState)
        end
        --播放该unitid + state对应的动作声音系统
        RARequire("RAFightSoundSystem"):playUnitActionSound(unitItemId,self.curState)

    end

end

function RAFU_FightUnit_Basic:checkCrash(  )
    -- print("checkCrash -- self.id = ",self.id)
    if self.isAlive then
        self.crashCount = self.crashCount or 0
        self.crashCount = self.crashCount + 1        
        if self.crashCount > 5 then        
            local RABattleSceneManager = RARequire('RABattleSceneManager')
            local RABattleConfig = RARequire("RABattleConfig")
            local tilePos = RABattleSceneManager:spaceToTile(self:getPosition())

            if self.coreBone then
                local isCrash, crashUnit = RABattleSceneManager:isCrashInTile( tilePos, self.id, {4} )

                if isCrash and self.coreBone.isCrashUp == RABattleConfig.AircraftCrashType.CRASH_STAND then
                    for k,boneController in pairs(self.boneManager) do
                        if boneController.crashUp then
                            boneController:crashUp(crashUnit)
                        end
                    end
                    
                end
                if self.coreBone.isCrashUp == RABattleConfig.AircraftCrashType.CRASH_HIGH and isCrash == false then
                    for k,boneController in pairs(self.boneManager) do
                        if boneController.crashDrop then
                            boneController:crashDrop()
                        end
                    end                
                end
            end
        end
    end
end

--兵种转换到死亡层，指死亡的城墙之类的
function RAFU_FightUnit_Basic:changeToDieLayer()
    local RABattleScene = RARequire('RABattleScene')
    self.rootNode:retain()
    self.rootNode:removeFromParentAndCleanup(false)
    RABattleScene.mBattleUnitDieLayer:addChild(self.rootNode)
    self.rootNode:release()
end

function RAFU_FightUnit_Basic:changetToAliveLayer()
    local RABattleScene = RARequire('RABattleScene')
    self.rootNode:retain()
    self.rootNode:removeFromParentAndCleanup(false)
    RABattleScene.mBattleUnitLayer:addChild(self.rootNode)
    self.rootNode:release()
end

-- function ( ... )
--     -- body
-- end

function RAFU_FightUnit_Basic:upgradeLevel()
    if self.isUpgrade == true then

    else
        self.isUpgrade = true
        self.levelFlag:setVisible(true)
        self:whiteFlashBuff({})
    end
end

function RAFU_FightUnit_Basic:addAttackTime()
    self.attackTime = self.attackTime + 1
    if self.levelFlag and self.attackTime%10 ==0 then
        local isCan  = math.random(1,6)
        if isCan == 1 or isCan == 5 then 
            self:upgradeLevel()
        end
    end
end

function RAFU_FightUnit_Basic:Die()
    self.isAlive = false
    self.data.hp = 0
    self.rootNode:setVisible(false)
    RA_SAFE_RELEASE(self.buffSystem)
end

function RAFU_FightUnit_Basic:Alive()
    self.curState = ACTION_TYPE.ACTION_IDLE
    self.curDir = FU_DIRECTION_ENUM.DIR_DOWN
    self:changetToAliveLayer()
    self.rootNode:stopAllActions()
    self.data:reset()
    self.isAlive = true
    self.state = 0
    self.isUpgrade = false
    self.attackTime = 0
    if self.levelFlag then
        self.levelFlag:setVisible(false)
    end

    self.rootNode:setVisible(true)
    for boneName,boneController in pairs(self.boneManager) do
        boneController:initSpriteInfo()
        boneController:setVisible(true)
    end
    self:updateCount()
    self:changeState(STATE_TYPE.STATE_IDLE) 
end


function RAFU_FightUnit_Basic:Execute(dt)
    if self.isAlive == false then
        return 
    end
    -- 需要的state才会去 Execute
    if self.curState and self.stateManager[self.curState] and self.stateManager[self.curState]:GetIsExecute() then        
        self.stateManager[self.curState]:Execute(dt)
    end

    RA_SAFE_EXECUTE(self.weapon,dt)

    RA_SAFE_EXECUTE(self.buffSystem,dt)

    self:updateZorder(dt)

    if self.curState == STATE_TYPE.STATE_MOVE then
        if self.type ~= BattleField_pb.UNIT_PLANE then
            if self.type ~= BattleField_pb.UNIT_DEFENCE and self.type ~=  BattleField_pb.UNIT_BUILDING then 
                self:setTileMap()
            end
        else
            self:checkCrash()
        end
    end
    self:_executeSpecific(dt)
end

-- 方便子类添加自己的刷新逻辑
function RAFU_FightUnit_Basic:_executeSpecific(dt)
    
end

--方便子类添加自己的降落逻辑
function RAFU_FightUnit_Basic:HelicopterLand()
    
end

--方便子类添加自己的升起逻辑
function RAFU_FightUnit_Basic:HelicopterRise()
    
end

return RAFU_FightUnit_Basic