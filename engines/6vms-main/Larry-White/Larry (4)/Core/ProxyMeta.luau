local StringUtil = require("../Utils/String")
local TableUtil = require("../Utils/Table")

local ProxyMeta = {}

function ProxyMeta.Build(Proxy, Path, IsParam)
	local State = Proxy.State
	local Emitter = Proxy.Emitter
	local Beautifier = Proxy.Beautifier
	local Scope = Proxy.Scope
	local Config = Beautifier.Config
	local MaxOps = Config.max_ops or 10500

	local IsFunction = false
	if typeof(IsParam) == "table" then
		IsFunction = IsParam.Function
		IsParam = IsParam.Param
	end

	local function InternalValue(Value, PathValue)
		if not PathValue then
			return Value
		end

		if typeof(Value) == "table" then
			local Unwrapped = rawget(Value, "V")
			if Unwrapped ~= nil then
				return Unwrapped
			end
		end

		return Value
	end

	local function Arth(Symbol)
		return Proxy:NewCClosure(function(A, B)
			local Value = `{Beautifier:Beautify(A)} {Symbol} {Beautifier:Beautify(B)}`
			local Var = State:NextId()

			local OpMode = Symbol == ".." and "CONCAT" or "ARTH"
			local ModeValue = typeof(Config.hookOpValue) == "table" and Config.hookOpValue[OpMode] or Config.hookOpValue

				local VA = InternalValue(A, State:IsInternal(A))
				local VB = InternalValue(B, State:IsInternal(B))

			local Ok, Computed = pcall(function()
				if Symbol == "+" then return VA + VB end
				if Symbol == "-" then return VA - VB end
				if Symbol == "*" then return VA * VB end
				if Symbol == "/" then return VA / VB end
				if Symbol == "//" then return VA // VB end
				if Symbol == "^" then return VA ^ VB end
				if Symbol == "%" then return VA % VB end
				if Symbol == ".." then return VA .. VB end
				return nil
			end)

			if ModeValue == "spy" then
				Emitter:Append(`local {Var} = {Value}`)
				State:Define(Var, Value, "__arth")
				local Result = Proxy:Spy(Var)
				if Ok and Computed ~= nil then
					rawset(Result, "V", Computed)
				elseif Symbol == ".." then
					rawset(Result, "V", "")
				else
					rawset(Result, "V", 0)
				end
				return Result
			end

			if not Ok then
				error(Computed, 0)
			end

			return Computed
		end)
	end

	local function Comp(Symbol)
		return function(A, B)
			local PathA = State:IsInternal(A)
			local PathB = State:IsInternal(B)

			local VA = InternalValue(A, PathA)
			local VB = InternalValue(B, PathB)

			local Left = PathA or Beautifier:Beautify(A)
			local Right = PathB or Beautifier:Beautify(B)

			if PathA then State:Use(PathA, "__comp", true) end
			if PathB then State:Use(PathB, "__comp", true) end

			local Value = `{Left} {Symbol} {Right}`
			local Var = Scope:AddVar("comp", Symbol, Value, "__comp")

			local Ok, Computed = pcall(function()
				if Symbol == "<" then return VA < VB end
				if Symbol == ">" then return VA > VB end
				if Symbol == "<=" then return VA <= VB end
				if Symbol == ">=" then return VA >= VB end
				return false
			end)
			if not Ok then
				error(Computed, 0)
			end

			return Computed
		end
	end

	local function Eq(A, B)
		local PathA = State:IsInternal(A)
		local PathB = State:IsInternal(B)

		local VA = InternalValue(A, PathA)
		local VB = InternalValue(B, PathB)

		local Left = PathA or Beautifier:Beautify(A)
		local Right = PathB or Beautifier:Beautify(B)

		if PathA then State:Use(PathA, "__comp", true) end
		if PathB then State:Use(PathB, "__comp", true) end

		local Value = `{Left} == {Right}`
		Emitter:Append(`local check = {Value}`)

		if rawequal(A, B) then return true end
		if rawequal(VA, VB) then return true end

		local Ok, Res = pcall(function() return VA == VB end)
		return Ok and Res or false
	end

	local function OpGuard(Method)
		return function(Self, ...)
			State:IncrementOps()
			if State.OpCount >= MaxOps then
				error("Too many operations.", 0)
			end
			if IsParam then State.ParamsUsed[Path] = true end
			return Method(Self, ...)
		end
	end

	local Mt = {}

	Mt.__index = OpGuard(function(_, Key)
		local StoredValue = rawget(_, "V")
		if StoredValue ~= nil then
			if typeof(StoredValue) == "string" and typeof(Key) == "string" then
				local DirectString = string[Key]
				if typeof(DirectString) == "function" then
					return function(_, ...)
						local Args = table.pack(...)
						local Tuple = {}
						for I = 1, Args.n do
							Tuple[I] = Beautifier:Beautify(Args[I], State.CurrentIndent + 1)
						end

						local Value
						if Args.n > 0 then
							Value = `{Path}:{Key}({table.concat(Tuple, ", ")})`
						else
							Value = `{Path}:{Key}()`
						end

						local Results = table.pack(DirectString(StoredValue, ...))
						if Results.n <= 1 then
							if Results[1] ~= nil then
								local Var = Scope:AddVar(Key, "str", Value, "__call")
								State:RegisterInternal(Results[1], Var)
							else
								Emitter:Append(Value)
							end

							return Results[1]
						end

						local Locals = {}
						for I = 1, Results.n do
							Locals[I] = Scope:GenerateName(Key, I == 1 and "str" or "ret")
						end
						Emitter:Append(`local {table.concat(Locals, ", ")} = {Value}`)

						for I = 1, Results.n do
							local CallVar = Locals[I]
							State:Define(CallVar, `select({I}, {Value})`, "__call")
							if Results[I] ~= nil then
								State:RegisterInternal(Results[I], CallVar)
							end
						end

						return table.unpack(Results, 1, Results.n)
					end
				end
			end

			local Ok, Direct = pcall(function() return StoredValue[Key] end)
			if not Ok then
				error(tostring(Direct), 0)
			end
			if Direct ~= nil then
				local IsDataType = rawget(StoredValue, "__larryType") ~= nil
				local IsSignal = typeof(StoredValue._Name) == "string" and typeof(StoredValue._Connections) == "table" and typeof(StoredValue.Connect) == "function"
				local IsConnection = typeof(StoredValue.Connected) == "boolean" and typeof(StoredValue._Signal) == "table"
				if IsDataType or IsSignal or IsConnection then
					if typeof(Direct) == "function" then
						return function(_, ...)
							return Direct(StoredValue, ...)
						end
					else
						return Direct
					end
				end
			end
		end

		local FormattedKey = State:IsInternal(Key)
		local Value
		local MethodName = FormattedKey or Key

		local ModeValue = typeof(Config.hookOpValue) == "table" and Config.hookOpValue.INDEX or Config.hookOpValue
		local HookName = Config.CHECKINDEX and "CHECKINDEX" or "INDEX"

		if FormattedKey then
			Value = `{Path}[{FormattedKey}]`
		else
			Value = StringUtil.Index(Key, Path)
		end

		if ModeValue == "hook" then
			Value = `Wrapper.{HookName}({Path}, {Beautifier:Beautify(Key)})`
		end

		local Var = Scope:GenerateName(Path, typeof(MethodName) == "string" and MethodName or "idx")

		State:Use(Path, "__index", true)
		Emitter:Append(`local {Var} = {Value}`)
		State:Define(Var, Value, "__index")

		return Proxy:Spy(Var)
	end)

	Mt.__newindex = OpGuard(function(_, Key, Value)
		local StoredValue = rawget(_, "V")
		if StoredValue ~= nil then
			local Ok, Err = pcall(function() StoredValue[Key] = Value end)
			if not Ok then
				error(tostring(Err), 0)
			end
		end

		State:Use(Path, "__newindex", true)

		local InternalValue = State:IsInternal(Value)
		if State.Values[InternalValue] then
			State.Values[InternalValue].Usage -= 1
		end

		local InternalKey = State:IsInternal(Key)
		local Var

		if InternalKey then
			Var = `{Path}[{InternalKey}]`
		else
			Var = StringUtil.Index(Key, Path)
		end

		Emitter:Append(`{Var} = {Beautifier:Beautify(Value, State.CurrentIndent + 1)}`)
		State:Use(Var, "__newindex", true)
	end)

	Mt.__call = OpGuard(function(_, ...)
		State:Use(Path, "__call")

		local EffectivePath = Path == "..." and "(...)" or Path

		local Dots = StringUtil.SplitPath(TableUtil.ResolvePath(EffectivePath, State.Values))
		local Self = table.concat(table.move(Dots, 1, #Dots - 1, 1, {}), ".")

		local Args = table.pack(...)
		local Tuple = {}

		local FirstArg = Args[1]
		local SecondArg = Args[2]
		local Var
		local SkipFirstArg = false

		if Beautifier:Beautify(FirstArg) == Self and Self ~= "" then
			local Method = Dots[#Dots]
			EffectivePath = `{Self}:{Method}`
			Var = Scope:GenerateName(Method, typeof(SecondArg) == "string" and SecondArg or "__call")
			SkipFirstArg = true

			local Entry = State.Values[Path]
			if Entry and Entry.Tag == "__index" then
				Entry.NoEmit = true
			end
		end

		local Entry = State.Values[Path]
		if not Var and Entry and Entry.Tag == "__index" and Entry.Usage <= 1 then
			local Resolved = Entry.Value
			if Resolved then
				EffectivePath = Resolved
				Entry.NoEmit = true
			end
		end

		for I = (SkipFirstArg and 2 or 1), Args.n do
			local Arg = Args[I]

			if Path == "loadstring" and I == 2 then
				if typeof(Arg) ~= "string" then
					local ArgPath = State:IsInternal(Arg)
					if ArgPath then
						local ArgEntry = State.Values[ArgPath]
						if ArgEntry then
							ArgEntry.NoEmit = true
						end
					end
					continue
				end
			end

			if Path == "loadstring" and I == 1 then
				local ArgPath = State:IsInternal(Arg)
				if ArgPath then
					local ArgEntry = State.Values[ArgPath]
					if ArgEntry and ArgEntry.Tag == "__call" and typeof(ArgEntry.Value) == "string" then
						if string.match(ArgEntry.Value, "^game:HttpGet%(") then
							ArgEntry.NoEmit = true
							table.insert(Tuple, ArgEntry.Value)
							continue
						end
					end
				end
			end

			local BeautifiedArg = Beautifier:Beautify(Arg, State.CurrentIndent + 1)
			table.insert(Tuple, BeautifiedArg)
		end

		Var = Var or Scope:GenerateName(EffectivePath, typeof(FirstArg) == "string" and FirstArg or "__call")

		local ModeValue = typeof(Config.hookOpValue) == "table" and (SkipFirstArg and Config.hookOpValue.NAMECALL or Config.hookOpValue.CALL) or Config.hookOpValue
		local Value

		if ModeValue == "hook" then
			if SkipFirstArg then
				local Method = Dots[#Dots]
				Value = `Wrapper.NAMECALL({Self}, {StringUtil.Quote(Method)}, {table.concat(Tuple, ", ")})`
			else
				Value = `Wrapper.CALL({EffectivePath}, {table.concat(Tuple, ", ")})`
			end
		else
			Value = `{EffectivePath}({table.concat(Tuple, ", ")})`
		end

		local IsDecompressCall = string.match(EffectivePath, "%.DecompressBuffer$") ~= nil
			or string.match(EffectivePath, ":DecompressBuffer$") ~= nil
		if IsDecompressCall then
			Emitter:Append(`local {Var} = {Value}`)
			State:Define(Var, Value, "__call")

			return 0
		end

		return Proxy:MultiSpy(Var, Value, 3)
	end)

	Mt.__tostring = OpGuard(function(_)
		State:Use(Path, "__tostring")
		return Path
	end)

	Mt.__unm = OpGuard(function(_)
		local Var = Scope:GenerateName(Path, "unm")
		local Value = `-{Path}`
		Emitter:Append(`local {Var} = {Value}`)
		State:Define(Var, Value, "__unm")

		local Result = Proxy:Spy(Var)
		local V = rawget(_, "V")
		if typeof(V) == "number" then
			rawset(Result, "V", -V)
		end
		return Result
	end)

	Mt.__len = OpGuard(function(_)
		local Var = Scope:AddVar("len", "len", `#{Path}`, "__len")
		local Result = Proxy:Spy(Var)

		local V = rawget(_, "V")
		local L = 0

		if V ~= nil then
			local S, LenRes = pcall(function() return #V end)
			if S and type(LenRes) == "number" then
				L = LenRes
			end
		end

		rawset(Result, "V", L)
		return L
	end)

	Mt.__lt = Comp("<")
	Mt.__le = Comp("<=")
	Mt.__eq = Eq

	Mt.__add = Arth("+")
	Mt.__sub = Arth("-")
	Mt.__mul = Arth("*")
	Mt.__div = Arth("/")
	Mt.__idiv = Arth("//")
	Mt.__pow = Arth("^")
	Mt.__concat = Arth("..")
	Mt.__mod = Arth("%")

	Mt.__metatable = {}

	if IsFunction then
		Mt.__call = Mt.__call or OpGuard(function(_, ...)
			State:Use(Path, "__call")
			local Args = table.pack(...)
			local Tuple = {}
			for I = 1, Args.n do
				Tuple[I] = Beautifier:Beautify(Args[I], State.CurrentIndent + 1)
			end
			local Var = Scope:GenerateName(Path, "call")
			local Value = `{Path}({table.concat(Tuple, ", ")})`
			Emitter:Append(`local {Var} = {Value}`)
			State:Define(Var, Value, "__call")
			return Proxy:Spy(Var)
		end)
	end

	return Mt
end

return ProxyMeta