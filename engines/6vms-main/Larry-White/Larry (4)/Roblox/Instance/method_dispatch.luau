local Legacy = require("./legacy_impl")

local Dispatch = {}

function Dispatch.Resolve(Inst, MethodName)
	local Value = Legacy.__index(Inst, MethodName)
	if typeof(Value) == "function" then
		return Value
	end
	return nil
end

function Dispatch.Call(Inst, MethodName, ...)
	local Handler = Dispatch.Resolve(Inst, MethodName)
	if Handler == nil then
		error("unknown instance method: " .. tostring(MethodName))
	end
	return Handler(Inst, ...)
end

return Dispatch