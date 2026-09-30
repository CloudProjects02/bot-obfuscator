local Constants = {}

Constants.MoonSec = {
	InternalKeyLength = 15,
	ExcludeLengths = { 12, 13, 14 },
	AntiTamperExcludeLengths = { 13, 17, 32 },
	Signature = "This file was protected with MoonSec V3",
	AntiTamperMarker = "_ENV",
	ConstantProtectionMarker = "//",
}

Constants.Limits = {
	MaxOperations = 10500,
	MaxWhileCount = 100000,
	MaxTasks = 5,
	MaxLoads = 4,
	ParamBufferCount = 50,
	TabLimit = 20,
	TaskSpawnMaxOps = 1000,
	MaxStringDisplay = 1000,
	MaxStringDisplayKB = 1024,
}

Constants.Timeout = {
	Base = 60,
	MaxExtra = 40,
}

Constants.IgnoredUrls = {
	"rayfield",
	"sirius",
	"orionlib",
}

Constants.JunkPatterns = {
	RepeatedAssignment = "^%s*%[.-%]%s*=%s*['\"]",
	EmptyMetatable = "^%s*setmetatable%s*%(%s*{%s*}%s*,%s*{%s*}%s*%)",
}

Constants.Keywords = {
	"and", "break", "do", "else", "elseif", "end",
	"false", "for", "function", "if", "in",
	"local", "nil", "not", "or", "repeat",
	"return", "then", "true", "until", "while",
	"continue", "export", "type",
}

local KeywordSet = {}
for _, Kw in Constants.Keywords do
	KeywordSet[Kw] = true
end

function Constants.IsKeyword(Word)
	return KeywordSet[Word] == true
end

Constants.IterFunctions = { "pairs", "ipairs" }
Constants.PassthroughFunctions = { "newproxy", "select", "setmetatable", "assert", "rawget", "rawset", "rawequal", "rawlen", "xpcall", "unpack", "ypcall", "error", "spawn", "getmetatable", "pcall" }
Constants.WrappedFunctions = { "tonumber", "collectgarbage", "tostring", "pcall" }
Constants.PassthroughTables = { "os", "debug", "bit32", "package", "math", "string", "table", "coroutine" }

Constants.Executor = {
	Name = "Potassium",
	Version = "1.2.5",
}

Constants.HwidLength = 32
Constants.UserIdRange = { 100000, 9999999 }

return Constants