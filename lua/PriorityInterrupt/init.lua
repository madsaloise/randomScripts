aura_env.Prefix = "JODS_INT_V2"
C_ChatInfo.RegisterAddonMessagePrefix(aura_env.Prefix)
--Getting info from LibSpec and returning it to the trigger

-- helper function to handle sorting via custom options. This is bad practice and shouldn't be done if it could be avoided
local sortOption = aura_env.config.sorting.sortType
aura_env.sortForSettings = function(a,b)
    if not a and not b then
        return
    elseif not a and b then
        return b
    elseif not b and a then
        return a
    end
    
    if sortOption == 2 then
        return a<b
    else
        return a>b
        
    end
end

-- if this spell is cast reduce cooldown of Interupt spell by CD amount
aura_env.CastSuccessModifiers = {
    [382445] = {
        spell = 2139,
        CD = 2.5
    }, -- mage shifting power ticks
    [382440] = {
        spell = 2139,
        CD = 2.5
    }, -- mage shifting power initial cast
    [404977] = {
        spell = 351338,
        CD = 20
    }, -- augmentation Time Skip
    
}
-- if this interrupt is succesfully and the talent is selected used reduce the cooldown by the CD amount
aura_env.InterruptSuccessModifiers = {
    [78675] = {
        talent = 128588,
        CD = 15
    }, -- balance druid
    [47528] = {
        talent = 96212,
        CD = 3
    },  -- DeathKnight
    [2139] = {
        talent = 80161 ,
        CD =4 
    }, -- mage
}
-- when this talent is selected the cooldown of the spell is reduced by the modifier amount CD*(1-modifer) = currentCD
aura_env.PercentModifiers = {
    [351338] = {
        talent = 115686, 
        modifier = 0.1
    } -- augmentation interwoven threads
}
-- maps the silence spellid to the casted spell
aura_env.silenceMap = { 
    [220543] = 15487,  --silence
    [97547]  = 78675,  --solar beam
    [93985]  = 106839, --skullbash  
    [347008] = 89766,  --axe toss Check Zen
    [132409] = 19647,  --Spell Lock (Sacrifice)
}
-- which spells are casted by pets
aura_env.petSpells = {
    [19647]  = 119910, --Spell Lock if used from pet bar
    [132409] = 119910, --Spell Lock Command Demon Sacrifice
    [89766] = 119914 -- axe toss from pet bar]
    --TODO: DK Leap
}

aura_env.ClassList = {
    -- warrior
    [71]= { --Arms
        [6552] = { --Pummel
            default = 15 -- cooldown
        }
    },
    [72]= { -- Fury
        [6552] = { -- Pummel
            default = 15 -- cooldown
        }
    },
    [73]= { -- Protection
        [6552] = { -- Pummel
            default = 15 -- cooldown
        },
        [23920] = { -- Spell Reflection
            required={
                [112253] = true -- selected talent
            },
            [112253] = 20 -- cooldown
        }, 
        [386071] ={ -- Disrupting Shout
            required = {
                [112161] = true -- selected talent
            },
            [112161] = 75 -- cooldown
        }
    }, 
    -- paladin
    [65]=  { -- Holy
        [96231] = { -- Rebuke
            required = {
                [102591] = true -- selected talent
            },
            [102591] = 15 -- cooldown
        }
    },
    [66]= { -- Protection
        [96231] = { -- Rebuke
            required = {
                [102591] = true -- selected talent
            },
            [102591] = 15 -- cooldown
        },
        [31935] = { -- Avenger's Shield
            default = 15 -- cooldown
        }
    },
    [70]= { -- Retribution
        [96231] = { -- Rebuke
            required ={
                [102591] = true -- selected talent
            },
            [102591] = 15 -- cooldown
        }
    },
    --HUNTER
    [253]= { -- Beast Mastery    
        [147362] = { -- Counter Shot
            required = {
                [126352] = true -- selected talent
            },
            [126352] = 24 -- cooldown
        }
    },
    
    [254]={ -- Marksmanship    
        [147362] = { -- Counter Shot
            required = {
                [126466] = true -- selected talent
            },
            [126466] = 24 -- cooldown
        }
    },
    [255]= { -- Survival
        [187707] = { -- Muzzle
            required = {
                [100543] = true -- selected talent
            } ,
            [100543] = 15 -- cooldown
        }
    },
    --ROGUE"
    [259]= { -- Assassination
        [1766] = { -- Kick
            default = 15 -- cooldown
        }
    },
    [260]= { -- Outlaw
        [1766] = { -- Kick
            default = 15 -- cooldown
        }
    },
    [261]= { -- Subtlety 
        [1766] = { -- Kick
            default = 15 -- cooldown
        }
    },
    --PRIEST
    [256]= nil, -- no kick for disc
    [257]= nil, -- no kick for holy
    [258]= {
        [15487] = { -- Silence
            required = {
                [103792] = true -- selected talent
            },
            [103794] = 15, -- additional reduction when talented
            [103792] = 45 -- Normal Cooldown
        }
    },
    --DEATHKNIGHT 
    [250]= { -- Blood
        [47528] = { -- Mind Freeze
            required ={
                [96213] = true -- selected talent
            } ,
            [96213] = 15 -- cooldown
        }
    }, 
    [251]= { -- Frost
        [47528] = { -- Mind Freeze
            required ={
                [96213] = true -- selected talent
            },
            [96213] = 15 -- cooldown
        }
    },
    [252]= { -- Unholy
        [47528] = { -- Mind Freeze
            required ={
                [96213] = true -- selected talent
            },
            [96213] = 15 -- cooldown
        }
    },
    --SHAMAN
    [262]= { -- Elemental
        [57994] = { -- Wind Shear
            required = {
                [127892] = true -- selected talent
            } ,
            [127892] = 12 -- cooldown
        }
    },
    [263]= { -- Enhancement
        [57994] = { -- Wind Shear
            required ={
                [127892] = true -- selected talent
            },
            [127892] = 12 -- cooldown
        }
    },
    [264]= { -- Restoration
        [57994] = { -- Wind Shear
            required ={
                [127892] = true -- selected talent
            }, 
            [127892] = 12 -- cooldown
        }
    },
    --MAGE
    [62]= { -- Arcane
        [2139] = { -- Counterspell
            default = 24 -- cooldown
        }
    },
    [63]= { -- Fire
        [2139] = { -- Counterspell
            default = 24 -- cooldown
        }
    },
    [64]= { -- Frost
        [2139] = { -- Counterspell
            default = 24 -- cooldown
        }
    },
    --"WARLOCK
    [265]= { -- Affliction
        [119910] = { -- Spell Lock (pet)
            default = 24, -- cooldown
            disabled = {
                [124691] = true -- grimoir of sacrifice
            }
        }, 
        [132409] = { -- Spell Lock
            required = {
                [124691] = true -- grimoir of sacrifice
            },
            [124691] = 24 -- cooldown
        }
    },
    [266]= { -- Demonology
        [119914] = { -- Axe Toss
            default = 30 -- cooldown
        }
    },
    [267]= { -- Destruction    
        [119910] = { -- Spell Lock (pet)
            default = 24, -- cooldown
            disabled = {
                [125618] = true -- grimoir of sacrifice
            } 
        },
        [132409] = {
            required = { -- Spell Lock
                [125618] = true -- grimoir of sacrifice
            },
            [125618] = 24 -- cooldown
        }
    },
    --MONK
    [268]= { -- Brewmaster
        [116705] = { -- Spear Hand Strike
            required = {
                [124943] = true -- selected talent
            },
            [124943] = 15 -- cooldown
        }
    },
    [270]= { -- Mistweaver
        [116705] = { -- Spear Hand Strike
            required ={
                [124943] = true -- selected talent
            },
            [124943] = 15 -- cooldown
        }
    },
    [269]= { -- Windwalker
        [116705] = { -- Spear Hand Strike
            required ={
                [124943] = true -- selected talent
            },
            [124943] = 15 -- cooldown
        }
    },
    --DRUID
    [102]= { -- Balance
        [78675] = { -- Solar Beam
            required ={
                [109867] = true -- selected talent
            },
            [109867] = 60 -- cooldown
        }
    },
    [103]= { --Feral
        [106839] ={ -- Skull Bash
            required ={
                [103322] = true -- selected talent
            },
            [103322] = 15 -- cooldown
        }
    },
    [104]= { -- Guardian
        [106839] ={ -- Skull Bash
            required ={
                [103322] = true -- selected talent
            },
            [103322] = 15 -- cooldown
        }
    },
    [105]= { -- Restoration
        [106839] ={ -- Skull Bash
            required ={
                [103322] = true -- selected talent
            },
            [103322] = 15 -- cooldown
        }
    },
    --DEMONHUNTER
    [577]= { -- Havoc
        [183752] = { -- Disrupt
            default = 15 -- cooldown
        }
    },
    [581]= { -- Vengeance
        [183752] = { -- Disrupt
            default = 15 -- cooldown
        },
        [202137] = { -- Sigil of Silence
            required = {
                [112904] = true -- selected talent
            } , 
            disabled = {
                [117771] = true -- previse sigils
            },
            [112904] = 90 -- cooldown
        } ,
        [389809] = { -- Sigil of Silence with previse sigils
            required = {
                [112904] = true, -- selected talent
                [117771] = true -- previse sigils
            },
            [112904] = 90, -- cooldown
            [117771] = 90 -- cooldown
        },
    },
    -- Evoker
    [1467]= { -- Devastation
        [351338] = { -- Quell
            required = {
                [115620] = true -- selected talent
            } , 
            [115645] = 20, -- imposing presence
            [115620] = 40 -- cooldown
        },
    },
    [1468]= { -- Preservation
        [351338] = { -- Quell
            required = {
                [115620] = true -- selected talent
            },
            [115620] = 40 -- cooldown
        },
    },
    [1473]= { -- Augmentation    
        [351338] = {  -- Quell
            required = {
                [115620] = true -- selected talent
            } ,            
            [115497] = 20, -- imposing presence
            [115620] = 40 -- cooldown
        },
    },
    
}
-- special handling for pet shenanigans
aura_env.specialAllowlist = {}

if aura_env.config.enabledInterrupts["119910"] then
    aura_env.specialAllowlist[132409] = true
end

if aura_env.config.enabledInterrupts["202137"] then
    aura_env.specialAllowlist[389809]= true
end



--  build the list to easier check against if spell even exists
aura_env.spells = {}
for specID, classDetails in pairs(aura_env.ClassList) do
    for spellID, _ in pairs(classDetails) do
        aura_env.spells[spellID] = true
    end
end

-- Watch spell cooldown updates for player spells. These can later be used to send updates to party members if the cooldown somehow changes 
local specSpells = aura_env.ClassList[GetSpecializationInfo(GetActiveSpecGroup())]
if specSpells then
    for k,_ in pairs (specSpells) do
        WeakAuras.WatchSpellCooldown(k)
        
    end
end

-- spells that are cast by pets needs to be matched back to it's owner to show proper interrupts
aura_env.adjustForPetInterrupts = function(sourceGUID,spellId)
    -- if the unit is the players pet we can skip iteration
    if UnitGUID("pet") == sourceGUID then
        sourceGUID=UnitGUID("PLAYER")
    else
        -- match the pet to it's owner by iterating the group and overwrite the guid
        for u in WA_IterateGroupMembers() do
            if UnitGUID(u.."pet") == sourceGUID then
                sourceGUID = UnitGUID(u)
                break
            end
        end
    end
    -- if it is actually a petspell
    if aura_env.petSpells[spellId] then
        spellId = aura_env.petSpells[spellId]
    end
    return sourceGUID, spellId
end
-- check if a spell should be active
aura_env.getSpellIsActive = function(spell,specId,unit)
    local isRequiredActive = true
    -- if the interrupt isn't enabled in custom options disable it
    if not (aura_env.specialAllowlist[spell] or aura_env.config.enabledInterrupts[tostring(spell)]) then
        return false 
    end
    -- check if required talents are active
    if aura_env.ClassList[specId][spell].required then
        for talent,_ in pairs(aura_env.ClassList[specId][spell].required) do
            if WeakAuras.CheckTalentForUnit(unit,talent) == 0 then
                isRequiredActive = false
                break
            end
        end
    end
    -- check if non of the disabling talents are active
    if aura_env.ClassList[specId][spell].disabled then
        for talent,_ in pairs(aura_env.ClassList[specId][spell].disabled) do
            if WeakAuras.CheckTalentForUnit(unit,talent) == 1 then
                isRequiredActive = false
                break
            end
        end
    end
    
    return isRequiredActive
end

-- get the cooldown of a spell
aura_env.getCooldownOfSpell = function (spell,unit,spellID)
    if not spell then print("spell is nil") return 0 end
    local Cooldown = spell.default or 0 -- If a spell doesn't have a default cd assume it's 0
    if spell.required then
        for requiredTalent in pairs (spell.required) do
            -- if a spell doesn't have a default cd it should have a required cd check what that is and set it
            if WeakAuras.CheckTalentForUnit(unit, requiredTalent) and WeakAuras.CheckTalentForUnit(unit, requiredTalent) == 1 then
                Cooldown = spell[requiredTalent]
            end
        end
    end
    
    for key in pairs (spell) do
        -- iterate over all talents and adjust cooldown for non required talents that have data setup
        if key~= "required" and key ~="default" and (not spell.required or not spell.required[key]) then
            if WeakAuras.CheckTalentForUnit(unit, key) == 1 then
                Cooldown = Cooldown - spell[key]
            end
        end
    end
    -- some classes (mainly aug evoker right now) have percentage based cooldown modifiert. Apply them here if appropriate talents are selected
    if aura_env.PercentModifiers[spellID] and WeakAuras.CheckTalentForUnit(unit, aura_env.PercentModifiers[spellID].talent) then
        Cooldown = Cooldown * (1- aura_env.PercentModifiers[spellID].modifier)
    end
    return Cooldown
end









