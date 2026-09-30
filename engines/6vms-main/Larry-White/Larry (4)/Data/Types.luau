local Find = table.find

local Types = {}

Types.Map = {
	["table"] = {
		"syn", "syn.crypt", "syn.oth", "synapse", "krnl", "fluxus",
		"protosmasher", "debug", "bit", "Drawing", "WebSocket",
		"cache", "shared", "_G", "syn.crypto", "crypt", "crypto",
		"getfenv()", "getgenv()", "getrenv()", "http",
		"math", "string", "table", "os", "coroutine",
	},
	["function"] = {
		"checkcaller", "getgenv", "getrenv", "getreg", "getgc", "getinstances",
		"getnilinstances", "getscripts", "getloadedmodules",
		"getconnections", "firesignal", "fireclickdetector",
		"firetouchinterest", "replicatesignal", "getsenv", "gettenv",
		"getmenv", "getcallingscript",
		"syn.cache_replace", "syn.cache_invalidate",
		"syn.set_thread_identity", "syn.get_thread_identity",
		"syn.is_cached", "syn.protect_gui", "syn.unprotect_gui",
		"syn.queue_on_teleport", "syn.secure_call",
		"syn.create_secure_function", "syn.run_secure_function",
		"syn.request", "syn.write_clipboard", "syn.is_beta",
		"hookfunction", "hookmetamethod", "clonefunction", "newcclosure",
		"setstackhidden", "isfunctionhooked", "restorefunction",
		"syn.crypt.base64", "syn.crypt.hex", "syn.crypt.lz4",
		"syn.crypt.zstd", "syn.crypt.derive", "syn.crypt.url",
		"syn.crypt.user.prompt", "syn.crypt.sign.detached",
		"syn.crypt.seal", "syn.crypt.custom",
		"mouse1click", "mouse1press", "mouse1release",
		"mouse2click", "mouse2press", "mouse2release",
		"mousemoveabs", "mousemoverel", "mousescroll",
		"fireclickdetector", "fireproximityprompt", "firetouchinterest",
		"iswindowactive", "keypress", "keyrelease", "isnetworkowner",
		"readfile", "writefile", "appendfile", "loadfile", "listfiles",
		"isfile", "isfolder", "makefolder", "delfolder", "delfile",
		"setclipboard", "setrbxclipboard", "setfflag",
		"getnamecallmethod", "setnamecallmethod", "saveinstance",
		"gethiddenproperty", "sethiddenproperty", "setsimulationradius",
		"debug.getupvalue", "debug.getupvalues", "debug.getstack",
		"debug.getproto", "debug.getprotos",
		"Drawing.new", "Drawing.Fonts",
		"http.request", "WebSocket.connect",
		"typeof", "elapsedTime", "UserSettings", "warn",
		"assert", "error", "gcinfo", "getmetatable", "setmetatable",
		"ipairs", "pairs", "next", "newproxy", "pcall", "xpcall",
		"print", "rawequal", "rawget", "rawset", "rawlen",
		"require", "select", "tick", "time",
		"coroutine.create", "coroutine.resume", "coroutine.yield",
		"request",
	},
	["Instance"] = {
		"game", "workspace", "Game", "Workspace",
		"game.Workspace", "Game.Workspace",
	},
}

local LookupCache = {}

local function BuildCache()
	for TypeName, List in next, Types.Map do
		for _, Name in List do
			LookupCache[Name] = TypeName
		end
	end
end

BuildCache()

function Types.GetType(Name)
	local Actual = typeof(Name)
	if Actual ~= "string" then
		return Actual
	end
	return LookupCache[Name]
end

function Types.Register(TypeName, Name)
	if not Types.Map[TypeName] then
		Types.Map[TypeName] = {}
	end

	table.insert(Types.Map[TypeName], Name)
	LookupCache[Name] = TypeName
end

function Types.IsInstancePath(Name)
	return LookupCache[Name] == "Instance"
end

function Types.IsFunction(Name)
	return LookupCache[Name] == "function"
end

function Types.IsTable(Name)
	return LookupCache[Name] == "table"
end

return Types