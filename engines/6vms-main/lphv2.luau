local process = require("@lune/process")
local fs = require("@lune/fs")

local inpath = process.args[1]
if not inpath then
    print("usage: lune run lphv2.luau <input.lua> [output.lua]")
    return
end

local outpath = process.args[2] or inpath:gsub("%.lua$", "_lphv2_out.lua")
local abs_in = fs.isFile(inpath) and fs.fullPath(inpath) or nil
if not abs_in then print("File not found: " .. inpath); return end

local src = fs.readFile(abs_in)
if not src or #src == 0 then print("Empty input"); return end

-- Try static decryption first (DecryptConstant algorithm from injector.lua)
-- Build the string decryption table
local function buildStringTable(seed)
    local s, K = {}, seed or 226
    for _ = 0, 255 do
        s[bit32.bxor(K, 98)] = string.char(K)
        K = (97 * K + 33) % 256
    end
    return s
end

-- Decrypt a single string using rolling XOR cipher
local function decryptString(str, s)
    if type(str) ~= "string" or #str < 2 then return str end
    local Q = (97 * string.byte(str, 1, 1) + 33) % 256
    local out = {}
    for i = 2, #str do
        local byte = string.byte(str, i)
        out[#out + 1] = s[bit32.bxor(byte, Q)]
        Q = (97 * Q + 33) % 256
    end
    return table.concat(out)
end

-- Try to find and decrypt GlobalLuraphData[2] constants in source
local function tryStaticDecrypt(src)
    local s = buildStringTable(226)
    local decrypted = src
    local count = 0

    -- Pattern: find GlobalLuraphData[2] table with string entries
    -- Match "[0] = \"<string>\"" patterns within GlobalLuraphData[2] context
    local function findEncryptedStrings(body)
        local results = {}
        for match in body:gmatch('%[0%s*%]%s*=%s*"([^"]+)"') do
            table.insert(results, match)
        end
        return results
    end

    -- Find GlobalLuraphData[2] table body
    local gstart, gend = src:find("GlobalLuraphData%b[]%s*=")
    if gstart then
        -- Look for the opening brace of the table
        local braceStart = src:find("{", gend)
        if braceStart then
            -- Extract balanced braces content (simple approach)
            local depth, bodyStart = 0, braceStart
            for i = braceStart, #src do
                local c = src:sub(i, i)
                if c == "{" then depth = depth + 1
                elseif c == "}" then depth = depth - 1
                end
                if depth == 0 then
                    local body = src:sub(bodyStart, i)
                    local strings = findEncryptedStrings(body)
                    for _, enc in ipairs(strings) do
                        local plain = decryptString(enc, s)
                        decrypted = decrypted:gsub('"%s*%[0%s*%]%s*=%s*"' .. enc .. '"', function()
                            count = count + 1
                            return '"[0] = "' .. plain .. '"'
                        end, 1)
                    end
                    break
                end
            end
        end
    end

    -- Also try to find string entries in nested table format
    for enc in src:gmatch('"([%z\1-\127][%z\1-\127]+)"') do
        if #enc > 4 then
            local plain = decryptString(enc, s)
            if plain ~= enc then
                decrypted = decrypted:gsub('"' .. enc .. '"', "'" .. plain .. "'", 1)
                count = count + 1
            end
        end
    end

    return decrypted, count
end

local decrypted, count = tryStaticDecrypt(src)

if count > 0 then
    fs.writeFile(outpath, decrypted)
    print(string.format("Static decrypt: decrypted %d constants -> %s", count, outpath))
    return
end

-- Fallback: run through 6Vms pipeline
print("Static extraction found no v2 constants, trying 6Vms pipeline...")
local lune = process.os == "windows" and "lune.exe" or "lune"
local result = process.exec(lune, {
    "run", "6vms/main.luau", abs_in,
    "out=" .. outpath,
    "discord=false",
})

if result and result.exitCode == 0 then
    local content = fs.readFile(outpath)
    if content and #content > 0 then
        print(string.format("Pipeline: wrote %d bytes to %s", #content, outpath))
    else
        print("Pipeline ran but output is empty. Check " .. outpath)
    end
else
    local err = (result and result.stderr) or "unknown error"
    print("All methods failed: " .. err)
end
