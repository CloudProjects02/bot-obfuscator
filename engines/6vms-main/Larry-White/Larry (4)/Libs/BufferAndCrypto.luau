local StringUtil = require("../Utils/String")

local BufferAndCrypto = {}

local Serde = nil
pcall(function()
	Serde = require("@lune/serde")
end)

local function ResolveBufferLib()
	local LuneBuffer = nil
	pcall(function()
		LuneBuffer = require("@lune/buffer") or buffer
	end)

	if not LuneBuffer then
		LuneBuffer = buffer
	end

	return LuneBuffer
end

local function UnwrapInput(Value)
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if Raw ~= nil then
			return Raw
		end
	end

	return Value
end

local function NormalizeBase64Input(Data, ErrorName)
	local Value = UnwrapInput(Data)
	if typeof(Value) == "string" then
		return Value, "string"
	end

	local BufferLib = ResolveBufferLib()
	if BufferLib and typeof(BufferLib.tostring) == "function" then
		local Ok, Result = pcall(BufferLib.tostring, Value)
		if Ok and typeof(Result) == "string" then
			return Result, "buffer"
		end
	end

	error(`{ErrorName or "Base64"}: invalid argument #1 (string expected)`, 0)
end

local function EncodeBase64String(Data)
	if Serde then
		local Ok, Result = pcall(Serde.encode, "base64", Data)
		if Ok then return Result end
	end

	local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local Result = {}
	local Pad = #Data % 3

	for I = 1, #Data, 3 do
		local B1 = string.byte(Data, I)
		local B2 = string.byte(Data, I + 1) or 0
		local B3 = string.byte(Data, I + 2) or 0

		local N = B1 * 65536 + B2 * 256 + B3

		table.insert(Result, string.sub(Alphabet, math.floor(N / 262144) % 64 + 1, math.floor(N / 262144) % 64 + 1))
		table.insert(Result, string.sub(Alphabet, math.floor(N / 4096) % 64 + 1, math.floor(N / 4096) % 64 + 1))

		if I + 1 <= #Data then
			table.insert(Result, string.sub(Alphabet, math.floor(N / 64) % 64 + 1, math.floor(N / 64) % 64 + 1))
		end

		if I + 2 <= #Data then
			table.insert(Result, string.sub(Alphabet, N % 64 + 1, N % 64 + 1))
		end
	end

	if Pad == 1 then
		table.insert(Result, "==")
	elseif Pad == 2 then
		table.insert(Result, "=")
	end

	return table.concat(Result)
end

local function DecodeBase64String(Data)
	if Serde then
		local Ok, Result = pcall(Serde.decode, "base64", Data)
		if Ok then return Result end
	end

	local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local Lookup = {}
	for I = 1, 64 do
		Lookup[string.sub(Alphabet, I, I)] = I - 1
	end

	Data = string.gsub(Data, "=", "")
	local Result = {}

	for I = 1, #Data, 4 do
		local A = Lookup[string.sub(Data, I, I)] or 0
		local B = Lookup[string.sub(Data, I + 1, I + 1)] or 0
		local C = Lookup[string.sub(Data, I + 2, I + 2)] or 0
		local D = Lookup[string.sub(Data, I + 3, I + 3)] or 0

		local N = A * 262144 + B * 4096 + C * 64 + D

		table.insert(Result, string.char(math.floor(N / 65536) % 256))

		if I + 2 <= #Data then
			table.insert(Result, string.char(math.floor(N / 256) % 256))
		end

		if I + 3 <= #Data then
			table.insert(Result, string.char(N % 256))
		end
	end

	return table.concat(Result)
end

local function ReturnLikeInput(Kind, Text)
	if Kind ~= "buffer" then
		return Text
	end

	local BufferLib = ResolveBufferLib()
	if BufferLib and typeof(BufferLib.fromstring) == "function" then
		local Ok, Result = pcall(BufferLib.fromstring, Text)
		if Ok then
			return Result
		end
	end

	return Text
end

function BufferAndCrypto.Base64EncodeValue(Data, ErrorName)
	local Text, Kind = NormalizeBase64Input(Data, ErrorName or "Base64Encode")
	return EncodeBase64String(Text)
end

function BufferAndCrypto.Base64DecodeValue(Data, ErrorName)
	local Text, Kind = NormalizeBase64Input(Data, ErrorName or "Base64Decode")
	local Decoded = DecodeBase64String(Text)
	return BufferAndCrypto.StringToBuffer(Decoded, ErrorName or "Base64Decode")
end

local MAX_DECOMPRESSED = 1024 * 1024 * 1024
local ZSTD_MAGIC = "LZST"
local ZSTD_VERSION = 1

local function EncodeU32LE(Value)
	local B1 = Value % 256
	local B2 = math.floor(Value / 256) % 256
	local B3 = math.floor(Value / 65536) % 256
	local B4 = math.floor(Value / 16777216) % 256
	return string.char(B1, B2, B3, B4)
end

local function DecodeU32LE(Data, Index)
	local B1 = string.byte(Data, Index) or 0
	local B2 = string.byte(Data, Index + 1) or 0
	local B3 = string.byte(Data, Index + 2) or 0
	local B4 = string.byte(Data, Index + 3) or 0
	return B1 + B2 * 256 + B3 * 65536 + B4 * 16777216
end

local function NormalizeEnumValue(Value)
	if typeof(Value) == "table" then
		local Tag = rawget(Value, "__larryType")
		if Tag == "EnumItem" then
			local EnumType = rawget(Value, "_EnumType") or rawget(Value, "EnumType")
			local Name = rawget(Value, "_Name") or rawget(Value, "Name")
			if typeof(Name) == "string" then
				return string.lower(Name), EnumType
			end
		end
	elseif typeof(Value) == "string" then
		local EnumType, Name = string.match(Value, "^Enum%.([%w_]+)%.([%w_]+)$")
		if EnumType and Name then
			return string.lower(Name), EnumType
		end
		return string.lower(Value), nil
	end
	return nil, nil
end

function BufferAndCrypto.ResolveCompressionAlgorithm(Alg)
	if typeof(Alg) == "number" then
		if math.floor(Alg) == 0 then
			return "Zstd"
		end
		return nil
	end

	local NameLower, EnumType = NormalizeEnumValue(Alg)
	if EnumType ~= nil and string.lower(EnumType) ~= "compressionalgorithm" then
		return nil
	end
	if NameLower == "zstd" then
		return "Zstd"
	end
	return nil
end

function BufferAndCrypto.ResolveHashAlgorithm(Alg)
	if typeof(Alg) == "number" then
		local Map = {
			[0] = "Blake2b",
			[1] = "Blake3",
			[2] = "Md5",
			[3] = "Sha1",
			[4] = "Sha256",
		}
		return Map[math.floor(Alg)]
	end

	local NameLower, EnumType = NormalizeEnumValue(Alg)
	if EnumType ~= nil and string.lower(EnumType) ~= "hashalgorithm" then
		return nil
	end
	if NameLower == "blake2b" then return "Blake2b" end
	if NameLower == "blake3" then return "Blake3" end
	if NameLower == "md5" then return "Md5" end
	if NameLower == "sha1" then return "Sha1" end
	if NameLower == "sha256" then return "Sha256" end
	return nil
end

local function SeedFromName(Name)
	local Seed = 2166136261
	for I = 1, #Name do
		local Byte = string.byte(Name, I)
		Seed = bit32.bxor(Seed, Byte)
		Seed = (Seed * 16777619) % 4294967296
	end
	return Seed
end

local function PseudoHashBytes(Data, Length, Seed)
	local Hash = Seed
	for I = 1, #Data do
		local Byte = string.byte(Data, I)
		Hash = bit32.bxor(Hash, Byte)
		Hash = (Hash * 16777619) % 4294967296
	end

	local Out = table.create(Length)
	for I = 1, Length do
		Hash = bit32.bxor(Hash, I)
		Hash = (Hash * 16777619) % 4294967296
		local Shift = ((I - 1) % 4) * 8
		local Byte = bit32.band(bit32.rshift(Hash, Shift), 0xFF)
		Out[I] = string.char(Byte)
	end
	return table.concat(Out)
end

local function RleEncode(Data)
	local Out = {}
	local I = 1
	local Len = #Data
	while I <= Len do
		local Byte = string.byte(Data, I)
		local Run = 1
		while I + Run <= Len and Run < 255 and string.byte(Data, I + Run) == Byte do
			Run += 1
		end
		table.insert(Out, string.char(Run, Byte))
		I += Run
	end
	return table.concat(Out)
end

local function RleDecode(Data)
	if (#Data % 2) ~= 0 then
		return nil
	end
	local Out = {}
	for I = 1, #Data, 2 do
		local Run = string.byte(Data, I) or 0
		local Byte = string.byte(Data, I + 1) or 0
		if Run <= 0 then
			return nil
		end
		Out[#Out + 1] = string.rep(string.char(Byte), Run)
	end
	return table.concat(Out)
end

function BufferAndCrypto.TryBufferToString(Value)
	if typeof(Value) == "string" then
		return nil
	end
	local BufferLib = ResolveBufferLib()
	if BufferLib and typeof(BufferLib.tostring) == "function" then
		local Ok, Result = pcall(BufferLib.tostring, Value)
		if Ok and typeof(Result) == "string" then
			return Result
		end
	end
	return nil
end

function BufferAndCrypto.RequireBufferToString(Value, ErrorName, ArgIndex)
	local Result = BufferAndCrypto.TryBufferToString(Value)
	if Result ~= nil then
		return Result
	end
	local Name = ErrorName or "buffer"
	local Index = ArgIndex or 1
	error(`invalid argument #{Index} to '{Name}' (buffer expected)`, 0)
end

function BufferAndCrypto.StringToBuffer(Text, ErrorName)
	local BufferLib = ResolveBufferLib()
	if BufferLib and typeof(BufferLib.fromstring) == "function" then
		local Ok, Result = pcall(BufferLib.fromstring, Text)
		if Ok then
			return Result
		end
	end
	local Name = ErrorName or "buffer"
	error(`failed to build buffer in '{Name}'`, 0)
end

function BufferAndCrypto.Base64EncodeBuffer(Input)
	local Text = BufferAndCrypto.RequireBufferToString(Input, "Base64Encode", 1)
	local Encoded = EncodeBase64String(Text)
	return BufferAndCrypto.StringToBuffer(Encoded, "Base64Encode")
end

function BufferAndCrypto.Base64DecodeBuffer(Input)
	local Text = BufferAndCrypto.RequireBufferToString(Input, "Base64Decode", 1)
	local Decoded = DecodeBase64String(Text)
	return BufferAndCrypto.StringToBuffer(Decoded, "Base64Decode")
end

function BufferAndCrypto.CompressZstdString(Input, CompressionLevel)
	local Level = CompressionLevel
	if Level == nil then
		Level = 1
	end
	if typeof(Level) ~= "number" then
		error("compressionLevel must be a number", 0)
	end

	if Serde then
		local Ok, Result = pcall(Serde.compress, "zstd", Input, Level)
		if Ok and typeof(Result) == "string" then
			return Result
		end
	end

	local Size = #Input
	if Size > MAX_DECOMPRESSED then
		error("compressed buffer exceeds maximum size", 0)
	end

	local Flags = 0
	local Payload = Input
	if Level > 0 then
		local Rle = RleEncode(Input)
		if #Rle < #Input then
			Payload = Rle
			Flags = 1
		end
	end

	local Header = ZSTD_MAGIC .. string.char(ZSTD_VERSION, Flags) .. EncodeU32LE(Size)
	return Header .. Payload
end

function BufferAndCrypto.GetZstdDecompressedSizeString(Input)
	if #Input < 10 then
		if not Serde then
			return nil
		end
	else
		if string.sub(Input, 1, 4) == ZSTD_MAGIC then
			local Version = string.byte(Input, 5) or 0
			if Version == ZSTD_VERSION then
				local Size = DecodeU32LE(Input, 7)
				if Size > MAX_DECOMPRESSED then
					return nil
				end
				return Size
			end
		end
	end

	if Serde then
		local Ok, Result = pcall(Serde.decompress, "zstd", Input)
		if Ok and typeof(Result) == "string" then
			if #Result > MAX_DECOMPRESSED then
				return nil
			end
			return #Result
		end
	end

	return nil
end

function BufferAndCrypto.DecompressZstdString(Input)
	if #Input >= 4 and string.sub(Input, 1, 4) == ZSTD_MAGIC then
		if #Input >= 10 then
			local Version = string.byte(Input, 5) or 0
			if Version == ZSTD_VERSION then
				local Flags = string.byte(Input, 6) or 0
				local Size = DecodeU32LE(Input, 7)
				if Size > MAX_DECOMPRESSED then
					error("invalid compressed buffer", 0)
				end

				local Payload = string.sub(Input, 11)
				local Out = Payload
				if bit32.band(Flags, 1) == 1 then
					local Decoded = RleDecode(Payload)
					if Decoded == nil then
						error("invalid compressed buffer", 0)
					end
					Out = Decoded
				end

				if #Out ~= Size then
					error("invalid compressed buffer", 0)
				end

				return Out
			end
		end
	end

	if Serde then
		local Ok, Result = pcall(Serde.decompress, "zstd", Input)
		if Ok and typeof(Result) == "string" then
			if #Result > MAX_DECOMPRESSED then
				error("invalid compressed buffer", 0)
			end
			return Result
		end
	end

	error("invalid compressed buffer", 0)
end

function BufferAndCrypto.ComputeHashString(Input, AlgName)
	local Sizes = {
		Blake2b = 64,
		Blake3 = 32,
		Md5 = 16,
		Sha1 = 20,
		Sha256 = 32,
	}
	local Length = Sizes[AlgName]
	if Length == nil then
		return nil
	end
	local Seed = SeedFromName(AlgName)
	return PseudoHashBytes(Input, Length, Seed)
end

function BufferAndCrypto.BuildBuffer(Proxy, State, Emitter, Beautifier, Scope)
	local LuneBuffer = ResolveBufferLib()

	local Lib = {}
	local function SpyReturn(Method, ...)
		local Value = `buffer.{Method}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:AddVar("buf", Method, Value, "__call")
		return Proxy:Spy(Var)
	end

	local Methods = {
		"create", "fromstring", "tostring", "len",
		"readi8", "readu8", "readi16", "readu16",
		"readi32", "readu32", "readf32", "readf64",
		"writei8", "writeu8", "writei16", "writeu16",
		"writei32", "writeu32", "writef32", "writef64",
		"readstring", "writestring", "copy", "fill",
	}

	for _, Method in Methods do
		Lib[Method] = function(...)
			local Args = table.pack(...)
			local HasInternal = false
			for I = 1, Args.n do
				if State:IsInternal(Args[I]) then
					HasInternal = true
					break
				end
			end

			if not LuneBuffer then
				return SpyReturn(Method, ...)
			end

			local Native = LuneBuffer[Method]
			if typeof(Native) ~= "function" then
				return SpyReturn(Method, ...)
			end

			local Ok, Packed = pcall(function(...)
				return table.pack(Native(...))
			end, ...)

			if not Ok then
				if HasInternal then
					return SpyReturn(Method, ...)
				end
				error(Packed, 0)
			end

			return table.unpack(Packed, 1, Packed.n)
		end
	end

	State:RegisterInternal(Lib, "buffer")

	return Lib
end

function BufferAndCrypto.BuildCrypto(Proxy, State, Emitter, Beautifier, Scope)
	local function SpyReturn(Path, ...)
		local Value = `{Path}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:GenerateName("crypto", "call")
		return Proxy:MultiSpy(Var, Value, 2)
	end

	local function Base64Encode(Data)
		if State:IsInternal(Data) then
			return SpyReturn("base64encode", Data)
		end

		return BufferAndCrypto.Base64EncodeValue(Data)
	end

	local function Base64Decode(Data)
		if State:IsInternal(Data) then
			return SpyReturn("base64decode", Data)
		end

		return BufferAndCrypto.Base64DecodeValue(Data)
	end

	local Crypt = {
		base64 = {
			encode = Base64Encode,
			decode = Base64Decode,
		},
		base64encode = Base64Encode,
		base64decode = Base64Decode,
		encode = Base64Encode,
		decode = Base64Decode,
	}

	local CryptMeta = setmetatable(Crypt, {
		__index = function(_, Key)
			return SpyReturn(`crypt.{Key}`)
		end,
		__tostring = function()
			return "crypt"
		end,
	})

	State:RegisterInternal(CryptMeta, "crypt")

	return CryptMeta, Base64Encode, Base64Decode
end

function BufferAndCrypto.BuildHTTPTable(Proxy, State, Emitter, Beautifier, Scope, RequestFunc)
	local Http = {
		request = RequestFunc or function(Options)
			local Value = `http.request({Beautifier:Beautify(Options)})`
			local Var = Scope:AddVar("httpResp", "req", Value, "__call")
			return Proxy:Spy(Var)
		end,
	}

	local Meta = setmetatable(Http, {
		__tostring = function()
			return "http"
		end,
		__index = function(_, Key)
			return Proxy:Spy(StringUtil.Index(Key, "http"))
		end,
	})

	State:RegisterInternal(Meta, "http")
	return Meta
end

function BufferAndCrypto.BuildLz4(Proxy, State, Emitter, Beautifier, Scope)
	local function SpyReturn(Name, ...)
		local Value = `{Name}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:GenerateName("lz4", "call")
		return Proxy:MultiSpy(Var, Value, 2)
	end

	return {
		lz4compress = function(Data)
			if State:IsInternal(Data) then
				return SpyReturn("lz4compress", Data)
			end
			if typeof(Data) ~= "string" then
				return Data
			end
			if Serde then
				local Ok, Result = pcall(Serde.compress, "lz4", Data)
				if Ok and typeof(Result) == "string" then
					return Result
				end
			end
			return Data
		end,
		lz4decompress = function(Data, Size)
			if State:IsInternal(Data) then
				return SpyReturn("lz4decompress", Data, Size)
			end
			if typeof(Data) ~= "string" then
				return Data
			end
			if Serde then
				local Ok, Result = pcall(Serde.decompress, "lz4", Data)
				if Ok and typeof(Result) == "string" then
					return Result
				end
			end
			return Data
		end,
	}
end

return BufferAndCrypto