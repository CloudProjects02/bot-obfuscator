local Legacy = require("./Standard/legacy_impl")

Legacy.TypeFuncs = require("./Standard/type_funcs")
Legacy.Logging = require("./Standard/logging")
Legacy.Globals = require("./Standard/globals")
Legacy.DebugBridge = require("./Standard/debug_bridge")
Legacy.MetatablePolicy = require("./Standard/metatable_policy")

return Legacy