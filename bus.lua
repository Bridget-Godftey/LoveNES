require "bytestring"
ppu = require "PPU"

controler = require "controler"

gamepad1 = 0
gamepad2 = 0

AND = 4
bus = {}
local ffi = require("ffi")
--CPU can read/write to:
--RAM
--APU
--CONTROLER INPUT
--SOME BASIC SYSTEM STUFF
--PPU
bus.systemClockCounter = 0
bus.digitalScreen = love.graphics.newCanvas(256, 240)
--PPU AND CPU CAN READ/WRITE TO:
	--PATTERN MEMORY
	--PROGRAM ROM
	--MAPPER
bus.cycles = 0

bus.ppuNMI = false
bus.last = 0



local readCtrl = function (addr) end
local writeCtrl = function (addr, val) end
local OAMRead = function (addr) end
local OAMWrite = function (addr, value) end


bus.register = function (addr1, addr2, rd, wr, n)
	readCtrl = rd
	writeCtrl = wr
end



bus.register2 = function (addr1, addr2, rd, wr, n)
	OAMRead = rd
	OAMWrite = wr
end
require "PPU2"
require "cartridge"
bus.myCart = newCart("nestest.nes")
-- -- bus.cpuRam = {} --= ffi.new("uint8_t [8192]", {})
-- for i = 0, 8192 do
-- 	bus.cpuRam[i] = 0
-- end

bus.cpuRam = {}
for i = 0, 8192 do
	bus.cpuRam[i] = 0
end


bus.cpuRead = function (addr, readonly)
	readonly = readonly or false

	data = 0x00;
	if addr >= 0x0000 and addr <= 0x1FFF then
		data = bus.cpuRam[bit.band(addr, 0x07ff)]
	elseif addr >= 0x2000 and addr <= 0x3FFF then
		data = readCtrl(addr%8)
		--data = ppu.cpuRead(addr%8)
		bus.last = data
	--elseif addr == 0xFFFC or addr == 0xFFFD then
		--data = bus.cpuRam[addr]
	elseif addr == 0x4014 then
		OAMRead(addr)
	elseif addr >= 0x4016 and addr <= 0x4017 then
		if bit.band(gamepad1, 0x80) > 0 then data = 1 else data = 0 end
		gamepad1 = gamepad1 *2
	elseif addr >= 0x4020 then
		data = bus.myCart.cpuRead(addr, readonly)
	end
	return data
end
bus.cpuWrite = function (addr, val)
	if addr >= 0x0000 and addr <= 0x1FFF then
		bus.cpuRam[bit.band(addr, 0x07ff)] = val
	elseif addr >= 0x2000 and addr <= 0x3FFF then
		--ppu.cpuWrite(bit.band(addr, 0x0007), val)
		--readCtrl(bit.band(addr, 0x0007), val)
		writeCtrl(addr%8, val)
	--elseif addr == 0xFFFC or addr == 0xFFFD then
	--	bus.cpuRam[addr] = val
	elseif addr == 0x4014 then
		OAMWrite(addr, val)
	elseif addr >= 0x4016 and addr <= 0x4017 then
		gamepad1 = controler.readByte()
	elseif addr >= 0x4020 then
		bus.myCart.cpuWrite(addr, val)
	end
end

bus.insertCart = function (cartridge)
	bus.myCart = newCart(cartridge)
	ppu2.insertCart(bus.myCart)
	ppu.connectCartridge(bus.myCart)
end
bus.clock = function () 
	love.graphics.setCanvas(bus.digitalScreen)
	ppu.clock()
	ppu.clock()
	ppu.clock()
	bus.ppuNMI = ppu.nmi
		--if bus.systemClockCounter%3 == 0 then
	cpu.clock()
	ppu.nmi = bus.ppuNMI
	love.graphics.setCanvas()
end
bus.testPPU = function()
	ppu.clock()
end

bus.clockFrame = function () 
	bus.clockFrame2()
	----      print (bus.frameComplete())
	----local cnt = 0
	--love.graphics.setCanvas(bus.digitalScreen)
	--for n= 1, 7445 do
	--	ppu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	cpu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	cpu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	cpu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	ppu.clock()
	--	cpu.clock()
	--	--cnt = cnt + 1
	--	--if bus.systemClockCounter%3 == 0 then
	--    
	--	--bus.systemClockCounter = bus.systemClockCounter + 1
	--end
	--love.graphics.setCanvas()
	----print (cnt)
end

bus.drawPSHACK = function () 
	love.graphics.setCanvas(bus.digitalScreen)
	ppu.drawPSHACK() 
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(bus.digitalScreen, 0, 0, 0, 2, 2)
end

bus.clockFrame2 = function () 
	--print (bus.frameComplete())
	controler.getState()
	--local cnt = 0
	love.graphics.setCanvas(bus.digitalScreen)
	bus.cycles = 29781
	for i = 0,  29781 do
		--ppu.clock()
		--ppu.clock()
		--ppu.clock()
		ppu2.run()
		bus.cycles =  bus.cycles  - 1
		ppu2.run()
		bus.cycles =  bus.cycles  - 1
		ppu2.run()
		bus.cycles =  bus.cycles  - 1
		--ppu2.draw()
		--bus.ppuNMI = ppu.nmi
	    cpu.clock()
	    --ppu.nmi = bus.ppuNMI
		--bus.systemClockCounter = bus.systemClockCounter + 1
	end
    love.graphics.setCanvas()
    
	--return bus.digitalScreen
end


bus.clockFrame3 = function () 
	--print (bus.frameComplete())
	local cnt = 0
	love.graphics.setCanvas(bus.digitalScreen)
	while( not bus.frameComplete()) do
		ppu.clock()
		ppu.clock()
		ppu.clock()
		bus.ppuNMI = ppu.nmi
		--if bus.systemClockCounter%3 == 0 then
	    cpu.clock()
	    local op = cpu.getCurrentOp
	    --print("current opcode = ", op[1], op[2])

	    ppu.nmi = bus.ppuNMI
		--bus.systemClockCounter = bus.systemClockCounter + 1
	end
	love.graphics.setCanvas()
	return bus.digitalScreen
end

bus.reset = function () 
	bus.systemClockCounter = 0
end

bus.getPPUScreen = function ()
	return bus.digitalScreen
end

bus.frameComplete = function()
	return ppu.getFrameComplete()
end

bus.getPatternMemory = function (i, pal)
	return ppu.getPatternTables(i, pal)
end
bus.getNameTables = function ()
	return ppu2.getNameTables()
end
--testCode = {0xA2, 0x0A, 0x8E, 0x00, 0x00, 0xA2, 0x03, 0x8E, 0x01, 0x00, 0xAC, 0x00, 0x00, 0xA9, 0x00, 0x18, 0x6D, 0x01, 0x00, 0x88, 0xD0, 0xFA, 0x8D, 0x02, 0x00, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA, 0xEA}
bus.getSwatchFromPaletteRam = function (num)
	return ppu.getSwatchFromPaletteRam(num)
end
--nOffset = 0x0600

--for i= 0, table.getn(testCode)-1 do
--	bus.cpuWrite(nOffset+i, testCode[i])
--end
--bus.cpuWrite(0xFFFC, 0x00 ) 
--bus.cpuWrite(0xFFFD, 0x06 ) 

bus.lookup ={{ name = "BRK", execute = BRK, addressMode = "IMM", cycles = 7 },{ name = "ORA", execute = ORA, addressMode = "IZX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 3 },{ name = "ORA", execute = ORA, addressMode = "ZP0", cycles = 3 },{ name = "ASL", execute = ASL, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "PHP", execute = PHP, addressMode = "IMP", cycles = 3 },{ name = "ORA", execute = ORA, addressMode = "IMM", cycles = 2 },{ name = "ASL", execute = ASL, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "ORA", execute = ORA, addressMode = "ABS", cycles = 4 },{ name = "ASL", execute = ASL, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BPL", execute = BPL, addressMode = "REL", cycles = 2 },{ name = "ORA", execute = ORA, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "ORA", execute = ORA, addressMode = "ZPX", cycles = 4 },{ name = "ASL", execute = ASL, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "CLC", execute = CLC, addressMode = "IMP", cycles = 2 },{ name = "ORA", execute = ORA, addressMode = "ABY", cycles = 4 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "ORA", execute = ORA, addressMode = "ABX", cycles = 4 },{ name = "ASL", execute = ASL, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },
		  { name = "JSR", execute = JSR, addressMode = "ABS", cycles = 6 },{ name = "AND", execute = AND, addressMode = "IZX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "BIT", execute = BIT, addressMode = "ZP0", cycles = 3 },{ name = "AND", execute = AND, addressMode = "ZP0", cycles = 3 },{ name = "ROL", execute = ROL, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "PLP", execute = PLP, addressMode = "IMP", cycles = 4 },{ name = "AND", execute = AND, addressMode = "IMM", cycles = 2 },{ name = "ROL", execute = ROL, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "BIT", execute = BIT, addressMode = "ABS", cycles = 4 },{ name = "AND", execute = AND, addressMode = "ABS", cycles = 4 },{ name = "ROL", execute = ROL, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BMI", execute = BMI, addressMode = "REL", cycles = 2 },{ name = "AND", execute = AND, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "AND", execute = AND, addressMode = "ZPX", cycles = 4 },{ name = "ROL", execute = ROL, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "SEC", execute = SEC, addressMode = "IMP", cycles = 2 },{ name = "AND", execute = AND, addressMode = "ABY", cycles = 4 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "AND", execute = AND, addressMode = "ABX", cycles = 4 },{ name = "ROL", execute = ROL, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },
		  { name = "RTI", execute = RTI, addressMode = "IMP", cycles = 6 },{ name = "EOR", execute = EOR, addressMode = "IZX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 3 },{ name = "EOR", execute = EOR, addressMode = "ZP0", cycles = 3 },{ name = "LSR", execute = LSR, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "PHA", execute = PHA, addressMode = "IMP", cycles = 3 },{ name = "EOR", execute = EOR, addressMode = "IMM", cycles = 2 },{ name = "LSR", execute = LSR, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "JMP", execute = JMP, addressMode = "ABS", cycles = 3 },{ name = "EOR", execute = EOR, addressMode = "ABS", cycles = 4 },{ name = "LSR", execute = LSR, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BVC", execute = BVC, addressMode = "REL", cycles = 2 },{ name = "EOR", execute = EOR, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "EOR", execute = EOR, addressMode = "ZPX", cycles = 4 },{ name = "LSR", execute = LSR, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "CLI", execute = CLI, addressMode = "IMP", cycles = 2 },{ name = "EOR", execute = EOR, addressMode = "ABY", cycles = 4 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "EOR", execute = EOR, addressMode = "ABX", cycles = 4 },{ name = "LSR", execute = LSR, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },
		  { name = "RTS", execute = RTS, addressMode = "IMP", cycles = 6 },{ name = "ADC", execute = ADC, addressMode = "IZX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 3 },{ name = "ADC", execute = ADC, addressMode = "ZP0", cycles = 3 },{ name = "ROR", execute = ROR, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "PLA", execute = PLA, addressMode = "IMP", cycles = 4 },{ name = "ADC", execute = ADC, addressMode = "IMM", cycles = 2 },{ name = "ROR", execute = ROR, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "JMP", execute = JMP, addressMode = "IND", cycles = 5 },{ name = "ADC", execute = ADC, addressMode = "ABS", cycles = 4 },{ name = "ROR", execute = ROR, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BVS", execute = BVS, addressMode = "REL", cycles = 2 },{ name = "ADC", execute = ADC, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "ADC", execute = ADC, addressMode = "ZPX", cycles = 4 },{ name = "ROR", execute = ROR, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "SEI", execute = SEI, addressMode = "IMP", cycles = 2 },{ name = "ADC", execute = ADC, addressMode = "ABY", cycles = 4 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "ADC", execute = ADC, addressMode = "ABX", cycles = 4 },{ name = "ROR", execute = ROR, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },
		  { name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "STA", execute = STA, addressMode = "IZX", cycles = 6 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "STY", execute = STY, addressMode = "ZP0", cycles = 3 },{ name = "STA", execute = STA, addressMode = "ZP0", cycles = 3 },{ name = "STX", execute = STX, addressMode = "ZP0", cycles = 3 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 3 },{ name = "DEY", execute = DEY, addressMode = "IMP", cycles = 2 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "TXA", execute = TXA, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "STY", execute = STY, addressMode = "ABS", cycles = 4 },{ name = "STA", execute = STA, addressMode = "ABS", cycles = 4 },{ name = "STX", execute = STX, addressMode = "ABS", cycles = 4 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },
		  { name = "BCC", execute = BCC, addressMode = "REL", cycles = 2 },{ name = "STA", execute = STA, addressMode = "IZY", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "STY", execute = STY, addressMode = "ZPX", cycles = 4 },{ name = "STA", execute = STA, addressMode = "ZPX", cycles = 4 },{ name = "STX", execute = STX, addressMode = "ZPY", cycles = 4 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },{ name = "TYA", execute = TYA, addressMode = "IMP", cycles = 2 },{ name = "STA", execute = STA, addressMode = "ABY", cycles = 5 },{ name = "TXS", execute = TXS, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 5 },{ name = "STA", execute = STA, addressMode = "ABX", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },
		  { name = "LDY", execute = LDY, addressMode = "IMM", cycles = 2 },{ name = "LDA", execute = LDA, addressMode = "IZX", cycles = 6 },{ name = "LDX", execute = LDX, addressMode = "IMM", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "LDY", execute = LDY, addressMode = "ZP0", cycles = 3 },{ name = "LDA", execute = LDA, addressMode = "ZP0", cycles = 3 },{ name = "LDX", execute = LDX, addressMode = "ZP0", cycles = 3 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 3 },{ name = "TAY", execute = TAY, addressMode = "IMP", cycles = 2 },{ name = "LDA", execute = LDA, addressMode = "IMM", cycles = 2 },{ name = "TAX", execute = TAX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "LDY", execute = LDY, addressMode = "ABS", cycles = 4 },{ name = "LDA", execute = LDA, addressMode = "ABS", cycles = 4 },{ name = "LDX", execute = LDX, addressMode = "ABS", cycles = 4 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },
		  { name = "BCS", execute = BCS, addressMode = "REL", cycles = 2 },{ name = "LDA", execute = LDA, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "LDY", execute = LDY, addressMode = "ZPX", cycles = 4 },{ name = "LDA", execute = LDA, addressMode = "ZPX", cycles = 4 },{ name = "LDX", execute = LDX, addressMode = "ZPY", cycles = 4 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },{ name = "CLV", execute = CLV, addressMode = "IMP", cycles = 2 },{ name = "LDA", execute = LDA, addressMode = "ABY", cycles = 4 },{ name = "TSX", execute = TSX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },{ name = "LDY", execute = LDY, addressMode = "ABX", cycles = 4 },{ name = "LDA", execute = LDA, addressMode = "ABX", cycles = 4 },{ name = "LDX", execute = LDX, addressMode = "ABY", cycles = 4 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 4 },
		  { name = "CPY", execute = CPY, addressMode = "IMM", cycles = 2 },{ name = "CMP", execute = CMP, addressMode = "IZX", cycles = 6 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "CPY", execute = CPY, addressMode = "ZP0", cycles = 3 },{ name = "CMP", execute = CMP, addressMode = "ZP0", cycles = 3 },{ name = "DEC", execute = DEC, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "INY", execute = INY, addressMode = "IMP", cycles = 2 },{ name = "CMP", execute = CMP, addressMode = "IMM", cycles = 2 },{ name = "DEX", execute = DEX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "CPY", execute = CPY, addressMode = "ABS", cycles = 4 },{ name = "CMP", execute = CMP, addressMode = "ABS", cycles = 4 },{ name = "DEC", execute = DEC, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BNE", execute = BNE, addressMode = "REL", cycles = 2 },{ name = "CMP", execute = CMP, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "CMP", execute = CMP, addressMode = "ZPX", cycles = 4 },{ name = "DEC", execute = DEC, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "CLD", execute = CLD, addressMode = "IMP", cycles = 2 },{ name = "CMP", execute = CMP, addressMode = "ABY", cycles = 4 },{ name = "NOP", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "CMP", execute = CMP, addressMode = "ABX", cycles = 4 },{ name = "DEC", execute = DEC, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },
		  { name = "CPX", execute = CPX, addressMode = "IMM", cycles = 2 },{ name = "SBC", execute = SBC, addressMode = "IZX", cycles = 6 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "CPX", execute = CPX, addressMode = "ZP0", cycles = 3 },{ name = "SBC", execute = SBC, addressMode = "ZP0", cycles = 3 },{ name = "INC", execute = INC, addressMode = "ZP0", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 5 },{ name = "INX", execute = INX, addressMode = "IMP", cycles = 2 },{ name = "SBC", execute = SBC, addressMode = "IMM", cycles = 2 },{ name = "NOP", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = SBC, addressMode = "IMP", cycles = 2 },{ name = "CPX", execute = CPX, addressMode = "ABS", cycles = 4 },{ name = "SBC", execute = SBC, addressMode = "ABS", cycles = 4 },{ name = "INC", execute = INC, addressMode = "ABS", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },
		  { name = "BEQ", execute = BEQ, addressMode = "REL", cycles = 2 },{ name = "SBC", execute = SBC, addressMode = "IZY", cycles = 5 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 8 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "SBC", execute = SBC, addressMode = "ZPX", cycles = 4 },{ name = "INC", execute = INC, addressMode = "ZPX", cycles = 6 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 6 },{ name = "SED", execute = SED, addressMode = "IMP", cycles = 2 },{ name = "SBC", execute = SBC, addressMode = "ABY", cycles = 4 },{ name = "NOP", execute = NOP, addressMode = "IMP", cycles = 2 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 },{ name = "???", execute = NOP, addressMode = "IMP", cycles = 4 },{ name = "SBC", execute = SBC, addressMode = "ABX", cycles = 4 },{ name = "INC", execute = INC, addressMode = "ABX", cycles = 7 },{ name = "???", execute = XXX, addressMode = "IMP", cycles = 7 }}



bus.getDissassembly = function (lb, ub)
	i = lb
	at_addr = lb
	dissasssem = {}
	while i < ub do
		local tc = bus.cpuRead(i, true)
		local info = bus.lookup[tc+1]
		if info.addressMode == "IMP" then
			table.insert(dissasssem, {info.name, at_addr})
		elseif info.addressMode == "IMM" then
			immVal = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(immVal) == 1 then immVal = "0" .. immVal end
			table.insert(dissasssem, {info.name .. " 0x" .. immVal, at_addr})
			i = i + 1
			at_addr = at_addr +1
		elseif info.addressMode == "REL" then
			local addr_rel = bus.cpuRead(i+1, true)
			i = i + 1
			--local prefix = " "
			local jmpTo = at_addr + addr_rel
			if bit.band(addr_rel, 0x80) >= 1 then --Check if negative
				addr_rel = bit.bor(addr_rel, 0xFF00)
				--print(addr_rel)
				--addr_rel = i + addr_rel -1 
				--addr_rel = addr_rel%0x10000
				--prefix = " -"
				--jmpTo = at_addr - addr_rel
			end
			jmpTo = bit.band((at_addr+2 + addr_rel), 0xFFFF)
			jmpTo = string.format("%x", jmpTo)
			if string.len(jmpTo) == 3 then jmpTo = "0" .. jmpTo 
			elseif string.len(jmpTo) == 2 then jmpTo = "00" .. jmpTo
			elseif string.len(jmpTo) == 1 then jmpTo = "000" .. jmpTo end
			--string.format("%x", addr_rel) .. 
			table.insert(dissasssem, {info.name  .. "{" .. jmpTo .. "}", at_addr})
			at_addr = at_addr + 1
		elseif info.addressMode == "ZP0" then
			local addr_rel = bus.cpuRead(i+1, true)
			i = i + 1
			
			table.insert(dissasssem, {info.name .. " $" .. "00" .. string.format("%x", addr_rel), at_addr})
			at_addr = at_addr + 1
		elseif info.addressMode == "ABS" then
			local lo = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(lo) == 1 then lo = "0" .. lo end 
			i = i + 1
			--at_addr = at_addr + 1
			local hi = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(hi) == 1 then hi = "0" .. hi end 
			i = i + 1
			--at_addr = at_addr + 1
			table.insert(dissasssem, {info.name .. " $" .. hi .. lo, at_addr})
			at_addr = at_addr + 2
		elseif info.addressMode == "ZPX" or info.addressMode == "ZPY" then
			local foo = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(foo) == 1 then foo = "0" .. foo end
			i = i + 1
			local suffix = " X"
			if info.addressMode == "ZPY" then suffix = " Y" end
			table.insert(dissasssem, {info.name .. " " .. foo .. suffix, at_addr})
			at_addr = at_addr + 1
		elseif info.addressMode == "ABX" then
			local lo = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(lo) == 1 then lo = "0" .. lo end 
			i = i + 1
			--at_addr = at_addr + 1
			local hi = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(hi) == 1 then hi = "0" .. hi end 
			i = i + 1
			--at_addr = at_addr + 1
			table.insert(dissasssem, {info.name .. " $" .. hi .. lo .. "+X", at_addr})
			at_addr = at_addr + 2
		elseif info.addressMode == "ABY" then
			local lo = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(lo) == 1 then lo = "0" .. lo end 
			i = i + 1
			--at_addr = at_addr + 1
			local hi = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(hi) == 1 then hi = "0" .. hi end 
			i = i + 1
			--at_addr = at_addr + 1
			table.insert(dissasssem, {info.name .. " $" .. hi .. lo .. "+Y", at_addr})
			at_addr = at_addr + 2
		elseif info.addressMode == "IZX" then
			immVal = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(immVal) == 1 then immVal = "0" .. immVal end
			table.insert(dissasssem, {info.name .. " 0x" .. immVal, at_addr})
			i = i + 1
			at_addr = at_addr +1
		else
			immVal = string.format("%x", bus.cpuRead(i+1, true))
			if string.len(immVal) == 1 then immVal = "0" .. immVal end
			table.insert(dissasssem, {info.name .. " 0x" .. immVal, at_addr})
			i = i + 1
			at_addr = at_addr +1
		end
		at_addr = at_addr + 1
		i = i + 1
	end
	return dissasssem
end
