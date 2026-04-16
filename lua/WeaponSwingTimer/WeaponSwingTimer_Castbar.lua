---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--- define addon structure from the above local variable
addon_data.castbar = {}

addon_data.castbar.shot_spell_ids = addon_data.spells.GetSpellLines(
    L"Shoot", 
    L"Feign Death", 
    L"Trueshot Aura", 
    L"Multi-Shot", 
    L"Aimed Shot"
)

local MULTI_SHOT_IDS = addon_data.spells.GetSpellIDs(L"Multi-Shot")
local AIMED_SHOT_IDS = addon_data.spells.GetSpellIDs(L"Aimed Shot")
local STEADY_SHOT_IDS = addon_data.spells.GetSpellIDs(L"Steady Shot")
local AUTO_SHOT_ID = addon_data.spells.GetSpellIDs(L"Auto Shot")[1]
local SHOOT_ID = addon_data.spells.GetSpellIDs(L"Shoot")[1]

--- is spell multi-shot defined by spell_id
function addon_data.castbar.is_spell_multi_shot(spellID)
    return MULTI_SHOT_IDS[spellID] or false
end
--- is spell aimed shot defined by spell_id
function addon_data.castbar.is_spell_aimed_shot(spellID)
    return AIMED_SHOT_IDS[spellID] or false
end
--- is spell steady shot defined by spell_id
function addon_data.castbar.is_spell_steady_shot(spellID)
    return STEADY_SHOT_IDS[spellID] or false
end
--- is spell auto shot defined by spell_id
function addon_data.castbar.is_spell_auto_shot(spellID)
    return spellID == AUTO_SHOT_ID
end
--- is spell shoot defined by spell_id
function addon_data.castbar.is_spell_shoot(spellID)
    return spellID == SHOOT_ID
end

--- default settings to be loaded on initial load and reset to default
addon_data.castbar.default_settings = {
    enabled = true,
    width = 300,
    height = 12,
    fontsize = 12,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = 0,
    in_combat_alpha = 1.0,
    --ooc_alpha = 0.5,
    backplane_alpha = 0.5,
    show_cast_text = true,
    show_aimedshot_cast_bar = true,
    show_multishot_cast_bar = true,
    show_latency_bars = false,
    show_border = false
}
--- Initializing variables for calculations and function calls

addon_data.castbar.casting = false
addon_data.castbar.casting_shot = false
addon_data.castbar.casting_spell_id = 0
addon_data.castbar.cast_timer = 0.1
addon_data.castbar.cast_time = 0.1
addon_data.castbar.last_failed_time = GetTime()
addon_data.castbar.cast_start_time = GetTime()
addon_data.castbar.hitcount = 0
addon_data.castbar.initial_pushback_time = 0
addon_data.castbar.initial_cast_time = 0
addon_data.castbar.total_pushback = 0

function addon_data.castbar.CastPushback()
    if addon_data.castbar.casting_shot then
            -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        addon_data.castbar.pushbackValue = addon_data.castbar.pushbackValue or 1

        if ((GetTime() - addon_data.castbar.cast_start_time) < 1) and (addon_data.castbar.hitcount < 1) then
            addon_data.castbar.initial_pushback_time = GetTime() - addon_data.castbar.cast_start_time
        end

        if addon_data.castbar.initial_pushback_time > 0 then
            addon_data.castbar.cast_time = addon_data.castbar.cast_time + addon_data.castbar.initial_pushback_time
            addon_data.castbar.initial_pushback_time = 0
            addon_data.castbar.pushbackValue = 1
        else
            addon_data.castbar.cast_time = addon_data.castbar.cast_time + addon_data.castbar.pushbackValue
        end

        addon_data.castbar.hitcount = addon_data.castbar.hitcount + 1
        addon_data.castbar.pushbackValue = max(addon_data.castbar.pushbackValue - 0.2, 0.2)
    end
end

-- Selection of starting a timer for casting multi and handling of stopping auto timer from starting
function addon_data.castbar.StartCastingSpell(spellID)
    local settings = character_castbar_settings
    if (GetTime() - addon_data.castbar.last_failed_time) > 0 then
        if not addon_data.castbar.casting and UnitCanAttack("player", "target") then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            local name = spellInfo.castTime
            local castTime = spellInfo.castTime
            if castTime > 0 and
                not addon_data.hunter.is_spell_auto_shot(spellID) and
                not addon_data.hunter.is_spell_shoot(spellID) then
                addon_data.hunter.casting = true
            end

            if (not addon_data.castbar.casting_shot) and (addon_data.castbar.is_spell_multi_shot(spellID) and settings.show_multishot_cast_bar) or (addon_data.castbar.is_spell_aimed_shot(spellID) and settings.show_aimedshot_cast_bar) then
                addon_data.castbar.cast_start_time = GetTime()
                addon_data.castbar.casting_shot = true
                addon_data.castbar.casting_spell_id = spellID
                addon_data.castbar.pushbackValue = 1
                addon_data.castbar.initial_pushback_time = 0
                addon_data.castbar.hitcount = 0
                addon_data.castbar.initial_cast_time = castTime
                addon_data.castbar.cast_timer = 0
                addon_data.castbar.frame.spell_bar:SetVertexColor(0.7, 0.4, 0, 1)

                if settings.show_latency_bars then
                    local _, _, _, latency = GetNetStats()
                    addon_data.castbar.cast_time = addon_data.castbar.cast_time + (latency / 1000)
                end
                if settings.show_cast_text then
                    addon_data.castbar.frame.spell_text_center:SetText(name)
                end
            end
        end
    end
end

function addon_data.castbar.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_castbar_settings then
        character_castbar_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.castbar.default_settings) do
        if character_castbar_settings[setting] == nil then
            character_castbar_settings[setting] = value
        end
    end
    -- only load castbar if hunter class, since it's only used for multi and aimed shot
    if character_castbar_settings.enabled == nil then
        local _, class = UnitClass("player")
        character_castbar_settings.enabled = class == "HUNTER"
    end
    -- One-time tooltip creation
    if not addon_data.castbar.scan_tip then
        addon_data.castbar.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
        addon_data.castbar.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
end

function addon_data.castbar.RestoreDefaults()
    for setting, value in pairs(addon_data.castbar.default_settings) do
        character_castbar_settings[setting] = value
    end
    _, class, _ = UnitClass("player")
    character_castbar_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateConfigPanelValues()
end

--- Buffs and debuffs change casting speeds, which is multiplied by the cast time
--- -----------------------------------------------------------------------------
--- Anything that changes cast times should go here. Need to add other forms of debuffs
--- berserk haste is a simple calculation to derive the percent of berserking haste provided to the player from their health percent

function addon_data.castbar.UpdateCastTimer(elapsed)
    local base_cast_time = addon_data.castbar.shot_spell_ids[addon_data.castbar.casting_spell_id].castTime

    if (addon_data.castbar.cast_timer < 0.25) then
        addon_data.castbar.cast_time = base_cast_time * addon_data.hunter.range_cast_speed_modifer
    end

    addon_data.castbar.cast_timer = GetTime() - addon_data.castbar.cast_start_time
    if addon_data.castbar.cast_timer > addon_data.castbar.cast_time + 0.5 then
        addon_data.castbar.OnUnitSpellCastFailed("player", 1)
    end

    addon_data.castbar.total_pushback = addon_data.castbar.cast_time - addon_data.castbar.initial_cast_time
end

function addon_data.castbar.OnUpdate(elapsed)
    local _, class, _ = UnitClass("player")
    if character_castbar_settings.enabled and (class == "HUNTER") then
        -- Update the cast bar timers
        if addon_data.castbar.casting_shot then
            addon_data.castbar.UpdateCastTimer(elapsed)
        end
        -- Update the visuals
        addon_data.castbar.UpdateVisualsOnUpdate()
    end
end

-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
function addon_data.castbar.OnCombatLogUnfiltered(...)
    local sourceGUID = select(4, ...)
    local subevent = select(2, ...)
    if sourceGUID == UnitGUID("player") then
        if subevent == "SPELL_CAST_START" then
            local spellID = select(12, ...)
            addon_data.hunter.FeignStatus = false
            if addon_data.castbar.is_spell_multi_shot(spellID) or addon_data.castbar.is_spell_aimed_shot(spellID) then
                addon_data.castbar.StartCastingSpell(spellID)
            end
        end
    else
        if subevent == "SWING_DAMAGE" or subevent == "ENVIRONMENTAL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE" then
            local targetGUID = select(8, ...)
            if targetGUID == UnitGUID("player") then
                addon_data.castbar.CastPushback()
            end
        end
    end
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
function addon_data.castbar.OnUnitSpellCastSucceeded(unit, spell_id)
    local settings = character_castbar_settings

    if unit == "player" then
        addon_data.castbar.casting = false

        if addon_data.castbar.shot_spell_ids[spell_id] then
            addon_data.castbar.casting_spell_id = 0
            addon_data.castbar.casting_shot = false
            -- only show green bar overlay if setting is enabled
            local spell_aimed_enabled = (addon_data.castbar.is_spell_aimed_shot(spell_id) and settings.show_aimedshot_cast_bar)
            local spell_multi_enabled = (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar)
            if (spell_aimed_enabled or spell_multi_enabled) then
                addon_data.castbar.frame.spell_bar:SetVertexColor(0, 0.5, 0, 1)
                addon_data.castbar.frame.spell_bar:SetWidth(character_castbar_settings.width)
                addon_data.castbar.frame.spell_bar_text:SetText("0.0")
            end
        end
    end
end

function addon_data.castbar.OnUnitSpellCastFailed(unit, spell_id)
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame
    -- only care about if multi fails to cast, so ignore others
    if unit == "player" and (addon_data.castbar.is_spell_multi_shot(spell_id) or addon_data.castbar.is_spell_aimed_shot(spell_id)) then

        addon_data.castbar.last_failed_time = GetTime()
        addon_data.castbar.casting = false
        addon_data.castbar.pushbackValue = 1
        addon_data.castbar.initial_pushback_time = 0
        addon_data.castbar.hitcount = 0

        local spell_aimed_enabled = (addon_data.castbar.is_spell_aimed_shot(spell_id) and settings.show_aimedshot_cast_bar)
        local spell_multi_enabled = (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar)
        if (addon_data.castbar.casting_spell_id > 0) and (spell_aimed_enabled or spell_multi_enabled) then
            addon_data.castbar.casting_shot = false
            addon_data.castbar.casting_spell_id = 0
            if spell_aimed_enabled or spell_multi_enabled then
                addon_data.castbar.frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
                if character_castbar_settings.show_text then
                    frame.spell_text_center:SetText(L"Failed")
                end
                frame.spell_bar:SetWidth(settings.width)
            end
        end
    end
end

function addon_data.castbar.OnUnitSpellCastInterrupted(unit, spell_id)
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame
    if unit == "player" and (addon_data.castbar.is_spell_multi_shot(spell_id) or addon_data.castbar.is_spell_aimed_shot(spell_id)) then
        addon_data.castbar.casting = false
        addon_data.castbar.pushbackValue = 1
        addon_data.castbar.initial_pushback_time = 0
        addon_data.castbar.hitcount = 0

        local spell_aimed_enabled = (addon_data.castbar.is_spell_aimed_shot(spell_id) and settings.show_aimedshot_cast_bar)
        local spell_multi_enabled = (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar)
        if (addon_data.castbar.casting_spell_id > 0) and (spell_aimed_enabled or spell_multi_enabled) then
            addon_data.castbar.casting_shot = false
            addon_data.castbar.casting_spell_id = 0

            if spell_aimed_enabled or spell_multi_enabled then
                frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
                if settings.show_text then
                    frame.spell_text_center:SetText(L"Interrupted")
                end
                frame.spell_bar:SetWidth(settings.width)
            end
        end
    end
end

--- Updating and initializing visuals
--- ---------------------------------
function addon_data.castbar.UpdateVisualsOnUpdate()
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame

    if addon_data.core.in_combat or addon_data.castbar.casting_shot then
        if addon_data.castbar.casting_shot then

            local time_left = math.max(addon_data.utils.SimpleRound(addon_data.castbar.cast_time - addon_data.castbar.cast_timer, 0.1), 0)
            frame.spell_bar_text:SetText(string.format("%.1f", time_left))
            frame:SetAlpha(1)
            frame.spell_bar:SetVertexColor(0.8, 0.64, 0, 1)
            new_width = settings.width * (addon_data.castbar.cast_timer / addon_data.castbar.cast_time)
            new_width = math.min(new_width, settings.width)
            frame.spell_bar:SetWidth(new_width)
            frame.spell_spark:SetPoint("TOPLEFT", new_width - 8, 0)
            if new_width == settings.width or not settings.classic_bars then
                frame.spell_spark:Hide()
            else
                frame.spell_spark:Show()
            end
        else
            new_alpha = frame:GetAlpha() - 0.005

            if new_alpha <= 0 then
                new_alpha = 0
                frame:SetSize(settings.width, settings.height)
                frame.spell_text_center:SetText("")
                frame.spell_bar_text:SetText("")
            end
            frame:SetAlpha(new_alpha)
            frame.spell_spark:Hide()
        end
        if settings.show_latency_bars then
                if addon_data.castbar.casting_shot then
                frame.cast_latency:Show()
                _, _, _, latency = GetNetStats()
                lag_width = settings.width * ((latency / 1000) / addon_data.castbar.cast_time)
                frame.cast_latency:SetWidth(lag_width)
            else
                frame.cast_latency:Hide()
        end
    end
    else
        frame.spell_bar:SetVertexColor(0.2, 0.2, 0.2, 1)
        frame:SetSize(settings.width, settings.height)
        if not (settings.is_locked) then
            frame.spell_text_center:SetText(L"Spell Bar Unlocked")
            frame:SetAlpha(1)
        else
            frame:SetAlpha(0)
        end
    end
end

function addon_data.castbar.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "HUNTER" then return end

    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame
    local _, class, _ = UnitClass("player")
    if (settings.show_multishot_cast_bar or settings.show_aimedshot_cast_bar) and (class == "HUNTER") then
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        if settings.show_border then
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border", 
                tile = true, tileSize = 16, edgeSize = 12, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        else
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = nil, 
                tile = true, tileSize = 16, edgeSize = 16, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        end
        frame:SetAlpha(1)
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)

        frame.spell_bar_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.spell_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
        frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.spell_bar:SetPoint("TOPLEFT", 0, 0)
        frame.spell_bar:SetHeight(settings.height)

        frame.spell_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        frame.spell_spark:SetSize(16, settings.height)
        frame.spell_text_center:SetPoint("TOP", 2, -(settings.height / 2) + (settings.fontsize / 2))
        frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.cast_latency:SetHeight(settings.height)
        frame.cast_latency:SetPoint("TOPLEFT", 0, 0)
        frame.cast_latency:SetColorTexture(1, 0, 0, 0.75)
        if settings.show_latency_bars then
            frame.cast_latency:Show()
        else
            frame.cast_latency:Hide()
        end

        if settings.show_cast_text then
            frame.spell_text_center:Show()
            frame.spell_bar_text:Show()
        else
            frame.spell_text_center:Hide()
            frame.spell_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

function addon_data.castbar.OnFrameDragStart()
    if not character_castbar_settings.is_locked then
        addon_data.castbar.frame:StartMoving()
    end
end

function addon_data.castbar.OnFrameDragStop()
    local frame = addon_data.castbar.frame
    local settings = character_castbar_settings
    frame:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateConfigPanelValues()
end

function addon_data.castbar.InitializeVisuals()
    local settings = character_castbar_settings
    -- Create the frame
    addon_data.castbar.frame = CreateFrame("Frame", addon_name .. "HunterCastbarFrame", UIParent)
    local frame = addon_data.castbar.frame

    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.castbar.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.castbar.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")
    -- Create the range spell shot bar
    frame.spell_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the spell bar text
    frame.spell_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_bar_text:SetJustifyV("MIDDLE")
    frame.spell_bar_text:SetJustifyH("CENTER")
    -- Create the spell spark
    frame.spell_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.spell_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the range spell shot bar center text
    frame.spell_text_center = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_text_center:SetTextColor(1, 1, 1, 1)
    frame.spell_text_center:SetJustifyV("MIDDLE")
    frame.spell_text_center:SetJustifyH("LEFT")
    -- Create the latency bar
    frame.cast_latency = frame:CreateTexture(nil,"OVERLAY")
    -- Show it off
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateVisualsOnUpdate()
    frame:Show()
end

--- Everything below is designated as part of the UI settings menu. Checkboxes, adjustments, sliders
--- ------------------------------------------------------------------------------------------------
--- Adjusts the values of everything based on the settings selected with UpdateConfigPanelValues
--- 10 boxes that can be checked, all exact same just with different names
--- Bar height, width, and offset values set with numerical value
--- Color picker selection for 3 visual displays of the bars
--- Alpha adjustments for 3 visual displays of the bars
function addon_data.castbar.UpdateConfigPanelValues()
    local panel = addon_data.castbar.config_frame
    local settings = character_castbar_settings
    panel.show_aimedshot_cast_bar_checkbox:SetChecked(settings.show_aimedshot_cast_bar)
    panel.show_multishot_cast_bar_checkbox:SetChecked(settings.show_multishot_cast_bar)
    panel.show_latency_bar_checkbox:SetChecked(settings.show_latency_bars)
    panel.show_casttext_checkbox:SetChecked(settings.show_cast_text)
    panel.width_editbox:SetText(tostring(settings.width))
    panel.width_editbox:SetCursorPosition(0)
    panel.height_editbox:SetText(tostring(settings.height))
    panel.height_editbox:SetCursorPosition(0)
    panel.fontsize_editbox:SetText(tostring(settings.fontsize))
    panel.fontsize_editbox:SetCursorPosition(0)
    panel.x_offset_editbox:SetText(tostring(settings.x_offset))
    panel.x_offset_editbox:SetCursorPosition(0)
    panel.y_offset_editbox:SetText(tostring(settings.y_offset))
    panel.y_offset_editbox:SetCursorPosition(0)

    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    -- panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    -- panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

function addon_data.castbar.ShowAimedShotCastBarCheckBoxOnClick(self)
    character_castbar_settings.show_aimedshot_cast_bar = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.ShowMultiShotCastBarCheckBoxOnClick(self)
    character_castbar_settings.show_multishot_cast_bar = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.ShowLatencyBarsCheckBoxOnClick(self)
    character_castbar_settings.show_latency_bars = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.ShowCastTextCheckBoxOnClick(self)
    character_castbar_settings.show_cast_text = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.WidthEditBoxOnEnter(self)
    character_castbar_settings.width = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.HeightEditBoxOnEnter(self)
    character_castbar_settings.height = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.FontSizeEditBoxOnEnter(self)
    character_castbar_settings.fontsize = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.XOffsetEditBoxOnEnter(self)
    character_castbar_settings.x_offset = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.YOffsetEditBoxOnEnter(self)
    character_castbar_settings.y_offset = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

function addon_data.castbar.CombatAlphaOnValChange(self)
    character_castbar_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

-- function addon_data.castbar.OOCAlphaOnValChange(self)
    -- character_castbar_settings.ooc_alpha = tonumber(self:GetValue())
    -- addon_data.castbar.UpdateVisualsOnSettingsChange()
-- end

function addon_data.castbar.BackplaneAlphaOnValChange(self)
    character_castbar_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end
--- Initializes the main setting panel including layout, alignment, and design
function addon_data.castbar.CreateConfigPanel(parent_panel)
    addon_data.castbar.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = addon_data.castbar.config_frame

    -- Show Text Checkbox
    panel.show_casttext_checkbox = addon_data.config.CheckBoxFactory(
        "CastBarShowCastTextCheckBox",
        panel,
        L"Show Cast Text",
        L"Enables the cast bar text.",
        addon_data.castbar.ShowCastTextCheckBoxOnClick)
    panel.show_casttext_checkbox:SetPoint("TOPLEFT", 10, -85)
    -- Width EditBox
    panel.width_editbox = addon_data.config.EditBoxFactory(
        "CastBarWidthEditBox",
        panel,
        L"Bar Width",
        75,
        25,
        addon_data.castbar.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -90)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "CastBarHeightEditBox",
        panel,
        L"Bar Height",
        75,
        25,
        addon_data.castbar.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 320, -90)
    -- Font Size EditBox
    panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        addon_data.castbar.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "CastBarXOffsetEditBox",
        panel,
        L"X Offset",
        75,
        25,
        addon_data.castbar.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -140)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "CastBarYOffsetEditBox",
        panel,
        L"Y Offset",
        75,
        25,
        addon_data.castbar.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -140)
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "CastBarInCombatAlphaSlider",
        panel,
        L"In Combat Alpha",
        0,
        1,
        0.05,
        addon_data.castbar.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -90)
    -- -- Out Of Combat Alpha Slider
    -- panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        -- "CastBarOOCAlphaSlider",
        -- panel,
        -- L"Out of Combat Alpha",
        -- 0,
        -- 1,
        -- 0.05,
        -- addon_data.castbar.OOCAlphaOnValChange)
    -- panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "CastBarBackplaneAlphaSlider",
        panel,
        L"Backplane Alpha",
        0,
        1,
        0.05,
        addon_data.castbar.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -190)
    -- Show Aimed Shot Cast Bar Checkbox
    panel.show_aimedshot_cast_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowAimedShotCastBarCheckBox",
        panel,
        L"Aimed Shot cast bar",
        L"Allows the cast bar to show Aimed Shot casts.",
        addon_data.castbar.ShowAimedShotCastBarCheckBoxOnClick)
    panel.show_aimedshot_cast_bar_checkbox:SetPoint("TOPLEFT", 10, -110)
    -- Show Multi Shot Cast Bar Checkbox
    panel.show_multishot_cast_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowMultiShotCastBarCheckBox",
        panel,
        L"Multi-Shot cast bar",
        L"Allows the cast bar to show Multi-Shot casts.",
        addon_data.castbar.ShowMultiShotCastBarCheckBoxOnClick)
    panel.show_multishot_cast_bar_checkbox:SetPoint("TOPLEFT", 10, -45)
    -- Show Latency Bar Checkbox
    panel.show_latency_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowLatencyBarCheckBox",
        panel,
        L"Latency bar",
        L"Shows a bar that represents latency on cast bar.",
        addon_data.castbar.ShowLatencyBarsCheckBoxOnClick)
    panel.show_latency_bar_checkbox:SetPoint("TOPLEFT", 10, -65)

    -- Return the final panel
    addon_data.castbar.UpdateConfigPanelValues()
    return panel
end