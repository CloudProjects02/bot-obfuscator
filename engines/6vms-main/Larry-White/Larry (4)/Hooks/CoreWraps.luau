local IdentityUtil = require("../Utils/Identity")
local ExecEnv = require("../Data/ExecEnv")
local Types = require("../Data/Types")
local TableUtil = require("../Utils/Table")
local InstanceModel = require("../Roblox/Instance")
local luau = require("@lune/luau")

local CoreWraps = {}
local CompileOptions = {
	optimizationLevel = 2,
	debugLevel = 1,
}

local function IsProtectedStringModule(ModuleName)
	return typeof(ModuleName) == "string" and string.sub(ModuleName, 1, 6) == "@lune/"
end

function CoreWraps.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = CoreWraps })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.LockedEnv = nil
	Self.ModuleCache = setmetatable({}, { __mode = "k" })
	return Self
end

function CoreWraps:SetLockedEnv(Env)
	self.LockedEnv = Env
end

function CoreWraps:Tostring(Str)
	local State = self.State
	local StrType = typeof(Str)

	if StrType == "string" or StrType == "number" or StrType == "boolean" or StrType == "nil" then
		return tostring(Str)
	end

	if State:IsInternal(Str) then
		if InstanceModel.IsInstance(Str) then
			return tostring(Str)
		end

		local Path = State:IsInternal(Str)
		if typeof(Str) == "table" then
			Path = rawget(Str, "P") or Path
		end
		if typeof(Path) ~= "string" then
			return tostring(Str)
		end
		local Type = Types.GetType(Path)
		if typeof(Type) ~= "string" or Type == "" then
			Type = typeof(Str)
		end
		return IdentityUtil.Address(Path, Type, State.Addresses)
	end

	return tostring(Str)
end

function CoreWraps:Wait(A)
	local Proxy = self.Proxy
	local Scope = self.Scope
	local Beautifier = self.Beautifier

	local Value = A and `wait({Beautifier:Beautify(A)})` or "wait()"
	return Proxy:Spy(Scope:AddVar("waited", "", Value, "__call"))
end

function CoreWraps:Pcall(F, ...)
	local State = self.State
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Proxy = self.Proxy

	local InternalPath = State:IsInternal(F)
	local Args = table.pack(...)
	local ArgStr = Beautifier:BeautifyTuple(...)

	local FuncStr
	if InternalPath then
		FuncStr = InternalPath
	else
		FuncStr = Beautifier:Beautify(F)
	end

	local BlockStart = #State.Output + 1

	local Results = table.pack(pcall(F, ...))

	local Vars = {}
	for I = 1, Results.n do
		local Var = Scope:AddVar("pcall", "ret", Beautifier:Beautify(Results[I]), "__call")
		table.insert(Vars, Proxy:Spy(Var))
	end

	return unpack(Vars)
end

function CoreWraps:Setfenv(A, B)
	if getmetatable(B) then return end
	if self.LockedEnv then
		setfenv(A, setmetatable(B, self.LockedEnv))
	end
end

function CoreWraps:Islclosure(A)
	local State = self.State
	local Scope = self.Scope
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier

	Scope:AddVar("IsLua", "_call", `islclosure({Beautifier:Beautify(A)})`, "__call")

	local Path = State:IsInternal(A)
	if Path then
		if ExecEnv.IsSafe(Path) then return false end
	end

	return debug.info(A, "s") ~= "[C]"
end

function CoreWraps:Iscclosure(A)
	local State = self.State
	local Scope = self.Scope
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier

	Scope:AddVar("IsC", "_call", `iscclosure({Beautifier:Beautify(A)})`, "__call")

	local Path = State:IsInternal(A)
	if Path then
		if ExecEnv.IsSafe(Path) then return true end
	end

	return debug.info(A, "s") == "[C]"
end

function CoreWraps:Getmetatable(Tbl)
	local State = self.State

	if State:IsInternal(Tbl) then return nil end

	local Tp = typeof(Tbl)

	if Tp == "string" then
		return setmetatable({}, {
			__index = function(_, Key)
				return string[Key]
			end,
			__tostring = function()
				return "string"
			end,
		})
	end

	if Tp ~= "table" and Tp ~= "userdata" then
		error(`invalid argument #1 to 'getmetatable', 'table' or 'userdata' expected got '{Tp}'`)
	end

	return getmetatable(Tbl)
end

function CoreWraps:Select(Index, ...)
	local State = self.State
	local Proxy = self.Proxy
	local Scope = self.Scope
	local Beautifier = self.Beautifier

	if Index == "#" then
		return select(Index, ...)
	end

	if typeof(Index) == "table" then
		local RawValue = rawget(Index, "V")
		if RawValue == "#" then
			return select("#", ...)
		end

		local Path = State:IsInternal(Index)
		if typeof(Path) == "string" and Path ~= "" then
			local Entry = State.Values[Path]
			if Entry and Entry.Value == "#" then
				return select("#", ...)
			end
		end
	end

	local PathIdx = State:IsInternal(Index)

	if PathIdx then
		local Value = `select({PathIdx}, {Beautifier:BeautifyTuple(...)})`
		local Var = Scope:AddVar("sel", "call", Value, "__call")
		return Proxy:Spy(Var)
	end

	local Args = table.pack(...)
	local HasInternal = false

	for I = 1, Args.n do
		if State:IsInternal(Args[I]) then
			HasInternal = true
			break
		end
	end

	if HasInternal then
		local Value = `select({Beautifier:Beautify(Index)}, {Beautifier:BeautifyTuple(...)})`
		local Var = Scope:AddVar("sel", "call", Value, "__call")
		return Proxy:Spy(Var)
	end

	return select(Index, ...)
end

function CoreWraps:Assert(Value, Message)
	local State = self.State
	local Beautifier = self.Beautifier
	local Emitter = self.Emitter

	local PathV = State:IsInternal(Value)
	local PathM = State:IsInternal(Message)

	if PathV or PathM then
		local ValStr = PathV or Beautifier:Beautify(Value)
		local MsgStr = PathM or (Message ~= nil and Beautifier:Beautify(Message) or nil)

		local Call = MsgStr and `assert({ValStr}, {MsgStr})` or `assert({ValStr})`
		Emitter:Append(Call)
		return Value
	end

	return assert(Value, Message)
end

function CoreWraps:Getgc()
	return table.create(math.random(1000, 10000), {})
end

function CoreWraps:Require(Mod)
	local State = self.State
	local Scope = self.Scope
	local Beautifier = self.Beautifier
	local Proxy = self.Proxy

	local Path = State:IsInternal(Mod)
	local ActualMod = Path and (rawget(Mod, "V") or Mod) or Mod
	local ModStr = Path or Beautifier:Beautify(Mod)

	local Var = Scope:AddVar("req", "call", `require({ModStr})`, "__call")

	if ActualMod == "@lune/task" and self.LockedEnv and self.LockedEnv.task then
		return self.LockedEnv.task
	end

	if InstanceModel.IsInstance(ActualMod) and ActualMod:GetClassName() == "ModuleScript" then
		local Cached = self.ModuleCache[ActualMod]
		if Cached ~= nil then
			return Cached
		end

		local Source = ActualMod.Source
		if typeof(Source) ~= "string" then
			error("ModuleScript.Source must be a string", 0)
		end

		local CompileOk, Compiled = pcall(luau.compile, Source, CompileOptions)
		if not CompileOk then
			error(Compiled, 0)
		end

		local LoadOk, ChunkOrErr = pcall(luau.load, Compiled, {
			debugName = ActualMod.Name or "ModuleScript",
			environment = self.LockedEnv,
		})
		if not LoadOk or typeof(ChunkOrErr) ~= "function" then
			error(ChunkOrErr or "Failed to load ModuleScript", 0)
		end

		local Run = table.pack(pcall(ChunkOrErr))
		if not Run[1] then
			error(Run[2], 0)
		end

		if Run.n < 2 or Run[2] == nil then
			error("module code did not return exactly one value", 0)
		end

		self.ModuleCache[ActualMod] = Run[2]
		ActualMod._Properties["Loaded"] = true
		return Run[2]
	end

	if typeof(ActualMod) == "string" then
		if IsProtectedStringModule(ActualMod) then
			error(`cannot require protected module '{ActualMod}'`, 0)
		end
		local Ok, Result = pcall(require, ActualMod)
		if Ok then
			return Result
		end
		error(Result, 0)
	end

	if Path then
		return Proxy:Spy(Var)
	end

	error(`invalid argument #1 to 'require' (string or ModuleScript expected, got {typeof(Mod)})`, 0)
end

function CoreWraps:Build()
	return {
		tostring = function(A) return self:Tostring(A) end,
		wait = function(A) return self:Wait(A) end,
		setfenv = function(A, B) return self:Setfenv(A, B) end,
		islclosure = function(A) return self:Islclosure(A) end,
		iscclosure = function(A) return self:Iscclosure(A) end,
		getmetatable = function(A) return self:Getmetatable(A) end,
		select = function(I, ...) return self:Select(I, ...) end,
		assert = function(V, M) return self:Assert(V, M) end,
		getgc = function() return self:Getgc() end,
		require = function(M) return self:Require(M) end,
		ypcall = function(F, ErrHandler, ...)
			if typeof(ErrHandler) ~= "function" then
				ErrHandler = function(err) return err end
			end
			return xpcall(F, ErrHandler, ...)
		end,
		settings = function()
			local Services = require("../Roblox/Services")
			local SettingsService = Services.GetOrNil("Settings")
			if SettingsService then
				return SettingsService
			end
			error("Settings service not available", 0)
		end,
	}
end

return CoreWraps