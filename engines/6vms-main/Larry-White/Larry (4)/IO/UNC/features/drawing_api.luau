local TypeGuards = require("../util/typeguards")

local DrawingApi = {}

function DrawingApi.Build(Ctx)
	local DrawingCache = Ctx.DrawingCache

	local function MakeDrawingObject(Class)
		local Props = {
			Visible = false,
			Color = TypeGuards.SafeColor3(0, 0, 0),
			Transparency = 1,
			ZIndex = 0,
			Position = TypeGuards.SafeVector2(0, 0),
			From = TypeGuards.SafeVector2(0, 0),
			To = TypeGuards.SafeVector2(0, 0),
			Size = 16,
			Text = "",
			Center = false,
			Outline = false,
			OutlineColor = TypeGuards.SafeColor3(0, 0, 0),
			Thickness = 1,
			Filled = false,
			Radius = 0,
			NumSides = 12,
			Font = 0,
			Data = "",
			PointA = TypeGuards.SafeVector2(0, 0),
			PointB = TypeGuards.SafeVector2(0, 0),
			PointC = TypeGuards.SafeVector2(0, 0),
			PointD = TypeGuards.SafeVector2(0, 0),
			TextBounds = TypeGuards.SafeVector2(0, 0),
		}

		local Obj = {}
		local Removed = false

		local Mt = {
			__index = function(_, Key)
				if Key == "Remove" or Key == "Destroy" then
					return function()
						Removed = true
						DrawingCache[Obj] = nil
					end
				end
				if Key == "__OBJECT_EXISTS" then
					return not Removed
				end
				if Key == "__DRAWING_CLASS" then
					return Class
				end
				return Props[Key]
			end,
			__newindex = function(_, Key, Value)
				if Removed then return end
				Props[Key] = Value
			end,
			__tostring = function()
				return "Drawing (" .. tostring(Class) .. ")"
			end,
		}

		local result = setmetatable(Obj, Mt)
		DrawingCache[result] = true
		return result
	end

	local DrawingLib = {
		Fonts = {
			UI = 0,
			System = 1,
			Plex = 2,
			Monospace = 3,
		},
		new = function(Class)
			return MakeDrawingObject(Class)
		end,
		clear = function()
			for obj in DrawingCache do
				pcall(function()
					local mt = getmetatable(obj)
					if mt and mt.__index then
						local remove = mt.__index(obj, "Remove")
						if remove then remove() end
					end
				end)
			end
			Ctx.DrawingCache = {}
		end,
	}

	return {
		Drawing = DrawingLib,
		isrenderobj = function(Obj)
			if typeof(Obj) == "table" then
				if DrawingCache[Obj] then return true end
				local mt = getmetatable(Obj)
				if mt then
					local ok, exists = pcall(function() return mt.__index(Obj, "__OBJECT_EXISTS") end)
					if ok and exists ~= nil then return true end
				end
			end
			return false
		end,
		cleardrawcache = function()
			Ctx.DrawingCache = {}
		end,
		getrenderproperty = function(Obj, Prop)
			if typeof(Obj) ~= "table" then
				error("invalid argument #1 to 'getrenderproperty'")
			end
			if typeof(Prop) ~= "string" then
				error("invalid argument #2 to 'getrenderproperty' (string expected)")
			end
			if not DrawingCache[Obj] then
				error("invalid argument #1 to 'getrenderproperty'")
			end
			return Obj[Prop]
		end,
		setrenderproperty = function(Obj, Prop, Value)
			if typeof(Obj) ~= "table" then
				error("invalid argument #1 to 'setrenderproperty'")
			end
			if typeof(Prop) ~= "string" then
				error("invalid argument #2 to 'setrenderproperty' (string expected)")
			end
			if not DrawingCache[Obj] then
				error("invalid argument #1 to 'setrenderproperty'")
			end
			Obj[Prop] = Value
		end,
	}
end

return DrawingApi