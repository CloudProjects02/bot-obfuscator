local luau = require("@lune/luau")

local Config = require("../Config")
local State = require("./State")
local Scope = require("./Scope")
local Proxy = require("./Proxy")
local ProxyMeta = require("./ProxyMeta")
local Iteration = require("./Iteration")
local SpyHelpers = require("./SpyHelpers")
local AstReconstruction = require("./AstReconstruction")

local Emitter = require("../CodeGen/Emitter")
local Beautifier = require("../CodeGen/Beautifier")
local Unparser = require("../CodeGen/Unparser")

local Comparisons = require("../Hooks/Comparisons")
local Equality = require("../Hooks/Equality")
local Logic = require("../Hooks/Logic")
local ControlChecks = require("../Hooks/ControlChecks")
local TypeChecks = require("../Hooks/TypeChecks")
local Loaders = require("../Hooks/Loaders")
local CoreWraps = require("../Hooks/CoreWraps")
local FunctionHooks = require("../Hooks/FunctionHooks")

local IfChecks = require("../Flow/IfChecks")
local Loops = require("../Flow/Loops")
local PcallHandler = require("../Flow/PcallHandler")
local ScopeFixer = require("../Flow/ScopeFixer")

local DebugLib = require("../Libs/DebugLib")
local TaskLib = require("../Libs/TaskLib")
local CoroutineLib = require("../Libs/CoroutineLib")
local BufferAndCrypto = require("../Libs/BufferAndCrypto")

local MacroSystem = require("../Macros/MacroSystem")
local Predefined = require("../Macros/Predefined")
local CallHooks = require("../Macros/CallHooks")
local ExpressionHooksMacro = require("../Macros/ExpressionHooks")

local StandardEnv = require("../Env/StandardEnv")
local SharedEnvs = require("../Env/SharedEnvs")
local AntiTamper = require("../Env/AntiTamper")

local HierarchyMod = require("../Roblox/Hierarchy")
local Services = require("../Roblox/Services")
local InstanceMod = require("../Roblox/Instance")
local DataTypes = require("../Roblox/DataTypes")
local Enums = require("../Roblox/Enums")
local Signals = require("../Roblox/Signals")
local DrawingMod = require("../IO/Drawing")
local HTTP = require("../IO/HTTP")
local FileSystem = require("../IO/FileSystem")
local UNC = require("../IO/UNC")
local View = require("../Tools/View")

local MinifierMod = require("../PostProcess/Minifier")
local RenamerMod = require("../PostProcess/Renamer")
local Collection = require("../PostProcess/Collection")
local CleanupMod = require("../PostProcess/Cleanup")
local Bootstrap = require("./Bootstrap")
local VmStateRuntime = require("./VmStateRuntime")

local Constants = require("../Data/Constants")
local ExecEnv = require("../Data/ExecEnv")
local Types = require("../Data/Types")
local StringUtil = require("../Utils/String")
local IdentityUtil = require("../Utils/Identity")
local Logger = require("../Utils/Logger")
local LuauErrorFormatter = require("../Utils/LuauErrorFormatter")

local Tracer = {}
local CompileOptions = {
	optimizationLevel = 2,
	debugLevel = 1,
}

function Tracer.LoadFunction(Source, Environment)
	local function TryBuild(ChunkSource)
		local OkCompile, CompiledOrErr = pcall(luau.compile, ChunkSource, CompileOptions)
		if not OkCompile then
			return nil, CompiledOrErr
		end

		local OkLoad, FuncOrErr = pcall(luau.load, CompiledOrErr, {
			debugName = "LocalScript",
			environment = Environment,
		})
		if not OkLoad then
			return nil, FuncOrErr
		end

		return FuncOrErr, nil
	end

	local Func, LastErr = TryBuild(Source)
	if Func ~= nil then
		if typeof(setfenv) == "function" and typeof(Environment) == "table" then
			pcall(setfenv, Func, Environment)
		end
		return Func
	end

	if typeof(Source) == "string" then
		local Candidates = {}
		local function PushCandidate(Value)
			if typeof(Value) == "string" and Value ~= "" then
				Candidates[#Candidates + 1] = Value
			end
		end

		local DotLocalFixed = string.gsub(Source, "([%s;\n])%.([%s]*local[%s])", "%1%2")
		DotLocalFixed = string.gsub(DotLocalFixed, "^([%s]*)%.([%s]*local[%s])", "%1%2")
		PushCandidate(DotLocalFixed)

		local Trimmed = DotLocalFixed
		for _ = 1, 3 do
			local NextTrimmed = string.gsub(Trimmed, "[%s\r\n]*end[%s\r\n]*$", "")
			if NextTrimmed == Trimmed then
				break
			end
			Trimmed = NextTrimmed
			PushCandidate(Trimmed)
		end

		for _, Candidate in ipairs(Candidates) do
			local RetryFunc, RetryErr = TryBuild(Candidate)
			if RetryFunc ~= nil then
				if typeof(setfenv) == "function" and typeof(Environment) == "table" then
					pcall(setfenv, RetryFunc, Environment)
				end
				return RetryFunc
			end
			LastErr = RetryErr
		end
	end

	error(LastErr or "failed to compile source", 0)
end

function Tracer.Run(Source, Cfg, IsOriginal)
	Cfg = Cfg or Config.Settings

	local IsSourceString = typeof(Source) == "string"
	local Has25msDetector = IsSourceString and AntiTamper.Detect25ms(Source)
	local HasKolobfDetector = IsSourceString and AntiTamper.DetectKolobf(Source)
	local Pristine = IsSourceString and AntiTamper.PristineCheck(Source)
	local ReconstructionSource = (typeof(Cfg.__original_source) == "string" and Cfg.__original_source ~= "") and Cfg.__original_source or Source
	local Reconstruction = (typeof(ReconstructionSource) == "string" and Cfg.ast_reconstruction) and AstReconstruction.new(ReconstructionSource) or nil

	local SessionState = State.new()
	SessionState:ConfigureRuntime(Cfg)
	SessionState.AstReconstruction = Reconstruction
	local SessionEmitter = Emitter.new(SessionState, Cfg)
	local SessionBeautifier = Beautifier.new(SessionState, SessionEmitter, Cfg)
	local SessionScope = Scope.new(SessionState, SessionEmitter)
	local SessionProxy = Proxy.new(SessionState, SessionEmitter, SessionBeautifier, SessionScope)

	View.Configure(SessionState, SessionEmitter, SessionBeautifier)

	local SessionIteration = Iteration.new(SessionProxy, SessionState, SessionEmitter, SessionScope, SessionBeautifier)
	local SessionSpyHelpers = SpyHelpers.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	SessionSpyHelpers:SetIteration(SessionIteration)

	local SessionUnparser = Unparser.new(Cfg)

	local SessionComparisons = Comparisons.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionEquality = Equality.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionLogic = Logic.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionControlChecks = ControlChecks.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionTypeChecks = TypeChecks.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionLoaders = Loaders.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionCoreWraps = CoreWraps.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)
	local SessionFunctionHooks = FunctionHooks.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)

	local SessionPcall = PcallHandler.new(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg)

	local SessionMacros = MacroSystem.new(SessionState, Cfg)
	local SessionPredefined = Predefined.new(SessionState, Cfg)
	local SessionCallHooks = CallHooks.new(SessionState, Cfg)
	local SessionExprHooks = ExpressionHooksMacro.new(SessionState, Cfg)

	SessionPredefined:CreateHandler(SessionMacros)
	SessionCallHooks:CreateHandlers(SessionMacros)
	SessionExprHooks:CreateHandlers(SessionMacros, SessionPcall)

	local RobloxRuntime = Bootstrap.RobloxRuntime.Init(
		SessionProxy,
		SessionState,
		SessionEmitter,
		SessionBeautifier,
		SessionScope,
		Constants,
		HierarchyMod,
		Services,
		InstanceMod,
		DataTypes,
		Enums,
		HTTP,
		Signals,
		Cfg,
		Reconstruction
	)
	local GameRoot = RobloxRuntime.GameRoot
	local ScriptInstance = RobloxRuntime.ScriptInstance
	local DataTypeConstructors = RobloxRuntime.DataTypeConstructors

	local Hooks = Bootstrap.Hooks.New()
	Hooks.__larry_vm_get = function()
		return VmStateRuntime.Get()
	end
	SessionState:RegisterInternal(Hooks.__larry_vm_get, "__larry_vm_get")

	local CompHooks = SessionComparisons:Build()
	local EqHooks = SessionEquality:Build()
	local LogicHooks = SessionLogic:Build()
	local ControlHooks = SessionControlChecks:Build()
	local TypeHooks = SessionTypeChecks:Build()
	local LoaderResult = SessionLoaders:Build()
	local CoreHooks = SessionCoreWraps:Build()
	local FuncHooks = SessionFunctionHooks:Build()

	local PcallHooks = SessionPcall:Build()
	Bootstrap.Hooks.MergeMany(Hooks, CompHooks, EqHooks, LogicHooks, ControlHooks, TypeHooks, CoreHooks, FuncHooks, PcallHooks)
	for TypeName, ConstructorLib in next, DataTypeConstructors do
		if Hooks[TypeName] == nil then
			Hooks[TypeName] = ConstructorLib
		end
	end

	for _, TypeName in next, {"Vector3", "Vector2", "CFrame", "Color3", "BrickColor", "UDim", "UDim2", "TweenInfo", "Random", "Font", "DateTime", "RaycastParams", "OverlapParams"} do
		if Hooks[TypeName] == nil and DataTypeConstructors[TypeName] then
			Hooks[TypeName] = DataTypeConstructors[TypeName]
		end
	end

	Hooks.hookexpr = function(Id, Val) SessionExprHooks:HookExpr(Id, Val) end
	Hooks.hookeq = function(Id, Val) SessionExprHooks:HookEq(Id, Val) end
	Hooks.next = function(Tbl, ...) return SessionIteration:HookNext(Tbl, ...) end

	Hooks.string = SessionSpyHelpers:HookLib("string")
	Hooks.math = SessionSpyHelpers:HookLib("math")
	Hooks.table = SessionSpyHelpers:HookLib("table")
	if typeof(table.freeze) == "function" then
		pcall(table.freeze, Hooks.math)
	end

	local SessionDebug = DebugLib.Build(
		SessionProxy,
		SessionState,
		SessionEmitter,
		SessionBeautifier,
		SessionScope,
		Cfg,
		SessionIteration,
		{
			Kolobf = HasKolobfDetector,
		}
	)
	Hooks.debug = SessionDebug

	local SessionCoroutine = CoroutineLib.Build(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg, nil)
	Hooks.coroutine = SessionCoroutine

	local SessionBuffer = BufferAndCrypto.BuildBuffer(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	Hooks.buffer = SessionBuffer

	local SessionCrypt, Base64Enc, Base64Dec = BufferAndCrypto.BuildCrypto(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	Hooks.crypt = SessionCrypt
	Hooks.crypto = SessionCrypt
	Hooks.base64encode = Base64Enc
	Hooks.base64decode = Base64Dec

	local SessionLz4 = BufferAndCrypto.BuildLz4(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	Bootstrap.Hooks.Merge(Hooks, SessionLz4)

	local DrawingLib, DrawingFuncs = DrawingMod.Build(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	Hooks.Drawing = DrawingLib
	Bootstrap.Hooks.Merge(Hooks, DrawingFuncs)

	local FsFuncs = FileSystem.Build(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	Bootstrap.Hooks.Merge(Hooks, FsFuncs)

	local UncFuncs = UNC.Build(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg, HierarchyMod)
	Bootstrap.Hooks.Merge(Hooks, UncFuncs)
	if typeof(PcallHooks) == "table" then
		if typeof(PcallHooks.pcall) == "function" then
			Hooks.pcall = PcallHooks.pcall
		end
		if typeof(PcallHooks.xpcall) == "function" then
			Hooks.xpcall = PcallHooks.xpcall
		end
	end

	local WorkspaceRoot = HierarchyMod.GetService("Workspace") or Services.GetOrNil("Workspace")
	local ReplicatedStorageRoot = HierarchyMod.GetService("ReplicatedStorage") or Services.GetOrNil("ReplicatedStorage")
	Hooks.game = GameRoot
	Hooks.Game = GameRoot
	Hooks.workspace = WorkspaceRoot
	Hooks.Workspace = WorkspaceRoot
	Hooks.ReplicatedStorage = ReplicatedStorageRoot
	Hooks.script = ScriptInstance
	Hooks.Instance = InstanceMod

	if GameRoot then SessionState:RegisterInternal(GameRoot, "game") end
	if WorkspaceRoot then SessionState:RegisterInternal(WorkspaceRoot, "workspace") end
	if ReplicatedStorageRoot then SessionState:RegisterInternal(ReplicatedStorageRoot, "ReplicatedStorage") end
	if ScriptInstance then SessionState:RegisterInternal(ScriptInstance, "script") end
	SessionState:RegisterInternal(InstanceMod, "Instance")

	Hooks.Enum = Enums.BuildProxy()
	SessionState:RegisterInternal(Hooks.Enum, "Enum")
	for TypeName, ConstructorLib in next, DataTypeConstructors do
		if typeof(ConstructorLib) == "table" then
			SessionState:RegisterInternal(ConstructorLib, TypeName)
		end
	end

	Hooks.vector = {
		__lazy = true,
		__tostring = function() return "vector" end,
	}

	SessionLoaders:SetObfuscator(function(Code)
		return SessionUnparser:ObfuscateCode(Code)
	end)

	SessionLogic:SetLoadstring(LoaderResult.Loadstring)

	local Locked

	local Deps = Bootstrap.RuntimeEnv.BuildDeps(
		SessionState,
		SessionProxy,
		SessionEmitter,
		SessionBeautifier,
		SessionScope,
		Cfg,
		Hooks,
		SessionIteration,
		LoaderResult,
		Pristine,
		function(Code)
			return SessionUnparser:ObfuscateCode(Code)
		end
	)
	Deps.AntiTamperFlags = {
		Kolobf = HasKolobfDetector,
	}

	local SharedResult = SharedEnvs.Build({
		State = SessionState,
		Proxy = SessionProxy,
		Emitter = SessionEmitter,
		Beautifier = SessionBeautifier,
		Scope = SessionScope,
		Config = Cfg,
		Iteration = SessionIteration,
		Hooks = Hooks,
		GetLockedEnv = function()
			return Locked
		end,
	})

	Bootstrap.RuntimeEnv.AttachShared(Hooks, SharedResult)

	Locked = Bootstrap.RuntimeEnv.BuildLocked(StandardEnv, Deps)
	local SharedVm = VmStateRuntime.Get()
	rawset(Locked, "__larry_vm", SharedVm)
	rawset(Locked, "__larry_vm_get", Hooks.__larry_vm_get)

	if typeof(_G) == "table" then
		rawset(_G, "__larry_vm", SharedVm)
		rawset(_G, "__larry_vm_get", Hooks.__larry_vm_get)
	end

	if Has25msDetector and Locked then
		local OriginalWarn = rawget(Locked, "warn") or warn
		local OriginalError = rawget(Locked, "error") or error

		local WarnWrapper = SessionProxy:NewCClosure(function(...)
			local First = ...
			if AntiTamper.ShouldBypass25msWarn(First) then
				return nil
			end
			return OriginalWarn(...)
		end)

		local ErrorWrapper = SessionProxy:NewCClosure(function(Message, Level)
			if AntiTamper.ShouldBypass25msError(Message) then
				return nil
			end
			return OriginalError(Message, Level)
		end)

		rawset(Locked, "warn", WarnWrapper)
		rawset(Locked, "error", ErrorWrapper)
		SessionState:RegisterInternal(WarnWrapper, "warn")
		SessionState:RegisterInternal(ErrorWrapper, "error")
	end

	SessionCoreWraps:SetLockedEnv(Locked)
	SessionLoaders:SetLockedEnv(Locked)

	if Cfg.lm then
		Logger.SetLogMore(true)
	end

	local SessionTask = TaskLib.Build(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Cfg, Locked, Pristine)
	if typeof(InstanceMod.SetWaitFunction) == "function" then
		InstanceMod.SetWaitFunction(function(Duration)
			return SessionTask.wait(Duration)
		end)
	end
	rawset(Locked, "task", SessionTask)
	rawset(Locked, "spawn", function(...)
		return SessionTask.spawn(...)
	end)
	rawset(Locked, "delay", function(...)
		return SessionTask.delay(...)
	end)
	rawset(Locked, "wait", function(Duration)
		local Elapsed = SessionTask.wait(Duration)
		return Elapsed, os.clock()
	end)
	if SharedResult and SharedResult.Sync then
		SharedResult.Sync()
	end
	local GlobalEnv = Locked
	local GetGlobalEnv = function()
		return GlobalEnv
	end
	if SharedResult and typeof(SharedResult._G) == "table" then
		GlobalEnv = SharedResult._G
	end
	if SharedResult and typeof(SharedResult.getgenv) == "function" then
		GetGlobalEnv = SharedResult.getgenv
	end
	rawset(Locked, "_G", GlobalEnv)
	rawset(Locked, "getgenv", GetGlobalEnv)

	if rawget(Locked, "vector") and rawget(Locked, "vector").__lazy then
		local function MakeV3Raw(X, Y, Z)
			local V3Lib = rawget(Locked, "Vector3")
			if typeof(V3Lib) == "table" and typeof(V3Lib.new) == "function" then
				return V3Lib.new(X, Y, Z)
			end
			return setmetatable({ X = X, Y = Y, Z = Z }, {
				__index = function(_, K)
					if K == "Magnitude" then return math.sqrt(X*X+Y*Y+Z*Z) end
					return nil
				end,
				__tostring = function() return X..", "..Y..", "..Z end,
				__larryType = "Vector3",
			})
		end
		local function ReadV3Raw(V)
			if typeof(V) == "table" then
				return tonumber(rawget(V, "X")) or 0, tonumber(rawget(V, "Y")) or 0, tonumber(rawget(V, "Z")) or 0
			end
			return 0, 0, 0
		end
		rawset(Locked, "vector", {
			cross = function(A, B)
				local AX, AY, AZ = ReadV3Raw(A)
				local BX, BY, BZ = ReadV3Raw(B)
				return MakeV3Raw(AY*BZ - AZ*BY, AZ*BX - AX*BZ, AX*BY - AY*BX)
			end,
			dot = function(A, B)
				local AX, AY, AZ = ReadV3Raw(A)
				local BX, BY, BZ = ReadV3Raw(B)
				return AX*BX + AY*BY + AZ*BZ
			end,
			fromAxis = function(Axis)
				local N = typeof(Axis) == "table" and (rawget(Axis, "_Name") or rawget(Axis, "Name")) or tostring(Axis)
				if N == "X" then return MakeV3Raw(1,0,0) end
				if N == "Y" then return MakeV3Raw(0,1,0) end
				if N == "Z" then return MakeV3Raw(0,0,1) end
				return MakeV3Raw(0,0,0)
			end,
			fromNormalId = function(NormalId)
				local N = typeof(NormalId) == "table" and (rawget(NormalId, "_Name") or rawget(NormalId, "Name")) or tostring(NormalId)
				if N == "Top" then return MakeV3Raw(0,1,0) end
				if N == "Bottom" then return MakeV3Raw(0,-1,0) end
				if N == "Front" then return MakeV3Raw(0,0,-1) end
				if N == "Back" then return MakeV3Raw(0,0,1) end
				if N == "Left" then return MakeV3Raw(-1,0,0) end
				if N == "Right" then return MakeV3Raw(1,0,0) end
				return MakeV3Raw(0,0,0)
			end,
			fromEulerAnglesYXZ = function(X, Y, Z) return MakeV3Raw(X or 0, Y or 0, Z or 0) end,
			fromEulerAnglesXYZ = function(X, Y, Z) return MakeV3Raw(X or 0, Y or 0, Z or 0) end,
			fromOrientation = function(X, Y, Z) return MakeV3Raw(X or 0, Y or 0, Z or 0) end,
		})
	end

	for _, Key in next, { "_VERSION", "game", "workspace", "task", "loadstring", "wait", "spawn", "delay", "print", "getgenv" } do
		local Value = rawget(Locked, Key)
		if Value ~= nil then
			rawset(Locked, Key, Value)
		end
	end
	if SharedResult and SharedResult.Sync then
		SharedResult.Sync()
	end

	local Function

	if IsSourceString then
		Function = Tracer.LoadFunction(Source, Locked)
	else
		Function = Source
	end

	if not Function then
		error("Failed to load source")
	end

	local ParamCount, HasVarargs = debug.info(Function, "a")
	local BufferCount = HasVarargs and 0 or Constants.Limits.ParamBufferCount
	local Suffix = SessionState:ParamSuffix()

	local Params = {}
	for I = 1, ParamCount + BufferCount do
		Params[#Params + 1] = SessionProxy:Spy(`arg{I}{Suffix}`, { Param = true })
	end

	if HasVarargs and BufferCount > 0 then
		Params[#Params + 1] = SessionProxy:Spy("...", { Param = true })
	end

	local ExecResult = table.pack(xpcall(function()
		return Function(unpack(Params, 1, #Params))
	end, function(Err)
		return debug.traceback(tostring(Err), 2)
	end))

	View.WaitForPendingSessions()

	local ReturnValue = ""

	if not ExecResult[1] then
		local ErrMsg = LuauErrorFormatter.Format(ExecResult[2], Cfg.debug, {
			defaultFile = "LocalScript",
		})
		ReturnValue = `error({SessionBeautifier:Beautify(ErrMsg)})`
	elseif ExecResult.n > 1 then
		local Parts = {}
		for I = 2, ExecResult.n do
			Parts[#Parts + 1] = SessionBeautifier:Beautify(ExecResult[I], 1)
		end
		ReturnValue = "return " .. table.concat(Parts, ", ")
	end

	if IsOriginal and ReturnValue ~= "" then
		SessionState.Output[#SessionState.Output + 1] = ReturnValue
	end

	local FinalSource = Bootstrap.PostProcess.Finalize(
		SessionState,
		Cfg,
		CleanupMod,
		MinifierMod,
		RenamerMod,
		Collection,
		SessionBeautifier,
		UncFuncs
	)

	View.ResetRuntime()

	return StringUtil.Strip(FinalSource, true), ReturnValue
end

return Tracer