-- Prometheus/src/prometheus/steps/AntiTamper.lua
-- Integrity wrapper for chunked encrypted source.

local Step = require("prometheus.step")
local Parser = require("prometheus.parser")
local Enums = require("prometheus.enums")
local logger = require("logger")

local table_insert = table.insert
local table_concat = table.concat
local math_random = math.random
local ipairs = ipairs
local math_ceil = math.ceil
local math_max = math.max

local AntiTamper = Step:extend()

AntiTamper.Description = "Integrity wrapper with chunked encrypted loader"
AntiTamper.Name = "OELD Anti Tamper"

AntiTamper.SettingsDescriptor = {
    Fast = {
        name = "Fast",
        description = "Use fast mode to skip expensive encryption chunking.",
        type = "boolean",
        default = false,
    },
}

function AntiTamper:init(settings)
    self.Fast = settings and settings.Fast or false
end

function AntiTamper:apply(ast, pipeline)
    if pipeline.PrettyPrint then
        logger:warn(string.format(
            "\"%s\" cannot be used with PrettyPrint, ignoring \"%s\"",
            self.Name,
            self.Name
        ))
        return ast
    end

    if self.Fast then
        return ast
    end

    local target_version =
        pipeline.LuaVersion or Enums.LuaVersion.Lua51

    --------------------------------------------------------------------------
    -- Convert AST to source
    --------------------------------------------------------------------------

    local unparser = require("prometheus.unparser")

    local ok_unparse, original_source = pcall(function()
        local u = unparser:new({
            LuaVersion = target_version
        })

        assert(u, "unparser:new() returned nil")
        assert(
            type(u.unparse) == "function",
            "unparser.unparse is not a function"
        )

        return u:unparse(ast)
    end)

    if not ok_unparse then
        error(
            "AntiTamper: failed to unparse AST: "
            .. tostring(original_source)
        )
    end

    if type(original_source) ~= "string" then
        error(
            "AntiTamper: unparser returned "
            .. type(original_source)
            .. " instead of string"
        )
    end

    --------------------------------------------------------------------------
    -- Split source into chunks
    --------------------------------------------------------------------------

    local num_chunks = 3

    local chunk_size = math_max(
        1,
        math_ceil(#original_source / num_chunks)
    )

    local chunks = {}

    for i = 1, #original_source, chunk_size do
        chunks[#chunks + 1] = original_source:sub(
            i,
            math.min(
                i + chunk_size - 1,
                #original_source
            )
        )
    end

    --------------------------------------------------------------------------
    -- Encrypt chunks
    --------------------------------------------------------------------------

    local function encrypt(data, key)
        local bytes = {}

        for i = 1, #data do
            bytes[i] =
                (string.byte(data, i) + key + i) % 256
        end

        return bytes
    end

    local keys = {}
    local encrypted_chunks = {}

    for i, chunk in ipairs(chunks) do
        local key = math_random(50, 150)

        keys[i] = key
        encrypted_chunks[i] = encrypt(chunk, key)
    end

    --------------------------------------------------------------------------
    -- Convert byte arrays to Lua table literals
    --------------------------------------------------------------------------

    local function bytes_to_string(bytes)
        local parts = {}

        for i, b in ipairs(bytes) do
            parts[i] = tostring(b)
        end

        return "{" .. table_concat(parts, ",") .. "}"
    end

    local chunk_tables = {}

    for i, bytes in ipairs(encrypted_chunks) do
        chunk_tables[i] = bytes_to_string(bytes)
    end

    --------------------------------------------------------------------------
    -- Wrapper
    --------------------------------------------------------------------------

    local wrapper_parts = {}

    table_insert(wrapper_parts, [[
do

local startTime = os.clock()

local TAMPER_MSG = [==[
                    Protected using Lurape v17.8 https://luraph-v17.onrender.com/


                                                                               /       /     / -  -   - /  -
                         `…’°„¡(×7ìljc¤%%Icl<†?)!¯“°:‚ˆ·¨´``````                   / no good env logger?  /
                     `·/9ÕÅþÐmdFÝ9µFÝ9ÖœËÊŒÊŒÊÆÆÊŒØØMËWæþÄÀœŠã$åä¤·…¸…``        /    /   /  lol             /
                    `—ÚNO|‚·´`´³0ÔNŽŸî¬^”¯¡¡¡¯^¯¡«¿z&äëãAqœËÊÈRÅ#QÄÜ½›´`       / \      /   \    /  |   /
                   …4ÑZ‘```¨›wÁØÙi¿úŠØMÁpbŸÞANÉŒØÃNg€ÜÞäTasöaÝèÐBŒÊMØmÔŒ#C˜´` / \                     
                 `;šÉL´´``fÂðƒõWŠµ[”¬>%ÏùçÍ%7¯¨`´…‚‘‘’‚‚;;;››:’˜¸·´¨…¨…j¶Â8*…`/                     
                 ;eBJ¨´…»àÀõ=áŽô(Yäes*“²‹‚…¨’C¤¨``´`    ¨t6äZàSeUäÓÎí:¨´` ;õ#e›´`                   
                ’üÅ@¸  ¿Tc‹ŸXütdñõ¾SU4ÿäü56ŸU™Òe´``  ````ˆ;j·` ```´˜rÒö˜```·C#L´`                   
                óQ™‚` `´¨|ð3/9KxLŸ‘¨´´´=PÒÞï…` ````‹ã¬·ˆ—sUñbÒè¶ÅÜ2(’`ÖK˜                    
               zÃk’´`  ``¨¨—ë®³¨¨::¨¨¹*[¬’¨¡ñ3:…!å$¡´    ^ä*éñ=„J/·¨<*’›³ïÿéïTË*`                   
              îÂ8ˆ¨´    `˜ë0lÓZ¿…·ÏBÆÆÆÆÑgˆ´·…‚pûEÓ:`   ¸Án…```’°´´…‘‚´¨P–‚óñBE³`                  
           ·”LEœo¤I%î÷`·zÁR¿}î’·´¡¶ÆÆÆÆÆÆØ4´‚¥õ¸…µÆ°`¨…°Õ!¤‘` …¤ŽÑÑÆÑÿ—·` ¨öãéBS³´               
         `¦dÊþáÏ—:ªit‡t¬ˆ‚7Qü…´´›;…cÙWŒÆØÀü·;7y‰ƒ©AÙ‘…ƒQÊÊ—¨°¦ˆ`²šÆÆÑÆÆÊJ…·³j™þ€5âÛ†              
        ´IBÈž°·|ÒÂNý9ñÀÂÜú*ïdš(Iž@[¨·…›º…·ˆ‚¸”…jßñ“``´³CÅ€’¨´´‹¨³sñŠÔÝj‘´1¿ñœÎ)ygæ”`             
       ´cRBé’…±ÂŠ7‚¨›1‚—±ÐŒd;+DœÞ¢º¬ýö§j¬ii†íh¶Àý{¸`   `´mMgµ4†—^¿‚°…t™t˜´;©KA/>ä„ÇØÝ´             
       ªÿÛf9´¤Àd˜´´´žØš’¨·ˆ˜¨¨¨…J$#ÃBBBBBNêû>‹¸´´``    ´pB)²VÕ$ó*5?²ª¿SŠAL!¯}°’Ÿln#ø·             
       }A©wá:ûM•¨´ˆ—ÐØÉŒG[’¨¨´´´`´¨´``  `’³‘>Cn¦·¨`      ªpÉK%ˆ´````  ``·øåˆ´``:ÒrúÈÒ´             
       !$Þòè¹ZÉ^ipØŒŒó…*ûÀÑêC!˜´´´´¦ìî¼3õÒžþÛ§Î¿¨´`      `¨ªÿÑW[¨```   `…ŽE«¨¨~ha+éŒ%`             
       ˆõQ™G’5ËÍ‚¬¯¯Ðâ¨´¨¦eKŒÉ¥Ï(‚·¨´  `…¹þõ…³ÚÄœây‹`    `°ŸMÂBzn[˜   ´@ÈÑp*‚c;¡ûÃÚ…              
       `!ßÅRj~áø¨´`¨%Æœs‘´``/¶m¾AMÃãhò“…``‚û#¼ªK„;½hí´```¨^8ËC÷?¨˜×Ì™’¸sþÑÑØfìU®38Ô«             
        `ìÂÐUÙ†‚¨` `‘QÆÆBd¯`¹äÁ°´¸º/ÌÔŒÉÉEÔbl¡‹¨¨¨´`´´´>ÛÐœŒHƒ¸¨´´´´´…tqÉäŽÊÊb¦…‚äKj´             
         `‹éÃ0³–·`  `ŸÆÆÆÆÑÃãAØQ¿·```´¸;JÅÆÑÊÈBgŸ>‹…´`´‚–º‹…´´`·:1ÓNØNÁ4:rÑÑR†¨3B0·`             
           ¨îÁ$````¨jÆÆÆÆÆÆÆÆÆÆÆQf!‚```+Ä£´´¨’^LdÀØÊÃMØÊÆÆÆÆŒØÃÄœÂ‡··ƒÔ*·XÑØƒ…¾q*``             
           ``+ßN•`` `—MÆÆÆÆÆÆÆÆÆÆÆÆÆÑÅhCâÃ¨´``  `´}Ûñ··¨·…Ç¶²…·´`…§¾¨¨îEŸúÉÑÑ3ˆVg7``             
             ´„ÕK¿   ‘¶ÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑøOç@<~ˆ´)Šé…¨```¿é›¨¨·°jéŒñ8ÈÆÆÆÆÑÑõ‚@Ží``             
               –Hð| `…YÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑØŒÆÆÃNÁÁæŒÆÃæÈÊÆÆÆÆÆÆÆÆÆÆÆÆÆš›¤KI`               
                (#å^``[æÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÙìÀz´`              
                `*ÔÀ¦ ‘ÎÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÛ²¿E½                
                ``›žÃá–!ÜÃ>fÀÊÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆþ”*þs`               
                  ``¡$ÁV7AÃ>˜jãÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÁª/ÁÌ`               
                     …JXÙ7d#Ï˜¹#êü¶ØÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ#^—æw´               
                     `¨„FB™óÅ¥ÌW¥¨…¹74RŒÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÁªºÁü¨               
                       `…‰ÊÜ*ÿÊÃ¨´´´´´…uQÊÂÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÐ³Nõ…               
                          –Eêv<þÁz¸´```´/EU…¨;1ÜQMÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑÃÂb¹°E4…               
                          `°UB£‚íÔês;¨´’DN…´````´˜4ËÁ3á¶ÔÐHÑÑØØŒÑÑÑŒÃÂÑÐhÁê1ß©˜”#&¨               
                           `¸IÐÐi˜†ä#ZJSÃj``      IÀ¥´´¨¨´‹ÃÒ—ˆ’íQè¦˜Dq=¨€ñU8«`t#C`               
                             `›2Âý†…¹%åËØÓn“¨´¨` `sæd´````tØµ¸´´íþ%…¹Qš(s€ØG{·:œp¯                
                              ``¹üÅÔC˜·›†9ÃØQŽ¶¥TT€ÑÃ…´´¨…Äœí¨´ˆùH¥åNŒŒÑÑN‰’´‚dÃl`               
                                ``·<ÕÊËð¢;¨·›*YdÄMÑÑÆÑÑÑÆÆÑŒŒËægéäfó>¬¸¨¨` ºÖMï``               
                                 ```¨¨ƒÒÀQQâ5>ª°:’…¨·¨¨´¨¨¨¨¨¨¨¨·…’‘;°²„»cOÛWd¦```               
                                 `````````´›?L§ëmgEÁEq€G8ÚéãAqKþÁEKêAGÜÓP¾n{‘`````               
                                                ``´…‚›º“””“~²¹‘ˆ·¨´´``` `````                       
                                                     `````````            `````                       
]==]

local detected = false
local checks = {}

local function fail(msg)
    print(TAMPER_MSG)
    while true do end
end

local function checkWatermark()
    return y
        and y.l
        and y.l.u
        and y.l.u.r
        and y.l.u.r.a
        and y.l.u.r.a.p
        and y.l.u.r.a.p.e
        and y.l.u.r.a.p.e.v
        and y.l.u.r.a.p.e.v["17.8"]
        == "Protected using Lurape v17.8 https://luraph-v17.onrender.com/"
end

if not checkWatermark() then
    print'i worked hard on ts btw'
    while true do end
end

checks[1] = {
    name = "game_instance",
    run = function()
        if typeof(game) ~= "Instance" then
            return false
        end

        if typeof(workspace) ~= "Instance" then
            return false
        end

        return true
    end
}



checks[2] = {
    name = "game_props",
    run = function()
        if type(game.PlaceId) ~= "number" then
            return false
        end

        if type(game.JobId) ~= "string" then
            return false
        end

        if #game.JobId == 0 then
            return false
        end

        return true
    end
}

checks[3] = {
    name = "local_player",
    run = function()
        local ok, Players =
            pcall(game.GetService, game, "Players")

        if not ok or typeof(Players) ~= "Instance" then
            return false
        end

        local lp = Players.LocalPlayer

        if not lp or not lp:IsA("Player") then
            return false
        end

        return true
    end
}

checks[4] = {
    name = "character",
    run = function()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer

        if not lp then
            return false
        end

        local char =
            lp.Character
            or lp.CharacterAdded:Wait(5)

        if not char then
            return false
        end

        local hrp =
            char:FindFirstChild("HumanoidRootPart")

        if not hrp or not hrp:IsA("BasePart") then
            return false
        end

        return true
    end
}

checks[5] = {
    name = "services",
    run = function()
        local needed = {
            "RunService",
            "ReplicatedStorage",
            "UserInputService",
            "TweenService"
        }

        for _, name in ipairs(needed) do
            local ok, service =
                pcall(game.GetService, game, name)

            if not ok or typeof(service) ~= "Instance" then
                return false
            end
        end

        return true
    end
}

checks[6] = {
    name = "data_types",
    run = function()
        if typeof(Vector3.new(0, 0, 0)) ~= "Vector3" then
            return false
        end

        if typeof(CFrame.new()) ~= "CFrame" then
            return false
        end

        if typeof(Color3.new()) ~= "Color3" then
            return false
        end

        if typeof(UDim2.new()) ~= "UDim2" then
            return false
        end

        if typeof(Vector2.new()) ~= "Vector2" then
            return false
        end

        return true
    end
}

checks[7] = {
    name = "getfenv_check",
    run = function()
        local ok1, env1 =
            pcall(getfenv, 0)

        if not ok1 or type(env1) ~= "table" then
            return false
        end

        local ok2, env2 =
            pcall(getfenv, 1)

        if not ok2 or type(env2) ~= "table" then
            return false
        end

        if env1.game == nil and env2.game == nil then
            return false
        end

        if env1.workspace == nil and env2.workspace == nil then
            return false
        end

        return true
    end
}

checks[8] = {
    name = "getenv_check",
    run = function()
        local env = getfenv(0)

        if type(env) ~= "table" then
            return false
        end

        if type(env.print) ~= "function" then
            return false
        end

        if type(env.pcall) ~= "function" then
            return false
        end

        if type(env.typeof) ~= "function" then
            return false
        end

        if type(env.tick) ~= "function" then
            return false
        end

        return true
    end
}

checks[9] = {
    name = "runservice",
    run = function()
        local ok, RS =
            pcall(game.GetService, game, "RunService")

        if not ok or typeof(RS) ~= "Instance" then
            return false
        end

        local ok2 =
            pcall(function()
                return RS:IsClient()
            end)

        local ok3 =
            pcall(function()
                return RS:IsServer()
            end)

        if not ok2 and not ok3 then
            return false
        end

        return true
    end
}

local function runChecks()
    for i = 1, #checks do
        local check = checks[i]

        local ok, result, reason =
            pcall(check.run)

        if not ok then
            detected = true

            warn(
                "[LRPE AntiTamper] Check #" ..
                tostring(i) ..
                " (" ..
                tostring(check.name) ..
                ") ERROR: " ..
                tostring(result)
            )

            return false, check.name, tostring(result)
        end

        if not result then
            detected = true

            warn(
                "[LRPE AntiTamper] Check #" ..
                tostring(i) ..
                " (" ..
                tostring(check.name) ..
                ") FAILED" ..
                (reason and (": " .. tostring(reason)) or "")
            )

            return false, check.name, reason
        end
    end

    return true
end

runChecks()

if detected then
    print(TAMPER_MSG)
    return
end

local RS = game:GetService("RunService")
local last = tick()

RS.Heartbeat:Connect(function()
    local now = tick()

    if now - last >= 0.5 then
        last = now

        runChecks()

        if detected then
            fail(TAMPER_MSG)
        end
    end
end)

local players = game:GetService("Players")
local lp = players.LocalPlayer

if not lp then
    fail("LocalPlayer is nil")
end

local playerScripts =
    lp:FindFirstChild("PlayerScripts")

if not playerScripts then
    fail("PlayerScripts not found")
end

if not playerScripts:FindFirstChild("PlayerModule") then
    fail("PlayerModule missing")
end

if not playerScripts:FindFirstChild("RbxCharacterSounds") then
    fail("RbxCharacterSounds missing")
end

local vecSuccess, vec =
    pcall(Vector3.new, 0, 0, 0)

if not vecSuccess or typeof(vec) ~= "Vector3" then
    fail("Vector3 failed")
end

local netSuccess, networkClient =
    pcall(game.GetService, game, "NetworkClient")

if not netSuccess or not networkClient then
    fail("NetworkClient not available")
end

if not networkClient:FindFirstChild("ClientReplicator") then
    fail("ClientReplicator missing")
end

local chatSuccess, chatService =
    pcall(game.GetService, game, "Chat")

if not chatSuccess or not chatService then
    fail("Chat service not available")
end

if not chatService.Parent
    or chatService.Parent.Name ~= "Ugc" then
    fail("Chat service not under Ugc")
end

-- Embedded encrypted chunks and keys

local chunks = {
    ]] .. table_concat(chunk_tables, ",\n    ") .. [[
}

local keys = {
    ]] .. table_concat(keys, ",\n    ") .. [[
}

local function decrypt(data, key)
    local out = {}

    for i = 1, #data do
        out[i] =
            (data[i] - key - i) % 256
    end

    return out
end

local decrypted_parts = {}

for i = 1, #chunks do
    local decrypted_bytes =
        decrypt(chunks[i], keys[i])

    local part = {}

    for j, b in ipairs(decrypted_bytes) do
        part[j] = string.char(b)
    end

    decrypted_parts[i] =
        table.concat(part)
end

local original_source =
    table.concat(decrypted_parts)

local loadfunc =
    load or loadstring

if not loadfunc then
    fail("No loading function available")
end

local chunk, err =
    loadfunc(
        original_source,
        "=AntiTamper"
    )

if not chunk then
    fail(
        "Failed to load original code: "
        .. tostring(err)
    )
end

chunk()

local elapsed =
    os.clock() - startTime

warn(
    "Authenticated in "
    .. string.format("%.2f", elapsed)
    .. " seconds! Welcome, "
    .. tostring(lp.Name)
)

end
]])

    --------------------------------------------------------------------------
    -- Parse generated wrapper
    --------------------------------------------------------------------------

    local wrapper_code =
        table_concat(wrapper_parts, "")

    local parser =
        Parser:new({
            LuaVersion = target_version
        })

    local wrapper_ast =
        parser:parse(wrapper_code)

    return wrapper_ast
end

return AntiTamper