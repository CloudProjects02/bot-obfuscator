local Logic = {}

local function UnwrapInternal(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

function Logic.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = Logic })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.Loadstring = nil
	return Self
end

function Logic:SetLoadstring(Loader)
	self.Loadstring = Loader
end

function Logic:CHECKOR(A, B)
	local State = self.State
	local Proxy = self.Proxy
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Config = self.Config

	local PathA = State:IsInternal(A)
	local PathB = State:IsInternal(B)

	if PathA or PathB then
		local V1, V2

		if PathA then
			if PathA == "loadstring" and self.Loadstring then return self.Loadstring end
			V1 = UnwrapInternal(A)
		end

		if PathB then
			if PathB == "loadstring" and self.Loadstring then return V1 or self.Loadstring end
			V2 = UnwrapInternal(B)
		end

		if V1 == nil then V1 = A end
		if V2 == nil then V2 = B end

		if tostring(V1 or V2) == "getfenv()" then
			return rawget(State.Spied["getfenv()"] or {}, "V") or V1 or V2
		end

		local Left = PathA or Beautifier:Beautify(A)
		local Right = PathB or Beautifier:Beautify(B)

		local Value = `({Left} or {Right})`
		local Var = Scope:AddVar("comp", "Or", Value, "__comp")

		local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.OR or Config.hookOpValue
		if OpMode == "spy" then
			local Result = Proxy:Spy(Var)
			rawset(Result, "V", V1 or V2)
			return Result
		end

		return V1 or V2
	end

	return A or B
end

function Logic:CHECKAND(A, B)
	local State = self.State
	local Proxy = self.Proxy
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Config = self.Config

	local PathA = State:IsInternal(A)
	local PathB = State:IsInternal(B)

	if PathA or PathB then
		local V1, V2

		if PathA then State:Use(PathA, "__comp", true); V1 = UnwrapInternal(A) end
		if PathB then State:Use(PathB, "__comp", true); V2 = UnwrapInternal(B) end

		if V1 == nil then V1 = A end
		if V2 == nil then V2 = B end

		local Left = PathA or Beautifier:Beautify(A)
		local Right = PathB or Beautifier:Beautify(B)

		local Value = `{Left} and {Right}`
		local Var = Scope:AddVar("Comp", "And", Value, "__comp")

		local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.AND or Config.hookOpValue
		if OpMode == "spy" then
			local Result = Proxy:Spy(Var)
			rawset(Result, "V", V1 and V2)
			return Result
		end

		return V1 and V2
	end

	return A and B
end

function Logic:CHECKNOT(A)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Config = self.Config

	local Path = State:IsInternal(A)

	if Path then
		if Path == "getconstants" then return true end
		if Path == "loadstring" then return false end

		local V = UnwrapInternal(A)
		if V == nil then
			V = A
		end

		local Var = State:NextId()
		local Value = `not {Path}`

		Emitter:Append(`local {Var} = {Value};`)
		State:Define(Var, Value, "__comp")

		local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.NOT or Config.hookOpValue
		if OpMode == "spy" then
			local Result = Proxy:Spy(Var)
			rawset(Result, "V", not V)
			return Result
		end

		return not V
	end

	return not A
end

function Logic:CHECKLEN(A)
	local State = self.State
	local Proxy = self.Proxy
	local Scope = self.Scope
	local Emitter = self.Emitter
	local Config = self.Config

	local Path = State:IsInternal(A)
	local V = UnwrapInternal(A)
	local Len

	if Path then
		State:Use(Path, "__len", true)
		if V == nil then V = A end
		local Ok, Res = pcall(function()
			return #V
		end)
		if Ok then
			Len = Res
		else
			error(Res, 0)
		end

		local Var = Scope:AddVar("Len", "len", `#{Path}`, "__len")

		local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.LEN or Config.hookOpValue
		if OpMode == "spy" then
			local Result = Proxy:Spy(Var)
			rawset(Result, "V", Len)
			return Result
		else
			return Len
		end
	end

	local Ok, Res = pcall(function()
		return #A
	end)
	if not Ok then
		error(Res, 0)
	end
	Len = Res

	return Len
end

function Logic:Build()
	return {
		CHECKOR = function(A, B) return self:CHECKOR(A, B) end,
		CHECKAND = function(A, B) return self:CHECKAND(A, B) end,
		CHECKNOT = function(A) return self:CHECKNOT(A) end,
		CHECKLEN = function(A) return self:CHECKLEN(A) end,
	}
end

return Logic