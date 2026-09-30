local StringUtil = require("../Utils/String")
local ExecEnv = require("../Data/ExecEnv")
local Constants = require("../Data/Constants")

local Renamer = {}

function Renamer.new(State, Config)
	local Self = setmetatable({}, { __index = Renamer })
	Self.State = State
	Self.Config = Config
	Self.Replace = {}
	Self.NameCounters = {}
	return Self
end

function Renamer:GetCounter(Name)
	local Count = self.NameCounters[Name] or 0
	Count += 1
	self.NameCounters[Name] = Count
	return Count == 1 and "" or Count
end

function Renamer:GetName(Var, Value, Side2, Old)
	local VarId = string.match(Var, "%d+") or ""
	local Name
	local IsNamecall = string.find(Side2, ":") and Value.Tag == "__call"

	local CompMap = {
		["<"] = "is_less",
		[">"] = "is_greater",
		["<="] = "less_equal",
		[">="] = "greater_equal",
	}

	if IsNamecall then
		local Calls = string.split(Side2, ":")
		local Args = StringUtil.DecodeArgs(string.match(Side2, "%((.-)%)") or "")

		Name = string.split(Calls[#Calls], "(")[1]

		local ServiceMethods = { "FindFirstChild", "WaitForChild", "FindFirstChildOfClass", "GetService" }

		if table.find(ServiceMethods, Name) and Args[1] then
			Name = tostring(Args[1]) .. VarId
		end

		Name = string.gsub(Name, StringUtil.CaseInsensitive("Get"), "")
		Name = string.gsub(Name, StringUtil.CaseInsensitive("Make"), "")
		Name = string.gsub(Name, StringUtil.CaseInsensitive("Create"), "")
		Name = string.gsub(Name, StringUtil.CaseInsensitive("Decode"), "%1ecoded")
		Name = string.gsub(Name, StringUtil.CaseInsensitive("Encode"), "%1ncoded")
	elseif Value.Tag == "__index" then
		local Indexes = StringUtil.SplitPath(Value.Value)
		Name = Indexes[#Indexes]
	elseif Value.Tag == "__comp" then
		local Symbol = string.match(Side2, "[<>]=?")
		local Keyword = string.match(Side2, "%w+")
		Name = CompMap[Symbol or Keyword] or "unknown"
	elseif Value.Tag == "__len" then
		Name = "len"
	elseif Value.Tag == "__eq" then
		local EqType = string.match(Value.Value, "[~=]=")
		Name = EqType == "~=" and "not_equal" or "is_equal"
	elseif Value.Tag == "__call" then
		local Resolved = Value.Value
		local OldResolved = Resolved
		local DidChange = true

		while DidChange do
			for Var2, Val2 in next, self.State.Values do
				local V = Val2.Value
				if not V or Val2.Usage > 1 or Var2 == Var then continue end
				Resolved = string.gsub(Resolved, "%f[%w_]" .. Var2 .. "%f[^%w_]", StringUtil.PatternSafe(V))
			end
			DidChange = Resolved ~= OldResolved
			OldResolved = Resolved
		end

		local Path = string.split(Resolved, "(")[1]
		local Indexes = string.split(Path, ".")
		local First = Indexes[1]
		local Args = StringUtil.DecodeArgs(string.match(Side2, "%((.-)%)") or "")

		if Path == "Instance.new" and Args[1] then
			Name = tostring(Args[1])
		elseif First == "Vector3" or First == "Vector2" or First == "CFrame" then
			local Prefix = string.sub(First, 1, First == "CFrame" and 3 or 2) .. string.sub(First, #First) .. "_"
			Name = Prefix .. (Indexes[2] or "new")
		else
			Name = string.gsub(Path, "%W", "") .. "_call"
		end
	end

	if Name then
		Name = ExecEnv.Deglobal(Name .. self:GetCounter(Name))
	end

	local IsValid = Name
		and not string.match(Name, "[^A-Za-z0-9_]")
		and Name ~= ""
		and not tonumber(string.sub(Name, 1, 1))
		and not Constants.IsKeyword(Name)

	if IsValid then
		self.Replace[Var] = Name
		return `local {Name} ={Side2}`
	end

	return Old
end

function Renamer:ApplyToSource(Source)
	local Old = Source
	local Changed = true

	while Changed do
		for Var, Name in next, self.Replace do
			Source = string.gsub(Source, "%f[%w_]" .. Var .. "%f[^%w_]", StringUtil.PatternSafe(Name))
		end

		Changed = Source ~= Old
		Old = Source
	end

	return Source
end

function Renamer:SmartName(Path, Value)
	if not Path then return nil end

	local Parts = StringUtil.SplitPath(Path)
	local Last = Parts[#Parts]

	if not Last or Last == "" then return nil end
	if Constants.IsKeyword(Last) then return nil end
	if StringUtil.IsWeird(Last) then return nil end

	return Last
end

return Renamer