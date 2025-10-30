-- Game Guardian Script: Freeze MaxAirJumpCount using Offset
-- Target: public System.Int32 GetMaxAirJumpCount(System.Boolean check); // 0x4FF590C

gg.setVisible(false)

local METHOD_OFFSET = 0x4FF590C
local LIB_NAME = "libil2cpp.so"
local SEARCH_RANGE = 0x10000  -- Search ±64KB around method
local FREEZE_VALUE = 999

-- Get library base
function getLibBase()
    local ranges = gg.getRangesList(LIB_NAME)
    if #ranges == 0 then
        gg.alert(LIB_NAME .. " not found!")
        os.exit()
    end
    return ranges[1].start
end

-- Read return value of method by calling it via register hook (ARM64)
function getCurrentJumpCount()
    local libBase = getLibBase()
    local addr = libBase + METHOD_OFFSET

    -- Backup original instructions
    local backup = gg.getValues({
        {address = addr, flags = gg.TYPE_DWORD},
        {address = addr + 4, flags = gg.TYPE_DWORD}
    })

    -- Inject: MOV W0, #0xAAAA ; RET  (we'll read W0 after call)
    gg.setValues({
        {address = addr,     flags = gg.TYPE_DWORD, value = 0x52815540}, -- mov w0, #0xAAA
        {address = addr + 4, flags = gg.TYPE_DWORD, value = 0xD65F03C0}  -- ret
    })

    -- Trigger method call (just wait a bit or move in-game)
    gg.toast("Move or jump in-game to trigger GetMaxAirJumpCount...")
    gg.sleep(2000)

    -- Restore
    gg.setValues(backup)

    -- Now search for 0xAAA in memory → this is our return value
    gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
    gg.searchNumber("43690", gg.TYPE_DWORD)  -- 0xAAA = 43690
    local results = gg.getResults(100)
    gg.clearResults()

    if #results == 0 then
        gg.alert("Failed to capture return value.")
        return nil
    end

    -- Assume first result is in W0 register context → not useful
    -- We need the *actual field* — so return nothing, proceed to search near method
    return nil
end

-- MAIN: Search near method for the return value
function main()
    local libBase = getLibBase()
    local methodAddr = libBase + METHOD_OFFSET
    gg.toast("libil2cpp.so: 0x" .. string.format("%X", libBase))
    gg.toast("Method: 0x" .. string.format("%X", methodAddr))

    -- Step 1: Get current default value (ask user)
    local input = gg.prompt({"What is the CURRENT max air jumps? (e.g., 1)"}, {1}, {"number"})
    if not input then return end
    local currentValue = input[1]

    -- Step 2: Search near method (±64KB) for that value
    local startAddr = methodAddr - SEARCH_RANGE
    local endAddr = methodAddr + SEARCH_RANGE

    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(currentValue, gg.TYPE_DWORD, false, false, startAddr, endAddr)

    local count = gg.getResultCount()
    if count == 0 then
        gg.alert("Value " .. currentValue .. " not found near method. Try a bigger range?")
        return
    end

    local results = gg.getResults(count)
    gg.toast("Found " .. count .. " candidates near method.")

    -- Step 3: Refine — do one air jump, value should increase
    gg.alert("Do ONE air jump (or trigger the check), then press OK.")
    gg.sleep(1000)

    local newValue = currentValue
    if currentValue > 0 then newValue = currentValue - 1 end -- or ask user
    local refineInput = gg.prompt({"What is the value NOW?"}, {newValue}, {"number"})
    if not refineInput then return end
    newValue = refineInput[1]

    gg.refineNumber(newValue, gg.TYPE_DWORD, false, false, startAddr, endAddr)
    results = gg.getResults(100)

    if #results == 0 then
        gg.alert("Refine failed. Try again.")
        return
    end

    -- Step 4: Freeze all candidates
    for i, v in ipairs(results) do
        v.value = FREEZE_VALUE
        v.freeze = true
    end
    gg.addListItems(results)

    -- Show offset from lib base
    local frozen = {}
    for i, v in ipairs(results) do
        local offset = v.address - libBase
        table.insert(frozen, string.format("0x%X", offset))
    end

    gg.alert(
        "FREEZE SUCCESS!\n\n" ..
        "Frozen " .. #results .. " address(es) to " .. FREEZE_VALUE .. "\n\n" ..
        "Offsets from libil2cpp.so:\n" .. table.concat(frozen, "\n") ..
        "\n\nSave to GG list for reuse!"
    )
end

-- Run
main()
