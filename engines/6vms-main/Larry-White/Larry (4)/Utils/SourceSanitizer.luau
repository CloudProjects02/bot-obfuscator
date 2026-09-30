local SourceSanitizer = {}

local SourceRoots = {
	"Core",
	"CodeGen",
	"Env",
	"Flow",
	"Hooks",
	"IO",
	"Libs",
	"Macros",
	"PostProcess",
	"Roblox",
	"Utils",
	"Data",
}

local function NormalizePath(Value)
	if typeof(Value) ~= "string" then
		return Value
	end

	return string.gsub(Value, "\\", "/")
end

local function StripPrefix(Value)
	if typeof(Value) ~= "string" then
		return Value
	end

	while string.sub(Value, 1, 1) == "=" or string.sub(Value, 1, 1) == "@" do
		Value = string.sub(Value, 2)
	end

	return Value
end

local function FindRelativeSource(Value)
	if typeof(Value) ~= "string" or Value == "" then
		return nil
	end

	local Normalized = StripPrefix(NormalizePath(Value))
	if typeof(Normalized) ~= "string" or Normalized == "" then
		return nil
	end

	for _, Root in ipairs(SourceRoots) do
		local Needle = "/" .. Root .. "/"
		local Start = string.find(Normalized, Needle, 1, true)
		if Start ~= nil then
			return string.sub(Normalized, Start + 1)
		end

		if string.sub(Normalized, 1, #Root + 1) == Root .. "/" then
			return Normalized
		end
	end

	if string.find(string.lower(Normalized), "larry.run", 1, true) then
		return "larry.run"
	end

	return nil
end

local function IsAbsolutePath(Value)
	if typeof(Value) ~= "string" or Value == "" then
		return false
	end

	return string.match(Value, "^[A-Za-z]:/") ~= nil or string.sub(Value, 1, 1) == "/"
end

local function ShortLabel(Value)
	if typeof(Value) ~= "string" or Value == "" then
		return ""
	end

	local Relative = FindRelativeSource(Value)
	local Target = Relative or StripPrefix(NormalizePath(Value))
	if typeof(Target) ~= "string" or Target == "" then
		return ""
	end

	local Label = string.match(Target, "[^/]+$") or Target
	Label = string.gsub(Label, "%.luau?$", "")
	return Label
end

function SourceSanitizer.NormalizePath(Value)
	return NormalizePath(Value)
end

function SourceSanitizer.StripPrefix(Value)
	return StripPrefix(Value)
end

function SourceSanitizer.FindRelativeSource(Value)
	return FindRelativeSource(Value)
end

function SourceSanitizer.IsAbsolutePath(Value)
	return IsAbsolutePath(Value)
end

function SourceSanitizer.IsInternalSource(Value)
	return FindRelativeSource(Value) ~= nil
end

function SourceSanitizer.ShortLabel(Value)
	return ShortLabel(Value)
end

function SourceSanitizer.SanitizeFileLabel(Name)
	if typeof(Name) ~= "string" or Name == "" then
		return nil
	end

	local Normalized = StripPrefix(NormalizePath(Name))
	if typeof(Normalized) ~= "string" or Normalized == "" then
		return nil
	end

	if string.find(string.lower(Normalized), "larry.run", 1, true) then
		return nil
	end

	if FindRelativeSource(Normalized) ~= nil or IsAbsolutePath(Normalized) then
		local Label = ShortLabel(Normalized)
		if Label == "" or Label == "larry.run" then
			return nil
		end
		return Label
	end

	return Normalized
end

function SourceSanitizer.SanitizeDebugSource(Source, InternalAsC)
	if typeof(Source) ~= "string" or Source == "" then
		return "=[C]", "[C]", "C"
	end

	if Source == "[C]" or Source == "=[C]" then
		return "=[C]", "[C]", "C"
	end

	local Normalized = StripPrefix(NormalizePath(Source))
	if typeof(Normalized) ~= "string" or Normalized == "" then
		return "=[C]", "[C]", "C"
	end

	if string.match(Normalized, "^%[string .+%]$") then
		return "=" .. Normalized, Normalized, "Lua"
	end

	if FindRelativeSource(Normalized) ~= nil or IsAbsolutePath(Normalized) then
		if InternalAsC ~= false then
			return "=[C]", "[C]", "C"
		end

		local Label = ShortLabel(Normalized)
		if Label == "" then
			return "=[C]", "[C]", "C"
		end
		return "=" .. Label, Label, "Lua"
	end

	return "=" .. Normalized, Normalized, "Lua"
end

function SourceSanitizer.SanitizeTraceText(Message)
	if typeof(Message) ~= "string" then
		return Message
	end

	local Result = NormalizePath(Message)

	Result = string.gsub(Result, "[A-Za-z]:/[^:\n]-/Larry/", "")
	Result = string.gsub(Result, "/[^:\n]-/Larry/", "")
	Result = string.gsub(Result, "[A-Za-z]:/[^:\n]-/larryenv/", "")
	Result = string.gsub(Result, "/[^:\n]-/larryenv/", "")

	for _, Root in ipairs(SourceRoots) do
		Result = string.gsub(Result, "[A-Za-z]:/[^:\n]-/" .. Root .. "/", Root .. "/")
		Result = string.gsub(Result, "/[^:\n]-/" .. Root .. "/", Root .. "/")
	end

	Result = string.gsub(Result, "[A-Za-z]:/[^:\n]-/larry%.run", "larry.run")
	Result = string.gsub(Result, "/[^:\n]-/larry%.run", "larry.run")

	return Result
end

return SourceSanitizer