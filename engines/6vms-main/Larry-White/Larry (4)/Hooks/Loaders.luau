local fs = require("@lune/fs")
local luau = require("@lune/luau")
local HTTP = require("../IO/HTTP")

local IdentityUtil = require("../Utils/Identity")

local Loaders = {}
local CompileOptions = {
	optimizationLevel = 2,
	debugLevel = 1,
}
local NativeGetfenv = getfenv
local NativeSetfenv = setfenv
local NativePcall = pcall

function Loaders.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = Loaders })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.Obfuscator = nil
	Self.LockedEnv = nil
	return Self
end

function Loaders:SetObfuscator(Obf)
	self.Obfuscator = Obf
end

function Loaders:SetLockedEnv(Env)
	self.LockedEnv = Env
end

function Loaders:CreateLoader(Name)
	local State = self.State
	local Proxy = self.Proxy
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Emitter = self.Emitter
	local Config = self.Config
	local DefaultWrapperEnv = nil
	if typeof(NativeGetfenv) == "function" then
		DefaultWrapperEnv = NativeGetfenv(1)
	end

	local function SourceLiteral(Source)
		if typeof(Source) ~= "string" or string.find(Source, "\n", 1, true) == nil then
			return Beautifier:Beautify(Source)
		end

		local Equals = ""
		while string.find(Source, "]" .. Equals .. "]", 1, true) ~= nil do
			Equals ..= "="
		end

		local Body = Source
		if string.sub(Body, 1, 1) ~= "\n" and string.sub(Body, 1, 1) ~= "\r" then
			Body = "\n" .. Body
		end
		return "[" .. Equals .. "[" .. Body .. "]" .. Equals .. "]"
	end

	local function BuildChunkWrapper(Func, Value)
		return function(...)
			local CallValue = `{Value}({Beautifier:BeautifyTuple(...)})`
			Emitter:Append(CallValue)

			if typeof(NativeGetfenv) == "function" and typeof(NativeSetfenv) == "function" then
				local TargetEnv = self.LockedEnv
				local Env = NativeGetfenv(1)
				if typeof(Env) == "table" and Env ~= DefaultWrapperEnv then
					TargetEnv = Env
				end
				if typeof(TargetEnv) == "table" then
					NativePcall(NativeSetfenv, Func, TargetEnv)
				end
			end

			local Returned = table.pack(NativePcall(Func, ...))
			if not Returned[1] then
				error(Returned[2], 0)
			end

			if Returned.n > 1 then
				return unpack(Returned, 2, Returned.n)
			end

			return nil
		end
	end

	local function BuildChunkPassthrough(Value)
		return Proxy:CreateFunction(function(...)
			local CallValue = `{Value}({Beautifier:BeautifyTuple(...)})`
			local Var = Scope:AddVar("chunk", "call", CallValue, "__call")
			return Proxy:Spy(Var)
		end, Value)
	end

	local Loader = Proxy:CreateFunction(function(A, B)
		local ActualA = A
		if typeof(A) == "table" then
			local V = rawget(A, "V")
			if typeof(V) == "string" then
				ActualA = V
			end
		end

		local IsString = typeof(ActualA) == "string"
		local ChunkArg = typeof(B) == "string" and B or nil
		local ArgDisplay = IsString and SourceLiteral(ActualA) or Beautifier:Beautify(A)
		local IsHttpGetChunk = false

		local APath = State:IsInternal(A)
		if APath then
			local AEntry = State.Values[APath]
			if AEntry and AEntry.Tag == "__call" and typeof(AEntry.Value) == "string" then
				if string.match(AEntry.Value, "^game:HttpGet%(") then
					ArgDisplay = AEntry.Value
					AEntry.NoEmit = true
					IsHttpGetChunk = true
				end
			end
		end

		if not IsHttpGetChunk and IsString then
			local OriginUrl = HTTP.GetBodyOrigin(ActualA)
			if typeof(OriginUrl) == "string" then
				ArgDisplay = `game:HttpGet({Beautifier:Beautify(OriginUrl)})`
				IsHttpGetChunk = true
			end
		end

		if B ~= nil and ChunkArg == nil then
			local BPath = State:IsInternal(B)
			if BPath then
				local BEntry = State.Values[BPath]
				if BEntry then
					BEntry.NoEmit = true
				end
			end
		end

		local Value
		if ChunkArg then
			Value = `{Name}({ArgDisplay}, {Beautifier:Beautify(ChunkArg)})`
		else
			Value = `{Name}({ArgDisplay})`
		end

		if not IsString or ActualA == "" then
			return BuildChunkPassthrough(Value)
		end

		local MaxChunkSize = tonumber(Config.max_dynamic_chunk_len) or 2000
		if #ActualA > MaxChunkSize then
			return BuildChunkPassthrough(Value)
		end

		local CompileOk, Compiled = pcall(luau.compile, ActualA, CompileOptions)
		if not CompileOk then
			return nil, tostring(Compiled)
		end

		local LoadOk, Func = pcall(luau.load, Compiled, {
			debugName = ChunkArg or "loadstring",
			environment = self.LockedEnv,
		})
		if not LoadOk or not Func then
			return nil, tostring(Func or "failed to load chunk")
		end
		if typeof(setfenv) == "function" and typeof(self.LockedEnv) == "table" then
			pcall(setfenv, Func, self.LockedEnv)
		end

		return BuildChunkWrapper(Func, Value)
	end, Name)

	State:RegisterInternal(Loader, Name)
	return Loader
end

function Loaders:Build()
	return {
		Loadstring = self:CreateLoader("loadstring"),
		Load = self:CreateLoader("load"),
	}
end

return Loaders