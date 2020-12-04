--require "test"
require "cpu"
ProFi = require 'ProFi'
require "bus"
ppu = require "ppu"
--file = io.open ("dissassembly.txt", "w+")
io.output(file)
local ffi = require("ffi")

local moonshine = require 'moonshine'
--ffi.load("M6502.dll")
--require "luarocks.loader"
--require "libnativefunc"
--local mpu = require('M6502').new()
jit.on()
DEBUG_SCROLL_SIZE = 8

debugSubMode = 0

local lg = love.graphics

function reset ()
	cpu.reset()
	bus.reset()
end

function zfill (str, numZeros)
	local str = str
	for i = string.len(str), numZeros-1 do
		str = "0" .. str
	end
	return str
end

function love.load()

	NES = {}
	--NES.screen = --love.image.newImageData(256, 240)
	NES.screen = love.image.newImageData(4*256, 4*240)
	NES.image = love.graphics.newImage(NES.screen)

	counter = 0
	disAssCMD = ""
	num = 0
	cps = 0
	pageN = 0
	debugMode = true
	counter = 0
	big = lg.newFont("joystix monospace.ttf", 12) 
	--small = lg.newFont("joystix monospace.ttf", 12)
	pcounter = 0
	love.graphics.setBackgroundColor(.2, .2, 1, 1)

	foundInst = true
	--disAs = bus.getDissassembly()
	lg.setDefaultFilter( "nearest", "nearest", 1 )
	--tempBackground = lg.newImage("bkg.png")
	onInst = 0
	--bus.insertCart("DKtest2.nes")
	--bus.insertCart("mappy.nes")
	--bus.insertCart("ICTEST.nes")
	bus.insertCart("ntsc_torture.nes")
	cpu.reset()
	disAs = bus.getDissassembly(0x8000, 0xFFFF)
	selectedPal = 0
	timer = 0
	drawPatternTableTimer = 20
	enableFilter = true
	effectRad = 0.6
	effectAngle = 0
	effect = moonshine(moonshine.effects.crt)
                   .chain(moonshine.effects.glow)
                   		.chain(moonshine.effects.chromasep)

    effect.glow.strength = 1
    effect.chromasep.radius = .6
    effect.chromasep.width = 256
    effect.chromasep.height = 240
  	effect.crt.distortionFactor = {1.0001, 1.0001}

	--collectgarbage('stop')
	-- ProFi:start()
	-- bus.clockFrame2()
	-- ProFi:stop()
	-- ProFi:writeReport( 'clockProfile8.txt' )
	lg.setFont( big)


end

function love.update(dt)
	timer = dt + timer
	if debugMode == false then
		
	else
		--if love.keyboard.isDown("space") then bus.clockFrame() end
		if drawPatternTableTimer > 5  then
			drawPatternTableTimer = 0
	-- 		
	-- -- for i = 0, 8400 do
	-- -- 	add1()
	-- -- 	add2()
	-- -- end
	-- 	ProFi:stop()
	-- 	ProFi:writeReport( 'clockProfile7.txt' )
			patternTable1 = bus.getPatternMemory(0, selectedPal)
			patternTable2 = bus.getPatternMemory(1, selectedPal)
		else 
			
			 drawPatternTableTimer =  drawPatternTableTimer + dt
		end
		lg.setColor(1, 1, 1)
		--if love.keyboard.isDown("space") then bus.clockFrame2() end
		bus.clockFrame2()
		-- if love.keyboard.isDown("c") then 
		-- 	if love.keyboard.isDown("x") then 
		-- 		for i = 0, 200 do
		-- 			bus.clock()
		-- 		end
		-- 	else
		-- 		bus.clock()
		-- 	end
			
		-- 	patternTable1 = bus.getPatternMemory(0, selectedPal)
		-- 	patternTable2 = bus.getPatternMemory(1, selectedPal)
		-- end
	end
end

function love.draw()
	if debugMode then
		--lg.clear( )
		lg.setCanvas()
		--lg.clear( )
		lg.setColor(1, 1, 1, 1)
		
		--SUPER DEBUG MODE
		--if love.keyboard.isDown("space") then 
		--	for i = 0, 255 do
		--	lastDis = disAssCMD
		--	bus.clock()
		--	foundInst = false
		--	drawDissassembly(right_sidebar)
		--	lg.clear( )
		--	ssp = string.format("%x", cpu.getSP())
		--	if string.len(ast) == 1 then ssp = "0" .. ssp end
		--	if disAssCMD ~= lastDis then  
		--	 io.write(disAssCMD .. " A:".. ast .. " X:".. xst .. " Y:".. yst .. " SP:" .. ssp .. "\n")
		--	end
		--	end
		--end
		lg.setColor(1, 1, 1)
		
		lg.setColor(1, 1, 1)
		--lg.draw(bus.getPPUScreen(), 0, 0, 0, 2, 2)
		--if love.keyboard.isDown("space") then bus.clockFrame() end
		lg.setColor(1, 1, 1)
		lg.print("FPS: ".. love.timer.getFPS(), 600, (17 + 8)*20 )
		ppu2.draw()
		NES.image = love.graphics.newImage(NES.screen)
		
		--lg.setColor(0, 0, 0, .5)
		--lg.rectangle("fill", 10, 10, 700, 600)
		--lg.setColor(1, 1, 1, 1)
		
		if debugSubMode == 2 then drawDebug(pageN, 0x80) end
		if debugSubMode == 1 then drawPPUDebug() end
		if debugSubMode == 0 then 
			if enableFilter then 
			effect(function()
      			love.graphics.draw(NES.image, 8, 8, 0, 2, 2)
    		end)
    		else
    			love.graphics.draw(NES.image, 8, 8, 0, 2, 2)
    		end
		end --drawDebug(pageN, 0x80) end
		if debugSubMode == 3 then bus.getNameTables(1) end

		--drawPPUDebugSide()
		--drawPPUDebug()
		--drawDebug(pageN, 0x80)
		drawDissassembly(600)

		
	else
		lg.setColor(1, 1, 1, 1)

	end
end

function love.keypressed(k)
	if debugMode then
		if k == "space" then
			--pcounter = pcounter + 1
			--cpu.debugClock()
			--cpu.printA()
			--counter = cpu.getPC()
			--print ("counter = ", counter)
		elseif k == "r" then cpu.reset()
		elseif k == "escape" then love.event.quit()
		elseif k == "-" then effect.chromasep.radius = effectRad - 0.2
			effectRad = effectRad - 0.2--selectedPal = (selectedPal - 1)%8 --
		elseif k == "=" then effect.chromasep.radius = effectRad + 0.2
			effectRad = effectRad + 0.2--selectedPal = (selectedPal + 1)%8 --
		elseif k == "[" then effect.chromasep.angle = effectAngle - 0.78539816339
			effectAngle = effectAngle - 0.78539816339--selectedPal = (selectedPal - 1)%8 --
		elseif k == "]" then effect.chromasep.angle = effectAngle + 0.78539816339
			effectAngle = effectAngle + 0.78539816339
		elseif k == "f" then enableFilter = not enableFilter
		elseif k == "p" then selectedPal = (selectedPal + 1)%8 
		elseif k == "z" then if cpu.getFlag("Z") == "0" then cpu.setFlag("Z", 1) else cpu.setFlag("Z", 0) end
		elseif k == "s" then foundInst = false 
		elseif k == "q" then debugSubMode = (debugSubMode + 1)%4
		elseif k == "g" then for i = 1, 50 do
			cpu.debugClock()
			foundInst = false
			drawDissassembly(right_sidebar)

			--io.write(cpu.getCurrentOp() .. " A:".. string.upper(ast) .. " X:".. string.upper(xst) .. " Y:".. string.upper(yst) .. "\n")
			io.write(disAssCMD .. " A:".. ast .. " X:".. xst .. " Y:".. yst .. "\n")
			ast = string.format("%x", cpu.getA())
			if string.len(ast) == 1 then ast = "0" .. ast end
			xst = string.format("%x", cpu.getX())
			if string.len(xst) == 1 then xst = "0" .. xst end
			yst = string.format("%x", cpu.getY())
			if string.len(yst) == 1 then yst = "0" .. yst end
		end
		elseif k == "k" then cpu.debugClock()
			io.write(disAssCMD .. " A:".. ast .. " X:".. xst .. " Y:".. yst .. "\n")
		elseif k == "7" then 
			print("Universal Background =",  string.format("%02x", pbus.readByte(0x3F00)))
			local palStart = 0x3F01
			print("Background palette 0 =",  string.format("%02x", pbus.readByte(palStart + 0)), string.format("%02x", pbus.readByte(palStart + 1)), string.format("%02x", pbus.readByte(palStart + 2)))
			 palStart = 0x3F11
			print("Sprite palette 0 =",  string.format("%02x", pbus.readByte(palStart + 0)), string.format("%02x", pbus.readByte(palStart + 1)), string.format("%02x", pbus.readByte(palStart + 2)))
			print("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
		end
	end

	--print(effectRad, effectAngle)
end

function drawPPUDebug()
	--lg.draw(patternTable1, 500, (17)*20, 0, 2, 2)
	lg.draw(patternTable1, 0, 50, 0, 4, 4)
	--lg.draw(patternTable2, 650, (17)*20, 0, 1,  1)
	swatch = bus.getSwatchFromPaletteRam(selectedPal)
	lg.setColor(swatch[1])
	lg.rectangle("fill", 0, 0, 50, 50)
	lg.setColor(swatch[2])
	lg.rectangle("fill", 50, 0, 50, 50)
	lg.setColor(swatch[3])
	lg.rectangle("fill", 100, 0, 50, 50)
	lg.setColor(swatch[4])
	lg.rectangle("fill", 150, 0, 50, 50)
	lg.setColor(1, 1, 1)
end


function drawPPUDebugSide()
	lg.draw(patternTable1, 500, (17)*20, 0, 1, 1)
	--lg.draw(patternTable1, 0, 50, 0, 4, 4)
	lg.draw(patternTable2, 650, (17)*20, 0, 1,  1)
	swatch = bus.getSwatchFromPaletteRam(selectedPal)
	lg.setColor(swatch[1])
	lg.rectangle("fill", 500 + 0, (17)*20-10, 10, 10)
	lg.setColor(swatch[2])
	lg.rectangle("fill", 500 + 10, (17)*20-10, 10, 10)
	lg.setColor(swatch[3])
	lg.rectangle("fill", 500 + 20, (17)*20-10, 10, 10)
	lg.setColor(swatch[4])
	lg.rectangle("fill", 500 + 30, (17)*20-10, 10, 10)
	lg.setColor(1, 1, 1)
end


function drawDebug(page1, page2)
	if page1 >= 0x20 and page1 <= 0x3F then
		return 0
	end
	memStr = ""
	lg.setFont( big)
	for i = 0, 255 do

		pstr = string.format("%x", page1)
		istr = string.format("%x", i)
		vstr = string.format("%x",  bus.cpuRead((page1*256) + i))
		if string.len(pstr) == 1 then pstr = "0" .. pstr end
		if string.len(istr) == 1 then istr = "0" .. istr end
		if string.len(vstr) == 1 then vstr = "0" .. vstr end
		if i%16 == 0 then 
			memStr = memStr .. "\n" .. pstr..istr..": " .. vstr .. " " 
		else
			memStr = memStr .. vstr .. " "  
		end
	end
	
	memStr = memStr .. "\n"

	for i = 0, 255 do
		pstr = string.format("%x", page2)
		istr = string.format("%x", i)
		vstr = string.format("%x", bus.cpuRead((page2*256) + i))
		--print((page2*255) + i)
		if string.len(pstr) == 1 then pstr = "0" .. pstr end
		if string.len(istr) == 1 then istr = "0" .. istr end
		if string.len(vstr) == 1 then vstr = "0" .. vstr end
		if i%16 == 0 then 
			memStr = memStr .. "\n" .. pstr..istr..": " .. vstr .. " "
		else
			memStr = memStr .. vstr .. " "  
		end
	end
	
	lg.printf(memStr, 10, 10, 700, "left")
	--lg.setFont( small)
	
end


function drawDissassembly(right_sidebar)
	right_sidebar = right_sidebar or  600

	upperBound  = table.getn(disAs)
	if upperBound > onInst + DEBUG_SCROLL_SIZE then
		upperBound = onInst + DEBUG_SCROLL_SIZE
	end

	lowerBound = 1
	if onInst-DEBUG_SCROLL_SIZE > lowerBound then lowerBound = onInst-DEBUG_SCROLL_SIZE end
	
	if not foundInst then
		for i = 1, table.getn(disAs) do
			if disAs[i][2] == cpu.getLastPC() then 
				foundInst = true 
				--print(i, table.getn(disAs))
				onInst = i
				lowerBound = onInst - DEBUG_SCROLL_SIZE
				if lowerBound < 1 then lowerBound = 1 end
				upperBound  = table.getn(disAs)
				if upperBound > onInst + DEBUG_SCROLL_SIZE then
					upperBound = onInst + DEBUG_SCROLL_SIZE
				end
			end
		end
	end

	upperBound  = table.getn(disAs)
	if upperBound > onInst + DEBUG_SCROLL_SIZE then
		upperBound = onInst + DEBUG_SCROLL_SIZE
	end


	for i = lowerBound, upperBound do
		if disAs[i][2] == cpu.getLastPC() then 
			lg.setColor(252/255, 186/255, 3/255)
			onInst = i
			disAssCMD = "{" .. zfill(string.format("%04x", disAs[i][2]), 4) .. "}: " .. disAs[i][1]
		else 
			lg.setColor(1, 1, 1)
		end 
		lg.print("{" .. zfill(string.format("%x", disAs[i][2]), 4) .. "}: " .. disAs[i][1], right_sidebar, (i-lowerBound + 1)*20)
		
	end
	lg.setColor(1, 1, 1)
	lg.print("{" .. zfill(string.format("%x", cpu.getLastPC()), 4) .. "}: " .. cpu.getCurrentOp(), right_sidebar, (17 + 3)*20 )
	ast = string.format("%x", cpu.getA())
	if string.len(ast) == 1 then ast = "0" .. ast end
	xst = string.format("%x", cpu.getX())
	if string.len(xst) == 1 then xst = "0" .. xst end
	yst = string.format("%x", cpu.getY())
	if string.len(yst) == 1 then yst = "0" .. yst end
	lg.print("A: ".. ast, right_sidebar, (17 + 4)*20 )
	lg.print("X: ".. xst, right_sidebar, (17 + 5)*20 )
	lg.print("Y: ".. yst, right_sidebar, (17 + 6)*20 )


	lg.setColor(1, .5, .5)
	local flags = {"N", "V", "U", "B", "D", "I", "Z", "C"}
	for i = 1 , table.getn(flags) do
		if cpu.getFlag(flags[i]) == 1 then
			lg.setColor(.5, 1, .5)
		else
			lg.setColor(1, .5, .5)
		end
		lg.print(flags[i], right_sidebar-10+((i-1)*12), (17 + 7)*20 ) 
	end
	lg.setColor(1, 1, 1)
	lg.print("FPS: ".. love.timer.getFPS(), right_sidebar, (17 + 8)*20 )


end


