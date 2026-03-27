function()
    local colorRed = "FFFF3333"
    local colorYellow = "fffff569"
    local colorGreen = "FF42FF33"

    local color
    if aura_env.threatPercent < 70 then
        color = colorGreen
    elseif aura_env.threatPercent < 90 then
        color = colorYellow
    else
        color = colorRed
    end

    local threatPercent = aura_env.threatPercent .. "%"
    if aura_env.config["show_position"] then
        threatPercent = threatPercent .. " (#" .. aura_env.position .. ")"
    end

    local function formatGap(value)
        local absVal = math.abs(value)
        local formatted
        if absVal >= 10000 then
            formatted = math.floor(absVal / 1000) .. "k"
        else
            formatted = FormatLargeNumber(absVal)
        end
        if value > 0 then
            return "+" .. formatted
        elseif value < 0 then
            return "-" .. formatted
        else
            return formatted
        end
    end

    return WrapTextInColorCode(threatPercent, color),
           WrapTextInColorCode(formatGap(aura_env.gapToFirst), color),
           WrapTextInColorCode(formatGap(aura_env.gapToSecond), color)
end