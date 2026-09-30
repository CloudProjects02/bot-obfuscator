local StringUtil = require("../Utils/String")

local Collection = {}

local function LiteralKey(Value)
	local T = typeof(Value)
	if T == "string" then
		return `s:{Value}`
	end
	if T == "number" then
		return `n:{tostring(Value)}`
	end
	if T == "boolean" then
		return `b:{tostring(Value)}`
	end
	return nil
end

local function IsWordChar(Char)
	return Char ~= "" and string.match(Char, "[%w_]") ~= nil
end

local function IsDigit(Char)
	return Char ~= "" and string.match(Char, "%d") ~= nil
end

function Collection.new(State, Config)
	local Self = setmetatable({}, { __index = Collection })
	Self.State = State
	Self.Config = Config
	Self.Constants = {}
	Self.ConstantSet = {}
	Self.Tables = {}
	Self.MaxConstants = tonumber(Config.constant_limit) or 800
	return Self
end

function Collection:IsGarbage(Str)
	if typeof(Str) ~= "string" then return true end
	if #Str < 2 then return true end
	if #Str > 5000 then return true end

	if string.match(Str, "^%s*$") then
		return true
	end

	if #Str >= 24 and string.match(Str, "^[A-Za-z0-9+/]+=*$") then
		return true
	end

	if #Str >= 16 and string.match(Str, "^%x+$") then
		return true
	end

	local Printable = 0
	local Total = math.min(#Str, 200)

	for I = 1, Total do
		local B = string.byte(Str, I)
		if B >= 32 and B <= 126 then
			Printable += 1
		end
	end

	if Printable / Total < 0.6 then
		return true
	end

	return false
end

function Collection:AddLiteral(Value)
	local T = typeof(Value)
	if T == "string" then
		if self:IsGarbage(Value) then return end
	elseif T == "number" then
		if Value ~= Value or Value == math.huge or Value == -math.huge then return end
	elseif T == "boolean" then
	else
		return
	end

	if #self.Constants >= self.MaxConstants then
		return
	end

	local Key = LiteralKey(Value)
	if not Key or self.ConstantSet[Key] then
		return
	end

	self.ConstantSet[Key] = true
	table.insert(self.Constants, Value)
end

function Collection:ScanGc(GcItems)
	for _, Item in GcItems do
		if typeof(Item) == "string" then
			self:AddLiteral(Item)
		elseif typeof(Item) == "number" or typeof(Item) == "boolean" then
			self:AddLiteral(Item)
		elseif typeof(Item) == "table" then
			self:ScanTable(Item, 0)
		end
	end
end

function Collection:ScanTable(Tbl, Depth)
	Depth = Depth or 0
	if Depth > 5 then return end

	local Visited = {}

	for K, V in next, Tbl do
		if typeof(K) == "string" or typeof(K) == "number" or typeof(K) == "boolean" then
			self:AddLiteral(K)
		end

		if typeof(V) == "string" or typeof(V) == "number" or typeof(V) == "boolean" then
			self:AddLiteral(V)
		elseif typeof(V) == "table" and not Visited[V] then
			Visited[V] = true

			local IsSmall = true
			local Count = 0

			for _ in next, V do
				Count += 1
				if Count > 100 then
					IsSmall = false
					break
				end
			end

			if IsSmall then
				self:ScanTable(V, Depth + 1)

				if Count > 0 and Count <= 50 then
					table.insert(self.Tables, V)
				end
			end
		end
	end
end

function Collection:AddConstant(Value)
	self:AddLiteral(Value)
end

function Collection:ScanSource(Source)
	if typeof(Source) ~= "string" or Source == "" then
		return
	end

	for Quoted in string.gmatch(Source, "\"([^\n\r\"]*)\"") do
		self:AddLiteral(Quoted)
	end

	for Quoted in string.gmatch(Source, "'([^\n\r']*)'") do
		self:AddLiteral(Quoted)
	end

	for Num in string.gmatch(Source, "[=,%(%[%{%s]([%-]?%d+%.?%d*)[%],%)%}%s]") do
		local Parsed = tonumber(Num)
		if Parsed ~= nil then
			self:AddLiteral(Parsed)
		end
	end

	for _ in string.gmatch(Source, "%f[%a]true%f[^%w_]") do
		self:AddLiteral(true)
	end

	for _ in string.gmatch(Source, "%f[%a]false%f[^%w_]") do
		self:AddLiteral(false)
	end
end

function Collection:TokenizeSource(Source)
	local Tokens = {}
	local Counts = {}
	local Order = {}
	local Seen = {}
	local I = 1
	local Len = #Source

	local function PushToken(StartPos, EndPos, Kind)
		local Token = string.sub(Source, StartPos, EndPos)
		Tokens[#Tokens + 1] = {
			Start = StartPos,
			Stop = EndPos,
			Token = Token,
			Kind = Kind,
		}
		Counts[Token] = (Counts[Token] or 0) + 1
		if not Seen[Token] then
			Seen[Token] = true
			Order[#Order + 1] = {
				Token = Token,
				Kind = Kind,
			}
		end
	end

	while I <= Len do
		local C = string.sub(Source, I, I)
		local NextC = I < Len and string.sub(Source, I + 1, I + 1) or ""

		if C == "-" and NextC == "-" then
			local IsBlock = string.sub(Source, I + 2, I + 3) == "[["
			if IsBlock then
				local Close = string.find(Source, "]]", I + 4, true)
				if not Close then
					break
				end
				I = Close + 2
			else
				local Newline = string.find(Source, "\n", I + 2, true)
				if not Newline then
					break
				end
				I = Newline + 1
			end
		elseif C == "\"" or C == "'" then
			local Quote = C
			local J = I + 1
			while J <= Len do
				local Ch = string.sub(Source, J, J)
				if Ch == "\\" then
					J += 2
				elseif Ch == Quote then
					break
				else
					J += 1
				end
			end
			if J > Len then
				J = Len
			end
			PushToken(I, J, "string")
			I = J + 1
		elseif string.match(C, "[%a_]") then
			local J = I
			while J <= Len and IsWordChar(string.sub(Source, J, J)) do
				J += 1
			end
			local Word = string.sub(Source, I, J - 1)
			if Word == "true" or Word == "false" then
				PushToken(I, J - 1, "boolean")
			end
			I = J
		elseif IsDigit(C) or (C == "-" and IsDigit(NextC)) then
			local StartPos = I
			local J = I
			if C == "-" then
				J += 1
			end
			local SeenDot = false
			while J <= Len do
				local Ch = string.sub(Source, J, J)
				local NextNum = J < Len and string.sub(Source, J + 1, J + 1) or ""
				if IsDigit(Ch) then
					J += 1
				elseif Ch == "." and not SeenDot and IsDigit(NextNum) then
					SeenDot = true
					J += 1
				else
					break
				end
			end

			local Prev = StartPos > 1 and string.sub(Source, StartPos - 1, StartPos - 1) or ""
			local After = J <= Len and string.sub(Source, J, J) or ""
			if not IsWordChar(Prev) and not IsWordChar(After) then
				PushToken(StartPos, J - 1, "number")
			end
			I = J
		else
			I += 1
		end
	end

	return Tokens, Counts, Order
end

function Collection:BuildAliasName(Index, UsedNames, Source)
	local Name = `constant{Index}`
	if not UsedNames[Name] and string.find(Source, "%f[%w_]" .. Name .. "%f[^%w_]", 1) == nil then
		return Name
	end

	local J = Index
	while true do
		Name = `constant_alias{J}`
		if not UsedNames[Name] and string.find(Source, "%f[%w_]" .. Name .. "%f[^%w_]", 1) == nil then
			return Name
		end
		J += 1
	end
end

function Collection:AliasSource(Source)
	if typeof(Source) ~= "string" or Source == "" then
		return Source, 0
	end

	local Tokens, Counts, Order = self:TokenizeSource(Source)
	if #Tokens == 0 then
		return Source, 0
	end

	local AliasMap = {}
	local AliasOrder = {}
	local UsedNames = {}
	local Limit = tonumber(self.Config.constant_limit) or self.MaxConstants
	local MinUses = tonumber(self.Config.constant_alias_min_uses) or 1

	for _, Entry in Order do
		local Token = Entry.Token
		local Kind = Entry.Kind
		local Count = Counts[Token] or 0
		if Count < MinUses then
			continue
		end

		local Allowed = false
		if Kind == "string" then
			local Text = #Token >= 2 and string.sub(Token, 2, -2) or ""
			Allowed = not self:IsGarbage(Text)
		elseif Kind == "number" then
			local Parsed = tonumber(Token)
			Allowed = Parsed ~= nil and Parsed == Parsed and Parsed ~= math.huge and Parsed ~= -math.huge
		elseif Kind == "boolean" then
			Allowed = true
		end

		if not Allowed or AliasMap[Token] then
			continue
		end

		local Name = self:BuildAliasName(#AliasOrder + 1, UsedNames, Source)
		UsedNames[Name] = true
		AliasMap[Token] = Name
		AliasOrder[#AliasOrder + 1] = {
			Name = Name,
			Token = Token,
		}

		if #AliasOrder >= Limit then
			break
		end
	end

	if #AliasOrder == 0 then
		return Source, 0
	end

	local Out = {}
	local Last = 1
	local ReplacedAny = false

	for _, Entry in Tokens do
		local Name = AliasMap[Entry.Token]
		if Name then
			Out[#Out + 1] = string.sub(Source, Last, Entry.Start - 1)
			Out[#Out + 1] = Name
			Last = Entry.Stop + 1
			ReplacedAny = true
		end
	end

	if not ReplacedAny then
		return Source, 0
	end

	Out[#Out + 1] = string.sub(Source, Last)
	local Rewritten = table.concat(Out)

	local Declarations = {}
	for _, Alias in AliasOrder do
		Declarations[#Declarations + 1] = `local {Alias.Name} = {Alias.Token}`
	end

	return table.concat(Declarations, "\n") .. "\n\n" .. Rewritten, #AliasOrder
end

function Collection:AddTable(Tbl)
	if typeof(Tbl) ~= "table" then return end

	if not table.find(self.Tables, Tbl) then
		table.insert(self.Tables, Tbl)
	end
end

function Collection:Generate(Beautifier)
	if #self.Constants == 0 and #self.Tables == 0 then
		return ""
	end

	local Lines = {}

	if #self.Constants > 0 then
		local Entries = {}

		for _, Value in self.Constants do
			local T = typeof(Value)
			if T == "string" then
				table.insert(Entries, StringUtil.Quote(Value))
			elseif T == "number" or T == "boolean" then
				table.insert(Entries, tostring(Value))
			end
		end

		if #Entries > 0 then
			table.insert(Lines, `local constants = \{ {table.concat(Entries, ", ")} \}`)
		end
	end

	if #self.Tables > 0 and Beautifier then
		for I, Tbl in self.Tables do
			local Beautified = Beautifier:Beautify(Tbl, 1)
			table.insert(Lines, `local collected_table_{I} = {Beautified}`)
		end
	end

	return table.concat(Lines, "\n")
end

function Collection:Clear()
	table.clear(self.Constants)
	table.clear(self.ConstantSet)
	table.clear(self.Tables)
end

function Collection:GetConstants()
	return self.Constants
end

function Collection:GetTables()
	return self.Tables
end

return Collection