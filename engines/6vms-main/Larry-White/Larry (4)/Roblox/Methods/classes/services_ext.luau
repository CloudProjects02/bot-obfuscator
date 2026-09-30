local Signals = require("../../Signals")
local Enums = require("../../Enums")
local ApiDumpIndex = require("../../ApiCatalog")
local DataTypes = require("../../DataTypes")
local IdentityUtil = require("../../../Utils/Identity")

local ServicesExt = {}

local DEFAULT_LOCALE = "en-us"

local function createInternalInstance(Anchor, ClassName, Name)
	local InstanceMod = require("../../Instance")
	local Created = InstanceMod._new(
		ClassName,
		{},
		rawget(Anchor, "_Proxy"),
		rawget(Anchor, "_State"),
		rawget(Anchor, "_Emitter"),
		rawget(Anchor, "_Beautifier"),
		rawget(Anchor, "_Scope"),
		true
	)

	Created._Name = (typeof(Name) == "string" and Name ~= "") and Name or ClassName
	return Created
end

local function ensureBucket(Inst, Key)
	local Bucket = Inst:GetProperty(Key)
	if typeof(Bucket) ~= "table" then
		Bucket = {}
		Inst:SetProperty(Key, Bucket)
	end
	return Bucket
end

local function ensureMemStorageItems(Service)
	return ensureBucket(Service, "_MemStorageItems")
end

local function copyArray(Source)
	local Out = {}
	if typeof(Source) ~= "table" then
		return Out
	end
	for Index, Value in ipairs(Source) do
		Out[Index] = Value
	end
	return Out
end

local function ensureContextActions(Service)
	return ensureBucket(Service, "_BoundActions")
end

local function snapshotContextActions(BoundActions)
	local Snapshot = {}
	if typeof(BoundActions) ~= "table" then
		return Snapshot
	end

	for ActionName, Info in next, BoundActions do
		if typeof(Info) == "table" then
			Snapshot[ActionName] = {
				actionName = ActionName,
				createTouchButton = Info.createTouchButton == true,
				inputTypes = copyArray(Info.inputTypes),
				functionToBind = Info.functionToBind,
				priorityLevel = Info.priorityLevel,
				isCore = Info.isCore == true,
			}
		end
	end

	return Snapshot
end

local function normalizeLocale(Locale)
	if typeof(Locale) ~= "string" or Locale == "" then
		return DEFAULT_LOCALE
	end

	return string.lower(Locale)
end

local function enumItem(EnumType, PreferredName)
	if typeof(PreferredName) == "string" and PreferredName ~= "" then
		local Preferred = Enums.Get(EnumType, PreferredName)
		if Preferred ~= nil then
			return Preferred
		end
	end

	local FirstName = ApiDumpIndex.GetFirstEnumItem(EnumType)
	if typeof(FirstName) == "string" and FirstName ~= "" then
		return Enums.Get(EnumType, FirstName)
	end

	return nil
end

local function makeVector2(X, Y)
	local Lib = DataTypes.Get("Vector2")
	if typeof(Lib) == "table" and typeof(Lib.new) == "function" then
		local Ok, Value = pcall(Lib.new, X, Y)
		if Ok then
			return Value
		end
	end

	return {
		X = X,
		Y = Y,
	}
end

local function makeVector3(X, Y, Z)
	local Lib = DataTypes.Get("Vector3")
	if typeof(Lib) == "table" and typeof(Lib.new) == "function" then
		local Ok, Value = pcall(Lib.new, X, Y, Z)
		if Ok then
			return Value
		end
	end

	return {
		X = X,
		Y = Y,
		Z = Z,
	}
end

local function readComponents(Value)
	local ValueType = typeof(Value)
	if ValueType == "Vector3" then
		return Value.X, Value.Y, Value.Z
	end
	if ValueType == "Vector2" then
		return Value.X, Value.Y, nil
	end

	if typeof(Value) == "table" then
		local X = rawget(Value, "X")
		local Y = rawget(Value, "Y")
		local Z = rawget(Value, "Z")
		if typeof(X) == "number" and typeof(Y) == "number" then
			return X, Y, Z
		end
	end

	return nil
end

local function lerpNumber(Current, Target, Alpha)
	return Current + (Target - Current) * Alpha
end

local function lerpValue(Current, Target, Alpha)
	if typeof(Current) == "number" and typeof(Target) == "number" then
		return lerpNumber(Current, Target, Alpha)
	end

	local CX, CY, CZ = readComponents(Current)
	local TX, TY, TZ = readComponents(Target)
	if CX ~= nil and TX ~= nil then
		if CZ ~= nil or TZ ~= nil then
			return makeVector3(
				lerpNumber(CX, TX, Alpha),
				lerpNumber(CY, TY, Alpha),
				lerpNumber(CZ or 0, TZ or 0, Alpha)
			)
		end

		return makeVector2(
			lerpNumber(CX, TX, Alpha),
			lerpNumber(CY, TY, Alpha)
		)
	end

	return Target
end

local function subtractValue(Left, Right)
	if typeof(Left) == "number" and typeof(Right) == "number" then
		return Left - Right
	end

	local LX, LY, LZ = readComponents(Left)
	local RX, RY, RZ = readComponents(Right)
	if LX ~= nil and RX ~= nil then
		if LZ ~= nil or RZ ~= nil then
			return makeVector3(LX - RX, LY - RY, (LZ or 0) - (RZ or 0))
		end

		return makeVector2(LX - RX, LY - RY)
	end

	return nil
end

local function scaleValue(Value, Scalar)
	if typeof(Value) == "number" then
		return Value * Scalar
	end

	local X, Y, Z = readComponents(Value)
	if X ~= nil then
		if Z ~= nil then
			return makeVector3(X * Scalar, Y * Scalar, Z * Scalar)
		end
		return makeVector2(X * Scalar, Y * Scalar)
	end

	return Value
end

local function zeroLike(Value)
	if typeof(Value) == "number" then
		return 0
	end

	local X, Y, Z = readComponents(Value)
	if X ~= nil then
		if Z ~= nil then
			return makeVector3(0, 0, 0)
		end
		return makeVector2(0, 0)
	end

	return 0
end

local function tweenValueKind(Value)
	local ValueType = typeof(Value)
	if ValueType == "table" then
		local Tag = rawget(Value, "__larryType")
		if typeof(Tag) == "string" and Tag ~= "" then
			return Tag
		end
	end
	return ValueType
end

local function tweenValuesCompatible(Current, Target)
	local CurrentKind = tweenValueKind(Current)
	local TargetKind = tweenValueKind(Target)
	if CurrentKind == nil or TargetKind == nil then
		return true
	end
	return CurrentKind == TargetKind
end

local function pathWaypoint(Position, ActionName, Label)
	local Action = enumItem("PathWaypointAction", ActionName) or ActionName or "Walk"
	local PathWaypointLib = DataTypes.Get("PathWaypoint")
	if typeof(PathWaypointLib) == "table" and typeof(PathWaypointLib.new) == "function" then
		local Ok, Value = pcall(PathWaypointLib.new, Position, Action, Label or "")
		if Ok then
			return Value
		end
	end

	return {
		__larryType = "PathWaypoint",
		Position = Position,
		Action = Action,
		Label = Label or "",
	}
end

local function setHiddenProperty(Inst, Key, Value)
	Inst:SetProperty(Key, Value)
	return Value
end

local function getGameProperty(Key)
	local Hierarchy = require("../../Hierarchy")
	local GameRoot = Hierarchy.GetRoot()
	if GameRoot and typeof(GameRoot.GetProperty) == "function" then
		return GameRoot:GetProperty(Key)
	end
	return nil
end

local function ensureTranslator(Service, Locale)
	local Cache = ensureBucket(Service, "_TranslatorCache")
	local Normalized = normalizeLocale(Locale)
	local Existing = Cache[Normalized]
	if Existing ~= nil then
		return Existing
	end

	local Translator = createInternalInstance(Service, "Translator", "Translator")
	setHiddenProperty(Translator, "LocaleId", Normalized)
	Cache[Normalized] = Translator
	return Translator
end

local function ensureCorescriptLocalizations(Service)
	local Existing = Service:GetProperty("_CoreScriptLocalizations")
	if typeof(Existing) == "table" and #Existing > 0 then
		return Existing
	end

	local Locale = normalizeLocale(
		Service:GetProperty("RobloxLocaleId")
			or Service:GetProperty("SystemLocaleId")
			or DEFAULT_LOCALE
	)

	local LocalizationTable = createInternalInstance(Service, "LocalizationTable", "CoreScriptLocalizationTable")
	setHiddenProperty(LocalizationTable, "LocaleId", Locale)
	setHiddenProperty(LocalizationTable, "SourceLocaleId", Locale)
	setHiddenProperty(LocalizationTable, "DevelopmentLanguage", Locale)

	local List = { LocalizationTable }
	setHiddenProperty(Service, "_CoreScriptLocalizations", List)
	return List
end

local function ensureDataStore(Service, ClassName, Name, Scope)
	local Cache = ensureBucket(Service, "_DataStoreCache")
	local StoreName = typeof(Name) == "string" and Name ~= "" and Name or "global"
	local StoreScope = typeof(Scope) == "string" and Scope ~= "" and Scope or "global"
	local CacheKey = `{ClassName}|{StoreName}|{StoreScope}`
	local Existing = Cache[CacheKey]
	if Existing ~= nil then
		return Existing
	end

	local Store = createInternalInstance(Service, ClassName, StoreName)
	setHiddenProperty(Store, "_StoreName", StoreName)
	setHiddenProperty(Store, "_StoreScope", StoreScope)
	setHiddenProperty(Store, "_StoreEntries", {})
	Cache[CacheKey] = Store
	return Store
end

local function isValidDataStoreToken(Value)
	if typeof(Value) ~= "string" or Value == "" then
		return false
	end
	if #Value > 50 then
		return false
	end
	return string.find(Value, "[^%w%._%-]") == nil
end

local function dataStoreEntries(Store)
	return ensureBucket(Store, "_StoreEntries")
end

local function notifyStoreUpdate(Store, Key, Value)
	local SignalsByKey = ensureBucket(Store, "_UpdateSignals")
	local Signal = SignalsByKey[Key]
	if Signal ~= nil then
		Signal:Fire(Value)
	end
end

local function buildPages(Anchor, ClassName, Entries, PageSize)
	local Pages = createInternalInstance(Anchor, ClassName, ClassName)
	local Size = tonumber(PageSize) or 0
	if Size <= 0 then
		Size = math.max(#Entries, 1)
	end

	local Chunked = {}
	if #Entries == 0 then
		Chunked[1] = {}
	else
		for Index = 1, #Entries, Size do
			local Slice = {}
			for Cursor = Index, math.min(Index + Size - 1, #Entries) do
				Slice[#Slice + 1] = Entries[Cursor]
			end
			Chunked[#Chunked + 1] = Slice
		end
	end

	setHiddenProperty(Pages, "_Pages", Chunked)
	setHiddenProperty(Pages, "_PageIndex", 1)
	setHiddenProperty(Pages, "IsFinished", #Chunked <= 1)
	setHiddenProperty(Pages, "Cursor", "")
	return Pages
end

local function messageTopicSignal(Service, Topic)
	local SignalsByTopic = ensureBucket(Service, "_TopicSignals")
	local Signal = SignalsByTopic[Topic]
	if Signal == nil then
		Signal = Signals.ForInstance(Service, `Messaging_{Topic}`)
		SignalsByTopic[Topic] = Signal
	end
	return Signal
end

local function badgeUserBucket(Service, UserId)
	local Badges = ensureBucket(Service, "_AwardedBadges")
	local Key = tostring(math.floor(math.abs(tonumber(UserId) or 0)))
	local UserBucket = Badges[Key]
	if UserBucket == nil then
		UserBucket = {}
		Badges[Key] = UserBucket
	end
	return UserBucket
end

local function getFilteredText(Value)
	return typeof(Value) == "string" and Value or ""
end

local function newTextFilterResult(Anchor, Text)
	local Result = createInternalInstance(Anchor, "TextFilterResult", "TextFilterResult")
	setHiddenProperty(Result, "_FilteredText", getFilteredText(Text))
	return Result
end

local function newTranslatedFilterResult(Anchor, Text, Locales)
	local Result = createInternalInstance(Anchor, "TextFilterTranslatedResult", "TextFilterTranslatedResult")
	local Source = newTextFilterResult(Anchor, Text)
	local NormalizedLocales = {}

	if typeof(Locales) == "table" then
		for _, Locale in ipairs(Locales) do
			NormalizedLocales[normalizeLocale(Locale)] = getFilteredText(Text)
		end
	end

	if next(NormalizedLocales) == nil then
		NormalizedLocales[DEFAULT_LOCALE] = getFilteredText(Text)
	end

	setHiddenProperty(Result, "_Translations", NormalizedLocales)
	setHiddenProperty(Result, "SourceLanguage", DEFAULT_LOCALE)
	setHiddenProperty(Result, "SourceText", Source)
	return Result
end

local function getStoreListing(Service, Prefix)
	local Cache = ensureBucket(Service, "_DataStoreCache")
	local Out = {}
	local Seen = {}

	for _, Store in next, Cache do
		local StoreName = Store:GetProperty("_StoreName") or tostring(Store:GetName())
		if typeof(Prefix) == "string" and Prefix ~= "" and string.sub(StoreName, 1, #Prefix) ~= Prefix then
			continue
		end
		if not Seen[StoreName] then
			Seen[StoreName] = true
			Out[#Out + 1] = {
				Name = StoreName,
			}
		end
	end

	table.sort(Out, function(Left, Right)
		return tostring(Left.Name) < tostring(Right.Name)
	end)

	return Out
end

local function cleanupExpiringEntries(Entries)
	local Now = os.clock()
	for Key, Entry in next, Entries do
		if typeof(Entry) == "table" then
			local ExpireAt = rawget(Entry, "ExpireAt")
			if typeof(ExpireAt) == "number" and ExpireAt <= Now then
				Entries[Key] = nil
			end
		end
	end
end

local function buildTeleportHistory(Service, PlaceId)
	local Places = ensureBucket(Service, "_PlaceHistory")
	Places[#Places + 1] = PlaceId

	local Universes = ensureBucket(Service, "_UniverseHistory")
	Universes[#Universes + 1] = getGameProperty("GameId")
end

local function firePlayerTeleport(Players, PlaceId, SpawnName)
	local State = enumItem("TeleportState", "Started")
	if typeof(Players) ~= "table" then
		return
	end

	for _, Player in ipairs(Players) do
		if typeof(Player) == "table" and Player.IsA and Player:IsA("Player") then
			Signals.ForInstance(Player, "OnTeleport"):Fire(State, PlaceId, SpawnName or "")
		end
	end
end

local function teleportLocalPlayer(Service, PlaceId, TeleportData, CustomGui, Players, SpawnName)
	setHiddenProperty(Service, "_LocalTeleportData", TeleportData)
	if CustomGui ~= nil then
		setHiddenProperty(Service, "_ArrivingTeleportGui", CustomGui)
	end
	buildTeleportHistory(Service, PlaceId)
	firePlayerTeleport(Players, PlaceId, SpawnName)
	return true
end

local function getLocaleRegion(Locale)
	local _, Region = string.match(normalizeLocale(Locale), "^([a-z]+)[%-%_]([a-z]+)$")
	if typeof(Region) == "string" and Region ~= "" then
		return string.upper(Region)
	end
	return "US"
end

local function formatTemplate(Template, Args)
	if typeof(Template) ~= "string" then
		return ""
	end

	if typeof(Args) ~= "table" then
		return Template
	end

	return (string.gsub(Template, "{([%w_]+)}", function(Key)
		local Value = Args[Key]
		if Value == nil then
			return `{` .. Key .. `}`
		end
		return tostring(Value)
	end))
end

local function measureText(Text, FontSize, MaxWidth)
	local CleanText = getFilteredText(Text)
	local Size = math.max(1, tonumber(FontSize) or 14)
	local WidthLimit = tonumber(MaxWidth)
	if WidthLimit ~= nil and (WidthLimit ~= WidthLimit or WidthLimit <= 0 or WidthLimit == math.huge or WidthLimit == -math.huge) then
		WidthLimit = nil
	end

	local LongestLine = 0
	local LineCount = 0
	for Line in string.gmatch(CleanText .. "\n", "([^\n]*)\n") do
		LineCount += 1
		if #Line > LongestLine then
			LongestLine = #Line
		end
	end

	if LineCount == 0 then
		LineCount = 1
	end

	local CharWidth = Size * 0.55
	local RawWidth = math.max(CharWidth, LongestLine * CharWidth)
	local EffectiveWidth = RawWidth
	local EffectiveLines = LineCount

	if WidthLimit ~= nil then
		EffectiveWidth = math.min(WidthLimit, RawWidth)
		EffectiveLines = math.max(LineCount, math.ceil(RawWidth / WidthLimit))
	end

	local Height = math.max(Size, EffectiveLines * Size * 1.2)
	return makeVector2(math.ceil(EffectiveWidth), math.ceil(Height))
end

local function easingName(Value)
	if typeof(Value) == "table" then
		local Name = rawget(Value, "_Name") or rawget(Value, "Name")
		if typeof(Name) == "string" then
			return Name
		end
	end

	if typeof(Value) == "string" then
		return string.match(Value, "^Enum%.[%w_]+%.([%w_]+)$") or Value
	end

	return tostring(Value)
end

local function applyEasingStyle(Alpha, StyleName)
	local A = math.max(0, math.min(1, Alpha))
	local Name = string.lower(StyleName or "linear")

	if Name == "linear" then
		return A
	elseif Name == "sine" then
		return 1 - math.cos((A * math.pi) / 2)
	elseif Name == "quad" then
		return A * A
	elseif Name == "cubic" then
		return A * A * A
	elseif Name == "quart" then
		return A * A * A * A
	elseif Name == "quint" then
		return A * A * A * A * A
	elseif Name == "circular" then
		return 1 - math.sqrt(1 - A * A)
	elseif Name == "exponential" then
		if A == 0 then
			return 0
		end
		return 2 ^ (10 * (A - 1))
	elseif Name == "back" then
		local C1 = 1.70158
		local C3 = C1 + 1
		return C3 * A * A * A - C1 * A * A
	elseif Name == "bounce" then
		local N1 = 7.5625
		local D1 = 2.75
		if A < 1 / D1 then
			return N1 * A * A
		elseif A < 2 / D1 then
			A -= 1.5 / D1
			return N1 * A * A + 0.75
		elseif A < 2.5 / D1 then
			A -= 2.25 / D1
			return N1 * A * A + 0.9375
		end
		A -= 2.625 / D1
		return N1 * A * A + 0.984375
	elseif Name == "elastic" then
		if A == 0 or A == 1 then
			return A
		end
		local C4 = (2 * math.pi) / 3
		return -(2 ^ (10 * A - 10)) * math.sin((A * 10 - 10.75) * C4)
	end

	return A
end

local function applyEasingDirection(Alpha, StyleName, DirectionName)
	local Direction = string.lower(DirectionName or "inout")
	if Direction == "in" then
		return applyEasingStyle(Alpha, StyleName)
	elseif Direction == "out" then
		return 1 - applyEasingStyle(1 - Alpha, StyleName)
	end

	if Alpha < 0.5 then
		return applyEasingStyle(Alpha * 2, StyleName) / 2
	end

	return 1 - applyEasingStyle((1 - Alpha) * 2, StyleName) / 2
end

local function applyTweenProperties(Tween)
	local Target = Tween:GetProperty("Instance")
	local PropertyTable = Tween:GetProperty("_TweenProperties")
	if typeof(Target) ~= "table" or typeof(PropertyTable) ~= "table" then
		return
	end

	for Key, Value in next, PropertyTable do
		pcall(function()
			if typeof(Target.SetProperty) == "function" then
				Target:SetProperty(Key, Value)
			else
				Target[Key] = Value
			end
		end)
	end
end

local function readTweenDuration(TweenInfo)
	if typeof(TweenInfo) ~= "table" then
		return 0
	end

	local Duration = tonumber(rawget(TweenInfo, "Time"))
	if Duration == nil then
		Duration = tonumber(rawget(TweenInfo, "DelayTime"))
	else
		local Delay = tonumber(rawget(TweenInfo, "DelayTime")) or 0
		Duration += math.max(0, Delay)
	end
	if Duration == nil or Duration < 0 then
		return 0
	end
	return Duration
end

local function toClockTime(Value)
	local Number = tonumber(Value)
	if Number == nil then
		return nil
	end

	Number = Number % 24
	if Number < 0 then
		Number += 24
	end
	return Number
end

local function parseTimeOfDay(Value)
	if typeof(Value) ~= "string" then
		return nil
	end

	local H, M, S = string.match(Value, "^(%d+):(%d+):(%d+)$")
	if H == nil then
		H, M = string.match(Value, "^(%d+):(%d+)$")
		S = "0"
	end
	if H == nil then
		return nil
	end

	local Hours = tonumber(H)
	local Minutes = tonumber(M)
	local Seconds = tonumber(S)
	if Hours == nil or Minutes == nil or Seconds == nil then
		return nil
	end

	return ((Hours % 24) + (Minutes / 60) + (Seconds / 3600)) % 24
end

local function clockTimeToTimeOfDay(ClockTime)
	local Normalized = toClockTime(ClockTime) or 0
	local Hours = math.floor(Normalized)
	local MinuteFloat = (Normalized - Hours) * 60
	local Minutes = math.floor(MinuteFloat)
	local Seconds = math.floor((MinuteFloat - Minutes) * 60 + 0.5)

	if Seconds >= 60 then
		Seconds -= 60
		Minutes += 1
	end
	if Minutes >= 60 then
		Minutes -= 60
		Hours = (Hours + 1) % 24
	end

	return string.format("%02d:%02d:%02d", Hours, Minutes, Seconds)
end

function ServicesExt.Register(Methods)
	Methods.Register("Pages", "GetCurrentPage", function(Inst)
		local Pages = Inst:GetProperty("_Pages")
		local PageIndex = tonumber(Inst:GetProperty("_PageIndex")) or 1
		if typeof(Pages) ~= "table" then
			return {}
		end

		return Pages[PageIndex] or {}
	end)

	Methods.Register("Pages", "AdvanceToNextPageAsync", function(Inst)
		local Pages = Inst:GetProperty("_Pages")
		local PageIndex = tonumber(Inst:GetProperty("_PageIndex")) or 1
		if typeof(Pages) ~= "table" then
			setHiddenProperty(Inst, "IsFinished", true)
			return
		end

		if PageIndex < #Pages then
			PageIndex += 1
			setHiddenProperty(Inst, "_PageIndex", PageIndex)
		end

		setHiddenProperty(Inst, "IsFinished", PageIndex >= #Pages)
	end)

	Methods.Register("MemStorageService", "SetItem", function(Inst, Key, Value)
		local Entries = ensureMemStorageItems(Inst)
		Entries[tostring(Key)] = Value
		return true
	end)

	Methods.Register("MemStorageService", "GetItem", function(Inst, Key)
		local Entries = ensureMemStorageItems(Inst)
		return Entries[tostring(Key)]
	end)

	Methods.Register("MemStorageService", "RemoveItem", function(Inst, Key)
		local Entries = ensureMemStorageItems(Inst)
		local Lookup = tostring(Key)
		local Previous = Entries[Lookup]
		Entries[Lookup] = nil
		return Previous
	end)

	Methods.Register("ContextActionService", "BindAction", function(Inst, ActionName, FunctionToBind, CreateTouchButton, ...)
		local Name = tostring(ActionName)
		local InputTypes = table.pack(...)
		local BoundActions = ensureContextActions(Inst)
		local StoredInputs = {}
		for I = 1, InputTypes.n do
			StoredInputs[I] = InputTypes[I]
		end
		BoundActions[Name] = {
			functionToBind = FunctionToBind,
			createTouchButton = CreateTouchButton == true,
			inputTypes = StoredInputs,
			priorityLevel = nil,
			isCore = false,
		}
	end)

	Methods.Register("ContextActionService", "BindActionAtPriority", function(Inst, ActionName, FunctionToBind, CreateTouchButton, PriorityLevel, ...)
		local Name = tostring(ActionName)
		local InputTypes = table.pack(...)
		local BoundActions = ensureContextActions(Inst)
		local StoredInputs = {}
		for I = 1, InputTypes.n do
			StoredInputs[I] = InputTypes[I]
		end
		BoundActions[Name] = {
			functionToBind = FunctionToBind,
			createTouchButton = CreateTouchButton == true,
			inputTypes = StoredInputs,
			priorityLevel = tonumber(PriorityLevel) or PriorityLevel,
			isCore = false,
		}
	end)

	Methods.Register("ContextActionService", "BindActionToInputTypes", function(Inst, ActionName, FunctionToBind, CreateTouchButton, ...)
		return Methods.GetSpecific(Inst, "BindAction")(Inst, ActionName, FunctionToBind, CreateTouchButton, ...)
	end)

	Methods.Register("ContextActionService", "GetAllBoundActionInfo", function(Inst)
		local BoundActions = ensureContextActions(Inst)
		return snapshotContextActions(BoundActions)
	end)

	Methods.Register("ContextActionService", "GetBoundActionInfo", function(Inst, ActionName)
		local BoundActions = ensureContextActions(Inst)
		local Info = BoundActions[tostring(ActionName)]
		if typeof(Info) ~= "table" then
			return nil
		end
		return {
			actionName = tostring(ActionName),
			createTouchButton = Info.createTouchButton == true,
			inputTypes = copyArray(Info.inputTypes),
			functionToBind = Info.functionToBind,
			priorityLevel = Info.priorityLevel,
			isCore = Info.isCore == true,
		}
	end)

	Methods.Register("ContextActionService", "UnbindAction", function(Inst, ActionName)
		local BoundActions = ensureContextActions(Inst)
		BoundActions[tostring(ActionName)] = nil
	end)

	Methods.Register("ContextActionService", "UnbindAllActions", function(Inst)
		local BoundActions = ensureContextActions(Inst)
		table.clear(BoundActions)
	end)

	Methods.Register("DataStoreService", "GetDataStore", function(Inst, Name, Scope)
		if not isValidDataStoreToken(Name) then
			error("DataStore key rejected", 0)
		end
		if Scope ~= nil and not isValidDataStoreToken(Scope) then
			error("DataStore scope rejected", 0)
		end
		return ensureDataStore(Inst, "DataStore", Name, Scope)
	end)

	Methods.Register("DataStoreService", "GetGlobalDataStore", function(Inst)
		error("Global store unavailable", 0)
	end)

	Methods.Register("DataStoreService", "GetOrderedDataStore", function(Inst, Name, Scope)
		if not isValidDataStoreToken(Name) then
			error("Ordered store key rejected", 0)
		end
		if Scope ~= nil and not isValidDataStoreToken(Scope) then
			error("Ordered store scope rejected", 0)
		end
		return ensureDataStore(Inst, "OrderedDataStore", Name, Scope)
	end)

	Methods.Register("DataStoreService", "GetRequestBudgetForRequestType", function(_Inst, _RequestType)
		return 100
	end)

	Methods.Register("DataStoreService", "SetRateLimitForRequestType", function(Inst, RequestType, BaseLimit, PerPlayerLimit)
		local Limits = ensureBucket(Inst, "_RequestLimits")
		Limits[tostring(RequestType)] = {
			BaseLimit = tonumber(BaseLimit) or 0,
			PerPlayerLimit = tonumber(PerPlayerLimit) or 0,
		}
	end)

	Methods.Register("DataStoreService", "ListDataStoresAsync", function(Inst, Prefix, PageSize)
		local Entries = getStoreListing(Inst, Prefix)
		return buildPages(Inst, "DataStoreListingPages", Entries, PageSize)
	end)

	Methods.Register("GlobalDataStore", "GetAsync", function(Inst, Key)
		local Entries = dataStoreEntries(Inst)
		return Entries[Key]
	end)

	Methods.Register("GlobalDataStore", "SetAsync", function(Inst, Key, Value)
		local Entries = dataStoreEntries(Inst)
		Entries[Key] = Value
		notifyStoreUpdate(Inst, Key, Value)
		return Value
	end)

	Methods.Register("GlobalDataStore", "IncrementAsync", function(Inst, Key, Delta)
		local Entries = dataStoreEntries(Inst)
		local Current = tonumber(Entries[Key]) or 0
		local Step = tonumber(Delta)
		if Step == nil then
			Step = 1
		end
		local Next = Current + Step
		Entries[Key] = Next
		notifyStoreUpdate(Inst, Key, Next)
		return Next
	end)

	Methods.Register("GlobalDataStore", "RemoveAsync", function(Inst, Key)
		local Entries = dataStoreEntries(Inst)
		local Previous = Entries[Key]
		Entries[Key] = nil
		notifyStoreUpdate(Inst, Key, nil)
		return Previous
	end)

	Methods.Register("GlobalDataStore", "UpdateAsync", function(Inst, Key, TransformFunction)
		local Entries = dataStoreEntries(Inst)
		local Previous = Entries[Key]
		if typeof(TransformFunction) ~= "function" then
			return Previous
		end

		local Ok, NextValue = pcall(TransformFunction, Previous)
		if not Ok then
			error(NextValue, 0)
		end

		if NextValue ~= nil then
			Entries[Key] = NextValue
			notifyStoreUpdate(Inst, Key, NextValue)
			return NextValue
		end

		return Previous
	end)

	Methods.Register("GlobalDataStore", "OnUpdate", function(Inst, Key, Callback)
		if typeof(Callback) ~= "function" then
			error("GlobalDataStore:OnUpdate() callback must be a function", 0)
		end

		local SignalsByKey = ensureBucket(Inst, "_UpdateSignals")
		local Signal = SignalsByKey[Key]
		if Signal == nil then
			Signal = Signals.ForInstance(Inst, `OnUpdate_{Key}`)
			SignalsByKey[Key] = Signal
		end

		return Signals.DirectConnect(Signal, Callback)
	end)

	Methods.Register("OrderedDataStore", "GetSortedAsync", function(Inst, Ascending, PageSize, MinValue, MaxValue)
		local Entries = dataStoreEntries(Inst)
		local Items = {}
		for Key, Value in next, Entries do
			if typeof(Value) == "number" then
				if MinValue ~= nil and Value < MinValue then
					continue
				end
				if MaxValue ~= nil and Value > MaxValue then
					continue
				end
			end

			Items[#Items + 1] = {
				key = Key,
				value = Value,
			}
		end

		table.sort(Items, function(Left, Right)
			local LV = Left.value
			local RV = Right.value
			if typeof(LV) == "number" and typeof(RV) == "number" then
				if Ascending then
					if LV == RV then
						return tostring(Left.key) < tostring(Right.key)
					end
					return LV < RV
				end
				if LV == RV then
					return tostring(Left.key) < tostring(Right.key)
				end
				return LV > RV
			end

			if Ascending then
				return tostring(Left.key) < tostring(Right.key)
			end
			return tostring(Left.key) > tostring(Right.key)
		end)

		return buildPages(Inst, "DataStorePages", Items, PageSize)
	end)

	Methods.Register("MemoryStoreService", "GetHashMap", function(Inst, Name)
		local Cache = ensureBucket(Inst, "_HashMaps")
		local Key = tostring(Name)
		if Cache[Key] == nil then
			local Map = createInternalInstance(Inst, "MemoryStoreHashMap", Key)
			setHiddenProperty(Map, "_MemoryEntries", {})
			Cache[Key] = Map
		end
		return Cache[Key]
	end)

	Methods.Register("MemoryStoreService", "GetQueue", function(Inst, Name, InvisibilityTimeout)
		local Cache = ensureBucket(Inst, "_Queues")
		local Key = tostring(Name)
		if Cache[Key] == nil then
			local Queue = createInternalInstance(Inst, "MemoryStoreQueue", Key)
			setHiddenProperty(Queue, "_QueueEntries", {})
			setHiddenProperty(Queue, "_InvisibilityTimeout", tonumber(InvisibilityTimeout) or 30)
			Cache[Key] = Queue
		end
		return Cache[Key]
	end)

	Methods.Register("MemoryStoreService", "GetSortedMap", function(Inst, Name)
		local Cache = ensureBucket(Inst, "_SortedMaps")
		local Key = tostring(Name)
		if Cache[Key] == nil then
			local Map = createInternalInstance(Inst, "MemoryStoreSortedMap", Key)
			setHiddenProperty(Map, "_MemoryEntries", {})
			Cache[Key] = Map
		end
		return Cache[Key]
	end)

	Methods.Register("MemoryStoreHashMap", "GetAsync", function(Inst, Key)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Entry = Entries[Key]
		return Entry and Entry.Value or nil
	end)

	Methods.Register("MemoryStoreHashMap", "SetAsync", function(Inst, Key, Value, Expiration)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		Entries[Key] = {
			Value = Value,
			ExpireAt = os.clock() + math.max(0, tonumber(Expiration) or 0),
		}
		return true
	end)

	Methods.Register("MemoryStoreHashMap", "RemoveAsync", function(Inst, Key)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		Entries[Key] = nil
	end)

	Methods.Register("MemoryStoreHashMap", "UpdateAsync", function(Inst, Key, TransformFunction, Expiration)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Previous = Entries[Key]
		local PreviousValue = Previous and Previous.Value or nil
		if typeof(TransformFunction) ~= "function" then
			return PreviousValue
		end

		local Ok, NextValue = pcall(TransformFunction, PreviousValue)
		if not Ok then
			error(NextValue, 0)
		end

		if NextValue ~= nil then
			Entries[Key] = {
				Value = NextValue,
				ExpireAt = os.clock() + math.max(0, tonumber(Expiration) or 0),
			}
			return NextValue
		end

		return PreviousValue
	end)

	Methods.Register("MemoryStoreHashMap", "ListItemsAsync", function(Inst, Count)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Items = {}
		for Key, Value in next, Entries do
			Items[#Items + 1] = {
				key = Key,
				value = Value.Value,
			}
		end
		table.sort(Items, function(Left, Right)
			return tostring(Left.key) < tostring(Right.key)
		end)
		return buildPages(Inst, "MemoryStoreHashMapPages", Items, Count)
	end)

	Methods.Register("MemoryStoreSortedMap", "GetAsync", function(Inst, Key)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Entry = Entries[Key]
		return Entry and Entry.Value or nil
	end)

	Methods.Register("MemoryStoreSortedMap", "SetAsync", function(Inst, Key, Value, Expiration, SortKey)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		Entries[Key] = {
			Value = Value,
			SortKey = SortKey ~= nil and SortKey or Value,
			ExpireAt = os.clock() + math.max(0, tonumber(Expiration) or 0),
		}
		return true
	end)

	Methods.Register("MemoryStoreSortedMap", "RemoveAsync", function(Inst, Key)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		Entries[Key] = nil
	end)

	Methods.Register("MemoryStoreSortedMap", "GetSizeAsync", function(Inst)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Count = 0
		for _ in next, Entries do
			Count += 1
		end
		return Count
	end)

	Methods.Register("MemoryStoreSortedMap", "UpdateAsync", function(Inst, Key, TransformFunction, Expiration)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Previous = Entries[Key]
		local PreviousValue = Previous and Previous.Value or nil
		if typeof(TransformFunction) ~= "function" then
			return PreviousValue
		end

		local Ok, NextValue = pcall(TransformFunction, PreviousValue)
		if not Ok then
			error(NextValue, 0)
		end

		if NextValue ~= nil then
			Entries[Key] = {
				Value = NextValue,
				SortKey = Previous and Previous.SortKey or NextValue,
				ExpireAt = os.clock() + math.max(0, tonumber(Expiration) or 0),
			}
			return NextValue
		end

		return PreviousValue
	end)

	Methods.Register("MemoryStoreSortedMap", "GetRangeAsync", function(Inst, Direction, Count, ExclusiveLowerBound, ExclusiveUpperBound)
		local Entries = ensureBucket(Inst, "_MemoryEntries")
		cleanupExpiringEntries(Entries)
		local Items = {}
		for Key, Entry in next, Entries do
			local SortKey = Entry.SortKey
			if ExclusiveLowerBound ~= nil and SortKey <= ExclusiveLowerBound then
				continue
			end
			if ExclusiveUpperBound ~= nil and SortKey >= ExclusiveUpperBound then
				continue
			end

			Items[#Items + 1] = {
				key = Key,
				value = Entry.Value,
				sortKey = SortKey,
			}
		end

		local DirectionName = string.lower(easingName(Direction))
		table.sort(Items, function(Left, Right)
			if Left.sortKey == Right.sortKey then
				return tostring(Left.key) < tostring(Right.key)
			end

			if DirectionName == "descending" then
				return Left.sortKey > Right.sortKey
			end
			return Left.sortKey < Right.sortKey
		end)

		local Limit = math.max(0, math.floor(tonumber(Count) or #Items))
		local Out = {}
		for Index = 1, math.min(Limit, #Items) do
			Out[#Out + 1] = Items[Index]
		end
		return Out
	end)

	Methods.Register("MemoryStoreQueue", "AddAsync", function(Inst, Value, Expiration, Priority)
		local Queue = ensureBucket(Inst, "_QueueEntries")
		Queue[#Queue + 1] = {
			Id = IdentityUtil.Generate(12),
			Value = Value,
			Priority = tonumber(Priority) or 0,
			ExpireAt = os.clock() + math.max(0, tonumber(Expiration) or 0),
			InvisibleUntil = nil,
		}

		table.sort(Queue, function(Left, Right)
			if Left.Priority == Right.Priority then
				return tostring(Left.Id) < tostring(Right.Id)
			end
			return Left.Priority > Right.Priority
		end)
	end)

	Methods.Register("MemoryStoreQueue", "GetSizeAsync", function(Inst, ExcludeInvisible)
		local Queue = ensureBucket(Inst, "_QueueEntries")
		local Now = os.clock()
		local Count = 0
		for Index = #Queue, 1, -1 do
			local Entry = Queue[Index]
			if typeof(Entry.ExpireAt) == "number" and Entry.ExpireAt <= Now then
				table.remove(Queue, Index)
				continue
			end

			if ExcludeInvisible and typeof(Entry.InvisibleUntil) == "number" and Entry.InvisibleUntil > Now then
				continue
			end

			Count += 1
		end
		return Count
	end)

	Methods.Register("MemoryStoreQueue", "ReadAsync", function(Inst, Count, AllOrNothing, _WaitTimeout)
		local Queue = ensureBucket(Inst, "_QueueEntries")
		local Now = os.clock()
		local Limit = math.max(0, math.floor(tonumber(Count) or 1))
		local InvisibleFor = tonumber(Inst:GetProperty("_InvisibilityTimeout")) or 30
		local Out = {}

		for Index = #Queue, 1, -1 do
			local Entry = Queue[Index]
			if typeof(Entry.ExpireAt) == "number" and Entry.ExpireAt <= Now then
				table.remove(Queue, Index)
			end
		end

		for _, Entry in ipairs(Queue) do
			if #Out >= Limit then
				break
			end

			if typeof(Entry.InvisibleUntil) == "number" and Entry.InvisibleUntil > Now then
				continue
			end

			Entry.InvisibleUntil = Now + math.max(0, InvisibleFor)
			Out[#Out + 1] = Entry.Value
		end

		if AllOrNothing and #Out < Limit then
			return {}
		end

		return Out
	end)

	Methods.Register("MemoryStoreQueue", "RemoveAsync", function(Inst, Id)
		local Queue = ensureBucket(Inst, "_QueueEntries")
		for Index = #Queue, 1, -1 do
			if tostring(Queue[Index].Id) == tostring(Id) then
				table.remove(Queue, Index)
				break
			end
		end
	end)

	Methods.Register("MessagingService", "PublishAsync", function(Inst, Topic, Message)
		local Payload = {
			Data = Message,
			Topic = Topic,
			Sent = os.time(),
		}
		messageTopicSignal(Inst, tostring(Topic)):Fire(Payload)
	end)

	Methods.Register("MessagingService", "SubscribeAsync", function(Inst, Topic, Callback)
		if typeof(Callback) ~= "function" then
			error("MessagingService:SubscribeAsync() callback must be a function", 0)
		end

		return Signals.DirectConnect(messageTopicSignal(Inst, tostring(Topic)), Callback)
	end)

	Methods.Register("BadgeService", "AwardBadgeAsync", function(Inst, UserId, BadgeId)
		badgeUserBucket(Inst, UserId)[tostring(BadgeId)] = true
		return true
	end)

	Methods.Register("BadgeService", "AwardBadge", function(Inst, UserId, BadgeId)
		return Methods.GetSpecific(Inst, "AwardBadgeAsync")(Inst, UserId, BadgeId)
	end)

	Methods.Register("BadgeService", "UserHasBadgeAsync", function(Inst, UserId, BadgeId)
		return badgeUserBucket(Inst, UserId)[tostring(BadgeId)] == true
	end)

	Methods.Register("BadgeService", "UserHasBadge", function(Inst, UserId, BadgeId)
		return Methods.GetSpecific(Inst, "UserHasBadgeAsync")(Inst, UserId, BadgeId)
	end)

	Methods.Register("BadgeService", "CheckUserBadgesAsync", function(Inst, UserId, BadgeIds)
		local Out = {}
		if typeof(BadgeIds) ~= "table" then
			return Out
		end

		for Index, BadgeId in ipairs(BadgeIds) do
			Out[Index] = badgeUserBucket(Inst, UserId)[tostring(BadgeId)] == true
		end
		return Out
	end)

	Methods.Register("BadgeService", "GetBadgeInfoAsync", function(_Inst, BadgeId)
		local NumericId = math.max(0, math.floor(math.abs(tonumber(BadgeId) or 0)))
		return {
			BadgeId = NumericId,
			Name = `Badge {NumericId}`,
			Description = "",
			IconImageId = 0,
			Enabled = true,
		}
	end)

	Methods.Register("BadgeService", "IsDisabled", function(_Inst, _BadgeId)
		return false
	end)

	Methods.Register("BadgeService", "IsLegal", function(_Inst, _BadgeId)
		return true
	end)

	Methods.Register("LocalizationService", "GetCorescriptLocalizations", function(Inst)
		local Source = ensureCorescriptLocalizations(Inst)
		local Out = {}
		for Index, Value in ipairs(Source) do
			Out[Index] = Value
		end
		return Out
	end)

	Methods.Register("LocalizationService", "GetTableEntries", function(_Inst, _Instance)
		return {}
	end)

	Methods.Register("LocalizationService", "SetRobloxLocaleId", function(Inst, Locale)
		setHiddenProperty(Inst, "RobloxLocaleId", normalizeLocale(Locale))
	end)

	Methods.Register("LocalizationService", "GetTranslatorForLocaleAsync", function(Inst, Locale)
		return ensureTranslator(Inst, Locale)
	end)

	Methods.Register("LocalizationService", "GetTranslatorForPlayer", function(Inst, Player)
		if typeof(Player) ~= "table" or typeof(Player.GetClassName) ~= "function" or Player:GetClassName() ~= "Player" then
			error("LocalizationService:GetTranslatorForPlayer() player must be a Player", 0)
		end

		local Locale = DEFAULT_LOCALE
		if typeof(Player) == "table" and typeof(Player.GetProperty) == "function" then
			Locale = Player:GetProperty("LocaleId") or Inst:GetProperty("RobloxLocaleId") or DEFAULT_LOCALE
		end
		return ensureTranslator(Inst, Locale)
	end)

	Methods.Register("LocalizationService", "GetTranslatorForPlayerAsync", function(Inst, Player)
		return Methods.GetSpecific(Inst, "GetTranslatorForPlayer")(Inst, Player)
	end)

	Methods.Register("LocalizationService", "GetCountryRegionForPlayerAsync", function(Inst, Player)
		if typeof(Player) ~= "table" or typeof(Player.GetClassName) ~= "function" or Player:GetClassName() ~= "Player" then
			error("LocalizationService:GetCountryRegionForPlayerAsync() player must be a Player", 0)
		end

		local Locale = Inst:GetProperty("RobloxLocaleId") or DEFAULT_LOCALE
		if typeof(Player) == "table" and typeof(Player.GetProperty) == "function" then
			Locale = Player:GetProperty("LocaleId") or Locale
		end
		return getLocaleRegion(Locale)
	end)

	Methods.Register("LocalizationService", "GetIsLoadingInternalTranslations", function(_Inst)
		return false
	end)

	Methods.Register("Translator", "FormatByKey", function(_Inst, Key, Args)
		return formatTemplate(tostring(Key or ""), Args)
	end)

	Methods.Register("Translator", "Translate", function(_Inst, _Context, Text)
		return tostring(Text or "")
	end)

	Methods.Register("TextChatService", "CreateDefaultTextChannels", function(Inst)
		local TextChannels = Inst:GetProperty("TextChannels")
		if typeof(TextChannels) ~= "table" then
			TextChannels = createInternalInstance(Inst, "Folder", "TextChannels")
			TextChannels:SetParent(Inst)
			setHiddenProperty(Inst, "TextChannels", TextChannels)
		end

		local General = TextChannels:FindFirstChild("RBXGeneral")
		if General == nil then
			General = createInternalInstance(Inst, "TextChannel", "RBXGeneral")
			General:SetParent(TextChannels)
		end

		return TextChannels
	end)

	Methods.Register("TextChannel", "SendAsync", function(Inst, Message, Metadata)
		local Text = tostring(Message or "")
		local Meta = tostring(Metadata or "")
		local Service = Inst:GetParent()
		if typeof(Service) == "table" and Service.IsA and not Service:IsA("TextChatService") then
			Service = Service:GetParent()
		end

		local PlayersService = require("../../Services").GetOrNil("Players")
		local LocalPlayer = typeof(PlayersService) == "table" and PlayersService:GetProperty("LocalPlayer") or nil
		local UserId = tonumber(typeof(LocalPlayer) == "table" and LocalPlayer:GetProperty("UserId")) or 0
		local PlayerName = typeof(LocalPlayer) == "table" and tostring(LocalPlayer:GetName()) or "LocalPlayer"

		local MessageObj = {
			__larryType = "TextChatMessage",
			Text = Text,
			Metadata = Meta,
			PrefixText = "",
			Status = enumItem("TextChatMessageStatus", "Success"),
			TextSource = {
				__larryType = "TextSource",
				UserId = UserId,
				Name = PlayerName,
			},
			TextChannel = Inst,
			Timestamp = os.time(),
		}

		Signals.ForInstance(Inst, "MessageReceived"):Fire(MessageObj)
		if typeof(Service) == "table" and Service.IsA and Service:IsA("TextChatService") then
			Signals.ForInstance(Service, "SendingMessage"):Fire(MessageObj)
			Signals.ForInstance(Service, "MessageReceived"):Fire(MessageObj)
			Signals.ForInstance(Service, "OnIncomingMessageEvent"):Fire(MessageObj)
		end

		return MessageObj
	end)

	Methods.Register("TextChannel", "DisplaySystemMessage", function(Inst, SystemMessage, Metadata)
		return Methods.GetSpecific(Inst, "SendAsync")(Inst, SystemMessage, Metadata)
	end)

	Methods.Register("TextService", "FilterStringAsync", function(Inst, StringToFilter, _FromUserId, _TextContext)
		return newTextFilterResult(Inst, StringToFilter)
	end)

	Methods.Register("TextService", "FilterAndTranslateStringAsync", function(Inst, StringToFilter, _FromUserId, TargetLocales, _TextContext)
		return newTranslatedFilterResult(Inst, StringToFilter, TargetLocales)
	end)

	Methods.Register("TextService", "GetTextSize", function(_Inst, Text, FontSize, _Font, FrameSize)
		local MaxWidth = nil
		local X = readComponents(FrameSize)
		if X ~= nil then
			MaxWidth = X
		elseif typeof(FrameSize) == "table" then
			MaxWidth = rawget(FrameSize, "X")
		end
		return measureText(Text, FontSize, MaxWidth)
	end)

	Methods.Register("TextService", "GetTextBoundsAsync", function(_Inst, Params)
		if typeof(Params) ~= "table" then
			return measureText("", 14, nil)
		end

		local Text = Params.Text or (typeof(Params.GetProperty) == "function" and Params:GetProperty("Text")) or ""
		local Size = Params.Size or (typeof(Params.GetProperty) == "function" and Params:GetProperty("Size")) or 14
		local Width = Params.Width or (typeof(Params.GetProperty) == "function" and Params:GetProperty("Width")) or nil
		return measureText(Text, Size, Width)
	end)

	Methods.Register("TextService", "GetTextSizeOffsetAsync", function(_Inst, FontSize, _Font)
		return math.max(1, math.floor((tonumber(FontSize) or 14) * 0.15))
	end)

	Methods.Register("TextService", "GetFamilyInfoAsync", function(_Inst, AssetId)
		return {
			Name = tostring(AssetId or "FontFamily"),
			Faces = {},
		}
	end)

	Methods.Register("TextFilterResult", "GetNonChatStringForBroadcastAsync", function(Inst)
		return Inst:GetProperty("_FilteredText") or ""
	end)

	Methods.Register("TextFilterResult", "GetNonChatStringForUserAsync", function(Inst, _ToUserId)
		return Inst:GetProperty("_FilteredText") or ""
	end)

	Methods.Register("TextFilterResult", "GetChatForUserAsync", function(Inst, _ToUserId)
		return Inst:GetProperty("_FilteredText") or ""
	end)

	Methods.Register("TextFilterTranslatedResult", "GetTranslationForLocale", function(Inst, Locale)
		local Translations = Inst:GetProperty("_Translations") or {}
		return newTextFilterResult(Inst, Translations[normalizeLocale(Locale)] or "")
	end)

	Methods.Register("TextFilterTranslatedResult", "GetTranslations", function(Inst)
		local Translations = Inst:GetProperty("_Translations")
		if typeof(Translations) == "table" then
			return Translations
		end
		return {}
	end)

	Methods.Register("TeleportOptions", "GetTeleportData", function(Inst)
		return Inst:GetProperty("_TeleportData")
	end)

	Methods.Register("TeleportOptions", "SetTeleportData", function(Inst, TeleportData)
		setHiddenProperty(Inst, "_TeleportData", TeleportData)
	end)

	Methods.Register("TeleportService", "SetTeleportGui", function(Inst, Gui)
		setHiddenProperty(Inst, "_ArrivingTeleportGui", Gui)
	end)

	Methods.Register("TeleportService", "GetArrivingTeleportGui", function(Inst)
		return Inst:GetProperty("_ArrivingTeleportGui")
	end)

	Methods.Register("TeleportService", "SetTeleportSetting", function(Inst, Setting, Value)
		local Settings = ensureBucket(Inst, "_TeleportSettings")
		Settings[tostring(Setting)] = Value
	end)

	Methods.Register("TeleportService", "GetTeleportSetting", function(Inst, Setting)
		local Settings = ensureBucket(Inst, "_TeleportSettings")
		return Settings[tostring(Setting)]
	end)

	Methods.Register("TeleportService", "GetLocalPlayerTeleportData", function(Inst)
		return Inst:GetProperty("_LocalTeleportData")
	end)

	Methods.Register("TeleportService", "ReserveServerAsync", function(_Inst, PlaceId)
		local AccessCode = IdentityUtil.Generate(24)
		local PrivateServerId = `private_{PlaceId}_{IdentityUtil.Generate(12)}`
		return AccessCode, PrivateServerId
	end)

	Methods.Register("TeleportService", "ReserveServer", function(Inst, PlaceId)
		return Methods.GetSpecific(Inst, "ReserveServerAsync")(Inst, PlaceId)
	end)

	Methods.Register("TeleportService", "PromptExperienceDetailsAsync", function(_Inst, _Player, _UniverseId)
		return enumItem("PromptExperienceDetailsResult", "Success")
	end)

	Methods.Register("TeleportService", "GetPlayerPlaceInstanceAsync", function(_Inst, _UserId)
		return getGameProperty("PlaceId"), getGameProperty("JobId")
	end)

	Methods.Register("TeleportService", "Teleport", function(Inst, PlaceId, Player, TeleportData, CustomLoadingScreen)
		local Players = {}
		if Player ~= nil then
			Players[1] = Player
		end
		teleportLocalPlayer(Inst, PlaceId, TeleportData, CustomLoadingScreen, Players, "")
	end)

	Methods.Register("TeleportService", "TeleportAsync", function(Inst, PlaceId, Players, TeleportOptions)
		local TeleportData = nil
		if typeof(TeleportOptions) == "table" and typeof(TeleportOptions.GetTeleportData) == "function" then
			TeleportData = TeleportOptions:GetTeleportData()
		end
		teleportLocalPlayer(Inst, PlaceId, TeleportData, nil, Players, "")
		return TeleportOptions
	end)

	Methods.Register("TeleportService", "TeleportPartyAsync", function(Inst, PlaceId, Players, TeleportData, CustomLoadingScreen)
		teleportLocalPlayer(Inst, PlaceId, TeleportData, CustomLoadingScreen, Players, "")
		return `party_{IdentityUtil.Generate(16)}`
	end)

	Methods.Register("TeleportService", "TeleportToPlaceInstance", function(Inst, PlaceId, InstanceId, Player, SpawnName, TeleportData, CustomLoadingScreen)
		local Players = {}
		if Player ~= nil then
			Players[1] = Player
		end
		setHiddenProperty(Inst, "_LastServerInstanceId", InstanceId)
		teleportLocalPlayer(Inst, PlaceId, TeleportData, CustomLoadingScreen, Players, SpawnName)
	end)

	Methods.Register("TeleportService", "TeleportToPrivateServer", function(Inst, PlaceId, ReservedServerAccessCode, Players, SpawnName, TeleportData, CustomLoadingScreen)
		setHiddenProperty(Inst, "_ReservedServerAccessCode", ReservedServerAccessCode)
		teleportLocalPlayer(Inst, PlaceId, TeleportData, CustomLoadingScreen, Players, SpawnName)
	end)

	Methods.Register("TeleportService", "TeleportToSpawnByName", function(Inst, PlaceId, SpawnName, Player, TeleportData, CustomLoadingScreen)
		local Players = {}
		if Player ~= nil then
			Players[1] = Player
		end
		teleportLocalPlayer(Inst, PlaceId, TeleportData, CustomLoadingScreen, Players, SpawnName)
	end)

	Methods.Register("TeleportService", "TeleportTrustedBackHistory", function(Inst, PlaceId)
		buildTeleportHistory(Inst, PlaceId)
	end)

	Methods.Register("TeleportService", "TeleportedPlacesBackHistory", function(Inst)
		return ensureBucket(Inst, "_PlaceHistory")
	end)

	Methods.Register("TeleportService", "TeleportedUniversesBackHistory", function(Inst)
		return ensureBucket(Inst, "_UniverseHistory")
	end)

	Methods.Register("TeleportService", "GetThirdPartyTeleportInfo", function(_Inst, _GoForth)
		return {}
	end)

	Methods.Register("TeleportService", "UnblockAsync", function(_Inst)
		return true
	end)

	Methods.Register("TeleportService", "TeleportCancel", function(_Inst) end)
	Methods.Register("TeleportService", "TeleportReconnect", function(_Inst) end)
	Methods.Register("TeleportService", "TeleportTrustedBackForth", function(_Inst, _GoForth) end)
	Methods.Register("TeleportService", "PromptExperienceDetailsCompleted", function(_Inst, _ResultEnum, _ErrorMessage) end)
	Methods.Register("TeleportService", "Block", function(_Inst) end)

	Methods.Register("PathfindingService", "CreatePath", function(Inst, AgentParameters)
		local Path = createInternalInstance(Inst, "Path", "Path")
		setHiddenProperty(Path, "_AgentParameters", AgentParameters or {})
		setHiddenProperty(Path, "_Waypoints", {})
		setHiddenProperty(Path, "_PointCoordinates", {})
		setHiddenProperty(Path, "Status", enumItem("PathStatus", "NoPath"))
		return Path
	end)

	Methods.Register("Path", "ComputeAsync", function(Inst, Start, Finish)
		local SX, SY, SZ = readComponents(Start)
		local FX, FY, FZ = readComponents(Finish)
		local Midpoint
		if SX ~= nil and FX ~= nil then
			Midpoint = makeVector3((SX + FX) / 2, (SY + FY) / 2, ((SZ or 0) + (FZ or 0)) / 2)
		else
			Midpoint = makeVector3(0, 0, 0)
		end

		local Waypoints = {
			pathWaypoint(Start, "Walk"),
			pathWaypoint(Midpoint, "Walk"),
			pathWaypoint(Finish, "Walk"),
		}

		setHiddenProperty(Inst, "_Waypoints", Waypoints)
		setHiddenProperty(Inst, "_PointCoordinates", { Start, Midpoint, Finish })
		setHiddenProperty(Inst, "Status", enumItem("PathStatus", "Success"))
	end)

	Methods.Register("Path", "GetWaypoints", function(Inst)
		return Inst:GetProperty("_Waypoints") or {}
	end)

	Methods.Register("Path", "GetPointCoordinates", function(Inst)
		return Inst:GetProperty("_PointCoordinates") or {}
	end)

	Methods.Register("Path", "CheckOcclusionAsync", function(_Inst, _Start)
		return -1
	end)

	Methods.Register("PathfindingService", "FindPathAsync", function(Inst, Start, Finish)
		local Path = Methods.GetSpecific(Inst, "CreatePath")(Inst, nil)
		Path:ComputeAsync(Start, Finish)
		return Path
	end)

	Methods.Register("PathfindingService", "ComputeRawPathAsync", function(Inst, Start, Finish, _MaxDistance)
		return Methods.GetSpecific(Inst, "FindPathAsync")(Inst, Start, Finish)
	end)

	Methods.Register("PathfindingService", "ComputeSmoothPathAsync", function(Inst, Start, Finish, _MaxDistance)
		return Methods.GetSpecific(Inst, "FindPathAsync")(Inst, Start, Finish)
	end)

	Methods.Register("TweenService", "Create", function(Inst, Target, TweenInfo, PropertyTable)
		if typeof(PropertyTable) ~= "table" then
			error("TweenService:Create propertyTable must be a table", 0)
		end

		if typeof(Target) == "table" and typeof(Target.GetProperty) == "function" then
			for PropertyName, Goal in next, PropertyTable do
				local Current = Target:GetProperty(PropertyName)
				if Current ~= nil and not tweenValuesCompatible(Current, Goal) then
					error(`TweenService:Create invalid goal type for property {tostring(PropertyName)}`, 0)
				end
			end
		end

		local Tween = createInternalInstance(Inst, "Tween", "Tween")
		setHiddenProperty(Tween, "Instance", Target)
		setHiddenProperty(Tween, "TweenInfo", TweenInfo)
		setHiddenProperty(Tween, "_TweenProperties", PropertyTable or {})
		setHiddenProperty(Tween, "PlaybackState", enumItem("PlaybackState", "Begin"))
		return Tween
	end)

	Methods.Register("TweenService", "GetValue", function(_Inst, Alpha, EasingStyle, EasingDirection)
		local A = tonumber(Alpha) or 0
		return applyEasingDirection(A, easingName(EasingStyle), easingName(EasingDirection))
	end)

	Methods.Register("TweenService", "SmoothDamp", function(_Inst, Current, Target, Velocity, SmoothTime, _MaxSpeed, Dt)
		local DeltaTime = tonumber(Dt)
		if DeltaTime == nil or DeltaTime <= 0 then
			DeltaTime = 1 / 60
		end

		local Time = math.max(0.0001, tonumber(SmoothTime) or 0.15)
		local Alpha = math.max(0, math.min(1, DeltaTime / (Time + DeltaTime)))
		local NextValue = lerpValue(Current, Target, Alpha)
		local Difference = subtractValue(NextValue, Current)
		local NextVelocity = Difference ~= nil and scaleValue(Difference, 1 / DeltaTime) or Velocity or zeroLike(Target)
		return NextValue, NextVelocity
	end)

	Methods.Register("SoundService", "GetListener", function(_Inst)
		return enumItem("ListenerType", "Camera") or enumItem("ListenerType", "CFrame") or enumItem("ListenerType", "ObjectPosition")
	end)

	Methods.Register("Lighting", "GetMinutesAfterMidnight", function(Inst)
		local ClockTime = toClockTime(Inst:GetProperty("ClockTime"))
		if ClockTime == nil then
			ClockTime = parseTimeOfDay(Inst:GetProperty("TimeOfDay"))
		end
		if ClockTime == nil then
			ClockTime = 12
		end
		return ClockTime * 60
	end)

	Methods.Register("Lighting", "SetMinutesAfterMidnight", function(Inst, Minutes)
		local ClockTime = toClockTime((tonumber(Minutes) or 0) / 60) or 0
		setHiddenProperty(Inst, "ClockTime", ClockTime)
		setHiddenProperty(Inst, "TimeOfDay", clockTimeToTimeOfDay(ClockTime))
	end)

	Methods.Register("Lighting", "GetMoonPhase", function(_Inst)
		return 0
	end)

	Methods.Register("TweenBase", "Play", function(Inst)
		local PlayingState = enumItem("PlaybackState", "Playing")
		local CompletedState = enumItem("PlaybackState", "Completed")
		local Token = (tonumber(Inst:GetProperty("_LarryTweenToken")) or 0) + 1
		setHiddenProperty(Inst, "_LarryTweenToken", Token)
		setHiddenProperty(Inst, "_LarryTweenCompleteAtWaitSerial", nil)
		setHiddenProperty(Inst, "PlaybackState", PlayingState)

		local function FinalizeTween()
			if (tonumber(Inst:GetProperty("_LarryTweenToken")) or 0) ~= Token then
				return
			end

			local Current = Inst:GetProperty("PlaybackState")
			if Current ~= nil and Current ~= PlayingState then
				return
			end

			applyTweenProperties(Inst)
			setHiddenProperty(Inst, "PlaybackState", CompletedState)
			Signals.ForInstance(Inst, "Completed"):Fire(CompletedState)
		end

		local Duration = readTweenDuration(Inst:GetProperty("TweenInfo"))
		if Duration > 0 then
			local WaitSerial = 0
			local RuntimeState = rawget(Inst, "_State")
			if typeof(RuntimeState) == "table" then
				WaitSerial = tonumber(rawget(RuntimeState, "_LarryWaitSerial")) or 0
			end
			setHiddenProperty(Inst, "_LarryTweenCompleteAtWaitSerial", WaitSerial + 1)
		else
			FinalizeTween()
		end
	end)

	Methods.Register("TweenBase", "Pause", function(Inst)
		setHiddenProperty(Inst, "_LarryTweenToken", (tonumber(Inst:GetProperty("_LarryTweenToken")) or 0) + 1)
		setHiddenProperty(Inst, "_LarryTweenCompleteAtWaitSerial", nil)
		setHiddenProperty(Inst, "PlaybackState", enumItem("PlaybackState", "Paused"))
	end)

	Methods.Register("TweenBase", "Cancel", function(Inst)
		setHiddenProperty(Inst, "_LarryTweenToken", (tonumber(Inst:GetProperty("_LarryTweenToken")) or 0) + 1)
		setHiddenProperty(Inst, "_LarryTweenCompleteAtWaitSerial", nil)
		local CancelledState = enumItem("PlaybackState", "Cancelled")
		setHiddenProperty(Inst, "PlaybackState", CancelledState)
		Signals.ForInstance(Inst, "Completed"):Fire(CancelledState)
	end)
end

return ServicesExt