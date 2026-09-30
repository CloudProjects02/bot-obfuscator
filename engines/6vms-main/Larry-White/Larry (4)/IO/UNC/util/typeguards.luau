local TypeGuards = {}

function TypeGuards.GetCallerEnv()
	local BestEnv = nil
	local BestScore = -1

	for Level = 1, 24 do
		local Ok, Candidate = pcall(getfenv, Level)
		if Ok and typeof(Candidate) == "table" then
			local Score = 0
			if rawget(Candidate, "game") ~= nil then
				Score += 4
			end
			if rawget(Candidate, "workspace") ~= nil then
				Score += 2
			end
			if rawget(Candidate, "task") ~= nil then
				Score += 1
			end
			if rawget(Candidate, "_G") ~= nil then
				Score += 1
			end

			if Score > BestScore then
				BestScore = Score
				BestEnv = Candidate
			end
		end
	end

	if BestEnv ~= nil then
		return BestEnv
	end

	local Ok0, Env0 = pcall(getfenv)
	if Ok0 and typeof(Env0) == "table" then
		return Env0
	end

	return {}
end

function TypeGuards.NormalizePropName(Prop)
	if typeof(Prop) ~= "string" then
		return ""
	end
	return string.lower(Prop)
end

function TypeGuards.IsDefaultScriptable(Object, Prop)
	local PropKey = TypeGuards.NormalizePropName(Prop)
	if PropKey == "size_xml" then
		return false
	end
	return true
end

function TypeGuards.GetScriptableMap(Ctx, Object)
	local Map = Ctx.scriptable_props[Object]
	if Map == nil then
		Map = {}
		Ctx.scriptable_props[Object] = Map
	end
	return Map
end

function TypeGuards.GetHiddenMap(Ctx, Object)
	local Map = Ctx.hidden_props[Object]
	if Map == nil then
		Map = {}
		Ctx.hidden_props[Object] = Map
	end
	return Map
end

function TypeGuards.SafeVector2(X, Y)
	local Lib = getfenv().Vector2
	if typeof(Lib) == "table" and typeof(Lib.new) == "function" then
		local Ok, Result = pcall(Lib.new, X, Y)
		if Ok then
			return Result
		end
	end
	return { X = X, Y = Y }
end

function TypeGuards.SafeColor3(R, G, B)
	local Lib = getfenv().Color3
	if typeof(Lib) == "table" then
		if typeof(Lib.fromRGB) == "function" then
			local Ok, Result = pcall(Lib.fromRGB, R, G, B)
			if Ok then
				return Result
			end
		end
		if typeof(Lib.new) == "function" then
			local Ok, Result = pcall(Lib.new, R / 255, G / 255, B / 255)
			if Ok then
				return Result
			end
		end
	end
	return { R = R / 255, G = G / 255, B = B / 255 }
end

function TypeGuards.SpyReturn(Proxy, Scope, Beautifier, FuncName, ...)
	local Value = `{FuncName}({Beautifier:BeautifyTuple(...)})`
	local Var = Scope:AddVar(FuncName, "unc", Value, "__call")
	return Proxy:Spy(Var)
end

function TypeGuards.SafeRequireInstance()
	local ok, mod = pcall(require, "../../../Roblox/Instance")
	if ok and mod and mod._new then
		return mod
	end
	return nil
end

function TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, className)
	local mod = TypeGuards.SafeRequireInstance()
	if mod then
		return mod._new(className, {}, Proxy, State, Emitter, Beautifier, Scope, true)
	end
	return nil
end

function TypeGuards.MakeHexDigest(Input, Length)
	local HexChars = "0123456789abcdef"
	local Str = tostring(Input or "")
	if #Str == 0 then
		Str = "larry"
	end
	local StateHash = 2166136261
	local Out = table.create(Length)
	for i = 1, Length do
		local Byte = string.byte(Str, ((i - 1) % #Str) + 1)
		StateHash = bit32.bxor(StateHash, Byte + i)
		StateHash = (StateHash * 16777619) % 4294967296
		local Nibble = bit32.band(bit32.rshift(StateHash, (i % 8) * 4), 0xF)
		Out[i] = string.sub(HexChars, Nibble + 1, Nibble + 1)
	end
	return table.concat(Out)
end

return TypeGuards