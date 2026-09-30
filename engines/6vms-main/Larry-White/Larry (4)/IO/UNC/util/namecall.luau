local Namecall = {}

function Namecall.CallOriginalNamecall(Ctx, Object, Method, ...)
	local Entry = Ctx.namecall_states[Object]
	local Indexer = Entry and Entry.original_index
	local Member = nil

	if typeof(Indexer) == "function" then
		local Ok, Res = pcall(Indexer, Object, Method)
		if Ok then
			Member = Res
		end
	elseif typeof(Indexer) == "table" then
		Member = Indexer[Method]
	end

	if Member == nil then
		local Ok, Res = pcall(function()
			return Object[Method]
		end)
		if Ok then
			Member = Res
		end
	end

	if typeof(Member) ~= "function" then
		error(`attempt to call missing method '{tostring(Method)}' of table`, 0)
	end

	return Member(Object, ...)
end

function Namecall.EnsureNamecallState(Ctx, Object)
	local Existing = Ctx.namecall_states[Object]
	if Existing ~= nil then
		return Existing
	end

	if typeof(Object) ~= "table" then
		return nil
	end

	local OldMt = Ctx.native_getmetatable(Object)
	if typeof(OldMt) ~= "table" then
		return nil
	end

	local OldIndex = rawget(OldMt, "__index")
	local OldNewIndex = rawget(OldMt, "__newindex")

	local ShimMt = {}
	for K, V in next, OldMt do
		ShimMt[K] = V
	end

	ShimMt.__index = function(Self, Key)
		local BaseValue = nil

		if typeof(OldIndex) == "function" then
			BaseValue = OldIndex(Self, Key)
		elseif typeof(OldIndex) == "table" then
			BaseValue = OldIndex[Key]
		else
			BaseValue = rawget(Self, Key)
		end

		if typeof(Key) == "string" and typeof(BaseValue) == "function" then
			return function(_, ...)
				local Entry = Ctx.namecall_states[Self]
				local Hook = Entry and Entry.hook or nil
				local PreviousMethod = Ctx.lastNamecallMethod
				local ActiveMethod = Key
				if typeof(Ctx.namecall_override_method) == "string" and Ctx.namecall_override_method ~= "" then
					ActiveMethod = Ctx.namecall_override_method
				end

				Ctx.lastNamecallMethod = ActiveMethod

				local function CallOld(TargetSelf, ...)
					local MethodToCall = ActiveMethod
					if typeof(Ctx.namecall_override_method) == "string" and Ctx.namecall_override_method ~= "" then
						MethodToCall = Ctx.namecall_override_method
					end
					Ctx.namecall_override_method = nil
					return Namecall.CallOriginalNamecall(Ctx, TargetSelf, MethodToCall, ...)
				end

				if typeof(Hook) == "function" then
					local Ok, Ret = pcall(function(...)
						return table.pack(Hook(Self, ...))
					end, ...)
					Ctx.lastNamecallMethod = PreviousMethod
					if not Ok then
						Ctx.namecall_override_method = nil
						error(Ret, 0)
					end
					Ctx.namecall_override_method = nil
					return table.unpack(Ret, 1, Ret.n)
				end

				local Returns = table.pack(CallOld(Self, ...))
				Ctx.lastNamecallMethod = PreviousMethod
				return table.unpack(Returns, 1, Returns.n)
			end
		end

		return BaseValue
	end

	if typeof(OldNewIndex) == "function" then
		ShimMt.__newindex = function(Self, Key, Value)
			return OldNewIndex(Self, Key, Value)
		end
	elseif typeof(OldNewIndex) == "table" then
		ShimMt.__newindex = function(_, Key, Value)
			OldNewIndex[Key] = Value
		end
	end

	local OkSet = pcall(Ctx.native_setmetatable, Object, ShimMt)
	if not OkSet then
		return nil
	end

	local NewEntry = {
		original_mt = OldMt,
		original_index = OldIndex,
		hook = nil,
	}

	Ctx.namecall_states[Object] = NewEntry
	Ctx.raw_metatables[Object] = OldMt
	return NewEntry
end

function Namecall.EnsureSyntheticMetatable(Ctx, Object)
	local function DefaultNamecall(Self, ...)
		local Method = Ctx.lastNamecallMethod
		if typeof(Ctx.namecall_override_method) == "string" and Ctx.namecall_override_method ~= "" then
			Method = Ctx.namecall_override_method
		end
		Ctx.namecall_override_method = nil
		return Namecall.CallOriginalNamecall(Ctx, Self, Method, ...)
	end

	local Existing = Ctx.raw_metatables[Object]
	if Existing ~= nil then
		if Ctx.readonly_tables[Existing] == nil then
			Ctx.readonly_tables[Existing] = true
		end
		if Ctx.synthetic_metatable_fields[Existing] == nil then
			Ctx.synthetic_metatable_fields[Existing] = {
				__namecall = DefaultNamecall,
			}
		elseif typeof(Ctx.synthetic_metatable_fields[Existing].__namecall) ~= "function" then
			Ctx.synthetic_metatable_fields[Existing].__namecall = DefaultNamecall
		end
		return Existing
	end

	local Synthetic = {}
	Ctx.synthetic_metatable_fields[Synthetic] = {
		__namecall = DefaultNamecall,
	}
	Ctx.readonly_tables[Synthetic] = true

	setmetatable(Synthetic, {
		__index = function(Tbl, Key)
			local Fields = Ctx.synthetic_metatable_fields[Tbl]
			if Fields == nil then
				return nil
			end
			return Fields[Key]
		end,
		__newindex = function(Tbl, Key, Value)
			if Ctx.readonly_tables[Tbl] ~= false then
				error("attempt to modify a readonly table", 2)
			end
			local Fields = Ctx.synthetic_metatable_fields[Tbl]
			if Fields == nil then
				Fields = {}
				Ctx.synthetic_metatable_fields[Tbl] = Fields
			end
			Fields[Key] = Value
		end,
		__iter = function(Tbl)
			return next, Ctx.synthetic_metatable_fields[Tbl] or {}, nil
		end,
	})

	Ctx.raw_metatables[Object] = Synthetic
	return Synthetic
end

return Namecall