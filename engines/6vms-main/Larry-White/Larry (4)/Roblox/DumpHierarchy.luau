local fs = require("@lune/fs")

local HTTP = require("../IO/HTTP")
local Enums = require("./Enums")
local DataTypes = require("./DataTypes")

local DumpHierarchy = {}

local Loaded = false
local LoadError = nil
local RootNode = nil
local TopLevelByName = {}
local SnapshotPath = nil
local CachePrefix = nil

local CandidatePaths = {
	"Data/roblox.json",
	"./Data/roblox.json",
	"Data/fullhierachy.json",
	"Data/fullhierarchy.json",
	"./Data/fullhierachy.json",
	"./Data/fullhierarchy.json",
}

local function sanitizeName(Value)
	local Name = string.lower(tostring(Value or "node"))
	Name = string.gsub(Name, "[^%w_]+", "_")
	if Name == "" then
		Name = "node"
	end
	return Name
end

local function readFirstExistingPath()
	for _, Path in ipairs(CandidatePaths) do
		local OkExists, Exists = pcall(fs.isFile, Path)
		if OkExists and Exists then
			return Path
		end
	end
	return nil
end

local function readJsonFile(Path)
	local OkRead, Contents = pcall(fs.readFile, Path)
	if not OkRead or typeof(Contents) ~= "string" or Contents == "" then
		return nil
	end

	local Parsed = HTTP.JSONDecode(Contents)
	if typeof(Parsed) ~= "table" then
		return nil
	end

	return Parsed
end

local function getCacheIndexPath()
	return `Data/.larry_hierarchy_index_{CachePrefix}.json`
end

local function getCacheNodePath(Name)
	local SafeName = sanitizeName(Name)
	return `Data/.larry_hierarchy_node_{CachePrefix}_{SafeName}.json`
end

local function writeJsonFile(Path, Value)
	local Encoded = HTTP.JSONEncode(Value)
	if typeof(Encoded) ~= "string" or Encoded == "" then
		return false
	end
	return pcall(fs.writeFile, Path, Encoded)
end

local function loadCacheIndex()
	local IndexPath = getCacheIndexPath()
	local Parsed = readJsonFile(IndexPath)
	if typeof(Parsed) ~= "table" then
		return "missing"
	end
	if Parsed.Version ~= 1 then
		return "missing"
	end
	if Parsed.SnapshotPath ~= SnapshotPath then
		return "missing"
	end
	if Parsed.Unsupported == true then
		LoadError = Parsed.Reason or "hierarchy snapshot unsupported format"
		return "unsupported"
	end

	local Services = Parsed.Services
	if typeof(Services) ~= "table" then
		return "missing"
	end

	table.clear(TopLevelByName)
	for Name, Path in next, Services do
		if typeof(Name) == "string" and typeof(Path) == "string" and Path ~= "" then
			TopLevelByName[Name] = Path
		end
	end
	if next(TopLevelByName) ~= nil then
		return "ready"
	end
	return "missing"
end

local function writeUnsupportedCache(Reason)
	local IndexValue = {
		Version = 1,
		SnapshotPath = SnapshotPath,
		Unsupported = true,
		Reason = Reason,
	}
	writeJsonFile(getCacheIndexPath(), IndexValue)
end

local function buildCacheFromSnapshot()
	local Snapshot = readJsonFile(SnapshotPath)
	if typeof(Snapshot) ~= "table" then
		LoadError = "failed to decode hierarchy snapshot"
		return false
	end

	local Children = Snapshot.Children
	if typeof(Children) ~= "table" then
		LoadError = "hierarchy snapshot missing root Children"
		writeUnsupportedCache(LoadError)
		return false
	end

	table.clear(TopLevelByName)
	local ServicePaths = {}

	for _, Child in ipairs(Children) do
		if typeof(Child) == "table" and typeof(Child.Name) == "string" and Child.Name ~= "" then
			local NodePath = getCacheNodePath(Child.Name)
			local OkWrite = writeJsonFile(NodePath, Child)
			if OkWrite then
				TopLevelByName[Child.Name] = NodePath
				ServicePaths[Child.Name] = NodePath
			else
				TopLevelByName[Child.Name] = Child
			end
		end
	end

	local IndexValue = {
		Version = 1,
		SnapshotPath = SnapshotPath,
		Services = ServicePaths,
	}
	writeJsonFile(getCacheIndexPath(), IndexValue)

	return next(TopLevelByName) ~= nil
end

local function ensureLoaded()
	if Loaded then
		return RootNode
	end

	Loaded = true
	SnapshotPath = readFirstExistingPath()
	if typeof(SnapshotPath) ~= "string" then
		LoadError = "missing hierarchy snapshot"
		return nil
	end

	CachePrefix = sanitizeName(SnapshotPath)
	RootNode = {
		Name = "Game",
		ClassName = "DataModel",
		Children = {},
	}

	local CacheState = loadCacheIndex()
	if CacheState == "ready" then
		return RootNode
	end
	if CacheState == "unsupported" then
		return nil
	end

	if buildCacheFromSnapshot() then
		return RootNode
	end

	return nil
end

local function tryEnum(Value)
	if typeof(Value) ~= "string" then
		return nil
	end

	local EnumName, ItemName = string.match(Value, "^Enum%.([%w_]+)%.([%w_]+)$")
	if EnumName == nil then
		return nil
	end

	return Enums.Get(EnumName, ItemName)
end

local function makeVector3(X, Y, Z)
	local Vector3 = DataTypes.Get("Vector3")
	if typeof(Vector3) == "table" and typeof(Vector3.new) == "function" then
		local Ok, Value = pcall(Vector3.new, X, Y, Z)
		if Ok and Value ~= nil then
			return Value
		end
	end

	return {
		X = X,
		Y = Y,
		Z = Z,
		__larryType = "Vector3",
	}
end

local function makeCFrame(Values)
	local CFrameLib = DataTypes.Get("CFrame")
	if typeof(CFrameLib) == "table" and typeof(CFrameLib.new) == "function" then
		local Ok, Value = pcall(CFrameLib.new, table.unpack(Values, 1, #Values))
		if Ok and Value ~= nil then
			return Value
		end
	end

	local X = Values[1] or 0
	local Y = Values[2] or 0
	local Z = Values[3] or 0
	return {
		X = X,
		Y = Y,
		Z = Z,
		Position = makeVector3(X, Y, Z),
		RightVector = makeVector3(1, 0, 0),
		UpVector = makeVector3(0, 1, 0),
		LookVector = makeVector3(0, 0, -1),
		__larryType = "CFrame",
	}
end

local function parseCommaNumbers(Value)
	if typeof(Value) ~= "string" or not string.find(Value, ",", 1, true) then
		return nil
	end

	local Out = {}
	for Part in string.gmatch(Value, "([^,]+)") do
		local Num = tonumber((string.gsub(Part, "^%s*(.-)%s*$", "%1")))
		if Num == nil then
			return nil
		end
		Out[#Out + 1] = Num
	end
	return #Out > 0 and Out or nil
end

local function coerceValue(PropertyName, Value)
	local EnumItem = tryEnum(Value)
	if EnumItem ~= nil then
		return EnumItem
	end

	local Numbers = parseCommaNumbers(Value)
	if Numbers ~= nil then
		if #Numbers == 12 then
			return makeCFrame(Numbers)
		end
		if #Numbers == 3 then
			return makeVector3(Numbers[1], Numbers[2], Numbers[3])
		end
	end

	if PropertyName == "Archivable" and typeof(Value) ~= "boolean" then
		return Value == true
	end

	if Value == "None" and (PropertyName == "PrimaryPart" or PropertyName == "Team") then
		return nil
	end

	return Value
end

local function findExistingChildRaw(Parent, Name, ClassName)
	if typeof(Parent) ~= "table" then
		return nil
	end

	for _, Child in ipairs(rawget(Parent, "_Children") or {}) do
		if rawget(Child, "_Name") == Name then
			if ClassName == nil or rawget(Child, "_ClassName") == ClassName then
				return Child
			end
		end
	end

	return nil
end

local function applyProperties(Inst, Node)
	local Props = typeof(Node) == "table" and rawget(Node, "Properties") or nil
	if typeof(Props) ~= "table" then
		return
	end

	for PropertyName, PropertyValue in next, Props do
		if typeof(PropertyName) == "string" then
			local Coerced = coerceValue(PropertyName, PropertyValue)
			if Coerced ~= nil then
				Inst:SetProperty(PropertyName, Coerced)
			end
		end
	end

	if rawget(Inst, "_ClassName") == "ModuleScript" and Inst:GetRawProperty("Source") == nil then
		Inst:SetProperty("Source", "return {}")
	end
end

local function attachNode(Node, Inst, Runtime)
	if typeof(Node) ~= "table" or typeof(Inst) ~= "table" then
		return Inst
	end

	if typeof(Node.Name) == "string" and Node.Name ~= "" then
		rawset(Inst, "_Name", Node.Name)
	end

	rawset(Inst, "_LarryDumpNode", Node)
	rawset(Inst, "_LarryDumpPath", Node.FullName)
	applyProperties(Inst, Node)

	local Children = rawget(Node, "Children")
	if typeof(Children) == "table" and next(Children) ~= nil then
		rawset(Inst, "_LarryMaterializeChildren", function(Target)
			for _, ChildNode in ipairs(Children) do
				if typeof(ChildNode) ~= "table" then
					continue
				end

				local ChildName = ChildNode.Name or ChildNode.ClassName or "Instance"
				local ChildClassName = ChildNode.ClassName or "Folder"
				local Child = findExistingChildRaw(Target, ChildName, ChildClassName)
				if Child == nil then
					Child = Runtime.Instance._new(
						ChildClassName,
						{},
						Runtime.Proxy,
						Runtime.State,
						Runtime.Emitter,
						Runtime.Beautifier,
						Runtime.Scope,
						true
					)
					rawset(Child, "_Name", ChildName)
					Child:SetParent(Target)
				end
				attachNode(ChildNode, Child, Runtime)
			end
		end)
	end

	return Inst
end

local function resolveTopLevelEntry(Name)
	local Entry = TopLevelByName[Name]
	if typeof(Entry) == "table" then
		return Entry
	end
	if typeof(Entry) ~= "string" then
		return nil
	end

	local Parsed = readJsonFile(Entry)
	if typeof(Parsed) ~= "table" then
		return nil
	end
	TopLevelByName[Name] = Parsed
	return Parsed
end

function DumpHierarchy.GetRootNode()
	return ensureLoaded()
end

function DumpHierarchy.GetTopLevelNode(Name)
	ensureLoaded()
	if typeof(Name) ~= "string" or Name == "" then
		return nil
	end
	return resolveTopLevelEntry(Name)
end

function DumpHierarchy.GetTopLevelNodes()
	ensureLoaded()
	local Out = {}
	for Name in next, TopLevelByName do
		local Node = resolveTopLevelEntry(Name)
		if typeof(Node) == "table" then
			Out[#Out + 1] = Node
		end
	end
	return Out
end

function DumpHierarchy.FindNodeChild(Node, Name, ClassName)
	if typeof(Node) ~= "table" or typeof(Name) ~= "string" then
		return nil
	end

	for _, Child in ipairs(Node.Children or {}) do
		if typeof(Child) == "table" and Child.Name == Name then
			if ClassName == nil or Child.ClassName == ClassName then
				return Child
			end
		end
	end

	return nil
end

function DumpHierarchy.FindFirstChildByClass(Node, ClassName)
	if typeof(Node) ~= "table" or typeof(ClassName) ~= "string" then
		return nil
	end

	for _, Child in ipairs(Node.Children or {}) do
		if typeof(Child) == "table" and Child.ClassName == ClassName then
			return Child
		end
	end

	return nil
end

function DumpHierarchy.AttachNode(Node, Inst, Runtime)
	return attachNode(Node, Inst, Runtime)
end

function DumpHierarchy.IsAvailable()
	return ensureLoaded() ~= nil
end

function DumpHierarchy.GetLoadError()
	ensureLoaded()
	return LoadError
end

return DumpHierarchy