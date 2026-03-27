local GetTimePreciseSec = GetTimePreciseSec
local GetTime = GetTime
local GetNetStats = GetNetStats
local UnitAttackSpeed = UnitAttackSpeed

aura_env.config.worldPingOffset = 0
aura_env.fqEnabled = true
aura_env.swingTimer = 0        -- seconds remaining, stolen from WST's main_swing_timer
aura_env.weaponSpeed = 0       -- seconds,
aura_env.prevWeaponSpeed = 0
aura_env.lastFrameTime = 0

-- Mirrors WST swing_reset_spells['WARRIOR'] exactly
aura_env.slamResetSpells = {
    -- Heroic Strike
    [78]=true,[284]=true,[285]=true,[1608]=true,
    [11564]=true,[11565]=true,[11566]=true,[11567]=true,[25286]=true,
    -- Cleave
    [845]=true,[7369]=true,[11608]=true,[11609]=true,[20569]=true,
    -- Slam
    [1464]=true,[8820]=true,[11604]=true,[11605]=true,
}

aura_env.updateWeaponSpeed = function()
    aura_env.prevWeaponSpeed = aura_env.weaponSpeed
    aura_env.weaponSpeed = UnitAttackSpeed("player")  -- main hand only
    -- If haste changed, scale timer proportionally (stolen WST OnUpdate)
    if aura_env.prevWeaponSpeed > 0 and 
       aura_env.weaponSpeed ~= aura_env.prevWeaponSpeed and
       aura_env.swingTimer > 0 then
        local multiplier = aura_env.weaponSpeed / aura_env.prevWeaponSpeed
        aura_env.swingTimer = aura_env.swingTimer * multiplier
    end
end

aura_env.resetSwing = function()
    aura_env.updateWeaponSpeed()
    aura_env.swingTimer = aura_env.weaponSpeed
    -- Store absolute end time for FQ calculation
    aura_env.swingEndTime = GetTime() + aura_env.weaponSpeed
end

aura_env.getSwingEndTime = function()
    return aura_env.swingEndTime
end

local function getOffset()
    if aura_env.config.useWorldPingOffset then
        return (select(4, GetNetStats()) + aura_env.config.worldPingOffset) / 1000
    else
        return aura_env.config.absoluteOffset / 1000
    end
end

local function fakeQueue() end  -- busy wait body

local function fakeQueueSlam()
    if not aura_env.fqEnabled then return end
    if not aura_env.swingEndTime then return end

    local now = GetTime()
    local offset = getOffset()
    local targetTime = aura_env.swingEndTime - offset
    local waitFor = targetTime - now  -- in seconds

    local maxWaitSec = aura_env.config.maxWait / 1000
    local weaponSpeedSec = aura_env.weaponSpeed

    -- Don't wait if swing is in the past or more than one swing away
    if waitFor <= 0 or waitFor > weaponSpeedSec then return end

    -- Don't freeze longer than maxWait
    if waitFor > maxWaitSec then return end

    local waitMs = waitFor * 1000
    local start = GetTimePreciseSec() * 1000
    while GetTimePreciseSec() * 1000 - start < waitMs do
        fakeQueue()
    end
end

setglobal("SlamFQ", fakeQueueSlam)
setglobal("SlamFQToggle", function()
    aura_env.fqEnabled = not aura_env.fqEnabled
    WeakAuras.ScanEvents("WA_SLAMFQ_TOGGLE")
end)

-- Initialize weapon speed on load
aura_env.weaponSpeed = UnitAttackSpeed("player") or 2
aura_env.prevWeaponSpeed = aura_env.weaponSpeed