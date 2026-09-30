local HTTP = require("../../IO/HTTP")
local Config = require("../../Config")
local Enums = require("../Enums")
local ApiDumpIndex = require("../ApiCatalog")
local TypeDefaults = require("../TypeDefaults")
local RuntimeClock = require("../RuntimeClock")
local BufferAndCrypto = require("../../Libs/BufferAndCrypto")

local Methods = {}

local MethodRegistry = {}
local DynamicMethodCache = {}
local ServerClockStart = os.clock()
local ServerTimeStart = os.time() + (ServerClockStart % 1)
local LastServerTime = ServerTimeStart

local function ClassNameOf(Inst)
	if typeof(Inst) ~= "table" then
		return nil
	end

	local RawClass = rawget(Inst, "_ClassName")
	if typeof(RawClass) == "string" and RawClass ~= "" then
		return RawClass
	end

	local Getter = rawget(Inst, "GetClassName")
	if typeof(Getter) ~= "function" then
		return nil
	end

	local Ok, ClassName = pcall(Getter, Inst)
	if Ok and typeof(ClassName) == "string" then
		return ClassName
	end

	return nil
end

local function NextServerTimeNow()
	local Elapsed = os.clock() - ServerClockStart
	if Elapsed < 0 then
		Elapsed = 0
	end

	local Now = ServerTimeStart + Elapsed
	if Now <= LastServerTime then
		Now = LastServerTime + 0.000001
	end

	LastServerTime = Now
	return Now
end

local function EmitTupleReturn(ReturnType, Context)
	local Packed = TypeDefaults.ForTuple(ReturnType, Context)
	if not Packed then
		return nil
	end
	return table.unpack(Packed, 1, Packed.n)
end

local function AutoMethodFallback(Inst, ClassName, MethodName, Descriptor, ...)
	local ArgCount = select("#", ...)

	if string.sub(MethodName, 1, 3) == "Set" and ArgCount >= 1 then
		local PropName = string.sub(MethodName, 4)
		if PropName ~= "" and typeof(Inst.SetProperty) == "function" then
			local Value = select(1, ...)
			pcall(function()
				Inst:SetProperty(PropName, Value)
			end)
		end
		return nil
	end

	if string.sub(MethodName, 1, 3) == "Get" and ArgCount == 0 and typeof(Inst.GetProperty) == "function" then
		local PropName = string.sub(MethodName, 4)
		if PropName ~= "" then
			local Existing = Inst:GetProperty(PropName)
			if Existing ~= nil then
				return Existing
			end

			local PropertyDescriptor = ApiDumpIndex.GetPropertyDescriptor(ClassName, PropName)
			if PropertyDescriptor then
				local Generated = TypeDefaults.ForType(PropertyDescriptor.Type, {
					Instance = Inst,
					ClassName = ClassName,
					MethodName = MethodName,
					PropertyName = PropName,
					SignalName = PropName,
				})
				if Generated ~= nil then
					Inst:SetProperty(PropName, Generated)
					return Generated
				end
			end
		end
	end

	local ReturnType = Descriptor and Descriptor.ReturnType or ""

	local TupleResult = EmitTupleReturn(ReturnType, {
		Instance = Inst,
		ClassName = ClassName,
		MethodName = MethodName,
		SignalName = MethodName,
	})
	if TupleResult ~= nil then
		return TupleResult
	end

	local DefaultValue = TypeDefaults.ForType(ReturnType, {
		Instance = Inst,
		ClassName = ClassName,
		MethodName = MethodName,
		SignalName = MethodName,
	})
	if DefaultValue ~= nil then
		return DefaultValue
	end

	local LowerName = string.lower(MethodName)
	if string.sub(MethodName, 1, 2) == "Is" then
		return false
	end

	if string.sub(MethodName, 1, 3) == "Has" then
		return false
	end

	if string.find(LowerName, "enabled", 1, true) then
		return false
	end

	return nil
end

local function UnwrapValue(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

local function DescribeValueType(Value)
	local Unwrapped = UnwrapValue(Value)
	if typeof(Unwrapped) == "table" then
		local DataType = rawget(Unwrapped, "__larryType")
		if typeof(DataType) == "string" and DataType ~= "" then
			return DataType
		end
	end
	return typeof(Unwrapped)
end

local function ResolveMethodCandidates(Inst, MethodName)
	local ClassName = ClassNameOf(Inst)
	if ClassName == nil or typeof(MethodName) ~= "string" then
		return nil, ClassName
	end

	local Candidates = ApiDumpIndex.GetFunctionOverloads(ClassName, MethodName)
	if Candidates == nil then
		Candidates = ApiDumpIndex.GetAnyFunctionOverloads(MethodName)
	end

	if Candidates == nil then
		local Descriptor = ApiDumpIndex.GetFunctionDescriptor(ClassName, MethodName)
		if Descriptor == nil then
			Descriptor = ApiDumpIndex.GetAnyFunctionDescriptor(MethodName)
		end
		if Descriptor ~= nil then
			Candidates = { Descriptor }
		end
	end

	return Candidates, ClassName
end

local function ResolveMethodDescriptor(Inst, MethodName)
	local Candidates, ClassName = ResolveMethodCandidates(Inst, MethodName)
	if typeof(Candidates) == "table" and #Candidates > 0 then
		return Candidates[1], ClassName
	end
	return nil, ClassName
end

local function IsBroadExpectedType(TypeName)
	if typeof(TypeName) ~= "string" then
		return true
	end

	local Lower = string.lower(TypeName)
	if Lower == "" or Lower == "any" or Lower == "variant" or Lower == "unknown" then
		return true
	end

	if Lower == "..." or string.find(Lower, "tuple", 1, true) then
		return true
	end

	return false
end

local function ValidateOneMethodArgument(ClassName, MethodName, ArgIndex, ArgDescriptor, ArgValue)
	if typeof(ArgDescriptor) ~= "table" then
		return
	end

	if typeof(ArgValue) == "table" then
		local Raw = rawget(ArgValue, "V")
		local Path = rawget(ArgValue, "P")

		if Raw == nil and typeof(Path) == "string" and Path ~= "" then
			return
		end
	end

	local ExpectedType = ArgDescriptor.Type or "any"
	if IsBroadExpectedType(ExpectedType) then
		return
	end

	if ArgValue == nil and ArgDescriptor.Optional == true then
		return
	end

	if not TypeDefaults.MatchesType(ExpectedType, ArgValue) then
		local GotType = DescribeValueType(ArgValue)
		error(`{ClassName}:{MethodName}() argument #{ArgIndex} expected {ExpectedType}, got {GotType}`, 0)
	end
end

local function ValidateDescriptorArguments(ClassName, MethodName, Descriptor, ...)
	local ParsedArguments = Descriptor.ParsedArguments
	if typeof(ParsedArguments) ~= "table" or #ParsedArguments == 0 then
		return
	end

	local ArgCount = select("#", ...)
	local RequiredCount = tonumber(Descriptor.RequiredArgumentCount) or 0
	if ArgCount < RequiredCount then
		error(`{ClassName}:{MethodName}() missing argument #{ArgCount + 1}`, 0)
	end

	local VariadicIndex = nil
	for I, ArgDescriptor in ipairs(ParsedArguments) do
		if ArgDescriptor.Variadic == true then
			VariadicIndex = I
			break
		end
	end

	local FixedLimit = #ParsedArguments
	if VariadicIndex ~= nil then
		FixedLimit = VariadicIndex - 1
	elseif ArgCount > FixedLimit then
		error(`{ClassName}:{MethodName}() expected at most {FixedLimit} argument(s), got {ArgCount}`, 0)
	end

	for I = 1, math.min(ArgCount, FixedLimit) do
		ValidateOneMethodArgument(ClassName, MethodName, I, ParsedArguments[I], select(I, ...))
	end

	if VariadicIndex ~= nil and ArgCount >= VariadicIndex then
		local VariadicDescriptor = ParsedArguments[VariadicIndex]
		for I = VariadicIndex, ArgCount do
			ValidateOneMethodArgument(ClassName, MethodName, I, VariadicDescriptor, select(I, ...))
		end
	else
		for I = FixedLimit + 1, math.min(ArgCount, #ParsedArguments) do
			ValidateOneMethodArgument(ClassName, MethodName, I, ParsedArguments[I], select(I, ...))
		end
	end
end

local function ValidateMethodArguments(Inst, MethodName, ...)
	local Candidates, ClassName = ResolveMethodCandidates(Inst, MethodName)
	if typeof(Candidates) ~= "table" or #Candidates == 0 then
		return
	end

	ClassName = ClassName or "Instance"

	local LastError = nil
	for _, Descriptor in ipairs(Candidates) do
		local Ok, Err = pcall(function(...)
			ValidateDescriptorArguments(ClassName, MethodName, Descriptor, ...)
		end, ...)

		if Ok then
			return
		end

		LastError = Err
	end

	if LastError ~= nil then
		error(LastError, 0)
	end
end

function Methods.Register(ClassName, MethodName, Handler)
	local Key = `{ClassName}.{MethodName}`
	MethodRegistry[Key] = Handler
	DynamicMethodCache[Key] = nil
end

function Methods.RegisterGlobal(MethodName, Handler)
	MethodRegistry[`*.{MethodName}`] = Handler
end

function Methods.GetSpecific(Inst, MethodName)
	local ClassName = ClassNameOf(Inst)
	if not ClassName then
		return nil
	end

	return MethodRegistry[`{ClassName}.{MethodName}`]
end

function Methods.GetGlobal(MethodName)
	return MethodRegistry[`*.{MethodName}`]
end

function Methods.GetDumpFallback(Inst, MethodName)
	local ClassName = ClassNameOf(Inst)
	if ClassName == nil or typeof(MethodName) ~= "string" then
		return nil
	end

	local CacheKey = `{ClassName}.{MethodName}`
	local Cached = DynamicMethodCache[CacheKey]
	if Cached ~= nil then
		return Cached == false and nil or Cached
	end

	local Descriptor = ResolveMethodDescriptor(Inst, MethodName)
	if Descriptor == nil then
		DynamicMethodCache[CacheKey] = false
		return nil
	end

	local Handler = function(TargetInst, ...)
		return AutoMethodFallback(TargetInst, ClassName, MethodName, Descriptor, ...)
	end

	DynamicMethodCache[CacheKey] = Handler
	return Handler
end

function Methods.Get(Inst, MethodName)
	local Specific = Methods.GetSpecific(Inst, MethodName)
	if Specific then return Specific end

	local Global = Methods.GetGlobal(MethodName)
	if Global then return Global end

	local DumpFallback = Methods.GetDumpFallback(Inst, MethodName)
	if DumpFallback then
		return DumpFallback
	end

	return nil
end

function Methods.Call(Inst, MethodName, ...)
	local Handler = Methods.Get(Inst, MethodName)
	if Handler then
		ValidateMethodArguments(Inst, MethodName, ...)
		return Handler(Inst, ...)
	end
	return nil
end

function Methods.Validate(Inst, MethodName, ...)
	ValidateMethodArguments(Inst, MethodName, ...)
end

function Methods.Has(Inst, MethodName)
	return Methods.Get(Inst, MethodName) ~= nil
end

Methods.RegisterGlobal("IsA", function(Inst, ClassName)
	return Inst:IsA(ClassName)
end)

Methods.RegisterGlobal("FindFirstChild", function(Inst, Name, Recursive)
	return Inst:FindFirstChild(Name, Recursive)
end)

Methods.RegisterGlobal("FindFirstChildOfClass", function(Inst, ClassName)
	return Inst:FindFirstChildOfClass(ClassName)
end)

Methods.RegisterGlobal("FindFirstChildWhichIsA", function(Inst, ClassName)
	return Inst:FindFirstChildWhichIsA(ClassName)
end)

Methods.RegisterGlobal("FindFirstAncestorOfClass", function(Inst, ClassName)
	return Inst:FindFirstAncestorOfClass(ClassName)
end)

Methods.RegisterGlobal("GetChildren", function(Inst)
	return Inst:GetChildren()
end)

Methods.RegisterGlobal("GetDescendants", function(Inst)
	return Inst:GetDescendants()
end)

Methods.RegisterGlobal("Clone", function(Inst)
	return Inst:Clone()
end)

Methods.RegisterGlobal("Destroy", function(Inst)
	Inst:Destroy()
end)

Methods.RegisterGlobal("SetAttribute", function(Inst, Name, Value)
	Inst:SetAttribute(Name, Value)
end)

Methods.RegisterGlobal("GetAttribute", function(Inst, Name)
	return Inst:GetAttribute(Name)
end)

Methods.RegisterGlobal("WaitForChild", function(Inst, Name, Timeout)
	return Inst:WaitForChild(Name, Timeout)
end)

Methods.RegisterGlobal("ClearAllChildren", function(Inst)
	local Children = Inst:GetChildren()
	for I = #Children, 1, -1 do
		Children[I]:Destroy()
	end
end)

Methods.RegisterGlobal("GetFullName", function(Inst)
	local Parts = {}
	local Current = Inst

	while Current do
		table.insert(Parts, 1, Current:GetName())
		local Parent = Current:GetParent()
		if typeof(Parent) ~= "table" or not Parent.GetName then break end
		if Parent.GetClassName and Parent:GetClassName() == "DataModel" then
			break
		end
		Current = Parent
	end

	return table.concat(Parts, ".")
end)

Methods.RegisterGlobal("GetPropertyChangedSignal", function(Inst, PropName)
	if typeof(PropName) ~= "string" then
		error("invalid argument #1 to 'GetPropertyChangedSignal' (string expected)", 2)
	end

	local ApiDumpIndex = require("../ApiCatalog")
	local ClassName = typeof(Inst) == "table" and Inst.ClassName or nil
	local IsValidProperty = typeof(ClassName) == "string" and ApiDumpIndex.HasProperty(ClassName, PropName)
	if not IsValidProperty then
		error(`{PropName} is not a valid member of {tostring(ClassName or "Instance")}`, 2)
	end

	local Signals = require("../Signals")
	return Signals.ForInstance(Inst, PropName .. "_Changed")
end)

Methods.RegisterGlobal("JSONDecode", function(Inst, Str)
	return HTTP.JSONDecode(Str)
end)

Methods.RegisterGlobal("JSONEncode", function(Inst, Data)
	return HTTP.JSONEncode(Data)
end)

Methods.Register("EncodingService", "Base64Encode", function(Inst, Input)
	return BufferAndCrypto.Base64EncodeBuffer(Input)
end)

Methods.Register("EncodingService", "Base64Decode", function(Inst, Input)
	return BufferAndCrypto.Base64DecodeBuffer(Input)
end)

local function ResolveCompressionAlg(MethodName, Alg)
	local Name = BufferAndCrypto.ResolveCompressionAlgorithm(Alg)
	if Name == nil then
		error(`EncodingService:{MethodName}() invalid CompressionAlgorithm`, 0)
	end
	return Name
end

local function ResolveHashAlg(MethodName, Alg)
	local Name = BufferAndCrypto.ResolveHashAlgorithm(Alg)
	if Name == nil then
		error(`EncodingService:{MethodName}() invalid HashAlgorithm`, 0)
	end
	return Name
end

Methods.Register("EncodingService", "CompressBuffer", function(_Inst, Input, Algorithm, CompressionLevel)
	local AlgName = ResolveCompressionAlg("CompressBuffer", Algorithm)
	local Level = CompressionLevel
	if Level == nil then
		Level = 1
	end
	if typeof(Level) ~= "number" then
		error("EncodingService:CompressBuffer() compressionLevel must be a number", 0)
	end
	if Level % 1 ~= 0 then
		error("EncodingService:CompressBuffer() compressionLevel must be an integer", 0)
	end
	if AlgName == "Zstd" and (Level < -7 or Level > 22) then
		error("EncodingService:CompressBuffer() compressionLevel out of range", 0)
	end
	local Data = BufferAndCrypto.RequireBufferToString(Input, "CompressBuffer", 1)
	local Encoded = BufferAndCrypto.CompressZstdString(Data, Level)
	return BufferAndCrypto.StringToBuffer(Encoded, "CompressBuffer")
end)

Methods.Register("EncodingService", "DecompressBuffer", function(_Inst, Input, Algorithm)
	ResolveCompressionAlg("DecompressBuffer", Algorithm)
	local Data = BufferAndCrypto.RequireBufferToString(Input, "DecompressBuffer", 1)
	local Ok, Decoded = pcall(BufferAndCrypto.DecompressZstdString, Data)
	if not Ok then
		if Config and Config.Settings and Config.Settings.spy_exec_only then
			return Input
		end
		error(Decoded, 0)
	end
	return BufferAndCrypto.StringToBuffer(Decoded, "DecompressBuffer")
end)

Methods.Register("EncodingService", "GetDecompressedBufferSize", function(_Inst, Input, Algorithm)
	ResolveCompressionAlg("GetDecompressedBufferSize", Algorithm)
	local Data = BufferAndCrypto.RequireBufferToString(Input, "GetDecompressedBufferSize", 1)
	return BufferAndCrypto.GetZstdDecompressedSizeString(Data)
end)

Methods.Register("EncodingService", "ComputeBufferHash", function(_Inst, Input, Algorithm)
	local AlgName = ResolveHashAlg("ComputeBufferHash", Algorithm)
	local Data = BufferAndCrypto.RequireBufferToString(Input, "ComputeBufferHash", 1)
	local Digest = BufferAndCrypto.ComputeHashString(Data, AlgName)
	return BufferAndCrypto.StringToBuffer(Digest, "ComputeBufferHash")
end)

Methods.Register("EncodingService", "ComputeStringHash", function(_Inst, Input, Algorithm)
	if typeof(Input) ~= "string" then
		error("EncodingService:ComputeStringHash() input must be a string", 0)
	end
	local AlgName = ResolveHashAlg("ComputeStringHash", Algorithm)
	return BufferAndCrypto.ComputeHashString(Input, AlgName)
end)

Methods.Register("CollectionService", "GetTagged", function(Inst, TagName)
	local Hierarchy = require("../Hierarchy")
	local Out = {}

	for _, Obj in Hierarchy.GetAllInstances() do
		if Obj:HasTag(TagName) then
			Out[#Out + 1] = Obj
		end
	end

	return Out
end)

Methods.Register("DataModel", "Load", function(Inst)
	return nil
end)

Methods.Register("DataModel", "IsLoaded", function(Inst)
	return true
end)

Methods.Register("RunService", "IsStudio", function(Inst)
	return false
end)

Methods.Register("RunService", "IsClient", function(Inst)
	return true
end)

Methods.Register("RunService", "IsServer", function(Inst)
	return false
end)

Methods.Register("RunService", "IsRunning", function(Inst)
	local Running = Inst:GetProperty("IsRunning")
	if typeof(Running) == "boolean" then
		return Running
	end
	return true
end)

Methods.Register("RunService", "GetRobloxVersion", function(Inst)
	local Version = require("../Version")
	return Version.Get().version
end)

Methods.Register("RunService", "GetCoreScriptVersion", function(Inst)
	return string.rep("0", 40)
end)

Methods.Register("RunService", "GetRealPhysicsFPS", function(Inst)
	local Services = require("../Services")
	local Workspace = Services.GetOrNil("Workspace")
	if Workspace and Workspace.GetProperty then
		local Fps = Workspace:GetProperty("RealPhysicsFPS")
		if typeof(Fps) == "number" then
			return Fps
		end
	end
	return 60
end)

Methods.Register("Workspace", "GetNumAwakeParts", function(Inst)
	local Count = Inst:GetProperty("NumAwakeParts")
	if typeof(Count) == "number" then
		return math.max(0, math.floor(Count))
	end
	return 8
end)

Methods.Register("Workspace", "GetRealPhysicsFPS", function(Inst)
	local Fps = Inst:GetProperty("RealPhysicsFPS")
	if typeof(Fps) == "number" then
		return Fps
	end
	return 60
end)

Methods.Register("Workspace", "GetServerTimeNow", function(Inst)
	local Bias = Inst:GetProperty("ServerTimeBias")
	if typeof(Bias) ~= "number" then
		Bias = 0
	end
	return NextServerTimeNow() + Bias
end)

Methods.Register("UserInputService", "GetPlatform", function(Inst)
	local Platform = Inst:GetProperty("Platform")
	if Platform ~= nil then
		return Platform
	end

	return Enums.Get("Platform", "Windows")
end)

Methods.Register("UserInputService", "GetMouseLocation", function(Inst)
	local DataTypes = require("../DataTypes")
	return DataTypes.Get("Vector2").new(960, 540)
end)

Methods.Register("Workspace", "Raycast", function(Inst, Origin, Direction, RaycastParams)
	local DataTypes = require("../DataTypes")
	local RaycastResult = {
		Position = DataTypes.Get("Vector3").new(Origin.X, Origin.Y, Origin.Z),
		Normal = DataTypes.Get("Vector3").new(0, 1, 0),
		Material = Enums.Get("Material", "Plastic"),
		Instance = Inst,
	}
	return RaycastResult
end)

Methods.Register("Camera", "WorldToScreenPoint", function(Inst, WorldPoint)
	local DataTypes = require("../DataTypes")
	local X = 960 + (WorldPoint.X or 0)
	local Y = 540 - (WorldPoint.Y or 0)
	return DataTypes.Get("Vector3").new(X, Y, 1)
end)

Methods.Register("Camera", "WorldToViewportPoint", function(Inst, WorldPoint)
	local DataTypes = require("../DataTypes")
	local X = 960 + (WorldPoint.X or 0)
	local Y = 540 - (WorldPoint.Y or 0)
	return DataTypes.Get("Vector3").new(X, Y, 1)
end)

Methods.Register("Camera", "ScreenPointToRay", function(Inst, X, Y)
	local DataTypes = require("../DataTypes")
	return DataTypes.Get("Ray").new(
		DataTypes.Get("Vector3").new(0, 5, 0),
		DataTypes.Get("Vector3").new(0, -1, 0)
	)
end)

Methods.Register("Camera", "ViewportPointToRay", function(Inst, X, Y)
	local DataTypes = require("../DataTypes")
	return DataTypes.Get("Ray").new(
		DataTypes.Get("Vector3").new(0, 5, 0),
		DataTypes.Get("Vector3").new(0, -1, 0)
	)
end)

Methods.Register("Player", "GetMouse", function(Inst)
	local Mouse = {}
	Mouse.X = 960
	Mouse.Y = 540
	return setmetatable(Mouse, {
		__tostring = function() return "Mouse" end,
	})
end)

Methods.Register("Players", "GetPlayerFromCharacter", function(Inst, Character)
	if typeof(Character) == "table" and Character:IsA("Model") then
		for _, Child in Inst:GetChildren() do
			if typeof(Child) == "table" and Child:IsA("Player") and Child.Character == Character then
				return Child
			end
		end
	end
	return nil
end)

Methods.Register("Model", "GetExtentsSize", function(Inst)
	local DataTypes = require("../DataTypes")
	return DataTypes.Get("Vector3").new(4, 4, 4)
end)

Methods.Register("Part", "GetMass", function(Inst)
	return 1
end)

Methods.Register("TweenService", "Create", function(Inst, Object, TweenInfo, PropertyTable)
	if typeof(Object) ~= "table" then
		error("TweenService:Create() invalid goal type", 0)
	end
	if typeof(PropertyTable) ~= "table" then
		error("TweenService:Create() goals must be a dictionary", 0)
	end
	local Signals = require("../Signals")
	local FakeTween = {
		Play = function() end,
		Pause = function() end,
		Cancel = function() end,
	}
	return FakeTween
end)

Methods.Register("TweenService", "GetValue", function(Inst, Alpha, EasingStyle, EasingDirection)
	return Alpha
end)

Methods.Register("Players", "GetNetworkPing", function(Inst, Player)
	return 0.036
end)

Methods.Register("Players", "GetNameFromUserIdAsync", function(Inst, UserId)
	local NumericId = tonumber(UserId)
	if NumericId == nil then
		error("Players:GetNameFromUserIdAsync() userId must be a number", 0)
	end

	NumericId = math.max(1, math.floor(math.abs(NumericId)))

	for _, Child in Inst:GetChildren() do
		if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") then
			local ChildUserId = tonumber(Child.UserId)
			if ChildUserId and math.floor(ChildUserId) == NumericId then
				return tostring(Child.Name)
			end
		end
	end

	return `Player{NumericId}`
end)

Methods.Register("Players", "GetUserIdFromNameAsync", function(Inst, Name)
	if typeof(Name) ~= "string" or Name == "" then
		error("Players:GetUserIdFromNameAsync() name must be a non-empty string", 0)
	end

	for _, Child in Inst:GetChildren() do
		if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") and Child.Name == Name then
			local ChildUserId = tonumber(Child.UserId)
			if ChildUserId then
				return math.floor(ChildUserId)
			end
		end
	end

	return 1
end)

Methods.Register("Teams", "GetTeams", function(Inst)
	return Inst:GetChildren()
end)

Methods.Register("LogService", "GetLogHistory", function(Inst)
	local History = Inst:GetProperty("_History")
	if typeof(History) == "table" then
		return History
	end

	return {
		{
			message = "Log initialized",
			timestamp = RuntimeClock.Now(),
			messageType = "Output",
		},
	}
end)

Methods.Register("Stats", "GetTotalMemoryUsageMb", function(Inst)
	local Value = Inst:GetProperty("TotalMemoryUsageMb")
	if typeof(Value) ~= "number" then
		Value = 512
	end
	if Value < 16 then
		Value = 16
	end
	return Value
end)

Methods.Register("StatsService", "GetTotalMemoryUsageMb", function(Inst)
	local Value = Inst:GetProperty("TotalMemoryUsageMb")
	if typeof(Value) ~= "number" then
		Value = 512
	end
	if Value < 16 then
		Value = 16
	end
	return Value
end)

Methods.Register("BindableEvent", "Fire", function(Inst, ...)
	local Event = Inst.Event
	if typeof(Event) == "table" and typeof(Event.Fire) == "function" then
		Event:Fire(...)
	end
end)

Methods.Register("CollectionService", "HasTag", function(Inst, Obj, TagName)
	if typeof(Obj) ~= "table" or not Obj.HasTag then
		return false
	end
	return Obj:HasTag(TagName)
end)

Methods.Register("CollectionService", "AddTag", function(Inst, Obj, TagName)
	if typeof(Obj) ~= "table" or not Obj.AddTag then
		return
	end

	local HadTag = typeof(Obj.HasTag) == "function" and Obj:HasTag(TagName) or false
	Obj:AddTag(TagName)

	if not HadTag then
		local Signal = Inst:GetInstanceAddedSignal(TagName)
		if typeof(Signal) == "table" and typeof(Signal.Fire) == "function" then
			Signal:Fire(Obj)
		end
	end
end)

Methods.Register("CollectionService", "RemoveTag", function(Inst, Obj, TagName)
	if typeof(Obj) ~= "table" or not Obj.RemoveTag then
		return
	end

	local HadTag = typeof(Obj.HasTag) == "function" and Obj:HasTag(TagName) or false
	Obj:RemoveTag(TagName)

	if HadTag then
		local Signal = Inst:GetInstanceRemovedSignal(TagName)
		if typeof(Signal) == "table" and typeof(Signal.Fire) == "function" then
			Signal:Fire(Obj)
		end
	end
end)

Methods.Register("CollectionService", "GetTags", function(Inst, Obj)
	if typeof(Obj) ~= "table" or not Obj.GetTags then
		return {}
	end
	return Obj:GetTags()
end)

Methods.Register("CollectionService", "GetAllTags", function(Inst)
	local Hierarchy = require("../Hierarchy")
	local Seen = {}
	local Out = {}

	for _, Obj in Hierarchy.GetAllInstances() do
		if typeof(Obj) == "table" and Obj.GetTags then
			for _, Tag in Obj:GetTags() do
				Seen[Tag] = true
			end
		end
	end

	for Tag in next, Seen do
		Out[#Out + 1] = Tag
	end

	table.sort(Out)
	return Out
end)

Methods.Register("CollectionService", "GetInstanceAddedSignal", function(Inst, TagName)
	local Signals = require("../Signals")
	local Key = `CollectionService_{tostring(TagName)}_Added`
	local Existing = Inst:GetProperty(Key)
	if Existing ~= nil then
		return Existing
	end
	local Signal = Signals.ForInstance(Inst, Key)
	Inst:SetProperty(Key, Signal)
	return Signal
end)

Methods.Register("CollectionService", "GetInstanceRemovedSignal", function(Inst, TagName)
	local Signals = require("../Signals")
	local Key = `CollectionService_{tostring(TagName)}_Removed`
	local Existing = Inst:GetProperty(Key)
	if Existing ~= nil then
		return Existing
	end
	local Signal = Signals.ForInstance(Inst, Key)
	Inst:SetProperty(Key, Signal)
	return Signal
end)

Methods.Register("Debris", "AddItem", function(Inst, Obj, Lifetime)
	if typeof(Obj) ~= "table" or typeof(Obj.Destroy) ~= "function" then
		return
	end

	local DelayTime = tonumber(Lifetime)
	if DelayTime == nil then
		DelayTime = 10
	end
	DelayTime = math.max(0, DelayTime)

	local Queue = Inst:GetProperty("_DebrisQueue")
	if typeof(Queue) ~= "table" then
		Queue = {}
		Inst:SetProperty("_DebrisQueue", Queue)
	end

	Queue[#Queue + 1] = {
		Object = Obj,
		DestroyAt = os.clock() + DelayTime,
	}

	if DelayTime == 0 then
		Obj:Destroy()
		return
	end

	local LuneTask = nil
	pcall(function()
		LuneTask = require("@lune/task")
	end)
	if LuneTask and typeof(LuneTask.delay) == "function" then
		pcall(LuneTask.delay, math.min(DelayTime, 5), function()
			if typeof(Obj) == "table" and not Obj._Destroyed and typeof(Obj.Destroy) == "function" then
				Obj:Destroy()
			end
		end)
	end
end)

Methods.Register("Debris", "SetLegacyMaxItems", function(Inst, Enabled)
	Inst:SetProperty("LegacyMaxItems", Enabled == true)
end)

Methods.Register("MarketplaceService", "GetProductInfo", function(Inst, AssetId, InfoType)
	local Id = tonumber(AssetId) or 0
	local CreatorId = 1

	return {
		AssetId = Id,
		ProductId = Id,
		Name = `Asset {Id}`,
		Description = "",
		AssetTypeId = 10,
		Creator = {
			Id = CreatorId,
			Name = "Roblox",
			CreatorType = "User",
			CreatorTargetId = CreatorId,
		},
		IconImageAssetId = 0,
		Created = "2024-01-01T00:00:00Z",
		Updated = "2024-01-01T00:00:00Z",
		PriceInRobux = 0,
		IsForSale = false,
		IsLimited = false,
		IsLimitedUnique = false,
		MinimumMembershipLevel = 0,
		ContentRatingTypeId = 0,
	}
end)

Methods.Register("MarketplaceService", "UserOwnsGamePassAsync", function(Inst, UserId, GamePassId)
	return false
end)

Methods.Register("MarketplaceService", "PlayerOwnsAsset", function(Inst, Player, AssetId)
	return false
end)

return Methods