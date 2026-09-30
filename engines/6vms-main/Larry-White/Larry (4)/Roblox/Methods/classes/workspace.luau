local Workspace = {}

local function GetConstructor(TypeName)
	local DataTypes = require("../../DataTypes")
	local Lib = DataTypes.Get(TypeName)
	if typeof(Lib) == "table" and typeof(Lib.new) == "function" then
		return Lib.new
	end
	return nil
end

local function MakeVector3(X, Y, Z)
	local New = GetConstructor("Vector3")
	if New then
		local Ok, Value = pcall(New, X, Y, Z)
		if Ok and Value ~= nil then
			return Value
		end
	end
	return { X = X, Y = Y, Z = Z }
end

local function MakeColor3(R, G, B)
	local New = GetConstructor("Color3")
	if New then
		local Ok, Value = pcall(New, R, G, B)
		if Ok and Value ~= nil then
			return Value
		end
	end
	return { R = R, G = G, B = B, __larryType = "Color3" }
end

local function Unwrap(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

local function ReadVector3(Value)
	local Target = Unwrap(Value)
	if typeof(Target) == "Vector3" then
		return Target.X, Target.Y, Target.Z
	end
	if typeof(Target) == "table" then
		local X = tonumber(rawget(Target, "X"))
		local Y = tonumber(rawget(Target, "Y"))
		local Z = tonumber(rawget(Target, "Z"))
		if X ~= nil and Y ~= nil and Z ~= nil then
			return X, Y, Z
		end

		local Position = rawget(Target, "Position")
		if typeof(Position) == "table" then
			local Px = tonumber(rawget(Position, "X"))
			local Py = tonumber(rawget(Position, "Y"))
			local Pz = tonumber(rawget(Position, "Z"))
			if Px ~= nil and Py ~= nil and Pz ~= nil then
				return Px, Py, Pz
			end
		end
	end
	return 0, 0, 0
end

local function AabbIntersects(CenterAX, CenterAY, CenterAZ, SizeAX, SizeAY, SizeAZ, CenterBX, CenterBY, CenterBZ, SizeBX, SizeBY, SizeBZ)
	local HalfAX = math.abs(SizeAX) * 0.5
	local HalfAY = math.abs(SizeAY) * 0.5
	local HalfAZ = math.abs(SizeAZ) * 0.5
	local HalfBX = math.abs(SizeBX) * 0.5
	local HalfBY = math.abs(SizeBY) * 0.5
	local HalfBZ = math.abs(SizeBZ) * 0.5

	return math.abs(CenterAX - CenterBX) <= (HalfAX + HalfBX)
		and math.abs(CenterAY - CenterBY) <= (HalfAY + HalfBY)
		and math.abs(CenterAZ - CenterBZ) <= (HalfAZ + HalfBZ)
end

local function IsDescendantOrSelf(Inst, Root)
	if Inst == Root then
		return true
	end
	if typeof(Inst) == "table" and typeof(Inst.IsDescendantOf) == "function" then
		local Ok, Result = pcall(Inst.IsDescendantOf, Inst, Root)
		if Ok then
			return Result == true
		end
	end
	return false
end

local function NormalizeFilterType(FilterType)
	local Value = Unwrap(FilterType)
	if typeof(Value) == "table" then
		Value = rawget(Value, "_Name") or rawget(Value, "Name")
	end
	local Name = string.lower(tostring(Value or ""))
	if Name == "include" or Name == "whitelist" then
		return "include"
	end
	if Name == "exclude" or Name == "blacklist" then
		return "exclude"
	end
	return "exclude"
end

local function MatchesFilter(Part, FilterType, FilterList)
	if typeof(FilterList) ~= "table" or #FilterList == 0 then
		return FilterType ~= "include"
	end

	local Matched = false
	for _, Candidate in ipairs(FilterList) do
		if Candidate ~= nil and IsDescendantOrSelf(Part, Candidate) then
			Matched = true
			break
		end
	end

	if FilterType == "include" then
		return Matched
	end
	return not Matched
end

local function GetWorkspaceParts(Inst)
	local Parts = {}
	if typeof(Inst) ~= "table" or typeof(Inst.GetDescendants) ~= "function" then
		return Parts
	end

	for _, Candidate in ipairs(Inst:GetDescendants()) do
		if typeof(Candidate) == "table" and Candidate.IsA and Candidate:IsA("BasePart") and Candidate:GetParent() ~= nil then
			Parts[#Parts + 1] = Candidate
		end
	end

	return Parts
end

local function ReadPartPosition(Part)
	if typeof(Part) ~= "table" or typeof(Part.GetProperty) ~= "function" then
		return 0, 0, 0
	end

	local CFrame = (typeof(Part.GetRawProperty) == "function") and Part:GetRawProperty("CFrame") or nil
	if CFrame == nil then
		CFrame = Part:GetProperty("CFrame")
	end
	if CFrame ~= nil then
		local Cx, Cy, Cz = ReadVector3(CFrame)
		if Cx ~= 0 or Cy ~= 0 or Cz ~= 0 then
			return Cx, Cy, Cz
		end
	end

	local Position = Part:GetProperty("Position")
	return ReadVector3(Position)
end

local function ReadPartSize(Part)
	if typeof(Part) ~= "table" or typeof(Part.GetProperty) ~= "function" then
		return 4, 1, 2
	end

	local Size = Part:GetProperty("Size")
	local X, Y, Z = ReadVector3(Size)
	if X == 0 and Y == 0 and Z == 0 then
		return 4, 1, 2
	end
	return X, Y, Z
end

local function ReadRegionBounds(Region)
	if typeof(Region) ~= "table" then
		return 0, 0, 0, 4, 4, 4
	end

	local Min = rawget(Region, "Min")
	local Max = rawget(Region, "Max")
	local MinX, MinY, MinZ = ReadVector3(Min)
	local MaxX, MaxY, MaxZ = ReadVector3(Max)

	if MaxX < MinX then MinX, MaxX = MaxX, MinX end
	if MaxY < MinY then MinY, MaxY = MaxY, MinY end
	if MaxZ < MinZ then MinZ, MaxZ = MaxZ, MinZ end

	return MinX, MinY, MinZ, MaxX, MaxY, MaxZ
end

function Workspace.Register(Methods, Fallbacks)
	Methods.Register("Workspace", "BulkMoveTo", function(_Inst, Parts, CFrames, _Mode)
		if typeof(Parts) ~= "table" or typeof(CFrames) ~= "table" then
			return
		end

		for Index, Part in ipairs(Parts) do
			local CFrameValue = CFrames[Index]
			if typeof(Part) == "table" and typeof(Part.SetProperty) == "function" and CFrameValue ~= nil then
				local X, Y, Z = ReadVector3(CFrameValue)
				local Position = MakeVector3(X, Y, Z)
				Part:SetProperty("CFrame", CFrameValue)
				Part:SetProperty("Position", Position)
				Part:SetProperty("_LarrySimPosition", Position)
			end
		end
	end)

	Methods.Register("Workspace", "Raycast", function(Inst, Origin, Direction, Params)
		local Enums = require("../../Enums")
		local OX, OY, OZ = ReadVector3(Origin)
		local DX, DY, DZ = ReadVector3(Direction)
		local FilterType = NormalizeFilterType(typeof(Params) == "table" and rawget(Params, "FilterType") or nil)
		local FilterList = typeof(Params) == "table" and rawget(Params, "FilterDescendantsInstances") or nil
		local DefaultSceneNames = {
			Baseplate = true,
			Head = true,
			Torso = true,
			["Left Arm"] = true,
			["Right Arm"] = true,
			["Left Leg"] = true,
			["Right Leg"] = true,
			HumanoidRootPart = true,
		}

		local RayLenSq = DX * DX + DY * DY + DZ * DZ
		if RayLenSq <= 0 then
			return nil
		end
		local RayLen = math.sqrt(RayLenSq)
		local BestT = nil
		local BestPart = nil
		local BestNormal = nil

		local function PreferTie(Part)
			if BestPart == nil or typeof(BestPart.GetName) ~= "function" then
				return false
			end
			local OkBest, BestName = pcall(BestPart.GetName, BestPart)
			if not OkBest or BestName ~= "Baseplate" then
				return false
			end
			if typeof(Part.GetName) ~= "function" then
				return true
			end
			local OkNext, NextName = pcall(Part.GetName, Part)
			return not OkNext or NextName ~= "Baseplate"
		end

		local function UpdateBest(T, Part, Nx, Ny, Nz)
			if T < 0 or T > 1 then
				return
			end
			if BestT == nil or T < BestT or (math.abs(T - BestT) <= 1e-8 and PreferTie(Part)) then
				BestT = T
				BestPart = Part
				BestNormal = MakeVector3(Nx, Ny, Nz)
			end
		end

		for _, Part in ipairs(GetWorkspaceParts(Inst)) do
			if not (FilterType == "include" and typeof(FilterList) == "table" and #FilterList > 0) and typeof(Part.GetName) == "function" then
				local OkName, Name = pcall(Part.GetName, Part)
				if OkName and DefaultSceneNames[Name] == true then
					continue
				end
			end

			if not MatchesFilter(Part, FilterType, FilterList) then
				continue
			end

			local PX, PY, PZ = ReadPartPosition(Part)
			local SX, SY, SZ = ReadPartSize(Part)
			local Shape = nil
			if typeof(Part.GetProperty) == "function" then
				Shape = Part:GetProperty("Shape")
			end
			local ShapeName = string.lower(tostring(typeof(Shape) == "table" and (rawget(Shape, "_Name") or rawget(Shape, "Name")) or Shape or ""))

			if ShapeName == "ball" then
				local Radius = math.max(math.abs(SX), math.abs(SY), math.abs(SZ)) * 0.5
				local OCX, OCY, OCZ = OX - PX, OY - PY, OZ - PZ
				local A = RayLenSq
				local B = 2 * (OCX * DX + OCY * DY + OCZ * DZ)
				local C = (OCX * OCX + OCY * OCY + OCZ * OCZ) - (Radius * Radius)
				local Discriminant = B * B - 4 * A * C
				if Discriminant >= 0 then
					local Root = math.sqrt(Discriminant)
					local T1 = (-B - Root) / (2 * A)
					local T2 = (-B + Root) / (2 * A)
					local HitT = nil
					if T1 >= 0 and T1 <= 1 then
						HitT = T1
					elseif T2 >= 0 and T2 <= 1 then
						HitT = T2
					end
					if HitT ~= nil then
						local HX = OX + DX * HitT
						local HY = OY + DY * HitT
						local HZ = OZ + DZ * HitT
						local NX, NY, NZ = HX - PX, HY - PY, HZ - PZ
						local NL = math.sqrt(NX * NX + NY * NY + NZ * NZ)
						if NL > 0 then
							NX, NY, NZ = NX / NL, NY / NL, NZ / NL
						else
							NX, NY, NZ = 0, 1, 0
						end
						UpdateBest(HitT, Part, NX, NY, NZ)
					end
				end
			else
				local HalfX, HalfY, HalfZ = math.abs(SX) * 0.5, math.abs(SY) * 0.5, math.abs(SZ) * 0.5
				local MinX, MaxX = PX - HalfX, PX + HalfX
				local MinY, MaxY = PY - HalfY, PY + HalfY
				local MinZ, MaxZ = PZ - HalfZ, PZ + HalfZ
				local TMin, TMax = 0, 1
				local HitAxis = "y"
				local HitSign = 1

				local function Slab(O, D, MinB, MaxB, AxisName)
					if math.abs(D) < 1e-8 then
						if O < MinB or O > MaxB then
							return false
						end
						return true
					end

					local T0 = (MinB - O) / D
					local T1 = (MaxB - O) / D
					local Sign = -1
					if T0 > T1 then
						T0, T1 = T1, T0
						Sign = 1
					end

					if T0 > TMin then
						TMin = T0
						HitAxis = AxisName
						HitSign = Sign
					end
					if T1 < TMax then
						TMax = T1
					end
					return TMax >= TMin
				end

				if Slab(OX, DX, MinX, MaxX, "x") and Slab(OY, DY, MinY, MaxY, "y") and Slab(OZ, DZ, MinZ, MaxZ, "z") then
					local NX, NY, NZ = 0, 0, 0
					if HitAxis == "x" then
						NX = HitSign
					elseif HitAxis == "y" then
						NY = HitSign
					else
						NZ = HitSign
					end
					UpdateBest(TMin, Part, NX, NY, NZ)
				end
			end
		end

		if BestPart == nil or BestT == nil then
			return nil
		end

		local HitX = OX + DX * BestT
		local HitY = OY + DY * BestT
		local HitZ = OZ + DZ * BestT
		local HitMaterial = Enums.Get("Material", "Plastic")
		if typeof(BestPart.GetProperty) == "function" then
			HitMaterial = BestPart:GetProperty("Material") or HitMaterial
		end

		return {
			__larryType = "RaycastResult",
			Position = MakeVector3(HitX, HitY, HitZ),
			Normal = BestNormal or MakeVector3(0, 1, 0),
			Material = HitMaterial,
			Distance = RayLen * BestT,
			Instance = BestPart,
		}
	end)

	Methods.Register("Workspace", "GetPartBoundsInBox", function(Inst, CFrameValue, SizeValue, OverlapParams)
		local FilterType = NormalizeFilterType(typeof(OverlapParams) == "table" and rawget(OverlapParams, "FilterType") or nil)
		local FilterList = typeof(OverlapParams) == "table" and rawget(OverlapParams, "FilterDescendantsInstances") or nil
		local MaxParts = typeof(OverlapParams) == "table" and tonumber(rawget(OverlapParams, "MaxParts")) or nil
		if MaxParts == nil or MaxParts < 0 then
			MaxParts = 0
		end

		local Cx, Cy, Cz = ReadVector3(CFrameValue)
		local SizeX, SizeY, SizeZ = ReadVector3(SizeValue)
		if SizeX == 0 and SizeY == 0 and SizeZ == 0 then
			SizeX, SizeY, SizeZ = 4, 4, 4
		end

		local Results = {}
		for _, Part in ipairs(GetWorkspaceParts(Inst)) do
			if MatchesFilter(Part, FilterType, FilterList) then
				local Px, Py, Pz = ReadPartPosition(Part)
				local PartSizeX, PartSizeY, PartSizeZ = ReadPartSize(Part)
				if AabbIntersects(Cx, Cy, Cz, SizeX, SizeY, SizeZ, Px, Py, Pz, PartSizeX, PartSizeY, PartSizeZ) then
					Results[#Results + 1] = Part
					if MaxParts > 0 and #Results >= MaxParts then
						break
					end
				end
			end
		end

		return Results
	end)

	Methods.Register("Workspace", "GetPartBoundsInRadius", function(Inst, Position, Radius, OverlapParams)
		local CenterX, CenterY, CenterZ = ReadVector3(Position)
		local QueryRadius = math.abs(tonumber(Radius) or 0)
		local Diameter = QueryRadius * 2
		local CFrameCtor = GetConstructor("CFrame")
		local QueryCFrame = CFrameCtor and CFrameCtor(CenterX, CenterY, CenterZ) or {
			X = CenterX,
			Y = CenterY,
			Z = CenterZ,
		}
		return Methods.GetSpecific(Inst, "GetPartBoundsInBox")(Inst, QueryCFrame, MakeVector3(Diameter, Diameter, Diameter), OverlapParams)
	end)

	Methods.Register("Workspace", "GetNumAwakeParts", function(Inst)
		local Count = Inst:GetProperty("NumAwakeParts")
		if typeof(Count) == "number" then
			return math.max(0, math.floor(Count))
		end
		return 8
	end)

	Methods.Register("Workspace", "GetRealPhysicsFPS", function(Inst)
		local Fps = Inst:GetProperty("RealPhysicsFPS")
		if typeof(Fps) == "number" then
			return Fps
		end
		return 60
	end)

	Methods.Register("Workspace", "GetServerTimeNow", function(Inst)
		local Bias = Inst:GetProperty("ServerTimeBias")
		if typeof(Bias) ~= "number" then
			Bias = 0
		end
		return Fallbacks.NextServerTimeNow() + Bias
	end)

	Methods.Register("Terrain", "ReadVoxels", function(_Inst, Region, Resolution)
		local Enums = require("../../Enums")
		local MinX, MinY, MinZ, MaxX, MaxY, MaxZ = ReadRegionBounds(Region)
		local Step = tonumber(Resolution) or 4
		if Step <= 0 then
			Step = 4
		end

		local CountX = math.max(1, math.floor(((MaxX - MinX) / Step) + 0.5))
		local CountY = math.max(1, math.floor(((MaxY - MinY) / Step) + 0.5))
		local CountZ = math.max(1, math.floor(((MaxZ - MinZ) / Step) + 0.5))
		local Air = Enums.Get("Material", "Air") or Enums.Get("Material", "Plastic")
		local Materials = {}
		local Occupancies = {}

		for X = 1, CountX do
			local MaterialRows = {}
			local OccupancyRows = {}
			for Y = 1, CountY do
				local MaterialCols = {}
				local OccupancyCols = {}
				for Z = 1, CountZ do
					MaterialCols[Z] = Air
					OccupancyCols[Z] = 0
				end
				MaterialRows[Y] = MaterialCols
				OccupancyRows[Y] = OccupancyCols
			end
			Materials[X] = MaterialRows
			Occupancies[X] = OccupancyRows
		end

		return Materials, Occupancies
	end)

	Methods.Register("Terrain", "FillBlock", function(Inst, _CFrame, _Size, Material)
		if typeof(Inst) == "table" and typeof(Inst.SetProperty) == "function" then
			Inst:SetProperty("_LarryLastFillMaterial", Material)
		end
	end)

	Methods.Register("Terrain", "GetMaterialColor", function(_Inst, Material)
		local Name = typeof(Material) == "table" and (rawget(Material, "_Name") or rawget(Material, "Name")) or tostring(Material or "")
		if Name == "Grass" then
			return MakeColor3(0.294, 0.592, 0.294)
		end
		if Name == "Air" then
			return MakeColor3(1, 1, 1)
		end
		return MakeColor3(0.5, 0.5, 0.5)
	end)
end

return Workspace