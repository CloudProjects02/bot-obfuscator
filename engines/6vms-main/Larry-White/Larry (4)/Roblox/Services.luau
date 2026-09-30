local Instance = require("./Instance")
local Hierarchy = require("./Hierarchy")
local Properties = require("./Properties")
local Signals = require("./Signals")
local ApiDumpIndex = require("./ApiCatalog")

local Services = {}

local ServiceDefinitions = {
	Workspace = { ClassName = "Workspace" },
	Players = { ClassName = "Players" },
	ReplicatedStorage = { ClassName = "ReplicatedStorage" },
	ReplicatedFirst = { ClassName = "ReplicatedFirst" },
	ServerStorage = { ClassName = "ServerStorage" },
	ServerScriptService = { ClassName = "ServerScriptService" },
	StarterGui = { ClassName = "StarterGui" },
	StarterPack = { ClassName = "StarterPack" },
	StarterPlayer = { ClassName = "StarterPlayer" },
	StarterPlayerScripts = { ClassName = "StarterPlayerScripts" },
	StarterCharacterScripts = { ClassName = "StarterCharacterScripts" },
	Lighting = { ClassName = "Lighting" },
	SoundService = { ClassName = "SoundService" },
	TweenService = { ClassName = "TweenService" },
	RunService = { ClassName = "RunService" },
	UserInputService = { ClassName = "UserInputService" },
	HttpService = { ClassName = "HttpService" },
	EncodingService = { ClassName = "EncodingService" },
	MarketplaceService = { ClassName = "MarketplaceService" },
	TeleportService = { ClassName = "TeleportService" },
	TextChatService = { ClassName = "TextChatService" },
	CoreGui = { ClassName = "CoreGui" },
	GuiService = { ClassName = "GuiService" },
	PathfindingService = { ClassName = "PathfindingService" },
	PhysicsService = { ClassName = "PhysicsService" },
	CollectionService = { ClassName = "CollectionService" },
	ContextActionService = { ClassName = "ContextActionService" },
	VirtualInputManager = { ClassName = "VirtualInputManager" },
	ContentProvider = { ClassName = "ContentProvider" },
	LocalizationService = { ClassName = "LocalizationService" },
	PolicyService = { ClassName = "PolicyService" },
	RbxAnalyticsService = { ClassName = "RbxAnalyticsService" },
	LogService = { ClassName = "LogService" },
	StatsService = { ClassName = "StatsService" },
	Chat = { ClassName = "Chat" },
	Teams = { ClassName = "Teams" },
	ProximityPromptService = { ClassName = "ProximityPromptService" },
	MaterialService = { ClassName = "MaterialService" },
	NetworkClient = { ClassName = "NetworkClient" },
	TestService = { ClassName = "TestService" },
	VRService = { ClassName = "VRService" },
	BadgeService = { ClassName = "BadgeService" },
	GamePassService = { ClassName = "GamePassService" },
	InsertService = { ClassName = "InsertService" },
	KeyframeSequenceProvider = { ClassName = "KeyframeSequenceProvider" },
	MemoryStoreService = { ClassName = "MemoryStoreService" },
	MessagingService = { ClassName = "MessagingService" },
	DataStoreService = { ClassName = "DataStoreService" },
	Debris = { ClassName = "Debris" },
	Stats = { ClassName = "Stats" },
	Settings = { ClassName = "Settings" },
	SocialService = { ClassName = "SocialService" },
	GroupService = { ClassName = "GroupService" },
	AnimationClipProvider = { ClassName = "AnimationClipProvider" },
	HapticService = { ClassName = "HapticService" },
	AvatarEditorService = { ClassName = "AvatarEditorService" },
	AchievementService = { ClassName = "AchievementService" },
	PlayerViewService = { ClassName = "PlayerViewService" },
	AppLifecycleObserverService = { ClassName = "AppLifecycleObserverService" },
	HttpRbxApiService = { ClassName = "HttpRbxApiService" },
	RobloxReplicatedStorage = { ClassName = "RobloxReplicatedStorage" },
	ScriptContext = { ClassName = "ScriptContext" },
	CorePackages = { ClassName = "CorePackages" },
}

local BlockedServiceNames = {
	DebuggerManager = true,
}

local ValidNames = {}
local ServiceClassNames = {}
for Name in next, ServiceDefinitions do
	ValidNames[Name] = true
	local Def = ServiceDefinitions[Name]
	if Def and Def.ClassName then
		ServiceClassNames[Def.ClassName] = true
	end
end

local LazyCreated = {}
local StatsDefaults = {
	ContactsCount = 12,
	DataReceiveKbps = 128.4,
	DataSendKbps = 32.7,
	FrameTime = 0.016,
	HeartbeatTime = 0.016,
	HeartbeatTimeMs = 16.0,
	InstanceCount = 2048,
	MemoryTrackingEnabled = true,
	MovingPrimitivesCount = 14,
	PhysicsReceiveKbps = 12.5,
	PhysicsSendKbps = 8.3,
	PhysicsStepTime = 0.004,
	PhysicsStepTimeMs = 4.0,
	PrimitivesCount = 160,
	RenderCPUFrameTime = 0.006,
	RenderGPUFrameTime = 0.005,
	SceneDrawcallCount = 220,
	SceneTriangleCount = 42000,
	ShadowsDrawcallCount = 18,
	ShadowsTriangleCount = 9000,
	UI2DDrawcallCount = 30,
	UI2DTriangleCount = 4200,
	UI3DDrawcallCount = 7,
	UI3DTriangleCount = 1200,
}

local function SeedCoreGui(Inst)
	if #Inst._Children > 0 then
		return
	end

	for I = 1, 60 do
		local Child = Instance._new(
			"Frame", {},
			Services._Proxy, Services._State,
			Services._Emitter, Services._Beautifier,
			Services._Scope,
			true
		)
		Child._Name = `CoreGuiDescendant{I}`
		Child:SetParent(Inst)
	end
end

local function BuildSettingsRendering()
	local PreferredItem = "Automatic"
	if ApiDumpIndex and typeof(ApiDumpIndex.GetFirstEnumItem) == "function" then
		local First = ApiDumpIndex.GetFirstEnumItem("QualityLevel")
		if typeof(First) == "string" and First ~= "" then
			PreferredItem = First
		end
	end

	local Enums = nil
	pcall(function()
		Enums = require("./Enums")
	end)

	if Enums and typeof(Enums.Get) == "function" then
		local EnumItem = Enums.Get("QualityLevel", PreferredItem)
			or Enums.Get("QualityLevel", "Automatic")
		if EnumItem ~= nil then
			return {
				QualityLevel = EnumItem,
			}
		end
	end

	return {
		QualityLevel = PreferredItem,
	}
end

function Services.Init(Proxy, State, Emitter, Beautifier, Scope)
	Services._Proxy = Proxy
	Services._State = State
	Services._Emitter = Emitter
	Services._Beautifier = Beautifier
	Services._Scope = Scope

	for _, DumpService in next, ApiDumpIndex.GetServiceLikeClasses() do
		if not ServiceDefinitions[DumpService] then
			Services.RegisterCustom(DumpService, DumpService)
		end
	end
end

function Services.IsValid(Name)
	if BlockedServiceNames[Name] then
		return false
	end
	return ValidNames[Name] == true
end

function Services.Get(Name)
	if typeof(Name) ~= "string" or Name == "" then
		return nil
	end

	if BlockedServiceNames[Name] then
		return nil
	end

	local Existing = Hierarchy.GetService(Name)
	if Existing then return Existing end

	if not ValidNames[Name] then
		return nil
	end

	if LazyCreated[Name] then return LazyCreated[Name] end

	local Def = ServiceDefinitions[Name]
	local Inst = Instance._new(
		Def.ClassName, {},
		Services._Proxy, Services._State,
		Services._Emitter, Services._Beautifier,
		Services._Scope,
		true
	)

	Inst._Name = Name
	Inst._VarName = Name
	Hierarchy.RegisterService(Name, Inst)
	LazyCreated[Name] = Inst
	if Services._State then
		Services._State:RegisterInternal(Inst, Name)
	end

	if Name == "RunService" then
		local HeartbeatSignal = Signals.ForInstance(Inst, "Heartbeat")
		Inst._Properties["Heartbeat"] = HeartbeatSignal
		Inst._Properties["RenderStepped"] = Signals.ForInstance(Inst, "RenderStepped")
		Inst._Properties["Stepped"] = Signals.ForInstance(Inst, "Stepped")
		Inst._Properties["ClientGitHash"] = string.rep("0", 40)
		Inst._Properties["RunState"] = "Running"
		Inst._Properties["IsRunning"] = true
	end

	if Name == "TextChatService" then
		Inst._Properties["MessageReceived"] = Signals.ForInstance(Inst, "MessageReceived")
		Inst._Properties["SendingMessage"] = Signals.ForInstance(Inst, "SendingMessage")
		Inst._Properties["OnIncomingMessageEvent"] = Signals.ForInstance(Inst, "OnIncomingMessageEvent")

		local TextChannels = Instance._new(
			"Folder", {},
			Services._Proxy, Services._State,
			Services._Emitter, Services._Beautifier,
			Services._Scope,
			true
		)
		TextChannels._Name = "TextChannels"
		TextChannels:SetParent(Inst)

		local RbxGeneral = Instance._new(
			"TextChannel", {},
			Services._Proxy, Services._State,
			Services._Emitter, Services._Beautifier,
			Services._Scope,
			true
		)
		RbxGeneral._Name = "RBXGeneral"
		RbxGeneral:SetParent(TextChannels)

		Inst._Properties["TextChannels"] = TextChannels
	end

	if Name == "Workspace" then
		Inst._Properties["NumAwakeParts"] = 8
		Inst._Properties["RealPhysicsFPS"] = 60
		Inst._Properties["ServerTimeBias"] = 0
	end

	if Name == "CoreGui" then
		Inst._Properties["Version"] = 0
		SeedCoreGui(Inst)
	end

	if Name == "Players" then
		Inst._Properties["PlayerAdded"] = Signals.ForInstance(Inst, "PlayerAdded")
		Inst._Properties["PlayerRemoving"] = Signals.ForInstance(Inst, "PlayerRemoving")
		Inst._Properties["MaxPlayers"] = 32
		Inst._Properties["NumPlayers"] = 1
	end

	if Name == "UserInputService" then
		Inst._Properties["TouchEnabled"] = false
		Inst._Properties["KeyboardEnabled"] = true
		Inst._Properties["MouseEnabled"] = true
		Inst._Properties["GamepadEnabled"] = false
		Inst._Properties["AccelerometerEnabled"] = false
		Inst._Properties["GyroscopeEnabled"] = false
		Inst._Properties["VREnabled"] = false
		Inst._Properties["MouseIcon"] = "rbxasset://textures/cursor.png"
		Inst._Properties["MouseIconEnabled"] = true
	end

	if Name == "Lighting" then
		Inst._Properties["Ambient"] = {R = 0, G = 0, B = 0, __larryType = "Color3"}
		Inst._Properties["OutdoorAmbient"] = {R = 0.5, G = 0.5, B = 0.5, __larryType = "Color3"}
		Inst._Properties["Brightness"] = 1
		Inst._Properties["ClockTime"] = 12
		Inst._Properties["FogColor"] = {R = 0.5, G = 0.5, B = 0.5, __larryType = "Color3"}
		Inst._Properties["FogStart"] = 0
		Inst._Properties["FogEnd"] = 100000
		Inst._Properties["GeographicLatitude"] = 41
		Inst._Properties["TimeOfDay"] = "12:00:00"
		Inst._Properties["GlobalShadows"] = true
	end

	if Name == "SoundService" then
		Inst._Properties["RolloffScale"] = 1
	end

	if Name == "LocalizationService" then
		Inst._Properties["RobloxLocaleId"] = "en-us"
		Inst._Properties["SystemLocaleId"] = "en-us"
	end

	if Name == "Stats" then
		for Prop, Value in next, StatsDefaults do
			Inst._Properties[Prop] = Value
		end
		Inst._Properties["TotalMemoryUsageMb"] = 512
	end

	if Name == "StatsService" then
		Inst._Properties["TotalMemoryUsageMb"] = 512
	end

	if Name == "Debris" then
		Inst._Properties["LegacyMaxItems"] = false
	end

	if Name == "Settings" then
		Inst._Properties["Rendering"] = BuildSettingsRendering()
	end

	if Name == "LogService" then
		Inst._Properties["MessageOut"] = Signals.ForInstance(Inst, "MessageOut")
		Inst._Properties["_History"] = {}
	end

	if Name == "ScriptContext" then
		Inst._Properties["Error"] = Signals.ForInstance(Inst, "Error")
		Inst._Properties["ErrorDetailed"] = Signals.ForInstance(Inst, "ErrorDetailed")
	end

	if Name == "AchievementService" then
		Inst._Properties["ClassName"] = "AchievementService"
		Inst._Properties["IsAvailable"] = function()
			return true
		end
		Inst._Properties["HasAchieved"] = function(_, _)
			return false
		end
		Inst._Properties["GrantAchievement"] = function(_, _)
			return nil
		end
	end

	if Name == "PlayerViewService" then
		Inst._Properties["ClassName"] = "PlayerViewService"
		Inst._Properties["GetDeviceCameraCFrame"] = function()
			local CFrame = require("./DataTypes").Get("CFrame")
			if CFrame and CFrame.new then
				return CFrame.new(0, 0, 0)
			end
			return {__larryType = "CFrame"}
		end
		Inst._Properties["GetDeviceCameraCFrameForSelfView"] = function()
			local CFrame = require("./DataTypes").Get("CFrame")
			if CFrame and CFrame.new then
				return CFrame.new(0, 0, 0)
			end
			return {__larryType = "CFrame"}
		end
		Inst._Properties["UpdateDeviceCFrame"] = function(_, _)
			return nil
		end
	end

	if Name == "AppLifecycleObserverService" then
		Inst._Properties["ClassName"] = "AppLifecycleObserverService"
	end

	if Name == "HttpRbxApiService" then
		Inst._Properties["ClassName"] = "HttpRbxApiService"
	end

	if Name == "RobloxReplicatedStorage" then
		Inst._Properties["ClassName"] = "RobloxReplicatedStorage"
	end

	if Name == "CorePackages" then
		Inst._Properties["ClassName"] = "CorePackages"
		local Folder = require("./Instance")._new(
			"Folder", {},
			Services._Proxy, Services._State,
			Services._Emitter, Services._Beautifier,
			Services._Scope,
			true
		)
		Folder._Name = "CorePackages"
		Folder:SetParent(Inst)
	end

	return Inst
end

function Services.GetOrNil(Name)
	return Services.Get(Name)
end

function Services.FindService(Name)
	if typeof(Name) ~= "string" or Name == "" then
		return nil
	end

	if BlockedServiceNames[Name] then
		return nil
	end

	local Existing = Hierarchy.GetService(Name) or LazyCreated[Name]
	if Existing ~= nil then
		return Existing
	end

	if ValidNames[Name] then
		return Services.Get(Name)
	end

	return nil
end

function Services.GetAllNames()
	local Names = {}
	for Name in next, ServiceDefinitions do
		if BlockedServiceNames[Name] then
			continue
		end
		table.insert(Names, Name)
	end
	table.sort(Names)
	return Names
end

function Services.IsServiceClass(ClassName)
	if ServiceClassNames[ClassName] then
		return true
	end

	if ApiDumpIndex.IsServiceClass(ClassName) then
		return true
	end

	return string.match(ClassName, "Service$") ~= nil
end

function Services.RegisterCustom(Name, ClassName)
	ServiceDefinitions[Name] = { ClassName = ClassName or Name }
	ValidNames[Name] = true
	ServiceClassNames[ClassName or Name] = true
end

return Services