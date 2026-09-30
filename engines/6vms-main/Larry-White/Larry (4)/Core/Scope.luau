local StringUtil = require("../Utils/String")

local Scope = {}
Scope.__index = Scope

function Scope.new(State, Emitter)
	local Self = setmetatable({}, Scope)
	Self.State = State
	Self.Emitter = Emitter
	return Self
end

local NameHints = require("../Data/NameHints")

function Scope:GenerateName(Base, Method)
	local State = self.State

	while true do
		local Entry = State.Values[Base]
		if not Entry or not Entry.Value then break end
		Base = Entry.Value
	end

	local Cleaned = string.gsub(Method, "%A", "")
	local Hint = NameHints.Properties[Cleaned] or NameHints.Methods[Cleaned]

	if Hint then
		Cleaned = Hint
	elseif Cleaned == "" then
		Cleaned = "unnamedvar"
	else
		Cleaned = string.lower(string.sub(Cleaned, 1, 1)) .. string.sub(Cleaned, 2)
	end

	if Base == "GetService" or Cleaned == "GetService" then
		return Cleaned .. State.Id
	end

	if Cleaned == "iter" then
		return Base .. State.Id
	end

	return Cleaned .. State:GetVarCounter(Cleaned)
end

function Scope:AddVar(Name1, Name2, Value, Tag)
	local Var = self:GenerateName(Name1, Name2)
	self.Emitter:Append(`local {Var} = {Value}`)
	self.State:Define(Var, Value, Tag)
	return Var
end

function Scope:HoistVariable(Var, InitialValue)
	local State = self.State
	local ExistingLine = nil

	for I = #State.Output, 1, -1 do
		local Line = State.Output[I]
		if Line and string.match(Line, `^%s*local%s+{Var}%s*=`) then
			ExistingLine = I
			break
		end
	end

	if ExistingLine then
		local Line = State.Output[ExistingLine]
		local Assignment = string.match(Line, `^(%s*)local%s+{Var}%s*=%s*(.+)$`)

		if Assignment then
			local Indent = string.match(Line, "^(%s*)") or ""
			State.Output[ExistingLine] = `{Indent}{Var} = {Assignment}`

			local Declaration = `local {Var} = {InitialValue or "nil"}`
			table.insert(State.Output, 1, Declaration)
		end
	end
end

function Scope:ExtractFromBlock(BlockStartLine, Var)
	local State = self.State

	for I = BlockStartLine, #State.Output do
		local Line = State.Output[I]
		if Line and string.match(Line, `^%s*local%s+{Var}%s*=`) then
			self:HoistVariable(Var)
			return true
		end
	end

	return false
end

function Scope:FixScopes(BlockStartLine, BlockEndLine)
	local State = self.State
	local Hoisted = {}

	for I = BlockStartLine, math.min(BlockEndLine, #State.Output) do
		local Line = State.Output[I]
		if not Line then continue end

		local Var = string.match(Line, "^%s*local%s+([%w_]+)%s*=")
		if not Var then continue end

		for J = BlockEndLine + 1, #State.Output do
			local Later = State.Output[J]
			if Later and string.find(Later, Var, 1, true) then
				if not Hoisted[Var] then
					self:HoistVariable(Var)
					Hoisted[Var] = true
				end
				break
			end
		end
	end
end

return Scope