return(function(a,b,c,d,e,f,g,h,i,j)return function()local k,l,m,n,o = {}, {}, 0, {[5] = 1, [10] = 6, [3] = 2}, 0
        local function RunCrashFunction()
            local p = string.rep(' ', 8)
            local function ID_145(q, r)
                local s, t = 0, 1
                while 0 < q and 0 < r do
                    local u, v = q % 2, r % 2
                    if u ~= v then s = s + t end
                    q = (q - u) / 2
                    r = (r - v) / 2
                    t = t * 2
                end
                while r > 0 do
                    local u = r % 2
                    if u > 0 then s = s + t; r = (r - u) / 2; t = t * 2
                    else r = (r - u) / 2; t = t * 2 end
                end
                return s
            end
            -- RunCrashFunction generates infinite loops + heavy computation to crash VMs/emulators
            -- The key payload parts are below (DecryptConstant, string table, loadstring wrapper)
        end

        local p = { [1642754488] = 25, [3105969070] = 50, [48342080] = 50, [793184576] = 25 }

        local function RunCrashFunctionIndirect()
            a = RunCrashFunction
            pcall(string.find, pcall(string.rep, ' ', 1048576), pcall(string.rep, '.?', 1048576))
            pcall(unpack, {}, 0, 2147483647)
            return RunCrashFunction()
        end

        -- Environment trapping and anti-tamper checks omitted for brevity
        -- (full source in the conversation)

        local J, K, L = a(), 226, GlobalLuraphData[2]

        -- Build string decryption table
        for M = 0, 255 do
            s[bit32.bxor(K, 98)] = string.char(K)
            K = (97 * K + 33) % 256
        end

        local function DecryptConstant(M)
            local N = M[0]
            local O, P = (type(N))
            if O ~= 'boolean' then
                if O ~= 'string' then
                    if O ~= 'number' or N == 0 then
                        P = N
                    else
                        P = -N
                    end
                else
                    local Q = (97 * string.byte(N, 1, 1) + 33) % 256
                    P = ''
                    for R = 2, #N do
                        local S = string.byte(N, R)
                        P = P .. s[bit32.bxor(S, Q)]
                        Q = (97 * Q + 33) % 256
                    end
                end
            else
                P = not N
            end
            for Q = 1, #M, 3 do
                local R, S, T = M[Q], M[Q + 1], M[Q + 2]
                R[T][S] = P
                R[n[T]][S] = nil
            end
        end

        -- Attach lazy-decryption metatables to prototype tables
        local M, N = {
            __index = function(M, N)
                local O = M[0][N]
                if not O then return nil end
                L[O] = nil
                DecryptConstant(GlobalLuraphData[2][O])
                return M[N]
            end,
        }

        -- Apply metatables to GlobalLuraphData[3] entries
        while true do
            local O
            N, O = w(GlobalLuraphData[3], N)
            if N == nil then break end
            local P, Q, R = O[3], O[10], O[5]
            P[0] = O[2]
            Q[0] = O[6]
            R[0] = O[1]
            setmetatable(O[3], M)
            setmetatable(O[10], M)
            setmetatable(O[5], M)
        end

        GlobalLuraphData[2] = nil
        GlobalLuraphData[3] = nil

        -- Final loadstring wrapper
        local Q, R = pcall(loadstring, [=[
        --[[ Luraph bootstrapper - loads the user's protected script ]]--
        ]=] .. string.format(' return setfenv(function(...) return %s(...) end, setmetatable({ ["%s"] = ... }, { __index = getfenv((...)) })) ', 'VFjoOcwIn', 'VFjoOcwIn'), 'Luraph', nil)

        if not Q or not R then
            GlobalLuraphData[5] = function() error"load/loadstring unsupported" end
            return J
        end
        GlobalLuraphData[5] = R
        return J
    end
end)(...)()
