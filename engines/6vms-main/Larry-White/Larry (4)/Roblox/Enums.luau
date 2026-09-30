local ApiCatalog = require("./ApiCatalog")

local Enums = {}

local EnumTree = {}
local EnumTypeCache = {}
local EnumItemMeta = {}

EnumItemMeta.__index = function(Self, Key)
	if Key == "EnumType" then
		return Enums.GetEnumType(Self._EnumType)
	end
	if Key == "Name" then
		return Self._Name
	end
	if Key == "Value" then
		return Self._Value
	end
	return rawget(EnumItemMeta, Key)
end

function EnumItemMeta:__tostring()
	return `Enum.{self._EnumType}.{self._Name}`
end

function EnumItemMeta:__eq(Other)
	if getmetatable(Other) == EnumItemMeta then
		return self._EnumType == Other._EnumType and self._Name == Other._Name
	end
	return false
end

local function CreateEnumItem(EnumType, Name, Value)
	return setmetatable({
		__larryType = "EnumItem",
		_EnumType = EnumType,
		_Name = Name,
		_Value = Value or 0,
	}, EnumItemMeta)
end

function Enums.Init()
	local LuneEnum = nil

	pcall(function()
		LuneEnum = require("@lune/roblox").Enum
	end)

	if LuneEnum then
		Enums._LuneEnum = LuneEnum
	end
end

local function LoadEnumFromCatalog(EnumType)
	local Descriptor = ApiCatalog.GetEnumDescriptor(EnumType)
	if typeof(Descriptor) ~= "table" or typeof(Descriptor.Items) ~= "table" then
		return nil
	end

	local Branch = {}
	EnumTree[EnumType] = Branch
	EnumTypeCache[EnumType] = nil

	for Name, Value in next, Descriptor.Items do
		Branch[Name] = CreateEnumItem(EnumType, Name, Value)
	end

	return Branch
end

local function EnsureBranch(EnumType)
	return EnumTree[EnumType] or LoadEnumFromCatalog(EnumType)
end

function Enums.Register(EnumType, Items)
	local Branch = LoadEnumFromCatalog(EnumType)
	if Branch then
		return
	end

	Branch = {}
	EnumTree[EnumType] = Branch
	EnumTypeCache[EnumType] = nil

	for _, Item in Items do
		local Name = typeof(Item) == "table" and Item.Name or Item
		local Value = typeof(Item) == "table" and Item.Value or nil

		Branch[Name] = CreateEnumItem(EnumType, Name, Value)
	end
end

function Enums.Get(EnumType, ItemName)
	local Branch = EnsureBranch(EnumType)
	if Branch then
		return Branch[ItemName]
	end

	if Enums._LuneEnum then
		local S, R = pcall(function()
			local EnumValue = Enums._LuneEnum[EnumType]
			if EnumValue == nil then
				return nil
			end
			return EnumValue[ItemName]
		end)
		if S and R then return R end
	end

	return nil
end

function Enums.GetEnumType(EnumType)
	local Cached = EnumTypeCache[EnumType]
	if Cached ~= nil then
		return Cached
	end

	local Branch = EnsureBranch(EnumType)

		if Branch then
			local EnumTable = setmetatable({ __larryType = "Enum" }, {
				__index = function(_, Key)
					if Key == "GetEnumItems" then
						return function()
							local Items = {}
							for K, V in next, Branch do
								table.insert(Items, V)
							end
							return Items
						end
					end
					local Item = Branch[Key]
					if Item ~= nil then
						return Item
					end
					error(`'{Key}' is not a valid EnumItem of Enum.{EnumType}`, 2)
				end,
				__newindex = function()
					error("Enum cannot be modified", 2)
				end,
				__tostring = function()
					return `Enum.{EnumType}`
				end,
			})

			if typeof(table.freeze) == "function" then
				pcall(table.freeze, EnumTable)
			end
		EnumTypeCache[EnumType] = EnumTable
		return EnumTable
	end

	if Enums._LuneEnum then
		local S, R = pcall(function()
			return Enums._LuneEnum[EnumType]
		end)
		if S and R then
			EnumTypeCache[EnumType] = R
			return R
		end
	end

	return nil
end

function Enums.BuildProxy()
	return setmetatable({ __larryType = "Enums" }, {
		__index = function(_, EnumType)
			if EnumType == "GetEnumItems" then
				return function()
					return {}
				end
			end
			return Enums.GetEnumType(EnumType)
		end,
		__tostring = function()
			return "Enum"
		end,
		__call = function(_, EnumType)
			return Enums.GetEnumType(EnumType)
		end,
	})
end

function Enums.IsEnumItem(Value)
	return getmetatable(Value) == EnumItemMeta
end

function Enums.ItemToString(Value)
	if Enums.IsEnumItem(Value) then
		return tostring(Value)
	end
	return nil
end

Enums.Register("Font", {
	{ Name = "Legacy", Value = 0 },
	{ Name = "Arial", Value = 1 },
	{ Name = "ArialBold", Value = 2 },
	{ Name = "SourceSans", Value = 3 },
	{ Name = "SourceSansBold", Value = 4 },
	{ Name = "SourceSansLight", Value = 5 },
	{ Name = "SourceSansItalic", Value = 6 },
	{ Name = "Bodoni", Value = 7 },
	{ Name = "Garamond", Value = 8 },
	{ Name = "Cartoon", Value = 9 },
	{ Name = "Code", Value = 10 },
	{ Name = "Highway", Value = 11 },
	{ Name = "SciFi", Value = 12 },
	{ Name = "Arcade", Value = 13 },
	{ Name = "Fantasy", Value = 14 },
	{ Name = "Antique", Value = 15 },
	{ Name = "Gotham", Value = 16 },
	{ Name = "GothamBold", Value = 17 },
	{ Name = "GothamBlack", Value = 18 },
	{ Name = "FredokaOne", Value = 19 },
	{ Name = "Ubuntu", Value = 20 },
	{ Name = "BuilderSans", Value = 21 },
	{ Name = "BuilderSansBold", Value = 22 },
})

Enums.Register("KeyCode", {
	{ Name = "W", Value = 119 },
	{ Name = "A", Value = 97 },
	{ Name = "S", Value = 115 },
	{ Name = "D", Value = 100 },
	{ Name = "Space", Value = 32 },
	{ Name = "LeftShift", Value = 304 },
	{ Name = "E", Value = 101 },
	{ Name = "F", Value = 102 },
	{ Name = "Q", Value = 113 },
	{ Name = "R", Value = 114 },
})

Enums.Register("UserInputType", {
	{ Name = "MouseButton1", Value = 0 },
	{ Name = "MouseButton2", Value = 1 },
	{ Name = "MouseButton3", Value = 2 },
	{ Name = "MouseWheel", Value = 3 },
	{ Name = "MouseMovement", Value = 4 },
	{ Name = "Touch", Value = 7 },
	{ Name = "Keyboard", Value = 8 },
	{ Name = "Gamepad1", Value = 12 },
})

Enums.Register("Material", {
	{ Name = "Plastic", Value = 256 },
	{ Name = "SmoothPlastic", Value = 272 },
	{ Name = "Neon", Value = 288 },
	{ Name = "Wood", Value = 512 },
	{ Name = "Brick", Value = 528 },
	{ Name = "Metal", Value = 1040 },
	{ Name = "Glass", Value = 1568 },
})

Enums.Register("EasingStyle", {
	{ Name = "Linear", Value = 0 },
	{ Name = "Sine", Value = 1 },
	{ Name = "Back", Value = 2 },
	{ Name = "Quad", Value = 3 },
	{ Name = "Quart", Value = 4 },
	{ Name = "Quint", Value = 5 },
	{ Name = "Bounce", Value = 6 },
	{ Name = "Elastic", Value = 7 },
	{ Name = "Exponential", Value = 8 },
	{ Name = "Circular", Value = 9 },
	{ Name = "Cubic", Value = 10 },
})

Enums.Register("EasingDirection", {
	{ Name = "In", Value = 0 },
	{ Name = "Out", Value = 1 },
	{ Name = "InOut", Value = 2 },
})

return Enums