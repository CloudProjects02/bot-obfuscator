local StringUtil = require("../../Utils/String")
local IdentityUtil = require("../../Utils/Identity")
local Properties = require("../Properties")
local Signals = require("../Signals")
local Methods = require("../Methods")
local ApiDumpIndex = require("../ApiCatalog")

local Instance = {}

local CreatedInstances = {}
local InstanceCounter = 0
local TagRegistry = {}
local BlockedClasses = { DataModel = true }
local NonCreatableClasses = {
	Workspace = true,
	Terrain = true,
	Status = true,
	RunService = true,
	GuiService = true,
	ScreenshotHud = true,
	Stats = true,
	StatsItem = true,
	RunningAverageItemInt = true,
	TotalCountTimeIntervalItem = true,
	RunningAverageItemDouble = true,
	TimerService = true,
	SoundService = true,
	VideoCaptureService = true,
	LogService = true,
	MicroProfilerService = true,
	ContentProvider = true,
	KeyframeSequenceProvider = true,
	AnimationClipProvider = true,
	Chat = true,
	MarketplaceService = true,
	Players = true,
	PlayerScripts = true,
	PlayerGui = true,
	PointsService = true,
	NotificationService = true,
	ReplicatedFirst = true,
	HttpRbxApiService = true,
	TweenService = true,
	MaterialService = true,
	TextChatService = true,
	ChatWindowConfiguration = true,
	ChatInputBarConfiguration = true,
	BubbleChatConfiguration = true,
	ChannelTabsConfiguration = true,
	TextSource = true,
	TextService = true,
	PlayerEmulatorService = true,
	CorePackages = true,
	StudioData = true,
	SharedTableRegistry = true,
	StarterPlayer = true,
	StarterPlayerScripts = true,
	StarterCharacterScripts = true,
	StarterPack = true,
	StarterGui = true,
	CoreGui = true,
	CoreScript = true,
	LocalizationService = true,
	CloudLocalizationTable = true,
	PolicyService = true,
	TeleportService = true,
	JointsService = true,
	CollectionService = true,
	PhysicsService = true,
	BadgeService = true,
	FriendService = true,
	InsertService = true,
	GamePassService = true,
	Debris = true,
	CookiesService = true,
	Selection = true,
	UserInputService = true,
	KeyboardService = true,
	MouseService = true,
	VRService = true,
	ContextActionService = true,
	ScriptService = true,
	AssetService = true,
	RuntimeContentService = true,
	TouchInputService = true,
	BrowserService = true,
	CaptureService = true,
	AppStorageService = true,
	AnalyticsService = true,
	HeatmapService = true,
	AvatarSettings = true,
	SlimContentProvider = true,
	ScriptContext = true,
	RbxAnalyticsService = true,
	TelemetryService = true,
	Lighting = true,
	ThirdPartyUserService = true,
	PlatformFriendsService = true,
	PlatformCloudStorageService = true,
	GenericChallengeService = true,
	ScriptRegistrationService = true,
	RuntimeScriptService = true,
	HttpService = true,
	RobloxReplicatedStorage = true,
	MessageBusService = true,
	MemStorageService = true,
	MemStorageConnection = true,
	IXPService = true,
	ChangeHistoryService = true,
	EventIngestService = true,
	ExperienceStateCaptureService = true,
	ExperienceService = true,
	LinkingService = true,
	StylingService = true,
	HapticService = true,
	GamepadService = true,
	SessionService = true,
	WebViewService = true,
	FacialAgeEstimationService = true,
	VoiceChatService = true,
	ReplicatedStorage = true,
	AdService = true,
	AvatarChatService = true,
	AudioFocusService = true,
	SocialService = true,
	UserService = true,
	AppLifecycleObserverService = true,
	UIDragDetectorService = true,
	TextBoxService = true,
	MeshContentProvider = true,
	SolidModelContentProvider = true,
	HSRDataContentProvider = true,
	VideoService = true,
	LodDataService = true,
	EditableService = true,
	ControllerService = true,
	NetworkClient = true,
	ClientReplicator = true,
	Visit = true,
	PlayerHydrationService = true,
	GuidRegistryService = true,
	PermissionsService = true,
	Teams = true,
	FeatureRestrictionManager = true,
	ExperienceAuthService = true,
	CommerceService = true,
	RecommendationService = true,
	SafetyService = true,
	AvatarCreationService = true,
	GenerationService = true,
	RobloxServerStorage = true,
	ScriptProfilerService = true,
	HeapProfilerService = true,
	ModerationService = true,
	FaceAnimatorService = true,
	TrackerLodController = true,
	GroupService = true,
	CreatorStoreService = true,
	AvatarEditorService = true,
	RtMessagingService = true,
	ExperienceNotificationService = true,
	AchievementService = true,
	PathfindingService = true,
	TemporaryCageMeshProvider = true,
}
local Runtime = {
	Proxy = nil,
	State = nil,
	Emitter = nil,
	Beautifier = nil,
	Scope = nil,
	WaitFunction = nil,
}

local function MaterializeIfNeeded(Inst)
	if typeof(Inst) ~= "table" then
		return
	end

	local Loader = rawget(Inst, "_LarryMaterializeChildren")
	if typeof(Loader) ~= "function" then
		return
	end

	local Hierarchy = require("../Hierarchy")
	if Hierarchy and typeof(Hierarchy.MaterializeChildren) == "function" then
		Hierarchy.MaterializeChildren(Inst)
		return
	end

	rawset(Inst, "_LarryMaterializeChildren", nil)
	pcall(Loader, Inst)
end

local function WaitStep(Duration)
	if typeof(Runtime.WaitFunction) == "function" then
		local Ok, Result = pcall(Runtime.WaitFunction, Duration)
		if Ok then
			return Result
		end
	end

	local LuneTask = nil
	pcall(function()
		LuneTask = require("@lune/task")
	end)
	if LuneTask and typeof(LuneTask.wait) == "function" then
		LuneTask.wait(math.max(0, tonumber(Duration) or 0))
		return
	end
end

local function MakeServiceVarName(Name)
	local Base = string.lower(tostring(Name or "service"))
	Base = string.gsub(Base, "[^%w_]+", "_")
	if Base == "" then
		Base = "service"
	end
	if string.match(Base, "^[%d]") then
		Base = "_" .. Base
	end
	return Base
end

local function IsBlockedClassName(ClassName)
	if ApiDumpIndex.IsClassCreatable(ClassName) == false then
		return true
	end

	if BlockedClasses[ClassName] or NonCreatableClasses[ClassName] then
		return true
	end

	local Services = require("../Services")
	if Services and Services.IsServiceClass and Services.IsServiceClass(ClassName) then
		return true
	end

	if string.match(ClassName, "Service$") then
		return true
	end

	return false
end

local EventNames = {
	Changed = true,
	AncestryChanged = true,
	Destroying = true,
	ChildAdded = true,
	ChildRemoved = true,
	DescendantAdded = true,
	DescendantRemoving = true,
	Heartbeat = true,
	RenderStepped = true,
	Stepped = true,
	PlayerAdded = true,
	PlayerRemoving = true,
	CharacterAdded = true,
	CharacterRemoving = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	MouseButton1Click = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	MouseButton2Click = true,
	MouseButton2Down = true,
	MouseButton2Up = true,
	MouseEnter = true,
	MouseLeave = true,
	Activated = true,
	Touched = true,
	TouchEnded = true,
}

local EventSuffixes = {
	"Changed",
	"Added",
	"Removed",
	"Removing",
	"Click",
	"Down",
	"Up",
	"Enter",
	"Leave",
	"Began",
	"Ended",
	"Triggered",
	"Stepped",
}

local function IsLikelyEventName(Key)
	if typeof(Key) ~= "string" or Key == "" then
		return false
	end

	if EventNames[Key] then
		return true
	end

	for _, Suffix in EventSuffixes do
		if string.sub(Key, -#Suffix) == Suffix then
			return true
		end
	end

	return false
end

local function ValuesEqual(Left, Right)
	if Left == Right then
		return true
	end

	local Ok, Equal = pcall(function()
		return Left == Right
	end)

	return Ok and Equal == true
end

local function FireInstancePropertySignals(Inst, PropertyName)
	if typeof(Inst) ~= "table" or typeof(PropertyName) ~= "string" or PropertyName == "" then
		return
	end

	local ChangedSignal = Signals.ForInstance(Inst, "Changed")
	if typeof(ChangedSignal) == "table" and typeof(ChangedSignal.Fire) == "function" then
		pcall(ChangedSignal.Fire, ChangedSignal, PropertyName)
	end

	local PropertySignal = Signals.ForInstance(Inst, PropertyName .. "_Changed")
	if typeof(PropertySignal) == "table" and typeof(PropertySignal.Fire) == "function" then
		pcall(PropertySignal.Fire, PropertySignal)
	end
end

function Instance.Configure(Proxy, State, Emitter, Beautifier, Scope)
	Runtime.Proxy = Proxy
	Runtime.State = State
	Runtime.Emitter = Emitter
	Runtime.Beautifier = Beautifier
	Runtime.Scope = Scope
end

function Instance.SetWaitFunction(WaitFunction)
	Runtime.WaitFunction = WaitFunction
end

function Instance.GetCreated()
	return CreatedInstances
end

function Instance.ResetCreated()
	table.clear(CreatedInstances)
	InstanceCounter = 0
end

function Instance.new(ClassName, Parent)
	if typeof(ClassName) ~= "string" then
		error("invalid argument #1 to 'new' (string expected)")
	end

	local Inst = Instance._new(
		ClassName,
		{},
		Runtime.Proxy,
		Runtime.State,
		Runtime.Emitter,
		Runtime.Beautifier,
		Runtime.Scope
	)

	if Runtime.Scope and Runtime.Beautifier and Runtime.State then
		local Value = `Instance.new({Runtime.Beautifier:Beautify(ClassName)})`
		local Var = Runtime.Scope:AddVar(ClassName, ClassName, Value, "__call")
		Runtime.State:RegisterInternal(Inst, Var)
	end

	if Parent ~= nil then
		Inst:SetParent(Parent)
	end

	return Inst
end

function Instance._new(ClassName, Properties, Proxy, State, Emitter, Beautifier, Scope, InternalBypass)
	if not InternalBypass then
		local Stats = ApiDumpIndex.GetStats()
		if Stats.Loaded and not ApiDumpIndex.HasClass(ClassName) then
			error(`Unable to create an Instance of type "{ClassName}"`, 0)
		end

		if IsBlockedClassName(ClassName) then
			error(`Cannot create instance of class '{ClassName}'`, 0)
		end
	end

	InstanceCounter += 1

	local Self = setmetatable({}, Instance)

	Self._ClassName = ClassName
	Self._Name = ClassName
	Self._Parent = nil
	Self._Children = {}
	Self._Properties = Properties or {}
	Self._Properties["Archivable"] = true
	Self._Properties["Sandboxed"] = false
	Self._Properties["UniqueId"] = IdentityUtil.Generate(16)
	Self._Attributes = {}
	Self._Connections = {}
	Self._Destroyed = false
	Self._Id = InstanceCounter
	Self._InternalId = IdentityUtil.Generate(8)
	Self._PropertyVersion = {}
	Self._MethodCache = {}

	Self._Proxy = Proxy
	Self._State = State
	Self._Emitter = Emitter
	Self._Beautifier = Beautifier
	Self._Scope = Scope

	if ClassName == "BindableEvent" then
		Self._Properties["Event"] = Signals.ForInstance(Self, "Event")
	end

	table.insert(CreatedInstances, Self)

	return Self
end

function Instance.FromExisting(Existing, Proxy, State, Emitter, Beautifier, Scope)
	local Path = State:IsInternal(Existing)
	local Value = `Instance.fromExisting({Path or Beautifier:Beautify(Existing)})`
	local Var = Scope:AddVar("fromExisting", "inst", Value, "__call")
	return Proxy:Spy(Var)
end

function Instance:GetClassName()
	return self._ClassName
end

function Instance:GetName()
	return self._Name
end

function Instance:SetName(Value)
	if typeof(Value) ~= "string" then
		error(`Unable to assign property Name. string expected, got {typeof(Value)}`, 0)
	end

	local PreviousName = self._Name
	self._Name = Value
	if not ValuesEqual(PreviousName, Value) then
		FireInstancePropertySignals(self, "Name")
	end
end

function Instance:GetParent()
	return self._Parent
end

function Instance:SetParent(Parent)
	if self._Destroyed then
		error("Cannot set parent of destroyed instance")
	end

	if Parent == self then
		error("Cannot set parent to self")
	end

	if Parent ~= nil and not Instance.IsInstance(Parent) then
		error("Parent must be an Instance or nil", 0)
	end

	local OldParent = self._Parent

	if OldParent and typeof(OldParent) == "table" and OldParent._Children then
		for I = #OldParent._Children, 1, -1 do
			if OldParent._Children[I] == self then
				table.remove(OldParent._Children, I)
				break
			end
		end
		local ChildRemoved = OldParent:GetProperty('ChildRemoved')
		if typeof(ChildRemoved) == 'table' and typeof(ChildRemoved.Fire) == 'function' then
			ChildRemoved:Fire(self)
		end
	end

	self._Parent = Parent

	local AncestryChanged = self:GetProperty('AncestryChanged')
	if typeof(AncestryChanged) == 'table' and typeof(AncestryChanged.Fire) == 'function' then
		AncestryChanged:Fire(self, Parent)
	end

	if Parent and typeof(Parent) == "table" and Parent._Children then
		table.insert(Parent._Children, self)
		local ChildAdded = Parent:GetProperty('ChildAdded')
		if typeof(ChildAdded) == 'table' and typeof(ChildAdded.Fire) == 'function' then
			ChildAdded:Fire(self)
		end
	end

	if not ValuesEqual(OldParent, Parent) then
		FireInstancePropertySignals(self, "Parent")
	end
end

function Instance:GetChildren()
	MaterializeIfNeeded(self)
	local Result = {}
	for _, Child in self._Children do
		table.insert(Result, Child)
	end
	return Result
end

function Instance:GetDescendants()
	MaterializeIfNeeded(self)
	local Result = {}

	local function Collect(Inst)
		MaterializeIfNeeded(Inst)
		for _, Child in Inst._Children do
			table.insert(Result, Child)
			if Child._Children then
				Collect(Child)
			end
		end
	end

	Collect(self)
	return Result
end

function Instance:IsA(ClassName)
	if self._ClassName == ClassName then
		return true
	end

	if ClassName == "Instance" then
		return true
	end

	if ClassName == "PVInstance" then
		return self._ClassName == "Part" or self._ClassName == "MeshPart" or self._ClassName == "Model"
	end

	if ClassName == "BasePart" then
		return self._ClassName == "Part" or self._ClassName == "MeshPart"
	end

	if ApiDumpIndex.IsA(self._ClassName, ClassName) then
		return true
	end

	return false
end

function Instance:FindFirstChild(Name, Recursive)
	MaterializeIfNeeded(self)
	for _, Child in self._Children do
		if Child._Name == Name then
			return Child
		end
	end

	if Recursive then
		for _, Child in self._Children do
			local Found = Child:FindFirstChild(Name, true)
			if Found then return Found end
		end
	end

	if self._State and self._State.ExploringFunction and self._Proxy and typeof(Name) == "string" then
		local SelfPath = self._State:IsInternal(self)
		if typeof(SelfPath) == "string" and SelfPath ~= "" then
			return self._Proxy:Spy(StringUtil.Index(Name, SelfPath))
		end
	end

	if typeof(Key) == "string" then
		error(`{Key} is not a valid member of {Self._ClassName}`, 2)
	end

	return nil
end

function Instance:HttpGet(Url, NoCache)
	local HTTP = require("../../IO/HTTP")
	return HTTP.HttpGet(Url, self._Proxy, self._State, self._Emitter, self._Beautifier, self._Scope)
end

function Instance:HttpGetAsync(Url, NoCache)
	return self:HttpGet(Url, NoCache)
end

function Instance:GetService(Name)
	local Services = require("../Services")
	local Service = Services.Get(Name)

	if Service == nil then
		error(`{tostring(Name)} is not a valid service name`, 0)
	end

	if self._Emitter and self._Beautifier then
		local PrettyName = self._Beautifier:Beautify(Name)
		local ShouldEmit = true

		if self._State then
			local ServiceVars = rawget(self._State, "_ServiceLookupVars")
			if typeof(ServiceVars) ~= "table" then
				ServiceVars = {}
				rawset(self._State, "_ServiceLookupVars", ServiceVars)
			end

			local ExistingVar = ServiceVars[Name]
			if typeof(ExistingVar) == "string" and ExistingVar ~= "" then
				ShouldEmit = false
			end

			local Counts = rawget(self._State, "_ServiceLookupEmitCounts")
			if typeof(Counts) ~= "table" then
				Counts = {}
				rawset(self._State, "_ServiceLookupEmitCounts", Counts)
			end

			local Key = tostring(Name)
			local Count = (Counts[Key] or 0) + 1
			Counts[Key] = Count

			local MaxRepeated = 1
			if Count > MaxRepeated then
				ShouldEmit = false
			end

			if Count == 1 then
				local VarName = MakeServiceVarName(Name)
				local NameCounts = rawget(self._State, "_ServiceLookupVarCounts")
				if typeof(NameCounts) ~= "table" then
					NameCounts = {}
					rawset(self._State, "_ServiceLookupVarCounts", NameCounts)
				end

				local ExistingCount = NameCounts[VarName] or 0
				NameCounts[VarName] = ExistingCount + 1
				if ExistingCount > 0 then
					VarName = `{VarName}{ExistingCount + 1}`
				end

				ServiceVars[Name] = VarName
				self._Emitter:Append(`local {VarName} = game:GetService({PrettyName})`)
				self._State:Define(VarName, `game:GetService({PrettyName})`, "__call")
				self._State:RegisterInternal(Service, VarName)
				ShouldEmit = false
			end
		end

		if ShouldEmit then
			self._Emitter:Append(`game:GetService({PrettyName})`)
		end
	end

	return Service
end

function Instance:FindService(Name)
	local Services = require("../Services")
	local Service = Services.FindService(Name)

	if self._Emitter and self._Beautifier then
		self._Emitter:Append(`game:FindService({self._Beautifier:Beautify(Name)})`)
	end

	return Service
end

function Instance:WaitForChild(Name, Timeout)
	local Existing = self:FindFirstChild(Name)
	if Existing ~= nil then
		return Existing
	end

	local Start = os.clock()
	local Limit = 5
	if Timeout ~= nil then
		if typeof(Timeout) ~= "number" then
			error("invalid argument #2 to 'WaitForChild' (number expected)", 2)
		end
		if Timeout < 0 then
			error("invalid argument #2 to 'WaitForChild' (non-negative number expected)", 2)
		end
		Limit = Timeout
	end

	while true do
		WaitStep(0.03)

		Existing = self:FindFirstChild(Name)
		if Existing ~= nil then
			return Existing
		end

		if os.clock() - Start >= Limit then
			return nil
		end
	end

	return nil
end

function Instance:FindFirstChildOfClass(ClassName)
	MaterializeIfNeeded(self)
	for _, Child in self._Children do
		if Child._ClassName == ClassName then
			return Child
		end
	end
	return nil
end

function Instance:FindFirstChildWhichIsA(ClassName)
	MaterializeIfNeeded(self)
	for _, Child in self._Children do
		if Child:IsA(ClassName) then
			return Child
		end
	end
	return nil
end

function Instance:FindFirstAncestorOfClass(ClassName)
	local Current = self._Parent

	while Current do
		if typeof(Current) == "table" and Current._ClassName == ClassName then
			return Current
		end
		Current = typeof(Current) == "table" and Current._Parent or nil
	end

	return nil
end

function Instance:Clone()
	local Archivable = self._Properties["Archivable"]
	if Archivable == false then
		error("Instance is not archivable")
	end

	local Cloned = Instance._new(
		self._ClassName,
		{},
		self._Proxy,
		self._State,
		self._Emitter,
		self._Beautifier,
		self._Scope
	)

	Cloned._Name = self._Name

	for K, V in next, self._Properties do
		Cloned._Properties[K] = V
	end

	for K, V in next, self._Attributes do
		Cloned._Attributes[K] = V
	end

	for _, Child in self._Children do
		local ChildClone = Child:Clone()
		ChildClone:SetParent(Cloned)
	end

	return Cloned
end

function Instance:Destroy()
	if self._Destroyed then
		return
	end

	local Services = require("../Services")
	if self._ClassName == "DataModel" then
		error("The DataModel cannot be destroyed", 0)
	end
	if Services and Services.IsServiceClass and Services.IsServiceClass(self._ClassName) then
		error(`The {self._ClassName} service cannot be destroyed`, 0)
	end

	if self._Properties["Sandboxed"] == true and self._VarName then
		return
	end

	self:SetParent(nil)
	self._Destroyed = true
	TagRegistry[self] = nil

	for I = #self._Children, 1, -1 do
		self._Children[I]:Destroy()
	end

	table.clear(self._Connections)
end

function Instance:IsDescendantOf(Ancestor)
	if Ancestor == nil then
		return false
	end

	if self == Ancestor then
		return true
	end

	local Current = self._Parent

	while Current do
		if Current == Ancestor then
			return true
		end
		Current = Current._Parent
	end

	return false
end

function Instance:IsAncestorOf(Descendant)
	if typeof(Descendant) ~= "table" then
		return false
	end

	return Descendant:IsDescendantOf(self)
end

function Instance:AddTag(TagName)
	if typeof(TagName) ~= "string" then
		return
	end

	local Tags = TagRegistry[self]
	if not Tags then
		Tags = {}
		TagRegistry[self] = Tags
	end

	Tags[TagName] = true
end

function Instance:RemoveTag(TagName)
	local Tags = TagRegistry[self]
	if not Tags then
		return
	end
	Tags[TagName] = nil
end

function Instance:HasTag(TagName)
	local Tags = TagRegistry[self]
	return Tags ~= nil and Tags[TagName] == true
end

function Instance:GetTags()
	local Tags = TagRegistry[self]
	if not Tags then
		return {}
	end

	local Out = {}
	for Tag in next, Tags do
		Out[#Out + 1] = Tag
	end
	table.sort(Out)
	return Out
end

function Instance:SetAttribute(Name, Value)
	self._Attributes[Name] = Value
end

function Instance:GetAttribute(Name)
	return self._Attributes[Name]
end

function Instance:GetProperty(Name)
	local Explicit = self._Properties[Name]
	if Explicit ~= nil then
		return Explicit
	end

	return Properties.Get(self, Name)
end

function Instance:GetRawProperty(Name)
	return self._Properties[Name]
end

function Instance:SetProperty(Name, Value)
	local PreviousValue = self._Properties[Name]
	if self._PropertyVersion == nil then
		self._PropertyVersion = {}
	end
	self._PropertyVersion[Name] = (self._PropertyVersion[Name] or 0) + 1
	self._Properties[Name] = Value

	if typeof(Name) == "string" and string.sub(Name, 1, 1) ~= "_" and not ValuesEqual(PreviousValue, Value) then
		FireInstancePropertySignals(self, Name)
	end
end

function Instance:GetPropertyVersion(Name)
	if self._PropertyVersion == nil then
		return 0
	end
	return self._PropertyVersion[Name] or 0
end

function Instance:HasProperty(Name)
	return self._Properties[Name] ~= nil
end

function Instance.IsInstance(Value)
	return getmetatable(Value) == Instance
end

Instance.__index = function(Self, Key)
	if typeof(Key) == "table" then
		local RawKey = rawget(Key, "V")
		if RawKey ~= nil then
			Key = RawKey
		end
	end
	if typeof(Key) == "string" and string.sub(Key, 1, 1) == "_" then
		return rawget(Self, Key)
	end

	local function RequireSelf(Value)
		if not Instance.IsInstance(Value) then
			error(`Expected ':' not '.' calling member function {tostring(Key)}`, 2)
		end
	end

	local MethodCache = rawget(Self, "_MethodCache")
	if typeof(MethodCache) ~= "table" then
		MethodCache = {}
		rawset(Self, "_MethodCache", MethodCache)
	end

	local function GetOrCacheMethod(MethodKey, Factory)
		local Cached = MethodCache[MethodKey]
		if typeof(Cached) == "function" then
			return Cached
		end

		local Created = Factory()
		if typeof(Created) == "function" then
			MethodCache[MethodKey] = Created
		end
		return Created
	end

	local SpecificMethod = Methods.GetSpecific(Self, Key)
	if SpecificMethod then
		return GetOrCacheMethod(Key, function()
			return function(Value, ...)
				RequireSelf(Value)
				Methods.Validate(Value, Key, ...)
				return SpecificMethod(Value, ...)
			end
		end)
	end

	local Method = rawget(Instance, Key)
	if Method ~= nil then
		return Method
	end

	if Key == "ClassName" then
		return Self._ClassName
	elseif Key == "Name" then
		return Self._Name
	elseif Key == "Parent" then
		return Self._Parent
	end

	if Self._ClassName == "DataModel" and typeof(Key) == "string" then
		local Services = require("../Services")
		local Direct = Services.FindService(Key)
		if Direct ~= nil then
			return Direct
		end

		local LowerKey = string.lower(Key)
		for _, ServiceName in ipairs(Services.GetAllNames()) do
			if string.lower(ServiceName) == LowerKey then
				local Found = Services.FindService(ServiceName)
				if Found ~= nil then
					return Found
				end
			end
		end
	end

	local Prop = Properties.Get(Self, Key)
	if Prop ~= nil then
		return Prop
	end
	if typeof(Key) == "string" and Properties.HasNilDefault and Properties.HasNilDefault(Self._ClassName, Key) then
		return nil
	end

	local GlobalMethod = Methods.GetGlobal(Key)
	if GlobalMethod then
		return GetOrCacheMethod(Key, function()
			return function(Value, ...)
				RequireSelf(Value)
				Methods.Validate(Value, Key, ...)
				return GlobalMethod(Value, ...)
			end
		end)
	end

	local DumpMethod = Methods.GetDumpFallback(Self, Key)
	if DumpMethod then
		return GetOrCacheMethod(Key, function()
			return function(Value, ...)
				RequireSelf(Value)
				Methods.Validate(Value, Key, ...)
				return DumpMethod(Value, ...)
			end
		end)
	end

	if typeof(Key) == "string"
		and not ApiDumpIndex.HasCallback(Self._ClassName, Key)
		and (ApiDumpIndex.HasFunction(Self._ClassName, Key) or ApiDumpIndex.HasAnyFunction(Key))
	then
		return GetOrCacheMethod(Key, function()
			return function(Value, ...)
				RequireSelf(Value)
				Methods.Validate(Value, Key, ...)
				local Handler = Methods.GetDumpFallback(Value, Key)
				if Handler then
					return Handler(Value, ...)
				end
				return nil
			end
		end)
	end

	if Self._ClassName == "DataModel" and typeof(Key) == "string" then
		local Services = require("../Services")
		local ExistingService = Services.FindService(Key)
		if ExistingService ~= nil then
			return ExistingService
		end

		if Services.IsValid and Services.IsValid(Key) then
			local Ok, Service = pcall(Services.Get, Key)
			if Ok then
				return Service
			end
		end
	end

	if IsLikelyEventName(Key) or ApiDumpIndex.HasEvent(Self._ClassName, Key) then
		local Signal = Signals.ForInstance(Self, Key)
		Self._Properties[Key] = Signal

		if Self._State then
			local SelfPath = Self._State:IsInternal(Self)
			if SelfPath then
				Self._State:RegisterInternal(Signal, `{SelfPath}.{Key}`)
			end
		end

		return Signal
	end

	local Child = Self:FindFirstChild(Key, false)
	if Child ~= nil then
		return Child
	end

	if typeof(Key) == "string" then
		error(`{Key} is not a valid member of {Self._ClassName}`, 2)
	end

	return nil
end

Instance.__newindex = function(Self, Key, Value)
	if typeof(Key) == "table" then
		local RawKey = rawget(Key, "V")
		if RawKey ~= nil then
			Key = RawKey
		end
	end

	if string.sub(tostring(Key), 1, 1) == "_" then
		rawset(Self, Key, Value)
		return
	end

	local AssignedValue

	if Key == "Parent" then
		Self:SetParent(Value)
		AssignedValue = Value
	elseif Key == "Name" then
		local NameValue = Value
		if typeof(NameValue) == "table" then
			local RawValue = rawget(NameValue, "V")
			if RawValue ~= nil then
				NameValue = RawValue
			end
		end

		if typeof(NameValue) ~= "string" then
			error(`Unable to assign property Name. string expected, got {typeof(NameValue)}`, 0)
		end

		Self:SetName(NameValue)
		AssignedValue = NameValue
	end

	if AssignedValue == nil and typeof(Key) == "string" then
		local IsMethod = rawget(Instance, Key) ~= nil
			or Methods.GetSpecific(Self, Key) ~= nil
			or (ApiDumpIndex.HasFunction(Self._ClassName, Key) and not ApiDumpIndex.HasCallback(Self._ClassName, Key))
		if IsMethod then
			error(`Unable to assign property {Key}. Member is read only`, 0)
		end

		if IsLikelyEventName(Key) or ApiDumpIndex.HasEvent(Self._ClassName, Key) then
			error(`Unable to assign property {Key}. Member is read only`, 0)
		end
	end

	if AssignedValue == nil then
		AssignedValue = Properties.Set(Self, Key, Value)
	end

	if Self._Emitter and Self._Beautifier then
		local Target = (Self._State and Self._State:IsInternal(Self)) or Self._Name or Self._ClassName or "instance"
		local Left

		if typeof(Key) == "string" and not StringUtil.IsWeird(Key) then
			Left = `{Target}.{Key}`
		else
			Left = `{Target}[{Self._Beautifier:Beautify(Key)}]`
		end

		local Right = AssignedValue == nil and "nil" or Self._Beautifier:Beautify(AssignedValue)
		Self._Emitter:Append(`{Left} = {Right}`)
	end
end

Instance.__call = function(_Self, ...)
	error("attempt to call a Instance value", 0)
end

Instance.__tostring = function(Self)
	return Self._Name or Self._ClassName or "Instance"
end

return Instance