---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

addon_data.core = {}

addon_data.core.core_frame = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
local frame = addon_data.core.core_frame

frame:RegisterEvent("ADDON_LOADED")

addon_data.core.all_timers = {
    addon_data.player, addon_data.target
}

local version = "2.3.1"

local load_message = L"Thank you for installing WeaponSwingTimer Version" .. " " .. version .. 
                    " " .. L"by Skad! Use |cFFFFC300/wst|r for more options."
addon_data.core.default_settings = {
    one_frame = false,
    welcome_message = true
}

addon_data.core.in_combat = false

local class = select(2, UnitClass("player"))
local isHunter = class == "HUNTER"

local swing_reset_spells = {}
swing_reset_spells["DRUID"] = addon_data.spells.GetSpellIDs(L"Maul")
swing_reset_spells["HUNTER"] = addon_data.spells.GetSpellIDs(L"Raptor Strike")
swing_reset_spells["MAGE"] = {}
swing_reset_spells["PALADIN"] = {}
swing_reset_spells["PRIEST"] = {}
swing_reset_spells["ROGUE"] = {}
swing_reset_spells["SHAMAN"] = {}
swing_reset_spells["WARLOCK"] = {}
swing_reset_spells["WARRIOR"] = addon_data.spells.GetSpellIDs(L"Heroic Strike", L"Cleave", L"Slam")

local function LoadAllSettings()
    addon_data.core.LoadSettings()
    addon_data.player.LoadSettings()
    addon_data.target.LoadSettings()
    addon_data.warrior.LoadSettings()
    addon_data.druid.LoadSettings()
    addon_data.hunter.LoadSettings()
    addon_data.shaman.LoadSettings()
    addon_data.castbar.LoadSettings()
end

function addon_data.core.RestoreAllDefaults()
    addon_data.core.RestoreDefaults()
    addon_data.player.RestoreDefaults()
    addon_data.target.RestoreDefaults()
    addon_data.warrior.RestoreDefaults()
    addon_data.druid.RestoreDefaults()
    addon_data.hunter.RestoreDefaults()
    addon_data.shaman.RestoreDefaults()
    addon_data.castbar.RestoreDefaults()
end

local function InitializeAllVisuals()
    addon_data.player.InitializeVisuals()
    addon_data.target.InitializeVisuals()
    if class == "WARRIOR" then
        addon_data.warrior.InitializeVisuals()
    elseif class == "DRUID" then
        addon_data.druid.InitializeVisuals()
    elseif class == "HUNTER" then
        addon_data.hunter.InitializeVisuals()
        addon_data.castbar.InitializeVisuals()
    elseif class == "SHAMAN" then
        addon_data.shaman.InitializeVisuals()
    end
    addon_data.config.InitializeVisuals()
end

function addon_data.core.UpdateAllVisualsOnSettingsChange()
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.target.UpdateVisualsOnSettingsChange()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
    addon_data.druid.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.shaman.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.core.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_core_settings then
        character_core_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.core.default_settings) do
        if character_core_settings[setting] == nil then
            character_core_settings[setting] = value
        end
    end
end

function addon_data.core.RestoreDefaults()
    for setting, value in pairs(addon_data.core.default_settings) do
        character_core_settings[setting] = value
    end
end

local noop = function() end
local UPDATE_FUNCS = {
    ["WARRIOR"] = addon_data.warrior.OnUpdate,
    ["HUNTER"] = function(elapsed)
        addon_data.hunter.OnUpdate(elapsed)
        addon_data.castbar.OnUpdate(elapsed)
    end,
    ["SHAMAN"] = addon_data.shaman.OnUpdate,
}

local classFunc = UPDATE_FUNCS[class] or noop

local function CoreFrame_OnUpdate(self, elapsed)
    addon_data.player.OnUpdate(elapsed)
    addon_data.target.OnUpdate(elapsed)
    classFunc(elapsed)
end

function addon_data.core.MissHandler(unit, miss_type, is_offhand, is_player)
    if miss_type == "PARRY" then
        if unit == "player" then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = addon_data.target.main_weapon_speed * 0.2

            if min_swing_time >= addon_data.target.main_swing_timer then
                -- do nothing
            else
                addon_data.target.main_swing_timer = addon_data.target.main_swing_timer - (addon_data.target.main_weapon_speed * 0.4)

                if addon_data.target.main_swing_timer < min_swing_time then
                    addon_data.target.main_swing_timer = min_swing_time
                end
            end
            if not is_offhand then
            -- resets swing timer if it's not an extra attack, attempt to fix random resets mid-swing
                if (addon_data.player.extra_attacks_flag == false) then
                    addon_data.player.ResetMainSwingTimer()
                end
            addon_data.player.extra_attacks_flag = false
            else
                addon_data.player.ResetOffSwingTimer()
            end
        elseif unit == "target" and is_player then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = addon_data.player.main_weapon_speed * 0.2

            if min_swing_time >= addon_data.player.main_swing_timer then
                -- do nothing
            else
                addon_data.player.main_swing_timer = addon_data.player.main_swing_timer - (addon_data.player.main_weapon_speed * 0.4)

                if addon_data.player.main_swing_timer < min_swing_time then
                    addon_data.player.main_swing_timer = min_swing_time
                end
            end
            if not is_offhand then
                addon_data.target.ResetMainSwingTimer()
            else
                addon_data.target.ResetOffSwingTimer()
            end
        elseif unit == "target" then
            -- do nothing
        else
            addon_data.utils.PrintMsg(L"Unexpected Unit Type in MissHandler().")
        end
    else
        if unit == "player" then
            if not is_offhand then
                if (addon_data.player.extra_attacks_flag == false) then
            addon_data.player.ResetMainSwingTimer()
        end
        addon_data.player.extra_attacks_flag = false
            else
                addon_data.player.ResetOffSwingTimer()
            end
        elseif unit == "target" then
            if not is_offhand then
                addon_data.target.ResetMainSwingTimer()
            else
                addon_data.target.ResetOffSwingTimer()
            end
        else
            addon_data.utils.PrintMsg(L"Unexpected Unit Type in MissHandler().")
        end
    end
end

function addon_data.core.SpellHandler(unit, spell_id)
    if swing_reset_spells[class][spell_id] then
        if unit == "player" then
            addon_data.player.ResetMainSwingTimer()
        elseif unit == "target" then
            addon_data.target.ResetMainSwingTimer()
        else
            addon_data.utils.PrintMsg(L"Unexpected Unit Type in SpellHandler().")
        end
    end
end

function frame:OnAddonLoaded()
    self:UnregisterEvent("ADDON_LOADED")
    -- Attach the rest of the events and scripts to the core frame
    self:SetScript("OnUpdate", CoreFrame_OnUpdate)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    if class == "HUNTER" then
        self:RegisterEvent("START_AUTOREPEAT_SPELL")
        self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    end
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    -- Load the settings for the core and all timers
    LoadAllSettings()
    InitializeAllVisuals()
    -- Any other misc operations that happen at the start
    addon_data.player.ZeroizeSwingTimers()
    addon_data.target.ZeroizeSwingTimers()

    if character_core_settings.welcome_message then
        addon_data.utils.PrintMsg(load_message)
    end
end

function frame:ADDON_LOADED(name)
    if name ~= addon_name then return end
    self:OnAddonLoaded()
end

function frame:COMBAT_LOG_EVENT_UNFILTERED()
    local combat_info = {CombatLogGetCurrentEventInfo()}
    addon_data.player.OnCombatLogUnfiltered(unpack(combat_info))
    addon_data.target.OnCombatLogUnfiltered(unpack(combat_info))
    addon_data.queuing.OnCombatLogUnfiltered(unpack(combat_info))

    if isHunter then
        addon_data.hunter.OnCombatLogUnfiltered(unpack(combat_info))
        addon_data.castbar.OnCombatLogUnfiltered(unpack(combat_info))
    end
end

function frame:PLAYER_REGEN_DISABLED()
    addon_data.core.in_combat = true
end

function frame:PLAYER_REGEN_ENABLED()
    addon_data.core.in_combat = false
end

function frame:PLAYER_TARGET_CHANGED()
    addon_data.player.OnPlayerTargetChanged()
    addon_data.target.OnPlayerTargetChanged()
    addon_data.queuing.OnPlayerTargetChanged()
end

function frame:START_AUTOREPEAT_SPELL()
    addon_data.hunter.OnStartAutorepeatSpell()
end

function frame:STOP_AUTOREPEAT_SPELL()
    addon_data.hunter.OnStopAutorepeatSpell()
end

function frame:SPELL_UPDATE_COOLDOWN(spellID)
    addon_data.player.OnSpellUpdateCooldown(spellID)
end

function frame:UNIT_INVENTORY_CHANGED()
    addon_data.player.OnInventoryChange()
    addon_data.target.OnInventoryChange()

    if isHunter then
        addon_data.hunter.OnInventoryChange()
    end
end

function frame:UNIT_SPELLCAST_INTERRUPTED(unitTarget, _, spellID)
    addon_data.player.OnUnitSpellCastInterrupted(unitTarget, spellID)
    addon_data.queuing.OnUnitSpellCastInterrupted(unitTarget, spellID)

    if isHunter then
        addon_data.hunter.OnUnitSpellCastInterrupted(unitTarget, spellID)
        addon_data.castbar.OnUnitSpellCastInterrupted(unitTarget, spellID)
    end
end

function frame:UNIT_SPELLCAST_SENT(unitTarget, _, _, spellID)
    addon_data.queuing.OnUnitSpellCastSent(unitTarget, spellID)
end

function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
    addon_data.queuing.OnUnitSpellCastSucceeded(unitTarget, spellID)

    if isHunter then
        addon_data.hunter.OnUnitSpellCastSucceeded(unitTarget, spellID)
        addon_data.castbar.OnUnitSpellCastSucceeded(unitTarget, spellID)
    end
end

function frame:UNIT_SPELLCAST_FAILED(unitTarget, _, spellID)
    addon_data.player.OnUnitSpellCastFailed(unitTarget, spellID)
    addon_data.queuing.OnUnitSpellCastFailed(unitTarget, spellID)

    if isHunter then
        addon_data.castbar.OnUnitSpellCastFailed(unitTarget, spellID)
    end
end

function frame:UNIT_SPELLCAST_FAILED_QUIET(unitTarget, _, spellID)
    addon_data.player.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
    addon_data.queuing.OnUnitSpellCastFailedQuiet(unitTarget, spellID)

    if isHunter then
        addon_data.hunter.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)

-- Add a slash command to bring up the config window
SLASH_WEAPONSWINGTIMER_CONFIG1 = "/WeaponSwingTimer"
SLASH_WEAPONSWINGTIMER_CONFIG2 = "/weaponswingtimer"
SLASH_WEAPONSWINGTIMER_CONFIG3 = "/wst"
SlashCmdList["WEAPONSWINGTIMER_CONFIG"] = function(option)
    Settings.OpenToCategory("WeaponSwingTimer")
end