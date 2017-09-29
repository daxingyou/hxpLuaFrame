-- EnterFrameDefine

-- TimeCalculator also define here

-- enter frame define
-- warning!!!!
-- keep id code is unique!!!

local EnterFrameDefine = {

	-- id for TimeCalculator
	-- 110001 ~ 120000
	TimeCalculator = {
		EF_TestTime = '110001',		
	},

	-- id for Action
	-- 120001 ~ 130000
	Action = {
		-- used in RAActionManager 
		EF_NumLabelChangeAction = '120001',

		-- used in RAActionManager 
		EF_MoveToAction = '120002',		

        -- used in RAActionManager 
		EF_Scale9SpriteChangeAction = '120003',	
        
        -- used in RAActionManager
        EF_RAGridProcessBarAction = '120004',	
	},


	-- id for MainUI
	-- 130001 ~ 140000
	MainUI = {
		-- used in RAMainUIQueueHelper 
		EF_QueueHelperUpdate = '130001',
		EF_NuclearHelperUpdate = '130002'
	},

	-- id for BuildingUI
	-- 140001 ~ 150000
	BuildingUI = {
		-- used in BuildingUI 
		EF_BuildingUpdate = '140001'
	},

	-- id for TreasureBox
	-- 150001 ~ 160000
	TreasureBox = {
		-- used in BuildingUI 
		EF_TreasureBoxUpdate = '150001'
	},

	Guide = {
		EF_GuideUpdate = '160001'
	}
	-- -- id for example
	-- -- 900900 ~ 900999
	-- Example = {
	-- 	EF_Example = '900900',
	-- 	EF_LoginSuccess = '900901'
	-- }

}

return EnterFrameDefine