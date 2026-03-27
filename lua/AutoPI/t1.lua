--
-- Author: Chilly @ Draenor
--
function(e, arg1)
    if e == "GROUP_ROSTER_UPDATE" or e == "CHALLENGE_MODE_START" or e == "PLAYER_ENTERING_WORLD" or "PLAYER_FOCUS_CHANGED" or (e == "UNIT_PET" and arg1 == "player") or e == "PLAYER_REGEN_ENABLED" then
        
        
        if InCombatLockdown() then
            aura_env.needUpdate = true
        else
            aura_env.UpdatePI()
        end
    elseif aura_env.needUpdate then
        aura_env.UpdatePI()
        aura_env.needUpdate = false
        
    end
    
end