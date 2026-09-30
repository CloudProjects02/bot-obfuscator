local Instance = require("./Instance")
local DumpHierarchy = require("./DumpHierarchy")
local DataTypes = require("./DataTypes")
local Enums = require("./Enums")
local RuntimeClock = require("./RuntimeClock")

local Hierarchy = {}

local Runtime = {
	Proxy = nil,
	State = nil,
	Emitter = nil,
	Beautifier = nil,
	Scope = nil,
	Instance = Instance,
}

local GameRoot = nil
local ScriptInstance = nil
local ServiceMap = {}
local NilInstances = {}
local NilInstanceSet = {}
local TolerantPaths = {}

local EssentialServices = {
	Workspace = "Workspace",
	Players = "Players",
	ReplicatedStorage = "ReplicatedStorage",
	ReplicatedFirst = "ReplicatedFirst",
	ServerStorage = "ServerStorage",
	ServerScriptService = "ServerScriptService",
	StarterGui = "StarterGui",
	StarterPack = "StarterPack",
	StarterPlayer = "StarterPlayer",
	Lighting = "Lighting",
	CoreGui = "CoreGui",
	RunService = "RunService",
	UserInputService = "UserInputService",
	HttpService = "HttpService",
	Teams = "Teams",
	Debris = "Debris",
	CollectionService = "CollectionService",
	NetworkClient = "NetworkClient",
	TextChatService = "TextChatService",
	Stats = "Stats",
}

local function ResolveSpoofedId(Value, FlagName)
	if Value == nil then
		return nil
	end

	if typeof(Value) ~= "number" or Value ~= Value or Value == math.huge or Value == -math.huge then
		error(`
	end

	if Value <= 0 or math.floor(Value) ~= Value then
		error(`
	end

	return Value
end

local function GenerateDataModelId()
	return math.random(100000, 99999999)
end

local function isInstance(Value)
	return typeof(Value) == "table" and rawget(Value, "_ClassName") ~= nil and rawget(Value, "_Id") ~= nil
end

local function registerInternal(Object, Path)
	if Runtime.State and typeof(Path) == "string" and Path ~= "" then
		Runtime.State:RegisterInternal(Object, Path)
	end
end

local function refreshPaths(Inst, Path)
	if not isInstance(Inst) then
		return
	end

	if typeof(Path) == "string" and Path ~= "" then
		registerInternal(Inst, Path)
	end

	for _, Child in ipairs(rawget(Inst, "_Children") or {}) do
		local ChildName = rawget(Child, "_Name") or rawget(Child, "_ClassName") or "Instance"
		refreshPaths(Child, Path and `{Path}.{ChildName}` or nil)
	end
end

local function makeVector2(X, Y)
	local Vector2 = DataTypes.Get("Vector2")
	if typeof(Vector2) == "table" and typeof(Vector2.new) == "function" then
		local Ok, Value = pcall(Vector2.new, X, Y)
		if Ok and Value ~= nil then
			return Value
		end
	end

	return {
		X = X,
		Y = Y,
		__larryType = "Vector2",
	}
end

local function makeVector3(X, Y, Z)
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
		__larryType = "Vector3",
	}
end

local function makeCFrame(X, Y, Z)
	local CFrameLib = DataTypes.Get("CFrame")
	if typeof(CFrameLib) == "table" and typeof(CFrameLib.new) == "function" then
		local Ok, Value = pcall(CFrameLib.new, X, Y, Z)
		if Ok and Value ~= nil then
			return Value
		end
	end

	return {
		X = X,
		Y = Y,
		Z = Z,
		Position = makeVector3(X, Y, Z),
		RightVector = makeVector3(1, 0, 0),
		UpVector = makeVector3(0, 1, 0),
		LookVector = makeVector3(0, 0, -1),
		__larryType = "CFrame",
	}
end

local function enumItem(EnumName, ItemName)
	if typeof(EnumName) ~= "string" or typeof(ItemName) ~= "string" then
		return nil
	end
	return Enums.Get(EnumName, ItemName)
end

local function createInternalInstance(ClassName, Name)
	local Created = Instance._new(
		ClassName,
		{},
		Runtime.Proxy,
		Runtime.State,
		Runtime.Emitter,
		Runtime.Beautifier,
		Runtime.Scope,
		true
	)
	Created._Name = (typeof(Name) == "string" and Name ~= "") and Name or ClassName
	return Created
end

local function materializeChildren(Inst)
	if not isInstance(Inst) then
		return
	end

	local Loader = rawget(Inst, "_LarryMaterializeChildren")
	if typeof(Loader) ~= "function" then
		return
	end

	rawset(Inst, "_LarryMaterializeChildren", nil)
	local Ok = pcall(Loader, Inst)
	if not Ok then
		return
	end

	local Path = Runtime.State and Runtime.State:IsInternal(Inst) or nil
	refreshPaths(Inst, Path)
end

local function materializeTree(Inst)
	if not isInstance(Inst) then
		return
	end

	materializeChildren(Inst)
	for _, Child in ipairs(rawget(Inst, "_Children") or {}) do
		materializeTree(Child)
	end
end

local function setProp(Inst, Key, Value)
	if isInstance(Inst) then
		Inst:SetProperty(Key, Value)
	end
end

local function setPropIfMissing(Inst, Key, Value)
	if isInstance(Inst) and Inst:GetRawProperty(Key) == nil then
		Inst:SetProperty(Key, Value)
	end
end

local function ensureChild(Parent, ClassName, Name)
	materializeChildren(Parent)

	local Existing = Parent:FindFirstChild(Name)
	if Existing ~= nil then
		return Existing
	end

	local Child = createInternalInstance(ClassName, Name)
	Child:SetParent(Parent)
	local ParentPath = Runtime.State and Runtime.State:IsInternal(Parent) or nil
	if typeof(ParentPath) == "string" and ParentPath ~= "" then
		registerInternal(Child, `{ParentPath}.{Name}`)
	end
	return Child
end

local function ensureService(Name, ClassName)
	local Existing = ServiceMap[Name]
	if Existing ~= nil then
		return Existing
	end

	local Service = createInternalInstance(ClassName or Name, Name)
	Service:SetParent(GameRoot)
	ServiceMap[Name] = Service
	registerInternal(Service, `game.{Name}`)

	local DumpNode = DumpHierarchy.GetTopLevelNode(Name)
	if typeof(DumpNode) == "table" then
		DumpHierarchy.AttachNode(DumpNode, Service, Runtime)
	end

	return Service
end

local function seedRunService(Service)
	setPropIfMissing(Service, "Heartbeat", require("./Signals").ForInstance(Service, "Heartbeat"))
	setPropIfMissing(Service, "RenderStepped", require("./Signals").ForInstance(Service, "RenderStepped"))
	setPropIfMissing(Service, "Stepped", require("./Signals").ForInstance(Service, "Stepped"))
	setPropIfMissing(Service, "ClientGitHash", string.rep("0", 40))
	setPropIfMissing(Service, "RunState", "Running")
	setPropIfMissing(Service, "IsRunning", true)
end

local function seedWorkspace(Service)
	setPropIfMissing(Service, "Gravity", 196.2)
	setPropIfMissing(Service, "StreamingEnabled", false)
	setPropIfMissing(Service, "FallenPartsDestroyHeight", -500)
	setPropIfMissing(Service, "NumAwakeParts", 8)
	setPropIfMissing(Service, "RealPhysicsFPS", 60)
	setPropIfMissing(Service, "DistributedGameTime", RuntimeClock.GetServerNow())
end

local function seedUserInputService(Service)
	setPropIfMissing(Service, "TouchEnabled", false)
	setPropIfMissing(Service, "KeyboardEnabled", true)
	setPropIfMissing(Service, "MouseEnabled", true)
	setPropIfMissing(Service, "GamepadEnabled", false)
	setPropIfMissing(Service, "MouseIconEnabled", true)
end

local function seedCoreGui(Service)
	setPropIfMissing(Service, "Version", 0)
end

local function seedLighting(Service)
	setPropIfMissing(Service, "Brightness", 1)
	setPropIfMissing(Service, "FogStart", 0)
	setPropIfMissing(Service, "FogEnd", 100000)
	setPropIfMissing(Service, "ClockTime", 12)
	setPropIfMissing(Service, "TimeOfDay", "12:00:00")
	setPropIfMissing(Service, "Technology", enumItem("Technology", "Future") or enumItem("Technology", "ShadowMap") or "Future")
end

local function seedPlayers(Service)
	setPropIfMissing(Service, "RespawnTime", 5)
	setPropIfMissing(Service, "PlayerAdded", require("./Signals").ForInstance(Service, "PlayerAdded"))
	setPropIfMissing(Service, "PlayerRemoving", require("./Signals").ForInstance(Service, "PlayerRemoving"))
	setProp(Service, "MaxPlayers", 32)
	setProp(Service, "NumPlayers", 1)
	setProp(Service, "PreferredPlayers", 0)
	setProp(Service, "MaxPlayersInternal", 32)
end

local function seedSoundService(Service)
	setProp(Service, "RolloffScale", 1)
end

local function seedDebris(Service)
	setPropIfMissing(Service, "LegacyMaxItems", false)
end

local function seedStats(Service)
	setPropIfMissing(Service, "HeartbeatTime", RuntimeClock.GetFrameDelta())
	setPropIfMissing(Service, "HeartbeatTimeMs", RuntimeClock.GetFrameDelta() * 1000)
	setPropIfMissing(Service, "TotalMemoryUsageMb", 512)
end

local function seedTextChatService(Service)
	local SignalLib = require("./Signals")
	setPropIfMissing(Service, "MessageReceived", SignalLib.ForInstance(Service, "MessageReceived"))
	setPropIfMissing(Service, "SendingMessage", SignalLib.ForInstance(Service, "SendingMessage"))
	setPropIfMissing(Service, "OnIncomingMessageEvent", SignalLib.ForInstance(Service, "OnIncomingMessageEvent"))

	local TextChannels = Service:GetRawProperty("TextChannels")
	if not isInstance(TextChannels) then
		TextChannels = ensureChild(Service, "Folder", "TextChannels")
		setProp(Service, "TextChannels", TextChannels)
	end

	local General = TextChannels:FindFirstChild("RBXGeneral")
	if General == nil then
		General = ensureChild(TextChannels, "TextChannel", "RBXGeneral")
	end
end

local function seedServiceDefaults(Name, Inst)
	if Name == "RunService" then
		seedRunService(Inst)
	elseif Name == "Workspace" then
		seedWorkspace(Inst)
	elseif Name == "UserInputService" then
		seedUserInputService(Inst)
	elseif Name == "CoreGui" then
		seedCoreGui(Inst)
	elseif Name == "Lighting" then
		seedLighting(Inst)
	elseif Name == "Players" then
		seedPlayers(Inst)
	elseif Name == "SoundService" then
		seedSoundService(Inst)
	elseif Name == "Debris" then
		seedDebris(Inst)
	elseif Name == "Stats" then
		seedStats(Inst)
	elseif Name == "TextChatService" then
		seedTextChatService(Inst)
	end
end

local function seedWorkspaceShell(Workspace)
	local Terrain = Workspace:FindFirstChild("Terrain")
	if Terrain == nil then
		Terrain = ensureChild(Workspace, "Terrain", "Terrain")
	end
	setPropIfMissing(Terrain, "Anchored", true)
	setPropIfMissing(Terrain, "CanCollide", true)

	local Baseplate = Workspace:FindFirstChild("Baseplate")
	if Baseplate == nil then
		Baseplate = ensureChild(Workspace, "Part", "Baseplate")
	end
	setPropIfMissing(Baseplate, "Anchored", true)
	setPropIfMissing(Baseplate, "CanCollide", true)
	setPropIfMissing(Baseplate, "Size", makeVector3(512, 20, 512))
	setPropIfMissing(Baseplate, "Position", makeVector3(0, -10, 0))
end

local function ensureBodyPart(Character, PartName, Position, Size, Transparent)
	local Part = ensureChild(Character, "Part", PartName)
	setPropIfMissing(Part, "Anchored", false)
	setPropIfMissing(Part, "CanCollide", true)
	setPropIfMissing(Part, "Position", Position)
	setPropIfMissing(Part, "Size", Size)
	setPropIfMissing(Part, "Transparency", Transparent and 1 or 0)
	return Part
end

local function ensureAnimationTrack(Animator)
	local Tracks = Animator:GetRawProperty("_LarryPlayingAnimationTracks")
	if typeof(Tracks) ~= "table" then
		Tracks = {}
		Animator:SetProperty("_LarryPlayingAnimationTracks", Tracks)
	end

	if #Tracks > 0 then
		return Tracks[1]
	end

	local Animation = createInternalInstance("Animation", "IdleAnimation")
	setProp(Animation, "AnimationId", "rbxassetid://507766388")

	local Track = createInternalInstance("AnimationTrack", "Idle")
	setProp(Track, "Animation", Animation)
	setProp(Track, "IsPlaying", true)
	setProp(Track, "Length", 1)
	setProp(Track, "Looped", true)
	setProp(Track, "Priority", enumItem("AnimationPriority", "Core") or "Core")
	setProp(Track, "Speed", 1)
	setProp(Track, "WeightCurrent", 1)
	setProp(Track, "WeightTarget", 1)

	Tracks[1] = Track
	return Track
end

local function ensureAnimator(Humanoid)
	local Animator = Humanoid:FindFirstChild("Animator")
	if Animator == nil then
		Animator = ensureChild(Humanoid, "Animator", "Animator")
	end

	ensureAnimationTrack(Animator)
	return Animator
end

local function ensureHumanoid(Character)
	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid == nil then
		Humanoid = ensureChild(Character, "Humanoid", "Humanoid")
	end

	setProp(Humanoid, "Health", 100)
	setProp(Humanoid, "MaxHealth", 100)
	setProp(Humanoid, "WalkSpeed", 16)
	setProp(Humanoid, "JumpPower", 50)
	setProp(Humanoid, "HealthDisplayDistance", 100)
	setProp(Humanoid, "NameDisplayDistance", 100)
	setProp(Humanoid, "AutoRotate", true)
	setProp(Humanoid, "RigType", enumItem("HumanoidRigType", "R6") or "R6")
	setPropIfMissing(Humanoid, "DisplayDistanceType", enumItem("HumanoidDisplayDistanceType", "Viewer") or "Viewer")
	setPropIfMissing(Humanoid, "Jump", false)

	local Head = ensureBodyPart(Character, "Head", makeVector3(0, 6, 0), makeVector3(2, 1, 1), false)
	local Torso = ensureBodyPart(Character, "Torso", makeVector3(0, 4, 0), makeVector3(2, 2, 1), false)
	ensureBodyPart(Character, "Left Arm", makeVector3(-1.5, 4, 0), makeVector3(1, 2, 1), false)
	ensureBodyPart(Character, "Right Arm", makeVector3(1.5, 4, 0), makeVector3(1, 2, 1), false)
	ensureBodyPart(Character, "Left Leg", makeVector3(-0.5, 2, 0), makeVector3(1, 2, 1), false)
	ensureBodyPart(Character, "Right Leg", makeVector3(0.5, 2, 0), makeVector3(1, 2, 1), false)
	local RootPart = ensureBodyPart(Character, "HumanoidRootPart", makeVector3(0, 3, 0), makeVector3(2, 2, 1), true)

	setProp(RootPart, "Anchored", false)
	setProp(RootPart, "CanCollide", true)
	setProp(RootPart, "Velocity", makeVector3(0, 0, 0))
	setProp(RootPart, "AssemblyLinearVelocity", makeVector3(0, 0, 0))
	setProp(Character, "PrimaryPart", RootPart)
	setProp(Character, "WorldPivot", makeCFrame(0, 3, 0))
	setPropIfMissing(Character, "Archivable", true)

	ensureAnimator(Humanoid)

	return {
		Humanoid = Humanoid,
		Head = Head,
		Torso = Torso,
		RootPart = RootPart,
	}
end

local function ensureCoreGuiModules(CoreGui)
	local RobloxGui = CoreGui:FindFirstChild("RobloxGui") or ensureChild(CoreGui, "ScreenGui", "RobloxGui")
	local Modules = RobloxGui:FindFirstChild("Modules") or ensureChild(RobloxGui, "Folder", "Modules")
	local Common = Modules:FindFirstChild("Common") or ensureChild(Modules, "Folder", "Common")
	local Constants = Common:FindFirstChild("Constants") or ensureChild(Common, "ModuleScript", "Constants")
	setProp(Constants, "Source", "return {Modules = {Common = true}, Flags = {Ready = true}, Version = '1.0.0'}")
	return Constants
end

local function ensurePlayerWorld()
	local Players = ensureService("Players", "Players")
	local Workspace = ensureService("Workspace", "Workspace")
	local Teams = ensureService("Teams", "Teams")
	local CoreGui = ensureService("CoreGui", "CoreGui")
	local StarterPlayer = ensureService("StarterPlayer", "StarterPlayer")
	local ReplicatedStorage = ensureService("ReplicatedStorage", "ReplicatedStorage")
	local ReplicatedFirst = ensureService("ReplicatedFirst", "ReplicatedFirst")
	local ServerStorage = ensureService("ServerStorage", "ServerStorage")
	local ServerScriptService = ensureService("ServerScriptService", "ServerScriptService")
	local StarterGui = ensureService("StarterGui", "StarterGui")
	local StarterPack = ensureService("StarterPack", "StarterPack")
	local Chat = ensureService("Chat", "Chat")
	local TextChatService = ensureService("TextChatService", "TextChatService")
	local SoundService = ensureService("SoundService", "SoundService")
	local PhysicsService = ensureService("PhysicsService", "PhysicsService")
	local TestService = ensureService("TestService", "TestService")

	seedServiceDefaults("Players", Players)
	seedServiceDefaults("Workspace", Workspace)
	seedServiceDefaults("CoreGui", CoreGui)
	seedServiceDefaults("SoundService", SoundService)
	seedServiceDefaults("TextChatService", TextChatService)

	local NeutralTeam = Teams:FindFirstChild("Players") or ensureChild(Teams, "Team", "Players")
	setPropIfMissing(NeutralTeam, "TeamColor", "Bright blue")

	local LocalPlayer = Players:GetRawProperty("LocalPlayer")
	if not isInstance(LocalPlayer) then
		materializeChildren(Players)
		for _, Child in ipairs(Players:GetChildren()) do
			if Child:IsA("Player") then
				LocalPlayer = Child
				break
			end
		end
	end
	if LocalPlayer == nil then
		LocalPlayer = ensureChild(Players, "Player", "LocalPlayer")
	end

	setProp(Players, "LocalPlayer", LocalPlayer)
	setPropIfMissing(LocalPlayer, "UserId", 2235582)
	setPropIfMissing(LocalPlayer, "DisplayName", "God")
	setPropIfMissing(LocalPlayer, "AccountAge", 214)
	setProp(LocalPlayer, "Neutral", true)
	setProp(LocalPlayer, "Team", NeutralTeam)
	setProp(LocalPlayer, "TeamColor", "Bright blue")

	local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts") or ensureChild(LocalPlayer, "PlayerScripts", "PlayerScripts")
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or ensureChild(LocalPlayer, "PlayerGui", "PlayerGui")
	local Backpack = LocalPlayer:FindFirstChild("Backpack") or ensureChild(LocalPlayer, "Backpack", "Backpack")
	local StarterGear = LocalPlayer:FindFirstChild("StarterGear") or ensureChild(LocalPlayer, "StarterGear", "StarterGear")

	local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts") or ensureChild(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts")
	local StarterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts") or ensureChild(StarterPlayer, "StarterCharacterScripts", "StarterCharacterScripts")
	local StarterControlScript = StarterPlayerScripts:FindFirstChild("ControlScript") or ensureChild(StarterPlayerScripts, "LocalScript", "ControlScript")
	setPropIfMissing(StarterControlScript, "Source", "return {}")
	local StarterPlayerModule = StarterPlayerScripts:FindFirstChild("PlayerModule") or ensureChild(StarterPlayerScripts, "ModuleScript", "PlayerModule")
	setPropIfMissing(StarterPlayerModule, "Source", "return {}")

	if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") == nil then
		local DefaultChat = ensureChild(ReplicatedStorage, "Folder", "DefaultChatSystemChatEvents")
		ensureChild(DefaultChat, "RemoteEvent", "OnMessageDoneFiltering")
		ensureChild(DefaultChat, "RemoteEvent", "OnNewMessage")
		ensureChild(DefaultChat, "RemoteEvent", "SetBlockedUserIdsRequest")
	end
	if ReplicatedStorage:FindFirstChild("RobloxPlaceResource") == nil then
		ensureChild(ReplicatedStorage, "Folder", "RobloxPlaceResource")
	end

	local Character = LocalPlayer:GetRawProperty("Character")
	if not isInstance(Character) then
		materializeChildren(Workspace)
		Character = Workspace:FindFirstChild(LocalPlayer:GetName())
		if Character == nil then
			Character = Workspace:FindFirstChild("Character")
		end
	end
	if Character == nil then
		Character = ensureChild(Workspace, "Model", LocalPlayer:GetName())
	end
	if Character:GetParent() ~= Workspace then
		Character:SetParent(Workspace)
	end

	setProp(LocalPlayer, "PlayerScripts", PlayerScripts)
	setProp(LocalPlayer, "PlayerGui", PlayerGui)
	setProp(LocalPlayer, "Backpack", Backpack)
	setProp(LocalPlayer, "StarterGear", StarterGear)
	setProp(LocalPlayer, "Character", Character)
	setPropIfMissing(LocalPlayer, "CharacterAppearanceId", LocalPlayer.UserId)

	local Animate = Character:FindFirstChild("Animate") or ensureChild(Character, "LocalScript", "Animate")
	setProp(Animate, "Source", "return {idle = true}")
	local RbxCharacterSounds = PlayerScripts:FindFirstChild("RbxCharacterSounds") or ensureChild(PlayerScripts, "LocalScript", "RbxCharacterSounds")
	setPropIfMissing(RbxCharacterSounds, "Source", "return {}")
	local AtomicBinding = RbxCharacterSounds:FindFirstChild("AtomicBinding") or ensureChild(RbxCharacterSounds, "Folder", "AtomicBinding")
	setProp(AtomicBinding, "Archivable", true)
	local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule") or ensureChild(PlayerScripts, "ModuleScript", "PlayerModule")
	setProp(PlayerModule, "Source", "return {CameraModule = {}}")
	local CameraModuleFolder = PlayerScripts:FindFirstChild("PlayerModuleScripts") or ensureChild(PlayerScripts, "Folder", "PlayerModuleScripts")
	local ClassicCamera = CameraModuleFolder:FindFirstChild("ClassicCamera") or ensureChild(CameraModuleFolder, "LocalScript", "ClassicCamera")
	setPropIfMissing(ClassicCamera, "Source", "return {}")
	local Invisicam = CameraModuleFolder:FindFirstChild("Invisicam") or ensureChild(CameraModuleFolder, "ModuleScript", "Invisicam")
	setPropIfMissing(Invisicam, "Source", "return {}")
	StarterCharacterScripts:SetProperty("_LarrySeeded", true)
	StarterPlayerScripts:SetProperty("_LarrySeeded", true)

	local Rig = ensureHumanoid(Character)
	ensureCoreGuiModules(CoreGui)

	return {
		Player = LocalPlayer,
		Workspace = Workspace,
		Character = Character,
		Humanoid = Rig.Humanoid,
		RootPart = Rig.RootPart,
		Head = Rig.Head,
		Animate = Animate,
	}
end

local function ensureCurrentCamera(World)
	local Workspace = World.Workspace
	materializeChildren(Workspace)

	local Camera = Workspace:GetRawProperty("CurrentCamera")
	if not isInstance(Camera) then
		Camera = Workspace:FindFirstChild("Camera")
	end
	if Camera == nil then
		Camera = ensureChild(Workspace, "Camera", "Camera")
	end

	local RootPosition = World.RootPart:GetRawProperty("Position") or makeVector3(0, 3, 0)
	local CameraCFrame = makeCFrame(
		(tonumber(RootPosition.X) or 0) + 7,
		(tonumber(RootPosition.Y) or 0) + 6,
		(tonumber(RootPosition.Z) or 0) - 12
	)
	local Focus = makeCFrame(
		tonumber(RootPosition.X) or 0,
		(tonumber(RootPosition.Y) or 0) + 2,
		tonumber(RootPosition.Z) or 0
	)

	setProp(Workspace, "CurrentCamera", Camera)
	setProp(Camera, "NearPlaneZ", -0.1)
	setProp(Camera, "FarPlaneZ", 10000)
	setProp(Camera, "FieldOfView", 70)
	setProp(Camera, "CameraType", enumItem("CameraType", "Custom") or "Custom")
	setProp(Camera, "CameraSubject", World.Humanoid)
	setProp(Camera, "ViewportSize", makeVector2(1920, 1080))
	setProp(Camera, "CFrame", CameraCFrame)
	setProp(Camera, "Focus", Focus)
end

local function createSnapshotServices()

end

local function createFallbackServices()
	for Name, ClassName in next, EssentialServices do
		local Service = ensureService(Name, ClassName)
		seedServiceDefaults(Name, Service)
	end
end

local function attachDataModel(Config)
	RuntimeClock.Reset()

	local SpoofedPlaceId = ResolveSpoofedId(Config and Config.placeid, "placeid")
	local SpoofedGameId = ResolveSpoofedId(Config and Config.gameid, "gameid")
	local PlaceId = SpoofedPlaceId or GenerateDataModelId()
	local GameId = SpoofedGameId or GenerateDataModelId()

	if SpoofedPlaceId == nil or SpoofedGameId == nil then
		while PlaceId == GameId do
			if SpoofedPlaceId == nil then
				PlaceId = GenerateDataModelId()
			else
				GameId = GenerateDataModelId()
			end
		end
	end

	GameRoot = createInternalInstance("DataModel", "Game")
	GameRoot._VarName = "game"
	setProp(GameRoot, "PlaceId", PlaceId)
	setProp(GameRoot, "GameId", GameId)
	setProp(GameRoot, "DataCost", 0)
	setProp(GameRoot, "JobId", require("../Utils/Identity").Generate(32))
	registerInternal(GameRoot, "game")
end

local function pickScriptInstance(World)
	local Script = World.Animate or World.Player:FindFirstChild("PlayerScripts")
	if Script ~= nil and isInstance(Script) then
		return Script
	end

	local PlayerScripts = World.Player:FindFirstChild("PlayerScripts") or ensureChild(World.Player, "PlayerScripts", "PlayerScripts")
	return ensureChild(PlayerScripts, "LocalScript", "PlayerScriptsLoader")
end

function Hierarchy.Init(Proxy, State, Emitter, Beautifier, Scope, Config)
	Runtime.Proxy = Proxy
	Runtime.State = State
	Runtime.Emitter = Emitter
	Runtime.Beautifier = Beautifier
	Runtime.Scope = Scope

	table.clear(ServiceMap)
	table.clear(NilInstances)
	table.clear(NilInstanceSet)
	table.clear(TolerantPaths)

	attachDataModel(Config)
	createSnapshotServices()
	createFallbackServices()
	seedWorkspaceShell(ensureService("Workspace", "Workspace"))

	local World = ensurePlayerWorld()
	ensureCurrentCamera(World)

	ScriptInstance = pickScriptInstance(World)
	registerInternal(ScriptInstance, "script")
	refreshPaths(GameRoot, "game")

	return GameRoot, ScriptInstance
end

function Hierarchy.GetRoot()
	return GameRoot
end

function Hierarchy.GetScriptInstance()
	return ScriptInstance
end

function Hierarchy.GetService(Name)
	return ServiceMap[Name]
end

function Hierarchy.RegisterService(Name, Inst)
	ServiceMap[Name] = Inst
	if GameRoot then
		if isInstance(Inst) and Inst:GetParent() ~= GameRoot then
			Inst:SetParent(GameRoot)
		end
		registerInternal(Inst, `game.{Name}`)
	end
end

function Hierarchy.AddNilInstance(Inst)
	if not isInstance(Inst) or NilInstanceSet[Inst] then
		return
	end
	NilInstanceSet[Inst] = true
	NilInstances[#NilInstances + 1] = Inst
end

function Hierarchy.GetNilInstances()
	local Copy = {}
	for I, Inst in ipairs(NilInstances) do
		Copy[I] = Inst
	end
	return Copy
end

function Hierarchy.SetTolerant(Path)
	if typeof(Path) == "string" and Path ~= "" then
		TolerantPaths[Path] = true
	end
end

function Hierarchy.IsTolerant(Path)
	return TolerantPaths[Path] == true
end

function Hierarchy.Resolve(Root, Path)
	local Parts
	if typeof(Path) == "string" then
		Parts = string.split(Path, ".")
	elseif typeof(Path) == "table" then
		Parts = Path
	else
		return nil
	end

	local Current = Root or GameRoot

	for _, Part in ipairs(Parts) do
		if Current == nil or typeof(Current) ~= "table" then
			return nil
		end

		materializeChildren(Current)

		local Prop = nil
		local OkProp, PropResult = pcall(function()
			return Current[Part]
		end)
		if OkProp then
			Prop = PropResult
		end
		if Prop ~= nil then
			Current = Prop
			continue
		end

		local Child = Current:FindFirstChild(Part)
		if Child ~= nil then
			Current = Child
			continue
		end

		local Service = ServiceMap[Part]
		if Service ~= nil and Current == GameRoot then
			Current = Service
			continue
		end

		local FullPath = (typeof(Current.GetName) == "function" and Current:GetName() or "game") .. "." .. Part
		if TolerantPaths[FullPath] or TolerantPaths[Part] then
			return nil
		end

		return nil
	end

	return Current
end

function Hierarchy.ResolveOrError(Root, Part, SpyFallback)
	local Result = Hierarchy.Resolve(Root, { Part })
	if Result ~= nil then
		return Result
	end
	if SpyFallback then
		return nil, true
	end
	return nil, false
end

function Hierarchy.GetAllInstances()
	if GameRoot == nil then
		return Instance.GetCreated()
	end

	materializeTree(GameRoot)
	return Instance.GetCreated()
end

function Hierarchy.GetScripts()
	local Result = {}
	for _, Inst in ipairs(Hierarchy.GetAllInstances()) do
		local Class = Inst:GetClassName()
		if Class == "LocalScript" or Class == "ModuleScript" or Class == "Script" then
			Result[#Result + 1] = Inst
		end
	end
	return Result
end

function Hierarchy.GetLoadedModules()
	local Result = {}
	for _, Inst in ipairs(Hierarchy.GetAllInstances()) do
		if Inst:GetClassName() == "ModuleScript" then
			Result[#Result + 1] = Inst
		end
	end
	return Result
end

function Hierarchy.MaterializeChildren(Inst)
	materializeChildren(Inst)
end

function Hierarchy.MaterializeTree(Inst)
	materializeTree(Inst or GameRoot)
end

return Hierarchy