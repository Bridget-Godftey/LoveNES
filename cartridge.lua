--cartridge
require "mappers"

local function shiftLeft(num, shift)
	return num * 2 ^ shift
end
local function shiftRight(num, shift)
	return math.floor(num / 2 ^ shift)
end

local function rd(file, num)
	local foo = file:read(num)
	print(foo)
	return foo
end


function newCart(fileName)
	local cart = {}

	local PRGMemory = {}
	local CHRMemory = {}

	local mapperID = 0 -- iNES standard Mapper ID
	local numPRGBanks = 0 --Number of banks of Program Memory
	local numCHRBanks = 0 --Number of bamls of Character Memory

	--Read header of iNES file

	local romFile = assert(io.open(fileName, "rb")) -- open fileName
	header = {}
	header.name = tonumber(rd(romFile, 4)) -- read the first 16 bytes
	header.prg_rom_chunks = string.byte(romFile:read(1))
	header.chr_rom_chunks = string.byte(romFile:read(1))
	header.mapper1 = string.byte(romFile:read(1))
	header.mapper2 = string.byte(romFile:read(1))
	header.prg_ram_size = string.byte(romFile:read(1))
	header.tv_system1 = string.byte(romFile:read(1))
	header.tv_system2 = string.byte(romFile:read(1))
	header.unused = string.byte(romFile:read(5))
	if bit.band(header.mapper1, 0x04) > 0 then
		romFile:read(512)
	end

	--determine mapper ID
	mapperID= bit.bor(shiftLeft(shiftRight(header.mapper2, 4),4), shiftRight(header.mapper1, 4))

	-- determine file format
	nFileType = 1
	if nFileType == 0 then
		--stub
	elseif nFileType == 1 then
		numPRGBanks = header.prg_rom_chunks
		for i= 0, numPRGBanks*16384 do
			PRGMemory[i] = string.byte(romFile:read(1))
			
		end

		numCHRBanks = header.chr_rom_chunks
		for i= 0, numCHRBanks*8192 do
			local foo = romFile:read(1)
			foo = foo or string.char(0xEA)
			CHRMemory[i] = string.byte(foo)
		end

	elseif nFileType == 2 then
		--stub
	end
	
	romFile:close()

	cart.mapper = MAPPER_CONSTRUCTORS[mapperID](numPRGBanks, numCHRBanks)

	cart.cpuRead = function(addr, readOnly) 
		mappedAddr = cart.mapper.cpuMapRead(addr)
		data = 0
		if mappedAddr then
			data = PRGMemory[mappedAddr]
		end
		return data
	end

	cart.cpuWrite = function(addr, value)
		mappedAddr = cart.mapper.cpuMapWrite(addr)
		if mappedAddr then
			PRGMemory[mappedAddr] = value
		end
	end


	cart.ppuRead = function(addr, readOnly) 
		mappedAddr = cart.mapper.ppuMapRead(addr)
		data = 0
		if mappedAddr then
			data = CHRMemory[mappedAddr]
		end
		return data
	end


	cart.ppuWrite = function(addr, value) 
		mappedAddr = cart.mapper.ppuMapWrite(addr)
		if mappedAddr then
			CHRMemory[mappedAddr] = value
		end
	end




	return cart
end