chars = {}
charTable = {}
binTable = {}
binaryToInt = {}
charToInt = {}
charToString = {}
binaryToChar = {}
charToBinary = {}
intToBinary = {}
intToChar = {}
intToString = {}
stringToChar = {}
stringToInt = {}


function init()

	for i = 0, 255 do
		num = i
		bstring = ""
		
		for j = 0, 7 do
			if num >= 1 then 
				bstring = tostring(num%2) .. bstring
				num = math.floor(num/2)
			else
				bstring = "0" .. bstring
			end
		end
		print(i, bstring, string.char(i))
		stringToChar[bstring] = string.char(i)
		stringToInt[bstring] = i
		intToChar[i] = string.char(i)
		intToString[i] = bstring
		charToInt[string.char(i)] = i
		charToString[string.char(i)] = bstring

	end
	binaryToChar = stringToChar
	binaryToInt = stringToInt
	intToBinary = intToString
	charToBinary = charToString
end

function newByte(value, sw1, sw2)
	b = {}
	b.sw1 = sw1 or nil
	b.sw2 = sw2 or nil
	b.value = "+"
	
	if b.sw1 == nil and b.sw2 == nil then
		if type(value) == "string" then
			if string.len(value) > 1 then
				b.value = stringToChar[value]
			else
				b.value = value
			end
		elseif type(value) == "number" then
			b.value = intToChar[value]
		end
	elseif b.sw1 ~= nil then 
		if type(value) == "string" then
			if string.len(value) == 1 then
				b.value = value
			elseif string.len(value) <= 7 then
				b.value = stringToChar["0" .. value]
			else
				b.value = stringToChar["0" .. string.sub(value, 2)]
			end
		elseif type(value) == "number" then
			if value >= 256/2 then
				b.value = intToChar[value/2]
			else
				b.value = intToChar[value]
			end
		end
	else
		if type(value) == "string" then
			if string.len(value) == 1 then
				b.value = value
			elseif string.len(value) <= 6 then
				b.value = stringToChar["0" .. "0" .. value]
			elseif string.len(value) <= 7 then
				b.value = stringToChar["0" .. string.sub(value, 2)]
			else
				b.value = stringToChar["0" .. "0" .. string.sub(value, 3)]
			end

		elseif type(value) == "number" then
			if value >= (256/2)/2 then
				b.value = intToChar[(value/2)/2]
			elseif value >= (256/2) then
				b.value = intToChar[(value/2)]
			else
				b.value = intToChar[value]
			end
		end
	end

	b.getValue = function()
		return b.value
	end

	b.set = function (value, sw1, sw2)
		b.sw1 = sw1 or nil
		b.sw2 = sw2 or nil
		b.value = "+"
		
		if b.sw1 == nil and b.sw2 == nil then
			if type(value) == "string" then
				if string.len(value) > 1 then
					b.value = stringToChar[value]
				else
					b.value = value
				end
			elseif type(value) == "number" then
				b.value = intToChar[value]
			end
		elseif b.sw1 ~= nil then 
			if type(value) == "string" then
				if string.len(value) == 1 then
					b.value = value
				elseif string.len(value) <= 7 then
					b.value = stringToChar["0" .. value]
				else
					b.value = stringToChar["0" .. string.sub(value, 2)]
				end
			elseif type(value) == "number" then
				if value >= 256/2 then
					b.value = intToChar[value/2]
				else
					b.value = intToChar[value]
				end
			end
		else
			if type(value) == "string" then
				if string.len(value) == 1 then
					b.value = value
				elseif string.len(value) <= 6 then
					b.value = stringToChar["0" .. "0" .. value]
				elseif string.len(value) <= 7 then
					b.value = stringToChar["0" .. string.sub(value, 2)]
				else
					b.value = stringToChar["0" .. "0" .. string.sub(value, 3)]
				end

			elseif type(value) == "number" then
				if value >= (256/2)/2 then
					b.value = intToChar[(value/2)/2]
				elseif value >= (256/2) then
					b.value = intToChar[(value/2)]
				else
					b.value = intToChar[value]
				end
			end
		end
	end

	return b
end


function byteToInt (b)
	return string.byte(b.value)
end

function byteToHex (b)
	return string.format("%x", byteToInt (b)) -- "7F"
end

function byteToBinary(b)
	return charToString[b.value]
end

function byteToChar(b)
	return b.value
end

function editByte(b, newValue)
	b.set(newValue)
	return b
end

function frontHalfInt(b)
	bs = byteToBinary(b)
	bs = string.sub(bs, 1, 4)
	bs = "0000" .. bs
	return binaryToInt[bs]
end

function backHalfInt(b)
	bs = byteToBinary(b)
	bs = string.sub(bs, 5)
	bs = "0000" .. bs
	print(bs)
	return binaryToInt[bs]
end
init()