local Ast = require("prometheus.ast")
local AstKind = Ast.AstKind

local Macros = {}

local function expectArgs(name, args, count)
    if #args ~= count then
        error(string.format(
            "LRPE_%s expects %d argument(s), got %d",
            name,
            count,
            #args
        ))
    end
end

local function expectString(name, node)
    if node.kind ~= AstKind.StringExpression then
        error("LRPE_" .. name .. " expects a string literal")
    end

    return node.value
end

local function expectNumber(name, node)
    if node.kind ~= AstKind.NumberExpression then
        error("LRPE_" .. name .. " expects a number literal")
    end

    return node.value
end

function Macros.registerAll(Registry)

    Registry.register("LRPE_STRLOCK", function(args, context)
        expectArgs("STRLOCK", args, 1)

        local value = expectString(
            "STRLOCK",
            args[1]
        )

        return Ast.StringExpression(value)
    end)

    Registry.register("LRPE_NUMLOCK", function(args, context)
        expectArgs("NUMLOCK", args, 1)

        local value = expectNumber(
            "NUMLOCK",
            args[1]
        )

        return Ast.NumberExpression(value)
    end)

    Registry.register("LRPE_HALT", function(args, context)
        expectArgs("HALT", args, 0)

        return {
            kind = AstKind.FunctionCallExpression,

            base = {
                kind = AstKind.VariableExpression,
                scope = context.data.scope,
                id = context.data.scope:addVariable("error")
            },

            args = {
                Ast.StringExpression("LRPE_HALT")
            }
        }
    end)

end

return Macros