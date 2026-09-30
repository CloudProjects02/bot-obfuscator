local Enums = require("./Enums")
local Signals = require("./Signals")
local ApiDumpIndex = require("./ApiCatalog")
local BufferAndCrypto = require("../Libs/BufferAndCrypto")

local TypeDefaults = {}

local NumericTypes = {
	int = true,
	int64 = true,
	int32 = true,
	int16 = true,
	int8 = true,
	double = true,
	float = true,
	number = true,
	integer = true,
}

local StringTypes = {
	string = true,
	binarystring = true,
	sharedstring = true,
	protectedstring = true,
	content = true,
	token = true,
}

local function Trim(Value)
	if typeof(Value) ~= "string" then
		return ""
	end
	return (string.gsub(string.gsub(Value, "^%s+", ""), "%s+$", ""))
end

local function NormalizeTypeName(TypeName)
	local Out = Trim(TypeName)

	if Out == "" then
		return Out
	end

	Out = string.gsub(Out, "%?$", "")
	Out = string.gsub(Out, "^%((.*)%)$", "%1")
	Out = Trim(Out)

	local UnionFirst = string.match(Out, "^([^|]+)|")
	if UnionFirst then
		Out = Trim(UnionFirst)
	end

	return Out
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

local function TryGlobalConstructor(TypeName, Constructor, ...)
	local Env = getfenv()
	local Lib = Env[TypeName]
	if typeof(Lib) ~= "table" then
		return nil
	end

	local Ctor = Lib[Constructor]
	if typeof(Ctor) ~= "function" then
		return nil
	end

	local Ok, Result = pcall(Ctor, ...)
	if Ok then
		return Result
	end

	return nil
end

local function PrimitiveDefault(TypeName)
	local Lower = string.lower(TypeName)

	if Lower == "bool" or Lower == "boolean" then
		return false
	end

	if NumericTypes[Lower] then
		return 0
	end

	if StringTypes[Lower] then
		return ""
	end

	if Lower == "void" or Lower == "null" or Lower == "nil" then
		return nil
	end

	return nil
end

local function DataTypeDefault(TypeName)
	if TypeName == "Vector3" then
		return TryGlobalConstructor("Vector3", "new", 0, 0, 0) or { X = 0, Y = 0, Z = 0 }
	end

	if TypeName == "Vector2" then
		return TryGlobalConstructor("Vector2", "new", 0, 0) or { X = 0, Y = 0 }
	end

	if TypeName == "UDim" then
		return TryGlobalConstructor("UDim", "new", 0, 0) or { Scale = 0, Offset = 0 }
	end

	if TypeName == "UDim2" then
		return TryGlobalConstructor("UDim2", "new", 0, 0, 0, 0) or {
			X = { Scale = 0, Offset = 0 },
			Y = { Scale = 0, Offset = 0 },
		}
	end

	if TypeName == "CFrame" then
		return TryGlobalConstructor("CFrame", "new", 0, 0, 0)
	end

	if TypeName == "Color3" then
		return TryGlobalConstructor("Color3", "new", 0, 0, 0)
	end

	if TypeName == "BrickColor" then
		return TryGlobalConstructor("BrickColor", "new", "Medium stone grey")
	end

	if TypeName == "NumberRange" then
		return TryGlobalConstructor("NumberRange", "new", 0, 0)
	end

	if TypeName == "PhysicalProperties" then
		return TryGlobalConstructor("PhysicalProperties", "new", 0.7, 0.3, 0.5, 1, 1)
	end

	if TypeName == "Rect" then
		return TryGlobalConstructor("Rect", "new", 0, 0, 0, 0)
	end

	if TypeName == "TweenInfo" then
		return TryGlobalConstructor("TweenInfo", "new")
	end

	if TypeName == "Random" then
		return TryGlobalConstructor("Random", "new")
	end

	if TypeName == "RaycastParams" then
		return TryGlobalConstructor("RaycastParams", "new")
	end

	if TypeName == "OverlapParams" then
		return TryGlobalConstructor("OverlapParams", "new")
	end

	if TypeName == "DateTime" then
		local Now = TryGlobalConstructor("DateTime", "now")
		if Now ~= nil then
			return Now
		end
		return TryGlobalConstructor("DateTime", "fromUnixTimestamp", os.time())
	end

	if TypeName == "Content" then
		return TryGlobalConstructor("Content", "fromUri", "")
	end

	if TypeName == "FloatCurveKey" then
		return TryGlobalConstructor("FloatCurveKey", "new", 0, 0)
	end

	if TypeName == "RotationCurveKey" then
		local Cf = TryGlobalConstructor("CFrame", "new", 0, 0, 0)
		return TryGlobalConstructor("RotationCurveKey", "new", 0, Cf)
	end

	if TypeName == "Path2DControlPoint" then
		local V = TryGlobalConstructor("Vector2", "new", 0, 0)
		return TryGlobalConstructor("Path2DControlPoint", "new", V, V, V)
	end

	if TypeName == "PathWaypoint" then
		local V = TryGlobalConstructor("Vector3", "new", 0, 0, 0)
		return TryGlobalConstructor("PathWaypoint", "new", V)
	end

	if TypeName == "SecurityCapabilities" then
		return TryGlobalConstructor("SecurityCapabilities", "new", 0)
	end

	return nil
end

local function IsFiniteNumber(Value)
	return typeof(Value) == "number" and Value == Value and Value ~= math.huge and Value ~= -math.huge
end

local function IsBufferLike(Value)
	if typeof(Value) == "buffer" then
		return true
	end

	return BufferAndCrypto.TryBufferToString(Value) ~= nil
end

local function IsEnumItemLike(Value, EnumName)
	if Enums.IsEnumItem and Enums.IsEnumItem(Value) then
		if EnumName == nil then
			return true
		end

		local Declared = rawget(Value, "_EnumType") or rawget(Value, "EnumType")
		if typeof(Declared) == "string" and Declared ~= "" then
			return Declared == EnumName
		end

		return true
	end

	if typeof(Value) == "EnumItem" then
		if EnumName == nil then
			return true
		end

		local AsText = tostring(Value)
		if type(AsText) == "string" then
			local Parsed = string.match(AsText, "^Enum%.([%w_]+)%.")
			if Parsed then
				return Parsed == EnumName
			end
		end

		return true
	end

	return false
end

function TypeDefaults.MatchesType(TypeName, Value)
	local RawTypeName = Trim(TypeName)
	local IsOptional = string.sub(RawTypeName, -1) == "?"
	local Normalized = NormalizeTypeName(TypeName)
	if Normalized == "" then
		return true
	end

	local Actual = UnwrapValue(Value)
	if IsOptional and Actual == nil then
		return true
	end

	local Primitive = PrimitiveDefault(Normalized)
	local Lower = string.lower(Normalized)

	if Primitive ~= nil or Lower == "bool" or Lower == "boolean" or NumericTypes[Lower] or StringTypes[Lower] or Lower == "void" or Lower == "null" or Lower == "nil" then
		if Lower == "bool" or Lower == "boolean" then
			return typeof(Actual) == "boolean"
		end
		if NumericTypes[Lower] then
			return IsFiniteNumber(Actual)
		end
		if StringTypes[Lower] then
			return typeof(Actual) == "string"
		end
		if Lower == "void" or Lower == "null" or Lower == "nil" then
			return Actual == nil
		end
	end

	if Lower == "buffer" then
		return IsBufferLike(Actual)
	end

	if string.find(Lower, "array", 1, true) or string.find(Lower, "dictionary", 1, true) or string.find(Lower, "map", 1, true) then
		return typeof(Actual) == "table"
	end

	if string.sub(Normalized, -2) == "[]" or Lower == "tuple" or string.find(Lower, "table", 1, true) then
		return typeof(Actual) == "table"
	end

	if string.sub(Normalized, 1, 1) == "{" and string.sub(Normalized, -1) == "}" then
		return typeof(Actual) == "table"
	end

	if Lower == "rbxscriptsignal" or string.find(Lower, "signal", 1, true) then
		return typeof(Actual) == "table"
	end

	local EnumName = string.match(Normalized, "^Enum%.([%w_]+)$")
	if EnumName ~= nil then
		if IsEnumItemLike(Actual, EnumName) then
			return true
		end
		return typeof(Actual) == "string" or typeof(Actual) == "number"
	end

	if ApiDumpIndex.EnumExists(Normalized) then
		if IsEnumItemLike(Actual, Normalized) then
			return true
		end
		return typeof(Actual) == "string" or typeof(Actual) == "number"
	end

	if Normalized == "Vector3" then
		if typeof(Actual) == "Vector3" then
			return true
		end
		if typeof(Actual) == "table" then
			return typeof(rawget(Actual, "X")) == "number"
				and typeof(rawget(Actual, "Y")) == "number"
				and typeof(rawget(Actual, "Z")) == "number"
		end
		return false
	end

	if Normalized == "Vector2" then
		if typeof(Actual) == "Vector2" then
			return true
		end
		if typeof(Actual) == "table" then
			return typeof(rawget(Actual, "X")) == "number"
				and typeof(rawget(Actual, "Y")) == "number"
		end
		return false
	end

	if Normalized == "UDim2" then
		return typeof(Actual) == "UDim2" or typeof(Actual) == "table"
	end

	if Normalized == "UDim" then
		return typeof(Actual) == "UDim" or typeof(Actual) == "table"
	end

	if Normalized == "CFrame" then
		return typeof(Actual) == "CFrame" or typeof(Actual) == "table"
	end

	if Normalized == "Color3" then
		return typeof(Actual) == "Color3" or typeof(Actual) == "table"
	end

	if Normalized == "BrickColor" then
		return typeof(Actual) == "BrickColor" or typeof(Actual) == "string" or typeof(Actual) == "table"
	end

	if Normalized == "Instance" then
		return typeof(Actual) == "table" and typeof(Actual.IsA) == "function"
	end

	if ApiDumpIndex.HasClass(Normalized) then
		if typeof(Actual) ~= "table" then
			return false
		end

		local IsA = Actual.IsA
		if typeof(IsA) == "function" then
			local Ok, Result = pcall(IsA, Actual, Normalized)
			if Ok then
				return Result == true
			end
		end

		return typeof(Actual.GetClassName) == "function"
	end

	return true
end

function TypeDefaults.ParseTupleTypes(TypeName)
	local Normalized = NormalizeTypeName(TypeName)
	if Normalized == "" then
		return nil
	end

	if not (string.sub(Normalized, 1, 1) == "(" and string.sub(Normalized, -1) == ")") then
		return nil
	end

	local Inner = string.sub(Normalized, 2, #Normalized - 1)
	if not string.find(Inner, ",", 1, true) then
		return nil
	end

	local Out = {}
	for Part in string.gmatch(Inner, "[^,]+") do
		Out[#Out + 1] = NormalizeTypeName(Part)
	end

	if #Out == 0 then
		return nil
	end

	return Out
end

function TypeDefaults.ForTuple(TypeName, Context)
	local TupleTypes = TypeDefaults.ParseTupleTypes(TypeName)
	if not TupleTypes then
		return nil
	end

	local Packed = { n = #TupleTypes }
	for I, TupleType in ipairs(TupleTypes) do
		Packed[I] = TypeDefaults.ForType(TupleType, Context)
	end

	return Packed
end

function TypeDefaults.ForType(TypeName, Context)
	local Normalized = NormalizeTypeName(TypeName)
	if Normalized == "" then
		return nil
	end

	local Primitive = PrimitiveDefault(Normalized)
	if Primitive ~= nil then
		return Primitive
	end

	local Lower = string.lower(Normalized)

	if string.find(Lower, "array", 1, true) then
		return {}
	end

	if string.find(Lower, "dictionary", 1, true) or string.find(Lower, "map", 1, true) then
		return {}
	end

	if string.sub(Normalized, -2) == "[]" then
		return {}
	end

	if Lower == "tuple" then
		return {}
	end

	if Lower == "objects" or Lower == "instances" then
		return {}
	end

	if string.sub(Normalized, 1, 1) == "{" and string.sub(Normalized, -1) == "}" then
		return {}
	end

	if Lower == "rbxscriptsignal" or string.find(Lower, "signal", 1, true) then
		if Context and Context.Instance then
			local Name = Context.SignalName or Context.PropertyName or Context.MethodName or "Signal"
			return Signals.ForInstance(Context.Instance, Name)
		end
		return nil
	end

	local EnumName = string.match(Normalized, "^Enum%.([%w_]+)$")
	if EnumName ~= nil then
		local DefaultItem = ApiDumpIndex.GetFirstEnumItem(EnumName) or "Unknown"
		return Enums.Get(EnumName, DefaultItem)
	end

	if ApiDumpIndex.EnumExists(Normalized) then
		local DefaultItem = ApiDumpIndex.GetFirstEnumItem(Normalized) or "Unknown"
		return Enums.Get(Normalized, DefaultItem)
	end

	local DataType = DataTypeDefault(Normalized)
	if DataType ~= nil then
		return DataType
	end

	if Lower == "buffer" then
		local Ok, Value = pcall(BufferAndCrypto.StringToBuffer, "", "TypeDefaults.ForType")
		if Ok then
			return Value
		end
		return nil
	end

	if string.find(Lower, "table", 1, true) then
		return {}
	end

	return nil
end

return TypeDefaults