local fs = require("@lune/fs")

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(State, Config)
	local Self = setmetatable({}, Emitter)
	Self.State = State
	Self.Config = Config
	Self.IndentStr = "    "
	Self.LastAppendedLine = nil
	Self.RepeatedLineCount = 0
	Self.SuppressedLineCount = 0
	Self.MaxRepeatedLineEcho = Config.max_repeated_output_lines or 4
	Self.MaxSuppressedLineBuffer = Config.max_suppressed_output_lines or 1000
	return Self
end

function Emitter:Tab()
	return string.rep(self.IndentStr, self.State.CurrentIndent)
end

function Emitter:_FinalizeOutputChecks()
	local State = self.State
	local MaxOutput = self.Config.max_output_lines or self.Config.max_output
	if typeof(MaxOutput) ~= "number" or MaxOutput <= 0 then
		MaxOutput = math.max(5000, (self.Config.max_ops or 10000) * 3)
	end

	State:CheckOutputLimit(MaxOutput)

	if self.Config.saveFails and self.Config.outfile then
		task.spawn(fs.writeFile, self.Config.outfile, table.concat(State.Output, "\n"))
	end
end

function Emitter:_PushLine(Line)
	local State = self.State
	State.Output[#State.Output + 1] = Line
	self:_FinalizeOutputChecks()
end

function Emitter:FlushRepeated()
	if self.SuppressedLineCount > 0 then
		local Summary = self:Tab() .. ``
		self:_PushLine(Summary)
		self.SuppressedLineCount = 0
	end
	self.RepeatedLineCount = 0
end

function Emitter:Append(Line)
	local FullLine = self:Tab() .. Line

	if self.LastAppendedLine == FullLine then
		self.RepeatedLineCount += 1
		if self.RepeatedLineCount > self.MaxRepeatedLineEcho then
			self.SuppressedLineCount += 1
			if self.MaxSuppressedLineBuffer > 0 and self.SuppressedLineCount >= self.MaxSuppressedLineBuffer then
				self:FlushRepeated()
			end
			return
		end
	else
		self:FlushRepeated()
		self.LastAppendedLine = FullLine
		self.RepeatedLineCount = 1
	end

	self:_PushLine(FullLine)
end

function Emitter:AppendRaw(Line)
	self:FlushRepeated()
	self.LastAppendedLine = nil
	self:_PushLine(Line)
end

function Emitter:Indent()
	self.State.CurrentIndent += 1
end

function Emitter:Dedent()
	local State = self.State
	if State.CurrentIndent > 0 then
		State.CurrentIndent -= 1
	end
end

function Emitter:SetIndent(Level)
	self.State.CurrentIndent = Level
end

function Emitter:GetIndent()
	return self.State.CurrentIndent
end

function Emitter:CloseEnds(Count)
	for _ = 1, Count do
		self:Append("end")
	end
end

function Emitter:GetOutput()
	self:FlushRepeated()
	return self.State.Output
end

function Emitter:GetOutputText()
	self:FlushRepeated()
	local Result = {}
	for _, Line in self.State.Output do
		if Line ~= nil then
			table.insert(Result, Line)
		end
	end
	return table.concat(Result, "\n")
end

function Emitter:IndentBlock(Body)
	self:Indent()
	Body()
	self:Dedent()
end

function Emitter:WithTab(Indent, Body)
	local Old = self.State.CurrentIndent
	self.State.CurrentIndent = Indent
	Body()
	self.State.CurrentIndent = Old
end

return Emitter