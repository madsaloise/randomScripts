function (allstates, event, ...)
    
    if event == "FRAME_UPDATE" then
        if not aura_env.last then
            aura_env.last = GetTime()
        elseif aura_env.last < GetTime() - 10 then
            aura_env.last = GetTime()
            local StatesUpdated = false
            for _, state in pairs(allstates) do
                local unit = state.unit
                if unit then
                    --Player Dead
                    local isDead = UnitIsDeadOrGhost(unit) or (not UnitIsConnected(unit)) or (not UnitIsVisible(unit))
                    if isDead ~= state.isDead then
                        state.isDead = isDead
                        state.changed = true
                        StatesUpdated = true
                    end
                    --Player out of Range
                    local outOfRange = WeakAuras.CheckRange(unit, 100, ">=")
                    if outOfRange ~= state.outOfRange then
                        state.outOfRange = outOfRange
                        state.changed = true
                        StatesUpdated = true
                    end
                end
            end
            if StatesUpdated == true then
                -- only return true if data actually changed (so the ui doesn't update for 0 reason)
                return true
            end
        end
    elseif event == "SPELL_COOLDOWN_READY" then
        local spellID = ...
        if aura_env.spells[spellID] then
            local guid = UnitGUID("PLAYER")
            local state = allstates[guid .. " " .. spellID]
            if state and state.expirationTime and state.expirationTime > GetTime() then
                -- send an update via addonmessages if cooldow is ready faster then it should be
                local serverTime = GetServerTime()
                local remainingCooldownDuration = state.expirationTime - GetTime()
                local serverExpirationTime = serverTime+ remainingCooldownDuration
                
                C_ChatInfo.SendAddonMessage(aura_env.Prefix,
                    spellID .. ":" .. guid .. ":" .. serverExpirationTime .. ":" .. serverTime,
                    IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "instance_chat" or IsInRaid() and "raid" or "party")
                state.expirationTime = GetTime()
                state.changed = true
                return true
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        -- catch cooldown updates send by other aura users
        local prefix, msg = ...
        if prefix == aura_env.Prefix then
            local spellID, guid, serverExpirationTime, time = string.split(":", msg)
            if allstates[guid .. " " .. spellID] then
                local state = allstates[guid .. " " .. spellID]
                local serverTime = GetServerTime()
                local expirationDuration = serverExpirationTime-serverTime
                local expirationTime = state.expirationTime
                local timeDifference = expirationTime-GetTime()-expirationDuration
                -- if either the difference between expirationTime or difference between serverTimes is less then a second we want to adjust the CD
                if (timeDifference >-1) and (timeDifference<1)  or (serverTime - time)<1 and (serverTime - time )>-1 then
                    state.expirationTime = GetTime()
                    state.changed = true
                    return true
                end
            end
        end
    elseif event == "STATUS" then
        for unit in WA_IterateGroupMembers() do
            -- idk why the event is like this but alas
            WeakAuras.ScanEvents("UNIT_SPEC_CHANGED_"..unit, unit)
        end
        return true
    elseif event == "OPTIONS" or event == "CHALLENGE_MODE_START" or event == "GROUP_ROSTER_UPDATE" and not C_PartyInfo.IsDelveInProgress() then
        -- If people leave the group we want to throw away their states. Additionally if people join the group that have previously been in the group the LibSpec callback doesn't fire so we manually update it in that case.
        
        -- since matching states and doing shenanigans can create different issues we just throw away all states and recreate them
        -- remove all states and create new ones
        
        local guidList = {}
        for unit in WA_IterateGroupMembers() do
            local guid = UnitGUID(unit)
            guidList[guid] = unit
            WeakAuras.ScanEvents("UNIT_SPEC_CHANGED_"..unit, unit)
        end
        for _, state in pairs(allstates) do
            if not guidList[state.guid] then
                state.show = false
                state.changed = true
            end
        end
        
        return true
        
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "UNIT_SPELLCAST_SUCCEEDED" and select(3, ...) == 384255 then
        -- if a player respecs or changes talents we need to throw away their currently active states before creating new ones when the callback fires
        local unit, _, _ = ...
        local guid = UnitGUID(unit)
        for _, state in pairs(allstates) do
            if (state.guid == guid) then
                state.show = false
                state.changed = true
            end
        end
        return true
    elseif event == "UNIT_SPEC_CHANGED_player" or event == "UNIT_SPEC_CHANGED_party1" or event == "UNIT_SPEC_CHANGED_party2" or event == "UNIT_SPEC_CHANGED_party3" or event == "UNIT_SPEC_CHANGED_party4" or event == "UNIT_SPEC_CHANGED" then
        --if not aura_env.wasInitialized then aura_env.wasInitialized = true end
        local unit = ...
        local specID = WeakAuras.SpecForUnit(unit)
        local name = UnitName(unit)
        if not unit or not specID or not aura_env.ClassList or not aura_env.ClassList[specID] or aura_env.ClassList[specID] == nil then
            
            -- incase we don't have the required info available return early
            return
        end
        local guid = UnitGUID(unit)
        for spell, _ in pairs(aura_env.ClassList[specID]) do
            -- iterate over all spells in the list and create states
            if aura_env.getSpellIsActive(spell, specID, unit) then
                local cooldown = aura_env.getCooldownOfSpell(aura_env.ClassList[specID
                    ][spell], unit, spell)
                
                if not cooldown or cooldown == 0 then return end
                
                local spellInfo = C_Spell.GetSpellInfo(spell);
                local _, class,_ = UnitClass(unit)
                allstates[guid .. " " .. spell] = {
                    duration = cooldown,
                    expirationTime = GetTime(),
                    progressType = "timed",
                    autoHide = false,
                    changed = true,
                    show = true,
                    unit = unit,
                    name = name,
                    spellID = spell,
                    successful = false,
                    isDead = false,
                    --isPlayer = UnitIsUnit(unit, "player"),
                    outOfRange = false,
                    icon = spellInfo.iconID,
                    class = class,
                    guid = guid,
                    CD = cooldown,
                    useBarClassColor = aura_env.config.display.useBarClassColor,
                    useTextClassColor = aura_env.config.display.useTextClassColor
                }
                -- if state exists but shouldn't we want to remove it.
            elseif allstates[guid .. " " .. spell] then
                allstates[guid .. " " .. spell].show = false
                allstates[guid .. " " .. spell].changed = true
            end
        end
        return true
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        local guid = UnitGUID(unit)
        -- if it's a spell which reduces the cooldown of an interrupt spell we want to adjust it
        if aura_env.CastSuccessModifiers[spellID] then
            if aura_env.CastSuccessModifiers[spellID].talent and (not WeakAuras.CheckTalentForUnit(unit, aura_env.CastSuccessModifiers[spellID].talent) or WeakAuras.CheckTalentForUnit(unit, aura_env.CastSuccessModifiers[spellID].talent) == 0) then
                return 
            end
            
            if allstates[guid .. " " .. aura_env.CastSuccessModifiers[spellID].spell] then
                local state = allstates[guid .. " " .. aura_env.CastSuccessModifiers[spellID].spell]
                state.expirationTime = state.expirationTime - aura_env.CastSuccessModifiers[spellID].CD
                state.changed = true
                return true
            end
        end
        -- if it's a pet spell we need to adjust to properly display cooldowns
        if aura_env.petSpells[spellID] then
            guid , spellID = aura_env.adjustForPetInterrupts(guid, spellID)
        end
        
        -- otherwise if a state exists for the spell we want to put it on CD
        if allstates[guid .. " " .. spellID] then
            local state = allstates[guid .. " " .. spellID]
            state.changed = true;
            state.expirationTime = state.CD + GetTime()
            state.duration = state.CD
            return true
        elseif aura_env.spells[spellID] then
            -- if state somehow doesn't exist we need to create it
            local specID = WeakAuras.SpecForUnit(unit)
            if not specID or not aura_env.getSpellIsActive(aura_env.ClassList[specID][spellID], specID, unit) then return end
            local cooldown = aura_env.getCooldownOfSpell(aura_env.ClassList[specID][spellID], unit, spellID)
            if cooldown and cooldown ~= 0 then
                local spellInfo = C_Spell.GetSpellInfo(spellID);
                local _, class,_ = UnitClass(unit)
                allstates[guid .. " " .. spellID] = {
                    duration = cooldown,
                    expirationTime = GetTime(),
                    progressType = "timed",
                    autoHide = false,
                    changed = true,
                    show = true,
                    unit = unit,
                    name = UnitName(unit),
                    spellID = spellID,
                    successful = false,
                    isDead = false,
                    --isPlayer = UnitIsUnit(unit, "player"),
                    outOfRange = false,
                    icon = spellInfo.iconID,
                    class = class,
                    guid = guid,
                    CD = cooldown,
                    useBarClassColor = aura_env.config.display.useBarClassColor,
                    useTextClassColor = aura_env.config.display.useTextClassColor
                }
                return true
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, _, _, sourceGUID, _, _, _, destGUID, _, _, destRaidFlags, spellID, _, _, extraSpellID, _, _ = ...
        if aura_env.silenceMap[spellID] then spellID = aura_env.silenceMap[spellID] end
        --Attribute Pet Spell's to its owner
        local sourceType = strsplit("-", sourceGUID)
        if sourceType == "Pet" or sourceType == "Creature" then
            sourceGUID , spellID = aura_env.adjustForPetInterrupts(sourceGUID, spellID)
        end
        if sourceGUID and spellID then
            local state = allstates[sourceGUID .. " " .. spellID]
            if state then
                -- if it is a spell that reduces it's cooldown if succesffuly interrupted adjust cd
                if aura_env.InterruptSuccessModifiers[spellID] then
                    if aura_env.InterruptSuccessModifiers[spellID] and aura_env.InterruptSuccessModifiers[spellID].talent and 
                    WeakAuras.CheckTalentForUnit(state.unit, aura_env.InterruptSuccessModifiers[spellID].talent)
                    and
                    WeakAuras.CheckTalentForUnit(state.unit, aura_env.InterruptSuccessModifiers[spellID].talent) == 1 then
                        local currentCD = state.expirationTime - GetTime()
                        currentCD = currentCD - aura_env.InterruptSuccessModifiers[spellID].CD
                        state.expirationTime = GetTime() + currentCD
                    end
                end
                -- add an icon of the interrupted spell if option is selected
                local spellInfo = C_Spell.GetSpellInfo(extraSpellID);
                state.extraIcon = aura_env.config.advanced.showSpell and ("\124T%s:0\124t"):format(spellInfo.iconID)
                state.successful = true
                -- add mark icon
                local mark = math.log(destRaidFlags) / math.log(2) + 1
                if ICON_LIST[mark] then
                    state.raidIcon = aura_env.config.advanced.showTarget and ("{rt%i}"):format(mark)
                else
                    state.raidIcon = nil
                end
                state.changed = true
                return true
            end
        end
    end
end