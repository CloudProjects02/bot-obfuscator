local Module = {}

function Module.Apply(Env, Hooks)
	if typeof(Env) ~= "table" or typeof(Hooks) ~= "table" then
		return Env
	end

	if Env.debug == nil and Hooks.debug ~= nil then
		Env.debug = Hooks.debug
	end

	return Env
end

return Module