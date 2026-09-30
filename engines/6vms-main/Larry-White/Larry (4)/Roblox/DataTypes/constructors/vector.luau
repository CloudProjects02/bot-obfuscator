local Legacy = require("../legacy_impl")

local Module = {}
local Names = {"Vector2", "Vector3", "Vector2int16", "Vector3int16"}

function Module.GetNames()
	local Out = {}
	for _, Name in ipairs(Names) do
		Out[#Out + 1] = Name
	end
	return Out
end

function Module.Build()
	local All = Legacy.BuildAll()
	local Out = {}
	for _, Name in ipairs(Names) do
		if All[Name] ~= nil then
			Out[Name] = All[Name]
		end
	end
	return Out
end

return Module