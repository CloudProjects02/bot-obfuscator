local RuntimeEnv = {}

function RuntimeEnv.BuildDeps(SessionState, SessionProxy, SessionEmitter, SessionBeautifier, SessionScope, Cfg, Hooks, SessionIteration, LoaderResult, Pristine, Obfuscator)
	return {
		State = SessionState,
		Proxy = SessionProxy,
		Emitter = SessionEmitter,
		Beautifier = SessionBeautifier,
		Scope = SessionScope,
		Config = Cfg,
		Hooks = Hooks,
		Iteration = SessionIteration,
		Loaders = LoaderResult,
		TrueEnv = getfenv(),
		Pristine = Pristine,
		Obfuscator = Obfuscator,
	}
end

function RuntimeEnv.AttachShared(Hooks, SharedResult)
	if typeof(Hooks) ~= "table" or typeof(SharedResult) ~= "table" then
		return
	end

	if Hooks.getgenv == nil then
		Hooks.getgenv = SharedResult.getgenv
	end
	if Hooks.shared == nil then
		Hooks.shared = SharedResult.shared
	end
	if Hooks._G == nil then
		Hooks._G = SharedResult._G
	end
end

function RuntimeEnv.BuildLocked(StandardEnv, Deps)
	return StandardEnv.Build(Deps)
end

return RuntimeEnv