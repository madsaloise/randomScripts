---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--- expose global variable for other addons to check queued state
---@type SpellID?
WST_Queued = nil

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

--- define addon structure from the above local variable
addon_data.queuing = {}

---@type table<SpellID, true>
addon_data.queuing.queuedSpellIDs = addon_data.spells.GetSpellIDs(
    L"Heroic Strike",
    L"Cleave",
    L"Maul"
)

---@type table<SpellID, SpellPalette>
addon_data.queuing.spellPalettes = {}

--[[====================================================================================]]--
--[[================================== VISUAL UPDATES ==================================]]--
--[[====================================================================================]]--

local function ColorQueuedBars()
    if not WST_Queued then return end

    local spellPalette = addon_data.queuing.spellPalettes[WST_Queued]
    if not spellPalette then return end

    local frame = addon_data.player.frame

    if spellPalette.MainHand then
        local bar = spellPalette.MainHand.bar
        local text = spellPalette.MainHand.text

        frame.main_bar:SetVertexColor(bar.r, bar.g, bar.b, bar.a)
        frame.main_left_text:SetTextColor(text.r, text.g, text.b, text.a)
        frame.main_right_text:SetTextColor(text.r, text.g, text.b, text.a)
    end

    if spellPalette.OffHand then
        local bar = spellPalette.OffHand.bar
        local text = spellPalette.OffHand.text

        frame.off_bar:SetVertexColor(bar.r, bar.g, bar.b, bar.a)
        frame.off_left_text:SetTextColor(text.r, text.g, text.b, text.a)
        frame.off_right_text:SetTextColor(text.r, text.g, text.b, text.a)
    end
end

local function UncolorQueuedBars()
    local settings = character_player_settings

    local frame = addon_data.player.frame

    frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
    frame.main_left_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
    frame.main_right_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)

    frame.off_bar:SetVertexColor(settings.off_r, settings.off_g, settings.off_b, settings.off_a)
    frame.off_left_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
    frame.off_right_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
end

---@param spellName string
---@param spellPalette SpellPalette
function addon_data.queuing.RegisterSpell(spellName, spellPalette)
    for spellID, _ in pairs(addon_data.spells.GetSpellIDs(spellName)) do
        addon_data.queuing.spellPalettes[spellID] = spellPalette
        if spellID == WST_Queued then
            UncolorQueuedBars()
        end
    end
    ColorQueuedBars()
end

---@param spellName string
function addon_data.queuing.UnregisterSpell(spellName)
    for spellID, _ in pairs(addon_data.spells.GetSpellIDs(spellName)) do
        addon_data.queuing.spellPalettes[spellID] = nil
        if spellID == WST_Queued then
            UncolorQueuedBars()
        end
    end
end

function addon_data.queuing.UnregisterAllSpells()
    addon_data.queuing.spellPalettes = {}
    UncolorQueuedBars()
end

--[[=====================================================================================]]--
--[[================================== EVENT HANDLING ===================================]]--
--[[=====================================================================================]]--

---@param unit UnitToken
---@param spellID SpellID
local function CheckQueueEvent(unit, spellID)
    if unit ~= "player" then return end

    if addon_data.queuing.queuedSpellIDs[spellID] then
        WST_Queued = spellID
        ColorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
local function CheckDequeueEvent(unit, spellID)
    if unit ~= "player" then return end

    if spellID == WST_Queued then
        WST_Queued = nil
        UncolorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
local function cbFunc(unit, spellID)
    if C_Spell.IsCurrentSpell(spellID) then
        CheckQueueEvent(unit, spellID)
    else
        CheckDequeueEvent(unit, spellID)
    end
end

local ticker

---@param unit UnitToken
---@param spellID SpellID
local function PeriodicCheck(unit, spellID)
    if ticker then
        ticker:Cancel()
    end

    ticker = C_Timer.NewTicker(0.025, function() cbFunc(unit, spellID) end, 16)
end

function addon_data.queuing.OnCombatLogUnfiltered(...)
    local sourceGUID = select(4, ...)
    if sourceGUID ~= addon_data.player.guid then return end

    local subevent = select(2, ...)

    local isOffHand
    if subevent == "SWING_DAMAGE" then
        isOffHand = select(21, ...)
    elseif subevent == "SWING_MISSED" then
        isOffHand = select(13, ...)
    else
        return -- only handle white hits
    end

    if not isOffHand then
        WST_Queued = nil
        UncolorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
function addon_data.queuing.OnUnitSpellCastInterrupted(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

function addon_data.queuing.OnPlayerTargetChanged()
    WST_Queued = nil
    UncolorQueuedBars()
end

---@param unit UnitToken
---@param spellID SpellID
function addon_data.queuing.OnUnitSpellCastSent(unit, spellID)
    CheckQueueEvent(unit, spellID)
end

---@param unit UnitToken
---@param spellID SpellID
function addon_data.queuing.OnUnitSpellCastSucceeded(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

---@param unit UnitToken
---@param spellID SpellID
function addon_data.queuing.OnUnitSpellCastFailed(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

-- This function exists to handle edge cases of heroic strike/cleave toggling.
---@param unit UnitToken
---@param spellID SpellID
function addon_data.queuing.OnUnitSpellCastFailedQuiet(unit, spellID)
    if unit ~= "player" then return end

    if addon_data.queuing.queuedSpellIDs[spellID] then
        PeriodicCheck(unit, spellID)
    end
end