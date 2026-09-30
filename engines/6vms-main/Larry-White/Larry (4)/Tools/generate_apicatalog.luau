local fs = require("@lune/fs")

local ApiDumpIndex = require("../Roblox/ApiDumpIndex")

local function sortKeys(Map)
	local Keys = {}
	for Key in next, Map do
		Keys[#Keys + 1] = Key
	end
	table.sort(Keys)
	return Keys
end

local function isArray(Value)
	if typeof(Value) ~= "table" then
		return false, 0
	end

	local Count = 0
	local MaxIndex = 0
	for Key in next, Value do
		if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
			return false, 0
		end
		Count += 1
		if Key > MaxIndex then
			MaxIndex = Key
		end
	end

	if Count ~= MaxIndex then
		return false, 0
	end

	return true, MaxIndex
end

local function indent(Level)
	return string.rep("\t", Level)
end

local function serialize(Value, Level)
	Level = Level or 0
	local ValueType = typeof(Value)

	if ValueType == "nil" then
		return "nil"
	end

	if ValueType == "boolean" then
		return Value and "true" or "false"
	end

	if ValueType == "number" then
		if Value ~= Value then
			return "0/0"
		end
		if Value == math.huge then
			return "math.huge"
		end
		if Value == -math.huge then
			return "-math.huge"
		end
		return tostring(Value)
	end

	if ValueType == "string" then
		return string.format("%q", Value)
	end

	if ValueType ~= "table" then
		return "nil"
	end

	local Array, Length = isArray(Value)
	if Array then
		if Length == 0 then
			return "{}"
		end

		local Parts = { "{\n" }
		for Index = 1, Length do
			Parts[#Parts + 1] = indent(Level + 1)
			Parts[#Parts + 1] = serialize(Value[Index], Level + 1)
			Parts[#Parts + 1] = ",\n"
		end
		Parts[#Parts + 1] = indent(Level)
		Parts[#Parts + 1] = "}"
		return table.concat(Parts)
	end

	local Keys = sortKeys(Value)
	if #Keys == 0 then
		return "{}"
	end

	local Parts = { "{\n" }
	for _, Key in ipairs(Keys) do
		local KeyOut
		if typeof(Key) == "string" and string.match(Key, "^[%a_][%w_]*$") then
			KeyOut = Key
		else
			KeyOut = "[" .. serialize(Key, Level + 1) .. "]"
		end

		Parts[#Parts + 1] = indent(Level + 1)
		Parts[#Parts + 1] = KeyOut
		Parts[#Parts + 1] = " = "
		Parts[#Parts + 1] = serialize(Value[Key], Level + 1)
		Parts[#Parts + 1] = ",\n"
	end
	Parts[#Parts + 1] = indent(Level)
	Parts[#Parts + 1] = "}"

	return table.concat(Parts)
end

local function writeModule(Path, Value)
	local Source = "return " .. serialize(Value, 0) .. "\n"
	fs.writeFile(Path, Source)
end

local function chunkItems(Names, ChunkSize)
	local Chunks = {}
	local Current = {}
	for _, Name in ipairs(Names) do
		Current[#Current + 1] = Name
		if #Current >= ChunkSize then
			Chunks[#Chunks + 1] = Current
			Current = {}
		end
	end
	if #Current > 0 then
		Chunks[#Chunks + 1] = Current
	end
	return Chunks
end

local Snapshot, SnapshotError = ApiDumpIndex.GetSnapshot()
if Snapshot == nil then
	error("ApiDumpIndex snapshot failed: " .. tostring(SnapshotError))
end

local Classes = Snapshot.Classes
local Enums = Snapshot.Enums
local EnumOrder = Snapshot.EnumOrder
local GlobalByName = Snapshot.GlobalFunctionByName
local GlobalOverloadsByName = Snapshot.GlobalFunctionOverloadsByName

local ClassNames = sortKeys(Classes)
local EnumNames = sortKeys(Enums)
local GlobalNames = sortKeys(GlobalByName)

local ClassChunks = chunkItems(ClassNames, 12)
local EnumChunks = chunkItems(EnumNames, 80)
local GlobalChunks = chunkItems(GlobalNames, 120)

local Manifest = {
	Version = 1,
	GeneratedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	Stats = Snapshot.Stats,
	Classes = {},
	Enums = {},
	Globals = {},
	Shards = {},
}

for Index, Chunk in ipairs(ClassChunks) do
	local ShardName = string.format("classes_%03d", Index)
	local Data = {
		Classes = {},
	}

	for _, ClassName in ipairs(Chunk) do
		Data.Classes[ClassName] = Classes[ClassName]
		Manifest.Classes[ClassName] = ShardName
	end

	writeModule("Roblox/ApiCatalog/shards/" .. ShardName .. ".luau", Data)
	Manifest.Shards[#Manifest.Shards + 1] = ShardName
end

for Index, Chunk in ipairs(EnumChunks) do
	local ShardName = string.format("enums_%03d", Index)
	local Data = {
		Enums = {},
		EnumOrder = {},
	}

	for _, EnumName in ipairs(Chunk) do
		Data.Enums[EnumName] = Enums[EnumName]
		Data.EnumOrder[EnumName] = EnumOrder[EnumName]
		Manifest.Enums[EnumName] = ShardName
	end

	writeModule("Roblox/ApiCatalog/shards/" .. ShardName .. ".luau", Data)
	Manifest.Shards[#Manifest.Shards + 1] = ShardName
end

for Index, Chunk in ipairs(GlobalChunks) do
	local ShardName = string.format("globals_%03d", Index)
	local Data = {
		GlobalFunctions = {},
		GlobalFunctionOverloads = {},
	}

	for _, Name in ipairs(Chunk) do
		Data.GlobalFunctions[Name] = GlobalByName[Name]
		Data.GlobalFunctionOverloads[Name] = GlobalOverloadsByName[Name]
		Manifest.Globals[Name] = ShardName
	end

	writeModule("Roblox/ApiCatalog/shards/" .. ShardName .. ".luau", Data)
	Manifest.Shards[#Manifest.Shards + 1] = ShardName
end

writeModule("Roblox/ApiCatalog/manifest.luau", Manifest)

print(string.format(
	"Generated ApiCatalog: %d class shards, %d enum shards, %d global shards",
	#ClassChunks,
	#EnumChunks,
	#GlobalChunks
))