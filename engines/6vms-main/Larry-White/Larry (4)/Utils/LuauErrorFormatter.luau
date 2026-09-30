local SourceSanitizer = require("./SourceSanitizer")
local ErrorSanitizer = require("./ErrorSanitizer")

local LuauErrorFormatter = {}

local function NormalizeMessage(Message)
	if typeof(Message) ~= "string" then
		return tostring(Message)
	end

	local Clean = string.gsub(Message, "\r", "")
	Clean = string.gsub(Clean, "^%s+", "")
	Clean = string.gsub(Clean, "%s+$", "")
	return Clean
end

local function ParseLocation(Line)
	if typeof(Line) ~= "string" then
		return nil, nil, nil
	end

	local File, LineNo, Tail = string.match(Line, "^%[string%s+\"([^\"]+)\"%]:(%d+):%s*(.*)$")
	if File then
		return File, tonumber(LineNo), Tail
	end

	File, LineNo, Tail = string.match(Line, "^([^:\n]+):(%d+):%s*(.*)$")
	if File then
		return File, tonumber(LineNo), Tail
	end

	return nil, nil, nil
end

local function SplitLines(Text)
	local Out = {}
	for Line in string.gmatch(Text .. "\n", "(.-)\n") do
		Out[#Out + 1] = Line
	end
	return Out
end

function LuauErrorFormatter.Format(Message, Debug, Options)
	Options = typeof(Options) == "table" and Options or {}

	local Sanitized = ErrorSanitizer.Sanitize(NormalizeMessage(Message), true)
	local Lines = SplitLines(Sanitized)
	local PrimaryLine = ""
	local FileName = nil
	local LineNumber = nil
	local PrimaryMessage = nil

	for _, Line in ipairs(Lines) do
		local Trimmed = NormalizeMessage(Line)
		if Trimmed == "" then
			continue
		end

		if PrimaryLine == "" then
			PrimaryLine = Trimmed
		end

		local ParsedFile, ParsedLine, ParsedMessage = ParseLocation(Trimmed)
		if ParsedFile ~= nil then
			FileName = ParsedFile
			LineNumber = ParsedLine
			PrimaryMessage = NormalizeMessage(ParsedMessage)
			break
		end
	end

	if PrimaryLine == "" then
		PrimaryLine = NormalizeMessage(Sanitized)
	end

	if PrimaryMessage == nil or PrimaryMessage == "" then
		PrimaryMessage = PrimaryLine
	end

	local Label = SourceSanitizer.SanitizeFileLabel(FileName)
	if not Label then
		Label = SourceSanitizer.SanitizeFileLabel(Options.defaultFile)
	end
	if not Label then
		Label = "LocalScript"
	end

	if typeof(LineNumber) ~= "number" then
		LineNumber = tonumber(Options.defaultLine) or 1
	end

	local Compact = `{Label}:{LineNumber}: {PrimaryMessage}`
	if not Debug then
		return Compact
	end

	local StackLines = {}
	for _, Line in ipairs(Lines) do
		local Trimmed = NormalizeMessage(Line)
		if Trimmed == "" then
			continue
		end
		if Trimmed == PrimaryLine then
			continue
		end
		StackLines[#StackLines + 1] = Trimmed
	end

	if #StackLines == 0 then
		return Compact
	end

	return Compact .. "\n" .. table.concat(StackLines, "\n")
end

return LuauErrorFormatter