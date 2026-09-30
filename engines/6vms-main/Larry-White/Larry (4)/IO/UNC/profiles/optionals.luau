local Optionals = {}

local OPTIONAL_STUBS = {
	gethostenv = function(Context)
		if Context and Context.LockedEnv then
			return Context.LockedEnv
		end
		local Ok, Env = pcall(getfenv)
		if Ok and typeof(Env) == "table" then
			return Env
		end
		return {}
	end,
	setstackhidden = function(...)
		return nil
	end,
	isexecutorclosure = function(F)
		return typeof(F) == "function"
	end,
	isfunctionhooked = function()
		return false
	end,
}

function Optionals.Apply(Env, Context)
	for Name, Stub in next, OPTIONAL_STUBS do
		if Env[Name] == nil then
			Env[Name] = function(...)
				return Stub(Context, ...)
			end
		end
	end
end

return Optionals