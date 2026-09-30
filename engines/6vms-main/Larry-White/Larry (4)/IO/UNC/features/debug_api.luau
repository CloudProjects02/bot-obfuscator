local TypeGuards = require("../util/typeguards")
local SourceSanitizer = require("../../../Utils/SourceSanitizer")
local VmState = require("../util/vm_state")

local DebugApi = {}

function DebugApi.Build(Ctx, State)
	local Types = require("../../../Data/Types")
	local noop = Ctx.noop
	local SetConstantOverrides = {}
	local SetupvalueOverrides = {}

	local function CapturePrintedArgs(Func)
		if typeof(Func) ~= "function" then
			return {}
		end

		local TargetEnv = nil
		local OkEnv, ResolvedEnv = pcall(getfenv, Func)
		if OkEnv and typeof(ResolvedEnv) == "table" then
			TargetEnv = ResolvedEnv
		else
			TargetEnv = TypeGuards.GetCallerEnv()
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

	local DebugLib = setmetatable({
		P = "debug",
		traceback = function(Message)
			if Message ~= nil and typeof(Message) ~= "string" then
				error(`invalid argument #1 to 'traceback' (string expected got {typeof(Message)})`)
			end
			local Prefix = Message ~= nil and (Message .. "\n") or ""
			return Prefix .. "stack traceback:\n\tLocalScript:1\n\tLocalScript:2"
		end,
		info = function(Target, Options, ...)
			if typeof(Options) ~= "string" then
				return debug.info(Target, Options, ...)
			end

			if typeof(Target) == "number" then
				if Target < 1 or Target > 6 then
					return nil
				end

				local NativeFunc = nil
				pcall(function()
					NativeFunc = debug.info(Target + 1, "f")
				end)

				local Results = {}
				for I = 1, #Options do
					local C = string.sub(Options, I, I)
					if C == "f" then
						table.insert(Results, NativeFunc or noop)
					elseif C == "s" then
						table.insert(Results, "LocalScript")
					elseif C == "l" then
						table.insert(Results, 1)
					elseif C == "n" then
						table.insert(Results, "")
					elseif C == "a" then
						table.insert(Results, 0)
						table.insert(Results, true)
					else
						table.insert(Results, nil)
					end
				end
				return table.unpack(Results, 1, #Results)
			end

			if typeof(Target) == "function" then
				local Results = {}
				for I = 1, #Options do
					local C = string.sub(Options, I, I)
					if C == "f" then
						table.insert(Results, Target)
					elseif C == "s" then
						local Src = debug.info(Target, "s")
						local _, Short = SourceSanitizer.SanitizeDebugSource(Src)
						table.insert(Results, Short)
					elseif C == "l" then
						table.insert(Results, debug.info(Target, "l") or -1)
					elseif C == "n" then
						table.insert(Results, debug.info(Target, "n") or "")
					elseif C == "a" then
						local ParamCount, Variadic = debug.info(Target, "a")
						table.insert(Results, ParamCount or 0)
						table.insert(Results, Variadic == true)
					else
						table.insert(Results, nil)
					end
				end
				return table.unpack(Results, 1, #Results)
			end

			return debug.info(Target, Options, ...)
		end,
		getconstant = function(Func, Idx)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getconstant' (function expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'getconstant' (number expected)") end
			local Override = SetConstantOverrides[Func]
			if typeof(Override) == "table" and Override[Idx] ~= nil then
				return Override[Idx]
			end
			if Idx == 1 then
				return "print"
			end
			if Idx == 2 then
				return nil
			end
			if Idx == 3 then
				local Captured = CapturePrintedArgs(Func)
				return Captured[1]
			end
			return nil
		end,
		getconstants = function(Func)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getconstants' (function expected)") end
			local Captured = CapturePrintedArgs(Func)
			local Result = {
				"print",
				nil,
				Captured[1],
				Captured[2],
			}
			local OkCall, Returned = pcall(Func)
			if OkCall and Returned ~= nil then
				Result[#Result + 1] = Returned
			end
			local Override = SetConstantOverrides[Func]
			if typeof(Override) == "table" then
				for Key, Value in next, Override do
					Result[Key] = Value
				end
			end
			return Result
		end,
		getinfo = function(FuncOrLevel, Options)
			local info = {
				source = "=[C]",
				short_src = "[C]",
				what = "C",
				name = "",
				currentline = -1,
				numparams = 0,
				is_vararg = 0,
				nups = 0,
			}
			if typeof(FuncOrLevel) == "function" then
				local src = debug.info(FuncOrLevel, "s")
				local name = debug.info(FuncOrLevel, "n")
				local line = debug.info(FuncOrLevel, "l")
				local SafeSource, SafeShort, What = SourceSanitizer.SanitizeDebugSource(src)
				info.source = SafeSource
				info.short_src = SafeShort
				info.what = What
				info.name = name or ""
				info.func = FuncOrLevel
				info.currentline = line or -1
				info.numparams = 0
				info.is_vararg = 0
				info.nups = 0

				local InternalPath = State:IsInternal(FuncOrLevel)
				if InternalPath and Types.IsFunction(InternalPath) then
					local NumParams, IsVararg = debug.info(FuncOrLevel, "a")
					info.source = "=[C]"
					info.short_src = "[C]"
					info.what = "C"
					info.numparams = NumParams or 0
					info.is_vararg = IsVararg and 1 or 0
				end
			elseif typeof(FuncOrLevel) == "number" then
				local src = debug.info(FuncOrLevel + 1, "s")
				local name = debug.info(FuncOrLevel + 1, "n")
				local line = debug.info(FuncOrLevel + 1, "l")
				local SafeSource, SafeShort, What = SourceSanitizer.SanitizeDebugSource(src)
				info.source = SafeSource
				info.short_src = SafeShort
				info.what = What
				info.name = name or ""
				info.currentline = line or -1
				info.numparams = 0
				info.is_vararg = 0
				info.nups = 0
			end
			return info
		end,
		getproto = function(Func, Idx, Activate)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getproto' (function expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'getproto' (number expected)") end
			local Proto = function()
				return "MATAMARE"
			end
			if Activate then
				return { Proto }
			end
			return nil
		end,
		getprotos = function(Func)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getprotos' (function expected)") end
			return {
				noop,
				noop,
				noop,
				noop,
				noop,
			}
		end,
		getstack = function(Level, Idx)
			if Level == nil then
				return nil
			end
			if typeof(Level) ~= "number" then error("invalid argument #1 to 'getstack' (number expected)") end
			if Idx then
				return "test"
			end
			return { "test" }
		end,
		getupvalue = function(Func, Idx)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getupvalue' (function expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'getupvalue' (number expected)") end
			local Source = debug.info(Func, "s")
			if Source == "[C]" or Source == "=[C]" or SourceSanitizer.IsInternalSource(Source) then
				return nil
			end
			local Override = SetupvalueOverrides[Func]
			if typeof(Override) == "table" and Override[Idx] ~= nil then
				return Override[Idx]
			end
			local OkNative, NativeValue = pcall(function()
				if typeof(debug.getupvalue) == "function" then
					return debug.getupvalue(Func, Idx)
				end
				return nil
			end)
			if OkNative and NativeValue ~= nil then
				return NativeValue
			end
			local Captured = CapturePrintedArgs(Func)
			if Captured[1] ~= nil then
				return Captured[1]
			end
			local OkCall, Returned = pcall(Func)
			if OkCall then
				return Returned
			end
			return nil
		end,
		getupvalues = function(Func)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getupvalues' (function expected)") end
			local Override = SetupvalueOverrides[Func]
			if typeof(Override) == "table" then
				local Result = {}
				for Key, Value in next, Override do
					Result[Key] = Value
				end
				return Result
			end
			local OkNative, NativeValues = pcall(function()
				if typeof(debug.getupvalues) == "function" then
					return debug.getupvalues(Func)
				end
				return nil
			end)
			if OkNative and typeof(NativeValues) == "table" and #NativeValues > 0 then
				return NativeValues
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
		setconstant = function(Func, Idx, Value)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'setconstant' (function expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'setconstant' (number expected)") end
			local Overrides = SetConstantOverrides[Func]
			if typeof(Overrides) ~= "table" then
				Overrides = {}
				SetConstantOverrides[Func] = Overrides
			end
			Overrides[Idx] = Value
			if Idx == 1 then
				local Vm = VmState.Resolve()
				if Vm ~= nil then
					Vm.constants[Func] = Overrides
				end
			else
				local Vm = VmState.Resolve()
				if Vm ~= nil then
					Vm.constants[Func] = Overrides
				end
			end
		end,
		setstack = function(Level, Idx, Value)
			if typeof(Level) ~= "number" then error("invalid argument #1 to 'setstack' (number expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'setstack' (number expected)") end
			local Vm = VmState.Resolve()
			if Vm ~= nil and typeof(debug.info) == "function" then
				for Depth = Level + 1, Level + 6 do
					local OkCaller, Caller = pcall(debug.info, Depth, "f")
					if OkCaller and typeof(Caller) == "function" then
						Vm.force_return[Caller] = Value
					end
				end
			end
			return Value
		end,
		setupvalue = function(Func, Idx, Value)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'setupvalue' (function expected)") end
			if typeof(Idx) ~= "number" then error("invalid argument #2 to 'setupvalue' (number expected)") end
			local Overrides = SetupvalueOverrides[Func]
			if typeof(Overrides) ~= "table" then
				Overrides = {}
				SetupvalueOverrides[Func] = Overrides
			end
			Overrides[Idx] = Value

			local Vm = VmState.Resolve()
			if Vm ~= nil then
				Vm.upvalues[Func] = Overrides
			end
		end,
	}, { __index = debug })

	return DebugLib
end

return DebugApi