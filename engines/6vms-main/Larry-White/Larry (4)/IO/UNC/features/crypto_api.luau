local IdentityUtil = require("../../../Utils/Identity")

local CryptoApi = {}

function CryptoApi.Build(Ctx, Proxy, State, Emitter, Beautifier, Scope)
	local BufferAndCrypto = require("../../../Libs/BufferAndCrypto")
	local CryptLibMeta, Base64Enc, Base64Dec = BufferAndCrypto.BuildCrypto(Proxy, State, Emitter, Beautifier, Scope)

	local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

	local function b64encode(data)
		if typeof(data) ~= "string" then return "" end
		local result = {}
		local len = #data
		for i = 1, len, 3 do
			local a = string.byte(data, i)
			local b = i + 1 <= len and string.byte(data, i + 1) or 0
			local c = i + 2 <= len and string.byte(data, i + 2) or 0
			local n = a * 65536 + b * 256 + c
			table.insert(result, string.sub(b64chars, math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1))
			table.insert(result, string.sub(b64chars, math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
			if i + 1 <= len then
				table.insert(result, string.sub(b64chars, math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1))
			else
				table.insert(result, "=")
			end
			if i + 2 <= len then
				table.insert(result, string.sub(b64chars, n % 64 + 1, n % 64 + 1))
			else
				table.insert(result, "=")
			end
		end
		return table.concat(result)
	end

	local function b64decode(data)
		if typeof(data) ~= "string" then return "" end
		local b64lookup = {}
		for i = 1, 64 do
			b64lookup[string.sub(b64chars, i, i)] = i - 1
		end
		data = string.gsub(data, "[^%w%+%/=]", "")
		local result = {}
		for i = 1, #data, 4 do
			local a = b64lookup[string.sub(data, i, i)] or 0
			local b = b64lookup[string.sub(data, i + 1, i + 1)] or 0
			local c = b64lookup[string.sub(data, i + 2, i + 2)] or 0
			local d = b64lookup[string.sub(data, i + 3, i + 3)] or 0
			local nn = a * 262144 + b * 4096 + c * 64 + d
			table.insert(result, string.char(math.floor(nn / 65536) % 256))
			if string.sub(data, i + 2, i + 2) ~= "=" then
				table.insert(result, string.char(math.floor(nn / 256) % 256))
			end
			if string.sub(data, i + 3, i + 3) ~= "=" then
				table.insert(result, string.char(nn % 256))
			end
		end
		return table.concat(result)
	end

	local CryptLib = {
		base64encode = b64encode,
		base64decode = b64decode,
		base64_encode = b64encode,
		base64_decode = b64decode,
		base64 = {
			encode = b64encode,
			decode = b64decode,
		},
		encrypt = function(Data, Key, Iv, Mode)
			if typeof(Data) ~= "string" then error("invalid argument #1 to 'encrypt' (string expected)") end
			if typeof(Key) ~= "string" then error("invalid argument #2 to 'encrypt' (string expected)") end
			local derivedIv = Iv or string.rep("\0", 16)
			local keyBytes = {}
			for i = 1, #Key do
				keyBytes[i] = string.byte(Key, i)
			end
			local ivBytes = {}
			for i = 1, #derivedIv do
				ivBytes[i] = string.byte(derivedIv, i)
			end
			local encrypted = {}
			for i = 1, #Data do
				local dataByte = string.byte(Data, i)
				local keyByte = keyBytes[((i - 1) % #keyBytes) + 1]
				local ivByte = ivBytes[((i - 1) % #ivBytes) + 1]
				local enc = bit32.bxor(bit32.bxor(dataByte, keyByte), ivByte)
				table.insert(encrypted, string.char(enc))
			end
			return b64encode(table.concat(encrypted)), derivedIv
		end,
		decrypt = function(Data, Key, Iv, Mode)
			if typeof(Data) ~= "string" then error("invalid argument #1 to 'decrypt' (string expected)") end
			if typeof(Key) ~= "string" then error("invalid argument #2 to 'decrypt' (string expected)") end
			local derivedIv = Iv or string.rep("\0", 16)
			local decoded = b64decode(Data)
			local keyBytes = {}
			for i = 1, #Key do
				keyBytes[i] = string.byte(Key, i)
			end
			local ivBytes = {}
			for i = 1, #derivedIv do
				ivBytes[i] = string.byte(derivedIv, i)
			end
			local decrypted = {}
			for i = 1, #decoded do
				local dataByte = string.byte(decoded, i)
				local keyByte = keyBytes[((i - 1) % #keyBytes) + 1]
				local ivByte = ivBytes[((i - 1) % #ivBytes) + 1]
				local dec = bit32.bxor(bit32.bxor(dataByte, keyByte), ivByte)
				table.insert(decrypted, string.char(dec))
			end
			return table.concat(decrypted)
		end,
		hash = function(Data, Alg)
			if typeof(Data) ~= "string" then error("invalid argument #1 to 'hash' (string expected)") end
			local len = 32
			if Alg then
				local algLower = string.lower(tostring(Alg))
				if algLower == "sha256" then len = 64
				elseif algLower == "sha384" then len = 96
				elseif algLower == "sha512" then len = 128
				elseif algLower == "sha1" then len = 40
				elseif algLower == "md5" then len = 32
				end
			end
			return IdentityUtil.Generate(len)
		end,
		generatekey = function()
			local raw = {}
			for i = 1, 32 do
				raw[i] = string.char(math.random(0, 255))
			end
			return b64encode(table.concat(raw))
		end,
		generatebytes = function(Count)
			if typeof(Count) ~= "number" then Count = 16 end
			local bytes = {}
			for i = 1, Count do
				bytes[i] = string.char(math.random(0, 255))
			end
			return b64encode(table.concat(bytes))
		end,
	}

	return CryptLib
end

return CryptoApi