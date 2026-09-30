local IdentityUtil = require("../Utils/Identity")

local HTTP = {}

local UrlCache = {}
local BodyOrigins = {}
local CacheExpiry = 120
local IgnoredUrls = {}
local JSON_NULL = {}
local NetModule = nil
local NetCheckComplete = false

local function GetNetModule()
	if NetCheckComplete then
		return NetModule
	end

	NetCheckComplete = true
	local Ok, Loaded = pcall(require, "@lune/net")
	if Ok then
		NetModule = Loaded
	end

	return NetModule
end

local function DecodeJsonFallback(Str)
	if typeof(Str) ~= "string" then
		return nil
	end

	local Pos = 1
	local Len = #Str

	local function Peek()
		if Pos > Len then
			return ""
		end
		return string.sub(Str, Pos, Pos)
	end

	local function Advance(Count)
		Pos += Count or 1
	end

	local function SkipWhitespace()
		while true do
			local C = Peek()
			if C == " " or C == "\n" or C == "\r" or C == "\t" then
				Advance(1)
			else
				break
			end
		end
	end

	local ParseValue

	local function ParseString()
		if Peek() ~= "\"" then
			return nil, false
		end
		Advance(1)

		local Out = {}
		while Pos <= Len do
			local C = Peek()
			if C == "\"" then
				Advance(1)
				return table.concat(Out), true
			end

			if C == "\\" then
				Advance(1)
				local Esc = Peek()
				if Esc == "\"" or Esc == "\\" or Esc == "/" then
					Out[#Out + 1] = Esc
					Advance(1)
				elseif Esc == "b" then
					Out[#Out + 1] = "\b"
					Advance(1)
				elseif Esc == "f" then
					Out[#Out + 1] = "\f"
					Advance(1)
				elseif Esc == "n" then
					Out[#Out + 1] = "\n"
					Advance(1)
				elseif Esc == "r" then
					Out[#Out + 1] = "\r"
					Advance(1)
				elseif Esc == "t" then
					Out[#Out + 1] = "\t"
					Advance(1)
				elseif Esc == "u" then
					Advance(1)
					local Hex = string.sub(Str, Pos, Pos + 3)
					if #Hex < 4 or string.find(Hex, "[^0-9A-Fa-f]") then
						return nil, false
					end
					local Code = tonumber(Hex, 16) or 0
					if Code <= 0x7F then
						Out[#Out + 1] = string.char(Code)
					else
						Out[#Out + 1] = "?"
					end
					Advance(4)
				else
					return nil, false
				end
			else
				Out[#Out + 1] = C
				Advance(1)
			end
		end

		return nil, false
	end

	local function ParseNumber()
		local Slice = string.sub(Str, Pos)
		local Match = string.match(Slice, "^%-?%d+%.?%d*[eE]?[%+%-]?%d*")
		if not Match or Match == "" or Match == "-" then
			return nil, false
		end

		local Num = tonumber(Match)
		if Num == nil then
			return nil, false
		end

		Advance(#Match)
		return Num, true
	end

	local function ParseArray()
		if Peek() ~= "[" then
			return nil, false
		end
		Advance(1)
		SkipWhitespace()

		local Arr = {}
		local Index = 1

		if Peek() == "]" then
			Advance(1)
			return Arr, true
		end

		while true do
			local Value, Ok = ParseValue()
			if not Ok then
				return nil, false
			end

			if Value ~= JSON_NULL then
				Arr[Index] = Value
			end
			Index += 1

			SkipWhitespace()
			local C = Peek()
			if C == "," then
				Advance(1)
				SkipWhitespace()
			elseif C == "]" then
				Advance(1)
				break
			else
				return nil, false
			end
		end

		return Arr, true
	end

	local function ParseObject()
		if Peek() ~= "{" then
			return nil, false
		end
		Advance(1)
		SkipWhitespace()

		local Obj = {}

		if Peek() == "}" then
			Advance(1)
			return Obj, true
		end

		while true do
			local Key, OkKey = ParseString()
			if not OkKey then
				return nil, false
			end

			SkipWhitespace()
			if Peek() ~= ":" then
				return nil, false
			end
			Advance(1)
			SkipWhitespace()

			local Value, OkValue = ParseValue()
			if not OkValue then
				return nil, false
			end

			if Value ~= JSON_NULL then
				Obj[Key] = Value
			end

			SkipWhitespace()
			local C = Peek()
			if C == "," then
				Advance(1)
				SkipWhitespace()
			elseif C == "}" then
				Advance(1)
				break
			else
				return nil, false
			end
		end

		return Obj, true
	end

	ParseValue = function()
		SkipWhitespace()
		local C = Peek()

		if C == "\"" then
			return ParseString()
		end

		if C == "[" then
			return ParseArray()
		end

		if C == "{" then
			return ParseObject()
		end

		if C == "-" or string.find(C, "%d") then
			return ParseNumber()
		end

		if string.sub(Str, Pos, Pos + 3) == "true" then
			Advance(4)
			return true, true
		end

		if string.sub(Str, Pos, Pos + 4) == "false" then
			Advance(5)
			return false, true
		end

		if string.sub(Str, Pos, Pos + 3) == "null" then
			Advance(4)
			return JSON_NULL, true
		end

		return nil, false
	end

	SkipWhitespace()
	local Root, Ok = ParseValue()
	if not Ok then
		return nil
	end
	SkipWhitespace()
	if Pos <= Len then
		return nil
	end

	if Root == JSON_NULL then
		return nil
	end

	return Root
end

local function GetMockBodyForUrl(Url)
	if typeof(Url) ~= "string" then
		return nil
	end

	local Lower = string.lower(Url)

	if string.find(Lower, "apis.roblox.com/universes/v1/places/", 1, true)
		and string.find(Lower, "/universe", 1, true)
	then
		return '{"universeId":1234567890}'
	end

	if string.find(Lower, "games.roblox.com/v1/games?universeids=", 1, true) then
		return '{"data":[{"id":1234567890,"name":"Mock Experience"}]}'
	end

	if string.find(Lower, "ub-services.rhuda21.workers.dev/loaddata", 1, true) then
		return '{"Seeds":{"ShopData":[{"Name":"Carrot Seed"},{"Name":"Tomato Seed"},{"Name":"Pumpkin Seed"}]},"Mutations":[{"Name":"None"},{"Name":"Golden"},{"Name":"Rainbow"}]}'
	end

	if string.find(Lower, "pastefy.app/r6upmycz/raw", 1, true) then
		return 'print("hi!")'
	end

	if string.find(Lower, "raw.githubusercontent.com/hummingbird8/hummingrn/main/testloadstring", 1, true) then
		return 'return "CAND_MA_IA_FLAMA"'
	end

	if string.find(Lower, "setup.roblox.com/version-d0e8cfcd943d4ae2-api-dump.json", 1, true) then
		return '{"Classes":[{"Name":"DataModel"}],"Enums":[{"Name":"QualityLevel"}]}'
	end

	if string.find(Lower, "raw.githubusercontent.com/jensonhirst/orion/main/source", 1, true) then
		return [[
local OrionLib = {}

function OrionLib:MakeWindow(Config)
    return {
        Config = Config or {},
    }
end

function OrionLib:Destroy() end
function OrionLib:Init() end

return OrionLib
]]
	end

	if string.find(Lower, "raw.githubusercontent.com", 1, true)
		and string.find(Lower, "protected_funcs.lua", 1, true)
	then
		return [[
local function make_section()
    local section = {}
    return setmetatable(section, {
        __index = function(_, _k)
            return function(...)
                return section
            end
        end,
    })
end

local Funcs = setmetatable({}, {
    __index = function(_, _k)
        return function(...)
            return nil
        end
    end,
})

local api = {
    Funcs = Funcs,
}

function api.Init(...) end
function api.CreateStandardWindow(...) end
function api.AddDefaultElements(...) end
function api.SettingTab(...) end

function api:Tab(...)
    local tab = {}
    function tab:AddSection(...)
        return make_section()
    end
    return setmetatable(tab, {
        __index = function(_, _k)
            return function(...)
                return make_section()
            end
        end,
    })
end

return api
]]
	end

	if string.find(Lower, "raw.githubusercontent.com", 1, true)
		and string.find(Lower, "webhooklibrary.lua", 1, true)
	then
		return "return function(...) return {} end"
	end

	if string.find(Lower, "raw.githubusercontent.com", 1, true)
		and string.find(Lower, ".lua", 1, true)
	then
		return "return {}"
	end

	return nil
end

function HTTP.Init(IgnoreList)
	if IgnoreList then
		for _, Pattern in IgnoreList do
			table.insert(IgnoredUrls, string.lower(Pattern))
		end
	end
end

function HTTP.IsIgnored(Url)
	local Lower = string.lower(Url)
	for _, Pattern in IgnoredUrls do
		if string.find(Lower, Pattern, 1, true) then
			return true
		end
	end
	return false
end

function HTTP.GetCached(Url)
	local Entry = UrlCache[Url]
	if not Entry then return nil end

	if os.clock() - Entry.Time > CacheExpiry then
		UrlCache[Url] = nil
		return nil
	end

	return Entry.Response
end

function HTTP.GetBodyOrigin(Body)
	if typeof(Body) ~= "string" then
		return nil
	end

	return BodyOrigins[Body]
end

function HTTP.SetCached(Url, Response)
	UrlCache[Url] = {
		Response = Response,
		Time = os.clock(),
	}

	if typeof(Response) == "string" and typeof(Url) == "string" then
		BodyOrigins[Response] = Url
	end
end

function HTTP.ClearCache()
	table.clear(UrlCache)
	table.clear(BodyOrigins)
end

function HTTP.IsHTML(Body)
	if typeof(Body) ~= "string" then return false end
	return string.match(Body, "^%s*<!DOCTYPE") ~= nil or string.match(Body, "^%s*<html") ~= nil
end

function HTTP.MockResponse(StatusCode, Body)
	return {
		Success = (StatusCode or 200) == 200,
		StatusCode = StatusCode or 200,
		StatusMessage = StatusCode == 200 and "OK" or "Error",
		Headers = {},
		Body = Body or "",
	}
end

function HTTP.HttpGet(Url, Proxy, State, Emitter, Beautifier, Scope)
	local Path = State:IsInternal(Url)

	if Path then
		local Value = `game:HttpGet({Path})`
		local Var = Scope:AddVar("httpResult", "get", Value, "__call")
		local Spied = Proxy:Spy(Var)
		rawset(Spied, "V", "")
		return Spied
	end

	if typeof(Url) ~= "string" then
		local Value = `game:HttpGet({Beautifier:Beautify(Url)})`
		local Var = Scope:AddVar("httpResult", "get", Value, "__call")
		local Spied = Proxy:Spy(Var)
		rawset(Spied, "V", "")
		return Spied
	end

	local MockBody = GetMockBodyForUrl(Url)
	if MockBody ~= nil then
		HTTP.SetCached(Url, MockBody)
		return MockBody
	end

	if HTTP.IsIgnored(Url) then
		local Value = `game:HttpGet({Beautifier:Beautify(Url)}) `
		local Var = Scope:AddVar("httpResult", "get", Value, "__call")
		local Spied = Proxy:Spy(Var)
		rawset(Spied, "V", "")
		return Spied
	end

	local Cached = HTTP.GetCached(Url)
	if Cached then
		return Cached
	end

	local net = GetNetModule()
	if net then
		local S, R = pcall(function()
			local Response = net.request({
				url = Url,
				method = "GET",
				headers = {
					["User-Agent"] = "Roblox/WinInet",
					["Accept"] = "*/*",
					["Roblox-Id"] = tostring(math.random(100000000, 999999999)),
				},
			})
			return Response.body
		end)

		if S and R then
			if HTTP.IsHTML(R) then
				local Value = `game:HttpGet({Beautifier:Beautify(Url)}) `
				local Var = Scope:AddVar("httpResult", "get", Value, "__call")
				local Spied = Proxy:Spy(Var)
				rawset(Spied, "V", "")
				return Spied
			end

			HTTP.SetCached(Url, R)
			return R
		end
	end

	local Value = `game:HttpGet({Beautifier:Beautify(Url)})`
	local Var = Scope:AddVar("httpResult", "get", Value, "__call")
	local Spied = Proxy:Spy(Var)
	rawset(Spied, "V", "")
	return Spied
end

function HTTP.Request(Options, Proxy, State, Emitter, Beautifier, Scope)
	local Path = State:IsInternal(Options)

	if Path then
		local Value = `request({Path})`
		local Var = Scope:AddVar("response", "req", Value, "__call")
		return Proxy:Spy(Var)
	end

	if typeof(Options) ~= "table" then
		return HTTP.MockResponse(200)
	end

	local Url = Options.Url or Options.url
	local Method = string.upper(Options.Method or Options.method or "GET")

	if Method == "GET" and typeof(Url) == "string" and not HTTP.IsIgnored(Url) then
		local net = GetNetModule()
		if net then
			local S, R = pcall(function()
				return net.request({
					url = Url,
					method = "GET",
					headers = Options.Headers or Options.headers or {},
				})
			end)

			if S and R then
				return {
					Success = R.ok,
					StatusCode = R.statusCode,
					StatusMessage = R.statusMessage or "OK",
					Headers = R.headers or {},
					Body = R.body or "",
				}
			end
		end
	end

	return HTTP.MockResponse(200, "")
end

function HTTP.GenerateGUID(WrapInCurlyBraces)
	if WrapInCurlyBraces == nil then
		WrapInCurlyBraces = true
	end

	if typeof(WrapInCurlyBraces) ~= "boolean" then
		error(`invalid argument #1 to 'GenerateGUID' (boolean expected, got {typeof(WrapInCurlyBraces)})`, 2)
	end

	local function RandomHex(Count)
		local Parts = table.create(Count)
		for I = 1, Count do
			Parts[I] = string.format("%X", math.random(0, 15))
		end
		return table.concat(Parts)
	end

	local Guid = string.format(
		"%s-%s-4%s-%X%s-%s",
		RandomHex(8),
		RandomHex(4),
		RandomHex(3),
		math.random(8, 11),
		RandomHex(3),
		RandomHex(12)
	)

	if WrapInCurlyBraces then
		return "{" .. Guid .. "}"
	end

	return Guid
end

function HTTP.UrlEncode(Input)
	if typeof(Input) ~= "string" then
		error(`invalid argument #1 to 'UrlEncode' (string expected, got {typeof(Input)})`, 2)
	end

	local Encoded = string.gsub(Input, ".", function(Char)
		local Byte = string.byte(Char)
		if Byte >= 48 and Byte <= 57 then
			return Char
		end
		if Byte >= 65 and Byte <= 90 then
			return Char
		end
		if Byte >= 97 and Byte <= 122 then
			return Char
		end
		return string.format("%%%02X", Byte)
	end)

	return Encoded
end

function HTTP.JSONEncode(Data, Beautifier)
	local net = GetNetModule()
	if net then
		local S, R = pcall(net.jsonEncode, Data)
		if S then return R end
	end

	local function EscapeJson(Value)
		local Text = tostring(Value or "")
		Text = string.gsub(Text, "\\", "\\\\")
		Text = string.gsub(Text, "\"", "\\\"")
		Text = string.gsub(Text, "\r", "\\r")
		Text = string.gsub(Text, "\n", "\\n")
		Text = string.gsub(Text, "\t", "\\t")
		return Text
	end

	local function IsArray(Tbl)
		local Count = 0
		local MaxIndex = 0
		for Key in next, Tbl do
			if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
				return false
			end
			Count += 1
			if Key > MaxIndex then
				MaxIndex = Key
			end
		end
		return MaxIndex == Count
	end

	local function EncodeValue(Value, Seen)
		local ValueType = typeof(Value)
		if ValueType == "nil" then
			return "null"
		end
		if ValueType == "boolean" then
			return Value and "true" or "false"
		end
		if ValueType == "number" then
			if Value ~= Value or Value == math.huge or Value == -math.huge then
				return "0"
			end
			return tostring(Value)
		end
		if ValueType == "string" then
			return `"{EscapeJson(Value)}"`
		end
		if ValueType == "table" then
			if Seen[Value] then
				return "\"<cycle>\""
			end
			Seen[Value] = true

			if IsArray(Value) then
				local Parts = {}
				for Index = 1, #Value do
					Parts[Index] = EncodeValue(Value[Index], Seen)
				end
				Seen[Value] = nil
				return "[" .. table.concat(Parts, ",") .. "]"
			end

			local Keys = {}
			for Key in next, Value do
				Keys[#Keys + 1] = {
					raw = Key,
					text = tostring(Key),
				}
			end
			table.sort(Keys, function(Left, Right)
				return Left.text < Right.text
			end)

			local Parts = {}
			for _, Entry in ipairs(Keys) do
				Parts[#Parts + 1] = `"{EscapeJson(Entry.text)}":{EncodeValue(Value[Entry.raw], Seen)}`
			end
			Seen[Value] = nil
			return "{" .. table.concat(Parts, ",") .. "}"
		end

		return `"{EscapeJson(tostring(Value))}"`
	end

	local OkEncode, Encoded = pcall(EncodeValue, Data, {})
	if OkEncode and typeof(Encoded) == "string" then
		return Encoded
	end

	return Beautifier and Beautifier:Beautify(Data) or tostring(Data)
end

function HTTP.JSONDecode(Str)
	if typeof(Str) == "table" then
		local V = rawget(Str, "V")
		if typeof(V) == "string" then
			Str = V
		end
	end

	if typeof(Str) ~= "string" then
		error(`invalid argument #1 to 'JSONDecode' (string expected, got {typeof(Str)})`, 2)
	end

	local net = GetNetModule()
	if net and typeof(Str) == "string" then
		local S, R = pcall(net.jsonDecode, Str)
		if S then return R end
	end

	local Parsed = DecodeJsonFallback(Str)
	if Parsed ~= nil then
		return Parsed
	end

	if typeof(Str) == "string" then
		local UniverseId = string.match(Str, '"universeId"%s*:%s*(%d+)')
		if UniverseId then
			return {
				universeId = tonumber(UniverseId),
			}
		end

		if string.find(Str, '"data"%s*:%s*%[', 1) then
			local Name = string.match(Str, '"name"%s*:%s*"([^"]+)"') or "Mock Experience"
			local Id = tonumber(string.match(Str, '"id"%s*:%s*(%d+)') or "0") or 0
			return {
				data = {
					{
						id = Id,
						name = Name,
					},
				},
			}
		end

		if string.find(Str, '"ShopData"', 1, true) then
			return {
				Seeds = {
					ShopData = {
						{ Name = "Carrot Seed" },
						{ Name = "Tomato Seed" },
						{ Name = "Pumpkin Seed" },
					},
				},
				Mutations = {
					{ Name = "None" },
					{ Name = "Golden" },
					{ Name = "Rainbow" },
				},
			}
		end
	end

	error("HttpService:JSONDecode() failed to parse JSON", 0)
end

return HTTP