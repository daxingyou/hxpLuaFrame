local gameStateQuene = { gameMainState = { priority = 1,pages = {}},
						gameTerrainState = { priority = 1,pages = {}}
						}						
PriorityQuene = {}
PriorityQuene.priorityLevel = { 
								Exit = 1030,
								NAME_CHOOSE = 1020,
								MENU = 1010,
								Animation = 1000,
								LEVEL_UP = 990,
								YES_NO = 980,
								BaseAttacked = 975,
								MISSION_COMPLETE = 970,
								MISSION_STORY = 965,
								RookieBlessing = 964,
								MISSION_OPEN = 960,
								NORMAL = 950,								
								BATTLE_FAIL = 930,
								PopSkillInfo = 920,
								}
local function getCurrentStateQuene()
	if GameStateMachine.getState() == GameMainState then
		return gameStateQuene.gameMainState	
	elseif GameStateMachine.getState() == GameBattleState then
		return gameStateQuene.gameTerrainState
	end
	return {}
end
local function getStateQuene(gameState)
	if gameState == GameMainState then
		return gameStateQuene.gameMainState
	elseif gameState == GameBattleState then
		return gameStateQuene.gameTerrainState
	end
	return {}
end
function PriorityQuene.pushToQuene(priorityLevel,page,gameState)								
	local quene = getStateQuene(gameState)
	for k,v in ipairs(quene) do
		if v.priority == priorityLevel then		
			table.insert(v.pages,1,page)
			return
		end
	end
	local temp = {priority = priorityLevel,pages = {page}}
	local index = #quene + 1
	for k,v in ipairs(quene) do
		if v.priority < temp.priority then
			index = k
			break
		end
	end
	table.insert(quene, index, temp)	
end

function PriorityQuene.topQuene()
	local quene = getCurrentStateQuene()
	for _,v in ipairs(quene) do	
		for _,k in ipairs(v.pages) do
			return k
		end
	end
	return nil
end

function PriorityQuene.popQuene()
	local quene = getCurrentStateQuene()
	for _,v in ipairs(quene) do
		for j,k in ipairs(v.pages) do
			if k then				
				v.pages[j] = nil
				v.pages = Utilitys.table_values(v.pages)
				return
			end					
		end
	end
end

function PriorityQuene.delFromeQuene(page,gameState)
	local quene = getStateQuene(gameState)
	for _,v in ipairs(quene) do
		if v.priority == page:getPriority() then
			for j,k in ipairs(v.pages) do
				if k == page then				
					v.pages[j] = nil
					v.pages = Utilitys.table_values(v.pages)
					return
				end					
			end
		end
	end
end