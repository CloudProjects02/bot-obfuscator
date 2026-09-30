local ExecEnv = require("../Data/ExecEnv")
local Constants = require("../Data/Constants")

local AntiTamper = {}

local BypassLog = {}
local DetectorErrorCodes25ms = {
	[""] = true,
	["PT"] = true,
	["2m"] = true,
	["a-t"] = true,
	["LGH"] = true,
	["N"] = true,
	["BCE"] = true,
	["BVH"] = true,
	["UN"] = true,
	["TWSPE"] = true,
	["THWSPE"] = true,
}

function AntiTamper.DetectMoonveil(Source)
	if typeof(Source) ~= "string" then return false end

	local Markers = {
		"moonveil",
		"MoonVeil",
		"moon_veil",
	}

	for _, Marker in Markers do
		if string.find(Source, Marker, 1, true) then
			return true
		end
	end

	return false
end

function AntiTamper.Detect25ms(Source)
	if typeof(Source) ~= "string" then return false end

	local Markers = {
		"25ms",
		"twentyfivems",
	}

	for _, Marker in Markers do
		if string.find(Source, Marker, 1, true) then
			return true
		end
	end

	return false
end

function AntiTamper.DetectKolobf(Source)
	if typeof(Source) ~= "string" then return false end

	local Markers = {
		"Kolobf_detected",
		"Kolobfdetected",
		"Kolobf by Jerry",
	}

	for _, Marker in Markers do
		if string.find(Source, Marker, 1, true) then
			return true
		end
	end

	return false
end

function AntiTamper.ShouldBypass25msWarn(Message)
	if typeof(Message) ~= "string" then
		return false
	end

	local Lower = string.lower(Message)
	if string.find(Lower, "detect", 1, true) then
		return true
	end
	if string.find(Lower, "25ms", 1, true) then
		return true
	end

	return false
end

function AntiTamper.ShouldBypass25msError(Message)
	if typeof(Message) ~= "string" then
		return false
	end

	if DetectorErrorCodes25ms[Message] == true then
		return true
	end

	local Lower = string.lower(Message)
	if string.find(Lower, "detected", 1, true) then
		return true
	end
	if string.find(Lower, "bootleg hookop dtc", 1, true) then
		return true
	end

	return false
end

function AntiTamper.DetectLPHCrash(Source)
	if typeof(Source) ~= "string" then return false end
	return string.find(Source, "LPH_CRASH", 1, true) ~= nil
end

function AntiTamper.DetectGlobalAssignment(Key, Value)
	if typeof(Value) ~= "function" then return false end

	local ExecNames = ExecEnv.Names

	for _, Name in ExecNames do
		if Key == Name then
			return true
		end
	end

	return false
end

function AntiTamper.IsJunkGlobalAssignment(Key, Value)
	if typeof(Value) ~= "function" then return false end

	local Info = debug.info(Value, "s")
	if Info == "[C]" then return false end

	local Dangerous = {
		"Detected",
		"detected",
		"tamper",
		"Tamper",
		"crash",
		"Crash",
		"kick",
		"Kick",
	}

	return AntiTamper.DetectGlobalAssignment(Key, Value)
end

function AntiTamper.SanitizeEnvCheck(Key, FenvRef)
	if not ExecEnv.IsSafe(Key) then
		return FenvRef[Key]
	end
	return nil
end

function AntiTamper.PristineCheck(Source)
	if typeof(Source) ~= "string" then return false end

	local Markers = {
		"pristine",
		"Pristine",
		"PRISTINE",
	}

	for _, Marker in Markers do
		if string.find(Source, Marker, 1, true) then
			return true
		end
	end

	return false
end

function AntiTamper.BypassGetfenv(NestLevel, LockedEnv, MaxLevel)
	MaxLevel = MaxLevel or 5

	if typeof(NestLevel) ~= "number" then
		return nil, false
	end

	if NestLevel ~= NestLevel then
		return LockedEnv, true
	end

	if NestLevel == math.huge or NestLevel == -math.huge then
		return LockedEnv, true
	end

	if NestLevel % 1 ~= 0 then
		return LockedEnv, true
	end

	if NestLevel < 0 or NestLevel > MaxLevel then
		return nil, false
	end

	return LockedEnv, true
end

function AntiTamper.ShouldIgnoreJunk(Key, Value, LastKey, LastValue)
	if Key == LastKey and typeof(Value) == typeof(LastValue) then
		if typeof(Value) == "string" and Value == LastValue then
			return true
		end
	end

	return false
end

function AntiTamper.LogBypass(Name, Details)
	table.insert(BypassLog, {
		Name = Name,
		Details = Details,
		Time = os.clock(),
	})
end

function AntiTamper.GetLog()
	return BypassLog
end

function AntiTamper.ClearLog()
	table.clear(BypassLog)
end

function AntiTamper.FilterTrace(Trace, TraceId)
	local Lines = string.split(Trace, "\n")
	local Result = {}

	for _, Line in Lines do
		if not string.match(Line, '%[string ".*hi"%]') then
			Line = string.gsub(Line, 'string "luau%.load%(.-%)\"', TraceId)
			table.insert(Result, Line)
		end
	end

	return table.concat(Result, "\n")
end

function AntiTamper.WrapPcallError(Message, TraceId)
	if typeof(Message) ~= "string" then return Message end

	Message = string.gsub(Message, TraceId, "Script")
	Message = string.gsub(Message, "luau%.load%(.-%)", "Script")

	return Message
end

return AntiTamper