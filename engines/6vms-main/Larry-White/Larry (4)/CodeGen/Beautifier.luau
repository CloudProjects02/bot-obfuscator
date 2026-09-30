local StringUtil = require("../Utils/String")
local TableUtil = require("../Utils/Table")
local IdentityUtil = require("../Utils/Identity")
local ErrorSanitizer = require("../Utils/ErrorSanitizer")
local SourceSanitizer = require("../Utils/SourceSanitizer")
local Enums = require("../Roblox/Enums")
local DataTypesMod = require("../Roblox/DataTypes")

local Beautifier = {}
Beautifier.__index = Beautifier

function Beautifier.new(State, Emitter, Config)
	local Self = setmetatable({}, Beautifier)
	Self.State = State
	Self.Emitter = Emitter
	Self.Config = Config
	Self.DeferredFunctions = {}
	Self.TableTracker = TableUtil.CreateTracker()
	Self.FunctionMetaCache = setmetatable({}, { __mode = "k" })
	return Self
end

function Beautifier:BeautifyTuple(...)
	local Out = {}
	local Args = table.pack(...)

	for I = 1, Args.n do
		Out[I] = self:Beautify(Args[I], self.State.CurrentIndent + 1)
	end

	return table.concat(Out, ", ")
end

function Beautifier:Beautify_string(Data, Indent, Args)
	return StringUtil.Quote(Data, self.Config.nostringlimit and nil or nil)
end

function Beautifier:Beautify_function(Data, Indent, Args)
	local State = self.State
	local FuncName = Args and Args.FuncName

	local Meta = self.FunctionMetaCache[Data]
	if Meta == nil then
		local SourceMeta, NameMeta = debug.info(Data, "sn")
		local ParamCountMeta, HasVarargsMeta = debug.info(Data, "a")
		local LineMeta = debug.info(Data, "l")
		Meta = {
			Source = SourceMeta,
			Name = NameMeta,
			ParamCount = ParamCountMeta or 0,
			HasVarargs = HasVarargsMeta == true,
			Line = LineMeta,
		}
		self.FunctionMetaCache[Data] = Meta
	end

	local Source, Name = Meta.Source, Meta.Name
	Name = FuncName or Name

	local ParamCount, HasVarargs = Meta.ParamCount, Meta.HasVarargs

	local function TryAstExtraction()
		if not self.Config.ast_reconstruction then
			return nil
		end
		if Source == "[C]" or SourceSanitizer.IsInternalSource(Source) then
			return nil
		end

		local Reconstruction = State.AstReconstruction
		if typeof(Reconstruction) ~= "table" or typeof(Reconstruction.ExtractFunctionByLine) ~= "function" then
			return nil
		end

		local LineNumber = Meta.Line
		if typeof(LineNumber) ~= "number" then
			return nil
		end

		local Snippet = Reconstruction:ExtractFunctionByLine(LineNumber)
		if typeof(Snippet) ~= "string" or Snippet == "" then
			return nil
		end

		return Snippet
	end

	local function BuildShallowFunction(Note)
		local ParamList = {}

		for I = 1, ParamCount do
			ParamList[I] = `arg{I}`
		end

		if HasVarargs then
			ParamList[#ParamList + 1] = "..."
		end

		local Params = table.concat(ParamList, ", ")
		local Body = ""

		if FuncName then
			if StringUtil.IsWeird(FuncName) then
				Body ..= `{StringUtil.Index(FuncName)} = function`
			else
				Body ..= `function {FuncName}`
			end
		else
			Body ..= "function"
		end

		Body ..= `({Params})\n`
		if typeof(Note) == "string" and Note ~= "" then
			local FuncIndent = Args and Args.FromBeautify and string.rep("    ", Indent) or string.rep("    ", 1)
			Body ..= FuncIndent .. `\n`
		end
		local CloseIndent = Indent > 1 and string.rep("    ", Indent - 1) or ""
		Body ..= CloseIndent .. "end"
		return Body, Name
	end

	if not self.Config.explore_funcs then
		return "function()end", Name
	end

	local ExploreMode = self.Config.explore_funcs
	local AllowDeepExplore = ExploreMode == "deep"
	if ExploreMode == true then

		local IsPrimaryScript = typeof(Source) == "string" and string.find(Source, "LocalScript", 1, true) ~= nil
		AllowDeepExplore = (Args and Args.ExploreCallback == true) and IsPrimaryScript and (ParamCount or 0) <= 4 and not HasVarargs
	end

	if Args and Args.ShallowAsync then
		return BuildShallowFunction()
	end

	if State:IsInternal(Data) or SourceSanitizer.IsInternalSource(Source) then
		return BuildShallowFunction()
	end

	if Source == "[C]" then
		return Name == "" and "(function()end)" or Name, Name
	end

	if Args and Args.ExploreCallback then
		local AstBody = TryAstExtraction()
		if AstBody ~= nil then
			return AstBody, Name
		end
	end

	if not AllowDeepExplore then
		local AstBody = TryAstExtraction()
		if AstBody ~= nil then
			return AstBody, Name
		end
		return BuildShallowFunction()
	end

	local OldOutput = State.Output
	local OldParams = State.ParamsUsed
	local OldExploringFunction = State.ExploringFunction
	local OldIndent = State.CurrentIndent
	State.Output = {}
	State.ParamsUsed = {}
	State.ExploringFunction = true

	local BufferCount = 50
	local Suffix = `_{State.NestCount + 1}`

	local ParamProxies = {}
	for I = 1, ParamCount + BufferCount do
		local ParamPath = `arg{I}{Suffix}`
		State.ParamsUsed[ParamPath] = false

		local Spied = State.Spied[ParamPath]
		if not Spied then
			local Mt = require("../Core/ProxyMeta").Build(
				require("../Core/Proxy").new(State, self.Emitter, self, require("../Core/Scope").new(State, self.Emitter)),
				ParamPath, true
			)
			Spied = setmetatable({ P = ParamPath, ISP = true }, Mt)
			State.Spied[ParamPath] = Spied
			State:RegisterInternal(Spied, ParamPath)
		end

		ParamProxies[I] = Spied
	end

	local S, Err = pcall(Data, unpack(ParamProxies, 1, ParamCount + BufferCount))

	if not S and State.CurrentIndent > OldIndent then
		for _ = State.CurrentIndent, OldIndent + 1, -1 do
			State.Output[#State.Output + 1] = "end"
		end
	end

	State.CurrentIndent = OldIndent

	local CapturedOutput = State.Output
	local CapturedParams = State.ParamsUsed

	State.Output = OldOutput
	State.ParamsUsed = OldParams
	State.ExploringFunction = OldExploringFunction

	CapturedOutput = self:InlineCallbackOutput(CapturedOutput)

	local Sorted = {}
	for K in next, CapturedParams do
		table.insert(Sorted, K)
	end

	table.sort(Sorted, function(A, B)
		local NumA = tonumber(string.match(A, "arg(%d+)")) or math.huge
		local NumB = tonumber(string.match(B, "arg(%d+)")) or math.huge
		return NumA < NumB
	end)

	local ParamList = {}
	for _, Key in Sorted do
		table.insert(ParamList, CapturedParams[Key] and Key or "_")
	end

	for I = #ParamList, 1, -1 do
		if ParamList[I] == "_" then
			table.remove(ParamList, I)
		else
			break
		end
	end

	local Params = table.concat(ParamList, ", ")
	local FuncIndent = Args and Args.FromBeautify and string.rep("    ", Indent) or string.rep("    ", 1)

	local Body = ""

	if FuncName then
		if StringUtil.IsWeird(FuncName) then
			Body ..= `{StringUtil.Index(FuncName)} = function`
		else
			Body ..= `function {FuncName}`
		end
	else
		Body ..= "function"
	end

	Body ..= `({Params})\n`

	if not S and #CapturedOutput == 0 then
		local AstBody = TryAstExtraction()
		if AstBody ~= nil then
			return AstBody, Name
		end
		if Args and Args.SignalPath and Args.ConnectMode then
			local Reconstruction = State.AstReconstruction
			if typeof(Reconstruction) == "table" and typeof(Reconstruction.TakeSignalCallback) == "function" then
				local Snippet = Reconstruction:TakeSignalCallback(Args.SignalPath, Args.ConnectMode, Args.EventName)
				if typeof(Snippet) == "string" and Snippet ~= "" then
					return Snippet, Name
				end
			end
		end
		local Sanitized = ErrorSanitizer.Sanitize(tostring(Err))
		Body ..= FuncIndent .. `\n`
	end

	for _, Line in CapturedOutput do
		if Line ~= nil and Line ~= "" then
			Body ..= FuncIndent .. Line .. "\n"
		end
	end

	local CloseIndent = Indent > 1 and string.rep("    ", Indent - 1) or ""
	Body ..= CloseIndent .. "end"

	return Body, Name
end

function Beautifier:Beautify_table(Data, Indent, Args)
	local State = self.State
	local Minify = Args and Args.Minify

	local InternalPath = State:IsInternal(Data)
	if InternalPath then return InternalPath end

	local TrackedName = self.TableTracker.Get(Data)
	if TrackedName then return TrackedName end

	if Enums.IsEnumItem(Data) then
		return tostring(Data)
	end

	if TableUtil.IsRecursive(Data) then return "{}" end

	local Entries = {}
	local Count = 0
	local IsArray = true

	local NewLine = Minify and " " or "\n"
	local EntryTab = Minify and "" or string.rep("    ", Indent)
	local CloseTab = Minify and " " or string.rep("    ", math.max(Indent - 1, 0))

	for K, V in next, Data do
		Count += 1

		if Count ~= K then IsArray = false end

		local IsCallbackField = typeof(K) == "string" and string.lower(K) == "callback"
		local FormattedValue = self:Beautify(V, Indent + 1, {
			FromBeautify = true,
			ExploreCallback = IsCallbackField,
		})
		local Entry

		if IsArray and Count == K then
			Entry = `{NewLine}{EntryTab}{FormattedValue}`
		else
			local FormattedKey
			if StringUtil.IsWeird(tostring(K)) then
				FormattedKey = `[{self:Beautify(K, Indent, { Minify = true })}]`
			else
				FormattedKey = tostring(K)
			end
			Entry = `{NewLine}{EntryTab}{FormattedKey} = {FormattedValue}`
			IsArray = false
		end

		Entries[Count] = Entry
	end

	if Count == 0 then return "{}" end

	return "{" .. table.concat(Entries, ",") .. `{NewLine}{CloseTab}` .. "}"
end

function Beautifier:InlineCallbackOutput(Lines)
	local LineList
	if typeof(Lines) == "string" then
		LineList = string.split(Lines, "\n")
	else
		LineList = Lines
	end

	local Declarations = {}
	local Usages = {}

	for I, Line in LineList do
		if not Line then continue end
		local Var = string.match(Line, "^%s*local%s+([%w_]+)%s*=")
		if Var then
			Declarations[Var] = I
			Usages[Var] = 0
		end
	end

	for I, Line in LineList do
		if not Line then continue end
		for Var in next, Declarations do
			if Declarations[Var] ~= I then
				if string.find(Line, Var, 1, true) then
					Usages[Var] = (Usages[Var] or 0) + 1
				end
			end
		end
	end

	local Result = {}
	for I, Line in LineList do
		if not Line then continue end
		local Var = string.match(Line, "^%s*local%s+([%w_]+)%s*=")
		if Var and Usages[Var] == 0 then
			continue
		end
		Result[#Result + 1] = Line
	end

	return Result
end

function Beautifier:Beautify_userdata(Data, Indent, Args)
	local Mt = getmetatable(Data)
	if Mt then
		return `get_user_data({self:Beautify(Mt, Indent + 1)})`
	end
	return self:Beautify(tostring(Data))
end

function Beautifier:Beautify_number(Data, Indent, Args)
	local Str = tostring(Data)

	if Str == "-inf" then return "-math.huge" end
	if Str == "inf" then return "math.huge" end
	if Str == "nan" then return "0/0" end

	if Data % 1 == 0 then
		return tostring(math.floor(Data))
	end

	local Rounded = tonumber(string.format("%.6f", Data))
	if not Rounded then
		return Str
	end

	local Pretty = string.format("%.6f", Rounded)
	Pretty = string.gsub(Pretty, "0+$", "")
	Pretty = string.gsub(Pretty, "%.$", "")

	if Pretty == "-0" then
		Pretty = "0"
	end

	return Pretty
end

function Beautifier:Beautify_boolean(Data, Indent, Args)
	return tostring(Data)
end

function Beautifier:Beautify_nil(Data, Indent, Args)
	return "nil"
end

function Beautifier:Beautify_EnumItem(Data, Indent, Args)
	return tostring(Data)
end

function Beautifier:Beautify(Data, Indent, Args)
	Indent = Indent or self.State.CurrentIndent
	Args = typeof(Args) == "table" and Args or {}

	local Type = typeof(Data)

	if Type == "table" then
		if Enums.IsEnumItem(Data) then
			return tostring(Data)
		end
	end

	local RobloxStr = DataTypesMod.Beautify(Data, self, Indent)
	if RobloxStr then return RobloxStr end

	local Handler = self["Beautify_" .. Type]

	if Handler then
		return Handler(self, Data, Indent, Args)
	end

	return tostring(Data)
end

function Beautifier:TrackTable(Tbl, Name)
	self.TableTracker.Mark(Tbl, Name)
end

return Beautifier