--!nolint
-- String Dumper for 6Vms — extracts strings, constants, opcodes via static analysis

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local filepath = ...

if not filepath or not fs.isFile(filepath) then
    io.stderr:write("usage: lune run mods/lua_string_dump.luau <file>\n")
    os.exit(1)
end

local code = fs.readFile(filepath)
local lines = {}

table.insert(lines, "=" .. string.rep("=", 58))
table.insert(lines, "  6Vms String Dumper — Lua Static Analysis")
table.insert(lines, "=" .. string.rep("=", 58))
table.insert(lines, string.format("  File: %s", filepath))
table.insert(lines, string.format("  Size: %d bytes", #code))
table.insert(lines, "")

-- Check if it's bytecode
if code:sub(1, 4) == "\\x1bLua" or string.byte(code, 1) == 0x1b then
    table.insert(lines, "! Detected compiled Lua bytecode (header: \\x1bLua)")
    table.insert(lines, "  Try .unluac or .d -> unluac Decompiler for decompilation.")
    table.insert(lines, "")
end

-- Extract strings
local strings = {}
for match in code:gmatch('"(([^"\\\\]|\\\\.)*)"') do
    strings[match] = true
end
for match in code:gmatch("'(([^'\\\\]|\\\\.)*)'") do
    strings[match] = true
end

local unique = {}
for s, _ in pairs(strings) do
    table.insert(unique, s)
end
table.sort(unique)

table.insert(lines, string.format("[ Strings Found: %d ]", #unique))
table.insert(lines, string.rep("-", 60))
for i, s in ipairs(unique) do
    local display = s:sub(1, 200)
    if #s > 200 then display = display .. "..." end
    display = display:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    table.insert(lines, string.format("  %4d. \"%s\"", i, display))
end

-- Detect common obfuscator patterns
local patterns = {
    { "loadstring%(game:HttpGet", "Remote loader" },
    { "string%.byte", "Byte encoding" },
    { "string%.char", "Char encoding" },
    { "bit32", "Bitwise ops (common in VMs)" },
    { "bit%.", "Bitwise ops (common in VMs)" },
    { "OP_", "VM opcodes" },
    { "vmdispatch", "VM dispatch" },
    { "LOP_", "Luau opcodes" },
    { "setmetatable", "Metatable usage" },
    { "getfenv", "Environment access" },
    { "newproxy", "Newproxy (Prometheus/etc)" },
    { "loadstring%(game:HttpGet", "Remote execution" },
}

local detected = {}
for _, p in ipairs(patterns) do
    if code:find(p[1]) then
        detected[p[2]] = true
    end
end

local det_list = {}
for k, _ in pairs(detected) do
    table.insert(det_list, k)
end
table.sort(det_list)

if #det_list > 0 then
    table.insert(lines, "")
    table.insert(lines, "[ Detected Patterns ]")
    table.insert(lines, string.rep("-", 60))
    for _, d in ipairs(det_list) do
        table.insert(lines, string.format("  * %s", d))
    end
end

table.insert(lines, "")
table.insert(lines, "=" .. string.rep("=", 58))
table.insert(lines, "  Analysis complete.")
table.insert(lines, "=" .. string.rep("=", 58))

io.write(table.concat(lines, "\n"))
