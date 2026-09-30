local Types = require("../Data/Types")
local TableUtil = require("../Utils/Table")
local InstanceModel = require("../Roblox/Instance")
local Signals = require("../Roblox/Signals")

local TypeChecks = {}

function TypeChecks.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = TypeChecks })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function TypeChecks:Resolve(FuncName, Arg)
	local State = self.State
	local Proxy = self.Proxy

	local Path = State:IsInternal(Arg)

	if not Path then
		if InstanceModel.IsInstance(Arg) then
			return FuncName == "type" and "userdata" or "Instance"
		end

		local SignalType = Signals.TypeOf(Arg)
		if SignalType then
			return FuncName == "type" and "userdata" or SignalType
		end

		return FuncName == "type" and type(Arg) or typeof(Arg)
	end

	local Resolved = TableUtil.ResolvePath(Path, State.Values) or Path
	local KnownType = Types.GetType(Resolved)

	if KnownType == nil and InstanceModel.IsInstance(Arg) then
		KnownType = "Instance"
	end

	local PathEntry = State:GetValue(Path)
	if KnownType == nil and PathEntry and typeof(PathEntry.Value) == "string" then
		local EntryValue = PathEntry.Value
		if string.match(EntryValue, "^Instance%.new%(")
			or string.match(EntryValue, ":GetService%(")
			or string.match(EntryValue, "^game:GetService%(")
		then
			KnownType = "Instance"
		end
	end

	local Hardcoded = { game = true, workspace = true, Workspace = true, Game = true }

	if Hardcoded[Path] or Hardcoded[Resolved] then
		KnownType = FuncName == "type" and "userdata" or "Instance"
	end

	if KnownType == nil and typeof(Resolved) == "string" then
		if string.match(Resolved, "^Instance%.new%(")
			or string.match(Resolved, ":GetService%(")
			or string.match(Resolved, "^game:GetService%(")
		then
			KnownType = "Instance"
		end
	end

	if KnownType == nil and typeof(Arg) == "table" then
		local ProxyValue = rawget(Arg, "V")
		if ProxyValue ~= nil then
			if InstanceModel.IsInstance(ProxyValue) then
				KnownType = "Instance"
			else
				KnownType = FuncName == "type" and type(ProxyValue) or typeof(ProxyValue)
			end
		end
	end

	if KnownType == "Instance" and FuncName == "type" then
		KnownType = "userdata"
	end

	local Expr = `{FuncName}({Path})`
	if KnownType ~= nil then
		self.Emitter:Append(Expr)
		return KnownType
	end

	return Proxy:Spy(Expr)
end

function TypeChecks:Build()
	return {
		type = function(...)
			return self:Resolve("type", ...)
		end,
		typeof = function(...)
			return self:Resolve("typeof", ...)
		end,
	}
end

return TypeChecks