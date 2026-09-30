local Table = {}

function Table.IsRecursive(Tbl)
	local Visited = {}

	local function Check(T)
		if Visited[T] then return true end
		Visited[T] = true

		for _, V in next, T do
			if type(V) == "table" and Check(V) then
				return true
			end
		end

		Visited[T] = nil
		return false
	end

	return Check(Tbl)
end

function Table.ResolvePath(Path, ValueMap)
	local Result = Path

	while true do
		local Entry = ValueMap[Result]
		if not Entry or not Entry.Value then break end
		Result = Entry.Value
	end

	return Result
end

function Table.IsJunk(Tbl, IsProxy)
	local ProxyCount, Total = 0, 0

	for K, V in next, Tbl do
		Total += 1
		if IsProxy(K) or IsProxy(V) then
			ProxyCount += 1
		end
	end

	return ProxyCount > 0 and Total - ProxyCount <= 1
end

function Table.CreateTracker()
	local Seen = {}

	return {
		Mark = function(Value, Name)
			Seen[Value] = Name
		end,
		Get = function(Value)
			return Seen[Value]
		end,
		Has = function(Value)
			return Seen[Value] ~= nil
		end,
	}
end

return Table