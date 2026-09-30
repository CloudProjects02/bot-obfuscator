local Char = string.char
local Format = string.format
local Match = string.match
local Concat = table.concat
local Create = table.create
local Random = math.random

local Identity = {}

local Alphabet = Create(62)
local Idx = 0

for Code = 97, 122 do Idx += 1; Alphabet[Idx] = Char(Code) end
for Code = 65, 90 do Idx += 1; Alphabet[Idx] = Char(Code) end
for Code = 48, 57 do Idx += 1; Alphabet[Idx] = Char(Code) end

Identity.Alphabet = Alphabet

function Identity.Generate(Length, LettersOnly)
	Length = Length or 6
	local Max = LettersOnly and 52 or 62
	local Parts = Create(Length)
	for I = 1, Length do
		Parts[I] = Alphabet[Random(1, Max)]
	end
	return Concat(Parts)
end

function Identity.Address(Path, Type, Cache)
	local Existing = Cache[Path]
	if Existing then return Existing end

	local Seed = Match(tostring(function() end), "0x([A-Fa-f0-9]+)") or "0"
	local Hash = 5381
	for I = 1, #Path do
		Hash = ((Hash * 33) + string.byte(Path, I) + I) % 4294967296
	end
	for I = 1, #Seed do
		Hash = ((Hash * 17) + string.byte(Seed, I) + I) % 4294967296
	end

	local Hex = string.lower(Format("%08X", Hash))
	local Prefix = (Type == "function" or Type == "table" or Type == "thread" or Type == "userdata")
		and Format("%s: ", Type)
		or ""
	local Result = Format("%s0x%s", Prefix, Hex)

	Cache[Path] = Result
	return Result
end

function Identity.Internal(Name)
	return `_{Identity.SessionPrefix}_{Name}`
end

Identity.TraceId = Identity.Generate(7)
Identity.SessionPrefix = Identity.Generate(10, true)

return Identity