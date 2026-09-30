local StringUtil = require("../../Utils/String")

local DataTypes = {}

local Constructors = {}
local TypeMeta = {}
local Vector2Meta = {}
local Vector3Meta = {}
local CFrameMeta = {}
local UDimMeta = {}
local UDim2Meta = {}
local Color3Meta = {}
local RectMeta = {}
local Region3Meta = {}
local SharedTableMeta = {}
local BrickColorMeta = {}
local MakeCFrame
local MakeUDim
local MakeUDim2
local PendingReadonlyViolation = nil

local function IsFiniteNumber(Value)
	return typeof(Value) == "number" and Value == Value and Value ~= math.huge and Value ~= -math.huge
end

local function ToNumber(Value, Default)
	local Num = tonumber(Value)
	if not IsFiniteNumber(Num) then
		return Default or 0
	end
	return Num
end

local function UnwrapArg(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end
	return Value
end

local function TagDataType(TypeName, Value)
	if typeof(Value) == "table" then
		rawset(Value, "__larryType", TypeName)
	end
	return Value
end

local function FreezeIfSupported(Value)
	if typeof(Value) == "table" and typeof(table.freeze) == "function" then
		pcall(table.freeze, Value)
	end
	return Value
end

local function MakeReadonlyProxy(TypeName, Source)
	local Proxy = {}
	if typeof(TypeName) == "string" and TypeName ~= "" then
		rawset(Proxy, "__larryType", TypeName)
	end
	rawset(Proxy, "_LarryReadonlyData", Source)
	rawset(Proxy, "_LarryReadonlyTouched", false)

	setmetatable(Proxy, {
		__index = function(_, Key)
			return Source[Key]
		end,
		__newindex = function(Tbl)
			rawset(Tbl, "_LarryReadonlyTouched", true)
			rawset(Tbl, "_LarryReadonlyMessage", "attempt to modify a readonly table")
			PendingReadonlyViolation = "attempt to modify a readonly table"
			local Services = require("../../Roblox/Services")
			local LogService = Services.GetOrNil("LogService")
			if LogService and typeof(LogService.SetProperty) == "function" then
				LogService:SetProperty("_LarryReadonlyViolation", "attempt to modify a readonly table")
			end
			error("attempt to modify a readonly table", 2)
		end,
		__len = function()
			return #Source
		end,
		__iter = function()
			return next, Source, nil
		end,
	})

	return Proxy
end

local function IsTypeTag(Value, TypeName)
	return typeof(Value) == "table" and rawget(Value, "__larryType") == TypeName
end

local function ReadVector2(Value)
	if IsTypeTag(Value, "Vector2") then
		return ToNumber(rawget(Value, "X"), 0), ToNumber(rawget(Value, "Y"), 0)
	end
	if typeof(Value) == "table" then
		return ToNumber(rawget(Value, "X"), 0), ToNumber(rawget(Value, "Y"), 0)
	end
	return 0, 0
end

local function ReadVector3(Value)
	if IsTypeTag(Value, "Vector3") then
		return ToNumber(rawget(Value, "X"), 0), ToNumber(rawget(Value, "Y"), 0), ToNumber(rawget(Value, "Z"), 0)
	end
	if typeof(Value) == "table" then
		return ToNumber(rawget(Value, "X"), 0), ToNumber(rawget(Value, "Y"), 0), ToNumber(rawget(Value, "Z"), 0)
	end
	return 0, 0, 0
end

local function NearlyEqual(A, B)
	return math.abs(ToNumber(A, 0) - ToNumber(B, 0)) <= 1e-6
end

local function FormatNumber(Value)
	local Num = ToNumber(Value, 0)
	if Num == 0 then
		Num = 0
	end
	if Num % 1 == 0 then
		return tostring(math.floor(Num))
	end

	local Text = string.format("%.6f", Num)
	Text = string.gsub(Text, "0+$", "")
	Text = string.gsub(Text, "%.$", "")
	if Text == "-0" then
		Text = "0"
	end
	return Text
end

local function MakeVector2(X, Y)
	local Out = TagDataType("Vector2", {
		X = ToNumber(X, 0),
		Y = ToNumber(Y, 0),
	})
	return setmetatable(Out, Vector2Meta)
end

local function MakeVector3(X, Y, Z)
	local Out = TagDataType("Vector3", {
		X = ToNumber(X, 0),
		Y = ToNumber(Y, 0),
		Z = ToNumber(Z, 0),
	})
	return setmetatable(Out, Vector3Meta)
end

local function GetCFrameBasis(Self)
	local Ux = rawget(Self, "Ux")
	local Uy = rawget(Self, "Uy")
	local Uz = rawget(Self, "Uz")
	local Lx = rawget(Self, "Lx")
	local Ly = rawget(Self, "Ly")
	local Lz = rawget(Self, "Lz")
	if IsFiniteNumber(Ux) and IsFiniteNumber(Uy) and IsFiniteNumber(Uz) and IsFiniteNumber(Lx) and IsFiniteNumber(Ly) and IsFiniteNumber(Lz) then
		return
			ToNumber(rawget(Self, "Rx"), 1), ToNumber(rawget(Self, "Ry"), 0), ToNumber(rawget(Self, "Rz"), 0),
			ToNumber(Ux, 0), ToNumber(Uy, 1), ToNumber(Uz, 0),
			ToNumber(Lx, 0), ToNumber(Ly, 0), ToNumber(Lz, 1)
	end

	local Rx = ToNumber(rawget(Self, "Rx"), 0)
	local Ry = ToNumber(rawget(Self, "Ry"), 0)
	local Rz = ToNumber(rawget(Self, "Rz"), 0)

	local Cx, Sx = math.cos(Rx), math.sin(Rx)
	local Cy, Sy = math.cos(Ry), math.sin(Ry)
	local Cz, Sz = math.cos(Rz), math.sin(Rz)

	local M00 = Cy * Cz
	local M01 = Cy * Sz
	local M02 = -Sy
	local M10 = (Sx * Sy * Cz) - (Cx * Sz)
	local M11 = (Sx * Sy * Sz) + (Cx * Cz)
	local M12 = Sx * Cy
	local M20 = (Cx * Sy * Cz) + (Sx * Sz)
	local M21 = (Cx * Sy * Sz) - (Sx * Cz)
	local M22 = Cx * Cy

	return M00, M10, M20, M01, M11, M21, M02, M12, M22
end

local function CFrameVectorToWorld(Self, Value)
	local VX, VY, VZ = ReadVector3(Value)
	local RX, RY, RZ, UX, UY, UZ, ZX, ZY, ZZ = GetCFrameBasis(Self)
	return MakeVector3(
		(RX * VX) + (UX * VY) + (ZX * VZ),
		(RY * VX) + (UY * VY) + (ZY * VZ),
		(RZ * VX) + (UZ * VY) + (ZZ * VZ)
	)
end

local function CFrameVectorToObject(Self, Value)
	local VX, VY, VZ = ReadVector3(Value)
	local RX, RY, RZ, UX, UY, UZ, ZX, ZY, ZZ = GetCFrameBasis(Self)
	return MakeVector3(
		(RX * VX) + (RY * VY) + (RZ * VZ),
		(UX * VX) + (UY * VY) + (UZ * VZ),
		(ZX * VX) + (ZY * VY) + (ZZ * VZ)
	)
end

local function CFramePointToWorld(Self, Value)
	local VX, VY, VZ = ReadVector3(CFrameVectorToWorld(Self, Value))
	return MakeVector3(
		ToNumber(rawget(Self, "X"), 0) + VX,
		ToNumber(rawget(Self, "Y"), 0) + VY,
		ToNumber(rawget(Self, "Z"), 0) + VZ
	)
end

local function CFramePointToObject(Self, Value)
	local VX, VY, VZ = ReadVector3(Value)
	return CFrameVectorToObject(Self, MakeVector3(
		VX - ToNumber(rawget(Self, "X"), 0),
		VY - ToNumber(rawget(Self, "Y"), 0),
		VZ - ToNumber(rawget(Self, "Z"), 0)
	))
end

local function BuildLookBasis(Ex, Ey, Ez, Dx, Dy, Dz, Ux, Uy, Uz)
	local DirMag = math.sqrt((Dx * Dx) + (Dy * Dy) + (Dz * Dz))
	if DirMag <= 0 then
		Dx, Dy, Dz = 0, 0, -1
		DirMag = 1
	end
	Dx, Dy, Dz = Dx / DirMag, Dy / DirMag, Dz / DirMag

	local UpMag = math.sqrt((Ux * Ux) + (Uy * Uy) + (Uz * Uz))
	if UpMag <= 0 then
		Ux, Uy, Uz = 0, 1, 0
		UpMag = 1
	end
	Ux, Uy, Uz = Ux / UpMag, Uy / UpMag, Uz / UpMag

	local Zx, Zy, Zz = -Dx, -Dy, -Dz
	local Rx = (Uy * Zz) - (Uz * Zy)
	local Ry = (Uz * Zx) - (Ux * Zz)
	local Rz = (Ux * Zy) - (Uy * Zx)
	local RightMag = math.sqrt((Rx * Rx) + (Ry * Ry) + (Rz * Rz))
	if RightMag <= 0 then
		Rx, Ry, Rz = 1, 0, 0
		RightMag = 1
	end
	Rx, Ry, Rz = Rx / RightMag, Ry / RightMag, Rz / RightMag

	local Upx = (Zy * Rz) - (Zz * Ry)
	local Upy = (Zz * Rx) - (Zx * Rz)
	local Upz = (Zx * Ry) - (Zy * Rx)

	return setmetatable({
		X = Ex,
		Y = Ey,
		Z = Ez,
		Rx = Rx,
		Ry = Ry,
		Rz = Rz,
		Ux = Upx,
		Uy = Upy,
		Uz = Upz,
		Lx = Zx,
		Ly = Zy,
		Lz = Zz,
		__larryType = "CFrame",
	}, CFrameMeta)
end

local function WrapInt16(Value)
	local Number = math.floor(ToNumber(Value, 0))
	Number = ((Number + 32768) % 65536) - 32768
	return Number
end

Vector2Meta.__index = function(Self, Key)
	if Key == "Magnitude" then
		local X, Y = ReadVector2(Self)
		return math.sqrt((X * X) + (Y * Y))
	end

	if Key == "Unit" then
		local X, Y = ReadVector2(Self)
		local M = math.sqrt((X * X) + (Y * Y))
		if M <= 0 then
			return MakeVector2(0, 0)
		end
		return MakeVector2(X / M, Y / M)
	end

	if Key == "Dot" then
		return function(Target, Other)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			return (AX * BX) + (AY * BY)
		end
	end

	if Key == "Cross" then
		return function(Target, Other)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			return (AX * BY) - (AY * BX)
		end
	end

	if Key == "Angle" then
		return function(Target, Other)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			local Dot = (AX * BX) + (AY * BY)
			local MagA = math.sqrt((AX * AX) + (AY * AY))
			local MagB = math.sqrt((BX * BX) + (BY * BY))
			if MagA <= 0 or MagB <= 0 then
				return 0
			end
			local Cosine = Dot / (MagA * MagB)
			if Cosine < -1 then Cosine = -1 end
			if Cosine > 1 then Cosine = 1 end
			return math.acos(Cosine)
		end
	end

	if Key == "FuzzyEq" then
		return function(Target, Other, Epsilon)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			local E = Epsilon or 0.0001
			return math.abs(AX - BX) <= E and math.abs(AY - BY) <= E
		end
	end

	if Key == "Lerp" then
		return function(Target, Goal, Alpha)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Goal)
			local A = Alpha or 0
			return MakeVector2(AX + (BX - AX) * A, AY + (BY - AY) * A)
		end
	end

	if Key == "Max" then
		return function(Target, Other)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			return MakeVector2(math.max(AX, BX), math.max(AY, BY))
		end
	end

	if Key == "Min" then
		return function(Target, Other)
			local AX, AY = ReadVector2(Target)
			local BX, BY = ReadVector2(Other)
			return MakeVector2(math.min(AX, BX), math.min(AY, BY))
		end
	end

	if Key == "Abs" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return MakeVector2(math.abs(X), math.abs(Y))
		end
	end

	if Key == "Floor" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return MakeVector2(math.floor(X), math.floor(Y))
		end
	end

	if Key == "Ceil" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return MakeVector2(math.ceil(X), math.ceil(Y))
		end
	end

	if Key == "Sign" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return MakeVector2(X > 0 and 1 or X < 0 and -1 or 0, Y > 0 and 1 or Y < 0 and -1 or 0)
		end
	end

	if Key == "Max" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return math.max(X, Y)
		end
	end

	if Key == "Min" then
		return function(Self)
			local X, Y = ReadVector2(Self)
			return math.min(X, Y)
		end
	end

	return rawget(Self, Key)
end

Vector2Meta.__add = function(A, B)
	local AX, AY = ReadVector2(A)
	local BX, BY = ReadVector2(B)
	return MakeVector2(AX + BX, AY + BY)
end

Vector2Meta.__sub = function(A, B)
	local AX, AY = ReadVector2(A)
	local BX, BY = ReadVector2(B)
	return MakeVector2(AX - BX, AY - BY)
end

Vector2Meta.__mul = function(A, B)
	if typeof(A) == "number" then
		local BX, BY = ReadVector2(B)
		return MakeVector2(BX * A, BY * A)
	end
	if typeof(B) == "number" then
		local AX, AY = ReadVector2(A)
		return MakeVector2(AX * B, AY * B)
	end

	local AX, AY = ReadVector2(A)
	local BX, BY = ReadVector2(B)
	return MakeVector2(AX * BX, AY * BY)
end

Vector2Meta.__div = function(A, B)
	if typeof(B) == "number" then
		local AX, AY = ReadVector2(A)
		if B == 0 then
			return MakeVector2(0, 0)
		end
		return MakeVector2(AX / B, AY / B)
	end

	local AX, AY = ReadVector2(A)
	local BX, BY = ReadVector2(B)
	if BX == 0 then BX = 1 end
	if BY == 0 then BY = 1 end
	return MakeVector2(AX / BX, AY / BY)
end

Vector2Meta.__eq = function(A, B)
	local AX, AY = ReadVector2(A)
	local BX, BY = ReadVector2(B)
	return NearlyEqual(AX, BX) and NearlyEqual(AY, BY)
end

Vector2Meta.__tostring = function(Self)
	local X, Y = ReadVector2(Self)
	return `{FormatNumber(X)}, {FormatNumber(Y)}`
end

Vector3Meta.__index = function(Self, Key)
	if Key == "Magnitude" then
		local X, Y, Z = ReadVector3(Self)
		return math.sqrt((X * X) + (Y * Y) + (Z * Z))
	end

	if Key == "Unit" then
		local X, Y, Z = ReadVector3(Self)
		local M = math.sqrt((X * X) + (Y * Y) + (Z * Z))
		if M <= 0 then
			return MakeVector3(0, 0, 0)
		end
		return MakeVector3(X / M, Y / M, Z / M)
	end

	if Key == "Dot" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			return (AX * BX) + (AY * BY) + (AZ * BZ)
		end
	end

	if Key == "Cross" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			return MakeVector3(
				(AY * BZ) - (AZ * BY),
				(AZ * BX) - (AX * BZ),
				(AX * BY) - (AY * BX)
			)
		end
	end

	if Key == "Angle" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			local Dot = (AX * BX) + (AY * BY) + (AZ * BZ)
			local MagA = math.sqrt((AX * AX) + (AY * AY) + (AZ * AZ))
			local MagB = math.sqrt((BX * BX) + (BY * BY) + (BZ * BZ))
			if MagA <= 0 or MagB <= 0 then
				return 0
			end
			local Cosine = Dot / (MagA * MagB)
			if Cosine < -1 then Cosine = -1 end
			if Cosine > 1 then Cosine = 1 end
			return math.acos(Cosine)
		end
	end

	if Key == "FuzzyEq" then
		return function(Target, Other, Epsilon)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			local E = Epsilon or 0.0001
			return math.abs(AX - BX) <= E and math.abs(AY - BY) <= E and math.abs(AZ - BZ) <= E
		end
	end

	if Key == "Lerp" then
		return function(Target, Goal, Alpha)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Goal)
			local A = Alpha or 0
			return MakeVector3(AX + (BX - AX) * A, AY + (BY - AY) * A, AZ + (BZ - AZ) * A)
		end
	end

	if Key == "Max" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			return MakeVector3(math.max(AX, BX), math.max(AY, BY), math.max(AZ, BZ))
		end
	end

	if Key == "Min" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target)
			local BX, BY, BZ = ReadVector3(Other)
			return MakeVector3(math.min(AX, BX), math.min(AY, BY), math.min(AZ, BZ))
		end
	end

	if Key == "Abs" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return MakeVector3(math.abs(X), math.abs(Y), math.abs(Z))
		end
	end

	if Key == "Floor" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return MakeVector3(math.floor(X), math.floor(Y), math.floor(Z))
		end
	end

	if Key == "Ceil" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return MakeVector3(math.ceil(X), math.ceil(Y), math.ceil(Z))
		end
	end

	if Key == "Sign" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return MakeVector3(X > 0 and 1 or X < 0 and -1 or 0, Y > 0 and 1 or Y < 0 and -1 or 0, Z > 0 and 1 or Z < 0 and -1 or 0)
		end
	end

	if Key == "Max" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return math.max(X, Y, Z)
		end
	end

	if Key == "Min" then
		return function(Self)
			local X, Y, Z = ReadVector3(Self)
			return math.min(X, Y, Z)
		end
	end

	return rawget(Self, Key)
end

Vector3Meta.__add = function(A, B)
	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	return MakeVector3(AX + BX, AY + BY, AZ + BZ)
end

Vector3Meta.__sub = function(A, B)
	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	return MakeVector3(AX - BX, AY - BY, AZ - BZ)
end

Vector3Meta.__mul = function(A, B)
	if typeof(A) == "number" then
		local BX, BY, BZ = ReadVector3(B)
		return MakeVector3(BX * A, BY * A, BZ * A)
	end
	if typeof(B) == "number" then
		local AX, AY, AZ = ReadVector3(A)
		return MakeVector3(AX * B, AY * B, AZ * B)
	end

	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	return MakeVector3(AX * BX, AY * BY, AZ * BZ)
end

Vector3Meta.__div = function(A, B)
	if typeof(B) == "number" then
		local AX, AY, AZ = ReadVector3(A)
		if B == 0 then
			return MakeVector3(0, 0, 0)
		end
		return MakeVector3(AX / B, AY / B, AZ / B)
	end

	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	if BX == 0 then BX = 1 end
	if BY == 0 then BY = 1 end
	if BZ == 0 then BZ = 1 end
	return MakeVector3(AX / BX, AY / BY, AZ / BZ)
end

Vector3Meta.__unm = function(A)
	local X, Y, Z = ReadVector3(A)
	return MakeVector3(-X, -Y, -Z)
end

Vector3Meta.__eq = function(A, B)
	local AX, AY, AZ = ReadVector3(A)
	local BX, BY, BZ = ReadVector3(B)
	return NearlyEqual(AX, BX) and NearlyEqual(AY, BY) and NearlyEqual(AZ, BZ)
end

Vector3Meta.__tostring = function(Self)
	local X, Y, Z = ReadVector3(Self)
	return `{FormatNumber(X)}, {FormatNumber(Y)}, {FormatNumber(Z)}`
end

CFrameMeta.__index = function(Self, Key)
	if Key == "Position" then
		return MakeVector3(ToNumber(rawget(Self, "X"), 0), ToNumber(rawget(Self, "Y"), 0), ToNumber(rawget(Self, "Z"), 0))
	end

	if Key == "Rotation" then
		return MakeCFrame(
			0,
			0,
			0,
			ToNumber(rawget(Self, "Rx"), 0),
			ToNumber(rawget(Self, "Ry"), 0),
			ToNumber(rawget(Self, "Rz"), 0)
		)
	end

	if Key == "RightVector" then
		local RX, RY, RZ = GetCFrameBasis(Self)
		return MakeVector3(RX, RY, RZ)
	end

	if Key == "XVector" then
		local RX, RY, RZ = GetCFrameBasis(Self)
		return MakeVector3(RX, RY, RZ)
	end

	if Key == "UpVector" then
		local _, _, _, UX, UY, UZ = GetCFrameBasis(Self)
		return MakeVector3(UX, UY, UZ)
	end

	if Key == "YVector" then
		local _, _, _, UX, UY, UZ = GetCFrameBasis(Self)
		return MakeVector3(UX, UY, UZ)
	end

	if Key == "LookVector" then
		local _, _, _, _, _, _, ZX, ZY, ZZ = GetCFrameBasis(Self)
		return MakeVector3(-ZX, -ZY, -ZZ)
	end

	if Key == "ZVector" then
		local _, _, _, _, _, _, ZX, ZY, ZZ = GetCFrameBasis(Self)
		return MakeVector3(ZX, ZY, ZZ)
	end

	if Key == "Inverse" then
		return function(Target)
			return MakeCFrame(
				-ToNumber(rawget(Target, "X"), 0),
				-ToNumber(rawget(Target, "Y"), 0),
				-ToNumber(rawget(Target, "Z"), 0),
				-ToNumber(rawget(Target, "Rx"), 0),
				-ToNumber(rawget(Target, "Ry"), 0),
				-ToNumber(rawget(Target, "Rz"), 0)
			)
		end
	end

	if Key == "ToEulerAnglesXYZ" then
		return function(Target)
			return ToNumber(rawget(Target, "Rx"), 0), ToNumber(rawget(Target, "Ry"), 0), ToNumber(rawget(Target, "Rz"), 0)
		end
	end

	if Key == "ToEulerAngles" then
		return function(Target)
			return ToNumber(rawget(Target, "Rx"), 0), ToNumber(rawget(Target, "Ry"), 0), ToNumber(rawget(Target, "Rz"), 0)
		end
	end

	if Key == "GetComponents" or Key == "components" then
		return function(Target)
			local RX, RY, RZ, UX, UY, UZ, ZX, ZY, ZZ = GetCFrameBasis(Target)
			return Target.X, Target.Y, Target.Z, RX, UX, ZX, RY, UY, ZY, RZ, UZ, ZZ
		end
	end

	if Key == "VectorToWorldSpace" then
		return function(Target, Value)
			return CFrameVectorToWorld(Target, Value)
		end
	end

	if Key == "VectorToObjectSpace" then
		return function(Target, Value)
			return CFrameVectorToObject(Target, Value)
		end
	end

	if Key == "PointToWorldSpace" then
		return function(Target, Value)
			return CFramePointToWorld(Target, Value)
		end
	end

	if Key == "PointToObjectSpace" then
		return function(Target, Value)
			return CFramePointToObject(Target, Value)
		end
	end

	if Key == "ToWorldSpace" then
		return function(Target, Other)
			if IsTypeTag(Other, "CFrame") then
				return Target * Other
			end
			return CFramePointToWorld(Target, Other)
		end
	end

	if Key == "ToObjectSpace" then
		return function(Target, Other)
			if IsTypeTag(Other, "CFrame") then
				local Point = CFramePointToObject(Target, MakeVector3(
					ToNumber(rawget(Other, "X"), 0),
					ToNumber(rawget(Other, "Y"), 0),
					ToNumber(rawget(Other, "Z"), 0)
				))
				return MakeCFrame(
					ToNumber(rawget(Point, "X"), 0),
					ToNumber(rawget(Point, "Y"), 0),
					ToNumber(rawget(Point, "Z"), 0),
					ToNumber(rawget(Other, "Rx"), 0) - ToNumber(rawget(Target, "Rx"), 0),
					ToNumber(rawget(Other, "Ry"), 0) - ToNumber(rawget(Target, "Ry"), 0),
					ToNumber(rawget(Other, "Rz"), 0) - ToNumber(rawget(Target, "Rz"), 0)
				)
			end
			return CFramePointToObject(Target, Other)
		end
	end

	if Key == "Lerp" then
		return function(Target, Goal, Alpha)
			local T = ToNumber(Alpha, 0)
			if T < 0 then
				T = 0
			elseif T > 1 then
				T = 1
			end
			local function Mix(A, B)
				return A + ((B - A) * T)
			end

			local Out = {
				X = Mix(ToNumber(rawget(Target, "X"), 0), ToNumber(rawget(Goal, "X"), 0)),
				Y = Mix(ToNumber(rawget(Target, "Y"), 0), ToNumber(rawget(Goal, "Y"), 0)),
				Z = Mix(ToNumber(rawget(Target, "Z"), 0), ToNumber(rawget(Goal, "Z"), 0)),
				Rx = Mix(ToNumber(rawget(Target, "Rx"), 0), ToNumber(rawget(Goal, "Rx"), 0)),
				Ry = Mix(ToNumber(rawget(Target, "Ry"), 0), ToNumber(rawget(Goal, "Ry"), 0)),
				Rz = Mix(ToNumber(rawget(Target, "Rz"), 0), ToNumber(rawget(Goal, "Rz"), 0)),
				__larryType = "CFrame",
			}

			local TargetUx = rawget(Target, "Ux")
			local GoalUx = rawget(Goal, "Ux")
			if IsFiniteNumber(TargetUx) or IsFiniteNumber(GoalUx) then
				Out.Ux = Mix(ToNumber(rawget(Target, "Ux"), 0), ToNumber(rawget(Goal, "Ux"), 0))
				Out.Uy = Mix(ToNumber(rawget(Target, "Uy"), 1), ToNumber(rawget(Goal, "Uy"), 1))
				Out.Uz = Mix(ToNumber(rawget(Target, "Uz"), 0), ToNumber(rawget(Goal, "Uz"), 0))
				Out.Lx = Mix(ToNumber(rawget(Target, "Lx"), 0), ToNumber(rawget(Goal, "Lx"), 0))
				Out.Ly = Mix(ToNumber(rawget(Target, "Ly"), 0), ToNumber(rawget(Goal, "Ly"), 0))
				Out.Lz = Mix(ToNumber(rawget(Target, "Lz"), 1), ToNumber(rawget(Goal, "Lz"), 1))
			end

			return setmetatable(Out, CFrameMeta)
		end
	end

	if Key == "Orthonormalize" then
		return function(Target)
			local Out = {
				X = ToNumber(rawget(Target, "X"), 0),
				Y = ToNumber(rawget(Target, "Y"), 0),
				Z = ToNumber(rawget(Target, "Z"), 0),
				Rx = ToNumber(rawget(Target, "Rx"), 0),
				Ry = ToNumber(rawget(Target, "Ry"), 0),
				Rz = ToNumber(rawget(Target, "Rz"), 0),
				__larryType = "CFrame",
			}
			if IsFiniteNumber(rawget(Target, "Ux")) then
				Out.Ux = ToNumber(rawget(Target, "Ux"), 0)
				Out.Uy = ToNumber(rawget(Target, "Uy"), 1)
				Out.Uz = ToNumber(rawget(Target, "Uz"), 0)
				Out.Lx = ToNumber(rawget(Target, "Lx"), 0)
				Out.Ly = ToNumber(rawget(Target, "Ly"), 0)
				Out.Lz = ToNumber(rawget(Target, "Lz"), 1)
			end
			return setmetatable(Out, CFrameMeta)
		end
	end

	if Key == "ToOrientation" or Key == "ToEulerAnglesYXZ" then
		return function(Target)
			return ToNumber(rawget(Target, "Rx"), 0), ToNumber(rawget(Target, "Ry"), 0), ToNumber(rawget(Target, "Rz"), 0)
		end
	end

	if Key == "ToAxisAngle" then
		return function(Target)
			local Rx = ToNumber(rawget(Target, "Rx"), 0)
			local Ry = ToNumber(rawget(Target, "Ry"), 0)
			local Rz = ToNumber(rawget(Target, "Rz"), 0)
			local Angle = math.sqrt((Rx * Rx) + (Ry * Ry) + (Rz * Rz))
			if Angle <= 0 then
				return MakeVector3(0, 0, 1), 0
			end
			return MakeVector3(Rx / Angle, Ry / Angle, Rz / Angle), Angle
		end
	end

	if Key == "FuzzyEq" then
		return function(Target, Other, Epsilon)
			local E = ToNumber(Epsilon, 0.0001)
			local AX, AY, AZ = ToNumber(rawget(Target, "X"), 0), ToNumber(rawget(Target, "Y"), 0), ToNumber(rawget(Target, "Z"), 0)
			local BX, BY, BZ = ToNumber(rawget(Other, "X"), 0), ToNumber(rawget(Other, "Y"), 0), ToNumber(rawget(Other, "Z"), 0)
			if math.abs(AX - BX) > E or math.abs(AY - BY) > E or math.abs(AZ - BZ) > E then
				return false
			end

			local ARX, ARY, ARZ = ToNumber(rawget(Target, "Rx"), 0), ToNumber(rawget(Target, "Ry"), 0), ToNumber(rawget(Target, "Rz"), 0)
			local BRX, BRY, BRZ = ToNumber(rawget(Other, "Rx"), 0), ToNumber(rawget(Other, "Ry"), 0), ToNumber(rawget(Other, "Rz"), 0)
			return math.abs(ARX - BRX) <= E and math.abs(ARY - BRY) <= E and math.abs(ARZ - BRZ) <= E
		end
	end

	if Key == "AngleBetween" then
		return function(Target, Other)
			local AX, AY, AZ = ReadVector3(Target.LookVector)
			local BX, BY, BZ = ReadVector3(Other.LookVector)
			local MagA = math.sqrt((AX * AX) + (AY * AY) + (AZ * AZ))
			local MagB = math.sqrt((BX * BX) + (BY * BY) + (BZ * BZ))
			if MagA <= 0 or MagB <= 0 then
				return 0
			end
			local Dot = ((AX * BX) + (AY * BY) + (AZ * BZ)) / (MagA * MagB)
			if Dot < -1 then
				Dot = -1
			elseif Dot > 1 then
				Dot = 1
			end
			return math.acos(Dot)
		end
	end

	return rawget(Self, Key)
end

CFrameMeta.__mul = function(A, B)
	if IsTypeTag(B, "CFrame") then
		local AX, AY, AZ = ToNumber(rawget(A, "X"), 0), ToNumber(rawget(A, "Y"), 0), ToNumber(rawget(A, "Z"), 0)
		local BX, BY, BZ = ToNumber(rawget(B, "X"), 0), ToNumber(rawget(B, "Y"), 0), ToNumber(rawget(B, "Z"), 0)
		local ARX, ARY, ARZ, AUX, AUY, AUZ, AZX, AZY, AZZ = GetCFrameBasis(A)
		local BRX, BRY, BRZ, BUX, BUY, BUZ, BZX, BZY, BZZ = GetCFrameBasis(B)

		local function Transform(VX, VY, VZ)
			return
				(ARX * VX) + (AUX * VY) + (AZX * VZ),
				(ARY * VX) + (AUY * VY) + (AZY * VZ),
				(ARZ * VX) + (AUZ * VY) + (AZZ * VZ)
		end

		local TX, TY, TZ = Transform(BX, BY, BZ)
		local CX, CY, CZ = AX + TX, AY + TY, AZ + TZ

		local CRX, CRY, CRZ = Transform(BRX, BRY, BRZ)
		local CUX, CUY, CUZ = Transform(BUX, BUY, BUZ)
		local CZX, CZY, CZZ = Transform(BZX, BZY, BZZ)

		local Clamped = math.clamp(-CZX, -1, 1)
		local NewRy = math.asin(Clamped)
		local CosY = math.cos(NewRy)
		local NewRx, NewRz

		if math.abs(CosY) > 1e-6 then
			NewRx = math.atan2(CZY, CZZ)
			NewRz = math.atan2(CUX, CRX)
		else
			NewRz = 0
			NewRx = math.atan2(-CUZ, CUY)
		end

		return MakeCFrame(CX, CY, CZ, NewRx, NewRy, NewRz)
	end

	if IsTypeTag(B, "Vector3") then
		return CFramePointToWorld(A, B)
	end

	return MakeCFrame(ToNumber(rawget(A, "X"), 0), ToNumber(rawget(A, "Y"), 0), ToNumber(rawget(A, "Z"), 0))
end

CFrameMeta.__add = function(A, B)
	if IsTypeTag(B, "Vector3") then
		local BX, BY, BZ = ReadVector3(B)
		return MakeCFrame(
			ToNumber(rawget(A, "X"), 0) + BX,
			ToNumber(rawget(A, "Y"), 0) + BY,
			ToNumber(rawget(A, "Z"), 0) + BZ,
			ToNumber(rawget(A, "Rx"), 0),
			ToNumber(rawget(A, "Ry"), 0),
			ToNumber(rawget(A, "Rz"), 0)
		)
	end

	return MakeCFrame(
		ToNumber(rawget(A, "X"), 0),
		ToNumber(rawget(A, "Y"), 0),
		ToNumber(rawget(A, "Z"), 0),
		ToNumber(rawget(A, "Rx"), 0),
		ToNumber(rawget(A, "Ry"), 0),
		ToNumber(rawget(A, "Rz"), 0)
	)
end

CFrameMeta.__sub = function(A, B)
	if IsTypeTag(B, "Vector3") then
		local BX, BY, BZ = ReadVector3(B)
		return MakeCFrame(
			ToNumber(rawget(A, "X"), 0) - BX,
			ToNumber(rawget(A, "Y"), 0) - BY,
			ToNumber(rawget(A, "Z"), 0) - BZ,
			ToNumber(rawget(A, "Rx"), 0),
			ToNumber(rawget(A, "Ry"), 0),
			ToNumber(rawget(A, "Rz"), 0)
		)
	end

	return MakeCFrame(
		ToNumber(rawget(A, "X"), 0),
		ToNumber(rawget(A, "Y"), 0),
		ToNumber(rawget(A, "Z"), 0),
		ToNumber(rawget(A, "Rx"), 0),
		ToNumber(rawget(A, "Ry"), 0),
		ToNumber(rawget(A, "Rz"), 0)
	)
end

CFrameMeta.__eq = function(A, B)
	local ComponentsA = table.pack(A:GetComponents())
	local ComponentsB = table.pack(B:GetComponents())
	if ComponentsA.n ~= ComponentsB.n then
		return false
	end
	for I = 1, ComponentsA.n do
		if not NearlyEqual(ComponentsA[I], ComponentsB[I]) then
			return false
		end
	end
	return true
end

CFrameMeta.__tostring = function(Self)
	local Components = table.pack(Self:GetComponents())
	local Parts = {}
	for I = 1, Components.n do
		Parts[I] = FormatNumber(Components[I])
	end
	return table.concat(Parts, ", ")
end

local function MakeVector2int16(X, Y)
	local Out = TagDataType("Vector2int16", {
		X = WrapInt16(X),
		Y = WrapInt16(Y),
	})
	return setmetatable(Out, {
		__add = function(A, B)
			local AX = math.floor(ToNumber(A.X, 0))
			local AY = math.floor(ToNumber(A.Y, 0))
			local BX = math.floor(ToNumber(B.X, 0))
			local BY = math.floor(ToNumber(B.Y, 0))
			return MakeVector2int16(AX + BX, AY + BY)
		end,
		__mul = function(A, B)
			if typeof(B) == "number" then
				return MakeVector2int16(
					math.floor(ToNumber(A.X, 0) * B),
					math.floor(ToNumber(A.Y, 0) * B)
				)
			end
			return MakeVector2int16(
				math.floor(ToNumber(A.X, 0) * ToNumber(B.X, 0)),
				math.floor(ToNumber(A.Y, 0) * ToNumber(B.Y, 0))
			)
		end,
		__div = function(A, B)
			if typeof(B) == "number" then
				if B == 0 then
					return MakeVector2int16(0, 0)
				end
				return MakeVector2int16(
					math.floor(ToNumber(A.X, 0) / B),
					math.floor(ToNumber(A.Y, 0) / B)
				)
			end
			local BX = ToNumber(B.X, 0)
			local BY = ToNumber(B.Y, 0)
			if BX == 0 then BX = 1 end
			if BY == 0 then BY = 1 end
			return MakeVector2int16(
				math.floor(ToNumber(A.X, 0) / BX),
				math.floor(ToNumber(A.Y, 0) / BY)
			)
		end,
		__sub = function(A, B)
			local AX = math.floor(ToNumber(A.X, 0))
			local AY = math.floor(ToNumber(A.Y, 0))
			local BX = math.floor(ToNumber(B.X, 0))
			local BY = math.floor(ToNumber(B.Y, 0))
			return MakeVector2int16(AX - BX, AY - BY)
		end,
		__eq = function(A, B)
			return math.floor(ToNumber(A.X, 0)) == math.floor(ToNumber(B.X, 0))
				and math.floor(ToNumber(A.Y, 0)) == math.floor(ToNumber(B.Y, 0))
		end,
		__tostring = function(Self)
			return `{math.floor(ToNumber(Self.X, 0))}, {math.floor(ToNumber(Self.Y, 0))}`
		end,
	})
end

local function MakeVector3int16(X, Y, Z)
	local Out = TagDataType("Vector3int16", {
		X = WrapInt16(X),
		Y = WrapInt16(Y),
		Z = WrapInt16(Z),
	})
	return setmetatable(Out, {
		__add = function(A, B)
			local AX = math.floor(ToNumber(A.X, 0))
			local AY = math.floor(ToNumber(A.Y, 0))
			local AZ = math.floor(ToNumber(A.Z, 0))
			local BX = math.floor(ToNumber(B.X, 0))
			local BY = math.floor(ToNumber(B.Y, 0))
			local BZ = math.floor(ToNumber(B.Z, 0))
			return MakeVector3int16(AX + BX, AY + BY, AZ + BZ)
		end,
		__mul = function(A, B)
			if typeof(B) == "number" then
				return MakeVector3int16(
					math.floor(ToNumber(A.X, 0) * B),
					math.floor(ToNumber(A.Y, 0) * B),
					math.floor(ToNumber(A.Z, 0) * B)
				)
			end
			return MakeVector3int16(
				math.floor(ToNumber(A.X, 0) * ToNumber(B.X, 0)),
				math.floor(ToNumber(A.Y, 0) * ToNumber(B.Y, 0)),
				math.floor(ToNumber(A.Z, 0) * ToNumber(B.Z, 0))
			)
		end,
		__div = function(A, B)
			if typeof(B) == "number" then
				if B == 0 then
					return MakeVector3int16(0, 0, 0)
				end
				return MakeVector3int16(
					math.floor(ToNumber(A.X, 0) / B),
					math.floor(ToNumber(A.Y, 0) / B),
					math.floor(ToNumber(A.Z, 0) / B)
				)
			end
			local BX = ToNumber(B.X, 0)
			local BY = ToNumber(B.Y, 0)
			local BZ = ToNumber(B.Z, 0)
			if BX == 0 then BX = 1 end
			if BY == 0 then BY = 1 end
			if BZ == 0 then BZ = 1 end
			return MakeVector3int16(
				math.floor(ToNumber(A.X, 0) / BX),
				math.floor(ToNumber(A.Y, 0) / BY),
				math.floor(ToNumber(A.Z, 0) / BZ)
			)
		end,
		__sub = function(A, B)
			local AX = math.floor(ToNumber(A.X, 0))
			local AY = math.floor(ToNumber(A.Y, 0))
			local AZ = math.floor(ToNumber(A.Z, 0))
			local BX = math.floor(ToNumber(B.X, 0))
			local BY = math.floor(ToNumber(B.Y, 0))
			local BZ = math.floor(ToNumber(B.Z, 0))
			return MakeVector3int16(AX - BX, AY - BY, AZ - BZ)
		end,
		__eq = function(A, B)
			return math.floor(ToNumber(A.X, 0)) == math.floor(ToNumber(B.X, 0))
				and math.floor(ToNumber(A.Y, 0)) == math.floor(ToNumber(B.Y, 0))
				and math.floor(ToNumber(A.Z, 0)) == math.floor(ToNumber(B.Z, 0))
		end,
		__tostring = function(Self)
			return `{math.floor(ToNumber(Self.X, 0))}, {math.floor(ToNumber(Self.Y, 0))}, {math.floor(ToNumber(Self.Z, 0))}`
		end,
	})
end

UDimMeta.__add = function(A, B)
	local AS = ToNumber(A.Scale, 0)
	local AO = math.floor(ToNumber(A.Offset, 0))
	local BS = ToNumber(B.Scale, 0)
	local BO = math.floor(ToNumber(B.Offset, 0))
	return MakeUDim(AS + BS, AO + BO)
end

UDimMeta.__sub = function(A, B)
	local AS = ToNumber(A.Scale, 0)
	local AO = math.floor(ToNumber(A.Offset, 0))
	local BS = ToNumber(B.Scale, 0)
	local BO = math.floor(ToNumber(B.Offset, 0))
	return MakeUDim(AS - BS, AO - BO)
end

UDimMeta.__eq = function(A, B)
	return NearlyEqual(A.Scale, B.Scale)
		and math.floor(ToNumber(A.Offset, 0)) == math.floor(ToNumber(B.Offset, 0))
end

UDimMeta.__tostring = function(Self)
	return `{FormatNumber(Self.Scale)}, {math.floor(ToNumber(Self.Offset, 0))}`
end

MakeUDim = function(Scale, Offset)
	local Out = TagDataType("UDim", {
		Scale = ToNumber(Scale, 0),
		Offset = math.floor(ToNumber(Offset, 0)),
	})
	return setmetatable(Out, UDimMeta)
end

UDim2Meta.__index = function(Self, Key)
	if Key == "Width" then return rawget(Self, "X") end
	if Key == "Height" then return rawget(Self, "Y") end
	if Key == "Lerp" then
		return function(Target, Goal, Alpha)
			local A = ToNumber(Alpha, 0)
			local X = MakeUDim(
				ToNumber(Target.X.Scale, 0) + (ToNumber(Goal.X.Scale, 0) - ToNumber(Target.X.Scale, 0)) * A,
				math.floor(ToNumber(Target.X.Offset, 0) + (ToNumber(Goal.X.Offset, 0) - ToNumber(Target.X.Offset, 0)) * A)
			)
			local Y = MakeUDim(
				ToNumber(Target.Y.Scale, 0) + (ToNumber(Goal.Y.Scale, 0) - ToNumber(Target.Y.Scale, 0)) * A,
				math.floor(ToNumber(Target.Y.Offset, 0) + (ToNumber(Goal.Y.Offset, 0) - ToNumber(Target.Y.Offset, 0)) * A)
			)
			return MakeUDim2(X, Y)
		end
	end
	return rawget(Self, Key)
end

UDim2Meta.__add = function(A, B)
	return MakeUDim2(A.X + B.X, A.Y + B.Y)
end

UDim2Meta.__sub = function(A, B)
	return MakeUDim2(A.X - B.X, A.Y - B.Y)
end

UDim2Meta.__eq = function(A, B)
	return A.X == B.X and A.Y == B.Y
end

UDim2Meta.__tostring = function(Self)
	return "{" .. tostring(Self.X) .. "}, {" .. tostring(Self.Y) .. "}"
end

MakeUDim2 = function(A, B, C, D)
	if IsTypeTag(A, "UDim") and IsTypeTag(B, "UDim") then
		return setmetatable(TagDataType("UDim2", { X = A, Y = B }), UDim2Meta)
	end

	return setmetatable(TagDataType("UDim2", {
		X = MakeUDim(A, B),
		Y = MakeUDim(C, D),
	}), UDim2Meta)
end

local function Clamp01(Value)
	local Num = ToNumber(Value, 0)
	if Num < 0 then return 0 end
	if Num > 1 then return 1 end
	return Num
end

local function HSVtoRGB(H, S, V)
	H = Clamp01(H)
	S = Clamp01(S)
	V = Clamp01(V)

	local I = math.floor(H * 6)
	local F = H * 6 - I
	local P = V * (1 - S)
	local Q = V * (1 - F * S)
	local T = V * (1 - (1 - F) * S)
	local M = I % 6

	if M == 0 then return V, T, P end
	if M == 1 then return Q, V, P end
	if M == 2 then return P, V, T end
	if M == 3 then return P, Q, V end
	if M == 4 then return T, P, V end
	return V, P, Q
end

local function RGBtoHSV(R, G, B)
	local Max = math.max(R, G, B)
	local Min = math.min(R, G, B)
	local Delta = Max - Min
	local H = 0

	if Delta > 0 then
		if Max == R then
			H = ((G - B) / Delta) % 6
		elseif Max == G then
			H = ((B - R) / Delta) + 2
		else
			H = ((R - G) / Delta) + 4
		end
		H /= 6
	end

	local S = Max <= 0 and 0 or (Delta / Max)
	return H, S, Max
end

local function MakeColor3(R, G, B)
	return setmetatable(TagDataType("Color3", {
		R = Clamp01(R),
		G = Clamp01(G),
		B = Clamp01(B),
	}), Color3Meta)
end

Color3Meta.__index = function(Self, Key)
	if Key == "Lerp" then
		return function(Target, Goal, Alpha)
			local A = ToNumber(Alpha, 0)
			return MakeColor3(
				ToNumber(rawget(Target, "R"), 0) + (ToNumber(rawget(Goal, "R"), 0) - ToNumber(rawget(Target, "R"), 0)) * A,
				ToNumber(rawget(Target, "G"), 0) + (ToNumber(rawget(Goal, "G"), 0) - ToNumber(rawget(Target, "G"), 0)) * A,
				ToNumber(rawget(Target, "B"), 0) + (ToNumber(rawget(Goal, "B"), 0) - ToNumber(rawget(Target, "B"), 0)) * A
			)
		end
	end
	if Key == "ToHex" then
		return function(Target)
			local R = math.floor(Clamp01(ToNumber(rawget(Target, "R"), 0)) * 255 + 0.5)
			local G = math.floor(Clamp01(ToNumber(rawget(Target, "G"), 0)) * 255 + 0.5)
			local B = math.floor(Clamp01(ToNumber(rawget(Target, "B"), 0)) * 255 + 0.5)
			return string.format("%02x%02x%02x", R, G, B)
		end
	end
	if Key == "ToHSV" then
		return function(Target)
			return RGBtoHSV(
				Clamp01(ToNumber(rawget(Target, "R"), 0)),
				Clamp01(ToNumber(rawget(Target, "G"), 0)),
				Clamp01(ToNumber(rawget(Target, "B"), 0))
			)
		end
	end

	return rawget(Self, Key)
end

Color3Meta.__eq = function(A, B)
	return NearlyEqual(A.R, B.R) and NearlyEqual(A.G, B.G) and NearlyEqual(A.B, B.B)
end

Color3Meta.__tostring = function(Self)
	return `{FormatNumber(Self.R)}, {FormatNumber(Self.G)}, {FormatNumber(Self.B)}`
end

function MakeCFrame(...)
	local Args = table.pack(...)
	local X, Y, Z
	local Rx, Ry, Rz = 0, 0, 0

	if IsTypeTag(Args[1], "Vector3") then
		X = ToNumber(Args[1].X, 0)
		Y = ToNumber(Args[1].Y, 0)
		Z = ToNumber(Args[1].Z, 0)
		Rx = ToNumber(Args[2], 0)
		Ry = ToNumber(Args[3], 0)
		Rz = ToNumber(Args[4], 0)
	else
		X = ToNumber(Args[1], 0)
		Y = ToNumber(Args[2], 0)
		Z = ToNumber(Args[3], 0)
		Rx = ToNumber(Args[4], 0)
		Ry = ToNumber(Args[5], 0)
		Rz = ToNumber(Args[6], 0)
	end

	local Cf = {
		X = X,
		Y = Y,
		Z = Z,
		Rx = Rx,
		Ry = Ry,
		Rz = Rz,
	}

	Cf.GetComponents = function(Self)
		return Self.X, Self.Y, Self.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1
	end

	return setmetatable(TagDataType("CFrame", Cf), CFrameMeta)
end

local function MakeRect(MinX, MinY, MaxX, MaxY)
	local Min, Max
	if IsTypeTag(MinX, "Vector2") and IsTypeTag(MinY, "Vector2") then
		Min = MinX
		Max = MinY
	elseif typeof(MinX) == "table" and rawget(MinX, "X") and rawget(MinX, "Y") and typeof(MinY) == "table" and rawget(MinY, "X") and rawget(MinY, "Y") then
		Min = MakeVector2(MinX.X, MinX.Y)
		Max = MakeVector2(MinY.X, MinY.Y)
	else
		Min = MakeVector2(MinX, MinY)
		Max = MakeVector2(MaxX, MaxY)
	end
	local Out = setmetatable(TagDataType("Rect", {
		Min = Min,
		Max = Max,
	}), RectMeta)
	return Out
end

RectMeta.__index = function(Self, Key)
	if Key == "Width" then
		local MinX = ToNumber(Self.Min.X, 0)
		local MaxX = ToNumber(Self.Max.X, 0)
		return math.abs(MaxX - MinX)
	end
	if Key == "Height" then
		local MinY = ToNumber(Self.Min.Y, 0)
		local MaxY = ToNumber(Self.Max.Y, 0)
		return math.abs(MaxY - MinY)
	end
	return rawget(Self, Key)
end

local function MakeNumberRange(Min, Max)
	Min = ToNumber(Min, 0)
	Max = ToNumber(Max, Min)
	if Max < Min then
		error("NumberRange min must be <= max", 0)
	end

	return TagDataType("NumberRange", {
		Min = Min,
		Max = Max,
	})
end

local function MakePhysicalProperties(Density, Friction, Elasticity, FrictionWeight, ElasticityWeight)
	return TagDataType("PhysicalProperties", {
		Density = ToNumber(Density, 0.7),
		Friction = ToNumber(Friction, 0.3),
		Elasticity = ToNumber(Elasticity, 0.5),
		FrictionWeight = ToNumber(FrictionWeight, 1),
		ElasticityWeight = ToNumber(ElasticityWeight, 1),
	})
end

local function MakeRay(Origin, Direction)
	local O = IsTypeTag(Origin, "Vector3") and Origin or MakeVector3(0, 0, 0)
	local D = IsTypeTag(Direction, "Vector3") and Direction or MakeVector3(0, -1, 0)
	return TagDataType("Ray", {
		Origin = O,
		Direction = D,
	})
end

local function MakeRegion3(Min, Max)
	local MinVec = IsTypeTag(Min, "Vector3") and Min or MakeVector3(0, 0, 0)
	local MaxVec = IsTypeTag(Max, "Vector3") and Max or MakeVector3(4, 4, 4)
	local Obj = setmetatable(TagDataType("Region3", {
		Min = MinVec,
		Max = MaxVec,
	}), Region3Meta)
	return Obj
end

Region3Meta.__index = function(Self, Key)
	if Key == "Size" then
		local MinX = ToNumber(Self.Min.X, 0)
		local MinY = ToNumber(Self.Min.Y, 0)
		local MinZ = ToNumber(Self.Min.Z, 0)
		local MaxX = ToNumber(Self.Max.X, 0)
		local MaxY = ToNumber(Self.Max.Y, 0)
		local MaxZ = ToNumber(Self.Max.Z, 0)
		return MakeVector3(MaxX - MinX, MaxY - MinY, MaxZ - MinZ)
	end
	if Key == "CFrame" then
		local MinX = ToNumber(Self.Min.X, 0)
		local MinY = ToNumber(Self.Min.Y, 0)
		local MinZ = ToNumber(Self.Min.Z, 0)
		local MaxX = ToNumber(Self.Max.X, 0)
		local MaxY = ToNumber(Self.Max.Y, 0)
		local MaxZ = ToNumber(Self.Max.Z, 0)
		return MakeCFrame((MinX + MaxX) / 2, (MinY + MaxY) / 2, (MinZ + MaxZ) / 2)
	end
	if Key == "ExpandToGrid" then
		return function(Target, Resolution)
			local Grid = ToNumber(Resolution, 4)
			if Grid <= 0 then
				Grid = 4
			end

			local MinX = math.floor(ToNumber(Target.Min.X, 0) / Grid) * Grid
			local MinY = math.floor(ToNumber(Target.Min.Y, 0) / Grid) * Grid
			local MinZ = math.floor(ToNumber(Target.Min.Z, 0) / Grid) * Grid
			local MaxX = math.ceil(ToNumber(Target.Max.X, 0) / Grid) * Grid
			local MaxY = math.ceil(ToNumber(Target.Max.Y, 0) / Grid) * Grid
			local MaxZ = math.ceil(ToNumber(Target.Max.Z, 0) / Grid) * Grid

			return MakeRegion3(
				MakeVector3(MinX, MinY, MinZ),
				MakeVector3(MaxX, MaxY, MaxZ)
			)
		end
	end
	return rawget(Self, Key)
end

local function MakeRegion3int16(Min, Max)
	local MinVec = IsTypeTag(Min, "Vector3int16") and Min or MakeVector3int16(0, 0, 0)
	local MaxVec = IsTypeTag(Max, "Vector3int16") and Max or MakeVector3int16(4, 4, 4)
	return TagDataType("Region3int16", {
		Min = MinVec,
		Max = MaxVec,
	})
end

local function MakeTweenInfo(Time, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime)
	local Enums = require("../../Roblox/Enums")
	local Obj = TagDataType("TweenInfo", {
		Time = ToNumber(Time, 1),
		EasingStyle = EasingStyle or Enums.Get("EasingStyle", "Quad") or "Quad",
		EasingDirection = EasingDirection or Enums.Get("EasingDirection", "Out") or "Out",
		RepeatCount = math.floor(ToNumber(RepeatCount, 0)),
		Reverses = Reverses == true,
		DelayTime = ToNumber(DelayTime, 0),
	})
	return Obj
end

local function MakeRandom(Seed)
	local State = math.floor(ToNumber(Seed, os.clock() * 1000000))
	if State == 0 then
		State = 1
	end

	local function WithLocalSeed(Callback)
		math.randomseed(State)
		local Packed = table.pack(Callback())
		State = math.random(1, 2147483646)
		if State <= 0 then
			State = 1
		end
		return table.unpack(Packed, 1, Packed.n)
	end

	local Obj = {}
	Obj.NextNumber = function(_, Min, Max)
		if Min == nil and Max == nil then
			return WithLocalSeed(function()
				return math.random()
			end)
		end

		Min = ToNumber(Min, 0)
		Max = ToNumber(Max, 1)
		if Max < Min then
			Min, Max = Max, Min
		end

		return WithLocalSeed(function()
			return Min + (Max - Min) * math.random()
		end)
	end
	Obj.NextInteger = function(_, Min, Max)
		Min = math.floor(ToNumber(Min, 0))
		Max = math.floor(ToNumber(Max, 1))
		if Max < Min then
			Min, Max = Max, Min
		end

		return WithLocalSeed(function()
			return math.random(Min, Max)
		end)
	end
	Obj.Clone = function()
		return MakeRandom(State)
	end

	return TagDataType("Random", Obj)
end

local function MakeFont(Family, Weight, Style)
	return TagDataType("Font", {
		Family = tostring(Family or "SourceSans"),
		Weight = Weight or "Regular",
		Style = Style or "Normal",
	})
end

local function MakeColorSequenceKeypoint(Time, Value)
	if not IsTypeTag(Value, "Color3") then
		Value = MakeColor3(1, 1, 1)
	end
	return TagDataType("ColorSequenceKeypoint", {
		Time = Clamp01(Time),
		Value = Value,
	})
end

local function NormalizeColorSequenceKeypoint(Value, DefaultTime)
	if IsTypeTag(Value, "ColorSequenceKeypoint") then
		return MakeColorSequenceKeypoint(ToNumber(Value.Time, DefaultTime or 0), Value.Value)
	end

	if IsTypeTag(Value, "Color3") then
		return MakeColorSequenceKeypoint(DefaultTime or 0, Value)
	end

	if typeof(Value) == "table" then
		local Time = rawget(Value, "Time")
		local Color = rawget(Value, "Value")
		if IsTypeTag(Color, "Color3") then
			return MakeColorSequenceKeypoint(ToNumber(Time, DefaultTime or 0), Color)
		end
	end

	return MakeColorSequenceKeypoint(DefaultTime or 0, MakeColor3(1, 1, 1))
end

local function MakeColorSequence(Keypoints, GoalValue)
	if IsTypeTag(Keypoints, "Color3") then
		local Goal = IsTypeTag(GoalValue, "Color3") and GoalValue or Keypoints
		Keypoints = {
			MakeColorSequenceKeypoint(0, Keypoints),
			MakeColorSequenceKeypoint(1, Goal),
		}
	elseif typeof(Keypoints) == "table" then
		local Count = #Keypoints
		local Normalized = {}

		for Index, Entry in ipairs(Keypoints) do
			local DefaultTime = 0
			if Count > 1 then
				DefaultTime = (Index - 1) / (Count - 1)
			end
			Normalized[#Normalized + 1] = NormalizeColorSequenceKeypoint(Entry, DefaultTime)
		end

		if #Normalized == 1 then
			local Only = Normalized[1]
			Keypoints = {
				MakeColorSequenceKeypoint(0, Only.Value),
				MakeColorSequenceKeypoint(1, Only.Value),
			}
		elseif #Normalized >= 2 then
			table.sort(Normalized, function(A, B)
				return ToNumber(A.Time, 0) < ToNumber(B.Time, 0)
			end)
			Keypoints = Normalized
		else
			Keypoints = {
				MakeColorSequenceKeypoint(0, MakeColor3(1, 1, 1)),
				MakeColorSequenceKeypoint(1, MakeColor3(1, 1, 1)),
			}
		end
	else
		Keypoints = {
			MakeColorSequenceKeypoint(0, MakeColor3(1, 1, 1)),
			MakeColorSequenceKeypoint(1, MakeColor3(1, 1, 1)),
		}
	end
	return TagDataType("ColorSequence", {
		Keypoints = Keypoints,
	})
end

local function MakeNumberSequenceKeypoint(Time, Value, Envelope)
	return TagDataType("NumberSequenceKeypoint", {
		Time = Clamp01(Time),
		Value = ToNumber(Value, 0),
		Envelope = ToNumber(Envelope, 0),
	})
end

local function MakeNumberSequence(Keypoints, GoalValue)
	if typeof(Keypoints) == "number" then
		local Goal = typeof(GoalValue) == "number" and GoalValue or Keypoints
		Keypoints = {
			MakeNumberSequenceKeypoint(0, Keypoints, 0),
			MakeNumberSequenceKeypoint(1, Goal, 0),
		}
	elseif typeof(Keypoints) ~= "table" then
		Keypoints = {
			MakeNumberSequenceKeypoint(0, 0, 0),
			MakeNumberSequenceKeypoint(1, 1, 0),
		}
	end
	return TagDataType("NumberSequence", {
		Keypoints = Keypoints,
	})
end

local function MakeCatalogSearchParams()
	local Enums = require("../../Roblox/Enums")
	return TagDataType("CatalogSearchParams", {
		SearchKeyword = "",
		Limit = 0,
		MinPrice = 0,
		MaxPrice = 0,
		IncludeOffSale = false,
		SortType = Enums.Get("CatalogSortType", "Relevance"),
		SortAggregation = Enums.Get("CatalogSortAggregation", "AllTime"),
		CategoryFilter = Enums.Get("CatalogCategoryFilter", "None"),
		BundleTypes = MakeReadonlyProxy(nil, {}),
		AssetTypes = MakeReadonlyProxy(nil, {}),
		Subcategory = nil,
		SalesTypeFilter = Enums.Get("SalesTypeFilter", "All"),
		CreatorName = "",
		CreatorId = 0,
	})
end

local function MakeFloatCurve()
	return TagDataType("FloatCurve", {
		Keypoints = {},
	})
end

local function FreezeTableIfSupported(Value)
	if typeof(Value) ~= "table" then
		return Value
	end
	if typeof(table.freeze) == "function" then
		pcall(table.freeze, Value)
	end
	return Value
end

local function IsTableFrozen(Value)
	if typeof(Value) ~= "table" then
		return false
	end
	if rawget(Value, "__frozen") == true then
		return true
	end
	if typeof(table.isfrozen) == "function" then
		local Ok, Result = pcall(table.isfrozen, Value)
		if Ok then
			return Result == true
		end
	end
	return false
end

local function GetFrozenSharedTableData(Table)
	local Data = rawget(Table, "_LarryFrozenData")
	if typeof(Data) == "table" then
		return Data
	end
	return nil
end

local function EachSharedTableEntry(Table, Callback)
	if typeof(Table) ~= "table" or typeof(Callback) ~= "function" then
		return
	end

	local FrozenData = GetFrozenSharedTableData(Table)
	if FrozenData ~= nil then
		for Key, Value in next, FrozenData do
			Callback(Key, Value)
		end
		return
	end

	for Key, Value in next, Table do
		if Key ~= "__larryType" and Key ~= "__frozen" and Key ~= "_LarryFrozenData" then
			Callback(Key, Value)
		end
	end
end

local function MoveSharedTableIntoFrozenStorage(Table)
	if typeof(Table) ~= "table" then
		return nil
	end

	local FrozenData = GetFrozenSharedTableData(Table)
	if FrozenData ~= nil then
		return FrozenData
	end

	FrozenData = {}
	for Key, Value in next, Table do
		if Key ~= "__larryType" and Key ~= "__frozen" and Key ~= "_LarryFrozenData" then
			FrozenData[Key] = Value
			rawset(Table, Key, nil)
		end
	end
	rawset(Table, "_LarryFrozenData", FrozenData)
	return FrozenData
end

local function MakeSharedTable(Initial)
	local function ValidateKey(Key)
		if Key == nil then
			error("SharedTable invalid key: nil", 0)
		end
		local KeyType = typeof(Key)
		if KeyType ~= "string" and KeyType ~= "number" then
			error(`SharedTable invalid key: {KeyType}`, 0)
		end
		if KeyType == "number" and (Key ~= Key or Key == math.huge or Key == -math.huge or Key < 0 or Key % 1 ~= 0) then
			error("SharedTable invalid key: number", 0)
		end
	end

	local function ValidateValue(Value)
		if Value == nil then
			return
		end

		local ValueType = typeof(Value)
		if ValueType == "string" or ValueType == "boolean" then
			return
		end

		if ValueType == "number" then
			if Value ~= Value or Value == math.huge or Value == -math.huge then
				error("SharedTable invalid value: number", 0)
			end
			return
		end

		if ValueType == "table" then
			if getmetatable(Value) == SharedTableMeta or rawget(Value, "__larryType") ~= nil then
				return
			end
			error("SharedTable invalid value: table", 0)
		end

		error(`SharedTable invalid value: {ValueType}`, 0)
	end

	local Obj
	if typeof(Initial) == "table" then
		local Copy = {}
		for K, V in next, Initial do
			ValidateKey(K)
			ValidateValue(V)
			Copy[K] = V
		end
		Obj = TagDataType("SharedTable", Copy)
	else
		Obj = TagDataType("SharedTable", {})
	end
	setmetatable(Obj, SharedTableMeta)
	return Obj
end

SharedTableMeta.__newindex = function(Self, Key, Value)
	if IsTableFrozen(Self) then
		error("attempt to modify a frozen SharedTable", 0)
	end
	if Key == nil then
		error("SharedTable invalid key: nil", 0)
	end
	local KeyType = typeof(Key)
	if KeyType ~= "string" and KeyType ~= "number" then
		error(`SharedTable invalid key: {KeyType}`, 0)
	end
	if KeyType == "number" and (Key ~= Key or Key == math.huge or Key == -math.huge or Key < 0 or Key % 1 ~= 0) then
		error("SharedTable invalid key: number", 0)
	end
	local ValueType = typeof(Value)
	if Value ~= nil then
		if ValueType == "string" or ValueType == "boolean" then

		elseif ValueType == "number" then
			if Value ~= Value or Value == math.huge or Value == -math.huge then
				error("SharedTable invalid value: number", 0)
			end
		elseif ValueType == "table" then
			if getmetatable(Value) ~= SharedTableMeta and rawget(Value, "__larryType") == nil then
				error("SharedTable invalid value: table", 0)
			end
		else
			error(`SharedTable invalid value: {ValueType}`, 0)
		end
	end
	rawset(Self, Key, Value)
end

SharedTableMeta.__index = function(Self, Key)
	local FrozenData = GetFrozenSharedTableData(Self)
	if FrozenData ~= nil then
		return rawget(FrozenData, Key)
	end
	return nil
end

SharedTableMeta.__iter = function(Self)
	local Entries = {}
	EachSharedTableEntry(Self, function(Key, Value)
		Entries[#Entries + 1] = { Key, Value }
	end)
	local Cursor = 0
	return function()
		Cursor += 1
		local Entry = Entries[Cursor]
		if Entry ~= nil then
			return Entry[1], Entry[2]
		end
		return nil
	end, nil, nil
end

local function BitwiseAnd(A, B)
	local Left = math.max(0, math.floor(ToNumber(A, 0)))
	local Right = math.max(0, math.floor(ToNumber(B, 0)))
	local Result = 0
	local Bit = 1

	while Left > 0 or Right > 0 do
		local LeftBit = Left % 2
		local RightBit = Right % 2
		if LeftBit == 1 and RightBit == 1 then
			Result += Bit
		end
		Left = math.floor(Left / 2)
		Right = math.floor(Right / 2)
		Bit *= 2
	end

	return Result
end

local BrickColorPalette = {
	["Medium stone grey"] = { Number = 194, Color = { 0.639216, 0.635294, 0.647059 } },
	["Dark stone grey"] = { Number = 199, Color = { 0.388235, 0.372549, 0.384314 } },
	["Black"] = { Number = 26, Color = { 0.105882, 0.164706, 0.207843 } },
	["Bright red"] = { Number = 21, Color = { 0.768627, 0.156863, 0.109804 } },
	["Really red"] = { Number = 1004, Color = { 1, 0, 0 } },
	["Bright blue"] = { Number = 23, Color = { 0.05098, 0.411765, 0.67451 } },
	["Dark green"] = { Number = 28, Color = { 0.156863, 0.498039, 0.278431 } },
	["Bright green"] = { Number = 37, Color = { 0.294118, 0.592157, 0.294118 } },
	["Bright yellow"] = { Number = 24, Color = { 0.960784, 0.803922, 0.188235 } },
	["White"] = { Number = 1, Color = { 0.94902, 0.952941, 0.952941 } },
}

local BrickColorNumbers = {}
for Name, Info in next, BrickColorPalette do
	BrickColorNumbers[Info.Number] = {
		Name = Name,
		Color = Info.Color,
		Number = Info.Number,
	}
end

BrickColorMeta.__index = function(Self, Key)
	if Key == "Color" then
		local Color = rawget(Self, "_Color") or { 0.5, 0.5, 0.5 }
		return MakeColor3(Color[1], Color[2], Color[3])
	end
	if Key == "r" or Key == "R" then
		local Color = rawget(Self, "_Color") or { 0.5, 0.5, 0.5 }
		return Color[1]
	end
	if Key == "g" or Key == "G" then
		local Color = rawget(Self, "_Color") or { 0.5, 0.5, 0.5 }
		return Color[2]
	end
	if Key == "b" or Key == "B" then
		local Color = rawget(Self, "_Color") or { 0.5, 0.5, 0.5 }
		return Color[3]
	end
	return rawget(Self, Key)
end

BrickColorMeta.__tostring = function(Self)
	return tostring(rawget(Self, "Name") or "Medium stone grey")
end

local function MakeBrickColor(Value)
	local Info
	if typeof(Value) == "number" then
		Info = BrickColorNumbers[math.floor(Value)]
		if Info == nil then
			Info = {
				Name = tostring(Value),
				Color = { 0.5, 0.5, 0.5 },
				Number = math.floor(Value),
			}
		end
	else
		local function ReadColor3(Input)
			if IsTypeTag(Input, "Color3") then
				return Clamp01(ToNumber(rawget(Input, "R"), 0)), Clamp01(ToNumber(rawget(Input, "G"), 0)), Clamp01(ToNumber(rawget(Input, "B"), 0))
			end
			if typeof(Input) == "table" then
				local R = rawget(Input, "R")
				local G = rawget(Input, "G")
				local B = rawget(Input, "B")
				if IsFiniteNumber(R) and IsFiniteNumber(G) and IsFiniteNumber(B) then
					return Clamp01(ToNumber(R, 0)), Clamp01(ToNumber(G, 0)), Clamp01(ToNumber(B, 0))
				end
			end
			return nil
		end

		local R, G, B = ReadColor3(Value)
		if R ~= nil then
			local BestName = nil
			local BestInfo = nil
			local BestDist = nil
			for Name, Candidate in next, BrickColorPalette do
				local Cr, Cg, Cb = Candidate.Color[1], Candidate.Color[2], Candidate.Color[3]
				local Dist = (R - Cr) * (R - Cr) + (G - Cg) * (G - Cg) + (B - Cb) * (B - Cb)
				if BestDist == nil or Dist < BestDist then
					BestDist = Dist
					BestName = Name
					BestInfo = Candidate
				end
			end
			if BestInfo ~= nil then
				Info = {
					Name = BestName,
					Color = BestInfo.Color,
					Number = BestInfo.Number,
				}
			end
		end

		if Info == nil then
			local Name = tostring(Value or "Medium stone grey")
			Info = BrickColorPalette[Name]
			if Info == nil then
				Info = {
					Name = Name,
					Color = { 0.5, 0.5, 0.5 },
					Number = 194,
				}
			else
				Info = {
					Name = Name,
					Color = Info.Color,
					Number = Info.Number,
				}
			end
		end
	end

	return setmetatable(TagDataType("BrickColor", {
		Name = Info.Name,
		Number = Info.Number,
		_Color = Info.Color,
	}), BrickColorMeta)
end

local function ResolveFontEnum(EnumName, Value, DefaultName)
	local Enums = require("../../Roblox/Enums")
	if typeof(Value) == "table" and rawget(Value, "_EnumType") == EnumName then
		return Value
	end
	if typeof(Value) == "string" then
		return Enums.Get(EnumName, Value) or Value
	end
	return Enums.Get(EnumName, DefaultName) or DefaultName
end

local function MakeFont(Family, Weight, Style)
	return TagDataType("Font", {
		Family = tostring(Family or "SourceSans"),
		Weight = ResolveFontEnum("FontWeight", Weight, "Regular"),
		Style = ResolveFontEnum("FontStyle", Style, "Normal"),
	})
end

local function MakeAxes(...)
	local Args = { ... }
	local Flags = {}
	local X, Y, Z, Top, Bottom, Front, Back, Left, Right = false, false, false, false, false, false, false, false, false
	local NormalToAxis = {
		Top = "Y",
		Bottom = "Y",
		Front = "Z",
		Back = "Z",
		Left = "X",
		Right = "X",
	}

	for _, Arg in Args do
		if typeof(Arg) == "table" and rawget(Arg, "_Name") then
			local Name = rawget(Arg, "_Name")
			Flags[Name] = true
			if Name == "X" then X = true end
			if Name == "Y" then Y = true end
			if Name == "Z" then Z = true end
			if Name == "Top" then Top = true; Y = true end
			if Name == "Bottom" then Bottom = true; Y = true end
			if Name == "Front" then Front = true; Z = true end
			if Name == "Back" then Back = true; Z = true end
			if Name == "Left" then Left = true; X = true end
			if Name == "Right" then Right = true; X = true end
			local Axis = NormalToAxis[Name]
			if Axis then
				Flags[Axis] = true
			end
		end
	end

	return TagDataType("Axes", {
		Flags = Flags,
		X = X,
		Y = Y,
		Z = Z,
		Top = Top,
		Bottom = Bottom,
		Front = Front,
		Back = Back,
		Left = Left,
		Right = Right,
	})
end

local function MakeFaces(...)
	local Args = { ... }
	local Top, Bottom, Front, Back, Left, Right = false, false, false, false, false, false

	if #Args == 0 then
		Top, Bottom, Front, Back, Left, Right = true, true, true, true, true, true
	end

	for _, Arg in ipairs(Args) do
		local Name = typeof(Arg) == "table" and (rawget(Arg, "_Name") or rawget(Arg, "Name")) or tostring(Arg)
		if Name == "Top" then Top = true end
		if Name == "Bottom" then Bottom = true end
		if Name == "Front" then Front = true end
		if Name == "Back" then Back = true end
		if Name == "Left" then Left = true end
		if Name == "Right" then Right = true end
	end

	return MakeReadonlyProxy("Faces", {
		Top = Top,
		Bottom = Bottom,
		Front = Front,
		Back = Back,
		Left = Left,
		Right = Right,
		top = Top,
		bottom = Bottom,
		front = Front,
		back = Back,
		left = Left,
		right = Right,
	})
end

local function MakeContent(Value)
	local Uri = tostring(Value or "")
	return TagDataType("Content", {
		Uri = Uri,
		Value = Uri,
		ToString = function(Self)
			return tostring(Self.Uri or "")
		end,
	})
end

local function MakeDateTimeFromUnixSeconds(Seconds)
	local Sec = ToNumber(Seconds, os.time())
	local Whole = math.floor(Sec)
	local Millis = math.floor((Sec - Whole) * 1000 + 0.5)

	local T = os.date("!*t", Whole)

	local Obj = {
		UnixTimestamp = Whole,
		UnixTimestampMillis = Whole * 1000 + Millis,
		Year = T.year,
		Month = T.month,
		Day = T.day,
		Hour = T.hour,
		Minute = T.min,
		Second = T.sec,
	}

	local function ToPlainDateTable(Source)
		local Plain = {}
		for Key, Value in next, Source do
			if Key ~= "__larryType" then
				Plain[Key] = Value
			end
		end
		rawset(Plain, "__larryType", nil)
		return Plain
	end

	Obj.ToLocalTime = function(Self)
		local LocalT = os.date("*t", Self.UnixTimestamp)
		local LocalObj = MakeDateTimeFromUnixSeconds(Self.UnixTimestamp)
		LocalObj.Year = LocalT.year
		LocalObj.Month = LocalT.month
		LocalObj.Day = LocalT.day
		LocalObj.Hour = LocalT.hour
		LocalObj.Minute = LocalT.min
		LocalObj.Second = LocalT.sec
		return ToPlainDateTable(LocalObj)
	end

	Obj.ToUniversalTime = function(Self)
		return ToPlainDateTable(MakeDateTimeFromUnixSeconds(Self.UnixTimestamp))
	end

	Obj.ToIsoDate = function(Self)
		return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", T.year, T.month, T.day, T.hour, T.min, T.sec)
	end

	Obj.FormatLocalTime = function(Self, _Locale, _Fmt)
		return os.date("%Y-%m-%d %H:%M:%S", Self.UnixTimestamp)
	end

	return TagDataType("DateTime", Obj)
end

local function MakeFloatCurveKey(Time, Value, Interpolation)
	return TagDataType("FloatCurveKey", {
		Time = ToNumber(Time, 0),
		Value = ToNumber(Value, 0),
		Interpolation = Interpolation or "Linear",
	})
end

local function MakeRotationCurveKey(Time, Value, Interpolation)
	local RotValue = Value
	if not IsTypeTag(RotValue, "CFrame") then
		RotValue = MakeCFrame(0, 0, 0)
	end

	return TagDataType("RotationCurveKey", {
		Time = ToNumber(Time, 0),
		Value = RotValue,
		Interpolation = Interpolation or "Linear",
		LeftTangent = ToNumber(Time, 0),
		RightTangent = ToNumber(Time, 0),
	})
end

local function MakePath2DControlPoint(Position, LeftTangent, RightTangent)
	local Pos = IsTypeTag(Position, "Vector2") and Position or MakeVector2(0, 0)
	local Left = IsTypeTag(LeftTangent, "Vector2") and LeftTangent or Pos
	local Right = IsTypeTag(RightTangent, "Vector2") and RightTangent or Pos

	return TagDataType("Path2DControlPoint", {
		Position = Pos,
		LeftTangent = Left,
		RightTangent = Right,
	})
end

local function MakePathWaypoint(Position, Action, Label)
	local Pos = IsTypeTag(Position, "Vector3") and Position or MakeVector3(0, 0, 0)
	return TagDataType("PathWaypoint", {
		Position = Pos,
		Action = Action or "Walk",
		Label = Label and tostring(Label) or "",
	})
end

local function MakeSecurityCapabilities(Value)
	if typeof(Value) == "table" and rawget(Value, "__larryType") == "SecurityCapabilities" then
		Value = rawget(Value, "Value")
	elseif typeof(Value) == "table" and rawget(Value, "_EnumType") == "SecurityCapability" then
		local EnumValue = math.floor(ToNumber(rawget(Value, "_Value") or rawget(Value, "Value"), 0))
		Value = 2 ^ math.max(EnumValue, 0)
	end
	local Obj = TagDataType("SecurityCapabilities", {
		Value = math.floor(ToNumber(Value, 0)),
	})
	setmetatable(Obj, {
		__add = function(Self, Other)
			local OtherVal = 0
			if typeof(Other) == "table" and rawget(Other, "__larryType") == "SecurityCapabilities" then
				OtherVal = rawget(Other, "Value") or 0
			elseif typeof(Other) == "table" and rawget(Other, "_EnumType") == "SecurityCapability" then
				local EnumValue = math.floor(ToNumber(rawget(Other, "_Value") or rawget(Other, "Value"), 0))
				OtherVal = 2 ^ math.max(EnumValue, 0)
			else
				OtherVal = math.floor(ToNumber(Other, 0))
			end
			local Current = rawget(Self, "Value")
			if OtherVal > 0 and BitwiseAnd(Current, OtherVal) == OtherVal then
				return MakeSecurityCapabilities(Current)
			end
			return MakeSecurityCapabilities(Current + OtherVal)
		end,
		__sub = function(Self, Other)
			local OtherVal = 0
			if typeof(Other) == "table" and rawget(Other, "__larryType") == "SecurityCapabilities" then
				OtherVal = rawget(Other, "Value") or 0
			elseif typeof(Other) == "table" and rawget(Other, "_EnumType") == "SecurityCapability" then
				local EnumValue = math.floor(ToNumber(rawget(Other, "_Value") or rawget(Other, "Value"), 0))
				OtherVal = 2 ^ math.max(EnumValue, 0)
			else
				OtherVal = math.floor(ToNumber(Other, 0))
			end
			local Current = rawget(Self, "Value")
			if OtherVal <= 0 or BitwiseAnd(Current, OtherVal) ~= OtherVal then
				return MakeSecurityCapabilities(Current)
			end
			return MakeSecurityCapabilities(math.max(0, Current - OtherVal))
		end,
		__index = function(Self, Key)
			if Key == "Add" then
				return function(_, Other)
					local OtherVal = 0
					if typeof(Other) == "table" and rawget(Other, "__larryType") == "SecurityCapabilities" then
						OtherVal = rawget(Other, "Value") or 0
					elseif typeof(Other) == "table" and rawget(Other, "_EnumType") == "SecurityCapability" then
						local EnumValue = math.floor(ToNumber(rawget(Other, "_Value") or rawget(Other, "Value"), 0))
						OtherVal = 2 ^ math.max(EnumValue, 0)
					else
						OtherVal = math.floor(ToNumber(Other, 0))
					end
					local Current = rawget(Self, "Value")
					if OtherVal > 0 and BitwiseAnd(Current, OtherVal) == OtherVal then
						return MakeSecurityCapabilities(Current)
					end
					return MakeSecurityCapabilities(Current + OtherVal)
				end
			end
			if Key == "Remove" then
				return function(_, Other)
					local OtherVal = 0
					if typeof(Other) == "table" and rawget(Other, "__larryType") == "SecurityCapabilities" then
						OtherVal = rawget(Other, "Value") or 0
					elseif typeof(Other) == "table" and rawget(Other, "_EnumType") == "SecurityCapability" then
						local EnumValue = math.floor(ToNumber(rawget(Other, "_Value") or rawget(Other, "Value"), 0))
						OtherVal = 2 ^ math.max(EnumValue, 0)
					else
						OtherVal = math.floor(ToNumber(Other, 0))
					end
					local Current = rawget(Self, "Value")
					if OtherVal <= 0 or BitwiseAnd(Current, OtherVal) ~= OtherVal then
						return MakeSecurityCapabilities(Current)
					end
					return MakeSecurityCapabilities(math.max(0, Current - OtherVal))
				end
			end
			if Key == "Contains" then
				return function(_, Other)
					local OtherVal = 0
					if typeof(Other) == "table" and rawget(Other, "__larryType") == "SecurityCapabilities" then
						OtherVal = rawget(Other, "Value") or 0
					elseif typeof(Other) == "table" and rawget(Other, "_EnumType") == "SecurityCapability" then
						local EnumValue = math.floor(ToNumber(rawget(Other, "_Value") or rawget(Other, "Value"), 0))
						OtherVal = 2 ^ math.max(EnumValue, 0)
					else
						OtherVal = math.floor(ToNumber(Other, 0))
					end
					return OtherVal > 0 and BitwiseAnd(rawget(Self, "Value"), OtherVal) == OtherVal
				end
			end
			return rawget(Self, Key)
		end,
	})
	return Obj
end

local 	FallbackLibs = {
	Vector2 = {
		new = MakeVector2,
		zero = MakeVector2(0, 0),
		one = MakeVector2(1, 1),
		xAxis = MakeVector2(1, 0),
		yAxis = MakeVector2(0, 1),
	},
	Vector3 = {
		new = MakeVector3,
		zero = MakeVector3(0, 0, 0),
		one = MakeVector3(1, 1, 1),
		xAxis = MakeVector3(1, 0, 0),
		yAxis = MakeVector3(0, 1, 0),
		zAxis = MakeVector3(0, 0, 1),
		FromNormalId = function(NormalId)
			local Name = typeof(NormalId) == "table" and (rawget(NormalId, "_Name") or rawget(NormalId, "Name")) or tostring(NormalId)
			if Name == "Top" then return MakeVector3(0, 1, 0) end
			if Name == "Bottom" then return MakeVector3(0, -1, 0) end
			if Name == "Front" then return MakeVector3(0, 0, -1) end
			if Name == "Back" then return MakeVector3(0, 0, 1) end
			if Name == "Left" then return MakeVector3(-1, 0, 0) end
			if Name == "Right" then return MakeVector3(1, 0, 0) end
			return MakeVector3(0, 0, 0)
		end,
		FromAxis = function(Axis)
			local Name = typeof(Axis) == "table" and (rawget(Axis, "_Name") or rawget(Axis, "Name")) or tostring(Axis)
			if Name == "X" then return MakeVector3(1, 0, 0) end
			if Name == "Y" then return MakeVector3(0, 1, 0) end
			if Name == "Z" then return MakeVector3(0, 0, 1) end
			return MakeVector3(0, 0, 0)
		end,
	},
	Vector2int16 = {
		new = MakeVector2int16,
	},
	Vector3int16 = {
		new = MakeVector3int16,
	},
	UDim = {
		new = MakeUDim,
	},
	UDim2 = {
		new = MakeUDim2,
		fromScale = function(X, Y)
			return MakeUDim2(ToNumber(X, 0), 0, ToNumber(Y, 0), 0)
		end,
		fromOffset = function(X, Y)
			return MakeUDim2(0, math.floor(ToNumber(X, 0)), 0, math.floor(ToNumber(Y, 0)))
		end,
	},
	Color3 = {
		new = MakeColor3,
		fromRGB = function(R, G, B)
			return MakeColor3(ToNumber(R, 0) / 255, ToNumber(G, 0) / 255, ToNumber(B, 0) / 255)
		end,
		fromHSV = function(H, S, V)
			local R, G, B = HSVtoRGB(H, S, V)
			return MakeColor3(R, G, B)
		end,
		fromHex = function(Hex)
			local HexStr = tostring(Hex)
			if string.sub(HexStr, 1, 1) == "#" then
				HexStr = string.sub(HexStr, 2)
			end
			if #HexStr == 3 then
				HexStr = string.rep(string.sub(HexStr, 1, 1), 2)
					.. string.rep(string.sub(HexStr, 2, 2), 2)
					.. string.rep(string.sub(HexStr, 3, 3), 2)
			end
			if #HexStr == 6 then
				local R = tonumber(string.sub(HexStr, 1, 2), 16) or 0
				local G = tonumber(string.sub(HexStr, 3, 4), 16) or 0
				local B = tonumber(string.sub(HexStr, 5, 6), 16) or 0
				return MakeColor3(R / 255, G / 255, B / 255)
			end
			return MakeColor3(0, 0, 0)
		end,
	},
	CFrame = {
		new = MakeCFrame,
		Angles = function(Rx, Ry, Rz)
			return MakeCFrame(0, 0, 0, ToNumber(Rx, 0), ToNumber(Ry, 0), ToNumber(Rz, 0))
		end,
		fromEulerAngles = function(Rx, Ry, Rz)
			return MakeCFrame(0, 0, 0, ToNumber(Rx, 0), ToNumber(Ry, 0), ToNumber(Rz, 0))
		end,
		fromOrientation = function(Rx, Ry, Rz)
			return MakeCFrame(0, 0, 0, ToNumber(Rx, 0), ToNumber(Ry, 0), ToNumber(Rz, 0))
		end,
		fromAxisAngle = function(Axis, Angle)
			local Ax, Ay, Az = ReadVector3(Axis)
			local Theta = ToNumber(Angle, 0)
			return MakeCFrame(0, 0, 0, Ax * Theta, Ay * Theta, Az * Theta)
		end,
		fromMatrix = function(Position, VX, VY, VZ)
			local X, Y, Z = ReadVector3(Position)
			local RX, RY, RZ = ReadVector3(VX)
			local UX, UY, UZ = ReadVector3(VY)
			local LX, LY, LZ = ReadVector3(VZ)
			if not IsFiniteNumber(LX) or not IsFiniteNumber(LY) or not IsFiniteNumber(LZ) or (LX == 0 and LY == 0 and LZ == 0) then
				LX = (RY * UZ) - (RZ * UY)
				LY = (RZ * UX) - (RX * UZ)
				LZ = (RX * UY) - (RY * UX)
			end
			return setmetatable({
				X = X,
				Y = Y,
				Z = Z,
				Rx = RX,
				Ry = RY,
				Rz = RZ,
				Ux = UX,
				Uy = UY,
				Uz = UZ,
				Lx = LX,
				Ly = LY,
				Lz = LZ,
				__larryType = "CFrame",
			}, CFrameMeta)
		end,
		fromEulerAnglesXYZ = function(Rx, Ry, Rz)
			return MakeCFrame(0, 0, 0, ToNumber(Rx, 0), ToNumber(Ry, 0), ToNumber(Rz, 0))
		end,
		fromEulerAnglesYXZ = function(Rx, Ry, Rz)
			return MakeCFrame(0, 0, 0, ToNumber(Rx, 0), ToNumber(Ry, 0), ToNumber(Rz, 0))
		end,
		lookAt = function(Eye, Target, Up)
			local Ex, Ey, Ez = ReadVector3(Eye)
			local Tx, Ty, Tz = ReadVector3(Target)
			local UpVec = Up or MakeVector3(0, 1, 0)
			local Ux, Uy, Uz = ReadVector3(UpVec)
			return BuildLookBasis(Ex, Ey, Ez, Tx - Ex, Ty - Ey, Tz - Ez, Ux, Uy, Uz)
		end,
		lookAlong = function(Position, Direction, Up)
			local Eye = Position or MakeVector3(0, 0, 0)
			local Dir = Direction or MakeVector3(0, 0, -1)
			local Ex, Ey, Ez = ReadVector3(Eye)
			local Dx, Dy, Dz = ReadVector3(Dir)
			local UpVec = Up or MakeVector3(0, 1, 0)
			local Ux, Uy, Uz = ReadVector3(UpVec)
			return BuildLookBasis(Ex, Ey, Ez, Dx, Dy, Dz, Ux, Uy, Uz)
		end,
		fromRotationBetweenVectors = function(From, To)
			local Fx, Fy, Fz = ReadVector3(From)
			local Tx, Ty, Tz = ReadVector3(To)
			return MakeCFrame(0, 0, 0, Tx - Fx, Ty - Fy, Tz - Fz)
		end,
		identity = MakeCFrame(0, 0, 0, 0, 0, 0),
	},
	Rect = {
		new = MakeRect,
	},
	NumberRange = {
		new = MakeNumberRange,
	},
	PhysicalProperties = {
		new = MakePhysicalProperties,
	},
	Ray = {
		new = function(Origin, Direction)
			local O = IsTypeTag(Origin, "Vector3") and Origin or MakeVector3(0, 0, 0)
			local D = IsTypeTag(Direction, "Vector3") and Direction or MakeVector3(0, -1, 0)
			local Obj = TagDataType("Ray", {
				Origin = O,
				Direction = D,
			})
			Obj.ClosestPoint = function(Self, Point)
				local OX, OY, OZ = ReadVector3(Self.Origin)
				local DX, DY, DZ = ReadVector3(Self.Direction)
				local PX, PY, PZ = ReadVector3(Point)
				local DirLenSq = DX * DX + DY * DY + DZ * DZ
				if DirLenSq == 0 then
					return MakeVector3(OX, OY, OZ)
				end
				local T = ((PX - OX) * DX + (PY - OY) * DY + (PZ - OZ) * DZ) / DirLenSq
				if T < 0 then T = 0 end
				if T > 1 then T = 1 end
				return MakeVector3(OX + DX * T, OY + DY * T, OZ + DZ * T)
			end
			return Obj
		end,
	},
	Region3 = {
		new = MakeRegion3,
	},
	Region3int16 = {
		new = MakeRegion3int16,
	},
	TweenInfo = {
		new = MakeTweenInfo,
	},
	Random = {
		new = function(Seed)
			local Obj = MakeRandom(Seed)
			Obj.NextUnitVector = function()
				local u = math.random() * 2 * math.pi
				local v = math.random() * 2 * math.pi
				local x = math.cos(u) * math.sin(v)
				local y = math.sin(u) * math.sin(v)
				local z = math.cos(v)
				return MakeVector3(x, y, z)
			end
			return Obj
		end,
	},
	Font = {
		new = MakeFont,
		fromEnum = function(FontEnum)
			local Family = typeof(FontEnum) == "table" and rawget(FontEnum, "_Name") or "SourceSans"
			return MakeFont(Family, "Regular", "Normal")
		end,
		fromName = function(Name)
			return MakeFont(Name, "Regular", "Normal")
		end,
	},
	ColorSequence = {
		new = MakeColorSequence,
	},
	ColorSequenceKeypoint = {
		new = MakeColorSequenceKeypoint,
	},
	NumberSequence = {
		new = MakeNumberSequence,
	},
	NumberSequenceKeypoint = {
		new = MakeNumberSequenceKeypoint,
	},
	RaycastParams = {
		new = function()
			local Enums = require("../../Roblox/Enums")
			return TagDataType("RaycastParams", {
				FilterDescendantsInstances = {},
				FilterType = Enums.Get("RaycastFilterType", "Exclude") or "Exclude",
				IgnoreWater = false,
				CollisionGroup = "Default",
			})
		end,
	},
	OverlapParams = {
		new = function()
			local Enums = require("../../Roblox/Enums")
			return TagDataType("OverlapParams", {
				FilterDescendantsInstances = {},
				FilterType = Enums.Get("RaycastFilterType", "Exclude") or "Exclude",
				MaxParts = 0,
				CollisionGroup = "Default",
			})
		end,
	},
	Axes = {
		new = MakeAxes,
	},
	Faces = (function()
		local function FreezeFaces(Obj)
			if typeof(table.freeze) == "function" then
				pcall(table.freeze, Obj)
			end
			return Obj
		end
		local FacesLib = {
			new = MakeFaces,
			Top = FreezeFaces(MakeFaces("Top")),
			Bottom = FreezeFaces(MakeFaces("Bottom")),
			Front = FreezeFaces(MakeFaces("Front")),
			Back = FreezeFaces(MakeFaces("Back")),
			Left = FreezeFaces(MakeFaces("Left")),
			Right = FreezeFaces(MakeFaces("Right")),
			top = FreezeFaces(MakeFaces("Top")),
			bottom = FreezeFaces(MakeFaces("Bottom")),
			front = FreezeFaces(MakeFaces("Front")),
			back = FreezeFaces(MakeFaces("Back")),
			left = FreezeFaces(MakeFaces("Left")),
			right = FreezeFaces(MakeFaces("Right")),
		}
		if typeof(table.freeze) == "function" then
			table.freeze(FacesLib)
		end
		return FacesLib
	end)(),
	BrickColor = {
		new = MakeBrickColor,
		White = function()
			return MakeBrickColor("White")
		end,
		Black = function()
			return MakeBrickColor("Black")
		end,
		Red = function()
			return MakeBrickColor("Bright red")
		end,
		Blue = function()
			return MakeBrickColor("Bright blue")
		end,
		Yellow = function()
			return MakeBrickColor("Bright yellow")
		end,
		Green = function()
			return MakeBrickColor("Dark green")
		end,
		Gray = function()
			return MakeBrickColor("Medium stone grey")
		end,
		DarkGray = function()
			return MakeBrickColor("Dark stone grey")
		end,
		palette = function(Index)
			local Choices = {}
			for Name in next, BrickColorPalette do
				table.insert(Choices, Name)
			end
			table.sort(Choices)
			local NumericIndex = math.floor(ToNumber(Index, 1))
			if NumericIndex < 1 then
				NumericIndex = 1
			end
			local Slot = ((NumericIndex - 1) % #Choices) + 1
			return MakeBrickColor(Choices[Slot])
		end,
		random = function()
			local Choices = {}
			for Name in next, BrickColorPalette do
				table.insert(Choices, Name)
			end
			table.sort(Choices)
			return MakeBrickColor(Choices[math.random(1, #Choices)])
		end,
	},
	CatalogSearchParams = {
		new = MakeCatalogSearchParams,
	},
	FloatCurve = {
		new = MakeFloatCurve,
	},
	SharedTable = {
		new = MakeSharedTable,
		size = function(Table)
			local Count = 0
			if typeof(Table) == "table" then
				EachSharedTableEntry(Table, function(_Key, _Value)
					Count += 1
				end)
			end
			return Count
		end,
		clear = function(Table)
			if typeof(Table) == "table" then
				if IsTableFrozen(Table) then
					error("attempt to modify a frozen SharedTable", 0)
				end
				for Key in next, Table do
					if Key ~= "__larryType" and Key ~= "__frozen" and Key ~= "_LarryFrozenData" then
						rawset(Table, Key, nil)
					end
				end
			end
			return Table
		end,
		clone = function(Table)
			local Copy = MakeSharedTable()
			if typeof(Table) == "table" then
				EachSharedTableEntry(Table, function(Key, Value)
					rawset(Copy, Key, Value)
				end)
			end
			return Copy
		end,
		freeze = function(Table)
			if typeof(Table) == "table" then
				rawset(Table, "__frozen", true)
				MoveSharedTableIntoFrozenStorage(Table)
				FreezeTableIfSupported(Table)
			end
			return Table
		end,
		isFrozen = function(Table)
			return IsTableFrozen(Table)
		end,
		cloneAndFreeze = function(Table)
			local Copy = MakeSharedTable()
			if typeof(Table) == "table" then
				EachSharedTableEntry(Table, function(Key, Value)
					rawset(Copy, Key, Value)
				end)
			end
			rawset(Copy, "__frozen", true)
			MoveSharedTableIntoFrozenStorage(Copy)
			FreezeTableIfSupported(Copy)
			return Copy
		end,
		increment = function(Table, Key, Delta)
			if typeof(Table) ~= "table" then
				error("SharedTable.increment expects SharedTable", 0)
			end
			if IsTableFrozen(Table) then
				error("attempt to modify a frozen SharedTable", 0)
			end

			if Key == nil then
				error("SharedTable invalid key: nil", 0)
			end
			local KeyType = typeof(Key)
			if KeyType ~= "string" and KeyType ~= "number" then
				error(`SharedTable invalid key: {KeyType}`, 0)
			end
			if KeyType == "number" and (Key ~= Key or Key == math.huge or Key == -math.huge or Key < 0 or Key % 1 ~= 0) then
				error("SharedTable invalid key: number", 0)
			end

			local Step = Delta
			if Step == nil then
				Step = 1
			elseif typeof(Step) ~= "number" or Step ~= Step or Step == math.huge or Step == -math.huge then
				error("SharedTable.increment expects number delta", 0)
			end

			local Current = Table[Key]
			if Current == nil then
				Current = 0
			elseif typeof(Current) ~= "number" or Current ~= Current or Current == math.huge or Current == -math.huge then
				error("SharedTable.increment expects number value", 0)
			end

			local NextValue = Current + Step
			if NextValue ~= NextValue or NextValue == math.huge or NextValue == -math.huge then
				error("SharedTable invalid value: number", 0)
			end
			Table[Key] = NextValue
			return Current
		end,
		update = function(Table, Key, Callback)
			if typeof(Table) ~= "table" then
				error("SharedTable.update expects SharedTable", 0)
			end
			if IsTableFrozen(Table) then
				error("attempt to modify a frozen SharedTable", 0)
			end
			if typeof(Callback) ~= "function" then
				error("SharedTable.update expects function callback", 0)
			end

			if Key == nil then
				error("SharedTable invalid key: nil", 0)
			end
			local KeyType = typeof(Key)
			if KeyType ~= "string" and KeyType ~= "number" then
				error(`SharedTable invalid key: {KeyType}`, 0)
			end
			if KeyType == "number" and (Key ~= Key or Key == math.huge or Key == -math.huge or Key < 0 or Key % 1 ~= 0) then
				error("SharedTable invalid key: number", 0)
			end

			local Current = Table[Key]
			local NextValue = Callback(Current)
			if NextValue == nil then
				NextValue = Current
			end

			if NextValue ~= nil then
				local ValueType = typeof(NextValue)
				if ValueType == "number" then
					if NextValue ~= NextValue or NextValue == math.huge or NextValue == -math.huge then
						error("SharedTable invalid value: number", 0)
					end
				elseif ValueType == "table" then
					if getmetatable(NextValue) ~= SharedTableMeta and rawget(NextValue, "__larryType") == nil then
						error("SharedTable invalid value: table", 0)
					end
				elseif ValueType ~= "string" and ValueType ~= "boolean" then
					error(`SharedTable invalid value: {ValueType}`, 0)
				end
			end

			Table[Key] = NextValue
			return Current
		end,
	},
	Content = {
		fromUri = function(Uri)
			return MakeContent(Uri)
		end,
		new = function(Uri)
			return MakeContent(Uri)
		end,
	},
	DateTime = {
		now = function()
			local Ok, RuntimeClock = pcall(require, "../RuntimeClock")
			if Ok and typeof(RuntimeClock) == "table" and typeof(RuntimeClock.GetServerNow) == "function" then
				return MakeDateTimeFromUnixSeconds(RuntimeClock.GetServerNow())
			end
			return MakeDateTimeFromUnixSeconds(os.time() + (os.clock() % 1))
		end,
		fromUnixTimestamp = function(Seconds)
			return MakeDateTimeFromUnixSeconds(Seconds)
		end,
		fromUnixTimestampMillis = function(Millis)
			return MakeDateTimeFromUnixSeconds(ToNumber(Millis, 0) / 1000)
		end,
		fromIsoDate = function(Iso)
			if typeof(Iso) ~= "string" then
				return MakeDateTimeFromUnixSeconds(os.time())
			end

			local Year, Month, Day, Hour, Minute, Second = string.match(Iso, "^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
			if Year then
				local Timestamp = os.time({
					year = tonumber(Year) or 1970,
					month = tonumber(Month) or 1,
					day = tonumber(Day) or 1,
					hour = tonumber(Hour) or 0,
					min = tonumber(Minute) or 0,
					sec = tonumber(Second) or 0,
					isdst = false,
				})
				return MakeDateTimeFromUnixSeconds(Timestamp)
			end

			return MakeDateTimeFromUnixSeconds(os.time())
		end,
		fromUniversalTime = function(Year, Month, Day, Hour, Minute, Second, Millisecond)
			local Timestamp = os.time({
				year = tonumber(Year) or 1970,
				month = tonumber(Month) or 1,
				day = tonumber(Day) or 1,
				hour = tonumber(Hour) or 0,
				min = tonumber(Minute) or 0,
				sec = tonumber(Second) or 0,
				isdst = false,
			})
			local Ms = ToNumber(Millisecond, 0) / 1000
			return MakeDateTimeFromUnixSeconds(Timestamp + Ms)
		end,
		fromLocalTime = function(Year, Month, Day, Hour, Minute, Second, Millisecond)
			local Timestamp = os.time({
				year = tonumber(Year) or 1970,
				month = tonumber(Month) or 1,
				day = tonumber(Day) or 1,
				hour = tonumber(Hour) or 0,
				min = tonumber(Minute) or 0,
				sec = tonumber(Second) or 0,
			})
			local Ms = ToNumber(Millisecond, 0) / 1000
			return MakeDateTimeFromUnixSeconds(Timestamp + Ms)
		end,
	},
	FloatCurveKey = {
		new = function(Time, Value, Interpolation)
			local Obj = TagDataType("FloatCurveKey", {
				Time = ToNumber(Time, 0),
				Value = ToNumber(Value, 0),
				Interpolation = Interpolation or "Linear",
			})
			return Obj
		end,
	},
	ValueCurveKey = {
		new = function(Time, Value, Interpolation)
			local Obj = TagDataType("ValueCurveKey", {
				Time = ToNumber(Time, 0),
				Value = ToNumber(Value, 0),
				Interpolation = Interpolation or "Linear",
			})
			return Obj
		end,
	},
	RotationCurveKey = {
		new = MakeRotationCurveKey,
	},
	Path2DControlPoint = {
		new = MakePath2DControlPoint,
	},
	PathWaypoint = {
		new = MakePathWaypoint,
	},
	SecurityCapabilities = {
		new = MakeSecurityCapabilities,
		None = MakeSecurityCapabilities(0),
		fromCurrent = function()
			return MakeSecurityCapabilities(4503599627370495)
		end,
	},
}

local function TryFallbackConstruct(TypeName, MethodName, ...)
	local Lib = FallbackLibs[TypeName]
	if typeof(Lib) ~= "table" then
		return false, nil, false
	end

	local Constructor = Lib[MethodName]
	if typeof(Constructor) ~= "function" then
		return false, nil, false
	end

	local Ok, Result = pcall(Constructor, ...)
	return Ok, Result, true
end

local function SafeConstruct(TypeName, MethodName, Constructor, ...)
	local Args = table.pack(...)
	local UnwrappedArgs = table.pack(...)
	local HasInternal = false
	local Proxy, Scope, Beautifier

	for I = 1, Args.n do
		local Arg = Args[I]
		if typeof(Arg) == "table" and rawget(Arg, "P") then
			HasInternal = true
		end
		UnwrappedArgs[I] = UnwrapArg(Arg)
	end

	local S, R = pcall(Constructor, table.unpack(UnwrappedArgs, 1, UnwrappedArgs.n))

	if HasInternal and DataTypes._Proxy then
		Proxy = DataTypes._Proxy
		Scope = DataTypes._Scope
		Beautifier = DataTypes._Beautifier

		local Parts = {}
		for I = 1, Args.n do
			Parts[I] = Beautifier:Beautify(Args[I])
		end

		local Value = `{TypeName}.{MethodName}({table.concat(Parts, ", ")})`
		local Var = Scope:AddVar(TypeName, "dt", Value, "__call")

		if S then
			Proxy:Spy(Var)
			return R
		else
			local FallbackOk, FallbackValue, HasFallback = TryFallbackConstruct(TypeName, MethodName, table.unpack(UnwrappedArgs, 1, UnwrappedArgs.n))
			if HasFallback then
				if FallbackOk then
					return FallbackValue
				end
				error(FallbackValue, 0)
			end
		end
	end

	if S then
		return R
	end

	local FallbackOk, Fallback, HasFallback = TryFallbackConstruct(TypeName, MethodName, table.unpack(UnwrappedArgs, 1, UnwrappedArgs.n))
	if HasFallback then
		if FallbackOk then
			return Fallback
		end
		error(Fallback, 0)
	end

	if DataTypes._Proxy then
		Proxy = DataTypes._Proxy
		Scope = DataTypes._Scope
		Beautifier = DataTypes._Beautifier

		local Parts = {}
		for I = 1, Args.n do
			Parts[I] = Beautifier:Beautify(Args[I])
		end

		local Value = `{TypeName}.{MethodName}({table.concat(Parts, ", ")})`
		local Var = Scope:AddVar(TypeName, "dt", Value, "__call")
		return Proxy:Spy(Var)
	end

	error(R, 0)
end

function DataTypes.Init(Proxy, State, Emitter, Beautifier, Scope)
	DataTypes._Proxy = Proxy
	DataTypes._State = State
	DataTypes._Emitter = Emitter
	DataTypes._Beautifier = Beautifier
	DataTypes._Scope = Scope
end

function DataTypes.ConsumeReadonlyViolation()
	local Message = PendingReadonlyViolation
	PendingReadonlyViolation = nil
	return Message
end

function DataTypes.RegisterType(TypeName, Lib)
	local Wrapped = {}

	for Key, Value in next, Lib do
		if typeof(Value) == "function" then
			Wrapped[Key] = function(...)
				return SafeConstruct(TypeName, Key, Value, ...)
			end
		else
			Wrapped[Key] = Value
		end
	end

	Constructors[TypeName] = Wrapped
end

function DataTypes.Get(TypeName)
	return Constructors[TypeName]
end

function DataTypes.Has(TypeName)
	return Constructors[TypeName] ~= nil
end

function DataTypes.GetAll()
	return Constructors
end

function DataTypes.BuildAll()
	local Env = getfenv()
	local PreferredFallbackKeys = {
		NumberRange = {
			new = true,
		},
		NumberSequence = {
			new = true,
		},
		ColorSequence = {
			new = true,
		},
		SharedTable = {
			new = true,
		},
	}

	local TypeList = {
		"Vector3", "Vector2", "Vector3int16", "Vector2int16",
		"CFrame", "Color3", "BrickColor",
		"UDim", "UDim2",
		"Ray", "Axes", "Faces",
		"Region3", "Region3int16", "Rect",
		"NumberRange", "PhysicalProperties",
		"TweenInfo", "RaycastParams", "OverlapParams",
		"Random", "Font",
		"ColorSequence", "ColorSequenceKeypoint",
		"NumberSequence", "NumberSequenceKeypoint",
		"CatalogSearchParams", "FloatCurve",
		"SharedTable", "Content", "DateTime",
		"FloatCurveKey", "Path2DControlPoint",
		"PathWaypoint", "RotationCurveKey",
		"SecurityCapabilities",
		"ValueCurveKey",
	}

	for _, Name in TypeList do
		local HostLib = Env[Name]
		local FallbackLib = FallbackLibs[Name]

		if typeof(HostLib) == "table" then
			local Merged = {}
			for Key, Value in next, HostLib do
				Merged[Key] = Value
			end
			if typeof(FallbackLib) == "table" then
				local OverrideKeys = PreferredFallbackKeys[Name]
				for Key, Value in next, FallbackLib do
					if Merged[Key] == nil or (OverrideKeys and OverrideKeys[Key]) then
						Merged[Key] = Value
					end
				end
			end
			DataTypes.RegisterType(Name, Merged)
		elseif HostLib ~= nil then
			local OverrideKeys = PreferredFallbackKeys[Name]
			if OverrideKeys and typeof(FallbackLib) == "table" then
				DataTypes.RegisterType(Name, FallbackLib)
			else
				Constructors[Name] = HostLib
			end
		elseif typeof(FallbackLib) == "table" then
			DataTypes.RegisterType(Name, FallbackLib)
		end
	end

	return Constructors
end

function DataTypes.Beautify(Value, Beautifier, Indent)
	local T = typeof(Value)
	local TypeTag = nil

	if T == "table" then
		local Enums = require("../../Roblox/Enums")
		if Enums.IsEnumItem(Value) then
			return tostring(Value)
		end

		TypeTag = rawget(Value, "__larryType")
		if TypeTag == "Vector3" then
			return `Vector3.new({Value.X}, {Value.Y}, {Value.Z})`
		elseif TypeTag == "Vector2" then
			return `Vector2.new({Value.X}, {Value.Y})`
		elseif TypeTag == "Vector3int16" then
			return `Vector3int16.new({Value.X}, {Value.Y}, {Value.Z})`
		elseif TypeTag == "Vector2int16" then
			return `Vector2int16.new({Value.X}, {Value.Y})`
		elseif TypeTag == "Color3" then
			local R = math.floor(ToNumber(Value.R, 0) * 255 + 0.5)
			local G = math.floor(ToNumber(Value.G, 0) * 255 + 0.5)
			local B = math.floor(ToNumber(Value.B, 0) * 255 + 0.5)
			return `Color3.fromRGB({R}, {G}, {B})`
		elseif TypeTag == "UDim" then
			return `UDim.new({Value.Scale}, {Value.Offset})`
		elseif TypeTag == "UDim2" then
			local X = Value.X or { Scale = 0, Offset = 0 }
			local Y = Value.Y or { Scale = 0, Offset = 0 }
			return `UDim2.new({X.Scale}, {X.Offset}, {Y.Scale}, {Y.Offset})`
		elseif TypeTag == "CFrame" then
			return `CFrame.new({Value.X}, {Value.Y}, {Value.Z})`
		elseif TypeTag == "BrickColor" then
			return `BrickColor.new({StringUtil.Quote(tostring(Value.Name or "Medium stone grey"))})`
		elseif TypeTag == "NumberRange" then
			return `NumberRange.new({Value.Min}, {Value.Max})`
		elseif TypeTag == "Rect" then
			local Min = Value.Min or { X = 0, Y = 0 }
			local Max = Value.Max or { X = 0, Y = 0 }
			return `Rect.new({Min.X}, {Min.Y}, {Max.X}, {Max.Y})`
		elseif TypeTag == "Ray" then
			local O = Value.Origin or { X = 0, Y = 0, Z = 0 }
			local D = Value.Direction or { X = 0, Y = -1, Z = 0 }
			return `Ray.new(Vector3.new({O.X}, {O.Y}, {O.Z}), Vector3.new({D.X}, {D.Y}, {D.Z}))`
		elseif TypeTag == "TweenInfo" then
			return `TweenInfo.new({Value.Time}, {Beautifier:Beautify(Value.EasingStyle)}, {Beautifier:Beautify(Value.EasingDirection)}, {Value.RepeatCount}, {Beautifier:Beautify(Value.Reverses)}, {Value.DelayTime})`
		elseif TypeTag == "Random" then
			return "Random.new()"
		elseif TypeTag == "RaycastParams" then
			return "RaycastParams.new()"
		elseif TypeTag == "OverlapParams" then
			return "OverlapParams.new()"
		elseif TypeTag == "Font" then
			return `Font.new({StringUtil.Quote(tostring(Value.Family or "SourceSans"))})`
		elseif TypeTag == "ColorSequence" then
			return `ColorSequence.new({Beautifier:Beautify(Value.Keypoints or {})})`
		elseif TypeTag == "NumberSequence" then
			return `NumberSequence.new({Beautifier:Beautify(Value.Keypoints or {})})`
		elseif TypeTag == "CatalogSearchParams" then
			return "CatalogSearchParams.new()"
		elseif TypeTag == "Faces" then
			local Enabled = {}
			if Value.Top then Enabled[#Enabled + 1] = "Enum.NormalId.Top" end
			if Value.Bottom then Enabled[#Enabled + 1] = "Enum.NormalId.Bottom" end
			if Value.Front then Enabled[#Enabled + 1] = "Enum.NormalId.Front" end
			if Value.Back then Enabled[#Enabled + 1] = "Enum.NormalId.Back" end
			if Value.Left then Enabled[#Enabled + 1] = "Enum.NormalId.Left" end
			if Value.Right then Enabled[#Enabled + 1] = "Enum.NormalId.Right" end
			if #Enabled == 0 then
				return "Faces.new()"
			end
			return `Faces.new({table.concat(Enabled, ", ")})`
		elseif TypeTag == "FloatCurve" then
			return "FloatCurve.new()"
		elseif TypeTag == "Content" then
			return `Content.fromUri({StringUtil.Quote(tostring(Value.Uri or ""))})`
		elseif TypeTag == "DateTime" then
			return `DateTime.fromUnixTimestamp({ToNumber(Value.UnixTimestamp, os.time())})`
		elseif TypeTag == "FloatCurveKey" then
			return `FloatCurveKey.new({ToNumber(Value.Time, 0)}, {ToNumber(Value.Value, 0)})`
		elseif TypeTag == "ColorSequenceKeypoint" then
			return `ColorSequenceKeypoint.new({ToNumber(Value.Time, 0)}, {Beautifier:Beautify(Value.Value)})`
		elseif TypeTag == "NumberSequenceKeypoint" then
			return `NumberSequenceKeypoint.new({ToNumber(Value.Time, 0)}, {ToNumber(Value.Value, 0)}, {ToNumber(Value.Envelope, 0)})`
		elseif TypeTag == "RotationCurveKey" then
			return `RotationCurveKey.new({ToNumber(Value.Time, 0)}, {Beautifier:Beautify(Value.Value)})`
		elseif TypeTag == "Path2DControlPoint" then
			return `Path2DControlPoint.new({Beautifier:Beautify(Value.Position)}, {Beautifier:Beautify(Value.LeftTangent)}, {Beautifier:Beautify(Value.RightTangent)})`
		elseif TypeTag == "PathWaypoint" then
			return `PathWaypoint.new({Beautifier:Beautify(Value.Position)}, {Beautifier:Beautify(Value.Action)}, {Beautifier:Beautify(Value.Label)})`
		elseif TypeTag == "SecurityCapabilities" then
			return `SecurityCapabilities.new({ToNumber(Value.Value, 0)})`
		end
	end

	if T == "Vector3" then
		return `Vector3.new({Value.X}, {Value.Y}, {Value.Z})`
	elseif T == "Vector2" then
		return `Vector2.new({Value.X}, {Value.Y})`
	elseif T == "CFrame" then
		local Components = { Value:GetComponents() }
		local Parts = {}
		for _, C in Components do
			table.insert(Parts, tostring(C))
		end
		return `CFrame.new({table.concat(Parts, ", ")})`
	elseif T == "Color3" then
		local R = math.floor(Value.R * 255)
		local G = math.floor(Value.G * 255)
		local B = math.floor(Value.B * 255)
		return `Color3.fromRGB({R}, {G}, {B})`
	elseif T == "UDim2" then
		return `UDim2.new({Value.X.Scale}, {Value.X.Offset}, {Value.Y.Scale}, {Value.Y.Offset})`
	elseif T == "UDim" then
		return `UDim.new({Value.Scale}, {Value.Offset})`
	elseif T == "BrickColor" then
		return `BrickColor.new("{Value.Name}")`
	elseif T == "TweenInfo" then
		return `TweenInfo.new()`
	elseif T == "NumberRange" then
		return `NumberRange.new({Value.Min}, {Value.Max})`
	elseif T == "Rect" then
		return `Rect.new({Value.Min.X}, {Value.Min.Y}, {Value.Max.X}, {Value.Max.Y})`
	elseif T == "Ray" then
		return `Ray.new(Vector3.new({Value.Origin.X}, {Value.Origin.Y}, {Value.Origin.Z}), Vector3.new({Value.Direction.X}, {Value.Direction.Y}, {Value.Direction.Z}))`
	end

	return nil
end

return DataTypes