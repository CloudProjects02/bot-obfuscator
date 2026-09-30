local p = require("@lune/process")
print("ARGS COUNT:", #p.args)
for i, a in ipairs(p.args) do
    print(i, a)
end
