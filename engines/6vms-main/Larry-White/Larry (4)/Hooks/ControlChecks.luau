local ControlChecks = {}

local function UnwrapInternal(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

function ControlChecks.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = ControlChecks })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function ControlChecks:CHECKIF(Condition)
	local State = self.State
	local Emitter = self.Emitter
	local Config = self.Config

	local Path = State:IsInternal(Condition)

	if Path then
		State.Top.add_if_comment = true

		local V = UnwrapInternal(Condition)

		local ExprId = State:NextExpressionId()
		local Hook = State.ExpressionHooks[ExprId]
		local HookExists = Hook ~= nil

		if HookExists then
			if Hook ~= "nil" and Hook ~= "spy" then
				V = Hook
			end
		end

		local OpMode = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.IF or Config.hookOpValue

		if not Config.neverNester then
			Emitter:Append(`if {Path} then end`)
			Emitter:Append("")
		end

		if OpMode == "spy" then
			if V == nil then return Condition end
			return V
		end

		return V == nil and Condition or V

	end

	return Condition
end

function ControlChecks:CHECKWHILE(Condition)
	local State = self.State
	local Config = self.Config
	local Emitter = self.Emitter

	local Path = State:IsInternal(Condition)
	local MaxWhile = Config.max_while_count or 100000
	State:CheckLoopTimeout(Path or "while")

	if MaxWhile <= State.LoopCount then
		return false
	end

	State:IncrementLoop()

	if Path then
		self.Scope:AddVar("While", "Condition", `CHECKWHILE({Path})`, "__while")
	end

	return Condition
end

function ControlChecks:CHECKINDEX(Tbl, Key)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope

	if not self.Config.CHECKINDEX then
		return nil
	end

	local TblPath = State:IsInternal(Tbl)

	if not TblPath then return nil end

	local Entry = State.Values[TblPath]

	if not Entry or (Entry.Tag ~= "__call" and Entry.Tag ~= "__index") then
		local TblVar = State:NextId()
		Emitter:Append(`local {TblVar} = \{\}`)
		State:Define(TblVar, "{}", "__table")
	end

	local KeyStr = State:IsInternal(Key) or Beautifier:Beautify(Key)
	local Value = `{TblPath}[{KeyStr}]`
	local Var = Scope:AddVar("idx", "check", Value, "__index")

	return Proxy:Spy(Var)
end

function ControlChecks:ForNumeric(Start, Stop, Step, Body)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Scope = self.Scope

	local StartPath = State:IsInternal(Start)
	local StopPath = State:IsInternal(Stop)
	local StepPath = Step and State:IsInternal(Step)

	local StartStr = StartPath or tostring(Start)
	local StopStr = StopPath or tostring(Stop)
	local StepStr = Step and (StepPath or tostring(Step)) or nil

	local IterVar = Scope:GenerateName("i", "for")

	local Header
	if StepStr then
		Header = `for {IterVar} = {StartStr}, {StopStr}, {StepStr} do`
	else
		Header = `for {IterVar} = {StartStr}, {StopStr} do`
	end

	Emitter:Append(Header)

	local OldIndent = State.CurrentIndent
	State.CurrentIndent = OldIndent + 1

	local StartVal = StartPath and (UnwrapInternal(Start) or 1) or Start
	local StopVal = StopPath and (UnwrapInternal(Stop) or 1) or Stop
	local StepVal = Step and (StepPath and (UnwrapInternal(Step) or 1) or Step) or 1

	if typeof(StartVal) == "number" and typeof(StopVal) == "number" and typeof(StepVal) == "number" then
		if StepVal > 0 then
			for I = StartVal, StopVal, StepVal do
				Body(I)
			end
		elseif StepVal < 0 then
			for I = StartVal, StopVal, StepVal do
				Body(I)
			end
		end
	end

	State.CurrentIndent = OldIndent
	Emitter:Append("end")
end

function ControlChecks:RepeatHook(Condition)
	local State = self.State
	local Config = self.Config
	local Emitter = self.Emitter

	local Path = State:IsInternal(Condition)
	local MaxWhile = Config.max_while_count or 100000
	State:CheckLoopTimeout(Path or "repeat")

	if MaxWhile <= State.LoopCount then
		return true
	end

	State:IncrementLoop()

	if Path then
		self.Scope:AddVar("Repeat", "Condition", `{Path}`, "__repeat")
	end

	return Condition
end

function ControlChecks:Build()
	return {
		CHECKIF = function(C) return self:CHECKIF(C) end,
		CHECKWHILE = function(C) return self:CHECKWHILE(C) end,
		CHECKINDEX = function(T, K) return self:CHECKINDEX(T, K) end,
	}
end

return ControlChecks