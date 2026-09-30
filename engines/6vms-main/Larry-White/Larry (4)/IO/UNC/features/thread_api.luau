local TypeGuards = require("../util/typeguards")
local Constants = require("../../../Data/Constants")
local SourceSanitizer = require("../../../Utils/SourceSanitizer")

local ThreadApi = {}

function ThreadApi.Build(Ctx, Emitter, Beautifier)

	return {
		gethwid = function()
			return Ctx.HwidValue
		end,

		getthreadidentity = function()
			return Ctx.ThreadIdentity
		end,

		setthreadidentity = function(Level)
			if typeof(Level) ~= "number" then error("invalid argument #1 to 'setthreadidentity' (number expected)") end
			if Level ~= Level or Level == math.huge or Level == -math.huge or math.floor(Level) ~= Level then
				error("invalid argument #1 to 'setthreadidentity' (integer expected)")
			end
			Ctx.ThreadIdentity = Level
			Emitter:Append(`setthreadidentity({Beautifier:Beautify(Level)})`)
		end,

		identifyexecutor = function()
			return Constants.Executor.Name, Constants.Executor.Version
		end,

		printidentity = function()
			return "Larry-UNC"
		end,

		checkcaller = function()
			return true
		end,

		isluau = function(Func)
			return true
		end,

		getfunctionhash = function(Func)
			if typeof(Func) ~= "function" then error("invalid argument #1 to 'getfunctionhash' (function expected)") end
			return TypeGuards.MakeHexDigest(Func, 96)
		end,

		getcallstack = function(Level)
			local stack = {}
			local l = (Level or 1) + 1
			for i = l, l + 10 do
				local src = debug.info(i, "s")
				if not src then break end
				local name = debug.info(i, "n")
				local line = debug.info(i, "l")
				local _, shortSrc = SourceSanitizer.SanitizeDebugSource(src)
				table.insert(stack, {
					source = shortSrc,
					name = name or "",
					currentline = line or -1,
				})
			end
			return stack
		end,

		readbinarystring = function(Target, Property)
			if typeof(Target) == "string" then
				return Target
			end
			if (typeof(Target) == "table" or typeof(Target) == "Instance") and typeof(Property) == "string" then
				local Ok, Value = pcall(function()
					return (Target :: any)[Property]
				end)
				if not Ok or Value == nil then
					return ""
				end
				if typeof(Value) == "string" then
					return Value
				end
				return tostring(Value)
			end
			error("invalid argument #1 to 'readbinarystring' (string expected)")
		end,
	}
end

return ThreadApi