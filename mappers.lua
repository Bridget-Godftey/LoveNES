--mappers.lua

function newMapper (num_prg_banks, num_chr_banks)
	local m = {}

	m.num_prg_banks = num_prg_banks or 1
	m.num_chr_banks = num_chr_banks or 1

	m.cpuMapRead = crd or  function (addr) return false end
	m.cpuMapWrite = cwr or  function (addr) return false end
	m.ppuMapRead = prd or  function (addr) return false end
	m.ppuMapWrite = pwr or  function (addr) return false end

	return m
end



local function newMapper_000 (num_prg_banks, num_chr_banks)
	local m = newMapper(num_prg_banks, num_chr_banks)
	
	m.cpuMapRead = function(addr)

		-- if PRGROM is 16KB
		--     CPU Address Bus          PRG ROM
		--     0x8000 -> 0xBFFF: Map    0x0000 -> 0x3FFF
		--     0xC000 -> 0xFFFF: Mirror 0x0000 -> 0x3FFF
		-- if PRGROM is 32KB
		--     CPU Address Bus          PRG ROM
		--     0x8000 -> 0xFFFF: Map    0x0000 -> 0x7FFF
		if addr >= 0x8000 and addr <= 0xFFFF then
			local foo = 0x3FFF
			if m.num_prg_banks > 1 then foo =  0x7FFF end
			mAddr = bit.band(addr, foo)
			return mAddr
		else
			return false
		end
	end

	m.ppuMapRead = function(addr)
		if addr >= 0x0000 and addr <= 0x1FFF then
			return addr
		else
		end
	end


	m.cpuMapWrite = function(addr)
		if addr >= 0x8000 and addr <= 0xFFFF then
			local foo = 0x3FFF
			if m.num_prg_banks > 1 then foo =  0x7FFF end
			mAddr = bit.band(addr, foo)
			return mAddr
		else
			return false
		end
	end

	m.ppuMapWrite = function(addr)
		if addr >= 0x0000 and addr <= 0x1FFF then
			return false
		end
	end


	return m

end

MAPPER_CONSTRUCTORS = {}

MAPPER_CONSTRUCTORS[0] = newMapper_000