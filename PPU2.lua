--[[
Nintendo Entertainment System emulator for Love2D
Pixel Processing Unit Emulation

By Gamax92
--]]

require "pbus"

local _ppu = {
	last = 0,
	palSwap = false,
	lastcycle = 0,
	vbstart = false,
	ctrl = {
		baseaddr = 0,
		xscroll = 0,
		yscroll = 0,
		increment = 0,
		spta = 0,
		bpta = 0,
		spritesize = 0,
		mode = 0,
		nmi = 0,
	},
	mask = {
		grayscale = 0,
		bgeight = 0,
		spriteeight = 0,
		bgshow = 0,
		spritesshow = 0,
		intensered = 0,
		intensegreen = 0,
		intenseblue = 0,
	},
	camx = 0,
	camy = 0,
	oamaddr = 0,
	ppuaddr = 0,
	camwrite = false,
	ppuwrite = false,
}

oct2bin = {
    ['0'] = '000',
    ['1'] = '001',
    ['2'] = '010',
    ['3'] = '011',
    ['4'] = '100',
    ['5'] = '101',
    ['6'] = '110',
    ['7'] = '111'
}
function getOct2bin(a) return oct2bin[a] end
function convertBin(n)
    local s = string.format('%o', n)
    s = s:gsub('.', getOct2bin)
    return s
end


local VRam = {}
for i = 0, 2047 do
	VRam[i] = 0xFF
end

local Buffer = {}

local PalRam = {}
for i = 0, 31 do
	PalRam[i] = 0
end

OAMRam = {}
for i = 0, 255 do
	OAMRam[i] = 0
end
local PatternTableCanvas = love.graphics.newCanvas(256, 256)

palHack2 = {}
palHack = {}

local shiftRight = function (n1, n2)
	return math.floor(n1/(2^n2))
end
local getNameTables = function ()
	for y = 0, 29 do
		for x = 0, 31 do

			foo = string.format("%02x", pbus.readByte(y*32+x+0x2000))--VRam[y*32+x])--pbus.readByte(y*32+x+0x2000))
			--print("~~~~~~~~~~~~", string.format("%04x", y*32+x+0x2000), "~~~~~~~~~~~~")
			love.graphics.print(foo, x*18, y*16)
			
		end
	end
end

local size = 1
local function readPalRam(address)
	if address == 0x10 or address == 0x14 or address == 0x18 or address == 0x1C then
		address = address - 0x10
	end
	--print("palette", string.format( address), string.format("%02x", PalRam[address]))
	--print(PalRam[address])
	return PalRam[address]

end
local function writePalRam(address, value)
	if address == 0x10 or address == 0x14 or address == 0x18 or address == 0x1C then
		address = address - 0x10
	end
	if _ppu.palSwap then
		if table.getn(palHack) >= 1 then
			local y = math.floor(262-((_ppu.lastcycle*3)/341))
			palHack[size] = {unpack(palHack[size-1])}
			palHack[size][address] = value
			size = size + 1
			table.insert(palHack2, y)
		else
			--table.insert(palHack2, y)
			local y = math.floor(262-((_ppu.lastcycle*3)/341))
			palHack[size] = {unpack(PalRam)}
			palHack[size][address] = value
			size = size + 1
			table.insert(palHack2, y)
		end
		PalRam[address] = value
	else
	--print(address, value)
		PalRam[address] = value
	end
end

local palette = {}
local palfile, err = love.filesystem.newFile("palette.act", "r")
if not palfile then
	error("[NES.ppu] Failed to load palette\n" .. err)
end
for i = 0, 63 do
	palette[i] = { palfile:read(3):byte(1, -1) }
	palette[i] = {palette[i][1]/255, palette[i][2]/255, palette[i][3]/255}
end
palfile:close()

local function readCtrl(address)
	--print("[PPU:GET] " .. address)
	if address == 2 then -- Status
		local stat = _ppu.last + (vbstart and 128 or 0)
		vbstart = false
		-- Clear Latch
		_ppu.camwrite = false
		_ppu.ppuwrite = false
		return stat
	elseif address == 4 then -- OAM data
		return OAMRam[_ppu.oamaddr]
	elseif address == 7 then -- Data
		-- TODO: Non-VBlank Glitchy Read?
		local value =    pbus.readByte(_ppu.ppuaddr)
		local ppuaddr = _ppu.ppuaddr
		if _ppu.ctrl.increment == 0 then
			_ppu.ppuaddr = (_ppu.ppuaddr+1)%16384
		else
			_ppu.ppuaddr = (_ppu.ppuaddr+32)%16384
		end
		if ppuaddr < 0x3F00 then
			if Buffer[ppuaddr] == nil then
				Buffer[ppuaddr] = math.random(0, 255)
			end
			local cache = Buffer[ppuaddr]
			Buffer[ppuaddr] = value
			return cache
		else
			return value
		end
	else
		return bus.last
	end
end

local function writeCtrl(address, value)
	--print("[PPU:SET] " .. address .. " " .. value)
	_ppu.last = bit.band(value, 31)
	if address == 0 then
		_ppu.ctrl.baseaddr   = bit.band(value, 3)
		_ppu.ctrl.xscroll    = bit.band(value, 1)
		_ppu.ctrl.yscroll    = bit.band(value, 2)
		_ppu.ctrl.increment  = bit.band(value, 4)
		_ppu.ctrl.spta       = bit.band(value, 8) * 512
		_ppu.ctrl.bpta       = bit.band(value, 16) * 256
		_ppu.ctrl.spritesize = bit.band(value, 32)
		_ppu.ctrl.mode       = bit.band(value, 64)
		_ppu.ctrl.nmi        = bit.band(value, 128)
	elseif address == 1 then
		_ppu.mask.grayscale    = bit.band(value, 1)
		_ppu.mask.bgeight      = bit.band(value, 2)
		_ppu.mask.spriteeight  = bit.band(value, 4)
		_ppu.mask.bgshow       = bit.band(value, 8)
		_ppu.mask.spritesshow  = bit.band(value, 16)
		_ppu.mask.intensered   = bit.band(value, 32)
		_ppu.mask.intensegreen = bit.band(value, 64)
		_ppu.mask.intenseblue  = bit.band(value, 128)
	elseif address == 3 then
		_ppu.oamaddr = value
	elseif address == 4 then
		-- TODO: Faulty Increment?
		-- TODO: Faulty Writes?
		OAMRam[_ppu.oamaddr] = value
		_ppu.oamaddr = bit.band(_ppu.oamaddr + 1, 0xFF)
	elseif address == 5 then
		if not _ppu.camwrite then -- X Address
			_ppu.camx = value
		else -- Y Address
			_ppu.camy = value
		end
		_ppu.camwrite = not _ppu.camwrite
	elseif address == 6 then
		if not _ppu.ppuwrite then -- High Byte
			_ppu.ppuaddr = bit.lshift(value, 8) + bit.band(_ppu.ppuaddr, 0xFF)
		else -- Low Byte
			_ppu.ppuaddr = bit.band(_ppu.ppuaddr, 0xFF00) + value
		end
		_ppu.ppuwrite = not _ppu.ppuwrite
	elseif address == 7 then
		-- TODO: Non-VBlank Glitchy Write?
		
		if _ppu.ppuaddr >=  0x3F00 and _ppu.ppuaddr <= 0x3FFF then
			--print("write pal", _ppu.ppuaddr)
			writePalRam(bit.band(_ppu.ppuaddr, 0x001f), value)
		else
		   pbus.writeByte(_ppu.ppuaddr, value)
		end
		if _ppu.ctrl.increment == 0 then
			_ppu.ppuaddr = (_ppu.ppuaddr+1)%16384
		else
			_ppu.ppuaddr = (_ppu.ppuaddr+32)%16384
		end
	end
end

local function writeDMA(address, value)
	local base = value * 256
	for i = 0, 255 do
		OAMRam[_ppu.oamaddr] = bus.cpuRead(base+i)
		_ppu.oamaddr = bit.band(_ppu.oamaddr + 1, 0xFF)
	end
end

local xscroll
local yscroll
local function drawPixel(x, y, pal)
	if x>=0 and x<256 and y>=0 and y<240 then
		NES.screen:setPixel(x, y, pal[1], pal[2], pal[3], 1)
		--print(x, y, pal[1], pal[2], pal[3])
	end
end

local function drawCHR(addr, x, y, pal, hflip, vflip)
	x=x-xscroll
	y=y-yscroll
	if x+8<0 or x>=256 or y+8<0 or y>=240 then return end
	local p1 = palette[   pbus.readByte(pal)]
	local p2 = palette[   pbus.readByte(pal+1)]
	local check = pbus.readByte(pal+2)
	local p3 = palette[   check]
	-- local errorFlag = false
	-- -- first = 0
	-- if check %2 == 1 and pbus.readByte(addr) == 0 and pbus.readByte(addr+ 8) == 0 then 
	-- 	errorFlag = true
	-- end
	-- if pbus.readByte(pal+2)%2 == 1 then  first = (pbus.readByte(addr))-1 end
	for i=0, 7 do
		--local tileVal =  pbus.readByte(addr+i)
		for n=0, 7 do
			--c = ((chr[addr+i] & (1 << n)) >> n) | ((chr[addr+i+8] & (1 << n)) >> (n-1))
			
			local c = bit.band(shiftRight(   pbus.readByte(addr+i), n), 1)+bit.band(n > 0 and shiftRight(   pbus.readByte(addr+i+8), n-1) or bit.lshift(   pbus.readByte(addr+i+8), 1), 2)
			-- if i == 0 and n == 0 and check%2 == 1 and c == 1 then errorFlag = true end
			-- --if pbus.readByte(pal+2)%2 == 1 and c == 1 then print(convertBin( pbus.readByte(addr+i))) end 
		 --    if love.keyboard.isDown("v") then 
			--    if c == 1 then print( (pbus.readByte(addr+i)),   (pbus.readByte(addr+i+8)), i, n, bit.rshift(   pbus.readByte(addr+i+8), 1)) end
			-- end
			if i == 0 and n == 0 and check%2 == 1 and c == 1 then
				c = 0
			end
			--if  errorFlag then c = 0 end
			if c ~= 0 then

				local sx = hflip and n or 7-n
				local sy = vflip and 7-i or i
				drawPixel(sx+x, sy+y, c == 1 and p1 or c == 2 and p2 or p3)
			end
		end
	end
end

local bgpal
local function drawBackground()
	return bgpal[1], bgpal[2], bgpal[3], 1
end

local drawPSHACK = function ()
	for y = 0, 29 do
		for x = 0, 31 do
			--foo = string.format("%02x", ppu.tblName[1][y*32+x])
			bar = VRam[y*32+x]
			local sX = (bar%16)*8
			local sY = math.floor(bar/16)*8--shiftLeft( band(shiftRight(bar, 4), 0x0f), 3)
			local fooquad  = love.graphics.newQuad(sX, sY, 8, 8, 128, 128)
			love.graphics.draw(ppu.patternTables[1], fooquad, x*8, y*8) --, 0, 2, 2)
		end
	end
end


-- drawCheats = {}
-- for i =  0, 300 do
-- 	drawCheats[i] = {}
-- 	for j = 0, 333 do
-- 		drawCheats[i][j] = true
-- 	end
-- end

-- --local paletteHack = {}
-- --local hackN = 0
-- for i = 0, 32 do
-- 	paletteHack[i] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
-- end
local size2 = 1
ppu2 = {
	run = function()
		local lX = (_ppu.lastcycle*3)%341
		local lY = math.floor(262-((_ppu.lastcycle*3)/341))

		local cX = (bus.cycles*3)%341
		local cY = math.floor(262-((bus.cycles*3)/341))

		-- if cX%8 == 0 then
		-- 	--drawCheats[cX/8][math.ceil(cY/8)] = true --(_ppu.mask.bgshow == 1)
		-- 	local x = cX/8
		-- 	local y = math.ceil(cY/8
		-- 	local bx = 0
		-- 	local by = 0
		-- 	local atx = math.floor(x/4)
		-- 	local aty = math.floor(y/4)
		-- 	local amx = math.floor((x-(atx*4))/2)
		-- 	local amy = math.floor((y-(aty*4))/2)
		-- 	local atb = 0x3C0
		-- 	local atr =    pbus.readByte(base+atb+(aty*8)+atx)
		-- 	local sa = amy == 0 and (amx == 0 and 0 or 2) or (amx == 0 and 4 or 6)
		-- 	local attr = bit.band(bit.rshift(atr, sa), 0x3)-
		-- 	drawCHR((  pbus.readByte(0x2000+(cY*32)+cX)*16)+_ppu.ctrl.bpta-1, (cX)+(bx*256), (cY*8)+(by*240), (attr*4)+0x3F01, false, false)
		-- end
		-- if bus.cycles%255 == 0 then
		-- 	paletteHack[hackN] = {unpack(PalRam)}
		-- 	hackN = hackN + 1
		-- end


		local set = 2065 -- Determined by vbl_clear_time.nes
		if _ppu.lastcycle > set and bus.cycles <= set then -- VBlank start
			vbstart = true
			hackN = 0
			if _ppu.ctrl.nmi ~= 0 then
				 cpu.nmi()
			end
		end
		if _ppu.lastcycle <= set and bus.cycles > set then -- VBlank ended
			vbstart = false
			
		end
		_ppu.lastcycle = bus.cycles
	end,
	draw = function()
		bgpal = palette[   pbus.readByte(0x3F00)] or {0, 0, 0, 1}
		NES.screen:mapPixel(drawBackground, 0, 0, 256, 240)
		for i = 63, 0, -1 do -- Sprites draw backwards
			local base = i*4
			if OAMRam[base] < 0xEF then
				if bit.band(OAMRam[base+2], 32) == 32 then -- Behind BG
					if _ppu.ctrl.spritesize == 0 then -- 8x8 sprites
						drawCHR((OAMRam[base+1]*16)+_ppu.ctrl.spta-1, OAMRam[base+3], OAMRam[base]+2, ((OAMRam[base+2]%4)*4)+0x3F11, bit.band(OAMRam[base+2], 64)>0, bit.band(OAMRam[base+2], 128)>0)
					else -- 8x16 sprites
						local tile = (math.floor(OAMRam[base+1]/2)*8)+((OAMRam[base+1]%2)*4096)
						-- TODO: 8x16 sprites
					end
				end
			end
		end
		xscroll = (_ppu.ctrl.xscroll*256)+_ppu.camx
		yscroll = (_ppu.camy)-(_ppu.ctrl.yscroll*10)
		print(xscroll, yscroll, _ppu.camy)
		-- TODO: Only draw visible tiles
		--local oldPram = {unpack(PalRam)}
		for by = 0, 1 do
			for bx = 0, 1 do
				local base = 0x2000 + (bx*0x400) + (by*0x800)
				for y = 0, 29 do
					if _ppu.palSwap then 
						if  (y*8)+(by*240) >= (palHack2[1] or 999999999) then 
							for i = 0, table.getn(PalRam) do
								if PalRam[i] ~= palHack[size2][i] then
									PalRam[i] = palHack[size2][i]
								end
							end
							--PalRam = {unpack(palHack[palHack2[1]])}
							print("SWAP", palHack2[1])--, unpack(PalRam))
							table.remove(palHack2, 1)
							--table.remove(palHack, 1)
							size2 = size2 + 1
						end

					end
					--PalRam = paletteHack[y*8]
					for x = 0, 31 do
						local atx = math.floor(x/4)
						local aty = math.floor(y/4)
						local amx = math.floor((x-(atx*4))/2)
						local amy = math.floor((y-(aty*4))/2)
						local atb = 0x3C0
						local atr =    pbus.readByte(base+atb+(aty*8)+atx)
						local sa = amy == 0 and (amx == 0 and 0 or 2) or (amx == 0 and 4 or 6)
						local attr = math.floor(atr/(2^sa))%4--bit.band(bit.rshift(atr, sa), 0x3)--NES.ppu.ppu
						drawCHR((   pbus.readByte(base+(y*32)+x)*16)+_ppu.ctrl.bpta-1, (x*8)+(bx*256), (y*8)+(by*240), (attr*4)+0x3F01, false, false)
					end
				end
			end
		end
		--PalRam = {unpack(oldPram)}
	--end,
		if palHack[size2-1] ~= nil then 
			PalRam = {unpack(palHack[size2-1])}
		end
		xscroll = 0
		yscroll = 0
		for i = 63, 0, -1 do -- Sprites draw backwards
			local base = i*4
			if OAMRam[base] < 0xEF then
				if bit.band(OAMRam[base+2], 32) == 0 then -- Infront of BG
					if _ppu.ctrl.spritesize == 0 then -- 8x8 sprites
						drawCHR((OAMRam[base+1]*16)+_ppu.ctrl.spta-1, OAMRam[base+3], OAMRam[base]+2, ((OAMRam[base+2]%4)*4)+0x3F11, bit.band(OAMRam[base+2], 64)>0, bit.band(OAMRam[base+2], 128)>0)
					else -- 8x16 sprites
						local tile = (math.floor(OAMRam[base+1]/2)*8)+((OAMRam[base+1]%2)*4096)
						print("Warning, 8x16 sprite")
						-- TODO: 8x16 sprites
					end
				end
			end
		end
	end,
	reset = function()
		-- TODO: Reset stuff
	end,
	ppu = _ppu,
	VRam = VRam,
	insertCart = function(c)



		local writeNameTbl = nil
		local readNameTbl = nil
		if c.getMirrorMode() == 1 then
			writeNameTbl = function (addr, value)
				--print("writing VRam", string.format("%04x", addr), value)
				addr =  bit.band(addr, 0x0FFF)
				if addr >= 0x0000 and addr <= 0x03FF then
					 VRam[addr] = value
				elseif addr >= 0x0400 and addr <= 0x07FF then
					 VRam[1024+ bit.band(addr, 0x03FF)] = value
				elseif addr >= 0x0800 and addr <= 0x0BFF then
					 VRam[ bit.band(addr, 0x03FF)] = value
				elseif addr >= 0x0C00 and addr <= 0x0FFF then
					 VRam[1024 + bit.band(addr, 0x03FF)] = value
				end
			end
		--end
		else
		--if c.getMirrorMode == 0 then
			writeNameTbl = function (addr, value)
				--print("writing VRam", string.format("%04x", addr), value)
				addr =  bit.band(addr, 0x0FFF)
				if addr >= 0x0000 and addr <= 0x03FF then
					 VRam[addr] = value
				elseif addr >= 0x0400 and addr <= 0x07FF then
					 VRam[ bit.band(addr, 0x03FF)] = value
				elseif addr >= 0x0800 and addr <= 0x0BFF then
					 VRam[1024 + bit.band(addr, 0x03FF)] = value
				elseif addr >= 0x0C00 and addr <= 0x0FFF then
					 VRam[1024 +  bit.band(addr, 0x03FF)] = value
				end
			end
		end


		if c.getMirrorMode() == 1 then
			readNameTbl = function (addr)
				data = 0x00
				addr =  bit.band(addr, 0x0FFF)
				if addr >= 0x0000 and addr <= 0x03FF then
					 data = VRam[addr] 
				elseif addr >= 0x0400 and addr <= 0x07FF then
					 data = VRam[1024+ bit.band(addr, 0x03FF)] 
				elseif addr >= 0x0800 and addr <= 0x0BFF then
					 data = VRam[ bit.band(addr, 0x03FF)] 
				elseif addr >= 0x0C00 and addr <= 0x0FFF then
					 data = VRam[1024 + bit.band(addr, 0x03FF)] 
				end
				--print("reading VRam", string.format("%04x", addr), data)
				return data
			end
		--end
		else
		--if c.getMirrorMode == 0 then
			--print(c.getMirrorMode())
			readNameTbl = function (addr)
				data = 0x00
				addr =  bit.band(addr, 0x0FFF)
				if addr >= 0x0000 and addr <= 0x03FF then
					 data = VRam[addr]
				elseif addr >= 0x0400 and addr <= 0x07FF then
					 data = VRam[ bit.band(addr, 0x03FF)] 
				elseif addr >= 0x0800 and addr <= 0x0BFF then
					 data = VRam[1024 + bit.band(addr, 0x03FF)] 
				elseif addr >= 0x0C00 and addr <= 0x0FFF then
					 data = VRam[1024 +  bit.band(addr, 0x03FF)] 
				end
				--print("reading VRam", string.format("%04x", addr), data)
				return data
			end
		end
		pbus.register(0x0000, 0x2000, c.ppuRead, c.ppuWrite, 0x1FFF)
		pbus.register(0x2000, 0x1EFF, readNameTbl, writeNameTbl, 0xFFFF)




	 end,
	 getNameTables = getNameTables,
}

-- Register ROM in bus
bus.register(0x2000, 0x2000, readCtrl, writeCtrl, 7)

-- OAM DMA
bus.register2(0x4014, 1, function() return bus.last end, writeDMA, 0xFFFF)

-- Register Memory in ppu-bus
pbus.register(0x3F00, 0x00FF, readPalRam, writePalRam, 0x1F)
