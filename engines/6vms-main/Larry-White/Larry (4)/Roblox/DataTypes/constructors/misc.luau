local Legacy = require("../legacy_impl")

local Module = {}
local Names = {"Ray", "Region3", "Region3int16", "TweenInfo", "Font", "Content", "SharedTable", "CatalogSearchParams", "FloatCurve", "FloatCurveKey", "RotationCurveKey", "Axes", "Faces", "RaycastParams", "OverlapParams"}

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