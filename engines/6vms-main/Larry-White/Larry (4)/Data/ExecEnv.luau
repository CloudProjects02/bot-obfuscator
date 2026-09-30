local Find = table.find

local ExecEnv = {}

ExecEnv.Names = {
	"game", "workspace", "script", "Instance", "Enum",
	"Vector3", "Vector2", "Vector3int16", "Vector2int16",
	"UDim", "UDim2", "CFrame", "Color3", "BrickColor",
	"Ray", "Axes", "Faces", "Region3", "Region3int16",
	"Rect", "NumberRange", "PhysicalProperties",
	"TweenInfo", "RaycastParams", "OverlapParams", "Random",
	"ColorSequence", "ColorSequenceKeypoint",
	"NumberSequenceKeypoint", "NumberSequence",
	"SharedTable", "shared", "Font", "DateTime",
	"PathWaypoint", "RotationCurveKey", "SecurityCapabilities",
	"ValueCurveKey", "CatalogSearchParams", "FloatCurve",
	"FloatCurveKey", "Path2DControlPoint",
	"cache", "cloneref", "compareinstances", "checkcaller",
	"clonefunction", "getcallingscript", "getscriptclosure",
	"hookfunction", "iscclosure", "islclosure", "isexecutorclosure",
	"loadstring", "newcclosure",
	"rconsoleclear", "rconsolecreate", "rconsoledestroy",
	"rconsoleinput", "rconsoleprint", "rconsolesettitle",
	"crypt", "debug",
	"readfile", "listfiles", "writefile", "makefolder",
	"appendfile", "isfile", "isfolder", "delfolder", "delfile",
	"loadfile", "dofile",
	"isrbxactive",
	"mouse1click", "mouse1press", "mouse1release",
	"mouse2click", "mouse2press", "mouse2release",
	"mousemoveabs", "mousemoverel", "mousescroll",
	"fireclickdetector",
	"getcallbackvalue", "getconnections", "getcustomasset",
	"gethiddenproperty", "sethiddenproperty",
	"syn", "gethui", "getinstances", "getnilinstances",
	"isscriptable", "setscriptable",
	"setrbxclipboard", "getrawmetatable", "hookmetamethod",
	"getnamecallmethod", "isreadonly", "setrawmetatable", "setreadonly",
	"identifyexecutor",
	"lz4compress", "lz4decompress",
	"messagebox", "request", "setclipboard", "setfpscap",
	"getgc", "getgenv", "getloadedmodules", "getrenv",
	"getrunningscripts", "getscriptbytecode", "getscripthash",
	"getscripts", "getsenv",
	"getthreadidentity", "setthreadidentity",
	"Drawing", "isrenderobj", "getrenderproperty", "setrenderproperty",
	"cleardrawcache", "WebSocket",
	"getfenv", "coroutine", "math", "string", "table", "os",
	"utf8", "bit32", "buffer", "vector",
	"elapsedTime", "settings", "tick", "time", "typeof",
	"UserSettings", "version", "warn", "plugin", "shared",
	"assert", "error", "gcinfo", "getmetatable", "ipairs",
	"newproxy", "next", "pairs", "pcall", "print",
	"rawequal", "rawget", "rawlen", "rawset", "require",
	"select", "setmetatable", "tostring", "unpack", "xpcall",
	"_G", "_VERSION", "Game", "Workspace",
	"gethwid", "delay",
	"queue_on_teleport", "queueonteleport",
	"http_request", "httprequest",
	"restorefunction", "isfunctionhooked",
	"hookallcalls", "hookallnamecalls",
	"base64decode", "base64encode",
	"is_l_closure",
}

local NameSet = {}
for _, Name in ExecEnv.Names do
	NameSet[Name] = true
end

function ExecEnv.IsSafe(Key)
	return NameSet[Key] == true
end

local VarCounters = {}

function ExecEnv.Deglobal(Text)
	if not NameSet[Text] then
		return Text
	end

	local Count = VarCounters[Text] or 0
	Count += 1
	VarCounters[Text] = Count

	return Count == 1 and Text or `{Text}{Count}`
end

function ExecEnv.ResetCounters()
	table.clear(VarCounters)
end

function ExecEnv.Contains(Key)
	return Find(ExecEnv.Names, Key) ~= nil
end

local IgnorePatterns = {
	"^[A-Z][a-z]+[A-Z]",
	"^_[_a-z]",
}

function ExecEnv.ShouldIgnore(Key, KeyLen)
	if NameSet[Key] then return false end

	for _, Pattern in IgnorePatterns do
		if string.match(Key, Pattern) then
			return true
		end
	end

	return false
end

return ExecEnv