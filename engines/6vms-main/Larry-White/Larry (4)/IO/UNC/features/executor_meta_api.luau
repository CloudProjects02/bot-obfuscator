local TypeGuards = require("../util/typeguards")
local Errors = require("../util/errors")
local IdentityUtil = require("../../../Utils/Identity")
local PhysicsRegistry = require("../../../Roblox/PhysicsRegistry")
local RuntimeClock = require("../../../Roblox/RuntimeClock")

local ExecutorMetaApi = {}
local HiddenPropertyAllowlist = {
	size_xml = true,
	networkissleeping = true,
}

local function deferCallback(Callback, ...)
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

function ExecutorMetaApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope, Hierarchy)
	local noop = Ctx.noop
	local function ResolveLocalPlayer()
		if Hierarchy and typeof(Hierarchy.GetService) == "function" then
			local PlayersService = Hierarchy.GetService("Players")
			if PlayersService ~= nil then
				local RawLocal = nil
				if typeof(PlayersService.GetRawProperty) == "function" then
					RawLocal = PlayersService:GetRawProperty("LocalPlayer")
				end
				if RawLocal ~= nil then
					return RawLocal
				end
				local OkProp, LocalPlayer = pcall(function()
					return PlayersService.LocalPlayer
				end)
				if OkProp and LocalPlayer ~= nil then
					return LocalPlayer
				end
			end
		end

		local CallerEnv = TypeGuards.GetCallerEnv()
		if typeof(CallerEnv) == "table" and CallerEnv.game ~= nil then
			local OkPlayer, LocalPlayer = pcall(function()
				return CallerEnv.game:GetService("Players").LocalPlayer
			end)
			if OkPlayer then
				return LocalPlayer
			end
		end

		return nil
	end

	return {
		getgc = function(IncludeTables)
			local Result = {}
			if IncludeTables then
				for _, Tbl in Ctx.GcTables do
					table.insert(Result, Tbl)
				end
			end
			for _ = 1, math.random(50, 200) do
				table.insert(Result, {})
			end
			return Result
		end,

		pcall = function(Func, ...)
			local Results = table.pack(Ctx.native_pcall(Func, ...))
			if Results[1] == false and Errors.ShouldBypassPcallError(Results[2]) then
				return true
			end
			return table.unpack(Results, 1, Results.n)
		end,

		xpcall = function(Func, ErrHandler, ...)
			return Ctx.native_xpcall(Func, ErrHandler, ...)
		end,

		_addToGc = function(Tbl)
			table.insert(Ctx.GcTables, Tbl)
		end,

		getreg = function()
			return { true }
		end,

		getregistry = function()
			return { true }
		end,

		collectgarbage = function(Opt, Arg)
			if Opt == "count" then
				return math.random(1000, 50000)
			end
			return 0
		end,

		getgenv = function()
			local CallerEnv = TypeGuards.GetCallerEnv()
			if typeof(CallerEnv) == "table" then
				return CallerEnv
			end
			return Ctx.genv_shared
		end,

		getrenv = function()
			local UniqueGlobal = {}
			local EnvSnapshot = {}
			local CallerEnv = TypeGuards.GetCallerEnv()
			if typeof(CallerEnv) == "table" then
				for Key, Value in next, CallerEnv do
					if Key ~= "_G" then
						EnvSnapshot[Key] = Value
					end
				end
			end
			EnvSnapshot._G = UniqueGlobal
			return EnvSnapshot
		end,

		getmenv = function()
			return TypeGuards.SpyReturn(Proxy, Scope, Beautifier, "getmenv")
		end,

		getsenv = function(Script)
			return {
				script = Script,
				onRunning = function()
					return true
				end,
				disabled = false,
			}
		end,

		queue_on_teleport = function(Script)
			if typeof(Script) ~= "string" then error("invalid argument #1 to 'queue_on_teleport' (string expected)") end
			Emitter:Append(`queue_on_teleport({Beautifier:Beautify(Script)})`)
		end,

		gethiddenproperty = function(Object, Prop)
			if typeof(Prop) ~= "string" then error("invalid argument #2 to 'gethiddenproperty' (string expected)") end
			local PropKey = TypeGuards.NormalizePropName(Prop)
			local Hidden = TypeGuards.GetHiddenMap(Ctx, Object)
			local Stored = Hidden[PropKey]
			if Stored ~= nil then
				return Stored, true
			end

			if PropKey == "size_xml" then
				return 5, true
			end
			if PropKey == "networkissleeping" then
				return false, true
			end

			local Ok, Val = pcall(function()
				return (Object :: any)[Prop]
			end)
			if Ok then
				return Val, true
			end

			error(`hidden property {Prop} is not available`, 0)
		end,

		sethiddenproperty = function(Object, Prop, Value)
			if typeof(Prop) ~= "string" then error("invalid argument #2 to 'sethiddenproperty' (string expected)") end
			local PropKey = TypeGuards.NormalizePropName(Prop)
			local Hidden = TypeGuards.GetHiddenMap(Ctx, Object)
			if not HiddenPropertyAllowlist[PropKey] and Hidden[PropKey] == nil then
				error(`hidden property {Prop} is not writable`, 0)
			end

			Hidden[PropKey] = Value
			pcall(function()
				(Object :: any)[Prop] = Value
			end)
			return true
		end,

		isscriptable = function(Object, Prop)
			if typeof(Prop) ~= "string" then error("invalid argument #2 to 'isscriptable' (string expected)") end
			local PropKey = TypeGuards.NormalizePropName(Prop)
			local Map = TypeGuards.GetScriptableMap(Ctx, Object)
			if Map[PropKey] ~= nil then
				return Map[PropKey]
			end
			return TypeGuards.IsDefaultScriptable(Object, Prop)
		end,

		setscriptable = function(Object, Prop, Value)
			if typeof(Prop) ~= "string" then error("invalid argument #2 to 'setscriptable' (string expected)") end
			local PropKey = TypeGuards.NormalizePropName(Prop)
			local Map = TypeGuards.GetScriptableMap(Ctx, Object)
			local Was = Map[PropKey]
			if Was == nil then
				Was = TypeGuards.IsDefaultScriptable(Object, Prop)
			end
			Map[PropKey] = Value == true
			local Hidden = TypeGuards.GetHiddenMap(Ctx, Object)
			if Hidden[PropKey] == nil and PropKey == "size_xml" then
				Hidden[PropKey] = 5
			end
			local was = Was
			return was
		end,

		isnetworkowner = function(Inst)
			return true
		end,

		getinputs = function()
			local Ok, UserInputService = pcall(function()
				return game:GetService("UserInputService")
			end)
			if Ok and UserInputService and typeof(UserInputService.GetKeysPressed) == "function" then
				local OkKeys, Keys = pcall(function()
					return UserInputService:GetKeysPressed()
				end)
				if OkKeys and typeof(Keys) == "table" then
					return Keys
				end
			end
			return {}
		end,

		setsimulationradius = function(Radius, MaxRadius)
			if typeof(Radius) ~= "number" then error("invalid argument #1 to 'setsimulationradius' (number expected)") end
			Emitter:Append(`setsimulationradius({Beautifier:Beautify(Radius)})`)
		end,

		setfpscap = function(Fps)
			if typeof(Fps) == "number" then
				Ctx.FpsCap = Fps
				RuntimeClock.SetFrameRate(Fps)
			end
			Emitter:Append(`setfpscap({Beautifier:Beautify(Fps)})`)
		end,

		getfpscap = function()
			return Ctx.FpsCap or RuntimeClock.GetFrameRate()
		end,

		decompile = function(Script)
			if typeof(Script) == "table" or typeof(Script) == "Instance" then
				local Source = nil
				pcall(function()
					Source = Script.Source
				end)
				if typeof(Source) ~= "string" or Source == "" then
					return "Bytecode is empty"
				end
				return "
			end
			return "Bytecode is empty"
		end,

		isrbxactive = function()
			return true
		end,

		mouse1click = noop,
		mouse1press = noop,
		mouse1release = noop,
		mouse2click = noop,
		mouse2press = noop,
		mouse2release = noop,
		mousemoveabs = function(X, Y) end,
		mousemoverel = function(X, Y) end,
		mousescroll = function(Lines) end,
		keypress = function(Key) end,
		keyrelease = function(Key) end,
		keyclick = function(Key) end,

		messagebox = function(Text, Caption, MsgFlags)
			Emitter:Append(`messagebox({Beautifier:Beautify(Text)}, {Beautifier:Beautify(Caption)}, {Beautifier:Beautify(MsgFlags)})`)
			return 1
		end,

		saveinstance = function(Options)
			Emitter:Append(`saveinstance({Beautifier:Beautify(Options)})`)
		end,

		setfflag = function(Key, Value)
			if typeof(Key) ~= "string" then error("invalid argument #1 to 'setfflag' (string expected)") end
			error("setfflag is not available in this environment", 0)
		end,

		getfflag = function(Key)
			if typeof(Key) ~= "string" then error("invalid argument #1 to 'getfflag' (string expected)") end
			error("getfflag is not available in this environment", 0)
		end,

		getfflags = function()
			local Snapshot = {}
			for Key, Value in next, Ctx.Flags do
				Snapshot[Key] = tostring(Value)
			end
			if next(Snapshot) == nil then
				Snapshot.FFlagDebugGraphicsPreferD3D11 = "True"
			end
			return Snapshot
		end,

		isfflagenabled = function(Key)
			if typeof(Key) ~= "string" then error("invalid argument #1 to 'isfflagenabled' (string expected)") end
			local Value = Ctx.Flags[Key]
			if Value == nil then
				return true
			end
			local Lower = string.lower(tostring(Value))
			return Lower == "true" or Lower == "1" or Lower == "yes" or Lower == "on"
		end,

		getconnections = function(Signal)
			if typeof(Signal) == "table" then
				if Signal._Connections then
					local res = {}
					for _, conn in Signal._Connections do
						local enabled = true
						if conn.Connected ~= nil then
							enabled = conn.Connected
						end
						local connWrap = {
							Enabled = enabled,
							ForeignState = false,
							LuaConnection = true,
							Function = conn._Callback or noop,
							Thread = coroutine.create(noop),
						}
						connWrap.Fire = function(self, ...)
							local a = table.pack(...)
							if conn._Callback then conn._Callback(table.unpack(a, 1, a.n)) end
						end
						connWrap.Defer = function(self, ...)
							local a = table.pack(...)
							if conn._Callback then deferCallback(conn._Callback, table.unpack(a, 1, a.n)) end
						end
						connWrap.Disconnect = function(self)
							if conn.Disconnect then conn:Disconnect() end
						end
						connWrap.Disable = function(self)
							self.Enabled = false
							if conn.Connected ~= nil then conn.Connected = false end
						end
						connWrap.Enable = function(self)
							self.Enabled = true
							if conn.Connected ~= nil then conn.Connected = true end
						end
						table.insert(res, connWrap)
					end
					if #res == 0 then
						res[1] = {
							Enabled = true,
							ForeignState = false,
							LuaConnection = true,
							Function = noop,
							Thread = coroutine.create(noop),
							Fire = function() end,
							Defer = function() end,
							Disconnect = function() end,
							Disable = function(self) self.Enabled = false end,
							Enable = function(self) self.Enabled = true end,
						}
					end
					return res
				end
				if Signal.Connect then
					return {
						{
							Enabled = true,
							ForeignState = false,
							LuaConnection = true,
							Function = noop,
							Thread = coroutine.create(noop),
							Fire = function() end,
							Defer = function() end,
							Disconnect = function() end,
							Disable = function(self) self.Enabled = false end,
							Enable = function(self) self.Enabled = true end,
						}
					}
				end
			end
			return {
				{
					Enabled = true,
					ForeignState = false,
					LuaConnection = true,
					Function = noop,
					Thread = coroutine.create(noop),
					Fire = function() end,
					Defer = function() end,
					Disconnect = function() end,
					Disable = function(self) self.Enabled = false end,
					Enable = function(self) self.Enabled = true end,
				}
			}
		end,

		getsignalargumentsinfo = function(Signal)
			local Name = typeof(Signal) == "table" and rawget(Signal, "_Name") or nil
			if Name == "PlayerAdded" then
				return {
					{
						Name = "player",
						Type = "Player",
					},
				}
			end
			return {
				{
					Name = "arg1",
					Type = "Variant",
				},
			}
		end,

		firesignal = function(Signal, ...)
			local args = table.pack(...)
			if typeof(Signal) == "table" then
				if Signal.Fire then
					Signal:Fire(table.unpack(args, 1, args.n))
					return
				end
				if Signal._Connections then
					for _, conn in Signal._Connections do
						if conn._Callback and (conn.Connected == nil or conn.Connected) then
							pcall(conn._Callback, table.unpack(args, 1, args.n))
						end
					end
					return
				end
			end
			if typeof(Signal) == "RBXScriptSignal" then
				pcall(function()
					Signal:Fire(table.unpack(args, 1, args.n))
				end)
			end
		end,

		fireclickdetector = function(Detector, Distance, Player)
			if Player == nil then
				Player = ResolveLocalPlayer()
			end

			if typeof(Detector) == "table" then
				local sig = Detector.MouseClick
				if sig and typeof(sig) == "table" and sig.Fire then
					sig:Fire(Player)
				end
			elseif typeof(Detector) == "Instance" then
				pcall(function()
					Detector.MouseClick:Fire(Player)
				end)
			end
		end,

		fireproximityprompt = function(Prompt, Amount, Skip)
			if typeof(Prompt) == "table" then
				if Prompt.Triggered and typeof(Prompt.Triggered) == "table" and Prompt.Triggered.Fire then
					Prompt.Triggered:Fire()
				end
			elseif typeof(Prompt) == "Instance" then
				pcall(function()
					local Signal = (Prompt :: any).Triggered
					if Signal == nil then
						local Signals = require("../../../Roblox/Signals")
						Signal = Signals.ForInstance(Prompt, "Triggered")
						pcall(function()
							(Prompt :: any)._Properties["Triggered"] = Signal
						end)
					end
					if Signal and typeof(Signal) == "table" and Signal.Fire then
						Signal:Fire()
					end
				end)
			end
		end,

		firetouchinterest = function(Part, Other, Toggle)
			if (typeof(Part) == "table" or typeof(Part) == "Instance")
				and (typeof(Other) == "table" or typeof(Other) == "Instance")
			then
				if Toggle == 0 then
					PhysicsRegistry.AddTouch(Part, Other)
				else
					PhysicsRegistry.RemoveTouch(Part, Other)
				end
			end

			if typeof(Part) == "table" and typeof(Other) == "table" then
				if Toggle == 0 then
					local sig = Part.Touched
					if sig and typeof(sig) == "table" and sig.Fire then sig:Fire(Other) end
				else
					local sig = Part.TouchEnded
					if sig and typeof(sig) == "table" and sig.Fire then sig:Fire(Other) end
				end
			elseif typeof(Part) == "Instance" and typeof(Other) == "Instance" then
				pcall(function()
					if Toggle == 0 then
						Part.Touched:Fire(Other)
					else
						Part.TouchEnded:Fire(Other)
					end
				end)
			end
		end,

		firetouchtransmitter = function(Part, Other, Toggle)
			if typeof(Part) == "Instance" then
				local okTouchTransmitter, isTouchTransmitter = pcall(function()
					return Part:IsA("TouchTransmitter")
				end)
				if okTouchTransmitter and isTouchTransmitter then
					local OkParent, Parent = pcall(function()
						return Part.Parent
					end)
					if OkParent and Parent ~= nil then
						Part = Parent
					end
				end
			end

			if typeof(Part) == "table" and typeof(Other) == "table" then
				if Toggle == 0 then
					local sig = Part.Touched
					if sig and typeof(sig) == "table" and sig.Fire then sig:Fire(Other) end
				else
					local sig = Part.TouchEnded
					if sig and typeof(sig) == "table" and sig.Fire then sig:Fire(Other) end
				end
			elseif typeof(Part) == "Instance" then
				if typeof(Other) ~= "Instance" then
					pcall(function()
						local Players = game:GetService("Players")
						local LocalPlayer = Players.LocalPlayer
						if LocalPlayer and LocalPlayer.Character then
							Other = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChildWhichIsA("BasePart")
						end
					end)
				end
				if typeof(Other) == "Instance" then
					pcall(function()
						if Toggle == 0 then
							Part.Touched:Fire(Other)
						else
							Part.TouchEnded:Fire(Other)
						end
					end)
				end
			end
		end,

		lz4compress = function(Data)
			if typeof(Data) ~= "string" then error("invalid argument #1 to 'lz4compress' (string expected)") end
			local ok, serde = pcall(require, "@lune/serde")
			if ok and serde then
				local ok2, out = pcall(serde.compress, "lz4", Data)
				if ok2 and typeof(out) == "string" then
					return out
				end
			end
			return Data
		end,

		lz4decompress = function(Data, Size)
			if typeof(Data) ~= "string" then error("invalid argument #1 to 'lz4decompress' (string expected)") end
			if typeof(Size) ~= "number" then error("invalid argument #2 to 'lz4decompress' (number expected)") end
			local ok, serde = pcall(require, "@lune/serde")
			if ok and serde then
				local ok2, out = pcall(serde.decompress, "lz4", Data)
				if ok2 and typeof(out) == "string" then
					return out
				end
			end
			return Data
		end,

		loadstring = function(Source, ChunkName)
			if typeof(Source) ~= "string" then error("invalid argument #1 to 'loadstring' (string expected)") end
			local ok1, luau = pcall(require, "@lune/luau")
			if not ok1 then return nil, "loadstring not available" end
			local s, c = pcall(luau.compile, Source)
			if s then
				local CallerEnv = TypeGuards.GetCallerEnv()
				local s2, f = pcall(luau.load, c, { environment = CallerEnv })
				if s2 then return f end
				return nil, "failed to load"
			end
			return nil, c
		end,

		run_on_actor = function(Actor, Source)
			if typeof(Source) ~= "string" then error("invalid argument #2 to 'run_on_actor' (string expected)") end
			Emitter:Append(`run_on_actor({Beautifier:Beautify(tostring(Actor))}, {Beautifier:Beautify(Source)})`)
		end,
	}
end

return ExecutorMetaApi