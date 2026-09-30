-- Lurape v17.7
-- lrpe_crypto.lua
--
-- Build-side LRPE cryptography.
--
-- Primitive:
--   ChaCha20-Poly1305
--
-- KDF:
--   HKDF-style HMAC-SHA256
--
-- Runtime:
--   The generated LRPE VM must provide the matching
--   LRPE_DECRYPT(ciphertext, nonce, aad, tag, seed, id)
--
-- LuaJIT 5.1 compatible.

local ffi = require("ffi")
local bit = require("bit")

local bxor = bit.bxor

local Crypto = {}
Crypto.__index = Crypto

ffi.cdef[[
typedef struct evp_md_st EVP_MD;
typedef struct evp_md_ctx_st EVP_MD_CTX;
typedef struct evp_cipher_st EVP_CIPHER;
typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
typedef struct engine_st ENGINE;

const EVP_MD *EVP_sha256(void);

EVP_MD_CTX *EVP_MD_CTX_new(void);
void EVP_MD_CTX_free(EVP_MD_CTX *ctx);

int EVP_DigestInit_ex(
    EVP_MD_CTX *ctx,
    const EVP_MD *type,
    ENGINE *impl
);

int EVP_DigestUpdate(
    EVP_MD_CTX *ctx,
    const void *d,
    size_t cnt
);

int EVP_DigestFinal_ex(
    EVP_MD_CTX *ctx,
    unsigned char *md,
    unsigned int *s
);

EVP_CIPHER_CTX *EVP_CIPHER_CTX_new(void);
void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *ctx);

const EVP_CIPHER *EVP_chacha20_poly1305(void);

int EVP_EncryptInit_ex(
    EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *type,
    ENGINE *impl,
    const unsigned char *key,
    const unsigned char *iv
);

int EVP_EncryptUpdate(
    EVP_CIPHER_CTX *ctx,
    unsigned char *out,
    int *outl,
    const unsigned char *in,
    int inl
);

int EVP_EncryptFinal_ex(
    EVP_CIPHER_CTX *ctx,
    unsigned char *out,
    int *outl
);

int EVP_DecryptInit_ex(
    EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *type,
    ENGINE *impl,
    const unsigned char *key,
    const unsigned char *iv
);

int EVP_DecryptUpdate(
    EVP_CIPHER_CTX *ctx,
    unsigned char *out,
    int *outl,
    const unsigned char *in,
    int inl
);

int EVP_DecryptFinal_ex(
    EVP_CIPHER_CTX *ctx,
    unsigned char *out,
    int *outl
);

int EVP_CIPHER_CTX_ctrl(
    EVP_CIPHER_CTX *ctx,
    int type,
    int arg,
    void *ptr
);

unsigned int EVP_CIPHER_key_length(
    const EVP_CIPHER *cipher
);

unsigned int EVP_CIPHER_iv_length(
    const EVP_CIPHER *cipher
);
]]

local function loadCryptoLibrary()
    local names = {
        "libcrypto-3-x64.dll",
        "libcrypto-3.dll",
        "crypto-3-x64.dll",
        "libcrypto-3",
        "libcrypto.so.3",
        "libcrypto.so.1.1",
        "libcrypto.so",
    }

    local errors = {}

    for _, name in ipairs(names) do
        local ok, handle = pcall(ffi.load, name)

        if ok and handle then
            return handle
        end

        errors[#errors + 1] = name
    end

    error(
        "LRPE crypto: OpenSSL/libcrypto could not be loaded. "
        .. "Tried: "
        .. table.concat(errors, ", ")
    )
end

local C = loadCryptoLibrary()

local EVP_CTRL_AEAD_GET_TAG = 0x10
local EVP_CTRL_AEAD_SET_TAG = 0x11

local function check(value, message)
    if value ~= 1 then
        error(
            "LRPE crypto: "
            .. message
        )
    end
end

local function sha256(data)
    if type(data) ~= "string" then
        error(
            "LRPE crypto: sha256 input must be a string"
        )
    end

    local output =
        ffi.new("unsigned char[32]")

    local outputLength =
        ffi.new("unsigned int[1]")

    local ctx =
        C.EVP_MD_CTX_new()

    if ctx == nil then
        error(
            "LRPE crypto: EVP_MD_CTX_new failed"
        )
    end

    local ok, result =
        pcall(function()
            check(
                C.EVP_DigestInit_ex(
                    ctx,
                    C.EVP_sha256(),
                    nil
                ),
                "EVP_DigestInit_ex failed"
            )

            if #data > 0 then
                check(
                    C.EVP_DigestUpdate(
                        ctx,
                        data,
                        #data
                    ),
                    "EVP_DigestUpdate failed"
                )
            end

            check(
                C.EVP_DigestFinal_ex(
                    ctx,
                    output,
                    outputLength
                ),
                "EVP_DigestFinal_ex failed"
            )

            return ffi.string(
                output,
                outputLength[0]
            )
        end)

    C.EVP_MD_CTX_free(ctx)

    if not ok then
        error(result)
    end

    return result
end

local function hmacSha256(key, message)
    if type(key) ~= "string" then
        error(
            "LRPE crypto: HMAC key must be a string"
        )
    end

    if type(message) ~= "string" then
        error(
            "LRPE crypto: HMAC message must be a string"
        )
    end

    local blockSize = 64

    if #key > blockSize then
        key = sha256(key)
    end

    if #key < blockSize then
        key =
            key
            .. string.rep(
                "\0",
                blockSize - #key
            )
    end

    local innerPad = {}
    local outerPad = {}

    for i = 1, blockSize do
        local byteValue =
            string.byte(
                key,
                i
            )

        innerPad[i] =
            string.char(
                bxor(
                    byteValue,
                    0x36
                )
            )

        outerPad[i] =
            string.char(
                bxor(
                    byteValue,
                    0x5c
                )
            )
    end

    local inner =
        sha256(
            table.concat(innerPad)
            .. message
        )

    return sha256(
        table.concat(outerPad)
        .. inner
    )
end

local function hkdfExtract(
    salt,
    ikm
)
    if not salt or #salt == 0 then
        salt =
            string.rep(
                "\0",
                32
            )
    end

    return hmacSha256(
        salt,
        ikm
    )
end

local function hkdfExpand(
    prk,
    info,
    length
)
    if type(prk) ~= "string" then
        error(
            "LRPE crypto: HKDF PRK must be a string"
        )
    end

    if type(info) ~= "string" then
        error(
            "LRPE crypto: HKDF info must be a string"
        )
    end

    if type(length) ~= "number"
        or length < 0
        or length ~= math.floor(length)
    then
        error(
            "LRPE crypto: invalid HKDF output length"
        )
    end

    if length == 0 then
        return ""
    end

    if length > 255 * 32 then
        error(
            "LRPE crypto: HKDF output too large"
        )
    end

    local output = {}
    local previous = ""
    local counter = 1
    local generated = 0

    while generated < length do
        previous =
            hmacSha256(
                prk,
                previous
                .. info
                .. string.char(counter)
            )

        output[#output + 1] =
            previous

        generated =
            generated
            + #previous

        counter =
            counter + 1
    end

    return table.concat(output):sub(
        1,
        length
    )
end

local function u32le(value)
    value =
        value % 4294967296

    return string.char(
        value % 256,
        math.floor(value / 256) % 256,
        math.floor(value / 65536) % 256,
        math.floor(value / 16777216) % 256
    )
end

function Crypto.new(seed)
    if type(seed) ~= "number" then
        error(
            "LRPE crypto seed must be numeric"
        )
    end

    if seed ~= seed
        or seed == math.huge
        or seed == -math.huge
    then
        error(
            "LRPE crypto seed must be finite"
        )
    end

    seed =
        math.floor(seed)
        % 4294967296

    local self =
        setmetatable({
            seed = seed,
            masterKey = nil,
        }, Crypto)

    local seedBytes =
        u32le(seed)

    local salt =
        sha256(
            "LRPE-17.7-SALT"
            .. seedBytes
        )

    local extract =
        hkdfExtract(
            salt,
            "LRPE-17.7-MASTER"
            .. seedBytes
        )

    self.masterKey =
        hkdfExpand(
            extract,
            "LRPE-17.7-MASTER-KEY",
            32
        )

    return self
end

function Crypto:deriveKey(id)
    if type(id) ~= "number" then
        error(
            "LRPE crypto constant id must be numeric"
        )
    end

    local info =
        "LRPE-17.7-CONSTANT:"
        .. tostring(id)

    local prk =
        hkdfExtract(
            self.masterKey,
            info
        )

    return hkdfExpand(
        prk,
        "LRPE-17.7-CHACHA20-POLY1305",
        32
    )
end

function Crypto:deriveNonce(id)
    local keyMaterial =
        self:deriveKey(id)

    return sha256(
        "LRPE-17.7-NONCE"
        .. keyMaterial
        .. tostring(self.seed)
        .. ":"
        .. tostring(id)
    ):sub(1, 12)
end

function Crypto:encrypt(
    plaintext,
    key,
    nonce,
    aad
)
    if type(plaintext) ~= "string" then
        error(
            "LRPE crypto: plaintext must be a string"
        )
    end

    if type(key) ~= "string"
        or #key ~= 32
    then
        error(
            "LRPE crypto: ChaCha20 key must be 32 bytes"
        )
    end

    if type(nonce) ~= "string"
        or #nonce ~= 12
    then
        error(
            "LRPE crypto: ChaCha20-Poly1305 nonce must be 12 bytes"
        )
    end

    aad =
        aad or ""

    if type(aad) ~= "string" then
        error(
            "LRPE crypto: AAD must be a string"
        )
    end

    local cipher =
        C.EVP_chacha20_poly1305()

    if cipher == nil then
        error(
            "LRPE crypto: ChaCha20-Poly1305 unavailable"
        )
    end

    local ctx =
        C.EVP_CIPHER_CTX_new()

    if ctx == nil then
        error(
            "LRPE crypto: EVP_CIPHER_CTX_new failed"
        )
    end

    local ok, ciphertext, tag =
        pcall(function()
            check(
                C.EVP_EncryptInit_ex(
                    ctx,
                    cipher,
                    nil,
                    key,
                    nonce
                ),
                "EVP_EncryptInit_ex failed"
            )

            local aadLength =
                ffi.new("int[1]")

            if #aad > 0 then
                check(
                    C.EVP_EncryptUpdate(
                        ctx,
                        nil,
                        aadLength,
                        aad,
                        #aad
                    ),
                    "AAD processing failed"
                )
            end

            local output =
                ffi.new(
                    "unsigned char[?]",
                    #plaintext + 32
                )

            local written =
                ffi.new("int[1]")

            if #plaintext > 0 then
                check(
                    C.EVP_EncryptUpdate(
                        ctx,
                        output,
                        written,
                        plaintext,
                        #plaintext
                    ),
                    "EVP_EncryptUpdate failed"
                )
            else
                written[0] = 0
            end

            local finalWritten =
                ffi.new("int[1]")

            check(
                C.EVP_EncryptFinal_ex(
                    ctx,
                    output + written[0],
                    finalWritten
                ),
                "EVP_EncryptFinal_ex failed"
            )

            local ciphertextValue =
                ffi.string(
                    output,
                    written[0]
                    + finalWritten[0]
                )

            local tagBuffer =
                ffi.new(
                    "unsigned char[16]"
                )

            check(
                C.EVP_CIPHER_CTX_ctrl(
                    ctx,
                    EVP_CTRL_AEAD_GET_TAG,
                    16,
                    tagBuffer
                ),
                "EVP_CIPHER_CTX_ctrl(GET_TAG) failed"
            )

            local tagValue =
                ffi.string(
                    tagBuffer,
                    16
                )

            return ciphertextValue,
                tagValue
        end)

    C.EVP_CIPHER_CTX_free(ctx)

    if not ok then
        error(ciphertext)
    end

    if type(ciphertext) ~= "string"
        or type(tag) ~= "string"
    then
        error(
            "LRPE crypto: encryption returned invalid result"
        )
    end

    if #tag ~= 16 then
        error(
            "LRPE crypto: invalid Poly1305 tag length"
        )
    end

    return ciphertext, tag
end

function Crypto:decrypt(
    ciphertext,
    key,
    nonce,
    aad,
    tag
)
    if type(ciphertext) ~= "string" then
        error(
            "LRPE crypto: ciphertext must be a string"
        )
    end

    if type(key) ~= "string"
        or #key ~= 32
    then
        error(
            "LRPE crypto: ChaCha20 key must be 32 bytes"
        )
    end

    if type(nonce) ~= "string"
        or #nonce ~= 12
    then
        error(
            "LRPE crypto: ChaCha20-Poly1305 nonce must be 12 bytes"
        )
    end

    if type(tag) ~= "string"
        or #tag ~= 16
    then
        error(
            "LRPE crypto: Poly1305 tag must be 16 bytes"
        )
    end

    aad =
        aad or ""

    if type(aad) ~= "string" then
        error(
            "LRPE crypto: AAD must be a string"
        )
    end

    local cipher =
        C.EVP_chacha20_poly1305()

    if cipher == nil then
        error(
            "LRPE crypto: ChaCha20-Poly1305 unavailable"
        )
    end

    local ctx =
        C.EVP_CIPHER_CTX_new()

    if ctx == nil then
        error(
            "LRPE crypto: EVP_CIPHER_CTX_new failed"
        )
    end

    local ok, plaintext =
        pcall(function()
            check(
                C.EVP_DecryptInit_ex(
                    ctx,
                    cipher,
                    nil,
                    key,
                    nonce
                ),
                "EVP_DecryptInit_ex failed"
            )

            local aadLength =
                ffi.new("int[1]")

            if #aad > 0 then
                check(
                    C.EVP_DecryptUpdate(
                        ctx,
                        nil,
                        aadLength,
                        aad,
                        #aad
                    ),
                    "AAD processing failed"
                )
            end

            local output =
                ffi.new(
                    "unsigned char[?]",
                    #ciphertext + 32
                )

            local written =
                ffi.new("int[1]")

            if #ciphertext > 0 then
                check(
                    C.EVP_DecryptUpdate(
                        ctx,
                        output,
                        written,
                        ciphertext,
                        #ciphertext
                    ),
                    "EVP_DecryptUpdate failed"
                )
            else
                written[0] = 0
            end

            check(
                C.EVP_CIPHER_CTX_ctrl(
                    ctx,
                    EVP_CTRL_AEAD_SET_TAG,
                    16,
                    tag
                ),
                "EVP_CIPHER_CTX_ctrl(SET_TAG) failed"
            )

            local finalWritten =
                ffi.new("int[1]")

            local finalResult =
                C.EVP_DecryptFinal_ex(
                    ctx,
                    output + written[0],
                    finalWritten
                )

            if finalResult ~= 1 then
                error(
                    "LRPE crypto: authentication failed"
                )
            end

            return ffi.string(
                output,
                written[0]
                + finalWritten[0]
            )
        end)

    C.EVP_CIPHER_CTX_free(ctx)

    if not ok then
        error(plaintext)
    end

    if type(plaintext) ~= "string" then
        error(
            "LRPE crypto: decryption returned invalid plaintext"
        )
    end

    return plaintext
end

function Crypto:encryptConstant(
    id,
    plaintext,
    nonce,
    aad
)
    if not nonce then
        nonce =
            self:deriveNonce(id)
    end

    local key =
        self:deriveKey(id)

    local ciphertext, tag =
        self:encrypt(
            plaintext,
            key,
            nonce,
            aad
        )

    if type(ciphertext) ~= "string"
        or type(tag) ~= "string"
    then
        error(
            "LRPE crypto: encryptConstant returned invalid ciphertext/tag"
        )
    end

    return ciphertext,
        nonce,
        aad or "",
        tag
end

function Crypto:decryptConstant(
    id,
    ciphertext,
    nonce,
    aad,
    tag
)
    local key =
        self:deriveKey(id)

    return self:decrypt(
        ciphertext,
        key,
        nonce,
        aad,
        tag
    )
end

function Crypto.selfTest()
    local crypto =
        Crypto.new(
            0x12345678
        )

    local plaintext =
        "Lurape v17.7 LRPE crypto self-test"

    local id = 1

    local aad =
        "LRPE-17.7-TEST"

    local ciphertext,
        nonce,
        returnedAAD,
        tag =
        crypto:encryptConstant(
            id,
            plaintext,
            nil,
            aad
        )

    assert(
        type(ciphertext) == "string",
        "LRPE crypto self-test: ciphertext invalid"
    )

    assert(
        type(nonce) == "string"
            and #nonce == 12,
        "LRPE crypto self-test: nonce invalid"
    )

    assert(
        returnedAAD == aad,
        "LRPE crypto self-test: AAD mismatch"
    )

    assert(
        type(tag) == "string"
            and #tag == 16,
        "LRPE crypto self-test: tag invalid"
    )

    local recovered =
        crypto:decryptConstant(
            id,
            ciphertext,
            nonce,
            returnedAAD,
            tag
        )

    assert(
        recovered == plaintext,
        "LRPE crypto self-test: plaintext mismatch"
    )

    local alteredCiphertext =
        ciphertext

    if #alteredCiphertext > 0 then
        local first =
            alteredCiphertext:byte(1)

        alteredCiphertext =
            string.char(
                bxor(first, 1)
            )
            .. alteredCiphertext:sub(2)

        local tamperOK =
            pcall(function()
                crypto:decryptConstant(
                    id,
                    alteredCiphertext,
                    nonce,
                    returnedAAD,
                    tag
                )
            end)

        assert(
            not tamperOK,
            "LRPE crypto self-test: tamper detection failed"
        )
    end

    return true
end

return Crypto