--controler.lua

inputCont = {}
	
keybinds = {"d","a","s","w","9","0","m","n"}
local inputContState
--port 4016, 4017

inputCont.getState = function()
	outByte = 0
	if love.keyboard.isDown(keybinds[1]) then outByte = outByte + 0x01 end	
	if love.keyboard.isDown(keybinds[2]) then outByte = outByte + 0x02 end	
	if love.keyboard.isDown(keybinds[3]) then outByte = outByte + 0x04 end	
	if love.keyboard.isDown(keybinds[4]) then outByte = outByte + 0x08 end	
	if love.keyboard.isDown(keybinds[5]) then outByte = outByte + 0x10 end	
	if love.keyboard.isDown(keybinds[6]) then outByte = outByte + 0x20 end	
	if love.keyboard.isDown(keybinds[7]) then outByte = outByte + 0x40 end	
	if love.keyboard.isDown(keybinds[8]) then outByte = outByte + 0x80 end
	inputContState = outByte
	return outByte	
end


inputCont.readByte = function()
	return inputContState

end
inputCont.writeByte = function()
	local outByte = 0
	if love.keyboard.isDown(keybinds[1]) then outByte = outByte + 1 end	
	if love.keyboard.isDown(keybinds[2]) then outByte = outByte + 2 end	
	if love.keyboard.isDown(keybinds[3]) then outByte = outByte + 4 end	
	if love.keyboard.isDown(keybinds[4]) then outByte = outByte + 8 end	
	if love.keyboard.isDown(keybinds[5]) then outByte = outByte + 16 end	
	if love.keyboard.isDown(keybinds[6]) then outByte = outByte + 32 end	
	if love.keyboard.isDown(keybinds[7]) then outByte = outByte + 64 end	
	if love.keyboard.isDown(keybinds[8]) then outByte = outByte + 128 end
	return outByte	
end


return inputCont