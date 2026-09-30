local Module = {}

function Module.Apply(Env, Hooks)
	if typeof(Env) ~= "table" or typeof(Hooks) ~= "table" then
		return Env
	end

	local Names = {
		"getfenv",
		"setfenv",
		"loadstring",
		"newproxy",
		"getgenv",
		"getrenv",
		"getsenv",
		"getreg",
		"setreadonly",
		"isreadonly",
		"pcall",
		"xpcall",
		"ypcall",
		"settings",
	}

	for _, Name in ipairs(Names) do
		if Env[Name] == nil and Hooks[Name] ~= nil then
			Env[Name] = Hooks[Name]
		end
	end

	return Env
end

return Module