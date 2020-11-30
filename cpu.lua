require "bus"
local ffi = require("ffi")
cpu = {}


local bnot =  bit.bnot
local band, bor, bxor =  bit.band,  bit.bor,  bit.bxor
local lshift, rshift, rol =  bit.lshift,  bit.rshift, bit.rol

local cpustatus =[[ typedef union {
    struct
      {

      	uint8_t C: 1;
		uint8_t Z: 1;
		uint8_t I: 1;
		uint8_t D: 1;
		uint8_t B: 1;
		uint8_t U: 1;
		uint8_t V: 1;
		uint8_t N: 1;

      } flag;
      unsigned __int8 reg;
        
}statuss_register;]]

ffi.cdef(cpustatus)
status = ffi.new("statuss_register")

lastPC = 0x0000
local _nz = 0x00

local band = function (a, b)
	--if b == 0x00ff then
	--	return a%256
	--end
	return band(a, b) --bitoper(a, b, AND)
end

local bor = function (a, b)
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
	bus.cpuWrite(address, band(byte, 0xFF))
end

local function fetch()
	if impliedAddressingMode then
		
	else
		fetched = read(address_abs)
	end
	return band(fetched, 0xFF)
end




local function btoi(str)
	outNum = 0
	for i = 1, string.len(str) do
		if string.sub(str, i, i) == 1 then
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
			bstring = 0 .. bstring
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
fetched = 0x00
address_abs = 0x0000
address_relative = 0x00
opcode = 0x00
cycles = 0x00
impliedAddressingMode = false


--flags

local function getFlag(f)
	if f == "N" then  return  status.flag.N end
	if f == "V" then  return  status.flag.V end
	if f == "U" then  return  status.flag.U end
	if f == "B" then  return  status.flag.B end
	if f == "D" then  return  status.flag.D end
	if f == "I" then  return  status.flag.I end
	if f == "Z" then  return  status.flag.Z end
 	if f == "C" then  return  status.flag.C end
end


local function setFlag(f, value)
	value = value or 0
	if type(value) == "number" then
		if value == 0 then value = false else value = true end
	end

	if value == true then value = 1
	elseif value == false then value = 0 else value = tonumber(value) end

	if f == "N" then status.flag.N = value 
	elseif f == "V" then status.flag.V = value 
	elseif f == "U" then status.flag.U = value 
	elseif f == "B" then status.flag.B = value
	elseif f == "D" then status.flag.D = value
	elseif f == "I" then status.flag.I = value
	elseif f == "Z" then status.flag.Z = value
 	elseif f == "C" then status.flag.C = value end

	--status[flag] = tostring(value)
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
	--address_abs = btoi(band(itob(address_abs, 2), itob( 0x00FF, 2)))
	return false
end
local function ZPX()  --zero page addressing with x as offset
	address_abs = (read(pc) + X)
	pc = pc + 1
	address_abs = band(address_abs, 0x00FF)
	return false
end
local function ZPY()
	address_abs = (read(pc) + Y)
	pc = pc + 1
	address_abs = band(address_abs,  0x00FF)
	return false
end
local function ABS() 
	lo = read (pc)
	pc = pc + 1
	hi = read (pc)
	pc = pc + 1

	--address_abs = btoi(itob(hi) .. itob(lo)) -- append the high byte to the low byte to get the full memory address
	address_abs = bor(shiftLeft(hi, 8),  lo)
	return false
end
local function ABX() 
	lo = read (pc)
	pc = pc + 1
	hi = read (pc)
	pc = pc + 1

	address_abs = bor(shiftLeft(hi, 8),  lo) -- append the high byte to the low byte to get the full memory address
	address_abs = (address_abs + X)%(2^16)
	--print("ABX", address_abs)
	if band(address_abs, 0xFF00) ~= shiftLeft(hi, 8) then --If after incrementing by X the address is on a new page, we might need an extra clock cycle
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

	address_abs = bor(shiftLeft(hi, 8),  lo) -- append the high byte to the low byte to get the full memory address
	--address_abs = (address_abs + Y)%(2^16)
	if band(address_abs, 0xFF00) ~= shiftLeft(hi, 8) then--If after incrementing by Y the address is on a new page, we might need an extra clock cycle
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

	ptr = bor(shiftLeft(ptr_hi, 8),  ptr_lo)

	-- this would be the intended functionality, but theres actually a bug in the hardware...
	--address_abs = bor(shiftLeft(read(ptr+1), 8), read(ptr + 0))

	if ptr_lo == 0x00ff then --page boundary bug
		address_abs = bor(shiftLeft(read(band(ptr, 0xFF00)), 8), read(ptr + 0))
	else -- behave normally
		address_abs = bor(shiftLeft(read(ptr+1), 8), read(ptr + 0))
	end
	return false
end

local function IZX() 
	t = read(pc)
	pc = pc + 1

	local lo = read(band(t + X, 0x00FF))
	local hi = read(band(t + X + 1, 0x00FF))
	address_abs = bor(shiftLeft(hi, 8),  lo)

	return false
end
local function IZY() 
	t = read(pc)
	pc = pc + 1

	local lo = read(band(t, 0x00FF))
	local hi = read(band(t + 1, 0x00FF))
	address_abs = bor(shiftLeft(hi, 8),  lo)
	address_abs = address_abs + Y
	address_abs = band(address_abs, 0xFFFF)
	--print("IZY", address_abs)
	if band(address_abs, 0xFF00) ~= shiftLeft(hi, 8)  then
		return true
	else
		return false
	end
end

local function REL() 
	address_relative = read(pc)
	pc = pc + 1
	if band(address_relative, 0x80) >= 1 then --Check if negative
		address_relative = bor(address_relative, 0xFF00)
	end
	return false
end




--OPCODES AS local FUNCTIONS

local function  AND() 
	fetch()
	A = band(band(A, fetched), 0xFF)
	setFlag("Z", A == 0x00)
	setFlag("N", ( band(A, 0x80)))
	return true
end	
local function  BCC() 
	if status.flag.C == 0 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = band(address_abs, 0xFFFF)
	end
	return false

end
local function  BCS() 
	if status.flag.C == 1 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = band(address_abs, 0xFFFF)
	end
	return false

end	
local function  BEQ() 
	if status.flag.Z == 1 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = band(address_abs, 0xFFFF)
	end
	return false
end	
local function  BMI() 
	if status.flag.N == 1 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = band(address_abs, 0xFFFF)
	end
	return false
end
local function  BNE() 
	if status.flag.Z == 0 then

		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end
		pc = band(address_abs, 0xFFFF)
		address_abs = pc
		--print ("branching to", address_abs)
		
	end
	return false
end	
local function  BPL() 
	if status.flag.N == 0 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = band(address_abs, 0xFFFF)
	end
	return false
end	
	
local function  BVC() 
	if status.flag.V == 0 then
		cycles = cycles + 1
		address_abs = pc + address_relative
		if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
			cycles = cycles + 1
		end

		pc = address_abs
	end
	return false
end
local function  BVS()
	if status.flag.V == 1 then
	cycles = cycles + 1
	address_abs = pc + address_relative
	if band(address_abs, 0xff00) ~= band(pc, 0xff00) then
		cycles = cycles + 1
	end

	pc = address_abs
	end
	return false
end
local function  CLC() 
	setFlag("C",  false)
	return false
end	
local function  ADC()
	fetch()
	result = A + fetched + status.flag.C
	setFlag("C", result > 255)
	setFlag("Z",  band(result, 0x00ff) == 0)
	setFlag("N", ( band(A, 0x80)))
	local n1 = bxor(result, A)
	local n2 = bxor(bxor(A, fetched), 0xFFFF)
	local n3 = band(n1, n2)
	setFlag("V", band(n3, 0x0080))
	mostSigA = bit.bxor(A, 128) == 128
	mostSigM = bit.bxor(fetched, 128) == 128
	mostSigR = bit.bxor(result, 128) == 128

	local b1, b2, b3 = (A >= 0x80), (fetched >= 0x80), (result >= 0x80)
	--setFlag("V", (not(b1 or b2) and (b1 and b3)))
	if (not b1) and (not b2) and b3 then setFlag( "V", 1)
	elseif (b1) and (b2) and not b3  then setFlag( "V", 1)
	else
		setFlag( "V", 0)
	end

	--setFlag( "V", ( ((mostSigA == mostSigM) and (mostSigA ~= mostSigR))))
	A = band(result, 0x00FF)
	return true
end
local function  SBC()
	fetch()
	local temp = fetched
	local temp2 = A
	local temp3 = status.flag.C
	print("")
	value = bxor(fetched, 0x00ff)
	result = A + value + status.flag.C
	setFlag("C", band(result, 0xFF00))
	setFlag("Z",  band(result, 0x00ff) == 0)
	setFlag("N", ( band(A, 0x0080)))
	local v = band(band(fetched, A), 0x40) > 0
	if v then v = 1 else v = 0 end

	-- local n1 = bxor(result, A)
	-- local n2 = bxor(result, bxor(fetched, 0x00ff))
	-- local n3 = band(n1, n2)

	-- local b1, b2, b3 = (A >= 128), (fetched >= 128), (result >= 128)
	-- setFlag("V", (not(b1 or b2) and (b1 and b3)))

	-- --setFlag("V", band(n3, 0x0080))
	-- setFlag("V", band(n3, 0x0080))
	local b1, b2, b3 = (A >= 0x80), (fetched >= 0x80), (result >= 0x80)
	--setFlag("V", (not(b1 or b2) and (b1 and b3)))
	if (not b1) and (not b2) and b3 then 
		setFlag( "V", 1)
		print(A, fetched, result)
	elseif (b1) and (b2) and not b3  then 
		setFlag( "V", 1)
		print(A, fetched, result)
	else
		setFlag( "V", 0)
		
	end


	-- mostSigA = bit.bxor(A, 128) == 128
	-- mostSigM = bit.bxor(value, 128) == 128
	-- mostSigR = bit.bxor(result, 128) == 128
	--setFlag( "V", tonumber( ((mostSigA == mostSigM) and (mostSigA ~= mostSigR))))
	A = band(result, 0x00FF)
	if status.flag.Z == 1 then status.flag.N = 0 end
	if status.flag.N == 1 and A <= 127 then status.flag.N = 0 end
	print("SBC  A = ", tonumber(temp2) .. " - " .. tonumber(temp) .. " - " .. "( 1  -  " ..tonumber(temp3) .. ")", A, result, status.flag.C, status.flag.Z, status.flag.N, status.flag.V)
	return true
end


local function  CLD() 
	status.flag.D = ( false)
	return false
end		
local function  CLI() 
	status.flag.I = ( false)
	return false
end	
local function  CLV() 
	setFlag( "V", ( false))
	return false
end		

local function  PHA() 
	write(STACKPOINTERBASE + stkp, A)
	--print("PHA writing ", string.format("%02x", A), "to the stack at", string.format("%04x", STACKPOINTERBASE + stkp))
	stkp = stkp - 1
	return false
end
local function  PLA() 
	stkp = stkp + 1
	A = read(STACKPOINTERBASE + stkp)
	--print("PLA Poping ", string.format("%02x", A), "from stack location", string.format("%04x", STACKPOINTERBASE + stkp))
	setFlag("Z",  A == 0x00)
	setFlag("N", ( band(A, 0x80)))
	return false
end


local function  ASL() 
	fetch();
	temp = shiftLeft(fetched, 1)
	setFlag("C", band(temp, 0xFF00) > 0)
	setFlag("Z",  band(temp , 0x00FF) == 0x00)
	setFlag("N", ( band(temp , 0x80)))
	if impliedAddressingMode then
		A = band(temp, 0x00FF)
	else
		write(address_abs, band(temp, 0x00FF))
	end
	return false
end	
local function  BIT() 

	fetch()
	temp = band(A , fetched)
	setFlag("Z",  band(temp , 0x00FF) == 0x00)
	setFlag("N", ( band(fetched , shiftLeft(1, 7))))
	setFlag( "V", tonumber( band(fetched , shiftLeft(1, 6))))
	return false
end
local function  BRK() 
	pc = pc + 1
	
	status.flag.I = ( 1)
	write(STACKPOINTERBASE + stkp, band(math.floor(shiftRight(pc, 8)), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp,  band(pc, 0x00FF))
	stkp = stkp - 1

	status.flag.B = ( 1)
	write(STACKPOINTERBASE + stkp, status.reg)
	stkp = stkp - 1
	status.flag.B = ( 0)

	pc = bor(read(0xFFFE), shiftLeft(read(0xFFFF), 8))
	return false;
end
local function  CMP() 
	--print(string.format("%04x", address_abs))
	fetch()
	temp = A - fetched
	setFlag("C",  (A >= fetched))
	setFlag("Z", ( A == fetched))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return true
end	
local function  CPX()
	fetch()
	temp = X - fetched
	setFlag("C",  X >= fetched)
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return false
end
local function  CPY()
	fetch()
	temp = Y - fetched
	setFlag("C",  Y >= fetched)
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
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
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return false
end
local function  DEX() 
	X = band(X-1 , 0x00FF)
	setFlag("Z", ( X == 0))
	setFlag("N", ( band(X , 0x0080) >= 1))
	return false
end	
local function  DEY() 
	Y = band(Y-1 , 0x00FF)
	setFlag("Z", ( Y == 0))
	setFlag("N", ( band(Y , 0x0080) >= 1))
	return false
end		
local function  EOR()
	fetch()
	A = bit.bxor(A, fetched)
	setFlag("Z", ( A == 0x00))
	setFlag("N", ( band(A, 0x80)))
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
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return false
end
local function  INX()
	temp = X + 1
	if X == 255 then
		temp = 0
	end
	if temp >= 256 then temp = temp%256 end
	X = temp
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return false
end		
local function  INY()
	temp = Y + 1
	if Y == 255 then
		temp = 0
	end
	if temp >= 256 then temp = temp%256 end
	Y = temp
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	return false
end		

local function  JMP()
	pc = address_abs
	return false
end
local function  JSR() 
	pc = pc -1
	write(STACKPOINTERBASE + stkp, band(shiftRight(pc, 8), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp, band(pc, 0x00FF))
	stkp = stkp - 1
	pc = address_abs
	return false
end	
local function  LDA() 
	fetch()
	A = fetched
	setFlag("Z", ( A == 0x00))
	setFlag("N", ( band(A , 0x80)))
	return true
end	
local function  LDX() 
	fetch()
	X = fetched
	setFlag("Z", ( X == 0x00))
	setFlag("N", ( band(X , 0x80)))
	return true
end	
local function  LDY() 
	fetch()
	Y = fetched
	setFlag("Z", ( Y == 0x00))
	setFlag("N", ( band(Y , 0x80)))
	return true
end	

local function  LSR() 
	fetch()
	setFlag("C",  band(fetched, 0x0001))
	temp = shiftRight(fetched, 1)
	setFlag("Z", ( band(temp , 0x00FF) == 0x0000))
	setFlag("N", ( band(temp , 0x0080) > 0))
	if impliedAddressingMode then
		A = band(temp, 0x00FF)
	else
		write(address_abs, band(temp, 0x00FF))
	end
	return 0;
end	
local function  NOP() 
	if opcode == 0xFC then return true
	else return false end
end	
local function  ORA()
	fetch()
	A = bor(A, fetched)
	setFlag("Z", ( A == 0x00))
	setFlag("N", ( band(A, 0x80)))
	return true
end
local function  PHP() 
	local temp = bor(status.reg, status.flag.B)
	write(STACKPOINTERBASE + stkp, bor( temp, status.flag.U))
	--print("PHP writing ", string.format("%02x", bor(temp, status.flag.U), "to the stack at", string.format("%04x", STACKPOINTERBASE + stkp)))
	status.flag.B = ( 0)
	status.flag.U = ( 0)
	stkp = stkp - 1
	return false
end

local function  PLP() 
	stkp = stkp + 1
	tmp = read(STACKPOINTERBASE + stkp)
	status.reg = (tmp)
	--print("PLP Poping ", string.format("%02x", tmp), "from stack location", string.format("%04x", STACKPOINTERBASE + stkp))
	status.flag.U = ( 1)
	return false
end	
local function  ROL() 
	fetch()
	temp = bor(shiftLeft(fetched, 1), status.flag.C)
	setFlag("C",  band(temp, 0xFF00))
	setFlag("Z", ( band(temp, 0x00FF) == 0))
	setFlag("N", ( band(temp, 0x0080)))
	if impliedAddressingMode then
		A = band(temp, 0x00ff)
	else
		write(address_abs, band(temp, 0x00ff))
	end
	return false

end -- shiftRight
local function  ROR()
	fetch()
	temp = bor(shiftLeft(fetched, 7), shiftRight(fetched, 1))
	setFlag("C",  band(temp, 0x01))
	setFlag("Z", ( band(temp, 0x00FF) == 0))
	setFlag("N", ( band(temp, 0x0080)))
	if impliedAddressingMode then
		A = band(temp, 0x00ff)
	else
		write(address_abs, band(temp, 0x00ff))
	end
	return false
end
local function  RTI() 
	stkp = stkp + 1
	status.reg = (read(STACKPOINTERBASE + stkp))

	status.reg = (band(status.reg, bit.bnot(status.flag.B)))
	status.reg = (band(status.reg, bit.bnot(status.flag.U)))
	stkp = stkp + 1
	lo = read(STACKPOINTERBASE + stkp)
	stkp = stkp + 1
	hi = read(STACKPOINTERBASE + stkp)
	pc = bor(shiftLeft(hi, 8),  lo)
	return false
end	
local function  RTS()
	stkp = stkp + 1
	lo = read(STACKPOINTERBASE + stkp)
	stkp = stkp + 1
	hi = read(STACKPOINTERBASE + stkp)
	pc = bor(shiftLeft(hi, 8),  lo)
	pc = pc + 1
	return false
end	
local function  SEC() 
	setFlag("C",  true)
	return false
end
local function  SED()  
	status.flag.D = ( true)
	return false
end	
local function  SEI()  
	status.flag.I = ( true)
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
	setFlag("Z", ( X == 0x00))
	setFlag("N", ( band(X, 0x80)))
	return false
end
local function  TAY()
	Y = A
	setFlag("Z", ( Y == 0x00))
	setFlag("N", ( band(Y, 0x80)))
	return false
end
local function  TSX() 
	X = stkp
	setFlag("Z", ( X == 0x00))
	setFlag("N", ( band(X, 0x80)))
	return false
end	
local function  TXA() 
	A = X
	setFlag("Z", ( A == 0x00))
	setFlag("N", ( band(A, 0x80)))
	return false
end	
local function  TXS() 
	stkp = X
	return false
end	
local function  TYA() 
	A = Y
	setFlag("Z", ( A == 0x00))
	setFlag("N", ( band(A, 0x80)))
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




local function reset()
	A = 0
	X = 0
	Y = 0
	stkp = 0xFD
	status.reg = 0 -- status register 8 bit word
   
	address_abs = 0xFFFC
	lo = read(address_abs + 0)
	hi = read(address_abs + 1)

	pc = bor(shiftLeft(hi, 8),  lo)
	--pc = 0x8000 -- FOR NESTEST
	address_abs = 0
	address_relative = 0
	fetched = 0

	cycles = 8
end -- interrupts and resets
local function irq() 

	if status.flag.I == 0 then
		-- write program counter to the stack
		write(STACKPOINTERBASE + stkp, band(shiftRight(pc, 8), 0x00FF))
		stkp = stkp - 1
		write(STACKPOINTERBASE + stkp, band(pc, 0x00FF))
		stkp = stkp - 1
		--store status
		status.flag.B = ( 0)
		status.flag.U = ( 1)
		status.flag.I = ( 1)
		write(STACKPOINTERBASE + stkp, status.reg)
		stkp = stkp - 1
		--jump to location at address FFFE
		address_abs = 0xfffe
		lo = read(address_abs + 0)
		hi = read(address_abs + 1)
		pc = bor(shiftLeft(hi, 8),  lo)

		cycles = 7
	end
		

end -- interrupt request, can be ignored
local function nmi() 
	-- write program counter to the stack
	write(STACKPOINTERBASE + stkp, band(shiftRight(pc, 8), 0x00FF))
	stkp = stkp - 1
	write(STACKPOINTERBASE + stkp, band(pc, 0x00FF))
	stkp = stkp - 1
	--store status
	status.flag.B = ( 0)
	status.flag.U = ( 1)
	status.flag.I = ( 1)
	write(STACKPOINTERBASE + stkp, status.reg)
	stkp = stkp - 1
	--jump to location at address FFFA
	address_abs = 0xfffa
	lo = read(address_abs + 0)
	hi = read(address_abs + 1)
	pc = bor(shiftLeft(hi, 8),  lo)

	cycles = 8

end -- nonMaskable interrupt
local function clock(dt)
	if cycles == 0 then
		fetchExecuteCycle()
	end
	cycles = cycles - 1
end

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
local function getSP()
	return stkp
end

local function getCurrentOp()
	return LOOKUP[opcode+1].name
end


cpu = {btoi = btoi,
 A =  A,
 X =  X,
 Y =  Y,
 getSP = getSP,
 getPC = getPC,
 getLastPC = getLastPC,
 printA = printA,
 -- status =  status,
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
 nmi  =  nmi,
 debugClock = fetchExecuteCycle,
 getCurrentOp = getCurrentOp,
 getA = getA, 
 getX = getX,
 getY = getY
 }
