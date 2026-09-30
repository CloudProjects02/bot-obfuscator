local Constants = require("../Data/Constants")

local IfChecks = {}

function IfChecks.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = IfChecks })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.OpenEnds = 0
	return Self
end

function IfChecks:Check(Condition)
	local State = self.State
	local Emitter = self.Emitter
	local Config = self.Config

	local Path = State:IsInternal(Condition)

	if not Path then
		return Condition
	end

	State.Top.add_if_comment = true

	local V = rawget(Condition, "V")

	local ExprId = State:NextExpressionId()
	local Hook = State.ExpressionHooks[ExprId]
	local HookExists = Hook ~= nil

	if HookExists and Hook ~= "nil" and Hook ~= "spy" then
		V = Hook
	else
		HookExists = false
	end

		if not Config.neverNester then
			Emitter:Append(`if {Path} then end`)
			Emitter:Append("")
		end

	if V == nil then return Condition end
	return V
end

function IfChecks:BeginIf(Condition, Body)
	local State = self.State
	local Emitter = self.Emitter

	local Path = State:IsInternal(Condition)
	local CondStr = Path or self.Beautifier:Beautify(Condition)

	local V = Path and rawget(Condition, "V") or Condition

	Emitter:Append(`if {CondStr} then`)

	local OldIndent = State.CurrentIndent
	State.CurrentIndent = OldIndent + 1
	self.OpenEnds += 1

	if Body then
		Body(V)
	end

	return V
end

function IfChecks:ElseIf(Condition, Body)
	local State = self.State
	local Emitter = self.Emitter

	local Path = State:IsInternal(Condition)
	local CondStr = Path or self.Beautifier:Beautify(Condition)

	State.CurrentIndent = math.max(State.CurrentIndent - 1, 0)
	Emitter:Append(`elseif {CondStr} then`)
	State.CurrentIndent += 1

	local V = Path and rawget(Condition, "V") or Condition

	if Body then
		Body(V)
	end

	return V
end

function IfChecks:Else(Body)
	local State = self.State
	local Emitter = self.Emitter

	State.CurrentIndent = math.max(State.CurrentIndent - 1, 0)
	Emitter:Append("else")
	State.CurrentIndent += 1

	if Body then
		Body()
	end
end

function IfChecks:EndIf()
	local State = self.State
	local Emitter = self.Emitter

	if self.OpenEnds > 0 then
		State.CurrentIndent = math.max(State.CurrentIndent - 1, 0)
		Emitter:Append("end")
		self.OpenEnds -= 1
	end
end

function IfChecks:CloseAll()
	while self.OpenEnds > 0 do
		self:EndIf()
	end
end

function IfChecks:IsPrometheusJunk(CondStr)
	if not CondStr then return false end

	local Patterns = {
		"^while%s+game%s+do$",
		"^while%s+true%s+do$",
		"^if%s+getfenv%s+and%s+%d+",
	}

	for _, Pattern in Patterns do
		if string.match(CondStr, Pattern) then
			return true
		end
	end

	return false
end

return IfChecks