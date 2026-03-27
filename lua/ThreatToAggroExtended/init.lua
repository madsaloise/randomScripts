aura_env.threatPercent = 0
aura_env.aggroThreat = 0
aura_env.position = 1
aura_env.gapToFirst = 0
aura_env.gapToSecond = 0

-- Get highest non-tanking threat on the threat table
local highestThreatPercentage = 0
local highestThreatValue = 0
local _UnitDetailedThreatSituation = UnitDetailedThreatSituation

local function UpdateHighestThreat(unit, target)
    if not UnitExists(unit) then
        return
    end
    
    local isTanking, _, threatPct, _, threatValue = _UnitDetailedThreatSituation(unit, target)
    if threatPct == nil then
        return
    end
    
    if not isTanking and threatPct > highestThreatPercentage then
        highestThreatPercentage = threatPct
        highestThreatValue = threatValue
    end
end

aura_env.findHighestThreat = function(target)
    highestThreatPercentage = 0
    highestThreatValue = 0
    local isInRaid = IsInRaid()
    -- Find all party/raid members + pets
    for i = 1, GetNumGroupMembers() do
        local unit = nil
        local petUnit = nil
        if isInRaid then
            unit = format("raid%d", i)
            petUnit = format("raidpet%d", i)
        else
            unit = format("party%d", i)
            petUnit = format("partypet%d", i)
        end
        
        UpdateHighestThreat(unit, target)
        UpdateHighestThreat(petUnit, target)
    end
    
    -- Don't forget player pet
    UpdateHighestThreat("playerpet", target)
    
    return highestThreatPercentage, highestThreatValue
end

aura_env.findTankThreatValue = function(target)
    local isInRaid = IsInRaid()
    local isTanking
    local threatValue
    for i = 1, GetNumGroupMembers() do
        local unit = nil
        local petUnit = nil
        if isInRaid then
            unit = format("raid%d", i)
            petUnit = format("raidpet%d", i)
        else
            unit = format("party%d", i)
            petUnit = format("partypet%d", i)
        end
        
        isTanking, _, _, _, threatValue = _UnitDetailedThreatSituation(unit, target)
        if isTanking then return threatValue or 0 end
        
        isTanking, _, _, _, threatValue = _UnitDetailedThreatSituation(petUnit, target)
        if isTanking then return threatValue or 0 end
    end
    
    -- Don't forget player pet
    isTanking, _, _, _, threatValue = _UnitDetailedThreatSituation("playerpet", target)
    
    return threatValue or 0
end

aura_env.findPlayerPosition = function(target, playerThreatPercent)
    local isInRaid = IsInRaid()
    local playerPosition = 1
    local threatPercent = 0
    for i = 1, GetNumGroupMembers() do
        local unit = nil
        local petUnit = nil
        if isInRaid then
            unit = format("raid%d", i)
            petUnit = format("raidpet%d", i)
        else
            unit = format("party%d", i)
            petUnit = format("partypet%d", i)
        end
        
        _, _, threatPercent = _UnitDetailedThreatSituation(unit, target)
        if (threatPercent or 0) > playerThreatPercent then
            playerPosition = playerPosition + 1
        end
        
        _, _, threatPercent = _UnitDetailedThreatSituation(petUnit, target)
        if (threatPercent or 0) > playerThreatPercent then
            playerPosition = playerPosition + 1
        end
    end
    
    -- Don't forget player pet
    _, _, threatPercent = _UnitDetailedThreatSituation("playerpet", target)
    if (threatPercent or 0) > playerThreatPercent then
        playerPosition = playerPosition + 1
    end
    
    return playerPosition
end