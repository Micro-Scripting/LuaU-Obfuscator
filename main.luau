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

-- Generate loader
-- local loader = Obfuscator.generate_loader(obf_code, "base64")

-- print(loader) -- This is the obfuscated Lua script ready to run

-- To deobfuscate
-- local original = Obfuscator.deobfuscate(obf_code, "base64")
-- print(original)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Easy to customize with instructions and proper set variable naming
-- Easy to upgrade and add some features into it, probably set some updates

local Obfuscator = {}

-- Base64 encoding
local function base64_encode(data)
    local b64_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2^i - b % 2^(i - 1) > 0 and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0)
        end
        return b64_chars:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

-- Base64 decoding
local function base64_decode(data)
    local b64_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^' .. b64_chars .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', b64_chars:find(x) - 1
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0')
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0)
        end
        return string.char(c)
    end))
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
    if not key or #key == 0 then return text end
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
            return nil, "XOR key is missing"
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
            return nil, "XOR key is missing for deobfuscation"
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
    method = string.upper(method or "")
    key = key or ""
    -- For the parameters on return(function(...) you could just replace the variables with one of them or setup a table and use ...
    local loader_start = ([[ 
return(function(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z)
local env = getfenv()
local OBFUSCATED_CODE = [===[%s]===]
local METHOD = "%s"
local KEY = "%s"
local DECODED
]]):format(obfuscated_code, method, key)

    local decode_section = ""
    if method == "BASE64" then
        decode_section = [[
local b64_chars ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function internal_base64_decode(data)
    data = string.gsub(data, '[^'..b64_chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b64_chars:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%%d%%d%%d?%%d?%%d?%%d?%%d?%%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
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
DECODED = OBFUSCATED_CODE
]] -- Unknown method, just run as is
    end

    local loader_end = [[
local func, err = loadstring(DECODED)
if not func then error("Failed to load obfuscated code: ".. err) end
return func()
end)()
]]

    return loader_start .. decode_section .. loader_end
end

return Obfuscator
