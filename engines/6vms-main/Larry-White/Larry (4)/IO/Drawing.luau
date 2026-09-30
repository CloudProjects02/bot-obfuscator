local IdentityUtil = require("../Utils/Identity")

local Drawing = {}

local DrawingObjects = {}
local DrawingFonts = {
	UI = 0,
	System = 1,
	Plex = 2,
	Monospace = 3,
}

local DrawingClasses = {
	Line = { "From", "To", "Color", "Thickness", "Transparency", "Visible", "ZIndex" },
	Text = { "Text", "Size", "Center", "Outline", "OutlineColor", "Position", "Color", "Transparency", "Visible", "Font", "ZIndex" },
	Image = { "Data", "Size", "Position", "Color", "Transparency", "Visible", "Rounding", "ZIndex" },
	Circle = { "Radius", "Position", "Color", "Thickness", "Filled", "Transparency", "Visible", "NumSides", "ZIndex" },
	Square = { "Size", "Position", "Color", "Thickness", "Filled", "Transparency", "Visible", "ZIndex" },
	Quad = { "PointA", "PointB", "PointC", "PointD", "Color", "Thickness", "Filled", "Transparency", "Visible", "ZIndex" },
	Triangle = { "PointA", "PointB", "PointC", "Color", "Thickness", "Filled", "Transparency", "Visible", "ZIndex" },
}

local DrawingDefaults = {
	Color = { R = 0, G = 0, B = 0 },
	Thickness = 1,
	Transparency = 1,
	Visible = false,
	Filled = false,
	ZIndex = 0,
	Size = 12,
	Center = false,
	Outline = false,
	Text = "",
	Radius = 50,
	NumSides = 12,
	Rounding = 0,
}

local DrawingObjectMeta = {}
DrawingObjectMeta.__index = DrawingObjectMeta

function DrawingObjectMeta:Remove()
	self._Removed = true

	for I = #DrawingObjects, 1, -1 do
		if DrawingObjects[I] == self then
			table.remove(DrawingObjects, I)
			break
		end
	end
end

function DrawingObjectMeta:Destroy()
	self:Remove()
end

function DrawingObjectMeta:__tostring()
	return `Drawing({self._Class})`
end

function Drawing.New(Class, Proxy, State, Emitter, Beautifier, Scope)
	if not DrawingClasses[Class] then
		error(`Invalid drawing class '{Class}'`)
	end

	local Obj = setmetatable({
		_Class = Class,
		_Id = IdentityUtil.Generate(8),
		_Removed = false,
		_Properties = {},
	}, DrawingObjectMeta)

	for _, Prop in DrawingClasses[Class] do
		local Default = DrawingDefaults[Prop]
		if Default ~= nil then
			Obj._Properties[Prop] = typeof(Default) == "table" and table.clone(Default) or Default
		end
	end

	table.insert(DrawingObjects, Obj)

	local Value = `Drawing.new("{Class}")`
	local Var = Scope:AddVar("drawing", Class, Value, "__call")

	State:RegisterInternal(Obj, Var)

	return Proxy:Spy(Var), Obj
end

function Drawing.GetRenderProperty(Obj, Prop)
	if typeof(Obj) ~= "table" or not Obj._Properties then
		error("invalid argument #1 to 'getrenderproperty'")
	end
	return Obj._Properties[Prop]
end

function Drawing.SetRenderProperty(Obj, Prop, Value)
	if typeof(Obj) ~= "table" or not Obj._Properties then
		error("invalid argument #1 to 'setrenderproperty'")
	end
	Obj._Properties[Prop] = Value
end

function Drawing.IsRenderObj(Obj)
	return getmetatable(Obj) == DrawingObjectMeta
end

function Drawing.ClearCache()
	for _, Obj in DrawingObjects do
		Obj._Removed = true
	end
	table.clear(DrawingObjects)
end

function Drawing.GetAll()
	return DrawingObjects
end

function Drawing.Build(Proxy, State, Emitter, Beautifier, Scope)
	local Lib = {
		new = function(Class)
			return Drawing.New(Class, Proxy, State, Emitter, Beautifier, Scope)
		end,
		Fonts = DrawingFonts,
	}

	local Meta = setmetatable(Lib, {
		__tostring = function()
			return "Drawing"
		end,
	})

	State:RegisterInternal(Meta, "Drawing")

	return Meta, {
		isrenderobj = function(Obj)
			return Drawing.IsRenderObj(Obj)
		end,
		getrenderproperty = function(Obj, Prop)
			return Drawing.GetRenderProperty(Obj, Prop)
		end,
		setrenderproperty = function(Obj, Prop, Value)
			Drawing.SetRenderProperty(Obj, Prop, Value)
		end,
		cleardrawcache = function()
			Drawing.ClearCache()
		end,
	}
end

return Drawing