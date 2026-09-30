local Register = {}

function Register.register_global(Env, Name, Value)
	if typeof(Env) ~= "table" then
		return
	end
	Env[Name] = Value
end

function Register.register_alias(Env, AliasName, CanonicalName)
	if typeof(Env) ~= "table" then
		return
	end
	if Env[AliasName] ~= nil then
		return
	end
	local Target = Env[CanonicalName]
	if Target ~= nil then
		Env[AliasName] = Target
	end
end

function Register.register_optional(Env, Name, Builder)
	if typeof(Env) ~= "table" or typeof(Name) ~= "string" then
		return
	end
	if Env[Name] ~= nil then
		return
	end
	if typeof(Builder) == "function" then
		Env[Name] = Builder
	end
end

function Register.MarkBuiltin(Context, Func)
	if typeof(Context) ~= "table" or typeof(Func) ~= "function" then
		return
	end
	local Set = Context.builtin_cclosures
	if typeof(Set) == "table" then
		Set[Func] = true
	end
end

return Register