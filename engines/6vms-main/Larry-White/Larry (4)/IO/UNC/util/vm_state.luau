local VmMutationBridge = require("../../../Core/VmMutationBridge")

local VmState = {}

function VmState.Resolve()
	return VmMutationBridge.Resolve()
end

return VmState