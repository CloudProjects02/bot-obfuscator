local Equality = {}

function Equality.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = Equality })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function Equality:FastEq(Symbol)
	local State = self.State
	local Proxy = self.Proxy
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Emitter = self.Emitter
	local Config = self.Config

	return function(A, B)
		local PathA = State:IsInternal(A)
		local PathB = State:IsInternal(B)
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
			local V1, V2

			if PathA then State:Use(PathA, "__comp", true); V1 = Unwrap(A) end
			if PathB then State:Use(PathB, "__comp", true); V2 = Unwrap(B) end

			if V1 == nil then V1 = A end
			if V2 == nil then V2 = B end

			local ExprId = State:NextExpressionId()
			local Hook = State.ExpressionHooks[ExprId]
			local HookExists = Hook ~= nil

			local ValueOut

			if HookExists and Hook ~= "nil" and Hook ~= "spy" then
				ValueOut = Hook
			else
				HookExists = false
			end

			local Eq

			if Symbol == "~=" then
				Eq = V1 ~= V2
			else
				Eq = V1 == V2
			end

			if ValueOut ~= nil then
				Eq = ValueOut
			end

			local Left = PathA or Beautifier:Beautify(A)
			local Right = PathB or Beautifier:Beautify(B)

			local Value = `{Left} {Symbol} {Right}`
			local Var = Scope:AddVar("Equal", "", Value, "__eq")

			if HookExists then return Eq end

			local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.EQ or Config.hookOpValue

			if Symbol == "~=" then
				OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.NEQ or Config.hookOpValue
			end

			if OpMode == "spy" then
				local Result = Proxy:Spy(Var)
				rawset(Result, "V", Eq)
				return Result
			end

			return Eq
		end

		if Symbol == "~=" then return A ~= B end
		return A == B
	end
end

function Equality:HookEq(Id, Val)
	self.State.ExpressionHooks[Id] = Val
end

function Equality:Build()
	return {
		__EQ = self:FastEq("=="),
		__NEQ = self:FastEq("~="),
	}
end

return Equality