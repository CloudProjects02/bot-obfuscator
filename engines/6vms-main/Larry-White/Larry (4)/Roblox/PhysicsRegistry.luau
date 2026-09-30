local PhysicsRegistry = {}

local TouchMap = setmetatable({}, { __mode = "k" })
local JointMap = setmetatable({}, { __mode = "k" })

local function GetSet(Map, Key)
	local Set = Map[Key]
	if Set == nil then
		Set = setmetatable({}, { __mode = "k" })
		Map[Key] = Set
	end
	return Set
end

function PhysicsRegistry.AddTouch(PartA, PartB)
	if typeof(PartA) ~= "table" or typeof(PartB) ~= "table" then
		return
	end
	if PartA == PartB then
		return
	end
	GetSet(TouchMap, PartA)[PartB] = true
	GetSet(TouchMap, PartB)[PartA] = true
end

function PhysicsRegistry.RemoveTouch(PartA, PartB)
	if typeof(PartA) ~= "table" or typeof(PartB) ~= "table" then
		return
	end
	local SetA = TouchMap[PartA]
	if SetA then
		SetA[PartB] = nil
	end
	local SetB = TouchMap[PartB]
	if SetB then
		SetB[PartA] = nil
	end
end

function PhysicsRegistry.GetTouches(Part)
	local Set = TouchMap[Part]
	if Set == nil then
		return {}
	end
	local Out = {}
	for Other in next, Set do
		if Other ~= nil then
			table.insert(Out, Other)
		end
	end
	return Out
end

function PhysicsRegistry.AddJoint(PartA, PartB)
	if typeof(PartA) ~= "table" or typeof(PartB) ~= "table" then
		return
	end
	if PartA == PartB then
		return
	end
	GetSet(JointMap, PartA)[PartB] = true
	GetSet(JointMap, PartB)[PartA] = true
end

function PhysicsRegistry.RemoveJoints(Part)
	local Set = JointMap[Part]
	if Set == nil then
		return
	end
	for Other in next, Set do
		local OtherSet = JointMap[Other]
		if OtherSet then
			OtherSet[Part] = nil
		end
	end
	JointMap[Part] = nil
end

function PhysicsRegistry.GetJointNeighbors(Part)
	local Set = JointMap[Part]
	if Set == nil then
		return {}
	end
	local Out = {}
	for Other in next, Set do
		if Other ~= nil then
			table.insert(Out, Other)
		end
	end
	return Out
end

return PhysicsRegistry