-- Game Guardian Script: PATCH + FREEZE GetMaxAirJumpCount
-- Forces return value AND locks it in memory forever

gg.setVisible(false)

-- CONFIG
local METHOD_OFFSET = 0x4FF590C
local DESIRED_JUMP_COUNT = 999
local LIB_NAME = "libil2cpp.so"

-- Get base
function getLibBase()
    local r = gg.getRangesList(LIB_NAME)
    if #r == 0 then gg.alert("libil2cpp.so not found!") os.exit() end
    return r[1].start
end

-- Main
function applyPatchAndFreeze()
    local base = getLibBase()
    local addr = base + METHOD_OFFSET

    -- Validate address
    local test = gg.getValues({{address = addr, flags = gg.TYPE_BYTE}})
    if not test[1].value then
        gg.alert("Cannot read method address!")
        return
    end

    -- Build ARM64 instructions
    local imm = DESIRED_JUMP_COUNT
    if imm > 0xFFFF then imm = 999 end

    local mov_w0 = 0x52800000 | (imm << 5)   -- MOV W0, #imm16
    local ret    = 0xD65F03C0                -- RET

    -- === PATCH ===
    gg.setValues({
        {address = addr,     flags = gg.TYPE_DWORD, value = mov_w0},
        {address = addr + 4, flags = gg.TYPE_DWORD, value = ret}
    })

    -- === FREEZE PATCH IN MEMORY ===
    local freezeList = {
        {address = addr,     flags = gg.TYPE_DWORD, value = mov_w0, freeze = true, freezeType = gg.FREEZE_NORMAL},
        {address = addr + 4, flags = gg.TYPE_DWORD, value = ret,    freeze = true, freezeType = gg.FREEZE_NORMAL}
    }
    gg.addListItems(freezeList)

    gg.toast("PATCHED + FROZEN!")
    gg.alert(
        "SUCCESS: GetMaxAirJumpCount = " .. imm .. "\n" ..
        "Method: 0x" .. string.format("%X", addr) .. "\n" ..
        "Offset: 0x" .. string.format("%X", METHOD_OFFSET) .. "\n\n" ..
        "FROZEN IN GG LIST — WILL STAY EVEN AFTER RESTART!"
    )
end

-- === MENU ===
local choice = gg.choice({
    "Apply Patch + Freeze",
    "Change Value & Re-Freeze",
    "Remove Freeze (Unpatch)",
    "Exit"
}, nil, "Air Jump: Patch + Freeze")

if choice == 1 then
    applyPatchAndFreeze()
elseif choice == 2 then
    local input = gg.prompt({"New jump count (1-65535):"}, {DESIRED_JUMP_COUNT}, {"number"})
    if input then
        DESIRED_JUMP_COUNT = input[1]
        if DESIRED_JUMP_COUNT > 65535 then DESIRED_JUMP_COUNT = 65535 end
        -- Clear old freeze
        gg.removeListItems(gg.getListItems())
        applyPatchAndFreeze()
    end
elseif choice == 3 then
    gg.removeListItems(gg.getListItems())
    gg.alert("Freeze removed. Restart game to fully restore.")
end
