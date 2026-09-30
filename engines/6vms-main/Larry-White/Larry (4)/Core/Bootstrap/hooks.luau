local Hooks = {}

function Hooks.New()
	return {}
end

function Hooks.Merge(Target, Source)
	if typeof(Target) ~= "table" or typeof(Source) ~= "table" then
		return Target
	end

	for K, V in next, Source do
		Target[K] = V
	end

	return Target
end

function Hooks.MergeMany(Target, ...)
	for I = 1, select("#", ...) do
		Hooks.Merge(Target, select(I, ...))
	end
	return Target
end

return Hooks