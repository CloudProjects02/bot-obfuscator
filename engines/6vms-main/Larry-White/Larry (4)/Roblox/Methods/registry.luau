local ApiDumpIndex = require("../ApiCatalog")

local Registry = {}

local MethodRegistry = {}
local DynamicMethodCache = {}

function Registry.ClassNameOf(Inst)
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

function Registry.Register(ClassName, MethodName, Handler)
	local Key = `{ClassName}.{MethodName}`
	MethodRegistry[Key] = Handler
	DynamicMethodCache[Key] = nil
end

function Registry.RegisterGlobal(MethodName, Handler)
	MethodRegistry[`*.{MethodName}`] = Handler
end

function Registry.GetSpecific(Inst, MethodName)
	local ClassName = Registry.ClassNameOf(Inst)
	if not ClassName then
		return nil
	end

	local Exact = MethodRegistry[`{ClassName}.{MethodName}`]
	if Exact ~= nil then
		return Exact
	end

	local Seen = {}
	local Current = ClassName
	while typeof(Current) == "string" and Current ~= "" and not Seen[Current] do
		Seen[Current] = true
		local Entry = ApiDumpIndex.GetClass(Current)
		if Entry == nil then
			break
		end

		local Super = Entry.Super
		if typeof(Super) ~= "string" or Super == "" then
			break
		end

		local Handler = MethodRegistry[`{Super}.{MethodName}`]
		if Handler ~= nil then
			return Handler
		end

		Current = Super
	end

	return nil
end

function Registry.GetGlobal(MethodName)
	return MethodRegistry[`*.{MethodName}`]
end

function Registry.GetDynamic(CacheKey)
	return DynamicMethodCache[CacheKey]
end

function Registry.SetDynamic(CacheKey, Value)
	DynamicMethodCache[CacheKey] = Value
end

return Registry