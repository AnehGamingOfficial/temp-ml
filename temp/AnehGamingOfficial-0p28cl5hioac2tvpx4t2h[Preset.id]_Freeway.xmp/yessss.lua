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
