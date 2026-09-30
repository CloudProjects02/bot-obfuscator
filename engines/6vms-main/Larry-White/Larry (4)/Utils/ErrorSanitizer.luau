local ErrorSanitizer = {}
local SourceSanitizer = require("./SourceSanitizer")

local SourceRoots = {
	"Core/",
	"CodeGen/",
	"Env/",
	"Flow/",
	"Hooks/",
	"IO/",
	"Libs/",
	"Macros/",
	"PostProcess/",
	"Roblox/",
	"Utils/",
	"Data/",
}

local function IsInternalFrame(Line)
	if typeof(Line) ~= "string" or Line == "" then
		return false
	end

	for _, Root in ipairs(SourceRoots) do
		if string.find(Line, Root, 1, true) then
			return true
		end
	end

	if string.match(Line, "^main:%d+$") then
		return true
	end

	if string.match(Line, "^main%.lua[u]?:%d+$") then
		return true
	end

	if string.match(Line, "^larry%.run:%d+$") then
		return true
	end

	return false
end

function ErrorSanitizer.Sanitize(Message, Debug)
	if typeof(Message) ~= "string" then
		return Message
	end

	local Result = SourceSanitizer.SanitizeTraceText(Message)

	local Lines = string.split(Result, "\n")
	local FinalLines = {}
	local StrippedCount = 0

	for _, Line in ipairs(Lines) do
		local IsInternal = IsInternalFrame(Line)

		if not Debug and IsInternal then
			StrippedCount += 1

		else

			local CleanLine = SourceSanitizer.SanitizeTraceText(Line)
			table.insert(FinalLines, CleanLine)
		end
	end

	return table.concat(FinalLines, "\n")
end

return ErrorSanitizer