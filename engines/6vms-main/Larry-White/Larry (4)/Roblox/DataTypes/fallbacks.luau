local Legacy = require("./legacy_impl")

local Fallbacks = {}

function Fallbacks.Get(TypeName)
	local All = Legacy.BuildAll()
	return All[TypeName]
end

function Fallbacks.GetAll()
	return Legacy.BuildAll()
end

return Fallbacks