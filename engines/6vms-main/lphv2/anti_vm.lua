local EncodingService = game:GetService("EncodingService")

local b = buffer.create(6)
buffer.writestring(b, 0, "LURAPH")

local compressed = EncodingService:CompressBuffer(b, Enum.CompressionAlgorithm.Zstd, 22)
local decompressed = EncodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)

if buffer.readstring(decompressed, 0, 6) ~= "LURAPH" then
    error("luraph 1")
end

do
    local ok, err = pcall(function()
        local dts = {}
        local count = 0
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            count = count + 1
            dts[count] = dt
            if count >= 5 then conn:Disconnect() end
        end)
        while count < 5 do task.wait() end
        for _, dt in next, dts do
            if type(dt) ~= "number" or dt <= 0 or dt > 1 then error("luraph") end
        end
        local same = true
        for i = 2, #dts do
            if dts[i] ~= dts[1] then same = false break end
        end
        if same then error("luraph2") end
    end)
    if not ok then error("luraph3") end
end
