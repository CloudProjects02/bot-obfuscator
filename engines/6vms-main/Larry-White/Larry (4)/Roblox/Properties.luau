local IdentityUtil = require("../Utils/Identity")
local ApiDumpIndex = require("./ApiCatalog")
local TypeDefaults = require("./TypeDefaults")
local DataTypes = require("./DataTypes")
local Enums = require("./Enums")
local View = require("../Tools/View")

local Properties = {}

local DynamicGenerators = {}
local DeprecatedAliases = {}
local PropertyDefaults = {}
local PropertyValidators = {}
local NilPropertyDefaults = {}

local function UnwrapValue(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

local function MakeVector3(X, Y, Z)
	local Ok, Value = pcall(function()
		local Vector3Lib = DataTypes.Get("Vector3")
		if typeof(Vector3Lib) == "table" and typeof(Vector3Lib.new) == "function" then
			return Vector3Lib.new(X, Y, Z)
		end
		return nil
	end)

	if Ok and Value ~= nil then
		return Value
	end

	return {
		X = X,
		Y = Y,
		Z = Z,
	}
end

local function MakeVector2(X, Y)
	local Ok, Value = pcall(function()
		local Vector2Lib = DataTypes.Get("Vector2")
		if typeof(Vector2Lib) == "table" and typeof(Vector2Lib.new) == "function" then
			return Vector2Lib.new(X, Y)
		end
		return nil
	end)

	if Ok and Value ~= nil then
		return Value
	end

	return {
		X = X,
		Y = Y,
	}
end

local function MakeColor3(R, G, B)
	local Ok, Value = pcall(function()
		local Color3Lib = DataTypes.Get("Color3")
		if typeof(Color3Lib) == "table" and typeof(Color3Lib.new) == "function" then
			return Color3Lib.new(R, G, B)
		end
		if typeof(Color3Lib) == "table" and typeof(Color3Lib.fromRGB) == "function" then
			return Color3Lib.fromRGB(
				math.floor(R * 255 + 0.5),
				math.floor(G * 255 + 0.5),
				math.floor(B * 255 + 0.5)
			)
		end
		return nil
	end)

	if Ok and Value ~= nil then
		return Value
	end

	return {
		R = R,
		G = G,
		B = B,
		__larryType = "Color3",
	}
end

local function MakeBrickColor(Name)
	local Ok, Value = pcall(function()
		local BrickColorLib = DataTypes.Get("BrickColor")
		if typeof(BrickColorLib) == "table" and typeof(BrickColorLib.new) == "function" then
			return BrickColorLib.new(Name)
		end
		return nil
	end)

	if Ok and Value ~= nil then
		return Value
	end

	return {
		Name = Name,
		Number = 194,
		__larryType = "BrickColor",
	}
end

local function IsVector3Like(Value)
	local Unwrapped = UnwrapValue(Value)
	local ValueType = typeof(Unwrapped)

	if ValueType == "Vector3" then
		return true
	end

	if ValueType == "table" then
		local X = rawget(Unwrapped, "X")
		local Y = rawget(Unwrapped, "Y")
		local Z = rawget(Unwrapped, "Z")
		return type(X) == "number" and type(Y) == "number" and type(Z) == "number"
	end

	return false
end

local function IsBoolean(Value)
	return typeof(UnwrapValue(Value)) == "boolean"
end

local function IsNumber(Value)
	local Num = UnwrapValue(Value)
	return typeof(Num) == "number" and Num == Num and Num ~= math.huge and Num ~= -math.huge
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

local function ReadExplicitProperty(Inst, PropName)
	if typeof(Inst) ~= "table" then
		return nil
	end

	if typeof(Inst.GetRawProperty) == "function" then
		local Ok, Value = pcall(Inst.GetRawProperty, Inst, PropName)
		if Ok then
			return Value
		end
	end

	local Props = rawget(Inst, "_Properties")
	if typeof(Props) == "table" then
		return Props[PropName]
	end

	return nil
end

local function CoerceMissingEnumValue(DescriptorType, Value)
	if Value ~= nil or typeof(DescriptorType) ~= "string" then
		return Value, false
	end

	local EnumName = string.match(DescriptorType, "^Enum%.([%w_]+)$")
	if EnumName == nil then
		return Value, false
	end

	local Fallback = Enums.Get(EnumName, "Unknown")
	if Fallback == nil then
		local First = ApiDumpIndex.GetFirstEnumItem(EnumName)
		if typeof(First) == "string" then
			Fallback = Enums.Get(EnumName, First)
		end
	end

	if Fallback ~= nil then
		return Fallback, true
	end

	return Value, false
end

local function TryFinalizeTweenPlayback(Inst)
	if typeof(Inst) ~= "table" then
		return
	end

	local PendingSerial = ReadExplicitProperty(Inst, "_LarryTweenCompleteAtWaitSerial")
	if typeof(PendingSerial) ~= "number" then
		return
	end

	local RuntimeState = rawget(Inst, "_State")
	local CurrentSerial = 0
	if typeof(RuntimeState) == "table" then
		CurrentSerial = tonumber(rawget(RuntimeState, "_LarryWaitSerial")) or 0
	end
	if CurrentSerial < PendingSerial then
		return
	end

	local Target = ReadExplicitProperty(Inst, "Instance")
	local TweenProperties = ReadExplicitProperty(Inst, "_TweenProperties")
	if typeof(Target) == "table" and typeof(TweenProperties) == "table" then
		for Key, Value in next, TweenProperties do
			pcall(function()
				if typeof(Target.SetProperty) == "function" then
					Target:SetProperty(Key, Value)
				else
					Target[Key] = Value
				end
			end)
		end
	end

	local CompletedState = Enums.Get("PlaybackState", "Completed") or "Completed"
	Inst:SetProperty("PlaybackState", CompletedState)
	Inst:SetProperty("_LarryTweenCompleteAtWaitSerial", nil)

	local Signals = require("./Signals")
	local CompletedSignal = Signals.ForInstance(Inst, "Completed")
	if typeof(CompletedSignal) == "table" and typeof(CompletedSignal.Fire) == "function" then
		pcall(CompletedSignal.Fire, CompletedSignal, CompletedState)
	end
end

local function ReadVector3Components(Value)
	local Target = UnwrapValue(Value)
	if typeof(Target) == "Vector3" then
		return Target.X, Target.Y, Target.Z
	end
	if typeof(Target) == "table" then
		local X = tonumber(rawget(Target, "X"))
		local Y = tonumber(rawget(Target, "Y"))
		local Z = tonumber(rawget(Target, "Z"))
		if X ~= nil and Y ~= nil and Z ~= nil then
			return X, Y, Z
		end
		local Position = rawget(Target, "Position")
		if typeof(Position) == "table" then
			return ReadVector3Components(Position)
		end
	end
	return 0, 0, 0
end

local function MakeCFrameFromPosition(X, Y, Z, Existing)
	local CFrameLib = DataTypes.Get("CFrame")
	if typeof(CFrameLib) == "table" and typeof(CFrameLib.new) == "function" then
		local Ok, Value = pcall(CFrameLib.new, X, Y, Z)
		if Ok and Value ~= nil then
			return Value
		end
	end

	if typeof(Existing) == "table" then
		local Copy = {}
		for Key, Value in next, Existing do
			Copy[Key] = Value
		end
		Copy.X = X
		Copy.Y = Y
		Copy.Z = Z
		Copy.Position = MakeVector3(X, Y, Z)
		Copy.__larryType = "CFrame"
		return Copy
	end

	return {
		X = X,
		Y = Y,
		Z = Z,
		Position = MakeVector3(X, Y, Z),
		__larryType = "CFrame",
	}
end

local function TranslatePart(Part, Dx, Dy, Dz)
	if typeof(Part) ~= "table" or typeof(Part.GetProperty) ~= "function" or typeof(Part.SetProperty) ~= "function" then
		return
	end

	local Position = Part:GetProperty("Position")
	local PX, PY, PZ = ReadVector3Components(Position)
	local NextPosition = MakeVector3(PX + Dx, PY + Dy, PZ + Dz)
	Part:SetProperty("Position", NextPosition)
	Part:SetProperty("_LarrySimPosition", NextPosition)

	local CFrameValue = Part:GetProperty("CFrame")
	local CX, CY, CZ = ReadVector3Components(CFrameValue)
	Part:SetProperty("CFrame", MakeCFrameFromPosition(CX + Dx, CY + Dy, CZ + Dz, CFrameValue))
end

local function PropagateWeldedCFrameMove(Inst, OldCFrame, NewCFrame)
	local OldX, OldY, OldZ = ReadVector3Components(OldCFrame)
	local NewX, NewY, NewZ = ReadVector3Components(NewCFrame)
	local Dx, Dy, Dz = NewX - OldX, NewY - OldY, NewZ - OldZ
	if math.abs(Dx) <= 1e-9 and math.abs(Dy) <= 1e-9 and math.abs(Dz) <= 1e-9 then
		return
	end

	local OkInstance, InstanceMod = pcall(require, "./Instance")
	if not OkInstance or typeof(InstanceMod) ~= "table" or typeof(InstanceMod.GetCreated) ~= "function" then
		return
	end

	for _, Candidate in ipairs(InstanceMod.GetCreated()) do
		if typeof(Candidate) == "table" and rawget(Candidate, "_ClassName") == "WeldConstraint" and typeof(Candidate.GetProperty) == "function" then
			local Part0 = Candidate:GetProperty("Part0")
			local Part1 = Candidate:GetProperty("Part1")
			if Part0 == Inst and Part1 ~= nil then
				TranslatePart(Part1, Dx, Dy, Dz)
			elseif Part1 == Inst and Part0 ~= nil then
				TranslatePart(Part0, Dx, Dy, Dz)
			end
		end
	end
end

function Properties.RegisterDynamic(ClassName, PropName, Generator)
	local Key = `{ClassName}.{PropName}`
	DynamicGenerators[Key] = Generator
end

function Properties.RegisterAlias(Alias, Canonical)
	DeprecatedAliases[string.lower(Alias)] = Canonical
end

function Properties.RegisterDefault(ClassName, PropName, Value)
	local Key = `{ClassName}.{PropName}`
	PropertyDefaults[Key] = Value
end

function Properties.RegisterNilDefault(ClassName, PropName)
	local Key = `{ClassName}.{PropName}`
	NilPropertyDefaults[Key] = true
end

function Properties.RegisterValidator(ClassName, PropName, Validator, ExpectedType)
	local Key = `{ClassName}.{PropName}`
	PropertyValidators[Key] = {
		Validator = Validator,
		ExpectedType = ExpectedType or "value",
	}
end

function Properties.ResolveAlias(PropName)
	return DeprecatedAliases[string.lower(PropName)] or PropName
end

function Properties.GetDefault(ClassName, PropName)
	local Resolved = Properties.ResolveAlias(PropName)
	return PropertyDefaults[`{ClassName}.{Resolved}`]
end

function Properties.HasNilDefault(ClassName, PropName)
	local Resolved = Properties.ResolveAlias(PropName)
	return NilPropertyDefaults[`{ClassName}.{Resolved}`] == true
end

function Properties.GetDynamic(ClassName, PropName)
	local Resolved = Properties.ResolveAlias(PropName)
	local Generator = DynamicGenerators[`{ClassName}.{Resolved}`]
	if Generator then
		return Generator(), true
	end
	return nil, false
end

function Properties.Get(Inst, PropName)
	local ClassName = Inst:GetClassName()
	local Resolved = Properties.ResolveAlias(PropName)

	if ClassName == "Tween" and Resolved == "PlaybackState" then
		TryFinalizeTweenPlayback(Inst)
	end

	if Resolved == "ClassName" then return ClassName end
	if Resolved == "Name" then return Inst:GetName() end
	if Resolved == "Parent" then return Inst:GetParent() end

	if Resolved == "Position" then
		local SimPosition = ReadExplicitProperty(Inst, "_LarrySimPosition")
		if SimPosition ~= nil then
			return SimPosition
		end
	end
	if Resolved == "Velocity" or Resolved == "AssemblyLinearVelocity" then
		local SimVelocity = ReadExplicitProperty(Inst, "_LarrySimVelocity")
		if SimVelocity ~= nil then
			return SimVelocity
		end
	end
	if Resolved == "CurrentPhysicalProperties" and (ClassName == "Part" or ClassName == "MeshPart" or ClassName == "WedgePart" or ClassName == "CornerWedgePart" or ClassName == "UnionOperation" or ClassName == "TrussPart" or ClassName == "SpawnLocation" or ClassName == "Seat" or ClassName == "VehicleSeat") then
		local CustomPhysical = ReadExplicitProperty(Inst, "CustomPhysicalProperties")
		if CustomPhysical ~= nil then
			return CustomPhysical
		end

		local Generated = TypeDefaults.ForType("PhysicalProperties", {
			Instance = Inst,
			ClassName = ClassName,
			PropertyName = Resolved,
		})
		if Generated ~= nil then
			Inst:SetProperty(Resolved, Generated)
			return Generated
		end
	end

	local Explicit = ReadExplicitProperty(Inst, Resolved)
	if Explicit ~= nil then return Explicit end

	local Dynamic, Found = Properties.GetDynamic(ClassName, Resolved)
	if Found then return Dynamic end

	local Default = Properties.GetDefault(ClassName, Resolved)
	if Default ~= nil then
		return Default
	end

	local Descriptor = ApiDumpIndex.GetPropertyDescriptor(ClassName, Resolved)
	if Descriptor ~= nil then
		local Generated = TypeDefaults.ForType(Descriptor.Type, {
			Instance = Inst,
			ClassName = ClassName,
			PropertyName = Resolved,
			SignalName = Resolved,
		})

		if Generated ~= nil then
			Inst:SetProperty(Resolved, Generated)
			return Generated
		end
	end

	return nil
end

function Properties.Set(Inst, PropName, Value, Emitter, Beautifier, State)
	local ClassName = Inst:GetClassName()
	local Resolved = Properties.ResolveAlias(PropName)
	local AssignedValue = Value
	local PreviousCFrame = nil

	if Resolved == "Name" then
		Inst:SetName(AssignedValue)
		pcall(View.ObserveProperty, Inst, Resolved, AssignedValue)
		return AssignedValue
	end

	if Resolved == "Parent" then
		if AssignedValue == Inst then
			error(`{Inst:GetClassName()}.Parent cannot be set to itself`)
		end
		Inst:SetParent(AssignedValue)
		pcall(View.ObserveProperty, Inst, Resolved, AssignedValue)
		return AssignedValue
	end

	if ApiDumpIndex.IsPropertyReadOnly(ClassName, Resolved) then
		error(`Unable to assign property {Resolved}. Property is read only`, 0)
	end

	if ClassName == "Camera" and Resolved == "FieldOfView" then
		local NumberValue = UnwrapValue(AssignedValue)
		if not IsNumber(NumberValue) then
			error(`Unable to assign property {Resolved}. number expected, got {DescribeValueType(AssignedValue)}`, 0)
		end
		AssignedValue = math.clamp(NumberValue, 1, 120)
	end

	if Resolved == "CFrame" and (ClassName == "Part" or ClassName == "MeshPart" or ClassName == "WedgePart" or ClassName == "CornerWedgePart" or ClassName == "UnionOperation" or ClassName == "TrussPart" or ClassName == "SpawnLocation" or ClassName == "Seat" or ClassName == "VehicleSeat") then
		PreviousCFrame = ReadExplicitProperty(Inst, "CFrame") or Inst:GetProperty("CFrame")
	end

	local Descriptor = ApiDumpIndex.GetPropertyDescriptor(ClassName, Resolved)
	local SkipDescriptorValidation = false
	if Resolved == "MaxForce" and ClassName == "LinearVelocity" and typeof(AssignedValue) == "number" and (AssignedValue == math.huge or AssignedValue == -math.huge) then
		SkipDescriptorValidation = true
	end
	if Descriptor ~= nil and not SkipDescriptorValidation then
		AssignedValue = select(1, CoerceMissingEnumValue(Descriptor.Type, AssignedValue))
		local Matches = TypeDefaults.MatchesType(Descriptor.Type, AssignedValue)
		if not Matches then
			local GotType = DescribeValueType(AssignedValue)
			error(`Unable to assign property {Resolved}. {Descriptor.Type} expected, got {GotType}`, 0)
		end
	end

	local Validation = PropertyValidators[`{ClassName}.{Resolved}`]
	if Validation and typeof(Validation.Validator) == "function" then
		local IsValid = Validation.Validator(AssignedValue)
		if not IsValid then
			local GotType = DescribeValueType(AssignedValue)
			error(`Unable to assign property {Resolved}. {Validation.ExpectedType} expected, got {GotType}`, 0)
		end
	end

	if Resolved == "Position" then
		Inst:SetProperty("_LarrySimPosition", AssignedValue)
	elseif Resolved == "Velocity" or Resolved == "AssemblyLinearVelocity" then
		Inst:SetProperty("_LarrySimVelocity", AssignedValue)
	elseif Resolved == "CFrame" then
		local X, Y, Z = ReadVector3Components(AssignedValue)
		local Position = MakeVector3(X, Y, Z)
		Inst:SetProperty("Position", Position)
		Inst:SetProperty("_LarrySimPosition", Position)
	end

	Inst:SetProperty(Resolved, AssignedValue)
	if PreviousCFrame ~= nil then
		PropagateWeldedCFrameMove(Inst, PreviousCFrame, AssignedValue)
	end
	pcall(View.ObserveProperty, Inst, Resolved, AssignedValue)
	return AssignedValue
end

function Properties.IsScriptable(ClassName, PropName)
	return true
end

Properties.RegisterAlias("parent", "Parent")
Properties.RegisterAlias("className", "ClassName")
Properties.RegisterAlias("name", "Name")

Properties.RegisterDefault("LocalScript", "Disabled", false)
Properties.RegisterDefault("ModuleScript", "Source", "return {}")
Properties.RegisterDefault("Part", "Anchored", false)
Properties.RegisterDefault("Part", "CanCollide", true)
Properties.RegisterDefault("Part", "Transparency", 0)
Properties.RegisterDefault("Part", "Shape", Enums.Get("PartType", "Block") or "Block")
Properties.RegisterDynamic("Part", "Color", function()
	return MakeColor3(163 / 255, 162 / 255, 165 / 255)
end)
Properties.RegisterDynamic("Part", "BrickColor", function()
	return MakeBrickColor("Medium stone grey")
end)
Properties.RegisterDefault("Workspace", "Gravity", 196.2)
Properties.RegisterDefault("Workspace", "FallenPartsDestroyHeight", -500)
Properties.RegisterDefault("Workspace", "StreamingEnabled", false)
Properties.RegisterDefault("CoreGui", "Version", 0)
Properties.RegisterDefault("TextLabel", "Text", "")
Properties.RegisterDefault("TextBox", "Text", "")
Properties.RegisterDefault("TextButton", "Text", "")
Properties.RegisterDefault("DataModel", "DataCost", 0)
Properties.RegisterDefault("Players", "RespawnTime", 5)
Properties.RegisterDefault("Lighting", "Ambient", {R = 0, G = 0, B = 0, __larryType = "Color3"})
Properties.RegisterDefault("Lighting", "OutdoorAmbient", {R = 0.5, G = 0.5, B = 0.5, __larryType = "Color3"})
Properties.RegisterDefault("Lighting", "FogColor", {R = 0.5, G = 0.5, B = 0.5, __larryType = "Color3"})
Properties.RegisterDefault("Fire", "Color", {R = 1, G = 0.5, B = 0, __larryType = "Color3"})
Properties.RegisterDefault("Smoke", "Color", {R = 0.5, G = 0.5, B = 0.5, __larryType = "Color3"})
Properties.RegisterDefault("Sparkles", "SparkleColor", {R = 1, G = 1, B = 1, __larryType = "Color3"})
Properties.RegisterDefault("Frame", "Position", {X = {Scale = 0, Offset = 0}, Y = {Scale = 0, Offset = 0}, __larryType = "UDim2"})
Properties.RegisterDefault("Frame", "Size", {X = {Scale = 1, Offset = 0}, Y = {Scale = 1, Offset = 0}, __larryType = "UDim2"})
Properties.RegisterDefault("Frame", "AnchorPoint", {X = 0, Y = 0, __larryType = "Vector2"})
Properties.RegisterDefault("Frame", "BorderColor3", {R = 0, G = 0, B = 0, __larryType = "Color3"})
Properties.RegisterDefault("Frame", "BorderSizePixel", 1)
Properties.RegisterDefault("TextLabel", "FontFace", {Family = "SourceSans", Weight = "Regular", Style = "Normal", __larryType = "Font"})
Properties.RegisterDefault("TextLabel", "TextColor3", {R = 1, G = 1, B = 1, __larryType = "Color3"})
Properties.RegisterDefault("TextLabel", "TextStrokeColor3", {R = 0, G = 0, B = 0, __larryType = "Color3"})
Properties.RegisterDefault("ColorCorrectionEffect", "TintColor", {R = 1, G = 1, B = 1, __larryType = "Color3"})
Properties.RegisterDefault("Atmosphere", "Color", {R = 0.5, G = 0.7, B = 1, __larryType = "Color3"})
Properties.RegisterDynamic("Player", "MembershipType", function()
	local Enums = require("./Enums")
	return Enums.Get("MembershipType", "None") or "None"
end)
Properties.RegisterDefault("Player", "TeamColor", "Medium stone grey")
Properties.RegisterDefault("Player", "Neutral", true)
Properties.RegisterDefault("Humanoid", "Health", 100)
Properties.RegisterDefault("Humanoid", "MaxHealth", 100)
Properties.RegisterDefault("Humanoid", "WalkSpeed", 16)
Properties.RegisterDefault("Humanoid", "JumpPower", 50)
Properties.RegisterDefault("Humanoid", "HealthDisplayDistance", 100)
Properties.RegisterDefault("Humanoid", "NameDisplayDistance", 100)
Properties.RegisterDefault("Humanoid", "AutoRotate", true)
Properties.RegisterDefault("Humanoid", "DisplayDistanceType", Enums.Get("HumanoidDisplayDistanceType", "Viewer") or "Viewer")
Properties.RegisterDefault("Camera", "FieldOfView", 70)
Properties.RegisterDefault("Camera", "CameraType", Enums.Get("CameraType", "Custom") or "Custom")
Properties.RegisterNilDefault("GuiService", "SelectedObject")
Properties.RegisterNilDefault("GuiService", "SelectedCoreObject")
Properties.RegisterDefault("StarterGui", "ResetPlayerGuiOnSpawn", true)

Properties.RegisterDynamic("Camera", "ViewportSize", function()
	return MakeVector2(1920, 1080)
end)

Properties.RegisterDynamic("Camera", "CFrame", function()
	local Ok, Value = pcall(function()
		local CFrameLib = DataTypes.Get("CFrame")
		if typeof(CFrameLib) == "table" and typeof(CFrameLib.new) == "function" then
			return CFrameLib.new(0, 5, 0)
		end
		return CFrame.new(0, 5, 0)
	end)

	if Ok and Value ~= nil then
		return Value
	end

	local function MakeVec(X, Y, Z)
		local OkVec, Vec = pcall(function()
			local Vector3Lib = DataTypes.Get("Vector3")
			if typeof(Vector3Lib) == "table" and typeof(Vector3Lib.new) == "function" then
				return Vector3Lib.new(X, Y, Z)
			end
			return Vector3.new(X, Y, Z)
		end)
		if OkVec and Vec ~= nil then
			return Vec
		end
		return { X = X, Y = Y, Z = Z }
	end

	return {
		X = 0,
		Y = 5,
		Z = 0,
		Position = MakeVec(0, 5, 0),
		RightVector = MakeVec(1, 0, 0),
		UpVector = MakeVec(0, 1, 0),
		LookVector = MakeVec(0, 0, -1),
	}
end)

Properties.RegisterDynamic("Camera", "Focus", function()
	local Ok, Value = pcall(function()
		local CFrameLib = DataTypes.Get("CFrame")
		if typeof(CFrameLib) == "table" and typeof(CFrameLib.new) == "function" then
			return CFrameLib.new(0, 0, 0)
		end
		return CFrame.new(0, 0, 0)
	end)
	if Ok and Value ~= nil then return Value end
	return { X = 0, Y = 0, Z = 0 }
end)

Properties.RegisterDefault("Camera", "NearPlaneZ", -0.1)
Properties.RegisterDefault("Camera", "FarPlaneZ", 10000)
Properties.RegisterDefault("Model", "WorldPivot", { X = 0, Y = 0, Z = 0, __larryType = "CFrame" })

Properties.RegisterValidator("Camera", "FieldOfView", function(Value)
	return IsNumber(Value)
end, "number")

Properties.RegisterValidator("GuiService", "SelectedObject", function(Value)
	if Value == nil then
		return true
	end
	return typeof(Value) == "table" and typeof(Value.IsA) == "function" and Value:IsA("GuiObject")
end, "GuiObject")

Properties.RegisterValidator("GuiService", "SelectedCoreObject", function(Value)
	if Value == nil then
		return true
	end
	return typeof(Value) == "table" and typeof(Value.IsA) == "function" and Value:IsA("GuiObject")
end, "GuiObject")

Properties.RegisterDynamic("DataModel", "PlaceId", function()
	return math.random(100000, 99999999)
end)

Properties.RegisterDynamic("DataModel", "GameId", function()
	return math.random(100000, 99999999)
end)

Properties.RegisterDynamic("DataModel", "JobId", function()
	return IdentityUtil.Generate(32)
end)

Properties.RegisterDynamic("Player", "UserId", function()
	return math.random(100000, 9999999)
end)

Properties.RegisterDynamic("Player", "DisplayName", function()
	return "Player" .. tostring(math.random(1000, 9999))
end)

Properties.RegisterDynamic("Player", "AccountAge", function()
	return math.random(90, 2400)
end)

Properties.RegisterDynamic("Workspace", "DistributedGameTime", function()
	local RuntimeClock = require("./RuntimeClock")
	return RuntimeClock.GetServerNow()
end)

Properties.RegisterDynamic("Part", "Position", function()
	return MakeVector3(0, 0, 0)
end)

Properties.RegisterDynamic("Part", "CFrame", function(Inst)
	local X, Y, Z = 0, 0, 0
	if typeof(Inst) == "table" and typeof(Inst.GetProperty) == "function" then
		local Position = Inst:GetProperty("Position")
		if typeof(Position) == "table" then
			X = tonumber(rawget(Position, "X")) or 0
			Y = tonumber(rawget(Position, "Y")) or 0
			Z = tonumber(rawget(Position, "Z")) or 0
		end
	end

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
		Position = MakeVector3(X, Y, Z),
		RightVector = MakeVector3(1, 0, 0),
		UpVector = MakeVector3(0, 1, 0),
		LookVector = MakeVector3(0, 0, -1),
		__larryType = "CFrame",
	}
end)

Properties.RegisterDynamic("MeshPart", "CFrame", function(Inst)
	local X, Y, Z = 0, 0, 0
	if typeof(Inst) == "table" and typeof(Inst.GetProperty) == "function" then
		local Position = Inst:GetProperty("Position")
		if typeof(Position) == "table" then
			X = tonumber(rawget(Position, "X")) or 0
			Y = tonumber(rawget(Position, "Y")) or 0
			Z = tonumber(rawget(Position, "Z")) or 0
		end
	end

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
		Position = MakeVector3(X, Y, Z),
		RightVector = MakeVector3(1, 0, 0),
		UpVector = MakeVector3(0, 1, 0),
		LookVector = MakeVector3(0, 0, -1),
		__larryType = "CFrame",
	}
end)

Properties.RegisterDynamic("Part", "Orientation", function()
	return MakeVector3(0, 0, 0)
end)

Properties.RegisterDynamic("Part", "Rotation", function()
	return MakeVector3(0, 0, 0)
end)

Properties.RegisterDynamic("Part", "Size", function()
	return MakeVector3(4, 1, 2)
end)

Properties.RegisterDynamic("Player", "Name", function()
	return "Player_" .. IdentityUtil.Generate(6)
end)

for _, Prop in { "Position", "Orientation", "Rotation", "Size", "Velocity", "RotVelocity", "AssemblyLinearVelocity", "AssemblyAngularVelocity" } do
	Properties.RegisterValidator("Part", Prop, IsVector3Like, "Vector3")
	Properties.RegisterValidator("MeshPart", Prop, IsVector3Like, "Vector3")
end

for _, Prop in { "Anchored", "CanCollide", "CanTouch", "CanQuery" } do
	Properties.RegisterValidator("Part", Prop, IsBoolean, "boolean")
	Properties.RegisterValidator("MeshPart", Prop, IsBoolean, "boolean")
end

for _, Prop in { "Transparency", "Reflectance" } do
	Properties.RegisterValidator("Part", Prop, IsNumber, "number")
	Properties.RegisterValidator("MeshPart", Prop, IsNumber, "number")
end

return Properties