function(e, ...)
    if e == "PLAYER_REGEN_ENABLED" then
        if aura_env.FailedCasts > 0 then 
            print("You sent "..aura_env.FailedCasts.." Hot Streaks while having SKB ready")
        end    
        aura_env.FailedCasts = 0
        return true
    end
end