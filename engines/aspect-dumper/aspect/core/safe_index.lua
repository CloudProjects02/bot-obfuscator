-- PATCHED safe_index - returns a sentinel instead of nil to prevent RCE
local _SAFE_INDEX_SENTINEL = {}  -- unique sentinel object, never equals nil or any real value

function safe_index(obj, key)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then return _SAFE_INDEX_SENTINEL end
    local ok, res = pcall(function() return obj[key] end)
    if ok then
        -- If the result is nil (missing key), return sentinel instead of nil
        if res == nil then return _SAFE_INDEX_SENTINEL end
        return res
    end
    return _SAFE_INDEX_SENTINEL
end