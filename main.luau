-- Simple yet effective obfuscator with techniques developed in pure Roblox LuaU by Micro
-- Techniques: ASCII, HEX, BINARY, G-CODE, URL and BASE64
-- This script is to be used as a ModuleScript
-- Please give credits when forking / modifying the script

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- WHAT IT HAS: MINIFICATION, STRING ENCRYPTION AND FUNCTION RENAMING
-- WHAT IT DOES NOT HAVE: CONTROL FLOW, ANTI-TAMPER, DUMMY CODE AND VIRTUAL MACHINE

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HOW TO USE?

-- local Obfuscator = require("obfuscator")

-- local lua_code = [[ print("Hello World!") ]]

-- Obfuscate with base64 or whatever method of obfuscation you like to use
-- local obf_code = Obfuscator.obfuscate(lua_code, "base64")
-- For XOR, provide a key:
-- local obf_code, err = Obfuscator.obfuscate(lua_code, "XOR", "mySecretKey")


-- Generate loader
-- local loader = Obfuscator.generate_loader(obf_code, "base64")
-- For XOR, provide the key to the loader as well:
-- local loader, err = Obfuscator.generate_loader(obf_code, "XOR", "mySecretKey")

-- print(loader) -- This is the obfuscated Lua script ready to run

-- To deobfuscate
-- local original = Obfuscator.deobfuscate(obf_code, "base64")
-- For XOR:
-- local original, err = Obfuscator.deobfuscate(obf_code, "XOR", "mySecretKey")
-- print(original)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Easy to customize with instructions and proper set variable naming
-- Easy to upgrade and add some features into it, probably set some updates

local Obfuscator = {}

-- Base64 constants (moved here to be shared and corrected)
local b64_chars_const = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64_decode_map_const = {}
for i = 1, #b64_chars_const do
    b64_decode_map_const[b64_chars_const:sub(i,i)] = i - 1
end

-- Base64 encoding (Corrected using bit32)
local function base64_encode(data)
	if type(data) ~= "string" then return nil, "Input to base64_encode must be a string" end
	local result = {}
	local len = #data

	for i = 1, len, 3 do
		local byte1 = string.byte(data, i)
		local byte2 = (i + 1 <= len) and string.byte(data, i + 1) or nil
		local byte3 = (i + 2 <= len) and string.byte(data, i + 2) or nil

		table.insert(result, b64_chars_const:sub(bit32.rshift(byte1, 2) + 1, bit32.rshift(byte1, 2) + 1))
		
		if byte2 then
			table.insert(result, b64_chars_const:sub(bit32.bor(bit32.lshift(bit32.band(byte1, 0x03), 4), bit32.rshift(byte2, 4)) + 1, bit32.bor(bit32.lshift(bit32.band(byte1, 0x03), 4), bit32.rshift(byte2, 4)) + 1))
			if byte3 then
				table.insert(result, b64_chars_const:sub(bit32.bor(bit32.lshift(bit32.band(byte2, 0x0F), 2), bit32.rshift(byte3, 6)) + 1, bit32.bor(bit32.lshift(bit32.band(byte2, 0x0F), 2), bit32.rshift(byte3, 6)) + 1))
				table.insert(result, b64_chars_const:sub(bit32.band(byte3, 0x3F) + 1, bit32.band(byte3, 0x3F) + 1))
			else 
				table.insert(result, b64_chars_const:sub(bit32.lshift(bit32.band(byte2, 0x0F), 2) + 1, bit32.lshift(bit32.band(byte2, 0x0F), 2) + 1))
				table.insert(result, "=")
			end
		else 
			table.insert(result, b64_chars_const:sub(bit32.lshift(bit32.band(byte1, 0x03), 4) + 1, bit32.lshift(bit32.band(byte1, 0x03), 4) + 1))
			table.insert(result, "=")
			table.insert(result, "=")
		end
	end
	return table.concat(result)
end

-- Base64 decoding (Corrected using bit32)
local function base64_decode(data)
	if type(data) ~= "string" then return nil, "Input to base64_decode must be a string" end
	data = string.gsub(data, '[^'..b64_chars_const..'=]', '') 

	local result = {}
	local len = #data
	if len % 4 ~= 0 then
		return nil, "Invalid Base64 string length for decoding (must be multiple of 4)"
	end

	for i = 1, len, 4 do
		local char1_val = b64_decode_map_const[data:sub(i, i)]
		local char2_val = b64_decode_map_const[data:sub(i+1, i+1)]
		local char3_str = data:sub(i+2, i+2)
		local char4_str = data:sub(i+3, i+3)

		if char1_val == nil or char2_val == nil then
			 return nil, "Invalid character in Base64 string for decoding"
		end

		local byte1 = bit32.bor(bit32.lshift(char1_val, 2), bit32.rshift(char2_val, 4))
		table.insert(result, string.char(byte1))

		if char3_str ~= "=" then
			local char3_val = b64_decode_map_const[char3_str]
			if char3_val == nil then return nil, "Invalid character in Base64 string for decoding" end
			
			local byte2 = bit32.bor(bit32.lshift(bit32.band(char2_val, 0x0F), 4), bit32.rshift(char3_val, 2))
			table.insert(result, string.char(byte2))

			if char4_str ~= "=" then
				local char4_val = b64_decode_map_const[char4_str]
				if char4_val == nil then return nil, "Invalid character in Base64 string for decoding" end

				local byte3 = bit32.bor(bit32.lshift(bit32.band(char3_val, 0x03), 6), char4_val)
				table.insert(result, string.char(byte3))
			end
		end
	end
	return table.concat(result)
end

-- ASCII encode (space separated decimal bytes)
local function ascii_encode(str)
	local bytes = {}
	for i = 1, #str do
		table.insert(bytes, tostring(string.byte(str, i)))
	end
	return table.concat(bytes, " ")
end

-- ASCII decode (space separated decimal bytes)
local function ascii_decode(data)
	local chars = {}
	for num_str in string.gmatch(data, "%d+") do
		table.insert(chars, string.char(tonumber(num_str)))
	end
	return table.concat(chars)
end

-- Hex encode
local function hex_encode(str)
	return (str:gsub('.', function(c)
		return string.format('%02x', string.byte(c))
	end))
end

-- Hex decode
local function hex_decode(hex)
	return (hex:gsub('..', function(cc)
		return string.char(tonumber(cc, 16))
	end))
end

-- Binary encode (space separated bytes as bits)
local function binary_encode(str)
	local bin_str = ""
	for i = 1, #str do
		local byte = string.byte(str, i)
		local bits = ""
		for j = 7, 0, -1 do
			bits = bits .. (math.floor(byte / 2^j) % 2)
		end
		bin_str = bin_str .. bits .. (i == #str and "" or " ")
	end
	return bin_str
end

-- Binary decode (ignores spaces, parses bits 8 by 8)
local function binary_decode(bin_str)
	local text = ""
	bin_str = bin_str:gsub("%s+", "")
	for i = 1, #bin_str, 8 do
		local byte_str = bin_str:sub(i, i + 7)
		if #byte_str == 8 then
			text = text .. string.char(tonumber(byte_str, 2))
		end
	end
	return text
end

-- XOR cipher (same function for encode and decode)
local function xor_cipher(text, key)
	if not key or #key == 0 then return text end -- Note: if key is empty, original text is returned. Consider if this is desired.
	local res = {}
	for i = 1, #text do
		local x = bit32.bxor(string.byte(text, i), string.byte(key, ((i - 1) % #key) + 1))
		res[i] = string.char(x)
	end
	return table.concat(res)
end

-- URL Encode
local function url_encode(str)
	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w _%%%-%.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	str = str:gsub(" ", "+")
	return str
end

-- URL Decode
local function url_decode(str)
	str = str:gsub("+", " ")
	str = str:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end)
	return str
end

-- G-code encode: ASCII code to zero-padded 3-digit numbers
local function gcode_encode(str)
	local codes = {}
	for i = 1, #str do
		table.insert(codes, string.format("%03d", string.byte(str, i)))
	end
	return table.concat(codes)
end

-- G-code decode: 3-digit groups back to chars
local function gcode_decode(str)
	local chars = {}
	for i = 1, #str, 3 do
		local chunk = str:sub(i, i + 2)
		if #chunk == 3 then
			table.insert(chars, string.char(tonumber(chunk)))
		end
	end
	return table.concat(chars)
end

-- Obfuscate using chosen method and optional key (for XOR)
function Obfuscator.obfuscate(code, method, key)
	method = string.upper(method or "")
	if method == "BASE64" then
		return base64_encode(code)
	elseif method == "ASCII" then
		return ascii_encode(code)
	elseif method == "HEX" then
		return hex_encode(code)
	elseif method == "BINARY" then
		return binary_encode(code)
	elseif method == "XOR" then
		if not key or #key == 0 then
			return nil, "XOR key is missing or empty"
		end
		return xor_cipher(code, key)
	elseif method == "URL" then
		return url_encode(code)
	elseif method == "GCODE" then
		return gcode_encode(code)
	else
		return nil, "Unknown obfuscation method: " .. method
	end
end

-- Deobfuscate using chosen method and optional key (for XOR)
function Obfuscator.deobfuscate(obfuscated_code, method, key)
	method = string.upper(method or "")
	if method == "BASE64" then
		return base64_decode(obfuscated_code)
	elseif method == "ASCII" then
		return ascii_decode(obfuscated_code)
	elseif method == "HEX" then
		return hex_decode(obfuscated_code)
	elseif method == "BINARY" then
		return binary_decode(obfuscated_code)
	elseif method == "XOR" then
		if not key or #key == 0 then
			return nil, "XOR key is missing or empty for deobfuscation"
		end
		return xor_cipher(obfuscated_code, key)
	elseif method == "URL" then
		return url_decode(obfuscated_code)
	elseif method == "GCODE" then
		return gcode_decode(obfuscated_code)
	else
		return nil, "Unknown deobfuscation method: " .. method
	end
end

-- Minify Lua code (remove comments and unnecessary whitespace)
function Obfuscator.minify(code)
	code = code:gsub("%-%-%[%[.-%]%]", "") -- Remove multi-line comments
	code = code:gsub("%-%-[^\r\n]*", "")   -- Remove single-line comments
	code = code:gsub("[\r\n]+", "\n")      -- Normalize newlines
	code = code:gsub("\n%s+", "\n")        -- Remove leading whitespace on lines
	code = code:gsub("%s+\n", "\n")        -- Remove trailing whitespace on lines
	code = code:gsub("%s+", " ")            -- Collapse spaces
	code = code:gsub("^%s+", ""):gsub("%s+$", "") -- Trim start/end spaces
	return code
end

-- Generate loader Lua code that decodes and runs the obfuscated code
function Obfuscator.generate_loader(obfuscated_code, method, key)
    -- Add check for nil obfuscated_code
    if obfuscated_code == nil then
        return nil, "Cannot generate loader: obfuscated_code is nil. This often means obfuscation failed or was not performed correctly (e.g. missing key for XOR)."
    end

	method = string.upper(method or "")
	key = key or "" -- Ensure key is a string (empty if nil) for the loader template

	local loader_start = ([[ 
return(function(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z)
local env = getfenv()
local OBFUSCATED_CODE = [===[%s]===]
local METHOD = "%s"
local KEY = [===[%s]===] -- Changed to safely embed key
local DECODED
]]):format(obfuscated_code, method, key)

	local decode_section = ""
	if method == "BASE64" then
		decode_section = [[
local b64_chars_loader = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64_decode_map_loader = {}
for i = 1, #b64_chars_loader do
    b64_decode_map_loader[b64_chars_loader:sub(i,i)] = i - 1
end
local function internal_base64_decode(data)
    if type(data) ~= "string" then return "" end 
    data = string.gsub(data, '[^'..b64_chars_loader..'=]', '') 
    local result = {}
    local len = #data
    if len % 4 ~= 0 then return "" end

    for i = 1, len, 4 do
        local char1_val = b64_decode_map_loader[data:sub(i, i)]
        local char2_val = b64_decode_map_loader[data:sub(i+1, i+1)]
        local char3_str = data:sub(i+2, i+2)
        local char4_str = data:sub(i+3, i+3)

        if char1_val == nil or char2_val == nil then return "" end

        local byte1 = bit32.bor(bit32.lshift(char1_val, 2), bit32.rshift(char2_val, 4))
        table.insert(result, string.char(byte1))

        if char3_str ~= "=" then
            local char3_val = b64_decode_map_loader[char3_str]
            if char3_val == nil then return "" end
            
            local byte2 = bit32.bor(bit32.lshift(bit32.band(char2_val, 0x0F), 4), bit32.rshift(char3_val, 2))
            table.insert(result, string.char(byte2))

            if char4_str ~= "=" then
                local char4_val = b64_decode_map_loader[char4_str]
                if char4_val == nil then return "" end

                local byte3 = bit32.bor(bit32.lshift(bit32.band(char3_val, 0x03), 6), char4_val)
                table.insert(result, string.char(byte3))
            end
        end
    end
    return table.concat(result)
end
DECODED = internal_base64_decode(OBFUSCATED_CODE)
]]
	elseif method == "ASCII" then
		decode_section = [[
local function internal_ascii_decode(data)
    local chars = {}
    for num_str in string.gmatch(data, '%d+') do
        table.insert(chars, string.char(tonumber(num_str)))
    end
    return table.concat(chars)
end
DECODED = internal_ascii_decode(OBFUSCATED_CODE)
]]
	elseif method == "HEX" then
		decode_section = [[
local function internal_hex_decode(hex)
    return (hex:gsub('..', function(cc)
        return string.char(tonumber(cc,16))
    end))
end
DECODED = internal_hex_decode(OBFUSCATED_CODE)
]]
	elseif method == "BINARY" then
		decode_section = [[
local function internal_binary_decode(bin_str)
    local text = ""
    bin_str = bin_str:gsub("%s+", "")
    for i=1,#bin_str,8 do
        local byte_str = bin_str:sub(i,i+7)
        if (#byte_str == 8) then
            text = text..string.char(tonumber(byte_str,2))
        end
    end
    return text
end
DECODED = internal_binary_decode(OBFUSCATED_CODE)
]]
	elseif method == "XOR" then
		decode_section = [[
local function internal_xor_cipher(text,key)
    if not key or #key == 0 then return text end -- Added check for empty key in loader
    local res = {}
    for i=1,#text do
        local x = bit32.bxor(string.byte(text,i), string.byte(key, ((i-1) % #key)+1))
        res[i] = string.char(x)
    end
    return table.concat(res)
end
DECODED = internal_xor_cipher(OBFUSCATED_CODE, KEY)
]]
	elseif method == "URL" then
		decode_section = [[
local function internal_url_decode(str)
    str = str:gsub("+"," ")
    str = str:gsub("%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    return str
end
DECODED = internal_url_decode(OBFUSCATED_CODE)
]]
	elseif method == "GCODE" then
		decode_section = [[
local function internal_gcode_decode(str)
    local chars = {}
    for i=1,#str,3 do
        local chunk = str:sub(i,i+2)
        if (#chunk == 3) then
            table.insert(chars, string.char(tonumber(chunk)))
        end
    end
    return table.concat(chars)
end
DECODED = internal_gcode_decode(OBFUSCATED_CODE)
]]
	else
		decode_section = [[
DECODED = OBFUSCATED_CODE -- Unknown method, loader will try to run it as is.
]]
	end

	local loader_end = [[
local func, err = loadstring(DECODED)
if not func then error("Failed to load obfuscated code from loader: ".. (err or "Unknown error")) end
return func()
end)()
]]

	return loader_start .. decode_section .. loader_end
end

return Obfuscator
