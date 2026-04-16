---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

--- define addon structure from the above local variable
addon_data.shaman = {}

addon_data.shaman.default_settings = {
    -- dual-wield swing sync coloring
    sync_coloring_enabled = true,
    sync_threshold = 0.5,
    sync_mh_r = 0.1, sync_mh_g = 0.8, sync_mh_b = 0.2, sync_mh_a = 1.0,
    sync_oh_r = 0.1, sync_oh_g = 0.8, sync_oh_b = 0.2, sync_oh_a = 1.0,
}

function addon_data.shaman.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_shaman_settings then
        character_shaman_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.shaman.default_settings) do
        if character_shaman_settings[setting] == nil then
            character_shaman_settings[setting] = value
        end
    end
end

function addon_data.shaman.RestoreDefaults()
    for setting, value in pairs(addon_data.shaman.default_settings) do
        character_shaman_settings[setting] = value
    end
    addon_data.shaman.UpdateVisualsOnSettingsChange()
end

--[[================================================================================]]--
--[[=================================== LOGIC ======================================]]--
--[[================================================================================]]--

--- Returns true when the next MH swing will land within [0, threshold] seconds before
--- an OH swing.  Two cases are checked:
---   A) Normal: both swings are still upcoming and MH fires first within threshold.
---   B) Post-swing: MH just fired and OH will fire within threshold seconds of it,
---      i.e. the pair (last MH, next OH) are still within the threshold window.
local function IsSwingsSynced()
    if not addon_data.player.has_offhand then return false end

    local main_timer = addon_data.player.main_swing_timer
    local off_timer  = addon_data.player.off_swing_timer
    local main_speed = addon_data.player.main_weapon_speed
    local threshold  = character_shaman_settings.sync_threshold

    -- Case A: upcoming MH fires [0, threshold] seconds before upcoming OH
    local delta = off_timer - main_timer
    if delta >= 0 and delta <= threshold then
        return true
    end

    -- Case B: MH just fired (main_timer reset to ~main_speed), and OH fires within
    -- threshold seconds after where MH was — equivalent to checking whether the
    -- elapsed time since MH fired plus the remaining OH timer is within threshold.
    -- Algebraically: off_timer - (main_timer - main_speed) in [0, threshold].
    local past_delta = off_timer - (main_timer - main_speed)
    if past_delta >= 0 and past_delta <= threshold then
        return true
    end

    return false
end

--[[================================================================================]]--
--[[=================================== VISUALS ====================================]]--
--[[================================================================================]]--

local function UpdateSwingSyncColors()
    local frame    = addon_data.player.frame
    local settings = character_player_settings
    local sh       = character_shaman_settings

    if sh.sync_coloring_enabled and IsSwingsSynced() then
        frame.main_bar:SetVertexColor(sh.sync_mh_r, sh.sync_mh_g, sh.sync_mh_b, sh.sync_mh_a)
        frame.off_bar:SetVertexColor( sh.sync_oh_r, sh.sync_oh_g, sh.sync_oh_b, sh.sync_oh_a)
    else
        frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        frame.off_bar:SetVertexColor( settings.off_r,  settings.off_g,  settings.off_b,  settings.off_a)
    end
end

function addon_data.shaman.OnUpdate(elapsed)
    UpdateSwingSyncColors()
end

function addon_data.shaman.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "SHAMAN" then return end
    UpdateSwingSyncColors()
end

function addon_data.shaman.InitializeVisuals()
    -- No extra visual elements required for shaman
end
