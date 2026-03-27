local a = aura_env
--
-- Original author: Chilly @ Draenor
-- Modified to work in DF by: Qweekk/Whattheqweek @ Kazzak
-- Modified for PI by: Aloise/Búttplúg @ Kazzak


aura_env.prio = {
    9,
    6,
    3,
    13,
    7,
    8,
    1,
    4,
    11,
    2,
    10,
    12,
    5
}

if not _G["AutoPI"] then
    local locale = GetLocale()
    local _, class, _ = UnitClass("player")
    a.btn = CreateFrame("Button", "AutoPI", UIParent, "SecureActionButtonTemplate")
    a.btn:SetAttribute("type", "spell")
    a.btn:SetAttribute("unit", "player")
    if class == "PRIEST" then  
        a.btn:SetAttribute("spell", "Power Infusion")    
        
    end
    a.btn:SetAttribute("checkselfcast", false)
    a.btn:SetAttribute("checkfocuscast", false)
else
    a.btn = _G["AutoPI"]
end


function aura_env.UpdatePI()
    if aura_env.config.focus and UnitExists("focus") and UnitIsFriend("player", "focus")  then
        aura_env.btn:SetAttribute("unit", "focus")
        return
    end
    -- Moved to custom options
    --for _, v in ipairs(aura_env.PINames) do
    for _, v in ipairs(aura_env.config.PriorityTargets) do 
        
        for unit in WA_IterateGroupMembers() do
            if v.Names == UnitName(unit) --and UnitGroupRolesAssigned(unit) == "DAMAGER" 
            then
                aura_env.btn:SetAttribute("unit", unit)
                return
            end
        end
    end
    
    
    --fall back on class priority
    if IsInGroup() then
        for _,v in ipairs(aura_env.prio) do
            
            for unit in WA_IterateGroupMembers() do
                local _,_,unitclass = UnitClass(unit)
                if unitclass == v and UnitGroupRolesAssigned(unit) == "DAMAGER" and UnitName(unit) ~= UnitName("Player") 
                then 
                    aura_env.btn:SetAttribute("unit", unit)
                    
                    return
                end
            end
            
            
            
        end
    else
        aura_env.btn:SetAttribute("unit", "player")
        
    end
    
    
    
    
    
end






