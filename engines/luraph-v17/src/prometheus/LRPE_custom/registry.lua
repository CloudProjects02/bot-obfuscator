local Registry = {
    macros = {}
}

function Registry.register(name, handler)
    assert(
        type(name) == "string",
        "LRPE macro name must be a string"
    )

    assert(
        type(handler) == "function",
        "LRPE macro handler must be a function"
    )

    Registry.macros[name] = handler
end

function Registry.get(name)
    return Registry.macros[name]
end

function Registry.has(name)
    return Registry.macros[name] ~= nil
end

return Registry