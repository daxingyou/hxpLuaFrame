--region *.lua
--Date

local RAWorldUIManager =
{
	mRootNode = nil
}

local RAWorldHudManager = RARequire('RAWorldHudManager')
local RAWorldMigrateHelper = RARequire('RAWorldMigrateHelper')
local RAWorldTargetHelper = RARequire('RAWorldTargetHelper')
local RAWorldBuildSiloHelper = RARequire('RAWorldBuildSiloHelper')
local RAWorldMath = RARequire('RAWorldMath')

function RAWorldUIManager:Init(rootNode)
	self.mRootNode = rootNode
    RAWorldHudManager:Init(rootNode)
    RAWorldMigrateHelper:Init(rootNode)
    RAWorldTargetHelper:Init(rootNode)
    RAWorldBuildSiloHelper:Init(rootNode)
end

function RAWorldUIManager:Execute()
    RAWorldHudManager:Execute()
end

function RAWorldUIManager:Clear()
    self:RemoveHud(nil, true)
    RAWorldMigrateHelper:Clear()
    RAWorldTargetHelper:Clear()
    RAWorldBuildSiloHelper:Clear()
end

function RAWorldUIManager:onSingleTouchBegin(touchPos, touch)
    if RAWorldMigrateHelper:IsOnTouch(touchPos, touch) then
        return true
    elseif RAWorldTargetHelper:IsOnTouch(touchPos, touch) then
        return true
    elseif RAWorldBuildSiloHelper:IsOnTouch(touchPos, touch) then
        return true
    end
    return false
end

function RAWorldUIManager:onSingleTouchMoved(offset,touchPos,touchSpacePos)
    if self:IsMigrating() then
        RAWorldMigrateHelper:Migrating(offset, touchPos, touchSpacePos)
    elseif self:IsTargeting() then
        RAWorldTargetHelper:Targeting(offset)
    elseif self:IsBuildingSilo() then
        RAWorldBuildSiloHelper:BuildingSilo(offset, touchPos, touchSpacePos)
    end
end

function RAWorldUIManager:onSingleTouchEnd(viewPos)
    if self:IsMigrating() or self:IsTargeting() or self:IsBuildingSilo() then
        self:StopMoving()
    else
        local mapPos = RAWorldMath:View2Map(viewPos, true)
        self:ShowHud(mapPos)
    end
end

function RAWorldUIManager:StopMoving()
    RAWorldMigrateHelper:StopMigrate()
    RAWorldTargetHelper:StopTarget()
    RAWorldBuildSiloHelper:StopBuildSilo()
end

-------------------------------------------------
-- region: hud

function RAWorldUIManager:ShowHud(mapPos, doCleanup)
    self:StopMoving()
    if doCleanup then
        RAWorldHudManager:RemoveHud()
    end
    RAWorldHudManager:ShowHud(mapPos)
end

function RAWorldUIManager:RemoveHud(mapPos)
    RAWorldHudManager:RemoveHud(mapPos)
end

-- endregion: hud
-------------------------------------------------
-- region: migrate

function RAWorldUIManager:doMigrate(mapPos)
    RAWorldMigrateHelper:BeginMigrate(mapPos)
end

function RAWorldUIManager:IsMigrating()
    return RAWorldMigrateHelper:IsMigrating()
end

function RAWorldUIManager:OnMigrateRsp(isOK, migratePos, hasTip)
    RAWorldMigrateHelper:OnMigrateRsp(isOK, migratePos, hasTip)
end

-- endregion: migrate
-------------------------------------------------
-- region: buildSilo

function RAWorldUIManager:doBuildSilo(mapPos)
    RAWorldBuildSiloHelper:BeginBuildSilo(mapPos)
end

function RAWorldUIManager:IsBuildingSilo()
    return RAWorldBuildSiloHelper:IsBuildingSilo()
end

function RAWorldUIManager:OnBuildRsp(isOK)
    RAWorldBuildSiloHelper:OnBuildRsp(isOK)
end
-- endregion: buildSilo
-------------------------------------------------
-- region: target

function RAWorldUIManager:doTarget(mapPos)
    RAWorldTargetHelper:BeginTarget(mapPos)
end

function RAWorldUIManager:IsTargeting()
    return RAWorldTargetHelper:IsTargeting()
end

function RAWorldUIManager:OnTargetRsp(isOK)
	RAWorldTargetHelper:OnTargetRsp(isOK)
end

-- endregion: target
-------------------------------------------------

return RAWorldUIManager

--endregion