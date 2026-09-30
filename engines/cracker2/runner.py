from __future__ import annotations

from pathlib import Path
from typing import Optional


def generate_instrumented_runner(deobfuscated_source: str) -> str:
    """
    Generates a fully instrumented Lua 5.1 / Luau script with built-in runtime
    hooks, Roblox API mocks, and standard library polyfills (buffer, bit32) so
    it runs standalone in standard lua.exe, Luau, or Roblox Studio to capture
    all decrypted strings, service accesses, and function calls.
    """
    runner_header = """-- ==============================================================================
--  CRACKER2 DYNAMIC RUNTIME HOOK & INSTRUMENTATION HARNESS
--  Compatible with: Lua 5.1 (lua.exe), Luau, LuaJIT, and Roblox Studio
-- ==============================================================================

local original_print = print
local original_warn = warn or print
local is_internal_logging = false

local CapturedLogs = {
    Strings = {},
    Buffers = {},
    Calls = {}
}

local function LogString(str)
    if is_internal_logging then return end
    if type(str) == "string" and #str > 1 and not CapturedLogs.Strings[str] then
        -- Filter out pure internal numeric noise
        if str:match("^[%d%s%p]+$") and #str < 6 then return end
        CapturedLogs.Strings[str] = true
        original_print("[CAPTURED STRING]: " .. tostring(str))
    end
end

local function LogCall(name, ...)
    if is_internal_logging then return end
    local args = {...}
    local formatted_args = {}
    for i, v in ipairs(args) do
        table.insert(formatted_args, tostring(v))
        if type(v) == "string" then LogString(v) end
    end
    local entry = name .. "(" .. table.concat(formatted_args, ", ") .. ")"
    table.insert(CapturedLogs.Calls, entry)
    original_print("[CAPTURED CALL]: " .. entry)
end

-- ------------------------------------------------------------------------------
-- [1] Standard Library Polyfills (for standalone lua.exe compatibility)
-- ------------------------------------------------------------------------------
if not bit32 then
    bit32 = {}
    local function tobit(x) return x % 4294967296 end
    function bit32.bnot(x) return tobit(4294967295 - (x % 4294967296)) end
    function bit32.band(a, b)
        local res, p = 0, 1
        a, b = a % 4294967296, b % 4294967296
        for i = 1, 32 do
            local ra, rb = a % 2, b % 2
            if ra == 1 and rb == 1 then res = res + p end
            a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
        end
        return res
    end
    function bit32.bor(a, b)
        local res, p = 0, 1
        a, b = a % 4294967296, b % 4294967296
        for i = 1, 32 do
            local ra, rb = a % 2, b % 2
            if ra == 1 or rb == 1 then res = res + p end
            a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
        end
        return res
    end
    function bit32.bxor(a, b)
        local res, p = 0, 1
        a, b = a % 4294967296, b % 4294967296
        for i = 1, 32 do
            local ra, rb = a % 2, b % 2
            if ra ~= rb then res = res + p end
            a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
        end
        return res
    end
    function bit32.lshift(a, b) return tobit(math.floor((a % 4294967296) * (2 ^ b))) end
    function bit32.rshift(a, b) return math.floor((a % 4294967296) / (2 ^ b)) end
end

if not buffer then
    buffer = {}
    local BufferMeta = { __index = buffer }
    function buffer.create(size)
        local b = setmetatable({ data = {}, size = size }, BufferMeta)
        for i = 1, size do b.data[i] = 0 end
        return b
    end
    function buffer.fromstring(s)
        local size = #s
        local b = setmetatable({ data = {}, size = size }, BufferMeta)
        for i = 1, size do b.data[i] = string.byte(s, i) end
        return b
    end
    function buffer.tostring(b)
        local t = {}
        for i = 1, b.size do t[i] = string.char(b.data[i] or 0) end
        local s = table.concat(t)
        LogString(s)
        return s
    end
    function buffer.len(b) return b.size or #b.data end
    function buffer.readu8(b, offset) return b.data[offset + 1] or 0 end
    function buffer.writeu8(b, offset, val) b.data[offset + 1] = val % 256 end
    function buffer.readu32(b, offset)
        local d = b.data
        local o = offset + 1
        return (d[o] or 0) + (d[o + 1] or 0) * 256 + (d[o + 2] or 0) * 65536 + (d[o + 3] or 0) * 16777216
    end
    function buffer.readi16(b, offset)
        local d = b.data
        local o = offset + 1
        local u = (d[o] or 0) + (d[o + 1] or 0) * 256
        if u >= 32768 then return u - 65536 end
        return u
    end
    function buffer.readi32(b, offset)
        local u = buffer.readu32(b, offset)
        if u >= 2147483648 then return u - 4294967296 end
        return u
    end
    function buffer.copy(dst, dst_off, src, src_off, count)
        for i = 0, count - 1 do
            dst.data[dst_off + i + 1] = src.data[src_off + i + 1] or 0
        end
    end
    function buffer.fill(b, off, val, count)
        for i = 0, count - 1 do
            b.data[off + i + 1] = val % 256
        end
    end
end

if not Vector2 then
    Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
end
if not Vector3 then
    Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }
end
if not CFrame then
    CFrame = { new = function(...) return {} end }
end
if not Color3 then
    Color3 = {
        new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
        fromRGB = function(r, g, b) return { R = (r or 0)/255, G = (g or 0)/255, B = (b or 0)/255 } end
    }
end
if not UDim2 then
    UDim2 = { new = function(sx, ox, sy, oy) return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } } end }
end

if not vector then
    vector = {
        create = function(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end,
        zero = { x = 0, y = 0, z = 0 },
        one = { x = 1, y = 1, z = 1 }
    }
end

if not typeof then
    typeof = function(v) return type(v) end
end
if not tick then
    tick = function() return os.time() end
end
if not task then
    task = {
        spawn = function(f, ...) return coroutine.wrap(f)(...) end,
        defer = function(f, ...) return coroutine.wrap(f)(...) end,
        delay = function(d, f, ...) return coroutine.wrap(f)(...) end,
        wait = function() return 0 end,
        cancel = function() end
    }
end

if not table.pack then
    table.pack = function(...) return { n = select("#", ...), ... } end
end
if not table.unpack then
    table.unpack = unpack
end
if not table.move then
    table.move = function(a1, f, e, t, a2)
        a2 = a2 or a1
        for i = 0, e - f do a2[t + i] = a1[f + i] end
        return a2
    end
end
if not table.create then
    table.create = function(count, val)
        local t = {}
        for i = 1, count do t[i] = val end
        return t
    end
end
if not table.clone then
    table.clone = function(t)
        local c = {}
        for k, v in pairs(t) do c[k] = v end
        return c
    end
end

-- ------------------------------------------------------------------------------
-- [2] Roblox Environment Mocks
-- ------------------------------------------------------------------------------
if not game then
    local ServiceMock = {}
    ServiceMock.__index = function(t, k)
        return function(...)
            LogCall(t.Name .. "." .. tostring(k), ...)
            return ServiceMock
        end
    end
    game = {
        GetService = function(self, name)
            LogString(tostring(name))
            LogCall("game:GetService", name)
            return setmetatable({ Name = name }, ServiceMock)
        end,
        HttpGet = function(self, url)
            LogString(tostring(url))
            LogCall("game:HttpGet", url)
            return ""
        end
    }
    workspace = setmetatable({ Name = "Workspace" }, ServiceMock)
    script = setmetatable({ Name = "Script" }, ServiceMock)
    Instance = {
        new = function(className, parent)
            LogString(tostring(className))
            LogCall("Instance.new", className, parent)
            return setmetatable({ ClassName = className, Parent = parent }, ServiceMock)
        end
    }
end

-- ------------------------------------------------------------------------------
-- [3] Dynamic Hooks
-- ------------------------------------------------------------------------------
print = function(...)
    if not is_internal_logging then
        LogCall("print", ...)
    end
    return original_print(...)
end

warn = function(...)
    if not is_internal_logging then
        LogCall("warn", ...)
    end
    return original_warn(...)
end

local original_concat = table.concat
table.concat = function(t, sep, i, j)
    local s = original_concat(t, sep or "", i, j)
    if #s > 3 and not is_internal_logging then
        LogString(s)
    end
    return s
end

original_print("[*] Starting instrumented VM execution...")

local success, result = pcall(function(...)
    return (function(...)
"""

    runner_footer = """
    end)(...)
end, ...)

if success and type(result) == "function" then
    original_print("[*] VM initialized successfully. Executing main payload closure...")
    local run_success, run_result = pcall(result, ...)
    if not run_success then
        original_print("[!] Runtime error in inner payload: " .. tostring(run_result))
    end
end

is_internal_logging = true

original_print("[*] VM Execution finished. Status: " .. (success and "SUCCESS" or "ERROR"))
if not success then
    original_print("[!] Runtime error (captured safely): " .. tostring(result))
end

original_print("================================================================================")
original_print("                           DYNAMIC CAPTURE SUMMARY                              ")
original_print("[+] Total Unique Strings Captured: " .. (function()
    local c = 0
    for _ in pairs(CapturedLogs.Strings) do c = c + 1 end
    return c
end)())

for s in pairs(CapturedLogs.Strings) do
    original_print("  * " .. string.format("%q", s))
end

original_print("[+] Total Calls Intercepted: " .. #CapturedLogs.Calls)
for _, c in ipairs(CapturedLogs.Calls) do
    original_print("  > " .. c)
end
original_print("================================================================================")
"""

    return runner_header + "\n" + deobfuscated_source + "\n" + runner_footer


def create_instrumented_runner_file(deobfuscated_source: str, output_path: str | Path) -> Path:
    out = Path(output_path)
    content = generate_instrumented_runner(deobfuscated_source)
    out.write_text(content, encoding="utf-8")
    return out
