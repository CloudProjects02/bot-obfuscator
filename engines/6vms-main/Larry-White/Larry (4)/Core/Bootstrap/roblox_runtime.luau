local RobloxRuntime = {}

function RobloxRuntime.Init(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Constants, HierarchyMod, Services, InstanceMod, DataTypes, Enums, HTTP, Signals, Config, Reconstruction)
	Enums.Init()
	HTTP.Init(Constants.IgnoredUrls)
	Signals.Configure(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Config, Reconstruction)
	local GameRoot, ScriptInstance = HierarchyMod.Init(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope, Config)
	Services.Init(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	InstanceMod.Configure(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	DataTypes.Init(SessionProxy, SessionState, SessionEmitter, SessionBeautifier, SessionScope)
	local DataTypeConstructors = DataTypes.BuildAll()

	return {
		GameRoot = GameRoot,
		ScriptInstance = ScriptInstance,
		DataTypeConstructors = DataTypeConstructors,
	}
end

return RobloxRuntime