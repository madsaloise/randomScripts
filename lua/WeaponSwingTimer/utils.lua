---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)

addon_data.utils = {}

local interfaceVersion = select(4, GetBuildInfo())

-- Sends the given message to the chat frame with the addon name in front.
function addon_data.utils.PrintMsg(msg)
    chat_msg = "|cFF00FFB0" .. addon_name .. ": |r" .. msg
    DEFAULT_CHAT_FRAME:AddMessage(chat_msg)
end

-- Rounds the given number to the given step.
-- If num was 1.17 and step was 0.1 then this would return 1.1
-- the step / 100 addition is to prevent rounding errors (i.e. 1.999997 instead of 2)
function addon_data.utils.SimpleRound(num, step)
    return floor(num / step + step / 100) * step
end

function addon_data.utils.IsClassicWow()
    return interfaceVersion < 20000
end

function addon_data.utils.IsTbcWow()
    return interfaceVersion < 30000 and interfaceVersion >= 20000
end

function addon_data.utils.IsWrathWow()
    return interfaceVersion < 40000 and interfaceVersion >= 30000
end