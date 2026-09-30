local IdentityUtil = require("../Utils/Identity")
local RuntimeClock = require("./RuntimeClock")

local Signals = {}
local Runtime = {
	Proxy = nil,
	State = nil,
	Emitter = nil,
	Beautifier = nil,
	Scope = nil,
	Config = nil,
	Reconstruction = nil,
}

local SignalMeta = {}
SignalMeta.__index = SignalMeta

local ConnectionMeta = {}
ConnectionMeta.__index = ConnectionMeta

local ActiveSignals = {}
local InstanceSignals = setmetatable({}, { __mode = "k" })

local function ReadProperty(Inst, Key)
	if typeof(Inst) ~= "table" then
		return nil
	end
	if typeof(Inst.GetRawProperty) == "function" then
		local Ok, Value = pcall(Inst.GetRawProperty, Inst, Key)
		if Ok and Value ~= nil then
			return Value
		end
	end
	if typeof(Inst.GetProperty) == "function" then
		local Ok, Value = pcall(Inst.GetProperty, Inst, Key)
		if Ok then
			return Value
		end
	end
	local Props = rawget(Inst, "_Properties")
	if typeof(Props) == "table" then
		return Props[Key]
	end
	return nil
end

local function WriteProperty(Inst, Key, Value)
	if typeof(Inst) ~= "table" then
		return
	end
	if typeof(Inst.SetProperty) == "function" then
		pcall(Inst.SetProperty, Inst, Key, Value)
		return
	end
	local Props = rawget(Inst, "_Properties")
	if typeof(Props) == "table" then
		Props[Key] = Value
	end
end

local function EnumValue(EnumName, ItemName)
	local Ok, Enums = pcall(require, "./Enums")
	if Ok and typeof(Enums) == "table" and typeof(Enums.Get) == "function" then
		local Value = Enums.Get(EnumName, ItemName)
		if Value ~= nil then
			return Value
		end
	end
	return ItemName
end

local function EnumName(Value)
	if typeof(Value) == "table" then
		return rawget(Value, "_Name") or rawget(Value, "Name") or tostring(Value)
	end
	return tostring(Value)
end

local function TweenDuration(TweenInfo)
	if typeof(TweenInfo) ~= "table" then
		return RuntimeClock.GetFrameDelta()
	end
	local Duration = tonumber(rawget(TweenInfo, "Time")) or 0
	local Delay = tonumber(rawget(TweenInfo, "DelayTime")) or 0
	return math.max(RuntimeClock.GetFrameDelta(), Duration + Delay)
end

local function CompleteTweenFromWait(Signal)
	if Signal._Name ~= "Completed" then
		return nil, nil
	end

	local Owner = Signal._Owner
	if typeof(Owner) ~= "table" then
		return nil, nil
	end

	local ClassName = rawget(Owner, "_ClassName")
	if ClassName ~= "Tween" and ClassName ~= "TweenBase" then
		return nil, nil
	end

	local Completed = EnumValue("PlaybackState", "Completed")
	local Current = ReadProperty(Owner, "PlaybackState")
	if EnumName(Current) == "Completed" then
		return RuntimeClock.GetFrameDelta(), Completed
	end

	local Target = ReadProperty(Owner, "Instance")
	local Goals = ReadProperty(Owner, "_TweenProperties")
	if typeof(Target) == "table" and typeof(Goals) == "table" then
		for Key, Value in next, Goals do
			if typeof(Target.SetProperty) == "function" then
				pcall(Target.SetProperty, Target, Key, Value)
			else
				pcall(function()
					Target[Key] = Value
				end)
			end
		end
	end

	WriteProperty(Owner, "PlaybackState", Completed)
	WriteProperty(Owner, "_LarryTweenCompleteAtWaitSerial", nil)
	return TweenDuration(ReadProperty(Owner, "TweenInfo")), Completed
end

local function DeferCallback(Callback, ...)
	local Args = table.pack(...)
	local LuneTask = nil
	pcall(function()
		LuneTask = require("@lune/task")
	end)

	if LuneTask and typeof(LuneTask.defer) == "function" then
		LuneTask.defer(function()
			Callback(table.unpack(Args, 1, Args.n))
		end)
		return
	end

	local Thread = coroutine.create(function()
		Callback(table.unpack(Args, 1, Args.n))
	end)
	pcall(coroutine.resume, Thread)
end

local function ShouldSkipCallback(Signal, ...)
	local Owner = typeof(Signal) == "table" and rawget(Signal, "_Owner") or nil
	if typeof(Owner) ~= "table" or rawget(Owner, "_ClassName") ~= "BindableEvent" then
		return false
	end
	local Args = table.pack(...)
	for I = 1, Args.n do
		local Value = Args[I]
		if typeof(Value) == "table" and rawget(Value, "_ClassName") == nil and typeof(Value.GetClassName) ~= "function" then
			local Ok, Mt = pcall(getmetatable, Value)
			if Ok and typeof(Mt) == "table" and rawget(Mt, "__index") ~= nil then
				return true
			end
		end
	end
	return false
end

function Signals.new(Name, Owner)
	local Self = setmetatable({}, SignalMeta)

	Self._Name = Name
	Self._Owner = Owner
	Self._Connections = {}
	Self._Id = IdentityUtil.Generate(8)

	table.insert(ActiveSignals, Self)

	return Self
end

function Signals.Configure(Proxy, State, Emitter, Beautifier, Scope, Config, Reconstruction)
	Runtime.Proxy = Proxy
	Runtime.State = State
	Runtime.Emitter = Emitter
	Runtime.Beautifier = Beautifier
	Runtime.Scope = Scope
	Runtime.Config = Config
	Runtime.Reconstruction = Reconstruction
end

function Signals.ResetRuntime()
	Runtime.Proxy = nil
	Runtime.State = nil
	Runtime.Emitter = nil
	Runtime.Beautifier = nil
	Runtime.Scope = nil
	Runtime.Config = nil
	Runtime.Reconstruction = nil
end

function Signals.DirectConnect(Signal, Callback)
	local Conn = Signals.CreateConnection(Signal, Callback)
	table.insert(Signal._Connections, Conn)
	return Conn
end

function SignalMeta:Connect(Callback)
	if Runtime.State and Runtime.Proxy and Runtime.Emitter and Runtime.Beautifier and Runtime.Scope and Runtime.Config then
		return Signals.SpyConnect(
			self,
			Callback,
			Runtime.Proxy,
			Runtime.State,
			Runtime.Emitter,
			Runtime.Beautifier,
			Runtime.Scope,
			Runtime.Config,
			"Connect"
		)
	end

	return Signals.DirectConnect(self, Callback)
end

function SignalMeta:connect(Callback)
	return self:Connect(Callback)
end

function SignalMeta:ConnectParallel(Callback)
	return self:Connect(Callback)
end

function SignalMeta:Once(Callback)
	if Runtime.State and Runtime.Proxy and Runtime.Emitter and Runtime.Beautifier and Runtime.Scope and Runtime.Config then
		return Signals.SpyConnect(
			self,
			Callback,
			Runtime.Proxy,
			Runtime.State,
			Runtime.Emitter,
			Runtime.Beautifier,
			Runtime.Scope,
			Runtime.Config,
			"Once"
		)
	end

	local Conn
	Conn = self:Connect(function(...)
		Conn:Disconnect()
		Callback(...)
	end)
	return Conn
end

function SignalMeta:Wait()
	if getmetatable(self) ~= SignalMeta then
		error("Expected ':' not '.' calling member function Wait", 2)
	end

	local dt, ReturnValue = CompleteTweenFromWait(self)
	if dt == nil then
		dt = RuntimeClock.GetFrameDelta()
	end
	local previous = RuntimeClock.Now()
	local stamp = RuntimeClock.Advance(dt)
	self._WaitStamp = stamp
	if ReturnValue ~= nil then
		return ReturnValue
	end
	return dt, stamp, previous
end

function SignalMeta:WaitTimeout(Timeout)
	if getmetatable(self) ~= SignalMeta then
		error("Expected ':' not '.' calling member function WaitTimeout", 2)
	end

	local Requested = tonumber(Timeout)
	local dt = Requested and Requested > 0 and Requested or RuntimeClock.GetFrameDelta()
	local previous = RuntimeClock.Now()
	local stamp = RuntimeClock.Advance(dt)
	self._WaitStamp = stamp
	return dt, stamp, previous
end

function SignalMeta:Fire(...)
	if ShouldSkipCallback(self, ...) then
		return
	end
	for _, Conn in self._Connections do
		if Conn.Connected then
			local S, E = pcall(Conn._Callback, ...)
			if not S then continue end
		end
	end
end

function SignalMeta:GetConnections()
	local Result = {}
	for _, Conn in self._Connections do
		if Conn.Connected then
			table.insert(Result, Conn)
		end
	end
	return Result
end

function SignalMeta:__tostring()
	return `Signal<{self._Name}>`
end

function Signals.CreateConnection(Signal, Callback)
	local Self = setmetatable({}, ConnectionMeta)

	Self.Connected = true
	Self._Signal = Signal
	Self._Callback = Callback
	Self._Id = IdentityUtil.Generate(6)

	return Self
end

function ConnectionMeta:Disconnect()
	self.Connected = false

	local Connections = self._Signal._Connections
	for I = #Connections, 1, -1 do
		if Connections[I] == self then
			table.remove(Connections, I)
			break
		end
	end
end

function ConnectionMeta:disconnect()
	self:Disconnect()
end

function ConnectionMeta:Defer(...)
	if not self.Connected then return end

	local Args = table.pack(...)
	DeferCallback(function()
		if self.Connected then
			self._Callback(unpack(Args, 1, Args.n))
		end
	end)
end

function ConnectionMeta:__tostring()
	return `Connection<{self._Id}>`
end

function Signals.GetAll()
	return ActiveSignals
end

function Signals.Clear()
	for _, Signal in ActiveSignals do
		for _, Conn in Signal._Connections do
			Conn.Connected = false
		end
		table.clear(Signal._Connections)
	end
	table.clear(ActiveSignals)
	table.clear(InstanceSignals)
end

function Signals.ForInstance(Inst, EventName)
	if typeof(Inst) == "table" then
		local Bucket = InstanceSignals[Inst]
		if Bucket == nil then
			Bucket = {}
			InstanceSignals[Inst] = Bucket
		end

		local Existing = Bucket[EventName]
		if Existing ~= nil then
			return Existing
		end

		local Signal = Signals.new(EventName, Inst)
		local StableId = rawget(Inst, "_InternalId") or rawget(Inst, "_Id") or tostring(Inst)
		Signal._Id = `{StableId}_{EventName}`
		Bucket[EventName] = Signal
		return Signal
	end

	local Key = `{tostring(Inst)}_{EventName}`
	for _, Signal in ActiveSignals do
		if Signal._Id == Key then
			return Signal
		end
	end

	local Signal = Signals.new(EventName, Inst)
	Signal._Id = Key
	return Signal
end

function Signals.SpyConnect(Signal, Callback, Proxy, State, Emitter, Beautifier, Scope, Config, ConnectMode)
	ConnectMode = ConnectMode or "Connect"
	local SignalPath = State:IsInternal(Signal)

	if not SignalPath then
		if typeof(Signal) == "table" and getmetatable(Signal) == SignalMeta then
			if ConnectMode == "Once" then
				local Conn
				Conn = Signals.DirectConnect(Signal, function(...)
					Conn:Disconnect()
					return Callback(...)
				end)
				return Conn
			end

			return Signals.DirectConnect(Signal, Callback)
		end
		return nil
	end

	local FuncStr = nil
	if Runtime.Reconstruction and Runtime.Config and Runtime.Config.ast_reconstruction then
		FuncStr = Runtime.Reconstruction:TakeSignalCallback(SignalPath, ConnectMode, Signal._Name)
	end
	if typeof(FuncStr) ~= "string" or FuncStr == "" then
		FuncStr = Beautifier:Beautify(Callback, State.CurrentIndent + 1, {
			ExploreCallback = true,
			SignalPath = SignalPath,
			ConnectMode = ConnectMode,
			EventName = Signal._Name,
		})
	end

	local Value = `{SignalPath}:{ConnectMode}({FuncStr})`
	local Var = Scope:AddVar("connection", "sig", Value, "__call")

	local MaxOps = Config.max_ops or 10500

	if typeof(Callback) == "function" then
		local ConnRef = nil
		local WrappedCallback = function(...)
			State:IncrementOps()
			State:CheckOps(MaxOps)
			if ConnectMode == "Once" and ConnRef ~= nil then
				ConnRef:Disconnect()
			end
			return Callback(...)
		end

		if typeof(Signal) == "table" and getmetatable(Signal) == SignalMeta then
			local Conn = Signals.DirectConnect(Signal, WrappedCallback)
			ConnRef = Conn
			State:RegisterInternal(Conn, Var)
			return Conn
		end

		local RealSignal = rawget(Signal, "_signal")
		if RealSignal and getmetatable(RealSignal) == SignalMeta then
			local Conn = Signals.DirectConnect(RealSignal, WrappedCallback)
			ConnRef = Conn
			State:RegisterInternal(Conn, Var)
			return Conn
		end
	end

	return Proxy:Spy(Var)
end

function Signals.TypeOf(Value)
	if getmetatable(Value) == SignalMeta then
		return "RBXScriptSignal"
	end
	if getmetatable(Value) == ConnectionMeta then
		return "RBXScriptConnection"
	end
	return nil
end

function Signals.CreateBindableEvent()
	local Event = {}
	local Signal = Signals.new("Event", Event)

	Event.Event = Signal

	Event.Fire = function(_, ...)
		Signal:Fire(...)
	end

	Event.Destroy = function(_)
		for _, Conn in Signal._Connections do
			Conn.Connected = false
		end
		table.clear(Signal._Connections)
	end

	return setmetatable(Event, {
		__tostring = function()
			return "BindableEvent"
		end,
	})
end

return Signals