-- Prometheus/src/prometheus/steps/AntiParser.lua
-- Anti-parser/anti-analyzer wrapper step.
local Step = require("prometheus.step")
local Parser = require("prometheus.parser")
local Enums = require("prometheus.enums")
local logger = require("logger")

local AntiParser = Step:extend()
AntiParser.Description = "anti-parser/anti-analyzer wrapper"
AntiParser.Name = "Anti Parser"
AntiParser.SettingsDescriptor = {
    Fast = {
        name = "Fast",
        description = "Use fast (less secure) mode to skip heavy hash-based parsing.",
        type = "boolean",
        default = false,
    },
}

function AntiParser:init(settings)
    -- no initialization required
end

function AntiParser:apply(ast, pipeline)
    if pipeline.PrettyPrint then
        logger:warn(string.format("\"%s\" cannot be used with PrettyPrint, ignoring \"%s\"", self.Name, self.Name))
        return ast
    end

    if self.Fast then
        -- fast mode: keep step active but skip expensive string parse/unparse.
        return ast
    end

    local unparser = require("prometheus.unparser")
    local original_source = unparser:new({LuaVersion = pipeline.LuaVersion}):unparse(ast)

    local wrapper_parts = {}
    table.insert(wrapper_parts, [[
        do
            local dirtyWarning = "ew thats drity don't execute me in this >.<"

            local TAMPER_MSG = [==[
                    Protected using Lurape v17.4 https://luraph-v17.onrender.com/
                                                                                                    
                                                                                                    
                                                                               /       /     / -  -   - /  -
                         `…’°„¡(×7ìljc¤%%Icl<†?)!¯“°:‚ˆ·¨´``````                   / no good env logger?  /
                     `·/9ÕÅþÐmdFÝ9µ9ÖœËŒÊÊŒÊÆÆÊŒØØMËWæþÄÀœŠã$åä¤·…¸…``        /    /   /  lol             /
                    `—ÚNO|‚·´`´³0ÔNŽŸî¬^”¯¡¡¡¯^¯¡«¿z&äëãAqœÀæËÊÈRÅ#QÄÜ½›´`       / \      /   \    /  |   /
                   …4ÑZ‘```¨›wÁØÙi¿úŠØMÁpbŸÞANÉŒØÃNg€ÜÞäTasöaÝèÐBŒÊMØmÔŒ#C˜´` / \                     
                 `;šÉL´´``fÂðƒõWŠµ[”¬>%ÏùçÍ%7¯¨`´…‚‘‘’‚‚;;;››:’˜¸·´¨…¨…j¶Â8*…`/                     
                 ;eBJ¨´…»àÀõ=áŽô(Yäes*“²‹‚…¨’C¤¨``´`    ¨t6äZàSeUäÓÎí:¨´` ;õ#e›´`                   
                ’üÅ@¸  ¿Tc‹ŸXütdñõ¾SU4ÿäü56ŸU™Òe´``  ````ˆ;j·` ```´˜rÒö˜```·C#L´`                   
                óQ™‚` `´¨|ð3/9KxLŸ‘¨´´=P×…´´’U0ÒÞï…` ````‹ã¬·ˆ—sUñbÒè¶ÅÜ2(’`ÖK˜                    
               zÃk’´`  ``¨¨—ë®³¨¨::¨¨¹*[¬’¨¡ñ3:…!å$¡´    ^ä*éñ=„J/·¨<*’›³ïÿéïTË*`                   
              îÂ8ˆ¨´`    `˜ë0lÓZ¿…·ÏBÆÆÆÆÑgˆ´·…‚pûEÓ:`   ¸Án…```’°´´…‘‚´¨P–‚óñBE³`                  
           ·”LEœo¤I%î÷`·zÿÁR¿}î’·´¡¶ÆÆÆÆÆÆØ4´‚¥õ¸…µÆ°`¨…°Õ!¤‘` …¤ŽÑÑÆÑÿ—·` ¨öãéBS³´                
         `¦dÊþáÏ—:ªit‡t¬ˆ‚7Qü…´´›;…cÙWŒÆØÀü·;7y‰ƒ©AÙ‘…ƒQÊÊ—¨°¦ˆ`²šÆÆÑÆÆÊJ…·³j™þ€5âÛ†                
        ´IBÈž°·|ÒÂNý9ñÀÂÜú*ïdš(Iž@[¨·…›º;…·ˆ‚¸”…jßñ“``´³CÅ€’¨´´‹¨³sñŠÔÝj‘´1¿ñœÎ)ygæ”`              
       ´cRBé’…±ÂŠ7‚¨›1‚—±ÐŒd;+DœÞ¢º¬ýö§j¬ii†íh¶Àý{¸`   `´mMgµ4†—^¿‚°…t™t˜´;©KA/>ä„ÇØÝ´              
       ªÿÛf9´¤Àd˜´´´žØš’¨·ˆ˜¨¨¨…J$#ÃBBBBBNêû>‹¸´´``    ´pB)²VÕ$ó*5?²ª¿SŠAL!¯}°’Ÿln#ø·              
       }A©wá:ûM•¨´ˆ—ÐØÉŒG[’¨¨´´´`´¨´``  `’³‘>Cn¦·¨`      ªpÉK%ˆ´````  ``·øåˆ´``:ÒrúÈÒ´              
       !$Þòè¹ZÉ^ipØŒŒó…*ûÀÑêC!˜´´´´¦ìî¼3õÒžþÛ§Î¿¨´`      `¨ªÿÑW[¨```   `…ŽE«¨¨~ha+éŒ%`              
       ˆõQ™G’5ËÍ‚¬¯¯Ðâ¨´¨¦eKŒÉ¥Ï(‚·¨´  `…¹þõ…³ÚÄœây‹`    `°ŸMÂBzn[˜   ´@ÈÑp*‚c;¡ûÃÚ…               
       `!ßÅRj~áø¨´`¨%Æœs‘´``/¶m¾AMÃãhò“…``‚û#¼ªK„;½hí´```¨^8ËC÷?¨˜×Ì™’¸sþÑÑØfìU®38Ô«                
        `ìÂÐUÙ†‚¨` `‘QÆÆBd¯`¹äÁ°´¸º/ÌÔŒÉEÔbl¡‹¨¨¨´`´´´>ÛÐœŒHƒ¸¨´´´´´…tqÉäŽÊÊb¦…‚äKj´                
         `‹éÃ0³–·`  `ŸÆÆÆÆÑÃãAØQ¿·```´¸;JÅÆÑÊÈBgŸ>‹…´`´‚–º‹…´´`·:1ÓNØNÁ4:rÑÑR†¨3B0·`                
           ¨îÁ$````¨jÆÆÆÆÆÆÆÆÆÆÆQf!‚```+Ä£´´¨’^LdÀØÊÃMØÊÆÆÆÆŒØÃÄœÂ‡··ƒÔ*·XÑØƒ…¾q*``                
           ``+ßN•`` `—MÆÆÆÆÆÆÆÆÆÆÆÆÆÑÅhCâÃ¨´``  `´}Ûñ··¨·…Ç¶²…·´`…§¾¨¨îEŸúÉÑÑ3ˆVg7``                
             ´„ÕK¿   ‘¶ÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑøOç@<~ˆ´)Šé…¨```¿é›¨¨·°jéŒñ8ÈÆÆÆÆÑÑõ‚@Ží``                
               –Hð| `…YÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑØŒÆÆÃNÁÁæŒÆÃæÈÊÆÆÆÆÆÆÆÆÆÆÆÆÆš›¤KI`                 
                (#å^``[æÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÙìÀz´`                
                `*ÔÀ¦ ‘ÎÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÛ²¿E½                  
                ``›žÃá–!ÜÃ>fÀÊÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆþ”*þs`                 
                  ``¡$ÁV7AÃ>˜jãÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÁª/ÁÌ`                 
                     …JXÙ7d#Ï˜¹#êü¶ØÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆ#^—æw´                 
                     `¨„FB™óÅ¥ÌW¥¨…¹74RŒÑÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÁªºÁü¨                 
                       `…‰ÊÜ*ÿÊÃ¨´´´´´…uQÊÂÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÐ³Nõ…                 
                          –Eêv<þÁz¸´```´/EU…¨;1ÜQMÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÆÑÃÂb¹°E4…                 
                          `°UB£‚íÔês;¨´’DN…´````´˜4ËÁ3á¶ÔÐHÑÑØØŒÑÑÑŒÃÂÑÐhÁê1ß©˜”#&¨                 
                           `¸IÐÐi˜†ä#ZJSÃj``      IÀ¥´´¨¨´‹ÃÒ—ˆ’íQè¦˜Dq=¨€ñU8«`t#C`                 
                             `›2Âý†…¹%åËØÓn“¨´¨` `sæd´````tØµ¸´´íþ%…¹Qš(s€ØG{·:œp¯                  
                              ``¹üÅÔC˜·›†9ÃØQŽ¶¥TT€ÑÃ…´´¨…Äœí¨´ˆùH¥åNŒŒÑÑN‰’´‚dÃl`                  
                                ``·<ÕÊËð¢;¨·›*YdÄMÑÑÆÑÑÑÆÆÑŒŒËægéäfó>¬¸¨¨` ºÖMï``                  
                                 ```¨¨ƒÒÀQQâ5>ª°:’…¨·¨¨´´¨¨¨¨¨¨·…’‘;°²„»cOÛWd¦```                  
                                 `````````´›?L§ëmgEÁEq€G8ÚéãAqKþÁEKêAGÜÓP¾n{‘`````                  
                                                ``´…‚›º“””“~²¹‘ˆ·¨´´``` ```````                     
                                                     `````````            `````                     
                                                                                                    
]==]

            local function fail(tag)
                print(TAMPER_MSG)
                while true do print("HONESTLY dtc on the EASIET test") end
                return
            end

            local function isStaticAnalyzer()
                if type(package) == "table" and type(package.loaded) == "table" then
                    for _, module_name in ipairs({"luaparse", "metalua", "luainspect", "typedlua"}) do
                        if package.loaded[module_name] then
                            return true
                        end
                    end
                end

                local suspicious = {"luaparse", "metalua", "LuaParser", "deobfuscator", "TimmyENV"}
                for _, name in ipairs(suspicious) do
                    if rawget(_G, name) then
                        return true
                    end
                end

                if type(shared) == "table" then
                    for _, name in ipairs({"luaparse", "metalua", "TimmyENV", "deobf"}) do
                        if rawget(shared, name) then
                            return true
                        end
                    end
                end

                return false
            end

            if isStaticAnalyzer() then
                fail("thats dirty dont execute this here >.<")
            end
        end
    ]])

    local wrapper_code = table.concat(wrapper_parts, "") .. original_source
    local parser = Parser:new({LuaVersion = pipeline.LuaVersion or Enums.LuaVersion.Lua51})
    return parser:parse(wrapper_code)
end

return AntiParser
