LibBaseAnogs = gg.getRangesList("libanogs.so")
if #LibBaseAnogs == 0 then return end

ListOffsetsAnogs = {
    0x00515e40,  -- gettimeofday
}

for i = 1, #ListOffsetsAnogs do
    gg.setValues({
        {
            address = LibBaseAnogs[1].start + ListOffsetsAnogs[i],
            flags = gg.TYPE_QWORD,
            value = "h 00 00 80 D2 C0 03 5F D6"
        }
    })
end

LibBaseAnort = gg.getRangesList("libanort.so")
if #LibBaseAnort == 0 then return end

ListOffsetsAnort = {
    0x00193880,  -- gettimeofday
}

for i = 1, #ListOffsetsAnort do
    gg.setValues({
        {
            address = LibBaseAnort[1].start + ListOffsetsAnort[i],
            flags = gg.TYPE_QWORD,
            value = "h 00 00 80 D2 C0 03 5F D6"
        }
    })
end

gg.clearResults()
gg.setRanges(gg.REGION_ANONYMOUS)
gg.searchNumber("-15.125", 16)
local results = gg.getResults(gg.getResultsCount())
gg.clearResults()
local t = {}
for i = 1, #results do
    t[i] = {flags = 16, address = results[i].address - 0x84}
end
gg.loadResults(t)
gg.getResults(gg.getResultsCount())
gg.refineNumber("5", 16)
gg.getResults(gg.getResultsCount())
gg.editAll("750", 16)
gg.clearResults()
Anti FC + High Jump by GG    -- === PATCH ===
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
