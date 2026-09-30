local StringUtil = require("../Utils/String")
local Constants = require("../Data/Constants")

local Minifier = {}

local function LooksLikeCallExpression(Value)
	if typeof(Value) ~= "string" then
		return false
	end

	local Stripped = StringUtil.Strip(Value)
	if Stripped == "" then
		return false
	end

	local Prefix = string.match(Stripped, "^([%w_%.:%[%]\"']+)%s*%(")
	if not Prefix then
		return false
	end

	if string.sub(Stripped, -1) ~= ")" then
		return false
	end

	local Depth = 0
	for I = 1, #Stripped do
		local Ch = string.sub(Stripped, I, I)
		if Ch == "(" then
			Depth += 1
		elseif Ch == ")" then
			Depth -= 1
			if Depth < 0 then
				return false
			end
		end
	end

	return Depth == 0
end

function Minifier.new(State, Config)
	local Self = setmetatable({}, { __index = Minifier })
	Self.State = State
	Self.Config = Config
	Self.Replace = {}
	Self.CachedSafe = {}
	return Self
end

function Minifier:GetSafe(Val)
	local Cached = self.CachedSafe[Val]
	if Cached then return Cached end

	local Safe = StringUtil.PatternSafe(Val)
	self.CachedSafe[Val] = Safe
	return Safe
end

function Minifier:HandleSplit(Separated)
	local State = self.State
	local Side1 = Separated[1]
	local Side2 = table.concat(table.move(Separated, 2, #Separated, 1, {}), "=")

	local IsLocal = string.sub(Side1, 1, 5) == "local"
	local Var = IsLocal and string.sub(Side1, 7, -2)
	local Value = State.Values[Var]
	local Old = `{Side1}={Side2}`

	if not Var or not Value or not Value.Value then
		return Old
	end

	if Value.NoEmit then
		return nil
	end

	if Value.Usage == 0 then
		if Value.Tag == "__call" then
			if typeof(Value.Value) == "string" and string.match(Value.Value, "^game:HttpGet%(") then
				return nil
			end
			if LooksLikeCallExpression(Value.Value) then
				return Value.Value
			end
			return nil
		end
		return nil
	end

	if Value.Usage == 1 then
		return Old
	end

	if self.Config.varRenamer and self.Renamer then
		return self.Renamer:GetName(Var, Value, Side2, Old)
	end

	return Old
end

function Minifier:SetRenamer(Renamer)
	self.Renamer = Renamer
end

function Minifier:Process(Output)
	local Result = ""
	local State = self.State

	for _, Line in Output do
		if not Line then
			continue
		end

		local Stripped = StringUtil.Strip(Line)
		local RetVar, PackVar = string.match(Stripped, "^local%s+([%w_]+)%s*=%s*([%w_]+)%s*%[%s*%d+%s*%]%s*;?$")
		if RetVar and PackVar then
			local RetEntry = State.Values[RetVar]
			local PackEntry = State.Values[PackVar]

			if RetEntry and PackEntry and PackEntry.Tag == "__call" then
				if (RetEntry.Usage or 0) > 0 then
					PackEntry.Usage = math.max(PackEntry.Usage or 0, 1)
				end
			end
		end
	end

	for _, Line in Output do
		if not Line then
			continue
		end

		local Stripped = StringUtil.Strip(Line)
		for Var, Entry in next, State.Values do
			if not Entry or (Entry.Tag ~= "__pack" and not string.match(StringUtil.Strip(tostring(Entry.Value or "")), "^table%.pack%(")) then
				continue
			end

			if string.find(Stripped, Var .. "[", 1, true)
				or string.find(Stripped, Var .. ".n", 1, true)
				or string.find(Stripped, "table.unpack(" .. Var, 1, true)
				or string.find(Stripped, "unpack(" .. Var, 1, true)
			then
				Entry.Usage = math.max(Entry.Usage or 0, 1)
			end
		end
	end

	for _, Line in Output do
		if not Line then continue end

		local Stripped = StringUtil.Strip(Line)
		local Separated = string.split(Stripped, "=")
		local Spaces = string.match(Line, "^%s+") or ""

		if #Separated > 1 then
			local Handled = self:HandleSplit(Separated)
			if not Handled then continue end
			Line = Spaces .. Handled
		end

		Result ..= Line .. "\n"
	end

	return Result
end

function Minifier:ApplyReplacements(Source)
	Source = string.gsub(Source, "if not not ", "if ")

	for Var, Value in next, self.Replace do
		Source = string.gsub(Source, "%f[%w_]" .. Var .. "%f[^%w_]", StringUtil.PatternSafe(Value))
	end

	return Source
end

function Minifier:Run(Output)
	local Processed = self:Process(Output)
	return self:ApplyReplacements(Processed)
end

return Minifier