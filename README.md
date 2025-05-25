# Obfuscator
Simple yet effective obfuscator with techniques developed in pure Roblox LuaU by Micro
Techniques: ASCII, HEX, BINARY, G-CODE, URL and BASE64
This script is to be used as a ModuleScript
Please give credits when forking / modifying the script

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WHAT IT HAS: MINIFICATION, STRING ENCRYPTION AND FUNCTION RENAMING
WHAT IT DOES NOT HAVE: CONTROL FLOW, ANTI-TAMPER, DUMMY CODE AND VIRTUAL MACHINE

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
HOW TO USE?

local Obfuscator = require("obfuscator")

local lua_code = [[ print("Hello World!") ]]

Obfuscate with base64 or whatever method of obfuscation you like to use
local obf_code = Obfuscator.obfuscate(lua_code, "base64")

Generate loader
local loader = Obfuscator.generate_loader(obf_code, "base64")

print(loader) This is the obfuscated Lua script ready to run

To deobfuscate
local original = Obfuscator.deobfuscate(obf_code, "base64")
print(original)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Easy to customize with instructions and proper set variable naming
Easy to upgrade and add some features into it, probably set some updates
