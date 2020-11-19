--require "test"
require "bytestring"
require "cpu"
ProFi = require 'ProFi'
require "bus"
ppu = require "ppu"
--require "luarocks.loader"
--require "libnativefunc"
--local mpu = require('M6502').new()
jit.on()
DEBUG_SCROLL_SIZE = 8
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
	counter = 0
	num = 0
	cps = 0
	pageN = 0
	debugMode = true
	counter = 0
	big = lg.newFont("joystix monospace.ttf", 12) 
	--small = lg.newFont("joystix monospace.ttf", 12)
	pcounter = 0
	--disAs = bus.getDissassembly()
	lg.setDefaultFilter( "nearest", "nearest", 1 )
	--tempBackground = lg.newImage("bkg.png")
	onInst = 0
	bus.insertCart("nestest.nes")
	cpu.reset()
	disAs = bus.getDissassembly(0xC000, 0xFFFF)
	collectgarbage('stop')

end

function love.update(dt)
	if debugMode == false then
		--num = num + dt
		--if num < 1+tollerance and num > 1-tollerance then cps = counter end
		--counter = counter + 4
		bus.clock(dt)
		bus.clock(dt)
		bus.clock(dt)
		bus.clock(dt)
	else
		--if love.keyboard.isDown("space") then bus.clockFrame() end
		if love.keyboard.isDown("c") then bus.clock() end
	end
end

function love.draw()
	if debugMode then
		lg.setCanvas()
		--lg.clear( )
		lg.setColor(1, 1, 1, 1)
		
		lg.draw(bus.getPPUScreen(), 0, 0, 0, 2, 2)--, 0, 1, 1)
		if love.keyboard.isDown("space") then bus.clockFrame() end

		--if love.keyboard.isDown("space") then bus.clockFrame() end
		lg.setColor(1, 1, 1)
		lg.print("FPS: ".. love.timer.getFPS(), 600, (17 + 8)*20 )
		--lg.setColor(0, 0, 0, .5)
		--lg.rectangle("fill", 10, 10, 700, 600)
		--lg.setColor(1, 1, 1, 1)
--
		--drawDebug(pageN, 0x80)
		--drawDissassembly(600)

		
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
		elseif k == "-" then pageN = pageN - 1
		elseif k == "=" then pageN = pageN + 1
		elseif k == "f" then bus.clockFrame2() 
		elseif k == "k" then bus.clock() end
	end
end



function drawDebug(page1, page2)
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

	for i = lowerBound, upperBound do
		if disAs[i][2] == cpu.getLastPC() then 
			lg.setColor(252/255, 186/255, 3/255)
			onInst = i
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
		if cpu.getFlag(flags[i]) then
			lg.setColor(.5, 1, .5)
		else
			lg.setColor(1, .5, .5)
		end
		lg.print(flags[i], right_sidebar-10+((i-1)*12), (17 + 7)*20 ) 
	end
	lg.setColor(1, 1, 1)
	lg.print("FPS: ".. love.timer.getFPS(), right_sidebar, (17 + 8)*20 )
end