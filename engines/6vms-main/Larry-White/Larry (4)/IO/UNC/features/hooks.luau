local TypeGuards = require("../util/typeguards")
local Namecall = require("../util/namecall")
local VmState = require("../util/vm_state")

local Hooks = {}

function Hooks.Build(Ctx, Emitter, Beautifier)
	local noop = Ctx.noop

	local function BuildOriginalWrapper(Target)
		return function(...)
			local Vm = VmState.Resolve()
			local PreviousHook = nil

			if Vm ~= nil then
				PreviousHook = Vm.hooks[Target]
				Vm.hooks[Target] = nil
			end

			local Results = table.pack(Target(...))

			if Vm ~= nil then
				if PreviousHook ~= nil then
					Vm.hooks[Target] = PreviousHook
				else
					Vm.hooks[Target] = nil
				end
			end

			return table.unpack(Results, 1, Results.n)
		end
	end

	return {
		hookfunction = function(Target, Hook)
			if typeof(Target) ~= "function" then error("invalid argument #1 to 'hookfunction' (function expected)") end
			if typeof(Hook) ~= "function" then error("invalid argument #2 to 'hookfunction' (function expected)") end
			local old = BuildOriginalWrapper(Target)
			Ctx.original_functions[Hook] = old
			Ctx.hooked_functions[Target] = Hook
			local Vm = VmState.Resolve()
			if Vm ~= nil then
				Vm.hooks[Target] = Hook
			end
			return old
		end,

		hookmetamethod = function(Object, Method, Hook)
			if typeof(Method) ~= "string" then error("invalid argument #2 to 'hookmetamethod' (string expected)") end
			if typeof(Hook) ~= "function" then error("invalid argument #3 to 'hookmetamethod' (function expected)") end

			local RawClassName = typeof(Object) == "table" and rawget(Object, "ClassName") or nil
			local RawGetService = typeof(Object) == "table" and rawget(Object, "GetService") or nil
			local InstanceMod = TypeGuards.SafeRequireInstance()
			local IsRuntimeInstance = InstanceMod and InstanceMod.IsInstance and InstanceMod.IsInstance(Object)
			if typeof(Object) == "table" and (RawClassName ~= nil or RawGetService ~= nil or IsRuntimeInstance) and Method ~= "__namecall" then
				error("cannot hook protected instance metamethod", 0)
			end

			if Method == "__namecall" then
				local Entry = Namecall.EnsureNamecallState(Ctx, Object)
				if Entry ~= nil then
					Entry.hook = Hook
					Ctx.hooked_metamethods[Object] = {
						method = Method,
						hook = Hook,
					}
				else

					Ctx.lastNamecallMethod = "GetService"
					pcall(Hook, Object)
				end

				return function(Self, ...)
					local Args = table.pack(...)
					if Args.n > 0 and Args[1] == Self then
						for Index = 1, Args.n - 1 do
							Args[Index] = Args[Index + 1]
						end
						Args[Args.n] = nil
						Args.n -= 1
					end

					local ActiveMethod = Ctx.lastNamecallMethod
					if typeof(Ctx.namecall_override_method) == "string" and Ctx.namecall_override_method ~= "" then
						ActiveMethod = Ctx.namecall_override_method
					end
					Ctx.namecall_override_method = nil
					return Namecall.CallOriginalNamecall(Ctx, Self, ActiveMethod, table.unpack(Args, 1, Args.n))
				end
			end

			local mt
			if typeof(Object) == "table" or typeof(Object) == "userdata" then
				mt = Ctx.raw_metatables[Object] or Ctx.native_getmetatable(Object)
			end
			local old = noop
			if mt and typeof(mt) == "table" then
				if rawget(mt, Method) then
					old = rawget(mt, Method)
				end
				rawset(mt, Method, Hook)
				Ctx.hooked_metamethods[Method] = { original = old, hook = Hook, mt = mt }
			end
			return old
		end,

		restorefunction = function(Func)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'restorefunction' (function expected)") end
			for target, hook in Ctx.hooked_functions do
				if hook == Func or target == Func then
					Ctx.hooked_functions[target] = nil
					local Vm = VmState.Resolve()
					if Vm ~= nil then
						Vm.hooks[target] = nil
					end
					break
				end
			end
		end,

		replaceclosure = function(Target, Hook)
			if typeof(Target) ~= "function" then error("invalid argument #1 to 'replaceclosure' (function expected)") end
			if typeof(Hook) ~= "function" then error("invalid argument #2 to 'replaceclosure' (function expected)") end
			local old = BuildOriginalWrapper(Target)
			Ctx.hooked_functions[Target] = Hook
			local Vm = VmState.Resolve()
			if Vm ~= nil then
				Vm.hooks[Target] = Hook
			end
			return old
		end,

		iscclosure = function(Func)
			if typeof(Func) ~= "function" then return false end
			local CallerEnv = TypeGuards.GetCallerEnv()
			if Func == CallerEnv.print or Func == CallerEnv.warn or Func == CallerEnv.error then
				return true
			end
			if Ctx.builtin_cclosures[Func] then return true end
			if Ctx.cclosure_registry[Func] then return true end
			local s = debug.info(Func, "s")
			if s == "[C]" then return true end
			return false
		end,

		islclosure = function(Func)
			if typeof(Func) ~= "function" then return false end
			local CallerEnv = TypeGuards.GetCallerEnv()
			if Func == CallerEnv.print or Func == CallerEnv.warn or Func == CallerEnv.error then
				return false
			end
			if Ctx.builtin_cclosures[Func] then return false end
			if Ctx.cclosure_registry[Func] then return false end
			local s = debug.info(Func, "s")
			if s == "[C]" then return false end
			return true
		end,

		isexecutorclosure = function(Func)
			if typeof(Func) ~= "function" then return false end
			local CallerEnv = TypeGuards.GetCallerEnv()
			if Func == CallerEnv.print or Func == CallerEnv.warn or Func == CallerEnv.error then
				return false
			end
			if Ctx.builtin_cclosures[Func] then
				return false
			end
			return true
		end,

		newcclosure = function(Func)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'newcclosure' (function expected)")
			end
			local wrapped = function(...)
				return Func(...)
			end
			Ctx.cclosure_registry[wrapped] = true
			return wrapped
		end,

		clonefunction = function(Func)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'clonefunction' (function expected)")
			end
			return function(...)
				return Func(...)
			end
		end,

		cloneclosure = function(Func)
			if typeof(Func) ~= "function" then
				error("invalid argument #1 to 'cloneclosure' (function expected)")
			end
			return function(...)
				return Func(...)
			end
		end,

		getcallbackvalue = function(Object, Property)
			if typeof(Property) ~= "string" then error("invalid argument #2 to 'getcallbackvalue' (string expected)") end
			if typeof(Object) == "Instance" then
				local ok, val = pcall(function()
					return (Object :: any)[Property]
				end)
				if ok and typeof(val) == "function" then return val end
			end
			if typeof(Object) == "table" then
				local ok, val = pcall(function() return Object[Property] end)
				if ok and typeof(val) == "function" then return val end
				if Object._Properties and typeof(Object._Properties) == "table" then
					local pval = Object._Properties[Property]
					if pval and typeof(pval) == "function" then return pval end
				end
			end
			return nil
		end,
	}
end

return Hooks