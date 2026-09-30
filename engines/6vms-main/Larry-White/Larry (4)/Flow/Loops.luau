local Constants = require("../Data/Constants")

local Loops = {}

function Loops.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = Loops })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	return Self
end

function Loops:While(Condition)
	local State = self.State
	local Config = self.Config
	local Emitter = self.Emitter
	local Scope = self.Scope

	local Path = State:IsInternal(Condition)
	local MaxWhile = Config.max_while_count or Constants.Limits.MaxWhileCount
	State:CheckLoopTimeout(Path or "while")

	if MaxWhile <= State.LoopCount then
		return false
	end

	State:IncrementLoop()

	if Path then
		Scope:AddVar("While", "Condition", `CHECKWHILE({Path})`, "__while")
	end

	return Condition
end

function Loops:BeginWhile(CondStr)
	local Emitter = self.Emitter
	local State = self.State

	Emitter:Append(`while {CondStr} do`)
	State.CurrentIndent += 1
end

function Loops:EndWhile()
	local Emitter = self.Emitter
	local State = self.State

	State.CurrentIndent = math.max(State.CurrentIndent - 1, 0)
	Emitter:Append("end")
end

function Loops:Repeat(Condition)
	local State = self.State
	local Config = self.Config
	local Emitter = self.Emitter

	local Path = State:IsInternal(Condition)
	local MaxWhile = Config.max_while_count or Constants.Limits.MaxWhileCount
	State:CheckLoopTimeout(Path or "repeat")

	if MaxWhile <= State.LoopCount then
		return true
	end

	State:IncrementLoop()

	if Path then
		self.Scope:AddVar("Repeat", "Cond", `{Path}`, "__repeat")
	end

	return Condition
end

function Loops:BeginRepeat()
	local Emitter = self.Emitter
	local State = self.State

	Emitter:Append("repeat")
	State.CurrentIndent += 1
end

function Loops:EndRepeat(CondStr)
	local Emitter = self.Emitter
	local State = self.State

	State.CurrentIndent = math.max(State.CurrentIndent - 1, 0)
	Emitter:Append(`until {CondStr}`)
end

function Loops:ForNumeric(Start, Stop, Step, Body)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Scope = self.Scope
	local Beautifier = self.Beautifier
	local Config = self.Config

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

	local StartVal = StartPath and (rawget(Start, "V") or 1) or Start
	local StopVal = StopPath and (rawget(Stop, "V") or 1) or Stop
	local StepVal = Step and (StepPath and (rawget(Step, "V") or 1) or Step) or 1

	local Executed = false

	if typeof(StartVal) == "number" and typeof(StopVal) == "number" and typeof(StepVal) == "number" then
		if StepVal ~= 0 then
			local Count = 0
			local MaxOps = Config.max_ops or Constants.Limits.MaxOperations

			for I = StartVal, StopVal, StepVal do
				Count += 1
				State:IncrementOps()
				State:CheckOps(MaxOps)

				if Body then
					Body(I, Proxy:Spy(IterVar))
				end
			end

			Executed = true
		end
	end

	State.CurrentIndent = OldIndent
	Emitter:Append("end")

	return Executed
end

function Loops:ForGeneric(IterExpr, Body)
	local State = self.State
	local Emitter = self.Emitter
	local Scope = self.Scope

	local Kv = Scope:GenerateName("k", "iter")
	local Vv = Scope:GenerateName("v", "iter")

	Emitter:Append(`for {Kv}, {Vv} in {IterExpr} do`)

	local OldIndent = State.CurrentIndent
	State.CurrentIndent = OldIndent + 1

	if Body then
		Body(self.Proxy:Spy(Kv), self.Proxy:Spy(Vv))
	end

	State.CurrentIndent = OldIndent
	Emitter:Append("end")
end

return Loops