local Ast = require("prometheus.ast")
local visitAst = require("prometheus.visitast")

local AstKind = Ast.AstKind

local Processor = {}

local function getVariableName(node)
    if not node then
        return nil
    end

    if node.kind ~= AstKind.VariableExpression then
        return nil
    end

    if node.scope and node.id ~= nil then
        if type(node.scope.getVariableName) == "function" then
            local success, result = pcall(
                node.scope.getVariableName,
                node.scope,
                node.id
            )

            if success and type(result) == "string" then
                return result
            end
        end
    end

    if type(node.getName) == "function" then
        local success, result = pcall(function()
            return node:getName()
        end)

        if success and type(result) == "string" then
            return result
        end
    end

    return nil
end

local function getMacroName(node)
    if not node then
        return nil
    end

    if node.kind ~= AstKind.FunctionCallExpression then
        return nil
    end

    return getVariableName(node.base)
end

function Processor.process(ast, Registry, options)

    options = options or {}

    local state = {
        ast = ast,
        registry = Registry,
        options = options,

        obfuscated = options.obfuscated ~= false
    }

    local function previsit(node, data)

        if node.kind == AstKind.VariableExpression then

            local name = getVariableName(node)

            if name == "LRPE_PROTECTED" then
                return Ast.BooleanExpression(
                    state.obfuscated
                )
            end

            if name == "LRPE_LINE" then
                local line =
                    node.line
                    or node.sourceLine
                    or 0

                return Ast.NumberExpression(line)
            end
        end

        if node.kind == AstKind.FunctionCallExpression then

            local name = getMacroName(node)

            if name and name:sub(1, 5) == "LRPE_" then

                local macro = Registry.get(name)

                if not macro then
                    error(
                        "Unknown LRPE macro: " .. name
                    )
                end

                return macro(
                    node.args,
                    {
                        ast = ast,
                        data = data,
                        state = state,
                        options = options,
                        Ast = Ast
                    }
                )
            end
        end

        return node
    end

    return visitAst(
        ast,
        previsit
    )
end

return Processor