local Legacy = require("./legacy_impl")

local Bridge = {}

function Bridge.GetProperty(Inst, Name)
	return Legacy.GetProperty(Inst, Name)
end

function Bridge.SetProperty(Inst, Name, Value)
	return Legacy.SetProperty(Inst, Name, Value)
end

function Bridge.GetPropertyVersion(Inst, Name)
	return Legacy.GetPropertyVersion(Inst, Name)
end

function Bridge.HasProperty(Inst, Name)
	return Legacy.HasProperty(Inst, Name)
end

function Bridge.Index(Inst, Key)
	return Legacy.__index(Inst, Key)
end

function Bridge.NewIndex(Inst, Key, Value)
	return Legacy.__newindex(Inst, Key, Value)
end

return Bridge