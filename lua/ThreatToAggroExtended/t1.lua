function()
    ------------------------------------------------------------
    -- aggro logic + gap to #1 (tank) and #2 (top non-tank) on the overall threat table.                 --
    ------------------------------------------------------------
    
    local playerTarget = "target"
    local _UnitDetailedThreatSituation = UnitDetailedThreatSituation
    local _UnitExists = UnitExists
    
    -- Do not proceed unless live NPC is targeted
    if not _UnitExists(playerTarget) or
    UnitHealth(playerTarget) == 0 or
    UnitIsPlayer(playerTarget) or
    UnitIsFriend("player", playerTarget)
    then
        aura_env.threatPercent = 0
        aura_env.aggroThreat = 0
        aura_env.position = 1
        aura_env.gapToFirst = 0
        aura_env.gapToSecond = 0
        return false
    end
    
    local playerIsTanking, _, playerThreatPercent, _, playerThreatValue =
    _UnitDetailedThreatSituation("player", playerTarget)
    
    if playerThreatPercent == nil then
        return false
    end
    playerThreatValue = playerThreatValue or 0
    
    -- #2 overall = highest non-tank on the threat table
    local highestThreatPercentage, highestThreatValue =
    aura_env.findHighestThreat(playerTarget)
    
    -- Gap to #2 (highest non-tank): positive = they're above us
    aura_env.gapToSecond = math.floor(((highestThreatValue or 0) - playerThreatValue) / 100)
    
    if not playerIsTanking then
        -- Gap to #1 (tank): derive tank threat from the API
        if playerThreatValue == 0 then
            local tankThreat = aura_env.findTankThreatValue(playerTarget)
            aura_env.gapToFirst = math.floor(tankThreat / 100)
            local aggroModifier = CheckInteractDistance(playerTarget, 3) and 1.1 or 1.3
            aura_env.aggroThreat = tankThreat * aggroModifier
        else
            local tankThreat = playerThreatValue * 100 / playerThreatPercent
            aura_env.gapToFirst = math.floor((tankThreat - playerThreatValue) / 100)
            aura_env.aggroThreat = tankThreat - playerThreatValue
        end
        
        if aura_env.config["show_position"] then
            aura_env.position = aura_env.findPlayerPosition(playerTarget, playerThreatPercent)
        end
    else
        -- We ARE #1
        aura_env.position = 1
        aura_env.gapToFirst = 0
        playerThreatPercent = 100
        
        if highestThreatPercentage == 0 then
            aura_env.aggroThreat = playerThreatValue > 0 and -playerThreatValue * 1.1 or 0
        else
            aura_env.aggroThreat = highestThreatValue - highestThreatValue * 100 / highestThreatPercentage
        end
    end
    
    aura_env.threatPercent = math.floor(playerThreatPercent)
    aura_env.aggroThreat = math.floor(aura_env.aggroThreat / 100)
    
    return true
end