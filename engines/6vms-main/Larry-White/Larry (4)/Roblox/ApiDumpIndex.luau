local fs = require("@lune/fs")

local ApiDumpIndex = {}

local DumpPath = "Data/Robloxdump.txt"
local DumpCandidatePaths = {
	"Data/Robloxdump.txt",
	"./Data/Robloxdump.txt",
	"../Data/Robloxdump.txt",
	"..\\Data\\Robloxdump.txt",
}

local function AddCandidatePath(Path)
	if typeof(Path) ~= "string" or Path == "" then
		return
	end

	for _, Existing in ipairs(DumpCandidatePaths) do
		if Existing == Path then
			return
		end
	end

	table.insert(DumpCandidatePaths, Path)
end

do
	local ModuleSource = debug.info(1, "s")
	if typeof(ModuleSource) == "string" and ModuleSource ~= "[C]" then
		ModuleSource = string.gsub(ModuleSource, "^@", "")
		local ModuleDir = string.match(ModuleSource, "^(.*)[/\\][^/\\]+$")
		if ModuleDir then
			AddCandidatePath(ModuleDir .. "/../Data/Robloxdump.txt")
			AddCandidatePath(ModuleDir .. "\\..\\Data\\Robloxdump.txt")
		end
	end
end

local Loaded = false
local LoadError = nil

local Classes = {}
local Enums = {}
local EnumOrder = {}
local GlobalFunctionByName = {}
local GlobalFunctionOverloadsByName = {}

local ClassCount = 0
local PropertyCount = 0
local FunctionCount = 0
local EventCount = 0
local CallbackCount = 0
local EnumCount = 0
local EnumItemCount = 0

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

local function Trim(Value)
	if typeof(Value) ~= "string" then
		return ""
	end
	return (string.gsub(string.gsub(Value, "^%s+", ""), "%s+$", ""))
end

local function StripTrailingMetadata(Value)
	local Out = Trim(Value)
	local Previous = nil

	local function IsMetadataBrace(BraceContent)
		local Content = Trim(BraceContent)
		if Content == "" then
			return true
		end

		if string.find(Content, "🛠", 1, true) then return true end
		if string.find(Content, "🔒", 1, true) then return true end
		if string.find(Content, "✏", 1, true) then return true end
		if string.find(Content, "🧬", 1, true) then return true end
		if string.find(Content, "📁", 1, true) then return true end

		if string.find(Content, "RobloxScript", 1, true) then return true end
		if string.find(Content, "LocalUser", 1, true) then return true end
		if string.find(Content, "Plugin", 1, true) then return true end

		return false
	end

	while Previous ~= Out do
		Previous = Out
		Out = Trim((string.gsub(Out, "%s*%b[]%s*$", "")))

		local OpenIdx, CloseIdx = string.find(Out, "%b{}%s*$")
		if OpenIdx and CloseIdx then
			local Brace = string.sub(Out, OpenIdx + 1, CloseIdx - 1)
			if IsMetadataBrace(Brace) then
				Out = Trim(string.sub(Out, 1, OpenIdx - 1))
			end
		end
	end

	return Out
end

local function ExtractModifierFlags(Value)
	local Flags = {}
	if typeof(Value) ~= "string" or Value == "" then
		return Flags
	end

	for Group in string.gmatch(Value, "%b[]") do
		local Inner = string.sub(Group, 2, #Group - 1)
		for Token in string.gmatch(Inner, "[^,%s]+") do
			Flags[Token] = true
		end
	end

	return Flags
end

local function AddMetadataFlag(Flags, Token)
	local Clean = Trim(Token)
	if Clean == "" then
		return
	end

	Flags[Clean] = true

	local Normalized = string.gsub(Clean, "[^%w_]", "")
	if Normalized ~= "" then
		Flags[Normalized] = true
	end
end

local function ExtractTagFlags(Value)
	local Flags = {}
	if typeof(Value) ~= "string" or Value == "" then
		return Flags
	end

	for Group in string.gmatch(Value, "%b{}") do
		local Inner = string.sub(Group, 2, #Group - 1)
		for Token in string.gmatch(Inner, "[^,%s|]+") do
			AddMetadataFlag(Flags, Token)
		end
	end

	for Group in string.gmatch(Value, "%b[]") do
		local Inner = string.sub(Group, 2, #Group - 1)
		for Token in string.gmatch(Inner, "[^,%s|]+") do
			AddMetadataFlag(Flags, Token)
		end
	end

	return Flags
end

local function EnsureClass(ClassName)
	local Existing = Classes[ClassName]
	if Existing ~= nil then
		return Existing
	end

	local Entry = {
		Name = ClassName,
		Super = nil,
		Modifiers = "",
		ModifierFlags = {},
		TagFlags = {},
		Properties = {},
		Functions = {},
		FunctionOverloads = {},
		Events = {},
		Callbacks = {},
		CallbackOverloads = {},
	}

	Classes[ClassName] = Entry
	ClassCount += 1
	return Entry
end

local function ParseClass(Line)
	local Name, Super, Modifiers = string.match(Line, "^Class%s+([%w_]+)%s*:%s*([%w_]+)%s*(.*)$")
	if Name == nil then
		Name, Modifiers = string.match(Line, "^Class%s+([%w_]+)%s*(.*)$")
	end
	if Name == nil then
		return
	end

	local Entry = EnsureClass(Name)
	Entry.Super = Super
	Entry.Modifiers = Trim(Modifiers or "")
	Entry.ModifierFlags = ExtractModifierFlags(Entry.Modifiers)
	Entry.TagFlags = ExtractTagFlags(Entry.Modifiers)
end

local function ParseProperty(Line)
	local ClassName, PropertyName, Tail = string.match(Line, "^Property%s+([%w_]+)%.([%w_]+)%s*:%s*(.+)$")
	if not ClassName then
		return
	end

	local Entry = EnsureClass(ClassName)
	local TypeName = StripTrailingMetadata(Tail)
	local ModifierFlags = ExtractModifierFlags(Tail)

	Entry.Properties[PropertyName] = {
		Name = PropertyName,
		Type = TypeName,
		Raw = Tail,
		ModifierFlags = ModifierFlags,
		TagFlags = ExtractTagFlags(Tail),
	}
	PropertyCount += 1
end

local function SplitTopLevelComma(Value)
	local Parts = {}
	local Chunks = {}
	local DepthParen = 0
	local DepthBracket = 0
	local DepthBrace = 0
	local DepthAngle = 0

	for I = 1, #Value do
		local Ch = string.sub(Value, I, I)

		if Ch == "," and DepthParen == 0 and DepthBracket == 0 and DepthBrace == 0 and DepthAngle == 0 then
			local Token = Trim(table.concat(Chunks))
			if Token ~= "" then
				Parts[#Parts + 1] = Token
			end
			table.clear(Chunks)
		else
			Chunks[#Chunks + 1] = Ch

			if Ch == "(" then DepthParen += 1 end
			if Ch == ")" then DepthParen = math.max(0, DepthParen - 1) end
			if Ch == "[" then DepthBracket += 1 end
			if Ch == "]" then DepthBracket = math.max(0, DepthBracket - 1) end
			if Ch == "{" then DepthBrace += 1 end
			if Ch == "}" then DepthBrace = math.max(0, DepthBrace - 1) end
			if Ch == "<" then DepthAngle += 1 end
			if Ch == ">" then DepthAngle = math.max(0, DepthAngle - 1) end
		end
	end

	local Tail = Trim(table.concat(Chunks))
	if Tail ~= "" then
		Parts[#Parts + 1] = Tail
	end

	return Parts
end

local function ParseArgumentList(Arguments)
	local List = {}
	local RequiredCount = 0
	local HasVariadic = false
	local RawArgs = Trim(Arguments or "")

	if RawArgs == "" then
		return List, RequiredCount, HasVariadic
	end

	local Parts = SplitTopLevelComma(RawArgs)
	for _, RawPart in ipairs(Parts) do
		local Part = Trim(RawPart)
		if Part == "" then
			continue
		end

		local Optional = false
		local Variadic = false
		local Name = nil
		local TypeName = nil

		local BeforeDefault = string.match(Part, "^(.-)%s*=")
		if BeforeDefault ~= nil then
			Part = Trim(BeforeDefault)
			Optional = true
		end

		if string.sub(Part, 1, 3) == "..." then
			Variadic = true
			local VarType = string.match(Part, "^%.%.%.%s*:%s*(.+)$")
			TypeName = Trim(VarType or "any")
			Name = "..."
		else
			local ArgName, ArgType = string.match(Part, "^([%w_%.]+)%s*:%s*(.+)$")
			if ArgName ~= nil then
				Name = Trim(ArgName)
				TypeName = Trim(ArgType)
			else
				Name = Part
				TypeName = "any"
			end
		end

		if TypeName == nil or TypeName == "" then
			TypeName = "any"
		end

		if string.sub(TypeName, 1, 3) == "..." then
			Variadic = true
			TypeName = Trim(string.sub(TypeName, 4))
			if TypeName == "" then
				TypeName = "any"
			end
		end

		if string.sub(TypeName, -1) == "?" then
			Optional = true
		end

		if Name and string.sub(Name, -1) == "?" then
			Optional = true
			Name = string.sub(Name, 1, #Name - 1)
		end

		if Variadic then
			HasVariadic = true
			Optional = true
		end

		List[#List + 1] = {
			Name = Name or "",
			Type = StripTrailingMetadata(TypeName),
			Optional = Optional,
			Variadic = Variadic,
			Raw = RawPart,
		}

		if not Optional and not Variadic then
			RequiredCount += 1
		end
	end

	return List, RequiredCount, HasVariadic
end

local function ParseFunction(Line)
	local ClassName, MethodName, Arguments, ReturnType = string.match(Line, "^Function%s+([%w_]+):([%w_]+)%((.*)%)%s*%-%>%s*(.+)$")
	local IsVoid = false

	if ClassName == nil then
		ClassName, MethodName, Arguments = string.match(Line, "^Function%s+([%w_]+):([%w_]+)%((.*)%)%s*$")
		ReturnType = "void"
		IsVoid = true
	end

	if not ClassName then
		return
	end

	local Entry = EnsureClass(ClassName)
	local ParsedArguments, RequiredArgumentCount, HasVariadicArguments = ParseArgumentList(Arguments)

	local Descriptor = {
		Name = MethodName,
		Arguments = Trim(Arguments or ""),
		ParsedArguments = ParsedArguments,
		RequiredArgumentCount = RequiredArgumentCount,
		HasVariadicArguments = HasVariadicArguments,
		ReturnType = StripTrailingMetadata(ReturnType or "void"),
		IsVoid = IsVoid,
		Raw = Line,
		ModifierFlags = ExtractModifierFlags(Line),
		TagFlags = ExtractTagFlags(Line),
	}

	local Overloads = Entry.FunctionOverloads[MethodName]
	if Overloads == nil then
		Overloads = {}
		Entry.FunctionOverloads[MethodName] = Overloads
	end
	table.insert(Overloads, Descriptor)

	if Entry.Functions[MethodName] == nil then
		Entry.Functions[MethodName] = Descriptor
	end

	if GlobalFunctionByName[MethodName] == nil then
		GlobalFunctionByName[MethodName] = Descriptor
	end

	local GlobalOverloads = GlobalFunctionOverloadsByName[MethodName]
	if GlobalOverloads == nil then
		GlobalOverloads = {}
		GlobalFunctionOverloadsByName[MethodName] = GlobalOverloads
	end
	table.insert(GlobalOverloads, Descriptor)

	FunctionCount += 1
end

local function ParseEvent(Line)
	local ClassName, EventName, Arguments = string.match(Line, "^Event%s+([%w_]+)%.([%w_]+)%((.*)%)")
	if not ClassName then
		return
	end

	local Entry = EnsureClass(ClassName)
	Entry.Events[EventName] = {
		Name = EventName,
		Arguments = Trim(Arguments or ""),
		Raw = Line,
		ModifierFlags = ExtractModifierFlags(Line),
		TagFlags = ExtractTagFlags(Line),
	}
	EventCount += 1
end

local function ParseCallback(Line)
	local ClassName, CallbackName, Arguments, ReturnType = string.match(Line, "^Callback%s+([%w_]+)%.([%w_]+)%((.*)%)%s*%-%>%s*(.+)$")
	if not ClassName then
		return
	end

	local Entry = EnsureClass(ClassName)
	local ParsedArguments, RequiredArgumentCount, HasVariadicArguments = ParseArgumentList(Arguments)
	local Descriptor = {
		Name = CallbackName,
		Arguments = Trim(Arguments or ""),
		ParsedArguments = ParsedArguments,
		RequiredArgumentCount = RequiredArgumentCount,
		HasVariadicArguments = HasVariadicArguments,
		ReturnType = StripTrailingMetadata(ReturnType or "void"),
		Raw = Line,
		ModifierFlags = ExtractModifierFlags(Line),
		TagFlags = ExtractTagFlags(Line),
	}

	local Overloads = Entry.CallbackOverloads[CallbackName]
	if Overloads == nil then
		Overloads = {}
		Entry.CallbackOverloads[CallbackName] = Overloads
	end
	table.insert(Overloads, Descriptor)

	if Entry.Callbacks[CallbackName] == nil then
		Entry.Callbacks[CallbackName] = Descriptor
	end
	CallbackCount += 1
end

local function ParseEnum(Line)
	local EnumName = string.match(Line, "^Enum%s+([%w_]+)")
	if not EnumName then
		return
	end

	if Enums[EnumName] ~= nil then
		return
	end

	Enums[EnumName] = {}
	EnumOrder[EnumName] = {}
	EnumCount += 1
end

local function ParseEnumItem(Line)
	local EnumName, ItemName, ItemValue = string.match(Line, "^EnumItem%s+([%w_]+)%.([%w_]+)%s*:%s*([%-]?%d+)")
	if not EnumName then
		return
	end

	if Enums[EnumName] == nil then
		Enums[EnumName] = {}
		EnumOrder[EnumName] = {}
		EnumCount += 1
	end

	if Enums[EnumName][ItemName] == nil then
		table.insert(EnumOrder[EnumName], ItemName)
	end

	Enums[EnumName][ItemName] = tonumber(ItemValue) or 0
	EnumItemCount += 1
end

local function ParseLine(Line)
	local Trimmed = Trim(Line)
	if Trimmed == "" then
		return
	end

	if string.sub(Trimmed, 1, 6) == "Class " then
		ParseClass(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 9) == "Property " then
		ParseProperty(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 9) == "Function " then
		ParseFunction(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 6) == "Event " then
		ParseEvent(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 9) == "Callback " then
		ParseCallback(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 5) == "Enum " then
		ParseEnum(Trimmed)
		return
	end

	if string.sub(Trimmed, 1, 9) == "EnumItem " then
		ParseEnumItem(Trimmed)
		return
	end
end

local function EnsureLoaded()
	if Loaded and LoadError == nil then
		return
	end

	table.clear(Classes)
	table.clear(Enums)
	table.clear(EnumOrder)
	table.clear(GlobalFunctionByName)
	table.clear(GlobalFunctionOverloadsByName)

	ClassCount = 0
	PropertyCount = 0
	FunctionCount = 0
	EventCount = 0
	CallbackCount = 0
	EnumCount = 0
	EnumItemCount = 0

	Loaded = true
	LoadError = nil

	local Dump = nil
	for _, CandidatePath in ipairs(DumpCandidatePaths) do
		local Ok, ReadResult = pcall(fs.readFile, CandidatePath)
		if Ok and typeof(ReadResult) == "string" then
			Dump = ReadResult
			DumpPath = CandidatePath
			break
		end
	end

	if typeof(Dump) ~= "string" then
		LoadError = "failed_to_read_dump"
		return
	end

	for Line in string.gmatch(Dump, "[^\r\n]+") do
		ParseLine(Line)
	end
end

local function WalkInheritance(ClassName, Visitor)
	local Current = ClassName
	local Visited = {}

	while Current ~= nil and Current ~= "" and not Visited[Current] do
		Visited[Current] = true
		local Entry = Classes[Current]
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

function ApiDumpIndex.GetStats()
	EnsureLoaded()
	return {
		Loaded = Loaded and LoadError == nil,
		LoadError = LoadError,
		ClassCount = ClassCount,
		PropertyCount = PropertyCount,
		FunctionCount = FunctionCount,
		EventCount = EventCount,
		CallbackCount = CallbackCount,
		EnumCount = EnumCount,
		EnumItemCount = EnumItemCount,
	}
end

function ApiDumpIndex.HasClass(ClassName)
	EnsureLoaded()
	return Classes[ClassName] ~= nil
end

function ApiDumpIndex.GetClass(ClassName)
	EnsureLoaded()
	return Classes[ClassName]
end

function ApiDumpIndex.ClassHasModifier(ClassName, ModifierName)
	if typeof(ModifierName) ~= "string" or ModifierName == "" then
		return false
	end

	EnsureLoaded()
	local Entry = Classes[ClassName]
	if not Entry or typeof(Entry.ModifierFlags) ~= "table" then
		return false
	end

	return Entry.ModifierFlags[ModifierName] == true
end

function ApiDumpIndex.ClassHasTag(ClassName, TagName)
	if typeof(TagName) ~= "string" or TagName == "" then
		return false
	end

	EnsureLoaded()
	local Entry = Classes[ClassName]
	if not Entry or typeof(Entry.TagFlags) ~= "table" then
		return false
	end

	return Entry.TagFlags[TagName] == true
end

function ApiDumpIndex.IsA(ClassName, TargetClass)
	if typeof(ClassName) ~= "string" or typeof(TargetClass) ~= "string" then
		return false
	end

	if ClassName == TargetClass then
		return true
	end

	EnsureLoaded()

	return WalkInheritance(ClassName, function(Entry)
		return Entry.Name == TargetClass, Entry.Name == TargetClass
	end) == true
end

function ApiDumpIndex.GetPropertyDescriptor(ClassName, PropertyName)
	EnsureLoaded()
	return WalkInheritance(ClassName, function(Entry)
		local Property = Entry.Properties[PropertyName]
		if Property ~= nil then
			return true, Property
		end
		return false, nil
	end)
end

function ApiDumpIndex.HasProperty(ClassName, PropertyName)
	return ApiDumpIndex.GetPropertyDescriptor(ClassName, PropertyName) ~= nil
end

function ApiDumpIndex.PropertyHasModifier(ClassName, PropertyName, ModifierName)
	if typeof(ModifierName) ~= "string" or ModifierName == "" then
		return false
	end

	local Descriptor = ApiDumpIndex.GetPropertyDescriptor(ClassName, PropertyName)
	if not Descriptor or typeof(Descriptor.ModifierFlags) ~= "table" then
		return false
	end

	return Descriptor.ModifierFlags[ModifierName] == true
end

function ApiDumpIndex.PropertyHasTag(ClassName, PropertyName, TagName)
	if typeof(TagName) ~= "string" or TagName == "" then
		return false
	end

	local Descriptor = ApiDumpIndex.GetPropertyDescriptor(ClassName, PropertyName)
	if not Descriptor or typeof(Descriptor.TagFlags) ~= "table" then
		return false
	end

	return Descriptor.TagFlags[TagName] == true
end

function ApiDumpIndex.GetFunctionDescriptor(ClassName, MethodName)
	EnsureLoaded()
	return WalkInheritance(ClassName, function(Entry)
		local Method = Entry.Functions[MethodName]
		if Method ~= nil then
			return true, Method
		end

		local Callback = Entry.Callbacks[MethodName]
		if Callback ~= nil then
			return true, Callback
		end

		return false, nil
	end)
end

function ApiDumpIndex.GetCallbackDescriptor(ClassName, CallbackName)
	EnsureLoaded()
	return WalkInheritance(ClassName, function(Entry)
		local Callback = Entry.Callbacks[CallbackName]
		if Callback ~= nil then
			return true, Callback
		end
		return false, nil
	end)
end

function ApiDumpIndex.GetFunctionOverloads(ClassName, MethodName)
	EnsureLoaded()
	return WalkInheritance(ClassName, function(Entry)
		local Methods = Entry.FunctionOverloads[MethodName]
		if Methods ~= nil and #Methods > 0 then
			return true, Methods
		end

		local Callbacks = Entry.CallbackOverloads[MethodName]
		if Callbacks ~= nil and #Callbacks > 0 then
			return true, Callbacks
		end

		local Method = Entry.Functions[MethodName]
		if Method ~= nil then
			return true, { Method }
		end

		local Callback = Entry.Callbacks[MethodName]
		if Callback ~= nil then
			return true, { Callback }
		end

		return false, nil
	end)
end

function ApiDumpIndex.HasFunction(ClassName, MethodName)
	return ApiDumpIndex.GetFunctionDescriptor(ClassName, MethodName) ~= nil
end

function ApiDumpIndex.HasCallback(ClassName, CallbackName)
	return ApiDumpIndex.GetCallbackDescriptor(ClassName, CallbackName) ~= nil
end

function ApiDumpIndex.GetAnyFunctionDescriptor(MethodName)
	EnsureLoaded()
	return GlobalFunctionByName[MethodName]
end

function ApiDumpIndex.GetAnyFunctionOverloads(MethodName)
	EnsureLoaded()
	local Overloads = GlobalFunctionOverloadsByName[MethodName]
	if Overloads ~= nil and #Overloads > 0 then
		return Overloads
	end

	local Descriptor = GlobalFunctionByName[MethodName]
	if Descriptor ~= nil then
		return { Descriptor }
	end

	return nil
end

function ApiDumpIndex.HasAnyFunction(MethodName)
	return ApiDumpIndex.GetAnyFunctionDescriptor(MethodName) ~= nil
end

function ApiDumpIndex.GetEventDescriptor(ClassName, EventName)
	EnsureLoaded()
	return WalkInheritance(ClassName, function(Entry)
		local Event = Entry.Events[EventName]
		if Event ~= nil then
			return true, Event
		end
		return false, nil
	end)
end

function ApiDumpIndex.HasEvent(ClassName, EventName)
	return ApiDumpIndex.GetEventDescriptor(ClassName, EventName) ~= nil
end

function ApiDumpIndex.EnumExists(EnumName)
	EnsureLoaded()
	return Enums[EnumName] ~= nil
end

function ApiDumpIndex.GetFirstEnumItem(EnumName)
	EnsureLoaded()
	local Order = EnumOrder[EnumName]
	if not Order or #Order == 0 then
		return nil
	end
	return Order[1]
end

function ApiDumpIndex.GetEnumValue(EnumName, ItemName)
	EnsureLoaded()
	local EnumData = Enums[EnumName]
	if not EnumData then
		return nil
	end
	return EnumData[ItemName]
end

function ApiDumpIndex.IsServiceClass(ClassName)
	if typeof(ClassName) ~= "string" or ClassName == "" then
		return false
	end

	if WellKnownServiceClasses[ClassName] then
		return true
	end

	if string.match(ClassName, "Service$") then
		return true
	end

	EnsureLoaded()
	local Entry = Classes[ClassName]
	if not Entry then
		return false
	end

	if string.find(Entry.Modifiers, "Service", 1, true) then
		return true
	end

	return false
end

function ApiDumpIndex.IsClassCreatable(ClassName)
	if typeof(ClassName) ~= "string" or ClassName == "" then
		return false
	end

	if not ApiDumpIndex.HasClass(ClassName) then
		local Stats = ApiDumpIndex.GetStats()
		if Stats.Loaded then
			return false
		end
		return true
	end

	if ApiDumpIndex.ClassHasModifier(ClassName, "NotCreatable") then
		return false
	end

	if ApiDumpIndex.IsServiceClass(ClassName) then
		return false
	end

	return true
end

function ApiDumpIndex.IsPropertyReadOnly(ClassName, PropertyName)
	if ApiDumpIndex.PropertyHasModifier(ClassName, PropertyName, "ReadOnly") then
		return true
	end

	if ApiDumpIndex.PropertyHasModifier(ClassName, PropertyName, "ReadSafe") then
		return true
	end

	return false
end

function ApiDumpIndex.GetServiceLikeClasses()
	EnsureLoaded()

	local Out = {}
	for ClassName in next, Classes do
		if ApiDumpIndex.IsServiceClass(ClassName) then
			Out[#Out + 1] = ClassName
		end
	end

	table.sort(Out)
	return Out
end

function ApiDumpIndex.GetSnapshot()
	EnsureLoaded()
	if LoadError ~= nil then
		return nil, LoadError
	end

	return {
		Classes = Classes,
		Enums = Enums,
		EnumOrder = EnumOrder,
		GlobalFunctionByName = GlobalFunctionByName,
		GlobalFunctionOverloadsByName = GlobalFunctionOverloadsByName,
		Stats = ApiDumpIndex.GetStats(),
	}
end

return ApiDumpIndex