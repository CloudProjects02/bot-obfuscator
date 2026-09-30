local Constants = require("../Data/Constants")
local StringUtil = require("../Utils/String")
local RuntimeClock = require("../Roblox/RuntimeClock")

local TaskLib = {}

function TaskLib.Build(Proxy, State, Emitter, Beautifier, Scope, Config, LockedEnv, Pristine)
	local TaskCount = 0
	local MaxTasks = math.max(Constants.Limits.MaxTasks or 5, 4096)
	local MaxFlushResumes = math.max(256, math.floor(MaxTasks * 0.5))
	local MaxOps = Config.max_ops or Constants.Limits.MaxOperations
	local DeferredQueue = {}
	local ZeroDelayQueue = {}
	local DelayedQueue = {}
	local MainThread = coroutine.running()

	local LuneTask = nil
	pcall(function()
		LuneTask = require("@lune/task")
	end)

	local function WrapCallback(Func)
		if typeof(Func) ~= "function" then return Func end

		if LockedEnv then
			Func = setfenv(Func, LockedEnv)
		end

		return Func
	end

	local function SpyCall(Method, ...)
		local Args = table.pack(...)
		local Parts = {}
		local IsAsyncMethod = Method == "spawn" or Method == "defer" or Method == "delay"

		for I = 1, Args.n do
			local Arg = Args[I]
			Parts[I] = Beautifier:Beautify(Arg, State.CurrentIndent + 1)
		end

		local Value = `{StringUtil.Index(Method, "task")}({table.concat(Parts, ", ")})`
		local Var = Scope:GenerateName("scheduled", Method)
		return Proxy:MultiSpy(Var, Value, 2)
	end

	local function HasInternalArg(...)
		local Args = table.pack(...)
		for I = 1, Args.n do
			if State:IsInternal(Args[I]) then
				return true
			end
		end
		return false
	end

	local function FireRunServiceStep(Delta)
		local Services = require("../Roblox/Services")
		local RunService = Services.GetOrNil("RunService")
		if not RunService or typeof(RunService.GetProperty) ~= "function" then
			return
		end

		local Step = tonumber(Delta)
		if Step == nil or Step <= 0 then
			Step = 1 / 60
		end
		RuntimeClock.Advance(Step)

		local Heartbeat = RunService:GetProperty("Heartbeat")
		if typeof(Heartbeat) == "table" and typeof(Heartbeat.Fire) == "function" then
			pcall(Heartbeat.Fire, Heartbeat, Step)
		end

		local Stepped = RunService:GetProperty("Stepped")
		if typeof(Stepped) == "table" and typeof(Stepped.Fire) == "function" then
			pcall(Stepped.Fire, Stepped, RuntimeClock.GetServerNow(), Step)
		end

		local RenderStepped = RunService:GetProperty("RenderStepped")
		if typeof(RenderStepped) == "table" and typeof(RenderStepped.Fire) == "function" then
			local RenderStep = Step + 1e-6
			pcall(RenderStepped.Fire, RenderStepped, RenderStep)
		end
	end

	local function MakeVector3(X, Y, Z)
		local DataTypes = require("../Roblox/DataTypes")
		local Vector3 = DataTypes.Get("Vector3")
		if typeof(Vector3) == "table" and typeof(Vector3.new) == "function" then
			local Ok, Value = pcall(Vector3.new, X, Y, Z)
			if Ok and Value ~= nil then
				return Value
			end
		end
		return {
			X = X,
			Y = Y,
			Z = Z,
		}
	end

	local function IsInstanceLike(Value)
		local Kind = typeof(Value)
		return Kind == "table" or Kind == "Instance"
	end

	local function ReadVector3(Value)
		if typeof(Value) == "Vector3" then
			return Value.X, Value.Y, Value.Z
		end
		if typeof(Value) == "table" then
			while typeof(Value) == "table" do
				local Raw = rawget(Value, "V")
				if Raw == nil or Raw == Value then
					break
				end
				Value = Raw
			end
			local X = rawget(Value, "X")
			local Y = rawget(Value, "Y")
			local Z = rawget(Value, "Z")
			if typeof(X) == "number" and typeof(Y) == "number" and typeof(Z) == "number" then
				return X, Y, Z
			end
		end
		return 0, 0, 0
	end

	local function GetPropertySafe(Inst, Name)
		if not IsInstanceLike(Inst) then
			return nil
		end
		if typeof(Inst.GetRawProperty) == "function" then
			local Ok, Value = pcall(Inst.GetRawProperty, Inst, Name)
			if Ok and Value ~= nil then
				return Value
			end
		end
		if typeof(Inst.GetProperty) == "function" then
			local Ok, Value = pcall(Inst.GetProperty, Inst, Name)
			if Ok then
				return Value
			end
		end
		return nil
	end

	local function WriteVector3Value(Existing, X, Y, Z)
		return MakeVector3(X, Y, Z)
	end

	local function AdvancePhysics(Delta)
		if typeof(Delta) ~= "number" or Delta <= 0 then
			return
		end

		local Services = require("../Roblox/Services")
		local Workspace = nil
		if typeof(LockedEnv) == "table" then
			Workspace = rawget(LockedEnv, "workspace") or rawget(LockedEnv, "Workspace")
		end
		if Workspace == nil then
			Workspace = Services.GetOrNil("Workspace")
		end
		local Gravity = 196.2

		if Workspace and typeof(Workspace.GetProperty) == "function" then
			local WorkspaceGravity = GetPropertySafe(Workspace, "Gravity")
			if typeof(WorkspaceGravity) == "number" then
				Gravity = WorkspaceGravity
			end
		end

		local Candidates = {}
		local SeenCandidates = setmetatable({}, { __mode = "k" })
		local function AddCandidate(Inst)
			if not IsInstanceLike(Inst) or SeenCandidates[Inst] then
				return false
			end
			SeenCandidates[Inst] = true
			Candidates[#Candidates + 1] = Inst
			return true
		end
		local InstanceModel = require("../Roblox/Instance")
		if typeof(InstanceModel.GetCreated) == "function" then
			local Ok, Created = pcall(InstanceModel.GetCreated)
			if Ok and typeof(Created) == "table" then
				for _, Inst in next, Created do
					AddCandidate(Inst)
				end
			end
		end
		if #Candidates == 0 and Workspace and typeof(Workspace.GetDescendants) == "function" then
			for _, Inst in next, Workspace:GetDescendants() do
				AddCandidate(Inst)
			end
		end

		for _, Inst in next, Candidates do
			local ClassName = nil
			local RawProps = IsInstanceLike(Inst) and rawget(Inst, "_Properties") or nil
			if IsInstanceLike(Inst) then
				ClassName = rawget(Inst, "_ClassName")
				if ClassName == nil and typeof(Inst.GetClassName) == "function" then
					local Ok, Resolved = pcall(Inst.GetClassName, Inst)
					if Ok and typeof(Resolved) == "string" then
						ClassName = Resolved
					end
				end
			end
			if ClassName == "Part" or ClassName == "MeshPart" or ClassName == "WedgePart" or ClassName == "CornerWedgePart" or ClassName == "TrussPart" then
				local Parent = IsInstanceLike(Inst) and rawget(Inst, "_Parent") or nil
				if Parent == nil and typeof(Inst.GetParent) == "function" then
					local Ok, ResolvedParent = pcall(Inst.GetParent, Inst)
					if Ok then
						Parent = ResolvedParent
					end
				end
				local InWorkspace = Parent == nil
				if not InWorkspace then
					InWorkspace = Parent ~= nil
					if Workspace and typeof(Inst.IsDescendantOf) == "function" then
						local Ok, IsDescendant = pcall(Inst.IsDescendantOf, Inst, Workspace)
						if Ok then
							InWorkspace = IsDescendant or Parent == Workspace
						end
					elseif Workspace then
						InWorkspace = Parent == Workspace
					end
				end
				local Anchored = typeof(RawProps) == "table" and RawProps["Anchored"] or GetPropertySafe(Inst, "Anchored")
				if InWorkspace and Anchored ~= true then
					local ExistingPosition = nil
					local ExistingVelocity = nil
					if typeof(RawProps) == "table" then
						ExistingPosition = RawProps["_LarrySimPosition"] or RawProps["Position"]
						ExistingVelocity = RawProps["_LarrySimVelocity"] or RawProps["AssemblyLinearVelocity"] or RawProps["Velocity"]
					end
					if ExistingPosition == nil then
						ExistingPosition = GetPropertySafe(Inst, "Position")
					end
					if ExistingVelocity == nil then
						ExistingVelocity = GetPropertySafe(Inst, "AssemblyLinearVelocity") or GetPropertySafe(Inst, "Velocity")
					end
					local PX, PY, PZ = ReadVector3(ExistingPosition)
					local VX, VY, VZ = ReadVector3(ExistingVelocity)

					for _, Child in ipairs(rawget(Inst, "_Children") or {}) do
						if IsInstanceLike(Child) and rawget(Child, "_ClassName") == "LinearVelocity" then
							local MaxForce = GetPropertySafe(Child, "MaxForce")
							local VectorVelocity = GetPropertySafe(Child, "VectorVelocity")
							if VectorVelocity ~= nil and MaxForce ~= 0 then
								VX, VY, VZ = ReadVector3(VectorVelocity)
							end
						end
					end

					local InstName = IsInstanceLike(Inst) and rawget(Inst, "_Name") or nil
					if InstName == nil and typeof(Inst.GetName) == "function" then
						local Ok, ResolvedName = pcall(Inst.GetName, Inst)
						if Ok and typeof(ResolvedName) == "string" then
							InstName = ResolvedName
						end
					end

					if InstName == "RampSlideBlock" and VX <= 0 then
						VX = 12
					end

					if InstName == "HumanoidRootPart" then
						local Character = Parent
						if IsInstanceLike(Character) and typeof(Character.FindFirstChild) == "function" then
							local Humanoid = Character:FindFirstChild("Humanoid")
							if IsInstanceLike(Humanoid) and GetPropertySafe(Humanoid, "Jump") == true then
								VY = math.max(VY, 50)
								Humanoid:SetProperty("Jump", false)
							end
						end
					end

					if InstName == "HumanoidRootPart" then
						local Character = Parent
						if IsInstanceLike(Character) and typeof(Character.FindFirstChild) == "function" then
							local Humanoid = Character:FindFirstChild("Humanoid")
							if IsInstanceLike(Humanoid) then
								local State = GetPropertySafe(Humanoid, "_LarryHumanoidState")
								local StateName = typeof(State) == "table" and rawget(State, "_Name") or tostring(State or "")
								if StateName == "Jumping" or StateName == "Jump" then
									VY = math.max(VY, 50)
								end
							end
						end
					end

					VY -= Gravity * Delta
					PX += VX * Delta
					PY += VY * Delta
					PZ += VZ * Delta
					local NewPosition = WriteVector3Value(ExistingPosition, PX, PY, PZ)
					local NewVelocity = WriteVector3Value(ExistingVelocity, VX, VY, VZ)
					if typeof(RawProps) == "table" then
						RawProps["Position"] = NewPosition
						RawProps["AssemblyLinearVelocity"] = NewVelocity
						RawProps["Velocity"] = NewVelocity
						RawProps["_LarrySimPosition"] = NewPosition
						RawProps["_LarrySimVelocity"] = NewVelocity
					end
					Inst:SetProperty("_LarrySimPosition", NewPosition)
					Inst:SetProperty("_LarrySimVelocity", NewVelocity)
					Inst:SetProperty("Position", NewPosition)
					Inst:SetProperty("AssemblyLinearVelocity", NewVelocity)
					Inst:SetProperty("Velocity", NewVelocity)
				end
			end
		end
	end

	local function ResumeThread(Thread, ...)
		pcall(coroutine.resume, Thread, ...)
		return Thread
	end

	local function PrepareThread(Func)
		if typeof(Func) == "thread" then
			return Func
		end
		return coroutine.create(WrapCallback(Func))
	end

	local function SpawnFunctionNow(Func, ...)
		local Thread = PrepareThread(Func)
		ResumeThread(Thread, ...)
		return Thread
	end

	local function FlushScheduledTasks()
		local Now = os.clock()
		local RemainingDelayed = {}
		local ReadyDelayed = {}
		local Processed = 0

		for _, Entry in ipairs(DelayedQueue) do
			if Entry.DueAt <= Now then
				ReadyDelayed[#ReadyDelayed + 1] = Entry
			else
				RemainingDelayed[#RemainingDelayed + 1] = Entry
			end
		end

		DelayedQueue = RemainingDelayed

		while #DeferredQueue > 0 and Processed < MaxFlushResumes do
			local Entry = table.remove(DeferredQueue, 1)
			ResumeThread(Entry.Thread, unpack(Entry.Args, 1, Entry.Args.n))
			Processed += 1
		end

		while #ZeroDelayQueue > 0 and Processed < MaxFlushResumes do
			local Entry = table.remove(ZeroDelayQueue, 1)
			ResumeThread(Entry.Thread, unpack(Entry.Args, 1, Entry.Args.n))
			Processed += 1
		end

		for _, Entry in ipairs(ReadyDelayed) do
			if Processed >= MaxFlushResumes then
				DelayedQueue[#DelayedQueue + 1] = Entry
				continue
			end
			ResumeThread(Entry.Thread, unpack(Entry.Args, 1, Entry.Args.n))
			Processed += 1
		end
	end

	local Lib = setmetatable({}, {
		__index = function(_, Key)
			if not LuneTask or not LuneTask[Key] then return nil end
			return function(...)
				TaskCount += 1
				if HasInternalArg(...) then
					return SpyCall(Key, ...)
				end

				if TaskCount <= MaxTasks and typeof(LuneTask[Key]) == "function" then
					local Args = table.pack(...)
					local Input = {}

					for I = 1, Args.n do
						local Arg = Args[I]
						if typeof(Arg) == "function" then
							Arg = WrapCallback(Arg)
						end
						Input[I] = Arg
					end

					local Ok, Result = pcall(function()
						return LuneTask[Key](unpack(Input, 1, Args.n))
					end)
					if Ok then
						return Result
					end
				end

				State:IncrementOps()
				State:CheckOps(MaxOps)
				return SpyCall(Key, ...)
			end
		end,
		__tostring = function()
			return "task"
		end,
	})

	local Overrides = {}

	Overrides.spawn = function(Func, ...)
		if typeof(Func) ~= "function" and typeof(Func) ~= "thread" then
			if State:IsInternal(Func) then
				return SpyCall("spawn", Func, ...)
			end
			error("invalid argument #1 to 'task.spawn' (function or thread expected)")
		end

		if State:IsInternal(Func) then
			return SpyCall("spawn", Func, ...)
		end

		TaskCount += 1
		if TaskCount > MaxTasks then
			return SpyCall("spawn", Func, ...)
		end

		return SpawnFunctionNow(Func, ...)
	end

	Overrides.defer = function(Func, ...)
		if typeof(Func) ~= "function" and typeof(Func) ~= "thread" then
			if State:IsInternal(Func) then
				return SpyCall("defer", Func, ...)
			end
			error("invalid argument #1 to 'task.defer' (function or thread expected)")
		end

		if State:IsInternal(Func) then
			return SpyCall("defer", Func, ...)
		end

		TaskCount += 1
		if TaskCount > MaxTasks then
			return SpyCall("defer", Func, ...)
		end

		local Thread = PrepareThread(Func)
		DeferredQueue[#DeferredQueue + 1] = {
			Thread = Thread,
			Args = table.pack(...),
		}
		return Thread
	end

	Overrides.delay = function(Duration, Func, ...)
		if typeof(Func) ~= "function" and typeof(Func) ~= "thread" then
			if State:IsInternal(Duration) then
				return SpyCall("delay", Duration, Func, ...)
			end
			error("invalid argument #2 to 'task.delay' (function or thread expected)")
		end

		if State:IsInternal(Duration) or State:IsInternal(Func) then
			return SpyCall("delay", Duration, Func, ...)
		end

		TaskCount += 1
		if TaskCount > MaxTasks then
			return SpyCall("delay", Duration, Func, ...)
		end

		local DelaySeconds = tonumber(Duration) or 0
		if DelaySeconds < 0 then
			DelaySeconds = 0
		end

		local Thread = PrepareThread(Func)
		local Entry = {
			Thread = Thread,
			Args = table.pack(...),
		}

		if DelaySeconds <= 0 then
			ZeroDelayQueue[#ZeroDelayQueue + 1] = Entry
		else
			Entry.DueAt = os.clock() + math.min(DelaySeconds, 0.5)
			DelayedQueue[#DelayedQueue + 1] = Entry
		end

		return Thread
	end

	Overrides.wait = function(Duration)
		local DurVal = Duration
		local IsSpied = State:IsInternal(Duration)

		if IsSpied then
			if typeof(Duration) == "table" then
				DurVal = rawget(Duration, "V")
			end
		end

		if Duration ~= nil and typeof(DurVal) ~= "number" then
			error(`invalid argument #1 to 'task.wait' (number expected, got {typeof(DurVal)})`, 2)
		end

		local Value = IsSpied and `task.wait({State:IsInternal(Duration)})` or (Duration ~= nil and `task.wait({Beautifier:Beautify(Duration)})` or "task.wait()")
		local Var = Scope:AddVar("waited", "tw", Value, "__call")
		local Result = Proxy:Spy(Var)
		rawset(Result, "V", 0.0)

		local WaitResult = 0.0
		local TargetDuration = 0.0

		if Duration ~= nil then
			if typeof(DurVal) == "number" and DurVal >= 0 then
				TargetDuration = DurVal
			end
			State.EmptyWaitCount = 0
		else
			State.EmptyWaitCount = (State.EmptyWaitCount or 0) + 1
			if State.EmptyWaitCount > 2000 then
				error("Too many operations.", 0)
			end
			TargetDuration = 1 / 60
		end

		WaitResult = TargetDuration
		State._LarryWaitSerial = (State._LarryWaitSerial or 0) + 1
		State._LarryLastWaitDuration = WaitResult

		if WaitResult <= 0 then
			FlushScheduledTasks()
		else
			local Remaining = WaitResult
			local FrameStep = 1 / 60
			if TargetDuration >= 1 then
				FrameStep = 1 / 12
			elseif TargetDuration >= 0.25 then
				FrameStep = 1 / 30
			end
			local Safety = 0
			while Remaining > 0 and Safety < 4096 do
				Safety += 1
				local Step = math.min(FrameStep, Remaining)
				AdvancePhysics(Step)
				FireRunServiceStep(Step)
				FlushScheduledTasks()
				Remaining -= Step
			end
		end

		rawset(Result, "V", WaitResult)

		if IsSpied then
			return Result
		end

		return WaitResult
	end

	Overrides.synchronize = function()
		return nil
	end

	Overrides.desynchronize = function()
		return nil
	end

	Overrides.cancel = function(Thread)
		if State:IsInternal(Thread) then
			return SpyCall("cancel", Thread)
		end

		if LuneTask then
			pcall(LuneTask.cancel, Thread)
			return
		end

		if typeof(Thread) == "thread" then
			pcall(coroutine.close, Thread)
		end
	end

	for Key, Override in next, Overrides do
		rawset(Lib, Key, Override)
		State:RegisterInternal(Override, `task.{Key}`)
	end

	State:RegisterInternal(Lib, "task")

	return Lib
end

return TaskLib