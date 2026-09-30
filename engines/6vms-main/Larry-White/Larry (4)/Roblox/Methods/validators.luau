local ApiDumpIndex = require("../ApiCatalog")
local TypeDefaults = require("../TypeDefaults")

local Validators = {}

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
	local EffectiveRequiredCount = RequiredCount
	for Index = #ParsedArguments, 1, -1 do
		local ArgDescriptor = ParsedArguments[Index]
		if ArgDescriptor.Variadic == true or ArgDescriptor.Optional == true then
			EffectiveRequiredCount = math.min(EffectiveRequiredCount, Index - 1)
			continue
		end

		if IsBroadExpectedType(ArgDescriptor.Type or "any") then
			EffectiveRequiredCount = math.min(EffectiveRequiredCount, Index - 1)
			continue
		end

		break
	end

	if ArgCount < EffectiveRequiredCount then
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

function Validators.ResolveMethodCandidates(Registry, Inst, MethodName)
	local ClassName = Registry.ClassNameOf(Inst)
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

function Validators.ResolveMethodDescriptor(Registry, Inst, MethodName)
	local Candidates, ClassName = Validators.ResolveMethodCandidates(Registry, Inst, MethodName)
	if typeof(Candidates) == "table" and #Candidates > 0 then
		return Candidates[1], ClassName
	end
	return nil, ClassName
end

function Validators.ValidateMethodArguments(Registry, Inst, MethodName, ...)
	local Candidates, ClassName = Validators.ResolveMethodCandidates(Registry, Inst, MethodName)
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

return Validators