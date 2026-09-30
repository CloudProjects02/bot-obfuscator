local TypeDefaults = require("../TypeDefaults")
local ApiDumpIndex = require("../ApiCatalog")

local Fallbacks = {}

local ServerClockStart = os.clock()
local ServerTimeStart = os.time() + (ServerClockStart % 1)
local LastServerTime = ServerTimeStart

function Fallbacks.NextServerTimeNow()
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

local function NormalizeSingleReturnType(ReturnType)
	if typeof(ReturnType) ~= "string" then
		return nil
	end

	local Normalized = string.gsub(ReturnType, "^%s+", "")
	Normalized = string.gsub(Normalized, "%s+$", "")
	Normalized = string.gsub(Normalized, "%?$", "")
	Normalized = string.gsub(Normalized, "^%((.*)%)$", "%1")
	Normalized = string.match(Normalized, "^([^|]+)") or Normalized
	Normalized = string.gsub(Normalized, "^%s+", "")
	Normalized = string.gsub(Normalized, "%s+$", "")

	if Normalized == "" then
		return nil
	end

	return Normalized
end

local function CreateInternalInstanceLike(Inst, ClassName, MethodName)
	if typeof(ClassName) ~= "string" or ClassName == "" then
		return nil
	end

	local InstanceClass = ClassName
	if ClassName == "LuaSourceContainer" then
		InstanceClass = "LocalScript"
	elseif ClassName == "Instance" then
		InstanceClass = "Folder"
	end

	if not ApiDumpIndex.HasClass(InstanceClass) then
		return nil
	end

	local InstanceMod = require("../Instance")
	local Created = InstanceMod._new(
		InstanceClass,
		{},
		rawget(Inst, "_Proxy"),
		rawget(Inst, "_State"),
		rawget(Inst, "_Emitter"),
		rawget(Inst, "_Beautifier"),
		rawget(Inst, "_Scope"),
		true
	)

	if typeof(Created) == "table" and rawget(Created, "_Name") == InstanceClass then
		Created._Name = MethodName ~= nil and `{MethodName}_{InstanceClass}` or InstanceClass
	end

	return Created
end

function Fallbacks.AutoMethodFallback(Inst, ClassName, MethodName, Descriptor, ...)
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

	local ConcreteReturnType = NormalizeSingleReturnType(ReturnType)
	if ConcreteReturnType ~= nil then
		local InstanceValue = CreateInternalInstanceLike(Inst, ConcreteReturnType, MethodName)
		if InstanceValue ~= nil then
			return InstanceValue
		end
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

return Fallbacks