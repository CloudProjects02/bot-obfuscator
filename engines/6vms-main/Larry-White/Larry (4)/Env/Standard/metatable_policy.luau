local Module = {}

function Module.Apply(Env, Hooks)
	if typeof(Env) ~= "table" or typeof(Hooks) ~= "table" then
		return Env
	end

	if Env.getmetatable == nil and Hooks.getmetatable ~= nil then
		Env.getmetatable = Hooks.getmetatable
	end
	if Env.setmetatable == nil and Hooks.setmetatable ~= nil then
		Env.setmetatable = Hooks.setmetatable
	end

	return Env
end

return Module