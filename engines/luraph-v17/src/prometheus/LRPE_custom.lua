local Registry =
    require("prometheus.LRPE_custom.registry")

local Processor =
    require("prometheus.LRPE_custom.processor")

local Macros =
    require("prometheus.LRPE_custom.macros")

Macros.registerAll(Registry)

local LRPE = {}

function LRPE.process(ast, options)
    return Processor.process(
        ast,
        Registry,
        options
    )
end

function LRPE.register(name, handler)
    Registry.register(
        name,
        handler
    )
end

function LRPE.get(name)
    return Registry.get(name)
end

return LRPE