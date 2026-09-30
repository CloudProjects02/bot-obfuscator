local StringUtil = require("../Utils/String")

local SpyHelpers = {}

function SpyHelpers.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = SpyHelpers })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function SpyHelpers:SpyParams(Amount)
	local Suffix = self.State:ParamSuffix()
	local Out = {}

	for I = 1, Amount do
		Out[I] = self.Proxy:Spy(`arg{I}{Suffix}`, { Param = true })
	end

	return unpack(Out)
end

function SpyHelpers:SpyVarargs()
	return self.Proxy:Spy("...", { Param = true })
end

function SpyHelpers:WrapStringMethod(SpiedVar, MethodName, ...)
	local State = self.State
	local Path = State:IsInternal(SpiedVar)

	if not Path then return nil end

	local Entry = State.Values[Path]
	local ActualValue = Entry and Entry.Value

	if typeof(ActualValue) == "string" then
		local Func = string[MethodName]
		if Func then
			return Func(ActualValue, ...)
		end
	end

	local Args = self.Beautifier:BeautifyTuple(...)
	local Value

	if #Args > 0 then
		Value = `{Path}:{MethodName}({Args})`
	else
		Value = `{Path}:{MethodName}()`
	end

	local Var = self.Scope:AddVar(MethodName, "str", Value, "__call")
	return self.Proxy:Spy(Var)
end

function SpyHelpers:CreateRealFunction(InternalPath, Callback)
	local State = self.State
	local Proxy = self.Proxy

	local Func = function(...)
		return Callback(...)
	end

	State:RegisterInternal(Func, InternalPath)
	return Func
end

function SpyHelpers:SpyCall(Path, ...)
	local Var = self.Scope:AddVar("", "", "", "__call") 

	self.State.Output[#self.State.Output] = nil
	local Value = `{Path}({self.Beautifier:BeautifyTuple(...)})`
	return self.Proxy:MultiSpy(Var, Value, 3)
end

function SpyHelpers:SpyIndex(Path, Key)
	local State = self.State

	local FormattedKey = State:IsInternal(Key)
	local Value

	if FormattedKey then
		Value = `{Path}[{FormattedKey}]`
	else
		Value = StringUtil.Index(Key, Path)
	end

	local Var = self.Scope:AddVar("", "", Value, "__index")
	return self.Proxy:Spy(Var)
end

function SpyHelpers:HandleNamecall(Object, Method, ...)
	local State = self.State
	local Path = State:IsInternal(Object)

	if not Path then return nil end

	local Value = `{Path}:{Method}({self.Beautifier:BeautifyTuple(...)})`
	local Var = self.Scope:GenerateName(Method, "call")

	return self.Proxy:MultiSpy(Var, Value, 3)
end

function SpyHelpers:HookLib(LibName, Extra)
	local State = self.State
	local Proxy = self.Proxy
	local Lib = getfenv()[LibName]

	if not Lib then return nil end

	local Result = { P = LibName }

	for Key, Value in next, Lib do
		if typeof(Value) == "function" then
			Result[Key] = Proxy:SafeWrap(Value, StringUtil.Index(Key, LibName), true)
		else
			Result[Key] = Value
		end
	end

	if Extra then
		for Key, Value in next, Extra do
			Result[Key] = Value
		end
	end

	local Iteration = self.Iteration

	local Meta = setmetatable(Result, {
		__tostring = function()
			return LibName
		end,
		__metatable = "This metatable is locked.",
		__iter = Iteration and function(Obj, Key)
			return Iteration:Iter(Obj, Key)
		end or nil,
	})

	State:RegisterInternal(Meta, LibName)
	return Meta
end

function SpyHelpers:SetIteration(Iteration)
	self.Iteration = Iteration
end

return SpyHelpers