local ExpressionHooks = {}

function ExpressionHooks.new(State, Config)
	local Self = setmetatable({}, { __index = ExpressionHooks })
	Self.State = State
	Self.Config = Config
	Self.EqHooks = {}
	Self.ExprHooks = {}
	Self.PreventedPcalls = {}
	Self.ForcedPcalls = {}
	return Self
end

function ExpressionHooks:HookExpr(Id, Value)
	if typeof(Id) ~= "number" then
		error("invalid argument #1 to 'hookexpr' (number expected)")
	end

	self.ExprHooks[Id] = Value
	self.State.ExpressionHooks[Id] = Value
end

function ExpressionHooks:HookEq(Id, Value)
	if typeof(Id) ~= "number" then
		error("invalid argument #1 to 'hookeq' (number expected)")
	end

	self.EqHooks[Id] = Value
	self.State.ExpressionHooks[Id] = Value
end

function ExpressionHooks:GetExprHook(Id)
	return self.ExprHooks[Id]
end

function ExpressionHooks:GetEqHook(Id)
	return self.EqHooks[Id]
end

function ExpressionHooks:PreventError(PcallId)
	if typeof(PcallId) ~= "number" then
		error("invalid argument #1 to 'preventerror' (number expected)")
	end

	self.PreventedPcalls[PcallId] = true
end

function ExpressionHooks:ForceError(PcallId, Message)
	if typeof(PcallId) ~= "number" then
		error("invalid argument #1 to 'forceerror' (number expected)")
	end

	self.ForcedPcalls[PcallId] = Message or "forced error"
end

function ExpressionHooks:IsPrevented(PcallId)
	return self.PreventedPcalls[PcallId] == true
end

function ExpressionHooks:GetForcedError(PcallId)
	return self.ForcedPcalls[PcallId]
end

function ExpressionHooks:CreateHandlers(MacroSystem, PcallHandler)
	MacroSystem:Register("hookexpr", function(Id, Val)
		self:HookExpr(Id, Val)
	end)

	MacroSystem:BlockInPcall("hookexpr")

	MacroSystem:Register("hookeq", function(Id, Val)
		self:HookEq(Id, Val)
	end)

	MacroSystem:BlockInPcall("hookeq")

	MacroSystem:Register("preventerror", function(PcallId)
		self:PreventError(PcallId)
		if PcallHandler then
			PcallHandler:PreventError(PcallId)
		end
	end)

	MacroSystem:Register("forceerror", function(PcallId, Message)
		self:ForceError(PcallId, Message)
		if PcallHandler then
			PcallHandler:ForceError(PcallId, Message)
		end
	end)
end

function ExpressionHooks:Clear()
	table.clear(self.ExprHooks)
	table.clear(self.EqHooks)
	table.clear(self.PreventedPcalls)
	table.clear(self.ForcedPcalls)
end

return ExpressionHooks