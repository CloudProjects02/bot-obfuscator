unpack = unpack or table.unpack

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local AstKind = Ast.AstKind
local visitast = require("prometheus.visitast")

local NumbersToExpressions = Step:extend()

NumbersToExpressions.Description = "Encodes number literals for LRPE"
NumbersToExpressions.Name = "LRPE Number Encoding"

NumbersToExpressions.SettingsDescriptor = {
    Threshold = {
        type = "number",
        default = 0.35,
        min = 0,
        max = 1,
    },
}

function NumbersToExpressions:init(settings)
    settings = settings or {}
    self.Threshold = settings.Threshold or 0.35
end

function NumbersToExpressions:apply(ast)
    visitast(ast, nil, function(node)
        if node.kind ~= AstKind.NumberExpression then
            return
        end

        if math.random() > self.Threshold then
            return
        end

        local value = node.value

        if value == math.floor(value) and value >= -255 and value <= 255 then
            return Ast.UnaryExpression and Ast.UnaryExpression(node) or node
        end

        return node
    end)
end

return NumbersToExpressions