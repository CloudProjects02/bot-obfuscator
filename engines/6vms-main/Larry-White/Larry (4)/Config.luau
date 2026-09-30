local Process = require("@lune/process")

local StringUtil = require("./Utils/String")

local Config = {}

Config.Version = "1"
Config.Name = "Larry"
Config.Defaults = {
	hookOpValue = {
		AND = "spy",
		OR = "spy",
		NOT = "spy",
		LEN = "spy",
		EQ = "spy",
		NEQ = "spy",
		COMP = "spy",
		ARTH = "spy",
		CONCAT = "spy",
		IF = "spy",
		CALL = "spy",
		NAMECALL = "spy",
		INDEX = "spy",
		CHECKINDEX = "spy",
	},
	profile = "fidelity",
	readable_output = true,
	explore_funcs = true,
	ast_reconstruction = true,
	trace_builtins = true,
	vm_mutation_mode = "strict",
	spy_exec_only = true,
	minifier = false,
	varRenamer = false,
	raw = false,
	max_ops = 10000,
	max_while_count = 100000,
	max_pcall_emits = 12,
	max_log_calls = 20000,
	max_repeated_logs = 40,
	max_suppressed_logs = 1000,
	max_log_payload_chars = 600,
	lm = false,
	saveFails = false,
	env_index = false,
	outfile = "out2.lua",
	constant_collection = false,
	constant_source_scan = false,
	constant_limit = 800,
	constant_aliases = false,
	constant_alias_min_uses = 1,
	neverNester = false,
	comment = true,
	nostringlimit = false,
	cleaner = false,
	CHECKINDEX = false,
	disableLogs = false,
	debug = false,
	sanitize_sources = true,
	diagnostics = false,
	execution_timeout_ms = 15000,
	loop_timeout_ms = 2000,
	experimental_vm_shim = false,
	postprocess_safe_mode = true,
}

function Config.Parse(Args)
	local Settings = {}

	for K, V in next, Config.Defaults do
		Settings[K] = V
	end

	for _, Arg in Args do
		local Key, Value = string.match(Arg, "^%-%-([%w_]+)=(.+)$")
		if Key and Value then
			local Converted = StringUtil.ToValue(Value)
			if Key == "hookOpValue" and typeof(Settings.hookOpValue) == "table" and type(Converted) == "string" then
				for K in next, Settings.hookOpValue do
					Settings.hookOpValue[K] = Converted
				end
			else
				Settings[Key] = Converted
			end
		else
			local Flag = string.sub(Arg, 3)
			if #Flag > 0 then
				Settings[Flag] = true
			end
		end
	end

	return Settings
end

function Config.DynamicTimeout(FileSizeKB, BaseTimeout)
	BaseTimeout = BaseTimeout or 60
	local Extra = math.min(math.floor(FileSizeKB / (60 * 1024) * 60), 40)
	return BaseTimeout + Extra
end

Config.Settings = Config.Parse(Process.args)

return Config