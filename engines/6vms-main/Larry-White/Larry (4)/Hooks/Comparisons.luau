local Comparisons = {}

function Comparisons.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = Comparisons })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function Comparisons:FastComp(Symbol)
	local State = self.State
	local Proxy = self.Proxy
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Emitter = self.Emitter

	local function SafeCompare(LeftVal, RightVal)
		local Ok, Result = pcall(function()
			if Symbol == "<" then
				return LeftVal < RightVal
			elseif Symbol == ">" then
				return LeftVal > RightVal
			elseif Symbol == "<=" then
				return LeftVal <= RightVal
			elseif Symbol == ">=" then
				return LeftVal >= RightVal
			end
			return false
		end)

		if Ok then
			return Result
		end

		error(Result, 0)
	end

	return function(A, B)
		local PathA = State:IsInternal(A)
		local PathB = State:IsInternal(B)

		local V1, V2 = A, B
		local function Unwrap(Value)
			if typeof(Value) == "table" then
				local Raw = rawget(Value, "V")
				if Raw ~= nil then
					return Raw
				end
			end
			return Value
		end

		if PathA or PathB then
			if PathA then State:Use(PathA, "__comp", true); V1 = Unwrap(A) end
			if PathB then State:Use(PathB, "__comp", true); V2 = Unwrap(B) end

			local Left = PathA or Beautifier:Beautify(A)
			local Right = PathB or Beautifier:Beautify(B)

			local Value = `{Left} {Symbol} {Right}`
			local Var = Scope:AddVar("Comp", Symbol, Value, "__comp")

			local OpMode = typeof(self.Config.hookOpValue) == "table" and self.Config.hookOpValue.COMP or self.Config.hookOpValue

			local Computed
			if V1 ~= nil and V2 ~= nil then
				Computed = SafeCompare(V1, V2)
			end

			if OpMode == "spy" then
				local Result = Proxy:Spy(Var)
				if Computed ~= nil then
					rawset(Result, "V", Computed)
				end
				return Result
			end

			return Computed
		end

		return SafeCompare(V1, V2)
	end
end

function Comparisons:Build()
	return {
		COMPL = self:FastComp("<"),
		COMPG = self:FastComp(">"),
		COMPLE = self:FastComp("<="),
		COMPGE = self:FastComp(">="),
	}
end

return Comparisons