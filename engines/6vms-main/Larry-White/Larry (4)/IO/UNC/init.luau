local ContextMod = require("./UNC/context")
local Register = require("./UNC/register")
local DrawingApi = require("./UNC/features/drawing_api")
local CryptoApi = require("./UNC/features/crypto_api")
local HttpApi = require("./UNC/features/http_api")
local DebugApi = require("./UNC/features/debug_api")
local FilesystemApi = require("./UNC/features/filesystem_api")
local HooksMod = require("./UNC/features/hooks")
local MetatableMod = require("./UNC/features/metatable")
local InstanceApi = require("./UNC/features/instance_api")
local ThreadApi = require("./UNC/features/thread_api")
local ClipboardConsoleApi = require("./UNC/features/clipboard_console_api")
local ExecutorMetaApi = require("./UNC/features/executor_meta_api")
local AliasesProfile = require("./UNC/profiles/aliases")
local OptionalsProfile = require("./UNC/profiles/optionals")

local UNC = {}

function UNC.Build(Proxy, State, Emitter, Beautifier, Scope, Config, Hierarchy)
	local Ctx = ContextMod.new()

	local drawResult = DrawingApi.Build(Ctx)
	local CryptLib = CryptoApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope)
	local httpResult = HttpApi.Build(Ctx, Emitter, Beautifier)
	local DebugLib = DebugApi.Build(Ctx, State)
	local fsResult = FilesystemApi.Build(Ctx)
	local hooksResult = HooksMod.Build(Ctx, Emitter, Beautifier)
	local mtResult = MetatableMod.Build(Ctx, State, Emitter, Beautifier)
	local instResult = InstanceApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope, Hierarchy)
	local threadResult = ThreadApi.Build(Ctx, Emitter, Beautifier)
	local clipResult = ClipboardConsoleApi.Build(Ctx, Emitter, Beautifier)
	local execResult = ExecutorMetaApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope, Hierarchy)

	local Env = {}

	local function MergeInto(Source)
		for K, V in next, Source do
			if Env[K] == nil then
				Env[K] = V
			end
		end
	end

	Env.Drawing = drawResult.Drawing
	Env.isrenderobj = drawResult.isrenderobj
	Env.cleardrawcache = drawResult.cleardrawcache
	Env.getrenderproperty = drawResult.getrenderproperty
	Env.setrenderproperty = drawResult.setrenderproperty

	Env.crypt = CryptLib

	Env.http = httpResult.http
	Env.WebSocket = httpResult.WebSocket
	Env.cache = httpResult.cache
	Env.request = httpResult.request
	Env.httpget = httpResult.httpget

	Env.debug = DebugLib

	MergeInto(fsResult)

	MergeInto(hooksResult)

	MergeInto(mtResult)

	MergeInto(instResult)

	MergeInto(threadResult)

	MergeInto(clipResult)

	MergeInto(execResult)

	Env.http_request = function(Options)
		return Env.request(Options)
	end

	Env.base64 = CryptLib.base64
	Env.base64encode = CryptLib.base64encode
	Env.base64decode = CryptLib.base64decode
	Env.base64_encode = CryptLib.base64encode
	Env.base64_decode = CryptLib.base64decode
	Env["cache.invalidate"] = httpResult.cache.invalidate
	Env["cache.iscached"] = httpResult.cache.iscached
	Env["cache.replace"] = httpResult.cache.replace
	Env["crypt.base64encode"] = CryptLib.base64encode
	Env["crypt.base64decode"] = CryptLib.base64decode
	Env["crypt.encrypt"] = CryptLib.encrypt
	Env["crypt.decrypt"] = CryptLib.decrypt
	Env["crypt.generatebytes"] = CryptLib.generatebytes
	Env["crypt.generatekey"] = CryptLib.generatekey
	Env["crypt.hash"] = CryptLib.hash
	Env.crypt.base64_encode = CryptLib.base64encode
	Env.crypt.base64_decode = CryptLib.base64decode

	Env.hookfunc = Env.hookfunction
	Env.replacefunc = Env.replaceclosure
	Env.dumpstring = Env.getscriptbytecode
	Env.getidentity = Env.getthreadidentity
	Env.getthreadcontext = Env.getthreadidentity
	Env.getexecutorname = Env.identifyexecutor
	Env.isgameactive = Env.isrbxactive
	Env.checkclosure = Env.isexecutorclosure
	Env.isourclosure = Env.isexecutorclosure
	Env.queueonteleport = Env.queue_on_teleport
	Env.consoleclear = Env.rconsoleclear
	Env.consolecreate = Env.rconsolecreate
	Env.consoledestroy = Env.rconsoledestroy
	Env.consoleinput = Env.rconsoleinput
	Env.consoleprint = Env.rconsoleprint
	Env.rconsolename = Env.rconsolesettitle
	Env.consolesettitle = Env.rconsolesettitle
	Env.consolewarn = Env.rconsolewarn
	Env.consoleerr = Env.rconsoleerr
	Env.toclipboard = Env.setclipboard
	Env.setidentity = Env.setthreadidentity
	Env.setthreadcontext = Env.setthreadidentity
	Env.getstack = DebugLib.getstack
	Env.getprotos = DebugLib.getprotos
	Env.getupvalues = DebugLib.getupvalues
	Env.getupvalue = DebugLib.getupvalue
	Env.setupvalue = DebugLib.setupvalue
	Env.getconstants = DebugLib.getconstants
	Env.getconstant = DebugLib.getconstant
	Env.setconstant = DebugLib.setconstant
	Env.setstack = DebugLib.setstack
	Env.save_instance = Env.saveinstance
	Env.runonactor = Env.run_on_actor
	Env.dumperState = {
		property_store = {},
	}
	Env._at = {}
	Env._byp_require = true
	Env.raknet = {
		add_send_hook = function(Callback)
			if typeof(Callback) == "function" then
				Callback({
					PacketId = 0,
					Size = 0,
					AsBuffer = "",
				})
			end
		end,
	}

	do
		local NativeTable = table
		local NativeIsFrozen = typeof(NativeTable) == "table" and typeof(NativeTable.isfrozen) == "function" and NativeTable.isfrozen or nil
		local NativeFreeze = typeof(NativeTable) == "table" and typeof(NativeTable.freeze) == "function" and NativeTable.freeze or nil
		local TableCompat = {}

		for Key, Value in next, NativeTable do
			TableCompat[Key] = Value
		end

		TableCompat.freeze = function(Tbl)
			if typeof(Tbl) ~= "table" then
				error("invalid argument #1 to 'freeze' (table expected)")
			end
			Ctx.readonly_tables[Tbl] = true
			return Tbl
		end

		TableCompat.isfrozen = function(Tbl)
			if typeof(Tbl) ~= "table" then
				return false
			end

			local NativeFrozen = false
			if NativeIsFrozen ~= nil then
				local OkFrozen, IsFrozen = pcall(NativeIsFrozen, Tbl)
				if OkFrozen then
					NativeFrozen = IsFrozen == true
				end
			end

			if NativeFrozen then
				return true
			end

			local Tracked = Ctx.readonly_tables[Tbl]
			if Tracked ~= nil then
				return Tracked
			end

			return NativeFrozen
		end

		Env.table = TableCompat
	end

	local function MarkBuiltin(Func)
		Register.MarkBuiltin(Ctx, Func)
	end

	for _, Fn in {
		print, warn, error, assert, pcall, xpcall,
		type, typeof, tostring, tonumber, next, pairs, ipairs,
		rawget, rawset, rawequal, rawlen, select, require,
		setmetatable, getmetatable,
	} do
		MarkBuiltin(Fn)
	end

	if typeof(table) == "table" then
		for _, Name in { "insert", "remove", "sort", "concat", "move", "pack", "unpack", "freeze", "isfrozen", "clone" } do
			MarkBuiltin(table[Name])
		end
	end

	if typeof(string) == "table" then
		for _, Name in { "format", "sub", "len", "byte", "char", "find", "gsub", "gmatch", "match", "split" } do
			MarkBuiltin(string[Name])
		end
	end

	if typeof(math) == "table" then
		for _, Name in { "random", "randomseed", "sin", "cos", "sqrt", "abs", "floor", "ceil", "log" } do
			MarkBuiltin(math[Name])
		end
	end

	AliasesProfile.Apply(Env)
	OptionalsProfile.Apply(Env, {
		LockedEnv = getfenv(),
	})

	Env.syn = false
	Env.fluxus = false
	Env.krnl = false
	Env.scriptware = false

	Ctx.genv_shared.__index = Ctx.genv_shared
	setmetatable(Ctx.genv_shared, {
		__index = Env,
		__newindex = function(_, k, v)
			rawset(Ctx.genv_shared, k, v)
		end,
	})

	return Env
end

return UNC