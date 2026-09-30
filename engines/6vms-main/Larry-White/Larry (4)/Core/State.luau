local Identity = require("../Utils/Identity")

local State = {}
State.__index = State

function State.new()
	local Self = setmetatable({}, State)

	Self.Output = {}
	Self.Values = {}
	Self.Internal = {}
	Self.Addresses = {}
	Self.Spied = {}
	Self.ParamsUsed = {}
	Self.EnvValues = {}
	Self.NextCalls = {}
	Self.ExpressionHooks = {}

	Self.Id = 0
	Self.ExpressionId = 0
	Self.OpCount = 0
	Self.LoopCount = 0
	Self.NestCount = 0
	Self.CurrentIndent = 0

	Self.Top = {
		add_if_comment = false,
	}

	Self.Replace = {}
	Self.VarCounters = {}
	Self.CachedSafe = {}
	Self.ExploringFunction = false
	Self.ExecutionStartedAt = nil
	Self.ExecutionDeadline = nil
	Self.LoopTimeoutSeconds = nil
	Self.LoopTimers = {}
	Self.AstReconstruction = nil
	Self.StageTimings = {}

	return Self
end

function State:Child()
	local Child = State.new()

	Child.Internal = self.Internal
	Child.Addresses = self.Addresses
	Child.NestCount = self.NestCount + 1
	Child.ExpressionHooks = self.ExpressionHooks

	return Child
end

function State:ParamSuffix()
	if self.NestCount == 0 then
		return ""
	end
	return `_{self.NestCount}`
end

function State:NextId()
	self.Id += 1
	return `var{self.Id}{self:ParamSuffix()}`
end

function State:NextExpressionId()
	local Current = self.ExpressionId
	self.ExpressionId += 1
	return Current
end

function State:IncrementOps()
	self:CheckTimeout("operation")
	self.OpCount += 1
end

function State:CheckOps(Max)
	self:CheckTimeout("operation")
	if self.OpCount >= Max then
		error("Too many operations.", 2)
	end
end

function State:IncrementLoop()
	self.LoopCount += 1
end

function State:GetVarCounter(Idx)
	local Value = self.VarCounters[Idx] or 1
	self.VarCounters[Idx] = Value + 1
	return Value == 1 and "" or Value
end

function State:Define(Var, Value, Tag)
	self.Values[Var] = {
		Value = Value,
		Tag = Tag,
		Line = #self.Output,
		Usage = 0,
	}
end

function State:Use(Var, Tag, Increment, Val)
	local Entry = self.Values[Var]
	if not Entry then
		return self:Define(Var, Val, Tag)
	end
	if Entry.Usage == 0 or Increment then
		Entry.Usage = (Increment and Entry.Usage or 0) + 1
	end
end

function State:GetValue(Var)
	return self.Values[Var]
end

function State:IsInternal(Object)
	local Path = self.Internal[Object]
	if Path then
		if typeof(Object) == "table" and rawget(Object, "ISP") then
			self.ParamsUsed[Path] = true
		end
		self:Use(Path, "__tostring")
	end
	return Path
end

function State:CheckOutputLimit(Max)
	Max = Max or 5000
	if #self.Output >= Max then
		error("Too many operations.", 0)
	end
end

function State:RegisterInternal(Object, Path)
	self.Internal[Object] = Path
end

function State:ConfigureRuntime(Config)
	self.ExecutionStartedAt = os.clock()

	local TimeoutMs = tonumber(Config.execution_timeout_ms)
	if TimeoutMs ~= nil and TimeoutMs > 0 then
		self.ExecutionDeadline = self.ExecutionStartedAt + (TimeoutMs / 1000)
	else
		self.ExecutionDeadline = nil
	end

	local LoopTimeoutMs = tonumber(Config.loop_timeout_ms)
	if LoopTimeoutMs ~= nil and LoopTimeoutMs > 0 then
		self.LoopTimeoutSeconds = LoopTimeoutMs / 1000
	else
		self.LoopTimeoutSeconds = nil
	end

	table.clear(self.LoopTimers)
end

function State:CheckTimeout(Context)
	if self.ExecutionDeadline ~= nil and os.clock() >= self.ExecutionDeadline then
		if typeof(Context) == "string" and Context ~= "" then
			error(`Execution timed out ({Context})`, 0)
		end

		error("Execution timed out", 0)
	end
end

function State:CheckLoopTimeout(Context)
	if self.LoopTimeoutSeconds == nil or self.LoopTimeoutSeconds <= 0 then
		return
	end

	local Key = (typeof(Context) == "string" and Context ~= "") and Context or "__loop__"
	local Now = os.clock()
	local Entry = self.LoopTimers[Key]

	if Entry == nil or (Now - Entry.LastSeen) > 0.25 then
		self.LoopTimers[Key] = {
			StartedAt = Now,
			LastSeen = Now,
		}
		return
	end

	Entry.LastSeen = Now
	if (Now - Entry.StartedAt) >= self.LoopTimeoutSeconds then
		error(`Loop timed out ({Key})`, 0)
	end
end

function State:GetSafe(Val)
	local Cached = self.CachedSafe[Val]
	if Cached then return Cached end

	local StringUtil = require("../Utils/String")
	local Safe = StringUtil.PatternSafe(Val)
	self.CachedSafe[Val] = Safe
	return Safe
end

function State:ClearOutput()
	table.clear(self.Output)
end

function State:OutputLine(Index)
	return self.Output[Index]
end

function State:SetOutputLine(Index, Value)
	self.Output[Index] = Value
end

function State:RemoveOutputLine(Index)
	if Index and Index >= 1 and Index <= #self.Output then
		self.Output[Index] = nil
	end
end

return State