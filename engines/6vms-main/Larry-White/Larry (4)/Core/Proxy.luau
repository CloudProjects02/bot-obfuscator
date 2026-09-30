local StringUtil = require("../Utils/String")
local IdentityUtil = require("../Utils/Identity")
local ProxyMeta = require("./ProxyMeta")

local Proxy = {}
Proxy.__index = Proxy

function Proxy.new(State, Emitter, Beautifier, Scope)
	local Self = setmetatable({}, Proxy)
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	return Self
end

function Proxy:IsInternal(Object)
	return self.State:IsInternal(Object)
end

function Proxy:RegisterInternal(Object, Path)
	self.State:RegisterInternal(Object, Path)
end

function Proxy:BuildMetatable(Path, IsParam)
	return ProxyMeta.Build(self, Path, IsParam)
end

function Proxy:Spy(Path, Flags)
	local State = self.State
	local Spied = State.Spied

	if Spied[Path] then return Spied[Path] end

	Flags = Flags or {}
	local IsParam = Flags.Param

	local Meta = self:BuildMetatable(Path, IsParam)

	local Object = setmetatable({ P = Path, ISP = IsParam }, Meta)
	Spied[Path] = Object

	if IsParam then
		State.ParamsUsed[Path] = false
	end

	State:RegisterInternal(Object, Path)

	return Object
end

function Proxy:SpyParams(Amount)
	local Out = {}
	local Suffix = self.State:ParamSuffix()

	for I = 1, Amount do
		Out[I] = self:Spy(`arg{I}{Suffix}`, { Param = true })
	end

	return unpack(Out)
end

function Proxy:MultiSpy(Var, Value, Amount)
	Amount = Amount or 2
	local Out = {}
	local Scope = self.Scope
	local State = self.State
	local Emitter = self.Emitter

	local Vars = {}
	for I = 1, Amount do
		if I == 1 then
			Vars[I] = Var
		else
			Vars[I] = Scope:GenerateName(Var, "ret")
		end
	end

	Emitter:Append(`local {table.concat(Vars, ", ")} = {Value}`)

	for I = 1, Amount do
		local CallVar = Vars[I]
		State:Define(CallVar, `select({I}, {Value})`, "__call")
		Out[I] = self:Spy(CallVar)
	end

	return unpack(Out)
end

function Proxy:CreateFunction(Callback, Path)
	Path = Path or "(function()end)"

	local State = self.State
	local Wrapped = function(...)
		return Callback(...)
	end

	State:RegisterInternal(Wrapped, Path)
	return Wrapped
end

function Proxy:NewCClosure(Function)
	return function(...)
		return Function(...)
	end
end

function Proxy:SafeWrap(Func, Path, IsCore)
	if typeof(Func) ~= "function" then return end

	local State = self.State
	local Name = debug.info(Func, "n")

	local function IsDangerous(V)
		if typeof(V) == "table" then
			for K, Val in next, V do
				if IsDangerous(K) or IsDangerous(Val) then
					return true
				end
			end
		end

		local Internal = State:IsInternal(V)
		local SafeInternals = { "string", "table", "os", "task", "coroutine", "debug" }

		return Internal
			and Internal ~= "getfenv()"
			and not table.find(SafeInternals, Internal)
			and (typeof(V) ~= "table" or not rawget(V, "ISP"))
	end

	local function Helper(...)
		local ArgStr = self.Beautifier:BeautifyTuple(...)
		local Var = self.Scope:GenerateName(Name, "ret")
		local Value = `{Path}({ArgStr})`

		if Name == "" then
			self.Emitter:Append(`local {Var} = {Value}`)
		end

		return self:MultiSpy(Var, Value, 3)
	end

	return self:CreateFunction(function(...)
		local Args = table.pack(...)
		local CallArgs = {}
		local HasOpaqueInternal = false

		for I = 1, Args.n do
			local Arg = Args[I]
			local IsParamSpy = typeof(Arg) == "table" and rawget(Arg, "ISP")
			local ArgPath = State:IsInternal(Arg)
			local ArgType = typeof(Arg)
			local IsPrimitiveInternal = ArgType == "number" or ArgType == "string" or ArgType == "boolean" or ArgType == "function"
			local Unwrapped = nil
			local IsProxyTable = ArgType == "table" and rawget(Arg, "P") ~= nil

			if ArgPath and typeof(Arg) == "table" then
				Unwrapped = rawget(Arg, "V")
			end

			if Unwrapped ~= nil then
				CallArgs[I] = Unwrapped
				continue
			end

			if ArgPath and ArgType == "table" and not IsProxyTable then
				CallArgs[I] = Arg
				continue
			end

			if ArgPath and not IsPrimitiveInternal and (not IsCore or not IsParamSpy) then
				HasOpaqueInternal = true
				break
			end

			CallArgs[I] = Arg
		end

		if HasOpaqueInternal then
			local Result = Helper(...)
			if Result then return Result end
		end

		local Ret = nil
		local Err = nil
		local Success, PackedOrErr = pcall(function()
			return table.pack(Func(unpack(CallArgs, 1, Args.n)))
		end)
		if Success then
			Ret = PackedOrErr
		else
			Err = PackedOrErr
		end

		if Err then
			if Path == "table.create" and typeof(Err) == "string" and string.find(Err, "size out of range", 1, true) then
				local Size = tonumber(CallArgs[1]) or 0
				local Fill = CallArgs[2]
				if Size < 0 then Size = 0 end
				if Size > 100000 then Size = 100000 end

				local SafeTable = {}
				for I = 1, Size do
					SafeTable[I] = Fill
				end

				return SafeTable
			end

			error(Err, 0)
		end

		if Ret then
			return unpack(Ret, 1, Ret.n)
		end
	end, Path)
end

return Proxy