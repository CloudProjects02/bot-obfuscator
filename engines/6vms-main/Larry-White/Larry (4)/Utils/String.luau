local Gsub = string.gsub
local Sub = string.sub
local Match = string.match
local Split = string.split
local Format = string.format
local Byte = string.byte
local Upper = string.upper
local Lower = string.lower

local Insert = table.insert
local Concat = table.concat
local Create = table.create
local Tonumber = tonumber

local String = {}

function String.PatternSafe(Str, AllChars)
	if AllChars then
		return (Gsub(Str, "([%%%(%)%[%]%.%-%+%^%*%$%?])", "%%%1"))
	end
	return (Gsub(Str, "%%", "%%%%"))
end

function String.Strip(Str, KeepLeading)
	if KeepLeading then
		return Match(Str, "^(.-)%s*$") or ""
	end
	return Match(Str, "^%s*(.-)%s*$") or ""
end

function String.IsWeird(Key)
	return Key == ""
		or Match(Key, "[^_%w]") ~= nil
		or Match(Key, "^%d") ~= nil
end

function String.SplitPath(Str)
	Str = tostring(Str)
	local Result = {}
	for Part in Str:gmatch("[^%.%[]+") do
		local Key = Match(Part, "^%s*(.-)%s*$") or Part
		if Sub(Key, -1) == "]" then
			Key = Sub(Key, 1, -2)
			Key = Gsub(Key, '^["\'](.-)["\']$', "%1")
		end
		Insert(Result, Key)
	end
	return Result
end

function String.Index(Key, Path, FormattedKey)
	if Path == "..." then
		Path = "(...)"
	end

	if String.IsWeird(Key) then
		return `{Path or "getfenv()"}[{FormattedKey or '"' .. Key .. '"'}]`
	end

	return Path and `{Path}.{Key}` or Key
end

function String.CaseInsensitive(Str)
	local Len = #Str
	local Parts = Create(Len)
	for I = 1, Len do
		local C = Sub(Str, I, I)
		Parts[I] = `[{Upper(C)}{Lower(C)}]`
	end
	return Concat(Parts)
end

function String.DecodeArgs(Str)
	local Args = {}
	for _, V in Split(Str, ", ") do
		local Num = Tonumber(V)
		if Sub(V, 1, 1) == '"' and Sub(V, -1) == '"' then
			Insert(Args, Sub(V, 2, -2))
		elseif Num then
			Insert(Args, Num)
		elseif V == "true" then
			Insert(Args, true)
		elseif V == "false" then
			Insert(Args, false)
		else
			Insert(Args, V)
		end
	end
	return Args
end

function String.Escape(Str)
	local Result = Gsub(Str, "\\", "\\\\")
	Result = Gsub(Result, "[\n\b\t\v\f\"\r]", {
		["\n"] = "\\n",
		["\b"] = "\\b",
		["\t"] = "\\t",
		["\v"] = "\\v",
		["\f"] = "\\f",
		["\""] = "\\\"",
		["\r"] = "\\r",
	})
	return (Gsub(Result, "[%z\1-\31\127]", function(C)
		return Format("\\%03d", Byte(C))
	end))
end

function String.Quote(Str, MaxLength)
	local Escaped = String.Escape(Str)
	local Limit = MaxLength or 8024

	if #Escaped > Limit then
		local Remaining = #Escaped - Limit
		local Unit = Remaining >= 1024 and "kilobytes" or "bytes"
		local Amount = Remaining >= 1024 and math.ceil(Remaining / 1024) or Remaining
		Escaped = Sub(Escaped, 1, Limit) .. `..( {Amount} {Unit} left)`
	end

	return `"{Escaped}"`
end

function String.ToValue(Str)
	if Str == "false" then return false end
	if Str == "true" then return true end
	if Str == "nil" then return nil end
	return Tonumber(Str) or Str
end

return String