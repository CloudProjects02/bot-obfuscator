local ScopeFixer = {}

function ScopeFixer.new(State)
	local Self = setmetatable({}, { __index = ScopeFixer })
	Self.State = State
	Self.HoistedVars = {}
	return Self
end

function ScopeFixer:FindDeclaration(Var, StartLine, EndLine)
	local State = self.State
	EndLine = math.min(EndLine or #State.Output, #State.Output)

	for I = StartLine, EndLine do
		local Line = State.Output[I]
		if not Line then continue end

		local Pattern = `^(%s*)local%s+{Var}%s*=`
		if string.match(Line, Pattern) then
			return I
		end
	end

	return nil
end

function ScopeFixer:FindUsages(Var, StartLine, EndLine)
	local State = self.State
	local Usages = {}
	EndLine = math.min(EndLine or #State.Output, #State.Output)

	for I = StartLine, EndLine do
		local Line = State.Output[I]
		if not Line then continue end
		if string.find(Line, Var, 1, true) then
			table.insert(Usages, I)
		end
	end

	return Usages
end

function ScopeFixer:Hoist(Var, DeclarationLine, InitValue)
	local State = self.State

	if self.HoistedVars[Var] then return end

	local Line = State.Output[DeclarationLine]
	if not Line then return end

	local Indent, Assignment = string.match(Line, `^(%s*)local%s+{Var}%s*=%s*(.+)$`)

	if not Assignment then return end

	State.Output[DeclarationLine] = `{Indent or ""}{Var} = {Assignment}`

	local InsertLine = 1

	for I = 1, DeclarationLine - 1 do
		local L = State.Output[I]
		if L and not string.match(L, "^%s*local%s+") and not string.match(L, "^%s*$") and not string.match(L, "^%s*%-%-") then
			InsertLine = I
			break
		end
	end

	table.insert(State.Output, InsertLine, `local {Var} = {InitValue or "nil"}`)

	self.HoistedVars[Var] = true
end

function ScopeFixer:FixBlock(BlockStart, BlockEnd)
	local State = self.State
	BlockEnd = math.min(BlockEnd, #State.Output)

	local Declarations = {}

	for I = BlockStart, BlockEnd do
		local Line = State.Output[I]
		if not Line then continue end

		local Var = string.match(Line, "^%s*local%s+([%w_]+)%s*=")
		if Var then
			table.insert(Declarations, { Var = Var, Line = I })
		end
	end

	for _, Decl in Declarations do
		local Usages = self:FindUsages(Decl.Var, BlockEnd + 1)

		if #Usages > 0 then
			self:Hoist(Decl.Var, Decl.Line)
		end
	end
end

function ScopeFixer:FixAll()
	local State = self.State
	local Output = State.Output

	local Blocks = {}
	local Stack = {}

	for I = 1, #Output do
		local Line = Output[I]
		if not Line then continue end

		local Stripped = string.match(Line, "^%s*(.-)%s*$") or ""

		local IsBlockStart = string.match(Stripped, "^if%s+") or
			string.match(Stripped, "^for%s+") or
			string.match(Stripped, "^while%s+") or
			string.match(Stripped, "^repeat$") or
			string.match(Stripped, "^do$") or
			string.match(Stripped, "function%s*%(")

		if IsBlockStart then
			table.insert(Stack, I)
		end

		local IsBlockEnd = Stripped == "end" or string.match(Stripped, "^until%s+")

		if IsBlockEnd and #Stack > 0 then
			local Start = table.remove(Stack)
			table.insert(Blocks, { Start = Start, End = I })
		end
	end

	for _, Block in Blocks do
		self:FixBlock(Block.Start, Block.End)
	end
end

function ScopeFixer:FixPcall(PcallStart, PcallEnd)
	self:FixBlock(PcallStart, PcallEnd)
end

function ScopeFixer:FixFunction(FuncStart, FuncEnd)
	self:FixBlock(FuncStart, FuncEnd)
end

return ScopeFixer