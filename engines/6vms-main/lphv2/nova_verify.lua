local final = _VERSION .. "_"

local EncodingService = game:GetService("EncodingService")

local function stringToHash(inputString: string)
    return EncodingService:ComputeStringHash(inputString, Enum.HashAlgorithm.Sha256)
end

local function binaryToHex(binaryString: string): string
    local hex, _ = string.gsub(binaryString, ".", function(char)
        return string.format("%02x", string.byte(char))
    end)
    return hex
end

local function getDeterministicEnumHash()
    local allEnums = Enum:GetEnums()
    local enumData = {}
    local sortedEnumNames = {}
    for _, enum in ipairs(allEnums) do
        local enumName = tostring(enum)
        enumName = string.gsub(enumName, "^Enum%.", "")
        table.insert(sortedEnumNames, enumName)
        local items = enum:GetEnumItems()
        local itemNames = {}
        for _, item in ipairs(items) do
            table.insert(itemNames, item.Name)
        end
        table.sort(itemNames)
        enumData[enumName] = itemNames
    end
    table.sort(sortedEnumNames)
    local payloadParts = {}
    for _, enumName in ipairs(sortedEnumNames) do
        local items = enumData[enumName]
        local enumString = enumName .. ":" .. table.concat(items, ",")
        table.insert(payloadParts, enumString)
    end
    local finalPayload = table.concat(payloadParts, "NOVA")

    local hash = EncodingService:ComputeStringHash(finalPayload, Enum.HashAlgorithm.Sha256)
    return hash, finalPayload
end

local SoundService = game:GetService("SoundService")
local EXPECTED_AUDIOS = {
    ["action_falling.ogg"] = 10.0000000000000000,
    ["action_footsteps_plastic.mp3"] = 2.4816326530612245,
    ["action_get_up.mp3"] = 0.5746938775510204,
    ["action_jump.mp3"] = 0.3395918367346939,
    ["action_jump_land.mp3"] = 0.2612244897959184,
    ["action_swim.mp3"] = 4.8848979591836734,
    ["impact_explosion_03.mp3"] = 2.5861224489795918,
    ["impact_water.mp3"] = 2.3771428571428572,
    ["oof.ogg"] = 0.3322902494331066,
    ["ouch.ogg"] = 0.3322902494331066,
    ["volume_slider.ogg"] = 0.8454166666666667
}

local BASE_PATH = "rbxasset://sounds/"
local TOLERANCE = 0.1

local function validateAllAudios()
    local allPassed = true
    for fileName, expectedLength in pairs(EXPECTED_AUDIOS) do
        local sound = Instance.new("Sound")
        sound.SoundId = BASE_PATH .. fileName
        sound.Volume = 0
        sound.Parent = SoundService
        if not sound.IsLoaded then
            sound.Loaded:Wait()
        end
        local difference = math.abs(sound.TimeLength - expectedLength)
        if difference > TOLERANCE then
            allPassed = false
        end
        sound:Destroy()
    end
    return allPassed
end

local function IiIiiI(_valX, _valY)
    local s = 1
    while s ~= 0 do
        task.wait()
        if (_valX * _valX) + (_valY * _valY) >= 0 then
            if s == 1 then
                if validateAllAudios() then
                    final = final .. "NOVA_PASS"; s = 3
                else
                    while true do end
                end
            elseif s == 2 then
                final = final .. "NOVA_PASS"; s = 0
            elseif s == 3 then
                local success, hash, rawPayload = pcall(getDeterministicEnumHash)
                if success then
                    if binaryToHex(hash) == "72e6aafe989c1c4244aaa1172cedc55f652877c73264fe787344c1c621536b93" then
                        final = final .. "NOVA_PASS"; s = 2
                    else
                        while true do end
                    end
                end
            end
        end
    end
    print(final)
    local buf = stringToHash(final)
    print(binaryToHex(buf))
    if binaryToHex(buf) == "f1745bcfbc3bc453c7c78c8ff4a56b293121f8c013289465ac722eccbb299c62" then
        print("passed")
    end
end

local _valX = math.abs(os.time() % 100)
local _valY = math.abs(os.clock() % 100)
if (_valX * _valX) + (_valY * _valY) >= 0 then
    IiIiiI(_valX, _valY)
end
