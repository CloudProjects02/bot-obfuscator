local VmMutationBridge = require("./VmMutationBridge")

local VmStateRuntime = {}

function VmStateRuntime.Get()
	return VmMutationBridge.GetShared()
end

return VmStateRuntime