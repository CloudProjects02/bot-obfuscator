local serde = require("@lune/serde")
local fs = require("@lune/fs")
local api_dump = serde.decode("json", fs.readFile("core/io/apidump.json"))
for _, c in ipairs(api_dump.Classes) do
    if c.Name == "Players" then
        for _, m in ipairs(c.Members) do
            if m.Name == "LocalPlayer" then
                print("Found LocalPlayer in Players:", serde.encode("json", m))
            end
        end
    end
end
