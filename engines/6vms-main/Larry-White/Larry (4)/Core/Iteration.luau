local Iteration = {}

function Iteration.new(Proxy, State, Emitter, Scope, Beautifier)
	local Self = setmetatable({}, { __index = Iteration })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Scope = Scope
	Self.Beautifier = Beautifier
	return Self
end

function Iteration:Iter(Object, Key)
	local State = self.State
	local Emitter = self.Emitter
	local Proxy = self.Proxy
	local Scope = self.Scope

	local Path = rawget(Object, "P")
	local Entry = State.Values[Path] or {}

	local IterFunc = Path

	if not Key then
		if Entry.Tag == "__call" and Entry.Usage == 0 then
			IterFunc = Entry.Value
			State:RemoveOutputLine(Entry.Line)
		end
	else
		local Arg1 = Path
		if Entry.Usage == 0 then
			Arg1 = Entry.Value or Path
		end

		if Key == "next" then
			IterFunc = `next, {Arg1}`
		else
			IterFunc = `{Key}({Arg1})`
		end
	end

	local Iv = Scope:GenerateName("k", "iter")
	local Vv = Scope:GenerateName("val", "iter")

	Emitter:Append(`for {Iv}, {Vv} in {IterFunc} do`)

	local Called = false
	local Indent = State.CurrentIndent

	State.CurrentIndent = Indent + 1

	return function(_, K)
		if Called then
			State.CurrentIndent = Indent
			Emitter:Append("end")
			return
		end

		Called = true
		return Proxy:Spy(Iv), Proxy:Spy(Vv)
	end
end

function Iteration:HookNext(Tbl, ...)
	local State = self.State
	local NextCalls = State.NextCalls

	local Path = State:IsInternal(Tbl)

	if Path == "getfenv()" then
		return next(Tbl, ...)
	end

	if Path then
		if NextCalls[Tbl] then
			return NextCalls[Tbl](Tbl, ...)
		end

		local Func = function(T, K)
			return self:Iter(T, "next")(T, K)
		end

		NextCalls[Tbl] = Func
		return Func(Tbl, ...)
	end

	return next(Tbl, ...)
end

function Iteration:CreatePairsProxy(Key)
	local Proxy = self.Proxy
	local State = self.State
	local TrueEnv = getfenv()

	return Proxy:NewCClosure(function(Tbl)
		if State:IsInternal(Tbl) then
			return self:Iter(Tbl, Key)
		end
		return TrueEnv[Key](Tbl)
	end)
end

function Iteration:IterMetamethod()
	return function(Object, Key)
		return self:Iter(Object, Key)
	end
end

function Iteration:GameChildrenIter(Children, TypeInference)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Scope = self.Scope

	local Index = 0
	local Total = #Children

	return function()
		Index += 1
		if Index > Total then return nil end

		local Child = Children[Index]
		return Proxy:Spy(Scope:AddVar("i", "iter", tostring(Index), "__iter")),
			Proxy:Spy(Scope:AddVar("child", "iter", tostring(Child), "__iter"))
	end
end

return Iteration