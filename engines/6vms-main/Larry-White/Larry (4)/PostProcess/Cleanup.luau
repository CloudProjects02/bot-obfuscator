local StringUtil = require("../Utils/String")

local Cleanup = {}

local function ShiftIndent(Line, OldIndent, NewIndent)
	if typeof(Line) ~= "string" then
		return Line
	end

	if OldIndent ~= "" and string.sub(Line, 1, #OldIndent) == OldIndent then
		return NewIndent .. string.sub(Line, #OldIndent + 1)
	end

	return NewIndent .. Line
end

local function StripLeadingLocalAssignment(Line)
	if typeof(Line) ~= "string" then
		return Line
	end

	local Indent = string.match(Line, "^(%s*)") or ""
	local Stripped = string.match(Line, "^%s*local%s+[%w_]+%s*=%s*(.+)$")
	if Stripped ~= nil then
		return Indent .. Stripped
	end

	return Line
end

local function FindLastConnectBlock(Output, ButtonPath)
	for Start = #Output, 1, -1 do
		local Line = Output[Start]
		if typeof(Line) ~= "string" then
			continue
		end

		local Trimmed = StringUtil.Strip(Line)
		if string.find(Trimmed, ButtonPath, 1, true) == nil then
			continue
		end

		if string.find(Trimmed, ":Connect(function(", 1, true) == nil then
			continue
		end

		local Indent = string.match(Line, "^(%s*)") or ""
		if string.find(Line, "\n", 1, true) ~= nil then
			local InlineClose = "\n" .. Indent .. "end)"
			if string.find(Line, InlineClose, 1, true) ~= nil then
				return Start, Start, Indent
			end
		end

		local CloseLine = Indent .. "end)"

		for EndIndex = Start + 1, #Output do
			if Output[EndIndex] == CloseLine then
				return Start, EndIndex, Indent
			end
		end
	end

	return nil
end

function Cleanup.new(State, Config)
	local Self = setmetatable({}, { __index = Cleanup })
	Self.State = State
	Self.Config = Config
	Self.DuplicateThreshold = 3
	Self.SeenLines = {}
	Self.SeenCounts = {}
	return Self
end

local function IsSafeMode(Config)
	if Config.postprocess_safe_mode == true then
		return true
	end

	local Profile = string.lower(tostring(Config.profile or ""))
	return Profile == "fidelity" or Config.readable_output == true
end

function Cleanup:RemoveBlanks(Source)
	return (string.gsub(Source, "%s*\n%s*\n", "\n"))
end

function Cleanup:RemoveDuplicateCode(Output)
	local function IsCondensableCall(Line)
		if typeof(Line) ~= "string" then
			return false
		end

		local Trimmed = StringUtil.Strip(Line)
		if Trimmed == "" then
			return false
		end
		if string.sub(Trimmed, 1, 2) == "
			return false
		end
		if string.match(Trimmed, "^local%s+") then
			return false
		end
		if string.find(Trimmed, "=", 1, true) then
			return false
		end

		return string.match(Trimmed, "^[%w_%.:%[%]\"']+%b()%s*$") ~= nil
	end

	local Result = {}
	local LastKey = nil
	local RunCount = 0
	local Suppressed = 0

	local function FlushSuppressed()
		if Suppressed <= 0 then
			return
		end
		Result[#Result + 1] = ``
		Suppressed = 0
	end

	for _, Line in Output do
		if Line == nil then
			continue
		end

		local Key = StringUtil.Strip(Line)
		if Key == LastKey and IsCondensableCall(Line) then
			RunCount += 1
			if RunCount > self.DuplicateThreshold then
				Suppressed += 1
				continue
			end
		else
			FlushSuppressed()
			LastKey = Key
			RunCount = 1
		end

		table.insert(Result, Line)
	end
	FlushSuppressed()

	return Result
end

function Cleanup:RemoveJunkNewindex(Output)
	local Result = {}
	local LastAssignment = nil
	local LastValue = nil

	for _, Line in Output do
		if not Line then continue end

		local Stripped = StringUtil.Strip(Line)
		local Var, Val = string.match(Stripped, "^([%w_%.%[%]\"]+)%s*=%s*(.+)$")

		if Var and Val and Var == LastAssignment and Val == LastValue then
			continue
		end

		if Var then
			LastAssignment = Var
			LastValue = Val
		else
			LastAssignment = nil
			LastValue = nil
		end

		table.insert(Result, Line)
	end

	return Result
end

function Cleanup:RemoveJunkTables(Output)
	local Result = {}

	for _, Line in Output do
		if not Line then continue end

		local Stripped = StringUtil.Strip(Line)

		local IsJunk = string.match(Stripped, "^local%s+[%w_]+%s*=%s*{%s*true%s*,%s*getfenv") or
			string.match(Stripped, "^local%s+[%w_]+%s*=%s*{%s*getfenv")

		if IsJunk then
			continue
		end

		table.insert(Result, Line)
	end

	return Result
end

function Cleanup:RemovePrometheusJunk(Output)
	local Result = {}

	for _, Line in Output do
		if not Line then continue end

		local Stripped = StringUtil.Strip(Line)

		if string.match(Stripped, "^while%s+game%s+do%s*$") then
			continue
		end

		table.insert(Result, Line)
	end

	return Result
end

function Cleanup:RemoveUnusedLiteralLocals(Output)
	local Result = {}

	local function IsLiteral(Value)
		local Stripped = StringUtil.Strip(Value)
		if Stripped == "true" or Stripped == "false" or Stripped == "nil" then
			return true
		end

		if string.match(Stripped, "^[%-]?%d+%.?%d*$") then
			return true
		end

		if string.match(Stripped, "^\".*\"$") or string.match(Stripped, "^'.*'$") then
			return true
		end

		return false
	end

	for I, Line in ipairs(Output) do
		if not Line then
			continue
		end

		local Var, Value = string.match(StringUtil.Strip(Line), "^local%s+([%w_]+)%s*=%s*(.+)$")
		if Var and Value and IsLiteral(Value) then
			local Used = false
			local Pattern = "%f[%w_]" .. Var .. "%f[^%w_]"
			for J = I + 1, #Output do
				local Later = Output[J]
				if Later and string.match(Later, Pattern) then
					Used = true
					break
				end
			end

			if not Used then
				continue
			end
		end

		Result[#Result + 1] = Line
	end

	return Result
end

function Cleanup:ReconstructIfElse(Output)
	local Result = {}
	local i = 1
	while i <= #Output do
		local Line = Output[i]
		if not Line then 
			i += 1 
			continue 
		end

		local Indent, Var = string.match(Line, "^(%s*)if%s+([^%s]+)%s+then%s*end%s*$")

		if Var then
			local Chain = { {Indent, Var} }
			local j = i + 1
			while j <= #Output do
				local NextLine = Output[j]
				if not NextLine or StringUtil.Strip(NextLine) == "" then
					j += 1
					continue
				end
				local isLocal = string.match(NextLine, "^%s*local%s+[%w_]+%s*=")
				if isLocal then
					table.insert(Chain, {NextLine = NextLine})
					j += 1
					continue
				end

				local NIndent, NVar = string.match(NextLine, "^(%s*)if%s+([^%s]+)%s+then%s*end%s*$")
				if NVar and NIndent == Indent then
					table.insert(Chain, {Indent = NIndent, Var = NVar})
					j += 1
				else
					break
				end
			end

			local RealIfs = 0
			for _, item in Chain do
				if item.Var then RealIfs += 1 end
			end

			if RealIfs > 1 then
				local first = true
				for _, item in Chain do
					if item.NextLine then
						table.insert(Result, item.NextLine)
					elseif item.Var then
						if first then
							table.insert(Result, item.Indent .. `if {item.Var} then`)
							first = false
						else
							table.insert(Result, item.Indent .. `elseif {item.Var} then`)
						end
					end
				end
				table.insert(Result, Indent .. "end")
				i = j - 1
			else
				table.insert(Result, Line)
			end
		else
			table.insert(Result, Line)
		end
		i += 1
	end
	return Result
end

function Cleanup:InlineVariables(Output)
	local Result = {}
	local VarDefs = {}
	local VarUsage = {}

	for _, Line in Output do
		if not Line then continue end
		local Indent, Var, Val = string.match(Line, "^(%s*)local%s+([%w_]+)%s*=%s*(.+)$")
		if Var and Val then
			VarUsage[Var] = 0
			VarDefs[Var] = { Line = Line, Val = Val, Regex = "%f[%w_]" .. Var .. "%f[^%w_]" }
		end
	end

	for _, Line in Output do
		for Var, Dat in VarDefs do
			if string.match(Line, Dat.Regex) and Line ~= Dat.Line then
				VarUsage[Var] += 1
			end
		end
	end

	for _, Line in Output do
		if not Line then continue end

		local Indent, Var, Val = string.match(Line, "^(%s*)local%s+([%w_]+)%s*=%s*(.+)$")
		if Var and Val and VarUsage[Var] == 1 then
			local CanInline = false
			local isSimple = false

			if string.match(Val, "^[%w_%.%[%]\"']+$") then
				isSimple = true
			elseif string.match(Val, "^%(.*%)$") then
				isSimple = true 
			elseif string.match(Val, "^not%s+[%w_%.%[%]\"']+$") then
				isSimple = true
			elseif string.match(Val, "^[%w_%.%[%]\"']+%s+and%s+[%w_%.%[%]\"']+$") then
				isSimple = true
			elseif string.match(Val, "^[%w_%.%[%]\"']+%s+or%s+[%w_%.%[%]\"']+$") then
				isSimple = true
			elseif string.match(Val, "^[%w_%.]+%s*[=~<>-]+%s*[%w_%.]+$") then
				isSimple = true
			end

			if isSimple then
				VarDefs[Var].InlineReady = true
				continue
			end
		end

		local newLine = Line
		for v, Dat in VarDefs do
			if Dat.InlineReady and string.match(newLine, Dat.Regex) then
				newLine = string.gsub(newLine, Dat.Regex, Dat.Val)
			end
		end

		table.insert(Result, newLine)
	end

	return Result
end

function Cleanup:FoldTables(Output)
	local Result = {}
	local i = 1
	while i <= #Output do
		local Line = Output[i]
		if not Line then 
			i += 1
			continue 
		end

		local Indent, Var = string.match(Line, "^(%s*)local%s+([%w_]+)%s*=%s*{%s*}%s*$")
		if Var then
			local Elements = {}
			local HasMetatable = false
			local MetaMt = nil
			local j = i + 1

			while j <= #Output do
				local NextLine = Output[j]
				if not NextLine or StringUtil.Strip(NextLine) == "" then
					j += 1
					continue
				end

				local ArrVar, ArrKey, ArrVal = string.match(NextLine, "^%s*([%w_]+)%[([%d]+)%]%s*=%s*(.+)$")
				if ArrVar == Var and tonumber(ArrKey) == #Elements + 1 then
					table.insert(Elements, ArrVal)
					j += 1
					continue
				end

				local MapVar, MapKey, MapVal = string.match(NextLine, "^%s*([%w_]+)%[\"([^\"]+)\"%]%s*=%s*(.+)$")
				if MapVar == Var then
					table.insert(Elements, `["{MapKey}"] = {MapVal}`)
					j += 1
					continue
				end

				local PropVar, PropKey, PropVal = string.match(NextLine, "^%s*([%w_]+)%.([%w_]+)%s*=%s*(.+)$")
				if PropVar == Var then
					table.insert(Elements, `{PropKey} = {PropVal}`)
					j += 1
					continue
				end

				local MetaVar, MtVal = string.match(NextLine, "^%s*setmetatable%(%s*([%w_]+)%s*,%s*(.+)%s*%)%s*$")
				if MetaVar == Var then
					HasMetatable = true
					MetaMt = MtVal
					j += 1
					break
				end

				break
			end

			if #Elements > 0 or HasMetatable then
				local FormattedElements = table.concat(Elements, ", ")

				if HasMetatable then
					table.insert(Result, Indent .. `local {Var} = setmetatable(\{{FormattedElements}}, {MetaMt})`)
				else
					table.insert(Result, Indent .. `local {Var} = \{{FormattedElements}}`)
				end
				i = j - 1
			else
				table.insert(Result, Line)
			end
		else
			table.insert(Result, Line)
		end
		i += 1
	end
	return Result
end

function Cleanup:ReconstructViewSubmitIfElse(Output)
	local Result = {}
	local Index = 1

	while Index <= #Output do
		local Line = Output[Index]
		if typeof(Line) ~= "string" then
			Index += 1
			continue
		end

		local ButtonPath, TextBoxPath, KeyLiteral = string.match(
			Line,
			"^%-%-%[%[%s*larry:view%-submit begin button=(.-) textbox=(.-) key=(.+)%s*%]%]$"
		)

		if ButtonPath == nil then
			Result[#Result + 1] = Line
			Index += 1
			continue
		end

		KeyLiteral = StringUtil.Strip(KeyLiteral)

		local Continuation = {}
		local EndIndex = Index + 1
		while EndIndex <= #Output do
			local Current = Output[EndIndex]
			if Current == "" then
				break
			end
			if Current ~= nil then
				Continuation[#Continuation + 1] = Current
			end
			EndIndex += 1
		end

		if EndIndex > #Output then
			for _, ContinuationLine in ipairs(Continuation) do
				Result[#Result + 1] = ContinuationLine
			end
			break
		end

		local AssignmentLine = `{TextBoxPath}.Text = {KeyLiteral}`
		while #Continuation > 0 and StringUtil.Strip(Continuation[1]) == "" do
			table.remove(Continuation, 1)
		end
		if #Continuation > 0 and StringUtil.Strip(string.gsub(Continuation[1], "\r", "")) == AssignmentLine then
			table.remove(Continuation, 1)
		end

		local StartIndex, CloseIndex, Indent = FindLastConnectBlock(Result, ButtonPath)
		if StartIndex == nil or CloseIndex == nil or #Continuation == 0 then
			for _, ContinuationLine in ipairs(Continuation) do
				Result[#Result + 1] = ContinuationLine
			end
			Index = EndIndex + 1
			continue
		end

		local BodyIndent = Indent .. "    "
		local BranchIndent = BodyIndent .. "    "
		local Rebuilt = {}

		for I = 1, StartIndex - 1 do
			Rebuilt[#Rebuilt + 1] = Result[I]
		end

		if StartIndex == CloseIndex and string.find(Result[StartIndex], "\n", 1, true) ~= nil then
			local Inline = string.gsub(Result[StartIndex], "\r", "")
			local Header, OriginalBody, Footer = string.match(
				Inline,
				"^(.-:Connect%(function%b())\n(.-)\n([ \t]*end%))$"
			)

			if Header ~= nil and Footer ~= nil then
				local InlineLines = {
					StripLeadingLocalAssignment(Header),
					BodyIndent .. `if {TextBoxPath}.Text == {KeyLiteral} then`,
				}

				for _, ContinuationLine in ipairs(Continuation) do
					InlineLines[#InlineLines + 1] = ShiftIndent(ContinuationLine, "", BranchIndent)
				end

				InlineLines[#InlineLines + 1] = BodyIndent .. "else"

				for BodyLine in string.gmatch(OriginalBody, "([^\n]+)") do
					InlineLines[#InlineLines + 1] = ShiftIndent(BodyLine, BodyIndent, BranchIndent)
				end

				InlineLines[#InlineLines + 1] = BodyIndent .. "end"
				InlineLines[#InlineLines + 1] = Footer
				for _, InlineLine in ipairs(InlineLines) do
					Rebuilt[#Rebuilt + 1] = InlineLine
				end
			else
				Rebuilt[#Rebuilt + 1] = StripLeadingLocalAssignment(Result[StartIndex])
				for _, ContinuationLine in ipairs(Continuation) do
					Rebuilt[#Rebuilt + 1] = ContinuationLine
				end
			end
		else
			Rebuilt[#Rebuilt + 1] = StripLeadingLocalAssignment(Result[StartIndex])
			Rebuilt[#Rebuilt + 1] = BodyIndent .. `if {TextBoxPath}.Text == {KeyLiteral} then`

			for _, ContinuationLine in ipairs(Continuation) do
				Rebuilt[#Rebuilt + 1] = ShiftIndent(ContinuationLine, "", BranchIndent)
			end

			Rebuilt[#Rebuilt + 1] = BodyIndent .. "else"

			for I = StartIndex + 1, CloseIndex - 1 do
				Rebuilt[#Rebuilt + 1] = ShiftIndent(Result[I], BodyIndent, BranchIndent)
			end

			Rebuilt[#Rebuilt + 1] = BodyIndent .. "end"
			Rebuilt[#Rebuilt + 1] = Result[CloseIndex]
		end

		for I = CloseIndex + 1, #Result do
			Rebuilt[#Rebuilt + 1] = Result[I]
		end

		Result = Rebuilt
		Index = EndIndex + 1
	end

	return Result
end

function Cleanup:StripComments(Output)
	if self.Config.comment then return Output end

	local Result = {}

	for _, Line in Output do
		if not Line then continue end

		local Stripped = StringUtil.Strip(Line)

		if string.sub(Stripped, 1, 2) == "
			continue
		end

		local WithoutTrailing = string.gsub(Line, "%s*%-%-[^%[%]].*$", "")

		if StringUtil.Strip(WithoutTrailing) ~= "" then
			table.insert(Result, WithoutTrailing)
		end
	end

	return Result
end

function Cleanup:CondenseWaits(Output)
	local Result = {}
	local i = 1
	while i <= #Output do
		local Line = Output[i]
		if not Line then
			i += 1
			continue
		end

		local Indent, Var, WaitArg = string.match(Line, "^(%s*)local%s+([%w_]+)%s*=%s*task%.wait%((.*)%)$")
		if not Indent then
			Indent, WaitArg = string.match(Line, "^(%s*)task%.wait%((.*)%)$")
		end

		if Indent then
			local Group = { Line }
			local j = i + 1
			while j <= #Output do
				local NextLine = Output[j]
				if not NextLine then
					j += 1
					continue
				end

				local NIndent, NVar, NWaitArg = string.match(NextLine, "^(%s*)local%s+([%w_]+)%s*=%s*task%.wait%((.*)%)$")
				if not NIndent then
					NIndent, NWaitArg = string.match(NextLine, "^(%s*)task%.wait%((.*)%)$")
				end

				if NIndent == Indent and NWaitArg == WaitArg then
					table.insert(Group, NextLine)
					j += 1
				else
					break
				end
			end

			if #Group > 5 then
				table.insert(Result, Indent .. `
				i = j - 1
			else
				table.insert(Result, Line)
			end
		else
			table.insert(Result, Line)
		end
		i += 1
	end
	return Result
end

function Cleanup:Run(Output)
	local Filtered = {}
	for _, Line in Output do
		if Line ~= nil then
			Filtered[#Filtered + 1] = Line
		end
	end

	if IsSafeMode(self.Config) then
		return self:StripComments(Filtered)
	end

	local Result = Filtered

	Result = self:CondenseWaits(Result)
	Result = self:RemoveDuplicateCode(Result)
	Result = self:RemoveJunkNewindex(Result)
	Result = self:RemoveJunkTables(Result)
	Result = self:RemovePrometheusJunk(Result)
	Result = self:RemoveUnusedLiteralLocals(Result)
	Result = self:ReconstructViewSubmitIfElse(Result)
	Result = self:InlineVariables(Result)
	Result = self:FoldTables(Result)
	Result = self:ReconstructIfElse(Result)
	Result = self:StripComments(Result)

	return Result
end

function Cleanup:PostProcess(Source)
	Source = self:RemoveBlanks(Source)
	return Source
end

return Cleanup