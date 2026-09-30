local PhysicsRegistry = require("../../PhysicsRegistry")

local BasePart = {}

local function MakeVector3(X, Y, Z)
	local Ok, Value = pcall(function()
		local DataTypes = require("../../DataTypes")
		local Vector3Lib = DataTypes.Get("Vector3")
		if typeof(Vector3Lib) == "table" and typeof(Vector3Lib.new) == "function" then
			return Vector3Lib.new(X, Y, Z)
		end
		return nil
	end)
	if Ok and Value ~= nil then
		return Value
	end
	return { X = X, Y = Y, Z = Z, __larryType = "Vector3" }
end

local function ReadVector3(Value)
	if typeof(Value) == "Vector3" then
		return Value.X, Value.Y, Value.Z
	end
	if typeof(Value) == "table" then
		local X = rawget(Value, "X")
		local Y = rawget(Value, "Y")
		local Z = rawget(Value, "Z")
		if typeof(X) == "number" and typeof(Y) == "number" and typeof(Z) == "number" then
			return X, Y, Z
		end
	end
	return 0, 0, 0
end

local function VectorAdd(A, B)
	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	return MakeVector3(AX + BX, AY + BY, AZ + BZ)
end

local function VectorScale(A, Scale)
	local AX, AY, AZ = ReadVector3(A)
	return MakeVector3(AX * Scale, AY * Scale, AZ * Scale)
end

local function GetPropertySafe(Inst, Name)
	if typeof(Inst) == "table" then
		local Ok, Value = pcall(function()
			return Inst[Name]
		end)
		if Ok then
			return Value
		end

		if typeof(Inst.GetProperty) == "function" then
			local RawOk, RawValue = pcall(Inst.GetProperty, Inst, Name)
			if RawOk then
				return RawValue
			end
		end
	end
	return nil
end

local function SetPropertySafe(Inst, Name, Value)
	if typeof(Inst) == "table" and typeof(Inst.SetProperty) == "function" then
		pcall(Inst.SetProperty, Inst, Name, Value)
	end
end

local function ComputeMass(Inst)
	if GetPropertySafe(Inst, "Massless") == true then
		return 0
	end

	local MassProp = GetPropertySafe(Inst, "Mass")
	if typeof(MassProp) == "number" and MassProp > 0 then
		return MassProp
	end

	local Size = GetPropertySafe(Inst, "Size")
	local SX, SY, SZ = ReadVector3(Size)
	local Volume = math.abs(SX * SY * SZ)
	if Volume == 0 then
		return 0
	end

	local Density = nil
	local Custom = GetPropertySafe(Inst, "CustomPhysicalProperties")
	if typeof(Custom) == "table" and typeof(rawget(Custom, "Density")) == "number" then
		Density = rawget(Custom, "Density")
	end
	if Density == nil then
		local D = GetPropertySafe(Inst, "Density")
		if typeof(D) == "number" then
			Density = D
		end
	end
	if Density == nil then
		Density = 0.7
	end

	local Mass = Volume * Density
	if Mass ~= Mass or Mass < 0 then
		Mass = 0
	end
	return Mass
end

function BasePart.Register(Methods, Fallbacks)
	local function RegisterFor(ClassName)
		Methods.Register(ClassName, "GetTouchingParts", function(Inst)
			return PhysicsRegistry.GetTouches(Inst)
		end)

		Methods.Register(ClassName, "GetConnectedParts", function(Inst, Recursive)
			local function GetConstraintNeighbors(Part, Out, Seen)
				local Parent = GetPropertySafe(Part, "Parent")
				if typeof(Parent) ~= "table" or typeof(Parent.GetDescendants) ~= "function" then
					return
				end
				local Ok, Descendants = pcall(Parent.GetDescendants, Parent)
				if not Ok or typeof(Descendants) ~= "table" then
					return
				end
				for _, Obj in ipairs(Descendants) do
					if Obj ~= nil and Obj ~= Part then
						local Part0 = GetPropertySafe(Obj, "Part0")
						local Part1 = GetPropertySafe(Obj, "Part1")
						if Part0 == Part and Part1 ~= nil and Seen[Part1] ~= true then
							Seen[Part1] = true
							table.insert(Out, Part1)
						elseif Part1 == Part and Part0 ~= nil and Seen[Part0] ~= true then
							Seen[Part0] = true
							table.insert(Out, Part0)
						end
					end
				end
			end

			local Result = {}
			local Seen = { [Inst] = true }

			local function AddNeighbors(Part)
				for _, Other in ipairs(PhysicsRegistry.GetJointNeighbors(Part)) do
					if Other ~= nil and Seen[Other] ~= true then
						Seen[Other] = true
						table.insert(Result, Other)
					end
				end
				GetConstraintNeighbors(Part, Result, Seen)
			end

			if Recursive then
				local Queue = { Inst }
				local Index = 1
				while Index <= #Queue do
					local Current = Queue[Index]
					Index += 1
					local Before = #Result
					AddNeighbors(Current)
					for I = Before + 1, #Result do
						table.insert(Queue, Result[I])
					end
				end
			else
				AddNeighbors(Inst)
			end

			return Result
		end)

		Methods.Register(ClassName, "MakeJoints", function(Inst)
			for _, Other in ipairs(PhysicsRegistry.GetTouches(Inst)) do
				PhysicsRegistry.AddJoint(Inst, Other)
			end
		end)

		Methods.Register(ClassName, "BreakJoints", function(Inst)
			PhysicsRegistry.RemoveJoints(Inst)
		end)

		Methods.Register(ClassName, "GetMass", function(Inst)
			local Mass = ComputeMass(Inst)
			if typeof(Mass) ~= "number" or Mass <= 0 then
				return 1.2
			end
			return Mass
		end)

		Methods.Register(ClassName, "CanCollideWith", function(Inst, OtherPart)
			if typeof(OtherPart) ~= "table" then
				return false
			end
			local CanCollideA = GetPropertySafe(Inst, "CanCollide")
			local CanCollideB = GetPropertySafe(OtherPart, "CanCollide")
			if CanCollideA == false or CanCollideB == false then
				return false
			end
			local CanQueryA = GetPropertySafe(Inst, "CanQuery")
			local CanQueryB = GetPropertySafe(OtherPart, "CanQuery")
			if CanQueryA == false or CanQueryB == false then
				return false
			end
			return true
		end)

		Methods.Register(ClassName, "GetRootPart", function(Inst)
			local Root = GetPropertySafe(Inst, "AssemblyRootPart")
			if typeof(Root) == "table" then
				return Root
			end
			return Inst
		end)

		Methods.Register(ClassName, "SubtractAsync", function(Inst, Parts)
			return Inst:Clone()
		end)

		Methods.Register(ClassName, "UnionAsync", function(Inst, Parts)
			return Inst:Clone()
		end)

		Methods.Register(ClassName, "ApplyImpulse", function(Inst, Force)
			local Mass = ComputeMass(Inst)
			if Mass <= 0 then
				return
			end
			local Velocity = GetPropertySafe(Inst, "AssemblyLinearVelocity") or GetPropertySafe(Inst, "Velocity") or MakeVector3(0, 0, 0)
			local Delta = VectorScale(Force, 1 / Mass)
			local NewVelocity = VectorAdd(Velocity, Delta)
			SetPropertySafe(Inst, "AssemblyLinearVelocity", NewVelocity)
			SetPropertySafe(Inst, "Velocity", NewVelocity)
		end)

		Methods.Register(ClassName, "ApplyAngularImpulse", function(Inst, Torque)
			local Mass = ComputeMass(Inst)
			if Mass <= 0 then
				return
			end
			local Velocity = GetPropertySafe(Inst, "AssemblyAngularVelocity") or GetPropertySafe(Inst, "RotVelocity") or MakeVector3(0, 0, 0)
			local Delta = VectorScale(Torque, 1 / Mass)
			local NewVelocity = VectorAdd(Velocity, Delta)
			SetPropertySafe(Inst, "AssemblyAngularVelocity", NewVelocity)
			SetPropertySafe(Inst, "RotVelocity", NewVelocity)
		end)

		Methods.Register(ClassName, "GetVelocityAtPosition", function(Inst, Position)
			local Velocity = GetPropertySafe(Inst, "AssemblyLinearVelocity") or GetPropertySafe(Inst, "Velocity")
			if Velocity == nil then
				return MakeVector3(0, 0, 0)
			end
			return Velocity
		end)
	end

	RegisterFor("BasePart")
	RegisterFor("Part")
	RegisterFor("MeshPart")
	RegisterFor("WedgePart")
	RegisterFor("CornerWedgePart")
	RegisterFor("TrussPart")
end

return BasePart