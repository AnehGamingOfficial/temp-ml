--[[
════════════════════════════════════════════════════════════════
    GAME GUARDIAN CHEST HACK SCRIPT - ARM64
    Features: Auto-Open Chests, Distance Bypass, Teleport (placeholder),
              Loot Modifier (basic placeholder)
    Target: libil2cpp.so
════════════════════════════════════════════════════════════════
--]]

-- friendly safety: guard calls that may not exist in other environments
local safe = {}
safe.alert = gg.alert or function(...) end
safe.toast  = gg.toast  or function(...) end
safe.sleep  = gg.sleep  or function(ms) end
safe.setVisible = gg.setVisible or function(...) end
safe.isVisible  = gg.isVisible or function() return false end

safe.alert("Chest Hack Script v2.0\n\nFeatures:\n• Auto-Open All Chests\n• Infinite Interaction Distance\n• Teleport (manual placeholder)\n• Modify Chest Rewards (simple placeholder)\n\nMade for ARM64")

-- ════════════════════════════════════════════════════════════════
-- OFFSETS (user-supplied)
-- ════════════════════════════════════════════════════════════════
local OFFSETS = {
    ORIGINAL_1 = 0x500585c,
    ORIGINAL_2 = 0x4cec074,
    ORIGINAL_3 = 0x4cec528,
    ORIGINAL_4 = 0x4e44d34,
    ORIGINAL_5 = 0x4e4b0c8,

    GET_CHEST_BOX_CONFIG = 0x501f188,
    GET_MECHANISM_CHEST_CONFIG = 0x50200b4,
    GET_CHEST_BOX_RECORDS = 0x5020dbc,

    SPAWN_PRESENT_CHEST_BOX = 0x4c92eac,
    SPAWN_PRESENT_MECHANISM_CHEST = 0x4c94c58,

    ON_INTERACTION_RESULT = 0x4c7121c,
    ON_INTERACT_WAIT_CLIENT = 0x4c721e8,
    INTERACT_RESULT = 0x4ca0f2c,
    ON_INTERACTION_CHANGED = 0x4c9e6cc,
    ON_INTERACT = 0x4e2bb08,
    ON_INTERACT_LOOP_START = 0x4e2bb4c,

    MEET_QUERY_DISTANCE = 0x4c8a110,
    MEET_QUERY_DISTANCE_2 = 0x4cda8ac,
    IS_TARGET_IN_SIGHT = 0x52e414c,
    GET_DISTANCE = 0x4a69e60,

    GET_INTERACT_DURATION = 0x5017134,
    IS_OPERATION_VALID = 0x4ce85b8,
    IS_OPERATION_VALID_2 = 0x4ce868c,
    CAN_OPERATION_DISPLAY = 0x4ce87a4,
    GET_COOLDOWN = 0x4ce8808,
    HAS_COOLDOWN = 0x4ce88d4,
    IS_CONDITION_SATISFIED = 0x4ceb830,
    HAS_COST_ITEM_CONDITION = 0x4cebcdc,

    GET_LOOT_ID = 0x5014318,
    GET_LOOT_ID_2 = 0x50f0a5c,
    CALCULATE_LOOT_VALUE = 0x501af30,
    CALCULATE_LOOT_VALUE_BY_REF = 0x501c6c8,
    GET_LOOT_RECORDS = 0x5020e0c,
    FIND_LOOT = 0x5021040,
    GET_LOOTABLE_ID = 0x501a3f4,
    GET_LOOT_LEVEL_UP_INFO = 0x4b4eea8,
    PRESENTATION_SEARCH_LOOT = 0x4c8bc50,

    ON_TELEPORT = 0x4c70d24,

    CHEST_BOX_OPEN_CHANGED = 0x5006418,
    CHEST_BOX_DISTANCE = 0x14,
    CHEST_BOX_DISTANCE_SQR = 0x20,

    GET_OPERATION_CONDITION = 0x501ff78,
    COLLECT_OPERATION_CONDITION = 0x501e66c,
    GET_ITEM_GROUP_RECORDS = 0x5017b80,
    GET_ITEM_DURABILITY_RECORDS = 0x5018208,
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════

local function getLibBase()
    local ranges = gg.getRangesList("libil2cpp.so") or {}
    for i, v in ipairs(ranges) do
        if v.state == "Xa" then
            return v.start
        end
    end
    safe.alert("❌ Error: libil2cpp.so not found! Make sure the correct process is selected and the game uses IL2CPP.")
    return nil
end

local function calculateAddress(offset)
    local base = getLibBase()
    if base and offset then
        return base + tonumber(offset)
    end
    return nil
end

local function safeSetValue(addr, flags, value)
    if not addr then return false end
    local ok, err = pcall(function()
        gg.setValues({{address = addr, flags = flags, value = value}})
    end)
    if not ok then
        -- don't spam, just toast once
        safe.toast("Write failed at 0x" .. string.format("%X", addr))
        return false
    end
    return true
end

local function patchMemory(offset, value, valueType)
    local addr = calculateAddress(offset)
    if addr then
        return safeSetValue(addr, valueType, value)
    end
    return false
end

local function readMemory(offset, valueType)
    local addr = calculateAddress(offset)
    if not addr then return nil end
    local status, results = pcall(function()
        return gg.getValues({{address = addr, flags = valueType}})
    end)
    if not status or not results or #results == 0 then
        return nil
    end
    return results[1].value
end

-- ════════════════════════════════════════════════════════════════
-- FEATURES
-- ════════════════════════════════════════════════════════════════

local function enableInfiniteDistance()
    safe.toast("🎯 Enabling Infinite Interaction Distance...")
    -- ARM64 helper opcodes (32-bit instruction words)
    local MOV_W0_1 = 0x52800020 -- MOV W0, #1
    local RET = 0xD65F03C0     -- RET

    local distanceOffsets = {
        OFFSETS.MEET_QUERY_DISTANCE,
        OFFSETS.MEET_QUERY_DISTANCE_2,
        OFFSETS.IS_TARGET_IN_SIGHT,
    }

    local patched = 0
    for _, off in ipairs(distanceOffsets) do
        local addr = calculateAddress(off)
        if addr then
            -- write MOV W0, #1 ; RET
            safeSetValue(addr, gg.TYPE_DWORD, MOV_W0_1)
            safeSetValue(addr + 4, gg.TYPE_DWORD, RET)
            patched = patched + 1
        end
    end

    -- set has cooldown to false (MOV W0, #0 ; RET) or simply RET true depending on target
    if calculateAddress(OFFSETS.HAS_COOLDOWN) then
        safeSetValue(calculateAddress(OFFSETS.HAS_COOLDOWN), gg.TYPE_DWORD, 0x52800000) -- MOV W0, #0
    end
    if calculateAddress(OFFSETS.GET_COOLDOWN) then
        -- set cooldown float to 0.0 (write 0 as float)
        safeSetValue(calculateAddress(OFFSETS.GET_COOLDOWN), gg.TYPE_FLOAT, 0)
    end

    safe.alert("✅ Infinite Distance Enabled!\nPatched " .. patched .. " distance checks.")
end

local function autoOpenChests()
    safe.toast("🎁 Auto-Opening All Chests...")
    local conditionOffsets = {
        OFFSETS.IS_CONDITION_SATISFIED,
        OFFSETS.HAS_COST_ITEM_CONDITION,
        OFFSETS.IS_OPERATION_VALID,
        OFFSETS.IS_OPERATION_VALID_2,
    }
    local MOV_W0_1 = 0x52800020
    local RET = 0xD65F03C0

    for _, off in ipairs(conditionOffsets) do
        local addr = calculateAddress(off)
        if addr then
            safeSetValue(addr, gg.TYPE_DWORD, MOV_W0_1)
            safeSetValue(addr + 4, gg.TYPE_DWORD, RET)
        end
    end

    -- Set interaction duration to 0 (instant)
    if calculateAddress(OFFSETS.GET_INTERACT_DURATION) then
        safeSetValue(calculateAddress(OFFSETS.GET_INTERACT_DURATION), gg.TYPE_FLOAT, 0.0)
    end

    -- Force operation display to true
    local addr = calculateAddress(OFFSETS.CAN_OPERATION_DISPLAY)
    if addr then
        safeSetValue(addr, gg.TYPE_DWORD, MOV_W0_1)
        safeSetValue(addr + 4, gg.TYPE_DWORD, RET)
    end

    safe.alert("✅ Auto-Open Chests Enabled!\n• Instant interaction\n• Conditions bypassed")
end

local function modifyChestLoot()
    safe.toast("💰 Modifying Chest Rewards...")
    local input = gg.prompt({"Enter Loot Multiplier (1-1000):"}, {100}, {"number"})
    if not input or not input[1] then return end
    local lootMult = tonumber(input[1]) or 100
    if lootMult < 1 then lootMult = 1 end
    if lootMult > 1000 then lootMult = 1000 end

    -- NOTE: Proper loot modification typically requires reverse-engineering the
    -- calculate_loot_value function. Here we present a safe placeholder:
    -- attempt to write a float multiplier to nearby known function data if present.
    local written = 0
    local candidates = {
        OFFSETS.CALCULATE_LOOT_VALUE,
        OFFSETS.CALCULATE_LOOT_VALUE_BY_REF,
    }
    for _, off in ipairs(candidates) do
        local addr = calculateAddress(off)
        if addr then
            -- this is a heuristic: write the multiplier as a float at addr+0x10 (may be wrong)
            local ok = safeSetValue(addr + 0x10, gg.TYPE_FLOAT, lootMult)
            if ok then written = written + 1 end
        end
    end

    safe.alert("✅ Loot Modifier applied (heuristic).\nMultiplier: x" .. lootMult .. "\nPatched entries: " .. written .. "\n\nNote: Accurate loot changes require manual reverse engineering of the target game's functions.")
end

local function teleportToChests()
    safe.toast("🔍 Teleport helper (manual placeholder)...")
    local choice = gg.alert(
        "Teleport to Chests\n\nThis feature requires active chest coordinates.\n\nOptions:",
        "Scan Nearby",
        "Manual Input",
        "Cancel"
    )
    if choice == 1 then
        safe.toast("Scanning for chest entities (placeholder)...")
        local addr = calculateAddress(OFFSETS.GET_CHEST_BOX_RECORDS)
        if not addr then
            safe.alert("⚠️ Chest records address not found. Open the map near chests and try again.")
            return
        end
        safe.alert("⚠️ Scan is a placeholder. Implement entity scanning + pointer dereference for real teleport.")
    elseif choice == 2 then
        local coords = gg.prompt({"X Coordinate:", "Y Coordinate:", "Z Coordinate:"}, {0, 0, 0}, {"number", "number", "number"})
        if coords then
            safe.alert("Teleport coordinates set to:\nX: " .. coords[1] .. "\nY: " .. coords[2] .. "\nZ: " .. coords[3] .. "\n\n⚠️ Executing teleport requires writing entity position memory and is game-specific.")
        end
    end
end

local function patchOriginalOffsets()
    safe.toast("🔧 Patching Original Offsets...")
    local originalOffsets = {
        OFFSETS.ORIGINAL_1,
        OFFSETS.ORIGINAL_2,
        OFFSETS.ORIGINAL_3,
        OFFSETS.ORIGINAL_4,
        OFFSETS.ORIGINAL_5,
    }

    local MOV_W0_1 = 0x52800020
    local RET = 0xD65F03C0
    local count = 0
    for _, off in ipairs(originalOffsets) do
        local addr = calculateAddress(off)
        if addr then
            safeSetValue(addr, gg.TYPE_DWORD, MOV_W0_1)
            safeSetValue(addr + 4, gg.TYPE_DWORD, RET)
            count = count + 1
        end
    end
    safe.alert("✅ Original Offsets Patched!\nTotal: " .. count .. " offsets")
end

local function advancedChestHack()
    safe.toast("⚡ Applying Advanced Chest Hack (combo of heuristics)...")
    local MOV_W0_1 = 0x52800020
    local NOP = 0x1F2003D5
    local patches = {
        {offset = OFFSETS.SPAWN_PRESENT_CHEST_BOX, patch = MOV_W0_1},
        {offset = OFFSETS.SPAWN_PRESENT_MECHANISM_CHEST, patch = MOV_W0_1},
        {offset = OFFSETS.ON_INTERACTION_RESULT, patch = MOV_W0_1},
        {offset = OFFSETS.INTERACT_RESULT, patch = MOV_W0_1},
        {offset = OFFSETS.HAS_COOLDOWN, patch = 0x52800000}, -- MOV W0, #0
        {offset = OFFSETS.GET_COOLDOWN, patch = NOP},
    }

    local count = 0
    for _, p in ipairs(patches) do
        local addr = calculateAddress(p.offset)
        if addr then
            safeSetValue(addr, gg.TYPE_DWORD, p.patch)
            count = count + 1
        end
    end
    safe.alert("✅ Advanced Chest Hack Applied!\nTotal patches: " .. count)
end

local function showAllOffsets()
    local s = {}
    table.insert(s, "📋 All Chest-Related Offsets:\n")
    table.insert(s, "ORIGINAL OFFSETS:")
    table.insert(s, string.format("• 0x%X", OFFSETS.ORIGINAL_1))
    table.insert(s, string.format("• 0x%X", OFFSETS.ORIGINAL_2))
    table.insert(s, string.format("• 0x%X", OFFSETS.ORIGINAL_3))
    table.insert(s, string.format("• 0x%X", OFFSETS.ORIGINAL_4))
    table.insert(s, string.format("• 0x%X\n", OFFSETS.ORIGINAL_5))

    table.insert(s, "CHEST CONFIG:")
    table.insert(s, string.format("• GetChestBoxConfig: 0x%X", OFFSETS.GET_CHEST_BOX_CONFIG))
    table.insert(s, string.format("• GetMechanismChest: 0x%X", OFFSETS.GET_MECHANISM_CHEST_CONFIG))
    table.insert(s, string.format("• GetChestRecords: 0x%X\n", OFFSETS.GET_CHEST_BOX_RECORDS))

    table.insert(s, "INTERACTION:")
    table.insert(s, string.format("• InteractResult: 0x%X", OFFSETS.INTERACT_RESULT))
    table.insert(s, string.format("• OnInteract: 0x%X", OFFSETS.ON_INTERACT))
    table.insert(s, string.format("• OnInteractionChanged: 0x%X\n", OFFSETS.ON_INTERACTION_CHANGED))

    table.insert(s, "LOOT SYSTEM:")
    table.insert(s, string.format("• CalculateLootValue: 0x%X", OFFSETS.CALCULATE_LOOT_VALUE))
    table.insert(s, string.format("• GetLootRecords: 0x%X\n", OFFSETS.GET_LOOT_RECORDS))

    safe.alert(table.concat(s, "\n"))
end

-- ════════════════════════════════════════════════════════════════
-- MAIN MENU
-- ════════════════════════════════════════════════════════════════

local function mainMenu()
    local menu = gg.choice({
        "🎯 Enable Infinite Interaction Distance",
        "🎁 Auto-Open All Chests",
        "💰 Modify Chest Loot Rewards",
        "📍 Teleport to Chest Locations (placeholder)",
        "🔧 Patch Original User Offsets",
        "⚡ Apply All Chest Hacks (Combo)",
        "📋 Show All Offsets",
        "❌ Exit"
    }, nil, "Chest Hack Menu - ARM64")

    if menu == nil then
        safe.toast("Script Exited")
        os.exit()
    end

    if menu == 1 then
        enableInfiniteDistance()
    elseif menu == 2 then
        autoOpenChests()
    elseif menu == 3 then
        modifyChestLoot()
    elseif menu == 4 then
        teleportToChests()
    elseif menu == 5 then
        patchOriginalOffsets()
    elseif menu == 6 then
        advancedChestHack()
        enableInfiniteDistance()
        autoOpenChests()
        safe.alert("✅ ALL HACKS APPLIED!\n\n• Infinite Distance\n• Auto-Open Chests\n• Advanced Patches")
    elseif menu == 7 then
        showAllOffsets()
    elseif menu == 8 then
        safe.toast("Script Exited")
        os.exit()
    end
end

-- ════════════════════════════════════════════════════════════════
-- STARTUP & MAIN LOOP
-- ════════════════════════════════════════════════════════════════

-- ensure Game Guardian visibility toggles will trigger menu
if not safe.isVisible() then
    safe.setVisible(true)
end

local base = getLibBase()
if not base then
    safe.alert("❌ ERROR: libil2cpp.so not found!\n\nMake sure:\n1. Game is running\n2. You've selected the correct process\n3. The game uses IL2CPP")
    os.exit()
end

safe.toast("✅ libil2cpp.so found at: 0x" .. string.format("%X", base))

while true do
    if gg.isVisible() then
        gg.setVisible(false)
        mainMenu()
    end
    safe.sleep(100)
end
