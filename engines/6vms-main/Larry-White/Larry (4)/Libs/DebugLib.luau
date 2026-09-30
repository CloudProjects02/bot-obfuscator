local StringUtil = require("../Utils/String")
local IdentityUtil = require("../Utils/Identity")
local AntiTamper = require("../Env/AntiTamper")
local ErrorSanitizer = require("../Utils/ErrorSanitizer")
local SourceSanitizer = require("../Utils/SourceSanitizer")
local Types = require("../Data/Types")

local DebugLib = {}

function DebugLib.Build(Proxy, State, Emitter, Beautifier, Scope, Config, Iteration, AntiTamperFlags)
	local MemoryCategory = "Default"
	AntiTamperFlags = AntiTamperFlags or {}
	local ConstantOverrides = setmetatable({}, { __mode = "k" })
	local UpvalueOverrides = setmetatable({}, { __mode = "k" })

	local function CapturePrintedArgs(Func)
		if typeof(Func) ~= "function" then
			return {}
		end

		local TargetEnv = nil
		local OkEnv, ResolvedEnv = pcall(getfenv, Func)
		if OkEnv and typeof(ResolvedEnv) == "table" then
			TargetEnv = ResolvedEnv
		end
		if typeof(TargetEnv) ~= "table" then
			TargetEnv = getfenv()
		end
		if typeof(TargetEnv) ~= "table" then
			return {}
		end

		local PreviousPrint = TargetEnv.print
		local Captured = {}

		TargetEnv.print = function(...)
			local Args = table.pack(...)
			for I = 1, Args.n do
				Captured[I] = Args[I]
			end
		end

		pcall(Func)
		TargetEnv.print = PreviousPrint
		return Captured
	end

	local function ParseInternalFunctionName(Path)
		if typeof(Path) ~= "string" or Path == "" then
			return ""
		end

		local LastDot = string.match(Path, "([^%.]+)$")
		if LastDot and LastDot ~= "" then
			return LastDot
		end

		return Path
	end

	local function InternalCInfo(Func)
		if typeof(Func) ~= "function" then
			return nil
		end

		local Path = State:IsInternal(Func)
		if typeof(Path) ~= "string" or Path == "" then
			local Source = debug.info(Func, "s")
			local SourceText = tostring(Source or "")
			if SourceSanitizer.IsInternalSource(SourceText) then
				return {
					Path = SourceText,
					Name = debug.info(Func, "n") or "",
				}
			end
			return nil
		end

		return {
			Path = Path,
			Name = ParseInternalFunctionName(Path),
		}
	end

	local function SpyReturn(FuncName, ...)
		local Value = `{FuncName}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:GenerateName("dbg", string.match(FuncName, "%.([^%.]+)$") or FuncName)
		return Proxy:MultiSpy(Var, Value, 3)
	end

	local function AttachName(InfoTable, Name)
		if typeof(Name) == "string" and Name ~= "" then
			InfoTable.name = Name
		end
		return InfoTable
	end

	local Lib = {
		P = "debug",

		getinfo = function(Thread, Options)
			if typeof(Thread) ~= "function" and typeof(Thread) ~= "number" then
				return AttachName({
					source = "=[C]",
					short_src = "[C]",
					numparams = 1,
					is_vararg = 1,
					what = "C",
					currentline = 1,
					nups = 0,
				})
			end

			if AntiTamperFlags.Kolobf and typeof(Thread) == "number" then
				return {
					source = "=[C]",
					short_src = "[C]",
					numparams = 0,
					is_vararg = 1,
					what = "C",
					currentline = 1,
					nups = 0,
				}
			end

			local Internal = InternalCInfo(Thread)
			if Internal then
				local NumParams, IsVararg = debug.info(Thread, "a")
				return AttachName({
					source = "=[C]",
					short_src = "[C]",
					currentline = -1,
					numparams = NumParams or 0,
					is_vararg = IsVararg and 1 or 0,
					what = "C",
					nups = 0,
					func = Thread,
				}, Internal.Name)
			end

			local Line = debug.info(2, "l")
			local NumParams, IsVararg = debug.info(Thread, "a")
			local Source = debug.info(Thread, "s")
			local Name = debug.info(Thread, "n")
			local SafeSource, SafeShort, What = SourceSanitizer.SanitizeDebugSource(Source)
			local InternalPath = State:IsInternal(Thread)
			if InternalPath and Types.IsFunction(InternalPath) then
				What = "C"
			end

			local ForceNativeSource = typeof(Options) == "string" and string.find(Options, "s", 1, true) ~= nil
			local InfoTable = AttachName({
				source = ForceNativeSource and "=[C]" or SafeSource,
				short_src = ForceNativeSource and "[C]" or SafeShort,
				currentline = Line or 1,
				numparams = NumParams or 0,
				is_vararg = IsVararg and 1 or 0,
				what = ForceNativeSource and "C" or What,
				nups = 0,
				func = typeof(Thread) == "function" and Thread or function() end
			}, Name)

			if Config.hookOp then
				Scope:AddVar("debugInfo", "dbg", `debug.getinfo({Beautifier:Beautify(Thread)})`, "__call")
			end

			return InfoTable
		end,

		info = function(Thread, Options, ...)
			if typeof(Thread) == "function" and typeof(Options) == "string" then
				local Internal = InternalCInfo(Thread)
				local Source = tostring(debug.info(Thread, "s") or "")
				local IsScriptFunc = string.find(Source, "[string", 1, true) ~= nil

				if Internal or not IsScriptFunc then
					local Name = (Internal and Internal.Name) or (debug.info(Thread, "n") or "")
					local Results = {}

					for I = 1, #Options do
						local C = string.sub(Options, I, I)

						if C == "l" then
							table.insert(Results, -1)
						elseif C == "n" then
							table.insert(Results, Name ~= "" and Name or nil)
						elseif C == "s" then
							table.insert(Results, "[C]")
						elseif C == "a" then
							table.insert(Results, 0)
							table.insert(Results, true)
						else
							table.insert(Results, nil)
						end
					end

					return unpack(Results)
				end
			end

			local Internal = InternalCInfo(Thread)
			if Internal and typeof(Options) == "string" then
				local Results = {}

				for I = 1, #Options do
					local C = string.sub(Options, I, I)

					if C == "l" then
						table.insert(Results, -1)
					elseif C == "n" then
						table.insert(Results, Internal.Name ~= "" and Internal.Name or nil)
					elseif C == "s" then
						table.insert(Results, "[C]")
					elseif C == "a" then
						table.insert(Results, 0)
						table.insert(Results, true)
					else
						table.insert(Results, nil)
					end
				end

				return unpack(Results)
			end

			if State:IsInternal(Thread) or State:IsInternal(Options) then
				local ArgStr = Beautifier:BeautifyTuple(Thread, Options, ...)
				local Value = `debug.info({ArgStr})`

				if Config.hookOp then
					local Results = {}
					local Count = typeof(Options) == "string" and #Options or 1

					for I = 1, Count do
						local Var = Scope:AddVar("dinfo", "dbg", `select({I}, {Value})`, "__call")
						table.insert(Results, Proxy:Spy(Var))
					end

					return unpack(Results)
				end

				local Var = Scope:AddVar("dinfo", "dbg", Value, "__call")
				return Proxy:Spy(Var)
			end

			if typeof(Thread) == "function" then
				local Source = select(2, SourceSanitizer.SanitizeDebugSource(debug.info(Thread, "s")))

				if Source == "[C]" and typeof(Options) == "string" then
					local Results = {}

					for I = 1, #Options do
						local C = string.sub(Options, I, I)

						if C == "l" then
							table.insert(Results, -1)
						elseif C == "n" then
							local Name = debug.info(Thread, "n")
							local Path = State:IsInternal(Thread)
							if Path then
								local Parts = StringUtil.SplitPath(Path)
								Name = Parts[#Parts]
							end
							table.insert(Results, Name or "")
						elseif C == "s" then
							table.insert(Results, "[C]")
						elseif C == "a" then
							local P, V = debug.info(Thread, "a")
							table.insert(Results, P)
							table.insert(Results, V)
						else
							table.insert(Results, nil)
						end
					end

					return unpack(Results)
				end
			end

			return debug.info(Thread, Options, ...)
		end,

		traceback = function(Message)
			if Message ~= nil and typeof(Message) ~= "string" then
				error(`invalid argument #1 to 'traceback' (string expected got {typeof(Message)})`)
			end

			local Trace = debug.traceback(Message)
			Trace = AntiTamper.FilterTrace(Trace, IdentityUtil.TraceId)
			return ErrorSanitizer.Sanitize(Trace)
		end,

		getupvalue = function(Func, Index)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'getupvalue' (function expected)")
			end
			if typeof(Index) ~= "number" then
				error("invalid argument #2 to 'getupvalue' (number expected)")
			end

			if Index ~= 1 then
				return nil
			end

			local Override = UpvalueOverrides[Func]
			if Override ~= nil then
				return Override
			end

			local Captured = CapturePrintedArgs(Func)
			if Captured[1] ~= nil then
				return Captured[1]
			end

			local OkCall, Value = pcall(Func)
			if OkCall then
				return Value
			end

			return nil
		end,

		getupvalues = function(Func)
			if typeof(Func) ~= "function" then
				return {}
			end

			local Override = UpvalueOverrides[Func]
			if Override ~= nil then
				return { Override }
			end

			local OkCall, Value = pcall(Func)
			if OkCall and Value ~= nil then
				return { Value }
			end

			local Captured = CapturePrintedArgs(Func)
			if Captured[1] ~= nil then
				return { Captured[1] }
			end

			return {}
		end,

		setupvalue = function(Func, Index, Value)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'setupvalue' (function expected)")
			end
			if typeof(Index) ~= "number" then
				error("invalid argument #2 to 'setupvalue' (number expected)")
			end
			if Index == 1 then
				UpvalueOverrides[Func] = Value
			end
			return
		end,

		getstack = function(Level, Index)
			if Level == nil then
				return { "test" }
			end
			if typeof(Level) ~= "number" then
				error("invalid argument #1 to 'getstack' (number expected)")
			end
			if Index ~= nil then
				return "test"
			end
			return { "test" }
		end,

		setstack = function(Level, Index, Value)
			return Value
		end,

		getproto = function(Func, Index, Activated)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'getproto' (function expected)")
			end
			if typeof(Index) ~= "number" then
				error("invalid argument #2 to 'getproto' (number expected)")
			end
			error("debug.getproto is not available for this function", 0)
		end,

		getprotos = function(Func)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'getprotos' (function expected)")
			end
			return { 1, 2, 3, 4, 5 }
		end,

		getconstant = function(Func, Index)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'getconstant' (function expected)")
			end
			if typeof(Index) ~= "number" then
				error("invalid argument #2 to 'getconstant' (number expected)")
			end

			local Overrides = ConstantOverrides[Func]
			if typeof(Overrides) == "table" and Overrides[Index] ~= nil then
				return Overrides[Index]
			end

			if Index == 1 then
				return "print"
			end
			if Index == 2 then
				return nil
			end
			if Index == 3 then
				local Captured = CapturePrintedArgs(Func)
				return Captured[1]
			end
			return nil
		end,

		getconstants = function(Func)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'getconstants' (function expected)")
			end

			local Captured = CapturePrintedArgs(Func)
			local Result = {
				"print",
				nil,
				Captured[1],
				Captured[2],
			}

			local Overrides = ConstantOverrides[Func]
			if typeof(Overrides) == "table" then
				for Key, Value in next, Overrides do
					Result[Key] = Value
				end
			end

			return Result
		end,

		setconstant = function(Func, Index, Value)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'setconstant' (function expected)")
			end
			if typeof(Index) ~= "number" then
				error("invalid argument #2 to 'setconstant' (number expected)")
			end
			local Overrides = ConstantOverrides[Func]
			if typeof(Overrides) ~= "table" then
				Overrides = {}
				ConstantOverrides[Func] = Overrides
			end
			Overrides[Index] = Value
			return
		end,

		setmetatable = function(Object, Mt)
			if State:IsInternal(Object) then
				return SpyReturn("debug.setmetatable", Object, Mt)
			end
			return setmetatable(Object, Mt)
		end,

		getmetatable = function(Object)
			if State:IsInternal(Object) then
				return SpyReturn("debug.getmetatable", Object)
			end
			return getmetatable(Object)
		end,

		getrawmetatable = function(Object)
			if State:IsInternal(Object) then
				return nil
			end
			return getmetatable(Object)
		end,

		setrawmetatable = function(Object, Mt)
			if State:IsInternal(Object) then
				return Object
			end
			return setmetatable(Object, Mt)
		end,

		setmemorycategory = function(Category)
			if typeof(Category) ~= "string" then
				error("invalid argument #1 to 'setmemorycategory' (string expected)")
			end
			MemoryCategory = Category
			Emitter:Append(`debug.setmemorycategory({Beautifier:Beautify(Category)})`)
		end,

		getmemorycategory = function()
			return MemoryCategory
		end,

		resetmemorycategory = function()
			MemoryCategory = "Default"
			Emitter:Append("debug.resetmemorycategory()")
		end,

		profilebegin = function(Label)
			Emitter:Append(`debug.profilebegin({Beautifier:Beautify(Label)})`)
		end,

		profileend = function()
			Emitter:Append("debug.profileend()")
		end,
	}

	local Meta = setmetatable(Lib, {
		__index = function(_, Key)
			local Actual = debug[Key]
			if Actual then
				return Proxy:Spy(StringUtil.Index(Key, "debug"))
			end
			return nil
		end,
		__tostring = function()
			return "debug"
		end,
		__newindex = function(_, K, V)
			if K == "P" then return end
			rawset(_, K, V)
		end,
		__iter = Iteration and function(Obj, Key)
			return Iteration:Iter(Obj, Key)
		end or nil,
	})

	State:RegisterInternal(Meta, "debug")

	return Meta
end

return DebugLib