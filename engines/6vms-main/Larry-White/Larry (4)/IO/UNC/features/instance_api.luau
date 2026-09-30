local TypeGuards = require("../util/typeguards")
local IdentityUtil = require("../../../Utils/Identity")

local InstanceApi = {}
local LuauModule = nil
local LuauCheckComplete = false

local function GetLuauModule()
	if LuauCheckComplete then
		return LuauModule
	end

	LuauCheckComplete = true
	local Ok, Loaded = pcall(require, "@lune/luau")
	if Ok then
		LuauModule = Loaded
	end

	return LuauModule
end

local function IsProtectedStringModule(ModuleName)
	return typeof(ModuleName) == "string" and string.sub(ModuleName, 1, 6) == "@lune/"
end

function InstanceApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope, Hierarchy)
	local noop = Ctx.noop

	local function TraceValue(Name, Value, Result, TrackResult)
		if Emitter ~= nil and Beautifier ~= nil and Scope ~= nil and State ~= nil then
			local Var = Scope:GenerateName(Name, Name .. "Result")
			Emitter:Append(`local {Var} = {Value}`)
			State:Define(Var, Value, "__call")
			if TrackResult ~= false and Result ~= nil then
				local Kind = typeof(Result)
				if Kind == "table" or Kind == "function" or Kind == "thread" or Kind == "userdata" then
					State:RegisterInternal(Result, Var)
				end
			end
		end
		return Result
	end

	local function CallValue(Name, ...)
		local Args = table.pack(...)
		return Args.n > 0 and `{Name}({Beautifier:BeautifyTuple(table.unpack(Args, 1, Args.n))})` or `{Name}()`
	end

	return {
		cloneref = function(Obj)
			local IsInstanceLike = typeof(Obj) == "Instance"
			if not IsInstanceLike and typeof(Obj) == "table" and typeof(Obj.IsA) == "function" then
				local OkClass = pcall(function()
					return Obj.ClassName
				end)
				IsInstanceLike = OkClass
			end

			if IsInstanceLike then
				local OkClone, Cloned = pcall(function()
					return (Obj :: any):Clone()
				end)
				if OkClone and Cloned ~= nil then
					pcall(function()
						(Cloned :: any).Parent = nil
					end)
					Ctx.cloneref_map[Cloned] = Obj
					return Cloned
				end

				local ClassName = nil
				pcall(function()
					ClassName = (Obj :: any).ClassName
				end)
				if typeof(ClassName) == "string" and ClassName ~= "" then
					local Synthetic = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, ClassName)
					if Synthetic ~= nil then
						pcall(function()
							Synthetic.Name = (Obj :: any).Name
						end)
						Ctx.cloneref_map[Synthetic] = Obj
						return Synthetic
					end
				end

				local proxy = newproxy(true)
				local mt = getmetatable(proxy)
				mt.__index = function(_, k)
					return (Obj :: any)[k]
				end
				mt.__newindex = function(_, k, v)
					(Obj :: any)[k] = v
				end
				mt.__tostring = function()
					return tostring(Obj)
				end
				Ctx.cloneref_map[proxy] = Obj
				return proxy
			end
			if typeof(Obj) == "table" then
				local proxy = setmetatable({}, {
					__index = function(_, k)
						return Obj[k]
					end,
					__newindex = function(_, k, v)
						Obj[k] = v
					end,
					__tostring = function()
						return tostring(Obj)
					end,
					__len = function()
						return #Obj
					end,
					__iter = function()
						return next, Obj
					end,
				})
				Ctx.cloneref_map[proxy] = Obj
				return proxy
			end
			return Obj
		end,

		compareinstances = function(A, B)
			local realA = Ctx.cloneref_map[A] or A
			local realB = Ctx.cloneref_map[B] or B
			return rawequal(realA, realB)
		end,

		getloadedmodules = function()
			if Hierarchy then
				local res = {}
				for _, v in Hierarchy.GetAllInstances() do
					if v:IsA("ModuleScript") then
						table.insert(res, v)
					end
				end
				if #res == 0 then
					local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "ModuleScript")
					if inst then table.insert(res, inst) end
				end
				return TraceValue("getloadedmodules", "getloadedmodules()", res, false)
			end
			return TraceValue("getloadedmodules", "getloadedmodules()", {}, false)
		end,

		getrunningscripts = function()
			if Hierarchy then
				local res = {}
				for _, v in Hierarchy.GetAllInstances() do
					local Parent = nil
					pcall(function()
						Parent = v.Parent
					end)
					if Parent ~= nil and (v:IsA("LocalScript") or v:IsA("Script")) then
						table.insert(res, v)
					end
				end
				if #res == 0 then
					local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "LocalScript")
					if inst then table.insert(res, inst) end
				end
				return TraceValue("getrunningscripts", "getrunningscripts()", res, false)
			end
			return TraceValue("getrunningscripts", "getrunningscripts()", {}, false)
		end,

		getscripts = function()
			if Hierarchy then
				local res = {}
				for _, v in Hierarchy.GetAllInstances() do
					if v:IsA("LocalScript") or v:IsA("ModuleScript") then
						table.insert(res, v)
					end
				end
				if #res == 0 then
					local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "LocalScript")
					if inst then table.insert(res, inst) end
				end
				return TraceValue("getscripts", "getscripts()", res, false)
			end
			return TraceValue("getscripts", "getscripts()", {}, false)
		end,

		getcallingscript = function()
			if Hierarchy then
				local Getter = Hierarchy.GetScriptInstance
				if typeof(Getter) == "function" then
					local Inst = Getter()
					if Inst ~= nil then
						return Inst
					end
				end
				local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "LocalScript")
				if inst then return inst end
			end
			return nil
		end,

		getscriptfromthread = function(Thread)
			if typeof(Thread) ~= "thread" then
				Thread = coroutine.running()
			end
			return nil
		end,

		getscriptclosure = function(Script)
			local ScriptObject = Script
			if typeof(ScriptObject) == "Instance" then
				ScriptObject = ScriptObject
			elseif typeof(ScriptObject) ~= "table" then
				return noop
			end

			local Source = nil
			if typeof(ScriptObject) == "table" then
				Source = ScriptObject.Source
				if Source == nil and typeof(ScriptObject.GetProperty) == "function" then
					Source = ScriptObject:GetProperty("Source")
				end
			end

			if typeof(Source) ~= "string" then
				return noop
			end

			local Luau = GetLuauModule()
			if Luau == nil then
				return noop
			end

			return function(...)
				local OkCompile, Compiled = pcall(Luau.compile, Source)
				if not OkCompile then
					error(Compiled, 0)
				end

				local OkLoad, Loader = pcall(Luau.load, Compiled, {
					debugName = (typeof(ScriptObject) == "table" and (ScriptObject.Name or ScriptObject.ClassName)) or "ModuleScript",
					environment = getfenv(),
				})
				if not OkLoad or typeof(Loader) ~= "function" then
					error(Loader or "failed to load script closure", 0)
				end

				local Result = table.pack(Loader(...))
				return table.unpack(Result, 1, Result.n)
			end
		end,

		getscriptbytecode = function(Script)
			if Script == nil then
				error("invalid argument #1 to 'getscriptbytecode' (Instance expected)", 0)
			end
			if typeof(Script) ~= "table" and typeof(Script) ~= "Instance" then
				return nil
			end
			local Source = nil
			pcall(function()
				if typeof(Script.GetProperty) == "function" then
					Source = Script:GetProperty("Source")
				else
					Source = Script.Source
				end
			end)
			if typeof(Source) ~= "string" or Source == "" then
				return nil
			end
			local Luau = GetLuauModule()
			if Luau == nil then
				return nil
			end
			local Ok, Bytecode = pcall(Luau.compile, Source)
			if Ok and typeof(Bytecode) == "string" then
				return Bytecode
			end
			return nil
		end,

		getscripthash = function(Script)
			local key = ""
			if typeof(Script) == "table" then
				if Script.Source then
					local Version = 0
					if typeof(Script.GetPropertyVersion) == "function" then
						local OkVersion, ResolvedVersion = pcall(function()
							return Script:GetPropertyVersion("Source")
						end)
						if OkVersion and typeof(ResolvedVersion) == "number" then
							Version = ResolvedVersion
						end
					end
					key = tostring(Script.Source) .. "#" .. tostring(Version)
				elseif Script.GetFullName then
					local ok, fn = pcall(function() return Script:GetFullName() end)
					if ok then key = fn end
				end
			elseif typeof(Script) == "Instance" then
				pcall(function()
					local Source = (Script :: any).Source
					local Version = 0
					if typeof((Script :: any).GetPropertyVersion) == "function" then
						Version = (Script :: any):GetPropertyVersion("Source")
					end
					if typeof(Source) == "string" and Source ~= "" then
						key = Source .. "#" .. tostring(Version)
					else
						key = Script:GetFullName() .. "#" .. tostring(Version)
					end
				end)
			end
			if key == "" then
				key = tostring(Script)
			end
			local hash = 5381
			for i = 1, #key do
				hash = ((hash * 33) + string.byte(key, i)) % 4294967296
			end
			return string.format("%032x", hash)
		end,

		getinstances = function()
			if Hierarchy then
				local res = Hierarchy.GetAllInstances()
				if #res == 0 then
					local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "Part")
					if inst then table.insert(res, inst) end
				end
				return TraceValue("getinstances", "getinstances()", res, false)
			end
			return TraceValue("getinstances", "getinstances()", {}, false)
		end,

		getnilinstances = function()
			if Hierarchy then
				local res = {}
				for _, v in Hierarchy.GetAllInstances() do
					local ok, p = pcall(function() return v.Parent end)
					if ok and p == nil then
						table.insert(res, v)
					end
				end
				while #res < 10 do
					local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "Folder")
					if not inst then
						break
					end
					table.insert(res, inst)
				end
				return TraceValue("getnilinstances", "getnilinstances()", res, false)
			end
			return TraceValue("getnilinstances", "getnilinstances()", {}, false)
		end,

		getobjects = function(Asset)
			if typeof(Asset) ~= "string" then error("invalid argument #1 to 'getobjects' (string expected)") end
			local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "Model")
			if inst then return TraceValue("getobjects", CallValue("getobjects", Asset), { inst }, false) end
			return TraceValue("getobjects", CallValue("getobjects", Asset), {}, false)
		end,

		gethui = function()
			if Hierarchy then
				local Svc = Hierarchy.GetService("CoreGui")
				if Svc then return TraceValue("gethui", "gethui()", Svc) end
				local Root = Hierarchy.GetRoot()
				if Root then return TraceValue("gethui", "gethui()", Root) end
			end
			local ok, result = pcall(function()
				return game:GetService("CoreGui")
			end)
			if ok then return TraceValue("gethui", "gethui()", result) end
			local inst = TypeGuards.TryNewInstance(Proxy, State, Emitter, Beautifier, Scope, "Folder")
			if inst then return TraceValue("gethui", "gethui()", inst) end
			return TraceValue("gethui", "gethui()", nil)
		end,

		getactors = function()
			if Hierarchy then
				local res = {}
				for _, v in Hierarchy.GetAllInstances() do
					if v:IsA("Actor") then
						table.insert(res, v)
					end
				end
				return res
			end
			return {}
		end,

		getpointerfrominstance = function(Inst)
			if typeof(Inst) == "table" then
				return tostring(Inst):gsub("table: ", "0x")
			end
			if typeof(Inst) == "Instance" then
				return "0x" .. string.format("%x", math.random(100000, 999999999))
			end
			return "0x" .. IdentityUtil.Generate(8)
		end,

		getspecialinfo = function(Inst)
			return {
				ClassName = (typeof(Inst) == "table" and Inst.ClassName) or (typeof(Inst) == "Instance" and Inst.ClassName) or "Unknown",
				MeshId = "",
				TextureId = "",
				AssetId = "",
			}
		end,

		getcustomasset = function(Path)
			if typeof(Path) ~= "string" then error("invalid argument #1 to 'getcustomasset' (string expected)") end
			if string.sub(Path, 1, 11) == "rbxasset://" then
				error("invalid argument #1 to 'getcustomasset' (expected local file path)", 0)
			end
			return "rbxasset://" .. Path
		end,

		require = function(Module)
			local ModulePath = State:IsInternal(Module)
			local TraceCall = `require({ModulePath or Beautifier:Beautify(Module)})`
			local ModuleScript = nil

			if typeof(Module) == "table" and Module.IsA then
				local ok, isMs = pcall(function()
					return Module:IsA("ModuleScript")
				end)
				if ok and isMs then
					ModuleScript = Module
				end
			end

			if ModuleScript then
				local Parent = nil
				if typeof(ModuleScript.GetParent) == "function" then
					local okParent, parentResult = pcall(function()
						return ModuleScript:GetParent()
					end)
					if okParent then
						Parent = parentResult
					end
				end
				if Parent == nil then
					error("module script must be parented before require", 0)
				end

				local Cached = Ctx.module_require_cache[ModuleScript]
				if Cached ~= nil then
					return TraceValue("require", TraceCall, Cached)
				end

				local Source = ModuleScript.Source
				if typeof(Source) ~= "string" then
					error("ModuleScript.Source must be a string", 0)
				end

				local luau = GetLuauModule()
				if not luau then
					error("module loader unavailable", 0)
				end

				local ok2, Compiled = pcall(luau.compile, Source)
				if not ok2 then
					error(Compiled, 0)
				end

				local ok3, LoaderOrErr = pcall(luau.load, Compiled, {
					debugName = ModuleScript.Name or "ModuleScript",
					environment = getfenv(),
				})
				if not ok3 or typeof(LoaderOrErr) ~= "function" then
					error(LoaderOrErr or "failed to load module", 0)
				end

				local Run = table.pack(pcall(LoaderOrErr))
				if not Run[1] then
					error(Run[2], 0)
				end

				if Run.n < 2 or Run[2] == nil then
					error("module code did not return exactly one value", 0)
				end

				Ctx.module_require_cache[ModuleScript] = Run[2]
				return TraceValue("require", TraceCall, Run[2])
			end

			if typeof(Module) == "string" then
				if Module == "@lune/task" then
					local CurrentEnv = getfenv()
					if typeof(CurrentEnv) == "table" and rawget(CurrentEnv, "task") ~= nil then
						return TraceValue("require", TraceCall, rawget(CurrentEnv, "task"))
					end
				end
				if IsProtectedStringModule(Module) then
					error(`cannot require protected module '{Module}'`, 0)
				end
				local ok, Result = pcall(require, Module)
				if ok then
					return TraceValue("require", TraceCall, Result)
				end
				error(Result, 0)
			end

			error(`invalid argument #1 to 'require' (string or ModuleScript expected, got {typeof(Module)})`, 0)
		end,
	}
end

return InstanceApi