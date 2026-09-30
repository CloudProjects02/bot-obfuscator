local OriginalPrint = print
local Info = debug.info
local SourceSanitizer = require("./SourceSanitizer")

local Logger = {}

local Enabled = true
local LogMore = false
local UnnamedCounter = 0

local function Color(Text, Code)
	return `\27[{Code}m{Text}\27[0m`
end

local function SanitizeSource(Name)
	return SourceSanitizer.SanitizeFileLabel(Name)
end

function Logger.SetEnabled(State)
	Enabled = State
end

function Logger.SetLogMore(State)
	LogMore = State
end

function Logger.GetLogMore()
	return LogMore
end

function Logger.IsEnabled()
	return Enabled
end

function Logger.GenerateUnnamed()
	UnnamedCounter += 1
	return UnnamedCounter
end

function Logger.Print(...)
	if not Enabled then return end

	local Line, Name = Info(2, "ln")
	local CleanName = SanitizeSource(Name)

	if CleanName then
		local DisplayName = Color(CleanName, 32)
		local DisplayLine = Color(`line {Line}`, 35)
		OriginalPrint(`[ {DisplayName} @ {DisplayLine} ]:`, ...)
	else
		OriginalPrint(...)
	end
end

function Logger.Raw(...)
	OriginalPrint(...)
end

function Logger.Override()
	print = Logger.Print
end

function Logger.Restore()
	print = OriginalPrint
end

Logger.Color = Color
Logger.DebugInfo = Info

return Logger