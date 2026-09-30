-- Lurape v17.7
-- lrpe_serializer.lua
-- LuaJIT 5.1 compatible

local Serializer = {}

local MAGIC = "LRPS"
local VERSION = 1

local function writeByte(out, value)
    out[#out + 1] =
        string.char(value % 256)
end

local function writeU16(out, value)
    value = value % 65536

    out[#out + 1] =
        string.char(
            value % 256,
            math.floor(value / 256) % 256
        )
end

local function writeU32(out, value)
    value = value % 4294967296

    out[#out + 1] =
        string.char(
            value % 256,
            math.floor(value / 256) % 256,
            math.floor(value / 65536) % 256,
            math.floor(value / 16777216) % 256
        )
end

local function writeVarint(out, value)
    if type(value) ~= "number" then
        error("LRPE serializer: varint must be numeric")
    end

    value = math.floor(value)

    if value < 0 then
        error("LRPE serializer: negative varint")
    end

    repeat
        local byte =
            value % 128

        value =
            math.floor(
                value / 128
            )

        if value > 0 then
            byte =
                byte + 128
        end

        writeByte(out, byte)
    until value == 0
end

local function readByte(data, state)
    local position = state.position

    if position > #data then
        error(
            "LRPE serializer: unexpected end of data"
        )
    end

    local value =
        data:byte(position)

    state.position =
        position + 1

    return value
end

local function readU16(data, state)
    local a =
        readByte(data, state)

    local b =
        readByte(data, state)

    return a + b * 256
end

local function readU32(data, state)
    local a =
        readByte(data, state)

    local b =
        readByte(data, state)

    local c =
        readByte(data, state)

    local d =
        readByte(data, state)

    return
        a
        + b * 256
        + c * 65536
        + d * 16777216
end

local function readVarint(data, state)
    local value = 0
    local multiplier = 1

    for _ = 1, 8 do
        local byte =
            readByte(data, state)

        value =
            value
            + (byte % 128)
            * multiplier

        if byte < 128 then
            return value
        end

        multiplier =
            multiplier * 128
    end

    error(
        "LRPE serializer: invalid varint"
    )
end

local TAG_NIL = 0
local TAG_STRING = 1
local TAG_NUMBER = 2
local TAG_BOOLEAN_FALSE = 3
local TAG_BOOLEAN_TRUE = 4

local function writeValue(out, value)
    local valueType =
        type(value)

    if value == nil then
        writeByte(
            out,
            TAG_NIL
        )

        return
    end

    if valueType == "string" then
        writeByte(
            out,
            TAG_STRING
        )

        writeVarint(
            out,
            #value
        )

        out[#out + 1] =
            value

        return
    end

    if valueType == "number" then
        writeByte(
            out,
            TAG_NUMBER
        )

        local text =
            string.format(
                "%.17g",
                value
            )

        writeVarint(
            out,
            #text
        )

        out[#out + 1] =
            text

        return
    end

    if valueType == "boolean" then
        if value then
            writeByte(
                out,
                TAG_BOOLEAN_TRUE
            )
        else
            writeByte(
                out,
                TAG_BOOLEAN_FALSE
            )
        end

        return
    end

    error(
        "LRPE serializer: unsupported constant type "
        .. tostring(valueType)
    )
end

local function readValue(data, state)
    local tag =
        readByte(data, state)

    if tag == TAG_NIL then
        return nil
    end

    if tag == TAG_STRING then
        local length =
            readVarint(data, state)

        local start =
            state.position

        local finish =
            start + length - 1

        if finish > #data then
            error(
                "LRPE serializer: truncated string"
            )
        end

        local value =
            data:sub(
                start,
                finish
            )

        state.position =
            finish + 1

        return value
    end

    if tag == TAG_NUMBER then
        local length =
            readVarint(data, state)

        local start =
            state.position

        local finish =
            start + length - 1

        if finish > #data then
            error(
                "LRPE serializer: truncated number"
            )
        end

        local text =
            data:sub(
                start,
                finish
            )

        state.position =
            finish + 1

        local value =
            tonumber(text)

        if value == nil then
            error(
                "LRPE serializer: invalid number"
            )
        end

        return value
    end

    if tag == TAG_BOOLEAN_FALSE then
        return false
    end

    if tag == TAG_BOOLEAN_TRUE then
        return true
    end

    error(
        "LRPE serializer: unknown value tag "
        .. tostring(tag)
    )
end

local function encodeInstruction(out, instruction)
    writeVarint(
        out,
        #instruction
    )

    for i = 1, #instruction do
        writeValue(
            out,
            instruction[i]
        )
    end
end

local function decodeInstruction(data, state)
    local count =
        readVarint(data, state)

    local instruction = {}

    for i = 1, count do
        instruction[i] =
            readValue(
                data,
                state
            )
    end

    return instruction
end

local function encodePrototype(out, proto)
    writeVarint(
        out,
        proto.params or 0
    )

    writeByte(
        out,
        proto.vararg and 1 or 0
    )

    local constants =
        proto.constants or {}

    writeVarint(
        out,
        #constants
    )

    for i = 1, #constants do
        writeValue(
            out,
            constants[i]
        )
    end

    local code =
        proto.code or {}

    writeVarint(
        out,
        #code
    )

    for i = 1, #code do
        encodeInstruction(
            out,
            code[i]
        )
    end

    local upvalues =
        proto.upvalues or {}

    writeVarint(
        out,
        #upvalues
    )

    for i = 1, #upvalues do
        local upvalue =
            upvalues[i]

        writeVarint(
            out,
            upvalue.index or 0
        )

        writeValue(
            out,
            upvalue.kind
        )
    end

    local children =
        proto.prototypes or {}

    writeVarint(
        out,
        #children
    )

    for i = 1, #children do
        encodePrototype(
            out,
            children[i]
        )
    end
end

local function decodePrototype(data, state)
    local proto = {
        version = "LRPE-17.7",
        code = {},
        constants = {},
        prototypes = {},
        upvalues = {},
        maxstack = 0,
        params = 0,
        vararg = false,
    }

    proto.params =
        readVarint(
            data,
            state
        )

    proto.vararg =
        readByte(
            data,
            state
        ) ~= 0

    local constantCount =
        readVarint(
            data,
            state
        )

    for i = 1, constantCount do
        proto.constants[i] =
            readValue(
                data,
                state
            )
    end

    local codeCount =
        readVarint(
            data,
            state
        )

    for i = 1, codeCount do
        proto.code[i] =
            decodeInstruction(
                data,
                state
            )
    end

    local upvalueCount =
        readVarint(
            data,
            state
        )

    for i = 1, upvalueCount do
        proto.upvalues[i] = {
            index =
                readVarint(
                    data,
                    state
                ),
            kind =
                readValue(
                    data,
                    state
                ),
        }
    end

    local childCount =
        readVarint(
            data,
            state
        )

    for i = 1, childCount do
        proto.prototypes[i] =
            decodePrototype(
                data,
                state
            )
    end

    local maxRegister = 0

    for _, instruction in ipairs(proto.code) do
        for i = 2, #instruction do
            local value =
                instruction[i]

            if type(value) == "number"
                and value >= 0
                and value > maxRegister
            then
                maxRegister = value
            end
        end
    end

    proto.maxstack =
        maxRegister + 1

    return proto
end

function Serializer.encode(proto)
    if type(proto) ~= "table" then
        error(
            "LRPE serializer: prototype must be a table"
        )
    end

    local out = {
        MAGIC
    }

    writeByte(
        out,
        VERSION
    )

    encodePrototype(
        out,
        proto
    )

    return table.concat(out)
end

function Serializer.decode(data)
    if type(data) ~= "string" then
        error(
            "LRPE serializer: input must be a string"
        )
    end

    if data:sub(
        1,
        #MAGIC
    ) ~= MAGIC then
        error(
            "LRPE serializer: invalid magic"
        )
    end

    local state = {
        position =
            #MAGIC + 1
    }

    local version =
        readByte(
            data,
            state
        )

    if version ~= VERSION then
        error(
            "LRPE serializer: unsupported version "
            .. tostring(version)
        )
    end

    local proto =
        decodePrototype(
            data,
            state
        )

    if state.position <= #data then
        error(
            "LRPE serializer: trailing data"
        )
    end

    return proto
end

function Serializer.roundTrip(proto)
    local encoded =
        Serializer.encode(
            proto
        )

    local decoded =
        Serializer.decode(
            encoded
        )

    return encoded,
        decoded
end

return Serializer