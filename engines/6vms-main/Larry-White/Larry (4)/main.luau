local Config = require("./Config")
local Decoder = require("./Core/Decoder")
local Logger = require("./Utils/Logger")
local StringUtil = require("./Utils/String")
local LuauErrorFormatter = require("./Utils/LuauErrorFormatter")

Logger.Override()

local InputFile = Config.Settings.input or "input.lua"

local args = require("@lune/process").args
local i = 1

while i <= #args do
	local arg = args[i]
	if arg == "-i" or arg == "
		InputFile = args[i + 1]
		i += 1
	elseif arg == "-o" or arg == "
		Config.Settings.outfile = args[i + 1]
		i += 1
	elseif arg == "
		Config.Settings.gameid = StringUtil.ToValue(args[i + 1])
		i += 1
	elseif arg == "
		Config.Settings.placeid = StringUtil.ToValue(args[i + 1])
		i += 1
	elseif arg == "-debug" or arg == "
		Config.Settings.debug = true
	elseif not string.match(arg, "^%-") and InputFile == (Config.Settings.input or "input.lua") then
		InputFile = arg
	end
	i += 1
end

local Ok, Result, Elapsed, TracerSuccess = pcall(Decoder.Decode, InputFile, Config.Settings)

if Ok then
	if TracerSuccess then
		Logger.Print(`{Config.Name} v{Config.Version} completed in {Elapsed or 0}s`)
	else
		local Msg = LuauErrorFormatter.Format(Result, Config.Settings.debug, {
			defaultFile = InputFile,
		})
		Logger.Print(`{Config.Name} v{Config.Version} failed:`, Msg)
	end
else
	local Msg = LuauErrorFormatter.Format(Result, Config.Settings.debug, {
		defaultFile = InputFile,
	})
	Logger.Print(`{Config.Name} v{Config.Version} crashed:`, Msg)
end

return Decoder