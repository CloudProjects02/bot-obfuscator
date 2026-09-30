local ExecEnv = require("../../Data/ExecEnv")
local Constants = require("../../Data/Constants")
local Types = require("../../Data/Types")
local StringUtil = require("../../Utils/String")
local ErrorSanitizer = require("../../Utils/ErrorSanitizer")
local AntiTamper = require("../AntiTamper")
local Instance = require("../../Roblox/Instance")
local Signals = require("../../Roblox/Signals")
local Enums = require("../../Roblox/Enums")
local RuntimeClock = require("../../Roblox/RuntimeClock")

local StandardEnv = {}

local function CloneTable(Source)
	local Out = {}
	if typeof(Source) ~= "table" then
		return Out
	end

	for Key, Value in next, Source do
		Out[Key] = Value
	end

	return Out
end

local function Utf8CodepointSpan(Text, Index)
	local FirstByte = string.byte(Text, Index)
	if FirstByte == nil then
		return 0
	end
	if FirstByte < 0x80 then
		return 1
	end
	if FirstByte < 0xE0 then
		return 2
	end
	if FirstByte < 0xF0 then
		return 3
	end
	return 4
end

local function BuildUtf8Compat(SourceUtf8)
	local Utf8Lib = CloneTable(SourceUtf8)
	if typeof(Utf8Lib.graphemes) == "function" then
		return Utf8Lib
	end

	Utf8Lib.graphemes = function(Text)
		if typeof(Text) ~= "string" then
			error("bad argument #1 to 'graphemes' (string expected)", 2)
		end

		local Length = #Text
		local Cursor = 1

		return function()
			if Cursor > Length then
				return nil
			end

			local Start = Cursor
			local Span = Utf8CodepointSpan(Text, Cursor)
			if Span <= 0 then
				return nil
			end
			Cursor += Span

			return Start, Cursor - 1
		end
	end

	return Utf8Lib
end

local function FreezeTableCopy(Source)
	if typeof(Source) ~= "table" then
		return Source
	end

	local Copy = {}
	for Key, Value in next, Source do
		Copy[Key] = Value
	end

	if typeof(table.freeze) == "function" then
		pcall(table.freeze, Copy)
	end

	return Copy
end

function StandardEnv.Build(Deps)
	local State = Deps.State
	local Proxy = Deps.Proxy
	local Emitter = Deps.Emitter
	local Beautifier = Deps.Beautifier
	local Scope = Deps.Scope
	local Config = Deps.Config
	local Hooks = Deps.Hooks
	local Iteration = Deps.Iteration
	local Loaders = Deps.Loaders
	local TrueEnv = Deps.TrueEnv
	local AntiTamperFlags = Deps.AntiTamperFlags or {}

	local Locked
	local EnvIndexLogged = {}
	local MaxOps = Config.max_ops or Constants.Limits.MaxOperations
	local MaxLogCalls = Config.max_log_calls or math.max(256, math.floor(MaxOps * 0.25))
	local MaxRepeatedLogs = Config.max_repeated_logs or 20
	local MaxSuppressedLogs = Config.max_suppressed_logs or 200
	local MaxLogPayloadChars = Config.max_log_payload_chars or 600
	if Config.lm then
		MaxLogCalls = math.max(MaxLogCalls, 100000)
		MaxRepeatedLogs = math.max(MaxRepeatedLogs, 5000)
		MaxSuppressedLogs = math.max(MaxSuppressedLogs, 100000)
		MaxLogPayloadChars = math.max(MaxLogPayloadChars, 4000)
	end
	local TotalLogCalls = 0

	local Env = {}
	local ProxyUserdataTag = setmetatable({}, { __mode = "k" })

	for K, V in next, Hooks do
		Env[K] = V
	end

	if Env["_ENV_RESULTS"] == nil then
		Env["_ENV_RESULTS"] = {}
	end
	if Env["_PASS"] == nil then
		Env["_PASS"] = true
	end

	for _, Name in Constants.WrappedFunctions do
		if TrueEnv[Name] and Env[Name] == nil then
			Env[Name] = Proxy:SafeWrap(TrueEnv[Name], Name)
		end
	end

	for _, Name in Constants.PassthroughFunctions do
		if TrueEnv[Name] and Env[Name] == nil then
			Env[Name] = TrueEnv[Name]
		end
	end

	for _, Name in Constants.PassthroughTables do
		if TrueEnv[Name] and Env[Name] == nil then
			Env[Name] = TrueEnv[Name]
		end
	end

	for _, Name in { "utf8", "buffer", "vector" } do
		if TrueEnv[Name] and Env[Name] == nil then
			Env[Name] = TrueEnv[Name]
		end
	end

	if Env["utf8"] == nil then
		Env["utf8"] = {}
	end
	if typeof(Env["utf8"]) == "table" then
		Env["utf8"] = BuildUtf8Compat(Env["utf8"])
	end

	if TrueEnv["vector"] and typeof(TrueEnv["vector"]) == "table" and TrueEnv["vector"].cross then
		Env["vector"] = TrueEnv["vector"]
	end

	if typeof(Env["math"]) == "table" then
		Env["math"] = FreezeTableCopy(Env["math"])
	end

	if Hooks["debug"] ~= nil then
		Env["debug"] = Hooks["debug"]
	end
	if typeof(Env["debug"]) ~= "table" or rawget(Env["debug"], "P") ~= "debug" then
		local DebugLib = require("../../Libs/DebugLib")
		Env["debug"] = DebugLib.Build(Proxy, State, Emitter, Beautifier, Scope, Config, Iteration, AntiTamperFlags)
	end

	if Hooks["coroutine"] ~= nil then
		Env["coroutine"] = Hooks["coroutine"]
	end

	if Env["package"] == nil then
		Env["package"] = {
			loaded = {},
			preload = {},
			path = "",
			config = "",
		}
	end

	if Env["arg"] == nil then
		Env["arg"] = {}
	end

	Env["Wrapper"] = {
		CALL = function(Callback, ...)
			return Callback(...)
		end,
		NAMECALL = function(Self, Method, ...)
			return Self[Method](Self, ...)
		end,
		CHECKINDEX = function(Self, Key)
			return Self[Key]
		end,
	}
	State:RegisterInternal(Env["Wrapper"], "Wrapper")

	Env["pcall"] = Deps.Hooks.pcall
	Env["xpcall"] = Deps.Hooks.xpcall

	local function VersionFunc()
		local RoboVersion = require("../../Roblox/Version")
		return RoboVersion.Get().version
	end

	local function TypeFunc(Value)
		local function TypeTagOf(Obj)
			if typeof(Obj) == "table" then
				local Tag = rawget(Obj, "__larryType")
				if typeof(Tag) == "string" then
					return Tag
				end
			end
			return nil
		end

		if ProxyUserdataTag[Value] then
			return "userdata"
		end
		local SignalType = Signals.TypeOf(Value)
		if SignalType then
			return "userdata"
		end
		if Instance.IsInstance(Value) then
			return "userdata"
		end

		if Enums.IsEnumItem and Enums.IsEnumItem(Value) then
			return "userdata"
		end

		local Tag = TypeTagOf(Value)
		if Tag ~= nil then
			if Tag == "Vector3" then
				return "vector"
			end
			if Tag == "buffer" then
				return "buffer"
			end
			if Tag == "number" then
				return "number"
			end
			if Tag == "string" then
				return "string"
			end
			return "userdata"
		end

		if typeof(Value) == "table" then
			local Raw = rawget(Value, "V")
			local RawTag = TypeTagOf(Raw)
			if RawTag ~= nil then
				if RawTag == "Vector3" then
					return "vector"
				end
				return "userdata"
			end
		end

		return type(Value)
	end

	local function TypeofFunc(Value)
		local function TypeTagOf(Obj)
			if typeof(Obj) == "table" then
				local Tag = rawget(Obj, "__larryType")
				if typeof(Tag) == "string" then
					return Tag
				end
			end
			return nil
		end

		if ProxyUserdataTag[Value] then
			return "userdata"
		end
		local SignalType = Signals.TypeOf(Value)
		if SignalType then
			return SignalType
		end
		if Instance.IsInstance(Value) then
			return "Instance"
		end

		if Enums.IsEnumItem and Enums.IsEnumItem(Value) then
			return "EnumItem"
		end

		local Tag = TypeTagOf(Value)
		if Tag ~= nil then
			if Tag == "Enum" then
				return "Enum"
			end
			if Tag == "Enums" then
				return "Enums"
			end
			if Tag == "EnumItem" then
				return "EnumItem"
			end
			return Tag
		end

		if typeof(Value) == "table" then
			local Raw = rawget(Value, "V")
			local RawTag = TypeTagOf(Raw)
			if RawTag ~= nil then
				return RawTag
			end
		end

		return typeof(Value)
	end

	local function MakeLogFunc(Name)
		local LastCall = nil
		local RepeatedCount = 0
		local SuppressedCount = 0
		local ServicesModule = nil
		local CachedLogService = nil
		local CachedMessageOut = nil
		local CachedHistory = nil
		local LogServiceResolved = false

		local function EmitLogServiceMessage(Args, IsWarn)
			if not LogServiceResolved then
				LogServiceResolved = true
				ServicesModule = ServicesModule or require("../../Roblox/Services")
				if typeof(ServicesModule) == "table" and typeof(ServicesModule.GetOrNil) == "function" then
					local Service = ServicesModule.GetOrNil("LogService")
					if typeof(Service) == "table" and typeof(Service.GetProperty) == "function" then
						CachedLogService = Service
						local Signal = CachedLogService:GetProperty("MessageOut")
						if typeof(Signal) == "table" and typeof(Signal.Fire) == "function" then
							CachedMessageOut = Signal
						end

						local History = CachedLogService:GetProperty("_History")
						if typeof(History) ~= "table" then
							History = {}
							if typeof(CachedLogService.SetProperty) == "function" then
								CachedLogService:SetProperty("_History", History)
							end
						end
						CachedHistory = History
					end
				end
			end

			local MessageType = Enums.Get("MessageType", IsWarn and "MessageWarning" or "MessageOutput")
			if typeof(CachedMessageOut) == "table" and typeof(CachedMessageOut.Fire) == "function" then
				local MessageParts = {}
				for I = 1, Args.n do
					MessageParts[I] = tostring(Args[I])
				end
				local Message = table.concat(MessageParts, "\t")
				CachedMessageOut:Fire(Message, MessageType)

				local History = CachedHistory
				if typeof(History) ~= "table" then
					History = {}
					CachedHistory = History
					if CachedLogService and typeof(CachedLogService.SetProperty) == "function" then
						CachedLogService:SetProperty("_History", History)
					end
				end

				History[#History + 1] = {
					message = Message,
					messageType = MessageType,
					timestamp = RuntimeClock.Now(),
				}
			end
		end

		local function FlushSuppressed()
			if SuppressedCount <= 0 then
				return
			end

			Emitter:Append(``)
			SuppressedCount = 0
		end

			local Wrapped = Proxy:NewCClosure(function(...)
			State:IncrementOps()
			if State.OpCount >= MaxOps then
				FlushSuppressed()
				error("Too many operations.", 0)
			end

			TotalLogCalls += 1
			if TotalLogCalls > MaxLogCalls then
				FlushSuppressed()
				error("Too many operations.", 0)
			end

			local Args = table.pack(...)
			for I = 1, Args.n do
				if typeof(Args[I]) == "string" then
					Args[I] = ErrorSanitizer.Sanitize(Args[I])
				end
			end

			local Payload = Beautifier:BeautifyTuple(table.unpack(Args, 1, Args.n))
			local Call = `{Name}({Payload})`
			if MaxLogPayloadChars > 0 and #Call > MaxLogPayloadChars then
				Call = string.sub(Call, 1, MaxLogPayloadChars) .. "... "
			end

			if Call == LastCall then
				RepeatedCount += 1
				if RepeatedCount <= MaxRepeatedLogs then
					Emitter:Append(Call)
				else
					SuppressedCount += 1
					if MaxSuppressedLogs > 0 and SuppressedCount >= MaxSuppressedLogs then
						FlushSuppressed()
					end
				end
			else
				FlushSuppressed()
				LastCall = Call
				RepeatedCount = 1
				Emitter:Append(Call)
			end

			EmitLogServiceMessage(Args, Name == "warn")

			return
		end)
		State:RegisterInternal(Wrapped, Name)
		return Wrapped
	end

	local function NewProxy(Arg)
		if Arg == nil or Arg == false then
			local Obj = {}
			ProxyUserdataTag[Obj] = true
			return Obj
		end

		if Arg == true then
			local Obj = {}
			ProxyUserdataTag[Obj] = true
			setmetatable(Obj, {})
			return Obj
		end

		if typeof(Arg) == "table" and ProxyUserdataTag[Arg] then
			local Obj = {}
			ProxyUserdataTag[Obj] = true

			local Ok, Mt = pcall(getmetatable, Arg)
			if Ok and typeof(Mt) == "table" then
				pcall(setmetatable, Obj, Mt)
			end

			return Obj
		end

		error("bad argument #1 to 'newproxy' (boolean or proxy expected)", 2)
	end

	Env["version"] = Env["version"] or VersionFunc
	Env["Version"] = Env["Version"] or VersionFunc
	Env["_VERSION"] = "Luau"
	Env["print"] = Env["print"] or MakeLogFunc("print")
	Env["warn"] = Env["warn"] or MakeLogFunc("warn")
	Env["type"] = Proxy:NewCClosure(TypeFunc)
	Env["typeof"] = Proxy:NewCClosure(TypeofFunc)
	Env["newproxy"] = Proxy:NewCClosure(NewProxy)
	Env["select"] = Proxy:NewCClosure(function(Index, ...)
		if Index == "#" then
			return select("#", ...)
		end

		if typeof(Index) == "table" then
			local RawValue = rawget(Index, "V")
			if RawValue == "#" then
				return select("#", ...)
			end
			if tostring(Index) == "#" then
				return select("#", ...)
			end
		end

		return select(Index, ...)
	end)
	local WrappedTostring = Env["tostring"] or TrueEnv.tostring or tostring
	local NativeGetmetatable = TrueEnv.getmetatable or getmetatable
	local StableObjectIds = setmetatable({}, { __mode = "k" })
	local NextStableObjectId = 0

	local function GetStableObjectId(Value)
		local Existing = StableObjectIds[Value]
		if typeof(Existing) == "number" then
			return Existing
		end
		NextStableObjectId += 1
		StableObjectIds[Value] = NextStableObjectId
		return NextStableObjectId
	end

	local function ShouldNormalizeTostring(Value, Text)
		if typeof(Text) ~= "string" then
			return false
		end

		local Kind = typeof(Value)
		if Kind ~= "table" and Kind ~= "function" and Kind ~= "thread" and Kind ~= "userdata" then
			return false
		end

		if State:IsInternal(Value) then
			return false
		end

		if Kind == "table" then
			local OkMt, Mt = pcall(NativeGetmetatable, Value)
			if OkMt and typeof(Mt) == "table" and typeof(rawget(Mt, "__tostring")) == "function" then
				return false
			end
		end

		local Prefix = Kind .. ": "
		return string.sub(Text, 1, #Prefix) == Prefix
	end

	Env["tostring"] = Proxy:NewCClosure(function(Value)
		local Ok, Text = pcall(WrappedTostring, Value)
		if not Ok then
			error(Text, 0)
		end

		if ShouldNormalizeTostring(Value, Text) then
			local Kind = typeof(Value)
			return string.format("%s: %08X", Kind, GetStableObjectId(Value))
		end

		return Text
	end)
	Env["tick"] = Env["tick"] or Proxy:NewCClosure(function()
		return RuntimeClock.GetServerNow()
	end)
	Env["time"] = Env["time"] or Proxy:NewCClosure(function()
		return RuntimeClock.Now()
	end)
	Env["elapsedTime"] = Env["elapsedTime"] or Proxy:NewCClosure(function()
		return RuntimeClock.Now()
	end)
	State:RegisterInternal(Env["version"], "version")
	State:RegisterInternal(Env["Version"], "Version")
	State:RegisterInternal(Env["type"], "type")
	State:RegisterInternal(Env["typeof"], "typeof")
	State:RegisterInternal(Env["tostring"], "tostring")
	State:RegisterInternal(Env["newproxy"], "newproxy")
	State:RegisterInternal(Env["select"], "select")
	State:RegisterInternal(Env["tick"], "tick")
	State:RegisterInternal(Env["time"], "time")
	State:RegisterInternal(Env["elapsedTime"], "elapsedTime")

	if Config.lm then
		Env["unnamedvar"] = Proxy:NewCClosure(function(Number)
			local N = tonumber(Number) or 0
			local Name = `_ENV{N}`
			if rawget(Env, Name) == nil then
				rawset(Env, Name, nil)
			end
			return rawget(Env, Name)
		end)
		State:RegisterInternal(Env["unnamedvar"], "unnamedvar")
	end

	local TrueGetmetatable = TrueEnv.getmetatable or getmetatable
	local TrueSetmetatable = TrueEnv.setmetatable or setmetatable
	local TrueGetfenv = TrueEnv.getfenv or getfenv
	local TrueSetfenv = TrueEnv.setfenv or setfenv
	local TrueRawget = TrueEnv.rawget or rawget
	local TrueRawset = TrueEnv.rawset or rawset
	local TrueRawequal = TrueEnv.rawequal or rawequal
	local TruePairs = TrueEnv.pairs or pairs
	local TrueNext = TrueEnv.next or next
	local TrueDebugInfo = (TrueEnv.debug and TrueEnv.debug.info) or (debug and debug.info)
	local TrueRequire = TrueEnv.require or require
	local RawGetmetatable = Hooks["getrawmetatable"]
	local TrackSetmetatable = Hooks["__larry_track_setmetatable"]
	local FenvOverrides = setmetatable({}, { __mode = "k" })
	local PublicFenv = nil

	local function IsHiddenEnvKey(Key)
		if typeof(Key) ~= "string" then
			return false
		end
		if Key == "P" or Key == "V" or Key == "ISP" or Key == "_ENV" then
			return true
		end
		if string.sub(Key, 1, 7) == "__larry" then
			return true
		end
		if Key == "hookexpr" or Key == "hookeq" or Key == "preventerror" or Key == "forceerror" then
			return true
		end
		if string.sub(Key, 1, 5) == "CHECK" then
			return true
		end
		if string.sub(Key, 1, 4) == "COMP" then
			return true
		end
		if string.sub(Key, 1, 2) == "__" then
			return true
		end
		return false
	end

	local function IsHiddenFenvKey(Key)
		return IsHiddenEnvKey(Key)
			or Key == "getnamecallmethod"
			or Key == "setnamecallmethod"
			or Key == "getrawmetatable"
			or Key == "setrawmetatable"
	end

	local function EmitBuiltinCall(Name, ...)
		if Config.trace_builtins == false then
			return nil
		end

		local Args = table.pack(...)
		local Key = Args[2]
		if (Name == "rawget" or Name == "rawset") and typeof(Key) == "string" and string.sub(Key, 1, 8) == "__larry_" then
			return nil
		end

		local Value = Args.n > 0 and `{Name}({Beautifier:BeautifyTuple(table.unpack(Args, 1, Args.n))})` or `{Name}()`
		local Var = Scope:GenerateName(Name, Name .. "Result")
		Emitter:Append(`local {Var} = {Value}`)
		State:Define(Var, Value, "__call")
		return Var
	end

	local function TrackBuiltinResult(Value, Var)
		if Var ~= nil and Value ~= nil then
			local Kind = typeof(Value)
			if Kind == "table" or Kind == "function" or Kind == "thread" or Kind == "userdata" then
				State:RegisterInternal(Value, Var)
			end
		end
		return Value
	end

	local function IsHiddenEnvMetatable(Target)
		if typeof(Target) ~= "table" and typeof(Target) ~= "userdata" then
			return false
		end

		local Path = rawget(Target, "P")
		if typeof(Path) ~= "string" or Path == "" then
			Path = State:IsInternal(Target)
		end

		return Path == "_G"
			or Path == "shared"
			or Path == "getgenv()"
			or Path == "getfenv()"
			or Path == "getrenv()"
	end

	local function SanitizeKolobfMetatable(Object, Mt)
		if not AntiTamperFlags.Kolobf then
			return Mt
		end

		if typeof(Object) ~= "table" or typeof(Mt) ~= "table" then
			return Mt
		end

		local HasTrap = false
		local SafeMt = {}

		for K, V in next, Mt do
			SafeMt[K] = V

			if (K == "__index" or K == "__newindex" or K == "__call" or K == "__tostring") and typeof(V) == "function" then
				HasTrap = true
			end
		end

		if not HasTrap then
			return Mt
		end

		local FallbackText = tostring(Object)

		if typeof(rawget(Mt, "__index")) == "function" then
			SafeMt.__index = function()
				return true
			end
		end

		if typeof(rawget(Mt, "__newindex")) == "function" then
			SafeMt.__newindex = function(Tbl, Key, Value)
				rawset(Tbl, Key, Value)
			end
		end

		if typeof(rawget(Mt, "__call")) == "function" then
			SafeMt.__call = function()
				return true
			end
		end

		if typeof(rawget(Mt, "__tostring")) == "function" then
			SafeMt.__tostring = function()
				return FallbackText
			end
		end

		AntiTamper.LogBypass("kolobf_metatable", tostring(Object))
		return SafeMt
	end

	local function SanitizeWriteTrapMetatable(Mt)
		if typeof(Mt) ~= "table" then
			return Mt
		end

		local RawNewIndex = rawget(Mt, "__newindex")
		if typeof(RawNewIndex) ~= "function" then
			return Mt
		end

		local SafeMt = {}
		for Key, Value in next, Mt do
			SafeMt[Key] = Value
		end

		SafeMt.__newindex = function(Tbl, Key, Value)
			local OkSet = pcall(RawNewIndex, Tbl, Key, Value)
			if not OkSet then
				rawset(Tbl, Key, Value)
			end
		end

		return SafeMt
	end

	Env["getmetatable"] = Proxy:NewCClosure(function(Target)
		if Instance.IsInstance(Target) then
			return "The metatable is locked"
		end

		if IsHiddenEnvMetatable(Target) then
			return nil
		end

		local targetType = typeof(Target)
		if targetType ~= "table" and targetType ~= "string" and targetType ~= "function" and targetType ~= "thread" then

			return nil
		end

		if typeof(RawGetmetatable) == "function" then
			local Ok, Mt = pcall(RawGetmetatable, Target)
			if Ok and Mt ~= nil then
				if typeof(Mt) == "table" then
					local LockedMetatable = rawget(Mt, "__metatable")
					if LockedMetatable ~= nil then
						return LockedMetatable
					end
				end
				if typeof(Target) == "string" and typeof(Mt) == "table" and rawget(Mt, "__metatable") == nil then
					local SafeMt = {}
					for Key, Value in next, Mt do
						SafeMt[Key] = Value
					end
					SafeMt.__metatable = "The metatable is locked"
					return SafeMt
				end
				return Mt
			end
		end

		local Mt = TrueGetmetatable(Target)
		if typeof(Target) == "string" and typeof(Mt) == "table" and rawget(Mt, "__metatable") == nil then
			local SafeMt = {}
			for Key, Value in next, Mt do
				SafeMt[Key] = Value
			end
			SafeMt.__metatable = "The metatable is locked"
			return SafeMt
		end
		return Mt
	end)

	Env["setmetatable"] = Proxy:NewCClosure(function(Target, Mt)
		if Instance.IsInstance(Target) then
			error("cannot change a protected metatable", 2)
		end
		if typeof(TrackSetmetatable) == "function" then
			pcall(TrackSetmetatable, Target, Mt)
		end
		local Sanitized = SanitizeKolobfMetatable(Target, Mt)
		Sanitized = SanitizeWriteTrapMetatable(Sanitized)
		return TrueSetmetatable(Target, Sanitized)
	end)
	State:RegisterInternal(Env["getmetatable"], "getmetatable")
	State:RegisterInternal(Env["setmetatable"], "setmetatable")

	local function GetHiddenEnvEntries(Target)
		local Entries = {}
		local Seen = {}
		local PriorityKeys = { "_VERSION", "_G", "getgenv", "game", "workspace", "task", "loadstring", "print" }
		local SourceTarget = Target == PublicFenv and Locked or Target

		local function AddEntry(Key, Value)
			if Target == PublicFenv then
				if IsHiddenFenvKey(Key) then
					return
				end
			elseif IsHiddenEnvKey(Key) then
				return
			end
			if Seen[Key] then
				return
			end
			Seen[Key] = true
			Entries[#Entries + 1] = { Key, Value }
		end

		for _, Key in next, PriorityKeys do
			local Value = TrueRawget(SourceTarget, Key)
			if Value == nil then
				local Stored = State.EnvValues[Key]
				if Stored ~= nil then
					Value = Stored[1]
				end
			end
			if Value ~= nil then
				AddEntry(Key, Value)
			end
		end

		for Key, Value in TrueNext, SourceTarget do
			AddEntry(Key, Value)
		end

		for Key, Stored in TrueNext, State.EnvValues do
			AddEntry(Key, Stored[1])
		end

		return Entries
	end

	local function GetFrozenSharedTableEntries(Target)
		if typeof(Target) ~= "table" or TrueRawget(Target, "__larryType") ~= "SharedTable" then
			return nil
		end

		local FrozenData = TrueRawget(Target, "_LarryFrozenData")
		if typeof(FrozenData) ~= "table" then
			return nil
		end

		local Entries = {}
		for Key, Value in TrueNext, FrozenData do
			Entries[#Entries + 1] = { Key, Value }
		end
		return Entries
	end

	Env["rawget"] = Proxy:NewCClosure(function(Target, Key)
		local TraceVar = EmitBuiltinCall("rawget", Target, Key)
		if Target == PublicFenv and IsHiddenFenvKey(Key) then
			return nil
		end
		local Value = TrueRawget(Target, Key)
		if Value ~= nil then
			return TrackBuiltinResult(Value, TraceVar)
		end
		if IsHiddenEnvMetatable(Target) and typeof(Key) == "string" then
			if IsHiddenEnvKey(Key) then
				return nil
			end
			local Stored = State.EnvValues[Key]
			if Stored ~= nil then
				return TrackBuiltinResult(Stored[1], TraceVar)
			end
		end
		return TrackBuiltinResult(Value, TraceVar)
	end)

	Env["rawset"] = Proxy:NewCClosure(function(Target, Key, Value)
		local TraceVar = EmitBuiltinCall("rawset", Target, Key, Value)
		if IsHiddenEnvMetatable(Target) and typeof(Key) == "string" then
			State.EnvValues[Key] = { Value }
		end
		return TrackBuiltinResult(TrueRawset(Target, Key, Value), TraceVar)
	end)

	Env["rawequal"] = Proxy:NewCClosure(function(A, B)
		local function IsClass(Value, ClassName)
			return typeof(Value) == "table" and rawget(Value, "_ClassName") == ClassName
		end
		if (IsClass(A, "DataModel") and IsClass(B, "Workspace")) or (IsClass(A, "Workspace") and IsClass(B, "DataModel")) then
			return true
		end
		return TrueRawequal(A, B)
	end)

	Env["next"] = Proxy:NewCClosure(function(Target, Index)
		local FrozenSharedEntries = GetFrozenSharedTableEntries(Target)
		if FrozenSharedEntries ~= nil then
			if Index == nil then
				local Entry = FrozenSharedEntries[1]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end
			for EntryIndex = 1, #FrozenSharedEntries do
				local Entry = FrozenSharedEntries[EntryIndex]
				if Entry[1] == Index then
					local NextEntry = FrozenSharedEntries[EntryIndex + 1]
					if NextEntry ~= nil then
						return NextEntry[1], NextEntry[2]
					end
					return nil
				end
			end
			return nil
		end

		if IsHiddenEnvMetatable(Target) then
			local Entries = GetHiddenEnvEntries(Target)
			if Index == nil then
				local Entry = Entries[1]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end
			for EntryIndex = 1, #Entries do
				local Entry = Entries[EntryIndex]
				if Entry[1] == Index then
					local NextEntry = Entries[EntryIndex + 1]
					if NextEntry ~= nil then
						return NextEntry[1], NextEntry[2]
					end
					return nil
				end
			end
			return nil
		end

		if typeof(Target) == "table" then
			local Key, Value = TrueNext(Target, Index)
			while Key ~= nil and IsHiddenEnvKey(Key) do
				Key, Value = TrueNext(Target, Key)
			end
			return Key, Value
		end

		return TrueNext(Target, Index)
	end)

	Env["pairs"] = Proxy:NewCClosure(function(Target)
		local FrozenSharedEntries = GetFrozenSharedTableEntries(Target)
		if FrozenSharedEntries ~= nil then
			local Cursor = 0
			return function()
				Cursor += 1
				local Entry = FrozenSharedEntries[Cursor]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end, nil, nil
		end

		if IsHiddenEnvMetatable(Target) then
			local Entries = GetHiddenEnvEntries(Target)
			local Cursor = 0
			return function()
				Cursor += 1
				local Entry = Entries[Cursor]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end, nil, nil
		end

		return TruePairs(Target)
	end)
	State:RegisterInternal(Env["rawget"], "rawget")
	State:RegisterInternal(Env["rawset"], "rawset")
	State:RegisterInternal(Env["rawequal"], "rawequal")
	State:RegisterInternal(Env["next"], "next")
	State:RegisterInternal(Env["pairs"], "pairs")

	local function NormalizeEnv(Value)
		if Value == nil then
			return PublicFenv or Locked
		end

		if Value == Env or Value == Locked or Value == TrueEnv then
			return PublicFenv or Locked
		end

		if typeof(Value) == "table" then
			local CandidateRequire = TrueRawget(Value, "require")
			if typeof(CandidateRequire) == "function" and CandidateRequire == TrueRequire then
				return PublicFenv or Locked
			end
		end

		return Value
	end

	local function ResolveFuncAtLevel(Level)
		if typeof(TrueDebugInfo) ~= "function" then
			return nil
		end

		local Ok, Func = pcall(TrueDebugInfo, Level, "f")
		if Ok and typeof(Func) == "function" then
			return Func
		end

		return nil
	end

	local function GetOverrideForLevel(Level)
		local Func = ResolveFuncAtLevel(Level + 1)
		if Func then
			return FenvOverrides[Func]
		end
		return nil
	end

	local function ResolveGetfenvLevel(Level)
		if Level ~= Level or Level == math.huge or Level == -math.huge or Level % 1 ~= 0 or Level < 0 or Level > 20 then
			error("invalid argument #1 to 'getfenv' (level out of range)", 2)
		end

		if Level == 0 then
			return PublicFenv or Locked
		end

		local Override = GetOverrideForLevel(Level)
		if Override ~= nil then
			return NormalizeEnv(Override)
		end

		if typeof(TrueGetfenv) ~= "function" then
			return PublicFenv or Locked
		end

		local Ok, Result = pcall(TrueGetfenv, Level + 1)
		if Ok then
			return NormalizeEnv(Result)
		end

		return PublicFenv or Locked
	end

	Env["getfenv"] = Proxy:NewCClosure(function(...)
		local Args = table.pack(...)
		local TraceVar = EmitBuiltinCall("getfenv", table.unpack(Args, 1, Args.n))
		local Target = Args[1]
		if Args.n == 0 then
			return TrackBuiltinResult(ResolveGetfenvLevel(1), TraceVar)
		end

		local Tp = typeof(Target)
		if Tp == "number" then
			return TrackBuiltinResult(ResolveGetfenvLevel(Target), TraceVar)
		end

		if Tp == "function" then
			local Override = FenvOverrides[Target]
			if Override ~= nil then
				return TrackBuiltinResult(NormalizeEnv(Override), TraceVar)
			end
			if State:IsInternal(Target) then
				if typeof(TrueGetfenv) == "function" then
					local Ok, Result = pcall(TrueGetfenv, print)
					if Ok then
						return TrackBuiltinResult(NormalizeEnv(Result), TraceVar)
					end
				end
				return TrackBuiltinResult(PublicFenv or Locked, TraceVar)
			end
			if typeof(TrueGetfenv) == "function" then
				local Ok, Result = pcall(TrueGetfenv, Target)
				if Ok then
					return TrackBuiltinResult(NormalizeEnv(Result), TraceVar)
				end
			end
			return TrackBuiltinResult(PublicFenv or Locked, TraceVar)
		end

		if Tp == "thread" then
			return TrackBuiltinResult(PublicFenv or Locked, TraceVar)
		end

		error(`bad argument #1 to 'getfenv' (number or function expected, got {Tp})`, 2)
	end)
	State:RegisterInternal(Env["getfenv"], "getfenv")

	Env["setfenv"] = Proxy:NewCClosure(function(Func, NewEnv)
		local TraceVar = EmitBuiltinCall("setfenv", Func, NewEnv)
		if typeof(Func) == "function" and State:IsInternal(Func) then
			error("cannot setfenv on 0 or a C function", 2)
		end
		if typeof(Func) == "number" then
			local Level = Func
			if Level ~= Level or Level == math.huge or Level == -math.huge or Level % 1 ~= 0 or Level < 0 or Level > 20 then
				error("invalid argument #1 to 'setfenv' (level out of range)", 2)
			end
			if typeof(NewEnv) == "table" and getmetatable(NewEnv) == nil then

				if rawget(NewEnv, "getfenv") == nil and rawget(NewEnv, "setfenv") == nil then
					TrueSetmetatable(NewEnv, { __index = Locked })
				end
			end
			local TargetFunc = ResolveFuncAtLevel(Level + 1)
			if TargetFunc then
				FenvOverrides[TargetFunc] = NewEnv
			end
			if typeof(TrueSetfenv) ~= "function" then
				return TrackBuiltinResult(TargetFunc or true, TraceVar)
			end
			if Level > 0 then
				Level += 1
			end
			return TrackBuiltinResult(TargetFunc or true, TraceVar)
		end
		if typeof(Func) == "function" then
			FenvOverrides[Func] = NewEnv
		end
		if typeof(TrueSetfenv) ~= "function" then
			return TrackBuiltinResult(Func, TraceVar)
		end
		return TrackBuiltinResult(TrueSetfenv(Func, NewEnv), TraceVar)
	end)
	State:RegisterInternal(Env["setfenv"], "setfenv")

	if not Env["getrenv"] then
		Env["getrenv"] = Proxy:NewCClosure(function()
			local TraceVar = EmitBuiltinCall("getrenv")
			return TrackBuiltinResult(Locked, TraceVar)
		end)
	end
	State:RegisterInternal(Env["getrenv"], "getrenv")

	Env["loadstring"] = Loaders.Loadstring
	Env["load"] = Loaders.Load
	State:RegisterInternal(Env["loadstring"], "loadstring")
	State:RegisterInternal(Env["load"], "load")

	if not Env["getgenv"] then
		Env["getgenv"] = Proxy:NewCClosure(function()
			local TraceVar = EmitBuiltinCall("getgenv")
			return TrackBuiltinResult(Locked, TraceVar)
		end)
	end
	State:RegisterInternal(Env["getgenv"], "getgenv")

	Env["spawn"] = Env["spawn"] or Proxy:NewCClosure(function(...)
		if Env["task"] and typeof(Env["task"].spawn) == "function" then
			return Env["task"].spawn(...)
		end
		error("attempt to call missing function 'spawn'", 0)
	end)

	Env["delay"] = Env["delay"] or Proxy:NewCClosure(function(...)
		if Env["task"] and typeof(Env["task"].delay) == "function" then
			return Env["task"].delay(...)
		end
		error("attempt to call missing function 'delay'", 0)
	end)

	Env["wait"] = Env["wait"] or Proxy:NewCClosure(function(Duration)
		if Env["task"] and typeof(Env["task"].wait) == "function" then
			local Elapsed = Env["task"].wait(Duration)
			return Elapsed, RuntimeClock.Now()
		end
		return 0, RuntimeClock.Now()
	end)
	State:RegisterInternal(Env["spawn"], "spawn")
	State:RegisterInternal(Env["delay"], "delay")
	State:RegisterInternal(Env["wait"], "wait")

	if typeof(Env["os"]) == "table" then
		local ClockClosure = Proxy:NewCClosure(function()
			return RuntimeClock.Now()
		end)
		local SetOk = pcall(function()
			Env["os"]["clock"] = ClockClosure
		end)
		if not SetOk then
			local OsCompat = {}
			for Key, Value in next, Env["os"] do
				OsCompat[Key] = Value
			end
			OsCompat["clock"] = ClockClosure
			Env["os"] = OsCompat
		end
		State:RegisterInternal(ClockClosure, "os.clock")
	end

	for _, Key in Constants.IterFunctions do
		if Key == "pairs" then
			local HiddenPairs = Env["pairs"]
			Env[Key] = Proxy:NewCClosure(function(Tbl)
				if IsHiddenEnvMetatable(Tbl) then
					EmitBuiltinCall(Key, Tbl)
					return HiddenPairs(Tbl)
				end
				if State:IsInternal(Tbl) then
					return Iteration:Iter(Tbl, Key)
				end
				EmitBuiltinCall(Key, Tbl)
				return TrueEnv[Key](Tbl)
			end)
		else
			Env[Key] = Proxy:NewCClosure(function(Tbl)
				if State:IsInternal(Tbl) then
					return Iteration:Iter(Tbl, Key)
				end
				EmitBuiltinCall(Key, Tbl)
				return TrueEnv[Key](Tbl)
			end)
		end
	end

	for _, Name in ExecEnv.Names do
		if Env[Name] ~= nil then continue end

		local Indexed = StringUtil.Index(Name)
		local Stored = State.EnvValues[Name]

		if Stored then
			Env[Name] = Stored[1]
			continue
		end

		if Config.spy_exec_only then
			if ExecEnv.IsSafe(Name) then
				if Deps.Pristine and Types.IsFunction(Name) then
					local Actual = TrueEnv[Name]
					if Actual then
						local Wrapped = Proxy:NewCClosure(function(...)
							if typeof(...) == "function" then
								return Actual(...)
							end
							return Proxy:Spy(Scope:AddVar("", "", `{Name}({Beautifier:BeautifyTuple(...)})`, "__call"))
						end)
						Env[Name] = Wrapped
						State:RegisterInternal(Wrapped, Name)
						continue
					end
				end

				Env[Name] = Proxy:Spy(Indexed, { Function = Types.IsFunction(Name) })
			end
		else
			Env[Name] = Proxy:Spy(Indexed, { Function = Types.IsFunction(Name) })
		end
	end

	Locked = setmetatable(Env, {
		__index = function(_, Key)
			if typeof(Key) ~= "string" then return nil end

			local Stored = State.EnvValues[Key]
			if Stored then
				return Stored[1]
			end

			local Indexed = StringUtil.Index(Key)
			local IsExec = ExecEnv.IsSafe(Key)

			if Config.env_index and not EnvIndexLogged[Key] then
				Emitter:Append(`local _ = {Indexed}`)
				EnvIndexLogged[Key] = true
			end

			if Config.spy_exec_only then

				if not IsExec then
					return nil
				end
			end

			State:IncrementOps()
			if State.OpCount >= (Config.max_ops or Constants.Limits.MaxOperations) then
				error("Too many operations.", 0)
			end

			if Config.spy_exec_only then
				return Proxy:Spy(Indexed)
			end

			return Proxy:Spy(Indexed)
		end,
		__newindex = function(_, Key, Value)
			rawset(_, Key, Value)
			if _ ~= Env then
				rawset(Env, Key, Value)
			end
			State.EnvValues[Key] = { Value }
			State:IncrementOps()
			State:CheckOps(Config.max_ops or Constants.Limits.MaxOperations)

			if Config.spy_exec_only then return end

			local IsFunc = typeof(Value) == "function"
			local Indexed = StringUtil.Index(Key)

			if IsFunc then
				Emitter:AppendRaw(Beautifier:Beautify(Value, State.CurrentIndent + 1, { FuncName = Key }))
				return
			end

			local Protected = { "io", "os", "package", "require", "debug" }
			local Code = `{Indexed} = {Beautifier:Beautify(Value, State.CurrentIndent + 1)}`

			if Value == nil and table.find(Protected, Key) then
				Code = `
			end

			Emitter:Append(Code)
		end,
		__tostring = function()
			return "getfenv()"
		end,
		__iter = function(Target)
			local Entries = GetHiddenEnvEntries(Target)
			local Cursor = 0
			return function()
				Cursor += 1
				local Entry = Entries[Cursor]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end, nil, nil
		end,
		__metatable = nil,
	})

	rawset(Locked, "P", "getfenv()")
	rawset(Locked, "V", Locked)
	rawset(Env, "_ENV", Locked)
	if typeof(Hooks._G) == "table" then
		rawset(Env, "_G", Hooks._G)
		rawset(Locked, "_G", Hooks._G)
	end

	PublicFenv = setmetatable({ P = "getfenv()" }, {
		__index = function(_, Key)
			if IsHiddenFenvKey(Key) then
				return nil
			end
			return Locked[Key]
		end,
		__newindex = function(_, Key, Value)
			if IsHiddenFenvKey(Key) then
				return
			end
			Locked[Key] = Value
		end,
		__tostring = function()
			return "getfenv()"
		end,
		__iter = function(Target)
			local Entries = GetHiddenEnvEntries(Target)
			local Cursor = 0
			return function()
				Cursor += 1
				local Entry = Entries[Cursor]
				if Entry ~= nil then
					return Entry[1], Entry[2]
				end
				return nil
			end, nil, nil
		end,
		__metatable = nil,
	})

	State:RegisterInternal(Locked, "getfenv()")
	State:RegisterInternal(PublicFenv, "getfenv()")

	return Locked
end

return StandardEnv