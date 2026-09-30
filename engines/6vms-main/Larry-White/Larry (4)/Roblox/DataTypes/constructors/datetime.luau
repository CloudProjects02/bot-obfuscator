local Legacy = require("../legacy_impl")

local Module = {}
local Names = {"DateTime"}

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