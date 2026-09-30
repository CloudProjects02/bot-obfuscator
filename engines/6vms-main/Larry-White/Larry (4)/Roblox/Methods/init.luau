local Registry = require("./Methods/registry")
local Validators = require("./Methods/validators")
local Fallbacks = require("./Methods/fallbacks")
local ApiDumpIndex = require("./ApiCatalog")

local Methods = {}

function Methods.Register(ClassName, MethodName, Handler)
	Registry.Register(ClassName, MethodName, Handler)
end

function Methods.RegisterGlobal(MethodName, Handler)
	Registry.RegisterGlobal(MethodName, Handler)
end

function Methods.GetSpecific(Inst, MethodName)
	return Registry.GetSpecific(Inst, MethodName)
end

function Methods.GetGlobal(MethodName)
	return Registry.GetGlobal(MethodName)
end

function Methods.GetDumpFallback(Inst, MethodName)
	local ClassName = Registry.ClassNameOf(Inst)
	if ClassName == nil or typeof(MethodName) ~= "string" then
		return nil
	end

	if ApiDumpIndex.HasCallback(ClassName, MethodName) then
		return nil
	end

	local CacheKey = `{ClassName}.{MethodName}`
	local Cached = Registry.GetDynamic(CacheKey)
	if Cached ~= nil then
		return Cached == false and nil or Cached
	end

	local Descriptor, ResolvedClassName = Validators.ResolveMethodDescriptor(Registry, Inst, MethodName)
	if Descriptor == nil then
		Registry.SetDynamic(CacheKey, false)
		return nil
	end

	local HandlerClassName = ResolvedClassName or ClassName
	local Handler = function(TargetInst, ...)
		return Fallbacks.AutoMethodFallback(TargetInst, HandlerClassName, MethodName, Descriptor, ...)
	end

	Registry.SetDynamic(CacheKey, Handler)
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
		Validators.ValidateMethodArguments(Registry, Inst, MethodName, ...)
		return Handler(Inst, ...)
	end
	return nil
end

function Methods.Validate(Inst, MethodName, ...)
	Validators.ValidateMethodArguments(Registry, Inst, MethodName, ...)
end

function Methods.Has(Inst, MethodName)
	return Methods.Get(Inst, MethodName) ~= nil
end

local ClassModules = {
	require("./Methods/classes/misc"),
	require("./Methods/classes/datamodel"),
	require("./Methods/classes/runservice"),
	require("./Methods/classes/workspace"),
	require("./Methods/classes/players"),
	require("./Methods/classes/collectionservice"),
	require("./Methods/classes/logservice"),
	require("./Methods/classes/stats"),
	require("./Methods/classes/bindables"),
	require("./Methods/classes/debris"),
	require("./Methods/classes/basepart"),
	require("./Methods/classes/humanoid"),
	require("./Methods/classes/services_ext"),
}

for _, Module in ipairs(ClassModules) do
	if typeof(Module) == "table" and typeof(Module.Register) == "function" then
		Module.Register(Methods, Fallbacks)
	end
end

return Methods