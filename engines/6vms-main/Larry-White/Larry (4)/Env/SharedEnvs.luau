local StringUtil = require("../Utils/String")
local ExecEnv = require("../Data/ExecEnv")

local SharedEnvs = {}

function SharedEnvs.Build(Deps)
	local State = Deps.State
	local Proxy = Deps.Proxy
	local Emitter = Deps.Emitter
	local Beautifier = Deps.Beautifier
	local Scope = Deps.Scope
	local Config = Deps.Config
	local Iteration = Deps.Iteration
	local LockedEnv = Deps.LockedEnv
	local BaseValues = Deps.Hooks or Deps.BaseValues or {}
	local GetLockedEnv = Deps.GetLockedEnv

	local Stores = {}

	local function IsHiddenEnvKey(Key)
		if typeof(Key) ~= "string" then
			return false
		end
		if Key == "P" or Key == "V" or Key == "ISP" or Key == "_ENV" then
			return true
		end
		if string.sub(Key, 1, 7) == "__larry" then
			return true
		end
		if Key == "hookexpr" or Key == "hookeq" or Key == "preventerror" or Key == "forceerror" then
			return true
		end
		if string.sub(Key, 1, 5) == "CHECK" then
			return true
		end
		if string.sub(Key, 1, 4) == "COMP" then
			return true
		end
		if string.sub(Key, 1, 2) == "__" then
			return true
		end
		return false
	end

	local function CreateSharedEnv(Name)
		local Storage = {}
		local Env
		local IsShared = Name == "shared"
		local MirrorFromLockedKeys = {
			loadstring = true,
			load = true,
			require = true,
			rawget = true,
			rawset = true,
			setmetatable = true,
			getmetatable = true,
			pcall = true,
			xpcall = true,
			tostring = true,
			type = true,
		}

		local function ShouldHideRawKey(Key)
			return IsHiddenEnvKey(Key)
		end

		local function SyncFromFenv()
			if IsShared then
				return
			end

			for K, V in next, BaseValues do
				if Storage[K] == nil and not ShouldHideRawKey(K) then
					Storage[K] = V
					if Env ~= nil then
						rawset(Env, K, V)
					end
				end
			end

			local Locked = LockedEnv
			if typeof(GetLockedEnv) == "function" then
				local Ok, Resolved = pcall(GetLockedEnv)
				if Ok then
					Locked = Resolved
				end
			end

			if typeof(Locked) == "table" then
				for K, V in next, Locked do
					local ShouldMirror = MirrorFromLockedKeys[K] == true
					if not ShouldHideRawKey(K)
						and (Storage[K] == nil or ShouldMirror)
					then
						Storage[K] = V
						if Env ~= nil then
							rawset(Env, K, V)
						end
					end
				end
			end

			for K, V in next, State.EnvValues do
				if Storage[K] == nil and not ShouldHideRawKey(K) then
					Storage[K] = V[1]
					if Env ~= nil then
						rawset(Env, K, V[1])
					end
				end
			end
		end

		local function GetIterableEntries()
			SyncFromFenv()

			local Entries = {}
			local Seen = {}
			local PriorityKeys = { "_VERSION", "_G", "getgenv", "shared", "game", "workspace", "task", "loadstring", "print" }

			local function AddEntry(Key, Value)
				if ShouldHideRawKey(Key) then
					return
				end
				if Seen[Key] or Value == nil then
					return
				end
				Seen[Key] = true
				Entries[#Entries + 1] = { Key, Value }
			end

			local Locked = LockedEnv
			if typeof(GetLockedEnv) == "function" then
				local Ok, Resolved = pcall(GetLockedEnv)
				if Ok then
					Locked = Resolved
				end
			end

			for _, Key in next, PriorityKeys do
				local Value = rawget(Env, Key)
				if Value == nil then
					Value = Storage[Key]
				end
				if Value == nil then
					local Stored = State.EnvValues[Key]
					if Stored ~= nil then
						Value = Stored[1]
					end
				end
				if Value == nil and typeof(Locked) == "table" then
					Value = rawget(Locked, Key)
				end
				if Value == nil and not IsShared then
					Value = BaseValues[Key]
				end
				AddEntry(Key, Value)
			end

			for Key, Value in next, Storage do
				AddEntry(Key, Value)
			end

			if typeof(Locked) == "table" and not IsShared then
				for Key, Value in next, Locked do
					if ShouldHideRawKey(Key) then
						continue
					end
					AddEntry(Key, Value)
				end
			end

			if not IsShared then
				for Key, Stored in next, State.EnvValues do
					if ShouldHideRawKey(Key) then
						continue
					end
					AddEntry(Key, Stored[1])
				end
			end

			for Key, Value in next, Env do
				AddEntry(Key, Value)
			end

			return Entries
		end

		Env = setmetatable({ P = Name }, {
			__index = function(_, Key)
				if Key == "P" or Key == "ISP" then
					return rawget(_, Key)
				end
				if ShouldHideRawKey(Key) then
					return nil
				end

				local Stored = Storage[Key]
				if Stored ~= nil then
					return Stored
				end

				if not IsShared then
					local FenvValue = State.EnvValues[Key]
					if FenvValue then
						return FenvValue[1]
					end

					local BaseValue = BaseValues[Key]
					if BaseValue ~= nil then
						if ShouldHideRawKey(Key) then
							return BaseValue
						end
						return BaseValue
					end

					local Locked = LockedEnv
					if typeof(GetLockedEnv) == "function" then
						local Ok, Resolved = pcall(GetLockedEnv)
						if Ok then
							Locked = Resolved
						end
					end
					if typeof(Locked) == "table" then
						local LockedValue = rawget(Locked, Key)
						if LockedValue ~= nil then
							if ShouldHideRawKey(Key) then
								return LockedValue
							end
							return LockedValue
						end
					end
				end

				local Indexed = StringUtil.Index(Key, Name)

				if Config.spy_exec_only then
					return nil
				end

				if Config.env_index then
					Emitter:Append(`local _ = {Indexed}`)
				else
					local Var = Scope:AddVar("_", "", Indexed, "__index")
					return Proxy:Spy(Var)
				end

				return Proxy:Spy(Indexed)
			end,
			__newindex = function(_, Key, Value)
				if Key == "P" or Key == "ISP" or Key == "V" then
					rawset(_, Key, Value)
					return
				end
				if ShouldHideRawKey(Key) then
					return
				end

				Storage[Key] = Value
				rawset(_, Key, Value)
				if not IsShared then
					State.EnvValues[Key] = { Value }
				end

				local InternalVal = State:IsInternal(Value)
				local Indexed = StringUtil.Index(Key, Name)
				local BeautifiedVal = InternalVal or Beautifier:Beautify(Value, State.CurrentIndent + 1)

				local Protected = { "io", "os", "package", "require", "debug" }
				local Code = `{Indexed} = {BeautifiedVal}`

				if Value == nil and table.find(Protected, Key) then
					Code = `
				end

				Emitter:Append(Code)
			end,
			__tostring = function()
				return Name
			end,
			__iter = function()
				local Entries = GetIterableEntries()
				local Cursor = 0
				return function()
					Cursor += 1
					local Entry = Entries[Cursor]
					if Entry ~= nil then
						return Entry[1], Entry[2]
					end
					return nil
				end, nil, nil
			end,
			__metatable = nil,
		})

		SyncFromFenv()
		State:RegisterInternal(Env, Name)
		Stores[Name] = { Env = Env, Storage = Storage, Sync = SyncFromFenv }

		return Env
	end

	local Getgenv = CreateSharedEnv("getgenv()")
	local Shared = CreateSharedEnv("shared")
	local GlobalG = CreateSharedEnv("_G")

	rawset(GlobalG, "_G", GlobalG)
	rawset(GlobalG, "_VERSION", rawget(GlobalG, "_VERSION") or "Luau")
	rawset(Getgenv, "_G", GlobalG)
	rawset(Getgenv, "_VERSION", rawget(Getgenv, "_VERSION") or "Luau")

	return {
		getgenv = function()
			return GlobalG
		end,
		shared = Shared,
		_G = GlobalG,
		Stores = Stores,
		Sync = function()
			for _, Store in next, Stores do
				Store.Sync()
			end
		end,
	}
end

return SharedEnvs