-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- optimized unparser.lua
--
-- Lua 5.1 / LuaU compatible

local config = require("config")
local Ast = require("prometheus.ast")
local Enums = require("prometheus.enums")
local util = require("prometheus.util")
local logger = require("logger")

local lookupify = util.lookupify
local LuaVersion = Enums.LuaVersion
local AstKind = Ast.AstKind
local kindToNumber = Ast.astKindExpressionToNumber

local Unparser = {}

Unparser.SPACE = config.SPACE
Unparser.TAB = config.TAB

local function escapeString(str)
	return util.escape(str)
end

-- Cached compound operators.
local COMPOUND_OPERATORS = {
	[AstKind.CompoundAddStatement] = "+=",
	[AstKind.CompoundSubStatement] = "-=",
	[AstKind.CompoundMulStatement] = "*=",
	[AstKind.CompoundDivStatement] = "/=",
	[AstKind.CompoundModStatement] = "%=",
	[AstKind.CompoundPowStatement] = "^=",
	[AstKind.CompoundConcatStatement] = "..=",
}

-- Binary operators.
local BINARY_OPERATORS = {
	[AstKind.LessThanExpression] = "<",
	[AstKind.GreaterThanExpression] = ">",
	[AstKind.LessThanOrEqualsExpression] = "<=",
	[AstKind.GreaterThanOrEqualsExpression] = ">=",
	[AstKind.NotEqualsExpression] = "~=",
	[AstKind.EqualsExpression] = "==",
	[AstKind.StrCatExpression] = "..",
	[AstKind.AddExpression] = "+",
	[AstKind.SubExpression] = "-",
	[AstKind.MulExpression] = "*",
	[AstKind.DivExpression] = "/",
	[AstKind.ModExpression] = "%",
	[AstKind.PowExpression] = "^",
}

-- Operators where the left/right precedence handling is identical.
local PAREN_BINARY_OPERATORS = {
	[AstKind.LessThanExpression] = true,
	[AstKind.GreaterThanExpression] = true,
	[AstKind.LessThanOrEqualsExpression] = true,
	[AstKind.GreaterThanOrEqualsExpression] = true,
	[AstKind.NotEqualsExpression] = true,
	[AstKind.EqualsExpression] = true,
	[AstKind.StrCatExpression] = true,
	[AstKind.AddExpression] = true,
	[AstKind.SubExpression] = true,
	[AstKind.MulExpression] = true,
	[AstKind.DivExpression] = true,
	[AstKind.ModExpression] = true,
	[AstKind.PowExpression] = true,
}

local function randomTableSeparator()
	return math.random(1, 2) == 1 and "," or ";"
end

function Unparser:new(settings)
	settings = settings or {}

	local luaVersion = settings.LuaVersion or LuaVersion.LuaU
	local conventions = Enums.Conventions[luaVersion]

	local identChars = conventions.IdentChars
	local numberChars = conventions.NumberChars

	local unparser = {
		luaVersion = luaVersion,
		conventions = conventions,

		identCharsLookup = lookupify(identChars),
		numberCharsLookup = lookupify(numberChars),
		keywordsLookup = lookupify(conventions.Keywords),

		prettyPrint = settings.PrettyPrint or false,
		highlight = settings.Highlight or false,

		notIdentPattern = "[^" .. table.concat(identChars, "") .. "]",
		numberPattern = "^[" .. table.concat(numberChars, "") .. "]",
	}

	setmetatable(unparser, self)
	self.__index = self

	return unparser
end

function Unparser:isValidIdentifier(source)
	if #source == 0 then
		return false
	end

	if string.find(source, self.notIdentPattern) then
		return false
	end

	if string.find(source, self.numberPattern) then
		return false
	end

	return not self.keywordsLookup[source]
end

function Unparser:setPrettyPrint(prettyPrint)
	self.prettyPrint = prettyPrint
end

function Unparser:getPrettyPrint()
	return self.prettyPrint
end

function Unparser:tabs(i, wsNeeded)
	if self.prettyPrint then
		return string.rep(self.TAB, i)
	end

	if wsNeeded then
		return self.SPACE
	end

	return ""
end

function Unparser:newline(wsNeeded)
	if self.prettyPrint then
		return "\n"
	end

	if wsNeeded then
		return self.SPACE
	end

	return ""
end

function Unparser:whitespaceIfNeeded(following, ws)
	if self.prettyPrint then
		return ws or self.SPACE
	end

	if following and self.identCharsLookup[following:sub(1, 1)] then
		return ws or self.SPACE
	end

	return ""
end

function Unparser:whitespaceIfNeeded2(leading, ws)
	if self.prettyPrint then
		return ws or self.SPACE
	end

	if leading and #leading > 0
		and self.identCharsLookup[leading:sub(-1)] then
		return ws or self.SPACE
	end

	return ""
end

function Unparser:optionalWhitespace(ws)
	if self.prettyPrint then
		return ws or self.SPACE
	end

	return ""
end

function Unparser:whitespace(ws)
	return ws or self.SPACE
end

function Unparser:unparse(ast)
	if ast.kind ~= AstKind.TopNode then
		logger:error("Unparser:unparse expects a TopNode as first argument")
	end

	return self:unparseBlock(ast.body)
end

function Unparser:unparseBlock(block, tabbing)
	local statements = block.statements
	local count = #statements

	if count < 1 then
		return self:whitespace()
	end

	local parts = {}
	local partCount = 0
	local previousCode = ""
	local pretty = self.prettyPrint

	for i = 1, count do
		local statement = statements[i]

		if statement.kind ~= AstKind.NopStatement then
			local statementCode = self:unparseStatement(statement, tabbing)

			if not pretty
				and #previousCode > 0
				and statementCode:sub(1, 1) == "(" then
				statementCode = ";" .. statementCode
			end

			local ws = self:whitespaceIfNeeded2(
				previousCode,
				self:whitespaceIfNeeded(
					statementCode,
					self:newline(true)
				)
			)

			partCount = partCount + 1

			if i ~= 1 then
				parts[partCount] = ws .. statementCode
			else
				parts[partCount] = statementCode
			end

			if pretty then
				parts[partCount] = parts[partCount] .. ";"
			end

			previousCode = statementCode
		end
	end

	return table.concat(parts)
end

local function joinExpressions(self, expressions, tabbing, separator)
	local count = #expressions

	if count == 0 then
		return ""
	end

	local parts = {}
	local ws = self:optionalWhitespace()
	local sep = separator .. ws

	for i = 1, count do
		parts[i] = self:unparseExpression(expressions[i], tabbing)

		if i < count then
			parts[i] = parts[i] .. sep
		end
	end

	return table.concat(parts)
end

function Unparser:unparseStatement(statement, tabbing)
	tabbing = tabbing and tabbing + 1 or 0

	local kind = statement.kind
	local code

	if kind == AstKind.ContinueStatement then

		code = "continue"

	elseif kind == AstKind.BreakStatement then

		code = "break"

	elseif kind == AstKind.DoStatement then

		local bodyCode = self:unparseBlock(statement.body, tabbing)

		code =
			"do"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.WhileStatement then

		local expressionCode =
			self:unparseExpression(statement.condition, tabbing)

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		code =
			"while"
			.. self:whitespaceIfNeeded(expressionCode)
			.. expressionCode
			.. self:whitespaceIfNeeded2(expressionCode)
			.. "do"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.RepeatStatement then

		local expressionCode =
			self:unparseExpression(statement.condition, tabbing)

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		code =
			"repeat"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:newline() .. self:tabs(tabbing, true)
			)
			.. "until"
			.. self:whitespaceIfNeeded(expressionCode)
			.. expressionCode

	elseif kind == AstKind.ForStatement then

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		local variable =
			statement.scope:getVariableName(statement.id)

		local initialValue =
			self:unparseExpression(statement.initialValue, tabbing)

		local finalValue =
			self:unparseExpression(statement.finalValue, tabbing)

		local incrementBy =
			statement.incrementBy
			and self:unparseExpression(statement.incrementBy, tabbing)
			or "1"

		code =
			"for"
			.. self:whitespace()
			.. variable
			.. self:optionalWhitespace()
			.. "="
			.. self:optionalWhitespace()
			.. initialValue
			.. ","
			.. self:optionalWhitespace()
			.. finalValue
			.. ","
			.. self:optionalWhitespace()
			.. incrementBy
			.. self:whitespaceIfNeeded2(incrementBy)
			.. "do"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.ForInStatement then

		local parts = {
			"for",
			self:whitespace(),
		}

		local partCount = 2

		for i = 1, #statement.ids do
			if i > 1 then
				partCount = partCount + 1
				parts[partCount] = ","
				partCount = partCount + 1
				parts[partCount] = self:optionalWhitespace()
			end

			partCount = partCount + 1
			parts[partCount] =
				statement.scope:getVariableName(statement.ids[i])
		end

		partCount = partCount + 1
		parts[partCount] = self:whitespace()
		partCount = partCount + 1
		parts[partCount] = "in"

		local expressionCode =
			self:unparseExpression(statement.expressions[1], tabbing)

		partCount = partCount + 1
		parts[partCount] =
			self:whitespaceIfNeeded(expressionCode)

		partCount = partCount + 1
		parts[partCount] = expressionCode

		for i = 2, #statement.expressions do
			expressionCode =
				self:unparseExpression(statement.expressions[i], tabbing)

			partCount = partCount + 1
			parts[partCount] = ","

			partCount = partCount + 1
			parts[partCount] = self:optionalWhitespace()

			partCount = partCount + 1
			parts[partCount] = expressionCode
		end

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		partCount = partCount + 1
		parts[partCount] =
			self:whitespaceIfNeeded2(table.concat(parts))
			.. "do"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

		code = table.concat(parts)

	elseif kind == AstKind.IfStatement then

		local expressionCode =
			self:unparseExpression(statement.condition, tabbing)

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		code =
			"if"
			.. self:whitespaceIfNeeded(expressionCode)
			.. expressionCode
			.. self:whitespaceIfNeeded2(expressionCode)
			.. "then"
			.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
			.. bodyCode

		for i = 1, #statement.elseifs do
			local elseifNode = statement.elseifs[i]

			expressionCode =
				self:unparseExpression(elseifNode.condition, tabbing)

			bodyCode =
				self:unparseBlock(elseifNode.body, tabbing)

			code =
				code
				.. self:newline(false)
				.. self:whitespaceIfNeeded2(
					code,
					self:tabs(tabbing, true)
				)
				.. "elseif"
				.. self:whitespaceIfNeeded(expressionCode)
				.. expressionCode
				.. self:whitespaceIfNeeded2(expressionCode)
				.. "then"
				.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
				.. bodyCode
		end

		if statement.elsebody then
			bodyCode =
				self:unparseBlock(statement.elsebody, tabbing)

			code =
				code
				.. self:newline(false)
				.. self:whitespaceIfNeeded2(
					code,
					self:tabs(tabbing, true)
				)
				.. "else"
				.. self:whitespaceIfNeeded(bodyCode, self:newline(true))
				.. bodyCode
		end

		code =
			code
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.FunctionDeclaration then

		local funcname =
			statement.scope:getVariableName(statement.id)

		for i = 1, #statement.indices do
			funcname =
				funcname .. "." .. statement.indices[i]
		end

		local args = {}

		for i = 1, #statement.args do
			local arg = statement.args[i]

			if arg.kind == AstKind.VarargExpression then
				args[i] = "..."
			else
				args[i] =
					arg.scope:getVariableName(arg.id)
			end
		end

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		code =
			"function"
			.. self:whitespace()
			.. funcname
			.. "("
			.. table.concat(args, "," .. self:optionalWhitespace())
			.. ")"
			.. self:newline(false)
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.LocalFunctionDeclaration then

		local funcname =
			statement.scope:getVariableName(statement.id)

		local args = {}

		for i = 1, #statement.args do
			local arg = statement.args[i]

			if arg.kind == AstKind.VarargExpression then
				args[i] = "..."
			else
				args[i] =
					arg.scope:getVariableName(arg.id)
			end
		end

		local bodyCode =
			self:unparseBlock(statement.body, tabbing)

		code =
			"local"
			.. self:whitespace()
			.. "function"
			.. self:whitespace()
			.. funcname
			.. "("
			.. table.concat(args, "," .. self:optionalWhitespace())
			.. ")"
			.. self:newline(false)
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"

	elseif kind == AstKind.LocalVariableDeclaration then

		local parts = {
			"local",
			self:whitespace(),
		}

		for i = 1, #statement.ids do
			if i > 1 then
				parts[#parts + 1] = ","
				parts[#parts + 1] = self:optionalWhitespace()
			end

			parts[#parts + 1] =
				statement.scope:getVariableName(statement.ids[i])
		end

		if #statement.expressions > 0 then
			parts[#parts + 1] = self:optionalWhitespace()
			parts[#parts + 1] = "="
			parts[#parts + 1] = self:optionalWhitespace()

			for i = 1, #statement.expressions do
				if i > 1 then
					parts[#parts + 1] = ","
					parts[#parts + 1] = self:optionalWhitespace()
				end

				parts[#parts + 1] =
					self:unparseExpression(
						statement.expressions[i],
						tabbing + 1
					)
			end
		end

		code = table.concat(parts)

	elseif kind == AstKind.FunctionCallStatement then

		local base = statement.base

		if base.kind == AstKind.IndexExpression
			or base.kind == AstKind.VariableExpression then
			code = self:unparseExpression(base, tabbing)
		else
			code =
				"("
				.. self:unparseExpression(base, tabbing)
				.. ")"
		end

		code =
			code
			.. "("
			.. joinExpressions(self, statement.args, tabbing, ",")
			.. ")"

	elseif kind == AstKind.PassSelfFunctionCallStatement then

		local base = statement.base

		if base.kind == AstKind.IndexExpression
			or base.kind == AstKind.VariableExpression then
			code = self:unparseExpression(base, tabbing)
		else
			code =
				"("
				.. self:unparseExpression(base, tabbing)
				.. ")"
		end

		code =
			code
			.. ":"
			.. statement.passSelfFunctionName
			.. "("
			.. joinExpressions(self, statement.args, tabbing, ",")
			.. ")"

	elseif kind == AstKind.AssignmentStatement then

		local parts = {}

		for i = 1, #statement.lhs do
			if i > 1 then
				parts[#parts + 1] = ","
				parts[#parts + 1] = self:optionalWhitespace()
			end

			parts[#parts + 1] =
				self:unparseExpression(statement.lhs[i], tabbing)
		end

		parts[#parts + 1] = self:optionalWhitespace()
		parts[#parts + 1] = "="
		parts[#parts + 1] = self:optionalWhitespace()

		for i = 1, #statement.rhs do
			if i > 1 then
				parts[#parts + 1] = ","
				parts[#parts + 1] = self:optionalWhitespace()
			end

			parts[#parts + 1] =
				self:unparseExpression(
					statement.rhs[i],
					tabbing + 1
				)
		end

		code = table.concat(parts)

	elseif kind == AstKind.ReturnStatement then

		code = "return"

		if #statement.args > 0 then
			local expressionCode =
				self:unparseExpression(statement.args[1], tabbing)

			local parts = {
				code,
				self:whitespaceIfNeeded(expressionCode),
				expressionCode,
			}

			for i = 2, #statement.args do
				parts[#parts + 1] = ","
				parts[#parts + 1] = self:optionalWhitespace()
				parts[#parts + 1] =
					self:unparseExpression(statement.args[i], tabbing)
			end

			code = table.concat(parts)
		end

	else

		local operator =
			self.luaVersion == LuaVersion.LuaU
			and COMPOUND_OPERATORS[kind]

		if operator then
			code =
				self:unparseExpression(statement.lhs, tabbing)
				.. self:optionalWhitespace()
				.. operator
				.. self:optionalWhitespace()
				.. self:unparseExpression(statement.rhs, tabbing)
		else
			logger:error(
				string.format(
					"\"%s\" is not a valid unparseable statement in %s!",
					kind,
					self.luaVersion
				)
			)
		end
	end

	return self:tabs(tabbing, false) .. code
end

local function binaryExpression(self, expression, tabbing, operator)
	local lhs = self:unparseExpression(expression.lhs, tabbing)
	local rhs = self:unparseExpression(expression.rhs, tabbing)

	local currentKind = kindToNumber(expression.kind)

	if kindToNumber(expression.lhs.kind) >= currentKind then
		lhs = "(" .. lhs .. ")"
	end

	if kindToNumber(expression.rhs.kind) >= currentKind then
		rhs = "(" .. rhs .. ")"
	end

	return lhs
		.. self:optionalWhitespace()
		.. operator
		.. self:optionalWhitespace()
		.. rhs
end

function Unparser:unparseExpression(expression, tabbing)
	local kind = expression.kind

	if kind == AstKind.BooleanExpression then
		return expression.value and "true" or "false"
	end

	if kind == AstKind.NumberExpression then
		local str = tostring(expression.value)

		if str == "inf" then
			return "2e1024"
		end

		if str == "-inf" then
			return "-2e1024"
		end

		if str:sub(1, 2) == "0." then
			return str:sub(2)
		end

		return str
	end

	if kind == AstKind.VariableExpression
		or kind == AstKind.AssignmentVariable then
		return expression.scope:getVariableName(expression.id)
	end

	if kind == AstKind.StringExpression then
		return "\"" .. escapeString(expression.value) .. "\""
	end

	if kind == AstKind.NilExpression then
		return "nil"
	end

	if kind == AstKind.VarargExpression then
		return "..."
	end

	-- OR
	if kind == AstKind.OrExpression then
		local lhs =
			self:unparseExpression(expression.lhs, tabbing)

		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		return lhs
			.. self:whitespaceIfNeeded2(lhs)
			.. "or"
			.. self:whitespaceIfNeeded(rhs)
			.. rhs
	end

	-- AND
	if kind == AstKind.AndExpression then
		local lhs =
			self:unparseExpression(expression.lhs, tabbing)

		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		local currentKind = kindToNumber(kind)

		if kindToNumber(expression.lhs.kind) >= currentKind then
			lhs = "(" .. lhs .. ")"
		end

		if kindToNumber(expression.rhs.kind) >= currentKind then
			rhs = "(" .. rhs .. ")"
		end

		return lhs
			.. self:whitespaceIfNeeded2(lhs)
			.. "and"
			.. self:whitespaceIfNeeded(rhs)
			.. rhs
	end

	-- Binary operators
	local operator = BINARY_OPERATORS[kind]

	if operator then
		local lhs =
			self:unparseExpression(expression.lhs, tabbing)

		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		local currentKind = kindToNumber(kind)

		if kindToNumber(expression.lhs.kind) >= currentKind then
			lhs = "(" .. lhs .. ")"
		end

		if kindToNumber(expression.rhs.kind) >= currentKind then
			rhs = "(" .. rhs .. ")"
		end

		-- Concatenation needs protection between number literals
		-- and the ".." token.
		if kind == AstKind.StrCatExpression then
			if self.numberCharsLookup[lhs:sub(-1)] then
				lhs = lhs .. " "
			end
		end

		-- Unary minus on the RHS of subtraction needs parentheses.
		if kind == AstKind.SubExpression
			and rhs:sub(1, 1) == "-" then
			rhs = "(" .. rhs .. ")"
		end

		return lhs
			.. self:optionalWhitespace()
			.. operator
			.. self:optionalWhitespace()
			.. rhs
	end

	-- NOT
	if kind == AstKind.NotExpression then
		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		if kindToNumber(expression.rhs.kind) >= kindToNumber(kind) then
			rhs = "(" .. rhs .. ")"
		end

		return "not"
			.. self:whitespaceIfNeeded(rhs)
			.. rhs
	end

	-- NEGATE
	if kind == AstKind.NegateExpression then
		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		if kindToNumber(expression.rhs.kind) >= kindToNumber(kind) then
			rhs = "(" .. rhs .. ")"
		end

		if rhs:sub(1, 1) == "-" then
			rhs = "(" .. rhs .. ")"
		end

		return "-" .. rhs
	end

	-- LENGTH
	if kind == AstKind.LenExpression then
		local rhs =
			self:unparseExpression(expression.rhs, tabbing)

		if kindToNumber(expression.rhs.kind) >= kindToNumber(kind) then
			rhs = "(" .. rhs .. ")"
		end

		return "#" .. rhs
	end

	-- INDEX
	if kind == AstKind.IndexExpression
		or kind == AstKind.AssignmentIndexing then

		local base =
			self:unparseExpression(expression.base, tabbing)

		if expression.base.kind == AstKind.VarargExpression
			or kindToNumber(expression.base.kind)
				> kindToNumber(AstKind.IndexExpression) then
			base = "(" .. base .. ")"
		end

		local index = expression.index

		if index.kind == AstKind.StringExpression
			and self:isValidIdentifier(index.value) then
			return base .. "." .. index.value
		end

		return base
			.. "["
			.. self:unparseExpression(index, tabbing)
			.. "]"
	end

	-- FUNCTION CALL
	if kind == AstKind.FunctionCallExpression then
		local base = expression.base

		if base.kind == AstKind.IndexExpression
			or base.kind == AstKind.VariableExpression then
			code = self:unparseExpression(base, tabbing)
		else
			code =
				"("
				.. self:unparseExpression(base, tabbing)
				.. ")"
		end

		return code
			.. "("
			.. joinExpressions(self, expression.args, tabbing, ",")
			.. ")"
	end

	-- SELF FUNCTION CALL
	if kind == AstKind.PassSelfFunctionCallExpression then
		local base = expression.base

		if base.kind == AstKind.IndexExpression
			or base.kind == AstKind.VariableExpression then
			code = self:unparseExpression(base, tabbing)
		else
			code =
				"("
				.. self:unparseExpression(base, tabbing)
				.. ")"
		end

		return code
			.. ":"
			.. expression.passSelfFunctionName
			.. "("
			.. joinExpressions(self, expression.args, tabbing, ",")
			.. ")"
	end

	-- FUNCTION LITERAL
	if kind == AstKind.FunctionLiteralExpression then
		local args = {}

		for i = 1, #expression.args do
			local arg = expression.args[i]

			if arg.kind == AstKind.VarargExpression then
				args[i] = "..."
			else
				args[i] =
					arg.scope:getVariableName(arg.id)
			end
		end

		local bodyCode =
			self:unparseBlock(expression.body, tabbing)

		return "function("
			.. table.concat(args, "," .. self:optionalWhitespace())
			.. ")"
			.. self:newline(false)
			.. bodyCode
			.. self:newline(false)
			.. self:whitespaceIfNeeded2(
				bodyCode,
				self:tabs(tabbing, true)
			)
			.. "end"
	end

	-- TABLE CONSTRUCTOR
	if kind == AstKind.TableConstructorExpression then
		local entries = expression.entries
		local entryCount = #entries

		if entryCount == 0 then
			return "{}"
		end

		local inlineTable = entryCount <= 3
		local tableTabbing = tabbing + 1

		local parts = {
			"{"
		}

		if inlineTable then
			parts[#parts + 1] =
				self:optionalWhitespace()
		else
			parts[#parts + 1] =
				self:optionalWhitespace(
					self:newline()
					.. self:tabs(tableTabbing)
				)
		end

		for i = 1, entryCount do
			local entry = entries[i]

			if i > 1 then
				local separator =
					self.prettyPrint
					and ","
					or randomTableSeparator()

				parts[#parts + 1] = separator

				if inlineTable then
					parts[#parts + 1] =
						self:optionalWhitespace()
				else
					parts[#parts + 1] =
						self:optionalWhitespace(
							self:newline()
							.. self:tabs(tableTabbing)
						)
				end
			end

			if entry.kind == AstKind.KeyedTableEntry then
				local key = entry.key

				if key.kind == AstKind.StringExpression
					and self:isValidIdentifier(key.value) then

					parts[#parts + 1] = key.value
				else
					parts[#parts + 1] = "["
					parts[#parts + 1] =
						self:unparseExpression(
							key,
							tableTabbing
						)
					parts[#parts + 1] = "]"
				end

				parts[#parts + 1] =
					self:optionalWhitespace()

				parts[#parts + 1] = "="

				parts[#parts + 1] =
					self:optionalWhitespace()

				parts[#parts + 1] =
					self:unparseExpression(
						entry.value,
						tableTabbing
					)
			else
				parts[#parts + 1] =
					self:unparseExpression(
						entry.value,
						tableTabbing
					)
			end
		end

		if inlineTable then
			parts[#parts + 1] =
				self:optionalWhitespace()

			parts[#parts + 1] = "}"

			return table.concat(parts)
		end

		parts[#parts + 1] =
			self:optionalWhitespace(
				","
				.. self:newline()
				.. self:tabs(tabbing)
			)

		parts[#parts + 1] = "}"

		return table.concat(parts)
	end

	-- LUAU IF/ELSE EXPRESSION
	if self.luaVersion == LuaVersion.LuaU
		and kind == AstKind.IfElseExpression then

		return "if "
			.. self:unparseExpression(
				expression.condition
			)
			.. " then "
			.. self:unparseExpression(
				expression.true_value
			)
			.. " else "
			.. self:unparseExpression(
				expression.false_value
			)
	end

	logger:error(
		string.format(
			"\"%s\" is not a valid unparseable expression",
			kind
		)
	)
end

return Unparser