local Stats = {}

local function GetUsage(Inst)
	local Value = Inst:GetProperty("TotalMemoryUsageMb")
	if typeof(Value) ~= "number" then
		Value = 512
	end
	if Value < 16 then
		Value = 16
	end
	return Value
end

function Stats.Register(Methods)
	Methods.Register("Stats", "GetTotalMemoryUsageMb", function(Inst)
		return GetUsage(Inst)
	end)

	Methods.Register("StatsService", "GetTotalMemoryUsageMb", function(Inst)
		return GetUsage(Inst)
	end)
end

return Stats