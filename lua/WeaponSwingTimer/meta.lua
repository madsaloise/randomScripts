---@meta WeaponSwingTimer

---@alias SpellID SpellID

---@class SpellLine
---@field name string
---@field rank number
---@field castTime number|nil
---@field cooldown number|nil

---@class RGBA
---@field r number
---@field g number
---@field b number
---@field a number

---@class BarPalette
---@field bar RGBA
---@field text RGBA

---@class SpellPalette
---@field MainHand BarPalette?
---@field OffHand BarPalette?

---[Documentation](https://warcraft.wiki.gg/wiki/API_CombatLogGetCurrentEventInfo)
---@return any ...
function CombatLogGetCurrentEventInfo() end