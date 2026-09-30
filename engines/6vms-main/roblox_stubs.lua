-- minimal roblox stubs
-- just so getservice doesnt crash

local a = {}
function b(c)
    local d = {classname=c, name=c, _c={}}
    d.destroy = function() end
    d.clone = function() return b(c) end
    d.getchildren = function() return {} end
    d.getdescendants = function() return {} end
    d.findfirstchild = function() return nil end
    d.findfirstchildofclass = function() return nil end
    d.findfirstancestor = function() return nil end
    d.waitforchild = function() return nil end
    d.isa = function(e, f) return f == c or f == 'instance' end
    d.isancestorof = function() return false end
    d.isdescendantof = function() return false end
    d.getfullname = function() return c end
    d.getattribute = function() return nil end
    d.setattribute = function() end
    d.clearallchildren = function() end
    return d
end

local e = {}
function f(c)
    if not e[c] then
        e[c] = b(c)
        e[c].getservice = function(d, g) return f(g) end
        e[c].findservice = function(d, g) return f(g) end
        e[c].create = function(d, g, h) return b(g) end
    end
    return e[c]
end

_G.game = f('datamodel')
_G.game.name = 'game'
_G.game.gameid = 0
_G.game.placeid = 0

_G.workspace = f('workspace')
_G.workspace.gravity = 196.2
_G.instance = {new = b}

_G.enum = setmetatable({}, {__index = function(c,d) rawset(c,d,{}); return rawget(c,d) end})

_G.vector3 = {new = function(c,d,e) return {x=c or 0, y=d or 0, z=e or 0} end, zero={x=0,y=0,z=0}, one={x=1,y=1,z=1}}
_G.cframe = {new = function() return setmetatable({},{__tostring=function() return '0 0 0 1 0 0 0 1 0 0 0 1' end}) end,
    angles = function() return _G.cframe.new() end, fromeuleranglesxyz = function() return _G.cframe.new() end,
    identity = setmetatable({},{__tostring=function() return '0 0 0 1 0 0 0 1 0 0 0 1' end})}
_G.color3 = {new = function(c,d,e) return {r=c or 0,g=d or 0,b=e or 0} end}
_G.udim2 = {new = function(c,d,e,f) return {x={c or 0,d or 0},y={e or 0,f or 0}} end}
_G.brickcolor = {new = function(c) return {number=c or 1} end}
_G.ray = {new = function(c,d) return {origin=c, direction=d} end}
_G.region3 = {new = function(c,d) return {min=c,max=d} end}

_G.isfunction = function(c) return type(c) == 'function' end
_G.istable = function(c) return type(c) == 'table' end
_G.isstring = function(c) return type(c) == 'string' end
_G.isnumber = function(c) return type(c) == 'number' end
_G.isbool = function(c) return type(c) == 'boolean' end
_G.typeof = function(c)
    local d = type(c)
    if d == 'table' then
        local e = rawget(c, 'classname')
        if e then return e end
    end
    return d
end

_G.printidentity = function() end
_G.settings = {getservice = function() return b('s') end}
_G.debug = {
    traceback = function(message, level) return tostring(message or '') end,
    info = function(...) return {} end,
    getmemorycategory = function() return 'lua' end,
    setmemorycategory = function(tag) return tag end,
    resetmemorycategory = function() end,
    profilebegin = function(label) end,
    profileend = function() end,
    dumpcodesize = function() return 0 end,
}
_G.script = b('script')
_G.loadstring = loadstring
_G.tick = function() return os.clock() end
_G.time = function() return os.clock() end

_G.task = {
    wait = function(c) return c or 0 end,
    spawn = function(c) if type(c)=='function' then c() end end,
    delay = function(c,d) if type(d)=='function' then d() end end,
    defer = function(c) if type(c)=='function' then c() end end,
    cancel = function() end,
}