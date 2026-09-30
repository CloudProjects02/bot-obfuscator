local util = require("prometheus.util")
local chararray = util.chararray

local VarDigits = chararray(
    "abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "0123456789_"
)

local VarStartDigits = chararray(
    "abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
)

local BASE_START = #VarStartDigits
local BASE = #VarDigits

local count = 0
local start_time = os.clock()

return function(id, scope)

    count = count + 1

    -- Print every 1,000 generated names
    if count % 1000 == 0 then
        local elapsed = os.clock() - start_time

        print(
            string.format(
                "[BEERBREW: Renaming Variables] " ..
                "Generated: %d | Time: %.2fs | Last ID: %s",
                count,
                elapsed,
                tostring(id)
            )
        )
    end

    id = tonumber(id) or 0

    local chars = {}
    local n = id

    -- First character
    chars[1] = VarStartDigits[
        (n % BASE_START) + 1
    ]

    n = math.floor(
        n / BASE_START
    )

    -- Remaining characters
    for i = 2, 10 do
        chars[i] = VarDigits[
            (n % BASE) + 1
        ]

        n = math.floor(
            n / BASE
        )
    end

    local result =
        "LRPE_" ..
        table.concat(chars)

    return result
end