local Predefined = {}

function Predefined.new(State, Config)
	local Self = setmetatable({}, { __index = Predefined })
	Self.State = State
	Self.Config = Config
	Self.Values = {}
	Self.Used = false
	return Self
end

function Predefined:Apply(Definitions)
	if self.Used then
		error("predefine() can only be called once")
	end

	if typeof(Definitions) ~= "table" then
		error("invalid argument #1 to 'predefine' (table expected)")
	end

	for Key, Value in next, Definitions do
		if typeof(Key) ~= "string" then
			error(`predefine key must be a string, got {typeof(Key)}`)
		end

		self.Values[Key] = Value
	end

	self.Used = true
end

function Predefined:Get(Key)
	return self.Values[Key]
end

function Predefined:Has(Key)
	return self.Values[Key] ~= nil
end

function Predefined:GetAll()
	local Copy = {}
	for K, V in next, self.Values do
		Copy[K] = V
	end
	return Copy
end

function Predefined:CreateHandler(MacroSystem)
	local Handler = function(Definitions)
		self:Apply(Definitions)
	end

	MacroSystem:Register("predefine", Handler)
	MacroSystem:BlockInPcall("predefine")

	return Handler
end

return Predefined