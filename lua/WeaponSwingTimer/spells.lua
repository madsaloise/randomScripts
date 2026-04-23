---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

spells = {}
addon_data.spells = spells

---@type table<SpellID, SpellLine>
spells.spellInfo = {}

-- Hunter
spells.spellInfo[75] = {name = L"Auto Shot", rank = nil, castTime = nil, cooldown = nil}
spells.spellInfo[5019] = {name = L"Shoot", rank = nil, castTime = nil, cooldown = nil}
spells.spellInfo[5384] = {name = L"Feign Death", rank = nil, castTime = nil, cooldown = nil}

if addon_data.utils.IsClassicWow() then
    -- Hunter
    spells.spellInfo[19506] = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[20905] = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[20906] = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    spells.spellInfo[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    spells.spellInfo[19434] = {name = L"Aimed Shot", rank = 1, castTime = 3.5, cooldown = 6}
    spells.spellInfo[20900] = {name = L"Aimed Shot", rank = 2, castTime = 3.5, cooldown = 6}
    spells.spellInfo[20901] = {name = L"Aimed Shot", rank = 3, castTime = 3.5, cooldown = 6}
    spells.spellInfo[20902] = {name = L"Aimed Shot", rank = 4, castTime = 3.5, cooldown = 6}
    spells.spellInfo[20903] = {name = L"Aimed Shot", rank = 5, castTime = 3.5, cooldown = 6}
    spells.spellInfo[20904] = {name = L"Aimed Shot", rank = 6, castTime = 3.5, cooldown = 6}
    spells.spellInfo[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    spells.spellInfo[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    spells.spellInfo[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    spells.spellInfo[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    spells.spellInfo[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    spells.spellInfo[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    spells.spellInfo[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    spells.spellInfo[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    -- Warrior
    spells.spellInfo[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    spells.spellInfo[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    spells.spellInfo[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    spells.spellInfo[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    -- Druid
    spells.spellInfo[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
elseif addon_data.utils.IsTbcWow() then
    -- Hunter
    spells.spellInfo[19506] = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[20905] = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[20906] = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[27066] = {name = L"Trueshot Aura", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    spells.spellInfo[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    spells.spellInfo[27021] = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    spells.spellInfo[19434] = {name = L"Aimed Shot", rank = 1, castTime = 3, cooldown = 6}
    spells.spellInfo[20900] = {name = L"Aimed Shot", rank = 2, castTime = 3, cooldown = 6}
    spells.spellInfo[20901] = {name = L"Aimed Shot", rank = 3, castTime = 3, cooldown = 6}
    spells.spellInfo[20902] = {name = L"Aimed Shot", rank = 4, castTime = 3, cooldown = 6}
    spells.spellInfo[20903] = {name = L"Aimed Shot", rank = 5, castTime = 3, cooldown = 6}
    spells.spellInfo[20904] = {name = L"Aimed Shot", rank = 6, castTime = 3, cooldown = 6}
    spells.spellInfo[27065] = {name = L"Aimed Shot", rank = 7, castTime = 3, cooldown = 6}
    spells.spellInfo[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    spells.spellInfo[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    spells.spellInfo[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    spells.spellInfo[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    spells.spellInfo[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    spells.spellInfo[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    spells.spellInfo[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    spells.spellInfo[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    spells.spellInfo[27014] = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    spells.spellInfo[34120] = {name = L"Steady Shot", rank = nil, castTime = 1.5, cooldown = nil}
    -- Warrior
    spells.spellInfo[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    spells.spellInfo[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    spells.spellInfo[29707] = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    spells.spellInfo[30324] = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    spells.spellInfo[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[25231] = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    spells.spellInfo[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    spells.spellInfo[25241] = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    spells.spellInfo[25242] = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    -- Druid
    spells.spellInfo[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[26996] = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
elseif addon_data.utils.IsWrathWow() then
    -- Hunter
    spells.spellInfo[19506] = {name = L"Trueshot Aura", rank = nil, castTime = nil, cooldown = nil}
    spells.spellInfo[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    spells.spellInfo[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    spells.spellInfo[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    spells.spellInfo[27021] = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    spells.spellInfo[49047] = {name = L"Multi-Shot", rank = 7, castTime = 0.5, cooldown = 10}
    spells.spellInfo[49048] = {name = L"Multi-Shot", rank = 8, castTime = 0.5, cooldown = 10}
    spells.spellInfo[19434] = {name = L"Aimed Shot", rank = 1, castTime = 0.5, cooldown = 10}
    spells.spellInfo[20900] = {name = L"Aimed Shot", rank = 2, castTime = 0.5, cooldown = 10}
    spells.spellInfo[20901] = {name = L"Aimed Shot", rank = 3, castTime = 0.5, cooldown = 10}
    spells.spellInfo[20902] = {name = L"Aimed Shot", rank = 4, castTime = 0.5, cooldown = 10}
    spells.spellInfo[20903] = {name = L"Aimed Shot", rank = 5, castTime = 0.5, cooldown = 10}
    spells.spellInfo[20904] = {name = L"Aimed Shot", rank = 6, castTime = 0.5, cooldown = 10}
    spells.spellInfo[27065] = {name = L"Aimed Shot", rank = 7, castTime = 0.5, cooldown = 10}
    spells.spellInfo[49049] = {name = L"Aimed Shot", rank = 8, castTime = 0.5, cooldown = 10}
    spells.spellInfo[49050] = {name = L"Aimed Shot", rank = 9, castTime = 0.5, cooldown = 10}
    spells.spellInfo[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    spells.spellInfo[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    spells.spellInfo[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    spells.spellInfo[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    spells.spellInfo[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    spells.spellInfo[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    spells.spellInfo[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    spells.spellInfo[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    spells.spellInfo[27014] = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    spells.spellInfo[48995] = {name = L"Raptor Strike", rank = 10, castTime = nil, cooldown = 6}
    spells.spellInfo[48996] = {name = L"Raptor Strike", rank = 11, castTime = nil, cooldown = 6}
    spells.spellInfo[56641] = {name = L"Steady Shot", rank = 1, castTime = 1.5, cooldown = nil}
    spells.spellInfo[34120] = {name = L"Steady Shot", rank = 2, castTime = 1.5, cooldown = nil}
    spells.spellInfo[49051] = {name = L"Steady Shot", rank = 3, castTime = 1.5, cooldown = nil}
    spells.spellInfo[49052] = {name = L"Steady Shot", rank = 4, castTime = 1.5, cooldown = nil}
    -- Warrior
    spells.spellInfo[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    spells.spellInfo[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    spells.spellInfo[29707] = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    spells.spellInfo[30324] = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    spells.spellInfo[47449] = {name = L"Heroic Strike", rank = 12, castTime = nil, cooldown = nil}
    spells.spellInfo[47450] = {name = L"Heroic Strike", rank = 13, castTime = nil, cooldown = nil}
    spells.spellInfo[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[25231] = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[47519] = {name = L"Cleave", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[47520] = {name = L"Cleave", rank = 8, castTime = nil, cooldown = nil}
    spells.spellInfo[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    spells.spellInfo[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    spells.spellInfo[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    spells.spellInfo[25241] = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    spells.spellInfo[25242] = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    spells.spellInfo[47474] = {name = L"Slam", rank = 7, castTime = 1.5, cooldown = nil}
    spells.spellInfo[47475] = {name = L"Slam", rank = 8, castTime = 1.5, cooldown = nil}
    -- Druid
    spells.spellInfo[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    spells.spellInfo[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    spells.spellInfo[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    spells.spellInfo[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    spells.spellInfo[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    spells.spellInfo[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    spells.spellInfo[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    spells.spellInfo[26996] = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
    spells.spellInfo[48479] = {name = L"Maul", rank = 9, castTime = nil, cooldown = nil}
    spells.spellInfo[48480] = {name = L"Maul", rank = 10, castTime = nil, cooldown = nil}
end

---@param name string
---@return table<SpellID, SpellLine>
local function GetSpellLines(name)
    local spellLines = {}
    for spellID, spellInfo in pairs(spells.spellInfo) do
        if spellInfo.name == name then
            spellLines[spellID] = spellInfo
        end
    end
    return spellLines
end

---@param name string
---@return table<SpellID, true>
local function GetSpellIDs(name)
    local spellIDs = {}
    for spellID, spellInfo in pairs(spells.spellInfo) do
        if spellInfo.name == name then
            spellIDs[spellID] = true
        end
    end
    return spellIDs
end

---Returns spell lines for each spell named.
---@param ... string -- Localized spell names
---@return table<SpellID, SpellLine>
function addon_data.spells.GetSpellLines(...)
    local args = {...}
    if #args == 1 then
        return GetSpellLines(args[1])
    else
        local spellLines = {}
        for _, name in ipairs(args) do
            for spellID, spellInfo in pairs(GetSpellLines(name)) do
                spellLines[spellID] = spellInfo
            end
        end
        return spellLines
    end
end

---Returns spell IDs for each spell named.
---@param ... string -- Localized spell names
---@return table<SpellID, true>
function addon_data.spells.GetSpellIDs(...)
    local args = {...}
    if #args == 1 then
        return GetSpellIDs(args[1])
    else
        local spellIDs = {}
        for _, name in ipairs(args) do
            for spellID, _ in pairs(GetSpellIDs(name)) do
                spellIDs[spellID] = true
            end
        end
        return spellIDs
    end
end