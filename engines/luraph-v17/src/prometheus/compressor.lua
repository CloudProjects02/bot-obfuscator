-- Lurape v17.7
-- compressor.lua
-- LuaJIT 5.1 compatible

local Compressor = {}

local MAGIC = "LRPC"
local VERSION = 1

local MIN_MATCH = 3
local MAX_MATCH = 130
local MAX_DISTANCE = 65535
local MAX_LITERAL = 128

local function writeU16(out, value)
    out[#out + 1] = string.char(
        value % 256,
        math.floor(value / 256) % 256
    )
end

local function writeVarint(out, value)
    repeat
        local byte = value % 128
        value = math.floor(value / 128)

        if value > 0 then
            byte = byte + 128
        end

        out[#out + 1] = string.char(byte)
    until value == 0
end

local function readVarint(data, pos)
    local value = 0
    local shift = 0

    while true do
        local byte = data:byte(pos)

        if not byte then
            error("LRPE compressor: truncated varint")
        end

        pos = pos + 1

        value = value + (byte % 128) * (2 ^ shift)

        if byte < 128 then
            return value, pos
        end

        shift = shift + 7

        if shift > 49 then
            error("LRPE compressor: invalid varint")
        end
    end
end

local function findMatch(data, pos)
    local dataLen = #data

    if pos > dataLen then
        return 0, 0
    end

    local maxLength = math.min(
        MAX_MATCH,
        dataLen - pos + 1
    )

    if maxLength < MIN_MATCH then
        return 0, 0
    end

    local maxDistance = math.min(
        MAX_DISTANCE,
        pos - 1
    )

    if maxDistance < 1 then
        return 0, 0
    end

    local searchLimit = math.min(
        maxDistance,
        8192
    )

    local bestLength = 0
    local bestDistance = 0

    for distance = 1, searchLimit do
        local source = pos - distance

        if data:byte(source) == data:byte(pos) then
            local length = 1

            while length < maxLength do
                local sourceIndex =
                    source + ((length) % distance)

                local targetIndex =
                    pos + length

                if data:byte(sourceIndex) ~=
                    data:byte(targetIndex)
                then
                    break
                end

                length = length + 1
            end

            if length >= MIN_MATCH and length > bestLength then
                bestLength = length
                bestDistance = distance

                if length == maxLength then
                    break
                end
            end
        end
    end

    return bestLength, bestDistance
end

local function emitLiteral(out, data, pos, length)
    while length > 0 do
        local count = math.min(
            length,
            MAX_LITERAL
        )

        out[#out + 1] =
            string.char(count - 1)

        out[#out + 1] =
            data:sub(
                pos,
                pos + count - 1
            )

        pos = pos + count
        length = length - count
    end
end

local function emitMatch(out, length, distance)
    out[#out + 1] =
        string.char(
            0x80 + (length - MIN_MATCH)
        )

    writeU16(out, distance)
end

function Compressor.compress(data)
    if type(data) ~= "string" then
        error(
            "LRPE compressor: input must be a string"
        )
    end

    local out = {
        MAGIC
    }

    out[#out + 1] =
        string.char(VERSION)

    writeVarint(
        out,
        #data
    )

    if #data == 0 then
        return table.concat(out)
    end

    local pos = 1
    local literalStart = 1

    while pos <= #data do
        local matchLength,
            matchDistance =
            findMatch(
                data,
                pos
            )

        if matchLength >= MIN_MATCH then
            if pos > literalStart then
                emitLiteral(
                    out,
                    data,
                    literalStart,
                    pos - literalStart
                )
            end

            emitMatch(
                out,
                matchLength,
                matchDistance
            )

            pos =
                pos + matchLength

            literalStart =
                pos
        else
            pos = pos + 1

            if pos - literalStart >= MAX_LITERAL then
                emitLiteral(
                    out,
                    data,
                    literalStart,
                    MAX_LITERAL
                )

                literalStart =
                    pos
            end
        end
    end

    if literalStart <= #data then
        emitLiteral(
            out,
            data,
            literalStart,
            #data - literalStart + 1
        )
    end

    return table.concat(out)
end

function Compressor.decompress(data)
    if type(data) ~= "string" then
        error(
            "LRPE compressor: input must be a string"
        )
    end

    if data:sub(1, #MAGIC) ~= MAGIC then
        error(
            "LRPE compressor: invalid magic"
        )
    end

    local pos = #MAGIC + 1

    local version =
        data:byte(pos)

    if version ~= VERSION then
        error(
            "LRPE compressor: unsupported version "
            .. tostring(version)
        )
    end

    pos = pos + 1

    local originalLength

    originalLength, pos =
        readVarint(
            data,
            pos
        )

    local output = {}
    local outputLength = 0

    while pos <= #data do
        local control =
            data:byte(pos)

        pos = pos + 1

        if not control then
            error(
                "LRPE compressor: truncated token"
            )
        end

        if control < 0x80 then
            local length =
                control + 1

            if pos + length - 1 > #data then
                error(
                    "LRPE compressor: truncated literal"
                )
            end

            local chunk =
                data:sub(
                    pos,
                    pos + length - 1
                )

            output[#output + 1] =
                chunk

            outputLength =
                outputLength + length

            pos =
                pos + length
        else
            local length =
                (control - 0x80)
                + MIN_MATCH

            local low =
                data:byte(pos)

            local high =
                data:byte(pos + 1)

            if not low or not high then
                error(
                    "LRPE compressor: truncated match"
                )
            end

            pos = pos + 2

            local distance =
                low + high * 256

            if distance < 1
                or distance > outputLength
            then
                error(
                    "LRPE compressor: invalid distance"
                )
            end

            local previous =
                table.concat(output)

            local start =
                #previous - distance + 1

            local generated = {}

            for i = 0, length - 1 do
                local sourceIndex =
                    start + i

                local character

                if sourceIndex <= #previous then
                    character =
                        previous:sub(
                            sourceIndex,
                            sourceIndex
                        )
                else
                    local generatedIndex =
                        sourceIndex
                        - #previous

                    character =
                        generated[
                            (
                                generatedIndex - 1
                            ) % #generated + 1
                        ]
                end

                generated[#generated + 1] =
                    character
            end

            local chunk =
                table.concat(
                    generated
                )

            output[#output + 1] =
                chunk

            outputLength =
                outputLength + #chunk
        end

        if outputLength > originalLength then
            error(
                "LRPE compressor: output exceeds original size"
            )
        end
    end

    local result =
        table.concat(output)

    if #result ~= originalLength then
        error(
            "LRPE compressor: length mismatch: expected "
            .. tostring(originalLength)
            .. ", got "
            .. tostring(#result)
        )
    end

    return result
end

function Compressor.roundTrip(data)
    local compressed =
        Compressor.compress(
            data
        )

    local decompressed =
        Compressor.decompress(
            compressed
        )

    if decompressed ~= data then
        error(
            "LRPE compressor: round-trip verification failed"
        )
    end

    return compressed
end

function Compressor.stats(data)
    local compressed =
        Compressor.compress(
            data
        )

    return {
        originalSize = #data,
        compressedSize = #compressed,
        ratio =
            #data == 0
            and 1
            or #compressed / #data,
        saved =
            #data - #compressed,
    }
end

return Compressor