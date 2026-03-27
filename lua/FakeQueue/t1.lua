function(event, timestamp, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, missType, isOffhand)
    if sourceGUID ~= UnitGUID("player") then return end
    
    if subEvent == "SWING_DAMAGE" then
        -- isOffhand is arg  16 for SWING_DAMAGE
        local offhand = select(16, ...)
        if not offhand then
            aura_env.resetSwing()
        end
        
    elseif subEvent == "SWING_MISSED" then
        -- missType=arg12, isOffhand=arg13 for SWING_MISSED  
        local mType, offhand = select(12, ...)
        if not offhand then
            -- Parry on player attack resets swing to full
            aura_env.resetSwing()
        end
        
    elseif subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED" then
        -- Check if it's a swing-resetting spell (HS, Cleave, Slam)
        if aura_env.slamResetSpells[spellId] then
            aura_env.resetSwing()
        end
    end
end
-- Events: CLEU:SWING_DAMAGE,CLEU:SWING_MISSED,CLEU:SPELL_DAMAGE,CLEU:SPELL_MISSED