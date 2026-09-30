local ExecEnv = require("../Data/ExecEnv")
local StringUtil = require("../Utils/String")

local FunctionHooks = {}

function FunctionHooks.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = FunctionHooks })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.HookedFunctions = {}
	Self.ClonedFunctions = {}
	Self.RestoredFunctions = {}
	Self.CClosures = {}
	return Self
end

function FunctionHooks:Hookfunction(Target, Hook)
	local State = self.State
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Proxy = self.Proxy

	local TargetPath = State:IsInternal(Target)
	local HookPath = State:IsInternal(Hook)

	local TargetStr = TargetPath or Beautifier:Beautify(Target)
	local HookStr = HookPath or Beautifier:Beautify(Hook)

	local Value = `hookfunction({TargetStr}, {HookStr})`
	local Var = Scope:AddVar("hooked", "func", Value, "__call")

	local Old = typeof(Target) == "function" and Target or nil

	self.HookedFunctions[Target] = Hook

	local Result = Old or function(...) return ... end

	local Wrapped = Proxy:CreateFunction(function(...)
		if Old then return Old(...) end
		return ...
	end, Var)

	return Wrapped
end

function FunctionHooks:Hookmetamethod(Object, Method, Hook)
	local State = self.State
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Proxy = self.Proxy

	local ObjPath = State:IsInternal(Object)
	local HookPath = State:IsInternal(Hook)

	local ObjStr = ObjPath or Beautifier:Beautify(Object)
	local MethodStr = Beautifier:Beautify(Method)
	local HookStr = HookPath or Beautifier:Beautify(Hook)

	local Value = `hookmetamethod({ObjStr}, {MethodStr}, {HookStr})`
	local Var = Scope:AddVar("oldMeta", "hook", Value, "__call")

	local Mt = (typeof(Object) == "table" or typeof(Object) == "userdata") and getmetatable(Object)
	local Old

	if Mt and typeof(Mt) == "table" then

		local IsProtected = false
		local S = pcall(function()
			local Test = {}
			setmetatable(Test, Mt)
		end)
		if not S then IsProtected = true end

		if not IsProtected then

			local NewMt = {}
			for K, V in next, Mt do
				NewMt[K] = V
			end

			local SetS = pcall(setmetatable, Object, NewMt)
			if SetS then
				Mt = NewMt
			end
		end

		Old = Mt[Method]
		if typeof(Hook) == "function" then

			pcall(function() Mt[Method] = Hook end)
		end
	end

	if Old then
		return Proxy:CreateFunction(function(...)
			return Old(...)
		end, Var)
	end

	return Proxy:Spy(Var, { Function = true })
end

function FunctionHooks:Clonefunction(Func)
	local State = self.State
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Proxy = self.Proxy

	local Path = State:IsInternal(Func)

	if Path then
		local Value = `clonefunction({Path})`
		local Var = Scope:AddVar("cloned", "func", Value, "__call")
		return Proxy:Spy(Var)
	end

	if typeof(Func) ~= "function" then
		error("invalid argument #1 to 'clonefunction' (function expected)")
	end

	local Cloned = function(...)
		return Func(...)
	end

	self.ClonedFunctions[Cloned] = Func
	return Cloned
end

function FunctionHooks:Newcclosure(Func)
	local Proxy = self.Proxy
	local State = self.State
	local Scope = self.Scope
	local Beautifier = self.Beautifier

	local Path = State:IsInternal(Func)

	if Path then
		local Value = `newcclosure({Path})`
		local Var = Scope:AddVar("cclosure", "func", Value, "__call")
		return Proxy:Spy(Var)
	end

	if typeof(Func) ~= "function" then
		error("invalid argument #1 to 'newcclosure' (function expected)")
	end

	local Wrapped = Proxy:NewCClosure(Func)
	self.CClosures[Wrapped] = true
	return Wrapped
end

function FunctionHooks:Restorefunction(Func)
	local State = self.State
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier

	local Path = State:IsInternal(Func)
	local FuncStr = Path or Beautifier:Beautify(Func)

	Emitter:Append(`restorefunction({FuncStr})`)

	if self.HookedFunctions[Func] then
		self.HookedFunctions[Func] = nil
		self.RestoredFunctions[Func] = true
	end
end

function FunctionHooks:Isexecutorclosure(Func)
	local State = self.State
	local Scope = self.Scope
	local Beautifier = self.Beautifier

	local Path = State:IsInternal(Func)

	if Path then
		Scope:AddVar("isExec", "_call", `isexecutorclosure({Path})`, "__call")

		if ExecEnv.IsSafe(Path) then return true end
		return false
	end

	if self.CClosures[Func] then return true end
	if self.ClonedFunctions[Func] then return true end

	return debug.info(Func, "s") ~= "[C]"
end

function FunctionHooks:Isfunctionhooked(Func)
	return self.HookedFunctions[Func] ~= nil
end

function FunctionHooks:Build()
	return {
		hookfunction = function(T, H) return self:Hookfunction(T, H) end,
		hookmetamethod = function(O, M, H) return self:Hookmetamethod(O, M, H) end,
		clonefunction = function(F) return self:Clonefunction(F) end,
		newcclosure = function(F) return self:Newcclosure(F) end,
		restorefunction = function(F) return self:Restorefunction(F) end,
		isexecutorclosure = function(F) return self:Isexecutorclosure(F) end,
		isfunctionhooked = function(F) return self:Isfunctionhooked(F) end,
	}
end

return FunctionHooks