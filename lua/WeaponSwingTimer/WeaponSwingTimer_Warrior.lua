---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

--- define addon structure from the above local variable
addon_data.warrior = {}

addon_data.warrior.default_settings = {
    -- bar coloring
    coloring_enabled = true,
    color_mh = true,
    color_oh = true,
    cleave = true,
    queued_mh_r = 0.9, queued_mh_g = 0.6, queued_mh_b = 0.1, queued_mh_a = 1.0,
    queued_mh_text_r = 1.0, queued_mh_text_g = 1.0, queued_mh_text_b = 1.0, queued_mh_text_a = 1.0,
    queued_oh_r = 0.9, queued_oh_g = 0.6, queued_oh_b = 0.1, queued_oh_a = 1.0,
    queued_oh_text_r = 1.0, queued_oh_text_g = 1.0, queued_oh_text_b = 1.0, queued_oh_text_a = 1.0,
    cleave_mh_r = 0.1, cleave_mh_g = 0.8, cleave_mh_b = 0.2, cleave_mh_a = 1.0,
    cleave_mh_text_r = 1.0, cleave_mh_text_g = 1.0, cleave_mh_text_b = 1.0, cleave_mh_text_a = 1.0,
    cleave_oh_r = 0.1, cleave_oh_g = 0.8, cleave_oh_b = 0.2, cleave_oh_a = 1.0,
    cleave_oh_text_r = 1.0, cleave_oh_text_g = 1.0, cleave_oh_text_b = 1.0, cleave_oh_text_a = 1.0,
    -- slam delay bar
    slam_delay_enabled = true,
    slam_delay_bar = true,
    slam_delay = 0.100,
    slam_delay_r = 0.9, slam_delay_g = 0.1, slam_delay_b = 0, slam_delay_a = 1.0,
    slam_delay_one_handing = false,
    slam_gcd_spark = true,
}

function addon_data.warrior.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_warrior_settings then
        character_warrior_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.warrior.default_settings) do
        if character_warrior_settings[setting] == nil then
            character_warrior_settings[setting] = value
        end
    end
end

function addon_data.warrior.RestoreDefaults()
    for setting, value in pairs(addon_data.warrior.default_settings) do
        character_warrior_settings[setting] = value
    end
    addon_data.warrior.UpdateVisualsOnSettingsChange()
    addon_data.warrior.UpdateConfigPanelValues()
end

--[[=====================================================================================]]--
--[[================================== EVENT HANDLING ===================================]]--
--[[=====================================================================================]]--

function addon_data.warrior.OnUpdate(elapsed)
    addon_data.warrior.UpdateVisualsOnUpdate()
end

--[[================================================================================]]--
--[[=================================== VISUALS ====================================]]--
--[[================================================================================]]--

local function UpdateColorPalettes()
    local settings = character_warrior_settings

    if not settings.coloring_enabled then
        addon_data.queuing.UnregisterAllSpells()
    else
        local heroicStrikePalette = {
            MainHand = settings.color_mh and {
                bar = {
                    r = settings.queued_mh_r,
                    g = settings.queued_mh_g,
                    b = settings.queued_mh_b,
                    a = settings.queued_mh_a,
                },
                text = {
                    r = settings.queued_mh_text_r,
                    g = settings.queued_mh_text_g,
                    b = settings.queued_mh_text_b,
                    a = settings.queued_mh_text_a,
                }
            } or nil,
            OffHand = settings.color_oh and {
                bar = {
                    r = settings.queued_oh_r,
                    g = settings.queued_oh_g,
                    b = settings.queued_oh_b,
                    a = settings.queued_oh_a,
                },
                text = {
                    r = settings.queued_oh_text_r,
                    g = settings.queued_oh_text_g,
                    b = settings.queued_oh_text_b,
                    a = settings.queued_oh_text_a,
                }
            } or nil
        }
        local cleavePalette
        if settings.cleave then
            cleavePalette = {
                MainHand = settings.color_mh and {
                    bar = {
                        r = settings.cleave_mh_r,
                        g = settings.cleave_mh_g,
                        b = settings.cleave_mh_b,
                        a = settings.cleave_mh_a,
                    },
                    text = {
                        r = settings.cleave_mh_text_r,
                        g = settings.cleave_mh_text_g,
                        b = settings.cleave_mh_text_b,
                        a = settings.cleave_mh_text_a,
                    }
                } or nil,
                OffHand = settings.color_oh and {
                    bar = {
                        r = settings.cleave_oh_r,
                        g = settings.cleave_oh_g,
                        b = settings.cleave_oh_b,
                        a = settings.cleave_oh_a,
                    },
                    text = {
                        r = settings.cleave_oh_text_r,
                        g = settings.cleave_oh_text_g,
                        b = settings.cleave_oh_text_b,
                        a = settings.cleave_oh_text_a,
                    }
                } or nil
            }
        else
            cleavePalette = heroicStrikePalette
        end
        addon_data.queuing.RegisterSpell(L"Heroic Strike", heroicStrikePalette)
        addon_data.queuing.RegisterSpell(L"Cleave", cleavePalette)
    end
end

local function UpdateSlamIndicators()
    local settings = character_warrior_settings

    local frame = addon_data.player.frame
    local frameWidth = frame:GetWidth()
    frame.slam_delay_bar:SetWidth(frameWidth * settings.slam_delay / addon_data.player.main_weapon_speed)
    frame.slam_delay_bar:SetVertexColor(settings.slam_delay_r, settings.slam_delay_g, settings.slam_delay_b, settings.slam_delay_a)
    frame.slam_gcd_spark:SetPoint("RIGHT", frameWidth * -1.5 / addon_data.player.main_weapon_speed + 8, 0)
    frame.slam_gcd_spark:SetVertexColor(settings.slam_delay_r, settings.slam_delay_g, settings.slam_delay_b, settings.slam_delay_a)
    if addon_data.player.has_twohand or settings.slam_delay_one_handing then
        if settings.slam_delay_enabled and settings.slam_delay > 0 then
            frame.slam_delay_bar:Show()
        else
            frame.slam_delay_bar:Hide()
        end
        if settings.slam_gcd_spark then
            frame.slam_gcd_spark:Show()
        else
            frame.slam_gcd_spark:Hide()
        end
    else
        frame.slam_delay_bar:Hide()
        frame.slam_gcd_spark:Hide()
    end
end

function addon_data.warrior.UpdateVisualsOnUpdate()
    UpdateSlamIndicators()
end

function addon_data.warrior.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "WARRIOR" then return end

    local settings = character_player_settings
    local frame = addon_data.player.frame
    if settings.classic_bars then
        frame.slam_delay_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
    else
        frame.slam_delay_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
    end
    UpdateColorPalettes()
    UpdateSlamIndicators()
end

function addon_data.warrior.InitializeVisuals()
    local frame = addon_data.player.frame
    frame.slam_delay_bar = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.slam_delay_bar:SetPoint("TOPRIGHT")
    frame.slam_delay_bar:SetPoint("BOTTOMRIGHT")

    frame.slam_gcd_spark = frame:CreateTexture(nil, "OVERLAY")
    frame.slam_gcd_spark:SetPoint("TOP")
    frame.slam_gcd_spark:SetPoint("BOTTOM")
    frame.slam_gcd_spark:SetWidth(16)
    frame.slam_gcd_spark:SetTexture("Interface/AddOns/WeaponSwingTimer/Images/Spark")

    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local function displayCleave(enabled)
    local panel = addon_data.warrior.config_frame

    if enabled then
        panel.cleave_mh_color_picker:Show()
        panel.cleave_mh_text_color_picker:Show()
        panel.cleave_oh_color_picker:Show()
        panel.cleave_oh_text_color_picker:Show()

        panel.queued_mh_color_picker.text:SetText(L"Heroic Strike Main-Hand Bar Color")
        panel.queued_mh_text_color_picker.text:SetText(L"Heroic Strike Main-Hand Bar Text Color")
        panel.queued_oh_color_picker.text:SetText(L"Heroic Strike Off-Hand Bar Color")
        panel.queued_oh_text_color_picker.text:SetText(L"Heroic Strike Off-Hand Bar Text Color")
    else
        panel.cleave_mh_color_picker:Hide()
        panel.cleave_mh_text_color_picker:Hide()
        panel.cleave_oh_color_picker:Hide()
        panel.cleave_oh_text_color_picker:Hide()

        panel.queued_mh_color_picker.text:SetText(L"Queued Main-Hand Bar Color")
        panel.queued_mh_text_color_picker.text:SetText(L"Queued Main-Hand Bar Text Color")
        panel.queued_oh_color_picker.text:SetText(L"Queued Off-Hand Bar Color")
        panel.queued_oh_text_color_picker.text:SetText(L"Queued Off-Hand Bar Text Color")
    end
end

function addon_data.warrior.UpdateConfigPanelValues()
    local panel = addon_data.warrior.config_frame
    local settings = character_warrior_settings

    panel.enabled_checkbox:SetChecked(settings.coloring_enabled)
    panel.color_mh_checkbox:SetChecked(settings.color_mh)
    panel.color_oh_checkbox:SetChecked(settings.color_oh)
    panel.cleave_checkbox:SetChecked(settings.cleave)

    panel.queued_mh_color_picker.foreground:SetColorTexture(
        settings.queued_mh_r, settings.queued_mh_g, settings.queued_mh_b, settings.queued_mh_a)
    panel.queued_mh_text_color_picker.foreground:SetColorTexture(
        settings.queued_mh_text_r, settings.queued_mh_text_g, settings.queued_mh_text_b, settings.queued_mh_text_a)
    panel.queued_oh_color_picker.foreground:SetColorTexture(
        settings.queued_oh_r, settings.queued_oh_g, settings.queued_oh_b, settings.queued_oh_a)
    panel.queued_oh_text_color_picker.foreground:SetColorTexture(
        settings.queued_oh_text_r, settings.queued_oh_text_g, settings.queued_oh_text_b, settings.queued_oh_text_a)

    panel.cleave_mh_color_picker.foreground:SetColorTexture(
        settings.cleave_mh_r, settings.cleave_mh_g, settings.cleave_mh_b, settings.cleave_mh_a)
    panel.cleave_mh_text_color_picker.foreground:SetColorTexture(
        settings.cleave_mh_text_r, settings.cleave_mh_text_g, settings.cleave_mh_text_b, settings.cleave_mh_text_a)
    panel.cleave_oh_color_picker.foreground:SetColorTexture(
        settings.cleave_oh_r, settings.cleave_oh_g, settings.cleave_oh_b, settings.cleave_oh_a)
    panel.cleave_oh_text_color_picker.foreground:SetColorTexture(
        settings.cleave_oh_text_r, settings.cleave_oh_text_g, settings.cleave_oh_text_b, settings.cleave_oh_text_a)

    displayCleave(settings.cleave)

    panel.enable_slam_delay:SetChecked(settings.slam_delay_enabled)
    panel.enable_slam_delay_one_handing:SetChecked(settings.slam_delay_one_handing)
    panel.enable_slam_gcd_spark:SetChecked(settings.slam_gcd_spark)
    panel.slam_delay_color_picker.foreground:SetColorTexture(
        settings.slam_delay_r, settings.slam_delay_g, settings.slam_delay_b, settings.slam_delay_a)
    panel.slam_delay_slider:SetValue(settings.slam_delay)
    panel.slam_delay_slider.editbox:SetCursorPosition(0)
end

function addon_data.warrior.EnabledCheckBoxOnClick(self)
    character_warrior_settings.coloring_enabled = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.ColorMainHandCheckBoxOnClick(self)
    character_warrior_settings.color_mh = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.ColorOffHandCheckBoxOnClick(self)
    character_warrior_settings.color_oh = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.CleaveCheckBoxOnClick(self)
    local checked = self:GetChecked()
    character_warrior_settings.cleave = checked
    displayCleave(checked)
end

function addon_data.warrior.QueuedMainHandColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "queued_mh_r"
    local g = "queued_mh_g"
    local b = "queued_mh_b"
    local a = "queued_mh_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.QueuedMainHandTextColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "queued_mh_text_r"
    local g = "queued_mh_text_g"
    local b = "queued_mh_text_b"
    local a = "queued_mh_text_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.QueuedOffHandColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "queued_oh_r"
    local g = "queued_oh_g"
    local b = "queued_oh_b"
    local a = "queued_oh_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.QueuedOffHandTextColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "queued_oh_text_r"
    local g = "queued_oh_text_g"
    local b = "queued_oh_text_b"
    local a = "queued_oh_text_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.CleaveMainHandColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "cleave_mh_r"
    local g = "cleave_mh_g"
    local b = "cleave_mh_b"
    local a = "cleave_mh_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.CleaveMainHandTextColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "cleave_mh_text_r"
    local g = "cleave_mh_text_g"
    local b = "cleave_mh_text_b"
    local a = "cleave_mh_text_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.CleaveOffHandColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "cleave_oh_r"
    local g = "cleave_oh_g"
    local b = "cleave_oh_b"
    local a = "cleave_oh_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.CleaveOffHandTextColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "cleave_oh_text_r"
    local g = "cleave_oh_text_g"
    local b = "cleave_oh_text_b"
    local a = "cleave_oh_text_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.EnableSlamDelayCheckBoxOnClick(self)
    character_warrior_settings.slam_delay_enabled = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.EnableSlamDelayDuelWieldingCheckBoxOnClick(self)
    character_warrior_settings.slam_delay_one_handing = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.EnableSlamGcdSparkCheckBoxOnClick(self)
    character_warrior_settings.slam_gcd_spark = self:GetChecked()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.SlamDelayColorPickerOnClick()
    local colorTable = character_warrior_settings
    local r = "slam_delay_r"
    local g = "slam_delay_g"
    local b = "slam_delay_b"
    local a = "slam_delay_a"
    local updateFunc = function()
        addon_data.warrior.UpdateConfigPanelValues()
        addon_data.warrior.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.warrior.SlamDelayOnValChange(self)
    character_warrior_settings.slam_delay = tonumber(self:GetValue())
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function addon_data.warrior.CreateConfigPanel(parent_panel)
    addon_data.warrior.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = addon_data.warrior.config_frame
    local settings = character_warrior_settings

    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L"Warrior Queuing Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enabled Checkbox
    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "WarriorEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables queued bar coloring.",
        addon_data.warrior.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)

    -- Color Main-Hand Checkbox
    panel.color_mh_checkbox = addon_data.config.CheckBoxFactory(
        "WarriorShowMainHandCheckBox",
        panel,
        L"Color Main-Hand Bar",
        L"Enables coloring of the main-hand swing bar.",
        addon_data.warrior.ColorMainHandCheckBoxOnClick)
    panel.color_mh_checkbox:SetPoint("TOPLEFT", 10, -60)

    -- Color Off-Hand Checkbox
    panel.color_oh_checkbox = addon_data.config.CheckBoxFactory(
        "WarriorShowOffHandCheckBox",
        panel,
        L"Color Off-Hand Bar",
        L"Enables coloring of the off-hand swing bar.",
        addon_data.warrior.ColorOffHandCheckBoxOnClick)
    panel.color_oh_checkbox:SetPoint("TOPLEFT", 10, -80)

    -- Cleave coloring checkbox
    panel.cleave_checkbox = addon_data.config.CheckBoxFactory(
        "WarriorCleaveCheckBox",
        panel,
        L"Cleave Coloring",
        L"Enables unique coloring of heroic strikes and cleaves.",
        addon_data.warrior.CleaveCheckBoxOnClick)
    panel.cleave_checkbox:SetPoint("TOPLEFT", 10, -125)

    -- Queued main-hand color picker
    panel.queued_mh_color_picker = addon_data.config.color_picker_factory(
        "WarriorQueuedMainHandColorPicker",
        panel,
        settings.queued_mh_r, settings.queued_mh_g, settings.queued_mh_b, settings.queued_mh_a,
        L"Queued Main-Hand Bar Color",
        addon_data.warrior.QueuedMainHandColorPickerOnClick)
    panel.queued_mh_color_picker:SetPoint("TOPLEFT", 205, -50)

    -- Queued main-hand color text picker
    panel.queued_mh_text_color_picker = addon_data.config.color_picker_factory(
        "WarriorQueuedMainHandTextColorPicker",
        panel,
        settings.queued_mh_text_r, settings.queued_mh_text_g, settings.queued_mh_text_b, settings.queued_mh_text_a,
        L"Queued Main-Hand Bar Text Color",
        addon_data.warrior.QueuedMainHandTextColorPickerOnClick)
    panel.queued_mh_text_color_picker:SetPoint("TOPLEFT", 205, -70)

    -- Queued off-hand color picker
    panel.queued_oh_color_picker = addon_data.config.color_picker_factory(
        "WarriorQueuedOffHandColorPicker",
        panel,
        settings.queued_oh_r, settings.queued_oh_g, settings.queued_oh_b, settings.queued_oh_a,
        L"Queued Off-Hand Bar Color",
        addon_data.warrior.QueuedOffHandColorPickerOnClick)
    panel.queued_oh_color_picker:SetPoint("TOPLEFT", 205, -100)

    -- Queued off-hand color text picker
    panel.queued_oh_text_color_picker = addon_data.config.color_picker_factory(
        "WarriorQueuedOffHandTextColorPicker",
        panel,
        settings.queued_oh_text_r, settings.queued_oh_text_g, settings.queued_oh_text_b, settings.queued_oh_text_a,
        L"Queued Off-Hand Bar Text Color",
        addon_data.warrior.QueuedOffHandTextColorPickerOnClick)
    panel.queued_oh_text_color_picker:SetPoint("TOPLEFT", 205, -120)

    -- Cleave main-hand color picker
    panel.cleave_mh_color_picker = addon_data.config.color_picker_factory(
        "WarriorCleaveMainHandColorPicker",
        panel,
        settings.cleave_mh_r, settings.cleave_mh_g, settings.cleave_mh_b, settings.cleave_mh_a,
        L"Cleave Main-Hand Bar Color",
        addon_data.warrior.CleaveMainHandColorPickerOnClick)
    panel.cleave_mh_color_picker:SetPoint("TOPLEFT", 205, -160)

    -- Cleave main-hand color text picker
    panel.cleave_mh_text_color_picker = addon_data.config.color_picker_factory(
        "WarriorCleaveMainHandTextColorPicker",
        panel,
        settings.cleave_mh_text_r, settings.cleave_mh_text_g, settings.cleave_mh_text_b, settings.cleave_mh_text_a,
        L"Cleave Main-Hand Bar Text Color",
        addon_data.warrior.CleaveMainHandTextColorPickerOnClick)
    panel.cleave_mh_text_color_picker:SetPoint("TOPLEFT", 205, -180)

    -- Cleave off-hand color picker
    panel.cleave_oh_color_picker = addon_data.config.color_picker_factory(
        "WarriorCleaveOffHandColorPicker",
        panel,
        settings.cleave_oh_r, settings.cleave_oh_g, settings.cleave_oh_b, settings.cleave_oh_a,
        L"Cleave Off-Hand Bar Color",
        addon_data.warrior.CleaveOffHandColorPickerOnClick)
    panel.cleave_oh_color_picker:SetPoint("TOPLEFT", 205, -210)

    -- Cleave off-hand color text picker
    panel.cleave_oh_text_color_picker = addon_data.config.color_picker_factory(
        "WarriorCleaveOffHandTextColorPicker",
        panel,
        settings.cleave_oh_text_r, settings.cleave_oh_text_g, settings.cleave_oh_text_b, settings.cleave_oh_text_a,
        L"Cleave Off-Hand Bar Text Color",
        addon_data.warrior.CleaveOffHandTextColorPickerOnClick)
    panel.cleave_oh_text_color_picker:SetPoint("TOPLEFT", 205, -230)

    -- Slam Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L"Warrior Slam Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -260)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enable Slam Delay Checkbox
    panel.enable_slam_delay = addon_data.config.CheckBoxFactory(
        "WarriorEnableSlamDelayCheckBox",
        panel,
        L"Enable Slam Delay",
        L"Enables an indicator at the end of the bar for pre-casting Slam.",
        addon_data.warrior.EnableSlamDelayCheckBoxOnClick)
    panel.enable_slam_delay:SetPoint("TOPLEFT", 10, -260)

    -- Enable Slam Delay Dual Wielding Checkbox
    panel.enable_slam_delay_one_handing = addon_data.config.CheckBoxFactory(
        "WarriorEnableSlamDelayDualWieldingCheckBox",
        panel,
        L"Show Slam Delay While One-Handing",
        nil,
        addon_data.warrior.EnableSlamDelayDuelWieldingCheckBoxOnClick)
    panel.enable_slam_delay_one_handing:SetPoint("TOPLEFT", 10, -280)

    -- Enable Slam Delay Checkbox
    panel.enable_slam_gcd_spark = addon_data.config.CheckBoxFactory(
        "WarriorEnableSlamGcdSparkCheckBox",
        panel,
        L"Enable Slam GCD Spark",
        L"Displays a spark 1.5s before the Slam Delay Bar.",
        addon_data.warrior.EnableSlamGcdSparkCheckBoxOnClick)
    panel.enable_slam_gcd_spark:SetPoint("TOPLEFT", 10, -300)

    -- Slam delay color picker
    panel.slam_delay_color_picker = addon_data.config.color_picker_factory(
        "WarriorSlamDelayColorPicker",
        panel,
        settings.slam_delay_r, settings.slam_delay_g, settings.slam_delay_b, settings.slam_delay_a,
        L"Slam Delay Bar Color",
        addon_data.warrior.SlamDelayColorPickerOnClick)
    panel.slam_delay_color_picker:SetPoint("TOPLEFT", 205, -290)

    -- Slam delay Slider
    panel.slam_delay_slider = addon_data.config.SliderFactory(
        "WarriorSlamDelaySlider",
        panel,
        L"Slam Delay",
        0,
        0.500,
        0.010,
        addon_data.warrior.SlamDelayOnValChange)
    panel.slam_delay_slider:SetPoint("TOPLEFT", 405, -290)

    -- Return the final panel
    addon_data.warrior.UpdateConfigPanelValues()
    return panel
end