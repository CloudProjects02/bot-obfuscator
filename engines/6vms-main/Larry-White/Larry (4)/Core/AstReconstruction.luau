local AstReconstruction = {}
AstReconstruction.__index = AstReconstruction

local function NormalizePathKey(Path)
	if typeof(Path) ~= "string" then
		return nil
	end

	local Clean = string.gsub(Path, "%s+", "")
	if Clean == "" then
		return nil
	end

	return Clean
end

local function AppendQueue(Map, Key, Value)
	if Key == nil or Value == nil then
		return
	end

	local Queue = Map[Key]
	if Queue == nil then
		Queue = {}
		Map[Key] = Queue
	end
	Queue[#Queue + 1] = Value
end

local function PopQueue(Map, Key)
	local Queue = Map[Key]
	if Queue == nil or #Queue == 0 then
		return nil
	end

	local Value = Queue[1]
	table.remove(Queue, 1)
	return Value
end

local function IsIdentifierStart(Char)
	return string.match(Char, "[%a_]") ~= nil
end

local function IsIdentifierPart(Char)
	return string.match(Char, "[%w_]") ~= nil
end

local function FindLongBracketClose(Source, StartPos)
	local Equals = string.match(string.sub(Source, StartPos), "^%[(=*)%[")
	if Equals == nil then
		return nil
	end

	local ClosePat = "]" .. Equals .. "]"
	local SearchStart = StartPos + 2 + #Equals
	local CloseStart = string.find(Source, ClosePat, SearchStart, true)
	if CloseStart == nil then
		return #Source
	end

	return CloseStart + #ClosePat - 1
end

local function FindFunctionToken(Source, StartPos)
	local Index = math.max(1, StartPos or 1)
	local Len = #Source

	while Index <= Len do
		local Char = string.sub(Source, Index, Index)

		if Char == "\"" or Char == "'" then
			local Quote = Char
			Index += 1
			while Index <= Len do
				local Cur = string.sub(Source, Index, Index)
				if Cur == "\\" then
					Index += 2
				elseif Cur == Quote then
					Index += 1
					break
				else
					Index += 1
				end
			end
		elseif Char == "-" and string.sub(Source, Index + 1, Index + 1) == "-" then
			if string.sub(Source, Index + 2, Index + 2) == "[" then
				local BlockEnd = FindLongBracketClose(Source, Index + 2)
				if BlockEnd ~= nil then
					Index = BlockEnd + 1
				else
					Index += 1
				end
			else
				local Newline = string.find(Source, "\n", Index + 2, true)
				if Newline == nil then
					return nil
				end
				Index = Newline + 1
			end
		elseif Char == "[" then
			local BlockEnd = FindLongBracketClose(Source, Index)
			if BlockEnd ~= nil then
				Index = BlockEnd + 1
			else
				Index += 1
			end
		elseif IsIdentifierStart(Char) then
			local TokenStart = Index
			Index += 1
			while Index <= Len and IsIdentifierPart(string.sub(Source, Index, Index)) do
				Index += 1
			end

			local Token = string.sub(Source, TokenStart, Index - 1)
			if Token == "function" then
				return TokenStart
			end
		else
			Index += 1
		end
	end

	return nil
end

local function FindFunctionEnd(Source, FunctionStart)
	local Len = #Source
	local Index = FunctionStart
	local Depth = 0
	local RepeatDepth = 0
	local LastToken = nil

	while Index <= Len do
		local Char = string.sub(Source, Index, Index)

		if Char == "\"" or Char == "'" then
			local Quote = Char
			Index += 1
			while Index <= Len do
				local Cur = string.sub(Source, Index, Index)
				if Cur == "\\" then
					Index += 2
				elseif Cur == Quote then
					Index += 1
					break
				else
					Index += 1
				end
			end
		elseif Char == "-" and string.sub(Source, Index + 1, Index + 1) == "-" then
			if string.sub(Source, Index + 2, Index + 2) == "[" then
				local BlockEnd = FindLongBracketClose(Source, Index + 2)
				if BlockEnd ~= nil then
					Index = BlockEnd + 1
				else
					Index += 1
				end
			else
				local Newline = string.find(Source, "\n", Index + 2, true)
				if Newline == nil then
					return nil
				end
				Index = Newline + 1
			end
		elseif Char == "[" then
			local BlockEnd = FindLongBracketClose(Source, Index)
			if BlockEnd ~= nil then
				Index = BlockEnd + 1
			else
				Index += 1
			end
		elseif IsIdentifierStart(Char) then
			local TokenStart = Index
			Index += 1
			while Index <= Len and IsIdentifierPart(string.sub(Source, Index, Index)) do
				Index += 1
			end

			local Token = string.sub(Source, TokenStart, Index - 1)
			if Token == "function" or Token == "if" or Token == "for" or Token == "while" then
				Depth += 1
			elseif Token == "do" then
				if LastToken ~= "for" and LastToken ~= "while" then
					Depth += 1
				end
			elseif Token == "repeat" then
				RepeatDepth += 1
			elseif Token == "until" then
				if RepeatDepth > 0 then
					RepeatDepth -= 1
				end
			elseif Token == "end" then
				Depth -= 1
				if Depth <= 0 and RepeatDepth <= 0 then
					return Index - 1
				end
			end

			LastToken = Token
		else
			Index += 1
		end
	end

	return nil
end

local function BuildLineOffsets(Source)
	local Offsets = { 1 }
	for Index = 1, #Source do
		if string.sub(Source, Index, Index) == "\n" then
			Offsets[#Offsets + 1] = Index + 1
		end
	end
	return Offsets
end

function AstReconstruction.new(Source)
	local Self = setmetatable({}, AstReconstruction)
	Self.Source = typeof(Source) == "string" and Source or ""
	Self.LineOffsets = BuildLineOffsets(Self.Source)
	Self.FunctionCache = {}
	Self.PcallCallbacks = {}
	Self.CallbacksByPath = {}
	Self.CallbacksByEvent = {}
	Self.Features = {
		has_pairs = string.find(Self.Source, "pairs(", 1, true) ~= nil,
		has_ipairs = string.find(Self.Source, "ipairs(", 1, true) ~= nil,
		has_type = string.find(Self.Source, "type(", 1, true) ~= nil,
		has_typeof = string.find(Self.Source, "typeof(", 1, true) ~= nil,
		has_isa = string.find(Self.Source, ":IsA(", 1, true) ~= nil,
	}
	Self:_IndexPcallCallbacks()
	Self:_IndexSignalCallbacks()
	return Self
end

function AstReconstruction:_IndexPcallCallbacks()
	local Cursor = 1
	local Source = self.Source
	local Len = #Source
	local Aliases = {
		pcall = true,
	}

	for Alias in string.gmatch(Source, "local%s+([%a_][%w_]*)%s*=%s*pcall") do
		Aliases[Alias] = true
	end
	for Alias in string.gmatch(Source, "[;%s]([%a_][%w_]*)%s*=%s*pcall") do
		Aliases[Alias] = true
	end

	while Cursor <= Len do
		local MatchStart, MatchEnd, Name = string.find(Source, "([%a_][%w_]*)%s*%(%s*function", Cursor)
		if MatchStart == nil then
			break
		end
		if not Aliases[Name] then
			Cursor = MatchEnd + 1
			continue
		end

		local FunctionStart = string.find(Source, "function", MatchStart, true)
		if FunctionStart == nil then
			Cursor = MatchEnd + 1
			continue
		end

		local FunctionEnd = FindFunctionEnd(Source, FunctionStart)
		if FunctionEnd == nil then
			Cursor = MatchEnd + 1
			continue
		end

		self.PcallCallbacks[#self.PcallCallbacks + 1] = string.sub(Source, FunctionStart, FunctionEnd)
		Cursor = FunctionEnd + 1
	end
end

function AstReconstruction:_IndexSignalCallbacks()
	local Cursor = 1
	local Source = self.Source
	local Len = #Source

	while Cursor <= Len do
		local MatchStart, MatchEnd, RawPath, Method = string.find(
			Source,
			"([%w_%.%[%]%s]+):([%a_][%w_]*)%s*%(%s*function",
			Cursor
		)
		if MatchStart == nil then
			break
		end

		local FunctionKeywordStart = string.find(Source, "function", MatchEnd - 12, true)
		if FunctionKeywordStart == nil then
			Cursor = MatchEnd + 1
			continue
		end

		local FunctionStart = FunctionKeywordStart
		local FunctionEnd = FindFunctionEnd(Source, FunctionStart)
		if FunctionEnd == nil then
			Cursor = MatchEnd + 1
			continue
		end

		RawPath = string.gsub(RawPath, "%s+$", "")

		local Snippet = string.sub(Source, FunctionStart, FunctionEnd)
		local PathKey = NormalizePathKey(RawPath .. ":" .. Method)
		AppendQueue(self.CallbacksByPath, PathKey, Snippet)

		local EventName = string.match(RawPath, "([%a_][%w_]*)$")
		if EventName ~= nil then
			local EventKey = NormalizePathKey(EventName .. ":" .. Method)
			AppendQueue(self.CallbacksByEvent, EventKey, Snippet)
		end

		Cursor = FunctionEnd + 1
	end
end

function AstReconstruction:ExtractFunctionByLine(LineNumber)
	if typeof(LineNumber) ~= "number" then
		return nil
	end

	local Cached = self.FunctionCache[LineNumber]
	if Cached ~= nil then
		return Cached
	end

	local LineStart = self.LineOffsets[LineNumber]
	if typeof(LineStart) ~= "number" then
		self.FunctionCache[LineNumber] = false
		return nil
	end

	local FunctionStart = FindFunctionToken(self.Source, LineStart)
	if FunctionStart == nil then
		self.FunctionCache[LineNumber] = false
		return nil
	end

	local FunctionEnd = FindFunctionEnd(self.Source, FunctionStart)
	if FunctionEnd == nil then
		self.FunctionCache[LineNumber] = false
		return nil
	end

	local Snippet = string.sub(self.Source, FunctionStart, FunctionEnd)
	self.FunctionCache[LineNumber] = Snippet
	return Snippet
end

function AstReconstruction:TakeSignalCallback(Path, Method, EventName)
	Method = Method or "Connect"
	local PathKey = NormalizePathKey((Path or "") .. ":" .. Method)
	local EventKey = NormalizePathKey((EventName or "") .. ":" .. Method)

	local Candidate = PopQueue(self.CallbacksByPath, PathKey)
	if Candidate ~= nil then
		return Candidate
	end

	Candidate = PopQueue(self.CallbacksByEvent, EventKey)
	if Candidate ~= nil then
		return Candidate
	end

	return nil
end

function AstReconstruction:TakePcallCallback()
	if #self.PcallCallbacks == 0 then
		return nil
	end
	local Snippet = self.PcallCallbacks[1]
	table.remove(self.PcallCallbacks, 1)
	return Snippet
end

function AstReconstruction:GetFeatures()
	return self.Features
end

return AstReconstruction