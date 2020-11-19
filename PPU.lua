--PPU.lua


--function newPPU()
	local ppu = {}

	ppu.myCart = nil


	ppu.tblName = {}
	ppu.tblPalette = {}
	ppu.n = 0

	ppu.colors = {} --????

	ppu.colors[0x00] = {84/255, 84/255, 84/255}
	ppu.colors[0x01] = {0/255, 30/255, 116/255}
	ppu.colors[0x02] = {8/255, 16/255, 144/255}
	ppu.colors[0x03] = {48/255, 0/255, 136/255}
	ppu.colors[0x04] = {68/255, 0/255, 100/255}
	ppu.colors[0x05] = {92/255, 0/255, 48/255}
	ppu.colors[0x06] = {84/255, 4/255, 0/255}
	ppu.colors[0x07] = {60/255, 24/255, 0/255}
	ppu.colors[0x08] = {32/255, 42/255, 0/255}
	ppu.colors[0x09] = {8/255, 58/255, 0/255}
	ppu.colors[0x0A] = {0/255, 64/255, 0/255}
	ppu.colors[0x0B] = {0/255, 60/255, 0/255}
	ppu.colors[0x0C] = {0/255, 50/255, 60/255}
	ppu.colors[0x0D] = {0/255, 0/255, 0/255}
	ppu.colors[0x0E] = {0/255, 0/255, 0/255}
	ppu.colors[0x0F] = {0/255, 0/255, 0/255}

	ppu.colors[0x10] = {152/255, 150/255, 152/255}
	ppu.colors[0x11] = {8/255, 76/255, 196/255}
	ppu.colors[0x12] = {48/255, 50/255, 236/255}
	ppu.colors[0x13] = {92/255, 30/255, 228/255}
	ppu.colors[0x14] = {136/255, 20/255, 176/255}
	ppu.colors[0x15] = {160/255, 20/255, 100/255}
	ppu.colors[0x16] = {152/255, 34/255, 32/255}
	ppu.colors[0x17] = {120/255, 60/255, 0/255}
	ppu.colors[0x18] = {84/255, 90/255, 0/255}
	ppu.colors[0x19] = {40/255, 114/255, 0/255}
	ppu.colors[0x1A] = {8/255, 124/255, 0/255}
	ppu.colors[0x1B] = {0/255, 118/255, 40/255}
	ppu.colors[0x1C] = {0/255, 102/255, 120/255}
	ppu.colors[0x1D] = {0/255, 0/255, 0/255}
	ppu.colors[0x1E] = {0/255, 0/255, 0/255}
	ppu.colors[0x1F] = {0/255, 0/255, 0/255}

	ppu.colors[0x20] = {236/255, 238/255, 236/255}
	ppu.colors[0x21] = {76/255, 154/255, 236/255}
	ppu.colors[0x22] = {120/255, 124/255, 236/255}
	ppu.colors[0x23] = {176/255, 98/255, 236/255}
	ppu.colors[0x24] = {228/255, 84/255, 236/255}
	ppu.colors[0x25] = {236/255, 88/255, 180/255}
	ppu.colors[0x26] = {236/255, 106/255, 100/255}
	ppu.colors[0x27] = {212/255, 136/255, 32/255}
	ppu.colors[0x28] = {160/255, 170/255, 0/255}
	ppu.colors[0x29] = {116/255, 196/255, 0/255}
	ppu.colors[0x2A] = {76/255, 208/255, 32/255}
	ppu.colors[0x2B] = {56/255, 204/255, 108/255}
	ppu.colors[0x2C] = {56/255, 180/255, 204/255}
	ppu.colors[0x2D] = {60/255, 60/255, 60/255}
	ppu.colors[0x2E] = {0/255, 0/255, 0/255}
	ppu.colors[0x2F] = {0/255, 0/255, 0/255}

	ppu.colors[0x30] = {236/255, 238/255, 236/255}
	ppu.colors[0x31] = {168/255, 204/255, 236/255}
	ppu.colors[0x32] = {188/255, 188/255, 236/255}
	ppu.colors[0x33] = {212/255, 178/255, 236/255}
	ppu.colors[0x34] = {236/255, 174/255, 236/255}
	ppu.colors[0x35] = {236/255, 174/255, 212/255}
	ppu.colors[0x36] = {236/255, 180/255, 176/255}
	ppu.colors[0x37] = {228/255, 196/255, 144/255}
	ppu.colors[0x38] = {204/255, 210/255, 120/255}
	ppu.colors[0x39] = {180/255, 222/255, 120/255}
	ppu.colors[0x3A] = {168/255, 226/255, 144/255}
	ppu.colors[0x3B] = {152/255, 226/255, 180/255}
	ppu.colors[0x3C] = {160/255, 214/255, 228/255}
	ppu.colors[0x3D] = {160/255, 162/255, 160/255}
	ppu.colors[0x3E] = {0, 0, 0}
	ppu.colors[0x3F] = {0, 0, 0}







	--ppu.screen = love.graphics.newCanvas(256, 240)
	ppu.nameTableCanvas = {love.graphics.newCanvas(256, 240)}
	ppu.patternTables = {love.graphics.newCanvas(128, 128)}



	--ppu.getScreen = function ()  return ppu.screen  end
	ppu.getNameTableCanvas = function ()  return ppu.nameTableCanvas end
	ppu.getPatternTables = function () return ppu.patternTables  end
	ppu.frameComplete = false
	ppu.scanline = 0
	ppu.cycle = 0
	ppu.getFrameComplete = function() 
		foo =  ppu.frameComplete 
		ppu.frameComplete = false
		return foo
	end

	ppu.tblName[0] = {}
	ppu.tblName[1] = {}
	for i = 0, 1024-1 do
		ppu.tblName = 0
	end
	ppu.tblPalette = {}
	for i = 0, 31 do
		ppu.tblPalette = 0
	end


	ppu.cpuRead = function(addr, readOnly) 
		data = 0x00
		if     addr == 0x0000 then 
			--control
		elseif addr == 0x0001 then 
			--mask
		elseif addr == 0x0002 then
			--status
		elseif addr == 0x0003 then
			--OAM address
		elseif addr == 0x0004 then
			-- OAM DATA
		elseif addr == 0x0005 then
			--SCROLL
		elseif addr == 0x0006 then
			-- ppu address
		else
			--PPU DATA
		end
		return data
	end

	ppu.cpuWrite = function(addr, value) 
		if     addr == 0x0000 then 
			--control
		elseif addr == 0x0001 then 
			--mask
		elseif addr == 0x0002 then
			--status
		elseif addr == 0x0003 then
			--OAM address
		elseif addr == 0x0004 then
			-- OAM DATA
		elseif addr == 0x0005 then
			--SCROLL
		elseif addr == 0x0006 then
			-- ppu address
		else
			--PPU DATA
		end 
	end


	ppu.ppuRead = function(addr, readOnly) 
		addr = addr%0x3FFF
		readOnly = false
		data = 0x00
		if addr >= 0x0000 and addr <= 0x1FFF then
			data = ppu.myCart.ppuRead(addr, readOnly)
		end 
		return 0
	end

	ppu.ppuWrite = function(addr, value) 
		addr = addr%0x3FFF
		if addr >= 0x0000 and addr <= 0x1FFF then
			ppu.myCart.ppuWrite(value)
		end
	end

	ppu.connectCartridge = function(cart)
		ppu.myCart = cart
	end
	local mr =  math.random
	local lg = love.graphics
	local noiz =  love.math.noise
	ppu.clock = function()
		--ppu.n = (ppu.n)%255 + 1.1
		--ppu.frameComplete  = false
		--love.graphics.setCanvas(ppu.screen)
		local color =mr (0, 1) --love.math.random(0, 1)
		--print(color, ppu.cycle-1, ppu.scanline)
		lg.setColor(color, color, color, 1)
		lg.rectangle("fill", ppu.cycle-1, ppu.scanline, 2, 2)

		 ppu.cycle =  ppu.cycle + 1
		if  ppu.cycle >= 341 then
			 ppu.cycle = 0
			ppu.scanline = ppu.scanline + 1
			if ppu.scanline >= 261 then
				ppu.scanline = -1
				ppu.frameComplete  = true
			end
		end
	end


	return ppu