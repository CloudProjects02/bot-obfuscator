import re
import sys
import subprocess
import time
import os
import glob
import math
import tempfile
import shutil


COMPOUND_ASSIGNMENT_OPERATORS = ("+=", "-=", "*=", "/=", "%=", "..=")
LUA_CONTROL_STRUCTURE_TOO_LONG = "control structure too long"


def get_lua_executable():
    if os.name == "nt":
        return os.path.join("lua_bin", "lua5.1.exe")

    env_path = os.environ.get("LUA51_EXECUTABLE")
    if env_path:
        return env_path

    for candidate in ("lua5.1", "lua51", "lua"):
        path = shutil.which(candidate)
        if path:
            return path

    return "lua5.1"


def _find_table_literal_end(content, open_brace_index):
    depth = 0
    quote = None
    idx = open_brace_index

    while idx < len(content):
        char = content[idx]

        if quote:
            if char == "\\":
                idx += 2
                continue
            if char == quote:
                quote = None
            idx += 1
            continue

        if char in ("'", '"'):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return idx + 1

        idx += 1

    return -1


def extract_static_constants(content, var_name):
    table_match = re.search(rf'\blocal\s+{re.escape(var_name)}\s*=\s*\{{', content)
    if not table_match:
        return ""

    open_brace_index = content.find("{", table_match.start())
    table_end = _find_table_literal_end(content, open_brace_index)
    if table_end == -1:
        return ""

    lua_code = r'''
local function escape_lua_string(s)
    local parts = {'"'}
    for i = 1, #s do
        local byte = string.byte(s, i)
        if byte == 92 then
            table.insert(parts, "\\\\")
        elseif byte == 34 then
            table.insert(parts, "\\\"")
        elseif byte == 10 then
            table.insert(parts, "\\n")
        elseif byte == 13 then
            table.insert(parts, "\\r")
        elseif byte == 9 then
            table.insert(parts, "\\t")
        elseif byte >= 32 and byte <= 126 then
            table.insert(parts, string.char(byte))
        else
            table.insert(parts, string.format("\\%03d", byte))
        end
    end
    table.insert(parts, '"')
    return table.concat(parts)
end

local constants = __STATIC_TABLE__
local out = "local Constants = {"
for i, v in ipairs(constants) do
    out = out .. " [" .. i .. "] = " .. escape_lua_string(v) .. ","
end
out = out .. " }"
print(out)
'''.replace("__STATIC_TABLE__", content[open_brace_index:table_end])

    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        suffix=".lua",
        delete=False,
    ) as temp_handle:
        temp_path = temp_handle.name
        temp_handle.write(lua_code)

    try:
        process = subprocess.run(
            [get_lua_executable(), temp_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=20,
        )
        if process.returncode == 0:
            return process.stdout.decode("utf-8", errors="replace").strip()
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    return ""


def _configure_text_streams():
    for stream_name in ("stdout", "stderr"):
        stream = getattr(sys, stream_name, None)
        if stream is None or not hasattr(stream, "reconfigure"):
            continue
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass


def _find_compound_lhs_start(content, operator_index):
    idx = operator_index - 1
    while idx >= 0 and content[idx].isspace():
        idx -= 1

    while idx >= 0 and content[idx] == "]":
        bracket_depth = 1
        idx -= 1
        while idx >= 0 and bracket_depth > 0:
            if content[idx] == "]":
                bracket_depth += 1
            elif content[idx] == "[":
                bracket_depth -= 1
            idx -= 1

    while idx >= 0 and (content[idx].isalnum() or content[idx] == "_"):
        idx -= 1

    while idx >= 0 and content[idx] == ".":
        idx -= 1
        while idx >= 0 and content[idx] == "]":
            bracket_depth = 1
            idx -= 1
            while idx >= 0 and bracket_depth > 0:
                if content[idx] == "]":
                    bracket_depth += 1
                elif content[idx] == "[":
                    bracket_depth -= 1
                idx -= 1
        while idx >= 0 and (content[idx].isalnum() or content[idx] == "_"):
            idx -= 1

    return idx + 1


def _find_compound_rhs_end(content, rhs_start):
    idx = rhs_start
    length = len(content)
    bracket_depth = 0
    paren_depth = 0
    brace_depth = 0
    quote = None

    while idx < length and content[idx].isspace():
        idx += 1

    while idx < length:
        char = content[idx]

        if quote:
            if char == "\\":
                idx += 2
                continue
            if char == quote:
                quote = None
            idx += 1
            continue

        if char in ("'", '"'):
            quote = char
            idx += 1
            continue

        if char == "[":
            bracket_depth += 1
        elif char == "]":
            bracket_depth = max(0, bracket_depth - 1)
        elif char == "(":
            paren_depth += 1
        elif char == ")":
            if paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                break
            paren_depth = max(0, paren_depth - 1)
        elif char == "{":
            brace_depth += 1
        elif char == "}":
            if brace_depth == 0 and bracket_depth == 0 and paren_depth == 0:
                break
            brace_depth = max(0, brace_depth - 1)
        elif bracket_depth == 0 and paren_depth == 0 and brace_depth == 0:
            if char in ";,\n\r":
                break
            if char.isspace():
                break

        idx += 1

    return idx


def normalize_luau_syntax(content):
    replacements = []
    idx = 0

    while idx < len(content):
        matched_operator = None
        for operator in COMPOUND_ASSIGNMENT_OPERATORS:
            if content.startswith(operator, idx):
                matched_operator = operator
                break

        if not matched_operator:
            idx += 1
            continue

        lhs_start = _find_compound_lhs_start(content, idx)
        rhs_start = idx + len(matched_operator)
        rhs_end = _find_compound_rhs_end(content, rhs_start)

        lhs = content[lhs_start:idx].strip()
        rhs = content[rhs_start:rhs_end].strip()
        if lhs and rhs:
            replacements.append(
                (lhs_start, rhs_end, f"{lhs} = {lhs} {matched_operator[:-1]} {rhs}")
            )
        idx = rhs_end

    if not replacements:
        return content

    rewritten = content
    for start, end, replacement in reversed(replacements):
        rewritten = rewritten[:start] + replacement + rewritten[end:]

    return rewritten


_configure_text_streams()

def deobfuscate_file(filepath):
    print(f"Processing {filepath}...")
    
    if ".deobf." in filepath or ".report." in filepath:
        return
        
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return

    content = normalize_luau_syntax(content)

    match = re.search(r'local ([a-zA-Z0-9_]+)=\{"', content)
    if not match:
        print(f"Could not identify string table variable in {filepath}.")
        return
    var_name = match.group(1)
    static_constants = extract_static_constants(content, var_name)

    mock_env_code = r"""
local real_type = type
local real_tonumber = tonumber
local real_unpack = unpack
local real_concat = table.concat
local real_tostring = tostring
local real_print = print

local _WAIT_COUNT = 0
local _LOOP_COUNTER = 0
local _MAX_LOOPS = 150
local _LOOP_BODIES = {}

local function _check_loop()
    _LOOP_COUNTER = _LOOP_COUNTER + 1
    if _LOOP_COUNTER > _MAX_LOOPS then
        return false
    end
    return true
end

local function type(v)
    local mt = getmetatable(v)
    if mt and mt.__is_mock_dummy then
        return "userdata"
    end
    return real_type(v)
end

local function typeof(v)
    local mt = getmetatable(v)
    if mt and mt.__is_mock_dummy then
        return "Instance"
    end
    return type(v)
end

local function tonumber(v, base)
    if type(v) == "userdata" or (type(v) == "table" and getmetatable(v) and getmetatable(v).__is_mock_dummy) then
        return 1
    end
    return real_tonumber(v, base)
end

local function unpack(t, i, j)
    if real_type(t) == "table" then
        local looks_like_chunk = true
        for k, v in pairs(t) do
            if real_type(k) ~= "number" then looks_like_chunk = false break end
        end
        
        if looks_like_chunk and #t > 0 then
            print("UNPACK CALLED WITH TABLE (Potential Chunk): size=" .. #t)
            local success, res = pcall(real_concat, t, ",")
            if success then
                print("CAPTURED CHUNK STRING: " .. res)
                local url = res:match("https?://[%w%.%-%/%?%_%=%&%:]+") or res:match("www%.[%w%.%-%/%?%_%=%&%:]+")
                if url then
                    print("URL DETECTED IN UNPACK --> " .. url)
                end
            end
        end
    end
    return real_unpack(t, i, j)
end

local function table_concat(t, sep, i, j)
    local res = real_concat(t, sep, i, j)
    if real_type(res) == "string" then
        local url = res:match("https?://[%w%.%-%/%?%_%=%&%:]+") or res:match("www%.[%w%.%-%/%?%_%=%&%:]+")
        if url then
            print("URL DETECTED IN CONCAT --> " .. url)
        end
    end
    return res
end

local function escape_lua_string(s)
    local parts = {'"'}
    for i = 1, #s do
        local byte = string.byte(s, i)
        if byte == 92 then
            table.insert(parts, "\\\\")
        elseif byte == 34 then
            table.insert(parts, "\\\"")
        elseif byte == 10 then
            table.insert(parts, "\\n")
        elseif byte == 13 then
            table.insert(parts, "\\r")
        elseif byte == 9 then
            table.insert(parts, "\\t")
        elseif byte >= 32 and byte <= 126 then
            table.insert(parts, string.char(byte))
        else
            table.insert(parts, string.format("\\%03d", byte))
        end
    end
    table.insert(parts, '"')
    return table.concat(parts)
end

local function recursive_tostring(v, depth)
    if depth == nil then depth = 0 end
    if depth > 2 then return tostring(v) end
    
    if real_type(v) == "string" then
        return escape_lua_string(v)
    elseif real_type(v) == "number" then
        if v == math.floor(v) and v >= -2147483648 and v <= 2147483647 then
            return tostring(math.floor(v))
        end
        return tostring(v)
    elseif real_type(v) == "boolean" then
        return tostring(v)
    elseif v == nil then
        return "nil"
    elseif real_type(v) == "table" then
        if getmetatable(v) and getmetatable(v).__is_mock_dummy then
            return tostring(v)
        end
        local parts = {}
        local keys = {}
        for k in pairs(v) do table.insert(keys, k) end
        table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)

        for _, k in ipairs(keys) do
            local val = v[k]
            local k_str = tostring(k)
            if real_type(k) == "string" then k_str = '["' .. k .. '"]' end
            table.insert(parts, k_str .. " = " .. recursive_tostring(val, depth + 1))
        end
        return "{" .. real_concat(parts, ", ") .. "}"
    elseif real_type(v) == "function" then
        return tostring(v)
    else
        return tostring(v)
    end
end

local function create_dummy(name)
    local d = {}
    local mt = {
        __is_mock_dummy = true,
        __index = function(_, k)
             print("ACCESSED --> " .. name .. "." .. k)
             if k == "HttpGet" or k == "HttpGetAsync" then
                 return function(_, url, ...)
                     print("URL DETECTED --> " .. tostring(url))
                     return create_dummy("HttpGetResult")
                 end
            end
            return create_dummy(name .. "." .. k)
        end,
        __newindex = function(_, k, v)
            local val_str = recursive_tostring(v, 0)
            print("PROP_SET --> " .. name .. "." .. k .. " = " .. val_str)
        end,
        __call = function(_, ...)
            local args = {...}
            local arg_str = ""
            for i, v in ipairs(args) do
                if i > 1 then arg_str = arg_str .. ", " end
                arg_str = arg_str .. recursive_tostring(v)
            end

            local var_name = name:gsub("%.", "_") .. "_" .. math.random(100, 999)
            print("CALL_RESULT --> local " .. var_name .. " = " .. name .. "(" .. arg_str .. ")")
            if name == "task.wait" or name == "wait" then
                _WAIT_COUNT = _WAIT_COUNT + 1
                if _WAIT_COUNT > 10 then
                     error("Too many waits!")
                end
            end

            
            for i, v in ipairs(args) do
                if real_type(v) == "function" then
                    print("--- ENTERING CLOSURE FOR " .. name .. " ---")
                    local success, err = pcall(v, 
                        create_dummy("arg1"), create_dummy("arg2"), 
                        create_dummy("arg3"), create_dummy("arg4"))
                    if not success then 
                        print("-- CLOSURE ERROR: " .. tostring(err)) 
                    end
                    print("--- EXITING CLOSURE FOR " .. name .. " ---")
                end
            end

            if name == "readfile" or name == "loadfile" or name == "dofile" then
                return ""
            end
            if name == "isfile" or name == "isfolder" then
                return false
            end
            if name == "listfiles" then
                return {}
            end
            if name == "writefile" or name == "appendfile" or name == "makefolder" or name == "delfile" or name == "delfolder" then
                return nil
            end
            
            return create_dummy(var_name)
        end,
        __tostring = function() return name end,
        __concat = function(a, b) return tostring(a) .. tostring(b) end,
        __add = function(a, b) return create_dummy("("..tostring(a).."+"..tostring(b)..")") end,
        __sub = function(a, b) return create_dummy("("..tostring(a).."-"..tostring(b)..")") end,
        __mul = function(a, b) return create_dummy("("..tostring(a).."*"..tostring(b)..")") end,
        __div = function(a, b) return create_dummy("("..tostring(a).."/"..tostring(b)..")") end,
        __mod = function(a, b) return create_dummy("("..tostring(a).."%"..tostring(b)..")") end,
        __pow = function(a, b) return create_dummy("("..tostring(a).."^"..tostring(b)..")") end,
        __unm = function(a) return create_dummy("-"..tostring(a)) end,
        __lt = function(a, b) return false end,
        __le = function(a, b) return false end,
        __eq = function(a, b) return false end,
        __len = function(a) return 2 end,
    }
    setmetatable(d, mt)
    return d
end

local function mock_pairs(t)
    local mt = getmetatable(t)
    if mt and mt.__is_mock_dummy then
        local i = 0
        return function(...)
            i = i + 1
            if i <= 1 then
                return i, create_dummy(tostring(t).."_v"..i)
            end
            return nil
        end
    end
    return pairs(t)
end

local function mock_ipairs(t)
    local mt = getmetatable(t)
    if mt and mt.__is_mock_dummy then
        local i = 0
        return function(...)
            i = i + 1
            if i <= 1 then
                return i, create_dummy(tostring(t).."_v"..i)
            end
            return nil
        end
    end
    return ipairs(t)
end

local safe_string = {}
for k, v in pairs(string) do
    safe_string[k] = v
end
safe_string.char = function(...)
    local args = {...}
    for i = 1, #args do
        local value = tonumber(args[i]) or 0
        args[i] = math.floor(value) % 256
    end
    return string.char(unpack(args))
end

local MockEnv = {}
local function trace_httpget(url)
    url = tostring(url)

    print("================================")
    print("HTTPGET DETECTED")
    print("URL:", url)
    print("================================")

    return {
        __trace_httpget = true,
        url = url,
        source = ""
    }
end


local function trace_loadstring(source)
    print("================================")
    print("LOADSTRING DETECTED")
    print("================================")

    -- Direct pattern:
    -- loadstring(game:HttpGet("https://example.com"))()
    if type(source) == "table" and source.__trace_httpget then
        print("LOADSTRING_HTTPGET --> " .. tostring(source.url))

        return function()
            print("DUMMY LOADSTRING CALL")
            return nil
        end
    end

    source = tostring(source)

    print("LOADSTRING SIZE:", #source)

    for url in source:gmatch(
        "[Hh][Tt][Tt][Pp][Gg][Ee][Tt]%s*%([^)]*[\"'](https?://[^\"']+)"
    ) do
        print("HTTPGET INSIDE SOURCE:", url)
    end

    for url in source:gmatch("https?://[^%s\"']+") do
        print("URL INSIDE LOADSTRING:", url)
    end

    print("LOADSTRING CONTENT START")
    print(source)
    print("LOADSTRING CONTENT END")

    return function()
        print("DUMMY LOADSTRING CALL")
        return nil
    end
end


local safe_globals = {
    ["loadstring"] = trace_loadstring,

    ["HttpGet"] = trace_httpget,

    ["httpget"] = trace_httpget,

    ["http"] = {
        ["get"] = trace_httpget
    },

    ["string"] = safe_string,

    ["table"] = {
        ["insert"] = table.insert,
        ["remove"] = table.remove,
        ["sort"] = table.sort,
        ["concat"] = table_concat
    },

    ["math"] = math,
    ["pairs"] = mock_pairs,
    ["ipairs"] = mock_ipairs,
    ["select"] = select,
    ["unpack"] = unpack,
    ["tonumber"] = tonumber,
    ["tostring"] = tostring,
    ["type"] = type,
    ["typeof"] = typeof,
    ["pcall"] = pcall,
    ["xpcall"] = xpcall,

    ["getfenv"] = getfenv,
    ["setmetatable"] = setmetatable,
    ["getmetatable"] = getmetatable,

    ["rawset"] = rawset,
    ["rawget"] = rawget,

    ["error"] = error,
    ["assert"] = assert,
    ["next"] = next,

    ["_VERSION"] = _VERSION,

    ["print"] = function(...)
        local args = {...}
        local parts = {}

        for i, v in ipairs(args) do
            parts[i] = tostring(v)
        end

        print("TRACE_PRINT --> " .. table.concat(parts, "\t"))
    end,

    ["os"] = os,
    ["io"] = io,
    ["package"] = package,
    ["debug"] = debug,

    ["dofile"] = dofile,
    ["loadfile"] = loadfile
}

setmetatable(MockEnv, {
    __index = function(t, k)
        if safe_globals[k] then
            return safe_globals[k]
        end

        if k == "game" then
            print("ACCESSED --> game")
            return create_dummy("game")
        end
        if k == "getgenv" or k == "getrenv" or k == "getreg" then
            return function() return MockEnv end
        end

        local exploit_funcs = {
    "getgc",
    "getinstances",
    "getnilinstances",
    "getloadedmodules",
    "getconnections",
    "getcallingscript",
    "getgenv",
    "getrenv",
    "getreg",
    "getfenv",
    "setfenv",
    "firesignal",
    "fireclickdetector",
    "firetouchinterest",
    "isnetworkowner",
    "gethiddenproperty",
    "sethiddenproperty",
    "setsimulationradius",
    "hookfunction",
    "hookmetamethod",
    "newcclosure",
    "clonefunction",
    "replaceclosure",
    "restoreclosure",
    "islclosure",
    "iscclosure",
    "checkcaller",
    "getnamecallmethod",
    "setnamecallmethod",
    "getrawmetatable",
    "setrawmetatable",
    "setreadonly",
    "isreadonly",
    "rconsoleprint",
    "rconsolewarn",
    "rconsoleerr",
    "rconsoleinfo",
    "rconsolename",
    "rconsoleclear",
    "consoleprint",
    "consolewarn",
    "consoleerr",
    "consoleinfo",
    "consolename",
    "consoleclear",
    "keypress",
    "keyrelease",
    "mouse1click",
    "mouse1press",
    "mouse1release",
    "mouse2click",
    "mouse2press",
    "mouse2release",
    "mousescroll",
    "mousemoverel",
    "mousemoveabs",
    "iswindowactive",
    "makefolder",
    "writefile",
    "readfile",
    "appendfile",
    "loadfile",
    "listfiles",
    "isfile",
    "isfolder",
    "delfile",
    "delfolder",
    "queue_on_teleport",
    "queueonteleport",
    "loadstring",
    "dofile",
    "request",
    "http_request",
    "http",
    "syn",
    "httpget",
    "http_get",
    "httprequest",
    "HttpGet",
    "HttpGetAsync",
    "httpgetasync",
    "http_get_async",
    "identifyexecutor",
    "getexecutorname",
    "identify_executor",
    "get_executor_name",
    "setclipboard",
    "toclipboard",
    "setfpscap",
    "getfpscap",
    "setthreadidentity",
    "getthreadidentity",
    "getidentity",
    "setidentity",
    "Drawing",
    "WebSocket",
    "websocket",
    "Vector2",
    "Vector3",
    "Vector2int16",
    "Vector3int16",
    "CFrame",
    "UDim",
    "UDim2",
    "Rect",
    "Region3",
    "Region3int16",
    "Ray",
    "RaycastParams",
    "OverlapParams",
    "Color3",
    "BrickColor",
    "NumberRange",
    "NumberSequence",
    "NumberSequenceKeypoint",
    "ColorSequence",
    "ColorSequenceKeypoint",
    "Instance",
    "Enum",
    "Faces",
    "Axes",
    "task",
    "coroutine",
    "spawn",
    "Spawn",
    "wait",
    "Wait",
    "delay",
    "Delay",
    "tick",
    "time",
    "elapsedTime",
    "game",
    "workspace",
    "Workspace",
    "script",
    "shared",
    "assert",
    "collectgarbage",
    "error",
    "getmetatable",
    "setmetatable",
    "ipairs",
    "pairs",
    "next",
    "pcall",
    "xpcall",
    "print",
    "warn",
    "select",
    "tonumber",
    "tostring",
    "type",
    "typeof",
    "rawget",
    "rawset",
    "unpack",
    "require",
    "bit",
    "bit32",
    "utf8",
    "math",
    "string",
    "table",
    "os",
    "debug",
    "new",
    "Circle",
    "FilledCircle",
    "FilledQuad",
    "FilledRectangle",
    "FilledTriangle",
    "GetPaint",
    "Line",
    "OutlinedText",
    "Quad",
    "Rectangle",
    "Text",
    "Triangle",
    "FromDays",
    "FromHours",
    "FromMicroseconds",
    "FromMilliseconds",
    "FromMinutes",
    "FromMonths",
    "FromNanoseconds",
    "FromSeconds",
    "FromYears",
    "TimeSinceEpoch",
    "AcceptDragDropPayload",
    "AlignTextToFramePadding",
    "ArrowButton",
    "ArrowButtonEx",
    "Begin",
    "BeginChild",
    "BeginCombo",
    "BeginDragDropSource",
    "BeginDragDropTarget",
    "BeginGroup",
    "BeginItemTooltip",
    "BeginListBox",
    "BeginMainMenuBar",
    "BeginMenu",
    "BeginMenuBar",
    "BeginPopup",
    "BeginPopupContextItem",
    "BeginPopupContextVoid",
    "BeginPopupContextWindow",
    "BeginPopupModal",
    "BeginTabBar",
    "BeginTabItem",
    "BeginTable",
    "BeginTooltip",
    "BeginTooltipEx",
    "BeginTooltipHidden",
    "Bullet",
    "BulletText",
    "Button",
    "ButtonEx",
    "CalcTextSize",
    "Checkbox",
    "CloseCurrentPopup",
    "CollapsingHeader",
    "ColorButton",
    "ColorEdit3",
    "ColorEdit4",
    "ColorPicker3",
    "ColorPicker4",
    "Combo",
    "DockSpace",
    "DragFloat",
    "DragInt",
    "DrawCircle",
    "DrawCircleFilled",
    "DrawLine",
    "DrawRect",
    "DrawRectFilled",
    "DrawText",
    "Dummy",
    "End",
    "EndChild",
    "EndCombo",
    "EndDragDropSource",
    "EndDragDropTarget",
    "EndGroup",
    "EndListBox",
    "EndMainMenuBar",
    "EndMenu",
    "EndMenuBar",
    "EndPopup",
    "EndTabBar",
    "EndTabItem",
    "EndTable",
    "EndTooltip",
    "GetClipboardText",
    "GetColorU32",
    "GetContentRegionAvail",
    "GetCursorPos",
    "GetCursorPosX",
    "GetCursorPosY",
    "GetCursorScreenPos",
    "GetCursorStartPos",
    "GetFontSize",
    "GetFrameCount",
    "GetFrameHeight",
    "GetFrameHeightWithSpacing",
    "GetID",
    "GetItemRectMax",
    "GetItemRectMin",
    "GetItemRectSize",
    "GetMouseCursor",
    "GetMouseDragDelta",
    "GetMousePos",
    "GetScrollMaxX",
    "GetScrollMaxY",
    "GetScrollX",
    "GetScrollY",
    "GetTextLineHeight",
    "GetTextLineHeightWithSpacing",
    "GetWindowPos",
    "GetWindowSize",
    "Image",
    "ImageButton",
    "Indent",
    "InputFloat",
    "InputInt",
    "InputText",
    "InputTextMultiline",
    "InputTextWithHint",
    "InvisibleButton",
    "IsAnyItemActive",
    "IsAnyItemFocused",
    "IsAnyItemHovered",
    "IsItemActivated",
    "IsItemActive",
    "IsItemClicked",
    "IsItemDeactivated",
    "IsItemDeactivatedAfterEdit",
    "IsItemEdited",
    "IsItemFocused",
    "IsItemHovered",
    "IsItemToggledOpen",
    "IsItemVisible",
    "IsKeyDown",
    "IsKeyPressed",
    "IsKeyReleased",
    "IsMouseClicked",
    "IsMouseDoubleClicked",
    "IsMouseDown",
    "IsMouseDragging",
    "IsMouseReleased",
    "IsPopupOpen",
    "IsWindowAppearing",
    "IsWindowCollapsed",
    "IsWindowFocused",
    "IsWindowHovered",
    "ListBox",
    "MenuItem",
    "NewLine",
    "OnRender",
    "OpenPopup",
    "PlotHistogram",
    "PlotLines",
    "PopFont",
    "PopID",
    "PopItemFlag",
    "PopItemWidth",
    "PopStyleColor",
    "PopStyleVar",
    "PopTextWrapPos",
    "ProgressBar",
    "PushFont",
    "PushID",
    "PushItemFlag",
    "PushItemWidth",
    "PushStyleColor",
    "PushStyleVar",
    "PushTextWrapPos",
    "RadioButton",
    "ResetMouseDragDelta",
    "SameLine",
    "Selectable",
    "Separator",
    "SeparatorText",
    "SetClipboardText",
    "SetCursorPos",
    "SetCursorPosX",
    "SetCursorPosY",
    "SetCursorScreenPos",
    "SetDragDropPayload",
    "SetItemAllowOverlap",
    "SetItemDefaultFocus",
    "SetItemTooltip",
    "SetKeyboardFocusHere",
    "SetMouseCursor",
    "SetNextItemOpen",
    "SetNextItemShortcut",
    "SetNextItemWidth",
    "SetNextWindowBgAlpha",
    "SetNextWindowCollapsed",
    "SetNextWindowContentSize",
    "SetNextWindowFocus",
    "SetNextWindowPos",
    "SetNextWindowScroll",
    "SetNextWindowSize",
    "SetNextWindowSizeConstraints",
    "SetScrollHereX",
    "SetScrollHereY",
    "SetScrollX",
    "SetScrollY",
    "SetTabItemClosed",
    "SetTooltip",
    "Shortcut",
    "SliderAngle",
    "SliderFloat",
    "SliderInt",
    "SmallButton",
    "Spacing",
    "StringBuffer",
    "StyleColorsClassic",
    "StyleColorsDark",
    "StyleColorsLight",
    "TabItemButton",
    "TableGetColumnCount",
    "TableGetColumnFlags",
    "TableGetColumnIndex",
    "TableGetColumnName",
    "TableGetRowIndex",
    "TableHeader",
    "TableHeadersRow",
    "TableNextColumn",
    "TableNextRow",
    "TableSetBgColor",
    "TableSetColumnEnabled",
    "TableSetColumnIndex",
    "TableSetupColumn",
    "TableSetupScrollFreeze",
    "TextColored",
    "TextDisabled",
    "TextEx",
    "TextWrapped",
    "TreeNode",
    "TreeNodeEx",
    "TreePop",
    "Unindent",
    "Escape",
    "append_file",
    "appendfileasync",
    "decode",
    "encode",
    "base64_decode",
    "base64_encode",
    "base64decode",
    "base64encode",
    "c_fire_signal",
    "invalidate",
    "iscached",
    "replace",
    "can_signal_replicate",
    "cansignalreplicate",
    "cfiresignal",
    "check_caller",
    "check_closure",
    "check_parallel",
    "checkclosure",
    "checkparallel",
    "clear_draw_cache",
    "clear_teleport_queue",
    "cleardrawcache",
    "clearqueueonteleport",
    "clearteleportqueue",
    "clone_function",
    "clone_ref",
    "cloneref",
    "clonereference",
    "compare_instances",
    "compareinstances",
    "console_clear",
    "console_create",
    "console_destroy",
    "console_input",
    "console_print",
    "console_set_title",
    "consolecreate",
    "consoledestroy",
    "consoleinput",
    "consolesettitle",
    "create_comm_channel",
    "createcommchannel",
    "decrypt",
    "encrypt",
    "generatebytes",
    "generatekey",
    "hash",
    "hmac",
    "lz4compress",
    "lz4decompress",
    "random",
    "dumpcodesize",
    "dumpheap",
    "dumprefs",
    "getcallstack",
    "getconstant",
    "getconstants",
    "getinfo",
    "getmemorycategory",
    "getproto",
    "getprotos",
    "getregistry",
    "getstack",
    "getupvalue",
    "getupvalues",
    "info",
    "isvalidlevel",
    "loadmodule",
    "profilebegin",
    "profileend",
    "resetmemorycategory",
    "setconstant",
    "setmemorycategory",
    "setstack",
    "setupvalue",
    "traceback",
    "tracerefs",
    "validlevel",
    "decompile",
    "del_file",
    "del_folder",
    "deletefile",
    "deletefolder",
    "dump_string",
    "dumpstring",
    "filter_gc",
    "filtergc",
    "fire_click_detector",
    "fire_proximity_prompt",
    "fire_signal",
    "fire_touch_interest",
    "fireproximityprompt",
    "get_actor_states",
    "get_actor_threads",
    "get_actors",
    "get_all_threads",
    "get_callback_function",
    "get_callback_member",
    "get_callback_thread",
    "get_callback_value",
    "get_calling_script",
    "get_callstack",
    "get_comm_channel",
    "get_connection_function",
    "get_connection_thread",
    "get_connections",
    "get_constant",
    "get_constants",
    "get_current_actor",
    "get_custom_asset",
    "get_deleted_actors",
    "get_event_member",
    "get_fflag",
    "get_filter",
    "get_fps_cap",
    "get_function_hash",
    "get_game_state",
    "get_gc",
    "get_genv",
    "get_hidden_gui",
    "get_hidden_properties",
    "get_hidden_property",
    "get_hui",
    "get_hwid",
    "get_identity",
    "get_info",
    "get_instances",
    "get_loaded_modules",
    "get_lua_state",
    "get_namecall_method",
    "get_nil_instances",
    "get_process_identifier",
    "get_properties",
    "get_proto",
    "get_protos",
    "get_raw_metatable",
    "get_reg",
    "get_registry",
    "get_render_property",
    "get_render_stepped_list",
    "get_renv",
    "get_running_scripts",
    "get_script_bytecode",
    "get_script_closure",
    "get_script_from_thread",
    "get_script_function",
    "get_script_hash",
    "get_script_thread",
    "get_scripts",
    "get_senv",
    "get_signal_arguments",
    "get_signal_arguments_info",
    "get_signal_cons",
    "get_stack",
    "get_tenv",
    "get_thread_context",
    "get_thread_identity",
    "get_upvalue",
    "get_upvalues",
    "getactors",
    "getactorstates",
    "getactorthreads",
    "getallthreads",
    "getcallbackfunction",
    "getcallbackmember",
    "getcallbackthread",
    "getcallbackvalue",
    "getcommchannel",
    "getconnectionfunction",
    "getconnectionthread",
    "getcurrentactor",
    "getcustomasset",
    "getdeletedactors",
    "geteventmember",
    "getfflag",
    "getfilter",
    "getfunctionhash",
    "getgamestate",
    "gethiddenproperties",
    "gethui",
    "gethwid",
    "getinstancecache",
    "getluastate",
    "getmenv",
    "getmodules",
    "getprocessidentifier",
    "getproperties",
    "getrenderproperty",
    "getrendersteppedlist",
    "getrunningscripts",
    "getscriptbytecode",
    "getscriptclosure",
    "getscriptfromthread",
    "getscriptfunction",
    "getscripthash",
    "getscripts",
    "getscriptthread",
    "getsenv",
    "getsignalarguments",
    "getsignalargumentsinfo",
    "getsignalwhitelist",
    "getsynasset",
    "gettenv",
    "getthreadcontext",
    "hook_func",
    "hook_function",
    "hook_meta_method",
    "hook_proto",
    "hook_signal",
    "hookfunc",
    "hookproto",
    "hooksignal",
    "is_c_closure",
    "is_connection_enabled",
    "is_executor_closure",
    "is_executor_thread",
    "is_file",
    "is_folder",
    "is_function_hooked",
    "is_game_active",
    "is_game_script_connection",
    "is_l_closure",
    "is_lua_connection",
    "is_network_owner",
    "is_our_closure",
    "is_parallel",
    "is_protected",
    "is_proto_hooked",
    "is_rbx_active",
    "is_read_only",
    "is_render_obj",
    "is_scriptable",
    "is_signal_hooked",
    "is_un_touched",
    "is_valid_level",
    "is_waiting_connection",
    "is_window_active",
    "is_write_able",
    "isconnectionenabled",
    "iscustomcclosure",
    "isexecutorclosure",
    "isexecutorfunction",
    "isexecutorthread",
    "isfunchooked",
    "isfunctionhooked",
    "isgameactive",
    "isgamescriptconnection",
    "isluaconnection",
    "isnewcclosure",
    "isourclosure",
    "isparallel",
    "isprotected",
    "isprotohooked",
    "isrbxactive",
    "isrenderobj",
    "isrenderobject",
    "isscriptable",
    "issignalhooked",
    "isuntouched",
    "iswaitingconnection",
    "iswritable",
    "iswriteable",
    "key_click",
    "key_press",
    "key_release",
    "key_tap",
    "keyclick",
    "keytap",
    "list_files",
    "load_file",
    "load_string",
    "loadfileasync",
    "compress",
    "decompress",
    "lz4_compress",
    "lz4_decompress",
    "make_folder",
    "make_read_only",
    "make_write_able",
    "makereadonly",
    "makewritable",
    "makewriteable",
    "message_box",
    "messagebox",
    "mouse_1_click",
    "mouse_1_press",
    "mouse_1_release",
    "mouse_2_click",
    "mouse_2_press",
    "mouse_2_release",
    "mouse_move_abs",
    "mouse_move_rel",
    "mouse_scroll",
    "new_c_closure",
    "new_l_closure",
    "newlclosure",
    "get_original_thread",
    "get_root_callback",
    "hook",
    "is_hook_thread",
    "unhook",
    "queueteleport",
    "add_send_hook",
    "is_enabled",
    "remove_send_hook",
    "send",
    "rconsole_clear",
    "rconsole_create",
    "rconsole_destroy",
    "rconsole_err",
    "rconsole_hidden",
    "rconsole_hide",
    "rconsole_info",
    "rconsole_input",
    "rconsole_name",
    "rconsole_print",
    "rconsole_set_title",
    "rconsole_show",
    "rconsole_toggle",
    "rconsole_warn",
    "rconsolecreate",
    "rconsoledestroy",
    "rconsolehidden",
    "rconsolehide",
    "rconsoleinput",
    "rconsolesettitle",
    "rconsoleshow",
    "rconsoletoggle",
    "rconsoletop",
    "read_file",
    "readfileasync",
    "replace_closure",
    "replicate_signal",
    "replicatesignal",
    "restore_function",
    "restore_proto",
    "restore_signal",
    "restorefunc",
    "restorefunction",
    "restoreproto",
    "restoresignal",
    "run_on_actor",
    "runonactor",
    "saveinstance",
    "saveplace",
    "set_clipboard",
    "set_connection_enabled",
    "set_constant",
    "set_fflag",
    "set_fps_cap",
    "set_hidden_property",
    "set_identity",
    "set_namecall_method",
    "set_raw_metatable",
    "set_rbx_clipboard",
    "set_read_only",
    "set_render_property",
    "set_scriptable",
    "set_stack",
    "set_thread_context",
    "set_thread_identity",
    "set_un_touched",
    "set_upvalue",
    "setconnectionenabled",
    "setfflag",
    "setrbxclipboard",
    "setrenderproperty",
    "setscriptable",
    "setstackhidden",
    "setthreadcontext",
    "setuntouched",
    "to_clipboard",
    "trampoline_call",
    "valid_level",
    "connect",
    "write_file",
    "writefileasync",
}
        for _, name in ipairs(exploit_funcs) do
            if k == name then
                print("ACCESSED --> " .. k)
                return create_dummy(k)
            end
        end

        -- 4. Fallback: Return NIL (to satisfy Fallback Path logic)
        print("ACCESSED (NIL) --> " .. k)
        return nil
    end,
    
    __newindex = function(t, k, v)
        local val_str = ""
        if real_type(v) == "string" then
            val_str = '"' .. v .. '"'
        elseif real_type(v) == "number" or real_type(v) == "boolean" then
            val_str = tostring(v)
        else
            val_str = tostring(v)
        end
        print("SET GLOBAL --> " .. tostring(k) .. " = " .. val_str)
        rawset(t, k, v)
    end
})

safe_globals["_G"] = MockEnv
safe_globals["shared"] = MockEnv
"""

    idx_args = content.rfind("(getfenv")
    if idx_args == -1:
         idx_args = content.rfind("( getfenv")

    if idx_args == -1:
         idx_args = len(content)

    idx_ret = content.rfind("return(function", 0, idx_args)
    if idx_ret == -1:
        print(f"Could not find return(function injection point in {filepath}.")
        return

    dumper_code = f"""
    print("--- CONSTANTS START ---")
    if {var_name} then
        local sorted_keys = {{}}
        for k in pairs({var_name}) do table.insert(sorted_keys, k) end
        table.sort(sorted_keys)
        local out = "local Constants = {{"
        for i, k in ipairs(sorted_keys) do
            local v = {var_name}[k]
            local v_str = escape_lua_string(v)
            out = out .. " [" .. k .. "] = " .. v_str .. ","
        end
        out = out .. " }}"
        print(out)
    end
    print("--- CONSTANTS END ---")
    """

    new_content = mock_env_code + content[:idx_ret] + dumper_code + content[idx_ret:]

    if "getfenv and getfenv()or _ENV" in new_content:
        new_content = new_content.replace("getfenv and getfenv()or _ENV", "MockEnv")
    else:
        new_content = re.sub(r'getfenv\s+and\s+getfenv\(\)or\s+_ENV', 'MockEnv', new_content)

    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        suffix=".lua",
        delete=False,
    ) as temp_handle:
        temp_file = temp_handle.name
        temp_handle.write(new_content)

    print(f"Executing deobfuscation for {filepath}...")

    process = subprocess.Popen([get_lua_executable(), temp_file, "1"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    stdout_lines = []
    
    RELEVANT_PREFIXES = (
        "ACCESSED", "CALL_RESULT", "local Constants =", 
        "URL DETECTED", "SET GLOBAL", "UNPACK CALLED", 
        "CAPTURED CHUNK", "CLOSURE", "TRACE_PRINT", 
        "PROP_SET", "LOADSTRING"
    )
    
    stdout_data = b""
    err = b""
    try:
        stdout_data, err = process.communicate(timeout=20)
    except subprocess.TimeoutExpired as exc:
        print("Timeout reached.")
        process.kill()
        stdout_data, err = process.communicate()
        if exc.output:
            stdout_data = exc.output + stdout_data
        if exc.stderr:
            err = exc.stderr + err
    except Exception as e:
        print(f"Error: {e}")
        process.kill()

    if stdout_data:
        for line in stdout_data.decode('utf-8', errors='replace').splitlines():
            stdout_lines.append(line.strip())
            if any(prefix in line for prefix in RELEVANT_PREFIXES):
                print(line.strip())
    stderr_text = ""
    if err:
        stderr_text = err.decode('utf-8', errors='replace')
        if LUA_CONTROL_STRUCTURE_TOO_LONG in stderr_text and static_constants:
            print("Lua 5.1 could not compile the full script; using static string-table fallback.")
        elif stderr_text.strip():
            print("STDERR:", stderr_text)

    constants_str = ""
    trace_lines = []

    in_constants = False
    for line in stdout_lines:
        if line == "--- CONSTANTS START ---":
            in_constants = True
            continue
        if line == "--- CONSTANTS END ---":
            in_constants = False
            continue

        if in_constants:
            constants_str += line + "\n"
        elif any(prefix in line for prefix in RELEVANT_PREFIXES):
            trace_lines.append(line)

    if not constants_str and LUA_CONTROL_STRUCTURE_TOO_LONG in stderr_text and static_constants:
        constants_str = static_constants + "\n"

    report_file = filepath + ".report.txt"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("--- DEOBFUSCATION REPORT ---\n")
        f.write(f"File: {filepath}\n\n")
        f.write("--- TRACE ---\n")
        for line in trace_lines:
            f.write(line + "\n")
        f.write("\n--- CONSTANTS ---\n")
        f.write(constants_str)

    print(f"Report saved to {report_file}")

    try:
        import trace_to_lua
        import importlib
        importlib.reload(trace_to_lua)
        trace_to_lua.parse_trace(report_file)
    except Exception as e:
        print(f"Failed to convert trace: {e}")
        import traceback
        traceback.print_exc()

    if os.path.exists(temp_file):
        os.remove(temp_file)
    #if os.path.exists(report_file):
    #    os.remove(report_file)

def main():
    target = "obfuscated_scripts"
    if len(sys.argv) > 1:
        target = sys.argv[1]

    if os.path.isfile(target):
        deobfuscate_file(target)
    elif os.path.isdir(target):
        files = glob.glob(os.path.join(target, "*.lua"))
        for file in sorted(files):
            if "temp_deob" in file or ".report.txt" in file or ".deobf." in file:
                continue
            deobfuscate_file(file)
            print("-" * 40)
    else:
        print("Invalid path")

if __name__ == "__main__":
    main()