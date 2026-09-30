local Legacy = require("./legacy_impl")

local Core = {}

function Core.Configure(Proxy, State, Emitter, Beautifier, Scope)
	return Legacy.Configure(Proxy, State, Emitter, Beautifier, Scope)
end

function Core.New(ClassName, Parent)
	return Legacy.new(ClassName, Parent)
end

function Core.InternalNew(ClassName, Properties, Proxy, State, Emitter, Beautifier, Scope, InternalBypass)
	return Legacy._new(ClassName, Properties, Proxy, State, Emitter, Beautifier, Scope, InternalBypass)
end

function Core.FromExisting(Existing, Proxy, State, Emitter, Beautifier, Scope)
	return Legacy.FromExisting(Existing, Proxy, State, Emitter, Beautifier, Scope)
end

function Core.GetCreated()
	return Legacy.GetCreated()
end

function Core.ResetCreated()
	return Legacy.ResetCreated()
end

return Core