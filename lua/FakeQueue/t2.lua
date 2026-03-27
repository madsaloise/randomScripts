function(event, ...)
    if event == "UNIT_INVENTORY_CHANGED" then
        -- Weapon swap: reset 
        aura_env.updateWeaponSpeed()
        aura_env.swingTimer = 0
        aura_env.swingEndTime = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        aura_env.weaponSpeed = UnitAttackSpeed("player") or 2
        aura_env.prevWeaponSpeed = aura_env.weaponSpeed
        aura_env.swingTimer = 0
        aura_env.swingEndTime = nil
    end
end
-- Events: UNIT_INVENTORY_CHANGED, PLAYER_ENTERING_WORLD