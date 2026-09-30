local Manifest = require("./ApiCatalog/manifest")

local ApiCatalog = {}

local LoadedShards = {}
local Classes = {}
local Enums = {}
local EnumOrder = {}
local GlobalFunctions = {}
local GlobalFunctionOverloads = {}

local WellKnownServiceClasses = {
	DataModel = true,
	Workspace = true,
	Players = true,
	ReplicatedStorage = true,
	ReplicatedFirst = true,
	ServerStorage = true,
	ServerScriptService = true,
	StarterGui = true,
	StarterPack = true,
	StarterPlayer = true,
	CoreGui = true,
	Teams = true,
	Lighting = true,
	Chat = true,
	Debris = true,
	Stats = true,
	RunService = true,
	UserInputService = true,
	SoundService = true,
}

local function loadShard(ShardName)
	if typeof(ShardName) ~= "string" or ShardName == "" then
		return nil
	end

	local Existing = LoadedShards[ShardName]
	if Existing then
		return Existing
	end

	local Loaded = require("./ApiCatalog/shards/" .. ShardName)
	LoadedShards[ShardName] = Loaded

	local ClassData = Loaded.Classes
	if typeof(ClassData) == "table" then
		for Name, Descriptor in next, ClassData do
			Classes[Name] = Descriptor
		end
	end

	local EnumData = Loaded.Enums
	if typeof(EnumData) == "table" then
		for Name, Descriptor in next, EnumData do
			Enums[Name] = Descriptor
		end
	end

	local EnumOrderData = Loaded.EnumOrder
	if typeof(EnumOrderData) == "table" then
		for Name, Order in next, EnumOrderData do
			EnumOrder[Name] = Order
		end
	end

	local GlobalData = Loaded.GlobalFunctions
	if typeof(GlobalData) == "table" then
		for Name, Descriptor in next, GlobalData do
			GlobalFunctions[Name] = Descriptor
		end
	end

	local GlobalOverloadData = Loaded.GlobalFunctionOverloads
	if typeof(GlobalOverloadData) == "table" then
		for Name, Overloads in next, GlobalOverloadData do
			GlobalFunctionOverloads[Name] = Overloads
		end
	end

	return Loaded
end

local function ensureClassLoaded(ClassName)
	if typeof(ClassName) ~= "string" then
		return nil
	end
	local ShardName = Manifest.Classes and Manifest.Classes[ClassName]
	if ShardName then
		loadShard(ShardName)
	end
	return Classes[ClassName]
end

local function ensureEnumLoaded(EnumName)
	if typeof(EnumName) ~= "string" then
		return nil
	end
	local ShardName = Manifest.Enums and Manifest.Enums[EnumName]
	if ShardName then
		loadShard(ShardName)
	end
	return Enums[EnumName]
end

local function ensureGlobalLoaded(MethodName)
	if typeof(MethodName) ~= "string" then
		return nil
	end
	local ShardName = Manifest.Globals and Manifest.Globals[MethodName]
	if ShardName then
		loadShard(ShardName)
	end
	return GlobalFunctions[MethodName]
end

local function walkInheritance(ClassName, Visitor)
	local Current = ClassName
	local Visited = {}

	while typeof(Current) == "string" and Current ~= "" and not Visited[Current] do
		Visited[Current] = true
		local Entry = ensureClassLoaded(Current)
		if Entry == nil then
			break
		end

		local Stop, Result = Visitor(Entry)
		if Stop then
			return Result
		end

		Current = Entry.Super
	end

	return nil
end

function ApiCatalog.GetClassDescriptor(ClassName)
	return ensureClassLoaded(ClassName)
end

function ApiCatalog.GetPropertyDescriptor(ClassName, PropertyName)
	return walkInheritance(ClassName, function(Entry)
		local Properties = Entry.Properties
		local Descriptor = typeof(Properties) == "table" and Properties[PropertyName] or nil
		if Descriptor ~= nil then
			return true, Descriptor
		end
		return false, nil
	end)
end

function ApiCatalog.GetFunctionDescriptor(ClassName, MethodName)
	return walkInheritance(ClassName, function(Entry)
		local Functions = Entry.Functions
		local Descriptor = typeof(Functions) == "table" and Functions[MethodName] or nil
		if Descriptor ~= nil then
			return true, Descriptor
		end

		local Callbacks = Entry.Callbacks
		local Callback = typeof(Callbacks) == "table" and Callbacks[MethodName] or nil
		if Callback ~= nil then
			return true, Callback
		end

		return false, nil
	end)
end

function ApiCatalog.GetCallbackDescriptor(ClassName, CallbackName)
	return walkInheritance(ClassName, function(Entry)
		local Callbacks = Entry.Callbacks
		local Descriptor = typeof(Callbacks) == "table" and Callbacks[CallbackName] or nil
		if Descriptor ~= nil then
			return true, Descriptor
		end
		return false, nil
	end)
end

function ApiCatalog.GetFunctionOverloads(ClassName, MethodName)
	return walkInheritance(ClassName, function(Entry)
		local FunctionOverloads = Entry.FunctionOverloads
		local Overloads = typeof(FunctionOverloads) == "table" and FunctionOverloads[MethodName] or nil
		if typeof(Overloads) == "table" and #Overloads > 0 then
			return true, Overloads
		end

		local CallbackOverloads = Entry.CallbackOverloads
		local CallbackList = typeof(CallbackOverloads) == "table" and CallbackOverloads[MethodName] or nil
		if typeof(CallbackList) == "table" and #CallbackList > 0 then
			return true, CallbackList
		end

		local FunctionTable = Entry.Functions
		local FunctionDescriptor = typeof(FunctionTable) == "table" and FunctionTable[MethodName] or nil
		if FunctionDescriptor ~= nil then
			return true, { FunctionDescriptor }
		end

		local CallbackTable = Entry.Callbacks
		local CallbackDescriptor = typeof(CallbackTable) == "table" and CallbackTable[MethodName] or nil
		if CallbackDescriptor ~= nil then
			return true, { CallbackDescriptor }
		end

		return false, nil
	end)
end

function ApiCatalog.GetAnyFunctionDescriptor(MethodName)
	return ensureGlobalLoaded(MethodName)
end

function ApiCatalog.GetAnyFunctionOverloads(MethodName)
	ensureGlobalLoaded(MethodName)
	local Overloads = GlobalFunctionOverloads[MethodName]
	if typeof(Overloads) == "table" and #Overloads > 0 then
		return Overloads
	end

	local Descriptor = GlobalFunctions[MethodName]
	if Descriptor ~= nil then
		return { Descriptor }
	end

	return nil
end

function ApiCatalog.GetEnumDescriptor(EnumName)
	local Items = ensureEnumLoaded(EnumName)
	if typeof(Items) ~= "table" then
		return nil
	end
	return {
		Name = EnumName,
		Items = Items,
		Order = EnumOrder[EnumName] or {},
	}
end

function ApiCatalog.HasServiceClass(ClassName)
	if typeof(ClassName) ~= "string" or ClassName == "" then
		return false
	end

	if WellKnownServiceClasses[ClassName] then
		return true
	end

	if string.match(ClassName, "Service$") then
		return true
	end

	local Descriptor = ensureClassLoaded(ClassName)
	if typeof(Descriptor) ~= "table" then
		return false
	end

	if typeof(Descriptor.Modifiers) == "string" and string.find(Descriptor.Modifiers, "Service", 1, true) then
		return true
	end

	return false
end

function ApiCatalog.Stats()
	local Stats = Manifest.Stats or {}
	return {
		class_count = Stats.ClassCount or 0,
		property_count = Stats.PropertyCount or 0,
		function_count = Stats.FunctionCount or 0,
		event_count = Stats.EventCount or 0,
		callback_count = Stats.CallbackCount or 0,
		enum_count = Stats.EnumCount or 0,
		enum_item_count = Stats.EnumItemCount or 0,
		shard_count = #(Manifest.Shards or {}),
	}
end

function ApiCatalog.GetStats()
	local Stats = Manifest.Stats or {}
	return {
		Loaded = Stats.Loaded ~= false,
		LoadError = Stats.LoadError,
		ClassCount = Stats.ClassCount or 0,
		PropertyCount = Stats.PropertyCount or 0,
		FunctionCount = Stats.FunctionCount or 0,
		EventCount = Stats.EventCount or 0,
		CallbackCount = Stats.CallbackCount or 0,
		EnumCount = Stats.EnumCount or 0,
		EnumItemCount = Stats.EnumItemCount or 0,
	}
end

function ApiCatalog.HasClass(ClassName)
	return ApiCatalog.GetClassDescriptor(ClassName) ~= nil
end

function ApiCatalog.GetClass(ClassName)
	return ApiCatalog.GetClassDescriptor(ClassName)
end

function ApiCatalog.ClassHasModifier(ClassName, ModifierName)
	if typeof(ModifierName) ~= "string" or ModifierName == "" then
		return false
	end

	local Descriptor = ApiCatalog.GetClassDescriptor(ClassName)
	if typeof(Descriptor) ~= "table" then
		return false
	end

	local Flags = Descriptor.ModifierFlags
	if typeof(Flags) ~= "table" then
		return false
	end

	return Flags[ModifierName] == true
end

function ApiCatalog.IsA(ClassName, TargetClass)
	if typeof(ClassName) ~= "string" or typeof(TargetClass) ~= "string" then
		return false
	end

	if ClassName == TargetClass then
		return true
	end

	return walkInheritance(ClassName, function(Entry)
		return Entry.Name == TargetClass, Entry.Name == TargetClass
	end) == true
end

function ApiCatalog.HasProperty(ClassName, PropertyName)
	return ApiCatalog.GetPropertyDescriptor(ClassName, PropertyName) ~= nil
end

function ApiCatalog.PropertyHasModifier(ClassName, PropertyName, ModifierName)
	if typeof(ModifierName) ~= "string" or ModifierName == "" then
		return false
	end

	local Descriptor = ApiCatalog.GetPropertyDescriptor(ClassName, PropertyName)
	if typeof(Descriptor) ~= "table" then
		return false
	end

	local Flags = Descriptor.ModifierFlags
	if typeof(Flags) ~= "table" then
		return false
	end

	return Flags[ModifierName] == true
end

function ApiCatalog.HasFunction(ClassName, MethodName)
	return ApiCatalog.GetFunctionDescriptor(ClassName, MethodName) ~= nil
end

function ApiCatalog.HasCallback(ClassName, CallbackName)
	return ApiCatalog.GetCallbackDescriptor(ClassName, CallbackName) ~= nil
end

function ApiCatalog.HasAnyFunction(MethodName)
	return ApiCatalog.GetAnyFunctionDescriptor(MethodName) ~= nil
end

function ApiCatalog.GetEventDescriptor(ClassName, EventName)
	return walkInheritance(ClassName, function(Entry)
		local Events = Entry.Events
		local Descriptor = typeof(Events) == "table" and Events[EventName] or nil
		if Descriptor ~= nil then
			return true, Descriptor
		end
		return false, nil
	end)
end

function ApiCatalog.HasEvent(ClassName, EventName)
	return ApiCatalog.GetEventDescriptor(ClassName, EventName) ~= nil
end

function ApiCatalog.EnumExists(EnumName)
	return ApiCatalog.GetEnumDescriptor(EnumName) ~= nil
end

function ApiCatalog.GetFirstEnumItem(EnumName)
	local Descriptor = ApiCatalog.GetEnumDescriptor(EnumName)
	if typeof(Descriptor) ~= "table" then
		return nil
	end
	local Order = Descriptor.Order
	if typeof(Order) == "table" and #Order > 0 then
		return Order[1]
	end
	local Names = {}
	for Name in next, Descriptor.Items do
		Names[#Names + 1] = Name
	end
	table.sort(Names)
	return Names[1]
end

function ApiCatalog.GetEnumValue(EnumName, ItemName)
	local Descriptor = ApiCatalog.GetEnumDescriptor(EnumName)
	if typeof(Descriptor) ~= "table" then
		return nil
	end
	return Descriptor.Items[ItemName]
end

function ApiCatalog.IsServiceClass(ClassName)
	return ApiCatalog.HasServiceClass(ClassName)
end

function ApiCatalog.IsClassCreatable(ClassName)
	if typeof(ClassName) ~= "string" or ClassName == "" then
		return false
	end

	if not ApiCatalog.HasClass(ClassName) then
		local Stats = ApiCatalog.GetStats()
		if Stats.Loaded then
			return false
		end
		return true
	end

	if ApiCatalog.ClassHasModifier(ClassName, "NotCreatable") then
		return false
	end

	if ApiCatalog.IsServiceClass(ClassName) then
		return false
	end

	return true
end

function ApiCatalog.IsPropertyReadOnly(ClassName, PropertyName)
	if ApiCatalog.PropertyHasModifier(ClassName, PropertyName, "ReadOnly") then
		return true
	end

	if ApiCatalog.PropertyHasModifier(ClassName, PropertyName, "ReadSafe") then
		return true
	end

	return false
end

function ApiCatalog.GetServiceLikeClasses()
	local Names = {}
	local Map = Manifest.Classes or {}
	for ClassName in next, Map do
		if ApiCatalog.IsServiceClass(ClassName) then
			Names[#Names + 1] = ClassName
		end
	end
	table.sort(Names)
	return Names
end

for _, ShardName in ipairs(Manifest.Shards or {}) do
	loadShard(ShardName)
end

return ApiCatalog