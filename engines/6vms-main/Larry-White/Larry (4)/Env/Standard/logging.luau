local Module = {}

function Module.Apply(Env, Hooks)
	if typeof(Env) ~= "table" or typeof(Hooks) ~= "table" then
		return Env
	end
	if Env.print == nil and Hooks.print ~= nil then
		Env.print = Hooks.print
	end
	if Env.warn == nil and Hooks.warn ~= nil then
		Env.warn = Hooks.warn
	end
	if Env.error == nil and Hooks.error ~= nil then
		Env.error = Hooks.error
	end
	return Env
end

return Module