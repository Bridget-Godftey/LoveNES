require "bytestring"
--require "luabit/bit"
require "bus"
cpu = {}

lastPC = 0x0000
local _nz = 0x00

local bitand = function (a, b)
	--if b == 0x00ff then
	--	return a%256
	--end
	return bit.band(a, b) --bitoper(a, b, AND)
end

local bitor = function (a, b)
	return bit.bor(a, b) --bitoper(a, b, OR)
end

local bitxor = function (a, b)
	return bit.bxor(a, b)--bitoper(a, b, XOR)
end
local STACKPOINTERBASE = 0x0100


local function read(address, readonly)
	readonly = readonly or false
	return bus.cpuRead(address, readonlyy)
end

local function write(address, byte)
	--stub
	bus.cpuWrite(address, byte)
end

local function fetch()
	if impliedAddressingMode then
		
	else
		fetched = read(address_abs)
	end
	return fetched
end




local function btoi(str)
	outNum = 0
	for i = 1, string.len(str) do
		if string.sub(str, i, i) == "1" then
			outNum = outNum +  2^(string.len(str)-i)
		end
	end
	return outNum
end
local function itob(numI, bytes)
	bytes = bytes or 1
	num = numI
	bstring = ""
	
	for j = 1, 8*bytes do
		if num >= 1 then 
			bstring = tostring(num%2) .. bstring
			num = math.floor(num/2)
		else
			bstring = "0" .. bstring
		end
	end
	return bstring
end

local function shiftLeft(num, shift)
	return num * 2 ^ shift
end
local function shiftRight(num, shift)
	return math.floor(num / 2 ^ shift)
end
A = 0x00 -- accumulator 8 bit
X = 0x00 -- register 8 bit
Y = 0x00 -- register 8 bit
stkp =0x00-- stavck pointer (possibly 8 bits?)
pc = 0x0000 --program counter 16 bits
status = {} -- status register 8 bit word
status["C"] = "0"
status["Z"] = "0"
status["I"] = "0"
status["D"] = "0"
status["B"] = "0"
status["U"] = "0"
status["V"] = "0"
status["N"] = "0"
fetched = 0x00
address_abs = 0x0000
address_relative = 0x00
opcode = 0x00
cycles = 0x00
impliedAddressingMode = false

local function setStatus(num)
	if bit.band(0x01, num) > 0 then status["C"] = "1" else status["C"] = "0" end
	if bit.band(0x02, num) > 0 then status["Z"] = "1" else status["Z"] = "0" end
	if bit.band(0x04, num) > 0 then status["I"] = "1" else status["I"] = "0" end
	if bit.band(0x08, num) > 0 then status["D"] = "1" else status["D"] = "0" end
	if bit.band(0x10, num) > 0 then status["B"] = "1" else status["B"] = "0" end
	if bit.band(0x20, num) > 0 then status["U"] = "1" else status["U"] = "0" end
	if bit.band(0x40, num) > 0 then status["V"] = "1" else status["V"] = "0" end
	if bit.band(0x80, num) > 0 then status["N"] = "1" else status["N"] = "0" end
end
local function getStatus() 
	return "" .. status["C"] .. status["Z"] .. status["I"] .. status["D"] .. status["B"] .. status["U"] .. status["V"] .. status["N"]
end
--flags
local function getFlag(flag)
	return status[flag]
end

local function setFlag(flag, value)
	value = value or "0"
	if type(value) == "number" then
		value = value >= 1
	end

	if value == true then value = "1"
	elseif value == false then value = "0" end
	status[flag] = tostring(value)
end

--ADDRESSING_MODES
local function IMP() --Implied addressing Mode, no more data to read, probably using accumulator
	fetched = A 
	impliedAddressingMode = true
	return false
end
local function IMM() --Read data at the next address
	
	address_abs = pc
	pc = pc + 1
	return false
end
local function ZP0() -- zero page addressing, the first byte of an address is it's page, 
	address_abs = read(pc)
	pc = pc + 1
	address_abs = btoi(bitand(itob(address_abs, 2), itob( 0x00FF, 2)))
	return false
end
local function ZPX()  --zero page addressing with x as offset
	address_abs = (read(pc) + X)
	pc = pc + 1
	address_abs = btoi(bitand(itob(address_abs, 2), itob( 0x00FF, 2)))
	return false
end
local function ZPY()
	address_abs = (read(pc) + Y)
	pc = pc + 1
	address_abs = btoi(bitand(itob(address_abs, 2), itob( 0x00FF, 2)))
	return false
end
local function ABS() 
	lo = read (pc)
	pc = pc + 1
	hi = read (pc)
	pc = pc + 1

	--address_abs = btoi(itob(hi) .. itob(lo)) -- append the high byte to the low byte to get the full memory address
	address_abs = bitor(shiftLeft(hi, 8),  lo)
	return false
end
local function ABX() 
	lo = read (pc)
	pc = pc + 1
	hi = read (pc)
	pc = pc + 1

	address_abs = bitor(shiftLeft(hi, 8),  lo) -- append the high byte to the low byte to get the full memory address
	address_abs = (address_abs + X)%(2^16)
	if bitand(address_abs, 0xFF00) ~= shiftLeft(hi, 8) then --If after incrementing by X the address is on a new page, we might need an extra clock cycle
		return true
	else
		return false
	end
end
local function ABY() 
	lo = read (pc)
	pc = pc + 1
	hi = read (pc)
	pc = pc + 1

	address_abs = bitor(shiftLeft(hi, 8),  lo) -- append the high byte to the low byte to get the full memory address
	--address_abs = (address_abs + Y)%(2^16)
	if bitand(address_abs, 0xFF00) ~= shiftLeft(hi, 8) then--If after incrementing by Y the address is on a new page, we might need an extra clock cycle
		return true
	else
		return false
	end
end

local function IND() -- 6502 equivalent of pointers
	ptr_lo = read (pc)
	pc = pc + 1
	ptr_hi = read (pc)
	pc = pc + 1

	ptr = bitor(shiftLeft(ptr_hi, 8),  ptr_lo)

	-- this would be the intended functionality, but theres actually a bug in the hardware...
	--address_abs = bitor(shiftLeft(read(ptr+1), 8), read(ptr + 0))

	if ptr_lo == 0x00ff then --page boundary bug
		address_abs = bitor(shiftLeft(read(bitand(ptr, 0xFF00)), 8), read(ptr + 0))
	else -- behave normally
		address_abs = bitor(shiftLeft(read(ptr+1), 8), read(ptr + 0))
	end
	return false
end

local function IZX() 
	t = read(pc)
	pc = pc + 1

	local lo = read(bitand(t + X, 0x00FF))
	local hi = read(bitand(t + X + 1, 0x00FF))
	address_abs = bitor(shiftLeft(hi, 8),  lo)

	return false
end
local function IZY() 
	t = read(pc)
	pc = pc + 1

	local lo = read(bitand(t, 0x00FF))
	local hi = read(bitand(t + 1, 0x00FF))
	address_abs = bitor(shiftLeft(hi, 8),  lo)
	address_abs = address_abs + Y

	if bitand(address_abs, 0xFF00) ~= shiftLeft(hi, 8)  then
		return true
	else
		return false
	end
end

local function REL() 
	address_relative = read(pc)
	pc = pc + 1
	if bitand(address_relative, 0x80) >= 1 then --Check if negative
		address_relative = bitor(address_relative, 0xFF00)
	end
	return false
end




--OPCODES AS local FUNCTIONS

local function  AND() 
	fetch()
	A = bitand(A, fetched)
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return true
end	
local function  BCC() 
	if getFlag("C") == "0" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false

end
local function  BCS() 
	if getFlag("C") == "1" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false

end	
local function  BEQ() 
	if getFlag("Z") == "1" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false
end	
local function  BMI() 
	if getFlag("N") == "1" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false
end
local function  BNE() 
	if getFlag("Z") == "0" then

		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end
		pc = bitand(address_abs, 0xFFFF)
		address_abs = pc
		--print ("branching to", address_abs)
		
	end
	return false
end	
local function  BPL() 
	if getFlag("N") == "0" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false
end	
	
local function  BVC() 
	if getFlag("V") == "0" then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false
end
local function  BVS()
	if getFlag("V") == "1" then
	cycles = cycles + 1
	address_abs = pc + address_relative
	if bitand(address_abs, 0xff00) ~= bitand(pc, 0xff00) then
		cycles = cycles + 1
	end

	pc = address_abs
	end
	return false
end
local function  CLC() 
	setFlag("C", false)
	return false
end	
local function  ADC()
	fetch()
	result = A + fetched + tonumber(getFlag("C"))
	setFlag("C", result > 255)
	setFlag("Z", bitand(result, 0x00ff) == 0)
	setFlag("N", bitand(A, 0x80))
	mostSigA = bit.bxor(A, 128) == 128
	mostSigM = bit.bxor(fetched, 128) == 128
	mostSigR = bit.bxor(result, 128) == 128
	setFlag("V", ((mostSigA == mostSigM) and (mostSigA ~= mostSigR)))
	A = bitand(result, 0x00FF)
	return true
end
local function  SBC()
	fetch()
	value = bit.bxor(fetched, 0x00ff)
	result = A + value + tonumber(getFlag("C"))
	setFlag("C", result > 255)
	setFlag("Z", bitand(result, 0x00ff) == 0)
	setFlag("N", bitand(A, 0x80))
	mostSigA = bit.bxor(A, 128) == 128
	mostSigM = bit.bxor(mem, 128) == 128
	mostSigR = bit.bxor(result, 128) == 128
	setFlag("V", ((mostSigA == mostSigM) and (mostSigA ~= mostSigR)))
	A = bitand(result, 0x00FF)
	return true
end


local function  CLD() 
	setFlag("D", false)
	return false
end		
local function  CLI() 
	setFlag("I", false)
	return false
end	
local function  CLV() 
	setFlag("V", false)
	return false
end		

local function  PHA() 
	write(STACKPOINTERBASE + stkp, A)
	stkp = stkp - 1
	return false
end
local function  PLA() 
	stkp = stkp + 1
	A = read(STACKPOINTERBASE + stkp)
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return false
end


local function  ASL() 
	fetch();
	temp = shiftLeft(fetched, 1)
	setFlag("C", bitand(temp, 0xFF00) > 0)
	setFlag("Z", bitand(temp , 0x00FF) == 0x00)
	setFlag("N", bitand(temp , 0x80))
	if impliedAddressingMode then
		A = bitand(temp, 0x00FF)
	else
		write(addr_abs, bitand(temp, 0x00FF))
	end
	return false
end	
local function  BIT() 

	fetch()
	temp = bitand(A , fetched)
	setFlag("Z", bitand(temp , 0x00FF) == 0x00)
	setFlag("N", bitand(fetched , shiftLeft(1, 7)))
	setFlag("V", bitand(fetched , shiftLeft(1, 6)))
	return false
end
local function  BRK() 
	pc = pc + 1
	
	setFlag("I", 1)
	write(STACKPOINTERBASE + stkp, bitand(math.floor(shiftRight(pc, 8)), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp,  bitand(pc, 0x00FF))
	stkp = stkp - 1

	setFlag("B", 1)
	write(STACKPOINTERBASE + stkp, getStatus())
	stkp = stkp - 1
	setFlag("B", 0)

	pc = bitor(read(0xFFFE), shiftLeft(read(0xFFFF), 8))
	return false;
end
local function  CMP() 
	fetch()
	temp = A - fetched
	setFlag("C", A >= fetched)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return true
end	
local function  CPX()
	fetch()
	temp = X - fetched
	setFlag("C", X >= fetched)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end
local function  CPY()
	fetch()
	temp = Y - fetched
	setFlag("C", Y >= fetched)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end
local function  DEC() 
	fetch()
	temp = fetched - 1
	if fetched == 0 then
		temp = 255
	end
	if temp >= 256 then temp = temp%256 end
	write (address_abs, temp)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end
local function  DEX() 
	X = bitand(X-1 , 0x00FF)
	setFlag("Z", X == 0)
	setFlag("N", bitand(X , 0x0080) >= 1)
	return false
end	
local function  DEY() 
	Y = bitand(Y-1 , 0x00FF)
	setFlag("Z", Y == 0)
	setFlag("N", bitand(Y , 0x0080) >= 1)
	return false
end		
local function  EOR()
	fetch()
	A = bit.xor(A, fetched)
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return true
end

local function  INC()
	fetch()
	temp = fetched + 1
	if fetched == 255 then
		temp = 0
	end
	if temp >= 256 then temp = temp%256 end
	write (address_abs, temp)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end
local function  INX()
	temp = X + 1
	if X == 255 then
		temp = 0
	end
	if temp >= 256 then temp = temp%256 end
	X = temp
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end		
local function  INY()
	temp = Y + 1
	if Y == 255 then
		temp = 0
	end
	if temp >= 256 then temp = temp%256 end
	Y = temp
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	return false
end		

local function  JMP()
	pc = address_abs
	return false
end
local function  JSR() 
	pc = pc -1
	write(STACKPOINTERBASE + stkp, bitand(shiftRight(pc, 8), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp, bitand(pc, 0x00FF))
	stkp = stkp - 1
	pc = address_abs
	return false
end	
local function  LDA() 
	fetch()
	A = fetched
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A , 0x80))
	return true
end	
local function  LDX() 
	fetch()
	X = fetched
	setFlag("Z", X == 0x00)
	setFlag("N", bitand(X , 0x80))
	return true
end	
local function  LDY() 
	fetch()
	Y = fetched
	setFlag("Z", Y == 0x00)
	setFlag("N", bitand(Y , 0x80))
	return true
end	

local function  LSR() 
	fetch()
	setFlag("C", bitand(fetched, 0x0001))
	temp = shiftRight(fetched, 1)
	setFlag("Z", bitand(temp , 0x00FF) == 0x0000)
	setFlag("N", bitand(temp , 0x0080) > 0)
	if impliedAddressingMode then
		A = bitand(temp, 0x00FF)
	else
		write(addr_abs, bitand(temp, 0x00FF))
	end
	return 0;
end	
local function  NOP() 
	if opcode == 0xFC then return true
	else return false end
end	
local function  ORA()
	fetch()
	A = bitor(A, fetched)
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return true
end
local function  PHP() 
	write(STACKPOINTERBASE + stkp, bitor(bitor(status, tonumber(getFlag("B"))), tonumber(getFlag("U"))))
	setFlag("B", 0)
	setFlag("U", 0)
	stkp = stkp - 1
	return false
end

local function  PLP() 
	setStatus(read(STACKPOINTERBASE + stkp))
	setFlag("U", 1)
	return false
end	
local function  ROL() 
	fetch()
	temp = bitor(leftShift(fetched, 1), tonumber(getFlag("C")))
	setFlag("C", bitand(temp, 0xFF00))
	setFlag("Z", bitand(temp, 0x00FF) == 0)
	setFlag("N", bitand(temp, 0x0080))
	if impliedAddressingMode then
		A = bitand(temp, 0x00ff)
	else
		write(address_abs, bitand(temp, 0x00ff))
	end
	return false

end
local function  ROR()
	fetch()
	temp = bitor(leftShift(fetched, 7), rightShift(fetched, 1))
	setFlag("C", bitand(temp, 0x01))
	setFlag("Z", bitand(temp, 0x00FF) == 0)
	setFlag("N", bitand(temp, 0x0080))
	if impliedAddressingMode then
		A = bitand(temp, 0x00ff)
	else
		write(address_abs, bitand(temp, 0x00ff))
	end
	return false
end
local function  RTI() 
	stkp = stkp + 1
	setStatus(read(STACKPOINTERBASE + stkp))

	setStatus(bitand(getStatus(), bit.bnot(tonumber(getFlag("B"), 2))))
	setStatus(bitand(getStatus(), bit.bnot(tonumber(getFlag("U"), 2))))
	stkp = stkp + 1
	lo = read(STACKPOINTERBASE + stkp)
	stkp = stkp + 1
	hi = read(STACKPOINTERBASE + stkp)
	pc = bitor(shiftLeft(hi, 8),  lo)
	return false
end	
local function  RTS()
	stkp = stkp + 1
	lo = read(STACKPOINTERBASE + stkp)
	stkp = stkp + 1
	hi = read(STACKPOINTERBASE + stkp)
	pc = bitor(shiftLeft(hi, 8),  lo)
	pc = pc + 1
	return false
end	
local function  SEC() 
	setFlag("C", true)
	return false
end
local function  SED()  
	setFlag("D", true)
	return false
end	
local function  SEI()  
	setFlag("I", true)
	return false
end
local function  STA()
	write(address_abs, A)
	return false
end
local function  STX() 
	write(address_abs, X)
	return false
end	
local function  STY() 
	write(address_abs, Y)
	return false
end
local function  TAX()
	X = A
	setFlag("Z", X == 0x00)
	setFlag("N", bitand(X, 0x80))
	return false
end
local function  TAY()
	Y = A
	setFlag("Z", Y == 0x00)
	setFlag("N", bitand(Y, 0x80))
	return false
end
local function  TSX() 
	X = stkp
	setFlag("Z", X == 0x00)
	setFlag("N", bitand(X, 0x80))
	return false
end	
local function  TXA() 
	A = X
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return false
end	
local function  TXS() 
	stkp = X
	return false
end	
local function  TYA() 
	A = Y
	setFlag("Z", A == 0x00)
	setFlag("N", bitand(A, 0x80))
	return false
end

local function XXX() 
	return false
end --FOR ILLEGAL OPCODES








LOOKUP  ={{ name = "BRK", execute = BRK, addressMode = IMM, cycles = 7 },{ name = "ORA", execute = ORA, addressMode = IZX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 3 },{ name = "ORA", execute = ORA, addressMode = ZP0, cycles = 3 },{ name = "ASL", execute = ASL, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "PHP", execute = PHP, addressMode = IMP, cycles = 3 },{ name = "ORA", execute = ORA, addressMode = IMM, cycles = 2 },{ name = "ASL", execute = ASL, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "ORA", execute = ORA, addressMode = ABS, cycles = 4 },{ name = "ASL", execute = ASL, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BPL", execute = BPL, addressMode = REL, cycles = 2 },{ name = "ORA", execute = ORA, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "ORA", execute = ORA, addressMode = ZPX, cycles = 4 },{ name = "ASL", execute = ASL, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "CLC", execute = CLC, addressMode = IMP, cycles = 2 },{ name = "ORA", execute = ORA, addressMode = ABY, cycles = 4 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "ORA", execute = ORA, addressMode = ABX, cycles = 4 },{ name = "ASL", execute = ASL, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },
		  { name = "JSR", execute = JSR, addressMode = ABS, cycles = 6 },{ name = "AND", execute = AND, addressMode = IZX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "BIT", execute = BIT, addressMode = ZP0, cycles = 3 },{ name = "AND", execute = AND, addressMode = ZP0, cycles = 3 },{ name = "ROL", execute = ROL, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "PLP", execute = PLP, addressMode = IMP, cycles = 4 },{ name = "AND", execute = AND, addressMode = IMM, cycles = 2 },{ name = "ROL", execute = ROL, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "BIT", execute = BIT, addressMode = ABS, cycles = 4 },{ name = "AND", execute = AND, addressMode = ABS, cycles = 4 },{ name = "ROL", execute = ROL, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BMI", execute = BMI, addressMode = REL, cycles = 2 },{ name = "AND", execute = AND, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "AND", execute = AND, addressMode = ZPX, cycles = 4 },{ name = "ROL", execute = ROL, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "SEC", execute = SEC, addressMode = IMP, cycles = 2 },{ name = "AND", execute = AND, addressMode = ABY, cycles = 4 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "AND", execute = AND, addressMode = ABX, cycles = 4 },{ name = "ROL", execute = ROL, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },
		  { name = "RTI", execute = RTI, addressMode = IMP, cycles = 6 },{ name = "EOR", execute = EOR, addressMode = IZX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 3 },{ name = "EOR", execute = EOR, addressMode = ZP0, cycles = 3 },{ name = "LSR", execute = LSR, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "PHA", execute = PHA, addressMode = IMP, cycles = 3 },{ name = "EOR", execute = EOR, addressMode = IMM, cycles = 2 },{ name = "LSR", execute = LSR, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "JMP", execute = JMP, addressMode = ABS, cycles = 3 },{ name = "EOR", execute = EOR, addressMode = ABS, cycles = 4 },{ name = "LSR", execute = LSR, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BVC", execute = BVC, addressMode = REL, cycles = 2 },{ name = "EOR", execute = EOR, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "EOR", execute = EOR, addressMode = ZPX, cycles = 4 },{ name = "LSR", execute = LSR, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "CLI", execute = CLI, addressMode = IMP, cycles = 2 },{ name = "EOR", execute = EOR, addressMode = ABY, cycles = 4 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "EOR", execute = EOR, addressMode = ABX, cycles = 4 },{ name = "LSR", execute = LSR, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },
		  { name = "RTS", execute = RTS, addressMode = IMP, cycles = 6 },{ name = "ADC", execute = ADC, addressMode = IZX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 3 },{ name = "ADC", execute = ADC, addressMode = ZP0, cycles = 3 },{ name = "ROR", execute = ROR, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "PLA", execute = PLA, addressMode = IMP, cycles = 4 },{ name = "ADC", execute = ADC, addressMode = IMM, cycles = 2 },{ name = "ROR", execute = ROR, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "JMP", execute = JMP, addressMode = IND, cycles = 5 },{ name = "ADC", execute = ADC, addressMode = ABS, cycles = 4 },{ name = "ROR", execute = ROR, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BVS", execute = BVS, addressMode = REL, cycles = 2 },{ name = "ADC", execute = ADC, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "ADC", execute = ADC, addressMode = ZPX, cycles = 4 },{ name = "ROR", execute = ROR, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "SEI", execute = SEI, addressMode = IMP, cycles = 2 },{ name = "ADC", execute = ADC, addressMode = ABY, cycles = 4 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "ADC", execute = ADC, addressMode = ABX, cycles = 4 },{ name = "ROR", execute = ROR, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },
		  { name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "STA", execute = STA, addressMode = IZX, cycles = 6 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "STY", execute = STY, addressMode = ZP0, cycles = 3 },{ name = "STA", execute = STA, addressMode = ZP0, cycles = 3 },{ name = "STX", execute = STX, addressMode = ZP0, cycles = 3 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 3 },{ name = "DEY", execute = DEY, addressMode = IMP, cycles = 2 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "TXA", execute = TXA, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "STY", execute = STY, addressMode = ABS, cycles = 4 },{ name = "STA", execute = STA, addressMode = ABS, cycles = 4 },{ name = "STX", execute = STX, addressMode = ABS, cycles = 4 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },
		  { name = "BCC", execute = BCC, addressMode = REL, cycles = 2 },{ name = "STA", execute = STA, addressMode = IZY, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "STY", execute = STY, addressMode = ZPX, cycles = 4 },{ name = "STA", execute = STA, addressMode = ZPX, cycles = 4 },{ name = "STX", execute = STX, addressMode = ZPY, cycles = 4 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },{ name = "TYA", execute = TYA, addressMode = IMP, cycles = 2 },{ name = "STA", execute = STA, addressMode = ABY, cycles = 5 },{ name = "TXS", execute = TXS, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 5 },{ name = "STA", execute = STA, addressMode = ABX, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },
		  { name = "LDY", execute = LDY, addressMode = IMM, cycles = 2 },{ name = "LDA", execute = LDA, addressMode = IZX, cycles = 6 },{ name = "LDX", execute = LDX, addressMode = IMM, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "LDY", execute = LDY, addressMode = ZP0, cycles = 3 },{ name = "LDA", execute = LDA, addressMode = ZP0, cycles = 3 },{ name = "LDX", execute = LDX, addressMode = ZP0, cycles = 3 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 3 },{ name = "TAY", execute = TAY, addressMode = IMP, cycles = 2 },{ name = "LDA", execute = LDA, addressMode = IMM, cycles = 2 },{ name = "TAX", execute = TAX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "LDY", execute = LDY, addressMode = ABS, cycles = 4 },{ name = "LDA", execute = LDA, addressMode = ABS, cycles = 4 },{ name = "LDX", execute = LDX, addressMode = ABS, cycles = 4 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },
		  { name = "BCS", execute = BCS, addressMode = REL, cycles = 2 },{ name = "LDA", execute = LDA, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "LDY", execute = LDY, addressMode = ZPX, cycles = 4 },{ name = "LDA", execute = LDA, addressMode = ZPX, cycles = 4 },{ name = "LDX", execute = LDX, addressMode = ZPY, cycles = 4 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },{ name = "CLV", execute = CLV, addressMode = IMP, cycles = 2 },{ name = "LDA", execute = LDA, addressMode = ABY, cycles = 4 },{ name = "TSX", execute = TSX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },{ name = "LDY", execute = LDY, addressMode = ABX, cycles = 4 },{ name = "LDA", execute = LDA, addressMode = ABX, cycles = 4 },{ name = "LDX", execute = LDX, addressMode = ABY, cycles = 4 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 4 },
		  { name = "CPY", execute = CPY, addressMode = IMM, cycles = 2 },{ name = "CMP", execute = CMP, addressMode = IZX, cycles = 6 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "CPY", execute = CPY, addressMode = ZP0, cycles = 3 },{ name = "CMP", execute = CMP, addressMode = ZP0, cycles = 3 },{ name = "DEC", execute = DEC, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "INY", execute = INY, addressMode = IMP, cycles = 2 },{ name = "CMP", execute = CMP, addressMode = IMM, cycles = 2 },{ name = "DEX", execute = DEX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "CPY", execute = CPY, addressMode = ABS, cycles = 4 },{ name = "CMP", execute = CMP, addressMode = ABS, cycles = 4 },{ name = "DEC", execute = DEC, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BNE", execute = BNE, addressMode = REL, cycles = 2 },{ name = "CMP", execute = CMP, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "CMP", execute = CMP, addressMode = ZPX, cycles = 4 },{ name = "DEC", execute = DEC, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "CLD", execute = CLD, addressMode = IMP, cycles = 2 },{ name = "CMP", execute = CMP, addressMode = ABY, cycles = 4 },{ name = "NOP", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "CMP", execute = CMP, addressMode = ABX, cycles = 4 },{ name = "DEC", execute = DEC, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },
		  { name = "CPX", execute = CPX, addressMode = IMM, cycles = 2 },{ name = "SBC", execute = SBC, addressMode = IZX, cycles = 6 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "CPX", execute = CPX, addressMode = ZP0, cycles = 3 },{ name = "SBC", execute = SBC, addressMode = ZP0, cycles = 3 },{ name = "INC", execute = INC, addressMode = ZP0, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 5 },{ name = "INX", execute = INX, addressMode = IMP, cycles = 2 },{ name = "SBC", execute = SBC, addressMode = IMM, cycles = 2 },{ name = "NOP", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = SBC, addressMode = IMP, cycles = 2 },{ name = "CPX", execute = CPX, addressMode = ABS, cycles = 4 },{ name = "SBC", execute = SBC, addressMode = ABS, cycles = 4 },{ name = "INC", execute = INC, addressMode = ABS, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },
		  { name = "BEQ", execute = BEQ, addressMode = REL, cycles = 2 },{ name = "SBC", execute = SBC, addressMode = IZY, cycles = 5 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 8 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "SBC", execute = SBC, addressMode = ZPX, cycles = 4 },{ name = "INC", execute = INC, addressMode = ZPX, cycles = 6 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 6 },{ name = "SED", execute = SED, addressMode = IMP, cycles = 2 },{ name = "SBC", execute = SBC, addressMode = ABY, cycles = 4 },{ name = "NOP", execute = NOP, addressMode = IMP, cycles = 2 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 },{ name = "???", execute = NOP, addressMode = IMP, cycles = 4 },{ name = "SBC", execute = SBC, addressMode = ABX, cycles = 4 },{ name = "INC", execute = INC, addressMode = ABX, cycles = 7 },{ name = "???", execute = XXX, addressMode = IMP, cycles = 7 }}




local function fetchExecuteCycle()
	--read byte @ PC
	lastPC = pc
	fb = read(pc)
	pc = (pc + 1)%0x10000
	--opcode[byte] --> addressing mode, num cycles
	opcode = fb
	--print(string.format("%x",opcode), LOOKUP[fb+1].name, string.format("%x", pc) )
	command  = LOOKUP[fb+1]
	--command.execute()
	cycles = command.cycles
	--read N more bytes
	additionalCycle1 = command.addressMode()
	-- execute
	additionalCycle2 = command.execute()
	if additionalCycle1 and additionalCycle2 then
		cycles = cycles + 1
	end

	impliedAddressingMode = false
	--wait for C cycles

end

local function clock(dt)
	if cycles == 0 then
		fetchExecuteCycle()
	end
	cycles = cycles - 1
end


local function reset()
	A = 0
	X = 0
	Y = 0
	stkp = 0xFD
	status = {} -- status register 8 bit word
    status["C"] = "0"
    status["Z"] = "0"
    status["I"] = "0"
    status["D"] = "0"
    status["B"] = "0"
    status["U"] = "0"
    status["V"] = "0"
    status["N"] = "0"

	address_abs = 0xFFFC
	lo = read(address_abs + 0)
	hi = read(address_abs + 1)

	pc = bitor(shiftLeft(hi, 8),  lo)
	--pc = 0x8000
	address_abs = 0
	address_relative = 0
	fetched = 0

	cycles = 8
end -- interrupts and resets
local function irq() 

	if getFlag("I") == "0" then
		-- write program counter to the stack
		write(STACKPOINTERBASE + stkp, bitand(rightShift(pc, 8), 0x00FF))
		stkp = stkp - 1
		write(STACKPOINTERBASE + stkp, bitand(pc, 0x00FF))
		stkp = stkp - 1
		--store status
		setFlag("B", "0")
		setFlag("U", "1")
		setFlag("I", "1")
		write(STACKPOINTERBASE + stkp, btoi(status))
		stkp = stkp - 1
		--jump to location at address FFFE
		address_abs = 0xfffe
		lo = read(address_abs + 0)
		hi = read(address_abs + 1)
		pc = bitor(shiftLeft(hi, 8),  lo)

		cycles = 7
	end
		

end -- interrupt request, can be ignored
local function nml() 
	-- write program counter to the stack
	write(STACKPOINTERBASE + stkp, bitand(rightShift(pc, 8), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp, bitand(pc, 0x00FF))
	stkp = stkp - 1
	--store status
	setFlag("B", "0")
	setFlag("U", "1")
	setFlag("I", "1")
	write(STACKPOINTERBASE + stkp, btoi(status))
	stkp = stkp - 1
	--jump to location at address FFFA
	address_abs = 0xfffa
	lo = read(address_abs + 0)
	hi = read(address_abs + 1)
	pc = bitor(shiftLeft(hi, 8),  lo)

	cycles = 8

end -- nonMaskable interrupt


local function printA()
	print(opcode)
	--print(LOOKUP[opcode+1])
	love.graphics.print(tostring(A) .. " " .. LOOKUP[opcode+1].name, 100, 300)
end


local function getPC()
	return pc
end
local function getLastPC()
	return lastPC
end
local function getA()
	return A
end
local function getX()
	return X
end
local function getY()
	return Y
end

local function getCurrentOp()
	return LOOKUP[opcode+1].name
end


cpu = {btoi = btoi,
 A =  A,
 X =  X,
 Y =  Y,
 getPC = getPC,
 getLastPC = getLastPC,
 printA = printA,
 status =  status,
 stkp =  stkp,
 itob =  itob,
 shiftLeft =  shiftLeft,
 shiftRight =  shiftRight,
 getFlag =  getFlag,
 setFlag =  setFlag,
 IMP = IMP, --Implied addressing Mode, no more data to read, probably using accumulator =  IMP --Implied addressing Mode, no more data to read, probably using accumulator,
 IMM  =  IMM,
 ZP0 =  ZP0,
 ZPX  =  ZPX ,
 ZPY =  ZPY,
 ABS  =  ABS ,
 ABX  =  ABX ,
 ABY  =  ABY ,
 IND = IND,-- 6502 equivalent of pointers =  IND -- 6502 equivalent of pointers,
 IZX  =  IZX ,
 IZY  =  IZY ,
 REL =  REL,
 read =  read,
 write =  write,
 fetch =  fetch,
  AND  =   AND ,
  BCC  =   BCC ,
  BCS  =   BCS ,
  BEQ  =   BEQ ,
  BMI  =   BMI ,
  BNE  =   BNE ,
  BPL  =   BPL ,
  BVC  =   BVC ,
  BVS =   BVS,
  CLC  =   CLC ,
  ADC =   ADC,
  SBC =   SBC,
  CLD  =   CLD ,
  CLI  =   CLI ,
  CLV  =   CLV ,
  PHA  =   PHA ,
  PLA  =   PLA ,
  ASL  =   ASL ,
  BIT  =   BIT ,
  BRK  =   BRK ,
  CMP  =   CMP ,
  CPX =   CPX,
  CPY =   CPY,
  DEC  =   DEC ,
  DEX  =   DEX ,
  DEY  =   DEY ,
  EOR =   EOR,
  INC =   INC,
  INX =   INX,
  INY =   INY,
  JMP =   JMP,
  JSR  =   JSR ,
  LDA  =   LDA ,
  LDX  =   LDX ,
  LDY  =   LDY ,
  LSR  =   LSR ,
  NOP  =   NOP ,
  ORA =   ORA,
  PHP  =   PHP ,
  PLP  =   PLP ,
  ROL  =   ROL ,
  ROR =   ROR,
  RTI  =   RTI ,
  RTS =   RTS,
  SEC  =   SEC ,
  SED   =   SED  ,
  SEI   =   SEI  ,
  STA =   STA,
  STX  =   STX ,
  STY  =   STY ,
  TAX =   TAX,
  TAY =   TAY,
  TSX  =   TSX ,
  TXA  =   TXA ,
  TXS  =   TXS ,
  TYA  =   TYA ,
 XXX  =  XXX ,
 fetchExecuteCycle =  fetchExecuteCycle,
 clock =  clock,
 reset =  reset,
 irq  =  irq ,
 nml  =  nml,
 debugClock = fetchExecuteCycle,
 getCurrentOp = getCurrentOp,
 getA = getA, 
 getX = getX,
 getY = getY
 }
