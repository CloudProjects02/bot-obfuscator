local IdentityUtil = require("../../Utils/Identity")
local Constants = require("../../Data/Constants")

local Context = {}

function Context.new()
	return {
		HwidValue = IdentityUtil.Generate(Constants.HwidLength),
		GcTables = {},
		Flags = {},
		ThreadIdentity = 7,
		cloneref_map = {},
		raw_metatables = setmetatable({}, { __mode = "k" }),
		readonly_tables = setmetatable({}, { __mode = "k" }),
		synthetic_metatable_fields = setmetatable({}, { __mode = "k" }),
		scriptable_props = setmetatable({}, { __mode = "k" }),
		hidden_props = setmetatable({}, { __mode = "k" }),
		ClipboardContent = "",
		FpsCap = 60,
		DrawingCache = {},
		hooked_functions = {},
		hooked_metamethods = {},
		original_functions = {},
		cclosure_registry = {},
		builtin_cclosures = setmetatable({}, { __mode = "k" }),
		genv_shared = {},
		renv_shared = nil,
		module_require_cache = setmetatable({}, { __mode = "k" }),
		namecall_states = setmetatable({}, { __mode = "k" }),
		namecall_override_method = nil,
		native_setmetatable = setmetatable,
		native_getmetatable = getmetatable,
		native_pcall = pcall,
		native_xpcall = xpcall,
		lastNamecallMethod = "GetService",
		FileContents = {},
		Folders = {},
		noop = function() end,
	}
end

return Context