local UNCProfiles = {}

local ALIAS_PAIRS = {
	{ "hookfunc", "hookfunction" },
	{ "replacefunc", "replaceclosure" },
	{ "dumpstring", "getscriptbytecode" },
	{ "getidentity", "getthreadidentity" },
	{ "getthreadcontext", "getthreadidentity" },
	{ "setidentity", "setthreadidentity" },
	{ "setthreadcontext", "setthreadidentity" },
	{ "getexecutorname", "identifyexecutor" },
	{ "isgameactive", "isrbxactive" },
	{ "checkclosure", "isexecutorclosure" },
	{ "isourclosure", "isexecutorclosure" },
	{ "queueonteleport", "queue_on_teleport" },
	{ "consoleclear", "rconsoleclear" },
	{ "consolecreate", "rconsolecreate" },
	{ "consoledestroy", "rconsoledestroy" },
	{ "consoleinput", "rconsoleinput" },
	{ "consoleprint", "rconsoleprint" },
	{ "consolewarn", "rconsolewarn" },
	{ "consoleerr", "rconsoleerr" },
	{ "consolesettitle", "rconsolesettitle" },
	{ "rconsolename", "rconsolesettitle" },
	{ "toclipboard", "setclipboard" },
	{ "save_instance", "saveinstance" },
	{ "runonactor", "run_on_actor" },
	{ "base64_encode", "base64encode" },
	{ "base64_decode", "base64decode" },
	{ "http_request", "request" },
	{ "request", "request" },
}

local DOTTED_ALIASES = {
	{ "cache.invalidate", "cache", "invalidate" },
	{ "cache.iscached", "cache", "iscached" },
	{ "cache.replace", "cache", "replace" },
	{ "crypt.base64encode", "crypt", "base64encode" },
	{ "crypt.base64decode", "crypt", "base64decode" },
	{ "crypt.base64_encode", "crypt", "base64encode" },
	{ "crypt.base64_decode", "crypt", "base64decode" },
	{ "crypt.encrypt", "crypt", "encrypt" },
	{ "crypt.decrypt", "crypt", "decrypt" },
	{ "crypt.generatebytes", "crypt", "generatebytes" },
	{ "crypt.generatekey", "crypt", "generatekey" },
	{ "crypt.hash", "crypt", "hash" },
}

local OPTIONAL_STUBS = {
	gethostenv = function(Context)
		if Context and Context.LockedEnv then
			return Context.LockedEnv
		end
		local Ok, Env = pcall(getfenv)
		if Ok and typeof(Env) == "table" then
			return Env
		end
		return {}
	end,
	setstackhidden = function(...)
		return nil
	end,
	isexecutorclosure = function(F)
		return typeof(F) == "function"
	end,
	isfunctionhooked = function()
		return false
	end,
}

local function AssignAlias(Env, AliasName, CanonicalName)
	if typeof(Env) ~= "table" then
		return
	end
	if Env[AliasName] ~= nil then
		return
	end
	local Target = Env[CanonicalName]
	if Target ~= nil then
		Env[AliasName] = Target
	end
end

local function AssignDottedAlias(Env, AliasName, RootName, MemberName)
	if typeof(Env) ~= "table" then
		return
	end
	if Env[AliasName] ~= nil then
		return
	end
	local Root = Env[RootName]
	if typeof(Root) ~= "table" then
		return
	end
	local Member = Root[MemberName]
	if Member ~= nil then
		Env[AliasName] = Member
	end
end

function UNCProfiles.ApplyAliases(Env)
	for _, Pair in next, ALIAS_PAIRS do
		AssignAlias(Env, Pair[1], Pair[2])
	end

	for _, Pair in next, DOTTED_ALIASES do
		AssignDottedAlias(Env, Pair[1], Pair[2], Pair[3])
	end
end

function UNCProfiles.ApplyOptionals(Env, Context)
	for Name, Stub in next, OPTIONAL_STUBS do
		if Env[Name] == nil then
			Env[Name] = function(...)
				return Stub(Context, ...)
			end
		end
	end
end

function UNCProfiles.Apply(Env, Context)
	UNCProfiles.ApplyAliases(Env)
	UNCProfiles.ApplyOptionals(Env, Context)
	return Env
end

return UNCProfiles