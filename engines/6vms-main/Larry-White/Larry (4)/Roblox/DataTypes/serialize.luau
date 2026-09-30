local Legacy = require("./legacy_impl")

local Serialize = {}

function Serialize.Encode(Value, Beautifier, Indent)
	return Legacy.Beautify(Value, Beautifier, Indent)
end

function Serialize.Beautify(Value, Beautifier, Indent)
	return Legacy.Beautify(Value, Beautifier, Indent)
end

return Serialize