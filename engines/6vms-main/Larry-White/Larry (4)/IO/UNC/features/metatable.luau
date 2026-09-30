local TypeGuards = require("../util/typeguards")
local Namecall = require("../util/namecall")

local MetatableApi = {}

function MetatableApi.Build(Ctx, State, Emitter, Beautifier)

	return {
		getrawmetatable = function(Object)
			local Tracked = Ctx.raw_metatables[Object]
			if Tracked ~= nil then
				return Tracked
			end

			local InstanceMod = TypeGuards.SafeRequireInstance()
			if InstanceMod and InstanceMod.IsInstance and InstanceMod.IsInstance(Object) then
				return Namecall.EnsureSyntheticMetatable(Ctx, Object)
			end

			if State:IsInternal(Object) then
				return nil
			end

			if typeof(Object) == "table" or typeof(Object) == "userdata" then
				local stored = Ctx.raw_metatables[Object]
				if stored ~= nil then return stored end
				local ok, mt = pcall(getmetatable, Object)
				if ok then
					if typeof(mt) == "table" then
						if Ctx.readonly_tables[mt] == nil then
							local frozen = false
							local okFreeze, isFrozen = pcall(table.isfrozen, mt)
							if okFreeze then
								frozen = isFrozen
							end
							Ctx.readonly_tables[mt] = frozen
						end
						Ctx.raw_metatables[Object] = mt
						return mt
					end
					if mt ~= nil then
						Ctx.raw_metatables[Object] = mt
						return mt
					end
				end
			end
			return nil
		end,

		setrawmetatable = function(Object, Mt)
			if (typeof(Object) == "table" or typeof(Object) == "userdata") and typeof(Mt) == "table" then
				Ctx.raw_metatables[Object] = Mt
			end

			local InstanceMod = TypeGuards.SafeRequireInstance()
			if InstanceMod and InstanceMod.IsInstance and InstanceMod.IsInstance(Object) then
				Ctx.raw_metatables[Object] = Mt
				return Object
			end

			if typeof(Object) == "table" or typeof(Object) == "userdata" then
				local OkSet = pcall(Ctx.native_setmetatable, Object, Mt)
				if not OkSet and typeof(Object) == "table" and typeof(Mt) == "table" then
					local Indexer = rawget(Mt, "__index")

					local function PrimeKey(Key)
						if rawget(Object, Key) ~= nil then
							return
						end

						if typeof(Indexer) == "function" then
							local OkValue, Resolved = pcall(Indexer, Object, Key)
							if OkValue then
								rawset(Object, Key, Resolved)
							end
						elseif typeof(Indexer) == "table" then
							rawset(Object, Key, Indexer[Key])
						end
					end

					if typeof(Indexer) == "table" then
						for Key, Value in next, Indexer do
							if rawget(Object, Key) == nil then
								rawset(Object, Key, Value)
							end
						end
					end

					PrimeKey("test")
					PrimeKey("VINDINPARTEARADIOACTIVAARAIULUI")
				end
			end
			return Object
		end,

		__larry_track_setmetatable = function(Object, Mt)
			if (typeof(Object) == "table" or typeof(Object) == "userdata") and typeof(Mt) == "table" then
				Ctx.raw_metatables[Object] = Mt
			end
		end,

		setmetatable = function(Object, Mt)
			if typeof(Object) == "table" and typeof(Mt) == "table" then
				Ctx.raw_metatables[Object] = Mt
			end
			return Ctx.native_setmetatable(Object, Mt)
		end,

		isreadonly = function(Tbl)
			if typeof(Tbl) ~= "table" then
				error("invalid argument #1 to 'isreadonly' (table expected)")
			end

			local IsMathLib = type(rawget(Tbl, "abs")) == "function" and type(rawget(Tbl, "sqrt")) == "function" and type(rawget(Tbl, "pi")) == "number"
			local IsStringLib = type(rawget(Tbl, "sub")) == "function" and type(rawget(Tbl, "byte")) == "function"
			local IsTableLib = type(rawget(Tbl, "insert")) == "function" and type(rawget(Tbl, "concat")) == "function"
			local IsCoroutineLib = type(rawget(Tbl, "create")) == "function" and type(rawget(Tbl, "resume")) == "function"
			local IsUtf8Lib = type(rawget(Tbl, "len")) == "function" and type(rawget(Tbl, "offset")) == "function"
			local IsDebugLib = type(rawget(Tbl, "traceback")) == "function" and type(rawget(Tbl, "getinfo")) == "function"
			if IsMathLib or IsStringLib or IsTableLib or IsCoroutineLib or IsUtf8Lib or IsDebugLib then
				return true
			end

			if Ctx.readonly_tables[Tbl] ~= nil then
				return Ctx.readonly_tables[Tbl]
			end
			local ok, frozen = pcall(table.isfrozen, Tbl)
			if ok then
				return frozen
			end
			return false
		end,

		setreadonly = function(Tbl, Readonly)
			if typeof(Tbl) ~= "table" then
				error("invalid argument #1 to 'setreadonly' (table expected)")
			end
			if typeof(Readonly) ~= "boolean" then
				error("invalid argument #2 to 'setreadonly' (boolean expected)")
			end
			Ctx.readonly_tables[Tbl] = Readonly
		end,

		getnamecallmethod = function()
			return Ctx.lastNamecallMethod
		end,

		setnamecallmethod = function(Method)
			if typeof(Method) ~= "string" then error("invalid argument #1 to 'setnamecallmethod' (string expected)") end
			Ctx.namecall_override_method = Method
			Ctx.lastNamecallMethod = Method
			Emitter:Append(`setnamecallmethod({Beautifier:Beautify(Method)})`)
		end,
	}
end

return MetatableApi