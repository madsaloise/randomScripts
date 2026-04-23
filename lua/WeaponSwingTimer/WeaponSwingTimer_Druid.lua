---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

--- define addon structure from the above local variable
addon_data.druid = {}

addon_data.druid.default_settings = {
    -- bar coloring
    coloring_enabled = true,
    maul_r = 0.67, maul_g = 0.47, maul_b = 0.47, maul_a = 1.0,
    maul_text_r = 1.0, maul_text_g = 1.0, maul_text_b = 1.0, maul_text_a = 1.0,
}

function addon_data.druid.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_druid_settings then
        character_druid_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.druid.default_settings) do
        if character_druid_settings[setting] == nil then
            character_druid_settings[setting] = value
        end
    end
end

function addon_data.druid.RestoreDefaults()
    for setting, value in pairs(addon_data.druid.default_settings) do
        character_druid_settings[setting] = value
    end
    addon_data.druid.UpdateVisualsOnSettingsChange()
    addon_data.druid.UpdateConfigPanelValues()
end

--[[================================================================================]]--
--[[=================================== VISUALS ====================================]]--
--[[================================================================================]]--

local function UpdateColorPalettes()
    local settings = character_druid_settings

    if not settings.coloring_enabled then
        addon_data.queuing.UnregisterAllSpells()
    else
        local maulPalette = {
            MainHand = {
                bar = {
                    r = settings.maul_r,
                    g = settings.maul_g,
                    b = settings.maul_b,
                    a = settings.maul_a,
                },
                text = {
                    r = settings.maul_text_r,
                    g = settings.maul_text_g,
                    b = settings.maul_text_b,
                    a = settings.maul_text_a,
                }
            },
        }
        addon_data.queuing.RegisterSpell(L"Maul", maulPalette)
    end
end

function addon_data.druid.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "DRUID" then return end

    UpdateColorPalettes()
end

function addon_data.druid.InitializeVisuals()
    addon_data.druid.UpdateVisualsOnSettingsChange()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

function addon_data.druid.UpdateConfigPanelValues()
    local panel = addon_data.druid.config_frame
    local settings = character_druid_settings

    panel.enabled_checkbox:SetChecked(settings.coloring_enabled)

    panel.maul_color_picker.foreground:SetColorTexture(
        settings.maul_r, settings.maul_g, settings.maul_b, settings.maul_a)
    panel.maul_text_color_picker.foreground:SetColorTexture(
        settings.maul_text_r, settings.maul_text_g, settings.maul_text_b, settings.maul_text_a)
end

function addon_data.druid.EnabledCheckBoxOnClick(self)
    character_druid_settings.coloring_enabled = self:GetChecked()
    addon_data.druid.UpdateVisualsOnSettingsChange()
end

function addon_data.druid.MaulColorPickerOnClick()
    local colorTable = character_druid_settings
    local r = "maul_r"
    local g = "maul_g"
    local b = "maul_b"
    local a = "maul_a"
    local updateFunc = function()
        addon_data.druid.UpdateConfigPanelValues()
        addon_data.druid.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.druid.MaulTextColorPickerOnClick()
    local colorTable = character_druid_settings
    local r = "maul_text_r"
    local g = "maul_text_g"
    local b = "maul_text_b"
    local a = "maul_text_a"
    local updateFunc = function()
        addon_data.druid.UpdateConfigPanelValues()
        addon_data.druid.UpdateVisualsOnSettingsChange()
    end

    addon_data.config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function addon_data.druid.CreateConfigPanel(parent_panel)
    addon_data.druid.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = addon_data.druid.config_frame
    local settings = character_druid_settings

    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L"Druid Queuing Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enabled Checkbox
    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "DruidEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables queued bar coloring.",
        addon_data.druid.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)

    -- Queued main-hand color picker
    panel.maul_color_picker = addon_data.config.color_picker_factory(
        "DruidMaulColorPicker",
        panel,
        settings.maul_r, settings.maul_g, settings.maul_b, settings.maul_a,
        L"Maul Bar Color",
        addon_data.druid.MaulColorPickerOnClick)
    panel.maul_color_picker:SetPoint("TOPLEFT", 205, -50)

    -- Queued main-hand color text picker
    panel.maul_text_color_picker = addon_data.config.color_picker_factory(
        "DruidMaulTextColorPicker",
        panel,
        settings.maul_text_r, settings.maul_text_g, settings.maul_text_b, settings.maul_text_a,
        L"Maul Bar Text Color",
        addon_data.druid.MaulTextColorPickerOnClick)
    panel.maul_text_color_picker:SetPoint("TOPLEFT", 205, -70)

    -- Return the final panel
    addon_data.druid.UpdateConfigPanelValues()
    return panel
end