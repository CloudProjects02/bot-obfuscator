local MacroSystem = {}

function MacroSystem.new(State, Config)
	local Self = setmetatable({}, { __index = MacroSystem })
	Self.State = State
	Self.Config = Config
	Self.RegisteredMacros = {}
	Self.Loaded = false
	Self.PcallBlocked = {}
	return Self
end

function MacroSystem:Register(Name, Handler)
	self.RegisteredMacros[Name] = Handler
end

function MacroSystem:Has(Name)
	return self.RegisteredMacros[Name] ~= nil
end

function MacroSystem:Execute(Name, ...)
	local Handler = self.RegisteredMacros[Name]

	if not Handler then
		error(`Macro '{Name}' is not registered`)
	end

	return Handler(...)
end

function MacroSystem:Load(MacroString, Env)
	if self.Loaded then
		error("Macros have already been loaded")
	end

	if typeof(MacroString) ~= "string" then
		error("invalid argument #1 to 'loadmacros' (string expected)")
	end

	local MacroEnv = {}

	for Name, Handler in next, self.RegisteredMacros do
		MacroEnv[Name] = Handler
	end

	if Env then
		setmetatable(MacroEnv, { __index = Env })
	end

	local luau = require("@lune/luau")
	local Func = luau.load(MacroString)

	if not Func then
		error("Failed to parse macro string")
	end

	setfenv(Func, MacroEnv)

	local S, E = pcall(Func)

	if not S then
		error(`Macro execution failed: {E}`)
	end

	self.Loaded = true
end

function MacroSystem:BlockInPcall(Name)
	self.PcallBlocked[Name] = true
end

function MacroSystem:IsBlockedInPcall(Name)
	return self.PcallBlocked[Name] == true
end

function MacroSystem:Clear()
	table.clear(self.RegisteredMacros)
	self.Loaded = false
end

return MacroSystem