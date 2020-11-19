local out = assert(io.open("test.nes", "wb"))
F = ""
Q = {}
local function addToF(stuff)
	F = F .. stuff
	table.insert(Q, string.byte(stuff))
end
addToF( "N")
addToF( "E")
addToF( "S")
addToF(string.char(0x1a))

addToF(string.char(1))
addToF(string.char(1))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))
addToF(string.char(0))


local prg = {}
for i= 0, 16384 do -- fill PRGBanks
	prg[i] = (string.char(0))
end
local testCode = {0xA2, 0x0A, 0x8E, 0x00, 0x00, 0xA2, 0x03, 0x8E, 0x01, 0x00, 0xAC, 0x00, 0x00, 0xA9, 0x00, 0x18, 0x6D, 0x01, 0x00, 0x88, 0xD0, 0xFA, 0x8D, 0x02, 0x00, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA}

nOffset = 0x8000

for i= 0, table.getn(testCode)-1 do
	prg[i] =  string.char(testCode[i+1])
end

prg[0x3FFC] = string.char(0x00)
prg[0x3FFD] = string.char(0x80)
for i= 0, 16384 do -- fill PRGBanks
	addToF(prg[i])
end

for i= 0, 8192 do --fill CHRBanks
	addToF(string.char(0))
end
for i = 1, table.getn(Q) do
	foo =  string.format("%x", Q[i])
	bar =  string.format("%x", string.byte(F, i))
	if i == 0x3FFD + 15 then bar = bar .. "<=========================================" end
	if string.len(foo) == 1 then foo = "0" .. foo end
	foo = tostring(i) .. ": " .. foo
	print(foo .. " " .. bar)
end
out:write(F)
out:close()