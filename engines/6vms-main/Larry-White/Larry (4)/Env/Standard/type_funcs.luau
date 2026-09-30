local Module = {}

function Module.Apply(Env, Hooks)
	if typeof(Env) ~= "table" then
		return Env
	end
	if typeof(Hooks) ~= "table" then
		return Env
	end

	if Env.type == nil and Hooks.type ~= nil then
		Env.type = Hooks.type
	end
	if Env.typeof == nil and Hooks.typeof ~= nil then
		Env.typeof = Hooks.typeof
	end

	return Env
end

return Module